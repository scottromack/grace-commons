---- MODULE session-buggy-read-stored-status ----
\* DELIBERATELY WRONG twin of session.tla (unit: `atoms/session.md formal layer`).
\*
\* INJECTED DEFECT: [Read] carries the stored status as the effective status, so a lapsed
\* session reads active (Operation 38, 41, Invariant 12.4).
\*
\* BREAKS: Inv12_4_EffectiveStatus.
\* Everything else is session.tla as written; read its comments there.

EXTENDS Integers, FiniteSets

CONSTANTS
    Tokens,      \* the session tokens the host may allocate, and a caller present
    Principals,  \* the principal references an [Issue] may carry
    Windows,     \* the session durations an [Issue] may carry, each above zero
    MaxTime,     \* the last instant the clock reaches in the model
    MaxSess      \* how many sessions the model's database holds room for

\* NONE: the value of a string field not yet written.
NONE == "none"

\* Issuer, Actor, Reason: the one issued by reference, revoked by reference and
\* revocation reason the model's calls carry (see NOT MODELED HERE).
Issuer == "login_svc"
Actor == "user_u91"
Reason == "logout"

\* Slots: the places a session can occupy, in the order they are issued.
Slots == 1..MaxSess

\* Answers: the four answers [Validate] may give (Term validation failure).
Answers == {"valid", "expired", "revoked", "not-known"}

\* NoEff: the effective statuses a call that is no [Read] reports: none.
NoEff == [s \in Slots |-> "none"]

\* NoCall: the record of the last call before any call is made, and the shape
\* of every such record: the action, the token it named, the answers it gave,
\* and the effective status a [Read] carried for each session.
NoCall == [op |-> "none", tok |-> NONE, ans |-> {}, eff |-> NoEff]

\* ---------------------------------------------------------------------------
\* State
\* ---------------------------------------------------------------------------

VARIABLES
    now,        \* the host's clock reading, injected at the seam
    n,          \* the next slot an issued session takes
    tok,        \* slot -> session token
    prin,       \* slot -> principal reference
    iss,        \* slot -> issued by reference
    issuedAt,   \* slot -> issuance instant
    expiresAt,  \* slot -> expiry instant
    status,     \* slot -> stored status ("none": no session)
    revokedAt,  \* slot -> revocation instant (-1: none)
    revokedBy,  \* slot -> revoked by reference
    reason,     \* slot -> revocation reason
    last        \* the last call made and what it answered (NoCall's shape)

\* vars: every variable; a step that changes none of them is a stutter.
vars == <<now, n, tok, prin, iss, issuedAt, expiresAt, status, revokedAt, revokedBy, reason, last>>

\* sessions: every variable that holds a session's fields: what the database
\* holds.
sessions == <<n, tok, prin, iss, issuedAt, expiresAt, status, revokedAt, revokedBy, reason>>

\* Recorded: the slot holds a session [Issue] recorded.
Recorded(s) == s < n

\* Carried: the session tokens the recorded sessions carry.
Carried == {tok[s] : s \in {x \in Slots : Recorded(x)}}

\* Live: the slots holding a session; its size is the session count.
Live == {s \in Slots : status[s] # "none"}

\* SlotOf: the slot whose session the token names, or 0 where it names none.
SlotOf(t) == IF \E s \in Slots : Recorded(s) /\ tok[s] = t
             THEN CHOOSE s \in Slots : Recorded(s) /\ tok[s] = t
             ELSE 0

\* Lapsed: the session is stored active and now is no earlier than its expiry
\* instant (Term lapsed).
Lapsed(s) == status[s] = "active" /\ now >= expiresAt[s]

\* Effective: the session's effective status: expired where it is lapsed, the
\* stored status otherwise (Term effective status).
Effective(s) == IF Lapsed(s) THEN "expired" ELSE status[s]

\* ValidateAnswers: what [Validate] answers for a token, each of the page's rules
\* adding the answer its condition calls for: not-known where the token names
\* no session (Operation 14), revoked where the stored status is revoked
\* (Operation 15), expired where the session is lapsed (Operation 16, 17), valid
\* where the effective status is active (Operation 18). Invariant 6.1 asks that
\* exactly one rule fires.
ValidateAnswers(t) ==
    LET s == SlotOf(t) IN
    IF s = 0 THEN {"not-known"}
    ELSE (IF status[s] = "revoked" THEN {"revoked"} ELSE {})
         \cup (IF Lapsed(s) THEN {"expired"} ELSE {})
         \cup (IF Effective(s) = "active" THEN {"valid"} ELSE {})

\* TypeOK: each variable holds a value of its kind (the model's typing, not a
\* rule of the page). The stored status may hold "expired", so a write that
\* stored the derived lapse would show (Invariant 12.1 is the Alloy model's).
TypeOK ==
    /\ now \in 0..MaxTime
    /\ n \in 1..(MaxSess + 1)
    /\ tok \in [Slots -> Tokens \cup {NONE}]
    /\ prin \in [Slots -> Principals \cup {NONE}]
    /\ iss \in [Slots -> {Issuer, NONE}]
    /\ issuedAt \in [Slots -> Int]
    /\ expiresAt \in [Slots -> Int]
    /\ status \in [Slots -> {"none", "active", "revoked", "expired"}]
    /\ revokedAt \in [Slots -> Int]
    /\ revokedBy \in [Slots -> {Actor, NONE}]
    /\ reason \in [Slots -> {Reason, NONE}]

\* Init: no session; the clock at its first instant.
Init ==
    /\ now = 0
    /\ n = 1
    /\ tok = [s \in Slots |-> NONE]
    /\ prin = [s \in Slots |-> NONE]
    /\ iss = [s \in Slots |-> NONE]
    /\ issuedAt = [s \in Slots |-> -1]
    /\ expiresAt = [s \in Slots |-> -1]
    /\ status = [s \in Slots |-> "none"]
    /\ revokedAt = [s \in Slots |-> -1]
    /\ revokedBy = [s \in Slots |-> NONE]
    /\ reason = [s \in Slots |-> NONE]
    /\ last = NoCall

\* ---------------------------------------------------------------------------
\* Actions
\* ---------------------------------------------------------------------------

\* Tick: the host's clock moves on by a second. A session whose expiry instant
\* it reaches lapses, and nothing is written (Expiry 2, 4, 5).
Tick ==
    /\ now < MaxTime
    /\ now' = now + 1
    /\ last' = [NoCall EXCEPT !.op = "tick"]
    /\ UNCHANGED sessions

\* Issue: [Issue] records one session in active (Operation 1, 2) in the next
\* slot, carrying the token the host allocated, one no session carries
\* (Operation 58, Identity 3, Invariant 7.2), the principal and issued by
\* references (Operation 50, 51), the injected now as its issuance instant
\* (Operation 9) and now plus the window as its expiry instant (Operation 10),
\* and answers the token (Operation 3).
Issue(t, p, w) ==
    /\ n <= MaxSess
    /\ t \notin Carried
    /\ tok' = [tok EXCEPT ![n] = t]
    /\ prin' = [prin EXCEPT ![n] = p]
    /\ iss' = [iss EXCEPT ![n] = Issuer]
    /\ issuedAt' = [issuedAt EXCEPT ![n] = now]
    /\ expiresAt' = [expiresAt EXCEPT ![n] = now + w]
    /\ status' = [status EXCEPT ![n] = "active"]
    /\ n' = n + 1
    /\ last' = [op |-> "issue", tok |-> t, ans |-> {"issued"}, eff |-> NoEff]
    /\ UNCHANGED <<now, revokedAt, revokedBy, reason>>

\* Validate: [Validate] of a token answers by the page's rules and writes
\* nothing (Operation 14 to 18, 20).
Validate(t) ==
    /\ last' = [op |-> "validate", tok |-> t, ans |-> ValidateAnswers(t), eff |-> NoEff]
    /\ UNCHANGED <<now, n, tok, prin, iss, issuedAt, expiresAt, status, revokedAt, revokedBy, reason>>

\* RevokeActive: [Revoke] of a token naming an active session, lapsed or not
\* (Operation 27), stands it in revoked (Operation 28), stamps the injected now
\* as its revocation instant (Operation 29), records the revoked by reference
\* and the reason (Operation 30, 31), and answers revoked (Operation 33).
RevokeActive(t) ==
    LET s == SlotOf(t) IN
    /\ s # 0
    /\ status[s] = "active"
    /\ status' = [status EXCEPT ![s] = "revoked"]
    /\ revokedAt' = [revokedAt EXCEPT ![s] = now]
    /\ revokedBy' = [revokedBy EXCEPT ![s] = Actor]
    /\ reason' = [reason EXCEPT ![s] = Reason]
    /\ last' = [op |-> "revoke", tok |-> t, ans |-> {"revoked"}, eff |-> NoEff]
    /\ UNCHANGED <<now, n, tok, prin, iss, issuedAt, expiresAt>>

\* RevokeAlready: [Revoke] of a token naming a revoked session answers
\* already-terminal and writes nothing (Operation 23).
RevokeAlready(t) ==
    LET s == SlotOf(t) IN
    /\ s # 0
    /\ status[s] = "revoked"
    /\ last' = [op |-> "revoke", tok |-> t, ans |-> {"already-terminal"}, eff |-> NoEff]
    /\ UNCHANGED <<now, n, tok, prin, iss, issuedAt, expiresAt, status, revokedAt, revokedBy, reason>>

\* RevokeNotKnown: [Revoke] of a token naming no session answers not-known and
\* writes nothing (Operation 22).
RevokeNotKnown(t) ==
    /\ SlotOf(t) = 0
    /\ last' = [op |-> "revoke", tok |-> t, ans |-> {"not-known"}, eff |-> NoEff]
    /\ UNCHANGED <<now, n, tok, prin, iss, issuedAt, expiresAt, status, revokedAt, revokedBy, reason>>

\* Read: [Read] answers every session with its effective status (Operation 37,
\* 38) and writes nothing (Operation 39).
Read ==
    /\ last' = [op |-> "read", tok |-> NONE, ans |-> {},
                eff |-> [s \in Slots |-> IF Recorded(s) THEN status[s] ELSE "none"]]   \* BUG: stored status alone
    /\ UNCHANGED <<now, n, tok, prin, iss, issuedAt, expiresAt, status, revokedAt, revokedBy, reason>>

\* Next: the clock moving, or any call: an [Issue], a [Validate] or a [Revoke]
\* of any token, or a [Read].
Next ==
    \/ Tick
    \/ \E t \in Tokens, p \in Principals, w \in Windows : Issue(t, p, w)
    \/ \E t \in Tokens : Validate(t)
    \/ \E t \in Tokens : RevokeActive(t)
    \/ \E t \in Tokens : RevokeAlready(t)
    \/ \E t \in Tokens : RevokeNotKnown(t)
    \/ Read

\* Spec: every behaviour from Init by Next steps.
Spec == Init /\ [][Next]_vars

\* ---------------------------------------------------------------------------
\* Checks (the verification surface). Each spells the page's condition itself,
\* so a defect in an action's own reading of it shows.
\* ---------------------------------------------------------------------------

\* Names: some recorded session carries the token.
Names(t, s) == Recorded(s) /\ tok[s] = t

\* Inv1_1_IssueFieldsFixed: no step changes a recorded session's token,
\* principal reference, issued by reference, issuance instant or expiry
\* instant: what [Issue] recorded reads the same for ever (Invariant 1.1,
\* Identity 6, Check 1.2). With the page's nine fields, the status and the
\* revocation fields are all a later step may write (Invariant 1.2).
Inv1_1_IssueFieldsFixed ==
    [][\A s \in Slots : Recorded(s) =>
          /\ tok'[s] = tok[s]
          /\ prin'[s] = prin[s]
          /\ iss'[s] = iss[s]
          /\ issuedAt'[s] = issuedAt[s]
          /\ expiresAt'[s] = expiresAt[s]]_vars

\* Inv2_1_ExpiryFixed: no step changes a recorded expiry instant: a session
\* that needs longer is issued again, never extended (Invariant 2.1,
\* Non-goal 7).
Inv2_1_ExpiryFixed ==
    [][\A s \in Slots : Recorded(s) => expiresAt'[s] = expiresAt[s]]_vars

\* Inv3_1_ValidOnlyIfLive: [Validate] answers valid only where the token names
\* a session stored active whose expiry instant now has not reached
\* (Invariant 3.1).
Inv3_1_ValidOnlyIfLive ==
    [][(last'.op = "validate" /\ "valid" \in last'.ans) =>
          \E s \in Slots : Names(last'.tok, s) /\ status[s] = "active" /\ now < expiresAt[s]]_vars

\* Inv3_3_RevokedNeverExpired: [Validate] never answers expired for a revoked
\* session, its deadline passed or not: revocation takes precedence
\* (Invariant 3.3, Operation 15, 17).
Inv3_3_RevokedNeverExpired ==
    [][(last'.op = "validate" /\ \E s \in Slots : Names(last'.tok, s) /\ status[s] = "revoked")
          => "expired" \notin last'.ans]_vars

\* Inv4_1_RevokedNeverValid: [Validate] never answers valid for a revoked
\* session, its window still open or not (Invariant 4.1).
Inv4_1_RevokedNeverValid ==
    [][(last'.op = "validate" /\ \E s \in Slots : Names(last'.tok, s) /\ status[s] = "revoked")
          => "valid" \notin last'.ans]_vars

\* Inv5_1_RevokedStaysRevoked: no step moves a revoked session out of revoked
\* (Invariant 5.1, State 10, Operation 47).
Inv5_1_RevokedStaysRevoked ==
    [][\A s \in Slots : status[s] = "revoked" => status'[s] = "revoked"]_vars

\* Inv6_1_ExactlyOneAnswer: every [Validate] answers exactly one of valid,
\* expired, revoked and not-known: the page's four rules never both fire and
\* never all fail, the deadline instant included (Invariant 6.1).
Inv6_1_ExactlyOneAnswer ==
    [][last'.op = "validate" =>
          /\ Cardinality(last'.ans) = 1
          /\ last'.ans \subseteq Answers]_vars

\* Inv7_2_HostTokenFresh: no [Issue] records a token a session already carries,
\* a revoked or lapsed session's included: a token is never reused
\* (Invariant 7.2, Identity 5).
Inv7_2_HostTokenFresh ==
    [][last'.op = "issue" => last'.tok \notin Carried]_vars

\* Inv9_2_CountNeverReduced: no step reduces the session count: the atom offers
\* no removal (Invariant 9.2, Invariant 9.1, State 11).
Inv9_2_CountNeverReduced ==
    [][Cardinality(Live') >= Cardinality(Live)]_vars

\* Inv11_1_LapsedNeverValid: [Validate] never answers valid for a session stored
\* active whose expiry instant now has reached, the deadline instant itself
\* included (Invariant 11.1, Term lapsed).
Inv11_1_LapsedNeverValid ==
    [][(last'.op = "validate" /\ \E s \in Slots : Names(last'.tok, s) /\ status[s] = "active" /\ now >= expiresAt[s])
          => "valid" \notin last'.ans]_vars

\* Inv12_3_LapseWritesNothing: the clock moving, and every lapse it brings,
\* writes nothing to a session: no expire action, no scheduler, no stamp
\* (Invariant 12.3, Expiry 2, 4).
Inv12_3_LapseWritesNothing ==
    [][last'.op = "tick" => UNCHANGED sessions]_vars

\* Inv12_4_EffectiveStatus: the effective status a [Read] carries for each
\* session is expired where it is stored active and now has reached its
\* expiry instant, and its stored status otherwise: it rests on the stored
\* status, the expiry instant and now, and never on the stored status alone
\* (Invariant 12.4, Operation 38, 40, 41).
Inv12_4_EffectiveStatus ==
    [][last'.op = "read" =>
          \A s \in Slots : Recorded(s) =>
              last'.eff[s] = IF status[s] = "active" /\ now >= expiresAt[s]
                             THEN "expired" ELSE status[s]]_vars

\* Op20_ValidateWritesNothing: a [Validate] step changes no session
\* (Operation 20).
Op20_ValidateWritesNothing ==
    [][last'.op = "validate" => UNCHANGED sessions]_vars

\* Op27_RevokeAcceptsLapsed: a [Revoke] of a token naming a session stored
\* active answers revoked, its deadline passed or not: a lapse is not a stored
\* terminal (Operation 27, Operation 24).
Op27_RevokeAcceptsLapsed ==
    [][(last'.op = "revoke" /\ \E s \in Slots : Names(last'.tok, s) /\ status[s] = "active")
          => last'.ans = {"revoked"}]_vars

\* Op39_ReadWritesNothing: a [Read] step changes no session (Operation 39).
Op39_ReadWritesNothing ==
    [][last'.op = "read" => UNCHANGED sessions]_vars

\* Con4_IssueAddsASession: every [Issue] adds one session to the count, where
\* the principal already holds a session too: two [Issue] calls for one
\* principal record two sessions (Concurrency 4, Operation 1, Non-goal 12).
Con4_IssueAddsASession ==
    [][last'.op = "issue" => Cardinality(Live') = Cardinality(Live) + 1]_vars

====
