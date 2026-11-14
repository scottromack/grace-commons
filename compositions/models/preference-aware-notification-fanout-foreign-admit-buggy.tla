---- MODULE preference-aware-notification-fanout-foreign-admit-buggy ----
\* BUGGY TWIN (foreign-admit): The per-disposition exclusion admits a foreign holder (Capability requirement 38 broken).
\* The checker must reject it. Everything else is the correct model.
\* Grace Commons — Preference-Aware Notification Fanout composition.
\* Spec-level formal sibling of compositions/preference-aware-notification-fanout.md.
\* Derived validator; the English spec is the single source of truth. On any
\* disagreement, diagnose per the entry *The conflict protocol* in pressure-testing.md.
\*
\* Re-derived 2026-11-09 (the first model, 2026-06-12, checked one claim: the frequency-cap
\* bound under concurrent invocations, over one principal and a single observe-and-commit step).
\* It now carries what the page grew into: the invocation and a second writer, a [Redispose]
\* or the gap run's repair, as two processes over one disposition pair under a per-disposition
\* exclusion whose lease expiry is the holder's terminus; the disposition's create and its
\* delivery event as one commit (Execution Contract Database 1); the gap leg bounded below by
\* the young-invocation edge and writing its intent first; and the abandonment record. The
\* invocation's loop over several subscribers is the second model, beside this one:
\* preference-aware-notification-fanout-batch.tla.
\*
\* WHAT THIS MODEL CHECKS
\* One disposition pair of one fanout, whatever the invocation, the redisposer, the gap run, the
\* transport, the clock and another fanout to the same principal do:
\*   - Invariant 9.1   a disposition pair never carries two live Notification records.
\*   - Invariant 1.1   when the invocation returns, the subscriber is answered, a yielded one was
\*                     written for by no one in the invocation, and a created, failed or
\*                     suppressed answer names a disposition event the journal holds.
\*   - Invariant 5.1, 5.2   a suppression or a failure answered is a suppression or failure event.
\*   - Invariant 4.1, 4.2   the principal's committed deliveries never pass the cap, and no delivery
\*                     lands between a gate's observation and the commit it decides (the
\*                     per-principal exclusion, Capability requirement 16 to 18).
\*   - Invariant 8.1   no record is created from a payload whose digest differs from the
\*                     initiation entry's (Action wiring 40, Reconciliation 7).
\*   - Invariant 10.1, 10.2   one initiation entry per fanout id; no disposition before it.
\*   - Invariant 2.1   a suppressed or failed pair gets no create in the pass.
\*   - Action wiring 45   no disposition lands on a pair an abandonment record covers.
\*   - Reconciliation 3, 4   the gap run writes nothing for a young invocation.
\*   - Reconciliation 8   the gap run repairs and abandons nothing before its intent lands.
\*   - Reconciliation 20   the gap run abandons only a gap principal (a pair with no disposition
\*                     event).
\*
\* BOUND
\* Two subscribers, Cap = 2 (a delivery, a retry and another fanout's delivery are not all admitted),
\* lease and invocation duration bound D = 2, create latency Cr = 1 (the gap leg's lower edge is
\* 3). Exhaustive. The clock counts to the lower edge and holds there, and each lease counts down
\* to expiry, so the space is finite without a clock bound. Two subscribers passed the old
\* checker's 200,000-state cap (the writers' states multiply over each pair); on TLC they take
\* 11,564,902 states and 64 s and hold, and the .cfg takes two. The loop over several subscribers
\* has its own model, preference-aware-notification-fanout-batch.tla. The state counts and the
\* bound-bump runs are in the .cfg.
\*
\* HOW AN INVARIANT IS READ
\* The journal is the page's only truth, and a pair's reads derive from it (Composition state 13:
\* the latest disposition event is the pair's operative disposition). The log grows with the run,
\* so the model keeps what a read derives: the pair's operative event, the status of its latest
\* record and the count of earlier records still live, beside the count of committed deliveries
\* the cap reads. A property of the state is an invariant over the state. A property of a step
\* (no create on a suppression, no repair before the intent, no write for a young invocation) is a
\* name the step adds to `viol` when it breaks the rule, and the named invariants say `viol` does
\* not hold their name. A step reads the world, never the rule it is checked against, so a rule a
\* step gets wrong is caught.
\*
\* THE TWO WRITERS AND THE EXCLUSION
\* A writer is the invocation (`inv`) or the redisposer (`rd`: a [Redispose] caller, or the gap
\* run calling [Redispose] as the holder). Each takes the pair's exclusion with a lease of length D
\* (Capability requirement 31 to 35), reads the pair's latest disposition event, runs the gate and
\* commits; those are separate steps, so the clock can run between them and a lease can lapse. A
\* writer whose lease lapsed writes nothing; the invocation answers the pair and every subscriber
\* it has not reached as yielded (Action wiring 13, 43, 44; Reconciliation 25). The exclusion is
\* the lease: a pair whose holder's lease has not expired admits no other holder (Capability
\* requirement 38), and one whose lease has expired admits any (Capability requirement 36).
\* The invocation takes a new pair only inside its invocation duration bound (Term invocation
\* duration bound); a stall after the take is the lease's case. A stalled writer that never wakes
\* is the model's death, so no separate death step is kept.
\*
\* SCOPE (named)
\* - Quiet windows, channel selection, the suspended and no-record rules, and the replay of a
\*   verdict (Invariant 2.2, 3, 7.1; Shaping gate 1 to 22; Verdict replay) are pure functions of
\*   the record, the now and the history, with no cross-writer surface. The gate here is a
\*   nondeterministic verdict: deliver (only below the cap), suppress with retry eligibility,
\*   suppress without it, fail.
\* - The retry horizon is longer than the model's clock, so a retry-eligible suppression stays
\*   retryable (Term retryable disposition); the audit horizon is too, so no entry ages.
\* - A [Redispose] and the gap run's repair are each one writer with the same three steps. The gap
\*   run's selection (a queried subscriber with no disposition event) and its intent are modelled
\*   once. The cadence, the liveness sum (Capability requirement 29), the run bound and the
\*   eventual accounting of every queried subscriber inside the reconciliation window
\*   (Composition state 12, Check 1.1) are arithmetic over time and a promise about repeated runs;
\*   the model checks that every run's writes are safe and leaves the arithmetic to the page's
\*   start refusal. A principal a run carries to the next run stays a gap principal here, so the
\*   next run is the same step again.
\* - The best-effort arm of Invariant 4 (Invariant 4.3, Check 2.4, Reconciliation 30 to 32, 35,
\*   38) is a recount over the journal with a deadline; the model takes the serialized arm and the
\*   twin that splits the observation from the commit.
\* - The delivery count index, the fanout dispositions index and their rebuilds (Composition state
\*   1 to 9) are derived and outside the model (Execution Contract Composition state).
\* - The audience check (Action wiring 52, 53) and the unsubscribed reason: a subscriber who left
\*   is a suppression without retry eligibility, which the gate's verdicts already include.
\* - Primitive policy, the refusals before any write (Primitive policy 1 to 13), the payload cap
\*   and Staleness are single-call refusals that touch no state.
\*
\* ENCODING (the proven idiom of compositions/compensable-workflow.tla)
\* - No Sequences, RECURSIVE or CHOOSE; flat \E/\A; column-aligned junctions; every implication
\*   in a junction list parenthesized (the checker binds `=>` tighter than `/\`); the operators
\*   below are pure over their arguments and read no state variable free.

EXTENDS Naturals

CONSTANTS Subs,             \* the queried subscribers
          Cap,              \* the interpreted frequency cap
          D,                \* the lease length, which is the invocation duration bound
          Cr                \* the notification create latency

Writers == {"inv", "rd"}

\* The gap leg's lower edge: nothing younger than the invocation duration bound and the create
\* latency is examined (Reconciliation 3, Term young invocation).
Lower == D + Cr

VARIABLES
    now,        \* the clock since the fanout fired, counted up to the lower edge and held there
    ninit,      \* initiation entries under the fanout id (one, by Invariant 10.1)
    inv,        \* the invocation: idle | loop | done
    wp,         \* Writers -> the pair the writer holds ("none" when no pair)
    wl,         \* Writers -> the time left on the writer's lease (0: expired, or no pair held)
    wv,         \* Writers -> the verdict the writer holds between its gate and its commit
    wo,         \* Writers -> 1 once a delivery lands between the writer's gate and its commit
    wk,         \* Writers -> the call: the redisposer's red (a caller) or gap (the gap run)
    wq,         \* Writers -> the payload content the call carries: orig | altered
    res,        \* Subs -> the invocation's answer for the subscriber
    iw,         \* Subs -> the invocation wrote for the subscriber
    ev,         \* Subs -> the pair's operative disposition event
    rs,         \* Subs -> the status of the pair's latest record
    old,        \* Subs -> earlier records of the pair still live
    cnt,        \* Subs -> the principal's committed in-window deliveries (all fanouts)
    abn,        \* Subs -> an abandonment record covers the principal
    intent,     \* the gap run's reconcile intent has landed
    mode,       \* the gap run's mode: none | repair | abandon
    badrec,     \* a record was created from a payload the digest does not name
    viol        \* the names of the rules a step has broken

vars == <<now, ninit, inv, wp, wl, wv, wo, wk, wq, res, iw, ev, rs, old, cnt, abn,
          intent, mode, badrec, viol>>

\* ----- pure helpers over their arguments -----

\* A record is live while Pending or Delivered (Term live record).
Live(s) == s \in {"pending", "delivered"}

\* The answer a disposition event gives the invocation's result list.
AnsOf(e) == IF e = "created" THEN "created"
            ELSE IF e = "failed" THEN "failed"
            ELSE "suppressed"

\* The event a verdict commits.
EvOf(v) == IF v = "deliver" THEN "created"
           ELSE IF v = "fail" THEN "failed"
           ELSE IF v = "supH" THEN "suppH"
           ELSE "suppN"

\* The list a verdict puts the subscriber in.
ResOf(v) == IF v = "deliver" THEN "created"
            ELSE IF v = "fail" THEN "failed"
            ELSE "suppressed"

\* A retryable disposition (Term retryable disposition; Action wiring 46, 47): a failure event, a
\* retry-eligible suppression, a delivery event whose record is failed or expired, or a queried
\* pair with no disposition event.
Retryable(e, s) == \/ e = "none"
                   \/ e = "failed"
                   \/ e = "suppH"
                   \/ (e = "created" /\ s \in {"failed", "expired"})

\* Writer w holds pair p: it took the pair and its lease has not expired.
HeldBy(P, Lv, w, p) == P[w] = p /\ Lv[w] > 0

\* No writer but w holds pair p (Capability requirement 36 to 38).
FreeFor(P, Lv, w, p) == TRUE

\* The per-principal exclusion is held over a cap evaluation and the delivery commit after it
\* (Capability requirement 16 to 18): a writer holding the pair with a deliver verdict.
Pex(P, Lv, V, p) == \E w \in Writers : HeldBy(P, Lv, w, p) /\ V[w] = "deliver"

\* The count of live records a pair carries.
LiveCount(s, o) == o + (IF Live(s) THEN 1 ELSE 0)

\* The rules a redisposition's commit breaks, read from the world: the gap run's call for a young
\* invocation (Reconciliation 3, 4), before its intent (Reconciliation 8), a [Redispose] over an
\* abandonment record (Action wiring 45; Term abandonment record, the terminal record).
RdFlags(isGap, T, lo, itn, ab) ==
    (IF isGap /\ T < lo THEN {"Reconciliation_3_4"} ELSE {})
    \cup (IF isGap /\ ~itn THEN {"Reconciliation_8"} ELSE {})
    \cup (IF ab THEN {"Action_45"} ELSE {})

\* ----- state -----

TypeOK ==
    /\ now \in 0..Lower
    /\ ninit \in 0..2
    /\ inv \in {"idle", "loop", "done"}
    /\ wp \in [Writers -> Subs \cup {"none"}]
    /\ wl \in [Writers -> 0..D]
    /\ wv \in [Writers -> {"none", "deliver", "supH", "supN", "fail"}]
    /\ wo \in [Writers -> 0..1]
    /\ wk \in [Writers -> {"inv", "red", "gap"}]
    /\ wq \in [Writers -> {"orig", "altered"}]
    /\ res \in [Subs -> {"none", "created", "failed", "suppressed", "yielded"}]
    /\ iw \in [Subs -> BOOLEAN]
    /\ ev \in [Subs -> {"none", "created", "failed", "suppH", "suppN"}]
    /\ rs \in [Subs -> {"none", "pending", "delivered", "failed", "expired"}]
    /\ old \in [Subs -> 0..2]
    /\ cnt \in [Subs -> 0..(Cap + 1)]
    /\ abn \in [Subs -> BOOLEAN]
    /\ intent \in BOOLEAN
    /\ mode \in {"none", "repair", "abandon"}
    /\ badrec \in BOOLEAN
    /\ viol \subseteq {"Invariant_2_1", "Reconciliation_3_4", "Reconciliation_8",
                       "Reconciliation_20", "Action_45"}

Init ==
    /\ now = 0
    /\ ninit = 0
    /\ inv = "idle"
    /\ wp = [w \in Writers |-> "none"]
    /\ wl = [w \in Writers |-> 0]
    /\ wv = [w \in Writers |-> "none"]
    /\ wo = [w \in Writers |-> 0]
    /\ wk = [w \in Writers |-> IF w = "inv" THEN "inv" ELSE "red"]
    /\ wq = [w \in Writers |-> "orig"]
    /\ res = [p \in Subs |-> "none"]
    /\ iw = [p \in Subs |-> FALSE]
    /\ ev = [p \in Subs |-> "none"]
    /\ rs = [p \in Subs |-> "none"]
    /\ old = [p \in Subs |-> 0]
    /\ cnt = [p \in Subs |-> 0]
    /\ abn = [p \in Subs |-> FALSE]
    /\ intent = FALSE
    /\ mode = "none"
    /\ badrec = FALSE
    /\ viol = {}

\* ----- the clock -----

\* Time passes once the fanout has fired: the clock counts up to the gap leg's lower edge and
\* holds there, and every lease shortens by one until it expires.
Tick ==
    /\ ninit >= 1
    /\ now' = IF now < Lower THEN now + 1 ELSE now
    /\ wl' = [w \in Writers |-> IF wl[w] > 0 THEN wl[w] - 1 ELSE 0]
    /\ UNCHANGED <<ninit, inv, wp, wv, wo, wk, wq, res, iw, ev, rs, old, cnt, abn,
                   intent, mode, badrec, viol>>

\* ----- the invocation -----

\* [Fanout Shaped] journals the initiation entry once, after the subscriber query answers
\* (Action wiring 5; Invariant 10.1). Everything the invocation writes follows it (Invariant 10.2).
Initiate ==
    /\ inv = "idle"
    /\ ninit = 0
    /\ ninit' = 1
    /\ inv' = "loop"
    /\ UNCHANGED <<now, wp, wl, wv, wo, wk, wq, res, iw, ev, rs, old, cnt, abn,
                   intent, mode, badrec, viol>>

\* The invocation takes a subscriber's per-disposition exclusion with a lease of length D
\* (Action wiring 10; Capability requirement 31, 34, 35). It takes a new pair only inside its
\* invocation duration bound, the longest a [Fanout Shaped] may run (Term invocation duration
\* bound); a stall after the take is the lease's case.
InvTake(p) ==
    /\ inv = "loop"
    /\ now < D
    /\ wp["inv"] = "none"
    /\ res[p] = "none"
    /\ FreeFor(wp, wl, "inv", p)
    /\ wp' = [wp EXCEPT !["inv"] = p]
    /\ wl' = [wl EXCEPT !["inv"] = D]
    /\ wv' = [wv EXCEPT !["inv"] = "none"]
    /\ UNCHANGED <<now, ninit, inv, wo, wk, wq, res, iw, ev, rs, old, cnt, abn,
                   intent, mode, badrec, viol>>

\* A foreign holder holds the pair at the read: the subscriber is yielded and nothing is written
\* (Action wiring 60, 14).
InvYield(p) ==
    /\ inv = "loop"
    /\ wp["inv"] = "none"
    /\ res[p] = "none"
    /\ ~FreeFor(wp, wl, "inv", p)
    /\ res' = [res EXCEPT ![p] = "yielded"]
    /\ UNCHANGED <<now, ninit, inv, wp, wl, wv, wo, wk, wq, iw, ev, rs, old, cnt, abn,
                   intent, mode, badrec, viol>>

\* Every subscriber answered: the invocation returns its result.
Finish ==
    /\ inv = "loop"
    /\ wp["inv"] = "none"
    /\ \A p \in Subs : res[p] /= "none"
    /\ inv' = "done"
    /\ UNCHANGED <<now, ninit, wp, wl, wv, wo, wk, wq, res, iw, ev, rs, old, cnt, abn,
                   intent, mode, badrec, viol>>

\* ----- the writers: read, gate, commit -----

\* The read under the exclusion finds a disposition event: the invocation answers the event's
\* disposition and writes nothing; the gap run writes nothing for the principal (Action wiring 10
\* to 12; Reconciliation 11). The exclusion is released.
GateSeen(w, p) ==
    /\ wp[w] = p
    /\ wv[w] = "none"
    /\ wl[w] > 0
    /\ ev[p] /= "none"
    /\ (w = "inv" \/ wk[w] = "gap")
    /\ res' = IF w = "inv" THEN [res EXCEPT ![p] = AnsOf(ev[p])] ELSE res
    /\ wp' = [wp EXCEPT ![w] = "none"]
    /\ wl' = [wl EXCEPT ![w] = 0]
    /\ wk' = [wk EXCEPT ![w] = IF w = "inv" THEN "inv" ELSE "red"]
    /\ UNCHANGED <<now, ninit, inv, wv, wo, wq, iw, ev, rs, old, cnt, abn,
                   intent, mode, badrec, viol>>

\* The gate renders one verdict, reading the cap under the per-principal exclusion. Deliver is
\* open only below the cap. The invocation reads a pair with no disposition event; a [Redispose]
\* caller reads a retryable one.
GateVerdict(w, p) ==
    /\ wp[w] = p
    /\ wv[w] = "none"
    /\ wl[w] > 0
    /\ (ev[p] = "none" \/ (w = "rd" /\ wk[w] = "red"))
    /\ \E v \in {"deliver", "supH", "supN", "fail"} :
        /\ ((v = "deliver") => (cnt[p] < Cap))
        /\ wv' = [wv EXCEPT ![w] = v]
    /\ wo' = [wo EXCEPT ![w] = 0]
    /\ UNCHANGED <<now, ninit, inv, wp, wl, wk, wq, res, iw, ev, rs, old, cnt, abn,
                   intent, mode, badrec, viol>>

\* The disposition commits as one: the create and its delivery event together, or the suppression
\* or failure event (Execution Contract Database 1; Action wiring 19 to 29). The lease is checked
\* at the commit (Action wiring 43; Reconciliation 25). The exclusion is released.
CommitWrite(w, p) ==
    /\ wp[w] = p
    /\ wv[w] /= "none"
    /\ wl[w] > 0
    /\ ev' = [ev EXCEPT ![p] = EvOf(wv[w])]
    /\ rs' = [rs EXCEPT ![p] = IF wv[w] = "deliver" THEN "pending" ELSE rs[p]]
    /\ old' = [old EXCEPT ![p] = IF wv[w] = "deliver" /\ Live(rs[p]) /\ old[p] < 2
                                 THEN old[p] + 1 ELSE old[p]]
    /\ cnt' = [cnt EXCEPT ![p] = IF wv[w] = "deliver" /\ cnt[p] <= Cap THEN cnt[p] + 1
                                 ELSE cnt[p]]
    /\ res' = IF w = "inv" THEN [res EXCEPT ![p] = ResOf(wv[w])] ELSE res
    /\ iw' = IF w = "inv" THEN [iw EXCEPT ![p] = TRUE] ELSE iw
    /\ badrec' = IF wv[w] = "deliver" /\ wq[w] = "altered" THEN TRUE ELSE badrec
    /\ viol' = viol \cup RdFlags(w = "rd" /\ wk[w] = "gap", now, Lower, intent, abn[p])
                    \cup (IF wv[w] /= "deliver" /\ rs'[p] /= rs[p] THEN {"Invariant_2_1"} ELSE {})
    /\ wp' = [wp EXCEPT ![w] = "none"]
    /\ wv' = [wv EXCEPT ![w] = "none"]
    /\ wl' = [wl EXCEPT ![w] = 0]
    /\ wo' = [wo EXCEPT ![w] = 0]
    /\ wk' = [wk EXCEPT ![w] = IF w = "inv" THEN "inv" ELSE "red"]
    /\ UNCHANGED <<now, ninit, inv, wq, abn, intent, mode>>

\* Event Log refuses the append: nothing is written, the create with it. The invocation answers
\* the subscriber as yielded; a [Redispose] answers journal-rejected; the gap run carries the
\* principal to its next run (Action wiring 24, 30, 56; Reconciliation 18).
CommitRefuse(w, p) ==
    /\ wp[w] = p
    /\ wv[w] /= "none"
    /\ wl[w] > 0
    /\ res' = IF w = "inv" THEN [res EXCEPT ![p] = "yielded"] ELSE res
    /\ wp' = [wp EXCEPT ![w] = "none"]
    /\ wv' = [wv EXCEPT ![w] = "none"]
    /\ wl' = [wl EXCEPT ![w] = 0]
    /\ wo' = [wo EXCEPT ![w] = 0]
    /\ wk' = [wk EXCEPT ![w] = IF w = "inv" THEN "inv" ELSE "red"]
    /\ UNCHANGED <<now, ninit, inv, wq, iw, ev, rs, old, cnt, abn,
                   intent, mode, badrec, viol>>

\* The writer's lease expired before its commit: it writes nothing. The invocation answers the
\* subscriber and every subscriber it has not answered as yielded and returns; a redisposer
\* answers yielded (Action wiring 13, 14, 43, 44; Reconciliation 25).
Lapse(w) ==
    /\ wp[w] /= "none"
    /\ wl[w] = 0
    /\ wp' = [wp EXCEPT ![w] = "none"]
    /\ wv' = [wv EXCEPT ![w] = "none"]
    /\ wo' = [wo EXCEPT ![w] = 0]
    /\ wk' = [wk EXCEPT ![w] = IF w = "inv" THEN "inv" ELSE "red"]
    /\ res' = IF w = "inv"
              THEN [q \in Subs |-> IF res[q] = "none" THEN "yielded" ELSE res[q]]
              ELSE res
    /\ inv' = IF w = "inv" THEN "done" ELSE inv
    /\ UNCHANGED <<now, ninit, wl, wq, iw, ev, rs, old, cnt, abn,
                   intent, mode, badrec, viol>>

\* ----- the redisposer and the gap run -----

\* A [Redispose] caller, or the gap run calling [Redispose] as the exclusion's holder, takes a
\* pair: the fanout is known, the payload digest matches, no abandonment record covers the
\* principal, the pair's disposition is retryable (Action wiring 37 to 47). The gap run calls only
\* for a gap principal, after its intent, in repair mode, for an invocation that is not young
\* (Reconciliation 3, 8, 10, 17, 21).
RdTake(p) ==
    /\ ninit >= 1
    /\ wp["rd"] = "none"
    /\ ~abn[p]
    /\ FreeFor(wp, wl, "rd", p)
    /\ \E k \in {"red", "gap"} :
        /\ ((k = "red") => Retryable(ev[p], rs[p]))
        /\ ((k = "gap") => (intent /\ mode = "repair" /\ now >= Lower /\ ev[p] = "none"))
        /\ \E q \in {"orig"} :
            /\ wk' = [wk EXCEPT !["rd"] = k]
            /\ wq' = [wq EXCEPT !["rd"] = q]
    /\ wp' = [wp EXCEPT !["rd"] = p]
    /\ wl' = [wl EXCEPT !["rd"] = D]
    /\ wv' = [wv EXCEPT !["rd"] = "none"]
    /\ UNCHANGED <<now, ninit, inv, wo, res, iw, ev, rs, old, cnt, abn,
                   intent, mode, badrec, viol>>

\* The gap run's reconcile intent lands before any repair, once the invocation is not young, for
\* an invocation with a gap principal; the run is a repair run or an abandon run (Reconciliation 3,
\* 8, 9, 20, 21, 37).
GapIntent ==
    /\ ninit >= 1
    /\ ~intent
    /\ now >= Lower
    /\ \E p \in Subs : ev[p] = "none" /\ ~abn[p]
    /\ intent' = TRUE
    /\ \E m \in {"repair", "abandon"} : mode' = m
    /\ UNCHANGED <<now, ninit, inv, wp, wl, wv, wo, wk, wq, res, iw, ev, rs, old, cnt, abn,
                   badrec, viol>>

\* The gap run abandons a gap principal under the pair's exclusion: an abandonment record covers it
\* and no disposition event does (Reconciliation 20, 22, 24, 37).
GapAbandon(p) ==
    /\ intent
    /\ mode = "abandon"
    /\ now >= Lower
    /\ ev[p] = "none"
    /\ ~abn[p]
    /\ \A v \in Writers : ~HeldBy(wp, wl, v, p)
    /\ abn' = [abn EXCEPT ![p] = TRUE]
    /\ viol' = viol \cup (IF ev[p] /= "none" THEN {"Reconciliation_20"} ELSE {})
                    \cup (IF now < Lower THEN {"Reconciliation_3_4"} ELSE {})
                    \cup (IF ~intent THEN {"Reconciliation_8"} ELSE {})
    /\ UNCHANGED <<now, ninit, inv, wp, wl, wv, wo, wk, wq, res, iw, ev, rs, old, cnt,
                   intent, mode, badrec>>

\* ----- the world -----

\* The transport ends a Pending Notification record: delivered, failed or expired
\* (Term live record; Action wiring 46).
Transport(p) ==
    /\ rs[p] = "pending"
    /\ \E s \in {"delivered", "failed", "expired"} : rs' = [rs EXCEPT ![p] = s]
    /\ UNCHANGED <<now, ninit, inv, wp, wl, wv, wo, wk, wq, res, iw, ev, old, cnt, abn,
                   intent, mode, badrec, viol>>

\* Another fanout delivers to the same principal. Its cap evaluation takes the per-principal
\* exclusion (Capability requirement 16 to 18), so it waits while a writer of this fanout holds
\* the exclusion over a deliver verdict; a delivery that lands inside a writer's gate-to-commit
\* span makes the writer's observed count stale.
Other(p) ==
    /\ cnt[p] < Cap
    /\ ~Pex(wp, wl, wv, p)
    /\ cnt' = [cnt EXCEPT ![p] = cnt[p] + 1]
    /\ wo' = [w \in Writers |-> IF HeldBy(wp, wl, w, p) /\ wv[w] = "deliver" THEN 1 ELSE wo[w]]
    /\ UNCHANGED <<now, ninit, inv, wp, wl, wv, wk, wq, res, iw, ev, rs, old, abn,
                   intent, mode, badrec, viol>>

Next ==
    \/ Tick
    \/ Initiate
    \/ Finish
    \/ GapIntent
    \/ \E w \in Writers : Lapse(w)
    \/ \E p \in Subs :
        \/ InvTake(p)
        \/ InvYield(p)
        \/ RdTake(p)
        \/ GapAbandon(p)
        \/ Transport(p)
        \/ Other(p)
        \/ \E w \in Writers : GateSeen(w, p)
        \/ \E w \in Writers : GateVerdict(w, p)
        \/ \E w \in Writers : CommitWrite(w, p)
        \/ \E w \in Writers : CommitRefuse(w, p)

Spec == Init /\ [][Next]_vars

\* ----- the invariants -----

\* Invariant 9.1: a disposition pair never carries two live Notification records.
Invariant_9_1 == \A p \in Subs : LiveCount(rs[p], old[p]) <= 1

\* Invariant 1.1: once the invocation returns, every queried subscriber is answered in exactly one
\* list (the answer is a function of the subscriber), a yielded subscriber was written for by no one
\* in the invocation, and a created, failed or suppressed answer names a disposition event.
Invariant_1_1 ==
    inv = "done" =>
        (\A p \in Subs :
            /\ res[p] /= "none"
            /\ ((res[p] = "yielded") => ~iw[p])
            /\ ((res[p] \in {"created", "failed", "suppressed"}) => (ev[p] /= "none")))

\* Invariant 5.1, 5.2: a suppression or a failure the invocation answers is a journaled event.
Invariant_5 ==
    \A p \in Subs : (res[p] \in {"suppressed", "failed"}) => (ev[p] /= "none")

\* Invariant 4.1: the principal's committed deliveries never pass the cap.
Invariant_4_1 == \A p \in Subs : cnt[p] <= Cap

\* Invariant 4.2: the count a gate observed is the true count at the commit it decides: no delivery
\* lands while a writer holds the exclusion over a deliver verdict.
Invariant_4_2 ==
    \A w \in Writers : \A p \in Subs :
        (HeldBy(wp, wl, w, p) /\ wv[w] = "deliver") => (wo[w] = 0)

\* Invariant 8.1: no record is created from a payload whose digest differs from the initiation
\* entry's.
Invariant_8_1 == ~badrec

\* Invariant 10.1: two initiation entries never carry one fanout id.
Invariant_10_1 == ninit <= 1

\* Invariant 10.2: no disposition lands before the initiation entry.
Invariant_10_2 ==
    (ninit = 0) => (\A p \in Subs : ev[p] = "none" /\ rs[p] = "none" /\ ~abn[p] /\ ~intent)

\* Invariant 2.1: a suppressed or failed pair gets no create in the pass. Read from the step.
Invariant_2_1 == "Invariant_2_1" \notin viol

\* Reconciliation 3, 4: the gap run writes nothing for a young invocation.
Reconciliation_3_4 == "Reconciliation_3_4" \notin viol

\* Reconciliation 8: the gap run repairs nothing before its intent lands.
Reconciliation_8 == "Reconciliation_8" \notin viol

\* Reconciliation 20: the gap run abandons only a gap principal.
Reconciliation_20 == "Reconciliation_20" \notin viol

\* Action wiring 45: no disposition lands on a pair an abandonment record covers (the abandonment
\* record is terminal, Term abandonment record).
Action_45 == "Action_45" \notin viol

====
