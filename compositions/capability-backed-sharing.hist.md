---
title: Capability-Backed Sharing — history
nav_exclude: true
search_exclude: true
---

# Capability-Backed Sharing — history

The dated record of how [Capability-Backed Sharing](./capability-backed-sharing.md) got here, moved out of the spec on 2026-10-20 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- compositions/capability-backed-sharing.md`.

## Decisions

Entries that record a migration rather than a turn the pattern took.

- **2026-08-27 — The disclosure is durable intent, then a transactional domain mutation, then a durable outcome — never one atomic set.** *Chose:* [Redeem And Disclose] writes a `[Sharing Authorization Intended]` event, commits the Selective Disclosure record with a pending marker in its own transaction, then appends the `[Sharing Disclosed]` outcome; Invariants 2 and 3 are stated as ordering plus reachable partials plus recovery. *Over:* the original claim that the record, the event and the index commit "together or not at all" under a host transaction. *Because:* an Audit Trail append cannot be enlisted or withdrawn, so a host transaction aborting after the append left the trail asserting a disclosure the store denied — a real design defect, not editorial debt. The rule generalizes: never include an independently durable append in a host transaction's atomic set.

- **2026-08-29 — The scan is bounded at both edges, writes as the composition behind a recovery record, and an attestation nobody can re-derive is not re-emitted.** *Chose:* a declared `redemption_completion_bound` below which no direction of the scan examines anything, with the audit horizon above (a marker still pending there is escalated, never sealed); every scan write attested under the service identity behind a `sharing.recovery_intended` record, the revoker carried as `revoked_by` on a compensated [Sharing Revoked]; an unattested capability recovered by attestation only inside the invocation that holds the allocator's credential and by revocation once it is gone; every intent-record transcription carrying `recording-failure(step)` and [Revoke Sharing]'s outcome arms enumerated; `index_durability` declared and the two window knobs moved into Configuration; and a stale duplicate step 3 of [Redeem And Disclose] — the pre-repair wiring, which still described the decrement rolling back with a transaction — deleted. *Over:* an unbounded scan under an unnamed identity, and "retry the attestation" as a crash recovery. *Because:* an unbounded scan seals beside the seal an in-flight invocation is about to append and lands redemption-unfulfilled for a use whose disclosure is about to commit; a compensation the absent actor did not make cannot be attested as theirs; and an attestation under the allocator's credential is precisely the thing no one else can produce (the frozen rules of 2026-08-29 — *A reconciliation is bounded at both ends*, *Recovery commits under a declared service identity*, *A transcribed rejection arm keeps its payload*).

- **2026-08-29 — The redemption is irreversible, the intent precedes it, and the third partial is landed rather than sealed.** *Chose:* [Redeem And Disclose] resolves the descriptor by the instance's declared token read, records intent, then redeems, then commits the disclosure with its marker, then seals; a consumed use with no disclosure is redemption-unfulfilled, never a fabricated seal; the pending marker is truth-bearing under a durability obligation and the only source a seal is written from; the Capability instance is exclusive; the `(step)` payload governs every retry. *Over:* a decrement described as rolling back with the transaction, a reconciliation that sealed every counter shortfall, a shared instance with a "foreign token" reading, and step-less retries. *Because:* Capability declares no enlistment or undo, so the rollback was attributed to a capability the atom does not have; sealing a shortfall appended seals for disclosures that never happened; a shared instance consumed foreign tokens on refusal and convicted them in the counter checks; and a step-less retry duplicated outcome events after a retention-arm failure.

- **2026-09-23 — Rewritten in GRACE lang v0.61; twenty-four of twenty-five open Ledger lines closed by the rules that now own them.** *Chose:* `Composes`, `Composition state`, `Capability requirement` — which takes the prose's Configuration and Logic confinement both — `Primitive policy`, `Audit arm`, `Action wiring`, `Wiring decision` and `Reconciliation` as the surfaces; invariant numbers 1 through 4 and 6 unchanged, Invariant 5 tombstoned to Composes 5; the checks renumbered `Check 1.1` through `Check 6.7`, which ends the prose's missing check 6 (2026-08-29-a); `Non-goals` and `Edge cases` split, with `Atomic writes`, `Clock semantics` and `Concurrency` under the second; the Recipient term entry renamed Intended Recipient, since Selective Disclosure declares *recipient* and this page's concept is the one the allocator declared. The lines' fixes, as prescribed: the substrate's step carried on every transcription (2026-08-27-g); a diverged index entry rebuilt before proceeding and an irreconcilable one refused (2026-08-27-i, 2026-08-29-h); the disclosure reading named as what stamps the marker and the event (2026-08-27-j); verification presented with the original payload, modulo the unsealed tail (2026-08-27-k, 2026-08-29-e); the substrate's own partials named as the substrate's (2026-08-27-l); the grammar stated once, read both ways (2026-08-27-m); the authorization event carrying the effective ttl, not an expiry instant no step read (2026-08-29-b); the outcome-position refusal naming the orphan (2026-08-29-d); compensation lateness measured between two substrate recording instants (2026-08-29-f); the past-horizon rebuild claim withdrawn (2026-08-29-g); [Sharing Disclosures]' invalid-query arm (2026-08-29-i); the descriptor capped at this layer, caller fault split from deployment fault (2026-08-29-j); concurrency weakened to at most one (2026-08-29-l); revocation's inputs listed and revocation deliberately ungated by provenance, since revocation is the unattested orphan's recovery (2026-08-29-m); the Summary's *permanently* narrowed, acronyms glossed at first use, Invariant 1 cited to Capability's contract rather than its model, and the history narration moved out of the rules (2026-08-27-n through q, 2026-08-29-k, p, q). *Over:* the prose spec. *Because:* the migration plan, and the standing rule that a migration closes a line only where a rule now owns what the line asked for. The model line stays open (2026-08-29-r). The rewrite also removed a contradiction the prose carried against itself — its wiring-decision section still put the redemption inside the transaction that its own step 4 and edge cases said it could not be in; Wiring decision 4 and Atomic writes 2 now say it once.

- **2026-10-20 — The store's guarantees cited, not restated, and a sharing action's writes one transaction.** *Chose:* Capability requirement 18 citing Execution Contract Store 1 through 4 for the store the three constituents and the two indexes keep their records in; the rules restating what that store guarantees tombstoned to it (Composition state 11, 15, External check 6, Atomic writes 1, Concurrency 1, 2); the four that kept the Audit Trail append and Capability's redeem out of the action's transaction, or denied that its writes commit together, which Store 1 as ruled contradicts (Wiring decision 3, 4, Atomic writes 2, 3); and the machinery that existed only because a crash, a split write or an invocation seen between its writes could leave a partial: the reconciliation's run at every process start, its lower edge and the auditor's inconclusive reading below it, the redemption completion bound with the slowest conforming invocation it bounds and the refusal to start without it, the in-invocation retries of the authorization, unfulfilled and disclosure events, the read-back of a recording-failure at the substrate's retention step, which Audit Trail's own rewrite made commit nothing, and an invalid-credential at a human-attested outcome, which the one transaction's read of the actor registry forecloses (Reconciliation 1, 3, Check 6.6, Capability requirement 10, 11, 13, Action wiring 9, 33, 37, Audit arm 3, 5, 18, 9). Rules 236 to 214. *Over:* an Audit Trail append and a Capability redeem no host transaction could enlist, so that each action was ordered across durability boundaries, the disclosure committed first and sealed second, with a process-start run, an in-flight edge and in-invocation retries against what a crash between the writes left. *Because:* the maintainer ruled 2026-10-12 that the corpus takes a store's specification, never the store, and 2026-10-20 that Store 1 binds every store write of one composition action, its constituents' included, while a refused attempt a page keeps as evidence stays a domain choice, written in the same transaction as the refusal. The redeem and the append are store writes, Capability and Audit Trail each supplying theirs under Store 1 through 4, so a sharing action's intent, constituent writes and outcome commit together, and the wiring decision's second half, the ordering, goes. An Audit Trail refusal at an outcome record still leaves the act committed and its record owed (Audit arm 13, 20), as Audit Trail's own refusals leave their evidence (Audit Trail record action step 7.11), so what closes it stays: the pending marker, the disclosure intent a compensating seal is built from, the pairing of authorization intents, the three-direction reconciliation, its window and its escalation. The capability-to-sharing index stays a derived index outside every action's transaction, as obligation 2 of the section titled Composition state in `execution-contract.md` keeps it, so its rebuild-on-miss, the refusal of a token the rebuild finds no entry for and revocation ungated by the index stay; the sealed disclosure-to-redemption entry keeps its named rebuild (Composition state 16), the derivation obligation 1 of that section asks of a derived index. Under Store 1 a Selective Disclosure storage failure fails the whole redemption, so the unfulfilled path answers only a refusal the descriptor's validation forecloses (Action wiring 31, 32), and the disclosure event follows Selective Disclosure's answer inside the one transaction (Action wiring 36). Sharing events are ordered by the substrate's sequence numbers and no rule reads a record as it stood at a past commit, so the composition cites neither Store 5 nor Order 1. What the composition does for its domain is unchanged.

- **2026-11-10 — The ttl capped by the audit horizon.** *Chose:* (Scott, 2026-11-10 7:00 PM Central, "cap it", on the escalation of Final Critique 14's count) a capability's effective ttl, supplied or default, no longer than the ttl cap, the audit horizon less twice the clock offset allowance (Term ttl cap): a supplied ttl over it an out-of-bounds envelope, refused invalid-request with nothing written (Primitive policy 3), and a default over it refusing the start (Capability requirement 33); [Redeem And Disclose] answers a spent token Capability's own redemption failure without reading the capability-to-sharing index or writing (Action wiring 65 through 67), the invocation's now injected for that read as for the commit (Capability requirement 22), so the index is read only for a token Capability answers allocated, whose authorization event the cap keeps inside the audit horizon; Invariant 1.1 and 1.4 and Check 1.1 and 1.5 name the two events the allocator-named claim reads (Term claimable disclosure). Capability requirement 33 and Action wiring 65 through 67 new; Capability requirement 22, Invariant 1.1, 1.4, Check 1.1 and 1.5 restated; none tombstoned. Rules 184 to 188. Open lines 2026-11-06-e and 2026-11-10-e close. *Kept, with why:* every aged-token arm the 00:45Z escalation named. Composition state 6, 7 and 21, Action wiring 56 through 58 and Term aged event serve [Authorization Provenance], which a caller reaches for any token at any instant, and Invariant 4.2 and Check 7.3 an auditor, who reads at any instant: the cap bounds a token's life, not a query's or an audit's, so the index stays unrebuildable past the horizon. Action wiring 17 through 19 and Term unattested token keep their aged clauses for a token allocated before the cap with a longer ttl, the one live token the horizon can still outlive, which they refuse not-authorized-sharing as before; without the clauses Action wiring 17 and 19 would oblige a rebuild Composition state 7 forbids, an exception no rule states. *Over:* a token past the horizon refused not-authorized-sharing while its ttl had time left (Final Critique 14's cure, open line 2026-11-10-e); a cap of the horizon itself, which a token allocated just before its authorization event's recording, stamped by the substrate's clock, could outlive by two allowances; a cap less the reconciliation run bound as well, which no reading needs, since neither the sweep nor the leg compares against a token's expiry instant or its authorization event; and the spent token left to the redeem after the open, which would read the index, and so the aged arms, for a token the cap had already ended. *Because:* six of the twelve foundational findings of the page's last three full rounds sat on the horizon's far side of a token, each cure opening the next edge; a token that lapses no later than its authorization event ages leaves the redemption no live state there, and a revoked or exhausted token never reads allocated again, so the refusal ahead of the index covers the token the horizon outlives as well as the one it does not. *Costs:* no share outlives the horizon less two allowances; a spent token's redemption leaves no intent or refusal record, as an unknown token's did not, the refusal record kept only where a revocation lands between the read and the redeem; a deployment whose default ttl exceeds the cap does not start.

- **2026-11-10 — The wait retired: the three sharing actions are three Recoverable Invocation act kinds.** *Chose:* (Scott, 2026-11-09 9:17 PM Central, "A", and 2026-11-10 7:15 AM Central, the wait ruling, "simple DRY"; the map rounds/cbs-ri-map-2026-11-10.md, its directions settled under A, 2026-11-10 7:55 AM Central) the three acting actions each bind one act kind, sharing.authorize keyed by the allocator reference and the encoded descriptor under the minted-key deviation, sharing.disclosure keyed by the descriptor's subject, recipient, scope and authority under the minted-key deviation with the disclosure transaction its commit, sharing.revocation keyed by the token, every kind repeatable (A: act kinds split by the wait, G3, G14); the intent commits at the open and the outcome at the close, so an Audit Trail fault at the outcome leaves an open intent the sweep closes, and a constituent's storage-failure is a pre-commit refusal (A: an audit failure composes rather than committing a partial); a Selective Disclosure refusal fails the disclosure transaction whole, so no use is consumed without its record and the unfulfilled path, the remainder and the unfulfilled event go (A, G6), the refusal answered by Selective Disclosure's own code (Recoverable Invocation commit 3); the invocation's now injected into Capability's seam and Selective Disclosure's seam and passed as disclosed_at, the pairing datum of every kind, so a lost reply closes itself (G2, Capability requirement 22, 23); every acting action's caller-visible codes Recoverable Invocation's, the orphan reference retired, recording-failure(outcome) answered and carrying no token or disclosure id, every Capability refusal leaving a refusal record, the events renamed sharing.<kind>.* with `recovery` for `cascade_recovery` (A: codes change to Recoverable Invocation's, G7); an operator's outcome detected, not prevented, by the seal alert and the duplicate-authorization alert (Composition state 17, 18), with the false-closing alert in the leg (A: detected, not prevented, with an alert, G8; Reconciliation 35); an intent whose invocation died before its commit escalated for an operator in place of the abandonment the reconciliation wrote (A, G9); a capability, a revocation or a disclosure record no intent carries a write-ownership finding (A: a record with no intent becomes a finding, G10; Reconciliation 32 through 34); the leg on Recoverable Invocation's cadence, run and run reading, its enumerations taken at the run's start by Capability's read naming no field and Selective Disclosure's read by disclosure instant range (G11); the mayor's derivable calls taken as the map recommends: a recovered authorization authorizes nothing, the capability-to-sharing index binding only an outcome carrying no recovery flag, so the reconciliation's revoke of an unattested capability goes and the token lapses at its ttl (G1 (ii); Composition state 6, Invariant 3.3, 3.5); a redemption identity for the bearer's invocation and a recovery identity for the sweep, distinct (G5; Capability requirement 2, 3, 26, 27); the act keys under the reference length cap, refused invalid-sharing-descriptor at the allocation that fixes them (G4; Primitive policy 15 through 18); a share's concurrent redemptions serialized by act-in-flight (G4); the pending entry kept, written in the disclosure transaction, and reclassified a derived index, a recovered disclosure outcome naming the allocator Capability's read answers and reaching the token through its intent (G13). Capability requirement 7 through 9, 12, 19 through 21, every live Audit arm rule but 17, Action wiring 1, 3, 7, 25, 27, 30, 34, 39, every live Reconciliation rule but 2, Invariant 2.4, 2.5, 3.4, 6.1, 6.2, Check 3.1, 4.3, 5.1, 5.2, 5.4, 6.1 through 6.4 and Clock semantics 3 tombstoned to what owns them; Composes 16 through 20, Composition state 17 through 20, Capability requirement 22 through 32, Primitive policy 15 through 18, Action wiring 59 through 62, Reconciliation 29 through 38, Invariant 3.5, Check 7.1, 7.2, External check 9, Non-goal 9, 10 and Cross-record consistency 1 new; the closure table drafted. Rules 217 to 189. Open lines 2026-08-29-r, 2026-11-05-a, 2026-11-05-c, 2026-11-05-d, 2026-11-06-b and 2026-11-06-f dissolve with the rules they named; 2026-11-06-d is carried, widened to the Lease host and the compliance surface; 2026-11-10-a and 2026-11-10-b are opened. *Over:* removing the wait by reversing 2026-10-20, so that an Audit Trail refusal of any outcome fails the whole sharing action, which nothing physical forbids here — the host delivers only after a disclosure result — but which would make the substrate's health a precondition of cancelling a live share, Propagate Consent Revocation Downstream's objection to it for a withdrawal; and keeping the page's own reconciliation beside Recoverable Invocation, which would have covered the intent-and-outcome pairing twice. *Because:* the wait was self-made: the 2026-10-20 decision left a committed sharing act with its record owed so an Audit Trail fault never undid a constituent write, and the page then built the pending marker's owed-record role, the pairing of authorization intents within a window, the three-direction reconciliation with its revoke, abandonments and unfulfilled events, the compensation window, its cadence, run bound and escalation reach to close it, which Recoverable Invocation owns; eleven of the seventeen foundational findings of Final Critique 7 through 13 sat in that machinery or in the audit-arm positions Recoverable Invocation's open, close and refuse own. It turns the 2026-10-20 entry's "what closes it stays" and, in part, the 2026-08-29 entry: an unattested capability is no longer recovered by revocation once its allocator is gone, and stays refused instead. *Costs:* a Lease host, the instance's bounds and a sweep; three completion bounds the page never had; every acting action's caller-visible codes; two service identities where the page had one; the pairing rests on a deployment obligation on Capability's and Selective Disclosure's seams; a share's concurrent redemptions answer act-in-flight to all but one; operator work for an intent whose invocation died before its commit, which the reconciliation had closed silently; Invariant 2.1, 2.2, 3.1 and 3.2 fall from prevented to detected against an operator's resolve.

- **2026-11-11 — The addressee and the recipient: two words, two meanings.** *Chose:* (Scott, 2026-11-11 6:41 AM Central, "recipient", and at 6:43 AM, on the composition's name for the other party, "that is better": addressee, on the 07:10Z ask; EOS Reading A had found open line 2026-10-27-a foundational in Final Critique 12 and 15) Selective Disclosure's Term recipient stays the party the data reached; this page's Term intended recipient becomes Term addressee, who the share was sent to, and Invariant 1.3 says once that a bearer's redemption may reach a recipient other than the addressee. *Over:* widening Selective Disclosure's Term recipient to carry the intended party where the authority is a bearer's (an atom changes on a composition's account, Composes 4). *Because:* a letter has an addressee, and whoever opens it has received it; two words end the reading that found the same edge each full round. Open line 2026-10-27-a closes by Invariant 1.3's sentence. Editorial: no obligation changes.

- **2026-11-18 — A composition action reads the clock once: Capability requirement 16 and Clock semantics 2 retire to Execution Contract Logic confinement 19, and Capability requirement 22 cites it.** *Chose:* Capability requirement 16 (the composition passes no now to a constituent, Selective Disclosure's disclosed_at and the intent data's pairing datum excepted) and Clock semantics 2 (the composition compares no composition reading against the substrate's recording instant, Term aged event's comparison excepted) leave their `Deleted:` tombstones naming Logic confinement 19 and the ruling, never renumbered or reused. Capability requirement 22, which said for this page what Logic confinement 19 now says for every composition (the host injects the invocation's now into Capability's and Selective Disclosure's seams), keeps its label, which twenty-six of the page's models, the coverage matrix, External check 9 and the tombstone of Clock semantics 3 cite, and carries the obligation PER Logic confinement 19; Term allocation reading, Term disclosure reading and Term revocation reading cite Logic confinement 19 for the instant the constituent's record carries equalling the reading, in place of Capability requirement 22. Citations found, by label: none for Capability requirement 16 or Clock semantics 2 (`cites.py`); no formal model, twin or coverage row names either. Action wiring 2, 23, 29 and 40 (the pairing datum in the intent data, and the disclosure reading passed as disclosed_at) stand: passing the reading and leaving the instant blank now record one instant. Kept, each with its subject: Term aged event, Term aged record and Term young record (a later call's now against an instant an earlier call stamped), Term clock offset allowance, and Term ttl cap, whose first allowance still covers an authorization event the sweep closes, a later call on its own clock; under the one reading the invocation's own close stamps the allocation reading, and whether the cap narrows by that allowance is a decision no rule makes. Rules 2 fewer. *Over:* retiring Capability requirement 22 to a tombstone, which would move the comments of twenty-six models, a coverage row, External check 9 and an owner named by a tombstone off a label whose obligation stands. *Because:* Scott, 2026-11-18 6:52 AM Central, "YYY" (rounds/escalations.md 2026-11-18 12:52Z, item 2, on the measure of 06:09Z): a composition action reads the clock once, and every constituent call it makes takes that reading as its now, from MIT's sync-engine (github.com/mit-sdg/sync-engine), which binds one instant per causal flow. The page takes a delta round.

## Deleted rules

The spec's tombstones, moved here from the page on 2026-11-13 because the spec is done (GRACE-lang Hard invariant 25 and Hard invariant 27, since v0.71): each `Deleted:` line byte for byte and in the page's order, under the heading it stood under there. A tombstone carries no obligation, and each still reserves its label: no rule of [Capability-Backed Sharing](./capability-backed-sharing.md) may carry it again.

### Composition logic › Composition state

```
Deleted: Composition state 11. Execution Contract Database 1 owns it.
Deleted: Composition state 15. Execution Contract Database 3 owns it.
```

### Composition logic › Capability requirement

```
Deleted: Capability requirement 7. Recoverable Invocation Instance start 4 owns it: the closure window.
Deleted: Capability requirement 8. Recoverable Invocation sweep cadence 2 and Recoverable Invocation sweep cadence 3 own it.
Deleted: Capability requirement 9. Recoverable Invocation Instance start 4 owns it: the worst closure against the closure window, the sweep's run counted in it.
Deleted: Capability requirement 10. Execution Contract Database 1 owns it.
Deleted: Capability requirement 11. Execution Contract Database 1 owns it.
Deleted: Capability requirement 12. Recoverable Invocation Instance start 4 owns it: a blank closure window does not pass, and Capability requirement 24 refuses a start on the composition's own required settings.
Deleted: Capability requirement 13. Execution Contract Database 1 owns it: the composition names no redemption completion bound for a deployment to leave blank.
Deleted: Capability requirement 16. Execution Contract Logic confinement 19 owns it: the host injects the invocation's one reading at the seam of every constituent call the invocation makes, so an instant the composition passes, Selective Disclosure's disclosed_at among them, and one it leaves blank are the same instant (Scott, 2026-11-18 6:52 AM Central, "YYY", rounds/escalations.md 2026-11-18 12:52Z, item 2).
Deleted: Capability requirement 19. Recoverable Invocation Instance start 5 owns it: the retention floor.
Deleted: Capability requirement 20. Recoverable Invocation run bound owns it: the sweep's own, and the write-ownership leg runs inside it.
Deleted: Capability requirement 21. Recoverable Invocation run bound and Recoverable Invocation Instance start 7 own it.
```

### Composition logic › Audit arm

```
Deleted: Audit arm 1. Recoverable Invocation Primitive policy 19 owns it for the intent of the three bound actions.
Deleted: Audit arm 2. Recoverable Invocation Primitive policy 23 owns it for the intent of the three bound actions.
Deleted: Audit arm 3. Execution Contract Database 1 owns it.
Deleted: Audit arm 4. Recoverable Invocation Primitive policy 36 owns it: a record the read-back finds is landed.
Deleted: Audit arm 5. Execution Contract Database 1 owns it.
Deleted: Audit arm 6. Recoverable Invocation Primitive policy 41 owns it for the intent of the three bound actions.
Deleted: Audit arm 7. Recoverable Invocation Primitive policy 43 owns it.
Deleted: Audit arm 8. Recoverable Invocation commit 8d and Recoverable Invocation Primitive policy 31 own it: an outcome that does not land answers recording-failure(outcome), which carries no orphan reference.
Deleted: Audit arm 9. Execution Contract Database 2 owns it.
Deleted: Audit arm 10. Recoverable Invocation Primitive policy 19, Recoverable Invocation Primitive policy 31 and Recoverable Invocation reconcile step 3.18 own it: an invalid-credential lands by the record's position.
Deleted: Audit arm 11. Recoverable Invocation reconcile step 3.19 owns it.
Deleted: Audit arm 12. Recoverable Invocation Invariant 8.3 owns it: recording-failure(intent) is a committed nothing.
Deleted: Audit arm 13. Recoverable Invocation Invariant 8.4 owns it: recording-failure(outcome) is an act that may exist, whose record the sweep closes.
Deleted: Audit arm 14. Recoverable Invocation Invariant 8.4 owns it.
Deleted: Audit arm 15. Recoverable Invocation Primitive policy 35 owns it: the read-back matches by invocation id, not by intent event id.
Deleted: Audit arm 16. Recoverable Invocation Primitive policy 42 owns it: the hard alert on an invalid-request from the substrate.
Deleted: Audit arm 18. Execution Contract Database 1 owns it.
Deleted: Audit arm 19. Recoverable Invocation Primitive policy 41 owns it: an invalid-request(step-3) at the intent answers invalid-request.
Deleted: Audit arm 20. Recoverable Invocation Primitive policy 42 owns it.
Deleted: Audit arm 21. Recoverable Invocation Primitive policy 27 and Recoverable Invocation Primitive policy 28 own it: an invalid-request(step-4) is read back by invocation id.
Deleted: Audit arm 22. Recoverable Invocation refuse step 3.5 through 3.8 own it: a refusal record that does not land answers recording-failure(refusal, constituent_code) with the intent left open.
Deleted: Audit arm 23. Recoverable Invocation's Action wiring table owns it: recording-failure(refusal, constituent_code) is a refusal whose attempt the sweep records.
```

### Composition logic › Action wiring

```
Deleted: Action wiring 1. Recoverable Invocation Action wiring 4 and Recoverable Invocation Invariant 1.1 own it: the allocate follows the invocation open, whose intent record verified the allocator's credential.
Deleted: Action wiring 3. Recoverable Invocation Primitive policy 10 owns it.
Deleted: Action wiring 6. Execution Contract Constituent failure 1 owns it.
Deleted: Action wiring 7. Recoverable Invocation refuse step 3.1 and Action wiring 5 own it: a refused allocate writes the intent and its sharing.authorize.refused record, and nothing else.
Deleted: Action wiring 9. Execution Contract Database 1 owns it.
Deleted: Action wiring 25. Recoverable Invocation Action wiring 4 owns it: the redeem follows the invocation open.
Deleted: Action wiring 54. Execution Contract Constituent failure 1 owns it.
Deleted: Action wiring 27. Recoverable Invocation refuse step 3.1 owns it: the refusal record is sharing.disclosure.refused, carrying the redemption failure as the constituent code.
Deleted: Action wiring 30. Action wiring 29 and Capability requirement 22 own it, reversed: the disclosure reading is passed as disclosed_at, the disclosure probe's pairing datum.
Deleted: Action wiring 55. Execution Contract Constituent failure 1 owns it.
Deleted: Action wiring 33. Execution Contract Database 1 owns it.
Deleted: Action wiring 34. Action wiring 31 owns it: a Selective Disclosure refusal consumes no use, so no unfulfilled redemption exists to seal.
Deleted: Action wiring 37. Execution Contract Database 1 owns it.
Deleted: Action wiring 39. Recoverable Invocation Action wiring 4 and Recoverable Invocation Invariant 1.1 own it: the revoke follows the invocation open, whose intent record verified the revoker's credential.
Deleted: Action wiring 44. Execution Contract Constituent failure 1 owns it.
```

### Composition logic › Wiring decision

```
Deleted: Wiring decision 3. Execution Contract Database 1 owns it.
Deleted: Wiring decision 4. Execution Contract Database 1 owns it.
```

### Composition logic › Reconciliation

```
Deleted: Reconciliation 1. Execution Contract Database 1 and Execution Contract Database 3 own it.
Deleted: Reconciliation 3. Execution Contract Database 1 owns it.
Deleted: Reconciliation 4. Recoverable Invocation Invariant 5.2 and Recoverable Invocation service identity 3 own it: the sweep writes under the recovery identity, and the leg writes no event.
Deleted: Reconciliation 5. Recoverable Invocation Invariant 5.1 and Recoverable Invocation reconcile step 3.2a own it: the recovery intent before any recovered outcome.
Deleted: Reconciliation 6. Recoverable Invocation reconcile step 3.2a owns it: the kind's recovery_intended record carries the invocation id, the intent event id, the act key and the plan.
Deleted: Reconciliation 7. Recoverable Invocation Invariant 5.2, Recoverable Invocation Primitive policy 11a and Recoverable Invocation Term recovered outcome payload own it: the recovered outcome carries the recovery flag, the acting actor reference and the intent event id.
Deleted: Reconciliation 8. Term authorization probe, Term disclosure probe, Term revocation probe, Recoverable Invocation act probe 6 and Recoverable Invocation Invariant 5.3 own it: the probe re-derives the outcome's fields from the constituent records.
Deleted: Reconciliation 9. Recoverable Invocation reconcile step 3.2 and Recoverable Invocation reconcile step 2.4 through 2.6 own it: a committed probe closes the intent with the outcome, after a re-read under the critical section.
Deleted: Reconciliation 28. Recoverable Invocation Sweep never 1, Recoverable Invocation Invariant 9.2 and Composition state 16 own it: the sweep writes no adopter state, and the rebuild seals the marker from a recovered disclosure event.
Deleted: Reconciliation 10. Term disclosure probe and Recoverable Invocation act probe 6 own it: a recovered disclosure outcome carries the disclosure record's fields and the allocator Capability's read answers.
Deleted: Reconciliation 11. Recoverable Invocation reconcile step 1.1, Recoverable Invocation reconcile step 1.2 and Recoverable Invocation reconcile step 3.1 own it: the sweep runs the act probe for every open intent.
Deleted: Reconciliation 12. Recoverable Invocation reconcile step 3.12, Recoverable Invocation act probe 6 and Recoverable Invocation Invariant 5.3 own it: the sweep writes only what the probe read.
Deleted: Reconciliation 13. Action wiring 31 owns it: a consumed use and its disclosure record commit together, so no remainder exists.
Deleted: Reconciliation 14. Recoverable Invocation Invariant 3.5a owns it: an outcome never carries candidates.
Deleted: Reconciliation 15. Recoverable Invocation reconcile step 3.5 and Recoverable Invocation Invariant 4.9 own it: an intent whose invocation consumed nothing is escalated, and an operator abandons it.
Deleted: Reconciliation 16. Action wiring 31 owns it: no remainder exists to seal from.
Deleted: Reconciliation 17. Term authorization probe and Recoverable Invocation Invariant 3.3 own it: the pairing datum, the allocation instant, joins an intent to its capability by equality.
Deleted: Reconciliation 18. Composition state 6 and Action wiring 18 own it: a recovered authorization binds no capability-to-sharing entry, so its token is refused not-authorized-sharing and lapses at its ttl, and nothing is revoked.
Deleted: Reconciliation 19. Recoverable Invocation reconcile step 3.8 through 3.10 own it.
Deleted: Reconciliation 27. Recoverable Invocation reconcile step 3.5 and Recoverable Invocation Invariant 4.9 own it: an authorization intent that allocated nothing is escalated, and an operator abandons it.
Deleted: Reconciliation 20. Term revocation probe, Recoverable Invocation reconcile step 3.2 and Reconciliation 33 own it: a revocation an intent carries is closed by the sweep, and one no intent carries opens a write-ownership finding.
Deleted: Reconciliation 21. Term revocation probe and Recoverable Invocation act probe 6 own it.
Deleted: Reconciliation 22. Recoverable Invocation Invariant 2.1 owns it, and Capability's already-terminal refuses a second revoke of one token.
Deleted: Reconciliation 23. Recoverable Invocation reconcile step 3.5, Recoverable Invocation reconcile step 3.8, Recoverable Invocation reconcile step 3.21 and Recoverable Invocation reconcile step 5.1 own it.
Deleted: Reconciliation 24. Recoverable Invocation Invariant 7.2, Recoverable Invocation Instance start 5 and Recoverable Invocation reconcile step 5.9 own it.
Deleted: Reconciliation 25. Recoverable Invocation Invariant 7.2 and Recoverable Invocation reconcile step 1.2 own it.
Deleted: Reconciliation 26. Composes 6 owns it: the leg writes no event, so it compensates nothing, and a substrate partial is the substrate's own reconciliation's.
```

### Composition-level invariants › Invariant 2 — Disclosure-accountability binding

```
  Deleted: Invariant 2.4. Recoverable Invocation Invariant 4.2 and Recoverable Invocation Check 3.1 own it: an intent whose invocation died is closed within the closure window, by an outcome on a committed probe, or escalated.
  Deleted: Invariant 2.5. Recoverable Invocation Instance start 4 through 8 and Recoverable Invocation Check 4.1 own it: the instance does not start without its bounds.
```

### Composition-level invariants › Invariant 3 — Allocation-authorization binding

```
  Deleted: Invariant 3.4. Recoverable Invocation Invariant 4.2 owns it: an authorization intent whose invocation died is closed within the closure window, by an outcome on a committed probe, or escalated.
```

### Composition-level invariants › Invariant 6 — Authentication precedes commitment at the actions that name an actor

```
  Deleted: Invariant 6.1. Recoverable Invocation Invariant 1.1 owns it: the allocate follows the invocation open, whose intent record verified the allocator's credential.
  Deleted: Invariant 6.2. Recoverable Invocation Invariant 1.1 owns it: the revoke follows the invocation open, whose intent record verified the revoker's credential.
  Deleted: Invariant 5. Composes 5 owns it.
```

### Generation acceptance › Conformance checks

```
Deleted: Check 2.4. Check 2.3 owns it.
Deleted: Check 3.1. Recoverable Invocation Check 3.1 and Recoverable Invocation Check 1.1 own it: every intent is closed or escalated within the closure window, and every outcome names its intent.
Deleted: Check 3.5. Check 3.1 owns it.
Deleted: Check 4.3. Action wiring 31 owns it: a consumed use and its disclosure record commit together, so no remainder exists.
Deleted: Check 5.1. Recoverable Invocation Check 1.1 owns it.
Deleted: Check 5.2. Recoverable Invocation Check 1.1 owns it.
Deleted: Check 5.3. Check 5.1 owns it.
Deleted: Check 5.4. Term revocation probe and Recoverable Invocation reconcile step 3.5 own it: a revocation intent is closed by its outcome, its refusal record, a recovered outcome or an escalation.
Deleted: Check 5.5. Action wiring 24 owns it.
Deleted: Check 6.1. Recoverable Invocation Check 3.1 owns it.
Deleted: Check 6.2. Action wiring 31 owns it: no remainder exists to seal from.
Deleted: Check 6.3. Recoverable Invocation Check 6.1 owns it.
Deleted: Check 6.4. Recoverable Invocation Check 3.1 owns it.
Deleted: Check 6.5. Reconciliation 23 owns it.
Deleted: Check 6.6. Execution Contract Database 1 owns it.
Deleted: Check 6.7. Reconciliation 25 owns it.
```

### Generation acceptance › External checks

```
Deleted: External check 6. Execution Contract Database 3 owns it.
```

### Edge cases › Atomic writes

```
Deleted: Atomic writes 1. Execution Contract Database 1 owns it.
Deleted: Atomic writes 2. Execution Contract Database 1 owns it.
Deleted: Atomic writes 3. Execution Contract Database 1 owns it.
```

### Edge cases › Clock semantics

```
Deleted: Clock semantics 2. Execution Contract Logic confinement 19 owns it: the substrate an invocation calls reads the invocation's one now, so an event the invocation records carries the composition's reading as its recording instant, and the substrate's recording instant meets a later reading only in Term aged event's comparison, under the clock offset allowance (Scott, 2026-11-18 6:52 AM Central, "YYY", rounds/escalations.md 2026-11-18 12:52Z, item 2).
Deleted: Clock semantics 3. Capability requirement 22 and Term disclosure probe own it, reversed: the disclosure reading is the disclosure record's disclosure instant, and the probe compares them by equality.
```

### Edge cases › Concurrency

```
Deleted: Concurrency 1. Execution Contract Database 2 owns it.
Deleted: Concurrency 2. Execution Contract Database 2 owns it.
```
