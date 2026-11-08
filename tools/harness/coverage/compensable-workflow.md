# Coverage matrix — `compensable-workflow`

- **Pattern:** `compositions/compensable-workflow.md`
- **Model:** `compensable-workflow.tla` + seventeen buggy twins, `compensable-workflow-<name>-buggy.tla` for `skip-comp`, `double-apply`, `fifo`, `commit-early`, `close-over-attempt`, `cancel-over-attempt`, `cancel-past-pivot`, `cancel-after-commit`, `cancel-nofire`, `onset-on-indeterminate`, `onset-on-roll-forward`, `storage-fail-resolves`, `ghost-write`, `lapsed-resume`, `resume-forward`, `halt-resolves`, `truncated` (each `.tla` with its `.cfg`)
- **Reviewer / date:** the model's author, the session that landed it — 2026-11-08. Not a fresh-context read; the next scheduled rescan owes one.
- **Formal-layer vote load-bearing claims:** the vote was cast yes in 2026-06 and the model re-derived 2026-11-08 over what the Ledger's `formal:` line named (the attempt markers, the critical section as a second writer with lease expiry as its terminus, the four-way verdict, the halt that parks rather than resolves, and the operator's resume). The model takes every composition-level Invariant the page states as load-bearing except those the projection holds by construction (Invariant 1, 3.1, 6.1, 6.2): Invariant 2.1 (progress equivalence), 4 (all-or-compensated, 4.1 to 4.5), 5.1 (reverse order), 6.3 (resume returns to the phase), 7 (idempotency under retry, 7.1 and 7.2), 8.1 (forward-closed after abort).

## Step 1 — harness re-run (must pass)

- Correct model: `node check.mjs ../../compositions/compensable-workflow.tla` → `HOLDS` ✓ *(3,808 states)*
- Buggy twins: each `node check.mjs ../../compositions/compensable-workflow-<name>-buggy.tla --buggy` → `CAUGHT` ✓ *(Step 2 names the check that finds each)*
- `node audit.mjs --only compositions/compensable-workflow`: 18 models, 1 HOLDS, 17 CAUGHT, 0 BROKEN, 0 MISSED, 0 ERROR.

## Step 2 — coverage matrix

The model has one run of two steps, each with a compensating action. The run is the projection the replay derives (the phase, each step's place, the unresolved attempt markers as effect keys, the halt's phase and named steps); beside it the world the page does not own (how many times each effect really landed at its target, and the effect keys a target has forgotten). An invocation is four steps (it takes the critical section, re-enters and marks, runs the effect and learns a verdict, records), so the window between the effect and its record is open; the lease may expire at any point, leaving the expired invocation holding a reply it must discard; a cancel is one step that takes and releases the section. The target answers one of four verdicts at every effect, the pivot is absent or the second step, the compensation failure policy is halt-and-surface or continue, a key lapses only while the run rests halted, and a target's reply to the forward step may exceed the input envelope. The model keeps no history: a property of the state is an invariant over the state, and a property of a step is a name the step adds to `viol` when it breaks the rule. Twenty entries in the `.cfg`.

| Spec invariant (no. + name) | Load-bearing (vote)? | Verdict | Model construct / reason |
|---|---|---|---|
| Invariant 1.1, 1.2 — log faithfulness (one event per recorded act, an act behind every event) | no | by-construction | the model holds the projection the replay derives, and every step is one recorded act; the faithfulness of the log to its acts is the projection's definition, read at Check 1.1 and 1.2 by an auditor |
| Invariant 2.1 — the spine equals the replayed state at every quiescent point | YES | **covered** | `Invariant_2_1` (`sp = ph` while no invocation holds the section). Twin `-cancel-nofire` (a cancel appends the onset and leaves the fire out) is rejected by it. The spine fault (Primitive policy 27) is the one way the page lets the two disagree and it is out of scope below. |
| Invariant 3.1 — one compensation reference on every completion of a step that is not roll-forward | no | by-construction | every step in the model carries its compensation (the key `N + i`); the pairing is the model's shape, and Non-goal 9 below reads the roll-forward steps the page excepts |
| Invariant 4 — all-or-compensated | YES | **covered** | `Invariant_4_AllOrCompensated`, read against the world: a committed run has every effect landed once and no compensation applied; a compensated run has every effect that landed reversed, the one an indeterminate verdict left unrecorded included. Twins `-skip-comp` (the close leaves older completed steps standing), `-commit-early`, `-close-over-attempt`, `-double-apply`, `-lapsed-resume`, `-resume-forward`, `-onset-on-indeterminate` and `-storage-fail-resolves` are each rejected by it (and by the more specific check named in the twin table). |
| Invariant 4.1 — a close carries a compensation run for every completion | YES | **covered** | `Invariant_4_1`. Twins `-skip-comp`, `-close-over-attempt`. |
| Invariant 4.2 — a commit carries a completion for every declared step | YES | **covered** | `Invariant_4_2`. Twins `-commit-early`, `-resume-forward`. |
| Invariant 4.3 — a commit carries no compensation onset | YES | **covered** | `Invariant_4_3` (no cancel lands over a commit; a committed run has no step reversed). Twin `-cancel-after-commit`. |
| Invariant 4.4 — the composition carries every open obligation | YES | **covered** | `Invariant_4_4_OpenObligations`: an effect that landed and has no completion record is an unresolved attempt, whatever a verdict, a halt, a storage failure or a cancel does after. Twins `-onset-on-indeterminate`, `-storage-fail-resolves`, `-halt-resolves`, `-ghost-write`. |
| Invariant 4.5 — a terminal marker lands only if no attempt is unresolved | YES | **covered** | `Invariant_4_5`. Twin `-close-over-attempt` (a step whose compensation attempt is unresolved counts as compensated). |
| Invariant 5.1 — completed steps are compensated newest first | YES | **covered** | `Invariant_5_1` (each compensation run is checked against the completed steps newer than it). Twin `-fifo` (the oldest pending step first) is rejected by it, and by `-ghost-write` reaching the same through a duplicate record. |
| Invariant 6.1 — no two terminal markers | no | by-construction | the phase is one value and a terminal is absorbing (no step is enabled out of committed or compensated); the nearest break, a cancel over a commit, is `-cancel-after-commit`, read as Invariant 4.3 |
| Invariant 6.2 — halted is not an outcome | no | by-construction | halted is a phase; no step reads it as committed or compensated |
| Invariant 6.3 — a resume marker returns the run to the phase the halt names | YES | **covered** | `Invariant_6_3` (the step compares the phase it fires to with the halt's phase). Twin `-resume-forward`. |
| Invariant 7.1 — the at-most-once claim, given the target key discipline and the critical section | YES | **covered** | `Invariant_7_1` (no effect and no compensation lands at its target twice). The two conditions are modelled, not assumed: the target honours a key it has seen until the key lapses, and the critical section keeps one invocation on the act. Twin `-double-apply` (the target does not honour the key, Capability requirement 15 missing) is rejected by it, and `-lapsed-resume` (an operator admitted without the horizon assertion over a key the target forgot, Primitive policy 7). The lease-and-ghost half is read by `Invariant_7_2` and `Check_7_1`. |
| Invariant 7.2 — the composition runs no effect whose key is in the applied effects | YES | **covered** | `Invariant_7_2` (a step runs an effect whose key has a completion record). Twin `-ghost-write` (an expired invocation records its reply, so the next invocation runs a recorded key). |
| Check 7.1 — no two completion records carry one effect key | no | **covered** | `Check_7_1`. Twin `-ghost-write`. |
| Invariant 8.1 — no step completion follows a compensation onset | YES | **covered** | `Invariant_8_1`. Twins `-cancel-over-attempt` (the onset over an unresolved attempt lets the re-entry record the forward step after it) and `-ghost-write`. |
| Replay 12, Check 4.5 — a halt event resolves no attempt | no | **covered** | `Replay_12_HaltParksAttempt`: every key a standing halt names is recorded, still an unresolved attempt, or a standing compensation failure. Twin `-halt-resolves` (the halt for an unknown effect resolves the attempt). |
| Action wiring 30 — a failed roll-forward step begins no compensation | no | **covered** | `Action_30_NoOnsetOnRollForward`. Twin `-onset-on-roll-forward`. |
| Action wiring 45 — an indeterminate verdict begins no compensation | no | **covered** | read as Invariant 4.4: the onset resolves the attempt and the landed effect loses its marker. Twin `-onset-on-indeterminate`. |
| Action wiring 53 — a completion that does not land resolves nothing | no | **covered** | read as Invariant 4.4. Twin `-storage-fail-resolves`. |
| Action wiring 72 — a cancel with an unresolved attempt answers step-unresolved, writes nothing | no | **covered** | `Action_72_NoCancelOverAttempt`. Twin `-cancel-over-attempt`. |
| Action wiring 73, Non-goal 9 — a cancel past the pivot answers roll-forward; no roll-forward step is compensated | no | **covered** | `Action_73_NoCancelPastPivot`, and `NonGoal_9_NoRollForwardCompensated` (no compensation applied for a roll-forward step). Twin `-cancel-past-pivot`. |
| Action wiring 3 through 5 — an expired invocation writes nothing and discards its reply | no | **covered** | the `Expire` and `GhostDiscard` steps; the break is read as Invariant 7.2, Check 7.1 and Invariant 8.1. Twin `-ghost-write`. |
| Primitive policy 7 — a halted advance carries the horizon assertion | no | **covered** | the guard on `Take`: a call on a halted run is admitted only while every parked or named key is still honoured at its target; read as Invariant 7.1. Twin `-lapsed-resume`. The model takes the operator as truthful (the assertion is the operator's act and the composition does not vouch for it, Term horizon assertion). |
| Primitive policy 23 through 25, Check 8.2 — an overflowed step is compensated from the operator's inputs | no | **covered** | `Primitive_25_OverflowFromOperator`. Twin `-truncated` (the resume marker does not keep the operator's compensation inputs). |
| Action wiring 37 through 41 — halt-and-surface, continue, the standing failure and the halt that names it | no | **covered** | the model takes both policies (`pol`) and the halt `HaltStanding`; Invariants 4 and 4.1 read their results, and `Replay_12_HaltParksAttempt` reads the halt that names a standing failure. No twin of its own: the break is the close ignoring a standing failure, which `-skip-comp` and `-close-over-attempt` reach through the same guard. |
| Composes 1 through 10; Composition state 1 through 13; Replay 1 through 11, 13, 14 | no | out-of-scope | wiring, storage and derivation rules the model fixes: it holds the projection the replay would derive, one instance of each constituent, and the effect keys as numbered keys. Open 2026-11-03-b and 2026-11-03-e (who provisions the log instance; a second caller of the spine's fire) are the page's. |
| Capability requirement 1 through 20 | no | out-of-scope | deployment configuration. The model takes the two it reads (the compensation failure policy, the pivot) as the shapes `Init` chooses and the critical section's exclusion as the host's, with the lease able to expire at any point. |
| Primitive policy 1 through 6, 8 through 18, 26, 27; Event schema; Action wiring 62 through 68 | no | out-of-scope | single-call refusals and event shapes before any state is touched (the start, the sizing against the payload cap, the oversized-input refusals, the blank-reason refusals); the spine fault (Primitive policy 27, Action wiring 57 through 59) is unreachable in the model because a transition-bearing event and its fire commit together (Execution Contract Database 1), which is why `sp` follows `ph` in every write |
| Parallel compensation order; Action wiring 15's loop over several unresolved attempts | no | out-of-scope | the order has no semantics on the page (open 2026-11-03-a); the model takes the reverse order and re-runs the unresolved attempts one per invocation, which no invariant reads differently |
| Non-goal 1 through 22, Concurrency 1 through 3, Indeterminate outcome 1 and 2 | no | out-of-scope, or read above | they bound the claim (isolation, true rollback, retention, authorization); Indeterminate outcome 1 and 2 are read as Invariant 4.4 and Action wiring 45 |

Each twin against the checks that reject it, measured by running every twin against every check alone (the second column is the first check to fail with the whole list on, with the states searched when it did; the third names every other check that rejects the twin by itself):

| Twin (the rule it breaks) | First check to fail (states) | Also rejected by |
|---|---|---|
| `-skip-comp` (Action wiring 40, 41: the close leaves an older completed step standing) | `Invariant_4_AllOrCompensated` (119) | `Invariant_4_1` |
| `-double-apply` (Capability requirement 15: the target applies every delivery) | `Invariant_7_1` (74) | `Invariant_4_AllOrCompensated` |
| `-fifo` (Invariant 5.1: oldest pending first) | `Invariant_5_1` (704) | — |
| `-commit-early` (Action wiring 31) | `Invariant_4_AllOrCompensated` (14) | `Invariant_4_2` |
| `-close-over-attempt` (Invariant 4.5, Replay 11) | `Invariant_4_AllOrCompensated` (355) | `Invariant_4_1`, `Invariant_4_5` |
| `-cancel-over-attempt` (Action wiring 72) | `Action_72_NoCancelOverAttempt` (51) | `Invariant_8_1`, `NonGoal_9_NoRollForwardCompensated` |
| `-cancel-past-pivot` (Action wiring 73) | `Action_73_NoCancelPastPivot` (297) | `NonGoal_9_NoRollForwardCompensated` |
| `-cancel-after-commit` (Action wiring 71, Invariant 4.3) | `Invariant_4_3` (423) | — |
| `-cancel-nofire` (Invariant 2.1) | `Invariant_2_1` (6) | — |
| `-onset-on-indeterminate` (Action wiring 45) | `Invariant_4_4_OpenObligations` (50) | `Invariant_4_AllOrCompensated` |
| `-onset-on-roll-forward` (Action wiring 30) | `Action_30_NoOnsetOnRollForward` (205) | — |
| `-storage-fail-resolves` (Action wiring 53) | `Invariant_4_4_OpenObligations` (47) | `Invariant_4_AllOrCompensated` |
| `-ghost-write` (Action wiring 3, 5) | `Invariant_7_2` (192) | `Invariant_4_1`, `Invariant_5_1`, `Check_7_1`, `Invariant_8_1`, `Replay_12_HaltParksAttempt`, `Invariant_4_4_OpenObligations` |
| `-lapsed-resume` (Primitive policy 7) | `Invariant_7_1` (475) | `Invariant_4_AllOrCompensated` |
| `-resume-forward` (Invariant 6.3) | `Invariant_6_3` (461) | `Invariant_4_AllOrCompensated`, `Invariant_4_2`, `Invariant_4_3` |
| `-halt-resolves` (Replay 12) | `Replay_12_HaltParksAttempt` (97) | `Invariant_4_4_OpenObligations` |
| `-truncated` (Primitive policy 23 through 25) | `Primitive_25_OverflowFromOperator` (561) | — |

Reachability, probed before the model was trusted (each state a deliberate falsehood, `--buggy`, so the checker must reject it): a committed run; a compensated run; a compensated run with both compensations run under continue; a halted run naming the forward phase and one naming the compensating phase; a halt naming two steps; a standing compensation failure; an effect left unrecorded with its attempt standing; the pivot step completed; an expired invocation's reply in flight; a lapsed key; a lapsed key with the run still halted; an overflowed step; a resume carrying the operator's inputs; an overflowed step compensated from them; and an overflowed step, and a resume carrying the operator's inputs, each in a run that ends committed.

Two readings the model made plain, neither a counterexample:

- A run whose parked key has lapsed rests halted for good: the operator cannot truthfully assert the horizon (Primitive policy 7), so no resume is admitted, and [Cancel] on a halted run is answered and not written (Action wiring 76). That is the page's open line 2026-11-03-d (the halted rest is the gap a deployment cannot keep) and the model shows no terminal outcome is wrongly reached from it; the page does not say how such a run is closed.
- A resume marker for an overflowed step names a recorded key, so by Replay 11 it holds no unresolved attempt; the resume carries the operator's inputs and nothing re-runs (the page's own rejection path). The model's `Resume` filters the parked keys by that rule.

## Step 3 — bound saturation

Raise the model's scope once and confirm the verdict does not change:

- At the shipped bound (two steps, both policies, both pivot shapes): 3,808 states, all twenty entries hold, under one second. The slowest twin to be found (`-fifo`) takes 704 states.
- At one step: 478 states, the same verdict (a lower bound, no newest-first to read).
- At three steps the checker stops with `MaxDepthExceeded` at depth 41 (the harness caps depth at 40 and treats it as an error, not a truncation), so a third step cannot be run without shortening the invocation. The space at two steps is exhaustive, not sampled; the arms a third step would repeat (a newest-first pick among three, the pivot after a compensable pair) are the arms two steps already take (the pick among two, the pivot as the last step).

## Outcome

- GAP rows: **none**.
- by-construction flags on load-bearing invariants: none (Invariant 1.1 and 1.2, 3.1, 6.1 and 6.2 are held by the projection and none is a vote-named load-bearing claim).
- Result: **all Invariants covered** — 2026-11-08. *Lineage entry: "Coverage cross-check 2026-11-08 — clean (every composition-level Invariant covered by a named check, by construction of the projection, or out of scope with its reason; seventeen twins each rejected by a named check)."*
