# Coverage matrix — `recurrence`

- **Pattern:** `atoms/recurrence.md`
- **Model:** `recurrence.als` + buggy twin `recurrence-buggy.als`
- **Reviewer / date:** the model's author, the session that landed it — 2026-11-08. Not a fresh-context read; the next scheduled rescan owes one.
- **Formal-layer vote load-bearing claims:** the vote was cast yes on the maintainer's ruling of 2026-11-06 (after-grounding item 14: "Recurrence gets an Alloy model (it is mostly shape)"), which names the page's shape and no one invariant. The model therefore takes every Invariant the page states as load-bearing: Invariant 1.1, 1.2 (a series is one repeat); Invariant 2.1, 2.2 (a series keeps its parts, and ends only sooner); Invariant 3.1 through 3.4 (an occurrence is a date the series generates).

## Step 1 — harness re-run (must pass)

- Correct model: `node check.mjs ../../atoms/recurrence.als` → `HOLDS` ✓ *(30 commands: 12 checks UNSAT, 18 runs SAT)*
- Buggy twin: `node check.mjs ../../atoms/recurrence-buggy.als --buggy` → `CAUGHT` ✓ *(`A_Invariant_2_2` finds the counterexample; the other eleven checks hold)*

## Step 2 — coverage matrix

The model bounds: six ordered dates, three periods, up to four series for the checks that pair a series before and after a call and up to three for the rest, integers of five bits. The caps are scaled to 3 (the page's 1,000), the limit cap equal to the occurrence cap as the page has them by default. A call that writes a series is a predicate over the series before and the series after it. Twelve named `check` asserts; eighteen `run` non-vacuity predicates. Calendar arithmetic (which dates a month day, an ordinal or a week start names) is left to the conformance table; the model takes each period's picks as given.

| Spec invariant (no. + name) | Load-bearing (vote)? | Verdict | Model construct / reason |
|---|---|---|---|
| Invariant 1.1 — no limit and end date both | YES | **covered** | `A_Invariant_1_1`: every series `openAccepts` carries at most one (Operation 11), and `step` (`exceptCall`, `restoreCall`, `endCall`) leaves one from a series that had at most one (`endCall` swaps the limit for the end date, Operation 28). |
| Invariant 1.2 — no position without a selector | YES | **covered** | `A_Invariant_1_2`: every series `openAccepts` that carries a position carries a selector (Operation 10), and no `step` changes either, both being fixed parts. |
| Invariant 2.1 — fixed parts never change | YES | **covered** | `A_Invariant_2_1` names each of the ten fields (series id, start, frequency, interval, week start, months, month days, day entries, positions, and the picks the fixed parts decide) after any `step`. |
| Invariant 2.2 — [End] never moves the end bound later | YES | **covered** | `A_Invariant_2_2`: after `endCall` the series has one end bound, no later than the end bound before it where there was one. Twin `recurrence-buggy.als` drops Operation 27's guard from `endCall` and is rejected by this check. |
| Invariant 3.1 — no excepted date answered | YES | **covered** | `A_Invariant_3_1`, over every series and every window. |
| Invariant 3.2 — no date before the start answered | YES | **covered** | `A_Invariant_3_2`; `ShowPositionCountsPastTheStart` and `ShowStartNotGenerated` show the case it guards (a pick before the start that still holds a place, and a start the series does not generate). |
| Invariant 3.3 — no date after the end bound answered | YES | **covered** | `A_Invariant_3_3`, for a limit's end bound and an end date's alike (`endBound`). |
| Invariant 3.4 — no date outside the window answered | YES | **covered** | `A_Invariant_3_4`. |
| the order the terms build in (the NOTE after Term window count) | no | **covered** | `A_TermsBuildInOrder`: selected dates within picked, generated within selected, occurrences within generated. |
| Term end bound — a date taken out still counts toward a limit | no | **covered** | `A_ExceptionsKeepTheBound` (a step of `exceptCall` or `restoreCall` leaves the end bound as it was); `ShowLimitCountsATakenOutDate` shows a series holding fewer occurrences than its limit. |
| Operation 12, Operation 37 — a limit is a positive count within the limit cap | no | **covered** | `A_LimitHoldsAtMostItsDates` (no more occurrences than the limit) and `A_LimitFitsOneCall` (an opened series' limit within the cap, and every occurrence within one call because the limit cap equals the occurrence cap, the Decisions entry "A cap on the limit"); `ShowAtTheLimitCap` and `ShowOverTheLimitCap` bracket the cap. |
| Operation 7, Operation 8 — month days not on a weekly series; an ordinal day entry only on a monthly or yearly series with no month days | no | by-construction (`openAccepts` states both, and every run that builds an opened series depends on them; no check asserts them apart from the guard itself) | `ShowDayEntryWithMonthDays` (a bare day entry beside month days), `ShowDayEntryWithoutMonths` (an ordinal day entry), `ShowDayEntryWithMonths`. |
| Operation 5, 6, 9, and the range half of Operation 8 — a number's range | no | out-of-scope (a check on a number, not on a shape; the model keeps only the sign of a position and an ordinal) | — |
| Term period through Term yearly picks — what a frequency's picks name; week start; interval | no | out-of-scope (calendar arithmetic, proved row by row by the conformance table; the model takes each period's picks as given) | — |
| Identity 1, 2 — a series id never reused | no | out-of-scope (the host's at the seam, Capability requirement 1); the series id is carried through every call so a call that changed it would fail Invariant 2.1 | — |
| Daylight-saving cases | no | out-of-scope (the wiring with Calendar Time, not this page; the Ledger's `formal:` line says so) | — |

## Step 3 — bound saturation

Alloy reports no state count, so the scope is raised once and the verdict compared:

- At 6 dates, 3 periods, 4 series (the shipped bound): all 12 checks UNSAT, all 18 runs SAT.
- At 8 dates, 4 periods, 5 series (the series-pairing checks), 4 series (the rest): the same — all 12 checks UNSAT, all 18 runs SAT; the run took twice as long and no check changed its verdict → **saturated** ☑. A series' shape is its picks, its positions, its start and its two bounds, and every distinct combination of these appears within six dates and three periods.

## Outcome

- GAP rows: **none**.
- by-construction flags on load-bearing invariants: none; the one by-construction row (Operation 7 and 8) is a guard on `[Open]` that the Invariants do not rest on, and none of the vote's claims depends on it.
- Result: **all Invariants covered** — 2026-11-08. *Lineage entry: "Coverage cross-check 2026-11-08 — clean (every Invariant covered by a named check, 2.2 caught by its twin; saturation confirmed at 8 dates, 4 periods)."*
