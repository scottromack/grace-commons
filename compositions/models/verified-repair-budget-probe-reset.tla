---- MODULE verified-repair-budget-probe-reset ----
\* EXPECT: violation — reachability probe: no round counts after a clean round ahead of it.
\* Grace Commons — Verified Repair, the round budget. Spec-level formal sibling of
\* compositions/verified-repair.md; the commit path is verified-repair.tla and the
\* round's settling verified-repair-settle.tla. Derived validator; the English spec is
\* the single source of truth. On any disagreement, diagnose per the entry *The conflict
\* protocol* in pressure-testing.md.
\*
\* ONE page with a round budget of Budget. [Freeze] calls open rounds on it, the
\* maintainer may record a ruling naming the page alone, [Report] counts a verdict
\* toward a round, and a round with a counted verdict may become clean, which restarts
\* the page's count.
\*
\* THE JOURNAL  as in verified-repair-settle.tla: a call's read and its own record are
\* one step (Execution Contract Database 2), and a record is readable once it is written,
\* at the next position in the journal's order (Execution Contract Database 3), so a read
\* shows every record written. With Store2 = FALSE a record becomes readable some time
\* after it is written, and not in the journal's order: the store the page no longer
\* meets, kept for the vacuity twin. No rule here reads the clock.
\*
\* THE TERMS  Read over a view of the journal: the round count is the number of rounds
\* after the page's latest clean round (Term round count); a round's position is the
\* number of rounds after the latest clean round ahead of it, up to and including it
\* (Term round position); a ruled round is a round written after a ruling with no other
\* round between them (Term ruled round); a ruling stands while the round it named is
\* still the page's latest (Term standing ruling).
\*
\* WHAT THIS MODEL CHECKS
\*   Inv8_1  no verdict counts toward a round whose position in the journal, every record
\*           included, exceeds the budget, unless the round is a ruled round (Invariant
\*           8.1, Check 8.1). The page states the invariant on the position the verdict's
\*           record carries; this reads it off the journal itself, so that a position read
\*           short is caught.
\*
\* WHAT CARRIES IT  [Freeze]'s budget check (Action wiring 34) reads the round count
\* inside the transaction that writes its round, so two [Freeze] calls never write a
\* round each on one count, and a standing ruling admits one [Freeze], since the round
\* that freeze writes is the page's latest from then on. A round past the budget is
\* written only where a ruling stands, and that round is a ruled round. [Report] reads
\* nothing of the budget: a position only falls as a round ahead of it becomes clean.
\* On a store that showed a round late, [Freeze]'s read could miss a round still
\* landing and two freezes wrote a round each on one count; until 2026-10-21 [Report]
\* held the budget, reading the round's position only once the round's record was older
\* than the settle bound and refusing a round past the budget that was not ruled.
\*
\* NOT MODELED
\*   - How a round becomes clean: any round with a counted verdict may become clean at any
\*     time, and a read shows it at once. The page asks more of a clean round (Term clean
\*     round), so this admits every clean round the page admits and more; a clean round a
\*     read shows late only raises the count it reads.
\*   - The rest of [Report]: one verdict counts per round, and its refusals are
\*     verified-repair-settle.tla's or write nothing here.
\*   - Escalations: [Freeze]'s budget-spent escalation writes nothing a count reads.
\*   - A retried [Rule] call, which writes a second ruling (Ledger 2026-10-17-aj): two
\*     rulings are two rulings here, each admitting its own round.
\*   - Purges: every record stays inside the retention period.
\*
\* RETIRED 2026-10-21, with Action wiring 48 and 58: -buggy-young ([Report] reading the
\* position before the round's record was older than the settle bound; no bound is read
\* now) and -probe-pastbudget (a round past the budget never written, which holds here,
\* since only a ruled round is written past it). -buggy-unbounded and -buggy-ruledany
\* now take the budget check and the standing ruling's spend off [Freeze].
\*
\* TWINS AND PROBES  Each is this module byte for byte below its header, with one
\* constant or one invariant changed in its .cfg: -buggy-unbounded, -buggy-ruledany,
\* -buggy-stale; -probe-ruled, -probe-reset.
EXTENDS Naturals, FiniteSets

\* Budget         the round budget every round's record carries.
\* Store2         TRUE: a call's read and its record are one step, and the record is
\*                readable once written (the page's store). FALSE: a record lands some
\*                time after it is written, not in the journal's order.
\* FreezeGate     TRUE: [Freeze] answers budget-spent where the page's round count has
\*                reached the budget and no ruling stands (Action wiring 34). FALSE:
\*                [Freeze] writes a round whatever the count.
\* StandingSpent  TRUE: a ruling stands only while the round it named is still the page's
\*                latest (Term standing ruling). FALSE: every ruling written stands.
\* MaxRounds, MaxRulings  the [Freeze] and [Rule] calls that write a record.
CONSTANTS Budget, Store2, FreezeGate, StandingSpent, MaxRounds, MaxRulings

MaxRec == MaxRounds + MaxRulings
Slots == 1..MaxRec

VARIABLES
    jT,       \* jT[s]: the record at journal position s — none, round or ruling
    jN,       \* jN[s]: for a ruling, the position of the page's latest round its read
              \* showed; 0 for none
    jL,       \* jL[s]: whether the record has landed, so a read shows it
    cnt,      \* cnt[s]: a verdict has counted toward the round at position s
    clean,    \* clean[s]: the round at position s is clean
    nextSeq   \* the position the next record takes
vars == <<jT, jN, jL, cnt, clean, nextSeq>>

TypeOK ==
    /\ jT \in [Slots -> {"none", "round", "ruling"}]
    /\ jN \in [Slots -> 0..MaxRec]
    /\ jL \in [Slots -> BOOLEAN]
    /\ cnt \in [Slots -> BOOLEAN]
    /\ clean \in [Slots -> BOOLEAN]
    /\ nextSeq \in 1..(MaxRec + 1)

Init ==
    /\ jT = [s \in Slots |-> "none"]
    /\ jN = [s \in Slots |-> 0]
    /\ jL = [s \in Slots |-> FALSE]
    /\ cnt = [s \in Slots |-> FALSE]
    /\ clean = [s \in Slots |-> FALSE]
    /\ nextSeq = 1

\* --- the Terms, over a view: "all", every record written, or "seen", what a read shows ---
In(x, s) == jT[s] # "none" /\ (x = "all" \/ jL[s])
IsRound(x, s) == In(x, s) /\ jT[s] = "round"
IsRuling(x, s) == In(x, s) /\ jT[s] = "ruling"

\* Whether u is the latest clean round of the view ahead of position p.
LatestCleanBefore(x, u, p) ==
    /\ u < p
    /\ IsRound(x, u)
    /\ clean[u]
    /\ ~(\E v \in Slots : u < v /\ v < p /\ IsRound(x, v) /\ clean[v])
NoCleanBefore(x, p) == ~(\E u \in Slots : u < p /\ IsRound(x, u) /\ clean[u])

\* Term round position: of the round at position p, the rounds after the latest clean
\* round ahead of it, up to and including it, each counted once.
After(x, s, p) ==
    \/ NoCleanBefore(x, p)
    \/ \E u \in Slots : LatestCleanBefore(x, u, p) /\ u < s
Counted(x, s, p) == IsRound(x, s) /\ s <= p /\ After(x, s, p)
\* The position exceeds the budget: more than Budget rounds are counted for p. Positions
\* are only compared with the budget, so counting to Budget + 1 is enough (Budget 0 to 2).
PositionExceeds(x, p) ==
    IF Budget = 0 THEN \E a \in Slots : Counted(x, a, p)
    ELSE IF Budget = 1 THEN \E a, b \in Slots : a < b /\ Counted(x, a, p) /\ Counted(x, b, p)
    ELSE \E a, b, c \in Slots : a < b /\ b < c /\ Counted(x, a, p) /\ Counted(x, b, p) /\ Counted(x, c, p)

\* Term ruled round: a ruling ahead of the round, with no other round between them.
Ruled(x, p) ==
    \E g \in Slots :
        /\ IsRuling(x, g)
        /\ g < p
        /\ ~(\E v \in Slots : g < v /\ v < p /\ IsRound(x, v))

\* The page's latest round in the view; 0 for none.
IsLatest(x, p) == IsRound(x, p) /\ ~(\E v \in Slots : p < v /\ IsRound(x, v))
LatestIs(x, p) == IF p = 0 THEN ~(\E v \in Slots : IsRound(x, v)) ELSE IsLatest(x, p)

\* Term standing ruling: a ruling whose named round is still the page's latest. With
\* StandingSpent = FALSE, any ruling written.
Standing(x) ==
    IF StandingSpent THEN \E g \in Slots : IsRuling(x, g) /\ LatestIs(x, jN[g])
    ELSE \E g \in Slots : IsRuling(x, g)

\* Term round count reaching the budget: the rounds after the page's latest clean round
\* number Budget or more.
CountAtBudget(x) ==
    LET p == MaxRec + 1
    IN IF Budget = 0 THEN TRUE
       ELSE IF Budget = 1 THEN \E a \in Slots : Counted(x, a, p)
       ELSE \E a, b \in Slots : a < b /\ Counted(x, a, p) /\ Counted(x, b, p)

\* --- actions; each call's refusals are read off what its read shows ---

\* [Freeze] answers budget-spent where the page's round count has reached the budget and
\* no ruling stands (Action wiring 34); otherwise it writes the round.
Freeze ==
    /\ nextSeq <= MaxRec
    /\ Cardinality({s \in Slots : jT[s] = "round"}) < MaxRounds
    /\ FreezeGate => (~CountAtBudget("seen") \/ Standing("seen"))
    /\ jT' = [jT EXCEPT ![nextSeq] = "round"]
    /\ jL' = [jL EXCEPT ![nextSeq] = Store2]
    /\ nextSeq' = nextSeq + 1
    /\ UNCHANGED <<jN, cnt, clean>>

\* [Rule], naming the page alone: the ruling carries the page's latest round as its read
\* shows it (Action wiring 39).
Rule ==
    /\ nextSeq <= MaxRec
    /\ Cardinality({s \in Slots : jT[s] = "ruling"}) < MaxRulings
    /\ jT' = [jT EXCEPT ![nextSeq] = "ruling"]
    /\ \E p \in 0..MaxRec : LatestIs("seen", p) /\ jN' = [jN EXCEPT ![nextSeq] = p]
    /\ jL' = [jL EXCEPT ![nextSeq] = Store2]
    /\ nextSeq' = nextSeq + 1
    /\ UNCHANGED <<cnt, clean>>

\* [Report] on a round its caller holds the id of, so the round's record has landed:
\* the verdict counts.
Report(p) ==
    /\ IsRound("seen", p)
    /\ ~cnt[p]
    /\ cnt' = [cnt EXCEPT ![p] = TRUE]
    /\ UNCHANGED <<jT, jN, jL, clean, nextSeq>>

\* A round with a counted verdict becomes clean.
Clean(p) ==
    /\ cnt[p]
    /\ ~clean[p]
    /\ clean' = [clean EXCEPT ![p] = TRUE]
    /\ UNCHANGED <<jT, jN, jL, cnt, nextSeq>>

\* A written record lands: a read now shows it. With Store2 every record landed as it
\* was written, so this step never runs.
Land(s) ==
    /\ jT[s] # "none"
    /\ ~jL[s]
    /\ jL' = [jL EXCEPT ![s] = TRUE]
    /\ UNCHANGED <<jT, jN, cnt, clean, nextSeq>>

Next ==
    \/ Freeze
    \/ Rule
    \/ \E p \in Slots : Report(p)
    \/ \E p \in Slots : Clean(p)
    \/ \E s \in Slots : Land(s)

Spec == Init /\ [][Next]_vars

\* --- invariant, read off every record written ---

\* Invariant 8.1: a counted verdict's round is within the budget or ruled.
Inv8_1 ==
    \A p \in Slots : cnt[p] => (~PositionExceeds("all", p) \/ Ruled("all", p))

\* --- reachability probes: deliberate falsehoods the checker must reject ---

\* No ruled round past the budget ever counts. Rejected: a ruling admits one round.
Probe_NeverRuledCounted ==
    \A p \in Slots : (cnt[p] /\ PositionExceeds("all", p)) => ~Ruled("all", p)

\* No round counts after a clean round ahead of it. Rejected: a clean round restarts the
\* count.
Probe_NeverResetCounted ==
    \A p \in Slots : cnt[p] => NoCleanBefore("all", p)

====
