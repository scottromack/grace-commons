-- immutable-ledger.als
-- Alloy structural model for the Immutable Ledger with Selective Disclosure composition (Grace Commons compositions/immutable-ledger.md)
-- Grounded on Final Critique 20, 2026-11-06 at 13edae6 — Alloy layer authored 2026-11-12.
-- Derived validator; the English spec is the single source of truth. On any
-- disagreement, diagnose per the entry *The conflict protocol* in pressure-testing.md.
--
-- PURPOSE
-- Verify, by bounded exhaustive search, the STATIC data model of the composition: what one
-- state of its records must satisfy — the ledger's intents and the closings Recoverable
-- Invocation writes for the act kind (outcome events, refusals, abandonments, escalations),
-- the accounting records Selective Disclosure keeps, the binding index, and the
-- reconciliation's write-ownership findings and alerts — whatever admitted writes left it,
-- and what the page's reads answer over that state: the disclosure probe, [Verify Ledger]'s
-- binding verdict, the disclosed set a reissue reads, the presentation a bound verification
-- passes, and the class Check 1.2 puts each unbound record in. The order of the writes, the
-- reconciliation's runs, the horizon arithmetic and every eventuality are the three TLA+
-- models' (immutable-ledger.tla, -rebuild.tla, -reconcile.tla), which own the operation
-- sequences.
--
-- The model has two parts.
--   Part A, the records: every record is what an admitted write left — the invocation open's
--   intent (Action wiring 3, Term intent data), the disclosure write's accounting record
--   (Action wiring 6), the invocation close's outcome event (Action wiring 53, Term outcome
--   data), the sweep's or an operator's recovered outcome (Recoverable Invocation's, through
--   this page's disclosure probe and outcome data), a refusal, an abandonment, an escalation,
--   the binding index's entries (Composition state 2 through 4, 18; Action wiring 16), and the
--   last reconciliation run's findings and alerts (Reconciliation 14, 33). A record no
--   intent's commit answered is one a deployment wrote outside the composition (against
--   Composes 11), the shape Reconciliation 14 finds.
--   Part B, the reads: what the page's reads answer over one state — the disclosure probe,
--   the binding verdict (Verdict 1 through 5, 15; Action wiring 28 through 30), the
--   reissue's disclosed set (Composition state 16; Action wiring 22, 23, 55, 62), a bound
--   verification's presentation (Action wiring 33 through 37, 67, 71) and Check 1.2's
--   classes.
--
-- RULES ENCODED (named by the page's own labels)
--   Invariant 1.3        — no two live outcome events carry one disclosure id at act
--                          quiescence.
--   Invariant 1.4        — every outcome event carries a disclosure id the accounting
--                          records carry.
--   Invariant 1.7        — every outcome event carries the subject reference, recipient,
--                          scope, authority and disclosure instant of the accounting record
--                          its disclosure id names (Check 1.10).
--   Composition state 16 — a disclosure's disclosed set is read from the intent its outcome
--                          event names, and that is the disclosure's own intent (Check 5.6).
--   Check 5.7            — a reissue builds only over its own disclosure's Retained intent;
--                          a Purged one reads entry-set-purged (Action wiring 22, 23, 55, 62).
--   Term disclosure probe — the probe of an intent whose disclosure write committed answers
--                          committed with that record (the probe's committed answer).
--   Verdict 1, 2         — bound on exactly one live outcome event, binding-duplicate on more,
--                          read through the ledger enumeration (Action wiring 29, 30).
--   Verdict 3            — binding-purged only where the binding names a Purged outcome
--                          event carrying the disclosure id.
--   Verdict 4            — binding-escalated only where an escalation no settling closing
--                          names stands for the record's invocation.
--   Verdict 15           — binding-gap carries the state of the record's own invocation.
--   Action wiring 33 through 37 — a bound verification's presentation lands on exactly one
--                          arm of Action wiring 34, 35, 36, 37, 67 and 71.
--   Reconciliation 14    — every examined orphan record no intent carries is found, and no
--                          finding names a record the composition wrote.
--   Reconciliation 33    — every examined orphan whose invocation is closed by an
--                          abandonment or a refusal is alerted carrying its disclosure id.
--   Check 1.2            — every accounting record with no live outcome event, a young
--                          record excepted, resolves to exactly one of the check's classes.
-- Invariant 1.3, 1.4 and the probe's committed answer are a cross-check with
-- immutable-ledger.tla (Inv1_3, Inv1_4, -buggy-probekey, -buggy-probewindow); Reconciliation
-- 14 with immutable-ledger-reconcile.tla (Inv_R14).
--
-- NOT CHECKED HERE
--   Nothing testable in Alloy:
--   Invariant 2.1 through 2.3 — a capability of the deployment's proof mechanism and what its
--     bundle reveals; the bundle is an answer, no record keeps it, and [Verify Disclosure]
--     reads no record (Action wiring 24 through 27; External check 6, 7).
--   Action wiring 38, 39 — a relay of the verification's own answer, unchanged.
--   Left to the TLA+ models, which check them over every sequence:
--   Invariant 1.6 — a purged outcome's binding kept: it holds by the rebuild having run while
--     the outcome was live (immutable-ledger-rebuild.tla, Inv1_6); here it is a premise of
--     Check 1.2 (pred purgedOutcomesBound), not re-derived.
--   Invariant 4.1, Capability requirement 34 — the order of an answer and the writes, which no
--     record keeps (immutable-ledger.tla, Inv4_1, CR34).
--   Elsewhere: Invariant 3.1 through 3.4 (Audit Trail's), Invariant 1.1, 1.2, 1.5
--     (Recoverable Invocation's).
--
-- THE PAGE RELIES ON, AND DOES NOT STATE (each recorded on the page's Ledger already; the
-- model reaches each one, recorded, not cured)
--   (a) No record written outside the composition carries an intent's act key and disclosure
--       instant (open 2026-10-19-d): where one copies an intent whose invocation stands
--       closed by its own outcome, an intent carries it, so Reconciliation 14 finds nothing,
--       and its invocation is closed by an outcome, so Reconciliation 33 alerts nothing — it
--       falls in no class of Check 1.2 (pred noCopiedRecord, run ShowCopyUnclassed).
--   (b) No false closing outlives its intent (open 2026-10-19-e): an abandonment over a record
--       that exists, its intent Purged, leaves the aged record in no class — its record's
--       invocation is none, so it is no false closing, and its intent had a closing (pred
--       falseClosingKeepsIntent, run ShowFalseClosingPastIntent).
--   (c) No outside record is aged on arrival (open 2026-10-19-g): Term aged record says Check
--       1.2 is where one shows; no class of the check takes a record with no intent and no
--       finding (pred agedOutsideFound, run ShowAgedOnArrival).
--   (d) Invariant 1.6 (pred purgedOutcomesBound): a Purged outcome whose binding a failed
--       write and a missed rebuild lost leaves its record in no class (run ShowLostBinding);
--       immutable-ledger-rebuild.tla holds Invariant 1.6 in its own qualification.
--   And an observation, no defect the page can cure: the disclosure probe pairs on the act
--   key and the disclosure instant alone, so a record written outside the composition that
--   copies an intent whose own write never applied is recovered as that intent's disclosure,
--   bound, with the intent's disclosed set, and no rule surfaces it (run ShowCopyAdopted) —
--   the pairing datum cannot tell the two writers apart, and Composes 11 is what holds it.
--   Reconciliation 33's refusal arm is reached only through such a copy: a refused write
--   leaves no record of its own (Selective Disclosure Operation 16, 17; run
--   ShowRefusalOverCopy).
--
-- SCOPE
-- for 3 but 5 Int, 10 Ev, 2 Entry, 3 Intent, 3 Outcome, 1 Refusal, 1 Abandon, 1 Escalation,
-- 3 Rec, 3 DiscId, 1 Subj, 1 Recip, 2 Scope, 1 Auth, 2 Instant: three intents and three
-- accounting records over two act keys (two scopes) and two instants, ten Event Log events.
-- Five-bit integers for the Event Log sequence. Instants are compared for equality only (the
-- probe's one-instant range, the act key's pairing datum); the clock's edges (young, aged,
-- purged) are inputs. No trace, no `var`, no stepping: what a write read before it wrote stands
-- as a ghost (Intent.answered, the disclosure id the intent's disclosure write answered), and
-- nothing is checked across writes.
--
-- NOT MODELED HERE
--   - Primitive policy, Audit arm, [Record Entry], the credential, the read passthrough: refusals
--     that write nothing and a transcription of Audit Trail's arms.
--   - The recovery intent, the escalation's cause, the closure window's three sub-classes of
--     an open invocation (one class here: Recoverable Invocation's clock and Check 3.3).
--   - An outcome superseded by another (open 2026-10-09-q): an outcome here stands once
--     written; Recoverable Invocation's late-appended duplicate stands beside it until act
--     quiescence (its Invariant 2.4).
--   - The verification bundle's content, the unsealed tail, the seal (Verdict 8 through 14).
--
-- HOW TO READ RESULTS
-- Every "check A_*" must return "No counterexample found" (UNSAT) — the asserted guarantee holds.
-- Every "run Show*" must return at least one instance (SAT) — confirms non-vacuity.
-- A "check" returning a counterexample is a spec finding.

module immutable_ledger

open util/integer

-- ─────────────────────────────────────────────────────────────────────────────
-- Signatures (types)
-- ─────────────────────────────────────────────────────────────────────────────

-- Subj: an opaque subject reference (Term subject reference), compared byte-exact.
sig Subj {}

-- Recip: a recipient (Term recipient).
sig Recip {}

-- Scope: the descriptor of what was disclosed (Term scope).
sig Scope {}

-- Auth: Selective Disclosure's structured authority, its type and reference (Term authority).
sig Auth {}

-- Instant: a disclosure instant — the now an admitted disclosure carries (Term disclosure
-- instant). Compared for equality only.
sig Instant {}

-- DiscId: a disclosure id Selective Disclosure's record answers (Term disclosure id).
sig DiscId {}

-- Writer: who wrote an outcome event: the invocation's close, the sweep under the recovery
-- identity, or an operator settling an escalation (Term recovered outcome, settling closing).
abstract sig Writer {}
one sig ByInvocation, BySweep, ByOperator extends Writer {}

-- Ev: one ledger event on the composition's Audit Trail instance, with its Event Log
-- sequence number (Term ledger event).
abstract sig Ev {
    sn : one Int
}

-- Entry: a ledger entry (ledger.entry), the events a disclosure discloses.
sig Entry extends Ev {}

-- Intent: the intent (ledger.disclosure.intended) the invocation open writes, carrying the
-- intent data — the act key (subject reference, recipient, scope, authority), the disclosure
-- instant and the disclosed entry ids, never blank (Composition state 11) — and, a ghost, the
-- disclosure id its disclosure write answered (none: the write refused, gave no answer, or was
-- never made).
sig Intent extends Ev {
    isubj    : one Subj,
    irecip   : one Recip,
    iscope   : one Scope,
    iauth    : one Auth,
    iat      : one Instant,
    eset     : some Entry,
    answered : lone DiscId
}

-- Closing: a record Recoverable Invocation writes for the act kind that closes an invocation,
-- naming its intent by intent event id (Term outcome event).
abstract sig Closing extends Ev {
    of : one Intent
}

-- Outcome: an outcome event (ledger.disclosure.disclosed), carrying the disclosure id and the
-- accounting record's other fields (Term outcome data), who wrote it, the escalation it
-- settles where an operator wrote it, and the covering range the record read names for it
-- (Term covering range; empty: no covering range).
sig Outcome extends Closing {
    did      : one DiscId,
    osubj    : one Subj,
    orecip   : one Recip,
    oscope   : one Scope,
    oauth    : one Auth,
    oat      : one Instant,
    wr       : one Writer,
    osettles : lone Escalation,
    cov      : set Ev
}

-- Refusal: a refusal record (ledger.disclosure.refused) the invocation refusal writes over a
-- disclosure refusal (Action wiring 48).
sig Refusal extends Closing {}

-- Abandon: an abandonment (ledger.disclosure.abandoned) — for this kind an operator's,
-- settling an escalation where the operator's probe showed no record (Term settling closing).
sig Abandon extends Closing {
    asettles : one Escalation
}

-- Escalation: an escalated closing (ledger.disclosure.escalated) the sweep writes where it
-- cannot write the outcome (Term escalated closing).
sig Escalation extends Closing {}

-- Rec: one accounting record (Selective Disclosure's record): its disclosure id, subject
-- reference, recipient, scope, authority and disclosure instant (Term accounting records).
sig Rec {
    id     : one DiscId,
    rsubj  : one Subj,
    rrecip : one Recip,
    rscope : one Scope,
    rauth  : one Auth,
    rat    : one Instant
}

-- Purged: the events the record read answers Purged (Retention Window's). An input.
sig Purged in Ev {}

-- Young, Aged: the accounting records the reconciliation's now reads as young or aged (Term
-- young record, Term aged record). The clock's; inputs.
sig Young in Rec {}
sig Aged in Rec {}

-- Idx: the binding index as stored: a disclosure id to the event its binding names (Term
-- binding index).
one sig Idx {
    bind : DiscId -> lone Ev
}

-- WOFinding: the disclosure ids the finding surface carries a write-ownership finding for,
-- persisted (Capability requirement 30; Term write-ownership finding).
sig WOFinding in DiscId {}

-- Alert33: the disclosure ids Reconciliation 33's alert carries.
sig Alert33 in DiscId {}

-- Map: the auditor's original event payloads at one [Verify Ledger] call — the sequence
-- positions it supplies a payload for (Term original event payloads).
one sig Map {
    has : set Ev
}

-- Verdict: the binding verdict (Term binding verdict).
abstract sig Verdict {}
one sig VBound, VDup, VPurged, VEsc, VGap extends Verdict {}

-- ─────────────────────────────────────────────────────────────────────────────
-- Helpers: the page's terms over one state
-- ─────────────────────────────────────────────────────────────────────────────

-- sameKey: two intents carry one act key (Term act key).
pred sameKey[i, j : Intent] {
    i.isubj = j.isubj and i.irecip = j.irecip and i.iscope = j.iscope and i.iauth = j.iauth
}

-- sameKI: an intent carries an accounting record's act key and disclosure instant (Term
-- record's invocation; Reconciliation 14).
pred sameKI[r : Rec, i : Intent] {
    r.rsubj = i.isubj and r.rrecip = i.irecip and r.rscope = i.iscope and r.rauth = i.iauth
    and r.rat = i.iat
}

-- recFields, intentFields: an outcome event carries a record's, or an intent's, subject
-- reference, recipient, scope, authority and disclosure instant.
pred recFields[o : Outcome, r : Rec] {
    o.osubj = r.rsubj and o.orecip = r.rrecip and o.oscope = r.rscope and o.oauth = r.rauth
    and o.oat = r.rat
}
pred intentFields[o : Outcome, i : Intent] {
    o.osubj = i.isubj and o.orecip = i.irecip and o.oscope = i.iscope and o.oauth = i.iauth
    and o.oat = i.iat
}

-- probe: the disclosure probe's matching records for an intent — the disclosure read filtered
-- by the act key's subject reference and recipient and by the intent's disclosure instant,
-- kept to the act key's scope and authority (Term disclosure probe). Committed where exactly
-- one matches, not-committed where none does, undecidable where more than one does.
fun probe[i : Intent] : set Rec {
    { r : Rec | r.rsubj = i.isubj and r.rrecip = i.irecip and r.rat = i.iat
                and r.rscope = i.iscope and r.rauth = i.iauth }
}

-- recOf: the accounting record a disclosure id names.
fun recOf[d : DiscId] : set Rec { id.d }

-- live: the live outcome events carrying a disclosure id — Retained, the ledger enumeration's
-- read of their payload (Term live outcome event).
fun live[d : DiscId] : set Outcome { (Outcome - Purged) & did.d }

-- settled: the escalations a settling closing names (Term settling closing).
fun settled : set Escalation { Outcome.osettles + Abandon.asettles }

-- standing: the closings that stand for some intents — every closing naming one, an escalation
-- a settling closing names excepted (Recoverable Invocation's which closing stands).
fun standing[is : set Intent] : set Closing { of.is - settled }

-- recInv: the record's invocation — the intents the ledger enumeration kept to the intents
-- finds carrying an accounting record's act key and disclosure instant: Retained only, since
-- the enumeration reads their payload (Term record's invocation).
fun recInv[rs : set Rec] : set Intent { { i : Intent - Purged | some r : rs | sameKI[r, i] } }

-- composed: the accounting records a commit of the composition wrote (a ghost: the id an
-- intent's disclosure write answered).
fun composed : set Rec { id.(Intent.answered) }

-- examined: an accounting record neither young nor aged.
pred examined[r : Rec] { r not in Young + Aged }

-- orphan: an examined accounting record no Retained outcome event names and no binding names
-- (Term orphan record).
pred orphan[r : Rec] { examined[r] and no live[r.id] and no Idx.bind[r.id] }

-- actQuiescent: act quiescence — every invocation of the act kind stands closed, by one
-- outcome where by an outcome (Recoverable Invocation's late-appended duplicate resolved).
pred actQuiescent { all i : Intent | some standing[i] and lone (standing[i] & Outcome) }

-- verdict: [Verify Ledger]'s binding verdict for a disclosure id the accounting records carry
-- (Verdict 1 through 5): the ledger enumeration kept to the outcome events carrying the id first
-- (Action wiring 29, 30), then the binding index read with the record read of the event it names,
-- then the record's invocation and the closing that stands for it.
fun verdict[d : DiscId] : one Verdict {
    (one live[d]) => VBound else
    ((some live[d]) => VDup else
    ((some Idx.bind[d] and Idx.bind[d] in Purged) => VPurged else
    ((some (standing[recInv[recOf[d]]] & Escalation)) => VEsc else VGap)))
}

-- gapState: the state of the record's invocation a binding-gap carries (Verdict 15) — the
-- closing that stands for it (none: open).
fun gapState[d : DiscId] : set Closing { standing[recInv[recOf[d]]] }

-- reissueFrom: the intent whose disclosed set a found reissue builds the bundle over — the
-- intent the live outcome event names, where the record read answers it Retained (Action wiring
-- 23, 55; Composition state 16). None: not-known, or entry-set-purged.
fun reissueFrom[d : DiscId] : set Intent { live[d].of - Purged }

-- The presentation arms of a bound verification over the outcome event's covering range and
-- the auditor's original event payloads (Action wiring 34 through 37, 67, 71).
pred arm36[o : Outcome] { some o.cov and no (o.cov & Purged) and o.cov in Map.has }
pred arm35[o : Outcome] { some o.cov and no (o.cov & Purged) and some (o.cov - Map.has) }
pred arm34[o : Outcome] { some (o.cov & Purged) and some (o.cov & Map.has) }
pred arm71[o : Outcome] { some (o.cov & Purged) and no (o.cov & Map.has) }
pred arm37[o : Outcome] { no o.cov and o in Map.has }
pred arm67[o : Outcome] { no o.cov and o not in Map.has }

-- armCount: how many presentation arms land for an outcome event.
fun armCount[o : Outcome] : Int {
    plus[plus[plus[(arm36[o] => 1 else 0), (arm35[o] => 1 else 0)],
              plus[(arm34[o] => 1 else 0), (arm71[o] => 1 else 0)]],
         plus[(arm37[o] => 1 else 0), (arm67[o] => 1 else 0)]]
}

-- Check 1.2's classes for an accounting record carrying no live outcome event.
-- cPurged: binding-purged (Verdict 3). cEsc: binding-escalated (Verdict 4).
pred cPurged[r : Rec] { verdict[r.id] = VPurged }
pred cEsc[r : Rec] { verdict[r.id] = VEsc }
-- cOpen: an open invocation, inside or outside the instance's closure window, exempt or not.
pred cOpen[r : Rec] { some i : recInv[r] | no standing[i] }
-- cIntentGone: an aged record whose invocation's intent the horizon destroyed, with no closing.
pred cIntentGone[r : Rec] { r in Aged and some i : Intent & Purged | sameKI[r, i] and no of.i }
-- cFalse: a false closing — the record's invocation closed by an abandonment or a refusal
-- (Term false closing).
pred cFalse[r : Rec] { some i : recInv[r] | some (standing[i] & (Abandon + Refusal)) }
-- cFound: a write-ownership finding.
pred cFound[r : Rec] { r.id in WOFinding }

-- classCount: how many of Check 1.2's classes take the record.
fun classCount[r : Rec] : Int {
    plus[plus[plus[(cPurged[r] => 1 else 0), (cEsc[r] => 1 else 0)],
              plus[(cOpen[r] => 1 else 0), (cIntentGone[r] => 1 else 0)]],
         plus[(cFalse[r] => 1 else 0), (cFound[r] => 1 else 0)]]
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Facts: what the page takes from outside
-- ─────────────────────────────────────────────────────────────────────────────

-- Event Log numbers each event with its own sequence number (Event Log Invariant 3).
fact EventLogSequence {
    all disj e1, e2 : Ev | e1.sn != e2.sn
}

-- Retention Window purges the oldest events first: an event older than a Purged one is Purged.
fact PurgeOldestFirst {
    all e : Purged, e2 : Ev | lt[e2.sn, e.sn] implies e2 in Purged
}

-- Recoverable Invocation writes the intent before any closing that names it (its Invariant 1),
-- and a settling closing after the escalation it names, for the same intent.
fact ClosingsFollowIntent {
    all c : Closing | lt[c.of.sn, c.sn]
    all o : Outcome | some o.osettles implies (o.osettles.of = o.of and lt[o.osettles.sn, o.sn])
    all a : Abandon | a.asettles.of = a.of and lt[a.asettles.sn, a.sn]
}

-- Recoverable Invocation's closings: one stands per invocation (its Invariant 2), but for the
-- late-appended duplicate outcome its close may land beside the sweep's before act quiescence
-- (its Invariant 2.4); at most one outcome per writer; an operator's outcome, and only an
-- operator's, settles an escalation, and an escalation is settled at most once.
fact OneClosingStands {
    all i : Intent | lone (standing[i] - Outcome)
    all i : Intent | some (standing[i] & Outcome) implies no (standing[i] - Outcome)
    all i : Intent, w : Writer | lone (of.i & Outcome & wr.w)
    all o : Outcome | some o.osettles iff o.wr = ByOperator
    all e : Escalation | lone (osettles.e + asettles.e)
}

-- Selective Disclosure mints a fresh disclosure id for every record (two records never carry
-- one id, two writes never answer one), and a refused write leaves the store as the call found
-- it (Selective Disclosure Operation 14, 16, 17): an intent the protocol refused answered no id.
fact SelectiveDisclosureIds {
    all disj r1, r2 : Rec | r1.id != r2.id
    all disj i, j : Intent | no (i.answered & j.answered)
    all f : Refusal | no f.of.answered
}

-- The host injects no equal now into two invocations of one act key (Capability requirement
-- 28; the host's).
fact HostNowDistinct {
    all disj i, j : Intent | sameKey[i, j] implies i.iat != j.iat
}

-- The clock's edges: no record is young and aged at once (the examine window end precedes the
-- aged edge, Capability requirement 33), and an intent whose disclosure instant is a record's
-- that is not yet aged is not yet purged (the aged edge is the horizon less two clock
-- allowances and the run bound, Term aged record).
fact ClockEdges {
    no Young & Aged
    all r : Rec - Aged, i : Intent | i.iat = r.rat implies i not in Purged
}

-- An operator leaves no unsettled escalation past its intent's horizon edge (Capability
-- requirement 29; the operator's).
fact OperatorSettles {
    all e : Escalation - settled | e.of not in Purged
}

-- Audit Trail's record read names a covering range that holds the event (Audit Trail's seal).
fact CoveringRangeHoldsEvent {
    all o : Outcome | some o.cov implies o in o.cov
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Part A — the records: what each admitted write leaves
-- ─────────────────────────────────────────────────────────────────────────────

-- commitWiring: the disclosure write is called with the intent's subject reference, recipient,
-- scope, authority and disclosure instant (Action wiring 6; Term disclosure instant), and the
-- record it answered stands, the accounting records' retention unbounded (Retention asymmetry 1).
pred commitWiring {
    all i : Intent | some i.answered implies one r : Rec | r.id = i.answered and sameKI[r, i]
}

-- outcomeWiring: the invocation close writes the outcome of an accounted disclosure, carrying
-- the disclosure id the write answered and the call's own fields (Action wiring 53, Term
-- outcome data); a recovered outcome — the sweep's, or an operator's settling one — carries the
-- disclosure id and fields of the one record the disclosure probe answers committed for the
-- intent (Recoverable Invocation's Invariant 3.5 and 5.3, through Term disclosure probe and
-- Term outcome data).
pred outcomeWiring {
    all o : Outcome | o.wr = ByInvocation implies
        (some o.of.answered and o.did = o.of.answered and intentFields[o, o.of])
    all o : Outcome | o.wr != ByInvocation implies
        (one probe[o.of] and o.did = probe[o.of].id and recFields[o, probe[o.of]])
}

-- indexWiring: a binding carries the outcome event id of an outcome event carrying its
-- disclosure id (Composition state 2, 3, 4; Action wiring 16; the binding rebuild,
-- Composition state 18). A write may fail (Action wiring 66), so a binding may be missing.
pred indexWiring {
    all d : DiscId, e : Idx.bind[d] | e in Outcome and e.did = d
}

-- reconcileWiring: the last reconciliation run read the stores as they stand (Reconciliation
-- 34: the database read first, so every record's intent is visible). It found every examined
-- orphan no Retained intent carries (Reconciliation 14); a finding names an accounting record
-- that is an orphan of no intent (Term write-ownership finding, standing while the record is an
-- orphan); it alerted every examined orphan whose record's invocation stands closed by an
-- abandonment or a refusal (Reconciliation 33); and an alert names a disclosure id the
-- accounting records carry.
pred reconcileWiring {
    all r : Rec | (orphan[r] and no i : Intent - Purged | sameKI[r, i]) implies r.id in WOFinding
    all d : WOFinding | some r : recOf[d] |
        no live[d] and no Idx.bind[d] and no i : Intent | sameKI[r, i]
    all r : Rec | (orphan[r] and some i : recInv[r] | some (standing[i] & (Abandon + Refusal)))
        implies r.id in Alert33
    Alert33 in Rec.id
}

-- built: every record in the state is what an admitted write left.
pred built {
    commitWiring
    outcomeWiring
    indexWiring
    reconcileWiring
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Premises the page relies on and does not state (header, (a) to (d))
-- ─────────────────────────────────────────────────────────────────────────────

-- noCopiedRecord: every accounting record an intent's act key and disclosure instant carry is
-- that intent's own (premise (a), open 2026-10-19-d; run ShowCopyUnclassed).
pred noCopiedRecord {
    all r : Rec, i : Intent | sameKI[r, i] implies r.id = i.answered
}

-- falseClosingKeepsIntent: no abandonment or refusal stands over a record that exists once the
-- record's intent is Purged (premise (b), open 2026-10-19-e; run ShowFalseClosingPastIntent).
pred falseClosingKeepsIntent {
    all r : Rec, i : Intent & Purged | sameKI[r, i] implies no (of.i & (Abandon + Refusal))
}

-- agedOutsideFound: an aged record no intent carries was found while it was examined
-- (premise (c), open 2026-10-19-g; run ShowAgedOnArrival).
pred agedOutsideFound {
    all r : Aged | (no i : Intent | sameKI[r, i]) implies r.id in WOFinding
}

-- purgedOutcomesBound: Invariant 1.6, which immutable-ledger-rebuild.tla checks — a disclosure
-- whose outcome events are all Purged keeps a binding naming a Purged one (premise (d); run
-- ShowLostBinding).
pred purgedOutcomesBound {
    all d : Rec.id | (some (Outcome & Purged & did.d) and no live[d]) implies
        (some Idx.bind[d] and Idx.bind[d] in Purged)
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Assertions (verified guarantees)
-- Each "check" asks: is there any state the page's writes can leave that violates this
-- assertion? No counterexample (UNSAT) = the guarantee holds within scope.
-- ─────────────────────────────────────────────────────────────────────────────

-- A_Invariant_1_3: at act quiescence no two live outcome events carry one disclosure id.
assert A_Invariant_1_3 {
    (built and actQuiescent) implies all disj o1, o2 : Outcome - Purged | o1.did != o2.did
}
check A_Invariant_1_3 for 3 but 5 Int, 10 Ev, 2 Entry, 3 Intent, 3 Outcome, 1 Refusal, 1 Abandon, 1 Escalation, 3 Rec, 3 DiscId, 1 Subj, 1 Recip, 2 Scope, 1 Auth, 2 Instant

-- A_Invariant_1_4: every outcome event carries a disclosure id the accounting records carry.
assert A_Invariant_1_4 {
    built implies all o : Outcome | some recOf[o.did]
}
check A_Invariant_1_4 for 3 but 5 Int, 10 Ev, 2 Entry, 3 Intent, 3 Outcome, 1 Refusal, 1 Abandon, 1 Escalation, 3 Rec, 3 DiscId, 1 Subj, 1 Recip, 2 Scope, 1 Auth, 2 Instant

-- A_Invariant_1_7: every outcome event carries the subject reference, recipient, scope,
-- authority and disclosure instant of the accounting record its disclosure id names (Check
-- 1.10).
assert A_Invariant_1_7 {
    built implies all o : Outcome, r : recOf[o.did] | recFields[o, r]
}
check A_Invariant_1_7 for 3 but 5 Int, 10 Ev, 2 Entry, 3 Intent, 3 Outcome, 1 Refusal, 1 Abandon, 1 Escalation, 3 Rec, 3 DiscId, 1 Subj, 1 Recip, 2 Scope, 1 Auth, 2 Instant

-- A_Composition_state_16: an outcome event carrying a disclosure id a commit of the composition
-- answered names that commit's own intent, so the disclosed set read through it is the
-- disclosure's own (Check 5.6).
assert A_Composition_state_16 {
    built implies all o : Outcome | some answered.(o.did) implies o.of = answered.(o.did)
}
check A_Composition_state_16 for 3 but 5 Int, 10 Ev, 2 Entry, 3 Intent, 3 Outcome, 1 Refusal, 1 Abandon, 1 Escalation, 3 Rec, 3 DiscId, 1 Subj, 1 Recip, 2 Scope, 1 Auth, 2 Instant

-- A_Check_5_7: a reissue of a disclosure the composition made builds only over the disclosed
-- set of the disclosure's own intent, and only where the record read answers it Retained; a
-- Purged intent reads entry-set-purged (Action wiring 22, 23, 55, 62).
assert A_Check_5_7 {
    built implies all d : Intent.answered | {
        reissueFrom[d] in answered.d - Purged
        (some live[d] and answered.d not in Purged) implies reissueFrom[d] = answered.d
    }
}
check A_Check_5_7 for 3 but 5 Int, 10 Ev, 2 Entry, 3 Intent, 3 Outcome, 1 Refusal, 1 Abandon, 1 Escalation, 3 Rec, 3 DiscId, 1 Subj, 1 Recip, 2 Scope, 1 Auth, 2 Instant

-- A_Term_disclosure_probe: the probe of an intent whose disclosure write committed, where no
-- other record carries its act key and instant, answers committed with that record.
assert A_Term_disclosure_probe {
    built implies all i : Intent |
        (some i.answered and (all r : Rec | sameKI[r, i] implies r.id = i.answered))
            implies probe[i] = recOf[i.answered]
}
check A_Term_disclosure_probe for 3 but 5 Int, 10 Ev, 2 Entry, 3 Intent, 3 Outcome, 1 Refusal, 1 Abandon, 1 Escalation, 3 Rec, 3 DiscId, 1 Subj, 1 Recip, 2 Scope, 1 Auth, 2 Instant

-- A_Verdict_1_2: a disclosure reads bound exactly where one live outcome event carries its id,
-- and binding-duplicate exactly where more than one does.
assert A_Verdict_1_2 {
    built implies all d : Rec.id | {
        verdict[d] = VBound iff one live[d]
        verdict[d] = VDup iff (some live[d] and not one live[d])
    }
}
check A_Verdict_1_2 for 3 but 5 Int, 10 Ev, 2 Entry, 3 Intent, 3 Outcome, 1 Refusal, 1 Abandon, 1 Escalation, 3 Rec, 3 DiscId, 1 Subj, 1 Recip, 2 Scope, 1 Auth, 2 Instant

-- A_Verdict_3: a disclosure reads binding-purged only where its binding names a Purged outcome
-- event carrying its disclosure id — honest destruction, never another event's purge.
assert A_Verdict_3 {
    built implies all d : Rec.id | verdict[d] = VPurged implies
        (Idx.bind[d] in Outcome & Purged and Idx.bind[d].did = d)
}
check A_Verdict_3 for 3 but 5 Int, 10 Ev, 2 Entry, 3 Intent, 3 Outcome, 1 Refusal, 1 Abandon, 1 Escalation, 3 Rec, 3 DiscId, 1 Subj, 1 Recip, 2 Scope, 1 Auth, 2 Instant

-- A_Verdict_4: a disclosure reads binding-escalated only where an escalation no settling
-- closing names stands for the record's invocation.
assert A_Verdict_4 {
    built implies all d : Rec.id | verdict[d] = VEsc implies
        some e : Escalation - settled | e.of in recInv[recOf[d]]
}
check A_Verdict_4 for 3 but 5 Int, 10 Ev, 2 Entry, 3 Intent, 3 Outcome, 1 Refusal, 1 Abandon, 1 Escalation, 3 Rec, 3 DiscId, 1 Subj, 1 Recip, 2 Scope, 1 Auth, 2 Instant

-- A_Verdict_15: a disclosure the composition made that reads binding-gap, its intent Retained,
-- carries the state of its own invocation — the one whose commit answered its id.
assert A_Verdict_15 {
    built implies all d : Intent.answered |
        (verdict[d] = VGap and answered.d not in Purged) implies gapState[d] = standing[answered.d]
}
check A_Verdict_15 for 3 but 5 Int, 10 Ev, 2 Entry, 3 Intent, 3 Outcome, 1 Refusal, 1 Abandon, 1 Escalation, 3 Rec, 3 DiscId, 1 Subj, 1 Recip, 2 Scope, 1 Auth, 2 Instant

-- A_Action_wiring_33_37: a bound verification's presentation lands on exactly one of the arms
-- Action wiring 34, 35, 36, 37, 67 and 71 give, whatever the covering range and the payloads
-- the auditor supplies.
assert A_Action_wiring_33_37 {
    built implies all o : Outcome - Purged | verdict[o.did] = VBound implies armCount[o] = 1
}
check A_Action_wiring_33_37 for 3 but 5 Int, 10 Ev, 2 Entry, 3 Intent, 3 Outcome, 1 Refusal, 1 Abandon, 1 Escalation, 3 Rec, 3 DiscId, 1 Subj, 1 Recip, 2 Scope, 1 Auth, 2 Instant

-- A_Reconciliation_14: every examined orphan record no intent carries — one a deployment wrote
-- outside the composition — carries a write-ownership finding, and no finding names a record a
-- commit of the composition wrote.
assert A_Reconciliation_14 {
    built implies {
        all r : Rec | (orphan[r] and no i : Intent | sameKI[r, i]) implies r.id in WOFinding
        no (WOFinding & Intent.answered)
    }
}
check A_Reconciliation_14 for 3 but 5 Int, 10 Ev, 2 Entry, 3 Intent, 3 Outcome, 1 Refusal, 1 Abandon, 1 Escalation, 3 Rec, 3 DiscId, 1 Subj, 1 Recip, 2 Scope, 1 Auth, 2 Instant

-- A_Reconciliation_33: every examined orphan record whose record's invocation stands closed by
-- an abandonment or a refusal is alerted carrying its disclosure id.
assert A_Reconciliation_33 {
    built implies all r : Rec |
        (orphan[r] and some (standing[recInv[r]] & (Abandon + Refusal))) implies r.id in Alert33
}
check A_Reconciliation_33 for 3 but 5 Int, 10 Ev, 2 Entry, 3 Intent, 3 Outcome, 1 Refusal, 1 Abandon, 1 Escalation, 3 Rec, 3 DiscId, 1 Subj, 1 Recip, 2 Scope, 1 Auth, 2 Instant

-- A_Check_1_2: every accounting record carrying no live outcome event, a young record excepted,
-- resolves to exactly one of binding-purged, binding-escalated, an open invocation, an aged
-- record whose intent the horizon destroyed with no closing, a false closing, a write-ownership
-- finding. Under premises (a) to (d).
assert A_Check_1_2 {
    (built and noCopiedRecord and falseClosingKeepsIntent and agedOutsideFound
     and purgedOutcomesBound) implies
        all r : Rec | (r not in Young and no live[r.id]) implies classCount[r] = 1
}
check A_Check_1_2 for 3 but 5 Int, 10 Ev, 2 Entry, 3 Intent, 3 Outcome, 1 Refusal, 1 Abandon, 1 Escalation, 3 Rec, 3 DiscId, 1 Subj, 1 Recip, 2 Scope, 1 Auth, 2 Instant

-- ─────────────────────────────────────────────────────────────────────────────
-- Satisfiability runs — non-vacuity guards, one for each shape the page admits
-- Each run must find at least one instance (SAT).
-- UNSAT means the model forbids a state the page admits.
-- ─────────────────────────────────────────────────────────────────────────────

-- ShowLanded: a disclosure the invocation landed — its intent, its accounting record, its
-- outcome event and its binding — read bound, its reissue built over its intent.
run ShowLanded {
    built and some o : Outcome - Purged | o.wr = ByInvocation and Idx.bind[o.did] = o
        and verdict[o.did] = VBound and reissueFrom[o.did] = o.of
} for 3 but 5 Int, 10 Ev, 2 Entry, 3 Intent, 3 Outcome, 1 Refusal, 1 Abandon, 1 Escalation, 3 Rec, 3 DiscId, 1 Subj, 1 Recip, 2 Scope, 1 Auth, 2 Instant

-- ShowRepeatedKey: two disclosures of one act key at two instants, each landed (the kind is
-- repeatable, Term act key).
run ShowRepeatedKey {
    built and actQuiescent and some disj i, j : Intent | sameKey[i, j]
        and some (standing[i] & Outcome) and some (standing[j] & Outcome)
} for 3 but 5 Int, 10 Ev, 2 Entry, 3 Intent, 3 Outcome, 1 Refusal, 1 Abandon, 1 Escalation, 3 Rec, 3 DiscId, 1 Subj, 1 Recip, 2 Scope, 1 Auth, 2 Instant

-- ShowRecovered: an outcome the sweep recovered through the probe for an intent whose close
-- failed, read bound.
run ShowRecovered {
    built and some o : Outcome - Purged | o.wr = BySweep and verdict[o.did] = VBound
} for 3 but 5 Int, 10 Ev, 2 Entry, 3 Intent, 3 Outcome, 1 Refusal, 1 Abandon, 1 Escalation, 3 Rec, 3 DiscId, 1 Subj, 1 Recip, 2 Scope, 1 Auth, 2 Instant

-- ShowLateDuplicate: before act quiescence, the invocation's late-appended outcome beside the
-- sweep's, read binding-duplicate.
run ShowLateDuplicate {
    built and some d : Rec.id | verdict[d] = VDup
} for 3 but 5 Int, 10 Ev, 2 Entry, 3 Intent, 3 Outcome, 1 Refusal, 1 Abandon, 1 Escalation, 3 Rec, 3 DiscId, 1 Subj, 1 Recip, 2 Scope, 1 Auth, 2 Instant

-- ShowPurgedBinding: an outcome event purged at its retention end, its binding kept, read
-- binding-purged; the reissue answers entry-set-purged (Action wiring 62).
run ShowPurgedBinding {
    built and some d : Rec.id | verdict[d] = VPurged and no reissueFrom[d]
} for 3 but 5 Int, 10 Ev, 2 Entry, 3 Intent, 3 Outcome, 1 Refusal, 1 Abandon, 1 Escalation, 3 Rec, 3 DiscId, 1 Subj, 1 Recip, 2 Scope, 1 Auth, 2 Instant

-- ShowEntrySetPurged: a live outcome event whose intent the horizon purged: its reissue reads
-- entry-set-purged (Action wiring 55, Check 5.7).
run ShowEntrySetPurged {
    built and some o : Outcome - Purged | o.of in Purged and no reissueFrom[o.did]
} for 3 but 5 Int, 10 Ev, 2 Entry, 3 Intent, 3 Outcome, 1 Refusal, 1 Abandon, 1 Escalation, 3 Rec, 3 DiscId, 1 Subj, 1 Recip, 2 Scope, 1 Auth, 2 Instant

-- ShowEscalated: a record whose invocation the sweep escalated, read binding-escalated.
run ShowEscalated {
    built and some d : Rec.id | verdict[d] = VEsc
} for 3 but 5 Int, 10 Ev, 2 Entry, 3 Intent, 3 Outcome, 1 Refusal, 1 Abandon, 1 Escalation, 3 Rec, 3 DiscId, 1 Subj, 1 Recip, 2 Scope, 1 Auth, 2 Instant

-- ShowSettled: an escalation an operator's outcome settled, read bound.
run ShowSettled {
    built and some o : Outcome - Purged | some o.osettles and verdict[o.did] = VBound
} for 3 but 5 Int, 10 Ev, 2 Entry, 3 Intent, 3 Outcome, 1 Refusal, 1 Abandon, 1 Escalation, 3 Rec, 3 DiscId, 1 Subj, 1 Recip, 2 Scope, 1 Auth, 2 Instant

-- ShowOpenGap: a record whose invocation is still open (a yielded disclosure), read binding-gap
-- carrying the open state.
run ShowOpenGap {
    built and some r : Rec - Young | verdict[r.id] = VGap and cOpen[r] and no gapState[r.id]
} for 3 but 5 Int, 10 Ev, 2 Entry, 3 Intent, 3 Outcome, 1 Refusal, 1 Abandon, 1 Escalation, 3 Rec, 3 DiscId, 1 Subj, 1 Recip, 2 Scope, 1 Auth, 2 Instant

-- ShowFalseClosing: an operator's abandonment over a record that exists, alerted
-- (Reconciliation 33), read binding-gap carrying the abandonment.
run ShowFalseClosing {
    built and some r : Rec | orphan[r] and cFalse[r] and r.id in Alert33
        and some (gapState[r.id] & Abandon)
} for 3 but 5 Int, 10 Ev, 2 Entry, 3 Intent, 3 Outcome, 1 Refusal, 1 Abandon, 1 Escalation, 3 Rec, 3 DiscId, 1 Subj, 1 Recip, 2 Scope, 1 Auth, 2 Instant

-- ShowRefused: a disclosure write refused, its intent closed by a refusal record, no record.
run ShowRefused {
    built and some f : Refusal | no probe[f.of]
} for 3 but 5 Int, 10 Ev, 2 Entry, 3 Intent, 3 Outcome, 1 Refusal, 1 Abandon, 1 Escalation, 3 Rec, 3 DiscId, 1 Subj, 1 Recip, 2 Scope, 1 Auth, 2 Instant

-- ShowOutsideFound: a record written outside the composition, no intent carrying it, found.
run ShowOutsideFound {
    built and some r : Rec | orphan[r] and r.id in WOFinding
} for 3 but 5 Int, 10 Ev, 2 Entry, 3 Intent, 3 Outcome, 1 Refusal, 1 Abandon, 1 Escalation, 3 Rec, 3 DiscId, 1 Subj, 1 Recip, 2 Scope, 1 Auth, 2 Instant

-- ShowIntentGone: an aged record whose intent the horizon destroyed with no closing (Verdict 5,
-- Recoverable Invocation Invariant 7.3).
run ShowIntentGone {
    built and some r : Rec | no live[r.id] and cIntentGone[r] and classCount[r] = 1
} for 3 but 5 Int, 10 Ev, 2 Entry, 3 Intent, 3 Outcome, 1 Refusal, 1 Abandon, 1 Escalation, 3 Rec, 3 DiscId, 1 Subj, 1 Recip, 2 Scope, 1 Auth, 2 Instant

-- ShowProbeUndecidable: a record written outside the composition copying an intent's act key
-- and instant beside its own record: the probe answers undecidable and the sweep escalates.
run ShowProbeUndecidable {
    built and some i : Intent | #probe[i] > 1 and some (standing[i] & Escalation)
} for 3 but 5 Int, 10 Ev, 2 Entry, 3 Intent, 3 Outcome, 1 Refusal, 1 Abandon, 1 Escalation, 3 Rec, 3 DiscId, 1 Subj, 1 Recip, 2 Scope, 1 Auth, 2 Instant

-- ShowPartialCoverage: a bound verification over a partially-purged covering range, the
-- auditor supplying a Retained member (Action wiring 34).
run ShowPartialCoverage {
    built and some o : Outcome - Purged | verdict[o.did] = VBound and arm34[o]
} for 3 but 5 Int, 10 Ev, 2 Entry, 3 Intent, 3 Outcome, 1 Refusal, 1 Abandon, 1 Escalation, 3 Rec, 3 DiscId, 1 Subj, 1 Recip, 2 Scope, 1 Auth, 2 Instant

-- ShowCopyUnclassed: premise (a). A record written outside the composition copying an intent
-- whose invocation stands closed by its own outcome: no finding, no alert, no class.
run ShowCopyUnclassed {
    built and falseClosingKeepsIntent and agedOutsideFound and purgedOutcomesBound
        and some r : Rec - Young | no live[r.id] and classCount[r] = 0
} for 3 but 5 Int, 10 Ev, 2 Entry, 3 Intent, 3 Outcome, 1 Refusal, 1 Abandon, 1 Escalation, 3 Rec, 3 DiscId, 1 Subj, 1 Recip, 2 Scope, 1 Auth, 2 Instant

-- ShowFalseClosingPastIntent: premise (b). An abandonment over a record that exists, the
-- intent Purged: the aged record falls in no class.
run ShowFalseClosingPastIntent {
    built and noCopiedRecord and agedOutsideFound and purgedOutcomesBound
        and some r : Rec - Young | no live[r.id] and classCount[r] = 0
} for 3 but 5 Int, 10 Ev, 2 Entry, 3 Intent, 3 Outcome, 1 Refusal, 1 Abandon, 1 Escalation, 3 Rec, 3 DiscId, 1 Subj, 1 Recip, 2 Scope, 1 Auth, 2 Instant

-- ShowAgedOnArrival: premise (c). A record written outside the composition, aged on arrival,
-- never examined: no finding, no class.
run ShowAgedOnArrival {
    built and noCopiedRecord and falseClosingKeepsIntent and purgedOutcomesBound
        and some r : Aged | no live[r.id] and classCount[r] = 0
} for 3 but 5 Int, 10 Ev, 2 Entry, 3 Intent, 3 Outcome, 1 Refusal, 1 Abandon, 1 Escalation, 3 Rec, 3 DiscId, 1 Subj, 1 Recip, 2 Scope, 1 Auth, 2 Instant

-- ShowLostBinding: premise (d). A Purged outcome event whose binding was never written: its
-- record falls in no class.
run ShowLostBinding {
    built and noCopiedRecord and falseClosingKeepsIntent and agedOutsideFound
        and some r : Rec - Young | no live[r.id] and classCount[r] = 0
} for 3 but 5 Int, 10 Ev, 2 Entry, 3 Intent, 3 Outcome, 1 Refusal, 1 Abandon, 1 Escalation, 3 Rec, 3 DiscId, 1 Subj, 1 Recip, 2 Scope, 1 Auth, 2 Instant

-- ShowCopyAdopted: the observation. A record written outside the composition copying an intent
-- whose own write never applied, recovered as that intent's disclosure and read bound, with no
-- finding.
run ShowCopyAdopted {
    built and some o : Outcome - Purged | no answered.(o.did) and verdict[o.did] = VBound
        and o.did not in WOFinding
} for 3 but 5 Int, 10 Ev, 2 Entry, 3 Intent, 3 Outcome, 1 Refusal, 1 Abandon, 1 Escalation, 3 Rec, 3 DiscId, 1 Subj, 1 Recip, 2 Scope, 1 Auth, 2 Instant

-- ShowRefusalOverCopy: Reconciliation 33's refusal arm, reached only through a record written
-- outside the composition copying a refused intent's act key and instant.
run ShowRefusalOverCopy {
    built and some r : Rec | orphan[r] and some (standing[recInv[r]] & Refusal) and r.id in Alert33
} for 3 but 5 Int, 10 Ev, 2 Entry, 3 Intent, 3 Outcome, 1 Refusal, 1 Abandon, 1 Escalation, 3 Rec, 3 DiscId, 1 Subj, 1 Recip, 2 Scope, 1 Auth, 2 Instant
