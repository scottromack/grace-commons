-- preference-aware-notification-fanout-buggy-undeclared-skipped.als
-- BUGGY TWIN: Shaping gate 11 broken: stored quiet hours under no declared interpretation are skipped, not failed closed.
-- A copy of preference-aware-notification-fanout.als with this one defect; the harness must reject it (a check SAT).
-- Alloy structural model for the Preference-Aware Notification Fanout composition
-- (Grace Commons compositions/preference-aware-notification-fanout.md)
-- Grounded on Final Critique 18, 2026-11-06 at a342d5e — Alloy layer authored 2026-11-12.
-- Derived validator; the English spec is the single source of truth. On any
-- disagreement, diagnose per the entry *The conflict protocol* in pressure-testing.md.
--
-- PURPOSE
-- Verify, by bounded exhaustive search, the STATIC data model of the composition: what one
-- state of its records must satisfy — the initiation entries, the disposition events
-- (delivery, suppression and failure events, in line or a redisposition) with the
-- evaluation inputs they journal, the Notification records the composition created, the
-- Message Preference records and the configuration versions they are read under — and,
-- for each disposition, the shaping gate's pure verdict over what it read (the record or
-- none, the observed record status, the injected now, the delivery history or its absence,
-- the configuration). How a call moves the records from one state to the next — the two
-- writers over one disposition pair, the lease, the loop, the gap leg — is the TLA+
-- models' (preference-aware-notification-fanout.tla and -batch.tla), which own the
-- operation sequences.
--
-- RULES ENCODED (named by the page's own labels)
--   Invariant 2.1 — a subscriber the gate suppresses receives no Notification create.
--   Invariant 2.2 — a suppression the gate renders carries the first precedence rule that
--                   fired as its reason.
--   Invariant 3.1 — no delivery for a principal whose observed record's quiet hours, under
--                   the declared interpretation, contain the now.
--   Invariant 3.2 — no envelope names a channel of the statutory quiet window at a now
--                   inside the window.
--   Invariant 4.1 — every delivery event's observed in-window count falls below every cap
--                   interpreted from the observed record (a cross-check with the TLA+ model).
--   Invariant 5.1, 5.2 — every suppression event carries its reason, preference id,
--                   evaluation inputs and retry eligibility; every failure event its cause
--                   and preference id (the TLA+ model reads that the event exists).
--   Invariant 7.1 — every verdict-bearing event replays to its recorded verdict PER Verdict
--                   replay 1 through 4.
--   Invariant 8.1 — every created record's content digests to the initiation entry's payload
--                   digest (a cross-check with the TLA+ model).
--   Composition state 15 — every preference id a disposition event carries names the record
--                   in effect at the event's decided instant (Check 3.2).
--   Shaping gate 10 — no history entry naming another channel counts toward a
--                   channel-scoped pair.
--   Shaping gate 19 — no deliver verdict on a fail-closed cause.
--   Action wiring 33, 34 — the retry eligibility is true only under a hold policy, and false
--                   for an action-relented reason.
--   Capability requirement 29 — the composition starts only where the reconciliation window
--                   exceeds the liveness sum.
--   The gate's walk (Shaping gate 1 through 9, 11 through 18, 20, 21) is the writer's rule
--   these checks read; Verdict replay 1 through 4 define the replay of Invariant 7.1.
--
-- NOT CHECKED HERE
--   Nothing testable in Alloy: Invariant 4.3 and Composition state 12 with Check 1.1 (each
--   an eventuality inside the reconciliation window, counted from an instant: a property
--   across steps, the TLA+ model's to state); Verdict replay 5 (an auditor's attribution of
--   a divergence, not a record); Primitive policy 1 through 13 (a refused call writes
--   nothing, Execution Contract Read 4, so no state holds one; byte-exact comparison and
--   the payload cap are below the model's atoms); Shaping gate 22 (a record change the read
--   did not see is a second state).
--   Left to the TLA+ models: Invariant 1.1, 1.2 (the invocation's answer is its loop's),
--   4.2 (the count of the preceding delivery events, an order), 9.1 (a live record across a
--   redisposition, an order), 10.1 and 10.2 (the seam's one fanout id, and an order).
--
-- READING TAKEN (see FOUND)
--   The gate of a disposition, in line or a redisposition, evaluates under the configuration
--   version the initiation entry journaled: the only version Verdict replay 4 reads, and no
--   disposition event journals another.
--   The preference read answers the record in effect at the call's now (Message
--   Preference's current_for); the model has no clock between the seam and the read.
--
-- FOUND (recorded, not cured; see the Ledger's formal line)
--   1. Shaping gate 11 and 12 are not ordered: a record carrying a frequency limit whose
--      interpretation is undeclared, read while the delivery history is unavailable, owes
--      fail carrying interpretation-undeclared and fail carrying accounting-unreadable at
--      once, where Shaping gate 1 owes exactly one verdict. The model admits either cause
--      (run ShowFailCauseUnordered).
--   2. Action wiring 18 and 54 run the gate on "the configuration" without naming its
--      version, and a disposition event journals none (Action wiring 22, 27, 29), while
--      Verdict replay 4 replays under the version the initiation entry journaled: a
--      [Redispose] after a configuration change that evaluates under the version then in
--      force fails Invariant 7.1 though every rule was kept. The model takes the reading
--      above (run ShowRedisposeAfterNewVersion).
--
-- SCOPE
-- One state: up to three each of principals, channels, instants, preference records,
-- window-and-cap pairs, delivery count entries, contents and digests, Notification records,
-- initiation entries, configuration versions and disposition events; Int at 4 bits
-- (counts and caps up to 3, the five durations of the liveness check at most 1 each, the
-- window at most 7). Each disposition event is what its writer's rules let it write over
-- what the call read: the model builds every state whose every event passes its writer's
-- rule. No trace, no `var`, no stepping.
--
-- NOT MODELED HERE
--   - The format: the channel interpretation maps a stored format to the envelope's, and no
--     rule checked here reads it.
--   - The interpretations' arithmetic: which nows a stored quiet hours value or a pair's
--     window holds is the deployment's declared rule (Capability requirement 1 through 3,
--     6), taken here as a relation, one answer per stored value and now.
--   - The derived indexes' upkeep (Composition state 4 through 9): the gate's history input
--     is the principal's delivery count entries as the gate read them.
--   - The reconciliation records (reconcile intent, abandonment, overshoot): their order and
--     their window are the TLA+ model's, and no check here reads them.
--
-- HOW TO READ RESULTS
-- Every "check A_*" must return "No counterexample found" (UNSAT) — the asserted guarantee holds.
-- Every "run Show*" must return at least one instance (SAT) — confirms non-vacuity.
-- A "check" returning a counterexample is a spec finding.

module preference_aware_notification_fanout_buggy_undeclared_skipped

-- ─────────────────────────────────────────────────────────────────────────────
-- Signatures (types)
-- ─────────────────────────────────────────────────────────────────────────────

-- Yes: a flag's one value; a field `lone Yes` reads as true when present.
one sig Yes {}

-- Bool: the two values of a suppression event's retry eligibility (Term retry eligibility).
abstract sig Bool {}
one sig True, False extends Bool {}

-- Channel: a delivery channel the channel interpretation can name.
sig Channel {}

-- Instant: a now the host injects at the seam (Term now). Which instants a window holds is
-- the deployment's interpretation, so instants carry no order of their own here.
sig Instant {}

-- Digest: a value of the payload digest function.
sig Digest {}

-- Content: a payload content, with its digest under the deployment's deterministic payload
-- digest function (Capability requirement 20).
sig Content {
    dig : one Digest
}

-- Principal: a principal reference, with Message Preference's answer to current_for at each
-- instant: the record in effect then, or none.
sig Principal {
    inEffect : Instant -> lone Pref
}

-- Pref: one Message Preference record — its principal and which of the interpreted fields it
-- carries (Term interpreted field); its values are immutable, read through the configuration.
sig Pref {
    powner : one Principal,
    hasQuiet : lone Yes,
    hasFreq : lone Yes,
    hasChan : lone Yes
}

-- Pair: one window-and-cap pair the frequency limit interpretation reads from a stored
-- frequency limit — its cap, the channel it is scoped to if any, and for each now the
-- instants its window holds (rolling or calendar-aligned alike).
sig Pair {
    cap : one Int,
    scope : lone Channel,
    win : Instant -> Instant
}

-- Config: one configuration version (Term configuration version): each interpretation with
-- whether the deployment declared it, the default shape's channel set, the statutory quiet
-- window (its instants and channels), the no record policy (suppress when present), and
-- the cap and quiet window policies (hold when present).
sig Config {
    quietDecl : lone Yes,
    quietIn : Pref -> Instant,
    freqDecl : lone Yes,
    freqPairs : Pref -> Pair,
    chanDecl : lone Yes,
    chanSet : Pref -> Channel,
    defChans : set Channel,
    statAt : set Instant,
    statChans : set Channel,
    noRecSuppress : lone Yes,
    capHold : lone Yes,
    quietHold : lone Yes
}

-- Entry: one delivery count entry — the principal it is keyed by, the decided instant and
-- the channels of one of the principal's delivery events (Composition state 2, 3).
sig Entry {
    ekey : one Principal,
    at : one Instant,
    chans : set Channel
}

-- NRec: one Notification record — its recipient and the envelope it carries (the payload
-- content and the channels; Term envelope).
sig NRec {
    recipient : one Principal,
    content : one Content,
    nchans : set Channel
}

-- Init: one initiation entry — the configuration version, the payload digest, the queried
-- list and the fired instant it journals (Action wiring 5); content is the invocation's
-- payload content, which the journal does not hold (Non-goal 10).
sig Init {
    cfg : one Config,
    digest : one Digest,
    queried : set Principal,
    fired : one Instant,
    content : one Content
}

-- Obs: the observed record status (Term observed record status).
abstract sig Obs {}
one sig OActive, OSuspended, ONone extends Obs {}

-- Kind: the verdict's three forms (Term verdict).
abstract sig Kind {}
one sig Deliver, Suppress, Fail extends Kind {}

-- Reason: the suppression reasons (Term suppression reason).
abstract sig Reason {}
one sig RSuspended, RNoRecord, RQuiet, RCap, ROptOut, RUnsub extends Reason {}

-- Cause: the failure causes (Term failure cause).
abstract sig Cause {}
one sig CPrefUnreadable, CAcctUnreadable, CUndeclared, CCreateFailed extends Cause {}

-- EType: the three disposition event types (Term disposition event).
abstract sig EType {}
one sig EDelivery, ESuppress, EFail extends EType {}

-- Disp: one disposition event with the call that wrote it. The call: the invocation it
-- names, the principal, the decided instant, the payload content the call carried, whether
-- it is a redisposition, and what the outside answered it (the audience re-check found the
-- principal not subscribed, the preference read failed, the delivery history was
-- unavailable, Notification refused the create). The gate's run (g*): when the preference
-- read was made and what it answered, the observed status, the now, the configuration, the
-- history and the counts, and the verdict (v*). The record created (made). The event as
-- journaled: its type, reason, cause, preference id (pslot, or prefNone for none), the
-- evaluation inputs (i*), the retry eligibility, the notification id and the channels.
sig Disp {
    fanout : one Init,
    who : one Principal,
    decided : one Instant,
    payload : one Content,
    redispo : lone Yes,
    audOut : lone Yes,
    prefFail : lone Yes,
    histUnavail : lone Yes,
    createRefused : lone Yes,
    gReadAt : lone Instant,
    gRec : lone Pref,
    gObs : lone Obs,
    gNow : lone Instant,
    gCfg : lone Config,
    gHist : set Entry,
    gCounts : Pair -> Int,
    vKind : lone Kind,
    vReason : lone Reason,
    vCause : lone Cause,
    vChans : set Channel,
    made : lone NRec,
    etype : one EType,
    reason : lone Reason,
    cause : lone Cause,
    pslot : lone Pref,
    prefNone : lone Yes,
    iObs : lone Obs,
    iNow : lone Instant,
    iCounts : Pair -> Int,
    iAud : lone Yes,
    retry : lone Bool,
    notif : lone NRec,
    echans : set Channel
}

-- Deploy: the deployment's start — whether the composition started, and the durations the
-- start compares: the reconciliation window, the invocation duration bound, the
-- notification create latency, the reconciliation cadence and the reconciliation run bound.
one sig Deploy {
    started : lone Yes,
    window : one Int,
    invBound : one Int,
    createLat : one Int,
    cadence : one Int,
    runBound : one Int
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Facts: only what the page takes from outside
-- ─────────────────────────────────────────────────────────────────────────────

-- Message Preference answers current_for with a record of the principal asked about.
fact PreferenceRecords {
    all p : Principal, t : Instant | p.inEffect[t] in powner.p
}

-- The preference read, where it is made and answers, answers the record in effect at the
-- read, and the status it observed on it (active or suspended), or none and the none
-- status; where no read was made, nothing was answered.
fact PreferenceRead {
    all d : Disp | some d.gReadAt implies {
        d.gRec = d.who.inEffect[d.gReadAt]
        one d.gObs
        d.gObs = ONone iff no d.gRec
    }
    all d : Disp | no d.gReadAt implies (no d.gRec and no d.gObs)
}

-- The frequency limit interpretation reads caps that are not negative.
fact InterpretedCaps {
    all p : Pair | p.cap >= 0
}

-- The deployment's durations are not negative; the scope bounds the four addends of the
-- liveness sum to 0 or 1 so the sum stays inside 4-bit Int.
fact DeploymentDurations {
    Deploy.window >= 0
    Deploy.invBound >= 0 and Deploy.invBound <= 1
    Deploy.createLat >= 0 and Deploy.createLat <= 1
    Deploy.cadence >= 0 and Deploy.cadence <= 1
    Deploy.runBound >= 0 and Deploy.runBound <= 1
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Helpers
-- ─────────────────────────────────────────────────────────────────────────────

-- pairsOf: the window-and-cap pairs the frequency limit interpretation reads from a record
-- that carries a frequency limit; none for a record without one, or no record.
fun pairsOf[r : lone Pref, c : Config] : set Pair {
    (some r.hasFreq) => r.(c.freqPairs) else none
}

-- base: the channel set channel selection starts from — the stated channel preferences
-- under the channel interpretation, or the default shape's set where the record carries
-- none or there is no record (Shaping gate 7, 13, 14).
fun base[r : lone Pref, c : Config] : set Channel {
    (some r.hasChan) => r.(c.chanSet) else c.defChans
}

-- statOut: the channels the statutory quiet window excludes at a now (Shaping gate 15).
fun statOut[n : lone Instant, c : Config] : set Channel {
    (some n and n in c.statAt) => c.statChans else none
}

-- countOf: a pair's in-window count over a history at a now — the entries inside the
-- pair's window, a channel-scoped pair counting only entries naming its channel (Shaping
-- gate 10).
fun countOf[h : set Entry, p : Pair, n : Instant] : Int {
    #{ e : h | e.at in n.(p.win) and (no p.scope or p.scope in e.chans) }
}

-- countsFor: each pair with its in-window count.
fun countsFor[h : set Entry, ps : set Pair, n : Instant] : Pair -> Int {
    { p : ps, i : Int | i = countOf[h, p, n] }
}

-- covers: the counts give one count for every interpreted pair (the cap rule's input).
pred covers[r : lone Pref, c : Config, cnt : Pair -> Int] {
    all p : pairsOf[r, c] | one cnt[p]
}

-- capHit: an interpreted pair's cap does not exceed its in-window count (Shaping gate 9).
pred capHit[r : lone Pref, c : Config, cnt : Pair -> Int] {
    some p : pairsOf[r, c] | p.cap <= cnt[p]
}

-- suppressWith: the verdict suppress carrying one reason.
pred suppressWith[k : lone Kind, rs : lone Reason, cs : lone Cause, ch : set Channel, why : Reason] {
    k = Suppress and rs = why and no cs and no ch
}

-- failWith: the verdict fail carrying one of the causes given.
pred failWith[k : lone Kind, rs : lone Reason, cs : lone Cause, ch : set Channel, why : set Cause] {
    k = Fail and no rs and one cs and cs in why and no ch
}

-- deliverWith: the verdict deliver carrying a channel set.
pred deliverWith[k : lone Kind, rs : lone Reason, cs : lone Cause, ch : set Channel, out : set Channel] {
    k = Deliver and no rs and no cs and ch = out
}

-- ruleV: channel selection (rule v): fail where the stated channel preferences have no
-- declared interpretation (Shaping gate 11); suppress channel-opt-out where the preference
-- values emptied the set (Shaping gate 17); suppress quiet-window where the statutory
-- exclusion emptied a set they left non-empty (Shaping gate 15, 18); else deliver the set
-- less the statutory exclusion (Shaping gate 16).
pred ruleV[r : lone Pref, n : Instant, c : Config, k : lone Kind, rs : lone Reason, cs : lone Cause, ch : set Channel] {
    (some r.hasChan and no c.chanDecl) => failWith[k, rs, cs, ch, CUndeclared]
    else (no base[r, c]) => suppressWith[k, rs, cs, ch, ROptOut]
    else (no (base[r, c] - statOut[n, c])) => suppressWith[k, rs, cs, ch, RQuiet]
    else deliverWith[k, rs, cs, ch, base[r, c] - statOut[n, c]]
}

-- gate: the shaping gate, a pure function of the record or none, the observed status, the
-- now, the counts (or the unavailable marker) and the configuration — one verdict per
-- disposition (Shaping gate 1, 20), the precedence rules in their declared order (Shaping
-- gate 2, 21), stopping at the first that fires (Shaping gate 3) and skipping a rule whose
-- input the record does not carry (Shaping gate 4): rule i suspended (Shaping gate 5), rule
-- ii no-record (Shaping gate 6, 7), rule iii quiet hours (Shaping gate 8, 11), rule iv the
-- cap (Shaping gate 9, 11, 12), rule v channel selection.
pred gate[r : lone Pref, o : lone Obs, n : lone Instant, cnt : Pair -> Int, un : lone Yes, c : lone Config,
          k : lone Kind, rs : lone Reason, cs : lone Cause, ch : set Channel] {
    one o and one n and one c
    (some r and o = OSuspended) => suppressWith[k, rs, cs, ch, RSuspended]
    else (no r and some c.noRecSuppress) => suppressWith[k, rs, cs, ch, RNoRecord]
    else (some r.hasQuiet and some c.quietDecl and n in r.(c.quietIn)) => suppressWith[k, rs, cs, ch, RQuiet]   -- BUG: Shaping gate 11 skipped
    else (some r.hasFreq and (no c.freqDecl or some un)) =>
        failWith[k, rs, cs, ch, ((no c.freqDecl) => CUndeclared else none) + ((some un) => CAcctUnreadable else none)]
    else (some r.hasFreq) =>
        (covers[r, c, cnt] and (capHit[r, c, cnt] => suppressWith[k, rs, cs, ch, RCap] else ruleV[r, n, c, k, rs, cs, ch]))
    else ruleV[r, n, c, k, rs, cs, ch]
}

-- retryFor: the retry eligibility a suppression carries — true where the reason's policy is
-- hold (the quiet window policy for quiet-window, the cap policy for frequency-cap), false
-- otherwise (Action wiring 33, 34; Term retry eligibility).
fun retryFor[rs : lone Reason, c : Config] : Bool {
    ((rs = RQuiet and some c.quietHold) or (rs = RCap and some c.capHold)) => True else False
}

-- liveSum: the liveness sum (Term liveness sum).
fun liveSum : Int {
    plus[plus[plus[Deploy.invBound, Deploy.createLat], Deploy.cadence], Deploy.runBound]
}

-- ─────────────────────────────────────────────────────────────────────────────
-- The writers: what each record may be, over what its call read
-- ─────────────────────────────────────────────────────────────────────────────

-- startWrites: the composition starts only where the reconciliation window exceeds the
-- liveness sum and the default shape's channel set is not blank (Capability requirement 5,
-- 29), and nothing is written before it starts.
pred startWrites {
    some Deploy.started implies {
        Deploy.window > liveSum                                     -- Capability requirement 29
        all c : Config | some c.defChans                            -- Capability requirement 5
    }
    some Init implies some Deploy.started
}

-- initWrites: an initiation entry journals the digest of the invocation's payload content
-- (Action wiring 5).
pred initWrites[i : Init] {
    i.digest = i.content.dig
}

-- dispWrites: one disposition event and the call that wrote it.
pred dispWrites[d : Disp] {
    d.who in d.fanout.queried                                       -- Action wiring 8, 47
    no d.redispo implies {
        d.decided = d.fanout.fired                                  -- Capability requirement 44
        d.payload = d.fanout.content                                -- the invocation's payload
    }
    some d.redispo implies d.payload.dig = d.fanout.digest         -- Action wiring 40
    some d.audOut implies some d.redispo                            -- Action wiring 52, 53
    -- The audience re-check answered not-subscribed: a suppression carrying unsubscribed,
    -- false, none and the audience check with the now (Action wiring 53); no gate.
    some d.audOut implies {
        no d.gReadAt and no d.gNow and no d.gCfg and no d.vKind and no d.made
        no d.createRefused and no d.histUnavail and no d.gHist and no d.gCounts
        no d.vReason and no d.vCause and no d.vChans
        d.etype = ESuppress and d.reason = RUnsub and d.retry = False
        no d.pslot and some d.prefNone
        some d.iAud and d.iNow = d.decided and no d.iObs and no d.iCounts
        no d.cause and no d.notif and no d.echans
    }
    -- The preference read failed: a failure event carrying preference-unreadable, the gate
    -- not run (Action wiring 16, 17, 27).
    (no d.audOut and some d.prefFail) implies {
        no d.gReadAt and no d.gNow and no d.gCfg and no d.vKind and no d.made
        no d.createRefused and no d.histUnavail and no d.gHist and no d.gCounts
        no d.vReason and no d.vCause and no d.vChans
        d.etype = EFail and d.cause = CPrefUnreadable
        no d.pslot and some d.prefNone
        no d.reason and no d.retry and no d.iObs and no d.iNow and no d.iCounts and no d.iAud
        no d.notif and no d.echans
    }
    -- The gate ran: on the record read at the call's now (Action wiring 15, Staleness 1, 2),
    -- the injected now (Action wiring 18, Capability requirement 45), the initiation
    -- entry's configuration version (the reading Verdict replay 4 needs), the principal's
    -- delivery count entries (Composition state 2) counted per pair (Shaping gate 10).
    (no d.audOut and no d.prefFail) implies {
        d.gReadAt = d.decided                                       -- Staleness 1, 2
        d.gNow = d.decided                                          -- Capability requirement 45
        d.gCfg = d.fanout.cfg                                       -- the reading (Verdict replay 4)
        d.gHist.ekey in d.who                                      -- Composition state 2
        d.gCounts = ((some d.histUnavail) => none -> none
                     else countsFor[d.gHist, pairsOf[d.gRec, d.gCfg], d.gNow])
        gate[d.gRec, d.gObs, d.gNow, d.gCounts, d.histUnavail, d.gCfg, d.vKind, d.vReason, d.vCause, d.vChans]
        d.pslot = d.gRec                                            -- Action wiring 22, 27, 29
        no d.gRec iff some d.prefNone
        d.vKind != Deliver implies (no d.made and no d.createRefused)   -- Wiring decision 2
        (d.vKind = Deliver and no d.createRefused) implies {
            one d.made                                              -- Action wiring 19
            d.made.recipient = d.who and d.made.content = d.payload and d.made.nchans = d.vChans  -- Action wiring 20
            d.etype = EDelivery and d.notif = d.made and d.echans = d.vChans   -- Action wiring 21, 22
            d.iObs = d.gObs and d.iNow = d.decided and d.iCounts = d.gCounts   -- Action wiring 31
            no d.reason and no d.cause and no d.retry and no d.iAud
        }
        (d.vKind = Deliver and some d.createRefused) implies {
            no d.made                                               -- Notification's refusal writes nothing
            d.etype = EFail and d.cause = CCreateFailed             -- Action wiring 26
            no d.reason and no d.retry and no d.notif and no d.echans
            no d.iObs and no d.iNow and no d.iCounts and no d.iAud
        }
        d.vKind = Suppress implies {
            d.etype = ESuppress and d.reason = d.vReason            -- Action wiring 29
            d.iObs = d.gObs and d.iNow = d.decided and d.iCounts = d.gCounts   -- Action wiring 32, 61
            d.retry = retryFor[d.vReason, d.gCfg]                  -- Action wiring 33, 34
            no d.cause and no d.notif and no d.echans and no d.iAud
        }
        d.vKind = Fail implies {
            d.etype = EFail and d.cause = d.vCause                  -- Action wiring 28
            no d.reason and no d.retry and no d.notif and no d.echans
            no d.iObs and no d.iNow and no d.iCounts and no d.iAud
        }
    }
}

-- conforms: every record in the state is one its writer's rules let it write.
pred conforms {
    startWrites
    all i : Init | initWrites[i]
    all d : Disp | dispWrites[d]
}

-- firstReason: the reason of the first precedence rule that fires on the gate's inputs —
-- each rule read alone, in the declared order (Term precedence rules): rule i suspended,
-- rule ii no-record, rule iii the quiet window under its declared interpretation, rule iv a
-- cap reached under its declared interpretation, rule v the set emptied by the preference
-- values (channel-opt-out) or by the statutory exclusion (quiet-window).
fun firstReason[r : lone Pref, o : lone Obs, n : lone Instant, cnt : Pair -> Int, c : lone Config] : lone Reason {
    (some r and o = OSuspended) => RSuspended
    else (no r and some c.noRecSuppress) => RNoRecord
    else (some r.hasQuiet and some c.quietDecl and n in r.(c.quietIn)) => RQuiet
    else (some r.hasFreq and some c.freqDecl and (some p : pairsOf[r, c] | one cnt[p] and p.cap <= cnt[p])) => RCap
    else (no base[r, c]) => ROptOut
    else (no (base[r, c] - statOut[n, c])) => RQuiet
    else none
}

-- recordedKind: the verdict a verdict-bearing event records — deliver for a delivery event,
-- suppress for a suppression event.
fun recordedKind[d : Disp] : Kind {
    (d.etype = EDelivery) => Deliver else Suppress
}

-- replays: re-evaluating the gate on the event's recorded inputs reproduces its recorded
-- verdict — the preference values read by the event's preference id or the absence the gate
-- saw (Verdict replay 2), the observed status, the now and the in-window counts from the
-- evaluation inputs (Verdict replay 3), under the configuration version the initiation entry
-- journaled (Verdict replay 4), the history available (Verdict replay 1).
pred replays[d : Disp] {
    one d.iObs and one d.iNow
    gate[d.pslot, d.iObs, d.iNow, d.iCounts, none, d.fanout.cfg, recordedKind[d], d.reason, none, d.echans]
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Assertions (verified guarantees)
-- Each "check" asks: is there any state the composition's writers can leave that violates
-- this assertion? No counterexample (UNSAT) = the guarantee holds within scope.
-- ─────────────────────────────────────────────────────────────────────────────

-- A_Invariant_2_1: a subscriber the shaping gate suppresses receives no Notification create
-- in the disposition.
assert A_Invariant_2_1 {
    conforms implies all d : Disp | d.vKind = Suppress implies no d.made
}
check A_Invariant_2_1 for 3 but 4 Int

-- A_Invariant_2_2: a suppression event the gate renders carries the first precedence rule
-- that fired as its reason.
assert A_Invariant_2_2 {
    conforms implies all d : Disp | (some d.vKind and d.etype = ESuppress) implies
        d.reason = firstReason[d.gRec, d.gObs, d.gNow, d.gCounts, d.gCfg]
}
check A_Invariant_2_2 for 3 but 4 Int

-- A_Invariant_3_1: no delivery event for a principal whose observed record carries quiet
-- hours that the declared quiet hours interpretation reads as containing the decided now.
assert A_Invariant_3_1 {
    conforms implies all d : Disp |
        (d.etype = EDelivery and some d.fanout.cfg.quietDecl and some d.pslot.hasQuiet) implies
            d.decided not in d.pslot.(d.fanout.cfg.quietIn)
}
check A_Invariant_3_1 for 3 but 4 Int

-- A_Invariant_3_2: no committed envelope names a channel of the statutory quiet window at a
-- now inside the window.
assert A_Invariant_3_2 {
    conforms implies all d : Disp | (d.etype = EDelivery and d.decided in d.fanout.cfg.statAt) implies
        no (d.notif.nchans & d.fanout.cfg.statChans)
}
check A_Invariant_3_2 for 3 but 4 Int

-- A_Invariant_4_1: under a declared frequency limit interpretation, every delivery event
-- carries, for every pair interpreted from the observed record, an observed in-window count
-- below the pair's cap.
assert A_Invariant_4_1 {
    conforms implies all d : Disp |
        (d.etype = EDelivery and some d.fanout.cfg.freqDecl and some d.pslot.hasFreq) implies
            all p : d.pslot.(d.fanout.cfg.freqPairs) | one d.iCounts[p] and d.iCounts[p] < p.cap
}
check A_Invariant_4_1 for 3 but 4 Int

-- A_Invariant_5_1: every suppression event carries a reason, a preference id or none, the
-- evaluation inputs (the now, with the observed status or the audience check) and the retry
-- eligibility.
assert A_Invariant_5_1 {
    conforms implies all d : Disp | d.etype = ESuppress implies {
        one d.reason
        one d.pslot or some d.prefNone
        one d.iNow
        one d.iObs or some d.iAud
        one d.retry
    }
}
check A_Invariant_5_1 for 3 but 4 Int

-- A_Invariant_5_2: every failure event carries a failure cause and a preference id or none.
assert A_Invariant_5_2 {
    conforms implies all d : Disp | d.etype = EFail implies {
        one d.cause
        one d.pslot or some d.prefNone
    }
}
check A_Invariant_5_2 for 3 but 4 Int

-- A_Invariant_7_1: every verdict-bearing event (a delivery event, or a suppression event
-- whose reason is not unsubscribed) replays to its recorded verdict.
assert A_Invariant_7_1 {
    conforms implies all d : Disp |
        (d.etype = EDelivery or (d.etype = ESuppress and d.reason != RUnsub)) implies replays[d]
}
check A_Invariant_7_1 for 3 but 4 Int

-- A_Invariant_8_1: every Notification record a disposition created carries content that
-- digests to the initiation entry's payload digest (Check 6.1).
assert A_Invariant_8_1 {
    conforms implies all d : Disp | some d.made implies d.made.content.dig = d.fanout.digest
}
check A_Invariant_8_1 for 3 but 4 Int

-- A_Composition_state_15: every preference id a disposition event carries names the record
-- in effect for its principal at the event's decided instant.
assert A_Composition_state_15 {
    conforms implies all d : Disp | some d.pslot implies d.pslot = d.who.inEffect[d.decided]
}
check A_Composition_state_15 for 3 but 4 Int

-- A_Shaping_gate_10: a channel-scoped pair's count holds no history entry that does not name
-- the pair's channel.
assert A_Shaping_gate_10 {
    conforms implies all d : Disp, p : Pair | (one d.gCounts[p] and some p.scope) implies
        d.gCounts[p] <= #{ e : d.gHist | e.at in d.gNow.(p.win) and p.scope in e.chans }
}
check A_Shaping_gate_10 for 3 but 4 Int

-- A_Shaping_gate_19: the gate never answers deliver past a fail-closed cause — every rule a
-- deliver reached that consults a field had its interpretation declared, and the cap rule
-- had the delivery history.
assert A_Shaping_gate_19 {
    conforms implies all d : Disp | d.vKind = Deliver implies {
        some d.gRec.hasQuiet implies some d.gCfg.quietDecl
        some d.gRec.hasFreq implies (some d.gCfg.freqDecl and no d.histUnavail)
        some d.gRec.hasChan implies some d.gCfg.chanDecl
    }
}
check A_Shaping_gate_19 for 3 but 4 Int

-- A_Action_wiring_33_34: a suppression event carries true as the retry eligibility only
-- where the reason's policy is hold, and false for an action-relented reason.
assert A_Action_wiring_33_34 {
    conforms implies all d : Disp | d.etype = ESuppress implies {
        d.retry = True implies
            ((d.reason = RQuiet and some d.fanout.cfg.quietHold) or (d.reason = RCap and some d.fanout.cfg.capHold))
        d.reason in RSuspended + RNoRecord + ROptOut + RUnsub implies d.retry = False
    }
}
check A_Action_wiring_33_34 for 3 but 4 Int

-- A_Capability_requirement_29: the composition started only where the reconciliation window
-- exceeds the invocation duration bound, the create latency, the cadence and the run bound
-- summed.
assert A_Capability_requirement_29 {
    conforms implies (some Deploy.started implies
        Deploy.window > plus[plus[plus[Deploy.invBound, Deploy.createLat], Deploy.cadence], Deploy.runBound])
}
check A_Capability_requirement_29 for 3 but 4 Int

-- ─────────────────────────────────────────────────────────────────────────────
-- Satisfiability runs — non-vacuity guards, one for each shape the page admits
-- Each run must find at least one instance (SAT).
-- UNSAT means the model forbids a state the page admits.
-- ─────────────────────────────────────────────────────────────────────────────

-- ShowDeliverShaped: ana — an active record whose stated channel preferences select a set;
-- the create and its delivery event.
run ShowDeliverShaped {
    conforms
    some d : Disp | d.etype = EDelivery and some d.pslot.hasChan and d.gObs = OActive and some d.echans
} for 3 but 4 Int

-- ShowDeliverUnshaped: dia — no record under deliver-unshaped; the default shape delivers,
-- the event carrying none as its preference id.
run ShowDeliverUnshaped {
    conforms
    some d : Disp | d.etype = EDelivery and no d.pslot and some d.prefNone
} for 3 but 4 Int

-- ShowSuspended: ben — a suspended record suppressed as suspended, though it carries quiet
-- hours the now is inside (precedence).
run ShowSuspended {
    conforms
    some d : Disp | d.reason = RSuspended and some d.pslot.hasQuiet and d.decided in d.pslot.(d.gCfg.quietIn)
} for 3 but 4 Int

-- ShowQuietHold: cho — the stored quiet window contains the now; suppressed quiet-window,
-- retry-eligible under the hold policy.
run ShowQuietHold {
    conforms
    some d : Disp | d.reason = RQuiet and some d.pslot.hasQuiet and d.retry = True
} for 3 but 4 Int

-- ShowCapSuppress: eli — an in-window count at the cap; suppressed frequency-cap, not
-- retry-eligible under the drop policy.
run ShowCapSuppress {
    conforms
    some d : Disp | d.reason = RCap and d.retry = False and some d.gHist
} for 3 but 4 Int

-- ShowStatutoryQuiet: finn — no stored quiet hours; the statutory window empties the
-- selected set and the suppression reads quiet-window.
run ShowStatutoryQuiet {
    conforms
    some d : Disp | d.reason = RQuiet and some d.pslot and no d.pslot.hasQuiet
} for 3 but 4 Int

-- ShowChannelOptOut: gus — stated channel preferences interpreted to no channel.
run ShowChannelOptOut {
    conforms
    some d : Disp | d.reason = ROptOut and some d.pslot
} for 3 but 4 Int

-- ShowNoRecordSuppress: hana — no record under the suppress policy.
run ShowNoRecordSuppress {
    conforms
    some d : Disp | d.reason = RNoRecord and some d.prefNone
} for 3 but 4 Int

-- ShowPreferenceUnreadable: the preference-record outage — a failure carrying
-- preference-unreadable, the gate not run.
run ShowPreferenceUnreadable {
    conforms
    some d : Disp | d.cause = CPrefUnreadable
} for 3 but 4 Int

-- ShowAccountingUnreadable: a cap-carrying record under a declared interpretation whose
-- history is unavailable fails with accounting-unreadable.
run ShowAccountingUnreadable {
    conforms
    some d : Disp | d.cause = CAcctUnreadable and some d.gCfg.freqDecl
} for 3 but 4 Int

-- ShowInterpretationUndeclared: a record carrying quiet hours under no declared quiet hours
-- interpretation fails with interpretation-undeclared.
run ShowInterpretationUndeclared {
    conforms
    some d : Disp | d.cause = CUndeclared and some d.gRec.hasQuiet and no d.gCfg.quietDecl
} for 3 but 4 Int

-- ShowCreateFailed: eli in the partial failure — Notification refuses the create, a failure
-- event carries create-failed, no record exists.
run ShowCreateFailed {
    conforms
    some d : Disp | d.cause = CCreateFailed
} for 3 but 4 Int

-- ShowRedisposeDelivers: cho's retry — a suppression in line, then a redisposition under the
-- same fanout id with a fresh now that delivers.
run ShowRedisposeDelivers {
    conforms
    some d1, d2 : Disp {
        d1.fanout = d2.fanout and d1.who = d2.who
        no d1.redispo and d1.reason = RQuiet
        some d2.redispo and d2.etype = EDelivery and d2.decided != d1.decided
    }
} for 3 but 4 Int

-- ShowRedisposeUnsubscribed: a principal who left the audience before the retry; the
-- redisposition journals unsubscribed.
run ShowRedisposeUnsubscribed {
    conforms
    some d : Disp | d.reason = RUnsub
} for 3 but 4 Int

-- ShowScopedPair: a channel-scoped pair does not count an in-window entry naming another
-- channel, and the delivery goes ahead.
run ShowScopedPair {
    conforms
    some d : Disp, p : Pair, e : Entry {
        d.etype = EDelivery and some p.scope and one d.gCounts[p]
        e in d.gHist and e.at in d.gNow.(p.win) and p.scope not in e.chans
    }
} for 3 but 4 Int

-- ShowFailCauseUnordered: (FOUND 1) a cap-carrying record under no declared frequency limit
-- interpretation, read while the history is unavailable — Shaping gate 11 and 12 both
-- apply, and the event carries accounting-unreadable.
run ShowFailCauseUnordered {
    conforms
    some d : Disp | d.cause = CAcctUnreadable and no d.gCfg.freqDecl and some d.histUnavail
} for 3 but 4 Int

-- ShowRedisposeAfterNewVersion: (FOUND 2) a redisposition whose gate runs under the
-- initiation entry's configuration version while another version exists.
run ShowRedisposeAfterNewVersion {
    conforms
    some d : Disp, c : Config | some d.redispo and some d.vKind and c != d.fanout.cfg
} for 3 but 4 Int
