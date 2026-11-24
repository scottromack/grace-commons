-- communication-buggy-record-normalizes-item.als
-- DELIBERATELY WRONG twin of communication.als (unit: `atoms/communication.md formal layer`).
--
-- INJECTED DEFECT: [Record] folds the case of each item reference before recording it
-- (Identity 8).
--
-- BREAKS: A_Operation_19.
-- Everything else is communication.als as written; read its comments there.

module communication_buggy_record_normalizes_item

open util/ordering[Call] as C
open util/ordering[Instant] as T

-- ─────────────────────────────────────────────────────────────────────────────
-- Signatures (types)
-- ─────────────────────────────────────────────────────────────────────────────

-- CommId: an opaque value naming one communication, which the host allocates at the seam
-- (Term communication id).
sig CommId {}

-- Medium: a string a call carries as how an exchange happened, such as phone or Phone,
-- compared codepoint for codepoint (Term medium, Identity 11).
sig Medium {}

-- Outcome: a string a call carries as how an exchange went, such as connected (Term outcome,
-- Identity 13).
sig Outcome {}

-- PersonRef: a string naming one person who took part, such as jane-ruiz or Jane-Ruiz, in
-- the deployment's own scheme (Term person reference, Identity 7).
sig PersonRef {}

-- ItemRef: a string naming one item an exchange was about, such as acme-supply (Term item
-- reference, Identity 9).
sig ItemRef {}

-- Summary: a short account of an exchange in words (Term summary).
sig Summary {}

-- Instant: a point in time, as an occurred instant or as the now the host injects at the seam
-- (Capability requirement 2). Instants are ordered, earliest first (the module T).
sig Instant {}

-- Direction: which way an exchange went (Term direction).
abstract sig Direction {}

-- Inbound, Outbound: the two directions.
one sig Inbound, Outbound extends Direction {}

-- Status: where a communication stands (Term status).
abstract sig Status {}

-- Active, Withdrawn: the two statuses.
one sig Active, Withdrawn extends Status {}

-- PersonList: one list of person references a version carries, read as the set of its
-- members; a version may carry none, so a write that left a list off would show.
sig PersonList {
    pm : set PersonRef
}

-- ItemList: one list of item references a version carries, read the same way.
sig ItemList {
    im : set ItemRef
}

-- Normalizer: what a normalizer that folds case would rewrite a value to, where the result
-- differs (jane-ruiz for Jane-Ruiz, phone for Phone). The page forbids it (Identity 6, 8,
-- 10, 12): the model's own actions never apply it. It is here so a run can show two values
-- one normalizer would merge, and so a twin can apply it.
one sig Normalizer {
    foldPerson  : PersonRef -> lone PersonRef,
    foldItem    : ItemRef -> lone ItemRef,
    foldMedium  : Medium -> lone Medium,
    foldOutcome : Outcome -> lone Outcome
}

-- Call: one call of a writing action, with the now the seam gives it and the medium set and
-- outcome set the deployment read at its last start (Capability requirement 8, 9). Calls
-- happen in one order, the order Execution Contract Order 1 gives every commit.
abstract sig Call {
    now        : one Instant,
    mediumSet  : set Medium,
    outcomeSet : set Outcome
}

-- RecordCall: one [Record] call, record(medium, occurred_instant, outside_participants, ...),
-- with the communication id the host allocates for it (Identity 2, Capability requirement
-- 12). A list or an optional detail the call leaves blank or omits is an empty set or none
-- here. callerId is a communication id the business caller may send along with the call, a
-- client's own id say; the page's [Record] takes none (Identity 3), and it is here so a twin
-- can take it.
sig RecordCall extends Call {
    rMedium    : one Medium,
    rOccurred  : one Instant,
    rOutside   : set PersonRef,
    rInside    : set PersonRef,
    rDirection : lone Direction,
    rSummary   : lone Summary,
    rItems     : set ItemRef,
    rOutcome   : lone Outcome,
    supplied   : one CommId,
    callerId   : lone CommId
}

-- ChangeCall: one [Change] call, change(communication_id, ...): each detail it leaves blank
-- or omits, an empty list among them, is none or an empty set here (GRACE-lang Earned
-- vocabulary 22).
sig ChangeCall extends Call {
    target     : one CommId,
    cMedium    : lone Medium,
    cOccurred  : lone Instant,
    cOutside   : set PersonRef,
    cInside    : set PersonRef,
    cDirection : lone Direction,
    cSummary   : lone Summary,
    cItems     : set ItemRef,
    cOutcome   : lone Outcome
}

-- WithdrawCall: one [Withdraw] call, withdraw(communication_id).
sig WithdrawCall extends Call {
    withdrawing : one CommId
}

-- Communication: one version of a communication record (Term records, Term version), as the
-- call that wrote it left it. Every field the page names may be absent and the status may
-- hold either member or both, so a write that forgot a field or stood a communication in two
-- statuses would show; what the page promises (State 1, 3) is checked, never built into the
-- type. The last two fields are the model's own: which call wrote this version, and which
-- version a [Change] or [Withdraw] found.
sig Communication {
    cid       : lone CommId,       -- communication id
    medium    : lone Medium,       -- medium
    occurred  : lone Instant,      -- occurred instant
    outside   : lone PersonList,   -- outside participants
    inside    : lone PersonList,   -- inside participants
    direction : lone Direction,    -- direction (State 2: may be absent)
    summary   : lone Summary,      -- summary (State 2: may be absent)
    items     : lone ItemList,     -- item references
    outcome   : lone Outcome,      -- outcome (State 2: may be absent)
    status    : set Status,        -- status
    by        : one Call,
    found     : lone Communication
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Fact: what the page takes from outside (the seam)
-- ─────────────────────────────────────────────────────────────────────────────

-- SeamIds: the host allocates, for each [Record] call, a communication id no communication
-- has carried before the call (Identity 2, Capability requirement 12, Execution Contract
-- Logic confinement 16).
fact SeamIds {
    all c : RecordCall | no g : Communication | C/lt[g.by, c] and g.cid = c.supplied
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Helpers
-- ─────────────────────────────────────────────────────────────────────────────

-- origin: the [Record] call that recorded the communication this version belongs to. Two
-- versions with one origin are one communication; two origins are two communications.
fun origin[g : Communication] : set RecordCall {
    { v : g.*found | no v.found }.by & RecordCall
}

-- currentAt: the version is its communication's latest version when call c runs: written
-- before c, and no later version of the same communication written before c (Execution
-- Contract Database 2).
pred currentAt[v : Communication, c : Call] {
    C/lt[v.by, c]
    no w : Communication | origin[w] = origin[v] and C/lt[v.by, w.by] and C/lt[w.by, c]
}

-- suppliesDetail: the [Change] call supplies at least one detail (Term detail; Operation 28).
pred suppliesDetail[c : ChangeCall] {
    some c.cMedium or some c.cOccurred or some c.cOutside or some c.cInside
        or some c.cDirection or some c.cSummary or some c.cItems or some c.cOutcome
}

-- setsMedium, setsOccurred, setsOutcome: the call that wrote the version set that detail:
-- every [Record] sets each (an outcome it omits is set to none), a [Change] only the details
-- it supplies.
pred setsMedium[u : Communication] { u.by in RecordCall or some u.by.cMedium }
pred setsOccurred[u : Communication] { u.by in RecordCall or some u.by.cOccurred }
pred setsOutcome[u : Communication] { u.by in RecordCall or some u.by.cOutcome }

-- mediumSetter: the version, among this one and its earlier versions, whose call last set
-- the medium: the call that set the detail this version carries (Term medium).
fun mediumSetter[v : Communication] : set Communication {
    { u : v.*found | setsMedium[u] and no w : v.*found | setsMedium[w] and u in w.^found }
}

-- occurredSetter: the same for the occurred instant (Term occurred instant).
fun occurredSetter[v : Communication] : set Communication {
    { u : v.*found | setsOccurred[u] and no w : v.*found | setsOccurred[w] and u in w.^found }
}

-- outcomeSetter: the same for the outcome (Term outcome).
fun outcomeSetter[v : Communication] : set Communication {
    { u : v.*found | setsOutcome[u] and no w : v.*found | setsOutcome[w] and u in w.^found }
}

-- ─────────────────────────────────────────────────────────────────────────────
-- The writing actions: their guards and their writes
-- ─────────────────────────────────────────────────────────────────────────────

-- recordRecords: the communication an admitted [Record] records: the medium in the medium set
-- (Operation 2), the occurred instant no later than now (Operation 3), an outside participant
-- named (Operation 4), any outcome in the outcome set (Operation 10). It carries the id the
-- host allocated (Identity 2, 3), every detail of the call as the call carried it (Operation
-- 19), an empty list for inside participants or item references the call names none of
-- (Operation 21, 22), and stands in active (Operation 20).
pred recordRecords[c : RecordCall, g : Communication] {
    c.rMedium in c.mediumSet                                      -- Operation 2
    T/lte[c.rOccurred, c.now]                                     -- Operation 3
    some c.rOutside                                               -- Operation 4
    c.rOutcome in c.outcomeSet                                    -- Operation 10
    g.cid = c.supplied                                            -- Identity 2, 3
    g.medium = c.rMedium                                          -- Operation 19
    g.occurred = c.rOccurred                                      -- Operation 19
    some g.outside and g.outside.pm = c.rOutside                  -- Operation 19
    some g.inside and g.inside.pm = c.rInside                     -- Operation 19, 21
    g.direction = c.rDirection                                    -- Operation 19
    g.summary = c.rSummary                                        -- Operation 19
    some g.items and g.items.im = c.rItems.(Normalizer.foldItem)
        + (c.rItems - (Normalizer.foldItem).ItemRef)              -- BUG: case folded
    g.outcome = c.rOutcome                                        -- Operation 19
    g.status = Active                                             -- Operation 20
}

-- changeChanges: the version an admitted [Change] records over the active communication it
-- found by the communication id (Operation 24, 25), where the call supplies a detail
-- (Operation 28) and every supplied detail passes its guard (Operation 2, 3, 10): every
-- supplied detail is set (Operation 26), every other detail stands (Operation 27), and the id
-- and status stand.
pred changeChanges[pre : Communication, c : ChangeCall, g : Communication] {
    currentAt[pre, c]
    pre.cid = c.target                                            -- Operation 24
    pre.status = Active                                           -- Operation 25
    suppliesDetail[c]                                             -- Operation 28
    c.cMedium in c.mediumSet                                      -- Operation 2
    all i : c.cOccurred | T/lte[i, c.now]                         -- Operation 3
    c.cOutcome in c.outcomeSet                                    -- Operation 10
    g.cid = pre.cid                                               -- the id stands
    some c.cMedium implies g.medium = c.cMedium else g.medium = pre.medium
    some c.cOccurred implies g.occurred = c.cOccurred else g.occurred = pre.occurred
    some c.cOutside implies (some g.outside and g.outside.pm = c.cOutside)
        else g.outside = pre.outside
    some c.cInside implies (some g.inside and g.inside.pm = c.cInside)
        else g.inside = pre.inside
    some c.cDirection implies g.direction = c.cDirection else g.direction = pre.direction
    some c.cSummary implies g.summary = c.cSummary else g.summary = pre.summary
    some c.cItems implies (some g.items and g.items.im = c.cItems)
        else g.items = pre.items
    some c.cOutcome implies g.outcome = c.cOutcome else g.outcome = pre.outcome
    g.status = pre.status                                         -- the status stands
}

-- withdrawWithdraws: the version an admitted [Withdraw] records over the active
-- communication it found by the communication id (Operation 24, 30): it stands in withdrawn
-- (Operation 31) and carries every detail and the id as they stood (Operation 32).
pred withdrawWithdraws[pre : Communication, c : WithdrawCall, g : Communication] {
    currentAt[pre, c]
    pre.cid = c.withdrawing                                       -- Operation 24
    pre.status = Active                                           -- Operation 30
    g.cid = pre.cid
    g.medium = pre.medium
    g.occurred = pre.occurred
    g.outside = pre.outside
    g.inside = pre.inside
    g.direction = pre.direction
    g.summary = pre.summary
    g.items = pre.items
    g.outcome = pre.outcome                                       -- Operation 32
    g.status = Withdrawn                                          -- Operation 31
}

-- written: the version is what its call's write left: a [Record] writes a first version; a
-- [Change] or a [Withdraw] a version over the one it found.
pred written[g : Communication] {
    let c = g.by {
        (c in RecordCall and no g.found and recordRecords[c, g])
        or (c in ChangeCall and some g.found and changeChanges[g.found, c, g])
        or (c in WithdrawCall and some g.found and withdrawWithdraws[g.found, c, g])
    }
}

-- Scope: every version the state holds is one an admitted call wrote, a call writes one
-- version at most, and no version is found by two later ones (see SCOPE). It is the model's
-- universe, not a rule of the page: each check reads "in any state the calls can leave".
pred Scope {
    all g : Communication | written[g]
    all c : Call | lone { g : Communication | g.by = c }
    all disj s1, s2 : Communication | some s1.found implies s1.found != s2.found
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Assertions (verified guarantees)
-- Each "check" asks: is there any state the page's calls can leave that violates this
-- assertion? No counterexample (UNSAT) = the guarantee holds within scope.
-- ─────────────────────────────────────────────────────────────────────────────

-- A_State_1: every version of every communication carries its communication id, medium,
-- occurred instant, outside participants, inside participants, item references and status,
-- a withdrawn one included (State 1, Check 1.1). An empty list is a list carried.
assert A_State_1 {
    Scope implies all v : Communication | {
        some v.cid
        some v.medium
        some v.occurred
        some v.outside
        some v.inside
        some v.items
        some v.status
    }
}
check A_State_1 for 4

-- A_State_3: every version of every communication stands in exactly one of active, withdrawn
-- (State 3, Check 1.2).
assert A_State_3 {
    Scope implies all v : Communication | one v.status
}
check A_State_3 for 4

-- A_Identity_3: the communication a [Record] recorded carries the communication id the host
-- allocated at the seam, never an id the business caller sent along (Identity 2, 3).
assert A_Identity_3 {
    Scope implies all g : Communication | no g.found implies g.cid = origin[g].supplied
}
check A_Identity_3 for 4

-- A_Identity_4: no two communications share a communication id: a withdrawn communication's
-- id is never given to another (Identity 4, Check 5.1).
assert A_Identity_4 {
    Scope implies all g1, g2 : Communication |
        origin[g1] != origin[g2] implies no (g1.cid & g2.cid)
}
check A_Identity_4 for 4

-- A_Operation_2: every version carries a medium the medium set offered to the call that set
-- it; a medium the deployment has since dropped stays on what it was set on (Operation 2,
-- Term medium, the Edge case "A medium set or an outcome set that changes").
assert A_Operation_2 {
    Scope implies all v : Communication | v.medium in mediumSetter[v].by.mediumSet
}
check A_Operation_2 for 4

-- A_Operation_3: every version carries an occurred instant no later than the now of the call
-- that set it: no exchange still to come is held (Operation 3, Term occurred instant,
-- Non-goal 2).
assert A_Operation_3 {
    Scope implies all v : Communication, u : occurredSetter[v] | T/lte[v.occurred, u.by.now]
}
check A_Operation_3 for 4

-- A_Operation_10: every version carrying an outcome carries one the outcome set offered to the
-- call that set it (Operation 10, Term outcome).
assert A_Operation_10 {
    Scope implies all v : Communication | v.outcome in outcomeSetter[v].by.outcomeSet
}
check A_Operation_10 for 4

-- A_Operation_19: the communication a [Record] recorded carries every detail of the call as
-- the call carried it, never rewritten into another form (Operation 19, Identity 6, 8, 10,
-- 12).
assert A_Operation_19 {
    Scope implies all g : Communication | no g.found implies {
        g.medium = origin[g].rMedium
        g.occurred = origin[g].rOccurred
        g.outside.pm = origin[g].rOutside
        g.inside.pm = origin[g].rInside
        g.direction = origin[g].rDirection
        g.summary = origin[g].rSummary
        g.items.im = origin[g].rItems
        g.outcome = origin[g].rOutcome
    }
}
check A_Operation_19 for 4

-- A_Operation_20: the communication a [Record] recorded stands in active (Operation 20).
assert A_Operation_20 {
    Scope implies all g : Communication | no g.found implies g.status = Active
}
check A_Operation_20 for 4

-- A_Operation_21: a [Record] naming no inside participant recorded an empty list as the
-- inside participants, never no list (Operation 21).
assert A_Operation_21 {
    Scope implies all g : Communication | (no g.found and no origin[g].rInside)
        implies (some g.inside and no g.inside.pm)
}
check A_Operation_21 for 4

-- A_Operation_22: a [Record] naming no item reference recorded an empty list as the item
-- references, never no list (Operation 22).
assert A_Operation_22 {
    Scope implies all g : Communication | (no g.found and no origin[g].rItems)
        implies (some g.items and no g.items.im)
}
check A_Operation_22 for 4

-- A_Invariant_1_1: every version of every communication carries an outside participant: a
-- [Change] cannot take the last one off (Invariant 1.1, Check 2.1, the Edge case "A detail
-- once given").
assert A_Invariant_1_1 {
    Scope implies all v : Communication | some v.outside.pm
}
check A_Invariant_1_1 for 4

-- ─────────────────────────────────────────────────────────────────────────────
-- Satisfiability runs — non-vacuity guards, one for each shape the page admits
-- Each run must find at least one instance (SAT).
-- UNSAT means the model forbids a state the page admits.
-- ─────────────────────────────────────────────────────────────────────────────

-- ShowLateLogged: two communications about one item, the one logged later having happened
-- earlier, as Dana's Tuesday call logged on Friday after Jane's Wednesday email.
run ShowLateLogged {
    Scope and some disj a, b : Communication | {
        no (a + b).found
        some (a.items.im & b.items.im)
        C/lt[a.by, b.by]
        T/lt[b.occurred, a.occurred]
    }
} for 4

-- ShowBare: a communication carrying no direction, summary or outcome, and empty lists of
-- inside participants and item references (State 2, Operation 21, 22).
run ShowBare {
    Scope and some g : Communication | {
        no g.direction and no g.summary and no g.outcome
        no g.inside.pm and no g.items.im
    }
} for 4

-- ShowChangedKept: a communication whose summary a [Change] set, the earlier version still
-- held beside the later one, as Dana's sharpened summary (Execution Contract Database 5).
run ShowChangedKept {
    Scope and some g : Communication | {
        g.by in ChangeCall
        some g.found.summary
        g.summary != g.found.summary
    }
} for 4

-- ShowWithdrawn: a withdrawn communication beside the active version it was withdrawn over,
-- as the sync's duplicate c-73.
run ShowWithdrawn {
    Scope and some g : Communication | g.status = Withdrawn and g.found.status = Active
} for 4

-- ShowDroppedMedium: a communication carrying a medium the medium set no longer offers to a
-- later call, which keeps the medium (the Edge case "A medium set or an outcome set that
-- changes").
run ShowDroppedMedium {
    Scope and some g : Communication, c : Call | C/lt[g.by, c] and g.medium not in c.mediumSet
} for 4

-- ShowCaseVariantPersons: two communications whose outside participants one normalizer would
-- merge, jane-ruiz and Jane-Ruiz, each recorded as written (Identity 6, 7).
run ShowCaseVariantPersons {
    Scope and some disj a, b : Communication | {
        no (a + b).found
        some p : a.outside.pm | p.(Normalizer.foldPerson) in b.outside.pm
    }
} for 4
