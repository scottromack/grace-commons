---- MODULE permissions-buggy-revoke-restamps-grant ----
\* DELIBERATELY WRONG twin of permissions.tla (unit: `atoms/permissions.md formal layer`).
\*
\* INJECTED DEFECT: [Revoke] stamps the injected now into the grant instant as well as the revocation
\* instant, as an updated-at column would (Invariant 1.1, 1.2; State 4).
\*
\* BREAKS: Inv1_1_GrantFixed.
\* Everything else is permissions.tla as written; read its comments there.

EXTENDS Integers, FiniteSets

CONSTANTS
    Subjects,   \* the subject references a call may name
    Scopes,     \* the action scopes a call may name
    GrantIds,   \* the grant ids the host may allocate, and a caller present to [Revoke]
    MaxTime,    \* the last instant the clock reaches in the model
    MaxRecs     \* how many grants the model's database holds room for

\* NONE: the value of a string field not yet written.
NONE == "none"

\* Slots: the places a grant can occupy, in the order grants are recorded.
Slots == 1..MaxRecs

\* NoCall: the record of the last call before any call is made, and the shape
\* of every such record: the action, the pair or the grant id it named, the
\* slot it reached, what it answered, and the grant ids a [Read] answered.
NoCall == [op |-> "none", sub |-> NONE, sc |-> NONE, gid |-> NONE, slot |-> 0, ans |-> "none", ids |-> {}]

\* ---------------------------------------------------------------------------
\* State
\* ---------------------------------------------------------------------------

VARIABLES
    now,      \* the host's clock reading, injected at the seam
    n,        \* the next slot a recorded grant takes
    used,     \* the grant ids the host has supplied to calls so far
    gid,      \* slot -> grant id
    subj,     \* slot -> subject reference
    scope,    \* slot -> action scope
    grantAt,  \* slot -> grant instant (0: none)
    status,   \* slot -> status ("none": no grant)
    revAt,    \* slot -> revocation instant (0: none)
    actAt,    \* slot -> the instants at whose end the grant stood in active (the model's own note)
    last      \* the last call made and what it answered (NoCall's shape)

\* vars: every variable; a step that changes none of them is a stutter.
vars == <<now, n, used, gid, subj, scope, grantAt, status, revAt, actAt, last>>

\* records: every variable that holds a grant's fields: what the database holds.
records == <<n, gid, subj, scope, grantAt, status, revAt>>

\* Recorded: the slot holds a grant.
Recorded(s) == status[s] # "none"

\* RecordedSet: the slots holding a grant: the grant set (Term grant set).
RecordedSet == {s \in Slots : Recorded(s)}

\* Names: some recorded grant carries the grant id.
Names(g) == \E s \in Slots : Recorded(s) /\ gid[s] = g

\* ActiveMatch: an active grant matches the pair, subject reference and action
\* scope both compared exactly (Term pair, Term active grant set).
ActiveMatch(su, sc) == \E s \in Slots : status[s] = "active" /\ subj[s] = su /\ scope[s] = sc

\* Live: the grant is live at the instant: granted at or before it, and either
\* not revoked or revoked after it (Term live at an instant).
Live(s, t) == grantAt[s] <= t /\ (revAt[s] = 0 \/ revAt[s] > t)

\* TypeOK: each variable holds a value of its kind (the model's typing, not a
\* rule of the page).
TypeOK ==
    /\ now \in 1..MaxTime
    /\ n \in 1..(MaxRecs + 1)
    /\ used \subseteq GrantIds
    /\ gid \in [Slots -> GrantIds \cup {NONE}]
    /\ subj \in [Slots -> Subjects \cup {NONE}]
    /\ scope \in [Slots -> Scopes \cup {NONE}]
    /\ grantAt \in [Slots -> Nat]
    /\ status \in [Slots -> {"none", "active", "revoked"}]
    /\ revAt \in [Slots -> Nat]
    /\ actAt \in [Slots -> SUBSET (1..MaxTime)]

\* Init: no grant; no id supplied; the clock at its first instant.
Init ==
    /\ now = 1
    /\ n = 1
    /\ used = {}
    /\ gid = [s \in Slots |-> NONE]
    /\ subj = [s \in Slots |-> NONE]
    /\ scope = [s \in Slots |-> NONE]
    /\ grantAt = [s \in Slots |-> 0]
    /\ status = [s \in Slots |-> "none"]
    /\ revAt = [s \in Slots |-> 0]
    /\ actAt = [s \in Slots |-> {}]
    /\ last = NoCall

\* ---------------------------------------------------------------------------
\* Actions
\* ---------------------------------------------------------------------------

\* Tick: the host's clock moves on by a second; the model notes which grants
\* stood in active at the end of the instant it leaves. No record is written.
Tick ==
    /\ now < MaxTime
    /\ now' = now + 1
    /\ actAt' = [s \in Slots |-> IF status[s] = "active" THEN actAt[s] \cup {now} ELSE actAt[s]]
    /\ last' = [NoCall EXCEPT !.op = "tick"]
    /\ UNCHANGED <<n, used, gid, subj, scope, grantAt, status, revAt>>

\* GrantAdmitted: [Grant] of a pair, the database accepting the write, records
\* one grant (Operation 1) carrying the grant id the host allocated (Identity
\* 2, Invariant 4.1), the pair, and the injected now as its grant instant
\* (State 4), stands it in active (Operation 2), and answers the grant id
\* (Operation 3). A pair an active grant already covers is no ground for
\* refusal (Operation 6).
GrantAdmitted(su, sc, g) ==
    /\ n <= MaxRecs
    /\ g \notin used
    /\ used' = used \cup {g}
    /\ gid' = [gid EXCEPT ![n] = g]
    /\ subj' = [subj EXCEPT ![n] = su]
    /\ scope' = [scope EXCEPT ![n] = sc]
    /\ grantAt' = [grantAt EXCEPT ![n] = now]
    /\ status' = [status EXCEPT ![n] = "active"]
    /\ n' = n + 1
    /\ last' = [op |-> "grant", sub |-> su, sc |-> sc, gid |-> g, slot |-> n, ans |-> "granted", ids |-> {}]
    /\ UNCHANGED <<now, revAt, actAt>>

\* GrantStorageFailure: [Grant] whose write the database refuses answers
\* storage-failure (Operation 7) and records nothing; the id the host
\* allocated for the call is spent all the same.
GrantStorageFailure(su, sc, g) ==
    /\ g \notin used
    /\ used' = used \cup {g}
    /\ last' = [op |-> "grant", sub |-> su, sc |-> sc, gid |-> NONE, slot |-> 0, ans |-> "storage-failure", ids |-> {}]
    /\ UNCHANGED <<now, n, gid, subj, scope, grantAt, status, revAt, actAt>>

\* RevokeOk: [Revoke] of an id naming an active grant, the database accepting
\* the write, stands that grant, and no other, in revoked (Operation 11,
\* Identity 8), stamps the injected now as its revocation instant (State 5),
\* and answers ok.
RevokeOk(g) ==
    \E s \in Slots :
        /\ Recorded(s)
        /\ gid[s] = g
        /\ status[s] = "active"
        /\ status' = [status EXCEPT ![s] = "revoked"]
        /\ revAt' = [revAt EXCEPT ![s] = now]
        /\ grantAt' = [grantAt EXCEPT ![s] = now]   \* BUG: the grant instant restamped
        /\ last' = [op |-> "revoke", sub |-> NONE, sc |-> NONE, gid |-> g, slot |-> s, ans |-> "ok", ids |-> {}]
        /\ UNCHANGED <<now, n, used, gid, subj, scope, actAt>>

\* RevokeNotActive: [Revoke] of an id naming a revoked grant answers
\* not-active and writes nothing (Operation 10).
RevokeNotActive(g) ==
    \E s \in Slots :
        /\ Recorded(s)
        /\ gid[s] = g
        /\ status[s] = "revoked"
        /\ last' = [op |-> "revoke", sub |-> NONE, sc |-> NONE, gid |-> g, slot |-> s, ans |-> "not-active", ids |-> {}]
        /\ UNCHANGED <<now, n, used, gid, subj, scope, grantAt, status, revAt, actAt>>

\* RevokeNotKnown: [Revoke] of an id no grant carries answers not-known and
\* writes nothing (Operation 9).
RevokeNotKnown(g) ==
    /\ ~Names(g)
    /\ last' = [op |-> "revoke", sub |-> NONE, sc |-> NONE, gid |-> g, slot |-> 0, ans |-> "not-known", ids |-> {}]
    /\ UNCHANGED <<now, n, used, gid, subj, scope, grantAt, status, revAt, actAt>>

\* RevokeStorageFailure: [Revoke] of an id naming an active grant whose write
\* the database refuses answers storage-failure (Operation 13) and writes
\* nothing, so the grant stays active (Operation 15).
RevokeStorageFailure(g) ==
    \E s \in Slots :
        /\ Recorded(s)
        /\ gid[s] = g
        /\ status[s] = "active"
        /\ last' = [op |-> "revoke", sub |-> NONE, sc |-> NONE, gid |-> g, slot |-> s, ans |-> "storage-failure", ids |-> {}]
        /\ UNCHANGED <<now, n, used, gid, subj, scope, grantAt, status, revAt, actAt>>

\* CheckCall: [Check] of a pair answers permitted where an active grant
\* matches it and denied otherwise (Operation 16 to 18), resting on the active
\* grant set alone (Invariant 6.1), and writes nothing (Operation 20).
CheckCall(su, sc) ==
    /\ last' = [op |-> "check", sub |-> su, sc |-> sc, gid |-> NONE, slot |-> 0,
                ans |-> IF ActiveMatch(su, sc) THEN "permitted" ELSE "denied", ids |-> {}]
    /\ UNCHANGED <<now, n, used, gid, subj, scope, grantAt, status, revAt, actAt>>

\* ReadCall: [Read] answers every grant, active and revoked (Operation 26), here
\* by its grant id, and writes nothing (Operation 28).
ReadCall ==
    /\ last' = [op |-> "read", sub |-> NONE, sc |-> NONE, gid |-> NONE, slot |-> 0, ans |-> "every",
                ids |-> {gid[s] : s \in RecordedSet}]
    /\ UNCHANGED <<now, n, used, gid, subj, scope, grantAt, status, revAt, actAt>>

\* Next: the clock moving, or any call: a [Grant] admitted or refused by the
\* database, a [Revoke] of any id with each of its answers, a [Check] of any
\* pair, or a [Read].
Next ==
    \/ Tick
    \/ \E su \in Subjects, sc \in Scopes, g \in GrantIds : GrantAdmitted(su, sc, g)
    \/ \E su \in Subjects, sc \in Scopes, g \in GrantIds : GrantStorageFailure(su, sc, g)
    \/ \E g \in GrantIds : RevokeOk(g)
    \/ \E g \in GrantIds : RevokeNotActive(g)
    \/ \E g \in GrantIds : RevokeNotKnown(g)
    \/ \E g \in GrantIds : RevokeStorageFailure(g)
    \/ \E su \in Subjects, sc \in Scopes : CheckCall(su, sc)
    \/ ReadCall

\* Spec: every behaviour from Init by Next steps.
Spec == Init /\ [][Next]_vars

\* ---------------------------------------------------------------------------
\* Checks (the verification surface)
\* ---------------------------------------------------------------------------

\* Inv1_1_GrantFixed: no step changes a recorded grant's grant id, subject
\* reference, action scope or grant instant, so the grant instant is stamped
\* once (Invariant 1.1, Invariant 1.2, Check 1.3).
Inv1_1_GrantFixed ==
    [][\A s \in Slots : Recorded(s) =>
          /\ gid'[s] = gid[s]
          /\ subj'[s] = subj[s]
          /\ scope'[s] = scope[s]
          /\ grantAt'[s] = grantAt[s]]_vars

\* Inv2_2_NoReactivation: no step moves a revoked grant back to active:
\* revocation is terminal (Invariant 2.2, Check 4.1).
Inv2_2_NoReactivation ==
    [][\A s \in Slots : status[s] = "revoked" => status'[s] = "revoked"]_vars

\* Inv4_1_GrantSetsId: a [Grant] answered with a grant id leaves the grant it
\* recorded carrying that id, an id the host allocated (Invariant 4.1,
\* Operation 3).
Inv4_1_GrantSetsId ==
    [][(last'.op = "grant" /\ last'.ans = "granted")
           => (last'.gid \in GrantIds /\ \A s \in Slots : s = last'.slot => gid'[s] = last'.gid)]_vars

\* Inv4_2_IdFixed: no step changes a recorded grant's grant id, the handle
\* [Revoke] takes (Invariant 4.2).
Inv4_2_IdFixed ==
    [][\A s \in Slots : Recorded(s) => gid'[s] = gid[s]]_vars

\* Inv5_1_NoIdShared: no two grants in the grant set share a grant id, revoked
\* grants included (Invariant 5.1, Check 1.4).
Inv5_1_NoIdShared ==
    \A s1, s2 \in Slots : (Recorded(s1) /\ Recorded(s2) /\ s1 # s2) => gid[s1] # gid[s2]

\* Inv9_1_RevokedNotBeforeGranted: no revocation instant precedes its grant's
\* grant instant (Invariant 9.1, Check 1.5).
Inv9_1_RevokedNotBeforeGranted ==
    \A s \in Slots : (Recorded(s) /\ revAt[s] # 0) => revAt[s] >= grantAt[s]

\* Inv9_2_ActiveOnlyIfLive: a grant stood in active at the end of an instant
\* only if it was live at that instant, and stands in active now only if it is
\* live now (Invariant 9.2; see THE WORLD AROUND THE RECORDS for the reading).
Inv9_2_ActiveOnlyIfLive ==
    \A s \in Slots : Recorded(s) =>
        /\ \A t \in actAt[s] : Live(s, t)
        /\ (status[s] = "active" => Live(s, now))

\* Check2_1_ReconstructActive: for every instant the clock has passed, the
\* grants that stood in active at its end are exactly the grants live at it,
\* so an auditor reconstructs them from grant instant and revocation instant
\* alone (Check 2.1).
Check2_1_ReconstructActive ==
    \A s \in Slots : \A t \in 1..(now - 1) :
        Recorded(s) => ((t \in actAt[s]) <=> Live(s, t))

\* Inv10_1_NothingDeleted: no step removes a grant from the grant set: a slot
\* holding a grant holds one after every step (Invariant 10.1, Check 5.1).
Inv10_1_NothingDeleted ==
    [][\A s \in Slots : Recorded(s) => status'[s] # "none"]_vars

\* Op1_OneGrantPerCall: a [Grant] answered with a grant id adds exactly one
\* grant to the grant set (Operation 1).
Op1_OneGrantPerCall ==
    [][(last'.op = "grant" /\ last'.ans = "granted")
           => Cardinality({s \in Slots : status'[s] # "none"}) = Cardinality(RecordedSet) + 1]_vars

\* Op6_CoveredPairGranted: a [Grant] of a pair an active grant already covers
\* answers a grant id, or storage-failure where the database refuses the write,
\* never a refusal on the ground of the cover (Operation 6, Identity 7).
Op6_CoveredPairGranted ==
    [][(last'.op = "grant" /\ ActiveMatch(last'.sub, last'.sc))
           => last'.ans \in {"granted", "storage-failure"}]_vars

\* Op7_FailedGrantWritesNothing: a [Grant] answered storage-failure changes no
\* grant record (Operation 7).
Op7_FailedGrantWritesNothing ==
    [][(last'.op = "grant" /\ last'.ans = "storage-failure") => UNCHANGED records]_vars

\* Id8_RevokeReachesOne: a [Revoke] answered ok changes the status of no grant
\* but the one its id names (Identity 8, Identity 6: never every grant of a
\* pair).
Id8_RevokeReachesOne ==
    [][(last'.op = "revoke" /\ last'.ans = "ok")
           => \A s \in Slots : s # last'.slot => status'[s] = status[s]]_vars

\* Op9_UnknownNotKnown: a [Revoke] of an id no grant carries answers not-known
\* (Operation 9).
Op9_UnknownNotKnown ==
    [][(last'.op = "revoke" /\ ~Names(last'.gid)) => last'.ans = "not-known"]_vars

\* Op10_RevokedNotActive: a [Revoke] of an id naming a revoked grant answers
\* not-active, the answer a retried revoke that landed gets (Operation 10,
\* Revoke persistence 3).
Op10_RevokedNotActive ==
    [][(last'.op = "revoke" /\ \E s \in Slots : Recorded(s) /\ gid[s] = last'.gid /\ status[s] = "revoked")
           => last'.ans = "not-active"]_vars

\* Op11_RevokeStandsRevoked: a [Revoke] answered ok leaves the grant its id
\* names in revoked (Operation 11).
Op11_RevokeStandsRevoked ==
    [][(last'.op = "revoke" /\ last'.ans = "ok")
           => \A s \in Slots : s = last'.slot => status'[s] = "revoked"]_vars

\* Op15_FailedRevokeKeepsActive: a [Revoke] answered storage-failure leaves the
\* grant in active, so a caller reading the answer as an active grant reads it
\* right (Operation 15, Operation 13).
Op15_FailedRevokeKeepsActive ==
    [][(last'.op = "revoke" /\ last'.ans = "storage-failure")
           => \A s \in Slots : s = last'.slot => status'[s] = "active"]_vars

\* Op17_PermittedOnlyIfActiveMatch: a [Check] answered permitted was made where
\* an active grant matched the pair, subject reference and action scope both
\* exactly (Operation 17, 21, 22; Invariant 3.2; Check 3.2).
Op17_PermittedOnlyIfActiveMatch ==
    [][(last'.op = "check" /\ last'.ans = "permitted") => ActiveMatch(last'.sub, last'.sc)]_vars

\* Inv7_1_DeniedOnlyIfNoActiveMatch: a [Check] answered denied was made where
\* no active grant matched the pair (Invariant 7.1, Check 3.3).
Inv7_1_DeniedOnlyIfNoActiveMatch ==
    [][(last'.op = "check" /\ last'.ans = "denied") => ~ActiveMatch(last'.sub, last'.sc)]_vars

\* Op20_CheckWritesNothing: a [Check] step changes no grant record (Operation 20).
Op20_CheckWritesNothing ==
    [][last'.op = "check" => UNCHANGED records]_vars

\* Op26_ReadAnswersEvery: a [Read] answers the grant id of every grant in the
\* grant set, active and revoked, and no other (Operation 26, Check 1.1).
Op26_ReadAnswersEvery ==
    [][last'.op = "read" => last'.ids = {gid[s] : s \in RecordedSet}]_vars

\* Op28_ReadWritesNothing: a [Read] step changes no grant record (Operation 28).
Op28_ReadWritesNothing ==
    [][last'.op = "read" => UNCHANGED records]_vars

====
