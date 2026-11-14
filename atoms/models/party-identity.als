-- party-identity.als
-- Alloy structural model for the Party Identity atom (Grace Commons atoms/party-identity.md)
-- Grounded on Final Critique 12, 2026-11-05 at 29399d0 — Alloy layer authored 2026-11-11.
-- Derived validator; the English spec is the single source of truth. On any
-- disagreement, diagnose per the entry *The conflict protocol* in pressure-testing.md.
--
-- PURPOSE
-- Verify, by bounded exhaustive search, the STATIC data model of a party: what one party
-- record, with its verification event list and its state change log, must carry,
-- whatever call last wrote it, and what the assigned ids of the records one state holds
-- must satisfy among themselves. Everything that happens across steps (a record never
-- removed, an event or an enrollment field never changed, a list that never shortens, an
-- id never changed) is the TLA+ model's, party-identity.tla, which owns the operation
-- sequences.
--
-- RULES ENCODED (named by the page's own labels)
--   Invariant 2.1 — every party stands in exactly one of unverified, verified, suspended, closed.
--   Invariant 3.1 — read off one record's state change log: no recorded transition leaves closed.
--   Invariant 4.1 — every verified party carries a fresh verification (a passed check that
--                   follows the most recent suspend in insertion order).
--   Invariant 8.1 — read off one record, as Check 5.1 reads it: the state change log
--                   replays in insertion order from unverified to the party's state, so no
--                   transition went unlogged.
-- Beyond the Invariants, the rules the page's Conformance checks test on one state:
--   State 1      — every party carries party id, every enrollment field and a state (Check 5.2, 8.1).
--   State 4      — every verification event carries its six fields (Check 3.1).
--   State 5      — every state change event carries its id, prior and new state, acting
--                  reference and instant (Check 4.2).
--   State 7      — every state change event a reasoned action appended carries a reason (Check 4.3).
--   Operation 21 — every verification event's result is exactly one of passed, failed (Check 3.4).
--   Operation 36 — no state change event an admitted verify appended carries a reason (Check 4.5).
--   Identity 5   — every assigned id a record carries is the id material the seam supplied
--                  for it (with Identity 4, its positive form): the atom generates none.
--   Identity 7   — two parties do not share a party id (Check 7.1).
--   Identity 8   — two verification events do not share a verification id (Check 7.2).
--   Identity 9   — two state change events do not share a state change id (Check 7.3).
-- Invariant 2.1, 3.1 and 4.1 are checked by party-identity.tla too (Inv2_StateExclusivity,
-- Inv3_ClosedAbsorbing, Inv4_PassedAfterSuspend), so the two models cross-check them.
--
-- NOT CHECKED HERE (nothing testable in Alloy; the TLA+ model's)
--   Invariant 1.1 (no party removed), Invariant 5.1 (no verification event changed),
--   Invariant 6.1 to 6.3 (no verification event removed, none appended before a prior one,
--   the list never shortens), Invariant 8.2 (the state change log never shortens),
--   Identity 6 (an assigned id never changed) and Non-goal 3 (an enrollment field never
--   changed): each compares a record with a later version of it, and the page keeps no
--   earlier version beside the record, so one state cannot show it. The writes below are
--   built to keep each of them (an action appends, and copies what it found); that they
--   do is the TLA+ model's to check.
--
-- SCOPE
-- A party version is what one admitted call leaves: [Enroll] records an unverified party
-- (Operation 4 to 7); [Verify] appends a verification event and, on an unverified party
-- with a passed result, stands it verified and appends a state change event (Operation 22
-- to 26, 33, 34, 36); [Suspend], [Reinstate] and [Close] stand it in their state and
-- append a state change event with the reason (Operation 30 to 35). Each version is
-- built from the version its call found, back to the [Enroll] that recorded the party, so
-- a version five calls deep (enroll, verify, suspend, verify, reinstate) is built too. The
-- model does not ask whether the version a call found was still the latest one (that is
-- the sequence, the TLA+ model's), so it builds every record a state can hold and some no
-- state reaches; a check that holds over all of them holds over the records. No trace, no
-- `var`, no stepping.
-- Insertion order: the database instance appends a call's records at the call's commit
-- (Execution Contract Order 1, cited by Capability requirement 10), so the model orders the
-- calls and an event's place in insertion order is its call's. The two events one verify
-- appends share a place; no rule of the page compares them with each other.
-- References, names and the opaque labels are uninterpreted strings; a string in Blank is
-- whitespace-only (String 5), and an absent input reads as blank (String 6). Instants are
-- ordered atoms, and no rule ties them to insertion order: a recorded instant is advisory
-- (Term insertion order, Clock semantics 5, Ordering 4).
--
-- NOT MODELED HERE
--   - [Read] (Operation 48 to 61): a read writes nothing (Operation 55), so it adds no
--     record; its filters and its order are the conformance table's.
--   - The date form and the date of birth start (Operation 2, 3), and the length bound
--     (String 7, Capability requirement 14): a spelling, a value and a length, not a shape.
--     A blank date of birth parses as no date, so [Enroll] refuses it (Operation 2).
--   - Which refusal answers (Execution Contract Refusal 1) and storage failure (Operation
--     39): a refused call writes nothing (Operation 41 to 43), so the model needs only
--     whether a call is admitted.
--   - Duplicate parties (Identity 16, Non-goal 1): the atom does not detect them, so two
--     parties may carry the same enrollment fields (a run below shows it).
--
-- HOW TO READ RESULTS
-- Every "check A_*" must return "No counterexample found" (UNSAT) — the asserted guarantee holds.
-- Every "run Show*" must return at least one instance (SAT) — confirms non-vacuity.
-- A "check" returning a counterexample is a spec finding.

module party_identity

open util/ordering[Instant] as T
open util/ordering[Call] as C

-- ─────────────────────────────────────────────────────────────────────────────
-- Signatures (types)
-- ─────────────────────────────────────────────────────────────────────────────

-- Str: a string a call carries or a record holds — a name, a date of birth, a document
-- type or reference, an acting reference, a method, an evidence reference, a reason, or
-- an assigned id. The atom compares strings byte-exactly and never interprets them
-- (Identity 11, 12, String 1 to 4), so a string is an uninterpreted token.
sig Str {}

-- Blank: the strings the atom reads as blank, the whitespace-only ones (String 5). Which
-- strings these are is the world's, not the atom's, so it is a subset with no rule on it.
sig Blank in Str {}

-- Instant: a moment on the deployment's clock (Term now). Only their order could matter,
-- and the atom reads no ordering from them (Ordering 4), so they are ordered atoms the
-- page's rules never compare.
sig Instant {}

-- State: the four states of a party (Term state).
abstract sig State {}
one sig Unverified, Verified, Suspended, Closed extends State {}

-- Result: a verification result as a caller sends it: passed, failed, or any other
-- string, which Operation 21 refuses.
abstract sig Result {}
one sig Passed, Failed extends Result {}
sig OtherResult extends Result {}

-- Call: one call of a writing action as it reaches the seam (Term writing action). Calls
-- commit in one order (Execution Contract Order 1), the order `C` gives them; `now` is the
-- clock reading the host injects for the call (Capability requirement 1, Term now). No
-- rule ties the two orders.
abstract sig Call {
    now : one Instant
}

-- EnrollCall: one [Enroll] call, enroll(name, date_of_birth, document_type, document_ref,
-- enrolling_actor_ref), with the party id the seam supplies for it (Term id material).
sig EnrollCall extends Call {
    partyIdMat : one Str,    -- the party id material (Capability requirement 2)
    nameIn     : lone Str,   -- name
    dobIn      : lone Str,   -- date_of_birth
    docTypeIn  : lone Str,   -- document_type
    docRefIn   : lone Str,   -- document_ref
    enrollerIn : lone Str    -- enrolling_actor_ref
}

-- PartyCall: one party action (Term party action): the party id it names, its acting
-- reference, and the state change id the seam supplies for it (Term id material; unused
-- by a verify that drives no transition).
abstract sig PartyCall extends Call {
    partyIdIn : lone Str,    -- party_id
    actorIn   : lone Str,    -- the call's acting reference (Term acting reference)
    scIdMat   : one Str      -- the state change id material (Capability requirement 2)
}

-- VerifyCall: one [Verify] call, verify(party_id, verifying_actor_ref,
-- verification_method, verification_result, evidence_ref), with the verification id
-- the seam supplies for it.
sig VerifyCall extends PartyCall {
    verIdMat   : one Str,    -- the verification id material (Capability requirement 2)
    methodIn   : lone Str,   -- verification_method
    resultIn   : lone Result,-- verification_result
    evidenceIn : lone Str    -- evidence_ref
}

-- ReasonedCall: a call of an action that carries a caller-supplied reason (Term reasoned
-- action): suspend, reinstate or close (party_id, acting reference, reason).
abstract sig ReasonedCall extends PartyCall {
    reasonIn : lone Str      -- reason
}
-- The three reasoned actions.
sig SuspendCall, ReinstateCall, CloseCall extends ReasonedCall {}

-- VerificationEvent: the record of one identity check (Term verification event). Every
-- field the page names is here and every one may be absent, so a write that forgot one
-- would show. `appendedBy` is the model's own: the call whose write appended it, which
-- gives its place in insertion order.
sig VerificationEvent {
    verId      : lone Str,     -- verification id (Identity 2)
    verifier   : lone Str,     -- verifying actor reference
    method     : lone Str,     -- verification method
    result     : lone Result,  -- verification result
    evidence   : lone Str,     -- evidence reference
    verifiedAt : lone Instant, -- verification instant
    appendedBy : one Call      -- the call that appended it (model)
}

-- StateChangeEvent: the record of one transition (Term state change event). Every field
-- may be absent, so a write that forgot one would show; `appendedBy` is the model's own,
-- as on a verification event.
sig StateChangeEvent {
    scId       : lone Str,     -- state change id (Identity 3)
    prior      : lone State,   -- the prior state
    new        : lone State,   -- the new state
    actor      : lone Str,     -- the acting reference
    changedAt  : lone Instant, -- the instant
    reason     : lone Str,     -- the reason, where the action carries one (State 6, 7)
    appendedBy : one Call      -- the call that appended it (model)
}

-- Party: one version of a party record (Term party, Term records), as the call that
-- wrote it left it. The state is a set of state flags, so a write that ADDED a state
-- instead of replacing one would show: what the page promises (exactly one) is checked,
-- never built into the type. The last two fields are the model's own: which call wrote
-- this version, and which version of the same party that call found.
sig Party {
    partyId       : lone Str,               -- party id (Identity 1)
    name          : lone Str,               -- name
    dob           : lone Str,               -- date of birth
    docType       : lone Str,               -- document type
    docRef        : lone Str,               -- document reference
    enrolledAt    : lone Instant,           -- enrollment instant
    enrolledBy    : lone Str,               -- enrolling actor reference
    state         : set State,              -- the party's state (State 1)
    verifications : set VerificationEvent,  -- the verification event list (State 3)
    changes       : set StateChangeEvent,   -- the state change log (State 2)
    writtenBy     : one Call,               -- the call whose write left this version (model)
    found         : lone Party              -- the version of this party that call found (model)
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Facts: what the page takes from outside
-- ─────────────────────────────────────────────────────────────────────────────

-- The deployment never supplies the same id material to two calls (Capability
-- requirement 12), and within one verify's id material the verification id is not the
-- state change id (Capability requirement 15). The atom assigns every id from it
-- (Identity 4), so this is where Identity 7 to 9 come from. (Capability requirement 11,
-- id material naming no record, adds nothing here: every record's id is some call's
-- id material.)
fact DeploymentSuppliesFreshIdMaterial {
    all disj a, b : Call | no (material[a] & material[b])
    all c : VerifyCall | c.verIdMat != c.scIdMat
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Helpers
-- ─────────────────────────────────────────────────────────────────────────────

-- material: the id material the seam supplies to one call (Term id material): the party
-- id on [Enroll], the verification id and the state change id on [Verify], the state
-- change id on the other party actions.
fun material[c : Call] : set Str {
    c.partyIdMat + c.verIdMat + c.scIdMat
}

-- nonBlank: a string is present and not whitespace-only. An absent input reads as blank
-- (String 6), and so does an absent field.
pred nonBlank[x : lone Str] {
    some x and x not in Blank
}

-- earlier: one event's call committed before another's, so it comes first in insertion
-- order (Term insertion order).
pred earlier[a, b : Call] {
    C/lt[a, b]
}

-- suspends: the suspend events in a party's state change log — the transitions into
-- suspended, which only [Suspend] makes (Operation 30).
fun suspends[p : Party] : set StateChangeEvent {
    { s : p.changes | s.new = Suspended }
}

-- fresh: the party carries a fresh verification (Term fresh verification): a verification
-- event whose result is passed and that follows the party's most recent suspend in
-- insertion order — follows every suspend, that is — or, where no suspend exists, follows
-- the enrollment, which every event does.
pred fresh[p : Party] {
    some v : p.verifications | v.result = Passed
        and (all s : suspends[p] | earlier[s.appendedBy, v.appendedBy])
}

-- origin: the [Enroll] call that recorded the party this version belongs to — the writer
-- of the first version along the chain of versions found.
fun origin[p : Party] : set Call {
    { v : p.*found | no v.found }.writtenBy
}

-- keepsEnrollment: a party action leaves the party id and every enrollment field as it
-- found them (Identity 6, Non-goal 3, Operation 46; written so here, and checked across
-- steps by the TLA+ model, not here).
pred keepsEnrollment[pre, post : Party] {
    post.partyId    = pre.partyId
    post.name       = pre.name
    post.dob        = pre.dob
    post.docType    = pre.docType
    post.docRef     = pre.docRef
    post.enrolledAt = pre.enrolledAt
    post.enrolledBy = pre.enrolledBy
}

-- ─────────────────────────────────────────────────────────────────────────────
-- [Enroll]: its guards and its write
-- ─────────────────────────────────────────────────────────────────────────────

-- enrollWrites: the party an admitted [Enroll] records (Term admitted enroll).
pred enrollWrites[c : EnrollCall, p : Party] {
    nonBlank[c.nameIn]                         -- Operation 1
    nonBlank[c.docTypeIn]                      -- Operation 1
    nonBlank[c.docRefIn]                       -- Operation 1
    nonBlank[c.enrollerIn]                     -- Operation 1 (an acting reference)
    nonBlank[c.dobIn]                          -- Operation 2 (a blank date parses as no date)
    p.partyId    = c.partyIdMat                -- Operation 4, Identity 4
    p.name       = c.nameIn                    -- Operation 5
    p.dob        = c.dobIn                     -- Operation 5
    p.docType    = c.docTypeIn                 -- Operation 5
    p.docRef     = c.docRefIn                  -- Operation 5
    p.enrolledBy = c.enrollerIn                -- Operation 5
    p.enrolledAt = c.now                       -- Operation 6
    p.state      = Unverified                  -- Operation 7
    no p.verifications
    no p.changes
}

-- ─────────────────────────────────────────────────────────────────────────────
-- The party actions: their guards and their writes
-- ─────────────────────────────────────────────────────────────────────────────

-- partyAdmitted: the checks every party action makes on the party it finds: a party id
-- that is not blank (Operation 10) and names this party (Operation 11), a party not
-- closed (Operation 13), and an acting reference that is not blank (Operation 1).
pred partyAdmitted[pre : Party, c : PartyCall] {
    nonBlank[c.partyIdIn]                      -- Operation 10
    pre.partyId = c.partyIdIn                  -- Operation 11 (byte-exact, Identity 11)
    not pre.state = Closed                     -- Operation 13
    nonBlank[c.actorIn]                        -- Operation 1
}

-- changeAppended: a transitioning action appends one state change event carrying a fresh
-- state change id, the prior state, the new state, the acting reference and now, and the
-- reason where the action is a reasoned one; a verify records none (Operation 33 to 36).
pred changeAppended[pre : Party, c : PartyCall, post : Party, to : State] {
    some s : StateChangeEvent {
        s.appendedBy = c
        post.changes = pre.changes + s                          -- Operation 33, Invariant 8.1
        s.scId       = c.scIdMat                                -- Operation 33, Identity 4
        s.prior      = pre.state                                -- Operation 34
        s.new        = to                                       -- Operation 34
        s.actor      = c.actorIn                                -- Operation 34, Term acting reference
        s.changedAt  = c.now                                    -- Operation 34
        c in ReasonedCall implies s.reason = c.reasonIn         -- Operation 35
        c in VerifyCall implies no s.reason                     -- Operation 36
    }
}

-- verificationAppended: an admitted verify appends one verification event carrying a
-- fresh verification id, the verifying actor reference, the method, the result, the
-- evidence reference and now (Operation 22 to 24).
pred verificationAppended[pre : Party, c : VerifyCall, post : Party] {
    some v : VerificationEvent {
        v.appendedBy = c
        post.verifications = pre.verifications + v              -- Operation 22
        v.verId      = c.verIdMat                               -- Operation 22, Identity 4
        v.verifier   = c.actorIn                                -- Operation 23
        v.method     = c.methodIn                               -- Operation 23
        v.result     = c.resultIn                               -- Operation 23
        v.evidence   = c.evidenceIn                             -- Operation 23
        v.verifiedAt = c.now                                    -- Operation 24
    }
}

-- verifyWrites: the version an admitted [Verify] leaves over the version it found. A
-- passed check on an unverified party stands it verified and logs the transition; any
-- other check changes no state and logs none (Operation 25, 26, 29).
pred verifyWrites[pre : Party, c : VerifyCall, post : Party] {
    partyAdmitted[pre, c]
    nonBlank[c.methodIn]                                        -- Operation 1
    nonBlank[c.evidenceIn]                                      -- Operation 1
    one c.resultIn and c.resultIn in Passed + Failed            -- Operation 21
    verificationAppended[pre, c, post]
    (pre.state = Unverified and c.resultIn = Passed) implies {
        post.state = Verified                                   -- Operation 25
        changeAppended[pre, c, post, Verified]
    } else {
        post.state   = pre.state                                -- Operation 26
        post.changes = pre.changes                              -- no transition, no state change event
    }
}

-- suspendWrites: the version an admitted [Suspend] leaves: refused on an unverified or a
-- suspended party, it stands the party suspended (Operation 14, 15, 30).
pred suspendWrites[pre : Party, c : SuspendCall, post : Party] {
    partyAdmitted[pre, c]
    not pre.state = Unverified                                  -- Operation 14
    not pre.state = Suspended                                   -- Operation 15
    nonBlank[c.reasonIn]                                        -- Operation 1
    post.state = Suspended                                      -- Operation 30
    post.verifications = pre.verifications
    changeAppended[pre, c, post, Suspended]
}

-- reinstateWrites: the version an admitted [Reinstate] leaves: refused on an unverified
-- or a verified party, and on a suspended one carrying no fresh verification, it stands
-- the party verified (Operation 16, 18, 31).
pred reinstateWrites[pre : Party, c : ReinstateCall, post : Party] {
    partyAdmitted[pre, c]
    not (pre.state = Unverified or pre.state = Verified)        -- Operation 16
    not (pre.state = Suspended and not fresh[pre])              -- Operation 18
    nonBlank[c.reasonIn]                                        -- Operation 1
    post.state = Verified                                       -- Operation 31
    post.verifications = pre.verifications
    changeAppended[pre, c, post, Verified]
}

-- closeWrites: the version an admitted [Close] leaves: it stands any party not closed in
-- closed (Operation 32).
pred closeWrites[pre : Party, c : CloseCall, post : Party] {
    partyAdmitted[pre, c]
    nonBlank[c.reasonIn]                                        -- Operation 1
    post.state = Closed                                         -- Operation 32
    post.verifications = pre.verifications
    changeAppended[pre, c, post, Closed]
}

-- partyWrites: the version an admitted party action leaves, by the action called.
pred partyWrites[pre : Party, c : PartyCall, post : Party] {
    c in VerifyCall    implies verifyWrites[pre, c, post]
    c in SuspendCall   implies suspendWrites[pre, c, post]
    c in ReinstateCall implies reinstateWrites[pre, c, post]
    c in CloseCall     implies closeWrites[pre, c, post]
}

-- written: the version is what its call's write left — an [Enroll]'s new party, or a
-- party action's write over a version an earlier call wrote (a call finds only what was
-- committed before it, Execution Contract Database 2).
pred written[p : Party] {
    let c = p.writtenBy {
        (c in EnrollCall and no p.found and enrollWrites[c, p])
        or (c in PartyCall and some p.found and earlier[p.found.writtenBy, c]
            and keepsEnrollment[p.found, p] and partyWrites[p.found, c, p])
    }
}

-- recorded: a version the page lets the records hold (see SCOPE): it and every version
-- it was built from are what an admitted call wrote.
pred recorded[p : Party] {
    all v : p.*found | written[v]
}

-- replays: the party's state change log, read in insertion order, starts from unverified,
-- each event leaves the state the next one found, and the last leaves the party's state;
-- an empty log leaves the party unverified (Check 5.1).
pred replays[p : Party] {
    no p.changes implies p.state = Unverified
    all s : p.changes | (no t : p.changes | earlier[t.appendedBy, s.appendedBy])
        implies s.prior = Unverified
    all s : p.changes | (no t : p.changes | earlier[s.appendedBy, t.appendedBy])
        implies s.new = p.state
    all s, t : p.changes | (earlier[s.appendedBy, t.appendedBy]
        and no u : p.changes | earlier[s.appendedBy, u.appendedBy] and earlier[u.appendedBy, t.appendedBy])
        implies t.prior = s.new
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Assertions (verified guarantees)
-- Each "check" asks: is there any record the page's calls can leave that violates this
-- assertion? No counterexample (UNSAT) = the guarantee holds within scope.
-- ─────────────────────────────────────────────────────────────────────────────

-- A_State_1: every party carries its party id, every enrollment field (name, date of
-- birth, document type, document reference, enrollment instant, enrolling actor
-- reference) and a state, whatever call last wrote it.
assert A_State_1 {
    all p : Party | recorded[p] implies {
        some p.partyId
        some p.name and some p.dob and some p.docType and some p.docRef
        some p.enrolledAt and some p.enrolledBy
        some p.state
    }
}
check A_State_1 for 5 but 8 Str, 3 Instant, 3 Result

-- A_State_4: every verification event carries its verification id, verifying actor
-- reference, method, result, evidence reference and verification instant: what an
-- auditor reads to know who checked, how, on what evidence, and what they found.
assert A_State_4 {
    all p : Party, v : p.verifications | recorded[p] implies {
        some v.verId and some v.verifier and some v.method
        some v.result and some v.evidence and some v.verifiedAt
    }
}
check A_State_4 for 5 but 8 Str, 3 Instant, 3 Result

-- A_State_5: every state change event carries its state change id, the prior state, the
-- new state, an acting reference and an instant, whichever action appended it.
assert A_State_5 {
    all p : Party, s : p.changes | recorded[p] implies {
        some s.scId and some s.prior and some s.new
        some s.actor and some s.changedAt
    }
}
check A_State_5 for 5 but 8 Str, 3 Instant, 3 Result

-- A_State_7: every state change event a reasoned action (suspend, reinstate, close)
-- appended carries a reason: no revocation, restoration or closure without its stated basis.
assert A_State_7 {
    all p : Party, s : p.changes | (recorded[p] and s.appendedBy in ReasonedCall)
        implies some s.reason
}
check A_State_7 for 5 but 8 Str, 3 Instant, 3 Result

-- A_Operation_21: every verification event's result is exactly one of passed, failed:
-- the record holds no third outcome a reader would have to interpret.
assert A_Operation_21 {
    all p : Party, v : p.verifications | recorded[p]
        implies (one v.result and v.result in Passed + Failed)
}
check A_Operation_21 for 5 but 8 Str, 3 Instant, 3 Result

-- A_Operation_36: no state change event a verify appended carries a reason: on a
-- verify-driven transition the verification event is the basis, not a reason.
assert A_Operation_36 {
    all p : Party, s : p.changes | (recorded[p] and s.appendedBy in VerifyCall)
        implies no s.reason
}
check A_Operation_36 for 5 but 8 Str, 3 Instant, 3 Result

-- A_Invariant_2_1: every party stands in exactly one of the four states. Each write
-- replaces the state it found with its own.
assert A_Invariant_2_1 {
    all p : Party | recorded[p] implies one p.state
}
check A_Invariant_2_1 for 5 but 8 Str, 3 Instant, 3 Result

-- A_Invariant_3_1: read off one record — no transition in a party's state change log
-- leaves closed. Every transition is logged with the state it left (Invariant 8.1,
-- Operation 34), so a party that left closed would carry an event whose prior state is
-- closed. (That a closed party stays closed from one version to the next is the TLA+
-- model's, Inv3_ClosedAbsorbing.)
assert A_Invariant_3_1 {
    all p : Party, s : p.changes | recorded[p] implies not s.prior = Closed
}
check A_Invariant_3_1 for 5 but 8 Str, 3 Instant, 3 Result

-- A_Invariant_4_1: every verified party carries a fresh verification — a passed check
-- recorded after its most recent suspend in insertion order. The atom's central
-- guarantee: verified rests on a recorded check, not a flipped flag.
assert A_Invariant_4_1 {
    all p : Party | (recorded[p] and p.state = Verified) implies fresh[p]
}
check A_Invariant_4_1 for 5 but 8 Str, 3 Instant, 3 Result

-- A_Invariant_8_1: read off one record, as Check 5.1 reads it — the state change log
-- replays in insertion order from unverified to the party's state. A transitioning action
-- that appended no state change event would leave a state the log cannot reach.
assert A_Invariant_8_1 {
    all p : Party | recorded[p] implies replays[p]
}
check A_Invariant_8_1 for 5 but 8 Str, 3 Instant, 3 Result

-- A_Identity_5: every assigned id a record carries is the id material the seam supplied
-- for it: the party id its [Enroll] was given, the verification id and the state change id
-- the appending call was given (Identity 4). The atom generates no id of its own — none
-- from an enrollment field, a reference or another record's id.
assert A_Identity_5 {
    all p : Party | recorded[p] implies {
        p.partyId = origin[p].partyIdMat
        all v : p.verifications | v.verId = v.appendedBy.verIdMat
        all s : p.changes | s.scId = s.appendedBy.scIdMat
    }
}
check A_Identity_5 for 5 but 8 Str, 3 Instant, 3 Result

-- A_Identity_7: two parties never share a party id. Versions recorded by different
-- [Enroll] calls are different parties, even where every enrollment field is the same
-- (the atom does not deduplicate, Non-goal 1).
assert A_Identity_7 {
    all p1, p2 : Party | (recorded[p1] and recorded[p2] and origin[p1] != origin[p2])
        implies p1.partyId != p2.partyId
}
check A_Identity_7 for 5 but 8 Str, 3 Instant, 3 Result

-- A_Identity_8: two verification events never share a verification id. Events appended by
-- different calls are different events (each admitted verify appends one, Operation 22),
-- on one party or on two.
assert A_Identity_8 {
    all p1, p2 : Party, v1 : p1.verifications, v2 : p2.verifications |
        (recorded[p1] and recorded[p2] and v1.appendedBy != v2.appendedBy)
            implies v1.verId != v2.verId
}
check A_Identity_8 for 5 but 8 Str, 3 Instant, 3 Result

-- A_Identity_9: two state change events never share a state change id, so an attestation
-- bound to one names one transition (Composition note 5). Events appended by different
-- calls are different events (each transitioning action appends one, Operation 33).
assert A_Identity_9 {
    all p1, p2 : Party, s1 : p1.changes, s2 : p2.changes |
        (recorded[p1] and recorded[p2] and s1.appendedBy != s2.appendedBy)
            implies s1.scId != s2.scId
}
check A_Identity_9 for 5 but 8 Str, 3 Instant, 3 Result

-- ─────────────────────────────────────────────────────────────────────────────
-- Satisfiability runs — non-vacuity guards, one for each shape the page admits
-- Each run must find at least one instance (SAT).
-- UNSAT means the model forbids a record the page admits.
-- ─────────────────────────────────────────────────────────────────────────────

-- ShowEnrolled: a party just enrolled, unverified, with no event yet.
run ShowEnrolled {
    some p : Party | recorded[p] and no p.found and p.state = Unverified
} for 5 but 8 Str, 3 Instant, 3 Result

-- ShowVerifiedByAPassedCheck: the banking example — a passed check on an unverified party
-- stands it verified, appending a verification event and a state change event with no reason.
run ShowVerifiedByAPassedCheck {
    some p : Party | recorded[p] and p.state = Verified
        and one p.verifications and one p.changes and no p.changes.reason
} for 5 but 8 Str, 3 Instant, 3 Result

-- ShowFailedCheckChangesNothing: the healthcare example — a failed check is recorded and
-- the party stays unverified, with no state change event.
run ShowFailedCheckChangesNothing {
    some p : Party | recorded[p] and p.state = Unverified
        and some p.verifications and p.verifications.result = Failed and no p.changes
} for 5 but 8 Str, 3 Instant, 3 Result

-- ShowCheckRecordedOnAVerifiedParty: a second passed check on a verified party is
-- recorded and drives no transition (Operation 26, 29).
run ShowCheckRecordedOnAVerifiedParty {
    some p : Party | recorded[p] and p.state = Verified
        and #p.verifications = 2 and one p.changes
} for 5 but 8 Str, 3 Instant, 3 Result

-- ShowCheckDuringSuspension: the sanctions example — a passed check recorded after the
-- suspend leaves the party suspended: evidence gathered during an investigation does not
-- clear it.
run ShowCheckDuringSuspension {
    some p : Party | recorded[p] and p.state = Suspended and fresh[p]
} for 5 but 8 Str, 3 Instant, 3 Result

-- ShowReinstated: the sanctions example's end — a suspended party with a fresh
-- verification reinstated to verified.
run ShowReinstated {
    some p : Party, s : p.changes | recorded[p] and p.state = Verified
        and s.prior = Suspended and s.new = Verified
} for 5 but 8 Str, 3 Instant, 3 Result

-- ShowClosedInError: the enrollment-in-error example — an unverified party closed at
-- once, with its reason; the record persists in closed.
run ShowClosedInError {
    some p : Party | recorded[p] and p.state = Closed and no p.verifications
        and one p.changes and p.changes.prior = Unverified
} for 5 but 8 Str, 3 Instant, 3 Result

-- ShowClosedWhileSuspended: close stands any party that is not closed in closed, a
-- suspended one among them.
run ShowClosedWhileSuspended {
    some p : Party, s : p.changes | recorded[p] and p.state = Closed
        and s.prior = Suspended and s.new = Closed
} for 5 but 8 Str, 3 Instant, 3 Result

-- ShowTwoPartiesOneEnrollment: two parties enrolled with the same enrollment fields, each
-- under its own party id: the atom does not detect a duplicate (Non-goal 1, Identity 16).
run ShowTwoPartiesOneEnrollment {
    some p1, p2 : Party | recorded[p1] and recorded[p2] and no p1.found and no p2.found
        and origin[p1] != origin[p2]
        and p1.name = p2.name and p1.dob = p2.dob and p1.docType = p2.docType
        and p1.docRef = p2.docRef
} for 5 but 8 Str, 3 Instant, 3 Result

-- ShowInstantAgainstInsertionOrder: a reinstated party whose fresh verification carries
-- an instant earlier than its suspend's: the clock went back, insertion order decides
-- (Ordering 3, 4), and the reinstatement stands.
run ShowInstantAgainstInsertionOrder {
    some p : Party, v : p.verifications, s : suspends[p] | recorded[p]
        and p.state = Verified and v.result = Passed
        and earlier[s.appendedBy, v.appendedBy] and T/lt[v.verifiedAt, s.changedAt]
} for 5 but 8 Str, 3 Instant, 3 Result
