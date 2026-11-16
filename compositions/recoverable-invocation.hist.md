---
title: Recoverable Invocation — history
nav_exclude: true
search_exclude: true
---

# Recoverable Invocation — history

The dated record of how [Recoverable Invocation](./recoverable-invocation.md) got here, moved out of the spec on 2026-10-20 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- compositions/recoverable-invocation.md`.

## Decisions

Entries that record a round, a binding, a model run or a migration rather than a turn the pattern took, and the twelfth gate's consolidations, which chose where a rule is stated.

- **2026-08-30 — The model's two corrections.** *Chose:* a host that releases only on return or expiry, and one budgeted dead run. *Over:* release on death, and one bound. *Because:* the death twin lands two closings for one act.

- **2026-08-30 — The closure window is bounded by three sweep runs.** *Chose:* `completion_bound + 2 × clock_offset_allowance + 2 × reconciliation_cadence + 3 × run_bound < compensation_window`. *Over:* one run bound, and the two-term correction the gate prescribed. *Because:* a budgeted death involves three runs; the enumeration breaches the old form on 420 of 432 tuples and the correction on 396.

- **2026-08-30 — A duplicate is decided by supersession first and position second.** *Chose:* a declared field on [Read Invocation], a scan over the delta, a check over all four closing kinds. *Over:* three detectors that did not exist. *Because:* a degraded guarantee whose detection is asserted is worth less than an honest statement that there is none.

- **2026-08-30 — Fenceless is a declared degraded mode.** *Chose:* journal fence optional, the weaker guarantee stated over records. *Over:* requiring a fence no substrate here can supply. *Because:* the guarantee changes and stays checkable.

- **2026-08-30 — The composition's own writes are fenced, not merely gated.** *Chose:* journal fence as an instance capability requirement. *Over:* the gate alone. *Because:* the gate is check-then-act; the fence carries Invariant 2 with or without it.

- **2026-08-30 — The protocol is a compound, adopted by binding.** *Chose:* one composition owning the pair, the critical section, the sweep, the derived-not-remembered rule, positioned codes and the closure inequality; adopters bind and declare deviations from a closed list. *Over:* six methodology rules applied twenty times, or a Transaction pattern the constituents cannot support. *Because:* fourteen exact instances and ~920 KB of protocol prose clear the higher-order composition test, and the invariants are provable only over the pair of processes and the one critical section.

- **2026-09-08 — [Resolve] is modelled as the third writer.** *Chose:* model v4, the operator taking the same critical section on its own seam reading, `SupersedesNamed`, `OperatorSkew` and service identity as modelled dimensions. *Over:* repairing from the gate's prescription. *Because:* the NOT MODELED list had named [Resolve] for three gates and the ninth returned five of seven foundational findings on it.

- **2026-09-08 — Supersession is by name; the operator's seam is the sixth clock.** *Chose:* every closing over an existing record carries supersedes; now injected at the operator's seam. *Over:* the name for the abandoned case only, and an unbounded reading. *Because:* resolving actor names the operator, not a record; a destructive write cannot be decided by a reading nothing bounds. Both are rejected twins.

- **2026-09-08 — kind is an argument; the act's closings are a declared index.** *Chose:* kind first in every action but [Reconcile], `(kind, act_key)` keys, act closings. *Over:* the kind implicit in the caller. *Because:* a signature that omits the kind names the wrong critical section, and `act-landed(outcome_event_id)` had nothing to supply its payload.

- **2026-09-10 — Rewritten in GRACE lang v0.28; nothing but language changed.** *Chose:* labelled rules, rationale under `WHY:`, the Ledger and invariant numbers unchanged. *Over:* the prose draft. *Because:* the migration plan.

- **2026-09-10 — Instance start in controlled form.** *Chose:* five terms, five one-line conditions, the round-trips as bindings. *Over:* inline inequalities marked `STRICTLY`. *Because:* arithmetic lives in term declarations, and a named term gives each expression one owner for the prose-versus-model diff.

- **2026-09-10 — One owner for the conditions of instance start, and there are five.** *Chose:* the section titled *Instance start*, cited by number. *Over:* four sites. *Because:* they drifted three ways at once, and the `max` floor matters: over 432 tuples the old floor admits 324 and breaches on 15, the new admits 288 and breaches on none.

- **2026-09-10 — One owner for where the allowance is spent.** *Chose:* the section titled *Where the allowance goes* — applied or minted, three instants, three payments. *Over:* three sites, one asserting the opposite of another. *Because:* the bare instant is the construction the Lease atom declares non-conforming; mint, then size for the minting.

- **2026-09-10 — Lease is the atom; what a fence costs stays here.** *Chose:* [`atoms/lease.md`](../atoms/lease.md) owning the critical section's lease and both fences as one concept; the binding and the three payments here. *Over:* an atom covering the critical section alone. *Because:* the atom declines what carrying an instant costs; lease-owned findings went 3 → 1 → 0 across the extraction.

- **2026-09-10 — The findings register is extraction-pending.** *Chose:* classify against a forthcoming Condition Register, the two obligations and five conditions named. *Over:* declaring the totality claim false. *Because:* an unclassified register ends up in process memory and loses the outage span a check reads.

- **2026-09-10 — The intents key branches on service identity; the first does not.** *Chose:* the branch once, at the section titled *Which closing stands*. *Over:* an unbranched key. *Because:* unbranched, [Open] step 3's own report-only instruction was a conformance failure for a whole retention period.

- **2026-09-10 — not-open is a precondition on the caller.** *Chose:* the pair [Open] returned, on the action's call stack. *Over:* a retained handle, or deleting the code. *Because:* the handle is the state the execution contract forbids, and the code is the one name an adopter has for the condition.

- **2026-09-10 — The fence earns Invariant 8; the lease gate does not.** *Chose:* the duplicate surfaces count open intents per `(kind, act_key)`; the read gains read bound. *Over:* gating the intent write as the remedy. *Because:* the gated fenceless configuration admits a second live intent and the ungated fenced one does not.

- **2026-09-10 — The sweep's lease is stated, not maximised.** *Chose:* `closure_latency + journal_write_bound`. *Over:* a `max` with a start check. *Because:* the check reduced to `0 > journal_write_bound` whenever closure latency reached completion bound.

- **2026-09-10 — Supersession is transitive; the model does not confirm it.** *Chose:* the standing closing is the one no other closing names; the reachable set counts as one. *Over:* pairwise. *Because:* pairwise collapse reports binding duplicate on the check-6 chain; the model counts supersessions without identifying them.

- **2026-10-07 — The adopter's second frozen round, here: the sweep's upper edge stands a run bound short of the horizon.** *Chose:* run bound subtracted at Term horizon edge and added to the retention floor at Instance start 5; a release on every refusal of [Open]'s intent write (open step 4.5); and act section 10d tombstoned to the four steps that each return their own arm, the entry below having named one arm for all of them, which [Open] could not obey. *Over:* a fresh reading of now at every step of a run, which Primitive policy 18 forbids for good reason. *Because:* the edge is the one guard against closing an act whose closing has been lawfully destroyed, and an applied comparison that is the sole guard of a write has to cover how old its reading can be.

- **2026-10-07 — The adopter's frozen round, here: the adopter says whether its commit answered, and an expired invocation returns its position's own arm.** *Chose:* a reply input on [Yield], answered or lost, since only the adopter's action knows and the release turns on it (yield 5 through 7); the position's existing arm for an invocation past its lease, with the rule that discarded a late reply tombstoned to the one that forbids the write (act section 10c, 10d); the auditor's closure checks kept to intents short of their computed horizon edge, as the sweep is (Check 7.3); not-open out of the two signatures, no action of this page returning it. *Over:* a yield that released by a Term no caller could evaluate — written the unit before. *Because:* the builder's reading walked the adopter's unknown partition into this page and could not build it.

- **2026-10-07 — What the first adopter's passes found here: a duplicate can be ended, an escalation is shown, a refused caller does not queue, and the lease is charged at its worst.** *Chose:* an operator's disposition naming every unsuperseded closing, the one place supersedes names more than one record (resolve 9a), with quiescence read as no duplicate awaiting it; a sixth finding condition for every act the sweep closes as escalated (reconcile step 3.21); a journal read ahead of the take that only refuses (open step 1.6 through 1.8); nine call pauses in lease spend and seven in closure spend, the last reading counted twice, and [Resolve]'s two reads and one write charged beside the sweep's closure; a step-3 failure read back and never retried where no fence is declared (Primitive policy 29a, 32a); no adopter write under the service identity (service identity 3). *Over:* a duplicate reported for good, an obligation no action could meet; and a pre-check under the section alone, which is safe and starves the sweep on the one key it most needs. *Because:* each was reached by a reader tracing the adopter's rules into this page, where twelve gates on this page alone had not gone.

- **2026-10-07 — The first adopter bound, and the binding surface says what the binding found.** *Chose:* probe answers committed only for a store record carrying every field of act key (probe 8); an invocation's outcome data carries only what probe answers (close 5); the sweep reads an adopter's store through probe and no other way (Sweep never 3); the walkthrough's adopter is the pilot's binding as that page states it, the kind `ledger.disclosure` and its vocabulary. *Over:* a binding surface that let a repeatable act be keyed fresh per invocation, where pairing datum 4's obligation has nothing to serialize and a dead intent pairs to another invocation's record; an outcome in two shapes, the invocation's and the sweep's; and a walkthrough whose record names fit no kind's vocabulary. *Because:* Immutable Transaction Ledger (now Immutable Ledger) bound as the pilot adopter and each of these was met in writing its binding; none changes a step of the protocol, and the model reads none of them. The lines against Lease (2026-10-04-a through c) are untouched and are the protocol's next unit, model first.

- **2026-10-07 — A call in flight holds the grant, an unfenced write is sized, and a holder mints its own fences.** *Chose:* no release behind a call in flight, read through one Term so that every release on the page means it (act section 15, Term release); Lease's sizing bound whole for the writes no fence reaches — a call pause bound, a reading for every write, a write floor and a commit floor, a reading ahead of the commit that [Open] takes and may refuse on, and no second issue of a lost-reply write where journal fence is none (act section 16 through 18a, call pause bound 1 and 2, open step 5.4 through 5.6, commit 14c, Primitive policy 37b); a holder value for every sweep take, with act section 14 tombstoned; both lease-derived fence instants minted by the holder. *Over:* a release that shows the landing to the next holder by read-your-writes, which Lease refused as an exception no reader could pin to a time; dropping the retry under a declared fence as well, which would leave the per-write instant with nothing to guard (Ledger 2026-10-07-d); and a twin for the hold, which the model does not reject when it is flipped alone. *Because:* Lease grounded on 2026-10-04 with rules this page broke on its unknown partition, the first place the pilot adopter landed. Model v6 holds with the hold, and with the operator's reading one tick ahead the hold is what stops a false abandonment.

- **2026-10-08 — The pilot's treatment, here: the store's word on an abandonment is owed only under a declared fence.** *Chose:* Invariant 5.6 scoped to a declared commit fence, an operator's abandonment without one resting on Invariant 5.8 and resolve 20a; act section 18a tombstoned to act section 16, which binds Lease Sizing 8 for every unfenced write. *Over:* an invariant every fenceless abandonment broke. *Because:* without a fence the store cannot say an act did not happen, and the page had already admitted the operator's attestation in its place.

- **2026-10-18 — Final Critique 16: reconcile step 3.22 names the substrate's codes, and [Resolve] refuses a malformed disposition before the take.** *Chose:* reconcile step 3.22 opening journal-unavailable for every recording-failure(step-2) and every recording-failure(step-3) reconcile step 3.17 leaves for the next run; resolve 30 landing invalid-request(malformed) with no take and nothing appended for a disposition outside the three forms resolve 1 names. *Over:* a step-2 arm and step-3 arm one build read as [Reconcile]'s own steps, opening journal-unavailable over a journal that answered every call, so that Check 3.3 exempted intents whose closings landed past the window; and a cause the signature exports that no rule landed, which one build refused and another wrote. *Because:* the third round on the text as cured found a rule of the last round's cure that read two ways and an exported code with no source; each cure takes the reading the page's other rules already gave, and the new refusal is decided before the take, ahead of every code the take or a read or write behind the take decides, so it stands beside none.

- **2026-10-18 — Final Critique 15: the recovery_intended write takes the outcome position, the sweep raises journal-unavailable wherever the journal fails it, and [Resolve] on a short lease answers section-unavailable.** *Chose:* reconcile step 3.15 giving every recovery_intended write the outcome position's arms, reconcile step 3.20 escalating one the substrate refuses as outcome-unrecordable, and Term skipped naming the act an unlanded recovery_intended write leaves; reconcile step 2.10 writing nothing, releasing, counting skipped and opening journal-unavailable where step 2's re-read fails, with Term read path naming that re-read and [Open] step 1's; reconcile step 3.22 opening journal-unavailable for every step-2 arm and step-3 arm reconcile step 3.17 leaves for the next run, as the finding's condition already said; resolve 7 a WHEN block that releases and lands section-unavailable, the card Critical Section Unavailable naming the held-but-short arm. *Over:* a recovery_intended write whose failures no rule landed, and an act it left in no bucket; a re-read whose failure one build read as empty and closed over another writer's closing; an outage of the journal's writes the register never recorded, which Check 3.1 then held against a conforming deployment; and an arm on which [Resolve] wrote nothing and answered nothing. *Because:* the second round on the text as cured found three failure arms with no owner, on one of which a build breaks Invariant 2, and a finding whose condition named a side of the journal no rule surfaced, each in older text; each cure takes the reading the page's other rules already gave.

- **2026-10-18 — Final Critique 14: [Refuse] returns the refusal it landed, a sweep run stops at its refused credential, and the register's runs carry their instants.** *Chose:* refuse step 3.12 returning refusal event id wherever the refusal record stands, with the hard alert Primitive policy 25 and 28 and resolve 24 raise for a step-4 at the other three positions, and Term refusal event id declared; reconcile step 2.1 excepting every intent not yet examined when a write under the service identity answers invalid-credential, reconcile step 2.8 forbidding its take and reconcile step 2.9 counting it in unreached; first seen and last seen carrying the run's reading of now. *Over:* a step-4 at [Refuse] that one build answered with the refusal and another with recording-failure(refusal) over a record that had closed the intent; a run obliged to take, probe and write for every kept intent after reconcile step 3.19 forbade its writes, the stop Term unreached names obliged nowhere; and an outage's start and end, which Invariant 4.5 obliges and Check 3.3 compares with an intent's window, held in runs that carry no instant. *Because:* the round on the text as cured found an arm no rule owned, two rules that could not both be obeyed, and a rule resting on fields the page did not declare, each in older text, and each cure takes the reading the page's other rules already gave.

- **2026-10-18 — Final Critique 13: [Resolve]'s closing write lands its own arms, the intents key is a service identity's alone, and an act the sweep cannot write for under its credential is skipped.** *Chose:* resolve 23 pointing at resolve 24 through 29, the resolution position Term position names; Which closing stands 9 and read invocation 8 conditioned on a declared service identity, with Term invocation report saying so; Term skipped naming an act whose write under the service identity answered invalid-credential. *Over:* the outcome position's arms at [Resolve], which land a code [Resolve]'s signature does not carry; an unconditional report of two open intents, which reports a report-only deployment's own instruction as a duplicate; and a tally whose exhaustive list left that act in no bucket. *Because:* the page's first round of its own since the twelfth gate found the first two as rules that cannot both be obeyed on one reachable input and the third as an examined act no bucket of the partition owned, and each cure takes the reading the page's other rules already gave.

- **2026-10-19 — Final Critique 17: [Read Invocation] answers not-known for an invocation id no readable intent carries, and [Open] refuses a kind the bindings table does not serve before it reads or takes.** *Chose:* read invocation 3b answering not-known for an invocation id no readable intent of the act key carries, read invocation 3a returning one entry for an invocation id a readable intent carries, and the card Not Known naming the second answer; open step 1.9 landing invalid-request with no read and no take where the bindings table does not serve kind. *Over:* a given invocation id with no entry to give — the re-entry arm's own, after an [Open] that refused before its intent — on which one build answered not-known and another an empty report; and a kind with no completion bound, no vocabulary and no service identity, which one build refused as invalid-request and another took as a failed take and answered section-unavailable, a retry that never succeeds. *Because:* the fourth round on the text as cured found two inputs no rule owned, both in older text; each cure gives the code the page already gives for the same absence (read invocation 12, the Action wiring table's invalid-request), and the new refusal is decided before the read and the take, so it stands beside no code either decides.

- **2026-10-20 — A writer's re-read, lease check and append are one transaction, and the journal carries no fence.** *Chose:* under the maintainer's ruling of 2026-10-20 14:26Z — Execution Contract Store 2 covers a guard decided across a lease check, the re-read, the lease check and the append being one transaction because the lease's grant and the journal live in the one store — no append lands beside a closing or an intent another writer committed after taking the critical section, so what the page built for that late append goes to Store 2: the journal fence, with its conveyance, its two minted instants and its headroom (journal fence 1 through 4, Allowance 13, Term journal fence, Term journal fence instant, Term journal fence lease terminus, Term journal fence per-write terminus); the fenceless branch and the binding duplicate it left for an operator to end (journal fence none 1 through 6, Which closing stands 6 and 9 through 11, read invocation 7 through 9, reconcile step 1.4, 1.5 and 5.2 through 5.7, resolve 9a, the binding duplicate finding, the closings key and the intents key, the two fields of [Read Invocation]'s answer that reported them, and their card); Invariant 2.4 and 2.5, so Invariant 2.1 binds every deployment; and close step 2.5. The retry only a declared fence admitted goes with the fence (Primitive policy 29a, 37a), so Primitive policy 32a and 37b bind every deployment as they bound this library's and no lost-reply write is issued twice, and Term unfenced write is the bound commit under commit fence none alone. Rules 598 to 563. *Over:* an optional fence on the journal's writes, and a fenceless mode in which a late append could land beside another writer's closing and wait as a binding duplicate for an operator (the 2026-08-30 entries). *Because:* the lease keeps its job for the act outside the store: every lease check, the critical section held across [Open], the commit and [Close], the commit fence and its minted deadline, act section 16 through 18 for the bound commit, and the sizing stand. What the composition does for an act outside the store is unchanged.

- **2026-10-20 — The store's guarantees cited, not restated, and the substrate's step-4 split read as gone.** *Chose:* Capability requirement 12 citing Execution Contract Store 1 through 4 for the journal's store; Capability requirement 7, which made a returned write visible to every later read, tombstoned to Execution Contract Store 2 and Execution Contract Store 3, with Term read-your-writes reading Capability requirement 8 and 12; recording-failure(step-4) no longer read as an append that landed without its placement — Primitive policy 24, 25 and 26 (the intent position's read-back, its proceeding and its bar on a retry) tombstoned to Execution Contract Store 1, and the code taken out of Primitive policy 27, 28 and 40, refuse step 3.3, 3.4 and 3.12, resolve 24 and 25 and reconcile step 3.16, each still reading back an invalid-request(step-4). Rules 601 to 598. *Over:* a journal whose returned write a later read might miss, and a substrate whose record action could land its append and lose its placement. *Because:* the maintainer ruled 2026-10-12 that the corpus takes a store's specification, never the store, and 2026-10-20 that Store 1 binds every store write of one composition action, its constituents' included, while a refused attempt a page keeps as evidence stays a domain choice: Audit Trail's record_action now commits nothing on a recording-failure and keeps its evidence on an invalid-request at step 3 or step 4 (its record action step 7.11), so only an invalid-request(step-4) leaves a record to read back. The critical section held across [Open], the commit and [Close] stays, and with it the journal fence, the fenceless late append and the binding duplicate surfaces: each re-read under the section is separated from its write by a lease reading, and the page does not read Store 2 as reaching a guard decided across an act outside the store. No rule reads an earlier version and Event Log's sequence numbers order the journal, so neither History 1 nor Order 1 is cited; what the protocol does for an act outside the store is unchanged.

- **2026-10-21 — The bounded-closure claim reads as provable.** *Chose:* *provable* (`glossary.md`: shown by the records alone, never by a system's say-so) where the page wrote *the records alone* or *from the records alone*: Invariant 4.1, under which the records reveal, provably, every act whose invocation has yielded or died as an aged intent with no record naming the intent's invocation id, and, by wording alone, Invariant 1's defended-in-line note and the acceptance bar; and *provide* where Composes said no constituent's records *grant* the act's critical section, so *grant* keeps the one meaning the glossary gives it, Lease's live grant; rules 563 to 563, the status draft as it stood. *Over:* the phrase restated at each site. *Because:* the maintainer ruled 2026-10-21 that *shred*, *grant* and *provable* are declared domain terms, each defined once, in `glossary.md`, and that the specifications say them where their meaning stood; the wording of Invariant 4.1 changed and no obligation did.

- **2026-10-23 — A resolution's supersession is no second closing, a declared fence reaches the commit, every holder value is fresh, and an outcome's reference is one the kind declares.** *Chose:* Invariant 2.1 forbidding two unsuperseded closing records, the reading Check 2.1 and the model's Inv2_OneWriter already had, so an operator's resolution over an escalation keeps it; [Open] minting the commit fence deadline from the expiry instant its take answered and returning it beside the pair, and the adopter issuing the commit carrying it (open step 5.7, open step 5.8, commit 13b); operator run id fresh for every [Resolve] call and run id fresh for every run, as Lease Identity 6 asks of every take; an outcome action reference one of the kind's enumerated outcome refs, an operator's other reference refused as malformed (resolve 31); close step 3.7 and 3.8 out of the withdrawn release-and-reject idiom into WHEN blocks, one obligation a line, and Action wiring 5's undeclared examples dropped; open lines 2026-10-23-a and 2026-10-23-b added and 2026-09-10-a widened, these three and 2026-10-18-a now flagged on the page beside their rules; rules 563 to 571. *Over:* Invariant 2.1 as the rewrite of 2026-10-20 left it, binding every deployment with no word for the supersession [Resolve] writes; a deadline the page named and no rule minted or handed over; holder values injected with nothing saying they are fresh; and a disposition's form tested without its reference. *Because:* Final Critique 18's readers traced each on a deployment that keeps every rule: a resolution breaking Invariant 2.1, a commit stalled past the lease landing after the sweep's abandonment under a declared fence, a late release ending another take's grant against Lease Check 5.3, and an operator's outcome under `<kind>.intended` writing a second intent record against Check 2.2. What the composition does for an act it serves is otherwise unchanged.

- **2026-10-24 — The branches no adopter binds are cut, and a closure table owns every input and arm.** *Chose:* under the maintainer's ruling of 2026-10-23 20:13Z, direction (b) and then (c) of the 16:51Z escalation, the declared commit fence branch and the counted(n) deviation deleted, since both adopters, Immutable Transaction Ledger (now Immutable Ledger) and Verified Repair, bind commit fence none and retry terminus lease, each tombstone saying no adopter binds it and an adopter that needs it reopens it with a Decisions entry: the minted deadline and its return (open step 5.7, 5.8), the commit's conveyance and the sweep's abandonment (commit 10 through 13b; reconcile step 3.4, 3.6 and 3.14; Invariant 4.10, 5.6 and 5.7; Check 6.3; External check 6), the minted instant's allowance rules and payments (Allowance 3 and 7 through 12) with Term commit fence deadline, Term abandon edge and Term usable term, and the count (close step 1.3, 3.6; Deviation 3); commit fence and retry terminus no longer bindings, so what held under none holds for every kind (open step 5.4 through 5.6, reconcile step 3.5, Invariant 4.8 and 4.9, commit 15 for commit 14c, resolve 32 for resolve 20a), the sweep counts no abandonment, Check 6.4 reads every abandonment as an operator's, and every cross-seam comparison takes the allowance at the reading (Allowance 4 through 6); a closure table in Action wiring mapping every action's inputs and every answer of record_action, read_record, the range read, take, remaining, release and the probe to where the action lands it and the rule that owns the landing; and the cells no rule owned cured: recording-failure(step-4) read as recording-failure(step-2) at every position, a record action that lands it committing nothing (Execution Contract Database 1; Primitive policy 44); an invalid-query landed where unavailable lands and never surfaced as journal-unavailable (Capability requirement 13, 14); a blank act key, actor reference or credential at [Open] (open step 1.10); an outcome reference outside the kind's at [Close] (close 6); a kind the bindings table does not serve at [Resolve], as at [Open] (resolve 33); an intent event id naming no intent of the act that carries the invocation id (resolve 34); every disposition but an outcome over a standing abandonment (resolve 16b, for resolve 17); [Resolve]'s closing event id (resolve 35); the outcome-unrecordable escalation that answers the same (reconcile step 3.23); and the surfaced count (reconcile step 1.7). Open lines 2026-10-18-d and 2026-10-18-i dissolved by the cut, and 2026-10-18-g, 2026-10-18-j, 2026-10-18-m and 2026-10-18-s cured by the table; no model changed, since the model chooses a fenced or a fenceless store at Init and every run covers both, so each invariant the page keeps is checked over the fenceless half, the page's whole; rules 571 to 540. *Over:* a fenced commit and a counted retry no adopter exercised, where Final Critique 18's second finding lived; and the edges of the six actions found one round at a time. *Because:* the council's counts held and then rose (Final Critique 13 to 18: 3, 3, 4, 2, 2, 4), each round finding the next input or arm with no owner; the maintainer ruled the unbound branches cut first and every input and arm given an owner, so the next round reads a page whose edges are enumerated, and the page's plateau count starts again from that round. What the composition does for an act its adopters bind changes only where the table found no owner.

- **2026-10-27 — The seven open lines decided: the page owns the settling period, an operator's outcome is correctable, each spend bounds the path with no retry, a read that never returns has no answer to give, and the names Audit Trail declares mean one thing on this page.** *Chose:* under the maintainer's ruling of 2026-10-27 16:37Z on the 08:14Z escalation, a per-kind settling period, added to condition 2's retention floor, and an escalation still standing within it of its intent's horizon edge surfaced as closure-at-risk (reconcile step 5.9), which Immutable Transaction Ledger (now Immutable Ledger) cites (2026-10-07-g, option (a)); a correcting resolution, an operator's outcome superseded by a later operator's outcome naming it, with resolve 9 narrowed to the outcomes the invocation or the sweep wrote and Check 6.1 reading the outcome that stands, the model's next version adding supersession chains (2026-10-07-l, (a)); lease spend and sweep lease spend bounding the path with no retry and no lost reply, a retry or a lost reply's read-back running past it under journal write bound 1 to the terminus (2026-10-19-a, (b)); the eight names this page declared in another sense than Audit Trail's renamed — act probe, sweep lease spend, act quiescence, pause bound, clock allowance, closure window, invocation completion bound and sweep cadence — and Audit Trail's retention period and external evidence cited, with Immutable Transaction Ledger and Verified Repair rebinding (2026-10-23-b, (b)); a read outside the critical section that never returns leaving the action no answer to give (Execution Contract Error model 1), and run bound ending a stalled [Reconcile] run (2026-10-25-d, (b)); the findings register kept as declared debt, flagged and on the roadmap's forthcoming row (2026-09-10-a, (b)); and spec-format's Terms item asking a term entry for each name a bracket marker lands on (2026-10-25-b, (a)). *Over:* the Condition Register written now; the deadline left to each adopter, or a purged escalation settled from its own record; correction left to the adopter; a read-back charged to each spend; a specification declaring a constituent's name for its own use; an entry for every declared term; a new rebuild bound. *Because:* every adopter's escalation strands the same way, and only the binding set differs; a wrong operator's outcome is curable on the records; no adopter's numbers change; make all things mean one thing; the corpus writes an entry for each bracketed name; the Execution Contract already answers a call that never returns.

- **2026-10-31 — A [Reconcile] run commits each act's closure as a transaction of its own.** *Chose:* under the maintainer's ruling of 2026-10-31 13:58Z on open line 2026-10-30-c, Database 1's one transaction in a [Reconcile] run is each act's closure (reconcile 8), so a take or a release that answers storage-failure fails that act alone, counted in skipped and left for the next run (reconcile 9, Execution Contract Constituent failure 1), and every act the run already closed stays committed. *Over:* the run as one transaction, failing every closing the run made on one act's lease call. *Because:* a run-wide transaction would hold every section the sweep releases until the run commits, which is unnecessary and risky, and the page's tombstones already read Database 2 per writer's append.

- **2026-11-07 — A refused credential degrades the closing arm to a report, and a kind's retention period changes only when no record placed under the old one is still inside its edges.** *Chose:* under the maintainer's ruling of 2026-11-07 08:54 Central ("ok cool", on the two choices as the 2026-11-01 entry for Final Critique 32 recommended them), closing open lines 2026-10-31-a and 2026-11-01-a: (a) a write under a kind's service identity that answers invalid-credential opens or advances the instance finding credential-refused for the kind, a sixth condition with a span (reconcile step 3.24a), and the run surfaces every aged intent of the kind as closure-at-risk for an operator to close through [Resolve] (reconcile step 3.24b, Invariant 4.11, Invariant 4.7 now naming it); Invariant 4.2 stops asking a writer to close such an intent, Check 3.3 exempts an intent whose window overlaps the span, and Check 3.6 asks the register for the report in its place, so an operator's response time is never sized into a window the sweep alone sets (Instance start 4 stands); (b) a kind's retention period may change, and a change takes effect on a running instance only when every Instance start rule reading it has passed against the change, in Audit Trail Instance start 33's form (Binding 11), a lengthening only when every record placed under the old period is past its retention end under it (Binding 12), a shortening at once (Binding 13), every rule of the page reading the period in force until then (Binding 14), so journal 8, Term retention end, Term horizon edge, open invocations 7, sequence high water 5, Invariant 7.2 and Binding 9 read one period at a time. *Over:* sizing an operator's closing into the closure window, which would bound a person's response time; fixing a kind's retention period while any record placed under it is retained (Binding 2's form), so a new period means binding a new kind. *Because:* the page already degrades the arm for a kind with no service identity (Invariant 4.6), and a refusal is an outage like the two spans Check 3.3 already exempts; the substrate fixes each record's retention at its placement (Retention Window State 5), so a period read from the bound now disagrees with the substrate until the records placed under the old one are gone, and Audit Trail 2026-11-01 (c) already holds a setting's change in this form. *Not modelled:* recoverable-invocation.tla models no credential and no retention change, so no model or twin moves.

## Status

The account the Status line carried after its token until 2026-10-20:

> first draft 2026-08-30 (corpus date); twelve fresh-reader gates on the prose draft through 2026-09-10, council read 7 on the GRACE lang rewrite, council read 50 on the current state. The Ledger carries every gate's counts. Immutable Transaction Ledger (now Immutable Ledger) bound to it as the pilot adopter on 2026-10-07, and the three lines Lease's grounding opened against this page cured the same day against model v6. Three passes read it on 2026-10-07 as the constituent of that adopter and returned four foundational findings against this page and a fifth it shares, cured the same day. Three rounds on the frozen pair returned three more, then two, then one, cured. Final Critique 13, its first round of its own since the twelfth gate, returned three on 2026-10-18, cured; Final Critique 14, the round on the text as cured, returned three more the same day, cured; Final Critique 15, the second round on the text as cured, four more, cured; Final Critique 16, the third, two more, cured; and Final Critique 17, the fourth, two more, cured. The word stays `draft` until a round of its own on the text as cured returns no foundational finding; the passes on this page alone ran, and this line said otherwise for a month (council read 50).

## Ledger

The gate records the Ledger's `last gate:` line carried behind its latest until 2026-10-20, newest first:

- 2026-10-18 — Final Critique 16, the page's fourth round of its own and the third on the text as cured, three fresh readers on free models (GRID DeepSeek V4.1 Flash, EOS Nemotron 3 Ultra, Linus MiMo V2.6 Flash), each handed only the round's reading set, three passes on one text (frozen at 1307806); the round rests on two counted passes: the EOS pass counts for nothing, its reader having read lines 1 to 519 of the page's 1,647 in one capped read and no further — foundational count 2 after triage (7 reports, 4 sent down to refining, 1 rejected), one in fresh text: reconcile step 3.22's step-2 arm and step-3 arm read as [Reconcile]'s own steps as well as the substrate's codes, so one build opened journal-unavailable for a failed take or an act short of its abandon edge over a journal that answered every call, and Check 3.3 then exempted intents whose closings landed past the window; and [Resolve] exported invalid-request(malformed) with no rule landing it, so a disposition outside the three forms resolve 1 names was refused by one build and written by another; 14 refining reports, 5 rhetorical reports; not clean; every foundational finding cured in place, none in a rule the model checks
- 2026-10-18 — Final Critique 15, the page's third round of its own and the second on the text as cured, three fresh readers on free models (GRID DeepSeek V4.1 Flash, EOS Nemotron 3 Ultra, Linus MiMo V2.6 Flash), each handed only the round's reading set, three passes on one text (frozen at c83eafb); the round rests on one counted pass: the EOS pass counts for nothing, its reader having read 1,619 of the page's 1,636 lines, its read tool's third cap unfollowed, and the Linus pass counts for nothing, its reader having read, after its context was compacted, the round's workflow bead and a Gas City skill file outside its reading set — foundational count 4 after triage (7 reports, 3 rejected), all in older text: the sweep's recovery_intended write landed at no position, so no rule owned its failures and an act it left was counted in no bucket of the tally; [Reconcile] step 2's re-read under the critical section had no failure arm, so one build closed an act on step 1's view over a closing another writer had landed; [Resolve] where remaining did not exceed write floor wrote nothing and answered nothing, one build giving section-unavailable and another recording-failure(resolution); and a journal that could not be written raised no journal-unavailable, though the finding's own condition names the write side, so Check 3.1 failed a conforming deployment whose journal took no writes for longer than the window; 12 refining reports, 4 rhetorical reports; not clean; every foundational finding cured in place, none in a rule the model checks
- 2026-10-18 — Final Critique 14, the page's second round of its own and the first on the text as cured, three fresh readers on free models (GRID DeepSeek V4.1 Flash, EOS Nemotron 3 Ultra once LongCat 2.5 Preview's free use ran out, Linus MiMo V2.6 Flash), each handed only the round's reading set, three passes on one text (frozen at 996df09), no lapse; the EOS pass counts for nothing, its reader having read the first 531 of the page's 1,631 lines where its read tool stopped, so the round rests on two counted passes — foundational count 3 after triage (13 reports, 4 sent down to refining, 5 rejected), all in older text: [Refuse] obliged to nothing where a step-4's read-back finds the refusal, so one build returned the refusal and another recording-failure(refusal) over a record that had closed the intent; a sweep run obliged to take, probe and write for every kept intent after a write under the service identity answered invalid-credential, which reconcile step 3.19 forbids, the stop Term unreached names obliged by no rule; and an outage finding obliged to carry the outage's start and end (Invariant 4.5) in a shape whose first seen and last seen are runs with no instant, which Check 3.3 compares with an intent's window; 10 refining reports, 5 rhetorical reports; not clean; every foundational finding cured in place, none in a rule the model checks
- 2026-10-18 — Final Critique 13, the page's first round of its own since the twelfth gate, three fresh readers on free models (GRID DeepSeek V4.1 Flash, EOS LongCat 2.5 Preview, Linus MiMo V2.6 Flash), each handed only the round's reading set, three passes on one text (frozen at ac6bde2, Lease and Audit Trail read whole beside it), no lapse — foundational count 3 after triage (10 reports, 6 sent down to refining, 1 rejected), all in older text: [Resolve]'s closing write given the outcome position, whose arms land recording-failure(outcome), a code its signature does not carry, where resolve 3, 26 and 29 land its own; the intents key obliged (Which closing stands 9, read invocation 8) and forbidden (Which closing stands 10, read invocation 9a) on the two open intents a report-only deployment holds by instruction; and an act the sweep took whose write under the service identity answered invalid-credential, which no bucket of the tally owned; 14 refining reports, 5 rhetorical reports; not clean; every foundational finding cured in place, none in a rule the model checks
- 2026-10-09 — read whole as the constituent of Immutable Transaction Ledger's (now Immutable Ledger's) Final Critique 14, the body at sha1 d58060b6, not a gate of its own — 0 foundational against this page: the one reported, an operator's closing never sized, was rejected by a second triage, [Open] sizing against the kind's largest record, which Term true maximum makes the operator's closing too; the measuring Term's list completed, and the compensation record named the escalation it is
- 2026-10-09 — read whole as the constituent of Immutable Transaction Ledger's (now Immutable Ledger's) confirming round, the body at sha1 11be8053, not a gate of its own — 1 foundational against this page, cured: service identity 3 forbade only the adopter to write under the service identity, so a deployment could share it with the substrate's reconciliation operator and check 5 would report that operator's scan as writes outside this composition (service identity 3, a writer other than the sweep). Also cured: the stall walkthrough's adopter yields at its commit round trip; Term standing closing agrees with Which closing stands 7; open step 4.4 and close step 3.2 cite Primitive policy 19 through 43
- 2026-10-08 — read whole as the constituent of Immutable Transaction Ledger's (now Immutable Ledger's) fourth round on frozen text, the body at sha1 29b0cdb6, not a gate of its own — 1 foundational against this page, cured: open invocations 3 rebuilt the set less every intent a later record named, a recovery_intended included, so an act whose recovered outcome failed to land left the sweep for good (open invocations 3, a later closing record). Also cured: Invariant 3.5a's escalation writes no outcome rather than closing nothing; Check 6.1 passes an operator's outcome among the candidates of an undecidable probe; the pairing datum WHY's failing order corrected to the second invocation dying; the open WHY on step 5.6 says a lost intent reply also fires it
- 2026-10-08 — read whole as the constituent of Immutable Transaction Ledger's (now Immutable Ledger's) third round on frozen text, the body at sha1 f4a91352, not a gate of its own — 1 foundational against this page, cured: Check 6.1 failed a conforming deployment whose adopter's store removes a record ahead of the journal's retention of its outcome, the probe answering not-committed for a lawfully removed record (Binding 9). Two lines readers kept finding were stated in the body before the text was frozen — what a hard alert is, and which read-backs land where — and neither came back
- 2026-10-07 — read whole as the constituent of that page's second round on frozen text, the body at sha1 00d866ff, not a gate of its own — 2 foundational against this page, cured after the third pass: [Open] named no release where its intent write was refused, so a refused caller could hold a key for a completion bound (open step 4.5); the sweep's upper edge allowed for the two clocks and not for the age of a run's one reading, so a closing purged while a run was in flight left its late-retained intent looking open and the run closed it twice (Term horizon edge, Instance start 5)
- 2026-10-07 — read whole as the constituent of that page's first round on frozen text, the body at sha1 63ecdaf2, not a gate of its own — 3 foundational against this page, cured after the third pass: [Yield] could not tell an answered commit from a lost one and so could not know whether to release (yield 5 through 7); an expired invocation at [Refuse] was obliged the outcome arm its signature lacks (act section 10d); an intent whose retention was placed late outlived its closing and failed Check 3 on a conforming deployment (Check 7.3)
- 2026-10-07 — earlier the same day, read as the constituent of that page's three passes, not a gate of its own — 4 foundational against this page, cured: no action could end a binding duplicate, which journal fence none 4 obliged (resolve 9a); an escalation was shown to nobody unless its cause was undecidable (reconcile step 3.21, the sixth condition); refused callers took the critical section to be refused and could stand ahead of the sweep's take for longer than the sweep waits (open step 1.6 through 1.8); lease spend and closure spend were each one call pause short of the gate they exist to clear. A fifth is shared with the adopter: a step-3 recording failure was retried as though nothing had been appended (Primitive policy 29a, 32a)
- 2026-09-10 — twelfth gate, fresh reader, on the draft — 6 foundational, 15 refining and 6 rhetorical, corrected in this round together with the four of gate 11's nine that gate 12 did not re-find. **The round's measurement:** the Lease extraction's own claim held per class — lease-owned findings went 3 → 1 → **0** — while every surviving foundational was a consolidation that had not carried every obligation into its new owner. **Two consolidations this round**, both written in controlled normative form: the allowance's disposition (three passages, one of which asserted of another the opposite of what it said) and the instance-start condition set (four sites, one of which — the walkthrough — breached a condition the page declared eight lines above its own numbers, while the acceptance check that clears instance start named a subset)
- 2026-09-10 — eleventh gate — 9 foundational, 17 refining and 5 rhetorical; the round that measured defect density flat at 18-20 KB per foundational across four gates and diagnosed propagation failure as 16 of 19 caused findings, which is what put the diff-derived obligation sweep into standing round discipline
- 2026-09-10 — tenth gate — 8 foundational
- 2026-09-09 — ninth gate — 8 foundational, and the round that brought [Resolve] into the model as its third writer
- 2026-09-09 — eighth gate, fresh reader, on the draft — 8 foundational, 15 refining and 7 rhetorical, all corrected in-round. Two of the eight were defects in start checks the previous round had copied out of Configuration into an acceptance check so an auditor would run them, and one of those two — the sweep's lease — was **unsatisfiable** wherever `closure_latency` reached `completion_bound`
- 2026-09-08 — seventh gate, fresh reader, on the draft — 7 foundational, 12 refining and 8 rhetorical, all corrected in-round; conceptual independence returned CLEAN for the first time, and foundational timing findings reached zero. Five of the seven landed on [Resolve] or the purge, both on the model's own NOT MODELED list, and two of those five were then reproduced by bringing [Resolve] into the model
- 2026-08-30 — sixth gate, fresh reader, on the draft — 6 foundational, 12 refining and 6 rhetorical, all corrected in-round, and the first round to run with the linter's mechanical checks active against the draft (they caught one defect the round itself introduced)
- fifth gate — 5 foundational, 11 refining and 5 rhetorical corrected in-round
- fourth gate — 8 foundational, 19 refining and 5 rhetorical corrected in-round
- third gate — 4 foundational, 15 refining and 6 rhetorical corrected in-round
- second gate the same day — 6 foundational, 17 refining and 7 rhetorical corrected in-round
- first gate — 8 foundational and 16 refining corrected in-round, 1 refining routed, 5 rhetorical corrected

## Migration notes

- **2026-09-11 — The walkthrough's closure latency, above an earlier draft's.** An earlier draft bound `closure_latency = 5 s`, which breaches condition 5: the second gate fails for any probe latency, the sweep re-opens a recovery intent every cadence and never lands a closing.
- **2026-09-14 — refuse step 0.1 restating close 4 (council read 50).** Council read 50's repoint made refuse step 0.1 an EXACT restatement of close 4: both now oblige the adopter's action, where before they differed by naming [Close] and [Refuse], so `W-duplicate-proposition` reports it where it did not. That is the watch gaining its sharpest specimen rather than a defect arriving — one proposition, two labels, no form to inherit with — and it is left standing as the evidence the inheritance ruling will need.

## Deleted rules

The spec's tombstones, moved here from the page on 2026-11-13 because the spec is done (GRACE-lang Hard invariant 25 and Hard invariant 27, since v0.71): each `Deleted:` line byte for byte and in the page's order, under the heading it stood under there. A tombstone carries no obligation, and each still reserves its label: no rule of [Recoverable Invocation](./recoverable-invocation.md) may carry it again.

### Composes › Journal fence (optional)

```
Deleted: journal fence 1. Execution Contract Database 2 owns it: a writer's re-read, lease check and append are one transaction, and no deployment declares a fence on the journal.
Deleted: journal fence 2. Execution Contract Database 2 owns it: a writer's re-read, lease check and append are one transaction, and the page mints no instant for a fence on the journal.
Deleted: journal fence 3. Execution Contract Database 2 owns it.
Deleted: journal fence 4. Execution Contract Database 2 owns it.
```

### Composes › Under journal fence set to none — the case in this library today

```
Deleted: journal fence none 1. Execution Contract Database 2 owns it: a writer's re-read, lease check and append are one transaction, so no append lands beside another writer's closing.
Deleted: journal fence none 1a. Execution Contract Database 2 owns it: a writer's re-read, lease check and append are one transaction, so no append lands beside another writer's closing.
Deleted: journal fence none 1b. Execution Contract Database 2 owns it: a writer's re-read, lease check and append are one transaction, so no act carries a binding duplicate.
Deleted: journal fence none 2. Execution Contract Database 2 owns it: a writer's re-read, lease check and append are one transaction, so no act carries a binding duplicate.
Deleted: journal fence none 3. Execution Contract Database 2 owns it: a writer's re-read, lease check and append are one transaction, so no act carries a binding duplicate.
Deleted: journal fence none 4. Execution Contract Database 2 owns it: a writer's re-read, lease check and append are one transaction, so no act carries a binding duplicate.
Deleted: journal fence none 5. Execution Contract Database 2 owns it: a writer's re-read, lease check and append are one transaction, so no act carries a binding duplicate.
Deleted: journal fence none 6. Execution Contract Database 2 owns it: a writer's re-read, lease check and append are one transaction, so no act carries a binding duplicate.
```

### Composition logic › Capability requirement

```
Deleted: Capability requirement 2. Non-goal 3 owns it: the range read answers as Event Log's read declares, every record the range holds, passed through Audit Trail unchanged (Audit Trail Action wiring 1 and 5), and no rule here reads a page.
Deleted: Capability requirement 7. Execution Contract Database 2 and Execution Contract Database 3 own it.
Deleted: Capability requirement 16. Execution Contract Scheduled leg 1 owns it.
Deleted: Capability requirement 17. Execution Contract Scheduled leg 1 owns it.
```

### Composition logic › Capability requirement › act section

```
      Deleted: act section 10c. act section 10a owns it: nothing is written on a reply that arrives after the expiry.
      Deleted: act section 10d. open step 4.2b, open step 5.6, close step 1.2c and refuse step 1.2b own it: each action returns its own arm where the lease no longer covers the write.
  Deleted: act section 14. Lease Non-goal 1 owns it: a party takes no key the party holds, the holder included.
  Deleted: act section 18a. act section 16 owns it: Lease Sizing 8, bound for every unfenced write.
```

### Composition logic › Capability requirement › pause bound

```
  Deleted: call pause bound 1. pause bound 1 owns it: the binding is renamed pause bound, a name Audit Trail does not declare (the maintainer's ruling of 2026-10-27).
  Deleted: call pause bound 2. pause bound 2 owns it: the binding is renamed pause bound.
```

### Composition logic › Capability requirement › sweep cadence

```
  Deleted: sweep cadence 1. Execution Contract Scheduled leg 1 owns it.
```

### Composition logic › Capability requirement › intent candidates cap

```
  Deleted: intent candidates cap 1. Execution Contract Logic confinement 15 owns it.
```

### Composition logic › Capability requirement › read cap

```
  Deleted: read cap 1. Execution Contract Logic confinement 15 owns it.
```

### Composition logic › Primitive policy

```
Deleted: Primitive policy 16. Composes 1 owns it: a stamp the composition takes from now is neither the substrate's nor the constituent's.
Deleted: Primitive policy 24. Execution Contract Database 1 owns it.
Deleted: Primitive policy 25. Execution Contract Database 1 owns it.
Deleted: Primitive policy 26. Execution Contract Database 1 owns it.
Deleted: Primitive policy 29a. Execution Contract Database 2 and Primitive policy 32a own it: no deployment declares a fence on the journal, and recording-failure(step-3) is a lost reply at every position.
    Deleted: Primitive policy 37a. Execution Contract Database 2 and Primitive policy 37b own it: no deployment declares a fence on the journal, and a read-back that finds nothing lands the position's existing arm.
```

### Composition logic › Action wiring

```
Deleted: Action wiring 5. commit 2 and commit 9 own it: the adopter closes through [Refuse] every arm the constituent declares pre-commit, and no other.
```

### Composition logic › Action wiring › Open contract

```
   Deleted: open step 2.2. Lease Operation 3 and Operation 4 own it: the host ends a waiting take at the waiter's bound, which no waiter reads; a take unanswered past the longest duration declared for the key and call pause bound is no answer (Lease Term no answer), which act section 17 lands.
   Deleted: open step 5.7. No adopter binds a declared commit fence, whose deadline it minted; an adopter that needs it reopens it with a Decisions entry.
   Deleted: open step 5.8. No adopter binds a declared commit fence, whose deadline it returned; an adopter that needs it reopens it with a Decisions entry.
```

### Composition logic › Action wiring › Close contract

```
   Deleted: close step 1.3. No adopter binds the counted(n) deviation, the one retry terminus beside the lease; an adopter that needs it reopens it with a Decisions entry.
   Deleted: close step 2.5. Execution Contract Database 2 owns it: a writer's re-read, lease check and append are one transaction, and no deployment declares a fence on the journal.
   Deleted: close step 3.6. No adopter binds the counted(n) deviation; an adopter that needs it reopens it with a Decisions entry.
   Deleted: close step 3.6a. No adopter binds the counted(n) deviation; an adopter that needs it reopens it with a Decisions entry.
```

### Composition logic › Action wiring › Refuse contract

```
   Deleted: refuse step 3.2. refuse step 3.3 through 3.8 and refuse step 3.12 own it: each arm of the refusal record is landed there.
```

### Composition logic › Action wiring › Resolve contract

```
Deleted: resolve 5. Lease Operation 3 and Operation 4 own it, as for open step 2.2.
Deleted: resolve 9a. Execution Contract Database 2 owns it: a writer's re-read, lease check and append are one transaction, so no act carries a binding duplicate.
Deleted: resolve 17. resolve 16b owns it: every disposition but outcome over a standing abandonment answers already-abandoned, an abandoned one among them.
Deleted: resolve 20. resolve 32 owns it: no adopter binds a declared commit fence, so the condition it opened held for every kind.
Deleted: resolve 20a. resolve 32 owns it, for every kind.
```

### Composition logic › Action wiring › Reconcile contract

```
   Deleted: reconcile step 1.4. Execution Contract Database 2 owns it: a writer's re-read, lease check and append are one transaction, so the run keeps no closing record for a duplicate scan.
   Deleted: reconcile step 1.5. Execution Contract Database 2 owns it: a writer's re-read, lease check and append are one transaction, so the run keeps no closing record for a duplicate scan.
   Deleted: reconcile step 2.2. Lease Operation 3 and Operation 4 own it, as for open step 2.2.
   Deleted: reconcile step 3.4. No adopter binds a declared commit fence, the one kind the sweep abandoned; an adopter that needs it reopens it with a Decisions entry.
   Deleted: reconcile step 3.4a. No adopter binds a declared commit fence, the one kind the sweep abandoned; an adopter that needs it reopens it with a Decisions entry.
   Deleted: reconcile step 3.4b. No adopter binds a declared commit fence, the one kind the sweep abandoned; an adopter that needs it reopens it with a Decisions entry.
   Deleted: reconcile step 3.6. No adopter binds a declared commit fence, the one kind whose not-committed the sweep held short of abandon edge; an adopter that needs it reopens it with a Decisions entry.
   Deleted: reconcile step 3.6a. No adopter binds a declared commit fence, the one kind whose not-committed the sweep held short of abandon edge; an adopter that needs it reopens it with a Decisions entry.
   Deleted: reconcile step 3.6b. No adopter binds a declared commit fence, the one kind whose not-committed the sweep held short of abandon edge; an adopter that needs it reopens it with a Decisions entry.
       Deleted: reconcile step 3.8b. reconcile step 3.21 owns it, for every cause.
   Deleted: reconcile step 3.14. Invariant 4.9 owns it: no adopter binds a declared commit fence, so the sweep writes no abandoned record, for an outage or otherwise; an adopter that needs the fence reopens it with a Decisions entry.
   Deleted: reconcile step 5.2. Execution Contract Database 2 owns it: a writer's re-read, lease check and append are one transaction, so no act carries a binding duplicate.
   Deleted: reconcile step 5.3. Execution Contract Database 2 owns it: a writer's re-read, lease check and append are one transaction, so no act carries a binding duplicate.
   Deleted: reconcile step 5.4. Execution Contract Database 2 owns it: a writer's re-read, lease check and append are one transaction, so no act carries a binding duplicate.
   Deleted: reconcile step 5.5. Execution Contract Database 2 owns it: a writer's re-read, lease check and append are one transaction, so no act carries a binding duplicate.
   Deleted: reconcile step 5.6. Execution Contract Database 2 owns it: a writer's re-read, lease check and append are one transaction, so no act carries a binding duplicate.
   Deleted: reconcile step 5.7. Execution Contract Database 2 owns it: a writer's re-read, lease check and append are one transaction, so no act carries a binding duplicate.
```

### Composition logic › Action wiring › Read Invocation contract

```
Deleted: read invocation 7. Execution Contract Database 2 owns it: a writer's re-read, lease check and append are one transaction, so no act carries a binding duplicate.
Deleted: read invocation 8. Execution Contract Database 2 owns it: a writer's re-read, lease check and append are one transaction, so no act carries a binding duplicate.
Deleted: read invocation 9. Execution Contract Database 2 owns it: a writer's re-read, lease check and append are one transaction, so no act carries a binding duplicate.
Deleted: read invocation 9a. Execution Contract Database 2 owns it: a writer's re-read, lease check and append are one transaction, so no act carries a binding duplicate.
```

### Composition logic › Bindings › commit

```
  Deleted: commit 10. No adopter binds a declared commit fence, so commit fence is no binding; an adopter that needs it reopens it with a Decisions entry.
  Deleted: commit 11. No adopter binds a declared commit fence, whose conveyance it declared; an adopter that needs it reopens it with a Decisions entry.
  Deleted: commit 12. No adopter binds a declared commit fence; an adopter that needs it reopens it with a Decisions entry.
  Deleted: commit 13. No adopter binds a declared commit fence; an adopter that needs it reopens it with a Decisions entry.
  Deleted: commit 13a. No adopter binds a declared commit fence, the one kind the sweep abandoned; an adopter that needs it reopens it with a Decisions entry.
  Deleted: commit 13b. No adopter binds a declared commit fence, whose deadline the commit carried; an adopter that needs it reopens it with a Decisions entry.
  Deleted: commit 14. commit 15, Invariant 4.9 and reconcile step 3.5 own it: no adopter binds a declared commit fence, so the condition it opened held for every kind.
  Deleted: commit 14a. Invariant 4.9 owns it, for every kind.
  Deleted: commit 14b. reconcile step 3.5 owns it, for every kind.
  Deleted: commit 14c. commit 15 owns it, for every kind.
```

### Composition logic › Bindings › act probe

```
  Deleted: probe 1. act probe 1 owns it: the binding is renamed act probe, since Audit Trail declares probe in another sense (the maintainer's ruling of 2026-10-27).
  Deleted: probe 2. act probe 2 owns it: the binding is renamed act probe.
  Deleted: probe 3. act probe 3 owns it: the binding is renamed act probe.
  Deleted: probe 4. act probe 4 owns it: the binding is renamed act probe.
  Deleted: probe 5. act probe 5 owns it: the binding is renamed act probe.
  Deleted: probe 6. act probe 6 owns it: the binding is renamed act probe.
  Deleted: probe 7. act probe 7 owns it: the binding is renamed act probe.
  Deleted: probe 7a. act probe 7a owns it: the binding is renamed act probe.
  Deleted: probe 8. act probe 8 owns it: the binding is renamed act probe.
```

### Composition logic › Bindings › retry terminus

```
  Deleted: retry terminus 1. journal write bound 1 owns it: [Close] writes only on a remaining queried for the write that exceeds write floor.
  Deleted: retry terminus 2. journal write bound 1 owns it: [Close] writes only on a remaining queried for the write that exceeds write floor.
  Deleted: retry terminus 3. No adopter binds the counted(n) deviation, so retry terminus is no binding and the lease is every invocation's terminus; an adopter that needs it reopens it with a Decisions entry.
```

### Composition logic › Where the allowance goes

```
Deleted: Allowance 3. No adopter binds a declared commit fence, whose deadline was the page's one minted instant, so every cross-seam comparison takes the allowance at the reading (Allowance 4); an adopter that needs it reopens it with a Decisions entry.
Deleted: Allowance 5. Allowance 4 owns it: every cross-seam comparison takes the allowance at the reading, against a stamp of the substrate's or the constituent's (Composes 1); [Open] and [Resolve] decide the writes it gates under the critical section, no pairing rests on a stamp within a window (Invariant 3.4), and the sweep abandons nothing (Invariant 4.9).
Deleted: Allowance 7. No adopter binds a declared commit fence, whose deadline was the page's one minted instant; an adopter that needs it reopens it with a Decisions entry.
Deleted: Allowance 8. No adopter binds a declared commit fence, whose deadline was the page's one minted instant; an adopter that needs it reopens it with a Decisions entry.
Deleted: Allowance 9. No adopter binds a declared commit fence, whose deadline was the page's one minted instant; an adopter that needs it reopens it with a Decisions entry.
Deleted: Allowance 10. No adopter binds a declared commit fence, whose deadline was the page's one minted instant; an adopter that needs it reopens it with a Decisions entry.
Deleted: Allowance 11. No adopter binds a declared commit fence, the one kind condition 3 charged an allowance for; an adopter that needs it reopens it with a Decisions entry.
Deleted: Allowance 12. Invariant 4.9 owns it: no adopter binds a declared commit fence, so the sweep writes no abandoned record; an adopter that needs the fence reopens it with a Decisions entry.
Deleted: Allowance 13. Execution Contract Database 2 owns it: a writer's re-read, lease check and append are one transaction, and the page mints no instant for a fence on the journal.
```

### Composition logic › Which closing stands

```
Deleted: Which closing stands 6. Execution Contract Database 2 owns it: a writer's re-read, lease check and append are one transaction, so no act carries a binding duplicate.
Deleted: Which closing stands 8. Which closing stands 7 owns it: the lowest sequence number stands among unsuperseded closings alone, so no sequence number stands a closing another closing names in supersedes.
Deleted: Which closing stands 9. Execution Contract Database 2 owns it: a writer's re-read, lease check and append are one transaction, so no act carries a binding duplicate.
Deleted: Which closing stands 10. Execution Contract Database 2 owns it: a writer's re-read, lease check and append are one transaction, so no act carries a binding duplicate.
Deleted: Which closing stands 11. Execution Contract Database 2 owns it: a writer's re-read, lease check and append are one transaction, so no act carries a binding duplicate.
```

### Composition-level invariants › Invariant 2 — One writer per act

```
  Deleted: Invariant 2.4. Execution Contract Database 2 owns it: a writer's re-read, lease check and append are one transaction, so Invariant 2.1 binds every deployment.
  Deleted: Invariant 2.5. Execution Contract Database 2 owns it: a writer's re-read, lease check and append are one transaction, so Invariant 2.1 binds every deployment.
```

### Composition-level invariants › Invariant 4 — Bounded closure (safety + liveness)

```
      Deleted: Invariant 4.3b. open step 1.8, open step 3.13, Primitive policy 23 and Capability requirement 6 own it: an outage that fails [Open]'s read lands journal-unavailable, and one that fails the intent record's write or the write's read-back lands recording-failure(intent).
  Deleted: Invariant 4.10. No adopter binds a declared commit fence, the one kind the sweep abandoned, so no abandoned arm degrades: Invariant 4.8 and 4.9 hold for every kind; an adopter that needs it reopens it with a Decisions entry.
```

### Composition-level invariants › Invariant 5 — Recovery is derived, never remembered

```
  Deleted: Invariant 5.6. No adopter binds a declared commit fence, under which the database could say the act did not happen; an adopter that needs it reopens it with a Decisions entry.
  Deleted: Invariant 5.7. Invariant 4.9 owns it: no adopter binds a declared commit fence, so the sweep writes no abandoned record; an adopter that needs the fence reopens it with a Decisions entry.
```

### Generation acceptance › Conformance checks

```
Deleted: Check 6.3. Check 6.4 owns it: no adopter binds a declared commit fence, the one kind the sweep abandoned, so no abandoned record carrying no resolving actor conforms; an adopter that needs the fence reopens it with a Decisions entry.
```

### Generation acceptance › External checks

```
Deleted: External check 6. No adopter binds a declared commit fence, which the database had to honour; an adopter that needs it reopens it with a Decisions entry.
```

### Edge cases › Clock semantics

```
Deleted: Clock semantics 2. Composes 1 owns it.
Deleted: Clock semantics 1. Execution Contract Logic confinement 3 owns it.
```

### Edge cases › Declared deviations

```
Deleted: Deviation 3. No adopter binds the counted(n) deviation; an adopter that needs it reopens it with a Decisions entry.
Deleted: Deviation 3a. No adopter binds the counted(n) deviation; an adopter that needs it reopens it with a Decisions entry.
Deleted: Deviation 3b. No adopter binds the counted(n) deviation; an adopter that needs it reopens it with a Decisions entry.
Deleted: Deviation 3c. No adopter binds the counted(n) deviation; an adopter that needs it reopens it with a Decisions entry.
```
