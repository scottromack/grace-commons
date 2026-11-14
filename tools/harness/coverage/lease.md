# Coverage matrix — `lease`

- **Pattern:** `atoms/lease.md`
- **Model:** `lease.tla` + `lease-buggy-death.tla`, `lease-buggy-margin.tla`, `lease-buggy-fence.tla`, `lease-buggy-release.tla`, `lease-buggy-waiter.tla` + probe `lease-probe-both.tla`; and `lease.als`, the static data model (+ 9 buggy twins `lease-buggy-<defect>.als`, 2026-11-12).
- **Reviewer / date:** the model's author, same session as the grounding gate — 2026-10-04. Not a fresh-context read; the next scheduled rescan owes one.
- **Formal-layer vote load-bearing claims:** Invariant 1 (one holder); Invariant 2 and 3 (the terminus is the instant, death is not observable); Invariant 6 (a fence carries its allowance); Sizing 2, 3, 3a (the write margin); Composition note 5c (no release with a call in flight).

## Step 1 — harness re-run (must pass)

- Correct model: `node check.mjs ../../atoms/models/lease.tla` → `PASS` ✓ *(14,480 states; Dur=4, Pause=1, Skew=1, MaxTime=8)*
- `lease-buggy-death` `--buggy` → `PASS` (rejected) ✓ *(110 states; Inv_Terminus)*
- `lease-buggy-margin` `--buggy` → `PASS` (rejected) ✓ *(5,707 states; Inv_NoLateWrite)*
- `lease-buggy-fence` `--buggy` → `PASS` (rejected) ✓ *(3,281 states; Inv_NoLateWrite)*
- `lease-buggy-release` `--buggy` → `PASS` (rejected) ✓ *(1,085 states; Inv_NoLateWrite)*
- `lease-probe-both` → rejected ✓ *(3,496 states; an unfenced write lands, a fenced write lands and the next holder reads in one trace)*
- 2026-11-10 (unit `tooling: every check has a twin that breaks it`): `audit.mjs` → HOLDS, five twins CAUGHT; `Inv_NoLateWrite` broken by `lease-buggy-fence.tla` (and margin, release), `Inv_Terminus` and `Inv_OneHolder` by `lease-buggy-death.tla`, `Inv_WaiterBound` by the new `lease-buggy-waiter.tla` (`Tick` runs past a free key with a waiter standing).
- 2026-11-12 (unit `atoms/lease.md formal layer`): `lease.als` added, the page's static data model: the one lease state the host holds for a key, every version a successful take or a release answered released leaves, built from the version its call found back to the key never taken; what the host derives from it at one reading (State 2) and what [Take], [Try Take], [Remaining] and [Release] answer there, in any world of beliefs about which holders have died; and the instants a holder mints from expires_at and hands its fenced parties. `node check.mjs ../../atoms/models/lease.als` → `HOLDS` (19 commands: 8 checks UNSAT, 11 runs SAT), at `for 3 but 5 Int`, about 15 s. Nine twins, one defect each, each `CAUGHT`: `-take-beside`, `-free-late`, `-free-on-margin`, `-free-on-death`, `-report-death`, `-release-any`, `-remaining-passed`, `-fence-bare`, `-fence-handed-on`. Two facts, both from outside the page's promises: a caller takes only for a duration above zero (Composition note 5e), and arithmetic is exact (Execution Contract Logic confinement 9). Not modeled in Alloy: the line of waiters, a second key, restarts, the sizing beyond the live reading, and the fenced party's judgment (the header says why).

## Step 2 — coverage matrix

| Spec invariant (no. + name) | Load-bearing (vote)? | Verdict | Model construct / reason |
|---|---|---|---|
| Invariant 1 — One holder | YES | `checked` **covered** | `Inv_OneHolder`, asserted from the two grants' own instants (`exp1`, `exp`, `rel1`) and not from the `holder` variable; and `Inv_NoLateWrite`, the same claim stated of the world: no write of the former holder lands after the next holder has read. Broken by `lease-buggy-death.tla` (`Inv_OneHolder`), `lease-buggy-fence.tla` (`Inv_NoLateWrite`). Cross-checked in Alloy (2026-11-12): `A_Invariant_1_1` in `lease.als`, one lease state stored (State 1) and at most one grant standing at any reading, broken by `lease-buggy-take-beside.als` (a take adds its grant beside the state it found, Operation 2a). Nothing testable in Alloy for Invariant 1.2: it orders two takes, and one state shows only the grant the later one left. |
| Invariant 2 — The terminus is the instant | YES | `checked` **covered** | `Inv_Terminus`: the second take lands no earlier than the first grant's instant unless the first holder released. Broken by `lease-buggy-death.tla`. Cross-checked in Alloy (2026-11-12), read at one reading: `A_Invariant_2_1` (a grant whose instant has passed, the equal reading included, stands no more, nothing stored), broken by `lease-buggy-free-late.als`; `A_Invariant_2_2` (before its instant a grant stands, whatever the world believes or the holder reads of its margin), broken by `lease-buggy-free-on-margin.als` and `lease-buggy-free-on-death.als`. 2.1's release arm and its "exactly one" are a step, the TLA+ model's. |
| Invariant 3 — Death is not observable | YES | `checked` **covered** | `P1Die` changes nothing the host reads; twin `lease-buggy-death` frees the key on the death and is rejected by `Inv_Terminus`. Broken by `lease-buggy-death.tla`. Cross-checked in Alloy (2026-11-12): `A_Invariant_3_1` (every answer the host gives at a reading is the same whatever is believed about which holders died), broken by `lease-buggy-report-death.als` and `lease-buggy-free-on-death.als`; `A_Invariant_3_2` (before its instant, whether a grant stands does not turn on such a belief), broken by `lease-buggy-free-on-death.als`. |
| Invariant 4.1 — A waiter's bound is fixed at arrival | no | `checked` **covered** | `Inv_WaiterBound`, with `Tick` withheld while a waiter stands at a free key (Operation 2). Broken by `lease-buggy-waiter.tla`. |
| Invariant 4.2 — Admitting an earlier waiter does not extend a later waiter's bound | no | `owed` (TLA+: a second waiter, across steps) out-of-scope (a second waiter is a third party; the property is a liveness bound and no safety claim rests on it) | Nothing testable in Alloy (2026-11-12): it compares a later waiter's bound before and after an earlier waiter's admission, and the host holds a waiter with its bound alone (State 4), so one state cannot show what the arrival set; a bound extended to the new grant's expires_at is the value a waiter arriving under that grant holds. Owed to `lease.tla`, a second waiter through its `.cfg`. |
| Invariant 5 — Standing is answered, never assumed | no | `checked` covered (Alloy, 2026-11-12) | `A_Invariant_5_1` in `lease.als`: at every reading, [Remaining] answers a term, and [Release] released, exactly to the holder of the grant that stands, the term its expires_at less the reading; a former holder whose term passed is answered none and not-held (Check 5.1). Broken by `lease-buggy-release-any.als` (Operation 12, 13 dropped), `lease-buggy-remaining-passed.als` (the stored grant answered, not the standing one) and `lease-buggy-report-death.als`. Not stated in the TLA+ model (`P1Ask` models only the holder's own reading). |
| Invariant 6.1 — A fence instant carries its allowance | YES | `checked` **covered** | `StoreAdmits` with `FenceCut`; twin `lease-buggy-fence` hands the instant bare and is rejected by `Inv_NoLateWrite`. Broken by `lease-buggy-fence.tla`. Cross-checked in Alloy (2026-11-12): `A_Invariant_6_1`, every handed instant no later than expires_at less the receiving party's allowance, broken by `lease-buggy-fence-bare.als` (Fence 5) and `lease-buggy-fence-handed-on.als`. |
| Invariant 6.2 — Every fence instant minted independently | no | `checked` covered (Alloy, 2026-11-12) | `A_Invariant_6_2` in `lease.als`: no one minted instant is handed to two fenced parties (Fence 8, 9). Broken by `lease-buggy-fence-handed-on.als`. The TLA+ model has one fenced party. |
| Sizing 2, 3, 3a — the write margin | YES | `checked` **covered** | `P1Ask` (live only above `Margin`), `P1Issue` (within `Pause` of the asking), `ULand` (within `Pause` of the issue); twin `lease-buggy-margin` is rejected. Broken by `lease-buggy-margin.tla`. |
| Composition note 5c — no release with a call in flight | YES | `checked` **covered** | `P1Release` guard; twin `lease-buggy-release` is rejected. Broken by `lease-buggy-release.tla`. |
| Sizing 5, 5a, 6 — a unit of work, the share term | no | `unstatable` out-of-scope (arithmetic over a pattern's own bounds; Audit Trail's closure enumerator carries its instance) | — |
| Capability requirement 10, 11 — one application, one delivery | no | `unstatable` out-of-scope (the model delivers each call once by construction) | — |

## Step 3 — bound saturation

- `MaxTime = 8`: 14,480 states — all invariants hold.
- `MaxTime = 10`: 25,484 states; `MaxTime = 12`: 41,224 states; `Dur = 5, MaxTime = 10`: 31,496 states — all invariants hold.
- The count grows with the bound because the clock is a state variable; no new behaviour appears. Every action is first enabled within `Dur + 2 * Pause + 1` = 7 ticks of the start, inside the committed bound of 8.

## Outcome

- GAP rows: **none**.
- by-construction flags on load-bearing invariants: none; Invariant 1 was promoted to `Inv_OneHolder` while the model was written.
- Result: **all vote-named claims covered** — 2026-10-04.
- 2026-11-12: Invariant 5 and 6.2 move to `checked` (Alloy); Invariant 1, 2, 3 and 6.1 gain Alloy cross-checks. Owed now: Invariant 4.2, across steps, to the TLA+ model.
