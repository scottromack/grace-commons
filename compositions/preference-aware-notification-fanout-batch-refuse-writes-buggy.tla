---- MODULE preference-aware-notification-fanout-batch-refuse-writes-buggy ----
\* BUGGY TWIN (refuse-writes): A disposition answered yielded because Event Log refused it is written anyway (Action wiring 14 broken).
\* The checker must reject it. Everything else is the correct model.
\* Grace Commons — Preference-Aware Notification Fanout composition, the batch.
\* Spec-level formal sibling of compositions/preference-aware-notification-fanout.md, beside
\* preference-aware-notification-fanout.tla. Derived validator; the English spec is the single
\* source of truth. On any disagreement, diagnose per the entry *The conflict protocol* in
\* pressure-testing.md.
\*
\* WHY A SECOND MODEL
\* The first model (preference-aware-notification-fanout.tla) follows one disposition pair
\* through its two writers, the lease, the gap run and the cap. It holds one subscriber: with two,
\* the writers' states multiply over each pair and the space passes the checker's cap of 200,000
\* states. The claims that need several subscribers are about the invocation's loop alone, so they
\* have their own small model here: the invocation, the clock, a foreign holder of a pair, and Event
\* Log refusing an append.
\*
\* WHAT THIS MODEL CHECKS
\* One invocation over two queried subscribers, whatever the clock, a foreign holder and the
\* journal do:
\*   - Invariant 1.1   when the invocation returns, every queried subscriber is answered once, in
\*                     the created, failed, suppressed or yielded list; a yielded subscriber was
\*                     written for by no one in the invocation (Action wiring 14); a created,
\*                     failed or suppressed answer names a disposition event the journal holds.
\*   - Action wiring 13   a lapsed lease answers the held subscriber and every subscriber the
\*                     invocation has not reached as yielded, and the invocation returns.
\*   - Action wiring 60, 24, 30   a foreign holder at the read, and a refused append, answer the
\*                     one subscriber as yielded and write nothing.
\*   - Action wiring 11, 12   a pair that already carries a disposition event is answered with it
\*                     and not written again.
\*
\* BOUND
\* Two subscribers (the held one and the one the invocation has not reached), lease and invocation
\* duration bound D = 2. Exhaustive; the state count is recorded in the .cfg.
\*
\* SCOPE (named)
\* - The gate is a nondeterministic verdict (deliver, suppress, fail): the cap, the quiet window and
\*   the rest are the first model's and the page's pure gate.
\* - A foreign holder is the second writer of the first model abstracted to what the invocation
\*   sees: it holds a pair for a lease, and may commit a delivery event before the lease runs out.
\* - The invocation's death is a stall that never ends: it leaves the held pair to the lease and
\*   the rest to the gap run, which the first model follows.
\*
\* ENCODING (the proven idiom of compositions/compensable-workflow.tla)
\* - No Sequences, RECURSIVE or CHOOSE; flat \E/\A; column-aligned junctions; every implication
\*   parenthesized; the operators below are pure over their arguments.

EXTENDS Naturals

CONSTANTS Subs,             \* the queried subscribers
          D                 \* the lease length, which is the invocation duration bound

VARIABLES
    now,        \* the clock since the fanout fired, held at the invocation duration bound
    inv,        \* the invocation: idle | loop | done
    hp,         \* the pair the invocation holds ("none" when none)
    hl,         \* the time left on the invocation's lease (0: expired, or none held)
    hv,         \* the verdict the invocation holds between its gate and its commit
    res,        \* Subs -> the invocation's answer for the subscriber
    ans,        \* Subs -> how many times the invocation answered the subscriber
    iw,         \* Subs -> the invocation wrote for the subscriber
    ev,         \* Subs -> the pair's operative disposition event: none | created | failed | supp
    fh          \* Subs -> the time left on a foreign holder's lease on the pair

vars == <<now, inv, hp, hl, hv, res, ans, iw, ev, fh>>

\* ----- pure helpers over their arguments -----

\* The event a verdict commits.
EvOf(v) == IF v = "deliver" THEN "created" ELSE IF v = "fail" THEN "failed" ELSE "supp"

\* The list a verdict, or a disposition event, puts the subscriber in.
ResOf(v) == IF v = "deliver" THEN "created" ELSE IF v = "fail" THEN "failed" ELSE "suppressed"
AnsOf(e) == IF e = "created" THEN "created" ELSE IF e = "failed" THEN "failed" ELSE "suppressed"

\* ----- state -----

TypeOK ==
    /\ now \in 0..D
    /\ inv \in {"idle", "loop", "done"}
    /\ hp \in Subs \cup {"none"}
    /\ hl \in 0..D
    /\ hv \in {"none", "deliver", "supp", "fail"}
    /\ res \in [Subs -> {"none", "created", "failed", "suppressed", "yielded"}]
    /\ ans \in [Subs -> 0..2]
    /\ iw \in [Subs -> BOOLEAN]
    /\ ev \in [Subs -> {"none", "created", "failed", "supp"}]
    /\ fh \in [Subs -> 0..D]

Init ==
    /\ now = 0
    /\ inv = "idle"
    /\ hp = "none"
    /\ hl = 0
    /\ hv = "none"
    /\ res = [p \in Subs |-> "none"]
    /\ ans = [p \in Subs |-> 0]
    /\ iw = [p \in Subs |-> FALSE]
    /\ ev = [p \in Subs |-> "none"]
    /\ fh = [p \in Subs |-> 0]

\* Time passes once the fanout has fired: the clock counts to the invocation duration bound and
\* holds there, and every lease shortens by one until it expires.
Tick ==
    /\ inv /= "idle"
    /\ now' = IF now < D THEN now + 1 ELSE now
    /\ hl' = IF hl > 0 THEN hl - 1 ELSE 0
    /\ fh' = [p \in Subs |-> IF fh[p] > 0 THEN fh[p] - 1 ELSE 0]
    /\ UNCHANGED <<inv, hp, hv, res, ans, iw, ev>>

\* [Fanout Shaped] journals the initiation entry and starts its loop (Action wiring 5, 8).
Initiate ==
    /\ inv = "idle"
    /\ inv' = "loop"
    /\ UNCHANGED <<now, hp, hl, hv, res, ans, iw, ev, fh>>

\* The invocation takes a subscriber's exclusion with a lease of length D, inside its invocation
\* duration bound, when no foreign holder holds the pair (Action wiring 10; Capability requirement
\* 31, 34, 35, 38).
Take(p) ==
    /\ inv = "loop"
    /\ now < D
    /\ hp = "none"
    /\ res[p] = "none"
    /\ fh[p] = 0
    /\ hp' = p
    /\ hl' = D
    /\ hv' = "none"
    /\ UNCHANGED <<now, inv, res, ans, iw, ev, fh>>

\* A foreign holder holds the pair at the read: the subscriber is yielded and nothing is written
\* (Action wiring 60, 14).
Yield(p) ==
    /\ inv = "loop"
    /\ hp = "none"
    /\ res[p] = "none"
    /\ fh[p] > 0
    /\ res' = [res EXCEPT ![p] = "yielded"]
    /\ ans' = [ans EXCEPT ![p] = ans[p] + 1]
    /\ UNCHANGED <<now, inv, hp, hl, hv, iw, ev, fh>>

\* The read under the exclusion finds a disposition event: the invocation answers the event's
\* disposition and writes nothing (Action wiring 10 to 12).
Seen(p) ==
    /\ hp = p
    /\ hv = "none"
    /\ hl > 0
    /\ ev[p] /= "none"
    /\ res' = [res EXCEPT ![p] = AnsOf(ev[p])]
    /\ ans' = [ans EXCEPT ![p] = ans[p] + 1]
    /\ hp' = "none"
    /\ hl' = 0
    /\ UNCHANGED <<now, inv, hv, iw, ev, fh>>

\* The gate renders one verdict for a pair with no disposition event (Action wiring 15 to 18).
Verdict(p) ==
    /\ hp = p
    /\ hv = "none"
    /\ hl > 0
    /\ ev[p] = "none"
    /\ \E v \in {"deliver", "supp", "fail"} : hv' = v
    /\ UNCHANGED <<now, inv, hp, hl, res, ans, iw, ev, fh>>

\* The disposition commits as one (Execution Contract Database 1; Action wiring 19 to 29), the lease
\* checked at the commit (Action wiring 43), and the subscriber is answered in the verdict's list.
Commit(p) ==
    /\ hp = p
    /\ hv /= "none"
    /\ hl > 0
    /\ ev' = [ev EXCEPT ![p] = EvOf(hv)]
    /\ res' = [res EXCEPT ![p] = ResOf(hv)]
    /\ ans' = [ans EXCEPT ![p] = ans[p] + 1]
    /\ iw' = [iw EXCEPT ![p] = TRUE]
    /\ hp' = "none"
    /\ hl' = 0
    /\ hv' = "none"
    /\ UNCHANGED <<now, inv, fh>>

\* Event Log refuses the append: nothing is written, the create with it; the subscriber is answered
\* yielded (Action wiring 24, 30).
Refuse(p) ==
    /\ hp = p
    /\ hv /= "none"
    /\ hl > 0
    /\ res' = [res EXCEPT ![p] = "yielded"]
    /\ ans' = [ans EXCEPT ![p] = ans[p] + 1]
    /\ iw' = [iw EXCEPT ![p] = TRUE]
    /\ hp' = "none"
    /\ hl' = 0
    /\ hv' = "none"
    /\ UNCHANGED <<now, inv, ev, fh>>

\* The lease expired before the commit: the invocation writes nothing, answers the held subscriber
\* and every subscriber it has not answered as yielded, and returns (Action wiring 13, 14, 43, 44).
Lapse ==
    /\ hp /= "none"
    /\ hl = 0
    /\ res' = [q \in Subs |-> IF res[q] = "none" THEN "yielded" ELSE res[q]]
    /\ ans' = [q \in Subs |-> IF res[q] = "none" THEN ans[q] + 1 ELSE ans[q]]
    /\ inv' = "done"
    /\ hp' = "none"
    /\ hv' = "none"
    /\ UNCHANGED <<now, hl, iw, ev, fh>>

\* Every subscriber answered: the invocation returns its result.
Finish ==
    /\ inv = "loop"
    /\ hp = "none"
    /\ \A p \in Subs : res[p] /= "none"
    /\ inv' = "done"
    /\ UNCHANGED <<now, hp, hl, hv, res, ans, iw, ev, fh>>

\* A foreign holder (a [Redispose] caller, or the gap run) takes a pair no one holds.
ForeignTake(p) ==
    /\ inv /= "idle"
    /\ fh[p] = 0
    /\ ~(hp = p /\ hl > 0)
    /\ fh' = [fh EXCEPT ![p] = D]
    /\ UNCHANGED <<now, inv, hp, hl, hv, res, ans, iw, ev>>

\* A foreign holder commits a delivery event for a pair with none, inside its lease, and releases.
ForeignCommit(p) ==
    /\ fh[p] > 0
    /\ ev[p] = "none"
    /\ ev' = [ev EXCEPT ![p] = "created"]
    /\ fh' = [fh EXCEPT ![p] = 0]
    /\ UNCHANGED <<now, inv, hp, hl, hv, res, ans, iw>>

Next ==
    \/ Tick
    \/ Initiate
    \/ Lapse
    \/ Finish
    \/ \E p \in Subs :
        \/ Take(p)
        \/ Yield(p)
        \/ Seen(p)
        \/ Verdict(p)
        \/ Commit(p)
        \/ Refuse(p)
        \/ ForeignTake(p)
        \/ ForeignCommit(p)

Spec == Init /\ [][Next]_vars

\* ----- the invariants -----

\* Invariant 1.1: once the invocation returns, every queried subscriber is answered exactly once, in
\* one list; a yielded subscriber was written for by no one in the invocation (Action wiring 14); a
\* created, failed or suppressed answer names a disposition event.
Invariant_1_1 ==
    inv = "done" =>
        (\A p \in Subs :
            /\ ans[p] = 1
            /\ res[p] /= "none"
            /\ ((res[p] = "yielded") => ~iw[p])
            /\ ((res[p] \in {"created", "failed", "suppressed"}) => (ev[p] /= "none")))

\* Action wiring 13: the invocation returns only with every subscriber answered; a lapse leaves none
\* unreached.
Action_13_LapseYieldsRemaining == inv = "done" => (\A p \in Subs : res[p] /= "none")

\* Invariant 1.1, read at every state: no subscriber is answered twice.
Invariant_1_1_Once == \A p \in Subs : ans[p] <= 1

====
