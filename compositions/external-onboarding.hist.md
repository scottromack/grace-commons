---
title: External Onboarding — history
nav_exclude: true
search_exclude: true
---

# External Onboarding — history

The dated record of how [External Onboarding](./external-onboarding.md) got here, moved out of the spec on 2026-10-20 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- compositions/external-onboarding.md`.

## Decisions

Entries that record a migration rather than a turn the pattern took.

- **2026-09-23 — Rewritten in GRACE lang v0.61; twenty-one of twenty-four open Ledger lines closed by the rules that now own them, and nothing else changed but what each line asked for.** *Chose:* `Composes`, `Composition state`, `Capability requirement`, `Primitive policy`, `Audit arm`, `Action wiring`, `Wiring decision` and a `Resume` family for the resume arm as the surfaces; invariant numbers 1 through 5 unchanged; the seven prose checks kept as `Check 1.1` through `Check 7.4`, grouped by their old numbers, with the standing rules as a `Standing rule` family; `Non-goals` and `Edge cases` split; Standards renamed Standards references and moved to its place. The lines' own fixes, taken as the ledger prescribed them: the validation depth pinned pre-gate against each constituent's field rules (2026-08-26-f, Primitive policy 3 and 4); the decliner's identity declared unrecorded (2026-08-26-e, Action wiring 47, Non-goal 5); Invariant 2 re-scoped to the completion record's linkage (2026-08-26-i); the substrate's third invalid-request source named, Actor Identity's arm at the substrate's second step, and the read-back floored at the invocation's own attempt record (2026-08-30-c, Audit arm 8 through 12); Party Identity's invalid-query landed as the composition's own defect (2026-08-30-e, Resume 25 and 26); the candidates declared unfiltered by state, since a closed party the arc enrolled is still the arc's party (2026-08-30-k, Resume 19); every alert named onto the deployment's alerting surface (2026-08-30-l); the relation's cardinality and modality declared (2026-08-30-h); the comparisons' edges pinned by the operators (2026-08-30-f); an operational membership test for the horizon (2026-08-30-g); *rests on* in every invariant's WHY (2026-08-30-i); the examples' credential call matched to the atom's raw-material model and the concurrent example changed to the same-acceptor race (2026-08-26-k, 2026-08-30-o); acronyms glossed and the SOC 2 attribution corrected (2026-08-26-j, 2026-08-30-j, 2026-08-30-m); and the mismatch with Invitation's `Composition note 2` and `Composition note 3` noted here and corrected there (2026-08-30-n). *Over:* the prose spec. *Because:* the migration plan, and the standing rule that a migration closes a line only where a rule now owns what the line asked for. Three stay open: the resume arm's credential read-back (2026-08-30-d), which wants a design choice between walking predecessors and naming the head, and the two formal lines.

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
