---- MODULE reserve-from-pool-retry-probe-settled-from-journal ----
\* EXPECT: violation — reachability probe: a call settled from the journal's outcome entry, the binding entry written by it.
\* Grace Commons — Reserve from Pool composition.
\* Spec-level formal sibling of compositions/reserve-from-pool.md, beside
\* compositions/reserve-from-pool.tla (the reservation's arc against the pool).
\* Derived validator; the English spec is the single source of truth. On any
\* disagreement, diagnose per the entry *The conflict protocol* in pressure-testing.md.
\*
\* Written 2026-11-09. The arc model holds the reservation, the pool, the binding and the order of
\* an action's writes; this one holds what makes every action safe to repeat (Invariant 5): the
\* token results map, Duplicate Prevention's window, the journal read on a token the guard has not
\* seen, the attestation, and the outcome entry. They are two models because the space of the
\* tokens' states times the arc's passes the checker's 200,000-state cap.
\*
\* WHAT THIS MODEL CHECKS
\* One reservation action called again and again under two tokens, whatever the verdict, the window
\* and the eviction do:
\*   - Invariant 5.1     a later call carrying a settled call's token and digest answers alike
\*                       inside the idempotency window (a replay, or a settle from the journal).
\*   - Invariant 5.2     no token drives two executions of the act (the page states it inside the
\*                       window; the model reads it for all time, because the journal read of
\*                       Action wiring 12 to 15 carries the guarantee past the window).
\*   - Invariant 5.3     a call reusing a token across action types answers token-collision.
\*   - Action wiring 7, 125  a digest that differs from the settled or journaled one answers
\*                       token-collision.
\*   - Action wiring 18  a settle from a reserve outcome entry writes the binding entry.
\*   - Action wiring 126, 13  a token the journal holds is never attested again.
\*   - Invariant 6.1     an outcome entry stands exactly when a state change committed.
\*   - Invariant 6.2, 8.2  an attestation binds the action reference of the one invocation,
\*                       composed of the action type and the token.
\*   - Invariant 6.3     an outcome entry has its intent entry.
\*   - Execution Contract Read 4 (Primitive policy 10)  a refusal writes nothing: the attestation
\*                       and the intent entry stand exactly as often as the act was admitted.
\*   - Composition state 22  a token results entry is evicted only after Duplicate Prevention's
\*                       check answers not-seen.
\*
\* BOUND
\* Two tokens, two action types ([Reserve] and [Confirm Reservation] stand for the page's four),
\* two digests, and at most two executions per token (a second one is a bug). Exhaustive. The
\* idempotency window is not a number: it elapses at any time (the guard forgets the token), the
\* weakest reading. Duplicate Prevention's check is the boolean `dp`. Three tokens (79,507 states)
\* and three digests (4,096) are the bump runs in the .cfg.
\*
\* HOW AN ACTION IS READ
\* A call is one transaction (Execution Contract Database 1): the attestation, the intent entry, the
\* act, the outcome entry, the token results entry and Duplicate Prevention's record commit together
\* or not at all, so the model has one step per branch the page names. The act's verdict is a free
\* choice: commit (an outcome entry), settle (an answer a constituent decides, such as
\* pool-closed or not-held, with the intent entry and no outcome entry, Action wiring 52, 89), or
\* refuse (nothing written). Each execution answers a number, one more than the executions before
\* it, so an act run twice answers two different numbers and a replay that is not a replay shows.
\* A property of a step is a name the step adds to `viol`; the named invariants say `viol` does not
\* hold their name. A step reads the world, never the rule it is checked against.
\*
\* SCOPE (named)
\* - Primitive policy 1 to 8 (blank and over-long tokens, a blank credential, the payload cap) and
\*   the attestation's refusals (Action wiring 22 to 25) are refusals before any write, and touch
\*   no state.
\* - The pool, the commitment and the binding's rebuild are the arc model's; here the binding is one
\*   flag a reserve outcome entry earns, written by the background step or by a settle from the
\*   journal (Action wiring 18).
\* - The digest function, its sharing across instances (Capability requirement 28, 31) and the
\*   token's byte-exact comparison (Primitive policy 3, 4) are deployment settings; the model holds
\*   the digest as one of two values.
\* - The audit horizon: no journal entry ages here. After it, a token the journal no longer holds
\*   would run afresh, which the page leaves to the retention duties (Capability requirement 29).
\*
\* ENCODING (the proven idiom of compositions/compensable-workflow.tla)
\* - No Sequences, RECURSIVE or CHOOSE; flat \E/\A; column-aligned junctions; every implication in
\*   a junction list parenthesized (the checker binds `=>` tighter than `/\`); the operators below
\*   are pure over their arguments and read no state variable free.

EXTENDS Naturals

CONSTANTS Tk,           \* the idempotency tokens
          Ty,           \* the action types a token may be called under
          Dg            \* the parameters digests a call may carry

\* An attestation's action reference: the action type and the token joined (Term action reference).
\* The buggy twin that names the type alone uses "any" for the token.
Refs == Ty \X (Tk \cup {"any"})

VARIABLES
    dp,         \* Tk -> Duplicate Prevention's check answers seen (the window has not elapsed)
    tty,        \* Tk -> the token results entry's action type ("none": no entry)
    td,         \* Tk -> the token results entry's parameters digest
    tres,       \* Tk -> the token results entry's result (0: none)
    ji,         \* Tk -> the journal holds the token's intent entry
    jo,         \* Tk -> the journal holds the token's outcome entry
    jty,        \* Tk -> the action type the journal's entries carry
    jd,         \* Tk -> the parameters digest the journal's entries carry
    jres,       \* Tk -> the result the outcome entry carries (0: none)
    att,        \* Tk -> the action reference of the token's attestation ("none": no attestation)
    na,         \* Tk -> attestations committed under the token
    ex,         \* Tk -> executions the token admitted (a commit or a settle verdict)
    cm,         \* Tk -> state changes committed under the token
    ans1,       \* Tk -> the first answer the token's first execution gave (0: none)
    bn,         \* Tk -> the binding entry of the token's reservation stands
    sfj,        \* Tk -> a call was settled from the journal's outcome entry
    viol        \* the names of the rules a step has broken

vars == <<dp, tty, td, tres, ji, jo, jty, jd, jres, att, na, ex, cm, ans1, bn, sfj, viol>>

\* ----- the shape -----

\* The shape of every variable.
TypeOK ==
    /\ dp \in [Tk -> BOOLEAN]
    /\ tty \in [Tk -> Ty \cup {"none"}]
    /\ td \in [Tk -> Dg \cup {"none"}]
    /\ tres \in [Tk -> 0..2]
    /\ ji \in [Tk -> BOOLEAN]
    /\ jo \in [Tk -> BOOLEAN]
    /\ jty \in [Tk -> Ty \cup {"none"}]
    /\ jd \in [Tk -> Dg \cup {"none"}]
    /\ jres \in [Tk -> 0..2]
    /\ att \in [Tk -> Refs \cup {"none"}]
    /\ na \in [Tk -> 0..2]
    /\ ex \in [Tk -> 0..2]
    /\ cm \in [Tk -> 0..2]
    /\ ans1 \in [Tk -> 0..2]
    /\ bn \in [Tk -> BOOLEAN]
    /\ sfj \in [Tk -> BOOLEAN]
    /\ viol \subseteq {"Invariant_5_1", "Invariant_5_3", "Action_7_125", "Composition_state_22"}

\* No token seen, nothing journaled, nothing attested.
Init ==
    /\ dp = [t \in Tk |-> FALSE]
    /\ tty = [t \in Tk |-> "none"]
    /\ td = [t \in Tk |-> "none"]
    /\ tres = [t \in Tk |-> 0]
    /\ ji = [t \in Tk |-> FALSE]
    /\ jo = [t \in Tk |-> FALSE]
    /\ jty = [t \in Tk |-> "none"]
    /\ jd = [t \in Tk |-> "none"]
    /\ jres = [t \in Tk |-> 0]
    /\ att = [t \in Tk |-> "none"]
    /\ na = [t \in Tk |-> 0]
    /\ ex = [t \in Tk |-> 0]
    /\ cm = [t \in Tk |-> 0]
    /\ ans1 = [t \in Tk |-> 0]
    /\ bn = [t \in Tk |-> FALSE]
    /\ sfj = [t \in Tk |-> FALSE]
    /\ viol = {}

\* ----- a call under a token the guard has seen (inside the window) -----

\* Duplicate Prevention's check answers seen and a matching token results entry stands: the call
\* answers the entry's result. A replay calls no constituent and writes no journal entry
\* (Action wiring 5, 8, 9). The step names the rules it breaks if the entry is not the call's or
\* the result is not the one first answered.
Replay(t, ty, d) ==
    /\ dp[t]
    /\ tty[t] = ty
    /\ td[t] = d
    /\ viol' = viol \cup (IF tres[t] /= ans1[t] THEN {"Invariant_5_1"} ELSE {})
                     \cup (IF tty[t] /= ty THEN {"Invariant_5_3"} ELSE {})
                     \cup (IF td[t] /= d THEN {"Action_7_125"} ELSE {})
    /\ UNCHANGED <<dp, tty, td, tres, ji, jo, jty, jd, jres, att, na, ex, cm, ans1, bn, sfj>>

\* The guard has seen the token and the entry names another action type or another digest: the call
\* answers token-collision and writes nothing (Action wiring 6, 7).
CollideSeen(t, ty, d) ==
    /\ dp[t]
    /\ tty[t] /= "none"
    /\ ((tty[t] /= ty) \/ (td[t] /= d))
    /\ UNCHANGED <<dp, tty, td, tres, ji, jo, jty, jd, jres, att, na, ex, cm, ans1, bn, sfj, viol>>

\* The guard has seen the token and no token results entry stands: the call answers
\* recording-failure carrying outcome and settles nothing (Action wiring 10, 11). That answer is not
\* the settled one, so the step names Invariant 5.1 when the token had one.
SeenNoEntry(t, ty, d) ==
    /\ dp[t]
    /\ tty[t] = "none"
    /\ viol' = viol \cup (IF ans1[t] > 0 THEN {"Invariant_5_1"} ELSE {})
    /\ UNCHANGED <<dp, tty, td, tres, ji, jo, jty, jd, jres, att, na, ex, cm, ans1, bn, sfj>>

\* ----- a call under a token the guard has not seen: the journal is read first -----

\* The journal holds the action's own outcome entry for the token under the call's digest: the call
\* settles the entry's result, recording it against the token (Action wiring 14), and writes the
\* binding entry from a reserve outcome entry that lacks one (Action wiring 18). The step names the
\* rules it breaks if the entry is not the call's.
SettleFromJournal(t, ty, d) ==
    /\ ~dp[t]
    /\ jo[t]
    /\ jty[t] = ty
    /\ jd[t] = d
    /\ dp' = [dp EXCEPT ![t] = TRUE]
    /\ tty' = [tty EXCEPT ![t] = ty]
    /\ td' = [td EXCEPT ![t] = d]
    /\ tres' = [tres EXCEPT ![t] = jres[t]]
    /\ bn' = [bn EXCEPT ![t] = IF ty = "R" THEN TRUE ELSE bn[t]]
    /\ sfj' = [sfj EXCEPT ![t] = TRUE]
    /\ viol' = viol \cup (IF jres[t] /= ans1[t] THEN {"Invariant_5_1"} ELSE {})
                     \cup (IF jty[t] /= ty THEN {"Invariant_5_3"} ELSE {})
                     \cup (IF jd[t] /= d THEN {"Action_7_125"} ELSE {})
    /\ UNCHANGED <<ji, jo, jty, jd, jres, att, na, ex, cm, ans1>>

\* The journal holds an entry for the token that is not the call's own, or the call's own under
\* another digest: token-collision, nothing written (Action wiring 15, 125).
CollideJournal(t, ty, d) ==
    /\ ~dp[t]
    /\ (ji[t] \/ jo[t])
    /\ ((jty[t] /= ty) \/ (jd[t] /= d))
    /\ UNCHANGED <<dp, tty, td, tres, ji, jo, jty, jd, jres, att, na, ex, cm, ans1, bn, sfj, viol>>

\* The journal holds the call's own intent entry and no outcome entry: the act may have committed,
\* so the call answers recording-failure carrying outcome and runs nothing (Action wiring 19).
IntentOnly(t, ty, d) ==
    /\ ~dp[t]
    /\ ji[t]
    /\ ~jo[t]
    /\ jty[t] = ty
    /\ jd[t] = d
    /\ UNCHANGED <<dp, tty, td, tres, ji, jo, jty, jd, jres, att, na, ex, cm, ans1, bn, sfj, viol>>

\* The journal holds nothing for the token: the call attests, records its intent entry, runs the act
\* and commits. The verdict is the act's: commit (an outcome entry) or settle (an answer a
\* constituent decides, with the intent entry and no outcome entry). The result is one more than the
\* executions the token has had.
Fresh(t, ty, d) ==
    /\ ~dp[t]
    /\ ~ji[t]
    /\ ~jo[t]
    /\ ex[t] < 2
    /\ \E v \in {"commit", "settle"} :
        /\ dp' = [dp EXCEPT ![t] = TRUE]
        /\ tty' = [tty EXCEPT ![t] = ty]
        /\ td' = [td EXCEPT ![t] = d]
        /\ tres' = [tres EXCEPT ![t] = ex[t] + 1]
        /\ ji' = [ji EXCEPT ![t] = TRUE]
        /\ jo' = [jo EXCEPT ![t] = (v = "commit")]
        /\ jty' = [jty EXCEPT ![t] = ty]
        /\ jd' = [jd EXCEPT ![t] = d]
        /\ jres' = [jres EXCEPT ![t] = IF v = "commit" THEN ex[t] + 1 ELSE 0]
        /\ att' = [att EXCEPT ![t] = <<ty, t>>]
        /\ na' = [na EXCEPT ![t] = na[t] + 1]
        /\ ex' = [ex EXCEPT ![t] = ex[t] + 1]
        /\ cm' = [cm EXCEPT ![t] = IF v = "commit" THEN cm[t] + 1 ELSE cm[t]]
        /\ ans1' = [ans1 EXCEPT ![t] = IF ans1[t] = 0 THEN ex[t] + 1 ELSE ans1[t]]
    /\ UNCHANGED <<bn, sfj, viol>>

\* The act is refused, or the attestation or a constituent fails: nothing is written, the attestation
\* and the intent entry included (Execution Contract Read 4), so a retry under the token runs afresh.
Refuse(t, ty, d) ==
    /\ ~dp[t]
    /\ ~ji[t]
    /\ ~jo[t]
    /\ UNCHANGED <<dp, tty, td, tres, ji, jo, jty, jd, jres, att, na, ex, cm, ans1, bn, sfj, viol>>

\* ----- outside every call -----

\* Duplicate Prevention's window elapses and the guard forgets the token.
Elapse(t) ==
    /\ dp[t]
    /\ dp' = [dp EXCEPT ![t] = FALSE]
    /\ UNCHANGED <<tty, td, tres, ji, jo, jty, jd, jres, att, na, ex, cm, ans1, bn, sfj, viol>>

\* A token results entry is evicted, only after the guard's check answers not-seen for the token
\* (Composition state 22). The journal keeps the outcome entry.
Evict(t) ==
    /\ ~dp[t]
    /\ tty[t] /= "none"
    /\ tty' = [tty EXCEPT ![t] = "none"]
    /\ td' = [td EXCEPT ![t] = "none"]
    /\ tres' = [tres EXCEPT ![t] = 0]
    /\ UNCHANGED <<dp, ji, jo, jty, jd, jres, att, na, ex, cm, ans1, bn, sfj, viol>>

\* The binding entry is written after a reserve outcome entry lands (Action wiring 78), outside the
\* call's transaction.
Bind(t) ==
    /\ jo[t]
    /\ jty[t] = "R"
    /\ ~bn[t]
    /\ bn' = [bn EXCEPT ![t] = TRUE]
    /\ UNCHANGED <<dp, tty, td, tres, ji, jo, jty, jd, jres, att, na, ex, cm, ans1, sfj, viol>>

Next ==
    \/ \E t \in Tk :
        \/ Elapse(t)
        \/ Evict(t)
        \/ Bind(t)
        \/ \E ty \in Ty : \E d \in Dg :
            \/ Replay(t, ty, d)
            \/ CollideSeen(t, ty, d)
            \/ SeenNoEntry(t, ty, d)
            \/ SettleFromJournal(t, ty, d)
            \/ CollideJournal(t, ty, d)
            \/ IntentOnly(t, ty, d)
            \/ Fresh(t, ty, d)
            \/ Refuse(t, ty, d)

Spec == Init /\ [][Next]_vars

\* ----- the invariants -----

\* Invariant 5.1: a later call carrying a settled call's token and digest answers alike inside the
\* window. Read from the step: a replay or a settle from the journal answers the first answer.
Invariant_5_1 == "Invariant_5_1" \notin viol

\* Invariant 5.2: the act runs at most once for a token. The model reads it for all time (see the
\* header).
Invariant_5_2 == \A t \in Tk : ex[t] <= 1

\* Invariant 5.3: a call reusing a token across action types answers token-collision.
Invariant_5_3 == "Invariant_5_3" \notin viol

\* Action wiring 7, 125: a digest other than the settled or journaled one answers token-collision.
Action_7_125 == "Action_7_125" \notin viol

\* Action wiring 18: a call settled from a reserve outcome entry has written the reservation's
\* binding entry.
Action_18 == \A t \in Tk : (sfj[t] /\ jty[t] = "R") => bn[t]

\* Action wiring 126, 13: the token is attested once; a call the journal already holds attests
\* nothing.
Action_126 == \A t \in Tk : na[t] <= 1

\* Execution Contract Read 4: the attestation and the intent entry stand exactly as often as the
\* act was admitted; a refusal leaves neither.
Read_4 == \A t \in Tk : (na[t] = ex[t]) /\ (ji[t] = (ex[t] > 0))

\* Invariant 6.1: an outcome entry stands exactly when a state change committed, once.
Invariant_6_1 == \A t \in Tk : (cm[t] <= 1) /\ (jo[t] = (cm[t] = 1))

\* Invariant 6.2, 8.2: the attestation binds the action reference recomposed from the entry's own
\* action type and token.
Invariant_8_2 == \A t \in Tk : ji[t] => (att[t] = <<jty[t], t>>)

\* Invariant 6.3: an outcome entry has the intent entry that carries its attestation.
Invariant_6_3 == \A t \in Tk : jo[t] => ji[t]

\* Composition state 22: a token results entry is not evicted before the check answers not-seen.
Composition_state_22 == "Composition_state_22" \notin viol

\* Reachability probe: the negation of a shape the model must be able to reach.
Probe_settled_from_journal == ~(\E t \in Tk : sfj[t] /\ bn[t])

====
