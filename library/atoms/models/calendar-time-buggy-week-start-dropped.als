-- calendar-time-buggy-week-start-dropped.als
-- DELIBERATELY WRONG twin of calendar-time.als (unit: `atoms/calendar-time.md formal layer`).
--
-- INJECTED DEFECT: [Change] writes only the fields that differ from the version it found and leaves the
-- others blank: a call that moves the place to a new time zone and keeps its week start
-- records no week start (Operation 6 writes both).
--
-- BREAKS: A_State_1.
-- Everything else is calendar-time.als as written; read its comments there.

module calendar_time_buggy_week_start_dropped

open util/ordering[Call] as C

-- ─────────────────────────────────────────────────────────────────────────────
-- Signatures (types)
-- ─────────────────────────────────────────────────────────────────────────────

-- TimeZone: a string a call carries as its time zone, such as America/Chicago, the link
-- US/Central, or america/chicago, which no zone name matches (Term time zone). The atom
-- compares it codepoint for codepoint, so two different strings are two different atoms.
sig TimeZone {}

-- Rules: the deployment's time zone rules as the state reads them (Term time zone rules,
-- Capability requirement 2). zoneNames are every name the rules carry, a zone's own name
-- or a link (Term zone names); linkTo takes a link to the zone it names.
one sig Rules {
    zoneNames : set TimeZone,
    linkTo    : TimeZone -> lone TimeZone
}

-- WeekWord: a word a call carries as its week start: a day of the week (Term day of the
-- week, monday through sunday) or a word that is none, such as "someday".
abstract sig WeekWord {}

-- Day: a day of the week. Which day it is matters to a reading, not to a record's shape,
-- so the days are not told apart here.
sig Day extends WeekWord {}

-- NotADay: a word a call may carry that is not a day of the week.
sig NotADay extends WeekWord {}

-- PlaceId: an opaque place id (Term place id). It means nothing by itself.
sig PlaceId {}

-- Call: one call of a zone action ([Open] or [Change], Term zone action), with the time
-- zone and the week start it carries. Calls happen in one order, the order Execution
-- Contract Order 1 gives every commit.
abstract sig Call {
    zoneIn : one TimeZone,  -- time_zone
    weekIn : one WeekWord   -- week_start
}

-- OpenCall: one [Open] call, open(time_zone, week_start). The seam supplies it a place id
-- (Capability requirement 1); the action allocates none.
sig OpenCall extends Call {
    seamId : one PlaceId
}

-- ChangeCall: one [Change] call, change(place_id, time_zone, week_start). The place it
-- names is the version it finds (see `written`).
sig ChangeCall extends Call {}

-- Place: one version of a place record (Term records), as the call that wrote it left it.
-- Every field the page names is here and every one may be absent, so a write that forgot
-- one would show; what the page promises (State 1) is checked, never built into the type.
-- The last two fields are the model's own: which call wrote this version and which version
-- that call found; the page has no such fields.
sig Place {
    placeId   : lone PlaceId,   -- place id (Identity 1)
    timeZone  : lone TimeZone,  -- time zone
    weekStart : lone WeekWord,  -- week start
    writtenBy : one Call,       -- the call whose write left this version
    found     : lone Place      -- the version of this place a [Change] found
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Facts: what the page takes from outside
-- ─────────────────────────────────────────────────────────────────────────────

-- The time zone rules as given: a link is a zone name, and it names a zone the rules
-- carry that is not itself a link (the IANA Time Zone Database's shape, which the
-- deployment supplies, Capability requirement 2).
fact RulesLinkToZones {
    all z : TimeZone | some z.(Rules.linkTo) implies {
        z in Rules.zoneNames
        z.(Rules.linkTo) in Rules.zoneNames
        no z.(Rules.linkTo).(Rules.linkTo)
    }
}

-- The seam supplies each [Open] a place id no place has carried (Capability requirement 1,
-- Execution Contract Logic confinement 3): two [Open] calls never get one id. This is
-- where Identity 2 comes from.
fact SeamSuppliesAFreshId {
    all disj a, b : OpenCall | a.seamId != b.seamId
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Helpers
-- ─────────────────────────────────────────────────────────────────────────────

-- zoneGuards: the two checks a zone action makes before it writes: the time zone is among
-- the zone names, compared codepoint for codepoint (Operation 1, Identity 4), and the week
-- start is a day of the week (Operation 2).
pred zoneGuards[c : Call] {
    c.zoneIn in Rules.zoneNames                    -- Operation 1
    c.weekIn in Day                                -- Operation 2
}

-- origin: the [Open] that recorded the place this version belongs to — the writer of the
-- first version along the chain of versions found.
fun origin[s : Place] : set Call {
    { v : s.*found | no v.found }.writtenBy
}

-- ─────────────────────────────────────────────────────────────────────────────
-- The writing actions: their guards and their writes
-- ─────────────────────────────────────────────────────────────────────────────

-- openWrites: the place an admitted [Open] records: the place id the seam supplies, and
-- the time zone and the week start of the call (Operation 3).
pred openWrites[c : OpenCall, s : Place] {
    zoneGuards[c]
    s.placeId   = c.seamId                         -- Operation 3, Identity 1
    s.timeZone  = c.zoneIn                         -- Operation 3, Identity 3
    s.weekStart = c.weekIn                         -- Operation 3
}

-- changeWrites: the version an admitted [Change] records over the version it found: the
-- call's time zone and week start, where either differs from the place's (Operation 6);
-- where both are equal [Change] writes nothing (Operation 7), so no version follows. A
-- call writes only the fields its own rules name, so the place id stays as found.
pred changeWrites[pre : Place, c : ChangeCall, s : Place] {
    zoneGuards[c]
    c.zoneIn != pre.timeZone or c.weekIn != pre.weekStart   -- Operation 6, Operation 7
    s.placeId   = pre.placeId
    s.timeZone  = c.zoneIn                         -- Operation 6, Identity 3
    c.weekIn = pre.weekStart implies no s.weekStart else s.weekStart = c.weekIn  -- BUG: only what changed is written
}

-- written: the version is what its call's write left, over a version an earlier call wrote
-- (a call finds only what was committed before it, Execution Contract Database 2).
pred written[v : Place] {
    let c = v.writtenBy {
        (c in OpenCall and no v.found and openWrites[c, v])
        or (c in ChangeCall and some v.found
            and C/lt[v.found.writtenBy, c] and changeWrites[v.found, c, v])
    }
}

-- recorded: a version the page lets the records hold (see SCOPE): it and every version it
-- was built from are what an admitted call wrote.
pred recorded[s : Place] {
    all v : s.*found | written[v]
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Assertions (verified guarantees)
-- Each "check" asks: is there any record the page's calls can leave that violates this
-- assertion? No counterexample (UNSAT) = the guarantee holds within scope.
-- ─────────────────────────────────────────────────────────────────────────────

-- A_State_1: every place carries its place id, its time zone and its week start, however
-- it was opened and however often it was changed (State 1, Check 1.1).
assert A_State_1 {
    all s : Place | recorded[s] implies {
        some s.placeId
        some s.timeZone
        some s.weekStart
    }
}
check A_State_1 for 4 but 4 Place, 3 Call

-- A_Invariant_1_1: every place's time zone names a zone of the time zone rules, a zone's
-- own name or a link, so every answer about the place can read the zone's offsets
-- (Invariant 1.1, Check 2.2).
assert A_Invariant_1_1 {
    all s : Place | recorded[s] implies s.timeZone in Rules.zoneNames
}
check A_Invariant_1_1 for 4 but 4 Place, 3 Call

-- A_Invariant_1_2: every place carries a day of the week as its week start, so its weeks
-- start somewhere (Invariant 1.2, Check 2.3).
assert A_Invariant_1_2 {
    all s : Place | recorded[s] implies s.weekStart in Day
}
check A_Invariant_1_2 for 4 but 4 Place, 3 Call

-- A_Identity_2: no two places share a place id. Two versions that two different [Open]
-- calls began are two places, and they never carry one id, so a place id names one place
-- and all its versions (Identity 2, Check 2.1).
assert A_Identity_2 {
    all s1, s2 : Place | (recorded[s1] and recorded[s2] and origin[s1] != origin[s2])
        implies s1.placeId != s2.placeId
}
check A_Identity_2 for 4 but 4 Place, 3 Call

-- A_Identity_3: a place carries its time zone exactly as the call that wrote it carried
-- it: a link stays the link, never replaced by the zone it names, and no string is
-- rewritten into another (Identity 3, Term time zone).
assert A_Identity_3 {
    all s : Place | recorded[s] implies s.timeZone = s.writtenBy.zoneIn
}
check A_Identity_3 for 4 but 4 Place, 3 Call

-- ─────────────────────────────────────────────────────────────────────────────
-- Satisfiability runs — non-vacuity guards, one for each shape the page admits
-- Each run must find at least one instance (SAT).
-- UNSAT means the model forbids a record the page admits.
-- ─────────────────────────────────────────────────────────────────────────────

-- ShowOpened: a place just opened, as `open("America/Chicago", sunday)` opens p1.
run ShowOpened {
    some s : Place | recorded[s] and s.writtenBy in OpenCall
} for 4 but 4 Place, 3 Call

-- ShowMoved: a place [Change] gave a new time zone, as when a person moves (the Edge case
-- "A place that moves").
run ShowMoved {
    some s : Place | recorded[s] and s.writtenBy in ChangeCall
        and s.timeZone != s.found.timeZone
} for 4 but 4 Place, 3 Call

-- ShowNewWeekStart: a place [Change] gave only a new week start, its time zone kept.
run ShowNewWeekStart {
    some s : Place | recorded[s] and s.writtenBy in ChangeCall
        and s.timeZone = s.found.timeZone and s.weekStart != s.found.weekStart
} for 4 but 4 Place, 3 Call

-- ShowLinkKept: a place opened on a link, such as US/Central, which it carries as the
-- call carried it (Term time zone: "such as America/Chicago or the link US/Central").
run ShowLinkKept {
    some s : Place | recorded[s] and some s.timeZone.(Rules.linkTo)
} for 4 but 4 Place, 3 Call

-- ShowTwoPlacesOneZone: two places on one time zone with two place ids, as two readers in
-- one city each keep a place of their own.
run ShowTwoPlacesOneZone {
    some s1, s2 : Place | recorded[s1] and recorded[s2] and origin[s1] != origin[s2]
        and s1.timeZone = s2.timeZone
} for 4 but 4 Place, 3 Call

-- ShowMovedBack: a place changed and then changed back to the time zone it was opened on:
-- each [Change] compares with the version it found, not with the first one.
run ShowMovedBack {
    some s : Place | recorded[s] and s.writtenBy in ChangeCall
        and s.found.writtenBy in ChangeCall
        and s.timeZone = s.found.found.timeZone and s.timeZone != s.found.timeZone
} for 4 but 4 Place, 3 Call
