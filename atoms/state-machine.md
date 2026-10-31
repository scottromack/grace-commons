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

State Machine records a single named workflow — think of it as a token moving through a flowchart — where the flowchart (the set of valid states and the transitions between them) is declared by the system deploying it rather than fixed by the pattern itself.

When the workflow is created, the deployer provides the complete map: every state, every allowed move between states (each move is a named action, optionally gated by a condition the calling system must assert is satisfied), the starting state, and any states that are permanent endpoints. From that moment forward the map is frozen — it cannot be changed for this workflow.

State Machine then enforces three guarantees for the lifetime of the workflow: only declared moves are allowed (an undeclared move is refused); exactly one current state exists at all times; and every move that succeeds is recorded, in order, and never deleted by the pattern itself, with enough context to replay the full history and arrive at the current state.

These guarantees make the system useful for regulated processes (a pharmaceutical batch that must prove it moved only through the approved sequence of quality-control states) and for any process where you need an unambiguous, auditable record of what happened and in what order. State Machine is the general pattern; [Approval Step](./approval-step.md) is one specific kind of state machine with its states and rules fixed in advance, whose workflows do not need their own declaration.

*Also known as: a workflow instance, a process instance, a declared finite state machine.*

---

## Intent

<details markdown="block">
<summary>WHY</summary>

Many real-world processes move an entity through a defined sequence of states: a pharmaceutical batch advances from *sampled* through *tested* through *qualified* through *released*; a purchase order from *draft* through *submitted* through *approved* through *fulfilled*; a change request from *open* through *in-review* through *merged* through *deployed*. In each the valid transitions are known in advance, the order they fire in must be auditable, and the current state must be unambiguously knowable at any moment. The structure governing them is the same in all of them: a named entity, a finite declared set of states, a declared set of transitions, and a durable history of which fired and when.

The core problem is that different deployments need different state machines. A batch-release workflow is governed by 21 CFR (Code of Federal Regulations) Part 11 and ISO (International Organization for Standardization) 9001 clause 8.5.1. An HL7 (Health Level Seven) FHIR (Fast Healthcare Interoperability Resources) Task resource has its own lifecycle. A BPMN (Business Process Model and Notation) workflow varies by process type. Writing a separate atom for each is not feasible, and it is also not the right factoring: the commonality is declared-finite-state-machine *enforcement*, not the particular states. That is what this atom captures — the declaration is data supplied by the deployment, and the enforcement is the atom.

The atom is structurally distinct from two adjacent concepts, and both distinctions are load-bearing.

[Approval Step](./approval-step.md) is a *specific* state machine whose states, transitions and semantics are fixed at the atom level — an external evaluator knows them without reading any deployment configuration. This atom's machine is fixed at the *workflow* level, and an external evaluator must read the workflow's declaration to know what is valid. Specificity is the axis: Approval Step is specification-level, State Machine is workflow-level. Approval Step also carries approval-specific semantics — one named approver, submitter exclusivity on withdrawal, a required reason on rejection — that this atom carries none of. Both are freestanding, and they compose into [Execute Gated Workflow](../compositions/execute-gated-workflow.md), where a State Machine workflow governs the process lifecycle and Approval Step workflows govern the gates inside it.

[Event Log](./event-log.md) records what happened; this atom enforces what is allowed to happen and tracks the resulting state. The transition history here resembles an event log structurally — append-only, totally ordered by a sequence number, with wall time as a best-effort annotation — but an event log has no declared states, no declared transitions, no current state and no validity gate. This atom is freestanding, and none of its rules names Event Log; where the two meet is a composition's business.

The guard is where the atom's restraint is sharpest. A declared transition may carry a guard label, and the atom enforces that the caller *asserts* the guard satisfied before the transition fires — while evaluating nothing. The history records the assertion, not a verdict. A caller asserting a guard it never checked is violating the declared process and the atom will record the assertion faithfully, because the alternative is an atom that must understand every deployment's predicates, which is the absorption this factoring exists to prevent.

</details>

## Structure

### Identity model

```
Identity 1: The atom MUST identify a workflow by the instance id.
Identity 2: The atom MUST identify a history entry by the transition id.
Identity 3: The host MUST allocate an instance id at the seam.
Identity 4: The host MUST allocate a transition id at the seam.
Identity 5: The transition MUST NOT allocate an instance id.
Identity 6: The transition MUST NOT allocate a transition id.
Identity 7: The atom MUST NOT change an instance id.
Identity 8: The atom MUST NOT change a transition id.
Identity 9: Two workflows in one database instance MUST NOT share an instance id.
Identity 10: Two history entries in one workflow MUST NOT share a transition id.
Deleted: Identity 11. Execution Contract Logic confinement 10 owns it.
Deleted: Identity 12. Execution Contract Database 7 owns it.
Identity 13: The atom MUST NOT identify a workflow by the subject reference.
Identity 14: The atom MUST admit a second workflow carrying a recorded subject reference.
Identity 15: The atom MUST NOT confirm that a subject reference names a known subject.
Identity 16: The atom MUST NOT interpret an instance metadata.
```

Term workflow: one running workflow — one declaration, one current state and one transition history; the record this atom holds.

Term instance id: the opaque value naming one workflow — a [Workflow Id]; host-allocated at the seam.

Term history entry: one recorded transition on one workflow, carrying transition id, sequence number, from state, to state, action, firing instant and the actor reference and guard satisfied [Fire] recorded.

Term transition id: the opaque value naming one history entry — a [Transition Id]; host-allocated at the seam.

Term subject reference: the opaque reference naming the entity whose lifecycle the workflow governs — a [Subject Reference]; a property of the workflow, never the workflow's identity.

Term instance metadata: the opaque payload the caller supplies at [Instantiate] for deployment context — a [Workflow Metadata]; recorded where not blank, never interpreted.

Term database instance: one named database a call is routed to; instance id uniqueness ranges over one database instance.

Term seam: the atom's I/O (input and output) boundary; the host injects the clock reading, the instance id and the transition id here.

Term transition: the atom's evaluation of one call against the workflow records.

Term declared transition: one from state, action, to state and optional guard in the declaration — a move the workflow may make. Distinct from the transition above, which is the atom's evaluation of a call.

NOTE: watch the seam citation (Term seam, Term transition).

### State

```
State 1: EVERY workflow MUST carry instance id, a declaration, a current state, a transition history, next sequence number and an instantiation instant.
State 2: A workflow MAY carry subject reference.
State 3: A workflow MAY carry instance metadata.
State 4: EVERY history entry MUST carry transition id, sequence number, from state, to state, action and firing instant.
State 5: A history entry MAY carry actor reference.
State 6: The atom MUST NOT offer a workflow removal surface.
State 7: The atom MUST NOT offer a history entry removal surface.
State 8: The atom MUST NOT offer a history entry edit surface.
State 9: The atom MUST NOT offer a reorder surface.
State 10: The atom MUST NOT offer a transition out of a terminal state.
State 11: The atom MUST NOT offer an action that stands a workflow in two states.
State 15: A workflow MAY carry actor reference.
State 16: A history entry MAY carry guard satisfied.
Deleted: State 12. Invariant 10.1 and Execution Contract Database 4 own it.
Deleted: State 13. Invariant 10.2 and Execution Contract Database 4 own it.
Deleted: State 14. Execution Contract Database 3 owns it.
```

### Capability requirement

```
Capability requirement 1: The deployment MUST supply now at the seam.
Capability requirement 5: The deployment MUST supply the workflow records PER Execution Contract Database 1 through 7, Execution Contract Read 1 through 4, Execution Contract Refusal 1, Execution Contract Query 1 through 4, Execution Contract Input 1 and Execution Contract Conformance 9.
Capability requirement 6: The deployment MUST declare which composing patterns the deployment wired in.
Deleted: Capability requirement 2. Execution Contract Logic confinement 7 owns it.
Deleted: Capability requirement 3. Execution Contract Logic confinement 7 owns it.
Deleted: Capability requirement 4. Execution Contract Logic confinement 7 owns it.
```

NOTE: watch the deployment's composition note (Capability requirement 6).

### Operations

```
instantiate(declaration, optional subject_ref, optional actor_ref, optional instance_metadata, optional instantiated_at)
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
Deleted: Operation 1. Execution Contract Refusal 1 owns it.
Operation 2: IF the call carries actor reference AND actor reference EQUALS blank THEN a writing action MUST answer invalid-request.
Operation 3: IF now PRECEDES the resolved instantiation instant THEN [Instantiate] MUST answer invalid-request.
Deleted: Operation 62. Execution Contract Input 1 owns it.
Operation 65: IF the resolved instantiation instant is malformed THEN [Instantiate] MUST answer invalid-request (Execution Contract Input 1).
Operation 4: An admitted instantiate MUST record EXACTLY ONE workflow.
Operation 5: An admitted instantiate MUST stand the workflow in the initial state.
Operation 6: An admitted instantiate MUST set next sequence number to one.
Operation 7: An admitted instantiate MUST record an empty transition history.
Operation 8: An admitted instantiate MUST answer the instance id.
Operation 56: IF subject reference DOES NOT EQUAL blank THEN an admitted instantiate MUST record subject reference.
Operation 70: IF subject reference EQUALS blank THEN an admitted instantiate MUST NOT record subject reference.
Operation 59: IF instance metadata DOES NOT EQUAL blank THEN an admitted instantiate MUST record instance metadata.
Operation 71: IF instance metadata EQUALS blank THEN an admitted instantiate MUST NOT record instance metadata.
Operation 60: IF actor reference DOES NOT EQUAL blank THEN an admitted instantiate MUST record actor reference on the workflow.
Operation 67: An admitted instantiate MUST record the resolved instantiation instant.
Operation 72: An admitted instantiate MUST record on the workflow the instance id the host allocates (Identity 3).
Operation 74: An admitted instantiate MUST record the declaration.
Operation 9: IF instance id EQUALS blank THEN an addressed action MUST answer invalid-request.
Operation 10: IF action EQUALS blank THEN [Fire] MUST answer invalid-request.
Operation 11: IF the instance id names no workflow THEN an addressed action MUST answer not-known.
Deleted: Operation 12. Execution Contract Refusal 1 owns it.
Operation 13: IF the current state IS IN the terminal states THEN [Fire] MUST answer terminal.
Deleted: Operation 14. Execution Contract Refusal 1 owns it.
Operation 15: IF no declared transition matches the current state and action THEN [Fire] MUST answer invalid-transition.
Deleted: Operation 16. Execution Contract Refusal 1 owns it.
Operation 17: IF the matched transition carries a guard AND guard satisfied DOES NOT EQUAL true THEN [Fire] MUST answer guard-not-satisfied.
Deleted: Operation 18. Execution Contract Refusal 1 owns it.
Operation 19: IF now PRECEDES the resolved firing instant THEN [Fire] MUST answer invalid-request.
Operation 20: IF the resolved firing instant PRECEDES the workflow's instantiation instant THEN [Fire] MUST answer invalid-request.
Deleted: Operation 63. Execution Contract Input 1 owns it, among the firing checks (Term firing check).
Operation 66: IF the resolved firing instant is malformed THEN [Fire] MUST answer invalid-request (Execution Contract Input 1).
Operation 69: IF the call carries guard satisfied AND guard satisfied is malformed THEN [Fire] MUST answer invalid-request (Execution Contract Input 1).
Operation 64: [Fire] MUST answer invalid-request on a firing fault ONLY IF the call is a cleared fire.
Operation 21: An admitted fire MUST append EXACTLY ONE history entry.
Operation 22: An admitted fire MUST take the history entry's sequence number from next sequence number.
Operation 23: An admitted fire MUST raise next sequence number by one.
Operation 24: An admitted fire MUST set the history entry's from state to the current state the call found.
Operation 25: An admitted fire MUST set the history entry's to state to the matched transition's to state.
Operation 26: An admitted fire MUST stand the workflow in the matched transition's to state.
Deleted: Operation 27. Execution Contract Database 1 owns it.
Operation 28: An admitted fire MUST answer the matched transition's to state.
Operation 29: An admitted fire over a guarded transition MUST record guard satisfied on the history entry.
Operation 30: An admitted fire over an unguarded transition MUST NOT record guard satisfied on the history entry.
Operation 61: IF actor reference DOES NOT EQUAL blank THEN an admitted fire MUST record actor reference on the history entry.
Operation 68: An admitted fire MUST record action and the resolved firing instant on the history entry.
Operation 73: An admitted fire MUST record the transition id the host allocates on the history entry (Identity 4).
Operation 31: [Fire] MUST NOT evaluate a guard.
Deleted: Operation 32. Operation 15 and Declaration 10 own it.
Operation 33: IF the database refuses the write THEN a writing action MUST answer storage-failure.
Deleted: Operation 34. Execution Contract Refusal 1 owns it.
Operation 35: A refused action MUST leave the workflow as the call found the workflow.
Operation 36: A refused action MUST NOT append a history entry.
Operation 37: A refused action MUST NOT raise next sequence number.
Operation 38: [Current] MUST answer the workflow's current state.
Operation 39: An admitted history MUST answer the matching history entries in sequence number ascending order.
Operation 40: An admitted history MUST answer EVERY history entry matching the supplied filters.
Operation 41: An admitted history MUST NOT answer a history entry failing a supplied filter.
Operation 42: IF no history entry matches THEN an admitted history MUST answer an empty entry sequence.
Operation 57: IF the query is malformed THEN [History] MUST answer invalid-query.
Operation 43: IF a filter's axis IS NOT IN the filter axes THEN [History] MUST answer invalid-query.
Operation 44: IF a string filter's value EQUALS blank THEN [History] MUST answer invalid-query.
Operation 45: IF a sequence number range's start EXCEEDS the range's end THEN [History] MUST answer invalid-query.
Operation 58: IF a firing instant range's end PRECEDES the range's start THEN [History] MUST answer invalid-query.
Deleted: Operation 46. Execution Contract Refusal 1 owns it.
Operation 47: [Read Declaration] MUST answer the workflow's declaration.
Operation 48: [Read Declaration] MUST NOT normalize the declaration.
Operation 49: [Read Declaration] MUST NOT reorder the declaration.
Operation 50: A reading action MUST NOT write.
Deleted: Operation 51. Capability requirement 1 owns it.
Deleted: Operation 52. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 53. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 54. Execution Contract Logic confinement 3 owns it.
Operation 55: An ordering rule MUST NOT rest on firing instant.
```

NOTE: watch the integer range (Operation 45, Operation 58).

NOTE: watch the optional field no rule records (Operation 56, Operation 59, Operation 60, Operation 61).

NOTE: watch the blank optional input (Operation 56, Operation 59, Operation 60, Operation 61, Operation 70, Operation 71).

NOTE: watch the required input no rule records (Operation 67, Operation 68, Operation 74).

NOTE: open 2026-10-31-a — no action answers a workflow's subject reference, instance metadata, actor reference or instantiation instant (State 2, State 3, State 15, Operation 67).

Term now: the deployment's clock reading at the call, as Execution Contract Logic confinement 11 declares it.

Term addressed action: any action carrying an instance id — every action but [Instantiate].

Term writing action: [Instantiate] | [Fire] — the two actions that write.

Term reading action: [Current] | [History] | [Read Declaration] — the three that do not.

Term current state: the state the workflow stands in — a [Current State]; the initial state until a fire lands, and the latest history entry's to state after.

Term next sequence number: the counter [Fire] takes a sequence number from — a [Next Sequence Number]; begins at one and rises by one per append.

Term sequence number: the strictly increasing integer a history entry takes at append — a [Sequence Number]; the history's order source, and never taken from a clock.

Term firing instant: the instant a declared transition fired — a [Firing Instant]; a best-effort annotation, and never an order source.

Term instantiation instant: the instant a workflow was created — an [Instantiation Instant].

Term resolved firing instant: the firing instant the history entry carries — the supplied value, as Execution Contract Logic confinement 12 resolves it.

Term resolved instantiation instant: the instantiation instant the workflow carries — the supplied value, as Execution Contract Logic confinement 12 resolves it.

Term actor reference: the opaque reference naming who instantiated a workflow or fired a declared transition — an [Actor Reference]; optional, and recorded where not blank.

Term guard: the opaque label naming the condition a caller asserts before a declared transition fires — a [Guard].

Term guard satisfied: true | false — a [Guard Satisfied], the caller's assertion that a guard holds; an assertion, never a verdict.

Term matched transition: the one declared transition whose from state is the current state and whose action is the call's action (Declaration 13).

Term cleared fire: a [Fire] call Operation 11, Operation 13, Operation 15 and Operation 17 all admit.

Term firing check: Operation 2, Operation 19, Operation 20, Operation 66 and Operation 69 — every check [Fire] makes on a cleared fire.

Term firing fault: a firing check the call fails.

Term filter axes: transition id | sequence number | from state | to state | action | actor reference | firing instant — the seven axes [History] accepts, and no others, a filter on sequence number or firing instant carrying a range.

Term admitted instantiate: an [Instantiate] call the action admits (Execution Contract Read 4).

Term admitted fire: a [Fire] call the action admits (Execution Contract Read 4).

Term admitted history: a [History] call whose instance id names a workflow and whose every filter axis and filter value the guards admit.

| # | Condition | [Fire] answers | Owner |
|---|---|---|---|
| 1 | instance id or action is blank | invalid-request | Operation 9, Operation 10 |
| 2 | both are well-formed, the instance id names no workflow | not-known | Operation 11 |
| 3 | the workflow exists, the current state is terminal | terminal | Operation 13 |
| 4 | the current state is not terminal, no declared transition matches | invalid-transition | Operation 15 |
| 5 | a declared transition matches, it carries a guard, guard satisfied is not true | guard-not-satisfied | Operation 17 |
| 6 | the call is a cleared fire, a firing check fails | invalid-request | Operation 64; Operation 2, Operation 19, Operation 20, Operation 66, Operation 69 |
| 7 | every precondition passes, the database refuses the write | storage-failure | Operation 33 |
| 8 | every precondition passes, the database accepts the write | new_state | Operation 28 |

Where two rows hold at once, the earlier row answers: the rows follow the refuses line (Execution Contract Refusal 1), and row 6 answers only on a cleared fire (Operation 64).

NOTE: watch condition negation — invalid-request occupies two rows of one precedence chain (row 1 and row 6), so the answer alone does not say which guard refused. Audit Trail's 2026-08-30-a open line is the same shape with a worse consequence, its row 6 landing after a commitment.

### Invariants

- **Invariant 1 — Declaration immutability.**
  ```
  Invariant 1.1: A recorded declaration's field MUST NOT change.
  Invariant 1.2: [Read Declaration] MUST answer the declaration as [Instantiate] took the declaration.
  ```
- **Invariant 2 — Exactly one current state.**
  ```
  Invariant 2.1: EVERY workflow MUST stand in EXACTLY ONE member of the workflow's states.
  ```
- **Invariant 3 — Only declared transitions fire.**
  ```
  Invariant 3.1: EVERY history entry MUST match EXACTLY ONE declared transition in the workflow's declaration.
  Invariant 3.2: Two declared transitions in one declaration MUST NOT share one from state and one action.
  ```
- **Invariant 4 — Terminal absorption.**
  ```
  Invariant 4.1: A workflow whose current state IS IN the terminal states MUST NOT leave the terminal state.
  Invariant 4.2: A declared transition's from state MUST NOT stand in the terminal states.
  ```
- **Invariant 5 — History append-only and complete.**
  ```
  Invariant 5.1: A history entry MUST NOT change.
  Invariant 5.2: A workflow's history entry count MUST equal the workflow's admitted fire count.
  ```
- **Invariant 6 — History total order.**
  ```
  Invariant 6.1: Two history entries in one workflow MUST NOT share a sequence number.
  Invariant 6.2: A workflow's sequence numbers MUST stand from one to the workflow's history entry count.
  Invariant 6.3: A workflow's history order MUST rest on sequence number alone.
  ```
- **Invariant 7 — Replay determinism.**
  ```
  Invariant 7.1: A workflow carrying a history entry MUST stand in the highest sequence number entry's to state.
  Invariant 7.2: A workflow carrying no history entry MUST stand in the initial state.
  Invariant 7.3: A replay of a workflow's history from the initial state in sequence number ascending order MUST reach the workflow's current state.
  ```
- **Invariant 8 — Guard gating without evaluation.**
  ```
  Invariant 8.1: A guarded declared transition MUST fire ONLY IF guard satisfied EQUALS true.
  Invariant 8.2: The atom MUST NOT evaluate a guard's condition.
  Invariant 8.3: A guarded declared transition's history entry MUST record the caller's assertion.
  ```
- **Invariant 9 — Transition attribution completeness.**
  ```
  Invariant 9.1: A recorded actor reference MUST stand non-blank.
  ```
- **Invariant 10 — Record durability.**
  ```
  Invariant 10.1: The atom MUST NOT remove a workflow from the database.
  Invariant 10.2: The atom MUST NOT remove a history entry from a workflow.
  Deleted: Invariant 10.3. Execution Contract Database 1 owns it.
  ```

### The declaration

```
Deleted: Declaration 1. Declaration 5 and Declaration 8 own it.
Declaration 2: The atom MUST NOT change a recorded declaration.
Declaration 3: The atom MUST NOT offer a declaration edit surface.
Declaration 4: EVERY enforcement decision MUST rest on the workflow's declaration.
Declaration 5: IF states carries no member THEN [Instantiate] MUST answer invalid-declaration.
Declaration 6: IF a state name EQUALS blank THEN [Instantiate] MUST answer invalid-declaration.
Declaration 7: IF two state names in states match THEN [Instantiate] MUST answer invalid-declaration.
Declaration 8: IF the initial state IS NOT IN states THEN [Instantiate] MUST answer invalid-declaration.
Declaration 9: IF the initial state IS IN the terminal states THEN [Instantiate] MUST answer invalid-declaration.
Declaration 10: IF a declared transition's from state IS NOT IN states THEN [Instantiate] MUST answer invalid-declaration.
Declaration 11: IF a declared transition's to state IS NOT IN states THEN [Instantiate] MUST answer invalid-declaration.
Declaration 12: IF a declared transition's from state IS IN the terminal states THEN [Instantiate] MUST answer invalid-declaration.
Declaration 13: IF two declared transitions share one from state and one action THEN [Instantiate] MUST answer invalid-declaration.
Declaration 14: IF a declared transition's action EQUALS blank THEN [Instantiate] MUST answer invalid-declaration.
Declaration 15: IF a declared transition carries a guard AND the guard EQUALS blank THEN [Instantiate] MUST answer invalid-declaration.
Declaration 18: IF a terminal state IS NOT IN states THEN [Instantiate] MUST answer invalid-declaration.
Declaration 19: IF the declaration is malformed THEN [Instantiate] MUST answer invalid-declaration (Execution Contract Input 1).
Declaration 16: The terminal states MAY carry no member.
Declaration 17: A declared transition MAY carry no guard.
```

Term declaration: the immutable map governing one workflow — a [Declaration]; carries states, the declared transitions, the initial state and the terminal states; the declared transitions or the terminal states the map leaves blank are none.

Term states: the named states one declaration admits — a [States]; every state name the workflow may stand in.

Term initial state: the state a workflow stands in at [Instantiate] — an [Initial State]; a member of states and never a terminal state.

Term terminal states: the absorbing members of states — a [Terminal States]; possibly none.

Term well-formed declaration: a declaration Declaration 5 through 15, Declaration 18 and Declaration 19 all admit.

---

## Examples

### Pharmaceutical batch qualification

A quality system instantiates a batch-release workflow. The declaration names `states: [sampled, tested, qualified, released, rejected]`, `initial state: sampled`, `terminal states: [released, rejected]`, and five declared transitions — `sampled --test--> tested`, `tested --qualify[qa_signoff]--> qualified`, `tested --reject--> rejected`, `qualified --release[qa_signoff]--> released`, `qualified --reject--> rejected`. `instantiate(declaration, actor_ref: "qa-system", subject_ref: "batch-x91")` → `wf_01HQ…`, standing in `sampled` with `next_sequence_number: 1` (Operation 4 through 8).

`fire("wf_01HQ…", "test", actor_ref: "lab-tech-r.chen")` → `tested`. One history entry lands at `sequence_number: 1` carrying `from_state: sampled`, `to_state: tested` (Operation 21 through 26, Operation 28).

`fire("wf_01HQ…", "qualify", actor_ref: "qa-lead-m.ross")` → guard-not-satisfied. The declared transition carries the `qa_signoff` guard and the call asserted nothing (Operation 17). The same call with `guard_satisfied: true` → `qualified`, and the entry records the assertion (Operation 29).

`fire("wf_01HQ…", "release", guard_satisfied: true, actor_ref: "qa-lead-m.ross")` → `released`. The workflow now stands in a terminal state.

### The audit question

An inspector asks whether the batch moved only through the approved sequence. `read_declaration("wf_01HQ…")` answers the map as supplied, unchanged since instantiation (Invariant 1.2). `history("wf_01HQ…")` answers three entries in sequence number order. Every entry's from state, action and to state triple appears in the declaration (Invariant 3.1), and replaying them from `sampled` arrives at `released`, which is what `current("wf_01HQ…")` answers (Invariant 7.3). The declaration bounds what *could* have happened and the history says what *did*; neither alone answers the inspector.

### Rejection paths

`fire("wf_01HQ…", "test")` against the released workflow → terminal. Not invalid-transition, even though no `test` edge leaves `released` — an absorbed workflow refuses every action, and saying so sends the caller to the right problem (Operation 13, Execution Contract Refusal 1).

`fire("wf_01HQ…", "expedite")` against a live workflow in `tested` → invalid-transition. No declared transition matches, and there is no wildcard (Operation 15, Declaration 10).

`fire("wf_99999", "test")` → not-known. `fire("", "test")` → invalid-request, answered ahead of not-known (Operation 9, Execution Contract Refusal 1).

`instantiate(declaration)` where two declared transitions both leave `tested` on `qualify` → invalid-declaration. The determinism constraint refuses the ambiguity at birth rather than inventing a tiebreak at fire time (Declaration 13).

`instantiate(declaration)` where `initial state: released` and `released` is terminal → invalid-declaration. A workflow born absorbed accepts nothing (Declaration 9).

`instantiate(declaration)` carrying an edge out of `released` → invalid-declaration (Declaration 12).

`fire("wf_01HQ…", "test", fired_at: "2020-01-01")` against a workflow instantiated in 2026 and standing in `sampled` → invalid-request. A transition cannot fire before the workflow existed (Operation 20). Against the released workflow the same call → terminal, since a firing fault answers only on a cleared fire (Operation 64).

### Multi-workflow independence

Two batches run the same declaration as two workflows. Firing `test` on one moves one current state; the other is untouched, carries its own history and its own next sequence number. The declaration is a value each workflow holds, not a shared object (Non-goal 8).

### Regulated adversarial scenarios

- **Regulator audit.** A US Food and Drug Administration (FDA) inspector auditing under 21 CFR Part 11 and ISO 9001 clause 8.5.1 asks the system to prove the batch moved only through approved states. Check 2.1 and Check 1.1 are the structural answer: every history entry matches a declared transition, and the declaration is the one supplied at instantiation. What the atom cannot answer is whether the `qa_signoff` guard was truly satisfied — `guard_satisfied: true` attests an assertion (Invariant 8.3), and the evidence lives in the composing [Approval Step](./approval-step.md) record.
- **Disputed transition.** An external party claims the workflow skipped a required state. The history is gap-free by sequence number (Invariant 6.2) and replays to the current state (Invariant 7.3), so a skipped state would have to appear as a declared transition that jumps it — which the declaration either names or does not. The claim resolves provably, against the declaration.
- **Breach investigation.** An investigator reconstructing an anomaly window filters the history by firing instant range and finds the entries generously bracketed. Because sequence number is dense and is the order source (Invariant 6.2, Operation 55), the investigator confirms the window's completeness against an unfiltered read rather than trusting the wall-time filter — a clock-skewed entry can fall outside the bracket and cannot fall out of the sequence.

---

## Generation acceptance

This atom's acceptance is provable: an external auditor clears it from the workflow records, with their committed versions (Execution Contract Generation acceptance 1), and the declaration.

### Conformance checks

```
Check 1.1: An auditor MUST find EVERY workflow's declaration unchanged across EVERY committed version of the workflow (Invariant 1.1; Execution Contract Generation acceptance 1).
Deleted: Check 1.2. Check 1.1 owns it.
Check 2.1: An auditor MUST find EVERY history entry's from state, action and to state standing as a declared transition in the workflow's declaration (Invariant 3.1).
Check 2.2: An auditor MUST find no two declared transitions in one declaration sharing one from state and one action (Invariant 3.2).
Check 3.1: An auditor MUST find EVERY workflow whose current state EQUALS EXACTLY ONE member of the workflow's states (Invariant 2.1).
Check 4.1: An auditor MUST find no history entry following a history entry whose to state IS IN the workflow's terminal states (Invariant 4.1).
Check 4.2: An auditor MUST find no declared transition whose from state IS IN the terminal states (Invariant 4.2).
Check 5.1: An auditor MUST find a workflow's sequence numbers standing from one to the workflow's history entry count (Invariant 6.2).
Check 5.2: An auditor MUST reconstruct a workflow's history order from sequence number alone (Invariant 6.3).
Check 5.3: An auditor MUST find EVERY history entry's fields unchanged across EVERY committed version carrying the history entry (Invariant 5.1; Execution Contract Generation acceptance 1).
Check 6.1: An auditor MUST reach the workflow's current state by replaying the workflow's history from the initial state (Invariant 7.3).
Check 7.1: An auditor MUST find guard satisfied recorded as true on EVERY guarded declared transition's history entry (Invariant 8.1, Invariant 8.3).
Check 7.2: An auditor MUST find no guard satisfied recorded on an unguarded declared transition's history entry (Operation 30).
Check 8.1: An auditor MUST find transition id, sequence number, from state, to state, action and firing instant on EVERY history entry (State 4).
Check 8.2: An auditor MUST find EVERY recorded actor reference non-blank (Invariant 9.1).
Check 8.3: An auditor MUST find no history entry whose firing instant PRECEDES the workflow's instantiation instant (Operation 20).
```

NOTE: EVERY check names the rule the check tests.

Term committed version: a record as it stood at the commit that wrote it, as Execution Contract Generation acceptance 1 declares it.

### External checks

```
External check 1: A deployment needing a guard's condition confirmed MUST read the composing pattern that evaluates the guard (Invariant 8.2).
External check 2: A deployment needing a workflow's history entry count matched against the workflow's admitted fire count MUST capture the fire answers (Invariant 5.2).
External check 3: A deployment needing an actor reference bound to an actor MUST read the composing Actor Identity attestation (Non-goal 11).
Deleted: External check 4. Execution Contract Conformance 9 owns it.
```

## Non-goals

```
Non-goal 1: A deployment needing a guard evaluated MUST compose the evaluating pattern.
Non-goal 2: A deployment gating a declared transition on an approval MUST compose Approval Step.
Non-goal 3: The atom MUST NOT stand a workflow in two states at once.
Non-goal 4: The atom MUST NOT offer a fork declared transition.
Non-goal 5: The atom MUST NOT offer a join declared transition.
Non-goal 6: The atom MUST NOT nest a state inside a state.
Non-goal 7: A deployment needing a nested state MUST name the nested state as a flat state.
Non-goal 8: The atom MUST NOT share one declaration across two workflows.
Non-goal 9: The atom MUST NOT version a declaration.
Non-goal 10: A deployment needing a shared declaration template MUST compose a definition registry pattern.
Non-goal 11: The atom MUST NOT bind an actor reference to an actor.
Non-goal 12: A deployment needing a non-repudiable actor MUST compose Actor Identity.
Non-goal 13: The atom MUST NOT detect a rewrite under the database.
Non-goal 14: A deployment needing a rewrite detected MUST compose Tamper Evidence.
Non-goal 15: The atom MUST NOT bound a workflow's retention.
Non-goal 16: A deployment needing a retention bound MUST compose Retention Window.
Non-goal 17: The atom MUST NOT decide who may call an action.
Non-goal 18: A deployment needing an authorization decision MUST compose Permissions.
Non-goal 19: The atom MUST NOT decide which state a workflow ought to stand in.
Non-goal 20: The atom MUST NOT read two [Fire] calls carrying one instance id and one action as one fire.
Non-goal 21: A deployment needing at-most-once firing MUST supply the deployment's own idempotency key.
Non-goal 22: A deployment needing a verifiable time anchor MUST compose a trusted timestamping pattern.
```

NOTE: the owners — [Execute Gated Workflow](../compositions/execute-gated-workflow.md) (Non-goal 1, External check 1, Composition note 2, Composition note 3); a fork-join pattern (Non-goal 3 through 5); a definition registry pattern and the calling system (Non-goal 8 through 10); [Actor Identity](./actor-identity.md) (Non-goal 11, Non-goal 12, External check 3); [Tamper Evidence](./tamper-evidence.md) (Non-goal 13, Non-goal 14); [Retention Window](./retention-window.md) (Non-goal 15, Non-goal 16); the composing system (Non-goal 19).

---

## Edge cases

### Atomic writes

```
Deleted: Atomic writes 1. Execution Contract Database 1 owns it.
Deleted: Atomic writes 2. Execution Contract Database 1 owns it.
Deleted: Atomic writes 3. Execution Contract Database 1 and Execution Contract Database 3 own it.
Deleted: Atomic writes 4. Execution Contract Database 1 owns it.
Deleted: Atomic writes 5. Execution Contract Database 1 owns it.
```

### Clock semantics

```
Clock semantics 4: A firing instant MUST NOT bound a later history entry's firing instant.
Deleted: Clock semantics 1. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 2. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 3. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 5. Non-goal 22 owns it.
```

### Concurrency

```
Deleted: Concurrency 1. Execution Contract Database 2 owns it.
Deleted: Concurrency 2. Execution Contract Database 2 owns it.
```

### String policy

```
String 1: The atom MUST compare a string input byte-exactly.
String 2: The atom MUST NOT trim a string input.
String 3: The atom MUST NOT normalize a string input.
String 4: The atom MUST NOT case-fold a string input.
String 5: The atom MUST read a whitespace-only string input as blank.
String 6: The atom MUST read an absent string input as blank.
Deleted: String 7. Execution Contract Logic confinement 13 owns it.
```

Term string input: instance id, action, actor reference, subject reference, a state name, a guard OR a filter's value — every caller-supplied string this atom accepts.

NOTE: watch host obligations — this atom sets no maximum length on a string input, where [Duplicate Prevention](./duplicate-prevention.md) declares a cap and [Provenance](./provenance.md) obliges the deployment to set one. Three postures, and the *host obligations* docket row carries the count — a watch flag states the pressure, never a census nothing reads.

---

## Composition notes

```
Deleted: Composition note 1. Capability requirement 6 owns it.
Composition note 2: A composing pattern MUST own a guard's evaluation.
Composition note 3: A composing pattern asserting guard satisfied MUST own the evidence.
Composition note 4: A composing pattern MUST own the authorization of a call.
Composition note 5: A composing pattern MUST own the attestation binding an actor reference.
Composition note 6: A composing pattern MUST own the tamper seal over a transition history.
Composition note 7: A composing pattern MUST own the retention of the workflow records.
Composition note 8: A composing pattern MUST own an idempotency key.
Composition note 9: A composing pattern MUST own a declaration template.
Deleted: Composition note 10. Execution Contract Atom interface 1 owns it.
```

NOTE: composing patterns — [Execute Gated Workflow](../compositions/execute-gated-workflow.md).

---

## Terms

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is* and its **Kind**.

### Vocabulary

Term actors: the atom; the host; the transition; the deployment; a composing pattern; a caller; a guard; an auditor; a regulator; an inspector; an investigator; the database; a workflow; a history entry; a declaration; a declared transition; a matched transition; a guarded declared transition; an unguarded declared transition; an addressed action; a writing action; a reading action; a refused action; an ordering rule; an action; a query; a filter; a range filter; a string filter; a replay; a state name; a string input; an opaque reference; the workflow's history entry count; the workflow's admitted fire count.

Term records: workflow — one running workflow, carrying instance id, a declaration, a current state, a transition history, next sequence number, an instantiation instant and the subject reference, instance metadata and actor reference [Instantiate] recorded. history entry — one recorded transition, carrying transition id, sequence number, from state, to state, action, firing instant and the actor reference and guard satisfied [Fire] recorded.

Term record verbs: identify, allocate, change, carry, stand, answer, record, append, set, take, raise, leave, own, match, normalize, reorder, interpret, confirm, admit, offer, evaluate, assert, fire, replay, reach, rest, share, precede, follow, compare, trim, case-fold, refuse, write, read, find, reconstruct, complete, equal, bound, nest, version, decide, compose, declare, wire, supply, remove, route, name, detect, bind, capture, count.

Term value sets: writing action = [Instantiate] | [Fire]. reading action = [Current] | [History] | [Read Declaration]. guard satisfied = true | false. filter axes = transition id | sequence number | from state | to state | action | actor reference | firing instant.
Term bounds: empty.

Term cadences: empty.

Term qualifiers: migrated — rewritten in GRACE lang v0.40 (2026-09-12).

Term terms: workflow, instance id, history entry, transition id, subject reference, instance metadata, database instance, seam, transition, declared transition, declaration, states, initial state, terminal states, well-formed declaration, now, addressed action, writing action, reading action, current state, next sequence number, sequence number, firing instant, instantiation instant, resolved firing instant, resolved instantiation instant, actor reference, guard, guard satisfied, matched transition, cleared fire, firing check, firing fault, filter axes, admitted instantiate, admitted fire, admitted history, committed version, string input.

#### Instantiate

The behavior that validates a caller-supplied [Declaration] and creates a new workflow in its [Initial State], assigning a fresh [Workflow Id], recording [Workflow Metadata], [Actor Reference], and [Instantiation Instant], and starting an empty [Transition History]. Rejected [Invalid Declaration] for any declaration defect, [Invalid Request] for a bad [Actor Reference] or [Instantiation Instant], or [Storage Failure].

Kind: Operation

#### Fire

The behavior that advances a workflow along a declared transition: it looks up the unique transition matching the current state and the supplied [Action], gates on [Guard] / [Guard Satisfied], appends one immutable history entry, and sets [Current State] to the transition's [To State]. Rejected [Not Known], [Terminal], [Invalid Transition], [Guard Not Satisfied], [Invalid Request], or [Storage Failure].

Kind: Operation

#### Current

The read-only query returning a workflow's [Current State] name. Rejected [Not Known] or [Invalid Request].

Kind: Operation

#### History

The read-only query returning a workflow's [Transition History] in [Sequence Number] ascending order, filterable by [Transition Id], a [Sequence Number] range, [From State], [To State], [Action], [Actor Reference], or a [Firing Instant] range. Rejected [Not Known], [Invalid Query], or [Invalid Request].

Kind: Operation

#### Read Declaration

The read-only query returning the workflow's immutable [Declaration] exactly as supplied at [Instantiate]. Rejected [Not Known] or [Invalid Request].

Kind: Operation

#### Workflow Id

The opaque, immutable, system-generated identity of a workflow — assigned on [Instantiate], never reused, byte-order sortable (Execution Contract Logic confinement 10). It is the workflow's identity; the [Declaration], [Current State], and [Transition History] are properties.

Kind:       Field
Field of:   the workflow
Projection: instance_id

#### Subject Reference

The optional opaque reference to the entity whose lifecycle the workflow governs (a batch id, document id, work item id). Set on [Instantiate], immutable; the atom does not validate it, and its absence is valid.

Kind:       Field
Field of:   the workflow
Projection: subject_ref

#### Workflow Metadata

The optional opaque deployment-context payload supplied at [Instantiate], immutable; recorded as an auditable field, never interpreted.

Kind:       Field
Field of:   the workflow
Projection: instance_metadata

#### Current State

The workflow's current state — a member of the declared [States] (Invariant 2). Set to [Initial State] on [Instantiate]; updated to the fired transition's [To State] on each [Fire]. Always replay-derivable from the [Transition History] (Invariant 7).

Kind:       Field
Field of:   the workflow
Projection: current_state

#### Transition History

The ordered, append-only sequence of transition history entries for a workflow (Invariant 5). Begins empty; each [Fire] appends exactly one entry; never shrinks; total-ordered by [Sequence Number] (Invariant 6).

Kind:       Field
Field of:   the workflow
Projection: transition_history

#### Next Sequence Number

The [Sequence Number] the next [Fire] will assign. Begins at 1; increments by one per successful [Fire].

Kind:       Field
Field of:   the workflow
Projection: next_sequence_number

#### Declaration

The immutable map supplied at [Instantiate] that governs a workflow — its [States], [Transitions], [Initial State], and [Terminal States]. Every enforcement decision derives from it; it never changes (Invariant 1) and is returned verbatim by [Read Declaration].

Kind:       Field
Field of:   the workflow
Projection: declaration

#### Instantiation Instant

The wall-time the workflow was created, stamped at [Instantiate] (or caller-supplied; not in the future). The lower bound for every [Firing Instant] — a transition cannot predate instantiation.

Kind:       Field
Field of:   the workflow
Projection: instantiated_at

#### States

The non-empty set of named states in a [Declaration]. Each name is non-blank and unique within the declaration; [Current State], [Initial State], [From State], and [To State] are all drawn from it.

Kind:       Field
Field of:   the declaration
Projection: states

#### Transitions

The set of declared transitions in a [Declaration], each a `{from_state, action, to_state, guard?}` tuple. At most one transition per `(from_state, action)` pair (determinism); none may originate from a [Terminal States] member.

Kind:       Field
Field of:   the declaration
Projection: transitions

#### Initial State

The [Declaration]'s starting state — a member of [States], never a [Terminal States] member. It is the workflow's [Current State] at [Instantiate] and the replay origin (Invariant 7).

Kind:       Field
Field of:   the declaration
Projection: initial_state

#### Terminal States

The subset of [States] that is absorbing (Invariant 4): once [Current State] is one of them, no [Fire] succeeds. No declared transition may originate from one (enforced at [Instantiate]).

Kind:       Field
Field of:   the declaration
Projection: terminal_states

#### From State

The state a declared transition (and the history entry it produces) departs from — a member of [States]. On a [Fire], it must equal the workflow's [Current State].

Kind:       Field
Field of:   a declared transition
Projection: from_state

#### To State

The state a declared transition (and the history entry it produces) arrives at — a member of [States]. On success it becomes the workflow's new [Current State] and the returned new_state.

Kind:       Field
Field of:   a declared transition
Projection: to_state

#### Action

The named trigger of a declared transition — a non-blank string. Supplied on [Fire] to select the unique transition from the [Current State]; recorded on the history entry.

Kind:       Field
Field of:   a declared transition
Projection: action

#### Guard

The optional opaque label on a declared transition naming a condition the caller must assert satisfied before the transition fires. The atom gates on it but never evaluates the predicate (Invariant 8); guard evaluation is the caller's obligation.

Kind:       Field
Field of:   a declared transition
Projection: guard

#### Transition Id

The opaque, immutable, system-generated identity of a transition history entry — assigned by [Fire], never reused within the workflow.

Kind:       Field
Field of:   the history entry
Projection: transition_id

#### Sequence Number

The strictly increasing integer assigned to a history entry from [Next Sequence Number] at [Fire]. The clock-independent total-order source for the [Transition History] (Invariant 6); [Firing Instant] is not.

Kind:       Field
Field of:   the history entry
Projection: sequence_number

#### Firing Instant

The best-effort wall-time a transition was recorded, stamped at [Fire] (or caller-supplied; not in the future; ≥ [Instantiation Instant]). Not required to be monotonic across entries — [Sequence Number] is the order source.

Kind:       Field
Field of:   the history entry
Projection: fired_at

#### Actor Reference

The optional opaque reference to the actor who fired a transition, recorded on the history entry (and on the workflow at [Instantiate]). If supplied, non-blank; its presence is deployment policy, not an atom mandate (Invariant 9).

Kind:       Field
Field of:   the history entry
Projection: actor_ref

#### Guard Satisfied

The caller-asserted flag that a guarded transition's [Guard] condition is met — a [Fire] on a guarded transition fires only if it is true, and the history entry then records `guard_satisfied: true` (Invariant 8). Absent for unguarded transitions: there a true or false assertion gates nothing, and the history entry records none (Operation 30).

Kind:       Field
Field of:   the history entry
Projection: guard_satisfied

#### Invalid Declaration

The rejection [Instantiate] returns for any declaration defect — a malformed [Declaration], an empty or duplicate-named [States] set, an [Initial State] that is missing or in [Terminal States], a [Terminal States] member missing from [States], a transition referencing an undeclared state or leaving a terminal state, a duplicate `(from_state, action)` pair, or a blank [Action] or [Guard].

Kind:       Member
Member of:  the Instantiate rejection
Role:       Outcome
Projection: invalid-declaration

#### Invalid Request

The rejection an action returns for a malformed argument — a null or whitespace-only [Workflow Id] or [Action], a bad [Actor Reference], a supplied instant that is not an instant, a supplied [Guard Satisfied] that is neither true nor false on an unguarded transition, or an [Instantiation Instant] / [Firing Instant] that is in the future or (for [Firing Instant]) before [Instantiation Instant].

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-request

#### Storage Failure

The rejection any write action returns when the database write fails after all preconditions pass; guarantees no partial record and an unchanged [Current State] / [Next Sequence Number] (Operation 35 through 37).

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: storage-failure

#### Not Known

The rejection [Fire], [Current], [History], or [Read Declaration] returns when the [Workflow Id] references no workflow in the database.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: not-known

#### Terminal

The rejection [Fire] returns when the workflow's [Current State] is a [Terminal States] member — terminal states are absorbing (Invariant 4).

Kind:       Member
Member of:  the Fire rejection
Role:       Outcome
Projection: terminal

#### Invalid Transition

The rejection [Fire] returns when no declared transition matches the [Current State] and the supplied [Action] — only declared transitions fire (Invariant 3).

Kind:       Member
Member of:  the Fire rejection
Role:       Outcome
Projection: invalid-transition

#### Guard Not Satisfied

The rejection [Fire] returns when the matched transition carries a [Guard] but the caller did not assert [Guard Satisfied] as true (Invariant 8).

Kind:       Member
Member of:  the Fire rejection
Role:       Outcome
Projection: guard-not-satisfied

#### Invalid Query

The rejection [History] returns for a malformed filter — a null or whitespace-only [Transition Id], [From State], [To State], [Action], or [Actor Reference]; a reversed [Sequence Number] or [Firing Instant] range, or one missing its start or its end; or an unrecognized filter key.

Kind:       Member
Member of:  the History rejection
Role:       Outcome
Projection: invalid-query

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a [Term] marker to its term entry heading above (kramdown
     auto-generates the heading anchors on GitHub Pages). Standard CommonMark /
     kramdown; no plugin required. -->

[Instantiate]: #instantiate
[Fire]: #fire
[Current]: #current
[History]: #history
[Read Declaration]: #read-declaration
[Workflow Id]: #workflow-id
[Subject Reference]: #subject-reference
[Workflow Metadata]: #workflow-metadata
[Current State]: #current-state
[Transition History]: #transition-history
[Next Sequence Number]: #next-sequence-number
[Declaration]: #declaration
[Instantiation Instant]: #instantiation-instant
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
[Firing Instant]: #firing-instant
[Actor Reference]: #actor-reference
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

- **FDA 21 CFR Part 11 (Electronic Records; Electronic Signatures)** — for FDA-regulated contexts: each declared state transition constitutes a regulated electronic record; the transition history is the audit trail that Part 11 section 11.50 (attributability) and Part 11 section 11.70 (record linking to prevent removal, substitution, or falsification) require. Composition with [Actor Identity](./actor-identity.md) provides the section 11.50 attributability; composition with [Tamper Evidence](./tamper-evidence.md) provides the section 11.70 non-falsifiability. Invariants 3 (only-declared-transitions), 5 (history append-only and complete), and 7 (replay determinism) are the atom-level guarantees the regulated record depends on.
- **ISO 9001:2015 clause 8.5.1 (Control of production and service provision)** — requires that production and service provision activities be controlled by documented procedures, including controlled transitions at defined points in the process lifecycle. A State Machine workflow governing a production process is the documented process record section 8.5.1 anticipates; the declaration is the procedure map; the transition history is the per-workflow proof of execution.
- **BPMN 2.0 (Business Process Model and Notation 2.0 — an international standard for modeling business processes, published by the Object Management Group)** — a BPMN process model's states and sequence flows map directly to this atom's [States] and [Transitions]; a BPMN lane actor maps to an [Actor Reference] on [Fire] calls; a BPMN gateway condition maps to a [Guard] label on a declared transition.
- **HL7 FHIR Task resource** — the HL7 FHIR Task resource uses a declared workflow state machine (`Task.status`) with a defined lifecycle (`requested → accepted → in-progress → completed | failed | cancelled | rejected`). This atom is the general primitive the FHIR Task lifecycle is an instance of. A conforming FHIR Task implementation may derive its state enforcement from this atom's declared-transition model.
- **UML (Unified Modeling Language — the standard object-oriented modeling language published by the Object Management Group) statecharts and Harel statecharts** — the conceptual core of this atom. A UML statechart's states, transitions, events, and guards map directly to this atom's [States], [Transitions], [Action]s, and [Guard] labels. This atom is a flat (non-hierarchical, single-active-state) Mealy / Moore finite-state-machine (a finite state machine is a computational model with a finite set of states, a start state, a set of transitions, and one active state at a time) workflow; Harel nesting and parallel regions are out of scope (see Non-goal 3 through 7).
- **SOX (Sarbanes-Oxley Act — US law on corporate financial reporting and records integrity) section 404** — internal control over financial reporting. For financial process workflows (approval chains, journal entry processing, purchase order lifecycle), State Machine workflows are the process-control records SOX auditors query to verify that required control steps occurred in the declared order.
- **HIPAA (Health Insurance Portability and Accountability Act) section 164.530(j)** — documentation requirements for covered entities: policies and procedures must be documented. Workflows governing patient-care or administrative processes under HIPAA may use this atom's transition history as the documentation of process execution.
- **GDPR (EU General Data Protection Regulation) Article 17** — the right to erasure. How long workflows are kept under it is a composed [Retention Window](./retention-window.md)'s obligation, not this atom's (Non-goal 15, Non-goal 16).
- **FRCP (Federal Rules of Civil Procedure) Rule 37(e)** — failure to preserve electronically stored information. How long workflows are kept under it is a composed [Retention Window](./retention-window.md)'s obligation, not this atom's (Non-goal 15, Non-goal 16).

Guard evaluation, non-repudiable attribution, tamper-evidence, and retention are explicitly composing-pattern obligations, not this atom's own standards obligations.

---

## Status

`grounded on Final Critique 10 — 2026-10-31` — see the Ledger.

## Ledger

```
status: grounded on Final Critique 10 — 2026-10-31
formal: verified — state-machine.als + 1 twin, 2026-06-04
last gate: 2026-10-31 — Final Critique 10 — foundational count 0, clean, one sample

open:
- 2026-10-31-a · refining · State 2; State 3; State 15; Operation 67 · no action answers a workflow's subject reference, instance metadata, actor reference or instantiation instant, which the workflow records carry, and a composing pattern reads an atom only through the atom's declared surface (the section titled The atom interface contract in `execution-contract.md`) → a read answering them, or a non-goal saying none does and who owns the need
```

<details markdown="block">
<summary>
    <h2 id="decisions" style="display: inline-block; margin-left: 1.5rem;">Decisions</h2>
</summary>

Directional changes only — the turns a future reader must know the pattern took, and why. Everything smaller lives in the commit that made it: `git log -- atoms/state-machine.md`; the migration and the repair that got it here are in [its history](./state-machine.hist.md).

- **2026-10-20 — The store's guarantees cited, not restated.** *Chose:* the workflow store supplied under Execution Contract Store 1 through 4 (Capability requirement 5), and the ten rules that restated them, or existed only for a store that could split a fire, tombstoned to their owner — Operation 27, a fire's entry, counter raise and state change committed in one operation, Invariant 10.3, no partial record left by a storage-failure rejection, and Atomic writes 1, 2, 4 and 5, no reader observing a history entry without its next sequence number raise or its current state change, a dangling transition resolved and no read served before it is, to Store 1, under which no fire stands partly applied; Atomic writes 3, an uncommitted crash leaving the workflow as the call found it, to Store 1 and Store 3; State 14, next sequence number surviving a restart, to Store 3; Concurrency 1 and 2, two fires on one workflow serialized and the later reading the current state the earlier left, to Store 2; rules 186 to 177. *Over:* the atom restating, for its own store, what every deployment's store guarantees, and keeping a crash-recovery obligation for a split fire that no conforming store leaves. *Because:* the maintainer ruled 2026-10-12 that the corpus takes a store's specification, never the store, and `execution-contract.md` writes it once as the Store contract. What stays is the atom's own: a refused action leaving the workflow as the call found it, appending no history entry and raising no next sequence number (Operation 35 through 37), and the rules that keep a workflow and its history once they exist (State 6, State 7, State 12, State 13, Invariant 10.1, Invariant 10.2), since Store 4 alone neither keeps the atom from removing a workflow or a history entry nor bars a purge another specification declares. The history's order is the atom's own sequence number, taken inside the fire that appends the entry (Operation 22, Invariant 6.3), and the atom's checks compare an auditor's own reads or replay the entries, so the atom cites neither History 1 nor Order 1. What the atom does for its domain is unchanged.

- **2026-10-21 — Which refusal answers is the Execution Contract's.** *Chose:* each refuses line kept as the page wrote it, already in the order its pairs gave — [Instantiate] invalid-declaration ahead of invalid-request; [Fire] invalid-request on a blank instance id or action, then not-known, terminal, invalid-transition and guard-not-satisfied, the table's rows 1 through 5; [History] not-known ahead of invalid-query; storage-failure last, answering only at the write — and the order cited from the Execution Contract (Capability requirement 5, Execution Contract Refusal 1); the pairs that only stated it deleted to Refusal 1: Operation 1 (invalid-request only on a well-formed declaration), Operation 12 (not-known only for an instance id that is not blank), Operation 14 (terminal only for an instance id naming a workflow), Operation 16 (invalid-transition only off a terminal state), Operation 18 (guard-not-satisfied only where a declared transition matches), Operation 34 (storage-failure behind every precondition) and Operation 46 (invalid-query only for an instance id naming a workflow); rules 177 to 170. The table's row 6, an actor or instant fault answered only once the gate clears, stood in no rule and no fixed line can hold invalid-request in both rows, so it is routed as open line 2026-10-21-a. *Over:* the page stating for itself which of an action's refusals answers when several apply. *Because:* the maintainer ruled on 2026-10-21 that the Execution Contract states once that the refusal listed first on an action's refuses line answers.

- **2026-10-22 — A guarded fire lands only on a true assertion, an admitted call is one whose writes commit, and a composed retention may purge what the atom never removes.** *Chose:* Operation 17 refusing a guarded fire whose guard satisfied is not true, with Term guard satisfied declaring true | false and Invariant 8.1 reading the same; the admitted instantiate and admitted fire written as a call that passes every precondition and whose database writes commit; [Instantiate] taking the optional subject reference State 2 and Term string input name, which Operation 56 records; and State 12 and State 13 deleted to Invariant 10.1, Invariant 10.2 and Execution Contract Database 4, the page read as Final Critique 4's text read it: the atom keeps every workflow and history entry, and time-bounded retention is a composing Retention Window's. *Over:* Operation 17 refusing only an absent assertion beside the term entries' true; admitted terms that stopped at the guards and took in a call the database refused; a subject reference no action took; and the 2026-10-20 entry's reading that State 6, State 7, State 12, State 13, Invariant 10.1 and Invariant 10.2 bar a purge another specification declares. *Because:* Final Critique 5 found the four, and the corpus already reads so: Medication Order, Credential, Provisional Commitment, Party Identity, Invitation and Provenance write their admitted calls in that form, and Selective Disclosure, Party Identity, Provisional Commitment, Observation, Capacity Constraint Enforcement and Message Preference cured the composed erasure the same way. Smaller fixes rode with them: State 1 carries the instantiation instant Operation 20 reads, and State 15 and State 16 the instantiating actor reference and guard satisfied; Declaration 18 refuses a terminal state outside states; External check 4 asks the deployment for the patterns it wired in (Composition note 1); Check 5.3 cites Invariant 5.1; the Workflow Id entry no longer names a consumer the page lacks; [History]'s query is routed as open line 2026-10-22-a; rules 170 to 173. What each action answers and writes on a call it admits is unchanged, but that a guarded fire asserting false is refused and the subject reference is taken and recorded.

- **2026-10-22 — An admitted call, a composed purge and the wiring are the Execution Contract's.** *Chose:* the admitted instantiate and the admitted fire citing Execution Contract Read 4 for what an action admits, in place of the commit clause this page's fifth Final Critique wrote into each, so Operation 38, Operation 47 and Invariant 1.2, which name [Current] and [Read Declaration], hold under Read 4 for the calls those actions admit, as every other effect rule does; Invariant 10.1 and Invariant 10.2 read by Execution Contract Database 6, so the atom removes no workflow and no history entry and a purge a composing Retention Window declares is answered by that pattern's records; External check 4, the auditor reading which composing patterns a deployment wired in from the deployment's own declaration, deleted to Execution Contract Conformance 9, and the checks NOTE's sentence restating it removed; the three labels cited on Capability requirement 5; rules 173 to 172. *Over:* the page stating for itself which calls its effect rules reach, that its no-removal rules bind the atom alone, and that the wiring is an external check. *Because:* the maintainer ruled on 2026-10-22 that five repeated cures are each stated once, the admitted effect, the composed erasure and the wiring declaration among them; this page's fifth Final Critique had made all three one specification at a time. What each action does and answers is unchanged.

</details>

NOTE: End of State Machine.
