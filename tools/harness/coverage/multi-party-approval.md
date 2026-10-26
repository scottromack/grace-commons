# Coverage matrix — Multi-Party Approval

> Formal-layer **coverage cross-check** (the section titled *The coverage cross-check* in pressure-testing.md).
> First emitted 2026-10-26 with the page's first model. The formal-layer vote of 2026-06-03 was yes,
> and no model was on disk until this one (the Ledger's formal line had read *pending*).

- **Pattern:** `compositions/multi-party-approval.md`
- **Models:** `multi-party-approval.tla` (one chain, its quorum, its cascade, the sweep's retry and the initiation leg) + `-buggy-steplist`, `-buggy-trailing`, `-buggy-closure`, `-buggy-oob`, `-buggy-split`, `-buggy-shortshape`, `-buggy-norecall`, `-buggy-unstaffed` + probes `-probe-residue`, `-probe-trailing`, `-probe-superseded`, `-probe-recoveryclosed`, `-probe-shortterminal`, `-probe-approved`, `-probe-outofband`
- **Reviewer / date:** the model's author, the settling session of Final Critique 12 (the mayor) — 2026-10-26. Not a fresh-context read; the next scheduled rescan owes one.
- **Formal-layer vote load-bearing claims:** quorum determinism split by terminal path (Invariant 2), bypass resistance (no chain Approved without the quorum's routed decisions; the paragraph after the invariants), chain completeness with the recovery's closure (Invariant 1), assignment coverage at quiescence (Invariant 4), terminal absorption (Invariant 7), and the partial cascade's closure (Reconciliation 26, 30; Check 5.4).
- **Layering:** no model imports another. Approval Step enters as its contract — a step decides once, from Pending, by its approver or its submitter, and refuses a second decision not-pending (its Invariant 3, 4, 5, proved in `atoms/approval-step.tla`); a cascade withdrawal may meet its temporal invalid-request. Assignment enters as recall answering ok on an Active assignment and not-active on a Recalled one (its own model, `atoms/assignment.tla`). Audit Trail's events land with their action (Execution Contract Database 1); its refusals are not modelled but the initiation-failed record's.

## Step 1 — harness run (must pass)

- `multi-party-approval.tla` → `HOLDS` ✓ *(104,207 states, every state explored inside the harness's cap of 200,000; N = 3 approver slots, the quorum rule chosen in the initial state over [All Of N] and [M Of N] with M = 1, 2, 3)*
  - `-buggy-steplist` → `CAUGHT` ✓ *(6; Inv1_1, and Bypass in isolation)* · `-buggy-trailing` → `CAUGHT` ✓ *(122; Inv2_2, and Inv2_1 in isolation)* · `-buggy-closure` → `CAUGHT` ✓ *(1,283; NoStuck)* · `-buggy-oob` → `CAUGHT` ✓ *(125; Inv2_2, and Inv2_1 and Bypass in isolation)* · `-buggy-split` → `CAUGHT` ✓ *(25; Inv1_1)* · `-buggy-shortshape` → `CAUGHT` ✓ *(1,281; Inv1_1 — the page as written, a finding)* · `-buggy-norecall` → `CAUGHT` ✓ *(23; Inv4_2)* · `-buggy-unstaffed` → `CAUGHT` ✓ *(5; Inv4_1)*
  - `-probe-residue` *(8)*, `-probe-trailing` *(121)*, `-probe-superseded` *(1,281)*, `-probe-recoveryclosed` *(6)*, `-probe-shortterminal` *(1,289)*, `-probe-approved` *(301)*, `-probe-outofband` *(111)* → each rejected ✓

`node audit.mjs --only compositions/multi-party-approval`: 16 models, 1 HOLDS, 15 CAUGHT, 0 problems. Each twin is the model byte for byte below a two-line header with one constant flipped in its .cfg; each probe adds one invariant. `isolate.mjs` was not run over the whole set (an isolated run of an invariant a twin does not break explores all 104,207 states, about three and a half minutes, and the eight twins against nine invariants make seventy-two runs); the five isolations above were run by hand, one invariant to a configuration. Variable coverage, audited by script (each action's every leaf branch assigns every variable once or names it in UNCHANGED once): 9 actions, 18 leaf branches over 13 variables, none missing one; the script was confirmed to report a variable taken out of one UNCHANGED.

## Step 2 — coverage matrix

| Spec invariant or claim | Load-bearing (vote)? | Verdict | Model construct / reason |
|---|---|---|---|
| Invariant 1.1 — a quiescent chain the recovery did not close has its full step list | YES | **covered — finding, cured** | `Inv1_1`. Carried by Term routed vector's N (`-buggy-steplist`: N as the step list's length resolves a chain whose first submit is refused Approved, Final Critique 12's eos A1), Execution Contract Database 1 (`-buggy-split`) and the initiation leg's closure of a short chain. **Finding, cured on the page 2026-10-26:** a chain whose submit was refused and whose initiation-failed record was refused stands quarantined with a short step list; its approvers or its initiator may drive it terminal, and Reconciliation 10 then recorded the initiation event (disposition d), leaving a quiescent chain with a short list that is not recovery-closed (`-buggy-shortshape`). Reconciliation 10 now holds for a full list, 12 records the initiation-failed record for a short one whatever its state, and 13 and 15 withdraw only a Pending chain. |
| Invariant 1.2 — a recovery-closed chain's step list is its initiation-failed record's | no | out-of-scope (records) | The model carries no audit record; the record carries the chain shape from the chain record (Reconciliation 12), which is what the model's step list is. |
| Invariant 1.3, 1.4 — step ids name Approval Step records; the step-chain index maps each back | no | out-of-scope (derived indexes) | The derived indexes are not modelled; a lost step-assignment entry is open line 2026-10-26-c. |
| Invariant 1.5 — no chainless step of a quiescent chain | no | by-construction | Each action is one transaction (Database 1); no step is written without its chain record. |
| Invariant 2.1 — a resolution-terminated chain's state is the quorum's answer on its routed vector | YES | **covered** | `Inv2_1`, at every state. `-buggy-trailing` (a trailing rejection of a quorum-Withdrawn chain's residue; the Final Critique 12 settle's own case) and `-buggy-oob` break it in isolation. |
| Invariant 2.2 — the quorum answers Pending on a withdrawal-terminated chain's pre-withdrawal vector | YES | **covered** | `Inv2_2`, at every state. `-buggy-trailing` (a trailing decision on a withdrawn chain's residue; Final Critique 12's linus F2), `-buggy-oob`. |
| Bypass resistance — no chain Approved without the quorum's routed, non-trailing approvals | YES | **covered** | `Bypass`. `-buggy-steplist` and `-buggy-oob` (Wiring decision 6, 7 dropped) break it in isolation. |
| Invariant 3.1 through 3.3 — permission enforcement | no | out-of-scope (Permissions) | A gate ahead of every write (Action wiring 1, 40, 51), not an interleaving; Permissions is not modelled. |
| Invariant 4.1 — at quiescence an open step carries one Active assignment | YES | **covered** | `Inv4_1`. `-buggy-unstaffed`. |
| Invariant 4.2 — at quiescence a settled step carries none | YES | **covered** | `Inv4_2`, steps decided around the composition aside (Composes 11). `-buggy-norecall` (Cascade 1 dropped). A lost step-assignment entry, which Cascade 7 reads as no assignment, is open line 2026-10-26-c and not modelled. |
| Invariant 4.3 — no recall of a Pending step's assignment in a Pending chain | no | by-construction | Only a decision recalls its own step's assignment, and a cascade runs on a terminal chain alone. |
| Invariant 5.1 through 5.3 — audit completeness | no | out-of-scope (audit writes) | The audit writes are not modelled (Ledger 2026-08-29-u); a refused resolution event is open line 2026-10-26-d. |
| Invariant 7.1 — a terminal chain's state never changes | YES | **by-construction** | `Inv7_1` is checked, and every action writing the chain state requires it Pending (Action wiring 34, 44; Reconciliation 12, 13), so no twin breaks it: one dropping Action wiring 31 holds too, since the routed vector counts no trailing decision and a re-run evaluation answers what the chain already holds. |
| Invariant 7.2 — a terminal chain's terminal instant never changes | no | out-of-scope (clock) | The model has no clock. |
| Invariant 7.3 — two resolution events carry no one chain id | no | by-construction | A chain's terminal event is set once. |
| Invariant 8.1, 8.2 — declared fields immutable; the quarantine flag set only by the initiation recovery | no | by-construction | No action writes a declared field; only the initiation actions and the initiation leg move the phase to quarantined. |
| Invariant 9.1 — a chain's lifecycle resolves from its records | no | out-of-scope (reads) | [Read Chain] is not modelled. |
| Invariant 10.1 through 10.3 — authentication precedes commitment | no | out-of-scope (Audit Trail) | Each action is one transaction whose intent attests first; Audit Trail's attestation is that page's. |
| Reconciliation 26, 30; Check 5.4 — every call a partial flag names closes with a closure mark | YES | **covered** | `NoStuck`; `-buggy-closure` (Term closure mark before Final Critique 12: a residue the initiator withdrew had no mark; Final Critique 12's linus F1). `-probe-residue` and `-probe-superseded` show the flag and the supersession are reached. |
| Reconciliation 5, 17, 26, 32 — the sweep examines no aged chain | no | out-of-scope (clock) | Conditions of the rules, not interleavings; the model has no horizon. |

## Result

Every vote-named claim the model takes is covered by a named check with a twin that breaks it, but terminal absorption, held by construction and recorded so. One finding, cured on the page in the commit that lands the model. The audit writes, the derived indexes, the clock and [Read Chain] are out of scope with their reasons; the first two carry open lines (2026-08-29-u, 2026-10-26-c, 2026-10-26-d).
