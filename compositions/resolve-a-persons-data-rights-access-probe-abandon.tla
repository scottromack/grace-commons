---- MODULE resolve-a-persons-data-rights-access-probe-abandon ----
\* EXPECT: violation — reachability probe: a leg abandons an intent with nothing planned and no disclosure, never.
\* Grace Commons — Resolve a Person's Data Rights. Spec-level formal sibling of
\* compositions/resolve-a-persons-data-rights.md. Derived validator; the English spec is the single
\* source of truth. On any disagreement, diagnose per the entry *The conflict protocol* in pressure-testing.md.
\*
\* Three files carry this one module body. resolve-a-persons-data-rights.tla runs one erasure against two
\* legs of the reconciliation. resolve-a-persons-data-rights-access.tla runs a fulfillment with nothing
\* planned — an access, or an erasure with empty plans — against the same two legs.
\* resolve-a-persons-data-rights-admission.tla runs two fulfillments of one request against each other.
\* The party a file leaves off takes no step.
\*
\* ONE request, one request section (a Lease on the request id) on one host clock, and a universe of two
\* records: S, settled before any planned call, and, where the fulfillment plans, R, planned for
\* Defensible Retention's purge. The parties:
\*   f, g  a fulfillment: takes the section, reads the request's state under it, and where the request is
\*         Received writes its intent, makes the planned call, writes the response disclosure and writes
\*         the fulfilled event — each call started only while the grant has the call's bound left, each
\*         landing or failing by that bound (Concurrency 3 through 22). A call may also answer and stay in
\*         flight: a step-3 refusal, or no answer. The write behind it may still land, or never. A purge
\*         may answer storage-failure over a record the storage layer already destroyed, and is then
\*         called once more.
\*   w, v  a leg: takes the section, reads the request's events, the disclosure store and the plan's
\*         store under it, and closes the open intent — compensate where a disclosure exists, complete
\*         where a destruction was planned, abandon where nothing was (Reconciliation 9 through 17, 23
\*         through 30).
\* Any party may stall at any moment for any length; a stalled party is a dead one to everyone else.
\*
\* WHAT THIS MODEL CHECKS
\*   Inv_OneSeal        a request carries at most one fulfilled event (Invariant 1.2).
\*   Inv_NoOrphanEvent  no fulfilled event without its response disclosure (Invariant 1.1).
\*   Inv_OneDisclosure  a request carries at most one response disclosure (Invariant 5.1).
\*   Inv_OneClose       an intent is closed at most once (Invariant 1.5, the safety half).
\*   Inv_OneOpen        a request carries at most one open intent (Reconciliation 8).
\*   Inv_OrphanOpen     a disclosure with no fulfilled event has an open intent behind it (Invariant 1.4).
\*   Inv_Accounted      a destruction a fulfillment made, whether or not the store shows it, stands under
\*                      an open intent or a sealed set, never under an abandoned one (Action wiring 19,
\*                      Reconciliation 13 and 15).
\*   Inv_Evidence       erased is sealed only where the store shows the record destroyed (Invariant 3.1).
\*   Inv_Truth          a record destroyed is never sealed retained (Disposition 42).
\*   Inv_Cover          every sealed set carries the settled record (Invariant 2.1, Reconciliation 16).
\*
\* THE TWINS, each this file with one constant changed:
\*   -buggy                  LegTakes = FALSE          a leg closes an intent without the request section (Reconciliation 17).
\*   -buggy-coverage         FromIntent = FALSE        a compensation built from the plan alone (Reconciliation 16).
\*   -buggy-retry            Retry = TRUE              the fulfilled event issued a second time (Audit arm 21).
\*   -buggy-release          HoldRefused = FALSE       the section released over a call that may still land (Concurrency 19, 20).
\*   -buggy-abandon          AbandonUnanswered = TRUE  an abandonment over a disclosure write that did not answer (Action wiring 39).
\*   -buggy-grant            Reads = FALSE             a call issued without a reading of the grant (Concurrency 9, 12, 13).
\*   -buggy-unsettled        Unsettled = FALSE         a planned call that did not settle its record read as a refusal (Disposition 42).
\*   -buggy-plan             AbandonPlanned = TRUE     a leg abandons a planned destruction no store shows (Reconciliation 13, 15).
\*   -buggy-taint            Taint = FALSE             a storage-failure followed by a refusal sealed retained (Term purge reading).
\*   -probe-recover          a reachability probe: a leg, not the invocation, writes the one fulfilled event.
\*   -probe-complete         a reachability probe: a leg writes the response disclosure and then the event.
\*   -probe-late             a reachability probe: a fulfilled event lands after its own write answered a refusal.
\*   -access-probe-abandon   a reachability probe: a leg abandons an intent with nothing planned.
\*   -admission-buggy-order  StateInside = FALSE       the request's state read before the section is taken (Concurrency 7).
\*   -admission-probe-again  a reachability probe: a second fulfillment seals a request the first abandoned.
\*
\* NOT MODELED: the intake; more than one planned record, the host delete, a re-invocation of a purge
\* beyond the one after a storage-failure, and a purge's own refusals beyond one that applies nothing and
\* one storage-failure — Defensible Retention's models carry the gate; the recovery intent, one more audit write under the same floor; the
\* reconciliation's two edges and the audit horizon, which keep a leg off young and aged work and which no
\* invariant here rests on; the pause between a reading of the grant and the call the reading admits, and a
\* lease call that never answers, both carried by the Lease model; the state read's failure; the two
\* indexes; the sizing of the largest record; a host restart; the rate at which two clocks drift.
EXTENDS Naturals

CONSTANTS Dur, Pause, Lat, PLat, MaxTime, FOn, GOn, WOn, VOn,
          LegTakes, StateInside, HoldRefused, Retry, AbandonUnanswered, Reads, Unsettled, FromIntent, HasPlan, AbandonPlanned, Taint

VARIABLES now, holder, exp, intF, intG, clF, clG, disc, seals, dest,
          sealedR, badCover, rec, legdisc, late, gone, legab, fp, fin, fby,
          fl, flby, fr, fd, gp, gin, gby, gl, glby, gr,
          gd, wp, wo, wc, win, wby, wl, wlby, wdest, vp,
          vo, vc, vin, vby, vl, vlby, vdest
vars == <<now, holder, exp, intF, intG, clF, clG, disc, seals, dest,
          sealedR, badCover, rec, legdisc, late, gone, legab, fp, fin, fby,
          fl, flby, fr, fd, gp, gin, gby, gl, glby, gr,
          gd, wp, wo, wc, win, wby, wl, wlby, wdest, vp,
          vo, vc, vin, vby, vl, vlby, vdest>>

TypeOK ==
    /\ now \in 0..MaxTime /\ holder \in {"none", "f", "g", "w", "v"} /\ exp \in 0..(MaxTime + Dur)
    /\ intF \in {"none", "open", "sealed", "aband"} /\ intG \in {"none", "open", "sealed", "aband"}
    /\ clF \in 0..2 /\ clG \in 0..2 /\ disc \in 0..2 /\ seals \in 0..2
    /\ dest \in BOOLEAN /\ sealedR \in {"planned", "none", "erased", "retained", "unsettled"}
    /\ badCover \in BOOLEAN /\ rec \in BOOLEAN /\ legdisc \in BOOLEAN /\ late \in BOOLEAN
    /\ gone \in BOOLEAN /\ legab \in BOOLEAN
    /\ fp \in {"idle", "pre", "held", "adm", "intd", "retry", "exec", "discd", "discr", "hold", "rel", "done"}
    /\ fin \in {"none", "intent", "purge", "disc", "seal", "aband"} /\ fl \in {"none", "intent", "purge", "disc", "seal", "aband"}
    /\ fby \in 0..(MaxTime + Lat + PLat) /\ flby \in 0..(MaxTime + Lat + PLat)
    /\ fr \in {"planned", "none", "tainted", "erased", "retained", "unsettled"} /\ fd \in {"none", "ok", "ref", "una"}
    /\ gp \in {"idle", "pre", "held", "adm", "intd", "retry", "exec", "discd", "discr", "hold", "rel", "done"}
    /\ gin \in {"none", "intent", "purge", "disc", "seal", "aband"} /\ gl \in {"none", "intent", "purge", "disc", "seal", "aband"}
    /\ gby \in 0..(MaxTime + Lat + PLat) /\ glby \in 0..(MaxTime + Lat + PLat)
    /\ gr \in {"planned", "none", "tainted", "erased", "retained", "unsettled"} /\ gd \in {"none", "ok", "ref", "una"}
    /\ wp \in {"idle", "held", "read", "hold", "fin", "done"} /\ wo \in {"none", "f", "g"}
    /\ wc \in {"none", "comp", "complete", "aband"}
    /\ win \in {"none", "disc", "seal", "aband"} /\ wl \in {"none", "disc", "seal", "aband"}
    /\ wby \in 0..(MaxTime + Lat) /\ wlby \in 0..(MaxTime + Lat) /\ wdest \in BOOLEAN
    /\ vp \in {"idle", "held", "read", "hold", "fin", "done"} /\ vo \in {"none", "f", "g"}
    /\ vc \in {"none", "comp", "complete", "aband"}
    /\ vin \in {"none", "disc", "seal", "aband"} /\ vl \in {"none", "disc", "seal", "aband"}
    /\ vby \in 0..(MaxTime + Lat) /\ vlby \in 0..(MaxTime + Lat) /\ vdest \in BOOLEAN

Init ==
    /\ now = 0 /\ holder = "none" /\ exp = 0
    /\ intF = "none" /\ intG = "none" /\ clF = 0 /\ clG = 0 /\ disc = 0 /\ seals = 0
    /\ dest = FALSE /\ sealedR = "planned" /\ badCover = FALSE /\ rec = FALSE /\ legdisc = FALSE /\ late = FALSE /\ gone = FALSE /\ legab = FALSE
    /\ fp = "idle" /\ fin = "none" /\ fby = 0 /\ fl = "none" /\ flby = 0 /\ fr = "planned" /\ fd = "none"
    /\ gp = "idle" /\ gin = "none" /\ gby = 0 /\ gl = "none" /\ glby = 0 /\ gr = "planned" /\ gd = "none"
    /\ wp = "idle" /\ wo = "none" /\ wc = "none" /\ win = "none" /\ wby = 0 /\ wl = "none" /\ wlby = 0 /\ wdest = FALSE
    /\ vp = "idle" /\ vo = "none" /\ vc = "none" /\ vin = "none" /\ vby = 0 /\ vl = "none" /\ vlby = 0 /\ vdest = FALSE

Inc(n) == IF n < 2 THEN n + 1 ELSE 2

\* Lease State 2: free is derived from a passed instant; the key is free at the reading that equals expires_at.
Free == holder = "none" \/ now >= exp

AnyOpen == intF = "open" \/ intG = "open"

\* Composition state 17, 19 and 24: Received is no fulfilled event, no open intent and no unbound disclosure.
AdmitOK == seals = 0 /\ ~AnyOpen /\ disc = 0

\* A call in flight lands, or fails, by its bound: the clock does not pass it (Lease Capability requirement 7).
Tick ==
    /\ now < MaxTime
    /\ ~(fin # "none" /\ now >= fby) /\ ~(fl # "none" /\ now >= flby)
    /\ ~(gin # "none" /\ now >= gby) /\ ~(gl # "none" /\ now >= glby)
    /\ ~(win # "none" /\ now >= wby) /\ ~(wl # "none" /\ now >= wlby)
    /\ ~(vin # "none" /\ now >= vby) /\ ~(vl # "none" /\ now >= vlby)
    /\ now' = (now + 1)
    /\ UNCHANGED <<holder, exp, intF, intG, clF, clG, disc, seals, dest,
                   sealedR, badCover, rec, legdisc, late, gone, legab, fp, fin,
                   fby, fl, flby, fr, fd, gp, gin, gby, gl,
                   glby, gr, gd, wp, wo, wc, win, wby, wl,
                   wlby, wdest, vp, vo, vc, vin, vby, vl, vlby,
                   vdest>>

\* The twin reads the request's state first and takes the section afterwards.
FPre ==
    /\ FOn /\ ~StateInside /\ fp = "idle"
    /\ fp' = (IF AdmitOK THEN "pre" ELSE "done")
    /\ UNCHANGED <<now, holder, exp, intF, intG, clF, clG, disc, seals,
                   dest, sealedR, badCover, rec, legdisc, late, gone, legab, fin,
                   fby, fl, flby, fr, fd, gp, gin, gby, gl,
                   glby, gr, gd, wp, wo, wc, win, wby, wl,
                   wlby, wdest, vp, vo, vc, vin, vby, vl, vlby,
                   vdest>>

\* Concurrency 3: the request section, by try_take for the section term.
FTake ==
    /\ FOn /\ ((StateInside /\ fp = "idle") \/ fp = "pre")
    /\ Free
    /\ holder' = "f"
    /\ exp' = (now + Dur)
    /\ fp' = (IF fp = "pre" THEN "adm" ELSE "held")
    /\ UNCHANGED <<now, intF, intG, clF, clG, disc, seals, dest, sealedR,
                   badCover, rec, legdisc, late, gone, legab, fin, fby, fl,
                   flby, fr, fd, gp, gin, gby, gl, glby, gr,
                   gd, wp, wo, wc, win, wby, wl, wlby, wdest,
                   vp, vo, vc, vin, vby, vl, vlby, vdest>>

\* Concurrency 7, Action wiring 5 and 6: the request's state read under the section.
FRead ==
    /\ fp = "held"
    /\ fp' = (IF AdmitOK THEN "adm" ELSE "rel")
    /\ UNCHANGED <<now, holder, exp, intF, intG, clF, clG, disc, seals,
                   dest, sealedR, badCover, rec, legdisc, late, gone, legab, fin,
                   fby, fl, flby, fr, fd, gp, gin, gby, gl,
                   glby, gr, gd, wp, wo, wc, win, wby, wl,
                   wlby, wdest, vp, vo, vc, vin, vby, vl, vlby,
                   vdest>>

\* Concurrency 12: an audit write starts only while the grant has its latency left.
FIntent ==
    /\ fp = "adm" /\ fin = "none" /\ fl = "none"
    /\ (~Reads \/ (holder = "f" /\ exp > now + Lat))
    /\ fin' = "intent"
    /\ fby' = (now + Lat)
    /\ UNCHANGED <<now, holder, exp, intF, intG, clF, clG, disc, seals,
                   dest, sealedR, badCover, rec, legdisc, late, gone, legab, fp,
                   fl, flby, fr, fd, gp, gin, gby, gl, glby,
                   gr, gd, wp, wo, wc, win, wby, wl, wlby,
                   wdest, vp, vo, vc, vin, vby, vl, vlby, vdest>>

\* Concurrency 13: a planned call starts only above the plan floor, the bind still fitting after it.
FPurge ==
    /\ HasPlan /\ fp \in {"intd", "retry"} /\ fin = "none"
    /\ (~Reads \/ (holder = "f" /\ exp > now + PLat + Pause + Lat))
    /\ fin' = "purge"
    /\ fby' = (now + PLat)
    /\ UNCHANGED <<now, holder, exp, intF, intG, clF, clG, disc, seals,
                   dest, sealedR, badCover, rec, legdisc, late, gone, legab, fp,
                   fl, flby, fr, fd, gp, gin, gby, gl, glby,
                   gr, gd, wp, wo, wc, win, wby, wl, wlby,
                   wdest, vp, vo, vc, vin, vby, vl, vlby, vdest>>

\* The access path, and an erasure whose plans stand empty: no planned call.
FNoPlan ==
    /\ ~HasPlan /\ fp = "intd" /\ fin = "none"
    /\ fr' = "none"
    /\ fp' = "exec"
    /\ UNCHANGED <<now, holder, exp, intF, intG, clF, clG, disc, seals,
                   dest, sealedR, badCover, rec, legdisc, late, gone, legab, fin,
                   fby, fl, flby, fd, gp, gin, gby, gl, glby,
                   gr, gd, wp, wo, wc, win, wby, wl, wlby,
                   wdest, vp, vo, vc, vin, vby, vl, vlby, vdest>>

\* Disposition 45: a planned record the grant admits no call for is unsettled.
FSkip ==
    /\ HasPlan /\ fp \in {"intd", "retry"} /\ fin = "none"
    /\ ~(holder = "f" /\ exp > now + PLat + Pause + Lat)
    /\ fr' = "unsettled"
    /\ fp' = "exec"
    /\ UNCHANGED <<now, holder, exp, intF, intG, clF, clG, disc, seals,
                   dest, sealedR, badCover, rec, legdisc, late, gone, legab, fin,
                   fby, fl, flby, fd, gp, gin, gby, gl, glby,
                   gr, gd, wp, wo, wc, win, wby, wl, wlby,
                   wdest, vp, vo, vc, vin, vby, vl, vlby, vdest>>

\* Concurrency 9: the disclosure write on a live reading.
FDisc ==
    /\ fp = "exec" /\ fin = "none"
    /\ (~Reads \/ (holder = "f" /\ exp > now + Pause))
    /\ fin' = "disc"
    /\ fby' = (now + Pause)
    /\ UNCHANGED <<now, holder, exp, intF, intG, clF, clG, disc, seals,
                   dest, sealedR, badCover, rec, legdisc, late, gone, legab, fp,
                   fl, flby, fr, fd, gp, gin, gby, gl, glby,
                   gr, gd, wp, wo, wc, win, wby, wl, wlby,
                   wdest, vp, vo, vc, vin, vby, vl, vlby, vdest>>

FSeal ==
    /\ fp = "discd" /\ fin = "none"
    /\ (~Reads \/ (holder = "f" /\ exp > now + Lat))
    /\ fin' = "seal"
    /\ fby' = (now + Lat)
    /\ UNCHANGED <<now, holder, exp, intF, intG, clF, clG, disc, seals,
                   dest, sealedR, badCover, rec, legdisc, late, gone, legab, fp,
                   fl, flby, fr, fd, gp, gin, gby, gl, glby,
                   gr, gd, wp, wo, wc, win, wby, wl, wlby,
                   wdest, vp, vo, vc, vin, vby, vl, vlby, vdest>>

\* Action wiring 19 and 39: an abandonment over a refused disclosure write with nothing possibly destroyed, never over one that did not answer.
FAband ==
    /\ fp = "discr" /\ fin = "none"
    /\ ((fd = "ref" \/ (AbandonUnanswered /\ fd = "una")) /\ fr \notin {"erased", "unsettled"})
    /\ (~Reads \/ (holder = "f" /\ exp > now + Lat))
    /\ fin' = "aband"
    /\ fby' = (now + Lat)
    /\ UNCHANGED <<now, holder, exp, intF, intG, clF, clG, disc, seals,
                   dest, sealedR, badCover, rec, legdisc, late, gone, legab, fp,
                   fl, flby, fr, fd, gp, gin, gby, gl, glby,
                   gr, gd, wp, wo, wc, win, wby, wl, wlby,
                   wdest, vp, vo, vc, vin, vby, vl, vlby, vdest>>

\* Action wiring 29: the fulfillment answers outcome and leaves the intent open.
FGiveUp ==
    /\ fp = "discr" /\ fin = "none"
    /\ ~((fd = "ref" \/ (AbandonUnanswered /\ fd = "una")) /\ fr \notin {"erased", "unsettled"})
    /\ fp' = (IF fd = "una" THEN "hold" ELSE "rel")
    /\ UNCHANGED <<now, holder, exp, intF, intG, clF, clG, disc, seals,
                   dest, sealedR, badCover, rec, legdisc, late, gone, legab, fin,
                   fby, fl, flby, fr, fd, gp, gin, gby, gl,
                   glby, gr, gd, wp, wo, wc, win, wby, wl,
                   wlby, wdest, vp, vo, vc, vin, vby, vl, vlby,
                   vdest>>

FLandIntent ==
    /\ fin = "intent" /\ now <= fby
    /\ fin' = "none"
    /\ fby' = 0
    /\ intF' = "open"
    /\ fp' = "intd"
    /\ UNCHANGED <<now, holder, exp, intG, clF, clG, disc, seals, dest,
                   sealedR, badCover, rec, legdisc, late, gone, legab, fl, flby,
                   fr, fd, gp, gin, gby, gl, glby, gr, gd,
                   wp, wo, wc, win, wby, wl, wlby, wdest, vp,
                   vo, vc, vin, vby, vl, vlby, vdest>>

FLandPurge ==
    /\ fin = "purge" /\ now <= fby
    /\ fin' = "none"
    /\ fby' = 0
    /\ dest' = TRUE
    /\ fr' = "erased"
    /\ fp' = "exec"
    /\ UNCHANGED <<now, holder, exp, intF, intG, clF, clG, disc, seals,
                   sealedR, badCover, rec, legdisc, late, gone, legab, fl, flby,
                   fd, gp, gin, gby, gl, glby, gr, gd, wp,
                   wo, wc, win, wby, wl, wlby, wdest, vp, vo,
                   vc, vin, vby, vl, vlby, vdest>>

FLandDisc ==
    /\ fin = "disc" /\ now <= fby
    /\ fin' = "none"
    /\ fby' = 0
    /\ disc' = Inc(disc)
    /\ fd' = "ok"
    /\ fp' = "discd"
    /\ UNCHANGED <<now, holder, exp, intF, intG, clF, clG, seals, dest,
                   sealedR, badCover, rec, legdisc, late, gone, legab, fl, flby,
                   fr, gp, gin, gby, gl, glby, gr, gd, wp,
                   wo, wc, win, wby, wl, wlby, wdest, vp, vo,
                   vc, vin, vby, vl, vlby, vdest>>

FLandSeal ==
    /\ fin = "seal" /\ now <= fby
    /\ fin' = "none"
    /\ fby' = 0
    /\ seals' = Inc(seals)
    /\ clF' = Inc(clF)
    /\ intF' = (IF intF = "open" THEN "sealed" ELSE intF)
    /\ sealedR' = (IF seals = 0 THEN fr ELSE sealedR)
    /\ fp' = "rel"
    /\ UNCHANGED <<now, holder, exp, intG, clG, disc, dest, badCover, rec,
                   legdisc, late, gone, legab, fl, flby, fr, fd, gp,
                   gin, gby, gl, glby, gr, gd, wp, wo, wc,
                   win, wby, wl, wlby, wdest, vp, vo, vc, vin,
                   vby, vl, vlby, vdest>>

FLandAband ==
    /\ fin = "aband" /\ now <= fby
    /\ fin' = "none"
    /\ fby' = 0
    /\ clF' = Inc(clF)
    /\ intF' = (IF intF = "open" THEN "aband" ELSE intF)
    /\ fp' = "rel"
    /\ UNCHANGED <<now, holder, exp, intG, clG, disc, seals, dest, sealedR,
                   badCover, rec, legdisc, late, gone, legab, fl, flby, fr,
                   fd, gp, gin, gby, gl, glby, gr, gd, wp,
                   wo, wc, win, wby, wl, wlby, wdest, vp, vo,
                   vc, vin, vby, vl, vlby, vdest>>

\* A refusal that applied nothing: the record is owed, or the gate refused, or the store refused.
FFailIntent ==
    /\ fin = "intent"
    /\ fin' = "none"
    /\ fby' = 0
    /\ fp' = "rel"
    /\ UNCHANGED <<now, holder, exp, intF, intG, clF, clG, disc, seals,
                   dest, sealedR, badCover, rec, legdisc, late, gone, legab, fl,
                   flby, fr, fd, gp, gin, gby, gl, glby, gr,
                   gd, wp, wo, wc, win, wby, wl, wlby, wdest,
                   vp, vo, vc, vin, vby, vl, vlby, vdest>>

\* Term purge reading: a pair that answered storage-failure is unsettled whatever the gate then refuses.
FFailPurge ==
    /\ fin = "purge"
    /\ fin' = "none"
    /\ fby' = 0
    /\ fr' = (IF fr = "tainted" /\ Taint THEN "unsettled" ELSE "retained")
    /\ fp' = "exec"
    /\ UNCHANGED <<now, holder, exp, intF, intG, clF, clG, disc, seals,
                   dest, sealedR, badCover, rec, legdisc, late, gone, legab, fl,
                   flby, fd, gp, gin, gby, gl, glby, gr, gd,
                   wp, wo, wc, win, wby, wl, wlby, wdest, vp,
                   vo, vc, vin, vby, vl, vlby, vdest>>

\* Defensible Retention Atomic writes 8 and 9: a purge that answers storage-failure leaves the retention retained, and the record may be gone all the same.
FStorPurge ==
    /\ fin = "purge"
    /\ fin' = "none"
    /\ fby' = 0
    /\ fr' = (IF ~Unsettled THEN "retained" ELSE IF fr = "tainted" THEN "unsettled" ELSE "tainted")
    /\ fp' = (IF Unsettled /\ fr # "tainted" THEN "retry" ELSE "exec")
    /\ UNCHANGED <<now, holder, exp, intF, intG, clF, clG, disc, seals,
                   dest, sealedR, badCover, rec, legdisc, late, gone, legab, fl,
                   flby, fd, gp, gin, gby, gl, glby, gr, gd,
                   wp, wo, wc, win, wby, wl, wlby, wdest, vp,
                   vo, vc, vin, vby, vl, vlby, vdest>>

FStorPurgeGone ==
    /\ fin = "purge"
    /\ fin' = "none"
    /\ fby' = 0
    /\ fr' = (IF ~Unsettled THEN "retained" ELSE IF fr = "tainted" THEN "unsettled" ELSE "tainted")
    /\ fp' = (IF Unsettled /\ fr # "tainted" THEN "retry" ELSE "exec")
    /\ gone' = TRUE
    /\ UNCHANGED <<now, holder, exp, intF, intG, clF, clG, disc, seals,
                   dest, sealedR, badCover, rec, legdisc, late, legab, fl, flby,
                   fd, gp, gin, gby, gl, glby, gr, gd, wp,
                   wo, wc, win, wby, wl, wlby, wdest, vp, vo,
                   vc, vin, vby, vl, vlby, vdest>>

FFailDisc ==
    /\ fin = "disc"
    /\ fin' = "none"
    /\ fby' = 0
    /\ fd' = "ref"
    /\ fp' = "discr"
    /\ UNCHANGED <<now, holder, exp, intF, intG, clF, clG, disc, seals,
                   dest, sealedR, badCover, rec, legdisc, late, gone, legab, fl,
                   flby, fr, gp, gin, gby, gl, glby, gr, gd,
                   wp, wo, wc, win, wby, wl, wlby, wdest, vp,
                   vo, vc, vin, vby, vl, vlby, vdest>>

FFailSeal ==
    /\ fin = "seal"
    /\ fin' = "none"
    /\ fby' = 0
    /\ fp' = "rel"
    /\ UNCHANGED <<now, holder, exp, intF, intG, clF, clG, disc, seals,
                   dest, sealedR, badCover, rec, legdisc, late, gone, legab, fl,
                   flby, fr, fd, gp, gin, gby, gl, glby, gr,
                   gd, wp, wo, wc, win, wby, wl, wlby, wdest,
                   vp, vo, vc, vin, vby, vl, vlby, vdest>>

FFailAband ==
    /\ fin = "aband"
    /\ fin' = "none"
    /\ fby' = 0
    /\ fp' = "rel"
    /\ UNCHANGED <<now, holder, exp, intF, intG, clF, clG, disc, seals,
                   dest, sealedR, badCover, rec, legdisc, late, gone, legab, fl,
                   flby, fr, fd, gp, gin, gby, gl, glby, gr,
                   gd, wp, wo, wc, win, wby, wl, wlby, wdest,
                   vp, vo, vc, vin, vby, vl, vlby, vdest>>

\* The call answered a step-3 refusal, or never answered, and the write behind it stays in flight: it may still land, or not (Audit Trail record action step 3.7).
FRefuseIntent ==
    /\ fin = "intent" /\ fl = "none"
    /\ fl' = fin
    /\ flby' = fby
    /\ fin' = "none"
    /\ fby' = 0
    /\ fp' = "hold"
    /\ UNCHANGED <<now, holder, exp, intF, intG, clF, clG, disc, seals,
                   dest, sealedR, badCover, rec, legdisc, late, gone, legab, fr,
                   fd, gp, gin, gby, gl, glby, gr, gd, wp,
                   wo, wc, win, wby, wl, wlby, wdest, vp, vo,
                   vc, vin, vby, vl, vlby, vdest>>

FRefusePurge ==
    /\ fin = "purge" /\ fl = "none"
    /\ fl' = fin
    /\ flby' = fby
    /\ fin' = "none"
    /\ fby' = 0
    /\ fr' = (IF Unsettled THEN "unsettled" ELSE "retained")
    /\ fp' = "exec"
    /\ UNCHANGED <<now, holder, exp, intF, intG, clF, clG, disc, seals,
                   dest, sealedR, badCover, rec, legdisc, late, gone, legab, fd,
                   gp, gin, gby, gl, glby, gr, gd, wp, wo,
                   wc, win, wby, wl, wlby, wdest, vp, vo, vc,
                   vin, vby, vl, vlby, vdest>>

FRefuseDisc ==
    /\ fin = "disc" /\ fl = "none"
    /\ fl' = fin
    /\ flby' = fby
    /\ fin' = "none"
    /\ fby' = 0
    /\ fd' = "una"
    /\ fp' = "discr"
    /\ UNCHANGED <<now, holder, exp, intF, intG, clF, clG, disc, seals,
                   dest, sealedR, badCover, rec, legdisc, late, gone, legab, fr,
                   gp, gin, gby, gl, glby, gr, gd, wp, wo,
                   wc, win, wby, wl, wlby, wdest, vp, vo, vc,
                   vin, vby, vl, vlby, vdest>>

FRefuseSeal ==
    /\ fin = "seal" /\ fl = "none"
    /\ fl' = fin
    /\ flby' = fby
    /\ fin' = "none"
    /\ fby' = 0
    /\ fp' = (IF Retry THEN "discd" ELSE "hold")
    /\ UNCHANGED <<now, holder, exp, intF, intG, clF, clG, disc, seals,
                   dest, sealedR, badCover, rec, legdisc, late, gone, legab, fr,
                   fd, gp, gin, gby, gl, glby, gr, gd, wp,
                   wo, wc, win, wby, wl, wlby, wdest, vp, vo,
                   vc, vin, vby, vl, vlby, vdest>>

FRefuseAband ==
    /\ fin = "aband" /\ fl = "none"
    /\ fl' = fin
    /\ flby' = fby
    /\ fin' = "none"
    /\ fby' = 0
    /\ fp' = "hold"
    /\ UNCHANGED <<now, holder, exp, intF, intG, clF, clG, disc, seals,
                   dest, sealedR, badCover, rec, legdisc, late, gone, legab, fr,
                   fd, gp, gin, gby, gl, glby, gr, gd, wp,
                   wo, wc, win, wby, wl, wlby, wdest, vp, vo,
                   vc, vin, vby, vl, vlby, vdest>>

FLateIntent ==
    /\ fl = "intent" /\ now <= flby
    /\ fl' = "none"
    /\ flby' = 0
    /\ intF' = "open"
    /\ UNCHANGED <<now, holder, exp, intG, clF, clG, disc, seals, dest,
                   sealedR, badCover, rec, legdisc, late, gone, legab, fp, fin,
                   fby, fr, fd, gp, gin, gby, gl, glby, gr,
                   gd, wp, wo, wc, win, wby, wl, wlby, wdest,
                   vp, vo, vc, vin, vby, vl, vlby, vdest>>

FLatePurge ==
    /\ fl = "purge" /\ now <= flby
    /\ fl' = "none"
    /\ flby' = 0
    /\ dest' = TRUE
    /\ UNCHANGED <<now, holder, exp, intF, intG, clF, clG, disc, seals,
                   sealedR, badCover, rec, legdisc, late, gone, legab, fp, fin,
                   fby, fr, fd, gp, gin, gby, gl, glby, gr,
                   gd, wp, wo, wc, win, wby, wl, wlby, wdest,
                   vp, vo, vc, vin, vby, vl, vlby, vdest>>

FLateDisc ==
    /\ fl = "disc" /\ now <= flby
    /\ fl' = "none"
    /\ flby' = 0
    /\ disc' = Inc(disc)
    /\ UNCHANGED <<now, holder, exp, intF, intG, clF, clG, seals, dest,
                   sealedR, badCover, rec, legdisc, late, gone, legab, fp, fin,
                   fby, fr, fd, gp, gin, gby, gl, glby, gr,
                   gd, wp, wo, wc, win, wby, wl, wlby, wdest,
                   vp, vo, vc, vin, vby, vl, vlby, vdest>>

FLateSeal ==
    /\ fl = "seal" /\ now <= flby
    /\ fl' = "none"
    /\ flby' = 0
    /\ seals' = Inc(seals)
    /\ clF' = Inc(clF)
    /\ intF' = (IF intF = "open" THEN "sealed" ELSE intF)
    /\ sealedR' = (IF seals = 0 THEN fr ELSE sealedR)
    /\ late' = TRUE
    /\ UNCHANGED <<now, holder, exp, intG, clG, disc, dest, badCover, rec,
                   legdisc, gone, legab, fp, fin, fby, fr, fd, gp,
                   gin, gby, gl, glby, gr, gd, wp, wo, wc,
                   win, wby, wl, wlby, wdest, vp, vo, vc, vin,
                   vby, vl, vlby, vdest>>

FLateAband ==
    /\ fl = "aband" /\ now <= flby
    /\ fl' = "none"
    /\ flby' = 0
    /\ clF' = Inc(clF)
    /\ intF' = (IF intF = "open" THEN "aband" ELSE intF)
    /\ UNCHANGED <<now, holder, exp, intG, clG, disc, seals, dest, sealedR,
                   badCover, rec, legdisc, late, gone, legab, fp, fin, fby,
                   fr, fd, gp, gin, gby, gl, glby, gr, gd,
                   wp, wo, wc, win, wby, wl, wlby, wdest, vp,
                   vo, vc, vin, vby, vl, vlby, vdest>>

FLateDie ==
    /\ fl # "none"
    /\ fl' = "none"
    /\ flby' = 0
    /\ UNCHANGED <<now, holder, exp, intF, intG, clF, clG, disc, seals,
                   dest, sealedR, badCover, rec, legdisc, late, gone, legab, fp,
                   fin, fby, fr, fd, gp, gin, gby, gl, glby,
                   gr, gd, wp, wo, wc, win, wby, wl, wlby,
                   wdest, vp, vo, vc, vin, vby, vl, vlby, vdest>>

\* Concurrency 19 through 22: no release with a call in flight, and none over a call that answered and may still land.
FRelease ==
    /\ (fp \in {"rel", "adm"} \/ (fp = "hold" /\ ~HoldRefused))
    /\ fin = "none"
    /\ (HoldRefused => fl = "none")
    /\ holder' = (IF holder = "f" THEN "none" ELSE holder)
    /\ exp' = (IF holder = "f" THEN 0 ELSE exp)
    /\ fp' = "done"
    /\ UNCHANGED <<now, intF, intG, clF, clG, disc, seals, dest, sealedR,
                   badCover, rec, legdisc, late, gone, legab, fin, fby, fl,
                   flby, fr, fd, gp, gin, gby, gl, glby, gr,
                   gd, wp, wo, wc, win, wby, wl, wlby, wdest,
                   vp, vo, vc, vin, vby, vl, vlby, vdest>>

\* The twin reads the request's state first and takes the section afterwards.
GPre ==
    /\ GOn /\ ~StateInside /\ gp = "idle"
    /\ gp' = (IF AdmitOK THEN "pre" ELSE "done")
    /\ UNCHANGED <<now, holder, exp, intF, intG, clF, clG, disc, seals,
                   dest, sealedR, badCover, rec, legdisc, late, gone, legab, fp,
                   fin, fby, fl, flby, fr, fd, gin, gby, gl,
                   glby, gr, gd, wp, wo, wc, win, wby, wl,
                   wlby, wdest, vp, vo, vc, vin, vby, vl, vlby,
                   vdest>>

\* Concurrency 3: the request section, by try_take for the section term.
GTake ==
    /\ GOn /\ ((StateInside /\ gp = "idle") \/ gp = "pre")
    /\ Free
    /\ holder' = "g"
    /\ exp' = (now + Dur)
    /\ gp' = (IF gp = "pre" THEN "adm" ELSE "held")
    /\ UNCHANGED <<now, intF, intG, clF, clG, disc, seals, dest, sealedR,
                   badCover, rec, legdisc, late, gone, legab, fp, fin, fby,
                   fl, flby, fr, fd, gin, gby, gl, glby, gr,
                   gd, wp, wo, wc, win, wby, wl, wlby, wdest,
                   vp, vo, vc, vin, vby, vl, vlby, vdest>>

\* Concurrency 7, Action wiring 5 and 6: the request's state read under the section.
GRead ==
    /\ gp = "held"
    /\ gp' = (IF AdmitOK THEN "adm" ELSE "rel")
    /\ UNCHANGED <<now, holder, exp, intF, intG, clF, clG, disc, seals,
                   dest, sealedR, badCover, rec, legdisc, late, gone, legab, fp,
                   fin, fby, fl, flby, fr, fd, gin, gby, gl,
                   glby, gr, gd, wp, wo, wc, win, wby, wl,
                   wlby, wdest, vp, vo, vc, vin, vby, vl, vlby,
                   vdest>>

\* Concurrency 12: an audit write starts only while the grant has its latency left.
GIntent ==
    /\ gp = "adm" /\ gin = "none" /\ gl = "none"
    /\ (~Reads \/ (holder = "g" /\ exp > now + Lat))
    /\ gin' = "intent"
    /\ gby' = (now + Lat)
    /\ UNCHANGED <<now, holder, exp, intF, intG, clF, clG, disc, seals,
                   dest, sealedR, badCover, rec, legdisc, late, gone, legab, fp,
                   fin, fby, fl, flby, fr, fd, gp, gl, glby,
                   gr, gd, wp, wo, wc, win, wby, wl, wlby,
                   wdest, vp, vo, vc, vin, vby, vl, vlby, vdest>>

\* Concurrency 13: a planned call starts only above the plan floor, the bind still fitting after it.
GPurge ==
    /\ HasPlan /\ gp \in {"intd", "retry"} /\ gin = "none"
    /\ (~Reads \/ (holder = "g" /\ exp > now + PLat + Pause + Lat))
    /\ gin' = "purge"
    /\ gby' = (now + PLat)
    /\ UNCHANGED <<now, holder, exp, intF, intG, clF, clG, disc, seals,
                   dest, sealedR, badCover, rec, legdisc, late, gone, legab, fp,
                   fin, fby, fl, flby, fr, fd, gp, gl, glby,
                   gr, gd, wp, wo, wc, win, wby, wl, wlby,
                   wdest, vp, vo, vc, vin, vby, vl, vlby, vdest>>

\* The access path, and an erasure whose plans stand empty: no planned call.
GNoPlan ==
    /\ ~HasPlan /\ gp = "intd" /\ gin = "none"
    /\ gr' = "none"
    /\ gp' = "exec"
    /\ UNCHANGED <<now, holder, exp, intF, intG, clF, clG, disc, seals,
                   dest, sealedR, badCover, rec, legdisc, late, gone, legab, fp,
                   fin, fby, fl, flby, fr, fd, gin, gby, gl,
                   glby, gd, wp, wo, wc, win, wby, wl, wlby,
                   wdest, vp, vo, vc, vin, vby, vl, vlby, vdest>>

\* Disposition 45: a planned record the grant admits no call for is unsettled.
GSkip ==
    /\ HasPlan /\ gp \in {"intd", "retry"} /\ gin = "none"
    /\ ~(holder = "g" /\ exp > now + PLat + Pause + Lat)
    /\ gr' = "unsettled"
    /\ gp' = "exec"
    /\ UNCHANGED <<now, holder, exp, intF, intG, clF, clG, disc, seals,
                   dest, sealedR, badCover, rec, legdisc, late, gone, legab, fp,
                   fin, fby, fl, flby, fr, fd, gin, gby, gl,
                   glby, gd, wp, wo, wc, win, wby, wl, wlby,
                   wdest, vp, vo, vc, vin, vby, vl, vlby, vdest>>

\* Concurrency 9: the disclosure write on a live reading.
GDisc ==
    /\ gp = "exec" /\ gin = "none"
    /\ (~Reads \/ (holder = "g" /\ exp > now + Pause))
    /\ gin' = "disc"
    /\ gby' = (now + Pause)
    /\ UNCHANGED <<now, holder, exp, intF, intG, clF, clG, disc, seals,
                   dest, sealedR, badCover, rec, legdisc, late, gone, legab, fp,
                   fin, fby, fl, flby, fr, fd, gp, gl, glby,
                   gr, gd, wp, wo, wc, win, wby, wl, wlby,
                   wdest, vp, vo, vc, vin, vby, vl, vlby, vdest>>

GSeal ==
    /\ gp = "discd" /\ gin = "none"
    /\ (~Reads \/ (holder = "g" /\ exp > now + Lat))
    /\ gin' = "seal"
    /\ gby' = (now + Lat)
    /\ UNCHANGED <<now, holder, exp, intF, intG, clF, clG, disc, seals,
                   dest, sealedR, badCover, rec, legdisc, late, gone, legab, fp,
                   fin, fby, fl, flby, fr, fd, gp, gl, glby,
                   gr, gd, wp, wo, wc, win, wby, wl, wlby,
                   wdest, vp, vo, vc, vin, vby, vl, vlby, vdest>>

\* Action wiring 19 and 39: an abandonment over a refused disclosure write with nothing possibly destroyed, never over one that did not answer.
GAband ==
    /\ gp = "discr" /\ gin = "none"
    /\ ((gd = "ref" \/ (AbandonUnanswered /\ gd = "una")) /\ gr \notin {"erased", "unsettled"})
    /\ (~Reads \/ (holder = "g" /\ exp > now + Lat))
    /\ gin' = "aband"
    /\ gby' = (now + Lat)
    /\ UNCHANGED <<now, holder, exp, intF, intG, clF, clG, disc, seals,
                   dest, sealedR, badCover, rec, legdisc, late, gone, legab, fp,
                   fin, fby, fl, flby, fr, fd, gp, gl, glby,
                   gr, gd, wp, wo, wc, win, wby, wl, wlby,
                   wdest, vp, vo, vc, vin, vby, vl, vlby, vdest>>

\* Action wiring 29: the fulfillment answers outcome and leaves the intent open.
GGiveUp ==
    /\ gp = "discr" /\ gin = "none"
    /\ ~((gd = "ref" \/ (AbandonUnanswered /\ gd = "una")) /\ gr \notin {"erased", "unsettled"})
    /\ gp' = (IF gd = "una" THEN "hold" ELSE "rel")
    /\ UNCHANGED <<now, holder, exp, intF, intG, clF, clG, disc, seals,
                   dest, sealedR, badCover, rec, legdisc, late, gone, legab, fp,
                   fin, fby, fl, flby, fr, fd, gin, gby, gl,
                   glby, gr, gd, wp, wo, wc, win, wby, wl,
                   wlby, wdest, vp, vo, vc, vin, vby, vl, vlby,
                   vdest>>

GLandIntent ==
    /\ gin = "intent" /\ now <= gby
    /\ gin' = "none"
    /\ gby' = 0
    /\ intG' = "open"
    /\ gp' = "intd"
    /\ UNCHANGED <<now, holder, exp, intF, clF, clG, disc, seals, dest,
                   sealedR, badCover, rec, legdisc, late, gone, legab, fp, fin,
                   fby, fl, flby, fr, fd, gl, glby, gr, gd,
                   wp, wo, wc, win, wby, wl, wlby, wdest, vp,
                   vo, vc, vin, vby, vl, vlby, vdest>>

GLandPurge ==
    /\ gin = "purge" /\ now <= gby
    /\ gin' = "none"
    /\ gby' = 0
    /\ dest' = TRUE
    /\ gr' = "erased"
    /\ gp' = "exec"
    /\ UNCHANGED <<now, holder, exp, intF, intG, clF, clG, disc, seals,
                   sealedR, badCover, rec, legdisc, late, gone, legab, fp, fin,
                   fby, fl, flby, fr, fd, gl, glby, gd, wp,
                   wo, wc, win, wby, wl, wlby, wdest, vp, vo,
                   vc, vin, vby, vl, vlby, vdest>>

GLandDisc ==
    /\ gin = "disc" /\ now <= gby
    /\ gin' = "none"
    /\ gby' = 0
    /\ disc' = Inc(disc)
    /\ gd' = "ok"
    /\ gp' = "discd"
    /\ UNCHANGED <<now, holder, exp, intF, intG, clF, clG, seals, dest,
                   sealedR, badCover, rec, legdisc, late, gone, legab, fp, fin,
                   fby, fl, flby, fr, fd, gl, glby, gr, wp,
                   wo, wc, win, wby, wl, wlby, wdest, vp, vo,
                   vc, vin, vby, vl, vlby, vdest>>

GLandSeal ==
    /\ gin = "seal" /\ now <= gby
    /\ gin' = "none"
    /\ gby' = 0
    /\ seals' = Inc(seals)
    /\ clG' = Inc(clG)
    /\ intG' = (IF intG = "open" THEN "sealed" ELSE intG)
    /\ sealedR' = (IF seals = 0 THEN gr ELSE sealedR)
    /\ gp' = "rel"
    /\ UNCHANGED <<now, holder, exp, intF, clF, disc, dest, badCover, rec,
                   legdisc, late, gone, legab, fp, fin, fby, fl, flby,
                   fr, fd, gl, glby, gr, gd, wp, wo, wc,
                   win, wby, wl, wlby, wdest, vp, vo, vc, vin,
                   vby, vl, vlby, vdest>>

GLandAband ==
    /\ gin = "aband" /\ now <= gby
    /\ gin' = "none"
    /\ gby' = 0
    /\ clG' = Inc(clG)
    /\ intG' = (IF intG = "open" THEN "aband" ELSE intG)
    /\ gp' = "rel"
    /\ UNCHANGED <<now, holder, exp, intF, clF, disc, seals, dest, sealedR,
                   badCover, rec, legdisc, late, gone, legab, fp, fin, fby,
                   fl, flby, fr, fd, gl, glby, gr, gd, wp,
                   wo, wc, win, wby, wl, wlby, wdest, vp, vo,
                   vc, vin, vby, vl, vlby, vdest>>

\* A refusal that applied nothing: the record is owed, or the gate refused, or the store refused.
GFailIntent ==
    /\ gin = "intent"
    /\ gin' = "none"
    /\ gby' = 0
    /\ gp' = "rel"
    /\ UNCHANGED <<now, holder, exp, intF, intG, clF, clG, disc, seals,
                   dest, sealedR, badCover, rec, legdisc, late, gone, legab, fp,
                   fin, fby, fl, flby, fr, fd, gl, glby, gr,
                   gd, wp, wo, wc, win, wby, wl, wlby, wdest,
                   vp, vo, vc, vin, vby, vl, vlby, vdest>>

\* Term purge reading: a pair that answered storage-failure is unsettled whatever the gate then refuses.
GFailPurge ==
    /\ gin = "purge"
    /\ gin' = "none"
    /\ gby' = 0
    /\ gr' = (IF gr = "tainted" /\ Taint THEN "unsettled" ELSE "retained")
    /\ gp' = "exec"
    /\ UNCHANGED <<now, holder, exp, intF, intG, clF, clG, disc, seals,
                   dest, sealedR, badCover, rec, legdisc, late, gone, legab, fp,
                   fin, fby, fl, flby, fr, fd, gl, glby, gd,
                   wp, wo, wc, win, wby, wl, wlby, wdest, vp,
                   vo, vc, vin, vby, vl, vlby, vdest>>

\* Defensible Retention Atomic writes 8 and 9: a purge that answers storage-failure leaves the retention retained, and the record may be gone all the same.
GStorPurge ==
    /\ gin = "purge"
    /\ gin' = "none"
    /\ gby' = 0
    /\ gr' = (IF ~Unsettled THEN "retained" ELSE IF gr = "tainted" THEN "unsettled" ELSE "tainted")
    /\ gp' = (IF Unsettled /\ gr # "tainted" THEN "retry" ELSE "exec")
    /\ UNCHANGED <<now, holder, exp, intF, intG, clF, clG, disc, seals,
                   dest, sealedR, badCover, rec, legdisc, late, gone, legab, fp,
                   fin, fby, fl, flby, fr, fd, gl, glby, gd,
                   wp, wo, wc, win, wby, wl, wlby, wdest, vp,
                   vo, vc, vin, vby, vl, vlby, vdest>>

GStorPurgeGone ==
    /\ gin = "purge"
    /\ gin' = "none"
    /\ gby' = 0
    /\ gr' = (IF ~Unsettled THEN "retained" ELSE IF gr = "tainted" THEN "unsettled" ELSE "tainted")
    /\ gp' = (IF Unsettled /\ gr # "tainted" THEN "retry" ELSE "exec")
    /\ gone' = TRUE
    /\ UNCHANGED <<now, holder, exp, intF, intG, clF, clG, disc, seals,
                   dest, sealedR, badCover, rec, legdisc, late, legab, fp, fin,
                   fby, fl, flby, fr, fd, gl, glby, gd, wp,
                   wo, wc, win, wby, wl, wlby, wdest, vp, vo,
                   vc, vin, vby, vl, vlby, vdest>>

GFailDisc ==
    /\ gin = "disc"
    /\ gin' = "none"
    /\ gby' = 0
    /\ gd' = "ref"
    /\ gp' = "discr"
    /\ UNCHANGED <<now, holder, exp, intF, intG, clF, clG, disc, seals,
                   dest, sealedR, badCover, rec, legdisc, late, gone, legab, fp,
                   fin, fby, fl, flby, fr, fd, gl, glby, gr,
                   wp, wo, wc, win, wby, wl, wlby, wdest, vp,
                   vo, vc, vin, vby, vl, vlby, vdest>>

GFailSeal ==
    /\ gin = "seal"
    /\ gin' = "none"
    /\ gby' = 0
    /\ gp' = "rel"
    /\ UNCHANGED <<now, holder, exp, intF, intG, clF, clG, disc, seals,
                   dest, sealedR, badCover, rec, legdisc, late, gone, legab, fp,
                   fin, fby, fl, flby, fr, fd, gl, glby, gr,
                   gd, wp, wo, wc, win, wby, wl, wlby, wdest,
                   vp, vo, vc, vin, vby, vl, vlby, vdest>>

GFailAband ==
    /\ gin = "aband"
    /\ gin' = "none"
    /\ gby' = 0
    /\ gp' = "rel"
    /\ UNCHANGED <<now, holder, exp, intF, intG, clF, clG, disc, seals,
                   dest, sealedR, badCover, rec, legdisc, late, gone, legab, fp,
                   fin, fby, fl, flby, fr, fd, gl, glby, gr,
                   gd, wp, wo, wc, win, wby, wl, wlby, wdest,
                   vp, vo, vc, vin, vby, vl, vlby, vdest>>

\* The call answered a step-3 refusal, or never answered, and the write behind it stays in flight: it may still land, or not (Audit Trail record action step 3.7).
GRefuseIntent ==
    /\ gin = "intent" /\ gl = "none"
    /\ gl' = gin
    /\ glby' = gby
    /\ gin' = "none"
    /\ gby' = 0
    /\ gp' = "hold"
    /\ UNCHANGED <<now, holder, exp, intF, intG, clF, clG, disc, seals,
                   dest, sealedR, badCover, rec, legdisc, late, gone, legab, fp,
                   fin, fby, fl, flby, fr, fd, gr, gd, wp,
                   wo, wc, win, wby, wl, wlby, wdest, vp, vo,
                   vc, vin, vby, vl, vlby, vdest>>

GRefusePurge ==
    /\ gin = "purge" /\ gl = "none"
    /\ gl' = gin
    /\ glby' = gby
    /\ gin' = "none"
    /\ gby' = 0
    /\ gr' = (IF Unsettled THEN "unsettled" ELSE "retained")
    /\ gp' = "exec"
    /\ UNCHANGED <<now, holder, exp, intF, intG, clF, clG, disc, seals,
                   dest, sealedR, badCover, rec, legdisc, late, gone, legab, fp,
                   fin, fby, fl, flby, fr, fd, gd, wp, wo,
                   wc, win, wby, wl, wlby, wdest, vp, vo, vc,
                   vin, vby, vl, vlby, vdest>>

GRefuseDisc ==
    /\ gin = "disc" /\ gl = "none"
    /\ gl' = gin
    /\ glby' = gby
    /\ gin' = "none"
    /\ gby' = 0
    /\ gd' = "una"
    /\ gp' = "discr"
    /\ UNCHANGED <<now, holder, exp, intF, intG, clF, clG, disc, seals,
                   dest, sealedR, badCover, rec, legdisc, late, gone, legab, fp,
                   fin, fby, fl, flby, fr, fd, gr, wp, wo,
                   wc, win, wby, wl, wlby, wdest, vp, vo, vc,
                   vin, vby, vl, vlby, vdest>>

GRefuseSeal ==
    /\ gin = "seal" /\ gl = "none"
    /\ gl' = gin
    /\ glby' = gby
    /\ gin' = "none"
    /\ gby' = 0
    /\ gp' = (IF Retry THEN "discd" ELSE "hold")
    /\ UNCHANGED <<now, holder, exp, intF, intG, clF, clG, disc, seals,
                   dest, sealedR, badCover, rec, legdisc, late, gone, legab, fp,
                   fin, fby, fl, flby, fr, fd, gr, gd, wp,
                   wo, wc, win, wby, wl, wlby, wdest, vp, vo,
                   vc, vin, vby, vl, vlby, vdest>>

GRefuseAband ==
    /\ gin = "aband" /\ gl = "none"
    /\ gl' = gin
    /\ glby' = gby
    /\ gin' = "none"
    /\ gby' = 0
    /\ gp' = "hold"
    /\ UNCHANGED <<now, holder, exp, intF, intG, clF, clG, disc, seals,
                   dest, sealedR, badCover, rec, legdisc, late, gone, legab, fp,
                   fin, fby, fl, flby, fr, fd, gr, gd, wp,
                   wo, wc, win, wby, wl, wlby, wdest, vp, vo,
                   vc, vin, vby, vl, vlby, vdest>>

GLateIntent ==
    /\ gl = "intent" /\ now <= glby
    /\ gl' = "none"
    /\ glby' = 0
    /\ intG' = "open"
    /\ UNCHANGED <<now, holder, exp, intF, clF, clG, disc, seals, dest,
                   sealedR, badCover, rec, legdisc, late, gone, legab, fp, fin,
                   fby, fl, flby, fr, fd, gp, gin, gby, gr,
                   gd, wp, wo, wc, win, wby, wl, wlby, wdest,
                   vp, vo, vc, vin, vby, vl, vlby, vdest>>

GLatePurge ==
    /\ gl = "purge" /\ now <= glby
    /\ gl' = "none"
    /\ glby' = 0
    /\ dest' = TRUE
    /\ UNCHANGED <<now, holder, exp, intF, intG, clF, clG, disc, seals,
                   sealedR, badCover, rec, legdisc, late, gone, legab, fp, fin,
                   fby, fl, flby, fr, fd, gp, gin, gby, gr,
                   gd, wp, wo, wc, win, wby, wl, wlby, wdest,
                   vp, vo, vc, vin, vby, vl, vlby, vdest>>

GLateDisc ==
    /\ gl = "disc" /\ now <= glby
    /\ gl' = "none"
    /\ glby' = 0
    /\ disc' = Inc(disc)
    /\ UNCHANGED <<now, holder, exp, intF, intG, clF, clG, seals, dest,
                   sealedR, badCover, rec, legdisc, late, gone, legab, fp, fin,
                   fby, fl, flby, fr, fd, gp, gin, gby, gr,
                   gd, wp, wo, wc, win, wby, wl, wlby, wdest,
                   vp, vo, vc, vin, vby, vl, vlby, vdest>>

GLateSeal ==
    /\ gl = "seal" /\ now <= glby
    /\ gl' = "none"
    /\ glby' = 0
    /\ seals' = Inc(seals)
    /\ clG' = Inc(clG)
    /\ intG' = (IF intG = "open" THEN "sealed" ELSE intG)
    /\ sealedR' = (IF seals = 0 THEN gr ELSE sealedR)
    /\ late' = TRUE
    /\ UNCHANGED <<now, holder, exp, intF, clF, disc, dest, badCover, rec,
                   legdisc, gone, legab, fp, fin, fby, fl, flby, fr,
                   fd, gp, gin, gby, gr, gd, wp, wo, wc,
                   win, wby, wl, wlby, wdest, vp, vo, vc, vin,
                   vby, vl, vlby, vdest>>

GLateAband ==
    /\ gl = "aband" /\ now <= glby
    /\ gl' = "none"
    /\ glby' = 0
    /\ clG' = Inc(clG)
    /\ intG' = (IF intG = "open" THEN "aband" ELSE intG)
    /\ UNCHANGED <<now, holder, exp, intF, clF, disc, seals, dest, sealedR,
                   badCover, rec, legdisc, late, gone, legab, fp, fin, fby,
                   fl, flby, fr, fd, gp, gin, gby, gr, gd,
                   wp, wo, wc, win, wby, wl, wlby, wdest, vp,
                   vo, vc, vin, vby, vl, vlby, vdest>>

GLateDie ==
    /\ gl # "none"
    /\ gl' = "none"
    /\ glby' = 0
    /\ UNCHANGED <<now, holder, exp, intF, intG, clF, clG, disc, seals,
                   dest, sealedR, badCover, rec, legdisc, late, gone, legab, fp,
                   fin, fby, fl, flby, fr, fd, gp, gin, gby,
                   gr, gd, wp, wo, wc, win, wby, wl, wlby,
                   wdest, vp, vo, vc, vin, vby, vl, vlby, vdest>>

\* Concurrency 19 through 22: no release with a call in flight, and none over a call that answered and may still land.
GRelease ==
    /\ (gp \in {"rel", "adm"} \/ (gp = "hold" /\ ~HoldRefused))
    /\ gin = "none"
    /\ (HoldRefused => gl = "none")
    /\ holder' = (IF holder = "g" THEN "none" ELSE holder)
    /\ exp' = (IF holder = "g" THEN 0 ELSE exp)
    /\ gp' = "done"
    /\ UNCHANGED <<now, intF, intG, clF, clG, disc, seals, dest, sealedR,
                   badCover, rec, legdisc, late, gone, legab, fp, fin, fby,
                   fl, flby, fr, fd, gin, gby, gl, glby, gr,
                   gd, wp, wo, wc, win, wby, wl, wlby, wdest,
                   vp, vo, vc, vin, vby, vl, vlby, vdest>>

\* Reconciliation 17: a leg closes nothing before it holds the request section.
WTake ==
    /\ WOn /\ LegTakes /\ wp = "idle" /\ AnyOpen
    /\ Free
    /\ holder' = "w"
    /\ exp' = (now + Dur)
    /\ wp' = "held"
    /\ UNCHANGED <<now, intF, intG, clF, clG, disc, seals, dest, sealedR,
                   badCover, rec, legdisc, late, gone, legab, fp, fin, fby,
                   fl, flby, fr, fd, gp, gin, gby, gl, glby,
                   gr, gd, wo, wc, win, wby, wl, wlby, wdest,
                   vp, vo, vc, vin, vby, vl, vlby, vdest>>

\* Reconciliation 9, 23 and 30: the request's events, the disclosure store and the plan's store, read under the section.
WReadF ==
    /\ (wp = "held" \/ (WOn /\ ~LegTakes /\ wp = "idle" /\ AnyOpen))
    /\ intF = "open"
    /\ wo' = "f"
    /\ wc' = (IF disc > 0 THEN "comp" ELSE IF (HasPlan /\ ~AbandonPlanned) \/ dest THEN "complete" ELSE "aband")
    /\ wdest' = dest
    /\ wp' = "read"
    /\ UNCHANGED <<now, holder, exp, intF, intG, clF, clG, disc, seals,
                   dest, sealedR, badCover, rec, legdisc, late, gone, legab, fp,
                   fin, fby, fl, flby, fr, fd, gp, gin, gby,
                   gl, glby, gr, gd, win, wby, wl, wlby, vp,
                   vo, vc, vin, vby, vl, vlby, vdest>>

WReadG ==
    /\ (wp = "held" \/ (WOn /\ ~LegTakes /\ wp = "idle" /\ AnyOpen))
    /\ intG = "open"
    /\ wo' = "g"
    /\ wc' = (IF disc > 0 THEN "comp" ELSE IF (HasPlan /\ ~AbandonPlanned) \/ dest THEN "complete" ELSE "aband")
    /\ wdest' = dest
    /\ wp' = "read"
    /\ UNCHANGED <<now, holder, exp, intF, intG, clF, clG, disc, seals,
                   dest, sealedR, badCover, rec, legdisc, late, gone, legab, fp,
                   fin, fby, fl, flby, fr, fd, gp, gin, gby,
                   gl, glby, gr, gd, win, wby, wl, wlby, vp,
                   vo, vc, vin, vby, vl, vlby, vdest>>

WReadNone ==
    /\ wp = "held"
    /\ ~AnyOpen
    /\ wp' = "fin"
    /\ UNCHANGED <<now, holder, exp, intF, intG, clF, clG, disc, seals,
                   dest, sealedR, badCover, rec, legdisc, late, gone, legab, fp,
                   fin, fby, fl, flby, fr, fd, gp, gin, gby,
                   gl, glby, gr, gd, wo, wc, win, wby, wl,
                   wlby, wdest, vp, vo, vc, vin, vby, vl, vlby,
                   vdest>>

\* Reconciliation 12: a disclosure exists, so the leg seals.
WCompensate ==
    /\ wp = "read" /\ win = "none" /\ wl = "none"
    /\ wc = "comp"
    /\ (~LegTakes \/ (holder = "w" /\ exp > now + Lat))
    /\ win' = "seal"
    /\ wby' = (now + Lat)
    /\ UNCHANGED <<now, holder, exp, intF, intG, clF, clG, disc, seals,
                   dest, sealedR, badCover, rec, legdisc, late, gone, legab, fp,
                   fin, fby, fl, flby, fr, fd, gp, gin, gby,
                   gl, glby, gr, gd, wp, wo, wc, wl, wlby,
                   wdest, vp, vo, vc, vin, vby, vl, vlby, vdest>>

\* Reconciliation 13: no disclosure and a destruction planned, so the leg discloses and then seals.
WComplete ==
    /\ wp = "read" /\ win = "none" /\ wl = "none"
    /\ wc = "complete"
    /\ (~LegTakes \/ (holder = "w" /\ exp > now + Pause))
    /\ win' = "disc"
    /\ wby' = (now + Pause)
    /\ UNCHANGED <<now, holder, exp, intF, intG, clF, clG, disc, seals,
                   dest, sealedR, badCover, rec, legdisc, late, gone, legab, fp,
                   fin, fby, fl, flby, fr, fd, gp, gin, gby,
                   gl, glby, gr, gd, wp, wo, wc, wl, wlby,
                   wdest, vp, vo, vc, vin, vby, vl, vlby, vdest>>

\* Reconciliation 15: no disclosure and nothing planned, so the leg abandons.
WAbandon ==
    /\ wp = "read" /\ win = "none" /\ wl = "none"
    /\ wc = "aband"
    /\ (~LegTakes \/ (holder = "w" /\ exp > now + Lat))
    /\ win' = "aband"
    /\ wby' = (now + Lat)
    /\ UNCHANGED <<now, holder, exp, intF, intG, clF, clG, disc, seals,
                   dest, sealedR, badCover, rec, legdisc, late, gone, legab, fp,
                   fin, fby, fl, flby, fr, fd, gp, gin, gby,
                   gl, glby, gr, gd, wp, wo, wc, wl, wlby,
                   wdest, vp, vo, vc, vin, vby, vl, vlby, vdest>>

\* Reconciliation 14, 16 and 24: the planned record sealed from the store's word, the settled one from the intent.
WLandSeal ==
    /\ win = "seal" /\ now <= wby
    /\ win' = "none"
    /\ wby' = 0
    /\ seals' = Inc(seals)
    /\ clF' = (IF wo = "f" THEN Inc(clF) ELSE clF)
    /\ clG' = (IF wo = "g" THEN Inc(clG) ELSE clG)
    /\ intF' = (IF wo = "f" /\ intF = "open" THEN "sealed" ELSE intF)
    /\ intG' = (IF wo = "g" /\ intG = "open" THEN "sealed" ELSE intG)
    /\ sealedR' = (IF seals = 0 THEN (IF wdest THEN "erased" ELSE IF HasPlan THEN "unsettled" ELSE "none") ELSE sealedR)
    /\ badCover' = (badCover \/ ~FromIntent)
    /\ rec' = TRUE
    /\ wp' = "fin"
    /\ UNCHANGED <<now, holder, exp, disc, dest, legdisc, late, gone, legab,
                   fp, fin, fby, fl, flby, fr, fd, gp, gin,
                   gby, gl, glby, gr, gd, wo, wc, wl, wlby,
                   wdest, vp, vo, vc, vin, vby, vl, vlby, vdest>>

WLandDisc ==
    /\ win = "disc" /\ now <= wby
    /\ win' = "none"
    /\ wby' = 0
    /\ disc' = Inc(disc)
    /\ wc' = "comp"
    /\ legdisc' = TRUE
    /\ UNCHANGED <<now, holder, exp, intF, intG, clF, clG, seals, dest,
                   sealedR, badCover, rec, late, gone, legab, fp, fin, fby,
                   fl, flby, fr, fd, gp, gin, gby, gl, glby,
                   gr, gd, wp, wo, wl, wlby, wdest, vp, vo,
                   vc, vin, vby, vl, vlby, vdest>>

WLandAband ==
    /\ win = "aband" /\ now <= wby
    /\ win' = "none"
    /\ wby' = 0
    /\ clF' = (IF wo = "f" THEN Inc(clF) ELSE clF)
    /\ clG' = (IF wo = "g" THEN Inc(clG) ELSE clG)
    /\ intF' = (IF wo = "f" /\ intF = "open" THEN "aband" ELSE intF)
    /\ intG' = (IF wo = "g" /\ intG = "open" THEN "aband" ELSE intG)
    /\ wp' = "fin"
    /\ legab' = TRUE
    /\ UNCHANGED <<now, holder, exp, disc, seals, dest, sealedR, badCover, rec,
                   legdisc, late, gone, fp, fin, fby, fl, flby, fr,
                   fd, gp, gin, gby, gl, glby, gr, gd, wo,
                   wc, wl, wlby, wdest, vp, vo, vc, vin, vby,
                   vl, vlby, vdest>>

\* Reconciliation 28: a call that refuses leaves the leg's remaining work to the next run.
WFail ==
    /\ win # "none"
    /\ win' = "none"
    /\ wby' = 0
    /\ wp' = "fin"
    /\ UNCHANGED <<now, holder, exp, intF, intG, clF, clG, disc, seals,
                   dest, sealedR, badCover, rec, legdisc, late, gone, legab, fp,
                   fin, fby, fl, flby, fr, fd, gp, gin, gby,
                   gl, glby, gr, gd, wo, wc, wl, wlby, wdest,
                   vp, vo, vc, vin, vby, vl, vlby, vdest>>

WRefuse ==
    /\ win # "none" /\ wl = "none"
    /\ wl' = win
    /\ wlby' = wby
    /\ win' = "none"
    /\ wby' = 0
    /\ wp' = "hold"
    /\ UNCHANGED <<now, holder, exp, intF, intG, clF, clG, disc, seals,
                   dest, sealedR, badCover, rec, legdisc, late, gone, legab, fp,
                   fin, fby, fl, flby, fr, fd, gp, gin, gby,
                   gl, glby, gr, gd, wo, wc, wdest, vp, vo,
                   vc, vin, vby, vl, vlby, vdest>>

WLateSeal ==
    /\ wl = "seal" /\ now <= wlby
    /\ wl' = "none"
    /\ wlby' = 0
    /\ seals' = Inc(seals)
    /\ clF' = (IF wo = "f" THEN Inc(clF) ELSE clF)
    /\ clG' = (IF wo = "g" THEN Inc(clG) ELSE clG)
    /\ intF' = (IF wo = "f" /\ intF = "open" THEN "sealed" ELSE intF)
    /\ intG' = (IF wo = "g" /\ intG = "open" THEN "sealed" ELSE intG)
    /\ sealedR' = (IF seals = 0 THEN (IF wdest THEN "erased" ELSE IF HasPlan THEN "unsettled" ELSE "none") ELSE sealedR)
    /\ badCover' = (badCover \/ ~FromIntent)
    /\ rec' = TRUE
    /\ UNCHANGED <<now, holder, exp, disc, dest, legdisc, late, gone, legab,
                   fp, fin, fby, fl, flby, fr, fd, gp, gin,
                   gby, gl, glby, gr, gd, wp, wo, wc, win,
                   wby, wdest, vp, vo, vc, vin, vby, vl, vlby,
                   vdest>>

WLateDisc ==
    /\ wl = "disc" /\ now <= wlby
    /\ wl' = "none"
    /\ wlby' = 0
    /\ disc' = Inc(disc)
    /\ legdisc' = TRUE
    /\ UNCHANGED <<now, holder, exp, intF, intG, clF, clG, seals, dest,
                   sealedR, badCover, rec, late, gone, legab, fp, fin, fby,
                   fl, flby, fr, fd, gp, gin, gby, gl, glby,
                   gr, gd, wp, wo, wc, win, wby, wdest, vp,
                   vo, vc, vin, vby, vl, vlby, vdest>>

WLateAband ==
    /\ wl = "aband" /\ now <= wlby
    /\ wl' = "none"
    /\ wlby' = 0
    /\ clF' = (IF wo = "f" THEN Inc(clF) ELSE clF)
    /\ clG' = (IF wo = "g" THEN Inc(clG) ELSE clG)
    /\ intF' = (IF wo = "f" /\ intF = "open" THEN "aband" ELSE intF)
    /\ intG' = (IF wo = "g" /\ intG = "open" THEN "aband" ELSE intG)
    /\ UNCHANGED <<now, holder, exp, disc, seals, dest, sealedR, badCover, rec,
                   legdisc, late, gone, legab, fp, fin, fby, fl, flby,
                   fr, fd, gp, gin, gby, gl, glby, gr, gd,
                   wp, wo, wc, win, wby, wdest, vp, vo, vc,
                   vin, vby, vl, vlby, vdest>>

WLateDie ==
    /\ wl # "none"
    /\ wl' = "none"
    /\ wlby' = 0
    /\ UNCHANGED <<now, holder, exp, intF, intG, clF, clG, disc, seals,
                   dest, sealedR, badCover, rec, legdisc, late, gone, legab, fp,
                   fin, fby, fl, flby, fr, fd, gp, gin, gby,
                   gl, glby, gr, gd, wp, wo, wc, win, wby,
                   wdest, vp, vo, vc, vin, vby, vl, vlby, vdest>>

WRelease ==
    /\ (wp \in {"fin", "read"} \/ (wp = "hold" /\ ~HoldRefused))
    /\ win = "none"
    /\ (HoldRefused => wl = "none")
    /\ holder' = (IF holder = "w" THEN "none" ELSE holder)
    /\ exp' = (IF holder = "w" THEN 0 ELSE exp)
    /\ wp' = "done"
    /\ UNCHANGED <<now, intF, intG, clF, clG, disc, seals, dest, sealedR,
                   badCover, rec, legdisc, late, gone, legab, fp, fin, fby,
                   fl, flby, fr, fd, gp, gin, gby, gl, glby,
                   gr, gd, wo, wc, win, wby, wl, wlby, wdest,
                   vp, vo, vc, vin, vby, vl, vlby, vdest>>

\* Reconciliation 17: a leg closes nothing before it holds the request section.
VTake ==
    /\ VOn /\ LegTakes /\ vp = "idle" /\ AnyOpen
    /\ Free
    /\ holder' = "v"
    /\ exp' = (now + Dur)
    /\ vp' = "held"
    /\ UNCHANGED <<now, intF, intG, clF, clG, disc, seals, dest, sealedR,
                   badCover, rec, legdisc, late, gone, legab, fp, fin, fby,
                   fl, flby, fr, fd, gp, gin, gby, gl, glby,
                   gr, gd, wp, wo, wc, win, wby, wl, wlby,
                   wdest, vo, vc, vin, vby, vl, vlby, vdest>>

\* Reconciliation 9, 23 and 30: the request's events, the disclosure store and the plan's store, read under the section.
VReadF ==
    /\ (vp = "held" \/ (VOn /\ ~LegTakes /\ vp = "idle" /\ AnyOpen))
    /\ intF = "open"
    /\ vo' = "f"
    /\ vc' = (IF disc > 0 THEN "comp" ELSE IF (HasPlan /\ ~AbandonPlanned) \/ dest THEN "complete" ELSE "aband")
    /\ vdest' = dest
    /\ vp' = "read"
    /\ UNCHANGED <<now, holder, exp, intF, intG, clF, clG, disc, seals,
                   dest, sealedR, badCover, rec, legdisc, late, gone, legab, fp,
                   fin, fby, fl, flby, fr, fd, gp, gin, gby,
                   gl, glby, gr, gd, wp, wo, wc, win, wby,
                   wl, wlby, wdest, vin, vby, vl, vlby>>

VReadG ==
    /\ (vp = "held" \/ (VOn /\ ~LegTakes /\ vp = "idle" /\ AnyOpen))
    /\ intG = "open"
    /\ vo' = "g"
    /\ vc' = (IF disc > 0 THEN "comp" ELSE IF (HasPlan /\ ~AbandonPlanned) \/ dest THEN "complete" ELSE "aband")
    /\ vdest' = dest
    /\ vp' = "read"
    /\ UNCHANGED <<now, holder, exp, intF, intG, clF, clG, disc, seals,
                   dest, sealedR, badCover, rec, legdisc, late, gone, legab, fp,
                   fin, fby, fl, flby, fr, fd, gp, gin, gby,
                   gl, glby, gr, gd, wp, wo, wc, win, wby,
                   wl, wlby, wdest, vin, vby, vl, vlby>>

VReadNone ==
    /\ vp = "held"
    /\ ~AnyOpen
    /\ vp' = "fin"
    /\ UNCHANGED <<now, holder, exp, intF, intG, clF, clG, disc, seals,
                   dest, sealedR, badCover, rec, legdisc, late, gone, legab, fp,
                   fin, fby, fl, flby, fr, fd, gp, gin, gby,
                   gl, glby, gr, gd, wp, wo, wc, win, wby,
                   wl, wlby, wdest, vo, vc, vin, vby, vl, vlby,
                   vdest>>

\* Reconciliation 12: a disclosure exists, so the leg seals.
VCompensate ==
    /\ vp = "read" /\ vin = "none" /\ vl = "none"
    /\ vc = "comp"
    /\ (~LegTakes \/ (holder = "v" /\ exp > now + Lat))
    /\ vin' = "seal"
    /\ vby' = (now + Lat)
    /\ UNCHANGED <<now, holder, exp, intF, intG, clF, clG, disc, seals,
                   dest, sealedR, badCover, rec, legdisc, late, gone, legab, fp,
                   fin, fby, fl, flby, fr, fd, gp, gin, gby,
                   gl, glby, gr, gd, wp, wo, wc, win, wby,
                   wl, wlby, wdest, vp, vo, vc, vl, vlby, vdest>>

\* Reconciliation 13: no disclosure and a destruction planned, so the leg discloses and then seals.
VComplete ==
    /\ vp = "read" /\ vin = "none" /\ vl = "none"
    /\ vc = "complete"
    /\ (~LegTakes \/ (holder = "v" /\ exp > now + Pause))
    /\ vin' = "disc"
    /\ vby' = (now + Pause)
    /\ UNCHANGED <<now, holder, exp, intF, intG, clF, clG, disc, seals,
                   dest, sealedR, badCover, rec, legdisc, late, gone, legab, fp,
                   fin, fby, fl, flby, fr, fd, gp, gin, gby,
                   gl, glby, gr, gd, wp, wo, wc, win, wby,
                   wl, wlby, wdest, vp, vo, vc, vl, vlby, vdest>>

\* Reconciliation 15: no disclosure and nothing planned, so the leg abandons.
VAbandon ==
    /\ vp = "read" /\ vin = "none" /\ vl = "none"
    /\ vc = "aband"
    /\ (~LegTakes \/ (holder = "v" /\ exp > now + Lat))
    /\ vin' = "aband"
    /\ vby' = (now + Lat)
    /\ UNCHANGED <<now, holder, exp, intF, intG, clF, clG, disc, seals,
                   dest, sealedR, badCover, rec, legdisc, late, gone, legab, fp,
                   fin, fby, fl, flby, fr, fd, gp, gin, gby,
                   gl, glby, gr, gd, wp, wo, wc, win, wby,
                   wl, wlby, wdest, vp, vo, vc, vl, vlby, vdest>>

\* Reconciliation 14, 16 and 24: the planned record sealed from the store's word, the settled one from the intent.
VLandSeal ==
    /\ vin = "seal" /\ now <= vby
    /\ vin' = "none"
    /\ vby' = 0
    /\ seals' = Inc(seals)
    /\ clF' = (IF vo = "f" THEN Inc(clF) ELSE clF)
    /\ clG' = (IF vo = "g" THEN Inc(clG) ELSE clG)
    /\ intF' = (IF vo = "f" /\ intF = "open" THEN "sealed" ELSE intF)
    /\ intG' = (IF vo = "g" /\ intG = "open" THEN "sealed" ELSE intG)
    /\ sealedR' = (IF seals = 0 THEN (IF vdest THEN "erased" ELSE IF HasPlan THEN "unsettled" ELSE "none") ELSE sealedR)
    /\ badCover' = (badCover \/ ~FromIntent)
    /\ rec' = TRUE
    /\ vp' = "fin"
    /\ UNCHANGED <<now, holder, exp, disc, dest, legdisc, late, gone, legab,
                   fp, fin, fby, fl, flby, fr, fd, gp, gin,
                   gby, gl, glby, gr, gd, wp, wo, wc, win,
                   wby, wl, wlby, wdest, vo, vc, vl, vlby, vdest>>

VLandDisc ==
    /\ vin = "disc" /\ now <= vby
    /\ vin' = "none"
    /\ vby' = 0
    /\ disc' = Inc(disc)
    /\ vc' = "comp"
    /\ legdisc' = TRUE
    /\ UNCHANGED <<now, holder, exp, intF, intG, clF, clG, seals, dest,
                   sealedR, badCover, rec, late, gone, legab, fp, fin, fby,
                   fl, flby, fr, fd, gp, gin, gby, gl, glby,
                   gr, gd, wp, wo, wc, win, wby, wl, wlby,
                   wdest, vp, vo, vl, vlby, vdest>>

VLandAband ==
    /\ vin = "aband" /\ now <= vby
    /\ vin' = "none"
    /\ vby' = 0
    /\ clF' = (IF vo = "f" THEN Inc(clF) ELSE clF)
    /\ clG' = (IF vo = "g" THEN Inc(clG) ELSE clG)
    /\ intF' = (IF vo = "f" /\ intF = "open" THEN "aband" ELSE intF)
    /\ intG' = (IF vo = "g" /\ intG = "open" THEN "aband" ELSE intG)
    /\ vp' = "fin"
    /\ legab' = TRUE
    /\ UNCHANGED <<now, holder, exp, disc, seals, dest, sealedR, badCover, rec,
                   legdisc, late, gone, fp, fin, fby, fl, flby, fr,
                   fd, gp, gin, gby, gl, glby, gr, gd, wp,
                   wo, wc, win, wby, wl, wlby, wdest, vo, vc,
                   vl, vlby, vdest>>

\* Reconciliation 28: a call that refuses leaves the leg's remaining work to the next run.
VFail ==
    /\ vin # "none"
    /\ vin' = "none"
    /\ vby' = 0
    /\ vp' = "fin"
    /\ UNCHANGED <<now, holder, exp, intF, intG, clF, clG, disc, seals,
                   dest, sealedR, badCover, rec, legdisc, late, gone, legab, fp,
                   fin, fby, fl, flby, fr, fd, gp, gin, gby,
                   gl, glby, gr, gd, wp, wo, wc, win, wby,
                   wl, wlby, wdest, vo, vc, vl, vlby, vdest>>

VRefuse ==
    /\ vin # "none" /\ vl = "none"
    /\ vl' = vin
    /\ vlby' = vby
    /\ vin' = "none"
    /\ vby' = 0
    /\ vp' = "hold"
    /\ UNCHANGED <<now, holder, exp, intF, intG, clF, clG, disc, seals,
                   dest, sealedR, badCover, rec, legdisc, late, gone, legab, fp,
                   fin, fby, fl, flby, fr, fd, gp, gin, gby,
                   gl, glby, gr, gd, wp, wo, wc, win, wby,
                   wl, wlby, wdest, vo, vc, vdest>>

VLateSeal ==
    /\ vl = "seal" /\ now <= vlby
    /\ vl' = "none"
    /\ vlby' = 0
    /\ seals' = Inc(seals)
    /\ clF' = (IF vo = "f" THEN Inc(clF) ELSE clF)
    /\ clG' = (IF vo = "g" THEN Inc(clG) ELSE clG)
    /\ intF' = (IF vo = "f" /\ intF = "open" THEN "sealed" ELSE intF)
    /\ intG' = (IF vo = "g" /\ intG = "open" THEN "sealed" ELSE intG)
    /\ sealedR' = (IF seals = 0 THEN (IF vdest THEN "erased" ELSE IF HasPlan THEN "unsettled" ELSE "none") ELSE sealedR)
    /\ badCover' = (badCover \/ ~FromIntent)
    /\ rec' = TRUE
    /\ UNCHANGED <<now, holder, exp, disc, dest, legdisc, late, gone, legab,
                   fp, fin, fby, fl, flby, fr, fd, gp, gin,
                   gby, gl, glby, gr, gd, wp, wo, wc, win,
                   wby, wl, wlby, wdest, vp, vo, vc, vin, vby,
                   vdest>>

VLateDisc ==
    /\ vl = "disc" /\ now <= vlby
    /\ vl' = "none"
    /\ vlby' = 0
    /\ disc' = Inc(disc)
    /\ legdisc' = TRUE
    /\ UNCHANGED <<now, holder, exp, intF, intG, clF, clG, seals, dest,
                   sealedR, badCover, rec, late, gone, legab, fp, fin, fby,
                   fl, flby, fr, fd, gp, gin, gby, gl, glby,
                   gr, gd, wp, wo, wc, win, wby, wl, wlby,
                   wdest, vp, vo, vc, vin, vby, vdest>>

VLateAband ==
    /\ vl = "aband" /\ now <= vlby
    /\ vl' = "none"
    /\ vlby' = 0
    /\ clF' = (IF vo = "f" THEN Inc(clF) ELSE clF)
    /\ clG' = (IF vo = "g" THEN Inc(clG) ELSE clG)
    /\ intF' = (IF vo = "f" /\ intF = "open" THEN "aband" ELSE intF)
    /\ intG' = (IF vo = "g" /\ intG = "open" THEN "aband" ELSE intG)
    /\ UNCHANGED <<now, holder, exp, disc, seals, dest, sealedR, badCover, rec,
                   legdisc, late, gone, legab, fp, fin, fby, fl, flby,
                   fr, fd, gp, gin, gby, gl, glby, gr, gd,
                   wp, wo, wc, win, wby, wl, wlby, wdest, vp,
                   vo, vc, vin, vby, vdest>>

VLateDie ==
    /\ vl # "none"
    /\ vl' = "none"
    /\ vlby' = 0
    /\ UNCHANGED <<now, holder, exp, intF, intG, clF, clG, disc, seals,
                   dest, sealedR, badCover, rec, legdisc, late, gone, legab, fp,
                   fin, fby, fl, flby, fr, fd, gp, gin, gby,
                   gl, glby, gr, gd, wp, wo, wc, win, wby,
                   wl, wlby, wdest, vp, vo, vc, vin, vby, vdest>>

VRelease ==
    /\ (vp \in {"fin", "read"} \/ (vp = "hold" /\ ~HoldRefused))
    /\ vin = "none"
    /\ (HoldRefused => vl = "none")
    /\ holder' = (IF holder = "v" THEN "none" ELSE holder)
    /\ exp' = (IF holder = "v" THEN 0 ELSE exp)
    /\ vp' = "done"
    /\ UNCHANGED <<now, intF, intG, clF, clG, disc, seals, dest, sealedR,
                   badCover, rec, legdisc, late, gone, legab, fp, fin, fby,
                   fl, flby, fr, fd, gp, gin, gby, gl, glby,
                   gr, gd, wp, wo, wc, win, wby, wl, wlby,
                   wdest, vo, vc, vin, vby, vl, vlby, vdest>>

Next ==
    \/ Tick \/ FPre \/ FTake \/ FRead \/ FIntent \/ FPurge
    \/ FNoPlan \/ FSkip \/ FDisc \/ FSeal \/ FAband \/ FGiveUp
    \/ FLandIntent \/ FLandPurge \/ FLandDisc \/ FLandSeal \/ FLandAband \/ FFailIntent
    \/ FFailPurge \/ FStorPurge \/ FStorPurgeGone \/ FFailDisc \/ FFailSeal \/ FFailAband
    \/ FRefuseIntent \/ FRefusePurge \/ FRefuseDisc \/ FRefuseSeal \/ FRefuseAband \/ FLateIntent
    \/ FLatePurge \/ FLateDisc \/ FLateSeal \/ FLateAband \/ FLateDie \/ FRelease
    \/ GPre \/ GTake \/ GRead \/ GIntent \/ GPurge \/ GNoPlan
    \/ GSkip \/ GDisc \/ GSeal \/ GAband \/ GGiveUp \/ GLandIntent
    \/ GLandPurge \/ GLandDisc \/ GLandSeal \/ GLandAband \/ GFailIntent \/ GFailPurge
    \/ GStorPurge \/ GStorPurgeGone \/ GFailDisc \/ GFailSeal \/ GFailAband \/ GRefuseIntent
    \/ GRefusePurge \/ GRefuseDisc \/ GRefuseSeal \/ GRefuseAband \/ GLateIntent \/ GLatePurge
    \/ GLateDisc \/ GLateSeal \/ GLateAband \/ GLateDie \/ GRelease \/ WTake
    \/ WReadF \/ WReadG \/ WReadNone \/ WCompensate \/ WComplete \/ WAbandon
    \/ WLandSeal \/ WLandDisc \/ WLandAband \/ WFail \/ WRefuse \/ WLateSeal
    \/ WLateDisc \/ WLateAband \/ WLateDie \/ WRelease \/ VTake \/ VReadF
    \/ VReadG \/ VReadNone \/ VCompensate \/ VComplete \/ VAbandon \/ VLandSeal
    \/ VLandDisc \/ VLandAband \/ VFail \/ VRefuse \/ VLateSeal \/ VLateDisc
    \/ VLateAband \/ VLateDie \/ VRelease

Spec == Init /\ [][Next]_vars

\* Invariant 1.2: a request is sealed once.
Inv_OneSeal == seals <= 1
\* Invariant 1.1: no fulfilled event without its response disclosure.
Inv_NoOrphanEvent == (seals > 0) => (disc > 0)
\* Invariant 5.1: one response disclosure for a request.
Inv_OneDisclosure == disc <= 1
\* Invariant 1.5, the safety half: an intent is closed at most once.
Inv_OneClose == clF <= 1 /\ clG <= 1
\* Reconciliation 8: a request carries at most one open intent.
Inv_OneOpen == ~(intF = "open" /\ intG = "open")
\* Invariant 1.4: a disclosure with no fulfilled event has an open intent behind it.
Inv_OrphanOpen == (disc > 0 /\ seals = 0) => AnyOpen
\* A destruction a fulfillment made, seen by the store or not, is under an open intent or a sealed set, never under an abandoned one (Action wiring 19, Reconciliation 13 and 15).
Inv_Accounted == (dest \/ gone) => (AnyOpen \/ seals > 0)
\* Invariant 3.1: erased is sealed only on destruction evidence.
Inv_Evidence == (sealedR = "erased") => dest
\* Disposition 42: a planned record whose call did not settle it is never sealed retained.
Inv_Truth == ~(sealedR = "retained" /\ (dest \/ gone))
\* Invariant 2.1 and Reconciliation 16: a sealed set carries the settled record.
Inv_Cover == ~badCover

Probe_NeverRecover == ~(seals = 1 /\ rec)
Probe_NeverComplete == ~(seals = 1 /\ legdisc)
Probe_NeverAgain == ~(intF = "aband" /\ intG = "sealed")
Probe_NeverLate == ~(seals = 1 /\ late)
Probe_NeverLegAbandon == ~legab
Probe_NeverClean == ~(seals = 1 /\ ~rec /\ ~late /\ sealedR = "erased")
====
