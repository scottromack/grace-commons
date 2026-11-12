-- provisional-commitment.als
-- Alloy structural model for the Provisional Commitment atom (Grace Commons atoms/provisional-commitment.md)
-- Grounded on Final Critique 13, 2026-11-05 at 8adbf07 — Alloy layer authored 2026-11-11.
-- Derived validator; the English spec is the single source of truth. On any
-- disagreement, diagnose per the entry *The conflict protocol* in pressure-testing.md.
--
-- PURPOSE
-- Verify, by bounded exhaustive search, the STATIC data model of a commitment: what one
-- commitment record must carry, whatever admitted call last wrote it, and what the ids of
-- the commitments one database holds must satisfy among themselves. Everything that
-- happens across steps (a terminal state never left, a property never changed, no
-- commitment removed) is the TLA+ model's, provisional-commitment.tla, which owns the
-- operation sequences.
--
-- RULES ENCODED (named by the page's own labels)
--   Invariant 1.1 — every commitment stands in exactly one of held, confirmed, released, expired.
--   Invariant 2.2 — no commitment carries two terminal instants.
--   Invariant 6.1 — no degenerate window: the expiry instant exceeds the placement instant.
--   Invariant 7.1 — no late resolution: a confirmed (released) commitment's expiry instant
--                   exceeds its confirmation (release) instant.
--   Invariant 7.2 — no premature expiry: an expired commitment's lapse instant does not
--                   precede its expiry instant.
--   Invariant 7.3 — every held commitment reads exactly one of open, lapsed, at every now.
--   Invariant 8.1 — a confirmation instant does not precede the placement instant.
--   Invariant 8.2 — a release instant does not precede the placement instant.
-- Beyond the Invariants, the rules the page's Conformance checks test on one state:
--   State 1    — every commitment carries id, resource, requester, placement instant,
--                expiry instant and a state (Check 7.1, 7.2).
--   State 2    — every confirmed commitment carries a confirmation instant (Check 1.2).
--   State 3    — every released commitment carries a release instant (Check 1.2).
--   State 4    — every expired commitment carries a lapse instant (Check 1.2).
--   State 5    — a held commitment carries no terminal instant (Check 1.3).
--   Identity 5 — two commitments do not share an id (Check 5.2).
-- Invariant 7.1 and 8.1/8.2 are checked by provisional-commitment.tla too
-- (Inv_ConfirmWithinWindow, Inv8_TransitionsAfterPlacement), spelled the same way, so the
-- two models cross-check them.
--
-- NOT CHECKED HERE (nothing testable in Alloy; the TLA+ model's)
--   Invariant 2.1 (a commitment never REACHES two terminal states: a history, which the
--   TLA+ model's Inv_SingleResolution checks; its single-state trace is Invariant 2.2,
--   checked here), Invariant 3.1 (a terminal state never left), Invariant 5.1 (an admitted
--   resolving action changes no property) and Invariant 10.1 (no commitment removed):
--   each compares a record with a later version of it, and the page keeps no earlier
--   version beside the record, so one state cannot show it. The writes below are built to
--   keep each of them (a resolve copies the properties it found); that they do is the
--   TLA+ model's to check.
--
-- SCOPE
-- A commitment version is what one admitted call leaves: [Place Hold] records a held
-- commitment (Operation 8 to 12); [Confirm], [Release] and [Expire] stand it in their
-- terminal state and stamp now as their instant (Operation 21 to 26). Each version is built
-- from the version its call found, back to the [Place Hold] that recorded it, so a
-- version a twin lets two resolves write is built too. The model does not ask whether the
-- version a call found was still the latest one (that is the sequence, the TLA+ model's),
-- so it builds every record a state can hold and some no state reaches; a check that
-- holds over all of them holds over the records. No trace, no `var`, no stepping.
-- Calls commit in one order (Execution Contract Database, cited by Capability requirement
-- 15), the order `C` gives them; each carries now, the clock reading at the call (Term now).
-- Instants and durations are integers (the window bound is a sum, Execution Contract Logic
-- confinement 9). References are uninterpreted strings; a string in Blank is whitespace-only
-- (String 5), and an absent input reads as blank (String 6).
-- Scope: for 4 but 3 Commitment, 3 Call (three versions and three calls: a place and two
-- resolves, or two commitments on one resource; four strings; integers of bitwidth 4, -8
-- through 7). At four versions and four calls the correct model takes about 4 s, but the
-- twin that drops Operation 15 takes minutes (unbounded resolve chains), so the scope is
-- the smallest that holds every shape the runs and twins need; for 5 but 5 Int was run
-- once on a copy, with the same verdicts.
--
-- NOT MODELED HERE
--   - The registry (Operation 5, 42, Concurrency 3, Capability requirement 3, 4, 10, 11,
--     16 to 20): its verdict decides whether a [Place Hold] is admitted, never what an
--     admitted one writes, and availability is not the atom's (Non-goal 11).
--   - [Read] (Operation 38 to 41): a read writes nothing (Operation 40), so it adds no record.
--   - Which refusal answers (Execution Contract Refusal 1), storage failure and a refused
--     call's footprint (Operation 30, 31): a refused call writes nothing, so the model needs
--     only whether a call is admitted.
--   - The string cap and the whole-seconds form of a duration (Execution Contract Input 1,
--     2): a length and a type, not a shape.
--   - The expire cadence, reclamation window, run and restart bounds (Capability
--     requirement 7, 8, 12, 24 to 26): a deployment's declarations and its timing.
--   - The signatures of the resolving actions (Operation 33 to 35) and the surfaces the
--     atom does not offer (State 8 to 11): what a call can carry, not what a record holds.
--
-- HOW TO READ RESULTS
-- Every "check A_*" must return "No counterexample found" (UNSAT) — the asserted guarantee holds.
-- Every "run Show*" must return at least one instance (SAT) — confirms non-vacuity.
-- A "check" returning a counterexample is a spec finding.

module provisional_commitment

open util/ordering[Call] as C

-- ─────────────────────────────────────────────────────────────────────────────
-- Signatures (types)
-- ─────────────────────────────────────────────────────────────────────────────

-- Str: a reference a call carries or a record holds — a resource, a requester, or an id.
-- The atom compares references byte-exactly and never interprets them (Identity 8 to 11,
-- String 1 to 4), so a reference is an uninterpreted token.
sig Str {}

-- Blank: the strings the atom reads as blank, the whitespace-only ones (String 5). Which
-- strings these are is the world's, not the atom's, so it is a subset with no rule on it.
sig Blank in Str {}

-- State: the four states of a commitment (Term value sets); confirmed, released and expired
-- are the terminal ones (Term terminal state).
abstract sig State {}
one sig Held, Confirmed, Released, Expired extends State {}

-- DeclaredBounds: the duration bounds, where the deployment declares them (Capability
-- requirement 22): the set of durations it admits. Absent, the page's default holds:
-- every duration exceeding zero (Term duration bounds).
lone sig DeclaredBounds {
    admits : set Int
}

-- Call: one call of a writing action as it reaches the seam. Calls commit in one order,
-- the order `C` gives them; `now` is the clock reading the host injects for the call
-- (Capability requirement 1, Term now).
abstract sig Call {
    now : one Int
}

-- PlaceCall: one [Place Hold] call, place_hold(resource, requester, duration), with the id
-- material the seam supplies for it (Term id material, Capability requirement 2).
sig PlaceCall extends Call {
    idMat       : one Str,    -- the id material
    resourceIn  : lone Str,   -- resource
    requesterIn : lone Str,   -- requester
    durIn       : lone Int    -- duration, a whole number of seconds
}

-- ResolveCall: one resolving action (Term resolving action), confirm(id), release(id) or
-- expire(id): the id it names is its only input (Operation 33 to 35).
abstract sig ResolveCall extends Call {
    idIn : lone Str           -- id
}
-- The three resolving actions.
sig ConfirmCall, ReleaseCall, ExpireCall extends ResolveCall {}

-- Commitment: one version of a commitment record (Term records), as the call that wrote it
-- left it. Every field the page names is here, and every one may be absent, so a write
-- that forgot one would show. The state is a set of state flags, so a write that ADDED a
-- state instead of replacing one would show: what the page promises (exactly one) is
-- checked, never built into the type. The last two fields are the model's own: which call
-- wrote this version, and which version of the same commitment that call found.
sig Commitment {
    id          : lone Str,         -- id (Identity 1)
    resource    : lone Str,         -- resource
    requester   : lone Str,         -- requester
    placedAt    : lone Int,         -- placement instant
    expiresAt   : lone Int,         -- expiry instant
    state       : set State,        -- the commitment's state (State 1)
    confirmedAt : lone Int,         -- confirmation instant
    releasedAt  : lone Int,         -- release instant
    lapsedAt    : lone Int,         -- lapse instant
    writtenBy   : one Call,         -- the call whose write left this version (model)
    found       : lone Commitment   -- the version of this commitment that call found (model)
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Facts: what the page takes from outside
-- ─────────────────────────────────────────────────────────────────────────────

-- The clock never goes backward over the calls' commit order: monotonicity is the
-- deployment's (Execution Contract Logic confinement 7, which the page's tombstones for
-- Capability requirement 13, 14 and Clock semantics 4, 5 cite). No guard of the page holds
-- Invariant 8.1 or 8.2 without it: a resolve stamps now and never compares it with the
-- placement instant.
fact ClockNeverGoesBackward {
    all c1, c2 : Call | C/lt[c1, c2] implies c1.now <= c2.now
}

-- The id material a [Place Hold] is given names no commitment of the database it commits
-- against (Capability requirement 23). Of two admitted place holds, the later commits
-- against a database holding the earlier's commitment, so their id material differs.
fact DeploymentSuppliesFreshIdMaterial {
    all disj a, b : PlaceCall | (placeAdmitted[a] and placeAdmitted[b]) implies a.idMat != b.idMat
}

-- Declared duration bounds admit only durations exceeding zero (Capability requirement 27).
fact DeclaredBoundsArePositive {
    all d : DeclaredBounds.admits | d > 0
}

-- Arithmetic is exact (Execution Contract Logic confinement 9): the window bound, a
-- placement instant plus a duration, lands later than the instant for a positive duration
-- and no later for any other. Alloy's integers wrap at the scope's bitwidth; this keeps the
-- calls to the ones whose sum the model computes without wrapping.
fact ArithmeticIsExact {
    all c : PlaceCall, d : c.durIn |
        (d > 0 implies plus[c.now, d] > c.now) and (d <= 0 implies plus[c.now, d] <= c.now)
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Helpers
-- ─────────────────────────────────────────────────────────────────────────────

-- Terminal: the terminal states (Term terminal state).
fun Terminal : set State { Confirmed + Released + Expired }

-- nonBlank: a string is present and not whitespace-only. An absent input reads as blank
-- (String 6).
pred nonBlank[x : lone Str] {
    some x and x not in Blank
}

-- inBounds: a duration is in the duration bounds: the declared set where the deployment
-- declares one, otherwise every duration exceeding zero (Term duration bounds).
pred inBounds[d : Int] {
    some DeclaredBounds implies d in DeclaredBounds.admits else d > 0
}

-- readsOpen: the window reading of a held commitment whose expiry instant exceeds now (Term open).
pred readsOpen[v : Commitment, n : Int] {
    Held in v.state and some v.expiresAt and v.expiresAt > n
}

-- readsLapsed: the window reading of a held commitment whose expiry instant does not exceed now;
-- the boundary instant, expiry instant equal to now, reads lapsed (Term lapsed).
pred readsLapsed[v : Commitment, n : Int] {
    Held in v.state and some v.expiresAt and v.expiresAt <= n
}

-- origin: the [Place Hold] call that recorded the commitment this version belongs to — the
-- writer of the first version along the chain of versions found. Versions with one origin
-- are one commitment; versions with two are two.
fun origin[v : Commitment] : set Call {
    { w : v.*found | no w.found }.writtenBy
}

-- ─────────────────────────────────────────────────────────────────────────────
-- [Place Hold]: its guards and its write
-- ─────────────────────────────────────────────────────────────────────────────

-- placeAdmitted: the guards of [Place Hold] admit the call (Term admitted place hold).
pred placeAdmitted[c : PlaceCall] {
    nonBlank[c.resourceIn]      -- Operation 1
    nonBlank[c.requesterIn]     -- Operation 2
    some c.durIn                -- Operation 3
    inBounds[c.durIn]           -- Operation 4
}

-- placeWrites: the record an admitted [Place Hold] leaves: the id from the id material, the
-- resource and requester, now as placement instant, the window bound (placement instant +
-- duration) as expiry instant, and the state held. It sets no terminal instant.
pred placeWrites[c : PlaceCall, v : Commitment] {
    placeAdmitted[c]
    v.id          = c.idMat                     -- Operation 8, Identity 2
    v.resource    = c.resourceIn                -- Operation 9
    v.requester   = c.requesterIn               -- Operation 9
    v.placedAt    = c.now                       -- Operation 10
    v.expiresAt   = plus[c.now, c.durIn]        -- Operation 11, Term window bound
    v.state       = Held                        -- Operation 12
    no v.confirmedAt
    no v.releasedAt
    no v.lapsedAt
}

-- ─────────────────────────────────────────────────────────────────────────────
-- The resolving actions: their guards and their writes
-- ─────────────────────────────────────────────────────────────────────────────

-- resolveAdmitted: the guards of a resolving action admit the call on the version it finds
-- (Term admitted resolving action). The id must name the commitment (Operation 14); the
-- commitment must not stand in a terminal state (Operation 15); [Confirm] and [Release]
-- are refused once it reads lapsed (Operation 17, 18), [Expire] while it reads open
-- (Operation 19).
pred resolveAdmitted[pre : Commitment, c : ResolveCall] {
    some c.idIn and c.idIn = pre.id                                   -- Operation 14
    no pre.state & Terminal                                           -- Operation 15
    c in ConfirmCall implies not readsLapsed[pre, c.now]               -- Operation 17
    c in ReleaseCall implies not readsLapsed[pre, c.now]               -- Operation 18
    c in ExpireCall  implies not readsOpen[pre, c.now]                 -- Operation 19
}

-- keepsProperties: the resolve leaves the id and every property as it found them (Identity
-- 4, Invariant 5.1; written so here, checked across steps by the TLA+ model).
pred keepsProperties[pre, post : Commitment] {
    post.id        = pre.id
    post.resource  = pre.resource
    post.requester = pre.requester
    post.placedAt  = pre.placedAt
    post.expiresAt = pre.expiresAt
}

-- confirmWrites: the record an admitted [Confirm] leaves over the version it found.
pred confirmWrites[pre : Commitment, c : ConfirmCall, post : Commitment] {
    post.state       = Confirmed                -- Operation 21
    post.confirmedAt = c.now                    -- Operation 24
    post.releasedAt  = pre.releasedAt
    post.lapsedAt    = pre.lapsedAt
}

-- releaseWrites: the record an admitted [Release] leaves over the version it found.
pred releaseWrites[pre : Commitment, c : ReleaseCall, post : Commitment] {
    post.state       = Released                 -- Operation 22
    post.releasedAt  = c.now                    -- Operation 25
    post.confirmedAt = pre.confirmedAt
    post.lapsedAt    = pre.lapsedAt
}

-- expireWrites: the record an admitted [Expire] leaves over the version it found.
pred expireWrites[pre : Commitment, c : ExpireCall, post : Commitment] {
    post.state       = Expired                  -- Operation 23
    post.lapsedAt    = c.now                    -- Operation 26
    post.confirmedAt = pre.confirmedAt
    post.releasedAt  = pre.releasedAt
}

-- resolveWrites: the record an admitted resolving action leaves over the version it finds.
pred resolveWrites[pre : Commitment, c : ResolveCall, post : Commitment] {
    resolveAdmitted[pre, c]
    keepsProperties[pre, post]
    c in ConfirmCall implies confirmWrites[pre, c, post]
    c in ReleaseCall implies releaseWrites[pre, c, post]
    c in ExpireCall  implies expireWrites[pre, c, post]
}

-- written: the version is what its call's write left: a [Place Hold] that found nothing,
-- or a resolving action over the version it found, which an earlier call wrote.
pred written[v : Commitment] {
    (v.writtenBy in PlaceCall and no v.found and placeWrites[v.writtenBy, v])
    or (v.writtenBy in ResolveCall and some v.found and C/lt[v.found.writtenBy, v.writtenBy]
        and resolveWrites[v.found, v.writtenBy, v])
}

-- recorded: a version the page lets a commitment hold (see SCOPE): every version along its
-- chain, back to the [Place Hold] that recorded it, is what its call wrote.
pred recorded[v : Commitment] {
    all w : v.*found | written[w]
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Assertions (verified guarantees)
-- Each "check" asks: is there any record the page's calls can leave that violates this
-- assertion? No counterexample (UNSAT) = the guarantee holds within scope.
-- ─────────────────────────────────────────────────────────────────────────────

-- A_Invariant_1_1: every commitment stands in exactly one of the four states. [Place Hold]
-- stands it held and each resolve replaces the state with its own terminal one.
assert A_Invariant_1_1 {
    all v : Commitment | recorded[v] implies one v.state
}
check A_Invariant_1_1 for 4 but 3 Commitment, 3 Call

-- A_Invariant_2_2: no commitment carries two terminal instants: a commitment resolved once
-- carries the one instant its resolve stamped. A second resolve is refused not-held
-- (Operation 15), so no second instant is stamped.
assert A_Invariant_2_2 {
    all v : Commitment | recorded[v] implies {
        not (some v.confirmedAt and some v.releasedAt)
        not (some v.confirmedAt and some v.lapsedAt)
        not (some v.releasedAt and some v.lapsedAt)
    }
}
check A_Invariant_2_2 for 4 but 3 Commitment, 3 Call

-- A_Invariant_6_1: no degenerate window: every commitment's expiry instant exceeds its
-- placement instant. The window bound is the placement instant plus a duration the bounds
-- admit (Operation 4, 11), and every admitted duration exceeds zero (Term duration bounds,
-- Capability requirement 27).
assert A_Invariant_6_1 {
    all v : Commitment | recorded[v] implies
        (all p : v.placedAt, e : v.expiresAt | e > p)
}
check A_Invariant_6_1 for 4 but 3 Commitment, 3 Call

-- A_Invariant_7_1: no late resolution: a confirmed commitment's expiry instant exceeds its
-- confirmation instant, and a released one's its release instant. Confirm and release are
-- refused once the commitment reads lapsed (Operation 17, 18), boundary included.
assert A_Invariant_7_1 {
    all v : Commitment | recorded[v] implies {
        v.state = Confirmed implies (all e : v.expiresAt, t : v.confirmedAt | e > t)
        v.state = Released  implies (all e : v.expiresAt, t : v.releasedAt  | e > t)
    }
}
check A_Invariant_7_1 for 4 but 3 Commitment, 3 Call

-- A_Invariant_7_2: no premature expiry: an expired commitment's lapse instant does not
-- precede its expiry instant. Expire is refused while the commitment reads open (Operation 19).
assert A_Invariant_7_2 {
    all v : Commitment | recorded[v] implies
        (v.state = Expired implies (all e : v.expiresAt, t : v.lapsedAt | not (t < e)))
}
check A_Invariant_7_2 for 4 but 3 Commitment, 3 Call

-- A_Invariant_7_3: every held commitment reads exactly one of open, lapsed, at every now:
-- the two readings meet at the boundary instant, which reads lapsed and only lapsed, and
-- leave no instant unread.
assert A_Invariant_7_3 {
    all v : Commitment, n : Int | (recorded[v] and Held in v.state) implies
        ((readsOpen[v, n] and not readsLapsed[v, n]) or (readsLapsed[v, n] and not readsOpen[v, n]))
}
check A_Invariant_7_3 for 4 but 3 Commitment, 3 Call

-- A_Invariant_8_1: a confirmation instant never precedes the placement instant: confirm
-- stamps now (Operation 24), placement stamped an earlier call's now (Operation 10), and the
-- clock does not go backward (the fact above).
assert A_Invariant_8_1 {
    all v : Commitment | recorded[v] implies
        (all p : v.placedAt, t : v.confirmedAt | not (t < p))
}
check A_Invariant_8_1 for 4 but 3 Commitment, 3 Call

-- A_Invariant_8_2: a release instant never precedes the placement instant (Operation 25, 10).
assert A_Invariant_8_2 {
    all v : Commitment | recorded[v] implies
        (all p : v.placedAt, t : v.releasedAt | not (t < p))
}
check A_Invariant_8_2 for 4 but 3 Commitment, 3 Call

-- A_State_1: every commitment carries its id, resource, requester, placement instant,
-- expiry instant and a state (Check 7.1, 7.2): [Place Hold] writes each (Operation 8 to 12)
-- and every resolve keeps them.
assert A_State_1 {
    all v : Commitment | recorded[v] implies {
        some v.id
        some v.resource
        some v.requester
        some v.placedAt
        some v.expiresAt
        some v.state
    }
}
check A_State_1 for 4 but 3 Commitment, 3 Call

-- A_State_2: every confirmed commitment carries its confirmation instant (Operation 24).
assert A_State_2 {
    all v : Commitment | (recorded[v] and Confirmed in v.state) implies some v.confirmedAt
}
check A_State_2 for 4 but 3 Commitment, 3 Call

-- A_State_3: every released commitment carries its release instant (Operation 25).
assert A_State_3 {
    all v : Commitment | (recorded[v] and Released in v.state) implies some v.releasedAt
}
check A_State_3 for 4 but 3 Commitment, 3 Call

-- A_State_4: every expired commitment carries its lapse instant (Operation 26).
assert A_State_4 {
    all v : Commitment | (recorded[v] and Expired in v.state) implies some v.lapsedAt
}
check A_State_4 for 4 but 3 Commitment, 3 Call

-- A_State_5: a held commitment carries no terminal instant (Check 1.3): nothing about a
-- resolution is on a hold that is still open to one.
assert A_State_5 {
    all v : Commitment | (recorded[v] and Held in v.state) implies
        (no v.confirmedAt and no v.releasedAt and no v.lapsedAt)
}
check A_State_5 for 4 but 3 Commitment, 3 Call

-- A_Identity_5: two commitments never share an id. Versions recorded by different
-- [Place Hold] calls are different commitments, even on one resource for one requester;
-- each takes its id from its own id material (Identity 2, Operation 8).
assert A_Identity_5 {
    all v1, v2 : Commitment | (recorded[v1] and recorded[v2] and origin[v1] != origin[v2])
        implies v1.id != v2.id
}
check A_Identity_5 for 4 but 3 Commitment, 3 Call

-- ─────────────────────────────────────────────────────────────────────────────
-- Satisfiability runs — non-vacuity guards, one for each shape the page admits
-- Each run must find at least one instance (SAT).
-- UNSAT means the model forbids a record the page admits.
-- ─────────────────────────────────────────────────────────────────────────────

-- ShowHeld: a hold just placed, held, its window open from the placement instant.
run ShowHeld {
    some v : Commitment | recorded[v] and v.state = Held
} for 4 but 3 Commitment, 3 Call

-- ShowConfirmed: the retail example — the shopper checks out inside the window.
run ShowConfirmed {
    some v : Commitment | recorded[v] and v.state = Confirmed
} for 4 but 3 Commitment, 3 Call

-- ShowReleased: the healthcare example — the patient is discharged before the window closes.
run ShowReleased {
    some v : Commitment | recorded[v] and v.state = Released
} for 4 but 3 Commitment, 3 Call

-- ShowExpiredAtTheBoundary: an expire at the very expiry instant is admitted: the boundary
-- instant reads lapsed (Term lapsed).
run ShowExpiredAtTheBoundary {
    some v : Commitment | recorded[v] and v.state = Expired and v.lapsedAt = v.expiresAt
} for 4 but 3 Commitment, 3 Call

-- ShowExpiredLate: the banking example — the sweep fires after the window closed, so the
-- lapse instant follows the expiry instant (the reclamation lag, Non-goal 25).
run ShowExpiredLate {
    some v : Commitment | recorded[v] and v.state = Expired and v.lapsedAt > v.expiresAt
} for 4 but 3 Commitment, 3 Call

-- ShowConfirmedAtPlacement: a confirm at the placement instant is admitted ("MUST NOT
-- PRECEDE" allows equality, Invariant 8.1).
run ShowConfirmedAtPlacement {
    some v : Commitment | recorded[v] and v.state = Confirmed and v.confirmedAt = v.placedAt
} for 4 but 3 Commitment, 3 Call

-- ShowHeldPastItsWindow: a held commitment awaiting an [Expire] after its window lapsed —
-- the atom does not guarantee that it resolves (Non-goal 25).
run ShowHeldPastItsWindow {
    some v : Commitment, c : Call | recorded[v] and v.state = Held
        and C/lt[v.writtenBy, c] and readsLapsed[v, c.now]
} for 4 but 3 Commitment, 3 Call

-- ShowTwoHoldsOneResource: a resource released and held again, for the same requester:
-- two commitments, each with its own id (Identity 6: a property is not identity).
run ShowTwoHoldsOneResource {
    some v1, v2 : Commitment | recorded[v1] and recorded[v2] and origin[v1] != origin[v2]
        and v1.resource = v2.resource and v1.requester = v2.requester
        and v1.state = Released and v2.state = Held
} for 4 but 3 Commitment, 3 Call

-- ShowDeclaredBounds: a hold placed under duration bounds the deployment declares
-- (Capability requirement 22).
run ShowDeclaredBounds {
    some DeclaredBounds
    some v : Commitment | recorded[v] and no v.found
} for 4 but 3 Commitment, 3 Call
