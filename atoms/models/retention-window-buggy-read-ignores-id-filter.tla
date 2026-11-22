---- MODULE retention-window-buggy-read-ignores-id-filter ----
\* DELIBERATELY WRONG twin of retention-window.tla (unit: `atoms/retention-window.md formal layer`).
\*
\* INJECTED DEFECT: [Read] drops its retention-id filter and answers every retention the record-
\* reference filter matches (Term matching retention; the [Read] entry).
\*
\* BREAKS: Read_OnlyMatches.
\* Everything else is retention-window.tla as written; read its comments there.

EXTENDS Integers, FiniteSets

CONSTANTS
    Rids,      \* the retention ids the host may allocate, and a caller present
    Records,   \* the record references a placement may carry
    MaxTime,   \* the last instant the clock reaches in the model
    MaxRet,    \* how many retentions the model's database holds room for
    Res        \* the time resolution, in ticks (Capability requirement 5)

\* NONE: the value of a reference field not yet written.
NONE == "none"

\* ANY: what a query carries on an axis it puts no filter on.
ANY == "any"

\* BLANK: a blank filter value (GRACE-lang Term blank), which no query axis
\* admits (Term query axes; Execution Contract Query 5).
BLANK == ""

\* Policies: the policy references the registry resolves; PolicyDuration and
\* PolicyDelay: the duration and the max purge delay each resolves to at the
\* seam (Operation 24a). p1's delay is the zero duration, which Operation 8
\* admits.
Policies == {"p1", "p2"}
PolicyDuration(p) == IF p = "p1" THEN 1 ELSE 2
PolicyDelay(p) == IF p = "p1" THEN 0 ELSE 1

\* RoundUp: the instant rounded up to the time resolution, counted from the
\* epoch (State 4a, 6a, Operation 13a, Term time resolution).
RoundUp(x) == IF x % Res = 0 THEN x ELSE x + (Res - (x % Res))

\* Slots: the places a retention can occupy, in the order they are placed.
Slots == 1..MaxRet

\* NoElig: the purge eligible a call that is no [Read] reports: none.
NoElig == [s \in Slots |-> "none"]

\* Queries: the queries a [Read] may carry. A query is a value or ANY on each
\* of the two query axes, retention id and record reference (Term query
\* axes), and a value or ANY on the policy reference, an axis outside them.
\* The well-formed ones: r1, r2 or no filter on retention id, x1 or no
\* filter on record reference, each pair of them, and no policy filter (the
\* bound: see BOUNDS). The malformed ones: a blank value on either query
\* axis (Operation 38), and a policy-reference filter (Operation 37).
Queries ==
    [rid : {"r1", "r2", ANY}, rec : {"x1", ANY}, pol : {ANY}]
    \cup {[rid |-> BLANK, rec |-> ANY, pol |-> ANY],
         [rid |-> ANY, rec |-> BLANK, pol |-> ANY],
         [rid |-> ANY, rec |-> ANY, pol |-> "p1"]}

\* NoQuery: the query a call that is no [Read] records: no filter.
NoQuery == [rid |-> ANY, rec |-> ANY, pol |-> ANY]

\* NoCall: the record of the last call before any call is made, and the shape
\* of every such record: the action, the retention id it named, what it
\* answered, and, for a [Read], the query it carried, the retentions it
\* listed and the purge eligible it answered for each.
NoCall == [op |-> "none", rid |-> NONE, ans |-> "none", q |-> NoQuery, listed |-> {}, elig |-> NoElig]

\* ---------------------------------------------------------------------------
\* State
\* ---------------------------------------------------------------------------

VARIABLES
    now,       \* the host's clock reading, injected at the seam
    n,         \* the next slot a placed retention takes
    rid,       \* slot -> retention id
    rec,       \* slot -> record reference
    pol,       \* slot -> policy reference
    retAt,     \* slot -> retention instant (-1: none)
    until,     \* slot -> retention deadline (-1: none)
    pdl,       \* slot -> purge deadline (-1: none)
    status,    \* slot -> retention state ("none": no retention)
    purgedAt,  \* slot -> purge instant (-1: none)
    present,   \* the records the database still holds
    last       \* the last call made and what it answered (NoCall's shape)

\* vars: every variable; a step that changes none of them is a stutter.
vars == <<now, n, rid, rec, pol, retAt, until, pdl, status, purgedAt, present, last>>

\* retentions: every variable a write changes: the retention records and the
\* records the database holds.
retentions == <<n, rid, rec, pol, retAt, until, pdl, status, purgedAt, present>>

\* Recorded: the slot holds a retention a placement recorded.
Recorded(s) == s < n

\* Carried: the retention ids the recorded retentions carry.
Carried == {rid[s] : s \in {x \in Slots : Recorded(x)}}

\* Live: the slots holding a retention; its size is the retention count.
Live == {s \in Slots : status[s] # "none"}

\* SlotOf: the slot whose retention the id names, or 0 where it names none.
SlotOf(id) == IF \E s \in Slots : Recorded(s) /\ rid[s] = id
              THEN CHOOSE s \in Slots : Recorded(s) /\ rid[s] = id
              ELSE 0

\* Eligible: purge eligible: the retention stands retained and now does not
\* precede its retention deadline (Term purge eligible).
Eligible(s) == status[s] = "retained" /\ now >= until[s]

\* TypeOK: each variable holds a value of its kind (the model's typing, not a
\* rule of the page).
TypeOK ==
    /\ now \in 0..MaxTime
    /\ n \in 1..(MaxRet + 1)
    /\ rid \in [Slots -> Rids \cup {NONE}]
    /\ rec \in [Slots -> Records \cup {NONE}]
    /\ pol \in [Slots -> Policies \cup {NONE}]
    /\ retAt \in [Slots -> Int]
    /\ until \in [Slots -> Int]
    /\ pdl \in [Slots -> Int]
    /\ status \in [Slots -> {"none", "retained", "purged"}]
    /\ purgedAt \in [Slots -> Int]
    /\ present \subseteq Records

\* Init: no retention; every record held; the clock at its first instant.
Init ==
    /\ now = 0
    /\ n = 1
    /\ rid = [s \in Slots |-> NONE]
    /\ rec = [s \in Slots |-> NONE]
    /\ pol = [s \in Slots |-> NONE]
    /\ retAt = [s \in Slots |-> -1]
    /\ until = [s \in Slots |-> -1]
    /\ pdl = [s \in Slots |-> -1]
    /\ status = [s \in Slots |-> "none"]
    /\ purgedAt = [s \in Slots |-> -1]
    /\ present = Records
    /\ last = NoCall

\* ---------------------------------------------------------------------------
\* Actions
\* ---------------------------------------------------------------------------

\* Tick: the host's clock moves on by one tick. A retention whose deadline it
\* reaches becomes purge eligible, and nothing is written (Invariant 11.3).
Tick ==
    /\ now < MaxTime
    /\ now' = now + 1
    /\ last' = [NoCall EXCEPT !.op = "tick"]
    /\ UNCHANGED retentions

\* Place: [Place Under Retention] records one retention in retained in the
\* next slot (Operation 1, 2), carrying the id the host allocated, one no
\* retention carries (Invariant 4.1, Capability requirement 8), the record and
\* policy references, now rounded up as its retention instant (State 4, 4a),
\* the two deadlines from the resolved policy (State 5, 6, 6a), and answers the
\* retention id (Operation 3).
Place(id, r, p) ==
    LET at == RoundUp(now)
        u  == RoundUp(at + PolicyDuration(p))
    IN
    /\ n <= MaxRet
    /\ id \notin Carried
    /\ r \in present
    /\ rid' = [rid EXCEPT ![n] = id]
    /\ rec' = [rec EXCEPT ![n] = r]
    /\ pol' = [pol EXCEPT ![n] = p]
    /\ retAt' = [retAt EXCEPT ![n] = at]
    /\ until' = [until EXCEPT ![n] = u]
    /\ pdl' = [pdl EXCEPT ![n] = RoundUp(u + PolicyDelay(p))]
    /\ status' = [status EXCEPT ![n] = "retained"]
    /\ n' = n + 1
    /\ last' = [NoCall EXCEPT !.op = "place", !.rid = id, !.ans = "ok"]
    /\ UNCHANGED <<now, purgedAt, present>>

\* PurgeOk: [Purge] of an id naming a retained retention whose retention
\* deadline now has reached (Operation 16), the purge deadline not read
\* (Operation 18), the database accepting the write: it stands the retention
\* purged (Operation 12), stamps now rounded up as its purge instant
\* (Operation 13, 13a), removes the record it names from the database in the
\* same write (Operation 13b), and answers ok.
PurgeOk(id) ==
    LET s == SlotOf(id) IN
    /\ s # 0
    /\ status[s] = "retained"
    /\ now >= until[s]
    /\ status' = [status EXCEPT ![s] = "purged"]
    /\ purgedAt' = [purgedAt EXCEPT ![s] = RoundUp(now)]
    /\ present' = present \ {rec[s]}
    /\ last' = [NoCall EXCEPT !.op = "purge", !.rid = id, !.ans = "ok"]
    /\ UNCHANGED <<now, n, rid, rec, pol, retAt, until, pdl>>

\* PurgeFails: the same purge where the database refuses the write: it
\* answers storage-failure and nothing is written, the retention left
\* retained (Operation 19, 20).
PurgeFails(id) ==
    LET s == SlotOf(id) IN
    /\ s # 0
    /\ status[s] = "retained"
    /\ now >= until[s]
    /\ last' = [NoCall EXCEPT !.op = "purge", !.rid = id, !.ans = "storage-failure"]
    /\ UNCHANGED <<now, n, rid, rec, pol, retAt, until, pdl, status, purgedAt, present>>

\* PurgeNotElapsed: [Purge] of a retained retention whose retention deadline
\* now has not reached answers retention-period-not-elapsed and writes nothing
\* (Operation 16, 17).
PurgeNotElapsed(id) ==
    LET s == SlotOf(id) IN
    /\ s # 0
    /\ status[s] = "retained"
    /\ now < until[s]
    /\ last' = [NoCall EXCEPT !.op = "purge", !.rid = id, !.ans = "retention-period-not-elapsed"]
    /\ UNCHANGED <<now, n, rid, rec, pol, retAt, until, pdl, status, purgedAt, present>>

\* PurgeNotRetained: [Purge] of a purged retention answers not-retained and
\* writes nothing (Operation 15).
PurgeNotRetained(id) ==
    LET s == SlotOf(id) IN
    /\ s # 0
    /\ status[s] = "purged"
    /\ last' = [NoCall EXCEPT !.op = "purge", !.rid = id, !.ans = "not-retained"]
    /\ UNCHANGED <<now, n, rid, rec, pol, retAt, until, pdl, status, purgedAt, present>>

\* PurgeNotKnown: [Purge] of an id naming no retention answers not-known and
\* writes nothing (Operation 14).
PurgeNotKnown(id) ==
    /\ SlotOf(id) = 0
    /\ last' = [NoCall EXCEPT !.op = "purge", !.rid = id, !.ans = "not-known"]
    /\ UNCHANGED <<now, n, rid, rec, pol, retAt, until, pdl, status, purgedAt, present>>

\* QueryAdmitted: the model's [Read] reading of whether it admits the query:
\* no filter on an axis outside the query axes, and no blank value.
QueryAdmitted(q) == q.pol = ANY /\ q.rid # BLANK /\ q.rec # BLANK

\* ReadMatch: the model's [Read] reading of whether the slot's retention
\* matches the query: on each query axis the query filters, the retention
\* carries the filter's value.
ReadMatch(q, s) ==
    /\ TRUE   \* BUG: the retention-id filter dropped
    /\ (q.rec = ANY \/ rec[s] = q.rec)

\* ReadOk: [Read] of a query it admits answers every recorded retention the
\* query matches, retained and purged (Operation 29), with purge eligible for
\* each retained one it answers (Operation 31), and writes nothing
\* (Operation 32).
ReadOk(q) ==
    LET L == {s \in Slots : Recorded(s) /\ ReadMatch(q, s)} IN
    /\ QueryAdmitted(q)
    /\ last' = [NoCall EXCEPT !.op = "read", !.ans = "ok", !.q = q,
                    !.listed = L,
                    !.elig = [s \in Slots |->
                                IF s \in L /\ status[s] = "retained"
                                THEN (IF Eligible(s) THEN "yes" ELSE "no")
                                ELSE "none"]]
    /\ UNCHANGED <<now, n, rid, rec, pol, retAt, until, pdl, status, purgedAt, present>>

\* ReadInvalid: [Read] of a query it does not admit answers invalid-query,
\* lists nothing and writes nothing (Operation 37, 38, 32).
ReadInvalid(q) ==
    /\ ~QueryAdmitted(q)
    /\ last' = [NoCall EXCEPT !.op = "read", !.ans = "invalid-query", !.q = q]
    /\ UNCHANGED <<now, n, rid, rec, pol, retAt, until, pdl, status, purgedAt, present>>

\* Next: the clock moving, or any call: a placement of any id over any record
\* under either policy, a [Purge] of any id, or a [Read] of any query.
Next ==
    \/ Tick
    \/ \E id \in Rids, r \in Records, p \in Policies : Place(id, r, p)
    \/ \E id \in Rids : PurgeOk(id)
    \/ \E id \in Rids : PurgeFails(id)
    \/ \E id \in Rids : PurgeNotElapsed(id)
    \/ \E id \in Rids : PurgeNotRetained(id)
    \/ \E id \in Rids : PurgeNotKnown(id)
    \/ \E q \in Queries : ReadOk(q)
    \/ \E q \in Queries : ReadInvalid(q)

\* Spec: every behaviour from Init by Next steps.
Spec == Init /\ [][Next]_vars

\* ---------------------------------------------------------------------------
\* Checks (the verification surface). Each spells the page's condition itself,
\* so a defect in an action's own reading of it shows.
\* ---------------------------------------------------------------------------

\* Names: some recorded retention carries the id.
Names(id, s) == Recorded(s) /\ rid[s] = id

\* IsPurge: the step is a [Purge] call (any answer).
IsPurge == last'.op = "purge"

\* Inv2_1_RetainedOnlyIfUnpurged: a [Purge] that answers ok leaves the
\* retention its id names purged: no retention stands retained once a
\* successful purge of it exists (Invariant 2.1, Operation 12).
Inv2_1_RetainedOnlyIfUnpurged ==
    [][(IsPurge /\ last'.ans = "ok") =>
          \A s \in Slots : Names(last'.rid, s) => status'[s] = "purged"]_vars

\* Inv2_2_PurgedOnlyByPurge: a retention comes to stand purged only in a step
\* that is a successful [Purge] naming its own id: no scheduler, no failed
\* write and no purge of a sibling ends it (Invariant 2.2, Simultaneous
\* retention 3).
Inv2_2_PurgedOnlyByPurge ==
    [][\A s \in Slots : (status[s] # "purged" /\ status'[s] = "purged") =>
          (IsPurge /\ last'.ans = "ok" /\ last'.rid = rid[s])]_vars

\* Inv3_1_PurgedStaysPurged: no step moves a purged retention out of purged:
\* there is no un-purge and no restore surface (Invariant 3.1, 3.2).
Inv3_1_PurgedStaysPurged ==
    [][\A s \in Slots : status[s] = "purged" => status'[s] = "purged"]_vars

\* Inv4_2_IdFixed: no step changes a recorded retention's id (Invariant 4.2).
Inv4_2_IdFixed ==
    [][\A s \in Slots : Recorded(s) => rid'[s] = rid[s]]_vars

\* Inv5_1_RecordRefFixed: no step changes a recorded retention's record
\* reference, its record destroyed or not (Invariant 5.1).
Inv5_1_RecordRefFixed ==
    [][\A s \in Slots : Recorded(s) => rec'[s] = rec[s]]_vars

\* Inv5_2_PolicyRefFixed: no step changes a recorded retention's policy
\* reference: there is no policy-change surface (Invariant 5.2, State 9).
Inv5_2_PolicyRefFixed ==
    [][\A s \in Slots : Recorded(s) => pol'[s] = pol[s]]_vars

\* Inv5_3_InstantsFixed: no step changes a recorded retention's retention
\* instant, retention deadline or purge deadline, nor a purge instant once
\* stamped (Invariant 5.3).
Inv5_3_InstantsFixed ==
    [][\A s \in Slots :
          /\ Recorded(s) => (retAt'[s] = retAt[s] /\ until'[s] = until[s] /\ pdl'[s] = pdl[s])
          /\ purgedAt[s] # -1 => purgedAt'[s] = purgedAt[s]]_vars

\* Inv7_1_NoEarlyPurge: a [Purge] of a retained retention whose retention
\* deadline now has not reached (purge eligible no) answers
\* retention-period-not-elapsed and writes nothing: no early purge is an
\* outcome the atom has (Invariant 7.1, Operation 16, Operation 17).
Inv7_1_NoEarlyPurge ==
    [][(IsPurge /\ \E s \in Slots : Names(last'.rid, s) /\ status[s] = "retained" /\ now < until[s])
          => (last'.ans = "retention-period-not-elapsed" /\ UNCHANGED retentions)]_vars

\* Inv8_3_LatePurgeAdmitted: a [Purge] of a purge eligible retention whose
\* purge deadline now has passed is not refused: it answers ok, or
\* storage-failure where the database refuses the write; the purge instant is
\* not bounded by the purge deadline (Invariant 8.3, Operation 18).
Inv8_3_LatePurgeAdmitted ==
    [][(IsPurge /\ \E s \in Slots : Names(last'.rid, s) /\ status[s] = "retained"
                                 /\ now >= until[s] /\ now > pdl[s])
          => last'.ans \in {"ok", "storage-failure"}]_vars

\* Inv10_2_SetNeverShrinks: no step reduces the retention count: the atom
\* deletes no retention record (Invariant 10.2, Invariant 10.1).
Inv10_2_SetNeverShrinks ==
    [][Cardinality(Live') >= Cardinality(Live)]_vars

\* Inv11_2_EligibilityDerived: the purge eligible a [Read] answers for each
\* retained retention it answers is yes exactly where now does not precede
\* its retention deadline, from the state, the deadline and now alone
\* (Invariant 11.2, Operation 31, Check 3.2).
Inv11_2_EligibilityDerived ==
    [][last'.op = "read" =>
          \A s \in last'.listed : (Recorded(s) /\ status[s] = "retained") =>
              last'.elig[s] = IF now >= until[s] THEN "yes" ELSE "no"]_vars

\* Inv11_3_CrossingWritesNothing: the clock moving, and every deadline it
\* crosses, writes nothing: no scheduler purges, no flag flips (Invariant
\* 11.3).
Inv11_3_CrossingWritesNothing ==
    [][last'.op = "tick" => UNCHANGED retentions]_vars

\* Inv9_1_HostIdFresh: no placement records a retention id a retention
\* already carries, a purged retention's included, so no two retentions share
\* one in any state the steps reach (Invariant 9.1 across steps; the host's
\* duty, Capability requirement 8, 9 and Execution Contract Logic
\* confinement 16).
Inv9_1_HostIdFresh ==
    [][last'.op = "place" => last'.rid \notin Carried]_vars

\* Op1_PlaceAddsOne: every placement that answers adds exactly one retention,
\* where a retention over the same record exists already: two retentions over
\* one record are two (Operation 1, Simultaneous retention 1, Identity 9).
Op1_PlaceAddsOne ==
    [][(last'.op = "place" /\ last'.ans = "ok") => Cardinality(Live') = Cardinality(Live) + 1]_vars

\* Op13b_PurgeRemovesRecord: a [Purge] that answers ok leaves the database
\* without the record its retention names, in the same step (Operation 13b,
\* no composing pattern owning the destruction).
Op13b_PurgeRemovesRecord ==
    [][(IsPurge /\ last'.ans = "ok") =>
          \A s \in Slots : Names(last'.rid, s) => rec[s] \notin present']_vars

\* Op15_PurgedAnswersNotRetained: a [Purge] of a purged retention answers
\* not-retained and writes nothing (Operation 15).
Op15_PurgedAnswersNotRetained ==
    [][(IsPurge /\ \E s \in Slots : Names(last'.rid, s) /\ status[s] = "purged")
          => (last'.ans = "not-retained" /\ UNCHANGED retentions)]_vars

\* Op20_FailureLeavesRetained: a [Purge] that answers storage-failure leaves
\* the retention its id names retained (Operation 20, Purge persistence 1).
Op20_FailureLeavesRetained ==
    [][(IsPurge /\ last'.ans = "storage-failure") =>
          \A s \in Slots : Names(last'.rid, s) => status'[s] = "retained"]_vars

\* WellFormed: the page's reading of a query [Read] answers: every filter on
\* a query axis (Operation 37), and no blank value (Operation 38).
WellFormed(q) == q.pol = ANY /\ BLANK \notin {q.rid, q.rec}

\* PageMatch: whether the slot's retention is a matching retention, as the
\* page says: its retention id EQUALS the filter's where the query carries
\* that filter, its record reference EQUALS the filter's where it carries
\* that one, and a query carrying no filter matches every retention (Term
\* matching retention; Identity 10; Execution Contract Query 3, 4).
PageMatch(q, s) ==
    /\ q.rid # ANY => rid[s] = q.rid
    /\ q.rec # ANY => rec[s] = q.rec

\* Op29_ReadAnswersEveryMatch: a [Read] of a well-formed query answers, and
\* lists every recorded retention the query matches, retained and purged
\* (Operation 29; Term matching retention).
Op29_ReadAnswersEveryMatch ==
    [][(last'.op = "read" /\ WellFormed(last'.q)) =>
          /\ last'.ans = "ok"
          /\ \A s \in Slots : (Recorded(s) /\ PageMatch(last'.q, s)) => s \in last'.listed]_vars

\* Read_OnlyMatches: a [Read] lists no retention its query does not match:
\* Operation 39 (Term matching retention).
Read_OnlyMatches ==
    [][last'.op = "read" =>
          \A s \in last'.listed : Recorded(s) /\ PageMatch(last'.q, s)]_vars

\* Id10_RecordRefExact: a [Read] carrying a record-reference filter lists only
\* retentions whose record reference is the filter's exact value: the atom
\* compares the two record references by exact value (Identity 10; the
\* deployment canonicalizes both at the seam, Execution Contract Logic
\* confinement 13).
Id10_RecordRefExact ==
    [][(last'.op = "read" /\ last'.q.rec \notin {ANY, BLANK}) =>
          \A s \in last'.listed : rec[s] = last'.q.rec]_vars

\* Op37_OffAxisFilterRefused: a [Read] whose query filters on an axis outside
\* the query axes, the policy reference, answers invalid-query (Operation 37).
Op37_OffAxisFilterRefused ==
    [][(last'.op = "read" /\ last'.q.pol # ANY) => last'.ans = "invalid-query"]_vars

\* Op38_BlankValueRefused: a [Read] whose query carries a blank value on a
\* query axis answers invalid-query: no axis admits a blank value (Operation
\* 38; Term query axes).
Op38_BlankValueRefused ==
    [][(last'.op = "read" /\ BLANK \in {last'.q.rid, last'.q.rec}) => last'.ans = "invalid-query"]_vars

\* Op32_ReadWritesNothing: a [Read] step, admitted or refused, changes no
\* retention and no record (Operation 32).
Op32_ReadWritesNothing ==
    [][last'.op = "read" => UNCHANGED retentions]_vars

\* Sim2_OwnDeadlineGate: a [Purge] of a retained retention whose own retention
\* deadline now has reached is not refused, whatever a sibling over the same
\* record carries: the gate reads the purging retention's deadline alone
\* (Simultaneous retention 2, Simultaneous retention 3).
Sim2_OwnDeadlineGate ==
    [][(IsPurge /\ \E s \in Slots : Names(last'.rid, s) /\ status[s] = "retained" /\ now >= until[s])
          => last'.ans \in {"ok", "storage-failure"}]_vars

====
