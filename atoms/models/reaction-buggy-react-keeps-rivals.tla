---- MODULE reaction-buggy-react-keeps-rivals ----
\* DELIBERATELY WRONG twin of reaction.tla (unit: `atoms/reaction.md formal layer`).
\*
\* INJECTED DEFECT: [React] never withdraws a rival, so under one-per-item ana holds like and love
\* at once after choosing love (Operation 10).
\*
\* BREAKS: Op10_OnePerItemWithdrawsRivals.
\* Everything else is reaction.tla as written; read its comments there.

EXTENDS Integers, FiniteSets

CONSTANTS
    Persons,       \* the person references a call may carry that are well-formed
    Items,         \* the item references a call may carry that are well-formed
    Names,         \* the reaction names a call may carry that are well-formed
    Blanks,        \* blank strings a call may carry as any of the three
    OverCaps,      \* tokens standing for strings over the string cap
    NotStrings,    \* tokens standing for values that are not strings, such as 42
    ReactionSets,  \* the reaction sets the deployment may declare, each a subset of Names
    MaxTime,       \* the clock's last reading
    MaxReactions   \* the budget: at most this many reactions recorded

\* Times: the clock readings the seam may inject as now.
Times == 1..MaxTime

\* HoldingRules: the two holding rules a deployment may declare (Term
\* holding rule).
HoldingRules == {"one-per-item", "one-of-each"}

\* PersonIn, ItemIn, NameIn: every value a call may carry as a person
\* reference, an item reference or a reaction name, well-formed or not.
PersonIn == Persons \cup Blanks \cup OverCaps \cup NotStrings
ItemIn == Items \cup Blanks \cup OverCaps \cup NotStrings
NameIn == Names \cup Blanks \cup OverCaps \cup NotStrings

\* Slots: one slot for each well-formed triple, where [React] records the
\* triple's reaction. A slot is the model's own name for a reaction, so a
\* check can ask whether its fields ever change; its fields are written by
\* the actions, never read off its name.
Slots == Persons \X Items \X Names

\* Writing: the writing actions (Term writing action).
Writing == {"react", "withdraw"}

\* NoRef: a slot's field before a reaction is recorded in it, and the field
\* of a call that carries none.
NoRef == "none"

\* NoNames, NoTallies: the empty list [Look Up] and [Count] answer, and the
\* list fields of an answer that is no list.
NoNames == [k \in {} |-> NoRef]
NoTallies == [k \in {} |-> [name |-> NoRef, tally |-> 0]]

\* NoCall: the record of the last call before any call is made, and the shape
\* of every such record: the action; the person reference, item reference
\* and reaction name it carried; what it answered; and the lists [Look Up]
\* (out) and [Count] (tal) answered.
NoCall == [op |-> "none", p |-> NoRef, i |-> NoRef, n |-> NoRef, ans |-> "none",
           out |-> NoNames, tal |-> NoTallies]

\* BlankOrOverCap, NotAString, WellFormed: what the page's refusals read of a
\* value (Operation 1 to 3, 23 to 28). The checks read these.
BlankOrOverCap(x) == x \in Blanks \/ x \in OverCaps
NotAString(x) == x \in NotStrings
WellFormed(x) == ~BlankOrOverCap(x) /\ ~NotAString(x)

\* Rank: the code point order of the reaction names (Execution Contract
\* Logic confinement 10): "Like" (L, U+004C) before "like" (l, U+006C),
\* and "like" (i, U+0069) before "love" (o, U+006F). It ranks the Names of
\* the .cfg and must be kept with them.
Rank(x) == CASE x = "Like" -> 1
             [] x = "like" -> 2
             [] x = "love" -> 3
             [] OTHER -> 4

\* Fold: what a case-folding comparison would make of a value. The page
\* forbids it (Identity 2 to 7): the model's own actions never apply it; it
\* is here so a twin can.
Fold(x) == CASE x = "Ana" -> "ana"
             [] x = "Post-41" -> "post-41"
             [] x = "Like" -> "like"
             [] OTHER -> x

\* ---------------------------------------------------------------------------
\* State
\* ---------------------------------------------------------------------------

VARIABLES
    per,    \* slot -> the reaction's person reference (NoRef before it is recorded)
    itm,    \* slot -> the reaction's item reference (NoRef before it is recorded)
    nm,     \* slot -> the reaction's reaction name (NoRef before it is recorded)
    fri,    \* slot -> the reaction's first reacted instant (0 before it is recorded)
    st,     \* slot -> the reaction's status ("none" before it is recorded)
    rule,   \* the holding rule the deployment declares now
    rset,   \* the reaction set the deployment declares now
    last,   \* the last call made and what it answered (NoCall's shape)
    wrote   \* the reactions the last step wrote

\* vars: every variable; a step that changes none of them is a stutter.
vars == <<per, itm, nm, fri, st, rule, rset, last, wrote>>

\* records: every variable that holds a reaction's fields.
records == <<per, itm, nm, fri, st>>

\* deployment: the deployment's two settings.
deployment == <<rule, rset>>

\* Seen: what TLC compares to tell two states apart (the .cfg's VIEW): the
\* reactions and the deployment's settings, not the record of the last call.
Seen == <<per, itm, nm, fri, st, rule, rset>>

\* Budget: at most MaxReactions reactions recorded (the .cfg's CONSTRAINT): a
\* bound on the search, not a rule of the page.
Budget == Cardinality({s \in Slots : st[s] # "none"}) <= MaxReactions

\* Recorded: a reaction stands in the slot.
Recorded(s) == st[s] # "none"

\* Holds: the reaction in slot s carries the triple, each value compared
\* codepoint for codepoint (Term triple, Identity 3, 5, 7).
Holds(s, p, i, n) == Recorded(s) /\ per[s] = p /\ itm[s] = i /\ nm[s] = n

\* Exists: some reaction exists for the triple.
Exists(p, i, n) == \E s \in Slots : Holds(s, p, i, n)

\* RivalOf: the reaction in slot s is a rival of a call carrying the triple:
\* held, carrying the call's pair and a reaction name other than the call's
\* (Term rival). The checks read this.
RivalOf(s, p, i, n) ==
    Recorded(s) /\ per[s] = p /\ itm[s] = i /\ nm[s] # n /\ st[s] = "held"

\* TypeOK: each variable holds a value of its kind (the model's typing, not a
\* rule of the page).
TypeOK ==
    /\ per \in [Slots -> PersonIn \cup {NoRef}]
    /\ itm \in [Slots -> ItemIn \cup {NoRef}]
    /\ nm \in [Slots -> NameIn \cup {NoRef}]
    /\ fri \in [Slots -> 0..MaxTime]
    /\ st \in [Slots -> {"none", "held", "withdrawn"}]
    /\ rule \in HoldingRules
    /\ rset \in ReactionSets
    /\ last.op \in {"none", "react", "withdraw", "look_up", "count", "declare"}
    /\ last.p \in PersonIn \cup {NoRef}
    /\ last.i \in ItemIn \cup {NoRef}
    /\ last.n \in NameIn \cup {NoRef}
    /\ last.ans \in STRING
    /\ DOMAIN last.out = 1..Cardinality(DOMAIN last.out)
    /\ DOMAIN last.tal = 1..Cardinality(DOMAIN last.tal)
    /\ wrote \subseteq Slots

\* Init: no reaction; the deployment declares one of the holding rules and
\* one of the reaction sets (a deployment that declares none takes
\* one-per-item and {like}, both among them).
Init ==
    /\ per = [s \in Slots |-> NoRef]
    /\ itm = [s \in Slots |-> NoRef]
    /\ nm = [s \in Slots |-> NoRef]
    /\ fri = [s \in Slots |-> 0]
    /\ st = [s \in Slots |-> "none"]
    /\ rule \in HoldingRules
    /\ rset \in ReactionSets
    /\ last = NoCall
    /\ wrote = {}

\* ---------------------------------------------------------------------------
\* Actions
\* ---------------------------------------------------------------------------

\* PersonBad, ItemBad, NameBad: the refusals' grounds: a value blank, over
\* the string cap, or not a string (Operation 1 to 3, 23 to 25).
PersonBad(x) == BlankOrOverCap(x) \/ NotAString(x)
ItemBad(x) == BlankOrOverCap(x) \/ NotAString(x)
NameBad(x) == BlankOrOverCap(x) \/ NotAString(x)

\* ReactAdmits, WithdrawAdmits: no refusal applies to the call. Only
\* [React] reads the reaction set (Operation 4).
ReactAdmits(p, i, n) == ~PersonBad(p) /\ ~ItemBad(i) /\ ~NameBad(n) /\ n \in rset
WithdrawAdmits(p, i, n) == ~PersonBad(p) /\ ~ItemBad(i) /\ ~NameBad(n)

\* Refusal: the refusal listed first on the refuses line that applies
\* (Execution Contract Refusal 1): the person reference's, then the item
\* reference's, then the reaction name's, a name outside the reaction set
\* included (Operation 4).
Refusal(p, i) ==
    IF PersonBad(p) THEN "invalid-person-reference"
    ELSE IF ItemBad(i) THEN "invalid-item-reference"
    ELSE "invalid-reaction-name"

\* Called: the record of a writing call and what it answered.
Called(op, p, i, n, a) == [NoCall EXCEPT !.op = op, !.p = p, !.i = i, !.n = n, !.ans = a]

\* Replaced: the slots an admitted [React] stands in withdrawn: under
\* one-per-item, every held reaction carrying the call's pair and another
\* reaction name (Operation 10); under one-of-each, none (Operation 11).
Replaced(p, i, n) ==
    {}                                                          \* BUG: no rival withdrawn

\* ReactRefused: a [React] some refusal applies to answers it and writes
\* nothing (Operation 1 to 4, 23 to 25).
ReactRefused(p, i, n) ==
    /\ ~ReactAdmits(p, i, n)
    /\ last' = Called("react", p, i, n, Refusal(p, i))
    /\ wrote' = {}
    /\ UNCHANGED <<records, deployment>>

\* ReactRecords: an admitted [React] on a triple with no reaction records one
\* reaction carrying the triple (Operation 5), its first reacted instant the
\* injected now t (Operation 6), standing in held (Operation 7); under
\* one-per-item it stands every rival in withdrawn in the same step
\* (Operation 10); it answers ok (Operation 12).
ReactRecords(p, i, n, t) ==
    /\ ReactAdmits(p, i, n)
    /\ ~Exists(p, i, n)
    /\ LET own == <<p, i, n>>
           gone == Replaced(p, i, n)
       IN /\ per' = [per EXCEPT ![own] = p]
          /\ itm' = [itm EXCEPT ![own] = i]
          /\ nm' = [nm EXCEPT ![own] = n]
          /\ fri' = [fri EXCEPT ![own] = t]
          /\ st' = [s \in Slots |-> IF s = own THEN "held"
                                    ELSE IF s \in gone THEN "withdrawn" ELSE st[s]]
          /\ wrote' = {own} \cup gone
    /\ last' = Called("react", p, i, n, "ok")
    /\ UNCHANGED deployment

\* ReactReholds: an admitted [React] on the triple's withdrawn reaction stands
\* it in held (Operation 8), its first reacted instant standing (the case
\* table, Invariant 2.1); under one-per-item it stands every rival in
\* withdrawn (Operation 10); it answers ok (Operation 12). The now t is
\* given; nothing reads it.
ReactReholds(p, i, n, t) ==
    /\ ReactAdmits(p, i, n)
    /\ \E s \in Slots :
         /\ Holds(s, p, i, n)
         /\ st[s] = "withdrawn"
         /\ LET gone == Replaced(p, i, n)
            IN /\ st' = [x \in Slots |-> IF x = s THEN "held"
                                         ELSE IF x \in gone THEN "withdrawn" ELSE st[x]]
               /\ wrote' = {s} \cup gone
    /\ last' = Called("react", p, i, n, "ok")
    /\ UNCHANGED <<per, itm, nm, fri, deployment>>

\* ReactHeld: an admitted [React] on the triple's held reaction leaves it as
\* it is (Operation 9); under one-per-item any rival still held stands
\* withdrawn (Operation 10, the case table); it answers ok (Operation 12):
\* the slow connection's second thanks.
ReactHeld(p, i, n) ==
    /\ ReactAdmits(p, i, n)
    /\ \E s \in Slots : Holds(s, p, i, n) /\ st[s] = "held"
    /\ LET gone == Replaced(p, i, n)
       IN /\ st' = [x \in Slots |-> IF x \in gone THEN "withdrawn" ELSE st[x]]
          /\ wrote' = gone
    /\ last' = Called("react", p, i, n, "ok")
    /\ UNCHANGED <<per, itm, nm, fri, deployment>>

\* WithdrawRefused: a [Withdraw] some refusal applies to answers it and writes
\* nothing (Operation 1 to 3, 23 to 25).
WithdrawRefused(p, i, n) ==
    /\ ~WithdrawAdmits(p, i, n)
    /\ last' = Called("withdraw", p, i, n, Refusal(p, i))
    /\ wrote' = {}
    /\ UNCHANGED <<records, deployment>>

\* WithdrawWithdraws: an admitted [Withdraw] on the triple's held reaction
\* stands it in withdrawn, removing nothing (Operation 13, State 3), and
\* answers ok (Operation 16).
WithdrawWithdraws(p, i, n) ==
    /\ WithdrawAdmits(p, i, n)
    /\ \E s \in Slots :
         /\ Holds(s, p, i, n)
         /\ st[s] = "held"
         /\ st' = [st EXCEPT ![s] = "withdrawn"]
         /\ wrote' = {s}
    /\ last' = Called("withdraw", p, i, n, "ok")
    /\ UNCHANGED <<per, itm, nm, fri, deployment>>

\* WithdrawWithdrawn: an admitted [Withdraw] on the triple's withdrawn
\* reaction writes nothing (Operation 14) and answers ok (Operation 16).
WithdrawWithdrawn(p, i, n) ==
    /\ WithdrawAdmits(p, i, n)
    /\ \E s \in Slots : Holds(s, p, i, n) /\ st[s] = "withdrawn"
    /\ wrote' = {}
    /\ last' = Called("withdraw", p, i, n, "ok")
    /\ UNCHANGED <<records, deployment>>

\* WithdrawUnknown: an admitted [Withdraw] on a triple with no reaction writes
\* nothing (Operation 15) and answers ok (Operation 16), as
\* withdraw("ana", "post-41", "angry") where ana holds no angry. The now t is
\* given; nothing reads it.
WithdrawUnknown(p, i, n, t) ==
    /\ WithdrawAdmits(p, i, n)
    /\ ~Exists(p, i, n)
    /\ wrote' = {}
    /\ last' = Called("withdraw", p, i, n, "ok")
    /\ UNCHANGED <<records, deployment>>

\* HeldNames: the reaction name of every held reaction carrying the pair
\* (Operation 17, the term Look Up).
HeldNames(p, i) ==
    {nm[s] : s \in {r \in Slots : Recorded(r) /\ per[r] = p /\ itm[r] = i /\ st[r] = "held"}}

\* SortNames: the names as a list, each placed after every name of lower
\* code point order (Operation 29).
SortNames(S) == [k \in 1..Cardinality(S) |->
                   CHOOSE e \in S : Cardinality({x \in S : Rank(x) < Rank(e)}) = k - 1]

\* LookUpBad: a [Look Up] whose person reference or item reference is blank,
\* over the string cap or not a string answers an empty list (Operation 26,
\* 27) and writes nothing (Operation 19).
LookUpBad(p, i) ==
    /\ (PersonBad(p) \/ ItemBad(i))
    /\ last' = [Called("look_up", p, i, NoRef, "reaction_names") EXCEPT !.out = NoNames]
    /\ wrote' = {}
    /\ UNCHANGED <<records, deployment>>

\* LookUpGood: a [Look Up] of a well-formed pair answers the reaction name of
\* every held reaction carrying it, in code point order, an empty list where
\* none is held (Operation 17, 18, 29), and writes nothing (Operation 19).
LookUpGood(p, i) ==
    /\ ~PersonBad(p) /\ ~ItemBad(i)
    /\ last' = [Called("look_up", p, i, NoRef, "reaction_names")
                  EXCEPT !.out = SortNames(HeldNames(p, i))]
    /\ wrote' = {}
    /\ UNCHANGED <<records, deployment>>

\* HeldOn: the reaction name of every held reaction carrying the item
\* reference (Operation 20, the term Count).
HeldOn(i) == {nm[s] : s \in {r \in Slots : st[r] = "held" /\ itm[r] = i}}

\* Tallies: each name held on the item with its tally, the number of held
\* reactions carrying the item reference and the name (Term tally), in code
\* point order of reaction name (Operation 30).
Tallies(i) ==
    LET S == HeldOn(i)
    IN [k \in 1..Cardinality(S) |->
          LET e == CHOOSE x \in S : Cardinality({y \in S : Rank(y) < Rank(x)}) = k - 1
          IN [name |-> e,
              tally |-> Cardinality({r \in Slots : st[r] = "held" /\ itm[r] = i /\ nm[r] = e})]]

\* CountBad: a [Count] whose item reference is blank, over the string cap or
\* not a string answers an empty list (Operation 28) and writes nothing
\* (Operation 22).
CountBad(i) ==
    /\ ItemBad(i)
    /\ last' = [Called("count", NoRef, i, NoRef, "tallies") EXCEPT !.tal = NoTallies]
    /\ wrote' = {}
    /\ UNCHANGED <<records, deployment>>

\* CountGood: a [Count] of a well-formed item reference answers each name
\* held on it with its tally, in code point order, an empty list where none
\* is held (Operation 20, 21, 30), and writes nothing (Operation 22).
CountGood(i) ==
    /\ ~ItemBad(i)
    /\ last' = [Called("count", NoRef, i, NoRef, "tallies") EXCEPT !.tal = Tallies(i)]
    /\ wrote' = {}
    /\ UNCHANGED <<records, deployment>>

\* Declare: the deployment declares a holding rule and a reaction set, the
\* same or others, between two calls (Capability requirement 7, 8; the Edge
\* case "A reaction set or a holding rule that changes"); no reaction is
\* written.
Declare(r, R) ==
    /\ rule' = r
    /\ rset' = R
    /\ last' = [NoCall EXCEPT !.op = "declare"]
    /\ wrote' = {}
    /\ UNCHANGED records

\* Next: any call of the four actions, admitted or refused as the page says,
\* or a declaration of the deployment.
Next ==
    \/ \E p \in PersonIn, i \in ItemIn, n \in NameIn : ReactRefused(p, i, n)
    \/ \E p \in PersonIn, i \in ItemIn, n \in NameIn, t \in Times : ReactRecords(p, i, n, t)
    \/ \E p \in PersonIn, i \in ItemIn, n \in NameIn, t \in Times : ReactReholds(p, i, n, t)
    \/ \E p \in PersonIn, i \in ItemIn, n \in NameIn : ReactHeld(p, i, n)
    \/ \E p \in PersonIn, i \in ItemIn, n \in NameIn : WithdrawRefused(p, i, n)
    \/ \E p \in PersonIn, i \in ItemIn, n \in NameIn : WithdrawWithdraws(p, i, n)
    \/ \E p \in PersonIn, i \in ItemIn, n \in NameIn : WithdrawWithdrawn(p, i, n)
    \/ \E p \in PersonIn, i \in ItemIn, n \in NameIn, t \in Times : WithdrawUnknown(p, i, n, t)
    \/ \E p \in PersonIn, i \in ItemIn : LookUpBad(p, i)
    \/ \E p \in PersonIn, i \in ItemIn : LookUpGood(p, i)
    \/ \E i \in ItemIn : CountBad(i)
    \/ \E i \in ItemIn : CountGood(i)
    \/ \E r \in HoldingRules, R \in ReactionSets : Declare(r, R)

\* Spec: every behaviour from Init by Next steps.
Spec == Init /\ [][Next]_vars

\* ---------------------------------------------------------------------------
\* Checks (the verification surface). Every check is an action property, so
\* the VIEW drops no step it reads (see the header).
\* ---------------------------------------------------------------------------

\* ReactCall, WithdrawCall: the step is a [React] or a [Withdraw] call whose
\* three values are well-formed; ReactIn also has the reaction set offer the
\* name, so no refusal applies (Operation 1 to 4, 23 to 25).
WellFormedCall(op) ==
    /\ last'.op = op
    /\ WellFormed(last'.p) /\ WellFormed(last'.i) /\ WellFormed(last'.n)
ReactIn == WellFormedCall("react") /\ last'.n \in rset
WithdrawIn == WellFormedCall("withdraw")

\* WroteNothing: the step wrote no reaction and changed no field of any.
WroteNothing == wrote' = {} /\ UNCHANGED records

\* Unchanged: no field of the reaction in slot s changed in the step.
Unchanged(s) ==
    /\ per'[s] = per[s] /\ itm'[s] = itm[s] /\ nm'[s] = nm[s]
    /\ fri'[s] = fri[s] /\ st'[s] = st[s]

\* State3_NeverRemoved: no step removes a reaction, a withdrawn one included:
\* taking a reaction back keeps it (State 3).
State3_NeverRemoved ==
    [][\A s \in Slots : st[s] # "none" => st'[s] # "none"]_vars

\* Inv2_1_FirstReactedKept: no step changes a reaction's first reacted
\* instant, so a reaction held again keeps it (Invariant 2.1).
Inv2_1_FirstReactedKept ==
    [][\A s \in Slots : st[s] # "none" => fri'[s] = fri[s]]_vars

\* Inv2_2_PersonKept: no step changes a reaction's person reference
\* (Invariant 2.2).
Inv2_2_PersonKept ==
    [][\A s \in Slots : st[s] # "none" => per'[s] = per[s]]_vars

\* Inv2_3_ItemKept: no step changes a reaction's item reference (Invariant
\* 2.3).
Inv2_3_ItemKept ==
    [][\A s \in Slots : st[s] # "none" => itm'[s] = itm[s]]_vars

\* Inv2_4_NameKept: no step changes a reaction's reaction name: love chosen
\* after like is a second reaction, not like renamed (Invariant 2.4).
Inv2_4_NameKept ==
    [][\A s \in Slots : st[s] # "none" => nm'[s] = nm[s]]_vars

\* Op1_BlankOrLongPersonRefused: a [React] or a [Withdraw] whose person
\* reference is blank or over the string cap answers invalid-person-reference
\* and writes nothing, whatever else it carries: react("", "", "") answers
\* the person's refusal (Operation 1, Execution Contract Refusal 1).
Op1_BlankOrLongPersonRefused ==
    [][(last'.op \in Writing /\ BlankOrOverCap(last'.p))
         => (last'.ans = "invalid-person-reference" /\ WroteNothing)]_vars

\* Op2_BlankOrLongItemRefused: a [React] or a [Withdraw] whose person
\* reference is well-formed and whose item reference is blank or over the
\* string cap answers invalid-item-reference and writes nothing:
\* react("ana", "   ", "like") (Operation 2).
Op2_BlankOrLongItemRefused ==
    [][(last'.op \in Writing /\ WellFormed(last'.p) /\ BlankOrOverCap(last'.i))
         => (last'.ans = "invalid-item-reference" /\ WroteNothing)]_vars

\* Op3_BlankOrLongNameRefused: a [React] or a [Withdraw] whose two references
\* are well-formed and whose reaction name is blank or over the string cap
\* answers invalid-reaction-name and writes nothing (Operation 3).
Op3_BlankOrLongNameRefused ==
    [][(last'.op \in Writing /\ WellFormed(last'.p) /\ WellFormed(last'.i)
            /\ BlankOrOverCap(last'.n))
         => (last'.ans = "invalid-reaction-name" /\ WroteNothing)]_vars

\* Op4_NameOutsideSetRefused: a [React] whose three values are well-formed
\* and whose reaction name the reaction set does not offer, compared
\* codepoint for codepoint, answers invalid-reaction-name and writes nothing:
\* react("ana", "post-41", "Like") where the set holds like, and a repeat on
\* a reaction already held in a name the deployment dropped (Operation 4,
\* Identity 7, the Edge case on a changing reaction set).
Op4_NameOutsideSetRefused ==
    [][(WellFormedCall("react") /\ last'.n \notin rset)
         => (last'.ans = "invalid-reaction-name" /\ WroteNothing)]_vars

\* Op5_ReactRecordsOne: an admitted [React] of a triple no reaction carries
\* records exactly one new reaction carrying that triple (Operation 5).
Op5_ReactRecordsOne ==
    [][(ReactIn /\ ~(\E s \in Slots : st[s] # "none" /\ per[s] = last'.p
                                      /\ itm[s] = last'.i /\ nm[s] = last'.n))
         => Cardinality({s \in Slots : st[s] = "none" /\ st'[s] # "none" /\ per'[s] = last'.p
                                       /\ itm'[s] = last'.i /\ nm'[s] = last'.n}) = 1]_vars

\* Op8_ReactReholds: an admitted [React] of a triple whose reaction stands
\* withdrawn leaves it held: love chosen again (Operation 8).
Op8_ReactReholds ==
    [][ReactIn => \A s \in Slots : (Holds(s, last'.p, last'.i, last'.n) /\ st[s] = "withdrawn")
                                     => st'[s] = "held"]_vars

\* Op9_HeldReactChangesNothing: an admitted [React] of a triple whose
\* reaction stands held leaves that reaction as it is: a double tap never
\* takes a reaction back (Operation 9).
Op9_HeldReactChangesNothing ==
    [][ReactIn => \A s \in Slots : (Holds(s, last'.p, last'.i, last'.n) /\ st[s] = "held")
                                     => Unchanged(s)]_vars

\* Op10_OnePerItemWithdrawsRivals: under one-per-item an admitted [React]
\* stands every rival in withdrawn: ana's like stands withdrawn when she
\* chooses love, and every reaction she held under one-of-each before the
\* deployment moved goes at her next [React] on the item (Operation 10).
Op10_OnePerItemWithdrawsRivals ==
    [][(ReactIn /\ rule = "one-per-item")
         => \A s \in Slots : RivalOf(s, last'.p, last'.i, last'.n) => st'[s] = "withdrawn"]_vars

\* Op11_OneOfEachKeepsRivals: under one-of-each an admitted [React] changes
\* no rival: r7's thanks stays when r7 adds eyes (Operation 11).
Op11_OneOfEachKeepsRivals ==
    [][(ReactIn /\ rule = "one-of-each")
         => \A s \in Slots : RivalOf(s, last'.p, last'.i, last'.n) => Unchanged(s)]_vars

\* Op12_ReactAnswersOk: a [React] no refusal applies to answers ok, whatever
\* it found (Operation 12, Execution Contract Read 4).
Op12_ReactAnswersOk ==
    [][ReactIn => last'.ans = "ok"]_vars

\* Op13_WithdrawWithdraws: an admitted [Withdraw] of a triple whose reaction
\* stands held leaves it withdrawn, a name the deployment has since dropped
\* included (Operation 13, the Edge case on a changing reaction set).
Op13_WithdrawWithdraws ==
    [][WithdrawIn => \A s \in Slots : (Holds(s, last'.p, last'.i, last'.n) /\ st[s] = "held")
                                        => st'[s] = "withdrawn"]_vars

\* Op14_WithdrawnWithdrawWritesNothing: an admitted [Withdraw] of a triple
\* whose reaction stands withdrawn writes nothing (Operation 14).
Op14_WithdrawnWithdrawWritesNothing ==
    [][(WithdrawIn /\ \E s \in Slots : Holds(s, last'.p, last'.i, last'.n) /\ st[s] = "withdrawn")
         => WroteNothing]_vars

\* Op15_UnknownWithdrawWritesNothing: an admitted [Withdraw] of a triple no
\* reaction carries writes nothing: withdraw("ana", "post-41", "angry")
\* (Operation 15).
Op15_UnknownWithdrawWritesNothing ==
    [][(WithdrawIn /\ ~(\E s \in Slots : Holds(s, last'.p, last'.i, last'.n)))
         => WroteNothing]_vars

\* Op16_WithdrawAnswersOk: a [Withdraw] no refusal applies to answers ok,
\* whatever it found, in a name outside the reaction set included
\* (Operation 16).
Op16_WithdrawAnswersOk ==
    [][WithdrawIn => last'.ans = "ok"]_vars

\* Op17_LookUpAnswersEveryHeld: a [Look Up] of a well-formed pair answers the
\* reaction name of every held reaction carrying it (Operation 17).
Op17_LookUpAnswersEveryHeld ==
    [][(last'.op = "look_up" /\ WellFormed(last'.p) /\ WellFormed(last'.i))
         => \A s \in Slots : (st[s] = "held" /\ per[s] = last'.p /\ itm[s] = last'.i)
                               => \E k \in DOMAIN last'.out : last'.out[k] = nm[s]]_vars

\* LookUpTerm_OnlyHeld: every name a [Look Up] answers is that of a held
\* reaction carrying the pair it was given: look_up("r7", "msg-9") answers
\* eyes and thanks and nothing else (the term Look Up: "every reaction one
\* person holds on one item now"; the team chat).
LookUpTerm_OnlyHeld ==
    [][last'.op = "look_up"
         => \A k \in DOMAIN last'.out :
              \E s \in Slots : st[s] = "held" /\ per[s] = last'.p /\ itm[s] = last'.i
                               /\ nm[s] = last'.out[k]]_vars

\* Op18_LookUpEmptyForNone: a [Look Up] of a well-formed pair no held
\* reaction carries answers an empty list (Operation 18).
Op18_LookUpEmptyForNone ==
    [][(last'.op = "look_up" /\ WellFormed(last'.p) /\ WellFormed(last'.i)
            /\ ~(\E s \in Slots : st[s] = "held" /\ per[s] = last'.p /\ itm[s] = last'.i))
         => (last'.ans = "reaction_names" /\ last'.out = NoNames)]_vars

\* Op19_LookUpWritesNothing: a [Look Up] step writes no reaction and changes
\* no field of any (Operation 19).
Op19_LookUpWritesNothing ==
    [][last'.op = "look_up" => WroteNothing]_vars

\* Op20_CountAnswersEveryHeldName: a [Count] of a well-formed item reference
\* answers every reaction name a held reaction carrying it carries, with its
\* tally, the number of held reactions carrying the item and the name: like
\* with a tally of 2 where ana and Ana both hold like (Operation 20, Term
\* tally).
Op20_CountAnswersEveryHeldName ==
    [][(last'.op = "count" /\ WellFormed(last'.i))
         => \A s \in Slots : (st[s] = "held" /\ itm[s] = last'.i)
              => \E k \in DOMAIN last'.tal :
                   /\ last'.tal[k].name = nm[s]
                   /\ last'.tal[k].tally
                        = Cardinality({r \in Slots : st[r] = "held" /\ itm[r] = last'.i
                                                     /\ nm[r] = nm[s]})]_vars

\* CountTerm_OnlyHeldNames: every name a [Count] answers is held on the item
\* it was given: after ana replaces like with love, count("post-41") answers
\* love "and no like" (the term Count: "each [Reaction Name] held on it";
\* the forum).
CountTerm_OnlyHeldNames ==
    [][last'.op = "count"
         => \A k \in DOMAIN last'.tal :
              \E s \in Slots : st[s] = "held" /\ itm[s] = last'.i /\ nm[s] = last'.tal[k].name]_vars

\* Op21_CountEmptyForNone: a [Count] of a well-formed item reference no held
\* reaction carries answers an empty list: count("post-41") once love is
\* taken back (Operation 21).
Op21_CountEmptyForNone ==
    [][(last'.op = "count" /\ WellFormed(last'.i)
            /\ ~(\E s \in Slots : st[s] = "held" /\ itm[s] = last'.i))
         => (last'.ans = "tallies" /\ last'.tal = NoTallies)]_vars

\* Op22_CountWritesNothing: a [Count] step writes no reaction and changes no
\* field of any (Operation 22).
Op22_CountWritesNothing ==
    [][last'.op = "count" => WroteNothing]_vars

\* Op23_MalformedPersonRefused: a [React] or a [Withdraw] whose person
\* reference is not a string answers invalid-person-reference and writes
\* nothing: react(42, "post-41", "like") (Operation 23).
Op23_MalformedPersonRefused ==
    [][(last'.op \in Writing /\ NotAString(last'.p))
         => (last'.ans = "invalid-person-reference" /\ WroteNothing)]_vars

\* Op24_MalformedItemRefused: a [React] or a [Withdraw] whose person reference
\* is well-formed and whose item reference is not a string answers
\* invalid-item-reference and writes nothing (Operation 24).
Op24_MalformedItemRefused ==
    [][(last'.op \in Writing /\ WellFormed(last'.p) /\ NotAString(last'.i))
         => (last'.ans = "invalid-item-reference" /\ WroteNothing)]_vars

\* Op25_MalformedNameRefused: a [React] or a [Withdraw] whose two references
\* are well-formed and whose reaction name is not a string answers
\* invalid-reaction-name and writes nothing (Operation 25).
Op25_MalformedNameRefused ==
    [][(last'.op \in Writing /\ WellFormed(last'.p) /\ WellFormed(last'.i) /\ NotAString(last'.n))
         => (last'.ans = "invalid-reaction-name" /\ WroteNothing)]_vars

\* Op26_LookUpBadPersonEmpty: a [Look Up] whose person reference is blank,
\* over the string cap or not a string answers an empty list (Operation 26).
Op26_LookUpBadPersonEmpty ==
    [][(last'.op = "look_up" /\ ~WellFormed(last'.p))
         => (last'.ans = "reaction_names" /\ last'.out = NoNames)]_vars

\* Op27_LookUpBadItemEmpty: a [Look Up] whose item reference is blank, over
\* the string cap or not a string answers an empty list (Operation 27).
Op27_LookUpBadItemEmpty ==
    [][(last'.op = "look_up" /\ ~WellFormed(last'.i))
         => (last'.ans = "reaction_names" /\ last'.out = NoNames)]_vars

\* Op28_CountBadItemEmpty: a [Count] whose item reference is blank, over the
\* string cap or not a string answers an empty list: count("") (Operation
\* 28).
Op28_CountBadItemEmpty ==
    [][(last'.op = "count" /\ ~WellFormed(last'.i))
         => (last'.ans = "tallies" /\ last'.tal = NoTallies)]_vars

\* Op29_LookUpOrder: each name of a [Look Up] answer comes before the next in
\* code point order: like before love (Operation 29, Execution Contract
\* Logic confinement 10).
Op29_LookUpOrder ==
    [][last'.op = "look_up"
         => \A k \in DOMAIN last'.out :
              (k + 1 \in DOMAIN last'.out) => Rank(last'.out[k]) < Rank(last'.out[k + 1])]_vars

\* Op30_CountOrder: each entry of a [Count] answer comes before the next in
\* code point order of reaction name (Operation 30).
Op30_CountOrder ==
    [][last'.op = "count"
         => \A k \in DOMAIN last'.tal :
              (k + 1 \in DOMAIN last'.tal)
                => Rank(last'.tal[k].name) < Rank(last'.tal[k + 1].name)]_vars

====
