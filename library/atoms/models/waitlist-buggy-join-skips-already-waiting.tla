---- MODULE waitlist-buggy-join-skips-already-waiting ----
\* DELIBERATELY WRONG twin of waitlist.tla (unit: `atoms/waitlist.md formal layer`).
\*
\* INJECTED DEFECT: [Join] never looks for the person's waiting spot and records a second
\* one (Operation 10).
\*
\* BREAKS: Op10_AlreadyWaitingRefused.
\* Everything else is waitlist.tla as written; read its comments there.

EXTENDS Integers, FiniteSets

CONSTANTS
    Offerings,   \* the offering references a call may carry that are well-formed
    Persons,     \* the person references a call may carry that are well-formed
    Blanks,      \* blank strings a call may carry as either reference
    OverCaps,    \* tokens standing for strings over the string cap
    MaxW,        \* how many waitlist ids the seam can supply
    MaxS,        \* how many spot ids the seam can supply
    MaxTime      \* the clock's last reading

\* WIds, SIds: the waitlist ids and spot ids a call may name, and the seam
\* may supply.
WIds == 1..MaxW
SIds == 1..MaxS

\* Times: the clock readings the seam may inject as now.
Times == 1..MaxTime

\* OfferingIn, PersonIn: every value a call may carry as an offering
\* reference or a person reference, well-formed or not.
OfferingIn == Offerings \cup Blanks \cup OverCaps
PersonIn == Persons \cup Blanks \cup OverCaps

\* NoRef: a record's reference before it is recorded, and the reference of a
\* call that carries none.
NoRef == "none"

\* Ended: the spot states of an ended spot (Term ended spot).
Ended == {"called", "left", "unserved"}

\* WaitlistActions, SpotActions: the actions that name a waitlist, and those
\* that name a spot, by id (Term waitlist action, Term spot action).
WaitlistActions == {"join", "call_next", "close", "read_waitlist"}
SpotActions == {"leave", "read_spot"}

\* NoEntry, NoList: the shape of one waiting spot [Read Waitlist] answers, and
\* the empty list.
NoEntry == [sid |-> 0, per |-> NoRef, num |-> 0, inst |-> 0]
NoList == [k \in {} |-> NoEntry]

\* NoRS: the shape of what [Read Spot] answers, and its value when no spot
\* is read.
NoRS == [sid |-> 0, wid |-> 0, per |-> NoRef, num |-> 0, inst |-> 0, st |-> "none",
         hasAhead |-> FALSE, ahead |-> 0]

\* NoRW: the shape of what [Read Waitlist] answers, and its value when no
\* waitlist is read.
NoRW == [wid |-> 0, off |-> NoRef, st |-> "none", spots |-> NoList]

\* NoCall: the record of the last call before any call is made, and the shape
\* of every such record: the action; the waitlist id and spot id it named or
\* the seam supplied; the reference it carried; what it answered (a word, an
\* id, a person reference); and what a read answered. The now a [Join] was
\* given is read off the spot it recorded (the Alloy model checks Operation 13).
NoCall == [op |-> "none", w |-> 0, s |-> 0, ref |-> NoRef,
           ans |-> "none", id |-> 0, per |-> NoRef, rs |-> NoRS, rw |-> NoRW]

\* Bad, Good: whether a reference is blank or over the string cap, the
\* grounds of Operation 1 and 8.
Bad(x) == x \in Blanks \/ x \in OverCaps
Good(x) == ~Bad(x)

\* Fold: what a case-folding comparison would make of a reference. The page
\* forbids it (Identity 6 to 9): the model's own actions never apply it; it
\* is here so a twin can.
Fold(x) == CASE x = "Yoga-Sat" -> "yoga-sat"
             [] x = "Mo" -> "mo"
             [] OTHER -> x

\* ---------------------------------------------------------------------------
\* State
\* ---------------------------------------------------------------------------

VARIABLES
    wst,    \* waitlist id -> the waitlist state ("none" before it is recorded)
    woff,   \* waitlist id -> the offering reference (NoRef before it is recorded)
    sst,    \* spot id -> the spot state ("none" before it is recorded)
    swl,    \* spot id -> the spot's waitlist id (0 before it is recorded)
    sper,   \* spot id -> the spot's person reference (NoRef before it is recorded)
    snum,   \* spot id -> the spot's join number (0 before it is recorded)
    sinst,  \* spot id -> the spot's join instant (0 before it is recorded)
    last,   \* the last call made and what it answered (NoCall's shape)
    wrote   \* the records the last step wrote

\* vars: every variable; a step that changes none of them is a stutter.
vars == <<wst, woff, sst, swl, sper, snum, sinst, last, wrote>>

\* records: every variable that holds a record's fields.
records == <<wst, woff, sst, swl, sper, snum, sinst>>

\* Seen: what TLC compares to tell two states apart (the .cfg's VIEW): the
\* records, not the record of the last call. See the header's VIEW note.
Seen == records

\* spotFields: every variable that holds a spot's fields.
spotFields == <<sst, swl, sper, snum, sinst>>

\* OpenFor: an open waitlist stands for the offering reference, compared
\* codepoint for codepoint (Identity 7).
OpenFor(o) == \E w \in WIds : wst[w] = "open" /\ woff[w] = o

\* TheOpen: that open waitlist's id.
TheOpen(o) == CHOOSE w \in WIds : wst[w] = "open" /\ woff[w] = o

\* Of: the spots of a waitlist, ended ones included.
Of(w) == {s \in SIds : sst[s] # "none" /\ swl[s] = w}

\* WaitingOf: the waiting spots of a waitlist.
WaitingOf(w) == {s \in SIds : sst[s] = "waiting" /\ swl[s] = w}

\* WaitingFor: a waiting spot of the waitlist carries the person reference,
\* compared codepoint for codepoint (Identity 9).
WaitingFor(w, p) == \E s \in WaitingOf(w) : sper[s] = p

\* Highest: the greatest join number any spot of the waitlist carries, an
\* ended spot's included; zero for a waitlist carrying no spot (Term highest
\* join number).
Highest(w) == IF Of(w) = {} THEN 0
              ELSE CHOOSE n \in {snum[s] : s \in Of(w)} :
                     \A m \in {snum[s] : s \in Of(w)} : m <= n

\* NextNumber: highest + 1 (Term next join number).
NextNumber(w) == Highest(w) + 1

\* Front: the waiting spot of the waitlist carrying the lowest join number
\* among its waiting spots (Term front spot); read only where one waits.
Front(w) == CHOOSE f \in WaitingOf(w) : \A g \in WaitingOf(w) : snum[f] <= snum[g]

\* Ahead: the number of waiting spots of the spot's waitlist carrying a join
\* number below the spot's (Term ahead count).
Ahead(s) == Cardinality({g \in WaitingOf(swl[s]) : snum[g] < snum[s]})

\* Entry: what [Read Waitlist] answers of one waiting spot (Operation 34).
Entry(s) == [sid |-> s, per |-> sper[s], num |-> snum[s], inst |-> sinst[s]]

\* Before: the order [Read Waitlist] answers in, lowest join number first
\* (Operation 33); the spot id breaks a tie only a broken model can make.
Before(a, b) == \/ a.num < b.num
                \/ (a.num = b.num /\ a.sid < b.sid)

\* Sorted: a set of entries as a list, each placed after every entry Before it.
Sorted(S) == [k \in 1..Cardinality(S) |->
                CHOOSE e \in S : Cardinality({x \in S : Before(x, e)}) = k - 1]

\* TypeOK: each variable holds a value of its kind (the model's typing, not a
\* rule of the page).
TypeOK ==
    /\ wst \in [WIds -> {"none", "open", "closed"}]
    /\ woff \in [WIds -> OfferingIn \cup {NoRef}]
    /\ sst \in [SIds -> {"none", "waiting", "called", "left", "unserved"}]
    /\ swl \in [SIds -> 0..MaxW]
    /\ sper \in [SIds -> PersonIn \cup {NoRef}]
    /\ \A s \in SIds : snum[s] \in Int
    /\ sinst \in [SIds -> 0..MaxTime]
    /\ wrote \subseteq ({"waitlist"} \X WIds) \cup ({"spot"} \X SIds)

\* Init: no waitlist and no spot.
Init ==
    /\ wst = [w \in WIds |-> "none"]
    /\ woff = [w \in WIds |-> NoRef]
    /\ sst = [s \in SIds |-> "none"]
    /\ swl = [s \in SIds |-> 0]
    /\ sper = [s \in SIds |-> NoRef]
    /\ snum = [s \in SIds |-> 0]
    /\ sinst = [s \in SIds |-> 0]
    /\ last = NoCall
    /\ wrote = {}

\* ---------------------------------------------------------------------------
\* Actions
\* ---------------------------------------------------------------------------

\* StartBad: a [Start] whose offering reference is blank or over the string
\* cap answers invalid-offering-reference and writes nothing (Operation 1).
StartBad(o) ==
    /\ Bad(o)                                                  \* Operation 1
    /\ last' = [NoCall EXCEPT !.op = "start", !.ref = o, !.ans = "invalid-offering-reference"]
    /\ wrote' = {}
    /\ UNCHANGED records

\* StartFound: a [Start] for an offering reference an open waitlist stands
\* for answers that waitlist's id and writes nothing (Operation 2, 3).
StartFound(o) ==
    /\ Good(o)                                                 \* StartFound: well-formed
    /\ OpenFor(o)                                              \* StartFound: an open one stands
    /\ last' = [NoCall EXCEPT !.op = "start", !.ref = o, !.ans = "id", !.id = TheOpen(o)]
    /\ wrote' = {}
    /\ UNCHANGED records

\* StartRecords: a [Start] for an offering reference no open waitlist stands
\* for records one waitlist under the id w the seam supplies (one no
\* waitlist has carried), carrying the offering reference, open (Operation
\* 4, 5), and answers its id (Operation 6).
StartRecords(o, w) ==
    /\ Good(o)                                                 \* StartRecords: well-formed
    /\ ~OpenFor(o)                                             \* Operation 4: none open for it
    /\ wst[w] = "none"                                         \* the seam's fresh id
    /\ wst' = [wst EXCEPT ![w] = "open"]                       \* Operation 4, 5
    /\ woff' = [woff EXCEPT ![w] = o]                          \* Operation 4
    /\ wrote' = {<<"waitlist", w>>}
    /\ last' = [NoCall EXCEPT !.op = "start", !.ref = o, !.w = w, !.ans = "id", !.id = w]
    /\ UNCHANGED spotFields

\* JoinUnknown: a [Join] naming a waitlist id no waitlist carries answers
\* not-known and writes nothing, whatever person reference it carries
\* (Operation 7; not-known is listed first on the refuses line), so the
\* record keeps no reference.
JoinUnknown(w) ==
    /\ wst[w] = "none"
    /\ last' = [NoCall EXCEPT !.op = "join", !.w = w, !.ans = "not-known"]
    /\ wrote' = {}
    /\ UNCHANGED records

\* JoinBadPerson: a [Join] on a waitlist whose person reference is blank or
\* over the string cap answers invalid-person-reference and writes nothing
\* (Operation 8), the waitlist open or closed.
JoinBadPerson(w, p) ==
    /\ wst[w] # "none"
    /\ Bad(p)                                                  \* Operation 8
    /\ last' = [NoCall EXCEPT !.op = "join", !.w = w, !.ref = p, !.ans = "invalid-person-reference"]
    /\ wrote' = {}
    /\ UNCHANGED records

\* JoinClosed: a [Join] on a closed waitlist answers waitlist-closed and
\* writes nothing (Operation 9).
JoinClosed(w, p) ==
    /\ wst[w] = "closed"
    /\ Good(p)                                                 \* JoinClosed: well-formed
    /\ last' = [NoCall EXCEPT !.op = "join", !.w = w, !.ref = p, !.ans = "waitlist-closed"]
    /\ wrote' = {}
    /\ UNCHANGED records

\* JoinAlready: a [Join] of a person reference a waiting spot of the open
\* waitlist carries answers already-waiting and writes nothing (Operation
\* 10); the person keeps the spot already held.
JoinAlready(w, p) ==
    /\ wst[w] = "open"                                         \* JoinAlready: open
    /\ Good(p)                                                 \* JoinAlready: well-formed
    /\ WaitingFor(w, p)                                        \* Operation 10
    /\ last' = [NoCall EXCEPT !.op = "join", !.w = w, !.ref = p, !.ans = "already-waiting"]
    /\ wrote' = {}
    /\ UNCHANGED records

\* JoinRecords: an admitted [Join] records one spot under the id s the seam
\* supplies (one no spot has carried), carrying the waitlist id and person
\* reference of the call (Operation 11), the next join number (Operation
\* 12), the injected now t (Operation 13), waiting (Operation 14), and
\* answers its spot id (Operation 15).
JoinRecords(w, p, s, t) ==
    /\ wst[w] = "open"                                         \* Operation 9: open
    /\ Good(p)                                                 \* JoinRecords: well-formed
    /\ TRUE                                                    \* BUG: no look for a waiting spot
    /\ sst[s] = "none"                                         \* the seam's fresh id
    /\ sst' = [sst EXCEPT ![s] = "waiting"]                    \* Operation 14
    /\ swl' = [swl EXCEPT ![s] = w]                            \* Operation 11
    /\ sper' = [sper EXCEPT ![s] = p]                          \* Operation 11
    /\ snum' = [snum EXCEPT ![s] = NextNumber(w)]              \* Operation 12
    /\ sinst' = [sinst EXCEPT ![s] = t]                        \* Operation 13
    /\ wrote' = {<<"spot", s>>}
    /\ last' = [NoCall EXCEPT !.op = "join", !.w = w, !.s = s, !.ref = p,
                              !.ans = "id", !.id = s]         \* Operation 15
    /\ UNCHANGED <<wst, woff>>

\* LeaveUnknown: a [Leave] naming a spot id no spot carries answers
\* not-known and writes nothing (Operation 16).
LeaveUnknown(s) ==
    /\ sst[s] = "none"
    /\ last' = [NoCall EXCEPT !.op = "leave", !.s = s, !.ans = "not-known"]
    /\ wrote' = {}
    /\ UNCHANGED records

\* LeaveEnded: a [Leave] of an ended spot answers not-waiting and writes
\* nothing (Operation 17).
LeaveEnded(s) ==
    /\ sst[s] \in Ended
    /\ last' = [NoCall EXCEPT !.op = "leave", !.s = s, !.ans = "not-waiting"]
    /\ wrote' = {}
    /\ UNCHANGED records

\* LeaveLeaves: a [Leave] of a waiting spot stands it in left (Operation 18)
\* and answers ok (Operation 19). The now t is given; nothing reads it.
LeaveLeaves(s, t) ==
    /\ sst[s] = "waiting"
    /\ sst' = [sst EXCEPT ![s] = "left"]                       \* Operation 18
    /\ wrote' = {<<"spot", s>>}
    /\ last' = [NoCall EXCEPT !.op = "leave", !.s = s, !.ans = "ok"]
    /\ UNCHANGED <<wst, woff, swl, sper, snum, sinst>>

\* CallNextUnknown: a [Call Next] naming a waitlist id no waitlist carries
\* answers not-known and writes nothing (Operation 7).
CallNextUnknown(w) ==
    /\ wst[w] = "none"
    /\ last' = [NoCall EXCEPT !.op = "call_next", !.w = w, !.ans = "not-known"]
    /\ wrote' = {}
    /\ UNCHANGED records

\* CallNextClosed: a [Call Next] on a closed waitlist answers waitlist-closed
\* and writes nothing (Operation 20).
CallNextClosed(w) ==
    /\ wst[w] = "closed"
    /\ last' = [NoCall EXCEPT !.op = "call_next", !.w = w, !.ans = "waitlist-closed"]
    /\ wrote' = {}
    /\ UNCHANGED records

\* CallNextEmpty: a [Call Next] on an open waitlist with no waiting spot
\* answers nobody-waiting and writes nothing (Operation 21).
CallNextEmpty(w) ==
    /\ wst[w] = "open"
    /\ WaitingOf(w) = {}
    /\ last' = [NoCall EXCEPT !.op = "call_next", !.w = w, !.ans = "nobody-waiting"]
    /\ wrote' = {}
    /\ UNCHANGED records

\* CallNextCalls: a [Call Next] on an open waitlist with someone waiting
\* stands the front spot in called (Operation 22), changes no other spot
\* (Operation 24), and answers the spot id and person reference of the
\* front spot as the waitlist stood before that write (Operation 23): f is
\* read in the state the call found.
CallNextCalls(w) ==
    /\ wst[w] = "open"
    /\ WaitingOf(w) # {}
    /\ LET f == Front(w) IN                                    \* Operation 22: the front spot
         /\ sst' = [sst EXCEPT ![f] = "called"]                \* Operation 22
         /\ wrote' = {<<"spot", f>>}
         /\ last' = [NoCall EXCEPT !.op = "call_next", !.w = w, !.ans = "spot",
                                   !.id = f, !.per = sper[f]]  \* Operation 23
    /\ UNCHANGED <<wst, woff, swl, sper, snum, sinst>>         \* Operation 24

\* CloseUnknown: a [Close] naming a waitlist id no waitlist carries answers
\* not-known and writes nothing (Operation 7).
CloseUnknown(w) ==
    /\ wst[w] = "none"
    /\ last' = [NoCall EXCEPT !.op = "close", !.w = w, !.ans = "not-known"]
    /\ wrote' = {}
    /\ UNCHANGED records

\* CloseClosed: a [Close] on a closed waitlist answers waitlist-closed and
\* writes nothing (Operation 25).
CloseClosed(w) ==
    /\ wst[w] = "closed"
    /\ last' = [NoCall EXCEPT !.op = "close", !.w = w, !.ans = "waitlist-closed"]
    /\ wrote' = {}
    /\ UNCHANGED records

\* CloseCloses: a [Close] on an open waitlist stands it in closed (Operation
\* 26) and every spot waiting on it in unserved (Operation 27), in one
\* transaction (Execution Contract Database 1), and answers ok (Operation 28).
CloseCloses(w) ==
    /\ wst[w] = "open"
    /\ wst' = [wst EXCEPT ![w] = "closed"]                     \* Operation 26
    /\ sst' = [s \in SIds |-> IF s \in WaitingOf(w) THEN "unserved" ELSE sst[s]]  \* Operation 27
    /\ wrote' = {<<"waitlist", w>>} \cup {<<"spot", s>> : s \in WaitingOf(w)}
    /\ last' = [NoCall EXCEPT !.op = "close", !.w = w, !.ans = "ok"]               \* Operation 28
    /\ UNCHANGED <<woff, swl, sper, snum, sinst>>

\* ReadSpotUnknown: a [Read Spot] naming a spot id no spot carries answers
\* not-known (Operation 16).
ReadSpotUnknown(s) ==
    /\ sst[s] = "none"
    /\ last' = [NoCall EXCEPT !.op = "read_spot", !.s = s, !.ans = "not-known"]
    /\ wrote' = {}
    /\ UNCHANGED records

\* ReadSpotKnown: a [Read Spot] answers the spot's spot id, waitlist id,
\* person reference, join number, join instant and spot state (Operation
\* 29), its ahead count where it is waiting (Operation 30), and writes
\* nothing (Operation 31).
ReadSpotKnown(s) ==
    /\ sst[s] # "none"
    /\ last' = [NoCall EXCEPT !.op = "read_spot", !.s = s, !.ans = "spot",
                  !.rs = [sid |-> s, wid |-> swl[s], per |-> sper[s], num |-> snum[s],
                          inst |-> sinst[s], st |-> sst[s],                       \* Operation 29
                          hasAhead |-> (sst[s] = "waiting"),
                          ahead |-> IF sst[s] = "waiting" THEN Ahead(s) ELSE 0]] \* Operation 30
    /\ wrote' = {}                                             \* Operation 31
    /\ UNCHANGED records

\* ReadWaitlistUnknown: a [Read Waitlist] naming a waitlist id no waitlist
\* carries answers not-known (Operation 7).
ReadWaitlistUnknown(w) ==
    /\ wst[w] = "none"
    /\ last' = [NoCall EXCEPT !.op = "read_waitlist", !.w = w, !.ans = "not-known"]
    /\ wrote' = {}
    /\ UNCHANGED records

\* ReadWaitlistKnown: a [Read Waitlist] answers the waitlist's waitlist id,
\* offering reference and waitlist state (Operation 32), and every waiting
\* spot of it, lowest join number first (Operation 33), and no spot other
\* than a waiting spot of it (Operation 36), each with its spot id, person
\* reference, join number and join instant (Operation 34), and writes
\* nothing (Operation 35).
ReadWaitlistKnown(w) ==
    /\ wst[w] # "none"
    /\ last' = [NoCall EXCEPT !.op = "read_waitlist", !.w = w, !.ans = "waitlist",
                  !.rw = [wid |-> w, off |-> woff[w], st |-> wst[w],                \* Operation 32
                          spots |-> Sorted({Entry(s) : s \in WaitingOf(w)})]]     \* Operation 33, 36
    /\ wrote' = {}                                             \* Operation 35
    /\ UNCHANGED records

\* Next: any call of the seven actions, admitted or refused as the page says.
Next ==
    \/ \E o \in OfferingIn : StartBad(o)
    \/ \E o \in OfferingIn : StartFound(o)
    \/ \E o \in OfferingIn, w \in WIds : StartRecords(o, w)
    \/ \E w \in WIds : JoinUnknown(w)
    \/ \E w \in WIds, p \in PersonIn : JoinBadPerson(w, p)
    \/ \E w \in WIds, p \in PersonIn : JoinClosed(w, p)
    \/ \E w \in WIds, p \in PersonIn : JoinAlready(w, p)
    \/ \E w \in WIds, p \in PersonIn, s \in SIds, t \in Times : JoinRecords(w, p, s, t)
    \/ \E s \in SIds : LeaveUnknown(s)
    \/ \E s \in SIds : LeaveEnded(s)
    \/ \E s \in SIds, t \in Times : LeaveLeaves(s, t)
    \/ \E w \in WIds : CallNextUnknown(w)
    \/ \E w \in WIds : CallNextClosed(w)
    \/ \E w \in WIds : CallNextEmpty(w)
    \/ \E w \in WIds : CallNextCalls(w)
    \/ \E w \in WIds : CloseUnknown(w)
    \/ \E w \in WIds : CloseClosed(w)
    \/ \E w \in WIds : CloseCloses(w)
    \/ \E s \in SIds : ReadSpotUnknown(s)
    \/ \E s \in SIds : ReadSpotKnown(s)
    \/ \E w \in WIds : ReadWaitlistUnknown(w)
    \/ \E w \in WIds : ReadWaitlistKnown(w)

\* Spec: every behaviour from Init by Next steps.
Spec == Init /\ [][Next]_vars

\* ---------------------------------------------------------------------------
\* Checks (the verification surface)
\* ---------------------------------------------------------------------------

\* Quiet: the step writes no record and changes no field of any record: the
\* case table's effect "none".
Quiet == wrote' = {} /\ UNCHANGED records

\* NewWaitlists, NewSpots: the records the step recorded.
NewWaitlists == {w \in WIds : wst[w] = "none" /\ wst'[w] # "none"}
NewSpots == {s \in SIds : sst[s] = "none" /\ sst'[s] # "none"}

\* JoinAdmitted: no refusal on [Join]'s refuses line applies to a call on
\* waitlist w carrying person reference p.
JoinAdmitted(w, p) == wst[w] = "open" /\ Good(p) /\ ~WaitingFor(w, p)

\* CallNextAdmitted: no refusal on [Call Next]'s refuses line applies.
CallNextAdmitted(w) == wst[w] = "open" /\ WaitingOf(w) # {}

\* State5_NoWaitlistRemoved: no step removes a waitlist, a closed one
\* included (State 5).
State5_NoWaitlistRemoved ==
    [][\A w \in WIds : wst[w] # "none" => wst'[w] # "none"]_vars

\* State6_NoSpotRemoved: no step removes a spot, an ended one included: a
\* person who leaves leaves a record that they did (State 6).
State6_NoSpotRemoved ==
    [][\A s \in SIds : sst[s] # "none" => sst'[s] # "none"]_vars

\* Inv1_2_OnlyFrontCalled: no step stands a spot in called unless it was the
\* front spot of its waitlist: the waiting spot with the lowest join number,
\* whatever the join instants say (Invariant 1.2).
Inv1_2_OnlyFrontCalled ==
    [][\A s \in SIds : (sst[s] # "called" /\ sst'[s] = "called")
         => (sst[s] = "waiting"
             /\ \A g \in WaitingOf(swl[s]) : snum[s] <= snum[g])]_vars

\* Inv1_3_JoinNumberKept: no step changes a spot's join number, so the line
\* never closes up by renumbering (Invariant 1.3).
Inv1_3_JoinNumberKept ==
    [][\A s \in SIds : sst[s] # "none" => snum'[s] = snum[s]]_vars

\* Inv3_1_WaitlistKept: no step changes a spot's waitlist id: a spot is never
\* moved to another waitlist (Invariant 3.1, Non-goal 21).
Inv3_1_WaitlistKept ==
    [][\A s \in SIds : sst[s] # "none" => swl'[s] = swl[s]]_vars

\* Inv3_2_PersonKept: no step changes a spot's person reference (Invariant
\* 3.2).
Inv3_2_PersonKept ==
    [][\A s \in SIds : sst[s] # "none" => sper'[s] = sper[s]]_vars

\* Inv3_3_JoinInstantKept: no step changes a spot's join instant (Invariant
\* 3.3).
Inv3_3_JoinInstantKept ==
    [][\A s \in SIds : sst[s] # "none" => sinst'[s] = sinst[s]]_vars

\* Inv4_1_EndedStaysEnded: no step changes the spot state of a called, left
\* or unserved spot: the atom never puts a called person back in line
\* (Invariant 4.1).
Inv4_1_EndedStaysEnded ==
    [][\A s \in SIds : sst[s] \in Ended => sst'[s] = sst[s]]_vars

\* Inv5_1_ClosedStaysClosed: no step changes the waitlist state of a closed
\* waitlist: a waitlist closed by mistake is started again as a new one
\* (Invariant 5.1, What undoes a write).
Inv5_1_ClosedStaysClosed ==
    [][\A w \in WIds : wst[w] = "closed" => wst'[w] = "closed"]_vars

\* Inv7_1_OfferingKept: no step changes a waitlist's offering reference
\* (Invariant 7.1).
Inv7_1_OfferingKept ==
    [][\A w \in WIds : wst[w] # "none" => woff'[w] = woff[w]]_vars

\* Op1_InvalidOfferingRefused: a [Start] whose offering reference is blank or
\* over the string cap answered invalid-offering-reference and wrote
\* nothing: start("   ") (Operation 1).
Op1_InvalidOfferingRefused ==
    [][(last'.op = "start" /\ Bad(last'.ref))
         => (last'.ans = "invalid-offering-reference" /\ Quiet)]_vars

\* Op2_StartAnswersOpen: a [Start] for a well-formed offering reference an
\* open waitlist stands for answered that waitlist's id: the shop's restart
\* (Operation 2, Identity 7).
Op2_StartAnswersOpen ==
    [][(last'.op = "start" /\ Good(last'.ref) /\ OpenFor(last'.ref))
         => (last'.ans = "id" /\ last'.id \in WIds
             /\ wst[last'.id] = "open" /\ woff[last'.id] = last'.ref)]_vars

\* Op3_StartOpenWritesNothing: such a [Start] wrote nothing (Operation 3).
Op3_StartOpenWritesNothing ==
    [][(last'.op = "start" /\ Good(last'.ref) /\ OpenFor(last'.ref)) => Quiet]_vars

\* Op4_StartRecordsOne: a [Start] for a well-formed offering reference no
\* open waitlist stands for, compared codepoint for codepoint, recorded
\* exactly one waitlist, under the id the seam supplied, carrying the
\* offering reference of the call (Operation 4, Identity 7).
Op4_StartRecordsOne ==
    [][(last'.op = "start" /\ Good(last'.ref) /\ ~OpenFor(last'.ref))
         => (NewWaitlists = {last'.w} /\ woff'[last'.w] = last'.ref)]_vars

\* Op6_StartAnswersNew: such a [Start] answered the recorded waitlist's id
\* (Operation 6).
Op6_StartAnswersNew ==
    [][(last'.op = "start" /\ Good(last'.ref) /\ ~OpenFor(last'.ref))
         => (last'.ans = "id" /\ last'.id = last'.w)]_vars

\* Op7_UnknownWaitlistNotKnown: a [Join], [Call Next], [Close] or [Read
\* Waitlist] naming a waitlist id no waitlist carries answered not-known and
\* wrote nothing: join(w404, "mo") (Operation 7).
Op7_UnknownWaitlistNotKnown ==
    [][(last'.op \in WaitlistActions /\ wst[last'.w] = "none")
         => (last'.ans = "not-known" /\ Quiet)]_vars

\* Op8_InvalidPersonRefused: a [Join] on a waitlist, open or closed, whose
\* person reference is blank or over the string cap answered
\* invalid-person-reference and wrote nothing: join(w12, "") (Operation 8).
Op8_InvalidPersonRefused ==
    [][(last'.op = "join" /\ wst[last'.w] # "none" /\ Bad(last'.ref))
         => (last'.ans = "invalid-person-reference" /\ Quiet)]_vars

\* Op9_JoinClosedRefused: a [Join] of a well-formed person reference on a
\* closed waitlist answered waitlist-closed and wrote nothing (Operation 9).
Op9_JoinClosedRefused ==
    [][(last'.op = "join" /\ wst[last'.w] = "closed" /\ Good(last'.ref))
         => (last'.ans = "waitlist-closed" /\ Quiet)]_vars

\* Op10_AlreadyWaitingRefused: a [Join] on an open waitlist of a person
\* reference a waiting spot of it carries answered already-waiting and wrote
\* nothing: the second join(w12, "mo") (Operation 10, Identity 9).
Op10_AlreadyWaitingRefused ==
    [][(last'.op = "join" /\ wst[last'.w] = "open" /\ Good(last'.ref)
            /\ WaitingFor(last'.w, last'.ref))
         => (last'.ans = "already-waiting" /\ Quiet)]_vars

\* Op11_JoinRecordsOne: a [Join] no refusal applies to recorded exactly one
\* spot, under the id the seam supplied, carrying the waitlist id and person
\* reference of the call: join(w12, "Mo") beside a waiting "mo" (Operation
\* 11, Identity 9).
Op11_JoinRecordsOne ==
    [][(last'.op = "join" /\ JoinAdmitted(last'.w, last'.ref))
         => (NewSpots = {last'.s} /\ swl'[last'.s] = last'.w
             /\ sper'[last'.s] = last'.ref)]_vars

\* Op12_JoinNumberNext: the spot such a [Join] recorded carries one more than
\* the waitlist's highest join number, an ended spot's included: Ana's 4
\* behind Cara's 3 (Operation 12).
Op12_JoinNumberNext ==
    [][(last'.op = "join" /\ JoinAdmitted(last'.w, last'.ref))
         => \A s \in NewSpots : snum'[s] = NextNumber(last'.w)]_vars

\* Op15_JoinAnswersSpotId: such a [Join] answered the recorded spot's id
\* (Operation 15).
Op15_JoinAnswersSpotId ==
    [][(last'.op = "join" /\ JoinAdmitted(last'.w, last'.ref))
         => (last'.ans = "id" /\ last'.id \in NewSpots)]_vars

\* Op16_UnknownSpotNotKnown: a [Leave] or [Read Spot] naming a spot id no
\* spot carries answered not-known and wrote nothing: leave(s-0000)
\* (Operation 16).
Op16_UnknownSpotNotKnown ==
    [][(last'.op \in SpotActions /\ sst[last'.s] = "none")
         => (last'.ans = "not-known" /\ Quiet)]_vars

\* Op17_NotWaitingRefused: a [Leave] of a called, left or unserved spot
\* answered not-waiting and wrote nothing: the second leave(s-Aq31)
\* (Operation 17).
Op17_NotWaitingRefused ==
    [][(last'.op = "leave" /\ sst[last'.s] \in Ended)
         => (last'.ans = "not-waiting" /\ Quiet)]_vars

\* Op18_LeaveStandsLeft: a [Leave] of a waiting spot left it standing in
\* left (Operation 18).
Op18_LeaveStandsLeft ==
    [][(last'.op = "leave" /\ sst[last'.s] = "waiting") => sst'[last'.s] = "left"]_vars

\* Op19_LeaveAnswersOk: a [Leave] of a waiting spot answered ok (Operation
\* 19).
Op19_LeaveAnswersOk ==
    [][(last'.op = "leave" /\ sst[last'.s] = "waiting") => last'.ans = "ok"]_vars

\* Op20_CallNextClosedRefused: a [Call Next] on a closed waitlist answered
\* waitlist-closed and wrote nothing (Operation 20).
Op20_CallNextClosedRefused ==
    [][(last'.op = "call_next" /\ wst[last'.w] = "closed")
         => (last'.ans = "waitlist-closed" /\ Quiet)]_vars

\* Op21_NobodyWaitingRefused: a [Call Next] on an open waitlist with no
\* waiting spot answered nobody-waiting and wrote nothing: call_next(w9) on
\* the size-43 list (Operation 21).
Op21_NobodyWaitingRefused ==
    [][(last'.op = "call_next" /\ wst[last'.w] = "open" /\ WaitingOf(last'.w) = {})
         => (last'.ans = "nobody-waiting" /\ Quiet)]_vars

\* Op22_CallNextCallsFront: a [Call Next] no refusal applies to left the
\* front spot standing in called (Operation 22).
Op22_CallNextCallsFront ==
    [][(last'.op = "call_next" /\ CallNextAdmitted(last'.w))
         => sst'[Front(last'.w)] = "called"]_vars

\* Op23_CallNextAnswersFront: such a [Call Next] answered the spot id and
\* person reference of the front spot as the waitlist stood before the write
\* of Operation 22, the spot it called and not the next one in line:
\* call_next(w1) answers s-9fQ2 and "ana", not Cara's spot (Operation 23).
\* Front and sper are read unprimed, in the state before the step.
Op23_CallNextAnswersFront ==
    [][(last'.op = "call_next" /\ CallNextAdmitted(last'.w))
         => (last'.ans = "spot" /\ last'.id = Front(last'.w)
             /\ last'.per = sper[Front(last'.w)])]_vars

\* Op24_CallNextChangesOnlyFront: such a [Call Next] changed no field of a
\* spot other than the front spot (Operation 24).
Op24_CallNextChangesOnlyFront ==
    [][(last'.op = "call_next" /\ CallNextAdmitted(last'.w))
         => \A s \in SIds \ {Front(last'.w)} :
              /\ sst'[s] = sst[s] /\ swl'[s] = swl[s] /\ sper'[s] = sper[s]
              /\ snum'[s] = snum[s] /\ sinst'[s] = sinst[s]]_vars

\* Op25_CloseClosedRefused: a [Close] on a closed waitlist answered
\* waitlist-closed and wrote nothing: the second close(w12) (Operation 25).
Op25_CloseClosedRefused ==
    [][(last'.op = "close" /\ wst[last'.w] = "closed")
         => (last'.ans = "waitlist-closed" /\ Quiet)]_vars

\* Op26_CloseStandsClosed: a [Close] on an open waitlist left it standing in
\* closed (Operation 26).
Op26_CloseStandsClosed ==
    [][(last'.op = "close" /\ wst[last'.w] = "open") => wst'[last'.w] = "closed"]_vars

\* Op27_CloseUnservesWaiting: such a [Close] left every spot then waiting on
\* the waitlist standing in unserved: Cara's and Ana's spots when the class
\* started (Operation 27).
Op27_CloseUnservesWaiting ==
    [][(last'.op = "close" /\ wst[last'.w] = "open")
         => \A s \in WaitingOf(last'.w) : sst'[s] = "unserved"]_vars

\* Op28_CloseAnswersOk: such a [Close] answered ok (Operation 28).
Op28_CloseAnswersOk ==
    [][(last'.op = "close" /\ wst[last'.w] = "open") => last'.ans = "ok"]_vars

\* Op29_ReadSpotFields: a [Read Spot] of a spot answered its spot id,
\* waitlist id, person reference, join number, join instant and spot state
\* (Operation 29).
Op29_ReadSpotFields ==
    [][(last'.op = "read_spot" /\ sst[last'.s] # "none")
         => (last'.ans = "spot" /\ last'.rs.sid = last'.s /\ last'.rs.wid = swl[last'.s]
             /\ last'.rs.per = sper[last'.s] /\ last'.rs.num = snum[last'.s]
             /\ last'.rs.inst = sinst[last'.s] /\ last'.rs.st = sst[last'.s])]_vars

\* Op30_ReadSpotAheadCount: a [Read Spot] of a waiting spot answered its
\* ahead count, the waiting spots of its waitlist below its join number:
\* Cara's 1 once Ben has left (Operation 30, Term ahead count).
Op30_ReadSpotAheadCount ==
    [][(last'.op = "read_spot" /\ sst[last'.s] = "waiting")
         => (last'.rs.hasAhead /\ last'.rs.ahead = Ahead(last'.s))]_vars

\* Op31_ReadSpotWritesNothing: a [Read Spot] step wrote nothing (Operation 31).
Op31_ReadSpotWritesNothing ==
    [][last'.op = "read_spot" => Quiet]_vars

\* Op32_ReadWaitlistFields: a [Read Waitlist] of a waitlist answered its
\* waitlist id, offering reference and waitlist state (Operation 32).
Op32_ReadWaitlistFields ==
    [][(last'.op = "read_waitlist" /\ wst[last'.w] # "none")
         => (last'.ans = "waitlist" /\ last'.rw.wid = last'.w
             /\ last'.rw.off = woff[last'.w] /\ last'.rw.st = wst[last'.w])]_vars

\* Op33_ReadWaitlistEveryWaitingInOrder: such a [Read Waitlist] answered
\* every waiting spot of the waitlist, lowest join number first: Cara, then
\* Ana (Operation 33).
Op33_ReadWaitlistEveryWaitingInOrder ==
    [][(last'.op = "read_waitlist" /\ wst[last'.w] # "none")
         => (/\ \A s \in WaitingOf(last'.w) :
                  \E k \in DOMAIN last'.rw.spots : last'.rw.spots[k].sid = s
             /\ \A k \in DOMAIN last'.rw.spots :
                  (k + 1 \in DOMAIN last'.rw.spots)
                    => last'.rw.spots[k].num < last'.rw.spots[k + 1].num)]_vars

\* Op36_ReadWaitlistOnlyWaiting: every spot such a [Read Waitlist] answered
\* is a waiting spot of the waitlist read: standing in waiting, and carrying
\* that waitlist's id. Ana's called spot and Ben's left one are not in the
\* pottery class's read_waitlist(w1), and neither is a spot waiting on
\* another waitlist, as Sam's on the size-42 list is not in a read of the
\* size-43 one (Operation 36). The two waitlist ids of the .cfg let one
\* waitlist be read while a spot waits on the other.
Op36_ReadWaitlistOnlyWaiting ==
    [][(last'.op = "read_waitlist" /\ wst[last'.w] # "none")
         => \A k \in DOMAIN last'.rw.spots :
              LET s == last'.rw.spots[k].sid IN
                /\ s \in SIds
                /\ sst[s] = "waiting"
                /\ swl[s] = last'.w]_vars

\* Op34_ReadWaitlistSpotFields: every spot such a [Read Waitlist] answered
\* came with its spot id, person reference, join number and join instant
\* (Operation 34).
Op34_ReadWaitlistSpotFields ==
    [][(last'.op = "read_waitlist" /\ wst[last'.w] # "none")
         => \A k \in DOMAIN last'.rw.spots :
              LET e == last'.rw.spots[k] IN
                /\ e.sid \in SIds
                /\ e.per = sper[e.sid] /\ e.num = snum[e.sid] /\ e.inst = sinst[e.sid]]_vars

\* Op35_ReadWaitlistWritesNothing: a [Read Waitlist] step wrote nothing
\* (Operation 35).
Op35_ReadWaitlistWritesNothing ==
    [][last'.op = "read_waitlist" => Quiet]_vars

====
