---- MODULE punch-card ----
\* Grace Commons — Punch Card atom (atoms/punch-card.md).
\* Grounded on Final Critique 2, 2026-11-13 at a3fb226 — TLA+ layer authored 2026-11-13.
\* Derived validator; the English spec is the single source of truth. On any
\* disagreement, diagnose per the entry *The conflict protocol* in pressure-testing.md.
\*
\* PURPOSE
\* Check what happens across steps: the punch cards [Issue], [Stamp] and
\* [Redeem] write over a sequence of calls, what each call answers, what a
\* refused [Stamp] or [Redeem], [Check Stamps] and [Read] leave, and what each
\* step writes, across restarts that change the stamp goal. What one state of
\* the records must carry (State 1, Identity 6 to 9, Operation 1's fields, 2,
\* 3 and 4, Invariant 1.1 and 1.2) is the Alloy model's, punch-card.als; the
\* two models spell the page's terms alike (punch card, card id, card code,
\* goal, stamps, redemptions, stamp goal).
\*
\* RULES CHECKED (named by the page's own labels)
\*   State 2       — the atom never removes a punch card            (State2_NeverRemoved)
\*   Invariant 2.1 — the atom never changes a card code             (Inv2_1_CodeKept)
\*   Invariant 2.2 — the atom never changes a goal                  (Inv2_2_GoalKept)
\*   Invariant 2.3 — the atom never lowers the redemptions          (Inv2_3_RedemptionsNeverFall)
\*   Invariant 3.1 — a refused [Stamp] changes no stamps            (Inv3_1_RefusedStampKeepsStamps)
\*   Invariant 3.2 — a refused [Redeem] changes no stamps           (Inv3_2_RefusedRedeemKeepsStamps)
\*   Invariant 3.3 — a refused [Redeem] changes no redemptions      (Inv3_3_RefusedRedeemKeepsRedemptions)
\*   Operation 1   — an [Issue] records exactly one punch card      (Op1_OneCardPerIssue)
\*   Operation 5   — [Issue] answers the card id and the card code  (Op5_IssueAnswersIdAndCode)
\*   Operation 6   — a code naming no punch card answers not-known  (Op6_UnknownCodeNotKnown)
\*   Operation 7   — [Check Stamps] answers the stamps and the goal (Op7_CheckAnswersStampsAndGoal)
\*   Operation 8   — [Check Stamps] writes nothing                  (Op8_CheckStampsWritesNothing)
\*   Operation 9   — a stamp on a full punch card answers full      (Op9_FullStampRefused)
\*   Operation 10  — a stamp below the goal adds exactly one        (Op10_StampAddsOne)
\*   Operation 11  — [Stamp] answers the new stamps                 (Op11_StampAnswersNewStamps)
\*   Operation 12  — a redeem below the goal answers not-full       (Op12_NotFullRedeemRefused)
\*   Operation 13  — [Redeem] sets the stamps to zero               (Op13_RedeemEmpties)
\*   Operation 14  — a redeem at the goal adds exactly one
\*                   redemption                                     (Op14_RedeemCountsOne)
\*   Operation 15  — [Redeem] answers the new redemptions           (Op15_RedeemAnswersNewRedemptions)
\*   Operation 16  — a card id naming no punch card answers
\*                   not-known; card ids compared codepoint for
\*                   codepoint (Identity 10)                        (Op16_UnknownIdNotKnown)
\*   Operation 17  — [Read] answers the card id, goal, stamps and
\*                   redemptions                                    (Op17_ReadAnswersCard)
\*   Operation 18  — [Read] never answers the card code             (Op18_ReadNeverAnswersCode)
\*   Operation 19  — [Read] writes nothing                          (Op19_ReadWritesNothing)
\*
\* WHAT THE MODEL TAKES FROM OUTSIDE THE PAGE (its inputs; no ASSUME)
\* - The seam: each [Issue] gets a card id and a card code no punch card
\*   carries (Capability requirement 1, 2, 8, 9).
\* - The deployment: a stamp goal among StampGoals, each a positive count
\*   (Capability requirement 5), read at the instance's start; a restart may
\*   read another (Execution Contract Logic confinement 17).
\* - The database (Execution Contract Database 1, 2): each call's guards and
\*   writes are one atomic step, so two stamps or two redeems on one punch
\*   card, concurrent ones included, are two steps in some order (the Edge
\*   case "Concurrency").
\*
\* BOUNDS (the .cfg)
\* Two card ids; a third id a [Read] may present, P1, differing from p1 only
\* in case; three card codes, so a code action can present a code no punch
\* card carries; stamp goals 1 and 2, so a punch card fills in one or two
\* stamps and a restart can change the goal. The redemptions are unbounded on
\* the page, so the one CONSTRAINT, RedemptionBound, stops the search past one
\* redemption per punch card (a bound, not a rule: the states one more
\* redemption reaches are still checked).
\*
\* NOT MODELED HERE
\* - The default stamp goal of five, and goals above two: the Alloy model's
\*   Operation 2 check reads the default; no rule here turns on a goal's size.
\* - Storage failure and the failed read (Execution Contract Database 3, Read
\*   1): a write that did not commit leaves nothing.
\* - Card codes that differ only in case (Identity 8, 9): the Alloy model's.
\* - What counts as a purchase, who may stamp, a bonus stamp, a stamp taken
\*   back, transfer, expiry, cancelling (Non-goal 1 to 9: Checkout,
\*   Permissions, Loyalty Card); a repeated stamp told from a new one
\*   (Non-goal 13: Duplicate Prevention); money (Non-goal 12: Gift Card).
\* - Liveness: the page states no eventually-property (no rule that a call
\*   must be made or must answer in time), so the model checks safety only.

EXTENDS Integers, FiniteSets

CONSTANTS
    Ids,            \* the card ids the seam may supply
    ReadIds,        \* the card ids a [Read] may present: the seam's, and others
    Codes,          \* the card codes the seam may supply and a code action may present
    StampGoals,     \* the stamp goals a deployment may declare at an instance's start
    MaxRedemptions  \* the search bound on a punch card's redemptions (see BOUNDS)

\* NoCode: the code field of an answer that carries no code.
NoCode == "none"

\* NoId: the card id field of an answer, or of a call, that names no punch card.
NoId == "none"

\* NoCall: the record of the last call before any call is made, and the shape
\* of every such record: the action; the card id a [Read] presented; the punch
\* card it named or found (NoId for none); the code it carried; what it
\* answered, and the card id, code, goal, stamps and redemptions its answer
\* carried.
NoCall == [op |-> "none", idIn |-> NoId, card |-> NoId, code |-> NoCode, ans |-> "none",
           outId |-> NoId, outCode |-> NoCode, outGoal |-> 0, outStamps |-> 0, outRed |-> 0]

\* ---------------------------------------------------------------------------
\* State
\* ---------------------------------------------------------------------------

VARIABLES
    issued,  \* card id -> whether a punch card carries it
    code,    \* card id -> the punch card's card code (NoCode before it is issued)
    goal,    \* card id -> the punch card's goal (0 before it is issued)
    stamps,  \* card id -> the punch card's stamps (0 before it is issued)
    red,     \* card id -> the punch card's redemptions (0 before it is issued)
    sgoal,   \* the stamp goal the instance read at its start
    last,    \* the last call made and what it answered (NoCall's shape)
    wrote    \* the punch cards the last step wrote

\* vars: every variable; a step that changes none of them is a stutter.
vars == <<issued, code, goal, stamps, red, sgoal, last, wrote>>

\* records: every variable that holds a punch card's fields.
records == <<issued, code, goal, stamps, red>>

\* Carried: some punch card carries the code, compared codepoint for codepoint.
Carried(k) == \E g \in Ids : issued[g] /\ code[g] = k

\* IdCarried: some punch card carries the card id, compared codepoint for
\* codepoint (Identity 10).
IdCarried(r) == \E g \in Ids : issued[g] /\ g = r

\* SameId: how [Read] compares the card id it is given with a punch card's:
\* codepoint for codepoint (Identity 10).
SameId(r, g) == r = g

\* TypeOK: each variable holds a value of its kind (the model's typing, not a
\* rule of the page).
TypeOK ==
    /\ issued \in [Ids -> BOOLEAN]
    /\ code \in [Ids -> Codes \cup {NoCode}]
    /\ goal \in [Ids -> Int]
    /\ stamps \in [Ids -> Int]
    /\ red \in [Ids -> Int]
    /\ sgoal \in StampGoals
    /\ last \in [op : {"none", "restart", "issue", "check", "stamp", "redeem", "read"},
                 idIn : ReadIds \cup {NoId}, card : Ids \cup {NoId},
                 code : Codes \cup {NoCode},
                 ans : {"none", "ok", "not-known", "full", "not-full"},
                 outId : Ids \cup {NoId}, outCode : Codes \cup {NoCode},
                 outGoal : Int, outStamps : Int, outRed : Int]
    /\ wrote \subseteq Ids

\* Init: no punch card; the instance has read some stamp goal at its start.
Init ==
    /\ issued = [g \in Ids |-> FALSE]
    /\ code = [g \in Ids |-> NoCode]
    /\ goal = [g \in Ids |-> 0]
    /\ stamps = [g \in Ids |-> 0]
    /\ red = [g \in Ids |-> 0]
    /\ sgoal \in StampGoals
    /\ last = NoCall
    /\ wrote = {}

\* ---------------------------------------------------------------------------
\* Actions
\* ---------------------------------------------------------------------------

\* Restart: the instance restarts and reads the stamp goal s (Execution
\* Contract Logic confinement 17); no punch card is written.
Restart(s) ==
    /\ sgoal' = s
    /\ last' = [NoCall EXCEPT !.op = "restart"]
    /\ wrote' = {}
    /\ UNCHANGED records

\* Issue: an [Issue] records one punch card carrying the card id g and the
\* card code k the seam supplies (Operation 1), the stamp goal as its goal
\* (Operation 2), zero stamps and zero redemptions (Operation 3, 4), and
\* answers the card id and the card code (Operation 5).
Issue(g, k) ==
    /\ ~issued[g]
    /\ ~Carried(k)
    /\ issued' = [issued EXCEPT ![g] = TRUE]
    /\ code' = [code EXCEPT ![g] = k]
    /\ goal' = [goal EXCEPT ![g] = sgoal]
    /\ stamps' = [stamps EXCEPT ![g] = 0]
    /\ red' = [red EXCEPT ![g] = 0]
    /\ last' = [NoCall EXCEPT !.op = "issue", !.card = g, !.ans = "ok",
                              !.outId = g, !.outCode = k]
    /\ wrote' = {g}
    /\ UNCHANGED sgoal

\* CheckKnown: [Check Stamps] with a code a punch card carries answers its
\* stamps and its goal (Operation 7) and writes nothing (Operation 8).
CheckKnown(g) ==
    /\ issued[g]
    /\ last' = [NoCall EXCEPT !.op = "check", !.card = g, !.code = code[g], !.ans = "ok",
                              !.outGoal = goal[g], !.outStamps = stamps[g]]
    /\ wrote' = {}
    /\ UNCHANGED <<issued, code, goal, stamps, red, sgoal>>

\* CodeUnknown: a code action ([Check Stamps], [Stamp] or [Redeem]) with a code
\* no punch card carries answers not-known, the first refusal on its line, and
\* writes nothing (Operation 6, Execution Contract Refusal 1).
CodeUnknown(o, k) ==
    /\ ~Carried(k)
    /\ last' = [NoCall EXCEPT !.op = o, !.code = k, !.ans = "not-known"]
    /\ wrote' = {}
    /\ UNCHANGED <<issued, code, goal, stamps, red, sgoal>>

\* StampFull: [Stamp] on a punch card whose stamps equal its goal answers full
\* and writes nothing (Operation 9).
StampFull(g) ==
    /\ issued[g]
    /\ stamps[g] = goal[g]
    /\ last' = [NoCall EXCEPT !.op = "stamp", !.card = g, !.code = code[g], !.ans = "full"]
    /\ wrote' = {}
    /\ UNCHANGED <<issued, code, goal, stamps, red, sgoal>>

\* StampLands: [Stamp] on a punch card whose stamps are below its goal (the
\* case table) sets the stamps to the stamps plus one (Operation 10) and
\* answers the new stamps (Operation 11); the code, goal and redemptions stand.
StampLands(g) ==
    /\ issued[g]
    /\ stamps[g] < goal[g]
    /\ stamps' = [stamps EXCEPT ![g] = stamps[g] + 1]
    /\ last' = [NoCall EXCEPT !.op = "stamp", !.card = g, !.code = code[g], !.ans = "ok",
                              !.outStamps = stamps[g] + 1]
    /\ wrote' = {g}
    /\ UNCHANGED <<issued, code, goal, red, sgoal>>

\* RedeemNotFull: [Redeem] on a punch card whose stamps do not equal its goal
\* answers not-full and writes nothing (Operation 12).
RedeemNotFull(g) ==
    /\ issued[g]
    /\ stamps[g] # goal[g]
    /\ last' = [NoCall EXCEPT !.op = "redeem", !.card = g, !.code = code[g],
                              !.ans = "not-full"]
    /\ wrote' = {}
    /\ UNCHANGED <<issued, code, goal, stamps, red, sgoal>>

\* RedeemLands: [Redeem] on a punch card whose stamps equal its goal sets the
\* stamps to zero (Operation 13) and the redemptions to the redemptions plus
\* one (Operation 14), and answers the new redemptions (Operation 15); the
\* code and the goal stand.
RedeemLands(g) ==
    /\ issued[g]
    /\ stamps[g] = goal[g]
    /\ stamps' = [stamps EXCEPT ![g] = 0]
    /\ red' = [red EXCEPT ![g] = red[g] + 1]
    /\ last' = [NoCall EXCEPT !.op = "redeem", !.card = g, !.code = code[g], !.ans = "ok",
                              !.outRed = red[g] + 1]
    /\ wrote' = {g}
    /\ UNCHANGED <<issued, code, goal, sgoal>>

\* ReadKnown: [Read] of the card id r, naming the punch card g, answers its
\* card id, goal, stamps and redemptions, never its code (Operation 17, 18),
\* and writes nothing (Operation 19).
ReadKnown(r, g) ==
    /\ issued[g]
    /\ SameId(r, g)
    /\ last' = [NoCall EXCEPT !.op = "read", !.idIn = r, !.card = g, !.ans = "ok",
                              !.outId = g, !.outGoal = goal[g], !.outStamps = stamps[g],
                              !.outRed = red[g]]
    /\ wrote' = {}
    /\ UNCHANGED <<issued, code, goal, stamps, red, sgoal>>

\* ReadUnknown: [Read] of a card id naming no punch card answers not-known
\* (Operation 16).
ReadUnknown(r) ==
    /\ ~(\E g \in Ids : issued[g] /\ SameId(r, g))
    /\ last' = [NoCall EXCEPT !.op = "read", !.idIn = r, !.ans = "not-known"]
    /\ wrote' = {}
    /\ UNCHANGED <<issued, code, goal, stamps, red, sgoal>>

\* Next: a restart, or any call of the five actions, admitted or refused as
\* the page says.
Next ==
    \/ \E s \in StampGoals : Restart(s)
    \/ \E g \in Ids, k \in Codes : Issue(g, k)
    \/ \E g \in Ids : CheckKnown(g)
    \/ \E o \in {"check", "stamp", "redeem"}, k \in Codes : CodeUnknown(o, k)
    \/ \E g \in Ids : StampFull(g)
    \/ \E g \in Ids : StampLands(g)
    \/ \E g \in Ids : RedeemNotFull(g)
    \/ \E g \in Ids : RedeemLands(g)
    \/ \E r \in ReadIds, g \in Ids : ReadKnown(r, g)
    \/ \E r \in ReadIds : ReadUnknown(r)

\* Spec: every behaviour from Init by Next steps.
Spec == Init /\ [][Next]_vars

\* RedemptionBound: the search stops past MaxRedemptions redemptions per punch
\* card (see BOUNDS); a bound on the search, not a rule of the page.
RedemptionBound == \A g \in Ids : red[g] <= MaxRedemptions

\* ---------------------------------------------------------------------------
\* Checks (the verification surface)
\* ---------------------------------------------------------------------------

\* State2_NeverRemoved: no step removes an issued punch card, a redeemed one
\* included: one punch card serves a customer for good (State 2).
State2_NeverRemoved ==
    [][\A g \in Ids : issued[g] => issued'[g]]_vars

\* Inv2_1_CodeKept: no step changes the card code of an issued punch card, a
\* redeemed one included (Invariant 2.1, Check 4.1).
Inv2_1_CodeKept ==
    [][\A g \in Ids : issued[g] => code'[g] = code[g]]_vars

\* Inv2_2_GoalKept: no step changes the goal of an issued punch card, a
\* restart that reads another stamp goal included: the café's c3 keeps its
\* six (Invariant 2.2, Check 4.2).
Inv2_2_GoalKept ==
    [][\A g \in Ids : issued[g] => goal'[g] = goal[g]]_vars

\* Inv2_3_RedemptionsNeverFall: no step lowers the redemptions of an issued
\* punch card: it counts every free item it has given (Invariant 2.3, Check
\* 4.3).
Inv2_3_RedemptionsNeverFall ==
    [][\A g \in Ids : issued[g] => red'[g] >= red[g]]_vars

\* Inv3_1_RefusedStampKeepsStamps: a [Stamp] step that answers a refusal
\* (not-known, full) leaves every punch card's stamps as they were (Invariant
\* 3.1).
Inv3_1_RefusedStampKeepsStamps ==
    [][(last'.op = "stamp" /\ last'.ans # "ok") => stamps' = stamps]_vars

\* Inv3_2_RefusedRedeemKeepsStamps: a [Redeem] step that answers a refusal
\* (not-known, not-full) leaves every punch card's stamps as they were
\* (Invariant 3.2).
Inv3_2_RefusedRedeemKeepsStamps ==
    [][(last'.op = "redeem" /\ last'.ans # "ok") => stamps' = stamps]_vars

\* Inv3_3_RefusedRedeemKeepsRedemptions: a [Redeem] step that answers a
\* refusal leaves every punch card's redemptions as they were (Invariant 3.3).
Inv3_3_RefusedRedeemKeepsRedemptions ==
    [][(last'.op = "redeem" /\ last'.ans # "ok") => red' = red]_vars

\* Op1_OneCardPerIssue: an [Issue] step that answers issued records exactly
\* one new punch card; a repeated [Issue] is a second punch card, never two
\* from one call (Operation 1, the Edge case "Indeterminate outcome").
Op1_OneCardPerIssue ==
    [][(last'.op = "issue" /\ last'.ans = "ok")
         => Cardinality({g \in Ids : issued'[g] /\ ~issued[g]}) = 1]_vars

\* Op5_IssueAnswersIdAndCode: an [Issue] that answered issued answered the
\* card id of a punch card it recorded and that punch card's card code, the
\* only answer that ever carries the code (Operation 5).
Op5_IssueAnswersIdAndCode ==
    (last.op = "issue" /\ last.ans = "ok")
        => (last.outId \in Ids /\ issued[last.outId] /\ last.outCode = code[last.outId])

\* Op6_UnknownCodeNotKnown: a [Check Stamps], [Stamp] or [Redeem] presenting a
\* code no punch card carries answered not-known (Operation 6).
Op6_UnknownCodeNotKnown ==
    (last.op \in {"check", "stamp", "redeem"} /\ ~Carried(last.code))
        => last.ans = "not-known"

\* Op7_CheckAnswersStampsAndGoal: a [Check Stamps] that answered a punch card
\* answered its stamps and its goal (Operation 7).
Op7_CheckAnswersStampsAndGoal ==
    (last.op = "check" /\ last.ans = "ok")
        => (last.card \in Ids /\ last.outStamps = stamps[last.card]
            /\ last.outGoal = goal[last.card])

\* Op8_CheckStampsWritesNothing: a [Check Stamps] step writes no record and
\* changes no field of any punch card (Operation 8).
Op8_CheckStampsWritesNothing ==
    [][last'.op = "check" => (wrote' = {} /\ UNCHANGED records)]_vars

\* Op9_FullStampRefused: a [Stamp] naming a punch card whose stamps equal its
\* goal answers full: a stamp never rolls into the next free item (Operation
\* 9; the Decisions entry's rejected roll-over).
Op9_FullStampRefused ==
    [][(last'.op = "stamp" /\ last'.card \in Ids
            /\ stamps[last'.card] = goal[last'.card])
         => last'.ans = "full"]_vars

\* Op10_StampAddsOne: a [Stamp] naming a punch card whose stamps are below its
\* goal lands, and the stamps rise by exactly one (Operation 10).
Op10_StampAddsOne ==
    [][(last'.op = "stamp" /\ last'.card \in Ids
            /\ stamps[last'.card] < goal[last'.card])
         => (last'.ans = "ok" /\ stamps'[last'.card] = stamps[last'.card] + 1)]_vars

\* Op11_StampAnswersNewStamps: a [Stamp] that landed answered the stamps the
\* punch card carries after it (Operation 11).
Op11_StampAnswersNewStamps ==
    (last.op = "stamp" /\ last.ans = "ok")
        => (last.card \in Ids /\ last.outStamps = stamps[last.card])

\* Op12_NotFullRedeemRefused: a [Redeem] naming a punch card whose stamps do
\* not equal its goal answers not-full: one full punch card gives one free
\* item (Operation 12, the Edge case "Concurrency").
Op12_NotFullRedeemRefused ==
    [][(last'.op = "redeem" /\ last'.card \in Ids
            /\ stamps[last'.card] # goal[last'.card])
         => last'.ans = "not-full"]_vars

\* Op13_RedeemEmpties: a [Redeem] that landed leaves the punch card's stamps at
\* zero, so it starts on the next goal (Operation 13).
Op13_RedeemEmpties ==
    [][(last'.op = "redeem" /\ last'.ans = "ok")
         => (last'.card \in Ids /\ stamps'[last'.card] = 0)]_vars

\* Op14_RedeemCountsOne: a [Redeem] naming a punch card whose stamps equal its
\* goal lands, and its redemptions rise by exactly one (Operation 14).
Op14_RedeemCountsOne ==
    [][(last'.op = "redeem" /\ last'.card \in Ids
            /\ stamps[last'.card] = goal[last'.card])
         => (last'.ans = "ok" /\ red'[last'.card] = red[last'.card] + 1)]_vars

\* Op15_RedeemAnswersNewRedemptions: a [Redeem] that landed answered the
\* redemptions the punch card carries after it (Operation 15).
Op15_RedeemAnswersNewRedemptions ==
    (last.op = "redeem" /\ last.ans = "ok")
        => (last.card \in Ids /\ last.outRed = red[last.card])

\* Op16_UnknownIdNotKnown: a [Read] of a card id no punch card carries,
\* compared codepoint for codepoint, answered not-known: P1 names nothing
\* where only p1 was issued (Operation 16, Identity 10).
Op16_UnknownIdNotKnown ==
    (last.op = "read" /\ ~IdCarried(last.idIn)) => last.ans = "not-known"

\* Op17_ReadAnswersCard: a [Read] that answered a punch card answered the card
\* id it was given and that punch card's goal, stamps and redemptions, the
\* goal the punch card carries, not the stamp goal now in force (Operation
\* 17; the café example).
Op17_ReadAnswersCard ==
    (last.op = "read" /\ last.ans = "ok")
        => (last.outId \in Ids /\ last.outId = last.idIn /\ issued[last.outId]
            /\ last.outGoal = goal[last.outId] /\ last.outStamps = stamps[last.outId]
            /\ last.outRed = red[last.outId])

\* Op18_ReadNeverAnswersCode: a [Read] answer carries no card code: the shop's
\* records never hold what stamps and redeems the punch card (Operation 18).
Op18_ReadNeverAnswersCode ==
    last.op = "read" => last.outCode = NoCode

\* Op19_ReadWritesNothing: a [Read] step writes no record and changes no field
\* of any punch card (Operation 19).
Op19_ReadWritesNothing ==
    [][last'.op = "read" => (wrote' = {} /\ UNCHANGED records)]_vars

====
