# Coverage matrix — `idempotent-reservation`

- **Pattern:** `compositions/idempotent-reservation.md`
- **Model:** `idempotent-reservation.tla` + eleven buggy twins, `idempotent-reservation-buggy.tla`, `-buggy-seen`, `-buggy-failopen`, `-buggy-collision`, `-buggy-digest`, `-buggy-rerun`, `-buggy-uncached`, `-buggy-candidates`, `-buggy-place-rerun`, `-buggy-unmarked`, `-buggy-norecord` (each `.tla` with its `.cfg`)
- **Reviewer / date:** the model's author, the session that landed it — 2026-11-08. Not a fresh-context read; the next scheduled rescan owes one.
- **Formal-layer vote load-bearing claims:** the vote was cast yes in 2026-06 and the model re-derived 2026-11-08 over what the Ledger's `formal:` line named (the eviction leg as a second process over one token, and the `outcome-unknown` arm). The model takes every composition-level Invariant the page states as load-bearing except Invariant 8.1 (a deployment condition): Invariant 1 (idempotent place hold), 2 (idempotent state transitions, with the re-entry), 3 (token to commitment, one to one), 4 (token action binding), 7 (token expiry releases the binding), 8.2 (exactly-once effect).

## Step 1 — harness re-run (must pass)

- Correct model: `node check.mjs ../../compositions/idempotent-reservation.tla` → `HOLDS` ✓ *(10,872 states)*
- Buggy twins: each `node check.mjs ../../compositions/idempotent-reservation-<twin>.tla --buggy` → `CAUGHT` ✓ *(see Step 2 for the check that finds each)*

## Step 2 — coverage matrix

The model has one token, one resource, calls of two action types (a place_hold whose digest is the requester, a release whose digest is the commitment released), a second caller under other tokens who places and releases, the eviction leg as the other process, and Duplicate Prevention's store, which may be unavailable (its check then reads as seen, Action wiring 27). A call is one transaction (Execution Contract Database 1 and 2). The model keeps no history: it keeps a summary of the token's current window and each step adds an invariant's name to `viol` when it breaks it, so every named invariant in the `.cfg` reads "the name is not in `viol`". Nineteen entries in the `.cfg`.

| Spec invariant (no. + name) | Load-bearing (vote)? | Verdict | Model construct / reason |
|---|---|---|---|
| Invariant 1.1 — two place_hold calls under one token and digest answer alike inside the window | YES | **covered** | `Invariant_1_1` (each answer is compared with the first answer given to the same action type and digest in the window). Twin `-buggy-uncached` (a rejection is not recorded, Wiring decision 2) is rejected by `Wiring_2_RejectionRecorded`, the first check to fail; the answers it lets differ once the resource has freed are what this one reads. |
| Invariant 2.1 — two resolving calls under one token and digest answer alike inside the window | YES | **covered** | `Invariant_2_1`. Twin `-buggy-rerun` (a matching entry for a release calls the constituent again and answers not-held) is rejected by `Invariant_2_2`, the first check to fail; the not-held it answers against the entry's ok is what this one reads. |
| Invariant 2.2 — the constituent is called once for the token inside a window, a re-entry excepted | YES | **covered** | `Invariant_2_2` (a second call that is not a re-entry in an open window). Twin `-buggy-rerun`. |
| Invariant 2.3 — a re-entry rests on Provisional Commitment Invariant 2 | YES | **covered** | `Invariant_2_3`: a re-entry that follows an earlier run in the window changes nothing in the constituent. The correct model never reaches a re-entry inside a window the entry's own run opened, so the check holds without a twin of its own: the property is Provisional Commitment's (its model checks it), and this one says the composition's re-run does not move the constituent. |
| Invariant 3.1 — the token binds one commitment id inside a window | YES | **covered** | `Invariant_3_1`. Reached with `Invariant_1_1` by the twins that call the constituent twice (`-buggy-uncached`, `-buggy-rerun`); no twin breaks this one alone, since a second id needs a second fresh place_hold, and `Invariant_8_2` stops that first. |
| Invariant 4.1 — the token binds one action type | YES | **covered** | `Invariant_4_1` (no entry written inside the window carries another action type, and no replay answers another action type than its entry's). Twin `-buggy-collision` (the action type is not compared, Action wiring 7) is rejected by it. |
| Invariant 4.2 — the token binds one parameters digest | YES | **covered** | `Invariant_4_2`. Twin `-buggy-digest` (the digest is not compared, Action wiring 8). |
| Invariant 7.1 — an entry is evicted only after the window and Duplicate Prevention's guard elapsed | YES | **covered** | `Invariant_7_1`. Twin `-buggy` (the leg evicts whenever an entry exists: the unsafe eviction ordering the first model checked) is rejected by it. |
| Invariant 7.2 — a call carrying an evicted token stands as a fresh request | YES | **covered, no twin** | `Invariant_7_2`: a call that finds no entry while the token is not seen never takes the re-entry or outcome-unknown arm. By construction of the arms: the model's arms are chosen by the entry and the check, so the invariant holds by the arms' guards, and the nearest break (reading an unavailable check as not-seen) is the twin `-buggy-failopen`, rejected by `Wiring_FreshMeansNotSeen`. |
| Invariant 8.1 — the exactly-once claim only if the deployment supplies Duplicate Prevention's database | no | out-of-scope (a deployment condition read from the deployment's own configuration, External check 3 and 5; the model's database is its atomic step) | — |
| Invariant 8.2 — an admitted first invocation reaches the constituent exactly once inside the window | YES | **covered** | `Invariant_8_2` (a second fresh request in an open window). Twins `-buggy-uncached` and `-buggy` (an entry dropped inside its window lets the retry meet a token the guard still holds; the invariant is stated against the window summary, not the entry, so the dropped entry cannot hide the second call). |
| Check 4.1 / Housekeeping 6 — no evicted entry belongs to a token the check answers seen for | no | **covered** | `Check_4_1_NoSeenEvicted`. Twin `-buggy-seen` (the leg does not read the check; while the store is unavailable the check reads as seen) and `-buggy` are rejected by it. |
| Check 4.2 / Housekeeping 5 — no evicted entry is younger than the window | no | **covered** | `Check_4_2_NoYoungEvicted`. Twin `-buggy`. |
| Composes 7 / Action wiring 25 — Duplicate Prevention records with every entry written | no | **covered** | `Composes_7_GuardRecordedWithEntry`: an entry inside its window has the guard live. Twin `-buggy-norecord`. |
| Wiring decision 1, 2 — every answer is recorded against the token, a rejection included | no | **covered** | `Wiring_2_RejectionRecorded`. Twin `-buggy-uncached`. |
| Wiring decision 3 — a malformed token records nothing | no | out-of-scope (the boundary predicate answers invalid-request before any entry, check or constituent is touched; the model takes every token as well formed) | — |
| Wiring decision 4 — a place_hold answer on a seen token with no entry is not recorded | no | **covered** | The `Unknown` arm writes no entry and no guard and calls no constituent; `Indeterminate_10_13_Arms` and `Indeterminate_4_7_Candidates` read it. |
| Indeterminate outcome 3, 4, 7 — outcome-unknown carries the held commitments whose requester equals the call's | no | **covered** | `Indeterminate_4_7_Candidates` compares the composition's filter with the page's, read from the world. Twin `-buggy-candidates` (the requester is ignored). |
| Indeterminate outcome 8 — a recovered entry is marked | no | **covered** | `Indeterminate_8_RecoveredMarked`. Twin `-buggy-unmarked`. |
| Indeterminate outcome 10, 13 — outcome-unknown answers a place_hold, a resolving action runs again | no | **covered** | `Indeterminate_10_13_Arms`. Twin `-buggy-place-rerun` (a place_hold on a seen token is delegated again). |
| Capability requirement 16 / Action wiring 27 — an unavailable check resolves as seen | no | **covered** | `Wiring_FreshMeansNotSeen` (a fresh request is one the check answered not-seen for). Twin `-buggy-failopen`. |
| Composes 1 through 6 and 8; Capability requirement 1 through 4 and 18; Composition notes | no | out-of-scope (wiring and configuration the model fixes: one instance of each constituent, the window a constant, the database the model's atomic step) | — |
| Primitive policy 1 through 6 — the token boundary | no | out-of-scope (single-call refusals before any state is touched) | — |
| Non-goals | no | out-of-scope (they bound the claim, as Non-goal 1 does: no guarantee after the window, which the window summary encodes) | — |

One reading the model made plain, not a counterexample: under Execution Contract Database 1 the entry, the constituent's write and Duplicate Prevention's record commit together, so the token reads as seen with no entry only while Duplicate Prevention's store is unavailable. The outcome-unknown arm and the re-entry arm are reached through the outage alone, and a fail-open reading of the outage costs no second effect inside the window (the entry is there); the rule is rejected on the term fresh request (`Wiring_FreshMeansNotSeen`), not on a double effect. Capability requirement 16 is what Indeterminate outcome 10 and 13 rest on.

## Step 3 — bound saturation

Raise the model's scope once and confirm the verdict does not change:

- At the shipped bound (Window 2, 4 ticks, 3 calls, 1 outage, 2 commitment ids): 10,872 states, all nineteen entries hold; about 11 minutes. The twins are found at the same bound, the slowest (`-buggy-seen`, which needs an outage and an elapsed window) at 547 states.
- At 5 ticks (the clock one longer, so the window opens, elapses and a second window opens inside the run): 15,897 states, the same verdict, about 18 minutes. The count grows with the clock and the call budget, so the space is **not saturated** in count; no violation appeared in the larger space. A second outage and a third commitment id were not run: the run took about 11 minutes at the shipped bound, and the outage and the second caller's place already repeat the same arms (the twins that need them, `-buggy-seen` and `-buggy-candidates`, are found within the shipped bound).

## Outcome

- GAP rows: **none**.
- by-construction flags on load-bearing invariants: Invariant 7.2 (the arms are chosen by the entry and the check, so the invariant holds by their guards; the nearest break is covered by `-buggy-failopen`).
- Result: **all Invariants covered** — 2026-11-08. *Lineage entry: "Coverage cross-check 2026-11-08 — clean (every composition-level Invariant covered by a named check or out of scope with its reason; eleven twins each rejected by a named check)."*
