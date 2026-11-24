---- MODULE session-gated-authorization-buggy-callerprincipal ----
\* DELIBERATELY WRONG twin of session-gated-authorization.tla (unit: `compositions/session-gated-authorization.md formal layer`).
\*
\* INJECTED DEFECT: permitted is called with a principal the caller supplies, not the valid answer's (Invariant 2.1, Action wiring 7, 8).
\*
\* BREAKS: Inv2_1_PrincipalBinding.
\* Everything else is session-gated-authorization.tla as written; read its comments there.

EXTENDS Integers, FiniteSets

CONSTANTS
    Tokens,      \* the session tokens Session may issue and a caller present
    Principals,  \* the principal references a session may be issued for
    Scopes,      \* the action scopes a caller may ask about
    Window,      \* the session duration Session issues with, above zero
    MaxTime      \* the last instant the clock reaches in the model

\* NONE: the value of a field not written.
NONE == "none"

\* NoFly: no [Check Permitted] call in flight.
NoFly == [tok |-> NONE, scp |-> NONE, vans |-> NONE, vprin |-> NONE]

\* NoLast: the record a step that answers no call leaves: what the last step did.
NoLast == [op |-> "env", tok |-> NONE, subj |-> NONE, ans |-> NONE, why |-> NONE]

\* ---------------------------------------------------------------------------
\* State
\* ---------------------------------------------------------------------------

VARIABLES
    now,          \* the host's clock
    status,       \* token -> Session's stored status ("none": never issued)
    prin,         \* token -> the principal the session was issued for
    exp,          \* token -> the session's expiry instant (-1: none)
    grants,       \* Permissions' active grants, as <<principal, scope>> pairs
    fly,          \* the call in flight: its inputs and the validate answer it holds
    last,         \* what the last step did, and the answer a call gave
    everRevoked,  \* history: the tokens whose session Session revoked
    everLapsed    \* history: the tokens whose expiry instant the clock reached

\* vars: every variable; a step that changes none of them is a stutter.
vars == <<now, status, prin, exp, grants, fly, last, everRevoked, everLapsed>>

\* records: Session's and Permissions' records, what a call must not write.
records == <<status, prin, exp, grants>>

\* VAnswer: Session's validate answer for a token at this step (Session Operation 14
\* to 18; Term valid answer, Term invalid answer).
VAnswer(t) ==
    IF status[t] = "none" THEN "not-known"
    ELSE IF status[t] = "revoked" THEN "revoked"
    ELSE IF now >= exp[t] THEN "expired"
    ELSE "valid"

\* TypeOK: each variable holds a value of its kind (the model's typing, not a rule of
\* the page).
TypeOK ==
    /\ now \in 0..MaxTime
    /\ status \in [Tokens -> {"none", "active", "revoked"}]
    /\ prin \in [Tokens -> Principals \cup {NONE}]
    /\ exp \in [Tokens -> Int]
    /\ grants \subseteq Principals \X Scopes
    /\ fly.vans \in {NONE, "valid", "expired", "revoked", "not-known"}
    /\ last.ans \in {NONE, "permitted", "denied", "session-invalid"}
    /\ everRevoked \subseteq Tokens
    /\ everLapsed \subseteq Tokens

\* Init: no session, no grant, no call; the clock at its first instant.
Init ==
    /\ now = 0
    /\ status = [t \in Tokens |-> "none"]
    /\ prin = [t \in Tokens |-> NONE]
    /\ exp = [t \in Tokens |-> -1]
    /\ grants = {}
    /\ fly = NoFly
    /\ last = NoLast
    /\ everRevoked = {}
    /\ everLapsed = {}

\* ---------------------------------------------------------------------------
\* Session's and Permissions' own steps (the world the composition reads)
\* ---------------------------------------------------------------------------

\* Tick: the clock moves on; a session whose expiry instant it reaches lapses, and
\* nothing is written (Session Expiry 2, 4).
Tick ==
    /\ now < MaxTime
    /\ now' = now + 1
    /\ everLapsed' = everLapsed \cup {t \in Tokens : status[t] # "none" /\ now + 1 >= exp[t]}
    /\ last' = NoLast
    /\ UNCHANGED <<status, prin, exp, grants, fly, everRevoked>>

\* Issue: Session issues a session for a principal under a token never issued, expiring
\* a window from now (Session Operation 1, 9, 10; Invariant 7.2).
Issue(t, p) ==
    /\ status[t] = "none"
    /\ status' = [status EXCEPT ![t] = "active"]
    /\ prin' = [prin EXCEPT ![t] = p]
    /\ exp' = [exp EXCEPT ![t] = now + Window]
    /\ last' = NoLast
    /\ UNCHANGED <<now, grants, fly, everRevoked, everLapsed>>

\* Revoke: Session revokes an active session, lapsed or not (Session Operation 27, 28),
\* by its own revoke, a logout or Login's cascade (the page's revoked example).
Revoke(t) ==
    /\ status[t] = "active"
    /\ status' = [status EXCEPT ![t] = "revoked"]
    /\ everRevoked' = everRevoked \cup {t}
    /\ last' = NoLast
    /\ UNCHANGED <<now, prin, exp, grants, fly, everLapsed>>

\* GrantP: Permissions records an active grant for a pair.
GrantP(p, s) ==
    /\ <<p, s>> \notin grants
    /\ grants' = grants \cup {<<p, s>>}
    /\ last' = NoLast
    /\ UNCHANGED <<now, status, prin, exp, fly, everRevoked, everLapsed>>

\* RevokeP: Permissions revokes a pair's grant.
RevokeP(p, s) ==
    /\ <<p, s>> \in grants
    /\ grants' = grants \ {<<p, s>>}
    /\ last' = NoLast
    /\ UNCHANGED <<now, status, prin, exp, fly, everRevoked, everLapsed>>

\* ---------------------------------------------------------------------------
\* The composition: [Check Permitted], two steps
\* ---------------------------------------------------------------------------

\* Validate: a call presenting a token and an action scope asks Session's validate with
\* the token (Action wiring 3, 13) and holds the answer it receives (Concurrency 1); a
\* valid answer carries the session's principal (Term valid answer). It writes nothing
\* (Action wiring 15).
Validate(t, s) ==
    /\ fly = NoFly
    /\ fly' = [tok |-> t, scp |-> s, vans |-> VAnswer(t),
               vprin |-> IF VAnswer(t) = "valid" THEN prin[t] ELSE NONE]
    /\ last' = [NoLast EXCEPT !.op = "validate", !.tok = t]
    /\ UNCHANGED <<now, status, prin, exp, grants, everRevoked, everLapsed>>

\* Permit: the gate admitted (a valid answer), so Permissions' permitted is called with
\* the valid answer's principal and the action scope (Action wiring 5, 6; Wiring
\* decision 1) and its answer is the call's, unchanged (Action wiring 10, 11), whatever
\* happened to the session since (Concurrency 2).
Permit(c) ==
    /\ fly # NoFly
    /\ fly.vans = "valid"
    /\ last' = [op |-> "answer", tok |-> fly.tok, subj |-> c,   \* BUG: a caller-supplied subject
                ans |-> IF <<c, fly.scp>> \in grants THEN "permitted" ELSE "denied",
                why |-> NONE]
    /\ fly' = NoFly
    /\ UNCHANGED <<now, status, prin, exp, grants, everRevoked, everLapsed>>

\* Reject: the gate gave an invalid answer, so the call answers session-invalid naming
\* its reason and Permissions is not called (Action wiring 9; Invariant 1.1).
Reject ==
    /\ fly # NoFly
    /\ fly.vans # "valid"
    /\ last' = [op |-> "answer", tok |-> fly.tok, subj |-> NONE,
                ans |-> "session-invalid", why |-> fly.vans]
    /\ fly' = NoFly
    /\ UNCHANGED <<now, status, prin, exp, grants, everRevoked, everLapsed>>

\* Next: the world moving (the clock, Session's issue and revoke, Permissions' grant and
\* revoke) or a step of a call.
Next ==
    \/ Tick
    \/ \E t \in Tokens, p \in Principals : Issue(t, p)
    \/ \E t \in Tokens : Revoke(t)
    \/ \E p \in Principals, s \in Scopes : GrantP(p, s)
    \/ \E p \in Principals, s \in Scopes : RevokeP(p, s)
    \/ \E t \in Tokens, s \in Scopes : Validate(t, s)
    \/ \E c \in Principals : Permit(c)
    \/ Reject

\* Spec: every behaviour from Init by Next steps.
Spec == Init /\ [][Next]_vars

\* ---------------------------------------------------------------------------
\* Checks (the verification surface). Each spells the page's condition itself, so a
\* defect in an action's own reading of it shows.
\* ---------------------------------------------------------------------------

\* GateStep: a call's first step: a call comes into flight.
GateStep == fly = NoFly /\ fly' # NoFly

\* AnswerStep: a call's last step: the call in flight answers.
AnswerStep == fly # NoFly /\ fly' = NoFly

\* CallStep: either step of a call.
CallStep == GateStep \/ AnswerStep

\* Inv1_1_GateBeforePermitted: a step that calls Permissions' permitted (a subject
\* reaches it) belongs to a call whose validate gave a valid answer (Invariant 1.1,
\* Wiring decision 1).
Inv1_1_GateBeforePermitted ==
    [][(AnswerStep /\ last'.subj # NONE) => fly.vans = "valid"]_vars

\* Inv2_1_PrincipalBinding: the subject permitted receives is the principal Session
\* issued the presented token's session for, never another (Invariant 2.1, Action
\* wiring 5, 8).
Inv2_1_PrincipalBinding ==
    [][(AnswerStep /\ last'.subj # NONE) => last'.subj = prin[fly.tok]]_vars

\* AW14_GateReflectsCurrentStatus: the answer a call holds at its gate is the one
\* Session's records give at that step — not-known for a token never issued, revoked for
\* a revoked session, expired once the clock reaches its expiry instant, valid otherwise —
\* so validate was asked on this call and no prior call's answer stands in (Action
\* wiring 13, 14; Concurrency 1).
AW14_GateReflectsCurrentStatus ==
    [][GateStep =>
          fly'.vans = (CASE status[fly'.tok] = "none"    -> "not-known"
                         [] status[fly'.tok] = "revoked" -> "revoked"
                         [] now >= exp[fly'.tok]         -> "expired"
                         [] OTHER                        -> "valid")]_vars

\* Con2_NoLaterRevocationDetected: a call whose gate admitted answers what Permissions'
\* records give for the session's principal and the scope, permitted or denied, even
\* where the session was revoked after the gate: the composition answers from the
\* validate answer it received and detects no later revocation (Concurrency 1, 2;
\* Action wiring 10).
Con2_NoLaterRevocationDetected ==
    [][(AnswerStep /\ fly.vans = "valid") =>
          last'.ans = (IF <<fly.vprin, fly.scp>> \in grants THEN "permitted" ELSE "denied")]_vars

\* AW15_CallDoesNotWrite: neither step of a call changes Session's or Permissions'
\* records (Action wiring 15; Composition state 1; Non-goal 1 to 4).
AW15_CallDoesNotWrite ==
    [][CallStep => UNCHANGED records]_vars

\* Composes7_RevocationTerminal: once Session has revoked a session, every later gate
\* presenting its token gives revoked: a revoked session buys no further authorization
\* (Composes 7, Session Composition note 4; the disputed-access scenario).
Composes7_RevocationTerminal ==
    [][(GateStep /\ fly'.tok \in everRevoked) => fly'.vans = "revoked"]_vars

\* Composes7_ExpiryTerminal: once the clock has reached a session's expiry instant, no
\* later gate presenting its token gives valid (Composes 7, Session Composition note 4;
\* the regulator-audit scenario).
Composes7_ExpiryTerminal ==
    [][(GateStep /\ fly'.tok \in everLapsed) => fly'.vans \in {"expired", "revoked"}]_vars

====
