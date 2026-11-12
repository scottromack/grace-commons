---- MODULE selective-disclosure-buggy-record-refuses-recorded-subject ----
\* DELIBERATELY WRONG twin of selective-disclosure.tla (unit: `atoms/selective-disclosure.md formal layer`).
\*
\* INJECTED DEFECT: [Record] refuses a call whose subject reference a record already carries (Identity 8).
\*
\* BREAKS: Id8_SecondRecordAdmitted.
\* Everything else is selective-disclosure.tla as written; read its comments there.

EXTENDS Integers, FiniteSets

CONSTANTS
    Ids,        \* the disclosure ids the host may allocate, as integers in code point order
    Subjects,   \* the subject references a [Record] may carry
    Recipients, \* the recipients a [Record] may carry
    Scopes,     \* the scopes a [Record] may carry
    AuthTypes,  \* the authority types: consent, legal-hold, regulatory
    Refs,       \* the authority references a [Record] may carry
    MaxRec,     \* how many records the model's database holds room for
    MaxTime     \* the last instant the clock reaches in the model

\* NONE: the value of a string field of an empty slot.
NONE == "none"

\* ANY: a filter value standing for no filter on its axis.
ANY == "any"

\* Slots: the places a record can occupy, in the order they are written.
Slots == 1..MaxRec

\* ---------------------------------------------------------------------------
\* State
\* ---------------------------------------------------------------------------

VARIABLES
    now,        \* the host's clock reading, injected at the seam
    n,          \* the next slot a record takes
    did,        \* slot -> disclosure id (0: no record)
    sub,        \* slot -> subject reference
    rcp,        \* slot -> recipient
    scp,        \* slot -> scope
    typ,        \* slot -> authority type
    ref,        \* slot -> authority reference
    at,         \* slot -> disclosure instant
    ans         \* the last call's answer: its kind, and the id a recorded answer carries

\* vars: every variable; a step that changes none of them is a stutter.
vars == <<now, n, did, sub, rcp, scp, typ, ref, at, ans>>

\* records: every variable that holds a record's fields: what the database holds.
records == <<n, did, sub, rcp, scp, typ, ref, at>>

\* Recorded: the slot holds a disclosure record.
Recorded(s) == did[s] # 0

\* Live: the slots holding a record; its size is the record count.
Live == {s \in Slots : Recorded(s)}

\* Carried: the disclosure ids the records carry.
Carried == {did[s] : s \in Live}

\* Fields: the seven fields of the slot's record (State 1).
Fields(s) == <<did[s], sub[s], rcp[s], scp[s], typ[s], ref[s], at[s]>>

\* Resolved: the resolved disclosure instant of a call supplying d: the
\* supplied instant, or now where the call left it blank (d = -1; Execution
\* Contract Logic confinement 12).
Resolved(d) == IF d = -1 THEN now ELSE d

\* Filters: every well-formed query: a value or no filter on each of the five
\* filter axes (Term filter axes), a range on disclosure instant holding both
\* its ends with its after not following its before (Operation 25; Execution
\* Contract Query 1, 2), filters combining as all-of (Query 4).
Filters ==
    {f \in [fid : {0} \cup Ids, fsub : {ANY} \cup Subjects, frcp : {ANY} \cup Recipients,
            ftyp : {ANY} \cup AuthTypes, lo : {-1} \cup 0..MaxTime, hi : {-1} \cup 0..MaxTime] :
        \/ (f.lo = -1 /\ f.hi = -1)
        \/ (f.lo # -1 /\ f.hi # -1 /\ f.lo <= f.hi)}

\* TypeOK: each variable holds a value of its kind (the model's typing, not a
\* rule of the page).
TypeOK ==
    /\ now \in 0..MaxTime
    /\ n \in 1..(MaxRec + 1)
    /\ did \in [Slots -> {0} \cup Ids]
    /\ sub \in [Slots -> {NONE} \cup Subjects]
    /\ rcp \in [Slots -> {NONE} \cup Recipients]
    /\ scp \in [Slots -> {NONE} \cup Scopes]
    /\ typ \in [Slots -> {NONE} \cup AuthTypes]
    /\ ref \in [Slots -> {NONE} \cup Refs]
    /\ at \in [Slots -> {-1} \cup 0..MaxTime]
    /\ ans \in [k : {"none", "recorded", "refused", "read"}, id : {0} \cup Ids]

\* Init: no record; the clock at its first instant; no call answered yet.
Init ==
    /\ now = 0
    /\ n = 1
    /\ did = [s \in Slots |-> 0]
    /\ sub = [s \in Slots |-> NONE]
    /\ rcp = [s \in Slots |-> NONE]
    /\ scp = [s \in Slots |-> NONE]
    /\ typ = [s \in Slots |-> NONE]
    /\ ref = [s \in Slots |-> NONE]
    /\ at = [s \in Slots |-> -1]
    /\ ans = [k |-> "none", id |-> 0]

\* ---------------------------------------------------------------------------
\* Steps of the world outside the atom
\* ---------------------------------------------------------------------------

\* Tick: the host's clock moves on by a second.
Tick ==
    /\ now < MaxTime
    /\ now' = now + 1
    /\ UNCHANGED <<ans>>
    /\ UNCHANGED records

\* ---------------------------------------------------------------------------
\* The atom's actions
\* ---------------------------------------------------------------------------

\* RecordAdmits: what [Record]'s guards ask of the stored records: nothing.
\* The guards read only the call and now (the page's Decisions, 2026-10-19),
\* so a subject already recorded, or a field set already recorded, does not
\* refuse a call (Identity 8, Non-goal 14, Concurrency 2).
RecordAdmits(p, r, x, t, a, d) == ~\E s \in Live : sub[s] = p  \* BUG

\* Record: an admitted [Record] (the call's inputs pass every guard; the
\* database accepts the write) writes one record in the next slot, carrying
\* the disclosure id the host injected, one no record carries (Operation 11,
\* Logic confinement 16), the call's subject reference, recipient, scope,
\* authority type and authority reference (Operation 42, 43; Execution
\* Contract Input 4), and the resolved disclosure instant (Operation 12), and
\* answers the disclosure id (Operation 13).
Record(i, p, r, x, t, a, d) ==
    /\ n <= MaxRec
    /\ i \notin Carried
    /\ RecordAdmits(p, r, x, t, a, d)
    /\ did' = [did EXCEPT ![n] = i]
    /\ sub' = [sub EXCEPT ![n] = p]
    /\ rcp' = [rcp EXCEPT ![n] = r]
    /\ scp' = [scp EXCEPT ![n] = x]
    /\ typ' = [typ EXCEPT ![n] = t]
    /\ ref' = [ref EXCEPT ![n] = a]
    /\ at' = [at EXCEPT ![n] = Resolved(d)]
    /\ n' = n + 1
    /\ ans' = [k |-> "recorded", id |-> i]
    /\ UNCHANGED now

\* Refuse: a refused [Record], for any of its refusals (a guard, or the
\* database refusing the write): it answers the refusal and writes nothing
\* (Operation 16, 17; Execution Contract Read 4).
Refuse ==
    /\ ans' = [k |-> "refused", id |-> 0]
    /\ UNCHANGED now
    /\ UNCHANGED records

\* ReadMatch: the model's [Read] reading of whether the slot's record matches
\* the query: on every axis the query filters, the record carries the
\* filter's value, or lies inside its range.
ReadMatch(s, f) ==
    /\ (f.fid = 0 \/ did[s] = f.fid)
    /\ (f.fsub = ANY \/ sub[s] = f.fsub)
    /\ (f.frcp = ANY \/ rcp[s] = f.frcp)
    /\ (f.ftyp = ANY \/ typ[s] = f.ftyp)
    /\ (f.lo = -1 \/ (f.lo <= at[s] /\ at[s] <= f.hi))

\* ReadSet: the records the model's [Read] answers for the query.
ReadSet(f) == {s \in Live : ReadMatch(s, f)}

\* ReadBefore: the model's [Read] order: the record in slot t comes before the
\* one in slot s.
ReadBefore(t, s) == at[t] < at[s] \/ (at[t] = at[s] /\ did[t] < did[s])

\* Pos: the place of the slot's record in what [Read] answers for the query:
\* one more than the count of answered records before it.
Pos(s, f) == 1 + Cardinality({t \in ReadSet(f) : ReadBefore(t, s)})

\* Read: a [Read] step. It answers ReadSet(f) in Pos order and writes nothing
\* (Operation 29); its answer is checked in every reachable state, for every
\* query (the invariants below), and the step leaves only its kind in `ans`.
Read ==
    /\ ans' = [k |-> "read", id |-> 0]
    /\ UNCHANGED now
    /\ UNCHANGED records

\* Next: a tick of the clock, or any call: an admitted [Record] of any id and
\* inputs, a supplied disclosure instant blank or not following now; a
\* refused [Record]; or a [Read].
Next ==
    \/ Tick
    \/ \E i \in Ids, p \in Subjects, r \in Recipients, x \in Scopes, t \in AuthTypes,
          a \in Refs, d \in {-1} \cup 0..now : Record(i, p, r, x, t, a, d)
    \/ Refuse
    \/ Read

\* Spec: every behaviour from Init by Next steps.
Spec == Init /\ [][Next]_vars

\* ---------------------------------------------------------------------------
\* Checks (the verification surface). Each spells the page's condition itself,
\* so a defect in an action's own reading of it shows.
\* ---------------------------------------------------------------------------

\* NewlyRecorded: the slots a step fills.
NewlyRecorded == {s \in Slots : did[s] = 0 /\ did'[s] # 0}

\* Recording: the step is a [Record] the atom admitted: it answers recorded.
Recording == ans'.k = "recorded" /\ ans' # ans

\* Refusing: the step is a refused [Record]: it answers a refusal.
Refusing == ans'.k = "refused" /\ ans' # ans

\* RecordShaped: the step writes one new record in the next slot and touches
\* no other slot: the only write an admitted [Record] makes.
RecordShaped ==
    /\ n' = n + 1
    /\ \A s \in Slots \ {n} : Fields(s)' = Fields(s)

\* PageMatch: whether the slot's record matches the query, as the page says:
\* it carries the filter's value exactly on every axis the query filters
\* (Identity 1, 9, 10), and a range holds both its ends (Execution Contract
\* Query 2, 3, 4).
PageMatch(s, f) ==
    /\ (f.fid = 0 \/ did[s] = f.fid)
    /\ (f.fsub = ANY \/ sub[s] = f.fsub)
    /\ (f.frcp = ANY \/ rcp[s] = f.frcp)
    /\ (f.ftyp = ANY \/ typ[s] = f.ftyp)
    /\ (f.lo = -1 \/ (f.lo <= at[s] /\ at[s] <= f.hi))

\* Inv1_1_FieldsFixed: no step changes a stored record's disclosure id,
\* subject reference, recipient, scope, authority type, authority reference
\* or disclosure instant while it stays stored (Invariant 1.1; Check 3.1); a
\* record taken away is Invariant 6.1's.
Inv1_1_FieldsFixed ==
    [][\A s \in Slots : (Recorded(s) /\ Recorded(s)') => Fields(s)' = Fields(s)]_vars

\* Inv6_1_NoRemoval: no step takes a record away: every disclosure id the
\* records carry, they carry after (Invariant 6.1).
Inv6_1_NoRemoval ==
    [][Carried \subseteq Carried']_vars

\* Cap9_HostIdFresh: no step writes a record under a disclosure id a record
\* already carries (Capability requirement 9, Logic confinement 16;
\* Identity 5 across steps).
Cap9_HostIdFresh ==
    [][\A s \in NewlyRecorded : did'[s] \notin Carried]_vars

\* Op10_ExactlyOneRecord: an admitted [Record] adds exactly one record to the
\* count, where a record of the same subject reference stands already
\* (Operation 10; State 7, Identity 7).
Op10_ExactlyOneRecord ==
    [][Recording => Cardinality(Live') = Cardinality(Live) + 1]_vars

\* Op13_AnswersTheId: an admitted [Record] answers the disclosure id of the
\* record it wrote (Operation 13).
Op13_AnswersTheId ==
    [][Recording => \E s \in NewlyRecorded : did'[s] = ans'.id]_vars

\* Op16_RefusedRecordsNothing: a refused [Record] writes no record
\* (Operation 16).
Op16_RefusedRecordsNothing ==
    [][Refusing => NewlyRecorded = {}]_vars

\* Op17_RefusedLeavesDatabase: a refused [Record] leaves every record as the
\* call found it (Operation 17).
Op17_RefusedLeavesDatabase ==
    [][Refusing => records' = records]_vars

\* Op29_OnlyRecordWrites: every step that changes the records is an admitted
\* [Record]'s one new record: a [Read] writes nothing, and the atom offers no
\* edit, removal or retraction (Operation 29; State 4, 5, 6).
Op29_OnlyRecordWrites ==
    [][records' # records => (Recording /\ RecordShaped)]_vars

\* Id8_SecondRecordAdmitted: in every state, [Record]'s guards admit every
\* well-formed call, a subject reference or a whole field set the records
\* carry already included: a second disclosure is a second record (Identity
\* 8; Non-goal 14, Concurrency 2).
Id8_SecondRecordAdmitted ==
    \A p \in Subjects, r \in Recipients, x \in Scopes, t \in AuthTypes, a \in Refs,
       d \in {-1} \cup 0..now :
        RecordAdmits(p, r, x, t, a, d)

\* Op18_InstantAscending: of two answered records, the one with the earlier
\* disclosure instant comes first (Operation 18).
Op18_InstantAscending ==
    \A f \in Filters : \A s, t \in ReadSet(f) :
        at[s] < at[t] => Pos(s, f) < Pos(t, f)

\* Op19_TiesByIdAscending: two answered records sharing a disclosure instant
\* take two places, the lower disclosure id first (Operation 19).
Op19_TiesByIdAscending ==
    \A f \in Filters : \A s, t \in ReadSet(f) :
        (s # t /\ at[s] = at[t]) => ((did[s] < did[t]) = (Pos(s, f) < Pos(t, f)))

\* Op20_EmptyWhenNoneMatches: where no record matches a well-formed query,
\* [Read] answers an empty record sequence (Operation 20, Check 5.3).
Op20_EmptyWhenNoneMatches ==
    \A f \in Filters :
        (\A s \in Live : ~PageMatch(s, f)) => ReadSet(f) = {}

\* Op27_EveryMatch: [Read] answers every record matching the query
\* (Operation 27; Check 5.1 for a subject reference query).
Op27_EveryMatch ==
    \A f \in Filters : \A s \in Live :
        PageMatch(s, f) => s \in ReadSet(f)

\* Op28_OnlyMatches: [Read] answers no record failing a filter of the query
\* (Operation 28; Check 5.2 for an authority type query; Identity 1 for a
\* disclosure id query).
Op28_OnlyMatches ==
    \A f \in Filters : \A s \in ReadSet(f) :
        s \in Live /\ PageMatch(s, f)

====
