# Coverage matrix — `approval-step`

- **Pattern:** `atoms/approval-step.md`
- **Model:** `approval-step.tla` (+ buggy twin `approval-step-buggy.tla`)
- **Reviewer / date:** agent coverage cross-check — 2026-06-03
- **Formal-layer vote load-bearing claims:** Invariant 4 (approver exclusivity), Invariant 5 (submitter exclusivity), Invariant 9 (concurrent step independence)

## Step 1 — harness re-run (must pass)

- Correct model: `node check.mjs ../../atoms/approval-step.tla` → `PASS` ☐ *(per Lineage: 16 states, holds)*
- Buggy twin: `node check.mjs ../../atoms/approval-step-buggy.tla --buggy` → `PASS` (rejected) ☐ *(per Lineage: rejected at 4 states — wrong actor approves s1)*
- 2026-11-10 (unit `tooling: every check has a twin that breaks it`): `audit.mjs` → the model HOLDS and each check has a twin that breaks it — `Inv4_ApproverExclusivity` by `approval-step-buggy-subject.tla` (and `approval-step-buggy.tla`), `Inv5_SubmitterExclusivity` by `approval-step-buggy-withdraw.tla` (withdraw without the submitter guard), `Inv9_StepIndependence` by `approval-step-buggy-subject.tla` (approve keyed by subject). All three twins CAUGHT.

## Step 2 — coverage matrix

The spec has 10 invariants. The model covers the three voted load-bearing claims plus Inv2 (membership exclusivity) and Inv3 (terminal absorption) by construction.

| Spec invariant (no. + name) | Load-bearing (vote)? | Verdict | Model construct / reason |
|---|---|---|---|
| Invariant 1 — Submission immutability | No | `owed` out-of-scope (structural; no field model) | Per model header: "id immutability / no-reuse / store durability / timestamp ordering (Invariants 1,6-8,10 — structural / clock)." Acceptable. |
| Invariant 2 — Membership exclusivity (exactly one state at all times) | No | `owed` held by `TypeOK` only | `TypeOK` constrains `state \in [Steps -> StepStates]`, so each step is always in exactly one named state. No check states it: `TypeOK` is the model's typing, which the twin audit does not count (2026-11-10); a check with a twin that writes a fifth state is owed. |
| Invariant 3 — Terminal absorption | No | `owed` by-construction | Every action (`Approve`, `Reject`, `Withdraw`) guards `state[s] = "Pending"`; once a step transitions to Approved/Rejected/Withdrawn no further transitions apply. Per model note explicitly. Acceptable: not load-bearing per vote. |
| Invariant 4 — Approver exclusivity | YES | `checked` covered | `Inv4_ApproverExclusivity == ∀ s ∈ Steps : state[s] ∈ {"Approved","Rejected"} ⇒ decidedBy[s] = approver[s]`; all three actors quantified over in `Next`, so any actor able to incorrectly approve would be caught. Broken by `approval-step-buggy-subject.tla`, `approval-step-buggy.tla`. |
| Invariant 5 — Submitter exclusivity | YES | `checked` covered | `Inv5_SubmitterExclusivity == ∀ s ∈ Steps : state[s] = "Withdrawn" ⇒ decidedBy[s] = submitter[s]`. Broken by `approval-step-buggy-withdraw.tla`. |
| Invariant 6 — Decision attribution complete for terminal steps | No | `owed` out-of-scope (field model not present; structural/clock per model header) | Acceptable: not load-bearing per vote. Note: `decidedBy` is modeled as a partial proxy for this but the non-whitespace and timestamp requirements are not checked. |
| Invariant 7 — Temporal ordering (`decided_at ≥ submitted_at`) | No | `owed` out-of-scope (no clock modeled; per model header) | Acceptable. |
| Invariant 8 — Submission attribution complete | No | `owed` out-of-scope (structural; per model header) | Acceptable. |
| Invariant 9 — Concurrent step independence | YES | `checked` covered (promoted 2026-07-12) | `Inv9_StepIndependence`: each action snapshots the other step's pre-action `state`/`decidedBy` (`lastOther`, `preState`, `preDecided`) and the check asserts the untouched step still carries it. A frame property, but a realistic defect breaks it: an approve keyed by subject rather than by step (`WHERE subject_ref = X`) resolves every pending step on the subject (2026-11-10). Broken by `approval-step-buggy-subject.tla`. |
| Invariant 10 — Step store durability | No | `unstatable` out-of-scope (structural; per model header) | Acceptable. |

## Step 3 — bound saturation

Per Lineage: 2 steps (`s1`, `s2`), 3 actors (`a1`, `a2`, `a3`) → 16 reachable states. Two steps is the minimum to exercise concurrent independence; three actors ensures that quantifying over all actors in `Next` would expose any actor authorized to act who should not be. Bound appears adequate.

## Outcome

- GAP rows: none
- by-construction flags on load-bearing invariants: **Invariant 9 (concurrent step independence) — load-bearing per vote, held by-construction (TLA+ frame property) rather than explicit state predicate.** The frame is a sound argument but a dedicated check would make independence explicit, e.g., `Inv9_Independence == ∀ s ∈ Steps : state[s] = decidedBy[s] = ...` is not the right form, but something like: after each action on `s`, assert `∀ s2 ∈ Steps \ {s} : state[s2] = state_before[s2]`. Flag for consideration.
- Result: **one by-construction flag on load-bearing Inv9** — no hard GAPs. Pattern is otherwise clean. The Inv9 by-construction argument is sound given how TLA+ frames work, but promotion to an explicit invariant would strengthen the formal surface.
