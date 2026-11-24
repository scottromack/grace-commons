---- MODULE erasure-tombstone ----
\* Grace Commons — Erasure Tombstone atom (atoms/erasure-tombstone.md).
\* Grounded on Final Critique 2, 2026-11-03 at aeea14e — TLA+ layer authored 2026-11-11.
\* Derived validator; the English spec is the single source of truth. On any
\* disagreement, diagnose per the entry *The conflict protocol* in pressure-testing.md.
\*
\* PURPOSE
\* Check what happens across steps: what [Record Destruction] writes and
\* answers over any sequence of calls, retries of one destruction included,
\* and what [Read Tombstone] and [List Destroyed] answer over the tombstones
\* those calls leave. What one state of the tombstones must carry (State 1,
\* Invariant 3 and 4, Identity 2 to 4, Operation 2, 5, 8, 9) is the Alloy
\* model's, erasure-tombstone.als; the two models spell the page's terms alike
\* (destroyed pattern, destroyed id, destruction instant, authority kind,
\* authority reference, actor reference), so the rule both check (Invariant
\* 2.1) is a cross-check.
\*
\* RULES CHECKED (named by the page's own labels)
\*   Invariant 1.1 — a recorded tombstone's fields never change
\*                   (State 2, Operation 22; Check 1.2)          (Inv1_1_TombstoneFixed)
\*   Invariant 1.2 — no tombstone is removed (State 3,
\*                   Operation 23, Non-goal 13)                  (Inv1_2_NeverRemoved)
\*   Invariant 2.1 — no two tombstones share a destroyed pattern
\*                   and a destroyed id (2.2; Check 2.1)         (Inv2_1_OnePerDestroyedRecord)
\*   Invariant 5.1 — two [List Destroyed] calls with one pattern,
\*                   one window and one continuation key answer
\*                   one sequence over one database state
\*                   (Check 7.1)                                 (Inv5_1_ListingDeterministic)
\*   Identity 1    — a tombstone is named by the pattern and the
\*                   id together: duplicate answers only for a
\*                   pair a tombstone carries                    (Id1_DuplicateOnlyForThePair)
\*   Operation 1   — a call answered recorded wrote exactly one
\*                   tombstone, carrying the call's inputs and
\*                   its now (with 2, 3; 10: a refused call,
\*                   storage-failure included, writes nothing)   (Op1_OneTombstonePerRecorded)
\*   Operation 4   — a call naming a pair a tombstone carries
\*                   answers duplicate, ahead of every other
\*                   refusal (Execution Contract Refusal 1;
\*                   Concurrency 1, 2)                           (Op4_DuplicateForARecordedPair)
\*   Operation 12  — [Read Tombstone] answers the tombstone the
\*                   pair identifies, or none (with 13)          (Op12_ReadAnswersThePair)
\*   Operation 15  — [List Destroyed] answers the matching
\*                   tombstones with the earliest listing keys,
\*                   up to the page size                         (Op15_EarliestPage)
\*   Operation 16  — in listing-key order: destruction instant,
\*                   then destroyed id in code point order       (Op16_ListingKeyOrder)
\*   Operation 18  — a window that ends before it starts answers
\*                   invalid-request                             (Op18_InvertedWindowRefused)
\*   Operation 20  — [Read Tombstone] and [List Destroyed] write
\*                   nothing (with 21)                           (Op20_ReadsWriteNothing)
\*   Operation 24  — [List Destroyed] answers only matching
\*                   tombstones: the pattern's, in the half-open
\*                   window, past the continuation key           (Op24_OnlyMatching)
\*
\* WHAT THE MODEL TAKES FROM OUTSIDE THE PAGE (its inputs; no ASSUME, no CONSTRAINT)
\* - The clock (Term now; Execution Contract Logic confinement 11): each
\*   [Record Destruction] carries one reading, any instant of 0..MaxTime;
\*   nothing makes the readings run forward.
\* - The database (Execution Contract Database 1, 2, Order 1): each call's
\*   guards and write are one atomic step, so two calls racing on one pair are
\*   two steps in some order and the second sees the first's tombstone; and
\*   whether it accepts a write (`ok`: a refused write answers storage-failure,
\*   Operation 10).
\* - The deployment's page size, chosen once at the start from PageSizes, every
\*   one above zero (Capability requirement 8, 9).
\*
\* BOUNDS (the .cfg)
\* Two destroyed patterns; two destroyed ids, inv_8c21 and pref_19aa, in code
\* point order (IdOrder below); the kinds retention-purge and erasure-request
\* (recognized) and cleanup (not); one authority reference and one actor
\* reference; two tombstone slots (a call that would need a third is not
\* taken); the clock 0..1; a page size of 1 or 2. Windows start at 0..1 and
\* end at 0..2; a continuation key is blank or any instant paired with any id.
\* Two slots, two ids and two instants already give two tombstones of one
\* pattern in each order of instant and id and at one instant, one id in both
\* patterns, a retry of a recorded pair, and a pattern holding more tombstones
\* than a page of one. 37,202 states, about 29 s; with three slots 310,610
\* states (about 409 s), the same verdicts.
\*
\* NOT MODELED HERE
\* - Blank, over-long and malformed inputs (Operation 5, 6, 8, 9, 14, 19, 25
\*   to 27): the Alloy model checks what [Record Destruction] admits; the
\*   reads' input refusals are owed. An unrecognized kind (Operation 7) stays,
\*   since Refusal 1 orders it after duplicate.
\* - The failed read (Execution Contract Read 1) and state-unavailable.
\* - The destroyed record and the composing pattern's delete in the same
\*   transaction (Composition note 1, 6): the atom reads none of it.

EXTENDS Integers, FiniteSets

CONSTANTS
    Patterns,     \* the destroyed patterns a call may carry
    Kinds,        \* the authority kinds a call may carry, recognized or not
    Recognized,   \* the recognized kinds: retention-purge, erasure-request and the deployment's
    AuthRefs,     \* the authority references a call may carry (none blank)
    ActorRefs,    \* the actor references a call may carry (none blank)
    Slots,        \* the tombstone slots: how many tombstones the database can hold
    MaxTime,      \* the last clock reading a call may carry
    PageSizes     \* the page sizes the deployment may run with (each above zero)

\* ---------------------------------------------------------------------------
\* Values
\* ---------------------------------------------------------------------------

\* IdOrder: the destroyed ids a call may carry, in code point order (Logic
\* confinement 10): "i" (U+0069) comes before "p" (U+0070).
IdOrder == <<"inv_8c21", "pref_19aa">>

\* Ids: the destroyed ids a call may carry.
Ids == {IdOrder[k] : k \in DOMAIN IdOrder}

\* IdRank: a destroyed id's place in code point order.
IdRank(i) == CHOOSE k \in DOMAIN IdOrder : IdOrder[k] = i

\* Instants: the clock readings a call may carry.
Instants == 0..MaxTime

\* WindowEnds: the window ends a [List Destroyed] call may carry, one past the
\* last instant so the half-open window can hold it.
WindowEnds == 0..(MaxTime + 1)

\* NoInstant: the value of an instant a record does not carry.
NoInstant == -1

\* NoKey: the blank continuation key (Term continuation key: a blank key starts
\* at the earliest).
NoKey == <<NoInstant, "none">>

\* ContinuationKeys: the continuation keys a call may carry: blank, or any
\* destruction instant paired with any destroyed id (Term continuation key).
ContinuationKeys == {NoKey} \cup (Instants \X Ids)

\* NoTomb: an empty tombstone slot.
NoTomb == [pat |-> "none", id |-> "none", kind |-> "none", aref |-> "none",
           actor |-> "none", at |-> NoInstant]

\* Min: the smaller of two numbers.
Min(a, b) == IF a < b THEN a ELSE b

\* Key: a tombstone's listing key, its destruction instant paired with its
\* destroyed id (Term listing key).
Key(r) == <<r.at, r.id>>

\* KeyBefore: listing key k1 comes before k2: by instant, then by destroyed id in
\* code point order (Term listing key, Operation 16). The page's order, which
\* the checks read.
KeyBefore(k1, k2) == \/ k1[1] < k2[1]
                     \/ (k1[1] = k2[1] /\ IdRank(k1[2]) < IdRank(k2[2]))

\* Call: the record of one call and its answer that the checks read: which
\* action, its inputs, and what it answered (ans), the tombstone a read answered
\* (rec) and the tombstones a listing answered, in order (page).
Call(op, p, i, k, a, r, t, ws, we, ck, ans, rec, page) ==
    [op |-> op, pat |-> p, id |-> i, kind |-> k, aref |-> a, actor |-> r, now |-> t,
     ws |-> ws, we |-> we, ck |-> ck, ans |-> ans, rec |-> rec, page |-> page]

\* NoCall: no call yet.
NoCall == Call("none", "none", "none", "none", "none", "none", NoInstant,
               NoInstant, NoInstant, NoKey, "none", NoTomb, <<>>)

\* ---------------------------------------------------------------------------
\* State
\* ---------------------------------------------------------------------------

VARIABLES
    tomb,      \* tombstone slot -> the tombstone it holds, or NoTomb
    pageSize,  \* the page size the deployment runs with
    last,      \* the last call and its answer
    wrote      \* the slots the last step wrote

\* vars: every variable, the tuple a step that changes nothing leaves as it was.
vars == <<tomb, pageSize, last, wrote>>

\* TypeOK: each variable holds a value of its kind (the model's typing, not a
\* rule of the page).
TypeOK ==
    /\ pageSize \in PageSizes
    /\ wrote \subseteq Slots
    /\ \A s \in Slots : tomb[s] = NoTomb \/ tomb[s].at \in Instants

\* ---------------------------------------------------------------------------
\* Derived (never stored)
\* ---------------------------------------------------------------------------

\* Holds: slot s holds the tombstone of destroyed pattern p and destroyed id i.
Holds(s, p, i) == tomb[s] # NoTomb /\ tomb[s].pat = p /\ tomb[s].id = i

\* HeldPair: a tombstone names destroyed pattern p and destroyed id i.
HeldPair(p, i) == \E s \in Slots : Holds(s, p, i)

\* Matching: the matching erasure tombstones of a [List Destroyed] call, as the
\* page defines them (Term matching erasure tombstone): of the destroyed
\* pattern, destruction instant in the half-open window (Term window: start
\* included, end excluded), listing key past the continuation key where one is
\* given. The checks read this; the action computes its own (Selected).
Matching(p, ws, we, ck) ==
    {tomb[s] : s \in {x \in Slots : /\ tomb[x] # NoTomb
                                    /\ tomb[x].pat = p
                                    /\ ws <= tomb[x].at /\ tomb[x].at < we
                                    /\ (ck = NoKey \/ KeyBefore(ck, Key(tomb[x])))}}

\* ---------------------------------------------------------------------------
\* What the atom computes for a [List Destroyed] call
\* ---------------------------------------------------------------------------

\* ListBefore: the order the atom sorts a listing in: by destruction instant,
\* then by destroyed id in code point order (Operation 16).
ListBefore(k1, k2) == \/ k1[1] < k2[1]
                      \/ (k1[1] = k2[1] /\ IdRank(k1[2]) < IdRank(k2[2]))

\* Selected: the tombstones the atom's query selects for a [List Destroyed]
\* call: the pattern's, in the window, past the continuation key.
Selected(p, ws, we, ck) ==
    {tomb[s] : s \in {x \in Slots : /\ tomb[x] # NoTomb
                                    /\ tomb[x].pat = p
                                    /\ tomb[x].at >= ws /\ tomb[x].at < we
                                    /\ (ck = NoKey \/ ListBefore(ck, Key(tomb[x])))}}

\* Rank: a tombstone's place among S in the atom's order, from 1.
Rank(r, S) == Cardinality({x \in S : ListBefore(Key(x), Key(r))}) + 1

\* Page: the first n of S in the atom's order (Operation 15). Two tombstones of
\* one listing key would share a rank; the fallback keeps the operator defined
\* for a twin that lets that happen (the correct model never does: Invariant
\* 2.1).
Page(S, n) ==
    [k \in 1..Min(n, Cardinality(S)) |->
        IF \E r \in S : Rank(r, S) = k
        THEN CHOOSE r \in S : Rank(r, S) = k
        ELSE CHOOSE r \in S : TRUE]

\* ---------------------------------------------------------------------------
\* Actions
\* ---------------------------------------------------------------------------

\* Init: no tombstone, no call yet, and the deployment's page size.
Init ==
    /\ tomb = [s \in Slots |-> NoTomb]
    /\ pageSize \in PageSizes
    /\ last = NoCall
    /\ wrote = {}

\* Refusal: what a [Record Destruction] call that writes nothing answers, the
\* first refusal on its refuses line that applies (Execution Contract Refusal
\* 1): duplicate where a tombstone names the pair (Operation 4), then
\* invalid-request for a kind not recognized (Operation 7), then
\* storage-failure where the database refuses the write (Operation 10).
Refusal(held, k, ok) ==
    IF held THEN "duplicate"
    ELSE IF k \notin Recognized THEN "invalid-request"
    ELSE "storage-failure"

\* Record: [Record Destruction] of destroyed pattern p, destroyed id i,
\* authority kind k, authority reference a and actor reference r, with the
\* clock reading t injected at the seam, the database accepting the write
\* where ok. A call the guards refuse, or whose write the database refuses,
\* writes nothing and answers its refusal. Otherwise exactly one tombstone
\* lands in the first free slot, carrying the call's five inputs and t as its
\* destruction instant (Operation 1, 2), and the call answers recorded
\* (Operation 3).
Record(p, i, k, a, r, t, ok) ==
    LET held == HeldPair(p, i)                                        \* Operation 4, Invariant 2.2
        new  == [pat |-> p, id |-> i, kind |-> k, aref |-> a, actor |-> r, at |-> t]
    IN  /\ IF held \/ k \notin Recognized \/ ~ok
           THEN /\ tomb' = tomb
                /\ wrote' = {}
                /\ last' = Call("record", p, i, k, a, r, t, NoInstant, NoInstant, NoKey,
                                Refusal(held, k, ok), NoTomb, <<>>)
           ELSE \E s \in Slots :
                  /\ tomb[s] = NoTomb
                  /\ \A x \in Slots : tomb[x] = NoTomb => s <= x
                  /\ tomb' = [tomb EXCEPT ![s] = new]                \* Operation 1, 2
                  /\ wrote' = {s}
                  /\ last' = Call("record", p, i, k, a, r, t, NoInstant, NoInstant, NoKey,
                                  "recorded", NoTomb, <<>>)          \* Operation 3
        /\ UNCHANGED pageSize

\* Read: [Read Tombstone] of destroyed pattern p and destroyed id i answers the
\* tombstone the pair names, or none where no tombstone names it (Operation 12,
\* 13), and writes nothing (Operation 20).
Read(p, i) ==
    LET hits == {s \in Slots : tomb[s] # NoTomb /\ tomb[s].pat = p /\ tomb[s].id = i}
    IN  /\ last' = Call("read", p, i, "none", "none", "none", NoInstant, NoInstant, NoInstant,
                        NoKey, IF hits = {} THEN "none" ELSE "tombstone",
                        IF hits = {} THEN NoTomb ELSE tomb[CHOOSE s \in hits : TRUE], <<>>)
        /\ wrote' = {}
        /\ UNCHANGED <<tomb, pageSize>>

\* List: [List Destroyed] of destroyed pattern p over the window from ws to we,
\* past continuation key ck. A window that ends before it starts answers
\* invalid-request (Operation 18). Otherwise it answers the first page of the
\* selected tombstones in the atom's order (Operation 15, 16, 24). It writes
\* nothing (Operation 21).
List(p, ws, we, ck) ==
    /\ IF we < ws
       THEN last' = Call("list", p, "none", "none", "none", "none", NoInstant, ws, we, ck,
                         "invalid-request", NoTomb, <<>>)
       ELSE last' = Call("list", p, "none", "none", "none", "none", NoInstant, ws, we, ck,
                         "listed", NoTomb, Page(Selected(p, ws, we, ck), pageSize))
    /\ wrote' = {}
    /\ UNCHANGED <<tomb, pageSize>>

\* Next: any call of any inputs at any clock reading, the database accepting or
\* refusing each write.
Next ==
    \/ \E p \in Patterns, i \in Ids, k \in Kinds, a \in AuthRefs, r \in ActorRefs,
          t \in Instants, ok \in BOOLEAN : Record(p, i, k, a, r, t, ok)
    \/ \E p \in Patterns, i \in Ids : Read(p, i)
    \/ \E p \in Patterns, ws \in Instants, we \in WindowEnds, ck \in ContinuationKeys :
          List(p, ws, we, ck)

\* Spec: every behaviour from Init by Next steps.
Spec == Init /\ [][Next]_vars

\* ---------------------------------------------------------------------------
\* Checks (the verification surface)
\* ---------------------------------------------------------------------------

\* Inv1_1_TombstoneFixed: no step changes a recorded tombstone's fields: a
\* tombstone reads the same forever, a retry included (Invariant 1.1, State 2,
\* Operation 22; Check 1.2).
Inv1_1_TombstoneFixed ==
    [][\A s \in Slots : (tomb[s] # NoTomb /\ tomb'[s] # NoTomb) => tomb'[s] = tomb[s]]_vars

\* Inv1_2_NeverRemoved: no step removes a tombstone (Invariant 1.2, State 3,
\* Operation 23, Non-goal 13).
Inv1_2_NeverRemoved ==
    [][\A s \in Slots : tomb[s] # NoTomb => tomb'[s] # NoTomb]_vars

\* Inv2_1_OnePerDestroyedRecord: in every reachable state no two tombstones
\* share a destroyed pattern and a destroyed id: a destroyed record has at most
\* one, however often its purge is retried (Invariant 2.1, Check 2.1).
Inv2_1_OnePerDestroyedRecord ==
    \A s1, s2 \in Slots :
        (s1 # s2 /\ tomb[s1] # NoTomb /\ tomb[s2] # NoTomb)
            => ~(tomb[s1].pat = tomb[s2].pat /\ tomb[s1].id = tomb[s2].id)

\* Inv5_1_ListingDeterministic: two [List Destroyed] calls in a row with one
\* pattern, one window and one continuation key, the first of which wrote
\* nothing, read one database state and answer one sequence: two auditors
\* rebuilding one seal's coverage reach one answer (Invariant 5.1, Check 7.1).
Inv5_1_ListingDeterministic ==
    [][(/\ last.op = "list" /\ last'.op = "list" /\ wrote = {}
        /\ last'.pat = last.pat /\ last'.ws = last.ws /\ last'.we = last.we
        /\ last'.ck = last.ck)
          => (last'.ans = last.ans /\ last'.page = last.page)]_vars

\* Id1_DuplicateOnlyForThePair: a [Record Destruction] call answered duplicate
\* names a pair a tombstone carries: a tombstone is named by the destroyed
\* pattern and the destroyed id together, compared byte-exactly, so one id
\* destroyed in two patterns is two destructions (Identity 1, String 1).
Id1_DuplicateOnlyForThePair ==
    [][(last'.op = "record" /\ last'.ans = "duplicate") => HeldPair(last'.pat, last'.id)]_vars

\* Op4_DuplicateForARecordedPair: a [Record Destruction] call naming a pair a
\* tombstone already carries answers duplicate, ahead of every other refusal
\* (Operation 4, Execution Contract Refusal 1), so of two calls for one pair the
\* later one answers duplicate and only one answers recorded (Concurrency 1, 2).
Op4_DuplicateForARecordedPair ==
    [][(last'.op = "record" /\ HeldPair(last'.pat, last'.id)) => last'.ans = "duplicate"]_vars

\* Op1_OneTombstonePerRecorded: a [Record Destruction] call answered recorded
\* wrote exactly one tombstone, into a free slot, carrying the call's destroyed
\* pattern, destroyed id, authority kind, authority reference and actor
\* reference and its injected now as the destruction instant, and changed
\* nothing else (Operation 1, 2, 3); a call answered with a refusal,
\* storage-failure included, wrote nothing (Operation 10, Execution Contract
\* Read 4), so a destroying pattern whose delete rolls back with it never
\* leaves a tombstone standing for a record still kept.
Op1_OneTombstonePerRecorded ==
    [][last'.op = "record" =>
         IF last'.ans = "recorded"
         THEN \E s \in Slots :
                /\ wrote' = {s}
                /\ tomb[s] = NoTomb
                /\ tomb'[s] = [pat |-> last'.pat, id |-> last'.id, kind |-> last'.kind,
                               aref |-> last'.aref, actor |-> last'.actor, at |-> last'.now]
                /\ \A x \in Slots \ {s} : tomb'[x] = tomb[x]
         ELSE wrote' = {} /\ tomb' = tomb]_vars

\* Op12_ReadAnswersThePair: [Read Tombstone] answers the tombstone that names
\* the call's destroyed pattern and destroyed id, and none where no tombstone
\* names them (Operation 12, 13).
Op12_ReadAnswersThePair ==
    [][last'.op = "read" =>
         IF HeldPair(last'.pat, last'.id)
         THEN /\ last'.ans = "tombstone"
              /\ \E s \in Slots : Holds(s, last'.pat, last'.id) /\ last'.rec = tomb[s]
         ELSE last'.ans = "none"]_vars

\* Op15_EarliestPage: a [List Destroyed] answer holds as many tombstones as the
\* page size allows, or every matching one where fewer match, and every matching
\* tombstone it leaves out comes after every one it answers: the earliest
\* listing keys first, so paging on reaches every one (Operation 15).
Op15_EarliestPage ==
    [][(last'.op = "list" /\ last'.ans = "listed") =>
         LET M  == Matching(last'.pat, last'.ws, last'.we, last'.ck)
             pg == last'.page
         IN  /\ DOMAIN pg = 1..Min(pageSize, Cardinality(M))
             /\ \A r \in M : (\A k \in DOMAIN pg : pg[k] # r)
                               => \A k \in DOMAIN pg : KeyBefore(Key(pg[k]), Key(r))]_vars

\* Op16_ListingKeyOrder: a [List Destroyed] answer runs in listing-key order: by
\* destruction instant, then by destroyed id in code point order (Operation 16).
Op16_ListingKeyOrder ==
    [][(last'.op = "list" /\ last'.ans = "listed") =>
         \A j, k \in DOMAIN last'.page :
             j < k => KeyBefore(Key(last'.page[j]), Key(last'.page[k]))]_vars

\* Op24_OnlyMatching: a [List Destroyed] answer holds only matching tombstones:
\* of the call's pattern, in the half-open window, past the continuation key
\* (Operation 24, Term matching erasure tombstone).
Op24_OnlyMatching ==
    [][(last'.op = "list" /\ last'.ans = "listed") =>
         \A k \in DOMAIN last'.page :
             last'.page[k] \in Matching(last'.pat, last'.ws, last'.we, last'.ck)]_vars

\* Op18_InvertedWindowRefused: a [List Destroyed] call whose window ends before
\* it starts answers invalid-request, not an empty page (Operation 18).
Op18_InvertedWindowRefused ==
    [][(last'.op = "list" /\ last'.we < last'.ws) => last'.ans = "invalid-request"]_vars

\* Op20_ReadsWriteNothing: a [Read Tombstone] or [List Destroyed] step writes no
\* record and changes no tombstone (Operation 20, 21).
Op20_ReadsWriteNothing ==
    [][last'.op \in {"read", "list"} => (wrote' = {} /\ tomb' = tomb)]_vars

====
