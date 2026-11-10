# Coverage matrix — `state-machine`

- **Pattern:** `atoms/state-machine.md`
- **Model:** `state-machine.als` (Alloy, static: one declaration and one linear history chain; 10 checks, 4 runs) + buggy twin `state-machine-buggy.als` (drops `TerminalNoOutgoingDecl`, `EveryEntryDeclared` and `ChainConsistency`)
- **Reviewer / date:** mayor, from the page at fc78924 and the model as it stands — 2026-11-10 (unit `formal: more coverage for the yes votes`, step 1; the page had no matrix)
- **Formal-layer vote load-bearing claims:** the model header names Invariant 3 (only declared transitions fire), Invariant 4 (terminal absorption), Invariant 7 (replay determinism), declaration determinism and chain consistency. It puts guard gating (Invariant 8) out of scope as an action-enablement property.

## Step 1 — harness run

- Correct model: `node check.mjs ../../atoms/state-machine.als` → `HOLDS` ✓ (14 commands: 10 checks hold, 4 runs satisfiable; 2026-11-10, JRE 17).
- Buggy twin: `node check.mjs ../../atoms/state-machine-buggy.als --buggy` → `CAUGHT` ✓ (counterexamples on `A_Inv3_OnlyDeclaredTransitions`, `A_Inv4_TerminalAbsorption` and `A_ChainConsistency`). The three counterexamples come from three dropped facts in one file.

## Step 2 — coverage matrix

One row per rule of *Invariants*. Every `check` in this model is the same proposition as a `fact` that constrains the universe of instances (`A_Inv3_…` ≡ `EveryEntryDeclared`, `A_Inv4_…` follows `TerminalNoOutgoingDecl`, `A_ChainConsistency` ≡ `ChainConsistency`, `A_Inv7_…` ≡ `SingleHistoryChain` and `HeadFromInitial`, `A_Linear_*` ≡ the linear facts). The model describes which histories are *well-formed*; it has no `fire` step, so the checks cannot be false for a reason the English could have got wrong, and the twin shows only that dropping the facts lets a malformed instance in.

| Spec claim | Load-bearing (vote)? | Verdict | Model construct / reason |
|---|---|---|---|
| Invariant 1.1 — a recorded declaration's field does not change | no | out-of-scope (named reason) | One declaration, one state of it; no step. **Owed to TLA+** (b). |
| Invariant 1.2 — `Read Declaration` answers the declaration as `Instantiate` took it | no | out-of-scope (named reason) | No read operation, no Instantiate step. Owed to TLA+ (b). |
| Invariant 2.1 — every workflow stands in exactly one state | yes | **covered** (as a derived value) | `current_state` is derived from the tail (or the initial state), never stored, so "exactly one" is `A_Inv7_ReplayUniqueTail` (`lone (Entry - Entry.successor)`: at most one tail). The page stores a state on the workflow; the claim that the stored state equals the derived one is Invariant 7.1 below. |
| Invariant 3.1 — every history entry matches exactly one declared transition | yes | **covered** | `A_Inv3_OnlyDeclaredTransitions` (at least one) and `A_DeterministicDecl` (at most one); the twin rejects the first. |
| Invariant 3.2 — two declared transitions share no from state and action | yes | **covered** | `A_DeterministicDecl` over `fact DeterministicDecl` (a restatement; no twin drops the fact). |
| Invariant 4.1 — a workflow in a terminal state does not leave it | yes | **covered** (static) | `A_Inv4_TerminalAbsorption` (no entry fires from a terminal state); the twin rejects it. "Does not leave" is a statement about two states; it is represented by "no entry has a terminal from-state". |
| Invariant 4.2 — a declared transition's from state is not terminal | yes | **covered** | `TerminalNoOutgoingDecl` (the instantiate guard), which `A_Inv4_TerminalAbsorption` follows from; the twin drops it. `InitialNotTerminal` states the initial state is not terminal. |
| Invariant 5.1 — a history entry does not change | no | out-of-scope (named reason) | Stepping; owed to TLA+ (b). |
| Invariant 5.2 — the history entry count equals the admitted fire count | yes | out-of-scope (named reason) | The model has no fire count and no admitted/refused distinction; it is a claim about a counter next to a log. Owed to TLA+ (b). |
| Invariant 6.1 — two entries share no sequence number | no | **covered** (by position) | `NoMerging`, `SuccPredInverse`, `A_Linear_*`. No numbers are modeled; position stands for them. |
| Invariant 6.2 — sequence numbers run from one to the entry count | no | **covered** (by position) | `A_Linear_NoCycles` and `SingleHistoryChain`: a path from one head has dense positions. |
| Invariant 6.3 — history order rests on sequence number alone | no | out-of-scope (named reason) | No instants (header: "Clock semantics / fired_at ordering"). |
| Invariant 7.1 — the workflow stands in the highest-numbered entry's to state | yes | by-construction | The model derives `current_state` as the tail's `to_state`, so the equality is a definition, not a property; a stored state that drifts from the tail is not representable. This is the claim a replay detects; owed (b), with a stored `state` field next to the history. |
| Invariant 7.2 — a workflow with no history stands in the initial state | yes | by-construction | The same derivation (`ShowEmptyHistory`, a run). |
| Invariant 7.3 — replaying the history from the initial state reaches the current state | yes | **covered** | `A_ChainConsistency` (consecutive entries agree) with `A_Inv7_HeadFromInitial` (the head starts at the initial state); together a replay walks the chain. The twin drops `ChainConsistency` and the check is rejected. |
| Invariant 8.1 — a guarded transition fires only if `guard satisfied` is true | yes | out-of-scope (named reason) | The header: "action-enablement; caller's obligation" (cf. Medication Order Inv 9, which the 2026-06-04 sweep recorded as a deliberate by-construction assumption). A TLA+ action with a guard conjunct and a twin dropping it can state it. Owed (b). |
| Invariant 8.2 — the atom does not evaluate a guard's condition | no | out-of-scope (named reason) | A rule about what the atom does not compute; no model can state an absence of computation. |
| Invariant 8.3 — a guarded transition's entry records the caller's assertion | no | out-of-scope (named reason) | The entry carries `efrom`, `eact`, `eto` only. A field claim; Alloy could add `eassert` and a guarded flag. Owed (b). |
| Invariant 9.1 — a recorded actor reference is non-blank | no | out-of-scope (named reason) | Header: actor_ref attribution is left to the composing pages. |
| Invariant 10.1, 10.2 — no workflow and no history entry is removed | no | out-of-scope (named reason) | Stepping; one workflow. Owed to TLA+ (b) as `[][…]_vars`. |

## Step 3 — bound saturation

Checks run `for 7` (up to seven entries). The facts make the history a path, so a longer path repeats a link already seen; `ShowReachTerminal` fits inside seven. A rerun `for 9` is owed; not run in this pass.

## Outcome

- GAP rows: none on the static claims the header names. The load-bearing stepping claims (5.2, 8.1) have no construct.
- by-construction flags on load-bearing claims: Invariant 7.1 and 7.2 (the state is derived, so the equality is a definition). Eight rows pass because they restate a fact the model is built from.
- Owed (step 2 of the coverage unit): **(b)** Invariants 5.2, 7.1, 8.1 and 8.3 (a `fire` step with a guard, a fire count, a stored state and a recorded assertion), with twins that drop the guard and skip the count; **(b)** Invariants 1.1, 1.2, 5.1, 10.1, 10.2 as `PROPERTY` action formulas; **(c)** Invariant 8.2 (a rule about what is not computed; stays with the reason). **Tool owed** (step 2c): TLA+ for the stepping claims; the Alloy file is static and keeps its checks. Step 2d's pattern matches it on no temporal keyword.
- Result: **findings routed** — coverage debt; no English defect.
