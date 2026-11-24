---
title: External Onboarding — history
nav_exclude: true
search_exclude: true
---

# External Onboarding — history

The dated record of how [External Onboarding](./external-onboarding.md) got here, moved out of the spec on 2026-10-20 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- compositions/external-onboarding.md`.

## Decisions

Entries that record a migration rather than a turn the pattern took.

- **2026-08-26 — The attempt record is the credential gate on all four actions.** *Chose:* every state-changing action opens with a `record_action` attempt event whose Actor Identity attestation, made inside the substrate's declared surface, is the credential check; an attempt refused at the gate lands no event. *Over:* a dry-run mode the substrate does not declare, or reaching Actor Identity directly, which is a transitive constituent. *Because:* the check must live on a surface the composition actually consumes, and the attempt is then auditable for free.

- **2026-08-26 — Invariant 4 is safety plus detectability, not totality.** *Chose:* the arc's completeness is claimed over named gap signatures that checks 5 and 6 enumerate. *Over:* the unconditional statement over paths that admit invisible terminal transitions. *Because:* the composition is stateless by design and carries no marker discipline, so detectability through records is the recovery posture it can honestly offer.

- **2026-08-27 — The gate authenticates and attributes; authorization is declared above the composition.** *Chose:* a named edge case declaring a composed Permissions instance over `invitations:initiate` / `invitations:revoke` as the deployment's authorization gate, with every "authorized actor" claim on the page downgraded to authenticated-and-attributed and the SOC 2 CC6.2 paragraph re-scoped to the registration and ordering halves. *Over:* wiring Permissions as a fifth constituent and gating [Invite] and [Revoke] on a scope. *Because:* the claim was made and neither wired nor disclaimed, which is the worst of the three states; absorbing the gate would make this composition the owner of an authorization vocabulary it has no other use for, while declaring it names the record a regulator's authorization question is answered from.

- **2026-08-29 — The gate can be re-entered but never re-accepted, and the substrate's arm keeps its step.** *Chose:* a resume arm on [Onboard] — same acceptor, acceptance older than a declared `onboarding_completion_bound`, stage established from the trail and then from the Party Identity store, candidates named where the store cannot decide, an `onboarding.resume-intended` record before any commit, then the remaining steps re-run under the caller's own identity; and every `record_action` transcription carrying `recording-failure(step)`, with the step-4 arm proceeding as landed and invalid-request read back rather than declared unreachable. *Over:* administrator completion of the constituent steps outside the composition, and a single bare recording-failure landing. *Because:* manual completion leaves the party with no completion record, which is the regulator-audit scenario's own failure produced by the recovery; and the substrate's step-4 arm means the event is already appended, so a bare token turned the retry into a duplicate-event generator (the frozen rules of 2026-08-29 — *Recovery commits under a declared service identity* and *A transcribed rejection arm keeps its payload*).

- **2026-08-30 — One resumer per token, the arc bounded at both edges, the dead resume's party found by the arc's actors, the skew declared, the position on the code.** *Chose:* a deployment-supplied `per_token_serialization` the resume arm holds from R1's first read to its return and the fresh arc takes at step 3's `accepted` arm and holds to its return, with stated lease semantics — released on return or death, a lease at least the widened bound long whose expiry is the invocation's terminus, every write after the first made only under the section, and an invocation that lost it re-taking it and re-running R1–R2 as a resume of its own arc before writing again — so two resumers never both enroll and a stalled original is refused until its lease expires; the arc's document_type and document_ref recorded on `onboarding.accept-attempt`, `onboarding.invitation-accepted`, and `onboarding.resume-intended`, R2 matching the store against the recorded pair and a resumer whose inputs differ refused; R4 taking the post-write landings with step-4 proceeding as landed; with R1 refusing a successor-less `onboarding.resume-intended` younger than the bound and check 7 condemning two completions or two parties per token; an upper edge on the resume arm — `accepted_at` older than `audit_trail_retention_policy`'s horizon is refused, since a purged completion is not an absent one; R1 reading a dead resume's `onboarding.resume-intended` as *stage unrecorded* and R2 reading the union of windows anchored at `accepted_at` and at every resume-intended's `recorded_at`; R2 filtering on the arc's actor set from the trail rather than the resumer's identity; a `clock_offset_allowance` widening every cross-seam comparison — step 3's bound, R1's edges, R2's window, the standing rule — with Invariant 1's duplicate-freedom made conditional on it; resume_party_id on a `Pending` invitation refused at step 1 by a read before the gate; and `storage-failure(intent | outcome)` on all four signatures, the relayed constituent tokens taking the position by the same test. *Over:* a resume arm whose only gate had already fired for every resumer; a section claimed in Configuration that no fresh-arc step took, with no release, expiry, or re-take rule; a party matched on documents the resumer typed; a leg with a lower edge and no upper one; a stage read from `onboarding.interrupted` alone and a window anchored at `accepted_at` alone; "equal this invocation's" against "re-run under the caller's own identity"; a write decision on a read the constituent calls best-effort; a declared rejection no step evaluates; and a bare token on both sides of the commit. *Because:* the gate serializes the one write to `Accepted` and nothing after it, so two re-entries are two writers the atom cannot tell apart; a section with no terminus lets a stalled holder block the arc forever and a lost one lets its holder write between a resumer's pre-check and its append; and a filter on the resumer's inputs finds a different person's party or none; a lawfully destroyed completion read as absent completes the arc twice; a resume that enrolled and died leaves its party outside every window the original arc anchors; an administrator finishing a service account's arc is the recovery the edge case names, and a filter on the resumer finds nothing; a stamp another seam wrote can differ from this one's by a sign the bound does not have; and a caller who cannot tell intent from outcome re-runs a committed act (the frozen rules of 2026-08-30 — *A compensator is exclusive*, *A stamp from another seam never decides a write alone*, *A composition's own rejection arm carries the retry bit*, and *Capability provenance* frozen with its tells for uses — with §*A reconciliation is bounded at both ends*, §*Recovery commits under a declared service identity*, and §*Lawful destruction is answered before absence*; *Liveness is arithmetic* and *An outcome is sized before the intent* were swept and found no shape here beyond naming the resume payloads in step 1's sizing).

- **2026-09-23 — Rewritten in GRACE lang v0.61; twenty-one of twenty-four open Ledger lines closed by the rules that now own them, and nothing else changed but what each line asked for.** *Chose:* `Composes`, `Composition state`, `Capability requirement`, `Primitive policy`, `Audit arm`, `Action wiring`, `Wiring decision` and a `Resume` family for the resume arm as the surfaces; invariant numbers 1 through 5 unchanged; the seven prose checks kept as `Check 1.1` through `Check 7.4`, grouped by their old numbers, with the standing rules as a `Standing rule` family; `Non-goals` and `Edge cases` split; Standards renamed Standards references and moved to its place. The lines' own fixes, taken as the ledger prescribed them: the validation depth pinned pre-gate against each constituent's field rules (2026-08-26-f, Primitive policy 3 and 4); the decliner's identity declared unrecorded (2026-08-26-e, Action wiring 47, Non-goal 5); Invariant 2 re-scoped to the completion record's linkage (2026-08-26-i); the substrate's third invalid-request source named, Actor Identity's arm at the substrate's second step, and the read-back floored at the invocation's own attempt record (2026-08-30-c, Audit arm 8 through 12); Party Identity's invalid-query landed as the composition's own defect (2026-08-30-e, Resume 25 and 26); the candidates declared unfiltered by state, since a closed party the arc enrolled is still the arc's party (2026-08-30-k, Resume 19); every alert named onto the deployment's alerting surface (2026-08-30-l); the relation's cardinality and modality declared (2026-08-30-h); the comparisons' edges pinned by the operators (2026-08-30-f); an operational membership test for the horizon (2026-08-30-g); *rests on* in every invariant's WHY (2026-08-30-i); the examples' credential call matched to the atom's raw-material model and the concurrent example changed to the same-acceptor race (2026-08-26-k, 2026-08-30-o); acronyms glossed and the SOC 2 attribution corrected (2026-08-26-j, 2026-08-30-j, 2026-08-30-m); and the mismatch with Invitation's `Composition note 2` and `Composition note 3` noted here and corrected there (2026-08-30-n). *Over:* the prose spec. *Because:* the migration plan, and the standing rule that a migration closes a line only where a rule now owns what the line asked for. Three stay open: the resume arm's credential read-back (2026-08-30-d), which wants a design choice between walking predecessors and naming the head, and the two formal lines.

- **2026-09-23 — The resume arm completes with the credential the arc registered, never the credential standing active.** *Chose:* on duplicate-active-credential the resume arm reads the party's credentials of the call's type in every status, keeps the chain roots registered inside the arc's window union, continues with a sole root, and refuses none or several with onboarding-indeterminate carrying the credential candidates, behind an interruption record, with a resume credential id for the administrator's choice (Resume 39 through 47). *Over:* naming the head — the credential standing active — and widening Check 2 to accept any link of the head's chain. *Because:* the head can be a rotation successor or a foreign registration, so a completion record naming the head records what the composition did not do, against Invariant 3.1; walking back keeps Check 2.1 through 2.3 true as written. The maintainer's ruling on 2026-08-30-d.

- **2026-09-27 — A dead resume without an acceptance record resumes at acceptance-unrecorded.** *Chose:* Resume 9 reads the stage as unrecorded only where an acceptance record exists. *Over:* Resume 9 and Resume 11 both firing on one arc. *Because:* a resume that dies after its resume record lands and before the acceptance record Resume 30 writes leaves a dead resume record and no acceptance record, and the two rules then named two stages; the arc still owes its acceptance record, which only acceptance-unrecorded writes. Found by the cold regeneration of the demo (council read 240).

- **2026-10-20 — The store's guarantees cited, not restated, the per-token critical section among them.** *Chose:* Capability requirement 21 citing Execution Contract Store 1 through 4 for the store the four constituents keep their records in; the rules restating what that store guarantees tombstoned to it — the host's critical section keyed by invitation token, with its supply, its exclusion across nodes, the fresh arc's take at the accept, every write under it, its release, its lease, its expiry, its loss and re-take, the refusals when the host withheld it and the bar on starting without it (Capability requirement 13 through 17, 20, Action wiring 10 through 16, 39, Resume 1 through 3, 38, Concurrency 2, 3, External check 5, 6); and the machinery that existed only because a split write or an invocation seen between its writes could leave a partial: the substrate's recording-failure at the retention step read as an appended event — proceeded as landed, never retried, alerted as unretained (Audit arm 6, 7, 20, Resume 34) — which Audit Trail's own rewrite made commit nothing, a read-back of an invalid-request at step-4 that finds no record (Audit arm 12, Resume 37), since that refusal leaves the event appended inside the one transaction, the bar on a constituent write before the resume record lands (Resume 27), and the auditor's reading of a record younger than the widened bound as inconclusive (Standing rule 7). Invariant 1.3 makes the duplicate-freedom claim on the clock offset allowance alone. Rules 249 to 220. *Over:* an onboarding whose accept, records, enrollment and registration committed one by one, a fresh arc and every resumer holding a host's per-token critical section — taken at the accept or before the resume arm's first read, held to the return, released on return or death, leased for at least the widened bound, its expiry the invocation's terminus — so that a resumer past the bound enrolled beside neither a stalled original nor a second resumer. *Because:* the maintainer ruled 2026-10-12 that the corpus takes a store's specification, never the store, and 2026-10-20 that Store 1 binds every store write of one composition action, its constituents' included, that a refused attempt a page keeps as evidence stays a domain choice, and that Store 2 covers a guard decided across a lease check, since the lease's grant lives in the one store. Invitation, Party Identity, Credential and Audit Trail each supply their store under Store 1 through 4, and no action here makes an act outside the store, so an onboarding's writes commit together, no resumer re-enters an arc a fresh arc is still running, and the critical section only held two arcs' reads and writes apart, which Store 2 now serializes: a later resumer reads what the earlier one committed and decides again (Resume 7, 8). An Audit Trail refusal at a post-write record on the resume arm — its recording-failure, its invalid-request below step-4, or a landing read that finds no record — still leaves the invitation write an earlier onboarding committed and its record owed (Audit arm 5, 18, 22, 25), and so does a Party Identity or Credential storage failure on the resume arm (Audit arm 15, 16); outside the resume arm each refuses the whole call, its Invitation write with it, since Audit Trail's record action step 7.11 keeps only its own attestation and event (Execution Contract Constituent failure 1, Read 4). So the census's question is decided by that reading, not escalated: the read for the credential the arc registered (Action wiring 33, 35, Resume 39 through 47) is still reached by a foreign registration under the arc's party, and it stays; so do the stages, the young and dead resume records, the party read over the arc's window union with its candidates, the resume record and the acceptance record re-derived from the Invitation record (Resume 8 through 26, 28 through 33, 36), the read-back of an invalid-request at step-4 (Audit arm 8 through 11), and the interruption record's refusal that leaves the arc's answer standing (Action wiring 36). The resume arm reads the Event Log's own sequence (Resume 6, 33) and Credential keeps its rotations as records of its own (Check 2.2), so the composition cites neither Store 5 nor Order 1. What the composition does for its domain is unchanged.

- **2026-11-10 — The resume arm retired: an onboarding is one Recoverable Invocation act.** *Chose:* (Scott, 2026-11-09 8:46 PM and 9:17 PM Central, "Reuse the Recoverable Invocation pattern", then "A") [Onboard] binds one act kind, onboarding, keyed by the invitation token, with the transaction of accept, enroll and register as its bound commit; a credential collision is a pre-commit refusal that rolls the transaction back and leaves the invitation pending, the invocation refuse keeping the attempt; Resume 4 through 52 tombstoned to what owns them; a stopped onboarding is an open intent the operator closes through the invocation resolve; no service identity (Composes 15 and 16 stand), so Recoverable Invocation's closure is provisional here; [Invite], [Decline] and [Revoke] stay unbound; the acceptance, interruption and resume records retired; the foreign-party exclusion and the check of an operator's chosen party against the candidates retired, so Invariant 4.5 is detected through Check 7.3, not prevented. *Over:* keeping the committed collision and the resume arm, wrapped in Recoverable Invocation, which would have covered about 15 of its 49 rules and left the rest, where eleven of the last twelve foundational findings sat, the page's own. *Because:* Recoverable Invocation never re-runs an act (its reconcile step 3.7 and Non-goal 4), so it cannot finish a stopped arc, and the stopped arc existed only because the page made the collision an answer. *Costs:* a Lease host, the instance's bounds and a sweep; every caller-visible code of [Onboard] changes (act-in-flight, recording-failure in place of storage-failure(position), duplicate-active-credential a refusal); Party Identity and Credential keep no pairing datum, so every open intent goes to an operator, a sole candidate included.

## Ledger

The gate record the Ledger's `last gate:` line carried behind its latest until 2026-10-20:

- 2026-08-26 — Final Critique 7, fresh reader — 6 foundational (all since closed), 10 refining, 3 rhetorical

## Deleted rules

The spec's tombstones, moved here from the page on 2026-11-13 because the spec is done (GRACE-lang Hard invariant 25 and Hard invariant 27, since v0.71): each `Deleted:` line byte for byte and in the page's order, under the heading it stood under there. A tombstone carries no obligation, and each still reserves its label: no rule of [External Onboarding](./external-onboarding.md) may carry it again.

### Composition logic › Capability requirement

```
Deleted: Capability requirement 10. Recoverable Invocation Instance start 4 and Instance start 5 own it: the closure window and the retention period bound how long an intent stays open before the sweep reports it, and the resume arm whose gap this bounded retired (Scott, 2026-11-09 9:17 PM Central, option A).
Deleted: Capability requirement 13. Execution Contract Database 2 owns it.
Deleted: Capability requirement 14. Execution Contract Database 2 owns it.
Deleted: Capability requirement 15. Execution Contract Database 2 owns it: an arc's reads and the writes they decide are one transaction, and the composition names no critical section to release.
Deleted: Capability requirement 16. Execution Contract Database 2 owns it: an arc's reads and the writes they decide are one transaction, and the composition names no critical section to release.
Deleted: Capability requirement 17. Execution Contract Database 2 owns it: an arc's reads and the writes they decide are one transaction, and the composition names no critical section to lease.
Deleted: Capability requirement 20. Execution Contract Database 2 owns it: an arc's reads and the writes they decide are one transaction, and the composition names no critical section for a deployment to leave blank.
Deleted: Capability requirement 23. Recoverable Invocation Instance start 5 owns it: the audit horizon, the act kind's retention period, exceeds the retention floor.
Deleted: Capability requirement 24. Recoverable Invocation Instance start 4 owns it: the resume arm and its longest gap retired.
Deleted: Capability requirement 25. The foreign party read the max purge delay protected retired with the resume arm; Check 7.3 detects a party on two tokens' completion records inside the horizon (Invariant 4.5).
Deleted: Capability requirement 26. Capability requirement 25 retired; no max purge delay remains to leave blank.
```

### Composition logic › Primitive policy

```
Deleted: Primitive policy 7. The resume choice retired with the resume arm: [Onboard] takes no resume party id and no resume credential id, and always runs the onboarding transaction (Scott, 2026-11-09 9:17 PM Central, option A).
Deleted: Primitive policy 8. Primitive policy 7 retired; [Onboard] records no accept attempt, and its intent follows validation (Recoverable Invocation Action wiring 4).
Deleted: Primitive policy 9. Primitive policy 7 retired; the call carries no resume choice.
```

### Composition logic › Audit arm

```
Deleted: Audit arm 6. Execution Contract Database 1 owns it.
Deleted: Audit arm 7. Execution Contract Database 1 owns it.
Deleted: Audit arm 12. Execution Contract Database 1 owns it.
Deleted: Audit arm 15. Recoverable Invocation commit 3 owns it: Party Identity's storage-failure is a pre-commit arm of the onboarding transaction, answered as its own code.
Deleted: Audit arm 16. Recoverable Invocation commit 3 owns it: Credential's storage-failure is a pre-commit arm of the onboarding transaction, answered as its own code.
Deleted: Audit arm 18. No action answers storage-failure carrying outcome: Audit arm 5, 22 and 25 carry intent, and [Onboard]'s outcome-position failure is Recoverable Invocation's recording-failure(outcome).
Deleted: Audit arm 20. Execution Contract Database 1 owns it.
```

### Composition logic › Action wiring

```
Deleted: Action wiring 8. Recoverable Invocation open step 4.3 owns it: the invocation open records the intent carrying the intent data (Action wiring 56 and 57), and the intent is the attempt record.
Deleted: Action wiring 10. Execution Contract Database 1 owns it.
Deleted: Action wiring 11. Execution Contract Database 1 owns it: a fresh arc's writes commit together, and the composition names no critical section for the host to refuse.
Deleted: Action wiring 12. Execution Contract Database 2 owns it.
Deleted: Action wiring 13. Execution Contract Database 2 owns it: an arc's reads and the writes they decide are one transaction, and the composition names no lease to expire.
Deleted: Action wiring 14. Execution Contract Database 2 owns it: an arc's reads and the writes they decide are one transaction, and the composition names no critical section to lose.
Deleted: Action wiring 15. Execution Contract Database 1 owns it: a fresh arc's writes commit together, so no resumer re-enters an arc a fresh arc is still running.
Deleted: Action wiring 16. Execution Contract Database 1 owns it: a fresh arc's writes commit together, so no resumer re-enters an arc a fresh arc is still running.
Deleted: Action wiring 22. Recoverable Invocation owns it, and retires it: no resumable acceptance is read, and an open intent is closed by the invocation resolve (Scott, 2026-11-09 9:17 PM Central, option A).
Deleted: Action wiring 23. Action wiring 20 owns it: the stored terminal accepted answers invitation-invalid carrying already-resolved AND accepted, whatever the acceptor.
Deleted: Action wiring 25. Recoverable Invocation Action wiring 6 owns it: an adopter writes to the journal for the act only through the invocation open, the invocation close and the invocation refuse, so no acceptance record is written; the intent carries the document pair (Action wiring 57).
Deleted: Action wiring 27. Execution Contract Constituent failure 1 and Read 4 own it: a Party Identity refusal fails the whole call, so no interruption record commits for it.
Deleted: Action wiring 30. Unreachable: duplicate-active-credential refuses the onboarding transaction and rolls it back (Action wiring 32), so no interruption record is written; the interruption record retired with the resume arm.
Deleted: Action wiring 33. The resume arm retired; an open intent is closed by the invocation resolve (Scott, 2026-11-09 9:17 PM Central, option A).
Deleted: Action wiring 34. Resume 41 and Resume 45 own it, because the arc continues with the credential the arc registered, never the credential standing active.
Deleted: Action wiring 35. The resume arm retired; no call reads an arc's credential back.
Deleted: Action wiring 36. No interruption record is written (Action wiring 30).
Deleted: Action wiring 39. Execution Contract Database 2 owns it: an arc's reads and the writes they decide are one transaction, and the composition names no critical section to release.
```

### Composition logic › Wiring decision

```
Deleted: Wiring decision 3. Invitation Invariant 2 owns it, inherited (Composes 6): a second accept of an accepted token commits nothing and answers already-resolved (Action wiring 20), and a rolled-back accept is no acceptance (Execution Contract Database 3).
```

### Composition logic › Resume

```
Deleted: Resume 1. Execution Contract Database 2 owns it.
Deleted: Resume 2. Execution Contract Database 2 owns it: an arc's reads and the writes they decide are one transaction, and the composition names no critical section for the host to refuse.
Deleted: Resume 3. Execution Contract Database 2 owns it: an arc's reads and the writes they decide are one transaction, and the composition names no critical section to release.
Deleted: Resume 4. Recoverable Invocation Invariant 7.2 and reconcile step 1.2 own it: an intent past its horizon edge is no longer read, and a second call is refused by Invitation's single resolution through the invocation refuse (Action wiring 20).
Deleted: Resume 5. Recoverable Invocation Invariant 7.3 owns it: a purged intent is excluded before any read.
Deleted: Resume 6. Recoverable Invocation open step 3 owns it: the invocation open reads the act key's records in sequence order.
Deleted: Resume 7. Recoverable Invocation open step 3.9 owns it: the invocation open answers act-landed, which [Onboard] answers as invitation-invalid carrying already-resolved AND accepted (Action wiring 59).
Deleted: Resume 8. Recoverable Invocation open step 3.5 owns it: a young open intent answers act-in-flight.
Deleted: Resume 9. Recoverable Invocation open step 3.8 owns it: an aged open intent never blocks the invocation open, the sweep surfaces it and the operator closes it through the invocation resolve.
Deleted: Resume 10. Unreachable: an onboarding's writes commit together (Execution Contract Database 1), so no stage stops between them; the stage and the interruption record retired with the resume arm.
Deleted: Resume 11. Unreachable: Recoverable Invocation Action wiring 6 admits no adopter write to the journal beyond the invocation open, the invocation close and the invocation refuse, so no acceptance record is written or missing.
Deleted: Resume 12. Resume 11 owns it, as unreachable.
Deleted: Resume 13. Recoverable Invocation Primitive policy 9 owns it: the intent data carries the document pair (Action wiring 57).
Deleted: Resume 14. Resume 11 owns it, as unreachable: the intent is the arc's one record of the documents.
Deleted: Resume 15. Unreachable: no call resumes an arc, and the operator's disposition replaces it.
Deleted: Resume 16. Term onboarding probe owns it: the probe reads Party Identity with a query carrying no filter and selects the parties by the intent's document pair and enrolling actor reference.
Deleted: Resume 17. Term onboarding probe owns it, without the foreign party exclusion: a party on another token's records is found by Check 7.3, not excluded by the read (Scott, 2026-11-09 9:17 PM Central, option A).
Deleted: Resume 18. Term onboarding probe owns it: the probe selects the parties by the intent's enrolling actor reference, the original caller's.
Deleted: Resume 19. Term onboarding probe owns it: the probe reads a party in any state.
Deleted: Resume 20. Recoverable Invocation act probe 6a owns it: the probe never answers committed with pairing datum none, so a sole candidate is undecidable and the operator decides.
Deleted: Resume 21. Recoverable Invocation reconcile step 3.8 owns it: several candidates are undecidable and escalated.
Deleted: Resume 22. Recoverable Invocation resolve 1 owns it: the operator's disposition names the outcome, and the chosen party is detected against the candidates by Check 7.3, not prevented (Scott, 2026-11-09 9:17 PM Central, option A).
Deleted: Resume 22a. Resume 22 owns it.
Deleted: Resume 22b. Unreachable: no acceptance record exists.
Deleted: Resume 22c. Unreachable: no acceptance record exists.
Deleted: Resume 23. Resume 22 owns it.
Deleted: Resume 24. Recoverable Invocation reconcile step 3.11 owns it.
Deleted: Resume 25. Recoverable Invocation act probe 4 owns it: a read rejection answers unavailable.
Deleted: Resume 26. Recoverable Invocation act probe 4 owns it: the rejected query reaches the compliance surface.
Deleted: Resume 27. Execution Contract Database 1 owns it.
Deleted: Resume 28. Recoverable Invocation open step 4.3 owns it: every [Onboard] writes its own intent.
Deleted: Resume 29. Recoverable Invocation Primitive policy 23 owns it: recording-failure(intent).
Deleted: Resume 30. Unreachable: no acceptance record is written (Action wiring 25).
Deleted: Resume 30a. Resume 30 owns it, as unreachable.
Deleted: Resume 31. Recoverable Invocation reconcile step 3.7 owns it: the sweep never re-runs an act, and Party Identity's enroll runs only inside the onboarding transaction.
Deleted: Resume 32. Resume 31 owns it.
Deleted: Resume 33. Recoverable Invocation Primitive policy 4 and Invariant 3.1 own it: an outcome pairs with its intent by invocation id.
Deleted: Resume 34. Execution Contract Database 1 owns it.
Deleted: Resume 35. Recoverable Invocation Primitive policy 19 owns it.
Deleted: Resume 36. Recoverable Invocation Primitive policy 20 owns it.
Deleted: Resume 37. Execution Contract Database 1 owns it.
Deleted: Resume 38. Execution Contract Database 2 owns it: an arc's reads and the writes they decide are one transaction, and the composition names no critical section to take again.
Deleted: Resume 39. Term onboarding probe owns it: the probe reads the party's credentials of the intent's type; duplicate-active-credential is a pre-commit refusal now (Action wiring 32).
Deleted: Resume 40. Term onboarding probe owns it.
Deleted: Resume 41. Recoverable Invocation act probe 6a owns it: a sole credential candidate is undecidable.
Deleted: Resume 42. Recoverable Invocation reconcile step 3.8 owns it: the next action is the operator's the invocation resolve disposition (outcome, abandoned or escalated).
Deleted: Resume 43. Recoverable Invocation reconcile step 3.8 owns it.
Deleted: Resume 44. Resume 22 owns it.
Deleted: Resume 45. Resume 22 owns it.
Deleted: Resume 46. Recoverable Invocation reconcile step 3.11 owns it.
Deleted: Resume 47. Recoverable Invocation reconcile step 3.8a owns it; under service identity none the case reaches the compliance surface (Recoverable Invocation service identity 1b).
Deleted: Resume 48. Recoverable Invocation Primitive policy 41 owns it: invalid-request.
Deleted: Resume 49. Recoverable Invocation Primitive policy 41 and 43 own it.
Deleted: Resume 50. Recoverable Invocation Primitive policy 22 owns it.
Deleted: Resume 51. Resume 17 owns it: the foreign party read retired (Scott, 2026-11-09 9:17 PM Central, option A).
Deleted: Resume 52. Unreachable: an accepted invitation with no party cannot commit; the onboarding transaction is atomic (Execution Contract Database 1).
```

### Composition-level invariants › Invariant 1 — Invitation gates enrollment

```
  Deleted: Invariant 1.2. Recoverable Invocation reconcile step 3.7 owns it: no arc is resumed, the sweep never re-runs an act, and the invocation resolve calls no constituent.
  Deleted: Invariant 1.3. Invitation's single resolution owns it, whatever the clock: exactly one accept answers accepted for one token; and Recoverable Invocation's critical section keeps a second call off the act while the first runs.
```

### Generation acceptance › Conformance checks

```
Deleted: Check 5.3. Unreachable: no interruption record is written (Action wiring 30).
Deleted: Check 5.4. Unreachable: no resume record is written (Resume 33).
Deleted: Check 7.2. Unreachable: no interruption record or resume record is written, and a completion record's party id is the one the operator or the transaction names once (Check 7.3).
Deleted: Check 7.4. External check 10 owns it, because no record carries a second writer.
```

### Generation acceptance › External checks

```
Deleted: External check 5. Execution Contract Database 2 owns it.
Deleted: External check 6. Execution Contract Database 2 owns it.
Deleted: External check 11. The longest resume gap retired with the resume arm (Capability requirement 24).
```

### Generation acceptance › Standing rules

```
Deleted: Standing rule 7. Execution Contract Database 1 owns it.
```

### Edge cases › Clock semantics

```
Deleted: Clock semantics 2. Recoverable Invocation Allowance 4 and Allowance 6 own it: in-flight and aged are read at the reading, and an edge excludes a record from a pass.
Deleted: Clock semantics 3. Recoverable Invocation Invariant 7 owns it: the horizon edge is read toward not reading.
```

### Edge cases › Concurrency

```
Deleted: Concurrency 2. Execution Contract Database 2 owns it.
Deleted: Concurrency 3. Execution Contract Database 2 owns it: an arc's reads and the writes they decide are one transaction, and the composition names no holder for a resumer to race.
```
