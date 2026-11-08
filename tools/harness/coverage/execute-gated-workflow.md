# Coverage matrix — `execute-gated-workflow`

- **Pattern:** `compositions/execute-gated-workflow.md`
- **Model:** `execute-gated-workflow.tla` + ten buggy twins, `execute-gated-workflow-buggy.tla`, `-buggy-reuse`, `-buggy-unmooted`, `-buggy-unmarked`, `-buggy-mispaired`, `-buggy-decision-join`, `-buggy-unrecorded`, `-buggy-unbounded-sweep`, `-buggy-norecall`, `-buggy-second-outcome` (each `.tla` with its `.cfg`)
- **Reviewer / date:** the model's author, the session that landed it — 2026-11-08. Not a fresh-context read; the next scheduled rescan owes one.
- **Formal-layer vote load-bearing claims:** the vote was cast yes in 2026-06 and the model re-derived 2026-11-08 over what the Ledger's `formal:` line named (the mooted mark, the horizon-bounded consumption arm, the sweep's recovery record and age bound, leg (4)'s decision-matched join). The model takes every composition-level Invariant the page states as load-bearing except the three that are single-call refusals: Invariant 1 (one firing per approval, gated on a live approval), 3 (every act carries exactly one outcome), 4 (assignment coverage), 6 (the process proof).

## Step 1 — harness re-run (must pass)

- Correct model: `node check.mjs ../../compositions/execute-gated-workflow.tla` → `HOLDS` ✓ *(66,525 states)*
- Buggy twins: each `node check.mjs ../../compositions/execute-gated-workflow-<twin>.tla --buggy` → `CAUGHT` ✓ *(see Step 2 for the check that finds each)*

## Step 2 — coverage matrix

The model has one workflow with two guarded transitions out of s0 (g1, g2), an unguarded way back from s1 to s0, up to three Approval Steps, up to two guarded firings, and at most two refused writes (an outcome event, a cascade call or a decision attempt the callee refused). The invocation is one transaction (Execution Contract Store 1 and 2); the sweep's four legs are the other process. Fifteen named invariants, all in the `.cfg`.

| Spec invariant (no. + name) | Load-bearing (vote)? | Verdict | Model construct / reason |
|---|---|---|---|
| Invariant 1.1 — a quiescent workflow's guarded entries carry a firing event naming an approved step | YES | **covered** | `Invariant_1_1` (the step is Approved and was decided before the firing). Twins `-buggy` (the guard is the caller's word, Wiring decision 1 and 2) and `-buggy-mispaired` (the firing leg pairs to the latest unmatched intent, Reconciliation 12) are rejected by it. |
| Invariant 1.2 — two firing events never carry one step id | YES | **covered** | `Invariant_1_2`. |
| Invariant 1.3 — no firing event names a step a moot record named earlier | YES | **covered** | `Invariant_1_3`; twin `-buggy-unmarked` (the cascade sets no mooted mark, so a mooted approval is held only by records the horizon purges) is rejected by it. |
| Invariant 1 (heading) — one firing per approval | YES | **covered** | `Invariant_1_OneFiringPerApproval`, read from the fire intents, which a purged firing event cannot weaken. Twin `-buggy-reuse` (the consumption rule's history arm stops at the horizon, Wiring decision 3 and 5) is rejected by it. |
| Invariant 2.1 through 2.3 — permission-gated advancement | no | out-of-scope (single-call refusals owned by Permissions, whose model checks them; no sequence of them reorders a firing) | — |
| Invariant 3.1 — a quiescent workflow's committed acts each carry exactly one outcome | YES | **covered** | `Invariant_3_1` (a firing event per history entry, an opening event per step, a decision event per decided step). Twin `-buggy-second-outcome` (the decision leg does not first read whether the event has landed) is rejected by it. |
| Invariant 3.2 — every moot cascade entry carries exactly one moot record | YES | **covered** | `Invariant_3_2`. |
| Invariant 3.3 — every outcome names a workflow the workflow records carry | no | by-construction (the model has one workflow, so every event names it) | — |
| Invariant 4.1 — a pending bound step carries one active assignment | YES | **covered** | `Invariant_4_1`. |
| Invariant 4.2 — a settled step carries no active assignment | YES | **covered** | `Invariant_4_2`; twin `-buggy-norecall` (the cascade withdraws without recalling, Cascade 4) is rejected by it. |
| Invariant 5.1, 5.2 — only declared transitions | no | out-of-scope (State Machine's own model checks it; the model's two transitions are the declared ones) | — |
| Invariant 6.1 — the process proof resolves | YES | **covered** | `Invariant_6_1` is Invariant 1.1 and 3.1 together, which is what the Term process proof names that the model carries (attribution and sealing are Audit Trail's). |
| Invariant 8.1 through 8.4 — authentication precedes commitment | no | out-of-scope (the credential check is a single call before any write, Audit Trail's; no model step writes before it) | — |
| Wiring decision 4 — the mooting rule | YES | **covered** | `Wiring_decision_4_MootedNeverFires` (a step a committed firing's plan names never clears a later firing, whatever has landed of the cascade). Twin `-buggy-unmooted` (the mooting rule leaves out the fire intent's plan) is rejected by it. |
| Wiring decision 3, 5 — a fresh approval is live | no | **covered** | `Wiring_decision_3_FreshApprovalLive`: no entry from before a step was submitted, aged or not, makes it read as consumed. |
| Wiring decision 7, 9 — re-bind over a spent step, marks blank | no | **covered** | `OpenGate` takes `Rebindable` (Rejected, Withdrawn, or Approved and spent) and writes both marks FALSE for the new step; the re-fire scenarios rest on them (twins `-buggy-reuse`, `-buggy-mispaired`). |
| Reconciliation 5 — the sweep does not examine an aged record | no | **covered** | `Reconciliation_5_SweepStaysInsideHorizon`; twin `-buggy-unbounded-sweep` (the decision leg lands the event of a step decided past the horizon) is rejected by it. |
| Reconciliation 8 — no sweep write before its recovery record lands | no | **covered** | `Reconciliation_8_RecoveryFirst`; twin `-buggy-unrecorded` (the legs write no recovery record) is rejected by it. |
| Reconciliation 18 through 20 — the decision leg joins on the step's own decision | no | **covered** | `Reconciliation_19_DecisionMatchesStep` (a decision event names the intent whose decision and instant are the step's). Twin `-buggy-decision-join` (the leg joins on the step alone) is rejected by it. |
| Reconciliation 15 through 17, 31 — the opening leg; Reconciliation 24 through 26 — candidates; findings | no | out-of-scope (an opening is one transaction that lands its event, binding and assignment; the model's instants all differ, so two intents never pair to one record; findings write nothing the invariants read) | — |
| Composition state 9 through 15 — the four derived indexes and their rebuild | no | out-of-scope (a lost entry is a rebuild trigger and never a relation violation, the invariants section's own sentence) | — |
| Capability requirement 3 — the longest workflow lifetime does not exceed the audit horizon | no | **covered as an assumption** | The correct model's configuration is Life = Horizon. Twins `-buggy-reuse` and `-buggy-unmarked` run Life above Horizon on purpose. One reading with it off, recorded as the open line 2026-11-08-a: the mooting rule has no aged arm, so an approval held mooted only by an owed cascade's fire intent reads as live again once that intent is purged. |

## Step 3 — bound saturation

Raise the model's scope once and confirm the verdict does not change:

- At the shipped bound (Life 6, Horizon 6, MaxClk 8, two refused writes, two firings, three steps): 66,525 states, all fifteen invariants hold.
- At three refused writes and Horizon 7: 158,677 states, the same verdict. The count grows with the fault budget (each refusal adds states), so the state space is **not saturated** in count; no violation appeared in the larger space, and the twins that need a second refusal (`-buggy-mispaired`, two owed firings on one gate key) are found within the shipped bound. A third firing and a fourth step were not run: the run took about 14 minutes at the shipped bound and the cycle (open, decide, fire, back) repeats the same two-firing step twice already.

## Outcome

- GAP rows: **none**.
- by-construction flags on load-bearing invariants: none (Invariant 3.3's one-workflow model is by construction, and it is not load-bearing for the vote).
- Result: **all Invariants covered** — 2026-11-08. *Lineage entry: "Coverage cross-check 2026-11-08 — clean (every composition-level Invariant covered by a named check or out of scope with its reason; ten twins each rejected by a named check)."*
