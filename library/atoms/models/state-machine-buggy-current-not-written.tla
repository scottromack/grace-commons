---- MODULE state-machine-buggy-current-not-written ----
\* Grace Commons — State Machine atom (atoms/state-machine.md).
\* Grounded on Final Critique 16, 2026-11-06 at ad732c0 — TLA+ layer written
\* 2026-11-11 (unit `atoms/state-machine.md formal layer`).
\* Derived validator; the English spec is the single source of truth. On any
\* disagreement, diagnose per the entry *The conflict protocol* in pressure-testing.md.
\* BUGGY TWIN of state-machine.tla: identical EXCEPT that an admitted fire appends its entry but leaves the current state as the call found it (Operation 26 dropped).
\* Expected result: Inv7_1_CurrentIsLastTo violated. If the checker reports every check
\* holding here, that check is vacuous.
\*
\* PURPOSE
\* Check what happens across steps: the workflow [Instantiate] records or
\* refuses, what every sequence of [Fire] calls writes to it, and what
\* [Current], [History] and [Read Declaration] answer in every state those
\* calls leave. The Alloy model, state-machine.als, holds one declaration and
\* one history chain as a snapshot; every rule below needs a call, a counter
\* or two states, so it is this model's.
\*
\* RULES CHECKED (named by the page's own labels)
\*   Invariant 1.1  — a recorded declaration never changes              (Inv1_1_DeclarationUnchanged)
\*   Invariant 1.2  — [Read Declaration] answers the declaration as
\*                    [Instantiate] took it                             (Inv1_2_ReadAsTaken)
\*   Invariant 2.1  — a workflow stands in exactly one of its states    (Inv2_1_ExactlyOneState)
\*   Invariant 3.1  — every entry matches exactly one declared transition (Inv3_1_EntryDeclared)
\*   Invariant 3.2  — no two declared transitions share from and action (Inv3_2_Deterministic)
\*   Invariant 4.1  — a workflow in a terminal state never leaves it    (Inv4_1_TerminalAbsorbs)
\*   Invariant 4.2  — no declared transition leaves a terminal state    (Inv4_2_NoExitFromTerminal)
\*   Invariant 5.1  — a history entry never changes                     (Inv5_1_EntryUnchanged)
\*   Invariant 5.2  — entry count equals the admitted fire count        (Inv5_2_CountIsFires)
\*   Invariant 6.1  — no two entries share a sequence number            (Inv6_1_SeqUnique)
\*   Invariant 6.2  — the sequence numbers run from one to the count    (Inv6_2_SeqDense)
\*   Invariant 6.3  — [History] orders by sequence number alone         (Inv6_3_OrderBySeq)
\*   Invariant 7.1  — with a history, the current state is the highest
\*                    entry's to state                                  (Inv7_1_CurrentIsLastTo)
\*   Invariant 7.2  — with no history, the current state is the initial (Inv7_2_EmptyIsInitial)
\*   Invariant 7.3  — replaying the history from the initial state
\*                    reaches the current state                         (Inv7_3_ReplayReachesCurrent)
\*   Invariant 8.1  — a guarded transition fires only on an asserted true (Inv8_1_GuardAsserted)
\*   Invariant 8.3  — a guarded entry records the caller's assertion    (Inv8_3_AssertionRecorded)
\*   Invariant 9.1  — a recorded actor reference is not blank           (Inv9_1_ActorNotBlank)
\*   Invariant 10.1 — no workflow is removed                            (Inv10_1_WorkflowKept)
\*   Invariant 10.2 — no history entry is removed                       (Inv10_2_EntryKept)
\* Invariant 8.2 (the atom does not evaluate a guard's condition) states
\* the absence of a computation: the model holds no condition to evaluate,
\* so nothing here can state it.
\*
\* WHICH REFUSAL ANSWERS
\* [Instantiate] and [Fire] are answered by their refuses lines in the
\* page's order (Execution Contract Refusal 1); [Fire]'s firing checks answer
\* only on a cleared fire (Operation 64), as the page's table has it. A
\* refused call writes nothing (Operation 35 through 37), so it is no step: each
\* action below takes its call and steps only on the answer that admits it.
\*
\* BOUNDS (the .cfg)
\* One workflow (MaxWf = 1): workflows are records apart, and no Invariant
\* relates two. Two state names, two actions, one guard label; [Instantiate]
\* is offered EVERY declaration over them with up to two declared
\* transitions (Decls: the valid ones it admits and the ones Declaration 5
\* to 18 refuse), so the checks range over every shape of map the names
\* allow, a self-loop, a dead end that is not terminal, a guarded and an
\* unguarded move among them. Up to two admitted fires (MaxFires = 2) and
\* two clock readings (MaxTime = 2), so a later entry can carry an earlier
\* firing instant (Clock semantics 4). Three admitted fires change no
\* verdict (STEP 3 of the coverage matrix).
\*
\* NOT MODELED HERE
\* - Strings as strings: a blank or over-cap instance id or action
\*   (Operation 9, 10, 75, 76), a blank state name, action or guard and the
\*   string cap in a declaration (Declaration 6, 14, 15, 20), a malformed
\*   declaration, firing instant or guard satisfied (Declaration 19,
\*   Operation 66, 69): input checks on one call, no Invariant rests on them.
\*   An actor reference is absent, the empty string, whitespace or a
\*   reference; String 5 and 6 read the first three as blank.
\* - States as a list: Declaration 7 (two names that match) needs the map's
\*   list; the model's states are a set, so a repeated name is one member,
\*   as Term terminal states reads the terminal list.
\* - An unknown instance id (Operation 11): every call addresses the one
\*   workflow once it stands. Storage failure (Operation 33): a refusal,
\*   which writes nothing.
\* - Transition ids, subject reference and instance metadata: the host's
\*   (Identity 4, 10) or opaque payloads no Invariant reads.
\* - [History]'s filters (Operation 39 through 45, 57, 58): the model reads the
\*   unfiltered answer, whose order is what Invariant 6.3 states.
\* - The resolved instants (Execution Contract Logic confinement 12): a call
\*   carries its instant; Operation 3, 19 and 20 bound it.

EXTENDS Integers, Sequences, FiniteSets, TLC

CONSTANTS
    MaxWf,     \* how many instance ids the seam supplies in the model
    MaxFires,  \* how many admitted fires the model makes on a workflow
    MaxTime    \* the last clock reading, the readings being 1..MaxTime

\* Ids: the instance ids the seam may supply, in the order it supplies them.
Ids == 1..MaxWf

\* Times: the clock readings, in time order.
Times == 1..MaxTime

\* StateNames: the state names a declaration may use (Term states).
StateNames == {"p", "q"}

\* Actions: the action names a declared transition or a [Fire] call may carry.
Actions == {"a", "b"}

\* NoGuard: a declared transition that carries no guard (Declaration 17).
NoGuard == "none"

\* Guards: no guard, or the one guard label "g" (Term guard).
Guards == {NoGuard, "g"}

\* Absent: an optional input the call leaves out, or a field not recorded.
Absent == "-"

\* WhitespaceStrings: the strings holding no code point outside White_Space,
\* the empty string among them (Term whitespace strings); two stand for all.
WhitespaceStrings == {"", " "}

\* ActorInputs: what a call may carry as actor reference: none, the empty
\* string, whitespace only, or a reference.
ActorInputs == {Absent, "", " ", "r"}

\* GuardInputs: what a [Fire] call may carry as guard satisfied: none, true
\* or false (Term guard satisfied).
GuardInputs == {Absent, "true", "false"}

\* Stuck: what a replay reaches when an entry does not start where the
\* replay stands; never a state name.
Stuck == "stuck"

\* TransUniverse: every declared transition the names allow (Term declared
\* transition): a from state, an action, a to state and a guard or none.
TransUniverse == [from: StateNames, act: Actions, to: StateNames, guard: Guards]

\* TransSets: every set of at most two declared transitions (BOUNDS).
TransSets == {{}} \cup {{t1, t2} : t1, t2 \in TransUniverse}

\* Decls: every declaration [Instantiate] may be offered (Term declaration):
\* states, declared transitions, an initial state and terminal states, with
\* the initial state free to fall outside states, so Declaration 5 through 18
\* each have a map to refuse.
Decls == [states: SUBSET StateNames, trans: TransSets,
          initial: StateNames, terminal: SUBSET StateNames]

\* Calls: every [Fire] call on a workflow: its action, guard satisfied,
\* actor reference and firing instant.
Calls == [act: Actions, gs: GuardInputs, actor: ActorInputs, at: Times]

\* ---------------------------------------------------------------------------
\* State
\* ---------------------------------------------------------------------------

VARIABLES
    now,     \* the clock reading the deployment supplies at the seam (Capability requirement 1)
    nextId,  \* the next instance id the seam will supply (Identity 3)
    wf,      \* instance id -> the workflow record (State 1): declaration, current state, history, next sequence number, instantiation instant, actor reference
    taken,   \* instance id -> the declaration the [Instantiate] call carried (what Invariant 1.2 compares with; not a record the atom keeps)
    fires    \* instance id -> how many [Fire] calls were answered new_state (the count External check 2 captures; not a record the atom keeps)

\* vars: every variable; a step that changes none of them is a stutter.
vars == <<now, nextId, wf, taken, fires>>

\* Range: the entries of a history, as a set.
Range(h) == {h[i] : i \in DOMAIN h}

\* TypeOK: each variable holds a value of its kind (the model's typing, not a
\* rule of the page).
TypeOK ==
    /\ now \in Times
    /\ nextId \in 1..(MaxWf + 1)
    /\ DOMAIN wf \subseteq Ids
    /\ DOMAIN taken \subseteq Ids
    /\ DOMAIN fires \subseteq Ids
    /\ \A w \in DOMAIN wf : wf[w].decl \in Decls /\ wf[w].cur \subseteq StateNames

\* Init: no workflow instantiated, the clock at its first reading.
Init ==
    /\ now = 1
    /\ nextId = 1
    /\ wf = [x \in {} |-> 0]
    /\ taken = [x \in {} |-> 0]
    /\ fires = [x \in {} |-> 0]

\* ---------------------------------------------------------------------------
\* The terms, as the page uses them
\* ---------------------------------------------------------------------------

\* IsBlank: String 5 and 6 read an absent or whitespace-only string as blank.
IsBlank(x) == x = Absent \/ x \in WhitespaceStrings

\* SuppliedBlank: the call carries the input, and it is one of the
\* whitespace strings (Operation 2's case).
SuppliedBlank(x) == x # Absent /\ IsBlank(x)

\* IsTerminal: s is among the declaration's terminal states (Term terminal
\* states), the one reading Declaration 9, 12 and Operation 13 share.
IsTerminal(d, s) == s \in d.terminal

\* DeclFault: the declaration is one [Instantiate] answers invalid-declaration.
DeclFault(d) ==
    \/ d.states = {}                                           \* Declaration 5
    \/ d.initial \notin d.states                               \* Declaration 8
    \/ IsTerminal(d, d.initial)                                \* Declaration 9
    \/ \E t \in d.trans : t.from \notin d.states               \* Declaration 10
    \/ \E t \in d.trans : t.to \notin d.states                 \* Declaration 11
    \/ \E t \in d.trans : IsTerminal(d, t.from)                \* Declaration 12
    \/ \E t1, t2 \in d.trans :
          t1 # t2 /\ t1.from = t2.from /\ t1.act = t2.act      \* Declaration 13
    \/ \E s \in d.terminal : s \notin d.states                 \* Declaration 18

\* InstAnswer: [Instantiate]'s answer to a declaration, an instantiation
\* instant and an actor reference, by its refuses line: invalid-declaration,
\* then invalid-request (Operation 2 and 3), else the workflow is recorded.
InstAnswer(d, i, a) ==
    IF DeclFault(d) THEN "invalid-declaration"
    ELSE IF SuppliedBlank(a) \/ now < i THEN "invalid-request"
    ELSE "instance_id"

\* Current: the state the workflow stands in (Term current state).
Current(w) == CHOOSE s \in wf[w].cur : TRUE

\* MatchSet: the declared transitions whose from state is the current state
\* and whose action is the call's (Term matched transition).
MatchSet(w, c) == {t \in wf[w].decl.trans : t.from = Current(w) /\ t.act = c.act}

\* Matched: the matched transition (one, by Declaration 13).
Matched(w, c) == CHOOSE t \in MatchSet(w, c) : TRUE

\* FiringFault: a firing check the call fails (Term firing fault): a
\* whitespace actor reference (Operation 2), a firing instant after now
\* (Operation 19) or before the instantiation instant (Operation 20).
FiringFault(w, c) ==
    \/ SuppliedBlank(c.actor)
    \/ now < c.at
    \/ c.at < wf[w].inst

\* FireAnswer: [Fire]'s answer by its refuses line (the page's table, rows 3
\* to 6 and 8): terminal (Operation 13), invalid-transition (Operation 15),
\* guard-not-satisfied (Operation 17), invalid-request on a cleared fire
\* (Operation 64), else new_state.
FireAnswer(w, c) ==
    IF IsTerminal(wf[w].decl, Current(w)) THEN "terminal"
    ELSE IF MatchSet(w, c) = {} THEN "invalid-transition"
    ELSE IF Matched(w, c).guard # NoGuard /\ c.gs # "true" THEN "guard-not-satisfied"
    ELSE IF FiringFault(w, c) THEN "invalid-request"
    ELSE "new_state"

\* NewEntry: the history entry an admitted fire appends (Operation 21 through 25,
\* 29, 30, 61, 68): the sequence number from next sequence number, the from
\* state the call found, the call's action, the matched transition's to
\* state, guard satisfied on a guarded transition only, the actor reference
\* where not blank, the firing instant. callGs keeps what the call asserted
\* on a guarded transition, so Invariant 8.1 can read the call; it is the
\* model's, not a field the atom records.
NewEntry(w, c, t) ==
    [seq    |-> wf[w].next,
     from   |-> Current(w),
     act    |-> c.act,
     to     |-> t.to,
     gs     |-> IF t.guard # NoGuard THEN c.gs ELSE Absent,
     callGs |-> IF t.guard # NoGuard THEN c.gs ELSE Absent,
     actor  |-> IF IsBlank(c.actor) THEN Absent ELSE c.actor,
     at     |-> c.at]

\* ---------------------------------------------------------------------------
\* The actions
\* ---------------------------------------------------------------------------

\* Tick: the clock reading moves on.
Tick ==
    /\ now < MaxTime
    /\ now' = now + 1
    /\ UNCHANGED <<nextId, wf, taken, fires>>

\* Instantiate: an admitted [Instantiate] records exactly one workflow under
\* the id the host allocates (Operation 4, 72), standing in the initial state
\* (Operation 5) with next sequence number one (Operation 6), an empty history
\* (Operation 7), the instantiation instant (Operation 67) and the actor
\* reference where not blank (Operation 60).
Instantiate(d, i, a) ==
    /\ nextId \in Ids
    /\ InstAnswer(d, i, a) = "instance_id"
    /\ wf' = wf @@ (nextId :> [decl  |-> d,
                               cur   |-> {d.initial},
                               hist  |-> <<>>,
                               next  |-> 1,
                               inst  |-> i,
                               actor |-> IF IsBlank(a) THEN Absent ELSE a])
    /\ taken' = taken @@ (nextId :> d)
    /\ fires' = fires @@ (nextId :> 0)
    /\ nextId' = nextId + 1
    /\ UNCHANGED now

\* Fire: an admitted [Fire] appends exactly one entry (Operation 21), raises
\* next sequence number by one (Operation 23) and stands the workflow in the
\* matched transition's to state (Operation 26); the count of new_state
\* answers rises by one.
Fire(w, c) ==
    /\ fires[w] < MaxFires
    /\ FireAnswer(w, c) = "new_state"
    /\ LET t == Matched(w, c)
           e == NewEntry(w, c, t)
       IN  wf' = [wf EXCEPT ![w].cur = @,   \* BUG: Operation 26 dropped
                            ![w].hist = Append(@, e),
                            ![w].next = @ + 1]
    /\ fires' = [fires EXCEPT ![w] = @ + 1]
    /\ UNCHANGED <<now, nextId, taken>>

\* Next: the clock moves, a workflow is instantiated, or a declared
\* transition fires.
Next ==
    \/ Tick
    \/ \E d \in Decls, i \in Times, a \in ActorInputs : Instantiate(d, i, a)
    \/ \E w \in DOMAIN wf, c \in Calls : Fire(w, c)

\* Spec: every behavior from Init by Next steps.
Spec == Init /\ [][Next]_vars

\* ---------------------------------------------------------------------------
\* The reads (a reading action writes nothing, Operation 50)
\* ---------------------------------------------------------------------------

\* ReadDeclaration: [Read Declaration]'s answer, the workflow's declaration
\* as recorded, not normalized and not reordered (Operation 47 through 49).
ReadDeclaration(w) == wf[w].decl

\* HistoryAnswer: [History]'s answer with no filter: every entry, in
\* sequence number ascending order (Operation 39).
HistoryAnswer(w) == SortSeq(wf[w].hist, LAMBDA x, y : x.seq < y.seq)

\* Highest: the entry carrying the highest sequence number.
Highest(w) == CHOOSE e \in Range(wf[w].hist) :
                  \A f \in Range(wf[w].hist) : f.seq <= e.seq

\* Replay: start in the initial state and take each entry of [History]'s
\* answer in order, moving to its to state where it starts where the replay
\* stands (Term current state; Check 6.1), or Stuck where it does not.
Replay(w) ==
    LET A == HistoryAnswer(w)
        R[k \in 0..Len(A)] ==
            IF k = 0 THEN wf[w].decl.initial
            ELSE IF A[k].from = R[k - 1] THEN A[k].to ELSE Stuck
    IN  R[Len(A)]

\* Guarded: entry e matches a declared transition carrying a guard.
Guarded(d, e) ==
    \E t \in d.trans : t.from = e.from /\ t.act = e.act /\ t.to = e.to /\ t.guard # NoGuard

\* ---------------------------------------------------------------------------
\* The checks
\* ---------------------------------------------------------------------------

\* Invariant 1.1: from any step to the next, a workflow's recorded
\* declaration keeps every field.
Inv1_1_DeclarationUnchanged ==
    [][\A w \in DOMAIN wf \cap DOMAIN wf' : wf'[w].decl = wf[w].decl]_vars

\* Invariant 1.2: [Read Declaration] answers the very declaration the
\* [Instantiate] call carried.
Inv1_2_ReadAsTaken ==
    \A w \in DOMAIN wf : ReadDeclaration(w) = taken[w]

\* Invariant 2.1: a workflow stands in exactly one state, and it is one of
\* the workflow's states.
Inv2_1_ExactlyOneState ==
    \A w \in DOMAIN wf :
        /\ Cardinality(wf[w].cur) = 1
        /\ wf[w].cur \subseteq wf[w].decl.states

\* Invariant 3.1: every history entry's from state, action and to state are
\* exactly one declared transition of the workflow's declaration.
Inv3_1_EntryDeclared ==
    \A w \in DOMAIN wf : \A e \in Range(wf[w].hist) :
        Cardinality({t \in wf[w].decl.trans :
                        t.from = e.from /\ t.act = e.act /\ t.to = e.to}) = 1

\* Invariant 3.2: no two declared transitions of one recorded declaration
\* share a from state and an action.
Inv3_2_Deterministic ==
    \A w \in DOMAIN wf : \A t1, t2 \in wf[w].decl.trans :
        (t1 # t2) => ~(t1.from = t2.from /\ t1.act = t2.act)

\* Invariant 4.1: from any step to the next, a workflow standing in one of
\* its terminal states stands there still.
Inv4_1_TerminalAbsorbs ==
    [][\A w \in DOMAIN wf \cap DOMAIN wf' :
          (wf[w].cur \subseteq wf[w].decl.terminal) => (wf'[w].cur = wf[w].cur)]_vars

\* Invariant 4.2: no declared transition of a recorded declaration leaves
\* one of its terminal states.
Inv4_2_NoExitFromTerminal ==
    \A w \in DOMAIN wf : \A t \in wf[w].decl.trans : t.from \notin wf[w].decl.terminal

\* Invariant 5.1: from any step to the next, every entry a history held,
\* where the position still stands, is the same entry.
Inv5_1_EntryUnchanged ==
    [][\A w \in DOMAIN wf \cap DOMAIN wf' :
          \A k \in DOMAIN wf[w].hist :
              (k \in DOMAIN wf'[w].hist) => (wf'[w].hist[k] = wf[w].hist[k])]_vars

\* Invariant 5.2: a workflow holds as many entries as fires were answered
\* new_state on it.
Inv5_2_CountIsFires ==
    \A w \in DOMAIN wf : Len(wf[w].hist) = fires[w]

\* Invariant 6.1: no two entries of one history carry one sequence number.
Inv6_1_SeqUnique ==
    \A w \in DOMAIN wf : \A j, k \in DOMAIN wf[w].hist :
        (j # k) => (wf[w].hist[j].seq # wf[w].hist[k].seq)

\* Invariant 6.2: a history's sequence numbers are exactly one through its
\* entry count.
Inv6_2_SeqDense ==
    \A w \in DOMAIN wf :
        {e.seq : e \in Range(wf[w].hist)} = 1..Len(wf[w].hist)

\* Invariant 6.3: [History] answers the entries in sequence number order,
\* whatever their firing instants, and answers every one of them.
Inv6_3_OrderBySeq ==
    \A w \in DOMAIN wf :
        LET A == HistoryAnswer(w)
        IN  /\ Len(A) = Len(wf[w].hist)
            /\ \A k \in 1..(Len(A) - 1) : A[k].seq < A[k + 1].seq

\* Invariant 7.1: a workflow carrying an entry stands in the to state of
\* the entry with the highest sequence number.
Inv7_1_CurrentIsLastTo ==
    \A w \in DOMAIN wf :
        (Len(wf[w].hist) > 0) => (wf[w].cur = {Highest(w).to})

\* Invariant 7.2: a workflow carrying no entry stands in the initial state.
Inv7_2_EmptyIsInitial ==
    \A w \in DOMAIN wf :
        (Len(wf[w].hist) = 0) => (wf[w].cur = {wf[w].decl.initial})

\* Invariant 7.3: replaying the history from the initial state in sequence
\* number order reaches the current state.
Inv7_3_ReplayReachesCurrent ==
    \A w \in DOMAIN wf : wf[w].cur = {Replay(w)}

\* Invariant 8.1: an entry of a guarded declared transition comes from a
\* call that asserted guard satisfied true.
Inv8_1_GuardAsserted ==
    \A w \in DOMAIN wf : \A e \in Range(wf[w].hist) :
        Guarded(wf[w].decl, e) => (e.callGs = "true")

\* Invariant 8.3: an entry of a guarded declared transition records what
\* the caller asserted.
Inv8_3_AssertionRecorded ==
    \A w \in DOMAIN wf : \A e \in Range(wf[w].hist) :
        Guarded(wf[w].decl, e) => (e.gs = e.callGs)

\* Invariant 9.1: an actor reference recorded on a workflow or an entry is
\* never one of the whitespace strings.
Inv9_1_ActorNotBlank ==
    \A w \in DOMAIN wf :
        /\ wf[w].actor \notin WhitespaceStrings
        /\ \A e \in Range(wf[w].hist) : e.actor \notin WhitespaceStrings

\* Invariant 10.1: from any step to the next, every workflow recorded is
\* recorded still.
Inv10_1_WorkflowKept ==
    [][DOMAIN wf \subseteq DOMAIN wf']_vars

\* Invariant 10.2: from any step to the next, every entry's sequence number
\* still stands in its workflow's history.
Inv10_2_EntryKept ==
    [][\A w \in DOMAIN wf \cap DOMAIN wf' :
          \A e \in Range(wf[w].hist) :
              \E f \in Range(wf'[w].hist) : f.seq = e.seq]_vars

====
