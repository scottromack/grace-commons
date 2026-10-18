# Coverage matrix — `verified-repair`

- **Pattern:** `compositions/verified-repair.md`
- **Models:** `verified-repair.tla` (the commit path) + `-buggy-nocas`, `-buggy-nostale`, `-buggy-basetree`, `-buggy-lateread` + probes `-probe-inflight`, `-probe-conflict`, `-probe-both`; `verified-repair-settle.tla` (the round's settling) + `-buggy-unaged`, `-buggy-latefinding`, `-buggy-oneactor`, `-buggy-onesort` + probes `-probe-displaced`, `-probe-parted`, `-probe-opens`; `verified-repair-budget.tla` (the round budget) + `-buggy-young`, `-buggy-unbounded`, `-buggy-ruledany` + probes `-probe-pastbudget`, `-probe-ruled`, `-probe-reset`
- **Reviewer / date:** the models' author, the session that drafted them — 2026-10-17. Not a fresh-context read; the next scheduled rescan owes one.
- **Formal-layer vote load-bearing claims:** one writer per repository (Invariant 2, Concurrency 1); no repair before the round settles (Invariant 1.1); the round's bounded repair (Invariant 8.1).

## Step 1 — harness re-run (must pass)

- `verified-repair.tla` → `HOLDS` ✓ *(61,659 states; MaxTries = 2, MaxPerson = 1)*
- `-buggy-nocas` → `CAUGHT` ✓ *(146 states; Conc1_OneWriter)* · `-buggy-nostale` → `CAUGHT` ✓ *(210; Inv2_1)* · `-buggy-basetree` → `CAUGHT` ✓ *(201; Inv2_2)* · `-buggy-lateread` → `CAUGHT` ✓ *(1,337; Inv7_3)*
- `-probe-inflight` *(211)*, `-probe-conflict` *(146)*, `-probe-both` *(1,158)* → each rejected ✓
- `verified-repair-settle.tla` → `HOLDS` ✓ *(94,031 states; W = 1, SettleBound = 1, MaxTriage = 3)*
- `-buggy-unaged` → `CAUGHT` ✓ *(167; Inv1_1)* · `-buggy-latefinding` → `CAUGHT` ✓ *(7; Inv5_1)* · `-buggy-oneactor` → `CAUGHT` ✓ *(1,146; Inv5_1)* · `-buggy-onesort` → `CAUGHT` ✓ *(31; Inv5_1)*
- `-probe-displaced` *(18)*, `-probe-parted` *(257)*, `-probe-opens` *(136)* → each rejected ✓
- `verified-repair-budget.tla` → `HOLDS` ✓ *(518 states; Budget = 1, MaxRounds = 3, MaxRulings = 1)*
- `-buggy-young` → `CAUGHT` ✓ *(35; Inv8_1)* · `-buggy-unbounded` → `CAUGHT` ✓ *(120; Inv8_1)* · `-buggy-ruledany` → `CAUGHT` ✓ *(252; Inv8_1)*
- `-probe-pastbudget` *(4)*, `-probe-ruled` *(226)*, `-probe-reset` *(223)* → each rejected ✓

Each twin is the module byte for byte with one constant flipped, so it has the correct model as its passing sibling, and `node isolate.mjs` finds each of the eleven dedicated: it breaks the invariant it names and no other.

## Step 2 — coverage matrix

| Spec invariant (no. + name) | Load-bearing (vote)? | Verdict | Model construct / reason |
|---|---|---|---|
| Invariant 1.1 — no council commit answers a round before it settles | YES | **covered** | `Inv1_1` (settle): the intent's position follows the settling record, read off the whole journal at each prefix. `-buggy-unaged` (Action wiring 52 dropped) is rejected: an earlier sound verdict lands after [Repair]'s read and displaces the counted verdict it read. |
| Invariant 1.2 — a verdict counts only with the round's snapshot hash | no | out-of-scope (within-action guard) | Action wiring 4 compares a verdict's hash with the round's record at the call; the settling model runs one snapshot. |
| Invariant 2.1 — the parent holds the round's snapshot | YES | **covered** | `Inv2_1` (commit path), read off the commits. `-buggy-nostale` (Action wiring 15 dropped) is rejected after a person's commit to the page. |
| Invariant 2.2 — every changed line is in the change set | YES | **covered** | `Inv2_2` (commit path). `-buggy-basetree` (Action wiring 23 dropped) is rejected after a person's commit to another page. |
| Invariant 3.1 — claims need the maintainer's ruling | no | out-of-scope (within-action guard) | Action wiring 19 and 56 read the rulings at the call; a ruling a read does not yet show gates the patch, so no interleaving turns a missing ruling into a landing. |
| Invariant 4.1 — a repair answers the side indicted | no | out-of-scope (within-action guard) | Action wiring 20. |
| Invariant 5.1 — a deciding count is sorted twice | no | **covered** | `Inv5_1` (settle). `-buggy-onesort` (Action wiring 11 dropped), `-buggy-oneactor` (Term counted triage's one-role clause dropped) and `-buggy-latefinding` (the page at e54d344) are rejected. The one-role clause, not Action wiring 37, keeps the count on two triagers when a triager's two sorts race. |
| Invariant 6.1 — no commit answers a formal engine's malformed verdict | no | out-of-scope (within-action guard) | Action wiring 35 and 40; no engine reports in the settling model. |
| Invariant 7.1 — every commit carries the trailer whose intent carries the round | no | by-construction | Only a [Repair] call makes a council commit, after its open, and the trailer names that call's intent. |
| Invariant 7.2 — a purged payload answers unverifiable | no | out-of-scope (no purge) | A check's answer over a destroyed payload, not an interleaving; every record stays inside the retention period. |
| Invariant 7.3 — no intent precedes a council-commit ancestor's | no | **covered** | `Inv7_3` (commit path). `-buggy-lateread` (the open before the read) is rejected. |
| Invariant 8.1 — repair is bounded | YES | **covered** | `Inv8_1` (budget), read off the whole journal so that a position read short is caught. `-buggy-young`, `-buggy-unbounded` and `-buggy-ruledany` are rejected. |
| Concurrency 1 — two [Repair] calls on one repository serialize | YES | **covered** | `Conc1_OneWriter` (commit path) checks what the page relies on, that of two commits built on one head at most one lands. Recoverable Invocation's critical section is not modelled, which only adds behaviours; with no commit fence two council commits are in flight at once whatever the section does (`-probe-inflight`). `-buggy-nocas` (Capability requirement 13 and 20 dropped) is rejected. |

## Step 3 — bound saturation

- **Time.** The settling and budget models carry each record's age capped at the largest bound read, so neither has a horizon, and the commit path reads no clock. There is no tick bound to raise.
- **Record budgets.** These grow the space and are recorded as statements at the budget: the commit path at `MaxPerson = 1` has 61,659 states and at `MaxPerson = 2` has 263,067, still holding (run past the harness's cap of 200,000); the settling model at `MaxTriage = 2` has 4,861 and at `MaxTriage = 3` has 94,031, holding; the budget model at three freezes and one ruling has 518 and at four and two has 14,740, holding.

## Outcome

- GAP rows: none.
- by-construction flags on load-bearing invariants: none (Invariant 7.1 is by-construction and not vote-named).
- Result: **one finding, cured on the page.** The settling model found that a reader's malformed verdict can be written after the round's settling record, since [Report] refuses already-counted and round-closed only from what its read shows; its finding was a counted finding no counted triage could reach, so Check 5.1 failed on a council that kept every rule. Term counted finding now reads a malformed verdict only up to the settling record. The commit-path model also showed that Invariant 2 rests on Capability requirement 13 and not on Recoverable Invocation's one writer per act key, and the page's WHY now says so. — Coverage cross-check 2026-10-17.
