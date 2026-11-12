-- personal-todo-buggy-edit-done-unguarded.als
-- DELIBERATELY WRONG twin of personal-todo.als (unit: `atoms/personal-todo.md formal layer`).
--
-- INJECTED DEFECT: [Edit] skips Operation 8: it edits a done unit instead of answering
-- not-editable.
--
-- BREAKS: A_Invariant_7_3.
-- Everything else is personal-todo.als as written; read its comments there.

module personal_todo_buggy_edit_done_unguarded

open util/ordering[Call] as C
open util/ordering[Instant] as T

-- ─────────────────────────────────────────────────────────────────────────────
-- Signatures (types)
-- ─────────────────────────────────────────────────────────────────────────────

-- Id: an opaque id (Term id), which the host allocates at the seam on [Add] (Identity 2).
sig Id {}

-- Desc: a text: what a call carries as its description or new description (raw, as typed:
-- "  buy milk", or café spelled with a combining accent), or a normalized one a unit
-- carries. Compared as tokens: two different texts are two atoms, so Buy milk and buy
-- milk are two (Description 6).
sig Desc {}

-- Instant: a reading of the clock. Only the order matters (util/ordering).
sig Instant {}

-- UnitState: the unit state, pending or done (Term unit state).
abstract sig UnitState {}

-- Pending, Done: the two members of the unit state.
one sig Pending, Done extends UnitState {}

-- Text: what the page says about texts. norm is the description policy's normalizer:
-- leading and trailing whitespace trimmed (Description 1), Unicode normal form C
-- (Description 2). empty is the text blank once normalized. overCap is the texts longer
-- than the description cap as the call carries them, before normalizing (Term description
-- cap). fold is what a case-folding comparison would merge a text with (buy milk for Buy
-- milk); the page forbids it (Description 6, Non-goal 15), so the model's actions never
-- apply it: it is here so the runs can show two texts it would merge.
one sig Text {
    norm    : Desc -> one Desc,
    empty   : one Desc,
    overCap : set Desc,
    fold    : Desc -> lone Desc
}

-- Call: one call of a writing action ([Add], [Edit], [Complete], [Delete]). Calls happen
-- in one order, the order Execution Contract Order 1 gives every commit. Each is given the
-- clock reading `now` at the seam (Capability requirement 1, Term now). callerAt is an
-- instant a business caller might send along; the page forbids stamping from it (Term
-- business caller: never the source of an injected value), so the model's actions never
-- read it: it is here so a twin can.
abstract sig Call {
    now      : one Instant,
    callerAt : one Instant
}

-- AddCall: one [Add] call, add(description). The seam supplies it an id (Identity 2).
-- callerId is an id the business caller might send along; [Add] must not take it
-- (Identity 4), so the model's actions never read it: it is here so a twin can.
sig AddCall extends Call {
    descIn   : one Desc,   -- description, as the call carries it
    seamId   : one Id,     -- the id the seam allocates this call
    callerId : one Id      -- an id the business caller sent along (never used)
}

-- EditCall: one [Edit] call, edit(id, new_description).
sig EditCall extends Call {
    editId : one Id,       -- id
    newIn  : one Desc      -- new_description, as the call carries it
}

-- CompleteCall: one [Complete] call, complete(id).
sig CompleteCall extends Call {
    compId : one Id        -- id
}

-- DeleteCall: one [Delete] call, delete(id).
sig DeleteCall extends Call {
    delId : one Id         -- id
}

-- Unit: one version of a unit record (Term records), as the call that wrote it left it.
-- Every field the page names may be absent, and the state a set, so a write that forgot a
-- field or stood a unit in two states would show; what the page promises (State 1, 2, 4)
-- is checked, never built into the type. The last two fields are the model's own: which
-- call wrote this version, and which version an [Edit] or [Complete] found.
sig Unit {
    uid       : lone Id,         -- id (Identity 1)
    desc      : lone Desc,       -- description
    st        : set UnitState,   -- unit state
    added     : lone Instant,    -- addition instant
    edited    : lone Instant,    -- last edit instant
    completed : lone Instant,    -- completion instant
    writtenBy : one AddCall + EditCall + CompleteCall,
    found     : lone Unit
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Facts: what the page takes from outside
-- ─────────────────────────────────────────────────────────────────────────────

-- A normalized text is already normalized: trimming a trimmed text and composing a
-- composed one change nothing (Unicode Standard Annex #15, which the page cites for NFC;
-- Description 1, 2).
fact NormalFormIsStable {
    all d : Desc | Text.norm[Text.norm[d]] = Text.norm[d]
}

-- The seam allocates each [Add] an id no unit has carried (Identity 2, Execution Contract
-- Logic confinement 3 and 16): two [Add] calls never get one id.
fact SeamAllocatesFreshIds {
    all disj a, b : AddCall | a.seamId != b.seamId
}

-- The clock's readings never go backward (Execution Contract Logic confinement 7, the
-- deployment's, which External check 1 cites for Invariant 7.1 through 7.3): a later call
-- is never given an earlier now.
fact ClockNeverGoesBack {
    all c1, c2 : Call | C/lt[c1, c2] implies not T/lt[c2.now, c1.now]
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Helpers
-- ─────────────────────────────────────────────────────────────────────────────

-- first: the first version of the unit this version belongs to, the one [Add] wrote.
fun first[u : Unit] : set Unit {
    { v : u.*found | no v.found }
}

-- adder: the [Add] call that recorded the unit this version belongs to. Two versions with
-- one adder are one unit; two adders are two units.
fun adder[u : Unit] : set AddCall {
    first[u].writtenBy & AddCall
}

-- takesOut: the [Delete] names the unit's id, so it takes the unit out of the list
-- (Operation 18 to 20).
pred takesOut[d : DeleteCall, u : Unit] {
    d.delId in first[u].uid
}

-- currentAt: the version is the unit's version in the list when call c runs: it was
-- written before c, no [Delete] between the unit's [Add] and c took the unit out, and no
-- later version of the unit was written before c (Execution Contract Database 2).
pred currentAt[v : Unit, c : Call] {
    C/lt[v.writtenBy, c]
    no d : DeleteCall | C/lt[adder[v], d] and C/lt[d, c] and takesOut[d, v]
    no w : Unit | adder[w] = adder[v] and C/lt[v.writtenBy, w.writtenBy]
        and C/lt[w.writtenBy, c]
}

-- currentNow: the version is the unit's version in the list in the state: the unit is in
-- the active set (Term active set) and this is its latest version.
pred currentNow[v : Unit] {
    no d : DeleteCall | C/lt[adder[v], d] and takesOut[d, v]
    no w : Unit | adder[w] = adder[v] and C/lt[v.writtenBy, w.writtenBy]
}

-- lastEdit: the last [Edit] that wrote a version of this unit up to this one (none if no
-- edit changed its description).
fun lastEdit[u : Unit] : lone EditCall {
    C/max[(u.*found).writtenBy & EditCall]
}

-- completer: the [Complete] that wrote a version of this unit up to this one.
fun completer[u : Unit] : lone CompleteCall {
    C/max[(u.*found).writtenBy & CompleteCall]
}

-- descSource: the text, as a call carried it, that gave this version its description:
-- the last changing [Edit]'s new description, or else its [Add]'s description.
fun descSource[u : Unit] : set Desc {
    some lastEdit[u] => lastEdit[u].newIn else adder[u].descIn
}

-- ─────────────────────────────────────────────────────────────────────────────
-- The writing actions: their guards and their writes
-- ─────────────────────────────────────────────────────────────────────────────

-- addWrites: the unit an admitted [Add] records, and the guards it passes first: the
-- normalized description is not blank (Description 4); the description as the call
-- carries it is not over the cap (Description 5); no unit in the active set carries the
-- normalized description, compared on the normalized form, case for case (Operation 4,
-- Description 6, 7). The unit carries the id the seam allocates (Identity 2, 4), the
-- normalized description (Operation 1, Description 1, 2), pending (Operation 2) and the
-- addition instant from now (State 5), and no last edit or completion instant.
pred addWrites[a : AddCall, u : Unit] {
    Text.norm[a.descIn] != Text.empty                               -- Description 4
    a.descIn not in Text.overCap                                    -- Description 5
    no v : Unit | currentAt[v, a] and v.desc = Text.norm[a.descIn]  -- Operation 4, Description 7
    u.uid       = a.seamId                                          -- Identity 2, Identity 4
    u.desc      = Text.norm[a.descIn]                               -- Operation 1, Description 1, 2
    u.st        = Pending                                           -- Operation 2
    u.added     = a.now                                             -- State 5
    no u.edited                                                     -- State 3
    no u.completed
}

-- editWrites: the version an admitted [Edit] with a different normalized text records over
-- the version it found: the call names a unit in the list (Operation 7); the unit is not
-- done (Operation 8); the normalized new description differs from the unit's (Operation
-- 10, 13) and is not blank (Operation 32); the new description as the call carries it is
-- not over the cap (Operation 33); no other unit in the active set carries it (Operation
-- 9). The version carries the normalized new description (Operation 13) and the last edit
-- instant from now (State 6); every other field stays as found (Invariant 5.2).
pred editWrites[pre : Unit, e : EditCall, u : Unit] {
    currentAt[pre, e]
    e.editId in pre.uid                                             -- Operation 7
    -- BUG: Operation 8 skipped
    Text.norm[e.newIn] != pre.desc                                  -- Operation 10, 13
    Text.norm[e.newIn] != Text.empty                                -- Operation 32
    e.newIn not in Text.overCap                                     -- Operation 33
    no v : Unit | currentAt[v, e] and adder[v] != adder[pre]
        and v.desc = Text.norm[e.newIn]                             -- Operation 9
    u.uid       = pre.uid
    u.st        = pre.st                                            -- Operation 14
    u.added     = pre.added
    u.completed = pre.completed
    u.desc      = Text.norm[e.newIn]                                -- Operation 13
    u.edited    = e.now                                             -- State 6
}

-- completeWrites: the version an admitted [Complete] records over the version it found:
-- the call names a unit in the list (Operation 15) that is not done (Operation 16). The
-- version stands in done (Operation 17) and carries the completion instant from now
-- (State 7); every other field stays as found.
pred completeWrites[pre : Unit, c : CompleteCall, u : Unit] {
    currentAt[pre, c]
    c.compId in pre.uid                                             -- Operation 15
    Done not in pre.st                                              -- Operation 16
    u.uid       = pre.uid
    u.desc      = pre.desc
    u.added     = pre.added
    u.edited    = pre.edited
    u.st        = Done                                              -- Operation 17
    u.completed = c.now                                             -- State 7
}

-- written: the version is what its call's write left: an [Add] writes a first version; an
-- [Edit] or a [Complete] writes over a version an earlier call wrote.
pred written[v : Unit] {
    let c = v.writtenBy {
        (c in AddCall and no v.found and addWrites[c, v])
        or (c in EditCall and some v.found and editWrites[v.found, c, v])
        or (c in CompleteCall and some v.found and completeWrites[v.found, c, v])
    }
}

-- Scope: every version the state holds is one an admitted call wrote (see SCOPE). It is
-- the model's universe, not a rule of the page: each check reads "in any state the calls
-- can leave".
pred Scope {
    all u : Unit | written[u]
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Assertions (verified guarantees)
-- Each "check" asks: is there any state the page's calls can leave that violates this
-- assertion? No counterexample (UNSAT) = the guarantee holds within scope.
-- ─────────────────────────────────────────────────────────────────────────────

-- A_State_1: every unit stands in exactly one of pending and done (State 1, Check 1.1).
assert A_State_1 {
    Scope implies all u : Unit | one u.st
}
check A_State_1 for 3 but 4 Call, 4 Unit

-- A_State_2: every version of every unit carries its id, its description and its addition
-- instant, however often it was edited (State 2, Check 1.2).
assert A_State_2 {
    Scope implies all u : Unit | some u.uid and some u.desc and some u.added
}
check A_State_2 for 3 but 4 Call, 4 Unit

-- A_State_4: every done unit carries a completion instant (State 4, Check 1.3).
assert A_State_4 {
    Scope implies all u : Unit | Done in u.st implies some u.completed
}
check A_State_4 for 3 but 4 Call, 4 Unit

-- A_State_5: every unit's addition instant is the now the seam gave its [Add], never an
-- instant the business caller sent (State 5, Term now).
assert A_State_5 {
    Scope implies all u : Unit | u.added = adder[u].now
}
check A_State_5 for 3 but 4 Call, 4 Unit

-- A_State_6: a unit's last edit instant is the now the seam gave the last [Edit] that
-- changed its description, and the unit carries none where no edit did (State 6, State 3).
assert A_State_6 {
    Scope implies all u : Unit | u.edited = lastEdit[u].now
}
check A_State_6 for 3 but 4 Call, 4 Unit

-- A_State_7: a done unit's completion instant is the now the seam gave its [Complete]
-- (State 7).
assert A_State_7 {
    Scope implies all u : Unit | Done in u.st implies u.completed = completer[u].now
}
check A_State_7 for 3 but 4 Call, 4 Unit

-- A_Identity_5: no two units share an id, among the units in the list and the versions of
-- units deleted, which the database keeps (Execution Contract Database 5): a description
-- deleted and added again gets a fresh id (Identity 5, Re-adding 2, Check 2.2).
assert A_Identity_5 {
    Scope implies all u1, u2 : Unit | adder[u1] != adder[u2] implies no (u1.uid & u2.uid)
}
check A_Identity_5 for 3 but 4 Call, 4 Unit

-- A_Invariant_6_1: two units in the active set, pending or done, never share a normalized
-- description, so a list never holds buy milk twice (Invariant 6.1, Check 3.1).
assert A_Invariant_6_1 {
    Scope implies all u1, u2 : Unit |
        (currentNow[u1] and currentNow[u2] and adder[u1] != adder[u2])
            implies no (u1.desc & u2.desc)
}
check A_Invariant_6_1 for 3 but 4 Call, 4 Unit

-- A_Invariant_7_1: a unit's last edit instant, where it carries one, never precedes its
-- addition instant (Invariant 7.1, Check 4.1).
assert A_Invariant_7_1 {
    Scope implies all u : Unit | all e : u.edited, a : u.added | not T/lt[e, a]
}
check A_Invariant_7_1 for 3 but 4 Call, 4 Unit

-- A_Invariant_7_2: a unit's completion instant, where it carries one, never precedes its
-- addition instant (Invariant 7.2, Check 4.2).
assert A_Invariant_7_2 {
    Scope implies all u : Unit | all c : u.completed, a : u.added | not T/lt[c, a]
}
check A_Invariant_7_2 for 3 but 4 Call, 4 Unit

-- A_Invariant_7_3: where a unit carries both, its completion instant never precedes its
-- last edit instant: no edit lands on a done unit (Invariant 7.3, Check 4.3, Operation 8).
assert A_Invariant_7_3 {
    Scope implies all u : Unit | all c : u.completed, e : u.edited | not T/lt[c, e]
}
check A_Invariant_7_3 for 3 but 4 Call, 4 Unit

-- A_Description_1_2: every unit carries its description normalized: normalizing it again
-- changes nothing, so "  buy milk " is held as "buy milk" and café in one spelling
-- (Description 1, 2; Operation 1; Description 8, the form shown).
assert A_Description_1_2 {
    Scope implies all u : Unit | all d : u.desc | Text.norm[d] = d
}
check A_Description_1_2 for 3 but 4 Call, 4 Unit

-- A_Description_4: no unit carries a description blank once normalized, whether [Add]
-- recorded it or an [Edit] wrote it (Description 4, Operation 32).
assert A_Description_4 {
    Scope implies all u : Unit | Text.empty not in u.desc
}
check A_Description_4 for 3 but 4 Call, 4 Unit

-- A_Description_5: no unit's description came from a text over the description cap as the
-- call carried it, before normalizing (Description 5, Operation 33, Term description cap).
assert A_Description_5 {
    Scope implies all u : Unit | no (descSource[u] & Text.overCap)
}
check A_Description_5 for 3 but 4 Call, 4 Unit

-- ─────────────────────────────────────────────────────────────────────────────
-- Satisfiability runs — non-vacuity guards, one for each shape the page admits
-- Each run must find at least one instance (SAT).
-- UNSAT means the model forbids a state the page admits.
-- ─────────────────────────────────────────────────────────────────────────────

-- ShowPending: a unit just added, pending, never edited, as add("buy milk") answers t1.
run ShowPending {
    Scope and some u : Unit | currentNow[u] and u.st = Pending and no u.edited
} for 3 but 4 Call, 4 Unit

-- ShowEditedThenDone: a unit edited and then completed, carrying all three instants, as
-- "learn Python" made concrete and then finished.
run ShowEditedThenDone {
    Scope and some u : Unit | currentNow[u] and u.st = Done and some u.edited
} for 3 but 4 Call, 4 Unit

-- ShowPendingBesideDone: a pending unit and a done one in the list together.
run ShowPendingBesideDone {
    Scope and some u1, u2 : Unit | currentNow[u1] and currentNow[u2]
        and u1.st = Pending and u2.st = Done
} for 3 but 4 Call, 4 Unit

-- ShowReAdded: a description deleted and added again: two units, two ids, the first taken
-- out and kept as a version, the second in the list (Re-adding 1, 2; "buy milk" as t1
-- and then t2).
run ShowReAdded {
    Scope and some u1, u2 : Unit | adder[u1] != adder[u2] and u1.desc = u2.desc
        and (some d : DeleteCall | C/lt[adder[u1], d] and takesOut[d, u1])
        and currentNow[u2]
} for 3 but 4 Call, 4 Unit

-- ShowCaseVariants: Buy milk and buy milk in the list together, two texts a case-folding
-- comparison would merge, as two units (Description 6).
run ShowCaseVariants {
    Scope and some u1, u2 : Unit | currentNow[u1] and currentNow[u2]
        and adder[u1] != adder[u2] and u2.desc = Text.fold[u1.desc]
} for 3 but 4 Call, 4 Unit

-- ShowNormalized: a unit whose [Add] carried a text other than the description it holds,
-- as "  buy milk" held as "buy milk", or café typed with a combining accent held composed.
run ShowNormalized {
    Scope and some u : Unit | currentNow[u] and adder[u].descIn not in u.desc
} for 3 but 4 Call, 4 Unit
