---- MODULE verified-repair-settle-probe-opens ----
\* EXPECT: violation — reachability probe: [Repair] never opens.
\* Grace Commons — Verified Repair, the round's settling. Spec-level formal sibling of
\* compositions/verified-repair.md; the commit path is verified-repair.tla and the round
\* budget verified-repair-budget.tla. Derived validator; the English spec is the single
\* source of truth. On any disagreement, diagnose per the entry *The conflict protocol*
\* in pressure-testing.md.
\*
\* ONE round, its record already older than the settle bound, and ONE reader pass,
\* which two verifiers race to report. A sound verdict carries no finding or one; a
\* malformed verdict carries one. Three triagers sort the findings. One [Repair] call
\* reads the round's records and, where the round reads as settled, opens.
\*
\* THE JOURNAL  Every record takes the next position in the journal's order when it is
\* written, and becomes readable some time after, no later than the journal write bound
\* W after it was written (Recoverable Invocation Capability requirement 7, 8), but not
\* in the journal's order: a read can show a record and miss one ahead of it. A read
\* shows exactly the records that have landed. Time is each record's age in ticks,
\* capped at the largest bound read, so the model has no horizon and its state space is
\* bounded by its records alone. The clock offset allowance is 0, so the settle bound
\* equals W.
\*
\* THE TERMS are read the way the page defines them, at each prefix of the journal's
\* order: a fold walks a view of the journal from the first position to the last and
\* carries, after each record, the counted verdict (the earliest sound verdict, Term
\* counted verdict), the counted findings (the counted verdict's and every malformed
\* verdict's, Term counted finding), the earliest counted triage of each finding in each
\* role (a triage record whose triager holds no earlier record of the finding in another
\* role, Term counted triage), and from those the settled triage, the parted findings
\* and the foundational count. The first record after which the round carries a counted
\* verdict and every counted finding carries a settled triage, a counted second where the
\* count is zero (Action wiring 11) and a counted third where the finding is parted
\* (Action wiring 14), is the settling record (Term settled round, Term settling record).
\* Two views are folded: what a read shows, the landed records (SeenFold, kept as the
\* variable seen), and the whole journal, every record written (WholeFold), which a read
\* shows in full once every record has landed. The calls read the first; the invariants
\* read the second.
\*
\* WHAT THIS MODEL CHECKS
\*   Inv1_1  no [Repair] intent precedes, in the journal's order, the record at which the
\*           round settles (Invariant 1.1, Check 1.1).
\*   Inv5_1  where the round settles with a foundational count of zero, every counted
\*           finding of the round carries a counted first triage and a counted second
\*           triage, the earliest of each by two triagers (Invariant 5.1, Check 5.1).
\*
\* WHAT THE MODEL FOUND  As the page stood at e54d344, Term counted finding read
\* every malformed verdict of the round, and a reader's malformed verdict can be written
\* after the round's settling record: [Report] refuses already-counted and round-closed
\* only from what its read shows (Action wiring 5, 47), and the counted verdict, or the
\* settling record, may not have landed. Its finding is then a counted finding no counted
\* triage can reach, since a triage record later than the settling record counts for
\* nothing, so a zero count that decides the round rests on no triage of it and Check 5.1
\* fails on a council that kept every rule (three states: a clean verdict written, a
\* malformed one written beside it). LateFindings = TRUE is that page; the page now reads
\* the counted findings up to the settling record.
\*
\* NOT MODELED
\*   - Refusals that cannot change which records are written: Primitive policy, Action
\*     wiring 4 (one snapshot here), 9 and the formal-engine arm of 35 (no engine
\*     reports), 58 (the round's record is old), and every [Repair] refusal after Action
\*     wiring 31 and 52.
\*   - Three reader passes: one is modelled. Settling waits for a counted verdict of each
\*     pass, and the race of two verifiers on one pass is the same race on each.
\*   - Kind, blame, side, disposition and patch: a triage record's class is foundational
\*     with a disposition other than reject, or not, which is all the count and the
\*     parting read; a parting on side or disposition is a parting on class here.
\*   - Purges: every record stays inside the retention period.
\*   - The pause between a call's read and its own record: the read and the write are one
\*     step and the record lands up to W later, so a longer pause is a longer flight,
\*     which the landing order covers.
\*
\* THE BUDGET  Each verifier reports once. MaxTriage triage records in all, from any
\* triager in any role, so a third triager, a second record by one triager in another
\* role and a race of two first triages each fit. Two symmetries are broken, since
\* nothing here tells the verifiers apart or the triagers apart: verifier 2 reports
\* only once verifier 1 has, and triager t2 sorts only once t1 has, t3 once t2 has. Every
\* behaviour is one of these under a renaming, and both invariants survive a renaming.
\*
\* TWINS AND PROBES  Each is this module byte for byte below its header, with one
\* constant or one invariant changed in its .cfg: -buggy-unaged, -buggy-latefinding,
\* -buggy-oneactor, -buggy-onesort; -probe-displaced, -probe-parted, -probe-opens.
EXTENDS Naturals, FiniteSets

\* W              the journal write bound: a record is readable once W ticks have
\*                passed since it was written. The settle bound is W here.
\* SettleBound    how old the settling record must be at [Repair]'s read (Action wiring
\*                52). The page: W.
\* LateFindings   TRUE: a malformed verdict written after the settling record still
\*                carries counted findings (the page at e54d344). FALSE: the
\*                counted findings are read up to the settling record.
\* OneSortPerActor  TRUE: a triage record whose triager holds an earlier record of the
\*                finding in another role is not a counted triage (Term counted triage).
\* SortTwice      TRUE: a zero count settles the round only once every counted finding
\*                carries a counted second triage (Action wiring 11).
\* MaxTriage      triage records in all.
CONSTANTS W, SettleBound, LateFindings, OneSortPerActor, SortTwice, MaxTriage

Verifiers == {1, 2}
Findings == {1, 2}        \* finding f is the one verifier f's verdict carries
Triagers == {1, 2, 3}  \* t1, t2, t3
Roles == {1, 2, 3}        \* first, second, third
Classes == {"F", "R"}     \* F: foundational, with a disposition other than reject
Cap == IF W > SettleBound THEN W ELSE SettleBound
MaxRec == 2 + MaxTriage + 1
Slots == 1..MaxRec
\* A verdict holds "clean" (sound, no finding), "found" (sound, one finding) or "mal"
\* (malformed, one finding); a triage record "tri"; [Repair]'s intent "int".
Types == {"none", "clean", "found", "mal", "tri", "int"}

VARIABLES
    jT,       \* jT[s]: what the record at journal position s is
    jW,       \* jW[s]: its verifier or triager
    jF,       \* jF[s]: the finding a triage record sorts
    jR,       \* jR[s]: a triage record's role
    jC,       \* jC[s]: a triage record's class
    jL,       \* jL[s]: whether the record has landed, so a read shows it
    jG,       \* jG[s]: its age in ticks, capped at Cap
    nextSeq,  \* the position the next record takes
    rpc,      \* [Repair]: idle, read (its read passed Action wiring 31 and 52), opened
    seen      \* the fold of what a read shows, read again whenever a record lands: the
              \* one step that changes what a read shows
vars == <<jT, jW, jF, jR, jC, jL, jG, nextSeq, rpc, seen>>

\* --- the Terms, as a fold over the journal's order ---
\* Triager t1, t2, t3 is written 1, 2, 3 in a record. Two small keys flatten the tables:
\* FR(f, r) names finding f in role r, AF(a, f) triager a on finding f.
FR(f, r) == (f - 1) * 3 + r
AF(a, f) == (a - 1) * 2 + f
Keys == 1..6

\* A fold state carries, after the records read so far:
\*   cv       the counted verdict's position; 0 for none
\*   cf[f]    finding f is a counted finding
\*   ro[AF(a, f)]  the roles triager a has recorded finding f in
\*   ea[FR(f, r)], ec[FR(f, r)]  the triager and class of the earliest counted triage of
\*            finding f in role r; 0 and "-" for none
\*   S        the settling record's position; 0 while the round is unsettled
\*   zeroS, okS, cfS  at the settling record: the count is zero; every counted finding
\*            has a counted first and second by two triagers; the counted findings
\*   late     a malformed verdict after the settling record carries a finding not counted
\*            at it
\*   pt       some finding has been parted at some prefix
Start ==
    [cv |-> 0, cf |-> [f \in Findings |-> FALSE],
     ro |-> [k \in Keys |-> {}],
     ea |-> [k \in Keys |-> 0], ec |-> [k \in Keys |-> "-"],
     S |-> 0, zeroS |-> FALSE, okS |-> FALSE, cfS |-> [f \in Findings |-> FALSE],
     late |-> FALSE, pt |-> FALSE]

\* The earliest counted triage of finding f in role r: its triager and class.
EA(n, f, r) == n.ea[FR(f, r)]
EC(n, f, r) == n.ec[FR(f, r)]
\* Term settled triage: the earliest third, otherwise the earliest second, otherwise the
\* earliest first; HasST(n, f) where there is one, STClass(n, f) its class.
HasST(n, f) == EA(n, f, 1) # 0 \/ EA(n, f, 2) # 0 \/ EA(n, f, 3) # 0
STClass(n, f) ==
    IF EA(n, f, 3) # 0 THEN EC(n, f, 3)
    ELSE IF EA(n, f, 2) # 0 THEN EC(n, f, 2)
    ELSE EC(n, f, 1)
\* Term parted finding: the earliest counted first and second differ on class.
Parted(n, f) == EA(n, f, 1) # 0 /\ EA(n, f, 2) # 0 /\ EC(n, f, 1) # EC(n, f, 2)
\* Term foundational count at zero: no counted finding settles foundational.
ZeroF(n, f) == (n.cf[f] /\ HasST(n, f)) => STClass(n, f) # "F"
Zero(n) == ZeroF(n, 1) /\ ZeroF(n, 2)
\* Term settled round: a counted verdict, and every counted finding with a settled
\* triage, a counted second where the count is zero (Action wiring 11) and a counted
\* third where it is parted (Action wiring 14). The count is passed in as z.
DoneF(n, f, z) ==
    n.cf[f] => /\ HasST(n, f)
               /\ (SortTwice /\ z) => EA(n, f, 2) # 0
               /\ Parted(n, f) => EA(n, f, 3) # 0
SettledNow(n, z) == n.cv # 0 /\ DoneF(n, 1, z) /\ DoneF(n, 2, z)
\* Every counted finding has a counted first and a counted second, by two triagers.
TwoSortsF(n, f) == n.cf[f] => (EA(n, f, 1) # 0 /\ EA(n, f, 2) # 0 /\ EA(n, f, 1) # EA(n, f, 2))
TwoSorts(n) == TwoSortsF(n, 1) /\ TwoSortsF(n, 2)

\* The record at position s read into a fold state: kind t, verifier or triager w,
\* finding f, role r, class c. A triage record counts where its triager has recorded
\* the finding in no other role (Term counted triage).
Read(st, s, t, w, f, r, c) ==
    IF t \in {"clean", "found"} THEN
        IF st.cv # 0 THEN st
        ELSE [st EXCEPT !.cv = s, !.cf = IF t = "found" THEN [st.cf EXCEPT ![w] = TRUE] ELSE st.cf]
    ELSE IF t = "mal" THEN
        [st EXCEPT !.cf = [st.cf EXCEPT ![w] = TRUE]]
    ELSE IF t = "tri" THEN
        IF (~OneSortPerActor \/ st.ro[AF(w, f)] \subseteq {r}) /\ st.ea[FR(f, r)] = 0
          THEN [st EXCEPT !.ro = [st.ro EXCEPT ![AF(w, f)] = st.ro[AF(w, f)] \cup {r}],
                          !.ea = [st.ea EXCEPT ![FR(f, r)] = w],
                          !.ec = [st.ec EXCEPT ![FR(f, r)] = c]]
          ELSE [st EXCEPT !.ro = [st.ro EXCEPT ![AF(w, f)] = st.ro[AF(w, f)] \cup {r}]]
    ELSE st

\* After a record is read: the first time the round is settled, its position is the
\* settling record; a malformed verdict after it whose finding was not counted at it is
\* late; and any parting is noted.
Settle(n, s, z) == [n EXCEPT !.S = s, !.zeroS = z, !.okS = TwoSorts(n), !.cfS = n.cf]
After(n, s, t, w) ==
    IF n.S = 0 /\ SettledNow(n, Zero(n)) THEN Settle(n, s, Zero(n))
    ELSE IF n.S # 0 /\ t = "mal" /\ ~n.cfS[w] THEN [n EXCEPT !.late = TRUE]
    ELSE n
Mark(n) == IF ~n.pt /\ (Parted(n, 1) \/ Parted(n, 2)) THEN [n EXCEPT !.pt = TRUE] ELSE n
Step(st, s, t, w, f, r, c) == Mark(After(Read(st, s, t, w, f, r, c), s, t, w))

\* The fold over what a read shows: positions 1 to 7 in order, a position read only where
\* its record has landed. Every argument is passed in, none read as a free variable.
\* L is what has landed and n the position landing now.
SeenStep(st, s, T, Wh, F, R, C, L, n) ==
    IF s <= MaxRec /\ T[s] # "none" /\ (L[s] \/ s = n) THEN Step(st, s, T[s], Wh[s], F[s], R[s], C[s]) ELSE st
SeenFold(T, Wh, F, R, C, L, n) ==
    SeenStep(SeenStep(SeenStep(SeenStep(SeenStep(SeenStep(SeenStep(
        Start, 1, T, Wh, F, R, C, L, n), 2, T, Wh, F, R, C, L, n), 3, T, Wh, F, R, C, L, n),
        4, T, Wh, F, R, C, L, n), 5, T, Wh, F, R, C, L, n), 6, T, Wh, F, R, C, L, n), 7, T, Wh, F, R, C, L, n)

TypeOK ==
    /\ jT \in [Slots -> Types]
    /\ jW \in [Slots -> Verifiers \cup Triagers \cup {0}]
    /\ jF \in [Slots -> Findings \cup {0}]
    /\ jR \in [Slots -> Roles \cup {0}]
    /\ jC \in [Slots -> Classes \cup {"-"}]
    /\ jL \in [Slots -> BOOLEAN]
    /\ jG \in [Slots -> 0..Cap]
    /\ nextSeq \in 1..(MaxRec + 1)
    /\ rpc \in {"idle", "read", "opened"}
    /\ MaxRec <= 7

Init ==
    /\ jT = [s \in Slots |-> "none"]
    /\ jW = [s \in Slots |-> 0]
    /\ jF = [s \in Slots |-> 0]
    /\ jR = [s \in Slots |-> 0]
    /\ jC = [s \in Slots |-> "-"]
    /\ jL = [s \in Slots |-> FALSE]
    /\ jG = [s \in Slots |-> 0]
    /\ nextSeq = 1
    /\ rpc = "idle"
    /\ seen = Start

\* --- actions; each call's refusals are read off what its read shows, seen ---
\* A call reads the journal and writes its own record in one step; the record lands
\* later (Land), so what a read shows changes only there.

\* A verifier reports. [Report] refuses round-closed where its read shows the round
\* settled (Action wiring 47) and already-counted where it shows a counted verdict, the
\* pass being the one pass (Action wiring 5); otherwise the verdict is written.
Report(v, kind) ==
    /\ (v = 2) => (\E s \in Slots : jT[s] \in {"clean", "found", "mal"} /\ jW[s] = 1)
    /\ nextSeq <= MaxRec
    /\ seen.S = 0
    /\ seen.cv = 0
    /\ ~(\E s \in Slots : jT[s] \in {"clean", "found", "mal"} /\ jW[s] = v)
    /\ jT' = [jT EXCEPT ![nextSeq] = kind]
    /\ jW' = [jW EXCEPT ![nextSeq] = v]
    /\ nextSeq' = nextSeq + 1
    /\ UNCHANGED <<jF, jR, jC, jL, jG, rpc, seen>>

\* A triager sorts a finding. The refusals: round-closed (Action wiring 47); not-known
\* for a finding that is not counted (35); already-triaged where a counted triage of the
\* finding in the role shows (36); a record of the finding in another role under the
\* same triager (37); a second with no counted first (43); a third for a finding not
\* parted (44).
TriageOpen ==
    /\ nextSeq <= MaxRec
    /\ Cardinality({s \in Slots : jT[s] = "tri"}) < MaxTriage
    /\ seen.S = 0
TriageAdmits(f, r) ==
    /\ seen.cf[f]
    /\ EA(seen, f, r) = 0
    /\ r = 2 => EA(seen, f, 1) # 0
    /\ r = 3 => Parted(seen, f)
Triage(a, f, r, c) ==
    /\ (a > 1) => (\E s \in Slots : jT[s] = "tri" /\ jW[s] = a - 1)
    /\ seen.ro[AF(a, f)] \subseteq {r}
    /\ jT' = [jT EXCEPT ![nextSeq] = "tri"]
    /\ jW' = [jW EXCEPT ![nextSeq] = a]
    /\ jF' = [jF EXCEPT ![nextSeq] = f]
    /\ jR' = [jR EXCEPT ![nextSeq] = r]
    /\ jC' = [jC EXCEPT ![nextSeq] = c]
    /\ nextSeq' = nextSeq + 1
    /\ UNCHANGED <<jL, jG, rpc, seen>>

\* A written record lands: a read now shows it.
Land(s) ==
    /\ jT[s] # "none"
    /\ ~jL[s]
    /\ jL' = [jL EXCEPT ![s] = TRUE]
    /\ seen' = IF \E u \in Slots : u > s /\ jL[u]
                 THEN SeenFold(jT, jW, jF, jR, jC, jL, s)
                 ELSE Step(seen, s, jT[s], jW[s], jF[s], jR[s], jC[s])
    /\ UNCHANGED <<jT, jW, jF, jR, jC, jG, nextSeq, rpc>>

\* Time passes, ageing every record. A record is readable once W ticks have passed since
\* it was written, so an unlanded record whose age would reach W lands first.
Tick ==
    /\ \A s \in Slots : (jT[s] # "none" /\ ~jL[s]) => jG[s] + 1 < W
    /\ \E s \in Slots : jT[s] # "none" /\ jG[s] < Cap
    /\ jG' = [s \in Slots |-> IF jT[s] # "none" /\ jG[s] < Cap THEN jG[s] + 1 ELSE jG[s]]
    /\ UNCHANGED <<jT, jW, jF, jR, jC, jL, nextSeq, rpc, seen>>

\* [Repair] reads the round's records (Action wiring 54). It answers unsettled unless the
\* read shows a settling record (Action wiring 31) at least SettleBound old (52).
RepairRead ==
    /\ rpc = "idle"
    /\ seen.S # 0
    /\ jG[seen.S] >= SettleBound
    /\ rpc' = "read"
    /\ UNCHANGED <<jT, jW, jF, jR, jC, jL, jG, nextSeq, seen>>

\* The invocation open writes the intent (Action wiring 22).
RepairOpen ==
    /\ rpc = "read"
    /\ nextSeq <= MaxRec
    /\ jT' = [jT EXCEPT ![nextSeq] = "int"]
    /\ nextSeq' = nextSeq + 1
    /\ rpc' = "opened"
    /\ UNCHANGED <<jW, jF, jR, jC, jL, jG, seen>>

Next ==
    \/ \E v \in Verifiers, kind \in {"clean", "found", "mal"} : Report(v, kind)
    \/ /\ TriageOpen
       /\ \E f \in Findings, r \in Roles :
            /\ TriageAdmits(f, r)
            /\ \E a \in Triagers, c \in Classes : Triage(a, f, r, c)
    \/ \E s \in Slots : Land(s)
    \/ Tick
    \/ RepairRead
    \/ RepairOpen

Spec == Init /\ [][Next]_vars

\* --- invariants, read off the whole journal ---

\* The fold over every record written, landed or not: positions 1 to 7 in order.
WholeStep(st, s, T, Wh, F, R, C) ==
    IF s <= MaxRec /\ T[s] # "none" THEN Step(st, s, T[s], Wh[s], F[s], R[s], C[s]) ELSE st
WholeFold(T, Wh, F, R, C) ==
    WholeStep(WholeStep(WholeStep(WholeStep(WholeStep(WholeStep(WholeStep(
        Start, 1, T, Wh, F, R, C), 2, T, Wh, F, R, C), 3, T, Wh, F, R, C),
        4, T, Wh, F, R, C), 5, T, Wh, F, R, C), 6, T, Wh, F, R, C), 7, T, Wh, F, R, C)
Whole == WholeFold(jT, jW, jF, jR, jC)

\* Invariant 1.1: the round settles at a record ahead of the intent.
Inv1_1 ==
    \A i \in Slots : jT[i] = "int" => (LET w == Whole IN (w.S # 0 /\ w.S < i))

\* Invariant 5.1: a zero count that settles the round rests on a counted first and a
\* counted second triage of every counted finding, the earliest of each by two
\* triagers. With LateFindings, a malformed verdict after the settling record carries
\* a counted finding too, which no counted triage reaches.
Inv5_1 ==
    LET w == Whole IN (w.S # 0 /\ w.zeroS) => (w.okS /\ ~(LateFindings /\ w.late))

\* --- reachability probes: deliberate falsehoods the checker must reject ---

\* A sound verdict never lands after a later sound verdict has landed. Rejected: the
\* counted verdict a read shows can be displaced by an earlier one that lands later.
Probe_NeverDisplaced ==
    ~(\E s, u \in Slots : s < u /\ jT[s] \in {"clean", "found"} /\ jT[u] \in {"clean", "found"} /\ jL[u] /\ ~jL[s])

\* No finding is ever parted. Rejected: third triages are reached.
Probe_NeverParted ==
    ~Whole.pt

\* [Repair] never opens. Rejected: the repair path is reached.
Probe_NeverOpens ==
    rpc # "opened"

====
