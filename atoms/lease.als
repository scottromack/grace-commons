-- lease.als
-- Alloy structural model for the Lease atom (Grace Commons atoms/lease.md)
-- Grounded on Final Critique 4, 2026-10-04 at 46804b7 — Alloy layer authored 2026-11-12.
-- Derived validator; the English spec is the single source of truth. On any
-- disagreement, diagnose per the entry *The conflict protocol* in pressure-testing.md.
--
-- PURPOSE
-- Verify, by bounded exhaustive search, the STATIC data model of a lease: what the one
-- lease state the host holds for a key must be, whatever call last wrote it, what the host
-- derives from that state at one reading of its clock (State 2), what [Take], [Try Take],
-- [Remaining] and [Release] answer from it, and what instant a holder may hand a fenced
-- party. Everything that happens across steps (two takes in turn, a grant's end as an
-- event, a waiter's bound from its arrival to its answer, a write landing after the next
-- holder has read) is the TLA+ model's, lease.tla, which owns the operation sequences.
--
-- INVARIANTS ENCODED (named by the page's own labels)
--   Invariant 1.1 — the key stands in exactly one of free, held by one holder: one lease
--                   state stored, and at most one grant standing at any reading.
--   Invariant 2.1 — read at one reading: a grant whose instant has passed stands no more.
--   Invariant 2.2 — read at one reading: a grant whose instant has not passed stands,
--                   whatever else is so (what the holder reads of its own margin included).
--   Invariant 3.1 — no answer the host gives depends on a belief that a holder has died.
--   Invariant 3.2 — no grant ends early on a belief that its holder has died.
--   Invariant 5.1 — [Remaining] and [Release] answer against the (key, holder) pair as the
--                   host holds it at the reading.
--   Invariant 6.1 — every instant handed to a fenced party carries that party's allowance
--                   subtracted.
--   Invariant 6.2 — every handed instant is minted independently: no one minted instant
--                   is handed to two parties.
-- Invariant 1, 2, 3.2 and 6.1 are checked by lease.tla too (Inv_OneHolder, Inv_Terminus,
-- the death and fence twins), spelled the same way, so the two models cross-check them.
--
-- NOT CHECKED HERE (nothing testable in Alloy; the TLA+ model's)
--   Invariant 1.2 (two takes with no release and no expiry between them do not both
--   succeed): it orders two takes; one state shows only the grant the later one left.
--   Invariant 2.1's release arm and its "exactly one": a grant's end is a step, and a
--   release stores free (Operation 11), so one state cannot show which ended it.
--   Invariant 4.1 and 4.2 (a waiter's bound stands as set at arrival; admitting an earlier
--   waiter does not extend a later one's): each compares a waiter's bound with an earlier
--   one, and the host holds a waiter with its bound alone (State 4), so one state cannot
--   show what was set at the arrival.
--
-- SCOPE
-- One key. Its lease state is built from the record the call found, back to the key never
-- taken (free): a successful take stands it held by the asking holder until the host's
-- reading plus the duration (Operation 2a, 2b, Term expires_at); a release by the holder
-- stands it free (Operation 11, 11a); a passed instant stores nothing (State 3), and a
-- release answered not-held writes nothing (Check 5.2). [Take] and [Try Take] write the
-- same record when they succeed (Term successful take), so one call shape stands for both.
-- The model does not ask whether the record a call found was still the latest one (that is
-- the sequence, the TLA+ model's), so it builds every record a state can hold and some no
-- state reaches; a check that holds over all of them holds over the records. Readings,
-- instants, durations and allowances are small integers. A World is what a party may
-- believe about the holders at a reading (which ones have died); the host is told it or
-- not, and the page says what it must not do with it.
--
-- NOT MODELED HERE
--   - The line of waiters (State 4, Operation 1, 2, 3 to 5c): a waiter's bound and its
--     admission are across steps, and a waiter standing at a free key is admitted at that
--     reading (Operation 2), so a record here has no waiter beside a free key; [Take]
--     succeeds where the key reads free (Operation 1a, 6a, 6c with no waiter standing).
--   - A second key and byte identity (Identity 1 to 4): a call names one key, and a write
--     to one key leaving another is across steps.
--   - The holder's freshness and restarts (Identity 6, 7, Operation 5c, Capability
--     requirement 5, 11): across steps.
--   - The sizing (Sizing 1 to 9) beyond the live reading: a unit of work, the share term
--     and the no-answer arm are spans of the holder's own work, which the composing
--     patterns carry; the live reading's margin appears in one run below. Sizing 2, 3 and
--     3a are lease.tla's.
--   - What the fenced party does (Fence 3, 4, 4a, 6, 10): the deployment's (Capability
--     requirement 6), and a judgment at a moment of its own clock.
--
-- HOW TO READ RESULTS
-- Every "check A_*" must return "No counterexample found" (UNSAT) — the asserted guarantee holds.
-- Every "run Show*" must return at least one instance (SAT) — confirms non-vacuity.
-- A "check" returning a counterexample is a spec finding.

module lease

open util/ordering[Call] as C

-- ─────────────────────────────────────────────────────────────────────────────
-- Signatures (types)
-- ─────────────────────────────────────────────────────────────────────────────

-- Holder: the opaque value naming one take's holder (Term holder), compared by byte
-- identity (Identity 4), so an uninterpreted token here.
sig Holder {}

-- Party: a fenced party (Term fenced party), the third party a fence is handed to. Its
-- allowance is the cross-seam allowance the deployment declares for it (Capability
-- requirement 3, Term allowance): one per fenced party.
sig Party {
    allowance : one Int
}

-- Pattern: the composing pattern, which declares the call pause bound (Sizing 1, Term
-- call pause bound). Twice it is the write margin (Term write margin), by which a holder
-- reads its own lease live or expired.
one sig Pattern {
    callPauseBound : one Int
}

-- World: what is believed about the holders at a reading — here, which of them have died.
-- Nothing in the atom observes a death (Invariant 3), so this is the world's, not the
-- host's; it is here so that a host that acted on it would show.
sig World {
    believedDead : set Holder
}

-- LeaseState: the lease state's values (Term lease state): free, or a grant — held by one
-- holder until one instant (Term grant, Term expires_at).
abstract sig LeaseState {}
one sig Free extends LeaseState {}
sig Grant extends LeaseState {
    holder    : one Holder,   -- the holder the host holds the key for (Term the holder)
    expiresAt : one Int       -- expires_at, on the granting host's clock (Fence 1)
}

-- Call: a write the host is asked for, at the host's reading (Term host's reading), in a
-- world. Calls are ordered so that a record is built only from one an earlier call wrote.
abstract sig Call {
    reading : one Int,     -- the host's reading at the call
    world   : one World    -- what is believed about the holders when the call arrives
}

-- TakeCall: a [Take] or a [Try Take] (Term successful take: either one that succeeds
-- writes the same record), asking for the key for a holder and a duration.
sig TakeCall extends Call {
    asker    : one Holder,  -- the holder value the caller minted for this take
    duration : one Int      -- the duration the take asks for
}

-- ReleaseCall: a [Release], by the party naming itself as holder (Term asking party).
sig ReleaseCall extends Call {
    asker : one Holder
}

-- LeaseRecord: one version of the key's lease state (State 1), as the call that wrote it
-- left it. The state is a SET of lease state values, so a write that added a value beside
-- the one it found, instead of replacing it, would show: what the page promises (exactly
-- one) is checked, never built into the type. The last two fields are the model's own:
-- which call wrote this version (none for the key never taken), and which version it found.
sig LeaseRecord {
    state     : set LeaseState,
    writtenBy : lone Call,
    found     : lone LeaseRecord
}

-- ReleaseAnswer: what [Release] answers (the signature block): released or not-held.
abstract sig ReleaseAnswer {}
one sig Released, NotHeld extends ReleaseAnswer {}

-- Fence: an instant a holder mints from the expires_at its take returned (Fence 1, 2) for
-- one fenced party, to hand that party as a deadline (Term fence).
sig Fence {
    grant     : one Grant,   -- the grant whose expires_at it is minted from
    mintedFor : one Party,   -- the fenced party it is minted for
    value     : one Int      -- the instant
}

-- Handing: one instant a holder hands one fenced party (Fence 2, Invariant 6.1).
sig Handing {
    fence    : one Fence,
    handedTo : one Party
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Facts: what the page takes from outside
-- ─────────────────────────────────────────────────────────────────────────────

-- A caller takes only for a duration that exceeds zero (Composition note 5e): the caller's
-- obligation, which the host receives.
fact TakesAskForAPositiveDuration {
    all c : TakeCall | c.duration > 0
}

-- Arithmetic is exact (Execution Contract Logic confinement 9): the host's reading plus a
-- positive duration lands after the reading. Alloy's integers wrap at the scope's
-- bitwidth; this keeps the takes to the ones whose sum the model computes without wrapping.
fact ArithmeticIsExact {
    all c : TakeCall | plus[c.reading, c.duration] > c.reading
}

-- ─────────────────────────────────────────────────────────────────────────────
-- What the host derives at a reading, and what it answers
-- ─────────────────────────────────────────────────────────────────────────────

-- standing: the grants the host derives as standing at a reading (State 2): a stored grant
-- whose instant the reading precedes. The key is free at the reading that equals
-- expires_at (Term passed instant), and nothing else the host reads (the world included)
-- enters the derivation (Invariant 2.2).
fun standing[x : LeaseRecord, r : Int, w : World] : set Grant {
    { g : x.state & Grant | r < g.expiresAt }
}

-- takeSucceeds: a [Take] or [Try Take] at the reading succeeds — the key reads free there
-- (Operation 1a, 6a); where a grant stands, [Try Take] answers held (Operation 6b) and
-- [Take] waits (Operation 1).
pred takeSucceeds[x : LeaseRecord, r : Int, w : World] {
    no standing[x, r, w]
}

-- remaining: what [Remaining] answers the asking holder at the reading: the part of the
-- holder's term not yet elapsed, as the host reads it (Operation 8, Term remaining term),
-- or nothing — none — where the asking party is not the holder (Operation 9).
fun remaining[x : LeaseRecord, r : Int, h : Holder, w : World] : set Int {
    { t : Int | some g : standing[x, r, w] | g.holder = h and t = minus[g.expiresAt, r] }
}

-- releaseAnswer: what [Release] answers the asking party at the reading: released where it
-- is the holder (Operation 11a), not-held where it is not (Operation 12).
fun releaseAnswer[x : LeaseRecord, r : Int, h : Holder, w : World] : one ReleaseAnswer {
    h in standing[x, r, w].holder => Released else NotHeld
}

-- readsLive: what the holder reads of the host's answer (Sizing 2, 2a, Term live): live
-- where the remaining term exceeds the write margin, twice the call pause bound. It is a
-- reading the holder acts on, never a transition the host makes (Term expired).
pred readsLive[x : LeaseRecord, r : Int, h : Holder, w : World] {
    some t : remaining[x, r, h, w] | t > plus[Pattern.callPauseBound, Pattern.callPauseBound]
}

-- ─────────────────────────────────────────────────────────────────────────────
-- The writes, and the records they can leave
-- ─────────────────────────────────────────────────────────────────────────────

-- takeWrites: the record a successful take leaves over the record it found. The key stands
-- held by the asking holder (Operation 2a) until the host's reading at the success plus
-- the duration (Operation 2b, Term expires_at).
pred takeWrites[pre : LeaseRecord, c : TakeCall, post : LeaseRecord] {
    takeSucceeds[pre, c.reading, c.world]                          -- Operation 1a, 6a
    some g : Grant {
        g.holder    = c.asker                                      -- Operation 2a
        g.expiresAt = plus[c.reading, c.duration]                  -- Operation 2b
        post.state  = g                                            -- Operation 2a, State 1
    }
}

-- releaseWrites: the record a release answered released leaves: the holder's grant ends
-- (Operation 11). A release answered not-held writes nothing (Check 5.2), so it leaves no
-- new record.
pred releaseWrites[pre : LeaseRecord, c : ReleaseCall, post : LeaseRecord] {
    releaseAnswer[pre, c.reading, c.asker, c.world] = Released     -- Operation 11a, 12
    post.state = Free                                              -- Operation 11
}

-- neverTaken: the key before any take: free, written by no call.
pred neverTaken[x : LeaseRecord] {
    no x.writtenBy
    no x.found
    x.state = Free
}

-- written: the record is the key never taken, or what its call's write left over a record
-- an earlier call wrote (or the key never taken).
pred written[x : LeaseRecord] {
    neverTaken[x]
    or (one x.writtenBy and one x.found
        and (no x.found.writtenBy or C/lt[x.found.writtenBy, x.writtenBy])
        and (x.writtenBy in TakeCall implies takeWrites[x.found, x.writtenBy, x])
        and (x.writtenBy in ReleaseCall implies releaseWrites[x.found, x.writtenBy, x]))
}

-- recorded: a record the page lets the host hold (see SCOPE): it and every version it was
-- built from are what an admitted call wrote.
pred recorded[x : LeaseRecord] {
    all v : x.*found | written[v]
}

-- ─────────────────────────────────────────────────────────────────────────────
-- What a holder mints and hands a fenced party
-- ─────────────────────────────────────────────────────────────────────────────

-- minted: the holder mints the fence from the expires_at a successful take returned
-- (Fence 1), for one fenced party, no later than that party's fence ceiling, expires_at
-- less its allowance (Fence 5, Term fence ceiling).
pred minted[f : Fence] {
    some x : LeaseRecord | recorded[x] and f.grant in x.state                -- Fence 1
    f.value <= minus[f.grant.expiresAt, f.mintedFor.allowance]               -- Fence 5
}

-- handed: the holder hands a party the fence it minted for that party (Fence 8: every
-- fence minted separately), never a fence minted for another, handed on bare (Fence 9).
pred handed[h : Handing] {
    minted[h.fence]
    h.handedTo = h.fence.mintedFor                                           -- Fence 8, 9
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Assertions (verified guarantees)
-- Each "check" asks: is there any record the page's calls can leave, or any instant a
-- holder can hand, that violates this assertion? No counterexample (UNSAT) = the
-- guarantee holds within scope.
-- ─────────────────────────────────────────────────────────────────────────────

-- A_Invariant_1_1: the key stands in exactly one of free, held by one holder. The host
-- stores one lease state (State 1), and at no reading do two grants stand.
assert A_Invariant_1_1 {
    all x : LeaseRecord | recorded[x] implies {
        one x.state
        all r : Int, w : World | lone standing[x, r, w]
    }
}
check A_Invariant_1_1 for 3 but 5 Int

-- A_Invariant_2_1: a grant ends at its instant. At every reading the instant does not
-- follow — the reading that equals it included (Term passed instant) — the grant stands no
-- more, though the host stored no transition (State 3). Check 2.1.
assert A_Invariant_2_1 {
    all x : LeaseRecord, g : Grant, r : Int, w : World |
        (recorded[x] and g in x.state and r >= g.expiresAt) implies g not in standing[x, r, w]
}
check A_Invariant_2_1 for 3 but 5 Int

-- A_Invariant_2_2: the host ends a grant on no other event. At every reading that precedes
-- its instant the grant stands, whatever the world believes and whatever the holder reads
-- of its own margin (Term expired: never a transition the host makes). Check 2.2, 3.1.
assert A_Invariant_2_2 {
    all x : LeaseRecord, g : Grant, r : Int, w : World |
        (recorded[x] and g in x.state and r < g.expiresAt) implies g in standing[x, r, w]
}
check A_Invariant_2_2 for 3 but 5 Int

-- A_Invariant_3_1: the atom reports no holder's death. Every answer the host gives at a
-- reading — whether a take succeeds, what [Remaining] answers, what [Release] answers — is
-- the same whatever is believed about which holders have died.
assert A_Invariant_3_1 {
    all x : LeaseRecord, r : Int, h : Holder, w1, w2 : World | recorded[x] implies {
        takeSucceeds[x, r, w1] iff takeSucceeds[x, r, w2]
        remaining[x, r, h, w1] = remaining[x, r, h, w2]
        releaseAnswer[x, r, h, w1] = releaseAnswer[x, r, h, w2]
    }
}
check A_Invariant_3_1 for 3 but 5 Int

-- A_Invariant_3_2: no grant ends early on a belief that its holder has died. Before its
-- instant, whether a grant stands is the same whatever is believed about the holders.
-- Check 3.2: whatever the host knows about the holder.
assert A_Invariant_3_2 {
    all x : LeaseRecord, g : Grant, r : Int, w1, w2 : World |
        (recorded[x] and g in x.state and r < g.expiresAt) implies
            (g in standing[x, r, w1] iff g in standing[x, r, w2])
}
check A_Invariant_3_2 for 3 but 5 Int

-- A_Invariant_5_1: [Remaining] and [Release] answer against the (key, holder) pair as the
-- host holds it at the reading. The asking party gets a remaining term, and released,
-- exactly where it is the holder of the grant that stands; the term is that grant's
-- expires_at less the reading. A former holder whose term has passed is answered none
-- and not-held (Check 5.1).
assert A_Invariant_5_1 {
    all x : LeaseRecord, r : Int, h : Holder, w : World | recorded[x] implies {
        some remaining[x, r, h, w] iff h in standing[x, r, w].holder
        releaseAnswer[x, r, h, w] = Released iff h in standing[x, r, w].holder
        all g : standing[x, r, w] | g.holder = h implies
            remaining[x, r, h, w] = minus[g.expiresAt, r]
    }
}
check A_Invariant_5_1 for 3 but 5 Int

-- A_Invariant_6_1: every instant handed to a party judging on another clock carries that
-- party's allowance subtracted: it is no later than expires_at less the allowance of the
-- party it is handed to (Check 6.1: the allowance does not exceed the fence margin).
assert A_Invariant_6_1 {
    all h : Handing | handed[h] implies
        h.fence.value <= minus[h.fence.grant.expiresAt, h.handedTo.allowance]
}
check A_Invariant_6_1 for 3 but 5 Int

-- A_Invariant_6_2: the holder mints every such instant independently: no one minted
-- instant is handed to two fenced parties (Check 6.2: minted with the allowance, not
-- inheriting another party's).
assert A_Invariant_6_2 {
    all disj h1, h2 : Handing | (handed[h1] and handed[h2] and h1.handedTo != h2.handedTo)
        implies h1.fence != h2.fence
}
check A_Invariant_6_2 for 3 but 5 Int

-- ─────────────────────────────────────────────────────────────────────────────
-- Satisfiability runs — non-vacuity guards, one for each shape the page admits
-- Each run must find at least one instance (SAT).
-- UNSAT means the model forbids a record the page admits.
-- ─────────────────────────────────────────────────────────────────────────────

-- ShowHeld: a take has stood the key held, and at a reading before its instant the grant
-- stands and a second take does not succeed (Operation 6b).
run ShowHeld {
    some x : LeaseRecord, r : Int, w : World |
        recorded[x] and x.writtenBy in TakeCall and some standing[x, r, w]
        and not takeSucceeds[x, r, w]
} for 3 but 5 Int

-- ShowReleasedBeforeTheInstant: the holder releases before its instant and the key stands
-- free (Operation 11): the release arm of Invariant 2.1.
run ShowReleasedBeforeTheInstant {
    some x : LeaseRecord |
        recorded[x] and x.writtenBy in ReleaseCall and x.state = Free
        and (some g : x.found.state & Grant | x.writtenBy.reading < g.expiresAt)
} for 3 but 5 Int

-- ShowFreeAtTheInstant: at the reading that equals expires_at the key reads free and a take
-- succeeds, the grant still stored (State 3, Term passed instant).
run ShowFreeAtTheInstant {
    some x : LeaseRecord, g : Grant, w : World |
        recorded[x] and g in x.state and takeSucceeds[x, g.expiresAt, w]
} for 3 but 5 Int

-- ShowNextHolderAfterTheInstant: a holder that never released; its instant passed and the
-- next holder took the key (Check 2.1, the dying-holder example).
run ShowNextHolderAfterTheInstant {
    some x : LeaseRecord |
        recorded[x] and x.writtenBy in TakeCall and x.found.writtenBy in TakeCall
        and x.found.state.holder != x.state.holder
} for 3 but 5 Int

-- ShowFormerHolderAnsweredNotHeld: a former holder whose term has passed asks; it is
-- answered none and not-held (Check 5.1).
run ShowFormerHolderAnsweredNotHeld {
    some x : LeaseRecord, g : Grant, r : Int, w : World |
        recorded[x] and g in x.state and r >= g.expiresAt
        and no remaining[x, r, g.holder, w] and releaseAnswer[x, r, g.holder, w] = NotHeld
} for 3 but 5 Int

-- ShowAnotherPartyAnsweredNotHeld: while the key is held, a party that is not the holder
-- asks to release it and is answered not-held (Operation 12, Check 5.1).
run ShowAnotherPartyAnsweredNotHeld {
    some x : LeaseRecord, r : Int, h : Holder, w : World |
        recorded[x] and some standing[x, r, w] and h not in standing[x, r, w].holder
        and releaseAnswer[x, r, h, w] = NotHeld
} for 3 but 5 Int

-- ShowRemainingAnswered: the holder asks what remains and is answered its term
-- (Operation 8).
run ShowRemainingAnswered {
    some x : LeaseRecord, r : Int, h : Holder, w : World |
        recorded[x] and some remaining[x, r, h, w]
} for 3 but 5 Int

-- ShowBelievedDeadStillHeld: a holder believed dead, its grant standing until its instant
-- (Invariant 3, the dying-holder example).
run ShowBelievedDeadStillHeld {
    some x : LeaseRecord, g : Grant, r : Int, w : World |
        recorded[x] and g.holder in w.believedDead and g in standing[x, r, w]
} for 3 but 5 Int

-- ShowHolderReadsExpiredWhileHeld: the holder's remaining term no longer exceeds the write
-- margin, so it reads its lease expired (Sizing 2a), while the host still holds the key for
-- it (Term expired: a reading the holder acts on, never a transition the host makes).
run ShowHolderReadsExpiredWhileHeld {
    some x : LeaseRecord, g : Grant, r : Int, w : World |
        recorded[x] and g in standing[x, r, w] and not readsLive[x, r, g.holder, w]
        and Pattern.callPauseBound > 0
} for 3 but 5 Int

-- ShowTwoPartiesFencedSeparately: a holder fencing two parties with different allowances
-- mints a fence for each (Fence 8; the database-fence example, with a second party).
run ShowTwoPartiesFencedSeparately {
    some disj h1, h2 : Handing |
        handed[h1] and handed[h2] and h1.handedTo != h2.handedTo
        and h1.handedTo.allowance != h2.handedTo.allowance
        and h1.fence.grant = h2.fence.grant
} for 3 but 5 Int

-- ShowFenceBeforeTheCeiling: a fence earlier than the fence ceiling, which the page admits
-- (Term fence: an instant no later than the fence ceiling).
run ShowFenceBeforeTheCeiling {
    some h : Handing |
        handed[h] and h.fence.value < minus[h.fence.grant.expiresAt, h.handedTo.allowance]
} for 3 but 5 Int
