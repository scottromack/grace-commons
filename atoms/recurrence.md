---
title: Recurrence
id: 55
parent: Atomic Concepts
has_toc: true
toc: true
---

# Recurrence

<details markdown="block">
<summary>Table of contents</summary>
{: .text-delta }
1. TOC
{:toc}
</details>

## Summary

Recurrence says which dates a repeating event falls on. A series starts on a date and repeats daily, weekly, monthly or yearly, every period or every few periods, on the days its parts pick: chosen months, days of the month such as the 15th or the last day, and days of the week, with an ordinal where one is wanted, such as the second Tuesday or the last Friday. A position narrows each period's picks to the first or the last of them, so the last weekday of the month is the month's Mondays through Fridays with the last one kept. A series ends after so many dates, on an end date, or never, and single dates can be taken out as exceptions and put back. It follows iCalendar's repeat rules (RFC 5545, the Internet standard for calendar exchange), the ones every calendar app exchanges: a date the calendar does not hold, such as February 30 or the 31st of a short month, is never produced, so "the 31st, or the month's last day" is written as the last day among the 28th through the 31st that the month holds. Recurrence answers dates only; the time of day, the place and what its clocks do, holidays and reminders belong to the patterns that compose it.

---

## Intent

<details markdown="block">
<summary>WHY</summary>

Calendars, billing, reminders and report schedules all need repeats, and each reinvents them, often wrongly: the monthly charge on the 31st that skips or spills, the every-other-week meeting whose weeks start on the wrong day, the series that loses count when a meeting is cancelled. iCalendar (RFC 5545) settled what a repeat rule says, and every calendar exchange speaks it, so this atom takes its decisions as the answer key for the parts most software needs: a frequency and an interval, the week start, months, days of the month, days of the week with ordinals, positions within each period, a limit or an end date, and exceptions. Where RFC 5545 leaves a choice open the atom decides, and the Decisions say how: a start the series does not generate is no occurrence; a date the calendar lacks is never generated or counted; exceptions take dates out of the series without moving its limit. The atom answers calendar dates, not moments: a repeat says which days, and what time of day, in which place, and what the clocks do there on a given day belong to Calendar Time, through which a composing pattern resolves each date, as RFC 5545 reads a recurrence's local time.

</details>

## Structure

### Identity model

```
Identity 1: The atom MUST identify a series by the series id.
Identity 2: The atom MUST NOT reuse a series id.
```

Term series: a repeat over calendar dates — a start, a frequency, the parts that pick dates within each period, a limit or an end date, and the dates taken out — a [Series].

Term series id: the opaque value naming one series — a [Series Id]; unique for the system's life.

Term seam: the atom's I/O boundary as the section titled Logic Confinement Principle in `execution-contract.md` declares it; the host injects each series id here.

### State

```
State 1: EVERY series MUST carry series id, start, frequency, interval, week start, months, month days, day entries, positions, limit, end date and exceptions.
State 2: The atom MUST NOT remove a series.
```

Term calendar: the Gregorian calendar of ISO 8601, the international standard for dates, run back before 1582 as if always in force.

Term calendar date: a year, a month from 1 through 12 and a day from 1 through the month's length, naming a day the calendar holds, such as 2028-02-29 but not 2026-02-29.

Term month length: the number of days a month of the calendar holds: 28, 29, 30 or 31.

Term date range: the calendar dates from 0001-01-01 through 9999-12-31.

Term range date: a calendar date in the date range.

Term day of the week: monday | tuesday | wednesday | thursday | friday | saturday | sunday.

Term start: the date a series starts from, as the call carries it — a [Start]; the series' periods are counted from the period holding the start, and no occurrence precedes it.

Term frequency: daily | weekly | monthly | yearly — how long one period of a series is — a [Frequency].

Term interval: every how many periods a series repeats, as the call carries it — an [Interval]; 1 for every period, 2 for every other one.

Term week start: the day of the week a series' weeks start on — a [Week Start]; RFC 5545's WKST.

Term months: the months of the year a series keeps or picks, each as the call carries it — the [Months]; none, or month numbers.

Term month days: the days of the month a series keeps or picks, each as the call carries it — the [Month Days]; none, or month day numbers, a number below zero counting back from the month's last day.

Term day entries: the days of the week a series keeps or picks, each as the call carries it — the [Day Entries]; none, or entries, each a day of the week with, for monthly and yearly, an optional ordinal: 2 tuesday for the second Tuesday, -1 friday for the last Friday.

Term positions: which of each period's picked dates a series keeps, each as the call carries it — the [Positions]; none, or position numbers, 1 for the first and -1 for the last.

Term limit: how many generated dates a series holds, counted from the start, as the call carries it — a [Limit]; RFC 5545's COUNT; blank for a series without one.

Term end date: the last date a series may fall on, as the call carries it — an [End Date]; RFC 5545's UNTIL, inclusive; blank for a series without one.

Term exceptions: the dates taken out of a series — the [Exceptions]; RFC 5545's EXDATE; none when the series opens; a date the series does not generate may be held all the same, and takes nothing out.

Term month number: a whole number from 1 through 12.

Term month day number: a whole number from 1 through 31 or from -31 through -1.

Term position number: a whole number from 1 through 366 or from -366 through -1.

Term positive count: a whole number, one or more.

Term admitted day entry: a day of the week alone; for monthly, also a day of the week with an ordinal from 1 through 5 or from -5 through -1; for yearly, also one with an ordinal from 1 through 53 or from -53 through -1; a day of the week with an ordinal is admitted only where the call gives no month days. So 2 tuesday is admitted on a monthly series and refused on a weekly one, and beside month days a day entry stands bare: friday, and never -1 friday.

Term selector: a month, a month day or a day entry of a series or a call.

### Capability requirement

```
Capability requirement 1: The deployment MUST supply at the seam, for each [Open] call, a series id no series has carried PER Execution Contract Logic confinement 3.
Capability requirement 2: The deployment MUST supply the database PER Execution Contract Database 1 through 7, Execution Contract Read 1 through 4 and Execution Contract Refusal 1.
Capability requirement 3: The deployment MAY declare the occurrence cap PER Execution Contract Input 2.
Capability requirement 4: The deployment MAY declare the limit cap PER Execution Contract Input 2.
```

Term occurrence cap: the most occurrences one [Occurrences] call answers; 1,000 where a deployment declares none — a default cap a deployment may override as Execution Contract Input 2 allows, though a call over it answers too-many-occurrences (Operation 34), this atom's own answer in place of Input 2's invalid-request.

Term limit cap: the largest limit a series may carry; 1,000 where a deployment declares none.

### Operations

```
open(start, frequency, interval, week_start, months, month_days, day_entries, positions, limit, end_date)
  answers series_id
  refuses invalid-start | invalid-frequency | invalid-interval | invalid-week-start | invalid-month | invalid-month-day | invalid-day-entry | invalid-position | invalid-end | storage-failure

except(series_id, date)
  answers ok
  refuses not-known | invalid-date | storage-failure

restore(series_id, date)
  answers ok
  refuses not-known | invalid-date | storage-failure

end(series_id, end_date)
  answers ok
  refuses not-known | invalid-date | invalid-end | storage-failure

read(series_id)
  answers series
  refuses not-known

occurrences(series_id, from_date, through_date)
  answers dates
  refuses not-known | invalid-date | invalid-window | too-many-occurrences
```

```
Operation 1: IF the start IS NOT IN the range dates THEN [Open] MUST answer invalid-start.
Operation 2: IF the frequency IS NOT IN the frequencies THEN [Open] MUST answer invalid-frequency.
Operation 3: IF the interval IS NOT IN the positive counts THEN [Open] MUST answer invalid-interval.
Operation 4: IF the week start IS NOT IN the days of the week THEN [Open] MUST answer invalid-week-start.
Operation 5: IF a month of the call IS NOT IN the month numbers THEN [Open] MUST answer invalid-month.
Operation 6: IF a month day of the call IS NOT IN the month day numbers THEN [Open] MUST answer invalid-month-day.
Operation 7: IF a month day of the call EXISTS AND the frequency EQUALS weekly THEN [Open] MUST answer invalid-month-day.
Operation 8: IF a day entry of the call IS NOT IN the admitted day entries THEN [Open] MUST answer invalid-day-entry.
Operation 9: IF a position of the call IS NOT IN the position numbers THEN [Open] MUST answer invalid-position.
Operation 10: IF a position of the call EXISTS AND no selector of the call EXISTS THEN [Open] MUST answer invalid-position.
Operation 11: IF the limit DOES NOT EQUAL blank AND the end date DOES NOT EQUAL blank THEN [Open] MUST answer invalid-end.
Operation 12: IF the limit DOES NOT EQUAL blank AND the limit IS NOT IN the positive counts THEN [Open] MUST answer invalid-end.
Operation 37: IF the limit DOES NOT EQUAL blank AND the limit EXCEEDS the limit cap THEN [Open] MUST answer invalid-end.
Operation 13: IF the end date DOES NOT EQUAL blank AND the end date IS NOT IN the range dates THEN [Open] MUST answer invalid-end.
Operation 14: IF the end date DOES NOT EQUAL blank AND the end date PRECEDES the start THEN [Open] MUST answer invalid-end.
Operation 15: [Open] MUST record EXACTLY ONE series carrying the series id the seam supplies, the start, frequency, interval, week start, months, month days, day entries, positions, limit and end date of the call, and no exception.
Operation 16: [Open] MUST answer the series id.
Operation 17: IF no series EXISTS for the series id THEN a series action MUST answer not-known.
Operation 18: IF the date IS NOT IN the range dates THEN an exception action MUST answer invalid-date.
Operation 19: IF the date IS NOT IN the series' exceptions THEN [Except] MUST add the date to the series' exceptions.
Operation 20: IF the date IS IN the series' exceptions THEN [Except] MUST NOT write.
Operation 21: [Except] MUST answer ok.
Operation 22: IF the date IS IN the series' exceptions THEN [Restore] MUST remove the date from the series' exceptions.
Operation 23: IF the date IS NOT IN the series' exceptions THEN [Restore] MUST NOT write.
Operation 24: [Restore] MUST answer ok.
Operation 25: IF the end date IS NOT IN the range dates THEN [End] MUST answer invalid-date.
Operation 26: IF the end date PRECEDES the series' start THEN [End] MUST answer invalid-end.
Operation 27: IF the series' end bound EXISTS AND the series' end bound PRECEDES the end date THEN [End] MUST answer invalid-end.
Operation 28: IF the end date DOES NOT EQUAL the series' end date THEN [End] MUST record the series carrying the end date of the call and no limit.
Operation 29: IF the end date EQUALS the series' end date THEN [End] MUST NOT write.
Operation 30: [End] MUST answer ok.
Operation 31: [Read] MUST answer EVERY field the series carries.
Operation 32: IF the from date IS NOT IN the range dates OR the through date IS NOT IN the range dates THEN [Occurrences] MUST answer invalid-date.
Operation 33: IF the through date PRECEDES the from date THEN [Occurrences] MUST answer invalid-window.
Operation 34: IF the window count EXCEEDS the occurrence cap THEN [Occurrences] MUST answer too-many-occurrences.
Operation 35: [Occurrences] MUST answer EVERY occurrence the window holds, in date order.
Operation 36: A query action MUST NOT write.
```

Term series action: [Except] | [Restore] | [End] | [Read] | [Occurrences] — the actions that name a series by the series id.

Term exception action: [Except] | [Restore] — the actions that take a date out of a series or put one back.

Term query action: [Read] | [Occurrences] — the actions that write nothing.

Term period: the calendar dates one repetition of a series covers: a single date for daily; for weekly, the seven dates from a date whose day of the week is the series' week start, the period holding the start being the one that begins on the latest such date not after the start; a calendar month for monthly; a calendar year for yearly.

Term period number: how many periods a period lies past the period holding the start: 0 for that period, 1 for the next.

Term repeating period: a period whose period number is zero or more and a whole multiple of the interval: every period for an interval of 1, every other period for 2.

Term day match: the date a month day names in a month: for a month day above zero, the date of that day number; for one below zero, the date that many days back from the month's end, the last day counting as -1; no date where the month is too short.

Term entry match: the dates a day entry names in a stretch of dates: every date of the entry's day of the week, for an entry with no ordinal; for an ordinal n, the nth such date counted from the stretch's first date where n is above zero, or from its last date where n is below zero, and no date where the stretch holds fewer.

Term daily picks: the period's one date, where the series' months, where given, hold the date's month, some month day, where given, has the date as a day match, and the day entries, where given, hold the date's day of the week.

Term weekly picks: the period's dates whose day of the week the day entries hold, or whose day of the week is the start's where no day entries are given, each kept where the months, where given, hold the date's month.

Term monthly picks: no date where the months are given and lack the period's month; otherwise the day matches of the month days in the month, each kept where the day entries, where given, hold the date's day of the week; or, with no month days, the entry matches of the day entries in the month; or, with neither, the date of the month whose day number is the start's.

Term yearly picks: with month days, the day matches of the month days in each month the months hold, or in every month where no months are given, each kept where the day entries, where given, hold the date's day of the week; with day entries and no month days, the entry matches of the day entries in each month the months hold, or in the whole year where no months are given; with months alone, the date whose day number is the start's in each month the months hold; with no selector, the date of the year whose month and day number are the start's.

Term picked dates: the daily, weekly, monthly or yearly picks of a repeating period, as the series' frequency is, a date the picks name more than once being one picked date.

Term selected dates: the picked dates of a repeating period, in date order, each kept where the date's place in that order is among the positions, counted from the first picked date as 1 for a position above zero and from the last as -1 for one below zero; every picked date where no positions are given.

Term generated date: a selected date of a repeating period that is a range date and is the series' start or falls later.

Term end bound: for a series with a limit, the generated date the limit reaches, counting the generated dates in date order from 1, and none where the series generates fewer dates than the limit; for a series with an end date, the end date; none for a series with neither.

Term occurrence: a generated date that is not later than the end bound, where the series has one, and that the exceptions do not hold — a date [Occurrences] answers.

Term window: the dates from the from date through the through date of an [Occurrences] call.

Term window count: the number of occurrences the window holds.

NOTE: the terms build in this order. A repeating period's picks come from the frequency (Term daily picks through Term yearly picks); its picked dates are those picks; the selected dates are the picked dates the positions keep; the generated dates are the selected dates the start and the date range keep; the occurrences are the generated dates the end bound and the exceptions leave. Positions count over a period's picks, and where some of those picks precede the start they still count (Edge cases, *A start the series does not generate*, says it).

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the series |
|---|---|---|---|
| [Open] | every part valid, database accepts | the series id | one series lands, carrying the call's parts and no exception (Operation 15) |
| [Open] | start not a range date | [Invalid Start] | none (Operation 1) |
| [Open] | frequency not daily, weekly, monthly or yearly | [Invalid Frequency] | none (Operation 2) |
| [Open] | interval not a positive count | [Invalid Interval] | none (Operation 3) |
| [Open] | week start not a day of the week | [Invalid Week Start] | none (Operation 4) |
| [Open] | a month outside 1 through 12 | [Invalid Month] | none (Operation 5) |
| [Open] | a month day outside 1 through 31 and -31 through -1, or any month day on a weekly series | [Invalid Month Day] | none (Operation 6, Operation 7) |
| [Open] | a day entry the frequency does not admit, such as 2 tuesday on a weekly series | [Invalid Day Entry] | none (Operation 8) |
| [Open] | a position outside 1 through 366 and -366 through -1, or positions with no selector | [Invalid Position] | none (Operation 9, Operation 10) |
| [Open] | a limit and an end date both, a limit not a positive count or over the limit cap, or an end date not a range date or earlier than the start | [Invalid End] | none (Operation 11 through 14, Operation 37) |
| [Except] | the date not yet taken out | ok | the date joins the exceptions (Operation 19) |
| [Except] | the date already taken out | ok | none — no write (Operation 20) |
| [Restore] | the date taken out | ok | the date leaves the exceptions (Operation 22) |
| [Restore] | the date not taken out | ok | none — no write (Operation 23) |
| an exception action | the date not a range date | [Invalid Date] | none (Operation 18) |
| [End] | an end date from the start through the end bound, different from the series' | ok | the series carries the end date and no limit (Operation 28) |
| [End] | the series' own end date | ok | none — no write (Operation 29) |
| [End] | the end date not a range date | [Invalid Date] | none (Operation 25) |
| [End] | the end date earlier than the start, or later than the end bound | [Invalid End] | none (Operation 26, Operation 27) |
| [Read] | the series exists | every field the series carries | none (Operation 31) |
| [Occurrences] | a window of range dates holding no more occurrences than the cap | every occurrence in the window, in date order | none (Operation 35) |
| [Occurrences] | a bound not a range date | [Invalid Date] | none (Operation 32) |
| [Occurrences] | the through date earlier than the from date | [Invalid Window] | none (Operation 33) |
| [Occurrences] | more occurrences in the window than the cap | [Too Many Occurrences] | none (Operation 34) |
| a series action | the series id names nothing | [Not Known] | none (Operation 17) |
| a writing call | database refuses the write | [Storage Failure] | none (Execution Contract Read 4) |
| any call | its read of the database fails | `state-unavailable` | none (Execution Contract Read 1, Execution Contract Read 3) |
| any call | more than one refusal applies | the refusal listed first on the action's refuses line | none (Execution Contract Refusal 1) |

### Invariants

- **Invariant 1 — A series is one repeat.**
  ```
  Invariant 1.1: The atom MUST NOT record a series carrying both a limit and an end date.
  Invariant 1.2: The atom MUST NOT record a series carrying a position and no selector.
  ```
- **Invariant 2 — A series keeps its parts, and ends only sooner.**
  ```
  Invariant 2.1: The atom MUST NOT change a series' fixed parts.
  Invariant 2.2: [End] MUST NOT move a series' end bound later.
  ```
- **Invariant 3 — An occurrence is a date the series generates.**
  ```
  Invariant 3.1: [Occurrences] MUST NOT answer a date the series' exceptions hold.
  Invariant 3.2: [Occurrences] MUST NOT answer a date earlier than the series' start.
  Invariant 3.3: [Occurrences] MUST NOT answer a date later than the series' end bound.
  Invariant 3.4: [Occurrences] MUST NOT answer a date outside the window.
  ```

Term fixed parts: the series id, start, frequency, interval, week start, months, month days, day entries and positions of a series — every part but the limit, the end date and the exceptions.

## Examples

The same atom in five uses, then the rejection paths. Lists are written in brackets, `none` for an empty one; dates are calendar dates with no place.

### Every second Tuesday, read two ways

English says "every second Tuesday" for two different series, and a series says which one it means.

- Every other Tuesday: `open(2026-11-10, weekly, 2, monday, none, none, [tuesday], none, none, none)` answers [Series Id] `s1`, and `occurrences(s1, 2026-11-01, 2026-12-31)` answers 2026-11-10, 2026-11-24, 2026-12-08 and 2026-12-22.
- The second Tuesday of each month: `open(2026-11-10, monthly, 1, monday, none, none, [2 tuesday], none, none, none)` answers `s2`, and `occurrences(s2, 2026-11-01, 2027-02-28)` answers 2026-11-10, 2026-12-08, 2027-01-12 and 2027-02-09.

### The last business day

The last weekday of each month: `open(2026-11-01, monthly, 1, monday, none, none, [monday, tuesday, wednesday, thursday, friday], [-1], none, none)` answers `s3`; `occurrences(s3, 2026-11-01, 2027-02-28)` answers 2026-11-30, 2026-12-31, 2027-01-29 and 2027-02-26. The start, a Sunday, is no occurrence, and it need not be: the series starts from it. A holiday on the last weekday, such as a bank's closing, is a business calendar's to move, not this atom's (Non-goal 4, 5).

### The 31st, and the month's last day

- `open(2026-01-31, monthly, 1, monday, none, none, none, none, none, none)` repeats on the start's day of the month, the 31st, and a month without one has no occurrence: 2026-01-31, 2026-03-31, 2026-05-31 and 2026-07-31 to the end of July. RFC 5545 never produces a date the calendar lacks, and never moves one to March 3.
- The 31st, or the month's last day where the month is shorter: `open(2026-01-31, monthly, 1, monday, none, [28, 29, 30, 31], none, [-1], none, none)` keeps the last of the 28th through the 31st that each month holds: 2026-01-31, 2026-02-28, 2026-03-31 and 2026-04-30.
- The last day of every month: month days `[-1]` answer the same four dates.

### Holidays that move, and a leap-day anniversary

- Thanksgiving in the United States, the fourth Thursday of November: `open(2026-11-26, yearly, 1, monday, [11], none, [4 thursday], none, none, none)` answers 2026-11-26, 2027-11-25 and 2028-11-23.
- Friday the 13th: `open(2026-01-01, monthly, 1, monday, none, [13], [friday], none, none, none)` answers 2026-02-13, 2026-03-13 and 2026-11-13 in 2026.
- A wedding on 2028-02-29: `open(2028-02-29, yearly, 1, monday, none, none, none, none, none, none)` falls only in leap years: 2028-02-29, 2032-02-29, 2036-02-29. To keep the anniversary every year, on February 28 in a common year, `open(2028-02-29, yearly, 1, monday, [2], [28, 29], none, [-1], none, none)` answers 2028-02-29, 2029-02-28, 2030-02-28, 2031-02-28 and 2032-02-29.

### A weekly meeting with a week off

A team meets on Mondays, ten times: `open(2026-11-02, weekly, 1, monday, none, none, none, none, 10, none)` answers `s4`, its ten dates from 2026-11-02 through 2027-01-04. The meeting of Thanksgiving week is cancelled: `except(s4, 2026-11-23)` answers ok, and the series now has nine occurrences; the limit still counts the cancelled date, as RFC 5545's exceptions do, so no eleventh Monday is added. `restore(s4, 2026-11-23)` puts the date back. The team then stops meeting in the new year: `end(s4, 2026-12-14)` answers ok, and the series ends with seven occurrences, the last on 2026-12-14. A later `end(s4, 2027-03-01)` is refused as [Invalid End]: an end moves a series' end sooner, never later.

### Rejection paths

- `open(2026-02-29, …)` — rejected as [Invalid Start]: 2026 is not a leap year.
- `open(2026-11-10, hourly, …)` — rejected as [Invalid Frequency].
- `open(2026-11-10, weekly, 0, …)` — rejected as [Invalid Interval].
- `open(2026-11-10, weekly, 1, someday, …)` — rejected as [Invalid Week Start].
- `open(2026-01-31, monthly, 1, monday, [13], …)` — rejected as [Invalid Month].
- `open(2026-01-31, monthly, 1, monday, none, [32], …)` — rejected as [Invalid Month Day]; so is `[15]` on a weekly series.
- `open(2026-11-10, weekly, 1, monday, none, none, [2 tuesday], …)` — rejected as [Invalid Day Entry]: an ordinal needs a monthly or yearly series.
- `open(2026-11-01, monthly, 1, monday, none, none, none, [-1], none, none)` — rejected as [Invalid Position]: a position narrows picks, and nothing picks.
- `open(2026-11-02, weekly, 1, monday, none, none, none, none, 10, 2027-01-04)` — rejected as [Invalid End]: a limit and an end date both.
- `except(s4, 2026-02-30)` — rejected as [Invalid Date].
- `occurrences(s4, 2027-01-31, 2026-11-01)` — rejected as [Invalid Window].
- `occurrences(s9, 0001-01-01, 9999-12-31)` on a daily series — rejected as [Too Many Occurrences]: the window holds more than the occurrence cap.
- `read(s404)`, where no series `s404` exists — rejected as [Not Known].

This covers every refusal but [Storage Failure], which answers when the database refuses a write.

## Generation acceptance

Acceptable when the checks below are provable to an external auditor: the series from the records the database holds, with their earlier versions (Execution Contract Database 5), and the occurrences from calls to the atom with the conformance table's inputs. The atom is not regulated and carries no adversarial scenarios.

The conformance table, each row a series as its [Open] call makes it, a window, and the occurrences the atom owes; the WKST rows are RFC 5545's own example, and every answer matches an implementation of RFC 5545's repeat rules:

| Series | Window | Occurrences | Rules |
|---|---|---|---|
| `open(2026-11-10, weekly, 2, monday, none, none, [tuesday], none, none, none)` | 2026-11-01 through 2026-12-31 | 2026-11-10, 2026-11-24, 2026-12-08, 2026-12-22 | Term weekly picks, Term repeating period |
| `open(2026-11-10, monthly, 1, monday, none, none, [2 tuesday], none, none, none)` | 2026-11-01 through 2027-02-28 | 2026-11-10, 2026-12-08, 2027-01-12, 2027-02-09 | Term monthly picks, Term entry match |
| `open(2026-11-01, monthly, 1, monday, none, none, [monday, tuesday, wednesday, thursday, friday], [-1], none, none)` | 2026-11-01 through 2027-02-28 | 2026-11-30, 2026-12-31, 2027-01-29, 2027-02-26 | Term selected dates |
| `open(2026-11-15, monthly, 1, monday, none, none, [monday, tuesday, wednesday, thursday, friday], [1], none, none)` | 2026-11-01 through 2027-01-31 | 2026-12-01, 2027-01-01 — the first weekday of November, 2026-11-02, precedes the start | Term selected dates, Term generated date |
| `open(2026-01-31, monthly, 1, monday, none, none, none, none, none, none)` | 2026-01-01 through 2026-07-31 | 2026-01-31, 2026-03-31, 2026-05-31, 2026-07-31 | Term monthly picks |
| `open(2026-01-31, monthly, 1, monday, none, [28, 29, 30, 31], none, [-1], none, none)` | 2026-01-01 through 2026-04-30 | 2026-01-31, 2026-02-28, 2026-03-31, 2026-04-30 | Term day match, Term selected dates |
| `open(2026-02-01, monthly, 1, monday, none, [28, -1], none, none, 2, none)` | 2026-02-01 through 2026-04-30 | 2026-02-28, 2026-03-28 | Term picked dates, Term end bound |
| `open(2026-01-31, monthly, 1, monday, none, [-1], none, none, none, none)` | 2026-01-01 through 2026-04-30 | 2026-01-31, 2026-02-28, 2026-03-31, 2026-04-30 | Term day match |
| `open(2028-02-29, yearly, 1, monday, none, none, none, none, none, none)` | 2028-01-01 through 2036-12-31 | 2028-02-29, 2032-02-29, 2036-02-29 | Term yearly picks |
| `open(2028-02-29, yearly, 1, monday, [2], [28, 29], none, [-1], none, none)` | 2028-01-01 through 2032-12-31 | 2028-02-29, 2029-02-28, 2030-02-28, 2031-02-28, 2032-02-29 | Term yearly picks, Term selected dates |
| `open(2026-11-26, yearly, 1, monday, [11], none, [4 thursday], none, none, none)` | 2026-01-01 through 2028-12-31 | 2026-11-26, 2027-11-25, 2028-11-23 | Term yearly picks |
| `open(2026-01-01, yearly, 1, monday, none, none, [20 monday], none, none, none)` | 2026-01-01 through 2027-12-31 | 2026-05-18, 2027-05-17 | Term yearly picks, Term entry match |
| `open(2026-01-01, monthly, 1, monday, none, [13], [friday], none, none, none)` | 2026-01-01 through 2026-12-31 | 2026-02-13, 2026-03-13, 2026-11-13 | Term monthly picks |
| `open(2026-12-30, daily, 1, monday, [1], none, none, none, none, none)` | 2026-12-30 through 2027-01-03 | 2027-01-01, 2027-01-02, 2027-01-03 | Term daily picks |
| `open(2026-11-06, weekly, 1, monday, none, none, [tuesday], none, none, none)` | 2026-11-01 through 2026-11-20 | 2026-11-10, 2026-11-17 | Term generated date |
| `open(1997-08-05, weekly, 2, monday, none, none, [tuesday, sunday], none, 4, none)` | 1997-08-01 through 1997-09-30 | 1997-08-05, 1997-08-10, 1997-08-19, 1997-08-24 | Term period, Term end bound |
| `open(1997-08-05, weekly, 2, sunday, none, none, [tuesday, sunday], none, 4, none)` | 1997-08-01 through 1997-09-30 | 1997-08-05, 1997-08-17, 1997-08-19, 1997-08-31 | Term period, Term end bound |
| `open(2026-11-02, weekly, 1, monday, none, none, none, none, 10, none)`, then `except(…, 2026-11-23)` | 2026-11-01 through 2027-01-31 | 2026-11-02, 2026-11-09, 2026-11-16, 2026-11-30, 2026-12-07, 2026-12-14, 2026-12-21, 2026-12-28, 2027-01-04 | Term occurrence, Invariant 3.1 |
| `open(2026-01-30, yearly, 1, monday, [2], [30], none, none, none, none)` | 2026-01-01 through 2040-12-31 | none: February never holds a 30th | Term day match |

### Conformance checks

```
Check 1.1: An auditor MUST find EVERY series carrying series id, start, frequency, interval, week start, months, month days, day entries, positions, limit, end date AND exceptions (State 1).
Check 2.1: An auditor MUST find no two series sharing a series id (Identity 2).
Check 2.2: An auditor MUST find no series carrying both a limit and an end date (Invariant 1.1).
Check 2.3: An auditor MUST find no series carrying a position and no selector (Invariant 1.2).
Check 3.1: An auditor MUST find EVERY version of a series carrying the fixed parts of the series' first version (Invariant 2.1).
Check 3.2: An auditor MUST find no version of a series whose end bound falls later than the end bound of the series' previous version (Invariant 2.2).
Check 4.1: An auditor MUST find, for EVERY row of the conformance table, the row's occurrences on a call with the row's series and window (Operation 35, Invariant 3.1 through 3.4).
```

Term version: a record as it stood at the commit that wrote it, which Execution Contract Database 5 keeps readable after the record changes.

Term conformance table: the table above, each row a series, a window, and the occurrences the atom owes.

NOTE: EVERY check names the rule the check tests.

### External checks

```
External check 1: An auditor needing an occurrence confirmed as a day the event was held MUST read the records of the pattern that keeps the event (Non-goal 2).
External check 2: An auditor needing an occurrence confirmed as a business day MUST read the records of the business calendar the deployment composes (Non-goal 4).
```

## Non-goals

```
Non-goal 1: The atom MUST NOT repeat within a day.
Non-goal 2: The atom MUST NOT hold a time of day.
Non-goal 3: The atom MUST NOT read a place.
Non-goal 4: The atom MUST NOT count working days.
Non-goal 5: The atom MUST NOT hold a holiday.
Non-goal 6: The atom MUST NOT read a calendar other than the Gregorian.
Non-goal 7: The atom MUST NOT add a single date to a series.
Non-goal 8: The atom MUST NOT move one occurrence.
Non-goal 9: The atom MUST NOT act on an occurrence.
Non-goal 10: The atom MUST NOT phrase a series.
Non-goal 11: The atom MUST NOT hold a series' owner.
```

NOTE: the owners — Scheduler *(forthcoming)*, for repeats within a day and for acting on an occurrence, such as a reminder (Non-goal 1, 9); Calendar Event *(forthcoming)*, the pattern that keeps an event, its time of day, its one-off dates and its moved occurrences, and resolves each date in the event's place through [Calendar Time](./calendar-time.md) (Non-goal 2, 3, 7, 8; External check 1); Business Calendar *(forthcoming)* (Non-goal 4, 5; External check 2); Calendar System *(forthcoming)* (Non-goal 6); Localization *(forthcoming)*, which says a series in the reader's words (Non-goal 10); the composing pattern that knows the person, such as one built on [Party Identity](./party-identity.md) or [Session](./session.md) (Non-goal 11).

Where the atom breaks down: a series by week number or by day of the year, RFC 5545's BYWEEKNO and BYYEARDAY; a series in a calendar other than the Gregorian, RFC 7529's RSCALE; a series whose next date depends on when the last one was done, such as every three months after the last service.

## Edge cases

### Concurrency

Two calls on one series are serialized (Execution Contract Database 2): two [Except] calls for one date leave the date taken out once, and an [End] decides afresh on the end bound an earlier call left.

### Indeterminate outcome

A caller whose answer is lost may call again, and the repeat is a second call (Execution Contract Error model 1). A repeated [Open] records a second series; a repeated [Except], [Restore] or [End] leaves the series as the first left it, writing nothing the second time; [Read] and [Occurrences] write nothing and answer the same again, unless another call changed the series in between.

### A clock change on an occurrence

An occurrence is a calendar date, with no time of day and no place. A pattern that keeps a series at 02:30 in Chicago resolves each date at 02:30 in its place, and on the night the clocks go forward that time does not exist there; RFC 5545 reads such a recurrence the way it reads any explicit local time, moved forward by the skipped length, and a time shown twice as its first showing (RFC 5545 erratum 4271), which is Calendar Time's compatible choice (Composition note 2).

### A date the calendar does not hold

A month day or a start's day of the month that a month lacks, such as the 30th in February or the 31st in April, names no date there, and the series simply has no occurrence in that month: the date is never produced and never counted toward the limit, as RFC 5545 says. A series that wants the month's last day in place of a missing one says so with month days and a position (Examples, *The 31st, and the month's last day*). A series that can never fall, such as the 30th of February every year, opens and answers no occurrence. The same holds for a yearly day entry's ordinal where months are given: it counts within each of those months (Term yearly picks), so one past 5 or below -5 names no date there, and with no months it counts over the whole year, where up to 53 can land.

### A start the series does not generate

A start is where a series starts counting periods from, not a promise that the start itself is an occurrence: every Tuesday from a Friday falls first on the Tuesday that follows. RFC 5545 calls a start its rule does not generate unsynchronized and leaves the set it makes undefined; this atom defines it, and positions still count over a whole period, so the first weekday of a month whose start falls mid-month is that month's first weekday, and it precedes the start.

### The week start and every other week

For a weekly series repeating every two weeks or more on several days, the week start decides which days share a period, and so which weeks repeat: RFC 5545's own example, every other week on Tuesday and Sunday from 1997-08-05, falls on August 5, 10, 19 and 24 with weeks from Monday and on August 5, 17, 19 and 31 with weeks from Sunday (Generation acceptance).

## Composition notes

```
Composition note 1: A composing pattern MUST own what this atom declines.
Composition note 2: A composing pattern that keeps a time of day for a series MUST resolve each occurrence at that time of day in the event's place.
```

NOTE: composing patterns — none yet. Forthcoming: Calendar Event, which wires this atom to [Calendar Time](./calendar-time.md): each occurrence's date at the event's time of day, resolved through Calendar Time's resolve with the choice compatible, as RFC 5545 reads a recurrence's local time; the daylight-saving cases of the maintainer's ruling live in that wiring.

## Terms

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is* and its **Kind**.

### Vocabulary

Term actors: the atom; the host; the deployment (also: a deployment); a composing pattern (also: a pattern); the database; a series; a series action; an exception action; a query action; an auditor; a person.

Term records: series — a repeat over calendar dates, carrying series id, start, frequency, interval, week start, months, month days, day entries, positions, limit, end date and exceptions.

Term record verbs: identify, reuse, carry, remove, supply, declare, record, answer, add, write, change, move, find, read, share, repeat, hold, count, act, phrase, own, resolve, keep, refuse.

Term value sets: day of the week, frequency, series action, exception action and query action are declared above and cited here (GRACE-lang Closed vocabulary 15).

Term bounds: date range (the calendar dates from 0001-01-01 through 9999-12-31); positive count (one, the floor of an interval and a limit); limit cap (the largest limit a series may carry, 1,000 where a deployment declares none); month number (1 through 12); month day number (1 through 31, -31 through -1); position number (1 through 366, -366 through -1); occurrence cap (the most occurrences one [Occurrences] call answers, 1,000 where a deployment declares none).

Term cadences: empty.

Term qualifiers: migrated — drafted in GRACE lang v0.69 (2026-11-07) through the Grace connector.

Term terms: series, series id, seam, calendar, calendar date, month length, date range, range date, day of the week, start, frequency, interval, week start, months, month days, day entries, positions, limit, end date, exceptions, month number, month day number, position number, positive count, admitted day entry, selector, occurrence cap, limit cap, series action, exception action, query action, period, period number, repeating period, day match, entry match, daily picks, weekly picks, monthly picks, yearly picks, picked dates, selected dates, generated date, end bound, occurrence, window, window count, fixed parts, version, conformance table.

#### Open

Starts a series: checks each part, records a series carrying the start, frequency, interval, week start, months, month days, day entries, positions, limit and end date of the call and no exception, and answers the new [Series Id].

Kind: Operation

#### Except

Takes one date out of a series, as RFC 5545's EXDATE does; a date already taken out writes nothing, and a date the series does not generate is taken out to no effect.

Kind: Operation

#### Restore

Puts a date taken out back into a series; a date not taken out writes nothing.

Kind: Operation

#### End

Ends a series on an [End Date] no later than its end bound and no earlier than its [Start], dropping its [Limit]; an end never makes a series longer.

Kind: Operation

#### Read

Answers a series and changes nothing: its [Series Id], [Start], [Frequency], [Interval], [Week Start], [Months], [Month Days], [Day Entries], [Positions], [Limit], [End Date] and [Exceptions].

Kind: Operation

#### Occurrences

Answers the occurrences of a series from one date through another, in date order, and changes nothing; a window holding more than the occurrence cap is refused, for the caller to narrow.

Kind: Operation

#### Series

A repeat over calendar dates: a [Start], a [Frequency] and an [Interval], the parts that pick dates within each period, a [Limit] or an [End Date] or neither, and the [Exceptions]; opened by [Open], changed only by [Except], [Restore] and [End], never removed.

Kind: Type

#### Series Id

The opaque, immutable identity of a series, allocated by the host at the seam on [Open], never reused.

Kind:       Field
Field of:   Series
Projection: series_id

#### Start

The date a series starts from: its periods are counted from the period holding it, and no occurrence precedes it; the start is itself an occurrence only where the series generates it.

Kind:       Field
Field of:   Series
Projection: start

#### Frequency

How long one period of a series is: daily, weekly, monthly or yearly, as RFC 5545's FREQ; repeats within a day are another pattern's.

Kind:       Field
Field of:   Series
Projection: frequency

#### Interval

Every how many periods a series repeats, a whole number of one or more: 2 for every other week on a weekly series; RFC 5545's INTERVAL.

Kind:       Field
Field of:   Series
Projection: interval

#### Week Start

The day of the week a series' weeks start on; it decides which days share a week, and so which weeks repeat; RFC 5545's WKST.

Kind:       Field
Field of:   Series
Projection: week_start

#### Months

The months of the year a series keeps or picks, numbers from 1 through 12, or none; RFC 5545's BYMONTH.

Kind:       Field
Field of:   Series
Projection: months

#### Month Days

The days of the month a series keeps or picks, from 1 through 31, or from -1 for the last day back to -31, or none; never on a weekly series; RFC 5545's BYMONTHDAY.

Kind:       Field
Field of:   Series
Projection: month_days

#### Day Entries

The days of the week a series keeps or picks, each with, on a monthly or yearly series, an optional ordinal such as 2 for the second or -1 for the last, or none; RFC 5545's BYDAY.

Kind:       Field
Field of:   Series
Projection: day_entries

#### Positions

Which of each period's picked dates a series keeps, from 1 for the first and -1 for the last, or none; only beside a month, a month day or a day entry; RFC 5545's BYSETPOS.

Kind:       Field
Field of:   Series
Projection: positions

#### Limit

How many dates a series generates, counted from the start, a whole number of one or more and no more than the limit cap, or none; the dates taken out still count; RFC 5545's COUNT.

Kind:       Field
Field of:   Series
Projection: limit

#### End Date

The last date a series may fall on, the date itself included, or none; set by [Open] or moved sooner by [End]; RFC 5545's UNTIL.

Kind:       Field
Field of:   Series
Projection: end_date

#### Exceptions

The dates taken out of a series by [Except], less those put back by [Restore]; none when the series opens; RFC 5545's EXDATE.

Kind:       Field
Field of:   Series
Projection: exceptions

#### Invalid Start

[Open]'s refusal of a [Start] that is not a calendar date from 0001-01-01 through 9999-12-31, such as 2026-02-29.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-start

#### Invalid Frequency

[Open]'s refusal of a [Frequency] other than daily, weekly, monthly and yearly.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-frequency

#### Invalid Interval

[Open]'s refusal of an [Interval] that is not a whole number of one or more.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-interval

#### Invalid Week Start

[Open]'s refusal of a [Week Start] that is not a day of the week.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-week-start

#### Invalid Month

[Open]'s refusal of a month in the [Months] outside 1 through 12.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-month

#### Invalid Month Day

[Open]'s refusal of a month day outside 1 through 31 and -31 through -1, or of any [Month Days] on a weekly series.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-month-day

#### Invalid Day Entry

[Open]'s refusal of a day entry that is not a day of the week, or whose ordinal the frequency does not admit: any ordinal on a daily or weekly series or beside month days, and one past 5 on a monthly series or past 53 on a yearly one.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-day-entry

#### Invalid Position

[Open]'s refusal of a position outside 1 through 366 and -366 through -1, or of [Positions] with no month, month day or day entry to narrow.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-position

#### Invalid End

The refusal of an end a series cannot have: on [Open], a [Limit] and an [End Date] both, a limit that is not a whole number of one or more or is over the limit cap, or an end date that is not a calendar date in the range or is earlier than the [Start]; on [End], an end date earlier than the start or later than the series' end bound.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-end

#### Not Known

The refusal of a [Series Id] naming no series, on [Except], [Restore], [End], [Read] or [Occurrences].

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: not-known

#### Invalid Date

The refusal of a date that is not a calendar date from 0001-01-01 through 9999-12-31, on [Except], [Restore], [End] or [Occurrences].

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-date

#### Invalid Window

[Occurrences]' refusal of a window whose through date is earlier than its from date.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-window

#### Too Many Occurrences

[Occurrences]' refusal of a window holding more occurrences than the occurrence cap; the caller asks again for a shorter window.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: too-many-occurrences

#### Storage Failure

The refusal [Open], [Except], [Restore] or [End] answers when the database refuses its write after every precondition passes: the Execution Contract's Step 3 failure.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: storage-failure

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a [Term] marker to its term entry heading above (kramdown
     auto-generates the heading anchors on GitHub Pages). Standard CommonMark /
     kramdown; no plugin required. -->

[Open]: #open
[Except]: #except
[Restore]: #restore
[End]: #end
[Read]: #read
[Occurrences]: #occurrences
[Series]: #series
[Series Id]: #series-id
[Start]: #start
[Frequency]: #frequency
[Interval]: #interval
[Week Start]: #week-start
[Months]: #months
[Month Days]: #month-days
[Day Entries]: #day-entries
[Positions]: #positions
[Limit]: #limit
[End Date]: #end-date
[Exceptions]: #exceptions
[Invalid Start]: #invalid-start
[Invalid Frequency]: #invalid-frequency
[Invalid Interval]: #invalid-interval
[Invalid Week Start]: #invalid-week-start
[Invalid Month]: #invalid-month
[Invalid Month Day]: #invalid-month-day
[Invalid Day Entry]: #invalid-day-entry
[Invalid Position]: #invalid-position
[Invalid End]: #invalid-end
[Not Known]: #not-known
[Invalid Date]: #invalid-date
[Invalid Window]: #invalid-window
[Too Many Occurrences]: #too-many-occurrences
[Storage Failure]: #storage-failure

---

## Standards references

Recurrence is a primitive with no regulatory anchor of its own. It inherits from:

- **RFC 5545 (iCalendar), sections 3.3.10 and 3.8.5** — the answer key: FREQ, INTERVAL, WKST, BYMONTH, BYMONTHDAY, BYDAY with ordinals, BYSETPOS, COUNT, UNTIL and EXDATE; a recurrence's invalid date ignored and never counted; DTSTART's part in a rule.
- **RFC 5545 errata 1911 and 4271** — an ordinal on BYDAY only for MONTHLY and YEARLY rules; a recurrence's nonexistent local time read as section 3.3.5 reads an explicit one, not dropped.
- **RFC 7529** — RSCALE and SKIP, not adopted: the Gregorian calendar alone, and a missing date written around with month days and a position rather than skipped forward or back.
- **ISO 8601** — the Gregorian calendar run back as if always in force, and calendar dates.
- **Daniel Jackson, *The Essence of Software*** — the concept as a freestanding, composable unit of software design, leaving time of day, place and holidays to concepts of their own.

---

## Status

`done — 2026-11-08` — see the Ledger.

## Ledger

```
status: done — 2026-11-08
formal: verified — recurrence.als + 10 twins (vote yes, on the maintainer's ruling (after-grounding item 14, 2026-11-06: "Recurrence gets an Alloy model (it is mostly shape)"); every Invariant checked, 1.1 through 3.4, with the build order of the Terms, the exceptions that keep a limit's bound and the limit cap; the twin drops Operation 27's guard from [End] and Invariant 2.2 catches it; the daylight-saving cases that ruling gives a TLA model belong to the wiring of this atom with Calendar Time, not to this page); coverage 2026-11-10 (unit formal: more coverage for the yes votes); recurrence.tla + 15 twins (across steps, 2026-11-11: one series under [Open], [Except], [Restore] and [End], refusals in each refuses line's order, with the answer [Occurrences] gives in every state they leave: Invariant 1.1, 1.2, 2.1, 2.2 and 3.1 through 3.4, a cross-check with the Alloy model, the date taken out that still counts toward a limit (Term end bound), and Operation 7 and 8, both ways); nothing testable in TLA+ for the daylight-saving cases: an occurrence is a date with no time of day (Non-goal 2, 3), so what a clock change does to a time on it is Calendar Time's resolve, through the wiring of a composing pattern (Composition note 2); coverage 2026-11-11 (unit `atoms/recurrence.md formal layer`): no owed rows, 2026-11-11
last gate: 2026-11-08 — Final Critique 2, delta, frozen at 237cc22 — foundational count 0 after the blind second triage, clean, one sample

open: none
```

<details markdown="block">
<summary>
    <h2 id="decisions" style="display: inline-block; margin-left: 1.5rem;">Decisions</h2>
</summary>

Directional changes only; everything smaller lives in `git log -- atoms/recurrence.md`.

- **2026-11-08 — Drafted through the Grace connector, the second atom of the hard set.** *Chose:* a Recurrence atom on the maintainer's ruling of 2026-11-06 (after-grounding item 14: "what a repeat rule says ('every second Tuesday', 'the last business day', exceptions), modeled on iCalendar's repeat rules as the answer key, composing Calendar Time"), begun on the maintainer's word of 2026-11-08 02:23Z ("lets go") once Calendar Time grounded, drafting begun 2026-11-08 02:27Z, from which its rounds to ground count; an atom, as the ruling's "two atoms, one purpose each" says, which names no other atom (spec-format.md, *Atom shape*), so it answers calendar dates and the pattern that composes it with Calendar Time resolves them. *Over:* a composition of Recurrence with Calendar Time in one page; a time of day and a place carried in the series. *Because:* a repeat says which days; what moment a day's time names in a place is Calendar Time's, already grounded, so the daylight-saving cases the ruling gives a TLA model belong to the wiring of the two, and this page's formal layer is the Alloy model of its shape.
- **2026-11-08 — RFC 5545's repeat rules for the parts most software needs.** *Chose:* daily, weekly, monthly and yearly frequencies with an interval and a week start (Term period, Term repeating period); months, month days and day entries, each picking or keeping dates by RFC 5545's table for those four frequencies (Term daily picks through Term yearly picks); positions over each period's picks (Term selected dates); a limit or an end date, never both (Operation 11); exceptions that take dates out without moving the limit (Term end bound, Term occurrence). *Over:* repeats within a day, BYHOUR, BYMINUTE and BYSECOND (a scheduler's, Non-goal 1); BYWEEKNO and BYYEARDAY (rare, and outside the needs the ruling names); RDATE and moved occurrences (an event's, Non-goal 7, 8); an RRULE text the atom would parse. *Because:* the ruling names every second Tuesday, the last business day and exceptions, and these parts say each of them in both its readings, the Examples showing how; what the atom leaves out is named with its owner.
- **2026-11-08 — Where RFC 5545 leaves a choice open.** *Chose:* a start the series does not generate is no occurrence, the series counting its periods from the start's period (Term generated date); a date the calendar lacks never generated and never counted (Term day match), so the 31st falls only in months that hold one; an ordinal on a day entry only on monthly and yearly series (RFC 5545 erratum 1911) and never beside month days; positions only beside a selector (Operation 10); an end that moves a series' end sooner and drops its limit, never later (Operation 27, Operation 28). *Over:* the start counted as the first occurrence whatever the series says (RFC 5545 calls an unsynchronized start undefined, and every Tuesday from a Friday would answer a Friday); RFC 7529's SKIP, moving a missing date back or forward (month days 28 through 31 with position -1 say the clamped 31st in RFC 5545's own terms, so the atom keeps one behavior); a day entry with an ordinal read beside month days in some order. *Because:* each choice keeps a series' meaning one meaning and matches what the common implementations of RFC 5545 answer, as the conformance table's rows show.
- **2026-11-08 — A cap on the limit.** *Chose:* the largest limit a series may carry is a cap, 1,000 where a deployment declares none (Term limit cap, Capability requirement 4), and an [Open] over it answers invalid-end (Operation 37). *Over:* no cap, which left the work of [End]'s check (Operation 27) and of the dates [Occurrences] keeps within a limit growing with a limit nothing bounds; a cap that cuts the series short, which would give one series two meanings. *Because:* 1,000 matches the occurrence cap, so every date of a limited series fits one [Occurrences] call, and a longer series takes an end date, which bounds it without counting (the corpus's posture on what the host must bound, Cart's 2026-11-02 entry).

</details>

NOTE: End of Recurrence.
