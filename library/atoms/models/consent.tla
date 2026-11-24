---- MODULE consent ----
\* Grace Commons — Consent atom (atoms/consent.md).
\* Grounded on Final Critique 21, 2026-11-05 at 4f85e1c — TLA+ layer authored 2026-11-11.
\* Derived validator; the English spec is the single source of truth. On any
\* disagreement, diagnose per the entry *The conflict protocol* in pressure-testing.md.
\*
\* PURPOSE
\* Check what happens across steps: the consent records [Grant] and [Revoke]
\* write over a sequence of calls while the clock moves, what [Check] and
\* [Read] leave, and how a record's derived state, and a [Check] answer for a
\* fixed at time, move from one state to the next. What one state of the
\* records must carry and what one [Check] or [Read] answers over it (State 3
\* to 9, Expiry 5, Invariant 2, 4 to 7, 10.1, 10.2, Instance 2, Operation 2,
\* 26) is the Alloy model's, consent.als; the two models spell the page's terms
\* alike (withdrawn, elapsed, the candidate record, granted, revoked, expired).
\*
\* RULES CHECKED (named by the page's own labels)
\*   Invariant 1.1 — a recorded record's grant fields never change    (Inv1_1_GrantFieldsFixed)
\*   Invariant 1.2 — an expiry instant [Grant] did not record never
\*                   appears later                                    (Inv1_2_NoGrantFieldAppears)
\*   Invariant 3.1 — a record standing in revoked at now stands in
\*                   revoked at every later now                       (Inv3_1_RevokedStaysRevoked)
\*   Invariant 3.2 — a record standing in expired at now stands in
\*                   expired at every later now                       (Inv3_2_ExpiredStaysExpired)
\*   Invariant 8.1 — no record is removed                             (Inv8_1_NeverRemoved)
\*   Invariant 9.1 — [Revoke] changes no grant field                  (Inv9_1_RevokeKeepsGrantFields)
\*   Invariant 10.3 — a later write leaves every [Check] answer for
\*                   the at time as it was (Check 8.2, 8.3)           (Inv10_3_LaterWriteKeepsAnswer)
\*   Operation 1   — an admitted [Grant] records exactly one new
\*                   record, a second [Grant] for the pair included
\*                   (Concurrency 4, Identity 6, Non-goal 1)          (Op1_OneRecordPerGrant)
\*   Operation 18  — a withdrawn record's revocation instant never
\*                   changes                                          (Op18_WithdrawalKept)
\*   Operation 36  — [Check] writes nothing                           (Op36_CheckWritesNothing)
\*   Operation 49  — [Read] writes nothing                            (Op49_ReadWritesNothing)
\*
\* WHAT THE MODEL TAKES FROM OUTSIDE THE PAGE (its inputs; no ASSUME, no CONSTRAINT)
\* - The clock (Term now; Capability requirement 1): one reading per call, the
\*   variable `now`, which moves forward a step at a time (Tick). That the
\*   readings never go back is the deployment's (Execution Contract Logic
\*   confinement 7, to which the page's deleted Clock semantics 1 to 4 hand
\*   it); Invariant 3.1 and 3.2, read at now, rest on it.
\* - The host: each [Grant] gets the next consent id no record carries
\*   (Identity 2; Execution Contract Logic confinement 16); the id is the slot.
\* - The database (Execution Contract Database 1, 2): each call's guards and
\*   writes are one atomic step, so two calls, concurrent ones included, are
\*   two steps in some order.
\*
\* BOUNDS (the .cfg)
\* One subject reference and one purpose (one pair, so every record is a
\* candidate for the same [Check]: which pair a record carries is the Alloy
\* model's), three consent ids, the clock 0..3. A [Grant] carries no expiry
\* instant or one after now; a [Revoke] carries no revocation instant (blank:
\* now) or any instant; a [Check] any at time or none.
\*
\* NOT MODELED HERE
\* - The refusals: a refused call writes nothing (Execution Contract Read 4),
\*   so it is no step. What a [Grant] or [Revoke] answers, and the guards on
\*   blank, over-cap or malformed inputs (Operation 4 to 9, 15, 22, 23, 66 to
\*   77), which guard only the Alloy model's checks.
\* - The granting actor, the metadata, the revoking actor and the revocation
\*   reason: no check here reads them; the grant fields here are the subject
\*   reference, the purpose, the grant instant and the expiry instant.
\* - The stored state's value on a step that writes nothing: Operation 36 and
\*   49 read every field of every record.
\* - [Read]'s filters and order (Operation 47 to 65).

EXTENDS Integers, FiniteSets

CONSTANTS
    MaxIds,     \* how many consent ids the host allocates in the model
    Subjects,   \* the subject references a [Grant] or [Check] may carry (none blank)
    Purposes,   \* the purposes a [Grant] or [Check] may carry (none blank)
    MaxTime     \* the last clock reading

\* Ids: the consent ids the host may allocate, in the order it allocates them.
Ids == 1..MaxIds

\* Instants: the clock readings, and the instants a call may carry.
Instants == 0..MaxTime

\* NoInstant: the value of an instant a record does not carry, or a call
\* leaves blank.
NoInstant == -1

\* None: a consent id no record carries, with every field of a record unset.
None == [subj |-> "none", purp |-> "none", grantAt |-> NoInstant, exp |-> NoInstant,
         col |-> "none", revAt |-> NoInstant]

\* ---------------------------------------------------------------------------
\* State
\* ---------------------------------------------------------------------------

VARIABLES
    rec,     \* consent id -> the consent record carrying it, or None
    nextId,  \* the next consent id the host will allocate
    now,     \* the clock reading the next call carries
    last     \* the last step: its action and the consent id it wrote, or 0

\* vars: every variable; a step that changes none of them is a stutter.
vars == <<rec, nextId, now, last>>

\* TypeOK: each variable holds a value of its kind (the model's typing, not a
\* rule of the page).
TypeOK ==
    /\ \A i \in Ids : rec[i].grantAt \in Instants \cup {NoInstant}
    /\ \A i \in Ids : rec[i].exp \in Instants \cup {NoInstant}
    /\ \A i \in Ids : rec[i].revAt \in Instants \cup {NoInstant}
    /\ \A i \in Ids : rec[i].col \in {"none", "granted", "revoked", "expired"}
    /\ nextId \in 1..(MaxIds + 1)
    /\ now \in Instants
    /\ last.op \in {"none", "tick", "grant", "revoke", "check", "read"}

\* ---------------------------------------------------------------------------
\* Derived (never stored)
\* ---------------------------------------------------------------------------

\* Recorded: a record carries the consent id.
Recorded(i) == rec[i] # None

\* Withdrawn: the record carries a revocation instant the evaluation instant e
\* does not precede (Term withdrawn).
Withdrawn(r, e) == r.revAt # NoInstant /\ r.revAt <= e

\* Elapsed: the record carries an expiry instant the evaluation instant e does
\* not precede (Term elapsed).
Elapsed(r, e) == r.exp # NoInstant /\ r.exp <= e

\* StandsAt: the state the record stands in at e: revoked where withdrawn,
\* expired where elapsed and not withdrawn, granted where neither (Expiry 1 to
\* 4, which the Alloy model checks are exactly one, Invariant 2.1).
StandsAt(r, e) ==
    IF Withdrawn(r, e) THEN "revoked"
    ELSE IF Elapsed(r, e) THEN "expired"
    ELSE "granted"

\* PairBy: in the records rc, the consent ids of the records carrying subject s
\* and purpose p whose grant instant the at time t does not precede.
PairBy(rc, s, p, t) ==
    {i \in Ids : rc[i] # None /\ rc[i].subj = s /\ rc[i].purp = p /\ rc[i].grantAt <= t}

\* Candidate: in the records rc, the candidate record's consent id (Term
\* candidate record): the latest grant instant in PairBy, a tie resolving to
\* the greatest consent id (Invariant 10.2; ids compare as numbers here, as
\* their spellings do in code point order, Execution Contract Logic
\* confinement 10).
Candidate(rc, s, p, t) ==
    CHOOSE i \in PairBy(rc, s, p, t) :
        \A j \in PairBy(rc, s, p, t) :
            \/ rc[j].grantAt < rc[i].grantAt
            \/ (rc[j].grantAt = rc[i].grantAt /\ j <= i)

\* AnswerIn: what [Check] for subject s, purpose p and at time t answers over
\* the records rc: not-known where no candidate exists (Operation 40), else the
\* state the candidate stands in at t (Operation 41 to 45).
AnswerIn(rc, s, p, t) ==
    IF PairBy(rc, s, p, t) = {} THEN "not-known"
    ELSE StandsAt(rc[Candidate(rc, s, p, t)], t)

\* GrantFields: the grant fields of a record this model keeps (Term grant
\* field; see NOT MODELED HERE).
GrantFields(r) == <<r.subj, r.purp, r.grantAt, r.exp>>

\* ---------------------------------------------------------------------------
\* Actions
\* ---------------------------------------------------------------------------

\* Init: no record; the clock at 0.
Init ==
    /\ rec = [i \in Ids |-> None]
    /\ nextId = 1
    /\ now = 0
    /\ last = [op |-> "none", id |-> 0]

\* Tick: the clock moves forward one step; nothing is written, so a record
\* runs out by its expiry instant alone (Expiry 5, 6: no action, no poll).
Tick ==
    /\ now < MaxTime
    /\ now' = now + 1
    /\ last' = [op |-> "tick", id |-> 0]
    /\ UNCHANGED <<rec, nextId>>

\* Grant: an admitted [Grant] for subject s and purpose p carrying expiry
\* instant x, no instant (blank) or one after now (Operation 8, 9), records
\* exactly one record under the id the host allocates (Operation 1, 3),
\* carrying s, p, the grant instant stamped from now (Operation 10), x
\* (State 4, 6) and the stored state granted (Operation 2).
Grant(s, p, x) ==
    /\ nextId <= MaxIds
    /\ x = NoInstant \/ x > now                                       \* Operation 8, 9
    /\ rec' = [rec EXCEPT ![nextId] =
                 [subj |-> s, purp |-> p, grantAt |-> now, exp |-> x,
                  col |-> "granted", revAt |-> NoInstant]]
    /\ nextId' = nextId + 1
    /\ last' = [op |-> "grant", id |-> nextId]
    /\ UNCHANGED now

\* Revoke: an admitted [Revoke] of the record with consent id i, carrying
\* revocation instant y or none (blank). The record exists (Operation 16), is
\* not withdrawn (Operation 18) and not elapsed (Operation 19) at now; the
\* resolved instant, y or now where y is blank (Operation 20, Execution
\* Contract Logic confinement 12), is not after now (Operation 24) and not
\* before the grant instant (Operation 25). The record then stands in revoked
\* and carries the resolved instant (Operation 26, 29); no grant field is
\* written.
Revoke(i, y) ==
    /\ Recorded(i)                                                    \* Operation 16
    /\ ~Withdrawn(rec[i], now)                                        \* Operation 18
    /\ ~Elapsed(rec[i], now)                                          \* Operation 19
    /\ LET r == IF y = NoInstant THEN now ELSE y
       IN  /\ r <= now                                                \* Operation 24
           /\ r >= rec[i].grantAt                                     \* Operation 25
           /\ rec' = [rec EXCEPT ![i].col = "revoked", ![i].revAt = r] \* Operation 26, 29
    /\ last' = [op |-> "revoke", id |-> i]
    /\ UNCHANGED <<nextId, now>>

\* Check: [Check] for subject s, purpose p and at time y (or none: now)
\* answers AnswerIn and writes nothing (Operation 36).
Check(s, p, y) ==
    /\ last' = [op |-> "check", id |-> 0]
    /\ UNCHANGED <<rec, nextId, now>>

\* Read: [Read] answers the records, each with the state it stands in at now,
\* and writes nothing (Operation 49).
Read ==
    /\ last' = [op |-> "read", id |-> 0]
    /\ UNCHANGED <<rec, nextId, now>>

\* Next: the clock moving, or any admitted call of any arguments.
Next ==
    \/ Tick
    \/ \E s \in Subjects, p \in Purposes, x \in Instants \cup {NoInstant} : Grant(s, p, x)
    \/ \E i \in Ids, y \in Instants \cup {NoInstant} : Revoke(i, y)
    \/ \E s \in Subjects, p \in Purposes, y \in Instants \cup {NoInstant} : Check(s, p, y)
    \/ Read

\* Spec: every behaviour from Init by Next steps.
Spec == Init /\ [][Next]_vars

\* ---------------------------------------------------------------------------
\* Checks (the verification surface)
\* ---------------------------------------------------------------------------

\* Inv1_1_GrantFieldsFixed: no step changes a recorded record's subject
\* reference, purpose, grant instant or expiry instant: what a grant recorded
\* is never edited (Invariant 1.1, Check 2.3).
Inv1_1_GrantFieldsFixed ==
    [][\A i \in Ids : Recorded(i) => GrantFields(rec'[i]) = GrantFields(rec[i])]_vars

\* Inv1_2_NoGrantFieldAppears: no step gives a recorded record an expiry
\* instant its [Grant] did not record (Invariant 1.2, Check 2.3).
Inv1_2_NoGrantFieldAppears ==
    [][\A i \in Ids : (Recorded(i) /\ rec[i].exp = NoInstant) => rec'[i].exp = NoInstant]_vars

\* Inv3_1_RevokedStaysRevoked: a record standing in revoked at now stands in
\* revoked at the next step's now: withdrawn consent is not revived
\* (Invariant 3.1, Check 4.1).
Inv3_1_RevokedStaysRevoked ==
    [][\A i \in Ids : (Recorded(i) /\ StandsAt(rec[i], now) = "revoked")
                          => StandsAt(rec'[i], now') = "revoked"]_vars

\* Inv3_2_ExpiredStaysExpired: a record standing in expired at now stands in
\* expired at the next step's now: run-out consent is neither revived nor
\* turned into a withdrawal (Invariant 3.2).
Inv3_2_ExpiredStaysExpired ==
    [][\A i \in Ids : (Recorded(i) /\ StandsAt(rec[i], now) = "expired")
                          => StandsAt(rec'[i], now') = "expired"]_vars

\* Inv8_1_NeverRemoved: no step removes a record, whatever state it stands in
\* (Invariant 8.1, Check 1.1, Check 7.1).
Inv8_1_NeverRemoved ==
    [][\A i \in Ids : Recorded(i) => rec'[i] # None]_vars

\* Inv9_1_RevokeKeepsGrantFields: a [Revoke] step changes no grant field of
\* any record: a withdrawal is added to the record, never written over what
\* the grant recorded (Invariant 9.1).
Inv9_1_RevokeKeepsGrantFields ==
    [][last'.op = "revoke" => \A i \in Ids : GrantFields(rec'[i]) = GrantFields(rec[i])]_vars

\* LaterWrite: the step is a later write for at time t (Term later write): a
\* [Grant] recording a grant instant t precedes, or a [Revoke] recording a
\* revocation instant t precedes.
LaterWrite(t) ==
    \/ (last'.op = "grant" /\ rec'[last'.id].grantAt > t)
    \/ (last'.op = "revoke" /\ rec'[last'.id].revAt > t)

\* Inv10_3_LaterWriteKeepsAnswer: for every pair and every at time t, a step
\* that is a later write for t leaves [Check]'s answer for t as it was: a
\* past date's answer stands across a later grant or a later withdrawal
\* (Invariant 10.3, Check 8.2, Check 8.3).
Inv10_3_LaterWriteKeepsAnswer ==
    [][\A s \in Subjects, p \in Purposes, t \in Instants :
          LaterWrite(t) => AnswerIn(rec', s, p, t) = AnswerIn(rec, s, p, t)]_vars

\* Op1_OneRecordPerGrant: a [Grant] step adds exactly one record and changes no
\* other: a second [Grant] for one pair is a second record, never merged into
\* the first (Operation 1, Concurrency 4, Identity 6, Non-goal 1).
Op1_OneRecordPerGrant ==
    [][last'.op = "grant" =>
         /\ ~Recorded(last'.id)
         /\ rec'[last'.id] # None
         /\ \A i \in Ids \ {last'.id} : rec'[i] = rec[i]]_vars

\* Op18_WithdrawalKept: no step changes the revocation instant of a record
\* withdrawn at now: a second [Revoke] answers already-revoked and writes
\* nothing (Operation 18).
Op18_WithdrawalKept ==
    [][\A i \in Ids : Withdrawn(rec[i], now) => rec'[i].revAt = rec[i].revAt]_vars

\* Op36_CheckWritesNothing: a [Check] step changes no field of any record
\* (Operation 36).
Op36_CheckWritesNothing ==
    [][last'.op = "check" => rec' = rec]_vars

\* Op49_ReadWritesNothing: a [Read] step changes no field of any record
\* (Operation 49).
Op49_ReadWritesNothing ==
    [][last'.op = "read" => rec' = rec]_vars

====
