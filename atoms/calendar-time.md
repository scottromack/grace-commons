---
title: Calendar Time
parent: Atomic Concepts
has_toc: true
toc: true
---

# Calendar Time

<details markdown="block">
<summary>Table of contents</summary>
{: .text-delta }
1. TOC
{:toc}
</details>

## Summary

Calendar Time says what a date and a time of day mean in a place. A place is a time zone, such as America/Chicago, and the day its weeks start on, such as Sunday. The atom keeps places, and in a place it answers four questions. Which stretch of time does a date cover there? Usually 24 hours, but 23 or 25 on the days the clocks change by an hour, and a day can start at 1 AM where the clocks change at midnight. Which moment does a local time name there? A time the clocks skip, such as 2:30 AM on the night they go forward, or show twice, such as 1:30 AM on the night they go back, is settled by one of four choices: the usual one (the time moves forward past a skip, and the first of two repeats is taken), the earlier moment, the later moment, or a refusal. What date is a date plus some years, months and days? January 31 plus one month is February 28, or February 29 in a leap year, or is refused, never March 3. And how does a moment read to a person in their place? Today, yesterday, tomorrow, the day of this week, last week, this month, last month, or the full date (a date further ahead than tomorrow reads as the full date), counted by the calendar where the person is rather than by hours, so something posted at 11:50 last night reads "yesterday", with the exact local date and time given beside it. Calendar Time decides nothing about repeating events, working days, holidays, other calendars, or the words a reading is shown in.

---

## Intent

<details markdown="block">
<summary>WHY</summary>

Software gets dates wrong in a few recurring ways, and each is a question of what a date means in a place: a deadline of November 7 that ends at midnight in the wrong city; an alarm for 2:30 AM on the night the clocks go forward; a monthly charge on January 31 that lands on March 3; a comment from 11:50 last night labeled "12 hours ago" when the reader thinks of it as yesterday. JavaScript's Temporal settled most of these after years of public design, and this atom takes Temporal's decisions as its answer key, not its API: a local time the clocks skip moves forward by the skipped length, and a local time they show twice takes the first of its two moments, unless the caller chooses the earlier moment, the later one, or a refusal; moving a date by months clamps the day to the month's end or refuses, as the caller chooses; the months move first and the days after. What Temporal leaves to each pattern that shows a time, how a time reads to a person, the maintainer ruled on: by calendar boundaries in the reader's place, never by a count of hours or days, so "last month" means the previous calendar month, with the exact date and time always one tap away, and every pattern that shows a time reads it here rather than inventing its own. The atom keeps places, a time zone and the day the weeks start, because a reading needs the reader's place and a date means a stretch of time only in some place; everything else it answers is computed at the call from the place, the deployment's time zone rules and, for a reading, now.

</details>

## Structure

### Identity model

```
Identity 1: The atom MUST identify a place by the place id.
Identity 2: The atom MUST NOT reuse a place id.
Identity 3: The atom MUST NOT normalize a time zone.
Identity 4: The atom MUST compare a time zone with the zone names codepoint for codepoint.
```

Term place: a time zone and the day the weeks start on there, where dates are read — a [Place].

Term place id: the opaque value naming one place — a [Place Id]; unique for the system's life.

Term time zone: the name of a zone in the time zone rules, such as America/Chicago — a [Time Zone]; recorded as the call carries it.

Term time zone rules: the deployment's record of every zone's offsets from UTC and of when each offset took effect, such as the IANA Time Zone Database.

Term zone names: every name the time zone rules carry, a zone's own name or a link to a zone, such as America/Chicago or the link US/Central.

Term seam: the atom's I/O boundary as the section titled Logic Confinement Principle in `execution-contract.md` declares it; the host injects each place id and the clock reading, now, here.

### State

```
State 1: EVERY place MUST carry place id, time zone and week start.
State 2: The atom MUST NOT remove a place.
```

Term week start: the day of the week a place's weeks start on — a [Week Start]; Sunday in the United States, Monday in most of Europe and in ISO 8601.

Term day of the week: monday | tuesday | wednesday | thursday | friday | saturday | sunday.

Term calendar: the Gregorian calendar of ISO 8601, run back before 1582 as if always in force.

Term calendar date: a year, a month from 1 through 12 and a day from 1 through the month's length, naming a day the calendar holds, such as 2028-02-29 but not 2026-02-29.

Term month length: the number of days a month of the calendar holds: 28, 29, 30 or 31.

Term local date: a calendar date as a place's clock shows one, carrying no place of its own — a [Local Date].

Term date range: the calendar dates from 0001-01-01 through 9999-12-31.

Term local time: a time of day on a 24-hour clock, in hours, minutes and whole seconds — a [Local Time].

Term times of day: the local times from 00:00:00 through 23:59:59; the calendar has no leap second.

Term offset: how far a place's clock stands from UTC at an instant — an [Offset].

Term now: the deployment's clock reading at the call, as Execution Contract Logic confinement 11 declares it.

NOTE: an instant is the grammar's rule noun, a point in time that belongs to no place; how finely the deployment's clock reads one, and what the clock guarantees, are the deployment's (Execution Contract Logic confinement 7).

### Capability requirement

```
Capability requirement 1: The deployment MUST supply at the seam, for each [Open] call, a place id no place has carried PER Execution Contract Logic confinement 3.
Capability requirement 2: The deployment MUST supply the time zone rules.
Capability requirement 3: The deployment MUST supply now at the seam PER Execution Contract Logic confinement 11.
Capability requirement 4: The deployment MUST supply the database PER Execution Contract Database 1 through 6, Execution Contract Read 1 through 4 and Execution Contract Refusal 1.
```

### Operations

```
open(time_zone, week_start)
  answers place_id
  refuses unknown-time-zone | invalid-week-start | storage-failure

change(place_id, time_zone, week_start)
  answers ok
  refuses not-known | unknown-time-zone | invalid-week-start | storage-failure

read(place_id)
  answers place
  refuses not-known

day(place_id, local_date)
  answers day_span
  refuses not-known | invalid-date | out-of-range

resolve(place_id, local_date, local_time, choice)
  answers instant
  refuses not-known | invalid-date | out-of-range | invalid-time | invalid-choice | skipped-time | repeated-time

shift(local_date, years, months, days, overflow)
  answers local_date
  refuses invalid-date | out-of-range | invalid-amount | invalid-overflow | no-such-day

show(place_id, instant)
  answers reading
  refuses not-known | out-of-range
```

```
Operation 1: IF the time zone IS NOT IN the zone names THEN a zone action MUST answer unknown-time-zone.
Operation 2: IF the week start IS NOT IN the days of the week THEN a zone action MUST answer invalid-week-start.
Operation 3: [Open] MUST record EXACTLY ONE place carrying the place id the seam supplies and the time zone and the week start of the call.
Operation 4: [Open] MUST answer the place id.
Operation 5: IF no place EXISTS for the place id THEN a place action MUST answer not-known.
Operation 6: IF the time zone DOES NOT EQUAL the place's time zone OR the week start DOES NOT EQUAL the place's week start THEN [Change] MUST record the place carrying the time zone and the week start of the call.
Operation 7: IF the time zone EQUALS the place's time zone AND the week start EQUALS the place's week start THEN [Change] MUST NOT write.
Operation 8: [Change] MUST answer ok.
Operation 9: [Read] MUST answer the place's place id, time zone AND week start.
Operation 10: IF the local date IS NOT IN the calendar dates THEN a date action MUST answer invalid-date.
Operation 11: IF the local date IS NOT IN the date range THEN a date action MUST answer out-of-range.
Operation 12: [Day] MUST answer the day start AND the day end.
Operation 13: IF the local time IS NOT IN the times of day THEN [Resolve] MUST answer invalid-time.
Operation 14: IF the choice IS NOT IN the choices THEN [Resolve] MUST answer invalid-choice.
Operation 15: IF the wall time IS IN the plain times THEN [Resolve] MUST answer the matching instant.
Operation 16: IF the wall time IS IN the skipped times AND the choice IS IN the forward choices THEN [Resolve] MUST answer the forward resolution.
Operation 17: IF the wall time IS IN the skipped times AND the choice EQUALS earlier THEN [Resolve] MUST answer the back resolution.
Operation 18: IF the wall time IS IN the skipped times AND the choice EQUALS reject THEN [Resolve] MUST answer skipped-time.
Operation 19: IF the wall time IS IN the repeated times AND the choice IS IN the first choices THEN [Resolve] MUST answer the earlier match.
Operation 20: IF the wall time IS IN the repeated times AND the choice EQUALS later THEN [Resolve] MUST answer the later match.
Operation 21: IF the wall time IS IN the repeated times AND the choice EQUALS reject THEN [Resolve] MUST answer repeated-time.
Operation 22: IF the amount IS NOT IN the signed amounts THEN [Shift] MUST answer invalid-amount.
Operation 23: IF the overflow IS NOT IN the overflows THEN [Shift] MUST answer invalid-overflow.
Operation 24: IF the local date's day EXCEEDS the landing month's length AND the overflow EQUALS reject THEN [Shift] MUST answer no-such-day.
Operation 25: IF the shifted date IS NOT IN the date range THEN [Shift] MUST answer out-of-range.
Operation 26: [Shift] MUST answer the shifted date.
Operation 27: IF the read date IS NOT IN the date range THEN [Show] MUST answer out-of-range.
Operation 28: IF the day count EQUALS 0 THEN [Show] MUST answer today as the relative day.
Operation 29: IF the day count EQUALS 1 THEN [Show] MUST answer yesterday as the relative day.
Operation 30: IF the day count EQUALS -1 THEN [Show] MUST answer tomorrow as the relative day.
Operation 31: IF the day count EXCEEDS 1 AND the week count EQUALS 0 THEN [Show] MUST answer current-week as the relative day.
Operation 32: IF the day count EXCEEDS 1 AND the week count EQUALS 1 THEN [Show] MUST answer last-week as the relative day.
Operation 33: IF the week count EXCEEDS 1 AND the month count EQUALS 0 THEN [Show] MUST answer current-month as the relative day.
Operation 34: IF the week count EXCEEDS 1 AND the month count EQUALS 1 THEN [Show] MUST answer last-month as the relative day.
Operation 35: IF the week count EXCEEDS 1 AND the month count EXCEEDS 1 THEN [Show] MUST answer full-date as the relative day.
Operation 36: IF the day count DOES NOT EXCEED -2 THEN [Show] MUST answer full-date as the relative day.
Operation 37: [Show] MUST answer the read date, the read time, the offset AND the read date's day of the week.
Operation 38: A query action MUST NOT write.
```

Term zone action: [Open] | [Change] — the actions that take a time zone and a week start.

Term place action: [Change] | [Read] | [Day] | [Resolve] | [Show] — the actions that name a place by the place id.

Term date action: [Day] | [Resolve] | [Shift] — the actions that take a local date.

Term query action: [Read] | [Day] | [Resolve] | [Shift] | [Show] — the actions that write nothing.

Term day start: the earliest instant at which the place's clock shows the local date or a later date — a [Day Start]; 00:00 on most days, the first time the clock shows on a day whose midnight the clock skips, and the day end itself on a date the clock skips whole.

Term day end: the day start of the date that follows the local date — a [Day End]; a day covers its day start and every instant up to the day end, the day end not included: the day end is the next date's day start, so no instant lies in two dates; a day lasts 24 hours unless the clocks change on it, when the change of the offset shortens or lengthens it: 23 or 25 hours for an hour's change, 0 hours on a date the clock skips whole.

Term day span: a local date's day start and day end in a place — a [Day Span]; computed at the call, never stored.

Term choice: compatible | earlier | later | reject — what [Resolve] answers for a wall time the place's clock skips or shows twice — a [Choice]; compatible is Temporal's default and RFC 5545's: forward for a skipped time, the earlier match for a repeated time.

Term forward choice: compatible | later — the choices that move a skipped time forward.

Term first choice: compatible | earlier — the choices that take a repeated time's earlier match.

Term wall time: the local date and the local time of a [Resolve] call, read on the clock of the call's place.

Term matching instant: an instant at which the place's clock shows the wall time.

Term plain time: a wall time that exactly one instant matches; a wall time at the moment the offset changes is read as the clock shows it after the change, so where the clocks go forward at 02:00 by an hour, 02:00:00 is skipped and 03:00:00 plain, and where they go back from 02:00 to 01:00, 01:00:00 through 01:59:59 are repeated and 02:00:00 plain.

Term skipped time: a wall time that no instant matches: the place's clock jumps over the wall time, as when the clocks go forward.

Term repeated time: a wall time that two instants match: the place's clock shows the wall time twice, as when the clocks go back.

Term gap: the local times a place's clock jumps over at one change of the place's offset; the gap's length is how much the offset grows at the change, an hour in most places.

Term forward resolution: the matching instant of the wall time moved forward by the length of the gap the wall time falls in — the instant the clock shows as 03:30 for a wall time of 02:30 in a one-hour gap opening at 02:00.

Term back resolution: the matching instant of the wall time moved back by the length of the gap the wall time falls in — the instant the clock shows as 01:30 for the same wall time.

Term earlier match: the first of a repeated time's two matching instants.

Term later match: the second of a repeated time's two matching instants.

Term amount: the years, the months and the days a [Shift] call moves a local date by, each a number as the call carries it, a whole number or not.

Term signed amount: an amount whose years, months and days are each a whole number, and are all zero or more, or all zero or less.

Term overflow: clamp | reject — what [Shift] does where the landing month holds no day of the local date's number — an [Overflow].

Term month move: ((years * 12) + months) — the months a [Shift] call moves the local date's month by.

Term landing month: the month of the calendar that lies the month move months from the local date's month, counted on across the end of a year: a month move of 13 takes January 2026 to February 2027, and a month move of -1 takes it to December 2025.

Term landing day: the local date's day, or the landing month's length where the local date's day exceeds the landing month's length.

Term shifted date: the date that lies the amount's days from the landing month's landing day, counted on across the end of a month and of a year: 31 days after 2026-02-28 is 2026-03-31, and 1 day before 2026-01-01 is 2025-12-31; the date [Shift] answers.

Term read date: the local date the place's clock shows at the instant.

Term read time: the local time the place's clock shows at the instant, to the whole second the instant falls in.

Term reader's date: the local date the place's clock shows at now.

Term day count: how many calendar days the read date lies back from the reader's date: 0 for the reader's date itself, 1 for the date before, -1 for the date after.

Term week: the seven dates from a date whose day of the week is the place's week start.

Term week count: how many weeks the read date's week lies back from the week holding the reader's date: 0 for the reader's own week, 1 for the week before.

Term month count: how many calendar months the read date's month lies back from the reader's date's month: 0 for the reader's own month, 1 for the month before.

Term relative day: today | yesterday | tomorrow | current-week | last-week | current-month | last-month | full-date — where the read date stands from the reader's date, which a person reads in place of the date — a [Relative Day]; current-week is shown by the read date's day of the week, such as Tuesday, and full-date by the read date itself.

Term reading: the relative day, the read date, the read time, the offset and the read date's day of the week — a [Reading]; computed at each [Show], never stored.

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the places |
|---|---|---|---|
| [Open] | time zone among the zone names, week start a day of the week, database accepts | the place id | one place lands, carrying the time zone and the week start (Operation 3) |
| a zone action | time zone not among the zone names | [Unknown Time Zone] | none (Operation 1) |
| a zone action | week start not a day of the week | [Invalid Week Start] | none (Operation 2) |
| [Change] | time zone or week start differs from the place's | ok | the place carries the call's time zone and week start (Operation 6) |
| [Change] | both equal to the place's | ok | none — no write (Operation 7) |
| [Read] | the place exists | the place id, time zone and week start | none (Operation 9) |
| [Day] | a calendar date in the date range | the day start and the day end | none (Operation 12) |
| a date action | the local date not a calendar date, such as 2026-02-29 | [Invalid Date] | none (Operation 10) |
| a date action | the local date outside the date range | [Out Of Range] | none (Operation 11) |
| [Resolve] | local time not a time of day | [Invalid Time] | none (Operation 13) |
| [Resolve] | choice not one of the four | [Invalid Choice] | none (Operation 14) |
| [Resolve] | a plain time | the matching instant | none (Operation 15) |
| [Resolve] | a skipped time, compatible or later | the forward resolution | none (Operation 16) |
| [Resolve] | a skipped time, earlier | the back resolution | none (Operation 17) |
| [Resolve] | a skipped time, reject | [Skipped Time] | none (Operation 18) |
| [Resolve] | a repeated time, compatible or earlier | the earlier match | none (Operation 19) |
| [Resolve] | a repeated time, later | the later match | none (Operation 20) |
| [Resolve] | a repeated time, reject | [Repeated Time] | none (Operation 21) |
| [Shift] | the years, months and days of two signs, or not whole | [Invalid Amount] | none (Operation 22) |
| [Shift] | overflow neither clamp nor reject | [Invalid Overflow] | none (Operation 23) |
| [Shift] | the landing month too short for the day, reject | [No Such Day] | none (Operation 24) |
| [Shift] | the landing month too short for the day, clamp | the shifted date, from the landing month's last day | none (Operation 26) |
| [Shift] | the shifted date outside the date range | [Out Of Range] | none (Operation 25) |
| [Show] | the read date outside the date range | [Out Of Range] | none (Operation 27) |
| [Show] | the read date is the reader's date | today, with the read date, read time, offset and day of the week | none (Operation 28, Operation 37) |
| [Show] | the date before the reader's date | yesterday | none (Operation 29) |
| [Show] | the date after the reader's date | tomorrow | none (Operation 30) |
| [Show] | earlier in the reader's week | current-week | none (Operation 31) |
| [Show] | in the week before the reader's week | last-week | none (Operation 32) |
| [Show] | earlier in the reader's month, two or more weeks back | current-month | none (Operation 33) |
| [Show] | in the month before the reader's month, two or more weeks back | last-month | none (Operation 34) |
| [Show] | two or more months back, or two or more days ahead | full-date | none (Operation 35, Operation 36) |
| a place action | the place id names nothing | [Not Known] | none (Operation 5) |
| a writing call | database refuses the write | [Storage Failure] | none (Execution Contract Read 4) |
| any call | its read of the database fails | `state-unavailable` | none (Execution Contract Read 1, Execution Contract Read 3) |
| any call | more than one refusal applies | the refusal listed first on the action's refuses line | none (Execution Contract Refusal 1) |

### Invariants

- **Invariant 1 — A place reads in a real zone and a real week.**
  ```
  Invariant 1.1: EVERY place's time zone MUST name a zone of the time zone rules.
  Invariant 1.2: EVERY place MUST carry a day of the week as the place's week start.
  ```
- **Invariant 2 — A place keeps its id.**
  ```
  Invariant 2.1: The atom MUST NOT change a place's place id.
  ```
- **Invariant 3 — A reading follows the calendar, not the hours.**
  ```
  Invariant 3.1: [Show] MUST NOT derive a relative day from the time between the instant and now.
  ```
- **Invariant 4 — A month moved lands in its month.**
  ```
  Invariant 4.1: IF the amount's days EQUALS 0 THEN [Shift] MUST NOT answer a date outside the landing month.
  ```

## Examples

The same atom in four uses, then the rejection paths. Instants are written in UTC with a trailing Z; local dates and times are the place's own.

### A team reads its comments

A team's deployment opens a place for its Chicago office: `open("America/Chicago", sunday)` answers [Place Id] `p1`. At noon on Saturday, November 7, 2026 in Chicago (now is 2026-11-07T18:00Z), a teammate opens a thread, and each comment's time is read with `show(p1, …)`:

- posted at 2026-11-07T15:00Z — today, 09:00:00 at an offset of −06:00, on a saturday;
- posted at 2026-11-07T05:50Z — yesterday, 23:50:00 on Friday: about twelve hours ago, but on the calendar it was yesterday;
- posted at 2026-11-03T15:00Z — current-week, shown as Tuesday;
- posted at 2026-10-28T15:00Z — last-week, the week from Sunday, October 25, though October 28 also lies in the month before;
- posted at 2026-10-10T15:00Z — last-month;
- posted at 2026-09-30T15:00Z — full-date: September 30, 2026;
- a reminder for 2026-11-08T18:00Z — tomorrow.

Each reading carries the exact local date, time and offset beside its relative day, so the thread shows "last month" and, one tap away, October 10, 2026, 10:00 at −05:00. Three weeks later, with now at 2026-11-28T18:00Z, a comment posted at 2026-11-09T15:00Z reads current-month.

### The nights the clocks change

In Chicago the clocks go forward at 02:00 on March 8, 2026 and back at 02:00 on November 1, 2026.

- `day(p1, 2026-03-08)` answers a [Day Start] of 2026-03-08T06:00Z and a [Day End] of 2026-03-09T05:00Z: a day of 23 hours. `day(p1, 2026-11-01)` answers 2026-11-01T05:00Z and 2026-11-02T06:00Z: 25 hours.
- An alarm set for 02:30 on March 8: `resolve(p1, 2026-03-08, 02:30:00, compatible)` answers 2026-03-08T08:30Z, which the clock shows as 03:30: the time moves forward by the hour the clock skips. The choice later answers the same; earlier answers 2026-03-08T07:30Z, shown as 01:30; reject is refused as [Skipped Time].
- A meeting at 01:30 on November 1: `resolve(p1, 2026-11-01, 01:30:00, compatible)` answers 2026-11-01T06:30Z, the first 01:30, at −05:00; the choice later answers 2026-11-01T07:30Z, the second, at −06:00; reject is refused as [Repeated Time].
- In Havana the clocks go forward at midnight. For a place on America/Havana, `day(…, 2026-03-08)` answers a day start of 2026-03-08T05:00Z, when the clock first shows the date, at 01:00, since its midnight never comes.

### A monthly charge

A billing pattern charges on the 31st and asks for next month's date.

- `shift(2026-01-31, 0, 1, 0, clamp)` answers 2026-02-28; in 2028, a leap year, `shift(2028-01-31, 0, 1, 0, clamp)` answers 2028-02-29.
- `shift(2026-01-31, 0, 1, 0, reject)` is refused as [No Such Day], for a pattern that would rather ask its customer.
- `shift(2026-01-31, 0, 1, 31, clamp)` answers 2026-03-31: the month moves first, to February 28, and the 31 days after. Never March 3.
- `shift(2026-03-31, 0, -1, 0, clamp)` answers 2026-02-28, and `shift(2028-02-29, 1, 0, 0, clamp)` answers 2029-02-28.

A pattern that keeps a time of day across the move, a 09:00 call every month, shifts the local date and then resolves 09:00 on the shifted date, so a call on either side of a clock change still lands at 09:00.

### Two readers, two places

A colleague in Berlin, whose weeks start on Monday, has a place of her own: `open("Europe/Berlin", monday)` answers `p2`. At 2026-11-08T12:00Z, Sunday, 06:00 in Chicago and 13:00 in Berlin:

- a comment posted at 2026-11-08T04:30Z reads today in Berlin, at 05:30, and yesterday in Chicago, at 22:30 on Saturday;
- a comment posted at 2026-11-02T12:00Z reads current-week in Berlin, shown as Monday, and last-week in Chicago, whose week began that Sunday.

### Rejection paths

- `open("America/Chicag", sunday)` — rejected as [Unknown Time Zone]; so is `"america/chicago"`, since a time zone is compared codepoint for codepoint.
- `open("America/Chicago", someday)` — rejected as [Invalid Week Start].
- `day(p1, 2026-02-29)` — rejected as [Invalid Date]: 2026 is not a leap year.
- `day(p1, 10000-01-01)` — rejected as [Out Of Range].
- `resolve(p1, 2026-03-08, 24:00:00, compatible)` — rejected as [Invalid Time]; so is 23:59:60, a leap second.
- `resolve(p1, 2026-03-08, 02:30:00, soonest)` — rejected as [Invalid Choice].
- `shift(2026-01-31, 0, 1, -1, clamp)` — rejected as [Invalid Amount]: one month forward and one day back carry two signs.
- `shift(2026-01-31, 0, 1, 0, roll)` — rejected as [Invalid Overflow].
- `show(p404, 2026-11-07T15:00Z)`, where no place `p404` exists — rejected as [Not Known].

With [Skipped Time], [Repeated Time] and [No Such Day] above, this covers every refusal but [Storage Failure], which answers when the database refuses a write.

## Generation acceptance

Acceptable when the checks below are provable to an external auditor: the places from the records the database holds, with their earlier versions (Execution Contract Database 5), and the answers from calls to the atom with the conformance table's inputs, time zone rules that carry the 2026 offsets of America/Chicago, America/Havana and Europe/Berlin and the 2011 offsets of Pacific/Apia, and now at the reading the table names. The atom is not regulated and carries no adversarial scenarios.

The conformance table, each row a call and the answer the atom owes:

| Call | Now | Answer | Rules |
|---|---|---|---|
| `day(Chicago, 2026-03-08)` | any | 2026-03-08T06:00Z to 2026-03-09T05:00Z | Operation 12 |
| `day(Chicago, 2026-11-01)` | any | 2026-11-01T05:00Z to 2026-11-02T06:00Z | Operation 12 |
| `day(Havana, 2026-03-08)` | any | 2026-03-08T05:00Z to 2026-03-09T04:00Z | Operation 12 |
| `day(Apia, 2011-12-30)` | any | 2011-12-30T10:00Z to 2011-12-30T10:00Z, a date the clock skipped whole | Operation 12 |
| `resolve(Chicago, 2026-03-08, 02:30:00, compatible)` | any | 2026-03-08T08:30Z | Operation 16 |
| `resolve(Chicago, 2026-03-08, 02:30:00, earlier)` | any | 2026-03-08T07:30Z | Operation 17 |
| `resolve(Chicago, 2026-03-08, 02:30:00, reject)` | any | skipped-time | Operation 18 |
| `resolve(Chicago, 2026-11-01, 01:30:00, compatible)` | any | 2026-11-01T06:30Z | Operation 19 |
| `resolve(Chicago, 2026-11-01, 01:30:00, later)` | any | 2026-11-01T07:30Z | Operation 20 |
| `resolve(Chicago, 2026-11-01, 01:30:00, reject)` | any | repeated-time | Operation 21 |
| `resolve(Chicago, 2026-11-07, 09:00:00, reject)` | any | 2026-11-07T15:00Z | Operation 15 |
| `resolve(Apia, 2011-12-30, 12:00:00, compatible)` | any | 2011-12-30T22:00Z, which the clock shows as 12:00 on 2011-12-31 | Operation 16 |
| `resolve(Apia, 2011-12-30, 12:00:00, earlier)` | any | 2011-12-29T22:00Z, 12:00 on 2011-12-29 | Operation 17 |
| `resolve(Apia, 2011-12-30, 12:00:00, reject)` | any | skipped-time | Operation 18 |
| `resolve(Chicago, 2026-02-29, 24:00:00, soonest)` | any | invalid-date, the first on the refuses line of the three refusals that apply | Operation 10, Execution Contract Refusal 1 |
| `shift(2026-01-31, 0, 1, 0, clamp)` | any | 2026-02-28 | Operation 26 |
| `shift(2028-01-31, 0, 1, 0, clamp)` | any | 2028-02-29 | Operation 26 |
| `shift(2026-01-31, 0, 1, 0, reject)` | any | no-such-day | Operation 24 |
| `shift(2026-01-31, 0, 1, 31, clamp)` | any | 2026-03-31 | Operation 26 |
| `shift(2026-01-31, 0, 1, -1, clamp)` | any | invalid-amount | Operation 22 |
| `show(Chicago, 2026-11-07T05:50Z)` | 2026-11-07T18:00Z | yesterday, 2026-11-06, 23:50:00, −06:00, friday | Operation 29, Operation 37 |
| `show(Chicago, 2026-11-03T15:00Z)` | 2026-11-07T18:00Z | current-week, 2026-11-03, 09:00:00, −06:00, tuesday | Operation 31, Operation 37 |
| `show(Chicago, 2026-10-28T15:00Z)` | 2026-11-07T18:00Z | last-week, 2026-10-28, 10:00:00, −05:00, wednesday | Operation 32, Operation 37 |
| `show(Chicago, 2026-10-10T15:00Z)` | 2026-11-07T18:00Z | last-month, 2026-10-10, 10:00:00, −05:00, saturday | Operation 34, Operation 37 |
| `show(Chicago, 2026-11-09T15:00Z)` | 2026-11-28T18:00Z | current-month, 2026-11-09, 09:00:00, −06:00, monday | Operation 33, Operation 37 |
| `show(Berlin, 2026-11-02T12:00Z)` | 2026-11-08T12:00Z | current-week, 2026-11-02, 13:00:00, +01:00, monday | Operation 31, Operation 37 |

Here Chicago is the place `open("America/Chicago", sunday)` opens, Berlin the place `open("Europe/Berlin", monday)` opens, Havana a place on America/Havana and Apia a place on Pacific/Apia, each with any week start, which no row reads.

### Conformance checks

```
Check 1.1: An auditor MUST find EVERY place carrying place id, time zone AND week start (State 1).
Check 2.1: An auditor MUST find no two places sharing a place id (Identity 2).
Check 2.2: An auditor MUST find EVERY place's time zone among the zone names (Invariant 1.1).
Check 2.3: An auditor MUST find EVERY place's week start among the days of the week (Invariant 1.2).
Check 3.1: An auditor MUST find EVERY version of a place carrying the place id of the place's first version (Invariant 2.1).
Check 4.1: An auditor MUST find, for EVERY row of the conformance table, the row's answer on a call with the row's inputs (Operation 12 through 37).
```

Term version: a record as it stood at the commit that wrote it, which Execution Contract Database 5 keeps readable after the record changes.

Term conformance table: the table above, each row a call, the now it is made at, and the answer the atom owes.

NOTE: EVERY check names the rule the check tests.

### External checks

```
External check 1: An auditor needing a place's time zone confirmed as the zone the place serves MUST read the records of the pattern that holds the place's owner (Non-goal 7).
External check 2: An auditor needing the time zone rules confirmed MUST read the release of the time zone database the deployment supplies (Capability requirement 2).
```

## Non-goals

```
Non-goal 1: The atom MUST NOT repeat a date.
Non-goal 2: The atom MUST NOT count working days.
Non-goal 3: The atom MUST NOT hold a holiday.
Non-goal 4: The atom MUST NOT read a calendar other than the Gregorian.
Non-goal 5: The atom MUST NOT phrase a reading.
Non-goal 6: The atom MUST NOT lay out a reading.
Non-goal 7: The atom MUST NOT hold a place's owner.
Non-goal 8: The atom MUST NOT act at a time.
```

NOTE: the owners — Recurrence *(forthcoming)*, which composes this atom (Non-goal 1); Business Calendar *(forthcoming)* (Non-goal 2, 3); Calendar System *(forthcoming)* (Non-goal 4); Localization *(forthcoming)*, which words a relative day and writes a date in the reader's language (Non-goal 5); the composing pattern that shows the time, which puts the exact date and time one tap away (Non-goal 6); the composing pattern that knows the person or the site, such as one built on [Party Identity](./party-identity.md) or [Session](./session.md) (Non-goal 7; External check 1); Scheduler *(forthcoming)* (Non-goal 8).

Where the atom breaks down: a date with no time of day, such as a due date or a birthday, has no instant for [Show] to read; a reader whose place is not where the reader is, such as a traveller whose place is still home; a local time kept for a future date in a zone whose rules then change (Edge cases).

## Edge cases

### Concurrency

Two [Change] calls on one place are serialized (Execution Contract Database 2): the later one decides afresh on what the earlier left, so the place ends carrying one call's time zone and week start, never a mix.

### Indeterminate outcome

A caller whose answer is lost may call again, and the repeat is a second call (Execution Contract Error model 1). A repeated [Open] records a second place; a repeated [Change] leaves the place as the first left it. [Read], [Day], [Resolve] and [Shift] write nothing and answer the same again, unless the time zone rules or the place changed in between; a repeated [Show] answers afresh against the new now, so a reading taken just before midnight may come back a day older.

### A place that moves

[Change] gives a place a new time zone, as when a person moves. Readings follow the new zone from that call on, and earlier versions of the place keep the old one (Execution Contract Database 5), so what a reader was shown last month can be reproduced.

### A zone whose rules change

A government can change a zone's offsets, and the deployment then updates the time zone rules. Every answer reads the rules as the deployment holds them at the call, so a wall time resolved before the change can name another instant after it. A composing pattern that must keep a time of day at a place, such as a meeting at 09:00 in Chicago, keeps the local date, the local time and the place id and resolves them at use; one that must keep a moment keeps the instant.

### Leap seconds

The calendar has no leap second: 23:59:60 is not a time of day and is refused as [Invalid Time], and how the deployment's clock counts a leap second is the deployment's (Execution Contract Logic confinement 7).

### Midnight that never comes, and a day skipped whole

Where a zone's clocks change at midnight, as America/Havana's and America/Santiago's do, the clock never shows 00:00 on that date, and the day starts when the clock first shows the date, at 01:00. Pacific/Apia skipped 2011-12-30 whole when Samoa moved across the date line: [Day] answers a day start equal to the day end, and a wall time on that date is a skipped time whose gap is a whole day, so the forward resolution lands on 2011-12-31.

A wall time in a gap that opens at midnight, resolved earlier, lands on the date before: America/Havana's 00:30 on 2026-03-08 resolves earlier to 2026-03-08T04:30Z, which the clock shows as 23:30 on 2026-03-07.

## Composition notes

```
Composition note 1: A composing pattern MUST own what this atom declines.
Composition note 2: A pattern that shows a person an instant MUST show the reading [Show] answers for the person's place.
```

NOTE: composing patterns — none yet. Forthcoming: Recurrence, which composes this atom; and every pattern that shows a time, such as a comment's, a Ledger entry's or a notification's, which reads the time through [Show] (Composition note 2).

NOTE: to keep a time of day at a place, a composing pattern keeps the local date, the local time and the place id and resolves them through [Resolve] at use; to move such a time by months or days and keep its time of day, it shifts the local date through [Shift] and resolves the time again, which is how Temporal and RFC 5545 add days across a clock change.

## Terms

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is* and its **Kind**.

### Vocabulary

Term actors: the atom; the host; the deployment (also: a deployment); a composing pattern (also: a pattern); the database; a place; a person; a reader; a zone action; a place action; a date action; a query action; an auditor.

Term records: place — a time zone and the day the weeks start on there, where dates are read, carrying place id, time zone and week start.

Term record verbs: identify, reuse, normalize, compare, carry, remove, supply, record, answer, write, change, derive, find, read, name, share, repeat, count, hold, phrase, lay, act, own, show, keep, resolve, shift, move, refuse, declare.

Term value sets: day of the week, choice, forward choice, first choice, overflow, relative day, zone action, place action, date action and query action are declared above and cited here (GRACE-lang Closed vocabulary 15).

Term bounds: date range (the calendar dates from 0001-01-01 through 9999-12-31); times of day (00:00:00 through 23:59:59).

Term cadences: empty.

Term qualifiers: migrated — drafted in GRACE lang v0.69 (2026-11-07) through the Grace connector.

Term terms: place, place id, time zone, time zone rules, zone names, seam, week start, day of the week, calendar, calendar date, month length, local date, date range, local time, times of day, offset, now, zone action, place action, date action, query action, day start, day end, day span, choice, forward choice, first choice, wall time, matching instant, plain time, skipped time, repeated time, gap, forward resolution, back resolution, earlier match, later match, amount, signed amount, overflow, month move, landing month, landing day, shifted date, read date, read time, reader's date, day count, week, week count, month count, relative day, reading, version, conformance table.

#### Open

Starts a place: checks the [Time Zone] against the zone names and the [Week Start] against the days of the week, records a place carrying both, and answers the new [Place Id].

Kind: Operation

#### Change

Gives a place a new [Time Zone], a new [Week Start] or both, as when a person moves; a call carrying the place's own time zone and week start writes nothing.

Kind: Operation

#### Read

Answers a place and changes nothing: its [Place Id], [Time Zone] and [Week Start].

Kind: Operation

#### Day

Answers what a [Local Date] means in a place: the [Day Span] from its [Day Start] to its [Day End]. Writes nothing.

Kind: Operation

#### Resolve

Answers the instant a [Local Date] and [Local Time] name in a place; for a wall time the clock skips or shows twice, the [Choice] decides, or the call is refused. Writes nothing.

Kind: Operation

#### Shift

Answers a [Local Date] moved by whole years, months and days of one sign: the months first, the day kept, clamped to the landing month's last day, or refused as the [Overflow] says, and the days after. Reads no place and writes nothing.

Kind: Operation

#### Show

Answers how an instant reads to a person in a place, as a [Reading]: its [Relative Day] by the calendar of the place at now, with the exact local date, local time and [Offset]. Writes nothing.

Kind: Operation

#### Place

A [Time Zone] and the [Week Start] there, where dates are read; opened by [Open], changed by [Change], never removed.

Kind: Type

#### Local Date

A year, a month and a day of the Gregorian calendar of ISO 8601, with no place of its own; taken by [Day], [Resolve] and [Shift], answered by [Shift] and in a [Reading].

Kind: Type

#### Local Time

A time of day on a 24-hour clock, from 00:00:00 through 23:59:59, in whole seconds; taken by [Resolve], answered in a [Reading].

Kind: Type

#### Offset

How far a place's clock stands from UTC at an instant, such as −06:00 for Chicago in winter; answered in a [Reading].

Kind: Type

#### Day Span

The instants a [Local Date] covers in a place, its [Day Start] and every instant up to its [Day End], the day end not included; computed at each [Day], never stored.

Kind: Type

#### Reading

How an instant reads to a person in a place at now: its [Relative Day], the local date and local time the place's clock shows at the instant, the [Offset] and the day of the week; computed at each [Show], never stored.

Kind: Type

#### Place Id

The opaque, immutable identity of a place, allocated by the host at the seam on [Open], never reused.

Kind:       Field
Field of:   Place
Projection: place_id

#### Time Zone

The name of a zone in the deployment's time zone rules, such as America/Chicago or the link US/Central, recorded as the call carries it and compared codepoint for codepoint.

Kind:       Field
Field of:   Place
Projection: time_zone

#### Week Start

The day of the week a place's weeks start on, which decides what last-week and current-week mean there.

Kind:       Field
Field of:   Place
Projection: week_start

#### Day Start

The earliest instant at which the place's clock shows the date or a later one: midnight on most days, 01:00 where the clock skips midnight, and the day end itself on a date the clock skips whole.

Kind:       Field
Field of:   Day Span
Projection: day_start

#### Day End

The day start of the next date: the instant the day stops covering, so not itself in the day but the first instant of the next date; 24 hours past the day start unless the clocks change on the day (Term day end).

Kind:       Field
Field of:   Day Span
Projection: day_end

#### Relative Day

Where the read date stands from the reader's date, by the calendar of the place: today, yesterday, tomorrow, current-week, last-week, current-month, last-month or full-date.

Kind:       Field
Field of:   Reading
Projection: relative_day

#### Choice

What [Resolve] answers for a wall time the clock skips or shows twice: compatible (forward for a skip, the first of two for a repeat), earlier, later, or reject.

Kind:         Parameter
Parameter of: Resolve
Projection:   choice

#### Overflow

What [Shift] does when the landing month has no day of the local date's number: clamp to the month's last day, or reject.

Kind:         Parameter
Parameter of: Shift
Projection:   overflow

#### Unknown Time Zone

[Open]'s or [Change]'s refusal of a [Time Zone] no zone name matches.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: unknown-time-zone

#### Invalid Week Start

[Open]'s or [Change]'s refusal of a [Week Start] that is not a day of the week.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-week-start

#### Not Known

The refusal of a [Place Id] naming no place, on [Change], [Read], [Day], [Resolve] or [Show].

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: not-known

#### Invalid Date

The refusal of a [Local Date] that names no day of the calendar, such as 2026-02-29, on [Day], [Resolve] or [Shift].

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-date

#### Out Of Range

The refusal of a date outside 0001-01-01 through 9999-12-31: a [Local Date] a call carries, the date [Shift] would answer, or the date an instant falls on for [Show].

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: out-of-range

#### Invalid Time

[Resolve]'s refusal of a [Local Time] that is not a time of day, such as 24:00:00 or the leap second 23:59:60.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-time

#### Invalid Choice

[Resolve]'s refusal of a [Choice] other than compatible, earlier, later and reject.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-choice

#### Skipped Time

[Resolve]'s refusal, under the choice reject, of a wall time the place's clock jumps over.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: skipped-time

#### Repeated Time

[Resolve]'s refusal, under the choice reject, of a wall time the place's clock shows twice.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: repeated-time

#### Invalid Amount

[Shift]'s refusal of years, months and days that are not whole numbers, or that carry two signs.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-amount

#### Invalid Overflow

[Shift]'s refusal of an [Overflow] other than clamp and reject.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-overflow

#### No Such Day

[Shift]'s refusal, under the overflow reject, of a move that lands on a day the landing month does not hold, such as January 31 plus one month.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: no-such-day

#### Storage Failure

The refusal [Open] or [Change] answers when the database refuses its write after every precondition passes: the Execution Contract's Step 3 failure.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: storage-failure

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a [Term] marker to its term entry heading above (kramdown
     auto-generates the heading anchors on GitHub Pages). Standard CommonMark /
     kramdown; no plugin required. -->

[Open]: #open
[Change]: #change
[Read]: #read
[Day]: #day
[Resolve]: #resolve
[Shift]: #shift
[Show]: #show
[Place]: #place
[Local Date]: #local-date
[Local Time]: #local-time
[Offset]: #offset
[Day Span]: #day-span
[Reading]: #reading
[Place Id]: #place-id
[Time Zone]: #time-zone
[Week Start]: #week-start
[Day Start]: #day-start
[Day End]: #day-end
[Relative Day]: #relative-day
[Choice]: #choice
[Overflow]: #overflow
[Unknown Time Zone]: #unknown-time-zone
[Invalid Week Start]: #invalid-week-start
[Not Known]: #not-known
[Invalid Date]: #invalid-date
[Out Of Range]: #out-of-range
[Invalid Time]: #invalid-time
[Invalid Choice]: #invalid-choice
[Skipped Time]: #skipped-time
[Repeated Time]: #repeated-time
[Invalid Amount]: #invalid-amount
[Invalid Overflow]: #invalid-overflow
[No Such Day]: #no-such-day
[Storage Failure]: #storage-failure

---

## Standards references

Calendar Time is a primitive with no regulatory anchor of its own. It inherits from:

- **ISO 8601** — the Gregorian calendar run back as if always in force, calendar dates, the 24-hour time of day, and the week; ISO's own weeks start on Monday, and a place may start them on another day.
- **IANA Time Zone Database** — the zone names and each zone's history of offsets, which the deployment supplies as the time zone rules.
- **ECMAScript Temporal (TC39)** — the answer key: its decisions, not its API, for a local time the clocks skip or repeat (compatible, earlier, later, reject), for a date moved by months (constrain, here clamp, or reject; the months first, the days after), for amounts of one sign, and for a day's start where midnight is skipped.
- **RFC 5545 (iCalendar)** — the handling of skipped and repeated local times that Temporal's compatible choice matches, and that adding days keeps the time of day.
- **Unicode CLDR** — the first day of the week by region, from which a deployment may set a place's week start.
- **Daniel Jackson, *The Essence of Software*** — the concept as a freestanding, composable unit of software design, leaving repetition, working days and wording to concepts of their own.

---

## Status

`grounded on Final Critique 1 — 2026-11-08 at 4b0bd47` — see the Ledger.

## Ledger

```
status: grounded on Final Critique 1 — 2026-11-08 at 4b0bd47
formal: not applicable — vote no 2026-11-08: the atom reads one clock reading at the seam (Execution Contract Logic confinement 11) and claims no ordering of its own; every answer is a single-state function of the place, the time zone rules and now that each action's rules hold, and its concurrency is Execution Contract Database 2's
last gate: 2026-11-08 — Final Critique 1, frozen at 4b0bd47 — foundational count 0, clean, one sample

open: none
```

<details markdown="block">
<summary>
    <h2 id="decisions" style="display: inline-block; margin-left: 1.5rem;">Decisions</h2>
</summary>

Directional changes only; everything smaller lives in `git log -- atoms/calendar-time.md`.

- **2026-11-08 — Drafted through the Grace connector, the first atom of the hard set.** *Chose:* a Calendar Time atom on the maintainer's ruling of 2026-11-06 (after-grounding item 14: "what a date means in a place, reverse-specified from JavaScript Temporal's decisions, not its API"), chosen next by the maintainer on 2026-11-07, drafting begun 2026-11-08 00:01Z, from which its rounds to ground count; written against the Database contract from the first draft, the Database, Read and Refusal families cited once (Capability requirement 4) and restated nowhere; Recurrence left to a pattern of its own that composes this one (Non-goal 1). *Over:* a calendar folded into each pattern that shows or keeps a time; Recurrence drafted in the same page. *Because:* the ruling asks for two atoms, one purpose each, Calendar Time grounding first, so that Recurrence composes a grounded page.
- **2026-11-08 — A place is the record.** *Chose:* the place, a time zone and a week start, as the atom's one record, with every other answer computed at the call from the place, the time zone rules and now (Term day span, Term reading); a place never removed (State 2), its earlier versions readable (Execution Contract Database 5). *Over:* a set of calculations with no record (the Execution Contract's taxonomy gives every atom records of its own); a stored local time or instant (a pattern that keeps a meeting or a posting keeps its own); a raw offset as a place (an offset ignores the law that moves a zone's clocks). *Because:* a reading needs the reader's place, and a date covers a stretch of time only in some place, so the place is what the atom must remember; everything else follows from it.
- **2026-11-08 — Temporal's decisions for a skipped or repeated time and for a month that is too short.** *Chose:* four choices for a wall time the clock skips or repeats (Term choice): compatible, Temporal's default and RFC 5545's, moving a skipped time forward by the gap's length and taking a repeated time's earlier match; earlier and later; reject, refused as skipped-time or repeated-time (Operation 15 through 21); [Shift] moving years and months first, keeping the day, clamping it to the landing month's last day or refusing as the overflow says, then adding the days (Term landing day, Operation 24, Operation 26); years, months and days of one sign (Operation 22). *Over:* the old Date's roll-over into the next month (January 31 plus one month as March 3); a choice the atom makes alone; mixed signs read in some order. *Because:* the ruling names these decisions as the answer key, and each is settled in Temporal's design and in RFC 5545; Invariant 4.1 states the roll-over this atom never makes.
- **2026-11-08 — A reading follows the calendar in the reader's place.** *Chose:* the relative days today, yesterday, tomorrow, current-week, last-week, current-month, last-month and full-date, decided by the read date's and the reader's date's calendar days, weeks from the place's week start and calendar months (Operation 28 through 36), never by the hours between (Invariant 3.1); current-week shown by the day of the week, and every reading carrying the exact local date, local time and offset (Operation 37). *Over:* a count of elapsed time ("12 hours ago", "previous 30 days"); a fixed week start. *Because:* the maintainer ruled on 2026-11-06 that a date reads today, yesterday, last week, last month and then the date itself, by calendar boundaries in the reader's place, so last month means the previous calendar month, with the exact date and time always one tap away; current-week, current-month and tomorrow fill the calendar between the ruling's names, and a place's week start says where its weeks begin.

</details>

NOTE: End of Calendar Time.
