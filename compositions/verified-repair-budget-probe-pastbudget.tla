---- MODULE verified-repair-budget-probe-pastbudget ----
\* EXPECT: violation — reachability probe: no round past the budget is ever written.
\* Grace Commons — Verified Repair, the round budget. Spec-level formal sibling of
\* compositions/verified-repair.md; the commit path is verified-repair.tla and the
\* round's settling verified-repair-settle.tla. Derived validator; the English spec is
\* the single source of truth. On any disagreement, diagnose per the entry *The conflict
\* protocol* in pressure-testing.md.
\*
\* ONE page with a round budget of Budget. [Freeze] calls race to open rounds on it, the
\* maintainer may record a ruling naming the page alone, [Report] counts a verdict
\* toward a round, and a round with a counted verdict may become clean, which restarts
\* the page's count.
\*
\* THE JOURNAL  as in verified-repair-settle.tla: every record takes the next position in
\* the journal's order when it is written and becomes readable no later than W ticks
\* after, not in the journal's order; a read shows the records that have landed; time is
\* each record's age, capped, so the state space is bounded by the records alone. The
\* clock offset allowance is 0, so the settle bound equals W.
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
\* WHAT CARRIES IT  [Freeze]'s budget check (Action wiring 34) reads a count that can
\* miss a round still landing, so two [Freeze] calls that read one count both write a
\* round, and a standing ruling admits every [Freeze] that reads it while it stands
\* (Probe_NeverPastBudget is rejected). What holds the budget is [Report]: it reads the
\* round's position and ruled state only once the round's record is older than the settle
\* bound (Action wiring 58), when every round written ahead of it has landed, and refuses
\* a round past the budget that is not ruled (Action wiring 48).
\*
\* NOT MODELED
\*   - How a round becomes clean: any round with a counted verdict may become clean at any
\*     time, and a read shows it at once. The page asks more of a clean round (Term clean
\*     round), so this admits every clean round the page admits and more; a clean round a
\*     read shows late only raises the count it reads.
\*   - The rest of [Report]: one verdict counts per round, and the refusals other than
\*     Action wiring 48 and 58 are verified-repair-settle.tla's or write nothing here.
\*   - Escalations: [Freeze]'s budget-spent escalation writes nothing a count reads.
\*   - A retried [Rule] call, which writes a second ruling (Ledger 2026-10-17-aj): two
\*     rulings are two rulings here, each admitting its own round.
\*   - Purges: every record stays inside the retention period.
\*
\* TWINS AND PROBES  Each is this module byte for byte below its header, with one
\* constant or one invariant changed in its .cfg: -buggy-young, -buggy-unbounded,
\* -buggy-ruledany; -probe-pastbudget, -probe-ruled, -probe-reset.
EXTENDS Naturals, FiniteSets

\* Budget         the round budget every round's record carries.
\* W              the journal write bound: a record is readable once W ticks have passed
\*                since it was written. The settle bound is W here.
\* SettleBound    how old the round's record must be before [Report] reads its position
\*                (Action wiring 58). The page: W.
\* ReportGate     TRUE: [Report] refuses a round past the budget that is not ruled
\*                (Action wiring 48).
\* RuledNeedsGap  TRUE: [Report] reads a round as ruled only where it follows a ruling
\*                with no other round between them (Term ruled round). FALSE: [Report]
\*                reads any round after a ruling as ruled.
\* MaxRounds, MaxRulings  the [Freeze] and [Rule] calls that write a record.
CONSTANTS Budget, W, SettleBound, ReportGate, RuledNeedsGap, MaxRounds, MaxRulings

Cap == IF W > SettleBound THEN W ELSE SettleBound
MaxRec == MaxRounds + MaxRulings
Slots == 1..MaxRec

VARIABLES
    jT,       \* jT[s]: the record at journal position s — none, round or ruling
    jN,       \* jN[s]: for a ruling, the position of the page's latest round its read
              \* showed; 0 for none
    jL,       \* jL[s]: whether the record has landed, so a read shows it
    jG,       \* jG[s]: its age in ticks, capped at Cap
    cnt,      \* cnt[s]: a verdict has counted toward the round at position s
    clean,    \* clean[s]: the round at position s is clean
    nextSeq   \* the position the next record takes
vars == <<jT, jN, jL, jG, cnt, clean, nextSeq>>

TypeOK ==
    /\ jT \in [Slots -> {"none", "round", "ruling"}]
    /\ jN \in [Slots -> 0..MaxRec]
    /\ jL \in [Slots -> BOOLEAN]
    /\ jG \in [Slots -> 0..Cap]
    /\ cnt \in [Slots -> BOOLEAN]
    /\ clean \in [Slots -> BOOLEAN]
    /\ nextSeq \in 1..(MaxRec + 1)

Init ==
    /\ jT = [s \in Slots |-> "none"]
    /\ jN = [s \in Slots |-> 0]
    /\ jL = [s \in Slots |-> FALSE]
    /\ jG = [s \in Slots |-> 0]
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
\* The ruled state [Report] reads: with RuledNeedsGap = FALSE, any ruling ahead of it.
ReportRuled(x, p) ==
    IF RuledNeedsGap THEN Ruled(x, p) ELSE \E g \in Slots : IsRuling(x, g) /\ g < p

\* The page's latest round in the view; 0 for none.
IsLatest(x, p) == IsRound(x, p) /\ ~(\E v \in Slots : p < v /\ IsRound(x, v))
LatestIs(x, p) == IF p = 0 THEN ~(\E v \in Slots : IsRound(x, v)) ELSE IsLatest(x, p)

\* Term standing ruling: a ruling whose named round is still the page's latest.
Standing(x) == \E g \in Slots : IsRuling(x, g) /\ LatestIs(x, jN[g])

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
    /\ (~CountAtBudget("seen") \/ Standing("seen"))
    /\ jT' = [jT EXCEPT ![nextSeq] = "round"]
    /\ nextSeq' = nextSeq + 1
    /\ UNCHANGED <<jN, jL, jG, cnt, clean>>

\* [Rule], naming the page alone: the ruling carries the page's latest round as its read
\* shows it (Action wiring 39).
Rule ==
    /\ nextSeq <= MaxRec
    /\ Cardinality({s \in Slots : jT[s] = "ruling"}) < MaxRulings
    /\ jT' = [jT EXCEPT ![nextSeq] = "ruling"]
    /\ \E p \in 0..MaxRec : LatestIs("seen", p) /\ jN' = [jN EXCEPT ![nextSeq] = p]
    /\ nextSeq' = nextSeq + 1
    /\ UNCHANGED <<jL, jG, cnt, clean>>

\* [Report] on a round its caller holds the id of, so the round's record has landed. It
\* answers too-young while the round's record is younger than SettleBound (Action wiring
\* 58) and budget-spent for a round past the budget that is not ruled (48); otherwise
\* the verdict counts.
Report(p) ==
    /\ IsRound("seen", p)
    /\ ~cnt[p]
    /\ jG[p] >= SettleBound
    /\ ReportGate => (~PositionExceeds("seen", p) \/ ReportRuled("seen", p))
    /\ cnt' = [cnt EXCEPT ![p] = TRUE]
    /\ UNCHANGED <<jT, jN, jL, jG, clean, nextSeq>>

\* A round with a counted verdict becomes clean.
Clean(p) ==
    /\ cnt[p]
    /\ ~clean[p]
    /\ clean' = [clean EXCEPT ![p] = TRUE]
    /\ UNCHANGED <<jT, jN, jL, jG, cnt, nextSeq>>

\* A written record lands: a read now shows it.
Land(s) ==
    /\ jT[s] # "none"
    /\ ~jL[s]
    /\ jL' = [jL EXCEPT ![s] = TRUE]
    /\ UNCHANGED <<jT, jN, jG, cnt, clean, nextSeq>>

\* Time passes, ageing every record. A record is readable once W ticks have passed since
\* it was written, so an unlanded record whose age would reach W lands first.
Tick ==
    /\ \A s \in Slots : (jT[s] # "none" /\ ~jL[s]) => jG[s] + 1 < W
    /\ \E s \in Slots : jT[s] # "none" /\ jG[s] < Cap
    /\ jG' = [s \in Slots |-> IF jT[s] # "none" /\ jG[s] < Cap THEN jG[s] + 1 ELSE jG[s]]
    /\ UNCHANGED <<jT, jN, jL, cnt, clean, nextSeq>>

Next ==
    \/ Freeze
    \/ Rule
    \/ \E p \in Slots : Report(p)
    \/ \E p \in Slots : Clean(p)
    \/ \E s \in Slots : Land(s)
    \/ Tick

Spec == Init /\ [][Next]_vars

\* --- invariant, read off every record written ---

\* Invariant 8.1: a counted verdict's round is within the budget or ruled.
Inv8_1 ==
    \A p \in Slots : cnt[p] => (~PositionExceeds("all", p) \/ Ruled("all", p))

\* --- reachability probes: deliberate falsehoods the checker must reject ---

\* No round past the budget is ever written. Rejected: [Freeze]'s read can miss a round.
Probe_NeverPastBudget ==
    \A p \in Slots : IsRound("all", p) => (~PositionExceeds("all", p) \/ Ruled("all", p))

\* No ruled round past the budget ever counts. Rejected: a ruling admits one round.
Probe_NeverRuledCounted ==
    \A p \in Slots : (cnt[p] /\ PositionExceeds("all", p)) => ~Ruled("all", p)

\* No round counts after a clean round ahead of it. Rejected: a clean round restarts the
\* count.
Probe_NeverResetCounted ==
    \A p \in Slots : cnt[p] => NoCleanBefore("all", p)

====
