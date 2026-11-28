---
title: Event Log — history
nav_exclude: true
search_exclude: true
---

# Event Log — history

The dated record of how [Event Log](./event-log.idd) got here, moved out of the spec on 2026-10-19 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- atoms/event-log.md`.

## Decisions

Entries that record a round or a migration rather than a turn the pattern took.

- **2026-11-20 — The deployment supplies each log instance's name and begins each fresh instance.** *Chose:* Capability requirement 5 (the deployment supplies the log name of every instance it runs) and Capability requirement 6 (the deployment begins a fresh instance for every instance a composing pattern owns, Identity 10), State 3 and State 5 unchanged. *Over:* naming the composing pattern as the supplier, or leaving both unstated. *Because:* no operation reads the log name and nothing in a call depends on who gave it, so it bears on neither interoperability nor audit across deployments and is operating policy, which the ruling of 2026-11-19 (group 4) sends to a deployment capability; the composing pattern already owns how many instances run (Identity 10), so the deployment begins that many. The second open line (landed and event field declared twice) is cured in the same commit by citing each at its owner (GRACE-lang Closed vocabulary 15).

- **2026-09-11 — Rewritten in GRACE lang v0.35; nothing but language changed.** *Chose:* labelled rules in fenced blocks, the two actions as a signature block, rationale under `WHY:`, terms declared where they are used, the invariant numbers frozen exactly as the compositions cite them, Non-goals and Edge cases as two sections, the case table kept beside the rules. *Over:* the prose spec. *Because:* the migration plan takes the atoms the migrated compositions already cite first — Audit Trail and Recoverable Invocation cite this atom's Invariants 1, 2, 3, 5 and 7, and a rewrite that moved a number would break those citations silently (`tools/grace/cites.py --into event-log`).

- **2026-09-14 — The atom gained an acceptance surface, and the external half is the load-bearing half.** *Chose:* fifteen `Check` rules cleared from one log instance and its read surface, and six `External check` rules naming what the log cannot show about itself. *Over:* declining by delegation, which would have been false — this atom is composed directly, not only through a substrate. *Because:* presence became mandatory on 2026-09-14, and this atom is the corpus's Start Here: it claims append-only, total order and read consistency while the evidence sat in a formal model, a twin suite and five independent renders, none of which a first reader has met. The section is the bridge. `External check 4` is the line that had to be written down — **append-only is not tamper-evidence**, every conformance check above passes over a log an adversary rewrote, and the atom compares the log only against itself (council read 65).

- **2026-10-19 — The store's guarantees cited, not restated.** *Chose:* the store supplied under Execution Contract Store 1 through 4 (Capability requirement 2), and the eleven rules that restated them tombstoned to their owner — Non-goal 16, one write across two events, to Store 1; Operation 7, 8 and 12 and External check 2, appends to one log serialized and never refused for contention or ordering, to Store 2; State 7, Durability 1 through 4 and External check 1, the log and its next sequence number kept across a restart, to Store 3; rules 105 to 95. *Over:* the atom restating, for its own store, what every deployment's store guarantees. *Because:* the maintainer ruled 2026-10-12 that the corpus takes a store's specification, never the store, and `execution-contract.md` writes it once as the Store contract. The log's order stays the atom's own, carried by the sequence number (State 1, Invariant 3, Invariant 7.2) — two appends one action makes share one commit — so the atom cites no Order 1; what the atom does for its domain is unchanged.

- **2026-10-20 — A refused append leaves the counter, a query never reads the payload, and wall time promises no order.** *Chose:* next sequence number raised only by an append that answers event id (State 6), so a refused append consumes no sequence number and the gap rules go to Execution Contract Store 1 (Sequence gap 1 through 4, Check 2.4, Invariant 5.3, Check 3.5); a query of sequence number and wall-time ranges alone (Term query), so a selection on the payload is malformed (Operation 15); recording instant an annotation that can fall in append order, its promise under a non-decreasing clock withdrawn to the sequence number's authority (Invariant 7.1 to Invariant 7.2, Check 5.1 to Check 5.2, External check 3 to Execution Contract Logic confinement 7). *Over:* a gap the store's one transaction per action rules out; a payload predicate the atom may not evaluate (Non-goal 11); a clock guarantee the store does not give, since two appends it serializes can land in the order opposite to their clock readings (Execution Contract Store 2, Logic confinement 3). *Because:* Final Critique 5 found each a divergence between conforming builds or a conforming run breaking a stated rule, and in each the page already held the answer — the store it cites, its own non-goals, and the sequence number it makes authoritative.

- **2026-10-22 — A refused append writes nothing because the Execution Contract says so, and the page points there.** *Chose:* the case table's over-cap row citing Execution Contract Read 4 beside Operation 5, so the row a reader leans on for why an over-cap append writes nothing names the rule that says it, as the storage-failure row cites Database 1; Term terms naming now beside the page's other declared terms; the seven open lines kept as they stand, each flagged beside its rule; the rule count stays at 83. *Over:* Operation 1 conditioned on the payload cap, a caller rule reading invalid-payload as the event not landing, and Operation 4 conditioned on the event landing, each restating Read 4 on the page. *Because:* Final Critique 8's readers reported the admitted effect twice more, on Operation 1 and Operation 4, the third round running after Read 4 landed; Read 4 holds a rule saying what an action does only for a call the action admits, and this page's entry on the admitted call chose it over a condition of its own. What each action does and answers is unchanged.

- **2026-10-22 — An append writes the event, and its sequence number places it.** *Chose:* Operation 1 obliges [Append] to write the event into the log and names no place for it, since the event carries next sequence number (Operation 3), which stands above every sequence number landed earlier (Invariant 4.1) and is authoritative for the log's order (Invariant 7.2); the case table and the [Append] entry follow it, and open line 2026-10-20-f is closed; the rule count stays at 83. *Over:* a place named *the tail*, the grammar's own word for the part a statement may end with, which names no place in a log (GRACE-lang Term tail, Closed vocabulary 4). *Because:* Final Critique 7's three readers each reported the undeclared tail, two of them as foundational, and the page already placed every event by its sequence number. A smaller fix rode with it, changing no rule: the Generation acceptance introduction no longer calls the atom the corpus's Start Here. What each action does and answers is unchanged.

- **2026-10-22 — A re-read check reads only the reads that can answer the event.** *Chose:* Check 1.1 held to a later read whose query the event matches, so a later read asking another query is no evidence that the log removed an event; the [Query] entry asking for nothing beyond the ranges Term query names; open lines 2026-10-22-a (an append whose answer is lost) and 2026-10-22-b (the event id's source among the Capability requirements), and every open line flagged beside its rule; the rule count stays at 83. *Over:* a check every conforming log fails once an auditor's later read asks another query, which the check's *a later read*, read as the page's checks read *a*, allowed. *Because:* Final Critique 6 found it, and the page already held the answer: a read answers every landed event its query matches (Invariant 5.1), so an event the log kept is in every later read whose query it matches, and Check 3.2 already bounds its two reads to one query. Smaller fixes rode with it, none changing what a rule means: the Summary glosses a replay system; the case table's storage-failure row and the Rejection paths cite Execution Contract Database 1 for the counter a failed append leaves, which State 6 has not said since the repeats sweep. What each action does and answers is unchanged.

- **2026-10-22 — An admitted call is the Execution Contract's.** *Chose:* State 6 written again as the page first had it, *[Append] MUST raise next sequence number by one*, its condition on the append answering an event id, which this page's fifth Final Critique wrote, retired, since Execution Contract Read 4 holds a rule saying what an action does to the calls the action admits, so a refused or failed append raises nothing; Read 4 cited on Capability requirement 2; the rule count stays at 83. *Over:* the page stating for itself that a refused append leaves the counter. *Because:* the maintainer ruled on 2026-10-22 that five repeated cures are each stated once, the admitted effect among them; this page's fifth Final Critique had made the cure first, one specification at a time. What each action does and answers is unchanged.

- **2026-10-23 — Grounded on Final Critique 11.** *Chose:* the page grounded on one sample, its foundational count zero on the settle's triage and again on the blind second triage, of fifteen foundational reports (eleven sent down, ten of them onto the page's five flagged open lines; four rejected); the Summary brought to six sentences, the length the atom shape asks of it, and saying that the log itself never changes or removes what is written to it, where it had said that anything written stays for as long as the log exists, which a purge or an erasure another specification owns can end (Execution Contract Database 4 and Database 6); Term seam glossing *I/O*, and the Standards references spelling out NIST's *SP* and GDPR's *EU*; open line 2026-10-23-a holding the seven declared terms that carry no term entry; the rule count stays at 83. *Over:* another round on a text two triages found no foundational defect in. *Because:* the section titled *What "grounded" means* in `pressure-testing.md` grounds a page whose final round counts zero foundational findings, with the formal-layer vote cast and its model verifying and every open line refining, and a page grounded on one clean round owes its second round as its first scheduled rescan (*A clean round is a sample*). Open line 2026-10-20-e still holds the Regulated adversarial scenarios that the section titled *When the conventions apply* in `pressure-testing.md` asks of a page whose Examples walk regulated domains. What each action does and answers is unchanged.

- **2026-10-23 — What a caller does when an append's answer is lost is the composing pattern's.** *Chose:* Indeterminate outcome 1, the first family under Edge cases, giving a composing pattern what a caller does when an append's answer never reaches the caller, and open line 2026-10-22-a closed; Capability requirement 1 supplying now PER Execution Contract Logic confinement 3, the rule the clock reading meets, as the atom shape in `spec-format.md` asks of each thing a deployment supplies; the rule count 82 to 83. *Over:* an arm no rule gave an owner, on which one deployment re-appended on silence and recorded one state change twice while another never re-appended and, where the call had not landed, recorded nothing, each obeying every rule; and a course chosen for the composing pattern, a retry or none, which only it can choose. *Because:* Final Critique 10's blind second triage placed the lost answer foundational, where the settle's own triage, as four before it, had sent it down onto its open line; settled against the text, it holds, since the page's own flag said the arm had no stated course and that nothing named who suppresses a retried append. The atom answers a retried append as a second call (Execution Contract Read 4) and tells no event by its data (Identity 9), so a composing pattern that needs one event for each state change carries what tells two apart in the data it owns (Composition note 3). The cure is counted on GRACE-lang's Watch list as *the lost answer*, with the seven specifications that state the same arm for themselves. What each action does and answers is unchanged.

- **2026-10-23 — A query carries a range, and a sequence number range's ends are integers.** *Chose:* Term query's malformed shapes taking in a query carrying no range and a sequence number range carrying an end that is not an integer, beside a range's lower end above its upper end, an end below one and anything beyond the ranges, so that [Read] answers invalid-query to each (Operation 15); the [Query] and [Invalid Query] entries following it, the second now naming a selection on the payload as one query asking beyond the ranges; the rule count stays at 82. *Over:* a query with no range, which no rule gave a meaning, so that one build answered it with every event, another with none and a third refused it; and an end such as 2.5, which one build compared and another refused. *Because:* Final Critique 9 found it in the text Final Critique 8's blind second triage wrote when it took the query's shape from the implementation. Term query already said a query is a sequence number range, a wall-time range or the two, so a query carrying neither was never one, and a read of the whole log is a sequence number range from one. What each action does and answers is unchanged but for those two inputs.

- **2026-10-23 — A query means one thing in every build, and a failed read answers as the Execution Contract says.** *Chose:* the query's meaning stated in Term query — a range holds both its ends, a combination matches an event each of its ranges matches, and a query is malformed where a range's lower end is above its upper end, where an end of a sequence number range is below one, or where it asks for anything beyond those ranges (Operation 15) — with Operation 18, which gave the query's shape to the implementation, deleted to Term query, the [Query] and [Invalid Query] entries following it, and open line 2026-10-20-b closed; the database supplied under Execution Contract Read 1 through 4 (Capability requirement 2), so a read of the database that fails answers state-unavailable on either action (Read 1), and the Rejection paths' storage-failure now a write the database refuses, which is what Operation 9 answers; rules 83 to 82. *Over:* a shape each build chose while the Examples, which compile into the test suite, pinned one shape's verdicts (a range of one to one answering its event, a negative end answering invalid-query), so a build obeying Operation 15 through 18 failed the page's own tests; and a walkthrough answering storage-failure for a database that cannot be reached, beside a capability requirement citing Read 4 alone, which let a build answer storage-failure where Read 1 answers state-unavailable. *Because:* Final Critique 8's blind second triage, run on 2026-10-23 by one cold reader given the round's reports, the method's test and the placement rule, placed both foundational where the settle's own triage had sent the first down onto its open line and rejected the second; settled against the text, each holds. The verdicts the Examples already showed became the rule, so no Example changes its answer. Whether a signature block that leaves state-unavailable out still lets Read 1 land it (GRACE-lang Closed vocabulary 21, 22 and 29) is the corpus's question, escalated on 2026-10-23.

- **2026-11-28 — The log keeps one order per stream, not one per instance.** *Chose:* every event carries a stream (Term stream, the Stream entry, State 2, Term event field), an opaque sequence of bytes, never empty, which the app supplies at the seam on [Append] and on [Read] (Term seam, Term supplied stream), one for each need the offer serves, the need's own unless the need names a stream (Bonds journal 8), and which no business caller supplies (Operation 26); the atom compares streams byte for byte (Identity 11) and sets no cap on them; the log holds each stream's events in one total order (State 1) and orders none across streams (Non-goal 17); the next sequence number is one for each stream, begins at one (State 4, State 5) and rises only on an append to its stream (State 6, State 10, Operation 3), so the sequence number rises per stream (Invariant 3.1, 3.2, 4.1 and 7.2 read within one stream, Check 2.1, 2.3 and 4.2 with them); [Append] carries the supplied stream into the event (Operation 24); a [Read] answers from the supplied stream alone (Invariant 5.1, Invariant 5.4, Check 1.1, 3.2, 3.6); a supplied stream that is missing, empty or no sequence of bytes is answered invalid-stream, listed first on both refuses lines (Operation 25, Operation 27, Check 3.7, the Invalid Stream entry); the event id stays one per instance, whatever the stream (Invariant 6.1); the offer's arms carry invalid-stream and its order reads `sequence number per stream`; the two signatures are unchanged, the stream reaching each call at the seam as the clock reading and the event id do. *Over:* one sequence per instance, under which one Event Log serving two journal needs, as the to-do app's three do, keeps their records in one order and so cannot keep journal 8, while Bond 9 forbids a second instance; and the stream as an input the call carries, which would leave every composing pattern's append, which carries its data alone, malformed. *Because:* the unit `atom: Event Log keeps a stream per need (Bonds journal 8)`, decided 2026-11-28 by the mayor at the settle of Shared Todo as an app Final Critique 4 (slot e, 6ba66cf6), under Bonds journal 8, which the bond kind journal states and no ask of Scott reopens (rounds/page-findings.md row 91). The models hold one sequence per instance, and their redraw is deferred to Lean on the Ledger's formal line.

## Migration notes

- **2026-09-15 — Capability requirement 1, moved from Operation.** What the deployment supplies, which is what the family means. The rule stood under `Operation` — one action's rules — while naming no action, because this spec was migrated before the standard family had a home in an atom; the five atoms migrated a day later put the same obligation here. The words are the words the rule carried (council read 76).

## Deleted rules

The spec's tombstones, moved here from the page on 2026-11-13 because the spec is done (GRACE-lang Hard invariant 25 and Hard invariant 27, since v0.71): each `Deleted:` line byte for byte and in the page's order, under the heading it stood under there. A tombstone carries no obligation, and each still reserves its label: no rule of [Event Log](./event-log.idd) may carry it again.

### Structure › Identity

```
Deleted: Identity 3. Execution Contract Logic confinement 3 owns it.
Deleted: Identity 4. Execution Contract Logic confinement 14 owns it.
```

### Structure › State

```
Deleted: State 7. Execution Contract Database 3 owns it.
```

### Structure › Operations

```
Deleted: Operation 7. Execution Contract Database 2 owns it.
Deleted: Operation 8. Execution Contract Database 2 owns it.
Deleted: Operation 12. Execution Contract Database 2 owns it.
Deleted: Operation 13. Invariant 5.1 owns it.
Deleted: Operation 14. Invariant 5.2 owns it.
Deleted: Operation 18. Term query and Execution Contract Query 1 through 4 own it: what a query holds and when it is malformed is one thing in every build.
Deleted: Operation 19. Capability requirement 1 owns it.
Deleted: Operation 20. Execution Contract Logic confinement 3 owns it.
```

### Structure › Invariants › Invariant 5 — Read consistency

```
  Deleted: Invariant 5.3. Execution Contract Database 1 owns it: a refused append writes nothing, so no sequence number is consumed.
```

### Structure › Invariants › Invariant 7 — Wall-time best-effort monotonicity

```
  Deleted: Invariant 7.1. Invariant 7.2 owns it: two appends the database serializes can land in the order opposite to their clock readings, so recording instant can fall along append order under a non-decreasing clock.
```

### Generation acceptance › Conformance checks

```
Deleted: Check 2.4. Execution Contract Database 1 owns it: a refused append writes nothing, so the sequence numbers carry no gap.
Deleted: Check 3.5. Execution Contract Database 1 owns it: a refused append writes nothing, so no sequence number is consumed.
Deleted: Check 5.1. Check 5.2 owns it: a falling recording instant is no clock finding either, since two appends the database serializes can land in the order opposite to their clock readings.
```

### Generation acceptance › External checks

```
Deleted: External check 1. Execution Contract Database 3 owns it.
Deleted: External check 2. Execution Contract Database 2 owns it.
Deleted: External check 3. Execution Contract Logic confinement 7 owns it: the page relies on no guarantee of the clock.
```

### Non-goals

```
Deleted: Non-goal 16. Execution Contract Database 1 owns it.
```

### Edge cases › Indeterminate outcome

```
Deleted: Indeterminate outcome 1. Execution Contract Error model 1 owns it.
```

### Edge cases › Durability across crashes

```
Deleted: Durability 1. Execution Contract Database 3 owns it.
Deleted: Durability 2. Execution Contract Database 3 owns it.
Deleted: Durability 3. Execution Contract Database 3 owns it.
Deleted: Durability 4. Execution Contract Database 3 owns it.
```

### Edge cases › Sequence-number gaps on storage failure

```
Deleted: Sequence gap 1. Execution Contract Database 1 owns it: a refused append writes nothing, so no sequence number is consumed.
Deleted: Sequence gap 2. Execution Contract Database 1 owns it: a refused append writes nothing, so no sequence number is consumed.
Deleted: Sequence gap 3. Execution Contract Database 1 owns it: a refused append writes nothing, so the sequence numbers carry no gap.
Deleted: Sequence gap 4. Execution Contract Database 1 owns it: a refused append writes nothing, so no sequence number is consumed.
```
