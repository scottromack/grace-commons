-- condition-register-buggy-close-keeps-open.als
-- DELIBERATELY WRONG twin of condition-register.als (unit: `atoms/condition-register.md formal layer`).
-- INJECTED DEFECT: [Report Clear] adds closed to the record's status and never clears open, as a
-- status kept as a set of flags would (Operation 19 written as an add).
--
-- BREAKS: A_State_3.
-- Everything else is condition-register.als as written; read its comments there.

module condition_register_buggy_close_keeps_open

open util/ordering[Call] as C
open util/ordering[Instant] as T

-- ─────────────────────────────────────────────────────────────────────────────
-- Signatures (types)
-- ─────────────────────────────────────────────────────────────────────────────

-- Text: a string a call carries as a subject, a scope or a run id. The atom compares a
-- string byte-exactly and never trims, normalizes or case-folds it (String 1 to 4), so two
-- different strings are two different atoms.
abstract sig Text {}

-- Empty: the empty string.
one sig Empty extends Text {}

-- Spaces: a string of whitespace only, which the atom reads as blank (String 5).
sig Spaces extends Text {}

-- Word: a string with a character that is not whitespace, such as "payment" or "run_7101".
sig Word extends Text {}

-- Condition: a condition name a composing pattern declares, or one nobody declared, such as
-- "disk-full" (Term condition).
sig Condition {}

-- Declared: the deployment's declared conditions (Term declared conditions), each with its
-- shape: those recorded once per subject, as sightings, and those recorded as spans, as
-- standing records (Capability requirement 3, Term shape).
one sig Declared {
    sightingConditions : set Condition,
    standingConditions : set Condition
}

-- Instant: a clock reading. Instants are ordered; which calls carry which instants is free.
sig Instant {}

-- RecordId: an opaque record id the host allocates (Term record id).
sig RecordId {}

-- Status: a standing record's status, open or closed (Term status).
abstract sig Status {}

-- Open: the status of a standing record whose condition the last run still saw.
one sig Open extends Status {}

-- Closed: the status of a standing record a run found clear.
one sig Closed extends Status {}

-- Call: one admitted call of a writing action (Term writing action), with the condition and
-- the run id it carries and the clock reading the host injects at the seam (Term now; Clock
-- dependence 2: no caller supplies an instant). Calls commit in one order (Execution
-- Contract Order 1), the order util/ordering gives them.
abstract sig Call {
    conditionIn : one Condition,  -- condition
    runIn       : one Text,       -- run_id
    now         : one Instant     -- the injected clock reading
}

-- SightCall: one [Record Sighting] call, record_sighting(condition, subject, run_id).
sig SightCall extends Call {
    subjectIn : one Text          -- subject
}

-- ScopeCall: a call that names a scope: [Report Standing] or [Report Clear]. A scope the
-- call leaves out is the empty string (Term scope: blank).
abstract sig ScopeCall extends Call {
    scopeIn : one Text            -- optional scope
}

-- StandCall: one [Report Standing] call, report_standing(condition, scope, run_id), with
-- the record id the host allocates at the seam (Term seam). The page has the host inject it
-- for "a call that opens a standing record", which the host cannot know before the
-- transition reads the records, so here every [Report Standing] call carries one, used only
-- where the call opens.
sig StandCall extends ScopeCall {
    seamId : one RecordId
}

-- ClearCall: one [Report Clear] call, report_clear(condition, scope, run_id).
sig ClearCall extends ScopeCall {}

-- Sighting: one sighting (Term records), as the call that wrote it left it. Every field the
-- page names may be absent here, so a write that forgot one would show; what the page
-- promises (State 1) is checked, never built into the type. writtenBy is the model's own:
-- the call whose write left the sighting.
sig Sighting {
    condition : lone Condition,   -- condition
    subject   : lone Text,        -- subject
    runId     : lone Text,        -- run id
    seenAt    : lone Instant,     -- seen instant
    writtenBy : one Call
}

-- Standing: one version of a standing record (Term records), as the call that wrote it left
-- it. A write that changes a standing record leaves a new version in place of the old one.
-- Every field may be absent and status may hold both values or none, so a write that broke
-- State 2 to 5 or 8 would show. writtenBy is the model's own.
sig Standing {
    recordId   : lone RecordId,   -- record id
    condition  : lone Condition,  -- condition
    scope      : lone Text,       -- scope
    firstRun   : lone Text,       -- first run id
    firstSeen  : lone Instant,    -- first seen
    lastRun    : lone Text,       -- last run id
    lastSeen   : lone Instant,    -- last seen
    status     : set Status,      -- status
    closingRun : lone Text,       -- closing run id
    closedAt   : lone Instant,    -- closing instant
    writtenBy  : one Call
}

-- DB: one state of the database: the sightings and the standing record versions it holds.
-- found and madeBy are the model's own: the database the last call found, and that call.
sig DB {
    sightings : set Sighting,
    standings : set Standing,
    found     : lone DB,
    madeBy    : lone Call
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Facts: what the page takes from outside
-- ─────────────────────────────────────────────────────────────────────────────

-- The deployment declares each condition with one shape (Capability requirement 3), and
-- keeps the declaration while a record of the condition stands (Capability requirement 8,
-- 9), so one set of declarations holds for every database here.
fact EachConditionHasOneShape {
    no Declared.sightingConditions & Declared.standingConditions
}

-- The host supplies each [Report Standing] call a record id of its own: no two calls get one
-- id (Identity 3: an id no standing record carries; Execution Contract Logic confinement 16:
-- an id the host allocates is supplied to one call). This is where Identity 4 comes from.
fact SeamSuppliesAFreshRecordId {
    all disj a, b : StandCall | a.seamId != b.seamId
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Helpers
-- ─────────────────────────────────────────────────────────────────────────────

-- blank: the strings the atom reads as blank: the empty string and every whitespace-only
-- string (String 5).
fun blank : set Text { Empty + Spaces }

-- asRecorded: the scope a [Report Standing] or [Report Clear] call names, as the atom reads
-- and records it: blank where the call's scope is blank (Operation 41, String 6), else the
-- scope the call supplies (Operation 40).
fun asRecorded[t : Text] : Text { t in blank implies Empty else t }

-- sameScope: two stored scopes are one scope where they are equal or both blank (String 6:
-- every blank scope is one scope).
pred sameScope[a, b : Text] { a = b or (a + b) in blank }

-- isOpen, isClosed: a standing record version that stands in open, or in closed, alone.
pred isOpen[r : Standing] { r.status = Open }
pred isClosed[r : Standing] { r.status = Closed }

-- openFor: the open standing records of the database for the call's condition and scope
-- (the "open standing record ... for the condition and the scope" of Operation 12 to 24).
fun openFor[db : DB, c : ScopeCall] : set Standing {
    { r : db.standings | isOpen[r] and r.condition = c.conditionIn
                         and r.scope = asRecorded[c.scopeIn] }
}

-- standingGuards: what [Report Standing] and [Report Clear] check before they write: a
-- declared condition of the standing shape (Operation 1, 8, 9) and a run id that is not
-- blank (Operation 10, 11).
pred standingGuards[c : ScopeCall] {
    c.conditionIn in Declared.standingConditions   -- Operation 1, 8, 9
    c.runIn not in blank                           -- Operation 10, 11
}

-- ─────────────────────────────────────────────────────────────────────────────
-- The writing actions: their guards and their writes
-- ─────────────────────────────────────────────────────────────────────────────

-- recordSighting: an admitted [Record Sighting]: a declared condition of the sighting shape
-- (Operation 1, 2), subject and run id not blank (Operation 3), no sighting yet for the
-- condition and the subject (Operation 4; the database's refusal, Invariant 2.2). It records
-- exactly one sighting (Operation 5) carrying the call's condition, subject and run id
-- (Operation 38), stamped from the injected now (Operation 6).
pred recordSighting[pre : DB, c : SightCall, post : DB] {
    c.conditionIn in Declared.sightingConditions                -- Operation 1, 2
    c.subjectIn not in blank and c.runIn not in blank           -- Operation 3
    no s : pre.sightings | s.condition = c.conditionIn and s.subject = c.subjectIn
                                                                -- Operation 4, Invariant 2.2
    some s : Sighting - pre.sightings {
        post.sightings = pre.sightings + s                      -- Operation 5
        s.condition = c.conditionIn                             -- Operation 38
        s.subject   = c.subjectIn                               -- Operation 38
        s.runId     = c.runIn                                   -- Operation 38
        s.seenAt    = c.now                                     -- Operation 6
        s.writtenBy = c
    }
    post.standings = pre.standings
}

-- opens: an admitted [Report Standing] where no standing record stands open for the
-- condition and the scope (Operation 15; the database's refusal of a second open record,
-- Invariant 3.2). It records exactly one standing record in open, carrying the call's
-- condition and the record id the host allocated (Operation 39), the scope the call supplies
-- or blank (Operation 40, 41), the run id as first and last run id (Operation 16), and first
-- and last seen stamped from the injected now (Operation 17). A new record carries no
-- closing run id and no closing instant: nothing has closed it.
pred opens[pre : DB, c : StandCall, post : DB] {
    standingGuards[c]
    no openFor[pre, c]                                          -- Operation 15, Invariant 3.2
    some r : Standing - pre.standings {
        post.standings = pre.standings + r                      -- Operation 15
        r.recordId   = c.seamId                                 -- Operation 39
        r.condition  = c.conditionIn                            -- Operation 39
        r.scope      = asRecorded[c.scopeIn]                    -- Operation 40, 41
        r.firstRun   = c.runIn                                  -- Operation 16
        r.lastRun    = c.runIn                                  -- Operation 16
        r.firstSeen  = c.now                                    -- Operation 17
        r.lastSeen   = c.now                                    -- Operation 17
        r.status     = Open                                     -- Operation 15
        no r.closingRun
        no r.closedAt
        r.writtenBy  = c
    }
    post.sightings = pre.sightings
}

-- advances: an admitted [Report Standing] where a standing record stands open for the
-- condition and the scope. The database refuses a write whose last seen precedes the
-- record's first seen or its stored last seen (Invariant 4.1, 4.3), so a call whose clock
-- reads earlier answers storage-failure and writes nothing. Otherwise the record's last run
-- id becomes the run id (Operation 12) and its last seen the injected now (Operation 13),
-- and it stays open; every other field stays as it was (Invariant 1.2).
pred advances[pre : DB, c : StandCall, post : DB] {
    standingGuards[c]
    some r : openFor[pre, c] {
        not T/lt[c.now, r.firstSeen]                            -- Invariant 4.1
        not T/lt[c.now, r.lastSeen]                             -- Invariant 4.3
        some r2 : Standing - pre.standings {
            post.standings = pre.standings - r + r2
            r2.recordId   = r.recordId
            r2.condition  = r.condition
            r2.scope      = r.scope
            r2.firstRun   = r.firstRun
            r2.firstSeen  = r.firstSeen
            r2.lastRun    = c.runIn                             -- Operation 12
            r2.lastSeen   = c.now                               -- Operation 13
            r2.status     = Open                                -- Operation 12 to 14: it stays open
            r2.closingRun = r.closingRun
            r2.closedAt   = r.closedAt
            r2.writtenBy  = c
        }
    }
    post.sightings = pre.sightings
}

-- closes: an admitted [Report Clear] where a standing record stands open for the condition
-- and the scope. The database refuses a write whose closing instant precedes the record's
-- last seen (Invariant 4.2). Otherwise the record stands in closed (Operation 19) with the
-- run id as its closing run id (Operation 20) and its closing instant stamped from the
-- injected now (Operation 21); last seen, and every other field, stays as it was
-- (Operation 22). Where nothing is open the call answers none-open and writes nothing
-- (Operation 24), so it is no write here.
pred closes[pre : DB, c : ClearCall, post : DB] {
    standingGuards[c]
    some r : openFor[pre, c] {
        not T/lt[c.now, r.lastSeen]                             -- Invariant 4.2
        some r2 : Standing - pre.standings {
            post.standings = pre.standings - r + r2
            r2.recordId   = r.recordId
            r2.condition  = r.condition
            r2.scope      = r.scope
            r2.firstRun   = r.firstRun
            r2.firstSeen  = r.firstSeen
            r2.lastRun    = r.lastRun
            r2.lastSeen   = r.lastSeen                          -- Operation 22
            r2.status     = r.status + Closed                   -- BUG: open never cleared
            r2.closingRun = c.runIn                             -- Operation 20
            r2.closedAt   = c.now                               -- Operation 21
            r2.writtenBy  = c
        }
    }
    post.sightings = pre.sightings
}

-- step: the write one admitted call makes over the database it found.
pred step[pre : DB, c : Call, post : DB] {
    (c in SightCall and recordSighting[pre, c, post])
    or (c in StandCall and (opens[pre, c, post] or advances[pre, c, post]))
    or (c in ClearCall and closes[pre, c, post])
}

-- written: the database is empty, or it is what its call wrote over the database that call
-- found, which an earlier call made (a call reads what was committed before it, Execution
-- Contract Database 2), so no call writes twice into one run.
pred written[d : DB] {
    (no d.found and no d.madeBy and no d.sightings and no d.standings)
    or (some d.found and some d.madeBy
        and (no d.found.madeBy or C/lt[d.found.madeBy, d.madeBy])
        and step[d.found, d.madeBy, d])
}

-- recorded: a database the page lets the atom hold (see SCOPE): it and every database it was
-- built from are what admitted calls wrote, back to the empty one.
pred recorded[db : DB] {
    all d : db.*found | written[d]
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Assertions (verified guarantees)
-- Each "check" asks: is there any database the page's calls can leave that violates this
-- assertion? No counterexample (UNSAT) = the guarantee holds within scope.
-- ─────────────────────────────────────────────────────────────────────────────

-- A_State_1: every sighting carries its condition, its subject, its run id and its seen
-- instant (State 1, Check 1.1).
assert A_State_1 {
    all db : DB | recorded[db] implies all s : db.sightings |
        some s.condition and some s.subject and some s.runId and some s.seenAt
}
check A_State_1 for 4 but 4 DB, 3 Call, 3 Sighting, 4 Standing, 3 Instant

-- A_State_2: every standing record carries its record id, condition, scope (blank is a
-- scope), first run id, first seen, last run id, last seen and status, however it was
-- opened, advanced or closed (State 2, Check 1.2).
assert A_State_2 {
    all db : DB | recorded[db] implies all r : db.standings |
        some r.recordId and some r.condition and some r.scope
        and some r.firstRun and some r.firstSeen
        and some r.lastRun and some r.lastSeen and some r.status
}
check A_State_2 for 4 but 4 DB, 3 Call, 3 Sighting, 4 Standing, 3 Instant

-- A_State_3: every standing record stands in exactly one of open and closed (State 3).
assert A_State_3 {
    all db : DB | recorded[db] implies all r : db.standings | one r.status
}
check A_State_3 for 4 but 4 DB, 3 Call, 3 Sighting, 4 Standing, 3 Instant

-- A_State_4: a closed standing record carries the run id that closed it and the instant it
-- closed (State 4).
assert A_State_4 {
    all db : DB | recorded[db] implies all r : db.standings |
        isClosed[r] implies (some r.closingRun and some r.closedAt)
}
check A_State_4 for 4 but 4 DB, 3 Call, 3 Sighting, 4 Standing, 3 Instant

-- A_State_5: an open standing record carries no closing run id: nothing has closed it
-- (State 5).
assert A_State_5 {
    all db : DB | recorded[db] implies all r : db.standings |
        isOpen[r] implies no r.closingRun
}
check A_State_5 for 4 but 4 DB, 3 Call, 3 Sighting, 4 Standing, 3 Instant

-- A_State_8: an open standing record carries no closing instant (State 8).
assert A_State_8 {
    all db : DB | recorded[db] implies all r : db.standings |
        isOpen[r] implies no r.closedAt
}
check A_State_8 for 4 but 4 DB, 3 Call, 3 Sighting, 4 Standing, 3 Instant

-- A_Invariant_2_1: no two sightings share a condition and a subject: a sighting stands once
-- however many runs find it (Invariant 2.1, Check 2.1; Identity 1 names a sighting by them).
assert A_Invariant_2_1 {
    all db : DB | recorded[db] implies all disj s1, s2 : db.sightings |
        not (s1.condition = s2.condition and s1.subject = s2.subject)
}
check A_Invariant_2_1 for 4 but 4 DB, 3 Call, 3 Sighting, 4 Standing, 3 Instant

-- A_Invariant_3_1: no two open standing records share a condition and a scope, every blank
-- scope read as one scope (String 6): an outage is one record while it lasts (Invariant 3.1,
-- Check 3.1).
assert A_Invariant_3_1 {
    all db : DB | recorded[db] implies all disj r1, r2 : db.standings |
        (isOpen[r1] and isOpen[r2] and r1.condition = r2.condition)
            implies not sameScope[r1.scope, r2.scope]
}
check A_Invariant_3_1 for 4 but 4 DB, 3 Call, 3 Sighting, 4 Standing, 3 Instant

-- A_Invariant_4_1: no standing record's last seen precedes its first seen: a span runs
-- forward (Invariant 4.1, Check 4.1).
assert A_Invariant_4_1 {
    all db : DB | recorded[db] implies all r : db.standings |
        not T/lt[r.lastSeen, r.firstSeen]
}
check A_Invariant_4_1 for 4 but 4 DB, 3 Call, 3 Sighting, 4 Standing, 3 Instant

-- A_Invariant_4_2: no closed standing record's closing instant precedes its last seen: the
-- record closes after the last run that saw the condition (Invariant 4.2, Check 4.4).
assert A_Invariant_4_2 {
    all db : DB | recorded[db] implies all r : db.standings |
        isClosed[r] implies not T/lt[r.closedAt, r.lastSeen]
}
check A_Invariant_4_2 for 4 but 4 DB, 3 Call, 3 Sighting, 4 Standing, 3 Instant

-- A_Invariant_5_1: every sighting's run id stands non-blank: it names the run that saw it
-- (Invariant 5.1, Check 5.2).
assert A_Invariant_5_1 {
    all db : DB | recorded[db] implies all s : db.sightings | no (s.runId & blank)
}
check A_Invariant_5_1 for 4 but 4 DB, 3 Call, 3 Sighting, 4 Standing, 3 Instant

-- A_Invariant_5_2: every standing record's first run id and last run id stand non-blank
-- (Invariant 5.2, Check 5.2).
assert A_Invariant_5_2 {
    all db : DB | recorded[db] implies all r : db.standings |
        no (r.firstRun & blank) and no (r.lastRun & blank)
}
check A_Invariant_5_2 for 4 but 4 DB, 3 Call, 3 Sighting, 4 Standing, 3 Instant

-- A_Identity_4: no two standing records share a record id, so a record id names one record
-- and, with no record removed (State 7), is never reused (Identity 2, Identity 4).
assert A_Identity_4 {
    all db : DB | recorded[db] implies all disj r1, r2 : db.standings |
        no (r1.recordId & r2.recordId)
}
check A_Identity_4 for 4 but 4 DB, 3 Call, 3 Sighting, 4 Standing, 3 Instant

-- A_OneShape: every sighting is of a declared sighting condition and every standing record
-- of a declared standing condition, so a condition's records are of its shape alone (Term
-- matching record; Operation 1, 2, 8, 9).
assert A_OneShape {
    all db : DB | recorded[db] implies {
        db.sightings.condition in Declared.sightingConditions
        db.standings.condition in Declared.standingConditions
    }
}
check A_OneShape for 4 but 4 DB, 3 Call, 3 Sighting, 4 Standing, 3 Instant

-- ─────────────────────────────────────────────────────────────────────────────
-- Satisfiability runs — non-vacuity guards, one for each shape the page admits
-- Each run must find at least one instance (SAT).
-- UNSAT means the model forbids a database the page admits.
-- ─────────────────────────────────────────────────────────────────────────────

-- ShowSighting: a sighting recorded, as record_sighting("escalated", "act_88e1", "run_7102")
-- records one (Examples, A sighting).
run ShowSighting {
    some db : DB | recorded[db] and some db.sightings
} for 4 but 4 DB, 3 Call, 3 Sighting, 4 Standing, 3 Instant

-- ShowTwoSubjects: two sightings of one condition about two subjects.
run ShowTwoSubjects {
    some db : DB | recorded[db] and some disj s1, s2 : db.sightings |
        s1.condition = s2.condition and s1.subject != s2.subject
} for 4 but 4 DB, 3 Call, 3 Sighting, 4 Standing, 3 Instant

-- ShowOpened: a standing record just opened, its first and last seen one instant.
run ShowOpened {
    some db : DB, r : db.standings | recorded[db] and isOpen[r] and r.lastSeen = r.firstSeen
} for 4 but 4 DB, 3 Call, 3 Sighting, 4 Standing, 3 Instant

-- ShowAdvanced: an open record a later run advanced: last seen after first seen, and the
-- last run another run (the outage at 02:15 and 02:30 in Examples, An outage).
run ShowAdvanced {
    some db : DB, r : db.standings | recorded[db] and isOpen[r]
        and T/lt[r.firstSeen, r.lastSeen] and r.lastRun != r.firstRun
} for 4 but 4 DB, 3 Call, 3 Sighting, 4 Standing, 3 Instant

-- ShowClosed: a closed standing record, its closing instant after its last seen (the span
-- 02:00 to 02:30, closed 02:45).
run ShowClosed {
    some db : DB, r : db.standings | recorded[db] and isClosed[r]
        and T/lt[r.lastSeen, r.closedAt]
} for 4 but 4 DB, 3 Call, 3 Sighting, 4 Standing, 3 Instant

-- ShowRecurrence: a closed record and an open one for the same condition and scope: a
-- recurrence opens a new record with its own span (Summary; Examples, the next week).
run ShowRecurrence {
    some db : DB, r1, r2 : db.standings | recorded[db] and isClosed[r1] and isOpen[r2]
        and r1.condition = r2.condition and r1.scope = r2.scope
} for 4 but 4 DB, 3 Call, 3 Sighting, 4 Standing, 3 Instant

-- ShowTwoScopes: two open records of one condition in two scopes, as one outage per
-- dependency (Decisions, 2026-11-02).
run ShowTwoScopes {
    some db : DB, r1, r2 : db.standings | recorded[db] and isOpen[r1] and isOpen[r2]
        and r1.condition = r2.condition and r1.scope != r2.scope
} for 4 but 4 DB, 3 Call, 3 Sighting, 4 Standing, 3 Instant

-- ShowBlankScope: a record a call named with a whitespace-only scope, recorded as blank
-- (Operation 41, String 5).
run ShowBlankScope {
    some db : DB, r : db.standings | recorded[db] and r.writtenBy.scopeIn in Spaces
        and r.scope = Empty
} for 4 but 4 DB, 3 Call, 3 Sighting, 4 Standing, 3 Instant

-- ShowBothShapes: one database holding a sighting and a standing record.
run ShowBothShapes {
    some db : DB | recorded[db] and some db.sightings and some db.standings
} for 4 but 4 DB, 3 Call, 3 Sighting, 4 Standing, 3 Instant
