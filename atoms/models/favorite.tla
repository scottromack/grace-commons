---- MODULE favorite ----
\* Grace Commons — Favorite atom (atoms/favorite.md).
\* Grounded on Final Critique 2, 2026-11-14 at f823313 — TLA+ layer authored 2026-11-14.
\* Derived validator; the English spec is the single source of truth. On any
\* disagreement, diagnose per the entry *The conflict protocol* in pressure-testing.md.
\*
\* PURPOSE
\* Check what happens across steps: the favorites [Mark] and [Unmark] write
\* over a sequence of calls, what each of the four actions answers, which
\* calls write nothing, and the order [List] answers in. What one state of the
\* records must carry (State 1, 2, Identity 3, 5, Operation 3's fields, 4, 5,
\* Invariant 1.1) is the Alloy model's, favorite.als; the two models spell the
\* page's terms alike (favorite, pair, person reference, item reference, first
\* marked instant, status, marked, unmarked).
\*
\* RULES CHECKED (named by the page's own labels)
\*   State 3       — the atom never removes a favorite             (State3_NeverRemoved)
\*   Invariant 2.1 — a first marked instant never changes          (Inv2_1_FirstMarkedKept)
\*   Invariant 2.2 — a person reference never changes              (Inv2_2_PersonKept)
\*   Invariant 2.3 — an item reference never changes               (Inv2_3_ItemKept)
\*   Operation 1   — a blank person reference, or one over the
\*                   string cap, is refused                         (Op1_BlankOrLongPersonRefused)
\*   Operation 2   — the same for an item reference                 (Op2_BlankOrLongItemRefused)
\*   Operation 3   — [Mark] on a pair with no favorite records
\*                   exactly one favorite carrying the pair         (Op3_MarkRecordsOne)
\*   Operation 6   — [Mark] stands an unmarked favorite in marked   (Op6_MarkRemarks)
\*   Operation 7   — [Mark] on a marked favorite writes nothing     (Op7_MarkedMarkWritesNothing)
\*   Operation 8   — [Mark] answers ok                              (Op8_MarkAnswersOk)
\*   Operation 9   — [Unmark] stands a marked favorite in unmarked  (Op9_UnmarkUnmarks)
\*   Operation 10  — [Unmark] on an unmarked favorite writes nothing
\*                                                                  (Op10_UnmarkedUnmarkWritesNothing)
\*   Operation 11  — [Unmark] on a pair with no favorite writes
\*                   nothing                                        (Op11_UnknownUnmarkWritesNothing)
\*   Operation 12  — [Unmark] answers ok                            (Op12_UnmarkAnswersOk)
\*   Operation 13  — [Look Up] answers exactly one of marked,
\*                   unmarked                                       (Op13_LookUpAnswersOne)
\*   Operation 14  — [Look Up] answers marked only if a marked
\*                   favorite exists for the pair                   (Op14_LookUpMarkedOnlyIfMarked)
\*                   and, by the term Look Up and the case table, a
\*                   marked favorite answers marked                 (LookUpTerm_MarkedAnswersMarked)
\*   Operation 15  — [Look Up] writes nothing                       (Op15_LookUpWritesNothing)
\*   Operation 16  — [List] answers every marked favorite of the
\*                   person                                         (Op16_ListAnswersEveryMarked)
\*                   and, by the term List, only those              (ListTerm_OnlyThePersonsMarked)
\*   Operation 17  — [List] answers each one's item reference and
\*                   first marked instant                           (Op17_ListAnswersItemAndInstant)
\*   Operation 18  — [List] answers an empty list where the person
\*                   keeps no marked favorite                       (Op18_ListEmptyForNone)
\*   Operation 19  — [List] writes nothing                          (Op19_ListWritesNothing)
\*   Operation 20  — a person reference that is not a string is
\*                   refused                                        (Op20_MalformedPersonRefused)
\*   Operation 21  — the same for an item reference                 (Op21_MalformedItemRefused)
\*   Operation 22  — [Look Up] with a bad person reference answers
\*                   unmarked                                       (Op22_LookUpBadPersonUnmarked)
\*   Operation 23  — the same for a bad item reference              (Op23_LookUpBadItemUnmarked)
\*   Operation 24  — [List] with a bad person reference answers an
\*                   empty list                                     (Op24_ListBadPersonEmpty)
\*   Operation 25  — [List] answers by first marked instant,
\*                   earliest first, then by item reference         (Op25_ListOrder)
\* Each refusal check also reads the case table's effect, none: a refused
\* call writes nothing (Execution Contract Read 4). Operation 2 and 21 hold
\* only where no person refusal applies (Execution Contract Refusal 1), and
\* Operation 8 and 12 only for a call the action admits (Execution Contract
\* Read 4), as `mark("", "")` answers [Invalid Person Reference].
\*
\* WHAT THE MODEL TAKES FROM OUTSIDE THE PAGE (its inputs; no ASSUME)
\* - The seam: each call carries what its caller sent, a well-formed
\*   reference or a bad one, and is given a clock reading now in Times
\*   (Capability requirement 2). No rule here turns on the order of two
\*   readings, so a reading may come in any order.
\* - The database (Execution Contract Database 1, 2): each call's guards and
\*   writes are one atomic step, so two calls on one pair, concurrent ones
\*   included, are two steps in some order (the Edge case "Concurrency").
\*
\* BOUNDS (the .cfg)
\* Two person references, ana and Ana, and two item references, kettle-blue
\* and Kettle-Blue: each pair of a case variant differs only in case, so a
\* comparison that folds case shows; four pairs a favorite can carry. A bad
\* reference of each
\* kind on each side: a blank one ("   ", whitespace only, the rejection
\* paths'), one standing for a string over the string cap, and one standing
\* for a value that is not a string (42). Two clock readings, so two
\* favorites can share a first marked instant (the order's second key) or
\* differ in it (its first key). No CONSTRAINT: the space is finite.
\*
\* NOT MODELED HERE
\* - Storage failure and the failed read (Execution Contract Database 3, Read
\*   1, 3): a write that did not commit leaves nothing.
\* - The string cap's value (Capability requirement 3): a reference over it
\*   is a token here; no rule turns on its size.
\* - Normalizing at the seam (Capability requirement 4, 5): the deployment's
\*   duty before the seam; the model takes each reference as carried.
\* - The versions the database keeps (Execution Contract Database 5): the
\*   Alloy model's; a state here is each favorite's latest version.
\* - Who may read or change a person's favorites, the catalog, availability,
\*   sharing, counting and save for later (Non-goal 1 to 8).
\* - Liveness: the page states no eventually-property (no rule that a call
\*   must be made or must answer in time), so the model checks safety only.

EXTENDS Integers, FiniteSets

CONSTANTS
    Persons,     \* the person references a call may carry that are well-formed
    Items,       \* the item references a call may carry that are well-formed
    Blanks,      \* blank strings a call may carry as either reference
    OverCaps,    \* tokens standing for strings over the string cap
    NotStrings,  \* tokens standing for values that are not strings, such as 42
    MaxTime      \* the clock's last reading

\* Times: the clock readings the seam may inject as now.
Times == 1..MaxTime

\* PersonIn, ItemIn: every value a call may carry as a person reference or
\* an item reference, well-formed or not.
PersonIn == Persons \cup Blanks \cup OverCaps \cup NotStrings
ItemIn == Items \cup Blanks \cup OverCaps \cup NotStrings

\* Slots: one slot for each pair a call may carry, where [Mark] records the
\* pair's favorite. A slot is the model's own name for a favorite, so a check
\* can ask whether its fields ever change; its fields are written by the
\* actions, never read off its name.
Slots == PersonIn \X ItemIn

\* Writing: the writing actions (Term writing action).
Writing == {"mark", "unmark"}

\* NoRef: a slot's reference before a favorite is recorded in it, and the
\* reference of a call that carries none.
NoRef == "none"

\* NoList: the empty list, and the list field of an answer that is no list.
NoList == [k \in {} |-> [item |-> NoRef, fmi |-> 0]]

\* NoCall: the record of the last call before any call is made, and the shape
\* of every such record: the action; the person reference and the item
\* reference it carried; what it answered; and the list [List] answered.
NoCall == [op |-> "none", p |-> NoRef, i |-> NoRef, ans |-> "none", out |-> NoList]

\* BlankOrOverCap, NotAString, WellFormed: what the page's refusals read of a
\* reference (Operation 1, 2, 20 to 24). The checks read these.
BlankOrOverCap(x) == x \in Blanks \/ x \in OverCaps
NotAString(x) == x \in NotStrings
WellFormed(x) == ~BlankOrOverCap(x) /\ ~NotAString(x)

\* Rank: the code point order of the item references (Execution Contract
\* Logic confinement 10): "Kettle-Blue" (K, U+004B) before "kettle-blue" (k,
\* U+006B). It ranks the Items of the .cfg and must be kept with them.
Rank(x) == CASE x = "Kettle-Blue" -> 1
             [] x = "kettle-blue" -> 2
             [] OTHER -> 3

\* Precedes: the order Operation 25 states for [List]'s answer: by first
\* marked instant, earliest first, then by item reference.
Precedes(a, b) == \/ a.fmi < b.fmi
                  \/ (a.fmi = b.fmi /\ Rank(a.item) < Rank(b.item))

\* Fold: what a case-folding comparison would make of a reference. The page
\* forbids it (Identity 2 to 5): the model's own actions never apply it; it
\* is here so a twin can.
Fold(x) == CASE x = "Ana" -> "ana"
             [] x = "Kettle-Blue" -> "kettle-blue"
             [] OTHER -> x

\* ---------------------------------------------------------------------------
\* State
\* ---------------------------------------------------------------------------

VARIABLES
    per,    \* slot -> the favorite's person reference (NoRef before it is recorded)
    itm,    \* slot -> the favorite's item reference (NoRef before it is recorded)
    fmi,    \* slot -> the favorite's first marked instant (0 before it is recorded)
    st,     \* slot -> the favorite's status ("none" before it is recorded)
    last,   \* the last call made and what it answered (NoCall's shape)
    wrote   \* the favorites the last step wrote

\* vars: every variable; a step that changes none of them is a stutter.
vars == <<per, itm, fmi, st, last, wrote>>

\* records: every variable that holds a favorite's fields.
records == <<per, itm, fmi, st>>

\* Recorded: a favorite stands in the slot.
Recorded(s) == st[s] # "none"

\* Holds: the favorite in slot s carries the pair, each reference compared
\* codepoint for codepoint (Term pair, Identity 3, 5).
Holds(s, p, i) == Recorded(s) /\ per[s] = p /\ itm[s] = i

\* Held: some favorite exists for the pair.
Held(p, i) == \E s \in Slots : Holds(s, p, i)

\* MarkedHeld: a marked favorite exists for the pair.
MarkedHeld(p, i) == \E s \in Slots : Holds(s, p, i) /\ st[s] = "marked"

\* TypeOK: each variable holds a value of its kind (the model's typing, not a
\* rule of the page).
TypeOK ==
    /\ per \in [Slots -> PersonIn \cup {NoRef}]
    /\ itm \in [Slots -> ItemIn \cup {NoRef}]
    /\ fmi \in [Slots -> 0..MaxTime]
    /\ st \in [Slots -> {"none", "marked", "unmarked"}]
    /\ last.op \in {"none", "mark", "unmark", "look_up", "list"}
    /\ last.p \in PersonIn \cup {NoRef}
    /\ last.i \in ItemIn \cup {NoRef}
    /\ last.ans \in STRING
    /\ DOMAIN last.out = 1..Cardinality(DOMAIN last.out)
    /\ wrote \subseteq Slots

\* Init: no favorite.
Init ==
    /\ per = [s \in Slots |-> NoRef]
    /\ itm = [s \in Slots |-> NoRef]
    /\ fmi = [s \in Slots |-> 0]
    /\ st = [s \in Slots |-> "none"]
    /\ last = NoCall
    /\ wrote = {}

\* ---------------------------------------------------------------------------
\* Actions
\* ---------------------------------------------------------------------------

\* PersonBad, ItemBad: the refusals' grounds: a reference blank, over the
\* string cap, or not a string (Operation 1, 2, 20, 21).
PersonBad(x) == BlankOrOverCap(x) \/ NotAString(x)
ItemBad(x) == BlankOrOverCap(x) \/ NotAString(x)

\* MarkAdmits, UnmarkAdmits: no refusal applies to the call.
MarkAdmits(p, i) == ~PersonBad(p) /\ ~ItemBad(i)
UnmarkAdmits(p, i) == ~PersonBad(p) /\ ~ItemBad(i)

\* Refusal: the refusal listed first on the refuses line that applies
\* (Execution Contract Refusal 1): the person reference's before the item
\* reference's.
Refusal(p) == IF PersonBad(p) THEN "invalid-person-reference" ELSE "invalid-item-reference"

\* MarkRefused: a [Mark] some refusal applies to answers it and writes
\* nothing (Operation 1, 2, 20, 21).
MarkRefused(p, i) ==
    /\ ~MarkAdmits(p, i)
    /\ last' = [NoCall EXCEPT !.op = "mark", !.p = p, !.i = i, !.ans = Refusal(p)]
    /\ wrote' = {}
    /\ UNCHANGED records

\* MarkRecords: an admitted [Mark] on a pair with no favorite records one
\* favorite carrying the pair (Operation 3), its first marked instant the
\* injected now t (Operation 4), standing in marked (Operation 5), and answers
\* ok (Operation 8).
MarkRecords(p, i, t) ==
    /\ MarkAdmits(p, i)
    /\ ~Held(p, i)
    /\ per' = [per EXCEPT ![<<p, i>>] = p]
    /\ itm' = [itm EXCEPT ![<<p, i>>] = i]
    /\ fmi' = [fmi EXCEPT ![<<p, i>>] = t]
    /\ st' = [st EXCEPT ![<<p, i>>] = "marked"]
    /\ wrote' = {<<p, i>>}
    /\ last' = [NoCall EXCEPT !.op = "mark", !.p = p, !.i = i, !.ans = "ok"]

\* MarkRemarks: an admitted [Mark] on the pair's unmarked favorite stands it
\* in marked (Operation 6), its first marked instant standing (the case
\* table), and answers ok (Operation 8). The now t is given; nothing reads it.
MarkRemarks(s, p, i, t) ==
    /\ MarkAdmits(p, i)
    /\ Holds(s, p, i)
    /\ st[s] = "unmarked"
    /\ st' = [st EXCEPT ![s] = "marked"]
    /\ wrote' = {s}
    /\ last' = [NoCall EXCEPT !.op = "mark", !.p = p, !.i = i, !.ans = "ok"]
    /\ UNCHANGED <<per, itm, fmi>>

\* MarkMarked: an admitted [Mark] on the pair's marked favorite writes nothing
\* (Operation 7) and answers ok (Operation 8): the slow connection's second
\* star.
MarkMarked(s, p, i) ==
    /\ MarkAdmits(p, i)
    /\ Holds(s, p, i)
    /\ st[s] = "marked"
    /\ wrote' = {}
    /\ last' = [NoCall EXCEPT !.op = "mark", !.p = p, !.i = i, !.ans = "ok"]
    /\ UNCHANGED records

\* UnmarkRefused: an [Unmark] some refusal applies to answers it and writes
\* nothing (Operation 1, 2, 20, 21).
UnmarkRefused(p, i) ==
    /\ ~UnmarkAdmits(p, i)
    /\ last' = [NoCall EXCEPT !.op = "unmark", !.p = p, !.i = i, !.ans = Refusal(p)]
    /\ wrote' = {}
    /\ UNCHANGED records

\* UnmarkUnmarks: an admitted [Unmark] on the pair's marked favorite stands it
\* in unmarked, removing nothing (Operation 9, State 3), and answers ok
\* (Operation 12).
UnmarkUnmarks(s, p, i) ==
    /\ UnmarkAdmits(p, i)
    /\ Holds(s, p, i)
    /\ st[s] = "marked"
    /\ st' = [st EXCEPT ![s] = "unmarked"]
    /\ wrote' = {s}
    /\ last' = [NoCall EXCEPT !.op = "unmark", !.p = p, !.i = i, !.ans = "ok"]
    /\ UNCHANGED <<per, itm, fmi>>

\* UnmarkUnmarked: an admitted [Unmark] on the pair's unmarked favorite writes
\* nothing (Operation 10) and answers ok (Operation 12).
UnmarkUnmarked(s, p, i) ==
    /\ UnmarkAdmits(p, i)
    /\ Holds(s, p, i)
    /\ st[s] = "unmarked"
    /\ wrote' = {}
    /\ last' = [NoCall EXCEPT !.op = "unmark", !.p = p, !.i = i, !.ans = "ok"]
    /\ UNCHANGED records

\* UnmarkUnknown: an admitted [Unmark] on a pair with no favorite writes
\* nothing (Operation 11) and answers ok (Operation 12), as
\* unmark("ana", "Kettle-Blue") where ana keeps kettle-blue. The now t is
\* given; nothing reads it.
UnmarkUnknown(p, i, t) ==
    /\ UnmarkAdmits(p, i)
    /\ ~Held(p, i)
    /\ wrote' = {}
    /\ last' = [NoCall EXCEPT !.op = "unmark", !.p = p, !.i = i, !.ans = "ok"]
    /\ UNCHANGED records

\* LookUpBad: a [Look Up] whose person reference or item reference is blank,
\* over the string cap or not a string answers unmarked (Operation 22, 23)
\* and writes nothing (Operation 15).
LookUpBad(p, i) ==
    /\ (PersonBad(p) \/ ItemBad(i))
    /\ last' = [NoCall EXCEPT !.op = "look_up", !.p = p, !.i = i, !.ans = "unmarked"]
    /\ wrote' = {}
    /\ UNCHANGED records

\* LookUpGood: a [Look Up] of a well-formed pair answers marked where a marked
\* favorite exists for it and unmarked otherwise, a pair with no favorite
\* included (Operation 13, 14, the term Look Up), and writes nothing
\* (Operation 15).
LookUpGood(p, i) ==
    /\ ~PersonBad(p) /\ ~ItemBad(i)
    /\ last' = [NoCall EXCEPT !.op = "look_up", !.p = p, !.i = i,
                              !.ans = IF MarkedHeld(p, i) THEN "marked" ELSE "unmarked"]
    /\ wrote' = {}
    /\ UNCHANGED records

\* Entries: the item reference and first marked instant of every marked
\* favorite carrying the person reference (Operation 16, 17, the term List).
Entries(p) == {[item |-> itm[s], fmi |-> fmi[s]] :
                 s \in {r \in Slots : Recorded(r) /\ per[r] = p /\ st[r] = "marked"}}

\* Before: the order [List] builds its answer in (Operation 25).
Before(a, b) == \/ a.fmi < b.fmi
                \/ (a.fmi = b.fmi /\ Rank(a.item) < Rank(b.item))

\* Sorted: the entries as a list, each placed after every entry Before it.
Sorted(S) == [k \in 1..Cardinality(S) |->
                CHOOSE e \in S : Cardinality({x \in S : Before(x, e)}) = k - 1]

\* ListBad: a [List] whose person reference is blank, over the string cap or
\* not a string answers an empty list (Operation 24) and writes nothing
\* (Operation 19).
ListBad(p) ==
    /\ PersonBad(p)
    /\ last' = [NoCall EXCEPT !.op = "list", !.p = p, !.ans = "ok", !.out = NoList]
    /\ wrote' = {}
    /\ UNCHANGED records

\* ListGood: a [List] of a well-formed person reference answers the person's
\* marked favorites, each one's item reference and first marked instant, in
\* Operation 25's order (Operation 16, 17, 18, 25), and writes nothing
\* (Operation 19).
ListGood(p) ==
    /\ ~PersonBad(p)
    /\ last' = [NoCall EXCEPT !.op = "list", !.p = p, !.ans = "ok", !.out = Sorted(Entries(p))]
    /\ wrote' = {}
    /\ UNCHANGED records

\* Next: any call of the four actions, admitted or refused as the page says.
Next ==
    \/ \E p \in PersonIn, i \in ItemIn : MarkRefused(p, i)
    \/ \E p \in PersonIn, i \in ItemIn, t \in Times : MarkRecords(p, i, t)
    \/ \E s \in Slots, p \in PersonIn, i \in ItemIn, t \in Times : MarkRemarks(s, p, i, t)
    \/ \E s \in Slots, p \in PersonIn, i \in ItemIn : MarkMarked(s, p, i)
    \/ \E p \in PersonIn, i \in ItemIn : UnmarkRefused(p, i)
    \/ \E s \in Slots, p \in PersonIn, i \in ItemIn : UnmarkUnmarks(s, p, i)
    \/ \E s \in Slots, p \in PersonIn, i \in ItemIn : UnmarkUnmarked(s, p, i)
    \/ \E p \in PersonIn, i \in ItemIn, t \in Times : UnmarkUnknown(p, i, t)
    \/ \E p \in PersonIn, i \in ItemIn : LookUpBad(p, i)
    \/ \E p \in PersonIn, i \in ItemIn : LookUpGood(p, i)
    \/ \E p \in PersonIn : ListBad(p)
    \/ \E p \in PersonIn : ListGood(p)

\* Spec: every behaviour from Init by Next steps.
Spec == Init /\ [][Next]_vars

\* ---------------------------------------------------------------------------
\* Checks (the verification surface)
\* ---------------------------------------------------------------------------

\* State3_NeverRemoved: no step removes a favorite, an unmarked one included:
\* emptying the heart keeps the favorite (State 3).
State3_NeverRemoved ==
    [][\A s \in Slots : st[s] # "none" => st'[s] # "none"]_vars

\* Inv2_1_FirstMarkedKept: no step changes a favorite's first marked instant,
\* so marking it again puts it back where it was (Invariant 2.1).
Inv2_1_FirstMarkedKept ==
    [][\A s \in Slots : st[s] # "none" => fmi'[s] = fmi[s]]_vars

\* Inv2_2_PersonKept: no step changes a favorite's person reference
\* (Invariant 2.2).
Inv2_2_PersonKept ==
    [][\A s \in Slots : st[s] # "none" => per'[s] = per[s]]_vars

\* Inv2_3_ItemKept: no step changes a favorite's item reference (Invariant
\* 2.3).
Inv2_3_ItemKept ==
    [][\A s \in Slots : st[s] # "none" => itm'[s] = itm[s]]_vars

\* Op1_BlankOrLongPersonRefused: a [Mark] or an [Unmark] whose person
\* reference is blank or over the string cap answers invalid-person-reference
\* and writes nothing, whatever its item reference: mark("", "") answers the
\* person's refusal (Operation 1, Execution Contract Refusal 1).
Op1_BlankOrLongPersonRefused ==
    [][(last'.op \in Writing /\ BlankOrOverCap(last'.p))
         => (last'.ans = "invalid-person-reference" /\ wrote' = {} /\ UNCHANGED records)]_vars

\* Op2_BlankOrLongItemRefused: a [Mark] or an [Unmark] whose person reference
\* is well-formed and whose item reference is blank or over the string cap
\* answers invalid-item-reference and writes nothing: mark("ana", "   ")
\* (Operation 2).
Op2_BlankOrLongItemRefused ==
    [][(last'.op \in Writing /\ WellFormed(last'.p) /\ BlankOrOverCap(last'.i))
         => (last'.ans = "invalid-item-reference" /\ wrote' = {} /\ UNCHANGED records)]_vars

\* Op20_MalformedPersonRefused: a [Mark] or an [Unmark] whose person
\* reference is not a string answers invalid-person-reference and writes
\* nothing: mark(42, "kettle-blue") (Operation 20).
Op20_MalformedPersonRefused ==
    [][(last'.op \in Writing /\ NotAString(last'.p))
         => (last'.ans = "invalid-person-reference" /\ wrote' = {} /\ UNCHANGED records)]_vars

\* Op21_MalformedItemRefused: a [Mark] or an [Unmark] whose person reference
\* is well-formed and whose item reference is not a string answers
\* invalid-item-reference and writes nothing (Operation 21).
Op21_MalformedItemRefused ==
    [][(last'.op \in Writing /\ WellFormed(last'.p) /\ NotAString(last'.i))
         => (last'.ans = "invalid-item-reference" /\ wrote' = {} /\ UNCHANGED records)]_vars

\* Op3_MarkRecordsOne: a [Mark] of a well-formed pair no favorite carries
\* records exactly one new favorite carrying that pair (Operation 3).
Op3_MarkRecordsOne ==
    [][(last'.op = "mark" /\ WellFormed(last'.p) /\ WellFormed(last'.i)
            /\ ~(\E s \in Slots : st[s] # "none" /\ per[s] = last'.p /\ itm[s] = last'.i))
         => Cardinality({s \in Slots : st[s] = "none" /\ st'[s] # "none"
                                       /\ per'[s] = last'.p /\ itm'[s] = last'.i}) = 1]_vars

\* Op6_MarkRemarks: a [Mark] of a well-formed pair whose favorite stands
\* unmarked leaves that favorite marked: filling the heart again (Operation 6).
Op6_MarkRemarks ==
    [][(last'.op = "mark" /\ WellFormed(last'.p) /\ WellFormed(last'.i))
         => \A s \in Slots : (Holds(s, last'.p, last'.i) /\ st[s] = "unmarked")
                               => st'[s] = "marked"]_vars

\* Op7_MarkedMarkWritesNothing: a [Mark] of a well-formed pair whose favorite
\* stands marked writes nothing: the same tap twice changes nothing
\* (Operation 7).
Op7_MarkedMarkWritesNothing ==
    [][(last'.op = "mark" /\ WellFormed(last'.p) /\ WellFormed(last'.i)
            /\ MarkedHeld(last'.p, last'.i))
         => (wrote' = {} /\ UNCHANGED records)]_vars

\* Op8_MarkAnswersOk: a [Mark] no refusal applies to answered ok, whatever it
\* found (Operation 8, Execution Contract Read 4).
Op8_MarkAnswersOk ==
    (last.op = "mark" /\ WellFormed(last.p) /\ WellFormed(last.i)) => last.ans = "ok"

\* Op9_UnmarkUnmarks: an [Unmark] of a well-formed pair whose favorite stands
\* marked leaves that favorite unmarked (Operation 9).
Op9_UnmarkUnmarks ==
    [][(last'.op = "unmark" /\ WellFormed(last'.p) /\ WellFormed(last'.i))
         => \A s \in Slots : (Holds(s, last'.p, last'.i) /\ st[s] = "marked")
                               => st'[s] = "unmarked"]_vars

\* Op10_UnmarkedUnmarkWritesNothing: an [Unmark] of a well-formed pair whose
\* favorite stands unmarked writes nothing (Operation 10).
Op10_UnmarkedUnmarkWritesNothing ==
    [][(last'.op = "unmark" /\ WellFormed(last'.p) /\ WellFormed(last'.i)
            /\ \E s \in Slots : Holds(s, last'.p, last'.i) /\ st[s] = "unmarked")
         => (wrote' = {} /\ UNCHANGED records)]_vars

\* Op11_UnknownUnmarkWritesNothing: an [Unmark] of a well-formed pair no
\* favorite carries writes nothing: unmark("ana", "Kettle-Blue") where ana
\* keeps kettle-blue (Operation 11, Identity 5).
Op11_UnknownUnmarkWritesNothing ==
    [][(last'.op = "unmark" /\ WellFormed(last'.p) /\ WellFormed(last'.i)
            /\ ~Held(last'.p, last'.i))
         => (wrote' = {} /\ UNCHANGED records)]_vars

\* Op12_UnmarkAnswersOk: an [Unmark] no refusal applies to answered ok,
\* whatever it found (Operation 12, Execution Contract Read 4).
Op12_UnmarkAnswersOk ==
    (last.op = "unmark" /\ WellFormed(last.p) /\ WellFormed(last.i)) => last.ans = "ok"

\* Op13_LookUpAnswersOne: a [Look Up] answered marked or unmarked, and nothing
\* else, whatever it was given (Operation 13).
Op13_LookUpAnswersOne ==
    last.op = "look_up" => last.ans \in {"marked", "unmarked"}

\* Op14_LookUpMarkedOnlyIfMarked: a [Look Up] that answered marked read a
\* marked favorite for the pair, compared codepoint for codepoint
\* (Operation 14, Identity 3, 5).
Op14_LookUpMarkedOnlyIfMarked ==
    [][(last'.op = "look_up" /\ last'.ans = "marked") => MarkedHeld(last'.p, last'.i)]_vars

\* LookUpTerm_MarkedAnswersMarked: a [Look Up] of a well-formed pair that
\* reads a marked favorite for it answers marked: look_up("r7",
\* "recipe-lentil-soup") after the star (the term Look Up: "Answers whether
\* one item is a person's favorite now"; the case table's row "a marked
\* favorite for the pair").
LookUpTerm_MarkedAnswersMarked ==
    [][(last'.op = "look_up" /\ WellFormed(last'.p) /\ WellFormed(last'.i)
            /\ MarkedHeld(last'.p, last'.i))
         => last'.ans = "marked"]_vars

\* Op15_LookUpWritesNothing: a [Look Up] step writes no record and changes no
\* field of any favorite (Operation 15).
Op15_LookUpWritesNothing ==
    [][last'.op = "look_up" => (wrote' = {} /\ UNCHANGED records)]_vars

\* Op16_ListAnswersEveryMarked: a [List] of a well-formed person reference
\* answered the item reference of every marked favorite carrying it
\* (Operation 16).
Op16_ListAnswersEveryMarked ==
    [][(last'.op = "list" /\ WellFormed(last'.p))
         => \A s \in Slots : (st[s] = "marked" /\ per[s] = last'.p)
                               => \E k \in DOMAIN last'.out : last'.out[k].item = itm[s]]_vars

\* ListTerm_OnlyThePersonsMarked: every entry a [List] answered is a marked
\* favorite carrying the person reference it was given: the kettle leaves
\* what list("ana") answers once unmarked (the term List: "Answers every
\* [Marked] favorite of one person"; the online store).
ListTerm_OnlyThePersonsMarked ==
    [][last'.op = "list"
         => \A k \in DOMAIN last'.out :
              \E s \in Slots : st[s] = "marked" /\ per[s] = last'.p
                               /\ itm[s] = last'.out[k].item]_vars

\* Op17_ListAnswersItemAndInstant: every entry a [List] answered carries the
\* item reference and the first marked instant of a favorite of the person
\* (Operation 17).
Op17_ListAnswersItemAndInstant ==
    [][last'.op = "list"
         => \A k \in DOMAIN last'.out :
              \E s \in Slots : st[s] # "none" /\ per[s] = last'.p
                               /\ itm[s] = last'.out[k].item /\ fmi[s] = last'.out[k].fmi]_vars

\* Op18_ListEmptyForNone: a [List] of a well-formed person reference no marked
\* favorite carries answered an empty list (Operation 18).
Op18_ListEmptyForNone ==
    [][(last'.op = "list" /\ WellFormed(last'.p)
            /\ ~(\E s \in Slots : st[s] = "marked" /\ per[s] = last'.p))
         => (last'.ans = "ok" /\ last'.out = NoList)]_vars

\* Op19_ListWritesNothing: a [List] step writes no record and changes no field
\* of any favorite (Operation 19).
Op19_ListWritesNothing ==
    [][last'.op = "list" => (wrote' = {} /\ UNCHANGED records)]_vars

\* Op22_LookUpBadPersonUnmarked: a [Look Up] whose person reference is blank,
\* over the string cap or not a string answered unmarked: look_up("",
\* "kettle-blue") (Operation 22).
Op22_LookUpBadPersonUnmarked ==
    (last.op = "look_up" /\ ~WellFormed(last.p)) => last.ans = "unmarked"

\* Op23_LookUpBadItemUnmarked: a [Look Up] whose item reference is blank,
\* over the string cap or not a string answered unmarked (Operation 23).
Op23_LookUpBadItemUnmarked ==
    (last.op = "look_up" /\ ~WellFormed(last.i)) => last.ans = "unmarked"

\* Op24_ListBadPersonEmpty: a [List] whose person reference is blank, over
\* the string cap or not a string answered an empty list (Operation 24).
Op24_ListBadPersonEmpty ==
    (last.op = "list" /\ ~WellFormed(last.p)) => (last.ans = "ok" /\ last.out = NoList)

\* Op25_ListOrder: each entry of a [List] answer comes before the next by
\* Operation 25's order: the kettle (Monday) before the teapot (Tuesday),
\* and, at one first marked instant, Kettle-Blue before kettle-blue
\* (Operation 25, Execution Contract Logic confinement 10).
Op25_ListOrder ==
    last.op = "list" => \A k \in DOMAIN last.out :
                          (k + 1 \in DOMAIN last.out) => Precedes(last.out[k], last.out[k + 1])

====
