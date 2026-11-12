---- MODULE observation-buggy-amend-amended ----
\* Grace Commons — Observation atom (atoms/observation.md).
\* Grounded on Final Critique 8, 2026-11-05 at 917cc95 — TLA+ layer written
\* 2026-11-11 (unit `atoms/observation.md formal layer`).
\* Derived validator; the English spec is the single source of truth. On any
\* disagreement, diagnose per the entry *The conflict protocol* in pressure-testing.md.
\* BUGGY TWIN of observation.tla: identical EXCEPT that [Amend]'s refuses
\* line lacks already-amended, so an amended observation is amended again.
\* Expected result: Inv3_1_OneSuccessor violated. If the checker reports every
\* check holding here, that check is vacuous.
\*
\* PURPOSE
\* Check what happens across steps: the observations [Record] records, the
\* successor an [Amend] records, and what [Amend] and [Retract] write or
\* refuse over every sequence of calls while the clock moves. What one state
\* must carry (the amendment chain's shape, Invariant 2 to 6 in a single
\* state) is the Alloy model's, observation.als; this model checks Invariant
\* 3.1, 3.2, 4.1 and 5.1 again across steps, as a cross-check.
\*
\* RULES CHECKED (named by the page's own labels)
\*   Invariant 1.1 — a recorded content field never changes        (Inv1_1_ContentKept)
\*   Invariant 2.1 — an admitted amend records a successor          (Inv2_1_AmendRecordsSuccessor)
\*   Invariant 2.2 — an admitted amend leaves the original's content
\*                   fields as they were                            (Inv2_2_AmendKeepsOriginal)
\*   Invariant 3.1 — no observation carries two successor ids       (Inv3_1_OneSuccessor)
\*   Invariant 3.2 — no observation carries two predecessor ids     (Inv3_2_OnePredecessor)
\*   Invariant 4.1 — one amendment chain, one subject reference     (Inv4_1_ChainSubject)
\*   Invariant 5.1 — one amendment chain, one observation type      (Inv5_1_ChainType)
\*   Invariant 6.1 — a retracted observation admits no chain action (Inv6_1_RetractedAdmitsNone)
\*   Invariant 7.1 — the atom never removes an observation          (Inv7_1_NeverRemoves)
\*   Invariant 8.1 — a recorded recording instant never changes     (Inv8_1_InstantKept)
\*   Invariant 8.2 — a successor's recording instant is the
\*                   amendment's instant                            (Inv8_2_SuccessorAtAmendment)
\*   Invariant 9.1 — a written transition metadata field never
\*                   changes                                        (Inv9_1_MetadataKept)
\*
\* WHICH REFUSAL ANSWERS
\* Each chain action's refuses line is read in the page's order (Execution
\* Contract Refusal 1: the refusal listed first that applies answers). Only
\* the state refusals are modeled: not-known (Operation 11, 12), then, on
\* [Amend]'s line, already-amended before already-retracted (Operation 13,
\* 14); [Retract]'s line carries no already-amended, so an amended
\* observation may be retracted (Operation 38).
\*
\* BOUNDS (the .cfg)
\* Three observation ids, each supplied once by the seam (Identity 2: the
\* counter nextId): one [Record] is admitted, under the first, and the other
\* two go to its successors, so the observation can be amended and its
\* successor amended again, and any link retracted. Observations are records
\* apart (no rule of the page relates two observations but an amendment's),
\* so one chain stands for every observation; letting every id go to a
\* [Record] as well took 1,569,170 states and 150 s here, too slow for the
\* twins, with no rule more in reach. Two subject references and two
\* observation types (so a successor that took the wrong one would show
\* it), two references for every actor, two values standing for value and
\* unit, and a clock that reads 1, then 2, so a supplied recording instant
\* may stand earlier than now and a successor recorded later shows a
\* different instant from its original's.
\*
\* NOT MODELED HERE
\* - The unit: the value stands for value and unit, the content an [Amend]
\*   supplies (Operation 57). The observation id is the function's domain:
\*   no step can change it (Identity 4).
\* - The reasons: an amendment reason is written with its amending actor and
\*   a retraction reason with its retracting actor (Operation 30, 36), so
\*   each actor stands for the pair; a reason rewritten is a pair rewritten.
\* - Blank and over-cap strings, value constraints, a malformed or past-the-
\*   future-bound recording instant (Operation 1 to 7, 16 to 18, 59, 60, 63):
\*   field validation, refused before any write. The clock offset allowance
\*   is 0 here: a supplied instant is any reading up to now.
\* - A refused call as a step: it writes nothing (Execution Contract Read 4),
\*   so it would be a stutter. Which state refusal a chain action answers is
\*   Answer's, computed in every state, which Inv6_1_RetractedAdmitsNone
\*   reads; storage-failure is not modeled.
\* - [Read] and its order (Operation 42 to 51): a read writes nothing.
\* - A retraction instant: the page records none (open line 2026-10-22-c).

EXTENDS Integers, Sequences, FiniteSets

CONSTANTS
    MaxObs,     \* how many observation ids the seam supplies in the model
    Subjects,   \* the subject references a [Record] may carry
    Types,      \* the observation types a [Record] may carry
    Actors,     \* the references a recording, amending or retracting actor may carry
    Values,     \* the values a [Record] or [Amend] may carry, each standing for value and unit
    MaxTime     \* the last clock reading in the model

\* Ids: the observation ids the seam may supply, in the order it supplies them.
Ids == 1..MaxObs
\* Times: the clock readings, from 1.
Times == 1..MaxTime

\* The page's states (Term states), and "none" for an id not yet recorded.
States == {"recorded", "amended", "retracted"}

\* ChainActions: the two actions that address a recorded observation (Term
\* chain action).
ChainActions == {"amend", "retract"}

\* Line: each chain action's refuses line, its state refusals in the page's
\* order (the Operations signatures).
Line(a) ==
    CASE a = "amend"   -> <<"not-known", "already-retracted">>   \* BUG: already-amended dropped
      [] a = "retract" -> <<"not-known", "already-retracted">>

\* ---------------------------------------------------------------------------
\* State
\* ---------------------------------------------------------------------------

VARIABLES
    st,      \* id -> the observation's state ("none" before it is recorded)
    subj,    \* id -> its subject reference, a content field ("none" before)
    otype,   \* id -> its observation type, a content field ("none" before)
    rby,     \* id -> its recording actor, a content field ("none" before)
    val,     \* id -> its value, a content field standing for value and unit (0 before)
    at,      \* id -> its recording instant, a content field (0 before)
    pred,    \* id -> its predecessor id, transition metadata (0: none)
    succ,    \* id -> its successor id, transition metadata (0: none)
    amBy,    \* id -> its amending actor (and amendment reason), transition metadata ("none": unwritten)
    retBy,   \* id -> its retracting actor (and retraction reason), transition metadata ("none": unwritten)
    now,     \* the clock reading the seam supplies (Term now)
    nextId   \* the next observation id the seam will supply (Identity 2)

\* vars: every variable; a step that changes none of them is a stutter.
vars == <<st, subj, otype, rby, val, at, pred, succ, amBy, retBy, now, nextId>>

\* Known: the observation id names a recorded observation.
Known(o) == st[o] # "none"

\* Content: the content fields of observation o modeled, as one record
\* (Term content field: the id is the function's domain).
Content(o) == <<subj[o], otype[o], rby[o], val[o], at[o]>>

\* RECURSIVE Root: the first observation of o's amendment chain, found by
\* following predecessor ids back (Term amendment chain).
RECURSIVE Root(_)
Root(o) == IF pred[o] = 0 THEN o ELSE Root(pred[o])

\* TypeOK: each variable holds a value of its kind (the model's typing, not a
\* rule of the page).
TypeOK ==
    /\ st \in [Ids -> States \cup {"none"}]
    /\ subj \in [Ids -> Subjects \cup {"none"}]
    /\ otype \in [Ids -> Types \cup {"none"}]
    /\ rby \in [Ids -> Actors \cup {"none"}]
    /\ val \in [Ids -> Values \cup {0}]
    /\ at \in [Ids -> 0..MaxTime]
    /\ pred \in [Ids -> 0..MaxObs]
    /\ succ \in [Ids -> 0..MaxObs]
    /\ amBy \in [Ids -> Actors \cup {"none"}]
    /\ retBy \in [Ids -> Actors \cup {"none"}]
    /\ now \in Times
    /\ nextId \in 1..(MaxObs + 1)

\* Init: no observation recorded, the clock at its first reading.
Init ==
    /\ st = [o \in Ids |-> "none"]
    /\ subj = [o \in Ids |-> "none"]
    /\ otype = [o \in Ids |-> "none"]
    /\ rby = [o \in Ids |-> "none"]
    /\ val = [o \in Ids |-> 0]
    /\ at = [o \in Ids |-> 0]
    /\ pred = [o \in Ids |-> 0]
    /\ succ = [o \in Ids |-> 0]
    /\ amBy = [o \in Ids |-> "none"]
    /\ retBy = [o \in Ids |-> "none"]
    /\ now = 1
    /\ nextId = 1

\* ---------------------------------------------------------------------------
\* Which refusal answers
\* ---------------------------------------------------------------------------

\* Applies: whether refusal r applies to the observation id o (Operation 11
\* to 14).
Applies(r, o) ==
    CASE r = "not-known"         -> ~Known(o)
      [] r = "already-amended"   -> st[o] = "amended"
      [] r = "already-retracted" -> st[o] = "retracted"

\* FirstFrom: the first refusal at or after position i of action a's line
\* that applies to o, or "ok" when none does.
RECURSIVE FirstFrom(_, _, _)
FirstFrom(a, o, i) ==
    IF i > Len(Line(a)) THEN "ok"
    ELSE IF Applies(Line(a)[i], o) THEN Line(a)[i]
    ELSE FirstFrom(a, o, i + 1)

\* Answer: what chain action a answers against observation id o: the first
\* refusal on its line that applies (Execution Contract Refusal 1), else it
\* admits ("ok").
Answer(a, o) == FirstFrom(a, o, 1)

\* ---------------------------------------------------------------------------
\* Actions
\* ---------------------------------------------------------------------------

\* Tick: the clock moves on.
Tick ==
    /\ now < MaxTime
    /\ now' = now + 1
    /\ UNCHANGED <<st, subj, otype, rby, val, at, pred, succ, amBy, retBy, nextId>>

\* Record: an admitted [Record] records exactly one observation under the
\* observation id the seam supplies, carrying the call's subject reference,
\* recording actor, observation type and value, and the resolved recording
\* instant i (supplied, or now; never past now here), standing in recorded
\* (Operation 8 to 10, 62, State 13). One observation is recorded (BOUNDS).
Record(s, t, r, v, i) ==
    /\ nextId = 1
    /\ st' = [st EXCEPT ![nextId] = "recorded"]
    /\ subj' = [subj EXCEPT ![nextId] = s]
    /\ otype' = [otype EXCEPT ![nextId] = t]
    /\ rby' = [rby EXCEPT ![nextId] = r]
    /\ val' = [val EXCEPT ![nextId] = v]
    /\ at' = [at EXCEPT ![nextId] = i]
    /\ nextId' = nextId + 1
    /\ UNCHANGED <<pred, succ, amBy, retBy, now>>

\* Amend: an admitted [Amend] by amending actor b supplying value v records
\* exactly one successor under the id the seam supplies (Operation 24),
\* taking its subject reference, observation type and recording actor from
\* the original (Operation 25, 26, 56), recording the supplied value
\* (Operation 57), stamping now as its recording instant (Operation 27),
\* standing it in recorded with the original's id as predecessor id and the
\* amending actor written (Operation 28 to 30); the original stands in
\* amended carrying the successor's id (Operation 31, 32).
Amend(o, b, v) ==
    /\ Answer("amend", o) = "ok"
    /\ nextId <= MaxObs
    /\ st' = [st EXCEPT ![o] = "amended", ![nextId] = "recorded"]
    /\ subj' = [subj EXCEPT ![nextId] = subj[o]]
    /\ otype' = [otype EXCEPT ![nextId] = otype[o]]
    /\ rby' = [rby EXCEPT ![nextId] = rby[o]]
    /\ val' = [val EXCEPT ![nextId] = v]
    /\ at' = [at EXCEPT ![nextId] = now]
    /\ pred' = [pred EXCEPT ![nextId] = o]
    /\ succ' = [succ EXCEPT ![o] = nextId]
    /\ amBy' = [amBy EXCEPT ![nextId] = b]
    /\ nextId' = nextId + 1
    /\ UNCHANGED <<retBy, now>>

\* Retract: an admitted [Retract] by retracting actor b stands the
\* observation in retracted and writes the retracting actor (Operation 35,
\* 36); an amended observation may be retracted (Operation 38), and its
\* successor id stays.
Retract(o, b) ==
    /\ Answer("retract", o) = "ok"
    /\ st' = [st EXCEPT ![o] = "retracted"]
    /\ retBy' = [retBy EXCEPT ![o] = b]
    /\ UNCHANGED <<subj, otype, rby, val, at, pred, succ, amBy, now, nextId>>

\* Next: the clock moves, a [Record] is admitted, or a chain action is
\* admitted on a recorded observation. A refused call writes nothing and is
\* a stutter here; what it answers is Answer's, which
\* Inv6_1_RetractedAdmitsNone reads.
Next ==
    \/ Tick
    \/ \E s \in Subjects, t \in Types, r \in Actors, v \in Values, i \in 1..now :
           Record(s, t, r, v, i)
    \/ \E o \in Ids, b \in Actors, v \in Values : Known(o) /\ Amend(o, b, v)
    \/ \E o \in Ids, b \in Actors : Known(o) /\ Retract(o, b)

\* Spec: every behaviour from Init by Next steps.
Spec == Init /\ [][Next]_vars

\* ---------------------------------------------------------------------------
\* Checks (the verification surface)
\* ---------------------------------------------------------------------------

\* Inv1_1_ContentKept: no step changes a recorded observation's subject
\* reference, observation type, recording actor, value or recording instant,
\* the content fields modeled (Invariant 1.1).
Inv1_1_ContentKept ==
    [][\A o \in Ids : Known(o) => Content(o)' = Content(o)]_vars

\* Inv2_1_AmendRecordsSuccessor: a step that stands an observation in
\* amended records, in the same step, a new observation naming it as
\* predecessor (Invariant 2.1).
Inv2_1_AmendRecordsSuccessor ==
    [][\A o \in Ids : (st[o] # "amended" /\ st'[o] = "amended")
                          => \E n \in Ids : ~Known(n) /\ Known(n)' /\ pred'[n] = o]_vars

\* Inv2_2_AmendKeepsOriginal: a step that stands an observation in amended
\* leaves its content fields as they were (Invariant 2.2).
Inv2_2_AmendKeepsOriginal ==
    [][\A o \in Ids : (st[o] # "amended" /\ st'[o] = "amended")
                          => Content(o)' = Content(o)]_vars

\* Inv3_1_OneSuccessor: no observation has two successors recorded against
\* it: at most one observation names it as predecessor, so it never carries
\* two successor ids (Invariant 3.1).
Inv3_1_OneSuccessor ==
    \A o \in Ids : Cardinality({n \in Ids : pred[n] = o}) <= 1

\* Inv3_2_OnePredecessor: no observation is named as successor by two: at
\* most one observation carries its id as successor id, so it never carries
\* two predecessor ids (Invariant 3.2).
Inv3_2_OnePredecessor ==
    \A n \in Ids : Cardinality({o \in Ids : succ[o] = n}) <= 1

\* Inv4_1_ChainSubject: every two recorded observations of one amendment
\* chain carry one subject reference (Invariant 4.1).
Inv4_1_ChainSubject ==
    \A a, b \in Ids : (Known(a) /\ Known(b) /\ Root(a) = Root(b))
                          => subj[a] = subj[b]

\* Inv5_1_ChainType: every two recorded observations of one amendment chain
\* carry one observation type (Invariant 5.1).
Inv5_1_ChainType ==
    \A a, b \in Ids : (Known(a) /\ Known(b) /\ Root(a) = Root(b))
                          => otype[a] = otype[b]

\* Inv6_1_RetractedAdmitsNone: in every state, each chain action answers a
\* refusal against a retracted observation, so none is admitted
\* (Invariant 6.1).
Inv6_1_RetractedAdmitsNone ==
    \A o \in Ids, a \in ChainActions :
        st[o] = "retracted" => Answer(a, o) # "ok"

\* Inv7_1_NeverRemoves: no step removes a recorded observation (Invariant
\* 7.1).
Inv7_1_NeverRemoves ==
    [][\A o \in Ids : Known(o) => Known(o)']_vars

\* Inv8_1_InstantKept: no step changes a recorded observation's recording
\* instant (Invariant 8.1).
Inv8_1_InstantKept ==
    [][\A o \in Ids : Known(o) => at'[o] = at[o]]_vars

\* Inv8_2_SuccessorAtAmendment: a successor is recorded with the reading of
\* the clock at its amendment as its recording instant, not its original's
\* (Invariant 8.2, Operation 27).
Inv8_2_SuccessorAtAmendment ==
    [][\A n \in Ids : (~Known(n) /\ Known(n)' /\ pred'[n] # 0) => at'[n] = now]_vars

\* Inv9_1_MetadataKept: no step changes a successor id, predecessor id,
\* amending actor or retracting actor once written (each actor standing for
\* its reason) (Invariant 9.1).
Inv9_1_MetadataKept ==
    [][\A o \in Ids :
          /\ succ[o] # 0 => succ'[o] = succ[o]
          /\ pred[o] # 0 => pred'[o] = pred[o]
          /\ amBy[o] # "none" => amBy'[o] = amBy[o]
          /\ retBy[o] # "none" => retBy'[o] = retBy[o]]_vars

====
