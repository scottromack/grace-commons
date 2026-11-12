---- MODULE tamper-evidence ----
\* Grace Commons — Tamper Evidence atom (atoms/tamper-evidence.md).
\* Grounded on Final Critique 17, 2026-11-06 at 700b167 — TLA+ layer authored 2026-11-12.
\* Derived validator; the English spec is the single source of truth. On any
\* disagreement, diagnose per the entry *The conflict protocol* in pressure-testing.md.
\*
\* PURPOSE
\* Check what happens across steps: the evidences [Seal] records over a
\* sequence of calls while the clock moves and the mechanism's external anchor
\* records anchor changes, what [Verify] and [Read] answer at each point, and
\* what a [Verify] and a [Read] leave. What one state of the seal records must
\* carry (State 1, 3, 4, 5, Identity 5 and 8, Invariant 5.1 and 6.1, and which
\* calls [Seal] admits: Operation 1, 3, 4, 6 to 9, 11, 34, Non-goal 13) is the
\* Alloy model's, tamper-evidence.als; the two models spell the page's terms
\* alike (sealed, the proof, the record set presented at [Seal], the seal
\* check, the evidence id).
\*
\* HOW THE ANSWERS ARE CHECKED
\* [Verify] and [Read] write nothing, so a call of either is no step that
\* changes a variable here. What [Verify] answers is the operator
\* VerifyAnswers(id, set, match, up): the evidence id, the content of the
\* original record set presented, the host's record set match, and whether
\* the mechanism's anchor answers. What [Read] answers is ReadRows. The checks
\* on answers (Invariant 2.1, Operation 14 to 19, 27, 28, 33) are invariants
\* that hold them in every reachable state, for every id, presented set, match
\* and anchor availability, which is every [Verify] and [Read] the state
\* admits. Invariant 4.3 and 7.1 compare answers across every step: one
\* verification before it and one after.
\*
\* RULES CHECKED (named by the page's own labels)
\*   Invariant 1.1  — no evidence field of a recorded evidence
\*                    changes (Invariant 5.2 with it)             (Inv1_1_FieldsFixed)
\*   Invariant 2.1  — the right record set, changed since [Seal],
\*                    seal check not unavailable: proof-invalid
\*                    (Operation 22b through it)                   (Inv2_1_TamperDetected)
\*   Invariant 3.1  — no anchor change, seal check not unavailable:
\*                    the recorded proof verifies against the
\*                    record set presented at [Seal]               (Inv3_1_VerifiesSealedSet)
\*   Invariant 3.2  — the recorded proof verifies against no record
\*                    set differing from the one presented at [Seal] (Inv3_2_NoOtherSet)
\*   Invariant 4.3  — [Verify] consults nothing outside the
\*                    verification set: one set, one answer        (Inv4_3_VerificationSetOnly)
\*   Invariant 7.1  — two verifications of one evidence against one
\*                    record set, no anchor change between them,
\*                    neither unavailable, answer alike            (Inv7_1_ConsistentUnderFixedSet)
\*   Invariant 9.1  — the atom deletes no evidence (State 6)       (Inv9_1_NoDeletion)
\*   State 2        — no step moves an evidence out of sealed
\*                    (State 7 with it)                            (State2_NoTransitionOut)
\*   Operation 2    — exactly one evidence per successful seal, a
\*                    record set or instant already sealed included
\*                    (Identity 6, 7, Concurrent seal 1 through it) (Op2_OneEvidencePerSeal)
\*   Operation 14   — [Verify] answers exactly one outcome         (Op14_ExactlyOneAnswer)
\*   Operation 15   — no evidence under the id: not-known          (Op15_NotKnown)
\*   Operation 16   — record set match no: record-set-mismatch     (Op16_RecordSetMismatch)
\*   Operation 17   — match yes, seal check unavailable:
\*                    mechanism-verification-unavailable           (Op17_Unavailable)
\*   Operation 18   — match yes, seal check failed: proof-invalid  (Op18_ProofInvalid)
\*   Operation 19   — match yes, seal check held: verified         (Op19_Verified)
\*   Operation 20, 29 — [Verify] and [Read] write nothing: only a
\*                    [Seal] writes                                (Op20_29_OnlySealWrites)
\*   Operation 27   — [Read] answers every evidence                (Op27_ReadAnswersEvery)
\*   Operation 28   — [Read] answers every evidence field          (Op28_ReadAnswersFields)
\*   Operation 33   — verified only if the seal check held         (Op33_VerifiedOnlyIfHeld)
\*
\* WHAT THE MODEL TAKES FROM OUTSIDE THE PAGE (its inputs; no ASSUME, no CONSTRAINT)
\* - The clock (Term now; Capability requirement 1): the variable `now`, moved
\*   by a step of its own (Tick).
\* - The deployment's mechanism (Capability requirement 3, 4; Term
\*   cryptographic material): one that anchors at seal time and whose
\*   verification function consults its own external anchor, so every arm of
\*   the seal check is reached. At [Seal] it computes the proof over the
\*   record set the reference names at the call, the content `x` the step
\*   takes (the record set presented at [Seal]), with the anchor's receipt for
\*   that seal, and the anchor records the anchoring instant at now. At
\*   [Verify] it computes the seal check over the presented content against
\*   the recorded proof (Capability requirement 7, 8, 9): unavailable where
\*   the anchor does not answer (`up` is FALSE), held where the proof commits
\*   to the presented content and the anchor has recorded no anchor change for
\*   its receipt, failed otherwise.
\* - Anchor changes (Term anchor change): the set `withdrawn` of the receipts
\*   whose trust the anchor has withdrawn, grown by a step of its own.
\* - The host (Term record set match, Capability requirement 5): its record
\*   set match is an input of each [Verify], yes or no; the atom never judges
\*   it (Operation 22b). The host allocates each [Seal]'s evidence id at the
\*   seam (Identity 2); [Seal] records none an evidence carries (Identity 5,
\*   the Alloy model's check), which is the guard on Seal.
\* - orig: the record set presented at [Seal] for each evidence, the model's
\*   own record of what the page's Invariant 2.1, 3.1 and 3.2 compare with. It
\*   is no evidence field and [Verify] never reads it (open line 2026-11-05-b:
\*   the page declares the record set presented at [Seal] by no Term).
\*
\* BOUNDS (the .cfg)
\* One record set reference (every second evidence is then over a record set
\* already sealed: Operation 2, Identity 6 and 8, Concurrent seal 1); two
\* contents, so a record set presented at [Verify] can differ from the one
\* presented at [Seal], and two seals over one reference can commit to two
\* contents; three evidence ids and room for two evidences, so an id names
\* nothing; the clock from 0 to 1, so two seals share an instant or not. Every
\* [Verify] answer is reached.
\*
\* NOT MODELED HERE
\* - Refused [Seal] calls (Operation 6 to 11, 34): each writes nothing
\*   (Execution Contract Read 4); which calls [Seal] admits is the Alloy
\*   model's to check. Here a [Seal] is admitted.
\* - What [Seal] answers (the evidence id).
\* - A verification cache (Verification caching 1, 2): the model's [Verify]
\*   caches nothing.
\* - A mechanism that anchors nothing: it has no anchor change and no
\*   unavailable arm, a subset of the shapes the anchored one reaches.

EXTENDS Integers, FiniteSets

CONSTANTS
    Ids,        \* the evidence ids the host may allocate, and a caller present
    Refs,       \* the record set references a [Seal] may carry
    Contents,   \* what a record set may hold when it is presented
    MaxEv,      \* how many evidences the model's database holds room for
    MaxTime     \* the last instant the clock reaches in the model

\* NONE: the value of a field not yet written.
NONE == "none"

\* Slots: the places an evidence can occupy, in the order they are recorded.
Slots == 1..MaxEv

\* Matches: the host's record set match (Term record set match).
Matches == {"yes", "no"}

\* Outcomes: what [Verify] may answer: verified, not-known, or a failed
\* verification carrying one of its three reasons (Term verification failure).
Outcomes == {"verified", "not-known", "proof-invalid", "record-set-mismatch",
             "mechanism-verification-unavailable"}

\* NoProof: the proof field of a slot holding no evidence: no content it
\* commits to, no anchor receipt.
NoProof == [over |-> NONE, rcpt |-> 0]

\* ---------------------------------------------------------------------------
\* State
\* ---------------------------------------------------------------------------

VARIABLES
    withdrawn,  \* the anchor receipts whose trust the anchor has withdrawn
    now,        \* the host's clock reading, injected at the seam
    n,          \* the next slot an evidence takes
    aid,        \* slot -> evidence id
    ref,        \* slot -> record set reference
    pf,         \* slot -> proof: the content it commits to and its anchor receipt
    sat,        \* slot -> sealing instant
    anc,        \* slot -> anchoring instant
    st,         \* slot -> the evidence's state ("none": no evidence)
    orig        \* slot -> the record set presented at [Seal] (the model's own)

\* vars: every variable; a step that changes none of them is a stutter.
vars == <<withdrawn, now, n, aid, ref, pf, sat, anc, st, orig>>

\* records: every variable that holds an evidence's fields, and the model's
\* record of what each seal was presented: what the database holds.
records == <<n, aid, ref, pf, sat, anc, st, orig>>

\* world: what lies outside the atom: the anchor's withdrawals and the clock.
world == <<withdrawn, now>>

\* Recorded: the slot holds an evidence.
Recorded(s) == st[s] # NONE

\* Live: the slots holding an evidence; its size is the evidence count.
Live == {s \in Slots : Recorded(s)}

\* Carried: the evidence ids the recorded evidences carry.
Carried == {aid[s] : s \in Live}

\* SlotOf: the slot whose evidence the id names, or 0 where it names none.
SlotOf(i) == IF \E s \in Live : aid[s] = i
             THEN CHOOSE s \in Live : aid[s] = i
             ELSE 0

\* SealCheck: the seal check the mechanism computes at the seam for the
\* evidence in slot s over the presented content x (Term seal check):
\* unavailable where its anchor does not answer; held where the recorded proof
\* commits to x and the anchor has recorded no anchor change for its receipt;
\* failed otherwise.
SealCheck(s, x, up) ==
    IF ~up THEN "unavailable"
    ELSE IF pf[s].over = x /\ pf[s].rcpt \notin withdrawn THEN "held"
    ELSE "failed"

\* VerifyAnswers: what [Verify] answers for an id, a presented content, the
\* host's record set match and the anchor's availability, each of the page's
\* rules adding the answer its condition calls for: not-known where the id
\* names no evidence (Operation 15); record-set-mismatch on a match of no
\* (Operation 16); on a match of yes, mechanism-verification-unavailable,
\* proof-invalid or verified on the seal check (Operation 17, 18, 19).
\* Operation 14 asks that exactly one rule fires.
VerifyAnswers(i, x, m, up) ==
    LET s   == SlotOf(i)
        mt  == m
        chk == SealCheck(s, x, up)
    IN
    IF s = 0 THEN {"not-known"}
    ELSE (IF mt = "no" THEN {"record-set-mismatch"} ELSE {})
         \cup (IF mt = "yes" /\ chk = "unavailable"
               THEN {"mechanism-verification-unavailable"} ELSE {})
         \cup (IF mt = "yes" /\ chk = "failed" THEN {"proof-invalid"} ELSE {})
         \cup (IF mt = "yes" /\ chk = "held" THEN {"verified"} ELSE {})

\* Fields: the evidence fields of the slot (Term evidence field).
Fields(s) == <<aid[s], ref[s], pf[s], sat[s], anc[s]>>

\* ReadRows: what [Read] answers: every evidence the records hold, with every
\* evidence field it carries (Operation 27, 28).
ReadRows == {Fields(s) : s \in Live}

\* Withdrawn: whether the anchor has recorded an anchor change for the
\* slot's proof.
Withdrawn(s) == pf[s].rcpt \in withdrawn

\* TypeOK: each variable holds a value of its kind (the model's typing, not a
\* rule of the page). The state may hold a value other than sealed, so a write
\* that moved an evidence would show (State 1 is the Alloy model's).
TypeOK ==
    /\ withdrawn \subseteq Slots
    /\ now \in 0..MaxTime
    /\ n \in 1..(MaxEv + 1)
    /\ aid \in [Slots -> Ids \cup {NONE}]
    /\ ref \in [Slots -> Refs \cup {NONE}]
    /\ sat \in [Slots -> Int]
    /\ anc \in [Slots -> Int]
    /\ st \in [Slots -> {NONE, "sealed", "tampered"}]
    /\ orig \in [Slots -> Contents \cup {NONE}]

\* Init: no evidence; no anchor change; the clock at its first instant.
Init ==
    /\ withdrawn = {}
    /\ now = 0
    /\ n = 1
    /\ aid = [s \in Slots |-> NONE]
    /\ ref = [s \in Slots |-> NONE]
    /\ pf = [s \in Slots |-> NoProof]
    /\ sat = [s \in Slots |-> -1]
    /\ anc = [s \in Slots |-> -1]
    /\ st = [s \in Slots |-> NONE]
    /\ orig = [s \in Slots |-> NONE]

\* ---------------------------------------------------------------------------
\* Steps of the world outside the atom
\* ---------------------------------------------------------------------------

\* Tick: the host's clock moves on by a second.
Tick ==
    /\ now < MaxTime
    /\ now' = now + 1
    /\ UNCHANGED withdrawn
    /\ UNCHANGED records

\* AnchorChanges: the mechanism's external anchor withdraws its trust in the
\* receipt of a recorded proof, as a revocation the anchoring authority
\* records (Term anchor change).
AnchorChanges(a) ==
    /\ a \notin withdrawn
    /\ \E s \in Live : pf[s].rcpt = a
    /\ withdrawn' = withdrawn \cup {a}
    /\ UNCHANGED now
    /\ UNCHANGED records

\* ---------------------------------------------------------------------------
\* The atom's actions
\* ---------------------------------------------------------------------------

\* Seal: an admitted [Seal] records one evidence in the next slot, carrying
\* the id the host allocated, one no evidence carries (Identity 2, 5), the
\* call's record set reference, the proof the mechanism computed over the
\* record set presented, content x, with the anchor's receipt (Operation 1),
\* the injected now as sealing instant (Operation 3), the anchor's time as
\* anchoring instant (Operation 4), standing in sealed (State 1).
Seal(i, r, x) ==
    /\ n <= MaxEv
    /\ i \notin Carried
    /\ aid' = [aid EXCEPT ![n] = i]
    /\ ref' = [ref EXCEPT ![n] = r]
    /\ pf' = [pf EXCEPT ![n] = [over |-> x, rcpt |-> n]]
    /\ sat' = [sat EXCEPT ![n] = now]
    /\ anc' = [anc EXCEPT ![n] = now]
    /\ st' = [st EXCEPT ![n] = "sealed"]
    /\ orig' = [orig EXCEPT ![n] = x]
    /\ n' = n + 1
    /\ UNCHANGED world

\* Verify: a [Verify] step. It answers VerifyAnswers(i, x, m, up) and writes
\* nothing (Operation 20), so in this model it changes no variable; the answer
\* is checked in every reachable state for every input (the invariants below),
\* which is every [Verify] the state admits.
Verify(i, x, m, up) ==
    /\ UNCHANGED world
    /\ UNCHANGED records

\* Read: a [Read] step. It answers ReadRows and writes nothing (Operation 29);
\* its answer is checked in every reachable state (Op27, Op28).
Read ==
    /\ UNCHANGED world
    /\ UNCHANGED records

\* Next: a step of the world, or any call: a [Seal] of any id, reference and
\* presented content, a [Verify] of any id, presented content and match with
\* the anchor answering or not, or a [Read].
Next ==
    \/ Tick
    \/ \E a \in Slots : AnchorChanges(a)
    \/ \E i \in Ids, r \in Refs, x \in Contents : Seal(i, r, x)
    \/ \E i \in Ids, x \in Contents, m \in Matches, up \in BOOLEAN : Verify(i, x, m, up)
    \/ Read

\* Spec: every behaviour from Init by Next steps.
Spec == Init /\ [][Next]_vars

\* ---------------------------------------------------------------------------
\* Checks (the verification surface). Each spells the page's condition itself,
\* so a defect in an action's own reading of it shows.
\* ---------------------------------------------------------------------------

\* Names: the slot holds an evidence carrying the id.
Names(i, s) == Recorded(s) /\ aid[s] = i

\* TheSealCheck: the seal check as Term seal check and Capability requirement
\* 7 to 9 define it, spelled for the checks: unavailable where the anchor the
\* verification function consults does not answer; failed where the recorded
\* proof does not commit to the presented content or the anchor has recorded
\* an anchor change for it; held otherwise.
TheSealCheck(s, x, up) ==
    IF ~up THEN "unavailable"
    ELSE IF pf[s].over # x \/ pf[s].rcpt \in withdrawn THEN "failed"
    ELSE "held"

\* SealShaped: the step records one new evidence in the next slot and touches
\* no other slot: the only write a [Seal] makes (Operation 1, 2).
SealShaped ==
    /\ n' = n + 1
    /\ \A s \in Slots \ {n} :
          /\ aid'[s] = aid[s] /\ ref'[s] = ref[s] /\ pf'[s] = pf[s]
          /\ sat'[s] = sat[s] /\ anc'[s] = anc[s] /\ st'[s] = st[s]
          /\ orig'[s] = orig[s]

\* Inv1_1_FieldsFixed: no step changes a recorded evidence's id, record set
\* reference, proof, sealing instant or anchoring instant (Invariant 1.1,
\* Invariant 5.2).
Inv1_1_FieldsFixed ==
    [][\A s \in Slots : Recorded(s) =>
          /\ aid'[s] = aid[s]
          /\ ref'[s] = ref[s]
          /\ pf'[s] = pf[s]
          /\ sat'[s] = sat[s]
          /\ anc'[s] = anc[s]]_vars

\* Inv2_1_TamperDetected: a [Verify] of an evidence, with the host's record
\* set match yes, the seal check not unavailable, and a presented record set
\* that differs from the one presented at [Seal], answers proof-invalid
\* (Invariant 2.1).
Inv2_1_TamperDetected ==
    \A i \in Ids, x \in Contents, up \in BOOLEAN :
        (\E s \in Slots : /\ Names(i, s)
                          /\ TheSealCheck(s, x, up) # "unavailable"
                          /\ x # orig[s])
            => VerifyAnswers(i, x, "yes", up) = {"proof-invalid"}

\* Inv3_1_VerifiesSealedSet: where the anchor has recorded no anchor change
\* for a recorded proof and the seal check is not unavailable, the proof
\* verifies against the record set presented at [Seal] (Invariant 3.1).
Inv3_1_VerifiesSealedSet ==
    \A s \in Slots, up \in BOOLEAN :
        (/\ Recorded(s) /\ ~Withdrawn(s)
         /\ TheSealCheck(s, orig[s], up) # "unavailable")
            => TheSealCheck(s, orig[s], up) = "held"

\* Inv3_2_NoOtherSet: a recorded proof verifies against no record set that
\* differs from the one presented at [Seal] (Invariant 3.2).
Inv3_2_NoOtherSet ==
    \A s \in Slots, x \in Contents, up \in BOOLEAN :
        (Recorded(s) /\ x # orig[s]) => TheSealCheck(s, x, up) # "held"

\* Inv4_3_VerificationSetOnly: across any step that leaves an evidence's
\* verification set as it was (its fields and what its anchor answers; the
\* presented set, the match and the anchor's availability taken alike on both
\* sides), a [Verify] of its id answers the same before and after: [Verify]
\* reads nothing outside the set, so nothing else (the clock, another
\* evidence) moves its answer (Invariant 4.3).
Inv4_3_VerificationSetOnly ==
    [][\A s \in Slots, x \in Contents, m \in Matches, up \in BOOLEAN :
          (/\ Recorded(s) /\ Recorded(s)'
           /\ Fields(s)' = Fields(s) /\ Withdrawn(s)' = Withdrawn(s))
          => VerifyAnswers(aid[s], x, m, up)' = VerifyAnswers(aid[s], x, m, up)]_vars

\* Inv7_1_ConsistentUnderFixedSet: two verifications of one evidence against
\* one record set (one content, one match), on either side of a step with no
\* anchor change for its proof, answer alike, unless one of them answers
\* mechanism-verification-unavailable (Invariant 7.1).
Inv7_1_ConsistentUnderFixedSet ==
    [][\A s \in Slots, x \in Contents, m \in Matches, u1 \in BOOLEAN, u2 \in BOOLEAN :
          (/\ Recorded(s) /\ Recorded(s)' /\ aid'[s] = aid[s]
           /\ Withdrawn(s)' = Withdrawn(s)
           /\ "mechanism-verification-unavailable" \notin VerifyAnswers(aid[s], x, m, u1)
           /\ "mechanism-verification-unavailable" \notin VerifyAnswers(aid[s], x, m, u2)')
          => VerifyAnswers(aid[s], x, m, u2)' = VerifyAnswers(aid[s], x, m, u1)]_vars

\* Inv9_1_NoDeletion: no step takes an evidence away: every id the records
\* carry, they carry after (Invariant 9.1, State 6).
Inv9_1_NoDeletion ==
    [][Carried \subseteq Carried']_vars

\* State2_NoTransitionOut: no step moves a recorded evidence out of sealed:
\* no surface revokes, invalidates or marks one (State 2, State 7).
State2_NoTransitionOut ==
    [][\A s \in Slots : st[s] = "sealed" => st'[s] = "sealed"]_vars

\* Op2_OneEvidencePerSeal: a step that records an evidence id the records did
\* not carry adds exactly one evidence, where an evidence over the same record
\* set or at the same instant stands already: the atom identifies an evidence
\* by neither (Operation 2; Identity 6, 7; Concurrent seal 1).
Op2_OneEvidencePerSeal ==
    [][(Carried' \ Carried # {}) => Cardinality(Live') = Cardinality(Live) + 1]_vars

\* Op20_29_OnlySealWrites: every step that changes the records is a [Seal]'s
\* write, one new evidence in the next slot: a [Verify] and a [Read] write
\* nothing (Operation 20, Operation 29).
Op20_29_OnlySealWrites ==
    [][records' # records => SealShaped]_vars

\* Op14_ExactlyOneAnswer: every [Verify], of any id, presented set, match and
\* anchor availability, answers exactly one outcome (Operation 14, Check 4.1).
Op14_ExactlyOneAnswer ==
    \A i \in Ids, x \in Contents, m \in Matches, up \in BOOLEAN :
        /\ Cardinality(VerifyAnswers(i, x, m, up)) = 1
        /\ VerifyAnswers(i, x, m, up) \subseteq Outcomes

\* Op15_NotKnown: a [Verify] of an id no evidence carries answers not-known
\* (Operation 15).
Op15_NotKnown ==
    \A i \in Ids, x \in Contents, m \in Matches, up \in BOOLEAN :
        (~\E s \in Slots : Names(i, s)) => VerifyAnswers(i, x, m, up) = {"not-known"}

\* Op16_RecordSetMismatch: a [Verify] of an evidence whose record set match
\* is no answers record-set-mismatch (Operation 16, Check 4.2).
Op16_RecordSetMismatch ==
    \A i \in Ids, x \in Contents, up \in BOOLEAN :
        (\E s \in Slots : Names(i, s))
            => VerifyAnswers(i, x, "no", up) = {"record-set-mismatch"}

\* Op17_Unavailable: a [Verify] of an evidence with a match of yes and the
\* seal check unavailable answers mechanism-verification-unavailable
\* (Operation 17, Check 4.2).
Op17_Unavailable ==
    \A i \in Ids, x \in Contents, up \in BOOLEAN :
        (\E s \in Slots : Names(i, s) /\ TheSealCheck(s, x, up) = "unavailable")
            => VerifyAnswers(i, x, "yes", up) = {"mechanism-verification-unavailable"}

\* Op18_ProofInvalid: a [Verify] of an evidence with a match of yes and the
\* seal check failed answers proof-invalid (Operation 18, Check 4.2).
Op18_ProofInvalid ==
    \A i \in Ids, x \in Contents, up \in BOOLEAN :
        (\E s \in Slots : Names(i, s) /\ TheSealCheck(s, x, up) = "failed")
            => VerifyAnswers(i, x, "yes", up) = {"proof-invalid"}

\* Op19_Verified: a [Verify] of an evidence with a match of yes and the seal
\* check held answers verified (Operation 19).
Op19_Verified ==
    \A i \in Ids, x \in Contents, up \in BOOLEAN :
        (\E s \in Slots : Names(i, s) /\ TheSealCheck(s, x, up) = "held")
            => VerifyAnswers(i, x, "yes", up) = {"verified"}

\* Op33_VerifiedOnlyIfHeld: a [Verify] answers verified only where the seal
\* check held (Operation 33).
Op33_VerifiedOnlyIfHeld ==
    \A i \in Ids, x \in Contents, m \in Matches, up \in BOOLEAN :
        "verified" \in VerifyAnswers(i, x, m, up)
            => \E s \in Slots : Names(i, s) /\ TheSealCheck(s, x, up) = "held"

\* Op27_ReadAnswersEvery: a [Read] answers every evidence the records hold
\* (Operation 27).
Op27_ReadAnswersEvery ==
    {row[1] : row \in ReadRows} = {aid[s] : s \in {y \in Slots : Recorded(y)}}

\* Op28_ReadAnswersFields: a [Read] answers every evidence field each evidence
\* carries: its id, record set reference, proof, sealing instant and
\* anchoring instant (Operation 28).
Op28_ReadAnswersFields ==
    ReadRows = {<<aid[s], ref[s], pf[s], sat[s], anc[s]>> : s \in {y \in Slots : Recorded(y)}}

====
