---- MODULE idempotent-reservation-buggy-digest ----
\* BUGGY TWIN (vacuity guard) for idempotent-reservation.tla — the parameters digest is not compared.
\*
\* The module is the correct model with one rule changed, so the checker must find the
\* counterexample the change makes reachable; a checker that reports every invariant
\* holding here is vacuous.
\*
\* BUG (Action wiring 8, Invariant 4.2): a live entry matches on the action type alone, so a call
\* with other parameters under the token is answered with the entry's result instead of
\* token-collision.
\*
\* Breaks: Invariant_4_2.
\* Grace Commons — Idempotent Reservation composition.
\* Spec-level formal sibling of compositions/idempotent-reservation.md.
\* Derived validator; the English spec is the single source of truth. On any
\* disagreement, diagnose per the entry *The conflict protocol* in pressure-testing.md.
\*
\* Re-derived 2026-11-08 (the first model, 2026-06-03, checked one claim: a single
\* effect per window, against an early eviction). It now carries the token results
\* entry with its action type, parameters digest, result and recovery mark; Duplicate
\* Prevention's guard as its own clock and its outage; the eviction leg as the second
\* process over the token; and the arms a call takes (collision, replay, fresh request,
\* outcome-unknown, re-entry).
\*
\* WHAT THIS MODEL CHECKS
\* One idempotency token, one resource, and calls of two action types: a place_hold
\* (the digest names the requester) and a release (the digest names the commitment it
\* releases). Provisional Commitment is the other writer of the resource, so the
\* model also lets a second caller, under other tokens, release the held commitment
\* and place another. What it checks is that a token yields one effect and one answer
\* inside its window, whatever the retries, the outage and the eviction leg do:
\*   - Invariant 1.1  two place_hold answers inside one window under one digest are alike.
\*   - Invariant 2.1  the same for two resolving answers.
\*   - Invariant 2.2  Provisional Commitment is called once for the token inside a
\*                    window, a re-entry excepted.
\*   - Invariant 2.3  a re-entry after an earlier run changes nothing.
\*   - Invariant 3.1  the token never binds two commitment ids inside one window.
\*   - Invariant 4.1  the token binds one action type (no entry, and no answer, crosses it).
\*   - Invariant 4.2  the token binds one parameters digest (the same).
\*   - Invariant 7.1  an entry is evicted only after the window and Duplicate Prevention's
\*                    guard have elapsed.
\*   - Invariant 7.2  a call finding no entry and a not-seen token stands as a fresh request.
\*   - Invariant 8.2  an admitted first invocation reaches Provisional Commitment once.
\* and, from the rules those invariants stand on:
\*   - Check 4.1 / Housekeeping 6  no evicted entry's token was seen at the eviction.
\*   - Check 4.2 / Housekeeping 5  no evicted entry was younger than the window.
\*   - Composes 7 / Action wiring 25  Duplicate Prevention records with every entry written.
\*   - Indeterminate outcome 3, 4, 7  outcome-unknown carries the held commitments whose
\*                    requester equals the call's, at most one.
\*   - Indeterminate outcome 8, 10, 13  a re-entry marks its entry; only a place_hold
\*                    answers outcome-unknown, only a resolving action re-runs.
\*   - Wiring decision 2  a rejection is recorded against the token like an answer.
\*   - Action wiring 27 / Capability requirement 16  an unavailable check reads as seen.
\*
\* HOW AN INVARIANT IS READ
\* Each invariant above is a property of the whole run, and the run's history is large, so the
\* model keeps no history. It keeps a summary of the token's current window instead (the first
\* answer given to each action type and digest, how many calls reached the constituent, the
\* commitment id and the action type and digest the window bound), and every step that could
\* break an invariant adds the invariant's name to `viol` when it does. The named invariants
\* below say `viol` does not hold their name. A step reads the summary and the world it acts on,
\* never the rule it is checked against, so a rule the step gets wrong is caught by the check.
\*
\* THE TWO PROCESSES AND THE OUTAGE
\* A call is one transaction (Execution Contract Database 1 and 2; Decisions entry
\* 2026-10-20): the entry, Provisional Commitment's write and Duplicate Prevention's record
\* commit together, so no call sees another half done. The eviction leg is the other
\* process: it reads an entry and the token's check and evicts, in one transaction of its
\* own. A call may evict an elapsed entry in place (Action wiring 12), which is the same
\* step. Duplicate Prevention's store may be unavailable for a while (`down`): its check
\* then reads as seen (Action wiring 27), while its writes ride the call's transaction.
\* That outage is the only way a token reads as seen with no entry, and so the only way
\* the outcome-unknown arm and the re-entry arm are reached; MaxFault bounds how many
\* outages the run holds.
\*
\* TIME AND THE WINDOW
\* clk counts ticks; a call, an eviction or an outage takes no tick of its own, so several
\* calls share an instant. The window summary (`gOn`, `gws`) is the token's idempotency window
\* as the invariants read it: it opens at the first admitted invocation (a write of the
\* entry) and a new one opens only at a write at or after its end. The model's own rules
\* read the entry's pending instant and Duplicate Prevention's guard instead, so an
\* invariant stated against the window cannot be satisfied by a rule that merely agrees
\* with itself.
\*
\* NOT MODELLED (out of scope for the load-bearing properties)
\* - The boundary predicate (Primitive policy 1 to 6): a blank or over-long token is
\*   answered invalid-request before any entry, check or constituent is touched, so the
\*   model takes every token as well formed.
\* - confirm and expire: confirm is a resolving action like release (a single resolution
\*   to a terminal state); expire only adds Provisional Commitment's window-not-elapsed
\*   refusal, which is the constituent's own answer, cached like any other. Provisional
\*   Commitment's state machine has a model of its own (provisional-commitment.tla); here
\*   it is a held commitment, a release and a place.
\* - Which rejection Provisional Commitment gives: not-known folds into not-held, and
\*   registry-unavailable and storage-failure are not answered by the model (a storage
\*   failure commits nothing, Execution Contract Constituent failure 1).
\* - The deployment's configuration (Capability requirement 1 to 4, 16, 18; Invariant 8.1):
\*   the window is a constant, and the database is the model's own atomic step.
\* - Several tokens: every invariant is per token, and the second caller stands for the
\*   others.

EXTENDS Naturals, FiniteSets

CONSTANTS
    Window,       \* the idempotency window, in ticks; Duplicate Prevention's guard is configured to it
    MaxClk,       \* the last tick of the clock
    MaxCall,      \* how many calls under the token the run may hold
    MaxFault,     \* how many outages of Duplicate Prevention's store the run may hold
    MaxId         \* how many commitments the resource may ever hold (ids are 1..MaxId)

ASSUME Window >= 1
ASSUME MaxId >= 2

VARIABLES
    clk,          \* the clock, in ticks
    calls,        \* how many calls under the token the run has made
    flt,          \* how many outages the run has spent (the fault budget)
    down,         \* TRUE while Duplicate Prevention's store is unavailable
    dpOn,         \* TRUE once Duplicate Prevention has recorded the token
    dpAt,         \* the instant of the token's most recent guard (Duplicate Prevention's record starts a guard)
    ent,          \* the token's entry in the token results map, one record; has = FALSE when there is none
    hid,          \* the id of the commitment Provisional Commitment holds, 0 when it holds none
    hreq,         \* the held commitment's requester, 0 when it holds none
    nid,          \* how many commitments Provisional Commitment has placed (ids are never reused)
    gOn,          \* the window summary: TRUE once a window has opened
    gws,          \* the window's first instant
    ga,           \* the first result answered to each action type and digest in the window, RNone for none
    gfresh,       \* how many fresh requests reached the constituent in the window (at most 2 is kept)
    gnon,         \* how many calls other than a re-entry reached the constituent in the window (at most 2 is kept)
    gid,          \* the commitment id the window's entries bound, 0 for none
    gact,         \* the action type the window's entries bound, "-" for none
    gdig,         \* the parameters digest the window's entries bound, 0 for none
    viol          \* the names of the invariants a step has broken

vars == <<clk, calls, flt, down, dpOn, dpAt, ent, hid, hreq, nid, gOn, gws, ga, gfresh, gnon, gid, gact, gdig, viol>>

Acts == {"place", "release"}
Digs == {1, 2}
Ids == 1..MaxId
\* A result that is not a commitment id is a tag above every id, so a result is always an integer
\* (TLC compares values of one type): ok, resource-unavailable, not-held, and none yet.
ROk == MaxId + 1
RUnavail == MaxId + 2
RNothd == MaxId + 3
RNone == MaxId + 4
\* What a constituent answers: a commitment id, resource-unavailable, ok or not-held.
Results == Ids \cup {ROk, RUnavail, RNothd}

\* The window summary with no answer given yet.
Blank == [x \in Acts |-> [y \in Digs |-> RNone]]

\* The shape of every variable: the scalars from the sets above and the entry as one record.
TypeOK ==
    /\ clk \in 0..MaxClk
    /\ calls \in 0..MaxCall
    /\ flt \in 0..MaxFault
    /\ down \in BOOLEAN
    /\ dpOn \in BOOLEAN
    /\ dpAt \in 0..MaxClk
    /\ ent.has \in BOOLEAN
    /\ ent.act \in Acts
    /\ ent.d \in Digs
    /\ ent.res \in Results
    /\ ent.at \in 0..MaxClk
    /\ ent.mark \in {"first", "recovered"}
    /\ hid \in 0..MaxId
    /\ hreq \in 0..2
    /\ nid \in 0..MaxId
    /\ gOn \in BOOLEAN
    /\ gws \in 0..MaxClk
    /\ gfresh \in 0..2
    /\ gnon \in 0..2
    /\ gid \in 0..MaxId
    /\ gact \in Acts \cup {"-"}
    /\ gdig \in 0..2

\* Nothing has happened: no entry, no guard, no commitment, the store available, no window.
Init ==
    /\ clk = 0
    /\ calls = 0
    /\ flt = 0
    /\ down = FALSE
    /\ dpOn = FALSE
    /\ dpAt = 0
    /\ ent = [has |-> FALSE, act |-> "place", d |-> 1, res |-> ROk, at |-> 0, mark |-> "first"]
    /\ hid = 0
    /\ hreq = 0
    /\ nid = 0
    /\ gOn = FALSE
    /\ gws = 0
    /\ ga = Blank
    /\ gfresh = 0
    /\ gnon = 0
    /\ gid = 0
    /\ gact = "-"
    /\ gdig = 0
    /\ viol = {}

\* ----------------------------------------------------------------------------------------------
\* Duplicate Prevention, the entry and the window, as the rules read them
\* ----------------------------------------------------------------------------------------------

\* Duplicate Prevention's guard on the token is live: it was recorded and its window has not
\* elapsed (the guard runs from the record's instant for the idempotency window).
GuardLive == dpOn /\ (clk < dpAt + Window)

\* What Duplicate Prevention's check answers, with an unavailable store resolved as seen
\* (Action wiring 27, Capability requirement 16). The invariants read this one.
FailClosedSeen == down \/ GuardLive

\* What the composition's rules read as the check. The correct model reads it fail-closed.
CheckSeen == FailClosedSeen

\* An entry a call may evict in place (Action wiring 12): it exists, the idempotency window has
\* elapsed since its pending instant (Housekeeping 5), and the check answers not-seen (Housekeeping 4, 6).
Evictable == ent.has /\ (clk >= ent.at + Window) /\ ~CheckSeen

\* What the eviction leg itself may evict (Housekeeping 4 to 6): the same entries.
LegMay == Evictable

\* An entry the call finds and does not evict (Term live entry).
Live == ent.has /\ ~Evictable

\* The call's action type and digest equal the live entry's (Action wiring 7, 8).
Match(a, d) == Live /\ ent.act = a

\* The window is open at this instant.
InW == gOn /\ (clk < gws + Window)

\* Wiring decision 2: a constituent's rejection is recorded against the token as an answer is.
Records(r) == TRUE

\* The invariants an eviction breaks: one younger than the window (Check 4.2, Invariant 7.1), one over a
\* token the check answers seen for (Check 4.1) and one over a guard still live (Invariant 7.1).
EvFlags ==
    (IF clk < ent.at + Window THEN {"Check_4_2_NoYoungEvicted", "Invariant_7_1"} ELSE {})
    \cup (IF FailClosedSeen THEN {"Check_4_1_NoSeenEvicted"} ELSE {})
    \cup (IF GuardLive THEN {"Invariant_7_1"} ELSE {})

\* ----------------------------------------------------------------------------------------------
\* Provisional Commitment, as far as the composition reads it
\* ----------------------------------------------------------------------------------------------

\* A place_hold is refused while a commitment is held (resource-unavailable) and otherwise places the
\* next commitment; a release of the held commitment resolves it to ok, and a release of any other
\* is not-held and changes nothing (Provisional Commitment Invariant 2, single resolution).
Deleg(a, d) ==
    IF a = "place"
    THEN IF hid /= 0
         THEN [res |-> RUnavail, hid |-> hid, hreq |-> hreq, nid |-> nid]
         ELSE [res |-> nid + 1, hid |-> nid + 1, hreq |-> d, nid |-> nid + 1]
    ELSE IF hid = d
         THEN [res |-> ROk, hid |-> 0, hreq |-> 0, nid |-> nid]
         ELSE [res |-> RNothd, hid |-> hid, hreq |-> hreq, nid |-> nid]

\* The constituent can take the call: a new commitment needs an id left to give.
CanDeleg(a) == (a = "place" /\ hid = 0) => (nid < MaxId)

\* The held commitments whose resource and requester equal a place_hold's: the resource is the
\* model's one, the requester is the call's digest, and at most one commitment is held (Term candidates).
CandSet(d) == IF (hid /= 0) /\ (hreq = d) THEN {hid} ELSE {}

\* The candidates the page names, read from the world and not from the composition's own filter.
ExpectedCand(d) == IF (hid /= 0) /\ (hreq = d) THEN {hid} ELSE {}

\* The window summary after an answer of result r to an action type and digest: the first answer to
\* each pair is kept, and a window not yet open is opened at this instant.
GaAfter(a, d, r) ==
    IF InW
    THEN (IF ga[a][d] = RNone THEN [ga EXCEPT ![a][d] = r] ELSE ga)
    ELSE [Blank EXCEPT ![a][d] = r]

\* Two answers inside one window to one action type and digest differ (Invariant 1.1, 2.1).
AlikeFlag(a, d, r) ==
    IF InW /\ ga[a][d] /= RNone /\ ga[a][d] /= r
    THEN {IF a = "place" THEN "Invariant_1_1" ELSE "Invariant_2_1"}
    ELSE {}

\* ----------------------------------------------------------------------------------------------
\* The calls
\* ----------------------------------------------------------------------------------------------

\* The call finds a live entry whose action type or parameters digest differs: token-collision, and
\* nothing changes (Action wiring 7, 8; Invariant 4).
Collision(a, d) ==
    /\ calls < MaxCall
    /\ Live /\ ~Match(a, d)
    /\ calls' = calls + 1
    /\ UNCHANGED <<clk, flt, down, dpOn, dpAt, ent, hid, hreq, nid, gOn, gws, ga, gfresh, gnon, gid, gact, gdig, viol>>

\* The call finds a matching complete entry: it answers the entry's result and calls no constituent
\* (Action wiring 9, 10; Invariant 1.1, 2.1). An answer to a call of another action type or digest than the
\* entry's breaks Invariant 4.1 or 4.2.
Replay(a, d) ==
    /\ calls < MaxCall
    /\ Match(a, d)
    /\ calls' = calls + 1
    /\ ga' = IF InW /\ ga[a][d] = RNone THEN [ga EXCEPT ![a][d] = ent.res] ELSE ga
    /\ viol' = viol \cup AlikeFlag(a, d, ent.res)
                     \cup (IF a /= ent.act THEN {"Invariant_4_1"} ELSE {})
                     \cup (IF d /= ent.d THEN {"Invariant_4_2"} ELSE {})
    /\ UNCHANGED <<clk, flt, down, dpOn, dpAt, ent, hid, hreq, nid, gOn, gws, gfresh, gnon, gid, gact, gdig>>

\* A call that reaches Provisional Commitment writes the entry, records the token with Duplicate
\* Prevention and updates the window summary, in one transaction (Execution Contract Database 1). k is
\* "fresh" for an admitted first invocation and "reentry" for a resolving action run again (Indeterminate
\* outcome 13). An elapsed entry the call evicts in place is checked as an eviction (Action wiring 12).
Commit(a, d, k) ==
    /\ calls < MaxCall
    /\ CanDeleg(a)
    /\ \E dg \in {Deleg(a, d)} : \E mk \in {IF k = "reentry" THEN "recovered" ELSE "first"} :
        /\ calls' = calls + 1
        /\ hid' = dg.hid
        /\ hreq' = dg.hreq
        /\ nid' = dg.nid
        /\ ent' = IF Records(dg.res)
                  THEN [has |-> TRUE, act |-> a, d |-> d, res |-> dg.res, at |-> clk, mark |-> mk]
                  ELSE [ent EXCEPT !.has = FALSE]
        /\ dpOn' = IF Records(dg.res) THEN TRUE ELSE dpOn
        /\ dpAt' = IF Records(dg.res) THEN (IF GuardLive THEN dpAt ELSE clk) ELSE dpAt
        /\ gOn' = TRUE
        /\ gws' = IF InW THEN gws ELSE clk
        /\ ga' = GaAfter(a, d, dg.res)
        /\ gfresh' = IF k = "fresh" THEN (IF InW THEN (IF gfresh >= 1 THEN 2 ELSE 1) ELSE 1)
                     ELSE (IF InW THEN gfresh ELSE 0)
        /\ gnon' = IF k /= "reentry" THEN (IF InW THEN (IF gnon >= 1 THEN 2 ELSE 1) ELSE 1)
                   ELSE (IF InW THEN gnon ELSE 0)
        /\ gid' = IF Records(dg.res) /\ dg.res \in Ids
                  THEN (IF InW /\ gid /= 0 THEN gid ELSE dg.res)
                  ELSE (IF InW THEN gid ELSE 0)
        /\ gact' = IF Records(dg.res) THEN (IF InW /\ gact /= "-" THEN gact ELSE a)
                   ELSE (IF InW THEN gact ELSE "-")
        /\ gdig' = IF Records(dg.res) THEN (IF InW /\ gdig /= 0 THEN gdig ELSE d)
                   ELSE (IF InW THEN gdig ELSE 0)
        /\ viol' = viol \cup AlikeFlag(a, d, dg.res)
                         \cup (IF InW /\ k /= "reentry" /\ gnon >= 1 THEN {"Invariant_2_2"} ELSE {})
                         \cup (IF InW /\ k = "fresh" /\ gfresh >= 1 THEN {"Invariant_8_2"} ELSE {})
                         \cup (IF k = "reentry" /\ InW /\ (dg.hid /= hid \/ dg.nid /= nid) THEN {"Invariant_2_3"} ELSE {})
                         \cup (IF Records(dg.res) /\ dg.res \in Ids /\ InW /\ gid /= 0 /\ gid /= dg.res
                               THEN {"Invariant_3_1"} ELSE {})
                         \cup (IF Records(dg.res) /\ InW /\ gact /= "-" /\ gact /= a THEN {"Invariant_4_1"} ELSE {})
                         \cup (IF Records(dg.res) /\ InW /\ gdig /= 0 /\ gdig /= d THEN {"Invariant_4_2"} ELSE {})
                         \cup (IF (k = "reentry") /= (mk = "recovered") THEN {"Indeterminate_8_RecoveredMarked"} ELSE {})
                         \cup (IF ~Records(dg.res) THEN {"Wiring_2_RejectionRecorded"} ELSE {})
                         \cup (IF k = "fresh" /\ FailClosedSeen THEN {"Wiring_FreshMeansNotSeen"} ELSE {})
                         \cup (IF k = "reentry" /\ (a = "place" \/ ~FailClosedSeen \/ Live)
                               THEN {"Indeterminate_10_13_Arms"} ELSE {})
                         \cup (IF k = "reentry" /\ ~FailClosedSeen THEN {"Invariant_7_2"} ELSE {})
                         \cup (IF Evictable THEN EvFlags ELSE {})
        /\ UNCHANGED <<clk, flt, down>>

\* No live entry and the check answers not-seen: a fresh request, delegated once (Composes 7; Invariant 7.2, 8.2).
Fresh(a, d) ==
    /\ ~Live /\ ~CheckSeen
    /\ Commit(a, d, "fresh")

\* No live entry, the token read as seen, and a resolving action: it runs again, and a re-run after an
\* earlier run is effect-free by Provisional Commitment's single resolution (Indeterminate outcome 13).
Reentry(a, d) ==
    /\ ~Live /\ CheckSeen /\ a /= "place"
    /\ Commit(a, d, "reentry")

\* No live entry, the token read as seen, and a place_hold: outcome-unknown carrying the candidates,
\* recorded nowhere and delegated to no one (Indeterminate outcome 10, 3, 4, 7; Wiring decision 4).
Unknown(a, d) ==
    /\ calls < MaxCall
    /\ ~Live /\ CheckSeen /\ a = "place"
    /\ calls' = calls + 1
    /\ ent' = IF Evictable THEN [ent EXCEPT !.has = FALSE] ELSE ent
    /\ viol' = viol \cup (IF CandSet(d) /= ExpectedCand(d) THEN {"Indeterminate_4_7_Candidates"} ELSE {})
                     \cup (IF ~FailClosedSeen THEN {"Invariant_7_2"} ELSE {})
                     \cup (IF Evictable THEN EvFlags ELSE {})
    /\ UNCHANGED <<clk, flt, down, dpOn, dpAt, hid, hreq, nid, gOn, gws, ga, gfresh, gnon, gid, gact, gdig>>

\* One call under the token, of any action type and digest, taking the arm the entry and the check decide.
Call(a, d) == Collision(a, d) \/ Replay(a, d) \/ Fresh(a, d) \/ Reentry(a, d) \/ Unknown(a, d)

\* ----------------------------------------------------------------------------------------------
\* The other writers: the eviction leg, the clock, the outage and the second caller
\* ----------------------------------------------------------------------------------------------

\* The eviction leg evicts an entry the rules let it (Housekeeping 4 to 9), in a transaction of its own.
Evict ==
    /\ LegMay
    /\ ent' = [ent EXCEPT !.has = FALSE]
    /\ viol' = viol \cup EvFlags
    /\ UNCHANGED <<clk, calls, flt, down, dpOn, dpAt, hid, hreq, nid, gOn, gws, ga, gfresh, gnon, gid, gact, gdig>>

\* The clock advances one tick.
Tick ==
    /\ clk < MaxClk
    /\ clk' = clk + 1
    /\ UNCHANGED <<calls, flt, down, dpOn, dpAt, ent, hid, hreq, nid, gOn, gws, ga, gfresh, gnon, gid, gact, gdig, viol>>

\* Duplicate Prevention's store becomes unavailable, spending one of the outages the run may hold.
GoDown ==
    /\ ~down /\ flt < MaxFault
    /\ down' = TRUE
    /\ flt' = flt + 1
    /\ UNCHANGED <<clk, calls, dpOn, dpAt, ent, hid, hreq, nid, gOn, gws, ga, gfresh, gnon, gid, gact, gdig, viol>>

\* Duplicate Prevention's store comes back.
GoUp ==
    /\ down
    /\ down' = FALSE
    /\ UNCHANGED <<clk, calls, flt, dpOn, dpAt, ent, hid, hreq, nid, gOn, gws, ga, gfresh, gnon, gid, gact, gdig, viol>>

\* A caller under another token releases the held commitment.
OtherRelease ==
    /\ hid /= 0
    /\ hid' = 0
    /\ hreq' = 0
    /\ UNCHANGED <<clk, calls, flt, down, dpOn, dpAt, ent, nid, gOn, gws, ga, gfresh, gnon, gid, gact, gdig, viol>>

\* A caller under another token places a commitment for a requester of its own.
OtherPlace ==
    /\ hid = 0 /\ nid < MaxId
    /\ nid' = nid + 1
    /\ hid' = nid + 1
    /\ \E r \in Digs : hreq' = r
    /\ UNCHANGED <<clk, calls, flt, down, dpOn, dpAt, ent, gOn, gws, ga, gfresh, gnon, gid, gact, gdig, viol>>

Next ==
    \/ \E a \in Acts, d \in Digs : Call(a, d)
    \/ Evict \/ Tick \/ GoDown \/ GoUp \/ OtherRelease \/ OtherPlace

Spec == Init /\ [][Next]_vars

\* ----------------------------------------------------------------------------------------------
\* The invariants
\* ----------------------------------------------------------------------------------------------

\* Invariant 1.1 — two place_hold calls carrying one token and one digest answer alike inside the window.
Invariant_1_1 == "Invariant_1_1" \notin viol

\* Invariant 2.1 — two resolving calls carrying one token and one digest answer alike inside the window.
Invariant_2_1 == "Invariant_2_1" \notin viol

\* Invariant 2.2 — the composition never calls the constituent twice for the token inside a window,
\* a resolving action's re-entry excepted.
Invariant_2_2 == "Invariant_2_2" \notin viol

\* Invariant 2.3 — a re-entry that follows an earlier run inside the window changes nothing in the
\* constituent (it rests on Provisional Commitment Invariant 2, single resolution).
Invariant_2_3 == "Invariant_2_3" \notin viol

\* Invariant 3.1 — the token binds one commitment id inside one window.
Invariant_3_1 == "Invariant_3_1" \notin viol

\* Invariant 4.1 — the token binds one action type: no two entries inside one window carry two, and
\* no replay answers a call of another action type than its entry's.
Invariant_4_1 == "Invariant_4_1" \notin viol

\* Invariant 4.2 — the token binds one parameters digest, the same two ways.
Invariant_4_2 == "Invariant_4_2" \notin viol

\* Invariant 7.1 — an entry is evicted only after the window elapsed since its pending instant and
\* after Duplicate Prevention's guard elapsed.
Invariant_7_1 == "Invariant_7_1" \notin viol

\* Invariant 7.2 — a call that finds no entry and a not-seen token stands as a fresh request.
Invariant_7_2 == "Invariant_7_2" \notin viol

\* Invariant 8.2 — an admitted first invocation reaches Provisional Commitment exactly once inside the window.
Invariant_8_2 == "Invariant_8_2" \notin viol

\* Check 4.1 / Housekeeping 6 — no evicted entry belongs to a token the check answered seen for.
Check_4_1_NoSeenEvicted == "Check_4_1_NoSeenEvicted" \notin viol

\* Check 4.2 / Housekeeping 5 — no evicted entry was younger than the window.
Check_4_2_NoYoungEvicted == "Check_4_2_NoYoungEvicted" \notin viol

\* Composes 7 / Action wiring 25 — an entry inside its window has Duplicate Prevention's guard recorded
\* alongside it: the token reads as seen for as long as the entry may answer.
Composes_7_GuardRecordedWithEntry == (ent.has /\ (clk < ent.at + Window)) => GuardLive

\* Term fresh request — the arm named fresh is the one the check answered not-seen for.
Wiring_FreshMeansNotSeen == "Wiring_FreshMeansNotSeen" \notin viol

\* Indeterminate outcome 10, 13 — outcome-unknown answers only a place_hold, a re-run only a resolving
\* action, and each only where the token read as seen with no entry found.
Indeterminate_10_13_Arms == "Indeterminate_10_13_Arms" \notin viol

\* Indeterminate outcome 3, 4, 7 — outcome-unknown carries exactly the held commitments whose
\* requester equals the call's: none or the one commitment held.
Indeterminate_4_7_Candidates == "Indeterminate_4_7_Candidates" \notin viol

\* Indeterminate outcome 8 — an entry a re-entry wrote carries the recovered mark, and only one.
Indeterminate_8_RecoveredMarked == "Indeterminate_8_RecoveredMarked" \notin viol

\* Wiring decision 2 — every constituent answer a fresh request gets, a rejection included, has its
\* entry: the answer is on the entry the moment the call returns.
Wiring_2_RejectionRecorded == "Wiring_2_RejectionRecorded" \notin viol

====
