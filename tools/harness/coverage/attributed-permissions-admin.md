# Coverage matrix — Attributed Permissions Admin

> Formal-layer **coverage cross-check** (the section titled *The coverage cross-check* in pressure-testing.md).
> First emitted 2026-10-27 with the page's re-derived model. The formal-layer vote of 2026-06-03 was yes, over the
> models of 2026-06-12; the page then turned three times (the report-only leg of 2026-08-30, [Revoke Permission] of
> 2026-09-10, the Database contract of 2026-10-20), and the Ledger's formal line had read *pending* since 2026-08-30.

- **Pattern:** `compositions/attributed-permissions-admin.md`
- **Models:** `attributed-permissions-admin.tla` (one pair, two grant ids and four attestation ids; the three administrative actions, admitted and refused; writes around the composition; an adversary removing an attestation record; both retention scopes with their purges; the attribution query's verify results) + `-buggy-storageorphan`, `-buggy-sharedattest`, `-buggy-completeorphan`, `-buggy-attestpurge`, `-buggy-tamperpurged` + probes `-probe-issue`, `-probe-orphan`, `-probe-sweeptwo`, `-probe-survivor`, `-probe-direct`, `-probe-directrevoke`, `-probe-purgedread`, `-probe-tamperread`, `-probe-entryheld`; and, from 2026-06-12, `attributed-permissions-admin.als` + `-buggy.als`, issuance and revocation over Alloy snapshots and short traces.
- **Reviewer / date:** the model's author, the settling session of Final Critique 8 (the mayor) — 2026-10-27. Not a fresh-context read; the next scheduled rescan owes one.
- **Formal-layer vote load-bearing claims:** attribution completeness (Invariant 1, 2), attestation exclusivity (Invariant 7), the pair-scoped revocation over its enumerated set (Invariant 9), the orphan as evidence never completed (Wiring decision 4, 5; Housekeeping 7, 8), and the attribution query's lawful destruction answered before absence (Action wiring 62 through 67).
- **Layering:** no model imports another. Permissions and Actor Identity enter as their contracts: a grant written once and revoked once, an attestation minted once and never changed (their own models and checks prove the atoms). Every action is one transaction (Execution Contract Database 1), so a storage failure is no step; the sweep's enumeration is read inside its transaction (Database 2).

## Step 1 — harness run (must pass)

- `attributed-permissions-admin.tla` → `HOLDS` ✓ *(25,470 states, every state explored; about 17 s in the harness)*
  - `-buggy-storageorphan` → `CAUGHT` ✓ *(5; OrphanLogged)* · `-buggy-sharedattest` → `CAUGHT` ✓ *(55; Inv7)* · `-buggy-completeorphan` → `CAUGHT` ✓ *(21; OrphanUnpaired)* · `-buggy-attestpurge` → `CAUGHT` ✓ *(19; PairScopeHeld)* · `-buggy-tamperpurged` → `CAUGHT` ✓ *(39; NoFalseTamper)*
  - `-probe-issue` *(3)*, `-probe-orphan` *(4)*, `-probe-sweeptwo` *(55)*, `-probe-survivor` *(85)*, `-probe-direct` *(6)*, `-probe-directrevoke` *(17)*, `-probe-purgedread` *(39)*, `-probe-tamperread` *(19)*, `-probe-entryheld` *(39)* → each rejected ✓
- `attributed-permissions-admin.als` → `HOLDS` ✓ · `-buggy.als` → `CAUGHT` ✓ *(Issuance_Revocation_Attestations_Differ)*

`node audit.mjs --only compositions/attributed-permissions-admin`: 17 models, 2 HOLDS, 15 CAUGHT, 0 problems. Each twin is the model byte for byte below a two-line header with one constant flipped in its .cfg; each probe adds one invariant. Every action of the model assigns or holds each of its eleven variables exactly once (checked by script; the checker holds an unnamed variable silently).

## Step 2 — coverage matrix

| Spec invariant or claim | Load-bearing (vote)? | Verdict | Model construct / reason |
|---|---|---|---|
| Invariant 1.1, 1.4; Check 1.1 — a grant the composition issued carries its grant attribution entry | YES | **covered** | `Inv1_1`, over every grant no direct write produced. `-probe-direct` shows a grant written around the composition stands with no consistent attribution, the state Invariant 3.1 read per known grant could not hold over (Final Critique 8, row 5). |
| Invariant 2.1, 2.4; Invariant 9.2; Check 2.1, 7.2 — a grant the composition revoked carries its revocation attribution entry | YES | **covered** | `Inv2_1`, over every revocation no direct write made; `-probe-directrevoke` shows a grant the composition issued, revoked around it (Final Critique 8, row 6). |
| Invariant 1.2, 2.2 — an entry names an attestation Actor Identity holds, a lawful destruction excepted | YES | **covered — the model's finding, cured** | `PairScopeHeld` under the pair-scoped scope. **The model's finding, cured on the page in the commit that lands it:** under the per-store scope a lawful destruction takes a standing grant's attestation and its entry stays (Capability requirement 27, Action wiring 63), so the two invariants, which read *hold* alone, failed a deployment the page admits (`-probe-entryheld`); each now excepts an attestation a lawful destruction took. |
| Invariant 7.1 through 7.3, 7.4; Composes 23, 24; Check 6.1 through 6.4 — the maps injective, each naming an attestation of its own kind | YES | **covered** | `Inv7`. `-buggy-sharedattest`: one attestation serving a sweep's whole enumerated set, the shared attestation the 2026-09-10 Decision declined. |
| Invariant 9.1, 9.3; Composition state 13; Concurrency 7 — every grant a pair-scoped revocation answered ok for stands revoked; a grant committed after it survives | YES | **covered** | `NoActiveRevEntry` and the sweep's one step; `-probe-sweeptwo` (two grants under two attestations), `-probe-survivor` (a grant committed after the sweep stands active beside it). |
| Wiring decision 4, 5; Housekeeping 4, 7, 8; Atomic writes 8; Action wiring 38, 39 — an orphan is logged, never completed, and a retry is a fresh act | YES | **covered** | `OrphanLogged` and `OrphanUnpaired`; `-probe-orphan`. `-buggy-completeorphan`: the leg completing an orphan's grant on the orphan's own attestation, the posture the 2026-08-30 Decision retired. Whether Execution Contract Read 4 keeps a refused act's attestation and log entry is open line 2026-10-27-a; the model keeps them, as the page does. |
| Action wiring 88, 90, 95; Execution Contract Database 1 — a storage failure commits nothing | YES | **covered** | No step. `-buggy-storageorphan`: Permissions' storage-failure committing the attestation alone (the answer two of Final Critique 8's readers proposed for it), caught by `OrphanLogged`. |
| Composition state 27; Action wiring 62 through 67; Term lawful destruction — a lawful destruction is answered before absence, and the tamper reading stands for every other absence | YES | **covered** | `NoFalseTamper`, `TamperFound`, `PairScopeHeld`; `-probe-purgedread`, `-probe-tamperread`. `-buggy-tamperpurged`: every absent attestation read as tamper, the reading the 2026-09-15 Decision retired. `-buggy-attestpurge`: a pair-scoped purge taking an attestation alone, which is where Action wiring 65 and 67 would meet. |
| Invariant 3.1, 3.2 — the record answered per consistent attribution | no | by-construction | The verify result `VR` is defined over every consistent attribution. |
| Composition state 28; open line 2026-10-27-b — an orphan purged under its own retention | no | covered (step) / open | `PurgeOrphan`; the orphan log entry stays, and whether it should is the open line. |
| Housekeeping 13 through 18 — the failed-grant leg's ages, horizon and report | no | **out-of-scope (open line 2026-08-30-b)** | The model has no clock and no leg process; the leg's population is what `OrphanLogged` reads. |
| Invariant 4 — stamps under the clock offset allowance | no | out-of-scope (clock) | No clock is modelled. |
| Identity 9, 10 — the request instant and the auditor's grouping | no | out-of-scope (proposals) | Proposals are not modelled. |
| Invariant 5, 6, 8 — the constituents' invariants, the maps and the orphan log never changed | no | by-construction / out-of-scope | No action changes an entry or a log entry; writes around the composition's own state are out of scope (Invariant 6.4, External check 5); each constituent's own model. |

## Result

Every vote-named claim the model takes is covered by a named check with a twin that breaks it, and one finding the model made is cured on the page in the commit that lands it (Invariant 1.2, 2.2 under the per-store scope). The failed-grant leg's ages and horizon, the clock and the proposals are out of scope, the first recorded as open line 2026-08-30-b.
