---- MODULE notification-fanout-buggy-supersede ----
\* DELIBERATELY WRONG twin of notification-fanout.tla (unit: `compositions/notification-fanout.md formal layer`).
\*
\* INJECTED DEFECT: a create for a subscriber fails that subscriber's earlier pending records, one live
\* notification per subscriber (Composes 6).
\*
\* BREAKS: Composes6_OnlyCreateWrites.
\* Everything else is notification-fanout.tla as written; read its comments there.

EXTENDS Integers, FiniteSets

CONSTANTS
    Refs,         \* the subscriber references
    MaxRecs,      \* how many notification records the model's database holds room for
    MaxFanouts    \* how many fanouts the model runs

\* NONE: the value of a reference not yet written.
NONE == "none"

\* Slots: the places a notification record can occupy, in the order created.
Slots == 1..MaxRecs

\* NoStep: the record of the last step before any step, and the shape of every
\* such record: what the step was, the reference and record slot it named, and
\* what it answered.
NoStep == [op |-> "none", ref |-> NONE, slot |-> 0, ans |-> "none"]

\* FanoutOps: the steps the composition takes; every other step is the world's.
FanoutOps == {"start", "takeid", "read", "create", "skip", "answer", "crash"}

\* ---------------------------------------------------------------------------
\* State
\* ---------------------------------------------------------------------------

VARIABLES
    sub,      \* reference -> its subscription's status for the scope ("none", "active", "cancelled")
    rRecip,   \* slot -> the record's recipient reference
    rFan,     \* slot -> the fanout whose create wrote it (the model's own; 0: none)
    rStatus,  \* slot -> the record's status ("none": no record)
    nrec,     \* the next free slot
    pc,       \* where the fanout in flight stands ("idle": none)
    fno,      \* how many fanouts have started; the one in flight is number fno
    nextId,   \* the next fanout id the seam supplies
    fid,      \* the fanout id the fanout in flight took (0: none yet)
    answer,   \* the subscribers_for answer the fanout in flight holds
    todo,     \* the references of that answer whose create is not yet called
    called,   \* the references the fanout in flight called create for
    created,  \* its created list (record slots)
    failed,   \* its failed list (references)
    reads,    \* how many subscribers_for calls the fanout in flight made
    last      \* the last step and what it answered (NoStep's shape)

\* vars: every variable; a step that changes none of them is a stutter.
vars == <<sub, rRecip, rFan, rStatus, nrec, pc, fno, nextId, fid, answer, todo,
          called, created, failed, reads, last>>

\* records: the notification records Notification's database holds.
records == <<rRecip, rFan, rStatus, nrec>>

\* fanout: the fanout in flight's own working state.
fanout == <<pc, fno, nextId, fid, answer, todo, called, created, failed, reads>>

\* Active: the references whose subscription is active now.
Active == {r \in Refs : sub[r] = "active"}

\* TypeOK: each variable holds a value of its kind (the model's typing, not a
\* rule of the page).
TypeOK ==
    /\ sub \in [Refs -> {"none", "active", "cancelled"}]
    /\ rRecip \in [Slots -> Refs \cup {NONE}]
    /\ rFan \in [Slots -> 0..MaxFanouts]
    /\ rStatus \in [Slots -> {"none", "pending", "delivered", "failed"}]
    /\ nrec \in 1..(MaxRecs + 1)
    /\ pc \in {"idle", "admitted", "holding", "creating"}
    /\ fno \in 0..MaxFanouts
    /\ nextId \in 1..(MaxFanouts + 1)
    /\ fid \in 0..MaxFanouts
    /\ answer \subseteq Refs
    /\ todo \subseteq Refs
    /\ called \subseteq Refs
    /\ created \subseteq Slots
    /\ failed \subseteq Refs
    /\ reads \in Nat

\* Init: no subscription, no record, no fanout in flight.
Init ==
    /\ sub = [r \in Refs |-> "none"]
    /\ rRecip = [s \in Slots |-> NONE]
    /\ rFan = [s \in Slots |-> 0]
    /\ rStatus = [s \in Slots |-> "none"]
    /\ nrec = 1
    /\ pc = "idle"
    /\ fno = 0
    /\ nextId = 1
    /\ fid = 0
    /\ answer = {}
    /\ todo = {}
    /\ called = {}
    /\ created = {}
    /\ failed = {}
    /\ reads = 0
    /\ last = NoStep

\* ---------------------------------------------------------------------------
\* The world's steps
\* ---------------------------------------------------------------------------

\* Subscribe: a subscriber with no active subscription subscribes to the scope
\* (Subscription's own [Subscribe]).
Subscribe(r) ==
    /\ sub[r] # "active"
    /\ sub' = [sub EXCEPT ![r] = "active"]
    /\ last' = [NoStep EXCEPT !.op = "subscribe", !.ref = r]
    /\ UNCHANGED <<rRecip, rFan, rStatus, nrec>>
    /\ UNCHANGED fanout

\* Cancel: an active subscriber cancels (Subscription's own [Cancel]).
Cancel(r) ==
    /\ sub[r] = "active"
    /\ sub' = [sub EXCEPT ![r] = "cancelled"]
    /\ last' = [NoStep EXCEPT !.op = "cancel", !.ref = r]
    /\ UNCHANGED <<rRecip, rFan, rStatus, nrec>>
    /\ UNCHANGED fanout

\* Deliver: the delivery layer delivers one pending record (Notification's
\* [Deliver], Non-goal 10).
Deliver(s) ==
    /\ rStatus[s] = "pending"
    /\ rStatus' = [rStatus EXCEPT ![s] = "delivered"]
    /\ last' = [NoStep EXCEPT !.op = "deliver", !.slot = s]
    /\ UNCHANGED <<sub, rRecip, rFan, nrec>>
    /\ UNCHANGED fanout

\* FailDelivery: the delivery layer fails one pending record (Notification's
\* [Fail]); not the fanout's failed list.
FailDelivery(s) ==
    /\ rStatus[s] = "pending"
    /\ rStatus' = [rStatus EXCEPT ![s] = "failed"]
    /\ last' = [NoStep EXCEPT !.op = "faildelivery", !.slot = s]
    /\ UNCHANGED <<sub, rRecip, rFan, nrec>>
    /\ UNCHANGED fanout

\* ---------------------------------------------------------------------------
\* The composition's steps
\* ---------------------------------------------------------------------------

\* Start: an admitted [Fanout] call begins; its working state starts empty and
\* it holds no fanout id yet.
Start ==
    /\ pc = "idle"
    /\ fno < MaxFanouts
    /\ pc' = "admitted"
    /\ fno' = fno + 1
    /\ fid' = 0
    /\ answer' = {}
    /\ todo' = {}
    /\ called' = {}
    /\ created' = {}
    /\ failed' = {}
    /\ reads' = 0
    /\ last' = [NoStep EXCEPT !.op = "start"]
    /\ UNCHANGED <<sub, rRecip, rFan, rStatus, nrec, nextId>>

\* TakeId: the admitted fanout takes the fanout id the seam supplies (Action
\* wiring 3), before any constituent call (Invariant 8.2).
TakeId ==
    /\ pc = "admitted"
    /\ fid' = nextId
    /\ nextId' = nextId + 1
    /\ pc' = "holding"
    /\ last' = [NoStep EXCEPT !.op = "takeid"]
    /\ UNCHANGED <<sub, rRecip, rFan, rStatus, nrec, fno, answer, todo, called,
                   created, failed, reads>>

\* ReadAnswered: subscribers_for answers the subscribers active as it executes
\* (Action wiring 1); the fanout holds that answer for the rest of its run.
ReadAnswered ==
    /\ pc = "holding"
    /\ answer' = Active
    /\ todo' = Active
    /\ reads' = reads + 1
    /\ pc' = "creating"
    /\ last' = [NoStep EXCEPT !.op = "read", !.ans = "answered"]
    /\ UNCHANGED <<sub, rRecip, rFan, rStatus, nrec, fno, nextId, fid, called,
                   created, failed>>

\* ReadFailed: subscribers_for answers state-unavailable or nothing within the
\* read latency bound; the fanout answers subscribers-unavailable and ends
\* (Action wiring 4, 5).
ReadFailed ==
    /\ pc = "holding"
    /\ reads' = reads + 1
    /\ pc' = "idle"
    /\ last' = [NoStep EXCEPT !.op = "read", !.ans = "subscribers-unavailable"]
    /\ UNCHANGED <<sub, rRecip, rFan, rStatus, nrec, fno, nextId, fid, answer,
                   todo, called, created, failed>>

\* CreateOk: create for a reference of the answer commits one pending record
\* and answers its notification id, which goes in the created list (Action
\* wiring 8, 10).
CreateOk(r) ==
    /\ pc = "creating"
    /\ r \in todo
    /\ nrec <= MaxRecs
    /\ rRecip' = [rRecip EXCEPT ![nrec] = r]
    /\ rFan' = [rFan EXCEPT ![nrec] = fno]
    /\ rStatus' = [s \in Slots |-> IF s = nrec THEN "pending"
                                   ELSE IF rRecip[s] = r /\ rStatus[s] = "pending" THEN "failed"
                                   ELSE rStatus[s]]   \* BUG: earlier records superseded
    /\ nrec' = nrec + 1
    /\ created' = created \cup {nrec}
    /\ todo' = todo \ {r}
    /\ called' = called \cup {r}
    /\ last' = [op |-> "create", ref |-> r, slot |-> nrec, ans |-> "ok"]
    /\ UNCHANGED <<sub, pc, fno, nextId, fid, answer, failed, reads>>

\* CreateRefused: create answers a declared refusal or state-unavailable and
\* commits nothing; the reference goes in the failed list and the fan-out goes
\* on (Action wiring 11, Wiring decision 1, 2).
CreateRefused(r) ==
    /\ pc = "creating"
    /\ r \in todo
    /\ failed' = failed \cup {r}
    /\ todo' = todo \ {r}
    /\ called' = called \cup {r}
    /\ last' = [op |-> "create", ref |-> r, slot |-> 0, ans |-> "refused"]
    /\ UNCHANGED <<sub, rRecip, rFan, rStatus, nrec, pc, fno, nextId, fid,
                   answer, created, reads>>

\* CreateUnanswered: create answers nothing within the create bound; its record
\* may have committed (a pending record the composition never sees) or not. The
\* reference goes in the failed list either way (Action wiring 11).
CreateUnanswered(r, commit) ==
    /\ pc = "creating"
    /\ r \in todo
    /\ commit => nrec <= MaxRecs
    /\ rRecip' = IF commit THEN [rRecip EXCEPT ![nrec] = r] ELSE rRecip
    /\ rFan' = IF commit THEN [rFan EXCEPT ![nrec] = fno] ELSE rFan
    /\ rStatus' = IF commit THEN [rStatus EXCEPT ![nrec] = "pending"] ELSE rStatus
    /\ nrec' = IF commit THEN nrec + 1 ELSE nrec
    /\ failed' = failed \cup {r}
    /\ todo' = todo \ {r}
    /\ called' = called \cup {r}
    /\ last' = [op |-> "create", ref |-> r, slot |-> 0, ans |-> "noanswer"]
    /\ UNCHANGED <<sub, pc, fno, nextId, fid, answer, created, reads>>

\* AnswerResult: once create was called for every reference of the answer, the
\* fanout answers its result and ends (Action wiring 13).
AnswerResult ==
    /\ pc = "creating"
    /\ todo = {}
    /\ pc' = "idle"
    /\ last' = [NoStep EXCEPT !.op = "answer", !.ans = "result"]
    /\ UNCHANGED <<sub, rRecip, rFan, rStatus, nrec, fno, nextId, fid, answer,
                   todo, called, created, failed, reads>>

\* Crash: the fanout dies partway; the records its creates committed stay, and
\* it answers nothing (Non-goal 3).
Crash ==
    /\ pc \in {"admitted", "holding", "creating"}
    /\ pc' = "idle"
    /\ last' = [NoStep EXCEPT !.op = "crash"]
    /\ UNCHANGED <<sub, rRecip, rFan, rStatus, nrec, fno, nextId, fid, answer,
                   todo, called, created, failed, reads>>

\* Next: a world step or a composition step.
Next ==
    \/ \E r \in Refs : Subscribe(r)
    \/ \E r \in Refs : Cancel(r)
    \/ \E s \in Slots : Deliver(s)
    \/ \E s \in Slots : FailDelivery(s)
    \/ Start
    \/ TakeId
    \/ ReadAnswered
    \/ ReadFailed
    \/ \E r \in Refs : CreateOk(r)
    \/ \E r \in Refs : CreateRefused(r)
    \/ \E r \in Refs, c \in BOOLEAN : CreateUnanswered(r, c)
    \/ AnswerResult
    \/ Crash

\* Spec: every behaviour from Init by Next steps.
Spec == Init /\ [][Next]_vars

\* ---------------------------------------------------------------------------
\* Checks (the verification surface)
\* ---------------------------------------------------------------------------

\* Inv3_1_FailedCreateChangesNoOther: a create that failed (refused, or not
\* answered) changes no record already in the database: another subscriber's
\* record, from this fanout or an earlier one, stays as it was (Invariant 3.1,
\* Action wiring 15).
Inv3_1_FailedCreateChangesNoOther ==
    [][(last'.op = "create" /\ last'.ans # "ok") =>
          \A s \in Slots : s < nrec =>
              /\ rRecip'[s] = rRecip[s]
              /\ rFan'[s] = rFan[s]
              /\ rStatus'[s] = rStatus[s]]_vars

\* Inv3_2_OwnStatus: a delivery or a failure of one record moves that record's
\* status alone: the records of one fanout each carry a status of their own
\* (Invariant 3.2, Check 3.1).
Inv3_2_OwnStatus ==
    [][last'.op \in {"deliver", "faildelivery"} =>
          \A s \in Slots : s # last'.slot => rStatus'[s] = rStatus[s]]_vars

\* Inv5_1_SubscriptionsReadOnly: no step of the composition changes a
\* subscription record (Invariant 5.1, Check 5.1).
Inv5_1_SubscriptionsReadOnly ==
    [][last'.op \in FanoutOps => sub' = sub]_vars

\* Inv8_2_IdBeforeAnyCall: the fanout calls subscribers_for or create only
\* while it holds the fanout id it took (Invariant 8.2).
Inv8_2_IdBeforeAnyCall ==
    [][last'.op \in {"read", "create"} => fid # 0]_vars

\* WD1_2_ContinueThroughFailure: a fanout that read its subscribers leaves the
\* fan-out only by answering a result or by crashing, and a crash answers
\* nothing: a failed create aborts nothing and a crash answers no result
\* (Wiring decision 1, 2, Non-goal 3). That the result comes only once every
\* create was called is NG5_NoSkip.
WD1_2_ContinueThroughFailure ==
    [][(pc = "creating" /\ pc' # "creating") =>
          \/ (last'.op = "answer" /\ last'.ans = "result")
          \/ (last'.op = "crash" /\ last'.ans = "none")]_vars

\* NG4_ReadOnce: no fanout calls subscribers_for twice (Non-goal 4): its
\* subscriber set is fixed once.
NG4_ReadOnce ==
    reads <= 1

\* NG5_NoSkip: a fanout answers a result only after calling create for every
\* reference its subscribers_for answer carried, a subscriber who cancelled
\* after the read included (Non-goal 5, Invariant 1.1 across steps).
NG5_NoSkip ==
    [][(last'.op = "answer" /\ last'.ans = "result") => answer \subseteq called]_vars

\* NG6_OnlyTheAnswer: every create the fanout calls names a reference its
\* subscribers_for answer carried, never one who subscribed after the read
\* (Non-goal 6, Action wiring 9).
NG6_OnlyTheAnswer ==
    [][last'.op = "create" => last'.ref \in answer]_vars

\* Composes6_OnlyCreateWrites: no step of the composition changes a record
\* already in the database: its one write to the notification records is a
\* create, which adds a record (Composes 6).
Composes6_OnlyCreateWrites ==
    [][last'.op \in FanoutOps =>
          \A s \in Slots : s < nrec =>
              /\ rRecip'[s] = rRecip[s]
              /\ rFan'[s] = rFan[s]
              /\ rStatus'[s] = rStatus[s]]_vars

====
