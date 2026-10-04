---- MODULE defensible-retention-buggy ----
\* BUGGY TWIN: a hold is placed outside the record section (Concurrency 5 violated).
\* Grace Commons — Defensible Retention. Spec-level formal sibling of compositions/defensible-retention.md.
\* Derived validator; the English spec is the single source of truth. On any disagreement,
\* diagnose per the entry *The conflict protocol* in pressure-testing.md.
\*
\* Two files carry this one module body. defensible-retention.tla runs the gate: the purge against a
\* placement (GateOn). defensible-retention-outcome.tla runs the record: the purge's outcome against a
\* sweep leg (OutOn). The party a file leaves off takes no step.
\*
\* ONE record, one record section (a Lease on the record reference) on one host clock, three parties:
\*   p  a [Purge Record] invocation under strict mode: takes the section, makes the gate read (the hold
\*      store and the sibling set), and on an empty gate issues Retention Window's purge on a live reading,
\*      within one call pause of asking; the purge lands within one more, or fails. It then writes its
\*      outcome as one record_action, started only while the grant has the record start floor left, and
\*      releases with no call in flight (Concurrency 5 through 24).
\*   q  a placement: a [Place Hold] invocation, or a [Place Record Under Retention] invocation placing a
\*      sibling retention still inside its window. It takes the section and issues its committing call
\*      the same way.
\*   w  a sweep leg over the purge's open marker: takes the section, reads the act's outcome again under
\*      it, and emits a recovery outcome where the store shows the destruction and the trail no outcome
\*      (Reconciliation 11, 20, 21).
\* Any party may stall at any moment for any length; a stalled party is a dead one to everyone else.
\*
\* WHAT THIS MODEL CHECKS
\*   Inv_Gate        no destruction lands over a hold or a live sibling retention standing in the store
\*                   (Invariant 1.1, Invariant 9.1, Retention Window Simultaneous retention 4, 6).
\*   Inv_OneOutcome  one destruction carries at most one record purged outcome (Invariant 5.6, Concurrency 4).
\*
\* THE TWINS, each this file with one constant changed:
\*   -buggy                  HTakes = FALSE       a hold is placed outside the record section (Concurrency 5).
\*   -buggy-sibling          STakes = FALSE       a retention is placed outside the record section (Concurrency 5).
\*   -buggy-gate             GateInside = FALSE   the gate is read before the section is taken (Concurrency 6, 7).
\*   -buggy-margin           Margin = Pause       a committing call is issued on one call pause of margin (Concurrency 14).
\*   -buggy-release          HoldInFlight = FALSE the section is released with a call in flight (Concurrency 22).
\*   -probe-after            a reachability probe: a destruction lands and a hold lands after it.
\*   -outcome-buggy-floor    Floor = Lat          an outcome is started without the write margin left (Concurrency 17).
\*   -outcome-buggy-sweep    WTakes = FALSE       the sweep closes a marker without the section (Reconciliation 20).
\*   -outcome-buggy-refused  HoldRefused = FALSE  the section is released over a step-3 refusal (Concurrency 25).
\*   -outcome-probe-recover  a reachability probe: the sweep, not the invocation, writes the one outcome.
\*
\* NOT MODELED: advisory mode; a hold release; two purges over one record and the sibling purges that
\* travel with a destruction; the intent, the gate record and the recovery intent, each one more
\* record_action under the same floor as the outcome; the audit arms; the lower edge and the two indexes;
\* a lease call that never answers (Concurrency 18, 19), which the Lease model's party reads as a grant
\* lost; the storage layer's own confirmation (Retention Window Record divergence 1), read here as one
\* landing; a host restart; the rate at which two clocks drift.
EXTENDS Naturals

CONSTANTS Dur, Pause, Lat, MaxTime, Margin, Floor, HTakes, STakes, GateInside, HoldInFlight, HoldRefused, WTakes, GateOn, OutOn

VARIABLES now, holder, exp, hold, sib, dest, bad, outs, wout,
          pp, psaw, plive, pchk, pin, pby, pdid, olive, ochk, oin, oby, odid, ofl,
          qp, qk, qlive, qchk, qin, qby,
          wp, wsee, win, wby
vars == <<now, holder, exp, hold, sib, dest, bad, outs, wout,
          pp, psaw, plive, pchk, pin, pby, pdid, olive, ochk, oin, oby, odid, ofl,
          qp, qk, qlive, qchk, qin, qby,
          wp, wsee, win, wby>>

TypeOK ==
    /\ now \in 0..MaxTime
    /\ holder \in {"none", "p", "q", "w"}
    /\ exp \in 0..(MaxTime + Dur)
    /\ hold \in BOOLEAN /\ sib \in BOOLEAN /\ dest \in BOOLEAN /\ bad \in BOOLEAN
    /\ outs \in 0..2 /\ wout \in BOOLEAN
    /\ pp \in {"idle", "pre", "held", "read", "done"}
    /\ psaw \in BOOLEAN /\ plive \in BOOLEAN /\ pin \in BOOLEAN /\ pdid \in BOOLEAN
    /\ olive \in BOOLEAN /\ oin \in BOOLEAN /\ odid \in BOOLEAN /\ ofl \in BOOLEAN
    /\ pchk \in 0..MaxTime /\ ochk \in 0..MaxTime
    /\ pby \in 0..(MaxTime + Pause) /\ oby \in 0..(MaxTime + Lat)
    /\ qp \in {"idle", "held", "done"} /\ qk \in {"hold", "sib"}
    /\ qlive \in BOOLEAN /\ qin \in BOOLEAN
    /\ qchk \in 0..MaxTime /\ qby \in 0..(MaxTime + Pause)
    /\ wp \in {"idle", "held", "read", "done"} /\ wsee \in BOOLEAN /\ win \in BOOLEAN
    /\ wby \in 0..(MaxTime + Lat)

Init ==
    /\ now = 0 /\ holder = "none" /\ exp = 0
    /\ hold = FALSE /\ sib = FALSE /\ dest = FALSE /\ bad = FALSE /\ outs = 0 /\ wout = FALSE
    /\ pp = "idle" /\ psaw = FALSE /\ plive = FALSE /\ pchk = 0 /\ pin = FALSE /\ pby = 0 /\ pdid = FALSE
    /\ olive = FALSE /\ ochk = 0 /\ oin = FALSE /\ oby = 0 /\ odid = FALSE /\ ofl = FALSE
    /\ qp = "idle" /\ qk \in {"hold", "sib"} /\ qlive = FALSE /\ qchk = 0 /\ qin = FALSE /\ qby = 0
    /\ wp = "idle" /\ wsee = FALSE /\ win = FALSE /\ wby = 0

\* Lease State 2: free is derived from a passed instant; the key is free at the reading that equals expires_at.
Free == holder = "none" \/ now >= exp

\* A call in flight lands, or fails, by its bound: the clock does not pass it (Lease Capability requirement 7).
Tick ==
    /\ now < MaxTime
    /\ ~(pin /\ now >= pby) /\ ~(oin /\ now >= oby)
    /\ ~(qin /\ now >= qby) /\ ~(win /\ now >= wby)
    /\ now' = now + 1
    /\ UNCHANGED <<holder, exp, hold, sib, dest, bad, outs, wout,
                   pp, psaw, plive, pchk, pin, pby, pdid, olive, ochk, oin, oby, odid, ofl,
                   qp, qk, qlive, qchk, qin, qby, wp, wsee, win, wby>>

\* ---- p: the purge -------------------------------------------------------------------------------
\* The twin reads the gate first and takes the section afterwards.
PPre ==
    /\ ~GateInside /\ pp = "idle"
    /\ psaw' = (hold \/ sib) /\ pp' = "pre"
    /\ UNCHANGED <<now, holder, exp, hold, sib, dest, bad, outs, wout,
                   plive, pchk, pin, pby, pdid, olive, ochk, oin, oby, odid, ofl,
                   qp, qk, qlive, qchk, qin, qby, wp, wsee, win, wby>>

PTake ==
    /\ ((GateInside /\ pp = "idle") \/ pp = "pre")
    /\ Free
    /\ holder' = "p" /\ exp' = now + Dur
    /\ pp' = IF pp = "pre" THEN "read" ELSE "held"
    /\ UNCHANGED <<now, hold, sib, dest, bad, outs, wout,
                   psaw, plive, pchk, pin, pby, pdid, olive, ochk, oin, oby, odid, ofl,
                   qp, qk, qlive, qchk, qin, qby, wp, wsee, win, wby>>

\* Concurrency 6, 7: the gate read and the sibling read under the section.
PRead ==
    /\ pp = "held"
    /\ psaw' = (hold \/ sib) /\ pp' = "read"
    /\ UNCHANGED <<now, holder, exp, hold, sib, dest, bad, outs, wout,
                   plive, pchk, pin, pby, pdid, olive, ochk, oin, oby, odid, ofl,
                   qp, qk, qlive, qchk, qin, qby, wp, wsee, win, wby>>

\* Concurrency 13, 14: one reading for the committing call, live only above the write margin.
PAsk ==
    /\ pp = "read" /\ ~psaw /\ ~pdid /\ ~pin /\ ~plive
    /\ holder = "p" /\ exp > now + Margin
    /\ plive' = TRUE /\ pchk' = now
    /\ UNCHANGED <<now, holder, exp, hold, sib, dest, bad, outs, wout,
                   pp, psaw, pin, pby, pdid, olive, ochk, oin, oby, odid, ofl,
                   qp, qk, qlive, qchk, qin, qby, wp, wsee, win, wby>>

\* Concurrency 15: the call follows its reading within one call pause.
PIssue ==
    /\ pp = "read" /\ plive /\ now <= pchk + Pause
    /\ pin' = TRUE /\ pby' = now + Pause /\ plive' = FALSE /\ pdid' = TRUE /\ pchk' = 0
    /\ UNCHANGED <<now, holder, exp, hold, sib, dest, bad, outs, wout,
                   pp, psaw, olive, ochk, oin, oby, odid, ofl,
                   qp, qk, qlive, qchk, qin, qby, wp, wsee, win, wby>>

PLand ==
    /\ pin /\ now <= pby
    /\ pin' = FALSE /\ pby' = 0 /\ dest' = TRUE /\ bad' = (bad \/ hold \/ sib)
    /\ UNCHANGED <<now, holder, exp, hold, sib, outs, wout,
                   pp, psaw, plive, pchk, pdid, olive, ochk, oin, oby, odid, ofl,
                   qp, qk, qlive, qchk, qin, qby, wp, wsee, win, wby>>

\* Atomic writes 8: a purge that fails leaves the retention retained.
PFail ==
    /\ pin
    /\ pin' = FALSE /\ pby' = 0
    /\ UNCHANGED <<now, holder, exp, hold, sib, dest, bad, outs, wout,
                   pp, psaw, plive, pchk, pdid, olive, ochk, oin, oby, odid, ofl,
                   qp, qk, qlive, qchk, qin, qby, wp, wsee, win, wby>>

\* Concurrency 16, 17: one reading for the outcome, admitted only above the record start floor.
OAsk ==
    /\ OutOn /\ pp = "read" /\ pdid /\ ~pin /\ dest /\ ~odid /\ ~olive
    /\ holder = "p" /\ exp > now + Floor
    /\ olive' = TRUE /\ ochk' = now
    /\ UNCHANGED <<now, holder, exp, hold, sib, dest, bad, outs, wout,
                   pp, psaw, plive, pchk, pin, pby, pdid, oin, oby, odid, ofl,
                   qp, qk, qlive, qchk, qin, qby, wp, wsee, win, wby>>

OIssue ==
    /\ pp = "read" /\ olive /\ now <= ochk + Pause
    /\ oin' = TRUE /\ oby' = now + Lat /\ olive' = FALSE /\ odid' = TRUE /\ ochk' = 0
    /\ UNCHANGED <<now, holder, exp, hold, sib, dest, bad, outs, wout,
                   pp, psaw, plive, pchk, pin, pby, pdid, ofl,
                   qp, qk, qlive, qchk, qin, qby, wp, wsee, win, wby>>

OLand ==
    /\ oin /\ now <= oby
    /\ oin' = FALSE /\ oby' = 0
    /\ outs' = IF outs < 2 THEN outs + 1 ELSE 2
    /\ UNCHANGED <<now, holder, exp, hold, sib, dest, bad, wout,
                   pp, psaw, plive, pchk, pin, pby, pdid, olive, ochk, odid, ofl,
                   qp, qk, qlive, qchk, qin, qby, wp, wsee, win, wby>>

\* A record_action that fails lands nothing, and the record stays owed (Audit arm 16, Audit arm 17).
OFail ==
    /\ oin
    /\ oin' = FALSE /\ oby' = 0
    /\ UNCHANGED <<now, holder, exp, hold, sib, dest, bad, outs, wout,
                   pp, psaw, plive, pchk, pin, pby, pdid, olive, ochk, odid, ofl,
                   qp, qk, qlive, qchk, qin, qby, wp, wsee, win, wby>>

\* The substrate answers recording-failure at step 3 and the append behind the answer stays in flight:
\* it may still land, or fail (Audit Trail record action step 3.7).
ORefuse ==
    /\ oin /\ ~ofl
    /\ ofl' = TRUE
    /\ UNCHANGED <<now, holder, exp, hold, sib, dest, bad, outs, wout,
                   pp, psaw, plive, pchk, pin, pby, pdid, olive, ochk, oin, oby, odid,
                   qp, qk, qlive, qchk, qin, qby, wp, wsee, win, wby>>

\* Concurrency 22, 23: no release with a call in flight, and nothing issued after it. Concurrency 25: no
\* release over a step-3 refusal, which the holder cannot tell from a call still in flight.
PRelease ==
    /\ pp \in {"held", "read"} /\ holder = "p"
    /\ (~HoldInFlight \/ (~pin /\ (~oin \/ ofl)))
    /\ (HoldRefused => ~ofl)
    /\ holder' = "none" /\ exp' = 0 /\ pp' = "done"
    /\ plive' = FALSE /\ olive' = FALSE /\ pchk' = 0 /\ ochk' = 0
    /\ UNCHANGED <<now, hold, sib, dest, bad, outs, wout,
                   psaw, pin, pby, pdid, oin, oby, odid, ofl,
                   qp, qk, qlive, qchk, qin, qby, wp, wsee, win, wby>>

\* ---- q: the placement, of a hold or of a sibling retention --------------------------------------
QTakes == IF qk = "hold" THEN HTakes ELSE STakes
QPlaced == IF qk = "hold" THEN hold ELSE sib

QTake ==
    /\ GateOn /\ QTakes /\ qp = "idle" /\ Free
    /\ holder' = "q" /\ exp' = now + Dur /\ qp' = "held"
    /\ UNCHANGED <<now, hold, sib, dest, bad, outs, wout,
                   pp, psaw, plive, pchk, pin, pby, pdid, olive, ochk, oin, oby, odid, ofl,
                   qk, qlive, qchk, qin, qby, wp, wsee, win, wby>>

QAsk ==
    /\ qp = "held" /\ ~qin /\ ~QPlaced /\ ~qlive
    /\ holder = "q" /\ exp > now + Margin
    /\ qlive' = TRUE /\ qchk' = now
    /\ UNCHANGED <<now, holder, exp, hold, sib, dest, bad, outs, wout,
                   pp, psaw, plive, pchk, pin, pby, pdid, olive, ochk, oin, oby, odid, ofl,
                   qp, qk, qin, qby, wp, wsee, win, wby>>

QIssue ==
    /\ \/ (qp = "held" /\ qlive /\ now <= qchk + Pause)
       \/ (GateOn /\ ~QTakes /\ qp = "idle" /\ ~qin /\ ~QPlaced)
    /\ qin' = TRUE /\ qby' = now + Pause /\ qlive' = FALSE /\ qchk' = 0
    /\ UNCHANGED <<now, holder, exp, hold, sib, dest, bad, outs, wout,
                   pp, psaw, plive, pchk, pin, pby, pdid, olive, ochk, oin, oby, odid, ofl,
                   qp, qk, wp, wsee, win, wby>>

QLand ==
    /\ qin /\ now <= qby
    /\ qin' = FALSE /\ qby' = 0
    /\ hold' = (hold \/ qk = "hold") /\ sib' = (sib \/ qk = "sib")
    /\ UNCHANGED <<now, holder, exp, dest, bad, outs, wout,
                   pp, psaw, plive, pchk, pin, pby, pdid, olive, ochk, oin, oby, odid, ofl,
                   qp, qk, qlive, qchk, wp, wsee, win, wby>>

QRelease ==
    /\ qp = "held" /\ holder = "q" /\ ~qin
    /\ holder' = "none" /\ exp' = 0 /\ qp' = "done" /\ qlive' = FALSE /\ qchk' = 0
    /\ UNCHANGED <<now, hold, sib, dest, bad, outs, wout,
                   pp, psaw, plive, pchk, pin, pby, pdid, olive, ochk, oin, oby, odid, ofl,
                   qk, qin, qby, wp, wsee, win, wby>>

\* ---- w: the sweep leg over the purge's open marker ----------------------------------------------
WTake ==
    /\ OutOn /\ WTakes /\ wp = "idle" /\ pdid /\ Free
    /\ holder' = "w" /\ exp' = now + Dur /\ wp' = "held"
    /\ UNCHANGED <<now, hold, sib, dest, bad, outs, wout,
                   pp, psaw, plive, pchk, pin, pby, pdid, olive, ochk, oin, oby, odid, ofl,
                   qp, qk, qlive, qchk, qin, qby, wsee, win, wby>>

\* Reconciliation 8, 21: the store says whether the act committed; the trail is read again under the section.
WRead ==
    /\ \/ wp = "held"
       \/ (OutOn /\ ~WTakes /\ wp = "idle" /\ pdid)
    /\ wsee' = (dest /\ outs = 0) /\ wp' = "read"
    /\ UNCHANGED <<now, holder, exp, hold, sib, dest, bad, outs, wout,
                   pp, psaw, plive, pchk, pin, pby, pdid, olive, ochk, oin, oby, odid, ofl,
                   qp, qk, qlive, qchk, qin, qby, win, wby>>

\* Reconciliation 11 under Concurrency 17: the recovery outcome is a record_action above the floor.
WIssue ==
    /\ wp = "read" /\ wsee /\ ~win
    /\ (~WTakes \/ (holder = "w" /\ exp > now + Floor))
    /\ win' = TRUE /\ wby' = now + Lat /\ wsee' = FALSE
    /\ UNCHANGED <<now, holder, exp, hold, sib, dest, bad, outs, wout,
                   pp, psaw, plive, pchk, pin, pby, pdid, olive, ochk, oin, oby, odid, ofl,
                   qp, qk, qlive, qchk, qin, qby, wp>>

WLand ==
    /\ win /\ now <= wby
    /\ win' = FALSE /\ wby' = 0 /\ wout' = TRUE
    /\ outs' = IF outs < 2 THEN outs + 1 ELSE 2
    /\ UNCHANGED <<now, holder, exp, hold, sib, dest, bad,
                   pp, psaw, plive, pchk, pin, pby, pdid, olive, ochk, oin, oby, odid, ofl,
                   qp, qk, qlive, qchk, qin, qby, wp, wsee>>

WRelease ==
    /\ wp \in {"held", "read"} /\ ~win
    /\ (WTakes => holder = "w")
    /\ holder' = IF WTakes THEN "none" ELSE holder
    /\ exp' = IF WTakes THEN 0 ELSE exp
    /\ wp' = "done" /\ wsee' = FALSE
    /\ UNCHANGED <<now, hold, sib, dest, bad, outs, wout,
                   pp, psaw, plive, pchk, pin, pby, pdid, olive, ochk, oin, oby, odid, ofl,
                   qp, qk, qlive, qchk, qin, qby, win, wby>>

Next ==
    \/ Tick
    \/ PPre \/ PTake \/ PRead \/ PAsk \/ PIssue \/ PLand \/ PFail \/ OAsk \/ OIssue \/ OLand \/ OFail \/ ORefuse \/ PRelease
    \/ QTake \/ QAsk \/ QIssue \/ QLand \/ QRelease
    \/ WTake \/ WRead \/ WIssue \/ WLand \/ WRelease

Spec == Init /\ [][Next]_vars

Inv_Gate == bad = FALSE
Inv_OneOutcome == outs <= 1

Probe_NeverAfter == ~(dest /\ hold /\ ~bad)
Probe_NeverRecover == ~(dest /\ outs = 1 /\ wout)
====
