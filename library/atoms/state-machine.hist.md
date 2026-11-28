---
title: State Machine — history
nav_exclude: true
search_exclude: true
---

# State Machine — history

The dated record of how [State Machine](./state-machine.idd) got here, moved out of the spec on 2026-10-20 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- atoms/state-machine.md`.

## Decisions

Entries that record a migration or a repair rather than a turn the pattern took.

- **2026-09-12 — Rewritten in GRACE lang v0.40; nothing but language changed.** *Chose:* the five actions as a signature block, Invariant 1 through 10 keeping their numbers, the declaration's ten well-formedness checks raised to a `Declaration 1 through 17` family of their own, every success effect conditioned on a declared admitted instantiate, admitted fire or admitted history (Hard invariant 16), [Fire]'s seven-step rejection precedence kept beside the rules as an eight-row case space with the ordering carried by `ONLY IF` guards rather than by a prose *rejection priority* line repeated in two sections, the six acceptance areas opened into `Check 1.1 through 8.2` with three `External check`s for what the store cannot answer, the Non-goals-and-edge-cases prose split into a `Non-goal 1 through 21` family and four edge-case families (`String`, `Clock semantics`, `Concurrency`, `Atomic writes`), the Composition notes prose raised to `Composition note 1 through 10`. *Over:* the prose spec. *Because:* the migration plan; `cites.py --into state-machine` found nothing in the corpus citing this atom by label. 78.8 KB → 67.0 KB.

- **2026-09-12 — The within-workflow temporal bound is a precedence, not a `≥`.** *Chose:* `Operation 20` — *IF the resolved firing instant precedes the workflow's instantiation instant THEN [Fire] MUST answer invalid-request*. *Over:* `IF fired_at EXCEEDS instantiated_at OR fired_at = instantiated_at`, the two-arm spelling the condition operator set forces on a `≥`. *Because:* that spelling is a watched class at five sites across two specs (council read 29), and this atom would have been the third. A bound that admits its own boundary is a *precedes* prohibition in one arm — the boundary case (a transition firing at the instant of instantiation) is legal, and one arm says so. The class may still earn an operator; it does not need this atom's vote.

- **2026-09-12 — Four propositions had two owners each.** *Chose:* `Invariant 2` owns exactly-one-current-state and the `State` family no longer restates it; `Operation 21` owns *one entry per admitted fire* and `Invariant 5` no longer does; `State 4` owns the history entry's field set and `Invariant 9` no longer does; `Invariant 8.2` owns *the atom does not evaluate a guard* and the `Non-goal` family no longer does. *Over:* keeping each pair for emphasis. *Because:* Authority 3. All four were found by `W-duplicate-proposition`, which is the check earning its keep on the largest atom migrated so far — 192 rules, where a reader cannot hold the whole surface at once and a duplicate is invisible by construction.

- **2026-10-20 — The store's guarantees cited, not restated.** *Chose:* the workflow store supplied under Execution Contract Store 1 through 4 (Capability requirement 5), and the ten rules that restated them, or existed only for a store that could split a fire, tombstoned to their owner — Operation 27, a fire's entry, counter raise and state change committed in one operation, Invariant 10.3, no partial record left by a storage-failure rejection, and Atomic writes 1, 2, 4 and 5, no reader observing a history entry without its next sequence number raise or its current state change, a dangling transition resolved and no read served before it is, to Store 1, under which no fire stands partly applied; Atomic writes 3, an uncommitted crash leaving the workflow as the call found it, to Store 1 and Store 3; State 14, next sequence number surviving a restart, to Store 3; Concurrency 1 and 2, two fires on one workflow serialized and the later reading the current state the earlier left, to Store 2; rules 186 to 177. *Over:* the atom restating, for its own store, what every deployment's store guarantees, and keeping a crash-recovery obligation for a split fire that no conforming store leaves. *Because:* the maintainer ruled 2026-10-12 that the corpus takes a store's specification, never the store, and `execution-contract.md` writes it once as the Store contract. What stays is the atom's own: a refused action leaving the workflow as the call found it, appending no history entry and raising no next sequence number (Operation 35 through 37), and the rules that keep a workflow and its history once they exist (State 6, State 7, State 12, State 13, Invariant 10.1, Invariant 10.2), since Store 4 alone neither keeps the atom from removing a workflow or a history entry nor bars a purge another specification declares. The history's order is the atom's own sequence number, taken inside the fire that appends the entry (Operation 22, Invariant 6.3), and the atom's checks compare an auditor's own reads or replay the entries, so the atom cites neither History 1 nor Order 1. What the atom does for its domain is unchanged.

- **2026-10-21 — Which refusal answers is the Execution Contract's.** *Chose:* each refuses line kept as the page wrote it, already in the order its pairs gave — [Instantiate] invalid-declaration ahead of invalid-request; [Fire] invalid-request on a blank instance id or action, then not-known, terminal, invalid-transition and guard-not-satisfied, the table's rows 1 through 5; [History] not-known ahead of invalid-query; storage-failure last, answering only at the write — and the order cited from the Execution Contract (Capability requirement 5, Execution Contract Refusal 1); the pairs that only stated it deleted to Refusal 1: Operation 1 (invalid-request only on a well-formed declaration), Operation 12 (not-known only for an instance id that is not blank), Operation 14 (terminal only for an instance id naming a workflow), Operation 16 (invalid-transition only off a terminal state), Operation 18 (guard-not-satisfied only where a declared transition matches), Operation 34 (storage-failure behind every precondition) and Operation 46 (invalid-query only for an instance id naming a workflow); rules 177 to 170. The table's row 6, an actor or instant fault answered only once the gate clears, stood in no rule and no fixed line can hold invalid-request in both rows, so it is routed as open line 2026-10-21-a. *Over:* the page stating for itself which of an action's refusals answers when several apply. *Because:* the maintainer ruled on 2026-10-21 that the Execution Contract states once that the refusal listed first on an action's refuses line answers.

- **2026-10-22 — A guarded fire lands only on a true assertion, an admitted call is one whose writes commit, and a composed retention may purge what the atom never removes.** *Chose:* Operation 17 refusing a guarded fire whose guard satisfied is not true, with Term guard satisfied declaring true | false and Invariant 8.1 reading the same; the admitted instantiate and admitted fire written as a call that passes every precondition and whose database writes commit; [Instantiate] taking the optional subject reference State 2 and Term string input name, which Operation 56 records; and State 12 and State 13 deleted to Invariant 10.1, Invariant 10.2 and Execution Contract Database 4, the page read as Final Critique 4's text read it: the atom keeps every workflow and history entry, and time-bounded retention is a composing Retention Window's. *Over:* Operation 17 refusing only an absent assertion beside the term entries' true; admitted terms that stopped at the guards and took in a call the database refused; a subject reference no action took; and the 2026-10-20 entry's reading that State 6, State 7, State 12, State 13, Invariant 10.1 and Invariant 10.2 bar a purge another specification declares. *Because:* Final Critique 5 found the four, and the corpus already reads so: Medication Order, Credential, Provisional Commitment, Party Identity, Invitation and Provenance write their admitted calls in that form, and Selective Disclosure, Party Identity, Provisional Commitment, Observation, Capacity Constraint Enforcement and Message Preference cured the composed erasure the same way. Smaller fixes rode with them: State 1 carries the instantiation instant Operation 20 reads, and State 15 and State 16 the instantiating actor reference and guard satisfied; Declaration 18 refuses a terminal state outside states; External check 4 asks the deployment for the patterns it wired in (Composition note 1); Check 5.3 cites Invariant 5.1; the Workflow Id entry no longer names a consumer the page lacks; [History]'s query is routed as open line 2026-10-22-a; rules 170 to 173. What each action answers and writes on a call it admits is unchanged, but that a guarded fire asserting false is refused and the subject reference is taken and recorded.

- **2026-10-22 — An admitted call, a composed purge and the wiring are the Execution Contract's.** *Chose:* the admitted instantiate and the admitted fire citing Execution Contract Read 4 for what an action admits, in place of the commit clause this page's fifth Final Critique wrote into each, so Operation 38, Operation 47 and Invariant 1.2, which name [Current] and [Read Declaration], hold under Read 4 for the calls those actions admit, as every other effect rule does; Invariant 10.1 and Invariant 10.2 read by Execution Contract Database 6, so the atom removes no workflow and no history entry and a purge a composing Retention Window declares is answered by that pattern's records; External check 4, the auditor reading which composing patterns a deployment wired in from the deployment's own declaration, deleted to Execution Contract Conformance 9, and the checks NOTE's sentence restating it removed; the three labels cited on Capability requirement 5; rules 173 to 172. *Over:* the page stating for itself which calls its effect rules reach, that its no-removal rules bind the atom alone, and that the wiring is an external check. *Because:* the maintainer ruled on 2026-10-22 that five repeated cures are each stated once, the admitted effect, the composed erasure and the wiring declaration among them; this page's fifth Final Critique had made all three one specification at a time. What each action does and answers is unchanged.

- **2026-11-02 — The string cap has a default.** *Chose:* the string cap stated as 1,024 Unicode code points where a deployment declares none, Capability requirement 7 added, citing Execution Contract Input 2. *Over:* a bound the deployment must supply, or silence. *Because:* the maintainer ruled on 2026-11-01 that what the host must bound takes one posture, a corpus default a deployment may override; the string inputs are a workflow's subject and actor references and an action name, and 1,024 code points, the corpus's default for text (Personal Todo's description cap), leaves room for any of them; the opaque instance metadata is no string input and stays outside the cap, as the page left it.

- **2026-11-26 — The atom converted into the tree order and bonded: it mints and offers the workflow id, its actor reference is the actor id, and no pattern is named.** *Chose:* the bonding converter's draft (grace-council assets/bond.py), judged line by line: the tree order Task, List and Ordering stand in, every label kept and none renumbered (167 before and after); the instance id renamed the workflow id, the word Bonds Key 17 gives a workflow's minted id, in every rule, term and signature (`workflow_id`), declared in declarations.md, and offered as `key workflow id; carried by workflows`; the actor reference is the actor id, met by the need `key actor id; pairs actor references`; Non-goal 2, 12, 14, 16 and 18 tombstoned to the Non-goal that owns the declined job, and External check 3, the owners NOTE, the Source lines, the WHY and the examples name no pattern; the WHY cut to the two points a reader would otherwise miss (the declaration is data, the guard is asserted and never evaluated); the invariants the draft placed twice kept once, under their own heading; Clock semantics under *While something is so*, and the empty Atomic writes and Concurrency headings dropped, as the old page held nothing under them. *Over:* keeping `instance_id` as the signatures' name, which would leave Operation 9, 11 and 75 bound to no action in the IR; offering the transition id as a second key, which Bonds Key 10 may ask, left for the design review. *Because:* Scott's ruling of 2026-11-25 8:07 PM Central ("NEXT"), the unit `atom: State Machine, converted`, batch 1, 1 of 5.

- **2026-11-17 — A workflow is found by its subject reference.** *Chose:* one read of the atom's own records, [Workflows About], answering the instance id of every workflow carrying a subject reference, a finished one among them, earliest instantiation first and two sharing one in the order they were recorded *Over:* a Customer Relationship composition that keeps its own list of workflows per customer, or a read answering whole workflow records *Because:* the maintainer ruled on 2026-11-16 that atoms are allowed small look-ups of their own, and nothing else could list a customer's workflows: the atom records the subject reference on each workflow and no action answered by it (open line 2026-10-31-a), while Identity 14 already admits several workflows carrying one subject reference; Assignment's History For is the form it mirrors.

- **2026-11-20 — A malformed subject reference is refused, not answered with an empty list.** *Chose:* [Workflows About] answering invalid-request to a subject reference that is blank, over the string cap or not a string (Operation 85, and Operation 86 where the read of the workflow records fails too), the refuses line and the term entry listing the refusal, the answer table's row 1 and the example following. *Over:* the empty list for a malformed subject reference, which a caller could not tell from a subject no workflow carries (Operation 84). *Because:* Operation 9 and Operation 75 already answer invalid-request to the same defects in an instance id, and Scott decided it on 2026-11-19 (rounds/open-line-choices-directions-2.md, item 101: "a malformed subject reference answers invalid-request, as Operation 9 and 75 do; the signature lists the refusal").

- **2026-11-28 — The transition history is a journal need.** *Chose:* the atom needs a journal (`Term need journal: records workflow events; calls append; arms event_id`, the word declared in declarations.md), met by Event Log's journal offer with nothing written (Bonds Bond 8); every admitted [Instantiate] and [Fire] appends one workflow events record through it (Operation 94), an instantiation's record carrying the workflow id, the initial state, the instantiation instant and the actor reference (Operation 95), and a fire record carrying what a history entry carried, named by its fields: the workflow id and action (Operation 96), the from state and to state (Operation 24, Operation 25), the guard satisfied (Operation 29, Operation 30), the actor reference (Operation 61) and the firing instant (Operation 68); Storage Failure and the two case tables name the journal's refusal (Execution Contract Constituent failure 1); the transition history, the history entry, its id and sequence number, Next Sequence Number, the [History] action with its refusal invalid-query and its case table, the offer `key history entry id` (which no atom consumed; its declaration leaves declarations.md) and the rules that only served them tombstoned to the journal need, 39 labels: Identity 2, 4, 8 and 10, State 4, 5, 7, 8, 9 and 16, Operation 6, 7, 21 through 23, 36, 37, 39, 42, 43, 45, 55, 57, 58, 73 and 87 through 89, Invariant 5.1, 5.2, 6.1 through 6.3 and 10.2, Check 5.1 through 5.3 and 8.1, and External check 2; Non-goal 23 in Medication Order Non-goal 19's words; Invariant 3.1, 7.1 through 7.3 and 8.3 and Check 2.1, 4.1, 6.1, 7.1, 7.2 and 8.3 re-cited to the fire records an auditor reads in the app's journal, in journal order; Clock semantics 4 kept, over a later fire; the Example's audit question and the Source's 21 CFR Part 11, ISO 9001 and HIPAA lines say the history is the journal's. *Over:* keeping the atom's own history beside the journal Event Log already keeps, and a read no other atom used. *Because:* the unit `atom: State Machine, the transition history is a journal need`, ruled by Scott; the library's standing line is Medication Order Non-goal 19 (efaa2bcb), and Capacity Constraint Enforcement's audit log took the same cure (6d80e43b).

## Migration notes

- **2026-09-15 — Capability requirement 1, moved from Operation.** What the deployment supplies, which is what the family means. The rule stood under `Operation` — one action's rules — while naming no action, because this spec was migrated before the standard family had a home in an atom; the five atoms migrated a day later put the same obligation here. The words are the words the rule carried (council read 76).

- **2026-11-26 — Batch-1 review cures: an absent actor reference refuses nothing, the History refusals are owned, the open read is answered, and the history entry id is offered.** *Chose:* from G's review as Scott relayed it (2026-11-25 10:35 PM Central) and his rulings of that evening. B1: Operation 2 refuses a blank actor reference only where the call carries one, so an absent one is absent and records nothing (Operations 60, 61), as State 5 and 15 and the Example's actor-less instantiate already read; the TLA+ model encoded that reading (`SuppliedBlank`), and the page was the outlier. B2: false at HEAD: every skipped label of every family already has its tombstone in this file's *Deleted rules* section, where cites.py reads them. B3: Operation 57 owns the History refusals and cites its cases, and Operation 87 through 89 state the three the member named and no rule did (a blank string filter value, one over the string cap, a range missing an end); a blank filter value is malformed (String 5). Should-fix: a precedence clause on Operation 2 and 77 (on [Fire], a cleared fire only); case tables for [Instantiate] and [History] and a read-failure row for [Fire]; the four rejection sets declared in Term value sets; Check 10.1 for Invariant 10; Identity 3 and 4 and Operations 72 and 73 say the host supplies at the seam the id the atom mints; Term admitted history cites its Operations; open item 2026-10-31-a closed by a read, [Read Workflow] (Operation 90 through 92), the data being held and Identity 13 standing; the assertion asymmetry's reason in one clause. The id: the transition id is renamed the history entry id in every rule, term, filter axis and signature, declared, and offered beside the workflow id (Scott, 9:45 PM, "yes"), each offer naming its existence read under calls (Bonds Key 26): [Read Workflow] and [History]. Nits: Term actors lists actors only; each member cites its owners; instance metadata is exempt from the string cap; the Part 11 source line reads 11.10(e) for the audit trail and 11.50 and 11.70 for signatures; the FHIR Task status codes in R4; Term qualifiers names v0.75. *Over:* a new model for the new read and refusals, which `formal: pause new modelling` defers to Lean (the Ledger's formal line). *Because:* Scott's batch-1 review, the unit `atom: State Machine, review cures`.

## Deleted rules

The spec's tombstones, moved here from the page on 2026-11-13 because the spec is done (GRACE-lang Hard invariant 25 and Hard invariant 27, since v0.71): each `Deleted:` line byte for byte and in the page's order, under the heading it stood under there. A tombstone carries no obligation, and each still reserves its label: no rule of [State Machine](./state-machine.idd) may carry it again.

### Structure › Identity model

```
Deleted: Identity 5. Execution Contract Logic confinement 3 owns it.
Deleted: Identity 6. Execution Contract Logic confinement 3 owns it.
Deleted: Identity 11. Execution Contract Logic confinement 10 owns it.
Deleted: Identity 12. Execution Contract Database 7 owns it.
Deleted: Identity 17. Execution Contract Input 2 owns it.
Deleted: Identity 18. Execution Contract Input 2 owns it.
```

### Structure › State

```
Deleted: State 12. Invariant 10.1 and Execution Contract Database 4 own it.
Deleted: State 13. Invariant 10.2 and Execution Contract Database 4 own it.
Deleted: State 14. Execution Contract Database 3 owns it.
```

### Structure › Capability requirement

```
Deleted: Capability requirement 6. Execution Contract Conformance 9 owns it.
Deleted: Capability requirement 2. Execution Contract Logic confinement 7 owns it.
Deleted: Capability requirement 3. Execution Contract Logic confinement 7 owns it.
Deleted: Capability requirement 4. Execution Contract Logic confinement 7 owns it.
Deleted: Capability requirement 8. Execution Contract Input 2 owns it.
```

### Structure › Operations

```
Deleted: Operation 1. Execution Contract Refusal 1 owns it.
Deleted: Operation 62. Execution Contract Input 1 owns it.
Deleted: Operation 65. Execution Contract Input 3 owns it.
Deleted: Operation 74. Execution Contract Input 4 owns it.
Deleted: Operation 12. Execution Contract Refusal 1 owns it.
Deleted: Operation 14. Execution Contract Refusal 1 owns it.
Deleted: Operation 16. Execution Contract Refusal 1 owns it.
Deleted: Operation 18. Execution Contract Refusal 1 owns it.
Deleted: Operation 63. Execution Contract Input 1 owns it, among the firing checks (Term firing check).
Deleted: Operation 27. Execution Contract Database 1 owns it.
Deleted: Operation 32. Operation 15 and Declaration 10 own it.
Deleted: Operation 34. Execution Contract Refusal 1 owns it.
Deleted: Operation 40. Execution Contract Read 6 owns it.
Deleted: Operation 41. Execution Contract Query 3 through 4 own it.
Deleted: Operation 44. Execution Contract Query 5 owns it.
Deleted: Operation 79. Execution Contract Query 5 owns it.
Deleted: Operation 46. Execution Contract Refusal 1 owns it.
Deleted: Operation 51. Capability requirement 1 owns it.
Deleted: Operation 52. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 53. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 54. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 81. Operation 80 owns it.
```

### Structure › Invariants › Invariant 10 — Record durability

```
  Deleted: Invariant 10.3. Execution Contract Database 1 owns it.
```

### Structure › The declaration

```
Deleted: Declaration 1. Declaration 5 and Declaration 8 own it.
```

### Generation acceptance › Conformance checks

```
Deleted: Check 1.2. Check 1.1 owns it.
```

### Generation acceptance › External checks

```
Deleted: External check 4. Execution Contract Conformance 9 owns it.
```

### Edge cases › Atomic writes

```
Deleted: Atomic writes 1. Execution Contract Database 1 owns it.
Deleted: Atomic writes 2. Execution Contract Database 1 owns it.
Deleted: Atomic writes 3. Execution Contract Database 1 and Execution Contract Database 3 own it.
Deleted: Atomic writes 4. Execution Contract Database 1 owns it.
Deleted: Atomic writes 5. Execution Contract Database 1 owns it.
```

### Edge cases › Clock semantics

```
Deleted: Clock semantics 1. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 2. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 3. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 5. Non-goal 22 owns it.
```

### Edge cases › Concurrency

```
Deleted: Concurrency 1. Execution Contract Database 2 owns it.
Deleted: Concurrency 2. Execution Contract Database 2 owns it.
```

### Edge cases › String policy

```
Deleted: String 7. Execution Contract Logic confinement 13 owns it.
```

### Composition notes

```
Deleted: Composition note 1. Execution Contract Conformance 9 owns it.
Deleted: Composition note 10. Execution Contract Atom interface 1 owns it.
```

### While something is so › String policy

```
Deleted: String 5. GRACE-lang Term blank owns it: a value carrying only white space is blank.
Deleted: String 6. GRACE-lang Term blank owns it: an absent value is blank.
```

### What it keeps › The workflows

```
Deleted: Identity 2. The journal need owns it: the journal names each workflow events record by the event id its append answers, and keeps it unchanged and unshared.
Deleted: Identity 4. The journal need owns it: the journal names each workflow events record by the event id its append answers, and keeps it unchanged and unshared.
Deleted: Identity 8. The journal need owns it: the journal names each workflow events record by the event id its append answers, and keeps it unchanged and unshared.
Deleted: Identity 10. The journal need owns it: the journal names each workflow events record by the event id its append answers, and keeps it unchanged and unshared.
Deleted: State 4. The journal need owns it: a fire record carries what a history entry carried (Operation 24, Operation 25, Operation 29, Operation 61, Operation 68, Operation 96).
Deleted: State 5. The journal need owns it: a fire record carries what a history entry carried (Operation 24, Operation 25, Operation 29, Operation 61, Operation 68, Operation 96).
Deleted: State 7. The journal need owns it: the workflow events stand in the journal, which keeps their order and removes and edits none, not on the workflow.
Deleted: State 8. The journal need owns it: the workflow events stand in the journal, which keeps their order and removes and edits none, not on the workflow.
Deleted: State 9. The journal need owns it: the workflow events stand in the journal, which keeps their order and removes and edits none, not on the workflow.
Deleted: State 16. The journal need owns it: a fire record carries what a history entry carried (Operation 24, Operation 25, Operation 29, Operation 61, Operation 68, Operation 96).
```

### What people do › Every action

```
Deleted: Operation 6. The journal need owns it: the atom keeps no sequence number, and the journal's append answers each record's place.
Deleted: Operation 7. The journal need owns it: the atom keeps no transition history, and an admitted instantiate appends one workflow events record (Operation 94).
Deleted: Operation 21. The journal need owns it: an admitted fire appends one fire record through it (Operation 94).
Deleted: Operation 22. The journal need owns it: the atom keeps no sequence number, and the journal's append answers each record's place.
Deleted: Operation 23. The journal need owns it: the atom keeps no sequence number, and the journal's append answers each record's place.
Deleted: Operation 73. The journal need owns it: the journal names each workflow events record by the event id its append answers, and the host mints no history entry id.
Deleted: Operation 36. The journal need owns it: a refused action commits nothing, so no journal holds it.
Deleted: Operation 37. The journal need owns it: the atom keeps no sequence number, and a refused action commits nothing (Execution Contract Read 4).
Deleted: Operation 39. The journal need owns it: an auditor or an app reads the workflow events from the journal by range, and the atom offers no read of them.
Deleted: Operation 42. The journal need owns it: an auditor or an app reads the workflow events from the journal by range, and the atom offers no read of them.
Deleted: Operation 55. The journal need owns it: the journal order is the order of the workflow events, and no rule of the atom orders by firing instant.
```

### What people do › History

```
Deleted: Operation 57. The journal need owns it: an auditor or an app reads the workflow events from the journal by range, and the atom offers no read of them.
Deleted: Operation 43. The journal need owns it: an auditor or an app reads the workflow events from the journal by range, and the atom offers no read of them.
Deleted: Operation 45. The journal need owns it: an auditor or an app reads the workflow events from the journal by range, and the atom offers no read of them.
Deleted: Operation 58. The journal need owns it: an auditor or an app reads the workflow events from the journal by range, and the atom offers no read of them.
Deleted: Operation 87. The journal need owns it: an auditor or an app reads the workflow events from the journal by range, and the atom offers no read of them.
Deleted: Operation 88. The journal need owns it: an auditor or an app reads the workflow events from the journal by range, and the atom offers no read of them.
Deleted: Operation 89. The journal need owns it: an auditor or an app reads the workflow events from the journal by range, and the atom offers no read of them.
```

### What is and what should never be (Invariants)

```
Deleted: Invariant 5.1. The journal need owns it: a workflow events record stands in the journal as appended, and the atom has no action over it.
Deleted: Invariant 5.2. The journal need owns it: an admitted fire appends one fire record (Operation 94), and the journal keeps every record its append answered a place for (Bonds journal 1).
Deleted: Invariant 6.1. The journal need owns it: the journal orders the workflow events by the place each append answers (Bonds journal 2), and the atom keeps no sequence number.
Deleted: Invariant 6.2. The journal need owns it: the journal orders the workflow events by the place each append answers (Bonds journal 2), and the atom keeps no sequence number.
Deleted: Invariant 6.3. The journal need owns it: the journal orders the workflow events by the place each append answers (Bonds journal 2), and the atom keeps no sequence number.
Deleted: Invariant 10.2. The journal need owns it: the journal keeps the workflow events, and removes none under this atom (Bonds journal 1).
```

### Proof › Generation acceptance › Conformance checks

```
Deleted: Check 5.1. The journal need owns it: the journal orders the workflow events by the place each append answers (Bonds journal 2), and the atom keeps no sequence number.
Deleted: Check 5.2. The journal need owns it: the journal orders the workflow events by the place each append answers (Bonds journal 2), and the atom keeps no sequence number.
Deleted: Check 5.3. The journal need owns it: a workflow events record stands in the journal as appended, and the atom has no action over it.
Deleted: Check 8.1. The journal need owns it: Operation 95 and Operation 96 name what each workflow events record carries.
```

### Proof › Generation acceptance › External checks

```
Deleted: External check 2. The journal need owns it: a deployment counts the fire records the app's journal holds, one for each admitted fire (Operation 94).
```
