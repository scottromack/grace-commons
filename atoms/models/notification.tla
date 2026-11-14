---- MODULE notification ----
\* Grace Commons — Notification atom (atoms/notification.md).
\* Grounded on Final Critique 11, 2026-11-05 at 917cc95 — TLA+ layer authored 2026-11-11.
\* Derived validator; the English spec is the single source of truth. On any
\* disagreement, diagnose per the entry *The conflict protocol* in pressure-testing.md.
\*
\* PURPOSE
\* Check what happens across steps: the notification records [Create],
\* [Deliver], [Fail] and [Expire] write over a sequence of calls, what each
\* call answers, what a refused call leaves, and what [Status Of] and [Pending
\* For] read. What one state of the records must carry (State 1 to 6, Invariant
\* 3 and 4: one status, the terminal stamp that status carries and no other)
\* is the Alloy model's, notification.als; the two models spell the page's
\* terms alike (notification, notification id, recipient reference, payload,
\* creation instant, status, delivery instant, failure instant, lapse instant).
\*
\* RULES CHECKED (named by the page's own labels)
\*   Invariant 1.1 — id, recipient, payload, creation instant never change (Inv1_1_RecordedFieldsKept)
\*   Invariant 1.2 — a landed terminal stamp never changes          (Inv1_2_LandedStampKept)
\*   Invariant 2.2 — no status moves back to pending                 (Inv2_2_NoReturnToPending)
\*   Invariant 2.3 — no status moves between two terminal statuses  (Inv2_3_NoMoveBetweenTerminals)
\*   Invariant 2.4 — read as pending at an instant only if pending
\*                   at that instant, from the stored fields          (Inv2_4_PendingReadReconstructs)
\*   Invariant 5.1 — [Create] sets the notification id               (Inv5_1_CreateSetsId)
\*   Invariant 6.1 — no two notifications share a notification id   (Inv6_1_NoSharedId)
\*   Invariant 8.1 — delivery instant never precedes creation        (Inv8_1_DeliveryNotBeforeCreation)
\*   Invariant 8.2 — failure instant never precedes creation         (Inv8_2_FailureNotBeforeCreation)
\*   Invariant 8.3 — lapse instant never precedes creation           (Inv8_3_LapseNotBeforeCreation)
\*   Invariant 9.1 — the atom never deletes a notification record    (Inv9_1_NoRecordDeleted)
\*   Invariant 9.2 — the notification set never shrinks              (Inv9_2_SetNeverShrinks)
\*   Invariant 9.3 — [Status Of] answers a created notification for
\*                   the database's life                              (Inv9_3_StatusOfAnswersForLife)
\*   State 7       — [Create] stamps creation instant from now       (State7_CreationFromNow)
\*   State 8       — a terminal transition stamps from now           (State8_StampFromNow)
\*   Operation 1   — an admitted [Create] records exactly one        (Op1_OneRecordPerCreate)
\*   Operation 3   — [Create] answers the notification id            (Op3_CreateAnswersId)
\*   Operation 4   — a blank recipient answers invalid-request       (Op4_BlankRecipientRefused)
\*   Operation 5   — [Create] accepts an empty payload               (Op5_EmptyPayloadAccepted)
\*   Operation 7   — a refused create write answers storage-failure  (Op7_CreateStorageFailure)
\*   Operation 8   — an id naming nothing answers not-known          (Op8_UnknownIdNotKnown)
\*   Operation 9   — a notification not pending answers not-pending  (Op9_NotPendingRefused)
\*   Operation 10  — [Deliver] stands the notification in delivered  (Op10_DeliverStandsDelivered)
\*   Operation 11  — [Fail] stands the notification in failed        (Op11_FailStandsFailed)
\*   Operation 12  — [Expire] stands the notification in expired     (Op12_ExpireStandsExpired)
\*   Operation 13  — [Expire] requires no delivery attempt           (Op13_ExpireNeedsNoAttempt)
\*   Operation 15  — a refused terminal write answers storage-failure (Op15_TerminalStorageFailure)
\*   Operation 16  — a refused call leaves the notification as found (Op16_RefusedCallLeavesRecord)
\*   Operation 17  — [Status Of] answers the stored fields           (Op17_StatusOfAnswersStoredFields)
\*   Operation 18  — [Status Of] of an id naming nothing: not-known  (Op18_StatusOfUnknownNotKnown)
\*   Operation 19  — [Pending For] answers every pending notification
\*                   carrying the recipient reference                 (Op19_PendingForAnswersEvery)
\*   Operation 20  — [Pending For] answers no terminal notification  (Op20_PendingForNoTerminal)
\*   Operation 22  — [Status Of] writes nothing                      (Op22_StatusOfWritesNothing)
\*   Operation 23  — [Pending For] writes nothing                    (Op23_PendingForWritesNothing)
\*   String 6      — a recipient over the string cap: invalid-request (String6_OverCapRefused)
\*   String 8      — [Pending For] reads an over-length recipient as
\*                   matching nothing                                 (String8_OverLengthMatchesNothing)
\*   String 9      — [Pending For] reads a blank recipient as
\*                   matching nothing                                 (String9_BlankMatchesNothing)
\*
\* WHAT THE MODEL TAKES FROM OUTSIDE THE PAGE (its inputs; no ASSUME, no CONSTRAINT)
\* - The clock (Capability requirement 1; Execution Contract Logic confinement
\*   3, 7 and 11): each call reads `now` once; the deployment's clock never
\*   goes backward, which the page takes from Logic confinement 7 (its deleted
\*   Capability requirement 2), so the one clock action, Tick, only advances it.
\* - The seam (Capability requirement 9, Identity 2, Execution Contract Logic
\*   confinement 16): every [Create] call, admitted or refused, is supplied
\*   the next id of a counter, nextId, which no notification has carried.
\* - The database (Capability requirement 4, Execution Contract Database 1 to
\*   3): each call's guards and writes are one atomic step, so two calls on one
\*   notification are two steps in some order; the database may refuse any
\*   write once a call's guards pass, which the model chooses freely.
\* - Delivery attempts: the transport is the composing pattern's (State 11,
\*   Composition note 4); the model's own ledger `tried` records which
\*   notifications a [Deliver] or [Fail] call found pending, the trace an
\*   attempt that answered storage-failure leaves (Deliver persistence 1). The
\*   atom's records never read it.
\*
\* BOUNDS (the .cfg)
\* Two notification rows; two ids the seam can supply, and a third id
\* (MaxIds + 1) that no call is ever supplied, so a call can name nothing;
\* clock readings 0 and 1, so a stamp can land at the creation instant or
\* after it; the recipient "ann", the blank recipient and one over the string
\* cap; payloads "p" and the empty payload. Two notifications for one
\* recipient carrying one payload are reachable, as are a [Deliver] refused by
\* the database and then an [Expire], and a second terminal call on an ended
\* notification.
\*
\* NOT MODELED HERE
\* - A malformed notification id or recipient reference (Operation 18b, 31,
\*   32; Execution Contract Input 1): every value here is a string or an id.
\* - The delivery window (Operation 14a, 14b): the atom holds none; a
\*   composing pattern owns it (Notification Fanout Composition note 6 gives
\*   it to the deployment), so nothing here bounds when [Expire] is called.
\* - The fail-versus-expire policy (Operation 14, Capability requirement 8): a
\*   deployment's declaration; the model lets any call end a pending
\*   notification either way.
\* - The order [Pending For] answers in (Execution Contract Read 5): the
\*   answer is a set. A failed read (Execution Contract Read 1).
\* - Payload retention and its purge (Payload retention 1 to 5; Retention
\*   Window): no purge is offered, and the payload is kept as written.
\* - What one state carries (State 1 to 6, Invariant 3, 4): notification.als.

EXTENDS Integers, FiniteSets

CONSTANTS
    MaxN,        \* how many notification rows the database holds in the model
    MaxIds,      \* how many ids the seam supplies (one per [Create] call)
    MaxTime,     \* the last clock reading the model reaches
    Recipients,  \* the recipient references a call may carry, blank and over-cap included
    OverCap,     \* the recipient references longer than the string cap (String 6)
    Payloads     \* the payloads a [Create] may carry, the empty payload included

\* Slots: the database's rows, in the order they are written.
Slots == 1..MaxN

\* QueryIds: the ids a call may name: every id the seam can supply, and one
\* (MaxIds + 1) it never supplies, so a call can name no notification.
QueryIds == 1..(MaxIds + 1)

\* Blank: an instant field that carries nothing (no stamp has landed).
Blank == -1

\* NoId: a notification id field or answer that carries no id.
NoId == 0

\* Terminal: the three statuses that end a notification (Term status).
Terminal == {"delivered", "failed", "expired"}

\* TermOps: the three calls that end a notification (Term terminal transition).
TermOps == {"deliver", "fail", "expire"}

\* Refusals: the answers by which a call refuses.
Refusals == {"invalid-request", "not-known", "not-pending", "storage-failure"}

\* Valid: a recipient reference [Create] admits: not blank (Operation 4) and
\* not over the string cap (String 6).
Valid(r) == r # "" /\ r \notin OverCap

\* NoCall: the record of the last call before any call is made, and the shape
\* of every such record: the action; the id it named or was supplied; the row
\* it found or wrote (0 for none); the recipient and payload it carried; the
\* database's answer to its write ("none" where it wrote nothing); what it
\* answered; the id, the fields and the id set its answer carried; and the
\* clock reading it was made at.
NoCall == [op |-> "none", id |-> NoId, slot |-> 0, rcp |-> "", pay |-> "",
           db |-> "none", ans |-> "none", outId |-> NoId, outSt |-> "none",
           outRcp |-> "", outPay |-> "", outC |-> Blank, outD |-> Blank,
           outF |-> Blank, outL |-> Blank, ids |-> {}, at |-> Blank]

\* ---------------------------------------------------------------------------
\* State
\* ---------------------------------------------------------------------------

VARIABLES
    held,     \* row -> whether a notification record is in the database there
    nid,      \* row -> the notification id it carries (NoId before)
    rcp,      \* row -> the recipient reference it carries
    pay,      \* row -> the payload it carries
    cAt,      \* row -> its creation instant (Blank before)
    st,       \* row -> its status ("none" before)
    dAt,      \* row -> its delivery instant (Blank until one lands)
    fAt,      \* row -> its failure instant (Blank until one lands)
    lAt,      \* row -> its lapse instant (Blank until one lands)
    tried,    \* row -> whether a [Deliver] or [Fail] call has found it pending
              \* (the model's ledger; the atom's records never carry it)
    rows,     \* how many rows the database has written
    nextId,   \* the next id the seam will supply
    answered, \* the ids an admitted [Create] has answered (the model's ledger)
    now,      \* the deployment's clock reading
    last,     \* the last call made and what it answered (NoCall's shape)
    wrote     \* the rows the last step wrote

\* vars: every variable; a step that changes none of them is a stutter.
vars == <<held, nid, rcp, pay, cAt, st, dAt, fAt, lAt, tried, rows, nextId,
          answered, now, last, wrote>>

\* records: every variable that holds a notification record's fields.
records == <<held, nid, rcp, pay, cAt, st, dAt, fAt, lAt>>

\* Known: some notification in the database carries the id.
Known(i) == \E s \in Slots : held[s] /\ nid[s] = i

\* Stamp: the terminal stamp a row carries, Blank where none has landed.
Stamp(s) == IF dAt[s] # Blank THEN dAt[s]
            ELSE IF fAt[s] # Blank THEN fAt[s]
            ELSE lAt[s]

\* PendingAt: the row is pending at instant t, read from its stored fields as
\* an auditor reads it, never from its status: t does not precede the
\* creation instant, and the row carries no terminal stamp or t precedes it
\* (Term pending at an instant).
PendingAt(s, t) == cAt[s] <= t /\ (Stamp(s) = Blank \/ t < Stamp(s))

\* Pending: the rows standing in pending that carry the recipient reference.
PendingRows(r) == {s \in Slots : held[s] /\ st[s] = "pending" /\ rcp[s] = r}

\* TypeOK: each variable holds a value of its kind (the model's typing, not a
\* rule of the page).
TypeOK ==
    /\ held \in [Slots -> BOOLEAN]
    /\ nid \in [Slots -> 0..MaxIds]
    /\ rcp \in [Slots -> Recipients]
    /\ pay \in [Slots -> Payloads]
    /\ cAt \in [Slots -> {Blank} \cup 0..MaxTime]
    /\ st \in [Slots -> {"none", "pending"} \cup Terminal]
    /\ dAt \in [Slots -> {Blank} \cup 0..MaxTime]
    /\ fAt \in [Slots -> {Blank} \cup 0..MaxTime]
    /\ lAt \in [Slots -> {Blank} \cup 0..MaxTime]
    /\ tried \in [Slots -> BOOLEAN]
    /\ rows \in 0..MaxN
    /\ nextId \in 1..(MaxIds + 1)
    /\ answered \subseteq 1..MaxIds
    /\ now \in 0..MaxTime
    /\ last \in [op : {"none", "create", "status_of", "pending_for"} \cup TermOps,
                 id : 0..(MaxIds + 1), slot : 0..MaxN, rcp : Recipients, pay : Payloads,
                 db : {"none", "ok", "refused"},
                 ans : {"none", "ok", "found"} \cup Refusals,
                 outId : 0..MaxIds, outSt : {"none", "pending"} \cup Terminal,
                 outRcp : Recipients, outPay : Payloads,
                 outC : {Blank} \cup 0..MaxTime, outD : {Blank} \cup 0..MaxTime,
                 outF : {Blank} \cup 0..MaxTime, outL : {Blank} \cup 0..MaxTime,
                 ids : SUBSET (0..MaxIds), at : {Blank} \cup 0..MaxTime]
    /\ wrote \subseteq Slots

\* Init: no notification; the clock at its first reading.
Init ==
    /\ held = [s \in Slots |-> FALSE]
    /\ nid = [s \in Slots |-> NoId]
    /\ rcp = [s \in Slots |-> ""]
    /\ pay = [s \in Slots |-> ""]
    /\ cAt = [s \in Slots |-> Blank]
    /\ st = [s \in Slots |-> "none"]
    /\ dAt = [s \in Slots |-> Blank]
    /\ fAt = [s \in Slots |-> Blank]
    /\ lAt = [s \in Slots |-> Blank]
    /\ tried = [s \in Slots |-> FALSE]
    /\ rows = 0
    /\ nextId = 1
    /\ answered = {}
    /\ now = 0
    /\ last = NoCall
    /\ wrote = {}

\* ---------------------------------------------------------------------------
\* Actions
\* ---------------------------------------------------------------------------

\* Tick: the deployment's clock advances; no call is made.
Tick ==
    /\ now < MaxTime
    /\ now' = now + 1
    /\ last' = NoCall
    /\ wrote' = {}
    /\ UNCHANGED <<held, nid, rcp, pay, cAt, st, dAt, fAt, lAt, tried, rows, nextId, answered>>

\* CreateLands: [Create] with a recipient reference it admits, the database
\* accepting the write, records one notification in the next row carrying the
\* id the seam supplied, the recipient reference and payload as given, the
\* creation instant from now, standing in pending (Operation 1, 2, State 7,
\* Invariant 5.1), and answers the id (Operation 3).
CreateLands(r, p) ==
    /\ nextId <= MaxIds
    /\ rows < MaxN
    /\ Valid(r)
    /\ held' = [held EXCEPT ![rows + 1] = TRUE]
    /\ nid' = [nid EXCEPT ![rows + 1] = nextId]
    /\ rcp' = [rcp EXCEPT ![rows + 1] = r]
    /\ pay' = [pay EXCEPT ![rows + 1] = p]
    /\ cAt' = [cAt EXCEPT ![rows + 1] = now]
    /\ st' = [st EXCEPT ![rows + 1] = "pending"]
    /\ rows' = rows + 1
    /\ nextId' = nextId + 1
    /\ answered' = answered \cup {nextId}
    /\ last' = [NoCall EXCEPT !.op = "create", !.id = nextId, !.slot = rows + 1,
                              !.rcp = r, !.pay = p, !.db = "ok", !.ans = "ok",
                              !.outId = nextId, !.at = now]
    /\ wrote' = {rows + 1}
    /\ UNCHANGED <<dAt, fAt, lAt, tried, now>>

\* CreateInvalid: [Create] with a blank recipient reference or one over the
\* string cap answers invalid-request and writes nothing (Operation 4, String
\* 6); the id the seam supplied the call is spent.
CreateInvalid(r, p) ==
    /\ nextId <= MaxIds
    /\ ~Valid(r)
    /\ nextId' = nextId + 1
    /\ last' = [NoCall EXCEPT !.op = "create", !.id = nextId, !.rcp = r, !.pay = p,
                              !.ans = "invalid-request", !.at = now]
    /\ wrote' = {}
    /\ UNCHANGED <<held, nid, rcp, pay, cAt, st, dAt, fAt, lAt, tried, rows, answered, now>>

\* CreateRefusedByDb: [Create] whose guards pass and whose write the database
\* refuses answers storage-failure (Operation 7) and records nothing.
CreateRefusedByDb(r, p) ==
    /\ nextId <= MaxIds
    /\ Valid(r)
    /\ nextId' = nextId + 1
    /\ last' = [NoCall EXCEPT !.op = "create", !.id = nextId, !.rcp = r, !.pay = p,
                              !.db = "refused", !.ans = "storage-failure", !.at = now]
    /\ wrote' = {}
    /\ UNCHANGED <<held, nid, rcp, pay, cAt, st, dAt, fAt, lAt, tried, rows, answered, now>>

\* TermUnknown: a terminal transition naming an id no notification carries
\* answers not-known, the first refusal on its line (Operation 8, Execution
\* Contract Refusal 1).
TermUnknown(op, i) ==
    /\ ~Known(i)
    /\ last' = [NoCall EXCEPT !.op = op, !.id = i, !.ans = "not-known", !.at = now]
    /\ wrote' = {}
    /\ UNCHANGED <<held, nid, rcp, pay, cAt, st, dAt, fAt, lAt, tried, rows, nextId, answered, now>>

\* TermNotPending: a terminal transition naming a notification whose status
\* is not pending answers not-pending and writes nothing (Operation 9), a
\* second [Deliver] included.
TermNotPending(op, s) ==
    /\ held[s]
    /\ st[s] # "pending"
    /\ last' = [NoCall EXCEPT !.op = op, !.id = nid[s], !.slot = s, !.ans = "not-pending", !.at = now]
    /\ wrote' = {}
    /\ UNCHANGED <<held, nid, rcp, pay, cAt, st, dAt, fAt, lAt, tried, rows, nextId, answered, now>>

\* TermRefusedByDb: a terminal transition on a pending notification whose
\* write the database refuses answers storage-failure (Operation 15) and
\* leaves the notification pending as found (Operation 16, Deliver
\* persistence 1); a [Deliver] or [Fail] so refused is an attempt the ledger
\* records.
TermRefusedByDb(op, s) ==
    /\ held[s]
    /\ st[s] = "pending"
    /\ tried' = IF op \in {"deliver", "fail"} THEN [tried EXCEPT ![s] = TRUE] ELSE tried
    /\ last' = [NoCall EXCEPT !.op = op, !.id = nid[s], !.slot = s, !.db = "refused",
                              !.ans = "storage-failure", !.at = now]
    /\ wrote' = {}
    /\ UNCHANGED <<held, nid, rcp, pay, cAt, st, dAt, fAt, lAt, rows, nextId, answered, now>>

\* Deliver: [Deliver] on a pending notification, the database accepting,
\* stands it in delivered (Operation 10), stamps the delivery instant from
\* now (State 8) and answers ok.
Deliver(s) ==
    /\ held[s]
    /\ st[s] = "pending"
    /\ st' = [st EXCEPT ![s] = "delivered"]
    /\ dAt' = [dAt EXCEPT ![s] = now]
    /\ tried' = [tried EXCEPT ![s] = TRUE]
    /\ last' = [NoCall EXCEPT !.op = "deliver", !.id = nid[s], !.slot = s, !.db = "ok",
                              !.ans = "ok", !.at = now]
    /\ wrote' = {s}
    /\ UNCHANGED <<held, nid, rcp, pay, cAt, fAt, lAt, rows, nextId, answered, now>>

\* Fail: [Fail] on a pending notification, the database accepting, stands it
\* in failed (Operation 11), stamps the failure instant from now (State 8)
\* and answers ok.
Fail(s) ==
    /\ held[s]
    /\ st[s] = "pending"
    /\ st' = [st EXCEPT ![s] = "failed"]
    /\ fAt' = [fAt EXCEPT ![s] = now]
    /\ tried' = [tried EXCEPT ![s] = TRUE]
    /\ last' = [NoCall EXCEPT !.op = "fail", !.id = nid[s], !.slot = s, !.db = "ok",
                              !.ans = "ok", !.at = now]
    /\ wrote' = {s}
    /\ UNCHANGED <<held, nid, rcp, pay, cAt, dAt, lAt, rows, nextId, answered, now>>

\* Expire: [Expire] on a pending notification, attempted or not, the database
\* accepting, stands it in expired (Operation 12, 13), stamps the lapse
\* instant from now (State 8) and answers ok.
Expire(s) ==
    /\ held[s]
    /\ st[s] = "pending"
    /\ st' = [st EXCEPT ![s] = "expired"]
    /\ lAt' = [lAt EXCEPT ![s] = now]
    /\ last' = [NoCall EXCEPT !.op = "expire", !.id = nid[s], !.slot = s, !.db = "ok",
                              !.ans = "ok", !.at = now]
    /\ wrote' = {s}
    /\ UNCHANGED <<held, nid, rcp, pay, cAt, dAt, fAt, tried, rows, nextId, answered, now>>

\* StatusOfKnown: [Status Of] naming a notification answers its stored fields
\* (Operation 17) and writes nothing (Operation 22).
StatusOfKnown(s) ==
    /\ held[s]
    /\ last' = [NoCall EXCEPT !.op = "status_of", !.id = nid[s], !.slot = s, !.ans = "found",
                              !.outId = nid[s], !.outSt = st[s], !.outRcp = rcp[s],
                              !.outPay = pay[s], !.outC = cAt[s], !.outD = dAt[s],
                              !.outF = fAt[s], !.outL = lAt[s], !.at = now]
    /\ wrote' = {}
    /\ UNCHANGED <<held, nid, rcp, pay, cAt, st, dAt, fAt, lAt, tried, rows, nextId, answered, now>>

\* StatusOfUnknown: [Status Of] naming an id no notification carries answers
\* not-known (Operation 18).
StatusOfUnknown(i) ==
    /\ ~Known(i)
    /\ last' = [NoCall EXCEPT !.op = "status_of", !.id = i, !.ans = "not-known", !.at = now]
    /\ wrote' = {}
    /\ UNCHANGED <<held, nid, rcp, pay, cAt, st, dAt, fAt, lAt, tried, rows, nextId, answered, now>>

\* PendingFor: [Pending For] answers the id of every pending notification
\* carrying the recipient reference, compared exactly (Operation 19, 20,
\* String 1), and writes nothing (Operation 23).
PendingFor(r) ==
    /\ last' = [NoCall EXCEPT !.op = "pending_for", !.rcp = r, !.ans = "ok",
                              !.ids = {nid[s] : s \in PendingRows(r)}, !.at = now]
    /\ wrote' = {}
    /\ UNCHANGED <<held, nid, rcp, pay, cAt, st, dAt, fAt, lAt, tried, rows, nextId, answered, now>>

\* Next: the clock advancing, or any call of the six actions, admitted or
\* refused as the page says.
Next ==
    \/ Tick
    \/ \E r \in Recipients, p \in Payloads : CreateLands(r, p)
    \/ \E r \in Recipients, p \in Payloads : CreateInvalid(r, p)
    \/ \E r \in Recipients, p \in Payloads : CreateRefusedByDb(r, p)
    \/ \E op \in TermOps, i \in QueryIds : TermUnknown(op, i)
    \/ \E op \in TermOps, s \in Slots : TermNotPending(op, s)
    \/ \E op \in TermOps, s \in Slots : TermRefusedByDb(op, s)
    \/ \E s \in Slots : Deliver(s)
    \/ \E s \in Slots : Fail(s)
    \/ \E s \in Slots : Expire(s)
    \/ \E s \in Slots : StatusOfKnown(s)
    \/ \E i \in QueryIds : StatusOfUnknown(i)
    \/ \E r \in Recipients : PendingFor(r)

\* Spec: every behaviour from Init by Next steps.
Spec == Init /\ [][Next]_vars

\* ---------------------------------------------------------------------------
\* Checks (the verification surface)
\* ---------------------------------------------------------------------------

\* Inv1_1_RecordedFieldsKept: no step changes a recorded notification's
\* notification id, recipient reference, payload or creation instant
\* (Invariant 1.1, Check 2.2).
Inv1_1_RecordedFieldsKept ==
    [][\A s \in Slots : held[s] =>
          (nid'[s] = nid[s] /\ rcp'[s] = rcp[s] /\ pay'[s] = pay[s] /\ cAt'[s] = cAt[s])]_vars

\* Inv1_2_LandedStampKept: no step changes a terminal stamp once it has
\* landed, so the outcome an auditor reads keeps its time (Invariant 1.2).
Inv1_2_LandedStampKept ==
    [][\A s \in Slots : held[s] =>
          (/\ (dAt[s] # Blank => dAt'[s] = dAt[s])
           /\ (fAt[s] # Blank => fAt'[s] = fAt[s])
           /\ (lAt[s] # Blank => lAt'[s] = lAt[s]))]_vars

\* Inv2_2_NoReturnToPending: no step moves a notification in a terminal status
\* back to pending: a retry is a second notification, never the failed one
\* reopened (Invariant 2.2, Non-goal 3, 4).
Inv2_2_NoReturnToPending ==
    [][\A s \in Slots : (held[s] /\ st[s] \in Terminal) => st'[s] # "pending"]_vars

\* Inv2_3_NoMoveBetweenTerminals: no step moves a notification from one
\* terminal status to another: one outcome per notification (Invariant 2.3).
Inv2_3_NoMoveBetweenTerminals ==
    [][\A s \in Slots : (held[s] /\ st[s] \in Terminal) => st'[s] = st[s]]_vars

\* Inv2_4_PendingReadReconstructs: whenever the atom reads a notification as
\* pending at the call's instant — [Pending For] answering its id, or [Status
\* Of] answering pending — the stored fields reconstruct it as pending at
\* that instant (Invariant 2.4, Check 2.1).
Inv2_4_PendingReadReconstructs ==
    /\ last.op = "pending_for" =>
          \A s \in Slots : (held[s] /\ nid[s] \in last.ids) => PendingAt(s, last.at)
    /\ (last.op = "status_of" /\ last.ans = "found" /\ last.outSt = "pending") =>
          (last.slot \in Slots /\ PendingAt(last.slot, last.at))

\* Inv5_1_CreateSetsId: an admitted [Create] wrote the id the seam supplied
\* it onto the notification it recorded (Invariant 5.1, Identity 2).
Inv5_1_CreateSetsId ==
    (last.op = "create" /\ last.ans = "ok")
        => (last.slot \in Slots /\ held[last.slot] /\ nid[last.slot] = last.id)

\* Inv6_1_NoSharedId: no two notifications in the database share a
\* notification id, two carrying one recipient and one payload included
\* (Invariant 6.1, Identity 6, 7, Check 6.2).
Inv6_1_NoSharedId ==
    \A s, t \in Slots : (s # t /\ held[s] /\ held[t]) => nid[s] # nid[t]

\* Inv8_1_DeliveryNotBeforeCreation: a delivery instant, once stamped, does
\* not precede the creation instant (Invariant 8.1).
Inv8_1_DeliveryNotBeforeCreation ==
    \A s \in Slots : (held[s] /\ dAt[s] # Blank) => dAt[s] >= cAt[s]

\* Inv8_2_FailureNotBeforeCreation: a failure instant, once stamped, does not
\* precede the creation instant (Invariant 8.2).
Inv8_2_FailureNotBeforeCreation ==
    \A s \in Slots : (held[s] /\ fAt[s] # Blank) => fAt[s] >= cAt[s]

\* Inv8_3_LapseNotBeforeCreation: a lapse instant, once stamped, does not
\* precede the creation instant (Invariant 8.3).
Inv8_3_LapseNotBeforeCreation ==
    \A s \in Slots : (held[s] /\ lAt[s] # Blank) => lAt[s] >= cAt[s]

\* Inv9_1_NoRecordDeleted: no step removes a notification record from the
\* database, a terminal one included (Invariant 9.1, State 10, Check 5.1).
Inv9_1_NoRecordDeleted ==
    [][\A s \in Slots : held[s] => held'[s]]_vars

\* Inv9_2_SetNeverShrinks: no step leaves the database holding fewer
\* notifications than before (Invariant 9.2, Check 5.1).
Inv9_2_SetNeverShrinks ==
    [][Cardinality({s \in Slots : held'[s]}) >= Cardinality({s \in Slots : held[s]})]_vars

\* Inv9_3_StatusOfAnswersForLife: [Status Of] naming an id an admitted
\* [Create] answered finds the notification, whatever has happened since
\* (Invariant 9.3).
Inv9_3_StatusOfAnswersForLife ==
    (last.op = "status_of" /\ last.id \in answered) => last.ans = "found"

\* State7_CreationFromNow: an admitted [Create] stamps the creation instant
\* from the clock reading of the call (State 7).
State7_CreationFromNow ==
    [][(last'.op = "create" /\ last'.ans = "ok")
         => (last'.slot \in Slots /\ cAt'[last'.slot] = now)]_vars

\* State8_StampFromNow: a terminal transition that answers ok stamps its
\* terminal stamp from the clock reading of the call (State 8).
State8_StampFromNow ==
    [][(last'.op \in TermOps /\ last'.ans = "ok" /\ last'.slot \in Slots)
         => (/\ (last'.op = "deliver" => dAt'[last'.slot] = now)
             /\ (last'.op = "fail" => fAt'[last'.slot] = now)
             /\ (last'.op = "expire" => lAt'[last'.slot] = now))]_vars

\* Op1_OneRecordPerCreate: a [Create] that answers ok records exactly one new
\* notification, a second call with the same recipient and payload included:
\* the atom never deduplicates (Operation 1, Identity 7, Non-goal 12).
Op1_OneRecordPerCreate ==
    [][(last'.op = "create" /\ last'.ans = "ok")
         => Cardinality({s \in Slots : held'[s] /\ ~held[s]}) = 1]_vars

\* Op3_CreateAnswersId: a [Create] that answered ok answered the
\* notification id the seam supplied it (Operation 3).
Op3_CreateAnswersId ==
    (last.op = "create" /\ last.ans = "ok") => (last.outId = last.id /\ last.id # NoId)

\* Op4_BlankRecipientRefused: a [Create] carrying a blank recipient reference
\* answered invalid-request (Operation 4).
Op4_BlankRecipientRefused ==
    (last.op = "create" /\ last.rcp = "") => last.ans = "invalid-request"

\* Op5_EmptyPayloadAccepted: a [Create] carrying the empty payload and a
\* recipient it admits was not refused as an invalid request (Operation 5).
Op5_EmptyPayloadAccepted ==
    (last.op = "create" /\ last.pay = "" /\ Valid(last.rcp)) => last.ans # "invalid-request"

\* Op7_CreateStorageFailure: a [Create] whose write the database refused
\* answered storage-failure (Operation 7).
Op7_CreateStorageFailure ==
    (last.op = "create" /\ last.db = "refused") => last.ans = "storage-failure"

\* Op8_UnknownIdNotKnown: a terminal transition naming an id no notification
\* carried answers not-known (Operation 8).
Op8_UnknownIdNotKnown ==
    [][(last'.op \in TermOps /\ ~Known(last'.id)) => last'.ans = "not-known"]_vars

\* Op9_NotPendingRefused: a terminal transition naming a notification whose
\* status was not pending answers not-pending (Operation 9).
Op9_NotPendingRefused ==
    [][(last'.op \in TermOps /\ last'.slot \in Slots /\ held[last'.slot]
            /\ st[last'.slot] # "pending")
         => last'.ans = "not-pending"]_vars

\* Op10_DeliverStandsDelivered: a [Deliver] that answers ok stands the
\* notification in delivered (Operation 10).
Op10_DeliverStandsDelivered ==
    [][(last'.op = "deliver" /\ last'.ans = "ok")
         => (last'.slot \in Slots /\ st'[last'.slot] = "delivered")]_vars

\* Op11_FailStandsFailed: a [Fail] that answers ok stands the notification in
\* failed, never in expired: the atom does not choose between the two
\* (Operation 11, 14).
Op11_FailStandsFailed ==
    [][(last'.op = "fail" /\ last'.ans = "ok")
         => (last'.slot \in Slots /\ st'[last'.slot] = "failed")]_vars

\* Op12_ExpireStandsExpired: an [Expire] that answers ok stands the
\* notification in expired, never in failed (Operation 12, 14).
Op12_ExpireStandsExpired ==
    [][(last'.op = "expire" /\ last'.ans = "ok")
         => (last'.slot \in Slots /\ st'[last'.slot] = "expired")]_vars

\* Op13_ExpireNeedsNoAttempt: an [Expire] on a pending notification no
\* [Deliver] or [Fail] has tried, the database accepting, lands (Operation
\* 13; the case table's "attempted or not").
Op13_ExpireNeedsNoAttempt ==
    [][(last'.op = "expire" /\ last'.db # "refused" /\ last'.slot \in Slots
            /\ held[last'.slot] /\ st[last'.slot] = "pending" /\ ~tried[last'.slot])
         => last'.ans = "ok"]_vars

\* Op15_TerminalStorageFailure: a terminal transition whose write the
\* database refused answered storage-failure (Operation 15, Deliver
\* persistence 1).
Op15_TerminalStorageFailure ==
    (last.op \in TermOps /\ last.db = "refused") => last.ans = "storage-failure"

\* Op16_RefusedCallLeavesRecord: a call that answers a refusal leaves every
\* notification record as it found it (Operation 16).
Op16_RefusedCallLeavesRecord ==
    [][last'.ans \in Refusals => UNCHANGED records]_vars

\* Op17_StatusOfAnswersStoredFields: a [Status Of] that found a notification
\* answered its stored fields, every one (Operation 17, Check 1.1).
Op17_StatusOfAnswersStoredFields ==
    (last.op = "status_of" /\ last.ans = "found")
        => (/\ last.slot \in Slots
            /\ last.outId = nid[last.slot] /\ last.outSt = st[last.slot]
            /\ last.outRcp = rcp[last.slot] /\ last.outPay = pay[last.slot]
            /\ last.outC = cAt[last.slot] /\ last.outD = dAt[last.slot]
            /\ last.outF = fAt[last.slot] /\ last.outL = lAt[last.slot])

\* Op18_StatusOfUnknownNotKnown: a [Status Of] naming an id no notification
\* carries answered not-known (Operation 18).
Op18_StatusOfUnknownNotKnown ==
    (last.op = "status_of" /\ ~Known(last.id)) => last.ans = "not-known"

\* Op19_PendingForAnswersEvery: a [Pending For] answered the id of every
\* pending notification carrying the recipient reference (Operation 19).
Op19_PendingForAnswersEvery ==
    last.op = "pending_for" => \A s \in PendingRows(last.rcp) : nid[s] \in last.ids

\* Op20_PendingForNoTerminal: a [Pending For] answered no id of a terminal
\* notification (Operation 20).
Op20_PendingForNoTerminal ==
    last.op = "pending_for" =>
        \A s \in Slots : (held[s] /\ nid[s] \in last.ids) => st[s] = "pending"

\* Op22_StatusOfWritesNothing: a [Status Of] step writes no record and
\* changes no field (Operation 22).
Op22_StatusOfWritesNothing ==
    [][last'.op = "status_of" => (wrote' = {} /\ UNCHANGED records)]_vars

\* Op23_PendingForWritesNothing: a [Pending For] step writes no record and
\* changes no field: it is a read, never a deadline sweep (Operation 23,
\* Bulk expiry 3, Non-goal 15).
Op23_PendingForWritesNothing ==
    [][last'.op = "pending_for" => (wrote' = {} /\ UNCHANGED records)]_vars

\* String6_OverCapRefused: a [Create] carrying a recipient reference over the
\* string cap answered invalid-request (String 6).
String6_OverCapRefused ==
    (last.op = "create" /\ last.rcp \in OverCap) => last.ans = "invalid-request"

\* String8_OverLengthMatchesNothing: a [Pending For] with a recipient
\* reference over the string cap answered no id (String 8).
String8_OverLengthMatchesNothing ==
    (last.op = "pending_for" /\ last.rcp \in OverCap) => last.ids = {}

\* String9_BlankMatchesNothing: a [Pending For] with a blank recipient
\* reference answered no id (String 9).
String9_BlankMatchesNothing ==
    (last.op = "pending_for" /\ last.rcp = "") => last.ids = {}

====
