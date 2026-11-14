-- erasure-tombstone-buggy-payload-accepted.als
-- DELIBERATELY WRONG twin of erasure-tombstone.als (unit: `atoms/erasure-tombstone.md formal layer`).
-- INJECTED DEFECT: [Record Destruction] accepts a call that names fields of the destroyed record beside
-- the pattern and the id, and drops them (Invariant 3.2): nothing of them is kept, but the
-- atom took them in.
-- BREAKS: A_Invariant_3_2.
-- Everything else is erasure-tombstone.als as written; read its comments there.

module erasure_tombstone_buggy_payload_accepted

open util/ordering[Call] as C

-- ─────────────────────────────────────────────────────────────────────────────
-- Signatures (types)
-- ─────────────────────────────────────────────────────────────────────────────

-- Text: a string a call carries as a destroyed pattern, a destroyed id, an authority
-- reference or an actor reference. The atom compares a string byte-exactly and never trims,
-- normalizes or case-folds it (String 1 to 4), so two different strings are two atoms.
abstract sig Text {}

-- Empty: the empty string.
one sig Empty extends Text {}

-- Spaces: a string of whitespace only, which the atom reads as blank (String 5).
sig Spaces extends Text {}

-- Word: a string with a character that is not whitespace, such as "event-log" or "inv_8c21".
sig Word extends Text {}

-- Strings: which strings are longer than the caps the deployment runs with, counted in
-- Unicode code points (Term reference cap, 256 by default; Term pattern name cap, 128 by
-- default; Execution Contract Input 2). Which ones they are is the world's.
one sig Strings {
    overReferenceCap : set Text,
    overPatternCap   : set Text
}

-- Normalizer: what an interpreting build would rewrite a string to (trimmed, Unicode-
-- normalized or case-folded). The atom never applies it (Identity 2 to 4, String 2 to 4);
-- it is here so a run can show two strings it would merge, and a twin can apply it.
one sig Normalizer {
    interp : Text -> lone Text
}

-- Kind: an authority kind a call may carry (Term authority kind).
abstract sig Kind {}

-- RetentionPurge: the authority kind retention-purge, which every deployment recognizes
-- (Capability requirement 4).
one sig RetentionPurge extends Kind {}

-- ErasureRequest: the authority kind erasure-request, which every deployment recognizes
-- (Capability requirement 5).
one sig ErasureRequest extends Kind {}

-- OtherKind: any other kind a call may carry: one the deployment declared, such as a court
-- order, or one nobody declared, such as "cleanup" (Examples, Rejection paths).
sig OtherKind extends Kind {}

-- Deployment: the deployment kinds the deployment declared (Capability requirement 3).
one sig Deployment {
    declaredKinds : set OtherKind
}

-- Instant: a clock reading.
sig Instant {}

-- Content: a field value of a destroyed record — a billing amount, a person's preference —
-- which a caller might pass and a tombstone must never hold (Invariant 3).
sig Content {}

-- Call: one [Record Destruction] call, record_destruction(destroyed_pattern, destroyed_id,
-- authority_kind, authority_ref, actor_ref), with the clock reading the host injects at the
-- seam (Term now). contentIn and instantIn are what a caller might send beyond the
-- signature: fields of the destroyed record and an instant of its own choosing. Calls commit
-- in one order (Execution Contract Order 1), the order util/ordering gives them.
sig Call {
    patternIn : one Text,      -- destroyed_pattern
    idIn      : one Text,      -- destroyed_id
    kindIn    : one Kind,      -- authority_kind
    authIn    : one Text,      -- authority_ref
    actorIn   : one Text,      -- actor_ref
    contentIn : set Content,   -- fields of the destroyed record the caller passes (none, here)
    instantIn : lone Instant,  -- a destruction instant the caller supplies (none, here)
    now       : one Instant    -- the injected clock reading
}

-- Tombstone: one erasure tombstone (Term records), as the call that wrote it left it. Every
-- field the page names may be absent here, so a write that forgot one would show; what the
-- page promises (State 1) is checked, never built into the type. carries is any field of
-- the destroyed record the tombstone holds beside its pattern and id (State 4: none).
-- writtenBy is the model's own: the call whose write left the tombstone.
sig Tombstone {
    pattern   : lone Text,      -- destroyed pattern
    id        : lone Text,      -- destroyed id
    at        : lone Instant,   -- destruction instant
    kind      : lone Kind,      -- authority kind
    authRef   : lone Text,      -- authority reference
    actorRef  : lone Text,      -- actor reference
    carries   : set Content,    -- a payload of the destroyed record
    writtenBy : one Call
}

-- DB: one state of the database: the tombstones it holds. found and madeBy are the model's
-- own: the database the last call found, and that call.
sig DB {
    tombstones : set Tombstone,
    found      : lone DB,
    madeBy     : lone Call
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Helpers
-- ─────────────────────────────────────────────────────────────────────────────

-- blank: the strings the atom reads as blank: the empty string and every whitespace-only
-- string (String 5).
fun blank : set Text { Empty + Spaces }

-- recognized: retention-purge, erasure-request and every deployment kind the deployment
-- declared (Term recognized kinds).
fun recognized : set Kind { RetentionPurge + ErasureRequest + Deployment.declaredKinds }

-- ─────────────────────────────────────────────────────────────────────────────
-- The writing action: its guards and its write
-- ─────────────────────────────────────────────────────────────────────────────

-- recordDestruction: an admitted [Record Destruction]. No tombstone yet for the pair
-- (Operation 4; the database's refusal, Invariant 2.2); destroyed pattern, destroyed id,
-- authority reference and actor reference not blank (Operation 5, 6); a recognized kind
-- (Operation 7); none over its cap (Operation 8, 9); no field of the destroyed record among
-- the inputs (Invariant 3.2). It records exactly one tombstone (Operation 1) carrying the
-- call's five inputs as the call supplied them (Operation 1; Identity 2 to 4) and its
-- destruction instant stamped from the injected now (Operation 2), and nothing else of the
-- destroyed record (State 4). The database accepting the write is what admits the call
-- (Operation 10: a refused write answers storage-failure and leaves nothing).
pred recordDestruction[pre : DB, c : Call, post : DB] {
    no t : pre.tombstones | t.pattern = c.patternIn and t.id = c.idIn   -- Operation 4, Invariant 2.2
    c.patternIn not in blank and c.idIn not in blank                    -- Operation 5
    c.authIn not in blank and c.actorIn not in blank                    -- Operation 6
    c.kindIn in recognized                                              -- Operation 7
    c.patternIn not in Strings.overPatternCap                           -- Operation 8
    no (c.idIn + c.authIn + c.actorIn) & Strings.overReferenceCap       -- Operation 9
    -- BUG: fields of the destroyed record accepted (and dropped)
    some t : Tombstone - pre.tombstones {
        post.tombstones = pre.tombstones + t                            -- Operation 1
        t.pattern   = c.patternIn                                       -- Operation 1
        t.id        = c.idIn                                            -- Operation 1, Identity 2
        t.kind      = c.kindIn                                          -- Operation 1
        t.authRef   = c.authIn                                          -- Operation 1, Identity 3
        t.actorRef  = c.actorIn                                         -- Operation 1, Identity 4
        t.at        = c.now                                             -- Operation 2
        no t.carries                                                    -- State 4
        t.writtenBy = c
    }
}

-- written: the database is empty, or it is what its call wrote over the database that call
-- found, which an earlier call made (a call reads what was committed before it, Execution
-- Contract Database 2), so no call writes twice into one run.
pred written[d : DB] {
    (no d.found and no d.madeBy and no d.tombstones)
    or (some d.found and some d.madeBy
        and (no d.found.madeBy or C/lt[d.found.madeBy, d.madeBy])
        and recordDestruction[d.found, d.madeBy, d])
}

-- recorded: a database the page lets the atom hold (see SCOPE): it and every database it was
-- built from are what admitted calls wrote, back to the empty one.
pred recorded[db : DB] {
    all d : db.*found | written[d]
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Assertions (verified guarantees)
-- Each "check" asks: is there any database the page's calls can leave that violates this
-- assertion? No counterexample (UNSAT) = the guarantee holds within scope.
-- ─────────────────────────────────────────────────────────────────────────────

-- A_State_1: every tombstone carries its destroyed pattern, destroyed id, destruction
-- instant, authority kind, authority reference and actor reference (State 1, Check 1.1).
assert A_State_1 {
    all db : DB | recorded[db] implies all t : db.tombstones |
        some t.pattern and some t.id and some t.at
        and some t.kind and some t.authRef and some t.actorRef
}
check A_State_1 for 4 but 4 DB, 3 Call, 3 Tombstone, 5 Text

-- A_Operation_1: each admitted call left exactly one tombstone, the one it wrote, carrying
-- the destroyed pattern and the authority kind the call supplied (Operation 1). Its other
-- three inputs are A_Identity_2 to 4's.
assert A_Operation_1 {
    all db : DB | recorded[db] implies all d : db.*found | some d.madeBy implies {
        one (d.tombstones - d.found.tombstones)
        all t : d.tombstones - d.found.tombstones |
            t.writtenBy = d.madeBy and t.pattern = d.madeBy.patternIn and t.kind = d.madeBy.kindIn
    }
}
check A_Operation_1 for 4 but 4 DB, 3 Call, 3 Tombstone, 5 Text

-- A_Operation_2: every tombstone's destruction instant is the clock reading the host
-- injected into the call that wrote it, never an instant the caller chose (Operation 2,
-- Clock dependence 2).
assert A_Operation_2 {
    all db : DB | recorded[db] implies all t : db.tombstones | t.at = t.writtenBy.now
}
check A_Operation_2 for 4 but 4 DB, 3 Call, 3 Tombstone, 5 Text

-- A_Invariant_2_1: no two tombstones share a destroyed pattern and a destroyed id: a
-- destroyed record has at most one tombstone, however often its purge is retried
-- (Invariant 2.1, Check 2.1; Identity 1 names a tombstone by the pair).
assert A_Invariant_2_1 {
    all db : DB | recorded[db] implies all disj t1, t2 : db.tombstones |
        not (t1.pattern = t2.pattern and t1.id = t2.id)
}
check A_Invariant_2_1 for 4 but 4 DB, 3 Call, 3 Tombstone, 5 Text

-- A_Invariant_3_1: no tombstone carries a payload of the destroyed record, so it can be
-- kept forever (Invariant 3.1, State 4, Check 3.1).
assert A_Invariant_3_1 {
    all db : DB | recorded[db] implies all t : db.tombstones | no t.carries
}
check A_Invariant_3_1 for 4 but 4 DB, 3 Call, 3 Tombstone, 5 Text

-- A_Invariant_3_2: no tombstone was written by a call that named a field of the destroyed
-- record beside destroyed pattern and destroyed id: the atom accepts no such input
-- (Invariant 3.2).
assert A_Invariant_3_2 {
    all db : DB | recorded[db] implies all t : db.tombstones | no t.writtenBy.contentIn
}
check A_Invariant_3_2 for 4 but 4 DB, 3 Call, 3 Tombstone, 5 Text

-- A_Invariant_4_1: every tombstone's authority kind is retention-purge, erasure-request or a
-- kind the deployment declared (Invariant 4.1, Check 4.1).
assert A_Invariant_4_1 {
    all db : DB | recorded[db] implies all t : db.tombstones | t.kind in recognized
}
check A_Invariant_4_1 for 4 but 4 DB, 3 Call, 3 Tombstone, 5 Text

-- A_Invariant_4_2: every tombstone's authority reference stands non-blank: every
-- destruction names what authorized it (Invariant 4.2, Check 6.1).
assert A_Invariant_4_2 {
    all db : DB | recorded[db] implies all t : db.tombstones | no (t.authRef & blank)
}
check A_Invariant_4_2 for 4 but 4 DB, 3 Call, 3 Tombstone, 5 Text

-- A_Invariant_4_3: every tombstone's actor reference stands non-blank: every destruction
-- names who carried it out (Invariant 4.3, Check 6.1).
assert A_Invariant_4_3 {
    all db : DB | recorded[db] implies all t : db.tombstones | no (t.actorRef & blank)
}
check A_Invariant_4_3 for 4 but 4 DB, 3 Call, 3 Tombstone, 5 Text

-- A_Operation_5: no tombstone carries a blank destroyed pattern or a blank destroyed id
-- (Operation 5, Check 6.1).
assert A_Operation_5 {
    all db : DB | recorded[db] implies all t : db.tombstones |
        no (t.pattern & blank) and no (t.id & blank)
}
check A_Operation_5 for 4 but 4 DB, 3 Call, 3 Tombstone, 5 Text

-- A_Operation_8: no tombstone carries a destroyed pattern longer than the pattern name cap
-- (Operation 8).
assert A_Operation_8 {
    all db : DB | recorded[db] implies all t : db.tombstones |
        no (t.pattern & Strings.overPatternCap)
}
check A_Operation_8 for 4 but 4 DB, 3 Call, 3 Tombstone, 5 Text

-- A_Operation_9: no tombstone carries a destroyed id, an authority reference or an actor
-- reference longer than the reference cap (Operation 9).
assert A_Operation_9 {
    all db : DB | recorded[db] implies all t : db.tombstones |
        no ((t.id + t.authRef + t.actorRef) & Strings.overReferenceCap)
}
check A_Operation_9 for 4 but 4 DB, 3 Call, 3 Tombstone, 5 Text

-- A_Identity_2: every tombstone carries its destroyed id exactly as the call supplied it:
-- the atom never trims, normalizes, case-folds or otherwise interprets it (Identity 2,
-- String 1 to 4).
assert A_Identity_2 {
    all db : DB | recorded[db] implies all t : db.tombstones | t.id = t.writtenBy.idIn
}
check A_Identity_2 for 4 but 4 DB, 3 Call, 3 Tombstone, 5 Text

-- A_Identity_3: every tombstone carries its authority reference exactly as the call
-- supplied it (Identity 3, String 1 to 4).
assert A_Identity_3 {
    all db : DB | recorded[db] implies all t : db.tombstones | t.authRef = t.writtenBy.authIn
}
check A_Identity_3 for 4 but 4 DB, 3 Call, 3 Tombstone, 5 Text

-- A_Identity_4: every tombstone carries its actor reference exactly as the call supplied it
-- (Identity 4, String 1 to 4).
assert A_Identity_4 {
    all db : DB | recorded[db] implies all t : db.tombstones | t.actorRef = t.writtenBy.actorIn
}
check A_Identity_4 for 4 but 4 DB, 3 Call, 3 Tombstone, 5 Text

-- ─────────────────────────────────────────────────────────────────────────────
-- Satisfiability runs — non-vacuity guards, one for each shape the page admits
-- Each run must find at least one instance (SAT).
-- UNSAT means the model forbids a database the page admits.
-- ─────────────────────────────────────────────────────────────────────────────

-- ShowRetentionPurge: a tombstone of a retention purge, as record_destruction("event-log",
-- "inv_8c21", retention-purge, "ret_31f0", "svc_retention_r01") leaves one (Examples, A
-- retention purge).
run ShowRetentionPurge {
    some db : DB, t : db.tombstones | recorded[db] and t.kind = RetentionPurge
} for 4 but 4 DB, 3 Call, 3 Tombstone, 5 Text

-- ShowErasureRequest: a tombstone of an erasure request (Examples, An erasure request).
run ShowErasureRequest {
    some db : DB, t : db.tombstones | recorded[db] and t.kind = ErasureRequest
} for 4 but 4 DB, 3 Call, 3 Tombstone, 5 Text

-- ShowDeploymentKind: a tombstone under a kind the deployment declared, such as a court
-- order (Capability requirement 3).
run ShowDeploymentKind {
    some db : DB, t : db.tombstones | recorded[db] and t.kind in OtherKind
} for 4 but 4 DB, 3 Call, 3 Tombstone, 5 Text

-- ShowOneIdTwoPatterns: one destroyed id in two patterns, two tombstones: a tombstone is
-- named by the pattern and the id together (Identity 1).
run ShowOneIdTwoPatterns {
    some db : DB | recorded[db] and some disj t1, t2 : db.tombstones |
        t1.id = t2.id and t1.pattern != t2.pattern
} for 4 but 4 DB, 3 Call, 3 Tombstone, 5 Text

-- ShowCaseVariants: two tombstones of one pattern whose destroyed ids an interpreting build
-- would merge, such as inv_8c21 and INV_8C21: byte-exact ids are two ids (String 1, 4).
run ShowCaseVariants {
    some db : DB | recorded[db] and some disj t1, t2 : db.tombstones |
        t1.pattern = t2.pattern and t2.id = t1.id.(Normalizer.interp)
} for 4 but 4 DB, 3 Call, 3 Tombstone, 5 Text

-- ShowOneInstant: two tombstones of one pattern destroyed at one instant, as one purge run
-- destroys many records (the listing key then orders them by destroyed id).
run ShowOneInstant {
    some db : DB | recorded[db] and some disj t1, t2 : db.tombstones |
        t1.pattern = t2.pattern and t1.at = t2.at
} for 4 but 4 DB, 3 Call, 3 Tombstone, 5 Text

-- ShowThree: three destructions in one database, of up to three records.
run ShowThree {
    some db : DB | recorded[db] and #db.tombstones = 3
} for 4 but 4 DB, 3 Call, 3 Tombstone, 5 Text
