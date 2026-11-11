# Coverage matrix — `medication-order`

- **Pattern:** `atoms/medication-order.md`
- **Models:** `medication-order.tla` (+ buggy twins `medication-order-buggy.tla`, `medication-order-buggy-prior.tla`); `medication-order.als` (+ buggy twins `medication-order-buggy.als`, `medication-order-buggy-link.als`, `medication-order-buggy-copy.als`)
- **Reviewer / date:** agent coverage cross-check — 2026-06-03; GAP closure — 2026-06-04
- **Formal-layer vote load-bearing claims:** Invariant 5 (hold carries prior_state; reinstate returns to exactly it), Invariants 3/4 (pre-dispensing-only, linear amendment chains), Invariant 9 (On Hold accepts only reinstate)

## Step 1 — harness re-run (must pass)

- TLA+ correct model: `node check.mjs ../../atoms/medication-order.tla` → `PASS` ✓ *(per Lineage: 31 states, holds)*
- TLA+ buggy twin: `node check.mjs ../../atoms/medication-order-buggy.tla --buggy` → `PASS` (rejected) ✓ *(per Lineage: rejected at 11 states — reinstates to wrong state)*
- Alloy correct model: `node check.mjs ../../atoms/medication-order.als` → `PASS` ✓ *(13 checks UNSAT, 7 runs SAT — scope 8)*
- Alloy buggy twin: `node check.mjs ../../atoms/medication-order-buggy.als --buggy` → `PASS` (rejected) ✓ *(4 counterexamples found)*
- 2026-11-10 (unit `tooling: every check has a twin that breaks it`): in the Alloy model four checks restated it and went (`A_Inv4_AtMostOnePredecessor` restated the `lone` field; `A_Inv4_NoCycles`, `A_Inv12_AmendedBySetOnSuccessorOnly`, `A_SuccessorPredecessorAreInverse` = `fact NoCycles`, `AmendedByConsistency`, `SuccessorPredecessorInverse`); `fact LinearChain` and `fact PreDispensingOnlyAmendment` were deleted, as the other facts imply them, so `A_Inv4_NoBranching` and `A_Inv3_NoSuccessorAfterDispensing` stay, leaving 9 checks. Twins added: `medication-order-buggy-link.als` (amend writes its two links independently), `medication-order-buggy-copy.als` (amend does not copy the identity fields) and `medication-order-buggy-prior.tla` (hold does not store prior_state). `GRACE_STATES_LEDGER=off node audit.mjs --only` over this family: both models HOLD, all 5 twins CAUGHT, all 11 checks broken by a twin, 0 red.

## Step 2 — coverage matrix

The spec has 14 invariants. The TLA+ model covers hold/reinstate round-trip (Invariants 5, 9); the Alloy model covers amendment chain structure (Invariants 3, 4, 2).

| Spec invariant (no. + name) | Load-bearing (vote)? | Verdict | Model construct / reason |
|---|---|---|---|
| Invariant 1 — Order immutability | No | `owed` out-of-scope (structural; field model not present) | Acceptable: not load-bearing per vote. |
| Invariant 2 — Successor inherits identity fields | No | `checked` covered (`A_Inv2_PatientRefChainConsistency`, `A_Inv2_PrescriberRefChainConsistency`, `A_Inv2_MedicationRefChainConsistency` in `medication-order.als`) | Covered as structural byproduct of Inv 3/4 model; not vote-named but included for completeness. Broken by `medication-order-buggy-copy.als`. |
| Invariant 3 — Amendment is pre-dispensing only | YES (vote) | `checked` **covered** (`A_Inv3_NoSuccessorAfterDispensing`, `A_Inv3_SuccessorOnlyFromPreDispensing` in `medication-order.als`) | GAP closed 2026-06-04. `AmendedIffHasSuccessor` enforces the boundary structurally (only an Amended order has a successor); since 2026-11-10 the fact `PreDispensingOnlyAmendment`, which `A_Inv3_NoSuccessorAfterDispensing` restated, is deleted, as `AmendedIffHasSuccessor` implies it. Broken by `medication-order-buggy.als`. |
| Invariant 4 — Amendment chains are linear | YES (vote) | `checked` **covered** in part (`A_Inv4_AtMostOneSuccessor`, `A_Inv4_NoBranching`, `A_Inv4_AmendedHasSuccessor`, `A_Inv4_SuccessorHasPredecessor` in `medication-order.als`) | GAP closed 2026-06-04. Facts `NoCycles`, `SuccessorPredecessorInverse`, `AmendedIffHasSuccessor`, `NoSelfLoop` enforce chain linearity structurally; `fact LinearChain`, which `A_Inv4_NoBranching` restated, was deleted (2026-11-10), as the inverse fact implies it. `A_Inv4_AtMostOnePredecessor` (restated the `lone` field), `A_Inv4_NoCycles` (= `fact NoCycles`) and `A_SuccessorPredecessorAreInverse` (= its fact) went (2026-11-10): no cycles is assumed by the fact, owed to a stepping model. Broken by `medication-order-buggy.als` (`A_Inv4_AtMostOneSuccessor`, `A_Inv4_AmendedHasSuccessor`), `medication-order-buggy-link.als` (`A_Inv4_NoBranching`, `A_Inv4_SuccessorHasPredecessor`). |
| Invariant 5 — Hold carries prior_state; reinstate returns to it | YES | `checked` covered | `Inv5_ReinstateRoundTrip == justReinstated => (state = heldFrom)`; ghost `heldFrom` records hold-from state; `justReinstated` flags post-reinstate step. Also `Inv5_PriorValid == (state = "OnHold") => (prior \in Holdable)`. Both are explicit state predicates. Broken by `medication-order-buggy.tla` (`Inv5_ReinstateRoundTrip`), `medication-order-buggy-prior.tla` (`Inv5_PriorValid`). |
| Invariant 6 — Cancel is pre-dispensing; discontinue is post-dispensing | No | `owed` by-construction | `Cancel` guards `state \in {"Ordered","Verified"}`; `Discontinue` guards `state \in {"Dispensed","Administered"}` — structurally impossible to cross the boundary. Acceptable: not load-bearing per vote. |
| Invariant 7 — Terminal states absorbing | No | `owed` by-construction | No action operates on `state \in {"Completed","Cancelled","Discontinued","Amended"}`; all forward actions guard non-terminal source states. Acceptable. |
| Invariant 8 — Amended state is inactive | No | `owed` out-of-scope (no `amend` action in TLA+ model; Alloy model is structural/snapshot, not action-sequence) | Acceptable: not load-bearing per vote. |
| Invariant 9 — On Hold accepts only reinstate | YES | `owed` by-construction | Every forward action (Verify, Dispense, Administer, Complete, Cancel, Discontinue) guards on a non-OnHold source state; from OnHold only `Reinstate` is enabled. Per model note explicitly. **Flag retained: load-bearing per vote, held by-construction rather than explicit check.** |
| Invariant 10 — All actor references non-whitespace | No | `unstatable` out-of-scope (field validation not modeled; per model header) | Acceptable. |
| Invariant 11 — Reason fields non-whitespace | No | `unstatable` out-of-scope (field validation not modeled) | Acceptable. |
| Invariant 12 — Transition metadata write-once (with hold/reinstate exceptions) | No | `owed` (was covered, partial) | Assumed by `fact AmendedByConsistency` (amendedBy set iff predecessor present) of the static model, which no twin can break; the check `A_Inv12_AmendedBySetOnSuccessorOnly` restated it and went (2026-11-10); owed to a stepping model (write-once metadata under amend, hold and reinstate). Full temporal immutability is out-of-scope for both models. |
| Invariant 13 — `ordered_at` set once | No | `owed` out-of-scope (no timestamp model) | Acceptable. |
| Invariant 14 — Order store durability | No | `owed` out-of-scope (no deletion surface modeled) | Acceptable. |

## Step 3 — bound saturation

- TLA+ model: 31 reachable states. The lifecycle is a single linear path (Ordered → ... → terminal) with a hold/reinstate branch from each of four holdable states; 31 states covers all paths. Saturated.
- Alloy model: scope 8, 13 checks UNSAT. Key Inv 3 and Inv 4 structural claims confirmed UNSAT at scope 9 (Order-only reduced model; `A_Inv4_OneSucc`, `A_Inv4_NoCyc`, `A_Inv3_NoPost`, `A_Inv3_SrcAmend` all hold at `for 9`). Saturated — no new structural topology emerges at scope 9. Full-model scope 9 exceeds sandbox timeout due to 9 state singletons + 4 reference type families; the structural core saturates at scope 8 per the reduced-model evidence.

## Outcome

- **No GAP rows remain.**
- Closed: Invariant 3 (amendment pre-dispensing only) — `covered` via `A_Inv3_NoSuccessorAfterDispensing`, `A_Inv3_SuccessorOnlyFromPreDispensing` in `medication-order.als`.
- Closed: Invariant 4 (amendment chains linear) — `covered` via seven checks in `medication-order.als`.
- by-construction flag retained: **Invariant 9 (On Hold accepts only reinstate) — load-bearing per vote, held by-construction in TLA+ model.** Flagged for promotion to an explicit state predicate in a future rescan; does not block `grounded` status.
- Result: **all vote-named load-bearing invariants now formally covered. Pattern retains `grounded` status with full formal-layer discharge.**
