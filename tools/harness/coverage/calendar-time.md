# Coverage matrix — `calendar-time`

- **Pattern:** `atoms/calendar-time.md`
- **Model:** `calendar-time.als`, the static data model (+ 6 buggy twins `calendar-time-buggy-<defect>.als`), and `calendar-time.tla` + `calendar-time.cfg`, the operation sequences (+ 6 buggy twins `calendar-time-buggy-<defect>.tla`, each with its `.cfg`), 2026-11-11
- **Reviewer / date:** the models' author, the session that landed them — 2026-11-11. Not a fresh-context read; the next scheduled rescan owes one.
- **Formal-layer vote load-bearing claims:** the vote was cast no on 2026-11-08 and superseded by the maintainer's ruling of 2026-11-09 (every page gets an Alloy model of its valid states and a TLA+ model of its operation sequences; only the writing vetoes one). Neither was vetoed. The models take every Invariant the page states as load-bearing: Invariant 1.1, 1.2 (a place reads in a real zone and a real week), 2.1 (a place keeps its id), 3.1 (a reading follows the calendar, not the hours), 4.1 (a month moved lands in its month).

## Step 1 — harness re-run (must pass)

- Correct model: `node check.mjs ../../atoms/models/calendar-time.als` → `HOLDS` ✓ *(11 commands: 5 checks UNSAT, 6 runs SAT, at `for 4 but 4 Place, 3 Call`)*
- Correct model: `node check.mjs ../../atoms/models/calendar-time.tla` → `HOLDS` ✓ *(363,539 states, TLC about 34 s)*
- Alloy twins, one defect each, each `CAUGHT` by the one check it targets and no other: `-week-start-dropped` (`A_State_1`), `-change-zone-unguarded` (`A_Invariant_1_1`), `-zone-case-folded` (`A_Invariant_1_1`), `-change-week-unguarded` (`A_Invariant_1_2`), `-id-reused` (`A_Identity_2`), `-zone-normalized` (`A_Identity_3`).
- TLA+ twins, one defect each, each `CAUGHT`: `-id-reallocated` (`Inv2_1_KeepsId`), `-change-replaces` (`State2_NeverRemoved`), `-hours` (`Inv3_1_CalendarNotHours`), `-cases-overlap` (`ShowOneRelativeDay`), `-roll-over` (`Inv4_1_LandsInItsMonth`), `-reject-clamps` (`Op24_NoSuchDay`).
- Two facts in the Alloy model, both from outside the page: the time zone rules' shape (a link is a zone name naming a zone that is no link; Capability requirement 2) and the seam's fresh place id for each [Open] (Capability requirement 1). The TLA+ model has no ASSUME and no CONSTRAINT; the time zone rules (the zone names, a link, the 2026 offsets of Chicago and Berlin) are its definitions. Every rule the page promises is checked, none assumed.

## Step 2 — coverage matrix

The Alloy model builds every place version an admitted [Open] or [Change] can leave, back to the [Open] that recorded it. The TLA+ model runs three parts chosen at the start, since [Shift] reads no place and [Show] writes nothing: [Open] and [Change] over two place slots; one opened place (any zone name, any day of the week) with the clock moving an hour a step over 2026-10-28T12:00Z to 2026-10-30T12:00Z and every whole-hour instant from 2026-08-29 to 2026-11-03 read; one [Shift] call over the date range scaled to 2027 and 2028.

| Spec rule (no. + name) | Load-bearing (vote)? | Verdict | Model construct / reason |
|---|---|---|---|
| Invariant 1.1 — every place's time zone names a zone of the time zone rules | YES | `checked` covered (Alloy) | `A_Invariant_1_1` in `calendar-time.als`, on every version an admitted [Open] or [Change] leaves (Check 2.2). Broken by `calendar-time-buggy-change-zone-unguarded.als` ([Change] skips Operation 1) and `calendar-time-buggy-zone-case-folded.als` (the guard ignores case, Identity 4). Holds against the rules the place was written under: the page says nothing of a zone name a later release of the rules no longer carries (see Outcome). |
| Invariant 1.2 — every place carries a day of the week as its week start | YES | `checked` covered (Alloy) | `A_Invariant_1_2` (Check 2.3). Broken by `calendar-time-buggy-change-week-unguarded.als` ([Change] skips Operation 2). |
| Invariant 2.1 — the atom never changes a place's place id | YES | `checked` covered (TLA+) | `Inv2_1_KeepsId`, an action property over every [Open] and [Change] (Check 3.1). Nothing testable in Alloy: it compares a place with a later state. Broken by `calendar-time-buggy-id-reallocated.tla` ([Change] records the place under a fresh id). |
| Invariant 3.1 — [Show] never derives a relative day from the time between the instant and now | YES | `checked` covered (TLA+) | `Inv3_1_CalendarNotHours`: while the reader's date and the place stay the same, the clock moving on changes no instant's relative day. Nothing testable in Alloy: a reading is computed at the call over the calendar and the offsets, never stored. Broken by `calendar-time-buggy-hours.tla` (the day count from whole 24-hour days elapsed: 23:50 last night, read at noon, reads today). |
| Invariant 4.1 — with no days to add, [Shift] never answers a date outside the landing month | YES | `checked` covered (TLA+) | `Inv4_1_LandsInItsMonth`, over every [Shift] call with a day 1 to 31 of any month of 2027 and 2028, years -1..1, months -13..13, days -1..1, clamp or reject. Nothing testable in Alloy: an answer is computed at the call, never stored. Broken by `calendar-time-buggy-roll-over.tla` (the day not clamped: January 31 plus one month answers March 3). |
| State 1 — every place carries place id, time zone and week start | no | `checked` covered (Alloy) | `A_State_1` (Check 1.1). Broken by `calendar-time-buggy-week-start-dropped.als` ([Change] writes only the fields that differ and leaves the others blank). |
| State 2 — the atom never removes a place | no | `checked` covered (TLA+) | `State2_NeverRemoved`, an action property. Nothing testable in Alloy: a removal is a later state without the place. Broken by `calendar-time-buggy-change-replaces.tla` ([Change] removes the place and opens a new one). |
| Identity 2 — a place id is never reused | no | `checked` covered (Alloy) | `A_Identity_2`: two places never share a place id (Check 2.1); with no place removed (State 2) that is never reused. Rests on the fact `SeamSuppliesAFreshId` (Capability requirement 1, which the page cites); a copy without it breaks this check alone. Broken by `calendar-time-buggy-id-reused.als` ([Open] records an id the seam supplied an earlier call). |
| Identity 3 — a time zone is never normalized | no | `checked` covered (Alloy) | `A_Identity_3`: every place carries its time zone as the call that wrote it carried it. `ShowLinkKept` shows a place on the link US/Central. Broken by `calendar-time-buggy-zone-normalized.als` ([Open] records the zone a link names). |
| Identity 4 — a time zone compared codepoint for codepoint | no | `checked` covered (Alloy, through Invariant 1.1) | No check of its own: a comparison that is not codepoint for codepoint admits a string no zone name is, which `A_Invariant_1_1` catches. Broken by `calendar-time-buggy-zone-case-folded.als`. |
| Operation 24 — under reject, a day the landing month does not hold answers no-such-day | no | `checked` covered (TLA+) | `Op24_NoSuchDay`: such a call answers no-such-day or a refusal listed before it (Execution Contract Refusal 1), never a date. Broken by `calendar-time-buggy-reject-clamps.tla` (reject clamps as clamp does). |
| Operation 28 through 36 — the relative days | no | `checked` covered (TLA+) | `ShowOneRelativeDay`: at every now of the window, in every zone and for every week start, every instant read meets exactly one of the nine conditions, so the eight relative days cover every read date, one each; a probe confirmed all eight are reached. Broken by `calendar-time-buggy-cases-overlap.tla` (Operation 31 reads a day count of one or more, overlapping yesterday). |
| Operation 7 — [Change] with the place's own time zone and week start writes nothing | no | `owed` (TLA+: across steps) | Both models take it as the guard of [Change] (no version follows, no step); no check counts writes, so a twin that writes anyway is not caught. A TLA+ check over a write count is owed. |
| Operation 12 through 21 — [Day] and [Resolve] across a clock change | no | `owed` | Each answer is computed at the call from the zone's offsets, and the conformance table proves them row by row (Chicago, Havana, Apia); neither model computes a day span or a resolution. A model over a zone's offset changes could state them (no instant in two dates, a skipped time moved by the gap's length). |

## Step 3 — bound saturation

Alloy reports no state count, so the scope is raised once and the verdict compared:

- At `for 4 but 4 Place, 3 Call` (the shipped bound): all 5 checks UNSAT, all 6 runs SAT.
- At `for 5 but 6 Place, 4 Call` on a scratch copy: the same verdicts → **saturated** ☑. A place's shape is three fields and the chain of versions it was built from; three calls build a place changed twice and two places side by side.

TLA+: the places part reaches every assignment of two slots (each slot unopened, or opened on one of three zone names and seven days, under the id order the seam gave); a third slot adds states and no new shape of id or removal. The show part covers every zone name and week start at every hour of a window that crosses midnight in both zones, with the instants read crossing both zones' 2026 clock changes and reaching every relative day. The shift part enumerates every call within its bounds at depth one (240,912 calls).

## Outcome

- GAP rows: **none**. Owed: Operation 7 and Operation 12 through 21.
- by-construction flags on load-bearing invariants: none.
- Under-specified, not cured (no rule changes, no round owed): the page holds Invariant 1.1 only at the write. Its Edge case "A zone whose rules change" says what a change of offsets does to an answer and nothing of a zone name a later release of the time zone rules no longer carries (a name the IANA database has removed before), after which a place's time zone names no zone and every answer about it is undefined; both models read one set of rules.
- Result: **all Invariants covered** — 2026-11-11. *Lineage entry: "Coverage cross-check 2026-11-11 — every Invariant covered by a named check, each broken by its twin; Operation 7 and 12 through 21 owed."*
