-- recurrence-buggy-end-keeps-limit.als
-- DELIBERATELY WRONG twin of recurrence.als (unit: every check has a twin that breaks it).
--
-- INJECTED DEFECT: [End] records the end date but keeps the series' limit (Operation 28
-- skipped: the end date replaces the limit), so a limited series ends up carrying both.
--
-- BREAKS: A_Invariant_1_1 (a step from a limit-only series to one with both).

module recurrence_buggy_end_keeps_limit

open util/ordering[Date]   as D
open util/ordering[Period] as P

-- ─────────────────────────────────────────────────────────────────────────────
-- Signatures (types)
-- ─────────────────────────────────────────────────────────────────────────────

-- Date: a calendar date in the date range. Only the ORDER of dates matters to the
-- shape of a repeat, so the model's dates are the ordered atoms D/first, D/next(...), and
-- so on. Every Date here is a range date (Operations 1, 13, 18, 25 and 32 refuse the
-- others, which the model never builds).
sig Date {}

-- Period: one repetition of a series, a stretch of dates (Term period). Only a
-- REPEATING period (Term repeating period) can pick dates, so the model's periods are
-- the repeating ones, in order, and every period with no picks is simply empty.
sig Period {}

-- Frequency: how long one period of a series is (Term frequency).
abstract sig Frequency {}
one sig Daily, Weekly, Monthly, Yearly extends Frequency {}

-- The opaque parts of a series. The model asks only whether a series carries one,
-- never what it is, so each is an uninterpreted token.
sig SeriesId {}   -- the series id (Term series id)
sig Weekday  {}   -- a day of the week (Term day of the week), for the week start and day entries
sig Month    {}   -- a month number (Term months)
sig MonthDay {}   -- a month day number (Term month days)

-- DayEntry: a day of the week with, on a monthly or yearly series, an optional ordinal
-- (Term day entries): "friday" has none, "2 tuesday" has one. The ordinal is a number
-- whose sign counts from the first or from the last, so zero is never one.
sig DayEntry {
    day     : one Weekday,
    ordinal : lone Int
}

-- Series: the record the atom keeps (State 1). Every field is a field of a series on
-- the page, except picks, which stands for what the fixed parts decide (see SCOPE).
sig Series {
    sid        : one SeriesId,        -- the series id (fixed)
    start      : one Date,            -- the date periods are counted from (fixed)
    frequency  : one Frequency,       -- how long a period is (fixed)
    interval   : one Int,             -- every how many periods the series repeats (fixed)
    weekStart  : one Weekday,         -- the day weeks start on (fixed)
    months     : set Month,           -- the months the series keeps or picks (fixed)
    monthDays  : set MonthDay,        -- the days of the month it keeps or picks (fixed)
    dayEntries : set DayEntry,        -- the days of the week it keeps or picks (fixed)
    positions  : set Int,             -- which of each period's picks it keeps (fixed)
    picks      : Period -> Date,      -- each repeating period's picked dates (decided by the fixed parts)
    limit      : lone Int,            -- how many generated dates it holds, or none
    endDate    : lone Date,           -- the last date it may fall on, or none
    exceptions : set Date             -- the dates taken out
}

-- ─────────────────────────────────────────────────────────────────────────────
-- The caps, scaled down
-- ─────────────────────────────────────────────────────────────────────────────

-- The occurrence cap and the limit cap (Term occurrence cap, Term limit cap): the page
-- declares 1,000 for each where a deployment declares none; the model uses 3 so a
-- search at a small scope reaches a series at the cap. The two are equal, as the page
-- has them by default, which is what Decisions' "A cap on the limit" rests on.
fun OccurrenceCap : Int { 3 }
fun LimitCap      : Int { 3 }

-- ─────────────────────────────────────────────────────────────────────────────
-- Structural well-formedness facts
-- ─────────────────────────────────────────────────────────────────────────────

-- The interval is a positive count (Operation 3); a position and an ordinal are never
-- zero (Operation 9, Operation 8: they count from the first or from the last).
fact NumbersAreWholeAndSigned {
    all s : Series | gte[s.interval, 1]
    all s : Series | 0 not in s.positions
    all e : DayEntry | 0 not in e.ordinal
}

-- Periods run in date order and do not overlap: every date a later period picks falls
-- after every date an earlier one picks, so a date belongs to at most one period of a
-- series. (This is what makes "the first picked date of a period" mean something.)
fact PeriodsRunInDateOrder {
    all s : Series, disj p1, p2 : Period |
        P/lt[p1, p2] implies
            (all d1 : p1.(s.picks), d2 : p2.(s.picks) | D/lt[d1, d2])
}

-- ─────────────────────────────────────────────────────────────────────────────
-- The terms, built in the page's order
-- picked dates → selected dates → generated dates → end bound → occurrences
-- ─────────────────────────────────────────────────────────────────────────────

-- Term picked dates: every date a repeating period of the series picks. (A date a
-- period's picks name twice is one picked date: a set holds it once.)
fun picked[s : Series] : set Date {
    Period.(s.picks)
}

-- The picks of the one period that holds a given picked date.
fun periodPicks[s : Series, d : Date] : set Date {
    (s.picks.d).(s.picks)
}

-- A picked date's place in its period's picks, counted from the first as 1, 2, ...
fun placeFromFirst[s : Series, d : Date] : Int {
    plus[#(periodPicks[s, d] & D/prevs[d]), 1]
}

-- A picked date's place counted from the last as -1, -2, ...
fun placeFromLast[s : Series, d : Date] : Int {
    minus[0, plus[#(periodPicks[s, d] & D/nexts[d]), 1]]
}

-- Term selected dates: the picked dates a period's positions keep. With no positions
-- every picked date is kept; with positions a date is kept where its place from the
-- first, or from the last, is one of them. Places count over the WHOLE period's picks,
-- including picks that fall before the start (Edge cases, A start the series does not
-- generate), so this step comes before the start is looked at.
fun selected[s : Series] : set Date {
    { d : picked[s] |
        no s.positions
        or placeFromFirst[s, d] in s.positions
        or placeFromLast[s, d] in s.positions }
}

-- Term generated date: a selected date that is the start or falls later. The date range
-- is the model's dates, so no date is cut for lying outside it.
fun generated[s : Series] : set Date {
    { d : selected[s] | D/gte[d, s.start] }
}

-- Term end bound: for a series with a limit, the generated date the limit reaches,
-- counting the generated dates in date order from 1 (none where the series generates
-- fewer dates than the limit); for a series with an end date, the end date; none for a
-- series with neither. A date taken out still counts toward a limit: the count is over
-- GENERATED dates, not occurrences (Term end bound; Examples, A weekly meeting with a week off).
fun endBound[s : Series] : set Date {
    some s.limit
        => { g : generated[s] | plus[#(generated[s] & D/prevs[g]), 1] = s.limit }
        else s.endDate
}

-- Term occurrence: a generated date that is not later than the end bound, where the
-- series has one, and that the exceptions do not hold.
fun occurrenceDates[s : Series] : set Date {
    { d : generated[s] | all b : endBound[s] | D/lte[d, b] } - s.exceptions
}

-- Term window and Operation 35: what [Occurrences] answers for a window, the occurrences
-- from the from date through the through date. (Operations 32 to 34, the refusals of a
-- bad window or a window over the cap, answer no dates and are not modeled.)
fun occurrencesAnswer[s : Series, from, through : Date] : set Date {
    { d : occurrenceDates[s] | D/gte[d, from] and D/lte[d, through] }
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Predicates: what makes a call acceptable, and what each call writes
-- ─────────────────────────────────────────────────────────────────────────────

-- Term selector: a month, a month day or a day entry. (Operation 10 asks for one
-- before a position is allowed.)
pred hasSelector[s : Series] {
    some s.months or some s.monthDays or some s.dayEntries
}

-- The invariants about what a record carries, as the page states them (Invariant 1.1, 1.2).
pred notBothLimitAndEnd[s : Series] {
    not (some s.limit and some s.endDate)
}
pred noPositionWithoutSelector[s : Series] {
    some s.positions implies hasSelector[s]
}

-- open_accepts: the series an [Open] call may record, one that passes every refusal the
-- model carries (the refusals of the shape: Operations 7, 8, 10, 11, 12, 14 and 37).
-- Operation 15 records such a call's parts and no exception, which is `opened` below.
pred openAccepts[s : Series] {
    -- Operation 7: month days never on a weekly series.
    some s.monthDays implies s.frequency != Weekly
    -- Operation 8 (the shape of it): an ordinal on a day entry only on a monthly or
    -- yearly series, and only where the call gives no month days.
    all e : s.dayEntries | some e.ordinal implies
        (s.frequency in Monthly + Yearly and no s.monthDays)
    -- Operation 10: a position only beside a selector.
    noPositionWithoutSelector[s]
    -- Operation 11: a limit and an end date never both.
    notBothLimitAndEnd[s]
    -- Operation 12 and Operation 37: a limit is a positive count, no more than the limit cap.
    some s.limit implies (gte[s.limit, 1] and lte[s.limit, LimitCap])
    -- Operation 14: an end date no earlier than the start.
    some s.endDate implies D/gte[s.endDate, s.start]
}

-- opened: a series just recorded by [Open] (Operation 15): the call's parts, no exception.
pred opened[s : Series] {
    openAccepts[s]
    no s.exceptions
}

-- The fixed parts (Term fixed parts), and what picks they decide: two versions of a series
-- carry the same ones. (Listed one by one, so the check on Invariant 2.1 can name each.)
pred sameFixedParts[a, b : Series] {
    a.sid        = b.sid
    a.start      = b.start
    a.frequency  = b.frequency
    a.interval   = b.interval
    a.weekStart  = b.weekStart
    a.months     = b.months
    a.monthDays  = b.monthDays
    a.dayEntries = b.dayEntries
    a.positions  = b.positions
    a.picks      = b.picks
}

-- except_call: [Except] on a date not yet taken out (Operations 19, 20, 21): the date
-- joins the exceptions, and nothing else of the series changes. (A date already taken
-- out writes nothing, so it makes no new version and is not a step.)
pred exceptCall[pre, post : Series, d : Date] {
    d not in pre.exceptions
    post.exceptions = pre.exceptions + d
    sameFixedParts[pre, post]
    post.limit   = pre.limit
    post.endDate = pre.endDate
}

-- restore_call: [Restore] on a date taken out (Operations 22, 23, 24): the date leaves
-- the exceptions, and nothing else changes.
pred restoreCall[pre, post : Series, d : Date] {
    d in pre.exceptions
    post.exceptions = pre.exceptions - d
    sameFixedParts[pre, post]
    post.limit   = pre.limit
    post.endDate = pre.endDate
}

-- end_call: [End] with an end date (Operations 25 to 30): an end date no earlier than
-- the start (Operation 26) and no later than the series' end bound where it has one
-- (Operation 27), different from the series' own (Operation 29), is recorded with NO
-- limit (Operation 28); the fixed parts and the exceptions stay.
pred endCall[pre, post : Series, e : Date] {
    -- Operation 26: not before the start.
    D/gte[e, pre.start]
    -- Operation 27: not later than the end bound, where the series has one.
    all b : endBound[pre] | D/lte[e, b]
    -- Operation 29: the series' own end date writes nothing, so it is no step.
    e != pre.endDate
    -- Operation 28: the end date of the call, and no limit.
    post.endDate = e
    post.limit = pre.limit   -- BUG: the limit is kept
    sameFixedParts[pre, post]
    post.exceptions = pre.exceptions
}

-- step: any call that writes an existing series, from the series before it to the
-- series after. ([Open] makes a new series, not a step; [Read] and [Occurrences]
-- write nothing, Operation 36.)
pred step[pre, post : Series] {
    some d : Date |
        exceptCall[pre, post, d] or restoreCall[pre, post, d] or endCall[pre, post, d]
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Assertions (verified guarantees)
-- Each "check" asks: is there any valid configuration that violates this assertion?
-- No counterexample (UNSAT) = the guarantee holds in all configurations within scope.
-- An invariant on what a record carries is checked two ways at once: every series
-- [Open] may record carries it, and every call that writes a series leaves it carried.
-- ─────────────────────────────────────────────────────────────────────────────

-- A_Invariant_1_1: a series never carries both a limit and an end date. Opened series
-- cannot (Operation 11), and [End] swaps a limit for an end date rather than adding one
-- (Operation 28), while [Except] and [Restore] touch neither.
assert A_Invariant_1_1 {
    (all s : Series | opened[s] implies notBothLimitAndEnd[s])
    and
    (all pre, post : Series |
        (notBothLimitAndEnd[pre] and step[pre, post]) implies notBothLimitAndEnd[post])
}
check A_Invariant_1_1 for 4 but exactly 6 Date, 3 Period, 5 Int

-- A_Invariant_1_2: a series never carries a position and no selector. Opened series
-- cannot (Operation 10), and no call changes the positions or the selectors (they are
-- fixed parts).
assert A_Invariant_1_2 {
    (all s : Series | opened[s] implies noPositionWithoutSelector[s])
    and
    (all pre, post : Series |
        (noPositionWithoutSelector[pre] and step[pre, post]) implies noPositionWithoutSelector[post])
}
check A_Invariant_1_2 for 4 but exactly 6 Date, 3 Period, 5 Int

-- A_Invariant_2_1: no call changes a fixed part. Each part is named, so a call that
-- let one slip would be caught on that part.
assert A_Invariant_2_1 {
    all pre, post : Series | step[pre, post] implies {
        post.sid        = pre.sid
        post.start      = pre.start
        post.frequency  = pre.frequency
        post.interval   = pre.interval
        post.weekStart  = pre.weekStart
        post.months     = pre.months
        post.monthDays  = pre.monthDays
        post.dayEntries = pre.dayEntries
        post.positions  = pre.positions
        post.picks      = pre.picks
    }
}
check A_Invariant_2_1 for 4 but exactly 6 Date, 3 Period, 5 Int

-- A_Invariant_2_2: [End] never moves a series' end bound later. Where the series had an
-- end bound the new one is no later; where it had none (a series that never ends, or
-- whose limit it never reaches) the new one is an end date, which is a bound where
-- there was none. This is the property Operation 27 guards.
assert A_Invariant_2_2 {
    all pre, post : Series, e : Date |
        endCall[pre, post, e] implies {
            one endBound[post]
            all b : endBound[pre] | D/lte[endBound[post], b]
        }
}
check A_Invariant_2_2 for 4 but exactly 6 Date, 3 Period, 5 Int

-- A_Invariant_3_1: [Occurrences] never answers a date the exceptions hold, for any
-- window.
assert A_Invariant_3_1 {
    all s : Series, from, through : Date |
        no (occurrencesAnswer[s, from, through] & s.exceptions)
}
check A_Invariant_3_1 for 3 but exactly 6 Date, 3 Period, 5 Int

-- A_Invariant_3_2: [Occurrences] never answers a date earlier than the start, though
-- such a date may be picked and may take a place among the positions (Edge cases,
-- A start the series does not generate).
assert A_Invariant_3_2 {
    all s : Series, from, through : Date |
        all d : occurrencesAnswer[s, from, through] | D/gte[d, s.start]
}
check A_Invariant_3_2 for 3 but exactly 6 Date, 3 Period, 5 Int

-- A_Invariant_3_3: [Occurrences] never answers a date later than the end bound, where
-- the series has one.
assert A_Invariant_3_3 {
    all s : Series, from, through : Date |
        all d : occurrencesAnswer[s, from, through], b : endBound[s] | D/lte[d, b]
}
check A_Invariant_3_3 for 3 but exactly 6 Date, 3 Period, 5 Int

-- A_Invariant_3_4: [Occurrences] never answers a date outside the window.
assert A_Invariant_3_4 {
    all s : Series, from, through : Date |
        all d : occurrencesAnswer[s, from, through] | D/gte[d, from] and D/lte[d, through]
}
check A_Invariant_3_4 for 3 but exactly 6 Date, 3 Period, 5 Int

-- A_TermsBuildInOrder: the order the terms build in (the NOTE after Term window count):
-- every step only narrows the one before it, picked, then selected, then generated, then
-- the occurrences, so no date appears that a step before it did not hold.
assert A_TermsBuildInOrder {
    all s : Series | {
        selected[s]        in picked[s]
        generated[s]       in selected[s]
        occurrenceDates[s] in generated[s]
    }
}
check A_TermsBuildInOrder for 3 but exactly 6 Date, 3 Period, 5 Int

-- A_ExceptionsKeepTheBound: a date taken out still counts toward a limit (Term end
-- bound; the Limit entry), so taking one out or putting it back never moves the end
-- bound, and no eleventh Monday is added to a series of ten.
assert A_ExceptionsKeepTheBound {
    all pre, post : Series, d : Date |
        (exceptCall[pre, post, d] or restoreCall[pre, post, d])
            implies endBound[post] = endBound[pre]
}
check A_ExceptionsKeepTheBound for 4 but exactly 6 Date, 3 Period, 5 Int

-- A_LimitHoldsAtMostItsDates: a series [Open] accepted, with a limit, holds no occurrence
-- beyond its limit, whatever the picks, the positions, the start or the exceptions. (The
-- limit being a positive count, Operation 12, is what [Open] guarantees here.)
assert A_LimitHoldsAtMostItsDates {
    all s : Series | (openAccepts[s] and some s.limit) implies lte[#occurrenceDates[s], s.limit]
}
check A_LimitHoldsAtMostItsDates for 3 but exactly 6 Date, 3 Period, 5 Int

-- A_LimitFitsOneCall: an opened series carries a limit no more than the limit cap
-- (Operation 37), and because the limit cap equals the occurrence cap every occurrence
-- of a limited series fits one [Occurrences] call (Decisions, "A cap on the limit").
assert A_LimitFitsOneCall {
    all s : Series | opened[s] and some s.limit implies {
        lte[s.limit, LimitCap]
        lte[#occurrenceDates[s], OccurrenceCap]
    }
}
check A_LimitFitsOneCall for 3 but exactly 6 Date, 3 Period, 5 Int

-- ─────────────────────────────────────────────────────────────────────────────
-- Satisfiability runs — non-vacuity guards
-- Each run must find at least one instance (SAT).
-- UNSAT means a fact is over-constraining the model.
-- ─────────────────────────────────────────────────────────────────────────────

-- ShowLimitSeries: a series with a limit, opened, whose limit is reached (an end bound).
run ShowLimitSeries {
    some s : Series | opened[s] and some s.limit and some endBound[s]
} for 3 but exactly 6 Date, 3 Period, 5 Int

-- ShowEndDateSeries: a series with an end date, opened, that holds an occurrence.
run ShowEndDateSeries {
    some s : Series | opened[s] and some s.endDate and some occurrenceDates[s]
} for 3 but exactly 6 Date, 3 Period, 5 Int

-- ShowSeriesWithNeither: a series with neither limit nor end date: it never ends,
-- so it has no end bound.
run ShowSeriesWithNeither {
    some s : Series | opened[s] and no s.limit and no s.endDate and some occurrenceDates[s] and no endBound[s]
} for 3 but exactly 6 Date, 3 Period, 5 Int

-- ShowDayEntryWithMonths: a day entry beside months (every Thanksgiving: the fourth
-- Thursday of November).
run ShowDayEntryWithMonths {
    some s : Series | opened[s] and some s.dayEntries and some s.months and some occurrenceDates[s]
} for 3 but exactly 6 Date, 3 Period, 5 Int

-- ShowDayEntryWithoutMonths: a day entry with no months (the second Tuesday of each month),
-- including one carrying an ordinal.
run ShowDayEntryWithoutMonths {
    some s : Series | opened[s] and some s.dayEntries and no s.months and some s.dayEntries.ordinal and some occurrenceDates[s]
} for 3 but exactly 6 Date, 3 Period, 5 Int

-- ShowDayEntryWithMonthDays: month days and day entries together, a day entry then
-- standing bare (friday, never -1 friday): the dates both hold (Friday the 13th).
run ShowDayEntryWithMonthDays {
    some s : Series | opened[s] and some s.monthDays and some s.dayEntries and no s.dayEntries.ordinal and some occurrenceDates[s]
} for 3 but exactly 6 Date, 3 Period, 5 Int

-- ShowPositionsNarrow: positions keep fewer dates than a period picks (the last weekday
-- of the month is a position beside a month's weekdays).
run ShowPositionsNarrow {
    some s : Series | opened[s] and some s.positions and selected[s] != picked[s] and some generated[s]
} for 3 but exactly 6 Date, 3 Period, 5 Int

-- ShowPositionCountsPastTheStart: a place counted over picks that precede the start still
-- counts: a picked date before the start holds position 1, so the period's first generated
-- date is not its first pick (the first weekday of a month starting mid-month is gone).
run ShowPositionCountsPastTheStart {
    some s : Series | opened[s] and some s.positions and some d : picked[s] |
        D/lt[d, s.start] and placeFromFirst[s, d] = 1 and 1 in s.positions
} for 3 but exactly 6 Date, 3 Period, 5 Int

-- ShowStartNotGenerated: a start the series does not generate is no occurrence: the
-- series counts its periods from the start, yet the start is not among its dates.
run ShowStartNotGenerated {
    some s : Series | opened[s] and s.start not in generated[s] and some generated[s]
} for 3 but exactly 6 Date, 3 Period, 5 Int

-- ShowExceptionOnAnOccurrence: a generated date taken out is no occurrence.
run ShowExceptionOnAnOccurrence {
    some s : Series | some (generated[s] & s.exceptions) and some occurrenceDates[s]
} for 3 but exactly 6 Date, 3 Period, 5 Int

-- ShowLimitCountsATakenOutDate: a limited series whose reached limit includes a date
-- taken out, so it holds fewer occurrences than its limit (the meeting of Thanksgiving
-- week, cancelled, still counts).
run ShowLimitCountsATakenOutDate {
    some s : Series | openAccepts[s] and some s.limit and some endBound[s] and
        some (generated[s] & s.exceptions) and lt[#occurrenceDates[s], s.limit]
} for 3 but exactly 6 Date, 3 Period, 5 Int

-- ShowLimitNotReached: a limit the series never reaches has no end bound (the 30th of
-- February generates nothing, whatever the limit).
run ShowLimitNotReached {
    some s : Series | opened[s] and some s.limit and no endBound[s]
} for 3 but exactly 6 Date, 3 Period, 5 Int

-- ShowAtTheLimitCap: a series opened at exactly the limit cap, the largest [Open] accepts.
run ShowAtTheLimitCap {
    some s : Series | opened[s] and s.limit = LimitCap and some endBound[s]
} for 3 but exactly 6 Date, 3 Period, 5 Int

-- ShowOverTheLimitCap: a limit over the cap is not one [Open] accepts (Operation 37).
run ShowOverTheLimitCap {
    some s : Series | some s.limit and gt[s.limit, LimitCap] and not openAccepts[s]
} for 3 but exactly 6 Date, 3 Period, 5 Int

-- ShowExceptStep: a valid [Except] step.
run ShowExceptStep {
    some pre, post : Series, d : Date | exceptCall[pre, post, d] and opened[pre]
} for 3 but exactly 6 Date, 3 Period, 5 Int

-- ShowRestoreStep: a valid [Restore] step.
run ShowRestoreStep {
    some pre, post : Series, d : Date | restoreCall[pre, post, d]
} for 3 but exactly 6 Date, 3 Period, 5 Int

-- ShowEndStep: a valid [End] step that swaps a limit for an end date.
run ShowEndStep {
    some pre, post : Series, e : Date |
        endCall[pre, post, e] and opened[pre] and some pre.limit and some endBound[pre]
} for 3 but exactly 6 Date, 3 Period, 5 Int

-- ShowEndShortensASeries: an [End] that actually cuts occurrences off: the series after
-- holds strictly fewer occurrences than the series before.
run ShowEndShortensASeries {
    some pre, post : Series, e : Date |
        endCall[pre, post, e] and opened[pre] and lt[#occurrenceDates[post], #occurrenceDates[pre]]
} for 3 but exactly 6 Date, 3 Period, 5 Int
