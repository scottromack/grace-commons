---- MODULE recurrence-buggy-month-days-on-weekly ----
\* Grace Commons — Recurrence atom (atoms/recurrence.md).
\* Grounded on Final Critique 2, 2026-11-08 at 237cc22 — TLA+ layer written
\* 2026-11-11 (unit `atoms/recurrence.md formal layer`).
\* Derived validator; the English spec is the single source of truth. On any
\* disagreement, diagnose per the entry *The conflict protocol* in pressure-testing.md.
\* BUGGY TWIN of recurrence.tla: identical EXCEPT that [Open] lacks Operation
\* 7, so month days are admitted on a weekly series. Expected result:
\* Op7_MonthDaysNotWeekly violated. If the checker reports every check
\* holding here, that check is vacuous.
\*
\* PURPOSE
\* Check what happens across steps: the series [Open] records or refuses, and
\* what [Except], [Restore] and [End] write over every sequence of calls, with
\* the answer [Occurrences] gives in every state those calls leave. What one
\* series must carry, and how its parts narrow its dates in the order the
\* Terms build them, is the Alloy model's, recurrence.als; this model checks
\* Invariant 1.1 through 3.4 again across steps, as a cross-check, and
\* Operation 7 and 8, the [Open] refusals the Alloy model takes as given.
\*
\* RULES CHECKED (named by the page's own labels)
\*   Invariant 1.1 — no series carries a limit and an end date      (Inv1_1_NotLimitAndEndDate)
\*   Invariant 1.2 — no series carries a position and no selector   (Inv1_2_NoPositionWithoutSelector)
\*   Invariant 2.1 — no step changes a series' fixed parts          (Inv2_1_FixedPartsKept)
\*   Invariant 2.2 — [End] never moves a series' end bound later    (Inv2_2_EndOnlySooner)
\*   Term end bound — a date taken out still counts, so [Except]
\*                    and [Restore] leave the end bound             (TermEndBound_ExceptionsKeepIt)
\*   Invariant 3.1 — [Occurrences] answers no date taken out        (Inv3_1_NoException)
\*   Invariant 3.2 — [Occurrences] answers no date before the start (Inv3_2_NotBeforeStart)
\*   Invariant 3.3 — [Occurrences] answers no date past the end bound (Inv3_3_NotPastEndBound)
\*   Invariant 3.4 — [Occurrences] answers no date outside the window (Inv3_4_InsideWindow)
\*   Operation 7   — month days on a weekly series answer
\*                   invalid-month-day                              (Op7_MonthDaysNotWeekly)
\*   Operation 8   — a day entry the frequency does not admit answers
\*                   invalid-day-entry                              (Op8_DayEntryAdmitted)
\*
\* WHICH REFUSAL ANSWERS
\* Each action's refuses line is read in the page's order (Execution Contract
\* Refusal 1: the refusal listed first that applies answers). [Open]'s line is
\* OpenLine; a refusal code that several Operations give (invalid-month-day
\* for Operation 6 and 7, invalid-position for 9 and 10, invalid-end for 11
\* to 14 and 37) applies where any of them does. Operation 7 and 8 are
\* checked on the answer, both ways: where the rule's case holds, [Open]
\* answers its refusal or one listed before it, and it answers that refusal
\* only where a rule of the page gives it. Those two checks read [Open]'s
\* answer to every call of ProbeCalls in each state where an [Open] may be
\* made (OpenMayBeCalled); the answer reads no state.
\*
\* BOUNDS (the .cfg)
\* One series id, supplied once by the seam (Identity 2: the counter nextId):
\* series are records apart, and no rule of the page relates two series, so
\* one series stands for every series. Four range dates, 1 to 4, in date
\* order; the limit cap and the occurrence cap both 2 (the page's 1,000 each
\* by default, equal as the page has them), so a limit is reached, a limit
\* is left unreached, and a window can hold more occurrences than the cap.
\* [Open] in the steps varies what the steps read: the start, the selected
\* dates, a month as the selector or none, a position or none, and a limit,
\* an end date, both or neither; the other fixed parts take one value each
\* (StepCalls). The answers of Operation 7 and 8 are checked over every
\* frequency, month days none, valid or out of range, and every kind of day
\* entry with the ordinals at each edge of the ranges the page admits
\* (ProbeCalls). Five dates (STEP 3 of the coverage matrix) change no verdict.
\*
\* NOT MODELED HERE
\* - Calendar arithmetic (Term period through Term selected dates): which
\*   dates a frequency, an interval, a week start, a month day, an ordinal
\*   and the positions select is the conformance table's, row by row. [Open]
\*   takes a series' selected dates as given with its call (sel), a fixed
\*   part like the rest, since the fixed parts decide them; the order the
\*   Terms build in is the Alloy model's.
\* - Values: a date is a number in date order; -1 stands for a date the
\*   date range does not hold (Operation 1, 13, 18, 25, 32) and 0 for a blank
\*   end date. A limit is a number, 0 for blank and -1 for one that is not a
\*   positive count. Months, month days and positions are "none", "some"
\*   (each a number in its range) or "out-of-range" (one is not): their
\*   ranges, Operation 5, 6 and 9, are numbers the coverage matrix leaves
\*   unstatable. A call's day entries are one entry, which stands for each
\*   entry of a list: Operation 8 refuses a call any one entry of which is
\*   not admitted.
\* - The week start, interval and frequency in the steps: one value each,
\*   the type admitting another, so a step that changed one shows it.
\* - A refused call as a step: it writes nothing (Execution Contract Read 4),
\*   so it would be a stutter; what each call answers is its Answer, computed
\*   in every state. Storage failure and state-unavailable are not modeled.
\* - [Read] (Operation 31) and Operation 36: a query writes nothing, so it is
\*   no step; [Occurrences]' answer is OccurrencesAnswer, read by the checks.
\* - The daylight-saving cases: an occurrence is a date with no time of day
\*   (Non-goal 2, 3); what a clock change does to a time on it is Calendar
\*   Time's resolve, through the wiring of a composing pattern (Composition
\*   note 2), so nothing here can state it.

EXTENDS Integers, Sequences, FiniteSets

CONSTANTS
    MaxSeries,  \* how many series ids the seam supplies in the model
    NDates,     \* how many range dates the model holds, 1..NDates in date order
    LimitCap,   \* the largest limit a series may carry (Term limit cap)
    OccCap      \* the most occurrences one [Occurrences] call answers (Term occurrence cap)

\* Ids: the series ids the seam may supply, in the order it supplies them.
Ids == 1..MaxSeries

\* Dates: the range dates (Term range date), numbered in date order.
Dates == 1..NDates

\* NotARangeDate: a date the date range does not hold, such as 2026-02-29.
NotARangeDate == -1

\* Blank: a blank limit or end date.
Blank == 0

\* Frequencies: daily | weekly | monthly | yearly (Term frequency).
Frequencies == {"daily", "weekly", "monthly", "yearly"}

\* Weekdays: the days of the week a week start may name; two stand for the
\* seven here, which is enough to show a week start changed.
Weekdays == {"monday", "sunday"}

\* MonthlyOrdinals, YearlyOrdinals: the ordinals Term admitted day entry
\* admits beside a day of the week on a monthly and on a yearly series.
MonthlyOrdinals == (1..5) \cup (-5..-1)
YearlyOrdinals == (1..53) \cup (-53..-1)

\* OrdinalProbes: the ordinals the checks of Operation 8 try: zero, and each
\* edge of both ranges from inside and from outside, from the first and from
\* the last.
OrdinalProbes == {0, 1, 5, 6, 53, 54, -1, -5, -6, -53, -54}

\* NoEntry: a call with no day entries. Every day entry is a record of its
\* kind ("bare": a day of the week alone; "ordinal": a day of the week with
\* the ordinal ord; "not-a-day": a day of the week the page does not name)
\* and its ordinal (0 where it has none).
NoEntry == [kind |-> "none", ord |-> 0]

\* DayEntryProbes: the day entries the checks of Operation 8 try.
DayEntryProbes ==
    {NoEntry, [kind |-> "bare", ord |-> 0], [kind |-> "not-a-day", ord |-> 0]}
        \cup {[kind |-> "ordinal", ord |-> n] : n \in OrdinalProbes}

\* OpenLine: [Open]'s refuses line, in the page's order (the Operations
\* signatures); storage-failure, last, is not modeled.
OpenLine == <<"invalid-start", "invalid-frequency", "invalid-interval",
              "invalid-week-start", "invalid-month", "invalid-month-day",
              "invalid-day-entry", "invalid-position", "invalid-end">>

\* Place: where refusal r stands on [Open]'s line, 1 for the first.
Place(r) == CHOOSE k \in 1..Len(OpenLine) : OpenLine[k] = r

\* StepCalls: the [Open] calls the steps make (BOUNDS): every start and
\* month (none or some), position (none or some), limit and end date,
\* including the calls Operation 10, 11 and 14 refuse.
StepCalls ==
    [start: Dates, freq: {"monthly"}, interval: {1}, wkst: {"monday"},
     months: {"none", "some"}, md: {"none"}, de: {NoEntry},
     pos: {"none", "some"}, limit: {Blank} \cup 1..LimitCap,
     end: {Blank} \cup Dates]

\* ProbeCalls: the [Open] calls the checks of Operation 7 and 8 read: every
\* frequency and one that is none (hourly), month days none, some or out of
\* range, and every day entry of DayEntryProbes, the other parts valid.
ProbeCalls ==
    [start: {1}, freq: Frequencies \cup {"hourly"}, interval: {1},
     wkst: {"monday"}, months: {"none"}, md: {"none", "some", "out-of-range"},
     de: DayEntryProbes, pos: {"none"}, limit: {Blank}, end: {Blank}]

\* NoSeries: what an id that names no series holds.
NoSeries == [start |-> 0, freq |-> "none", interval |-> 0, wkst |-> "none",
             months |-> "none", md |-> "none", de |-> NoEntry, pos |-> "none",
             sel |-> {}]

\* ---------------------------------------------------------------------------
\* State
\* ---------------------------------------------------------------------------

VARIABLES
    fixed,   \* id -> the series' fixed parts and its selected dates (NoSeries before it is opened)
    limit,   \* id -> its limit (Blank: none)
    endDate, \* id -> its end date (Blank: none)
    exc,     \* id -> its exceptions, the dates taken out
    nextId   \* the next series id the seam will supply (Identity 2)

\* vars: every variable; a step that changes none of them is a stutter.
vars == <<fixed, limit, endDate, exc, nextId>>

\* Known: the series id names a series.
Known(i) == fixed[i] # NoSeries

\* TypeOK: each variable holds a value of its kind (the model's typing, not a
\* rule of the page).
TypeOK ==
    /\ \A i \in Ids :
          \/ fixed[i] = NoSeries
          \/ fixed[i] \in [start: Dates, freq: Frequencies, interval: 1..2,
                           wkst: Weekdays, months: {"none", "some"},
                           md: {"none", "some"}, de: DayEntryProbes,
                           pos: {"none", "some"}, sel: SUBSET Dates]
    /\ limit \in [Ids -> {Blank} \cup 1..LimitCap]
    /\ endDate \in [Ids -> {Blank} \cup Dates]
    /\ exc \in [Ids -> SUBSET Dates]
    /\ nextId \in 1..(MaxSeries + 1)

\* Init: no series opened.
Init ==
    /\ fixed = [i \in Ids |-> NoSeries]
    /\ limit = [i \in Ids |-> Blank]
    /\ endDate = [i \in Ids |-> Blank]
    /\ exc = [i \in Ids |-> {}]
    /\ nextId = 1

\* ---------------------------------------------------------------------------
\* The terms, as the page builds them
\* ---------------------------------------------------------------------------

\* GeneratedDates: the selected dates of the series that are the start or
\* fall later (Term generated date); every model date is a range date.
GeneratedDates(i) == {d \in fixed[i].sel : d >= fixed[i].start}

\* Nth: the nth date of a set of dates, in date order, counting from 1.
Nth(S, n) == CHOOSE d \in S : Cardinality({e \in S : e <= d}) = n

\* EndBound: for a series with a limit, the generated date the limit
\* reaches, counting the generated dates (a date taken out among them) in
\* date order from 1, and none (0) where the series generates fewer; for a
\* series with an end date, the end date; none (0) for one with neither
\* (Term end bound).
EndBound(i) ==
    IF limit[i] # Blank
    THEN IF Cardinality(GeneratedDates(i)) >= limit[i]
         THEN Nth(GeneratedDates(i), limit[i]) ELSE 0
    ELSE endDate[i]

\* Occurrences: the generated dates not later than the end bound, where the
\* series has one, that the exceptions do not hold (Term occurrence).
Occurrences(i) ==
    {d \in GeneratedDates(i) : EndBound(i) = 0 \/ d <= EndBound(i)} \ exc[i]

\* WindowHolds: the occurrences the window from f through t holds (Term
\* window).
WindowHolds(i, f, t) == {d \in Occurrences(i) : f <= d /\ d <= t}

\* ---------------------------------------------------------------------------
\* Which refusal answers
\* ---------------------------------------------------------------------------

\* HasSelector: the call carries a month, a month day or a day entry (Term
\* selector).
HasSelector(c) == c.months # "none" \/ c.md # "none" \/ c.de.kind # "none"

\* AdmittedDayEntry: the call's day entry is one Term admitted day entry
\* admits: a day of the week alone, or, where the call gives no month days,
\* one with an ordinal from 1 through 5 or -5 through -1 on a monthly series
\* and from 1 through 53 or -53 through -1 on a yearly one.
AdmittedDayEntry(c) ==
    CASE c.de.kind = "none"      -> TRUE
      [] c.de.kind = "bare"      -> TRUE
      [] c.de.kind = "not-a-day" -> FALSE
      [] c.de.kind = "ordinal"   ->
            /\ c.md = "none"
            /\ \/ (c.freq = "monthly" /\ c.de.ord \in MonthlyOrdinals)
               \/ (c.freq = "yearly" /\ c.de.ord \in YearlyOrdinals)

\* OpenApplies: whether refusal r of [Open]'s line applies to call c, by the
\* Operations that give it.
OpenApplies(r, c) ==
    CASE r = "invalid-start"      -> c.start \notin Dates                          \* Operation 1
      [] r = "invalid-frequency"  -> c.freq \notin Frequencies                     \* Operation 2
      [] r = "invalid-interval"   -> c.interval < 1                                \* Operation 3
      [] r = "invalid-week-start" -> c.wkst \notin Weekdays                        \* Operation 4
      [] r = "invalid-month"      -> c.months = "out-of-range"                     \* Operation 5
      [] r = "invalid-month-day"  -> \/ c.md = "out-of-range"                      \* Operation 6
                                     \/ FALSE   \* BUG: Operation 7 dropped
      [] r = "invalid-day-entry"  -> ~AdmittedDayEntry(c)                          \* Operation 8
      [] r = "invalid-position"   -> \/ c.pos = "out-of-range"                     \* Operation 9
                                     \/ (c.pos # "none" /\ ~HasSelector(c))        \* Operation 10
      [] r = "invalid-end"        -> \/ (c.limit # Blank /\ c.end # Blank)         \* Operation 11
                                     \/ (c.limit # Blank /\ c.limit < 1)           \* Operation 12
                                     \/ (c.limit # Blank /\ c.limit > LimitCap)    \* Operation 37
                                     \/ (c.end # Blank /\ c.end \notin Dates)      \* Operation 13
                                     \/ (c.end # Blank /\ c.end < c.start)         \* Operation 14

\* OpenFrom: the first refusal at or after place k of [Open]'s line that
\* applies to call c, or "ok" when none does.
RECURSIVE OpenFrom(_, _)
OpenFrom(c, k) ==
    IF k > Len(OpenLine) THEN "ok"
    ELSE IF OpenApplies(OpenLine[k], c) THEN OpenLine[k]
    ELSE OpenFrom(c, k + 1)

\* OpenAnswer: what [Open] answers to call c: the first refusal on its line
\* that applies (Execution Contract Refusal 1), else it records ("ok").
OpenAnswer(c) == OpenFrom(c, 1)

\* ExceptAnswer: what an exception action answers for date d on id i:
\* not-known (Operation 17), then invalid-date (Operation 18).
ExceptAnswer(i, d) ==
    IF ~Known(i) THEN "not-known"
    ELSE IF d \notin Dates THEN "invalid-date"
    ELSE "ok"

\* EndAnswer: what [End] answers for end date e on id i: not-known
\* (Operation 17), invalid-date (Operation 25), then invalid-end for an end
\* date before the start (Operation 26) or past the end bound (Operation 27).
EndAnswer(i, e) ==
    IF ~Known(i) THEN "not-known"
    ELSE IF e \notin Dates THEN "invalid-date"
    ELSE IF e < fixed[i].start THEN "invalid-end"
    ELSE IF EndBound(i) # 0 /\ EndBound(i) < e THEN "invalid-end"
    ELSE "ok"

\* OccurrencesCode: what [Occurrences] answers for the window from f through
\* t on id i: not-known (Operation 17), invalid-date (Operation 32),
\* invalid-window (Operation 33), too-many-occurrences (Operation 34), else
\* the occurrences ("ok").
OccurrencesCode(i, f, t) ==
    IF ~Known(i) THEN "not-known"
    ELSE IF f \notin Dates \/ t \notin Dates THEN "invalid-date"
    ELSE IF t < f THEN "invalid-window"
    ELSE IF Cardinality(WindowHolds(i, f, t)) > OccCap THEN "too-many-occurrences"
    ELSE "ok"

\* OccurrencesAnswer: the dates [Occurrences] answers: every occurrence the
\* window holds (Operation 35), or none where it refuses.
OccurrencesAnswer(i, f, t) ==
    IF OccurrencesCode(i, f, t) = "ok" THEN WindowHolds(i, f, t) ELSE {}

\* ---------------------------------------------------------------------------
\* Actions
\* ---------------------------------------------------------------------------

\* Open: an admitted [Open] records exactly one series under the series id
\* the seam supplies, carrying the call's start, frequency, interval, week
\* start, months, month days, day entries, positions, limit and end date,
\* the dates those parts select (sel, the calendar's), and no exception
\* (Operation 15, 16).
Open(c, sl) ==
    /\ nextId <= MaxSeries
    /\ OpenAnswer(c) = "ok"
    /\ fixed' = [fixed EXCEPT ![nextId] =
                    [start |-> c.start, freq |-> c.freq, interval |-> c.interval,
                     wkst |-> c.wkst, months |-> c.months, md |-> c.md,
                     de |-> c.de, pos |-> c.pos, sel |-> sl]]
    /\ limit' = [limit EXCEPT ![nextId] = c.limit]
    /\ endDate' = [endDate EXCEPT ![nextId] = c.end]
    /\ exc' = [exc EXCEPT ![nextId] = {}]
    /\ nextId' = nextId + 1

\* Except: an admitted [Except] on a date not taken out adds it to the
\* exceptions (Operation 19, 21); on a date taken out it writes nothing
\* (Operation 20), a stutter.
Except(i, d) ==
    /\ ExceptAnswer(i, d) = "ok"
    /\ d \notin exc[i]
    /\ exc' = [exc EXCEPT ![i] = exc[i] \cup {d}]
    /\ UNCHANGED <<fixed, limit, endDate, nextId>>

\* Restore: an admitted [Restore] on a date taken out removes it from the
\* exceptions (Operation 22, 24); on another date it writes nothing
\* (Operation 23), a stutter.
Restore(i, d) ==
    /\ ExceptAnswer(i, d) = "ok"
    /\ d \in exc[i]
    /\ exc' = [exc EXCEPT ![i] = exc[i] \ {d}]
    /\ UNCHANGED <<fixed, limit, endDate, nextId>>

\* End: an admitted [End] with an end date other than the series' own
\* records the series carrying that end date and no limit (Operation 28,
\* 30); the series' own end date writes nothing (Operation 29), a stutter.
End(i, e) ==
    /\ EndAnswer(i, e) = "ok"
    /\ e # endDate[i]
    /\ endDate' = [endDate EXCEPT ![i] = e]
    /\ limit' = [limit EXCEPT ![i] = Blank]
    /\ UNCHANGED <<fixed, exc, nextId>>

\* Next: an [Open] is admitted, or a writing series action is admitted on
\* a series, with any date, a range date or not. A refused call writes
\* nothing and is a stutter.
Next ==
    \/ \E c \in StepCalls, sl \in SUBSET Dates : Open(c, sl)
    \/ \E i \in Ids, d \in Dates \cup {NotARangeDate} : Except(i, d)
    \/ \E i \in Ids, d \in Dates \cup {NotARangeDate} : Restore(i, d)
    \/ \E i \in Ids, e \in Dates \cup {NotARangeDate} : End(i, e)

\* Spec: every behaviour from Init by Next steps.
Spec == Init /\ [][Next]_vars

\* ---------------------------------------------------------------------------
\* Checks (the verification surface)
\* ---------------------------------------------------------------------------

\* Inv1_1_NotLimitAndEndDate: no series carries both a limit and an end date
\* (Invariant 1.1), in every state any sequence of calls leaves.
Inv1_1_NotLimitAndEndDate ==
    \A i \in Ids : Known(i) => ~(limit[i] # Blank /\ endDate[i] # Blank)

\* Inv1_2_NoPositionWithoutSelector: no series carries a position and no
\* month, month day or day entry (Invariant 1.2).
Inv1_2_NoPositionWithoutSelector ==
    \A i \in Ids : (Known(i) /\ fixed[i].pos # "none") =>
        (fixed[i].months # "none" \/ fixed[i].md # "none" \/ fixed[i].de.kind # "none")

\* Inv2_1_FixedPartsKept: no step changes a series' start, frequency,
\* interval, week start, months, month days, day entries or positions, nor
\* the dates they select; the series id is the function's domain
\* (Invariant 2.1, Term fixed parts).
Inv2_1_FixedPartsKept ==
    [][\A i \in Ids : Known(i) => fixed'[i] = fixed[i]]_vars

\* Ended: the step writes series i's limit or end date, which only [End]
\* does (Operation 28).
Ended(i) == limit'[i] # limit[i] \/ endDate'[i] # endDate[i]

\* Inv2_2_EndOnlySooner: a step that writes a series' limit or end date,
\* where the series had an end bound, leaves it one no later (Invariant
\* 2.2). A series with no end bound may take one.
Inv2_2_EndOnlySooner ==
    [][\A i \in Ids : (Known(i) /\ Ended(i) /\ EndBound(i) # 0)
                          => (EndBound(i)' # 0 /\ EndBound(i)' <= EndBound(i))]_vars

\* TermEndBound_ExceptionsKeepIt: a step that writes neither the limit nor
\* the end date of a series, an [Except] or a [Restore], leaves its end
\* bound where it was: a date taken out still counts toward a limit (Term
\* end bound; Examples, A weekly meeting with a week off: no eleventh Monday
\* is added).
TermEndBound_ExceptionsKeepIt ==
    [][\A i \in Ids : (Known(i) /\ ~Ended(i)) => EndBound(i)' = EndBound(i)]_vars

\* Inv3_1_NoException: in every state, [Occurrences] answers no date the
\* series' exceptions hold, for any window (Invariant 3.1).
Inv3_1_NoException ==
    \A i \in Ids, f, t \in Dates : OccurrencesAnswer(i, f, t) \cap exc[i] = {}

\* Inv3_2_NotBeforeStart: [Occurrences] answers no date earlier than the
\* series' start, though a selected date may precede it (Invariant 3.2).
Inv3_2_NotBeforeStart ==
    \A i \in Ids, f, t \in Dates :
        \A d \in OccurrencesAnswer(i, f, t) : d >= fixed[i].start

\* Inv3_3_NotPastEndBound: [Occurrences] answers no date later than the
\* series' end bound, where it has one (Invariant 3.3).
Inv3_3_NotPastEndBound ==
    \A i \in Ids, f, t \in Dates :
        EndBound(i) # 0 => \A d \in OccurrencesAnswer(i, f, t) : d <= EndBound(i)

\* Inv3_4_InsideWindow: [Occurrences] answers no date outside the window
\* from the from date through the through date (Invariant 3.4).
Inv3_4_InsideWindow ==
    \A i \in Ids, f, t \in Dates :
        \A d \in OccurrencesAnswer(i, f, t) : f <= d /\ d <= t

\* OpenMayBeCalled: the seam can still supply a series id, so an [Open]
\* call may be made in this state. [Open]'s answer reads no state (the
\* database's refusal, storage-failure, is not modeled), so the checks of
\* Operation 7 and 8 read it in each state where a call may be made.
OpenMayBeCalled == nextId <= MaxSeries

\* RefusedAtOrBefore: [Open] refuses call c with refusal r or with one its
\* line lists before r, as Execution Contract Refusal 1 has it when r's
\* case holds.
RefusedAtOrBefore(c, r) ==
    OpenAnswer(c) # "ok" /\ Place(OpenAnswer(c)) <= Place(r)

\* Op7_MonthDaysNotWeekly: a call carrying a month day on a weekly series is
\* refused with invalid-month-day or a refusal listed before it (Operation
\* 7); and [Open] answers invalid-month-day only to a month day out of range
\* (Operation 6) or one on a weekly series, so a month day on a daily,
\* monthly or yearly series is not refused for it.
Op7_MonthDaysNotWeekly ==
    OpenMayBeCalled => \A c \in ProbeCalls :
        /\ (c.md # "none" /\ c.freq = "weekly") => RefusedAtOrBefore(c, "invalid-month-day")
        /\ OpenAnswer(c) = "invalid-month-day" =>
               (c.md = "out-of-range" \/ (c.md # "none" /\ c.freq = "weekly"))

\* DayEntryRefused: the call's day entry is not one the page admits: not a
\* day of the week, or one with an ordinal where the series is not monthly
\* or yearly, where the call gives month days, or where the ordinal lies
\* outside 1 through 5 and -5 through -1 (monthly) or 1 through 53 and -53
\* through -1 (yearly) (Term admitted day entry; [Invalid Day Entry]).
DayEntryRefused(c) ==
    \/ c.de.kind = "not-a-day"
    \/ /\ c.de.kind = "ordinal"
       /\ \/ c.freq \notin {"monthly", "yearly"}
          \/ c.md # "none"
          \/ (c.freq = "monthly" /\ (c.de.ord = 0 \/ c.de.ord > 5 \/ c.de.ord < -5))
          \/ (c.freq = "yearly" /\ (c.de.ord = 0 \/ c.de.ord > 53 \/ c.de.ord < -53))

\* Op8_DayEntryAdmitted: a call carrying a day entry the page does not admit
\* is refused with invalid-day-entry or a refusal listed before it
\* (Operation 8), such as 2 tuesday on a weekly series; and [Open] answers
\* invalid-day-entry to no other call, so 2 tuesday on a monthly series and
\* the fifth or the 53rd where the page admits them are not refused for it.
Op8_DayEntryAdmitted ==
    OpenMayBeCalled => \A c \in ProbeCalls :
        /\ DayEntryRefused(c) => RefusedAtOrBefore(c, "invalid-day-entry")
        /\ OpenAnswer(c) = "invalid-day-entry" => DayEntryRefused(c)

====
