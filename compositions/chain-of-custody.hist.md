---
title: Chain of Custody — history
nav_exclude: true
search_exclude: true
---

# Chain of Custody — history

The dated record of how [Chain of Custody](./chain-of-custody.md) got here, moved out of the spec on 2026-10-20 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- compositions/chain-of-custody.md`.

## Decisions

Entries that record a migration rather than a turn the pattern took.

- **2026-06-11 — Invariant 4's compensated arm is in the model, not idealized away.** *Chose:* re-derive the model over sequential sub-writes with compensation. *Over:* the original model, which committed the sub-writes as one atomic action. *Because:* the Provenance write is irreversible and the audit append cannot be withdrawn, so the compensated path is the design.

- **2026-08-26 — [Transfer Custody] resolves the outgoing custodian before it authenticates, and authenticates before it commits.** *Chose:* a read-only resolution step, then the intent record under the outgoing custodian's credential, then the Provenance call; invalid-credential restored to all five signatures, reversing Final Critique 5's F2 on new grounds. *Over:* declaring the pre-check "a deployment obligation" (Final Critique 5's F-6 closure), or authenticating the incoming caller, the only principal available earlier. *Because:* a declaration discharges nothing the records can show, and the guarantee names the outgoing custodian, a principal produced by the commit.

- **2026-08-27 — The verification presentation is keyed by audit-log position, not by custody entry.** *Chose:* original_event_payloads keyed by `sequence_number`, with [Verify Custody] assembling each entry's presentation from the covering range `read_record` names. *Over:* a map keyed by `entry_id` holding one payload per entry, or a wiring rule requiring per-event cadence. *Because:* the substrate's rule is that a seal commits to a sequence range whose members include intent records and unrelated actions carrying no `entry_id`; an entry-keyed map cannot present that set under any cadence but per-event, and pinning the cadence would trade a representational fix for a deployment constraint.

- **2026-08-29 — The scan is bounded at both edges, pairs by parameters and names candidates, and writes as the recovery identity behind a recovery record; the outcome's step decides its landing.** *Chose:* `custody_completion_bound` below and the audit horizon above for the reconciliation scan; an orphan entry paired to its intent by chain, custodian, and the parameters the entry realizes, with `intent_event_candidates` where more than one unmatched intent matches; every scan write under `recovery_identity` behind `custody.recovery_intended` (the in-invocation retry keeping the custodian's credential and no marker); `recording-failure(step-4)` and the retention-source invalid-request at an outcome record read back and treated as landed at all five actions; `compensation_window`, `reconciliation_cadence` and `index_durability` declared; Invariant 4's "committed atomically or" restated as ordered. *Over:* an unbounded scan whose crash-side retry had no identity it could honestly use, and "all three arms surface as recording-failure" at the outcome. *Because:* an unbounded scan mints a second outcome beside an in-flight invocation's and re-emits lawful destruction as orphans; the custodian's credential is never persisted; and the substrate's step-4 arm means the event exists (the frozen rules of 2026-08-29 — *A reconciliation is bounded at both ends*, *Intents pair with outcomes*, *Recovery commits under a declared service identity*, *A transcribed rejection arm keeps its payload*).

- **2026-08-30 — One writer per entry, the purged answer first, the attestor named, the divergence landed, the genesis leg honest about what it can find.** *Chose:* an in-invocation retry bounded by `outcome_retry_attempts` and a scan that takes the per-chain section for every chain it touches, so the invocation and the scan never both land an outcome for one entry, with a binding-duplicate collision rule on the rebuild and check 5 quantified over the log; [Verify Custody] branching on retention state before any composition-side membership check, so a purged entry lands `failed-verification(purged)` and [Custody Proof Complete] stays reachable after a purge; an `actor_match` field and check-1 clause comparing the attestation's surviving `actor_ref` to the entry's custodian; `rejected(principal-divergence)` at [Transfer Custody] step 5 with no outcome written and a scan that never compensates it; `genesis_lookup` declared as an instance capability requirement, the genesis leg downgraded to *surfaced* without it; `recording-failure(intent | outcome)` on every signature; the liveness inequality written out with `outcome_write_latency`; `intent_candidates_cap` sizing the compensation envelope; and, on the closure check, `chain_serialization` declared as the instance capability the one-writer rule rests on, with a lease exactly the bound long whose expiry is the invocation's terminus, the transfer leg pairing by chain and recipient before it compares actors so a divergence is reachable at the scan, the zero-match landing (escalate, never compensate), and checks 2 and 4 quantified over the log. *Over:* "retry until it lands" beside a scan starting at the bound; a membership check ahead of the constituent's purged short-circuit; a check that confirmed the credential was valid and not whose it was; a code in the signature with no landing; a genesis leg that presumed a lookup Provenance declines; a bare token on both sides of the commit. *Because:* two compensators over one act land two outcomes the seal then protects; a lawfully destroyed payload is not one the caller failed to supply; a valid credential attesting a step its holder did not perform is the forgery the proof exists to catch; a committed entry nobody authenticated cannot be attested later without inventing an attribution; and a caller who cannot tell intent from outcome re-runs a committed act (the frozen rules of 2026-08-30 — *A compensator is exclusive*, *Lawful destruction is answered before absence*, *A composition's own rejection arm carries the retry bit*, *Liveness is arithmetic*, *An outcome is sized before the intent*, and *Capability provenance* frozen — with §*Authentication precedence*'s binding half and §*A transcribed rejection arm*'s fourth tell).

- **2026-09-24 — Rewritten in GRACE lang v0.61; forty-one of forty-three open Ledger lines closed by the rules that now own them.** *Chose:* `Composes`, `Composition state`, `Capability requirement` — which takes the prose's Configuration whole, the per-chain section renamed the chain exclusion because the grammar owns the noun *section* — `Primitive policy`, `Audit arm`, `Action wiring`, `Wiring decision` and `Reconciliation` as the surfaces, with the verdict classes as their own `Verdict` family; invariant numbers 1 through 5 and 7 unchanged, Invariant 6 tombstoned to Composes 5; the record checks renumbered as Conformance checks naming the rule each tests; the edge cases split into Non-goals and five Edge cases families. Choices the page left open, each decided by a standing rule: the blank credential answered invalid-credential in every action (2026-08-26-e, -r, 2026-08-30-j — *make all things mean one thing*); binding-unknown given a clock-free predicate — an unbound entry earlier than an entry whose event is already purged — and read as a durability finding in the proof and the checks alike (2026-08-30-a, -b, 2026-08-26-i, -u); the substrate's unverifiable reasons relayed unchanged and its compensation-window qualifier carried beside the verification, never in the retention state (2026-08-26-h, -p, -q); the reconciliation's window and cadence given names of their own, apart from the substrate's knobs (2026-08-30-l); the metadata taken off every audit write, and so off the caps (2026-08-26-v — *as simple as possible without losing fidelity*); the purged half named against Erasure Tombstone with the persist-at-purge alternative dropped (2026-08-30-c — *generalize nothing*); and one genesis pairing key, stated once (2026-08-30-n). *Over:* the prose's step lists, a verdict with three unlanded outcomes, and an alternative that rode a cascade the composition does not wrap. *Because:* the rules state each landing once; the two formal lines stay open because the model, not the page, is what they owe.

- **2026-10-20 — The store's guarantees cited, not restated, and a custody action's writes one transaction.** *Chose:* Capability requirement 28 citing Execution Contract Store 1 through 4 for the store the chain, the substrate and the binding index keep their records in; the rules restating what that store guarantees tombstoned to it — the binding index's durability and the auditor's reading of it, the chain exclusion with its supply, holding, release, lease and the refusal to start without it, an invocation's release of it and the expiry of its lease, the reconciliation's take of it and the host's declaration an auditor read (Composition state 12, Capability requirement 13, 14, 16 through 21, Action wiring 6, Audit arm 20 through 22, Reconciliation 5, 6, Concurrency 1, 2, External check 4, 5); the rule denying that a Provenance entry and its outcome event commit together, which Store 1 as ruled contradicts (Wiring decision 2); and the machinery that existed only because a crash, a split write or an invocation seen between its writes could leave a partial: the reconciliation's lower edge, the outcome retry attempts and the in-invocation retries with their pre-check and adoption, the read-back of a recording-failure at the substrate's retention step, which Audit Trail's own rewrite made commit nothing, the escalation of an invalid-request(step-4) whose event the read-back cannot find, which Audit Trail's evidence rule leaves appended, a recording-failure carrying outcome for a Provenance read that fails after the write, the mid-flight revocation and its re-attestation, which the one transaction's read of the actor registry forecloses, the principal divergence at [Transfer Custody], which the one transaction's resolution read forecloses, and the auditor's durability reading of an unbound pre-horizon entry (Reconciliation 3, Capability requirement 8, Audit arm 5, 11 through 18, Action wiring 10, 23 through 25, Check 5.4). Rules 263 to 228. *Over:* a Provenance write and an outcome append no transaction could span, so that each custody action was ordered across a durability boundary — the entry committed first, its outcome appended second — with a chain exclusion the host held across the invocation's retries as a lease, and a reconciliation that took the exclusion and paired what a crash between the writes left. *Because:* the maintainer ruled 2026-10-12 that the corpus takes a store's specification, never the store, and 2026-10-20 that Store 1 binds every store write of one composition action, its constituents' included, while a refused attempt a page keeps as evidence stays a domain choice, written in the same transaction as the refusal. The Provenance write and the audit append are store writes, Provenance and Audit Trail each supplying theirs under Store 1 through 4, so a custody action's intent, entry and outcome commit together; and the chain exclusion, a host mutual exclusion over store-only work, is Store 2's, under which a custody action's reads of a chain and the writes they decide are one transaction. An Audit Trail refusal at an outcome still leaves the custody entry committed and its record owed (Audit arm 19, 24, 26), as Audit Trail's own refusals leave their evidence (Audit Trail record action step 7.11), so what closes it stays: the reconciliation's pairing, its candidates and their cap, the genesis lookup, the recovery identity behind a recovery intent, the re-read before a compensating event, the custody compensation window and the liveness sum it must exceed, and the escalation; the custody completion bound stays with them, since the liveness sum and the pairing still read it (Capability requirement 12, Reconciliation 16, 17). The binding index stays a derived index outside every action's transaction, as obligation 2 of the section titled Composition state in `execution-contract.md` keeps it, so its rebuild on a miss and the binding-unknown reading of an entry no rebuild can reach stay (Composition state 7, Action wiring 36). Custody records are ordered by the Event Log's and Provenance's own sequence numbers (Clock semantics 1) and no rule reads a record as it stood at a past commit, so the composition cites neither Store 5 nor Order 1. What the composition does for its domain is unchanged.

- **2026-10-27 — The principal divergence retired: the one transaction forecloses it.** *Chose:* the transfer leg paired by Term realize, like every other leg, so an orphan transferred entry pairs to the unmatched intents it realizes, from the custodian each authenticated, and a transfer written outside the composition's surface that no intent realizes lands orphan-unpaired, surfaced and escalated (Reconciliation 10 through 12, Invariant 4.5); Reconciliation 16, 19 and 20, Invariant 4.6, the principal-divergence finding, Term confirmed transfer and Action wiring 22's confirmation read deleted, each tombstoned to its owner, with Action wiring 26 recording custody.transferred under the resolved custodian; Term compensable orphan paired to at least one intent, so the zero-candidate orphan Reconciliation 12 never compensates is one Invariant 4.5 escalates; and the formal model re-derived for this protocol, its in-invocation retry gone (chain-of-custody.tla, 8 twins, 6 probes). Rules 224 to 219. *Over:* keeping the divergence at the reconciliation and opening it only where no paired intent realizes the entry, the first cure open line 2026-10-27-a named. *Because:* the maintainer ruled 2026-10-27 that the one transaction already forecloses a divergence at the invocation: a transfer's resolution read and its write are one transaction (Execution Contract Database 2), so a committed transfer's outgoing custodian is its intent's, and what the reconciliation's comparison still caught was a write outside the composition's surface, which orphan-unpaired lands, and a false divergence between two orphans of one chain (2026-10-27-a). It turns the 2026-08-30 entry's divergence landing, which the 2026-10-20 rewrite kept. Open lines 2026-08-30-v and 2026-10-27-a close as dissolved, and 2026-08-29-a closes: the re-derived model carries the recovery identity, the recovery intent and the aged-intent edge.

- **2026-11-10 — The wait retired: the five custody actions are five Recoverable Invocation act kinds.** *Chose:* (Scott, 2026-11-09 9:17 PM Central, "A", and 2026-11-10 7:15 AM Central, the wait ruling, "simple DRY"; the map rounds/coc-ri-map-2026-11-10.md, its directions settled under A, 2026-11-10 7:55 AM Central) the five custody actions each bind one act kind, custody.originate keyed by the artifact reference, the custodian reference and the genesis type under the minted-key deviation, with the origination transaction its commit, custody.transfer, custody.transform, custody.disclose and custody.archive keyed by the chain id, every kind repeatable (A: act kinds split by the wait, G4); the intent commits at the open and the outcome at the close, so an Audit Trail fault at the outcome leaves an open intent the sweep closes, and Provenance's storage-failure is a pre-commit refusal (A: an audit failure composes rather than committing a partial); the transfer's resolution read left ahead of the open, and the transfer transaction re-reading the holder and refusing not-current-custodian where it changed, so the attribution the one transaction gave is kept by a refusal (A: a collision becomes a refusal, G1; Action wiring 63 through 65); the invocation's now injected into Provenance's seam as every kind's pairing datum, so a lost reply closes itself (G2, Capability requirement 34, 35); every custody action's caller-visible codes Recoverable Invocation's, recording-failure(outcome) answered and not refused, every Provenance refusal leaving a refusal record, and the events renamed custody.<kind>.* with `recovery` for `cascade_recovery` (A: codes change to Recoverable Invocation's, G5); an operator's outcome detected, not prevented, by the binding-duplicate finding and Check 5.1, 5.2, with the false-closing alert in the leg (A: detected, not prevented, with an alert, G6; Reconciliation 32); an intent whose invocation died before its commit escalated for an operator in place of being read silently as a refused attempt (G8); an entry no intent carries a write-ownership finding in place of orphan-unpaired and its escalation (A: a record with no intent becomes a finding, G9); the leg on Recoverable Invocation's cadence, run and run reading, its enumeration taken at the run's start and its aged edge excluding an entry whose intent the horizon may have destroyed (G10); Term actor match reading an operator's outcome as match carrying recovery (G7). Composes 11, Capability requirement 9 through 12, 27, 29 through 32, Primitive policy 14, every live Audit arm rule, Action wiring 1, 3, 4, 7, 60, Reconciliation 1, 8 through 10, 12 through 15, 17, 18, 21 through 29, Invariant 1.3, 1.4, 4.2, 4.5, 7.1, Check 1.4, 1.5, 5.6 through 5.8, 6.1 and Clock semantics 3 tombstoned to what owns them; Composes 12 through 16, Capability requirement 34 through 39, Audit arm 29, Action wiring 63 through 68, Reconciliation 30 through 34, Check 5.9, 7.3, External check 6, Non-goal 12, 13 and Cross-record consistency 1 new; the closure table drafted. Rules 235 to 202. *Over:* removing the wait by reversing 2026-10-20, so that an Audit Trail refusal of the outcome fails the whole custody action, which would make the substrate's health a precondition of recording a step whose artifact has already changed hands — the gap in custody the pattern exists to prevent — and keeping the page's own reconciliation beside Recoverable Invocation, which would have covered the intent-and-outcome pairing twice. *Because:* the wait was self-made: the 2026-10-20 decision left a committed custody entry with its record owed so an Audit Trail fault never undid an irreversible Provenance write, and the page then built the pairing, the candidates and their cap, the recovery identity, the compensation window, the liveness sum and the escalation to close it, which Recoverable Invocation owns; nineteen of the thirty-three foundational findings of Final Critique 10 through 17 sat in that machinery. It turns the 2026-10-20 entry's "what closes it stays" and, in part, the 2026-10-27 entry: the one transaction no longer spans the transfer's resolution and its write, and the re-check restores the foreclosure. *Costs:* a Lease host, the instance's bounds and a sweep; every custody action's caller-visible codes; a new refusal at [Transfer Custody] for a holder that changed between the resolution and the commit; the pairing rests on a deployment obligation on Provenance's seam; operator work for an intent whose invocation died before its commit; Invariant 4.3 and 4.4 fall from prevented to detected against an operator's resolve.

- **2026-11-21 — The eighteen open lines are closed.** *Chose:* the custody enumeration is a declared direct invocation of the Event Log instance Audit Trail carries (Composes 17), as Customer Onboarding and Capability-Backed Sharing declare it; [Verify Custody] never calls the verification for a purged event and counts an empty presented payload as not carried (Action wiring 39, 71), checks the binding's entry id among the compared fields, and names a young entry closing-pending, not binding-gap (Action wiring 70, Verdict 20); a transfer to the holder the chain shows is refused same-custodian before the open, the chain itself being the key a lost answer leaves (Action wiring 75); the binding rebuild runs at [Verify Custody] alone and orders across both sequences by the Event Log sequence (Composition state 7, Clock semantics 4, 5); the minted id width is a required setting (Capability requirement 24, 41); the missing sequence numbers and the payload map are bounded by the covering ranges (Action wiring 72, 73); the intent's unclosed states named as members of Recoverable Invocation's state value set, and the attestation reason and the failed seal named by the prefix Audit Trail's steps give them (Term unclosed intent state, Term attestation reason, Term failed seal, which now holds a seal-mechanism reason too); Check 1.2 and Check 4.1 are narrowed or widened to what they test, and Check 5.1 and 5.2 to the invocation-written outcome events, with Check 5.10 and 5.11 for an operator's. *Over:* a retry key as a new input of [Transfer Custody], a new verdict class for an unbound entry's failure beside the binding-gap, widening Invariant 4.3 and 4.4 to events an operator writes unchecked, and leaving the open lines for a round to find. *Because:* a pattern done with its open lines in its text is not done (Scott, 2026-11-19), and each cure is the one a direction of Scott's of 2026-11-19 or a rule of the corpus decides (Execution Contract Substrate composition invocation, Logic confinement 18, Audit Trail verify record steps 3.2, 3.4, 5.2, 5.4, Primitive policy 27). The cost: a chain whose every bound event is purged completes on its continuity check and lawful disposals alone, and a partially-purged range names no live member left unpresented (Verdict 21, Action wiring 74); the carried-out lines (Recoverable Invocation's Deviation 2, Audit Trail's enumeration surface) stand as evidence for those pages, not as this page's findings.

## Ledger

The gate records the Ledger's `last gate:` line carried behind its latest until 2026-10-20, newest first:

- 2026-08-26 authentication-precedence gate — 1 foundational routed (since closed), 2 foundational and 8 refining/rhetorical corrected in-round, 7 refining and 5 rhetorical routed (1 refining since closed)
- Final Critique 7's 2 other foundational (since closed), 7 refining and 4 rhetorical also routed

## Deleted rules

The spec's tombstones, moved here from the page on 2026-11-13 because the spec is done (GRACE-lang Hard invariant 25 and Hard invariant 27, since v0.71): each `Deleted:` line byte for byte and in the page's order, under the heading it stood under there. A tombstone carries no obligation, and each still reserves its label: no rule of [Chain of Custody](./chain-of-custody.md) may carry it again.

### Composes

```
Deleted: Composes 8. Composes 9 owns it.
Deleted: Composes 11. Recoverable Invocation Action wiring 4 and Action wiring 6 own it: a bound custody action writes its intent, outcome and refusal records through the invocation open, close and refuse.
```

### Composition logic › Composition state

```
Deleted: Composition state 12. Execution Contract Database 3 owns it.
```

### Composition logic › Capability requirement

```
Deleted: Capability requirement 7. Execution Contract Logic confinement 15 owns it: a required setting blank keeps the instance from starting.
Deleted: Capability requirement 8. Execution Contract Database 1 owns it.
Deleted: Capability requirement 9. Recoverable Invocation Instance start 4 owns it: the closure window.
Deleted: Capability requirement 10. Recoverable Invocation sweep cadence 2 and sweep cadence 3 own it.
Deleted: Capability requirement 11. Recoverable Invocation run bound owns it: the sweep's own, and the write-ownership leg runs inside it.
Deleted: Capability requirement 12. Recoverable Invocation Instance start 4 owns it: the worst closure against the closure window.
Deleted: Capability requirement 13. Execution Contract Database 3 owns it.
Deleted: Capability requirement 14. Execution Contract Database 3 owns it.
Deleted: Capability requirement 16. Execution Contract Database 2 owns it.
Deleted: Capability requirement 17. Execution Contract Database 2 owns it: a custody action's reads of a chain and the writes they decide are one transaction, and the composition names no exclusion to release.
Deleted: Capability requirement 18. Execution Contract Database 2 owns it: a custody action's reads of a chain and the writes they decide are one transaction, and the composition names no exclusion to release.
Deleted: Capability requirement 19. Execution Contract Database 2 owns it: a custody action's reads of a chain and the writes they decide are one transaction, and the composition names no exclusion to lease.
Deleted: Capability requirement 20. Execution Contract Database 2 owns it: a custody action's reads of a chain and the writes they decide are one transaction, and the composition names no lease to expire.
Deleted: Capability requirement 21. Execution Contract Database 2 owns it: a custody action's reads of a chain and the writes they decide are one transaction, and the composition names no exclusion for a host to lack.
Deleted: Capability requirement 27. Recoverable Invocation Primitive policy 18 owns it for the sweep, and the write-ownership leg reads the sweep's run reading (Reconciliation 31).
Deleted: Capability requirement 29. Recoverable Invocation Instance start 5 owns it: the retention floor.
Deleted: Capability requirement 30. Recoverable Invocation clock allowance owns it: one allowance, set at the instance, covering the widest pair of the clocks.
Deleted: Capability requirement 31. Recoverable Invocation clock allowance and Recoverable Invocation Instance start 4 own it: the allowance is the instance's setting, and a start condition reading a blank one does not pass.
Deleted: Capability requirement 32. Recoverable Invocation run bound owns it: the sweep's own, and the write-ownership leg runs inside it.
```

### Composition logic › Primitive policy

```
Deleted: Primitive policy 14. Recoverable Invocation Term outcome shape and Recoverable Invocation Check 2.5 own it: the invocation close writes the outcome under the intent's actor reference, which Primitive policy 16 and Action wiring 20 make the acting custodian.
```

### Composition logic › Audit arm

```
Deleted: Audit arm 1. Recoverable Invocation Primitive policy 19 owns it for the intent of the five bound actions.
Deleted: Audit arm 2. Recoverable Invocation Primitive policy 41 owns it for the intent of the five bound actions.
Deleted: Audit arm 3. Recoverable Invocation Primitive policy 23 owns it for the intent of the five bound actions.
Deleted: Audit arm 4. Recoverable Invocation Primitive policy 43 owns it for the five bound actions.
Deleted: Audit arm 5. Execution Contract Database 1 owns it.
Deleted: Audit arm 6. Recoverable Invocation Primitive policy 27 owns it: the outcome's invalid-request(step-4) is read back by invocation id.
Deleted: Audit arm 7. Recoverable Invocation Primitive policy 35 owns it: the read-back matches by invocation id over the delta range, not by action reference and intent event id over the log.
Deleted: Audit arm 8. Recoverable Invocation Primitive policy 35 owns it.
Deleted: Audit arm 9. Recoverable Invocation Primitive policy 28 owns it.
Deleted: Audit arm 10. Recoverable Invocation Primitive policy 28 owns it: a found read-back returns success with a hard alert.
Deleted: Audit arm 11. Execution Contract Database 1 owns it.
Deleted: Audit arm 12. Execution Contract Database 1 owns it.
Deleted: Audit arm 13. Execution Contract Database 1 owns it.
Deleted: Audit arm 14. Recoverable Invocation reconcile step 2.4 through 2.6 and Execution Contract Database 1 own it.
Deleted: Audit arm 15. Recoverable Invocation reconcile step 2.4 through 2.6 and Execution Contract Database 1 own it.
Deleted: Audit arm 16. Execution Contract Database 2 owns it.
Deleted: Audit arm 17. Execution Contract Database 2 owns it: a custody action's attestations read the actor registry inside one transaction, so no invocation re-attests an outcome.
Deleted: Audit arm 18. Execution Contract Database 1 owns it: a custody action's writes commit together, so no invocation retries an outcome.
Deleted: Audit arm 19. Recoverable Invocation commit 8d, Recoverable Invocation Primitive policy 30 and Recoverable Invocation Primitive policy 31 own it: an outcome that does not land answers recording-failure(outcome).
Deleted: Audit arm 20. Execution Contract Database 2 owns it: a custody action's reads of a chain and the writes they decide are one transaction, and the composition names no exclusion to release.
Deleted: Audit arm 21. Execution Contract Database 2 owns it: a custody action's reads of a chain and the writes they decide are one transaction, and the composition names no lease to expire.
Deleted: Audit arm 22. Execution Contract Database 2 owns it: a custody action's reads of a chain and the writes they decide are one transaction, and the composition names no lease to expire.
Deleted: Audit arm 23. Recoverable Invocation Invariant 8.3 owns it: recording-failure(intent) is a committed nothing.
Deleted: Audit arm 24. Recoverable Invocation Invariant 8.4 owns it: recording-failure(outcome) is an act that may exist, whose record the sweep closes.
Deleted: Audit arm 25. Recoverable Invocation Primitive policy 41 owns it for the intent of the five bound actions.
Deleted: Audit arm 26. Recoverable Invocation Primitive policy 42 owns it: the hard alert on the outcome's invalid-request below step-4.
Deleted: Audit arm 27. Recoverable Invocation Primitive policy 31 owns it.
Deleted: Audit arm 28. Recoverable Invocation Primitive policy 42 owns it.
```

### Composition logic › Action wiring

```
Deleted: Action wiring 1. Recoverable Invocation Action wiring 4 and Recoverable Invocation Invariant 1.1 own it: the commit follows the invocation open, whose intent record verified the credential.
Deleted: Action wiring 2. Primitive policy 16 and Action wiring 12, 20, 27, 29 and 31 own it.
Deleted: Action wiring 3. Recoverable Invocation Primitive policy 10 owns it.
Deleted: Action wiring 4. Recoverable Invocation Composes 1 owns it: a record carries only the substrate's stamps, and the pairing datum an intent carries is the adopter's parameter, no stamp.
Deleted: Action wiring 6. Execution Contract Database 2 owns it.
Deleted: Action wiring 7. Action wiring 8 and Execution Contract Constituent failure 1 own it: a Provenance storage-failure is a pre-commit arm, closed through the invocation refuse and answered storage-failure.
Deleted: Action wiring 10. Execution Contract Database 1 owns it.
Deleted: Action wiring 22. Action wiring 63 and Action wiring 65 own it: the transfer transaction re-reads the holder and refuses a holder other than the resolved custodian, so the committed entry's outgoing custodian is the resolved custodian.
Deleted: Action wiring 23. Execution Contract Database 2 owns it.
Deleted: Action wiring 24. Action wiring 65 owns it: a holder changed since the resolution is refused not-current-custodian inside the transfer transaction, so no transfer answers principal-divergence.
Deleted: Action wiring 25. Action wiring 65 owns it: a holder changed since the resolution is refused not-current-custodian inside the transfer transaction, so no transfer answers principal-divergence.
Deleted: Action wiring 60. Recoverable Invocation Invariant 8.3 and Recoverable Invocation Invariant 8.4 own it: a refusal commits no custody entry, and recording-failure(outcome) is an answer whose act may exist.
```

### Composition logic › Wiring decision

```
Deleted: Wiring decision 1. Invariant 1.1 and Invariant 4.3 own it: the outcome event of a settled carried entry whose carrying intent stands neither open, escalated, abandoned nor refused, and no second invocation-written one.
Deleted: Wiring decision 2. Execution Contract Database 1 owns it.
```

### Composition logic › Reconciliation

```
Deleted: Reconciliation 1. Execution Contract Scheduled leg 1 and Recoverable Invocation sweep cadence 2 own it: the sweep runs at every process start, and the reconciliation runs beside it (Reconciliation 2, Reconciliation 31).
Deleted: Reconciliation 3. Execution Contract Database 1 owns it.
Deleted: Reconciliation 5. Execution Contract Database 2 owns it.
Deleted: Reconciliation 6. Execution Contract Database 2 owns it: the reconciliation's reads of a chain and the writes they decide are one transaction, and the composition names no exclusion for another holder to hold.
Deleted: Reconciliation 8. Recoverable Invocation reconcile step 1.1, step 1.2 and step 3.1 own it: the sweep runs the act probe for every open intent.
Deleted: Reconciliation 9. Recoverable Invocation commit 2 and Recoverable Invocation reconcile step 3.5 own it: a pre-commit arm closes through the invocation refuse, and an intent whose invocation died before its commit is escalated for an operator to abandon.
Deleted: Reconciliation 10. Recoverable Invocation Invariant 3.3 owns it, through the originate probe and the step probe: the pairing datum, the entry's recording instant, joins an intent to its entry by equality.
Deleted: Reconciliation 12. Recoverable Invocation reconcile step 1.2 and Recoverable Invocation reconcile step 3.12 own it: the sweep writes only for an intent, and only what it read.
Deleted: Reconciliation 13. Recoverable Invocation Invariant 3.5a and Recoverable Invocation reconcile step 3.8 through 3.10 own it: an escalation carries the database candidates, and an outcome never does.
Deleted: Reconciliation 14. Recoverable Invocation reconcile step 3.8 through 3.10 own it.
Deleted: Reconciliation 15. Recoverable Invocation Invariant 3.5a owns it.
Deleted: Reconciliation 16. Term step probe and Recoverable Invocation Invariant 3.3 own it: a transferred entry pairs to its intent by the pairing datum, as every other entry does.
Deleted: Reconciliation 17. Term originate probe and Recoverable Invocation Deviation 4b own it: the genesis lookup is the originate probe's read.
Deleted: Reconciliation 18. Recoverable Invocation Deviation 4c and Recoverable Invocation reconcile step 3.8 own it: with no genesis lookup the originate probe answers undecidable, and the sweep escalates the intent.
Deleted: Reconciliation 19. Action wiring 65 and Reconciliation 11 own it: the transfer transaction refuses a holder changed since the resolution, so no committed transfer's outgoing custodian differs from its intent's, and a transferred entry no intent carries opens a write-ownership finding.
Deleted: Reconciliation 20. Recoverable Invocation reconcile step 1.2 owns it: a transferred entry no intent carries is never closed by the sweep.
Deleted: Reconciliation 21. Recoverable Invocation Invariant 5.1 and Recoverable Invocation reconcile step 3.2a own it: the recovery intent before any recovered outcome.
Deleted: Reconciliation 22. Recoverable Invocation Invariant 5.2 and the service identity own it: the recovery identity is the bindings' service identity.
Deleted: Reconciliation 23. Recoverable Invocation Invariant 5.2, Recoverable Invocation Primitive policy 11a and Recoverable Invocation Term outcome shape own it: the recovered outcome carries the recovery flag, the acting actor reference and the intent event id.
Deleted: Reconciliation 24. Term step probe, Recoverable Invocation act probe 6 and Recoverable Invocation Invariant 5.3 own it: the probe re-derives the outcome's fields from the entry.
Deleted: Reconciliation 25. Recoverable Invocation reconcile step 2.4 through 2.6 own it: the sweep re-reads the invocation's closings under the critical section before it writes.
Deleted: Reconciliation 26. Recoverable Invocation reconcile step 2.5 and step 2.6 own it: an invocation already closed is not written for again, and the binding rebuild binds its outcome (Composition state 7).
Deleted: Reconciliation 27. Recoverable Invocation Sweep never 1 and Recoverable Invocation Invariant 9.2 own it: the sweep writes no adopter state, and the binding rebuild reads a recovered outcome event (Term binding rebuild).
Deleted: Reconciliation 28. Recoverable Invocation reconcile step 3.5, step 3.8 and step 5.1 own it: an intent the sweep cannot close is escalated once and reported at risk.
Deleted: Reconciliation 29. Recoverable Invocation Invariant 2.1 and Recoverable Invocation journal 3 own it: one escalation record per invocation, of the kind's own vocabulary.
```

### Composition-level invariants › Invariant 1 — Attributed custody

```
  Deleted: Invariant 1.3. Recoverable Invocation Invariant 5.2, Recoverable Invocation Invariant 5.4 and Recoverable Invocation Term outcome shape own it: an outcome the sweep wrote carries the service identity's attestation and one an operator wrote the operator's, each with the recovery flag and the acting custodian as the acting actor reference.
  Deleted: Invariant 1.4. Recoverable Invocation Invariant 3.1, Recoverable Invocation Check 1.1 and Recoverable Invocation Primitive policy 11a own it: every outcome names its intent by the invocation id and the intent event id, the intent attested under the actor the outcome names.
```

### Composition-level invariants › Invariant 4 — Binding bijection

```
  Deleted: Invariant 4.2. Recoverable Invocation Invariant 4.2 and Recoverable Invocation Check 3.1 own it: an intent whose invocation died is closed within the closure window, by an outcome on a committed probe (Recoverable Invocation reconcile step 3.2), or escalated.
  Deleted: Invariant 4.5. Recoverable Invocation reconcile step 3.5, Recoverable Invocation reconcile step 3.8 and Reconciliation 11 own it: an intent the sweep cannot close is escalated, and an entry no intent carries opens a write-ownership finding.
  Deleted: Invariant 4.6. Reconciliation 11 owns it: a transferred entry no intent carries opens a write-ownership finding, and the sweep never closes it.
```

### Composition-level invariants › Invariant 7 — Authentication precedes commitment

```
  Deleted: Invariant 7.1. Recoverable Invocation Invariant 1.1 owns it: the commit follows the invocation open, whose intent record verified the acting custodian's credential.
  Deleted: Invariant 6. Composes 5 owns it.
```

### Generation acceptance › Conformance checks

```
Deleted: Check 1.4. Recoverable Invocation Check 2.5 owns it: an outcome carrying the recovery flag is the sweep's or an operator's shape.
Deleted: Check 1.5. Recoverable Invocation service identity 3 and Recoverable Invocation Check 2.5 own it.
Deleted: Check 2.2. Verdict 12 owns it.
Deleted: Check 5.4. Execution Contract Database 3 and Execution Contract Database 4 own it.
Deleted: Check 5.5. Reconciliation 11 owns it.
Deleted: Check 5.6. Recoverable Invocation Check 4.1 owns it.
Deleted: Check 5.7. Recoverable Invocation Check 3.1 owns it.
Deleted: Check 5.8. Recoverable Invocation Check 4.1 owns it.
Deleted: Check 6.1. Recoverable Invocation Check 1.1 owns it.
Deleted: Check 6.2. Reconciliation 9 owns it.
Deleted: Check 6.3. Check 6.1 owns it.
```

### Generation acceptance › External checks

```
Deleted: External check 4. Execution Contract Database 2 owns it.
Deleted: External check 5. Execution Contract Database 3 owns it.
```

### Edge cases › Clock semantics

```
Deleted: Clock semantics 3. Recoverable Invocation Allowance 4 and Recoverable Invocation Allowance 6 own it.
```

### Edge cases › Concurrency

```
Deleted: Concurrency 1. Execution Contract Database 2 owns it.
Deleted: Concurrency 2. Execution Contract Database 2 owns it.
```
