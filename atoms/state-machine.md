---
title: State Machine
parent: Atomic Concepts
has_toc: true
toc: true
---

# State Machine

<details markdown="block">
<summary>Table of contents</summary>
{: .text-delta }
1. TOC
{:toc}
</details>

## Summary

State Machine records a single named process instance — think of it as a token moving through a flowchart — where the flowchart (the set of valid states and the transitions between them) is declared by the system deploying it rather than fixed by this atom.

When the instance is created, the deployer provides the complete map: every state, every allowed move between states (each move is a named action, optionally gated by a condition the calling system must assert is satisfied), the starting state, and any states that are permanent endpoints. From that moment forward the map is frozen — it cannot be changed for this instance.

The atom then enforces three guarantees for the lifetime of the instance: only declared moves are allowed (an undeclared move is refused); exactly one current state exists at all times; and every move that succeeds is recorded permanently, in order, with enough context to replay the full history and arrive at the current state.

These guarantees make the system useful for regulated processes (a pharmaceutical batch that must prove it moved only through the approved sequence of quality-control states) and for any process where you need an unambiguous, auditable record of what happened and in what order. This atom is the general pattern; [Approval Step](./approval-step.md) is one specific kind of state machine with its states and rules fixed in advance, whose instances do not need their own declaration.

*Also known as: a workflow instance, a process instance, a declared finite state machine.*

---

## Intent

WHY:
Many real-world processes move an entity through a defined sequence of states: a pharmaceutical batch advances from *sampled* through *tested* through *qualified* through *released*; a purchase order from *draft* through *submitted* through *approved* through *fulfilled*; a change request from *open* through *in-review* through *merged* through *deployed*. In each the valid transitions are known in advance, the order they fire in must be auditable, and the current state must be unambiguously knowable at any moment. The structure governing them is the same in all of them: a named entity, a finite declared set of states, a declared set of transitions, and a durable history of which fired and when.

The core problem is that different deployments need different state machines. A batch-release workflow is governed by 21 CFR (Code of Federal Regulations) Part 11 and ISO (International Organization for Standardization) 9001 §8.5.1. An HL7 (Health Level Seven) FHIR (Fast Healthcare Interoperability Resources) Task resource has its own lifecycle. A BPMN (Business Process Model and Notation) workflow varies by process type. Writing a separate atom for each is not feasible, and it is also not the right factoring: the commonality is declared-finite-state-machine *enforcement*, not the particular states. That is what this atom captures — the declaration is data supplied by the deployment, and the enforcement is the atom.

The atom is structurally distinct from two adjacent concepts, and both distinctions are load-bearing.

[Approval Step](./approval-step.md) is a *specific* state machine whose states, transitions and semantics are fixed at the atom level — an external evaluator knows them without reading any deployment configuration. This atom's machine is fixed at the *instance* level, and an external evaluator must read the instance's declaration to know what is valid. Specificity is the axis: Approval Step is specification-level, State Machine is instance-level. Approval Step also carries approval-specific semantics — one named approver, submitter exclusivity on withdrawal, a required reason on rejection — that this atom carries none of. Both are freestanding, and they compose into [Execute Gated Workflow](../compositions/execute-gated-workflow.md), where a State Machine instance governs the process lifecycle and Approval Step instances govern the gates inside it.

[Event Log](./event-log.md) records what happened; this atom enforces what is allowed to happen and tracks the resulting state. The transition history here resembles an event log structurally — append-only, totally ordered by a sequence number, with wall time as a best-effort annotation — but an event log has no declared states, no declared transitions, no current state and no validity gate. This atom is freestanding and does not name Event Log; where the two meet is a composition's business.

The guard is where the atom's restraint is sharpest. A declared transition may carry a guard label, and the atom enforces that the caller *asserts* the guard satisfied before the transition fires — while evaluating nothing. The history records the assertion, not a verdict. A caller asserting a guard it never checked is violating the declared process and the atom will record the assertion faithfully, because the alternative is an atom that must understand every deployment's predicates, which is the absorption this factoring exists to prevent.

## Structure

### Identity model

```
Identity 1: The atom MUST identify an instance by the instance_id.
Identity 2: The atom MUST identify a history entry by the transition_id.
Identity 3: The host MUST allocate an instance_id at the seam.
Identity 4: The host MUST allocate a transition_id at the seam.
Identity 5: The transition MUST NOT allocate an instance_id.
Identity 6: The transition MUST NOT allocate a transition_id.
Identity 7: The atom MUST NOT change an instance_id.
Identity 8: The atom MUST NOT change a transition_id.
Identity 9: Two instances in one store instance MUST NOT share an instance_id.
Identity 10: Two history entries in one instance MUST NOT share a transition_id.
Identity 11: The deployment MUST choose an instance_id format that sorts in lexicographic byte order.
Identity 12: The deployment MUST route EVERY call to one store instance.
Identity 13: The atom MUST NOT identify an instance by the subject_ref.
Identity 14: The atom MUST admit a second instance carrying a recorded subject_ref.
Identity 15: The atom MUST NOT confirm that a subject_ref names a known subject.
Identity 16: The atom MUST NOT interpret an instance_metadata.
```

Term instance: one workflow instance — one declaration, one current state and one transition history; the record this atom holds.

Term instance_id: the opaque value naming one instance — an [Instance Id]; host-allocated at the seam.

Term history entry: one recorded transition on one instance, carrying `transition_id`, `sequence_number`, `from_state`, `to_state`, `action`, `fired_at` and, where supplied, `actor_ref` and `guard_satisfied`.

Term transition_id: the opaque value naming one history entry — a [Transition Id]; host-allocated at the seam.

Term subject_ref: the opaque reference naming the entity whose lifecycle the instance governs — a [Subject Ref]; a property of the instance, never the instance's identity.

Term instance_metadata: the opaque payload the caller supplies at [Instantiate] for deployment context — an [Instance Metadata]; recorded, never interpreted.

Term store instance: one named workflow store a call is routed to; `instance_id` uniqueness ranges over one instance.

Term seam: the atom's I/O boundary as `execution-contract.md` §Logic confinement declares it; the host injects the clock reading, the instance_id and the transition_id here.

Term transition: the atom's evaluation of one call against the workflow store, as `execution-contract.md` §Logic confinement declares it.

Term declared transition: one `from_state`, `action`, `to_state` and optional `guard` in the declaration — a move the instance may make. Distinct from the transition above, which is the atom's evaluation of a call.

WHY:
The corpus's word *transition* carries two senses here and the atom cannot avoid either: the execution contract's transition (one evaluation of one call) and the state machine's declared transition (one edge in the declaration). Both are declared, and every rule names which.

Lexicographic sortability (Identity 11) is the same deployment obligation [Selective Disclosure](./selective-disclosure.md) carries and for the same reason — it is the tiebreaker a deterministic read rests on.

### State

```
State 1: EVERY instance MUST carry instance_id, a declaration, a current state, a transition history and next_sequence_number.
State 2: An instance MAY carry subject_ref.
State 3: An instance MAY carry instance_metadata.
State 4: EVERY history entry MUST carry transition_id, sequence_number, from_state, to_state, action and fired_at.
State 5: A history entry MAY carry actor_ref.
State 6: The atom MUST NOT offer an instance removal surface.
State 7: The atom MUST NOT offer a history entry removal surface.
State 8: The atom MUST NOT offer a history entry edit surface.
State 9: The atom MUST NOT offer a reorder surface.
State 10: The atom MUST NOT offer a transition out of a terminal state.
State 11: The atom MUST NOT offer an action that stands an instance in two states.
State 12: The store instance's instance count MUST NOT fall.
State 13: An instance's transition history MUST NOT shrink.
State 14: next_sequence_number MUST survive a restart.
```

WHY:
State 14 is stated as a rule rather than left to the implementation because the failure it prevents is silent and total. A counter that resets to one on restart produces two history entries carrying `sequence_number: 1`, which breaks Invariant 6's total order and Invariant 7's replay in the same stroke — and it breaks them *retroactively*, for a history that looked correct before the restart and is unrecoverable after.

### Capability requirement

```
Capability requirement 1: The deployment MUST supply now at the seam.
Capability requirement 2: The deployment MUST own the clock's monotonicity.
Capability requirement 3: The deployment MUST own the clock's honesty.
Capability requirement 4: The deployment MUST own the clock's synchronization.
```

WHY:
What the deployment supplies, which is what the family means. The rule stood under `Operation` — one action's rules — while naming no action, because this spec was migrated before the standard family had a home in an atom; the five atoms migrated a day later put the same obligation here. The words are the words the rule carried (council read 76).

### Operations

```
instantiate(declaration, optional actor_ref, optional instance_metadata, optional instantiated_at)
  answers instance_id
  refuses invalid-declaration | invalid-request | storage-failure

fire(instance_id, action, optional actor_ref, optional guard_satisfied, optional fired_at)
  answers new_state
  refuses invalid-request | not-known | terminal | invalid-transition | guard-not-satisfied | storage-failure

current(instance_id)
  answers current_state
  refuses invalid-request | not-known

history(instance_id, optional query)
  answers the matching history entries
  refuses invalid-request | not-known | invalid-query

read_declaration(instance_id)
  answers declaration
  refuses invalid-request | not-known
```

```
Operation 1: [Instantiate] MUST answer invalid-request ONLY IF the declaration is well-formed.
Operation 2: IF a supplied actor_ref NOT EXISTS THEN an action MUST answer invalid-request.
Operation 3: IF the resolved instantiated_at EXCEEDS now THEN [Instantiate] MUST answer invalid-request.
Operation 4: An admitted instantiate MUST record EXACTLY ONE instance.
Operation 5: An admitted instantiate MUST stand the instance in the initial state.
Operation 6: An admitted instantiate MUST set next_sequence_number to one.
Operation 7: An admitted instantiate MUST record an empty transition history.
Operation 8: An admitted instantiate MUST answer the instance_id.
Operation 9: IF instance_id NOT EXISTS THEN an addressed action MUST answer invalid-request.
Operation 10: IF action NOT EXISTS THEN [Fire] MUST answer invalid-request.
Operation 11: IF the instance_id names no instance THEN an addressed action MUST answer not-known.
Operation 12: An addressed action MUST answer not-known ONLY IF instance_id EXISTS.
Operation 13: IF the current state EXISTS in the terminal states THEN [Fire] MUST answer terminal.
Operation 14: [Fire] MUST answer terminal ONLY IF the instance_id names an instance.
Operation 15: IF no declared transition matches the current state and action THEN [Fire] MUST answer invalid-transition.
Operation 16: [Fire] MUST answer invalid-transition ONLY IF the current state NOT EXISTS in the terminal states.
Operation 17: IF the matched transition carries a guard AND guard_satisfied NOT EXISTS THEN [Fire] MUST answer guard-not-satisfied.
Operation 18: [Fire] MUST answer guard-not-satisfied ONLY IF a declared transition matches.
Operation 19: IF the resolved fired_at EXCEEDS now THEN [Fire] MUST answer invalid-request.
Operation 20: IF the resolved fired_at precedes the instance's instantiated_at THEN [Fire] MUST answer invalid-request.
Operation 21: An admitted fire MUST append EXACTLY ONE history entry.
Operation 22: An admitted fire MUST take the history entry's sequence_number from next_sequence_number.
Operation 23: An admitted fire MUST raise next_sequence_number by one.
Operation 24: An admitted fire MUST set the history entry's from_state to the current state the call found.
Operation 25: An admitted fire MUST set the history entry's to_state to the matched transition's to_state.
Operation 26: An admitted fire MUST stand the instance in the matched transition's to_state.
Operation 27: An admitted fire MUST commit the entry, the raise and the state change in one operation.
Operation 28: An admitted fire MUST answer the matched transition's to_state.
Operation 29: An admitted fire over a guarded transition MUST record guard_satisfied on the history entry.
Operation 30: An admitted fire over an unguarded transition MUST NOT record guard_satisfied on the history entry.
Operation 31: [Fire] MUST NOT evaluate a guard.
Operation 32: [Fire] MUST NOT offer a wildcard declared transition.
Operation 33: IF the store refuses the write THEN a writing action MUST answer storage-failure.
Operation 34: An action MUST answer storage-failure ONLY IF EVERY precondition passes.
Operation 35: A refused action MUST leave the instance as the call found the instance.
Operation 36: A refused action MUST NOT append a history entry.
Operation 37: A refused action MUST NOT raise next_sequence_number.
Operation 38: [Current] MUST answer the instance's current state.
Operation 39: An admitted history MUST answer the matching history entries in sequence_number ascending order.
Operation 40: An admitted history MUST answer EVERY history entry matching the supplied filters.
Operation 41: An admitted history MUST NOT answer a history entry failing a supplied filter.
Operation 42: IF no history entry matches THEN an admitted history MUST answer an empty entry sequence.
Operation 43: IF a filter's axis NOT EXISTS in the filter axes THEN [History] MUST answer invalid-query.
Operation 44: IF a string filter's value NOT EXISTS THEN [History] MUST answer invalid-query.
Operation 45: IF a range filter's end precedes the range's start THEN [History] MUST answer invalid-query.
Operation 46: [History] MUST answer invalid-query ONLY IF the instance_id names an instance.
Operation 47: [Read Declaration] MUST answer the instance's declaration.
Operation 48: [Read Declaration] MUST NOT normalize the declaration.
Operation 49: [Read Declaration] MUST NOT reorder the declaration.
Operation 50: A reading action MUST NOT write.
Deleted: Operation 51. Capability requirement 1 owns it.
Deleted: Operation 52. `execution-contract.md` §Logic confinement owns it.
Deleted: Operation 53. `execution-contract.md` §Logic confinement owns it.
Deleted: Operation 54. `execution-contract.md` §Logic confinement owns it.
Operation 55: An ordering rule MUST NOT rest on fired_at.
```

Term now: the wall-time reading the host takes at the seam and hands to the transition, as `execution-contract.md` §Logic confinement declares it; never read inside the transition, never supplied by the business caller.

Term business caller: the party whose action the call carries, as `execution-contract.md` §Logic confinement declares it; never the source of an injected value.

Term addressed action: any action carrying an instance_id — every action but [Instantiate].

Term writing action: [Instantiate] | [Fire] — the two actions that write.

Term reading action: [Current] | [History] | [Read Declaration] — the three that do not.

Term current state: the state the instance stands in — a [Current State]; the initial state until a fire lands, and the latest history entry's to_state after.

Term next_sequence_number: the counter [Fire] takes a sequence_number from — a [Next Sequence Number]; begins at one, rises by one per append, and survives a restart.

Term sequence_number: the strictly increasing integer a history entry takes at append — a [Sequence Number]; the history's order source, and never taken from a clock.

Term fired_at: the instant a declared transition fired — a [Fired At]; a best-effort annotation, and never an order source.

Term instantiated_at: the instant an instance was created — an [Instantiated At].

Term resolved fired_at: the `fired_at` the history entry carries — the supplied value where one exists, and `now` otherwise.

Term resolved instantiated_at: the `instantiated_at` the instance carries — the supplied value where one exists, and `now` otherwise.

Term actor_ref: the opaque reference naming who fired a declared transition — an [Actor Ref]; optional, and recorded where supplied.

Term guard: the opaque label naming the condition a caller asserts before a declared transition fires — a [Guard].

Term guard_satisfied: the caller's assertion that a guard holds — a [Guard Satisfied]; an assertion, never a verdict.

Term matched transition: the one declared transition whose from_state is the current state and whose action is the call's action (Declaration 13).

Term filter axes: `transition_id` | `sequence_number` | `from_state` | `to_state` | `action` | `actor_ref` | `fired_at` — the seven axes [History] accepts, and no others.

Term admitted instantiate: an [Instantiate] call whose declaration, actor_ref and resolved instantiated_at the guards all admit.

Term admitted fire: a [Fire] call whose instance_id names a live instance, whose action matches a declared transition the current state offers, whose guard the caller asserted where one is carried, and whose actor_ref and resolved fired_at the guards admit.

Term admitted history: a [History] call whose instance_id names an instance and whose every filter axis and filter value the guards admit.

| # | Condition | [Fire] answers |
|---|---|---|
| 1 | instance_id or action is blank | `invalid-request` |
| 2 | both are well-formed, the instance_id names no instance | `not-known` |
| 3 | the instance exists, the current state is terminal | `terminal` |
| 4 | the current state is not terminal, no declared transition matches | `invalid-transition` |
| 5 | a declared transition matches, it carries a guard, the caller asserts none | `guard-not-satisfied` |
| 6 | the gate clears, actor_ref is blank or the resolved fired_at is out of bounds | `invalid-request` |
| 7 | every precondition passes, the store refuses the write | `storage-failure` |
| 8 | every precondition passes, the store accepts the write | `new_state` |

NOTE: watch condition negation — `invalid-request` occupies two rows of one precedence chain (row 1 and row 6), so the answer alone does not say which guard refused. Audit Trail's 2026-08-30-a open line is the same shape with a worse consequence, its row 6 landing after a commitment.

WHY:
The precedence chain is the atom's most load-bearing ordering and every step earns its place. Argument well-formedness precedes the store lookup (row 1) so a malformed call never costs a read. `not-known` precedes `terminal` (row 2) because a state answer about an instance that does not exist would be an invention. `terminal` precedes `invalid-transition` (row 3) because an absorbed instance rejects *every* action, and telling a caller their action was undeclared when the instance would refuse any action sends them to fix the wrong thing. `invalid-transition` precedes `guard-not-satisfied` (row 4) because a guard belongs to a declared transition, and an undeclared move has no guard to be unsatisfied about.

Row 6 is the one that surprises, and it is deliberate: attribution and temporal checks run *after* the gate. The alternative — checking `fired_at` before the guard — would tell a caller their timestamp is wrong on a transition they were never allowed to make, which leaks the declaration's shape to a caller the declaration refuses.

Operation 20 states the within-instance temporal bound as a precedence rather than as a comparison, which is why no rule here spells `≥` as a two-arm disjunction. A transition cannot be recorded as firing before the instance existed; a transition firing *at* the instant of instantiation is legal, and `precedes` says exactly that in one arm.

Operation 55 is the discipline [Event Log](./event-log.md) set and this atom inherits: `fired_at` is best-effort and `sequence_number` is the order. Under a skewing clock a later history entry may legitimately carry an earlier `fired_at`, and no invariant here is at risk from it.

### Invariants

- **Invariant 1 — Declaration immutability.**
  ```
  Invariant 1.1: A recorded declaration's field MUST NOT change.
  Invariant 1.2: [Read Declaration] MUST answer the declaration as [Instantiate] took the declaration.
  ```
- **Invariant 2 — Exactly one current state.**
  ```
  Invariant 2.1: EVERY instance MUST stand in EXACTLY ONE member of the instance's states.
  ```
- **Invariant 3 — Only declared transitions fire.**
  ```
  Invariant 3.1: EVERY history entry MUST match EXACTLY ONE declared transition in the instance's declaration.
  Invariant 3.2: Two declared transitions in one declaration MUST NOT share one from_state and one action.
  ```
  WHY: Invariant 3.2 is what makes Invariant 3.1's *exactly one* reachable. The uniqueness is enforced once, at [Instantiate] (Declaration 13), and every later match inherits it — so the atom never carries a tiebreak rule, because a conforming declaration never presents a tie.
- **Invariant 4 — Terminal absorption.**
  ```
  Invariant 4.1: An instance standing in a terminal state MUST NOT leave the terminal state.
  Invariant 4.2: A declared transition's from_state MUST NOT stand in the terminal states.
  ```
  WHY: absorption holds twice over — by enforcement at [Fire] (Operation 13) and by construction in the declaration (Invariant 4.2), which is what makes it structural. A deployment needing post-terminal behaviour models it as a non-terminal state or instantiates a new instance; there is no reopen surface and there is no declaration that could describe one.
- **Invariant 5 — History append-only and complete.**
  ```
  Invariant 5.1: A history entry MUST NOT change.
  Invariant 5.2: An instance's history entry count MUST equal the instance's admitted fire count.
  ```
- **Invariant 6 — History total order.**
  ```
  Invariant 6.1: Two history entries in one instance MUST NOT share a sequence_number.
  Invariant 6.2: An instance's sequence_numbers MUST stand from one to the instance's history entry count.
  Invariant 6.3: An instance's history order MUST rest on sequence_number alone.
  ```
- **Invariant 7 — Replay determinism.**
  ```
  Invariant 7.1: An instance carrying a history entry MUST stand in the highest sequence_number entry's to_state.
  Invariant 7.2: An instance carrying no history entry MUST stand in the initial state.
  Invariant 7.3: A replay of an instance's history from the initial state in sequence_number ascending order MUST reach the instance's current state.
  ```
  WHY: the current state is a projection of the history, cached so a guard need not replay. Invariant 7.3 is what makes the cache safe to hold: an auditor can rebuild the state from the entries alone, and a disagreement between the cache and the replay is a conformance failure rather than a repair job.
- **Invariant 8 — Guard gating without evaluation.**
  ```
  Invariant 8.1: A guarded declared transition MUST fire ONLY IF the caller asserts guard_satisfied.
  Invariant 8.2: The atom MUST NOT evaluate a guard's condition.
  Invariant 8.3: A guarded declared transition's history entry MUST record the caller's assertion.
  ```
  WHY: the entry attests that the caller asserted the guard at the moment of the call, and attests nothing about the world. The distinction is the atom's whole restraint, and it is what an auditor must understand before reading `guard_satisfied: true` as evidence — it is evidence of an assertion, and [Execute Gated Workflow](../compositions/execute-gated-workflow.md) is where the assertion is earned by reading a bound [Approval Step](./approval-step.md).
- **Invariant 9 — Transition attribution completeness.**
  ```
  Invariant 9.1: A recorded actor_ref MUST carry a non-whitespace character.
  ```
  WHY: the entry is complete for forensic replay whether or not `actor_ref` was supplied. Attribution is deployment policy here, not an atom-level mandate — which is exactly the gap [Actor Identity](./actor-identity.md) closes where a regulator needs the actor bound rather than named.
- **Invariant 10 — Store durability.**
  ```
  Invariant 10.1: The atom MUST NOT remove an instance from the store.
  Invariant 10.2: The atom MUST NOT remove a history entry from an instance.
  Invariant 10.3: A storage-failure rejection MUST leave no partial record in the store.
  ```

### The declaration

```
Declaration 1: [Instantiate] MUST NOT take a partial declaration.
Declaration 2: The atom MUST NOT change a recorded declaration.
Declaration 3: The atom MUST NOT offer a declaration edit surface.
Declaration 4: EVERY enforcement decision MUST rest on the instance's declaration.
Declaration 5: IF states carries no member THEN [Instantiate] MUST answer invalid-declaration.
Declaration 6: IF a state name NOT EXISTS THEN [Instantiate] MUST answer invalid-declaration.
Declaration 7: IF two state names in states match THEN [Instantiate] MUST answer invalid-declaration.
Declaration 8: IF the initial state NOT EXISTS in states THEN [Instantiate] MUST answer invalid-declaration.
Declaration 9: IF the initial state EXISTS in the terminal states THEN [Instantiate] MUST answer invalid-declaration.
Declaration 10: IF a declared transition's from_state NOT EXISTS in states THEN [Instantiate] MUST answer invalid-declaration.
Declaration 11: IF a declared transition's to_state NOT EXISTS in states THEN [Instantiate] MUST answer invalid-declaration.
Declaration 12: IF a declared transition's from_state EXISTS in the terminal states THEN [Instantiate] MUST answer invalid-declaration.
Declaration 13: IF two declared transitions share one from_state and one action THEN [Instantiate] MUST answer invalid-declaration.
Declaration 14: IF a declared transition's action NOT EXISTS THEN [Instantiate] MUST answer invalid-declaration.
Declaration 15: IF a supplied guard NOT EXISTS THEN [Instantiate] MUST answer invalid-declaration.
Declaration 16: The terminal states MAY carry no member.
Declaration 17: A declared transition MAY carry no guard.
```

Term declaration: the immutable map governing one instance — a [Declaration]; carries `states`, the declared transitions, the initial state and the terminal states.

Term states: the named states one declaration admits — a [States]; every state name the instance may stand in.

Term initial state: the state an instance stands in at [Instantiate] — an [Initial State]; a member of `states` and never a terminal state.

Term terminal states: the absorbing members of `states` — a [Terminal States]; possibly none.

Term well-formed declaration: a declaration Declaration 5 through 15 all admit.

WHY:
Declaration 13 is the determinism constraint and the load-bearing one: at most one declared transition per `from_state` and `action` pair means a [Fire] either matches exactly one edge or none, and the atom never chooses between two. Without it *fire the approve action* would be ambiguous in a declaration that named two approve edges, and an implementation would have to invent a tiebreak the spec does not have.

Declaration 9 and Declaration 12 are the same claim from two directions, and neither is redundant. Declaration 9 refuses an instance born absorbed — an instance whose initial state is terminal accepts nothing and exists only to be stuck. Declaration 12 refuses an edge *out of* a terminal state, which is what makes Invariant 4's absorption structural rather than merely enforced at [Fire]: a conforming declaration cannot even describe the move.

---

## Examples

### Pharmaceutical batch qualification

A quality system instantiates a batch-release workflow. The declaration names `states: [sampled, tested, qualified, released, rejected]`, `initial state: sampled`, `terminal states: [released, rejected]`, and five declared transitions — `sampled --test--> tested`, `tested --qualify[qa_signoff]--> qualified`, `tested --reject--> rejected`, `qualified --release[qa_signoff]--> released`, `qualified --reject--> rejected`. `instantiate(declaration, actor_ref: "qa-system", subject_ref: "batch-x91")` → `wf_01HQ…`, standing in `sampled` with `next_sequence_number: 1` (Operation 4 through 8).

`fire("wf_01HQ…", "test", actor_ref: "lab-tech-r.chen")` → `tested`. One history entry lands at `sequence_number: 1` carrying `from_state: sampled`, `to_state: tested` (Operation 21 through 28).

`fire("wf_01HQ…", "qualify", actor_ref: "qa-lead-m.ross")` → `guard-not-satisfied`. The declared transition carries the `qa_signoff` guard and the call asserted nothing (Operation 17). The same call with `guard_satisfied: true` → `qualified`, and the entry records the assertion (Operation 29).

`fire("wf_01HQ…", "release", guard_satisfied: true, actor_ref: "qa-lead-m.ross")` → `released`. The instance now stands in a terminal state.

### The audit question

An inspector asks whether the batch moved only through the approved sequence. `read_declaration("wf_01HQ…")` answers the map as supplied, unchanged since instantiation (Invariant 1.2). `history("wf_01HQ…")` answers three entries in `sequence_number` order. Every entry's `from_state`, `action` and `to_state` triple appears in the declaration (Invariant 3.1), and replaying them from `sampled` arrives at `released`, which is what `current("wf_01HQ…")` answers (Invariant 7.3). The declaration bounds what *could* have happened and the history says what *did*; neither alone answers the inspector.

### Rejection paths

`fire("wf_01HQ…", "test")` against the released instance → `terminal`. Not `invalid-transition`, even though no `test` edge leaves `released` — an absorbed instance refuses every action, and saying so sends the caller to the right problem (Operation 13, Operation 16).

`fire("wf_01HQ…", "expedite")` against a live instance in `tested` → `invalid-transition`. No declared transition matches, and there is no wildcard (Operation 15, Operation 32).

`fire("wf_99999", "test")` → `not-known`. `fire("", "test")` → `invalid-request`, refused before any store lookup (Operation 9, Operation 12).

`instantiate(declaration)` where two declared transitions both leave `tested` on `qualify` → `invalid-declaration`. The determinism constraint refuses the ambiguity at birth rather than inventing a tiebreak at fire time (Declaration 13).

`instantiate(declaration)` where `initial state: released` and `released` is terminal → `invalid-declaration`. An instance born absorbed accepts nothing (Declaration 9).

`instantiate(declaration)` carrying an edge out of `released` → `invalid-declaration` (Declaration 12).

`fire("wf_01HQ…", "test", fired_at: "2020-01-01")` against an instance instantiated in 2026 → `invalid-request`. A transition cannot fire before the instance existed (Operation 20).

### Multi-instance independence

Two batches run the same declaration as two instances. Firing `test` on one moves one current state; the other is untouched, carries its own history and its own `next_sequence_number`. The declaration is a value each instance holds, not a shared object (Non-goal 8).

### Regulated adversarial scenarios

- **Regulator audit.** An FDA inspector auditing under 21 CFR Part 11 and ISO 9001 §8.5.1 asks the system to prove the batch moved only through approved states. Check 2.1 and Check 6.1 are the structural answer: every history entry matches a declared transition, and the declaration is the one supplied at instantiation. What the atom cannot answer is whether the `qa_signoff` guard was truly satisfied — `guard_satisfied: true` attests an assertion (Invariant 8.3), and the evidence lives in the composing [Approval Step](./approval-step.md) record.
- **Disputed transition.** An external party claims the workflow skipped a required state. The history is gap-free by `sequence_number` (Invariant 6.2) and replays to the current state (Invariant 7.3), so a skipped state would have to appear as a declared transition that jumps it — which the declaration either names or does not. The claim resolves against the declaration, not against testimony.
- **Breach investigation.** An investigator reconstructing an anomaly window filters the history by `fired_at` range and finds the entries generously bracketed. Because `sequence_number` is dense and is the order source (Invariant 6.2, Operation 55), the investigator confirms the window's completeness against an unfiltered read rather than trusting the wall-time filter — a clock-skewed entry can fall outside the bracket and cannot fall out of the sequence.

---

## Generation acceptance

This atom's acceptance is what an external auditor can clear from the workflow store and the declaration, with no recourse to source code, runbooks or developer narration.

### Conformance checks

```
Check 1.1: An auditor MUST find a re-read declaration unchanged from the prior read (Invariant 1.1).
Check 1.2: An auditor MUST find a declaration unchanged across an admitted fire (Invariant 1.1).
Check 2.1: An auditor MUST find EVERY history entry's from_state, action and to_state standing as a declared transition in the instance's declaration (Invariant 3.1).
Check 2.2: An auditor MUST find no two declared transitions in one declaration sharing one from_state and one action (Invariant 3.2).
Check 3.1: An auditor MUST find EVERY instance standing in EXACTLY ONE member of the instance's states (Invariant 2.1).
Check 4.1: An auditor MUST find an instance standing in a terminal state carrying no history entry following the entry that reached the terminal state (Invariant 4.1).
Check 4.2: An auditor MUST find no declared transition's from_state standing in the terminal states (Invariant 4.2).
Check 5.1: An auditor MUST find an instance's sequence_numbers standing from one to the instance's history entry count (Invariant 6.2).
Check 5.2: An auditor MUST reconstruct an instance's history order from sequence_number alone (Invariant 6.3).
Check 5.3: An auditor MUST find a re-read history entry's fields unchanged from the prior read (Invariant 5.2).
Check 6.1: An auditor MUST reach the instance's current state by replaying the instance's history from the initial state (Invariant 7.3).
Check 7.1: An auditor MUST find guard_satisfied recorded on EVERY guarded declared transition's history entry (Invariant 8.3).
Check 7.2: An auditor MUST find no guard_satisfied recorded on an unguarded declared transition's history entry (Operation 30).
Check 8.1: An auditor MUST find transition_id, sequence_number, from_state, to_state, action and fired_at on EVERY history entry (State 4).
Check 8.2: An auditor MUST find a non-whitespace character in EVERY recorded actor_ref (Invariant 9.1).
```

NOTE: EVERY check names the rule the check tests.

### External checks

```
External check 1: A deployment needing a guard's condition confirmed MUST read the composing pattern that evaluates the guard (Invariant 8.2).
External check 2: A deployment needing an instance's history entry count matched against the instance's admitted fire count MUST capture the fire answers (Invariant 5.2).
External check 3: A deployment needing an actor_ref bound to an actor MUST read the composing [Actor Identity](./actor-identity.md) attestation (Non-goal 11).
```

WHY:
External check 2 is the check that could not stay in the conformance list. Counting an instance's history entries is trivial from the store; matching that count against the number of *admitted* fires needs the fire answers captured at call time, and a production auditor reading the store cannot enumerate them — the store is exactly what would be missing an entry. Check 5.1 is the store-alone substitute: a gap-free run from one to the entry count catches a lost entry from the other direction.

External check 1 is the atom's central restraint stated as an audit boundary. `guard_satisfied: true` is evidence that a caller asserted a guard, and evidence of nothing else. An auditor reading it as proof the condition held has misread the record, and the atom says so here rather than letting the misreading happen.

## Non-goals

```
Non-goal 1: A deployment needing a guard evaluated MUST compose the evaluating pattern.
Non-goal 2: A deployment gating a declared transition on an approval MUST compose [Approval Step](./approval-step.md).
Non-goal 3: The atom MUST NOT stand an instance in two states at once.
Non-goal 4: The atom MUST NOT offer a fork declared transition.
Non-goal 5: The atom MUST NOT offer a join declared transition.
Non-goal 6: The atom MUST NOT nest a state inside a state.
Non-goal 7: A deployment needing a nested state MUST name the nested state as a flat state.
Non-goal 8: The atom MUST NOT share one declaration across two instances.
Non-goal 9: The atom MUST NOT version a declaration.
Non-goal 10: A deployment needing a shared declaration template MUST compose a definition registry pattern.
Non-goal 11: The atom MUST NOT bind an actor_ref to an actor.
Non-goal 12: A deployment needing a non-repudiable actor MUST compose [Actor Identity](./actor-identity.md).
Non-goal 13: The atom MUST NOT detect a rewrite under the store.
Non-goal 14: A deployment needing a rewrite detected MUST compose [Tamper Evidence](./tamper-evidence.md).
Non-goal 15: The atom MUST NOT bound an instance's retention.
Non-goal 16: A deployment needing a retention bound MUST compose [Retention Window](./retention-window.md).
Non-goal 17: The atom MUST NOT decide who may call an action.
Non-goal 18: A deployment needing an authorization decision MUST compose [Permissions](./permissions.md).
Non-goal 19: The atom MUST NOT decide which state an instance ought to stand in.
Non-goal 20: The atom MUST NOT read two [Fire] calls carrying one instance_id and one action as one fire.
Non-goal 21: A deployment needing at-most-once firing MUST supply the deployment's own idempotency key.
Non-goal 22: A deployment needing a verifiable time anchor MUST compose a trusted timestamping pattern.
```

WHY:
Non-goal 3 through 5 bound the atom to a single active state, and the bound is what makes every other guarantee statable. Parallel workflows — an instance live in several states, a join firing when all branches complete — have no single current state to be exactly one of, so Invariant 2, Invariant 7 and the whole replay story would need rewriting rather than extending. This atom is the single-active-state primitive and a fork-join pattern is a sibling, not a setting.

Non-goal 8 and Non-goal 9 together answer the question every deployer asks second: *can I change the flowchart?* Not for a live instance, ever. The declaration is a value the instance holds, so two instances created from one template are two independent copies and editing the template moves neither. Where a deployer needs a canonical template that new instances pick up, that is a definition registry holding the template and a calling system supplying it at [Instantiate] — this atom receives a declaration and never asks where it came from.

Non-goal 19 is the limit an auditor most often pushes against. *Show me every batch that never reached released* is not a question this atom answers: it knows what each instance declared and what each instance did, and it does not know which instances ought to exist or what a batch of a given type is expected to terminate in. The composing system drives that analysis with this atom's records as input.

---

## Edge cases

### Atomic writes

```
Atomic writes 1: A reader MUST NOT observe a history entry without the entry's next_sequence_number raise.
Atomic writes 2: A reader MUST NOT observe a history entry without the entry's current state change.
Atomic writes 3: An uncommitted crash MUST leave the instance as the call found the instance.
Atomic writes 4: The implementation MUST resolve a dangling transition.
Atomic writes 5: The store MUST NOT serve a read BEFORE the implementation resolves the dangling transition.
```

Term uncommitted crash: a crash BEFORE an admitted fire's commit lands.

Term dangling transition: an admitted fire's mutations standing partly applied once a crash has landed; the implementation resolves one by completing the mutations OR rolling the mutations back.

WHY:
Every admitted fire couples three durable mutations — the entry, the counter raise and the state change (Operation 27) — and a crash between any two breaks Invariant 6 or Invariant 7 in a way a later read cannot distinguish from a correct history. The obligation is all-or-none observability: a partly applied fire is not a transient condition to be repaired later, it must never be servable.

### Clock semantics

```
Clock semantics 4: A fired_at MUST NOT bound a later history entry's fired_at.
Deleted: Clock semantics 1. Capability requirement 2 owns it.
Deleted: Clock semantics 2. Capability requirement 3 owns it.
Deleted: Clock semantics 3. Capability requirement 4 owns it.
Deleted: Clock semantics 5. Non-goal 22 owns it.
```

WHY:
Clock semantics 4 is the rule that looks like a gap and is a commitment. Wall-time monotonicity across history entries is deliberately *not* enforced: under a skewing or resynchronized clock a later transition can legitimately carry an earlier `fired_at`, and an atom that refused it would reject correct history to protect an annotation. `sequence_number` is the order (Invariant 6.3, Operation 55), so nothing is lost. A backdated `fired_at` is accepted within the instance's own lifetime — documenting a transition recognized late is valid — and the only temporal bounds are the two that are structural: not after `now`, and not before the instance existed (Operation 19, Operation 20).

### Concurrency

```
Concurrency 1: The implementation MUST serialize two [Fire] calls against one instance.
Concurrency 2: A serialized [Fire] MUST read the current state the prior [Fire] left.
```

WHY:
Unlike [Selective Disclosure](./selective-disclosure.md), whose concurrent records contend over nothing, two fires against one instance contend over the current state itself — the second call's matched transition depends on where the first left the instance. So the second may succeed, may answer `invalid-transition`, or may answer `terminal`, and which of the three is a fact about the declaration rather than a race. Serialization is what makes the outcome a fact at all.

### String policy

```
String 1: The atom MUST compare a string input byte-exactly.
String 2: The atom MUST NOT trim a string input.
String 3: The atom MUST NOT normalize a string input.
String 4: The atom MUST NOT case-fold a string input.
String 5: The atom MUST read a whitespace-only string input as blank.
String 6: The atom MUST read an absent string input as blank.
String 7: The deployment MUST canonicalize an opaque reference.
```

Term string input: `instance_id`, `action`, `actor_ref`, `subject_ref`, a state name, a guard OR a filter's value — every caller-supplied string this atom accepts.

Term blank: a value that is absent, empty, or carries only whitespace — what every presence check in this atom refuses; a blank argument NOT EXISTS.

WHY:
Byte-exactness reaches further here than in most atoms, because state names and action names are caller-supplied strings that the declaration and every later [Fire] must agree on. A declaration naming `Tested` and a fire naming `tested` are two different tokens, the match fails, and the answer is `invalid-transition` — correct, and mystifying to a caller who believes they are the same state. Canonicalization is the deployment's (String 7).

NOTE: watch host obligations — this atom sets no maximum length on a string input, where [Duplicate Prevention](./duplicate-prevention.md) declares a cap and [Provenance](./provenance.md) obliges the deployment to set one. Three postures, and the *host obligations* docket row carries the count — a watch flag states the pressure, never a census nothing reads.

---

## Composition notes

```
Composition note 1: A deployment MUST declare which composing patterns the deployment wired in.
Composition note 2: A composing pattern MUST own a guard's evaluation.
Composition note 3: A composing pattern asserting guard_satisfied MUST own the evidence.
Composition note 4: A composing pattern MUST own the authorization of a call.
Composition note 5: A composing pattern MUST own the attestation binding an actor_ref.
Composition note 6: A composing pattern MUST own the tamper seal over a transition history.
Composition note 7: A composing pattern MUST own the retention of the workflow store.
Composition note 8: A composing pattern MUST own an idempotency key.
Composition note 9: A composing pattern MUST own a declaration template.
Composition note 10: A composing pattern reading the workflow store MUST NOT write to the workflow store.
```

WHY:
[Execute Gated Workflow](../compositions/execute-gated-workflow.md) (`grounded` 2026-06-04) is the composition this atom exists inside, and it is where the guard evaluation this atom refuses re-converges: it reads a bound [Approval Step](./approval-step.md)'s state and asserts `guard_satisfied` only where that step stands approved (Composition note 2, Composition note 3). The wiring is State Machine plus Approval Step plus [Permissions](./permissions.md) plus Assignment plus an [Audit Trail](../compositions/audit-trail.md) substrate, and the emergent guarantee is one neither constituent holds alone — a transition that fired carries both the declared-machine proof and the approval evidence behind its gate.

[Approval Step](./approval-step.md) is the fixed-state sibling and the clearest way to see what this atom trades away: its states are known to an evaluator who has read only the spec, and this atom's are known only to one who has read the instance. [Actor Identity](./actor-identity.md) makes `actor_ref` survive an authorship challenge under 21 CFR Part 11 and SOX (Sarbanes-Oxley Act) §404; [Tamper Evidence](./tamper-evidence.md) seals the history for court admissibility; [Retention Window](./retention-window.md) bounds how long instances are kept under GDPR (General Data Protection Regulation) Article 17, HIPAA (Health Insurance Portability and Accountability Act) §164.530(j) and FRCP (Federal Rules of Civil Procedure) Rule 37(e); [Audit Trail](../compositions/audit-trail.md) is the regulated-evidence layer each admitted fire lands in.

[Event Log](./event-log.md) is the structural cousin this atom deliberately does not name as a constituent: the transition history is append-only and totally ordered by a sequence number with best-effort wall time, which is an event log's shape, and the load-bearing concept here is the validity gate an event log has no notion of. Where a deployment wants both, that layering belongs to Execute Gated Workflow.

---

## Terms

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is* and its **Kind**.

### Vocabulary

Term actors: the atom; the host; the transition; the implementation; the deployment; a composing pattern; a business caller; a caller; a guard; an auditor; a regulator; an inspector; an investigator; the store; an instance; a history entry; a declaration; a declared transition; a matched transition; a guarded declared transition; an unguarded declared transition; an addressed action; a writing action; a reading action; a refused action; an ordering rule; an action; a query; a filter; a range filter; a string filter; a replay; a rejection; a crash; a reader; a state name; a string input; an opaque reference; the store instance's instance count; the instance's history entry count; the instance's admitted fire count.

Term records: `instance` — one workflow instance, carrying `instance_id`, a declaration, a current state, a transition history, `next_sequence_number` and, where supplied, `subject_ref` and `instance_metadata`. `history entry` — one recorded transition, carrying `transition_id`, `sequence_number`, `from_state`, `to_state`, `action`, `fired_at` and, where supplied, `actor_ref` and `guard_satisfied`.

Term record verbs: identify, allocate, change, carry, stand, answer, record, append, set, take, raise, commit, leave, own, match, normalize, reorder, interpret, confirm, admit, offer, evaluate, assert, fire, replay, reach, rest, share, precede, follow, exceed, compare, trim, case-fold, refuse, write, read, find, reconstruct, observe, resolve, complete, serve, serialize, shrink, fall, equal, bound, nest, version, decide, compose, declare, wire, supply, remove, sort, route, name, detect, bind, capture, choose, count, survive, canonicalize.

Term value sets: instantiate answers instance_id and refuses invalid-declaration | invalid-request | storage-failure. fire answers the matched transition's to_state and refuses invalid-request | not-known | terminal | invalid-transition | guard-not-satisfied | storage-failure. current answers the instance's current state and refuses invalid-request | not-known. history answers the matching history entries and refuses invalid-request | not-known | invalid-query. read_declaration answers the instance's declaration and refuses invalid-request | not-known.

Term bounds: empty.

Term cadences: empty.

Term qualifiers: `migrated` — rewritten in GRACE lang v0.40 (2026-09-12).

Term terms: `instance`, `instance_id`, `history entry`, `transition_id`, `subject_ref`, `instance_metadata`, `store instance`, `seam`, `transition`, `declared transition`, `declaration`, `states`, `initial state`, `terminal states`, `well-formed declaration`, `now`, `business caller`, `addressed action`, `writing action`, `reading action`, `current state`, `next_sequence_number`, `sequence_number`, `fired_at`, `instantiated_at`, `resolved fired_at`, `resolved instantiated_at`, `actor_ref`, `guard`, `guard_satisfied`, `matched transition`, `filter axes`, `admitted instantiate`, `admitted fire`, `admitted history`, `string input`, `blank`, `uncommitted crash`, `dangling transition`.

#### Instantiate

The behavior that validates a caller-supplied [Declaration] and creates a new workflow instance in its [Initial State], assigning a fresh [Instance Id], recording [Instance Metadata], [Actor Ref], and [Instantiated At], and starting an empty [Transition History]. Rejected [Invalid Declaration] for any declaration defect, [Invalid Request] for a bad [Actor Ref] or [Instantiated At], or [Storage Failure].

Kind: Operation

#### Fire

The behavior that advances an instance along a declared transition: it looks up the unique transition matching the current state and the supplied [Action], gates on [Guard] / [Guard Satisfied], appends one immutable history entry, and sets [Current State] to the transition's [To State]. Rejected [Not Known], [Terminal], [Invalid Transition], [Guard Not Satisfied], [Invalid Request], or [Storage Failure].

Kind: Operation

#### Current

The read-only query returning an instance's [Current State] name. Rejected [Not Known] or [Invalid Request].

Kind: Operation

#### History

The read-only query returning an instance's [Transition History] in [Sequence Number] ascending order, filterable by [Transition Id], [Sequence Number], [From State], [To State], [Action], [Actor Ref], or a [Fired At] range. Rejected [Not Known], [Invalid Query], or [Invalid Request].

Kind: Operation

#### Read Declaration

The read-only query returning the instance's immutable [Declaration] exactly as supplied at [Instantiate]. Rejected [Not Known] or [Invalid Request].

Kind: Operation

#### Instance Id

The opaque, immutable, system-generated identity of a workflow instance — assigned on [Instantiate], never reused, byte-order sortable for deterministic [History] ordering. It is the instance's identity; the [Declaration], [Current State], and [Transition History] are properties.

Kind:     Field
Field of: the workflow instance
Projects: instance_id

#### Subject Ref

The optional opaque reference to the entity whose lifecycle the workflow governs (a batch id, document id, work item id). Set on [Instantiate], immutable; the atom does not validate it, and its absence is valid.

Kind:     Field
Field of: the workflow instance
Projects: subject_ref

#### Instance Metadata

The optional opaque deployment-context payload supplied at [Instantiate], immutable; recorded as an auditable field, never interpreted.

Kind:     Field
Field of: the workflow instance
Projects: instance_metadata

#### Current State

The instance's current state — a member of the declared [States] (Invariant 2). Set to [Initial State] on [Instantiate]; updated to the fired transition's [To State] on each [Fire]. Always replay-derivable from the [Transition History] (Invariant 7).

Kind:     Field
Field of: the workflow instance
Projects: current_state

#### Transition History

The ordered, append-only sequence of transition history entries for an instance (Invariant 5). Begins empty; each [Fire] appends exactly one entry; never shrinks; total-ordered by [Sequence Number] (Invariant 6).

Kind:     Field
Field of: the workflow instance
Projects: transition_history

#### Next Sequence Number

The [Sequence Number] the next [Fire] will assign. Begins at 1; increments by one per successful [Fire]. Persistent instance state that must survive restarts, or Invariant 6 breaks.

Kind:     Field
Field of: the workflow instance
Projects: next_sequence_number

#### Declaration

The immutable map supplied at [Instantiate] that governs an instance — its [States], [Transitions], [Initial State], and [Terminal States]. Every enforcement decision derives from it; it never changes (Invariant 1) and is returned verbatim by [Read Declaration].

Kind:     Field
Field of: the workflow instance
Projects: declaration

#### Instantiated At

The wall-time the instance was created, stamped at [Instantiate] (or caller-supplied; not in the future). The lower bound for every [Fired At] — a transition cannot predate instantiation.

Kind:     Field
Field of: the workflow instance
Projects: instantiated_at

#### States

The non-empty set of named states in a [Declaration]. Each name is non-whitespace and unique within the declaration; [Current State], [Initial State], [From State], and [To State] are all drawn from it.

Kind:     Field
Field of: the declaration
Projects: states

#### Transitions

The set of declared transitions in a [Declaration], each a `{from_state, action, to_state, guard?}` tuple. At most one transition per `(from_state, action)` pair (determinism); none may originate from a [Terminal States] member.

Kind:     Field
Field of: the declaration
Projects: transitions

#### Initial State

The [Declaration]'s starting state — a member of [States], never a [Terminal States] member. It is the instance's [Current State] at [Instantiate] and the replay origin (Invariant 7).

Kind:     Field
Field of: the declaration
Projects: initial_state

#### Terminal States

The subset of [States] that is absorbing (Invariant 4): once [Current State] is one of them, no [Fire] succeeds. No declared transition may originate from one (enforced at [Instantiate]).

Kind:     Field
Field of: the declaration
Projects: terminal_states

#### From State

The state a declared transition (and the history entry it produces) departs from — a member of [States]. On a [Fire], it must equal the instance's [Current State].

Kind:     Field
Field of: a declared transition
Projects: from_state

#### To State

The state a declared transition (and the history entry it produces) arrives at — a member of [States]. On success it becomes the instance's new [Current State] and the returned `new_state`.

Kind:     Field
Field of: a declared transition
Projects: to_state

#### Action

The named trigger of a declared transition — a non-whitespace string. Supplied on [Fire] to select the unique transition from the [Current State]; recorded on the history entry.

Kind:     Field
Field of: a declared transition
Projects: action

#### Guard

The optional opaque label on a declared transition naming a condition the caller must assert satisfied before the transition fires. The atom gates on it but never evaluates the predicate (Invariant 8); guard evaluation is the caller's obligation.

Kind:     Field
Field of: a declared transition
Projects: guard

#### Transition Id

The opaque, immutable, system-generated identity of a transition history entry — assigned by [Fire], never reused within the instance.

Kind:     Field
Field of: the history entry
Projects: transition_id

#### Sequence Number

The strictly increasing integer assigned to a history entry from [Next Sequence Number] at [Fire]. The clock-independent total-order source for the [Transition History] (Invariant 6); [Fired At] is not.

Kind:     Field
Field of: the history entry
Projects: sequence_number

#### Fired At

The best-effort wall-time a transition was recorded, stamped at [Fire] (or caller-supplied; not in the future; ≥ [Instantiated At]). Not required to be monotonic across entries — [Sequence Number] is the order source.

Kind:     Field
Field of: the history entry
Projects: fired_at

#### Actor Ref

The optional opaque reference to the actor who fired a transition, recorded on the history entry (and on the genesis at [Instantiate]). If supplied, non-whitespace; its presence is deployment policy, not an atom mandate (Invariant 9).

Kind:     Field
Field of: the history entry
Projects: actor_ref

#### Guard Satisfied

The caller-asserted flag that a guarded transition's [Guard] condition is met — a [Fire] on a guarded transition fires only if it is `true`, and the history entry then records `guard_satisfied: true` (Invariant 8). Absent for unguarded transitions.

Kind:     Field
Field of: the history entry
Projects: guard_satisfied

#### Invalid Declaration

The rejection [Instantiate] returns for any declaration defect — an empty or duplicate-named [States] set, an [Initial State] that is missing or in [Terminal States], a transition referencing an undeclared state or leaving a terminal state, a duplicate `(from_state, action)` pair, or a blank [Action] or [Guard].

Kind:      Member
Member of: the Instantiate rejection
Role:      Outcome
Projects:  invalid-declaration

#### Invalid Request

The rejection an action returns for a malformed argument — a null or whitespace-only [Instance Id] or [Action], a bad [Actor Ref], or an [Instantiated At] / [Fired At] that is in the future or (for [Fired At]) before [Instantiated At].

Kind:      Member
Member of: the action rejection
Role:      Outcome
Projects:  invalid-request

#### Storage Failure

The rejection any write action returns when the store write fails after all preconditions pass; guarantees no partial record and an unchanged [Current State] / [Next Sequence Number] (Invariant 10).

Kind:      Member
Member of: the action rejection
Role:      Outcome
Projects:  storage-failure

#### Not Known

The rejection [Fire], [Current], [History], or [Read Declaration] returns when the [Instance Id] references no instance in the store.

Kind:      Member
Member of: the action rejection
Role:      Outcome
Projects:  not-known

#### Terminal

The rejection [Fire] returns when the instance's [Current State] is a [Terminal States] member — terminal states are absorbing (Invariant 4).

Kind:      Member
Member of: the Fire rejection
Role:      Outcome
Projects:  terminal

#### Invalid Transition

The rejection [Fire] returns when no declared transition matches the [Current State] and the supplied [Action] — only declared transitions fire (Invariant 3).

Kind:      Member
Member of: the Fire rejection
Role:      Outcome
Projects:  invalid-transition

#### Guard Not Satisfied

The rejection [Fire] returns when the matched transition carries a [Guard] but the caller did not assert [Guard Satisfied] = `true` (Invariant 8).

Kind:      Member
Member of: the Fire rejection
Role:      Outcome
Projects:  guard-not-satisfied

#### Invalid Query

The rejection [History] returns for a malformed filter — a null or whitespace-only [Transition Id], [From State], [To State], [Action], or [Actor Ref]; a reversed [Sequence Number] or [Fired At] range; or an unrecognized filter key.

Kind:      Member
Member of: the History rejection
Role:      Outcome
Projects:  invalid-query

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a [Term] marker to its term entry heading above (kramdown
     auto-generates the heading anchors on GitHub Pages). Standard CommonMark /
     kramdown; no plugin required. -->

[Instantiate]: #instantiate
[Fire]: #fire
[Current]: #current
[History]: #history
[Read Declaration]: #read-declaration
[Instance Id]: #instance-id
[Subject Ref]: #subject-ref
[Instance Metadata]: #instance-metadata
[Current State]: #current-state
[Transition History]: #transition-history
[Next Sequence Number]: #next-sequence-number
[Declaration]: #declaration
[Instantiated At]: #instantiated-at
[States]: #states
[Transitions]: #transitions
[Initial State]: #initial-state
[Terminal States]: #terminal-states
[From State]: #from-state
[To State]: #to-state
[Action]: #action
[Guard]: #guard
[Transition Id]: #transition-id
[Sequence Number]: #sequence-number
[Fired At]: #fired-at
[Actor Ref]: #actor-ref
[Guard Satisfied]: #guard-satisfied
[Invalid Declaration]: #invalid-declaration
[Invalid Request]: #invalid-request
[Storage Failure]: #storage-failure
[Not Known]: #not-known
[Terminal]: #terminal
[Invalid Transition]: #invalid-transition
[Guard Not Satisfied]: #guard-not-satisfied
[Invalid Query]: #invalid-query

---

## Standards references

- **FDA 21 CFR Part 11 (Electronic Records; Electronic Signatures)** — for FDA-regulated contexts: each declared state transition constitutes a regulated electronic record; the transition history is the audit trail that Part 11 §11.50 (attributability) and Part 11 §11.70 (record linking to prevent removal, substitution, or falsification) require. Composition with [Actor Identity](./actor-identity.md) provides the §11.50 attributability; composition with [Tamper Evidence](./tamper-evidence.md) provides the §11.70 non-falsifiability. Invariants 3 (only-declared-transitions), 5 (history append-only and complete), and 7 (replay determinism) are the atom-level guarantees the regulated record depends on.
- **ISO 9001:2015 §8.5.1 (Control of production and service provision)** — requires that production and service provision activities be controlled by documented procedures, including controlled transitions at defined points in the process lifecycle. A State Machine instance governing a production process is the documented process record §8.5.1 anticipates; the declaration is the procedure map; the transition history is the per-instance proof of execution.
- **BPMN 2.0 (Business Process Model and Notation 2.0 — an international standard for modeling business processes, published by the Object Management Group)** — this atom is the primitive behind a BPMN state diagram. A BPMN process model's states and sequence flows map directly to this atom's [States] and [Transitions]; a BPMN lane actor maps to an [Actor Ref] on [Fire] calls; a BPMN gateway condition maps to a [Guard] label on a declared transition.
- **HL7 FHIR Task resource** — the HL7 FHIR Task resource uses a declared workflow state machine (`Task.status`) with a defined lifecycle (`requested → accepted → in-progress → completed | failed | cancelled | rejected`). This atom is the general primitive the FHIR Task lifecycle is an instance of. A conforming FHIR Task implementation may derive its state enforcement from this atom's declared-transition model.
- **UML (Unified Modeling Language — the standard object-oriented modeling language published by the Object Management Group) statecharts and Harel statecharts** — the conceptual core of this atom. A UML statechart's states, transitions, events, and guards map directly to this atom's [States], [Transitions], [Action]s, and [Guard] labels. This atom is a flat (non-hierarchical, single-active-state) Mealy / Moore finite-state-machine (a finite state machine is a computational model with a finite set of states, a start state, a set of transitions, and one active state at a time) instance; Harel nesting and parallel regions are out of scope (see Edge cases).
- **SOX (Sarbanes-Oxley Act — US law on corporate financial reporting and records integrity) §404** — internal control over financial reporting. For financial process workflows (approval chains, journal entry processing, purchase order lifecycle), State Machine instances are the process-control records SOX auditors query to verify that required control steps occurred in the declared order.
- **HIPAA §164.530(j)** — documentation requirements for covered entities: policies and procedures must be documented. Workflow instances governing patient-care or administrative processes under HIPAA may use this atom's transition history as the documentation of process execution.

Guard evaluation, non-repudiable attribution, tamper-evidence, and retention are explicitly composing-pattern obligations, not this atom's own standards obligations.

---

## Status

`grounded on Final Critique 4 — 2026-06-04` — see the Ledger.

## Ledger

```
status: grounded on Final Critique 4 — 2026-06-04
formal: verified — state-machine.als + 1 twin, 2026-06-04
last gate: 2026-06-04 — Final Critique 4, fresh reader — clean

open: none
```

## Decisions

Directional changes only — the turns a future reader must know the pattern took, and why. Everything smaller lives in the commit that made it: `git log -- atoms/state-machine.md`.

- **2026-09-12 — Rewritten in GRACE lang v0.40; nothing but language changed.** *Chose:* the five actions as a signature block, Invariant 1 through 10 keeping their numbers, the declaration's ten well-formedness checks raised to a `Declaration 1 through 17` family of their own, every success effect conditioned on a declared `admitted instantiate`, `admitted fire` or `admitted history` (Hard invariant 16), [Fire]'s seven-step rejection precedence kept beside the rules as an eight-row case space with the ordering carried by `ONLY IF` guards rather than by a prose *rejection priority* line repeated in two sections, the six acceptance areas opened into `Check 1.1 through 8.2` with three `External check`s for what the store cannot answer, the Non-goals-and-edge-cases prose split into a `Non-goal 1 through 21` family and four edge-case families (`String`, `Clock semantics`, `Concurrency`, `Atomic writes`), the Composition notes prose raised to `Composition note 1 through 10`. *Over:* the prose spec. *Because:* the migration plan; `cites.py --into state-machine` found nothing in the corpus citing this atom by label. 78.8 KB → 67.0 KB.

- **2026-09-12 — The within-instance temporal bound is a precedence, not a `≥`.** *Chose:* `Operation 20` — *IF the resolved fired_at precedes the instance's instantiated_at THEN [Fire] MUST answer invalid-request*. *Over:* `IF fired_at EXCEEDS instantiated_at OR fired_at = instantiated_at`, the two-arm spelling the condition operator set forces on a `≥`. *Because:* that spelling is a watched class at five sites across two specs (council read 29), and this atom would have been the third. A bound that admits its own boundary is a *precedes* prohibition in one arm — the boundary case (a transition firing at the instant of instantiation) is legal, and one arm says so. The class may still earn an operator; it does not need this atom's vote.

- **2026-09-12 — Four propositions had two owners each.** *Chose:* `Invariant 2` owns exactly-one-current-state and the `State` family no longer restates it; `Operation 21` owns *one entry per admitted fire* and `Invariant 5` no longer does; `State 4` owns the history entry's field set and `Invariant 9` no longer does; `Invariant 8.2` owns *the atom does not evaluate a guard* and the `Non-goal` family no longer does. *Over:* keeping each pair for emphasis. *Because:* Authority 3. All four were found by `W-duplicate-proposition`, which is the check earning its keep on the largest atom migrated so far — 192 rules, where a reader cannot hold the whole surface at once and a duplicate is invisible by construction.

NOTE: End of State Machine.
