---
title: Immutable Ledger with Selective Disclosure — history
nav_exclude: true
search_exclude: true
---

# Immutable Ledger with Selective Disclosure — history

The dated record of how [Immutable Ledger with Selective Disclosure](./immutable-ledger.md), named Immutable Transaction Ledger with Selective Disclosure until 2026-10-28, got here, moved out of the spec on 2026-10-21 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log --follow -- compositions/immutable-ledger.md`.

## Decisions

Entries that record a round, the treatment ahead of one, a model run or a migration rather than a turn the pattern took.

- **2026-06-10 — Invariant 1 is safety plus liveness, and the model checks the compensated arm.** *Chose:* state the disclosure-accountability binding as "no unsurfaced orphan" (safety) and "every orphan is eventually bound or surfaced" (liveness), and re-derive the model over the two truth-bearing sub-writes so the reachable orphan is in scope. *Over:* the original model's idealization, which committed the sub-writes as one atomic action. *Because:* Selective Disclosure writes first and irreversibly and no synchronous rollback exists, so the orphan is reachable by design and an invariant that assumed it away verified nothing.

- **2026-08-27 — The purged binding's key lives in the composition, and the unbindable orphan gets a terminal verdict.** *Chose:* `disclosure_to_event`'s purged half is truth-bearing under a durability obligation (extraction-pending against the Erasure Tombstone atom), and a deterministic invalid-request on the outcome write lands as a `ledger.disclosure_unbindable` marker read back as `binding-unbindable`. *Over:* configuring the substrate to carry `data.disclosure_id` on its destruction record, and retrying the unbindable orphan indefinitely under the recovery identity. *Because:* the substrate declares its destruction record carries no payload field, so the earlier obligation pinned a capability on a surface that disclaims it; and re-attestation changes only the credential, so an orphan the payload or policy refuses had no lawful terminal state until one was declared.

- **2026-08-29 — The scan is bounded and writes as the composition, the substrate's step decides the landing, and the seal is verified over its range.** *Chose:* a declared `disclosure_completion_bound` below which the orphan enumeration examines nothing, with the ledger horizon as its upper edge; every scan write attested under a declared recovery identity behind a `ledger.recovery_intended` record, the orphan paired to its intent by the reading step 3 now passes explicitly as `disclosed_at` (candidates named where undecidable, and an undetermined entry set omitted rather than asserted); a seam-injected invocation_id on every event payload so an indeterminate substrate arm is read back exactly; every transcription carrying `recording-failure(step)`, with step-4 and `invalid-request(step-4)` proceeding as landed at both actions; and [Verify Ledger]'s presentation keyed by `sequence_number` over the covering range `read_record` names. *Over:* an unbounded scan under an undeclared identity, a bare token that sent [Record Entry]'s caller back to append a second entry, and a one-payload presentation that returns a mismatch on every intact ledger under interval cadence. *Because:* an unbounded scan compensates in-flight disclosures beside their own outcome events and re-manufactures lawfully purged ones; a compensation the discloser did not make cannot be attested as theirs; the substrate's step-4 arm means the event exists; and a seal commits to a range (the frozen rules of 2026-08-29 — *A reconciliation is bounded at both ends*, *Recovery commits under a declared service identity*, *Intents pair with outcomes*, *A transcribed rejection arm keeps its payload*, *A seal presentation is keyed by log position*).

- **2026-08-30 — One writer per disclosure, the purged answer first, the outcome sized before the intent, the clock at the composition's seam, the position on the code.** *Chose:* [Disclose Subset] step 4 pre-checks under the per-disclosure_id section the scan also takes and adopts an existing `ledger.disclosed` as its own outcome, with an in-invocation retry counted by `outcome_retry_attempts` and the scan the only writer thereafter; the scan runs `disclosure_to_event`'s full rebuild as a write every cycle, under a declared `reconciliation_cadence` and the inequality `disclosure_completion_bound + reconciliation_cadence + outcome_write_latency <` the shortest retention period, so the index's purged half is captured before any purge can reach its event and a lost entry is honestly a loss; step 1 sizes the maximal outcome-and-compensation envelope against `payload_cap` before the intent, with `disclosed_entry_ids_cap` and `intent_candidates_cap` bounding the two set-valued fields; now declared host-injected at this composition's seam, one reading per invocation, with the pass-through to Selective Disclosure making the pairing equality by construction and the constituent's not-in-future guard named as the one cross-seam comparison; `recording-failure(intent | outcome)` on the [Disclose Subset] signature; [Verify Ledger] branching on retention state at its index hit and on coverage status at its presentation before any composition-side membership check; and — from the closure check — the per-disclosure_id section declared as the `disclosure_section` instance capability with lease semantics (taken at step 3's return, released on return or death, a lease exactly `disclosure_completion_bound` long whose expiry is the invocation's terminus, re-taken before any pre-check and never permitting an append past the bound), the bound restated seam-to-step-4, an adopted `entry_set_unresolved` event yielding `verification_bundle = unavailable(entry-set-unresolved)`, and every remaining "atomically" replaced by the ordered three-write sequence the protocol actually runs. *Over:* a bare append at step 4 beside a scan that starts at the bound; a truth-bearing half written only by a step an invocation may never reach; "foreclosed by construction" argued about the intent while the outcome and the compensation grow without a cap; a clock attributed to a substrate that exposes none; two dispositions on one token at the caller boundary; a payload-not-supplied verdict for a payload the substrate destroyed; a critical section attributed to the host in no Configuration entry, with no release or expiry bound; and a page that said *atomically* about a sequence its own edge case calls irreversible-then-compensated. *Because:* two compensators over one act land two outcomes the seal then protects; a truth-bearing index that presumes the fact was captured is a finding-generator against a durability obligation nobody breached; an unbounded set is an input, not a construction; a reading mislocated to a constituent mislocates every stamp the composition writes; a caller who cannot tell intent from outcome re-runs a committed disclosure; lawful destruction is not omission; a section nobody declared has no lease, and a lease no bound governs blocks the leg forever; and a bundle over a set no sealed record determines proves a set the composition never recorded (the frozen rules of 2026-08-30 — *A compensator is exclusive*, *Lawful destruction is answered before absence*, *An outcome is sized before the intent*, *Liveness is arithmetic*, *A stamp from another seam never decides a write alone*, *A composition's own rejection arm carries the retry bit*, and *Capability provenance* frozen — with §*A derived index splits at the horizon*'s truth-bearing half).

- **2026-09-24 — Rewritten in GRACE lang v0.61; twenty-three of twenty-five open Ledger lines closed by the rules that now own them.** *Chose:* `Composes`, `Composition state`, `Capability requirement` — which takes the prose's Configuration whole, the per-disclosure section renamed the disclosure exclusion because the grammar owns the noun *section* — `Primitive policy`, `Audit arm`, `Action wiring`, `Wiring decision` and `Reconciliation` as the surfaces, with the binding and authenticity verdicts as their own `Verdict` family; invariant numbers 1 through 4 and 6 unchanged, Invariant 5 tombstoned to Composes 5; the record checks renumbered as Conformance checks naming the rule each tests; the edge cases split into Non-goals and four Edge cases families. Choices the page left open, each decided by a standing rule: *produced by this composition* defined as *paired by the reconciliation's predicate*, with the ledger namespace and the disclosure write reserved to the composition and an unpaired record a write-ownership finding (2026-08-26-e, 2026-08-30-g); a declared [Reissue Bundle] rather than a dropped claim (2026-08-30-f — *as simple as possible without losing fidelity*: the prose leaned on a recovery path no surface declared); an entry unsealed or purged at bundle construction marked in the bundle per entry rather than refused (2026-08-26-i, 2026-08-30-d, -e — *make all things mean one thing*: the purge-between-check-and-bundle race already answered this way); blank refused with Selective Disclosure's own rule at step one (2026-08-30-c); binding-duplicate named as a fifth verdict (2026-08-30-a); and the constituent bars cited rather than counted (2026-08-26-f). *Over:* the prose's step lists, a lettered case list that skipped a letter, and a recovery path the page promised and the surface lacked. *Because:* the rules state each landing once; the two formal lines stay open because the model, not the page, is what they owe.

- **2026-10-07 — The second round on frozen text: three foundational, one here.** *Chose:* a refusal of its own for an index that gave no answer, since the index alone tells a purged disclosure from a gap (Action wiring 64 through 66; Reconciliation 31); the accountability proof's contents stated per verdict; a run's alert for an outcome the accounting store does not carry (Reconciliation 32). *Over:* widening store-unavailable to mean two stores. *Because:* the round's first and third passes each reached the same unowned read from different sides, and it had sat in this Ledger as a hardening line since the round before — a routed line a cold reader cannot see is found again, and promoted.

- **2026-10-07 — The first round on frozen text: nine foundational, cured after the third pass reported.** *Chose:* a binding that only a purge makes immutable, so a rebuild may move a live one to the lower sequence (Composition state 5); a retention record owed at the substrate's quiescence and not at the append (Invariant 3.4, Check 3.3); a bound on the reconciliation run and a horizon that exceeds a cadence and two runs (Capability requirement 32, 33); one refusal per call in a fixed order, with a read that concluded nothing ahead of the verdict it would have fed (Primitive policy 19 through 21); the escalated verdict behind the purged one (Verdict 4), and Check 1.9 tombstoned to Check 1.2, which already read the same records. *Over:* a second check for the unsettled escalation, written the unit before and found to overlap the first and to fail a conforming deployment whose records were placed late. *Because:* three passes that read one text returned 5, 3 and 2, and two of the nine were in rules a day old.

- **2026-10-07 — The bound pair's first three passes: fourteen foundational findings, each cured where it was found.** *Chose:* an operator's obligation to settle every escalation before its intent's horizon edge, with a settling period charged to retention, over a second index of escalated closings (Capability requirement 29 and 31); an orphan defined against the binding as well as the outcome, so no clock decides a finding (Term orphan record); a failure arm for every read this page makes, each naming the store that gave no answer, and for [Record Entry] a code that is never retried where the entry may be in the ledger — the substrate's step-3 failure included, since that page lands it for an append that may yet land (Primitive policy 16; Audit arm 26 through 30; Action wiring 57 through 60; Reconciliation 28 through 30); a ledger verification that counts from the enumeration on every call, the index supplying only what a destroyed payload once named (Action wiring 29; Action wiring 31 and 32 tombstoned); a reissue that answers a purged disclosure as purged (Action wiring 62); the recovery identity refused as a ledger entry's actor (Primitive policy 18). *Over:* reading a failed read as empty, the index as a verdict, and an escalation as an end state. *Because:* three cold passes over this page with the protocol as its constituent returned 3, 5 and 6 — and the adversarial pass found two defects in rules the first two passes' cures had written, which is why the cured text is owed a round of its own.

- **2026-10-07 — Bound to Recoverable Invocation as its pilot adopter: validate, open, commit, close; seventy-five rules deleted to tombstones that name their new owner.** *Chose:* the act kind ledger.disclosure on one Recoverable Invocation instance writing to this composition's Audit Trail instance (Composes 12 through 15); the act keyed by subject reference, recipient, scope and authority under the minted key deviation, the accounting write partitioned as Selective Disclosure states its arms, no commit fence, the disclosure instant as the pairing datum, the accounting store's read as the probe, the recovery identity as the service identity (Term disclosure binding); [Disclose Subset] as four calls with one route for each answer of the accounting write (Action wiring 3, 6, 47 through 54); the disclosed set recorded in the intent alone, since a recovered outcome carries only what the store re-derives (Composition state 16); the unbindable marker replaced by the protocol's escalation, read as binding-escalated through the protocol's own read (Verdict 4, 15); a reconciliation reduced to the binding rebuild and the reading of the accounting store for a record no intent carries (Reconciliation 1 through 4, 6, 7, 14, 27). *Over:* this page's own intent, outcome, per-disclosure exclusion, counted retry, rejection arms and compensating scan — the protocol other compositions also carry in their own words. *Because:* the roadmap names this page the pilot, with the deletion measured here before any other page is swept. Measured: 241 live rules to 190 — 75 deleted, 24 added — and the rules' own text 22% smaller; the page 3.8% larger, since every deleted rule leaves a tombstone and the binding is new prose; which is the roadmap's own reading, that owners fall where bytes may not. Four deleted rules said other than their new owner does, and the owner stands: a host freed the exclusion on a holder's death, where the protocol's model rejects that host (Recoverable Invocation act section 2); an invocation whose lease expired took the exclusion again, where it now never does (Recoverable Invocation act section 10); a refused accounting write left its intent standing with nothing after it, where a refusal record now closes it (Recoverable Invocation commit 2); and an intent appended behind a step-4 refusal was left standing, where it is now read back and the disclosure proceeds (Recoverable Invocation Primitive policy 20). One claim narrowed: no disclosure id under two live outcomes holds at quiescence, as far as the protocol's one-writer invariant reaches without a journal fence (Invariant 1.3). No pass has read the bound text; the page stays `partially resolved`.

- **2026-10-08 — The treatment before the confirming round: the guard given the invocation's reading, the outcome position its invocation, and the deciding count fixed in advance.** *Chose:* Selective Disclosure's seam injected with the invocation's own reading, so the not-in-future guard meets equal instants (Capability requirement 25); the invocation id carried on recording-failure carrying outcome, so a caller finds its own outcome and not a record of its key (Action wiring 68); the stopping rule in the Ledger ahead of the drain (2026-10-08-j). *Over:* one clock authority across two seams, which a read on two nodes inside the allowance still refused as the caller's fault; the accounting query by key, which an earlier disclosure of the same key can answer. *Because:* four rounds left the older tail flat at four, three, four and three, and a drain is worth running only if the round after it is counted by a rule written before it.

- **2026-10-08 — The fourth round on frozen text: a disclosure reaches its recipient once its outcome event lands.** *Chose:* Capability requirement 34 keyed to the outcome event, which the call's answer shows or [Verify Ledger] answering bound shows once the sweep has recovered the disclosure; the disclosure instant stated as the admission's, ahead of the transmission. *Over:* the call's answer alone, which strands every recovered disclosure; and Selective Disclosure's own order, transmission first, which leaves an abandoned invocation's transmitted data unaccounted with no re-run lawful. *Because:* a yielded disclosure ends recovered or abandoned, each order lost one of the two, and the outcome event is where both end.

- **2026-10-08 — The third round on frozen text: nine, eight here, and two cures by deletion.** *Chose:* Wiring decision 1 tombstoned to Invariant 1.3, which already said what was true of it; the accounting-horizon cover reduced to the ledger's own policy, the accounting store never bounded; both horizon conditions written in the strict form and priced with the run bound, the allowance and the settling period; an alert for a false closing and a fixed read order for the reconciliation; transmission only after the recording call answers. *Over:* qualifying the wiring decision's claim with every state that broke it. *Because:* the round found three defects in the two rounds' own cures, and where a rule was broken by the states the page calls lawful the rule that held them already existed.

- **2026-10-09 — Grounded (English) on Final Critique 14, on one sample, the formal layer pending.** *Chose:* the sixth round on frozen text as the clearance gate — zero foundational once its one report was adjudicated a second time, blind to what the count would decide; the formal-layer vote recorded yes, the model owed its re-derivation; refining findings cured in place where the cure adds no rule, the rest routed. *Over:* a seventh round before grounding. *Because:* the method grounds a page on a clean round and owes the second as its first scheduled rescan; the older tail ran 4, 3, 4, 3, 2 and then 0. Recoverable Invocation, which this page binds, stays draft with its own round owed, and a change there is a touch here.

- **2026-10-09 — The confirming round: the pre-registered rule counted two, and rounds continue.** *Chose:* the count by the line written before the treatment, every foundational finding adjudicated a second time, blind to the threshold, before it was counted; the accounting store's read lag, which the treatment had stated as a cost, owned instead by a capability (Capability requirement 35). *Over:* `partially resolved` as the resting state, which three older findings would have fixed. *Because:* two of the round's three foundational findings sat in older text and one in round four's own cure, and the older tail fell for the first time in five rounds: 4, 3, 4, 3, 2.

- **2026-10-19 — Final Critique 16 clean on the cured text; what the page waits on is 2026-10-19-e, not another round.** *Chose:* the round clean on three counted passes — six foundational reports, none standing, once the count was adjudicated a second time by a reader blind to what it would decide; the four refining findings left routed rather than cured in place, so the cleared text stands; the page kept `partially resolved`, since a foundational open line blocks grounding whatever a round returns. *Over:* curing Check 1.2's list and its WHY in place (2026-10-19-g), whose wording belongs beside 2026-10-19-e's cure; and another round on this text while 2026-10-19-e is open, which would read the same text and could not ground it. *Because:* the round was the first to read the formal-model commit's two load-bearing cures, the dead run Capability requirement 33 now budgets and the aged edge's second allowance and run bound, and found nothing they broke; what stands between the page and grounding is a false closing no operator corrects, and its cure turns on a question no rule here decides — whether the deployment declares how long its accounting store can still apply a disclosure write, so that an operator's abandonment waits it out and the correction is charged to the horizon, or the case is named a non-goal (Recoverable Invocation resolve 20a leaves the store's quiet to the operator's judgment).

- **2026-10-19 — The formal model re-derived over what is this page's own; the horizon budgets a dead run, and the page waits on a round for the cures.** *Chose:* three models against Recoverable Invocation's contracts, which that page's model proves — the binding, the binding index with the horizon, the reading of two stores — in place of the model of 2026-06-10 and its twin, which modelled a protocol that is now that page's (2026-08-29-a); Capability requirement 33 charged two cadences and three runs, as Recoverable Invocation Instance start 4 counts a dead sweep run, once the rebuild model lost an outcome's binding, unalerted, to one run that died before its write at the least horizon the page admitted; the aged edge moved by a second allowance and the run bound, its in-range comparison strict, once the reconcile model accused a falsely closed record of a write outside the composition (2026-10-09-m). *Over:* the models landed with their findings left as open lines, which would have verified a page that does not exist; and the edge's one-allowance form, which holds only where an intent's purge is judged on the clock that placed its deadline, which the substrate does not promise across nodes. *Because:* a vote-yes page writes its model's findings back into the English (the conflict protocol in `pressure-testing.md`), and a load-bearing edit returns a grounded page to `partially resolved` until a round reads it.

- **2026-10-19 — Grounded (English) again on Final Critique 15, the council's first round on the page; the model, not another round, is what it owes next.** *Chose:* the round clean on three counted passes — six foundational reports, none standing, once the count was adjudicated a second time by a reader blind to what it would decide; the three refining findings left routed rather than cured in place, so no rule changed and the cleared text is the text that stands. *Over:* another round before the formal model, which would read the same text again while the model the vote asks for is still owed (2026-08-29-a); and the redeclared Term disclosure instant rewritten in place, a load-bearing touch to a Term the round had just cleared. *Because:* the round read the page, unchanged since its fourteenth gate, against Recoverable Invocation as that page's rounds 13 through 17 cured it, and found nothing those cures broke here; a vote-yes page whose own claims are in no model gets the model before any further round.

- **2026-10-21 — The store's guarantees cited, not restated, and a disclosure's intent, accounting record and outcome one transaction.** *Chose:* Capability requirement 36 citing Execution Contract Store 1 through 4 for the store the three constituents' records and the binding index live in; the index durability tombstoned to Store 3 (Composition state 10, Capability requirement 19, 20) and the accounting store's read visibility to Store 2 and Store 3 (Capability requirement 35), as Recoverable Invocation's journal visibility went; Wiring decision 2, which denied an atomic set over the accounting record and the outcome event, to Store 1; Primitive policy 19 and Audit arm 14, which answered substrate codes Audit Trail's own rewrite removed (attribution not-recoverable at the record read, recording-failure at the retention step), to Store 1; and, by clause, the accounting write's lost reply out of the yield and its storage failure out of the refusals the protocol records (Action wiring 51, Term commit partition, Term disclosure refusal). Rules 228 to 222. *Over:* the turn of 2026-06-10, which re-derived the model over the two truth-bearing writes because the accounting record was written first with no synchronous rollback, and the ordered three-write sequence the 2026-08-30 turn put in place of every remaining *atomically*. *Because:* the maintainer ruled 2026-10-12 that the corpus takes a store's specification, never the store, and 2026-10-20 that Store 1 binds every store write of one composition action, its constituents' included. The accounting record is Selective Disclosure's record, a store write, so the census's question for this page, whether binding the record as Recoverable Invocation's act keeps it outside the transaction, is decided by that ruling: the intent, the record and the outcome commit in one transaction, and no disclosure write lands after its invocation's closing. The false closing of open line 2026-10-19-e, an operator's abandonment beside a disclosure write still in flight, therefore cannot happen on a deployment that keeps every rule, and the line closes as dissolved. A refused attempt the page keeps as evidence stays, as the same ruling has it: the refusal record is written with its intent. What the protocol still closes is what the audit trail's refusals leave (an outcome or a refusal record the substrate refuses), so the binding, the sweep, the settling of an escalation, the reconciliation's reading of two stores for a record no intent carries, and Reconciliation 33's alert for a record beside a refused or abandoned intent all stay. The ledger's order is Event Log's sequence and the checks compare an auditor's own reads, so the page cites neither Store 5 nor Order 1; what it does for its domain is unchanged.

- **2026-10-28 — Renamed Immutable Ledger with Selective Disclosure, from Immutable Transaction Ledger with Selective Disclosure.** *Chose:* the name without "Transaction", in the title and in every file the page owns: the spec at `compositions/immutable-ledger.md`, its history file, its three formal models with their 17 twins, 13 probes and configurations (each MODULE line renamed with its file) and its coverage file, each moved with `git mv` so `git log --follow` carries its history; every reference in the repository moved to the new path and name, so another page cites this one as Immutable Ledger before the label (GRACE-lang Hard invariant 28), and a dated record keeps the old name with the new one beside it. *Over:* keeping the old name, and a redirect from the old path. *Because:* the maintainer's ruling of 2026-10-28: "Transaction" is wrong as well as redundant, since the page's uses include HIPAA disclosure accounting and 21 CFR Part 11 submissions, which are no transactions, and a name should mean one thing everywhere, its file included; the repository has few outside links to keep. No obligation changed, so no round is owed.

- **2026-11-04 — The disclosure write's two arms follow the protocol, not one transaction.** *Chose:* the intent committed at the open, ahead of the disclosure write, so a storage-failure of the write is a refusal the protocol records and closes (Term disclosure refusal, Recoverable Invocation commit 2, commit 3), and a lost reply is unknown, yielded, and answered recording-failure(outcome) carrying the invocation id (Term commit partition, Action wiring 51, Recoverable Invocation commit 6, yield 7); the closure table says so in both cells. *Over:* the 2026-10-21 reading that Execution Contract Database 1 puts the intent, the accounting record and the outcome in one transaction. *Because:* Database 3 keeps what the invocation open acknowledged, Recoverable Invocation Non-goal 1 forbids describing open, commit and close as atomic, and Execution Contract's atomicity layers name this action the sequential-with-compensation worked form; three readers of Final Critique 18, on two models, each found the one-transaction cells against those rules, and the orphan example, the sweep and Reconciliation 14 and 33 are reachable only if the intent commits first. Open line 2026-10-19-e, closed as dissolved on 2026-10-21, is reopened, and the formal line owes a re-run (open 2026-11-04-a). Execution Contract Constituent failure 1 still reads as failing the whole composing action; the cure to it is a held method-page change.

## Ledger

The gate records the Ledger's `last gate:` line carried behind its latest until 2026-10-21, newest first:

- 2026-10-19 — Final Critique 15, the council's first round on the page, reading it unchanged since its fourteenth gate against Recoverable Invocation as that page's rounds 13 through 17 cured it, three fresh readers on free models (GRID Nemotron 3 Ultra, EOS LongCat 2.5 Preview, Linus MiMo V2.6 Flash), each handed only the round's reading set, three passes on one text (frozen at 6ac02aa); the round rests on three counted passes — foundational count 0 after triage (6 reports, 1 sent down to refining, 5 rejected on the text), the count adjudicated a second time by a reader blind to what it would decide, which placed none of the round's 16 reports foundational; 7 refining reports, 3 rhetorical reports; clean, the second clean round running
- 2026-10-09 — Final Critique 14, fresh reader, three passes on one text — 0 foundational (one reported, rejected by a second triage blind to what it would decide), 31 refining reports, 20 rhetorical reports; one sample

## Deleted rules

The spec's tombstones, moved here from the page on 2026-11-13 because the spec is done (GRACE-lang Hard invariant 25 and Hard invariant 27, since v0.71): each `Deleted:` line byte for byte and in the page's order, under the heading it stood under there. A tombstone carries no obligation, and each still reserves its label: no rule of [Immutable Ledger with Selective Disclosure](./immutable-ledger.md) may carry it again.

### Composes

```
Deleted: Composes 9. Recoverable Invocation Action wiring 4 owns it: an adopter's action runs validate, open, commit, close.
```

### Composition logic › Composition state

```
Deleted: Composition state 10. Execution Contract Database 3 owns it.
```

### Composition logic › Capability requirement

```
Deleted: Capability requirement 6. Execution Contract Logic confinement 15 owns it.
Deleted: Capability requirement 7. Recoverable Invocation close step 3.5 owns it: a retry ends at the lease, not at a count.
Deleted: Capability requirement 8. Recoverable Invocation Instance start 4 owns it: the cadence is the instance's.
Deleted: Capability requirement 9. Recoverable Invocation journal write bound 1 owns it.
Deleted: Capability requirement 10. Execution Contract Logic confinement 15 owns it.
Deleted: Capability requirement 11. Recoverable Invocation Instance start 5 owns it.
Deleted: Capability requirement 12. Recoverable Invocation act section 1 owns it, keyed by the act key (Recoverable Invocation open step 2.1).
Deleted: Capability requirement 13. Recoverable Invocation close step 4.2 owns it.
Deleted: Capability requirement 14. Recoverable Invocation act section 2 owns it, and reverses it: a host never frees the section on a holder's death.
Deleted: Capability requirement 15. Recoverable Invocation open step 2.1 owns it.
Deleted: Capability requirement 16. Recoverable Invocation act section 10 owns it.
Deleted: Capability requirement 17. Recoverable Invocation Capability requirement 11 owns it.
Deleted: Capability requirement 19. Execution Contract Database 3 owns it.
Deleted: Capability requirement 20. Execution Contract Database 3 owns it.
Deleted: Capability requirement 31. Recoverable Invocation Instance start 5 owns it: the act kind's retention period, the audit horizon, exceeds the retention floor, which carries the settling period and the run bound past the examine window end.
Deleted: Capability requirement 35. Execution Contract Database 2 and Execution Contract Database 3 own it.
```

### Composition logic › Primitive policy

```
Deleted: Primitive policy 7. Recoverable Invocation open step 1.4 owns it, sizing against the maximal envelope.
Deleted: Primitive policy 15. Primitive policy 8 owns it.
Deleted: Primitive policy 17. Primitive policy 8 owns it.
Deleted: Primitive policy 19. Execution Contract Database 1 owns it.
```

### Composition logic › Audit arm

```
Deleted: Audit arm 1. Recoverable Invocation Primitive policy 19 owns it.
Deleted: Audit arm 2. Recoverable Invocation Primitive policy 41 owns it.
Deleted: Audit arm 3. Recoverable Invocation Primitive policy 23 owns it.
Deleted: Audit arm 4. Recoverable Invocation Primitive policy 43 owns it.
Deleted: Audit arm 5. Recoverable Invocation Primitive policy 27 owns it.
Deleted: Audit arm 6. Recoverable Invocation Primitive policy 27 owns it.
Deleted: Audit arm 7. Recoverable Invocation Primitive policy 35 owns it, reading back by invocation id.
Deleted: Audit arm 8. Recoverable Invocation Primitive policy 28 owns it.
Deleted: Audit arm 9. Recoverable Invocation Primitive policy 28 owns it, as the hard alert.
Deleted: Audit arm 10. Recoverable Invocation Primitive policy 29 owns it.
Deleted: Audit arm 11. Recoverable Invocation Primitive policy 29 owns it: the retry ends at the terminus.
Deleted: Audit arm 12. Recoverable Invocation Primitive policy 30 owns it.
Deleted: Audit arm 13. Recoverable Invocation Primitive policy 31 owns it.
Deleted: Audit arm 14. Execution Contract Database 1 owns it.
Deleted: Audit arm 22. Recoverable Invocation Invariant 8.3 owns it.
Deleted: Audit arm 23. Recoverable Invocation Invariant 8.4 owns it.
Deleted: Audit arm 24. Recoverable Invocation Primitive policy 20 owns it, and Recoverable Invocation Primitive policy 21a proceeds where the read-back finds the intent.
Deleted: Audit arm 25. Recoverable Invocation Primitive policy 42 owns it.
```

### Composition logic › Action wiring

```
Deleted: Action wiring 4. Recoverable Invocation Primitive policy 10 owns it.
Deleted: Action wiring 5. Recoverable Invocation Invariant 1.1 owns it.
Deleted: Action wiring 7. Recoverable Invocation commit 3 owns it: a pre-commit arm answers the constituent's own code, storage-failure included.
Deleted: Action wiring 8. Recoverable Invocation commit 3 owns it.
Deleted: Action wiring 9. Recoverable Invocation commit 2 owns it, and reverses it: a refused commit is closed by a refusal record.
Deleted: Action wiring 10. Recoverable Invocation open step 2.1 owns it, taking the section ahead of the intent.
Deleted: Action wiring 11. Recoverable Invocation act section 10 owns it, and reverses it: an invocation whose lease expired never takes the section again.
Deleted: Action wiring 12. Recoverable Invocation close step 2.1 owns it.
Deleted: Action wiring 13. Recoverable Invocation close step 2.2 owns it.
Deleted: Action wiring 14. Recoverable Invocation act section 10 owns it.
Deleted: Action wiring 15. Recoverable Invocation close step 3.1 owns it.
Deleted: Action wiring 19. Recoverable Invocation Invariant 3.5 owns it: a sweep that cannot pair writes no outcome, so no outcome carries an unresolved set.
Deleted: Action wiring 21. Recoverable Invocation yield 3 owns it: no adopter touches the section.
Deleted: Action wiring 31. Action wiring 29 owns it: the enumeration runs on a hit and on a miss alike.
Deleted: Action wiring 32. Action wiring 29 owns it, and reverses it: the purged verdict's first clause needs the enumeration a purged hit was denied.
Deleted: Action wiring 46. Recoverable Invocation Primitive policy 4 owns it, and Action wiring 1 for a ledger entry.
```

### Composition logic › Wiring decision

```
Deleted: Wiring decision 1. Invariant 1.3 owns it: no disclosure id under two live outcome events at act quiescence, a purged and an escalated disclosure carrying none beside it.
Deleted: Wiring decision 2. Execution Contract Database 1 owns it.
```

### Composition logic › Reconciliation

```
Deleted: Reconciliation 5. Recoverable Invocation Invariant 7.2 owns it.
Deleted: Reconciliation 8. Recoverable Invocation reconcile step 2.1 owns it.
Deleted: Reconciliation 9. Recoverable Invocation reconcile step 2.3 owns it.
Deleted: Reconciliation 10. Recoverable Invocation reconcile step 2.5 owns it.
Deleted: Reconciliation 11. Recoverable Invocation Invariant 3.3 owns it, through the disclosure probe.
Deleted: Reconciliation 12. Recoverable Invocation reconcile step 3.8 owns it.
Deleted: Reconciliation 13. Recoverable Invocation reconcile step 3.10 owns it.
Deleted: Reconciliation 15. Recoverable Invocation reconcile step 3.11 owns it.
Deleted: Reconciliation 16. Recoverable Invocation Invariant 5.1 owns it.
Deleted: Reconciliation 17. Recoverable Invocation reconcile step 3.2 owns it.
Deleted: Reconciliation 18. Recoverable Invocation Invariant 5.2 owns it.
Deleted: Reconciliation 19. Recoverable Invocation Invariant 5.2 owns it.
Deleted: Reconciliation 20. Recoverable Invocation Invariant 5.3 owns it, and narrows it: a recovered outcome carries what the database re-derives and nothing of the intent's.
Deleted: Reconciliation 21. Recoverable Invocation Invariant 3.5 owns it.
Deleted: Reconciliation 22. Recoverable Invocation reconcile step 3.20 owns it.
Deleted: Reconciliation 23. Recoverable Invocation reconcile step 3.20 owns it.
Deleted: Reconciliation 24. Recoverable Invocation reconcile step 3.17 owns it.
Deleted: Reconciliation 25. Reconciliation 3 owns it.
Deleted: Reconciliation 26. Recoverable Invocation reconcile step 5.1 owns it.
```

### Composition logic › Verdict

```
Deleted: Verdict 6. Recoverable Invocation Which closing stands 2 owns it: an outcome supersedes an escalation it names.
```

### Composition-level invariants › Invariant 1 — Disclosure-accountability binding bijection

```
  Deleted: Invariant 1.1. Recoverable Invocation Invariant 4.1 owns it.
  Deleted: Invariant 1.2. Recoverable Invocation Invariant 4.2 owns it.
  Deleted: Invariant 1.5. Recoverable Invocation Invariant 5.2 owns it.
```

### Composition-level invariants › Invariant 4 — No disclosure unrecorded, structurally closed

```
  Deleted: Invariant 5. Composes 5 owns it.
```

### Composition-level invariants › Invariant 6 — Authentication precedes commitment

```
  Deleted: Invariant 6.1. Recoverable Invocation Invariant 1.1 owns it.
```

### Generation acceptance › Conformance checks

```
Deleted: Check 1.9. Check 1.2 owns it: an escalation left past its intent's horizon reads as the gap, and a second check of the same records overlapped the first.
Deleted: Check 1.6. Recoverable Invocation Check 2.5 owns it.
Deleted: Check 1.7. Recoverable Invocation Check 2.5 owns it.
Deleted: Check 1.8. Recoverable Invocation Check 4.1 owns it.
Deleted: Check 5.1. Recoverable Invocation Check 1.1 owns it.
Deleted: Check 5.2. Recoverable Invocation Primitive policy 5 owns it.
Deleted: Check 5.3. Recoverable Invocation Check 1.1 owns it.
Deleted: Check 5.4. Recoverable Invocation Check 3.1 owns it: an aged intent carries a closing inside the window.
Deleted: Check 5.5. Recoverable Invocation Check 1.4 owns it.
```
