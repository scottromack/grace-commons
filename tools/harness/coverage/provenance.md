# Coverage matrix — `provenance`

- **Pattern:** `atoms/provenance.md`
- **Model:** `provenance.als` (Alloy, static: one chain as a linear sequence of entries; 12 checks, 5 runs) + buggy twin `provenance-buggy.als` (drops `ArchivedTerminal` and `CustodyContinuity` together)
- **Reviewer / date:** mayor, from the page at fc78924 and the model as it stands — 2026-11-10 (unit `formal: more coverage for the yes votes`, step 1; the page had no matrix)
- **Formal-layer vote load-bearing claims:** the model header names custody continuity (Invariant 4) as the load-bearing claim, then single origin (3), archived terminal (6), the linear backbone (2 and 5), custodian presence (7) and event-type validity (8).

## Step 1 — harness run

- Correct model: `node check.mjs ../../atoms/provenance.als` → `HOLDS` ✓ (17 commands: 12 checks hold, 5 runs satisfiable; 2026-11-10, JRE 17).
- Buggy twin: `node check.mjs ../../atoms/provenance-buggy.als --buggy` → `CAUGHT` ✓ (counterexamples on `A_Inv4_CustodyUnbroken`, `A_Inv4_TransferHandToHand`, `A_Inv4_TransferSetsHolder`, `A_Inv4_OnlyHolderActs` and `A_Inv6_ArchivedTerminal`). One twin carries two defects, a custody gap and a non-absorbing archive; the checks for each are rejected, so neither masks the other here (Alloy reports each check on its own). No twin breaks the five `A_Linear_*` and `A_Inv3_*` checks, or `A_Inv4_UniqueHolder` and `A_Inv7_CustodianPresent`.

## Step 2 — coverage matrix

One row per rule of *Invariants*. The model is a static snapshot of one chain; a claim about how a chain *changes* is a stepping claim.

| Spec claim | Load-bearing (vote)? | Verdict | Model construct / reason |
|---|---|---|---|
| Invariant 1.1 — a recorded entry's fields do not change | no | out-of-scope (named reason) | A claim about two states of one entry; the snapshot has one. The model's `holder` and `fromC`/`toC` fields are fixed per entry by facts. **Owed to TLA+** (b): a step that rewrites a field is not representable here. |
| Invariant 2.1 — a chain's entry count does not fall | no | out-of-scope (named reason) | Stepping. The linear backbone (`A_Linear_*`) says a chain is a path; it says nothing about two snapshots. Owed to TLA+ as `[][len' >= len]_vars`. |
| Invariant 2.2 — a recorded entry's sequence number does not change | no | out-of-scope (named reason) | The model has no sequence numbers; position in the successor path stands for them (header: "linear position models it"). |
| Invariant 3.1 — exactly one genesis entry per chain | yes | **covered** | `GenesisTyping` (no predecessor iff a genesis event type) with `NoMerging`/`NoCycles`; `A_Inv3_SingleOriginTyping`. One chain is a path, so one entry has no predecessor. Two chains are `ShowTwoIndependentChains`. |
| Invariant 3.2 — the genesis entry's sequence number stands at one | no | out-of-scope (named reason) | No sequence numbers. |
| Invariant 3.3 — no second originate against a recorded chain | yes | out-of-scope (named reason) | An action-enablement claim (Originate refuses against an existing chain id). The model has no Originate action and no chain id. Owed to TLA+ (b). |
| Invariant 4.1 — an open chain has exactly one current custodian | yes | **covered** | `A_Inv4_UniqueHolder` (one `holder` per entry) over the cached-projection field; the twin does not break it. |
| Invariant 4.2 — a custodian-guarded entry's custodian equals the custodian it found | yes | **covered** | `A_Inv4_OnlyHolderActs` (acting custodian equals the predecessor's holder); the twin rejects it. |
| Invariant 4.3 — a transferred entry's from custodian equals the custodian it found | yes | **covered** | `A_Inv4_TransferHandToHand`; the twin rejects it. |
| Invariant 4.4 — a transferred entry's to custodian equals the custodian it set | yes | **covered** | `A_Inv4_TransferSetsHolder`; the twin rejects it. `A_Inv4_CustodyUnbroken` states the gap-free form for every link. |
| Invariant 5.1 — two entries in a chain share no sequence number | no | **covered** (by position) | `NoMerging`, `SuccPredInverse`, `A_Linear_AtMostOneSuccessor`/`Predecessor`/`NoBranching`: no two entries occupy a position. Restatements of the facts, so they cannot fail. |
| Invariant 5.2 — a chain's sequence numbers stand from one to the entry count | no | **covered** (by position) | `NoCycles`, `A_Linear_NoCycles`: a path has dense positions. No numbers are modeled. |
| Invariant 5.3 — a chain's order rests on sequence number alone | no | out-of-scope (named reason) | No clock and no instants in the model (header: "Clock semantics … linear position models it"). A claim that a recorded instant does not order the chain needs a model with an instant field next to the number. Owed (b) to the TLA+ model, with Invariant 2.2. |
| Invariant 6.1 — an archived chain does not leave archived | yes | **covered** (static) | `ArchivedTerminal` and `A_Inv6_ArchivedTerminal` (an Archived entry has no successor); the twin rejects it. |
| Invariant 6.2 — an archived chain admits no entry | yes | **covered** (static) | The same: no successor after Archived. |
| Invariant 7.1 — a non-transferred entry's custodian reference is non-blank | no | **covered** | `NonTransferFields` and `A_Inv7_CustodianPresent`. Blank vs non-blank is the presence of the relation; no twin removes it. |
| Invariant 7.2 — a transferred entry's from and to are non-blank | no | **covered** | `TransferFields`, same check. |
| Invariant 8.1 — an entry's event type is in the event types | no | by-construction | The `etype` sig hierarchy. |
| Invariant 8.2 — a genesis entry's event type is a genesis type | no | **covered** | `GenesisTyping`, `A_Inv3_SingleOriginTyping`. |
| Invariant 8.3 — a non-genesis entry's event type is not a genesis type | no | **covered** | The same fact, the "only if" half. |
| Invariant 8.4 — an archived chain's last entry's event type is archived | no | **covered** in part | `ArchivedTerminal` gives Archived-implies-last; the converse, that a chain recorded as archived ends in an Archived entry, needs a chain status the model does not carry. Owed (b), with the chain record. |
| Invariant 10.1 — the chain count does not fall | no | out-of-scope (named reason) | Stepping, and the model holds one chain. Owed to TLA+ (b). |

Out-of-scope residual, named (the model header's own list): clock semantics and `recorded_at` ordering; tamper evidence (Tamper Evidence); custodian identity (Actor Identity); disclosure scope (Selective Disclosure); storage-failure atomicity; multi-store routing and id uniqueness (Identity 15 and 16, deployment).

## Step 3 — bound saturation

Checks run `for 8` (up to eight entries). The facts make a chain a path, so every pattern a longer chain adds repeats a link already seen; the five runs, including `ShowFullLifecycle`, fit well inside eight. A rerun `for 10` is owed to confirm; not run in this pass.

## Outcome

- GAP rows: none on a load-bearing claim of the static model. Invariant 3.3 (a second originate) is load-bearing and has no model construct at all; it is an action claim.
- by-construction flags: Invariant 8.1. Nine rows are restatements of a fact (`A_Linear_*`, `A_Inv3_*`, `A_Inv7_*`): they pass because the fact forces them, and no twin breaks them.
- Owed (step 2 of the coverage unit): **(b)** Invariant 3.3 and 8.4 (an Originate action against a recorded chain, and a chain status); **(c)** none; **(a)** Invariant 5.3's clock half is for Tamper Evidence and Selective Disclosure to check only where it names time, otherwise Provenance's own. **Tool owed** (step 2c and 2d): a TLA+ model for Invariants 1.1, 2.1, 2.2, 3.3, 10.1 (append-only chain under steps). The Alloy file here is static: step 2d's pattern matches it (and its twin) only on the word "after" in comments (lines 189 of the model; 17 and 147 of the twin), no `var`, `always`, `eventually` or temporal `after`, so no stepping claim moves out of it.
- Result: **findings routed** — coverage debt; no English defect.
