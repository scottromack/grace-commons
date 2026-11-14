# Coverage matrix — `approval-step`

- **Pattern:** `atoms/approval-step.md`
- **Model:** `approval-step.tla` (+ 3 buggy twins: `approval-step-buggy.tla`, `-subject`, `-withdraw`) and `approval-step.als`, the static data model (+ 10 buggy twins `approval-step-buggy-<defect>.als`, 2026-11-11)
- **Reviewer / date:** agent coverage cross-check — 2026-06-03
- **Formal-layer vote load-bearing claims:** Invariant 4 (approver exclusivity), Invariant 5 (submitter exclusivity), Invariant 9 (concurrent step independence)

## Step 1 — harness re-run (must pass)

- Correct model: `node check.mjs ../../atoms/models/approval-step.tla` → `PASS` ☐ *(per Lineage: 16 states, holds)*
- Buggy twin: `node check.mjs ../../atoms/models/approval-step-buggy.tla --buggy` → `PASS` (rejected) ☐ *(per Lineage: rejected at 4 states — wrong actor approves s1)*
- 2026-11-10 (unit `tooling: every check has a twin that breaks it`): `audit.mjs` → the model HOLDS and each check has a twin that breaks it — `Inv4_ApproverExclusivity` by `approval-step-buggy-subject.tla` (and `approval-step-buggy.tla`), `Inv5_SubmitterExclusivity` by `approval-step-buggy-withdraw.tla` (withdraw without the submitter guard), `Inv9_StepIndependence` by `approval-step-buggy-subject.tla` (approve keyed by subject). All three twins CAUGHT.
- 2026-11-11 (unit `atoms/approval-step.md formal layer`): `approval-step.als` added, the page's static data model: one step record as [Submit] leaves it, or as one admitted resolve leaves it over that (Operation 13 and 36 allow no other history; that it has none is Invariant 3's, the TLA+ model's). `node check.mjs ../../atoms/models/approval-step.als` → `HOLDS` (22 commands: 12 checks UNSAT, 10 runs SAT), at `for 4 but 3 Step, 2 SubmitCall, 2 ResolveCall`. Ten twins, one defect each, each `CAUGHT`: `-state-added`, `-approver-unguarded`, `-submitter-unguarded`, `-actor-not-written`, `-instant-misfiled`, `-reason-unguarded`, `-backdated`, `-blank-scope`, `-instant-unresolved`, `-stray-attribution`. The one fact is the host's non-blank step id (Execution Contract Input 2); every Invariant is checked, none assumed.

## Step 2 — coverage matrix

The spec has 10 invariants. The model covers the three voted load-bearing claims plus Inv2 (membership exclusivity) and Inv3 (terminal absorption) by construction.

| Spec invariant (no. + name) | Load-bearing (vote)? | Verdict | Model construct / reason |
|---|---|---|---|
| Invariant 1 — Submission immutability | No | `owed` (TLA+: across steps) | Nothing testable in Alloy (2026-11-11): it compares a record with a later version of it. `approval-step.tla` models no submission field, so a TLA+ check with a twin that rewrites one is owed. |
| Invariant 2 — Membership exclusivity (exactly one state at all times) | No | `checked` covered (Alloy, 2026-11-11) | `A_Invariant_2_1` in `approval-step.als`: every recorded step carries exactly one state. The record's state is a set of state flags, so the type does not promise it; [Submit] writes pending and each resolve replaces it. Broken by `approval-step-buggy-state-added.als` ([Approve] adds approved beside pending). The TLA+ model's `TypeOK` still holds it there by typing only. |
| Invariant 3 — Terminal absorption | No | `owed` by-construction (TLA+: across steps; nothing testable in Alloy, 2026-11-11) | Every action (`Approve`, `Reject`, `Withdraw`) guards `state[s] = "Pending"`; once a step transitions to Approved/Rejected/Withdrawn no further transitions apply. Per model note explicitly. Acceptable: not load-bearing per vote. |
| Invariant 4 — Approver exclusivity | YES | `checked` covered | `Inv4_ApproverExclusivity == ∀ s ∈ Steps : state[s] ∈ {"Approved","Rejected"} ⇒ decidedBy[s] = approver[s]`; all three actors quantified over in `Next`, so any actor able to incorrectly approve would be caught. Broken by `approval-step-buggy-subject.tla`, `approval-step-buggy.tla`. Cross-checked in Alloy (2026-11-11): `A_Invariant_4_1`, `A_Invariant_4_2`, broken by `approval-step-buggy-approver-unguarded.als` (Operation 21 dropped). |
| Invariant 5 — Submitter exclusivity | YES | `checked` covered | `Inv5_SubmitterExclusivity == ∀ s ∈ Steps : state[s] = "Withdrawn" ⇒ decidedBy[s] = submitter[s]`. Broken by `approval-step-buggy-withdraw.tla`. Cross-checked in Alloy (2026-11-11): `A_Invariant_5_1`, broken by `approval-step-buggy-submitter-unguarded.als` (Operation 22 dropped). |
| Invariant 6 — Decision attribution complete for terminal steps | No | `checked` covered (Alloy, 2026-11-11) | `A_Invariant_6_1` (attribution reference non-blank), `A_Invariant_6_2` (the terminal state's instant carried), `A_Invariant_6_3` (rejected: decision reason non-blank), `A_Invariant_6_4` (withdrawn: withdrawal reason non-blank). Broken by `approval-step-buggy-actor-not-written.als` (6.1), `approval-step-buggy-instant-misfiled.als` (6.2), `approval-step-buggy-reason-unguarded.als` (6.3, 6.4). |
| Invariant 7 — Temporal ordering (`decided_at ≥ submitted_at`) | No | `checked` covered (Alloy, 2026-11-11) | `A_Invariant_7_1`: no terminal instant precedes the submission instant; the clock is not assumed to run forward (Non-goal 22), so Operation 19's guard holds it. `ShowDecidedAtTheSubmissionInstant` shows the equal case admitted. Broken by `approval-step-buggy-backdated.als` (Operation 19 dropped). |
| Invariant 8 — Submission attribution complete | No | `checked` covered (Alloy, 2026-11-11) | `A_Invariant_8_1` (step id, subject, approver, submitter references and scope non-blank; the step id from the fact `HostAllocatesANonBlankId`, Execution Contract Input 2, since no guard of the page reads it on [Submit]), `A_Invariant_8_2` (a submission instant carried; a blank one resolves to now). Broken by `approval-step-buggy-blank-scope.als` (8.1, Operation 4 dropped), `approval-step-buggy-instant-unresolved.als` (8.2). |
| Invariant 9 — Concurrent step independence | YES | `checked` covered (promoted 2026-07-12) | `Inv9_StepIndependence`: each action snapshots the other step's pre-action `state`/`decidedBy` (`lastOther`, `preState`, `preDecided`) and the check asserts the untouched step still carries it. A frame property, but a realistic defect breaks it: an approve keyed by subject rather than by step (`WHERE subject_ref = X`) resolves every pending step on the subject (2026-11-10). Broken by `approval-step-buggy-subject.tla`. |
| Invariant 10 — Step store durability | No | `unstatable` out-of-scope (structural; per model header) | Acceptable. |
| State 13 — a pending step carries no attribution field (Check 5.1) | No | `checked` covered (Alloy, 2026-11-11) | `A_State_13`: [Submit] sets the submission fields only (Term submission field) and every resolve leaves the step terminal. Broken by `approval-step-buggy-stray-attribution.als` ([Submit] stamps a decision instant). |

## Step 3 — bound saturation

Per Lineage: 2 steps (`s1`, `s2`), 3 actors (`a1`, `a2`, `a3`) → 16 reachable states. Two steps is the minimum to exercise concurrent independence; three actors ensures that quantifying over all actors in `Next` would expose any actor authorized to act who should not be. Bound appears adequate.

Alloy (2026-11-11): `approval-step.als` checks at `for 4 but 3 Step, 2 SubmitCall, 2 ResolveCall` (four strings and four instants, enough for distinct actors, a blank one, and an instant before, at and after a submission). Raised once to `for 5 but 4 Step, 3 SubmitCall, 3 ResolveCall` on a scratch copy: the same verdicts, 12 checks UNSAT and 10 runs SAT. A copy without the fact `HostAllocatesANonBlankId` breaks `A_Invariant_8_1` alone: the step id's non-blankness rests on Execution Contract Input 2, not on a guard of the page.

## Outcome

- GAP rows: none
- 2026-11-11: Invariant 2, 6, 7, 8 and State 13 move from `owed` to `checked` (Alloy). Owed now: Invariant 1 and Invariant 3, both across steps, to the TLA+ model.
- by-construction flags on load-bearing invariants: **Invariant 9 (concurrent step independence) — load-bearing per vote, held by-construction (TLA+ frame property) rather than explicit state predicate.** The frame is a sound argument but a dedicated check would make independence explicit, e.g., `Inv9_Independence == ∀ s ∈ Steps : state[s] = decidedBy[s] = ...` is not the right form, but something like: after each action on `s`, assert `∀ s2 ∈ Steps \ {s} : state[s2] = state_before[s2]`. Flag for consideration.
- Result: **one by-construction flag on load-bearing Inv9** — no hard GAPs. Pattern is otherwise clean. The Inv9 by-construction argument is sound given how TLA+ frames work, but promotion to an explicit invariant would strengthen the formal surface.
