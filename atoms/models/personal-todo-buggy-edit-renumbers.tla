---- MODULE personal-todo-buggy-edit-renumbers ----
\* DELIBERATELY WRONG twin of personal-todo.tla (unit: `atoms/personal-todo.md formal layer`).
\*
\* INJECTED DEFECT: [Edit] writes the edited unit under a fresh id, as a store keyed by the text
\* would (Invariant 8.3).
\*
\* BREAKS: Inv8_3_EditKeepsId.
\* Everything else is personal-todo.tla as written; read its comments there.

EXTENDS Integers

CONSTANTS
    MaxUnits,   \* how many units [Add] may record in the model
    MaxIds,     \* how many ids the seam may allocate
    MaxTime,    \* the clock's last reading
    Texts       \* the texts a call may carry as a description

\* Slots: the units in the order [Add] recorded them. A slot is the model's
\* own name for a unit, so a check can ask whether its id ever changes.
Slots == 1..MaxUnits

\* Norm: the description policy's normalizer: leading and trailing
\* whitespace trimmed (Description 1). " milk" is "milk".
Norm(t) == IF t = " milk" THEN "milk" ELSE t

\* Fold: what a case-folding comparison would make of a text. The page
\* forbids it (Description 6, Non-goal 15): the model's own actions never
\* apply it; it is here so a twin can.
Fold(t) == IF t = "Milk" THEN "milk" ELSE t

\* NoCall: the record of the last call before any call is made, and the
\* shape of every such record: the action, the text it carried and what it
\* answered.
NoCall == [op |-> "none", text |-> "none", ans |-> "none"]

\* ---------------------------------------------------------------------------
\* State
\* ---------------------------------------------------------------------------

VARIABLES
    inList,     \* slot -> whether the unit stands in the list (FALSE once deleted)
    st,         \* slot -> the unit state ("none" before the unit is recorded)
    uid,        \* slot -> the unit's id (0 before it is recorded)
    desc,       \* slot -> the unit's description ("none" before it is recorded)
    added,      \* slot -> the addition instant (0 before it is recorded)
    edited,     \* slot -> the last edit instant (0: blank, State 3)
    completed,  \* slot -> the completion instant (0: blank)
    cdone,      \* slot -> whether an admitted [Complete] named the unit
    deleted,    \* slot -> whether an admitted [Delete] named the unit
    nextSlot,   \* the slot the next [Add] records into
    nextId,     \* the next id the seam allocates (Identity 2)
    now,        \* the clock's reading, injected at the seam (Term now)
    last        \* the last call made and what it answered (NoCall's shape)

\* vars: every variable; a step that changes none of them is a stutter.
vars == <<inList, st, uid, desc, added, edited, completed, cdone, deleted,
          nextSlot, nextId, now, last>>

\* records: every variable that holds a unit's fields or the list.
records == <<inList, st, uid, desc, added, edited, completed>>

\* Descs: the normalized texts, the only ones a unit carries.
Descs == {Norm(t) : t \in Texts}

\* TypeOK: each variable holds a value of its kind (the model's typing, not a
\* rule of the page).
TypeOK ==
    /\ inList \in [Slots -> BOOLEAN]
    /\ st \in [Slots -> {"none", "pending", "done"}]
    /\ uid \in [Slots -> 0..MaxIds]
    /\ desc \in [Slots -> Descs \cup {"none"}]
    /\ added \in [Slots -> 0..MaxTime]
    /\ edited \in [Slots -> 0..MaxTime]
    /\ completed \in [Slots -> 0..MaxTime]
    /\ cdone \in [Slots -> BOOLEAN]
    /\ deleted \in [Slots -> BOOLEAN]
    /\ nextSlot \in 1..(MaxUnits + 1)
    /\ nextId \in 1..(MaxIds + 1)
    /\ now \in 1..MaxTime
    /\ last \in [op : {"none", "add", "edit", "complete", "delete", "read", "tick"},
                 text : Texts \cup {"none"},
                 ans : {"none", "id", "ok", "duplicate-active"}]

\* Init: an empty list, the clock at its first reading.
Init ==
    /\ inList = [k \in Slots |-> FALSE]
    /\ st = [k \in Slots |-> "none"]
    /\ uid = [k \in Slots |-> 0]
    /\ desc = [k \in Slots |-> "none"]
    /\ added = [k \in Slots |-> 0]
    /\ edited = [k \in Slots |-> 0]
    /\ completed = [k \in Slots |-> 0]
    /\ cdone = [k \in Slots |-> FALSE]
    /\ deleted = [k \in Slots |-> FALSE]
    /\ nextSlot = 1
    /\ nextId = 1
    /\ now = 1
    /\ last = NoCall

\* ---------------------------------------------------------------------------
\* Actions
\* ---------------------------------------------------------------------------

\* Add: [Add] of a text whose normalized form no unit in the active set
\* carries (Operation 4, Description 6, 7) records one unit carrying the id
\* the seam allocates (Identity 2, 4), the normalized description (Operation
\* 1), pending (Operation 2) and the addition instant from now (State 5),
\* and answers the id (Operation 3).
Add(t) ==
    /\ nextSlot <= MaxUnits
    /\ nextId <= MaxIds
    /\ ~\E k \in Slots : inList[k] /\ desc[k] = Norm(t)
    /\ inList' = [inList EXCEPT ![nextSlot] = TRUE]
    /\ st' = [st EXCEPT ![nextSlot] = "pending"]
    /\ uid' = [uid EXCEPT ![nextSlot] = nextId]
    /\ desc' = [desc EXCEPT ![nextSlot] = Norm(t)]
    /\ added' = [added EXCEPT ![nextSlot] = now]
    /\ nextSlot' = nextSlot + 1
    /\ nextId' = nextId + 1
    /\ last' = [op |-> "add", text |-> t, ans |-> "id"]
    /\ UNCHANGED <<edited, completed, cdone, deleted, now>>

\* AddDuplicate: [Add] of a text whose normalized form a unit in the active
\* set carries, pending or done, answers duplicate-active and writes nothing
\* (Operation 4).
AddDuplicate(t) ==
    /\ \E k \in Slots : inList[k] /\ desc[k] = Norm(t)
    /\ last' = [op |-> "add", text |-> t, ans |-> "duplicate-active"]
    /\ UNCHANGED <<inList, st, uid, desc, added, edited, completed, cdone, deleted,
                   nextSlot, nextId, now>>

\* EditNew: [Edit] of a pending unit (Operation 8) with a text whose
\* normalized form differs from the unit's description (Operation 13) and
\* that no other unit in the active set carries (Operation 9) replaces the
\* description and stamps the last edit instant from now (State 6).
EditNew(k, t) ==
    /\ inList[k]
    /\ st[k] = "pending"
    /\ Norm(t) # desc[k]
    /\ ~\E j \in Slots : j # k /\ inList[j] /\ desc[j] = Norm(t)
    /\ desc' = [desc EXCEPT ![k] = Norm(t)]
    /\ edited' = [edited EXCEPT ![k] = now]
    /\ nextId <= MaxIds
    /\ uid' = [uid EXCEPT ![k] = nextId]                    \* BUG: a fresh id
    /\ nextId' = nextId + 1
    /\ last' = [op |-> "edit", text |-> t, ans |-> "ok"]
    /\ UNCHANGED <<inList, st, added, completed, cdone, deleted, nextSlot, now>>

\* EditSame: [Edit] of a pending unit with a text whose normalized form is
\* the unit's own description answers ok (Operation 10) and stamps nothing
\* (Operation 12): it writes the unit unchanged (Execution Contract
\* Conformance 1).
EditSame(k, t) ==
    /\ inList[k]
    /\ st[k] = "pending"
    /\ Norm(t) = desc[k]
    /\ last' = [op |-> "edit", text |-> t, ans |-> "ok"]
    /\ UNCHANGED <<inList, st, uid, desc, added, edited, completed, cdone, deleted,
                   nextSlot, nextId, now>>

\* Complete: [Complete] of a pending unit (Operation 16) stands it in done
\* (Operation 17) and stamps the completion instant from now (State 7).
Complete(k) ==
    /\ inList[k]
    /\ st[k] = "pending"
    /\ st' = [st EXCEPT ![k] = "done"]
    /\ completed' = [completed EXCEPT ![k] = now]
    /\ cdone' = [cdone EXCEPT ![k] = TRUE]
    /\ last' = [NoCall EXCEPT !.op = "complete", !.ans = "ok"]
    /\ UNCHANGED <<inList, uid, desc, added, edited, deleted, nextSlot, nextId, now>>

\* Delete: [Delete] of a unit in the list, pending or done, takes it out of
\* the list (Operation 19, 20, State 8); the seam never allocates its id
\* again (Identity 5).
Delete(k) ==
    /\ inList[k]
    /\ inList' = [inList EXCEPT ![k] = FALSE]
    /\ deleted' = [deleted EXCEPT ![k] = TRUE]
    /\ last' = [NoCall EXCEPT !.op = "delete", !.ans = "ok"]
    /\ UNCHANGED <<st, uid, desc, added, edited, completed, cdone, nextSlot, nextId, now>>

\* Read: [Read] answers every unit and writes nothing (Operation 28 to 31).
Read ==
    /\ last' = [NoCall EXCEPT !.op = "read", !.ans = "ok"]
    /\ UNCHANGED <<inList, st, uid, desc, added, edited, completed, cdone, deleted,
                   nextSlot, nextId, now>>

\* Tick: the clock moves forward (Execution Contract Logic confinement 7: its
\* readings never go backward, the deployment's guarantee).
Tick ==
    /\ now < MaxTime
    /\ now' = now + 1
    /\ last' = [NoCall EXCEPT !.op = "tick"]
    /\ UNCHANGED <<inList, st, uid, desc, added, edited, completed, cdone, deleted,
                   nextSlot, nextId>>

\* Next: any admitted call, a refused [Add] of a duplicate, a [Read], or a
\* move of the clock.
Next ==
    \/ \E t \in Texts : Add(t)
    \/ \E t \in Texts : AddDuplicate(t)
    \/ \E k \in Slots, t \in Texts : EditNew(k, t)
    \/ \E k \in Slots, t \in Texts : EditSame(k, t)
    \/ \E k \in Slots : Complete(k)
    \/ \E k \in Slots : Delete(k)
    \/ Read
    \/ Tick

\* Spec: every behaviour from Init by Next steps.
Spec == Init /\ [][Next]_vars

\* ---------------------------------------------------------------------------
\* Checks (the verification surface)
\* ---------------------------------------------------------------------------

\* Inv2_1_PendingOnlyIfUntouched: a unit standing in pending in the list has
\* had no admitted [Complete] and no admitted [Delete] (Invariant 2.1).
Inv2_1_PendingOnlyIfUntouched ==
    \A k \in Slots : (inList[k] /\ st[k] = "pending") => (~cdone[k] /\ ~deleted[k])

\* Inv3_1_DoneOnlyIfNotDeleted: a unit standing in done in the list has had
\* no admitted [Delete] (Invariant 3.1).
Inv3_1_DoneOnlyIfNotDeleted ==
    \A k \in Slots : (inList[k] /\ st[k] = "done") => ~deleted[k]

\* Inv4_1_DeletedIdNotInList: no unit in the list carries the id of a
\* deleted unit, so a deleted unit never comes back under its id, a fresh
\* [Add] of its text included (Invariant 4.1, Check 2.1, Re-adding 2).
Inv4_1_DeletedIdNotInList ==
    \A k \in Slots : deleted[k] => ~\E j \in Slots : inList[j] /\ uid[j] = uid[k]

\* Inv5_2_EditChangesOnlyDescription: an [Edit] step changes no field but
\* a description and a last edit instant: no unit's place in the list,
\* state, id, addition instant or completion instant (Invariant 5.2,
\* Operation 14, Check 3.3).
Inv5_2_EditChangesOnlyDescription ==
    [][last'.op = "edit" =>
          \A k \in Slots : /\ inList'[k] = inList[k]
                           /\ st'[k] = st[k]
                           /\ uid'[k] = uid[k]
                           /\ added'[k] = added[k]
                           /\ completed'[k] = completed[k]]_vars

\* Inv8_2_IdNeverChanges: no step changes the id of a recorded unit
\* (Invariant 8.2).
Inv8_2_IdNeverChanges ==
    [][\A k \in Slots : k < nextSlot => uid'[k] = uid[k]]_vars

\* Inv8_3_EditKeepsId: an [Edit] step changes no unit's id, so editing the
\* wording of a task leaves which task it is (Invariant 8.3, Check 2.3).
Inv8_3_EditKeepsId ==
    [][last'.op = "edit" => \A k \in Slots : uid'[k] = uid[k]]_vars

\* State9_NoDoneToPending: a done unit that stays in the list stays done:
\* no step stands it back in pending (State 9, Non-goal 8).
State9_NoDoneToPending ==
    [][\A k \in Slots : (inList[k] /\ st[k] = "done" /\ inList'[k]) => st'[k] = "done"]_vars

\* Op12_SameTextEditStampsNothing: an [Edit] step that leaves a unit's
\* description as it was leaves its last edit instant as it was
\* (Operation 12, Check 3.4).
Op12_SameTextEditStampsNothing ==
    [][last'.op = "edit" =>
          \A k \in Slots : (desc'[k] = desc[k] => edited'[k] = edited[k])]_vars

\* Op4_DuplicateOnlyOnActiveMatch: an [Add] answered duplicate-active was
\* for a text whose normalized form a unit in the active set carries, the
\* same case for case: Milk is not refused because the list holds milk
\* (Description 6), and a deleted unit's text is not remembered (Re-adding
\* 1, Non-goal 4).
Op4_DuplicateOnlyOnActiveMatch ==
    (last.op = "add" /\ last.ans = "duplicate-active")
        => \E k \in Slots : inList[k] /\ desc[k] = Norm(last.text)

\* Op30_ReadWritesNothing: a [Read] step changes no unit and no unit's place
\* in the list (Operation 30).
Op30_ReadWritesNothing ==
    [][last'.op = "read" => UNCHANGED records]_vars

====
