# Coverage matrix — `resolve-a-persons-data-rights`

- **Pattern:** `compositions/resolve-a-persons-data-rights.md`
- **Model:** `resolve-a-persons-data-rights.tla` + `-buggy`, `-buggy-coverage`, `-buggy-retry`, `-buggy-release`, `-buggy-abandon`, `-buggy-grant`, `-buggy-unsettled`, `-buggy-plan`, `-buggy-taint` + probes `-probe-recover`, `-probe-complete`, `-probe-late`; `resolve-a-persons-data-rights-access.tla` + probe `-access-probe-abandon`; `resolve-a-persons-data-rights-admission.tla` + `-admission-buggy-order` + probe `-admission-probe-again`. One module body, eighteen files; the three base files differ by which parties run and whether the fulfillment plans a destruction.
- **Reviewer / date:** the model's author, same session as the re-derivation — 2026-10-05. Not a fresh-context read; the next scheduled rescan owes one.
- **Formal-layer vote load-bearing claims:** Invariant 1 (the binding: one fulfilled event, never without its disclosure, an orphan always under an open intent, an intent closed once); Invariant 5.1 (one response disclosure); Invariant 2.1 with Reconciliation 16 (a compensation seals the whole set); Invariant 3.1 with Disposition 42 (erased only on the store's evidence, a destroyed record never sealed retained); the request section (one writer over a request: Concurrency 7 through 22, Reconciliation 17). The vote is yes: each is a claim over interleavings of a fulfillment, a second fulfillment and the reconciliation's legs, which the page alone cannot settle.

## Step 1 — harness re-run (must pass)

- `node tools/harness/audit.mjs --only 'compositions/resolve-a-persons-data-rights'`, run in four parts under the device shell's time limit (`…-a`, `…-b`, `…-p`, and the base file by `check.mjs`) → 18 models, 0 FAIL ✓
- Correct, one erasure against two legs: `resolve-a-persons-data-rights.tla` → `PASS` ✓ *(90,837 states; Dur=6, Pause=1, Lat=2, PLat=2, MaxTime=8)*
- Correct, nothing planned: `-access.tla` → `PASS` ✓ *(9,436 states; Dur=6, MaxTime=8)*
- Correct, two fulfillments of one request: `-admission.tla` → `PASS` ✓ *(49,460 states; Dur=6, MaxTime=7)*
- `-buggy` → rejected ✓ *(3,519 states; Inv_OneDisclosure — a leg that closes without the section writes a second disclosure)*
- `-buggy-coverage` → rejected ✓ *(4,989 states; Inv_Cover — a compensation built from the plan alone drops the settled record)*
- `-buggy-retry` → rejected ✓ *(2,575 states; Inv_OneSeal — the fulfilled event issued a second time lands twice)*
- `-buggy-release` → rejected ✓ *(7,592 states; Inv_OneDisclosure — the section released over a call that then lands)*
- `-buggy-abandon` → rejected ✓ *(1,193 states; Inv_OrphanOpen — an abandonment over a disclosure write that did not answer, which then lands)*
- `-buggy-grant` → rejected ✓ *(13,853 states; Inv_OneDisclosure — a call issued without a reading of the grant lands in the next holder's)*
- `-buggy-unsettled` → rejected ✓ *(710 states; Inv_Truth — a planned call that did not settle its record read as a refusal)*
- `-buggy-plan` → rejected ✓ *(6,945 states; Inv_Accounted — a leg abandons a planned destruction no store shows)*
- `-buggy-taint` → rejected ✓ *(1,923 states; Inv_Truth — a storage-failure followed by a refusal sealed retained)*
- `-admission-buggy-order` → rejected ✓ *(15,640 states; Inv_OneOpen — the request's state read before the take)*
- `-probe-recover` → rejected ✓ *(4,989 states; a leg, not the invocation, writes the one fulfilled event: the compensation is reachable)*
- `-probe-complete` → rejected ✓ *(6,704 states; a leg writes the disclosure and then the event: the completion is reachable)*
- `-probe-late` → rejected ✓ *(1,083 states; a fulfilled event lands after its own write answered a refusal)*
- `-access-probe-abandon` → rejected ✓ *(1,306 states; a leg abandons an intent with nothing planned)*
- `-admission-probe-again` → rejected ✓ *(33,832 states; a second fulfillment seals a request the first abandoned)*

## Step 2 — coverage matrix

| Spec invariant (no. + name) | Load-bearing (vote)? | Verdict | Model construct / reason |
|---|---|---|---|
| Invariant 1 — Binding bijection (1.1, 1.2, 1.4, 1.5's safety half) | YES | **covered** | `Inv_NoOrphanEvent`, `Inv_OneSeal`, `Inv_OrphanOpen`, `Inv_OneClose`. The fulfilled event is the last write of a fulfillment and of a leg; every write is started on a reading of the grant and lands or fails by its bound. Twins `-buggy`, `-buggy-retry`, `-buggy-release`, `-buggy-abandon`, `-buggy-grant`. Invariant 1.3 (an event names one request) holds by construction with one request; Invariant 1.5's liveness half and Invariant 1.6 (the compensation flag) are out of scope: the window is arithmetic and the flag is a payload field. |
| Invariant 5 — Every response disclosure recorded (5.1) | YES | **covered** | `Inv_OneDisclosure`. Twins `-buggy`, `-buggy-release`, `-buggy-grant`. |
| Invariant 2 — No-silent-omission (2.1) with Reconciliation 16 | YES | **covered** | `Inv_Cover`: every sealed set carries the settled record, a leg's from the intent. Twin `-buggy-coverage`. The enumeration itself and Invariant 2.2 are out of scope: the universe is two records, given. |
| Invariant 3 — Erasure validity (3.1) with Disposition 42 | YES | **covered** | `Inv_Evidence`, `Inv_Truth`, `Inv_Accounted`: a seal reads the store, a destroyed record is never sealed retained, and a destruction stands under an open intent or a sealed set. Twins `-buggy-unsettled`, `-buggy-taint`, `-buggy-plan`. Invariant 3.2 (no host delete under a retention) is out of scope: the host delete is not modelled. |
| Concurrency 7 — the state read under the section; Reconciliation 8 | YES | **covered** | `Inv_OneOpen` in `-admission`: two fulfillments of one request never both hold an open intent. Twin `-admission-buggy-order`. |
| Concurrency 8 through 14 — a call on a reading of the grant, above its floor | YES | **covered** | every write's `Ask`, `Issue`, `Land` with the floors; twin `-buggy-grant`. |
| Concurrency 19, 20 — no release with a call in flight or over a step-3 refusal | YES | **covered** | the release guards; twin `-buggy-release`; probe `-probe-late`. |
| Reconciliation 13, 15; Action wiring 19, 39 — abandon only where nothing was planned and nothing may land | YES | **covered** | `Inv_Accounted`, `Inv_OrphanOpen`; twins `-buggy-plan`, `-buggy-abandon`; probes `-probe-complete`, `-access-probe-abandon`. |
| Reconciliation 17, 23 — a leg under the section, reading again | YES | **covered** | the leg's take and read; twin `-buggy`. |
| Invariant 4 — Disposition groundedness | no | out-of-scope (a property of a reason's content) | — |
| Invariant 6 — Fulfillment terminality | no | by-construction, probed | no action leaves a sealed request; `-admission-probe-again` shows a second fulfillment sealing after an abandonment and none after a seal. Invariant 6.2 is `Inv_OneOpen` with `Inv_OneSeal`. |
| Invariant 7 — Consent non-mutation | no | out-of-scope (Consent is not a party; the claim is over which surfaces are called) | — |
| Invariant 8 — Authentication precedes destruction, disclosure and commitment | no | out-of-scope (the credential is verified inside the substrate's record_action; the intent precedes every call by construction) | — |

## Step 3 — bound saturation

- One erasure against two legs holds at MaxTime=9 (130,671 states); nothing planned holds at Dur=7 within 9 ticks (10,795 states); two fulfillments hold at Dur=7 within 8 ticks (63,623 states). Each was run from a scratch copy and not committed. The committed bounds are the smallest at which every twin is rejected and every probe is reached.
- The body normalises a spent reading's instant and a landed call's bound to zero, as Defensible Retention's does; without that the main file passes 200,000 states at the same bounds.

## Outcome

- GAP rows: none.
- by-construction flags on load-bearing invariants: none.
- NOT MODELED, on the model's own list and so where the next reader's findings are likeliest: the intake; more than one planned record and the order of a plan's calls; the host delete; a purge's refusals beyond one that applies nothing and one storage-failure; the recovery intent; the reconciliation's two edges, the audit horizon and the alert floor, and the checks — where all seven of the closing round's foundational findings were; the instance topology (Capability requirement 52, 53); the state read's failure; the two indexes; the sizing of the largest record; a host restart; the rate at which two clocks drift.
- Result: **clean**, on the author's read. A fresh-context read is owed.
