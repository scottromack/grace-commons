---- MODULE owed-record-buggy-flag-toggles ----
\* DELIBERATELY WRONG twin of owed-record.tla (unit: `atoms/owed-record.md formal layer`).
\*
\* INJECTED DEFECT: [Flag] of a flagged record clears the flag back to open (a toggle)
\* instead of answering already-flagged (Operation 23).
\*
\* BREAKS: State8_FlaggedNeverReopens.
\* Everything else is owed-record.tla as written; read its comments there.

EXTENDS Integers, FiniteSets

CONSTANTS
    Patterns,     \* the owing patterns a call may name
    Ids,          \* the owed ids a call may name
    Causes,       \* the cause ids a [Record Owed] may carry
    Fulfilments,  \* the fulfilment ids a [Discharge] may carry
    Actors,       \* the actor references a [Flag] may carry
    Windows,      \* the due-by windows a [Record Owed] may carry, each above zero
    MaxTime,      \* the last instant the clock reaches in the model
    MaxRecs       \* how many owed records the model's database holds room for

\* NONE: the value of a string field not yet written.
NONE == "none"

\* Slots: the places an owed record can occupy, in the order they are recorded.
Slots == 1..MaxRecs

\* Statuses: the page's three statuses (Term status), and "none" for a slot
\* holding no record.
Statuses == {"open", "flagged", "discharged"}

\* NoCall: the record of the last call before any call is made, and the shape
\* of every such record: the action, the pair and slot it named, and what it
\* answered.
NoCall == [op |-> "none", pat |-> NONE, oid |-> NONE, slot |-> 0, ans |-> "none"]

\* ---------------------------------------------------------------------------
\* State
\* ---------------------------------------------------------------------------

VARIABLES
    now,     \* the host's clock reading, injected at the seam
    n,       \* the next slot a recorded owed record takes
    pat,     \* slot -> owing pattern
    oid,     \* slot -> owed id
    cause,   \* slot -> cause id
    recAt,   \* slot -> recording instant (0: none)
    due,     \* slot -> due-by instant (0: none)
    status,  \* slot -> status ("none": no record)
    ful,     \* slot -> fulfilment id
    disAt,   \* slot -> discharge instant (0: none)
    flagAt,  \* slot -> flag instant (0: none)
    actor,   \* slot -> actor reference
    dcount,  \* slot -> how many [Discharge] calls on it answered discharged (the model's own count)
    last     \* the last call made and what it answered (NoCall's shape)

\* vars: every variable; a step that changes none of them is a stutter.
vars == <<now, n, pat, oid, cause, recAt, due, status, ful, disAt, flagAt, actor, dcount, last>>

\* records: every variable that holds an owed record's fields: what the
\* database holds.
records == <<n, pat, oid, cause, recAt, due, status, ful, disAt, flagAt, actor>>

\* Recorded: the slot holds an owed record [Record Owed] recorded.
Recorded(s) == s < n

\* Exists: an owed record names the owing pattern and the owed id (Identity 1).
Exists(p, o) == \E s \in Slots : Recorded(s) /\ pat[s] = p /\ oid[s] = o

\* TypeOK: each variable holds a value of its kind (the model's typing, not a
\* rule of the page).
TypeOK ==
    /\ now \in 1..MaxTime
    /\ n \in 1..(MaxRecs + 1)
    /\ pat \in [Slots -> Patterns \cup {NONE}]
    /\ oid \in [Slots -> Ids \cup {NONE}]
    /\ cause \in [Slots -> Causes \cup {NONE}]
    /\ recAt \in [Slots -> Nat]
    /\ due \in [Slots -> Nat]
    /\ status \in [Slots -> Statuses \cup {"none"}]
    /\ ful \in [Slots -> Fulfilments \cup {NONE}]
    /\ disAt \in [Slots -> Nat]
    /\ flagAt \in [Slots -> Nat]
    /\ actor \in [Slots -> Actors \cup {NONE}]
    /\ dcount \in [Slots -> Nat]

\* Init: no owed record; the clock at its first instant.
Init ==
    /\ now = 1
    /\ n = 1
    /\ pat = [s \in Slots |-> NONE]
    /\ oid = [s \in Slots |-> NONE]
    /\ cause = [s \in Slots |-> NONE]
    /\ recAt = [s \in Slots |-> 0]
    /\ due = [s \in Slots |-> 0]
    /\ status = [s \in Slots |-> "none"]
    /\ ful = [s \in Slots |-> NONE]
    /\ disAt = [s \in Slots |-> 0]
    /\ flagAt = [s \in Slots |-> 0]
    /\ actor = [s \in Slots |-> NONE]
    /\ dcount = [s \in Slots |-> 0]
    /\ last = NoCall

\* ---------------------------------------------------------------------------
\* Actions
\* ---------------------------------------------------------------------------

\* Tick: the host's clock moves on by a second; no record is written.
Tick ==
    /\ now < MaxTime
    /\ now' = now + 1
    /\ last' = [NoCall EXCEPT !.op = "tick"]
    /\ UNCHANGED <<n, pat, oid, cause, recAt, due, status, ful, disAt, flagAt, actor, dcount>>

\* RecordAdmitted: [Record Owed] for a pair no owed record names records one
\* owed record in open (Operation 1, 2), carrying the pair and the cause id,
\* the injected now as its recording instant (Operation 3) and the due-by
\* deadline as its due-by instant (Operation 4), and answers recorded
\* (Operation 5).
RecordAdmitted(p, o, c, w) ==
    /\ n <= MaxRecs
    /\ ~Exists(p, o)
    /\ pat' = [pat EXCEPT ![n] = p]
    /\ oid' = [oid EXCEPT ![n] = o]
    /\ cause' = [cause EXCEPT ![n] = c]
    /\ recAt' = [recAt EXCEPT ![n] = now]
    /\ due' = [due EXCEPT ![n] = now + w]
    /\ status' = [status EXCEPT ![n] = "open"]
    /\ n' = n + 1
    /\ last' = [op |-> "record", pat |-> p, oid |-> o, slot |-> n, ans |-> "recorded"]
    /\ UNCHANGED <<now, ful, disAt, flagAt, actor, dcount>>

\* RecordDuplicate: [Record Owed] for a pair an owed record already names
\* answers duplicate and writes nothing (Operation 6).
RecordDuplicate(p, o) ==
    /\ Exists(p, o)
    /\ last' = [op |-> "record", pat |-> p, oid |-> o, slot |-> 0, ans |-> "duplicate"]
    /\ UNCHANGED <<now, n, pat, oid, cause, recAt, due, status, ful, disAt, flagAt, actor, dcount>>

\* Discharge: [Discharge] of an open or a flagged record (Operation 15) stands
\* it in discharged (Operation 16), stamps the injected now as its discharge
\* instant (Operation 17), records the fulfilment id (Operation 18), keeps any
\* flag instant and actor reference, and answers discharged (Operation 19).
Discharge(s, f) ==
    /\ Recorded(s)
    /\ status[s] \in {"open", "flagged"}
    /\ status' = [status EXCEPT ![s] = "discharged"]
    /\ ful' = [ful EXCEPT ![s] = f]
    /\ disAt' = [disAt EXCEPT ![s] = now]
    /\ dcount' = [dcount EXCEPT ![s] = dcount[s] + 1]
    /\ last' = [op |-> "discharge", pat |-> pat[s], oid |-> oid[s], slot |-> s, ans |-> "discharged"]
    /\ UNCHANGED <<now, n, pat, oid, cause, recAt, due, flagAt, actor>>

\* DischargeAlready: [Discharge] of a discharged record answers
\* already-discharged and writes nothing (Operation 13).
DischargeAlready(s) ==
    /\ Recorded(s)
    /\ status[s] = "discharged"
    /\ last' = [op |-> "discharge", pat |-> pat[s], oid |-> oid[s], slot |-> s, ans |-> "already-discharged"]
    /\ UNCHANGED <<now, n, pat, oid, cause, recAt, due, status, ful, disAt, flagAt, actor, dcount>>

\* Flag: [Flag] of an open record whose due-by instant has come (Operation 24)
\* stands it in flagged (Operation 26), stamps the injected now as its flag
\* instant (Operation 27), records the actor reference (Operation 28) and
\* answers flagged (Operation 29).
Flag(s, a) ==
    /\ Recorded(s)
    /\ status[s] = "open"
    /\ now >= due[s]
    /\ status' = [status EXCEPT ![s] = "flagged"]
    /\ flagAt' = [flagAt EXCEPT ![s] = now]
    /\ actor' = [actor EXCEPT ![s] = a]
    /\ last' = [op |-> "flag", pat |-> pat[s], oid |-> oid[s], slot |-> s, ans |-> "flagged"]
    /\ UNCHANGED <<now, n, pat, oid, cause, recAt, due, ful, disAt, dcount>>

\* FlagNotDue: [Flag] of an open record whose due-by instant is still ahead
\* answers not-due and writes nothing (Operation 24).
FlagNotDue(s) ==
    /\ Recorded(s)
    /\ status[s] = "open"
    /\ now < due[s]
    /\ last' = [op |-> "flag", pat |-> pat[s], oid |-> oid[s], slot |-> s, ans |-> "not-due"]
    /\ UNCHANGED <<now, n, pat, oid, cause, recAt, due, status, ful, disAt, flagAt, actor, dcount>>

\* FlagAlready: [Flag] of a flagged or a discharged record answers
\* already-flagged or already-discharged and writes nothing (Operation 22, 23).
FlagAlready(s) ==
    /\ Recorded(s)
    /\ status[s] \in {"flagged", "discharged"}
    /\ status' = [status EXCEPT ![s] = IF status[s] = "flagged" THEN "open" ELSE status[s]]   \* BUG: toggled
    /\ last' = [op |-> "flag", pat |-> pat[s], oid |-> oid[s], slot |-> s,
                ans |-> IF status[s] = "flagged" THEN "already-flagged" ELSE "already-discharged"]
    /\ UNCHANGED <<now, n, pat, oid, cause, recAt, due, ful, disAt, flagAt, actor, dcount>>

\* ListOwed: [List Owed] of one owing pattern in open or flagged answers the
\* matching records and writes nothing (Operation 31, 36).
ListOwed(p, ls) ==
    /\ ls \in {"open", "flagged"}
    /\ last' = [op |-> "list", pat |-> p, oid |-> NONE, slot |-> 0, ans |-> ls]
    /\ UNCHANGED <<now, n, pat, oid, cause, recAt, due, status, ful, disAt, flagAt, actor, dcount>>

\* Next: the clock moving, or any call: an admitted or a refused [Record Owed],
\* [Discharge] or [Flag], or a [List Owed].
Next ==
    \/ Tick
    \/ \E p \in Patterns, o \in Ids, c \in Causes, w \in Windows : RecordAdmitted(p, o, c, w)
    \/ \E p \in Patterns, o \in Ids : RecordDuplicate(p, o)
    \/ \E s \in Slots, f \in Fulfilments : Discharge(s, f)
    \/ \E s \in Slots : DischargeAlready(s)
    \/ \E s \in Slots, a \in Actors : Flag(s, a)
    \/ \E s \in Slots : FlagNotDue(s)
    \/ \E s \in Slots : FlagAlready(s)
    \/ \E p \in Patterns, ls \in {"open", "flagged"} : ListOwed(p, ls)

\* Spec: every behaviour from Init by Next steps.
Spec == Init /\ [][Next]_vars

\* ---------------------------------------------------------------------------
\* Checks (the verification surface)
\* ---------------------------------------------------------------------------

\* Inv1_1_OwedFixed: no step changes a recorded owed record's owing pattern,
\* owed id, cause id, recording instant or due-by instant: what was owed, by
\* whom and for what cause reads the same for ever (Invariant 1.1, Check 1.2).
Inv1_1_OwedFixed ==
    [][\A s \in Slots : Recorded(s) =>
          /\ pat'[s] = pat[s]
          /\ oid'[s] = oid[s]
          /\ cause'[s] = cause[s]
          /\ recAt'[s] = recAt[s]
          /\ due'[s] = due[s]]_vars

\* Inv1_2_SettlementFixed: no step changes a settlement field once written:
\* the fulfilment id, the discharge instant, the flag instant, the actor
\* reference (Invariant 1.2, Term settlement field). A flag stays on a record
\* discharged after it.
Inv1_2_SettlementFixed ==
    [][\A s \in Slots :
          /\ (ful[s] # NONE => ful'[s] = ful[s])
          /\ (disAt[s] # 0 => disAt'[s] = disAt[s])
          /\ (flagAt[s] # 0 => flagAt'[s] = flagAt[s])
          /\ (actor[s] # NONE => actor'[s] = actor[s])]_vars

\* Inv2_2_SecondRecordRefused: a [Record Owed] naming a pair an owed record
\* already names changes nothing in the database: the write of a second record
\* for one obligation is refused, not merged into the first (Invariant 2.2).
Inv2_2_SecondRecordRefused ==
    [][(last'.op = "record" /\ Exists(last'.pat, last'.oid)) => UNCHANGED records]_vars

\* Inv3_1_DischargedOnce: no owed record has had more than one [Discharge]
\* answered discharged, so it names one fulfilment (Invariant 3.1,
\* Concurrency 1).
Inv3_1_DischargedOnce ==
    \A s \in Slots : dcount[s] <= 1

\* Inv3_2_DischargedStays: no step moves a discharged owed record out of
\* discharged (Invariant 3.2, State 7).
Inv3_2_DischargedStays ==
    [][\A s \in Slots : status[s] = "discharged" => status'[s] = "discharged"]_vars

\* State8_FlaggedNeverReopens: no step moves a flagged owed record back to
\* open: a flag is settled only by a discharge (State 8).
State8_FlaggedNeverReopens ==
    [][\A s \in Slots : status[s] = "flagged" => status'[s] # "open"]_vars

\* Inv5_1_NothingLost: no step removes an owed record: a slot holding a record
\* holds one after every step, so each obligation stays to be matched against
\* its fulfilment or its flag (Invariant 5.1, State 9).
Inv5_1_NothingLost ==
    [][\A s \in Slots : status[s] # "none" => status'[s] # "none"]_vars

\* Con2_DischargeAnswersDischarged: a [Discharge] of an open or a flagged
\* record answers discharged, so a [Flag] that commits first never turns it
\* away (Concurrency 2, Operation 15).
Con2_DischargeAnswersDischarged ==
    [][(last'.op = "discharge" /\ status[last'.slot] \in {"open", "flagged"})
           => last'.ans = "discharged"]_vars

\* Op24_NotDueOnlyBeforeDue: a [Flag] answered not-due was made while now
\* preceded the record's due-by instant: a record is due at that instant
\* (Operation 24).
Op24_NotDueOnlyBeforeDue ==
    [][(last'.op = "flag" /\ last'.ans = "not-due") => now < due[last'.slot]]_vars

\* Op36_ListWritesNothing: a [List Owed] step changes no owed record
\* (Operation 36).
Op36_ListWritesNothing ==
    [][last'.op = "list" => UNCHANGED records]_vars

====
