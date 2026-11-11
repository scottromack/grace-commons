---- MODULE calendar-time-buggy-id-reallocated ----
\* DELIBERATELY WRONG twin of calendar-time.tla (unit: `atoms/calendar-time.md formal layer`).
\*
\* INJECTED DEFECT: [Change] records the place again under a fresh place id the seam supplies,
\* as a store that writes a changed record as a new one would (Invariant 2.1).
\*
\* BREAKS: Inv2_1_KeepsId.
\* Everything else is calendar-time.tla as written; read its comments there.

EXTENDS Integers, FiniteSets

CONSTANTS
    Slots,       \* the place slots: how many places the model can hold
    ZoneCalls,   \* the time zones a call may carry: the zone names and strings that are none
    WeekCalls,   \* the week starts a call may carry: days of the week and words that are none
    FirstYear,   \* the first year of the model's date range
    LastYear,    \* the last year of the model's date range
    MaxMonths    \* the largest months amount, either sign, a [Shift] call carries

\* ---------------------------------------------------------------------------
\* The calendar (Term calendar: the Gregorian calendar of ISO 8601)
\* ---------------------------------------------------------------------------

\* Leap: a year whose February holds 29 days in the Gregorian calendar.
Leap(y) == ((y % 4) = 0 /\ (y % 100) # 0) \/ (y % 400) = 0

\* MonthLength: how many days a month of the calendar holds (Term month length).
MonthLength(y, m) ==
    IF m = 2 THEN (IF Leap(y) THEN 29 ELSE 28)
    ELSE IF m \in {4, 6, 9, 11} THEN 30 ELSE 31

\* IsCalendarDate: a year, a month and a day naming a day the calendar holds
\* (Term calendar date): 2028-02-29 is one, 2027-02-29 is not.
IsCalendarDate(y, m, d) == m \in 1..12 /\ d \in 1..MonthLength(y, m)

\* InRange: a year inside the model's date range (Term date range, scaled).
InRange(y) == y \in FirstYear..LastYear

\* DaysFromCivil: the count of days from 1970-01-01 to a date (H. Hinnant's
\* civil-date algorithm, for years after 0). A day past its month's length
\* counts on into the next month, as an unclamped date library would.
DaysFromCivil(y, m, d) ==
    LET yy  == IF m <= 2 THEN y - 1 ELSE y
        era == yy \div 400
        yoe == yy - era * 400
        mp  == IF m > 2 THEN m - 3 ELSE m + 9
        doy == (153 * mp + 2) \div 5 + d - 1
        doe == yoe * 365 + yoe \div 4 - yoe \div 100 + doy
    IN  era * 146097 + doe - 719468

\* CivilFromDays: the date a count of days from 1970-01-01 names, as
\* <<year, month, day>>; the inverse of DaysFromCivil.
CivilFromDays(n) ==
    LET z   == n + 719468
        era == z \div 146097
        doe == z - era * 146097
        yoe == (doe - doe \div 1460 + doe \div 36524 - doe \div 146096) \div 365
        doy == doe - (365 * yoe + yoe \div 4 - yoe \div 100)
        mp  == (5 * doy + 2) \div 153
        dd  == doy - (153 * mp + 2) \div 5 + 1
        mm  == IF mp < 10 THEN mp + 3 ELSE mp - 9
    IN  <<yoe + era * 400 + (IF mm <= 2 THEN 1 ELSE 0), mm, dd>>

\* DayIndex: the days of the week (Term day of the week), Monday counted 0 as
\* ISO 8601 counts it. 1970-01-01, day 0, was a Thursday (index 3).
DayIndex == [monday |-> 0, tuesday |-> 1, wednesday |-> 2, thursday |-> 3,
             friday |-> 4, saturday |-> 5, sunday |-> 6]

\* DaysOfWeek: the seven days of the week, the words a week start may be.
DaysOfWeek == DOMAIN DayIndex

\* ---------------------------------------------------------------------------
\* The time zone rules, as the deployment supplies them (Capability
\* requirement 2): the zone names, a link, and each zone's offsets in hours.
\* ---------------------------------------------------------------------------

\* HourOf: an instant, counted in whole hours from 1970-01-01T00:00Z.
HourOf(y, m, d, h) == DaysFromCivil(y, m, d) * 24 + h

\* ZoneNames: every name the rules carry, two zones and a link (Term zone names).
ZoneNames == {"America/Chicago", "Europe/Berlin", "US/Central"}

\* ZoneOf: the zone a name names: a link names the zone it links to.
ZoneOf(z) == IF z = "US/Central" THEN "America/Chicago" ELSE z

\* Offset: how far the zone's clock stands from UTC at an instant, in hours
\* (Term offset): Chicago at -05:00 until its clocks go back at
\* 2026-11-01T07:00Z, then -06:00; Berlin at +02:00 until 2026-10-25T01:00Z,
\* then +01:00 (the 2026 rules the page's conformance table names).
Offset(z, t) ==
    IF ZoneOf(z) = "America/Chicago"
    THEN (IF t < HourOf(2026, 11, 1, 7) THEN -5 ELSE -6)
    ELSE (IF t < HourOf(2026, 10, 25, 1) THEN 2 ELSE 1)

\* ---------------------------------------------------------------------------
\* The window a [Show] reads in (bounds; see the header)
\* ---------------------------------------------------------------------------

\* NowFrom, NowTo: the first and last readers' nows.
NowFrom == HourOf(2026, 10, 28, 12)
NowTo   == HourOf(2026, 10, 30, 12)

\* Instants: every whole-hour instant a [Show] call reads in the model.
Instants == HourOf(2026, 8, 29, 0)..HourOf(2026, 11, 3, 0)

\* LocalDay: the local date the place's clock shows at an instant, as a count
\* of days from 1970-01-01 (Term read date; at now, Term reader's date).
\* Computed once for the window, since the rules do not change.
LocalDay == [z \in ZoneNames |-> [t \in Instants |-> (t + Offset(z, t)) \div 24]]

\* MonthIdx: the calendar month a local date lies in, counted as year * 12 +
\* month, so the month before is one less (for Term month count).
MonthIdx == [n \in (HourOf(2026, 8, 28, 0) \div 24)..(HourOf(2026, 11, 4, 0) \div 24) |->
                LET c == CivilFromDays(n) IN c[1] * 12 + c[2]]

\* WeekIdx: the week a local date lies in, where weeks start on the week start
\* (Term week): two dates share a week exactly when they share this number.
WeekIdx(n, w) == (n + 3 - DayIndex[w]) \div 7

\* ---------------------------------------------------------------------------
\* [Show]: the relative day (Operation 28 through 36)
\* ---------------------------------------------------------------------------

\* DayCount: how many calendar days the read date lies back from the reader's
\* date (Term day count): 0 for the reader's date, 1 for the date before.
DayCount(i, n, z) == LocalDay[z][n] - LocalDay[z][i]

\* WeekCount: how many weeks the read date's week lies back from the week of
\* the reader's date (Term week count).
WeekCount(i, n, z, w) == WeekIdx(LocalDay[z][n], w) - WeekIdx(LocalDay[z][i], w)

\* MonthCount: how many calendar months the read date's month lies back from
\* the reader's date's month (Term month count).
MonthCount(i, n, z) == MonthIdx[LocalDay[z][n]] - MonthIdx[LocalDay[z][i]]

\* Case: the condition of Operation k, 28 through 36, over the day count dc,
\* the week count wc and the month count mc, as the page states each.
Case(k, dc, wc, mc) ==
    CASE k = 28 -> dc = 0
      [] k = 29 -> dc = 1
      [] k = 30 -> dc = -1
      [] k = 31 -> dc > 1 /\ wc = 0
      [] k = 32 -> dc > 1 /\ wc = 1
      [] k = 33 -> wc > 1 /\ mc = 0
      [] k = 34 -> wc > 1 /\ mc = 1
      [] k = 35 -> wc > 1 /\ mc > 1
      [] k = 36 -> dc <= -2

\* Answer: the relative day Operation k answers (Term relative day).
Answer == [k \in 28..36 |->
             CASE k = 28 -> "today"        [] k = 29 -> "yesterday"
               [] k = 30 -> "tomorrow"     [] k = 31 -> "current-week"
               [] k = 32 -> "last-week"    [] k = 33 -> "current-month"
               [] k = 34 -> "last-month"   [] k = 35 -> "full-date"
               [] k = 36 -> "full-date"]

\* CasesFor: the operations among 28 through 36 whose condition holds for the
\* instant i read at now n in a place on zone z whose weeks start on w.
CasesFor(i, n, z, w) ==
    LET dc == DayCount(i, n, z)
        wc == WeekCount(i, n, z, w)
        mc == MonthCount(i, n, z)
    IN  {k \in 28..36 : Case(k, dc, wc, mc)}

\* RelativeDay: what [Show] answers as the relative day: the answer of the
\* operation whose condition holds ("none" where none does).
RelativeDay(i, n, z, w) ==
    LET ks == CasesFor(i, n, z, w)
    IN  IF ks = {} THEN "none" ELSE Answer[CHOOSE k \in ks : TRUE]

\* ---------------------------------------------------------------------------
\* [Shift] (Operation 22 through 26)
\* ---------------------------------------------------------------------------

\* Overflows: the overflows a [Shift] call may carry (Term overflow).
Overflows == {"clamp", "reject"}

\* Signed: the years, months and days are all zero or more, or all zero or
\* less (Term signed amount; the model's amounts are whole numbers).
Signed(c) == (c.years >= 0 /\ c.months >= 0 /\ c.days >= 0)
          \/ (c.years <= 0 /\ c.months <= 0 /\ c.days <= 0)

\* LandingMonth: the month the month move (years * 12 + months) months from the
\* local date's month, counted on across the end of a year (Term landing
\* month, Term month move), as <<year, month>>.
LandingMonth(c) ==
    LET k == c.y * 12 + (c.m - 1) + (c.years * 12 + c.months)
    IN  <<k \div 12, (k % 12) + 1>>

\* LandingDay: the local date's day, or the landing month's length where the
\* day exceeds it (Term landing day).
LandingDay(c) ==
    LET lm == LandingMonth(c)
    IN  IF c.d > MonthLength(lm[1], lm[2]) THEN MonthLength(lm[1], lm[2]) ELSE c.d

\* ShiftedDate: the date the amount's days from the landing month's landing
\* day, counted on across months and years (Term shifted date).
ShiftedDate(c) ==
    LET lm == LandingMonth(c)
    IN  CivilFromDays(DaysFromCivil(lm[1], lm[2], LandingDay(c)) + c.days)

\* Refused: a [Shift] answer that is a refusal, written as an answer record.
Refused(r) == [r |-> r, y |-> 0, m |-> 0, d |-> 0]

\* ShiftAnswer: what [Shift] answers for a call: the refusal listed first on
\* the action's refuses line among those that apply (Execution Contract
\* Refusal 1: invalid-date, out-of-range, invalid-amount, invalid-overflow,
\* no-such-day), else the shifted date (Operation 26).
ShiftAnswer(c) ==
    LET lm == LandingMonth(c)
        sd == ShiftedDate(c)
    IN  CASE ~IsCalendarDate(c.y, c.m, c.d)            -> Refused("invalid-date")      \* Operation 10
          [] ~InRange(c.y) \/ ~InRange(sd[1])          -> Refused("out-of-range")      \* Operation 11, 25
          [] ~Signed(c)                                -> Refused("invalid-amount")    \* Operation 22
          [] c.overflow \notin Overflows               -> Refused("invalid-overflow")  \* Operation 23
          [] c.d > MonthLength(lm[1], lm[2]) /\ c.overflow = "reject"
                                                       -> Refused("no-such-day")       \* Operation 24
          [] OTHER -> [r |-> "date", y |-> sd[1], m |-> sd[2], d |-> sd[3]]            \* Operation 26

\* NoCall, NoAnswer: the call and answer records before any [Shift] call.
NoCall   == [y |-> 0, m |-> 0, d |-> 0, years |-> 0, months |-> 0, days |-> 0, overflow |-> "none"]
NoAnswer == Refused("none")

\* ---------------------------------------------------------------------------
\* State
\* ---------------------------------------------------------------------------

VARIABLES
    part,     \* which part of the model this behaviour runs: "places", "show" or "shift"
    opened,   \* slot -> whether a place has been opened in it
    pid,      \* slot -> the place's place id (0 before it is opened)
    tz,       \* slot -> the place's time zone ("none" before it is opened)
    ws,       \* slot -> the place's week start ("none" before it is opened)
    nextId,   \* the next place id the seam will supply (Capability requirement 1)
    now,      \* the deployment's clock reading, in whole hours (Term now)
    call,     \* the [Shift] call made, or NoCall
    answer    \* what that [Shift] call answered, or NoAnswer

vars == <<part, opened, pid, tz, ws, nextId, now, call, answer>>

\* Reader: the slot whose place the "show" part reads.
Reader == CHOOSE s \in Slots : TRUE

\* TypeOK: each variable holds a value of its kind (the model's typing, not a
\* rule of the page).
TypeOK ==
    /\ part \in {"places", "show", "shift"}
    /\ opened \in [Slots -> BOOLEAN]
    /\ pid \in [Slots -> 0..(Cardinality(Slots) + 1)]
    /\ tz \in [Slots -> ZoneCalls \cup {"none"}]
    /\ ws \in [Slots -> WeekCalls \cup {"none"}]
    /\ nextId \in 1..(Cardinality(Slots) + 2)
    /\ now \in NowFrom..NowTo

\* Empty: no place opened, the seam's first id unsupplied.
Empty ==
    /\ opened = [s \in Slots |-> FALSE]
    /\ pid = [s \in Slots |-> 0]
    /\ tz = [s \in Slots |-> "none"]
    /\ ws = [s \in Slots |-> "none"]
    /\ nextId = 1

\* Init: one of the three parts. "places" starts with no place; "show" starts
\* with the reader's place opened on any zone name and any day of the week
\* (any place [Open] or [Change] can leave) and the clock at NowFrom; "shift"
\* starts with no call made.
Init ==
    \/ /\ part = "places"
       /\ Empty
       /\ now = NowFrom
       /\ call = NoCall /\ answer = NoAnswer
    \/ /\ part = "show"
       /\ opened = [s \in Slots |-> s = Reader]
       /\ pid = [s \in Slots |-> IF s = Reader THEN 1 ELSE 0]
       /\ tz \in {[s \in Slots |-> IF s = Reader THEN z ELSE "none"] : z \in ZoneNames}
       /\ ws \in {[s \in Slots |-> IF s = Reader THEN w ELSE "none"] : w \in DaysOfWeek}
       /\ nextId = 2
       /\ now = NowFrom
       /\ call = NoCall /\ answer = NoAnswer
    \/ /\ part = "shift"
       /\ Empty
       /\ now = NowFrom
       /\ call = NoCall /\ answer = NoAnswer

\* ---------------------------------------------------------------------------
\* Actions
\* ---------------------------------------------------------------------------

\* Open: [Open] in a free slot with a time zone among the zone names
\* (Operation 1) and a day of the week (Operation 2) records one place carrying
\* the place id the seam supplies and the call's time zone and week start
\* (Operation 3). A refused call writes nothing, so it is no step.
Open(s, z, w) ==
    /\ part = "places"
    /\ ~opened[s]
    /\ z \in ZoneNames
    /\ w \in DaysOfWeek
    /\ opened' = [opened EXCEPT ![s] = TRUE]
    /\ pid' = [pid EXCEPT ![s] = nextId]
    /\ tz' = [tz EXCEPT ![s] = z]
    /\ ws' = [ws EXCEPT ![s] = w]
    /\ nextId' = nextId + 1
    /\ UNCHANGED <<part, now, call, answer>>

\* Change: [Change] on an opened place with a time zone among the zone names
\* and a day of the week records the place carrying the call's time zone and
\* week start where either differs from the place's (Operation 6); where both
\* are equal it writes nothing (Operation 7), so that call is no step.
Change(s, z, w) ==
    /\ part = "places"
    /\ opened[s]
    /\ z \in ZoneNames
    /\ w \in DaysOfWeek
    /\ (z # tz[s] \/ w # ws[s])
    /\ tz' = [tz EXCEPT ![s] = z]
    /\ ws' = [ws EXCEPT ![s] = w]
    /\ nextId <= Cardinality(Slots) + 1
    /\ pid' = [pid EXCEPT ![s] = nextId]     \* BUG: a fresh id on every change
    /\ nextId' = nextId + 1
    /\ UNCHANGED <<part, opened, now, call, answer>>

\* Tick: the deployment's clock moves on an hour (Term now); a [Show] at any
\* now reads the place as it stands.
Tick ==
    /\ part = "show"
    /\ now < NowTo
    /\ now' = now + 1
    /\ UNCHANGED <<part, opened, pid, tz, ws, nextId, call, answer>>

\* ShiftCall: one [Shift] call, with a date of the model's years (day 1 to 31
\* of any month, so some are no calendar date), whole amounts of either sign
\* and an overflow, and the answer the page owes it.
ShiftCall ==
    /\ part = "shift"
    /\ call = NoCall
    /\ \E y \in FirstYear..LastYear, m \in 1..12, d \in 1..31,
          yrs \in -1..1, mos \in (-MaxMonths)..MaxMonths, dys \in -1..1,
          o \in Overflows :
         LET c == [y |-> y, m |-> m, d |-> d, years |-> yrs, months |-> mos,
                   days |-> dys, overflow |-> o]
         IN  /\ call' = c
             /\ answer' = ShiftAnswer(c)
    /\ UNCHANGED <<part, opened, pid, tz, ws, nextId, now>>

\* Next: any admitted [Open] or [Change], a clock tick, or a [Shift] call.
Next ==
    \/ \E s \in Slots, z \in ZoneCalls, w \in WeekCalls : Open(s, z, w)
    \/ \E s \in Slots, z \in ZoneCalls, w \in WeekCalls : Change(s, z, w)
    \/ Tick
    \/ ShiftCall

\* Spec: every behaviour from Init by Next steps.
Spec == Init /\ [][Next]_vars

\* ---------------------------------------------------------------------------
\* Checks (the verification surface)
\* ---------------------------------------------------------------------------

\* Inv2_1_KeepsId: no step changes the place id of a place that has one: a
\* place keeps the id it was opened with for the system's life (Invariant 2.1,
\* Check 3.1).
Inv2_1_KeepsId ==
    [][\A s \in Slots : opened[s] => pid'[s] = pid[s]]_vars

\* State2_NeverRemoved: no step removes a place that has been opened (State 2).
State2_NeverRemoved ==
    [][\A s \in Slots : opened[s] => opened'[s]]_vars

\* Inv3_1_CalendarNotHours: while the reader's date stays the same and the
\* place is unchanged, the clock moving on changes no instant's relative day: a
\* reading moves at the reader's midnight, never as the hours between the
\* instant and now grow (Invariant 3.1).
Inv3_1_CalendarNotHours ==
    [][(/\ opened[Reader]
        /\ UNCHANGED <<tz, ws>>
        /\ LocalDay[tz[Reader]][now'] = LocalDay[tz[Reader]][now])
       => \A i \in Instants :
             RelativeDay(i, now', tz[Reader], ws[Reader])
               = RelativeDay(i, now, tz[Reader], ws[Reader])]_vars

\* ShowOneRelativeDay: at every now, for every instant in the window, exactly
\* one of Operation 28 through 36 applies, so [Show] owes one relative day,
\* never none and never two (the Term relative day's eight answers cover every
\* read date, one each).
ShowOneRelativeDay ==
    part = "show" =>
        \A i \in Instants : Cardinality(CasesFor(i, now, tz[Reader], ws[Reader])) = 1

\* Inv4_1_LandsInItsMonth: a [Shift] with no days to add that answers a date
\* answers a date in the landing month: January 31 plus one month is in
\* February, never March 3 (Invariant 4.1).
Inv4_1_LandsInItsMonth ==
    (part = "shift" /\ call # NoCall /\ call.days = 0 /\ answer.r = "date")
        => <<answer.y, answer.m>> = LandingMonth(call)

\* Op24_NoSuchDay: a [Shift] under reject whose date's day exceeds the landing
\* month's length answers no-such-day, or a refusal the refuses line lists
\* before it (Execution Contract Refusal 1), never a date (Operation 24).
Op24_NoSuchDay ==
    (/\ part = "shift" /\ call # NoCall
     /\ call.overflow = "reject"
     /\ call.d > MonthLength(LandingMonth(call)[1], LandingMonth(call)[2]))
        => answer.r \in {"invalid-date", "out-of-range", "invalid-amount",
                         "invalid-overflow", "no-such-day"}

====
