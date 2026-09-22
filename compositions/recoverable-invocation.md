---
title: Recoverable Invocation
parent: Conceptual Compositions
nav_order: 10
has_toc: true
toc: true
---

# Recoverable Invocation

<details markdown="block">
<summary>Table of contents</summary>
{: .text-delta }
1. TOC
{:toc}
</details>

## Summary

Recoverable Invocation is the protocol every regulated action in this library follows when it changes something it cannot take back and must leave a trustworthy account of having done so: write down what you are about to do, do it, write down what you did — and if the process dies in between, let a separate sweep finish the writing, so that the sweep and the original never both write, the sweep never writes about work still in progress, and the sweep never invents an outcome it cannot read back from the store the act was made in.

Twenty compositions had each written this protocol in their own words. This composition specifies it once. An adopter names it and supplies **bindings** — what the act is, which store commits it, how long it may take, under what identity a sweep may finish the accounting. The intent record, the outcome record, the critical section, the sweep with its two edges, the position on every rejection code, and the arithmetic that makes the closure promise meetable all live here.

The protocol is proved in `recoverable-invocation.tla` (TLA+): six components over one act — the invocation, the critical section host, the store, the journal, the sweep as two runs on two nodes, and an operator through [Resolve] as the third writer — with time explicit, the crash anywhere, and every write split into the instant its gate is passed and the instant it is issued. The composition wires the **Audit Trail** substrate and a **critical section** the deployment supplies, keyed by the act, and composes no store of its own. The emergent guarantee: every act committed through it is accounted for exactly once, by exactly one writer, within a declared window or with a declared record of why not.

---

## Intent

WHY:
An irreversible act and its account are two writes no transaction spans (the library's rule since 2026-08-27: an atomic set may not contain a write the host cannot take back). The order — intent, act, outcome — leaves exactly one reachable partial: the act committed, its record owed. Something must close it after the process that opened it is dead.

By 2026-08-30 twenty compositions had each solved this in their own words, and two days of fresh-reader gates found the same defects in every one: two writers landing an outcome for one act; a sweep reading in-flight work as a crash; a sweep re-emitting an outcome it could not have known; a rejection code saying nothing had committed when something had; a closure window that could not be met. One protocol, carried once. The rule: **one act, one intent, one outcome, one writer** — the invocation while it holds the critical section, the sweep after the invocation has yielded, never both.

Not a transaction, not the adopter's store, not an audit journal, not a class. An adopter names it in *Composes*, binds its parameters, declares any deviation, and deletes the paragraphs this page replaces.

---

## Composes

- **[Lease](../atoms/lease.md)** — the per-key grant of exclusive standing whose terminus is an instant. The act's critical section is a lease, and so are both fences. This page binds the atom's parameters — which key, which holder, how long, which arm maps to which code — and restates none of its semantics. What the atom refuses to own and this page adds: which key protects which work, and how long a grant must last.
- **[Audit Trail](./audit-trail.md)** — the regulated-audit substrate and this composition's journal, its four constituents (Event Log, Actor Identity, Tamper Evidence, Retention Window) reached transitively per *Compositions of compositions* ([`spec-format.md`](../spec-format.md)). Consumed at the declared contract `record_action(action_ref, actor_ref, credential, data)`, which answers event id and refuses `invalid-credential | invalid-request | recording-failure(step)`, for every record this page writes, and `read_record(event_id)`, which answers `audit_record | not-known`, where an event id is in hand. Attribution, retention and sealing of every record here are Audit Trail Invariants 1, 2 and 3; destruction of a payload at the horizon is Audit Trail Invariants 4 and 8.
- **The bound act** — not a constituent. The adopter's constituent commit call, supplied as a binding together with the read that tells whether it committed. The constituent's own contract governs the commit.
- **The act's critical section** — keyed by the act, supplied by the deployment (*Capability requirement*, act section). No constituent grants it.

```
Composes 1: A record MUST carry only stamps of the substrate (recorded at) or of the constituent (through probe).
```

### Journal fence (optional)

A fence on the composition's own journal writes, standing to the journal as commit fence stands to the adopter's store: a conveyance, a clock, an edge.

```
journal fence 1: A deployment declaring journal fence MUST declare the conveyance: a deadline parameter on record_action, or a host-applied request-scoped deadline on every record_action of the instance.
journal fence 2: The section titled Where the allowance goes IS AUTHORITATIVE FOR the fence's instants.
NOTE: watch addressable sections — a section title as the subject of an authority claim (journal fence 2, Allowance 2, Instance start 1, Which closing stands 1, Invariant 2.6).
journal fence 3: The substrate MUST land a fenced-out write on the position's existing recording-failure arm.
journal fence 4: A sweep run MUST absorb a fenced-out closing write into skipped and leave the intent open.
```

Term position's existing arm: `recording-failure(intent)` at [Open]; `recording-failure(outcome)` at [Close]; `recording-failure(refusal, constituent_code)` at [Refuse]; `recording-failure(resolution)` at [Resolve].

Term constituent code: constituent_code — the refusal code a constituent returned, carried beside the composition's own.

Term closing event id: closing_event_id — the event id of the closing another writer already wrote for the invocation.

Term journal fence: journal_fence — the composition's optional fence on its own journal writes; a deployment declaring none takes the case this library ships.

Term journal fence instant: the earlier of the writer's lease terminus and the write's per-write terminus.

WHY:
record_action carries no deadline parameter, so the first conveyance is unavailable in this library. Without the per-write instant a write may land after journal write bound and inside the lease — after the read-back, which then retries and appends the duplicate (`-buggy-perwrite`, rejected).

### Under journal fence set to none — the case in this library today

```
journal fence none 1: WHEN journal fence EQUALS none:
    journal fence none 1a: A late append beside another writer's closing MUST leave both records.
    journal fence none 1b: The composition MUST set binding duplicate on the act.
journal fence none 2: The composition MUST surface a binding duplicate.
journal fence none 3: The composition MUST report a binding duplicate.
journal fence none 4: The composition MUST resolve a binding duplicate.
journal fence none 5: A surface MUST report a duplicate as EXACTLY ONE OF the closings key, the intents key.
journal fence none 6: A surface MAY report the intents key ONLY IF the act kind declares a service identity.
```

Three surfaces make journal fence none 2 checkable and read the section titled *Which closing stands* for both keys: [Read Invocation]'s two binding duplicate fields (read invocation 7, read invocation 8), [Reconcile] step 5's scan over the delta (reconcile step 5.2 through 5.4), and Generation acceptance check 2.

Term quiescence: no invocation in flight and no sweep run mid-pass.

WHY:
No auditor can enumerate which writers were paused, so the guarantee is over records alone. The scan rides the delta, where a late append appears, because step 1 keeps only open intents and an act with two closings is not open. The intent is inside this: [Open] releases on the intent write's return, so a late-landing intent leaves the next waiter's pre-check reading nothing and a second live intent appears, both escalating (Invariant 3) — invisible to any surface keyed on invocation id, hence the intents key. The fence prevents it and the gate does not (`probe-fenceless-intent` violates, `probe-fenced-ungated-intent` holds); the gate is kept because it is this page's rule for every write. With the fence none of this machinery fires.

---

## Composition logic

### Composition state

Five elements, each carrying the Contract classification of the section titled Composition state in [`execution-contract.md`](../execution-contract.md). Four are derived indexes rebuilt from one sequence-range read filtered to the bound kinds' records, whose kind and act key the composition writes itself. One is extraction-pending. act section is not composition state.

- **open invocations**
  Term open invocations: map from `(kind, act_key)` to the set of intent records (intent event id, invocation id, the payload) of every invocation of the act that has opened and not yet closed, refused, been abandoned or been escalated. Derived index.
  ```
  open invocations 1: IF service identity DOES NOT EQUAL none THEN two open intents MUST NOT share one (kind, act key).
  open invocations 2: IF service identity EQUALS none THEN several open intents MAY share one (kind, act key).
  open invocations 3: The composition MUST rebuild open invocations from the range read filtered to `<kind>.intended` records, less those a later record names through invocation id.
  open invocations 4: [Open] MUST populate open invocations.
  open invocations 5: [Close], [Refuse] and the sweep MUST clear open invocations.
  open invocations 6: [Open]'s pre-check, [Close]'s pre-check and the sweep MUST read open invocations.
  open invocations 7: open invocations MUST NOT hold an intent past the retention horizon.
  ```
  WHY: two kinds with byte-equal keys are two acts. On a multi-node instance a rebuilt map is a journal read that may lag another node's intent, so [Not Open] is a precondition on the caller.
- **act closings**
  Term act closings: map from `(kind, act_key)` to the act's closing records, whoever wrote them. *Derived index*, same rebuild.
  ```
  act closings 1: [Close], [Refuse], [Resolve] and the sweep MUST populate act closings.
  act closings 2: [Open] step 3, [Resolve]'s supersession check and [Read Invocation] MUST read act closings.
  ```
  WHY: every read is a delta above the mark, so a closing older than the mark is reachable only from a local map; without it `act-landed(outcome_event_id)` never fires.
- **sweep closed ids**
  Term sweep closed ids: the set of invocation id values the sweep has closed: an outcome under `recovery = true`, an `<kind>.abandoned`, or an `<kind>.escalated` naming the id. *Derived index*, same rebuild.
  ```
  sweep closed ids 1: The sweep MUST NOT write a closing BEFORE consulting sweep closed ids under the critical section.
  ```
  WHY: two sweep runs — restart and cadence, one node or two — never both close one act.
- **sequence high water**
  Term sequence high water: the highest sequence number the composition has read. Derived index.
  ```
  sequence high water 1: EVERY re-read of Recoverable Invocation MUST read the delta above sequence high water and advance the local maps by the delta.
  sequence high water 2: The mark MAY advance past a sequence number ONLY AFTER settle bound has elapsed since the sequence number's recorded at.
  sequence high water 3: EVERY instance MUST perform a full rebuild at process restart.
  sequence high water 4: EVERY instance MUST perform a full rebuild PER reconciliation cadence.
  sequence high water 5: IF an intent's retention end PRECEDES now THEN EVERY read of open invocations MUST drop the intent.
  sequence high water 6: A lost mark MUST rebuild both maps from the log's beginning.
  ```
  Term settle bound: `journal_write_bound + clock_offset_allowance`.

  Term retention end: `recorded_at + retention_period`.
  WHY: the delta rule needs a prefix-closed read, which Event Log does not grant. Contiguity cannot be the test: next sequence number counts allocations, so a gap is normal. A purge writes no log record, so the horizon is applied on read.
- **findings**
  Term findings: the register of what the sweep could not close and what the instance could not do, written to the deployment's compliance surface. *Extraction-pending*; the named proposed atom is a **Condition Register** *(forthcoming)*.
  ```
  findings 1: The deployment MUST persist a finding for at least the retention period of the kind the finding names.
  findings 2: The deployment MUST persist a finding naming no kind for at least the instance's longest retention period.
  findings 3: A surfacing that fails MUST NOT reject a [Reconcile] run that has landed closings.
  findings 4: The register MUST write a [Finding] as EXACTLY ONE OF act finding, instance finding.
  findings 5: An instance finding MAY omit kind.
  findings 6: A surface MUST NOT read a finding outside the five conditions.
  findings 7: The register MUST set first seen at the first surfacing.
  findings 8: The register MUST NOT move first seen.
  findings 9: The register MUST advance last seen on every run that still sees the condition.
  findings 10: WHEN a run does not see a standing condition:
      findings 10a: The register MUST close the record with last seen at the previous run.
  findings 11: The register MUST open a new record for a recurrence.
  findings 12: The register MUST hold one record per standing condition.
  findings 13: A reader MUST NOT rely on an order across act keys.
  ```
  Term act finding: {finding, kind, act_key, invocation_id, first_seen, run_id}; deduplicates on (invocation id, finding); carries no last seen and no span.

  Term instance finding: {finding, kind, first_seen, last_seen, run_id}; deduplicates on (finding, kind).

  Term first seen: the run that first surfaced a finding; set once (findings 7, findings 8).

  Term last seen: the last run that still saw an instance finding's condition (findings 9, findings 10).
  The five conditions:
  - journal-unavailable — instance finding, no kind: the journal could not be read or written this run ([Reconcile] step 1).
  - store-unavailable — instance finding, kind present: the kind's adopter's store answered unavailable to probe ([Reconcile] step 3).
  - closure-at-risk — act finding: the act's remaining window is below what one more cadence and one more run need ([Reconcile] step 5). Generation acceptance check 3's `service_identity = none` branch reads it.
  - binding duplicate — act finding: two closings or two open intents on one act (the section titled *Which closing stands*). A report under `journal_fence = none`; no check reads it.
  - unbound-kind — act finding: an open intent of a kind the instance no longer binds.

  WHY: no constituent witnesses a surfacing, so no rebuild exists. One record spanning two outages would exempt every intent in the healthy gap (findings 10, findings 11). A store outage is per kind; a journal outage stops every kind (findings 5).
- **act section**
  Not composition state: a **[Lease](../atoms/lease.md)**, bound in *Capability requirement*.
  ```
  act section 1: The deployment MUST supply act section with the Lease atom's semantics.
  act section 2: A host MUST NOT free the critical section on a holder's death (Lease Invariant 3).
  ```

### Capability requirement

Four declared, two optional.

```
Capability requirement 1: The substrate MUST supply the open-upper-bound sequence-range read over the delta range.
Capability requirement 2: The range read MUST answer a page of records with a cursor, a declared page size, and a page-complete signal.
Capability requirement 3: The range read MUST declare the arms invalid-query and unavailable.
Capability requirement 4: The composition MUST surface invalid-query on compliance surface.
Capability requirement 5: The composition MUST NOT retry an invalid-query read unchanged.
Capability requirement 6: EVERY read path of Recoverable Invocation MUST transcribe unavailable at the read path's own position.
Capability requirement 7: EVERY later range read of the instance, from any node, MUST return a record whose record_action returned on an arm that leaves the record appended.
Capability requirement 8: EVERY range read issued after journal write bound has elapsed since a lost-reply append's issue MUST return the record.
Capability requirement 9: A read_record that cannot reach the journal MUST land recording-failure(resolution) at [Resolve].
Capability requirement 10: A read_record that cannot reach the journal MUST NOT answer not-known.
Capability requirement 11: IF the range read, read-your-writes or act section is absent THEN the composition MUST NOT start.
```

Term delta range: the sequence-number range from `sequence_high_water + 1` with no upper bound.

Term open-upper-bound sequence-range read: `EventLog.read` over the delta range, reached through Audit Trail's list-shaped pass-through.

Term read path: [Open] step 3, [Reconcile] step 1, [Read Invocation], and the re-reads at [Close], [Refuse] and [Resolve]. The first three transcribe unavailable as journal-unavailable; the last three land it on the position's recording-failure arm.

Term read-your-writes: Capability requirement 7 and Capability requirement 8 together. The filtering of every range read on action ref, invocation id or a payload field is this composition's code; the substrate offers no such selector.

WHY:
The critical section is released on the holder's return, well inside journal write bound, so a waiter admitted then re-reads before a time-only guarantee says anything, sees no closing, and writes the second one (`-buggy-visible`, rejected). Without Capability requirement 9 an outage at [Resolve]'s purge check reads as absence.

- **bindings**
  Term bindings: the table of act kinds the instance serves, each with its full binding set. *Default:* none.
- **act section**
  Term act section: an instance capability requirement: a [Lease](../atoms/lease.md) host. *Default:* none.
  ```
  act section 3: The deployment MUST share act section across every node of the instance.
  act section 4: EVERY action but [Reconcile] MUST take kind as the first input.
  act section 5: [Open] step 2 and [Resolve] MUST transcribe the atom's unavailable arm as section-unavailable.
  act section 6: EVERY caller on this page MUST discard the atom's not-held arm.
  act section 7: The composition MUST NOT use try_take.
  act section 8: [Open] MUST NOT write the intent record BEFORE taking the critical section.
  act section 9: The invocation MUST hold the critical section through [Close]'s last write.
  act section 10: WHEN an invocation's lease has expired:
      act section 10a: The invocation MUST NOT write.
      act section 10b: The invocation MUST NOT re-take the critical section.
      act section 10c: The invocation MUST discard a constituent reply that arrives after the expiry.
      act section 10d: The invocation MUST return recording-failure(outcome).
  act section 11: The sweep MUST take the critical section on every act key the sweep examines.
  act section 12: The sweep MUST hold the critical section across the pre-check and the closing write.
  act section 13: A sweep run MUST leave a closing write in flight at expiry for the next run.
  act section 14: The critical section MUST admit re-entry by the critical section's own holder alone.
  ```
  Term critical section key: `(kind, act_key)`.

  Term critical section holder: the invocation id for an invocation; the run's own seam-injected id for a sweep run; operator run id for [Resolve].

  Term critical section duration: completion bound for an invocation; sweep lease for a sweep run or an operator.
  WHY: completion bound no shorter, so a conforming invocation is never evicted inside the critical section; no longer, so a stalled holder blocks the sweep for at most the bound. The lease ends the hold; the journal fence keeps a dead holder's write from landing — with the fence Invariant 2 holds with or without the gate, without it Invariant 2 fails with or without the gate. The gate stops a holder starting a write the fence will refuse.
- **journal write bound**
  Term journal write bound: the disclosed bound on a record_action from issue to landing: the substrate's record action completion bound plus issue-to-first-commit latency, with headroom. *Default:* none.
  ```
  journal write bound 1: IF journal write bound EXCEEDS remaining THEN a writer MUST NOT issue a journal write under the critical section.
  ```
  Term sweep lease: `closure_latency + journal_write_bound`.
- **reconciliation cadence**
  Term reconciliation cadence: the interval at which the sweep runs after the mandatory run at process restart. *Default:* none.
- **read bound**
  Term read bound: the disclosed bound on one journal read under the critical section ([Open] step 3, [Close] step 2, [Refuse], [Resolve]). Conditions 3 and 5. *Default:* none.
- **closure latency**
  Term closure latency: the disclosed bound on one whole closure: re-read, probe, `<kind>.recovery_intended`, the closing record, the index update. Condition 5. *Default:* none.
- **run bound**
  Term run bound: the disclosed bound from a [Reconcile] run's start to the last closing it lands, over the largest backlog the deployment sizes for. *Default:* none.
  ```
  run bound 1: The next run MUST NOT start beside a run in flight.
  ```
  WHY: sequentially, run bound is the backlog times closure latency plus one holder's remaining lease per act; condition 1 carries it three times.
- **compensation window**
  Term compensation window: the duration within which the sweep closes an act whose invocation died, from the intent's recorded at. Conditions 1 and 2; rearranged, the at-risk threshold of [Reconcile] step 5. *Default:* none.
- **clock offset allowance**
  Term clock offset allowance: the allowance for comparing a reading from one clock with a stamp or instant from another; the section titled *Where the allowance goes* owns where it is spent. *Default:* none.
- **intent candidates cap**
  Term intent candidates cap: the most store candidates an `<kind>.escalated` record names, each under reference length cap; past it, the count and the range. Sizes the compensation envelope (Invariant 6). *Default:* none.
- **retention period**
  Term retention period: a per-kind binding (*Bindings*, journal); [Reconcile] step 1 and condition 2 read it. *Default:* none.
- **read cap**
  Term read cap: the most invocations [Read Invocation] returns for one act, and the most records per invocation. *Default:* none.
- **compliance surface**
  Term compliance surface: the deployment's surface for the instance's findings (*Composition state* owns the contract); check 3 reads both branches on it. *Default:* none.

### Primitive policy

```
Primitive policy 1: The adopter MUST cap act key under reference length cap.
Primitive policy 2: The composition MUST write act key as a composition-written field of EVERY record the composition appends.
Primitive policy 3: The composition MUST NOT recover act key from an adopter's payload.
Primitive policy 4: EVERY record this composition writes for an invocation MUST carry the invocation's invocation id in the payload.
Primitive policy 5: EVERY check and EVERY journal join MUST pair on invocation id and no other field.
Primitive policy 6: The adopter MUST pass actor ref and credential through to record_action at the intent record.
Primitive policy 7: The composition MUST validate actor ref and credential as non-empty and MUST NOT inspect either.
Primitive policy 8: The adopter MUST NOT call [Open] BEFORE capping actor ref under reference length cap.
Primitive policy 9: intent data MUST carry the invocation's parameters and pairing datum.
Primitive policy 10: intent data MUST NOT carry a field the substrate or the constituent stamps or mints.
Primitive policy 11: The composition MUST write invocation id, intent event id, kind and act key into EVERY record the composition appends.
Primitive policy 12: [Open] MUST size intent data and the kind's largest record against outcome envelope and the substrate's payload cap as the substrate measures a payload.
Primitive policy 13: [Open] MUST refuse invalid-request for an act whose largest record would not fit.
Primitive policy 14: An action signature MUST NOT take now.
Primitive policy 15: [Open] MUST use now for exactly one comparison: step 3's age of an open intent against recorded at under clock offset allowance.
Deleted: Primitive policy 16. Composes 1 owns it: a stamp the composition takes from now is neither the substrate's nor the constituent's.
Primitive policy 17: The adopter's action MUST carry invocation id from [Open] into [Close] and [Refuse] as a parameter of each.
Primitive policy 18: The sweep MUST read now once per run at the sweep's own seam.
```

Term invocation id: injected at the adopter's seam alongside now, fresh per invocation, unique across every node of the instance for the journal's lifetime; opaque, byte-identity.

Term now: the seam-injected reading — at the adopter's seam per invocation, at the sweep's seam once per run, at the operator's seam once per [Resolve] call alongside operator run id, at the reader's seam once per [Read Invocation] call; each as the section titled Logic Confinement Principle in `execution-contract.md` declares it, never read inside the transition.

Term operator run id: injected at the operator's seam once per [Resolve] call; the critical section holder for [Resolve].

Term caller kind: EXACTLY ONE OF human, service — service where actor ref names the kind's service identity.

Term examine edge: `recorded_at + completion_bound + clock_offset_allowance`.

Term in-flight: an open intent for which examine edge EXCEEDS now.

Term aged: an open intent for which examine edge DOES NOT EXCEED now.

Term horizon edge: `recorded_at + retention_period − clock_offset_allowance`.

Term as the substrate measures a payload: the serialized envelope `{action_ref, actor_ref, attestation_id, data}` with the longer of the caller's and the service identity's actor ref, the substrate's attestation id width, and the framing. The sweep's two closings — the recovered outcome (outcome data plus recovery, acting actor ref) and the escalation (store candidates plus the same) — are sized separately; the bound is the larger.

WHY:
The four seam-against-stamp comparisons — step 3's age, the retention drop, the too-young guard, the mark advance — all only exclude; the mark advance comes nearest to deciding and is kept safe by the full rebuild at every restart and cadence. The substrate stamps recorded at at its own seam.

```
Primitive policy 19: IF position EQUALS intent THEN invalid-credential MUST pass through unchanged with nothing written.
NOTE: watch position scoping — every rule of this family scopes by IF position = … (Primitive policy 19 through 40); the corpus's answer is the condition, not a new form.
Primitive policy 20: IF position EQUALS intent THEN [Open] MUST NOT report invalid-request BEFORE reading back by invocation id.
Primitive policy 21: WHEN the intent-position read-back finds the record:
    Primitive policy 21a: The action MUST proceed with a hard alert.
Primitive policy 22: WHEN the intent-position read-back finds nothing:
    Primitive policy 22a: The action MUST land invalid-request.
Primitive policy 23: IF position EQUALS intent THEN recording-failure(step-2) and recording-failure(step-3) MUST land recording-failure(intent).
Primitive policy 24: IF position EQUALS intent THEN the action MUST read intent event id back for recording-failure(step-4).
Primitive policy 25: IF position EQUALS intent THEN the action MUST proceed with a hard alert for recording-failure(step-4).
Primitive policy 26: The action MUST NOT retry after recording-failure(step-4).
Primitive policy 27: IF position EQUALS outcome THEN the action MUST read event id back by invocation id for recording-failure(step-4) and for a retention-source invalid-request.
Primitive policy 28: IF position EQUALS outcome THEN the action MUST return success with a hard alert for recording-failure(step-4) and for a retention-source invalid-request.
Primitive policy 29: IF position EQUALS outcome THEN the writer MUST retry recording-failure(step-2) and recording-failure(step-3) under the critical section, to the terminus at most.
Primitive policy 30: A retry that reaches the terminus MUST land recording-failure(outcome).
Primitive policy 31: IF position EQUALS outcome THEN invalid-credential MUST land recording-failure(outcome).
Primitive policy 32: The composition MUST treat a record_action whose reply is lost as unknown at every position.
Primitive policy 33: The composition MUST NOT retry a lost-reply write blind.
Primitive policy 34: The composition MUST NOT read back a lost-reply write BEFORE journal write bound has elapsed since the issue, as remaining reports.
Primitive policy 35: The composition MUST read back by invocation id through the filtered range read.
Primitive policy 36: WHEN the read-back finds the record:
    Primitive policy 36a: The composition MUST adopt the record.
Primitive policy 37: WHEN the read-back finds nothing:
    Primitive policy 37a: The composition MAY retry.
Primitive policy 38: The composition MUST take the intent's sequence number and recorded at from the filtered range read.
Primitive policy 39: The composition MUST NOT take the intent's sequence number and recorded at from read_record.
Primitive policy 40: IF position EQUALS outcome THEN an invalid-request whose read-back finds nothing MUST land recording-failure(outcome) with a hard alert.
```

WHY:
Intent-position invalid-request has four sources — the substrate's input check, Actor Identity's, the payload fault, the retention configuration — and only the retention source leaves the intent appended; a retry after `step-4` appends a second intent. At the outcome position the act has committed and no arm can refuse it, only report it. The read-back's completeness rests on Event Log Invariant 5 through Audit Trail Invariant 5 and on read-your-writes (Capability requirement 7).

### Action wiring

Six actions and one read. [Open], [Close], [Refuse] and [Yield] are called by an adopter's action around the bound commit; [Reconcile] is the sweep, called by the deployment's scheduler and at every restart; [Resolve] is the operator's close; [Read Invocation] is the read.

```
Action wiring 1: EVERY action's signature MUST export the position of every code that could land on more than one side of the commit.
Action wiring 2: An adopter MUST export no code for the protocol's sake beyond the table below.
Action wiring 3: An adopter's re-entry arm MUST NOT collapse [Read Invocation]'s journal-unavailable into not-known.
Action wiring 4: An adopter's action MUST run: validate the adopter's own inputs; [Open]; the bound commit; return.
Action wiring 5: The adopter MUST close EVERY constituent guard that fires after the intent (not-current-custodian, already-closed, archived) through [Refuse].
Action wiring 6: An adopter's action MUST NOT write to the journal for the act other than through [Open], [Close] and [Refuse].
```

| Source | Code the adopter exports | What the caller does with it |
|---|---|---|
| [Open] | invalid-credential | nothing was written anywhere; the credential is the caller's to fix |
| [Open] | invalid-request | the act's inputs or its outcome's size; the caller's to fix |
| [Open] | `act-in-flight(invocation_id)` ([Act In Flight]) | another invocation of this act is live or awaiting the sweep; retry later |
| [Open] | `act-landed(outcome_event_id)` ([Act Landed]) | the act is done; take the adopter's own re-entry arm, not a second act |
| [Open] | section-unavailable ([Critical Section Unavailable]) | the critical section could not be taken inside the holder's lease; retry |
| [Open] | journal-unavailable ([Journal Unavailable]) | the pre-check's journal read failed; nothing written; retry |
| [Open] | `recording-failure(intent)` ([Recording Failure]) | the intent record did not land; nothing committed; the whole action may be retried |
| the bound commit's pre-commit partition | the constituent's own code, after [Refuse] has landed the refusal | the act was refused and the attempt is recorded |
| [Refuse] | `already-accounted(closing_event_id)` ([Already Accounted]) | another writer already closed this invocation; report the act as accounted for, do not re-run |
| [Refuse] | `recording-failure(refusal, constituent_code)` | the refusal record did not land; the sweep records the attempt instead; never re-run the act |
| the unknown partition, after [Yield] | `recording-failure(outcome)` | the act may exist; its record is the sweep's; never re-run |
| [Close] | `recording-failure(outcome)` | the same |

[Resolve]'s codes are the operator's; [Reconcile]'s journal-unavailable goes to the scheduler. [Read Invocation] is not in the table because it is not called around the commit; it answers journal-unavailable (the act's state unreadable for now) and not-known ([Not Known] — no readable intent), and Action wiring 3 keeps a re-entry arm from re-running an irreversible act whose record is sitting in the journal.

---

#### Open contract

```
open(kind, act_key, actor_ref, credential, intent_data)
  answers open result
  refuses invalid-credential | invalid-request | act-in-flight(invocation_id) | act-landed(outcome_event_id) | section-unavailable | journal-unavailable | recording-failure(intent)
```

Term open result: invocation id and intent event id — what open answers.

Term intent data: intent_data — the caller's payload at [Open], carrying the invocation's parameters and the pairing datum.

Term actor ref: actor_ref — the acting actor Actor Identity attests, reached through the journal.

Term resolve refusal: purged | malformed | too-young | already-abandoned | candidates-over-cap — the reasons [Resolve] gives for an invalid request.

Opens one invocation of the act: takes the critical section, sizes the records, writes the intent record — where the caller's credential is verified — and returns the pair the adopter carries through the commit to [Close].

Steps:

1. **Validate and size.**
   ```
   open step 1.1: [Open] MUST validate act key, actor ref and credential non-empty per Primitive policies.
   open step 1.2: IF caller kind EQUALS service THEN [Open] MUST land invalid-request.
   open step 1.3: [Open] MUST size intent data and the kind's largest record per Primitive policy 12.
   open step 1.4: IF the sized record EXCEEDS the cap THEN [Open] MUST land invalid-request.
   open step 1.5: A step-1 refusal MUST write nothing.
   ```
2. **Take the act's critical section.**
   ```
   open step 2.1: [Open] MUST take the critical section: take((kind, act key), invocation id, completion bound).
   open step 2.2: The take MUST NOT block longer than the current holder's remaining lease.
   open step 2.3: A failed take MUST land section-unavailable with nothing written.
   ```
3. **Pre-check under the critical section.**
   ```
   open step 3.1: [Open] MUST re-read the journal from sequence high water for the act key under the critical section.
   open step 3.2: [Open] MUST take open invocations at (kind, act key) from the re-read.
   open step 3.3: Step 3 MUST NOT decide from a local map hit.
   open step 3.4: [Open] MUST release for an in-flight open intent.
   open step 3.5: [Open] MUST land act-in-flight(invocation id) for an in-flight open intent.
   open step 3.6: IF service identity DOES NOT EQUAL none THEN [Open] MUST release for an aged open intent.
   open step 3.7: IF service identity DOES NOT EQUAL none THEN [Open] MUST land act-in-flight(invocation id) for an aged open intent.
   open step 3.8: WHEN service identity EQUALS none:
       open step 3.8a: [Open] MUST proceed past an aged open intent.
       open step 3.8b: [Open] MUST leave the old intent open.
       open step 3.8c: [Open] MUST surface the old intent on compliance surface.
       open step 3.8d: An operator MUST close the old intent through [Resolve].
       open step 3.8e: The new invocation's records MUST pair on the new invocation id.
   open step 3.9: WHEN repeatable EQUALS no:
       open step 3.9a: [Open] MUST read the act's latest outcome from act closings.
       open step 3.9b: IF an outcome for the act key EXISTS THEN [Open] MUST release.
       open step 3.9c: IF an outcome for the act key EXISTS THEN [Open] MUST land act-landed(outcome event id).
   open step 3.10: [Open] MUST bound the step-3 read by read bound.
   open step 3.11: An [Open] whose read exhausts the lease MUST release.
   open step 3.12: An [Open] whose read exhausts the lease MUST land section-unavailable with nothing written.
   open step 3.13: WHEN the step-3 read fails:
       open step 3.13a: [Open] MUST release.
       open step 3.13b: [Open] MUST land journal-unavailable with nothing written.
   ```
4. **Intent record.**
   ```
   open step 4.1: IF journal write bound EXCEEDS remaining THEN [Open] MUST NOT write the intent record.
   open step 4.2: WHEN journal write bound EXCEEDS remaining:
       open step 4.2a: [Open] MUST release.
       open step 4.2b: [Open] MUST land section-unavailable.
   open step 4.3: [Open] MUST write AuditTrail.record_action(action ref set to `<kind>.intended`, actor ref, credential, data set to intent payload), answering intent event id.
   open step 4.4: Step 4's arms MUST follow the intent position of the rejection-mapping rule.
   ```
5. **Populate and return.**
   ```
   open step 5.1: [Open] MUST populate open invocations at (kind, act key) with the intent.
   open step 5.2: [Open] MUST return invocation id and intent event id.
   open step 5.3: [Open] MUST hold the critical section at return.
   ```

WHY:
The service identity closes acts and never opens them (check 5). Step 3 reads the journal because on a multi-node instance a local absence is not a miss. open step 3.4 protects pairing, not Invariant 2: two acts of one act key in flight carry pairing datum values probe cannot tell apart (Invariant 3). open step 3.8's several open intents are the report-only deployment's declared degradation, not a binding duplicate; blocking every crashed act's key until purge would trade one orphan for an unusable key. open step 3.9 reads act closings because the delta begins above the mark; the constituent's own `already-*` arm is the authoritative guard. open step 3.13: the cheapest conforming implementation reads a failed range read as empty and appends a second live intent. open step 4.4's invalid-credential is the seam at which authentication precedes commitment (Invariant 1).

---

#### Close contract

```
close(kind, act_key, invocation_id, intent_event_id, actor_ref, credential, outcome_action_ref, outcome_data)
  answers close result
  refuses not-open | recording-failure(outcome)
```

Term close result: outcome event id and landed by — what close answers.

Term outcome data: outcome_data — the caller's payload at [Close].

Term outcome action ref: outcome_action_ref — the action ref [Close] writes on the outcome record.

Term outcome event id: outcome_event_id — the event id the journal assigns the outcome record.

Term landed by: landed_by — which writer landed the outcome: the operator, or the sweep.

Writes the act's outcome record after the bound commit has returned, under the critical section [Open] took, and releases the critical section. The one action that can find its own work already done.

```
close 1: The adopter MUST pass [Close] the actor ref [Open] was given for the invocation.
close 2: The composition MUST NOT retain state between [Open] and [Close].
close 3: [Close] and [Refuse] MUST take intent event id.
close 4: The adopter's action MUST decide not-open from the invocation's own [Open] result ([Not Open]).
```

Steps:

1. **Confirm standing.**
   ```
   close step 1.1: [Close] MUST query remaining((kind, act key), invocation id).
   close step 1.2: WHEN journal write bound EXCEEDS remaining OR remaining EQUALS none:
       close step 1.2a: [Close] MUST write nothing.
       close step 1.2b: [Close] MUST discard the commit's reply.
       NOTE: watch negative capability — an obligation to discard a reply already in hand (close step 1.2b, act section 10c).
       close step 1.2c: [Close] MUST return recording-failure(outcome).
   close step 1.3: Step 1 MUST NOT vary with retry terminus.
   ```
2. **Pre-check under the critical section — proceed as landed.**
   ```
   close step 2.1: [Close] MUST re-read the journal from sequence high water for the invocation id under the critical section.
   close step 2.2: WHEN a closing record naming the invocation id is an outcome:
       close step 2.2a: [Close] MUST adopt the outcome as the invocation's own.
       close step 2.2b: [Close] MUST release.
       close step 2.2c: [Close] MUST return outcome event id and landed by.
       close step 2.2d: IF the outcome carries resolved by THEN [Close] MUST return landed by set to operator.
       close step 2.2e: IF the outcome carries no resolved by THEN [Close] MUST return landed by set to sweep.
   close step 2.3: WHEN a closing record naming the invocation id is an abandonment OR an escalation:
       close step 2.3a: [Close] MUST NOT adopt the record.
       close step 2.3b: [Close] MUST release and return recording-failure(outcome).
   close step 2.4: WHEN the step-2 re-read fails:
       close step 2.4a: [Close] MUST write nothing.
       close step 2.4b: [Close] MUST return recording-failure(outcome).
   close step 2.5: Step 2 MUST run under every journal fence value.
   ```
3. **Outcome record.**
   ```
   close step 3.1: [Close] MUST write AuditTrail.record_action(action ref set to outcome action ref, actor ref, credential, data set to outcome payload), answering outcome event id.
   close step 3.2: Step 3's arms MUST follow the outcome position of the rejection-mapping rule.
   close step 3.3: A non-retention invalid-request at step 3 MUST land recording-failure(outcome) with a hard alert.
   close step 3.4: [Close] MUST NOT retry after recording-failure(step-2), recording-failure(step-3) or a lost reply BEFORE re-running step 2.
   close step 3.5: IF journal write bound EXCEEDS remaining THEN [Close] MUST NOT retry.
   close step 3.6: WHEN retry terminus EQUALS counted(n):
       close step 3.6a: [Close] MAY retry at most n attempts.
   close step 3.7: A retry cut short by the lease or the last attempt MUST land release and recording-failure(outcome).
   close step 3.8: An invalid-credential at step 3 MUST land release and recording-failure(outcome).
   ```
4. **Clear and release.**
   ```
   close step 4.1: [Close] MUST remove the invocation id from open invocations at (kind, act key).
   close step 4.2: [Close] MUST release the critical section.
   close step 4.3: [Close] MUST return outcome event id and landed by set to invocation.
   ```

WHY:
Check 2 reads an outcome without recovery whose actor ref differs from its intent's as a conformance failure (close 1). Every route from an id to an event id reads the intent's payload, which [Resolve] takes an argument to avoid (close 3). close step 1.2 cannot tell a yielded invocation from one never opened; step 0 is the caller's precondition. close step 2.3: an abandonment or escalation says the act was not accounted for, and the correction is [Resolve]'s `supersedes` path. close step 2.4 lands on the position's own arm because the act has committed and the caller's next move is fixed. Step 2 under a fence cannot land a write; without one it is load-bearing — a paused invocation passes step 1, wakes after the sweep closed the act, and the re-read stops a second outcome — and still a mitigation, since a pause between step 2 and the write appends beside the sweep's record (journal fence none 1). close step 3.3's act is escalated as outcome-unrecordable.

---

#### Refuse contract

```
refuse(kind, act_key, invocation_id, intent_event_id, actor_ref, credential, reason, constituent_code)
  answers refusal_event_id
  refuses not-open | already-accounted(closing_event_id) | recording-failure(refusal, constituent_code)
```

Closes an intent whose bound commit did not commit — the constituent refused on a pre-commit arm — so the intent does not stand open for the sweep to probe.

Steps:

0. **Not open.**
   ```
   refuse step 0.1: The adopter's action MUST decide not-open from the invocation's own [Open] result ([Not Open]).
   refuse step 0.2: [Refuse] MUST write nothing for a pair no [Open] returned.
   NOTE: watch rule inheritance — refuse step 0.1 and refuse step 2.1 restate [Close]'s close 4 and close step 2.1 for [Refuse] rather than inheriting; the grammar has no inheritance form. Council read 50's repoint made the first pair an EXACT restatement: both now oblige the adopter's action, where before they differed by naming [Close] and [Refuse], so `W-duplicate-proposition` reports it where it did not. That is the watch gaining its sharpest specimen rather than a defect arriving — one proposition, two labels, no form to inherit with — and it is left standing as the evidence the inheritance ruling will need.
   ```
1. **Confirm standing, before any read.**
   ```
   refuse step 1.1: [Refuse] MUST NOT read BEFORE querying remaining((kind, act key), invocation id).
   refuse step 1.2: WHEN journal write bound EXCEEDS remaining OR remaining EQUALS none:
       refuse step 1.2a: [Refuse] MUST write nothing.
       refuse step 1.2b: [Refuse] MUST return recording-failure(refusal, constituent code).
   refuse step 1.3: A yielded caller MUST NOT read at [Close] or [Refuse].
   refuse step 1.4: A yielded caller MUST NOT adopt at [Close] or [Refuse].
   ```
2. **Re-read under the critical section.**
   ```
   refuse step 2.1: [Refuse] MUST re-read the journal from sequence high water for the invocation id under the critical section.
   refuse step 2.2: IF a closing record naming the invocation id EXISTS THEN [Refuse] MUST land already-accounted(closing event id).
   refuse step 2.3: IF a closing record naming the invocation id EXISTS THEN [Refuse] MUST append nothing.
   refuse step 2.4: [Refuse] MUST NOT report already-accounted as not-open.
   ```
3. **Refusal record.**
   ```
   refuse step 3.1: [Refuse] MUST write `<kind>.refused` carrying invocation id, intent event id, kind, act key, reason and constituent code under the caller's credential.
   refuse step 3.2: The refusal record's arms MUST follow the intent position.
   refuse step 3.3: [Refuse] MUST read the refusal back by invocation id for recording-failure(step-4) and for a retention-source invalid-request.
   refuse step 3.4: [Refuse] MUST NOT retry after step-4 or the retention-source invalid-request.
   refuse step 3.5: recording-failure(step-2) and recording-failure(step-3) MUST land recording-failure(refusal, constituent code) with the intent left open.
   refuse step 3.6: A lost reply whose one read-back finds nothing MUST land recording-failure(refusal, constituent code) with the intent left open.
   refuse step 3.7: invalid-credential MUST land recording-failure(refusal, constituent code) with the intent left open.
   refuse step 3.8: A non-retention invalid-request MUST land recording-failure(refusal, constituent code) with the intent left open.
   refuse step 3.9: [Refuse] MUST clear the map.
   refuse step 3.10: [Refuse] MUST release the critical section.
   refuse step 3.11: The composition MUST NOT suppress a refusal record.
   ```

WHY:
Read before remaining and a lease-expired invocation reports already-accounted for a closing it had no standing to observe. A refusal that never lands leaves the intent open; the sweep writes the abandonment or escalation without the constituent's reason, which died with the invocation — so `recording-failure(refusal, constituent_code)` means the attempt is recorded by the sweep instead, never a reason to re-run, and the second slot tells the caller why.

---

#### Yield contract

```
yield(kind, act_key, invocation_id)
  answers ok
```

```
yield 1: [Yield] MUST release the critical section without writing.
yield 2: The adopter's action MUST call [Yield] on the unknown partition.
yield 3: No adopter MAY touch act section directly.
yield 4: [Yield] MUST NOT close the intent.
```

---

#### Resolve contract

```
resolve(kind, act_key, invocation_id, intent_event_id, actor_ref, credential, disposition)
  answers closing_event_id
  refuses already-accounted(closing_event_id) | not-known | section-unavailable | invalid-credential | invalid-request(resolve refusal) | recording-failure(resolution)
```

The human-attested close: an operator closes an open intent the sweep cannot — under `service_identity = none`, or for an escalated act the operator has investigated — supplying the disposition the operator's own run of the adopter's probe supports.

```
resolve 1: The operator MUST supply disposition as EXACTLY ONE OF outcome(outcome action ref, outcome data), abandoned(cause), escalated(candidates).
resolve 2: The substrate MUST validate the operator's credential at the closing record_action and nowhere earlier.
resolve 3: A credential failure MUST land invalid-credential with the critical section released and nothing appended.
resolve 4: [Resolve] MUST take the critical section: take((kind, act key), operator run id, sweep lease).
resolve 5: The take MUST NOT block longer than the holder's remaining lease.
resolve 6: A failed take MUST land section-unavailable.
resolve 7: IF journal write bound EXCEEDS remaining THEN [Resolve] MUST NOT write.
resolve 8: [Resolve] MUST re-read the act's records under the critical section.
resolve 9: An outcome or a refusal naming the invocation id MUST land already-accounted(closing event id).
resolve 10: An invocation id with no readable intent record MUST land not-known.
resolve 11: [Resolve] MUST read the intent by read_record(intent event id).
resolve 12: An intent whose payload the substrate reports Purged MUST land invalid-request(purged).
resolve 13: EVERY closing [Resolve] writes over an existing record MUST carry supersedes set to that record's event id.
resolve 14: WHEN no closing stands:
    resolve 14a: [Resolve] MAY write any disposition as the act's closing.
resolve 15: WHEN an escalated record stands:
    resolve 15a: [Resolve] MUST name the record in supersedes for any disposition.
resolve 16: WHEN an abandoned record stands:
    resolve 16a: [Resolve] MAY supersede the record ONLY IF disposition EQUALS outcome.
resolve 17: An abandoned disposition over an abandoned record MUST land invalid-request(already-abandoned).
resolve 18: An abandoned disposition for an in-flight intent MUST land invalid-request(too-young).
resolve 19: The too-young guard MUST compare against now injected at the operator's seam.
resolve 20: WHEN commit fence EQUALS none:
    resolve 20a: [Resolve] MUST admit the operator's abandoned disposition as the operator's attestation that the store has been quiet for as long as the operator's judgment requires.
resolve 21: [Resolve] MUST write the closing record under the operator's own credential with recovery set to true, resolved by set to actor ref, acting actor ref set to the intent's actor ref, and no recovery_intended.
resolve 22: [Resolve] MUST release after the write.
resolve 23: The closing write's arms MUST follow the outcome position.
resolve 24: After step-4 or the retention-source invalid-request, [Resolve] MUST read the record back by invocation id and return success with a hard alert.
resolve 25: [Resolve] MUST NOT retry after step-4 or the retention-source invalid-request.
resolve 26: step-2, step-3 and a lost reply after an empty read-back MUST land recording-failure(resolution).
resolve 27: invalid-request MUST carry the cause: malformed, candidates-over-cap, purged, already-abandoned, too-young.
resolve 28: A candidate list exceeding intent candidates cap MUST land invalid-request(candidates-over-cap).
```

WHY:
Audit Trail projects no read that validates a credential without appending, so validation before the take had no call to make; both substitutes broke it (an early record_action appends before the critical section; a direct `attest` mints an orphan attestation on every typo). resolve 11 is why [Resolve] takes intent event id: every route from an invocation id to an event id reads the payload the purge destroyed, and without the id a lawfully destroyed record answers not-known. resolved by names the operator, not a record; without resolve 13 a lawful resolution read as a binding duplicate (`-buggy-supersede`, rejected). The transitive rule is a prose repair the model does not confirm. resolve 19: a reading nothing bounds must not decide a destructive record (`-buggy-opclock` violates Invariant 5 against `probe-reportonly-clean`). resolve 23: a retry after `step-4` appends the duplicate in a deployment that has the fence and needs no pause to do it. resolve 27: the five causes imply three moves — fix and retry, nothing to do, wait and re-issue unchanged.

---

#### Reconcile contract

```
reconcile()
  answers reconcile tally
  refuses journal-unavailable
```

Term reconcile tally: examined, closed, abandoned, escalated, reported, skipped, closed already, surfaced and unreached — what reconcile answers; reconcile is the one action with no kind: the run sweeps every bound kind.

The sweep. Runs at every process restart and on reconciliation cadence; reads now once at the sweep's own seam.

```
reconcile 1: WHEN step 1's enumeration fails:
    reconcile 1a: The run MUST write nothing.
    reconcile 1b: The run MUST open or advance the instance finding journal-unavailable on compliance surface.
    reconcile 1c: The run MUST return journal-unavailable.
reconcile 2: WHEN service identity EQUALS none for the act's kind:
    reconcile 2a: The run MUST take the critical section.
    reconcile 2b: The run MUST run probe under the critical section.
    reconcile 2c: The run MUST release the critical section.
    reconcile 2d: The run MUST NOT write for the act.
    reconcile 2e: The run MUST report every closing step's result on compliance surface.
    reconcile 2f: The run MUST count the act in reported.
reconcile 3: A run over a mixed instance MUST close the kinds that declare a service identity.
reconcile 4: A run over a mixed instance MUST report the kinds that declare no service identity.
reconcile 5: The run MUST sum the counts over both.
```

Term examined: an act step 1 kept and the run reached — took, or attempted to take, the act's critical section.

Term partition: `closed + abandoned + escalated + reported + skipped + closed_already = examined`.

Term surfaced: the unbound-kind intents step 1 reports; outside the partition.

Term unreached: the acts step 1 kept that the run stopped short of after the service identity's credential was refused; outside the partition.

Term closed already: an act step 2's re-read finds another writer closed since step 1.

Term skipped: an act the run examined and left for the next run — a failed take; a probe answering unavailable; a closing write whose retries the lease cut short; a closing write left for the next run after step 3 counted the act; an act whose remaining fell below journal write bound at step 2 before any write; an act the fence refused a write for while the intent was short of abandon edge. The list is exhaustive.

Term reported: an act the run examined, of a kind whose service identity EQUALS none.

WHY:
Without reconcile 1 a journal outage returns zero counts and step 5 surfaces nothing, silently suppressing the at-risk report the window rests on. surfaced and unreached sit outside the partition because neither act was examined; counting either inside broke the identity. A persistently high closed already says the run is racing another run or an operator. reported is in the partition because the run examined the act, and not skipped because an operator, not a later run, will close it.

1. **Enumerate between two edges.**
   ```
   reconcile step 1.1: The run MUST rebuild open invocations and act closings from the substrate's range read.
   reconcile step 1.2: The run MUST keep EVERY aged intent for which now PRECEDES horizon edge, and no other intent.
   NOTE: watch applicability — the pass's domain is carried by a relative clause (reconcile step 1.2); the corpus has no WHERE.
   reconcile step 1.3: The run MUST make reconcile step 1.2's comparison from the sweep's seam reading against the substrate's stamp, under clock offset allowance.
   reconcile step 1.4: The run MUST keep every closing record in the delta for step 5.
   reconcile step 1.5: The run MUST discard the kept closing records with the run.
   reconcile step 1.6: Step 1 MUST surface EVERY unbound-kind intent per Binding 4 through 6.
   ```
2. **Take the act's critical section and re-read.**
   ```
   reconcile step 2.1: The run MUST take the critical section for each kept intent: take((kind, act key), run id, sweep lease).
   reconcile step 2.2: The take MUST NOT block longer than the current holder's remaining lease.
   reconcile step 2.3: A take that fails after the wait MUST count the act in skipped and surface the act in step 5.
   reconcile step 2.4: Under the critical section, the run MUST re-read open invocations at (kind, act key) and sweep closed ids.
   reconcile step 2.5: IF a closing record naming the invocation id landed since step 1 THEN the run MUST release.
   reconcile step 2.6: IF a closing record naming the invocation id landed since step 1 THEN the run MUST count the act in closed already.
   reconcile step 2.7: WHEN journal write bound EXCEEDS remaining:
       reconcile step 2.7a: The run MUST count the act in skipped.
   ```
3. **Probe the store.**
   ```
   reconcile step 3.1: The run MUST call the adopter's bound probe(act key, intent payload).
   reconcile step 3.2: WHEN probe EQUALS committed(outcome action ref, outcome data):
       reconcile step 3.2a: The run MUST write `<kind>.recovery_intended` under the service identity with data carrying invocation id, intent event id, act key and plan set to outcome.
       reconcile step 3.2b: The run MUST write the outcome record outcome action ref under the service identity with data set to recovered outcome payload.
       reconcile step 3.2c: The run MUST count closed.
   reconcile step 3.3: A later run MAY write a second recovery_intended for the act.
   reconcile step 3.4: WHEN probe EQUALS not-committed AND commit fence EQUALS declared AND the intent is past abandon edge:
       reconcile step 3.4a: The run MUST write `<kind>.abandoned` under the service identity with data carrying invocation id, intent event id, act key and cause set to not-committed.
       reconcile step 3.4b: The run MUST count abandoned.
   reconcile step 3.5: WHEN probe EQUALS not-committed AND commit fence EQUALS none:
       reconcile step 3.5a: The run MUST write `<kind>.escalated` with cause set to not-observed.
       reconcile step 3.5b: The run MUST count escalated.
   reconcile step 3.6: WHEN probe EQUALS not-committed AND commit fence EQUALS declared AND the intent is short of abandon edge:
       reconcile step 3.6a: The run MUST write nothing.
       reconcile step 3.6b: The run MUST count skipped.
   reconcile step 3.7: The sweep MUST NOT re-run an act.
   reconcile step 3.8: WHEN probe EQUALS undecidable(candidates):
       reconcile step 3.8a: The run MUST write `<kind>.escalated` under the service identity with data carrying invocation id, intent event id, act key, cause set to undecidable and store candidates set to candidates.
       reconcile step 3.8b: The run MUST surface the act on compliance surface.
       reconcile step 3.8c: The run MUST count escalated.
   reconcile step 3.9: store candidates MUST NOT carry more than intent candidates cap references.
   reconcile step 3.10: Past the cap, the escalated record MUST carry the count and the range.
   reconcile step 3.11: The sweep MUST NOT choose among candidates.
   reconcile step 3.12: The sweep MUST NOT write an outcome the sweep did not read.
   reconcile step 3.13: WHEN probe EQUALS unavailable:
       reconcile step 3.13a: The run MUST write nothing.
       reconcile step 3.13b: The run MUST release and count skipped.
       reconcile step 3.13c: The run MUST open or advance the instance finding store-unavailable for the act's kind.
   reconcile step 3.14: The sweep MUST NOT write abandoned for a store outage.
   reconcile step 3.15: EVERY closing write's arms MUST follow the outcome position.
   reconcile step 3.16: After step-4 or the retention-source invalid-request, the run MUST read the record back.
   reconcile step 3.17: The run MUST leave EVERY step-2 arm and step-3 arm not landed within the lease for the next run.
   reconcile step 3.18: The run MUST surface an invalid-credential for the service identity on compliance surface at once.
   reconcile step 3.19: The run MUST NOT write further under the credential until reconfigured.
   reconcile step 3.20: A non-retention invalid-request on a closing write MUST close the act as `<kind>.escalated` with cause set to outcome-unrecordable.
   ```
4. **Update and release.**
   ```
   reconcile step 4.1: The run MUST update open invocations.
   reconcile step 4.2: The run MUST update act closings.
   reconcile step 4.3: The run MUST update sweep closed ids.
   reconcile step 4.4: The run MUST release the critical section.
   ```
5. **Liveness, and the duplicate scan.**
   ```
   reconcile step 5.1: IF at risk threshold DOES NOT EXCEED intent age THEN the run MUST surface an examined or skipped intent whose closing has not landed as the act finding closure-at-risk.
   reconcile step 5.2: The run MUST count closing records by invocation id across the delta step 1 kept, discounting supersession PER the section titled Which closing stands.
   reconcile step 5.3: The run MUST count open intents by (kind, act key) across the delta, under the service identity EQUALS none branch of the section titled Which closing stands.
   reconcile step 5.4: The run MUST surface EVERY invocation id or (kind, act key) with more than one on compliance surface as binding duplicate.
   reconcile step 5.5: The duplicate scan MUST run over the delta.
   reconcile step 5.6: The duplicate scan MUST NOT run over the horizon.
   reconcile step 5.7: The duplicate scan MUST run under every journal fence value.
   reconcile step 5.8: The run MUST return the counts.
   ```

Term at risk threshold: `compensation_window − 2 × run_bound − reconciliation_cadence − clock_offset_allowance`.

Term intent age: `now − recorded_at`.

WHY:
Below the examine edge the invocation may still hold its lease and a take would wait on a live act, which the cadence does not budget; the second writer is forbidden by the critical section, not the edge (the model holds with the edge removed at zero skew). The upper edge is an inequality because the direction of the allowance decides whether an intent whose closings may already be purge-eligible is examined; a re-close past it would be the duplicate. reconcile step 3.4 is final only under a fence past the abandon edge; reconcile step 3.5's not-observed is the honest degree for a fenceless store, where a paused process may still land the write. reconcile step 3.13's per-act count carries no span; the instance finding does. reconcile step 3.20: an outcome that outgrew the envelope cannot shrink, and the escalation record fits.

at risk threshold is Invariant 4's inequality rearranged: subtract the terms still ahead of an intent this run can see — this run's remaining pass, a cadence, the next run's pass, the allowance — and leave out the terms already spent. The scan rides the delta because a duplicate is made by a record landing and every duplicate appears in exactly one run's delta; with the fence a finding is a conformance failure in the fence itself, without it the scan is the degraded Invariant 2's detection clause.

```
reconcile 6: An actor that is not a writer MUST NOT write a closing record.
reconcile 7: Two sweep runs MUST serialize on the critical section per act and on sweep closed ids under the critical section.
```

---

#### Read Invocation contract

```
read_invocation(kind, act_key, optional invocation_id)
  answers invocation report
  refuses not-known | journal-unavailable
```

Term invocation report: invocations, a sequence of invocation entry; the act-level binding duplicate, true | false, which reports two open intents on the act key; and more — what read_invocation answers.

Term invocation entry: invocation id; state; the entry-level binding duplicate, true | false, which reports two closings on the invocation id; records; and more — one invocation in an invocation report.

Reads the act's invocations — each intent and whichever closing record names it — through the same rebuild, for an adopter's re-entry arm and for an auditor.

```
read invocation 1: [Read Invocation] MUST perform the rebuild under now injected at the reader's own seam.
read invocation 2: [Read Invocation] MUST return one entry per invocation id, at most read cap of the most recent, with more set to true where the act has older ones.
read invocation 3: WHEN invocation id is given:
    read invocation 3a: [Read Invocation] MUST return one entry.
read invocation 4: records MUST carry the intent, the recovery_intended records and the closing records.
read invocation 5: [Read Invocation] MUST cap the recovery_intended records and the closing records at the most recent read cap, with more set to true beyond.
read invocation 6: [Read Invocation] MUST NOT exclude a superseded record from records.
read invocation 7: The entry-level binding duplicate MUST report the closings key.
read invocation 8: The act-level binding duplicate MUST report the intents key.
read invocation 9: WHEN service identity EQUALS none:
    read invocation 9a: The act-level binding duplicate MUST read false.
read invocation 10: [Read Invocation] MUST read the entry's state from the table in the section titled Which closing stands.
read invocation 11: [Read Invocation] MUST transcribe the range read's unavailable arm as journal-unavailable.
read invocation 12: [Read Invocation] MUST answer not-known for an act key with no readable intent.
read invocation 13: [Read Invocation] MUST NOT take a critical section.
read invocation 14: [Read Invocation] MUST NOT write.
read invocation 15: An adopter that decides a write on [Read Invocation]'s answer MUST decide the write under the critical section through [Open]'s pre-check.
```

WHY:
The rebuild's comparisons are against the substrate's stamps, so the reader is a seam (read invocation 1). Closings are capped because the degraded Invariant 2 admits them in plurality. Without read invocation 11 the cheapest implementation answers not-known for a key whose intent and outcome are sitting in the journal. read invocation 12 is also what a wholly purged act answers — the destroyed payload carried the key — the one admitted exception to the section titled *Lawful destruction is answered before absence* in `pressure-testing.md`; read_record by event id still answers *Purged*.

### Wiring decision

*One act, one writer, one closer.*

WHY:
An irreversible act and its account are two writes no transaction spans, and closing the partial after the opening process is dead is a second writer by definition. The protocol is sound exactly when the two writers cannot both write for one act, the second cannot mistake in-flight work for a dead invocation's, and the second cannot write what it did not read — properties of the critical section, the edges and the probe, none of the adopter's act. A methodology rule does not stop twenty authors writing it twenty ways or spare the formal layer twenty models; the higher-order composition test's threshold is five exact instances and this clears it several times over ([`tools/survey/protocol_prose.py`](../tools/survey/protocol_prose.py)). What differs between adopters is the binding set; anything else is a deviation from a closed list. One page carries the protocol, one model proves it, one gate attacks it; an adopter's action shrinks to *validate, open, commit, close*.

### Bindings

An adopter binds the parameters below once per **act kind**. The instance's bindings Configuration entry is the table of bound kinds — configuration, not state.

```
Binding 1: [Reconcile] MUST read completion bound, commit fence, probe, service identity, retention period and the `<kind>.*` vocabulary of every intent from the bindings table by the intent's kind.
Binding 2: The deployment MUST refuse a configuration change that unbinds a kind with an open intent.
Binding 3: The refusal Binding 2 names MUST land on compliance surface with the reason.
Binding 4: [Reconcile] step 1 MUST surface EVERY `<kind>.intended` record whose kind the bindings table does not serve and which no closing record of any kind names, once per run, on compliance surface.
Binding 5: [Reconcile] MUST NOT close an intent Binding 4 surfaces.
Binding 6: [Reconcile] MUST bound the pass Binding 4 names by the instance's longest retention period.
Binding 7: The adopter MUST declare EVERY binding in the adopter's own Composes entry for this composition.
Binding 8: The adopter MUST declare a need outside the bindings as a deviation (Edge cases, Declared deviations).
```

WHY:
An unbound kind has no probe, no completion bound and no retention period, so nothing downstream can close or enumerate it. Unbinding is a deployment-plane operation with no signature block and no code. Check 3 exempts Binding 4's intents.

- **act key**
  Term act key: the identity of one act, opaque and adopter-typed, with equality by byte-identity: the field or tuple under which two invocations are the same act. The critical section is keyed by it; the sweep pairs by it; the pre-check reads by it.
  ```
  act key 1: The adopter MUST know act key before [Open].
  act key 2: An act whose key is minted by the commit MUST bind the key the adopter can name before the commit and declare the minted-key deviation.
  ```
- **commit**
  Term commit: the adopter's constituent call that makes the act, with its rejection arms partitioned by the adopter.
  ```
  commit 1: The adopter MUST partition the constituent's arms as EXACTLY ONE OF pre-commit, committed, unknown.
  commit 2: The adopter MUST close a pre-commit arm through [Refuse].
  commit 3: The adopter MUST return the constituent's own code for a pre-commit arm.
  commit 4: The adopter MUST close a committed arm through [Close].
  commit 5: The adopter MUST transcribe the constituent's partition as the constituent states the partition.
  commit 6: The adopter MUST treat a lost reply as unknown.
  commit 7: The adopter MUST treat a reply the constituent's contract does not declare pre-commit as unknown.
  commit 8: WHEN the arm EQUALS unknown:
      commit 8a: The adopter MUST NOT call [Close].
      commit 8b: The adopter MUST NOT call [Refuse].
      commit 8c: The adopter MUST call [Yield].
      commit 8d: The adopter MUST return recording-failure(outcome) to the caller.
  commit 9: The adopter MAY call [Refuse] ONLY IF the constituent declares the arm pre-commit.
  commit 10: The binding MUST declare commit fence as EXACTLY ONE OF none, declared.
  commit 11: A declared commit fence MUST declare the conveyance: a deadline parameter on the constituent's call, or a store-applied request-scoped deadline on every write of the adopter's instance.
  commit 12: The adopter MUST NOT declare a relative request timeout as commit fence.
  commit 13: WHEN commit fence EQUALS declared:
      commit 13a: The sweep MAY write abandoned ONLY IF probe answers not-committed for an intent past abandon edge.
  commit 14: WHEN commit fence EQUALS none:
      commit 14a: The sweep MUST NOT write abandoned for the act kind.
      commit 14b: The sweep MUST write escalated for a not-committed answer.
  ```
  Term commit fence: an instance capability requirement on the constituent's store under which a write issued under the act's critical section is never applied after the fence's instant; none or declared.

  WHY: a lost reply mapped to a refusal closes the intent over an act that may have committed, and nothing looks at it again. No atom in this library declares a deadline parameter today.
- **pairing datum**
  Term pairing datum: the field the intent record and the constituent's record both carry by construction: the seam-injected now passed into commit, an adopter-minted nonce stored by the constituent, or a constituent-minted id the store exposes by the intent's parameters.
  ```
  pairing datum 1: intent data MUST carry pairing datum.
  pairing datum 2: probe MUST match on pairing datum by equality.
  pairing datum 3: A journal join MUST NOT pair on pairing datum.
  pairing datum 4: The adopter MAY bind a seam-injected now as pairing datum ONLY IF no two serialized invocations of one act key carry the same reading on any node of the instance.
  pairing datum 5: The adopter MUST declare the obligation pairing datum 4 names where the datum is a seam-injected now.
  pairing datum 6: WHEN pairing datum EQUALS none:
      pairing datum 6a: probe MUST NOT answer committed.
  ```
  WHY: two nodes' seams may read one instant within clock offset allowance, and the critical section separates invocations without separating stamps; the failure is safe (undecidable, escalated) but a nonce avoids it.
- **repeatable**
  Term repeatable: `yes` or no: whether two invocations against one act key are two acts or one act attempted twice.
  ```
  repeatable 1: [Open]'s act-landed refusal MAY fire ONLY IF repeatable EQUALS no.
  ```
- **probe**
  Term probe: a read of the adopter's store keyed by act key and pairing datum, answering for the sweep: did the act commit, and with what outcome.
  ```
  probe 1: probe MUST answer EXACTLY ONE OF committed(outcome action ref, outcome data), not-committed, undecidable(candidates), unavailable.
  probe 2: probe MAY answer committed ONLY IF exactly one store record matches pairing datum.
  probe 3: probe MAY answer undecidable(candidates) ONLY IF more than one record matches pairing datum OR payload match holds.
  probe 4: probe MUST map EVERY constituent read rejection to unavailable.
  probe 5: probe MUST NOT map a constituent read rejection to not-committed.
  probe 6: outcome data MUST carry only what the store re-derives.
  probe 7: WHEN the outcome's authoritative datum exists nowhere but in the dead invocation's memory:
      probe 7a: probe MUST answer undecidable.
  ```
  Term payload match: pairing datum EQUALS none AND at least one store record matches the intent's payload.
- **completion bound**
  Term completion bound: the longest a conforming invocation of the kind takes from [Open]'s critical section take to [Close]'s last write, including the constituent round-trip. The lease length of the critical section, the lower edge of the sweep, the first term of the liveness inequality. Read against the seam clock [Open] was injected with.
- **commit round trip**
  Term commit round trip: the longest one commit call takes from issue to reply; charged by lease spend.
- **probe round trip**
  Term probe round trip: the longest one probe call takes from issue to answer; charged by closure spend.
- **journal**
  Term journal: the Audit Trail instance the records go to, and the action ref vocabulary of the kind.
  ```
  journal 1: EVERY act kind of an instance MUST share one Audit Trail instance.
  journal 2: The vocabulary of a kind MUST declare `<kind>.intended`, the enumerated outcome refs `<kind>.<outcome>`, and `<kind>.refused`.
  journal 3: The composition MUST derive `<kind>.recovery_intended`, `<kind>.abandoned` and `<kind>.escalated` from the vocabulary.
  journal 4: The rebuild MUST classify a record as an outcome by membership in the enumerated outcome refs.
  journal 5: The adopter MUST NOT declare audit as a kind.
  journal 6: The substrate's retention policy MUST resolve EVERY `<kind>.*` record to one fixed policy ref of retention period, selected on the `<kind>` prefix of action ref and nothing else.
  journal 7: IF the substrate admits one policy ref per instance and no selector THEN kinds with different retention periods MUST run under different Recoverable Invocation instances.
  journal 8: The sweep MUST derive the upper edge from retention period.
  journal 9: The sweep MUST NOT read the upper edge from a record's own retention until.
  ```
  WHY: sequence high water is one scalar per instance. An intent retained late carries a later `retention_until`, and an edge read from it would examine an intent whose closings are purged.
- **service identity**
  Term service identity: a registered actor in the substrate's Actor Identity registry (actor ref and credential) under which the sweep writes, or none.
  ```
  service identity 1: WHEN service identity EQUALS none:
      service identity 1a: The sweep MUST NOT write.
      service identity 1b: The sweep MUST surface EVERY aged open intent on compliance surface.
  service identity 2: PROVISIONAL: Invariant 4's liveness arm DEGRADES TO surfaced under service identity EQUALS none.
  ```
- **outcome envelope**
  Term outcome envelope: the largest outcome payload the kind can write, sized by the adopter from the adopter's own caps, every set-valued field capped and every reference under reference length cap (Invariant 6).
- **retry terminus**
  Term retry terminus: `lease` (default) or the declared deviation `counted(n)`.
  ```
  retry terminus 1: [Close] MUST NOT write BEFORE querying remaining.
  retry terminus 2: IF journal write bound EXCEEDS remaining OR remaining EQUALS none THEN [Close] MUST NOT write.
  retry terminus 3: retry terminus MUST NOT move the terminus.
  ```
  Term terminus: the critical section's lease — an invocation's standing to write ends at the lease's expiry, under every retry terminus value.

### Instance start

```
Instance start 1: This section IS AUTHORITATIVE FOR the conditions of instance start.
NOTE: watch addressable sections (journal fence 2).
Instance start 2: The instance MUST check EVERY condition at start for EVERY bound act kind.
Instance start 3: IF any condition fails for any bound kind THEN the instance MUST NOT start.
```

Term worst closure: `completion_bound + 2 × clock_offset_allowance + 2 × reconciliation_cadence + 3 × run_bound` — completion bound the kind's, the rest the instance's, the allowance counted twice for every kind, fenced or not.

Term window end: `completion_bound + clock_offset_allowance + compensation_window`.

Term lease spend: `2 × read_bound + 2 × journal_write_bound + commit_round_trip`, plus clock offset allowance ONLY IF the act kind declares commit fence OR the substrate declares journal fence (Allowance 11).

Term run floor: `max(completion_bound, closure_latency + journal_write_bound) + closure_latency`.

Term closure spend: `read_bound + 2 × journal_write_bound + probe_round_trip`.

```
Instance start 4: The instance MAY start ONLY IF compensation window EXCEEDS worst closure.
Instance start 5: The instance MAY start ONLY IF retention period EXCEEDS window end.
Instance start 6: The instance MAY start ONLY IF completion bound EXCEEDS lease spend.
Instance start 7: run floor MUST NOT EXCEED run bound.
Instance start 8: The instance MAY start ONLY IF closure latency EXCEEDS closure spend.
```

Term conditions of instance start: condition 1 is Instance start 4; condition 2 is Instance start 5; condition 3 is Instance start 6; condition 4 is Instance start 7; condition 5 is Instance start 8; there is no sixth condition on the sweep's lease.

WHY:
*Condition 1's three run bound terms.* A budgeted death involves three runs: the run in flight when the act crossed the examine edge, which read now once and may lawfully finish its pass without the act; the run that examines the act and dies; the run that closes it. Two cadences, one after each of the first two. Over 432 parameter tuples the one-term form breaches on 420 and a two-term correction on 396; this form holds on every tuple meeting condition 4, with one tick of slack. The model has no backlog, so it could not catch this.

*Condition 2* keeps the sweep's upper edge outside the window; without it an orphan leaves the sweep's range before its promised window has elapsed, is closed by nobody, and check 7 removes it from checks 1–3.

*Condition 3* charges [Open]'s read and write, the commit, and [Close]'s read and write, all inside one lease; charging one write and the commit passes on `5 s > 4 s` and runs out of lease with the outcome unwritten.

*Condition 4's `max`.* The holder a run waits out may be an invocation (completion bound) or a dead run or operator (`closure_latency + journal_write_bound`); the old floor `2 × closure_latency + journal_write_bound` charged the shorter. Over the same 432 tuples the old floor admits 324 and condition 1 breaches on 15; this one admits 288 and breaches on none.

*Condition 5.* A closure holds one read and two writes; below their sum the run passes the gate for the first write, fails it for the second, and repeats every run.

*No sixth condition.* `max(completion_bound, closure_latency) > closure_latency + journal_write_bound` reduces to `0 > journal_write_bound` whenever closure latency reaches completion bound, so a closure slower than the act's bound could not be configured; the lease is stated directly (sweep lease).

### Where the allowance goes

```
Allowance 1: clock offset allowance IS AUTHORITATIVE FOR every comparison in Recoverable Invocation between a reading taken at one seam and a stamp or instant minted at another.
Allowance 2: This section IS AUTHORITATIVE FOR where the allowance is spent.
NOTE: watch addressable sections (journal fence 2).
Allowance 3: A writer MUST classify EVERY cross-seam comparison in Recoverable Invocation as EXACTLY ONE OF applied, minted.
Allowance 4: An applied comparison MUST take the allowance at the reading.
Allowance 5: An applied comparison MUST NOT decide a write.
Allowance 6: An applied comparison MAY exclude a record from a pass.
Allowance 7: A minted instant MUST carry the allowance subtracted at the minting.
Allowance 8: A minted instant MAY decide a write.
Allowance 9: A minter MUST NOT mint a fence's instant bare.
Allowance 10: A minter MUST mint EVERY instant independently.
```

Seven clocks meet on this page: the adopter's seam ([Open] step 3), the sweep's seam ([Reconcile]), the operator's seam ([Resolve]), the reader's seam ([Read Invocation]), the substrate's recorded at, the critical section host's expires at, and — under a declared commit fence — the constituent store's. One allowance covers every pair, set to cover the widest. [Lease](../atoms/lease.md) Invariant 6 owns the minting rule.

**Minted — three instants.**

Term commit fence deadline: minted by the critical section host as the act's expires at, judged by the adopter's constituent store, value `expires_at − clock_offset_allowance`; bound at *Bindings*, the section titled commit.

Term journal fence lease terminus: minted by the critical section host as the writer's expires at, judged by the substrate, value `expires_at − clock_offset_allowance`; bound at *Composes*, the section titled journal fence.

Term journal fence per-write terminus: minted by the writer's own seam at the write's issue, judged by the substrate, value `issue + journal_write_bound − clock_offset_allowance`; bound at *Composes*, the section titled journal fence.

**Applied — every other cross-seam comparison on this page:** [Open] step 3's age of an open intent; the retention drop on every read of open invocations; [Resolve]'s too-young guard; the sequence high water advance; the sweep's edges and window; [Read Invocation]'s rebuild.

**Payments.** A minted instant is paid for, and this page owns the payments because the atom refuses to.

```
Allowance 11: IF commit fence EQUALS declared OR journal fence EQUALS declared THEN condition 3 of instance start MUST charge one clock offset allowance.
Allowance 12: The sweep MUST NOT write abandoned BEFORE abandon edge.
Allowance 13: IF journal fence EQUALS declared THEN the deployment MUST disclose journal write bound with clock offset allowance of headroom over the substrate's own worst case.
```

Term abandon edge: the examine edge plus one further clock offset allowance — `recorded_at + completion_bound + 2 × clock_offset_allowance`.

Term usable term: `completion_bound − clock_offset_allowance` — the term a fenced lease's operations have to finish in.

WHY:
A judge whose clock lags the minter admits, for the lag, a write the minter would call late (`-buggy-skew`, rejected; with clocks in step the bare instant holds, so the skew decides). The margin is required on every instant (`-buggy-perwrite`). One allowance in Allowance 11: both fences pull the same terminus in. Allowance 12 is sweep-to-store, a different pair from the minting's host-to-store. Without Allowance 13 a write taking the full bound is fenced out and retried — safe, an undisclosed liveness cost; the model carries the fence, not the disclosure (Ledger, NOT MODELED).

### Which closing stands

One act may carry more than one closing record; a [Binding Duplicate] is what is left over once supersession is read.

```
Which closing stands 1: This section IS AUTHORITATIVE FOR which of an act's closing records is the act's.
NOTE: watch addressable sections (journal fence 2).
Which closing stands 2: A closing record MAY supersede another closing record ONLY IF the closing record names the other in supersedes.
Which closing stands 3: resolved by MUST NOT trigger supersession.
Which closing stands 4: EVERY surface MUST read supersession transitively.
Which closing stands 5: EVERY surface MUST count the standing closing and every record reachable from the standing closing through supersedes as one closing.
Which closing stands 6: An act MAY carry the closings key ONLY IF two closings each supersede nothing AND are superseded by nothing.
Which closing stands 7: Among unsuperseded closings, the lowest sequence number MUST stand.
Which closing stands 8: Position MUST NOT decide against a name.
Which closing stands 9: [Read Invocation] and [Reconcile] step 5 MUST report two open intents on one (kind, act key) as the intents key on the act.
Which closing stands 10: A surface MAY report the intents key ONLY IF the act kind declares a service identity.
Which closing stands 11: A surface MUST report the closings key under every binding.
```

Term standing closing: the closing no other closing names.

Term closings key: two unsuperseded closings on one invocation id; carried on the entry.

Term intents key: two open intents on one `(kind, act_key)`; carried on the act.

WHY:
Four surfaces need the answer and for two rounds each carried its own; transitive at one, pairwise at three, and a lawful correction read as a duplicate. Chains occur: a sweep escalates, an operator abandons naming it, check 6 shows the abandonment false, a second [Resolve] writes an outcome naming the abandonment — pairwise, the middle record belongs to two pairs. Which closing stands 10: open step 3.8 instructs a report-only deployment to leave an old intent open, so an unbranched second key reports this page's own instruction as a conformance failure. Which closing stands 11: no report-only instruction produces two closings.

**Which state a standing closing projects.**

Term state projection: no standing closing → open; an outcome record `<kind>.<outcome>` → closed; `<kind>.refused` → refused; `<kind>.abandoned` without resolved by → abandoned; `<kind>.abandoned` with resolved by → resolved; `<kind>.escalated` → escalated.

An escalated entry becomes resolved when an operator's abandonment names it, and closed when any outcome names it. resolved is reserved for the case where a human's judgement is the only thing that closed an act and the act did not happen; an operator's outcome is closed. The abandoned split is the one check 6 reads: the sweep's abandonments are tested against probe, the operator's are exempt, and resolved by separates them at both surfaces.

*Cited by:* [Read Invocation]'s state and both binding duplicate fields; [Reconcile] step 5; Generation acceptance check 2; Invariant 2. None restates it.

---

## Composition-level invariants

- **Invariant 1 — Authentication precedes commitment.**
  ```
  Invariant 1.1: An invocation MUST NOT reach the bound commit BEFORE the substrate has validated the caller's credential for actor ref inside [Open]'s intent record.
  Invariant 1.2: invalid-credential MUST land as a pre-state refusal with nothing written.
  ```
  *Rests on:* Audit Trail's record_action and the Actor Identity attestation reached through it (Audit Trail Invariant 1); [Open] step 4 before the adopter's commit. *Defended in-line:* the ordering [Open] → commit → [Close] in every adopter; Generation acceptance check 1 tests it from the records alone.

- **Invariant 2 — One writer per act.**
  ```
  Invariant 2.1: IF journal fence EQUALS declared THEN two closing records MUST NOT name one intent's invocation id.
  Invariant 2.2: EXACTLY ONE writer MUST write the closing record, under the act's critical section.
  Invariant 2.3: Two sweep runs MUST NOT close one act.
  Invariant 2.4: IF journal fence EQUALS none THEN two unsuperseded closing records MUST NOT name one invocation id at quiescence.
  Invariant 2.5: PROVISIONAL: Invariant 2.1 DEGRADES TO Invariant 2.4.
  Invariant 2.6: The section titled Which closing stands IS AUTHORITATIVE FOR which closing is the act's.
  NOTE: watch addressable sections (journal fence 2).
  ```
  *Rests on:* act section (Configuration) with lease-as-terminus semantics; the journal fence (Composes) with its margin and per-write instant; the return-based read-your-writes clause (Capability requirement 7); [Close] step 2's proceed-as-landed; [Reconcile] step 2's re-read under the critical section and sweep closed ids. *Defended in-line:* the load-bearing wiring decision; the model's six rejected twins bearing on this invariant — `-buggy-death`, `-buggy-reread`, `-buggy-journal`, `-buggy-visible`, `-buggy-skew`, `-buggy-perwrite` — each landing two closings for one act; a seventh, `-buggy-supersede`, lands two unsuperseded closings by omitting the name from a resolution over an escalation.

  WHY: the four closing kinds count together because each closes the act; quantified over outcomes alone, an escalation and an outcome coexisted. Under `service_identity = none` the operator and a second live invocation are kept apart by the critical section alone, which is why [Resolve] takes it.

- **Invariant 3 — Pairing is by the seam-injected key in the journal, and by the bound datum in the store.**
  ```
  Invariant 3.1: EVERY record this composition writes for an invocation MUST carry the invocation's invocation id.
  Invariant 3.2: EVERY check and EVERY journal join MUST pair on invocation id and no other field.
  Invariant 3.3: probe MUST make the intent-to-record join on pairing datum by equality.
  Invariant 3.4: probe MUST NOT pair on a stamp within a window.
  Invariant 3.5: WHEN pairing datum EQUALS none OR pairing datum matches more than one record:
      Invariant 3.5a: The sweep MUST name candidates and close nothing.
  ```
  *Rests on:* the seam injection (Primitive policies); Event Log Invariant 2 through Audit Trail Invariant 5 (an appended payload is immutable); the pairing datum binding.

- **Invariant 4 — Bounded closure (safety + liveness).**
  ```
  Invariant 4.1: The records alone MUST reveal EVERY act whose invocation has yielded or died, as an aged intent with no record naming the intent's invocation id.
  Invariant 4.2: IF the journal and the adopter's store are reachable THEN a writer MUST close EVERY aged intent by an outcome, an abandoned record or an escalation WITHIN compensation window of the intent's recorded at.
  Invariant 4.3: WHEN the journal is unreachable:
      Invariant 4.3a: A writer MUST NOT close the intent during the outage.
      Invariant 4.3b: [Open] MUST refuse the key journal-unavailable for the outage's duration.
  Invariant 4.4: [Reconcile] MUST surface a journal outage as the instance finding journal-unavailable, never as the outage's intents.
  Invariant 4.5: The outage finding MUST carry the outage's start and end.
  Invariant 4.6: IF service identity EQUALS none THEN a writer MUST report EVERY aged intent as closure-at-risk WITHIN compensation window, for an operator to close through [Resolve].
  Invariant 4.7: PROVISIONAL: Invariant 4.2 DEGRADES TO Invariant 4.6.
  Invariant 4.8: IF commit fence EQUALS none THEN the sweep MUST escalate an act the store cannot certify as not-committed.
  Invariant 4.9: IF commit fence EQUALS none THEN the sweep MUST NOT abandon the act.
  Invariant 4.10: PROVISIONAL: the abandoned arm DEGRADES TO escalated.
  ```
  *Rests on:* [Reconcile]'s edges and steps 3–5; the kind's completion bound and retention period; the instance's clock offset allowance, reconciliation cadence, run bound, closure latency, read bound, journal write bound and compensation window; the substrate's range read.

  WHY: during a journal outage no intent is enumerable, so per-intent evidence cannot exist; act-in-flight cannot be the outage's code because reading its payload is what failed.

- **Invariant 5 — Recovery is derived, never remembered.**
  ```
  Invariant 5.1: The sweep MUST NOT write an outcome BEFORE writing one or more `<kind>.recovery_intended` records naming the act and the plan.
  Invariant 5.2: EVERY outcome the sweep writes MUST carry the service identity's attestation with the original caller in acting actor ref.
  Invariant 5.3: EVERY outcome the sweep writes MUST carry only what probe re-derived from the store.
  Invariant 5.4: EVERY outcome an operator writes through [Resolve] MUST carry the operator's own attestation, the original caller in acting actor ref, and resolved by.
  Invariant 5.5: An operator's outcome MUST NOT owe a recovery_intended.
  Invariant 5.6: A writer MAY write `<kind>.abandoned` ONLY IF the store can say the act did not happen.
  Invariant 5.7: The sweep MAY write abandoned ONLY IF commit fence EQUALS declared AND the intent is past abandon edge.
  Invariant 5.8: An operator MAY write abandoned ONLY IF the intent is aged, as the operator's own attestation.
  Invariant 5.9: The sweep MUST escalate with candidates what the store cannot re-derive.
  Invariant 5.10: The sweep MUST NOT close an act whose store the sweep cannot read.
  ```
  *Rests on:* service identity (Bindings); Audit Trail Invariant 1 (the attesting actor is verified); [Reconcile] step 3. Generation acceptance check 6 and [Resolve]'s too-young guard rest on Invariant 5.6.

- **Invariant 6 — The outcome is sized before the intent.**
  ```
  Invariant 6.1: IF outcome envelope EQUALS the true maximum THEN an act MUST NOT commit with an outcome record or a compensation record the substrate's payload cap could refuse.
  Invariant 6.2: [Open] MUST NOT write the intent record BEFORE sizing the outcome and the compensation against outcome envelope and intent candidates cap.
  ```
  *Rests on:* [Open] step 1; the adopter's caps under reference length cap. outcome envelope's truth is an externally-clearable check.

- **Invariant 7 — The sweep is bounded at both ends.**
  ```
  Invariant 7.1: [Reconcile] MUST NOT examine an in-flight intent.
  Invariant 7.2: [Reconcile] MAY examine an intent ONLY IF now PRECEDES the intent's horizon edge.
  Invariant 7.3: EVERY check MUST exclude an intent whose payload the substrate has destroyed.
  ```
  *Rests on:* Audit Trail Invariant 2 (retention coverage at quiescence — every `<kind>.*` record is placed under the kind's fixed policy, late at worst), Audit Trail Invariant 4 (the cascade destroys the payload), Audit Trail Invariant 8 and its read_record step 5 (destruction and an unplaced retention are each honestly reported), and the journal binding's fixed-policy obligation. [Reconcile] step 1 owns both edges.

- **Invariant 8 — Positioned codes.**
  ```
  Invariant 8.1: EVERY code an adopter's action exports that could land before the commit and after the commit MUST carry the position — recording-failure(intent) and recording-failure(outcome) at least.
  Invariant 8.2: The adopter's signature MUST declare the payload.
  Invariant 8.3: A caller receiving intent MAY retry the action.
  Invariant 8.4: A caller receiving outcome MUST NOT retry the action.
  ```
  *Rests on:* [Open], [Close] and [Refuse]'s signatures; the position rule (Primitive policies).

- **Invariant 9 — Constituent invariants preserved.**
  ```
  Invariant 9.1: Audit Trail Invariant 1 through 8 MUST hold over the journal instance, and transitively every invariant of Audit Trail's four constituents.
  Invariant 9.2: This composition MUST NOT write to the adopter's constituent store.
  Invariant 9.3: The adopter's commit partition MUST transcribe the constituent's arms as the constituent states the arms.
  ```

---

## Examples

### Walkthrough — a disclosure, three ways

The adopter is Immutable Transaction Ledger's `disclose_subset`, bound as:

- act key = disclosure of `(subject_ref, recipient, scope, authority)` by actor ref.
- commit = `SelectiveDisclosure.record(subject_ref, recipient, scope, authority, disclosed_at = now)`; invalid-request, `unknown-authority-type` and `storage-failure` are pre-commit as the constituent declares them; a lost reply is unknown.
- pairing datum = `disclosed_at`, the seam-injected now, carried in intent data and passed into commit. Selective Disclosure admits no nonce, so the binding declares pairing datum 4's obligation and discharges it by minting `disclosed_at` from a per-node monotonic source whose low bits carry the node, the tag below the resolution at which the constituent's not-in-future guard discriminates, both seams sharing one clock authority (a declared deployment obligation). A deployment whose authority ticks at or below the tag's resolution tags elsewhere.
- probe = read Selective Disclosure's store by `subject_ref` and `recipient` and select, in the adopter's code, the record whose `scope`, authority and `disclosed_at` equal the intent's: `committed(ledger.disclosed, {disclosure_id, disclosed_at})` on exactly one match, not-committed on none, `undecidable(candidates)` on several, unavailable on any read outage — the constituent's `invalid-query` is unavailable to the sweep and surfaced on compliance surface.
- `commit_fence = none`; `repeatable = yes`; `completion_bound = 30 s`; `commit_round_trip = 1 s`; `probe_round_trip = 1 s`; `service_identity = ledger-reconciler`.
- Instance: `reconciliation_cadence = 60 s`; `clock_offset_allowance = 2 s`; `closure_latency = 12 s`; `run_bound = 135 s` (a backlog of three orphans, sequentially, each at worst one holder's remaining lease and one closure: `3 × (30 + 12) = 126 s`, the balance headroom); `journal_write_bound = 3 s`; `read_bound = 2 s`; `compensation_window = 10 min`.

**The five conditions of instance start, against these numbers:**

1. `30 + 2×2 + 2×60 + 3×135 = 559 s < 600 s`.
2. `30 + 2 + 600 = 632 s < retention_period` — `ledger.*` carries a period above 632 s.
3. `30 s > 2×2 + 2×3 + 1 = 11 s`; neither fence is declared, so no allowance is charged.
4. `135 s ≥ max(30, 12 + 3) + 12 = 42 s`.
5. `12 s > 2 + 2×3 + 1 = 9 s`.

The sweep's lease is `12 + 3 = 15 s`; one closure inside it spends `2 + 1 + 3 + 3 = 9 s`, clearing the gate before both writes. (An earlier draft bound `closure_latency = 5 s`, which breaches condition 5: the second gate fails for any probe latency, the sweep re-opens a recovery intent every cadence and never lands a closing.) The instance starts.

**The clean run.** `disclose_subset(...)` validates; [Open] takes the critical section, sizes the outcome (`disclosed_entry_ids` under the ledger's cardinality cap) and the compensation, writes `ledger.disclose_intended` (`inv-7f2`) under the discloser's credential, and returns. `SelectiveDisclosure.record` → `dsc-411`. [Close] finds no outcome for `inv-7f2` under the critical section, writes `ledger.disclosed` with `{invocation_id: inv-7f2, intent_event_id, disclosure_id: dsc-411, ...}`, releases, returns `landed_by = invocation`. One intent, one outcome, one writer.

**The crash.** The run dies between `SelectiveDisclosure.record` returning `dsc-411` and [Close]. The critical section stays held until its lease runs out at `t + 30 s`; the host does not see the death. Thirty-two seconds later a [Reconcile] run keeps `inv-7f2` (older than `30 + 2 s`, inside the horizon), takes the critical section, re-reads — still open — and probes: exactly one record matches → `committed(ledger.disclosed, {disclosure_id: dsc-411, disclosed_at})`. The sweep writes `ledger.recovery_intended` then `ledger.disclosed` with `recovery = true, acting_actor_ref = <the discloser>`, both under `ledger-reconciler`, and releases. Accounted for within about forty-five seconds, inside the ten-minute window, by the one writer left alive.

**The stall.** The run does not die; `SelectiveDisclosure.record` is slow. The store applies the write at eight seconds and the invocation reaches [Close] at forty: remaining answers none (the lease expired at thirty), the invocation writes nothing and returns `recording-failure(outcome)`, and the sweep at thirty-five probed committed and closed it, or will. Or the store never applied the write, [Refuse] failed too, and probe answers not-committed — not final under `commit_fence = none`, since a process paused past the lease could still land the write at forty-five. The sweep writes escalated with `cause = not-observed`; the operator writes the abandonment through [Resolve] once the store has been quiet long enough. A write landing at fifty after a sweep read the store empty at thirty-five is survivable: the escalation stands, the operator's later probe finds the record, and the disposition is outcome. A store-level fence makes that order unreachable and gets abandoned from the sweep.

**The refusal.** A different caller opens a disclosure and `SelectiveDisclosure.record` refuses invalid-request. The adopter partitions the arm pre-commit and calls [Refuse]; `ledger.disclosure_refused` lands with the reason; the intent is closed; the trail keeps the authenticated attempt. Nothing for the sweep.

### Rejection path — a second invocation of the same act

Two operators call `transfer_custody` for one chain within a second of each other, in an adopter whose act key is the chain. The first's [Open] takes the critical section and writes its intent. The second's [Open] waits on the critical section, takes it after the first's [Close] releases, and its step-3 pre-check finds no open intent — the outcome read runs only for a `repeatable = no` kind, and a transfer is repeatable — so it writes its own intent and its own transfer. Had the kind been non-repeatable (a genesis), the second would have landed `act-landed(outcome_event_id)` and the adopter's `already-*` arm would have answered its caller.

### Rejection path — the caller's retry after `outcome`

A caller receives `recording-failure(outcome)`. The position says the act committed. The caller does not re-run; it calls the adopter's read (through [Read Invocation]) and finds the act open — the sweep has not yet run — then, a minute later, closed with `recovery = true`. A caller that re-ran would have found `act-in-flight(invocation_id)` at [Open], the open intent being younger than the bound plus the allowance — and after the sweep, an act-landed refusal where the act is non-repeatable, or a second act where it is: the second act is the caller's decision, made with the position in hand.

### Regulated adversarial scenarios

**Regulator audit — "show me that every consequential act you took is accounted for."** The auditor enumerates the journal's `<kind>.intended` records inside the horizon and older than the bound, and for each finds exactly one closing record naming its invocation id — not since superseded, an abandoned carrying a later outcome with `supersedes` being the corrected-false-abandonment shape check 6 reads; recovery_intended records are not closings and may be several — within compensation window of its recorded at, under the allowance (checks 2 and 3). An intent with no closing record is younger than the bound (in flight) or a conformance failure surfaced on compliance surface, and the auditor can tell which from the stamps alone.

**Disputed act — "I never authorized that disclosure."** The outcome names invocation id; the intent record with that id is attested under the disputant's credential, verified by Actor Identity before the store committed (Invariant 1), and sealed (Audit Trail Invariant 3). If the outcome carries `recovery = true`, the sweep wrote it — under `ledger-reconciler`, behind a recovery_intended record — and acting actor ref still names the disputant. The structural rebuttal is the intent, not the outcome; the sweep changes who attests the outcome, never who attested the intent.

**Breach investigation — "the reconciler's credential was compromised; what could it have written?"** Every record under the service identity is a closing record naming an invocation id whose intent stands under a human's credential; a service-identity record with no such intent is a write outside this composition (check 5), and an outcome the store does not corroborate is one the sweep could not have derived (check 6). The compromised identity could close acts, never open them, and close only acts whose intents exist — the intent record is the control the service identity cannot forge.

---

## Generation acceptance

A derived implementation of Recoverable Invocation is acceptable when an auditor, given the journal and the adopter's constituent store, can clear the following from the records alone.

### Conformance checks

```
Check 1.1: EVERY outcome record whose intent is inside the horizon MUST follow, in the journal's sequence, an intent record with the same invocation id attested under the actor the outcome names — the outcome's own actor ref where recovery is absent, the outcome's acting actor ref where recovery EQUALS true.
Check 1.2: An auditor MUST decide inside the horizon by read_record(intent event id) answering Retained.
Check 1.3: An auditor MUST NOT decide inside the horizon by arithmetic on the outcome's stamp or by the presence of an answer.
Check 1.4: An auditor MUST answer purged, never absent, for an outcome whose intent the substrate reports Purged.
Check 2.1: For EVERY aged intent inside the horizon, two closing records of any of the four kinds MUST NOT name the intent's invocation id.
Check 2.2: For EVERY aged intent inside the horizon, two `<kind>.intended` records MUST NOT carry the intent's invocation id.
Check 2.3: Two intents MUST NOT stand open on one (kind, act key) at any reading inside the horizon, under the intents key of the section titled Which closing stands and that section's service identity EQUALS none branch.
Check 2.4: An auditor MUST read supersession transitively PER the section titled Which closing stands and count the reachable set as one closing.
Check 2.5: An auditor MUST read EVERY outcome as EXACTLY ONE OF the three outcome shapes.
Check 2.6: An auditor MUST report an outcome matching no outcome shape as a conformance failure.
Check 3.1: For EVERY aged intent inside the horizon, a closing record MUST land WITHIN compensation window of the intent's recorded at, the auditor's reading tolerating clock offset allowance across seams.
Check 3.2: An auditor MUST exempt an intent of a kind the bindings table no longer serves.
Check 3.3: An auditor MUST exempt an intent whose window overlaps any span of journal-unavailable, or of store-unavailable for the intent's kind.
Check 3.4: An auditor MUST NOT exempt an intent for the healthy gap between two spans.
Check 3.5: IF service identity EQUALS none THEN the register MUST carry EVERY aged intent as a closure-at-risk act finding WITHIN compensation window.
Check 4.1: An auditor MUST confirm all five conditions of instance start, as the section titled Instance start states the conditions, for EVERY bound act kind from the kind's completion bound, commit round trip, probe round trip, retention period and commit fence declaration, the substrate's journal fence declaration, and the instance's clock offset allowance, reconciliation cadence, run bound, closure latency, read bound, journal write bound and compensation window.
Check 5.1: EVERY record the service identity attests whose named intent is inside the horizon MUST name an invocation id whose intent record exists and is attested by a different actor.
Check 5.2: An auditor MUST report a service-identity record naming no readable intent inside the horizon as a write outside this composition.
Check 5.3: An auditor MUST answer purged for a service-identity record whose intent is Purged.
Check 6.1: For EVERY outcome whose recovery EQUALS true, probe run by the auditor against the constituent store MUST corroborate outcome data or answer unavailable.
Check 6.2: An auditor MUST read unavailable as not applicable, never as failed.
Check 6.3: For EVERY `<kind>.abandoned` not superseded by an outcome carrying supersedes, probe MUST answer not-committed, or undecidable where the kind's pairing datum EQUALS none and a later identical act exists.
Check 6.4: EVERY `<kind>.abandoned` carrying no resolved by MUST belong to a kind whose commit fence EQUALS declared.
Check 6.5: EVERY store candidates entry of an `<kind>.escalated` record MUST match a store record of the intent.
Check 7.1: An auditor MUST exclude an intent the substrate reports Purged from every check.
Check 7.2: An auditor MUST quantify Check 1, Check 2 and Check 3 over intents whose payload is readable.
Check 8.1: An auditor MUST clear Audit Trail's eight traversal checks over the journal instance.
```

Term outcome shape: recovery absent with actor ref set to the intent's actor ref; recovery set to true with resolved by, actor ref set to resolved by, no recovery_intended owed; recovery set to true without resolved by, actor ref set to the service identity, preceded by one or more `<kind>.recovery_intended` naming the same invocation id.

Term invariant map: Invariant 1 → Check 1; Invariants 2 and 5 → Check 2; Invariant 4 → Check 3 and Check 4 (conditions 1, 4, 5; with Invariant 7 for condition 2); Invariant 5 → Check 5 and Check 6; Invariant 7 → Check 7.

### External checks

```
External check 1: An auditor MUST clear from external evidence that a declared outage of the journal or the adopter's store was surfaced on compliance surface with the outage's start and end, and that every intent whose window overlapped the outage was closed once the outage ended.
External check 2: An auditor MUST clear from external evidence that act section is shared across every node of the instance and implemented as a lease of the declared length.
External check 3: An auditor MUST clear from external evidence that closure latency, completion bound, read bound and run bound were set from observed worst cases with headroom, run bound over the largest backlog the deployment sizes for.
External check 4: An auditor MUST clear from external evidence that the adopter's probe reads the store the act was made in.
External check 5: WHEN service identity EQUALS none:
    External check 5a: An auditor MUST clear from external evidence that the surfaced intents were acted on through [Resolve].
External check 6: An auditor MUST clear from external evidence that the store honours commit fence — that a write carrying the minted deadline is never applied after the deadline.
External check 7: An auditor MUST clear from external evidence that each adopter's outcome envelope is the true maximum of the records the kind writes.
External check 8: An auditor MUST clear from external evidence that no writer other than this composition's actions uses an adopter's journal vocabulary.
```

WHY:
External check 1 is keyed on the outage record, not the intents: during a journal outage nothing is enumerable. The records show consequences, not mechanisms — no binding duplicate at quiescence for External check 2, no abandoned record whose act the store later holds for External check 6. A probe that reads a projection can answer not-committed for a committed act, and the abandoned record it causes is false (External check 4). The substrate does not reserve namespaces (External check 8).

---

## Non-goals

```
Non-goal 1: An adopter MUST NOT describe [Open], then the commit, then [Close] as atomic.
Non-goal 2: This composition MUST NOT offer a rollback.
Non-goal 3: This composition MUST NOT add to the substrate's contract.
Non-goal 4: The adopter MUST own the `already-*` re-entry arm, informed by [Read Invocation].
Non-goal 5: A deployment whose regulator requires the account to outlive the act's own retention MUST set the journal's retention policy accordingly.
Non-goal 6: This composition MUST NOT govern the adopter's constituent store's lifecycle.
```

WHY: an adopter needing a withdrawable act composes a Transaction pattern *(forthcoming)* over a store that offers one. Attribution, sealing, retention, purge and the range read are Audit Trail's; this composition adds record kinds and nothing else, and the substrate accepts a `<kind>.*` record from any authenticated caller, so *one outcome per intent* is enforced by this composition's writers and nobody else (External check 8). This composition refuses the second intent for a non-repeatable act and leaves the caller's answer to the adopter. An act whose store record is purged before its journal records is corroborated by nothing (Check 6.2 reads *not applicable*).

### What the sweep never does

```
Sweep never 1: The sweep MUST NOT run adopter code other than probe.
Sweep never 2: The sweep MUST NOT write under a human's credential.
```

## Edge cases

### Clock semantics

```
Clock semantics 3: The composition MUST NOT time the lease.
Deleted: Clock semantics 2. Composes 1 owns it.
Deleted: Clock semantics 1. Execution Contract Logic confinement 3 owns it.
```

WHY: a clock read inside [Resolve] breaks the Contract's logic confinement (the section titled Logic Confinement Principle in `execution-contract.md`); `-buggy-opclock` shows the cost (Invariant 5: an act abandoned whose commit then lands).

### Cross-store consistency under partial failure

The reachable partials and their closers. *Crash after [Open], before the commit:* intent open, store untouched; probe answers not-committed; the sweep writes `<kind>.abandoned` where the kind declares a commit fence and the intent is past the abandon edge, `<kind>.escalated` otherwise. *Crash after the commit, before [Close]:* probe answers committed; the sweep writes the outcome under `recovery = true`. *Crash inside [Close] after the outcome landed and before the map update:* the map is a rebuild trigger, not a partial. *A stalled invocation past its lease:* it yields; the sweep closes; the late [Close] adopts or reports outcome. *A refusal record that failed:* the intent stands, probe answers not-committed, the sweep closes it — abandoned under a fence, escalated without. *An outcome the store cannot corroborate:* undecidable, escalated with candidates, never chosen. There is no sixth partial; a deployment that finds one has a critical section that is not a critical section.

### Declared deviations

```
Deviation 1: An adopter MUST declare a deviation as EXACTLY ONE OF: retry terminus set to counted(n); minted key; journal without attribution.
Deviation 2: An adopter MUST record a need outside Deviation 1 first, as a finding against the adopter or as evidence for the next revision of this page.
Deviation 3: WHEN retry terminus EQUALS counted(n):
    Deviation 3a: The adopter MUST bound the in-invocation retry of the outcome by n attempts.
    Deviation 3b: The adopter MUST carry the seam-injected now [Open] step 3 needs.
    Deviation 3c: [Close]'s remaining query before every write MUST NOT change.
Deviation 4: WHEN the act's key is minted by the commit:
    Deviation 4a: The adopter MUST bind the key the adopter can name before the commit.
    Deviation 4b: The adopter MUST declare the probe that finds the minted record from the bound key.
    Deviation 4c: IF no such read of the constituent EXISTS THEN the adopter MUST declare probe set to undecidable for the kind.
Deviation 5: An adopter journaling to a bare Event Log MUST declare that the adopter is not an adopter of this page.
```

WHY: Chain of Custody bounds its retry without a clock (Deviation 3). Under Deviation 4c the sweep escalates every orphan of the kind, the honest liveness degree. A bare Event Log adopter is the second group the higher-order composition test names, one instance short of its own compound.

### Repeatable and non-repeatable acts

The adopter's declaration; [Open]'s act-landed refusal fires only for `repeatable = no`. The composition does not guess.

---

## Terms

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is* and its **Kind**. The substrate's rejections (invalid-credential, invalid-request, `recording-failure(step)`) are the substrate's cards.

### Vocabulary

Term actors: invocation; sweep run (also: the sweep, the run); operator; adopter's action (also: the adopter, the action); caller; deployment; auditor; substrate; critical section host (also: the host); writer — EXACTLY ONE OF invocation, sweep run, operator; minter — the critical section host or a writer's seam; reader; register (the deployment's findings surface); surface — [Read Invocation], [Reconcile] step 5, or Generation acceptance check 2.

Term records: `<kind>.intended`, `<kind>.<outcome>`, `<kind>.refused`, `<kind>.recovery_intended`, `<kind>.abandoned`, `<kind>.escalated`, [Finding].

Term record verbs: write, read, read back, take, release, hold, yield, adopt, retry, refuse, return, surface, count, probe, close, examine, keep, drop, name, carry, size, validate, land, supersede, rebuild, populate, clear, discard, report, proceed, wait, persist, start, derive, sample, declare, bind, treat, transcribe, issue, mint, reach, reveal, escalate, abandon, open, advance, set, move, admit, absorb, exclude, stand, serialize, time, query, run, pass, decide, pair, share, stay, sum, rely, trigger, exist, answer, call, follow, re-read, leave, supply, perform, exempt, bound, block, use, re-run, match, map, make, export, classify, choose, cap, vary, update, touch, suppress, stamp, retain, resolve, remove, reject, recover, record, re-take, partition, own, owe, omit, offer, know, inspect, govern, free, fire, end, disclose, describe, corroborate, confirm, compare, collapse, check, charge, change, belong, add, commit, append, quantify.

Term cited: take, try_take, remaining, release, expires at: Lease. record_action, read_record, payload cap, reference length cap, attestation id width, retention policy, recorded at, sequence number, next sequence number, record action completion bound, event id, action ref, policy ref, retention until: Audit Trail.

Term value sets: landed by = invocation | sweep | operator. state = open | closed | refused | abandoned | escalated | resolved. disposition = outcome | abandoned | escalated. probe answers committed | not-committed | undecidable | unavailable. commit partition = pre-commit | committed | unknown. repeatable = yes | no. retry terminus = lease | counted(n). commit fence = none | declared. journal fence = none | declared. service identity = an actor | none. findings = journal-unavailable | store-unavailable | closure-at-risk | binding duplicate | unbound-kind. [Resolve]'s invalid-request causes = purged | malformed | too-young | already-abandoned | candidates-over-cap. Cross-seam comparisons = applied | minted.

Term position: intent | outcome | refusal | resolution — the record a write lands: the intent at [Open], the outcome at [Close] or after [Yield], the refusal at [Refuse], the resolution at [Resolve].

Term intent payload: intent data with invocation id, kind and act key added.

Term outcome payload: outcome data with invocation id, intent event id, kind and act key added.

Term recovered outcome payload: the outcome payload with recovery set to true and acting actor ref set to the intent's actor ref added.

Term acting actor ref: the original caller's actor ref, carried by an outcome the sweep or an operator writes (Invariant 5.2, Invariant 5.4).

Term resolved by: the operator's actor ref, carried by a closing record an operator writes through [Resolve] (resolve 21).

Term recovery_intended: a `<kind>.recovery_intended` record — the sweep's statement of an act and its plan, written before the outcome it names (Invariant 5.1).

Term store candidates: the store records an `<kind>.escalated` record names as possibly the intent's, at most intent candidates cap of them (reconcile step 3.8a).

Term run id: a sweep run's own seam-injected id; the critical section holder for the run.

Term true maximum: the largest record a kind writes, as External check 7 clears.

Term cause: not-committed | not-observed | undecidable | outcome-unrecordable — the closing record's escalation or abandonment cause.

Term external evidence: evidence outside the records — documentation, configuration, the deployment's own logs.

Term recording-failure(step-4): the substrate's code for an append that committed and a retention placement that did not; the record is appended.

Term bounds: completion bound, commit round trip, probe round trip, journal write bound, read bound, closure latency, run bound, compensation window, clock offset allowance, retention period, intent candidates cap, read cap.

Term cadences: reconciliation cadence.

Term qualifiers: migrated — rewritten in GRACE lang v0.35 (2026-09-11).

Term terms: (named expressions, each declared where it is used) worst closure, window end, lease spend, run floor, closure spend, examine edge, abandon edge, horizon edge, at risk threshold, intent age, settle bound, retention end, usable term, sweep lease, in-flight, aged, partition, examined, skipped, reported, surfaced, unreached, closed already, standing closing, closings key, intents key, terminus, caller kind, payload match, quiescence, read path, read-your-writes, `position's existing arm`, journal fence instant, commit fence, critical section key, critical section holder, critical section duration, act finding, instance finding, act key, invocation id, now, operator run id, resolve refusal, open result, close result, reconcile tally, invocation report, invocation entry, first seen, last seen, acting actor ref, resolved by, recovery_intended, store candidates.

#### Open

The action an adopter's action calls before the bound commit: takes the act's critical section, sizes the outcome and the compensation against the substrate's cap, refuses an act already in flight or already landed, and writes the intent record under the caller's credential. Returns `{invocation_id, intent_event_id}` with the critical section held.

Kind: Operation

#### Close

The action an adopter's action calls after the bound commit returned: under the critical section, adopts an outcome the sweep already landed for the invocation or writes the outcome record, then releases. Returns landed by; returns `recording-failure(outcome)` where the lease expired or the record could not land.

Kind: Operation

#### Refuse

The action an adopter's action calls when the bound commit refused on a pre-commit arm: writes the refusal record naming the intent, so the authenticated attempt is kept and the intent does not stand open, and releases the critical section.

Kind: Operation

#### Reconcile

The sweep, the composition's second writer: at restart and on cadence, examines open intents between the completion bound and the horizon, takes each act's critical section, probes the store, and closes each act with a re-derived outcome, an abandonment or an escalation — under the service identity behind a recovery-intended record, or as a report only where none is declared.

Kind: Operation

#### Yield

The release an adopter's action calls on a lost commit reply: the critical section is released, nothing is written, the intent stays open for the sweep.

Kind: Operation

#### Resolve

The human-attested close: an operator, present with an own credential, closes an open intent the sweep cannot — under a report-only deployment, or after investigating an escalation — supplying the disposition the operator's own run of probe supports; the record carries `recovery = true` and resolved by.

Kind: Operation

#### Read Invocation

The composition's read: the act's invocations, each with records and state, for an adopter's re-entry arm and for an auditor. Takes no critical section, writes nothing.

Kind: Operation

#### Recording Failure

The positioned failure code `recording-failure(intent | outcome | refusal | resolution)`; refusal carries a second slot for the constituent's pre-commit code. intent: nothing committed, retry the action. outcome: the act exists or may exist, never re-run; the sweep or an operator writes the record. refusal: the intent stays open; the sweep or an operator closes it. resolution: nothing appended — the one retry-safe arm of [Resolve].

Kind:       Type
Role:       the positioned failure code
Projection: recording_failure

#### Act In Flight

[Open]'s refusal where an open intent for the same act exists — younger than the bound (another invocation is between intent and outcome) or older (a dead invocation the sweep will close within the window). Carries the open invocation id.

Kind:       Member
Member of:  the open rejections
Role:       Rejection
Projection: act_in_flight

#### Critical Section Unavailable

[Open]'s and [Resolve]'s refusal where the act's critical section could not be taken within the current holder's remaining lease; nothing is written and the call may be retried.

Kind:       Member
Member of:  the open rejections and the resolve rejections
Role:       Rejection
Projection: section_unavailable

#### Not Open

[Close]'s and [Refuse]'s step 0 refusal, and theirs alone: an invocation id and intent event id pair the adopter's action did not receive from its own [Open]. An adopter's programming error, not a protocol state; nothing is written.

```
Not Open 1: The composition MUST NOT decide not-open.
Not Open 2: The adopter's action MUST hold [Open]'s returned pair on the action's own call stack for the life of the invocation.
Not Open 3: The composition MUST NOT decide not-open from a map or a range read.
Not Open 4: [Close] MUST land recording-failure(outcome) at step 1 for a pair no [Open] returned.
Not Open 5: [Refuse] MUST land recording-failure(refusal, constituent code) at step 1 for a pair no [Open] returned.
```

WHY: on a multi-node instance a local absence is not a miss, and a retained handle is the composition-owned state the section titled Logic Confinement Principle in [`execution-contract.md`](../execution-contract.md) forbids. Not Open 4 and Not Open 5 are a false positive in the safe direction: no intent record exists, so nothing will look at the id. They are two rules rather than one because each action lands the arm its own signature block declares — [Close] carries `recording-failure(outcome)` and [Refuse] carries `recording-failure(refusal, constituent_code)` — and a single rule naming both landed an arm [Refuse] does not have (Closed vocabulary 22, council read 50).

#### Not Known

The read's answer for an act with no readable intent at all, at [Read Invocation] and at [Resolve]. Absence, not destruction: a lawfully purged intent is answered `invalid-request(purged)` at [Resolve], which takes intent event id for exactly that reason. [Read Invocation] is the one surface that cannot make the distinction and says so.

Kind:       Member
Member of:  the read rejections and the resolve rejections
Role:       Rejection
Projection: not_known

#### Finding

A record in the instance's findings register (*Composition state* owns the contract). An act finding names one act the run could not close and carries no span; an instance finding names a condition of the instance, or of one bound kind, and carries one.

Kind:       Type
Role:       the surfaced record
Projection: finding

#### Binding Duplicate

The one token three surfaces agree on — [Read Invocation]'s two fields, [Reconcile] step 5's scan, Generation acceptance check 2 — answering two keys. Closings key: two closing records naming one invocation id that neither supersede one another nor are superseded; holds under every binding. Intents key: two intents open at once on one `(kind, act_key)`; holds only if the kind declares a service identity. The section titled *Which closing stands* owns both keys.

Kind:       Type
Role:       the conformance finding two writers leave
Projection: binding_duplicate

#### Journal Unavailable

The read-path outage code at [Open] step 3, [Reconcile] step 1 and [Read Invocation]: nothing was written, retry. A read's failure, never a write's. [Close], [Refuse] and [Resolve] do not carry it — by the time they read, the act's existence is decided, so their read failures land on their position's recording-failure arm.

Kind:       Member
Member of:  the open rejections and the sweep's
Role:       Rejection
Projection: journal_unavailable

#### Already Accounted

[Refuse]'s and [Resolve]'s refusal where a closing record already names the invocation id; carries that record's event id. Nothing is appended; the caller reports the act as accounted for. Distinct from not-open (a programming-error diagnosis never decided from a journal read) and not named `already-closed`, a constituent's pre-commit code an adopter transcribes verbatim.

Kind:       Member
Member of:  the refuse rejections and the resolve rejections
Role:       Rejection
Projection: already_accounted

#### Act Landed

[Open]'s refusal for a non-repeatable act whose outcome already exists; carries the outcome event id. The adopter's own re-entry arm answers the caller.

Kind:       Member
Member of:  the open rejections
Role:       Rejection
Projection: act_landed

[Open]: #open
[Close]: #close
[Refuse]: #refuse
[Reconcile]: #reconcile
[Resolve]: #resolve
[Yield]: #yield
[Read Invocation]: #read-invocation
[Recording Failure]: #recording-failure
[Act In Flight]: #act-in-flight
[Act Landed]: #act-landed
[Critical Section Unavailable]: #critical-section-unavailable
[Not Open]: #not-open
[Not Known]: #not-known
[Finding]: #finding
[Binding Duplicate]: #binding-duplicate
[Journal Unavailable]: #journal-unavailable
[Already Accounted]: #already-accounted

---

## Standards references

The composition anchors the accountability every regulated adopter's regime requires of a consequential act: an attributable record of intent before the act, a record of outcome after it, and a bounded, attributable account of any act the process failed to record — SOX §404 (Sarbanes-Oxley Act — internal controls over financial reporting), HIPAA §164.312(b) (Health Insurance Portability and Accountability Act — audit controls), PCI DSS Requirement 10 (Payment Card Industry Data Security Standard — logging and monitoring), 21 CFR (Code of Federal Regulations) Part 11 (electronic records and signatures), and GDPR (General Data Protection Regulation) Article 30 and Article 32 (records of processing; integrity of processing). Each adopter's own section names the regime its act falls under; this composition supplies the form the regime's *accountability* clause requires and no substantive judgment about the act.

---

## Status

`draft` — first draft 2026-08-30 (corpus date); twelve fresh-reader gates on the prose draft through 2026-09-10, council read 7 on the GRACE lang rewrite, council read 50 on the current state. The Ledger carries every gate's counts. The word stays `draft` because no adopter has bound to it yet, not because the passes are owed — they ran, and this line said otherwise for a month (council read 50).

## Ledger

```
status: draft
formal: verified — recoverable-invocation.tla (v5) + 9 twins + 8 probes and isolations (21,974 states **at a horizon of five ticks**, which is the whole of the claim: v5's four-phase [Open] costs about a factor of ten in states per tick and does not finish at six or seven, so "all invariants hold" here means *holds within five ticks at these constants* and no monotonicity argument is offered for more. **The twin suite is the evidence that five is enough for what it checks:** all nine twins still fail at this horizon, so each property's violating witness fits inside it; the two whose witnesses demonstrably do not — the window, and the intent landing past its section — have their own configurations; Invariants 1, 2, 4, 5 as safety over discrete time; six components over one act — the invocation, a section host with lease-as-terminus, a fenced-or-fenceless store, a journal whose writes return and become visible at separate instants, two sweep runs on two nodes with a blocking take, **an operator through [Resolve] as the third writer, taking the same section on its own seam reading and re-arming for a second call**, **[Open] split into take → read → gate → issue → return with the intent write carrying its own return and visibility instants**, a death budget and a pause budget; `service_identity` is a modelled dimension, so the sweep's writes and the operator's open-intent arm are gated by it; every journal write split into its gate and its issue, and carrying separate return, visibility and fence instants across two clocks; twins rejected — `-buggy-death`, host releases on death → Invariant 2; `-buggy-reread`, sweep skips the re-read under the section → Invariant 2; `-buggy-fence`, sweep abandons a fenceless act → Invariant 5; `-buggy-journal`, no `journal_fence` → Invariant 2; `-buggy-visible`, visibility only time-bounded → Invariant 2; `-buggy-skew`, fence instant minted bare → Invariant 2; `-buggy-perwrite`, no per-write fence instant → Invariant 2; `-buggy-supersede`, a resolution over an escalation carrying `resolved_by` and no `supersedes` → Invariants 2 and 6 (gate 9, F6); `-buggy-opclock`, the operator's reading one tick ahead in a report-only deployment → Invariant 5 (gate 9, F7), against `probe-reportonly-clean` which differs by that one constant and HOLDS; **Invariant 8 — an intent is never in flight while its own invocation no longer holds the section — is earned by the FENCE and not by the lease gate, which the model settles against the gate's own prescription: `probe-fenceless-intent` (no fence, gate on) VIOLATES it, `probe-fenced-ungated-intent` (fence on, gate off) HOLDS, and the fenced-and-gated case holds by monotonicity (gate 10, F6)**; established — the dead-run term inside the model's own frame is the sweep's own lease and not a second `completion_bound` (true of a world with one act in it; the page's inequality carries `run_bound` terms instead, which the model has no backlog to express — Configuration §`compensation_window`), the `remaining` gate is not what carries Invariant 2 (the fence is, in all four cells of gate × fence), the fence margin is required on every instant and not only the lease's, the lower edge not safety-bearing at zero skew; Invariant 4 is vacuous at the main constants and is checked in the window configurations instead; **reachability probes — `Probe_OperatorNeverHoldsSection`, `Probe_OperatorNeverWrites`, `Probe_OperatorNeverSupersedes` and `Probe_NeverASupersessionChain`, each a deliberate falsehood the checker rejects**, the last of them only after it had held twice and named two things that were off which the configuration did not say were off, so the operator's invariants are not vacuous the way Invariant 4 once was; not modeled — pairing, purge, the refusal path, `recovery_intended`, the bindings table's lifecycle and with it the `kind` half of the key, the rejection-code taxonomy, the derived indexes, the compliance surface, the sweep's own lost-reply retry, and **which record a supersession names**: the model counts supersessions and does not identify them, so a chain (an escalation superseded by an abandonment superseded by an outcome) and a double-naming of one record are the same state to it — the transitivity rule below is therefore a prose repair and is **not** model-confirmed), 2026-09-09
last gate: 2026-09-10 — twelfth gate, fresh reader, on the draft — 6 foundational, 15 refining and 6 rhetorical, corrected in this round together with the four of gate 11's nine that gate 12 did not re-find. **The round's measurement:** the Lease extraction's own claim held per class — lease-owned findings went 3 → 1 → **0** — while every surviving foundational was a consolidation that had not carried every obligation into its new owner. **Two consolidations this round**, both written in controlled normative form: the allowance's disposition (three passages, one of which asserted of another the opposite of what it said) and the instance-start condition set (four sites, one of which — the walkthrough — breached a condition the page declared eight lines above its own numbers, while the acceptance check that clears instance start named a subset); 2026-09-10 — eleventh gate — 9 foundational, 17 refining and 5 rhetorical; the round that measured defect density flat at 18-20 KB per foundational across four gates and diagnosed propagation failure as 16 of 19 caused findings, which is what put the diff-derived obligation sweep into standing round discipline; 2026-09-10 — tenth gate — 8 foundational; 2026-09-09 — ninth gate — 8 foundational, and the round that brought [Resolve] into the model as its third writer; 2026-09-09 — eighth gate, fresh reader, on the draft — 8 foundational, 15 refining and 7 rhetorical, all corrected in-round. Two of the eight were defects in start checks the previous round had copied out of Configuration into an acceptance check so an auditor would run them, and one of those two — the sweep's lease — was **unsatisfiable** wherever `closure_latency` reached `completion_bound`; 2026-09-08 — seventh gate, fresh reader, on the draft — 7 foundational, 12 refining and 8 rhetorical, all corrected in-round; conceptual independence returned CLEAN for the first time, and foundational timing findings reached zero. Five of the seven landed on [Resolve] or the purge, both on the model's own NOT MODELED list, and two of those five were then reproduced by bringing [Resolve] into the model; 2026-08-30 — sixth gate, fresh reader, on the draft — 6 foundational, 12 refining and 6 rhetorical, all corrected in-round, and the first round to run with the linter's mechanical checks active against the draft (they caught one defect the round itself introduced); fifth gate — 5 foundational, 11 refining and 5 rhetorical corrected in-round; fourth gate — 8 foundational, 19 refining and 5 rhetorical corrected in-round; third gate — 4 foundational, 15 refining and 6 rhetorical corrected in-round; second gate the same day — 6 foundational, 17 refining and 7 rhetorical corrected in-round; first gate — 8 foundational and 16 refining corrected in-round, 1 refining routed, 5 rhetorical corrected

open:
- 2026-09-10-a · refining · Composition state, `findings` · the register carries truth no constituent store replays, and it is classified extraction-pending with no atom yet owning it, so this page owns a durability contract that belongs to one → land the **Condition Register** atom, a durable register of named conditions each opening at a first sighting, advancing at every later one and ceasing when a pass no longer sees it; until it lands the contract in Composition state is the declaration and the debt is flagged rather than normalized
- 2026-09-10-b · refining · the section titled Where the allowance goes · a deployment declaring `journal_fence` whose `journal_write_bound` carries no headroom fences out writes that take the full disclosed bound, and the model does not distinguish that state because it carries the fence and not the disclosure → disclose `journal_write_bound` with `clock_offset_allowance` of headroom over the substrate's own worst case, and carry the liveness cost as NOT MODELED until a model of the disclosures exists
```

## Decisions

Directional changes only. Everything smaller lives in the commit that made it: `git log -- compositions/recoverable-invocation.md`.

- **2026-09-10 — Rewritten in GRACE lang v0.28; nothing but language changed.** *Chose:* labelled rules, rationale under `WHY:`, the Ledger and invariant numbers unchanged. *Over:* the prose draft. *Because:* the migration plan.
- **2026-09-10 — Instance start in controlled form.** *Chose:* five terms, five one-line conditions, the round-trips as bindings. *Over:* inline inequalities marked `STRICTLY`. *Because:* arithmetic lives in term declarations, and a named term gives each expression one owner for the prose-versus-model diff.
- **2026-09-10 — Lease is the atom; what a fence costs stays here.** *Chose:* [`atoms/lease.md`](../atoms/lease.md) owning the critical section's lease and both fences as one concept; the binding and the three payments here. *Over:* an atom covering the critical section alone. *Because:* the atom declines what carrying an instant costs; lease-owned findings went 3 → 1 → 0 across the extraction.
- **2026-09-10 — One owner for the conditions of instance start, and there are five.** *Chose:* the section titled *Instance start*, cited by number. *Over:* four sites. *Because:* they drifted three ways at once, and the `max` floor matters: over 432 tuples the old floor admits 324 and breaches on 15, the new admits 288 and breaches on none.
- **2026-09-10 — One owner for where the allowance is spent.** *Chose:* the section titled *Where the allowance goes* — applied or minted, three instants, three payments. *Over:* three sites, one asserting the opposite of another. *Because:* the bare instant is the construction the Lease atom declares non-conforming; mint, then size for the minting.
- **2026-09-10 — The findings register is extraction-pending.** *Chose:* classify against a forthcoming Condition Register, the two obligations and five conditions named. *Over:* declaring the totality claim false. *Because:* an unclassified register ends up in process memory and loses the outage span a check reads.
- **2026-09-10 — The intents key branches on service identity; the first does not.** *Chose:* the branch once, at the section titled *Which closing stands*. *Over:* an unbranched key. *Because:* unbranched, [Open] step 3's own report-only instruction was a conformance failure for a whole retention period.
- **2026-09-10 — not-open is a precondition on the caller.** *Chose:* the pair [Open] returned, on the action's call stack. *Over:* a retained handle, or deleting the code. *Because:* the handle is the state the execution contract forbids, and the code is the one name an adopter has for the condition.
- **2026-09-10 — The fence earns Invariant 8; the lease gate does not.** *Chose:* the duplicate surfaces count open intents per `(kind, act_key)`; the read gains read bound. *Over:* gating the intent write as the remedy. *Because:* the gated fenceless configuration admits a second live intent and the ungated fenced one does not.
- **2026-09-10 — The sweep's lease is stated, not maximised.** *Chose:* `closure_latency + journal_write_bound`. *Over:* a `max` with a start check. *Because:* the check reduced to `0 > journal_write_bound` whenever closure latency reached completion bound.
- **2026-09-10 — Supersession is transitive; the model does not confirm it.** *Chose:* the standing closing is the one no other closing names; the reachable set counts as one. *Over:* pairwise. *Because:* pairwise collapse reports binding duplicate on the check-6 chain; the model counts supersessions without identifying them.
- **2026-09-08 — [Resolve] is modelled as the third writer.** *Chose:* model v4, the operator taking the same critical section on its own seam reading, `SupersedesNamed`, `OperatorSkew` and service identity as modelled dimensions. *Over:* repairing from the gate's prescription. *Because:* the NOT MODELED list had named [Resolve] for three gates and the ninth returned five of seven foundational findings on it.
- **2026-09-08 — Supersession is by name; the operator's seam is the sixth clock.** *Chose:* every closing over an existing record carries `supersedes`; now injected at the operator's seam. *Over:* the name for the abandoned case only, and an unbounded reading. *Because:* resolved by names the operator, not a record; a destructive write cannot be decided by a reading nothing bounds. Both are rejected twins.
- **2026-09-08 — kind is an argument; the act's closings are a declared index.** *Chose:* kind first in every action but [Reconcile], `(kind, act_key)` keys, act closings. *Over:* the kind implicit in the caller. *Because:* a signature that omits the kind names the wrong critical section, and `act-landed(outcome_event_id)` had nothing to supply its payload.
- **2026-08-30 — The closure window is bounded by three sweep runs.** *Chose:* `completion_bound + 2 × clock_offset_allowance + 2 × reconciliation_cadence + 3 × run_bound < compensation_window`. *Over:* one run bound, and the two-term correction the gate prescribed. *Because:* a budgeted death involves three runs; the enumeration breaches the old form on 420 of 432 tuples and the correction on 396.
- **2026-08-30 — A duplicate is decided by supersession first and position second.** *Chose:* a declared field on [Read Invocation], a scan over the delta, a check over all four closing kinds. *Over:* three detectors that did not exist. *Because:* a degraded guarantee whose detection is asserted is worth less than an honest statement that there is none.
- **2026-08-30 — Fenceless is a declared degraded mode.** *Chose:* journal fence optional, the weaker guarantee stated over records. *Over:* requiring a fence no substrate here can supply. *Because:* the guarantee changes and stays checkable.
- **2026-08-30 — The composition's own writes are fenced, not merely gated.** *Chose:* journal fence as an instance capability requirement. *Over:* the gate alone. *Because:* the gate is check-then-act; the fence carries Invariant 2 with or without it.
- **2026-08-30 — The model's two corrections.** *Chose:* a host that releases only on return or expiry, and one budgeted dead run. *Over:* release on death, and one bound. *Because:* the death twin lands two closings for one act.
- **2026-08-30 — The protocol is a compound, adopted by binding.** *Chose:* one composition owning the pair, the critical section, the sweep, the derived-not-remembered rule, positioned codes and the closure inequality; adopters bind and declare deviations from a closed list. *Over:* six methodology rules applied twenty times, or a Transaction pattern the constituents cannot support. *Because:* fourteen exact instances and ~920 KB of protocol prose clear the higher-order composition test, and the invariants are provable only over the pair of processes and the one critical section.

NOTE: End of Recoverable Invocation.
