---- MODULE retention-window ----
\* Grace Commons — Retention Window atom (atoms/retention-window.md).
\* Grounded on Final Critique 13, 2026-10-24 at 142a72a — TLA+ layer authored 2026-11-12.
\* Derived validator; the English spec is the single source of truth. On any
\* disagreement, diagnose per the entry *The conflict protocol* in pressure-testing.md.
\*
\* PURPOSE
\* Check what happens across steps: the retentions [Place Under Retention] and
\* [Purge] write over a sequence of calls while the host's clock moves, what
\* [Purge] answers at each now, what [Read] answers, which records the database
\* still holds, and what a deadline crossed, a refused purge and a [Read] leave.
\* What one state of the records must carry (Invariant 1.1, 4.1, 6.1, 6.2, 8.1,
\* 9.1 and 11.1, State 2 to 6a and 10, Identity 1, Operation 4, 5, 7, 8c and
\* 13) is the Alloy model's, retention-window.als; the two models spell the
\* page's terms alike (retained, purged, the retention deadline, the purge
\* deadline, the purge instant, purge eligible).
\*
\* RULES CHECKED (named by the page's own labels)
\*   Invariant 2.1  — a successful [Purge] leaves its retention
\*                    purged (Operation 12)                         (Inv2_1_RetainedOnlyIfUnpurged)
\*   Invariant 2.2  — a retention becomes purged only by a
\*                    successful [Purge] of its own id              (Inv2_2_PurgedOnlyByPurge)
\*   Invariant 3.1  — a purged retention never stands retained
\*                    again (Invariant 3.2, State 8)                (Inv3_1_PurgedStaysPurged)
\*   Invariant 4.2  — a retention id never changes                  (Inv4_2_IdFixed)
\*   Invariant 5.1  — a record reference never changes              (Inv5_1_RecordRefFixed)
\*   Invariant 5.2  — a policy reference never changes (State 9)    (Inv5_2_PolicyRefFixed)
\*   Invariant 5.3  — the instants never change once set            (Inv5_3_InstantsFixed)
\*   Invariant 7.1  — a purge short of the retention deadline
\*                    refuses and writes nothing (Operation 16, 17) (Inv7_1_NoEarlyPurge)
\*   Invariant 8.3  — a purge past the purge deadline is not
\*                    refused (Operation 18)                        (Inv8_3_LatePurgeAdmitted)
\*   Invariant 10.2 — the retention set never shrinks
\*                    (Invariant 10.1)                              (Inv10_2_SetNeverShrinks)
\*   Invariant 11.2 — the purge eligible [Read] answers is derived
\*                    from state, deadline and now (Operation 31)   (Inv11_2_EligibilityDerived)
\*   Invariant 11.3 — crossing a retention deadline writes nothing  (Inv11_3_CrossingWritesNothing)
\*   Identity 5     — no placement records an id a retention
\*                    carries (Capability requirement 8, 9)         (Id5_IdNeverReused)
\*   Operation 1    — a placement records exactly one retention,
\*                    over a record already retained too
\*                    (Simultaneous retention 1, Identity 9)        (Op1_PlaceAddsOne)
\*   Operation 13b  — a successful [Purge] removes the record its
\*                    retention names from the database             (Op13b_PurgeRemovesRecord)
\*   Operation 15   — a [Purge] of a purged retention answers
\*                    not-retained and writes nothing               (Op15_PurgedAnswersNotRetained)
\*   Operation 20   — a [Purge] that answers storage-failure leaves
\*                    its retention retained                        (Op20_FailureLeavesRetained)
\*   Operation 29   — [Read] answers every retention, retained and
\*                    purged                                        (Op29_ReadAnswersEvery)
\*   Operation 32   — [Read] writes nothing                         (Op32_ReadWritesNothing)
\*   Simultaneous retention 2 — the gate reads the purging
\*                    retention's own retention deadline
\*                    (Simultaneous retention 3)                    (Sim2_OwnDeadlineGate)
\*
\* WHAT THE MODEL TAKES FROM OUTSIDE THE PAGE (its inputs; no ASSUME, no CONSTRAINT)
\* - The clock (Term now; Capability requirement 1): one reading per call, the
\*   variable `now`, which moves forward one tick at a time (Tick); a deadline
\*   crossed is the clock reaching it, and nothing else happens at it.
\* - The policy registry (Operation 24, 24a): the host resolves each policy
\*   reference at the seam to a duration and a max purge delay; the model's two
\*   policies resolve, and both are valid (see BOUNDS).
\* - The host allocates each placement's retention id at the seam (Identity 2);
\*   the page binds it never to supply one a retention carries (Capability
\*   requirement 8, 9), and that is the guard on Place and a check here.
\* - The deployment never supplies a placement the record reference of a
\*   destroyed record (Capability requirement 15): the guard on Place reads
\*   which records the database still holds as the deployment's choice of
\*   input, not as a read the atom makes (Record divergence 3, Operation 11).
\* - The database (Execution Contract Database 1, 2): each call's guards and
\*   writes are one atomic step, and a [Purge] judges one now (Operation 21).
\*   Whether it accepts a purge's write is its own: PurgeFails is the refusal.
\*
\* BOUNDS (the .cfg)
\* Three retention ids and room for two retentions, so an id names nothing, a
\* second retention is placed and an id stays spare; two record references, so
\* two retentions can share a record (Simultaneous retention 1) or name two,
\* and a purged id can be offered again over the record still held; two
\* policies, p1 (duration 1, max purge delay 0, the zero duration) and p2
\* (duration 2, max purge delay 1), so siblings over one record carry two
\* deadlines; a time resolution of one tick (the rounding is the Alloy
\* model's); the clock from 0 to 4. Every [Purge] answer is reached, a purge
\* at the retention deadline, inside the purge window and past the purge
\* deadline, and a [Read] at every now.
\*
\* NOT MODELED HERE
\* - Blank references, the policy registry's refusals and invalid policies
\*   (Operation 4 to 8c, 24b) and a placement's storage failure (Operation 9):
\*   each refusal writes nothing (Execution Contract Refusal 1), and the
\*   records a refused call cannot leave are the Alloy model's to check.
\* - The instance where a composing pattern owns the destruction (Record
\*   divergence 4 to 6, Capability requirement 6a): here none does, so [Purge]
\*   removes the record (Operation 13b). The destruction records, joint
\*   enforcement and the composing patterns' gates (Simultaneous retention 4
\*   to 8, External check 1 to 5) are other patterns' and the deployment's.
\* - What [Read] answers beyond the retentions it lists and purge eligible:
\*   the stored fields (Operation 30) are the Alloy model's records.

EXTENDS Integers, FiniteSets

CONSTANTS
    Rids,      \* the retention ids the host may allocate, and a caller present
    Records,   \* the record references a placement may carry
    MaxTime,   \* the last instant the clock reaches in the model
    MaxRet,    \* how many retentions the model's database holds room for
    Res        \* the time resolution, in ticks (Capability requirement 5)

\* NONE: the value of a reference field not yet written.
NONE == "none"

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

\* NoCall: the record of the last call before any call is made, and the shape
\* of every such record: the action, the retention id it named, what it
\* answered, and, for a [Read], the retentions it listed and the purge
\* eligible it answered for each.
NoCall == [op |-> "none", rid |-> NONE, ans |-> "none", listed |-> {}, elig |-> NoElig]

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

\* Read: [Read] answers every retention, retained and purged (Operation 29),
\* with purge eligible for each retained one (Operation 31), and writes nothing
\* (Operation 32).
Read ==
    /\ last' = [NoCall EXCEPT !.op = "read",
                    !.listed = {s \in Slots : Recorded(s)},
                    !.elig = [s \in Slots |->
                                IF Recorded(s) /\ status[s] = "retained"
                                THEN (IF Eligible(s) THEN "yes" ELSE "no")
                                ELSE "none"]]
    /\ UNCHANGED <<now, n, rid, rec, pol, retAt, until, pdl, status, purgedAt, present>>

\* Next: the clock moving, or any call: a placement of any id over any record
\* under either policy, a [Purge] of any id, or a [Read].
Next ==
    \/ Tick
    \/ \E id \in Rids, r \in Records, p \in Policies : Place(id, r, p)
    \/ \E id \in Rids : PurgeOk(id)
    \/ \E id \in Rids : PurgeFails(id)
    \/ \E id \in Rids : PurgeNotElapsed(id)
    \/ \E id \in Rids : PurgeNotRetained(id)
    \/ \E id \in Rids : PurgeNotKnown(id)
    \/ Read

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
\* there is no un-purge and no restore (Invariant 3.1, 3.2, State 8).
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
\* retained retention is yes exactly where now does not precede its retention
\* deadline, from the state, the deadline and now alone (Invariant 11.2,
\* Operation 31, Check 3.2).
Inv11_2_EligibilityDerived ==
    [][last'.op = "read" =>
          \A s \in Slots : (Recorded(s) /\ status[s] = "retained") =>
              last'.elig[s] = IF now >= until[s] THEN "yes" ELSE "no"]_vars

\* Inv11_3_CrossingWritesNothing: the clock moving, and every deadline it
\* crosses, writes nothing: no scheduler purges, no flag flips (Invariant
\* 11.3).
Inv11_3_CrossingWritesNothing ==
    [][last'.op = "tick" => UNCHANGED retentions]_vars

\* Id5_IdNeverReused: no placement records a retention id a retention already
\* carries, a purged retention's included (Identity 5, Capability requirement
\* 8, 9).
Id5_IdNeverReused ==
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

\* Op29_ReadAnswersEvery: a [Read] lists every recorded retention, retained
\* and purged (Operation 29).
Op29_ReadAnswersEvery ==
    [][last'.op = "read" => last'.listed = {s \in Slots : Recorded(s)}]_vars

\* Op32_ReadWritesNothing: a [Read] step changes no retention and no record
\* (Operation 32).
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
