# Coverage matrix — `authenticated-actor`

- **Pattern:** `compositions/authenticated-actor.md`
- **Model:** `authenticated-actor.tla` + `authenticated-actor.cfg` (TLA+, one principal, two actor references, three credential ids, two attestation ids; invariants TypeOK, Inv1_1, Inv3, Inv4, AuthBinding, CnaEntry; no PROPERTY) + four buggy twins (`-buggy-adopt`, `-buggy-race`, `-buggy-staleread`, `-buggy-unlogged`) + six probes (`-probe-attest`, `-rotated`, `-reentry`, `-refused`, `-stampgap`, `-reopen`)
- **Reviewer / date:** mayor, from the page at fc78924 and the model as it stands — 2026-11-10 (unit `formal: more coverage for the yes votes`, step 1; the page had no matrix)
- **Formal-layer vote load-bearing claims:** the model header names five: Inv1_1 (every attestation's gate credential stood effective-active at its commit), Inv3 (the binding and its inverse agree, each injective), Inv4 (every attestation carries its success entry), AuthBinding (no binding adopts a credential without a verified presenter) and CnaEntry (a credential-not-active entry names the pair's last credential).

## Step 1 — harness run

- Correct model: `node check.mjs ../../compositions/authenticated-actor.tla` → `HOLDS` ✓ (43,655 states, TLC, 2026-11-10).
- Buggy twins, each `--buggy`: `-adopt` → `CAUGHT` (AuthBinding, 137 states); `-race` → `CAUGHT` (Inv3, 115); `-staleread` → `CAUGHT` (Inv1_1, 170); `-unlogged` → `CAUGHT` (Inv4, 46). Each twin turns one transaction-boundary constant off and is rejected by the check built for it. No twin breaks `CnaEntry`; `-probe-refused` and the other probes establish reachability, not rejection.

## Step 2 — coverage matrix

One row per rule of *Composition-level invariants* (the page's numbering), then the wiring rules the model's checks are named for.

| Spec claim | Load-bearing (vote)? | Verdict | Model construct / reason |
|---|---|---|---|
| Invariant 1.1 — no attestation for a principal reference carrying no effective-active gating credential at the gate read | yes | **covered** | `Inv1_1` (`attp[a] # NONE => attok[a]`, computed from the state the commit wrote over, not from the guard); `-buggy-staleread` rejects it; `-probe-stampgap` and `-probe-rotated` and `-probe-reopen` show the stamp, rotation and re-opening readings are reachable. |
| Invariant 2.1 — the credential material is not passed to Actor Identity's `attest` | yes | out-of-scope (named reason) | Header: "the attest credential and secret-surface separation (Invariant 2, a deployment obligation)". The model has no material to pass. |
| Invariant 2.2 — Credential's verifier is not passed to `attest` | yes | out-of-scope (named reason) | The same. Neither (c) nor owed unless a model carries a secret value and a taint flag on what `attest` receives; stays with the reason. |
| Invariant 3.1 — every bound principal reference carries exactly one actor reference | yes | **covered** | `Inv3` (the binding injective); `-buggy-race` (the guard read in one step, the binding written in a later one) rejects it. |
| Invariant 3.2 — every bound actor reference carries exactly one principal reference | yes | **covered** | `Inv3`, the inverse map's half; the two actor references racing for one principal stand for two principals racing for one actor reference (header: the maps are symmetric). |
| Invariant 3.3 — the principal binding and the inverse map agree | yes | **covered** | `Inv3`. |
| Invariant 4.2 — an attest-failed call appends no attest log entry | yes | by-construction | A storage failure "commits nothing and is no step"; an attest-failed answer is no step the model takes. `Inv4` states the other direction (every attestation has its entry). A twin that writes an entry on a failed attest has no action to live in. Owed (b). |
| Invariant 4.3 — every success entry carries the attestation id and the current credential's id | yes | **covered** (partial) | `Inv4`: every attestation has its entry, the entry names a credential of the attestation's principal (`cown[attc[a]] = attp[a]`); `-buggy-unlogged` rejects the missing entry. The model checks "a credential of the principal", not "the *current* credential" (the pair's highest effective-active id). Owed (b): the stronger form, with a twin that names an older credential. |
| Action wiring 5 through 7 — the re-entry arm binds the current credential only after `verify` answers verified | yes | **covered** | `AuthBinding`; `-buggy-adopt` rejects it; `-probe-reentry` shows a proved adoption reachable. |
| Action wiring 18, 34 — a credential-not-active entry names the pair's last credential, not effective-active at the entry's commit | yes (as the page stands) | **covered**, no twin | `CnaEntry`; `-probe-refused` shows the entry reachable. No twin breaks the check, so its power is untested. The model's header notes open line 2026-10-27-a. Owed (b): a twin that names a live credential. |
| Action wiring 19, 24, 25 — the gate read, the attest and the success entry commit as one step | yes | **covered** | `GateInTxn` (twin `-staleread`) and `LogInTxn` (twin `-unlogged`). |
| Action wiring 2 through 4 — the namespace guard and the binding commit as one step | yes | **covered** | `GuardInTxn` (twin `-race`). |

Out-of-scope residual, named (the model header's own list): the boundary predicate and its invalid-request; not-bound's entry; Actor Identity's registry-unavailable and invalid-credential; the `verify` action (a read); clock values, the clock allowance and a second seam's clock; a second principal and a second credential type; registration instants that tie or run backward (Credential Operation 69, 70). Also named: Credential's own invariants (revoked never reads effective-active again, Credential Invariant 5.1) are Credential's (a).

## Step 3 — bound saturation

One principal, two actor references, three credential ids, two attestation ids: 43,655 states. The header gives the reason for each bound (ids taken lowest first; two actor references stand for two principals). A second principal or a fourth credential id is the dimension that would grow the space; neither is a new interleaving of the claims the checks name. Not raised in this pass.

## Outcome

- GAP rows: none on a load-bearing claim. Invariant 4.3's "current credential" is checked in a weaker form (a credential of the principal).
- by-construction flags: Invariant 4.2 (a failed attest writes no entry).
- Owed (step 2 of the coverage unit): **(b)** Invariant 4.3's current-credential form and a twin; **(b)** a twin for `CnaEntry`; **(b)** Invariant 4.2 as a failed-attest action that commits nothing; **(c)** Invariant 2.1 and 2.2, a deployment obligation about what a call receives, stays with its reason; **(a)** Credential Invariant 5.1 stays with Credential. **Tool owed** (step 2c): this composition has a TLA+ model and no Alloy; its static claims are the namespace binding's injectivity (Invariant 3), which `Inv3` already states over states, so an Alloy model would add no check TLC lacks. The Alloy model owed under 2c is vetoed if writing it only restates `Inv3`.
- Result: **findings routed** — coverage debt; no English defect.
