# Coverage matrix — `defensible-retention`

- **Pattern:** `compositions/defensible-retention.md`
- **Model:** `defensible-retention.tla` + `-buggy`, `-buggy-sibling`, `-buggy-gate`, `-buggy-margin`, `-buggy-release` + probe `-probe-after`; `defensible-retention-outcome.tla` + `-outcome-buggy-floor`, `-outcome-buggy-sweep`, `-outcome-buggy-refused` + probe `-outcome-probe-recover`. One module body, twelve files; the two base files differ by which parties run.
- **Reviewer / date:** the model's author, same session as the re-derivation — 2026-10-04. Not a fresh-context read; the next scheduled rescan owes one.
- **Formal-layer vote load-bearing claims:** Invariant 1 (hold-blocks-purge, the race against a hold placement included); Invariant 9 (no destruction while a sibling retention lives, the race against a placement included); Invariant 5.6 with Concurrency 4 (one outcome per act, the invocation against the sweep). The vote is yes: each is a claim over interleavings, which the page alone cannot settle.

## Step 1 — harness re-run (must pass)

- `node tools/harness/audit.mjs --only 'compositions/defensible-retention'` → 12 models, 0 FAIL ✓
- Correct, the gate: `defensible-retention.tla` → `PASS` ✓ *(4,206 states; Dur=5, Pause=1, MaxTime=7)*
- Correct, the record: `defensible-retention-outcome.tla` → `PASS` ✓ *(4,222 states; Dur=7, Pause=1, Lat=2, MaxTime=9)*
- `-buggy` → rejected ✓ *(562 states; Inv_Gate — a hold placed outside the section lands between the gate read and the destruction)*
- `-buggy-sibling` → rejected ✓ *(690 states; Inv_Gate — the same for a sibling retention)*
- `-buggy-gate` → rejected ✓ *(1,833 states; Inv_Gate — the gate read before the take)*
- `-buggy-margin` → rejected ✓ *(4,114 states; Inv_Gate — a purge issued on one call pause of margin lands after the next holder's placement)*
- `-buggy-release` → rejected ✓ *(1,786 states; Inv_Gate — a release with the purge in flight)*
- `-outcome-buggy-floor` → rejected ✓ *(4,363 states; Inv_OneOutcome — an outcome started without the write margin lands after the sweep's)*
- `-outcome-buggy-sweep` → rejected ✓ *(1,830 states; Inv_OneOutcome — a sweep that reads without the section)*
- `-outcome-buggy-refused` → rejected ✓ *(2,335 states; Inv_OneOutcome — the section released over a step-3 refusal whose append then lands)*
- `-probe-after` → rejected ✓ *(a destruction lands and a hold lands after it: the post-destruction hold is reachable)*
- `-outcome-probe-recover` → rejected ✓ *(the sweep, not the invocation, writes the one outcome: the recovery path is reachable)*

## Step 2 — coverage matrix

| Spec invariant (no. + name) | Load-bearing (vote)? | Verdict | Model construct / reason |
|---|---|---|---|
| Invariant 1 — Hold-blocks-purge | YES | **covered** | `Inv_Gate`: `bad` is set at `PLand` when a hold stands in the store. The purge reads the gate under the section (`PRead`), issues on a live reading (`PAsk`, `PIssue`) and lands within a pause (`PLand`); the placement takes the same section (`QTake`). Twins `-buggy`, `-buggy-gate`, `-buggy-margin`, `-buggy-release`. Strict mode only. |
| Invariant 9 — Cross-retention joint enforcement | YES | **covered** | `Inv_Gate` over `sib`: the placement party places a hold or a sibling retention (`qk`), and the same invariant reads both. Twin `-buggy-sibling`. Invariant 9.3 and 9.4 (siblings travelling with a destruction, the pending mark) are out of scope: one retention is purged. |
| Invariant 5 — Audit completeness (5.6, one outcome) with Concurrency 4 | YES | **covered** | `Inv_OneOutcome`: `outs` counts record purged outcomes from the invocation (`OLand`) and the sweep (`WLand`). The outcome starts only above the floor (`OAsk`), the sweep reads again under the section (`WRead`). Twins `-outcome-buggy-floor`, `-outcome-buggy-sweep`, `-outcome-buggy-refused`. Invariant 5.1 through 5.5 are out of scope: the intent is not a modelled record. |
| Invariant 2 — Retention coverage | no | out-of-scope (a scope statement over placements; no interleaving) | — |
| Invariant 3 — Hold audit coverage | no | out-of-scope (the substrate's records; Audit Trail's models carry the substrate) | — |
| Invariant 4 — Retention-decision audit coverage | no | out-of-scope (the gate record and the outcomes' payloads are not modelled) | — |
| Invariant 6 — Non-retroactivity of holds | no | by-construction, probed | `-probe-after` shows a hold landing after a destruction with `bad` unset; nothing in the model lets it change `dest`. The log-position reading (Invariant 6.3) is a reader's rule and is not modelled. |
| Invariant 7 — Multi-hold independence | no | out-of-scope (one hold; a release is not modelled, and the old model's counter carried this claim with the gate and the destruction as one step, which is why it could not show the race) | — |
| Invariant 8 — Defensible destruction | no | out-of-scope (a property of the records' content) | — |
| Invariant 10 — Authentication precedes destruction | no | out-of-scope (the credential is verified inside the substrate's record_action) | — |
| Concurrency 13 through 15 — a committing call on a live reading | YES | **covered** | `PAsk`, `PIssue`, `PLand` with `Margin` and `Pause`; twin `-buggy-margin`. |
| Concurrency 16, 17 — a record_action above the start floor | YES | **covered** | `OAsk`, `OIssue`, `OLand` with `Floor` and `Lat`; twin `-outcome-buggy-floor`. |
| Concurrency 22 — no release with a call in flight | YES | **covered** | `PRelease` guard; twin `-buggy-release`. |
| Concurrency 25 — no release over a step-3 refusal | YES | **covered** | `ORefuse` leaves the append in flight behind the refusal; `PRelease` guard; twin `-outcome-buggy-refused`. |
| Reconciliation 20, 21 — the sweep under the section | YES | **covered** | `WTake`, `WRead`; twin `-outcome-buggy-sweep`. |
| Concurrency 18, 19 — a lease call that never answers | no | out-of-scope (Lease's model reads it as a grant lost; a party here that stalls is the same party) | — |

## Step 3 — bound saturation

- The gate holds at Dur=7 within 10 ticks (9,162 states) and the record at Dur=9 within 12 ticks (7,798 states), run from scratch copies and not committed. The committed bounds are the smallest at which every twin is rejected and both probes are reached.
- The body normalises a reading's instant and a call's landing bound to zero once spent, and a released grant's instant to zero; without that the state count is the product of stale instants and passes 200,000 at the same bounds.

## Outcome

- GAP rows: none.
- by-construction flags on load-bearing invariants: none.
- NOT MODELED, on the model's own list and so where the next reader's findings are likeliest: advisory mode; a hold release; two purges over one record and the sibling purges that travel with a destruction; the intent, the gate record and the recovery intent; the audit arms; the sweep's pairing of markers to acts, where seven of the gate's foundational findings were; the lower edge and the two indexes; the audit horizon; the storage layer's confirmation; a host restart.
- Result: **clean**, on the author's read. A fresh-context read is owed.
