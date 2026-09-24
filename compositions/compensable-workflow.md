---
title: Compensable Workflow
parent: Conceptual Compositions
nav_order: 12
has_toc: true
toc: true
---

# Compensable Workflow

<details markdown="block">
<summary>Table of contents</summary>
{: .text-delta }
1. TOC
{:toc}
</details>


## Summary

Compensable Workflow wires two building blocks — a workflow state machine (a process that moves through a declared sequence of steps, one step current at a time) and an event log (an add-only record of everything that happens) — so that a multi-step process can be undone *as a whole* even after some of its steps have already had real-world effects.

The trick is that each forward step is recorded together with a **compensating action**: a second step that reverses the first one's effect, the way a refund reverses a charge or a cancellation reverses a reservation. While everything is going well the compensable workflow just advances, step by step. If a step fails (or someone cancels), the compensable workflow runs the compensating actions for the steps that already finished, in reverse order — so the process ends up either fully done or fully undone, never stranded half-finished.

(A guarantee that appears only when the two building blocks are combined is called an *emergent guarantee*; here the headline one is **all-or-compensated** — no finished step's real-world effect is left standing after an abort.)

Because the engine that runs a compensable workflow normally *retries* steps that may have failed, every step and every compensation must be **idempotent** — safe to run more than once with the same result — which the composition secures with a per-effect key kept in two places: its own record of which effects it has written down, and the external system's declared promise to honour the key and not apply it twice.

This is the building block for order processing, travel and financial bookings, and supply-chain flows: anywhere a sequence of real, external actions needs to come out all-or-nothing without a single database transaction wrapping them.

---

## Intent

A great many business processes are a short sequence of local steps, each touching a different system and each producing a real effect in the world: an order-fulfillment flow reserves inventory, then charges a card, then schedules a shipment; a travel booking reserves a flight, then a hotel, then a car; a money transfer debits one account, then credits another. The steps are not in one database, so there is no single transaction spanning them. If a later step fails, the earlier steps have already happened — the card is charged, the inventory is held — and the process needs *all-or-nothing* semantics anyway: either the whole sequence commits, or its effects are undone.

A *distributed transaction* — a protocol that locks every participating system and commits or rolls back all of them atomically (two-phase commit and its kin) — is the textbook answer and the one real systems routinely refuse: it couples the services, holds locks across network boundaries, and fails badly under partition. The *compensable workflow* is the alternative. A compensable workflow runs the steps as independent local commits and, for each step, records a **compensating action** — a second forward operation that semantically reverses the first (a refund reverses a charge; a release reverses a reservation). On failure or cancel, the compensable workflow executes the compensating actions for the steps that already completed, in reverse order. The net effect is *eventual* all-or-nothing — the compensable workflow ends either committed or fully compensated — achieved without any distributed lock.

The two constituent atoms supply the halves this needs and neither supplies the whole. [State Machine](../atoms/state-machine.md) governs the step sequence: a deployment-declared set of states and transitions, exactly one current state at all times, and a transition history that is append-only, total-ordered, and replays deterministically to the current state (its Invariants 2, 5, 6, 7). But it only ever *advances or refuses* — it has no surface for reversing a transition that already fired, and it deliberately does not evaluate the conditions under which a step should be abandoned (its Invariant 8, guard-gating without evaluation). [Event Log](../atoms/event-log.md) supplies the durable, append-only, total-ordered record of what actually happened (its Invariants 1, 3) but takes no action on it. This composition is the wiring that turns the two into a compensable workflow: each forward step, on completing, appends an event that registers its compensating action; the compensable workflow's progress is derived from that log, and the State Machine current state is the spine brought to it; and an emergent *advance-or-compensate* action drives the compensable workflow forward step by step or, once a step fails or the compensable workflow is cancelled, runs the registered compensations in reverse.

The sharpest way to locate this pattern is against its structural sibling, [Undo History](./undo-history.md). Undo History is the same skeleton — a durable step log plus an all-or-nothing-ish guarantee — with the *opposite* reversal mechanism. Undo reverses an action by **replay-skip**: it recomputes the visible state as if the skipped event had never occurred. That works only when an action's entire effect lives inside the log, and Undo History Non-goal 10 names exactly where it stops working: a substrate whose actions send email or charge cards, where skipping the event undoes nothing in the world. That boundary is the compensable workflow's whole reason to exist. A charge is not undone by deleting the charge event — the money has already moved — so the compensable workflow reverses it by recording and running an explicit compensating action (a refund), which is itself a real, recorded forward effect. **Replay-skip versus compensating action** is the one load-bearing difference between the two patterns; everything else is shared.

This composition is **not a new primitive.** State Machine and Event Log are unchanged; the compensating action is a *sub-atomic recorded closure* — a captured operation-plus-arguments paired to a forward step, the same shape Undo History's compensating events take — not an atom in its own right. The compensable workflow's progress carries no state that is not derivable from the step/compensation log. It is also, deliberately, **not a distributed-transaction protocol** and **not the durable-execution engine** that runs it. How the steps are driven and retried — a Temporal-style replay engine, a message queue, hand-rolled orchestration code — and whether the steps coordinate through a central orchestrator or by reacting to each other's events (*orchestration versus choreography*) are **realization choices below the contract**: a compensable workflow is one of the named realizations of the distributed-atomicity obligation (database transaction / compensable workflow / queue) the obligation-realization boundary sketched in [`working-ideas/outbound-contract-ports.md`](../working-ideas/outbound-contract-ports.md), a working idea the Execution Contract does not yet carry. What this spec owns is the part that boundary does *not* capture — the step-to-compensation pairing, the reverse-order compensation discipline, and the two emergent invariants (all-or-compensated, and idempotency under retry). A refund is a domain-meaningful act with its own recorded effect, not the transparent rollback of a database transaction; that domain meaning is what earns this a composition spec rather than a single line in the realization registry.

---

## Composes

- **[State Machine](../atoms/state-machine.md)** — the step-sequence spine the progress is brought to.
- **[Event Log](../atoms/event-log.md)** — the step log, the compensable workflow's one durable record.

```
Composes 1: EXACTLY ONE State Machine instance MUST serve the composition.
Composes 2: EXACTLY ONE State Machine workflow MUST serve a compensable workflow.
Composes 3: EXACTLY ONE Event Log instance MUST serve a compensable workflow.
Composes 4: The composition MUST change the spine through State Machine's fire alone.
Composes 5: The composition MUST record a compensable workflow's events through Event Log's append alone.
Composes 6: The composition MUST NOT reverse a fired transition.
Composes 7: The composition MUST NOT read the spine for a compensable workflow's progress.
Composes 8: The composition MUST decide EVERY compensation at the composition's own boundary.
Composes 9: The composition MUST NOT change a constituent's spec.
Composes 10: The composition MUST inherit a constituent's invariants PER Execution Contract Conformance 8.
```

Term composition: this pattern's wiring of [State Machine](../atoms/state-machine.md) and [Event Log](../atoms/event-log.md) — the step log, the five actions and the replay.

Term constituents: [State Machine](../atoms/state-machine.md), [Event Log](../atoms/event-log.md).

Term compensable workflow: one run of the composition, from [Start Compensable Workflow] to a terminal outcome, served by one spine and one step log.

Term spine: the State Machine workflow serving a compensable workflow — the progress's follower, never the progress's source.

Term step log: the Event Log instance serving a compensable workflow — the compensable workflow's sole truth.

WHY:
Composes 1 is what the keyed lookup already assumed. The compensable workflow id is the id State Machine issues for the spine, unique within one State Machine instance, and [Advance] finds a compensable workflow through State Machine's own lookup of that id (Action wiring 9); two State Machine instances behind one composition would make the id ambiguous and the lookup a guess. One State Machine instance holds every spine, one workflow in it per compensable workflow; one Event Log instance per compensable workflow holds the step log.

Composes 4 through 7 are the whole composition stated from four sides. The spine only ever advances: State Machine has no surface for reversing a transition that already fired, so a compensation is a *forward* transition to a compensating state, never an undo of the step it compensates. The step log only ever grows. And the two are not read alike: the log carries the progress, the spine is brought to it, and a read that asked the spine could be one owed `fire` behind (Composition state 1).

Composes 8 is State Machine's Invariant 8 met from the other side. The atom gates a guarded transition on the caller's assertion and never evaluates the condition, so the decision to abandon a compensable workflow and begin compensating has to be made somewhere — here, at the composition's boundary, from verdicts the targets returned.

Composes 10 is the preservation claim the prose once carried as its own invariant. What the composition leans on beyond the blanket is named where it is used: State Machine's declared-transition discipline, single current state, terminal absorption and replay-deterministic history (State Machine Invariant 2, 4, 5 and 7), and State Machine Invariant 10.3 — a `fire` that answers storage-failure left no partial record — which is what lets the re-entry arm fire a missing transition from the log; Event Log's append-only record and total order (Event Log Invariant 1 and Event Log Invariant 3), and `append`'s storage-failure arm. What neither grants is declared rather than assumed. State Machine serializes `fire` per workflow and declares it non-idempotent, and grants no critical section spanning an effect, an append and a `fire`; Event Log Durability 2 leaves persistence across a restart to the deployment, it enumerates no instances, and it exposes a clock only as each event's recording instant. The composition declares the first two in Capability requirement, uses the third nowhere, and takes the start instant from the fourth.

The **[Compensating Action]** itself is *sub-atomic* — a recorded closure (the reversing operation plus the arguments captured at the step's completion), the same primitive Undo History uses for its compensating events, not a freestanding atom.

Two neighbours, named here so the boundaries are explicit. [Execute Gated Workflow](./execute-gated-workflow.md) is the **sibling over the same spine**: it also wires State Machine, but for *human-approval gating of forward progress* (a transition fires only after a real Approval Step is Approved). This composition wires the same spine for *failure-compensation of completed steps*. The two are orthogonal — a regulated compensable workflow would compose both. [Undo History](./undo-history.md) is the **complement**, reversing by replay-skip where this composition reverses by compensating action (see Intent). The [Audit Trail](./audit-trail.md) regulated-audit substrate is deliberately *not* composed in this base shape (Non-goal 12).

---
## Composition logic

### Composition state

```
Composition state 1: The step log IS AUTHORITATIVE FOR a compensable workflow's progress.
Composition state 2: The composition MUST derive EVERY log projection from the step log PER the replay.
Composition state 3: The composition MUST NOT store a log projection.
Composition state 4: The composition MUST store EXACTLY ONE compensable workflow record PER compensable workflow.
Composition state 5: A compensable workflow record MUST carry the compensable workflow id, the definition reference, the subject reference AND the start instant.
Composition state 6: The composition MUST NOT change a compensable workflow record.
Composition state 7: The composition MUST rebuild a compensable workflow record from the start event alone.
Composition state 8: The composition MUST take the compensable workflow id from State Machine's instantiate.
Composition state 9: The composition MUST read the start instant from the start event's recording instant.
Composition state 10: The composition MUST NOT read a clock.
Composition state 11: The composition MUST derive a step's effect key from the compensable workflow id AND the step.
Composition state 12: The composition MUST derive a compensation's effect key from the compensable workflow id, the step AND the compensation.
Composition state 13: The composition MUST NOT mint an effect key PER attempt.
```

Term log projection: the progress, the completed steps, the unresolved attempts, the compensation registry and the applied effects — each a derived index by the section titled Composition state in `execution-contract.md`, rebuilt by the replay and stored nowhere.

Term progress: the phase, the current step and, once reached, the outcome — how far a compensable workflow has got.

Term compensable workflow store: the set of compensable workflow records — a projection of the start events, never a second truth.

Term compensable workflow id: the State Machine instance id issued for the spine, which names the compensable workflow for the compensable workflow's whole life.

Term definition: the deployment-declared step and compensation sequence a [Start Compensable Workflow] call carries.

Term definition reference: the opaque reference to the definition the compensable workflow record keeps.

Term start instant: the recording instant Event Log stamped on the start event.

Term completed steps: the steps whose step completion event landed and whose compensation run event has not, newest last.

Term unresolved attempts: the set of attempt markers no later resolving event answers — one member under the reverse compensation order, several under the parallel compensation order.

Term compensation registry: the map from a completed step to the step's compensation reference and captured inputs, as the step completion event recorded both.

Term applied effects: the set of effect keys a step completion event or a compensation run event carries — the effects already applied *and recorded*.

Term effect key: the at-most-once key an effect runs under; the same key on every attempt of one effect — an [Effect Key].

WHY:
Composition state 1 through 3 are why this is a composition rather than a new stateful atom: the composition holds no truth the log does not. Every log projection is a derived index in the Contract's sense, and the replay is the named rebuild. The State Machine current state is a copy of the same progress that the re-entry arm keeps level with the log (Action wiring 12) — it may lawfully lag by one owed `fire`, which is why nothing reads it for progress (Composes 7).

The compensable workflow store is a convenience, and Composition state 7 is the proof: every field it carries is on the start event. It carries no outcome. An earlier draft listed the terminal outcome among fields *set once at start and immutable thereafter* — a field set at the end, written by no step of any action, and declared unchanging from the beginning. The outcome is a log projection like the progress it belongs to, and the replay reads it from the terminal marker. The keyed lookup behind not-known is State Machine's own lookup of the compensable workflow id, not this store; the store's *set* — every compensable workflow that exists — is rebuilt by no enumeration either constituent offers, since the composition runs one Event Log instance per compensable workflow and the atom enumerates no instances (Non-goal 15).

The applied effects are the **record-side** half of the at-most-once discipline behind Invariant 7. A key present means the effect landed *and its record landed*, so the re-entry arm skips the effect. The set cannot see the one window the discipline exists for — an effect that landed and whose record did not — because the record it is built from is the one that failed; that window belongs to the **effect-side** half, the target honouring the key (Capability requirement 15), and to the attempt marker that makes the window visible in the records. Composition state 11 through 13 keep the key stable across retries, so a retried effect collides with its own prior key rather than escaping the dedup; a random per-attempt key would defeat the ledger.

#### Replay

```
Replay 1: The replay MUST read EVERY event of the step log in sequence number order.
Replay 2: IF no compensation onset event EXISTS THEN the replay MUST derive forward as the phase.
Replay 3: IF a compensation onset event EXISTS THEN the replay MUST derive compensating as the phase.
Replay 4: IF a standing halt EXISTS THEN the replay MUST derive halted as the phase.
Replay 5: IF a commit event EXISTS THEN the replay MUST derive committed as the outcome.
Replay 6: IF a compensation close event EXISTS THEN the replay MUST derive compensated as the outcome.
Replay 7: The replay MUST add a step completion event's step to the completed steps.
Replay 8: The replay MUST remove a compensation run event's step from the completed steps.
Replay 9: The replay MUST map a step completion event's step to the event's compensation reference AND captured inputs.
Replay 10: The replay MUST add the effect key of EVERY completion record to the applied effects.
Replay 11: The replay MUST hold an attempt marker in the unresolved attempts ONLY IF no resolving event EXISTS for the attempt marker.
Replay 12: The replay MUST NOT read a halt event as a resolving event.
Replay 13: The replay MUST read a step completion event as an applied effect.
Replay 14: The replay MUST produce one progress PER step log.
```

Term replay: the named rebuild procedure Replay 1 through 14 state — the composition's only route from the step log to a log projection.

Term standing halt: the step log's newest halt event, where no resume marker follows the halt event.

Term named step: a step the standing halt names.

Term resolving event: an event following the attempt marker in sequence number order — a completion record or a compensation failure event carrying the attempt marker's effect key, or a compensation onset event naming the attempt marker's step.

WHY:
Replay 2 through 4 place the phase, and Replay 4 is the one to read twice. A halt event sends the compensable workflow to the non-terminal holding state; the resume markers the halted arm appends end the standing halt, and the phase the compensable workflow returns to is simply the one Replay 2 and Replay 3 derive — forward where no compensation onset event exists, compensating where one does. The halt event names the phase it left, and the two always agree.

Replay 12 is the half of the holding state an operator most needs. A halt event **parks** the attempts it names; it does not resolve them, so a parked attempt stays in the unresolved attempts through the whole of the halted phase, and [Cancel] stays refused (Action wiring 72).

Replay 13 rests on the success-only completion rule: a step completion event is written only when the step's verdict was applied (Action wiring 21), so every recorded completion reflects a real external effect. An attempt marker, by contrast, reflects only that an effect was *about to be* run — which is exactly the fact a crashed or storage-failed invocation would otherwise take with it. The replay itself rests on the step log surviving the restart it is replayed after, which the atom does not promise and Capability requirement 12 declares.

### Capability requirement

```
Capability requirement 1: IF the compensation order EQUALS blank THEN the composition MUST read the compensation order as reverse.
Capability requirement 2: IF the compensation failure policy EQUALS blank THEN the composition MUST read the compensation failure policy as halt-and-surface.
Capability requirement 3: A deployment MUST set the step completion bound.
Capability requirement 4: IF the step completion bound EQUALS blank THEN the composition MUST refuse to start.
Capability requirement 5: The host MUST supply a critical section keyed by compensable workflow id.
Capability requirement 6: The host MUST exclude a second holder of one compensable workflow's critical section across EVERY node.
Capability requirement 7: The host MUST release a critical section on the holder's return.
Capability requirement 8: The host MUST release a critical section on the holder's death.
Capability requirement 9: The lease length MUST NOT EXCEED the step completion bound.
Capability requirement 10: The step completion bound MUST NOT EXCEED the lease length.
Capability requirement 11: IF the critical section EQUALS blank THEN the composition MUST refuse to start.
Capability requirement 12: A deployment MUST hold the step log durable across a restart AND a storage-engine failure.
Capability requirement 13: A deployment MUST hold the spine durable across a restart AND a storage-engine failure.
Capability requirement 14: IF the constituent store durability EQUALS blank THEN the composition MUST refuse to start.
Capability requirement 15: A deployment MUST front EVERY target a definition names with the target key discipline.
Capability requirement 16: A deployment MUST set the effect key horizon.
Capability requirement 17: The longest attempt gap MUST NOT EXCEED the effect key horizon.
Capability requirement 18: IF the target key discipline EQUALS blank THEN the composition MUST refuse to start.
Capability requirement 19: IF the captured input cap EQUALS blank THEN the composition MUST read the definition's input envelopes as the cap.
```

Term compensation order: reverse | parallel — the order a compensating phase unwinds the completed steps in; reverse, the default, is last-in-first-out, the newest completed step first.

Term compensation failure policy: halt-and-surface | continue — what a compensating phase does with a compensation the target definitely refused; halt-and-surface is the default.

Term step completion bound: the longest an [Advance] may run between taking the critical section and the invocation's last write — the critical section's lease length, and the terminus of every in-invocation re-attempt.

Term critical section: the host-supplied mutual exclusion keyed by compensable workflow id, taken by every section-taking action before the action's first read.

Term lease length: the duration the host holds a critical section implemented as a lease.

Term constituent store durability: the deployment's declaration that the step log and the spine persist across process restart and storage-engine failure — an event whose append answered an event id is readable afterwards, and a `fire` that answered a state is in the history.

Term target: a system a step's effect or a compensating action reaches — a payment processor, an inventory service, a carrier.

Term target key discipline: a target's promise that a second call under an effect key the target applied is not applied again and answers the original result, the captured inputs included, for the effect key horizon from the first call.

Term effect key horizon: the duration the targets keep an effect key's result.

Term longest attempt gap: the longest interval between two attempts of one effect key, a rest in the halted phase included.

Term captured input cap: the largest input envelope a definition may declare for a compensating action — a byte bound over the envelope's declared fields.

WHY:
Capability requirement 5 through 11 are the one declaring source for every serialization claim on this page. State Machine serializes `fire` per workflow and Event Log serializes `append` per instance, and neither declares a critical section spanning the applied-effects pre-check, the external effect, the append and the `fire`. The durable-execution engine may deliver one [Advance] twice at once, and without this critical section both deliveries read the same log, both find the key absent, and both run the charge before either appends.

Capability requirement 9 and Capability requirement 10 together say *exactly*: at least the bound, so an invocation inside the invocation's bound is never evicted, and no longer, so a stalled-but-alive holder keeps a retry off the compensable workflow for a bounded time. The composition reads no clock (Composition state 10), so it cannot time its own re-attempts; the host that holds the lease tells the invocation the lease is gone, and from that signal the invocation makes no further write (Action wiring 3). **Lease = bound = terminus**, and **lost = expired = yield** (Action wiring 6), so there is one rule and no invocation ever writes on a critical section it cannot show it holds. Under the parallel compensation order the one invocation holding the critical section runs several compensations at once, each under its own effect key and its own compensation attempt event; the critical section is per compensable workflow, not per key, because a second invocation is the writer the rule forbids.

Capability requirement 12 through 14 are the durability neither atom grants. Event Log Durability 2 gives persistence across a restart to the deployment, and State Machine State 14 makes the next sequence number's survival a duty on the implementor; every rebuild by replay, every retry after a crash, and Invariant 1, Invariant 2 and Invariant 7 rest on it.

Capability requirement 15 through 18 are the effect-side half of Invariant 7. The mechanism is the idempotency-key discipline of the [Idempotent Reservation](./idempotent-reservation.md) peer; a deployment fronts each target with that composition or with a target-native equivalent — a payment processor's idempotency key. Idempotent Reservation's own guarantee is window-bounded and conditional on a per-token critical section and a durable result memo (Idempotent Reservation Invariant 8.1), and this page carries those conditions to the deployment. The horizon is the deployment's declaration that the targets' key retention covers the longest gap between two attempts of one key, including the time a compensable workflow rests in the halted phase awaiting repair. A re-attempt past the horizon is outside the guarantee, and an operator who resumes a halted compensable workflow past the horizon is performing an operational act the composition does not vouch for — the honest reading of *at most once* over an unbounded holding state, made explicit by the horizon assertion (Primitive policy 7).

Whether the host's critical section excludes across nodes and honours the lease length, whether the stores survive, and whether the targets honour the key and for how long, are each an external check (External check 1 through 5). The durable-execution engine that drives and retries steps is not configured here (Wiring decision 5).

### Primitive policy

```
Primitive policy 1: The composition MUST answer invalid-request for a blank compensable workflow id.
Primitive policy 2: [Start Compensable Workflow] MUST answer invalid-request for a blank subject reference.
Primitive policy 3: [Start Compensable Workflow] MUST answer invalid-request for a blank definition.
Primitive policy 4: [Start Compensable Workflow] MUST answer invalid-request for a definition carrying a blank compensation reference.
Primitive policy 5: The composition MUST NOT run an effect under a blank effect key.
Primitive policy 6: The composition MUST answer invalid-request for a blank supplied reason.
Primitive policy 7: IF the phase EQUALS halted AND the horizon assertion DOES NOT EQUAL true THEN [Advance] MUST answer invalid-request.
Primitive policy 8: IF the phase DOES NOT EQUAL halted THEN [Advance] MUST ignore the horizon assertion.
Primitive policy 9: IF the phase EQUALS halted AND an overflowed step IS IN the named steps AND the compensation inputs EQUALS blank THEN [Advance] MUST answer invalid-request.
Primitive policy 10: [Advance] MUST answer invalid-request for oversized inputs.
Primitive policy 11: IF the phase DOES NOT EQUAL halted THEN [Advance] MUST ignore the compensation inputs.
Primitive policy 12: [Start Compensable Workflow] MUST answer invalid-definition for a definition carrying an unmarked irreversible step.
Primitive policy 13: A definition MUST declare an input envelope for EVERY compensating action.
Primitive policy 14: An input envelope MUST NOT EXCEED the captured input cap.
Primitive policy 15: [Start Compensable Workflow] MUST NOT instantiate the spine BEFORE sizing the largest admitted record against the payload cap.
Primitive policy 16: IF the largest admitted record EXCEEDS the payload cap THEN [Start Compensable Workflow] MUST answer invalid-payload.
Primitive policy 17: The composition MUST answer Event Log's invalid-payload at [Start Compensable Workflow] alone.
Primitive policy 18: The composition MUST NOT write captured inputs beyond the step's input envelope.
Primitive policy 19: IF a target answers oversized inputs THEN a forward advance MUST append the step completion event carrying the captured inputs truncated to the input envelope.
Primitive policy 20: IF a target answers oversized inputs THEN a forward advance MUST set the truncation mark to true.
Primitive policy 21: IF a target answers oversized inputs THEN a forward advance MUST append a halt event naming the forward phase AND the step.
Primitive policy 22: IF a target answers oversized inputs THEN a forward advance MUST answer `arguments-overflow`.
Primitive policy 23: A compensating advance MUST run an overflowed step's compensating action with the compensation inputs the resuming [Advance] supplied.
Primitive policy 24: A compensation run event for an overflowed step MUST carry operator as the input source.
Primitive policy 25: The composition MUST NOT compensate an overflowed step from the truncated captured inputs.
```

Term supplied reason: a reason the call carries, whatever the reason's content; an absent reason is not supplied.

Term horizon assertion: true | false — the operator's assertion, on an [Advance] from the halted phase, that a parked attempt's effect key is still inside the effect key horizon at the target.

Term compensation inputs: the reversal inputs an operator supplies on the [Advance] that resumes a compensable workflow halted on an overflowed step.

Term overflowed step: a step whose step completion event carries the truncation mark set to true.

Term oversized inputs: inputs carrying a field the step's input envelope does not declare, or a field over the field's byte bound.

Term input envelope: the fields a definition declares for a compensating action's captured inputs, with a byte bound on each.

Term captured inputs: the reversal inputs a target answered for a step's effect and the step completion event recorded — the `charge_id` a refund needs.

Term largest admitted record: the larger of a step completion event carrying the compensation reference, the full input envelope and the effect key, and a compensation run event — the largest record the definition lets a compensable workflow write.

Term effect step: a declared step whose result escapes the compensable workflow's own step log — a charge, a shipment, an outbound message.

Term step marker: read-only | pivot — read-only for a step with no external effect to reverse; pivot for the commit point past which the compensable workflow only rolls forward.

Term unmarked irreversible step: an effect step declaring no compensating action and no step marker.

Term roll-forward step: a step marked pivot, or a step following a step marked pivot.

Term truncation mark: the step completion event's field saying the captured inputs were truncated to the input envelope.

Term input source: recorded | operator — whose inputs a compensation run reversed with: the step completion event's, or the compensation inputs an operator supplied.

WHY:
Primitive policy 7 is the operator's act made explicit. The horizon assertion is the operational act the effect key horizon says the composition does not vouch for, stated at the signature and kept on the resume marker (Event schema 6), so the records say who judged the key still honoured — an operator, not the composition.

Primitive policy 12 is the compensable-workflow analog of Execute Gated Workflow's rule that a gate specification must cover every guarded transition. All-or-compensated (Invariant 4) cannot be promised for an effect nothing can reverse, so a definition that asks for one is refused before it starts.

Primitive policy 15 through 18 size the completion record at [Start Compensable Workflow], before any effect. A record refused after the charge is a charge with no record and nothing to compensate (the section titled *An outcome is sized before the intent* in `pressure-testing.md`); refused at the validation position, where nothing has committed, it is only a definition the deployment must fix. The completion position then writes only the declared envelope, so the record is bounded by construction and Event Log's invalid-payload is unreachable after an effect has landed.

Primitive policy 19 through 25 are the one landing for a target that answers more than the envelope holds. The effect landed and is recorded, truncated, with the truncation mark set; the compensable workflow halts from the forward phase; and the compensation's inputs become the operator's, supplied on the resuming [Advance] and recorded as the input source on the eventual compensation run event. The registry never holds a truncated input set as if it were whole.

### Action wiring

```
start_compensable_workflow(definition, subject_ref, optional reason)
  answers compensable_workflow_id
  refuses invalid-definition | invalid-payload | invalid-request | storage-failure

advance(compensable_workflow_id, optional within_horizon, optional compensation_arguments)
  answers advance result
  refuses not-known | already-terminal | invalid-request | step-failed | arguments-overflow | effect-indeterminate(indeterminate reason) | spine-fault | storage-failure(advance failure position)

cancel(compensable_workflow_id, optional reason)
  answers cancel result
  refuses not-known | already-terminal | invalid-request | step-unresolved | spine-fault | storage-failure(cancel failure position)

read_progress(compensable_workflow_id)
  answers progress
  refuses not-known | invalid-request

read_log(compensable_workflow_id, query)
  answers the matching events
  refuses not-known | invalid-query | invalid-request
```

Term advance result: the step the call acted on and the progress the call left.

Term cancel result: compensating | halted | roll-forward — the phase a [Cancel] leaves the compensable workflow in, or roll-forward where the compensable workflow completed a roll-forward step.

Term indeterminate reason: no-verdict | target-unknown — no-verdict where no reply, a timeout or a transport failure left the effect's verdict unknown to the composition; target-unknown where the target recognized the effect key and had lost the effect's outcome.

Term advance failure position: none | effect-landed | spine — where a storage-failure sat: none, nothing owed and no effect of the invocation stands unrecorded; effect-landed, an effect of the invocation may stand with no record the step log carries, and the attempt marker records that the effect may; spine, the record landed and the `fire` after the record wrote nothing.

Term cancel failure position: none | spine — the two positions a [Cancel] can land, since a [Cancel] runs no effect.

```
Action wiring 1: A section-taking action MUST read the step log ONLY AFTER taking the compensable workflow's critical section.
Action wiring 2: An invocation MUST write ONLY IF the invocation holds the critical section.
Action wiring 3: An invocation whose critical section expired MUST NOT write.
Action wiring 4: An invocation whose critical section expired MUST NOT take the critical section again.
Action wiring 5: An invocation whose critical section expired MUST discard an effect reply still in flight.
Action wiring 6: An invocation MUST read a critical section lost to a host fault as an expired critical section.
Action wiring 7: A validated start MUST serialize through State Machine's instantiate.
Action wiring 8: The composition MUST fire a transition-bearing event's declared transition ONLY AFTER appending the transition-bearing event.
Action wiring 9: The composition MUST answer not-known for a compensable workflow id State Machine's current answers not-known for.
Action wiring 10: IF a terminal marker EXISTS THEN [Advance] MUST answer already-terminal.
Action wiring 11: [Advance] MUST NOT run an effect BEFORE running the re-entry arm.
Action wiring 12: IF an owed transition EXISTS THEN the re-entry arm MUST fire the owed transition.
Action wiring 13: The re-entry arm MUST NOT run an effect for an owed transition.
Action wiring 14: The re-entry arm MUST NOT re-run an unresolved attempt BEFORE firing the owed transition.
Action wiring 15: The re-entry arm MUST re-run the effect of EVERY unresolved attempt under the attempt's own effect key.
Action wiring 16: The re-entry arm MUST re-run the unresolved attempts PER the compensation order.
Action wiring 17: The re-entry arm MUST take a re-run's captured inputs from the target's answer to the re-run.
Action wiring 18: The re-entry arm MUST NOT take captured inputs from the invocation's memory.
Action wiring 19: A re-run MUST follow the verdict rules of the phase the re-run's attempt marker belongs to.
Action wiring 20: The composition MUST read a verdict as failed ONLY IF the target answered the failure.
Action wiring 21: The composition MUST append a step completion event ONLY IF the effect verdict EQUALS applied.
Action wiring 22: A forward advance MUST append a step attempt event for the next step.
Action wiring 23: A forward advance MUST run the next step's effect ONLY AFTER appending the step attempt event.
Action wiring 24: A forward advance MUST run the next step's effect under the step's effect key.
Action wiring 25: IF the effect verdict EQUALS applied THEN a forward advance MUST append a step completion event.
Action wiring 26: IF the effect verdict EQUALS failed AND the step IS NOT IN the roll-forward steps THEN a forward advance MUST append a compensation onset event naming the step.
Action wiring 27: IF the effect verdict EQUALS failed AND the step IS IN the roll-forward steps THEN a forward advance MUST re-attempt the effect under the step's effect key WITHIN the step completion bound.
Action wiring 28: IF the step completion bound elapses on a failed roll-forward step THEN a forward advance MUST append a halt event naming the forward phase AND the step.
Action wiring 29: IF the effect verdict EQUALS failed THEN a forward advance MUST answer step-failed.
Action wiring 30: A forward advance MUST NOT append a compensation onset event for a roll-forward step.
Action wiring 31: IF no next step EXISTS THEN a forward advance MUST append a commit event.
Action wiring 32: A compensating advance MUST compensate the pending compensations PER the compensation order.
Action wiring 33: A compensating advance MUST append a compensation attempt event for EVERY compensating action the compensating advance runs.
Action wiring 34: A compensating advance MUST run a compensating action ONLY AFTER appending the compensation attempt event.
Action wiring 35: A compensating advance MUST run a compensating action under the compensation's own effect key.
Action wiring 36: IF the effect verdict EQUALS applied THEN a compensating advance MUST append a compensation run event.
Action wiring 37: IF the effect verdict EQUALS failed AND the compensation failure policy EQUALS halt-and-surface THEN a compensating advance MUST append a halt event naming the compensating phase AND the step.
Action wiring 38: IF the effect verdict EQUALS failed AND the compensation failure policy EQUALS continue THEN a compensating advance MUST append a compensation failure event.
Action wiring 39: The composition MUST NOT skip a failed compensation.
Action wiring 40: IF no pending compensation EXISTS AND no unresolved attempt EXISTS AND no standing failure EXISTS THEN a compensating advance MUST append a compensation close event.
Action wiring 41: IF no pending compensation EXISTS AND no unresolved attempt EXISTS AND a standing failure EXISTS THEN a compensating advance MUST append a halt event naming the compensating phase AND EVERY step a standing failure names.
Action wiring 42: The invocation MUST re-attempt an indeterminate effect under the effect's own effect key WITHIN the step completion bound.
Action wiring 43: IF the step completion bound elapses on an indeterminate effect THEN the invocation MUST answer effect-indeterminate naming no-verdict.
Action wiring 44: The invocation MUST NOT append a resolving event for an indeterminate effect.
Action wiring 45: The composition MUST NOT append a compensation onset event on an indeterminate verdict.
Action wiring 46: The invocation MUST re-attempt an unknown effect under the effect's own effect key WITHIN the step completion bound.
Action wiring 47: IF the step completion bound elapses on an unknown effect THEN the invocation MUST append a halt event naming the phase AND the step.
Action wiring 48: IF the step completion bound elapses on an unknown effect THEN the invocation MUST answer effect-indeterminate naming target-unknown.
Action wiring 49: A halted advance MUST append a resume marker for EVERY named step.
Action wiring 50: A halted advance MUST fire the transition back to the phase the standing halt names ONLY AFTER appending the resume markers.
Action wiring 51: A resumed attempt MUST proceed as an unresolved attempt.
Action wiring 52: IF Event Log's append answers storage-failure for a completion record THEN the invocation MUST re-attempt the append WITHIN the step completion bound.
Action wiring 53: IF the step completion bound elapses on a completion record's append THEN the invocation MUST answer storage-failure naming effect-landed.
Action wiring 54: IF Event Log's append answers storage-failure for a marker AND no unrecorded effect EXISTS THEN the invocation MUST answer storage-failure naming none.
Action wiring 55: IF Event Log's append answers storage-failure for a marker AND an unrecorded effect EXISTS THEN the invocation MUST answer storage-failure naming effect-landed.
Action wiring 56: IF State Machine's fire answers storage-failure for a landed transition-bearing event THEN the invocation MUST answer storage-failure naming spine.
Action wiring 57: IF State Machine's fire answers a spine refusal for a landed transition-bearing event THEN the invocation MUST append a fault halt carrying the finding.
Action wiring 58: IF State Machine's fire answers a spine refusal for a landed transition-bearing event THEN the invocation MUST NOT fire a further transition.
Action wiring 59: IF State Machine's fire answers a spine refusal for a landed transition-bearing event THEN the invocation MUST answer spine-fault.
Action wiring 60: A forward advance landing a step completion event MUST answer the advance result.
Action wiring 61: A compensating advance landing a compensation run event MUST answer the advance result.
Action wiring 62: A validated start MUST instantiate the spine with the definition's steps AND compensations as the declared transitions.
Action wiring 63: A validated start MUST instantiate the spine with not-started as the initial state.
Action wiring 64: A validated start MUST append the start event ONLY AFTER State Machine's instantiate answers.
Action wiring 65: A validated start MUST write the compensable workflow record ONLY AFTER appending the start event.
Action wiring 66: IF State Machine's instantiate OR Event Log's append answers storage-failure THEN [Start Compensable Workflow] MUST answer storage-failure.
Action wiring 67: IF [Start Compensable Workflow] answers storage-failure THEN [Start Compensable Workflow] MUST NOT answer a compensable workflow id.
Action wiring 68: An admitted start MUST answer the compensable workflow id State Machine's instantiate issued.
Action wiring 69: IF an owed transition EXISTS THEN [Cancel] MUST fire the owed transition.
Action wiring 70: [Cancel] MUST NOT append a compensation onset event BEFORE firing the owed transition.
Action wiring 71: IF a terminal marker EXISTS THEN [Cancel] MUST answer already-terminal.
Action wiring 72: IF an unresolved attempt EXISTS THEN [Cancel] MUST answer step-unresolved.
Action wiring 73: IF a step completion event for a roll-forward step EXISTS THEN [Cancel] MUST answer roll-forward.
Action wiring 74: [Cancel] MUST append a compensation onset event ONLY IF the phase EQUALS forward.
Action wiring 75: IF the phase EQUALS compensating THEN [Cancel] MUST answer compensating.
Action wiring 76: IF the phase EQUALS halted THEN [Cancel] MUST answer halted.
Action wiring 77: An admitted cancel MUST answer compensating.
Action wiring 78: [Read Progress] MUST derive the progress from the step log PER the replay.
Action wiring 79: [Read Log] MUST answer Event Log's read for the query.
Action wiring 80: [Read Log] MUST NOT write.
Action wiring 81: [Advance] MUST NOT answer already-terminal BEFORE firing the owed transition.
Action wiring 82: [Cancel] MUST NOT answer already-terminal BEFORE firing the owed transition.
```

Term section-taking action: [Advance] | [Cancel] | [Read Progress].

Term invocation: one call of a section-taking action, from taking the critical section to the call's answer.

Term re-entry arm: the first thing an [Advance] does in every phase — recognizing the invocation's own prior commits from the step log, never from process memory.

Term owed transition: the declared transition of the step log's newest transition-bearing event, where the spine carries no matching history entry.

Term effect: the external act a step or a compensating action runs at a target.

Term compensation: one run of a compensating action for one completed step, under the compensation's own effect key.

Term attempt: one run of an effect under an effect key, opened by an attempt marker.

Term effect verdict: applied | failed | indeterminate | unknown — applied where the target applied the effect; failed where the target answered that the effect did not land; indeterminate where no reply, a timeout or a transport failure left the verdict open; unknown where the target recognized the effect key and answered that the target cannot say whether the effect applied.

Term forward advance: an [Advance] call finding the compensable workflow in the forward phase with no owed transition and no unresolved attempt.

Term compensating advance: an [Advance] call finding the compensable workflow in the compensating phase with no owed transition and no unresolved attempt.

Term next step: the first declared step no step completion event names.

Term pending compensation: a completed step no standing failure names.

Term standing failure: a compensation failure event whose step no later compensation run event names.

Term resumed attempt: an attempt a resume marker opened.

Term completion record: a step completion event or a compensation run event.

Term marker: an attempt marker, a phase marker or a terminal marker.

Term unrecorded effect: an effect the invocation ran whose verdict is not failed and whose completion record did not land.

Term spine refusal: invalid-transition | terminal | guard-not-satisfied | invalid-request — the State Machine fire refusals the definition validation forecloses, so reaching one means the declaration and the log disagree.

Term fault halt: a halt event carrying a finding.

Term finding: spine-fault naming the spine refusal State Machine's fire answered.

Term validated start: a [Start Compensable Workflow] call whose inputs and definition clear Primitive policy 1 through 16.

Term admitted start: a validated start whose start event lands.

Term halted advance: an [Advance] call finding the compensable workflow in the halted phase whose horizon assertion EQUALS true and, where an overflowed step IS IN the named steps, whose compensation inputs clear Primitive policy 9 and Primitive policy 10.

Term admitted cancel: a [Cancel] call in the forward phase, with no terminal marker, no unresolved attempt and no completed roll-forward step, whose compensation onset event lands.

WHY:
The load-bearing action is the emergent **[Advance]** — neither constituent atom has it — which in the forward phase runs the next step and in the compensating phase runs the next compensation; this is the *advance-or-compensate* verb the pattern is named for. Every action that changes state takes the compensable workflow's critical section first and appends under it, except [Start Compensable Workflow], whose compensable workflow id does not exist before its first write: it serializes on State Machine's `instantiate`, a single constituent write that issues the id (Action wiring 7), and the critical section is taken from the first [Advance] onward.

Action wiring 11 through 19 are the re-entry arm, first in every phase, in three branches. **Branch 1 — a record landed and its `fire` did not** (Action wiring 12 and 13): the log is authoritative for progress, so the owed transition fires now and nothing external is touched. **Branch 2 — an attempt marker stands and its record does not** (Action wiring 15 through 19): the effect may have landed, so it is re-run under its **same** effect key; the target either applies it now or recognizes the key and answers the original result, and either way the captured inputs the record needs come from *that* answer — the only source the composition can re-derive them from, since the failed record is gone and process memory is not evidence. **Branch 3 — no attempt for the next act**: the fresh case, a forward advance or a compensating advance. Branches 2 and 3 are told apart by the log; whether branch 2's effect had already landed is told only by the target, which is why the key discipline is a declared capability (Capability requirement 15) and not an assumption.

Action wiring 20 through 31 are the forward phase, and the four verdicts land in four places. **Applied** lands a step completion event and the forward `fire`. **Failed** — a verdict the target *returned* (Action wiring 20) — records no completion; before the pivot it lands a compensation onset event, which resolves the attempt, since the target said the effect did not land and nothing is owed; at or after the pivot it re-attempts under the same key to the bound and then halts, so roll-forward is bounded per invocation and visible between invocations, never *retry until success*. **Indeterminate** (Action wiring 42 through 45) re-attempts to the bound and then yields with the attempt marker standing. **Unknown** — the peer's third answer, a result memo lost inside the target's window — re-attempts to the bound and then halts (Action wiring 46 through 48), because an automatic re-attempt cannot learn more than the target knows, so the exit is the operator's [Advance] carrying the horizon assertion. **The composition never flips to compensating on an indeterminate verdict** (Action wiring 45), because a step absent from the completed steps whose effect landed would be the silent survivor Invariant 4 forbids.

Action wiring 32 through 41 are the compensating phase: the same four verdicts, with the compensation failure policy deciding what a definite failure does. Under halt-and-surface the compensable workflow enters the non-terminal holding state with the attempt parked; under continue a compensation failure event resolves the attempt, the remaining compensations run, and the phase ends in the halted phase carrying every standing failure — never in compensated, whose safety half forbids it (Invariant 4.1). A later [Advance] from the halted phase runs the halted arm (Action wiring 49 through 51), and the stalled compensation re-runs under its same key at branch 2, so a repaired obstacle resumes compensation rather than restarting it.

Action wiring 52 through 59 are the three storage-failure positions, and the position rides the code because the caller's safe move differs by position (the section titled *A composition's own rejection arm carries the retry bit* in `pressure-testing.md`). **None**: nothing is owed, and a retry is a fresh call. **Effect-landed**: an external effect may exist that the log does not record, the attempt marker says it may, and the caller's only safe move is to retry [Advance], which re-enters at branch 2 under the same key — [Cancel] refuses until then (Action wiring 72). **Spine**: the record landed and the `fire` after it wrote nothing (State Machine Invariant 10.3), so the log is the truth, the spine is owed, and the next [Advance] or [Cancel] fires it at branch 1. Undo History's discipline — a storage-failed append is an action that did not happen — holds here for the none position only; the effect-then-record window is the reason the position rides the code. Action wiring 55 is the case the prose had left unpositioned: a halt event whose append fails after an unknown verdict leaves an effect that may have landed and a standing attempt marker, which is effect-landed's meaning exactly, where the prose's none would have told the caller nothing was owed. Any other `fire` refusal after a landed record is a **conformance fault**, not a position — the definition validation forecloses every one of them — so the invocation halts carrying the finding, fires nothing further, and answers spine-fault; the compensable workflow resumes through the halted arm once the finding is cleared.

Action wiring 69 through 77 are [Cancel]. Branch 1 runs first, so a landed marker owed a `fire` is fired before anything else. An unresolved attempt refuses the call — an effect may exist that the completed steps do not carry, and a compensating phase begun over it would leave it standing; the caller resolves it by retrying [Advance], through the halted arm where the compensable workflow is halted. Action wiring 73 through 76 are the dispositions the prose named and did not state. A compensable workflow past a pivot answers roll-forward: the prose promised *its roll-forward disposition* and declared none. And a [Cancel] outside the forward phase writes nothing: the prose appended a compensation onset event whatever the phase, which in the compensating phase would have fired a forward-to-compensating transition from a compensating spine — a spine refusal and a spine-fault, reached from an ordinary call.

Action wiring 81 and Action wiring 82 put branch 1 ahead of already-terminal. A terminal marker whose `fire` failed is owed like any other, and the prose's [Advance] answered already-terminal before re-entering, which left that `fire` to a [Cancel] nobody sends to a finished compensable workflow.

Action wiring 78 is [Read Progress] reading the log, never the spine, which may lawfully lag the log by one owed `fire`. [Read Log] is a passthrough to Event Log's `read`, the full step and compensation trail at any time.

### Wiring decision

```
Wiring decision 1: The composition MUST reverse a completed effect step by running the step's registered compensating action.
Wiring decision 2: The composition MUST NOT reverse a completed effect step by replay-skip.
Wiring decision 3: The composition MUST reverse a step from the captured inputs the step's completion event carries.
Wiring decision 4: The composition MUST NOT recompute a compensation's inputs from current state.
Wiring decision 5: The composition MUST NOT own the durable execution engine that drives AND retries the steps.
```

WHY:
The principle: when a compensable workflow aborts, each completed step that produced an external effect must be reversed by executing the specific compensating action recorded *at that step's completion* — a refund against the recorded charge, a release against the recorded reservation — run in reverse order of completion. Reversal is a new, recorded forward effect, not a deletion of history and not a recomputation of state.

The likely objection: *Undo History already reverses a logged action by skipping its event and re-deriving state — why not event-source the compensable workflow the same way and avoid a second mechanism?* And, one level up: *if the guarantee is just "no partial visible state", isn't this merely the obligation-realization boundary — declare distributed atomicity, let the projector pick a database transaction, a compensable workflow or a queue — rather than a composition with content of its own?*

The mechanism: replay-skip reverses only effects that live entirely in the log. Re-deriving state as if an event never happened cannot un-charge a card or un-send a shipment, because those effects already left the system. The compensable workflow therefore reverses by an explicit compensating action, which is itself a real recorded effect — and *that* is content the obligation-realization boundary does not carry. The boundary promises an observable and lets a realization fulfil it; this composition additionally specifies the step-to-compensation *pairing*, the reverse-order discipline and the at-most-once obligation under retry — domain-meaningful structure, because a refund is a business act an auditor sees in the ledger, not the transparent rollback of a transaction. The compensating closure is captured at completion, with the inputs needed to reverse *that* step's specific effect, and replayed from the log, so the composition introduces no non-derivable state. The engine that drives and retries the steps stays below the contract (Wiring decision 5): its only requirement on the engine is the one Invariant 7 encodes — that it may retry, and therefore steps and compensations must be idempotent.

The result: all-or-compensated (Invariant 4) falls out of the wiring as an emergent property. In every terminal state each completed external effect is either part of a committed compensable workflow or has had its paired compensation executed, and the step log makes which of the two is true *from the records alone*. The constituent atoms are unchanged; the guarantee lives entirely in the composition, exactly as it does in Undo History — but bought with the opposite reversal mechanism, which is the boundary past which Undo History could not go.

### Event schemas

```
{type: "compensable_workflow_started",     event_id, recorded_at, compensable_workflow_id, definition_ref, subject_ref}
{type: "step_attempted",                   event_id, recorded_at, step, effect_key, within_horizon_asserted}
{type: "compensation_attempted",           event_id, recorded_at, step, effect_key, within_horizon_asserted}
{type: "step_completed",                   event_id, recorded_at, step, compensation_ref, captured_arguments, arguments_overflow, effect_key}
{type: "compensation_run",                 event_id, recorded_at, step, effect_key, arguments_source}
{type: "compensation_failed",              event_id, recorded_at, step, effect_key}
{type: "compensation_begun",               event_id, recorded_at, step}
{type: "compensable_workflow_halted",      event_id, recorded_at, phase, steps, finding}
{type: "compensable_workflow_committed",   event_id, recorded_at}
{type: "compensable_workflow_compensated", event_id, recorded_at}
```

```
Event schema 1: The composition MUST append an event carrying EXACTLY ONE OF the ten event types.
Event schema 2: The composition MUST NOT change an appended event.
Event schema 3: A start event MUST carry the compensable workflow id, the definition reference AND the subject reference.
Event schema 4: An attempt marker MUST carry the step AND the effect key.
Event schema 5: A step completion event MUST carry the step, the compensation reference, the captured inputs, the truncation mark AND the effect key.
Event schema 6: A resume marker MUST carry the recorded horizon assertion.
Event schema 7: A compensation run event MUST carry the step, the effect key AND the input source.
Event schema 8: A compensation failure event MUST carry the step AND the effect key.
Event schema 9: IF a failed effect begins the compensating phase THEN the compensation onset event MUST carry the failed step.
Event schema 10: A halt event MUST carry the phase the halt event leaves AND the steps the halt event names.
Event schema 11: A fault halt MUST carry the finding.
```

Term event type: start | step attempt | compensation attempt | step completion | compensation run | compensation failure | compensation onset | halt | commit | compensation close — the ten schemas, in the order the fence above writes the schemas' wire spellings.

Term attempt marker: a step attempt event or a compensation attempt event.

Term phase marker: a compensation onset event or a halt event.

Term terminal marker: a commit event or a compensation close event.

Term resume marker: an attempt marker carrying the recorded horizon assertion — the event the halted arm appends for each named step.

Term recorded horizon assertion: the horizon assertion the resuming [Advance] carried, kept on the resume marker.

Term transition-bearing event: a completion record, a phase marker carrying no finding, a resume marker or a terminal marker — every event the composition follows with a `fire`.

WHY:
The attempt markers are appended *before* an effect runs (Action wiring 23, Action wiring 34), so an effect whose outcome the process never recorded is visible from the records as an unresolved attempt. That is the whole of their job, and the reason a halt event names them rather than resolving them: a parked attempt is an effect that may have landed and that an operator must see.

Event schema 9 is what lets a definite failure resolve its own attempt. The target said the effect did not land, so nothing is owed; the compensation onset event that begins the compensating phase names the step, and Term resolving event reads the name. A [Cancel]'s compensation onset event names no step, because a [Cancel] runs only where no attempt is unresolved (Action wiring 72).

A fault halt is not transition-bearing. The invocation that appends it fires nothing further (Action wiring 58), because the spine has already refused one transition the declaration should have permitted, and a second `fire` would only ask it again.

---

## Composition-level invariants

These emerge from the composition; none belongs to a single constituent atom. Each is stated over the compensable workflow's reachable states and names the constituent guarantees and wiring it rests on.

- **Invariant 1 — Log faithfulness.**
  ```
  Invariant 1.1: The composition MUST append EXACTLY ONE event PER recorded act.
  Invariant 1.2: EVERY event of the step log MUST follow a recorded act.
  Invariant 1.3: The composition MUST make the log-faithfulness claim ONLY IF the deployment declares the constituent store durability.
  ```
  WHY: no completion, compensation, phase change or outcome goes unrecorded, and the attempt markers make an effect with no recorded outcome an *unresolved* attempt in the log rather than an unrecorded one. The log the invariant quantifies over is the one that survives a restart, which the atom leaves to the deployment (Capability requirement 12). Rests on Event Log Invariant 1 and Event Log Invariant 3, Composition state 2 and Action wiring 52 through 56.
- **Invariant 2 — Progress equivalence.**
  ```
  Invariant 2.1: The spine's current state MUST equal the replayed progress at EVERY quiescent point.
  Invariant 2.2: The composition MUST NOT claim an atomic pair across the spine AND the step log.
  Invariant 2.3: The composition MUST make the progress-equivalence claim ONLY IF the deployment declares the constituent store durability AND the critical section.
  ```
  WHY: the two constituents share no transactional boundary — Event Log sends multi-write atomicity to a transaction pattern and State Machine serializes only its own call — so the composition claims no atomic pair, only a re-derivable one. A `fire` that answers storage-failure wrote nothing (State Machine Invariant 10.3) and lands as the spine position; the re-entry arm brings the spine level at the next invocation (Action wiring 12). Rests on State Machine Invariant 7 and Event Log Invariant 3.
- **Invariant 3 — Compensation pairing.**
  ```
  Invariant 3.1: EVERY step completion event of an effect step MUST carry EXACTLY ONE compensation reference.
  ```
  WHY: a step with an external effect and no compensation cannot complete, because it cannot start — the definition is refused (Primitive policy 12). The compensation is captured at completion with the inputs required to reverse *that* step's specific effect (Wiring decision 3).
- **Invariant 4 — All-or-compensated.** *(The load-bearing claim.)*
  ```
  Invariant 4.1: A compensable workflow carrying a compensation close event MUST carry a compensation run event for EVERY step completion event.
  Invariant 4.2: A compensable workflow carrying a commit event MUST carry a step completion event for EVERY declared step.
  Invariant 4.3: A compensable workflow carrying a commit event MUST carry no compensation onset event.
  Invariant 4.4: The composition MUST carry EVERY open obligation in the step log.
  Invariant 4.5: The composition MUST append a terminal marker ONLY IF no unresolved attempt EXISTS.
  ```
  Term open obligation: a completed step no compensation run event names after a compensation onset event, or an unresolved attempt — an escaped effect the step log still owes.

  WHY: stated as safety plus liveness rather than a flat absolute, because a compensation is itself a real action that can fail. Invariant 4.1 through 4.3 are the safety half: no compensable workflow reaches a terminal while any completed step's escaped effect is uncompensated — in [Committed] every completed effect is meant to stand, in [Compensated] every completed effect has had its compensating action run. Invariant 4.4 and Invariant 4.5 are the liveness half: an escaped effect whose compensation has not yet succeeded is never silently abandoned — it is carried as a visible obligation in the non-terminal halted phase (Invariant 6), and an effect whose *outcome* nobody recorded is carried in the unresolved attempts, which a halt event parks rather than resolves (Replay 12), so no compensating phase begins over it and no [Cancel] succeeds until an [Advance] resolves it. The liveness degree is *surfaced*: the composition runs no reconciliation leg and promises no window, and says so (Non-goal 14). The hazard the invariant forbids is the *silent* survivor — a completed external effect an abort leaves standing with no record that it must be reversed. Rests on Invariant 1 through 3, Action wiring 20, Action wiring 45, Action wiring 72 and Capability requirement 2.
- **Invariant 5 — Reverse-order compensation.**
  ```
  Invariant 5.1: IF the compensation order EQUALS reverse THEN the composition MUST compensate the completed steps newest first.
  ```
  WHY: a later effect is unwound before an earlier effect it may depend on. A deployment whose compensations are mutually independent may set parallel; running them concurrently is a realization choice that preserves Invariant 4 and relaxes this ordering by design, and the spec checks the observable all-compensated outcome, not the schedule.
- **Invariant 6 — Single terminal outcome.**
  ```
  Invariant 6.1: A compensable workflow MUST NOT carry two terminal markers.
  Invariant 6.2: The composition MUST NOT read halted as an outcome.
  Invariant 6.3: A resume marker MUST return the compensable workflow to the phase the standing halt names.
  ```
  WHY: the only resting outcomes are committed and compensated, and any pause short of them is the visible, obligation-bearing halted phase — never a silent partial. Halted is **not** a third terminal: it is the holding state a stalled compensation enters, or a failed roll-forward step at the bound, an overflowed envelope, a target that lost the outcome or a spine fault, and the halted arm returns the compensable workflow to the phase it left and onward — compensating, halted, compensating, compensated; forward, halted, forward, committed past the pivot. Rests on State Machine Invariant 4 — committed and compensated are the absorbing states, and halted deliberately is not.
- **Invariant 7 — Idempotency under retry.**
  ```
  Invariant 7.1: The composition MUST make the at-most-once claim ONLY IF the deployment declares the target key discipline, the critical section AND the constituent store durability.
  Invariant 7.2: The composition MUST NOT run an effect whose effect key IS IN the applied effects.
  ```
  WHY: the durable-execution engine may deliver or replay any step or compensation more than once, so each effect is applied *at most once per compensable workflow* — by two halves that cover different windows, stated honestly. The record-side half is the applied effects (Invariant 7.2): a key already present means the effect and its record both landed, and a re-delivery skips the effect and at most brings the spine up to the log. The effect-side half is the target honouring the key (Capability requirement 15): in the one window the ledger cannot see — the effect landed and its record did not — the re-run under the same key is not applied again and answers the original result (Action wiring 15). The ledger alone never prevented a double-charge in that window, and this invariant does not say it did. The critical section is what makes the pre-check exact: two concurrent deliveries of one [Advance] are one writer, not two writers reading one log. Rests on the idempotency-key discipline the [Idempotent Reservation](./idempotent-reservation.md) peer owns — a declared peer dependency (the section titled *Capability provenance* in `pressure-testing.md`).
- **Invariant 8 — Forward-closed after abort.**
  ```
  Invariant 8.1: IF a compensation onset event EXISTS THEN the composition MUST NOT append a step completion event.
  Deleted: Invariant 9. Composes 10 owns it.
  ```
  WHY: once a compensable workflow enters the compensating phase, the only effects appended thereafter are compensations. Reaching a new forward state after compensation has begun is a re-run, not this pattern (Non-goal 7). The tombstone beside this invariant is the prose's Invariant 9, *constituent invariants preserved*: that State Machine's invariants hold over the spine and Event Log's over the step log is Execution Contract Conformance 8's to say, and Composes 10 cites it — the class council read 53 ruled, at the class's fourth seam, Idempotent Reservation's being the third.

Term recorded act: an attempt, a step completion, a compensation run, a definite compensation failure, a phase change or a terminal outcome.

Term quiescent point: an instant no invocation holds the compensable workflow's critical section and no owed transition EXISTS.

---

## Examples

### Walkthrough — order fulfillment

A compensable workflow with three external-effect steps — *reserve* inventory, *charge* the card, *ship* the order — and their compensations *release*, *refund*, and (for shipment) *recall*. The definition passes validation: every external-effect step names a compensation.

1. `start_compensable_workflow(order_fulfillment, "order-9")` → `{compensable_workflow_id: s1}`. Log: `[compensable_workflow_started]`. Progress: *not-started* (forward phase).
2. `advance(s1)` → takes the run's section; appends `step_attempted(reserve, e1)`; runs *reserve* under `effect_key e1`; inventory held. Appends `step_completed(reserve, comp=release, args={hold_id}, e1)`; fires forward. Progress: *reserved*.
3. `advance(s1)` → appends `step_attempted(charge, e2)`; runs *charge* under `e2`; card charged. Appends `step_completed(charge, comp=refund, args={charge_id}, e2)`; fires. Progress: *charged*.
4. `advance(s1)` → appends `step_attempted(ship, e3)`; runs *ship* under `e3`; **the shipping carrier rejects the request** — a definite verdict the carrier returned, not a timeout. No completion is recorded. The compensable workflow appends `compensation_begun` (which resolves the attempt) and flips to the compensating phase. Returns [Step Failed].
5. `advance(s1)` → compensating phase, reverse order: the most recent completed step is *charge*, so it appends `compensation_attempted(charge, e4)` and runs *refund* against the recorded `charge_id` under `effect_key e4`. Appends `compensation_run(charge, e4)`; fires toward the compensated terminal.
6. `advance(s1)` → appends `compensation_attempted(reserve, e5)` and compensates *reserve* by running *release* against the recorded `hold_id` under `effect_key e5`. Appends `compensation_run(reserve, e5)`; fires. No completed-uncompensated steps remain and no attempt is unresolved; appends `compensable_workflow_compensated` and fires the terminal transition. Progress: *compensated* (terminal).

Outcome: the charge was refunded and the reservation released — the order's external effects are all reversed. The card was charged and then refunded; both remain visible in the payment ledger (a *semantic* reversal, not a pretence the charge never happened — Non-goal 5). All-or-compensated holds: no completed effect survived the abort.

### Idempotency under retry

Run step 3 again with a realistic engine. `advance(s1)` appends `step_attempted(charge, e2)`, charges the card under `e2`, the charge succeeds, but the `step_completed` append fails and keeps failing until `step_completion_bound`; the invocation yields with `storage-failure(effect-landed)` — the position telling the engine an effect exists that the log does not record — and the compensable workflow stays at *reserved* with `step_attempted(charge, e2)` standing as its unresolved attempt. A `cancel(s1)` here is refused [Step Unresolved]: a compensating phase begun now would refund nothing and leave the charge standing. The engine retries `advance(s1)`: the re-entry arm finds the unresolved attempt (branch 2) and re-attempts *charge* under the **same `effect_key e2`**; the payment service — the deployment's `effect_key_honoured` target — recognizes `e2` as already charged and returns the original result, `charge_id` included, without charging again; this time the append lands and the `fire` follows. The card is charged exactly once despite two [Advance] attempts. Note which half did the work: `applied_effects` was empty for `e2` throughout, because the record it is built from is the one that failed; the payment service's key discipline prevented the double-charge, and the attempt marker is what let [Cancel] refuse. Had the second delivery of `advance(s1)` arrived while the first was still inside its bound, `per_run_serialization` would have held it until the first returned — two writers reading one empty ledger is the double-charge the section exists to prevent. Had the *charge* call instead timed out with no reply, the same marker would stand, the invocation would re-attempt under `e2` until a verdict or the bound and then return [Effect Indeterminate] (no-verdict), and the run would not flip to compensating over a charge that may have landed. Had the `step_completed` landed and the `fire` after it failed, the return would be `storage-failure(spine)` — the record is the truth, the next [Advance] fires the owed transition at branch 1, and nothing external is touched. Had the payment service answered that it recognized `e2` but had lost its result, the run would halt at the bound with [Effect Indeterminate] (target-unknown), and only an operator's `advance(s1, within_horizon = true)` would re-ask it.

### Domain examples

- **Travel booking** — steps *book-flight*, *book-hotel*, *book-car* with compensations *cancel-flight*, *cancel-hotel*, *cancel-car*. If the car fails, the hotel and flight are cancelled in reverse order. The classic compensable workflow.
- **Money transfer** — *debit* source then *credit* destination, compensation *reverse-debit*. If the credit fails, the debit is reversed; the ledger shows debit-then-reversal, not a vanished debit.
- **Supply-chain fulfilment** — *allocate*, *pick*, *pack*, *dispatch* with a pivot at *dispatch*: once dispatched, the compensable workflow rolls forward (a recall is a new business process, not a compensation), so steps before the pivot are compensable and the pivot is the commit point.

### Rejection paths

- [Start Compensable Workflow] with a definition whose *charge* step declares no compensation and is not marked read-only or pivot → `rejected(invalid-definition)`. The compensable workflow never starts; the composition refuses to promise all-or-compensated for an irreversible effect.
- A *refund* compensation fails — definitely, the payment service returned the failure — during the compensating phase with `on_compensation_failure = halt-and-surface` → the compensable workflow appends `compensable_workflow_halted(compensating, charge)` and enters the non-terminal [Halted] holding state, surfacing the outstanding refund as a records-visible obligation; it rests *visibly stalled*, not in a silent partial, and once the refund path is repaired an operator's `advance(s1, within_horizon = true)` appends the resume marker for *charge*, fires back to the compensating phase, and re-runs the refund under its same key (re-entry branch 2) and the compensable workflow proceeds to [Compensated]. With continue, `compensation_failed(charge)` is recorded, the remaining compensations run, and the run ends in [Halted] carrying the failed refund — never in [Compensated], never dropped.
- A post-pivot *dispatch* step keeps failing → the invocation re-attempts under its key until `step_completion_bound`, then appends `compensable_workflow_halted(forward, dispatch)`, fires it, and returns [Step Failed]; the run rests in [Halted] in the forward phase, and the next [Advance] — with `within_horizon = true` — appends the resume marker and re-attempts.
- The *charge* target returns reversal arguments larger than the step's declared envelope → `step_completed(charge, …, arguments_overflow = true)` with the arguments truncated, `compensable_workflow_halted(forward, charge)`, [Arguments Overflow] returned; the operator's `advance(s1, within_horizon = true, compensation_arguments = {charge_id})` resumes the run, and if it later compensates, `compensation_run(charge, e4, arguments_source = operator)` says whose arguments reversed it.
- A `fire` after a landed record returns invalid-transition → `compensable_workflow_halted(forward, charge, finding = spine-fault(invalid-transition))`, [Spine Fault] returned: the declaration and the log disagree, which validation was meant to foreclose, and the run rests surfaced until the finding is cleared and an operator resumes it. Roll-forward is bounded per invocation and surfaced between, never an unbounded loop.

---

## Generation acceptance

An implementation is acceptable when an auditor, given the step log and the spine of each compensable workflow, can clear the conformance checks below without recourse to source code, runbooks or developer narration; the external checks name the deployment facts no record carries.

### Conformance checks

```
Check 1.1: An auditor MUST find EXACTLY ONE event PER recorded act in the step log (Invariant 1.1).
Check 1.2: An auditor MUST find a recorded act behind EVERY event of the step log (Invariant 1.2).
Check 2.1: An auditor MUST find the spine's current state equal to a fresh replay of the step log at a quiescent point (Invariant 2.1).
Check 2.2: An auditor MUST derive the progress from the step log AND NOT from the spine (Composes 7).
Check 3.1: An auditor MUST find EXACTLY ONE compensation reference on EVERY step completion event of an effect step (Invariant 3.1).
Check 4.1: An auditor MUST find a compensation run event for EVERY step completion event of a compensable workflow carrying a compensation close event (Invariant 4.1).
Check 4.2: An auditor MUST find a step completion event for EVERY declared step of a compensable workflow carrying a commit event (Invariant 4.2).
Check 4.3: An auditor MUST find no compensation onset event in a compensable workflow carrying a commit event (Invariant 4.3).
Check 4.4: An auditor MUST find no terminal marker in a compensable workflow carrying an unresolved attempt (Invariant 4.5).
Check 4.5: An auditor MUST find EVERY attempt marker a halt event names still unresolved in the replay of the halt event's prefix (Replay 12).
Check 5.1: An auditor MUST find compensation run events in the reverse of the step completion order under the reverse compensation order (Invariant 5.1).
Check 6.1: An auditor MUST find no compensable workflow carrying two terminal markers (Invariant 6.1).
Check 6.2: An auditor MUST find a recorded horizon assertion on EVERY resume marker (Event schema 6).
Check 7.1: An auditor MUST find no two completion records carrying one effect key (Invariant 7.2).
Check 7.2: An auditor MUST find EVERY effect key derived from the compensable workflow id AND the step (Composition state 11).
Check 8.1: An auditor MUST find no step completion event following a compensation onset event (Invariant 8.1).
Check 8.2: An auditor MUST find operator as the input source on EVERY compensation run event for an overflowed step (Primitive policy 24).
```

NOTE: EVERY check names the rule the check tests.

### External checks

```
External check 1: An auditor needing the target key discipline confirmed MUST read the deployment's own target declarations (Capability requirement 15).
External check 2: An auditor needing the effect key horizon confirmed MUST read the deployment's own configuration (Capability requirement 17).
External check 3: An auditor needing the critical section's cross-node exclusion confirmed MUST read the deployment's own host (Capability requirement 6).
External check 4: An auditor needing the lease length confirmed MUST read the deployment's own host (Capability requirement 9).
External check 5: An auditor needing the constituent store durability confirmed MUST read the deployment's own store configuration (Capability requirement 12).
External check 6: An auditor needing the at-most-once claim confirmed MUST read External check 1, External check 3 AND External check 5 (Invariant 7.1).
External check 7: An auditor needing a constituent's own guarantee confirmed MUST read the constituent's own acceptance (Composes 10).
```

WHY:
The first three external checks are the capabilities the prose already named as externally clearable — the honoured key and the key's horizon, the critical section's cross-node exclusion and lease length, and the constituent stores' durability — and none of the three is a record. External check 6 is what makes Invariant 7.1 auditable rather than decorative: an auditor who cleared the conformance checks and stopped would report at-most-once for a deployment that declares none of the three capabilities, and a concurrent pair that both passed the pre-check shows up at the *target* as a double charge rather than in the step log as a defect.

The record-versus-attempt line falls here as elsewhere: what *stands* — an attempt marker, a completion record, a halt event and the attempts it parks — clears from the step log; what the target did in the effect-then-record window is the target's to show.

---

## Non-goals

```
Non-goal 1: The composition MUST NOT choose between orchestration AND choreography.
Non-goal 2: A deployment MUST choose the topology the steps coordinate by.
Non-goal 3: The composition MUST NOT isolate a compensable workflow's intermediate effects from a reader.
Non-goal 4: A deployment needing isolation MUST compose a semantic lock pattern.
Non-goal 5: The composition MUST NOT restore a prior state byte for byte.
Non-goal 6: A deployment needing a true rollback MUST compose a transaction pattern.
Non-goal 7: The composition MUST NOT re-run a compensated compensable workflow.
Non-goal 8: A deployment needing a business goal attempted again MUST start a new compensable workflow.
Non-goal 9: The composition MUST NOT compensate a roll-forward step.
Non-goal 10: The composition MUST NOT resolve a compensation that cannot succeed.
Non-goal 11: An operator MUST own a compensation that cannot succeed.
Non-goal 12: The composition MUST NOT record an act under an audit substrate.
Non-goal 13: A deployment needing a regulated compensable workflow MUST compose Audit Trail.
Non-goal 14: The composition MUST NOT promise a window for discharging an open obligation.
Non-goal 15: The composition MUST NOT enumerate the compensable workflow store.
Non-goal 16: A deployment needing a list of compensable workflows MUST supply the deployment's own index.
```

WHY:
Non-goal 1 and Non-goal 2 are the topology below the contract, beside the engine Wiring decision 5 already puts there. Whether the steps are driven by a Temporal-style replay engine, a message bus or hand-written orchestration, and whether they coordinate through a central orchestrator or by reacting to each other's events, are realization choices. The Temporal *server* itself has no compensable workflow concept; compensable workflow and compensation are assembled at the SDK layer from the engine's generic durable-execution primitives. This page owns the observable contract; the engine owns the *how*. The obligation-realization boundary this page is one realization of — database transaction, compensable workflow, queue — is a working idea, [`working-ideas/outbound-contract-ports.md`](../working-ideas/outbound-contract-ports.md), and not yet a section of `execution-contract.md`, which the prose cited for it.

Non-goal 3 and Non-goal 4: compensable workflows are not isolated in the database-transaction sense. While one is mid-flight another reader can observe its intermediate effects — a reservation that may yet be released, a charge that may yet be refunded. Guarding against the resulting anomalies — dirty reads, lost updates — needs semantic locks or commutative operations — **Semantic Lock** *(forthcoming)*.

Non-goal 5 and Non-goal 6: a compensation undoes a step's effect *semantically* — a refund offsets a charge — and both remain visible. Callers that need true rollback need a single transactional store, not a compensable workflow, which is the trade the compensable workflow exists to make.

Non-goal 9 is the pivot. Some steps cannot be compensated — a physical dispatch, an irreversible external notification. Before the pivot the compensable workflow can compensate; at and after it the compensable workflow may only roll forward, each [Advance] re-attempting the failing step under its key to the bound and then halting as a surfaced obligation. *Retry until success* names a loop whose exit is success; the bound is what the loop does at the bound. A definition whose only path past a failure runs through a step that can be neither compensated nor retried to success cannot promise all-or-compensated, and is the deployment's definition error — one validation here cannot see, because whether a step can be retried to success is the target's to know.

Non-goal 10 and Non-goal 11: the halt-and-surface policy makes a stuck compensation visible as an obligation, but resolving it — manual intervention, an alternate compensation — is operational escalation. A compensation that can *never* succeed leaves the compensable workflow permanently in the halted phase: a recorded, escalated permanent exception, not a silent loss and not a fourth outcome.

Non-goal 12 and Non-goal 13: this is the base shape. A regulated compensable workflow — adding the regulated adversarial scenarios and composing the [Audit Trail](./audit-trail.md) substrate for attributed, retention-bounded, tamper-sealed step and compensation records — is a future composition, exactly as Undo History defers attribution and retention to a composition with Audit Trail.

Where the composition breaks down: when a step's external effect is irreversible *and* not a markable pivot — nothing can compensate it and it cannot be retried to success; when step effects are not idempotent and the executor retries, which fails Invariant 7 at the root; and when the steps require true isolation rather than eventual all-or-nothing.

---

## Edge cases

### Concurrency

```
Concurrency 1: The step log order MUST follow the order the critical section gave the invocations.
Concurrency 2: The composition MUST order a compensable workflow's events by sequence number alone.
Concurrency 3: The composition MUST NOT compare a recording instant against a constituent's stamp.
```

WHY:
A compensable workflow is single-writer by the critical section rather than by assumption (Capability requirement 5): two deliveries of one [Advance], or an [Advance] and a [Cancel], are one writer at a time, and the log order they produce is the order the critical section gave them. Recording instants are best-effort and the sequence number is authoritative (Event Log Invariant 7); the composition consumes no clock of its own (Composition state 10). A multi-actor cancellation race is resolved by the critical section and then recorded in the log order.

### Indeterminate outcome

```
Indeterminate outcome 1: An attempt marker MUST stand as an effect that may have happened.
Indeterminate outcome 2: The composition MUST NOT resolve an unresolved attempt without the target's answer.
```

WHY:
An external effect and the effect's record cannot share a transaction, so there is always an instant at which the effect has landed and the log does not say so, and there is always a reply that never arrives. The composition does not pretend otherwise: the attempt marker makes the instant visible in the records, the target's key discipline makes the re-attempt safe (Capability requirement 15), the bound makes the invocation yield instead of loop (Action wiring 42), [Cancel] refuses the compensable workflow while the attempt is unresolved (Action wiring 72), and the phase never flips on a verdict the target did not return (Action wiring 45). What the composition cannot do is resolve the attempt without the target: a target gone for good leaves the attempt unresolved and the compensable workflow visibly stalled, which is a surfaced obligation and not a silent partial.

---

## Terms

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is*, in plain English, and its **Kind**, and — for a Field, a Parameter or a wire Member — carries the one **Projection** line where the concrete name stays visible on the page. The composition's own concepts are the five actions it exposes, the [Compensating Action] it introduces, the fields and parameters of the records and calls it owns, its outcomes and holding state, and its own refusals. The deployment settings keep their wire spellings in configuration — `compensation_order`, `on_compensation_failure`, `per_run_serialization`, `constituent_store_durability`, `effect_key_honoured` — and the store and derived indexes in an implementation — `compensable_workflow_store`, `step_log`, `completed_steps`, `unresolved_attempts`, `compensation_registry`, `applied_effects`; the page names each in English where it declares it. *(annotation.md Terms registry; representational only — it changes no guarantee, invariant, or behavior of the composition above.)*

### Vocabulary

Term actors: the composition; the constituents; the host; the replay; the re-entry arm; the spine; the step log; a deployment; a definition; an auditor; a caller; an operator; an invocation; a section-taking action; a forward advance; a compensating advance; a re-run; a resumed attempt; a target; a step; an event; an attempt marker; a resume marker; a start event; a step completion event; a compensation run event; a compensation failure event; a compensation onset event; a halt event; a fault halt; a compensable workflow; a compensable workflow record; an input envelope; an admitted start; an admitted cancel; the lease length; the step completion bound; the longest attempt gap.

Term records: compensable workflow record — one per compensable workflow, carrying compensable workflow id, definition reference, subject reference and start instant. event — one appended record in the step log, carrying event id, recording instant, an event type and the type's own fields.

Term record verbs: serve, change, record, reverse, read, decide, inherit, derive, store, carry, rebuild, take, mint, add, remove, map, hold, produce, set, refuse, supply, exclude, release, front, answer, run, ignore, declare, instantiate, write, append, compensate, discard, serialize, fire, re-run, follow, re-attempt, skip, proceed, recompute, own, make, equal, claim, return, find, choose, isolate, compose, restore, start, resolve, promise, enumerate, order, compare, stand.

Term value sets: phase = forward | compensating | halted. outcome = committed | compensated. The rest are declared where the section that owns each declares it: compensation order, compensation failure policy, horizon assertion, step marker, input source, event type, effect verdict, indeterminate reason, advance failure position, cancel failure position, cancel result, spine refusal.

Term bounds: step completion bound (step_completion_bound), effect key horizon (effect_key_horizon), captured input cap (captured_argument_cap), lease length, longest attempt gap, input envelope.

Term cadences: empty.

Term qualifiers: migrated — rewritten in GRACE lang v0.61 (2026-09-23).

Term terms: composition, constituents, compensable workflow, spine, step log, log projection, progress, compensable workflow store, compensable workflow id, definition, definition reference, start instant, completed steps, unresolved attempts, compensation registry, applied effects, effect key, replay, standing halt, named step, resolving event, compensation order, compensation failure policy, step completion bound, critical section, lease length, constituent store durability, target, target key discipline, effect key horizon, longest attempt gap, captured input cap, supplied reason, horizon assertion, compensation inputs, overflowed step, oversized inputs, input envelope, captured inputs, largest admitted record, effect step, step marker, unmarked irreversible step, roll-forward step, truncation mark, input source, advance result, cancel result, indeterminate reason, advance failure position, cancel failure position, section-taking action, invocation, re-entry arm, owed transition, effect, compensation, attempt, effect verdict, forward advance, compensating advance, next step, pending compensation, standing failure, resumed attempt, completion record, marker, unrecorded effect, spine refusal, fault halt, finding, validated start, admitted start, halted advance, admitted cancel, event type, attempt marker, phase marker, terminal marker, resume marker, recorded horizon assertion, transition-bearing event, open obligation, recorded act, quiescent point.

Term cited: Execution Contract Conformance 8 — recursive conformance and the inherited guarantee. The section titled Composition state in `execution-contract.md` — the derived-index classification. workflow, instance id, subject reference, instantiate, fire, current, history entry: State Machine. append, read, query, event id, sequence number, recording instant, payload cap, landed: Event Log. Idempotent Reservation Invariant 8.1 — the peer's exactly-once claim and the claim's conditions.

#### Start Compensable Workflow

The action that begins a compensable workflow. It validates the definition — refusing [Invalid Definition] where a step with an external effect declares neither a [Compensating Action] nor a step marker, and Event Log's invalid-payload where the largest record the definition admits would exceed the payload cap — instantiates the spine over the declared step and compensation sequence, and appends the start event. The start event's recording instant is the compensable workflow's [Start Instant]. Answers the compensable workflow id (Primitive policy 12 through 17, Action wiring 62 through 68).

Kind: Operation

#### Advance

The composition's emergent, load-bearing action — the *advance-or-compensate* verb neither constituent has. Under the critical section it first re-enters from the step log — an owed transition, an unresolved attempt, or a fresh step — and, from [Halted], runs the halted arm under the operator's [Horizon Assertion], with [Compensation Inputs] for an overflowed step. In the forward phase it appends an attempt marker, runs the next step under its [Effect Key] and records the completion; in the compensating phase it does the same for the next [Compensating Action]. Answers the step and the progress it left; refuses [Step Failed] when a step's effect definitely fails, [Arguments Overflow] when the target's reversal inputs exceed the envelope, [Effect Indeterminate] when no usable verdict arrived by the bound, [Spine Fault] when a `fire` after a landed record is refused, and storage-failure naming where the failing write sat (Action wiring 9 through 61).

Kind: Operation

#### Cancel

The action that requests abort of an in-flight compensable workflow. Under the critical section it fires any owed transition, then appends a compensation onset event that moves a forward compensable workflow into the compensating phase, so later [Advance] calls run compensations. A compensable workflow carrying an unresolved attempt — a halt event parks one and does not resolve it — is refused [Step Unresolved] until an [Advance] resolves it; a terminal one refuses already-terminal; one past a pivot answers roll-forward; one already compensating or halted is answered its phase and is not written (Action wiring 69 through 77).

Kind: Operation

#### Read Progress

The read answering the phase, current step and outcome, derived from the step log under the critical section (Action wiring 78, Invariant 2.1). The spine, which may lag the log by one owed `fire`, is not consulted.

Kind: Operation

#### Read Log

The read-only passthrough to Event Log's `read`, answering the compensable workflow's full step and compensation trail at any time (Action wiring 79).

Kind: Operation

#### Compensating Action

The composition's signature concept: a captured operation-plus-arguments paired to a forward step and recorded at that step's completion, which semantically reverses the step's external effect (a refund reverses a charge, a release reverses a reservation). Registered by a [Compensation Reference]. Sub-atomic — a recorded closure, the same primitive Undo History uses for its compensating events, not a freestanding atom. Run in reverse completion order on abort by default (Invariant 5.1).

Kind: Type

#### Effect Key

The at-most-once key each step effect and each compensation runs under. Stable across retries — derived from the compensable workflow id and the step, and the compensation, never minted per attempt (Composition state 11 through 13) — so a retried effect collides with its own prior key. Two halves key off it: the record-side applied effects, where a present key means the effect and its record both landed, and the effect-side target key discipline within the effect key horizon, which refuses to apply the key twice in the window the ledger cannot see and answers the original result (Invariant 7).

Kind:       Field
Field of:   the attempt marker and the completion record
Role:       the at-most-once dedup key
Projection: effect_key

#### Compensation Reference

The reference to a completed step's registered [Compensating Action], recorded on the step completion event beside the [Captured Inputs]. Read, in the compensation order, when the compensable workflow compensates (Replay 9, Wiring decision 3).

Kind:       Field
Field of:   the step completion event
Role:       the step's registered reversal
Projection: compensation_ref

#### Captured Inputs

The reversal inputs a target answered for a step's effect, recorded on the step completion event within the step's input envelope — the `charge_id` a refund needs. Taken from the target's answer, never from the invocation's memory (Action wiring 17 and 18).

Kind:       Field
Field of:   the step completion event
Projection: captured_arguments

#### Truncation Mark

The step completion event's flag saying the captured inputs were truncated to the input envelope because the target answered more than it holds (Primitive policy 19 through 22). A step carrying it is compensated only from the operator's [Compensation Inputs].

Kind:       Field
Field of:   the step completion event
Projection: arguments_overflow

#### Input Source

Whose inputs a compensation run reversed with — recorded, the step completion event's own, or operator, the [Compensation Inputs] an operator supplied (Primitive policy 24).

Kind:       Field
Field of:   the compensation run event
Projection: arguments_source

#### Horizon Assertion

The operator's assertion, on an [Advance] from [Halted], that a parked attempt's effect key is still inside the effect key horizon at the target — the operational act the composition does not vouch for, made explicit in the signature and kept on the resume marker as the [Recorded Horizon Assertion] (Primitive policy 7).

Kind:         Parameter
Parameter of: Advance
Projection:   within_horizon

#### Recorded Horizon Assertion

The [Horizon Assertion] kept on the resume marker, so the records say that an operator, not the composition, judged the key still honoured (Event schema 6).

Kind:       Field
Field of:   the resume marker
Projection: within_horizon_asserted

#### Compensation Inputs

The reversal inputs an operator supplies on the [Advance] that resumes a compensable workflow halted on an overflowed step, within the step's input envelope, and recorded as operator in the [Input Source] of the compensation run that spends them (Primitive policy 9, 10 and 23).

Kind:         Parameter
Parameter of: Advance
Projection:   compensation_arguments

#### Start Instant

The recording instant Event Log stamped on the start event, read back from the log and kept on the compensable workflow record; the composition reads no clock of its own (Composition state 9 and 10).

Kind:       Field
Field of:   the compensable workflow record
Projection: started_at

#### Committed

The terminal outcome in which every step completed and every effect is meant to stand. One of the two resting outcomes.

Kind:       Member
Member of:  the compensable workflow outcome
Role:       terminal outcome
Projection: committed

#### Compensated

The terminal outcome in which the compensable workflow aborted and every completed step's [Compensating Action] has run. The other of the two resting outcomes.

Kind:       Member
Member of:  the compensable workflow outcome
Role:       terminal outcome
Projection: compensated

#### Halted

The explicitly surfaced, **non-terminal** holding state a stalled compensation enters under the halt-and-surface policy, or a failed roll-forward step at the step completion bound, an overflowed envelope, a target that lost the outcome, or a spine fault. The halt event **parks** the attempts it names — they stay unresolved, so [Cancel] stays refused. Not a third terminal: an operator's [Advance] carrying the [Horizon Assertion] appends a resume marker per named step and returns the compensable workflow to the phase it left. Carries the outstanding compensation or step as a visible, routed obligation — never a silent partial.

Kind:       Member
Member of:  the compensable workflow phase
Role:       non-terminal holding state
Projection: halted

#### Invalid Definition

The composition's own refusal at [Start Compensable Workflow] for a definition with a step that has an external effect, no [Compensating Action] and no step marker. The compensable workflow never starts, because all-or-compensated cannot be promised for an irreversible effect (Primitive policy 12).

Kind:       Member
Member of:  the start refusal
Role:       Rejection
Projection: invalid-definition

#### Step Failed

The composition's own refusal from [Advance] when a forward step's effect **definitely** fails — a verdict the target returned. No completion is recorded; before the pivot a compensation onset event moves the compensable workflow into the compensating phase, and past the pivot a halt event lands at the bound (Action wiring 26 through 29). An effect with no verdict is not this refusal — it is [Effect Indeterminate].

Kind:       Member
Member of:  the advance refusal
Role:       Outcome
Projection: step-failed

#### Effect Indeterminate

The composition's own refusal from [Advance] when a step's or a compensation's effect answered no usable verdict by the step completion bound, carrying the indeterminate reason: no-verdict — no reply, a timeout, a transport failure; the attempt marker stands, the phase does not change, and the next [Advance] re-runs it under the same [Effect Key]; target-unknown — the target recognized the key and had lost the outcome; the compensable workflow halts with the attempt parked, and only an operator's [Advance] from [Halted] asks again (Action wiring 42 through 48). Distinguished from [Step Failed] because an effect that may have landed must never be treated as one that did not.

Kind:       Member
Member of:  the advance refusal
Role:       Outcome
Projection: effect-indeterminate

#### Arguments Overflow

The composition's own refusal from [Advance] when a step's effect applied and the target answered reversal inputs larger than the step's input envelope. The completion is recorded with the inputs truncated and the [Truncation Mark] set, the compensable workflow halts from the forward phase, and the compensation's inputs become the operator's [Compensation Inputs] on the resuming [Advance] (Primitive policy 19 through 25).

Kind:       Member
Member of:  the advance refusal
Role:       Outcome
Projection: arguments-overflow

#### Spine Fault

The composition's own refusal from [Advance] or [Cancel] when a `fire` after a landed record answers a spine refusal the definition validation forecloses — meaning the declaration and the log disagree. A conformance fault, not a position: the compensable workflow halts carrying the finding, fires nothing further, and rests surfaced until the finding is cleared and an operator resumes it (Action wiring 57 through 59).

Kind:       Member
Member of:  the advance refusal
Role:       Rejection
Projection: spine-fault

#### Step Unresolved

The composition's own refusal at [Cancel] when the compensable workflow carries an unresolved attempt — an effect whose outcome nobody recorded. A compensating phase begun over it would leave that effect standing, so the abort waits until an [Advance] resolves the attempt (Action wiring 72).

Kind:       Member
Member of:  the cancel refusal
Role:       Rejection
Projection: step-unresolved

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a [Term] marker to its term entry heading above (kramdown
     auto-generates the heading anchors on GitHub Pages). Standard CommonMark /
     kramdown; no plugin required. -->

[Start Compensable Workflow]: #start-compensable-workflow
[Advance]: #advance
[Cancel]: #cancel
[Read Progress]: #read-progress
[Read Log]: #read-log
[Compensating Action]: #compensating-action
[Effect Key]: #effect-key
[Compensation Reference]: #compensation-reference
[Captured Inputs]: #captured-inputs
[Truncation Mark]: #truncation-mark
[Input Source]: #input-source
[Horizon Assertion]: #horizon-assertion
[Recorded Horizon Assertion]: #recorded-horizon-assertion
[Compensation Inputs]: #compensation-inputs
[Start Instant]: #start-instant
[Committed]: #committed
[Compensated]: #compensated
[Halted]: #halted
[Invalid Definition]: #invalid-definition
[Step Failed]: #step-failed
[Effect Indeterminate]: #effect-indeterminate
[Arguments Overflow]: #arguments-overflow
[Spine Fault]: #spine-fault
[Step Unresolved]: #step-unresolved

---

## Standards references

This composition draws on:

- **Sagas** (Hector Garcia-Molina and Kenneth Salem, *Sagas*, ACM SIGMOD — the Association for Computing Machinery's Special Interest Group on Management of Data — 1987) — the originating paper: a long-lived transaction expressed as a sequence of subtransactions, each with a compensating transaction that semantically undoes it, committing without holding locks for the whole duration.
- **Compensating-transaction pattern** — the enterprise-integration and cloud design-pattern formulation of reversal-by-compensation for operations that cannot share one atomic transaction.
- **Durable execution — Temporal** (`io.temporal.workflow.Saga`) — the crystallized SDK form: an in-memory list of compensating closures registered as steps complete, run in reverse order on failure, durable only through workflow replay. The Temporal *server* carries no compensable workflow concept — the engine is domain-blind durable execution — which is the source-grounded basis for placing the engine below the contract.
- **Microservices saga** (Chris Richardson, microservices.io) — the orchestration-versus-choreography framing and the compensatable / pivot / retriable step taxonomy, named here as realization detail rather than concept.

It composes with, and is positioned against, two library patterns: [Undo History](./undo-history.md) (event sourcing with compensating *events*; the replay-skip complement) and [Idempotent Reservation](./idempotent-reservation.md) (the idempotency-key discipline behind Invariant 7). The constituent atoms carry their own inheritance — State Machine (BPMN — Business Process Model and Notation; HL7 FHIR — Health Level Seven Fast Healthcare Interoperability Resources — Task lifecycle; 21 CFR Part 11 — US Code of Federal Regulations, Title 21, Part 11, electronic records) and Event Log (ISO/IEC 27001 — the international information-security standard; NIST SP 800-92 — National Institute of Standards and Technology log-management guidance).

---

## Status

`partially resolved` — returned 2026-08-30 by the sweep under the frozen rules; see the Ledger.

## Ledger

```
status: partially resolved
formal: pending — re-derivation, 2026-08-30: the model has no attempt marker, no per-run section as a second process over one act, no indeterminate verdict, no two-store re-entry, and no key horizon; was verified — compensable-workflow.tla + 2 twins, 2026-06-16
last gate: 2026-06-16 — Final Critique 4, fresh reader — clean

open:
- 2026-08-30-a · refining · formal · the model lacks the attempt markers, `per_run_serialization` as a second writer over one act with lease expiry as its terminus, the four-way verdict, the append-landed/`fire`-missing re-entry branch over every transition-bearing event, the halted marker that parks rather than resolves, and the operator's resume → extend it
```

## Decisions

Directional changes only — the turns a future reader must know the pattern took, and why. Everything smaller lives in the commit that made it: `git log -- compositions/compensable-workflow.md`.

- **2026-08-30 — An attempt is recorded before its effect, one writer per run, the ledger honest about which half it is, and the log authoritative over the spine.** *Chose:* `step_attempted` / `compensation_attempted` markers appended before every effect, so an effect whose outcome nobody recorded is an unresolved attempt the records show, over which [Cancel] refuses ([Step Unresolved]) and no compensating phase begins; a three-verdict effect (applied / definitely failed / indeterminate) with the phase flipping only on a verdict the target returned and [Effect Indeterminate] at `step_completion_bound`; `per_run_serialization` declared as an instance capability requirement with lease semantics, under which the `applied_effects` pre-check is re-read; a three-branch re-entry arm (record landed and `fire` missing / attempt present and record missing / fresh) with the log authoritative for position and the State Machine brought to it; Invariant 7 restated as a record-side ledger plus an effect-side key discipline declared as `effect_key_honoured` within `effect_key_horizon`; `constituent_store_durability` declared, with Invariants 1, 2 and 7 conditional on it; the completion record sized at [Start Compensable Workflow] against the Event Log cap with invalid-payload transcribed there only; `storage-failure(effect-landed | none)` on [Advance]; post-pivot roll-forward bounded per invocation and surfaced in [Halted]. On the closure check of the same day: the halted marker parks an attempt and does not resolve it, so [Cancel] stays refused through [Halted] and the exit is the operator's [Advance] carrying `within_horizon = true` (the horizon assertion made explicit in the signature and on the resume marker); `unresolved_attempts` a set, for parallel; a third position `storage-failure(spine)` for a record landed and its `fire` owed, every phase and terminal marker followed by a `fire` and re-derived at branch 1, and any other `fire` refusal a [Spine Fault] finding; one landing for an overflowed envelope — truncated record, `arguments_overflow = true`, operator-supplied compensation_arguments; the peer's third answer as target-unknown; the lease expiry as the terminus for writes with lost = expired = yield; [Read Progress] reading the log, never the spine; [Start Compensable Workflow] serializing on `instantiate` because its id does not yet exist. *Over:* a ledger built from the record that failed, credited with preventing the double-charge it could not see; "the action did not happen" written over a token that also landed after the charge; a phase flip on any failure, timeouts included; *retry until success* past the pivot; a position claimed equal in two stores nothing made equal; durability and idempotency the constituents and the peer decline, used as if granted. *Because:* two deliveries reading one empty ledger both charge the card; a caller told nothing committed cancels over a charge and reaches [Compensated] with it standing; and a guarantee resting on an undeclared capability is only as sound as the capability nobody declared (the frozen rules of 2026-08-30 — *A compensator is exclusive*, *An outcome is sized before the intent*, *A composition's own rejection arm carries the retry bit*, *Capability provenance* frozen — with §*Recovery commits under a declared service identity*'s re-derivability and re-entry clauses).

- **2026-09-23 — Rewritten in GRACE lang v0.61; nothing but language changed except one tombstone and eight repairs the rewrite could not restate.** *Chose:* `Composes`, `Composition state` with `Replay` beneath it, `Capability requirement`, `Primitive policy`, `Action wiring`, `Wiring decision` and `Event schemas` as the surfaces, in Undo History's and Idempotent Reservation's shapes; invariant numbers 1 through 8 unchanged and Invariant 9 tombstoned; a `Generation acceptance` section with seventeen `Check` and seven `External check` rules, each naming the rule it tests; `Non-goals` and `Edge cases` split, with `Concurrency` and `Indeterminate outcome` under the second; `Compensation Ref` renamed `Compensation Reference`, and `Start Workflow` renamed `Start Compensable Workflow`, the name its wire always carried. The repairs: the compensable workflow record loses the outcome field it declared *set once at start and immutable* while setting it at the terminal and writing it at no step — the replay reads it from the terminal marker (Composition state 5, Replay 5 and 6); a commit event is appended when no next step remains (Action wiring 31), where the prose named the terminal marker and no step that wrote it; the continue policy ends through standing failures (Action wiring 32, 40 and 41), where *move on* re-picked a failed step on every [Advance], since a compensation failure leaves the step completed; a marker whose append fails with an effect standing unrecorded answers effect-landed (Action wiring 55), where the prose positioned it nowhere; [Cancel] past a pivot answers roll-forward (Action wiring 73), where the prose promised *its roll-forward disposition* and declared none; [Cancel] writes only in the forward phase (Action wiring 74 through 76), where a compensation onset event appended in the compensating phase would have fired a transition the spine refuses and answered spine-fault to an ordinary call; [Advance] fires an owed transition before answering already-terminal (Action wiring 81), where the prose answered first and left a terminal marker's owed `fire` to a [Cancel] nobody sends; and two citations re-aimed — the obligation-realization boundary lives in `working-ideas/outbound-contract-ports.md`, not in `execution-contract.md`, and Undo History states the boundary the Intent quoted as Undo History Non-goal 10, the sentence quoted being gone. *Over:* the prose spec, and a first migration that restated those eight as it found them. *Because:* the migration plan, and the standing rule that a finding is fixed in the pass that finds it. Invariant 9, *constituent invariants preserved*, is the class council read 53 ruled — Execution Contract Conformance 8 settles it by reference and Composes 10 cites it — at the class's fourth seam, Idempotent Reservation's being the third. Richardson's title in Standards references is *Microservices saga* again: the saga rename reached a cited title, and a citation keeps the author's word. `formal:` and the open model line are unchanged — the model was stale for reasons that predate this rewrite, and the rewrite touches no `.tla`.

- **2026-09-23 — Progress for where a compensable workflow has got, position for where a write lands.** *Chose:* the phase, current step and outcome renamed **progress**, the read action Position renamed **[Read Progress]** with the wire read_progress, and Invariant 2 titled *Progress equivalence*, numbers unchanged. *Over:* keeping *position* in both senses. *Because:* the page used *position* for two things — the storage-failure positions, which is the sense four other specifications declare, and the phase-step-outcome triple no other page means by it — and a name carries one meaning (council read 166's ruling: this page renames, the corpus keeps *position*). *Progress* is the page's own word for the thing (*forward progress*), and a read action takes the corpus's *Read* form beside [Read Log]; the answer arm is the declared term itself. The TLA+ header's comment still says *position equivalence*; the model is stale for older reasons and untouched here.

NOTE: End of Compensable Workflow.
