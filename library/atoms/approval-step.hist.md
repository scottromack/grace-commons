---
title: Approval Step — history
nav_exclude: true
search_exclude: true
---

# Approval Step — history

The dated record of how [Approval Step](./approval-step.md) got here, moved out of the spec on 2026-10-19 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- atoms/approval-step.md`.

## Decisions

Entries that record a migration or a repair rather than a turn the pattern took.

- **2026-09-12 — Rewritten in GRACE lang v0.40; nothing but language changed.** *Chose:* the five actions as a signature block, Invariant 1 through 10 keeping their numbers, every success effect conditioned on a declared admitted submit, admitted resolve or admitted read (Hard invariant 16), the six-step rejection precedence — repeated verbatim in four places in the prose, once per resolving action and once in the state table — collapsed to one seven-row case space with the ordering carried by `ONLY IF` guards, the three resolving actions unified under declared resolving action, deciding reference and decision instant terms so [Approve], [Reject] and [Withdraw] state their shared guards once instead of three times, the six acceptance areas opened into `Check 1.1 through 6.3` with four `External check`s, the Non-goals-and-edge-cases prose split into a `Non-goal 1 through 20` family and five edge-case families (`String`, `Clock semantics`, `Concurrency`, `Atomic writes`, `Indeterminate outcome`). *Over:* the prose spec. *Because:* the migration plan; `cites.py --into approval-step` found nothing citing this atom by label. 81.1 KB → 62.7 KB.

- **2026-09-12 — Three propositions had two owners each.** *Chose:* `Invariant 2.1` owns membership exclusivity and the `State` family no longer restates it; `Operation 8` owns *an admitted submit stands the step in pending*; `Identity 12` owns *the atom does not confirm a subject reference*. *Over:* keeping each pair. *Because:* Authority 3, and all three were found by `W-duplicate-proposition` rather than by reading — the same pattern as State Machine, where the duplicates a 169-rule surface hides are exactly the ones no reader finds.

- **2026-09-12 — A cross-spec citation was written in the local form.** *Chose:* `Selective Disclosure Invariant 5.1`, the qualified form Hard invariant 28 declares. *Over:* `[Selective Disclosure](./selective-disclosure.md) states as its \`Invariant 5\``, which reads as a citation of *this* spec's Invariant 5 — submitter exclusivity, an unrelated rule. *Because:* the citation-aim audit resolved it against the local registry and the aim was wrong. Nothing enforces the qualified form, and a census over the corpus returns 24 candidates of which nearly all are local citations that merely sit near a spec link — so the class is docketed rather than instrumented.

- **2026-10-19 — The store's guarantees cited, not restated.** *Chose:* the step store supplied under Execution Contract Store 1 through 4 (Capability requirement 5), and the eleven rules that restated them, or stood in for them, tombstoned to their owner — Operation 31, a resolve's state change and recorded fields committed in one operation, Invariant 10.2, no partial record left by a storage-failure, and Atomic writes 1, 3 and 4, no reader seeing a terminal state without its attribution fields, a dangling transition resolved and no read served before it is, to Store 1; Atomic writes 2, an uncommitted crash leaving the step as the call found it, to Store 1 and Store 3; Invariant 10.3, an answered step id naming a durably persisted step, and External check 1, the submit answers captured to find a step the store is missing, to Store 3; Concurrency 1 through 3, two resolving actions on one step serialized, the later reading what the earlier left and answering not-pending, to Store 2; rules 163 to 153. *Over:* the atom restating, for its own store, what every deployment's store guarantees, and a deployment journalling its submit answers against a store that might lose a step. *Because:* the maintainer ruled 2026-10-12 that the corpus takes a store's specification, never the store, and `execution-contract.md` writes it once as the Store contract. The atom's own no-removal rules stay (State 5, State 14, Invariant 10.1), since Store 4 alone does not keep the atom from removing a step; Check 6.1 through 6.3 rest on the auditor's own two reads, and [Read] orders by submission instant and step id, so the atom cites neither History 1 nor Order 1. What the atom does for its domain is unchanged.

- **2026-10-21 — Which refusal answers is the Execution Contract's.** *Chose:* the resolving actions' refuses line kept as the page wrote it — invalid-request, not-known, not-pending, unauthorized, then storage-failure, which answers only at the write — and the order cited from the Execution Contract (Capability requirement 5, Execution Contract Refusal 1); the rules that only stated it deleted to Refusal 1: Operation 55, which evaluated the resolve refusal order, with Term resolve refusal order, and the pairs Operation 12 (a blank step id ahead of not-known), Operation 14 (not-known ahead of not-pending), Operation 23 (an attribution fault ahead of unauthorized) and Operation 35 (storage-failure behind every precondition); rules 154 to 149. Operation 20 stays the page's own: invalid-request answers a blank step id ahead of not-known and an attribution fault only on a pending step, after not-known and not-pending, so it holds two places in the order and no fixed line can carry both; Refusal 1 reads a refusal Operation 20 keeps from a call as not applying to it. *Over:* the page stating for itself which of a resolving action's refusals answers when several apply. *Because:* the maintainer ruled on 2026-10-21 that the Execution Contract states once that the refusal listed first on an action's refuses line answers; this page's sixth Final Critique had made the cure one specification at a time. What each action answers on every call is unchanged.

- **2026-10-21 — A failed read answers as the Execution Contract says.** *Chose:* the failed read cited from the Execution Contract (Capability requirement 5, Execution Contract Read 1 through 3) and the three rules that restated it deleted to Read 1: the atom-wide state-unavailable (Operation 53), and the submit and read refusal orders (Operation 54, Operation 56), whose rules after the read answer one code each, invalid-request and invalid-query; the read's condition off the admitted submit, resolve and read it held to an answered read, the read off the resolve refusal order and its table, Term database read deleted, and state-unavailable off every signature and the examples; rules 157 to 154. *Over:* the page stating for itself what every action answers when the step records cannot be read. *Because:* the maintainer ruled on 2026-10-21 that the Execution Contract states the failed read once; this page's sixth Final Critique had made one of the cures the contract's Read family is written from, and the read first in every order, which it gave as the pipeline's, is Read 1's. What each action answers on an answered read is unchanged.

- **2026-10-21 — A failed read answers on every action; each action's refusals answer in one stated order; a deleted subject answers as a live one.** *Chose:* state-unavailable on all five actions where the read of the step records fails, the Execution Contract's Step 1 failure (Operation 53, Term database read), the admitted submit, resolve and read each held to an answered read; one refusal order for [Submit], one for the three resolving actions and one for [Read], the read first since Step 1 runs before any guard, and the resolving actions' in the order the case table and Final Critique 5's fixed priority gave — blank step id, not-known, not-pending, the attribution checks, the actor guard (Operation 54 through 56) — with Operation 12, 14, 20 and 23 kept as the order's own pairs; and the Execution Contract's dangling-reference sentence rewritten, so a deleted subject produces no refusal of this atom's, which never consults it (Identity 12). *Over:* a failed read answered by no code the page names, which one build surfaced as a fault, one as invalid-query and one as an empty answer an auditor reads as no steps; pairwise ONLY IF rules that, each read alone, forbid what the rule they order obliges; and a guard failure the contract obliged and the atom forbids. *Because:* Final Critique 6 found each a divergence between conforming builds, or two rules no build can both obey, and the corpus already held each cure: Actor Identity's fifth round answered the failed read on every action, Verified Repair's ruling of 2026-10-19 gave each action one stated order, and the contract's own paragraph says this atom owns a decision about a reference, never the referenced thing. A blank step id is now refused after the Step 1 read, not before any lookup, since the pipeline reads first. What the atom answers a well-formed call on a readable database is unchanged.

- **2026-11-02 — The string cap has a default.** *Chose:* the string cap stated as 1,024 Unicode code points where a deployment declares none, Capability requirement 6 added, citing Execution Contract Input 2. *Over:* a bound the deployment must supply, or silence. *Because:* the maintainer ruled on 2026-11-01 that what the host must bound takes one posture, a corpus default a deployment may override; the string inputs run from references to a free-text reason, and 1,024 code points, the corpus's default for text (Personal Todo's description cap), holds a sentence or two; Operation 65 joins the attribution checks, so an over-cap deciding reference or reason is refused only on a pending step, as a blank one is (Operation 20), and a resolved step answers not-pending.

- **2026-11-26 — The atom converted to the bond shape, batch 2 of the converter: it mints and offers the step id, needs an actor id, and names no other pattern.** *Chose:* the tree order, every label kept and none renumbered; `Term offer key: key step id; carried by steps; calls Read` and `Term need key: key actor id; pairs steps` (Bonds Key 9, 10, 26), the step id declared (Key 18); the six `MUST compose <pattern>` Non-goals (2, 4, 10, 12, 15, 17) tombstoned to the Non-goal that states what the atom does not do; Indeterminate outcome 4 composes an idempotency pattern by its job and cites Non-goal 1 alone; External check 3 and 4 read the attestation and audit patterns by job; the WHY's three peers (a permission, an assignment pattern, a general state machine), the owners NOTE, a watch NOTE and the Part 11 source say each job, not a pattern. Labelled rules 151 before, 145 after; 824 lines before, 863 after. *Over:* splitting by length (Scott, 2026-11-25 11:14 PM Central: "don't arbetrarly split at 800 lines"); the converter names no split candidate. *Because:* unit `atom: Approval Step, converted` (batch 2, 3 of 5).

## Migration notes

- **2026-09-15 — Capability requirement 1, moved from Operation.** What the deployment supplies, which is what the family means. The rule stood under `Operation` — one action's rules — while naming no action, because this spec was migrated before the standard family had a home in an atom; the five atoms migrated a day later put the same obligation here. The words are the words the rule carried (council read 76).

## Deleted rules

The spec's tombstones, moved here from the page on 2026-11-13 because the spec is done (GRACE-lang Hard invariant 25 and Hard invariant 27, since v0.71): each `Deleted:` line byte for byte and in the page's order, under the heading it stood under there. A tombstone carries no obligation, and each still reserves its label: no rule of [Approval Step](./approval-step.md) may carry it again.

### Structure › Identity model

```
Deleted: Identity 3. Execution Contract Logic confinement 3 owns it.
Deleted: Identity 6. Execution Contract Logic confinement 10 owns it.
Deleted: Identity 7. Execution Contract Database 7 owns it.
Deleted: Identity 14. Execution Contract Logic confinement 13 owns it.
```

### Structure › State

```
Deleted: State 1. Invariant 3.1 owns it.
```

### Structure › Capability requirement

```
Deleted: Capability requirement 2. Execution Contract Logic confinement 7 owns it.
Deleted: Capability requirement 3. Execution Contract Logic confinement 7 owns it.
Deleted: Capability requirement 4. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 1. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 2. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 3. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 4. State 15 owns it.
Deleted: Clock semantics 5. Non-goal 21 owns it.
```

### Structure › Operations

```
Deleted: Operation 59. Execution Contract Input 1 owns it.
Deleted: Operation 12. Execution Contract Refusal 1 owns it.
Deleted: Operation 14. Execution Contract Refusal 1 owns it.
Deleted: Operation 60. Execution Contract Input 1 owns it, among the attribution checks (Term attribution check).
Deleted: Operation 23. Execution Contract Refusal 1 owns it.
Deleted: Operation 31. Execution Contract Database 1 owns it.
Deleted: Operation 35. Execution Contract Refusal 1 owns it.
Deleted: Operation 43. Execution Contract Query 3 and Operation 41 own it: a step carrying no instant on a range filter's axis fails the filter.
Deleted: Operation 49. Capability requirement 1 owns it.
Deleted: Operation 50. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 51. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 52. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 53. Execution Contract Read 1 owns it.
Deleted: Operation 54. Execution Contract Read 1 owns it: after the read, every refusal rule of [Submit] answers invalid-request.
Deleted: Operation 55. Execution Contract Refusal 1 and Operation 20 own it.
Deleted: Operation 56. Execution Contract Read 1 owns it: after the read, every refusal rule of [Read] answers invalid-query.
```

### Structure › Invariants › Invariant 10 — Record durability

```
  Deleted: Invariant 10.2. Execution Contract Database 1 owns it.
  Deleted: Invariant 10.3. Execution Contract Database 3 owns it.
```

### Generation acceptance › External checks

```
Deleted: External check 1. Execution Contract Database 3 owns it.
```

### Edge cases › Atomic writes

```
Deleted: Atomic writes 1. Execution Contract Database 1 owns it.
Deleted: Atomic writes 2. Execution Contract Database 1 and Execution Contract Database 3 own it.
Deleted: Atomic writes 3. Execution Contract Database 1 owns it.
Deleted: Atomic writes 4. Execution Contract Database 1 owns it.
```

### Edge cases › Concurrency

```
Deleted: Concurrency 1. Execution Contract Database 2 owns it.
Deleted: Concurrency 2. Execution Contract Database 2 owns it.
Deleted: Concurrency 3. Execution Contract Database 2 owns it.
```

### Edge cases › Indeterminate outcome

```
Deleted: Indeterminate outcome 2. Execution Contract Error model 1 owns it.
Deleted: Indeterminate outcome 3. Execution Contract Error model 1 owns it.
```

### Edge cases › String policy

```
Deleted: String 7. Execution Contract Logic confinement 13 owns it.
```

### Composition notes

```
Deleted: Composition note 11. Execution Contract Atom interface 1 owns it.
```
