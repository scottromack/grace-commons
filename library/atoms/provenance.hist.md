---
title: Provenance — history
nav_exclude: true
search_exclude: true
---

# Provenance — history

The dated record of how [Provenance](./provenance.idd) got here, moved out of the spec on 2026-10-20 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- atoms/provenance.md`.

## Decisions

Entries that record a round or a migration rather than a turn the pattern took.

- **2026-09-12 — Rewritten in GRACE lang v0.39; nothing but language changed.** *Chose:* labelled rules in fenced blocks, the six actions as a signature block, Invariant 1 through 8 keeping their numbers and their sub-rule numbering, every success effect conditioned on a declared admitted originate / admitted transfer / admitted transform / admitted disclose / admitted archive so no effect binds a refused call (Hard invariant 16), rejection precedence carried by `Operation 11`, `Operation 16` and `Operation 27` rather than by a WHY note, the seven acceptance areas raised to `Check 1.1 through 7.4`, the Non-goals-and-edge-cases prose split into a `Non-goal 1 through 22` family and five edge-case families (`String`, `Clock semantics`, `Concurrency`, `Atomic writes`, `Correction`), the Composition notes prose raised to `Composition note 1 through 8` with the named compositions moved into the WHY. *Over:* the prose spec. *Because:* the migration plan; `cites.py --into provenance` found nothing in the corpus citing this atom by label, so the rewrite carried no frozen-number risk.

- **2026-09-12 — Id uniqueness and the archived read are stated once.** *Chose:* the former Invariant 9 (no id reuse) is carried by `Identity 15` and `Identity 16` in the Identity model, and the former archived-chain-admits-a-read invariant by `Operation 53` on the action surface; the durability invariant took the freed number 9 — a renumbering Hard invariant 26 and Hard invariant 27 forbid, which left Chain of Custody's citation of Provenance's ten invariants pointing past the end; council read 95 returned durability to Invariant 10 and tombstoned Invariant 9. *Over:* keeping both copies for emphasis. *Because:* Authority 3 — two rules must not claim authority for one proposition, and the identity model is where identity rules sit. Both duplicates were found by the checker, not by a reader.

- **2026-09-12 — The transferred entry carries the custodian pair in place of a single custodian reference, not beside it.** *Chose:* `State 4` bounded to a non-transferred entry, `State 5` stating the exclusion, `Invariant 7.1` and `Check 1.1` bounded to match. *Over:* the rewrite's `EVERY entry MUST carry a custodian_ref`, which was mine and wrong. *Because:* the prose State section said the single field "is replaced by" the pair, and the preserved [Custodian Reference] term entry says so too — a rewritten rule contradicted a term entry the migration carried across byte-identical. Found by GLM on a first council read of this atom; the witness was the untouched half of the document, which is the argument for preserving term entries verbatim through a migration.

- **2026-10-20 — The store's guarantees cited, not restated.** *Chose:* the chain store supplied under Execution Contract Store 1 through 4 (Capability requirement 5), and the twelve rules that restated them, or existed only for a store that could split an append, tombstoned to their owner — Operation 38, an append's entry and counter raise committed in one operation, Invariant 10.2, no partial record left by a storage-failure rejection, and Atomic writes 1 through 3, no reader observing an entry without its counter raise, a transferred entry without its custodian change or an archived entry without the chain's move to archived, to Store 1; Atomic writes 4, an uncommitted crash leaving the chain as the call found it, to Store 1 and Store 3; Atomic writes 5 through 7, the implementation resolving a dangling transition before the store serves a read or accepts an action, to Store 1, under which no append stands partly applied; State 19, next sequence number surviving a restart, to Store 3; Concurrency 1, two calls against one chain serialized, and Concurrency 3, the second serialized transfer reading the custodian the first set, to Store 2; rules 187 to 176. *Over:* the atom restating, for its own store, what every deployment's store guarantees, and keeping a crash-recovery protocol for a split append that no conforming store leaves. *Because:* the maintainer ruled 2026-10-12 that the corpus takes a store's specification, never the store, and `execution-contract.md` writes it once as the Store contract. What stays is the atom's own: a refused action leaving the chain as the call found it, appending no entry and taking no sequence number (Operation 42 through 44), the entry chain governing a cached current custodian that disagrees with a replay (State 18), every serialized transfer appending, since [Transfer] carries no custodian guard (Concurrency 2), the host serializing its own calls for a transfer conditional on the custodian (Concurrency 4), and the append-only chain the atom never edits (State 15 through 17, Invariant 1.1, Invariant 2.1, Invariant 2.2, Invariant 10.1, Correction 1, Correction 2). The sequence number is the chain's own dense order, taken inside the append, and no rule reads an earlier version of a record, so the atom cites neither History 1 nor Order 1. What the atom does for its domain is unchanged.

- **2026-10-21 — Which refusal answers is the Execution Contract's.** *Chose:* each refuses line kept as the page wrote it, already in the page's order — [Originate] invalid-ref ahead of invalid-genesis-type; an addressed action not-known ahead of its chain-state rejection, the chain's state ahead of the attribution guard, invalid-ref ahead of not-current-custodian; storage-failure last, answering only at the write — and the order cited from the Execution Contract (Capability requirement 5, Execution Contract Refusal 1); the pairs that only stated it deleted to Refusal 1: Operation 4 (invalid-genesis-type only once both references are supplied), Operation 16 (a chain-state rejection only for a chain id naming a chain), Operation 27 (not-current-custodian only once every supplied reference is present) and Operation 45 (storage-failure behind every precondition); rules 176 to 172. *Over:* the page stating for itself which of an action's refusals answers when several apply. *Because:* the maintainer ruled on 2026-10-21 that the Execution Contract states once that the refusal listed first on an action's refuses line answers. What each action answers on every call is unchanged.

- **2026-10-22 — An action answers what its signature names, and an admitted call is one whose writes commit.** *Chose:* Operation 39 held to an admitted entry action — an admitted transfer, transform, disclose or archive — so [Originate] answers the chain id alone and the four answer the entry id only on a call that lands; the five admitted terms written as a call that passes every precondition and whose database writes commit, so no effect rule reads a call a length bound or the database refuses. *Over:* Operation 39 obliging every appending action, [Originate] among them, to answer the entry id beside Operation 9 and [Originate]'s signature, and every refused call beside its refusal; and admitted terms that stopped at a reference being supplied. *Because:* Final Critique 8 found the first, and the corpus's admitted calls (Medication Order, Credential, Provisional Commitment, Party Identity, Invitation) already read as the second does. Smaller fixes rode with them: Operation 52 deleted to Execution Contract Read 1, with Read 1 through 3 cited on Capability requirement 5; [Read]'s query marked optional, as every example calls it; Correction 4 names the transformed entry a correction rides on, as Final Critique 7's text did; External check 1 asks the deployment for the patterns it wired in (Composition note 1); the storage-failure example cites Refusal 1 for the tombstoned Operation 45; acronyms glossed at first use; an example opens a second custody episode with the received genesis type; rules 172 to 172. What each action answers and writes on a call it admits is unchanged; [Originate] answers what its signature always named.

- **2026-10-22 — An admitted call, an action set's reach and the wiring are stated once.** *Chose:* the five admitted terms citing Execution Contract Read 4 for what an action admits, in place of the commit clause this page's eighth Final Critique wrote into each, so the appending-action rules Operation 36, Operation 37 and Operation 40 and Concurrency 2 hold under Read 4 for the calls each action admits, as every other effect rule does; Operation 39 written again as the page first had it, *An appending action MUST answer the entry id*, and Term admitted entry action, the helper term the eighth Final Critique wrote, deleted, since under GRACE-lang Closed vocabulary 29 the rule binds [Transfer], [Transform], [Disclose] and [Archive], whose signatures answer the entry id, and not [Originate], whose signature answers the chain id; External check 1, the auditor reading which composing patterns a deployment wired in from the deployment's own declaration, deleted to Execution Contract Conformance 9, and the checks NOTE's sentence restating it removed; Read 4 and Conformance 9 cited on Capability requirement 5; rules 172 to 171. *Over:* the page stating for itself which calls its effect rules reach, which appending actions answer the entry id, and that the wiring is an external check. *Because:* the maintainer ruled on 2026-10-22 that five repeated cures are each stated once, the admitted effect, the category reach and the wiring declaration among them; this page's eighth Final Critique had made all three one specification at a time. What each action does and answers is unchanged.

- **2026-11-02 — The maximum length has a default.** *Chose:* the maximum length stated as 1,024 Unicode code points where a deployment declares none for each string input, which a deployment may override for one input alone; String 7 through 9 stand, Capability requirement 6 turned to *declare*, citing Execution Contract Input 2. *Over:* a bound the deployment must supply, or silence. *Because:* the maintainer ruled on 2026-11-01 that what the host must bound takes one posture, a corpus default a deployment may override; the string inputs are references, a transformation descriptor and metadata, and 1,024 code points, the corpus's default for text (Personal Todo's description cap), holds a descriptor of a sentence or two.

- **2026-11-19 — A correction is the caller's duty, and an auditor reads it.** *Chose:* Correction 3 and Correction 4 written as duties of the caller (a caller correcting an entry of an open chain calls [Transform]; its descriptor names the corrected entry's sequence number), and External check 2 for the deployment that needs a correction cleared, reading the correcting transformed entry's transformation descriptor beside the corrected entry's sequence number; the NOTE and the open line 2026-11-03-a gone. *Over:* a descriptor form the atom parses. *Because:* Non-goal 9 through 11 bar an amendment entry, a supersedes link and a view that resolves a correction, and a descriptor the atom reads and acts on is a supersedes link in all but name; the descriptor stays opaque (Term transformation descriptor, String 1 through 4); Selective Disclosure's Correction 3 and 4 with its External check 6 took the same arm, and as simple as possible without losing fidelity picks it, since no conforming build can tell a correcting [Transform] from any other (Execution Contract Read 4, Operation 28). Overrulable: a parsed descriptor form is a new rule and a new refusal, a Non-goal 9 through 11 ruling away.

## Migration notes

- **2026-09-15 — Clock dependence 1 and 2, cut out of Clock semantics and Operation.** Whether a guard's decision may depend on the clock reading, and under what condition — one question, stated in its own family rather than among the rules about what the clock is and what a transition stamps from it. Both rules keep the words they carried as Clock semantics 5 and Operation 57; only the heading changed.
- **2026-09-15 — Capability requirement 1, moved from Operation.** What the deployment supplies, which is what the family means. The rule stood under `Operation` — one action's rules — while naming no action, because this spec was migrated before the standard family had a home in an atom; the five atoms migrated a day later put the same obligation here. The words are the words the rule carried (council read 76).

- **2026-11-26 — The atom converted into the tree order and bonded: it mints and offers the chain id, its custodian references are actor ids, and no pattern is named.** *Chose:* the bonding converter's draft (grace-council assets/bond.py), judged line by line: the tree order Task, List and Ordering stand in, every label kept and none renumbered (162 before and after); `chain id` declared in declarations.md and offered as `key chain id; carried by chains`; the custodian references (the current custodian, the custodian reference, and the from and to custodian references) are actor ids, met by the need `key actor id; pairs custodian references`, since a custodian is a party who acts on the artifact; the recipient reference stays opaque, a disclosure's recipient being no actor of the chain; Non-goal 2, 4, 7, 13, 15 and 20 tombstoned to the Non-goal that owns each declined job; the owners NOTE, the WHY, the Disclose entry and the Source lines name no pattern; the invariants the draft placed twice kept once; Clock semantics under *While something is so*, after Clock dependence, and the empty Atomic writes heading dropped. *Over:* offering the entry id as a key too, which Bonds Key 10 may ask, left for the batch's design review with State Machine's transition id. *Because:* Scott's ruling of 2026-11-25 8:07 PM Central ("NEXT"), the unit `atom: Provenance, converted`, batch 1, 3 of 5.

## Deleted rules

The spec's tombstones, moved here from the page on 2026-11-13 because the spec is done (GRACE-lang Hard invariant 25 and Hard invariant 27, since v0.71): each `Deleted:` line byte for byte and in the page's order, under the heading it stood under there. A tombstone carries no obligation, and each still reserves its label: no rule of [Provenance](./provenance.idd) may carry it again.

### Structure › Identity model

```
Deleted: Identity 5. Execution Contract Logic confinement 3 owns it.
Deleted: Identity 6. Execution Contract Logic confinement 3 owns it.
Deleted: Identity 17. Execution Contract Database 7 owns it.
```

### Structure › State

```
Deleted: State 19. Execution Contract Database 3 owns it.
```

### Structure › Capability requirement

```
Deleted: Capability requirement 2. Execution Contract Logic confinement 7 owns it.
Deleted: Capability requirement 3. Execution Contract Logic confinement 7 owns it.
Deleted: Capability requirement 4. Execution Contract Logic confinement 7 owns it.
```

### Structure › Operations

```
Deleted: Operation 4. Execution Contract Refusal 1 owns it.
Deleted: Operation 16. Execution Contract Refusal 1 owns it.
Deleted: Operation 27. Execution Contract Refusal 1 owns it.
Deleted: Operation 35. Operation 34 owns it.
Deleted: Operation 38. Execution Contract Database 1 owns it.
Deleted: Operation 45. Execution Contract Refusal 1 owns it.
Deleted: Operation 52. Execution Contract Read 1 owns it.
Deleted: Operation 54. Capability requirement 1 owns it.
Deleted: Operation 55. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 56. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 57. Clock dependence 2 owns it.
```

### Structure › Invariants › Invariant 10 — Chain durability over this atom's own surface

```
  Deleted: Invariant 9. Identity 15 and Identity 16 own id uniqueness.
  Deleted: Invariant 10.2. Execution Contract Database 1 owns it.
```

### Generation acceptance › External checks

```
Deleted: External check 1. Execution Contract Conformance 9 owns it.
```

### Edge cases › Atomic writes

```
Deleted: Atomic writes 1. Execution Contract Database 1 owns it.
Deleted: Atomic writes 2. Execution Contract Database 1 owns it.
Deleted: Atomic writes 3. Execution Contract Database 1 owns it.
Deleted: Atomic writes 4. Execution Contract Database 1 and Execution Contract Database 3 own it.
Deleted: Atomic writes 5. Execution Contract Database 1 owns it.
Deleted: Atomic writes 6. Execution Contract Database 1 owns it.
Deleted: Atomic writes 7. Execution Contract Database 1 owns it.
```

### Edge cases › Clock semantics

```
Deleted: Clock semantics 1. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 2. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 3. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 5. Clock dependence 1 owns it.
Deleted: Clock semantics 6. Non-goal 23 owns it.
```

### Edge cases › Concurrency

```
Deleted: Concurrency 1. Execution Contract Database 2 owns it.
Deleted: Concurrency 3. Execution Contract Database 2 owns it.
```

### Edge cases › String policy

```
Deleted: String 6. Capability requirement 6 owns it.
```

### Composition notes

```
Deleted: Composition note 1. Capability requirement 7 owns it.
Deleted: Composition note 8. Execution Contract Atom interface 1 owns it.
```

### While something is so › String policy

```
Deleted: String 5. GRACE-lang Term blank owns it: a value carrying only white space is blank.
```
