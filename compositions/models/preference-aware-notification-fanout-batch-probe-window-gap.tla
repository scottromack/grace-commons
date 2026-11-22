---- MODULE preference-aware-notification-fanout-batch-probe-window-gap ----
\* EXPECT: violation — reachability probe: at quiescence after the window has passed, before a gap run begun after it has ended, a queried subscriber a run before the window carried has no disposition event, no abandonment record and no at-risk record (Composition state 12 read literally breaks with every rule kept).
\* Grace Commons — Preference-Aware Notification Fanout composition, the batch.
\* Spec-level formal sibling of compositions/preference-aware-notification-fanout.md, beside
\* preference-aware-notification-fanout.tla. Derived validator; the English spec is the single
\* source of truth. On any disagreement, diagnose per the entry *The conflict protocol* in
\* pressure-testing.md.
\*
\* WHY A SECOND MODEL
\* The first model (preference-aware-notification-fanout.tla) follows one disposition pair
\* through its two writers, the lease, the gap run and the cap. It held one subscriber: with two,
\* the writers' states multiply over each pair and the space passed the old checker's cap of 200,000
\* states. On TLC the first model takes two subscribers through its .cfg. The claims that need
\* several subscribers are about a loop over them, the invocation's or the gap run's, so they have
\* their own small model here: the invocation, the clock, a foreign holder of a pair, Event Log
\* refusing an append, and (from 2026-11-22) the gap run's repeated runs over the gap principals
\* with the carry and its at-risk record.
\*
\* Re-derived 2026-11-22 (unit `compositions/preference-aware-notification-fanout.md composes
\* Lease`): the per-disposition exclusion is a Lease lease taken by try_take, answering held while
\* another holder's grant stands, read as expired once it lapses (Lease Sizing 2a, 2b) and released
\* on the holder's return; a take whose take age exceeds the invocation duration bound is read as
\* expired (Capability requirement 57); and Composition state 12 is an accounting guarantee: a gap
\* run that carries a principal once the reconciliation window has passed records an at-risk record
\* (Reconciliation 40 to 42), and a principal an at-risk record names is excepted.
\*
\* WHAT THIS MODEL CHECKS
\* One fanout over two queried subscribers, whatever the clock, a foreign holder, the journal and
\* the gap runs do:
\*   - Invariant 1.1   when the invocation returns, every queried subscriber is answered once, in
\*                     the created, failed, suppressed or yielded list; a yielded subscriber was
\*                     written for by no one in the invocation (Action wiring 14); a created,
\*                     failed or suppressed answer names a disposition event the journal holds.
\*   - Action wiring 13   a lapsed lease, or a take past the invocation duration bound (Capability
\*                     requirement 57), answers the held subscriber and every subscriber the
\*                     invocation has not reached as yielded, and the invocation returns.
\*   - Action wiring 60, 24, 30   try_take answering held at the read, and a refused append, answer
\*                     the one subscriber as yielded and write nothing.
\*   - Action wiring 11, 12   a pair that already carries a disposition event is answered with it
\*                     and not written again.
\*   - Composition state 12 (Check 1.1)   at quiescence, once the reconciliation window has passed
\*                     and a gap run begun after it has ended, every queried subscriber carries a
\*                     disposition event, or an abandonment record or an at-risk record names it
\*                     (Reconciliation 10, 17 to 20, 25, 37, 39 to 41). See READING.
\*   - Reconciliation 42   no two at-risk records under the fanout id name one principal, however
\*                     often the gap runs carry it.
\*
\* READING (a finding, recorded in the Ledger's formal line, not cured)
\* Reconciliation 41 owes the at-risk record only for a carry made once the window has passed, so a
\* principal the last gap run before the window's end carried has no disposition event, no
\* abandonment record and no at-risk record from the window's end until the first gap run after it
\* carries it again: Composition state 12 and Check 1.1 read at that quiescence break with every rule
\* kept (probe `-probe-window-gap`). The check is read from the end of the first gap run begun after
\* the window (window state `swept`), at most a cadence and a run bound later.
\*
\* BOUND
\* Two subscribers (the held one and one the invocation has not reached; two gap principals in one
\* run), lease and invocation duration bound D = 2, create latency Cr = 1 (the first instant past
\* the young edge is 2D + Cr + 1 = 6). Exhaustive; the state count is recorded in the .cfg.
\*
\* SCOPE (named)
\* - The gate is a nondeterministic verdict (deliver, suppress, fail): the cap, the quiet window and
\*   the rest are the first model's and the page's pure gate.
\* - A foreign holder is a [Redispose] caller of the first model abstracted to what the loops see:
\*   it holds a pair for a lease, and may commit a delivery event before the lease runs out; it is
\*   refused over an abandonment record (Action wiring 45).
\* - The gap run's mode is its arguments: repair (a payload and abandon false, Reconciliation 17) or
\*   abandon (abandon true, or a blank payload, Reconciliation 20, 37; the reason is not kept). Its
\*   repair is a [Redispose] call as the holder that commits (any disposition), is refused (yielded,
\*   journal-rejected or not-retryable, Reconciliation 18) or outlives its lease (Reconciliation
\*   25). The intent and its order are the first model's (Reconciliation 8); a run here begins with
\*   its intent landed. Event Log refusing the gap run's own appends (the intent, an abandonment, an
\*   at-risk record) is outside the model: the page owes the accounting only where they land.
\* - The window's arithmetic: the window exceeds the liveness sum (Capability requirement 29), so it
\*   passes only once the clock stands past the young edge; the cadence (Reconciliation 1) is a gap
\*   run that may start whenever no run is in flight, the run bound a run that ends.
\* - A carry's cause (Reconciliation 40) is the step that carries; the record's fields are the Alloy
\*   model's (preference-aware-notification-fanout.als).
\* - The invocation's death is a stall that never ends: it leaves the held pair to the lease and
\*   the rest to the gap run.
\*
\* ENCODING (the proven idiom of compositions/compensable-workflow.tla)
\* - No Sequences, RECURSIVE or CHOOSE; flat \E/\A; column-aligned junctions; every implication
\*   parenthesized; the operators below are pure over their arguments.

EXTENDS Naturals

CONSTANTS Subs,             \* the queried subscribers
          D,                \* the lease length, which is the invocation duration bound
          Cr                \* the notification create latency

\* The gap leg's lower edge: the first instant past the young edge (Term young invocation:
\* young while `fired instant + D + D + Cr` does not precede now; Reconciliation 3).
Lower == 2 * D + Cr + 1

VARIABLES
    now,        \* the clock since the fanout fired, held at the gap leg's lower edge
    inv,        \* the invocation: idle | loop | done
    hp,         \* the pair the invocation holds ("none" when none)
    hl,         \* the remaining term of the invocation's grant (0: expired, or none held)
    hv,         \* the verdict the invocation holds between its gate and its commit
    res,        \* Subs -> the invocation's answer for the subscriber
    ans,        \* Subs -> how many times the invocation answered the subscriber
    iw,         \* Subs -> the invocation wrote for the subscriber
    ev,         \* Subs -> the pair's operative disposition event: none | created | failed | supp
    fh,         \* Subs -> the remaining term of a foreign holder's grant on the pair
    abn,        \* Subs -> an abandonment record covers the principal
    risk,       \* Subs -> at-risk records under the fanout id naming the principal
    win,        \* the reconciliation window: open | ran (open, a gap run has ended) | passed |
                \* swept (a gap run begun after it passed has ended)
    gr,         \* the gap run in flight: idle | repair | abandon
    glate,      \* the run in flight began once the window had passed (its decided instant)
    gd,         \* Subs -> the run in flight has dealt with the principal
    gp,         \* the pair the gap run holds ("none" when none)
    gw          \* the remaining term of the gap run's grant

vars == <<now, inv, hp, hl, hv, res, ans, iw, ev, fh, abn, risk, win, gr, glate, gd, gp, gw>>

\* ----- pure helpers over their arguments -----

\* The event a verdict commits.
EvOf(v) == IF v = "deliver" THEN "created" ELSE IF v = "fail" THEN "failed" ELSE "supp"

\* The list a verdict, or a disposition event, puts the subscriber in.
ResOf(v) == IF v = "deliver" THEN "created" ELSE IF v = "fail" THEN "failed" ELSE "suppressed"
AnsOf(e) == IF e = "created" THEN "created" ELSE IF e = "failed" THEN "failed" ELSE "suppressed"

\* The at-risk records after a carry: one more where the carrying run's decided instant is past the
\* window (Reconciliation 41), none where one already names the principal (Reconciliation 42).
RiskAfter(r, late) == IF late /\ r = 0 THEN 1 ELSE r

\* ----- state -----

TypeOK ==
    /\ now \in 0..Lower
    /\ inv \in {"idle", "loop", "done"}
    /\ hp \in Subs \cup {"none"}
    /\ hl \in 0..D
    /\ hv \in {"none", "deliver", "supp", "fail"}
    /\ res \in [Subs -> {"none", "created", "failed", "suppressed", "yielded"}]
    /\ ans \in [Subs -> 0..2]
    /\ iw \in [Subs -> BOOLEAN]
    /\ ev \in [Subs -> {"none", "created", "failed", "supp"}]
    /\ fh \in [Subs -> 0..D]
    /\ abn \in [Subs -> BOOLEAN]
    /\ risk \in [Subs -> 0..2]
    /\ win \in {"open", "ran", "passed", "swept"}
    /\ gr \in {"idle", "repair", "abandon"}
    /\ glate \in BOOLEAN
    /\ gd \in [Subs -> BOOLEAN]
    /\ gp \in Subs \cup {"none"}
    /\ gw \in 0..D

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
    /\ abn = [p \in Subs |-> FALSE]
    /\ risk = [p \in Subs |-> 0]
    /\ win = "open"
    /\ gr = "idle"
    /\ glate = FALSE
    /\ gd = [p \in Subs |-> FALSE]
    /\ gp = "none"
    /\ gw = 0

\* Lease's try_take on pair p answers held: a foreign holder's, the invocation's or the gap run's
\* grant on the key has not passed its expires_at (Lease Operation 4, 6b; Invariant 2).
HeldByInv(p) == hp = p /\ hl > 0
HeldByGap(p) == gp = p /\ gw > 0

\* Time passes once the fanout has fired: the clock counts to the gap leg's lower edge and holds
\* there, and every grant's remaining term shortens by one until it expires.
Tick ==
    /\ inv /= "idle"
    /\ now' = IF now < Lower THEN now + 1 ELSE now
    /\ hl' = IF hl > 0 THEN hl - 1 ELSE 0
    /\ fh' = [p \in Subs |-> IF fh[p] > 0 THEN fh[p] - 1 ELSE 0]
    /\ gw' = IF gw > 0 THEN gw - 1 ELSE 0
    /\ UNCHANGED <<inv, hp, hv, res, ans, iw, ev, abn, risk, win, gr, glate, gd, gp>>

\* The reconciliation window passes from the fired instant. It exceeds the liveness sum, the young
\* edge with a cadence and a run bound (Capability requirement 29), so it passes only once the
\* clock stands past the young edge and a gap run has ended.
WindowPasses ==
    /\ win = "ran"
    /\ now = Lower
    /\ win' = "passed"
    /\ UNCHANGED <<now, inv, hp, hl, hv, res, ans, iw, ev, fh, abn, risk, gr, glate, gd, gp, gw>>

\* ----- the invocation -----

\* [Fanout Shaped] journals the initiation entry and starts its loop (Action wiring 5, 8).
Initiate ==
    /\ inv = "idle"
    /\ inv' = "loop"
    /\ UNCHANGED <<now, hp, hl, hv, res, ans, iw, ev, fh, abn, risk, win, gr, glate, gd, gp, gw>>

\* The invocation's try_take answers taken, carrying D as duration, at a take age inside the
\* invocation duration bound (Action wiring 10; Capability requirement 31, 35, 57).
Take(p) ==
    /\ inv = "loop"
    /\ now <= D
    /\ hp = "none"
    /\ res[p] = "none"
    /\ fh[p] = 0
    /\ ~HeldByGap(p)
    /\ hp' = p
    /\ hl' = D
    /\ hv' = "none"
    /\ UNCHANGED <<now, inv, res, ans, iw, ev, fh, abn, risk, win, gr, glate, gd, gp, gw>>

\* The invocation's try_take answers taken at a take age past the invocation duration bound: the
\* lease is read as expired (Capability requirement 57, Lease Sizing 2a), the subscriber and every
\* subscriber not yet answered are yielded, and the invocation returns, releasing the grant
\* (Action wiring 13, 14).
TakeLate(p) ==
    /\ inv = "loop"
    /\ now > D
    /\ hp = "none"
    /\ res[p] = "none"
    /\ fh[p] = 0
    /\ ~HeldByGap(p)
    /\ res' = [q \in Subs |-> IF res[q] = "none" THEN "yielded" ELSE res[q]]
    /\ ans' = [q \in Subs |-> IF res[q] = "none" THEN ans[q] + 1 ELSE ans[q]]
    /\ inv' = "done"
    /\ UNCHANGED <<now, hp, hl, hv, iw, ev, fh, abn, risk, win, gr, glate, gd, gp, gw>>

\* Lease's try_take answers held at the read: the subscriber is yielded and nothing is written
\* (Action wiring 60, 14).
Yield(p) ==
    /\ inv = "loop"
    /\ hp = "none"
    /\ res[p] = "none"
    /\ (fh[p] > 0 \/ HeldByGap(p))
    /\ res' = [res EXCEPT ![p] = "yielded"]
    /\ ans' = [ans EXCEPT ![p] = ans[p] + 1]
    /\ UNCHANGED <<now, inv, hp, hl, hv, iw, ev, fh, abn, risk, win, gr, glate, gd, gp, gw>>

\* The read under the exclusion finds a disposition event: the invocation answers the event's
\* disposition, writes nothing and releases (Action wiring 10 to 12).
Seen(p) ==
    /\ hp = p
    /\ hv = "none"
    /\ hl > 0
    /\ ev[p] /= "none"
    /\ res' = [res EXCEPT ![p] = AnsOf(ev[p])]
    /\ ans' = [ans EXCEPT ![p] = ans[p] + 1]
    /\ hp' = "none"
    /\ hl' = 0
    /\ UNCHANGED <<now, inv, hv, iw, ev, fh, abn, risk, win, gr, glate, gd, gp, gw>>

\* The gate renders one verdict for a pair with no disposition event (Action wiring 15 to 18).
Verdict(p) ==
    /\ hp = p
    /\ hv = "none"
    /\ hl > 0
    /\ ev[p] = "none"
    /\ \E v \in {"deliver", "supp", "fail"} : hv' = v
    /\ UNCHANGED <<now, inv, hp, hl, res, ans, iw, ev, fh, abn, risk, win, gr, glate, gd, gp, gw>>

\* The disposition commits as one (Execution Contract Database 1; Action wiring 19 to 29), the lease
\* read live at the commit (Action wiring 43), the subscriber is answered in the verdict's list, and
\* the grant is released.
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
    /\ UNCHANGED <<now, inv, fh, abn, risk, win, gr, glate, gd, gp, gw>>

\* Event Log refuses the append: nothing is written, the create with it; the subscriber is answered
\* yielded (Action wiring 24, 30).
Refuse(p) ==
    /\ hp = p
    /\ hv /= "none"
    /\ hl > 0
    /\ res' = [res EXCEPT ![p] = "yielded"]
    /\ ans' = [ans EXCEPT ![p] = ans[p] + 1]
    /\ hp' = "none"
    /\ hl' = 0
    /\ hv' = "none"
    /\ UNCHANGED <<now, inv, iw, ev, fh, abn, risk, win, gr, glate, gd, gp, gw>>

\* The lease is read expired before the commit: the invocation writes nothing, answers the held
\* subscriber and every subscriber it has not answered as yielded, and returns (Action wiring 13,
\* 14, 43, 44).
Lapse ==
    /\ hp /= "none"
    /\ hl = 0
    /\ res' = [q \in Subs |-> IF res[q] = "none" THEN "yielded" ELSE res[q]]
    /\ ans' = [q \in Subs |-> IF res[q] = "none" THEN ans[q] + 1 ELSE ans[q]]
    /\ inv' = "done"
    /\ hp' = "none"
    /\ hv' = "none"
    /\ UNCHANGED <<now, hl, iw, ev, fh, abn, risk, win, gr, glate, gd, gp, gw>>

\* Every subscriber answered: the invocation returns its result.
Finish ==
    /\ inv = "loop"
    /\ hp = "none"
    /\ \A p \in Subs : res[p] /= "none"
    /\ inv' = "done"
    /\ UNCHANGED <<now, hp, hl, hv, res, ans, iw, ev, fh, abn, risk, win, gr, glate, gd, gp, gw>>

\* ----- the foreign holder -----

\* A [Redispose] caller's try_take answers taken on a pair no one holds, for a principal no
\* abandonment record covers (Action wiring 42, 45).
ForeignTake(p) ==
    /\ inv /= "idle"
    /\ fh[p] = 0
    /\ ~abn[p]
    /\ ~HeldByInv(p)
    /\ ~HeldByGap(p)
    /\ fh' = [fh EXCEPT ![p] = D]
    /\ UNCHANGED <<now, inv, hp, hl, hv, res, ans, iw, ev, abn, risk, win, gr, glate, gd, gp, gw>>

\* A foreign holder commits a delivery event for a pair with none, inside its lease, and releases.
ForeignCommit(p) ==
    /\ fh[p] > 0
    /\ ev[p] = "none"
    /\ ev' = [ev EXCEPT ![p] = "created"]
    /\ fh' = [fh EXCEPT ![p] = 0]
    /\ UNCHANGED <<now, inv, hp, hl, hv, res, ans, iw, abn, risk, win, gr, glate, gd, gp, gw>>

\* ----- the gap run -----

\* A gap run starts, past the young edge, for an invocation with a gap principal (Reconciliation 1,
\* 3, 8): its intent lands, its mode is its arguments, and its decided instant is past the window
\* or not.
GapStart ==
    /\ inv /= "idle"
    /\ gr = "idle"
    /\ now >= Lower
    /\ \E p \in Subs : ev[p] = "none" /\ ~abn[p]
    /\ \E m \in {"repair", "abandon"} : gr' = m
    /\ glate' = (win \in {"passed", "swept"})
    /\ gd' = [p \in Subs |-> FALSE]
    /\ UNCHANGED <<now, inv, hp, hl, hv, res, ans, iw, ev, fh, abn, risk, win, gp, gw>>

\* The gap run's try_take for a gap principal answers taken, carrying D as duration (Reconciliation
\* 10; Capability requirement 35).
GapTake(p) ==
    /\ gr /= "idle"
    /\ gp = "none"
    /\ ~gd[p]
    /\ ev[p] = "none"
    /\ ~abn[p]
    /\ fh[p] = 0
    /\ ~HeldByInv(p)
    /\ gp' = p
    /\ gw' = D
    /\ UNCHANGED <<now, inv, hp, hl, hv, res, ans, iw, ev, fh, abn, risk, win, gr, glate, gd>>

\* The gap run's try_take for a gap principal answers held: the run carries the principal (carry
\* cause held), writing nothing but the at-risk record a carry past the window owes (Reconciliation
\* 39, 40, 41, 42).
GapHeld(p) ==
    /\ gr /= "idle"
    /\ gp = "none"
    /\ ~gd[p]
    /\ ev[p] = "none"
    /\ ~abn[p]
    /\ (fh[p] > 0 \/ HeldByInv(p))
    /\ gd' = [gd EXCEPT ![p] = TRUE]
    /\ risk' = [risk EXCEPT ![p] = RiskAfter(risk[p], glate)]
    /\ UNCHANGED <<now, inv, hp, hl, hv, res, ans, iw, ev, fh, abn, win, gr, glate, gp, gw>>

\* The repair: [Redispose] as the holder commits a disposition under the live lease, and the grant
\* is released (Reconciliation 17).
GapCommit(p) ==
    /\ gr = "repair"
    /\ gp = p
    /\ gw > 0
    /\ ev[p] = "none"
    /\ \E e \in {"created", "failed", "supp"} : ev' = [ev EXCEPT ![p] = e]
    /\ gd' = [gd EXCEPT ![p] = TRUE]
    /\ gp' = "none"
    /\ gw' = 0
    /\ UNCHANGED <<now, inv, hp, hl, hv, res, ans, iw, fh, abn, risk, win, gr, glate>>

\* [Redispose] answers the gap run yielded, journal-rejected or not-retryable: the run carries the
\* principal (carry cause redispose-refused) and releases (Reconciliation 18, 40, 41, 42).
GapRefused(p) ==
    /\ gr = "repair"
    /\ gp = p
    /\ gw > 0
    /\ gd' = [gd EXCEPT ![p] = TRUE]
    /\ risk' = [risk EXCEPT ![p] = RiskAfter(risk[p], glate)]
    /\ gp' = "none"
    /\ gw' = 0
    /\ UNCHANGED <<now, inv, hp, hl, hv, res, ans, iw, ev, fh, abn, win, gr, glate>>

\* The gap run's lease is read expired before its write: the run carries the principal (carry cause
\* lease-expired), writing nothing but the at-risk record a carry past the window owes
\* (Reconciliation 25, 40, 41, 42).
GapLapse ==
    /\ gp /= "none"
    /\ gw = 0
    /\ gd' = [gd EXCEPT ![gp] = TRUE]
    /\ risk' = [risk EXCEPT ![gp] = RiskAfter(risk[gp], glate)]
    /\ gp' = "none"
    /\ UNCHANGED <<now, inv, hp, hl, hv, res, ans, iw, ev, fh, abn, win, gr, glate, gw>>

\* The abandonment: under the live lease the re-read finds no disposition event and the run records
\* the abandonment record, then releases (Reconciliation 11, 20, 22, 24, 37).
GapAbandon(p) ==
    /\ gr = "abandon"
    /\ gp = p
    /\ gw > 0
    /\ ev[p] = "none"
    /\ abn' = [abn EXCEPT ![p] = TRUE]
    /\ gd' = [gd EXCEPT ![p] = TRUE]
    /\ gp' = "none"
    /\ gw' = 0
    /\ UNCHANGED <<now, inv, hp, hl, hv, res, ans, iw, ev, fh, risk, win, gr, glate>>

\* The run ends once it has dealt with every gap principal (Reconciliation 10: it takes the
\* exclusion for every one). The first run to end marks the window ran; a run begun after the
\* window has passed sweeps it.
GapEnd ==
    /\ gr /= "idle"
    /\ gp = "none"
    /\ \A p \in Subs : gd[p] \/ ev[p] /= "none" \/ abn[p]
    /\ gr' = "idle"
    /\ win' = IF win = "open" THEN "ran"
              ELSE IF glate /\ win = "passed" THEN "swept" ELSE win
    /\ glate' = FALSE
    /\ gd' = [p \in Subs |-> FALSE]
    /\ UNCHANGED <<now, inv, hp, hl, hv, res, ans, iw, ev, fh, abn, risk, gp, gw>>

Next ==
    \/ Tick
    \/ WindowPasses
    \/ Initiate
    \/ Lapse
    \/ Finish
    \/ GapStart
    \/ GapLapse
    \/ GapEnd
    \/ \E p \in Subs :
        \/ Take(p)
        \/ TakeLate(p)
        \/ Yield(p)
        \/ Seen(p)
        \/ Verdict(p)
        \/ Commit(p)
        \/ Refuse(p)
        \/ ForeignTake(p)
        \/ ForeignCommit(p)
        \/ GapTake(p)
        \/ GapHeld(p)
        \/ GapCommit(p)
        \/ GapRefused(p)
        \/ GapAbandon(p)

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

\* Quiescence (Term quiescence): no invocation, redisposition or gap run in flight for the fanout.
Quiescent == inv = "done" /\ gr = "idle" /\ (\A p \in Subs : fh[p] = 0)

\* Composition state 12 and Check 1.1, the accounting guarantee: at quiescence once the window has
\* passed (read from the end of the first gap run begun after it; see READING), every queried
\* subscriber carries a disposition event, or an abandonment record or an at-risk record names it.
Composition_state_12 ==
    (Quiescent /\ win = "swept") =>
        (\A p \in Subs : ev[p] /= "none" \/ abn[p] \/ risk[p] > 0)

\* Reconciliation 42: no two at-risk records under the fanout id name one principal.
Reconciliation_42 == \A p \in Subs : risk[p] <= 1

\* Reachability probe: the negation of "at quiescence after the window has passed, before a gap run begun after it has ended, a queried subscriber a run before the window carried has no disposition event, no abandonment record and no at-risk record (Composition state 12 read literally breaks with every rule kept)"; the checker must find a state where it fails.
Probe_window_gap == ~(Quiescent /\ win = "passed" /\ \E p \in Subs : ev[p] = "none" /\ ~abn[p] /\ risk[p] = 0)

====
