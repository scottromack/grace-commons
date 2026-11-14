---- MODULE subscription-buggy-cancel-instant-lost ----
\* DELIBERATELY WRONG twin of subscription.tla (unit: `atoms/subscription.md formal layer`).
\* INJECTED DEFECT: [Cancel] stands the subscription in cancelled but its
\* cancellation-instant write is lost (State 3, 5).
\* BREAKS: State3_CancelledCarriesInstant, State5_CancelFromNow; also Check1_1.
\* Everything else is subscription.tla as written; read its comments there.

EXTENDS Integers, FiniteSets

CONSTANTS
    MaxN,        \* how many subscription rows the database holds in the model
    MaxIds,      \* how many ids the seam supplies (one per [Subscribe] call)
    MaxTime,     \* the last clock reading the model reaches
    Refs,        \* the strings a call may carry as subscriber reference or event scope
    OverCap,     \* the strings in Refs longer than the string cap (Term string cap)
    Malformed    \* the tokens in Refs standing for an input that is no string

\* Slots: the database's rows, in the order they are written.
Slots == 1..MaxN

\* MalformedId: a [Cancel] input that is no string, so it names no subscription
\* (Operation 31).
MalformedId == MaxIds + 2

\* QueryIds: the ids a [Cancel] may name: every id the seam can supply, one
\* (MaxIds + 1) it never supplies, and the malformed id.
QueryIds == 1..(MaxIds + 1) \cup {MalformedId}

\* Blank: an instant field that carries nothing (no stamp has landed).
Blank == -1

\* NoId: a subscription id field or answer that carries no id.
NoId == 0

\* Refusals: the answers by which a call refuses.
Refusals == {"invalid-request", "already-subscribed", "not-known", "not-active",
             "storage-failure"}

\* Valid: a string input [Subscribe] admits: not blank (Operation 4, 5), not
\* over the string cap (Operation 29) and not malformed (Operation 30).
Valid(r) == r # "" /\ r \notin OverCap /\ r \notin Malformed

\* NoCall: the record of the last call before any call is made, and the shape
\* of every such record: the action; the id it named or was supplied; the row
\* it wrote or found (0 for none); the subscriber reference and event scope it
\* carried; the database's answer to its write ("none" where it wrote
\* nothing); what it answered; the id and the set of subscriber references its
\* answer carried; and the clock reading it was made at.
NoCall == [op |-> "none", id |-> NoId, slot |-> 0, sub |-> "", scp |-> "",
           db |-> "none", ans |-> "none", outId |-> NoId, refs |-> {}, at |-> Blank]

\* ---------------------------------------------------------------------------
\* State
\* ---------------------------------------------------------------------------

VARIABLES
    held,     \* row -> whether a subscription record is in the database there
    nid,      \* row -> the subscription id it carries (NoId before)
    sub,      \* row -> the subscriber reference it carries
    scp,      \* row -> the event scope it carries
    sAt,      \* row -> its subscription instant (Blank before)
    st,       \* row -> its status ("none" before)
    cAt,      \* row -> its cancellation instant (Blank until one lands)
    rows,     \* how many rows the database has written
    nextId,   \* the next id the seam will supply
    now,      \* the deployment's clock reading
    last,     \* the last call made and what it answered (NoCall's shape)
    wrote     \* the rows the last step wrote

\* vars: every variable; a step that changes none of them is a stutter.
vars == <<held, nid, sub, scp, sAt, st, cAt, rows, nextId, now, last, wrote>>

\* records: every variable that holds a subscription record's fields.
records == <<held, nid, sub, scp, sAt, st, cAt>>

\* Known: some subscription in the database carries the id.
Known(i) == \E s \in Slots : held[s] /\ nid[s] = i

\* KnownAfter: some subscription carries the id once the step has run.
KnownAfter(i) == \E s \in Slots : held'[s] /\ nid'[s] = i

\* ActivePair: some active subscription carries the pair (Term pair, Term
\* active set).
ActivePair(r, e) == \E s \in Slots : held[s] /\ st[s] = "active" /\ sub[s] = r /\ scp[s] = e

\* ActiveRefs: the subscriber references of the active subscriptions matching
\* the event scope exactly — the audience the active set gives.
ActiveRefs(e) == {sub[s] : s \in {t \in Slots : held[t] /\ st[t] = "active" /\ scp[t] = e}}

\* ActiveAt: the row was active at instant t, read from its stored instants as
\* an auditor reads it, never from its status: subscription instant at or
\* before t, and cancellation instant absent or after t (Term active at an
\* instant).
ActiveAt(s, t) == sAt[s] <= t /\ (cAt[s] = Blank \/ t < cAt[s])

\* TypeOK: each variable holds a value of its kind (the model's typing, not a
\* rule of the page).
TypeOK ==
    /\ held \in [Slots -> BOOLEAN]
    /\ nid \in [Slots -> 0..MaxIds]
    /\ sub \in [Slots -> Refs]
    /\ scp \in [Slots -> Refs]
    /\ sAt \in [Slots -> {Blank} \cup 0..MaxTime]
    /\ st \in [Slots -> {"none", "active", "cancelled"}]
    /\ cAt \in [Slots -> {Blank} \cup 0..MaxTime]
    /\ rows \in 0..MaxN
    /\ nextId \in 1..(MaxIds + 1)
    /\ now \in 0..MaxTime
    /\ last \in [op : {"none", "subscribe", "cancel", "subscribed", "subscribers_for"},
                 id : 0..MalformedId, slot : 0..MaxN, sub : Refs, scp : Refs,
                 db : {"none", "ok", "refused"},
                 ans : {"none", "ok", "subscribed", "not-subscribed"} \cup Refusals,
                 outId : 0..MaxIds, refs : SUBSET Refs, at : {Blank} \cup 0..MaxTime]
    /\ wrote \subseteq Slots

\* Init: no subscription; the clock at its first reading.
Init ==
    /\ held = [s \in Slots |-> FALSE]
    /\ nid = [s \in Slots |-> NoId]
    /\ sub = [s \in Slots |-> ""]
    /\ scp = [s \in Slots |-> ""]
    /\ sAt = [s \in Slots |-> Blank]
    /\ st = [s \in Slots |-> "none"]
    /\ cAt = [s \in Slots |-> Blank]
    /\ rows = 0
    /\ nextId = 1
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
    /\ UNCHANGED <<held, nid, sub, scp, sAt, st, cAt, rows, nextId>>

\* SubscribeLands: [Subscribe] with a subscriber reference and an event scope
\* it admits, no active subscription for the pair, the database accepting,
\* records one subscription in the next row carrying the id the seam supplied,
\* the reference and the scope as given, the subscription instant from now,
\* standing in active (Operation 1, 2, 7, 8, State 4, Identity 2), and answers
\* the id (Operation 3).
SubscribeLands(r, e) ==
    /\ nextId <= MaxIds
    /\ rows < MaxN
    /\ Valid(r) /\ Valid(e)
    /\ ~ActivePair(r, e)
    /\ held' = [held EXCEPT ![rows + 1] = TRUE]
    /\ nid' = [nid EXCEPT ![rows + 1] = nextId]
    /\ sub' = [sub EXCEPT ![rows + 1] = r]
    /\ scp' = [scp EXCEPT ![rows + 1] = e]
    /\ sAt' = [sAt EXCEPT ![rows + 1] = now]
    /\ st' = [st EXCEPT ![rows + 1] = "active"]
    /\ rows' = rows + 1
    /\ nextId' = nextId + 1
    /\ last' = [NoCall EXCEPT !.op = "subscribe", !.id = nextId, !.slot = rows + 1,
                              !.sub = r, !.scp = e, !.db = "ok", !.ans = "ok",
                              !.outId = nextId, !.at = now]
    /\ wrote' = {rows + 1}
    /\ UNCHANGED <<cAt, now>>

\* SubscribeInvalid: [Subscribe] with a blank, over-cap or malformed
\* subscriber reference or event scope answers invalid-request, the first
\* refusal on its line, and writes nothing (Operation 4, 5, 29, 30); the id the
\* seam supplied the call is spent.
SubscribeInvalid(r, e) ==
    /\ nextId <= MaxIds
    /\ ~(Valid(r) /\ Valid(e))
    /\ nextId' = nextId + 1
    /\ last' = [NoCall EXCEPT !.op = "subscribe", !.id = nextId, !.sub = r, !.scp = e,
                              !.ans = "invalid-request", !.at = now]
    /\ wrote' = {}
    /\ UNCHANGED <<held, nid, sub, scp, sAt, st, cAt, rows, now>>

\* SubscribeAlready: [Subscribe] for a pair that already has an active
\* subscription answers already-subscribed and writes nothing (Operation 6).
SubscribeAlready(r, e) ==
    /\ nextId <= MaxIds
    /\ Valid(r) /\ Valid(e)
    /\ ActivePair(r, e)
    /\ nextId' = nextId + 1
    /\ last' = [NoCall EXCEPT !.op = "subscribe", !.id = nextId, !.sub = r, !.scp = e,
                              !.ans = "already-subscribed", !.at = now]
    /\ wrote' = {}
    /\ UNCHANGED <<held, nid, sub, scp, sAt, st, cAt, rows, now>>

\* SubscribeRefusedByDb: [Subscribe] whose guards pass and whose write the
\* database refuses answers storage-failure (Operation 13) and records nothing.
SubscribeRefusedByDb(r, e) ==
    /\ nextId <= MaxIds
    /\ Valid(r) /\ Valid(e)
    /\ ~ActivePair(r, e)
    /\ nextId' = nextId + 1
    /\ last' = [NoCall EXCEPT !.op = "subscribe", !.id = nextId, !.sub = r, !.scp = e,
                              !.db = "refused", !.ans = "storage-failure", !.at = now]
    /\ wrote' = {}
    /\ UNCHANGED <<held, nid, sub, scp, sAt, st, cAt, rows, now>>

\* CancelUnknown: [Cancel] naming an id no subscription carries, a malformed
\* id included, answers not-known, the first refusal on its line (Operation 9,
\* 31). The caller c is whoever holds the id; the atom never reads it.
CancelUnknown(i, c) ==
    /\ ~Known(i)
    /\ last' = [NoCall EXCEPT !.op = "cancel", !.id = i, !.ans = "not-known", !.at = now]
    /\ wrote' = {}
    /\ UNCHANGED <<held, nid, sub, scp, sAt, st, cAt, rows, nextId, now>>

\* CancelNotActive: [Cancel] naming a cancelled subscription answers
\* not-active and writes nothing (Operation 10).
CancelNotActive(s, c) ==
    /\ held[s]
    /\ st[s] = "cancelled"
    /\ last' = [NoCall EXCEPT !.op = "cancel", !.id = nid[s], !.slot = s,
                              !.ans = "not-active", !.at = now]
    /\ wrote' = {}
    /\ UNCHANGED <<held, nid, sub, scp, sAt, st, cAt, rows, nextId, now>>

\* CancelRefusedByDb: [Cancel] on an active subscription whose write the
\* database refuses answers storage-failure (Operation 14) and leaves the
\* subscription active.
CancelRefusedByDb(s, c) ==
    /\ held[s]
    /\ st[s] = "active"
    /\ last' = [NoCall EXCEPT !.op = "cancel", !.id = nid[s], !.slot = s, !.db = "refused",
                              !.ans = "storage-failure", !.at = now]
    /\ wrote' = {}
    /\ UNCHANGED <<held, nid, sub, scp, sAt, st, cAt, rows, nextId, now>>

\* CancelLands: [Cancel] on an active subscription, whoever the caller
\* holding its id (Operation 12, Cancel capability 1), the database
\* accepting, stands it in cancelled (Operation 11), stamps the cancellation
\* instant from now (State 5) and answers ok (Operation 32).
CancelLands(s, c) ==
    /\ held[s]
    /\ st[s] = "active"
    /\ st' = [st EXCEPT ![s] = "cancelled"]
    /\ last' = [NoCall EXCEPT !.op = "cancel", !.id = nid[s], !.slot = s, !.db = "ok",
                              !.ans = "ok", !.at = now]
    /\ wrote' = {s}
    /\ UNCHANGED <<held, nid, sub, scp, sAt, cAt, rows, nextId, now>>   \* BUG

\* Subscribed: [Subscribed] answers subscribed where an active subscription
\* carries the pair and not-subscribed otherwise, blank arguments included,
\* and writes nothing (Operation 16, 17, 18, 24, Invariant 7.1, 8.1).
Subscribed(r, e) ==
    /\ last' = [NoCall EXCEPT !.op = "subscribed", !.sub = r, !.scp = e,
                              !.ans = IF ActivePair(r, e) THEN "subscribed" ELSE "not-subscribed",
                              !.at = now]
    /\ wrote' = {}
    /\ UNCHANGED <<held, nid, sub, scp, sAt, st, cAt, rows, nextId, now>>

\* SubscribersFor: [Subscribers For] answers the subscriber reference of
\* every active subscription matching the event scope exactly, and no other
\* (Operation 19, 20, 22, Invariant 7.2), and writes nothing (Operation 25).
SubscribersFor(e) ==
    /\ last' = [NoCall EXCEPT !.op = "subscribers_for", !.scp = e, !.ans = "ok",
                              !.refs = ActiveRefs(e), !.at = now]
    /\ wrote' = {}
    /\ UNCHANGED <<held, nid, sub, scp, sAt, st, cAt, rows, nextId, now>>

\* Next: the clock advancing, or any call of the four actions, admitted or
\* refused as the page says.
Next ==
    \/ Tick
    \/ \E r, e \in Refs : SubscribeLands(r, e)
    \/ \E r, e \in Refs : SubscribeInvalid(r, e)
    \/ \E r, e \in Refs : SubscribeAlready(r, e)
    \/ \E r, e \in Refs : SubscribeRefusedByDb(r, e)
    \/ \E i \in QueryIds, c \in Refs : CancelUnknown(i, c)
    \/ \E s \in Slots, c \in Refs : CancelNotActive(s, c)
    \/ \E s \in Slots, c \in Refs : CancelRefusedByDb(s, c)
    \/ \E s \in Slots, c \in Refs : CancelLands(s, c)
    \/ \E r, e \in Refs : Subscribed(r, e)
    \/ \E e \in Refs : SubscribersFor(e)

\* Spec: every behaviour from Init by Next steps.
Spec == Init /\ [][Next]_vars

\* ---------------------------------------------------------------------------
\* Checks (the verification surface)
\* ---------------------------------------------------------------------------

\* Inv1_1_RecordedFieldsKept: no step changes a recorded subscription's
\* subscription id, subscriber reference, event scope or subscription instant
\* (Invariant 1.1, Check 1.3).
Inv1_1_RecordedFieldsKept ==
    [][\A s \in Slots : held[s] =>
          (nid'[s] = nid[s] /\ sub'[s] = sub[s] /\ scp'[s] = scp[s] /\ sAt'[s] = sAt[s])]_vars

\* Inv2_2_NoReturnToActive: no step moves a cancelled subscription back to
\* active: a re-subscription is a second subscription, never the cancelled one
\* reopened (Invariant 2.2, Check 3.3).
Inv2_2_NoReturnToActive ==
    [][\A s \in Slots : (held[s] /\ st[s] = "cancelled") => st'[s] # "active"]_vars

\* Inv4_1_ResubscribeFreshId: a [Subscribe] that lands for a pair whose
\* earlier subscription is cancelled answers an id no subscription carried
\* before the call (Invariant 4.1, Check 4.1).
Inv4_1_ResubscribeFreshId ==
    [][(/\ last'.op = "subscribe" /\ last'.ans = "ok"
        /\ \E s \in Slots : held[s] /\ st[s] = "cancelled"
                            /\ sub[s] = last'.sub /\ scp[s] = last'.scp)
         => ~Known(last'.outId)]_vars

\* Inv4_2_StandIndependently: a [Subscribe] that lands for a pair whose
\* earlier subscription is cancelled leaves that earlier subscription in the
\* database as it stood, in a row of its own beside the new one (Invariant
\* 4.2).
Inv4_2_StandIndependently ==
    [][(last'.op = "subscribe" /\ last'.ans = "ok")
         => \A s \in Slots :
               (held[s] /\ st[s] = "cancelled" /\ sub[s] = last'.sub /\ scp[s] = last'.scp)
                  => (/\ held'[s] /\ s # last'.slot
                      /\ nid'[s] = nid[s] /\ st'[s] = st[s]
                      /\ sAt'[s] = sAt[s] /\ cAt'[s] = cAt[s])]_vars

\* Inv5_1_NoSharedId: no two subscriptions in the database share a
\* subscription id, a cancelled one and its re-subscription included
\* (Invariant 5.1, Identity 4, 5, Check 4.1).
Inv5_1_NoSharedId ==
    \A s, t \in Slots : (s # t /\ held[s] /\ held[t]) => nid[s] # nid[t]

\* Inv6_1_OneActivePerPair: no two active subscriptions share a pair, in
\* every state the calls reach (Invariant 6.1, Check 2.1; the Alloy model's
\* A_NoDualActiveForSameKey states it of one state).
Inv6_1_OneActivePerPair ==
    \A s, t \in Slots :
        (s # t /\ held[s] /\ held[t] /\ st[s] = "active" /\ st[t] = "active")
            => ~(sub[s] = sub[t] /\ scp[s] = scp[t])

\* Inv7_1_SubscribedRestsOnActiveSet: a [Subscribed] answered subscribed
\* exactly when the active set holds the pair: its answer is the active set's
\* and nothing else's (Invariant 7.1).
Inv7_1_SubscribedRestsOnActiveSet ==
    last.op = "subscribed" => ((last.ans = "subscribed") = ActivePair(last.sub, last.scp))

\* Inv7_2_SubscribersForRestsOnActiveSet: a [Subscribers For] answered
\* exactly the subscriber references the active set gives for the scope
\* (Invariant 7.2).
Inv7_2_SubscribersForRestsOnActiveSet ==
    last.op = "subscribers_for" => last.refs = ActiveRefs(last.scp)

\* Inv8_1_NotSubscribedOnlyIfNone: a [Subscribed] answered not-subscribed
\* only where no active subscription carries the pair (Invariant 8.1).
Inv8_1_NotSubscribedOnlyIfNone ==
    (last.op = "subscribed" /\ last.ans = "not-subscribed") => ~ActivePair(last.sub, last.scp)

\* Inv9_1_CancelNotBeforeSubscribe: a cancellation instant, once stamped,
\* does not precede the subscription instant (Invariant 9.1, Check 1.2). It
\* rests on the clock never going backward, the deployment's (Logic
\* confinement 7), which the model's clock honours as its input.
Inv9_1_CancelNotBeforeSubscribe ==
    \A s \in Slots : (held[s] /\ cAt[s] # Blank) => cAt[s] >= sAt[s]

\* Id2_SeamIdRecorded: an admitted [Subscribe] wrote the id the seam supplied
\* it onto the subscription it recorded, never one the atom made (Identity 2).
Id2_SeamIdRecorded ==
    (last.op = "subscribe" /\ last.ans = "ok")
        => (last.slot \in Slots /\ held[last.slot] /\ nid[last.slot] = last.id)

\* State3_CancelledCarriesInstant: every cancelled subscription carries its
\* cancellation instant (State 3, Check 3.1; the Alloy model's
\* A_CancelledHasCancelledAt states it of one state).
State3_CancelledCarriesInstant ==
    \A s \in Slots : (held[s] /\ st[s] = "cancelled") => cAt[s] # Blank

\* State4_SubscribeFromNow: an admitted [Subscribe] stamps the subscription
\* instant from the clock reading of the call (State 4).
State4_SubscribeFromNow ==
    [][(last'.op = "subscribe" /\ last'.ans = "ok")
         => (last'.slot \in Slots /\ sAt'[last'.slot] = now)]_vars

\* State5_CancelFromNow: a [Cancel] that answers ok stamps the cancellation
\* instant from the clock reading of the call (State 5).
State5_CancelFromNow ==
    [][(last'.op = "cancel" /\ last'.ans = "ok")
         => (last'.slot \in Slots /\ cAt'[last'.slot] = now)]_vars

\* State7_NoSubscriptionDeleted: no step removes a subscription from the
\* database: every id a subscription carried is still carried after the step,
\* cancelled ones included (State 7).
State7_NoSubscriptionDeleted ==
    [][\A i \in 1..MaxIds : Known(i) => KnownAfter(i)]_vars

\* Op1_OneRecordPerSubscribe: a [Subscribe] that answers ok records exactly
\* one new subscription (Operation 1).
Op1_OneRecordPerSubscribe ==
    [][(last'.op = "subscribe" /\ last'.ans = "ok")
         => Cardinality({s \in Slots : held'[s] /\ ~held[s]}) = 1]_vars

\* Op2_SubscribeStandsActive: a [Subscribe] that answered ok left the
\* subscription it recorded standing in active (Operation 2).
Op2_SubscribeStandsActive ==
    (last.op = "subscribe" /\ last.ans = "ok")
        => (last.slot \in Slots /\ st[last.slot] = "active")

\* Op3_SubscribeAnswersId: a [Subscribe] that answered ok answered the
\* subscription id of the subscription it recorded (Operation 3).
Op3_SubscribeAnswersId ==
    (last.op = "subscribe" /\ last.ans = "ok")
        => (last.outId # NoId /\ last.slot \in Slots /\ last.outId = nid[last.slot])

\* Op4_BlankSubscriberRefused: a [Subscribe] carrying a blank subscriber
\* reference answered invalid-request (Operation 4).
Op4_BlankSubscriberRefused ==
    (last.op = "subscribe" /\ last.sub = "") => last.ans = "invalid-request"

\* Op5_BlankScopeRefused: a [Subscribe] carrying a blank event scope answered
\* invalid-request (Operation 5).
Op5_BlankScopeRefused ==
    (last.op = "subscribe" /\ last.scp = "") => last.ans = "invalid-request"

\* Op6_ActivePairRefused: a [Subscribe] it admits as input, for a pair that
\* had an active subscription when the call was made, answers
\* already-subscribed (Operation 6).
Op6_ActivePairRefused ==
    [][(/\ last'.op = "subscribe" /\ Valid(last'.sub) /\ Valid(last'.scp)
        /\ ActivePair(last'.sub, last'.scp))
         => last'.ans = "already-subscribed"]_vars

\* Op7_SubscriberKeptAsGiven: a [Subscribe] that answered ok recorded the
\* subscriber reference exactly as the call carried it: the atom interprets
\* it no further (Operation 7; canonicalizing is the deployment's, at the
\* seam, Execution Contract Logic confinement 13).
Op7_SubscriberKeptAsGiven ==
    (last.op = "subscribe" /\ last.ans = "ok")
        => (last.slot \in Slots /\ sub[last.slot] = last.sub)

\* Op8_ScopeKeptAsGiven: a [Subscribe] that answered ok recorded the event
\* scope exactly as the call carried it (Operation 8).
Op8_ScopeKeptAsGiven ==
    (last.op = "subscribe" /\ last.ans = "ok")
        => (last.slot \in Slots /\ scp[last.slot] = last.scp)

\* Op9_UnknownIdNotKnown: a [Cancel] naming an id no subscription carried
\* answers not-known (Operation 9).
Op9_UnknownIdNotKnown ==
    [][(last'.op = "cancel" /\ ~Known(last'.id)) => last'.ans = "not-known"]_vars

\* Op10_CancelledNotActive: a [Cancel] naming a subscription whose status was
\* cancelled answers not-active (Operation 10).
Op10_CancelledNotActive ==
    [][(last'.op = "cancel" /\ \E s \in Slots : held[s] /\ nid[s] = last'.id /\ st[s] = "cancelled")
         => last'.ans = "not-active"]_vars

\* Op11_CancelStandsCancelled: a [Cancel] that answers ok stands the
\* subscription its id names in cancelled (Operation 11).
Op11_CancelStandsCancelled ==
    [][(last'.op = "cancel" /\ last'.ans = "ok")
         => \E s \in Slots : held'[s] /\ nid'[s] = last'.id /\ st'[s] = "cancelled"]_vars

\* Op12_IdWholeAuthorization: a [Cancel] naming an active subscription's id,
\* the database accepting, lands, whoever made the call: the id is the whole
\* authorization (Operation 12, Cancel capability 1, Non-goal 15).
Op12_IdWholeAuthorization ==
    [][(/\ last'.op = "cancel" /\ last'.db # "refused"
        /\ \E s \in Slots : held[s] /\ nid[s] = last'.id /\ st[s] = "active")
         => last'.ans = "ok"]_vars

\* Op13_SubscribeStorageFailure: a [Subscribe] whose write the database
\* refused answered storage-failure (Operation 13).
Op13_SubscribeStorageFailure ==
    (last.op = "subscribe" /\ last.db = "refused") => last.ans = "storage-failure"

\* Op14_CancelStorageFailure: a [Cancel] whose write the database refused
\* answered storage-failure (Operation 14).
Op14_CancelStorageFailure ==
    (last.op = "cancel" /\ last.db = "refused") => last.ans = "storage-failure"

\* Op16_SubscribedAnswersOneOfTwo: a [Subscribed] answered subscribed or
\* not-subscribed, and nothing else (Operation 16).
Op16_SubscribedAnswersOneOfTwo ==
    last.op = "subscribed" => last.ans \in {"subscribed", "not-subscribed"}

\* Op17_SubscribedOnlyIfActive: a [Subscribed] answered subscribed only where
\* an active subscription carries the pair (Operation 17).
Op17_SubscribedOnlyIfActive ==
    (last.op = "subscribed" /\ last.ans = "subscribed") => ActivePair(last.sub, last.scp)

\* Op18_SubscribedRefusesNoBlank: a [Subscribed] carrying a blank subscriber
\* reference or event scope answered, without refusing (Operation 18).
Op18_SubscribedRefusesNoBlank ==
    (last.op = "subscribed" /\ (last.sub = "" \/ last.scp = "")) => last.ans \notin Refusals

\* Op19_SubscribersForAnswersEvery: a [Subscribers For] answered the
\* subscriber reference of every active subscription matching the scope
\* (Operation 19).
Op19_SubscribersForAnswersEvery ==
    last.op = "subscribers_for" => ActiveRefs(last.scp) \subseteq last.refs

\* Op20_SubscribersForOnlyActive: a [Subscribers For] answered a subscriber
\* reference only where an active subscription matching the scope carries it
\* (Operation 20, Check 3.2).
Op20_SubscribersForOnlyActive ==
    last.op = "subscribers_for" => last.refs \subseteq ActiveRefs(last.scp)

\* Op22_NoActiveEmptyList: a [Subscribers For] of a scope no active
\* subscription matches — never subscribed, blank, or all cancelled —
\* answered the empty list (Operation 22).
Op22_NoActiveEmptyList ==
    (last.op = "subscribers_for" /\ ActiveRefs(last.scp) = {}) => last.refs = {}

\* Op24_SubscribedWritesNothing: a [Subscribed] step writes no record and
\* changes no field (Operation 24).
Op24_SubscribedWritesNothing ==
    [][last'.op = "subscribed" => (wrote' = {} /\ UNCHANGED records)]_vars

\* Op25_SubscribersForWritesNothing: a [Subscribers For] step writes no
\* record and changes no field (Operation 25).
Op25_SubscribersForWritesNothing ==
    [][last'.op = "subscribers_for" => (wrote' = {} /\ UNCHANGED records)]_vars

\* Op29_OverCapRefused: a [Subscribe] carrying a subscriber reference or an
\* event scope over the string cap answered invalid-request (Operation 29).
Op29_OverCapRefused ==
    (last.op = "subscribe" /\ (last.sub \in OverCap \/ last.scp \in OverCap))
        => last.ans = "invalid-request"

\* Op30_MalformedRefused: a [Subscribe] carrying a malformed subscriber
\* reference or event scope answered invalid-request (Operation 30).
Op30_MalformedRefused ==
    (last.op = "subscribe" /\ (last.sub \in Malformed \/ last.scp \in Malformed))
        => last.ans = "invalid-request"

\* Op31_MalformedIdNotKnown: a [Cancel] carrying a malformed subscription id
\* answered not-known (Operation 31).
Op31_MalformedIdNotKnown ==
    (last.op = "cancel" /\ last.id = MalformedId) => last.ans = "not-known"

\* Op32_CancelAnswersOk: a [Cancel] that wrote the subscription answers ok
\* (Operation 32).
Op32_CancelAnswersOk ==
    [][(last'.op = "cancel" /\ wrote' # {}) => last'.ans = "ok"]_vars

\* NG16_CancelWritesOnlyItsId: a [Cancel] writes at most the one
\* subscription its id names, never another of the subscriber's or the
\* scope's: the atom identifies a subscription by its id and offers no bulk
\* cancel (Non-goal 16, Identity 1).
NG16_CancelWritesOnlyItsId ==
    [][last'.op = "cancel" =>
          (/\ wrote' \subseteq {s \in Slots : held[s] /\ nid[s] = last'.id}
           /\ \A s \in Slots : (held[s] /\ nid[s] # last'.id) => st'[s] = st[s])]_vars

\* Check1_1_AudienceReconstructs: the audience a [Subscribers For] answered
\* at the call's instant is the one an auditor reconstructs at that instant
\* from the stored subscription and cancellation instants, never from status
\* (Check 1.1, Term active at an instant).
Check1_1_AudienceReconstructs ==
    last.op = "subscribers_for" =>
        last.refs = {sub[s] : s \in {t \in Slots : held[t] /\ scp[t] = last.scp /\ ActiveAt(t, last.at)}}

====
