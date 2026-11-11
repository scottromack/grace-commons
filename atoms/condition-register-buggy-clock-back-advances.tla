---- MODULE condition-register-buggy-clock-back-advances ----
\* DELIBERATELY WRONG twin of condition-register.tla (unit: `atoms/condition-register.md formal layer`).
\*
\* INJECTED DEFECT: the database refuses no advance, so a call whose clock reads early moves last
\* seen before first seen (Invariant 4.1 and 4.3 not enforced).
\*
\* BREAKS: Inv4_1_SpanForward, Inv4_3_LastSeenNeverBack.
\* Everything else is condition-register.tla as written; read its comments there.

EXTENDS Integers, FiniteSets

CONSTANTS
    SightConds,   \* the declared conditions of the sighting shape
    StandConds,   \* the declared conditions of the standing shape
    Subjects,     \* the subjects a [Record Sighting] call may carry (none blank)
    ScopeCalls,   \* the scopes a [Report Standing] or [Report Clear] call may carry
    Runs,         \* the run ids a call may carry (none blank)
    SightSlots,   \* the sighting slots: how many sightings the database can hold
    RecordIds,    \* the record ids the host can allocate: how many standing records the database can hold
    MaxTime       \* the last clock reading a call may carry

\* ---------------------------------------------------------------------------
\* Values
\* ---------------------------------------------------------------------------

\* Instants: the clock readings a call may carry.
Instants == 0..MaxTime

\* NoInstant: the value of an instant a record does not carry.
NoInstant == -1

\* WhitespaceOnly: the scopes the atom reads as blank: the empty string and a
\* string of spaces (String 5).
WhitespaceOnly == {"", " ", "  "}

\* Read: the scope as the atom reads and records it: blank ("") where the
\* call's scope is blank (Operation 41, String 6), else the scope as the call
\* supplies it (Operation 40).
Read(s) == IF s \in WhitespaceOnly THEN "" ELSE s

\* NoSight: an empty sighting slot.
NoSight == [cond |-> "none", subj |-> "none", run |-> "none", seen |-> NoInstant]

\* NoRec: a record id no standing record carries.
NoRec == [cond |-> "none", scope |-> "none", firstRun |-> "none", firstSeen |-> NoInstant,
          lastRun |-> "none", lastSeen |-> NoInstant, status |-> "none",
          closeRun |-> "none", closedAt |-> NoInstant]

\* ---------------------------------------------------------------------------
\* State
\* ---------------------------------------------------------------------------

VARIABLES
    part,    \* which part of the model this behaviour runs: "sightings" or "standing"
    sight,   \* sighting slot -> the sighting it holds, or NoSight
    stand    \* record id -> the standing record carrying it, or NoRec

\* vars: every variable, the tuple a step that changes nothing leaves as it was.
vars == <<part, sight, stand>>

\* TypeOK: each variable holds a value of its kind (the model's typing, not a
\* rule of the page).
TypeOK ==
    /\ part \in {"sightings", "standing"}
    /\ \A i \in SightSlots : sight[i].seen \in Instants \cup {NoInstant}
    /\ \A i \in RecordIds :
         /\ stand[i].status \in {"none", "open", "closed"}
         /\ stand[i].firstSeen \in Instants \cup {NoInstant}
         /\ stand[i].lastSeen \in Instants \cup {NoInstant}
         /\ stand[i].closedAt \in Instants \cup {NoInstant}

\* ---------------------------------------------------------------------------
\* Derived (never stored)
\* ---------------------------------------------------------------------------

\* Sighted: the sighting slot holds a sighting.
Sighted(i) == sight[i] # NoSight

\* Recorded: a standing record carries the record id.
Recorded(i) == stand[i] # NoRec

\* OpenFor: the record ids of the standing records open for condition c and the
\* scope s names (the "open standing record ... for the condition and the
\* scope" of Operation 12 to 24).
OpenFor(c, s) == {i \in RecordIds : stand[i].status = "open" /\ stand[i].cond = c
                                     /\ stand[i].scope = Read(s)}

\* SpanKey: the fields of a standing record Invariant 1.2 holds fixed, the
\* record id aside (it is the slot): condition, scope, first run id, first seen.
SpanKey(r) == <<r.cond, r.scope, r.firstRun, r.firstSeen>>

\* ---------------------------------------------------------------------------
\* Actions
\* ---------------------------------------------------------------------------

\* Init: one of the two parts, with no sighting and no standing record.
Init ==
    /\ part \in {"sightings", "standing"}
    /\ sight = [i \in SightSlots |-> NoSight]
    /\ stand = [i \in RecordIds |-> NoRec]

\* RecordSighting: [Record Sighting] of condition c about subject u by run r at
\* clock reading t. Where a sighting of c about u exists the call answers
\* duplicate and writes nothing (Operation 4; the database refuses the write,
\* Invariant 2.2), so it is no step. Otherwise exactly one sighting lands in
\* the first free slot, carrying c, u and r (Operation 5, 38) and the seen
\* instant t (Operation 6).
RecordSighting(c, u, r, t) ==
    /\ part = "sightings"
    /\ ~\E j \in SightSlots : sight[j].cond = c /\ sight[j].subj = u     \* Operation 4, Invariant 2.2
    /\ \E i \in SightSlots :
         /\ ~Sighted(i)
         /\ \A j \in SightSlots : ~Sighted(j) => i <= j
         /\ sight' = [sight EXCEPT ![i] = [cond |-> c, subj |-> u, run |-> r, seen |-> t]]
    /\ UNCHANGED <<part, stand>>

\* Advance: [Report Standing] of condition c in scope s by run r at clock
\* reading t, where record id i stands open for c and s. The database refuses
\* a write whose last seen precedes the record's first seen (Invariant 4.1) or
\* its stored last seen (Invariant 4.3): the call answers storage-failure and
\* writes nothing, so it is no step. Otherwise the record's last run id
\* becomes r (Operation 12) and its last seen t (Operation 13).
Advance(c, s, r, t) ==
    /\ part = "standing"
    /\ OpenFor(c, s) # {}
    /\ LET i == CHOOSE x \in OpenFor(c, s) : TRUE
       IN  /\ stand' = [stand EXCEPT ![i].lastRun = r, ![i].lastSeen = t]  \* Operation 12, 13
    /\ UNCHANGED <<part, sight>>

\* Open: [Report Standing] of condition c in scope s by run r at clock reading
\* t, where no standing record stands open for c and s (Operation 15; the
\* database refuses a second open record, Invariant 3.2). Exactly one standing
\* record lands in open under the first record id no record carries (Identity
\* 3, Operation 39), carrying c, the scope as read (Operation 40, 41), r as
\* first and last run id (Operation 16) and t as first and last seen
\* (Operation 17).
Open(c, s, r, t) ==
    /\ part = "standing"
    /\ OpenFor(c, s) = {}                                             \* Operation 15, Invariant 3.2
    /\ \E i \in RecordIds :
         /\ ~Recorded(i)
         /\ \A j \in RecordIds : ~Recorded(j) => i <= j
         /\ stand' = [stand EXCEPT ![i] =
                        [cond |-> c, scope |-> Read(s), firstRun |-> r, firstSeen |-> t,
                         lastRun |-> r, lastSeen |-> t, status |-> "open",
                         closeRun |-> "none", closedAt |-> NoInstant]]
    /\ UNCHANGED <<part, sight>>

\* Close: [Report Clear] of condition c in scope s by run r at clock reading t,
\* where record id i stands open for c and s. The database refuses a write
\* whose closing instant precedes the record's last seen (Invariant 4.2): no
\* step. Otherwise the record stands in closed (Operation 19), r its closing
\* run id (Operation 20) and t its closing instant (Operation 21), its last
\* seen as it was (Operation 22). With nothing open the call answers none-open
\* and writes nothing (Operation 24): no step.
Close(c, s, r, t) ==
    /\ part = "standing"
    /\ OpenFor(c, s) # {}
    /\ LET i == CHOOSE x \in OpenFor(c, s) : TRUE
       IN  /\ t >= stand[i].lastSeen                                  \* Invariant 4.2
           /\ stand' = [stand EXCEPT ![i].status = "closed", ![i].closeRun = r,
                                     ![i].closedAt = t]               \* Operation 19, 20, 21
    /\ UNCHANGED <<part, sight>>

\* Next: any call of any arguments at any clock reading.
Next ==
    \/ \E c \in SightConds, u \in Subjects, r \in Runs, t \in Instants : RecordSighting(c, u, r, t)
    \/ \E c \in StandConds, s \in ScopeCalls, r \in Runs, t \in Instants : Advance(c, s, r, t)
    \/ \E c \in StandConds, s \in ScopeCalls, r \in Runs, t \in Instants : Open(c, s, r, t)
    \/ \E c \in StandConds, s \in ScopeCalls, r \in Runs, t \in Instants : Close(c, s, r, t)

\* Spec: every behaviour from Init by Next steps.
Spec == Init /\ [][Next]_vars

\* ---------------------------------------------------------------------------
\* Checks (the verification surface)
\* ---------------------------------------------------------------------------

\* Inv1_1_SightingFixed: no step changes a recorded sighting's condition,
\* subject, run id or seen instant: what a run saw reads the same forever
\* (Invariant 1.1, Check 1.3).
Inv1_1_SightingFixed ==
    [][\A i \in SightSlots : Sighted(i) => sight'[i] = sight[i]]_vars

\* Inv1_2_SpanKeyFixed: no step changes a standing record's record id,
\* condition, scope, first run id or first seen: a span's start can never be
\* moved (Invariant 1.2, Check 4.2).
Inv1_2_SpanKeyFixed ==
    [][\A i \in RecordIds : Recorded(i) => SpanKey(stand'[i]) = SpanKey(stand[i])]_vars

\* Inv1_3_ClosedFixed: no step changes a closed standing record: no transition
\* out of closed, no reopen, no second close (Invariant 1.3, State 6,
\* Operation 37; Check 1.4).
Inv1_3_ClosedFixed ==
    [][\A i \in RecordIds : stand[i].status = "closed" => stand'[i] = stand[i]]_vars

\* Inv1_4_NeverRemoved: no step removes a sighting or a standing record
\* (Invariant 1.4, State 7, Operation 36).
Inv1_4_NeverRemoved ==
    [][/\ \A i \in SightSlots : Sighted(i) => sight'[i] # NoSight
       /\ \A i \in RecordIds : Recorded(i) => stand'[i] # NoRec]_vars

\* Inv2_1_OneSightingPerSubject: in every reachable state no two sightings
\* share a condition and a subject, however many runs find the act
\* (Invariant 2.1, Check 2.1).
Inv2_1_OneSightingPerSubject ==
    \A i, j \in SightSlots :
        (i # j /\ Sighted(i) /\ Sighted(j))
            => ~(sight[i].cond = sight[j].cond /\ sight[i].subj = sight[j].subj)

\* Inv3_1_OneOpenSpan: in every reachable state no two open standing records
\* share a condition and a scope, every blank scope read as one scope
\* (String 6): an outage is one record while it lasts (Invariant 3.1,
\* Check 3.1).
Inv3_1_OneOpenSpan ==
    \A i, j \in RecordIds :
        (i # j /\ stand[i].status = "open" /\ stand[j].status = "open"
         /\ stand[i].cond = stand[j].cond)
            => Read(stand[i].scope) # Read(stand[j].scope)

\* Inv4_1_SpanForward: in every reachable state no standing record's last seen
\* precedes its first seen (Invariant 4.1, Check 4.1).
Inv4_1_SpanForward ==
    \A i \in RecordIds : Recorded(i) => stand[i].lastSeen >= stand[i].firstSeen

\* Inv4_2_ClosesAfterLastSeen: in every reachable state no closed standing
\* record's closing instant precedes its last seen (Invariant 4.2, Check 4.4).
Inv4_2_ClosesAfterLastSeen ==
    \A i \in RecordIds : stand[i].status = "closed" => stand[i].closedAt >= stand[i].lastSeen

\* Inv4_3_LastSeenNeverBack: no step moves a standing record's last seen to an
\* earlier instant: a span only grows forward, so an outage can never be
\* shortened (Invariant 4.3, Check 4.3).
Inv4_3_LastSeenNeverBack ==
    [][\A i \in RecordIds :
         (Recorded(i) /\ stand'[i] # NoRec) => stand'[i].lastSeen >= stand[i].lastSeen]_vars

\* Op22_ClearKeepsLastSeen: a step that closes a standing record leaves its last
\* seen as it was: the span ends at the last run that saw the condition, not
\* at the run that found it clear (Operation 22).
Op22_ClearKeepsLastSeen ==
    [][\A i \in RecordIds :
         (stand[i].status = "open" /\ stand'[i].status = "closed")
             => stand'[i].lastSeen = stand[i].lastSeen]_vars

====
