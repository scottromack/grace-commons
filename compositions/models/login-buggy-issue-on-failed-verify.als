-- login-buggy-issue-on-failed-verify.als
-- DELIBERATELY WRONG twin of login.als (unit: `compositions/login.md formal layer`).
--
-- INJECTED DEFECT: Session's issue is called although verify answered failed-verification (Action wiring
-- 4 dropped); the login still answers invalid-credential, and no login succeeded event names
-- the session.
--
-- BREAKS: A_Invariant_1_2, A_Composition_state_13.
-- Everything else is login.als as written; read its comments there.

module login_buggy_issue_on_failed_verify

-- ─────────────────────────────────────────────────────────────────────────────
-- Signatures (types)
-- ─────────────────────────────────────────────────────────────────────────────

-- Principal: a principal reference, the key Credential and Session use.
sig Principal {}

-- CType: a credential type; the credential id read keys on a principal reference and a
-- credential type (Action wiring 5).
sig CType {}

-- Cred: one of Credential's credentials, carrying the pair it was registered for.
sig Cred {
    owner : one Principal,
    ctype : one CType
}

-- Token: a session token, minted by Session's issue (Capability requirement 4: the
-- composition mints no id).
sig Token {}

-- EntryId: an entry id the host supplies at the seam for one login call (Capability
-- requirement 16).
sig EntryId {}

-- VerifyAnswer: what Credential's verify answered a login: verified, or failed-verification
-- (a state-unavailable writes nothing).
abstract sig VerifyAnswer {}
one sig Verified, FailedVerification extends VerifyAnswer {}

-- Outcome: the login event log entry's classification of a login call (Term Outcome).
abstract sig Outcome {}
one sig OSuccess, OFailedVerification extends Outcome {}

-- LoginEventKind: the login-family event a login records (Term login event).
abstract sig LoginEventKind {}
one sig LoginSucceeded, LoginFailed extends LoginEventKind {}

-- ValidateAnswer: the four answers of Session's validate.
abstract sig ValidateAnswer {}
one sig VValid, VExpired, VRevoked, VNotKnown extends ValidateAnswer {}

-- RevokeAnswer: what Session's revoke answers a cascade: revoked, or one of the refusals
-- the cascade counts (Action wiring 36, 41, 42).
abstract sig RevokeAnswer {}
one sig RRevoked, RAlreadyTerminal, RNotKnown, RInvalidRequest extends RevokeAnswer {}

-- Side: the two maps a map write writes (Composition state 1, 2).
abstract sig Side {}
one sig C2S, S2C extends Side {}

-- Mark: an audit event recorded in a cascade's transaction.
abstract sig Mark {}
one sig Recorded extends Mark {}

-- Event: one commit in the store's one order (Execution Contract Database 1, 2); earlier
-- holds the commits before it.
abstract sig Event {
    earlier : set Event
}

-- CredRegistered: the deployment's call of Credential's register (Composition note 2),
-- outside the composition (Composes 8).
sig CredRegistered extends Event {
    cred : one Cred
}

-- CredRevoked: the deployment's call of Credential's revoke (Composition note 2, 3),
-- outside the composition (Composes 10, Wiring decision 3).
sig CredRevoked extends Event {
    revoked : one Cred
}

-- OutsideIssue: Session's issue called by another surface, outside the issuer references
-- (Non-goal 12, 13).
sig OutsideIssue extends Event {
    otoken : one Token,
    oprincipal : one Principal
}

-- Login: one admitted login's transaction: what the call supplied, what verify answered,
-- the credential id read, the session Session's issue answered, the login event log entry
-- and its login event (Action wiring 1 to 13, 37 to 39; Execution Contract Database 1).
sig Login extends Event {
    lprincipal : one Principal,
    ltype : one CType,
    verify : one VerifyAnswer,
    credRead : lone Cred,
    session : lone Token,
    entryId : one EntryId,
    outcome : lone Outcome,
    eventKind : lone LoginEventKind,
    evToken : lone Token,
    evCred : lone Cred,
    evEntry : lone EntryId
}

-- MapWrite: one write of a pair into the maps, under one transaction of its own
-- (Composition state 3), outside the login's commit (the maps are a derived index).
abstract sig MapWrite extends Event {
    mcred : one Cred,
    mtoken : one Token,
    sides : set Side
}

-- LoginMap: a login's own map write, after its commit (Action wiring 9); a failed one
-- leaves no commit (Action wiring 10).
sig LoginMap extends MapWrite {
    mlogin : one Login
}

-- Backfill: the sweep's write of a pair a login succeeded event carries (Reconciliation 20).
sig Backfill extends MapWrite {
    source : one Login
}

-- Logout: one admitted logout whose Session's revoke answered revoked, with its logout
-- event (Action wiring 14, 16); a refused logout writes nothing.
sig Logout extends Event {
    lToken : one Token
}

-- Cascade: one admitted [Revoke Sessions For Credential] transaction: the initiation, the
-- cascade set it read, validate's and revoke's answers per token, the four counts as the
-- tokens counted, the per-session events and the completion (Action wiring 17 to 26, 32
-- to 36, 41, 42).
sig Cascade extends Event {
    kcred : one Cred,
    initiation : lone Mark,
    cset : set Token,
    validate : Token -> lone ValidateAnswer,
    revokeAns : Token -> lone RevokeAnswer,
    revokedT : set Token,
    skippedT : set Token,
    failedT : set Token,
    notFoundT : set Token,
    revEvents : set Token,
    notFoundEvents : set Token,
    failureEvents : set Token,
    completion : lone Mark
}

-- Abandon: the sweep's cascade abandoned event for an initiation (Reconciliation 12).
sig Abandon extends Event {
    abandons : one Cascade
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Facts: only what the page takes from outside
-- ─────────────────────────────────────────────────────────────────────────────

-- The store commits in one order (Execution Contract Database 1, 2): earlier is a strict
-- total order.
fact OneStoreOrder {
    all e : Event | e not in e.earlier
    all e : Event | e.earlier.earlier in e.earlier
    all disj x, y : Event | x in y.earlier or y in x.earlier
}

-- Credential registers each credential once, only where the pair holds no effective-active
-- credential (duplicate-active-credential otherwise), and revokes a credential once, only
-- while it stands active.
fact CredentialRecords {
    all c : Cred | one cred.c
    all r : CredRegistered | no effActive[r.cred.owner, r.cred.ctype, r.earlier]
    all v : CredRevoked | activeOver[v.revoked, v.earlier]
    all c : Cred | lone revoked.c
}

-- Session mints each session token once, to one issue call.
fact SessionMintsOnce {
    all t : Token | lone (session.t + otoken.t)
}

-- The host supplies an entry id per login call, distinct from every other login call's
-- (Capability requirement 16).
fact HostEntryIds {
    all disj l1, l2 : Login | l1.entryId != l2.entryId
}

-- Session's validate and revoke answer from its records: not-known for a token it never
-- issued, revoked or already-terminal for a session stored revoked; a session not stored
-- revoked validates valid or, its deadline passed, expired (a clock reading), and its
-- revoke answers revoked or invalid-request. A logout's revoke answered revoked.
fact SessionAnswers {
    all k : Cascade, t : Token | some k.validate[t] implies {
        k.validate[t] = VNotKnown iff not issuedOver[t, k.earlier]
        k.validate[t] = VRevoked iff (issuedOver[t, k.earlier] and storedRevokedOver[t, k.earlier])
    }
    all k : Cascade, t : Token | some k.revokeAns[t] implies {
        k.revokeAns[t] = RNotKnown iff not issuedOver[t, k.earlier]
        k.revokeAns[t] = RAlreadyTerminal iff (issuedOver[t, k.earlier] and storedRevokedOver[t, k.earlier])
    }
    all o : Logout | issuedOver[o.lToken, o.earlier] and not storedRevokedOver[o.lToken, o.earlier]
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Helpers
-- ─────────────────────────────────────────────────────────────────────────────

-- activeOver: a credential stands active over some commits — registered among them, not
-- yet revoked (effective-active, expiry left out).
pred activeOver[c : Cred, s : set Event] {
    some (cred.c & s)
    no (revoked.c & s)
}

-- pairCreds: the credentials registered for a pair over some commits.
fun pairCreds[p : set Principal, t : set CType, s : set Event] : set Cred {
    { c : Cred | c.owner in p and c.ctype in t and some (cred.c & s) }
}

-- effActive: the pair's credentials standing effective-active over some commits.
fun effActive[p : set Principal, t : set CType, s : set Event] : set Cred {
    { c : pairCreds[p, t, s] | activeOver[c, s] }
}

-- issuedOver: Session issued a token among some commits.
pred issuedOver[t : Token, s : set Event] {
    some ((session.t + otoken.t) & s)
}

-- storedRevokedOver: a session stands stored revoked over some commits — a logout's or a
-- cascade's revoke answered revoked for it.
pred storedRevokedOver[t : Token, s : set Event] {
    t in (Logout & s).lToken or (some k : Cascade & s | k.revokeAns[t] = RRevoked)
}

-- sessionsOf: the tokens Session issued to a principal over some commits.
fun sessionsOf[p : set Principal, s : set Event] : set Token {
    (Login & s & lprincipal.p).session + (OutsideIssue & s & oprincipal.p).otoken
}

-- c2sOver: the credential-to-sessions map as the map writes among some commits left it.
fun c2sOver[s : set Event] : Cred -> Token {
    { c : Cred, t : Token | some m : MapWrite & s | C2S in m.sides and m.mcred = c and m.mtoken = t }
}

-- s2cOver: the session-to-credential map as the map writes among some commits left it.
fun s2cOver[s : set Event] : Token -> Cred {
    { t : Token, c : Cred | some m : MapWrite & s | S2C in m.sides and m.mcred = c and m.mtoken = t }
}

-- rebuiltOver: the session-to-credential map rebuilt from the login succeeded events among
-- some commits (Composition state 7).
fun rebuiltOver[s : set Event] : Token -> Cred {
    { t : Token, c : Cred | some l : Login & s |
        l.eventKind = LoginSucceeded and l.evToken = t and l.evCred = c }
}

-- eventSet: the event-derived set for a credential id over some commits (Term cascade set).
fun eventSet[c : Cred, s : set Event] : set Token {
    (rebuiltOver[s]).c
}

-- ─────────────────────────────────────────────────────────────────────────────
-- The writers: what each record may be, over the commits before it
-- ─────────────────────────────────────────────────────────────────────────────

-- loginWrites: an admitted login. On verified: the credential id read answers the pair's
-- effective-active credential (Action wiring 5; none answers storage-failure and commits
-- nothing, Action wiring 30), Session's issue answers a token (Action wiring 4, 8), the
-- entry's outcome is success and the login succeeded event carries the pair (Action wiring
-- 12, 13). On failed-verification: no session (Action wiring 2, 4), the entry's outcome
-- failed-verification and the login failed event. Either way the event carries the entry's
-- entry id (Action wiring 39).
pred loginWrites[l : Login] {
    l.verify = Verified implies {
        l.credRead = effActive[l.lprincipal, l.ltype, l.earlier]   -- Action wiring 5
        one l.credRead                                              -- Action wiring 30
        one l.session                                               -- Action wiring 4, 8
        l.outcome = OSuccess                                        -- Action wiring 12
        l.eventKind = LoginSucceeded                                -- Action wiring 13
        l.evToken = l.session and l.evCred = l.credRead             -- the pair on the event
    }
    l.verify = FailedVerification implies {
        no l.credRead
        one l.session                                               -- DEFECT: issued on a refused verify
        l.outcome = OFailedVerification                             -- Action wiring 12
        l.eventKind = LoginFailed                                   -- Action wiring 13
        no l.evToken and no l.evCred
    }
    l.evEntry = l.entryId                                           -- Action wiring 39
}

-- loginMapWrites: a login's map write, after its commit and only where Session's issue
-- answered a token, writing the token and the credential id the read answered into both
-- maps (Action wiring 9; Composition state 1 to 3).
pred loginMapWrites[m : LoginMap] {
    m.mlogin in m.earlier                                           -- Action wiring 9
    some m.mlogin.session                                           -- Action wiring 9
    m.mtoken = m.mlogin.session
    m.mcred = m.mlogin.credRead                                     -- Action wiring 5
    m.sides = C2S + S2C                                             -- Composition state 3
}

-- backfillWrites: the sweep writes into both maps the pair a login succeeded event carries,
-- where both maps lack it (Reconciliation 20).
pred backfillWrites[b : Backfill] {
    b.source in b.earlier
    b.source.eventKind = LoginSucceeded
    b.mtoken = b.source.evToken and b.mcred = b.source.evCred
    b.mcred -> b.mtoken not in c2sOver[b.earlier]
    b.mtoken -> b.mcred not in s2cOver[b.earlier]
    b.sides = C2S + S2C                                             -- Reconciliation 20
}

-- logoutWrites: an admitted logout calls Session's revoke only where the rebuilt
-- session-to-credential map carries the token (Action wiring 14, 43).
pred logoutWrites[o : Logout] {
    some (rebuiltOver[o.earlier])[o.lToken]
}

-- cascadeWrites: an admitted cascade records its initiation, reads the cascade set as the
-- union of the map's entry and the event-derived set, validates every token of it, revokes
-- every token validate answered valid for, counts each token once by the answers, records
-- a per-session event for each revoked, not-found and failed token, and records the
-- completion (Action wiring 17 to 23, 25, 26, 32, 34 to 36, 41, 42).
pred cascadeWrites[k : Cascade] {
    one k.initiation                                                -- Action wiring 17, 32
    k.cset = (c2sOver[k.earlier])[k.kcred] + eventSet[k.kcred, k.earlier]   -- Action wiring 18
    k.validate.univ = k.cset                                        -- Action wiring 19
    k.revokeAns.univ = k.validate.VValid                            -- Action wiring 20, 21, 34
    k.revokedT = k.revokeAns.RRevoked                               -- Action wiring 23
    k.skippedT = k.validate.(VExpired + VRevoked)
               + k.revokeAns.RAlreadyTerminal                       -- Action wiring 22, 41
    k.notFoundT = k.validate.VNotKnown + k.revokeAns.RNotKnown      -- Action wiring 35, 42
    k.failedT = k.revokeAns.RInvalidRequest                         -- Action wiring 36
    k.revEvents = k.revokedT                                        -- Action wiring 23
    k.notFoundEvents = k.notFoundT                                  -- Action wiring 35, 42
    k.failureEvents = k.failedT                                     -- Action wiring 36
    one k.completion                                                -- Action wiring 25, 26
}

-- abandonWrites: the sweep records a cascade abandoned event for an initiation carrying no
-- completion (Reconciliation 12).
pred abandonWrites[a : Abandon] {
    a.abandons in a.earlier
    one a.abandons.initiation
    no a.abandons.completion                                        -- Reconciliation 12
}

-- conforms: every record in the state is one its writer's rules let it write.
pred conforms {
    all l : Login | loginWrites[l]
    all m : LoginMap | loginMapWrites[m]
    all b : Backfill | backfillWrites[b]
    all o : Logout | logoutWrites[o]
    all k : Cascade | cascadeWrites[k]
    all a : Abandon | abandonWrites[a]
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Assertions (verified guarantees)
-- Each "check" asks: is there any state the composition's writers can leave that violates
-- this assertion? No counterexample (UNSAT) = the guarantee holds within scope.
-- ─────────────────────────────────────────────────────────────────────────────

-- A_Invariant_1_1: every session token the session-to-credential map carries was issued by
-- a login whose verify answered verified, committed before the entry was written.
assert A_Invariant_1_1 {
    conforms implies all m : MapWrite | S2C in m.sides implies
        some l : Login & m.earlier | l.session = m.mtoken and l.verify = Verified
}
check A_Invariant_1_1 for 3 but 6 Event

-- A_Invariant_1_2: no login whose verify answered failed-verification issued a session.
assert A_Invariant_1_2 {
    conforms implies all l : Login | l.verify = FailedVerification implies no l.session
}
check A_Invariant_1_2 for 3 but 6 Event

-- A_Invariant_2_1: every token the cascade set carried, that validate answered valid for and
-- that the cascade did not count failed, stands revoked at the cascade's commit.
assert A_Invariant_2_1 {
    conforms implies all k : Cascade, t : k.cset |
        (k.validate[t] = VValid and t not in k.failedT) implies storedRevokedOver[t, k.earlier + k]
}
check A_Invariant_2_1 for 3 but 6 Event

-- A_Invariant_2_2: a cascade's counts and its per-session events cover only tokens its set
-- carried.
assert A_Invariant_2_2 {
    conforms implies all k : Cascade |
        (k.revokedT + k.skippedT + k.failedT + k.notFoundT
            + k.revEvents + k.notFoundEvents + k.failureEvents) in k.cset
}
check A_Invariant_2_2 for 3 but 6 Event

-- A_Invariant_2_3: a cascade's set is the union of the credential-to-sessions map's entry
-- and the event-derived set, as both stood at the cascade's commit.
assert A_Invariant_2_3 {
    conforms implies all k : Cascade |
        k.cset = (c2sOver[k.earlier])[k.kcred] + eventSet[k.kcred, k.earlier]
}
check A_Invariant_2_3 for 3 but 6 Event

-- A_Invariant_2_4: every session a login issued under the credential before the cascade is
-- in the cascade's set, whether or not the login's map write landed.
assert A_Invariant_2_4 {
    conforms implies all k : Cascade, l : Login & k.earlier |
        (l.credRead = k.kcred and some l.session) implies l.session in k.cset
}
check A_Invariant_2_4 for 3 but 6 Event

-- A_Invariant_3_1: every session-to-credential entry names the credential id the issuing
-- login's credential id read answered.
assert A_Invariant_3_1 {
    conforms implies all m : MapWrite, l : Login |
        (S2C in m.sides and l.session = m.mtoken) implies m.mcred = l.credRead
}
check A_Invariant_3_1 for 3 but 6 Event

-- A_Invariant_5_1: every login succeeded event names a session token the map rebuilt from
-- the login succeeded events carries.
assert A_Invariant_5_1 {
    conforms implies all l : Login | l.eventKind = LoginSucceeded implies
        (one l.evToken and some (rebuiltOver[Event])[l.evToken])
}
check A_Invariant_5_1 for 3 but 6 Event

-- A_Invariant_5_2: every session revoked event names a token the cascade found valid.
assert A_Invariant_5_2 {
    conforms implies all k : Cascade, t : k.revEvents | k.validate[t] = VValid
}
check A_Invariant_5_2 for 3 but 6 Event

-- A_Invariant_6_1: the credential-to-sessions map and the session-to-credential map agree,
-- pair for pair.
assert A_Invariant_6_1 {
    conforms implies c2sOver[Event] = ~(s2cOver[Event])
}
check A_Invariant_6_1 for 3 but 6 Event

-- A_Composition_state_13: every session a login issued rests on exactly one credential in
-- the rebuilt map, and no token carries two credentials in either stored map.
assert A_Composition_state_13 {
    conforms implies all t : Token {
        lone (s2cOver[Event])[t]
        lone (c2sOver[Event]).t
        t in Login.session implies one (rebuiltOver[Event])[t]
    }
}
check A_Composition_state_13 for 3 but 6 Event

-- A_Check_3_2: every login event log entry has exactly one mirrored event, the one carrying
-- its entry id, and the entry's outcome matches the event's kind.
assert A_Check_3_2 {
    conforms implies all l : Login | let ev = evEntry.(l.entryId) {
        one ev
        l.outcome = OSuccess iff ev.eventKind = LoginSucceeded
    }
}
check A_Check_3_2 for 3 but 6 Event

-- A_Check_4_1: every cascade initiation carries exactly one of a completion event and an
-- abandoned event.
assert A_Check_4_1 {
    conforms implies all k : Cascade | one k.initiation implies
        ((one k.completion and no abandons.k) or (no k.completion and one abandons.k))
}
check A_Check_4_1 for 3 but 6 Event

-- ─────────────────────────────────────────────────────────────────────────────
-- Satisfiability runs — non-vacuity guards, one for each shape the page admits
-- Each run must find at least one instance (SAT).
-- UNSAT means the model forbids a state the page admits.
-- ─────────────────────────────────────────────────────────────────────────────

-- ShowSuccessfulLogin: the successful login example — verified, a session, the entry, the
-- login succeeded event and both maps written.
run ShowSuccessfulLogin {
    conforms
    some l : Login, m : LoginMap | l.verify = Verified and m.mlogin = l
} for 3 but 6 Event

-- ShowFailedLogin: the wrong-password example — invalid-credential, the entry and the login
-- failed event, no session and no map entry.
run ShowFailedLogin {
    conforms
    some l : Login | l.verify = FailedVerification
} for 3 but 6 Event

-- ShowLogout: the logout example — a session issued, mapped, and revoked by its logout.
run ShowLogout {
    conforms
    some o : Logout, m : LoginMap | o.lToken = m.mtoken
} for 3 but 6 Event

-- ShowCompromiseCascade: the cascade example — the deployment revokes the credential, then
-- the cascade revokes one live session and skips one lapsed.
run ShowCompromiseCascade {
    conforms
    some k : Cascade, v : CredRevoked {
        v.revoked = k.kcred and v in k.earlier
        some k.revokedT
        some t : k.skippedT | k.validate[t] = VExpired
    }
} for 3 but 6 Event

-- ShowLostMapEntryCascade: a login whose map write failed (no map write commit), and a
-- cascade that still reaches and revokes its session through the event-derived set.
run ShowLostMapEntryCascade {
    conforms
    some k : Cascade, l : Login {
        l.session in k.revokedT
        no mlogin.l
        l.session not in (c2sOver[k.earlier])[k.kcred]
    }
} for 3 but 6 Event

-- ShowBackfill: the sweep writes into both maps a pair whose map write failed.
run ShowBackfill {
    conforms
    some b : Backfill | no mlogin.(b.source)
} for 3 but 6 Event

-- ShowFailedRevoke: Session's revoke refuses a cascade's revoke with invalid-request; the
-- token is counted failed with a revoke failure event, and stays live.
run ShowFailedRevoke {
    conforms
    some k : Cascade | some k.failedT
} for 3 but 6 Event

-- ShowLogoutBeforeCascade: the logout racing the cascade (Final Critique 1) — the session
-- logged out first is counted skipped.
run ShowLogoutBeforeCascade {
    conforms
    some o : Logout, k : Cascade | o in k.earlier and o.lToken in k.skippedT
} for 3 but 6 Event

-- ShowOutsideSession: a session Session issued outside the issuer references to the
-- credential's principal, which no map carries and the cascade leaves alone (Non-goal 12,
-- 13).
run ShowOutsideSession {
    conforms
    some o : OutsideIssue, k : Cascade {
        o in k.earlier
        o.oprincipal = k.kcred.owner
        o.otoken not in k.cset
        some k.cset
    }
} for 3 but 6 Event
