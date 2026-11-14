---- MODULE verified-repair-settle-buggy-stale ----
\* BUGGY TWIN: a call's read misses a record written ahead of it, which lands later and not in the journal's order (Execution Contract Database 2 and Database 3 taken away).
\* Grace Commons — Verified Repair, the round's settling. Spec-level formal sibling of
\* compositions/verified-repair.md; the commit path is verified-repair.tla and the round
\* budget verified-repair-budget.tla. Derived validator; the English spec is the single
\* source of truth. On any disagreement, diagnose per the entry *The conflict protocol*
\* in pressure-testing.md.
\*
\* ONE round and ONE reader pass, which two verifiers may both report. A sound verdict
\* carries no finding or one; a malformed verdict carries one. Three triagers sort the
\* findings. One [Repair] call reads the round's records and, where the round reads as
\* settled, opens.
\*
\* THE JOURNAL  The store the page names (Capability requirement 28): a call's read and
\* its own record are one step, the transaction Execution Contract Database 2 puts them in,
\* and a record is readable once it is written, at the next position in the journal's
\* order (Execution Contract Database 3; the journal's appends are serialized), so a read
\* shows every record written. With Store2 = FALSE a record becomes readable some time
\* after it is written, and not in the journal's order, so a read can show a record and
\* miss one ahead of it: the store the page no longer meets, kept for the vacuity twin.
\* No rule here reads the clock, so the model has no time.
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
\* Two views are folded: what a read shows, the landed records (kept as the variable
\* seen), and the whole journal, every record written (WholeFold). The calls read the
\* first; the invariants read the second. With Store2 the two are one view.
\*
\* WHAT THIS MODEL CHECKS
\*   Inv1_1  no [Repair] intent precedes, in the journal's order, the record at which the
\*           round settles (Invariant 1.1, Check 1.1).
\*   Inv5_1  where the round settles with a foundational count of zero, every counted
\*           finding of the round carries a counted first triage and a counted second
\*           triage, the earliest of each by two triagers (Invariant 5.1, Check 5.1).
\*
\* WHAT CARRIES THEM  [Report] and [Triage] answer round-closed where their read shows
\* the round settled (Action wiring 47), and a read shows every record written, so
\* nothing is written behind the settling record but the intent; [Repair] opens only
\* where its read shows the settling record (Action wiring 31, 54). Two verifiers on one
\* pass are answered by [Report]'s already-counted (Action wiring 5), and a triager's
\* second role by [Triage]'s refusal (Action wiring 37).
\*
\* WHAT THE MODEL FOUND  As the page stood at e54d344, Term counted finding read every
\* malformed verdict of the round. On a store that showed a record late, [Report]
\* refused already-counted and round-closed only from what its read showed, so a
\* reader's malformed verdict could be written after the round's settling record, and
\* its finding was a counted finding no counted triage could reach: Check 5.1 failed on
\* a council that kept every rule. The page now reads the counted findings up to the
\* settling record; under Execution Contract Database 2 that verdict is refused
\* round-closed in its own transaction.
\*
\* NOT MODELED
\*   - Refusals that cannot change which records are written: Primitive policy, Action
\*     wiring 4 (one snapshot here), 9 and the formal-engine arm of 35 (no engine
\*     reports), and every [Repair] refusal after Action wiring 31.
\*   - Three reader passes: one is modelled. Settling waits for a counted verdict of each
\*     pass, and two verifiers on one pass meet the same refusals on each.
\*   - Kind, blame, side, disposition and patch: a triage record's class is foundational
\*     with a disposition other than reject, or not, which is all the count and the
\*     parting read; a parting on side or disposition is a parting on class here.
\*   - Purges: every record stays inside the retention period.
\*
\* THE BUDGET  Each verifier reports once. MaxTriage triage records in all, from any
\* triager in any role, so a third triager, a second record by one triager in another
\* role and two first triages each fit. Two symmetries are broken, since nothing here
\* tells the verifiers apart or the triagers apart: verifier 2 reports only once
\* verifier 1 has, and triager t2 sorts only once t1 has, t3 once t2 has. Every
\* behaviour is one of these under a renaming, and both invariants survive a renaming.
\*
\* RETIRED 2026-10-21, with Action wiring 52 and the store that showed a record late:
\* -buggy-unaged ([Repair] reading the round as settled without the settle bound, which
\* is the page now), -buggy-latefinding (the page at e54d344, whose late malformed
\* verdict [Report] now refuses round-closed, so nothing is left for it to count) and
\* -probe-displaced (a sound verdict landing after a later one, which holds here, since
\* a record is readable once it is written).
\*
\* TWINS AND PROBES  Each is this module byte for byte below its header, with one
\* constant or one invariant changed in its .cfg: -buggy-oneactor, -buggy-onesort,
\* -buggy-stale; -probe-parted, -probe-opens.
EXTENDS Naturals, FiniteSets

\* Store2         TRUE: a call's read and its record are one step, and the record is
\*                readable once written (the page's store). FALSE: a record lands some
\*                time after it is written, not in the journal's order.
\* OneSortPerActor  TRUE: [Triage] refuses a record of a finding in another role under
\*                the same triager (Action wiring 37), and such a record is not a
\*                counted triage (Term counted triage).
\* SortTwice      TRUE: a zero count settles the round only once every counted finding
\*                carries a counted second triage (Action wiring 11).
\* MaxTriage      triage records in all.
CONSTANTS Store2, OneSortPerActor, SortTwice, MaxTriage

Verifiers == {1, 2}
Findings == {1, 2}        \* finding f is the one verifier f's verdict carries
Triagers == {1, 2, 3}  \* t1, t2, t3
Roles == {1, 2, 3}        \* first, second, third
Classes == {"F", "R"}     \* F: foundational, with a disposition other than reject
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
    nextSeq,  \* the position the next record takes
    rpc,      \* [Repair]: idle or opened
    seen      \* the fold of what a read shows, read again whenever a record lands
vars == <<jT, jW, jF, jR, jC, jL, nextSeq, rpc, seen>>

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
\*   zeroS, okS  at the settling record: the count is zero; every counted finding has a
\*            counted first and second by two triagers
\*   pt       some finding has been parted at some prefix
Start ==
    [cv |-> 0, cf |-> [f \in Findings |-> FALSE],
     ro |-> [k \in Keys |-> {}],
     ea |-> [k \in Keys |-> 0], ec |-> [k \in Keys |-> "-"],
     S |-> 0, zeroS |-> FALSE, okS |-> FALSE, pt |-> FALSE]

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
\* settling record; and any parting is noted.
Settle(n, s, z) == [n EXCEPT !.S = s, !.zeroS = z, !.okS = TwoSorts(n)]
After(n, s) == IF n.S = 0 /\ SettledNow(n, Zero(n)) THEN Settle(n, s, Zero(n)) ELSE n
Mark(n) == IF ~n.pt /\ (Parted(n, 1) \/ Parted(n, 2)) THEN [n EXCEPT !.pt = TRUE] ELSE n
Step(st, s, t, w, f, r, c) == Mark(After(Read(st, s, t, w, f, r, c), s))

\* The fold over what a read shows: positions 1 to 7 in order, a position read only where
\* its record has landed. Every argument is passed in, none read as a free variable.
\* L is what has landed and n the position landing now.
SeenStep(st, s, T, Wh, F, R, C, L, n) ==
    IF s <= MaxRec /\ T[s] # "none" /\ (L[s] \/ s = n) THEN Step(st, s, T[s], Wh[s], F[s], R[s], C[s]) ELSE st
SeenFold(T, Wh, F, R, C, L, n) ==
    SeenStep(SeenStep(SeenStep(SeenStep(SeenStep(SeenStep(SeenStep(
        Start, 1, T, Wh, F, R, C, L, n), 2, T, Wh, F, R, C, L, n), 3, T, Wh, F, R, C, L, n),
        4, T, Wh, F, R, C, L, n), 5, T, Wh, F, R, C, L, n), 6, T, Wh, F, R, C, L, n), 7, T, Wh, F, R, C, L, n)

\* What a read shows once the record at position s is written: with Store2 the record
\* is read at once, at the tail; otherwise the read is unchanged until it lands.
Written(s, t, w, f, r, c) == IF Store2 THEN Step(seen, s, t, w, f, r, c) ELSE seen

TypeOK ==
    /\ jT \in [Slots -> Types]
    /\ jW \in [Slots -> Verifiers \cup Triagers \cup {0}]
    /\ jF \in [Slots -> Findings \cup {0}]
    /\ jR \in [Slots -> Roles \cup {0}]
    /\ jC \in [Slots -> Classes \cup {"-"}]
    /\ jL \in [Slots -> BOOLEAN]
    /\ nextSeq \in 1..(MaxRec + 1)
    /\ rpc \in {"idle", "opened"}
    /\ MaxRec <= 7

Init ==
    /\ jT = [s \in Slots |-> "none"]
    /\ jW = [s \in Slots |-> 0]
    /\ jF = [s \in Slots |-> 0]
    /\ jR = [s \in Slots |-> 0]
    /\ jC = [s \in Slots |-> "-"]
    /\ jL = [s \in Slots |-> FALSE]
    /\ nextSeq = 1
    /\ rpc = "idle"
    /\ seen = Start

\* --- actions; each call's refusals are read off what its read shows, seen ---
\* A call reads the journal and writes its own record in one step.

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
    /\ jL' = [jL EXCEPT ![nextSeq] = Store2]
    /\ seen' = Written(nextSeq, kind, v, 0, 0, "-")
    /\ nextSeq' = nextSeq + 1
    /\ UNCHANGED <<jF, jR, jC, rpc>>

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
    /\ OneSortPerActor => (seen.ro[AF(a, f)] \subseteq {r})
    /\ jT' = [jT EXCEPT ![nextSeq] = "tri"]
    /\ jW' = [jW EXCEPT ![nextSeq] = a]
    /\ jF' = [jF EXCEPT ![nextSeq] = f]
    /\ jR' = [jR EXCEPT ![nextSeq] = r]
    /\ jC' = [jC EXCEPT ![nextSeq] = c]
    /\ jL' = [jL EXCEPT ![nextSeq] = Store2]
    /\ seen' = Written(nextSeq, "tri", a, f, r, c)
    /\ nextSeq' = nextSeq + 1
    /\ UNCHANGED <<rpc>>

\* A written record lands: a read now shows it. With Store2 every record landed as it
\* was written, so this step never runs.
Land(s) ==
    /\ jT[s] # "none"
    /\ ~jL[s]
    /\ jL' = [jL EXCEPT ![s] = TRUE]
    /\ seen' = IF \E u \in Slots : u > s /\ jL[u]
                 THEN SeenFold(jT, jW, jF, jR, jC, jL, s)
                 ELSE Step(seen, s, jT[s], jW[s], jF[s], jR[s], jC[s])
    /\ UNCHANGED <<jT, jW, jF, jR, jC, nextSeq, rpc>>

\* [Repair] reads the round's journal records (Action wiring 54) and answers unsettled
\* unless the read shows a settling record (Action wiring 31); otherwise the invocation
\* open writes the intent (Action wiring 22) in the same transaction.
Repair ==
    /\ rpc = "idle"
    /\ seen.S # 0
    /\ nextSeq <= MaxRec
    /\ jT' = [jT EXCEPT ![nextSeq] = "int"]
    /\ jL' = [jL EXCEPT ![nextSeq] = Store2]
    /\ seen' = Written(nextSeq, "int", 0, 0, 0, "-")
    /\ nextSeq' = nextSeq + 1
    /\ rpc' = "opened"
    /\ UNCHANGED <<jW, jF, jR, jC>>

Next ==
    \/ \E v \in Verifiers, kind \in {"clean", "found", "mal"} : Report(v, kind)
    \/ /\ TriageOpen
       /\ \E f \in Findings, r \in Roles :
            /\ TriageAdmits(f, r)
            /\ \E a \in Triagers, c \in Classes : Triage(a, f, r, c)
    \/ \E s \in Slots : Land(s)
    \/ Repair

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
\* triagers.
Inv5_1 ==
    LET w == Whole IN ((w.S # 0 /\ w.zeroS) => w.okS)

\* --- reachability probes: deliberate falsehoods the checker must reject ---

\* No finding is ever parted. Rejected: third triages are reached.
Probe_NeverParted ==
    ~Whole.pt

\* [Repair] never opens. Rejected: the repair path is reached.
Probe_NeverOpens ==
    rpc # "opened"

====
