# Coverage matrix — `defensible-retention`

- **Pattern:** `compositions/defensible-retention.md`
- **Model:** `defensible-retention.tla` + `-buggy`, `-buggy-sibling`, `-buggy-gate`, `-buggy-margin`, `-buggy-release` + probe `-probe-after`; `defensible-retention-outcome.tla` + `-outcome-buggy-floor`, `-outcome-buggy-sweep`, `-outcome-buggy-refused` + probe `-outcome-probe-recover`. One module body, twelve files; the two base files differ by which parties run.
- **Reviewer / date:** the model's author, same session as the re-derivation — 2026-10-04. Not a fresh-context read; the next scheduled rescan owes one.
- **Touch of 2026-10-05 (Final Critique 12):** the rules the two models read — Invariant 1, 9 and 5.6, Concurrency 4, 13 through 17, 22 and 25, Reconciliation 20 and 21 — are as they were; the cures of that round sit on the NOT MODELED list (the audit horizon and the stand-in, the sizing of a record, the audit arms, the indexes and the listing). The twelve files are unchanged and were run again: 12 models, 0 FAIL.
- **Touch of 2026-10-06 (Final Critique 13):** the same holds. That round's cures are the checks' horizon edge, the at-quiescence wording of Invariant 3, 4, 8 and 9.3, the alert floor and the enumeration bound, and the stand-in's reach — all on the NOT MODELED list or out-of-scope rows above. Invariant 9.3 gained *at quiescence*; the row for Invariant 9 already scopes 9.3 and 9.4 out. The twelve files are unchanged and were run again: 12 models, 0 FAIL.
- **Touch of 2026-11-02 (the purge move):** the audit cascade came from Audit Trail with its models. `defensible-retention-audit-hold.tla` + `-buggy-backdated`, `-buggy-edge`, `-buggy-late`, `-buggy-unbudgeted`, `-buggy-unserialized` + probes `-probe-held`, `-probe-open`, `-probe-restart` (renamed from `audit-trail-hold*`; 43,688 states at the committed bounds) check Invariant 12 and the hold gate over an open cascade entry; `audit-trail.tla` + `-buggy`, `-buggy-order` check the cascade's order (Invariant 11) and Audit Trail's Invariant 8, and both pages cite them. All run again: 0 FAIL. The rules the two original models read are as they were.
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
| Invariant 1 — Hold-blocks-purge | YES | `checked` **covered** | `Inv_Gate`: `bad` is set at `PLand` when a hold stands in the store. The purge reads the gate under the section (`PRead`), issues on a live reading (`PAsk`, `PIssue`) and lands within a pause (`PLand`); the placement takes the same section (`QTake`). Twins `-buggy`, `-buggy-gate`, `-buggy-margin`, `-buggy-release`. Strict mode only. Broken by `defensible-retention-buggy-gate.tla`. |
| Invariant 9 — Cross-retention joint enforcement | YES | `checked` **covered** | `Inv_Gate` over `sib`: the placement party places a hold or a sibling retention (`qk`), and the same invariant reads both. Twin `-buggy-sibling`. Invariant 9.3 and 9.4 (siblings travelling with a destruction, the pending mark) are out of scope: one retention is purged. Broken by `defensible-retention-buggy-gate.tla`. |
| Invariant 5 — Audit completeness (5.6, one outcome) with Concurrency 4 | YES | `checked` **covered** | `Inv_OneOutcome`: `outs` counts record purged outcomes from the invocation (`OLand`) and the sweep (`WLand`). The outcome starts only above the floor (`OAsk`), the sweep reads again under the section (`WRead`). Twins `-outcome-buggy-floor`, `-outcome-buggy-sweep`, `-outcome-buggy-refused`. Invariant 5.1 through 5.5 are out of scope: the intent is not a modelled record. Broken by `defensible-retention-outcome-buggy-floor.tla`. |
| Invariant 2 — Retention coverage | no | `unstatable` out-of-scope (a scope statement over placements; no interleaving) | — |
| Invariant 3 — Hold audit coverage | no | `elsewhere` out-of-scope (the substrate's records; Audit Trail's models carry the substrate) | — |
| Invariant 4 — Retention-decision audit coverage | no | `owed` out-of-scope (the gate record and the outcomes' payloads are not modelled) | — |
| Invariant 6 — Non-retroactivity of holds | no | `unstatable` by-construction, probed | `-probe-after` shows a hold landing after a destruction with `bad` unset; nothing in the model lets it change `dest`. The log-position reading (Invariant 6.3) is a reader's rule and is not modelled. |
| Invariant 7 — Multi-hold independence | no | `owed` out-of-scope (one hold; a release is not modelled, and the old model's counter carried this claim with the gate and the destruction as one step, which is why it could not show the race) | — |
| Invariant 8 — Defensible destruction | no | `unstatable` out-of-scope (a property of the records' content) | — |
| Invariant 10 — Authentication precedes destruction | no | `elsewhere` out-of-scope (the credential is verified inside the substrate's record_action) | — |
| Invariant 11 — Cascade coordination on purge (from Audit Trail's Invariant 4) | YES | `elsewhere` **covered** | `audit-trail.tla`: the cascade's steps as separate commits in the declared order, with `audit-trail-buggy.tla` and `audit-trail-buggy-order.tla` as twins. |
| Invariant 12 — A hold over an open cascade entry (from Audit Trail's Composition-level invariant 1e, 1h, 1i) | YES | `checked` **covered** | `defensible-retention-audit-hold.tla`: `Inv_NoDestroyUnderHold`, `Inv_ReDriveAfterRelease`, `Inv_ClosureAfterRestart`, `Inv_BoundedClosure`; twins `-buggy-backdated`, `-buggy-edge`, `-buggy-late`, `-buggy-unbudgeted`, `-buggy-unserialized`; probes `-probe-held`, `-probe-open`, `-probe-restart`. Twins `-buggy-unredriven` (an entry landed under-legal-hold is not re-driven after the release) and `-buggy-restart` (the window restarted at the first held landing's instant) break `Inv_ReDriveAfterRelease` and `Inv_ClosureAfterRestart`, 2026-11-10. Broken by `defensible-retention-audit-hold-buggy-late.tla` (`Inv_NoDestroyUnderHold`), `defensible-retention-audit-hold-buggy-unredriven.tla` (`Inv_ReDriveAfterRelease`), `defensible-retention-audit-hold-buggy-restart.tla` (`Inv_ClosureAfterRestart`), `defensible-retention-audit-hold-buggy-backdated.tla` (`Inv_BoundedClosure`). |
| Invariant 13 — Honest representation of a destroyed audit event (from Audit Trail's Invariant 8.3) | no | `elsewhere` covered with Audit Trail's Invariant 8 | `audit-trail.tla` carries the standing of a destroyed event and its liveness arm, bounded. |
| Concurrency 13 through 15 — a committing call on a live reading | YES | `checked` **covered** | `PAsk`, `PIssue`, `PLand` with `Margin` and `Pause`; twin `-buggy-margin`. Broken by `defensible-retention-buggy-margin.tla`. |
| Concurrency 16, 17 — a record_action above the start floor | YES | `checked` **covered** | `OAsk`, `OIssue`, `OLand` with `Floor` and `Lat`; twin `-outcome-buggy-floor`. Broken by `defensible-retention-outcome-buggy-floor.tla`. |
| Concurrency 22 — no release with a call in flight | YES | `checked` **covered** | `PRelease` guard; twin `-buggy-release`. Broken by `defensible-retention-buggy-release.tla`. |
| Concurrency 25 — no release over a step-3 refusal | YES | `checked` **covered** | `ORefuse` leaves the append in flight behind the refusal; `PRelease` guard; twin `-outcome-buggy-refused`. Broken by `defensible-retention-outcome-buggy-refused.tla`. |
| Reconciliation 20, 21 — the sweep under the section | YES | `checked` **covered** | `WTake`, `WRead`; twin `-outcome-buggy-sweep`. Broken by `defensible-retention-outcome-buggy-sweep.tla`. |
| Concurrency 18, 19 — a lease call that never answers | no | `elsewhere` out-of-scope (Lease's model reads it as a grant lost; a party here that stalls is the same party) | — |

## Step 3 — bound saturation

- The gate holds at Dur=7 within 10 ticks (9,162 states) and the record at Dur=9 within 12 ticks (7,798 states), run from scratch copies and not committed. The committed bounds are the smallest at which every twin is rejected and both probes are reached.
- The body normalises a reading's instant and a call's landing bound to zero once spent, and a released grant's instant to zero; without that the state count is the product of stale instants and passes 200,000 at the same bounds.

## Outcome

- GAP rows: none.
- by-construction flags on load-bearing invariants: none.
- NOT MODELED, on the model's own list and so where the next reader's findings are likeliest: advisory mode; a hold release; two purges over one record and the sibling purges that travel with a destruction; the intent, the gate record and the recovery intent; the audit arms; the sweep's pairing of markers to acts, where seven of the gate's foundational findings were; the lower edge and the two indexes; the audit horizon; the call to the record destruction pattern, read as one landing with the purge; a host restart.
- Result: **clean**, on the author's read. A fresh-context read is owed.
