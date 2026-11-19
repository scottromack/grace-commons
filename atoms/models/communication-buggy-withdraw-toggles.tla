---- MODULE communication-buggy-withdraw-toggles ----
\* DELIBERATELY WRONG twin of communication.tla (unit: `atoms/communication.md formal layer`).
\*
\* INJECTED DEFECT: [Withdraw] of a withdrawn communication stands it in
\* active again and answers ok, withdrawing taken for a switch (Invariant
\* 3.1, Operation 30).
\*
\* BREAKS: Inv3_1_WithdrawnFinal, Op30_WithdrawWithdrawnRefused.
\* Everything else is communication.tla as written; read its comments there.

EXTENDS Integers, FiniteSets

CONSTANTS
    MediumSets,   \* the medium sets the deployment may declare
    OutcomeSets,  \* the outcome sets the deployment may declare
    Blanks,       \* blank strings a call may carry
    OverCaps,     \* tokens standing for strings over the string cap
    NotStrings,   \* tokens standing for values that are not strings, such as 42
    MaxC,         \* how many communication ids the host can allocate
    MaxTime       \* the clock's last reading

\* Ids: the communication ids the host can allocate; the n-th communication
\* recorded carries id n and is kept in slot n (a slot is the model's own name
\* for a communication's row, so a check can ask whether its id ever changes).
Ids == 1..MaxC
Slots == 1..MaxC

\* NotId: a communication id a keyed call carries that is not a string.
NotId == 0

\* Times: the clock readings the seam may inject as now, and the instants a
\* call may carry.
Times == 1..MaxTime

\* NoInstant: an occurred instant, start instant or end instant the call
\* leaves blank or omits; NotInstant: one that is not an instant ("last
\* Tuesday").
NoInstant == 0
NotInstant == -1

\* Bad: a string blank or over the string cap, the ground of Operation 5, 6
\* and 8 for a member of a list.
Bad(x) == x \in Blanks \/ x \in OverCaps


\* L, NotAList: a list a call carries, as whether it is a list of strings
\* and the set of its members. An empty list is a list left blank, which
\* reads as omitted (GRACE-lang Earned vocabulary 22).
L(S) == [ok |-> TRUE, m |-> S]
NotAList == [ok |-> FALSE, m |-> {}]
Empty == L({})

\* Sales, Email: the details of the two calls the sales team logs, Dana's
\* call and Jane's email (the Examples), at occurred instant 1.
Sales == [m |-> "phone", o |-> 1, out |-> L({"jane-ruiz"}), in |-> L({"dana"}),
          d |-> "outbound", s |-> "renewal", itm |-> L({"acme-supply"}), oc |-> "connected"]
Email == [m |-> "email", o |-> 1, out |-> L({"jane-ruiz"}), in |-> Empty,
          d |-> "", s |-> "", itm |-> Empty, oc |-> ""]

\* Omitted: the details of a [Change] that supplies none.
Omitted == [m |-> "", o |-> NoInstant, out |-> Empty, in |-> Empty,
             d |-> "", s |-> "", itm |-> Empty, oc |-> ""]

\* Fields: the details in the order of the refuses line (medium, occurred
\* instant, outside participants, inside participants, direction, summary,
\* item references, outcome).
Fields == <<"m", "o", "out", "in", "d", "s", "itm", "oc">>

\* BadVals: for each detail, the bad values a call may carry in it: blank
\* where blank is refused on [Record], over the string cap, not a string (or
\* not a list, not an instant), outside the set, or a list with a bad member.
BadVals(f) ==
    CASE f = "m"   -> {"Phone"} \cup Blanks \cup OverCaps \cup NotStrings
      [] f = "o"   -> {NoInstant, NotInstant}
      [] f = "out" -> {Empty, L({"jane-ruiz"} \cup Blanks), L(OverCaps), NotAList}
      [] f = "in"  -> {L(Blanks), L(OverCaps), NotAList}
      [] f = "d"   -> {"sideways"} \cup NotStrings
      [] f = "s"   -> OverCaps \cup NotStrings
      [] f = "itm" -> {L(Blanks), L(OverCaps), NotAList}
      [] f = "oc"  -> {"Connected"} \cup OverCaps \cup NotStrings

\* Worst: for each detail, one value bad on either detail action.
Worst(f) ==
    CASE f = "m"   -> "Phone"
      [] f = "o"   -> NotInstant
      [] f = "out" -> L({"jane-ruiz"} \cup Blanks)
      [] f = "in"  -> NotAList
      [] f = "d"   -> "sideways"
      [] f = "s"   -> CHOOSE x \in OverCaps : TRUE
      [] f = "itm" -> L(Blanks)
      [] f = "oc"  -> CHOOSE x \in NotStrings : TRUE

\* With: the details base with detail f set to v.
With(base, f, v) == [g \in DOMAIN base |-> IF g = f THEN v ELSE base[g]]

\* From: the details base with every detail from the k-th on the refuses line
\* set to its Worst value: bad in that detail and every one after it.
From(base, k) == [g \in DOMAIN base |->
                    IF \E j \in k..8 : Fields[j] = g THEN Worst(g) ELSE base[g]]

\* RecordIn: every details a [Record] call may carry: Dana's call and Jane's
\* email at each instant (an instant later than now is refused), the email
\* bad in one detail, and the email bad from each detail on.
RecordIn ==
    {With(Sales, "o", t) : t \in Times} \cup {With(Email, "o", t) : t \in Times}
    \cup UNION {{With(Email, Fields[k], v) : v \in BadVals(Fields[k])} : k \in 1..8}
    \cup {From(Email, k) : k \in 1..8}

\* ChangeIn: every details a [Change] call may carry: none; an occurred
\* instant; the medium and a summary; outside participants; the four other
\* details; each detail bad alone; and bad from each detail on.
ChangeIn ==
    {Omitted}
    \cup {With(Omitted, "o", t) : t \in Times}
    \cup {[Omitted EXCEPT !.m = "email", !.s = "renewal-by-friday"]}
    \cup {[Omitted EXCEPT !.out = L({"omar-haddad"})]}
    \cup {[Omitted EXCEPT !.in = L({"dana"}), !.d = "inbound", !.itm = L({"acme-supply"}),
                          !.oc = "connected"]}
    \cup {With(Omitted, Fields[k], Worst(Fields[k])) : k \in 1..8}
    \cup {From(Omitted, k) : k \in 1..8}

\* RefIn: every reference a [History For] call may carry: three that take
\* part, a case variant of one, and each bad kind.
RefIn == {"jane-ruiz", "Jane-Ruiz", "dana", "acme-supply"} \cup Blanks \cup OverCaps \cup NotStrings

\* RangeIn: the start and end instants a [History For] call may carry: an
\* open range, from the last reading, to the first, one ending before it
\* starts, and one with a malformed end at either side.
RangeIn == {<<NoInstant, NoInstant>>, <<MaxTime, NoInstant>>, <<NoInstant, 1>>,
            <<MaxTime, 1>>, <<NotInstant, NoInstant>>, <<NoInstant, NotInstant>>}

\* Keyed: the keyed actions (Term keyed action).
Keyed == {"change", "withdraw", "look_up"}

\* NoLU: the shape of what [Look Up] answers, and its value when nothing is
\* looked up.
NoLU == [id |-> 0, m |-> "", o |-> 0, out |-> {}, in |-> {}, d |-> "", s |-> "",
         itm |-> {}, oc |-> "", st |-> "none"]

\* NoHist: the empty list [History For] answers.
NoHist == [k \in {} |-> 0]

\* NoCall: the record of the last call before any call is made, and the shape
\* of every such record: the action; the id it named; the details it
\* carried; the now it was given; what it answered (a word and an id); what
\* [Look Up] answered; the reference and range [History For] carried and
\* the list it answered.
NoCall == [op |-> "none", i |-> NotId, c |-> Omitted, t |-> 0, ans |-> "none", id |-> 0,
           lu |-> NoLU, ref |-> "", from |-> NoInstant, to |-> NoInstant, hist |-> NoHist]

\* Fold: what a case-folding comparison would make of a value. The page
\* forbids it (Identity 7, 9, 11, 13): the model's own actions never apply
\* it; it is here so a twin can.
Fold(x) == CASE x = "Phone" -> "phone"
             [] x = "Connected" -> "connected"
             [] x = "Jane-Ruiz" -> "jane-ruiz"
             [] OTHER -> x

\* ---------------------------------------------------------------------------
\* State
\* ---------------------------------------------------------------------------

VARIABLES
    st,     \* slot -> the communication's status ("none" before it is recorded)
    cid,    \* slot -> the communication's communication id (0 before)
    med,    \* slot -> the medium ("" before)
    occ,    \* slot -> the occurred instant (0 before)
    opart,  \* slot -> the outside participants, as a set of person references
    ipart,  \* slot -> the inside participants
    dir,    \* slot -> the direction ("" where the communication carries none)
    summ,   \* slot -> the summary ("" where it carries none)
    iref,   \* slot -> the item references
    outc,   \* slot -> the outcome ("" where it carries none)
    mset,   \* the medium set the deployment read at its last start
    oset,   \* the outcome set the deployment read at its last start
    last,   \* the last call made and what it answered (NoCall's shape)
    wrote   \* the communications the last step wrote

\* vars: every variable; a step that changes none of them is a stutter.
vars == <<st, cid, med, occ, opart, ipart, dir, summ, iref, outc, mset, oset, last, wrote>>

\* records: every variable that holds a communication's fields.
records == <<st, cid, med, occ, opart, ipart, dir, summ, iref, outc>>

\* details: every variable that holds a detail (Term detail).
details == <<med, occ, opart, ipart, dir, summ, iref, outc>>

\* deployment: the deployment's two sets.
deployment == <<mset, oset>>

\* Seen: what TLC compares to tell two states apart (the .cfg's VIEW): the
\* communications and the deployment's sets, not the record of the last call.
Seen == <<st, cid, med, occ, opart, ipart, dir, summ, iref, outc, mset, oset>>

\* TypeOK: each variable holds a value of its kind (the model's typing, not a
\* rule of the page).
TypeOK ==
    /\ st \in [Slots -> {"none", "active", "withdrawn"}]
    /\ \A s \in Slots : cid[s] \in Nat
    /\ \A s \in Slots : occ[s] \in Int
    /\ mset \in MediumSets
    /\ oset \in OutcomeSets
    /\ wrote \subseteq Slots

\* Init: no communication; the deployment declares one of the medium sets and
\* one of the outcome sets.
Init ==
    /\ st = [s \in Slots |-> "none"]
    /\ cid = [s \in Slots |-> 0]
    /\ med = [s \in Slots |-> ""]
    /\ occ = [s \in Slots |-> 0]
    /\ opart = [s \in Slots |-> {}]
    /\ ipart = [s \in Slots |-> {}]
    /\ dir = [s \in Slots |-> ""]
    /\ summ = [s \in Slots |-> ""]
    /\ iref = [s \in Slots |-> {}]
    /\ outc = [s \in Slots |-> ""]
    /\ mset \in MediumSets
    /\ oset \in OutcomeSets
    /\ last = NoCall
    /\ wrote = {}

\* ---------------------------------------------------------------------------
\* Actions
\* ---------------------------------------------------------------------------

\* Carries: slot s holds the communication carrying id i (Term keyed action).
Carries(s, i) == st[s] # "none" /\ cid[s] = i

\* The refusals' grounds on a detail action's details c, given now t; rec is
\* TRUE on [Record], where a blank medium, a blank occurred instant and blank
\* outside participants are refused, and FALSE on [Change], where each is a
\* detail omitted.
MediumRefused(c, rec) ==
    \/ rec /\ c.m \in Blanks                                    \* Operation 44
    \/ c.m \in OverCaps                                         \* Operation 1
    \/ c.m \in NotStrings                                       \* Operation 11
    \/ c.m \notin Blanks /\ c.m \notin mset                     \* Operation 2
OccurredRefused(c, t, rec) ==
    \/ rec /\ c.o = NoInstant                                   \* Operation 45
    \/ c.o # NoInstant /\ c.o \notin Times                      \* Operation 12
    \/ c.o \in Times /\ t < c.o                                 \* Operation 3
OutsideRefused(c, rec) ==
    \/ rec /\ c.out.ok /\ c.out.m = {}                          \* Operation 4
    \/ c.out.ok /\ \E x \in c.out.m : Bad(x)                    \* Operation 5
    \/ ~c.out.ok                                                \* Operation 13
InsideRefused(c) ==
    \/ c.in.ok /\ \E x \in c.in.m : Bad(x)                      \* Operation 6
    \/ ~c.in.ok                                                 \* Operation 14
DirectionRefused(c) ==
    c.d \notin Blanks /\ c.d \notin {"inbound", "outbound"}     \* Operation 15
SummaryRefused(c) ==
    \/ c.s \in OverCaps                                         \* Operation 7
    \/ c.s \in NotStrings                                       \* Operation 16
ItemsRefused(c) ==
    \/ c.itm.ok /\ \E x \in c.itm.m : Bad(x)                    \* Operation 8
    \/ ~c.itm.ok                                                \* Operation 17
OutcomeRefused(c) ==
    \/ c.oc \in OverCaps                                        \* Operation 9
    \/ c.oc \in NotStrings                                      \* Operation 18
    \/ c.oc \notin Blanks /\ c.oc \notin oset                   \* Operation 10

\* Refusal: the refusal listed first on the refuses line that applies to the
\* details (Execution Contract Refusal 1), or "none".
Refusal(c, t, rec) ==
    IF MediumRefused(c, rec) THEN "invalid-medium"
    ELSE IF OccurredRefused(c, t, rec) THEN "invalid-occurred-instant"
    ELSE IF OutsideRefused(c, rec) THEN "invalid-outside-participants"
    ELSE IF InsideRefused(c) THEN "invalid-inside-participants"
    ELSE IF DirectionRefused(c) THEN "invalid-direction"
    ELSE IF SummaryRefused(c) THEN "invalid-summary"
    ELSE IF ItemsRefused(c) THEN "invalid-item-references"
    ELSE IF OutcomeRefused(c) THEN "invalid-outcome"
    ELSE "none"

\* Called: the record of a detail action's call and what it answered.
Called(op, i, c, t, a) == [NoCall EXCEPT !.op = op, !.i = i, !.c = c, !.t = t, !.ans = a]

\* RecordRefused: a [Record] some refusal applies to answers it and writes
\* nothing (Operation 1 to 18, 44, 45).
RecordRefused(c, t) ==
    /\ Refusal(c, t, TRUE) # "none"
    /\ last' = Called("record", NotId, c, t, Refusal(c, t, TRUE))
    /\ wrote' = {}
    /\ UNCHANGED <<records, deployment>>

\* RecordRecords: a [Record] no refusal applies to records exactly one
\* communication under the id the host allocates (the next one), carrying the
\* details of the call (Operation 19), an omitted list recorded empty
\* (Operation 21, 22), standing in active (Operation 20), and answers the
\* communication id (Operation 23).
RecordRecords(c, t) ==
    /\ Refusal(c, t, TRUE) = "none"
    /\ LET s == Cardinality({x \in Slots : st[x] # "none"}) + 1 IN
         /\ s \in Slots                                          \* the host has an id left
         /\ st' = [st EXCEPT ![s] = "active"]                    \* Operation 20
         /\ cid' = [cid EXCEPT ![s] = s]                         \* Identity 2
         /\ med' = [med EXCEPT ![s] = c.m]                       \* Operation 19
         /\ occ' = [occ EXCEPT ![s] = c.o]
         /\ opart' = [opart EXCEPT ![s] = c.out.m]
         /\ ipart' = [ipart EXCEPT ![s] = c.in.m]                \* Operation 21
         /\ dir' = [dir EXCEPT ![s] = c.d]
         /\ summ' = [summ EXCEPT ![s] = c.s]
         /\ iref' = [iref EXCEPT ![s] = c.itm.m]                 \* Operation 22
         /\ outc' = [outc EXCEPT ![s] = c.oc]
         /\ wrote' = {s}
         /\ last' = [Called("record", NotId, c, t, "id") EXCEPT !.id = s]  \* Operation 23
    /\ UNCHANGED deployment

\* ChangeUnknown: a [Change] naming an id no communication carries, or one
\* that is not a string, answers not-known and writes nothing (Operation 24).
ChangeUnknown(i, c, t) ==
    /\ ~\E s \in Slots : Carries(s, i)
    /\ last' = Called("change", i, c, t, "not-known")
    /\ wrote' = {}
    /\ UNCHANGED <<records, deployment>>

\* ChangeWithdrawn: a [Change] of a withdrawn communication answers
\* not-active and writes nothing (Operation 25).
ChangeWithdrawn(i, c, t) ==
    /\ \E s \in Slots : Carries(s, i) /\ st[s] = "withdrawn"
    /\ last' = Called("change", i, c, t, "not-active")
    /\ wrote' = {}
    /\ UNCHANGED <<records, deployment>>

\* ChangeRefused: a [Change] of an active communication some refusal applies
\* to answers it and writes nothing (Operation 1 to 3, 5 to 18).
ChangeRefused(i, c, t) ==
    /\ \E s \in Slots : Carries(s, i) /\ st[s] = "active"
    /\ Refusal(c, t, FALSE) # "none"
    /\ last' = Called("change", i, c, t, Refusal(c, t, FALSE))
    /\ wrote' = {}
    /\ UNCHANGED <<records, deployment>>

\* Supplies: the details supply at least one detail; a blank one, an empty
\* list among them, is omitted (Operation 28, GRACE-lang Earned vocabulary
\* 22).
Supplies(c) ==
    \/ c.m \notin Blanks \/ c.o # NoInstant \/ c.out.m # {} \/ c.in.m # {}
    \/ c.d \notin Blanks \/ c.s \notin Blanks \/ c.itm.m # {} \/ c.oc \notin Blanks

\* ChangeNothing: a [Change] of an active communication no refusal applies to
\* that supplies no detail writes nothing (Operation 28) and answers ok
\* (Operation 29): change("c-71", inside_participants=[]).
ChangeNothing(i, c, t) ==
    /\ \E s \in Slots : Carries(s, i) /\ st[s] = "active"
    /\ Refusal(c, t, FALSE) = "none"
    /\ ~Supplies(c)
    /\ last' = Called("change", i, c, t, "ok")
    /\ wrote' = {}
    /\ UNCHANGED <<records, deployment>>

\* ChangeChanges: a [Change] of an active communication no refusal applies to
\* that supplies a detail sets every detail it supplies (Operation 26), leaves
\* every detail it omits (Operation 27), and answers ok (Operation 29).
ChangeChanges(i, c, t) ==
    /\ Refusal(c, t, FALSE) = "none"
    /\ Supplies(c)
    /\ \E s \in Slots :
         /\ Carries(s, i) /\ st[s] = "active"
         /\ med' = [med EXCEPT ![s] = IF c.m \notin Blanks THEN c.m ELSE med[s]]
         /\ occ' = [occ EXCEPT ![s] = IF c.o # NoInstant THEN c.o ELSE occ[s]]
         /\ opart' = [opart EXCEPT ![s] = IF c.out.m # {} THEN c.out.m ELSE opart[s]]
         /\ ipart' = [ipart EXCEPT ![s] = IF c.in.m # {} THEN c.in.m ELSE ipart[s]]
         /\ dir' = [dir EXCEPT ![s] = IF c.d \notin Blanks THEN c.d ELSE dir[s]]
         /\ summ' = [summ EXCEPT ![s] = IF c.s \notin Blanks THEN c.s ELSE summ[s]]
         /\ iref' = [iref EXCEPT ![s] = IF c.itm.m # {} THEN c.itm.m ELSE iref[s]]
         /\ outc' = [outc EXCEPT ![s] = IF c.oc \notin Blanks THEN c.oc ELSE outc[s]]
         /\ wrote' = {s}
    /\ last' = Called("change", i, c, t, "ok")
    /\ UNCHANGED <<st, cid, deployment>>

\* WithdrawUnknown: a [Withdraw] naming an id no communication carries
\* answers not-known and writes nothing (Operation 24).
WithdrawUnknown(i) ==
    /\ ~\E s \in Slots : Carries(s, i)
    /\ last' = [NoCall EXCEPT !.op = "withdraw", !.i = i, !.ans = "not-known"]
    /\ wrote' = {}
    /\ UNCHANGED <<records, deployment>>

\* WithdrawWithdrawn: a [Withdraw] of a withdrawn communication answers
\* not-active and writes nothing (Operation 30): the second withdraw("c-73").
WithdrawWithdrawn(i) ==
    /\ \E s \in Slots :
         /\ Carries(s, i) /\ st[s] = "withdrawn"
         /\ st' = [st EXCEPT ![s] = "active"]                    \* BUG: withdrawn undone
         /\ wrote' = {s}
    /\ last' = [NoCall EXCEPT !.op = "withdraw", !.i = i, !.ans = "ok"]
    /\ UNCHANGED <<cid, details, deployment>>

\* WithdrawWithdraws: a [Withdraw] of an active communication stands it in
\* withdrawn (Operation 31), changes no detail and removes nothing
\* (Operation 32, State 4), and answers ok (Operation 33).
WithdrawWithdraws(i) ==
    /\ \E s \in Slots :
         /\ Carries(s, i) /\ st[s] = "active"
         /\ st' = [st EXCEPT ![s] = "withdrawn"]                 \* Operation 31
         /\ wrote' = {s}
    /\ last' = [NoCall EXCEPT !.op = "withdraw", !.i = i, !.ans = "ok"]
    /\ UNCHANGED <<cid, details, deployment>>

\* LookUpUnknown: a [Look Up] naming an id no communication carries answers
\* not-known (Operation 24): look_up("c-404").
LookUpUnknown(i) ==
    /\ ~\E s \in Slots : Carries(s, i)
    /\ last' = [NoCall EXCEPT !.op = "look_up", !.i = i, !.ans = "not-known"]
    /\ wrote' = {}
    /\ UNCHANGED <<records, deployment>>

\* LookUpKnown: a [Look Up] answers the communication carrying the id, active
\* or withdrawn (Operation 34), and writes nothing (Operation 35).
LookUpKnown(i) ==
    /\ \E s \in Slots :
         /\ Carries(s, i)
         /\ last' = [NoCall EXCEPT !.op = "look_up", !.i = i, !.ans = "communication",
                      !.lu = [id |-> cid[s], m |-> med[s], o |-> occ[s], out |-> opart[s],
                              in |-> ipart[s], d |-> dir[s], s |-> summ[s], itm |-> iref[s],
                              oc |-> outc[s], st |-> st[s]]]
    /\ wrote' = {}
    /\ UNCHANGED <<records, deployment>>

\* Inside: the occurred instant o lies inside the range from a to b, each end
\* open where the call carries none (Term range).
Inside(o, a, b) == (a = NoInstant \/ a <= o) /\ (b = NoInstant \/ o <= b)

\* Matches: the slots of the active communications carrying the reference as
\* an outside participant, an inside participant or an item reference, each
\* compared codepoint for codepoint, with an occurred instant inside the
\* range (Term match, Identity 7, 9).
Matches(r, a, b) ==
    {s \in Slots : /\ st[s] = "active"
                   /\ r \in opart[s] \cup ipart[s] \cup iref[s]
                   /\ Inside(occ[s], a, b)}

\* Before: the order [History For] answers in: occurred instant, earliest
\* first, then codepoint order of communication id (Operation 39, 40).
Before(x, y) == \/ occ[x] < occ[y]
                \/ (occ[x] = occ[y] /\ cid[x] < cid[y])

\* Ordered: a set of slots as the list of their ids, each placed after every
\* slot Before it.
Ordered(S) == [k \in 1..Cardinality(S) |->
                 cid[CHOOSE e \in S : Cardinality({x \in S : Before(x, e)}) = k - 1]]

\* HistoryBad: a [History For] whose reference is blank, over the string cap
\* or not a string, or whose start or end instant is not an instant, answers
\* an empty list (Operation 41, 42) and writes nothing (Operation 43).
HistoryBad(r, a, b) ==
    /\ \/ r \in Blanks \/ r \in OverCaps \/ r \in NotStrings
       \/ a = NotInstant \/ b = NotInstant
    /\ last' = [NoCall EXCEPT !.op = "history_for", !.ref = r, !.from = a, !.to = b,
                 !.ans = "communications", !.hist = NoHist]
    /\ wrote' = {}
    /\ UNCHANGED <<records, deployment>>

\* HistoryGood: a [History For] of a well-formed reference and range answers
\* every match, in order (Operation 36 to 40), an empty list where none
\* matches (Operation 38), and writes nothing (Operation 43).
HistoryGood(r, a, b) ==
    /\ r \notin Blanks /\ r \notin OverCaps /\ r \notin NotStrings
    /\ a # NotInstant /\ b # NotInstant
    /\ last' = [NoCall EXCEPT !.op = "history_for", !.ref = r, !.from = a, !.to = b,
                 !.ans = "communications", !.hist = Ordered(Matches(r, a, b))]
    /\ wrote' = {}
    /\ UNCHANGED <<records, deployment>>

\* Declare: the deployment declares a medium set and an outcome set, the same
\* or others, at a restart between two calls (Capability requirement 8, 9;
\* Execution Contract Logic confinement 17); no communication is written.
Declare(M, O) ==
    /\ mset' = M
    /\ oset' = O
    /\ last' = [NoCall EXCEPT !.op = "declare"]
    /\ wrote' = {}
    /\ UNCHANGED records

\* Next: any call of the five actions, admitted or refused as the page says,
\* or a restart declaring the deployment's sets.
Next ==
    \/ \E c \in RecordIn, t \in Times : RecordRefused(c, t)
    \/ \E c \in RecordIn, t \in Times : RecordRecords(c, t)
    \/ \E i \in {NotId} \cup Ids, c \in ChangeIn, t \in Times : ChangeUnknown(i, c, t)
    \/ \E i \in Ids, c \in ChangeIn, t \in Times : ChangeWithdrawn(i, c, t)
    \/ \E i \in Ids, c \in ChangeIn, t \in Times : ChangeRefused(i, c, t)
    \/ \E i \in Ids, c \in ChangeIn, t \in Times : ChangeNothing(i, c, t)
    \/ \E i \in Ids, c \in ChangeIn, t \in Times : ChangeChanges(i, c, t)
    \/ \E i \in {NotId} \cup Ids : WithdrawUnknown(i)
    \/ \E i \in Ids : WithdrawWithdrawn(i)
    \/ \E i \in Ids : WithdrawWithdraws(i)
    \/ \E i \in {NotId} \cup Ids : LookUpUnknown(i)
    \/ \E i \in Ids : LookUpKnown(i)
    \/ \E r \in RefIn, g \in RangeIn : HistoryBad(r, g[1], g[2])
    \/ \E r \in RefIn, g \in RangeIn : HistoryGood(r, g[1], g[2])
    \/ \E M \in MediumSets, O \in OutcomeSets : Declare(M, O)

\* Spec: every behaviour from Init by Next steps.
Spec == Init /\ [][Next]_vars

\* ---------------------------------------------------------------------------
\* Checks (the verification surface). Every check is an action property, so
\* the VIEW drops no step it reads (see the header). The checks read the
\* page's grounds afresh, never the actions' own.
\* ---------------------------------------------------------------------------

\* Quiet: the step writes no communication and changes no field of any: the
\* case table's effect "none".
Quiet == wrote' = {} /\ UNCHANGED records

\* C, Rec, Detail: the details the step's call carried; the call is a
\* [Record]; the call is a detail action (Term detail action).
C == last'.c
Rec == last'.op = "record"
Detail == last'.op \in {"record", "change"}

\* Known, ActiveId, WithdrawnId: some communication carries the id the call
\* named; it stands active; it stands withdrawn (before the step).
Known == \E s \in Slots : st[s] # "none" /\ cid[s] = last'.i
ActiveId == \E s \in Slots : st[s] = "active" /\ cid[s] = last'.i
WithdrawnId == \E s \in Slots : st[s] = "withdrawn" /\ cid[s] = last'.i

\* Target: the slot of the communication carrying the id the call named.
Target == CHOOSE s \in Slots : st[s] # "none" /\ cid[s] = last'.i

\* Reached: no refusal listed before the details' on the refuses line applies:
\* on [Change], the id names an active communication (Operation 24, 25).
Reached == Detail /\ (Rec \/ ActiveId)

\* The page's grounds, detail by detail, as the checks read them: each detail
\* passes every rule on it (Operation 1 to 18, 44, 45).
MediumOk == /\ ~(Rec /\ C.m \in Blanks) /\ C.m \notin OverCaps /\ C.m \notin NotStrings
            /\ (C.m \in Blanks \/ C.m \in mset)
OccurredOk == /\ ~(Rec /\ C.o = NoInstant) /\ (C.o = NoInstant \/ C.o \in Times)
              /\ ~(C.o \in Times /\ last'.t < C.o)
OutsideOk == /\ C.out.ok /\ ~(Rec /\ C.out.m = {})
             /\ \A x \in C.out.m : x \notin Blanks /\ x \notin OverCaps
InsideOk == C.in.ok /\ \A x \in C.in.m : x \notin Blanks /\ x \notin OverCaps
DirectionOk == C.d \in Blanks \cup {"inbound", "outbound"}
SummaryOk == C.s \notin OverCaps /\ C.s \notin NotStrings
ItemsOk == C.itm.ok /\ \A x \in C.itm.m : x \notin Blanks /\ x \notin OverCaps
OutcomeOk == /\ C.oc \notin OverCaps /\ C.oc \notin NotStrings
             /\ (C.oc \in Blanks \/ C.oc \in oset)
AllOk == /\ MediumOk /\ OccurredOk /\ OutsideOk /\ InsideOk
         /\ DirectionOk /\ SummaryOk /\ ItemsOk /\ OutcomeOk

\* Refused: the call answered refusal a and wrote nothing.
Refused(a) == last'.ans = a /\ Quiet

\* NewSlots: the slots of the communications the step recorded.
NewSlots == {s \in Slots : st[s] = "none" /\ st'[s] # "none"}

\* State4_NeverRemoved: no step removes a communication, a withdrawn one
\* included (State 4, Non-goal 13).
State4_NeverRemoved ==
    [][\A s \in Slots : st[s] # "none" => st'[s] # "none"]_vars

\* Inv2_1_IdKept: no step changes a communication's communication id
\* (Invariant 2.1).
Inv2_1_IdKept ==
    [][\A s \in Slots : st[s] # "none" => cid'[s] = cid[s]]_vars

\* Inv3_1_WithdrawnFinal: no step stands a withdrawn communication in active
\* (Invariant 3.1, What undoes a write).
Inv3_1_WithdrawnFinal ==
    [][\A s \in Slots : st[s] = "withdrawn" => st'[s] = "withdrawn"]_vars

\* Op1_MediumOverCapRefused: a detail action whose medium is over the string
\* cap answered invalid-medium and wrote nothing (Operation 1).
Op1_MediumOverCapRefused ==
    [][(Reached /\ C.m \in OverCaps) => Refused("invalid-medium")]_vars

\* Op2_MediumOutsideSetRefused: a detail action whose medium is not blank and
\* not in the medium set, compared codepoint for codepoint, answered
\* invalid-medium and wrote nothing: record("fax", ...) and record("Phone",
\* ...) where the set offers phone, and a [Change] to a medium the deployment
\* dropped (Operation 2, Identity 11).
Op2_MediumOutsideSetRefused ==
    [][(Reached /\ C.m \notin Blanks /\ C.m \notin mset) => Refused("invalid-medium")]_vars

\* Op3_FutureInstantRefused: a detail action whose medium passes and whose
\* occurred instant is later than now answered invalid-occurred-instant and
\* wrote nothing: next Monday's call (Operation 3, Non-goal 2).
Op3_FutureInstantRefused ==
    [][(Reached /\ MediumOk /\ C.o \in Times /\ last'.t < C.o)
         => Refused("invalid-occurred-instant")]_vars

\* Op4_RecordNoOutsideRefused: a [Record] whose medium and occurred instant
\* pass and whose outside participants are blank, omitted or an empty list
\* answered invalid-outside-participants and wrote nothing (Operation 4).
Op4_RecordNoOutsideRefused ==
    [][(Rec /\ MediumOk /\ OccurredOk /\ C.out.ok /\ C.out.m = {})
         => Refused("invalid-outside-participants")]_vars

\* Op5_OutsideMemberRefused: a detail action whose earlier details pass and
\* one of whose outside participants is blank or over the string cap answered
\* invalid-outside-participants and wrote nothing (Operation 5).
Op5_OutsideMemberRefused ==
    [][(Reached /\ MediumOk /\ OccurredOk /\ C.out.ok /\ \E x \in C.out.m : Bad(x))
         => Refused("invalid-outside-participants")]_vars

\* Op6_InsideMemberRefused: the same for an inside participant (Operation 6).
Op6_InsideMemberRefused ==
    [][(Reached /\ MediumOk /\ OccurredOk /\ OutsideOk /\ C.in.ok /\ \E x \in C.in.m : Bad(x))
         => Refused("invalid-inside-participants")]_vars

\* Op7_SummaryOverCapRefused: a detail action whose earlier details pass and
\* whose summary is over the string cap answered invalid-summary and wrote
\* nothing (Operation 7).
Op7_SummaryOverCapRefused ==
    [][(Reached /\ MediumOk /\ OccurredOk /\ OutsideOk /\ InsideOk /\ DirectionOk
            /\ C.s \in OverCaps)
         => Refused("invalid-summary")]_vars

\* Op8_ItemMemberRefused: the same for an item reference blank or over the
\* string cap, answered invalid-item-references (Operation 8).
Op8_ItemMemberRefused ==
    [][(Reached /\ MediumOk /\ OccurredOk /\ OutsideOk /\ InsideOk /\ DirectionOk
            /\ SummaryOk /\ C.itm.ok /\ \E x \in C.itm.m : Bad(x))
         => Refused("invalid-item-references")]_vars

\* Op9_OutcomeOverCapRefused: a detail action whose earlier details pass and
\* whose outcome is over the string cap answered invalid-outcome and wrote
\* nothing (Operation 9).
Op9_OutcomeOverCapRefused ==
    [][(Reached /\ MediumOk /\ OccurredOk /\ OutsideOk /\ InsideOk /\ DirectionOk
            /\ SummaryOk /\ ItemsOk /\ C.oc \in OverCaps)
         => Refused("invalid-outcome")]_vars

\* Op10_OutcomeOutsideSetRefused: the same for an outcome not blank and not
\* in the outcome set, compared codepoint for codepoint: outcome busy at the
\* sales team, Connected where the set offers connected, and any outcome at
\* the property manager (Operation 10, Identity 13).
Op10_OutcomeOutsideSetRefused ==
    [][(Reached /\ MediumOk /\ OccurredOk /\ OutsideOk /\ InsideOk /\ DirectionOk
            /\ SummaryOk /\ ItemsOk /\ C.oc \notin Blanks /\ C.oc \notin oset)
         => Refused("invalid-outcome")]_vars

\* Op11_MediumNotAStringRefused: a detail action whose medium is not a string
\* answered invalid-medium and wrote nothing (Operation 11).
Op11_MediumNotAStringRefused ==
    [][(Reached /\ C.m \in NotStrings) => Refused("invalid-medium")]_vars

\* Op12_InstantMalformedRefused: a detail action whose medium passes and whose
\* occurred instant is not an instant answered invalid-occurred-instant and
\* wrote nothing: record("phone", "last Tuesday", ...) (Operation 12).
Op12_InstantMalformedRefused ==
    [][(Reached /\ MediumOk /\ C.o # NoInstant /\ C.o \notin Times)
         => Refused("invalid-occurred-instant")]_vars

\* Op13_OutsideMalformedRefused: a detail action whose earlier details pass
\* and whose outside participants are not a list of strings answered
\* invalid-outside-participants and wrote nothing (Operation 13).
Op13_OutsideMalformedRefused ==
    [][(Reached /\ MediumOk /\ OccurredOk /\ ~C.out.ok)
         => Refused("invalid-outside-participants")]_vars

\* Op14_InsideMalformedRefused: the same for inside participants (Operation
\* 14).
Op14_InsideMalformedRefused ==
    [][(Reached /\ MediumOk /\ OccurredOk /\ OutsideOk /\ ~C.in.ok)
         => Refused("invalid-inside-participants")]_vars

\* Op15_DirectionMalformedRefused: a detail action whose earlier details pass
\* and whose direction is neither blank, inbound nor outbound answered
\* invalid-direction and wrote nothing: direction="sideways" (Operation 15).
Op15_DirectionMalformedRefused ==
    [][(Reached /\ MediumOk /\ OccurredOk /\ OutsideOk /\ InsideOk
            /\ C.d \notin Blanks /\ C.d \notin {"inbound", "outbound"})
         => Refused("invalid-direction")]_vars

\* Op16_SummaryMalformedRefused: the same for a summary that is not a string,
\* answered invalid-summary (Operation 16).
Op16_SummaryMalformedRefused ==
    [][(Reached /\ MediumOk /\ OccurredOk /\ OutsideOk /\ InsideOk /\ DirectionOk
            /\ C.s \in NotStrings)
         => Refused("invalid-summary")]_vars

\* Op17_ItemsMalformedRefused: the same for item references that are not a
\* list of strings, answered invalid-item-references (Operation 17).
Op17_ItemsMalformedRefused ==
    [][(Reached /\ MediumOk /\ OccurredOk /\ OutsideOk /\ InsideOk /\ DirectionOk
            /\ SummaryOk /\ ~C.itm.ok)
         => Refused("invalid-item-references")]_vars

\* Op18_OutcomeMalformedRefused: the same for an outcome that is not a
\* string, answered invalid-outcome (Operation 18).
Op18_OutcomeMalformedRefused ==
    [][(Reached /\ MediumOk /\ OccurredOk /\ OutsideOk /\ InsideOk /\ DirectionOk
            /\ SummaryOk /\ ItemsOk /\ C.oc \in NotStrings)
         => Refused("invalid-outcome")]_vars

\* Op19_RecordRecordsOne: a [Record] no refusal applies to recorded exactly
\* one communication, carrying every detail of the call, the direction,
\* summary and outcome absent where the call gave none (Operation 19, State
\* 2): Jane's email, with no direction, summary or outcome, is recorded.
Op19_RecordRecordsOne ==
    [][(Rec /\ AllOk)
         => \E s \in Slots :
              /\ NewSlots = {s}
              /\ med'[s] = C.m /\ occ'[s] = C.o /\ opart'[s] = C.out.m
              /\ ipart'[s] = C.in.m /\ dir'[s] = C.d /\ summ'[s] = C.s
              /\ iref'[s] = C.itm.m /\ outc'[s] = C.oc]_vars

\* Op23_RecordAnswersId: such a [Record] answered the id of the communication
\* it recorded (Operation 23).
Op23_RecordAnswersId ==
    [][(Rec /\ AllOk)
         => (last'.ans = "id" /\ \E s \in NewSlots : last'.id = cid'[s])]_vars

\* Op24_UnknownIdNotKnown: a [Change], [Withdraw] or [Look Up] naming an id no
\* communication carries, or one that is not a string, answered not-known and
\* wrote nothing: change("c-404", ...) and look_up("c-404") (Operation 24).
Op24_UnknownIdNotKnown ==
    [][(last'.op \in Keyed /\ ~Known) => Refused("not-known")]_vars

\* Op25_ChangeWithdrawnRefused: a [Change] of a withdrawn communication
\* answered not-active and wrote nothing, whatever details it carried:
\* change("c-73", ...) (Operation 25).
Op25_ChangeWithdrawnRefused ==
    [][(last'.op = "change" /\ WithdrawnId) => Refused("not-active")]_vars

\* ChangeOk: the step is a [Change] of an active communication no refusal
\* applies to.
ChangeOk == last'.op = "change" /\ ActiveId /\ AllOk

\* Op26_ChangeSetsSupplied: such a [Change] set every detail it supplied, a
\* blank one, an empty list among them, being one it omits: Dana's sharper
\* summary, and the medium and summary set together (Operation 26).
Op26_ChangeSetsSupplied ==
    [][ChangeOk
         => LET s == Target IN
              /\ (C.m \notin Blanks => med'[s] = C.m)
              /\ (C.o # NoInstant => occ'[s] = C.o)
              /\ (C.out.m # {} => opart'[s] = C.out.m)
              /\ (C.in.m # {} => ipart'[s] = C.in.m)
              /\ (C.d \notin Blanks => dir'[s] = C.d)
              /\ (C.s \notin Blanks => summ'[s] = C.s)
              /\ (C.itm.m # {} => iref'[s] = C.itm.m)
              /\ (C.oc \notin Blanks => outc'[s] = C.oc)]_vars

\* Op27_ChangeKeepsOmitted: such a [Change] changed no detail it omitted or
\* left blank: a medium the deployment has since dropped stands where the
\* call carries no medium (Operation 27, the Edge cases "A detail once given"
\* and "A medium set or an outcome set that changes").
Op27_ChangeKeepsOmitted ==
    [][ChangeOk
         => LET s == Target IN
              /\ (C.m \in Blanks => med'[s] = med[s])
              /\ (C.o = NoInstant => occ'[s] = occ[s])
              /\ (C.out.m = {} => opart'[s] = opart[s])
              /\ (C.in.m = {} => ipart'[s] = ipart[s])
              /\ (C.d \in Blanks => dir'[s] = dir[s])
              /\ (C.s \in Blanks => summ'[s] = summ[s])
              /\ (C.itm.m = {} => iref'[s] = iref[s])
              /\ (C.oc \in Blanks => outc'[s] = outc[s])]_vars

\* Op28_ChangeNoDetailWritesNothing: such a [Change] supplying no detail
\* wrote nothing: change("c-71", inside_participants=[]) (Operation 28).
Op28_ChangeNoDetailWritesNothing ==
    [][(ChangeOk
          /\ C.m \in Blanks /\ C.o = NoInstant /\ C.out.m = {} /\ C.in.m = {}
          /\ C.d \in Blanks /\ C.s \in Blanks /\ C.itm.m = {} /\ C.oc \in Blanks)
         => Quiet]_vars

\* Op29_ChangeAnswersOk: such a [Change] answered ok, whether it supplied a
\* detail or none (Operation 29).
Op29_ChangeAnswersOk ==
    [][ChangeOk => last'.ans = "ok"]_vars

\* Op30_WithdrawWithdrawnRefused: a [Withdraw] of a withdrawn communication
\* answered not-active and wrote nothing: the second withdraw("c-73")
\* (Operation 30).
Op30_WithdrawWithdrawnRefused ==
    [][(last'.op = "withdraw" /\ WithdrawnId) => Refused("not-active")]_vars

\* Op31_WithdrawStandsWithdrawn: a [Withdraw] of an active communication
\* left it standing in withdrawn (Operation 31).
Op31_WithdrawStandsWithdrawn ==
    [][(last'.op = "withdraw" /\ ActiveId) => st'[Target] = "withdrawn"]_vars

\* Op32_WithdrawKeepsDetails: such a [Withdraw] changed no detail of the
\* communication (Operation 32).
Op32_WithdrawKeepsDetails ==
    [][(last'.op = "withdraw" /\ ActiveId)
         => LET s == Target IN
              /\ med'[s] = med[s] /\ occ'[s] = occ[s] /\ opart'[s] = opart[s]
              /\ ipart'[s] = ipart[s] /\ dir'[s] = dir[s] /\ summ'[s] = summ[s]
              /\ iref'[s] = iref[s] /\ outc'[s] = outc[s]]_vars

\* Op33_WithdrawAnswersOk: such a [Withdraw] answered ok (Operation 33).
Op33_WithdrawAnswersOk ==
    [][(last'.op = "withdraw" /\ ActiveId) => last'.ans = "ok"]_vars

\* Op34_LookUpAnswers: a [Look Up] naming a communication answered it, every
\* detail, its id and its status, a withdrawn one included: look_up("c-73")
\* answers the communication, withdrawn (Operation 34).
Op34_LookUpAnswers ==
    [][(last'.op = "look_up" /\ Known)
         => LET s == Target IN
              /\ last'.ans = "communication"
              /\ last'.lu = [id |-> cid[s], m |-> med[s], o |-> occ[s], out |-> opart[s],
                             in |-> ipart[s], d |-> dir[s], s |-> summ[s], itm |-> iref[s],
                             oc |-> outc[s], st |-> st[s]]]_vars

\* Op35_LookUpWritesNothing: a [Look Up] step wrote nothing (Operation 35).
Op35_LookUpWritesNothing ==
    [][last'.op = "look_up" => Quiet]_vars

\* History, GoodQuery: the step is a [History For] call; its reference is a
\* string within the cap and not blank, and each instant it carries is one
\* (Operation 41, 42).
History == last'.op = "history_for"
GoodQuery == /\ last'.ref \notin Blanks /\ last'.ref \notin OverCaps
             /\ last'.ref \notin NotStrings
             /\ last'.from # NotInstant /\ last'.to # NotInstant

\* IsMatch: slot s holds a match of the call: an active communication
\* carrying the reference as an outside participant, an inside participant
\* or an item reference, its occurred instant inside the range (Term match).
IsMatch(s) ==
    /\ st[s] = "active"
    /\ last'.ref \in opart[s] \cup ipart[s] \cup iref[s]
    /\ (last'.from = NoInstant \/ last'.from <= occ[s])
    /\ (last'.to = NoInstant \/ occ[s] <= last'.to)

\* H: the list the [History For] call answered.
H == last'.hist

\* OccOf: the occurred instant of the communication carrying id x.
OccOf(x) == occ[CHOOSE s \in Slots : st[s] # "none" /\ cid[s] = x]

\* Op36_HistoryEveryMatch: a [History For] of a well-formed reference and
\* range answered every match: history_for("unit-4b") answers p-9 and p-10,
\* and history_for("omar-haddad") the same two (Operation 36).
Op36_HistoryEveryMatch ==
    [][(History /\ GoodQuery)
         => \A s \in Slots : IsMatch(s) => \E k \in DOMAIN H : H[k] = cid[s]]_vars

\* HistoryTerm_OnlyMatches: every communication such a [History For]
\* answered is a match: none outside the range, none not naming the
\* reference (the term history: "the matches a [History For] call answers";
\* the term History For).
HistoryTerm_OnlyMatches ==
    [][(History /\ GoodQuery)
         => \A k \in DOMAIN H : \E s \in Slots : IsMatch(s) /\ cid[s] = H[k]]_vars

\* Op37_HistoryNoWithdrawn: no [History For] answered a withdrawn
\* communication: c-73 leaves the history once withdrawn (Operation 37).
Op37_HistoryNoWithdrawn ==
    [][History
         => \A k \in DOMAIN H, s \in Slots :
              (st[s] # "none" /\ cid[s] = H[k]) => st[s] = "active"]_vars

\* Op38_HistoryEmptyForNoMatch: a [History For] of a well-formed reference
\* and range no match carries answered an empty list: history_for
\* ("Jane-Ruiz") where only jane-ruiz took part, and a range ending before it
\* starts (Operation 38, Identity 7, 9).
Op38_HistoryEmptyForNoMatch ==
    [][(History /\ GoodQuery /\ ~\E s \in Slots : IsMatch(s)) => H = NoHist]_vars

\* Op39_HistoryByOccurred: each communication a [History For] answered
\* happened no later than the next: Dana's Tuesday call before Jane's
\* Wednesday email, whichever was logged first (Operation 39).
Op39_HistoryByOccurred ==
    [][History
         => \A k \in DOMAIN H : (k + 1 \in DOMAIN H) => OccOf(H[k]) <= OccOf(H[k + 1])]_vars

\* Op40_HistoryTiesById: of two communications sharing an occurred instant,
\* a [History For] answered the lower id first (Operation 40).
Op40_HistoryTiesById ==
    [][History
         => \A k \in DOMAIN H :
              (k + 1 \in DOMAIN H /\ OccOf(H[k]) = OccOf(H[k + 1])) => H[k] < H[k + 1]]_vars

\* Op41_HistoryBadReferenceEmpty: a [History For] whose reference is blank,
\* over the string cap or not a string answered an empty list (Operation 41).
Op41_HistoryBadReferenceEmpty ==
    [][(History /\ (last'.ref \in Blanks \/ last'.ref \in OverCaps \/ last'.ref \in NotStrings))
         => H = NoHist]_vars

\* Op42_HistoryBadInstantEmpty: a [History For] whose start or end instant is
\* not an instant answered an empty list (Operation 42).
Op42_HistoryBadInstantEmpty ==
    [][(History /\ (last'.from = NotInstant \/ last'.to = NotInstant)) => H = NoHist]_vars

\* Op43_HistoryWritesNothing: a [History For] step wrote nothing (Operation
\* 43).
Op43_HistoryWritesNothing ==
    [][History => Quiet]_vars

\* Op44_RecordBlankMediumRefused: a [Record] whose medium is blank answered
\* invalid-medium and wrote nothing, whatever else it carried: record("",
\* ...) and record("fax", "", []) (Operation 44, Execution Contract Refusal 1).
Op44_RecordBlankMediumRefused ==
    [][(Rec /\ C.m \in Blanks) => Refused("invalid-medium")]_vars

\* Op45_RecordBlankInstantRefused: a [Record] whose medium passes and whose
\* occurred instant is blank answered invalid-occurred-instant and wrote
\* nothing: record("phone", "", ["jane-ruiz"]) is never logged as now
\* (Operation 45, in place of Execution Contract Logic confinement 12).
Op45_RecordBlankInstantRefused ==
    [][(Rec /\ MediumOk /\ C.o = NoInstant) => Refused("invalid-occurred-instant")]_vars

====
