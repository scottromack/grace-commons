-- invitation-buggy-blank-identity.als
-- DELIBERATELY WRONG twin of invitation.als (unit: atoms/invitation.md formal layer).
--
-- INJECTED DEFECT: [Accept] admits a blank accepting identity reference (Operation 23 dropped).
--
-- BREAKS: A_Invariant_3_1.
-- Everything else is invitation.als as written; read its comments there.

module invitation_buggy_blank_identity

open util/ordering[Instant] as T
open util/ordering[Call] as C

-- ─────────────────────────────────────────────────────────────────────────────
-- Signatures (types)
-- ─────────────────────────────────────────────────────────────────────────────

-- Str: a string a call carries or a record holds — an inviter, invitee, accepting
-- identity or revoked by reference, a context or a reason (Term string input). The atom
-- compares strings byte-exactly and never interprets them (Identity 8, 9, String 1 to 4),
-- so a string is an uninterpreted token.
sig Str {}

-- Blank: the strings the atom reads as blank, the whitespace-only ones (String 5). Which
-- strings these are is the world's, not the atom's, so it is a subset with no rule on it.
sig Blank in Str {}

-- Token: an invitation token (Term invitation token), assigned from the token material
-- the seam supplies (Identity 2). `fold` is the token as a normalizer would spell it (one
-- case, trimmed): the world's, which the atom never applies (Identity 9, String 3, 4);
-- present so that a lookup that normalized would show.
sig Token {
    fold : one Token
}

-- Instant: a moment on the deployment's clock. Only the order of instants matters to the
-- page's rules ("precede"), so instants are ordered atoms.
sig Instant {}

-- Ttl: a window length (Term window length), a ttl an [Initiate] supplies or the default
-- ttl the deployment declares.
sig Ttl {}

-- Standing: the effective status a read answers (Term value sets): the stored status, or
-- expired, which is derived and never stored (State 7). It is also what an
-- already-resolved answer could name, so a payload naming expired would show.
abstract sig Standing {}
one sig Expired extends Standing {}

-- Status: the four values an invitation stores (Term status).
abstract sig Status extends Standing {}
one sig Pending extends Status {}

-- Terminal: the stored terminals (Term stored terminal).
abstract sig Terminal extends Status {}
one sig Accepted, Declined, Revoked extends Terminal {}

-- Answer: what a resolving write answers — a refusal (not-known, already-resolved,
-- expired, invalid-request) or the resolution it was called for (accepted, declined or
-- revoked: `Resolved`).
abstract sig Answer {}
one sig NotKnown, AlreadyResolved, ExpiredRefusal, InvalidRequest, Resolved extends Answer {}

-- Field: the resolution fields (Term resolution field), by name, so a record's resolution
-- field pattern (Invariant 5.1) is a set of them.
abstract sig Field {}
one sig AcceptingIdentityRef, AcceptanceInstant, DeclinationInstant,
        RevocationInstant, RevokedByRef, RevocationReason extends Field {}

-- Deployment: the one deployment: the ttl bounds and the default ttl it declares
-- (Capability requirement 4, 5), and the host's arithmetic giving the expiry bound of an
-- instant and a ttl (Term expiry bound, Execution Contract Logic confinement 9). The
-- default may be undeclared: Operation 5 is the page's own answer to that, so the model
-- does not assume Capability requirement 4.
one sig Deployment {
    bounds     : set Ttl,
    defaultTtl : lone Ttl,
    plus       : Instant -> Ttl -> one Instant
}

-- Call: one call of an action, as it reaches the seam. Calls happen in one order, the
-- order Execution Contract Order 1 gives every commit; `now` is the clock reading the host
-- injects for the call (Term now, Capability requirement 1). No rule ties the two orders.
abstract sig Call {
    now : one Instant
}

-- InitiateCall: one [Initiate] call, initiate(inviter_ref, optional invitee_ref, context,
-- optional ttl), with the token material the seam supplies for it (Capability
-- requirement 2).
sig InitiateCall extends Call {
    tokenIn   : one Token,      -- the token material
    inviterIn : lone Str,       -- inviter_ref
    inviteeIn : lone Str,       -- optional invitee_ref
    contextIn : lone Str,       -- context
    ttlIn     : lone Ttl        -- optional ttl
}

-- ResolveCall: one resolving write (Term resolving write), with the token it presents and
-- the invitation records it reads (`db`). The last three fields are what it decides: the
-- records its token names there, its answer, and the standing an already-resolved answer
-- names.
abstract sig ResolveCall extends Call {
    presented : one Token,          -- invitation_token
    db        : set Invitation,     -- the invitation records the call reads
    seen      : set Invitation,     -- the records the presented token names
    answer    : one Answer,         -- what the call answers
    named     : lone Standing       -- the standing an already-resolved answer names
}

-- AcceptCall: one [Accept] call, accept(invitation_token, accepting_identity_ref).
sig AcceptCall extends ResolveCall {
    identityIn : lone Str           -- accepting_identity_ref
}

-- DeclineCall: one [Decline] call, decline(invitation_token); it takes no acting
-- reference (Operation 27).
sig DeclineCall extends ResolveCall {}

-- RevokeCall: one [Revoke] call, revoke(invitation_token, revoked_by_ref, reason).
sig RevokeCall extends ResolveCall {
    revokedByIn : lone Str,         -- revoked_by_ref
    reasonIn    : lone Str          -- reason
}

-- Invitation: one version of an invitation record (Term records), as the call that wrote
-- it left it. Every field the page names is here and every one may be absent, so a write
-- that forgot one would show. The last two fields are the model's own: which call wrote
-- this version, and which version of the same invitation that call found.
sig Invitation {
    token            : lone Token,      -- invitation token (Identity 1)
    inviter          : lone Str,        -- inviter reference
    invitee          : lone Str,        -- invitee reference (State 2: optional)
    context          : lone Str,        -- context
    initiatedAt      : lone Instant,    -- initiation instant
    expiresAt        : lone Instant,    -- expiry instant (Invariant 9.1)
    status           : one Status,      -- status (State 1)
    acceptedBy       : lone Str,        -- accepting identity reference (State 3)
    acceptedAt       : lone Instant,    -- acceptance instant (State 3)
    declinedAt       : lone Instant,    -- declination instant (State 4)
    revokedBy        : lone Str,        -- revoked by reference (State 5)
    revocationReason : lone Str,        -- revocation reason (State 5)
    revokedAt        : lone Instant,    -- revocation instant (State 5)
    writtenBy        : one Call,        -- the call whose write left this version
    found            : lone Invitation  -- the version of this invitation that call found
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Facts: what the page takes from outside
-- ─────────────────────────────────────────────────────────────────────────────

-- The database refuses a write carrying an invitation token it holds (Capability
-- requirement 6): no [Initiate] commits a token that a version committed before it
-- carries. (Identity 6 is the atom's answer to that refusal, storage-failure, which
-- commits nothing.)
fact DatabaseRefusesAHeldToken {
    all x, y : Invitation | (x.writtenBy in InitiateCall and C/lt[y.writtenBy, x.writtenBy])
        implies y.token != x.token
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Helpers
-- ─────────────────────────────────────────────────────────────────────────────

-- nonBlank: a string is present and not whitespace-only. An absent input reads as blank
-- (String 6), and so does an absent field.
pred nonBlank[x : lone Str] {
    some x and x not in Blank
}

-- effectiveTtl: the ttl an [Initiate] sizes the window by: the one it supplies, else the
-- default ttl (Operation 4); none where neither is there.
fun effectiveTtl[c : InitiateCall] : lone Ttl {
    some c.ttlIn implies c.ttlIn else Deployment.defaultTtl
}

-- live: the invitation's window reads live at the reading: now precedes its expiry
-- instant (Term live). The boundary instant, and an invitation with no expiry instant,
-- read lapsed (Term lapsed).
pred live[x : Invitation, r : Instant] {
    some x.expiresAt and T/lt[r, x.expiresAt]
}

-- lapsed: a pending invitation whose window does not read live at the reading (Term
-- lapsed): the one an effective status answers as expired.
pred lapsed[x : Invitation, r : Instant] {
    x.status = Pending
    not live[x, r]
}

-- noResolutionField: the invitation carries no resolution field (Term resolution field).
pred noResolutionField[x : Invitation] {
    no x.acceptedBy
    no x.acceptedAt
    no x.declinedAt
    no x.revokedBy
    no x.revocationReason
    no x.revokedAt
}

-- pattern: the resolution fields the invitation carries (Invariant 5.1's resolution field
-- pattern).
fun pattern[x : Invitation] : set Field {
      (some x.acceptedBy       implies AcceptingIdentityRef else none)
    + (some x.acceptedAt       implies AcceptanceInstant    else none)
    + (some x.declinedAt       implies DeclinationInstant   else none)
    + (some x.revokedAt        implies RevocationInstant    else none)
    + (some x.revokedBy        implies RevokedByRef         else none)
    + (some x.revocationReason implies RevocationReason     else none)
}

-- keepsProperties: the write leaves the invitation token and every property (Term
-- property) as it found them: a resolving write writes only the fields its own rules name.
pred keepsProperties[pre, post : Invitation] {
    post.token       = pre.token
    post.inviter     = pre.inviter
    post.invitee     = pre.invitee
    post.context     = pre.context
    post.initiatedAt = pre.initiatedAt
    post.expiresAt   = pre.expiresAt
}

-- origin: the [Initiate] that recorded the invitation this version belongs to — the writer
-- of the first version along the chain of versions found.
fun origin[x : Invitation] : set Call {
    { v : x.*found | no v.found }.writtenBy
}

-- ─────────────────────────────────────────────────────────────────────────────
-- The actions: their guards, their answers and their writes
-- ─────────────────────────────────────────────────────────────────────────────

-- initiateWrites: the invitation an admitted [Initiate] records.
pred initiateWrites[c : InitiateCall, x : Invitation] {
    nonBlank[c.inviterIn]                           -- Operation 1
    nonBlank[c.contextIn]                           -- Operation 2
    some c.ttlIn implies c.ttlIn in Deployment.bounds   -- Operation 3
    some Deployment.defaultTtl                      -- Operation 5
    x.token       = c.tokenIn                       -- Operation 8, Identity 2
    x.inviter     = c.inviterIn                     -- Operation 9
    x.context     = c.contextIn                     -- Operation 9
    nonBlank[c.inviteeIn] implies x.invitee = c.inviteeIn   -- Operation 10
    x.invitee in c.inviteeIn                        -- State 2 (a blank one: no rule says)
    x.initiatedAt = c.now                           -- Operation 11
    x.expiresAt   = effectiveTtl[c].(c.now.(Deployment.plus))   -- Operation 12, 4
    x.status      = Pending                         -- Operation 13
    noResolutionField[x]
}

-- looksUp: the records the presented token names in what the call read, the token
-- compared byte-exactly and never normalized (Identity 1, 8, 9).
pred looksUp[c : ResolveCall] {
    c.seen = { x : c.db | x.token = c.presented }
}

-- inputsOk: the call's own inputs are non-blank where the page requires them.
pred inputsOk[c : ResolveCall] {
    -- BUG: Operation 23 dropped
    c in RevokeCall implies nonBlank[c.revokedByIn] -- Operation 24
    c in RevokeCall implies nonBlank[c.reasonIn]    -- Operation 25
}

-- answers: what a resolving write answers from what it read, the status checks first and
-- the call's inputs after them (Term status check, Execution Contract Refusal 1). A token
-- naming no record: not-known. A record in a stored terminal: already-resolved, naming
-- the status. A pending one reading lapsed: expired. Then a blank required input:
-- invalid-request. Otherwise the call resolves the invitation.
pred answers[c : ResolveCall] {
    looksUp[c]
    no c.seen implies (c.answer = NotKnown and no c.named)                          -- Operation 15
    all x : c.seen | {
        x.status in Terminal implies (c.answer = AlreadyResolved and c.named = x.status)   -- Operation 16, 17
        lapsed[x, c.now] implies (c.answer = ExpiredRefusal and no c.named)         -- Operation 20
        (x.status = Pending and live[x, c.now] and not inputsOk[c])
            implies (c.answer = InvalidRequest and no c.named)                      -- Operation 23 to 25
        (x.status = Pending and live[x, c.now] and inputsOk[c])
            implies (c.answer = Resolved and no c.named)
    }
}

-- acceptWrites: the version an admitted [Accept] leaves of the invitation it found.
pred acceptWrites[pre : Invitation, c : AcceptCall, v : Invitation] {
    v.status           = Accepted                   -- Operation 28
    v.acceptedBy       = c.identityIn               -- Operation 29
    v.acceptedAt       = c.now                      -- Operation 29
    v.declinedAt       = pre.declinedAt
    v.revokedBy        = pre.revokedBy
    v.revocationReason = pre.revocationReason
    v.revokedAt        = pre.revokedAt
}

-- declineWrites: the version an admitted [Decline] leaves of the invitation it found.
pred declineWrites[pre : Invitation, c : DeclineCall, v : Invitation] {
    v.status           = Declined                   -- Operation 30
    v.declinedAt       = c.now                      -- Operation 31
    v.acceptedBy       = pre.acceptedBy
    v.acceptedAt       = pre.acceptedAt
    v.revokedBy        = pre.revokedBy
    v.revocationReason = pre.revocationReason
    v.revokedAt        = pre.revokedAt
}

-- revokeWrites: the version an admitted [Revoke] leaves of the invitation it found.
pred revokeWrites[pre : Invitation, c : RevokeCall, v : Invitation] {
    v.status           = Revoked                    -- Operation 32
    v.revokedBy        = c.revokedByIn              -- Operation 33
    v.revocationReason = c.reasonIn                 -- Operation 33
    v.revokedAt        = c.now                      -- Operation 33
    v.acceptedBy       = pre.acceptedBy
    v.acceptedAt       = pre.acceptedAt
    v.declinedAt       = pre.declinedAt
}

-- written: the version is what its call's write left, over the version an earlier call
-- wrote that its token named (a call finds only what was committed before it, Execution
-- Contract Database 2).
pred written[v : Invitation] {
    let c = v.writtenBy {
        (c in InitiateCall and no v.found and initiateWrites[c, v])
        or (c in ResolveCall and some v.found and C/lt[v.found.writtenBy, c]
            and answers[c] and c.answer = Resolved and c.seen = v.found
            and keepsProperties[v.found, v]         -- Invariant 1.1, 7.1 (written so; across steps, the TLA+ model's)
            and ((c in AcceptCall  and acceptWrites[v.found, c, v])
              or (c in DeclineCall and declineWrites[v.found, c, v])
              or (c in RevokeCall  and revokeWrites[v.found, c, v])))
    }
}

-- recorded: a version the page lets the records hold (see SCOPE): it and every version it
-- was built from are what an admitted call wrote.
pred recorded[x : Invitation] {
    all v : x.*found | written[v]
}

-- aDatabase: what a resolving write reads is a state of the records — recorded
-- invitations, each written before the call, one version per invitation.
pred aDatabase[c : ResolveCall] {
    all x : c.db | recorded[x] and C/lt[x.writtenBy, c]
    all disj x, y : c.db | origin[x] != origin[y]
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Assertions (verified guarantees)
-- Each "check" asks: is there any record the page's calls can leave (or any answer a
-- resolving write can give over such records) that violates this assertion? No
-- counterexample (UNSAT) = the guarantee holds within scope.
-- ─────────────────────────────────────────────────────────────────────────────

-- A_State_3: an accepted invitation carries who joined and when.
assert A_State_3 {
    all x : Invitation | (recorded[x] and x.status = Accepted)
        implies (some x.acceptedBy and some x.acceptedAt)
}
check A_State_3 for 4 but 5 Invitation

-- A_State_4: a declined invitation carries the instant it was declined.
assert A_State_4 {
    all x : Invitation | (recorded[x] and x.status = Declined) implies some x.declinedAt
}
check A_State_4 for 4 but 5 Invitation

-- A_State_6: a pending invitation carries no resolution field: nothing records a
-- resolution that has not happened.
assert A_State_6 {
    all x : Invitation | (recorded[x] and x.status = Pending) implies noResolutionField[x]
}
check A_State_6 for 4 but 5 Invitation

-- A_Invariant_2_2: no invitation carries two resolution instants, so one record never
-- tells two stories of how it resolved.
assert A_Invariant_2_2 {
    all x : Invitation | recorded[x] implies not (
        (some x.acceptedAt and some x.declinedAt)
        or (some x.acceptedAt and some x.revokedAt)
        or (some x.declinedAt and some x.revokedAt))
}
check A_Invariant_2_2 for 4 but 5 Invitation

-- A_Invariant_3_1: every accepted invitation names, non-blank, the identity that joined.
assert A_Invariant_3_1 {
    all x : Invitation | (recorded[x] and x.status = Accepted) implies nonBlank[x.acceptedBy]
}
check A_Invariant_3_1 for 4 but 5 Invitation

-- A_Invariant_5_1: the stored terminals are told apart by their fields alone: two
-- invitations standing in different stored terminals never carry the same set of
-- resolution fields.
assert A_Invariant_5_1 {
    all x, y : Invitation | (recorded[x] and recorded[y]
                             and x.status in Terminal and y.status in Terminal
                             and x.status != y.status)
        implies pattern[x] != pattern[y]
}
check A_Invariant_5_1 for 4 but 5 Invitation

-- A_Invariant_6_1: a resolving write refused as already-resolved names which stored
-- terminal stands — never nothing, never pending, never expired.
assert A_Invariant_6_1 {
    all c : ResolveCall | (aDatabase[c] and answers[c] and c.answer = AlreadyResolved)
        implies (one c.named and c.named in Terminal)
}
check A_Invariant_6_1 for 4 but 5 Invitation

-- A_Invariant_6_2: a resolving write against a lapsed invitation answers expired, whatever
-- else is wrong with the call.
assert A_Invariant_6_2 {
    all c : ResolveCall | (aDatabase[c] and answers[c] and some x : c.seen | lapsed[x, c.now])
        implies c.answer = ExpiredRefusal
}
check A_Invariant_6_2 for 4 but 5 Invitation

-- A_Invariant_8_1: every revoked invitation names, non-blank, who withdrew it.
assert A_Invariant_8_1 {
    all x : Invitation | (recorded[x] and x.status = Revoked) implies nonBlank[x.revokedBy]
}
check A_Invariant_8_1 for 4 but 5 Invitation

-- A_Invariant_8_2: every revoked invitation says, non-blank, why it was withdrawn.
assert A_Invariant_8_2 {
    all x : Invitation | (recorded[x] and x.status = Revoked) implies nonBlank[x.revocationReason]
}
check A_Invariant_8_2 for 4 but 5 Invitation

-- A_Invariant_8_3: every revoked invitation says when it was withdrawn.
assert A_Invariant_8_3 {
    all x : Invitation | (recorded[x] and x.status = Revoked) implies some x.revokedAt
}
check A_Invariant_8_3 for 4 but 5 Invitation

-- A_Invariant_9_1: every invitation carries an expiry instant: no window is open forever.
assert A_Invariant_9_1 {
    all x : Invitation | recorded[x] implies some x.expiresAt
}
check A_Invariant_9_1 for 4 but 5 Invitation

-- A_Invariant_11_1: a token that names an invitation in the records names exactly one, so
-- the holder who presents it acts on one invitation and no other.
assert A_Invariant_11_1 {
    all c : ResolveCall | (aDatabase[c] and looksUp[c] and c.presented in c.db.token)
        implies one c.seen
}
check A_Invariant_11_1 for 4 but 5 Invitation

-- ─────────────────────────────────────────────────────────────────────────────
-- Satisfiability runs — non-vacuity guards, one for each shape the page admits
-- Each run must find at least one instance (SAT).
-- UNSAT means the model forbids a record the page admits.
-- ─────────────────────────────────────────────────────────────────────────────

-- ShowPendingWithoutInvitee: a pending invitation naming no invitee, its window sized by
-- the default ttl (the new hire with no system identity yet, tok_inv_c41 at initiation).
run ShowPendingWithoutInvitee {
    some x : Invitation | recorded[x] and x.status = Pending and no x.invitee
        and no x.writtenBy.ttlIn
} for 4 but 5 Invitation

-- ShowAcceptedByAnotherReference: an accepted invitation whose accepting identity
-- reference is not its invitee reference: the atom never matches the two (Identity 13).
run ShowAcceptedByAnotherReference {
    some x : Invitation | recorded[x] and x.status = Accepted
        and some x.invitee and x.acceptedBy != x.invitee
} for 4 but 5 Invitation

-- ShowDeclined: a declined invitation, its declination instant its one resolution field
-- (tok_inv_d58).
run ShowDeclined {
    some x : Invitation | recorded[x] and x.status = Declined
} for 4 but 5 Invitation

-- ShowRevoked: a revoked invitation with its revocation record (tok_inv_e5f).
run ShowRevoked {
    some x : Invitation | recorded[x] and x.status = Revoked
} for 4 but 5 Invitation

-- ShowAlreadyResolvedNamesRevoked: an accept against a revoked invitation answers
-- already-resolved(revoked) (the later accept of tok_inv_e5f).
run ShowAlreadyResolvedNamesRevoked {
    some c : AcceptCall | aDatabase[c] and answers[c]
        and c.answer = AlreadyResolved and c.named = Revoked
} for 4 but 5 Invitation

-- ShowStatusCheckFirst: a revoke with a blank reason against an accepted invitation
-- answers already-resolved(accepted), not invalid-request (the rejection paths).
run ShowStatusCheckFirst {
    some c : RevokeCall | aDatabase[c] and answers[c] and not nonBlank[c.reasonIn]
        and c.answer = AlreadyResolved and c.named = Accepted
} for 4 but 5 Invitation

-- ShowWindowClosed: a resolving write against a pending invitation whose window has
-- passed answers expired, and the record still stands pending (tok_inv_f77).
run ShowWindowClosed {
    some c : ResolveCall | aDatabase[c] and answers[c] and c.answer = ExpiredRefusal
        and some x : c.seen | T/lt[x.expiresAt, c.now]
} for 4 but 5 Invitation

-- ShowLapsedAtTheBoundary: the expiry instant equals the call's now: the window reads
-- lapsed, and the call answers expired (Term lapsed).
run ShowLapsedAtTheBoundary {
    some c : ResolveCall | aDatabase[c] and answers[c] and c.answer = ExpiredRefusal
        and some x : c.seen | x.expiresAt = c.now
} for 4 but 5 Invitation

-- ShowNotKnown: a token naming no invitation in the records answers not-known.
run ShowNotKnown {
    some c : ResolveCall | aDatabase[c] and answers[c] and some c.db and c.answer = NotKnown
} for 4 but 5 Invitation

-- ShowLostAnswerRetry: two pending invitations for one inviter and one context, under two
-- tokens: a retried initiate after a lost answer (tok_inv_g20 and tok_inv_h31).
run ShowLostAnswerRetry {
    some disj x, y : Invitation | recorded[x] and recorded[y] and origin[x] != origin[y]
        and x.status = Pending and y.status = Pending
        and x.inviter = y.inviter and x.context = y.context
} for 4 but 5 Invitation

-- ShowOneIdentityTwoAcceptances: one accepting identity reference on two accepted
-- invitations: no rule bounds how many invitations one identity accepts (the disputed
-- onboarding scenario).
run ShowOneIdentityTwoAcceptances {
    some disj x, y : Invitation | recorded[x] and recorded[y] and origin[x] != origin[y]
        and x.status = Accepted and y.status = Accepted and x.acceptedBy = y.acceptedBy
} for 4 but 5 Invitation
