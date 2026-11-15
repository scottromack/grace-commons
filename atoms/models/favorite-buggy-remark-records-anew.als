-- favorite-buggy-remark-records-anew.als
-- DELIBERATELY WRONG twin of favorite.als (unit: `atoms/favorite.md formal layer`).
--
-- INJECTED DEFECT: [Mark] looks only for a marked favorite, so on an unmarked one it records a second
-- favorite for the pair beside the first, which stays (Invariant 1.1; the Decisions entry's
-- rejected favorite recorded anew on mark).
--
-- BREAKS: A_Invariant_1_1.
-- Everything else is favorite.als as written; read its comments there.

module favorite_buggy_remark_records_anew

open util/ordering[Call] as C

-- ─────────────────────────────────────────────────────────────────────────────
-- Signatures (types)
-- ─────────────────────────────────────────────────────────────────────────────

-- PersonRef: a string a call carries as a person reference, such as ana or Ana, which the
-- atom compares codepoint for codepoint, so two different strings are two different atoms
-- (Term person reference, Identity 3).
sig PersonRef {}

-- ItemRef: a string a call carries as an item reference, such as kettle-blue or Kettle-Blue,
-- compared codepoint for codepoint (Term item reference, Identity 5).
sig ItemRef {}

-- Instant: a clock reading the host injects at the seam as now (Capability requirement 2,
-- Execution Contract Logic confinement 11). No rule here turns on the order of two readings.
sig Instant {}

-- Status: where a favorite stands (Term status).
abstract sig Status {}

-- Marked: the status of a favorite the person keeps; the heart is filled (Term marked).
one sig Marked extends Status {}

-- Unmarked: the status of a favorite the person has let go; the heart is empty (Term
-- unmarked).
one sig Unmarked extends Status {}

-- Normalizer: what a normalizer that folds case would rewrite a reference to, where the
-- result differs (ana for Ana, kettle-blue for Kettle-Blue). The page forbids it (Identity 2
-- to 5, Capability requirement 4, 5): the model's own actions never apply it. It is here so
-- a run can show two references one normalizer would merge, and so a twin can apply it.
one sig Normalizer {
    foldPerson : PersonRef -> lone PersonRef,
    foldItem   : ItemRef -> lone ItemRef
}

-- Call: one call of a writing action ([Mark], [Unmark]) with the person reference and the
-- item reference it carries, and the now the seam gives it. Calls happen in one order, the
-- order Execution Contract Order 1 gives every commit.
abstract sig Call {
    callPerson : one PersonRef,   -- person_reference
    callItem   : one ItemRef,     -- item_reference
    now        : one Instant      -- the clock reading injected at the seam
}

-- MarkCall: one [Mark] call, mark(person_reference, item_reference).
sig MarkCall extends Call {}

-- UnmarkCall: one [Unmark] call, unmark(person_reference, item_reference).
sig UnmarkCall extends Call {}

-- Favorite: one version of a favorite record (Term records, Term version), as the call that
-- wrote it left it. Every field the page names may be absent and the status may hold either
-- member or both, so a write that forgot a field or stood a favorite in two statuses would
-- show; what the page promises (State 1, 2) is checked, never built into the type. The last
-- two fields are the model's own: which call wrote this version, and which version a [Mark]
-- or an [Unmark] found.
sig Favorite {
    personRef   : lone PersonRef,  -- person reference
    itemRef     : lone ItemRef,    -- item reference
    firstMarked : lone Instant,    -- first marked instant
    status      : set Status,      -- status
    writtenBy   : one Call,
    found       : lone Favorite
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Helpers
-- ─────────────────────────────────────────────────────────────────────────────

-- first: the first version of the favorite this version belongs to, the one [Mark] wrote.
fun first[g : Favorite] : set Favorite {
    { v : g.*found | no v.found }
}

-- origin: the [Mark] call that recorded the favorite this version belongs to. Two versions
-- with one origin are one favorite; two origins are two favorites.
fun origin[g : Favorite] : set MarkCall {
    first[g].writtenBy & MarkCall
}

-- currentAt: the version is its favorite's latest version when call c runs: it was written
-- before c, and no later version of the same favorite was written before c (Execution
-- Contract Database 2).
pred currentAt[v : Favorite, c : Call] {
    C/lt[v.writtenBy, c]
    no w : Favorite | origin[w] = origin[v] and C/lt[v.writtenBy, w.writtenBy]
        and C/lt[w.writtenBy, c]
}

-- forPair: the version carries the pair the call carries, each reference compared codepoint
-- for codepoint (Term pair, Identity 3, 5).
pred forPair[v : Favorite, c : Call] {
    v.personRef = c.callPerson
    v.itemRef = c.callItem
}

-- ─────────────────────────────────────────────────────────────────────────────
-- The writing actions: their guards and their writes
-- ─────────────────────────────────────────────────────────────────────────────

-- markRecords: the favorite an admitted [Mark] records where no favorite exists for the pair
-- (Operation 3): it carries the person reference and the item reference as the call carried
-- them (Operation 3, Identity 2, 4), the first marked instant from the injected now
-- (Operation 4), and stands in marked (Operation 5).
pred markRecords[c : MarkCall, g : Favorite] {
    no v : Favorite | currentAt[v, c] and forPair[v, c]
        and v.status = Marked                                     -- BUG: only a marked one found
    g.personRef   = c.callPerson                                  -- Operation 3, Identity 2
    g.itemRef     = c.callItem                                    -- Operation 3, Identity 4
    g.firstMarked = c.now                                         -- Operation 4
    g.status      = Marked                                        -- Operation 5
}

-- markRemarks: the version an admitted [Mark] records over the favorite it found for the
-- pair, standing in unmarked (Operation 6): the favorite stands in marked, and keeps its
-- person reference, item reference and first marked instant (the case table: "its first
-- marked instant stands"). A marked favorite is not written (Operation 7).
pred markRemarks[pre : Favorite, c : MarkCall, g : Favorite] {
    currentAt[pre, c]
    forPair[pre, c]                                               -- Identity 3, 5
    pre.status = Unmarked                                         -- Operation 6, 7
    g.personRef   = pre.personRef
    g.itemRef     = pre.itemRef
    g.firstMarked = pre.firstMarked
    g.status      = Marked                                        -- Operation 6
}

-- unmarkWrites: the version an admitted [Unmark] records over the favorite it found for the
-- pair, standing in marked (Operation 9): the favorite stands in unmarked and keeps every
-- other field; nothing is removed (State 3). An unmarked favorite, or a pair with none, is
-- not written (Operation 10, 11).
pred unmarkWrites[pre : Favorite, c : UnmarkCall, g : Favorite] {
    currentAt[pre, c]
    forPair[pre, c]                                               -- Identity 3, 5
    pre.status = Marked                                           -- Operation 9, 10
    g.personRef   = pre.personRef
    g.itemRef     = pre.itemRef
    g.firstMarked = pre.firstMarked
    g.status      = Unmarked                                      -- Operation 9
}

-- written: the version is what its call's write left: a [Mark] writes a first version or a
-- version over one it found; an [Unmark] writes over one it found.
pred written[g : Favorite] {
    let c = g.writtenBy {
        (c in MarkCall and no g.found and markRecords[c, g])
        or (c in MarkCall and some g.found and markRemarks[g.found, c, g])
        or (c in UnmarkCall and some g.found and unmarkWrites[g.found, c, g])
    }
}

-- Scope: every version the state holds is one an admitted call wrote (see SCOPE). It is the
-- model's universe, not a rule of the page: each check reads "in any state the calls can
-- leave".
pred Scope {
    all g : Favorite | written[g]
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Assertions (verified guarantees)
-- Each "check" asks: is there any state the page's calls can leave that violates this
-- assertion? No counterexample (UNSAT) = the guarantee holds within scope.
-- ─────────────────────────────────────────────────────────────────────────────

-- A_State_1: every version of every favorite carries its person reference, item reference,
-- first marked instant and status, however often it was marked and unmarked (State 1,
-- Check 1.1).
assert A_State_1 {
    Scope implies all g : Favorite | {
        some g.personRef
        some g.itemRef
        some g.firstMarked
        some g.status
    }
}
check A_State_1 for 4

-- A_State_2: every version of every favorite stands in exactly one of marked and unmarked:
-- the heart is filled or empty, never both (State 2, Check 1.2).
assert A_State_2 {
    Scope implies all g : Favorite | one g.status
}
check A_State_2 for 4

-- A_Identity_3: every version a [Mark] or an [Unmark] wrote over a favorite it found is of the
-- favorite carrying the very person reference the call carried, codepoint for codepoint:
-- unmark("Ana", ...) never lets go of a favorite of ana (Identity 3).
assert A_Identity_3 {
    Scope implies all g : Favorite | some g.found implies
        g.writtenBy.callPerson = g.found.personRef
}
check A_Identity_3 for 4

-- A_Identity_5: every version a [Mark] or an [Unmark] wrote over a favorite it found is of the
-- favorite carrying the very item reference the call carried, codepoint for codepoint:
-- unmark("ana", "Kettle-Blue") writes nothing on ana's kettle-blue (Identity 5, the rejection
-- paths).
assert A_Identity_5 {
    Scope implies all g : Favorite | some g.found implies
        g.writtenBy.callItem = g.found.itemRef
}
check A_Identity_5 for 4

-- A_Operation_3: the favorite a [Mark] recorded carries the person reference and the item
-- reference the call carried, as it carried them, never rewritten into another form
-- (Operation 3, Identity 2, 4).
assert A_Operation_3 {
    Scope implies all g : Favorite | no g.found implies {
        g.personRef = origin[g].callPerson
        g.itemRef = origin[g].callItem
    }
}
check A_Operation_3 for 4

-- A_Operation_4: every version of every favorite carries as its first marked instant the now
-- the seam gave the [Mark] that recorded it, so a favorite unmarked and marked again keeps
-- the 9:14 on Monday it always had (Operation 4, Term first marked instant, the online store).
assert A_Operation_4 {
    Scope implies all g : Favorite | g.firstMarked = origin[g].now
}
check A_Operation_4 for 4

-- A_Operation_5: the favorite a [Mark] recorded stands in marked: the first tap fills the
-- heart (Operation 5).
assert A_Operation_5 {
    Scope implies all g : Favorite | no g.found implies g.status = Marked
}
check A_Operation_5 for 4

-- A_Invariant_1_1: no two favorites share a pair: an item is a person's favorite once or not
-- at all, the versions of each favorite included (Invariant 1.1, Check 2.1).
assert A_Invariant_1_1 {
    Scope implies all g1, g2 : Favorite | origin[g1] != origin[g2] implies
        not (g1.personRef = g2.personRef and g1.itemRef = g2.itemRef)
}
check A_Invariant_1_1 for 4

-- ─────────────────────────────────────────────────────────────────────────────
-- Satisfiability runs — non-vacuity guards, one for each shape the page admits
-- Each run must find at least one instance (SAT).
-- UNSAT means the model forbids a state the page admits.
-- ─────────────────────────────────────────────────────────────────────────────

-- ShowMarked: a favorite just marked, as mark("ana", "kettle-blue") on Monday at 9:14.
run ShowMarked {
    Scope and some g : Favorite | no g.found
} for 4

-- ShowUnmarked: a favorite let go, kept with its first marked instant, as ana's kettle after
-- Wednesday's slip.
run ShowUnmarked {
    Scope and some g : Favorite | g.writtenBy in UnmarkCall and g.status = Unmarked
} for 4

-- ShowRemarked: a favorite marked again after it was let go, carrying the first marked
-- instant of its first [Mark], not the now of the [Mark] that filled the heart again.
run ShowRemarked {
    Scope and some g : Favorite | g.writtenBy in MarkCall and some g.found
        and g.firstMarked != g.writtenBy.now
} for 4

-- ShowOneItemTwoPersons: one item two persons each keep as a favorite of their own.
run ShowOneItemTwoPersons {
    Scope and some g1, g2 : Favorite | origin[g1] != origin[g2]
        and g1.itemRef = g2.itemRef and g1.personRef != g2.personRef
} for 4

-- ShowCaseVariantItems: one person's two favorites whose item references one normalizer
-- would merge, kettle-blue and Kettle-Blue, each its own favorite (Identity 4, 5).
run ShowCaseVariantItems {
    Scope and some g1, g2 : Favorite | origin[g1] != origin[g2]
        and g1.personRef = g2.personRef
        and g2.itemRef = g1.itemRef.(Normalizer.foldItem)
} for 4

-- ShowCaseVariantPersons: two persons whose person references one normalizer would merge,
-- ana and Ana, each keeping one item as a favorite of their own (Identity 2, 3).
run ShowCaseVariantPersons {
    Scope and some g1, g2 : Favorite | origin[g1] != origin[g2]
        and g1.itemRef = g2.itemRef
        and g2.personRef = g1.personRef.(Normalizer.foldPerson)
} for 4
