-- credential-buggy-material-retained.als
-- DELIBERATELY WRONG twin of credential.als (unit: atoms/credential.md formal layer).
--
-- INJECTED DEFECT: [Register] keeps the credential material on the record beside the verifier (Operation 17
-- dropped).
--
-- BREAKS: A_State_9.
-- Everything else is credential.als as written; read its comments there.

module credential_buggy_material_retained

open util/ordering[Instant] as T
open util/ordering[Call] as C

-- ─────────────────────────────────────────────────────────────────────────────
-- Signatures (types)
-- ─────────────────────────────────────────────────────────────────────────────

-- Str: a string a call carries or a record holds — a principal reference, a credential
-- type, a revoked by reference or a reason. The atom compares strings byte-exactly and
-- never interprets them (Identity 7, 8, String 1 to 4), so a string is an uninterpreted
-- token.
sig Str {}

-- Blank: the strings the atom reads as blank, the whitespace-only ones (String 5). Which
-- strings these are is the world's, not the atom's, so it is a subset with no rule on it.
sig Blank in Str {}

-- Id: an opaque credential id (Term credential id), assigned from the id material the
-- seam supplies (Identity 2). It means nothing by itself.
sig Id {}

-- Instant: a moment on the deployment's clock. Only the order of instants matters to the
-- page's rules ("precede"), so instants are ordered atoms.
sig Instant {}

-- Material: credential material a caller supplies to [Register] or [Rotate], or the
-- presented material a caller supplies to [Verify].
sig Material {}

-- Empty: the empty materials, material that carries no character (Term empty material),
-- which [Register] and [Rotate] refuse (Operation 2, 31). Which materials these are is the
-- world's, so it is a subset with no rule on it.
sig Empty in Material {}

-- Verifier: the artifact a derivation function produces from material (Term verifier).
sig Verifier {}

-- Status: the three values a credential stores (Term status); rotated and revoked are the
-- stored terminals (Term stored terminal). Expired is no value here: it is derived, never
-- stored (State 6).
abstract sig Status {}
one sig Active, Rotated, Revoked extends Status {}

-- Answer: what [Verify] answers — verified, or failed-verification naming material-mismatch
-- or no-active-credential (Term verification failure).
abstract sig Answer {}
one sig Verified, MaterialMismatch, NoActiveCredential extends Answer {}

-- Registry: the deployment's derivation registry, supplied at the seam (Capability
-- requirement 3): the credential types it declares, and for each a derivation function
-- (material to verifier, which may draw entropy, so one material may derive several
-- verifiers, Capability requirement 24) and a check function (which material matches
-- which verifier). A material a function refuses has no image (Capability requirement 31,
-- 32). What the functions compute is the deployment's, so they are relations with no rule
-- on them.
one sig Registry {
    declared : set Str,
    derive   : Str -> Material -> Verifier,
    matches  : Str -> Material -> Verifier
}

-- Validity: the deployment's default validity (Term default validity), a duration that
-- exceeds zero or is unbounded. Only which of the two matters here.
abstract sig Validity {}
one sig Bounded, Unbounded extends Validity {}

-- Deployment: the one deployment, and the default validity it declares (Capability
-- requirement 7).
one sig Deployment {
    validity : one Validity
}

-- Call: one call of an action, as it reaches the seam. Calls happen in one order, the
-- order Execution Contract Order 1 gives every commit; `now` is the clock reading the host
-- injects for the call (Term now, Capability requirement 1). The page lets a call read a
-- clock earlier than a registration already committed (Term settled reading), so no rule
-- ties the two orders.
abstract sig Call {
    now : one Instant
}

-- RecordingCall: a call that records a new credential, [Register] or [Rotate], with the
-- id material the seam supplies for it (Capability requirement 2), the material it
-- derives from, the optional expiry instant, and the default expiry the deployment's
-- default validity gives it (Term default expiry; absent where the validity is unbounded).
abstract sig RecordingCall extends Call {
    idMaterial    : one Id,
    materialIn    : lone Material,  -- credential_material, or new_credential_material on [Rotate]
    expiresIn     : lone Instant,   -- optional expires_at
    defaultExpiry : lone Instant    -- now + default validity (Execution Contract Logic confinement 9)
}

-- RegisterCall: one [Register] call, register(principal_ref, credential_material,
-- credential_type, optional expires_at).
sig RegisterCall extends RecordingCall {
    principalIn : lone Str,         -- principal_ref
    typeIn      : lone Str          -- credential_type
}

-- RotateCall: one [Rotate] call, rotate(credential_id, new_credential_material, optional
-- expires_at). The credential it names is the version it finds (see `written`).
sig RotateCall extends RecordingCall {
    rotateTarget : one Id           -- credential_id
}

-- RevokeCall: one [Revoke] call, revoke(credential_id, revoked_by_ref, reason).
sig RevokeCall extends Call {
    revokeTarget : one Id,          -- credential_id
    revokedByIn  : lone Str,        -- revoked_by_ref
    reasonIn     : lone Str         -- reason
}

-- VerifyCall: one [Verify] call, verify(principal_ref, credential_type,
-- presented_material), with the credential records it reads (`db`). The last two fields
-- are what it decides: the credential it checks against, and its answer.
sig VerifyCall extends Call {
    askedPrincipal : lone Str,          -- principal_ref
    askedType      : lone Str,          -- credential_type
    presentedIn    : lone Material,     -- presented_material
    db             : set Credential,    -- the credential records the call reads
    against        : lone Credential,   -- the credential a proceeding verify checks against
    answer         : lone Answer        -- what the call answers
}

-- Credential: one version of a credential record (Term records), as the call that wrote it
-- left it. Every field the page names is here and every one may be absent, so a write that
-- forgot one would show; the status is a set of status flags, so a write that added one
-- would show too. `material` is the credential material the record keeps beyond its
-- verifier, which State 9 forbids: present so that a write keeping it would show. The last
-- three fields are the model's own: which call wrote this version, which version of the
-- same credential that call found, and, for a successor, the version of the prior its
-- rotate found.
sig Credential {
    credId           : lone Id,         -- credential id (Identity 1)
    principal        : lone Str,        -- principal reference
    ctype            : lone Str,        -- credential type
    verifier         : lone Verifier,   -- verifier
    registeredAt     : lone Instant,    -- registration instant
    expiresAt        : lone Instant,    -- expiry instant (State 2); absent means no deadline
    status           : set Status,      -- status (State 1)
    rotatedAt        : lone Instant,    -- rotation instant (State 3)
    successorId      : lone Id,         -- successor credential id (State 3)
    revokedAt        : lone Instant,    -- revocation instant (Invariant 9.3)
    revokedBy        : lone Str,        -- revoked by reference (Invariant 9.1)
    revocationReason : lone Str,        -- revocation reason (Invariant 9.2)
    material         : set Material,    -- credential material kept beyond the verifier (State 9)
    writtenBy        : one Call,        -- the call whose write left this version
    found            : lone Credential, -- the version of this credential that call found
    rotatedFrom      : lone Credential  -- for a successor: the version of the prior its rotate found
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Facts: what the page takes from outside
-- ─────────────────────────────────────────────────────────────────────────────

-- The deployment supplies id material naming no credential of the database instance and
-- never the same id material to two calls (Capability requirement 34, 35), and the atom
-- assigns the credential id from it (Identity 2). This is where Identity 5 comes from.
fact DeploymentSuppliesFreshIdMaterial {
    all disj a, b : RecordingCall | a.idMaterial != b.idMaterial
}

-- The default validity exceeds zero or is unbounded (Term default validity), declared once
-- for the deployment (Capability requirement 7): a bounded one gives every recording call
-- a default expiry after its now (Term default expiry), an unbounded one gives none.
fact DeploymentDeclaresTheDefaultValidity {
    Deployment.validity = Unbounded implies no RecordingCall.defaultExpiry
    Deployment.validity = Bounded implies
        all c : RecordingCall | one c.defaultExpiry and T/lt[c.now, c.defaultExpiry]
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Helpers
-- ─────────────────────────────────────────────────────────────────────────────

-- nonBlank: a string is present and not whitespace-only. An absent input reads as blank
-- (String 6), and so does an absent field.
pred nonBlank[x : lone Str] {
    some x and x not in Blank
}

-- hasMaterial: material is supplied and is not empty material (Operation 2, 31).
pred hasMaterial[m : lone Material] {
    some m and m not in Empty
}

-- derived: the verifiers the type's derivation function may derive from the material;
-- none where it refuses the material or the type names no derivation function.
fun derived[t : lone Str, m : lone Material] : set Verifier {
    m.(t.(Registry.derive))
}

-- matched: the type's check function answers a match for the material against the
-- verifier (Term check function).
pred matched[t : lone Str, m : lone Material, v : lone Verifier] {
    some m and some v and v in m.(t.(Registry.matches))
}

-- live: the credential's window reads live at the reading — no expiry instant, or the
-- reading precedes it (Term live). The boundary instant reads lapsed (Term lapsed).
pred live[x : Credential, r : Instant] {
    no x.expiresAt or T/lt[r, x.expiresAt]
}

-- effectiveActive: the credential stores active and reads live at the reading (Term
-- effective-active credential).
pred effectiveActive[x : Credential, r : Instant] {
    x.status = Active
    live[x, r]
}

-- expiryAdmitted: a supplied expiry instant follows now (Operation 5, 63).
pred expiryAdmitted[c : RecordingCall] {
    some c.expiresIn implies T/lt[c.now, c.expiresIn]
}

-- recordsExpiry: the expiry instant a recording call writes — the supplied one, else the
-- default expiry, which is absent where the default validity is unbounded (Operation 12,
-- 13, 71 on [Register]; 61, 62, 72 on [Rotate]'s successor).
pred recordsExpiry[c : RecordingCall, x : Credential] {
    some c.expiresIn implies x.expiresAt = c.expiresIn
    no c.expiresIn implies x.expiresAt = c.defaultExpiry
}

-- noTerminalField: the credential carries no terminal field (Term terminal field).
pred noTerminalField[x : Credential] {
    no x.rotatedAt
    no x.successorId
    no x.revokedAt
    no x.revokedBy
    no x.revocationReason
}

-- keepsProperties: the write leaves the credential id, every property (Term property)
-- and whatever material the record held as it found them: a call writes only the fields
-- its own rules name.
pred keepsProperties[pre, post : Credential] {
    post.credId       = pre.credId
    post.principal    = pre.principal
    post.ctype        = pre.ctype
    post.verifier     = pre.verifier
    post.registeredAt = pre.registeredAt
    post.expiresAt    = pre.expiresAt
    post.material     = pre.material
}

-- origin: the call that recorded the credential this version belongs to — the writer of
-- the first version along the chain of versions found.
fun origin[x : Credential] : set Call {
    { v : x.*found | no v.found }.writtenBy
}

-- ─────────────────────────────────────────────────────────────────────────────
-- The writing actions: their guards and their writes
-- ─────────────────────────────────────────────────────────────────────────────

-- registerWrites: the credential an admitted [Register] records.
pred registerWrites[c : RegisterCall, x : Credential] {
    nonBlank[c.principalIn]                         -- Operation 1
    hasMaterial[c.materialIn]                       -- Operation 2
    nonBlank[c.typeIn]                              -- Operation 3
    c.typeIn in Registry.declared                   -- Operation 4, Identity 11
    expiryAdmitted[c]                               -- Operation 5
    some derived[c.typeIn, c.materialIn]            -- Operation 66
    x.credId       = c.idMaterial                   -- Operation 9, Identity 2
    x.principal    = c.principalIn                  -- Operation 10
    x.ctype        = c.typeIn                       -- Operation 10
    one x.verifier
    x.verifier in derived[c.typeIn, c.materialIn]   -- Operation 11
    recordsExpiry[c, x]                             -- Operation 12, 13, 71
    x.registeredAt = c.now                          -- Operation 14
    x.status       = Active                         -- Operation 15
    noTerminalField[x]
    x.material = c.materialIn                       -- BUG: Operation 17 dropped, the material kept
}

-- rotateAdmitted: the guards of [Rotate] admit the call against the version it found.
pred rotateAdmitted[pre : Credential, c : RotateCall] {
    pre.credId = c.rotateTarget                     -- Operation 27
    effectiveActive[pre, c.now]                     -- Operation 28
    hasMaterial[c.materialIn]                       -- Operation 31
    expiryAdmitted[c]                               -- Operation 63
    some derived[pre.ctype, c.materialIn]           -- Operation 67
}

-- priorRotated: the version of the prior an admitted [Rotate] leaves.
pred priorRotated[pre : Credential, c : RotateCall, p : Credential] {
    keepsProperties[pre, p]                         -- Invariant 6.1, 6.2 (written so; checked across steps by TLA+)
    p.status      = Rotated                         -- Operation 37
    p.rotatedAt   = c.now                           -- Operation 38
    p.successorId = c.idMaterial                    -- Operation 39, 58
    p.revokedAt        = pre.revokedAt
    p.revokedBy        = pre.revokedBy
    p.revocationReason = pre.revocationReason
}

-- successorRecorded: the successor an admitted [Rotate] records for the prior's pair.
pred successorRecorded[pre : Credential, c : RotateCall, s : Credential] {
    s.credId       = c.idMaterial                   -- Operation 58, Identity 2
    s.principal    = pre.principal                  -- Operation 35
    s.ctype        = pre.ctype                      -- Operation 35
    one s.verifier
    s.verifier in derived[pre.ctype, c.materialIn]  -- Operation 59
    s.registeredAt = c.now                          -- Operation 60
    recordsExpiry[c, s]                             -- Operation 61, 62, 72
    s.status       = Active                         -- Operation 36
    noTerminalField[s]
    no s.material                                   -- Operation 64
}

-- rotateWrites: the prior's version an admitted [Rotate] leaves, beside the successor the
-- same call records (Operation 35: both, or neither).
pred rotateWrites[pre : Credential, c : RotateCall, p : Credential] {
    rotateAdmitted[pre, c]
    priorRotated[pre, c, p]
    some s : Credential | s.writtenBy = c and s.rotatedFrom = pre and no s.found
        and successorRecorded[pre, c, s]            -- Operation 35
}

-- successorWrites: the successor an admitted [Rotate] records, beside the prior's rotated
-- version the same call leaves (Operation 37).
pred successorWrites[pre : Credential, c : RotateCall, s : Credential] {
    rotateAdmitted[pre, c]
    successorRecorded[pre, c, s]
    some p : Credential | p.writtenBy = c and p.found = pre and no p.rotatedFrom
        and priorRotated[pre, c, p]                 -- Operation 37
}

-- revokeWrites: the version an admitted [Revoke] leaves of the active one it found.
pred revokeWrites[pre : Credential, c : RevokeCall, p : Credential] {
    pre.credId = c.revokeTarget                     -- Operation 27
    effectiveActive[pre, c.now]                     -- Operation 29
    nonBlank[c.revokedByIn]                         -- Operation 32
    nonBlank[c.reasonIn]                            -- Operation 33
    keepsProperties[pre, p]                         -- Invariant 1.1 (written so; checked across steps by TLA+)
    p.status           = Revoked                    -- Operation 42
    p.revokedBy        = c.revokedByIn              -- Operation 43
    p.revocationReason = c.reasonIn                 -- Operation 43
    p.revokedAt        = c.now                      -- Operation 43
    p.rotatedAt   = pre.rotatedAt
    p.successorId = pre.successorId
}

-- written: the version is what its call's write left, over a version an earlier call
-- wrote (a call finds only what was committed before it, Execution Contract Database 2).
pred written[v : Credential] {
    let c = v.writtenBy {
        (c in RegisterCall and no v.found and no v.rotatedFrom
            and registerWrites[c, v])
        or (c in RotateCall and some v.found and no v.rotatedFrom
            and C/lt[v.found.writtenBy, c] and rotateWrites[v.found, c, v])
        or (c in RotateCall and no v.found and some v.rotatedFrom
            and C/lt[v.rotatedFrom.writtenBy, c] and successorWrites[v.rotatedFrom, c, v])
        or (c in RevokeCall and some v.found and no v.rotatedFrom
            and C/lt[v.found.writtenBy, c] and revokeWrites[v.found, c, v])
    }
}

-- recorded: a version the page lets the records hold (see SCOPE): it and every version it
-- was built from are what an admitted call wrote.
pred recorded[x : Credential] {
    all v : x.*(found + rotatedFrom) | written[v]
}

-- ─────────────────────────────────────────────────────────────────────────────
-- [Verify]: what it reads and what it answers
-- ─────────────────────────────────────────────────────────────────────────────

-- aDatabase: what the verify reads is a state of the records — recorded credentials, each
-- written before the call, one version per credential.
pred aDatabase[v : VerifyCall] {
    all x : v.db | recorded[x] and C/lt[x.writtenBy, v]
    all disj x, y : v.db | origin[x] != origin[y]
}

-- verifyAnswers: the answer [Verify] gives from what it read. The candidates are the
-- pair's credentials standing active that read live at the call's reading. None: it
-- answers no-active-credential, whatever the reason (Operation 18, 19). Otherwise it
-- checks against the candidate with the latest registration instant (Operation 70), per
-- the type's check function (Operation 21), and answers verified on a match (Operation
-- 23), material-mismatch on no match or a refusal (Operation 22, 68).
pred verifyAnswers[v : VerifyCall] {
    let cand = { x : v.db | x.principal = v.askedPrincipal and x.ctype = v.askedType
                            and x.status = Active and live[x, v.now] } {
        no cand implies (v.answer = NoActiveCredential and no v.against)
        some cand implies {
            one v.against
            v.against in cand
            no y : cand | T/lt[v.against.registeredAt, y.registeredAt]
            matched[v.askedType, v.presentedIn, v.against.verifier] implies v.answer = Verified
            not matched[v.askedType, v.presentedIn, v.against.verifier] implies v.answer = MaterialMismatch
        }
    }
}

-- checkedAgainst: the credential a proceeding verify checks against, in the page's own
-- words: of the pair's credentials effective-active at the verify's reading, the one
-- carrying the latest registration instant (Operation 70, Term proceeding verify).
fun checkedAgainst[v : VerifyCall] : set Credential {
    let ea = { x : v.db | x.principal = v.askedPrincipal and x.ctype = v.askedType
                          and effectiveActive[x, v.now] } |
        { x : ea | no y : ea | T/lt[x.registeredAt, y.registeredAt] }
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Assertions (verified guarantees)
-- Each "check" asks: is there any record the page's calls can leave (or any answer a
-- verify can give over such records) that violates this assertion? No counterexample
-- (UNSAT) = the guarantee holds within scope.
-- ─────────────────────────────────────────────────────────────────────────────

-- A_State_3: a rotated credential carries the instant it was replaced and the link to the
-- credential that replaced it, the two fields an auditor walks the chain by.
assert A_State_3 {
    all x : Credential | (recorded[x] and Rotated in x.status)
        implies (some x.rotatedAt and some x.successorId)
}
check A_State_3 for 4 but 5 Credential

-- A_State_5: an active credential carries no terminal field: no rotation instant, no
-- successor link, no revocation instant, revoked by reference or reason.
assert A_State_5 {
    all x : Credential | (recorded[x] and x.status = Active) implies noTerminalField[x]
}
check A_State_5 for 4 but 5 Credential

-- A_State_9: no credential keeps the credential material it was derived from: the
-- verifier stands in its place, and the material is discarded.
assert A_State_9 {
    all x : Credential | recorded[x] implies no x.material
}
check A_State_9 for 4 but 5 Credential

-- A_Identity_5: two credentials never share a credential id. Versions recorded by
-- different calls are different credentials (a successor is a new credential, never the
-- prior under a new status).
assert A_Identity_5 {
    all x1, x2 : Credential | (recorded[x1] and recorded[x2] and origin[x1] != origin[x2])
        implies x1.credId != x2.credId
}
check A_Identity_5 for 4 but 5 Credential

-- A_Invariant_3_1: a verify answers verified only if the presented material matches, per
-- the check function, the verifier of the credential it must check against: the pair's
-- latest-registered credential that is effective-active at its reading. So a revoked or
-- rotated credential (the deleted Invariant 4.1), a lapsed one (the deleted Invariant
-- 11.1) and an older one beside a newer live one never let material through.
assert A_Invariant_3_1 {
    all v : VerifyCall | (aDatabase[v] and verifyAnswers[v] and v.answer = Verified) implies
        some x : checkedAgainst[v] | matched[x.ctype, v.presentedIn, x.verifier]
}
check A_Invariant_3_1 for 4 but 5 Credential

-- A_Invariant_5_1: a stored terminal is absorbing, read off one record. A write that took
-- a rotated credential to revoked, or a revoked one to rotated, would leave the fields of
-- the terminal it found beside the new one's (a write changes no terminal field it found,
-- Invariant 1.2). The term entries say rotation instant and successor credential id are
-- present only in rotated, and revocation instant only in revoked, so no credential
-- standing in one stored terminal carries the other's.
assert A_Invariant_5_1 {
    all x : Credential | recorded[x] implies {
        Rotated in x.status implies no x.revokedAt
        Revoked in x.status implies (no x.rotatedAt and no x.successorId)
    }
}
check A_Invariant_5_1 for 4 but 5 Credential

-- A_Invariant_7_1: every rotated credential's successor credential id names a credential,
-- so the chain of replacements is walkable and no link dangles.
assert A_Invariant_7_1 {
    all x : Credential | (recorded[x] and Rotated in x.status) implies
        some s : Credential | recorded[s] and s.credId = x.successorId
}
check A_Invariant_7_1 for 4 but 5 Credential

-- A_Invariant_7_2: every rotated credential's successor carries the rotated credential's
-- pair, so no link leaves the principal and credential type it started from.
assert A_Invariant_7_2 {
    all x, s : Credential | (recorded[x] and recorded[s] and Rotated in x.status
                             and s.credId = x.successorId)
        implies (s.principal = x.principal and s.ctype = x.ctype)
}
check A_Invariant_7_2 for 4 but 5 Credential

-- A_Invariant_9_1: every revoked credential names, non-blank, whom the caller said revoked it.
assert A_Invariant_9_1 {
    all x : Credential | (recorded[x] and Revoked in x.status) implies nonBlank[x.revokedBy]
}
check A_Invariant_9_1 for 4 but 5 Credential

-- A_Invariant_9_2: every revoked credential says, non-blank, why it was revoked.
assert A_Invariant_9_2 {
    all x : Credential | (recorded[x] and Revoked in x.status) implies nonBlank[x.revocationReason]
}
check A_Invariant_9_2 for 4 but 5 Credential

-- A_Invariant_9_3: every revoked credential says when it was revoked.
assert A_Invariant_9_3 {
    all x : Credential | (recorded[x] and Revoked in x.status) implies some x.revokedAt
}
check A_Invariant_9_3 for 4 but 5 Credential

-- ─────────────────────────────────────────────────────────────────────────────
-- Satisfiability runs — non-vacuity guards, one for each shape the page admits
-- Each run must find at least one instance (SAT).
-- UNSAT means the model forbids a record the page admits.
-- ─────────────────────────────────────────────────────────────────────────────

-- ShowRegisteredWithDeadline: a credential just registered, active, with an expiry
-- instant (the programming-interface token cred_c07).
run ShowRegisteredWithDeadline {
    some x : Credential | recorded[x] and x.writtenBy in RegisterCall and some x.expiresAt
} for 4 but 5 Credential

-- ShowNoDeadline: an active credential with no expiry instant, on a deployment declaring
-- the default validity unbounded (the password cred_c01, Operation 71).
run ShowNoDeadline {
    some x : Credential | recorded[x] and x.status = Active and no x.expiresAt
} for 4 but 5 Credential

-- ShowRotated: a rotated credential and the active successor its link names (cred_c07
-- rotated to cred_c11).
run ShowRotated {
    some x, s : Credential | recorded[x] and recorded[s] and x.status = Rotated
        and s.credId = x.successorId and s.status = Active
} for 4 but 5 Credential

-- ShowChain: two links of a rotation chain: a rotated credential whose successor was
-- rotated in turn (the quarterly rotation, two quarters on).
run ShowChain {
    some x, s : Credential | recorded[x] and recorded[s] and x.status = Rotated
        and s.credId = x.successorId and s.status = Rotated
} for 4 but 5 Credential

-- ShowRotatedToTheSameMaterial: a rotate to the material the prior was registered from is
-- admitted (Non-goal 37).
run ShowRotatedToTheSameMaterial {
    some x : Credential | recorded[x] and x.status = Rotated and origin[x] in RegisterCall
        and x.writtenBy.materialIn = origin[x].materialIn
} for 4 but 5 Credential

-- ShowRevoked: a revoked credential with its revocation record (cred_c15 after the log
-- exposure).
run ShowRevoked {
    some x : Credential | recorded[x] and x.status = Revoked
} for 4 but 5 Credential

-- ShowSuccessorRevoked: a successor a rotate recorded, later revoked.
run ShowSuccessorRevoked {
    some x : Credential | recorded[x] and x.status = Revoked and origin[x] in RotateCall
} for 4 but 5 Credential

-- ShowVerified: a verify answers verified (correct horse battery staple).
run ShowVerified {
    some v : VerifyCall | aDatabase[v] and verifyAnswers[v] and v.answer = Verified
} for 4 but 5 Credential

-- ShowMismatch: a verify against an effective-active credential answers material-mismatch
-- (hunter2).
run ShowMismatch {
    some v : VerifyCall | aDatabase[v] and verifyAnswers[v] and v.answer = MaterialMismatch
} for 4 but 5 Credential

-- ShowNoActiveAtTheBoundary: the pair's one credential stands active with its expiry
-- instant equal to the verify's reading: it reads lapsed, and the verify answers
-- no-active-credential (the deadline passes, at 2026-07-01 exactly).
run ShowNoActiveAtTheBoundary {
    some v : VerifyCall, x : v.db | aDatabase[v] and verifyAnswers[v]
        and x.principal = v.askedPrincipal and x.ctype = v.askedType
        and x.status = Active and x.expiresAt = v.now and v.answer = NoActiveCredential
} for 4 but 5 Credential

-- ShowVerifiedBesideALapsedOne: two credentials stand active for the pair, one lapsed and
-- one live, and the verify answers verified against the live one (cred_c11 and cred_c15).
run ShowVerifiedBesideALapsedOne {
    some v : VerifyCall, x : v.db | aDatabase[v] and verifyAnswers[v]
        and x.principal = v.askedPrincipal and x.ctype = v.askedType
        and x.status = Active and not live[x, v.now]
        and v.answer = Verified
} for 4 but 5 Credential

-- ShowNoActiveOverRevoked: the pair's only credential is revoked, and the verify answers
-- no-active-credential, not saying why.
run ShowNoActiveOverRevoked {
    some v : VerifyCall | aDatabase[v] and verifyAnswers[v] and v.answer = NoActiveCredential
        and some x : v.db | x.principal = v.askedPrincipal and x.ctype = v.askedType
                            and x.status = Revoked
} for 4 but 5 Credential
