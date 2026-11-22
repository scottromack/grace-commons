---
title: Defensible Retention — history
nav_exclude: true
search_exclude: true
---

# Defensible Retention — history

The dated record of how [Defensible Retention](./defensible-retention.md) got here, moved out of the spec on 2026-10-20 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- compositions/defensible-retention.md`.

## Decisions

Entries that record a round or a migration rather than a turn the pattern took.

- **2026-09-14 — Rewritten in GRACE lang v0.40; nothing but language changed except two rejection surfaces the prose misnamed.** *Chose:* `Composes`, `Composition state`, `Capability requirement`, `Primitive policy`, `Identity`, `Audit arm`, `Action wiring`, `Wiring decision` and `Reconciliation` as the wiring surfaces, with `Concurrency`, `Clock semantics` and `Atomic writes` as the edge-case families; the ten invariant numbers unchanged; the acceptance section's own two tiers carried across as `Check` and `External check`. *Over:* the prose spec. *Because:* the migration plan; `cites.py --into defensible-retention` finds nothing in the corpus citing this composition by label, so the rewrite carried no frozen-number risk. **No family was minted.** Every one of the sixteen is standard or already recurring, and two of them move: `Audit arm`, which [Login](./login.md) minted one migration earlier, reaches two specs and so meets Principle 2's recurrence half; `Reconciliation` reaches three and so stands as a promotion candidate under `GRACE-lang.md` Standard label 4. `Identity` is the grammar's own standard family taken for the first time by a composition — thirty specs carry it, all of them atoms that mint ids, and this composition mints none: what it owns is an equality the gate evaluates, which is the same question one layer out.

- **2026-09-14 — A constituent's storage failure surfaces as itself, and this composition's own recording failure carries its position.** *Chose:* storage-failure exported unchanged from all four state-changing actions, and `recording-failure(intent | outcome)` on every one of them. *Over:* the prose's mapping of a constituent storage-failure onto recording-failure, and a bare recording-failure on the three non-destructive actions. *Because:* the first renamed a failure to *write a record* into a failure to *record it*, which is a different fact and a different repair; the second put one token on both sides of the commit, so a caller who retried on it could not know whether anything had committed — which the corpus's own rule requires the exported code to answer.

- **2026-09-14 — The owed destruction record has exactly one writer.** *Chose:* an invocation retries its outcome until the retention completion bound and then yields; past the bound the record belongs to the sweep, which serializes its leg on the act's invocation id and re-reads the act's outcome under that serialization. *Over:* an out-of-band retry and a sweep both owing the same record with nothing between them. *Because:* two writers over one destruction land two record_purged events for one act, and the trail then protects both — the one failure a compensating write cannot undo.

- **2026-09-27 — The sweep can write the destruction record it owns, a closed marker stays closed, and the purge refusals take an order.** *Chose:* the purge intent carries the hold check result (Action wiring 76); intent_abandoned is an outcome; the not-eligible and under-active-retention rules apply only once the hold check admitted the destruction, and the second only over an elapsed named retention; a gate record that cannot land answers `recording-failure(gate)`. *Over:* a recovery outcome needing a hold check result no store carried, so every owed destruction record closed as abandoned; a closing no rule counted as an outcome, so the sweep re-closed it every run and Invariant 5.6 failed for every abandoned invocation; three refusal rules that could each demand their own answer for one call; and a position token with no member for the gate record. *Because:* the cold regeneration of 2026-09-27 met each — the owed record the 2026-09-14 decision gave the sweep could never be written.

- **2026-10-02 — The hold over an open entry is modelled: a suspended entry is a term, and closure sum budgets one hold placement.** *Chose:* Term suspended entry — an open entry a run landed under-legal-hold, until a later run reads no active hold — read by quiescence and by the audit edge, so the checks scoped to a quiescent cascade wait for the hold-free run (Term suspended entry, Term quiescence, Term audit edge); closure sum gaining `purge_completion_bound + reconciliation_cadence` WHERE Legal Hold EQUALS composed, one hold placement's lease and the run it displaces (Term closure sum, Audit Trail Instance start 17); `audit-trail-hold.tla` with five twins and three probes, and the enumerator's schedule carrying the placement. *Over:* a window counted from the entry's creation the moment the hold is released, before any run has read it free; a restart for every entry a placement touched, which Invariant 12.3 refuses; and a closure sum that budgets a dead run alone. *Because:* the model reaches an entry between its hold's release and the next run, open, not held and past its window, which Check 8.1 read as a conformance failure on a conforming instance — the residue of the finding four rounds reported; and a hold placement takes the entry's section by a waiting take while a leg skips a held section, so one placement costs the entry a run, and with the budgeted dead run the entry outlived closure sum on 2,508 of 2,592 composed tuples. With the part added none does, at zero slack, so it is the least that holds. The model also confirms what the page already said: a placement serialized by the section and a leg that writes nothing on an expired lease keep content from destruction under a hold, and a window restarted from the store's release instant, which a caller may backdate, breaches. Outside the budget, and unchanged: two hold placements over one entry inside one window.

- **2026-10-04 — Every act over a record runs under one record section, and the late hold is closed here.** *Chose:* a [Lease](../atoms/lease.md) on the record reference, taken before the gate read and held to the outcome by a placement, a hold placement, a hold release, a purge and a sweep leg (Concurrency 5 through 24, Reconciliation 20, 21, 30, 31); the atom's sizing rules stated as this composition's own over two kinds of write, a committing call on a live reading and a record_action above a start floor (Capability requirement 37 through 44); one refusal, section-unavailable, for a section held or run out before anything committed; the deployment bound to place and purge through this composition alone (Capability requirement 45 through 47). *Over:* a serialization the deployment owed and no rule sized (Capability requirement 34, 35, tombstoned), a late-hold race the page named and declined to close (Concurrency 1 through 3, tombstoned), and a sweep serialized on an invocation id by no declared means. *Because:* Retention Window re-grounded on Final Critique 7 obliging the pattern that owns joint enforcement to serialize a placement, the sibling read, a purge and a destruction over one record reference (its Simultaneous retention 5, 6), and Lease grounded on Final Critique 4 with the rules to do it by. Closes Ledger line 2026-10-03-a. The model is re-derived: the old one made the gate and the destruction one step, so it could not show the race at all; the 2026-08-29 line asking for the sweep in the model closes with it.

- **2026-10-04 — What the constituents now say is read as they say it.** *Chose:* a storage-failure from Retention Window's purge read as the retention retained and never as the record intact, with the deployment's destruction record named as where the record's fate is answered (Atomic writes 8, 9, Reconciliation 32, External check 8); the hold store's name matched at the gate (Action wiring 77, 78); the substrate's refusals read by the step they carry, and a step-3 failure never retried, since an append that did not answer may still land (Audit arm 2, 12, 13, 16, 17); a hold's order against a destruction decided against the purge intent, which lands under the section between the gate read and the destruction, and not against an outcome the sweep may write long after (Invariant 6.3, Check 1.4); a placement over a destroyed record refused and a pending sibling left to the sweep alone, since a purge call over one wrote a second record purged outcome for one destruction (Action wiring 93, 94, 95); a release ordered against a destruction by its intent's log position, as a placement is, since the two instants are read at two seams (Invariant 6.5, Check 1.3, Check 1.8); a sibling read as elapsed only past the clock offset allowance (Term elapsed retention); an outcome owed by a committed act and not by an admitted one, which a constituent may still refuse (Term committed purge); Invariant 7.4 tombstoned for Action wiring 53, and Invariant 1.2 restated as what a blocked purge never answers (Invariant 1.2, 1.5, 1.6); a recovered purge or release paired with the latest marker, which is the one that committed, and a placement paired by the ids its intent carries, since two placements with the same inputs are two acts and an old record with those inputs is none of them (Reconciliation 10 through 14, 34 through 38, Action wiring 102, 103, Concurrency 27, 28); the checks given a reading past the audit horizon, where a lawful act's own record has aged out (Check 1.10, 3.2, 3.4, 6.4); the section held over a step-3 refusal, whose append may still land (Concurrency 25); a release bound to this composition's surface as a placement is (Capability requirement 53). *Over:* a WHY that called the record intact after a failed purge, a gate that matched no store name, arms keyed on a source the substrate no longer reports, and a log-position test that read a recovered destruction as later than a hold it preceded. *Because:* each was a constituent's own rule this page contradicted or did not meet (Retention Window Purge persistence 1, 1a; Legal Hold Instance 5 through 7; Audit Trail's record action step 7), found by reading the three constituents as they stand after this campaign and by the three passes over the result.

- **2026-10-04 — The gated hold placement is the deployment's, and Legal Hold is a knob.** *Chose:* the hold placement a declared deployment facility with a term, a rule that no hold over this instance is placed outside it, a named non-goal, and two start refusals where it or its store is missing (Term hold placement, Capability requirement 69g, Non-goal 30, Capability requirement 71, 72); Legal Hold a knob with a default of absent and a setting rule (Term Legal Hold, Capability requirement 69h). *Over:* a seventh action on this composition, which would have to attest and record a placement Defensible Retention already attests; and an arm on Legal Hold's place, an atom that knows no lease. *Because:* the rule of 2026-10-02 lets an ownership finding close on a capability requirement that states the behaviour and its owner, the placement's rules already bound a party the page did not name, and the scan scheduler, the cadence driver and the erasure mechanism are owned the same way. Closes Ledger lines 2026-10-03-p and v.

- **2026-10-05 — The horizon is read from the log, the store answers what the index did, a record is sized whole, and one instance serves one composition.** *Chose:* a destroyed event later in the log as the sign that an intent's outcome may have aged out — an intent with such a stand-in is no open marker and the sweep leaves it — and the same reading for an auditor's pairing checks (Term stand-in, Reconciliation 5, 42, Check 5.4, 5.5, 6.5 through 6.7); one audit retention policy over every event the composition records, kept for the life of the instance (Capability requirement 57, 60); the horizon above an alert floor, with the escalation raised ahead of any take (Capability requirement 58, Reconciliation 43); the largest record sized whole against the payload cap before the first audit record is issued (Primitive policy 14, 23); not-known and the listing decided on Retention Window's store, and [Purge Eligible] refusing where that store cannot be read (Action wiring 32, 44, 45, 110, 111); a failed read ahead of the commit a storage-failure and after it an owed outcome, and an outcome the section admits no call of owed (Action wiring 98, 99, 109, Concurrency 34); a gate record owed only as the audit arms read it (Action wiring 85, Term owed record); one instance of the composition for each constituent instance (Capability requirement 59). *Over:* an edge a clock decided alone, which allowances and a leg's own span narrowed and never closed; an index a lost entry could make lie; field caps under a cap the substrate measures over the whole envelope; a gate record that had not landed, a condition three other rules also answered. *Because:* Resolve a Person's Data Rights' gate found its horizon assumed single and exact, and this page carried the same assumption (the batch rule — reference first, then swept, one closing round); the rest is what eighteen reader runs found on the way to one clean text, each a state two implementations would have answered differently. The models stand: no rule either one reads was changed.

- **2026-10-06 — The confirming round: what a reader would promote is cured before the reader runs, and a floor says what it does not promise.** *Chose:* one edge, *within the audit horizon*, for every horizon judgment a check makes, two allowances and the store's resolution inside the horizon (Term within the audit horizon, Check 6.4, Term aged-out hold, Term surviving destruction); the invariants that are owed at quiescence saying so, and over acts within the horizon (Invariant 3.1, 3.2, 4.1, 4.2, 8.1, 9.3, Term quiescence); an unverifiable answer over partly purged coverage read as unknown (Check 2.7); every overdue marker alerted on ahead of a run's first take, a run that cannot enumerate alerting on that, and a declared bound on a run's enumeration (Reconciliation 43, 44, Capability requirement 61, Term enumeration bound); an alert floor that promises the alert and a window to answer it and nothing of the closing after, and a closure floor that is the first leg's (Term alert floor, Term closure floor); one audit retention policy over every event of the audit instance, and the composition's action references kept to the composition (Capability requirement 57, 64); the recovery intent given its fields (Reconciliation 45, Term plan); an invocation id never given twice (Capability requirement 63, Check 5.10); a reference's field cap under the substrate's (Capability requirement 62); entry read from a hold placement's intent (Clock semantics 15). *Over:* check edges at the bare horizon while the sweep's stood inside it; invariants stated of every instant the rules themselves break for a while; a floor whose sentence promised a closing its arithmetic could not carry for a backlog; and a stand-in any co-tenant's short-lived event could supply. *Because:* the round the consecutive-rounds bar owed returned one foundational finding on five of its first seven Linus passes, and four of the five were lines this Ledger already carried as refining — the method cures a defect in the pass that finds it whatever its class, and a defect left on a Ledger is the next reader's finding. The models stand: no rule either one reads was changed.

- **2026-10-20 — The store's guarantees cited, not restated, and a store-only act's intent, write and outcome one transaction.** *Chose:* Capability requirement 65 citing Execution Contract Store 1 through 4 for the store of the three constituent instances; the rules restating what that store guarantees tombstoned to it (Capability requirement 49, External check 12); and the machinery that existed only because a placement's, a hold placement's or a hold release's intent, constituent write and outcome could come apart — the audit append held out of the act's transaction, each outcome ordered after its constituent commit, the ids a placement intent carried so the sweep could name the act an open marker had made, the read and the cap that list needed, the id a placement's outcome-position failure carried, and the index entries a recovered placement added (Atomic writes 1 through 4, Action wiring 102, 103, 104, 105, 107, Reconciliation 10, Composition state 34), with the reading of a recording-failure at step 4 as a landed record, a split Audit Trail's own rewrite removed (Audit arm 3, 4). Rules 513 to 499. *Over:* an audit append no host transaction could enlist, so that a store-only act's outcome followed its constituent's commit and the sweep recovered whatever a crash between the two left. *Because:* the maintainer ruled 2026-10-12 that the corpus takes a store's specification, never the store, and 2026-10-20 that Store 1 binds every store write of one composition action, its constituents' included, while a refused attempt a page keeps as evidence stays a domain choice, written in the same transaction as the refusal: so a refused act's intent still stands for the sweep to close as abandoned (Reconciliation 9, 28), the purge, whose destruction is an act outside the store, keeps its intent, its outcome and the sweep that recovers them, and the two indexes stay derived indexes outside every action's transaction (Composition state 20). What the composition does for its domain is unchanged.

- **2026-10-21 — The shred pattern named, and the gate's evidence provable.** *Chose:* *shred* (`glossary.md`) where the page wrote *cryptographic shredding*: Non-goal 16, under which a deployment needing a shred composes a shred pattern, with the composing patterns line and the owners NOTE; and *provable* (`glossary.md`: shown by the records alone, never by a system's say-so) where it wrote *from the records*, *records-alone* or their like, by wording alone: the Summary, the Intent, the gate's two halves, the [Hold Check Result] and [Hold Override] term entries, the override and spoliation examples, the acceptance bar and open line 2026-10-04-d; rules 499 to 499. *Over:* the phrases restated at each site. *Because:* the maintainer ruled 2026-10-21 that *shred*, *grant* and *provable* are declared domain terms, each defined once, in `glossary.md`, and that the specifications say them where their meaning stood; the wording of Non-goal 16 changed and no obligation did.

- **2026-10-21 — The erasure mechanism shreds, and the regulator's answer is provable.** *Chose:* *shred* (`glossary.md`: destroy the keys that decrypt a record's content, so the content cannot be recovered while every stored version stays as written) in place of the page's own Term shredding-class, deleted with its place on the terms line: erasure mechanism 1, under which the deployment wires an erasure mechanism that shreds, and External check 15, under which an auditor clears that it shreds, with *shred* among the record verbs; by wording alone, Boundary one's heading, the cascade-on-purge paragraph and its WHY, the bank example and the [Purge Event] term entry; and *provable* (`glossary.md`: shown by the records alone, never by a system's say-so) in the regulator-audit example and the acceptance bar; rules 749 to 749. The knob keeps its name, erasure mechanism, and the bank example's configuration value keeps its code spelling. *Over:* a shredding class declared on this page alone, holding the meaning the glossary now holds once. *Because:* the maintainer ruled 2026-10-21 that *shred*, *grant* and *provable* are declared domain terms, each defined once, in `glossary.md`, and that the specifications say them where their meaning stood, and Execution Contract Database 5 says a shred is not an erasure; the wording of erasure mechanism 1 and External check 15 changed and no obligation did.

- **2026-10-23 — The composition owns its records' destruction and makes it through a record destruction pattern.** *Chose:* the business retention instance supplied with the composition owning the destruction (Capability requirement 55, Retention Window Record divergence 4), as Audit Trail owns its own instance's, so Retention Window's purge is the state transition alone over it; the destruction made through a record destruction pattern, Record Destruction *(forthcoming)*, which a committed purge calls with the record reference while the grant still has the sibling floor, and which destroys only a record a purged retention names, keeps each confirmation and retries a record a purge left standing, as Retention Window Record divergence 4a through 6 ask of the owner (Capability requirement 66, Action wiring 112, Term record destruction pattern); that call a committing call, so it waits on the intent, the credential and a live reading of the record section as Retention Window's purge does, and its party bound by Lease Capability requirement 8 and 10 beside the constituents (Term committing call, Capability requirement 54, Term sibling floor, Term section work bound); Capability requirement 55 citing Retention Window Capability requirement 5 and 6a through 11, since 4, 4a and 6 are deleted; Term destroyed record's case of a record the storage layer destroyed under a purge that left every retention retained deleted, since nothing is destroyed before Retention Window's write commits; the Intent, [Purge Record], [Under Active Retention], the walkthrough and Term record saying who destroys; open line 2026-10-05-k closed as dissolved and 2026-10-04-j narrowed; rules 499 to 501. *Over:* the record destruction pattern owning the destruction itself, which Retention Window Record divergence 4 grants only to the pattern that wires the instance, and which its Simultaneous retention 6a would make owner of the joint enforcement this composition holds (Capability requirement 45, 46); and the business records kept in the database alone, removed by Retention Window's own purge, which would leave the electronically stored information, communications and non-erasable media this page governs with no one to destroy them. *Because:* the maintainer ruled on 2026-10-23 that every destruction outside the database is owned by a composing pattern, never by Retention Window, whose Record divergence 1 through 2b and Capability requirement 4, 4a and 6 this page's purge had rested on (Retention Window's 2026-10-03 entry: *Defensible Retention keeps a purge that destroys*), and no pattern in the corpus makes that destruction, so the pattern is named as forthcoming. What the gate decides, refuses and records is unchanged.

- **2026-11-01 — The cascade's purge and its destruction record commit together.** *Chose:* step 1's transition and step 2's destruction record committed as one transaction before the delegation, and step 3's outcome record in a transaction of its own after it (Invariant 4.2, 4.2a, Audit Trail record destruction step 2.9), so a step-2 failure leaves the retention as found, Retained for a first run (purge event 3), and a Purged retention with no destruction record stands only where a deployment fault leaves one. *Over:* step 1 committed alone before step 2 was written, the split Audit Trail record destruction step 2.9 kept through the 2026-10-20 sweep and Audit Trail read record step 4.4g and 4.4h served from Final Critique 41. *Because:* Execution Contract Database 1 commits every write of one action together, and the maintainer ruled 2026-10-20 that one transaction spans every store write of one composition action, its constituents' included; only the delegation, an act outside the store, stands between two of the cascade's writes, so only it splits the cascade's commits (Final Critique 59).

- **2026-11-02 — The audit instance's purge machinery arrived from Audit Trail (the maintainer's ruling of 2026-11-01 18:15Z, "Lawful destruction lives in one page", and his "as recommended" of 21:37Z).** See the Decisions entry of this date and [Audit Trail's history](./audit-trail.hist.md); this page's earlier claim that the audit cascade's gate was a non-goal (Non-goal 20 through 23) and a forthcoming Hold-Aware Audit Retention pattern's is withdrawn, the gate being this page's own.

- **2026-11-02 — The audit instance's end of life comes here from Audit Trail: lawful destruction lives in one page.** *Chose:* under the maintainer's ruling of 2026-11-01 18:15Z ("Lawful destruction lives in one page"), kept by his "as recommended" of 21:37Z, the purge machinery of [Audit Trail](./audit-trail.md) came here whole: Purge Eligible Events (named apart from this page's Purge Eligible, which answers the business retention instance) and Purge Event with their contracts and closure rows; the erasure mechanism and Legal Hold knobs (Capability requirement 69 through 72, Instance start 4, 31 and 32 of that page); the cascade's critical section (Cascade critical section 1 through 8); erasure outcomes; the first half of the reconciliation scan (First half 1 through 13); Boundary one; the cascade-on-purge rule and its WHY; Invariant 11 through 13; Check 8; External check 15 through 18; Non-goal 30; the edge case Legal hold suspension of purge; four open lines and four Decisions entries; the cascade reaches Audit Trail through its declared surface alone: step 0 and 0½ read the event through read_record and ask seal_now, step 1 calls record_destruction, which keeps the retention's purge and the destruction record in one transaction on Audit Trail's side (Audit Trail Invariant 4.2), step 3 delegates the shred (Composes 21, 22); Not Eligible and Under Legal Hold are shared with Purge Record; Composes 11 and Non-goal 20 tombstoned (the audit cascade is this page's own), Non-goal 22 cites Capability requirement 69g, and the Hold-Aware Audit Retention pattern this page named forthcoming is this page's own; the audit-trail-hold models renamed defensible-retention-audit-hold; a first closure table, covering the audit cascade (open line 2026-11-02-b); Audit Trail's open lines 2026-10-04-k and 2026-10-04-p arrived as 2026-10-04-t and 2026-10-04-u, their ids taken here; rules 499 to 657, lines 1,274 to 1,753. *Over:* keeping the cascade in Audit Trail and wrapping it here, which kept two pages over one act and Non-goal 20 through 23 as the debt; reaching the audit instance's indexes and records directly, which a composer's declared surfaces forbid; and moving the destruction record's write, which only Audit Trail's indexes and seal coverage can write consistently. *Because:* the end of a record's life is named once, and this composition exists to make record destruction lawful; no moved rule's content changed beyond the citations and the reads named above. Both pages owe a full round.

- **2026-11-18 — The business recovery retires to Execution Contract Database 1: Reconciliation 1 through 45 and what restated them, and nothing composes Recoverable Invocation.** *Chose:* Reconciliation 1 through 9, 11, 13 through 15, 17 through 31 and 33 through 45 (41 rules) go, with Composes 16 and 17, Capability requirement 17 through 21, 23, 44, 58 and 61, Composition state 7 and 33, Audit arm 8 and 9, Action wiring 62 and 70 through 72, Invariant 5.2, 5.3 and 9.4, Check 1.11, 3.3, 5.8, 5.9 and 6.8, External check 5, Concurrency 4, 25 and 34, Composition note 6 and 7, Reconciliation 32 (now Atomic writes 10) and about thirty Terms; every tombstone is in the blocks of *Deleted rules* above, each naming Database 1 and Read 4. The five business actions commit their intent, their constituent writes and their outcome in one transaction, so a purge whose outcome is owed, whose Retention Window call answers no answer or whose sibling cannot be purged commits nothing: Action wiring 68 and 80 answer storage-failure and Action wiring 81 section-unavailable (codes the page already uses, chosen from its own signatures and not from Recoverable Invocation's), and Action wiring 83 through 85 and 99 say the action commits nothing; no state holds an intent without its outcome, so Invariant 3.1, 3.2, 4.1, 4.2, 5.7, 8.1 and 9.3 lose "at quiescence". The call to the record destruction pattern follows the purge's commit (Action wiring 112; the walkthrough's step 5), and a record that call leaves standing is retried only under the record section and only where no active hold covers it (Capability requirement 67, 68). The page's rules fall by 75 (the Reader's IR counts 12,049 to 11,973 over the library, one of them Resolve a Person's Data Rights Check 3.6), its WHYs stay at three (the one after Term hold ids cap shortened). The Ledger's foundational line 2026-10-04-r closes by Database 1; twelve more open lines dissolve or close (2026-10-04-f, -k, -q, 2026-10-05-b, -e, -g, 2026-10-06-a, -b, -c, -f, -g and 2026-10-31-a) and eight narrow (2026-10-04-e, -h, -s, 2026-10-05-d, -i, 2026-10-06-e, 2026-10-25-b, 2026-11-02-c). The models follow: the outcome module with its three twins and probe retires whole; the gate module loses the sweep and the outcome, gains the destruction retry as a third party, `Inv_Withheld`, its twin `-buggy-retry-ungated` and the probe `-probe-withheld` (16,380 states); the Alloy model drops the sweep, the owed outcome, the pending sibling and quiescence, four twins retire and two are added so `A_Invariant_4_2`, `8_1` and `5_6` each keep one. Resolve a Person's Data Rights Check 3.6, whose one citation was Check 5.9, retires with it (that page's own history). *Over:* composing Recoverable Invocation, which the unit was queued to do: the map found no reachable state for it to act on, since every write is one store transaction (Execution Contract Database 1, Read 4 and Read 7), so the unit took the Login ruling's form (Scott, 2026-11-17 9:19 PM Central, "as recommended", item 2) and composes nothing. *Because:* a recovery with nothing to recover is rules that restate what the database already guarantees. One direction stays Scott's and did not block the build: the audit cascade's first half, a real wait on the erasure mechanism whose recovery re-drives the destruction, which Recoverable Invocation forbids, stays as it is (D1, rounds/escalations.md 2026-11-18 04:43Z). The map is rounds/dr-ri-map-2026-11-18.md in the council's folder, the one call of an Opus 5.5 subagent the unit's step 1 allows; the build ran in a scratch clone and reaches grace-commons as one commit.

- **2026-11-18 — A composition action reads the clock once: Composes 18 retires to Execution Contract Logic confinement 19, and Term elapsed retention keeps its allowance for the clock that set the deadline.** *Chose:* Composes 18 (the composition supplies the injected now to no constituent) leaves its `Deleted:` tombstone naming Logic confinement 19 and the ruling, never renumbered or reused, in the history file beside this page's other tombstones under *Composes*, where today's Composes 16 and 17 stand though the page is doing. Citations found, by label: none (`cites.py`: nothing rests on Composes 18); no formal model, twin or coverage row names it, so the formal line stands as written. Term elapsed retention's predicate stands as Final Critique 21 left it, and with it Composes 20, Clock semantics 4 and 5 and every rule that reads elapsed retention: a retention whose deadline does not exceed the injected now less the clock offset allowance. Its reason is restated: the allowance is for the clock of the call that placed the retention and set its deadline, set against this composition's reading (Execution Contract Logic confinement 18), since Retention Window's purge, a constituent call of [Purge Record], now reads this composition's now (Logic confinement 19), and the sentence that said Retention Window judges the purge on a reading of its own seam goes. Kept, each with its subject: Capability requirement 36 and Term clock offset allowance, Term log order, Term aged-out event and Clock semantics 11, 14 and 15, each about instants two calls, or a call and the substrate, stamped. Rules 1 fewer. *Over:* relaxing the predicate by its allowance: the deadline still comes from another call's clock, and the round of today settled the predicate. *Because:* Scott, 2026-11-18 6:52 AM Central, "YYY" (rounds/escalations.md 2026-11-18 12:52Z, item 2, on the measure of 06:09Z): a composition action reads the clock once, and every constituent call it makes takes that reading as its now, from MIT's sync-engine (github.com/mit-sdg/sync-engine), which binds one instant per causal flow. The page is doing and takes its round as queued.

- **2026-11-22 — The open lines are closed: twenty-three cured, two to Scott.** *Chose:* this page's four homonyms of Audit Trail's names renamed on this side (payload horizon, section call pause bound, seam offset allowance, cadence coverage; Audit Trail's purge edge allowance named as Audit Trail's); a hold placement and a hold release aged by the entry instant of their intent, never by the instant a caller may assert (Clock semantics 18); the sibling floor counting the read of the purge instant (three call pauses, Capability requirement 79); a retentions cap declared and refused at placement, with the largest purge record fitting the payload cap as a start condition (Capability requirement 81 through 83, Action wiring 113, per Scott's direction of 2026-11-19 that an attacker- or operator-controlled field takes an explicit cap and a refusal); a blank retention id refused at the boundary (Primitive policy 24); the indexes serving a reader's query alone, no action reading one, every rebuild leaving them agreeing (Composition state 21, 24, 26, 36); the first half reading an audit event's destruction through Audit Trail's read_record alone and no longer re-driving a divergence past the audit edge (Composes 23, First half 3, 14); a not-known from the destruction step landing as cascade-failure(step-1) (purge event step 1.3, Audit Trail Invariant 8.5); the cascade's hold read matched to the hold database name (purge event 5f); the refusals ahead of the intent and the take left ahead of the credential, named as non-goals with their reason (Non-goal 31, 32); the caller's retries ended at the first other answer (Action wiring 114, 115); the five business actions' closure rows written; the horizon alert's lead declared by the deployment (Capability requirement 84); a check per invariant that had none (Check 1.12, 1.13, 2.8 through 2.10, 3.8 through 3.10, 5.11, 6.10, 7.4). *Over:* leaving the homonyms qualified in the rules, a cap on [Purge Eligible] that would hide purge-ready retentions behind held ones, and extracting the audit hold gate as a pattern now. *Because:* each line was open on a page whose status is doing, and a rule of the corpus (Execution Contract Derived index 1, Legal Hold Instance 6 and 7, Audit Trail Invariant 8.5, Lease Sizing 3 and 5, Scott's directions of 2026-11-19) decided every one but two: whether the audit hold gate becomes a pattern of its own, and the shape of the purge-eligible list's pages, which went to Scott.

## Migration notes

- **2026-09-15 — Clock semantics 4, 5 and 16, kept under Clock semantics.** Clock semantics 4, Clock semantics 5 and Clock semantics 16 stay under Clock semantics rather than under Clock dependence: the first two are this layer's uses of the reading and the third says the gate makes none — instances of that family's question, not statements of it (council read 75).

## Deleted rules

The spec's tombstones, moved here from the page on 2026-11-13 because the spec is done (GRACE-lang Hard invariant 25 and Hard invariant 27, since v0.71): each `Deleted:` line byte for byte and in the page's order, under the heading it stood under there. A tombstone carries no obligation, and each still reserves its label: no rule of [Defensible Retention](./defensible-retention.md) may carry it again.

### Composes

```
Deleted: Composes 11. Composes 21 owns it: the audit instance's end of life is this composition's own, reached through Audit Trail's record_destruction.
Deleted: Composes 16. Execution Contract Database 1 owns it: the sweep this served retired with Reconciliation 1 through 45, the business acts being one transaction (Scott, 2026-11-17 9:19 PM Central, the Login ruling, applied by the map of 2026-11-18).
Deleted: Composes 17. Execution Contract Database 1 owns it: the sweep this barred retired with Reconciliation 1 through 45, the business acts being one transaction (Scott, 2026-11-17 9:19 PM Central, the Login ruling, applied by the map of 2026-11-18).
Deleted: Composes 18. Execution Contract Logic confinement 19 owns it: the host injects the invocation's one reading at the seam of every constituent call the invocation makes, so whether the composition supplies the injected now to a constituent or leaves the instant blank, the constituent records the same instant (Scott, 2026-11-18 6:52 AM Central, "YYY", rounds/escalations.md 2026-11-18 12:52Z, item 2).
```

### Composition logic › Composition state

```
Deleted: Composition state 34. Execution Contract Database 1 owns it.
Deleted: Composition state 33. Execution Contract Database 1 and Read 4 own it: an act and its records commit together or not at all, so no owed record or sweep remains (the Login ruling of 2026-11-17 9:19 PM Central, applied by the map of 2026-11-18).
Deleted: Composition state 7. Execution Contract Database 1 and Read 4 own it: a purge commits the named retention, every sibling and its outcome together or not at all, so no sibling is left pending (the Login ruling of 2026-11-17 9:19 PM Central, applied by the map of 2026-11-18).
```

### Composition logic › Composition state › erasure outcomes

```
  Deleted: erasure outcomes 5. Execution Contract Database 1, Execution Contract Database 3 and Execution Contract Database 4 own it.
```

### Composition logic › Capability requirement

```
Deleted: Capability requirement 3. Execution Contract Logic confinement 3 owns it.
Deleted: Capability requirement 5. Execution Contract Logic confinement 3 owns it.
Deleted: Capability requirement 34. Concurrency 5 owns it.
Deleted: Capability requirement 35. Concurrency 5 owns it.
Deleted: Capability requirement 49. Execution Contract Database 3 owns it.
Deleted: Capability requirement 51. Execution Contract Scheduled leg 1 owns it.
Deleted: Capability requirement 52. Execution Contract Scheduled leg 1 owns it.
Deleted: Capability requirement 56. Execution Contract Database 2 owns it: Audit Trail names no margin for a record action to start on.
Deleted: Capability requirement 61. Execution Contract Database 1 owns it: the sweep this served retired with Reconciliation 1 through 45, the business acts being one transaction (Scott, 2026-11-17 9:19 PM Central, the Login ruling, applied by the map of 2026-11-18).
Deleted: Capability requirement 58. Execution Contract Database 1 owns it: the sweep this served retired with Reconciliation 1 through 45, the business acts being one transaction (Scott, 2026-11-17 9:19 PM Central, the Login ruling, applied by the map of 2026-11-18).
Deleted: Capability requirement 44. Execution Contract Database 1 owns it: the sweep this served retired with Reconciliation 1 through 45, the business acts being one transaction (Scott, 2026-11-17 9:19 PM Central, the Login ruling, applied by the map of 2026-11-18).
Deleted: Capability requirement 23. Execution Contract Database 1 owns it: the sweep this served retired with Reconciliation 1 through 45, the business acts being one transaction (Scott, 2026-11-17 9:19 PM Central, the Login ruling, applied by the map of 2026-11-18).
Deleted: Capability requirement 21. Execution Contract Database 1 owns it: the sweep this served retired with Reconciliation 1 through 45, the business acts being one transaction (Scott, 2026-11-17 9:19 PM Central, the Login ruling, applied by the map of 2026-11-18).
Deleted: Capability requirement 20. Execution Contract Database 1 owns it: the sweep this served retired with Reconciliation 1 through 45, the business acts being one transaction (Scott, 2026-11-17 9:19 PM Central, the Login ruling, applied by the map of 2026-11-18).
Deleted: Capability requirement 19. Execution Contract Database 1 owns it: the sweep this served retired with Reconciliation 1 through 45, the business acts being one transaction (Scott, 2026-11-17 9:19 PM Central, the Login ruling, applied by the map of 2026-11-18).
Deleted: Capability requirement 18. Execution Contract Database 1 owns it: the sweep this served retired with Reconciliation 1 through 45, the business acts being one transaction (Scott, 2026-11-17 9:19 PM Central, the Login ruling, applied by the map of 2026-11-18).
Deleted: Capability requirement 17. Execution Contract Database 1 owns it: the sweep this served retired with Reconciliation 1 through 45, the business acts being one transaction (Scott, 2026-11-17 9:19 PM Central, the Login ruling, applied by the map of 2026-11-18).
```

### Composition logic › Primitive policy

```
Deleted: Primitive policy 15. Primitive policy 14 owns it.
```

### Composition logic › Audit arm

```
Deleted: Audit arm 3. Execution Contract Database 1 owns it.
Deleted: Audit arm 4. Execution Contract Database 1 owns it.
Deleted: Audit arm 8. Execution Contract Database 1 and Read 4 own it: an act and its records commit together or not at all, so no owed record or sweep remains (the Login ruling of 2026-11-17 9:19 PM Central, applied by the map of 2026-11-18).
Deleted: Audit arm 9. Execution Contract Database 1 and Read 4 own it: an act and its records commit together or not at all, so no owed record or sweep remains (the Login ruling of 2026-11-17 9:19 PM Central, applied by the map of 2026-11-18).
```

### Composition logic › Action wiring

```
Deleted: Action wiring 16. Execution Contract Constituent failure 1 owns it.
Deleted: Action wiring 21. Execution Contract Constituent failure 1 owns it.
Deleted: Action wiring 31. Execution Contract Constituent failure 1 owns it.
Deleted: Action wiring 42. Action wiring 111 owns it.
Deleted: Action wiring 67. Execution Contract Constituent failure 1 owns it.
Deleted: Action wiring 78. Action wiring 77 owns it.
Deleted: Action wiring 102. Execution Contract Database 1 owns it.
Deleted: Action wiring 103. Execution Contract Database 1 owns it.
Deleted: Action wiring 104. Execution Contract Database 1 owns it: a hold placement's intent, hold and outcome commit together, and the composition names no read ahead of the intent for Legal Hold to refuse.
Deleted: Action wiring 105. Execution Contract Database 1 owns it: a placement's intent, act and outcome commit together, and the composition names no id list for a placement intent to carry.
Deleted: Action wiring 107. Execution Contract Database 1 owns it.
Deleted: Action wiring 46. Composition state 19 owns it.
Deleted: Action wiring 51. Invariant 1.3 owns it.
Deleted: Action wiring 70. Execution Contract Database 1 and Read 4 own it: an act and its records commit together or not at all, so no owed record or sweep remains (the Login ruling of 2026-11-17 9:19 PM Central, applied by the map of 2026-11-18).
Deleted: Action wiring 71. Execution Contract Database 1 and Read 4 own it: an act and its records commit together or not at all, so no owed record or sweep remains (the Login ruling of 2026-11-17 9:19 PM Central, applied by the map of 2026-11-18).
Deleted: Action wiring 72. Execution Contract Database 1 and Read 4 own it: an act and its records commit together or not at all, so no owed record or sweep remains (the Login ruling of 2026-11-17 9:19 PM Central, applied by the map of 2026-11-18).
Deleted: Action wiring 62. Execution Contract Database 1 and Read 4 own it: a purge commits the named retention, every sibling and its outcome together or not at all, so no sibling is left pending (the Login ruling of 2026-11-17 9:19 PM Central, applied by the map of 2026-11-18).
```

### Composition logic › Action wiring › Purge Eligible Events contract

```
Deleted: purge eligible events 7. Execution Contract Error model 1 owns it: a declared read of Retention Window whose answer never arrives leaves [Purge Eligible Events] no answer to give, and none to read as an empty list.
```

### Composition logic › Wiring decision › Boundary one — only mechanisms that shred conform

```
Deleted: Boundary one 1. Audit Trail record destruction step 2.9 owns it.
Deleted: Boundary one 6. First half 5 owns it.
```

### Composition logic › Reconciliation

```
Deleted: Reconciliation 10. Execution Contract Database 1 owns it.
Deleted: Reconciliation 12. Reconciliation 9 owns it.
Deleted: Reconciliation 16. Reconciliation 14 owns it.
Deleted: Reconciliation 1. Execution Contract Database 1 owns it: the business acts are one transaction, so no state is left for a sweep to recover (Scott, 2026-11-17 9:19 PM Central, the Login ruling, applied by the map of 2026-11-18).
Deleted: Reconciliation 2. Execution Contract Database 1 owns it: the business acts are one transaction, so no state is left for a sweep to recover (Scott, 2026-11-17 9:19 PM Central, the Login ruling, applied by the map of 2026-11-18).
Deleted: Reconciliation 3. Execution Contract Database 1 owns it: the business acts are one transaction, so no state is left for a sweep to recover (Scott, 2026-11-17 9:19 PM Central, the Login ruling, applied by the map of 2026-11-18).
Deleted: Reconciliation 4. Execution Contract Database 1 owns it: the business acts are one transaction, so no state is left for a sweep to recover (Scott, 2026-11-17 9:19 PM Central, the Login ruling, applied by the map of 2026-11-18).
Deleted: Reconciliation 5. Execution Contract Database 1 owns it: the business acts are one transaction, so no state is left for a sweep to recover (Scott, 2026-11-17 9:19 PM Central, the Login ruling, applied by the map of 2026-11-18).
Deleted: Reconciliation 6. Execution Contract Database 1 owns it: the business acts are one transaction, so no state is left for a sweep to recover (Scott, 2026-11-17 9:19 PM Central, the Login ruling, applied by the map of 2026-11-18).
Deleted: Reconciliation 7. Execution Contract Database 1 owns it: the business acts are one transaction, so no state is left for a sweep to recover (Scott, 2026-11-17 9:19 PM Central, the Login ruling, applied by the map of 2026-11-18).
Deleted: Reconciliation 8. Execution Contract Database 1 owns it: the business acts are one transaction, so no state is left for a sweep to recover (Scott, 2026-11-17 9:19 PM Central, the Login ruling, applied by the map of 2026-11-18).
Deleted: Reconciliation 9. Execution Contract Database 1 owns it: the business acts are one transaction, so no state is left for a sweep to recover (Scott, 2026-11-17 9:19 PM Central, the Login ruling, applied by the map of 2026-11-18).
Deleted: Reconciliation 11. Execution Contract Database 1 owns it: the business acts are one transaction, so no state is left for a sweep to recover (Scott, 2026-11-17 9:19 PM Central, the Login ruling, applied by the map of 2026-11-18).
Deleted: Reconciliation 13. Execution Contract Database 1 owns it: the business acts are one transaction, so no state is left for a sweep to recover (Scott, 2026-11-17 9:19 PM Central, the Login ruling, applied by the map of 2026-11-18).
Deleted: Reconciliation 14. Execution Contract Database 1 owns it: the business acts are one transaction, so no state is left for a sweep to recover (Scott, 2026-11-17 9:19 PM Central, the Login ruling, applied by the map of 2026-11-18).
Deleted: Reconciliation 15. Execution Contract Database 1 owns it: the business acts are one transaction, so no state is left for a sweep to recover (Scott, 2026-11-17 9:19 PM Central, the Login ruling, applied by the map of 2026-11-18).
Deleted: Reconciliation 17. Execution Contract Database 1 owns it: the business acts are one transaction, so no state is left for a sweep to recover (Scott, 2026-11-17 9:19 PM Central, the Login ruling, applied by the map of 2026-11-18).
Deleted: Reconciliation 18. Execution Contract Database 1 owns it: the business acts are one transaction, so no state is left for a sweep to recover (Scott, 2026-11-17 9:19 PM Central, the Login ruling, applied by the map of 2026-11-18).
Deleted: Reconciliation 19. Execution Contract Database 1 owns it: the business acts are one transaction, so no state is left for a sweep to recover (Scott, 2026-11-17 9:19 PM Central, the Login ruling, applied by the map of 2026-11-18).
Deleted: Reconciliation 20. Execution Contract Database 1 owns it: the business acts are one transaction, so no state is left for a sweep to recover (Scott, 2026-11-17 9:19 PM Central, the Login ruling, applied by the map of 2026-11-18).
Deleted: Reconciliation 21. Execution Contract Database 1 owns it: the business acts are one transaction, so no state is left for a sweep to recover (Scott, 2026-11-17 9:19 PM Central, the Login ruling, applied by the map of 2026-11-18).
Deleted: Reconciliation 22. Execution Contract Database 1 owns it: the business acts are one transaction, so no state is left for a sweep to recover (Scott, 2026-11-17 9:19 PM Central, the Login ruling, applied by the map of 2026-11-18).
Deleted: Reconciliation 23. Execution Contract Database 1 owns it: the business acts are one transaction, so no state is left for a sweep to recover (Scott, 2026-11-17 9:19 PM Central, the Login ruling, applied by the map of 2026-11-18).
Deleted: Reconciliation 24. Execution Contract Database 1 owns it: the business acts are one transaction, so no state is left for a sweep to recover (Scott, 2026-11-17 9:19 PM Central, the Login ruling, applied by the map of 2026-11-18).
Deleted: Reconciliation 25. Execution Contract Database 1 owns it: the business acts are one transaction, so no state is left for a sweep to recover (Scott, 2026-11-17 9:19 PM Central, the Login ruling, applied by the map of 2026-11-18).
Deleted: Reconciliation 26. Execution Contract Database 1 owns it: the business acts are one transaction, so no state is left for a sweep to recover (Scott, 2026-11-17 9:19 PM Central, the Login ruling, applied by the map of 2026-11-18).
Deleted: Reconciliation 27. Execution Contract Database 1 owns it: the business acts are one transaction, so no state is left for a sweep to recover (Scott, 2026-11-17 9:19 PM Central, the Login ruling, applied by the map of 2026-11-18).
Deleted: Reconciliation 28. Execution Contract Database 1 owns it: the business acts are one transaction, so no state is left for a sweep to recover (Scott, 2026-11-17 9:19 PM Central, the Login ruling, applied by the map of 2026-11-18).
Deleted: Reconciliation 29. Execution Contract Database 1 owns it: the business acts are one transaction, so no state is left for a sweep to recover (Scott, 2026-11-17 9:19 PM Central, the Login ruling, applied by the map of 2026-11-18).
Deleted: Reconciliation 30. Execution Contract Database 1 owns it: the business acts are one transaction, so no state is left for a sweep to recover (Scott, 2026-11-17 9:19 PM Central, the Login ruling, applied by the map of 2026-11-18).
Deleted: Reconciliation 31. Execution Contract Database 1 owns it: the business acts are one transaction, so no state is left for a sweep to recover (Scott, 2026-11-17 9:19 PM Central, the Login ruling, applied by the map of 2026-11-18).
Deleted: Reconciliation 33. Execution Contract Database 1 owns it: the business acts are one transaction, so no state is left for a sweep to recover (Scott, 2026-11-17 9:19 PM Central, the Login ruling, applied by the map of 2026-11-18).
Deleted: Reconciliation 34. Execution Contract Database 1 owns it: the business acts are one transaction, so no state is left for a sweep to recover (Scott, 2026-11-17 9:19 PM Central, the Login ruling, applied by the map of 2026-11-18).
Deleted: Reconciliation 35. Execution Contract Database 1 owns it: the business acts are one transaction, so no state is left for a sweep to recover (Scott, 2026-11-17 9:19 PM Central, the Login ruling, applied by the map of 2026-11-18).
Deleted: Reconciliation 36. Execution Contract Database 1 owns it: the business acts are one transaction, so no state is left for a sweep to recover (Scott, 2026-11-17 9:19 PM Central, the Login ruling, applied by the map of 2026-11-18).
Deleted: Reconciliation 37. Execution Contract Database 1 owns it: the business acts are one transaction, so no state is left for a sweep to recover (Scott, 2026-11-17 9:19 PM Central, the Login ruling, applied by the map of 2026-11-18).
Deleted: Reconciliation 38. Execution Contract Database 1 owns it: the business acts are one transaction, so no state is left for a sweep to recover (Scott, 2026-11-17 9:19 PM Central, the Login ruling, applied by the map of 2026-11-18).
Deleted: Reconciliation 39. Execution Contract Database 1 owns it: the business acts are one transaction, so no state is left for a sweep to recover (Scott, 2026-11-17 9:19 PM Central, the Login ruling, applied by the map of 2026-11-18).
Deleted: Reconciliation 40. Execution Contract Database 1 owns it: the business acts are one transaction, so no state is left for a sweep to recover (Scott, 2026-11-17 9:19 PM Central, the Login ruling, applied by the map of 2026-11-18).
Deleted: Reconciliation 41. Execution Contract Database 1 owns it: the business acts are one transaction, so no state is left for a sweep to recover (Scott, 2026-11-17 9:19 PM Central, the Login ruling, applied by the map of 2026-11-18).
Deleted: Reconciliation 42. Execution Contract Database 1 owns it: the business acts are one transaction, so no state is left for a sweep to recover (Scott, 2026-11-17 9:19 PM Central, the Login ruling, applied by the map of 2026-11-18).
Deleted: Reconciliation 43. Execution Contract Database 1 owns it: the business acts are one transaction, so no state is left for a sweep to recover (Scott, 2026-11-17 9:19 PM Central, the Login ruling, applied by the map of 2026-11-18).
Deleted: Reconciliation 44. Execution Contract Database 1 owns it: the business acts are one transaction, so no state is left for a sweep to recover (Scott, 2026-11-17 9:19 PM Central, the Login ruling, applied by the map of 2026-11-18).
Deleted: Reconciliation 45. Execution Contract Database 1 owns it: the business acts are one transaction, so no state is left for a sweep to recover (Scott, 2026-11-17 9:19 PM Central, the Login ruling, applied by the map of 2026-11-18).
Deleted: Reconciliation 32. Atomic writes 10 owns it: no abandoned purge intent survives, so the reader's rule is stated of the record purged outcome (the Login ruling of 2026-11-17 9:19 PM Central, applied by the map of 2026-11-18).
```

### Composition logic › Reconciliation › First half — the half-completed cascade

```
Deleted: First half 4. First half 3 owns it.
Deleted: First half 8. First half 5 owns it.
```

### Composition-level invariants › Invariant 1 — Hold-blocks-purge

```
  Deleted: Invariant 1.4. Wiring decision 1 owns it.
```

### Composition-level invariants › Invariant 7 — Multi-hold independence

```
  Deleted: Invariant 7.4. Action wiring 53 owns it.
```

### Composition-level invariants › Invariant 9 — Cross-retention joint enforcement

```
  Deleted: Invariant 9.2. Composition state 19 owns it.
Deleted: Invariant 9.4. Execution Contract Database 1 and Read 4 own it: a purge commits the named retention, every sibling and its outcome together or not at all, so no sibling is left pending (the Login ruling of 2026-11-17 9:19 PM Central, applied by the map of 2026-11-18).
```

### Generation acceptance › Conformance checks

```
Deleted: Check 2.3. Check 2.4 owns it.
Deleted: Check 6.8. Execution Contract Database 1 owns it: the sweep this served retired with Reconciliation 1 through 45, the business acts being one transaction (Scott, 2026-11-17 9:19 PM Central, the Login ruling, applied by the map of 2026-11-18).
Deleted: Check 1.11. Execution Contract Database 1 and Read 4 own it: an act and its records commit together or not at all, so no open marker or sweep remains (the Login ruling of 2026-11-17 9:19 PM Central, applied by the map of 2026-11-18).
Deleted: Check 5.8. Execution Contract Database 1 and Read 4 own it: an act and its records commit together or not at all, so no open marker or sweep remains (the Login ruling of 2026-11-17 9:19 PM Central, applied by the map of 2026-11-18).
Deleted: Check 5.9. Execution Contract Database 1 and Read 4 own it: an act and its records commit together or not at all, so no open marker or sweep remains (the Login ruling of 2026-11-17 9:19 PM Central, applied by the map of 2026-11-18).
Deleted: Check 3.3. Execution Contract Database 1 and Read 4 own it: a purge commits the named retention, every sibling and its outcome together or not at all, so no sibling is left pending (the Login ruling of 2026-11-17 9:19 PM Central, applied by the map of 2026-11-18).
```

### Generation acceptance › External checks

```
Deleted: External check 12. Execution Contract Database 3 owns it.
Deleted: External check 14. Execution Contract Scheduled leg 1 owns it.
Deleted: External check 5. Execution Contract Database 1 owns it: the sweep this served retired with Reconciliation 1 through 45, the business acts being one transaction (Scott, 2026-11-17 9:19 PM Central, the Login ruling, applied by the map of 2026-11-18).
```

### Non-goals

```
Deleted: Non-goal 20. Capability requirement 69 owns it: this composition gates the audit instance's cascade, which moved here from Audit Trail.
```

### Edge cases › Atomic writes

```
Deleted: Atomic writes 1. Execution Contract Database 1 owns it.
Deleted: Atomic writes 2. Execution Contract Database 1 owns it.
Deleted: Atomic writes 3. Execution Contract Database 1 owns it.
Deleted: Atomic writes 4. Execution Contract Database 1 owns it.
Deleted: Atomic writes 7. Execution Contract Database 1 and Read 4 own it: an act and its records commit together or not at all, so no owed record or sweep remains (the Login ruling of 2026-11-17 9:19 PM Central, applied by the map of 2026-11-18).
```

### Edge cases › Clock semantics

```
Deleted: Clock semantics 2. Action wiring 8 owns it.
Deleted: Clock semantics 1. Execution Contract Logic confinement 3 owns it.
Deleted: Clock semantics 3. Action wiring 106 owns it.
Deleted: Clock semantics 6. Composes 18 owns it.
Deleted: Clock semantics 7. Retention Window Operation 13 owns it.
Deleted: Clock semantics 8. Execution Contract Logic confinement 12 owns it.
Deleted: Clock semantics 9. Execution Contract Logic confinement 12 owns it.
Deleted: Clock semantics 10. Event Log Operation 2 owns it, reached through Audit Trail.
Deleted: Clock semantics 12. Action wiring 106 owns it.
Deleted: Clock semantics 13. Action wiring 106 owns it.
Deleted: Clock semantics 17. Capability requirement 36 owns it.
```

### Edge cases › Concurrency

```
Deleted: Concurrency 1. Concurrency 5 owns it.
Deleted: Concurrency 2. Concurrency 5 owns it.
Deleted: Concurrency 3. Concurrency 5 owns it.
Deleted: Concurrency 4. Execution Contract Database 1 and Read 4 own it: an act and its records commit together or not at all, so no owed record or sweep remains (the Login ruling of 2026-11-17 9:19 PM Central, applied by the map of 2026-11-18).
Deleted: Concurrency 34. Execution Contract Database 1 and Read 4 own it: an act and its records commit together or not at all, so no owed record or sweep remains (the Login ruling of 2026-11-17 9:19 PM Central, applied by the map of 2026-11-18).
Deleted: Concurrency 25. Audit Trail's record action commits nothing on a recording-failure carrying step-3 (its record action step 3.3, 3.7), so no append is left to land and no hold on the section remains; Concurrency 24 and 33 lose the clause that named it (the Login ruling of 2026-11-17 9:19 PM Central, applied by the map of 2026-11-18).
```


### Composition notes

```
Deleted: Composition note 6. Execution Contract Database 1 and Read 4 own it: an act and its records commit together or not at all, so no owed record or sweep remains (the Login ruling of 2026-11-17 9:19 PM Central, applied by the map of 2026-11-18).
Deleted: Composition note 7. Execution Contract Database 1 and Read 4 own it: an act and its records commit together or not at all, so no owed record or sweep remains (the Login ruling of 2026-11-17 9:19 PM Central, applied by the map of 2026-11-18).
```

### Composition-level invariants › Invariant 5

```
Deleted: Invariant 5.2. Execution Contract Database 1 and Read 4 own it: an act and its records commit together or not at all, so no open marker or sweep remains (the Login ruling of 2026-11-17 9:19 PM Central, applied by the map of 2026-11-18).
Deleted: Invariant 5.3. Execution Contract Database 1 and Read 4 own it: an act and its records commit together or not at all, so no open marker or sweep remains (the Login ruling of 2026-11-17 9:19 PM Central, applied by the map of 2026-11-18).
```