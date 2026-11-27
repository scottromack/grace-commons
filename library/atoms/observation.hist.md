---
title: Observation — history
nav_exclude: true
search_exclude: true
---

# Observation — history

The dated record of how [Observation](./observation.md) got here, moved out of the spec on 2026-10-20 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log --follow -- atoms/observation.md`.

## Decisions

Entries that record a migration or a rename rather than a turn the pattern took, and the two turns that put the amend's two writes in one transaction under an observation's own critical section and forbade repairing a split amend, which the Store contract took over on 2026-10-20.

- **2026-08-30 — One writer per transition, and no repair leg.** *Chose:* transactional atomicity as the only conforming implementation of [Amend]'s two writes, the crash-recovery scan withdrawn; the per-id serialization stated as a critical section with its semantics — taken before the state check, released on return or death, a lease's expiry the invocation's terminus, a stalled invocation re-reading the state under the critical section and landing [Already Amended]; a deployment-declared clock offset allowance under which the future-dated check on a caller-supplied [Recording Instant] runs. *Over:* a scan "that detects and repairs dangling amendment links on restart" offered as an equal alternative to a transaction, beside a caller told to read the original and retry; a future-dated refusal decided by comparing the caller's stamp to the node's clock with no margin. *Because:* the scan presumed a visible partial record that Invariant 7 says never exists, could relink one dangling shape but not the other — the successor's content is nowhere in the store, and un-marking the original rewrites a write-once field — and made a second writer for an act the caller's retry could already have landed; and a caller's stamp and the node's reading are two clocks, so a refusal resting on their comparison needs the margin on the page (the frozen rules of 2026-08-30 — *A compensator is exclusive*, *A stamp from another seam never decides a write alone* — with *Recovery commits under a declared service identity … and what cannot be re-derived is re-run*, frozen 2026-08-29).

- **2026-09-13 — Rewritten in GRACE lang v0.40; nothing but language changed.** *Chose:* the four actions as a signature block, Invariant 1 through 9 keeping their numbers, every success effect conditioned on a declared admitted record, admitted amend, admitted retract or admitted read (Hard invariant 16), [Amend] and [Retract] unified under a declared chain action so their shared guards are stated once, the per-action *rejection priority* paragraph collapsed to one seven-row case space, the arithmetic in `recorded_at ≤ now + clock_offset_allowance` routed through a declared future bound so no rule carries a sum (Closed vocabulary 9), the five acceptance areas opened into `Check 1.1 through 6.1` with four `External check`s, the Non-goals-and-edge-cases prose split into a `Non-goal 1 through 22` family and four edge-case families. *Over:* the prose spec. *Because:* the migration plan; `cites.py --into clinical-observation` found nothing citing this atom by label. 61.2 KB → 60.7 KB, the smallest reduction of the migration — this atom's prose carried almost no restatement, and what came out was one repeated precedence paragraph.

- **2026-09-13 — The only atom that forbids repair-later.** *Chose:* `Invariant 7.3` and `Atomic writes 4` — no reader may observe a partial record once a crash has landed, and the implementation MUST NOT repair a dangling amend. *Over:* the crash-recovery scan every other store in the corpus is permitted. *Because:* the partial record is visible between the crash and the repair, which is the state Invariant 7.3 says never exists — and one of the two dangling shapes cannot be repaired at all, because an original marked amended with a successor id naming no record has lost the successor's value, unit, clinician and reason entirely, and un-marking it would rewrite a write-once field (`Invariant 9.1`).

- **2026-09-13 — Renamed from Clinical Observation; the domain was in the name, not the concept.** *Chose:* `Observation`, with `patient_ref` renamed subject reference and the clinician vocabulary neutralized wherever it was definitional. *Over:* holding the name, and over `Superseding Record` and `Amendment Chain`, which name the invariant more precisely and read less naturally. *Because:* `atoms/_TAXONOMY.md` had flagged this atom as the corpus's masquerade candidate since 2026-06-08 — a neutral concept dressed in domain clothes — and gated the judgment on the EOS strip test rather than on taste. The GRACE migration made the test decidable. Of 173 labelled rules, **not one carries a clinical semantic**: value, unit and observation type are opaque (Identity 14, Identity 15), the atom is forbidden to interpret a value (Non-goal 4) or confirm one correct (Non-goal 5), and what counts as valid is entirely the deployment's (Non-goal 1, Operation 5). Strip the setting and what remains is an amendable, attributed, retractable measurement record — equally a vital sign, an assay, an instrument reading, a financial mark. The two domain-flavoured identifiers were opaque references, and renaming one of them removed the last of it. `Medication Order` stays tagged `domain: healthcare` and earned it — its guards are irreducibly clinical and no census can count them away. The calibration the maintainer set is visible in what did *not* change: the worked example keeps its nurse and its blood pressure, and the Standards references keep their healthcare anchors, because those are illustration and evidence rather than framing. Neutral where the text is definitional, concrete where it is illustrative.

- **2026-09-13 — The value constraint is the deployment's, and the refusal is the atom's.** *Chose:* `Operation 5` — an observation type carrying no declared value constraint is refused — with `Non-goal 1` and `Non-goal 2` stating the division from both ends. *Over:* accepting an unknown type unchecked, which is what most record stores do. *Because:* what counts as a valid systolic pressure or pain score is clinical and local, so an atom that defined one would be specified against a single care setting, and an atom that accepted a type it could not check would have a per-type integrity guarantee in name only. A deployment adds a measurement by declaring what a valid value for it looks like first. This is the corpus's first bounds entry whose *value* is entirely the deployment's while its *existence* is normative.

- **2026-09-13 — Inheritance by construction, stated as the absence of a parameter.** *Chose:* `Operation 21`, `Operation 22` and `Operation 23` — [Amend] accepts no subject reference, no observation type and no recording instant — with `Invariant 4` and `Invariant 5` resting on them. *Over:* runtime checks that a successor matches its original. *Because:* a check catches divergence and a missing parameter makes it unrepresentable, and the second is the stronger guarantee. The consequence is the atom's most-questioned friction and it is deliberate: a clinician who charted the wrong measurement type is not correcting a value, they recorded something that did not happen, which retraction says and amendment does not.

- **2026-10-20 — The store's guarantees cited, not restated, the observation's critical section among them.** *Chose:* the observation store supplied under Execution Contract Store 1 through 4 (Capability requirement 6), and the fourteen rules that restated them, ran the atom's own critical section over an observation, or existed only for a store that could split an amend, tombstoned to their owner — Operation 33, an admitted amend's successor and the original's change committed in one operation, Invariant 7.2, no partial record left by a storage-failure rejection, Atomic writes 1 and 2, no reader observing either half of an amend without the other, and Atomic writes 4, no repair of a dangling amend, to Store 1, under which no amend stands half-written; Invariant 7.3, no partial record observed once a crash has landed, and Atomic writes 3, an uncommitted crash leaving the store as the call found it, to Store 1 and Store 3; Concurrency 1 through 4 and Concurrency 7, two chain actions on one observation serialized, the state precondition read and held inside the critical section across the check and the transition, a second serialized [Amend] answering already-amended, and no reconciliation leg, to Store 2, and with them the section's release on the invocation's return (Concurrency 5) and its lapse answered as storage-failure (Concurrency 6), since the atom names no section any more; rules 169 to 156. *Over:* the atom running its own critical section over an observation, released on return and lapsing to a storage failure, and forbidding a repair leg for a dangling amend and a reconciliation leg for a second writer that no conforming store leaves — the turns of 2026-08-30 and 2026-09-13, now in the history. *Because:* the maintainer ruled 2026-10-12 that the corpus takes a store's specification, never the store, and `execution-contract.md` writes it once as the Store contract: Store 2 reads the state a chain action's guards decide on inside the transaction that writes the action's effects, which is what the section was for, and Store 1 commits [Amend]'s successor and the original's change together or not at all, so no partial record is left to repair and no second writer to reconcile. A refused action leaving the store as the call found it stays the atom's own (Operation 41), as do the rules that keep an observation once it exists (State 5, State 12, Invariant 7.1, Check 4.1), since Store 4 alone neither keeps the atom from removing an observation nor bars a purge another specification declares, and the external check that holds Invariant 7.1 against the captured record answers (External check 1). Amendment chains are the atom's own records, linked by predecessor and successor ids, [Read] answers by recording instant, and the atom's checks compare an auditor's own reads, so it cites neither History 1 nor Order 1; what the atom does for its domain is unchanged.

- **2026-10-21 — Which refusal answers is the Execution Contract's.** *Chose:* each refuses line kept as the page wrote it, already in the page's order — a chain action answering not-known, its state rejections, then invalid-request once every state check passes, [Amend] invalid-observation after that, and storage-failure last, answering only at the write — and the order cited from the Execution Contract (Capability requirement 6, Execution Contract Refusal 1); the pairs that only stated it deleted to Refusal 1: Operation 15 (a state rejection only for an observation id naming an observation), Operation 19 (invalid-request only once every state check passes), Operation 20 (invalid-observation only once every request check passes) and Operation 40 (storage-failure behind every precondition), with Term state rejection, which only Operation 15 read; rules 156 to 152. *Over:* the page stating for itself which of an action's refusals answers when several apply. *Because:* the maintainer ruled on 2026-10-21 that the Execution Contract states once that the refusal listed first on an action's refuses line answers. What each action answers on every call is unchanged.

- **2026-10-22 — A composed retention may purge what the atom never removes; every field of a successor has a source; a refusal ban names its ground.** *Chose:* State 12 deleted to Invariant 7.1 and Execution Contract Database 4, and Check 4.1 to External check 5, which reads the composing Retention Window's purge records beside two unfiltered reads; Operation 56 and Operation 57, an admitted amend taking the successor's recording actor from the original and recording the call's value and unit on the successor; Operation 38 narrowed to the ground it meant, [Retract] refusing no call on the ground that the observation stands in amended; Non-goal 2 moved to Capability requirement 7, and Term seam naming the clock offset allowance and the value constraints the host injects; Operation 4 refusing a blank unit on [Amend] as on [Record], and Operation 48 a blank value on every filter. *Over:* the reading the 2026-10-20 entry recorded for the maintainer to overrule, under which State 12 and Check 4.1 also barred a purge another specification declares; a successor whose recording actor, value and unit no rule sourced; a ban that, read alone, kept [Retract] from every refusal on an amended observation; and the migration's narrowing of Final Critique 4's refusals to [Record]'s unit and a reference filter's value. *Because:* Final Critique 5 found each, and Final Critique 4's text decided the direction: the atom retains every observation indefinitely, and eventual destruction belongs to Retention Window and Legal Hold as composing patterns, as four Final Critiques read the same shape on their own pages; Medication Order carries the original's prescriber reference onto its successor beside the amending actor; Execution Contract Refusal 1 lets no refusal apply where a rule keeps the action from answering it, so a ban names its ground, as Retention Window, Permissions and Duplicate Prevention write theirs; and Final Critique 4 refused a blank unit on [Amend] and a blank observation id on [Read]. Smaller fixes rode with it, none changing what a rule means: Term content field, the Invalid Observation, Invalid Query, Recording Instant, Recording Actor, Unit and Amend entries, and the transcription example say what the rules say. What each action answers on a well-formed call is unchanged, and a successor now carries a stated recording actor, value and unit.

- **2026-10-22 — A composed purge is answered by the purging pattern's records, and a ban on refusing names its ground, as the Execution Contract says.** *Chose:* External check 5, a composing Retention Window's purge records read beside two unfiltered reads of the observation records, deleted to Execution Contract Database 6, with Check 4.1's tombstone, which named it, now naming the contract, and the label cited on Capability requirement 6; Operation 38's ground clause retired, the rule written as *[Retract] MUST NOT refuse an observation whose state EQUALS amended*, which Execution Contract Refusal 1's second sentence reads as naming the ground, so a blank retracting actor on an amended observation still answers invalid-request; rules 153 to 152. *Over:* the page stating for itself that a purge another specification declares is answered outside the observation records, and Operation 38 carrying the ground clause its fifth Final Critique wrote. *Because:* the maintainer ruled on 2026-10-22 that five repeated cures are each stated once, the composed erasure and the refusal ban among them; this page's fifth Final Critique had made both cures one specification at a time. What each action does and answers is unchanged.

- **2026-11-02 — The string cap has a default.** *Chose:* the string cap stated as 1,024 Unicode code points where a deployment declares none, Capability requirement 8 added, citing Execution Contract Input 2. *Over:* a bound the deployment must supply, or silence. *Because:* the maintainer ruled on 2026-11-01 that what the host must bound takes one posture, a corpus default a deployment may override; the string inputs run from references and a measurement's type, unit and value to a free-text reason, and 1,024 code points, the corpus's default for text (Personal Todo's description cap), holds a sentence or two.

- **2026-11-20 — A retraction records the instant it happened.** *Chose:* [Retraction Instant], one field stamped from now when a [Retract] is admitted (Operation 64), carried by every retracted observation (State 11), standing at the retraction's instant (Invariant 10.1) and written once (Invariant 9.1, Check 1.2 and Check 5.5), as an amend stamps its successor's recording instant (Operation 27, Invariant 8.2); the TLA+ model carries it (`Inv10_1_RetractionAtRetraction`, `Inv9_1_MetadataKept` over it) with two twins, a [Retract] that stamps none and one that copies the recording instant. *Over:* leaving the retraction undated, so the records could say who withdrew an observation and why and never when, and over a caller-supplied instant (the caller's clock is not the seam's; [Amend] takes none either, Operation 23). *Because:* Scott's session decided it on 2026-11-20 (rounds/escalations.md, 12:14Z and 12:42Z, answering the 11:30Z question on Ledger line 2026-10-22-c): one field, one rule, the model re-derived; an auditor reading a disputed observation (the page's regulated scenarios) needs when it was withdrawn as much as who and why, and the amend already answers the same question for a correction.

- **2026-11-26 — The atom converted to the bond shape, batch 2 of the converter: it mints and offers the observation id, needs an actor id, and names no other pattern.** *Chose:* the tree order, every label kept and none renumbered; `Term offer key: key observation id; carried by observations; calls Read` and `Term need key: key actor id; pairs observations` (Bonds Key 9, 10, 26), the observation id declared (Key 18); the six `MUST compose <pattern>` Non-goals (11, 13, 15, 16, 18, 20) tombstoned to the Non-goal that states what the atom does not do; External check 2 and 3 read the app's permission and the attestation pattern by job and cite Non-goal 12 and 10; the owners NOTE and the breach scenario say each job, not a pattern. Labelled rules 156 before, 150 after; 818 lines before, 850 after. *Over:* splitting by length (Scott, 2026-11-25 11:14 PM Central: "don't arbetrarly split at 800 lines"); the converter names no split candidate. *Because:* unit `atom: Observation, converted` (batch 2, 4 of 5).

## Migration notes

- **2026-09-15 — Capability requirement 1, moved from Operation.** What the deployment supplies, which is what the family means. The rule stood under `Operation` — one action's rules — while naming no action, because this spec was migrated before the standard family had a home in an atom; the five atoms migrated a day later put the same obligation here. The words are the words the rule carried (council read 76).

## Deleted rules

The spec's tombstones, moved here from the page on 2026-11-13 because the spec is done (GRACE-lang Hard invariant 25 and Hard invariant 27, since v0.71): each `Deleted:` line byte for byte and in the page's order, under the heading it stood under there. A tombstone carries no obligation, and each still reserves its label: no rule of [Observation](./observation.md) may carry it again.

### Structure › Identity model

```
Deleted: Identity 3. Execution Contract Logic confinement 3 owns it.
Deleted: Identity 6. Execution Contract Database 7 owns it.
```

### Structure › State

```
Deleted: State 12. Invariant 7.1 and Execution Contract Database 4 own it.
```

### Structure › Capability requirement

```
Deleted: Capability requirement 1. Execution Contract Logic confinement 11 owns it.
Deleted: Capability requirement 2. Execution Contract Logic confinement 7 owns it.
Deleted: Capability requirement 3. Execution Contract Logic confinement 7 owns it.
Deleted: Capability requirement 4. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 1. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 2. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 3. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 4. Capability requirement 5 owns it.
Deleted: Clock semantics 5. State 13 owns it.
Deleted: Clock semantics 6. State 14 owns it.
Deleted: Clock semantics 7. Non-goal 23 owns it.
```

### Structure › Operations

```
Deleted: Operation 15. Execution Contract Refusal 1 owns it.
Deleted: Operation 19. Execution Contract Refusal 1 owns it.
Deleted: Operation 20. Execution Contract Refusal 1 owns it.
Deleted: Operation 33. Execution Contract Database 1 owns it.
Deleted: Operation 40. Execution Contract Refusal 1 owns it.
Deleted: Operation 41. Execution Contract Read 4 owns it.
Deleted: Operation 52. Execution Contract Logic confinement 11 owns it.
Deleted: Operation 53. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 54. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 39. Execution Contract Read 4 owns it: a call whose write fails answers storage-failure.
```

### Structure › Invariants › Invariant 7 — Record durability

```
  Deleted: Invariant 7.2. Execution Contract Database 1 owns it.
  Deleted: Invariant 7.3. Execution Contract Database 1 and Execution Contract Database 3 own it.
```

### Generation acceptance › Conformance checks

```
Deleted: Check 4.1. Execution Contract Database 6 owns it.
```

### Generation acceptance › External checks

```
Deleted: External check 5. Execution Contract Database 6 owns it.
```

### Non-goals

```
Deleted: Non-goal 2. Capability requirement 7 owns it.
```

### Edge cases › Atomic writes

```
Deleted: Atomic writes 1. Execution Contract Database 1 owns it.
Deleted: Atomic writes 2. Execution Contract Database 1 owns it.
Deleted: Atomic writes 3. Execution Contract Database 1 and Execution Contract Database 3 own it.
Deleted: Atomic writes 4. Execution Contract Database 1 owns it.
```

### Edge cases › Concurrency

```
Deleted: Concurrency 1. Execution Contract Database 2 owns it.
Deleted: Concurrency 2. Execution Contract Database 2 owns it.
Deleted: Concurrency 3. Execution Contract Database 2 owns it.
Deleted: Concurrency 4. Execution Contract Database 2 owns it.
Deleted: Concurrency 5. Execution Contract Database 2 owns it: a chain action's state check and transition are one transaction, and the atom names no section to release.
Deleted: Concurrency 6. Execution Contract Database 2 owns it: a chain action's state check and transition are one transaction, and the atom names no section to lapse.
Deleted: Concurrency 7. Execution Contract Database 2 owns it.
```

### Edge cases › String policy

```
Deleted: String 7. Execution Contract Logic confinement 13 owns it.
```

### Composition notes

```
Deleted: Composition note 10. Execution Contract Atom interface 1 owns it.
```

### What it keeps › The observations

```
Deleted: Identity 11. String 1 owns it: a reference is a string input, compared byte for byte.
```

### While something is so › String policy

```
Deleted: String 5. GRACE-lang Term blank owns it: a value carrying only white space is blank.
Deleted: String 6. GRACE-lang Term blank owns it: an absent value is blank.
```
