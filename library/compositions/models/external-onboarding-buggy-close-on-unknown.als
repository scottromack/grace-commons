-- external-onboarding-buggy-close-on-unknown.als
-- DELIBERATELY WRONG twin of external-onboarding.als (unit: `compositions/external-onboarding.md formal layer`).
--
-- INJECTED DEFECT: an unknown arm is closed through the invocation close as committed, not yielded (Action wiring 60, Recoverable Invocation commit 6, 7).
--
-- BREAKS: A_Invariant_2_1, A_Invariant_4_4, A_Invariant_5_1, A_Check_4_1.
-- Everything else is external-onboarding.als as written; read its comments there.

module external_onboarding_buggy_close_on_unknown

-- ─────────────────────────────────────────────────────────────────────────────
-- Signatures (types)
-- ─────────────────────────────────────────────────────────────────────────────

-- Token: an invitation token, the id Invitation mints for one invitation.
sig Token {}

-- Ref: an external reference a caller supplies — an invitee reference at [Invite], an
-- accepting identity reference at [Onboard], or a principal reference an outside writer
-- registers a credential under.
sig Ref {}

-- Doc: a document pair (document type and document reference), folded to one value.
sig Doc {}

-- Status: the stored statuses of an invitation. Expired is shown by derivation and never
-- written (Invitation's single resolution), so it is not a stored value here.
abstract sig Status {}
one sig Pending, Accepted, Declined, Revoked extends Status {}

-- Arm: how an [Invite], [Decline] or [Revoke] call ended — landed (its post-write record
-- landed or proceeds as landed), post-failed (the post-write record refused: storage-failure
-- carrying intent, the action's writes rolled back, Audit arm 5, 22, 25), or refused (at
-- validation, at the attempt record or by Invitation: no constituent write).
abstract sig Arm {}
one sig Landed, PostFailed, Refused extends Arm {}

-- InviteCall: one [Invite] call, with the invitee reference it carries and its arm.
sig InviteCall {
    callInvitee : lone Ref,
    iarm        : one Arm
}

-- DeclineCall: one [Decline] call, with its invitation token and its arm.
sig DeclineCall {
    dToken : one Token,
    darm   : one Arm
}

-- RevokeCall: one [Revoke] call, with its invitation token and its arm.
sig RevokeCall {
    rToken : one Token,
    rarm   : one Arm
}

-- CArm: the commit partition's arm of an onboarding transaction (Term commit partition) —
-- committed, pre-commit (a call refused and the transaction rolled back), or unknown (a code
-- no constituent declares, or no reply within the commit round trip).
abstract sig CArm {}
one sig Committed, PreCommit, Unknown extends CArm {}

-- Intent: an onboarding.intended record the invocation open writes for an admitted [Onboard],
-- carrying the invitation token, the accepting identity reference and the document pair
-- (Action wiring 56, 57), and, as the model's ghost, the arm its transaction answered.
sig Intent {
    token : one Token,
    acc   : one Ref,
    doc   : one Doc,
    arm   : one CArm
}

-- Invitation: an invitation record — its token, invitee reference, stored status, the
-- accepting identity reference recorded at acceptance, and, as the model's ghosts, the
-- [Invite] that initiated it and the call whose write gave it its terminal status.
sig Invitation {
    itoken     : one Token,
    vInvitee   : lone Ref,
    status     : one Status,
    accRef     : lone Ref,
    madeBy     : one InviteCall,
    resolvedBy : lone Intent + DeclineCall + RevokeCall
}

-- Party: a party record Party Identity holds — the document pair it was enrolled with and,
-- as the model's ghost, the intent whose transaction enrolled it (none: enrolled outside the
-- composition).
sig Party {
    pdoc   : one Doc,
    pWrote : lone Intent
}

-- Credential: a credential record — its principal reference (a party id, or a reference of
-- the shared namespace an outside writer used) and, as the model's ghost, the intent whose
-- transaction registered it (none: registered outside the composition).
sig Credential {
    principal : one Party + Ref,
    cWrote    : lone Intent
}

-- InitiatedRec: an invitation.initiated record — the [Invite] that wrote it, the token and
-- the invitee reference it carries (Action wiring 6).
sig InitiatedRec {
    iCall       : one InviteCall,
    iRecToken   : one Token,
    iRecInvitee : lone Ref
}

-- DeclinedRec: an invitation.declined record — the [Decline] that wrote it and its token.
sig DeclinedRec {
    dCall     : one DeclineCall,
    dRecToken : one Token
}

-- RevokedRec: an invitation.revoked record — the [Revoke] that wrote it and its token.
sig RevokedRec {
    rCall     : one RevokeCall,
    rRecToken : one Token
}

-- Writer: who wrote a completion record — the invocation close, or an operator through the
-- invocation resolve. The sweep writes nothing here (service identity none, Recoverable
-- Invocation service identity 1a).
abstract sig Writer {}
one sig ByClose, ByOperator extends Writer {}

-- Closing: a record closing an intent under its invocation id.
abstract sig Closing {
    closes : one Intent
}

-- Completion: an onboarding.completed record — its writer, and the invitation token, the
-- accepting identity reference, the party id and the credential id it carries.
sig Completion extends Closing {
    writer : one Writer,
    cToken : lone Token,
    cAcc   : lone Ref,
    cParty : lone Party,
    cCred  : lone Credential
}

-- Refusal: an onboarding.refused record the invocation refuse writes for a pre-commit arm.
sig Refusal extends Closing {}

-- Abandonment: an operator's abandoned disposition through the invocation resolve.
sig Abandonment extends Closing {}

-- ─────────────────────────────────────────────────────────────────────────────
-- Facts: only what the page takes from outside
-- ─────────────────────────────────────────────────────────────────────────────

-- InvitationMintsOneTokenPerInvitation: Invitation mints a fresh token per initiate, so no
-- two invitation records carry one token (Invitation's own guarantee).
fact InvitationMintsOneTokenPerInvitation {
    all t : Token | lone itoken.t
}

-- InvitationRecordsTheAcceptorAtAccept: Invitation records an accepting identity reference
-- exactly on an accepted invitation (Invitation's accept; a pending, declined or revoked
-- invitation carries none).
fact InvitationRecordsTheAcceptorAtAccept {
    all v : Invitation | some v.accRef iff v.status = Accepted
}

-- OneClosingPerIntent: two closing records never name one intent's invocation id
-- (Recoverable Invocation Invariant 2.1, which that page's model checks).
fact OneClosingPerIntent {
    all i : Intent | lone closes.i
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Helpers
-- ─────────────────────────────────────────────────────────────────────────────

-- invOf: the invitation record a token names (one at most).
fun invOf[t : Token] : set Invitation {
    itoken.t
}

-- partyOf: the party an intent's transaction enrolled.
fun partyOf[i : Intent] : set Party {
    pWrote.i
}

-- credOf: the credential an intent's transaction registered.
fun credOf[i : Intent] : set Credential {
    cWrote.i
}

-- wroteNothing: an intent whose transaction left no write — no acceptance, no party, no
-- credential.
pred wroteNothing[i : Intent] {
    no pWrote.i
    no cWrote.i
    no resolvedBy.i
}

-- ─────────────────────────────────────────────────────────────────────────────
-- The writers' rules (the page's own)
-- ─────────────────────────────────────────────────────────────────────────────

-- txWrites: what a committed onboarding transaction wrote (Term onboarding transaction):
-- Invitation's accept on the intent's token with the call's accepting identity reference
-- (Action wiring 9, Wiring decision 4), Party Identity's enroll with the call's document pair
-- (Action wiring 26), and Credential's register under the party id the enroll answered
-- (Action wiring 29) — one commit.
pred txWrites[i : Intent] {
    one invOf[i.token]
    resolvedBy.i = invOf[i.token]
    invOf[i.token].status = Accepted
    invOf[i.token].accRef = i.acc
    one partyOf[i]
    partyOf[i].pdoc = i.doc
    one credOf[i]
    credOf[i].principal = partyOf[i]
}

-- commitWrites: a committed arm wrote the transaction; a pre-commit arm wrote nothing, the
-- transaction rolled back (Action wiring 24, 61, Execution Contract Database 1); an unknown
-- arm wrote the one or the other (Recoverable Invocation commit 6, 7).
pred commitWrites[i : Intent] {
    i.arm = Committed implies txWrites[i]
    i.arm = PreCommit implies wroteNothing[i]
    i.arm = Unknown implies (txWrites[i] or wroteNothing[i])
}

-- closeWrites: the invocation close closes a committed arm (Recoverable Invocation commit 4)
-- with a completion record carrying the call's token and accepting identity reference and
-- the party id and credential id the transaction answered (Action wiring 37).
pred closeWrites[m : Completion] {
    m.closes.arm in Committed + Unknown   -- DEFECT: an unknown arm closed as committed
    m.cToken = m.closes.token
    m.cAcc = m.closes.acc
    m.cParty = partyOf[m.closes]
    m.cCred = credOf[m.closes]
}

-- refuseWrites: the invocation refuse closes a pre-commit arm alone (Action wiring 58,
-- Recoverable Invocation commit 2); an unknown arm goes to the invocation yield, which writes
-- no closing (Action wiring 60).
pred refuseWrites[f : Refusal] {
    f.closes.arm = PreCommit
}

-- inviteWrites: a landed [Invite] wrote one invitation carrying the call's invitee reference
-- and one initiated record carrying its token and that reference, the record only after
-- Invitation's initiate answered the token (Action wiring 4, 6); any other arm wrote neither.
pred inviteWrites[c : InviteCall] {
    c.iarm = Landed implies {
        one madeBy.c
        (madeBy.c).vInvitee = c.callInvitee
        one iCall.c
        (iCall.c).iRecToken = (madeBy.c).itoken
        (iCall.c).iRecInvitee = c.callInvitee
    }
    c.iarm != Landed implies (no madeBy.c and no iCall.c)
}

-- declineWrites: a landed [Decline] wrote the decline on its token's invitation and the
-- decline record after it (Action wiring 41, 45); any other arm wrote neither.
pred declineWrites[c : DeclineCall] {
    c.darm = Landed implies {
        one invOf[c.dToken]
        resolvedBy.c = invOf[c.dToken]
        invOf[c.dToken].status = Declined
        one dCall.c
        (dCall.c).dRecToken = c.dToken
    }
    c.darm != Landed implies (no resolvedBy.c and no dCall.c)
}

-- revokeWrites: a landed [Revoke] wrote the revoke on its token's invitation and the revoke
-- record after it (Action wiring 49, 54); any other arm wrote neither.
pred revokeWrites[c : RevokeCall] {
    c.rarm = Landed implies {
        one invOf[c.rToken]
        resolvedBy.c = invOf[c.rToken]
        invOf[c.rToken].status = Revoked
        one rCall.c
        (rCall.c).rRecToken = c.rToken
    }
    c.rarm != Landed implies (no resolvedBy.c and no rCall.c)
}

-- conforms: every record in the state is one its writer's rules let it write. Every
-- Invitation write is a call of the four actions (Composes 9): an invitation is a landed
-- invite's, pending until a call resolves it, and its terminal status is its resolver's.
pred conforms {
    all i : Intent | commitWrites[i]
    all m : Completion | m.writer = ByClose implies closeWrites[m]
    all f : Refusal | refuseWrites[f]
    all c : InviteCall | inviteWrites[c]
    all c : DeclineCall | declineWrites[c]
    all c : RevokeCall | revokeWrites[c]
    all v : Invitation {
        v.madeBy.iarm = Landed
        v.status = Pending iff no v.resolvedBy
        v.status = Accepted implies v.resolvedBy in Intent
        v.status = Declined implies v.resolvedBy in DeclineCall
        v.status = Revoked implies v.resolvedBy in RevokeCall
    }
}

-- covered: Term covered transition for an accepted invitation — an intent of its token closed
-- by a completion record, or the gap signature of Check 5.1 (no intent and no completion
-- record for the token) or of Check 5.2 (an intent closed by neither a completion record nor a
-- refusal record).
pred covered[v : Invitation] {
    let I = token.(v.itoken) |
        (some i : I | some closes.i & Completion)
        or (no I and no cToken.(v.itoken))
        or (some i : I | no closes.i & (Completion + Refusal))
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Checks (one per single-state rule, named by the page's own label)
-- ─────────────────────────────────────────────────────────────────────────────

-- A_Invariant_1_1: every party an onboarding transaction enrolled stands beside the invitation
-- that same transaction accepted, carrying the arc's accepting identity reference.
assert A_Invariant_1_1 {
    conforms implies all p : Party | some p.pWrote implies
        some v : invOf[p.pWrote.token] |
            v.status = Accepted and v.resolvedBy = p.pWrote and v.accRef = p.pWrote.acc
}
check A_Invariant_1_1 for 3

-- A_Invariant_2_1: a completion record the close wrote carries the accepting identity reference
-- the invitation recorded at its acceptance (Check 1.3).
assert A_Invariant_2_1 {
    conforms implies all m : Completion | m.writer = ByClose implies
        all v : invOf[m.cToken] | v.status = Accepted implies m.cAcc = v.accRef
}
check A_Invariant_2_1 for 3

-- A_Invariant_2_2: an accepted invitation's accepting identity reference is the one the
-- accepting [Onboard] call carried, never one [Invite] supplied.
assert A_Invariant_2_2 {
    conforms implies all v : Invitation | v.status = Accepted implies
        v.accRef = (v.resolvedBy & Intent).acc
}
check A_Invariant_2_2 for 3

-- A_Invariant_3_1: a credential an onboarding transaction registered names that transaction's
-- party as its principal, and a completion record the close wrote names a credential whose
-- principal is the party it names (Check 2.1).
assert A_Invariant_3_1 {
    conforms implies {
        all k : Credential | some k.cWrote implies k.principal = partyOf[k.cWrote]
        all m : Completion | m.writer = ByClose implies
            all k : m.cCred | k.principal = m.cParty
    }
}
check A_Invariant_3_1 for 3

-- A_Invariant_4_1: an accepted invitation stands as a covered transition, and a declined or a
-- revoked one carries its decline or revoke record (Check 5.1, 5.2, 6.1).
assert A_Invariant_4_1 {
    conforms implies all v : Invitation {
        v.status = Accepted implies covered[v]
        v.status = Declined implies some r : DeclinedRec | r.dRecToken = v.itoken
        v.status = Revoked implies some r : RevokedRec | r.rRecToken = v.itoken
    }
}
check A_Invariant_4_1 for 3

-- A_Invariant_4_2: every invitation carries an initiated record naming its token (Check 6.2),
-- and every initiated record names an invitation that exists (Check 6.3).
assert A_Invariant_4_2 {
    conforms implies {
        all v : Invitation | some r : InitiatedRec | r.iRecToken = v.itoken
        all r : InitiatedRec | some invOf[r.iRecToken]
    }
}
check A_Invariant_4_2 for 3

-- A_Invariant_4_4: no invitation token carries two completion records the close wrote (Check
-- 7.1; an operator's second outcome is FOUND 2).
assert A_Invariant_4_4 {
    conforms implies all t : Token |
        lone { m : Completion | m.writer = ByClose and m.cToken = t }
}
check A_Invariant_4_4 for 3

-- A_Invariant_4_5: no party id stands on the close's completion records of two invitation
-- tokens; an outcome an administrator names is excepted (Invariant 4.6, Check 7.3).
assert A_Invariant_4_5 {
    conforms implies all disj m1, m2 : Completion |
        (m1.writer = ByClose and m2.writer = ByClose and m1.cToken != m2.cToken)
            implies no m1.cParty & m2.cParty
}
check A_Invariant_4_5 for 3

-- A_Invariant_5_1: a completion record the close wrote carries the invitation token, the
-- accepting identity reference, the party id and the credential id.
assert A_Invariant_5_1 {
    conforms implies all m : Completion | m.writer = ByClose implies
        (one m.cToken and one m.cAcc and one m.cParty and one m.cCred)
}
check A_Invariant_5_1 for 3

-- A_Check_4_1: no completion record the close wrote names an invitation whose status is not
-- accepted (Invariant 1.1's detection).
assert A_Check_4_1 {
    conforms implies all m : Completion | m.writer = ByClose implies
        some v : invOf[m.cToken] | v.status = Accepted
}
check A_Check_4_1 for 3

-- A_Action_wiring_24: an intent a refusal record closes wrote nothing beyond the intent and the
-- refusal record — no acceptance, no party, no credential.
assert A_Action_wiring_24 {
    conforms implies all i : Intent | some closes.i & Refusal implies wroteNothing[i]
}
check A_Action_wiring_24 for 3

-- ─────────────────────────────────────────────────────────────────────────────
-- Runs (each shape the page admits is reachable)
-- ─────────────────────────────────────────────────────────────────────────────

-- ShowHappyPath: an invitation initiated, accepted by one [Onboard] whose transaction
-- committed and whose close wrote the completion record (the happy path example).
run ShowHappyPath {
    conforms
    some m : Completion | m.writer = ByClose and some invOf[m.cToken].vInvitee
} for 3

-- ShowAcceptorNotInvitee: the accepting identity reference differs from the invitee
-- reference, and the composition does not check one against the other (Non-goal 8).
run ShowAcceptorNotInvitee {
    conforms
    some v : Invitation | v.status = Accepted and some v.vInvitee and v.accRef != v.vInvitee
} for 3

-- ShowSecondCallRefused: a second [Onboard] of an accepted token, its accept refused
-- already-resolved, closed by a refusal record beside the first arc's completion record.
run ShowSecondCallRefused {
    conforms
    some disj a, b : Intent | a.token = b.token
        and some closes.a & writer.ByClose and some closes.b & Refusal
} for 3

-- ShowRefusalLeavesPending: a refused arc (a credential collision, say, under an outside
-- credential) leaves the invitation pending, its intent and refusal record its only trace.
run ShowRefusalLeavesPending {
    conforms
    some i : Intent | some closes.i & Refusal and invOf[i.token].status = Pending
    some k : Credential | no k.cWrote
} for 3

-- ShowLostReplyOpen: a committed arc whose close never landed (a lost reply, the invocation
-- yield): the intent open, the invitation accepted, the party and credential standing —
-- Check 5.2's gap signature.
run ShowLostReplyOpen {
    conforms
    some i : Intent | no closes.i and some partyOf[i] and i.arm = Unknown
} for 3

-- ShowOperatorCompletesArc: an administrator closes an open committed arc with the outcome
-- naming its own records (the lost reply example).
run ShowOperatorCompletesArc {
    conforms
    some m : writer.ByOperator | some partyOf[m.closes] and m.cParty = partyOf[m.closes]
        and m.cCred = credOf[m.closes] and m.cToken = m.closes.token and m.cAcc = m.closes.acc
} for 3

-- ShowOperatorAbandonsCommitted: an administrator abandons a committed arc — an accepted
-- invitation with no completion record, Check 5.2's gap signature.
run ShowOperatorAbandonsCommitted {
    conforms
    some f : Abandonment | some partyOf[f.closes]
} for 3

-- ShowDeclined: a declined invitation and its decline record.
run ShowDeclined {
    conforms
    some v : Invitation | v.status = Declined
} for 3

-- ShowRevoked: a revoked invitation and its revoke record.
run ShowRevoked {
    conforms
    some v : Invitation | v.status = Revoked
} for 3

-- ShowInviteRecordFailed: an [Invite] whose initiated record failed — no invitation, no
-- initiated record (storage-failure carrying intent).
run ShowInviteRecordFailed {
    conforms
    some c : InviteCall | c.iarm = PostFailed
} for 3

-- ShowTwoPartiesShareDocuments: two arcs enrolled parties with one document pair (open line
-- 2026-11-10-b admits it), each completion naming its own.
run ShowTwoPartiesShareDocuments {
    conforms
    some disj p, q : Party | p.pdoc = q.pdoc and some p.pWrote and some q.pWrote
        and some closes.(p.pWrote) & writer.ByClose and some closes.(q.pWrote) & writer.ByClose
} for 3

-- ShowOperatorCompletionMisnames: FOUND 1 — an administrator's completion record on a
-- committed arc carrying another accepting identity reference and no credential id.
run ShowOperatorCompletionMisnames {
    conforms
    some m : writer.ByOperator | some partyOf[m.closes] and m.cAcc != m.closes.acc and no m.cCred
} for 3

-- ShowOperatorCompletesUncommitted: FOUND 1 — an administrator's completion record closing an
-- arc whose transaction never committed (its refusal record did not land), naming a pending
-- invitation.
run ShowOperatorCompletesUncommitted {
    conforms
    some m : writer.ByOperator | m.closes.arm = PreCommit and m.cToken = m.closes.token
        and invOf[m.cToken].status = Pending
} for 3

-- ShowOperatorSecondCompletion: FOUND 2 — an accepted token carrying the close's completion
-- record and an administrator's on a second, refused intent.
run ShowOperatorSecondCompletion {
    conforms
    some disj m1, m2 : Completion | m1.writer = ByClose and m2.writer = ByOperator
        and m1.cToken = m2.cToken and m2.closes.arm = PreCommit
} for 3

-- ShowOperatorNamesForeignParty: Invariant 4.6 — an administrator's outcome naming a party
-- another token's completion record names, which Check 7.3 detects.
run ShowOperatorNamesForeignParty {
    conforms
    some disj m1, m2 : Completion | m1.writer = ByClose and m2.writer = ByOperator
        and m1.cToken != m2.cToken and some m1.cParty & m2.cParty
} for 3
