# Coverage matrix — `session-gated-authorization`

- **Pattern:** `compositions/session-gated-authorization.md`
- **Model:** `session-gated-authorization.als` (Alloy: a static structural model and a dynamic Alloy 6 trace model; no TLA+ model, no buggy twin)
- **Reviewer / date:** mayor, from the page at 7f57305 and the model as it stands — 2026-11-10 (unit `formal: more coverage for the yes votes`, step 1; the page had no matrix)
- **Formal-layer vote load-bearing claims:** the Ledger reads `formal: verified — session-gated-authorization.als, no twin, 2026-06-03`; the model header names the four invariants and three temporal claims: T1 revocation is terminal, T2 expiry is terminal, T3 the gate reflects the session's current status.

## Step 1 — harness run

- Correct model: `node check.mjs ../../compositions/session-gated-authorization.als` → `HOLDS` ✓ (2026-11-10, JRE 17; every check holds, every run satisfiable).
- Buggy twin: none. The Ledger says "no twin"; the model's header records why: Alloy facts are file-global, so a "without Invariant 2" check collapses into the same proposition (Round 6, 2026-05-23).

## Step 2 — coverage matrix

One row per numbered rule of *Composition-level invariants*, plus the action wiring rules that carry a security claim the invariants do not restate.

| Spec claim | Load-bearing (vote)? | Verdict | Model construct / reason |
|---|---|---|---|
| Invariant 1.1 — no `permitted` call without a valid `validate` answer | yes | by-construction (static), **covered** (trace, in part) | `fact Invariant1_Session_Gates_Authorization` forces a Permitted or Denied outcome to carry a Valid resolved session and a gate principal. It is a fact, not a check, so no counterexample can be asked of it. The trace model's `Dyn_Gate_Reflects_Current_Status` asserts the outcome against the session's status at the step of the call, for Revoked and Expired; the Valid side (a call on a Valid session answers Permitted or Denied) is left to the `run`s, not asserted. |
| Invariant 2.1 — every subject `permitted` receives equals the valid answer's principal | yes | by-construction | `fact Invariant2_Principal_Binding`; `Principal_Binding_Holds` is the same proposition as the fact, so it can never fail (the model's own header says so: the "without" check was dropped in Round 6). A restatement, not a check. |
| Invariant 2.2 — no principal reference beside the session's own | yes | out-of-scope (named reason) | A rule about what the composition may *query*; the model has one `gate_principal` per call and no caller-supplied principal field, so the rule is true by the schema and a regression that adds one is not catchable. Same shape as Action wiring 7 and 8. |
| Invariant 3.1 — a denied answer follows an admitted gate | yes | **covered** (static) | `fact Invariant4_Default_Deny` requires `some c.gate_principal` for Denied; `fact Invariant1_…` requires a Valid resolved session for Permitted or Denied. Both facts. No check names 3.1. |
| Invariant 3.2 — a session-invalid answer does not follow an admitted gate | yes | **covered** (static) | `Denial_Is_Not_Rejection` (`no (Denied & RejectedSessionInvalid)`), which holds by the sig hierarchy; `fact Invariant1_…` gives a blocked call no gate principal. |
| Invariant 3.3 — no denied answer for a session `validate` answered invalid for | yes | **covered** | `Revoked_Session_Cannot_Authorize` and `Expired_Session_Cannot_Authorize` (a Revoked or Expired resolved session forces RejectedRevoked or RejectedExpired, never Denied) on the static side; `Dyn_Gate_Reflects_Current_Status` on the trace side. Not-known: `fact Outcome_Coherence` (no resolved session and not an invalid request forces RejectedNotKnown); no check. |
| Invariant 4.1 — an admitted gate answers denied for a pair no active grant covers | yes | **covered** | `Valid_Session_No_Grant_Is_Denied` (Valid session, no Active grant for the pair, outcome is not Permitted) over `fact Invariant4_Default_Deny`. Both directions are facts; the assertion is the Permitted direction. |
| Invariant 4.2 — a valid session is not sufficient for access | yes | **covered** | The same assertion; `run has_same_principal_mixed_outcomes` shows one principal with both Permitted and Denied outcomes. |
| Action wiring 14 — no read of a validate answer a prior call received | yes (the Session Composition note 4 half of the gate) | **GAP** (trace) → owed (b) | `dyn_check_permitted` resolves the session from the *current* store at the step of the call, so the model never carries an answer from one call to the next: the claim is true by the model's shape, and a defect that caches an answer is not representable. A twin that serves the call from a cached answer, and an invariant that a call after a revoke gets RejectedRevoked, would test it. `Dyn_Gate_Reflects_Current_Status` states the invariant; no twin breaks it. |
| Action wiring 15 — `check_permitted` does not write | no | **covered** (trace) | `dyn_check_permitted` frames every session status and every grant status unchanged and grows the call log by exactly one record. |
| Temporal T1 — revocation terminal | yes | **covered** (trace) | `Dyn_Revocation_Terminal`. |
| Temporal T2 — expiry terminal | yes | **covered** (trace) | `Dyn_Expiry_Terminal`. |

Out-of-scope residual, named: the boundary predicate (Action wiring 1 and 2, the Length Bound term) is not modeled; a blank or oversize input is `RejectedInvalidRequest`, and the model states only that such a call has no resolved session and no gate principal. Concurrency (a session revoked between `validate` and `permitted` inside one call) is the page's *Edge cases / Concurrency* section and is not an interleaving the model asks.

## Step 3 — bound saturation

The static checks run `for 5`; the trace checks `for 3 but 1..8 steps` (three sessions, tokens and scopes, eight steps). Not re-measured in this pass: Alloy reports the set of satisfying worlds, not a reachable-state count, so a saturation figure is a scope increase and a rerun, owed with the TLA+ model.

## Outcome

- GAP rows: Action wiring 14 (a cached `validate` answer is not representable), owed as a twin.
- by-construction flags on load-bearing claims: Invariant 1.1 and 2.1 are facts, not checks; 2.1's check restates its fact. Recorded as assumptions; the TLA+ model below would state both as invariants over a step relation a twin can break.
- Owed (step 2 of the coverage unit): **(b) the model left it out for cost or size** — Action wiring 14, the cached answer. **Tool owed** (step 2c, 2d): the model is in Alloy only and its trace claims T1, T2, T3 use `var`, `always` and `after`; the stepping claims are owed to a TLA+ model, and the Alloy file keeps its static checks.
- Result: **findings routed** — one row owed (Action wiring 14) and one tool owed (TLA+). Coverage cross-check 2026-11-10 — no defect in the English; the model is coverage debt only.
