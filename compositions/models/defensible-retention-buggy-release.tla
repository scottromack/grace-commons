---- MODULE defensible-retention-buggy-release ----
\* BUGGY TWIN: the record section is released with a call in flight (Concurrency 22 violated).
\* Grace Commons — Defensible Retention. Spec-level formal sibling of compositions/defensible-retention.md.
\* Derived validator; the English spec is the single source of truth. On any disagreement,
\* diagnose per the entry *The conflict protocol* in pressure-testing.md.
\*
\* ONE record, one record section (a Lease on the record reference) on one host clock, three parties:
\*   p  a [Purge Record] invocation under strict mode: takes the section, makes the gate read (the hold
\*      store and the sibling set), and on an empty gate issues Retention Window's purge on a live reading,
\*      within one call pause of asking; the purge commits with its intent and its outcome in one
\*      transaction (Execution Contract Database 1, Action wiring 80). After that commit it calls the
\*      record destruction pattern (Action wiring 112), and releases with no call in flight
\*      (Concurrency 5 through 24).
\*   q  a placement: a [Place Hold] invocation, or a [Place Record Under Retention] invocation placing a
\*      sibling retention still inside its window. It takes the section and issues its committing call
\*      the same way.
\*   r  the record destruction pattern's retry of a destruction a purge left standing: it takes the
\*      section (Capability requirement 67), reads Legal Hold under it, and retries only where no active
\*      hold covers the record (Capability requirement 68, Wiring decision 1).
\* Any party may stall at any moment for any length; a stalled party is a dead one to everyone else.
\*
\* WHAT THIS MODEL CHECKS
\*   Inv_Gate        no purge commits over a hold or a live sibling retention standing in the store
\*                   (Invariant 1.1, Invariant 9.1, Retention Window Simultaneous retention 4, 6).
\*   Inv_Withheld    no record is destroyed while an active hold covers it (Wiring decision 1,
\*                   Capability requirement 67, Capability requirement 68).
\*
\* THE TWINS, each this file with one constant changed:
\*   -buggy                  HTakes = FALSE       a hold is placed outside the record section (Concurrency 5).
\*   -buggy-sibling          STakes = FALSE       a retention is placed outside the record section (Concurrency 5).
\*   -buggy-gate             GateInside = FALSE   the gate is read before the section is taken (Concurrency 6, 7).
\*   -buggy-margin           Margin = Pause       a committing call is issued on one call pause of margin (Concurrency 14).
\*   -buggy-release          HoldInFlight = FALSE the section is released with a call in flight (Concurrency 22).
\*   -buggy-retry-ungated    RetryGated = FALSE   the record destruction pattern retries without reading the holds (Capability requirement 68).
\*   -probe-after            a reachability probe: a destruction lands and a hold lands after it.
\*   -probe-withheld         a reachability probe: a purge commits, its destruction fails, and a hold lands before any retry.
\*
\* NOT MODELED: advisory mode; a hold release, so the withheld record is never destroyed later; two
\* purges over one record and the sibling purges that travel with a destruction; the intent, the gate
\* record and the outcome, which commit with the purge (Database 1) and so are no step of their own; the
\* audit arms; the lower edge and the two indexes; the audit cascade (defensible-retention-audit-hold.tla);
\* a lease call that never answers (Concurrency 18, 19), which the Lease model's party reads as a grant
\* lost; the destruction call's own reading (it is issued on the write margin of the section without a
\* separate ask); a host restart; the rate at which two clocks drift.
EXTENDS Naturals

CONSTANTS Dur, Pause, MaxTime, Margin, HTakes, STakes, GateInside, HoldInFlight, RetryGated

VARIABLES now, holder, exp, hold, sib, purged, dest, bad, badd,
          pp, psaw, plive, pchk, pin, pby, pdid, din, dby, ddid,
          qp, qk, qlive, qchk, qin, qby,
          rp, rsaw, rin, rby
vars == <<now, holder, exp, hold, sib, purged, dest, bad, badd,
          pp, psaw, plive, pchk, pin, pby, pdid, din, dby, ddid,
          qp, qk, qlive, qchk, qin, qby,
          rp, rsaw, rin, rby>>

TypeOK ==
    /\ now \in 0..MaxTime
    /\ holder \in {"none", "p", "q", "r"}
    /\ exp \in 0..(MaxTime + Dur)
    /\ hold \in BOOLEAN /\ sib \in BOOLEAN /\ purged \in BOOLEAN /\ dest \in BOOLEAN
    /\ bad \in BOOLEAN /\ badd \in BOOLEAN
    /\ pp \in {"idle", "pre", "held", "read", "done"}
    /\ psaw \in BOOLEAN /\ plive \in BOOLEAN /\ pin \in BOOLEAN /\ pdid \in BOOLEAN
    /\ din \in BOOLEAN /\ ddid \in BOOLEAN
    /\ pchk \in 0..MaxTime
    /\ pby \in 0..(MaxTime + Pause) /\ dby \in 0..(MaxTime + Pause)
    /\ qp \in {"idle", "held", "done"} /\ qk \in {"hold", "sib"}
    /\ qlive \in BOOLEAN /\ qin \in BOOLEAN
    /\ qchk \in 0..MaxTime /\ qby \in 0..(MaxTime + Pause)
    /\ rp \in {"idle", "held", "read", "done"} /\ rsaw \in BOOLEAN /\ rin \in BOOLEAN
    /\ rby \in 0..(MaxTime + Pause)

Init ==
    /\ now = 0 /\ holder = "none" /\ exp = 0
    /\ hold = FALSE /\ sib = FALSE /\ purged = FALSE /\ dest = FALSE /\ bad = FALSE /\ badd = FALSE
    /\ pp = "idle" /\ psaw = FALSE /\ plive = FALSE /\ pchk = 0 /\ pin = FALSE /\ pby = 0 /\ pdid = FALSE
    /\ din = FALSE /\ dby = 0 /\ ddid = FALSE
    /\ qp = "idle" /\ qk \in {"hold", "sib"} /\ qlive = FALSE /\ qchk = 0 /\ qin = FALSE /\ qby = 0
    /\ rp = "idle" /\ rsaw = FALSE /\ rin = FALSE /\ rby = 0

\* Lease State 2: free is derived from a passed instant; the key is free at the reading that equals expires_at.
Free == holder = "none" \/ now >= exp

\* A call in flight lands, or fails, by its bound: the clock does not pass it (Lease Capability requirement 7).
Tick ==
    /\ now < MaxTime
    /\ ~(pin /\ now >= pby) /\ ~(din /\ now >= dby)
    /\ ~(qin /\ now >= qby) /\ ~(rin /\ now >= rby)
    /\ now' = now + 1
    /\ UNCHANGED <<holder, exp, hold, sib, purged, dest, bad, badd,
                   pp, psaw, plive, pchk, pin, pby, pdid, din, dby, ddid,
                   qp, qk, qlive, qchk, qin, qby, rp, rsaw, rin, rby>>

\* ---- p: the purge -------------------------------------------------------------------------------
\* The twin reads the gate first and takes the section afterwards.
PPre ==
    /\ ~GateInside /\ pp = "idle"
    /\ psaw' = (hold \/ sib) /\ pp' = "pre"
    /\ UNCHANGED <<now, holder, exp, hold, sib, purged, dest, bad, badd,
                   plive, pchk, pin, pby, pdid, din, dby, ddid,
                   qp, qk, qlive, qchk, qin, qby, rp, rsaw, rin, rby>>

PTake ==
    /\ ((GateInside /\ pp = "idle") \/ pp = "pre")
    /\ Free
    /\ holder' = "p" /\ exp' = now + Dur
    /\ pp' = IF pp = "pre" THEN "read" ELSE "held"
    /\ UNCHANGED <<now, hold, sib, purged, dest, bad, badd,
                   psaw, plive, pchk, pin, pby, pdid, din, dby, ddid,
                   qp, qk, qlive, qchk, qin, qby, rp, rsaw, rin, rby>>

\* Concurrency 6, 7: the gate read and the sibling read under the section.
PRead ==
    /\ pp = "held"
    /\ psaw' = (hold \/ sib) /\ pp' = "read"
    /\ UNCHANGED <<now, holder, exp, hold, sib, purged, dest, bad, badd,
                   plive, pchk, pin, pby, pdid, din, dby, ddid,
                   qp, qk, qlive, qchk, qin, qby, rp, rsaw, rin, rby>>

\* Concurrency 13, 14: one reading for the committing call, live only above the write margin.
PAsk ==
    /\ pp = "read" /\ ~psaw /\ ~pdid /\ ~pin /\ ~plive
    /\ holder = "p" /\ exp > now + Margin
    /\ plive' = TRUE /\ pchk' = now
    /\ UNCHANGED <<now, holder, exp, hold, sib, purged, dest, bad, badd,
                   pp, psaw, pin, pby, pdid, din, dby, ddid,
                   qp, qk, qlive, qchk, qin, qby, rp, rsaw, rin, rby>>

\* Concurrency 15: the call follows its reading within one call pause.
PIssue ==
    /\ pp = "read" /\ plive /\ now <= pchk + Pause
    /\ pin' = TRUE /\ pby' = now + Pause /\ plive' = FALSE /\ pdid' = TRUE /\ pchk' = 0
    /\ UNCHANGED <<now, holder, exp, hold, sib, purged, dest, bad, badd,
                   pp, psaw, din, dby, ddid,
                   qp, qk, qlive, qchk, qin, qby, rp, rsaw, rin, rby>>

\* The purge commits with its intent and its outcome (Database 1): it is a gate failure when a hold or a
\* sibling retention stands in the store at that commit.
PLand ==
    /\ pin /\ now <= pby
    /\ pin' = FALSE /\ pby' = 0 /\ purged' = TRUE /\ bad' = (bad \/ hold \/ sib)
    /\ UNCHANGED <<now, holder, exp, hold, sib, dest, badd,
                   pp, psaw, plive, pchk, pdid, din, dby, ddid,
                   qp, qk, qlive, qchk, qin, qby, rp, rsaw, rin, rby>>

\* Atomic writes 8: a purge that fails commits nothing and leaves the retention retained.
PFail ==
    /\ pin
    /\ pin' = FALSE /\ pby' = 0
    /\ UNCHANGED <<now, holder, exp, hold, sib, purged, dest, bad, badd,
                   pp, psaw, plive, pchk, pdid, din, dby, ddid,
                   qp, qk, qlive, qchk, qin, qby, rp, rsaw, rin, rby>>

\* Action wiring 112: the call to the record destruction pattern follows the purge's commit, under the section.
PDIssue ==
    /\ pp = "read" /\ purged /\ ~pin /\ ~din /\ ~ddid
    /\ holder = "p" /\ exp > now + Margin
    /\ din' = TRUE /\ dby' = now + Pause /\ ddid' = TRUE
    /\ UNCHANGED <<now, holder, exp, hold, sib, purged, dest, bad, badd,
                   pp, psaw, plive, pchk, pin, pby, pdid,
                   qp, qk, qlive, qchk, qin, qby, rp, rsaw, rin, rby>>

PDLand ==
    /\ din /\ now <= dby
    /\ din' = FALSE /\ dby' = 0 /\ dest' = TRUE /\ badd' = (badd \/ hold)
    /\ UNCHANGED <<now, holder, exp, hold, sib, purged, bad,
                   pp, psaw, plive, pchk, pin, pby, pdid, ddid,
                   qp, qk, qlive, qchk, qin, qby, rp, rsaw, rin, rby>>

\* A destruction that fails leaves the record standing, for the record destruction pattern to retry
\* (Retention Window Record divergence 4a through 6).
PDFail ==
    /\ din
    /\ din' = FALSE /\ dby' = 0
    /\ UNCHANGED <<now, holder, exp, hold, sib, purged, dest, bad, badd,
                   pp, psaw, plive, pchk, pin, pby, pdid, ddid,
                   qp, qk, qlive, qchk, qin, qby, rp, rsaw, rin, rby>>

\* Concurrency 22, 23: no release with a call in flight, and nothing issued after it.
PRelease ==
    /\ pp \in {"held", "read"} /\ holder = "p"
    /\ (~HoldInFlight \/ (~pin /\ ~din))
    /\ holder' = "none" /\ exp' = 0 /\ pp' = "done"
    /\ plive' = FALSE /\ pchk' = 0
    /\ UNCHANGED <<now, hold, sib, purged, dest, bad, badd,
                   psaw, pin, pby, pdid, din, dby, ddid,
                   qp, qk, qlive, qchk, qin, qby, rp, rsaw, rin, rby>>

\* ---- q: the placement, of a hold or of a sibling retention --------------------------------------
QTakes == IF qk = "hold" THEN HTakes ELSE STakes
QPlaced == IF qk = "hold" THEN hold ELSE sib

QTake ==
    /\ QTakes /\ qp = "idle" /\ Free
    /\ holder' = "q" /\ exp' = now + Dur /\ qp' = "held"
    /\ UNCHANGED <<now, hold, sib, purged, dest, bad, badd,
                   pp, psaw, plive, pchk, pin, pby, pdid, din, dby, ddid,
                   qk, qlive, qchk, qin, qby, rp, rsaw, rin, rby>>

QAsk ==
    /\ qp = "held" /\ ~qin /\ ~QPlaced /\ ~qlive
    /\ holder = "q" /\ exp > now + Margin
    /\ qlive' = TRUE /\ qchk' = now
    /\ UNCHANGED <<now, holder, exp, hold, sib, purged, dest, bad, badd,
                   pp, psaw, plive, pchk, pin, pby, pdid, din, dby, ddid,
                   qp, qk, qin, qby, rp, rsaw, rin, rby>>

QIssue ==
    /\ \/ (qp = "held" /\ qlive /\ now <= qchk + Pause)
       \/ (~QTakes /\ qp = "idle" /\ ~qin /\ ~QPlaced)
    /\ qin' = TRUE /\ qby' = now + Pause /\ qlive' = FALSE /\ qchk' = 0
    /\ UNCHANGED <<now, holder, exp, hold, sib, purged, dest, bad, badd,
                   pp, psaw, plive, pchk, pin, pby, pdid, din, dby, ddid,
                   qp, qk, rp, rsaw, rin, rby>>

QLand ==
    /\ qin /\ now <= qby
    /\ qin' = FALSE /\ qby' = 0
    /\ hold' = (hold \/ qk = "hold") /\ sib' = (sib \/ qk = "sib")
    /\ UNCHANGED <<now, holder, exp, purged, dest, bad, badd,
                   pp, psaw, plive, pchk, pin, pby, pdid, din, dby, ddid,
                   qp, qk, qlive, qchk, rp, rsaw, rin, rby>>

QRelease ==
    /\ qp = "held" /\ holder = "q" /\ ~qin
    /\ holder' = "none" /\ exp' = 0 /\ qp' = "done" /\ qlive' = FALSE /\ qchk' = 0
    /\ UNCHANGED <<now, hold, sib, purged, dest, bad, badd,
                   pp, psaw, plive, pchk, pin, pby, pdid, din, dby, ddid,
                   qk, qin, qby, rp, rsaw, rin, rby>>

\* ---- r: the record destruction pattern's retry of a record a purge left standing -----------------
\* Capability requirement 67: the retry takes the section first.
RTake ==
    /\ rp = "idle" /\ purged /\ ~dest /\ ~din /\ Free
    /\ holder' = "r" /\ exp' = now + Dur /\ rp' = "held"
    /\ UNCHANGED <<now, hold, sib, purged, dest, bad, badd,
                   pp, psaw, plive, pchk, pin, pby, pdid, din, dby, ddid,
                   qp, qk, qlive, qchk, qin, qby, rsaw, rin, rby>>

\* Capability requirement 68: a read of Legal Hold made under the section.
RRead ==
    /\ rp = "held"
    /\ rsaw' = hold /\ rp' = "read"
    /\ UNCHANGED <<now, holder, exp, hold, sib, purged, dest, bad, badd,
                   pp, psaw, plive, pchk, pin, pby, pdid, din, dby, ddid,
                   qp, qk, qlive, qchk, qin, qby, rin, rby>>

\* The retry is issued only on the section's write margin, and only where the read answered no hold.
RIssue ==
    /\ rp = "read" /\ ~rin /\ (RetryGated => ~rsaw)
    /\ holder = "r" /\ exp > now + Margin
    /\ rin' = TRUE /\ rby' = now + Pause
    /\ UNCHANGED <<now, holder, exp, hold, sib, purged, dest, bad, badd,
                   pp, psaw, plive, pchk, pin, pby, pdid, din, dby, ddid,
                   qp, qk, qlive, qchk, qin, qby, rp, rsaw>>

RLand ==
    /\ rin /\ now <= rby
    /\ rin' = FALSE /\ rby' = 0 /\ dest' = TRUE /\ badd' = (badd \/ hold)
    /\ UNCHANGED <<now, holder, exp, hold, sib, purged, bad,
                   pp, psaw, plive, pchk, pin, pby, pdid, din, dby, ddid,
                   qp, qk, qlive, qchk, qin, qby, rp, rsaw>>

RFail ==
    /\ rin
    /\ rin' = FALSE /\ rby' = 0
    /\ UNCHANGED <<now, holder, exp, hold, sib, purged, dest, bad, badd,
                   pp, psaw, plive, pchk, pin, pby, pdid, din, dby, ddid,
                   qp, qk, qlive, qchk, qin, qby, rp, rsaw>>

RRelease ==
    /\ rp \in {"held", "read"} /\ holder = "r" /\ (~HoldInFlight \/ ~rin)
    /\ holder' = "none" /\ exp' = 0 /\ rp' = "done"
    /\ UNCHANGED <<now, hold, sib, purged, dest, bad, badd,
                   pp, psaw, plive, pchk, pin, pby, pdid, din, dby, ddid,
                   qp, qk, qlive, qchk, qin, qby, rsaw, rin, rby>>

Next ==
    \/ Tick
    \/ PPre \/ PTake \/ PRead \/ PAsk \/ PIssue \/ PLand \/ PFail \/ PDIssue \/ PDLand \/ PDFail \/ PRelease
    \/ QTake \/ QAsk \/ QIssue \/ QLand \/ QRelease
    \/ RTake \/ RRead \/ RIssue \/ RLand \/ RFail \/ RRelease

Spec == Init /\ [][Next]_vars

Inv_Gate == bad = FALSE
Inv_Withheld == badd = FALSE

Probe_NeverAfter == ~(dest /\ hold /\ ~bad)
Probe_NeverWithheld == ~(purged /\ ~dest /\ hold)
====
