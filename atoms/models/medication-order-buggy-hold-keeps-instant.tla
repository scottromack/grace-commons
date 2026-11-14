---- MODULE medication-order-buggy-hold-keeps-instant ----
\* Grace Commons — Medication Order atom (atoms/medication-order.md).
\* Grounded on Final Critique 7, 2026-11-05 at ec26ba5 — TLA+ layer first
\* written 2026-06-04 (Invariant 5 alone), re-derived 2026-11-11 over the
\* whole lifecycle (unit `atoms/medication-order.md formal layer`).
\* BUGGY TWIN of medication-order.tla: identical EXCEPT that a second [Hold] of an order keeps the first hold's instant instead of
\* replacing it.
\* Expected result: Inv12_2_HoldReplaces violated. If the checker reports every
\* check holding here, that check is vacuous.
\* Derived validator; the English spec is the single source of truth. On any
\* disagreement, diagnose per the entry *The conflict protocol* in pressure-testing.md.
\*
\* PURPOSE
\* Check what happens across steps: the orders [Order] places, the successor
\* an [Amend] records, and what each order action writes or refuses over a
\* sequence of calls while the clock moves. What one record must carry (the
\* amendment chain's shape, Invariant 2, 3 and 4 in a single state) is the
\* Alloy model's, medication-order.als; this model checks Invariant 2.1, 3.1
\* and 4.1 again across steps, as a cross-check.
\*
\* RULES CHECKED (named by the page's own labels)
\*   Invariant 1.1  — no action changes a core field              (Inv1_1_CoreFieldsKept)
\*   Invariant 2.1  — a successor carries the original's patient
\*                    reference                                    (Inv2_1_SuccessorInherits)
\*   Invariant 3.1  — [Amend] changes only a pre-dispensing order   (Inv3_1_AmendPreDispensing)
\*   Invariant 4.1  — an order never carries a second successor id (Inv4_1_OneSuccessor)
\*   Invariant 5.1  — a reinstate stands the order in the state the
\*                    hold paused, which the hold recorded          (Inv5_ReinstateRoundTrip,
\*                                                                    Inv5_PriorValid)
\*   Invariant 6.1  — [Cancel] changes only a pre-dispensing order  (Inv6_1_CancelPreDispensing)
\*   Invariant 6.2  — [Discontinue] changes only a post-dispensing
\*                    order                                         (Inv6_2_DiscontinuePostDispensing)
\*   Invariant 7.1  — a terminal order never leaves its state       (Inv7_1_TerminalAbsorbing)
\*   Invariant 8.1  — an amended order never leaves amended         (Inv8_1_AmendedStays)
\*   Invariant 9.1  — an order action whose refuses line carries
\*                    on-hold answers it against an on-hold order   (Inv9_1_OnHoldAnswered)
\*   Invariant 12.1 — a field a transition wrote is never changed,
\*                    beside a hold field and a reinstate field     (Inv12_1_WrittenFieldsKept)
\*   Invariant 12.2 — a hold replaces every hold field              (Inv12_2_HoldReplaces)
\*   Invariant 12.3 — a reinstate replaces every reinstate field    (Inv12_3_ReinstateReplaces)
\*   Invariant 13.1 — no action changes an order's order instant    (Inv13_1_OrderInstantKept)
\*   Invariant 13.2 — a successor carries its own order instant     (Inv13_2_SuccessorOwnInstant)
\*   Invariant 14.1 — the atom never removes an order               (Inv14_1_NeverRemoves)
\*
\* WHICH REFUSAL ANSWERS
\* Each order action's refuses line is read in the page's order (Execution
\* Contract Refusal 1: the refusal listed first that applies answers), and a
\* rule binds an action only where its line carries the outcome (GRACE-lang
\* Closed vocabulary 29): on-hold binds every order action but [Hold] and
\* [Reinstate] (Operation 13, Invariant 9.1, the [On Hold Rejection]).
\*
\* BOUNDS (the .cfg)
\* Three order ids, each supplied once by the seam (Capability requirement 2:
\* the counter nextId): one [Order] is placed, under the first, and the other
\* two go to its successors, so the order can be amended and its successor
\* amended again. Orders are records apart (no rule of the page relates two
\* orders but an amendment's), so one chain stands for every order; a second
\* placed order beside it multiplied the states past what TLC explores in a
\* few minutes here (over 2.4 million at depth 12 and growing). Two patient
\* references; two doses, standing for every dosing parameter (an [Amend]
\* supplies one other than the order's, Operation 29); a clock that reads 1,
\* then 2 (Capability requirement 1: Tick), so a field written again later
\* shows a different instant.
\*
\* NOT MODELED HERE
\* - The prescriber, medication and clinical evidence references: the patient
\*   reference stands for every identity field an amendment copies (Operation
\*   33); the Alloy model checks the three of Invariant 2.1 each.
\* - Who acted and why: an attribution reference and a reason are written with
\*   their group, and each group is represented by the instant the transition
\*   wrote, which differs between two writes when the clock has moved. Blank
\*   strings (Invariant 10, 11, Operation 1) are not modeled.
\* - A refused call as a step: it writes nothing (Operation 64, Execution
\*   Contract Read 4), so it would be a stutter. Which state refusal an order
\*   action answers (Term state check) is Answer's, computed in every state,
\*   which Inv9_1_OnHoldAnswered reads; not-known, invalid-request,
\*   invalid-order, storage-failure and [Read] are not modeled.
\* - A supplied order instant earlier than now (Operation 3, 87): an order is
\*   placed at now.

EXTENDS Integers, Sequences

CONSTANTS
    MaxOrders,  \* how many order ids the seam supplies in the model
    Patients,   \* the patient references an [Order] may carry
    Doses,      \* the doses an [Order] or [Amend] may carry, each a dosing parameter
    MaxTime     \* the last clock reading in the model

\* Orders: the order ids the seam may supply, in the order it supplies them.
Orders == 1..MaxOrders
\* Times: the clock readings, from 1.
Times == 1..MaxTime

\* The page's state values (Term state) and its named sets of them.
States == {"ordered", "verified", "amended", "on-hold", "dispensed",
           "administered", "completed", "cancelled", "discontinued"}
\* PreDispensing: Term pre-dispensing state.
PreDispensing == {"ordered", "verified"}
\* PostDispensing: Term post-dispensing state.
PostDispensing == {"dispensed", "administered"}
\* Actionable: Term actionable state, every state a hold may suspend.
Actionable == PreDispensing \cup PostDispensing
\* Terminal: Term terminal state.
Terminal == {"completed", "cancelled", "discontinued"}

\* Actions: the order actions (Term order action).
Actions == {"amend", "verify", "hold", "reinstate", "dispense", "administer",
            "complete", "cancel", "discontinue"}
\* HeldRefusing: the order actions whose refuses line carries on-hold.
HeldRefusing == Actions \ {"hold", "reinstate"}

\* Groups: the field groups a forward transition writes, each carrying its
\* instant (State 2, 3, 5 to 8). The amendment's fields are the successor id
\* on the original and the predecessor id on the successor (State 9, 10).
Groups == {"verify", "dispense", "administer", "complete", "cancel", "discontinue"}

\* Line: each order action's refuses line, its state refusals in the page's
\* order (the Operations signatures).
Line(a) ==
    CASE a = "amend"       -> <<"on-hold", "already-amended", "already-cancelled",
                                "already-discontinued", "already-dispensed">>
      [] a = "verify"      -> <<"on-hold", "already-amended", "already-cancelled",
                                "already-discontinued", "already-completed",
                                "not-in-ordered-state">>
      [] a = "hold"        -> <<"already-on-hold", "already-amended", "already-cancelled",
                                "already-discontinued", "already-completed">>
      [] a = "reinstate"   -> <<"not-on-hold">>
      [] a = "dispense"    -> <<"on-hold", "already-amended", "already-cancelled",
                                "already-discontinued", "already-completed",
                                "not-verified", "already-dispensed">>
      [] a = "administer"  -> <<"on-hold", "already-amended", "already-cancelled",
                                "already-discontinued", "already-completed",
                                "not-dispensed", "already-administered">>
      [] a = "complete"    -> <<"on-hold", "already-amended", "already-cancelled",
                                "already-discontinued", "already-completed",
                                "not-administered">>
      [] a = "cancel"      -> <<"on-hold", "already-amended", "already-cancelled",
                                "already-discontinued", "already-completed",
                                "already-dispensed">>
      [] a = "discontinue" -> <<"on-hold", "already-amended", "already-cancelled",
                                "already-discontinued", "already-completed",
                                "not-dispensed">>

\* ---------------------------------------------------------------------------
\* State
\* ---------------------------------------------------------------------------

VARIABLES
    st,        \* order id -> the order's state ("none" before it is recorded)
    pat,       \* order id -> its patient reference, a core field ("none" before)
    dose,      \* order id -> its dose, a core field and dosing parameter (0 before)
    oinst,     \* order id -> its order instant, a core field (0 before)
    pred,      \* order id -> its predecessor id (0: none)
    succ,      \* order id -> its successor id (0: none)
    grp,       \* order id -> group -> the instant the transition wrote it (0: unwritten)
    prior,     \* order id -> the prior state the last hold recorded, a hold field ("none" before)
    holdAt,    \* order id -> the hold instant, a hold field (0 before)
    reinAt,    \* order id -> the reinstatement instant, a reinstate field (0 before)
    heldFrom,  \* ghost: order id -> the state the last hold paused, kept apart from prior
    now,       \* the clock reading the seam supplies (Capability requirement 1)
    nextId     \* the next order id the seam will supply (Capability requirement 2)

\* vars: every variable; a step that changes none of them is a stutter.
vars == <<st, pat, dose, oinst, pred, succ, grp, prior, holdAt, reinAt,
          heldFrom, now, nextId>>

\* Known: the order id names a recorded order.
Known(o) == st[o] # "none"

\* TypeOK: each variable holds a value of its kind (the model's typing, not a
\* rule of the page).
TypeOK ==
    /\ st \in [Orders -> States \cup {"none"}]
    /\ pat \in [Orders -> Patients \cup {"none"}]
    /\ dose \in [Orders -> Doses \cup {0}]
    /\ oinst \in [Orders -> 0..MaxTime]
    /\ pred \in [Orders -> 0..MaxOrders]
    /\ succ \in [Orders -> 0..MaxOrders]
    /\ grp \in [Orders -> [Groups -> 0..MaxTime]]
    /\ prior \in [Orders -> States \cup {"none"}]
    /\ holdAt \in [Orders -> 0..MaxTime]
    /\ reinAt \in [Orders -> 0..MaxTime]
    /\ heldFrom \in [Orders -> States \cup {"none"}]
    /\ now \in Times
    /\ nextId \in 1..(MaxOrders + 1)

\* Init: no order recorded, the clock at its first reading.
Init ==
    /\ st = [o \in Orders |-> "none"]
    /\ pat = [o \in Orders |-> "none"]
    /\ dose = [o \in Orders |-> 0]
    /\ oinst = [o \in Orders |-> 0]
    /\ pred = [o \in Orders |-> 0]
    /\ succ = [o \in Orders |-> 0]
    /\ grp = [o \in Orders |-> [g \in Groups |-> 0]]
    /\ prior = [o \in Orders |-> "none"]
    /\ holdAt = [o \in Orders |-> 0]
    /\ reinAt = [o \in Orders |-> 0]
    /\ heldFrom = [o \in Orders |-> "none"]
    /\ now = 1
    /\ nextId = 1

\* ---------------------------------------------------------------------------
\* Which refusal answers
\* ---------------------------------------------------------------------------

\* Applies: whether refusal r on action a's line applies to the order o
\* (Operation 13, 14, 16 to 24, 26, 27; Term inactive state's rejection).
Applies(a, r, o) ==
    CASE r = "on-hold"              -> st[o] = "on-hold"
      [] r = "already-on-hold"      -> st[o] = "on-hold"
      [] r = "already-amended"      -> st[o] = "amended"
      [] r = "already-cancelled"    -> st[o] = "cancelled"
      [] r = "already-discontinued" -> st[o] = "discontinued"
      [] r = "already-completed"    -> st[o] = "completed"
      [] r = "not-in-ordered-state" -> st[o] # "ordered"
      [] r = "not-verified"         -> st[o] = "ordered"
      [] r = "already-dispensed"    -> IF a = "dispense" THEN st[o] \in PostDispensing
                                       ELSE st[o] \notin PreDispensing
      [] r = "not-dispensed"        -> IF a = "administer" THEN st[o] \in PreDispensing
                                       ELSE st[o] \notin PostDispensing
      [] r = "already-administered" -> st[o] = "administered"
      [] r = "not-administered"     -> st[o] # "administered"
      [] r = "not-on-hold"          -> st[o] # "on-hold"

\* FirstFrom: the first refusal at or after position i of action a's line
\* that applies to o, or "ok" when none does.
RECURSIVE FirstFrom(_, _, _)
FirstFrom(a, o, i) ==
    IF i > Len(Line(a)) THEN "ok"
    ELSE IF Applies(a, Line(a)[i], o) THEN Line(a)[i]
    ELSE FirstFrom(a, o, i + 1)

\* Answer: what action a answers against order o: the first refusal on its
\* line that applies (Execution Contract Refusal 1), else it admits ("ok").
Answer(a, o) == FirstFrom(a, o, 1)

\* ---------------------------------------------------------------------------
\* Actions
\* ---------------------------------------------------------------------------

\* Tick: the clock moves on.
Tick ==
    /\ now < MaxTime
    /\ now' = now + 1
    /\ UNCHANGED <<st, pat, dose, oinst, pred, succ, grp, prior, holdAt, reinAt,
                   heldFrom, nextId>>

\* Place: an admitted [Order] records an order under the order id the seam
\* supplies, carrying the call's core fields and now as its order instant,
\* standing in ordered (Operation 5 to 8, 87). One order is placed (BOUNDS).
Place(p, d) ==
    /\ nextId = 1
    /\ st' = [st EXCEPT ![nextId] = "ordered"]
    /\ pat' = [pat EXCEPT ![nextId] = p]
    /\ dose' = [dose EXCEPT ![nextId] = d]
    /\ oinst' = [oinst EXCEPT ![nextId] = now]
    /\ nextId' = nextId + 1
    /\ UNCHANGED <<pred, succ, grp, prior, holdAt, reinAt, heldFrom, now>>

\* Amend: an admitted [Amend] supplying dose d records a successor under the
\* order id the seam supplies, carrying the original's patient reference
\* (Operation 33), the supplied dose (Operation 34), the original's id as its
\* predecessor id (Operation 37) and now as its order instant (Operation 81),
\* standing in ordered (Operation 38); the original stands in amended and
\* carries the successor's id (Operation 39, 40).
Amend(o, d) ==
    /\ Answer("amend", o) = "ok"
    /\ d # dose[o]
    /\ nextId <= MaxOrders
    /\ st' = [st EXCEPT ![o] = "amended", ![nextId] = "ordered"]
    /\ pat' = [pat EXCEPT ![nextId] = pat[o]]
    /\ dose' = [dose EXCEPT ![nextId] = d]
    /\ oinst' = [oinst EXCEPT ![nextId] = now]
    /\ pred' = [pred EXCEPT ![nextId] = o]
    /\ succ' = [succ EXCEPT ![o] = nextId]
    /\ nextId' = nextId + 1
    /\ UNCHANGED <<grp, prior, holdAt, reinAt, heldFrom, now>>

\* Forward: an admitted [Verify], [Dispense], [Administer], [Complete],
\* [Cancel] or [Discontinue] writes its field group at now and stands the
\* order in its new state (Operation 43, 44, 51 to 60).
Forward(a, o, s) ==
    /\ Answer(a, o) = "ok"
    /\ st' = [st EXCEPT ![o] = s]
    /\ grp' = [grp EXCEPT ![o][a] = now]
    /\ UNCHANGED <<pat, dose, oinst, pred, succ, prior, holdAt, reinAt, heldFrom,
                   now, nextId>>

\* Hold: an admitted [Hold] records the order's state as prior state and now
\* as hold instant, and stands the order in on-hold (Operation 45 to 47); the
\* ghost heldFrom notes the state paused, apart from prior.
Hold(o) ==
    /\ Answer("hold", o) = "ok"
    /\ st' = [st EXCEPT ![o] = "on-hold"]
    /\ prior' = [prior EXCEPT ![o] = st[o]]
    /\ holdAt' = [holdAt EXCEPT ![o] = IF holdAt[o] = 0 THEN now ELSE holdAt[o]]   \* BUG
    /\ heldFrom' = [heldFrom EXCEPT ![o] = st[o]]
    /\ UNCHANGED <<pat, dose, oinst, pred, succ, grp, reinAt, now, nextId>>

\* Reinstate: an admitted [Reinstate] records now as reinstatement instant
\* and stands the order in its prior state (Operation 48, 49); it takes no
\* target state (Operation 50). The hold fields stay (State 13).
Reinstate(o) ==
    /\ Answer("reinstate", o) = "ok"
    /\ st' = [st EXCEPT ![o] = prior[o]]
    /\ reinAt' = [reinAt EXCEPT ![o] = now]
    /\ UNCHANGED <<pat, dose, oinst, pred, succ, grp, prior, holdAt, heldFrom,
                   now, nextId>>

\* Next: the clock moves, an [Order] is placed, or an order action is
\* admitted on a recorded order. A refused call writes nothing (Operation 64)
\* and is a stutter here; what it answers is Answer's, which
\* Inv9_1_OnHoldAnswered reads.
Next ==
    \/ Tick
    \/ \E p \in Patients, d \in Doses : Place(p, d)
    \/ \E o \in Orders, d \in Doses : Known(o) /\ Amend(o, d)
    \/ \E o \in Orders : Known(o) /\ Forward("verify", o, "verified")
    \/ \E o \in Orders : Known(o) /\ Forward("dispense", o, "dispensed")
    \/ \E o \in Orders : Known(o) /\ Forward("administer", o, "administered")
    \/ \E o \in Orders : Known(o) /\ Forward("complete", o, "completed")
    \/ \E o \in Orders : Known(o) /\ Forward("cancel", o, "cancelled")
    \/ \E o \in Orders : Known(o) /\ Forward("discontinue", o, "discontinued")
    \/ \E o \in Orders : Known(o) /\ Hold(o)
    \/ \E o \in Orders : Known(o) /\ Reinstate(o)

\* Spec: every behaviour from Init by Next steps.
Spec == Init /\ [][Next]_vars

\* ---------------------------------------------------------------------------
\* Checks (the verification surface)
\* ---------------------------------------------------------------------------

\* Inv1_1_CoreFieldsKept: no step changes a recorded order's patient
\* reference, dose or order instant, the core fields modeled (Invariant 1.1).
Inv1_1_CoreFieldsKept ==
    [][\A o \in Orders : Known(o) =>
          /\ pat'[o] = pat[o]
          /\ dose'[o] = dose[o]
          /\ oinst'[o] = oinst[o]]_vars

\* Inv2_1_SuccessorInherits: every successor order carries its original's
\* patient reference (Invariant 2.1).
Inv2_1_SuccessorInherits ==
    \A o \in Orders : pred[o] # 0 => pat[o] = pat[pred[o]]

\* Inv3_1_AmendPreDispensing: a step that writes an amendment onto an order
\* (stands it in amended, or changes its successor id, Operation 39, 40)
\* found that order in a pre-dispensing state (Invariant 3.1).
Inv3_1_AmendPreDispensing ==
    [][\A o \in Orders : (\/ st'[o] = "amended" /\ st[o] # "amended"
                          \/ succ'[o] # succ[o])
                             => st[o] \in PreDispensing]_vars

\* Inv4_1_OneSuccessor: once an order carries a successor id, no step gives
\* it another: an order never carries two (Invariant 4.1).
Inv4_1_OneSuccessor ==
    [][\A o \in Orders : succ[o] # 0 => succ'[o] = succ[o]]_vars

\* Inv5_ReinstateRoundTrip: a step that takes an order off hold stands it in
\* the state its last hold paused (Invariant 5.1).
Inv5_ReinstateRoundTrip ==
    [][\A o \in Orders : (st[o] = "on-hold" /\ st'[o] # "on-hold")
                             => st'[o] = heldFrom[o]]_vars

\* Inv5_PriorValid: an on-hold order carries, as prior state, a state a hold
\* may suspend (Invariant 5.1, State 11).
Inv5_PriorValid ==
    \A o \in Orders : st[o] = "on-hold" => prior[o] \in Actionable

\* Inv6_1_CancelPreDispensing: a step that writes a cancellation onto an
\* order (stands it in cancelled, or writes its cancellation group, Operation
\* 57, 58) found that order in a pre-dispensing state (Invariant 6.1).
Inv6_1_CancelPreDispensing ==
    [][\A o \in Orders : (\/ st'[o] = "cancelled" /\ st[o] # "cancelled"
                          \/ grp'[o]["cancel"] # grp[o]["cancel"])
                             => st[o] \in PreDispensing]_vars

\* Inv6_2_DiscontinuePostDispensing: a step that writes a discontinuation
\* onto an order (stands it in discontinued, or writes its discontinuation
\* group, Operation 59, 60) found that order in a post-dispensing state
\* (Invariant 6.2).
Inv6_2_DiscontinuePostDispensing ==
    [][\A o \in Orders : (\/ st'[o] = "discontinued" /\ st[o] # "discontinued"
                          \/ grp'[o]["discontinue"] # grp[o]["discontinue"])
                             => st[o] \in PostDispensing]_vars

\* Inv7_1_TerminalAbsorbing: no step moves an order out of a terminal state
\* (Invariant 7.1).
Inv7_1_TerminalAbsorbing ==
    [][\A o \in Orders : st[o] \in Terminal => st'[o] = st[o]]_vars

\* Inv8_1_AmendedStays: no step moves an amended order out of amended
\* (Invariant 8.1).
Inv8_1_AmendedStays ==
    [][\A o \in Orders : st[o] = "amended" => st'[o] = "amended"]_vars

\* Inv9_1_OnHoldAnswered: in every state, each order action whose refuses
\* line carries on-hold answers on-hold against an order standing on-hold
\* (Invariant 9.1, Operation 13), whatever state the hold paused.
Inv9_1_OnHoldAnswered ==
    \A o \in Orders, a \in HeldRefusing :
        st[o] = "on-hold" => Answer(a, o) = "on-hold"

\* Inv12_1_WrittenFieldsKept: no step changes a field group a transition
\* wrote, nor a successor or predecessor id once written; the hold and
\* reinstate fields are set aside (Invariant 12.1).
Inv12_1_WrittenFieldsKept ==
    [][\A o \in Orders :
          /\ \A g \in Groups : grp[o][g] # 0 => grp'[o][g] = grp[o][g]
          /\ succ[o] # 0 => succ'[o] = succ[o]
          /\ pred[o] # 0 => pred'[o] = pred[o]]_vars

\* Inv12_2_HoldReplaces: a step that puts an order on hold writes every hold
\* field anew: the state it found as prior state and now as hold instant
\* (Invariant 12.2).
Inv12_2_HoldReplaces ==
    [][\A o \in Orders : (st[o] # "on-hold" /\ st'[o] = "on-hold")
                             => /\ prior'[o] = st[o]
                                /\ holdAt'[o] = now]_vars

\* Inv12_3_ReinstateReplaces: a step that takes an order off hold writes
\* every reinstate field anew: now as reinstatement instant (Invariant 12.3).
Inv12_3_ReinstateReplaces ==
    [][\A o \in Orders : (st[o] = "on-hold" /\ st'[o] # "on-hold")
                             => reinAt'[o] = now]_vars

\* Inv13_1_OrderInstantKept: no step changes a recorded order's order
\* instant (Invariant 13.1).
Inv13_1_OrderInstantKept ==
    [][\A o \in Orders : Known(o) => oinst'[o] = oinst[o]]_vars

\* Inv13_2_SuccessorOwnInstant: a successor is recorded with its own order
\* instant, the reading of the clock at its amendment (Invariant 13.2,
\* Operation 81), not its original's.
Inv13_2_SuccessorOwnInstant ==
    [][\A o \in Orders : (~Known(o) /\ Known(o)' /\ pred'[o] # 0) => oinst'[o] = now]_vars

\* Inv14_1_NeverRemoves: no step removes a recorded order (Invariant 14.1).
Inv14_1_NeverRemoves ==
    [][\A o \in Orders : Known(o) => Known(o)']_vars

====
