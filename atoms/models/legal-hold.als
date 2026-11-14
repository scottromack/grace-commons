-- legal-hold.als
-- Alloy structural model for the Legal Hold atom (Grace Commons atoms/legal-hold.md)
-- Grounded on Final Critique 8, 2026-10-24 at c39a73f — Alloy layer authored 2026-11-11.
-- Derived validator; the English spec is the single source of truth. On any
-- disagreement, diagnose per the entry *The conflict protocol* in pressure-testing.md.
--
-- PURPOSE
-- Verify, by bounded exhaustive search, the STATIC data model of a hold: what one hold
-- record must satisfy, whatever admitted [Place] or [Release] calls wrote it. The hold's
-- path through the calls, and what one release does to another hold, are the TLA+ model's,
-- legal-hold.tla, which owns the operation sequences.
--
-- RULES ENCODED (named by the page's own labels)
--   Invariant 1.1 — a hold's hold id, record reference, placing actor, hold reason,
--                   placement instant and case reference are the ones its [Place] recorded.
--   Invariant 1.2 — a released hold's releasing actor, release reason and release instant
--                   are the ones the release that ended it recorded.
--   Invariant 2.1 — every hold stands in exactly one of active, released (State 1 says the
--                   same, word for word; the page's open line 2026-10-21-c lists it).
--   Invariant 3.1 — a hold that once stood released does not stand in active.
--   Invariant 4.2 — a released hold was released by a [Release] naming its own hold id.
--   Invariant 5.1 — a released hold carries a releasing actor that is not blank.
--   Invariant 5.2 — a released hold carries a release reason that is not blank.
--   Invariant 5.3 — a released hold carries a release instant.
--   Invariant 6.1 — a released hold's release instant does not precede its placement instant.
--   Invariant 7.1 — every hold carries a placing actor that is not blank.
--   Invariant 7.2 — every hold carries a hold reason that is not blank.
--   Invariant 7.3 — every hold carries a placement instant.
--   State 5       — an active hold carries no release field.
--   Operation 4   — every hold carries a record reference that is not blank (Check 2.3).
--   Operation 7   — a hold that carries a case reference carries one that is not blank.
--   Instance 2    — two holds in one database instance do not share a hold id (with one
--                   instance in the model, Identity 4 and Identity 8 in one state).
-- Invariant 1 and 3.1 compare a hold with what it was: the page keeps no history of a hold
-- beyond its fields, so the model builds each version of a hold from the version its call
-- found, back to the placement, and reads a version against the versions that built it, as
-- duplicate-prevention.als reads a recording instant against the record that opened its
-- guard. A field changed and changed back leaves the fields as recorded; that sequence is
-- the TLA+ model's. Invariant 4.2 and 6.1 are checked by legal-hold.tla too
-- (Inv_HoldIndependence, Inv_TemporalOrdering), so the two models cross-check them; there
-- the clock only advances, while here a call's now is any reading and a caller may supply
-- either instant, so 6.1 rests on Operation 17's guard alone.
--
-- NOT CHECKED HERE (nothing testable in Alloy)
--   Invariant 3.2 (the atom offers no re-activation) names what the atom's signature offers,
--   not a state: the model's actions are the signature's, [Place] and [Release]. An offered
--   re-activation is the twin legal-hold-buggy-reinstated.als, which A_Invariant_3_1 catches.
--   Invariant 4.1 (a release changes no other hold's state) compares the other hold before
--   and after the release, and 4.3 defines a reading over stored fields (Term held at an
--   instant) that the atom stores no aggregate to compare with (State 8, Aggregate 2): both
--   are the TLA+ model's (4.1 is Inv_HoldIndependence there). Invariant 8 (no hold deleted;
--   the hold set never shrinks) compares two readings, and a deleted hold leaves nothing in
--   one state to read.
--
-- SCOPE
-- A hold version is what one admitted call leaves: [Place] records a hold in active from
-- the call's inputs and the hold id the host allocated (Operation 1 to 10); [Release] leaves
-- a new version of the hold it names over the version it found (Operation 12 to 19). Each
-- version is built from the version its call found, back to the placement, so a version
-- three or four calls deep is built too: the scope is four calls, four hold versions, four
-- strings and ids, and four-bit integers for instants. The model does not ask whether the
-- version a call found was still the latest one (that is the sequence, the TLA+ model's),
-- so it builds every record a state can hold and some no state reaches; a check that holds
-- over all of them holds over the records. All holds are in one database instance
-- (Instance 1); the model has no second one to reach (Instance 3). No trace, no `var`, no
-- stepping. Ids and strings are opaque tokens; a string in Blank is whitespace-only (the
-- examples' "   "), and an absent required input reads as blank. Instants are integers,
-- only ever compared.
--
-- NOT MODELED HERE
--   - A refused call (invalid-request, not-known, already-released, storage-failure): a
--     refused call writes nothing (Execution Contract Database 3, Refusal 1), so it adds no
--     version; which refusal answers is the Execution Contract's, and the model needs only
--     whether a call is admitted.
--   - [Read] (Operation 23 to 34) and the database name it answers (Instance 5 to 7): a read
--     writes nothing.
--   - The string cap (Capability requirement 5, Execution Contract Input 2): a length, not
--     a shape.
--   - The order of [Release]'s refusals (the Decisions entry of 2026-10-24): the answer, not
--     the record.
--
-- HOW TO READ RESULTS
-- Every "check A_*" must return "No counterexample found" (UNSAT) — the asserted guarantee holds.
-- Every "run Show*" must return at least one instance (SAT) — confirms non-vacuity.
-- A "check" returning a counterexample is a spec finding.

module legal_hold

-- ─────────────────────────────────────────────────────────────────────────────
-- Signatures (types)
-- ─────────────────────────────────────────────────────────────────────────────

-- Str: a string value a call carries or a hold holds — a record reference, an actor
-- reference, a reason or a case reference. The atom never reads what one names (Non-goal
-- 3; Term record reference, placing actor, case reference), so a string here is an
-- uninterpreted token.
sig Str {}

-- Blank: the strings that are empty or whitespace-only, which Operation 4 to 7, 15 and 16
-- refuse (the rejection path "place with empty reason"). Which strings these are is the
-- world's, not the atom's, so it is a subset with no rule on it.
sig Blank in Str {}

-- Id: an opaque hold id (Term hold id). It means nothing by itself and is compared by
-- identity only.
sig Id {}

-- HoldState: the two hold states (Term hold state); released is the terminal one.
abstract sig HoldState {}
one sig Active, Released extends HoldState {}

-- Call: one call of a writing action, as it reaches the seam, with the clock reading the
-- host injects for it (Term now, Execution Contract Logic confinement 11). Readings are
-- independent of one another: the page relies on no guarantee of the clock (Capability
-- requirement 1; Non-goal 17), so a later call may carry an earlier now.
abstract sig Call {
    now : one Int
}

-- PlaceCall: one [Place] call, place(record_ref, placed_by, reason, optional case_ref,
-- optional placed_at), with the hold id the host allocates for it at the seam (Identity 2).
-- An optional input left out is absent.
sig PlaceCall extends Call {
    allocatedId  : one Id,     -- the hold id the host injects
    recordRefIn  : lone Str,   -- record_ref
    placedByIn   : lone Str,   -- placed_by
    holdReasonIn : lone Str,   -- reason
    caseRefIn    : lone Str,   -- case_ref, optional
    placedAtIn   : lone Int    -- placed_at, optional (Operation 38)
}

-- ReleaseCall: one [Release] call, release(hold_id, released_by, reason, optional
-- released_at). The hold it names is the version it finds (see `written`).
sig ReleaseCall extends Call {
    holdIdIn        : one Id,    -- hold_id
    releasedByIn    : lone Str,  -- released_by
    releaseReasonIn : lone Str,  -- reason
    releasedAtIn    : lone Int   -- released_at, optional (Operation 39)
}

-- Hold: one version of a hold record (Term records), as the call that wrote it left it.
-- Every field the page names may be absent, and the state is a set of state flags, so a
-- write that forgot a field, or ADDED a state instead of replacing one, would show: what
-- the page promises (State 2, State 4, exactly one state) is checked, never built into the
-- type. The last two fields are the model's own: which call wrote this version and which
-- version that call found.
sig Hold {
    holdId        : lone Id,         -- hold id (Identity 1)
    recordRef     : lone Str,        -- record reference
    placedBy      : lone Str,        -- placing actor
    holdReason    : lone Str,        -- hold reason
    placedAt      : lone Int,        -- placement instant
    caseRef       : lone Str,        -- case reference (State 3: may be absent)
    state         : set HoldState,   -- the hold state (State 1)
    releasedBy    : lone Str,        -- releasing actor (State 4)
    releaseReason : lone Str,        -- release reason (State 4)
    releasedAt    : lone Int,        -- release instant (State 4)
    writtenBy     : one Call,        -- the call whose write left this version
    found         : lone Hold        -- the version that call found ([Release] only)
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Facts: what the page takes from outside
-- ─────────────────────────────────────────────────────────────────────────────

-- The host supplies an id it allocates to one call only (Execution Contract Logic
-- confinement 16, which the page does not cite): two [Place] calls never carry one hold id.
-- The page says the host allocates the id (Identity 2) and the transition does not
-- (Identity 3), and promises no reuse (Identity 4, Instance 2), which rests on this.
fact HostSuppliesEachIdOnce {
    all disj a, b : PlaceCall | a.allocatedId != b.allocatedId
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Helpers
-- ─────────────────────────────────────────────────────────────────────────────

-- nonBlank: a string is present and not empty or whitespace-only. An absent required input
-- reads as blank.
pred nonBlank[x : lone Str] {
    some x and x not in Blank
}

-- resolved: the instant a call records — the caller's value where it supplied one, and
-- now where it left the instant blank (Execution Contract Logic confinement 12; Term
-- resolved release instant).
fun resolved[supplied : lone Int, t : one Int] : lone Int {
    (some supplied) => supplied else t
}

-- originOf: the version [Place] wrote, the first along the chain of versions found.
fun originOf[h : Hold] : set Hold {
    { v : h.*found | no v.found }
}

-- originCall: the [Place] call that recorded the hold this version belongs to.
fun originCall[h : Hold] : set Call {
    originOf[h].writtenBy
}

-- firstRelease: the version that first stood the hold in released, along the chain.
fun firstRelease[h : Hold] : set Hold {
    { v : h.*found | Released in v.state and no w : v.^found | Released in w.state }
}

-- ─────────────────────────────────────────────────────────────────────────────
-- The writing actions: their guards and their writes
-- ─────────────────────────────────────────────────────────────────────────────

-- placeWrites: the hold an admitted [Place] records: the fields the Place entry lists, from
-- the call's inputs and the host's id, in active, with no release field yet.
pred placeWrites[c : PlaceCall, h : Hold] {
    nonBlank[c.recordRefIn]                            -- Operation 4
    nonBlank[c.placedByIn]                             -- Operation 5
    nonBlank[c.holdReasonIn]                           -- Operation 6
    no c.caseRefIn or c.caseRefIn not in Blank         -- Operation 7
    no c.placedAtIn or c.placedAtIn <= c.now           -- Operation 8, 40; Backdating 2
    h.holdId     = c.allocatedId                       -- Identity 2, 3
    h.recordRef  = c.recordRefIn
    h.placedBy   = c.placedByIn
    h.holdReason = c.holdReasonIn
    h.placedAt   = resolved[c.placedAtIn, c.now]       -- Operation 10, Logic confinement 12
    h.caseRef    = c.caseRefIn
    h.state      = Active                              -- Operation 2
    no h.releasedBy
    no h.releaseReason
    no h.releasedAt
}

-- keepsPlacement: the call leaves every field [Place] wrote as it found it: the release
-- writes its own fields and the state, nothing else (Execution Contract Database 4).
pred keepsPlacement[pre, h : Hold] {
    h.holdId     = pre.holdId
    h.recordRef  = pre.recordRef
    h.placedBy   = pre.placedBy
    h.holdReason = pre.holdReason
    h.placedAt   = pre.placedAt
    h.caseRef    = pre.caseRef
}

-- releaseWrites: the version an admitted [Release] leaves over the hold it found: the hold
-- the call names, still active, stood in released with the release fields stamped.
pred releaseWrites[pre : Hold, c : ReleaseCall, h : Hold] {
    c.holdIdIn = pre.holdId                            -- the hold named (Operation 13)
    Released not in pre.state                          -- Operation 14
    nonBlank[c.releasedByIn]                           -- Operation 15
    nonBlank[c.releaseReasonIn]                        -- Operation 16
    no c.releasedAtIn or c.releasedAtIn <= c.now       -- Operation 18, 41
    not (resolved[c.releasedAtIn, c.now] < pre.placedAt)   -- Operation 17
    keepsPlacement[pre, h]
    h.state         = Released                         -- Operation 19
    h.releasedBy    = c.releasedByIn                   -- State 4
    h.releaseReason = c.releaseReasonIn
    h.releasedAt    = resolved[c.releasedAtIn, c.now]  -- Term resolved release instant
}

-- written: the version is what its call's write left: a [Place] over nothing, or a
-- [Release] over a version an earlier call wrote (a call finds only what was committed
-- before it, Execution Contract Database 2).
pred written[v : Hold] {
    let c = v.writtenBy, pre = v.found {
        (c in PlaceCall and no pre and placeWrites[c, v])
        or (c in ReleaseCall and some pre and releaseWrites[pre, c, v])
    }
}

-- recorded: a version the page lets the records hold (see SCOPE): its chain ends at a
-- placement, and it and every version it was built from are what an admitted call wrote.
pred recorded[h : Hold] {
    some originOf[h]
    all v : h.*found | written[v]
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Assertions (verified guarantees)
-- Each "check" asks: is there any hold record the page's calls can leave that violates
-- this assertion? No counterexample (UNSAT) = the guarantee holds within scope.
-- ─────────────────────────────────────────────────────────────────────────────

-- A_Invariant_1_1: every placement field of a hold — hold id, record reference, placing
-- actor, hold reason, placement instant, case reference — is the one its [Place] recorded,
-- however many calls came after.
assert A_Invariant_1_1 {
    all h : Hold | recorded[h] implies all o : originOf[h] {
        h.holdId     = o.holdId
        h.recordRef  = o.recordRef
        h.placedBy   = o.placedBy
        h.holdReason = o.holdReason
        h.placedAt   = o.placedAt
        h.caseRef    = o.caseRef
    }
}
check A_Invariant_1_1 for 4 but 4 Int

-- A_Invariant_1_2: a released hold's releasing actor, release reason and release instant
-- are the ones the release that ended it recorded; nothing after it rewrites them.
assert A_Invariant_1_2 {
    all h : Hold | (recorded[h] and Released in h.state) implies all r : firstRelease[h] {
        h.releasedBy    = r.releasedBy
        h.releaseReason = r.releaseReason
        h.releasedAt    = r.releasedAt
    }
}
check A_Invariant_1_2 for 4 but 4 Int

-- A_Invariant_2_1: every hold stands in exactly one state. [Place] stands it active and
-- [Release] replaces the state with released.
assert A_Invariant_2_1 {
    all h : Hold | recorded[h] implies one h.state
}
check A_Invariant_2_1 for 4 but 4 Int

-- A_Invariant_3_1: a hold any earlier version of which stood released does not stand in
-- active: released is terminal (Check 5.1).
assert A_Invariant_3_1 {
    all h : Hold | (recorded[h] and some v : h.^found | Released in v.state)
        implies Active not in h.state
}
check A_Invariant_3_1 for 4 but 4 Int

-- A_Invariant_4_2: a released hold was stood in released by a [Release] that named its own
-- hold id, not by a release of another hold over the same record (Non-goal 10, Operation 20).
assert A_Invariant_4_2 {
    all h : Hold | (recorded[h] and Released in h.state) implies all r : firstRelease[h] {
        r.writtenBy in ReleaseCall
        r.writtenBy.holdIdIn = h.holdId
    }
}
check A_Invariant_4_2 for 4 but 4 Int

-- A_Invariant_5_1: a released hold carries a releasing actor that is not blank (Check 3.1).
assert A_Invariant_5_1 {
    all h : Hold | (recorded[h] and Released in h.state) implies nonBlank[h.releasedBy]
}
check A_Invariant_5_1 for 4 but 4 Int

-- A_Invariant_5_2: a released hold carries a release reason that is not blank (Check 3.1).
assert A_Invariant_5_2 {
    all h : Hold | (recorded[h] and Released in h.state) implies nonBlank[h.releaseReason]
}
check A_Invariant_5_2 for 4 but 4 Int

-- A_Invariant_5_3: a released hold carries its release instant (Check 3.2), whether the
-- caller supplied one or left it blank.
assert A_Invariant_5_3 {
    all h : Hold | (recorded[h] and Released in h.state) implies one h.releasedAt
}
check A_Invariant_5_3 for 4 but 4 Int

-- A_Invariant_6_1: no released hold's release instant precedes its placement instant
-- (Check 3.3), whatever instants the callers supplied and whatever the clock read.
assert A_Invariant_6_1 {
    all h : Hold | (recorded[h] and Released in h.state and one h.releasedAt and one h.placedAt)
        implies h.releasedAt >= h.placedAt
}
check A_Invariant_6_1 for 4 but 4 Int

-- A_Invariant_7_1: every hold carries a placing actor that is not blank (Check 2.1).
assert A_Invariant_7_1 {
    all h : Hold | recorded[h] implies nonBlank[h.placedBy]
}
check A_Invariant_7_1 for 4 but 4 Int

-- A_Invariant_7_2: every hold carries a hold reason that is not blank (Check 2.1).
assert A_Invariant_7_2 {
    all h : Hold | recorded[h] implies nonBlank[h.holdReason]
}
check A_Invariant_7_2 for 4 but 4 Int

-- A_Invariant_7_3: every hold carries its placement instant (Check 2.2), whether the
-- caller supplied one or left it blank.
assert A_Invariant_7_3 {
    all h : Hold | recorded[h] implies one h.placedAt
}
check A_Invariant_7_3 for 4 but 4 Int

-- A_State_5: an active hold carries no releasing actor, release reason or release
-- instant, so no reading of the stored fields takes an active hold for an ended one (Term
-- held at an instant).
assert A_State_5 {
    all h : Hold | (recorded[h] and Active in h.state) implies {
        no h.releasedBy
        no h.releaseReason
        no h.releasedAt
    }
}
check A_State_5 for 4 but 4 Int

-- A_Operation_4: every hold carries a record reference that is not blank (Check 2.3).
assert A_Operation_4 {
    all h : Hold | recorded[h] implies nonBlank[h.recordRef]
}
check A_Operation_4 for 4 but 4 Int

-- A_Operation_7: a hold carries no case reference, or one that is not blank: an empty
-- string never stands in for "no matter yet".
assert A_Operation_7 {
    all h : Hold | recorded[h] implies (no h.caseRef or h.caseRef not in Blank)
}
check A_Operation_7 for 4 but 4 Int

-- A_Instance_2: two holds placed by different [Place] calls never share a hold id — two
-- holds over one record included (Identity 8, Concurrency 3).
assert A_Instance_2 {
    all h1, h2 : Hold | (recorded[h1] and recorded[h2] and originCall[h1] != originCall[h2])
        implies h1.holdId != h2.holdId
}
check A_Instance_2 for 4 but 4 Int

-- ─────────────────────────────────────────────────────────────────────────────
-- Satisfiability runs — non-vacuity guards, one for each shape the page admits
-- Each run must find at least one instance (SAT).
-- UNSAT means the model forbids a hold record the page admits.
-- ─────────────────────────────────────────────────────────────────────────────

-- ShowPlacedUnderCase: a hold just placed under a legal matter (the litigation trigger of
-- the happy path).
run ShowPlacedUnderCase {
    some h : Hold | recorded[h] and h.writtenBy in PlaceCall and some h.caseRef
} for 4 but 4 Int

-- ShowPlacedWithoutCase: a hold placed where no formal matter exists yet (State 3).
run ShowPlacedWithoutCase {
    some h : Hold | recorded[h] and h.state = Active and no h.caseRef
} for 4 but 4 Int

-- ShowBackdatedPlacement: a hold whose placement instant the caller set below now
-- (Operation 10, Backdating 1).
run ShowBackdatedPlacement {
    some h : Hold | recorded[h] and h.writtenBy in PlaceCall and h.placedAt < h.writtenBy.now
} for 4 but 4 Int

-- ShowReleased: a hold released, its release fields stamped (the settlement).
run ShowReleased {
    some h : Hold | recorded[h] and h.state = Released
} for 4 but 4 Int

-- ShowReleasedAtThePlacementInstant: a release instant equal to the placement instant,
-- which Invariant 6.1 admits.
run ShowReleasedAtThePlacementInstant {
    some h : Hold | recorded[h] and h.state = Released and h.releasedAt = h.placedAt
} for 4 but 4 Int

-- ShowBackdatedRelease: a release whose instant the caller set below now, still at or
-- after the placement (Operation 39).
run ShowBackdatedRelease {
    some h : Hold | recorded[h] and h.writtenBy in ReleaseCall
        and h.releasedAt < h.writtenBy.now
} for 4 but 4 Int

-- ShowTwoHoldsOneRecord: two holds over one record under two hold ids, one released and
-- one still active (the dual regulatory investigation; Concurrency 3, Invariant 4).
run ShowTwoHoldsOneRecord {
    some disj h1, h2 : Hold | recorded[h1] and recorded[h2]
        and originCall[h1] != originCall[h2] and h1.recordRef = h2.recordRef
        and h1.state = Released and h2.state = Active
} for 4 but 4 Int
