-- duplicate-prevention-buggy-second-instant.als
-- DELIBERATELY WRONG twin of duplicate-prevention.als (unit: every check has a twin that breaks it).
--
-- INJECTED DEFECT: [Record] of an identity whose guard elapsed adds a second recording instant beside the old
-- one instead of replacing it (State 1).
--
-- BREAKS: A_State_1 (and A_Invariant_2_2 and A_Invariant_2_3, which read the one instant).
-- Everything else is duplicate-prevention.als as written; read its comments there.

module duplicate_prevention_buggy_second_instant

-- ─────────────────────────────────────────────────────────────────────────────
-- Signatures (types)
-- ─────────────────────────────────────────────────────────────────────────────

-- Identity: the opaque value a containing pattern asks the atom to remember and recognize
-- (Term identity). The atom never interprets or normalizes one (Identity 2 to 4), so it is
-- an uninterpreted token: two identities are the same only when they are the same token.
sig Identity {}

-- Verdict: the two answers [Check] gives (the Check outcome): seen and not-seen.
abstract sig Verdict {}
one sig Seen, NotSeen extends Verdict {}

-- Instance: one instance of the atom and the window duration its containing pattern
-- supplied for it, exactly one per instance (Operation 11, Term window duration).
one sig Instance {
    window : one Int
}

-- Call: one call of [Record] or [Check] as it reaches the seam: the identity it names and
-- the clock reading the host injects for it (Term now, Capability requirement 1).
abstract sig Call {
    id  : one Identity,
    now : one Int
}

-- RecordCall: one [Record] call, record(identity).
sig RecordCall extends Call {}

-- RefusedWrite: the [Record] calls whose write the database refuses (Operation 14). Which
-- writes fail is the database's, not the atom's, so it is a subset with no rule on it.
sig RefusedWrite in RecordCall {}

-- CheckCall: one [Check] call, check(identity), with the answer it gives. The answer is a
-- set of verdicts, so a build that gave two answers, or none, would show: what the page
-- promises (exactly one, Operation 5) is checked, never built into the type.
sig CheckCall extends Call {
    answer : set Verdict
}

-- Store: one state of the recorded set (Term recorded set): each identity held with its
-- recording instant. The relation lets an identity carry any number of instants, so a write
-- that added an instant instead of replacing one would show (State 1 is checked, not typed).
-- The last two fields are the model's own: the set this one was made from and the call
-- that made it; the page has no such fields.
sig Store {
    entries : Identity -> Int,   -- identity -> recording instant (recorded_at)
    prior   : lone Store,        -- the set the call found
    madeBy  : lone Call          -- the call whose transition left this set
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Facts: what the page takes from outside
-- ─────────────────────────────────────────────────────────────────────────────

-- The containing pattern's window duration exceeds zero (Term window duration; the
-- containing pattern supplies it, Operation 11). This is where Invariant 2.3 comes from: a
-- guard stamped from now holds at now only because the window is longer than nothing.
fact WindowExceedsZero {
    Instance.window > 0
}

-- The deployment computes every elapsed term and guard end without loss (Execution
-- Contract Logic confinement 9, which the page does not cite). In the model: the window
-- lies between 1 and 3 and every clock reading between -4 and 3, so the model's integers
-- (from -8 to 7) hold every difference of two readings and every reading plus the window.
fact ExactArithmetic {
    Instance.window <= 3
    all c : Call | c.now >= -4 and c.now <= 3
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Helpers
-- ─────────────────────────────────────────────────────────────────────────────

-- held: the identities a recorded set holds, under guard or not.
fun held[s : Store] : set Identity {
    s.entries.Int
}

-- elapsed: the elapsed term, (now - recorded_at) (Term elapsed term).
fun elapsed[t, r : Int] : Int {
    t.minus[r]
}

-- underGuard: the identity is in the recorded set and its elapsed term at the instant t is
-- less than the window duration (Term under guard; State 2 derives it at every call).
pred underGuard[s : Store, i : Identity, t : Int] {
    some r : s.entries[i] | elapsed[t, r] < Instance.window
}

-- guardEnd: the instant a guard stamped at r stops holding: r plus the window duration.
fun guardEnd[r : Int] : Int {
    r.plus[Instance.window]
}

-- found: the recorded set a call found, the one the set it made was made from.
fun found[c : Call] : set Store {
    madeBy.c.prior
}

-- landed: a [Record] call the action admits (Term landed record, Execution Contract Read
-- 4): [Record] states no precondition, so it admits every call whose write commits.
pred landed[c : RecordCall] {
    c not in RefusedWrite
}

-- opens: a landed record that found its identity not under guard: the record a guard is
-- anchored to (Clock semantics 1, "the opening record").
pred opens[c : RecordCall] {
    landed[c]
    not underGuard[found[c], c.id, c.now]
}

-- ─────────────────────────────────────────────────────────────────────────────
-- The actions: what each call leaves
-- ─────────────────────────────────────────────────────────────────────────────

-- recordLeaves: the recorded set a [Record] leaves over the set it found.
pred recordLeaves[pre, post : Store, c : RecordCall] {
    -- the database refused the write: nothing is written (Operation 14, Execution
    -- Contract Database 3), so an identity not under guard stays so (Record failure 2)
    not landed[c] implies post.entries = pre.entries
    -- an identity under guard: unchanged, its recording instant stands (Operation 4,
    -- Invariant 2.1, 2.2)
    (landed[c] and underGuard[pre, c.id, c.now]) implies post.entries = pre.entries
    -- an identity not under guard: placed under guard, its recording instant stamped from
    -- the injected now, replacing any elapsed one (Operation 1, 2, State 1)
    (landed[c] and not underGuard[pre, c.id, c.now])
        implies post.entries = pre.entries + (c.id -> c.now) -- BUG: added, not replaced
}

-- checkLeaves: what a [Check] leaves: the recorded set as it found it, and its answer,
-- derived from the elapsed term at its now (State 2, Operation 6, 7).
pred checkLeaves[pre, post : Store, c : CheckCall] {
    post.entries = pre.entries
    c.answer = (underGuard[pre, c.id, c.now] => Seen else NotSeen)
}

-- step: the set is what its call left of the set it found.
pred step[pre, post : Store, c : Call] {
    (c in RecordCall and recordLeaves[pre, post, c])
    or (c in CheckCall and checkLeaves[pre, post, c])
}

-- empty: the recorded set the atom starts with, holding nothing, made by no call.
pred empty[s : Store] {
    no s.prior
    no s.madeBy
    no s.entries
}

-- reached: a recorded set the page lets the atom hold (see SCOPE): it and every set it was
-- made from are the empty set or what one call left of the set before, and each call made
-- one set only (a call runs once).
pred reached[s : Store] {
    some v : s.*prior | empty[v]
    all v : s.*prior | empty[v] or {
        some v.prior
        one v.madeBy
        one madeBy.(v.madeBy)
        step[v.prior, v, v.madeBy]
    }
}

-- calls: the calls whose transitions built the set.
fun calls[s : Store] : set Call {
    s.*prior.madeBy
}

-- built: the call made a set the atom can hold, so its answer is one a check can give.
pred built[c : Call] {
    some s : Store | reached[s] and s.madeBy = c
}

-- later: call b ran after call a in the chain they share.
pred later[b, a : Call] {
    madeBy.a in (madeBy.b).^prior
}

-- opening: the record that opened the identity's current guard in the set: the last landed
-- record on it, in the calls that built the set, to find it not under guard.
fun opening[s : Store, i : Identity] : set RecordCall {
    { c : RecordCall & calls[s] | c.id = i and opens[c]
        and no c2 : RecordCall & calls[s] | c2.id = i and opens[c2] and later[c2, c] }
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Assertions (verified guarantees)
-- Each "check" asks: is there any recorded set, or answer, the page's calls can leave that
-- violates this assertion? No counterexample (UNSAT) = the guarantee holds within scope.
-- ─────────────────────────────────────────────────────────────────────────────

-- A_State_1: every identity the recorded set holds carries exactly one recording instant
-- (Check 1.1), however many records named it: a fresh guard replaces an elapsed instant
-- rather than adding a second.
assert A_State_1 {
    all s : Store, i : Identity | (reached[s] and i in held[s]) implies one s.entries[i]
}
check A_State_1 for 4 but 4 Int, 5 Store

-- A_Operation_5: every [Check] answers exactly one of seen, not-seen (Check 3.1).
assert A_Operation_5 {
    all c : CheckCall | built[c] implies one c.answer
}
check A_Operation_5 for 4 but 4 Int, 5 Store

-- A_Operation_6: a [Check] of an identity under guard at its now answers seen (Check 3.2),
-- the elapsed term of zero included: a check at the very reading of the record is seen.
assert A_Operation_6 {
    all c : CheckCall | (built[c] and underGuard[found[c], c.id, c.now]) implies Seen in c.answer
}
check A_Operation_6 for 4 but 4 Int, 5 Store

-- A_Operation_7: a [Check] of an identity not under guard at its now answers not-seen
-- (Check 3.3): never recorded, or its elapsed term has reached the window duration.
assert A_Operation_7 {
    all c : CheckCall | (built[c] and not underGuard[found[c], c.id, c.now]) implies NotSeen in c.answer
}
check A_Operation_7 for 4 but 4 Int, 5 Store

-- A_Invariant_2_1: no guard of a held identity ends later than the guard its opening record
-- opened, so a flurry of records under guard cannot push the guard forward.
assert A_Invariant_2_1 {
    all s : Store, i : Identity | (reached[s] and i in held[s]) implies
        some o : opening[s, i] | all r : s.entries[i] | guardEnd[r] <= guardEnd[o.now]
}
check A_Invariant_2_1 for 4 but 4 Int, 5 Store

-- A_Invariant_2_2: every held identity's recording instant is the now of the record that
-- opened its guard: a record under guard leaves the original instant standing (and Clock
-- semantics 1, the guard anchored to the opening record's now).
assert A_Invariant_2_2 {
    all s : Store, i : Identity | (reached[s] and i in held[s]) implies
        some o : opening[s, i] | s.entries[i] = o.now
}
check A_Invariant_2_2 for 4 but 4 Int, 5 Store

-- A_Invariant_2_3: the set a landed record leaves, where it found its identity not under
-- guard (never recorded, or elapsed), holds the identity under a fresh guard: stamped at the
-- record's now, and under guard at that now.
assert A_Invariant_2_3 {
    all s : Store | (reached[s] and s.madeBy in RecordCall and opens[s.madeBy]) implies {
        s.entries[s.madeBy.id] = s.madeBy.now
        underGuard[s, s.madeBy.id, s.madeBy.now]
    }
}
check A_Invariant_2_3 for 4 but 4 Int, 5 Store

-- A_Invariant_3_1: the recorded set is the landed records' alone: every entry it holds is
-- an identity a landed record named, at that record's now, and every identity a landed
-- record named is still held. A [Check] that wrote, re-stamped or removed an entry shows.
assert A_Invariant_3_1 {
    all s : Store | reached[s] implies {
        all i : Identity, r : Int | i -> r in s.entries implies
            some c : RecordCall & calls[s] | landed[c] and c.id = i and c.now = r
        all c : RecordCall & calls[s] | landed[c] implies c.id in held[s]
    }
}
check A_Invariant_3_1 for 4 but 4 Int, 5 Store

-- ─────────────────────────────────────────────────────────────────────────────
-- Satisfiability runs — non-vacuity guards, one for each shape the page admits
-- Each run must find at least one instance (SAT).
-- UNSAT means the model forbids a recorded set or an answer the page admits.
-- ─────────────────────────────────────────────────────────────────────────────

-- ShowFreshGuard: a record places an identity under guard (Personal Todo's "buy milk").
run ShowFreshGuard {
    some s : Store | reached[s] and s.madeBy in RecordCall and opens[s.madeBy]
} for 4 but 4 Int, 5 Store

-- ShowRecordUnderGuard: a later record, at a later now, of an identity under guard; the
-- original recording instant stands (the case table's second row).
run ShowRecordUnderGuard {
    some s : Store, c : RecordCall | reached[s] and s.madeBy = c and landed[c]
        and underGuard[found[c], c.id, c.now] and s.entries[c.id] < c.now
} for 4 but 4 Int, 5 Store

-- ShowReopenedAfterElapse: an identity whose guard elapsed, guarded afresh by a later
-- record (the same identity is fresh again once the window has passed).
run ShowReopenedAfterElapse {
    some s : Store, c : RecordCall | reached[s] and s.madeBy = c and opens[c]
        and c.id in held[found[c]]
} for 4 but 4 Int, 5 Store

-- ShowGuardMissed: a record whose write the database refused, its identity not under guard,
-- which stays unguarded (the rejection path; Record failure 2).
run ShowGuardMissed {
    some s : Store, c : RefusedWrite | reached[s] and s.madeBy = c
        and not underGuard[s, c.id, c.now]
} for 4 but 4 Int, 5 Store

-- ShowSeenAtTheRecordingInstant: a check at the very reading the record stamped answers
-- seen (the comment double-click).
run ShowSeenAtTheRecordingInstant {
    some c : CheckCall | built[c] and c.answer = Seen and c.now in found[c].entries[c.id]
} for 4 but 4 Int, 5 Store

-- ShowNotSeenNeverRecorded: a check of an identity no record placed answers not-seen.
run ShowNotSeenNeverRecorded {
    some c : CheckCall | built[c] and c.answer = NotSeen and c.id not in held[found[c]]
} for 4 but 4 Int, 5 Store

-- ShowNotSeenAtTheWindowEdge: a check whose elapsed term equals the window duration
-- answers not-seen, and the entry stays held (the degenerate bound; the WHY under Lazy
-- expiry: no action removes the entry).
run ShowNotSeenAtTheWindowEdge {
    some s : Store, c : CheckCall | reached[s] and s.madeBy = c and c.answer = NotSeen
        and c.id in held[s] and c.now = guardEnd[found[c].entries[c.id]]
} for 4 but 4 Int, 5 Store

-- ShowSeenUnderAnEarlierReading: a check whose now is earlier than the recording instant
-- answers seen: the elapsed term is negative, so less than the window. The atom does not
-- correct the clock (Non-goal 12).
run ShowSeenUnderAnEarlierReading {
    some c : CheckCall | built[c] and c.answer = Seen and c.now < found[c].entries[c.id]
} for 4 but 4 Int, 5 Store

-- ShowTwoIdentitiesTwoGuards: two identities held side by side under the one window, one
-- under guard and one elapsed.
run ShowTwoIdentitiesTwoGuards {
    some s : Store, c : CheckCall, disj i, j : held[s] | reached[s] and built[c]
        and found[c] = s and c.id = i and c.answer = Seen
        and not underGuard[s, j, c.now]
} for 4 but 4 Int, 5 Store
