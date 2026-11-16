---
title: Propagate Consent Revocation Downstream — history
nav_exclude: true
search_exclude: true
---

# Propagate Consent Revocation Downstream — history

The dated record of how [Propagate Consent Revocation Downstream](./propagate-consent-revocation-downstream.md) got here, moved out of the spec on 2026-10-21 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- compositions/propagate-consent-revocation-downstream.md`.

## Decisions

Entries that record a migration rather than a turn the pattern took.

- **2026-08-27 — Authentication happens at this composition's boundary, before the consent state changes.** *Chose:* [Record Consent] and [Withdraw Consent] open with an intent record whose substrate attestation verifies the credential; invalid-credential is a clean pre-state refusal. *Over:* the Action wiring preamble's declaration that the check "cannot be pre-empted at this composition's boundary" and belongs to a deployment pre-check. *Because:* the declaration was false — the composition reaches the same Actor Identity surface at whatever point it chooses to write — and a declared deployment obligation is the answer the methodology refuses.

- **2026-08-27 — Invariant 3 is safety plus liveness, with the propagation-set boundary on the intent event.** *Chose:* the revoke precedes the propagation event; the reachable partial (Revoked, unpropagated) is an accountability gap surfaced and compensated within `compensation_window`; check 2's set boundary is the withdrawal's own `consent.withdrawal.intended` event. *Over:* "commit together or not at all" under a host transaction. *Because:* Consent's revocation is immutable once committed and the substrate's append cannot be withdrawn, so neither member was ever enlistable; what makes the pair sound is the order.

- **2026-08-27 — A consent record is never destroyed by this composition; its retention is Retained for life.** *Chose:* the consent-record Retention Window instance marks the proof-period floor and never reaches `Purged`; check 5 requires `Retained` unconditionally. *Over:* letting the retention reach `Purged` once the audit horizon has run past the record's outcome. *Because:* a consent record is the proof of a grant and of a withdrawal, and this composition has no obligation whose act is to destroy it; Scott ruled it kept on 2026-11-10 ("keep it. why not?"), after the round found the first reasons (Consent's Invariant 8 read against a composition, Retention Window's `Purged` as Consent's forbidden destruction) no longer hold. Where a record's lawful destruction comes, its owner is Defensible Retention, not this composition (Scott, 2026-11-01).

- **2026-08-29 — The scan is bounded at both edges, writes as the composition, and pairs by the records; the indexes are truth-bearing past the horizon.** *Chose:* a declared `administration_completion_bound` below which the reconciliation scan and checks 1 and 7 examine nothing, with the audit horizon as their upper edge; every compensating write attested under a declared service identity behind a `consent.recovery_intended` record, the operator carried in `data`, the intent paired on `intended_at = revoked_at` and `actor_ref = revoked_by` (candidates named where undecidable); both grant-side orphan shapes resolved, the unretained one by re-running the placement from the intent's own retention_policy_ref; every `record_action` transcription carrying `(step)`, the `step-4` arm proceeding as landed and invalid-request never unreachable; and each index's past-horizon half classified truth-bearing under a declared `index_durability`, extraction-pending against Erasure Tombstone. *Over:* an unbounded scan attesting compensations as the absent operator, and "the map is not rebuildable" as the last word on the horizon. *Because:* an unbounded scan compensates in-flight withdrawals beside their own propagation events and reads lawfully purged history as orphans; a compensation the operator did not make cannot be attested as theirs; and a consent record outlives any audit horizon by Consent's own Invariant 8, so the only thing that keeps an old consent withdrawable is the index entry, which must therefore be declared for what it is (the frozen rules of 2026-08-29 — *A reconciliation is bounded at both ends*, *Recovery commits under a declared service identity*, *Intents pair with outcomes*, *A transcribed rejection arm keeps its payload*, *A derived index splits at the horizon*).

- **2026-08-30 — One Granted record per pair, one writer per act, the set derived from the events, the escalation a record, the pairing honest about whose clock stamped each side.** *Chose:* single-active-grant enforced at [Record Consent] step 4 by `Consent.check` under a per-`(subject_ref, purpose)` section, refusing already-granted, stated as Invariant 1(c) and tested by check 4, with the suppression claim made conditional on it; an in-invocation retry bounded by `outcome_retry_attempts` and a scan that takes the per-consent_id section for every consent it touches, so the invocation and the scan never both land a propagation event; `affected_scopes` derived at [Withdraw Consent] step 4 from the `processing.registered` events (the map supplying only its past-horizon entries) with a third scan leg repairing lost bindings; the grant-side scan pairing by actor, subject and purpose inside a symmetric window under a declared `clock_offset_allowance`, narrowing to candidates and escalating a zero-match as an unresolved grant orphan rather than concluding a bypass; check 6's case (v) requiring a *paired* intent, exact by pass-through, so a zero-match on the withdrawal side is the bypass signature; `consent.propagation_escalated` as composition-written audit content under the service identity, carrying the observed cause, in place of "an open compliance finding"; `registrations_cap`, `field_length_cap` and `intent_candidates_cap` with an envelope inequality checked at instance start, the digest withdrawn; the liveness inequality written out with `outcome_write_latency`; `recording-failure(intent | outcome)` on the two signatures that straddle a commit; "atomically" and "together or not at all" replaced at every site by revoke-then-event, ordered, bijective at quiescence modulo compensation; the log read declared once as the substrate's sequence-range read filtered composition-side; the purged answer counted as consistent ahead of any composition-side comparison; and `consent_to_downstream`'s past-horizon half re-homed from Erasure Tombstone to a Processing Register atom *(forthcoming)*, the two key-shaped maps staying with the tombstone; at the closure check, each map element carrying its registration `event_id` so that *past the horizon* is decided by `read_record` answering Purged and never by a timestamp, with check 3 carved out for a purged registration whose surviving `sequence_number` still precedes the boundary; checks 1 and 7 reading `kind: grant` escalations as escalated orphans, never as bypasses; `event_id_width` declared rather than attributed to the substrate; `per_key_serialization` declared as the instance capability the sections rest on, with lease semantics — a lease exactly `administration_completion_bound` long whose expiry is the invocation's terminus, the invocation re-taking the section before any pre-check and writing nothing after it has yielded — and `outcome_retry_attempts × outcome_write_latency ≤ administration_completion_bound` so the counted terminus fits the bound; and the scan's tie-break withdrawn for candidates never chosen. *Over:* a gate keyed per pair over a propagation keyed per consent_id with nothing holding the two to one record; "retry until it lands" beside a scan starting at the bound; a map read as gate input with "rebuild where its integrity is in doubt"; a bypass verdict landed on a comparison of two seams' stamps; an intent's existence standing in for its pairing; an escape branch living in no store; a digest no consumer can read; a bare token on both sides of the commit; atomicity language over two irreversible writes; a tombstone asked to carry a register; a past-horizon membership with no clock-free test; an escalation with no reader; a critical section attributed to the host and named nowhere, and a lost lease that could resume between a scan's look and its append. *Because:* Consent evaluates the latest grant and declines uniqueness for itself, so a composition that keys its two halves differently must supply it or contradict its own suppression claim; two compensators over one act land two outcomes the seal then protects; a short list is not an observable miss; a stamp another seam wrote can differ from this one's by a sign the bound does not have; a check that cannot see the escalation cannot count it; a set that only grows has no unreachable cap; a caller who cannot tell intent from outcome re-runs a committed act; a retention state is the substrate's to answer and a timestamp is not that answer; and a section nobody declared, with a lease nobody bounded, is a second writer waiting for a stall (the frozen rules of 2026-08-30 — *A compensator is exclusive*, *Lawful destruction is answered before absence*, *An outcome is sized before the intent*, *Liveness is arithmetic*, *A stamp from another seam never decides a write alone*, *A composition's own rejection arm carries the retry bit*, and *Capability provenance* frozen with its tells for uses — with §*A derived index is trustworthy only where a miss is observable*, §*Intents pair with outcomes*, §*Recovery commits under a declared service identity* and §*A derived index splits at the horizon*).

- **2026-09-24 — Rewritten in GRACE lang v0.61; nineteen of twenty-one open Ledger lines closed by the rules that now own them.** *Chose:* `Composes`, `Composition state`, `Capability requirement` — which takes the prose's Configuration whole, its per-key serialization split into the consent exclusion and the pair exclusion because the grammar owns the noun *section* — `Primitive policy`, `Audit arm`, `Action wiring`, `Wiring decision` and `Reconciliation` as the surfaces; invariant numbers 1 through 8 unchanged; the record checks renumbered as Conformance checks naming the rule each tests; the edge cases split into Non-goals and three Edge cases families, the two-instance retention entries joining `Retention asymmetry` as its fourth spec. Choices the page left open, each decided by a standing rule: *governed* defined as the record the composition's grant write made — every record of the instance under the reserved write surface — and Invariant 6 split into a floor and a liveness closure (2026-08-30-d); Consent's not-known at the revoke relayed as not-known with an index-anomaly finding rather than as a recording failure (2026-08-26-g — *make all things mean one thing*: recording-failure is a write that did not land); the gate's exposure and the retention policy reference's validation stated as rules (2026-08-30-f, 2026-08-26-b); the bound measured from the seam reading (2026-08-30-h); the knob collisions stated in the terms (2026-08-30-g); the pairing-key deviation declared and no refusal outcome added (2026-08-30-e — *as simple as possible without losing fidelity*); the expiry asymmetry restated on what this composition observes, not on how Consent expires (2026-08-27-c). **One defect fixed in this pass**: the invocation retried its grant event under the pair exclusion while the reconciliation compensated grant orphans under the consent exclusion, so the two could both land a grant event for one consent; the invocation now takes the consent exclusion once the consent id exists, and a grant candidate set whose retention policy references disagree is escalated rather than chosen (Action wiring 16; Reconciliation 29). *Over:* the prose's step lists, a lettered case list, and revision-history prose. *Because:* the rules state each landing once; the two formal lines stay open because the model, not the page, is what they owe.

- **2026-10-21 — The consent lifecycle reads as provable.** *Chose:* *provable* (`glossary.md`: shown by the records alone, never by a system's say-so) where the page wrote *from the records alone*, *records-alone* or their like: Invariant 5.1, under which every governed consent's lifecycle resolves provably from the Consent records, the Audit Trail instance and the indexes, with Invariant 5's heading, and, by wording alone, the Summary, the Wiring decision's principle, the invariants' closing paragraph, the DSAR and regulator examples, the acceptance bar, the [Affected Scopes] term entry and the Article 6(1)(a) standard; every *grant* on the page names a consent grant, a live authorization a withdrawal ends, so none changed; rules 233 to 233. *Over:* the phrase restated at each site. *Because:* the maintainer ruled 2026-10-21 that *shred*, *grant* and *provable* are declared domain terms, each defined once, in `glossary.md`, and that the specifications say them where their meaning stood; the wording of Invariant 5.1 changed and no obligation did.

- **2026-10-21 — The store's guarantees cited, not restated, and a withdrawal's revoke and its propagation event one transaction.** *Chose:* Capability requirement 32 citing Execution Contract Store 1 through 4 for the store the Consent, Permissions, consent retention and Audit Trail instances and the three indexes keep their records in; to Store 3, the indexes' persistence and the index durability held at the Consent store's (Composition state 15, Capability requirement 24, 25); to Store 2, under which an action's reads and the writes they decide are one transaction, the consent exclusion and the pair exclusion with their supply, holding, release and lease and the refusal to run without them, every take of them, an invocation's release of them and the expiry of its lease, the reconciliation's take of the consent exclusion and its skip of a held record, and the bar on [Processing Permitted] taking one (Capability requirement 16 through 22, Action wiring 6, 20, 27, 45 through 47, Reconciliation 7, 8, Concurrency 1 through 4); to Store 1, under which an action's writes commit together, its constituents' included, the rule denying that the revoke and the propagation event form one atomic set, which Store 1 as ruled contradicts (Wiring decision 2), and the machinery that existed only because a crash, a split write or an invocation seen between its writes could leave a partial: the outcome retry attempts with the retry span the administration completion bound had to cover, the in-invocation retries of an outcome with their pre-check and adoption, the proceed-as-landed reading of a recording-failure at the substrate's retention step, which Audit Trail's own rewrite made commit nothing, the outcome position for a placement's storage failure, the consent exclusion a grant took only to keep the reconciliation off it, the reconciliation's run at every process start and its lower edge, and the placement re-run for a Granted record whose placement was refused, with the rule holding a compensating grant event behind it (Capability requirement 11, 12, Audit arm 5, 10, 11, Action wiring 15, 16, 43, 44, Reconciliation 1, 3, 18, 19). By clause, the consent check, the grant write, the derivation and the binding repair no longer name an exclusion (Action wiring 7, 9, 28, Reconciliation 22), and a recording-failure at an outcome's pre-append step lands as recording-failure carrying outcome with no retry ahead of it (Audit arm 12). Rules 268 to 233. *Over:* a revoke and a propagation event no transaction could span, ordered instead, with a consent exclusion and a pair exclusion the host held across an invocation's retries as a lease, and a reconciliation bounded below that compensated what a crash between the writes left — the turns of 2026-08-27 and 2026-08-30, below. *Because:* the maintainer ruled 2026-10-12 that the corpus takes a store's specification, never the store, and 2026-10-20 that Store 1 binds every store write of one composition action, its constituents' included, that a refused attempt a page keeps as evidence stays a domain choice, written in the same transaction as the refusal, and that Store 2 covers a guard decided across a lease check, the lease keeping its job only for an act outside the store. The revoke and the propagation event are store writes, Consent and Audit Trail each supplying theirs under Store 1 through 4, and downstream cessation is Non-goal 1, so the composition makes no act outside the store: a withdrawal's intent, revoke and propagation event commit together, as a grant's intent, grant write, placement and grant event do, and the two exclusions, host mutual exclusions over store-only work, are Store 2's. A placement refused after the grant write is refused and writes nothing (Execution Contract Read 4), so no Granted record waits unretained for a re-run. An Audit Trail refusal of an outcome still leaves the Consent record committed and its event owed (Audit arm 12, 15, 17), as Audit Trail's own refusals leave their evidence (Audit Trail record action step 7.11), so what closes it stays: the pairing on both sides with its candidates, the re-derived set, the pre-check, the recovery identity behind a recovery intent, the recovery flag, the compensation window, the cadence, the outcome write latency and the liveness sum the window must exceed, and the escalation (Capability requirement 6 through 8, 10, 23, Reconciliation 9 through 17, 20, 21, 24 through 35, Invariant 3.5, 3.6, Check 3.5, 3.6, 3.8, 6.4); the administration completion bound stays with them, since the liveness sum, the grant pairing window and the surfacing bound still read it (Capability requirement 9). Audit Trail's evidence rule leaves an invalid-request at its retention step with the event appended, so that answer still proceeds as landed, with the alert (Audit arm 6, 16). The three indexes stay derived indexes outside every action's transaction, as obligation 2 of the section titled Composition state in `execution-contract.md` keeps them, so an index entry still follows the event it derives from and a lost binding is still repaired (Action wiring 24, 25, 31, Reconciliation 20, 22, 23). The propagation set's boundary and the order of an intent and its outcome are the Event Log's own sequence numbers (Clock semantics 1), and no rule reads a record as it stood at a past commit, so the composition cites neither Store 5 nor Order 1. What the composition does for its domain is unchanged.

- **2026-11-04 — A recording failure at an outcome is answered, not refused, so the Consent record it follows stays committed.** *Chose:* [Record Consent] and [Withdraw Consent] answering recording-failure carrying outcome beside the consent id and withdrawn, and refusing only recording-failure carrying intent, so a call whose grant event or propagation event Audit Trail refuses is admitted and its writes commit together, its Consent write among them (Execution Contract Database 1), the outcome owed to the reconciliation (Audit arm 12, 15, 17, Term position, Reconciliation 9 through 17, 24 through 27). *Over:* recording-failure carrying outcome on the refuses line, read as a committed Consent record while Execution Contract Read 4 has a refused call write nothing (open line 2026-10-30-a), and landing it carrying intent, which would have rolled the grant or the revoke back and left a caller's withdrawal lost. *Because:* the ruling of 2026-10-31 16:48Z answered the (b) shape for this page: keep, in the form Authenticated Actor and Login took, the outcome answered so Read 4 holds as written.

- **2026-11-10 — The wait retired: grant and withdrawal are two Recoverable Invocation act kinds.** *Chose:* (Scott, 2026-11-09 9:17 PM Central, "A", and 2026-11-10 7:15 AM Central, the wait ruling, "simple DRY"; the map's D1 through D7 settled under A, 2026-11-10 7:55 AM Central) [Record Consent] and [Withdraw Consent] each bind one act kind, consent.grant keyed by the subject reference with the purpose and consent.withdrawal keyed by the consent id, with the grant transaction and the revoke write as their bound commits; the revoke and the propagation event no longer commit together, the propagation event being the invocation's close, so a withdrawal that crashes between them leaves a Revoked record with an open intent the sweep closes (D1); the grant's pairing datum the invocation's now, injected at Consent's seam, so a grant whose reply was lost closes automatically (D2, Capability requirement 37, 38); the propagation set bounded at the withdrawal intent, a registration landing between the intent and the revoke omitted and named as a window (D3, Cross-record consistency 3); already-granted, already-revoked and already-expired moved from answers to refusals with a refusal record, a Consent or placement storage failure the constituent's own code, and Recoverable Invocation's codes added (D4); an operator's closing of an act detected, not prevented (D5, Invariant 3.1 and 3.2, Check 3.1 and 3.10), with the false-closing alert in the sweep's leg (Reconciliation 40, 41); the events renamed consent.grant.granted and consent.withdrawal.revoked (D6); a Consent record no grant intent carries a write-ownership finding in place of an escalation (D7); the withdrawal repeatable, the grant transaction one commit on External Onboarding's precedent, and the leg on Recoverable Invocation's cadence and run (G9 through G11); Reconciliation 1, 3, 5, 7 through 10, 12 through 14, 17 through 21 and 24 through 37 tombstoned to what owns them, 2, 4, 6, 11, 15, 16, 22 and 23 kept or restated and 38 through 41 new, and Invariant 2.1, 3.4 through 3.6, 6.2, 8.1 and 8.2 tombstoned. *Over:* removing the wait by reversing 2026-11-04, which would let an Audit Trail fault block a withdrawal, and keeping the page's own reconciliation beside Recoverable Invocation, which would have covered the intent-and-outcome pairing twice. *Because:* the wait was self-made: the 2026-11-04 decision left a committed Consent record with its outcome owed so an audit fault never blocked a withdrawal, and the page then built the pairing, the compensation, the recovery identity and the escalation to close it, which Recoverable Invocation owns. *Costs:* a Lease host, the instance's bounds and a sweep; every caller-visible code of both actions that named an outcome or a Consent refusal changes; Invariant 3.1 and 3.2 fall from prevented to detected against an operator's resolve; the propagation set no longer names a registration made in the window between an intent and its revoke; the grant's pairing rests on a deployment obligation on Consent's seam.

## Ledger

The gate records the Ledger's `last gate:` line carried behind its latest until 2026-10-21, newest first:

- 2026-08-27 — authentication-precedence gate, fresh reader — 5 foundational (3 corrected in-round, 2 routed and since closed), 9 refining/rhetorical routed (2 since closed)
- Final Critique 7's 7 refining and 3 rhetorical partly still open

## Deleted rules

The spec's tombstones, moved here from the page on 2026-11-13 because the spec is done (GRACE-lang Hard invariant 25 and Hard invariant 27, since v0.71): each `Deleted:` line byte for byte and in the page's order, under the heading it stood under there. A tombstone carries no obligation, and each still reserves its label: no rule of [Propagate Consent Revocation Downstream](./propagate-consent-revocation-downstream.md) may carry it again.

### Composition logic › Composition state

```
Deleted: Composition state 15. Execution Contract Database 3 owns it.
Deleted: Composition state 22. Execution Contract Derived index 1 owns it.
```

### Composition logic › Capability requirement

```
Deleted: Capability requirement 6. Recoverable Invocation Instance start 4 owns it: the closure window.
Deleted: Capability requirement 7. Recoverable Invocation sweep cadence 2 and 3 own it.
Deleted: Capability requirement 8. Term reconciliation run bound owns it: the run bound counts every write's landing.
Deleted: Capability requirement 10. Recoverable Invocation Instance start 4 and Instance start 5 own it: the worst closure against the closure window, and the retention floor.
Deleted: Capability requirement 11. Execution Contract Database 1 owns it.
Deleted: Capability requirement 12. Execution Contract Database 1 owns it: the composition names no retry span for the administration completion bound to cover.
Deleted: Capability requirement 15. Recoverable Invocation clock allowance owns it: one allowance, set at the instance, covering the widest pair of the clocks.
Deleted: Capability requirement 16. Execution Contract Database 2 owns it.
Deleted: Capability requirement 17. Execution Contract Database 2 owns it.
Deleted: Capability requirement 18. Execution Contract Database 2 owns it: an action's reads and the writes they decide are one transaction, and the composition names no exclusion to release.
Deleted: Capability requirement 19. Execution Contract Database 2 owns it: an action's reads and the writes they decide are one transaction, and the composition names no exclusion to release.
Deleted: Capability requirement 20. Execution Contract Database 2 owns it: an action's reads and the writes they decide are one transaction, and the composition names no exclusion to lease.
Deleted: Capability requirement 21. Execution Contract Database 2 owns it: an action's reads and the writes they decide are one transaction, and the composition names no lease to expire.
Deleted: Capability requirement 22. Execution Contract Database 2 owns it: an action's reads and the writes they decide are one transaction, and the composition names no exclusion for a host to lack.
Deleted: Capability requirement 24. Execution Contract Database 3 owns it.
Deleted: Capability requirement 25. Execution Contract Database 3 owns it.
Deleted: Capability requirement 29. Recoverable Invocation Primitive policy 18 owns it for the sweep, and the write-ownership leg reads the sweep's run reading (Reconciliation 39).
Deleted: Capability requirement 33. Recoverable Invocation run bound owns it: the sweep's own, and the write-ownership leg runs inside it.
Deleted: Capability requirement 34. Recoverable Invocation Instance start 5 owns it: the retention floor.
```

### Composition logic › Primitive policy

```
Deleted: Primitive policy 7. Recoverable Invocation Primitive policy 12 and Primitive policy 13 own it: the invocation open sizes the kind's largest record against the substrate's payload cap and refuses invalid-request for an act whose largest record would not fit.
```

### Composition logic › Audit arm

```
Deleted: Audit arm 1. Recoverable Invocation Primitive policy 19 owns it for the intent of the two bound actions.
Deleted: Audit arm 2. Recoverable Invocation Primitive policy 41 owns it for the intent of the two bound actions.
Deleted: Audit arm 3. Recoverable Invocation Primitive policy 23 owns it for the intent of the two bound actions.
Deleted: Audit arm 4. Recoverable Invocation Primitive policy 43 owns it for the two bound actions; a single write is never retried either (Audit arm 8).
Deleted: Audit arm 5. Execution Contract Database 1 owns it.
Deleted: Audit arm 10. Execution Contract Database 1 owns it.
Deleted: Audit arm 11. Execution Contract Database 1 owns it: an action's writes commit together, so no invocation retries an outcome.
Deleted: Audit arm 12. Recoverable Invocation Primitive policy 30 owns it for the outcome of the two bound actions.
Deleted: Audit arm 14. Recoverable Invocation Invariant 8.3 owns it: recording-failure(intent) is a committed nothing.
Deleted: Audit arm 15. Recoverable Invocation Invariant 8.4 owns it: recording-failure(outcome) is a committed act whose record the sweep closes.
Deleted: Audit arm 17. Recoverable Invocation Primitive policy 42 owns it for the outcome of the two bound actions.
```

### Composition logic › Action wiring

```
Deleted: Action wiring 6. Execution Contract Database 2 owns it.
Deleted: Action wiring 10. Consent Operation 10 owns it: the grant write stamps the grant instant from Consent's own now, and the expiry is the caller's, passed unchanged (Action wiring 9).
Deleted: Action wiring 15. Execution Contract Database 1 owns it.
Deleted: Action wiring 16. Execution Contract Database 1 owns it.
Deleted: Action wiring 20. Execution Contract Database 2 owns it.
Deleted: Action wiring 27. Execution Contract Database 2 owns it.
Deleted: Action wiring 43. Reconciliation 9 and Execution Contract Database 1 own it.
Deleted: Action wiring 44. Reconciliation 9 and Execution Contract Database 1 own it.
Deleted: Action wiring 45. Execution Contract Database 2 owns it: an action's reads and the writes they decide are one transaction, and the composition names no lease to expire.
Deleted: Action wiring 46. Execution Contract Database 2 owns it: an action's reads and the writes they decide are one transaction, and the composition names no lease to expire.
Deleted: Action wiring 47. Execution Contract Database 2 owns it: an action's reads and the writes they decide are one transaction, and the composition names no exclusion to release.
```

### Composition logic › Wiring decision

```
Deleted: Wiring decision 2. Execution Contract Database 1 owns it.
```

### Composition logic › Reconciliation

```
Deleted: Reconciliation 1. Execution Contract Database 1 and Execution Contract Database 3 own it.
Deleted: Reconciliation 3. Execution Contract Database 1 owns it.
Deleted: Reconciliation 5. Recoverable Invocation Invariant 7.3 and Recoverable Invocation Check 7.1 own it: the sweep excludes a purged intent, and propagation history purged stays an auditor's class (Check 3.4).
Deleted: Reconciliation 7. Execution Contract Database 2 owns it.
Deleted: Reconciliation 8. Execution Contract Database 2 owns it: the reconciliation's reads of a record and the writes they decide are one transaction, and the composition names no exclusion for another holder to hold.
Deleted: Reconciliation 9. Recoverable Invocation reconcile step 2.4 through 2.6 and Recoverable Invocation Invariant 2.1 own it: no closed invocation is written for again.
Deleted: Reconciliation 10. Recoverable Invocation Invariant 3.3 owns it, through the withdrawal probe: the pairing datum, the revocation instant, joins an intent to the record by equality.
Deleted: Reconciliation 12. Recoverable Invocation reconcile step 1.2 and Recoverable Invocation reconcile step 3.12 own it: the sweep writes only for an intent, and only what it read.
Deleted: Reconciliation 12a. Recoverable Invocation reconcile step 3.1 and Recoverable Invocation reconcile step 3.2 own it: the probe runs at every run while the intent is open.
Deleted: Reconciliation 13. The withdrawal probe owns it: its outcome data derives the propagation set at the intent's own position (Recoverable Invocation act probe 6).
Deleted: Reconciliation 14. Recoverable Invocation act probe 6 and Recoverable Invocation Invariant 5.3 own it: the probe re-derives the outcome's other fields from the database.
Deleted: Reconciliation 17. Recoverable Invocation Invariant 3.4 forbids it: the act probe pairs on a pairing datum by equality and never on a stamp within a window.
Deleted: Reconciliation 18. Execution Contract Database 1 owns it.
Deleted: Reconciliation 19. Execution Contract Database 1 owns it.
Deleted: Reconciliation 20. Recoverable Invocation Sweep never 1 and Recoverable Invocation Invariant 9.2 own it: the sweep writes no adopter state, and the grant rebuild reads a recovered grant event (Composition state 10).
Deleted: Reconciliation 21. Recoverable Invocation Invariant 3.5a and Recoverable Invocation reconcile step 3.8 through 3.10 own it: an escalation carries the database candidates, and an outcome never does.
Deleted: Reconciliation 24. Recoverable Invocation Invariant 5.1 and Recoverable Invocation reconcile step 3.2a own it: the recovery intent before any recovered outcome.
Deleted: Reconciliation 25. Recoverable Invocation reconcile step 3.2a owns it: the recovery intent's invocation id, intent event id, act key and plan.
Deleted: Reconciliation 26. Recoverable Invocation Invariant 5.2 and the service identity own it: the recovery identity is the binding's service identity.
Deleted: Reconciliation 27. Recoverable Invocation Invariant 5.2, Recoverable Invocation Primitive policy 11a and Term outcome shape own it: the recovered outcome carries the recovery flag, the acting actor reference and the intent event id.
Deleted: Reconciliation 28. Recoverable Invocation reconcile step 3.17 and Recoverable Invocation Primitive policy 29 own it: a closing-position write refused is left for the next run.
Deleted: Reconciliation 29. Recoverable Invocation reconcile step 3.5, step 3.8 through 3.10 and Recoverable Invocation Invariant 2.1 own it: an uncompensable cause is an escalation, once.
Deleted: Reconciliation 30. Recoverable Invocation reconcile step 3.20 and step 3.17 with Recoverable Invocation Invariant 5.1 own it: there is no escalation instant, and a closing the substrate refuses is surfaced as closure-at-risk or outcome-unrecordable.
Deleted: Reconciliation 31. Recoverable Invocation reconcile step 3.5a, Recoverable Invocation reconcile step 3.8a and Recoverable Invocation reconcile step 3.20 own it: an escalation carries its cause and its candidates.
Deleted: Reconciliation 32. Recoverable Invocation reconcile step 2.5 and Recoverable Invocation reconcile step 2.6 own it: only the invocation resolve supersedes an escalation.
Deleted: Reconciliation 33. Recoverable Invocation Invariant 2.1 owns it.
Deleted: Reconciliation 34. Recoverable Invocation reconcile step 3.17 and Recoverable Invocation reconcile step 3.23 own it.
Deleted: Reconciliation 35. Recoverable Invocation reconcile step 3.21, Recoverable Invocation reconcile step 5.9 and the findings register own it.
Deleted: Reconciliation 36. Recoverable Invocation Term hard alert, reconcile step 5.1 and Recoverable Invocation Primitive policy 40 own it.
Deleted: Reconciliation 37. Recoverable Invocation act probe 4, Recoverable Invocation act probe 5 and Recoverable Invocation reconcile step 3.13 own it for the sweep; Reconciliation 38 states it for the leg.
```

### Composition-level invariants › Invariant 2 — Grant audit coverage

```
  Deleted: Invariant 2.1. Recoverable Invocation Invariant 4.2 and Recoverable Invocation Check 3.1 own it: an intent is open, awaiting the sweep, or closed.
```

### Composition-level invariants › Invariant 3 — Revocation propagation completeness

```
  Deleted: Invariant 3.4. Recoverable Invocation Term hard alert and reconcile step 5.1 own it: the sweep alerts on every orphan, and an Invariant MUST NOT oblige an act (GRACE-lang Standard label 14).
  Deleted: Invariant 3.5. Recoverable Invocation Invariant 4.2 and Recoverable Invocation Check 3.1 own it: no intent stands open past the closure window.
  Deleted: Invariant 3.6. Recoverable Invocation Invariant 5.1 and Recoverable Invocation Invariant 5.2 own it: a recovered outcome is written behind a recovery intent under the service identity and carries the recovery flag.
```

### Composition-level invariants › Invariant 6 — Consent-record retention floor

```
  Deleted: Invariant 6.2. Invariant 6.1 owns it: the retention placement is inside the grant transaction (Action wiring 13), so a committed Consent record carries a consent retention.
```

### Composition-level invariants › Invariant 8 — Authentication precedes commitment

```
  Deleted: Invariant 8.1. Recoverable Invocation Invariant 1.1 owns it: the commit follows the intent, whose record verified the credential.
  Deleted: Invariant 8.2. Recoverable Invocation Invariant 1.1 owns it: the commit follows the intent, whose record verified the credential.
```

### Generation acceptance › Conformance checks

```
Deleted: Check 2.1. Recoverable Invocation Check 3.1 owns it.
Deleted: Check 3.5. Recoverable Invocation Check 3.1 owns it.
Deleted: Check 3.6. Recoverable Invocation Check 1.1, Recoverable Invocation Check 2.5 and Recoverable Invocation Check 5.1 own it.
Deleted: Check 3.7. Recoverable Invocation reconcile step 3.5a and step 3.20 own it: an escalation carries its cause.
Deleted: Check 3.8. Recoverable Invocation Check 4.1 owns it.
Deleted: Check 3.9. Recoverable Invocation Check 4.1 owns it.
```

### Edge cases › Clock semantics

```
Deleted: Clock semantics 2. Recoverable Invocation Primitive policy 5 owns it: every join pairs on the invocation id.
Deleted: Clock semantics 3. Recoverable Invocation Allowance 4 and Allowance 6 own it.
```

### Edge cases › Concurrency

```
Deleted: Concurrency 1. Execution Contract Database 2 owns it.
Deleted: Concurrency 2. Execution Contract Database 2 owns it.
Deleted: Concurrency 3. Execution Contract Database 2 owns it.
Deleted: Concurrency 4. Execution Contract Database 2 owns it: an action's reads and the writes they decide are one transaction, and the composition names no exclusion for [Processing Permitted] to take.
```
