---
title: Execute Gated Workflow — history
nav_exclude: true
search_exclude: true
---

# Execute Gated Workflow — history

The dated record of how [Execute Gated Workflow](./execute-gated-workflow.md) got here, moved out of the spec on 2026-10-20 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- compositions/execute-gated-workflow.md`.

## Decisions

Entries that record a migration rather than a turn the pattern took.

- **2026-08-26 — Every audit record emitted outside the original human invocation is composition-attributed.** *Chose:* retries, recovery emissions and cascade recalls attest under `application_actor_ref` / `application_credential`, with the human actor in the event `data` and `recovery = true`; the retry loop runs only on the substrate's transient failure, invalid-request foreclosed by budget-derived caps and minted-id width bounds. *Over:* re-presenting the human's credential on retry, or looping on every rejection. *Because:* a human credential is not available to a recovery path and a deterministic rejection retried forever is a stall, not a recovery; the discipline is shared with Multi-Party Approval so the two recovery vocabularies stay one.

- **2026-08-27 — Committed-but-unrecorded work is re-derived from the constituent stores, never remembered by the process.** *Chose:* the consumption test's second arm reads State Machine history, the moot-gate cascade is conditioned on the fire's commit, and a four-leg restart sweep diffs the constituent stores against the trail to land every owed record; the in-flight pending set is a cache classified extraction-pending against a forthcoming Outbox atom. *Over:* retry-until-lands obligations held in process memory, and a cascade conditioned on the action returning success. *Because:* a crash between a commit and its record lost the obligation entirely — one approval could fire twice and mooted gates stayed Pending with live Assignments — and an obligation that a records-alone auditor cannot re-derive is not one the pattern can claim.

- **2026-08-27 — Caller authentication is the composition's own obligation, before any constituent call.** *Chose:* an intent record whose substrate attestation verifies the credential before the Approval Step decision commits. *Over:* assuming an authenticated-caller binding the spec never declared, which let a parseable-garbage credential drive a committed Approved step. *Because:* Permissions assigns the actor-to-caller binding to "the composing system", and this composition is that system.

- **2026-08-29 — The restart sweep is bounded at both edges, writes a recovery record before it commits, and pairs a firing to its intent on the shared reading.** *Chose:* `workflow_completion_bound` below and the audit horizon above for every leg, with the sweep holding the per-instance serialization; a `workflow.recovery_intended` record before any leg that commits constituent state; leg (1) joined on `fired_at = intended_at` plus actor rather than "the latest unmatched intent", with `intent_event_candidates` and the union of plans where more than one matches; `compensation_window` and `reconciliation_cadence` declared. *Over:* a sweep on "a fixed cadence" whose pre-check was its only guard, and a definite-article join. *Because:* the pre-check cannot see an invocation that has not written yet, so a leg fired inside the completion bound lands a second outcome for one commit; a sweep that withdraws steps and recalls assignments without a record of its own is indistinguishable from a direct call; and "the latest" chooses where the records may not (the frozen rules of 2026-08-29 — *A reconciliation is bounded at both ends*, *Recovery commits under a declared service identity*, *Intents pair with outcomes*).

- **2026-08-30 — An approval is mooted on the record when the workflow leaves its state, the consumption arm stops at the horizon, the sweep's decision leg joins on the outcome, and the maps are read only at the shape their contract covers.** *Chose:* the moot-gate plan and cascade extended to Approved-and-unconsumed gates — one `moot_gate_recalled` with `moot_kind = approved-unconsumed` and a durable mooted flag, the step left standing as a decision that authorized nothing, [Open Gate] re-binding over it and [Fire Transition] refusing it; the consumption rule's history arm bounded to firings inside the audit horizon widened by `clock_offset_allowance`, with the consumed and mooted flags carried by every deployment under `binding_flag_durability` rather than offered as a fallback; sweep leg (4) joining a terminal step only to the `gate_decision_intended` whose decision, actor and stamp match the step's own, candidates on a tie and a surfaced finding on zero, never a re-emission; [Read Workflow]'s set-valued queries and the sweep's instance enumeration anchored in the `workflow_started` and `gate_opened` events with keyed rebuild-on-miss per instance; `gate_to_assignment` rebuilt from `ApprovalStep.read({})` and `Assignment.history_for(task_ref)` at every retention state; `recording-failure(pre-commit | post-commit)` and `already-open(pending | cleared-unconsumed)` on the signatures; the invocation yielding every owed write at `workflow_completion_bound` under a whole-invocation hold, the sweep re-reading its pre-check under the same serialization; the liveness inequality written out with `record_write_latency`; `intent_candidates_cap` sizing the recovery envelope; and, from the closure check, the firing's own consumed step excluded from its moot-gate plan, `instance_serialization` declared as the deployment's capability with lease-at-the-bound semantics and the re-take-before-pre-check rule, sweep leg (2) covering a withdraw that committed before its record, and leg (4) owning the recall [Decide Gate] could not land inside its bound. *Over:* an approval that survived a departure and cleared a return-path firing with no fresh decision; an unbounded history arm that read every purged firing as unrecorded and bricked the key; a leg that landed `gate_decided` for whichever intent named the step; queries that enumerated a derived index with no miss to observe; a payload-sourced rebuild declared *not rebuildable* on a capability gap the constituent does not have; a bare token on both sides of the commit; *retry until it lands* beside a sweep that starts at the bound; *cadence no longer than the window*; a plan that mooted the approval its own firing spent; a critical section attributed to nobody. *Because:* the cascade exists to keep a stale human decision from clearing a transition in a context the approver never saw, and Pending was the wrong place to stop; a horizon that destroys the event must not also destroy the key; a decision's outcome is on the step and the join must read it; an index read at a shape its contract does not cover puts the records-alone proof on a cache; a constituent's declared surface outranks the composition's memory of it; a caller who cannot tell pre-commit from post-commit re-fires a committed transition; and a section no Configuration names is a section whose lease nobody bounds (the frozen rules of 2026-08-30 — *A compensator is exclusive*, *Lawful destruction is answered before absence*, *An outcome is sized before the intent*, *Liveness is arithmetic*, *A stamp from another seam never decides a write alone*, *A composition's own rejection arm carries the retry bit*, and *Capability provenance* frozen — with §*Intents pair with outcomes*, §*A derived index is trustworthy only where a miss is observable* and §*A derived index splits at the horizon*).

- **2026-09-24 — Rewritten in GRACE lang v0.62; twenty-eight of thirty open Ledger lines closed by the rules that now own them.** *Chose:* `Composes`, `Composition state`, `Capability requirement` — which takes the prose's Configuration whole — `Primitive policy`, `Audit arm`, `Action wiring`, `Wiring decision` (the approval-gated transition, with the consumption and mooting rules), `Reconciliation` (the restart sweep, as four legs), `Scope vocabulary` and `Cascade` (the moot cascade, the family Multi-Party Approval opened) as the surfaces; invariant numbers 1 through 6 and 8 unchanged, Invariant 7 tombstoned to Composes 6; the record checks renumbered by the invariant each tests; the edge cases split into Non-goals and four Edge cases families. Choices the page left open, each decided by a standing rule: one State Machine workflow per run, stated as its own serve rule beside the one State Machine instance (Composes 1 and 17 — Compensable Workflow's shape for the same atom); every constituent write surface reserved to the composition, Permissions read-only (2026-08-26-h, 2026-08-30-b); the marks extraction-pending against Binding Registry, a write-once pairing of a step to the transition that spent it (2026-08-30-d — *A derived index splits at the horizon*); the retention step and invalid-request(step-4) at an outcome read back by the act's minted id and proceeding as landed (2026-08-26-d — *A transcribed rejection arm keeps its payload*); every read-side refusal landed (2026-08-26-b); the audit-completeness count taken from the constituent stores and the start half routed external (2026-08-26-e, 2026-08-30-c); the firing's binding read from its own event (2026-08-26-f); the grant reconstruction pinned to the outcome's payload instant (2026-08-26-g); a lost answer met by reading before re-invoking, and at-most-once left to the caller's key as it is for fire (2026-08-26-i — *make all things mean one thing*); approval staleness a non-goal (2026-08-26-k); the recovery intent renamed with underscores like every other kind here (2026-08-30-a). *Over:* the prose's step lists, a serialization rule titled for one action, and a Standards line claiming the substrate *satisfies* Part 11 where it is the structural form. *Because:* the rules state each landing once; the two formal lines stay open because the model, not the page, is what they owe.

- **2026-09-30 — Audit Trail's invalid-request is read by its step at an outcome.** *Chose:* `invalid-request(step-4)` at an outcome read back and proceeded as landed, and `invalid-request(step-1 | step-2 | step-3)` answered recording-failure carrying post-commit, as a pre-append step is (Audit arm 7 and 17); at an intent the answer stays a bare invalid-request, the intent standing with no outcome at step-3 and step-4 (Audit arm 3 and 16). *Over:* one read-back for every step, which left the not-found case unanswered, and a bare invalid-request over a committed act. *Because:* Audit Trail now refuses `invalid-request(step)` so a caller can tell a committed act from a clean refusal (its Decisions entry of 2026-09-30); the frozen rule that a composition's own rejection arm carries the retry bit, and the post-commit stage this page already exports, decide it.

- **2026-10-20 — The store's guarantees cited, not restated, the instance exclusion among them.** *Chose:* Capability requirement 24 citing Execution Contract Store 1 through 4 for the store the five constituents and the four indexes keep their records in; the rules restating what that store guarantees tombstoned to it — the host's instance exclusion over every state-changing invocation and the sweep, with its supply, its release, its lease, its terminus and the bar on running without it (Capability requirement 10 through 15, Action wiring 18, Concurrency 1, 2, Reconciliation 6, 7), the invalid-credential at an outcome, which the one transaction's read of the actor registry forecloses (Audit arm 10), and the marks' declared durability (Composition state 18, Capability requirement 17); and the machinery that existed only because a crash, a split write or an invocation seen between its writes could leave a partial: the sweep's run at every process start and its lower edge (Reconciliation 1, 4), the invocation's own retry of an outcome, an assign, a recall and a cascade call, with the read-back of an assign that answered already-assigned and the opening left unassigned past the bound (Audit arm 12, Action wiring 30 through 32, 43, Cascade 12), the read-back of a recording-failure at the substrate's retention step, which Audit Trail's own rewrite made commit nothing (Audit arm 6), and the decision leg's recall of an assignment a decision left active (Reconciliation 23); the opening leg records the opening event alone, a submit's assign now committing with it (Reconciliation 15). Rules 284 to 261. *Over:* intent, load-bearing call, constituent writes, outcome and moot cascade committed one by one under a host's instance exclusion held from before the intent through the cascade, ordered so that a crash between them left a state the composition could name — a committed firing with no record, a submitted step with no assignment, a decided step whose assignment stayed active, a cascade call unanswered — with an invocation that retried its own writes up to the completion bound and then yielded them, and a sweep that ran at every restart, waited out that bound and took the same exclusion. *Because:* the maintainer ruled 2026-10-12 that the corpus takes a store's specification, never the store, and 2026-10-20 that Store 1 binds every store write of one composition action, its constituents' included, while a refused attempt a page keeps as evidence stays a domain choice, written in the same transaction as the refusal. State Machine, Approval Step, Permissions, Assignment and Audit Trail each supply their store under Store 1 through 4, and no action here makes an act outside the store, so an action's intent, constituent writes and outcome commit together, and the instance exclusion only held store writes apart, which Store 2 now serializes. The census's question is decided by the reading Multi-Party Approval took for its own cascade: a cascade is part of the action that fires it (the section titled Multi-write atomicity in `execution-contract.md` names a cascade's writes as writes of one Step 3), so a cascade call's storage failure fails the whole firing, while a refusal — Approval Step's temporal invalid-request on a withdraw, Audit Trail's refusal of a moot record — leaves the firing standing and the call owed (Cascade 10, 11) for the cascade leg to close on a later reading (Reconciliation 14, 28); the invocation's own retry of that call goes, since its one reading cannot cure the refusal (Capability requirement 20). An Audit Trail refusal at an outcome — its invalid-request, or an append whose answer was lost — still leaves the act committed and its record owed (Audit arm 11, 17), as Audit Trail's own refusals leave their evidence (Audit Trail record action step 7.11), so what closes it stays: the read-back of an invalid-request at the retention step (Audit arm 7 through 9), the caller's bar on re-invoking a committed act and the start's re-invoke (Audit arm 14, 15), the unlanded start's quarantine and the bar on re-emitting a start event (Action wiring 10, Reconciliation 27, External check 1), the consumption rule's history arm (Wiring decision 3, 5), and the sweep on its cadence, with its horizon edge, enumeration, recovery intent, service identity, four legs, pairing, candidates, retry on a transient arm, window and escalation (Reconciliation 2, 3, 5, 8 through 22, 24 through 30), and the bounds and the liveness rule its window must clear (Capability requirement 4 through 8, 18, Check 3.5); the completion bound stays because the liveness sum reads it. The intents stay, since an intent is where the caller's credential is validated before any constituent write (Invariant 8). The four indexes stay derived indexes outside every action's transaction, as obligation 2 of the section titled Composition state in `execution-contract.md` keeps them, so their population after the landed event, their rebuild on a miss and the landing of an index anomaly stay (Composition state 9 through 15, Action wiring 13, 14, 16, 20, 21, 40, 44, 45, 67). The rebuilds read the machine's sequence numbers and the Event Log's order (Clock semantics 1, 2), and Check 5.1 reads Permissions' own stored instants, so the composition cites neither Store 5 nor Order 1. What the composition does for its domain is unchanged.

- **2026-10-21 — The process proof reads as provable.** *Chose:* *provable* (`glossary.md`: shown by the records alone, never by a system's say-so) where the page wrote *from the records alone*, *records-alone* or *without recourse to source code, runbooks or developer narration*: Invariant 6.1, under which every workflow's process proof resolves provably, with Invariant 6's heading, and, by wording alone, the Summary, the Intent, the Wiring decision's principle, the two inspection examples, the acceptance bar, the [Read Workflow] term entry and two standards; rules 261 to 261. *Over:* the phrase restated at each site. *Because:* the maintainer ruled 2026-10-21 that *shred*, *grant* and *provable* are declared domain terms, each defined once, in `glossary.md`, and that the specifications say them where their meaning stood; the wording of Invariant 6.1 changed and no obligation did.

## Ledger

The gate records the Ledger's `last gate:` line carried behind its latest until 2026-10-20, newest first:

- 2026-08-27 — authentication-precedence gate, fresh reader — 3 foundational pre-existing routed (all since closed), 8 refining/rhetorical routed
- Final Critique 9's 1 other foundational (since closed), 13 refining (1 since closed) and 4 rhetorical also routed

## Deleted rules

The spec's tombstones, moved here from the page on 2026-11-13 because the spec is done (GRACE-lang Hard invariant 25 and Hard invariant 27, since v0.71): each `Deleted:` line byte for byte and in the page's order, under the heading it stood under there. A tombstone carries no obligation, and each still reserves its label: no rule of [Execute Gated Workflow](./execute-gated-workflow.md) may carry it again.

### Composition logic › Composition state

```
Deleted: Composition state 18. Execution Contract Database 3 and Execution Contract Database 4 own it.
```

### Composition logic › Capability requirement

```
Deleted: Capability requirement 10. Execution Contract Database 2 owns it.
Deleted: Capability requirement 11. Execution Contract Database 2 owns it: an action's reads of a workflow and the writes they decide are one transaction, and the composition names no exclusion to release.
Deleted: Capability requirement 12. Execution Contract Database 2 owns it: an action's reads of a workflow and the writes they decide are one transaction, and the composition names no exclusion to release.
Deleted: Capability requirement 13. Execution Contract Database 2 owns it: an action's reads of a workflow and the writes they decide are one transaction, and the composition names no exclusion to lease.
Deleted: Capability requirement 14. Execution Contract Database 2 owns it: an action's reads of a workflow and the writes they decide are one transaction, and the composition names no lease to expire.
Deleted: Capability requirement 15. Execution Contract Database 2 owns it: an action's reads of a workflow and the writes they decide are one transaction, and the composition names no exclusion for a host to lack.
Deleted: Capability requirement 17. Execution Contract Database 3 and Execution Contract Database 4 own it.
```

### Composition logic › Audit arm

```
Deleted: Audit arm 6. Execution Contract Database 1 owns it.
Deleted: Audit arm 10. Execution Contract Database 2 owns it.
Deleted: Audit arm 12. Execution Contract Database 1 owns it: an action's writes commit together, so no invocation retries an outcome.
```

### Composition logic › Action wiring

```
Deleted: Action wiring 18. Execution Contract Database 2 owns it.
Deleted: Action wiring 30. Execution Contract Database 1 owns it.
Deleted: Action wiring 31. Execution Contract Database 1 owns it.
Deleted: Action wiring 32. Execution Contract Database 1 owns it.
Deleted: Action wiring 43. Execution Contract Database 1 owns it.
```

### Composition logic › Wiring decision

```
Deleted: Wiring decision 6. Term consumption rule owns it.
```

### Composition logic › Reconciliation

```
Deleted: Reconciliation 1. Execution Contract Database 1 and Execution Contract Database 3 own it.
Deleted: Reconciliation 4. Execution Contract Database 1 owns it.
Deleted: Reconciliation 6. Execution Contract Database 2 owns it.
Deleted: Reconciliation 7. Execution Contract Database 2 owns it: the sweep's reads of a workflow and the writes they decide are one transaction, and the composition names no exclusion for another holder to hold.
Deleted: Reconciliation 23. Execution Contract Database 1 owns it.
```

### Composition logic › Cascade

```
Deleted: Cascade 12. Execution Contract Database 1 owns it: a cascade call's storage failure fails the whole firing, so no invocation retries a cascade call.
```

### Composition-level invariants › Invariant 8 — Authentication precedes commitment

```
  Deleted: Invariant 7. Composes 6 owns it.
```

### Edge cases › Concurrency

```
Deleted: Concurrency 1. Execution Contract Database 2 owns it.
Deleted: Concurrency 2. Execution Contract Database 2 owns it.
```
