---
title: State Machine
id: 59
audience: common
---

# State Machine

<details markdown="block">
<summary>Table of contents</summary>
{: .text-xs .font-medium .uppercase .tracking-wide .opacity-50 }
1. TOC
{:toc}
</details>

## What it is

State Machine records a single named workflow — think of it as a token moving through a flowchart — where the flowchart (the set of valid states and the transitions between them) is declared by the system deploying it rather than fixed by the pattern itself.

When the workflow is created, the deployer provides the complete map: every state, every allowed move between states (each move is a named action, optionally gated by a condition the calling system must assert is satisfied), the starting state, and any states that are permanent endpoints. From that moment forward the map is frozen — it cannot be changed for this workflow.

State Machine then enforces three guarantees for the lifetime of the workflow: only declared moves are allowed (an undeclared move is refused); exactly one current state exists at all times; and every move that succeeds is recorded, in order, and never deleted by the pattern itself, with enough context to replay the full history and arrive at the current state.

These guarantees make it useful for regulated processes (a pharmaceutical batch that must prove it moved only through the approved sequence of quality-control states) and for any process that needs an unambiguous, auditable record of what happened and in what order. It holds every workflow id it mints.

*Also known as: a workflow instance, a process instance, a declared finite state machine.*

<details markdown="block">
<summary>WHY</summary>

Different deployments need different state machines: a batch release under 21 CFR (Code of Federal Regulations) Part 11, an HL7 (Health Level Seven) FHIR (Fast Healthcare Interoperability Resources) Task lifecycle, a BPMN (Business Process Model and Notation) process. The commonality is declared-finite-state-machine *enforcement*, not the particular states, so the declaration is data the deployment supplies and the enforcement is the atom. A machine whose states are fixed by its own specification is a different atom; this one's machine is fixed per workflow, and an evaluator reads the workflow's declaration to know what is valid.

The guard is where the atom's restraint is sharpest. A declared transition may carry a guard label, and the atom requires the caller to *assert* the guard satisfied before the transition fires, while evaluating nothing: the history records the assertion, not a verdict. The alternative is an atom that must understand every deployment's predicates.

</details>

## What it keeps

### The workflows

```
Identity 1: The atom MUST identify a workflow by the workflow id.
Identity 2: The atom MUST identify a history entry by the history entry id.
Identity 3: The host MUST supply at the seam the workflow id the atom mints.
Identity 4: The host MUST supply at the seam the history entry id the atom mints.
Identity 7: The atom MUST NOT change a workflow id.
Identity 8: The atom MUST NOT change a history entry id.
Identity 9: Two workflows in one database instance MUST NOT share a workflow id.
Identity 10: Two history entries in one workflow MUST NOT share a history entry id.
Identity 13: The atom MUST NOT identify a workflow by the subject reference.
Identity 14: The atom MUST admit a second workflow carrying a recorded subject reference.
Identity 15: The atom MUST NOT confirm that a subject reference names a known subject.
Identity 16: The atom MUST NOT interpret an instance metadata.
```

Term workflow: one running workflow — one declaration, one current state and one transition history; the record this atom holds, one for each workflow id.

Term history entry: one recorded transition on one workflow, carrying history entry id, sequence number, from state, to state, action, firing instant and the actor reference and guard satisfied [Fire] recorded.

Term subject reference: the opaque reference naming the entity whose lifecycle the workflow governs — a [Subject Reference]; a property of the workflow, never the workflow's identity.

Term instance metadata: the opaque payload the caller supplies at [Instantiate] for deployment context — a [Workflow Metadata]; opaque content of any value (Execution Contract Input 3), exempt from the string cap, recorded where not blank, never interpreted.

Term database instance: one named database a call is routed to; workflow id uniqueness ranges over one database instance.

Term declared transition: one from state, action, to state and optional guard in the declaration — a move the workflow may make. Distinct from the transition above, which is the atom's evaluation of a call.

NOTE: watch the seam citation (Term seam, Term transition).

```
State 1: EVERY workflow MUST carry workflow id, a declaration, a current state, a transition history, next sequence number and an instantiation instant.
State 2: A workflow MAY carry subject reference.
State 3: A workflow MAY carry instance metadata.
State 4: EVERY history entry MUST carry history entry id, sequence number, from state, to state, action and firing instant.
State 5: A history entry MAY carry actor reference.
State 6: The atom MUST NOT offer a workflow removal surface.
State 7: The atom MUST NOT offer a history entry removal surface.
State 8: The atom MUST NOT offer a history entry edit surface.
State 9: The atom MUST NOT offer a reorder surface.
State 10: The atom MUST NOT offer a transition out of a terminal state.
State 11: The atom MUST NOT offer an action that stands a workflow in two states.
State 15: A workflow MAY carry actor reference.
State 16: A history entry MAY carry guard satisfied.
```

### The declaration

```
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
Declaration 20: IF a state name EXCEEDS the string cap OR a declared transition's action EXCEEDS the string cap OR a guard EXCEEDS the string cap THEN [Instantiate] MUST answer invalid-declaration (Execution Contract Input 2).
Declaration 16: The terminal states MAY carry no member.
Declaration 17: A declared transition MAY carry no guard.
```

Term declaration: the immutable map governing one workflow — a [Declaration]; carries states, the declared transitions, the initial state and the terminal states; the declared transitions or the terminal states the map leaves blank are none.

Term states: the named states one declaration admits — a [States]; every state name the workflow may stand in.

Term initial state: the state a workflow stands in at [Instantiate] — an [Initial State]; a member of states and never a terminal state.

Term terminal states: the absorbing members of states — a [Terminal States]; possibly none; a name the map repeats is one member.

Term well-formed declaration: a declaration Declaration 5 through 15 and Declaration 18 through 20 all admit.

---

#### Workflow

One running workflow: the record this atom holds for each [Workflow Id], carrying a [Declaration], a [Current State] and a [Transition History]; [Read Workflow] answers what the record carries beside the declaration and the history.

Kind: Type

#### Workflow Id

The opaque, immutable, system-generated identity of a workflow — assigned on [Instantiate], never reused, byte-order sortable (Execution Contract Logic confinement 10). It is the workflow's identity; the [Declaration], [Current State], and [Transition History] are properties.

Kind:       Field
Field of:   the workflow
Projection: workflow_id

#### Subject Reference

The optional opaque reference to the entity whose lifecycle the workflow governs (a batch id, document id, work item id). Set on [Instantiate], immutable; the atom does not confirm it names a known subject (Identity 15), and its absence is valid. [Workflows About] finds the workflows carrying it.

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

The wall-time the workflow was created, stamped at [Instantiate] (or caller-supplied; not in the future). The lower bound for every [Firing Instant] — a transition cannot predate instantiation — and the order [Workflows About] answers in.

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

#### History Entry Id

The opaque, immutable, system-generated identity of a transition history entry — assigned by [Fire], never reused within the workflow.

Kind:       Field
Field of:   the history entry
Projection: history_entry_id

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

The optional opaque reference to the actor who fired a transition, recorded on the history entry (and on the workflow at [Instantiate]). If supplied as a string, not empty or whitespace-only; its presence is deployment policy, not an atom mandate (Invariant 9).

Kind:       Field
Field of:   the history entry
Projection: actor_ref

#### Guard Satisfied

The caller-asserted flag that a guarded transition's [Guard] condition is met — a [Fire] on a guarded transition fires only if it is true, and the history entry then records `guard_satisfied: true` (Invariant 8). Absent for unguarded transitions: there a true or false assertion gates nothing, and the history entry records none (Operation 30), since an assertion no guard asked for attests nothing.

Kind:       Field
Field of:   the history entry
Projection: guard_satisfied

Term current state: the state the workflow stands in — a [Current State]; the initial state until a fire lands, and the latest history entry's to state after.

Term next sequence number: the counter [Fire] takes a sequence number from — a [Next Sequence Number]; begins at one and rises by one per append.

Term sequence number: the strictly increasing integer a history entry takes at append — a [Sequence Number]; the history's order source, and never taken from a clock.

Term firing instant: the instant a declared transition fired — a [Firing Instant]; a best-effort annotation, and never an order source.

Term instantiation instant: the instant a workflow was created — an [Instantiation Instant].

Term actor reference: the actor id naming who instantiated a workflow or fired a declared transition — an [Actor Reference]; optional, recorded where not blank, and the atom reads nothing in it.

Term guard: the opaque label naming the condition a caller asserts before a declared transition fires — a [Guard].

Term guard satisfied: true | false — a [Guard Satisfied], the caller's assertion that a guard holds; an assertion, never a verdict.

## What people do

### Every action

```
Operation 2: IF the call carries actor reference AND actor reference IS IN whitespace strings THEN a writing action MUST answer invalid-request (on [Fire], a cleared fire only: Operation 64).
Operation 77: IF actor reference EXCEEDS the string cap THEN a writing action MUST answer invalid-request (Execution Contract Input 2; on [Fire], a cleared fire only: Operation 64).
Operation 4: An admitted instantiate MUST record EXACTLY ONE workflow.
Operation 5: An admitted instantiate MUST stand the workflow in the initial state.
Operation 6: An admitted instantiate MUST set next sequence number to one.
Operation 7: An admitted instantiate MUST record an empty transition history.
Operation 8: An admitted instantiate MUST answer the workflow id.
Operation 56: IF subject reference DOES NOT EQUAL blank THEN an admitted instantiate MUST record subject reference.
Operation 70: IF subject reference EQUALS blank THEN an admitted instantiate MUST NOT record subject reference.
Operation 59: IF instance metadata DOES NOT EQUAL blank THEN an admitted instantiate MUST record instance metadata.
Operation 71: IF instance metadata EQUALS blank THEN an admitted instantiate MUST NOT record instance metadata.
Operation 60: IF actor reference DOES NOT EQUAL blank THEN an admitted instantiate MUST record actor reference on the workflow.
Operation 67: An admitted instantiate MUST record the resolved instantiation instant.
Operation 72: An admitted instantiate MUST record on the workflow the workflow id the host supplies at the seam (Identity 3).
Operation 9: IF workflow id EQUALS blank THEN an addressed action MUST answer invalid-request.
Operation 75: IF workflow id EXCEEDS the string cap THEN an addressed action MUST answer invalid-request (Execution Contract Input 2).
Operation 11: IF the workflow id names no workflow THEN an addressed action MUST answer not-known.
Operation 21: An admitted fire MUST append EXACTLY ONE history entry.
Operation 22: An admitted fire MUST take the history entry's sequence number from next sequence number.
Operation 23: An admitted fire MUST raise next sequence number by one.
Operation 24: An admitted fire MUST set the history entry's from state to the current state the call found.
Operation 25: An admitted fire MUST set the history entry's to state to the matched transition's to state.
Operation 26: An admitted fire MUST stand the workflow in the matched transition's to state.
Operation 28: An admitted fire MUST answer the matched transition's to state.
Operation 29: An admitted fire over a guarded transition MUST record guard satisfied on the history entry.
Operation 30: An admitted fire over an unguarded transition MUST NOT record guard satisfied on the history entry.
Operation 61: IF actor reference DOES NOT EQUAL blank THEN an admitted fire MUST record actor reference on the history entry.
Operation 68: An admitted fire MUST record the resolved firing instant on the history entry.
Operation 73: An admitted fire MUST record on the history entry the history entry id the host supplies at the seam (Identity 4).
Operation 33: IF the database refuses the write THEN a writing action MUST answer storage-failure.
Operation 35: A refused action MUST leave the workflow as the call found the workflow.
Operation 36: A refused action MUST NOT append a history entry.
Operation 37: A refused action MUST NOT raise next sequence number.
Operation 39: An admitted history MUST answer the matching history entries in sequence number ascending order.
Operation 42: IF no history entry matches THEN an admitted history MUST answer an empty entry sequence.
Operation 50: A reading action MUST NOT write.
Operation 55: An ordering rule MUST NOT rest on firing instant.
```

NOTE: watch the integer range (Operation 45, Operation 58).

NOTE: watch the optional field no rule records (Operation 56, Operation 59, Operation 60, Operation 61).

NOTE: watch the blank optional input (Operation 2, Operation 56, Operation 59, Operation 60, Operation 61, Operation 70, Operation 71).

NOTE: watch the required input no rule records (Operation 67, Operation 68).

NOTE: watch the cap's refusal (Operation 75 through 78, Declaration 20).

Term addressed action: any action carrying a workflow id — [Fire], [Current], [History], [Read Declaration] and [Read Workflow].

Term writing action: [Instantiate] | [Fire] — the two actions that write.

Term reading action: [Current] | [History] | [Read Declaration] | [Read Workflow] | [Workflows About] — the five that do not.

Term resolved firing instant: the firing instant the history entry carries — the supplied value, as Execution Contract Logic confinement 12 resolves it.

Term resolved instantiation instant: the instantiation instant the workflow carries — the supplied value, as Execution Contract Logic confinement 12 resolves it.

Term matched transition: the one declared transition whose from state is the current state and whose action is the call's action (Declaration 13).

Term cleared fire: a [Fire] call Operation 11, Operation 13, Operation 15 and Operation 17 all admit.

Term firing check: Operation 2, Operation 19 through 20, Operation 66, Operation 69 and Operation 77, and Execution Contract Input 1 and Input 3 on an actor reference or a guard satisfied the call carries malformed — every check [Fire] makes on a cleared fire.

Term firing fault: a firing check the call fails.

Term filter axes: history entry id | sequence number | from state | to state | action | actor reference | firing instant — the seven axes [History] accepts, and no others, a filter on sequence number or firing instant carrying a range.

Term recording commit: the commit of the [Instantiate] call that recorded a workflow, one position in the single order Execution Contract Order 1 gives every commit.

Term admitted instantiate: an [Instantiate] call the action admits (Execution Contract Read 4).

Term admitted fire: a [Fire] call the action admits (Execution Contract Read 4).

Term admitted history: a [History] call whose workflow id names a workflow and that Operation 43, Operation 45, Operation 57, Operation 58 and Operation 87 through 89 all admit.

Term string filter: a filter on history entry id, from state, to state, action or actor reference.

Term range filter: a filter on sequence number or firing instant, which carries a range.

The case space, and the rule that owns each case:

| # | Condition | [Fire] answers | Owner |
|---|---|---|---|
| 1 | the read of the workflow records fails | state-unavailable | Execution Contract Read 1, Execution Contract Read 3 |
| 2 | workflow id or action is blank or over the string cap | invalid-request | Operation 9, Operation 10, Operation 75, Operation 76 |
| 3 | both are well-formed, the workflow id names no workflow | not-known | Operation 11 |
| 4 | the workflow exists, the current state is terminal | terminal | Operation 13 |
| 5 | the current state is not terminal, no declared transition matches | invalid-transition | Operation 15 |
| 6 | a declared transition matches, it carries a guard, guard satisfied is not true, a value neither true nor false included | guard-not-satisfied | Operation 17 |
| 7 | the call is a cleared fire, a firing check fails | invalid-request | Operation 64; Operation 2, Operation 19, Operation 20, Operation 66, Operation 69, Operation 77; Execution Contract Input 1, Execution Contract Input 3 |
| 8 | every precondition passes, the database refuses the write | storage-failure | Operation 33 |
| 9 | every precondition passes, the database accepts the write | new_state | Operation 28; Invariant 1.1, Invariant 5.1 |

Where two rows hold at once, the earlier row answers: row 1 answers ahead of every refusal, since in an atom every guard runs after the read (Execution Contract Read 1); the other rows follow the refuses line (Execution Contract Refusal 1), except that row 7 answers only on a cleared fire (Operation 64) and so stands below rows 3 through 6.

The case space, and the rule that owns each case:

| # | Condition | [Workflows About] answers | Owner |
|---|---|---|---|
| 1 | the subject reference is blank, over the string cap or not a string | invalid-request | Operation 85, Operation 86 |
| 2 | the read of the workflow records fails | state-unavailable | Execution Contract Read 1, Execution Contract Read 3 |
| 3 | no workflow carries the subject reference | an empty list | Operation 84 |
| 4 | one or more workflows carry the subject reference | the workflow id of each, terminal ones included, by instantiation instant earliest first, two sharing one by recording commit, two sharing both by workflow id | Operation 80, Operation 82, Operation 83 and Operation 93 |

Where two rows hold at once, the earlier row answers: row 1 answers a malformed subject reference whatever the workflow records hold or fail to answer (Operation 86; Execution Contract Query 5).

[Workflows About] writes nothing (Operation 50), and its refuses line lists invalid-request alone: row 1 refuses, row 2 is the answer Execution Contract Read 1 gives every action whose read fails, and rows 3 and 4 answer.

NOTE: watch condition negation — invalid-request occupies two rows of one precedence chain (row 2 and row 7), so the answer alone does not say which guard refused.

#### Invalid Request

The rejection an action returns for a malformed argument — a null or whitespace-only [Workflow Id] or [Action], an [Actor Reference] the call carries as an empty or whitespace-only string or as a value that is not a string (Execution Contract Input 3), an absent [Actor Reference] being no refusal and recording nothing (Operation 60, Operation 61, Execution Contract Input 4), a [Workflow Id], [Action], [Actor Reference] or [Subject Reference] over the string cap (Execution Contract Input 2), a supplied instant that is not an instant, a supplied [Guard Satisfied] that is neither true nor false on an unguarded transition, or an [Instantiation Instant] / [Firing Instant] that is in the future or (for [Firing Instant]) before [Instantiation Instant] (Operation 2, Operation 3, Operation 9, Operation 10, Operation 19, Operation 20, Operation 66, Operation 69, Operation 75 through 78).

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-request

#### Storage Failure

The rejection any write action returns when the database write fails after all preconditions pass; guarantees no partial record and an unchanged [Current State] / [Next Sequence Number] (Operation 33, Operation 35 through 37).

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: storage-failure

#### Not Known

The rejection [Fire], [Current], [History], [Read Declaration] or [Read Workflow] returns when the [Workflow Id] references no workflow in the database (Operation 11).

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: not-known

### Instantiate

#### Instantiate

The behavior that validates a caller-supplied [Declaration] and creates a new workflow in its [Initial State], recording the injected [Workflow Id], [Workflow Metadata], [Actor Reference], and [Instantiation Instant], and starting an empty [Transition History]. Rejected [Invalid Declaration] for any declaration defect, [Invalid Request] for an [Actor Reference] the call carries as an empty or whitespace-only string or as a value that is not a string, or a bad [Instantiation Instant], an [Actor Reference] over the string cap, or a [Subject Reference] over the string cap, or [Storage Failure].

Kind: Operation

```
instantiate(declaration, optional subject_ref, optional actor_ref, optional instance_metadata, optional instantiated_at)
  answers workflow_id
  refuses invalid-declaration | invalid-request | storage-failure
```

```
Operation 78: IF subject reference EXCEEDS the string cap THEN [Instantiate] MUST answer invalid-request (Execution Contract Input 2).
Operation 3: IF now PRECEDES the resolved instantiation instant THEN [Instantiate] MUST answer invalid-request.
```

The case space, and the rule that owns each case:

| # | Condition | [Instantiate] answers | Owner |
|---|---|---|---|
| 1 | the declaration is malformed or not well-formed | invalid-declaration | Declaration 5 through 15, Declaration 18 through 20 |
| 2 | the call carries an actor reference that is blank, over the string cap or not a string, a subject reference over the string cap, or an instantiation instant that is malformed or later than now | invalid-request | Operation 2, Operation 3, Operation 77, Operation 78; Execution Contract Input 1, Execution Contract Input 3 |
| 3 | every precondition passes, the database refuses the write | storage-failure | Operation 33 |
| 4 | every precondition passes, the database accepts the write | the workflow id | Operation 4 through 8, Operation 72 |

Where two rows hold at once, the earlier row answers (Execution Contract Refusal 1). [Instantiate] decides on no record it reads, so no read-failure row stands.

`instantiate(declaration)` where two declared transitions both leave `tested` on `qualify` → invalid-declaration. The determinism constraint refuses the ambiguity at birth rather than inventing a tiebreak at fire time (Declaration 13).

`instantiate(declaration)` where `initial state: released` and `released` is terminal → invalid-declaration. A workflow born absorbed accepts nothing (Declaration 9).

`instantiate(declaration)` carrying an edge out of `released` → invalid-declaration (Declaration 12).

#### Invalid Declaration

The rejection [Instantiate] returns for any declaration defect — a malformed [Declaration], an empty or duplicate-named [States] set, a blank state name, an [Initial State] that is missing or in [Terminal States], a [Terminal States] member missing from [States], a transition referencing an undeclared state or leaving a terminal state, a duplicate `(from_state, action)` pair, a blank [Action] or [Guard], or a state name, [Action] or [Guard] over the string cap (Declaration 5 through 15, Declaration 18 through 20).

Kind:       Member
Member of:  the Instantiate rejection
Role:       Outcome
Projection: invalid-declaration

### Fire

#### Fire

The behavior that advances a workflow along a declared transition: it looks up the unique transition matching the current state and the supplied [Action], gates on [Guard] / [Guard Satisfied], appends one immutable history entry, and sets [Current State] to the transition's [To State]. Rejected [Not Known], [Terminal], [Invalid Transition], [Guard Not Satisfied], [Invalid Request], or [Storage Failure].

Kind: Operation

```
fire(workflow_id, action, optional actor_ref, optional guard_satisfied, optional fired_at)
  answers new_state
  refuses invalid-request | not-known | terminal | invalid-transition | guard-not-satisfied | storage-failure
```

```
Operation 10: IF action EQUALS blank THEN [Fire] MUST answer invalid-request.
Operation 76: IF action EXCEEDS the string cap THEN [Fire] MUST answer invalid-request (Execution Contract Input 2).
Operation 13: IF the current state IS IN the terminal states THEN [Fire] MUST answer terminal.
Operation 15: IF no declared transition matches the current state and action THEN [Fire] MUST answer invalid-transition.
Operation 17: IF the matched transition carries a guard AND guard satisfied DOES NOT EQUAL true, a guard satisfied that is neither true nor false included, THEN [Fire] MUST answer guard-not-satisfied.
Operation 19: IF now PRECEDES the resolved firing instant THEN [Fire] MUST answer invalid-request.
Operation 20: IF the resolved firing instant PRECEDES the workflow's instantiation instant THEN [Fire] MUST answer invalid-request.
Operation 66: IF the resolved firing instant is malformed THEN [Fire] MUST answer invalid-request (Execution Contract Input 1).
Operation 69: IF the matched transition carries no guard AND the call carries guard satisfied AND guard satisfied is malformed THEN [Fire] MUST answer invalid-request (Execution Contract Input 1).
Operation 64: [Fire] MUST answer invalid-request on a firing fault ONLY IF the call is a cleared fire.
Operation 31: [Fire] MUST NOT evaluate a guard.
```

`fire("wf_01HQ…", "test")` against the released workflow → terminal. Not invalid-transition, even though no `test` edge leaves `released` — an absorbed workflow refuses every action, and saying so sends the caller to the right problem (Operation 13, Execution Contract Refusal 1).

`fire("wf_01HQ…", "expedite")` against a live workflow in `tested` → invalid-transition. No declared transition matches, and there is no wildcard (Operation 15, Declaration 10).

`fire("wf_99999", "test")` → not-known. `fire("", "test")` → invalid-request, answered ahead of not-known (Operation 9, Execution Contract Refusal 1).

`fire("wf_01HQ…", "test", fired_at: "2020-01-01")` against a workflow instantiated in 2026 and standing in `sampled` → invalid-request. A transition cannot fire before the workflow existed (Operation 20). Against the released workflow the same call → terminal, since a firing fault answers only on a cleared fire (Operation 64).

#### Terminal

The rejection [Fire] returns when the workflow's [Current State] is a [Terminal States] member — terminal states are absorbing (Operation 13, Invariant 4).

Kind:       Member
Member of:  the Fire rejection
Role:       Outcome
Projection: terminal

#### Invalid Transition

The rejection [Fire] returns when no declared transition matches the [Current State] and the supplied [Action] — only declared transitions fire (Operation 15, Invariant 3).

Kind:       Member
Member of:  the Fire rejection
Role:       Outcome
Projection: invalid-transition

#### Guard Not Satisfied

The rejection [Fire] returns when the matched transition carries a [Guard] but the caller did not assert [Guard Satisfied] as true (Operation 17, Invariant 8).

Kind:       Member
Member of:  the Fire rejection
Role:       Outcome
Projection: guard-not-satisfied

### Current

#### Current

The read-only query returning a workflow's [Current State] name. Rejected [Not Known] or [Invalid Request].

Kind: Operation

```
current(workflow_id)
  answers current_state
  refuses invalid-request | not-known
```

```
Operation 38: [Current] MUST answer the workflow's current state.
```

### History

#### History

The read-only query returning a workflow's [Transition History] in [Sequence Number] ascending order, filterable by [History Entry Id], a [Sequence Number] range, [From State], [To State], [Action], [Actor Reference], or a [Firing Instant] range. Rejected [Not Known], [Invalid Query], or [Invalid Request].

Kind: Operation

```
history(workflow_id, optional query)
  answers the matching history entries
  refuses invalid-request | not-known | invalid-query
```

```
Operation 57: IF the query is malformed THEN [History] MUST answer invalid-query (Operation 43, Operation 45, Operation 58, Operation 87 through 89).
Operation 43: IF a filter's axis IS NOT IN the filter axes THEN [History] MUST answer invalid-query.
Operation 45: IF a sequence number range's start EXCEEDS the range's end THEN [History] MUST answer invalid-query.
Operation 58: IF a firing instant range's end PRECEDES the range's start THEN [History] MUST answer invalid-query.
Operation 87: IF a string filter's value EQUALS blank THEN [History] MUST answer invalid-query (String 5, Execution Contract Query 5).
Operation 88: IF a string filter's value EXCEEDS the string cap THEN [History] MUST answer invalid-query (Execution Contract Query 5).
Operation 89: IF a range filter lacks the range's start OR lacks the range's end THEN [History] MUST answer invalid-query (Execution Contract Query 1).
```

The case space, and the rule that owns each case:

| # | Condition | [History] answers | Owner |
|---|---|---|---|
| 1 | the read of the workflow records fails | state-unavailable | Execution Contract Read 1, Execution Contract Read 3 |
| 2 | the workflow id is blank or over the string cap | invalid-request | Operation 9, Operation 75 |
| 3 | the workflow id names no workflow | not-known | Operation 11 |
| 4 | the query is malformed | invalid-query | Operation 57; Operation 43, Operation 45, Operation 58, Operation 87 through 89 |
| 5 | no history entry matches | an empty entry sequence | Operation 42 |
| 6 | one or more history entries match | the matching history entries, sequence number ascending | Operation 39 |

Where two rows hold at once, the earlier row answers: row 1 by Execution Contract Read 1, the others by the refuses line (Execution Contract Refusal 1).

#### Invalid Query

The rejection [History] returns for a malformed filter — a null or whitespace-only [History Entry Id], [From State], [To State], [Action], or [Actor Reference], or one over the string cap; a reversed [Sequence Number] or [Firing Instant] range, or one missing its start or its end; or an unrecognized filter key. A blank filter value is malformed: String 5 reads a whitespace-only value as blank, and a blank filter matches nothing a caller meant (Operation 43, Operation 45, Operation 57, Operation 58, Operation 87 through 89).

Kind:       Member
Member of:  the History rejection
Role:       Outcome
Projection: invalid-query

### Read Declaration

#### Read Declaration

The read-only query returning the workflow's immutable [Declaration] exactly as supplied at [Instantiate]. Rejected [Not Known] or [Invalid Request].

Kind: Operation

```
read_declaration(workflow_id)
  answers declaration
  refuses invalid-request | not-known
```

```
Operation 47: [Read Declaration] MUST answer the workflow's declaration.
Operation 48: [Read Declaration] MUST NOT normalize the declaration.
Operation 49: [Read Declaration] MUST NOT reorder the declaration.
```

### Read Workflow

#### Read Workflow

The read-only query returning what a [Workflow] carries beside its declaration and its history: its [Instantiation Instant] and [Current State], and the [Subject Reference], [Workflow Metadata] and [Actor Reference] where it carries them. It answers [Not Known] for a [Workflow Id] that names no workflow, so it is also the read that says whether a workflow id stands. Rejected [Not Known] or [Invalid Request].

Kind: Operation

```
read_workflow(workflow_id)
  answers workflow
  refuses invalid-request | not-known
```

```
Operation 90: [Read Workflow] MUST answer the workflow's instantiation instant and current state.
Operation 91: [Read Workflow] MUST answer the subject reference, the instance metadata and the actor reference the workflow carries.
Operation 92: [Read Workflow] MUST NOT answer a field the workflow does not carry.
```

### Workflows About

#### Workflows About

The read-only query returning the [Workflow Id] of every workflow carrying a given [Subject Reference], a workflow in a terminal state among them, by [Instantiation Instant] earliest first, two sharing one by the commit that recorded each, and two recorded in one commit by workflow id. It answers an empty list for a [Subject Reference] no workflow carries. Rejected [Invalid Request] for a [Subject Reference] that is blank, over the string cap or not a string.

Kind: Operation

```
workflows_about(subject_ref)
  answers workflow_ids
  refuses invalid-request
```

```
Operation 80: [Workflows About] MUST answer the workflow id of EVERY workflow carrying the subject reference, a workflow whose current state IS IN the terminal states included.
Operation 82: [Workflows About] MUST order the answer by instantiation instant, earliest first.
Operation 83: [Workflows About] MUST order two workflows sharing an instantiation instant by recording commit, earliest first.
Operation 93: [Workflows About] MUST order two workflows sharing an instantiation instant and a recording commit by workflow id, ascending (Execution Contract Logic confinement 10).
Operation 84: [Workflows About] MUST answer an empty list for a subject reference no workflow carries (Identity 15).
Operation 85: IF the subject reference is malformed THEN [Workflows About] MUST answer invalid-request (Execution Contract Query 1, Execution Contract Query 5).
Operation 86: IF the subject reference is malformed AND the read of the workflow records fails THEN [Workflows About] MUST answer invalid-request (Execution Contract Read 1).
```

## What is and what should never be (Invariants)

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
  ```

## While something is so

### Clock semantics

```
Clock semantics 4: A firing instant MUST NOT bound a later history entry's firing instant.
```

### String policy

```
String 1: The atom MUST compare a string input byte-exactly.
String 2: The atom MUST NOT trim a string input.
String 3: The atom MUST NOT normalize a string input.
String 4: The atom MUST NOT case-fold a string input.
String 5: The atom MUST read a whitespace-only string input as blank.
String 6: The atom MUST read an absent string input as blank.
```

Term string input: workflow id, action, actor reference, subject reference, a state name, a guard OR a filter's value — every caller-supplied string this atom accepts.

Term whitespace strings: every string holding no code point outside the Unicode White_Space property, the empty string among them.

NOTE: watch the cap's measure (Term string cap, Term bounds).

NOTE: watch the cap's floor (Capability requirement 7).

---

## Optional

```
Capability requirement 1: The deployment MUST supply now at the seam.
Capability requirement 5: The deployment MUST supply the workflow records PER Execution Contract Database 1 through 7, Execution Contract Order 1, Execution Contract Read 1 through 4, Execution Contract Read 6, Execution Contract Refusal 1, Execution Contract Query 1 through 5, Execution Contract Input 1 through 4 and Execution Contract Conformance 9.
Capability requirement 7: The deployment MAY declare the string cap ONLY IF the string cap EXCEEDS 0 PER Execution Contract Input 2.
```

Term seam: the atom's I/O (input and output) boundary; the host injects the clock reading, the workflow id and the history entry id here.

Term transition: the atom's evaluation of one call against the workflow records.

Term now: the deployment's clock reading at the call, as Execution Contract Logic confinement 11 declares it.

Term string cap: the bound on a string input's length in Unicode code points, counted on the value as the call carries it, or on an id as the host allocates it; 1,024 code points where a deployment declares none.

## Needs

The bonds this atom needs, of a bond kind [Bonds](../bonds.md) states; which atom meets each is the app's choice.

Term need key: key actor id; pairs actor references.

## Offers

The bonds this atom offers, of a bond kind [Bonds](../bonds.md) states.

Term offer key: key workflow id; carried by workflows; calls Read Workflow.

Term offer key: key history entry id; carried by history entries; calls History.

## Left to others

```
Non-goal 1: A deployment needing a guard evaluated MUST compose the evaluating pattern.
Deleted: Non-goal 2. Non-goal 1 owns it: an approval a declared transition waits on is a guard's condition, and which pattern decides it is the app's choice.
Non-goal 3: The atom MUST NOT stand a workflow in two states at once.
Non-goal 4: The atom MUST NOT offer a fork declared transition.
Non-goal 5: The atom MUST NOT offer a join declared transition.
Non-goal 6: The atom MUST NOT nest a state inside a state.
Non-goal 7: A deployment needing a nested state MUST name the nested state as a flat state.
Non-goal 8: The atom MUST NOT share one declaration across two workflows.
Non-goal 9: The atom MUST NOT version a declaration.
Non-goal 10: A deployment needing a shared declaration template MUST compose a definition registry pattern.
Non-goal 11: The atom MUST NOT bind an actor reference to an actor.
Deleted: Non-goal 12. Non-goal 11 owns it: the atom binds no actor reference to an actor, and which pattern attests an actor is the app's choice.
Non-goal 13: The atom MUST NOT detect a rewrite under the database.
Deleted: Non-goal 14. Non-goal 13 owns it: the atom detects no rewrite, and which pattern makes records tamper-evident is the app's choice.
Non-goal 15: The atom MUST NOT bound a workflow's retention.
Deleted: Non-goal 16. Non-goal 15 owns it: the atom bounds no retention, and which pattern does is the app's choice.
Non-goal 17: The atom MUST NOT decide who may call an action.
Deleted: Non-goal 18. Non-goal 17 owns it: the atom decides no caller's authority; the app's permission does.
Non-goal 19: The atom MUST NOT decide which state a workflow ought to stand in.
Non-goal 20: The atom MUST NOT read two [Fire] calls carrying one workflow id and one action as one fire.
Non-goal 21: A deployment needing at-most-once firing MUST supply the deployment's own idempotency key.
Non-goal 22: A deployment needing a verifiable time anchor MUST compose a trusted timestamping pattern.
```

NOTE: the owners — a pattern that evaluates the guard (Non-goal 1, External check 1, Composition note 2, Composition note 3); a fork-join pattern (Non-goal 3 through 5); a definition registry pattern and the calling system (Non-goal 8 through 10); a pattern that attests an actor (Non-goal 11, External check 3); a pattern that makes records tamper-evident (Non-goal 13); a pattern that bounds retention (Non-goal 15); the app's permission (Non-goal 17); the composing system (Non-goal 19).

---

```
Composition note 2: A composing pattern MUST own a guard's evaluation.
Composition note 3: A composing pattern asserting guard satisfied MUST own the evidence.
Composition note 4: A composing pattern MUST own the authorization of a call.
Composition note 5: A composing pattern MUST own the attestation binding an actor reference.
Composition note 6: A composing pattern MUST own the tamper seal over a transition history.
Composition note 7: A composing pattern MUST own the retention of the workflow records.
Composition note 8: A composing pattern MUST own an idempotency key.
Composition note 9: A composing pattern MUST own a declaration template.
```

## Example

### Pharmaceutical batch qualification

A quality system instantiates a batch-release workflow. The declaration names `states: [sampled, tested, qualified, released, rejected]`, `initial state: sampled`, `terminal states: [released, rejected]`, and five declared transitions — `sampled --test--> tested`, `tested --qualify[qa_signoff]--> qualified`, `tested --reject--> rejected`, `qualified --release[qa_signoff]--> released`, `qualified --reject--> rejected`. `instantiate(declaration, actor_ref: "qa-system", subject_ref: "batch-x91")` → `wf_01HQ…`, standing in `sampled` with `next_sequence_number: 1` (Operation 4 through 8).

`fire("wf_01HQ…", "test", actor_ref: "lab-tech-r.chen")` → `tested`. One history entry lands at `sequence_number: 1` carrying `from_state: sampled`, `to_state: tested` (Operation 21 through 26, Operation 28).

`fire("wf_01HQ…", "qualify", actor_ref: "qa-lead-m.ross")` → guard-not-satisfied. The declared transition carries the `qa_signoff` guard and the call asserted nothing (Operation 17). The same call with `guard_satisfied: true` → `qualified`, and the entry records the assertion (Operation 29).

`fire("wf_01HQ…", "release", guard_satisfied: true, actor_ref: "qa-lead-m.ross")` → `released`. The workflow now stands in a terminal state.

### Workflows about one subject

A re-test of the batch starts a second workflow: `instantiate(declaration, subject_ref: "batch-x91")` → `wf_01HR…`. `workflows_about("batch-x91")` → `["wf_01HQ…", "wf_01HR…"]`: the first workflow, which stands in the terminal state `released`, is listed because it carries the subject reference and comes first because it began first (Operation 80 through 83). `workflows_about("batch-x00")` → `[]`, as it would for a batch that exists and has no workflow, since the atom does not confirm a subject (Identity 15, Operation 84); `workflows_about("")` → invalid-request, not `[]`: a blank subject reference is malformed, as a blank workflow id is for the actions that address a workflow (Operation 85, Operation 9).

### The audit question

An inspector asks whether the batch moved only through the approved sequence. `read_declaration("wf_01HQ…")` answers the map as supplied, unchanged since instantiation (Invariant 1.2). `history("wf_01HQ…")` answers three entries in sequence number order. Every entry's from state, action and to state triple appears in the declaration (Invariant 3.1), and replaying them from `sampled` arrives at `released`, which is what `current("wf_01HQ…")` answers (Invariant 7.3). The declaration bounds what *could* have happened and the history says what *did*; neither alone answers the inspector.

### Multi-workflow independence

Two batches run the same declaration as two workflows. Firing `test` on one moves one current state; the other is untouched, carries its own history and its own next sequence number. The declaration is a value each workflow holds, not a shared object (Non-goal 8).

### Regulated adversarial scenarios

- **Regulator audit.** A United States (US) Food and Drug Administration (FDA) inspector auditing under 21 CFR Part 11 and ISO (International Organization for Standardization) 9001 clause 8.5.1 asks the system to prove the batch moved only through approved states. Check 2.1 and Check 1.1 are the structural answer: every history entry matches a declared transition, and the declaration is the one supplied at instantiation. What the atom cannot answer is whether the `qa_signoff` guard was truly satisfied — `guard_satisfied: true` attests an assertion (Invariant 8.3), and the evidence lives in the record of the pattern that evaluates the guard.
- **Disputed transition.** An external party claims the workflow skipped a required state. The history is gap-free by sequence number (Invariant 6.2) and replays to the current state (Invariant 7.3), so a skipped state would have to appear as a declared transition that jumps it — which the declaration either names or does not. The claim resolves provably, against the declaration.
- **Breach investigation.** An investigator reconstructing an anomaly window filters the history by firing instant range and finds the entries generously bracketed. Because sequence number is dense and is the order source (Invariant 6.2, Operation 55), the investigator confirms the window's completeness against an unfiltered read rather than trusting the wall-time filter — a clock-skewed entry can fall outside the bracket and cannot fall out of the sequence.

---

## Source

- **FDA 21 CFR Part 11 (Electronic Records; Electronic Signatures)** — for FDA-regulated contexts: each declared state transition constitutes a regulated electronic record, and the transition history is the record of operator actions that section 11.10(e)'s secure, computer-generated, time-stamped audit trail must capture. Sections 11.50 (signature manifestations: the signer's name, the date and time, the meaning) and 11.70 (signatures linked to their records so they cannot be excised, copied or transferred to falsify one) bind electronic signatures, which this atom does not make: a pattern that attests the actor carries them. Invariants 3 (only-declared-transitions), 5 (history append-only and complete), and 7 (replay determinism) are the atom-level guarantees the regulated record depends on.
- **ISO 9001:2015 clause 8.5.1 (Control of production and service provision)** — requires that production and service provision activities be controlled by documented procedures, including controlled transitions at defined points in the process lifecycle. A State Machine workflow governing a production process is the documented process record section 8.5.1 anticipates; the declaration is the procedure map; the transition history is the per-workflow proof of execution.
- **BPMN 2.0 (Business Process Model and Notation 2.0 — an international standard for modeling business processes, published by the Object Management Group)** — a BPMN process model's states and sequence flows map directly to this atom's [States] and [Transitions]; a BPMN lane actor maps to an [Actor Reference] on [Fire] calls; a BPMN gateway condition maps to a [Guard] label on a declared transition.
- **HL7 FHIR Task resource** — the HL7 FHIR Task resource uses a declared workflow state machine (`Task.status`) with a defined lifecycle (its codes, in R4: draft, requested, received, accepted, rejected, ready, cancelled, in-progress, on-hold, failed, completed, entered-in-error; a common path runs `requested → accepted → in-progress → completed`). This atom is the general primitive the FHIR Task lifecycle is an instance of. A conforming FHIR Task implementation may derive its state enforcement from this atom's declared-transition model.
- **UML (Unified Modeling Language — the standard object-oriented modeling language published by the Object Management Group) statecharts and Harel statecharts** — the conceptual core of this atom. A UML statechart's states, transitions, events, and guards map directly to this atom's [States], [Transitions], [Action]s, and [Guard] labels. This atom is a flat (non-hierarchical, single-active-state) Mealy / Moore finite-state-machine (a finite state machine is a computational model with a finite set of states, a start state, a set of transitions, and one active state at a time) workflow; Harel nesting and parallel regions are out of scope (see Non-goal 3 through 7).
- **SOX (Sarbanes-Oxley Act — US law on corporate financial reporting and records integrity) section 404** — internal control over financial reporting. For financial process workflows (approval chains, journal entry processing, purchase order lifecycle), State Machine workflows are the process-control records SOX auditors query to verify that required control steps occurred in the declared order.
- **HIPAA (Health Insurance Portability and Accountability Act) section 164.530(j)** — documentation requirements for covered entities: policies and procedures must be documented. Workflows governing patient-care or administrative processes under HIPAA may use this atom's transition history as the documentation of process execution.
- **GDPR (General Data Protection Regulation of the European Union) Article 17** — the right to erasure. How long workflows are kept under it is the obligation of a pattern that bounds retention, not this atom's (Non-goal 15).
- **FRCP (Federal Rules of Civil Procedure) Rule 37(e)** — failure to preserve electronically stored information. How long workflows are kept under it is the obligation of a pattern that bounds retention, not this atom's (Non-goal 15).

Guard evaluation, non-repudiable attribution, tamper-evidence, and retention are explicitly composing-pattern obligations, not this atom's own standards obligations.

---

## Proof

### Generation acceptance

This atom's acceptance is provable: an external auditor clears it from the workflow records, with their committed versions (Execution Contract Generation acceptance 1), and the declaration.

#### Conformance checks

```
Check 1.1: An auditor MUST find EVERY workflow's declaration unchanged across EVERY committed version of the workflow (Invariant 1.1; Execution Contract Generation acceptance 1).
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
Check 8.1: An auditor MUST find history entry id, sequence number, from state, to state, action and firing instant on EVERY history entry (State 4).
Check 8.2: An auditor MUST find EVERY recorded actor reference non-blank (Invariant 9.1).
Check 8.3: An auditor MUST find no history entry whose firing instant PRECEDES the workflow's instantiation instant (Operation 20).
Check 10.1: An auditor MUST find EVERY workflow AND EVERY history entry a committed version holds standing in EVERY later committed version (Invariant 10.1, Invariant 10.2; Execution Contract Generation acceptance 1).
Check 9.1: An auditor MUST find the workflow ids [Workflows About] answers for a subject reference to be the workflow ids of EVERY workflow carrying that subject reference, ordered by instantiation instant, earliest first, and then by recording commit, earliest first, and then by workflow id, ascending (Operation 80, Operation 82, Operation 83, Operation 93).
```

Term cited: workflow id, history entry id, actor id: Declarations.

Term committed version: a record as it stood at the commit that wrote it, as Execution Contract Generation acceptance 1 declares it.

#### External checks

```
External check 1: A deployment needing a guard's condition confirmed MUST read the composing pattern that evaluates the guard (Invariant 8.2).
External check 2: A deployment needing a workflow's history entry count matched against the workflow's admitted fire count MUST capture the fire answers (Invariant 5.2).
External check 3: A deployment needing an actor reference bound to an actor MUST read the composing pattern's attestation (Non-goal 11).
```

### Vocabulary

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is* and its **Kind**.

Term actors: the atom; the host; the deployment; a composing pattern; a caller; an auditor; a regulator; an inspector; an investigator; the database.

Term records: workflow — one running workflow, carrying workflow id, a declaration, a current state, a transition history, next sequence number, an instantiation instant and the subject reference, instance metadata and actor reference [Instantiate] recorded. history entry — one recorded transition, carrying history entry id, sequence number, from state, to state, action, firing instant and the actor reference and guard satisfied [Fire] recorded. actor reference — the actor id a workflow or a history entry carries for the party who instantiated the workflow or fired the transition.

Term record verbs: identify, allocate, change, carry, stand, answer, record, append, set, take, raise, leave, own, match, normalize, reorder, interpret, confirm, admit, offer, evaluate, assert, fire, replay, reach, rest, share, precede, follow, compare, trim, case-fold, refuse, write, read, find, reconstruct, complete, equal, bound, nest, version, decide, compose, declare, wire, supply, remove, route, name, detect, bind, capture, count, order.

Term value sets: writing action = [Instantiate] | [Fire]. reading action = [Current] | [History] | [Read Declaration] | [Read Workflow] | [Workflows About]. action rejection = invalid-request | not-known | storage-failure. Instantiate rejection = invalid-declaration. Fire rejection = terminal | invalid-transition | guard-not-satisfied. History rejection = invalid-query. guard satisfied = true | false. filter axes = history entry id | sequence number | from state | to state | action | actor reference | firing instant.
Term bounds: string cap (the bound on a string input's length in Unicode code points, counted on the value as the call carries it, or on an id as the host allocates it, 1,024 where a deployment declares none).

Term cadences: empty.

Term qualifiers: migrated — rewritten in GRACE lang v0.40 (2026-09-12); converted to the bond shape in GRACE lang v0.75 (2026-11-26).

Term terms: workflow, history entry, subject reference, instance metadata, database instance, seam, transition, declared transition, declaration, states, initial state, terminal states, well-formed declaration, now, addressed action, writing action, reading action, current state, next sequence number, sequence number, firing instant, instantiation instant, resolved firing instant, resolved instantiation instant, actor reference, guard, guard satisfied, matched transition, cleared fire, firing check, firing fault, filter axes, admitted instantiate, admitted fire, string filter, range filter, admitted history, recording commit, committed version, string input, string cap, whitespace strings.

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a [Term] marker to its term entry heading above (kramdown
     auto-generates the heading anchors on GitHub Pages). Standard CommonMark /
     kramdown; no plugin required. -->

[Instantiate]: #instantiate
[Fire]: #fire
[Current]: #current
[History]: #history
[Read Declaration]: #read-declaration
[Read Workflow]: #read-workflow
[Workflows About]: #workflows-about
[Workflow]: #workflow
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
[History Entry Id]: #history-entry-id
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

## Status

`done — 2026-11-26` — see the Ledger.

<details markdown="block">
<summary>
    <h2 id="ledger" style="display: inline-block; margin-left: 1.5rem;">Ledger</h2>
</summary>

```
status: done — 2026-11-26
formal: verified — state-machine.als + 2 twins; coverage 2026-11-10 (unit formal: more coverage for the yes votes); state-machine.tla + 21 twins (across steps, 2026-11-11: one workflow under [Instantiate], offered every declaration of two state names, two actions and one guard with up to two declared transitions, and up to two admitted [Fire] calls, refusals in each refuses line's order, with what [History] and [Read Declaration] answer in every state they leave: Invariant 1.1 through 7.3, 8.1, 8.3, 9.1, 10.1 and 10.2); nothing testable in TLA+ for Invariant 8.2: it states a computation the atom does not make, and no model holds the condition a guard names; coverage 2026-11-11 (unit `atoms/state-machine.md formal layer`): no owed rows, 2026-11-11; [Workflows About] (Operation 80 through 86, Operation 93, Check 9.1) is not yet modelled: both models hold one workflow and the read ranges over several, so a model of two workflows under one subject reference is owed, 2026-11-17; model redraw deferred to Lean: state-machine.tla, Operation 87 through 89 (the History refusals' cases), 2026-11-26; model redraw deferred to Lean: state-machine.tla, Operation 90 through 92 ([Read Workflow]), 2026-11-26
last gate: 2026-11-26 — Final Critique 25, a delta round, frozen at 7a43e1e — foundational count 0 after the blind second triage, clean, one sample; Linus's rerun claimed one foundational (Check 9.1 carrying two obligations), placed rhetorical by the first triage and refining by the blind second, cured

open: none
```

</details>

<details markdown="block">
<summary>
    <h2 id="decisions" style="display: inline-block; margin-left: 1.5rem;">Decisions</h2>
</summary>

Decisions are kept in [the pattern's history](./state-machine.hist.md#decisions), one dated entry for each turn the pattern took; everything smaller lives in the commit that made it: `git log -- atoms/state-machine.md`.

</details>

NOTE: End of State Machine.
