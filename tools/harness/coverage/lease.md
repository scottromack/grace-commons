# Coverage matrix — `lease`

- **Pattern:** `atoms/lease.md`
- **Model:** `lease.tla` + `lease-buggy-death.tla`, `lease-buggy-margin.tla`, `lease-buggy-fence.tla`, `lease-buggy-release.tla` + probe `lease-probe-both.tla`
- **Reviewer / date:** the model's author, same session as the grounding gate — 2026-10-04. Not a fresh-context read; the next scheduled rescan owes one.
- **Formal-layer vote load-bearing claims:** Invariant 1 (one holder); Invariant 2 and 3 (the terminus is the instant, death is not observable); Invariant 6 (a fence carries its allowance); Sizing 2, 3, 3a (the write margin); Composition note 5c (no release with a call in flight).

## Step 1 — harness re-run (must pass)

- Correct model: `node check.mjs ../../atoms/lease.tla` → `PASS` ✓ *(14,480 states; Dur=4, Pause=1, Skew=1, MaxTime=8)*
- `lease-buggy-death` `--buggy` → `PASS` (rejected) ✓ *(110 states; Inv_Terminus)*
- `lease-buggy-margin` `--buggy` → `PASS` (rejected) ✓ *(5,707 states; Inv_NoLateWrite)*
- `lease-buggy-fence` `--buggy` → `PASS` (rejected) ✓ *(3,281 states; Inv_NoLateWrite)*
- `lease-buggy-release` `--buggy` → `PASS` (rejected) ✓ *(1,085 states; Inv_NoLateWrite)*
- `lease-probe-both` → rejected ✓ *(3,496 states; an unfenced write lands, a fenced write lands and the next holder reads in one trace)*

## Step 2 — coverage matrix

| Spec invariant (no. + name) | Load-bearing (vote)? | Verdict | Model construct / reason |
|---|---|---|---|
| Invariant 1 — One holder | YES | **covered** | `Inv_OneHolder`, asserted from the two grants' own instants (`exp1`, `exp`, `rel1`) and not from the `holder` variable; and `Inv_NoLateWrite`, the same claim stated of the world: no write of the former holder lands after the next holder has read. |
| Invariant 2 — The terminus is the instant | YES | **covered** | `Inv_Terminus`: the second take lands no earlier than the first grant's instant unless the first holder released. |
| Invariant 3 — Death is not observable | YES | **covered** | `P1Die` changes nothing the host reads; twin `lease-buggy-death` frees the key on the death and is rejected by `Inv_Terminus`. |
| Invariant 4.1 — A waiter's bound is fixed at arrival | no | **covered** | `Inv_WaiterBound`, with `Tick` withheld while a waiter stands at a free key (Operation 2). |
| Invariant 4.2 — Admitting an earlier waiter does not extend a later waiter's bound | no | out-of-scope (a second waiter is a third party; the property is a liveness bound and no safety claim rests on it) | — |
| Invariant 5 — Standing is answered, never assumed | no | out-of-scope (the answer to one call, within an action; `P1Ask` models only the holder's own reading) | — |
| Invariant 6 — A fence instant carries its allowance | YES | **covered** | `StoreAdmits` with `FenceCut`; twin `lease-buggy-fence` hands the instant bare and is rejected by `Inv_NoLateWrite`. One fenced party only: Invariant 6.2 (each fence minted separately) is out of scope. |
| Sizing 2, 3, 3a — the write margin | YES | **covered** | `P1Ask` (live only above `Margin`), `P1Issue` (within `Pause` of the asking), `ULand` (within `Pause` of the issue); twin `lease-buggy-margin` is rejected. |
| Composition note 5c — no release with a call in flight | YES | **covered** | `P1Release` guard; twin `lease-buggy-release` is rejected. |
| Sizing 5, 5a, 6 — a unit of work, the share term | no | out-of-scope (arithmetic over a pattern's own bounds; Audit Trail's closure enumerator carries its instance) | — |
| Capability requirement 10, 11 — one application, one delivery | no | out-of-scope (the model delivers each call once by construction) | — |

## Step 3 — bound saturation

- `MaxTime = 8`: 14,480 states — all invariants hold.
- `MaxTime = 10`: 25,484 states; `MaxTime = 12`: 41,224 states; `Dur = 5, MaxTime = 10`: 31,496 states — all invariants hold.
- The count grows with the bound because the clock is a state variable; no new behaviour appears. Every action is first enabled within `Dur + 2 * Pause + 1` = 7 ticks of the start, inside the committed bound of 8.

## Outcome

- GAP rows: **none**.
- by-construction flags on load-bearing invariants: none; Invariant 1 was promoted to `Inv_OneHolder` while the model was written.
- Result: **all vote-named claims covered** — 2026-10-04.
