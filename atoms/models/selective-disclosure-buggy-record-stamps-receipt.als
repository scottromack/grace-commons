-- selective-disclosure-buggy-record-stamps-receipt.als
-- DELIBERATELY WRONG twin of selective-disclosure.als (unit: `atoms/selective-disclosure.md formal layer`).
--
-- INJECTED DEFECT: [Record] stamps the now it read as a receipt instant beside the disclosure instant (State 10).
--
-- BREAKS: A_State_10.
-- Everything else is selective-disclosure.als as written; read its comments there.

module selective_disclosure_buggy_record_stamps_receipt

-- ─────────────────────────────────────────────────────────────────────────────
-- Signatures (types)
-- ─────────────────────────────────────────────────────────────────────────────

-- Str: a string a call carries: a subject reference, a recipient, a scope, an authority
-- reference, or the further field an authority may carry (Term string input). The atom
-- never interprets one (Identity 13, 14), so a string is an uninterpreted token and two
-- different strings are two different atoms.
sig Str {}

-- Strings: which strings the guards refuse, and how a string could be respelled: the
-- blank ones (Operation 1 to 3, 6; String 5, 6), the empty ones among them (String 6:
-- the absent or empty string, beside the whitespace-only ones of String 5), the ones
-- longer than the string cap (Operation 44), and, for a string, the other spelling a
-- trim, a normalization or a case fold would give it (String 2 to 4). The atom applies
-- none of these: respelled is in the type so a write that applied one would show.
one sig Strings {
    blank     : set Str,
    empty     : set Str,
    overCap   : set Str,
    respelled : Str -> lone Str
}

-- Id: a disclosure id, the opaque string naming one disclosure record (Term disclosure
-- id). The host allocates it at the seam (Capability requirement 9); the atom only
-- records it (Operation 11).
sig Id {}

-- AType: a value a call's authority type may carry (Term authority type).
abstract sig AType {}

-- Consent, LegalHold, Regulatory: the authority types, the three members of authority
-- type (Term authority types).
one sig Consent, LegalHold, Regulatory extends AType {}

-- OtherType: a value outside the authority types, such as legitimate-interest, which
-- Operation 9 refuses.
sig OtherType extends AType {}

-- Status: a lifecycle state a build could keep on a record. The page offers none (State
-- 2); it is in the type so a write that stamped one would show.
abstract sig Status {}

-- Active, Retracted: two states a record could be stamped with.
one sig Active, Retracted extends Status {}

-- RecordCall: one [Record] call, record(subject_ref, recipient, scope, authority,
-- optional disclosed_at), with what the host injects at the seam for it (Term seam):
-- now and the disclosure id. The authority carries its authority type (absent where
-- blank), its authority reference, and possibly a further field (Term authority).
-- atIn is the supplied disclosure instant, absent where the call left it blank.
sig RecordCall {
    now       : one Int,     -- the injected now (Capability requirement 1)
    hostId    : one Id,      -- the injected disclosure id (Capability requirement 9)
    subjIn    : one Str,     -- subject_ref
    recipIn   : one Str,     -- recipient
    scopeIn   : one Str,     -- scope
    typeIn    : lone AType,  -- authority.type (absent: blank)
    refIn     : one Str,     -- authority.reference
    furtherIn : lone Str,    -- a further field the authority carries
    atIn      : lone Int     -- disclosed_at (absent: left blank)
}

-- MalformedAt: the calls whose supplied disclosure instant is no instant (Operation 38).
-- Such a call supplied something, so it did not leave the instant blank.
sig MalformedAt in RecordCall {}

-- WriteRefused: the calls whose write the database refuses (Operation 14).
sig WriteRefused in RecordCall {}

-- Rec: one disclosure record (Term records), as the call that wrote it left it. Every
-- field may be absent, so a write that forgot one would show; what the page promises
-- (State 1) is checked, never built into the type. further, receivedAt and state are
-- the fields State 3, State 10 and State 2 forbid, in the type so a write that stored
-- one would show. writtenBy is the model's own: the call that wrote it.
sig Rec {
    id         : lone Id,      -- disclosure id
    subject    : lone Str,     -- subject reference
    recipient  : lone Str,     -- recipient
    scope      : lone Str,     -- scope
    atype      : lone AType,   -- authority type
    aref       : lone Str,     -- authority reference
    at         : lone Int,     -- disclosure instant
    further    : lone Str,     -- a recorded further authority field (forbidden, State 3)
    receivedAt : lone Int,     -- a receipt instant (forbidden, State 10)
    state      : set Status,   -- a lifecycle state (forbidden, State 2)
    writtenBy  : one RecordCall
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Facts: what the page takes from outside
-- ─────────────────────────────────────────────────────────────────────────────

-- The empty strings are blank (String 6: an absent string input reads as blank); the
-- blank strings beside them are the whitespace-only ones (String 5). This is the
-- meaning of the words, GRACE-lang Term blank, not a promise of the page.
fact EmptyIsBlank {
    Strings.empty in Strings.blank
}

-- A supplied value that is no instant carries no instant (Operation 38).
fact MalformedCarriesNoInstant {
    all c : MalformedAt | no c.atIn
}

-- The host supplies one disclosure id to one call (Execution Contract Logic confinement
-- 16, cited by Capability requirement 9): no two calls carry one injected id. The atom
-- takes the id from outside; whether the host keeps this duty across steps is checked in
-- the TLA+ model (Cap9_HostIdFresh).
fact HostSuppliesAnIdToOneCall {
    all disj c1, c2 : RecordCall | c1.hostId != c2.hostId
}

-- ─────────────────────────────────────────────────────────────────────────────
-- The writing action: its guards and its write
-- ─────────────────────────────────────────────────────────────────────────────

-- resolved: the resolved disclosure instant of a call: the supplied disclosure instant,
-- or now where the call left it blank (Term resolved disclosure instant, Execution
-- Contract Logic confinement 12).
fun resolved[c : RecordCall] : lone Int {
    (some c.atIn) => c.atIn else c.now
}

-- recordWrites: the record an admitted [Record] writes, and the guards it passes first:
-- no blank subject reference, recipient, scope or authority reference (Operation 1, 2,
-- 3, 6), no blank authority type (Operation 4, 5), no string input over the cap
-- (Operation 44), a supplied disclosure instant that is an instant (Operation 38), now
-- not preceding the resolved disclosure instant (Operation 7), an authority type in the
-- authority types (Operation 9), the database accepting the write (Operation 14). The
-- record carries the injected disclosure id (Operation 11), the call's subject
-- reference, recipient and scope as the call carried them (Execution Contract Input 4;
-- Identity 11, 13, 14), the call's authority type and authority reference (Operation 42,
-- 43), the resolved disclosure instant (Operation 12), and nothing else: no further
-- authority field (Term authority, State 3), no receipt instant (State 10), no state
-- (State 2).
pred recordWrites[c : RecordCall, r : Rec] {
    c.subjIn not in Strings.blank                                     -- Operation 1
    c.recipIn not in Strings.blank                                    -- Operation 2
    c.scopeIn not in Strings.blank                                    -- Operation 3
    some c.typeIn                                                     -- Operation 4, 5
    c.refIn not in Strings.blank                                      -- Operation 6
    no ((c.subjIn + c.recipIn + c.scopeIn + c.refIn) & Strings.overCap) -- Operation 44
    c not in MalformedAt                                              -- Operation 38
    not (c.now < resolved[c])                                         -- Operation 7
    c.typeIn in Consent + LegalHold + Regulatory                      -- Operation 9
    c not in WriteRefused                                             -- Operation 14
    r.id        = c.hostId                                            -- Operation 11
    r.subject   = c.subjIn                                            -- Identity 11
    r.recipient = c.recipIn                                           -- Identity 14
    r.scope     = c.scopeIn                                           -- Identity 13
    r.atype     = c.typeIn                                            -- Operation 42
    r.aref      = c.refIn                                             -- Operation 43
    r.at        = resolved[c]                                         -- Operation 12
    no r.further                                                      -- State 3
    r.receivedAt = c.now  -- BUG: a receipt instant
    no r.state                                                        -- State 2
}

-- recorded: a disclosure record the page lets the database hold: what its call's write
-- left.
pred recorded[r : Rec] {
    recordWrites[r.writtenBy, r]
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Assertions (verified guarantees)
-- Each "check" asks: is there any state the page's calls can leave that violates this
-- assertion? No counterexample (UNSAT) = the guarantee holds within scope.
-- ─────────────────────────────────────────────────────────────────────────────

-- A_State_1: every disclosure record carries its seven fields: disclosure id, subject
-- reference, recipient, scope, authority type, authority reference and disclosure
-- instant (State 1, Check 2.1).
assert A_State_1 {
    all r : Rec | recorded[r] implies {
        some r.id
        some r.subject
        some r.recipient
        some r.scope
        some r.atype
        some r.aref
        some r.at
    }
}
check A_State_1 for 4

-- A_State_2: no disclosure record carries a lifecycle state: the atom offers no state
-- machine over a record (State 2).
assert A_State_2 {
    all r : Rec | recorded[r] implies no r.state
}
check A_State_2 for 4

-- A_State_3: no disclosure record carries an optional field: a further field the call's
-- authority carries is not recorded (State 3, Term authority).
assert A_State_3 {
    all r : Rec | recorded[r] implies no r.further
}
check A_State_3 for 4

-- A_State_10: no disclosure record carries a receipt instant: when the deployment
-- received the call is a composing Event Log's to hold (State 10, External check 3).
assert A_State_10 {
    all r : Rec | recorded[r] implies no r.receivedAt
}
check A_State_10 for 4

-- A_Identity_5: no two disclosure records, written by two [Record] calls, share a
-- disclosure id (Identity 5, Check 2.4).
assert A_Identity_5 {
    all r1, r2 : Rec | (recorded[r1] and recorded[r2] and r1.writtenBy != r2.writtenBy)
        implies no (r1.id & r2.id)
}
check A_Identity_5 for 4

-- A_Identity_11: every record's subject reference is the one its call carried, as the
-- seam canonicalized it: the atom normalizes none (Identity 11, String 3).
assert A_Identity_11 {
    all r : Rec | recorded[r] implies r.subject = r.writtenBy.subjIn
}
check A_Identity_11 for 4

-- A_Identity_13: every record's scope is the one its call carried: the atom interprets
-- none, and trims none (Identity 13, String 2).
assert A_Identity_13 {
    all r : Rec | recorded[r] implies r.scope = r.writtenBy.scopeIn
}
check A_Identity_13 for 4

-- A_Identity_14: every record's recipient is the one its call carried: the atom
-- interprets none, and case-folds none (Identity 14, String 4).
assert A_Identity_14 {
    all r : Rec | recorded[r] implies r.recipient = r.writtenBy.recipIn
}
check A_Identity_14 for 4

-- A_Invariant_2_1: every record's authority type stands in the authority types:
-- consent, legal-hold or regulatory, and no fourth (Invariant 2.1, Check 2.3).
assert A_Invariant_2_1 {
    all r : Rec | recorded[r] implies
        (some r.atype and r.atype in Consent + LegalHold + Regulatory)
}
check A_Invariant_2_1 for 4

-- A_Invariant_3_2: every record's subject reference, recipient, scope and authority
-- reference stand non-blank (Invariant 3.2, Check 2.2).
assert A_Invariant_3_2 {
    all r : Rec | recorded[r] implies
        no ((r.subject + r.recipient + r.scope + r.aref) & Strings.blank)
}
check A_Invariant_3_2 for 4

-- A_Invariant_4_1: no record's disclosure instant follows the now its creation read: a
-- disclosure is never recorded as happening later than it was keyed (Invariant 4.1).
assert A_Invariant_4_1 {
    all r : Rec | recorded[r] implies
        (all t : r.at | not (r.writtenBy.now < t))
}
check A_Invariant_4_1 for 4

-- A_Operation_1: no record comes from a call carrying a blank subject reference
-- (Operation 1).
assert A_Operation_1 {
    all r : Rec | recorded[r] implies r.writtenBy.subjIn not in Strings.blank
}
check A_Operation_1 for 4

-- A_Operation_2: no record comes from a call carrying a blank recipient (Operation 2).
assert A_Operation_2 {
    all r : Rec | recorded[r] implies r.writtenBy.recipIn not in Strings.blank
}
check A_Operation_2 for 4

-- A_Operation_3: no record comes from a call carrying a blank scope (Operation 3).
assert A_Operation_3 {
    all r : Rec | recorded[r] implies r.writtenBy.scopeIn not in Strings.blank
}
check A_Operation_3 for 4

-- A_Operation_6: no record comes from a call carrying a blank authority reference, a
-- whitespace-only one included (Operation 6, String 5).
assert A_Operation_6 {
    all r : Rec | recorded[r] implies r.writtenBy.refIn not in Strings.blank
}
check A_Operation_6 for 4

-- A_Operation_11: every record's disclosure id is the one the host injected for its
-- call: the atom mints none (Operation 11, Execution Contract Logic confinement 3).
assert A_Operation_11 {
    all r : Rec | recorded[r] implies r.id = r.writtenBy.hostId
}
check A_Operation_11 for 4

-- A_Operation_12: every record's disclosure instant is its call's resolved disclosure
-- instant: the supplied one, backdated or not, or now where the call left it blank
-- (Operation 12, Execution Contract Logic confinement 12).
assert A_Operation_12 {
    all r : Rec | recorded[r] implies
        r.at = ((some r.writtenBy.atIn) => r.writtenBy.atIn else r.writtenBy.now)
}
check A_Operation_12 for 4

-- A_Operation_38: no record comes from a call whose supplied disclosure instant is no
-- instant (Operation 38).
assert A_Operation_38 {
    all r : Rec | recorded[r] implies r.writtenBy not in MalformedAt
}
check A_Operation_38 for 4

-- A_Operation_42: every record's authority type is its call's (Operation 42).
assert A_Operation_42 {
    all r : Rec | recorded[r] implies r.atype = r.writtenBy.typeIn
}
check A_Operation_42 for 4

-- A_Operation_43: every record's authority reference is its call's (Operation 43).
assert A_Operation_43 {
    all r : Rec | recorded[r] implies r.aref = r.writtenBy.refIn
}
check A_Operation_43 for 4

-- A_Operation_44: no record comes from a call whose subject reference, recipient, scope
-- or authority reference exceeds the string cap (Operation 44).
assert A_Operation_44 {
    all r : Rec | recorded[r] implies
        no ((r.writtenBy.subjIn + r.writtenBy.recipIn + r.writtenBy.scopeIn
             + r.writtenBy.refIn) & Strings.overCap)
}
check A_Operation_44 for 4

-- ─────────────────────────────────────────────────────────────────────────────
-- Satisfiability runs — non-vacuity guards, one for each shape the page admits
-- Each run must find at least one instance (SAT).
-- UNSAT means the model forbids a state the page admits.
-- ─────────────────────────────────────────────────────────────────────────────

-- ShowRecorded: one disclosure record, as the consent disclosure of patient-88213 to
-- Northgate Research Institute.
run ShowRecorded {
    some r : Rec | recorded[r]
} for 4

-- ShowBackdated: a record whose disclosure instant precedes the now its call read, as
-- the regulatory report keyed two hours after it was sent (Operation 7, Non-goal 21).
run ShowBackdated {
    some r : Rec | recorded[r] and some r.writtenBy.atIn and r.at < r.writtenBy.now
} for 4

-- ShowDefaulted: a record whose call left the disclosure instant blank, carrying now
-- (Execution Contract Logic confinement 12).
run ShowDefaulted {
    some r : Rec | recorded[r] and no r.writtenBy.atIn and r.at = r.writtenBy.now
} for 4

-- ShowTwoForOneSubject: two records of one subject reference, under two authority
-- types, which the page admits: the subject reference is no record's identity
-- (Identity 7, 8).
run ShowTwoForOneSubject {
    some r1, r2 : Rec | recorded[r1] and recorded[r2] and r1.writtenBy != r2.writtenBy
        and r1.subject = r2.subject and r1.atype != r2.atype
} for 4

-- ShowOneFieldSetTwice: two records from two calls carrying one field set, which the
-- page admits as two disclosures (Non-goal 14).
run ShowOneFieldSetTwice {
    some r1, r2 : Rec | recorded[r1] and recorded[r2] and r1.writtenBy != r2.writtenBy
        and r1.subject = r2.subject and r1.recipient = r2.recipient
        and r1.scope = r2.scope and r1.atype = r2.atype and r1.aref = r2.aref
        and r1.at = r2.at
} for 4

-- ShowRefused: a call with a future disclosure instant leaves no record, while another
-- call's record stands (Operation 7, Operation 16).
run ShowRefused {
    some c : RecordCall | c.now < resolved[c] and (no r : Rec | recorded[r] and r.writtenBy = c)
    some r : Rec | recorded[r]
} for 4
