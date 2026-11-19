-- waitlist-buggy-close-adds-state.als
-- DELIBERATELY WRONG twin of waitlist.als (unit: `atoms/waitlist.md formal layer`).
--
-- INJECTED DEFECT: [Close] adds closed beside open, so the closed version stands in both
-- (State 3).
--
-- BREAKS: A_State_3.
-- Everything else is waitlist.als as written; read its comments there.

module waitlist_buggy_close_adds_state

open util/ordering[Call] as C

-- ─────────────────────────────────────────────────────────────────────────────
-- Signatures (types)
-- ─────────────────────────────────────────────────────────────────────────────

-- OfferingRef: a string a call carries as an offering reference, such as yoga-sat or
-- Yoga-Sat, compared codepoint for codepoint, so two different strings are two different
-- atoms (Term offering reference, Identity 7).
sig OfferingRef {}

-- PersonRef: a string a call carries as a person reference, such as mo or Mo, compared
-- codepoint for codepoint (Term person reference, Identity 9).
sig PersonRef {}

-- Instant: a clock reading the host injects at the seam as now (Capability requirement 3).
-- No rule turns on the order of two readings: the join number, never the instant, orders a
-- line (Term join instant).
sig Instant {}

-- WaitlistId: an opaque value naming one waitlist, which the seam supplies (Term waitlist id).
sig WaitlistId {}

-- SpotId: an opaque value naming one spot, which the seam supplies (Term spot id).
sig SpotId {}

-- WState: whether a waitlist takes new spots (Term waitlist state).
abstract sig WState {}

-- Open, Closed: the two waitlist states.
one sig Open, Closed extends WState {}

-- SState: where a spot stands (Term spot state).
abstract sig SState {}

-- Waiting, Called, Left, Unserved: the four spot states; the last three are ended (Term
-- ended spot).
one sig Waiting, Called, Left, Unserved extends SState {}

-- Normalizer: what a normalizer that folds case would rewrite a reference to, where the result
-- differs (yoga-sat for Yoga-Sat, mo for Mo). The page forbids it (Identity 6 to 9): the
-- model's own actions never apply it. It is here so a run can show two references one
-- normalizer would merge, and so a twin can apply it.
one sig Normalizer {
    foldOffering : OfferingRef -> lone OfferingRef,
    foldPerson   : PersonRef -> lone PersonRef
}

-- Call: one call of a writing action, with the now the seam gives it. Calls happen in one
-- order, the order Execution Contract Order 1 gives every commit.
abstract sig Call {
    now : one Instant
}

-- StartCall: one [Start] call, start(offering_reference), with the waitlist id the seam
-- supplies for it (Capability requirement 1).
sig StartCall extends Call {
    offering : one OfferingRef,
    supplied : one WaitlistId
}

-- JoinCall: one [Join] call, join(waitlist_id, person_reference), with the spot id the seam
-- supplies for it (Capability requirement 2).
sig JoinCall extends Call {
    target       : one WaitlistId,
    person       : one PersonRef,
    suppliedSpot : one SpotId
}

-- LeaveCall: one [Leave] call, leave(spot_id).
sig LeaveCall extends Call {
    leaving : one SpotId
}

-- CallNextCall: one [Call Next] call, call_next(waitlist_id).
sig CallNextCall extends Call {
    calling : one WaitlistId
}

-- CloseCall: one [Close] call, close(waitlist_id).
sig CloseCall extends Call {
    closing : one WaitlistId
}

-- Waitlist: one version of a waitlist record (Term records, Term version), as the call that
-- wrote it left it. Every field the page names may be absent and the state may hold either
-- member or both, so a write that forgot a field or stood a waitlist in two states would
-- show; what the page promises (State 1, 3) is checked, never built into the type. The last
-- two fields are the model's own: which call wrote this version, and which version a [Close]
-- found.
sig Waitlist {
    wid         : lone WaitlistId,   -- waitlist id
    offeringRef : lone OfferingRef,  -- offering reference
    wstate      : set WState,        -- waitlist state
    wBy         : one Call,
    wFound      : lone Waitlist
}

-- Spot: one version of a spot record, as the call that wrote it left it; as for Waitlist,
-- every field may be absent and the state may hold several members (State 2, 4 are checked).
-- The last two fields are the model's own: which call wrote this version, and which version
-- a [Leave], [Call Next] or [Close] found.
sig Spot {
    sid         : lone SpotId,       -- spot id
    swid        : lone WaitlistId,   -- waitlist id
    personRef   : lone PersonRef,    -- person reference
    joinNumber  : lone Int,          -- join number
    joinInstant : lone Instant,      -- join instant
    sstate      : set SState,        -- spot state
    sBy         : one Call,
    sFound      : lone Spot
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Facts: what the page takes from outside (the seam)
-- ─────────────────────────────────────────────────────────────────────────────

-- SeamWaitlistIds: the seam supplies, for each [Start] call, a waitlist id no waitlist has
-- carried before the call (Capability requirement 1).
fact SeamWaitlistIds {
    all c : StartCall | no g : Waitlist | C/lt[g.wBy, c] and g.wid = c.supplied
}

-- SeamSpotIds: the seam supplies, for each [Join] call, a spot id no spot has carried before
-- the call (Capability requirement 2).
fact SeamSpotIds {
    all c : JoinCall | no s : Spot | C/lt[s.sBy, c] and s.sid = c.suppliedSpot
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Helpers
-- ─────────────────────────────────────────────────────────────────────────────

-- originW: the [Start] call that recorded the waitlist this version belongs to. Two versions
-- with one origin are one waitlist; two origins are two waitlists.
fun originW[g : Waitlist] : set StartCall {
    { v : g.*wFound | no v.wFound }.wBy & StartCall
}

-- originS: the [Join] call that recorded the spot this version belongs to.
fun originS[s : Spot] : set JoinCall {
    { v : s.*sFound | no v.sFound }.sBy & JoinCall
}

-- currentW: the version is its waitlist's latest version when call c runs: written before c,
-- and no later version of the same waitlist written before c (Execution Contract Database 2).
pred currentW[v : Waitlist, c : Call] {
    C/lt[v.wBy, c]
    no w : Waitlist | originW[w] = originW[v] and C/lt[v.wBy, w.wBy] and C/lt[w.wBy, c]
}

-- currentS: the same for a spot.
pred currentS[v : Spot, c : Call] {
    C/lt[v.sBy, c]
    no w : Spot | originS[w] = originS[v] and C/lt[v.sBy, w.sBy] and C/lt[w.sBy, c]
}

-- asOfW: the version is its waitlist's latest version as of call c's commit, c's own writes
-- included: what an auditor reads "as of" that commit (Term version, Check 2.5, 2.7).
pred asOfW[v : Waitlist, c : Call] {
    C/lte[v.wBy, c]
    no w : Waitlist | originW[w] = originW[v] and C/lt[v.wBy, w.wBy] and C/lte[w.wBy, c]
}

-- asOfS: the same for a spot (Check 2.4, 2.7, 3.1).
pred asOfS[v : Spot, c : Call] {
    C/lte[v.sBy, c]
    no w : Spot | originS[w] = originS[v] and C/lt[v.sBy, w.sBy] and C/lte[w.sBy, c]
}

-- numbersOf: the join numbers the spots of waitlist id w carry when call c runs, ended spots
-- included (Term highest join number).
fun numbersOf[w : WaitlistId, c : Call] : set Int {
    { v : Spot | currentS[v, c] and v.swid = w }.joinNumber
}

-- highest: the highest join number of waitlist id w when call c runs; zero for a waitlist
-- carrying no spot (Term highest join number).
fun highest[w : WaitlistId, c : Call] : Int {
    no numbersOf[w, c] => 0 else { n : numbersOf[w, c] | all m : numbersOf[w, c] | m <= n }
}

-- nextJoin: the next join number of waitlist id w when call c runs: highest + 1 (Term next
-- join number).
fun nextJoin[w : WaitlistId, c : Call] : Int {
    plus[highest[w, c], 1]
}

-- ─────────────────────────────────────────────────────────────────────────────
-- The writing actions: their guards and their writes
-- ─────────────────────────────────────────────────────────────────────────────

-- startRecords: the waitlist an admitted [Start] records where no open waitlist stands for
-- the offering reference, compared codepoint for codepoint (Operation 4, Identity 7): it
-- carries the waitlist id the seam supplied and the offering reference as the call carried
-- it (Operation 4, Identity 6), and stands in open (Operation 5).
pred startRecords[c : StartCall, g : Waitlist] {
    no v : Waitlist | currentW[v, c] and v.wstate = Open
        and v.offeringRef = c.offering                            -- Operation 2, 4
    g.wid = c.supplied                                            -- Operation 4
    g.offeringRef = c.offering                                    -- Operation 4, Identity 6
    g.wstate = Open                                               -- Operation 5
}

-- closeCloses: the version an admitted [Close] records over the open waitlist it found by the
-- waitlist id (Identity 1, Operation 25): the waitlist stands in closed (Operation 26) and
-- keeps its waitlist id and offering reference.
pred closeCloses[pre : Waitlist, c : CloseCall, g : Waitlist] {
    currentW[pre, c]
    pre.wid = c.closing
    pre.wstate = Open                                             -- Operation 25
    g.wid = pre.wid                                               -- the closed version's id
    g.offeringRef = pre.offeringRef                               -- the closed version's offering
    g.wstate = Open + Closed                                      -- BUG: closed added beside open
}

-- joinRecords: the spot an admitted [Join] records: the waitlist id names an open waitlist
-- (Operation 7, 9), no waiting spot of it carries the person reference, compared codepoint
-- for codepoint (Operation 10, Identity 9); the spot carries the spot id the seam supplied,
-- the waitlist id and person reference of the call (Operation 11), the next join number
-- (Operation 12), the injected now (Operation 13), and stands in waiting (Operation 14).
pred joinRecords[c : JoinCall, s : Spot] {
    some w : Waitlist | currentW[w, c] and w.wid = c.target
        and w.wstate = Open                                       -- Operation 7, 9
    no v : Spot | currentS[v, c] and v.swid = c.target and v.personRef = c.person
        and v.sstate = Waiting                                    -- Operation 10
    s.sid = c.suppliedSpot                                        -- Operation 11
    s.swid = c.target                                             -- Operation 11, the waitlist
    s.personRef = c.person                                        -- Operation 11, Identity 8
    s.joinNumber = nextJoin[c.target, c]                          -- Operation 12
    s.joinInstant = c.now                                         -- Operation 13
    s.sstate = Waiting                                            -- Operation 14
}

-- leaveLeaves: the version an admitted [Leave] records over the waiting spot it found by the
-- spot id (Identity 2, Operation 17): the spot stands in left (Operation 18) and keeps every
-- other field.
pred leaveLeaves[pre : Spot, c : LeaveCall, g : Spot] {
    currentS[pre, c]
    pre.sid = c.leaving
    pre.sstate = Waiting                                          -- Operation 17
    g.sid = pre.sid                                               -- leave keeps the spot id
    g.swid = pre.swid                                             -- leave keeps the waitlist
    g.personRef = pre.personRef                                   -- leave keeps the person
    g.joinNumber = pre.joinNumber                                 -- leave keeps the join number
    g.joinInstant = pre.joinInstant                               -- leave keeps the join instant
    g.sstate = Left                                               -- Operation 18
}

-- front: the spot version is the front spot of the waitlist call c names, when c runs: a
-- waiting spot of it carrying the lowest join number among its waiting spots (Term front spot).
pred front[pre : Spot, c : CallNextCall] {
    currentS[pre, c]
    pre.swid = c.calling
    pre.sstate = Waiting
    all v : Spot | (currentS[v, c] and v.swid = c.calling and v.sstate = Waiting)
        implies pre.joinNumber <= v.joinNumber                    -- the lowest join number
}

-- callNextCalls: the version an admitted [Call Next] records over the front spot of an open
-- waitlist (Operation 20, 21): the front spot stands in called (Operation 22) and keeps every
-- other field.
pred callNextCalls[pre : Spot, c : CallNextCall, g : Spot] {
    some w : Waitlist | currentW[w, c] and w.wid = c.calling
        and w.wstate = Open                                       -- Operation 20
    front[pre, c]                                                 -- Operation 22
    g.sid = pre.sid
    g.swid = pre.swid
    g.personRef = pre.personRef
    g.joinNumber = pre.joinNumber
    g.joinInstant = pre.joinInstant
    g.sstate = Called                                             -- Operation 22
}

-- closeUnserves: the version an admitted [Close] records, in the commit that closes the
-- spot's waitlist, over a spot then waiting on it: the spot stands in unserved (Operation 27)
-- and keeps every other field.
pred closeUnserves[pre : Spot, c : CloseCall, g : Spot] {
    currentS[pre, c]
    pre.sstate = Waiting
    some w : Waitlist | w.wBy = c and w.wid = pre.swid            -- the close of its waitlist
    g.sid = pre.sid
    g.swid = pre.swid
    g.personRef = pre.personRef
    g.joinNumber = pre.joinNumber
    g.joinInstant = pre.joinInstant
    g.sstate = Unserved                                           -- Operation 27
}

-- closeComplete: a [Close] that closed a waitlist wrote, in the same commit, an unserved
-- version of EVERY spot then waiting on it (Operation 27, Execution Contract Database 1).
pred closeComplete[c : CloseCall] {
    all w : Waitlist, pre : Spot | (w.wBy = c and currentS[pre, c] and pre.swid = w.wid
        and pre.sstate = Waiting) implies some g : Spot | g.sBy = c and g.sFound = pre
}

-- writtenW: the waitlist version is what its call's write left: a [Start] writes a first
-- version, a [Close] a version over the one it found.
pred writtenW[g : Waitlist] {
    let c = g.wBy {
        (c in StartCall and no g.wFound and startRecords[c, g])
        or (c in CloseCall and some g.wFound and closeCloses[g.wFound, c, g])
    }
}

-- writtenS: the spot version is what its call's write left: a [Join] writes a first version;
-- a [Leave], [Call Next] or [Close] a version over the one it found.
pred writtenS[s : Spot] {
    let c = s.sBy {
        (c in JoinCall and no s.sFound and joinRecords[c, s])
        or (c in LeaveCall and some s.sFound and leaveLeaves[s.sFound, c, s])
        or (c in CallNextCall and some s.sFound and callNextCalls[s.sFound, c, s])
        or (c in CloseCall and some s.sFound and closeUnserves[s.sFound, c, s])
    }
}

-- Scope: every version the state holds is one an admitted call wrote, each [Close] wrote the
-- whole of its commit, and a commit writes one version of a record at most, a [Join], [Leave]
-- or [Call Next] one spot (see SCOPE). It is the model's universe, not a rule of the page:
-- each check reads "in any state the calls can leave".
pred Scope {
    all g : Waitlist | writtenW[g]
    all s : Spot | writtenS[s]
    all c : CloseCall | closeComplete[c]
    all c : Call | lone { g : Waitlist | g.wBy = c }
    all c : JoinCall + LeaveCall + CallNextCall | lone { s : Spot | s.sBy = c }
    all disj s1, s2 : Spot | some s1.sFound implies s1.sFound != s2.sFound
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Assertions (verified guarantees)
-- Each "check" asks: is there any state the page's calls can leave that violates this
-- assertion? No counterexample (UNSAT) = the guarantee holds within scope.
-- ─────────────────────────────────────────────────────────────────────────────

-- A_State_1: every version of every waitlist carries its waitlist id, offering reference and
-- waitlist state, closed ones included (State 1, Check 1.1).
assert A_State_1 {
    Scope implies all g : Waitlist | {
        some g.wid
        some g.offeringRef
        some g.wstate
    }
}
check A_State_1 for 4

-- A_State_2: every version of every spot carries its spot id, waitlist id, person reference,
-- join number, join instant and spot state, ended ones included (State 2, Check 1.2).
assert A_State_2 {
    Scope implies all s : Spot | {
        some s.sid
        some s.swid
        some s.personRef
        some s.joinNumber
        some s.joinInstant
        some s.sstate
    }
}
check A_State_2 for 4

-- A_State_3: every version of every waitlist stands in exactly one of open, closed (State 3).
assert A_State_3 {
    Scope implies all g : Waitlist | one g.wstate
}
check A_State_3 for 4

-- A_State_4: every version of every spot stands in exactly one of waiting, called, left,
-- unserved (State 4).
assert A_State_4 {
    Scope implies all s : Spot | one s.sstate
}
check A_State_4 for 4

-- A_Identity_3: no two waitlists share a waitlist id, a waitlist closed and the one started
-- again for its offering included (Identity 3, Check 2.1).
assert A_Identity_3 {
    Scope implies all g1, g2 : Waitlist | originW[g1] != originW[g2] implies no (g1.wid & g2.wid)
}
check A_Identity_3 for 4

-- A_Identity_4: no two spots share a spot id: a person who joins again holds a new spot under
-- a new spot id, never the one an ended spot carries (Identity 4, 5, Check 2.2, Term spot id).
assert A_Identity_4 {
    Scope implies all s1, s2 : Spot | originS[s1] != originS[s2] implies no (s1.sid & s2.sid)
}
check A_Identity_4 for 4

-- A_Operation_4: the waitlist a [Start] recorded carries the waitlist id the seam supplied and
-- the offering reference the call carried, as it carried it, never rewritten into another form
-- (Operation 4, Identity 6, 12).
assert A_Operation_4 {
    Scope implies all g : Waitlist | no g.wFound implies {
        g.wid = originW[g].supplied
        g.offeringRef = originW[g].offering
    }
}
check A_Operation_4 for 4

-- A_Operation_5: the waitlist a [Start] recorded stands in open (Operation 5).
assert A_Operation_5 {
    Scope implies all g : Waitlist | no g.wFound implies g.wstate = Open
}
check A_Operation_5 for 4

-- A_Operation_11: the spot a [Join] recorded carries the spot id the seam supplied, and the
-- waitlist id and the person reference the call carried, as it carried them (Operation 11,
-- Identity 8, 13).
assert A_Operation_11 {
    Scope implies all s : Spot | no s.sFound implies {
        s.sid = originS[s].suppliedSpot
        s.swid = originS[s].target
        s.personRef = originS[s].person
    }
}
check A_Operation_11 for 4

-- A_Operation_12: every version of every spot carries the next join number its waitlist had
-- when the [Join] that recorded the spot ran: one more than the highest, an ended spot's
-- included (Operation 12, Term next join number; Check 3.2's shape).
assert A_Operation_12 {
    Scope implies all s : Spot | s.joinNumber = nextJoin[originS[s].target, originS[s]]
}
check A_Operation_12 for 4

-- A_Operation_13: every version of every spot carries as its join instant the now the seam
-- gave the [Join] that recorded it (Operation 13; Check 3.5's shape).
assert A_Operation_13 {
    Scope implies all s : Spot | s.joinInstant = originS[s].now
}
check A_Operation_13 for 4

-- A_Operation_14: the spot a [Join] recorded stands in waiting: joining puts a person in line,
-- never straight to the front and called (Operation 14, Non-goal 6).
assert A_Operation_14 {
    Scope implies all s : Spot | no s.sFound implies s.sstate = Waiting
}
check A_Operation_14 for 4

-- A_Invariant_1_1: no two spots of one waitlist share a join number, a person's ended spot and
-- the spot they joined again with included (Invariant 1.1, Check 2.3).
assert A_Invariant_1_1 {
    Scope implies all s1, s2 : Spot |
        (originS[s1] != originS[s2] and some (s1.swid & s2.swid))
            implies no (s1.joinNumber & s2.joinNumber)
}
check A_Invariant_1_1 for 4

-- A_Invariant_1_2: as of no commit does a waiting spot carry a join number below that of a
-- called spot of the same waitlist: no one is called ahead of anyone who joined earlier and is
-- still waiting (Invariant 1.2, Check 3.1).
assert A_Invariant_1_2 {
    Scope implies all c : Call, a, b : Spot |
        (asOfS[a, c] and asOfS[b, c] and some (a.swid & b.swid)
            and a.sstate = Waiting and b.sstate = Called)
        implies not (a.joinNumber < b.joinNumber)
}
check A_Invariant_1_2 for 4

-- A_Invariant_2_1: as of no commit do two waiting spots of one waitlist share a person
-- reference: one waiting spot per person (Invariant 2.1, Check 2.4).
assert A_Invariant_2_1 {
    Scope implies all c : Call, a, b : Spot |
        (asOfS[a, c] and asOfS[b, c] and originS[a] != originS[b]
            and some (a.swid & b.swid) and a.sstate = Waiting and b.sstate = Waiting)
        implies no (a.personRef & b.personRef)
}
check A_Invariant_2_1 for 4

-- A_Invariant_5_2: as of no commit does a closed waitlist carry a waiting spot: closing ends
-- every spot still waiting on it (Invariant 5.2, Check 2.7).
assert A_Invariant_5_2 {
    Scope implies all c : Call, g : Waitlist, s : Spot |
        (asOfW[g, c] and asOfS[s, c] and g.wstate = Closed and some (s.swid & g.wid))
        implies s.sstate != Waiting
}
check A_Invariant_5_2 for 4

-- A_Invariant_6_1: as of no commit do two open waitlists share an offering reference: one
-- open line per offering (Invariant 6.1, Check 2.5).
assert A_Invariant_6_1 {
    Scope implies all c : Call, g1, g2 : Waitlist |
        (asOfW[g1, c] and asOfW[g2, c] and originW[g1] != originW[g2]
            and g1.wstate = Open and g2.wstate = Open)
        implies no (g1.offeringRef & g2.offeringRef)
}
check A_Invariant_6_1 for 4

-- A_Invariant_8_1: every spot's waitlist id names a waitlist recorded at or before the commit
-- that wrote the spot: no spot on a line that does not exist (Invariant 8.1, Check 2.6).
assert A_Invariant_8_1 {
    Scope implies all s : Spot | some g : Waitlist | g.wid = s.swid and C/lte[g.wBy, s.sBy]
}
check A_Invariant_8_1 for 4

-- A_Invariant_9_1: every spot carries a positive count, one or more, as its join number
-- (Invariant 9.1, Check 4.1).
assert A_Invariant_9_1 {
    Scope implies all s : Spot | some s.joinNumber and s.joinNumber >= 1
}
check A_Invariant_9_1 for 4

-- ─────────────────────────────────────────────────────────────────────────────
-- Satisfiability runs — non-vacuity guards, one for each shape the page admits
-- Each run must find at least one instance (SAT).
-- UNSAT means the model forbids a state the page admits.
-- ─────────────────────────────────────────────────────────────────────────────

-- ShowLine: three people waiting on one waitlist with join numbers 1, 2 and 3, as Ana, Ben and
-- Cara on the pottery class.
run ShowLine {
    Scope and some disj a, b, d : Spot | {
        no (a + b + d).sFound
        a.swid = b.swid and b.swid = d.swid
        a.joinNumber = 1 and b.joinNumber = 2 and d.joinNumber = 3
    }
} for 4

-- ShowCalledThenRejoined: a called spot and, behind on the same waitlist, the same person's
-- new waiting spot with a higher join number, as Ana after her offer ran out.
run ShowCalledThenRejoined {
    Scope and some disj a, b : Spot | {
        a.sstate = Called and b.sstate = Waiting
        a.swid = b.swid and a.personRef = b.personRef
        b.joinNumber > a.joinNumber
    }
} for 4

-- ShowLeft: a spot that left, as Ben finding a seat in another class.
run ShowLeft {
    Scope and some s : Spot | s.sstate = Left
} for 4

-- ShowClosedUnserved: a closed waitlist and a spot unserved by its closing, as Cara when the
-- class started.
run ShowClosedUnserved {
    Scope and some g : Waitlist, s : Spot | g.wstate = Closed and s.sstate = Unserved
        and s.swid = g.wid
} for 4

-- ShowRestarted: a closed waitlist and an open one started again for the same offering under a
-- new waitlist id (What undoes a write).
run ShowRestarted {
    Scope and some g1, g2 : Waitlist | originW[g1] != originW[g2]
        and g1.offeringRef = g2.offeringRef and g1.wstate = Closed and g2.wstate = Open
} for 4

-- ShowCaseVariantPersons: two waiting spots of one waitlist whose person references one
-- normalizer would merge, mo and Mo, each its own person (Identity 8, 9, the rejection paths).
run ShowCaseVariantPersons {
    Scope and some a, b : Spot | originS[a] != originS[b] and a.swid = b.swid
        and a.sstate = Waiting and b.sstate = Waiting
        and b.personRef = a.personRef.(Normalizer.foldPerson)
} for 4

-- ShowCaseVariantOfferings: two open waitlists whose offering references one normalizer would
-- merge, yoga-sat and Yoga-Sat, each its own offering (Identity 6, 7).
run ShowCaseVariantOfferings {
    Scope and some g1, g2 : Waitlist | originW[g1] != originW[g2]
        and g1.wstate = Open and g2.wstate = Open
        and g2.offeringRef = g1.offeringRef.(Normalizer.foldOffering)
} for 4
