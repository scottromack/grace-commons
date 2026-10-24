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

Recoverable Invocation is the protocol every regulated action in this library follows when it changes something it cannot take back and must leave a trustworthy account of having done so: write down what you are about to do, do it, write down what you did — and if the process dies in between, let a separate sweep finish the writing, so that the sweep and the original never both write, the sweep never writes about work still in progress, and the sweep never invents an outcome it cannot read back from the database the act was made in.

Twenty compositions had each written this protocol in their own words. This composition specifies it once. An adopter names it and supplies **bindings** — what the act is, which database commits it, how long it may take, under what identity a sweep may finish the accounting. The intent record, the outcome record, the critical section, the sweep with its two edges, the position on every rejection code, a closure table naming the rule that owns each input and each answer a constituent can give, and the arithmetic that makes the closure promise meetable all live here.

The protocol is proved in `recoverable-invocation.tla` (TLA+, a formal specification language whose models a checker explores state by state): six components over one act — the invocation, the critical section host, the database, the journal, the sweep as two runs on two nodes, and an operator through [Resolve] as the third writer — with time explicit, the crash anywhere, and every write split into the instant its gate is passed and the instant it is issued. The composition wires the **Audit Trail** substrate and a **critical section** the deployment supplies, keyed by the act, and composes no database of its own. The emergent guarantee: every act committed through it is accounted for exactly once inside the journal's retention, by exactly one writer, within a declared window or with a declared record of why not.

---

## Intent

WHY:
An irreversible act and its account are two writes no transaction spans (the library's rule since 2026-08-27: an atomic set may not contain a write the host cannot take back). The order — intent, act, outcome — leaves exactly one reachable partial: the act committed, its record owed. Something must close it after the process that opened it is dead.

By 2026-08-30 twenty compositions had each solved this in their own words, and two days of fresh-reader gates found the same defects in every one: two writers landing an outcome for one act; a sweep reading in-flight work as a crash; a sweep re-emitting an outcome it could not have known; a rejection code saying nothing had committed when something had; a closure window that could not be met. One protocol, carried once. The rule: **one act, one intent, one outcome, one writer** — the invocation while it holds the critical section, the sweep after the invocation has yielded, never both.

Not a transaction, not the adopter's database, not an audit journal, not a class. An adopter names it in *Composes*, binds its parameters, declares any deviation, and deletes the paragraphs this page replaces.

---

## Composes

- **[Lease](../atoms/lease.md)** — the per-key grant of exclusive standing whose terminus is an instant. The act's critical section is a lease. This page binds the atom's parameters — which key, which holder, how long, which arm maps to which code — and restates none of its semantics but the sizing the atom obliges a composer to state as its own (act section 16 through 18). What the atom refuses to own and this page adds: which key protects which work, and how long a grant must last.
- **[Audit Trail](./audit-trail.md)** — the regulated-audit substrate and this composition's journal, its four constituents (Event Log, Actor Identity, Tamper Evidence, Retention Window) reached transitively per *Compositions of compositions* ([`spec-format.md`](../spec-format.md)). Consumed at the declared contract `record_action(action_ref, actor_ref, credential, data)`, which answers event id and refuses `invalid-credential | invalid-request(step) | recording-failure(step)`, for every record this page writes; `read_record(event_id)`, which answers `audit_record | not-known`, or no answer where a constituent read gives none (Audit Trail read record 5), where an event id is in hand; and the open-upper-bound sequence-range read, for every other read of the journal (Capability requirement 1). Attribution, retention and sealing of every record here are Audit Trail Invariants 1, 2 and 3; destruction of a payload at the horizon is Audit Trail Invariants 4 and 8.
- **The bound act** — not a constituent. The adopter's constituent commit call, supplied as a binding together with the read that tells whether it committed. The constituent's own contract governs the commit.
- **The act's critical section** — keyed by the act, supplied by the deployment (*Capability requirement*, act section). No constituent's records provide it: Lease states what it is, and the deployment supplies the host.

```
Composes 1: A record MUST carry only stamps of the substrate (recording instant) or of the constituent (through probe).
```

A pairing datum that is a seam-injected now is no stamp of this composition's: it is the adopter's parameter, carried in intent data and into the commit, and matched by equality.

### Journal fence (optional)

```
Deleted: journal fence 1. Execution Contract Database 2 owns it: a writer's re-read, lease check and append are one transaction, and no deployment declares a fence on the journal.
Deleted: journal fence 2. Execution Contract Database 2 owns it: a writer's re-read, lease check and append are one transaction, and the page mints no instant for a fence on the journal.
Deleted: journal fence 3. Execution Contract Database 2 owns it.
Deleted: journal fence 4. Execution Contract Database 2 owns it.
```

Term position's existing arm: `recording-failure(intent)` at [Open]; `recording-failure(outcome)` at [Close]; `recording-failure(refusal, constituent_code)` at [Refuse]; `recording-failure(resolution)` at [Resolve]; at the sweep's writes, which follow the outcome position, the act left for the next run (reconcile step 3.17).

Term constituent code: constituent_code — the refusal code a constituent returned, carried beside the composition's own.

Term closing event id: closing_event_id — the event id of a closing record: the closing another writer already wrote for the invocation, which already-accounted carries, or the closing [Resolve] writes, which [Resolve] answers (resolve 35).

### Under journal fence set to none — the case in this library today

```
Deleted: journal fence none 1. Execution Contract Database 2 owns it: a writer's re-read, lease check and append are one transaction, so no append lands beside another writer's closing.
Deleted: journal fence none 1a. Execution Contract Database 2 owns it: a writer's re-read, lease check and append are one transaction, so no append lands beside another writer's closing.
Deleted: journal fence none 1b. Execution Contract Database 2 owns it: a writer's re-read, lease check and append are one transaction, so no act carries a binding duplicate.
Deleted: journal fence none 2. Execution Contract Database 2 owns it: a writer's re-read, lease check and append are one transaction, so no act carries a binding duplicate.
Deleted: journal fence none 3. Execution Contract Database 2 owns it: a writer's re-read, lease check and append are one transaction, so no act carries a binding duplicate.
Deleted: journal fence none 4. Execution Contract Database 2 owns it: a writer's re-read, lease check and append are one transaction, so no act carries a binding duplicate.
Deleted: journal fence none 5. Execution Contract Database 2 owns it: a writer's re-read, lease check and append are one transaction, so no act carries a binding duplicate.
Deleted: journal fence none 6. Execution Contract Database 2 owns it: a writer's re-read, lease check and append are one transaction, so no act carries a binding duplicate.
```

Term quiescence: no invocation in flight and no sweep run mid-pass.

---

## Composition logic

### Composition state

Five elements, each carrying the Contract classification of the section titled Composition state in [`execution-contract.md`](../execution-contract.md). Four are derived indexes rebuilt from one sequence-range read filtered to the bound kinds' records, whose kind and act key the composition writes itself. One is extraction-pending. act section is not composition state.

- **open invocations**
  Term open invocations: map from `(kind, act_key)` to the set of intent records (intent event id, invocation id, the payload) of every invocation of the act that has opened and not yet closed, refused, been abandoned or been escalated. Derived index.
  ```
  open invocations 1: IF service identity DOES NOT EQUAL none THEN two open intents MUST NOT share one (kind, act key).
  open invocations 2: IF service identity EQUALS none THEN several open intents MAY share one (kind, act key).
  open invocations 3: The composition MUST rebuild open invocations from the range read filtered to `<kind>.intended` records, less those a later closing record names through invocation id.
  open invocations 4: [Open] MUST populate open invocations.
  open invocations 5: [Close], [Refuse] and the sweep MUST clear open invocations.
  open invocations 6: [Open]'s pre-check, [Close]'s pre-check and the sweep MUST read open invocations.
  open invocations 7: open invocations MUST NOT hold an intent past the retention horizon.
  ```
- **act closings**
  Term act closings: map from `(kind, act_key)` to the act's closing records, whoever wrote them. *Derived index*, same rebuild. Past the horizon it holds no closing whose payload the substrate destroyed, the rebuild keying each closing on the act key its payload carries (Primitive policy 2), and no reader needs one there: [Resolve] answers a purged intent invalid-request(purged) (resolve 12), [Read Invocation] answers an act key with no readable intent not-known (read invocation 12), and the commit refuses a non-repeatable act's second attempt (repeatable 2).
  ```
  act closings 1: [Close], [Refuse], [Resolve] and the sweep MUST populate act closings.
  act closings 2: [Open] step 3, [Resolve]'s supersession check and [Read Invocation] MUST read act closings.
  ```
- **sweep closed ids**
  Term sweep closed ids: the set of invocation id values the sweep has closed: an outcome under `recovery = true` or an `<kind>.escalated` naming the id. *Derived index*, same rebuild.
  ```
  sweep closed ids 1: The sweep MUST NOT write a closing BEFORE consulting sweep closed ids under the critical section.
  ```
- **sequence high water**
  Term sequence high water: the highest sequence number the composition has read. Derived index.
  ```
  sequence high water 1: EVERY re-read of Recoverable Invocation MUST read the delta above sequence high water and advance the local maps by the delta.
  sequence high water 2: The mark MAY advance past a sequence number ONLY AFTER settle bound has elapsed since the sequence number's recording instant.
  sequence high water 3: EVERY instance MUST perform a full rebuild at process restart.
  sequence high water 4: EVERY instance MUST perform a full rebuild PER reconciliation cadence.
  sequence high water 5: IF an intent's retention end PRECEDES now THEN EVERY read of open invocations MUST drop the intent.
  sequence high water 6: A lost mark MUST rebuild both maps from the log's beginning.
  ```
  Term settle bound: `journal_write_bound + clock_offset_allowance`.

  Term retention end: `recorded_at + retention_period`.
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
  findings 9: The register MUST advance last seen on every run that still sees an instance finding's condition.
  findings 10: WHEN a run does not see a standing instance finding's condition:
      findings 10a: The register MUST close the record with last seen at the previous run.
  findings 11: The register MUST open a new record for a recurrence.
  findings 12: The register MUST hold one record per standing condition.
  findings 13: A reader MUST NOT rely on an order across act keys.
  NOTE: open line 2026-09-10-a — the register's durability contract waits on the forthcoming Condition Register, against which Audit Trail classifies its write-once outage record too.
  ```
  Term act finding: {finding, kind, act_key, invocation_id, first_seen, run_id}; deduplicates on (invocation id, finding); carries no last seen and no span. An act finding records a sighting; whether the act still stands escalated is [Read Invocation]'s answer, not the register's.

  Term instance finding: {finding, kind, first_seen, last_seen, run_id}; deduplicates on (finding, kind).

  Term first seen: the run that first surfaced a finding, with the run's reading of now; set once (findings 7, findings 8).

  Term last seen: the last run that still saw an instance finding's condition, with the run's reading of now (findings 9, findings 10).
  The five conditions:
  - journal-unavailable — instance finding, no kind: the journal could not be read or written this run ([Reconcile] step 1, reconcile step 2.10, reconcile step 3.22).
  - store-unavailable — instance finding, kind present: the kind's adopter's database answered unavailable to probe ([Reconcile] step 3).
  - closure-at-risk — act finding: the act's remaining window is below what one more cadence and one more run need ([Reconcile] step 5). Generation acceptance check 3's `service_identity = none` branch reads it.
  - unbound-kind — act finding: an open intent of a kind the instance no longer binds.
  - escalated — act finding: the sweep closed the act as `<kind>.escalated` and an operator's [Resolve] is what ends it ([Reconcile] step 3).

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
Deleted: Capability requirement 7. Execution Contract Database 2 and Execution Contract Database 3 own it.
Capability requirement 8: EVERY range read issued after journal write bound has elapsed since a lost-reply append's issue MUST return the record.
Capability requirement 9: A read_record that cannot reach the journal MUST land recording-failure(resolution) at [Resolve].
Capability requirement 10: A read_record that cannot reach the journal MUST NOT answer not-known.
Capability requirement 11: IF the range read, read-your-writes or act section is absent THEN the composition MUST NOT start.
Capability requirement 12: The deployment MUST supply the journal's database PER Execution Contract Database 1 through 4.
Capability requirement 13: EVERY read path of Recoverable Invocation MUST land an invalid-query where the read path lands unavailable, the instance finding journal-unavailable excepted.
Capability requirement 14: The composition MUST NOT surface an invalid-query as the instance finding journal-unavailable.
```

Term delta range: the sequence-number range from `sequence_high_water + 1` with no upper bound.

Term open-upper-bound sequence-range read: `EventLog.read` over the delta range, reached through Audit Trail's list-shaped pass-through.

Term read path: [Open] step 1 and step 3, [Reconcile] step 1, [Read Invocation], and the re-reads at [Close], [Refuse], [Resolve] and [Reconcile] step 2. The reads at [Open], [Reconcile] step 1 and [Read Invocation] transcribe unavailable as journal-unavailable; the re-reads at [Close], [Refuse] and [Resolve] land it on the position's recording-failure arm, and so do the read-backs of Primitive policy 20, 27 and 35; the re-read at [Reconcile] step 2 leaves the act for the next run under the instance finding journal-unavailable (reconcile step 2.10). A read-back that gives no answer lands the intent position although the intent may stand: nothing is committed, a retry is safe, and the stray intent is the sweep's to close. A read fails where it answers unavailable. An invalid-query is no outage of the journal but a fault of the build: it lands where unavailable lands, is surfaced, and opens no outage finding (Capability requirement 4, 13 and 14).

Term read-your-writes: Capability requirement 8 and Capability requirement 12 together. The filtering of every range read on action reference, invocation id or a payload field is this composition's code; the substrate offers no such selector.

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
      Deleted: act section 10c. act section 10a owns it: nothing is written on a reply that arrives after the expiry.
      Deleted: act section 10d. open step 4.2b, open step 5.6, close step 1.2c and refuse step 1.2b own it: each action returns its own arm where the lease no longer covers the write.
  act section 11: The sweep MUST take the critical section on every act key the sweep examines.
  act section 12: The sweep MUST hold the critical section across the pre-check and the closing write.
  act section 13: A sweep run MUST leave a closing write in flight at expiry for the next run.
  Deleted: act section 14. Lease Non-goal 1 owns it: a party takes no key the party holds, the holder included.
  act section 15: IF a call in flight EXISTS under the grant THEN the holder MUST NOT issue Lease's release for the grant (Lease Composition note 5c).
  act section 16: The composition MUST bind Lease Sizing 1 through 9 for EVERY unfenced write under the critical section, with call pause bound as the atom's call pause bound, lease spend and closure spend as the atom's work bounds, and write floor and commit floor as the atom's start floors.
  act section 17: IF a take, a remaining or a release on act section answers no answer THEN the holder MUST read remaining as none for the rest of the grant (Lease Sizing 7).
  act section 18: A holder MUST NOT issue a second time, under one lease, a lease call that answered no answer (Lease Sizing 8).
  Deleted: act section 18a. act section 16 owns it: Lease Sizing 8, bound for every unfenced write.
  act section 19: The deployment MUST supply Lease Capability requirement 8 through 10 at the journal and at the adopter's database.
  ```
  Term critical section key: `(kind, act_key)`.

  Term critical section holder: the invocation id for an invocation; the run id together with the examined intent's invocation id for a sweep run's take, so that no two takes carry one value (Lease Identity 6); operator run id for [Resolve].

  Term critical section duration: completion bound for an invocation; sweep lease for a sweep run or an operator; the longest a take on a key asks for is the larger of the two (Lease Composition note 5d).

  Term release: to issue Lease's release for the grant where no call in flight exists under the grant, and to issue nothing where one does — the grant then ends at its instant (act section 15). EVERY release on this page reads so.

  Term unfenced write: as Lease declares it; on this page the bound commit.

  Term terminus: the critical section's lease — an invocation's standing to write ends at the lease's expiry.
- **journal write bound**
  Term journal write bound: the disclosed bound on a record_action from issue to landing: issue-to-first-commit latency, with headroom. *Default:* none.
  ```
  journal write bound 1: A writer MUST issue a journal write under the critical section ONLY IF a remaining the writer queried for that write EXCEEDS write floor.
  ```
  Term sweep lease: `closure_latency + journal_write_bound`.
- **call pause bound**
  Term call pause bound: this composition's value of [Lease](../atoms/lease.md)'s call pause bound: the longest time from a holder's decision to issue one call — a lease call, the issue of a journal write, the issue of the bound commit — to the moment the call has taken effect or failed. *Default:* none.
  ```
  call pause bound 1: The deployment MUST hold EVERY lease call inside call pause bound, a pause of the holder's own process included.
  call pause bound 2: A writer MUST issue a journal write WITHIN call pause bound of asking for the write's remaining.
  ```
  A journal write is a unit of work in Lease's sense, its bound journal write bound; the call pause bound bounds the write's issue, as the atom's Term unit of work allows, and not the whole record action.
  Term write floor: `journal_write_bound + 3 × call_pause_bound` — Lease's start floor for one journal write: the reading and the issue behind it inside one pause, the write, and the atom's two-call margin. A remaining that answers none does not exceed it.

  Term commit floor: `commit_round_trip + 4 × call_pause_bound` — the same for the bound commit, with one pause more for the hand from [Open]'s return to the adopter's call.
- **reconciliation cadence**
  Term reconciliation cadence: the interval at which the sweep runs after the mandatory run at process restart. *Default:* none.
- **read bound**
  Term read bound: the disclosed bound on one journal read under the critical section ([Open] step 3, [Close] step 2, [Refuse], [Resolve], [Reconcile] step 2). Conditions 3 and 5. *Default:* none.
- **closure latency**
  Term closure latency: the disclosed bound on one whole closure: re-read, probe, `<kind>.recovery_intended`, the closing record, the index update. Condition 5. *Default:* none.
- **run bound**
  Term run bound: the disclosed bound from a [Reconcile] run's start to the last closing it lands, over the largest backlog the deployment sizes for. *Default:* none.
  ```
  run bound 1: A node MUST NOT start a run beside the node's own run in flight.
  ```
- **compensation window**
  Term compensation window: the duration within which the sweep closes an act whose invocation died, from the intent's recording instant. Conditions 1 and 2; rearranged, the at-risk threshold of [Reconcile] step 5. *Default:* none.
- **clock offset allowance**
  Term clock offset allowance: the allowance for comparing a reading from one clock with a stamp or instant from another; the section titled *Where the allowance goes* owns where it is spent. *Default:* none.
- **intent candidates cap**
  Term intent candidates cap: the most database candidates an `<kind>.escalated` record names, each under reference length cap; past it, the count and the range. Sizes the escalation (Invariant 6). *Default:* none.
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
Primitive policy 6: The adopter MUST pass actor reference and credential through to record_action at the intent record.
Primitive policy 7: The composition MUST validate actor reference and credential as non-empty and MUST NOT inspect either.
Primitive policy 8: The adopter MUST NOT call [Open] BEFORE capping actor reference under reference length cap.
Primitive policy 9: intent data MUST carry the invocation's parameters and pairing datum.
Primitive policy 10: intent data MUST NOT carry a field the substrate or the constituent stamps or mints.
Primitive policy 11: The composition MUST write invocation id, kind and act key into EVERY record the composition appends.
Primitive policy 11a: The composition MUST write intent event id into EVERY record of the invocation but the intent.
Primitive policy 12: [Open] MUST size intent data and the kind's largest record against outcome envelope and the substrate's payload cap as the substrate measures a payload.
Primitive policy 13: [Open] MUST refuse invalid-request for an act whose largest record would not fit.
Primitive policy 14: An action signature MUST NOT take now.
Primitive policy 15: [Open] MUST use now for two comparisons alone: step 3's age of an open intent against recording instant under clock offset allowance, and the retention drop of sequence high water 5.
Deleted: Primitive policy 16. Composes 1 owns it: a stamp the composition takes from now is neither the substrate's nor the constituent's.
Primitive policy 17: The adopter's action MUST carry invocation id from [Open] into [Close] and [Refuse] as a parameter of each.
Primitive policy 18: The sweep MUST read now once per run at the sweep's own seam.
```

Term invocation id: injected at the adopter's seam alongside now, fresh per invocation, unique across every node of the instance for the journal's lifetime; opaque, byte-identity.

Term now: the seam-injected reading — at the adopter's seam per invocation, at the sweep's seam once per run, at the operator's seam once per [Resolve] call alongside operator run id, at the reader's seam once per [Read Invocation] call; each as the section titled Logic Confinement Principle in `execution-contract.md` declares it, never read inside the transition.

Term operator run id: injected at the operator's seam once per [Resolve] call, fresh for every call; the critical section holder for [Resolve].

NOTE: watch the fresh holder value (Term operator run id, Term run id).

Term hard alert: an alert on the compliance surface naming the invocation id and the arm that raised it — beside the findings register and no part of it (findings 6), and what a deployment's operators are paged by.

Term caller kind: EXACTLY ONE OF human, service — service where actor reference names the kind's service identity.

Term examine edge: `recorded_at + completion_bound + clock_offset_allowance`.

Term in-flight: an open intent for which examine edge EXCEEDS now.

Term aged: an open intent for which examine edge DOES NOT EXCEED now.

Term horizon edge: `recorded_at + retention_period − clock_offset_allowance − run_bound` — the allowance for the two clocks, the run bound for the age of a run's one reading by the time the run reads and writes on it.

Term as the substrate measures a payload: the serialized envelope `{action_ref, actor_ref, attestation_id, data}` with the longer of the caller's and the service identity's actor reference, the substrate's attestation id width, and the framing. The sweep's two closings — the recovered outcome (outcome data plus recovery, acting actor reference) and the escalation (database candidates plus the same) — are sized separately; the bound is the larger. [Resolve]'s closings, under the operator's actor reference, are bounded by outcome envelope and intent candidates cap, which take every reference under reference length cap.

```
Primitive policy 19: IF position EQUALS intent THEN invalid-credential MUST pass through unchanged with nothing written.
NOTE: watch position scoping — every rule of this family scopes by IF position = … (Primitive policy 19 through 23, Primitive policy 27 through 43); the corpus's answer is the condition, not a new form.
Primitive policy 20: IF position EQUALS intent THEN [Open] MUST NOT report invalid-request(step-4) BEFORE reading back by invocation id.
Primitive policy 21: WHEN the intent-position read-back finds the record:
    Primitive policy 21a: The action MUST proceed with a hard alert.
Primitive policy 22: WHEN the intent-position read-back finds nothing:
    Primitive policy 22a: The action MUST land invalid-request.
Primitive policy 23: IF position EQUALS intent THEN recording-failure(step-2) and recording-failure(step-3) MUST land recording-failure(intent), a step-3 whose record the read-back of Primitive policy 32a finds excepted.
Deleted: Primitive policy 24. Execution Contract Database 1 owns it.
Deleted: Primitive policy 25. Execution Contract Database 1 owns it.
Deleted: Primitive policy 26. Execution Contract Database 1 owns it.
Primitive policy 27: IF position EQUALS outcome THEN the action MUST read event id back by invocation id for invalid-request(step-4).
Primitive policy 28: IF position EQUALS outcome THEN the action MUST return success with a hard alert for an invalid-request(step-4) whose read-back finds the record.
Primitive policy 29: IF position EQUALS outcome THEN the writer MUST retry recording-failure(step-2) under the critical section, to the terminus at most.
Deleted: Primitive policy 29a. Execution Contract Database 2 and Primitive policy 32a own it: no deployment declares a fence on the journal, and recording-failure(step-3) is a lost reply at every position.
Primitive policy 30: A retry that reaches the terminus MUST land recording-failure(outcome).
Primitive policy 31: IF position EQUALS outcome THEN invalid-credential MUST land recording-failure(outcome).
Primitive policy 32: The composition MUST treat a record_action whose reply is lost as unknown at every position.
Primitive policy 32a: The composition MUST treat recording-failure(step-3) as a lost reply.
Primitive policy 33: The composition MUST NOT retry a lost-reply write blind.
Primitive policy 34: The composition MUST NOT read back a lost-reply write BEFORE journal write bound has elapsed since the issue, as remaining reports.
Primitive policy 35: The composition MUST read back by invocation id through the filtered range read.
Primitive policy 36: WHEN the read-back finds the record:
    Primitive policy 36a: The composition MUST adopt the record.
Primitive policy 37: WHEN the read-back finds nothing:
    Deleted: Primitive policy 37a. Execution Contract Database 2 and Primitive policy 37b own it: no deployment declares a fence on the journal, and a read-back that finds nothing lands the position's existing arm.
    Primitive policy 37b: The composition MUST land the position's existing arm.
Primitive policy 38: The composition MUST take the intent's sequence number and recording instant from the filtered range read.
Primitive policy 39: The composition MUST NOT take the intent's sequence number and recording instant from read_record.
Primitive policy 40: IF position EQUALS outcome THEN an invalid-request(step-4) whose read-back finds nothing MUST land recording-failure(outcome) with a hard alert.
Primitive policy 41: IF position EQUALS intent THEN invalid-request(step-1), invalid-request(step-2) and invalid-request(step-3) MUST land invalid-request.
Primitive policy 42: IF position EQUALS outcome THEN invalid-request(step-1), invalid-request(step-2) and invalid-request(step-3) MUST land recording-failure(outcome) with a hard alert.
Primitive policy 43: The action MUST NOT retry after invalid-request(step-3) or invalid-request(step-4).
Primitive policy 44: The composition MUST treat recording-failure(step-4) as recording-failure(step-2) at every position.
```

### Action wiring

Six actions and one read. [Open], [Close], [Refuse] and [Yield] are called by an adopter's action around the bound commit; [Reconcile] is the sweep, called by the deployment's scheduler and at every restart; [Resolve] is the operator's close; [Read Invocation] is the read.

```
Action wiring 1: EVERY action's signature MUST export the position of every code that could land on more than one side of the commit.
Action wiring 2: An adopter MUST export no code for the protocol's sake beyond the table below.
Action wiring 3: An adopter's re-entry arm MUST NOT collapse [Read Invocation]'s journal-unavailable into not-known.
Action wiring 4: An adopter's action MUST run: validate the adopter's own inputs; [Open]; the bound commit; the one action commit 2 through 8 route the commit's arm to; return.
Action wiring 5: The adopter MUST close EVERY constituent guard that fires after the intent through [Refuse].
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
| [Open] | `recording-failure(outcome)` | the intent stands and the lease no longer covers the commit, which this invocation never issues; the record is the sweep's; never re-run |
| the bound commit's pre-commit partition | the constituent's own code, after [Refuse] has landed the refusal | the act was refused and the attempt is recorded |
| [Refuse] | `already-accounted(closing_event_id)` ([Already Accounted]) | another writer already closed this invocation; report the act as accounted for, do not re-run |
| [Refuse] | `recording-failure(refusal, constituent_code)` | the refusal record did not land; the sweep records the attempt instead; never re-run the act |
| the unknown partition, after [Yield] | `recording-failure(outcome)` | the act may exist; its record is the sweep's; never re-run |
| [Close] | `recording-failure(outcome)` | the same |

*Never re-run* holds while the invocation is unclosed; once [Read Invocation] shows its closing, a new call is the caller's decision: a new act where the kind is repeatable, and where it is not, a second attempt that [Open] or the commit refuses wherever the act committed (open step 3.9, repeatable 2). [Resolve]'s codes are the operator's; [Reconcile]'s journal-unavailable goes to the scheduler. [Read Invocation] is not in the table because it is not called around the commit; it answers journal-unavailable (the act's state unreadable for now) and not-known ([Not Known] — no readable intent), and Action wiring 3 keeps a re-entry arm from re-running an irreversible act whose record is sitting in the journal.

#### Closure table

Every input an action takes and every answer its calls can meet — what Audit Trail's record_action, read_record and range read, Lease's take, remaining and release, and the adopter's probe can answer — with where the action lands it and the rule that owns the landing. The enumeration is exhaustive: an answer a constituent adds is a row this table lacks, and a cell no rule owns is a finding against the page.

**Inputs.** [Reconcile] takes none.

| Action | Input | Lands | Owner |
|---|---|---|---|
| [Open] | a kind the bindings table does not serve | invalid-request, with no read and no take | open step 1.9 |
| [Open] | act key, actor reference or credential blank | invalid-request, nothing written | open step 1.10, open step 1.5 |
| [Open] | an actor reference naming the kind's service identity | invalid-request, nothing written | open step 1.2, open step 1.5 |
| [Open] | intent data or the kind's largest record over the cap | invalid-request, nothing written | open step 1.4, Primitive policy 13 |
| [Close] | a pair no [Open] returned | recording-failure(outcome) at step 1 | Not Open 4, close step 1.2 |
| [Close] | an outcome action reference outside the kind's outcome refs | recording-failure(outcome), a hard alert, nothing appended | close 6 |
| [Refuse] | a pair no [Open] returned | recording-failure(refusal, constituent_code) at step 1, nothing written | Not Open 5, refuse step 0.2 |
| [Yield] | reply answered | ok, the section released | yield 5 |
| [Yield] | reply lost | ok, the grant left to end at its instant | yield 6 |
| [Resolve] | a kind the bindings table does not serve | invalid-request(malformed), with no take and nothing appended | resolve 33 |
| [Resolve] | a disposition outside the three forms | invalid-request(malformed), with no take and nothing appended | resolve 30 |
| [Resolve] | an outcome action reference outside the kind's outcome refs | invalid-request(malformed), with no take and nothing appended | resolve 31 |
| [Resolve] | candidates over intent candidates cap | invalid-request(candidates-over-cap) | resolve 28 |
| [Resolve] | an abandoned disposition for an in-flight intent | invalid-request(too-young) | resolve 18, resolve 19 |
| [Read Invocation] | an invocation id no readable intent of the act key carries | not-known | read invocation 3b |
| [Read Invocation] | an act key with no readable intent | not-known | read invocation 12 |

**Lease: the take.**

| take answers | [Open] | [Resolve] | [Reconcile] |
|---|---|---|---|
| expires_at | the step-3 re-read (open step 3.1) | the re-read (resolve 8) | the step-2 re-read (reconcile step 2.4) |
| unavailable | section-unavailable, nothing written (open step 2.3, act section 5) | section-unavailable (resolve 6, act section 5) | skipped (reconcile step 2.3) |
| no answer | section-unavailable, nothing written (open step 2.3), remaining read as none (act section 17) | section-unavailable (resolve 6), remaining read as none (act section 17) | skipped (reconcile step 2.3), remaining read as none (act section 17) |

**Lease: the remaining reading** behind a write. The floor is write floor, and commit floor for the reading the commit goes out behind; every journal write takes a reading of its own (journal write bound 1).

| remaining answers | [Open] before the intent | [Open] before its return | [Close] | [Refuse] | [Resolve] | [Reconcile] |
|---|---|---|---|---|---|---|
| a remaining term above the floor | the intent record (open step 4.3) | open result, the section held (open step 5.2, open step 5.3) | the step-2 re-read (close step 2.1) | the step-2 re-read (refuse step 2.1) | the re-read (resolve 8) | the probe (reconcile step 3.1) |
| a remaining term at or below the floor, none, or no answer read as none (act section 17) | section-unavailable, released (open step 4.2) | recording-failure(outcome), released, the intent left open (open step 5.5, open step 5.6) | recording-failure(outcome), nothing written (close step 1.2) | recording-failure(refusal, constituent_code), nothing written (refuse step 1.2) | section-unavailable, released (resolve 7) | skipped (reconcile step 2.7) |

**Lease: the release.** Every release leaves the action's answer as it is: not-held is discarded (act section 6); no answer is read as none for the rest of the grant (act section 17) and the call is not issued again (act section 18); and where a call is in flight under the grant, nothing is issued (Term release, act section 15).

**Audit Trail: record_action**, by position. The sweep's closing and recovery_intended writes follow the outcome position (reconcile step 3.15).

| record_action answers | intent: [Open] step 4 | outcome: [Close] step 3 | outcome: the sweep | refusal: [Refuse] step 3 | resolution: [Resolve] |
|---|---|---|---|---|---|
| event id | open invocations populated, open result after open step 5.4's reading (open step 5.1, open step 5.2) | cleared, released, outcome event id and landing actor invocation (close step 4.1 through 4.3) | the act counted closed or escalated (reconcile step 3.2c, 3.5b, 3.8c) | cleared, released, refusal event id (refuse step 3.9, 3.10, 3.12) | released, closing event id (resolve 22, resolve 35) |
| invalid-credential | passed through unchanged, nothing written, released (Primitive policy 19, open step 4.5) | recording-failure(outcome), released (Primitive policy 31, close step 3.8) | surfaced at once, nothing more written under the credential, skipped, the rest of the run unreached (reconcile step 3.18, 3.19, 2.9) | recording-failure(refusal, constituent_code), the intent left open (refuse step 3.7) | invalid-credential, released, nothing appended (resolve 3) |
| invalid-request(step-1), (step-2) or (step-3) | invalid-request, released (Primitive policy 41, open step 4.5) | recording-failure(outcome), a hard alert (Primitive policy 42, close step 3.3) | the act closed as escalated, cause outcome-unrecordable (reconcile step 3.20); where that escalation answers the same, left for the next run with a hard alert (reconcile step 3.23) | recording-failure(refusal, constituent_code), the intent left open (refuse step 3.8) | recording-failure(resolution), a hard alert (resolve 29) |
| invalid-request(step-4), the read-back finding the record | proceeds with a hard alert (Primitive policy 20, 21) | success with a hard alert (Primitive policy 27, 28) | read back, success with a hard alert (reconcile step 3.16, Primitive policy 28) | refusal event id with a hard alert (refuse step 3.3, 3.12) | success with a hard alert (resolve 24) |
| invalid-request(step-4), the read-back finding nothing | invalid-request, released (Primitive policy 22, open step 4.5) | recording-failure(outcome), a hard alert (Primitive policy 40) | a hard alert, the act left for the next run (Primitive policy 40) | recording-failure(refusal, constituent_code), the intent left open (Primitive policy 37b) | recording-failure(resolution) (Primitive policy 37b) |
| recording-failure(step-2), and recording-failure(step-4) read as it (Primitive policy 44) | recording-failure(intent), released (Primitive policy 23, open step 4.5) | retried under the section to the terminus, step 2 re-run first; cut short, recording-failure(outcome), released (Primitive policy 29, 30, close step 3.4, 3.5, 3.7) | retried within the lease, else left for the next run under journal-unavailable (Primitive policy 29, reconcile step 3.17, 3.22) | recording-failure(refusal, constituent_code), the intent left open (refuse step 3.5) | recording-failure(resolution) (resolve 26) |
| recording-failure(step-3) or no answer — a lost reply (Primitive policy 32, 32a), read back once journal write bound has passed (Primitive policy 33 through 35) — the read-back finding the record | adopted, [Open] proceeding (Primitive policy 36) | adopted, cleared, released, returned (Primitive policy 36, close step 4.1 through 4.3) | adopted (Primitive policy 36) | refusal event id (refuse step 3.12) | adopted, closing event id (Primitive policy 36, resolve 35) |
| a lost reply, the read-back finding nothing | recording-failure(intent), released (Primitive policy 23, 37b) | recording-failure(outcome) (Primitive policy 37b) | left for the next run (Primitive policy 37b, reconcile step 3.17), under journal-unavailable for a recording-failure(step-3) (reconcile step 3.22) | recording-failure(refusal, constituent_code), the intent left open (refuse step 3.6) | recording-failure(resolution) (resolve 26) |

A read-back that answers unavailable or gives no answer lands the position's recording-failure arm (Term read path, Capability requirement 6).

**Audit Trail: the range read**, what it answers.

| Read | What it answers | Lands | Owner |
|---|---|---|---|
| [Open] step 1 | an open intent [Open] step 3 would refuse | act-in-flight(invocation_id), with no take | open step 1.7 |
| [Open] step 1 | no such intent | the take | open step 1.6, open step 2.1 |
| [Open] step 3 | an in-flight open intent | act-in-flight(invocation_id), released | open step 3.4, open step 3.5 |
| [Open] step 3 | an aged open intent, the kind's service identity not none | act-in-flight(invocation_id), released | open step 3.6, open step 3.7 |
| [Open] step 3 | an aged open intent, the kind's service identity none | proceeds, the old intent left open and surfaced | open step 3.8 |
| [Open] step 3 | an outcome for the act, the kind not repeatable | act-landed(outcome_event_id), released | open step 3.9 |
| [Open] step 3 | a read that exhausts the lease | section-unavailable, released, nothing written | open step 3.11, open step 3.12 |
| [Open] step 3 | none of these | the intent record | open step 4.3 |
| [Close] step 2 | an outcome naming the invocation id | adopted, released, outcome event id and landing actor | close step 2.2 |
| [Close] step 2 | an abandonment or an escalation naming it | recording-failure(outcome), released | close step 2.3 |
| [Close] step 2 | a refusal naming it | unreachable: an adopter's action routes each commit arm to one action | Action wiring 4, commit 1 |
| [Close] step 2 | no closing | the outcome record | close step 3.1 |
| [Refuse] step 2 | a closing naming the invocation id | already-accounted(closing_event_id), nothing appended | refuse step 2.2, refuse step 2.3 |
| [Refuse] step 2 | no closing | the refusal record | refuse step 3.1 |
| [Resolve] | an outcome or a refusal naming the invocation id | already-accounted(closing_event_id) | resolve 9 |
| [Resolve] | an escalation standing | any disposition, naming it in supersedes | resolve 15 |
| [Resolve] | an abandonment standing, the disposition an outcome | the outcome, superseding it | resolve 16a, resolve 13 |
| [Resolve] | an abandonment standing, any other disposition | invalid-request(already-abandoned) | resolve 16b |
| [Resolve] | no closing standing | any disposition | resolve 14 |
| [Reconcile] step 1 | an aged intent of a served kind short of its horizon edge | kept | reconcile step 1.2 |
| [Reconcile] step 1 | an intent of a kind the bindings table does not serve | surfaced, never closed, counted in surfaced | reconcile step 1.6, reconcile step 1.7, Binding 4, Binding 5 |
| [Reconcile] step 2 | a closing landed since step 1 | released, closed already | reconcile step 2.5, reconcile step 2.6 |
| [Reconcile] step 2 | the intent still open | the probe | reconcile step 3.1 |
| [Read Invocation] | the act's invocations | the invocation report | read invocation 2, read invocation 4 through 6, read invocation 10 |

**Audit Trail: read_record** at [Resolve] (resolve 11).

| read_record answers | Lands | Owner |
|---|---|---|
| the act's intent carrying the invocation id, its payload not Purged | proceeds | resolve 11 |
| an intent whose payload the substrate reports Purged | invalid-request(purged) | resolve 12 |
| any other record: no intent of the act carrying the invocation id | not-known | resolve 34 |
| not-known | not-known | resolve 10 |
| no answer | recording-failure(resolution), never not-known | Capability requirement 9, Capability requirement 10 |

**A read that fails.** Every read here is the composition's own, so an invalid-query is a fault of the build: it lands where unavailable lands, is surfaced, and opens no outage finding.

| Read | unavailable | invalid-query |
|---|---|---|
| [Open] step 1 | journal-unavailable (open step 1.8) | journal-unavailable, surfaced (Capability requirement 13, 4) |
| [Open] step 3 | journal-unavailable, released, nothing written (open step 3.13) | the same, surfaced (Capability requirement 13, 4) |
| [Close] step 2 | recording-failure(outcome), nothing written (close step 2.4) | the same, surfaced (Capability requirement 13, 4) |
| [Refuse] step 2 | recording-failure(refusal, constituent_code) (Capability requirement 6, Term read path) | the same, surfaced (Capability requirement 13, 4) |
| [Resolve]'s re-read | recording-failure(resolution) (Capability requirement 6, Term read path) | the same, surfaced (Capability requirement 13, 4) |
| a read-back (Primitive policy 20, 27 and 35) | the position's recording-failure arm (Capability requirement 6, Term read path) | the same, surfaced (Capability requirement 13, 4) |
| [Reconcile] step 1 | nothing written, journal-unavailable returned, the outage finding opened or advanced (reconcile 1) | journal-unavailable returned, surfaced, no outage finding (Capability requirement 13, 14, 4) |
| [Reconcile] step 2 | nothing written, released, skipped, the outage finding opened or advanced (reconcile step 2.10) | nothing written, released, skipped, surfaced, no outage finding (Capability requirement 13, 14, 4) |
| [Read Invocation] | journal-unavailable, never not-known (read invocation 11, Action wiring 3) | the same, surfaced (Capability requirement 13, 4) |

**The adopter's probe** at [Reconcile] step 3, for a kind that declares a service identity; under none the run probes, writes nothing and reports (reconcile 2).

| probe answers | Lands | Owner |
|---|---|---|
| committed | `<kind>.recovery_intended`, then the outcome under the service identity; closed | reconcile step 3.2 |
| not-committed | `<kind>.escalated`, cause not-observed; escalated | reconcile step 3.5 |
| undecidable | `<kind>.escalated` naming the candidates, past intent candidates cap their count and range; escalated | reconcile step 3.8 through 3.10 |
| unavailable | nothing written, released, skipped; store-unavailable opened or advanced | reconcile step 3.13 |

---

#### Open contract

```
open(kind, act_key, actor_ref, credential, intent_data)
  answers open result
  refuses invalid-credential | invalid-request | act-in-flight(invocation_id) | act-landed(outcome_event_id) | section-unavailable | journal-unavailable | recording-failure(intent) | recording-failure(outcome)
```

Term open result: invocation id and intent event id — what open answers. Neither invocation id nor now is a parameter of open: the adopter's seam injects both (Term invocation id, Term now, Primitive policy 14).

Term intent event id: intent_event_id — the event id the journal assigns the intent record, carried by every later record of the invocation (Primitive policy 11a).

Term intent data: intent_data — the caller's payload at [Open], carrying the invocation's parameters and the pairing datum.

Term actor reference: actor_ref — the acting actor Actor Identity attests, reached through the journal.

Term resolve refusal: purged | malformed | too-young | already-abandoned | candidates-over-cap — the reasons [Resolve] gives for an invalid request.

Opens one invocation of the act: takes the critical section, sizes the records, writes the intent record — where the caller's credential is verified — and returns the pair the adopter carries through the commit to [Close].

Steps:

1. **Validate and size.**
   ```
   open step 1.1: [Open] MUST validate act key, actor reference and credential non-empty per Primitive policies.
   open step 1.2: IF caller kind EQUALS service THEN [Open] MUST land invalid-request.
   open step 1.3: [Open] MUST size intent data and the kind's largest record per Primitive policy 12.
   open step 1.4: IF the sized record EXCEEDS the cap THEN [Open] MUST land invalid-request.
   open step 1.5: A step-1 refusal MUST write nothing.
   open step 1.6: [Open] MUST NOT take the critical section BEFORE reading open invocations at (kind, act key) from the journal.
   open step 1.7: IF the read of open step 1.6 shows an open intent open step 3.5 or open step 3.7 refuses THEN [Open] MUST land act-in-flight(invocation id) with no take.
   open step 1.8: IF the read of open step 1.6 fails THEN [Open] MUST land journal-unavailable.
   open step 1.9: IF kind IS NOT IN the bindings table THEN [Open] MUST land invalid-request with no read and no take.
   open step 1.10: IF act key EQUALS blank OR actor reference EQUALS blank OR credential EQUALS blank THEN [Open] MUST land invalid-request.
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
   open step 4.1: IF remaining DOES NOT EXCEED write floor THEN [Open] MUST NOT write the intent record.
   open step 4.2: WHEN remaining DOES NOT EXCEED write floor:
       open step 4.2a: [Open] MUST release.
       open step 4.2b: [Open] MUST land section-unavailable.
   open step 4.3: [Open] MUST write AuditTrail.record_action(action reference set to `<kind>.intended`, actor reference, credential, data set to intent payload), answering intent event id.
   open step 4.4: Step 4's arms MUST follow the intent position of Primitive policy 19 through 23 and Primitive policy 27 through 43.
   open step 4.5: IF step 4 lands a refusal THEN [Open] MUST release.
   ```
5. **Populate, read for the commit, and return.**
   ```
   open step 5.1: [Open] MUST populate open invocations at (kind, act key) with the intent.
   open step 5.2: [Open] MUST return invocation id and intent event id.
   open step 5.3: [Open] MUST hold the critical section at return.
   open step 5.4: [Open] MUST query remaining((kind, act key), invocation id) as the last call [Open] makes.
   open step 5.5: IF remaining DOES NOT EXCEED commit floor THEN [Open] MUST release.
   open step 5.6: IF remaining DOES NOT EXCEED commit floor THEN [Open] MUST land recording-failure(outcome) with the intent left open.
   Deleted: open step 5.7. No adopter binds a declared commit fence, whose deadline it minted; an adopter that needs it reopens it with a Decisions entry.
   Deleted: open step 5.8. No adopter binds a declared commit fence, whose deadline it returned; an adopter that needs it reopens it with a Decisions entry.
   ```

---

#### Close contract

```
close(kind, act_key, invocation_id, intent_event_id, actor_ref, credential, outcome_action_ref, outcome_data)
  answers close result
  refuses recording-failure(outcome)
```

Term close result: outcome event id and landing actor — what close answers.

Term outcome data: outcome_data — the caller's payload at [Close].

Term outcome action reference: outcome_action_ref — the action reference [Close] writes on the outcome record, one of the kind's enumerated outcome refs (journal 2).

Term outcome event id: outcome_event_id — the event id the journal assigns the outcome record.

Term landing actor: landed_by — which writer landed the outcome: the invocation, the operator, or the sweep.

Writes the act's outcome record after the bound commit has returned, under the critical section [Open] took, and releases the critical section. The one action that can find its own work already done.

```
close 1: The adopter MUST pass [Close] the actor reference [Open] was given for the invocation.
close 2: The composition MUST NOT retain state between [Open] and [Close].
close 3: [Close] and [Refuse] MUST take intent event id.
close 4: The adopter's action MUST decide not-open from the invocation's own [Open] result ([Not Open]).
close 5: The adopter MUST pass [Close] outcome data carrying only what probe answers for the act.
close 6: An outcome action reference that IS NOT IN the kind's enumerated outcome refs MUST land recording-failure(outcome) with a hard alert and nothing appended.
```

Steps:

1. **Confirm standing.**
   ```
   close step 1.1: [Close] MUST query remaining((kind, act key), invocation id).
   close step 1.2: WHEN remaining DOES NOT EXCEED write floor OR remaining EQUALS none:
       close step 1.2a: [Close] MUST write nothing.
       close step 1.2b: [Close] MUST discard the commit's reply.
       NOTE: watch negative capability — an obligation to discard a reply already in hand (close step 1.2b).
       close step 1.2c: [Close] MUST return recording-failure(outcome).
   Deleted: close step 1.3. No adopter binds the counted(n) deviation, the one retry terminus beside the lease; an adopter that needs it reopens it with a Decisions entry.
   ```
2. **Pre-check under the critical section — proceed as landed.**
   ```
   close step 2.1: [Close] MUST re-read the journal from sequence high water for the invocation id under the critical section.
   close step 2.2: WHEN a closing record naming the invocation id is an outcome:
       close step 2.2a: [Close] MUST adopt the outcome as the invocation's own.
       close step 2.2b: [Close] MUST release.
       close step 2.2c: [Close] MUST return outcome event id and landing actor.
       close step 2.2d: IF the outcome carries resolving actor THEN [Close] MUST return landing actor set to operator.
       close step 2.2e: IF the outcome carries recovery AND no resolving actor THEN [Close] MUST return landing actor set to sweep.
       close step 2.2f: IF the outcome carries no recovery THEN [Close] MUST return landing actor set to invocation.
   close step 2.3: WHEN a closing record naming the invocation id is an abandonment OR an escalation:
       close step 2.3a: [Close] MUST NOT adopt the record.
       close step 2.3b: [Close] MUST release and return recording-failure(outcome).
   close step 2.4: WHEN the step-2 re-read fails:
       close step 2.4a: [Close] MUST write nothing.
       close step 2.4b: [Close] MUST return recording-failure(outcome).
   Deleted: close step 2.5. Execution Contract Database 2 owns it: a writer's re-read, lease check and append are one transaction, and no deployment declares a fence on the journal.
   ```
3. **Outcome record.**
   ```
   close step 3.1: [Close] MUST write AuditTrail.record_action(action reference set to outcome action reference, actor reference, credential, data set to outcome payload), answering outcome event id.
   close step 3.2: Step 3's arms MUST follow the outcome position of Primitive policy 19 through 23 and Primitive policy 27 through 43.
   close step 3.3: An invalid-request(step-1), invalid-request(step-2) or invalid-request(step-3) at step 3 MUST land recording-failure(outcome) with a hard alert.
   close step 3.4: [Close] MUST NOT retry after recording-failure(step-2), recording-failure(step-3) or a lost reply BEFORE re-running step 2.
   close step 3.5: IF remaining DOES NOT EXCEED write floor THEN [Close] MUST NOT retry.
   Deleted: close step 3.6. No adopter binds the counted(n) deviation; an adopter that needs it reopens it with a Decisions entry.
   Deleted: close step 3.6a. No adopter binds the counted(n) deviation; an adopter that needs it reopens it with a Decisions entry.
   close step 3.7: WHEN the lease cuts a retry short:
       close step 3.7a: [Close] MUST release.
       close step 3.7b: [Close] MUST land recording-failure(outcome).
   close step 3.8: WHEN step 3 answers invalid-credential:
       close step 3.8a: [Close] MUST release.
       close step 3.8b: [Close] MUST land recording-failure(outcome).
   ```
4. **Clear and release.**
   ```
   close step 4.1: [Close] MUST remove the invocation id from open invocations at (kind, act key).
   close step 4.2: [Close] MUST release the critical section.
   close step 4.3: [Close] MUST return outcome event id and landing actor set to invocation.
   ```

---

#### Refuse contract

```
refuse(kind, act_key, invocation_id, intent_event_id, actor_ref, credential, reason, constituent_code)
  answers refusal_event_id
  refuses already-accounted(closing_event_id) | recording-failure(refusal, constituent_code)
```

Term refusal event id: refusal_event_id — the event id the journal assigns the refusal record; what refuse answers.

Closes an intent whose bound commit did not commit — the constituent refused on a pre-commit arm — so the intent does not stand open for the sweep to probe.

Steps:

0. **Not open.**
   ```
   refuse step 0.1: The adopter's action MUST decide not-open from the invocation's own [Open] result ([Not Open]).
   refuse step 0.2: [Refuse] MUST write nothing for a pair no [Open] returned.
   NOTE: watch rule inheritance — refuse step 0.1 and refuse step 2.1 restate [Close]'s close 4 and close step 2.1 for [Refuse] rather than inheriting; the grammar has no inheritance form.
   ```
1. **Confirm standing, before any read.**
   ```
   refuse step 1.1: [Refuse] MUST NOT read BEFORE querying remaining((kind, act key), invocation id).
   refuse step 1.2: WHEN remaining DOES NOT EXCEED write floor OR remaining EQUALS none:
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
   Deleted: refuse step 3.2. refuse step 3.3 through 3.8 and refuse step 3.12 own it: each arm of the refusal record is landed there.
   refuse step 3.3: [Refuse] MUST read the refusal back by invocation id for invalid-request(step-4).
   refuse step 3.4: [Refuse] MUST NOT retry after invalid-request(step-3) or invalid-request(step-4).
   refuse step 3.5: recording-failure(step-2) and recording-failure(step-3) MUST land recording-failure(refusal, constituent code) with the intent left open, a step-3 whose record the read-back of Primitive policy 32a finds excepted.
   refuse step 3.6: A lost reply whose one read-back finds nothing MUST land recording-failure(refusal, constituent code) with the intent left open.
   refuse step 3.7: invalid-credential MUST land recording-failure(refusal, constituent code) with the intent left open.
   refuse step 3.8: An invalid-request(step-1), invalid-request(step-2) or invalid-request(step-3) MUST land recording-failure(refusal, constituent code) with the intent left open.
   refuse step 3.9: [Refuse] MUST clear the map.
   refuse step 3.10: [Refuse] MUST release the critical section.
   refuse step 3.11: The composition MUST NOT suppress a refusal record.
   refuse step 3.12: IF the write answers an event id OR a read-back finds the refusal record THEN [Refuse] MUST return refusal event id, with a hard alert for an invalid-request(step-4).
   ```

---

#### Yield contract

```
yield(kind, act_key, invocation_id, reply)
  answers ok
```

```
yield 1: [Yield] MUST NOT write.
yield 2: The adopter's action MUST call [Yield] on the unknown partition.
yield 3: No adopter MAY touch act section directly.
yield 4: [Yield] MUST NOT close the intent.
yield 5: IF reply EQUALS answered THEN [Yield] MUST release the critical section.
yield 6: IF reply EQUALS lost THEN [Yield] MUST NOT issue Lease's release for the grant.
yield 7: The adopter's action MUST pass reply as lost for a bound commit that returned nothing AND as answered for a reply the constituent's contract does not declare pre-commit.
```

Term reply: reply — answered | lost: what the bound commit returned on the unknown partition.

---

#### Resolve contract

```
resolve(kind, act_key, invocation_id, intent_event_id, actor_ref, credential, disposition)
  answers closing_event_id
  refuses already-accounted(closing_event_id) | not-known | section-unavailable | invalid-credential | invalid-request(resolve refusal) | recording-failure(resolution)
```

The human-attested close: an operator closes an open intent the sweep cannot — under `service_identity = none`, or for an escalated act the operator has investigated — supplying the disposition the operator's own run of the adopter's probe supports.

```
resolve 1: The operator MUST supply disposition as EXACTLY ONE OF outcome(outcome action reference, outcome data), abandoned(cause), escalated(candidates).
resolve 2: The substrate MUST validate the operator's credential at the closing record_action and nowhere earlier.
resolve 3: A credential failure MUST land invalid-credential with the critical section released and nothing appended.
resolve 4: [Resolve] MUST take the critical section: take((kind, act key), operator run id, sweep lease).
resolve 5: The take MUST NOT block longer than the holder's remaining lease.
resolve 6: A failed take MUST land section-unavailable.
resolve 7: WHEN remaining DOES NOT EXCEED write floor:
    resolve 7a: [Resolve] MUST NOT write.
    resolve 7b: [Resolve] MUST release.
    resolve 7c: [Resolve] MUST land section-unavailable.
resolve 8: [Resolve] MUST re-read the act's records under the critical section.
resolve 9: An outcome or a refusal naming the invocation id MUST land already-accounted(closing event id).
Deleted: resolve 9a. Execution Contract Database 2 owns it: a writer's re-read, lease check and append are one transaction, so no act carries a binding duplicate.
resolve 10: An intent event id read_record answers not-known for MUST land not-known.
resolve 11: [Resolve] MUST read the intent by read_record(intent event id).
resolve 12: An intent whose payload the substrate reports Purged MUST land invalid-request(purged).
resolve 13: EVERY closing [Resolve] writes over an existing record MUST carry supersedes naming that record's event id.
resolve 14: WHEN no closing stands:
    resolve 14a: [Resolve] MAY write any disposition as the act's closing.
resolve 15: WHEN an escalated record stands:
    resolve 15a: [Resolve] MUST name the record in supersedes for any disposition.
resolve 16: WHEN an abandoned record stands:
    resolve 16a: [Resolve] MAY supersede the record ONLY IF disposition EQUALS outcome.
    resolve 16b: IF disposition DOES NOT EQUAL outcome THEN [Resolve] MUST land invalid-request(already-abandoned).
Deleted: resolve 17. resolve 16b owns it: every disposition but outcome over a standing abandonment answers already-abandoned, an abandoned one among them.
resolve 18: An abandoned disposition for an in-flight intent MUST land invalid-request(too-young).
resolve 19: The too-young guard MUST compare against now injected at the operator's seam.
Deleted: resolve 20. resolve 32 owns it: no adopter binds a declared commit fence, so the condition it opened held for every kind.
Deleted: resolve 20a. resolve 32 owns it, for every kind.
resolve 32: [Resolve] MUST admit the operator's abandoned disposition as the operator's attestation that the database has been quiet for as long as the operator's judgment requires.
resolve 21: [Resolve] MUST write the closing record under the operator's own credential with recovery set to true, resolving actor set to actor reference, acting actor reference set to the intent's actor reference, and no recovery_intended.
resolve 22: [Resolve] MUST release after the write.
resolve 23: The closing write's arms MUST follow the resolution position of resolve 24 through 29.
resolve 24: After invalid-request(step-4), [Resolve] MUST read the record back by invocation id and return success with a hard alert.
resolve 25: [Resolve] MUST NOT retry after invalid-request(step-3) or invalid-request(step-4).
resolve 26: step-2, step-3 and a lost reply after an empty read-back MUST land recording-failure(resolution).
resolve 27: invalid-request MUST carry the cause: malformed, candidates-over-cap, purged, already-abandoned, too-young.
resolve 28: A candidate list exceeding intent candidates cap MUST land invalid-request(candidates-over-cap).
resolve 29: An invalid-request(step-1), invalid-request(step-2) or invalid-request(step-3) from the closing write MUST land recording-failure(resolution) with a hard alert.
resolve 30: A disposition outside the three forms resolve 1 names MUST land invalid-request(malformed) with no take and nothing appended.
resolve 31: A disposition whose outcome action reference IS NOT IN the kind's enumerated outcome refs MUST land invalid-request(malformed) with no take and nothing appended.
resolve 33: IF kind IS NOT IN the bindings table THEN [Resolve] MUST land invalid-request(malformed) with no take and nothing appended.
resolve 34: An intent event id naming no `<kind>.intended` record of the act key carrying invocation id MUST land not-known, an intent whose payload the substrate reports Purged excepted.
resolve 35: [Resolve] MUST return closing event id for the closing the write lands.
```

---

#### Reconcile contract

```
reconcile()
  answers reconcile tally
  refuses journal-unavailable
```

Term reconcile tally: examined, closed, escalated, reported, skipped, closed already, surfaced and unreached — what reconcile answers; reconcile is the one action with no kind: the run sweeps every bound kind.

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

Term partition: `closed + escalated + reported + skipped + closed_already = examined`.

Term surfaced: the unbound-kind intents step 1 reports; outside the partition.

Term unreached: the acts step 1 kept that the run stopped short of after the service identity's credential was refused (reconcile step 2.1, reconcile step 2.8 through 2.9); outside the partition.

Term closed already: an act step 2's re-read finds another writer closed since step 1.

Term skipped: an act the run examined and left for the next run — a failed take; a re-read at step 2 that failed (reconcile step 2.10); a probe answering unavailable; a closing write or a recovery_intended write whose retries the lease cut short; a closing write or a recovery_intended write left for the next run after step 3 counted the act; an act whose remaining did not exceed write floor at step 2 before any write; an act whose write under the service identity answered invalid-credential (reconcile step 3.18); an act whose outcome-unrecordable escalation answered invalid-request(step-1), invalid-request(step-2) or invalid-request(step-3) (reconcile step 3.23). The list is exhaustive.

Term reported: an act the run examined, of a kind whose service identity EQUALS none.

1. **Enumerate between two edges.**
   ```
   reconcile step 1.1: The run MUST rebuild open invocations and act closings from the substrate's range read.
   reconcile step 1.2: The run MUST keep EVERY aged intent of a kind the bindings table serves for which now PRECEDES horizon edge, and no other intent.
   NOTE: watch applicability — the pass's domain is carried by a relative clause (reconcile step 1.2); the corpus has no WHERE.
   reconcile step 1.3: The run MUST make reconcile step 1.2's comparison from the sweep's seam reading against the substrate's stamp, under clock offset allowance.
   Deleted: reconcile step 1.4. Execution Contract Database 2 owns it: a writer's re-read, lease check and append are one transaction, so the run keeps no closing record for a duplicate scan.
   Deleted: reconcile step 1.5. Execution Contract Database 2 owns it: a writer's re-read, lease check and append are one transaction, so the run keeps no closing record for a duplicate scan.
   reconcile step 1.6: Step 1 MUST surface EVERY unbound-kind intent per Binding 4 through 6.
   reconcile step 1.7: The run MUST count EVERY intent step 1 surfaces in surfaced.
   ```
2. **Take the act's critical section and re-read.**
   ```
   reconcile step 2.1: The run MUST take the critical section for each kept intent: take((kind, act key), critical section holder, sweep lease), an intent not yet examined when a write under the service identity answers invalid-credential excepted.
   reconcile step 2.2: The take MUST NOT block longer than the current holder's remaining lease.
   reconcile step 2.3: A take that fails after the wait MUST count the act in skipped.
   reconcile step 2.4: Under the critical section, the run MUST re-read open invocations at (kind, act key) and sweep closed ids.
   reconcile step 2.5: IF a closing record naming the invocation id landed since step 1 THEN the run MUST release.
   reconcile step 2.6: IF a closing record naming the invocation id landed since step 1 THEN the run MUST count the act in closed already.
   reconcile step 2.7: WHEN remaining DOES NOT EXCEED write floor:
       reconcile step 2.7a: The run MUST count the act in skipped.
   reconcile step 2.8: The run MUST NOT take the critical section for an intent reconcile step 2.1 excepts.
   reconcile step 2.9: The run MUST count EVERY intent reconcile step 2.1 excepts in unreached.
   reconcile step 2.10: WHEN the step-2 re-read fails:
       reconcile step 2.10a: The run MUST write nothing for the act.
       reconcile step 2.10b: The run MUST release.
       reconcile step 2.10c: The run MUST count the act in skipped.
       reconcile step 2.10d: The run MUST open or advance the instance finding journal-unavailable on compliance surface.
   ```
3. **Probe the database.**
   ```
   reconcile step 3.1: The run MUST call the adopter's bound probe(act key, intent payload).
   reconcile step 3.2: WHEN probe EQUALS committed(outcome action reference, outcome data):
       reconcile step 3.2a: The run MUST write `<kind>.recovery_intended` under the service identity with data carrying invocation id, intent event id, act key and plan set to outcome.
       reconcile step 3.2b: The run MUST write the outcome record outcome action reference under the service identity with data set to recovered outcome payload.
       reconcile step 3.2c: The run MUST count closed.
   reconcile step 3.3: A later run MAY write a second recovery_intended for the act.
   Deleted: reconcile step 3.4. No adopter binds a declared commit fence, the one kind the sweep abandoned; an adopter that needs it reopens it with a Decisions entry.
   Deleted: reconcile step 3.4a. No adopter binds a declared commit fence, the one kind the sweep abandoned; an adopter that needs it reopens it with a Decisions entry.
   Deleted: reconcile step 3.4b. No adopter binds a declared commit fence, the one kind the sweep abandoned; an adopter that needs it reopens it with a Decisions entry.
   reconcile step 3.5: WHEN probe EQUALS not-committed:
       reconcile step 3.5a: The run MUST write `<kind>.escalated` under the service identity with data carrying invocation id, intent event id, act key and cause set to not-observed.
       reconcile step 3.5b: The run MUST count escalated.
   Deleted: reconcile step 3.6. No adopter binds a declared commit fence, the one kind whose not-committed the sweep held short of abandon edge; an adopter that needs it reopens it with a Decisions entry.
   Deleted: reconcile step 3.6a. No adopter binds a declared commit fence, the one kind whose not-committed the sweep held short of abandon edge; an adopter that needs it reopens it with a Decisions entry.
   Deleted: reconcile step 3.6b. No adopter binds a declared commit fence, the one kind whose not-committed the sweep held short of abandon edge; an adopter that needs it reopens it with a Decisions entry.
   reconcile step 3.7: The sweep MUST NOT re-run an act.
   reconcile step 3.8: WHEN probe EQUALS undecidable(candidates):
       reconcile step 3.8a: The run MUST write `<kind>.escalated` under the service identity with data carrying invocation id, intent event id, act key, cause set to undecidable and database candidates set to candidates.
       Deleted: reconcile step 3.8b. reconcile step 3.21 owns it, for every cause.
       reconcile step 3.8c: The run MUST count escalated.
   reconcile step 3.9: database candidates MUST NOT carry more than intent candidates cap references.
   reconcile step 3.10: Past the cap, the escalated record MUST carry the count and the range.
   reconcile step 3.11: The sweep MUST NOT choose among candidates.
   reconcile step 3.12: The sweep MUST NOT write an outcome the sweep did not read.
   reconcile step 3.13: WHEN probe EQUALS unavailable:
       reconcile step 3.13a: The run MUST write nothing.
       reconcile step 3.13b: The run MUST release and count skipped.
       reconcile step 3.13c: The run MUST open or advance the instance finding store-unavailable for the act's kind.
   Deleted: reconcile step 3.14. Invariant 4.9 owns it: no adopter binds a declared commit fence, so the sweep writes no abandoned record, for an outage or otherwise; an adopter that needs the fence reopens it with a Decisions entry.
   reconcile step 3.15: EVERY closing write's arms and EVERY recovery_intended write's arms MUST follow the outcome position.
   reconcile step 3.16: After invalid-request(step-4), the run MUST read the record back.
   reconcile step 3.17: The run MUST leave EVERY step-2 arm and step-3 arm not landed within the lease for the next run.
   reconcile step 3.18: The run MUST surface an invalid-credential for the service identity on compliance surface at once.
   reconcile step 3.19: The run MUST NOT write further under the credential until reconfigured.
   reconcile step 3.20: An invalid-request(step-1), invalid-request(step-2) or invalid-request(step-3) on a closing write or on a recovery_intended write MUST close the act as `<kind>.escalated` with cause set to outcome-unrecordable, the write of that escalation excepted (reconcile step 3.23).
   reconcile step 3.21: The run MUST surface EVERY act the run closes as `<kind>.escalated` on compliance surface as the act finding escalated.
   reconcile step 3.22: The run MUST open or advance the instance finding journal-unavailable on compliance surface for EVERY recording-failure(step-2) and EVERY recording-failure(step-3) reconcile step 3.17 leaves for the next run.
   reconcile step 3.23: IF the escalation reconcile step 3.20 writes answers invalid-request(step-1), invalid-request(step-2) or invalid-request(step-3) THEN the run MUST leave the act for the next run with a hard alert.
   ```
4. **Update and release.**
   ```
   reconcile step 4.1: The run MUST update open invocations.
   reconcile step 4.2: The run MUST update act closings.
   reconcile step 4.3: The run MUST update sweep closed ids.
   reconcile step 4.4: The run MUST release the critical section.
   ```
5. **Liveness.**
   ```
   reconcile step 5.1: IF at risk threshold DOES NOT EXCEED intent age THEN the run MUST surface an examined or skipped intent whose closing has not landed as the act finding closure-at-risk.
   Deleted: reconcile step 5.2. Execution Contract Database 2 owns it: a writer's re-read, lease check and append are one transaction, so no act carries a binding duplicate.
   Deleted: reconcile step 5.3. Execution Contract Database 2 owns it: a writer's re-read, lease check and append are one transaction, so no act carries a binding duplicate.
   Deleted: reconcile step 5.4. Execution Contract Database 2 owns it: a writer's re-read, lease check and append are one transaction, so no act carries a binding duplicate.
   Deleted: reconcile step 5.5. Execution Contract Database 2 owns it: a writer's re-read, lease check and append are one transaction, so no act carries a binding duplicate.
   Deleted: reconcile step 5.6. Execution Contract Database 2 owns it: a writer's re-read, lease check and append are one transaction, so no act carries a binding duplicate.
   Deleted: reconcile step 5.7. Execution Contract Database 2 owns it: a writer's re-read, lease check and append are one transaction, so no act carries a binding duplicate.
   reconcile step 5.8: The run MUST return the counts.
   ```

Term at risk threshold: `compensation_window − 2 × run_bound − reconciliation_cadence − clock_offset_allowance`.

Term intent age: `now − recorded_at`.

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

Term invocation report: invocations, a sequence of invocation entry; and more — what read_invocation answers.

Term invocation entry: invocation id; state; records; and more — one invocation in an invocation report.

Reads the act's invocations — each intent and whichever closing record names it — through the same rebuild, for an adopter's re-entry arm and for an auditor.

```
read invocation 1: [Read Invocation] MUST perform the rebuild under now injected at the reader's own seam.
read invocation 2: [Read Invocation] MUST return one entry per invocation id, at most read cap of the most recent, with more set to true where the act has older ones.
read invocation 3: WHEN invocation id is given:
    read invocation 3a: [Read Invocation] MUST return one entry for an invocation id a readable intent of the act key carries.
    read invocation 3b: [Read Invocation] MUST answer not-known for an invocation id no readable intent of the act key carries.
read invocation 4: records MUST carry the intent, the recovery_intended records and the closing records.
read invocation 5: [Read Invocation] MUST cap the recovery_intended records and the closing records at the most recent read cap, with more set to true beyond.
read invocation 6: [Read Invocation] MUST NOT exclude a superseded record from records.
Deleted: read invocation 7. Execution Contract Database 2 owns it: a writer's re-read, lease check and append are one transaction, so no act carries a binding duplicate.
Deleted: read invocation 8. Execution Contract Database 2 owns it: a writer's re-read, lease check and append are one transaction, so no act carries a binding duplicate.
Deleted: read invocation 9. Execution Contract Database 2 owns it: a writer's re-read, lease check and append are one transaction, so no act carries a binding duplicate.
Deleted: read invocation 9a. Execution Contract Database 2 owns it: a writer's re-read, lease check and append are one transaction, so no act carries a binding duplicate.
read invocation 10: [Read Invocation] MUST read the entry's state from the table in the section titled Which closing stands.
read invocation 11: [Read Invocation] MUST transcribe the range read's unavailable arm as journal-unavailable.
read invocation 12: [Read Invocation] MUST answer not-known for an act key with no readable intent.
read invocation 13: [Read Invocation] MUST NOT take a critical section.
read invocation 14: [Read Invocation] MUST NOT write.
read invocation 15: An adopter that decides a write on [Read Invocation]'s answer MUST decide the write under the critical section through [Open]'s pre-check.
```

### Wiring decision

*One act, one writer, one closer.*

WHY:
An irreversible act and its account are two writes no transaction spans, and closing the partial after the opening process is dead is a second writer by definition. The protocol is sound exactly when the two writers cannot both write for one act, the second cannot mistake in-flight work for a dead invocation's, and the second cannot write what it did not read — properties of the critical section, the edges and the probe, none of the adopter's act. A methodology rule does not stop twenty authors writing it twenty ways or spare the formal layer twenty models; the higher-order composition test's threshold is five exact instances and this clears it several times over ([`tools/survey/protocol_prose.py`](../tools/survey/protocol_prose.py)). What differs between adopters is the binding set; anything else is a deviation from a closed list. One page carries the protocol, one model proves it, one gate attacks it; an adopter's action shrinks to *validate, open, commit, close*.

### Bindings

An adopter binds the parameters below once per **act kind**. The instance's bindings Configuration entry is the table of bound kinds — configuration, not state.

```
Binding 1: [Reconcile] MUST read completion bound, probe, service identity, retention period and the `<kind>.*` vocabulary of every intent from the bindings table by the intent's kind.
Binding 2: The deployment MUST refuse a configuration change that unbinds a kind with an open intent.
Binding 3: The refusal Binding 2 names MUST land on compliance surface with the reason.
Binding 4: [Reconcile] step 1 MUST surface EVERY `<kind>.intended` record whose kind the bindings table does not serve and which no closing record of any kind names, once per run, on compliance surface.
Binding 5: [Reconcile] MUST NOT close an intent Binding 4 surfaces.
Binding 6: [Reconcile] MUST bound the pass Binding 4 names by the instance's longest retention period.
Binding 7: The adopter MUST declare EVERY binding in the adopter's own Composes entry for this composition.
Binding 8: The adopter MUST declare a need outside the bindings as a deviation (Edge cases, Declared deviations).
Binding 9: An adopter MUST NOT bind a kind whose database removes a record ahead of the journal's retention of the record's outcome.
```

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
  Deleted: commit 10. No adopter binds a declared commit fence, so commit fence is no binding; an adopter that needs it reopens it with a Decisions entry.
  Deleted: commit 11. No adopter binds a declared commit fence, whose conveyance it declared; an adopter that needs it reopens it with a Decisions entry.
  Deleted: commit 12. No adopter binds a declared commit fence; an adopter that needs it reopens it with a Decisions entry.
  Deleted: commit 13. No adopter binds a declared commit fence; an adopter that needs it reopens it with a Decisions entry.
  Deleted: commit 13a. No adopter binds a declared commit fence, the one kind the sweep abandoned; an adopter that needs it reopens it with a Decisions entry.
  Deleted: commit 13b. No adopter binds a declared commit fence, whose deadline the commit carried; an adopter that needs it reopens it with a Decisions entry.
  Deleted: commit 14. commit 15, Invariant 4.9 and reconcile step 3.5 own it: no adopter binds a declared commit fence, so the condition it opened held for every kind.
  Deleted: commit 14a. Invariant 4.9 owns it, for every kind.
  Deleted: commit 14b. reconcile step 3.5 owns it, for every kind.
  Deleted: commit 14c. commit 15 owns it, for every kind.
  commit 15: The adopter MUST issue the bound commit WITHIN call pause bound of [Open]'s return.
  ```

- **pairing datum**
  Term pairing datum: the field the intent record and the constituent's record both carry by construction: the seam-injected now passed into commit, an adopter-minted nonce stored by the constituent, or a constituent-minted id the database exposes by the intent's parameters.
  ```
  pairing datum 1: intent data MUST carry pairing datum.
  pairing datum 2: probe MUST match on pairing datum by equality.
  pairing datum 3: A journal join MUST NOT pair on pairing datum.
  pairing datum 4: The adopter MAY bind a seam-injected now as pairing datum ONLY IF no two serialized invocations of one act key carry the same reading on any node of the instance.
  pairing datum 5: The adopter MUST declare the obligation pairing datum 4 names where the datum is a seam-injected now.
  pairing datum 6: WHEN pairing datum EQUALS none:
      pairing datum 6a: probe MUST NOT answer committed.
  ```
  WHY: a journal join is a join between two records this composition writes; an adopter's own lookup of its intent by act key and pairing datum is the adopter's read, not a join of this page's.
- **repeatable**
  Term repeatable: `yes` or no: whether two invocations against one act key are two acts or one act attempted twice.
  ```
  repeatable 1: [Open]'s act-landed refusal MAY fire ONLY IF repeatable EQUALS no.
  repeatable 2: IF repeatable EQUALS no THEN the commit MUST refuse, on an arm the constituent declares pre-commit, EVERY call whose act key a record of the adopter's database carries.
  ```
- **probe**
  Term probe: a read of the adopter's database keyed by act key and pairing datum, answering for the sweep: did the act commit, and with what outcome.
  ```
  probe 1: probe MUST answer EXACTLY ONE OF committed(outcome action reference, outcome data), not-committed, undecidable(candidates), unavailable.
  probe 2: probe MAY answer committed ONLY IF exactly one database record matches pairing datum.
  probe 3: probe MAY answer undecidable(candidates) ONLY IF more than one record matches pairing datum OR payload match holds.
  probe 4: probe MUST map EVERY constituent read rejection to unavailable.
  probe 5: probe MUST NOT map a constituent read rejection to not-committed.
  probe 6: outcome data MUST carry only what the database re-derives.
  probe 7: WHEN the outcome's authoritative datum exists nowhere but in the dead invocation's memory:
      probe 7a: probe MUST answer undecidable.
  probe 8: probe MAY answer committed ONLY IF the matching database record carries EVERY field of act key.
  NOTE: open line 2026-10-23-b — Audit Trail declares its own Term probe, a run's first reconciliation-path record_action, so the word means two things across the seam.
  ```
  Term payload match: pairing datum EQUALS none AND at least one database record matches the intent's payload.

- **completion bound**
  Term completion bound: the longest a conforming invocation of the kind takes from [Open]'s critical section take to [Close]'s last write, including the constituent round-trip. The lease length of the critical section, the lower edge of the sweep, the first term of the liveness inequality. Read against the seam clock [Open] was injected with.
- **commit round trip**
  Term commit round trip: the longest one commit call takes from issue to reply; charged by lease spend.
- **probe round trip**
  Term probe round trip: the longest one probe call takes from issue to answer; charged by closure spend.
- **journal**
  Term journal: the Audit Trail instance the records go to, and the action reference vocabulary of the kind.
  ```
  journal 1: EVERY act kind of an instance MUST share one Audit Trail instance.
  journal 2: The vocabulary of a kind MUST declare `<kind>.intended`, the enumerated outcome refs `<kind>.<outcome>`, and `<kind>.refused`.
  journal 3: The composition MUST derive `<kind>.recovery_intended`, `<kind>.abandoned` and `<kind>.escalated` from the vocabulary.
  journal 4: The rebuild MUST classify a record as an outcome by membership in the enumerated outcome refs.
  journal 5: The adopter MUST NOT declare audit as a kind.
  journal 6: The substrate's retention policy MUST resolve EVERY `<kind>.*` record to one fixed policy reference of retention period, selected on the `<kind>` prefix of action reference and nothing else.
  journal 7: IF the substrate admits one policy reference per instance and no selector THEN kinds with different retention periods MUST run under different Recoverable Invocation instances.
  journal 8: The sweep MUST derive the upper edge from retention period.
  journal 9: The sweep MUST NOT read the upper edge from a record's own retention deadline.
  ```
- **service identity**
  Term service identity: a registered actor in the substrate's Actor Identity registry (actor reference and credential) under which the sweep writes, or none.
  ```
  service identity 1: WHEN service identity EQUALS none:
      service identity 1a: The sweep MUST NOT write.
      service identity 1b: The sweep MUST surface EVERY aged open intent on compliance surface.
  service identity 2: PROVISIONAL: Invariant 4's liveness arm DEGRADES TO surfaced under service identity EQUALS none.
  service identity 3: A writer other than the sweep MUST NOT write to the journal under the service identity.
  ```
- **outcome envelope**
  Term outcome envelope: the largest outcome payload the kind can write, sized by the adopter from the adopter's own caps, every set-valued field capped and every reference under reference length cap (Invariant 6).
- **retry terminus**
  ```
  Deleted: retry terminus 1. journal write bound 1 owns it: [Close] writes only on a remaining queried for the write that exceeds write floor.
  Deleted: retry terminus 2. journal write bound 1 owns it: [Close] writes only on a remaining queried for the write that exceeds write floor.
  Deleted: retry terminus 3. No adopter binds the counted(n) deviation, so retry terminus is no binding and the lease is every invocation's terminus; an adopter that needs it reopens it with a Decisions entry.
  ```

### Instance start

```
Instance start 1: This section IS AUTHORITATIVE FOR the conditions of instance start.
NOTE: watch addressable sections — a section title as the subject of an authority claim (Instance start 1, Allowance 2, Which closing stands 1, Invariant 2.6).
Instance start 2: The instance MUST check EVERY condition at start for EVERY bound act kind.
Instance start 3: IF any condition fails for any bound kind THEN the instance MUST NOT start.
```

Term worst closure: `completion_bound + 2 × clock_offset_allowance + 2 × reconciliation_cadence + 3 × run_bound` — completion bound the kind's, the rest the instance's, the allowance counted twice for every kind.

Term window end: `completion_bound + clock_offset_allowance + compensation_window`.

Term lease spend: `2 × read_bound + 2 × journal_write_bound + commit_round_trip + 9 × call_pause_bound`.

Term run floor: `max(completion_bound, closure_latency + journal_write_bound) + closure_latency`.

Term closure spend: `max(read_bound + 2 × journal_write_bound + probe_round_trip + 7 × call_pause_bound, 2 × read_bound + journal_write_bound + 6 × call_pause_bound)` — the sweep's closure, or [Resolve]'s work under the same lease, whichever is longer.

```
Instance start 4: The instance MAY start ONLY IF compensation window EXCEEDS worst closure.
Instance start 5: The instance MAY start ONLY IF retention period EXCEEDS window end added to run bound.
NOTE: open line 2026-10-18-a — Term window end is the examine edge plus compensation window, a completion bound and an allowance past the window's own end, and condition 2 adds run bound to it inside the rule.
Instance start 6: The instance MAY start ONLY IF completion bound EXCEEDS lease spend.
Instance start 7: run floor MUST NOT EXCEED run bound.
Instance start 8: The instance MAY start ONLY IF closure latency EXCEEDS closure spend.
```

Term conditions of instance start: condition 1 is Instance start 4; condition 2 is Instance start 5; condition 3 is Instance start 6; condition 4 is Instance start 7; condition 5 is Instance start 8; there is no sixth condition on the sweep's lease.

### Where the allowance goes

```
Allowance 1: clock offset allowance IS AUTHORITATIVE FOR every comparison in Recoverable Invocation between a reading taken at one seam and a stamp or instant minted at another.
Allowance 2: This section IS AUTHORITATIVE FOR where the allowance is spent.
NOTE: watch addressable sections (Instance start 1).
Deleted: Allowance 3. No adopter binds a declared commit fence, whose deadline was the page's one minted instant, so every cross-seam comparison takes the allowance at the reading (Allowance 4); an adopter that needs it reopens it with a Decisions entry.
Allowance 4: A cross-seam comparison MUST take the allowance at the reading.
Allowance 5: A cross-seam comparison MUST NOT decide a write.
Allowance 6: A cross-seam comparison MAY exclude a record from a pass.
Deleted: Allowance 7. No adopter binds a declared commit fence, whose deadline was the page's one minted instant; an adopter that needs it reopens it with a Decisions entry.
Deleted: Allowance 8. No adopter binds a declared commit fence, whose deadline was the page's one minted instant; an adopter that needs it reopens it with a Decisions entry.
Deleted: Allowance 9. No adopter binds a declared commit fence, whose deadline was the page's one minted instant; an adopter that needs it reopens it with a Decisions entry.
Deleted: Allowance 10. No adopter binds a declared commit fence, whose deadline was the page's one minted instant; an adopter that needs it reopens it with a Decisions entry.
Deleted: Allowance 11. No adopter binds a declared commit fence, the one kind condition 3 charged an allowance for; an adopter that needs it reopens it with a Decisions entry.
Deleted: Allowance 12. Invariant 4.9 owns it: no adopter binds a declared commit fence, so the sweep writes no abandoned record; an adopter that needs the fence reopens it with a Decisions entry.
Deleted: Allowance 13. Execution Contract Database 2 owns it: a writer's re-read, lease check and append are one transaction, and the page mints no instant for a fence on the journal.
```

Term cross-seam comparison: a comparison between a reading taken at one seam and a stamp or instant minted at another (Allowance 1).

Six clocks meet on this page: the adopter's seam ([Open] step 3), the sweep's seam ([Reconcile]), the operator's seam ([Resolve]), the reader's seam ([Read Invocation]), the substrate's recording instant, and the critical section host's expiry instant. One allowance covers every pair, set to cover the widest.

Every cross-seam comparison on this page takes the allowance at the reading: [Open] step 3's age of an open intent; the retention drop on every read of open invocations; [Resolve]'s too-young guard; the sequence high water advance; the sweep's edges and window; [Read Invocation]'s rebuild.

### Which closing stands

One act may carry more than one closing record.

```
Which closing stands 1: This section IS AUTHORITATIVE FOR which of an act's closing records is the act's.
NOTE: watch addressable sections (Instance start 1).
Which closing stands 2: A closing record MAY supersede another closing record ONLY IF the closing record names the other in supersedes.
Which closing stands 3: resolving actor MUST NOT trigger supersession.
Which closing stands 4: EVERY surface MUST read supersession transitively.
Which closing stands 5: EVERY surface MUST count the standing closing and every record reachable from the standing closing through supersedes as one closing.
Deleted: Which closing stands 6. Execution Contract Database 2 owns it: a writer's re-read, lease check and append are one transaction, so no act carries a binding duplicate.
Which closing stands 7: Among unsuperseded closings, the lowest sequence number MUST stand.
Which closing stands 8: Position MUST NOT decide against a name.
Deleted: Which closing stands 9. Execution Contract Database 2 owns it: a writer's re-read, lease check and append are one transaction, so no act carries a binding duplicate.
Deleted: Which closing stands 10. Execution Contract Database 2 owns it: a writer's re-read, lease check and append are one transaction, so no act carries a binding duplicate.
Deleted: Which closing stands 11. Execution Contract Database 2 owns it: a writer's re-read, lease check and append are one transaction, so no act carries a binding duplicate.
```

Term standing closing: the closing that stands under Which closing stands — the lowest-numbered of the closings no other closing names.

**Which state a standing closing projects.**

Term state projection: no standing closing → open; an outcome record `<kind>.<outcome>` → closed; `<kind>.refused` → refused; `<kind>.abandoned` without resolving actor → abandoned; `<kind>.abandoned` with resolving actor → resolved; `<kind>.escalated` → escalated.

An escalated entry becomes resolved when an operator's abandonment names it, and closed when any outcome names it. resolved is reserved for the case where a human's judgement is the only thing that closed an act and the act did not happen; an operator's outcome is closed. The abandoned split is the one Check 6.4 reads: only an operator abandons (Invariant 4.9), so an abandoned record carrying no resolving actor is a conformance failure, and resolving actor tells the two apart at both surfaces.

*Cited by:* [Read Invocation]'s state; Generation acceptance check 2; Invariant 2. None restates it.

---

## Composition-level invariants

- **Invariant 1 — Authentication precedes commitment.**
  ```
  Invariant 1.1: An invocation MUST NOT reach the bound commit BEFORE the substrate has validated the caller's credential for actor reference inside [Open]'s intent record.
  Invariant 1.2: invalid-credential MUST land as a pre-state refusal with nothing written.
  ```
  *Rests on:* Audit Trail's record_action and the Actor Identity attestation reached through it (Audit Trail Invariant 1); [Open] step 4 before the adopter's commit. *Defended in-line:* the ordering [Open] → commit → [Close] in every adopter; Generation acceptance check 1 makes it provable.

- **Invariant 2 — One writer per act.**
  ```
  Invariant 2.1: Two unsuperseded closing records MUST NOT name one intent's invocation id.
  Invariant 2.2: EXACTLY ONE writer MUST write the closing record, under the act's critical section.
  Invariant 2.3: Two sweep runs MUST NOT close one act.
  Deleted: Invariant 2.4. Execution Contract Database 2 owns it: a writer's re-read, lease check and append are one transaction, so Invariant 2.1 binds every deployment.
  Deleted: Invariant 2.5. Execution Contract Database 2 owns it: a writer's re-read, lease check and append are one transaction, so Invariant 2.1 binds every deployment.
  Invariant 2.6: The section titled Which closing stands IS AUTHORITATIVE FOR which closing is the act's.
  NOTE: watch addressable sections (Instance start 1).
  ```
  *Rests on:* act section (Configuration) with lease-as-terminus semantics; Execution Contract Database 2 through Capability requirement 12, under which a writer's re-read, lease check and append are one transaction; the return-based read-your-writes clause (Capability requirement 12); [Close] step 2's proceed-as-landed; [Reconcile] step 2's re-read under the critical section and sweep closed ids. *Defended in-line:* the load-bearing wiring decision; the model's rejected twins bearing on this invariant — `-buggy-reread` and `-buggy-visible`, each landing two closings for one act, and `-buggy-journal`, a take that does not refuse the write it overtakes, landing a second invocation's intent beside the first's at the main constants and an outcome beside the sweep's at nine ticks; a fourth, `-buggy-supersede`, lands two unsuperseded closings by omitting the name from a resolution over an escalation.

- **Invariant 3 — Pairing is by the seam-injected key in the journal, and by the bound datum in the database.**
  ```
  Invariant 3.1: EVERY record this composition writes for an invocation MUST carry the invocation's invocation id.
  Invariant 3.2: EVERY check and EVERY journal join MUST pair on invocation id and no other field.
  Invariant 3.3: probe MUST make the intent-to-record join on pairing datum by equality.
  Invariant 3.4: probe MUST NOT pair on a stamp within a window.
  Invariant 3.5: WHEN pairing datum EQUALS none OR pairing datum matches more than one record:
      Invariant 3.5a: The sweep MUST name candidates and write no outcome.
  ```
  *Rests on:* the seam injection (Primitive policies); Event Log Invariant 2 through Audit Trail Invariant 5 (an appended payload is immutable); the pairing datum binding.

- **Invariant 4 — Bounded closure (safety + liveness).**
  ```
  Invariant 4.1: The records MUST reveal, provably, EVERY act whose invocation has yielded or died, as an aged intent with no record naming the intent's invocation id.
  Invariant 4.2: IF the journal and the adopter's database are reachable THEN a writer MUST close EVERY aged intent by an outcome, an abandoned record or an escalation WITHIN compensation window of the intent's recording instant.
  Invariant 4.3: WHEN the journal is unreachable:
      Invariant 4.3a: A writer MUST NOT close the intent during the outage.
      Invariant 4.3b: [Open] MUST refuse the key journal-unavailable for the outage's duration.
  Invariant 4.4: [Reconcile] MUST surface a journal outage as the instance finding journal-unavailable, never as the outage's intents.
  Invariant 4.5: The outage finding MUST carry the outage's start and end.
  Invariant 4.6: IF service identity EQUALS none THEN a writer MUST report EVERY aged intent as closure-at-risk WITHIN compensation window, for an operator to close through [Resolve].
  Invariant 4.7: PROVISIONAL: Invariant 4.2 DEGRADES TO Invariant 4.6.
  Invariant 4.8: The sweep MUST escalate an act the database cannot certify as not-committed.
  Invariant 4.9: The sweep MUST NOT abandon an act.
  Deleted: Invariant 4.10. No adopter binds a declared commit fence, the one kind the sweep abandoned, so no abandoned arm degrades: Invariant 4.8 and 4.9 hold for every kind; an adopter that needs it reopens it with a Decisions entry.
  ```
  *Rests on:* [Reconcile]'s edges and steps 3–5; the kind's completion bound and retention period; the instance's clock offset allowance, reconciliation cadence, run bound, closure latency, read bound, journal write bound and compensation window; the substrate's range read.

- **Invariant 5 — Recovery is derived, never remembered.**
  ```
  Invariant 5.1: The sweep MUST NOT write an outcome BEFORE writing one or more `<kind>.recovery_intended` records naming the act and the plan.
  Invariant 5.2: EVERY outcome the sweep writes MUST carry the service identity's attestation with the original caller in acting actor reference.
  Invariant 5.3: EVERY outcome the sweep writes MUST carry only what probe re-derived from the database.
  Invariant 5.4: EVERY outcome an operator writes through [Resolve] MUST carry the operator's own attestation, the original caller in acting actor reference, and resolving actor.
  Invariant 5.5: An operator's outcome MUST NOT owe a recovery_intended.
  Deleted: Invariant 5.6. No adopter binds a declared commit fence, under which the database could say the act did not happen; an adopter that needs it reopens it with a Decisions entry.
  Deleted: Invariant 5.7. Invariant 4.9 owns it: no adopter binds a declared commit fence, so the sweep writes no abandoned record; an adopter that needs the fence reopens it with a Decisions entry.
  Invariant 5.8: An operator MAY write abandoned ONLY IF the intent is aged, as the operator's own attestation.
  Invariant 5.9: The sweep MUST escalate with candidates what the database cannot re-derive.
  Invariant 5.10: The sweep MUST NOT close an act whose database the sweep cannot read.
  ```
  *Rests on:* service identity (Bindings); Audit Trail Invariant 1 (the attesting actor is verified); [Reconcile] step 3. Generation acceptance Check 6.4 rests on Invariant 4.9, and [Resolve]'s too-young guard on Invariant 5.8: an operator's abandonment is the operator's attestation (resolve 32), not the database's word.

- **Invariant 6 — The outcome is sized before the intent.**
  ```
  Invariant 6.1: IF outcome envelope EQUALS the true maximum THEN an act MUST NOT commit with an outcome record or an `<kind>.escalated` record the substrate's payload cap could refuse.
  Invariant 6.2: [Open] MUST NOT write the intent record BEFORE sizing the outcome and the escalation against outcome envelope and intent candidates cap.
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
  Invariant 9.2: This composition MUST NOT write to the adopter's constituent records.
  Invariant 9.3: The adopter's commit partition MUST transcribe the constituent's arms as the constituent states the arms.
  ```

---

## Examples

### Walkthrough — a disclosure, three ways

The adopter is [Immutable Transaction Ledger](./immutable-transaction-ledger.md)'s `disclose_subset`, the pilot adopter, as that page binds the kind `ledger.disclosure`:

- act key = `(subject_ref, recipient, scope, authority)` — the minted-key deviation, the disclosure id being minted by the commit.
- commit = `SelectiveDisclosure.record(subject_ref, recipient, scope, authority, disclosed_at = now)`; invalid-request, `unknown-authority-type` and `storage-failure` are pre-commit as the constituent declares them; a lost reply is unknown.
- pairing datum = `disclosed_at`, the seam-injected now, carried in intent data and passed into commit. Selective Disclosure admits no nonce, so the binding declares pairing datum 4's obligation on its host — no equal now injected into two invocations of one act key, on one node or two — with Selective Disclosure's seam given the invocation's own reading (Immutable Transaction Ledger Capability requirement 28, Immutable Transaction Ledger Capability requirement 25). One way a host meets it is a per-node monotonic source whose low bits carry the node.
- probe = read Selective Disclosure's records by `subject_ref`, `recipient` and `disclosed_at` as a range of that one instant, and keep, in the adopter's code, the records whose `scope` and authority equal the intent's: `committed(ledger.disclosure.disclosed, {disclosure_id, subject_ref, recipient, scope, authority, disclosed_at})` on exactly one match, not-committed on none, `undecidable(candidates)` on several, unavailable on any read outage — the constituent's `invalid-query` is unavailable to the sweep and surfaced on compliance surface.
- `repeatable = yes`; `completion_bound = 30 s`; `commit_round_trip = 1 s`; `probe_round_trip = 1 s`; `service_identity = ledger-reconciler`.
- Instance: `reconciliation_cadence = 60 s`; `clock_offset_allowance = 2 s`; `closure_latency = 12 s`; `run_bound = 135 s` (a backlog of three orphans, sequentially, each at worst one holder's remaining lease and one closure: `3 × (30 + 12) = 126 s`, the balance headroom); `journal_write_bound = 3 s`; `read_bound = 2 s`; `call_pause_bound = 0.25 s`; `compensation_window = 10 min`.

**The five conditions of instance start, against these numbers:**

1. `30 + 2×2 + 2×60 + 3×135 = 559 s < 600 s`.
2. `30 + 2 + 600 + 135 = 767 s < retention_period` — `ledger.disclosure.*` carries a period above 767 s.
3. `30 s > 2×2 + 2×3 + 1 + 9×0.25 = 13.25 s`.
4. `135 s ≥ max(30, 12 + 3) + 12 = 42 s`.
5. `12 s > 2 + 2×3 + 1 + 7×0.25 = 10.75 s`, the sweep's closure being the longer; [Resolve]'s work is `2×2 + 3 + 6×0.25 = 8.5 s`.

The sweep's lease is `12 + 3 = 15 s`; one closure inside it spends `2 + 1 + 3 + 3 = 9 s` and seven call pauses, clearing the gate — a write floor of `3 + 3×0.25 = 3.75 s` — before both writes. The instance starts.

**The clean run.** `disclose_subset(...)` validates; [Open] takes the critical section, sizes the intent data (`disclosed_entry_ids` under the ledger's cardinality cap, which the intent alone carries) with the kind's largest record, writes `ledger.disclosure.intended` (`inv-7f2`) under the discloser's credential, and returns. `SelectiveDisclosure.record` → `dsc-411`. [Close] finds no outcome for `inv-7f2` under the critical section, writes `ledger.disclosure.disclosed` with `{invocation_id: inv-7f2, intent_event_id, disclosure_id: dsc-411, ...}`, releases, returns `landed_by = invocation`. One intent, one outcome, one writer.

**The crash.** The run dies between `SelectiveDisclosure.record` returning `dsc-411` and [Close]. The critical section stays held until its lease runs out at `t + 30 s`; the host does not see the death. Thirty-two seconds later a [Reconcile] run keeps `inv-7f2` (older than `30 + 2 s`, inside the horizon), takes the critical section, re-reads — still open — and probes: exactly one record matches → `committed(ledger.disclosure.disclosed, {disclosure_id: dsc-411, ...})`. The sweep writes `ledger.disclosure.recovery_intended` then `ledger.disclosure.disclosed` with `recovery = true, acting_actor_ref = <the discloser>`, both under `ledger-reconciler`, and releases. Accounted for within about forty-five seconds, inside the ten-minute window, by the one writer left alive.

**The stall.** The run does not die; `SelectiveDisclosure.record` is slow, past the commit round trip the deployment disclosed — outside the bounds, and what follows is what the protocol still holds there. The database applies the write at eight seconds; the adopter, unanswered past its commit round trip, has already yielded and returned `recording-failure(outcome)` (Immutable Transaction Ledger Term commit round trip), and the sweep at thirty-five probes committed and closes it. Or the database never applied the write, and probe answers not-committed — not final, since a process paused past the lease could still land the write at forty-five. The sweep writes escalated with `cause = not-observed`; the operator writes the abandonment through [Resolve] once the database has been quiet long enough. A write landing at fifty after a sweep read the database empty at thirty-five is survivable: the escalation stands, the operator's later probe finds the record, and the disposition is outcome.

**The lost reply.** `SelectiveDisclosure.record` is issued and its reply never arrives. The arm is unknown: the adopter calls [Yield] and returns `recording-failure(outcome)`. Nothing is released — the commit is a call in flight — so the critical section runs to `t + 30 s`, and a second `disclose_subset` on the same four fields meets `act-in-flight(inv-7f2)` at [Open]'s read ahead of the take, without waiting. The [Reconcile] run after `t + 32 s` probes, and closes as in the crash where the database holds the record and as in the stall where it does not.

**The refusal.** A different caller opens a disclosure and `SelectiveDisclosure.record` refuses invalid-request. The adopter partitions the arm pre-commit and calls [Refuse]; `ledger.disclosure.refused` lands with the reason; the intent is closed; the trail keeps the authenticated attempt. Nothing for the sweep.

### Rejection path — a second invocation of the same act

Two operators call `transfer_custody` for one chain within a second of each other, in an adopter whose act key is the chain. The first's [Open] takes the critical section and writes its intent. The second's [Open] reads the first's open intent ahead of the take and lands act-in-flight, or, where that intent is not yet visible, waits on the critical section and takes it after the first's [Close] releases. Called again, or at that take, its step-3 pre-check finds no open intent — the outcome read runs only for a `repeatable = no` kind, and a transfer is repeatable — so it writes its own intent and its own transfer. Had the kind been non-repeatable (a genesis), the second would have landed `act-landed(outcome_event_id)` and the adopter's `already-*` arm would have answered its caller.

### Rejection path — the caller's retry after `outcome`

A caller receives `recording-failure(outcome)`. The position says the act committed. The caller does not re-run; it calls the adopter's read (through [Read Invocation]) and finds the act open — the sweep has not yet run — then, a minute later, closed with `recovery = true`. A caller that re-ran would have found `act-in-flight(invocation_id)` at [Open], the open intent being younger than the bound plus the allowance — and after the sweep, an act-landed refusal where the act is non-repeatable, or a second act where it is: the second act is the caller's decision, made with the position in hand.

### Regulated adversarial scenarios

**Regulator audit — "show me that every consequential act you took is accounted for."** The auditor enumerates the journal's `<kind>.intended` records inside the horizon and older than the bound, and for each finds exactly one closing record naming its invocation id — not since superseded, an abandoned carrying a later outcome with `supersedes` being the corrected-false-abandonment shape check 6 reads; recovery_intended records are not closings and may be several — within compensation window of its recording instant, under the allowance (checks 2 and 3). An intent with no closing record is younger than the bound (in flight) or a conformance failure surfaced on compliance surface, and the auditor can tell which from the stamps alone.

**Disputed act — "I never authorized that disclosure."** The outcome names invocation id; the intent record with that id is attested under the disputant's credential, verified by Actor Identity before the database committed (Invariant 1), and sealed (Audit Trail Invariant 3). If the outcome carries `recovery = true` and no resolving actor, the sweep wrote it — under `ledger-reconciler`, behind a recovery_intended record — and acting actor reference still names the disputant. The structural rebuttal is the intent, not the outcome; the sweep changes who attests the outcome, never who attested the intent.

**Breach investigation — "the reconciler's credential was compromised; what could it have written?"** Every record under the service identity is a closing record naming an invocation id whose intent stands under a human's credential; a service-identity record with no such intent is a write outside this composition (check 5), and an outcome the database does not corroborate is one the sweep could not have derived (check 6). The compromised identity could close acts, never open them, and close only acts whose intents exist — the intent record is the control the service identity cannot forge.

---

## Generation acceptance

A derived implementation of Recoverable Invocation is acceptable when the following are provable to an auditor given the journal and the adopter's constituent records.

### Conformance checks

```
Check 1.1: EVERY outcome record whose intent is inside the horizon MUST follow, in the journal's sequence, an intent record with the same invocation id attested under the actor the outcome names — the outcome's own actor reference where recovery is absent, the outcome's acting actor reference where recovery EQUALS true.
Check 1.2: An auditor MUST decide inside the horizon by read_record(intent event id) answering Retained.
Check 1.3: An auditor MUST NOT decide inside the horizon by arithmetic on the outcome's stamp or by the presence of an answer.
Check 1.4: An auditor MUST answer purged, never absent, for an outcome whose intent the substrate reports Purged.
Check 2.1: For EVERY aged intent inside the horizon, two unsuperseded closing records of any of the four kinds MUST NOT name the intent's invocation id at quiescence.
Check 2.2: For EVERY aged intent inside the horizon, two `<kind>.intended` records MUST NOT carry the intent's invocation id.
Check 2.3: Two intents MUST NOT stand open on one (kind, act key) at any reading inside the horizon, for a kind whose service identity DOES NOT EQUAL none.
Check 2.4: An auditor MUST read supersession transitively PER the section titled Which closing stands and count the reachable set as one closing.
Check 2.5: An auditor MUST read EVERY outcome as EXACTLY ONE OF the three outcome shapes.
Check 2.6: An auditor MUST report an outcome matching no outcome shape as a conformance failure.
Check 3.1: For EVERY aged intent inside the horizon, a closing record MUST land WITHIN compensation window of the intent's recording instant, the auditor's reading tolerating clock offset allowance across seams.
Check 3.2: An auditor MUST exempt an intent of a kind the bindings table no longer serves.
Check 3.3: An auditor MUST exempt an intent whose window overlaps any span of journal-unavailable, or of store-unavailable for the intent's kind.
Check 3.4: An auditor MUST NOT exempt an intent for the healthy gap between two spans.
Check 3.5: IF service identity EQUALS none THEN the register MUST carry EVERY aged intent as a closure-at-risk act finding WITHIN compensation window.
Check 4.1: An auditor MUST confirm all five conditions of instance start, as the section titled Instance start states the conditions, for EVERY bound act kind from the kind's completion bound, commit round trip, probe round trip and retention period, and the instance's clock offset allowance, reconciliation cadence, run bound, closure latency, read bound, journal write bound, call pause bound and compensation window.
Check 5.1: EVERY record the service identity attests whose named intent is inside the horizon MUST name an invocation id whose intent record exists and is attested by a different actor.
Check 5.2: An auditor MUST report a service-identity record naming no readable intent inside the horizon as a write outside this composition.
Check 5.3: An auditor MUST answer purged for a service-identity record whose intent is Purged.
Check 6.1: For EVERY outcome whose recovery EQUALS true, probe run by the auditor against the constituent records MUST corroborate outcome data or answer unavailable, an outcome carrying a resolving actor also passing where probe answers undecidable with outcome data among the candidates.
Check 6.2: An auditor MUST read unavailable as not applicable, never as failed.
Deleted: Check 6.3. Check 6.4 owns it: no adopter binds a declared commit fence, the one kind the sweep abandoned, so no abandoned record carrying no resolving actor conforms; an adopter that needs the fence reopens it with a Decisions entry.
Check 6.4: EVERY `<kind>.abandoned` MUST carry a resolving actor.
Check 6.5: EVERY database candidates entry of an `<kind>.escalated` record MUST match a database record of the intent.
Check 7.1: An auditor MUST exclude an intent the substrate reports Purged from every check.
Check 7.2: An auditor MUST quantify Check 1, Check 2 and Check 3 over intents whose payload is readable.
Check 7.3: An auditor MUST exclude from Check 2 and Check 3 an intent whose horizon edge PRECEDES the auditor's now.
Check 8.1: An auditor MUST clear Audit Trail's eight traversal checks over the journal instance.
```

Term outcome shape: recovery absent with actor reference set to the intent's actor reference; recovery set to true with resolving actor, actor reference set to resolving actor, no recovery_intended owed; recovery set to true without resolving actor, actor reference set to the service identity, preceded by one or more `<kind>.recovery_intended` naming the same invocation id.

Term invariant map: Invariant 1 → Check 1; Invariants 2 and 5 → Check 2; Invariant 4 → Check 3 and Check 4 (conditions 1, 4, 5; with Invariant 7 for condition 2); Invariant 5 → Check 5 and Check 6; Invariant 7 → Check 7.

### External checks

```
External check 1: An auditor MUST clear from external evidence that a declared outage of the journal or the adopter's database was surfaced on compliance surface with the outage's start and end, and that every intent whose window overlapped the outage was closed once the outage ended.
External check 2: An auditor MUST clear from external evidence that act section is shared across every node of the instance and implemented as a lease of the declared length.
External check 3: An auditor MUST clear from external evidence that closure latency, completion bound, read bound, call pause bound and run bound were set from observed worst cases with headroom, run bound over the largest backlog the deployment sizes for.
External check 4: An auditor MUST clear from external evidence that the adopter's probe reads the database the act was made in.
External check 5: WHEN service identity EQUALS none:
    External check 5a: An auditor MUST clear from external evidence that the surfaced intents were acted on through [Resolve].
Deleted: External check 6. No adopter binds a declared commit fence, which the database had to honour; an adopter that needs it reopens it with a Decisions entry.
External check 7: An auditor MUST clear from external evidence that each adopter's outcome envelope is the true maximum of the records the kind writes.
External check 8: An auditor MUST clear from external evidence that no writer other than this composition's actions uses an adopter's journal vocabulary.
```

---

## Non-goals

```
Non-goal 1: An adopter MUST NOT describe [Open], then the commit, then [Close] as atomic.
Non-goal 2: This composition MUST NOT offer a rollback.
Non-goal 3: This composition MUST NOT add to the substrate's contract.
Non-goal 4: The adopter MUST own the `already-*` re-entry arm, informed by [Read Invocation].
Non-goal 5: A deployment whose regulator requires the account to outlive the act's own retention MUST set the journal's retention policy accordingly.
Non-goal 6: This composition MUST NOT govern the lifecycle of the adopter's constituent records.
```

NOTE: the owners — a Transaction pattern *(forthcoming)* (Non-goal 1, Non-goal 2); [Audit Trail](./audit-trail.md) (Non-goal 3).

### What the sweep never does

```
Sweep never 1: The sweep MUST NOT run adopter code other than probe.
Sweep never 2: The sweep MUST NOT write under a human's credential.
Sweep never 3: The sweep MUST NOT read the adopter's database other than through probe.
```

## Edge cases

### Clock semantics

```
Clock semantics 3: The composition MUST NOT time the lease.
Deleted: Clock semantics 2. Composes 1 owns it.
Deleted: Clock semantics 1. Execution Contract Logic confinement 3 owns it.
```

### Cross-record consistency under partial failure

The reachable partials and their closers. *Crash after [Open], before the commit:* intent open, database untouched; probe answers not-committed; the sweep writes `<kind>.escalated`, and an operator who finds the database quiet abandons the act through [Resolve]. *Crash after the commit, before [Close]:* probe answers committed; the sweep writes the outcome under `recovery = true`. *Crash inside [Close] after the outcome landed and before the map update:* the map is a rebuild trigger, not a partial. *A stalled invocation past its lease:* it writes nothing; the sweep closes; the late [Close] returns recording-failure(outcome). *A refusal record that failed:* the intent stands, probe answers not-committed, and the sweep escalates it. *An outcome the database cannot corroborate:* undecidable, escalated with candidates, never chosen. There is no sixth partial; a deployment that finds one has a critical section that is not a critical section.

### Declared deviations

```
Deviation 1: An adopter MUST declare a deviation as EXACTLY ONE OF: minted key; journal without attribution.
Deviation 2: An adopter MUST record a need outside Deviation 1 first, as a finding against the adopter or as evidence for the next revision of this page.
Deleted: Deviation 3. No adopter binds the counted(n) deviation; an adopter that needs it reopens it with a Decisions entry.
Deleted: Deviation 3a. No adopter binds the counted(n) deviation; an adopter that needs it reopens it with a Decisions entry.
Deleted: Deviation 3b. No adopter binds the counted(n) deviation; an adopter that needs it reopens it with a Decisions entry.
Deleted: Deviation 3c. No adopter binds the counted(n) deviation; an adopter that needs it reopens it with a Decisions entry.
Deviation 4: WHEN the act's key is minted by the commit:
    Deviation 4a: The adopter MUST bind the key the adopter can name before the commit.
    Deviation 4b: The adopter MUST declare the probe that finds the minted record from the bound key.
    Deviation 4c: IF no such read of the constituent EXISTS THEN the adopter MUST declare probe set to undecidable for the kind.
Deviation 5: An adopter journaling to a bare Event Log MUST declare that the adopter is not an adopter of this page.
```

### Repeatable and non-repeatable acts

The adopter's declaration; [Open]'s act-landed refusal fires only for `repeatable = no`. The composition does not guess. A second attempt of a non-repeatable act meets [Open]'s act-landed where act closings holds the act's outcome, and the commit's own refusal wherever the adopter's database holds the act (repeatable 2): past the horizon, which destroys the outcome's payload, and under an escalation over an act that committed.

---

## Terms

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is* and its **Kind**. The substrate's rejections (invalid-credential, invalid-request, `recording-failure(step)`) are the substrate's cards.

### Vocabulary

Term actors: invocation; sweep run (also: the sweep, the run); operator; adopter's action (also: the adopter, the action); caller; deployment; auditor; substrate; critical section host (also: the host); writer — EXACTLY ONE OF invocation, sweep run, operator; reader; register (the deployment's findings surface); surface — [Read Invocation] or Generation acceptance check 2.

Term records: `<kind>.intended`, `<kind>.<outcome>`, `<kind>.refused`, `<kind>.recovery_intended`, `<kind>.abandoned`, `<kind>.escalated`, [Finding].

Term record verbs: write, read, read back, take, release, hold, yield, adopt, retry, refuse, return, surface, count, probe, close, examine, keep, drop, name, carry, size, validate, land, supersede, rebuild, populate, clear, discard, report, proceed, wait, persist, start, derive, sample, declare, bind, treat, transcribe, issue, mint, reach, reveal, escalate, abandon, open, advance, set, move, admit, exclude, stand, serialize, time, query, run, pass, decide, pair, share, stay, sum, rely, trigger, exist, answer, call, follow, re-read, leave, supply, perform, exempt, bound, block, use, re-run, match, map, make, export, classify, choose, cap, vary, update, touch, suppress, stamp, retain, resolve, remove, reject, recover, record, re-take, partition, own, owe, omit, offer, know, inspect, govern, free, fire, end, describe, corroborate, confirm, compare, collapse, check, charge, change, belong, add, commit, append, quantify.

Term cited: take, try_take, remaining, expiry instant, call in flight, no answer: Lease. record_action, read_record, payload cap, reference length cap, attestation id width, retention policy, recording instant, sequence number, next sequence number, event id, action reference, policy reference, retention deadline: Audit Trail.

Term value sets: landing actor = invocation | sweep | operator. state = open | closed | refused | abandoned | escalated | resolved. disposition = outcome | abandoned | escalated. probe answers committed | not-committed | undecidable | unavailable. commit partition = pre-commit | committed | unknown. repeatable = yes | no. service identity = an actor | none. findings = journal-unavailable | store-unavailable | closure-at-risk | unbound-kind | escalated. [Resolve]'s invalid-request causes = purged | malformed | too-young | already-abandoned | candidates-over-cap.

Term position: intent | outcome | refusal | resolution — the record a write lands: the intent at [Open], the outcome at [Close] or after [Yield], the refusal at [Refuse], the resolution at [Resolve].

Term intent payload: intent data with invocation id, kind and act key added.

Term outcome payload: outcome data with invocation id, intent event id, kind and act key added.

Term recovered outcome payload: the outcome payload with recovery set to true and acting actor reference set to the intent's actor reference added.

Term acting actor reference: the original caller's actor reference, carried by an outcome the sweep or an operator writes (Invariant 5.2, Invariant 5.4).

Term resolving actor: the operator's actor reference, carried by a closing record an operator writes through [Resolve] (resolve 21).

Term recovery_intended: a `<kind>.recovery_intended` record — the sweep's statement of an act and its plan, written before the outcome it names (Invariant 5.1).

Term database candidates: the records in the database an `<kind>.escalated` record names as possibly the intent's, at most intent candidates cap of them (reconcile step 3.8a).

Term run id: a sweep run's own seam-injected id, fresh for every run; with the examined intent's invocation id, the critical section holder for one take.

Term true maximum: the largest record a kind writes, as External check 7 clears.

Term cause: not-committed | not-observed | undecidable | outcome-unrecordable — the closing record's escalation or abandonment cause.

Term external evidence: evidence outside the records — documentation, configuration, the deployment's own logs.

Term bounds: completion bound, commit round trip, probe round trip, journal write bound, call pause bound, read bound, closure latency, run bound, compensation window, clock offset allowance, retention period, intent candidates cap, read cap.

Term cadences: reconciliation cadence.

Term qualifiers: migrated — rewritten in GRACE lang v0.35 (2026-09-11).

Term terms: (named expressions, each declared where it is used) worst closure, window end, lease spend, run floor, closure spend, examine edge, horizon edge, at risk threshold, intent age, settle bound, retention end, sweep lease, in-flight, aged, partition, examined, skipped, reported, surfaced, unreached, closed already, standing closing, terminus, caller kind, payload match, quiescence, read path, read-your-writes, `position's existing arm`, cross-seam comparison, critical section key, critical section holder, critical section duration, reply, release, hard alert, unfenced write, write floor, commit floor, act finding, instance finding, act key, invocation id, now, operator run id, resolve refusal, open result, close result, reconcile tally, invocation report, invocation entry, first seen, last seen, acting actor reference, resolving actor, recovery_intended, database candidates.

#### Open

The action an adopter's action calls before the bound commit: takes the act's critical section, sizes the outcome and the escalation against the substrate's cap, refuses an act already in flight or already landed, and writes the intent record under the caller's credential. Returns `{invocation_id, intent_event_id}` with the critical section held; it first takes the reading the commit goes out behind, and returns `recording-failure(outcome)` where that reading does not cover the commit.

Kind: Operation

#### Close

The action an adopter's action calls after the bound commit returned: under the critical section, adopts an outcome the sweep already landed for the invocation or writes the outcome record, then releases. Returns landing actor; returns `recording-failure(outcome)` where the lease expired or the record could not land.

Kind: Operation

#### Refuse

The action an adopter's action calls when the bound commit refused on a pre-commit arm: writes the refusal record naming the intent, so the authenticated attempt is kept and the intent does not stand open, and releases the critical section.

Kind: Operation

#### Reconcile

The sweep, the composition's second writer: at restart and on cadence, examines open intents between the completion bound and the horizon, takes each act's critical section, probes the database, and closes each act with a re-derived outcome or an escalation — under the service identity behind a recovery-intended record, or as a report only where none is declared.

Kind: Operation

#### Yield

What an adopter's action calls on the unknown partition: nothing is written and the intent stays open for the sweep; the critical section is released where the commit answered, and left to end at its instant where the commit's reply was lost.

Kind: Operation

#### Resolve

The human-attested close: an operator, present with an own credential, closes an open intent the sweep cannot — under a report-only deployment, or after investigating an escalation — supplying the disposition the operator's own run of probe supports; the record carries `recovery = true` and resolving actor.

Kind: Operation

#### Read Invocation

The composition's read: the act's invocations, each with records and state, for an adopter's re-entry arm and for an auditor. Takes no critical section, writes nothing.

Kind: Operation

#### Recording Failure

The positioned failure code `recording-failure(intent | outcome | refusal | resolution)`; refusal carries a second slot for the constituent's pre-commit code. intent: nothing committed, retry the action. outcome: the intent stands, and the act exists, may exist, or was withheld for want of lease; never re-run; the sweep or an operator writes the record. refusal: the intent stays open; the sweep or an operator closes it. resolution: nothing appended — like section-unavailable, an arm on which [Resolve] may be called again.

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

[Open]'s and [Resolve]'s refusal where the act's critical section could not be taken within the current holder's remaining lease, or was held with too little of the lease left to write (open step 3.12, open step 4.2, resolve 7); nothing is written and the call may be retried.

Kind:       Member
Member of:  the open rejections and the resolve rejections
Role:       Rejection
Projection: section_unavailable

#### Not Open

[Close]'s precondition (close 4) and [Refuse]'s step 0, and theirs alone: an invocation id and intent event id pair the adopter's action did not receive from its own [Open]. An adopter's programming error, not a protocol state; nothing is written. It is the adopter's action that decides it and no action of this page returns it, so neither signature lists it.

```
Not Open 1: The composition MUST NOT decide not-open.
Not Open 2: The adopter's action MUST hold [Open]'s returned pair on the action's own call stack for the life of the invocation.
Not Open 3: The composition MUST NOT decide not-open from a map or a range read.
Not Open 4: [Close] MUST land recording-failure(outcome) at step 1 for a pair no [Open] returned.
Not Open 5: [Refuse] MUST land recording-failure(refusal, constituent code) at step 1 for a pair no [Open] returned.
```

#### Not Known

The read's answer for an act with no readable intent at all, at [Read Invocation] and at [Resolve]; for an invocation id no readable intent of the act carries, at [Read Invocation]; and for an intent event id naming no intent of the act that carries the invocation id, at [Resolve] (resolve 34). Absence, not destruction: a lawfully purged intent is answered `invalid-request(purged)` at [Resolve], which takes intent event id for exactly that reason. [Read Invocation] is the one surface that cannot make the distinction and says so.

Kind:       Member
Member of:  the read rejections and the resolve rejections
Role:       Rejection
Projection: not_known

#### Finding

A record in the instance's findings register (*Composition state* owns the contract). An act finding names one act the run could not close and carries no span; an instance finding names a condition of the instance, or of one bound kind, and carries one.

Kind:       Type
Role:       the surfaced record
Projection: finding

#### Journal Unavailable

The read-path outage code at [Open] step 1 and step 3, [Reconcile] step 1 and [Read Invocation]: nothing was written, retry. A read's failure, never a write's. [Close], [Refuse] and [Resolve] do not carry it — by the time they read, the act's existence is decided, so their read failures land on their position's recording-failure arm.

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

[Open]'s refusal for a non-repeatable act whose outcome act closings holds; carries the outcome event id. The adopter's own re-entry arm answers the caller. Where act closings holds none for an act the adopter's database holds — its outcome's payload destroyed at the horizon, or an escalation standing — the commit's own refusal answers instead (repeatable 2).

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
[Journal Unavailable]: #journal-unavailable
[Already Accounted]: #already-accounted

---

## Standards references

The composition anchors the accountability every regulated adopter's regime requires of a consequential act: an attributable record of intent before the act, a record of outcome after it, and a bounded, attributable account of any act the process failed to record — SOX section 404 (Sarbanes-Oxley Act — internal controls over financial reporting), HIPAA section 164.312(b) (Health Insurance Portability and Accountability Act — audit controls), PCI DSS Requirement 10 (Payment Card Industry Data Security Standard — logging and monitoring), 21 CFR (Code of Federal Regulations) Part 11 (electronic records and signatures), and GDPR (General Data Protection Regulation) Article 30 and Article 32 (records of processing; integrity of processing). Each adopter's own section names the regime its act falls under; this composition supplies the form the regime's *accountability* clause requires and no substantive judgment about the act.

---

## Status

`draft` — see the Ledger.

## Ledger

```
status: draft
formal: verified — recoverable-invocation.tla (v7) + 6 twins + 16 probes and isolations, and v7's own runs (23,962 states **at a horizon of five ticks**, which is the whole of the claim: the four-phase [Open] costs about a factor of ten in states per tick and does not finish at six or seven, so "all invariants hold" here means *holds within five ticks at these constants* and no monotonicity argument is offered for more. **The twin suite does not show that five is enough, and this line said it did:** five of the six twin files are full copies of v4 at their own constants — seven ticks — which carry v4's journal fence as a constant set TRUE, none of their defects turning on it, and each is rejected on the invariant its header names; the sixth, `-buggy-journal`, is the v7 module with its one constant flipped; run instead as configurations of the v7 module at the main constants, two of the three that are one constant's flip are rejected (`VisibleOnReturn`, 19,069 states; `SupersedesNamed`, 20,759) and one holds (`OperatorSkew` under a report-only deployment, 29,826, whose race needs the release at [Yield] that v6 removed), the two structural twins having no constant to flip. **v6 (2026-10-07)** carries the invocation's lost-reply path as Lease has it: `HoldUnanswered` — no release while a commit is in flight or once a write's reply is lost; flipped with the operator's reading one tick ahead it is what lets a false abandonment land (Invariant 5 violated at 4,510 states under v7, holding at 29,826 with the hold), so the hold is a second defence against the operator's clock and no twin file is added for it. **v7 (2026-10-20)** takes the journal fence out under the maintainer's ruling of that day: a take refuses every journal write it overtakes (`TakeRefuses`), a writer's re-read, lease check and append being one transaction (Execution Contract Store 2 through Capability requirement 12), and no lost-reply write is issued twice; with the refusal off (`-buggy-journal`) a second invocation's intent lands beside the first's (1,431 states), and at a nine-tick horizon with pauses and deaths off an invocation's outcome lands after the sweep's take, beside the sweep's (Invariant 2 violated at 23,321 states, holding at 25,286 with the refusal); with the intent write ungated it holds (27,045), so the refusal, not the lease gate, keeps a second intent off the first's; a host that releases on death holds as well (27,500), and `-buggy-death`, `-buggy-skew`, `-buggy-perwrite` and the six intent files that weighed the fence against the gate are retired. The window has its own configurations; Invariants 1, 2, 4, 5 as safety over discrete time; six components over one act — the invocation, a section host with lease-as-terminus, a fenced-or-fenceless store, a journal whose writes return and become visible at separate instants and which refuses a write another holder's take overtakes, two sweep runs on two nodes with a blocking take, **an operator through [Resolve] as the third writer, taking the same section on its own seam reading and re-arming for a second call**, **[Open] split into take → read → gate → issue → return with the intent write carrying its own return and visibility instants**, a death budget and a pause budget; `service_identity` is a modelled dimension, so the sweep's writes and the operator's open-intent arm are gated by it; every journal write split into its gate and its issue, and carrying separate return and visibility instants; twins rejected — `-buggy-reread`, sweep skips the re-read under the section → Invariant 2; `-buggy-fence`, sweep abandons a fenceless act → Invariant 5; `-buggy-journal`, a take that does not refuse the write it overtakes → Invariants 7 and 8; `-buggy-visible`, visibility only time-bounded → Invariant 2; `-buggy-supersede`, a resolution over an escalation carrying `resolved_by` and no `supersedes` → Invariants 2 and 6 (gate 9, F6); `-buggy-opclock`, the operator's reading one tick ahead in a report-only deployment → Invariant 5 (gate 9, F7), against `recoverable-invocation-probe-reportonly-clean` which differs by that one constant and HOLDS; **Invariant 8 — an intent is never in flight under another holder's grant — is earned by the store's refusal and not by the lease gate: with the refusal off it is violated, and with the gate off it holds (gate 10, F6; the journal fence earned it until v7)**; established — the dead-run term inside the model's own frame is the sweep's own lease and not a second `completion_bound` (true of a world with one act in it; the page's inequality carries `run_bound` terms instead, which the model has no backlog to express — Configuration §`compensation_window`), the `remaining` gate is not what carries Invariant 2 (the store's refusal is), the lower edge not safety-bearing at zero skew; Invariant 4 is vacuous at the main constants and is checked in the window configurations instead; **reachability probes — `Probe_OperatorNeverHoldsSection`, `Probe_OperatorNeverWrites`, `Probe_OperatorNeverSupersedes` and `Probe_NeverASupersessionChain`, each a deliberate falsehood the checker rejects**, the last of them only after it had held twice and named two things that were off which the configuration did not say were off, so the operator's invariants are not vacuous the way Invariant 4 once was; not modeled — pairing, purge, the refusal path, `recovery_intended`, the bindings table's lifecycle and with it the `kind` half of the key, the rejection-code taxonomy, the derived indexes, the compliance surface, the sweep's own lost-reply read-back, the call pause bound and the sizing bound from Lease with the reading ahead of the commit (the model's gates compare against `JournalWriteBound` alone and its commit goes ungated, the wider behaviour), [Open]'s read ahead of the take (the model's second opener always takes, the wider behaviour), and **which record a supersession names**: the model counts supersessions and does not identify them, so a chain (an escalation superseded by an abandonment superseded by an outcome) and a double-naming of one record are the same state to it — the transitivity rule below is therefore a prose repair and is **not** model-confirmed), 2026-10-20
last gate: 2026-10-24 — Final Critique 19 — foundational count 2, not clean, no sample

open:
- 2026-09-10-a · refining · Composition state, `findings` · the register carries truth no constituent's records replay, and it is classified extraction-pending with no atom yet owning it, so this page owns a durability contract that belongs to one → land the **Condition Register** atom, a durable register of named conditions each opening at a first sighting, advancing at every later one and ceasing when a pass no longer sees it; until it lands the contract in Composition state is the declaration and the debt is flagged rather than normalized; Audit Trail classifies its outage record against the same atom and bars modifying an entry once written (its outage record 1 and 2), where this page's findings advance last seen, close and reopen (findings 9 through 11), so the atom must hold both shapes or one page reclassify (Final Critique 18)
- 2026-10-07-e · refining · formal · five of the six twins are copies of v4, carrying v4's journal fence as a constant set TRUE, and against the v7 module at its own constants one of the three that are one constant's flip holds: the operator-clock race needs the release at [Yield] that act section 15 removed, so no run shows resolve 19 load-bearing on the page as it stands → re-derive the twins as configurations of the current module, each at the shortest horizon that reaches it, and name the rules a second defence now covers
- 2026-10-07-g · refining · resolve 12 · a purged intent refuses resolution, so any adopter's escalation is stranded at its intent's horizon, and only the pilot adopter obliges an operator to settle ahead of it → own the deadline here
- 2026-10-07-l · refining · resolve 9; Check 6.1 · an operator's outcome carrying a wrong datum is permanent: the check detects it and no action repairs it → a correcting resolution
- 2026-10-09-a · refining · Term quiescence · whether quiescence is per act or per instance is unstated, and an instance-wide reading leaves every check that waits on it empty on a busy instance → scope it per act
- 2026-10-09-b · refining · Term act key · two invocations of one key are called one act, which repeatable set to yes denies → say the key names one act only where repeatable is no
- 2026-10-09-c · refining · open step 2.2; reconcile step 2.2; resolve 5 · a waiter's bound is the current holder's remaining lease, which no waiter can read (Lease Invariant 5.1) → bound the wait by what the waiter can read
- 2026-10-09-d · refining · Primitive policy 5; Invariant 3.2 · invocation id and no other field, against Check 1.2's and an adopter's read of the intent by the intent event id a record carries → say a read by a carried event id is a lookup, not a join
- 2026-10-18-a · refining · Term window end; Instance start 5 · window end is the examine edge plus compensation window, a completion bound and an allowance later than the end of the window Term compensation window measures from the recording instant, and Instance start 5 adds run bound to window end inside the rule, arithmetic a rule does not carry (GRACE-lang Hard invariant 24, Closed vocabulary 9) → name the term for the instant it is, or measure condition 2 from the window's own end and state its margin, and declare the sum condition 2 compares as a term
- 2026-10-18-b · refining · Binding 3; reconcile step 3.18; open step 3.8c · a refused unbind, a refused service credential and a report-only deployment's old intent are surfaced on compliance surface and are neither one of the six findings nor a hard alert → say what record each is
- 2026-10-18-c · refining · Capability requirement 2; Term open-upper-bound sequence-range read · the range read is asked for a cursor, a declared page size and a page-complete signal that Event Log's read (Operation 13, 18) and Audit Trail's pass-through (Action wiring 1, 5) do not declare and no rule here reads, and the Term calls the pass-through list-shaped → state the paging as the deployment's query shape with the re-reads reading to the signal, or drop it
- 2026-10-18-e · refining · findings 1 · an unbound-kind finding names a kind the bindings table no longer serves, which has no retention period, so its persistence is sized by nothing → size it by the instance's longest retention period, as findings 2 sizes a finding naming no kind
- 2026-10-18-f · refining · open step 5 · open step 5.2 returns ahead of open step 5.4's reading, which is the last call [Open] makes, and of open step 5.6's arm, and open step 5.3 holds the critical section at every return, the return after open step 5.5's release included → order step 5 as [Open] runs it
- 2026-10-18-h · refining · Terms · kind, the first input of every action but [Reconcile] (act section 4) and the key of the bindings table, has no declaration (Closed vocabulary 4) → declare it
- 2026-10-18-k · refining · Term invariant map · the map names Invariants 1, 2, 4, 5 and 7 and leaves out 3, 6, 8 and 9, and Check 8 reads an invariant the map does not name → map each invariant to the check that reads it, or say that none does
- 2026-10-18-n · refining · close step 1.2; close step 2.4; refuse step 1.2 · each returns with nothing written and no release, where [Open]'s early arms release (open step 3.4, 3.6, 4.2a, 4.5) → say whether the invocation releases there or lets the grant end at its instant
- 2026-10-18-o · refining · Primitive policy 32; journal write bound · no rule says when a record_action's reply counts as lost, which yield 7 says only of the bound commit → say when a journal write's reply is lost
- 2026-10-18-p · refining · Binding 1 · Binding 1 has [Reconcile] read the per-kind bindings from the bindings table by the intent's kind and names no other action, while [Open], [Close] and [Resolve] read completion bound, service identity or the kind's outcome refs by kind as well (open step 2.1, open step 3.6, close 6, resolve 18, resolve 31) → say every action reads its kind's bindings from the table by the kind it takes
- 2026-10-18-t · refining · call pause bound 1; act section 19 · the page restates Lease Capability requirement 7 for lease calls alone, leaving out the unfenced write it issues (the bound commit) and the atom's exception for a blocking take, which open step 2.2, reconcile step 2.2 and resolve 5 let wait → restate the requirement whole for the page's calls and unfenced writes, its exception included, keeping the issue of a journal write the part call pause bound bounds
- 2026-10-18-u · refining · reconcile step 3.18; reconcile step 3.19; Invariant 4.2 · while the service identity's credential stays refused the sweep writes nothing, and no rule says who closes the kind's aged intents within compensation window, which Invariant 4.2 still obliges of a writer; the run counts the rest of its intents unreached, which reconcile step 5.1 does not surface as closure-at-risk, and no external check clears the surfacing reconcile step 3.18 obliges → name the operator's [Resolve] as the closer while the credential is refused, surface what the operator must close, and clear the surfacing
- 2026-10-18-v · refining · Invariant 4.2; Invariant 4.7; service identity 2 · the degradation of Invariant 4.2 to Invariant 4.6 under service identity none is a PROVISIONAL line, which carries no normative force (GRACE-lang Surface 14), and Invariant 4.2 carries no condition on service identity, so Invariant 4.2 and Check 3.1 still oblige a report-only deployment's operators to close every aged intent within compensation window → condition Invariant 4.2 and Check 3.1 on a declared service identity, as Check 3.5 is conditioned on none, or say that the window binds the operators
- 2026-10-19-a · refining · Term lease spend; Term closure spend; act section 16; Term critical section duration · lease spend and closure spend charge no lost reply's wait and read-back (Primitive policy 34, Primitive policy 35, reconcile step 3.16), while act section 16 binds them as Lease's work's bounds, the bound on all the work under one lease (Lease Term work's bound); every write past the overrun still passes its gate (open step 5.4 through 5.6, close step 3.5, journal write bound 1) → charge the wait and the read-back, or say the work's bound is the path with no lost reply and what a lost reply costs past it
- 2026-10-19-b · refining · reconcile step 2.1; Term unreached; reconcile step 3.19 · the exception reads, with Term unreached, as the run's stop at its first refused write under a service identity, and reconcile step 3.19 forbids writes under the refused credential alone, so where two kinds bind different service identities one build leaves the second kind's intents unreached and another closes them → say whether the exception reaches an intent whose kind binds another service identity
- 2026-10-23-b · refining · Term probe; probe 1 through 8 · Audit Trail declares Term probe, a run's first reconciliation-path record_action (Audit Trail Invariant 1.10), and this page its own Term probe, a read of the adopter's database: two meanings for one word across the seam (GRACE-lang Closed vocabulary 17) → rename one; a council commit of this page cannot change Audit Trail
```

## Decisions

Directional changes only. Everything smaller lives in the commit that made it: `git log -- compositions/recoverable-invocation.md`; the rounds, the binding, the model runs and the migration that got it here, and the twelfth gate's consolidations, are in [its history](./recoverable-invocation.hist.md).

- **2026-10-24 — The branches no adopter binds are cut, and a closure table owns every input and arm.** *Chose:* under the maintainer's ruling of 2026-10-23 20:13Z, direction (b) and then (c) of the 16:51Z escalation, the declared commit fence branch and the counted(n) deviation deleted, since both adopters, Immutable Transaction Ledger and Verified Repair, bind commit fence none and retry terminus lease, each tombstone saying no adopter binds it and an adopter that needs it reopens it with a Decisions entry: the minted deadline and its return (open step 5.7, 5.8), the commit's conveyance and the sweep's abandonment (commit 10 through 13b; reconcile step 3.4, 3.6 and 3.14; Invariant 4.10, 5.6 and 5.7; Check 6.3; External check 6), the minted instant's allowance rules and payments (Allowance 3 and 7 through 12) with Term commit fence deadline, Term abandon edge and Term usable term, and the count (close step 1.3, 3.6; Deviation 3); commit fence and retry terminus no longer bindings, so what held under none holds for every kind (open step 5.4 through 5.6, reconcile step 3.5, Invariant 4.8 and 4.9, commit 15 for commit 14c, resolve 32 for resolve 20a), the sweep counts no abandonment, Check 6.4 reads every abandonment as an operator's, and every cross-seam comparison takes the allowance at the reading (Allowance 4 through 6); a closure table in Action wiring mapping every action's inputs and every answer of record_action, read_record, the range read, take, remaining, release and the probe to where the action lands it and the rule that owns the landing; and the cells no rule owned cured: recording-failure(step-4) read as recording-failure(step-2) at every position, a record action that lands it committing nothing (Execution Contract Database 1; Primitive policy 44); an invalid-query landed where unavailable lands and never surfaced as journal-unavailable (Capability requirement 13, 14); a blank act key, actor reference or credential at [Open] (open step 1.10); an outcome reference outside the kind's at [Close] (close 6); a kind the bindings table does not serve at [Resolve], as at [Open] (resolve 33); an intent event id naming no intent of the act that carries the invocation id (resolve 34); every disposition but an outcome over a standing abandonment (resolve 16b, for resolve 17); [Resolve]'s closing event id (resolve 35); the outcome-unrecordable escalation that answers the same (reconcile step 3.23); and the surfaced count (reconcile step 1.7). Open lines 2026-10-18-d and 2026-10-18-i dissolved by the cut, and 2026-10-18-g, 2026-10-18-j, 2026-10-18-m and 2026-10-18-s cured by the table; no model changed, since the model chooses a fenced or a fenceless store at Init and every run covers both, so each invariant the page keeps is checked over the fenceless half, the page's whole; rules 571 to 540. *Over:* a fenced commit and a counted retry no adopter exercised, where Final Critique 18's second finding lived; and the edges of the six actions found one round at a time. *Because:* the council's counts held and then rose (Final Critique 13 to 18: 3, 3, 4, 2, 2, 4), each round finding the next input or arm with no owner; the maintainer ruled the unbound branches cut first and every input and arm given an owner, so the next round reads a page whose edges are enumerated, and the page's plateau count starts again from that round. What the composition does for an act its adopters bind changes only where the table found no owner.

- **2026-10-23 — A resolution's supersession is no second closing, a declared fence reaches the commit, every holder value is fresh, and an outcome's reference is one the kind declares.** *Chose:* Invariant 2.1 forbidding two unsuperseded closing records, the reading Check 2.1 and the model's Inv2_OneWriter already had, so an operator's resolution over an escalation keeps it; [Open] minting the commit fence deadline from the expiry instant its take answered and returning it beside the pair, and the adopter issuing the commit carrying it (open step 5.7, open step 5.8, commit 13b); operator run id fresh for every [Resolve] call and run id fresh for every run, as Lease Identity 6 asks of every take; an outcome action reference one of the kind's enumerated outcome refs, an operator's other reference refused as malformed (resolve 31); close step 3.7 and 3.8 out of the withdrawn release-and-reject idiom into WHEN blocks, one obligation a line, and Action wiring 5's undeclared examples dropped; open lines 2026-10-23-a and 2026-10-23-b added and 2026-09-10-a widened, these three and 2026-10-18-a now flagged on the page beside their rules; rules 563 to 571. *Over:* Invariant 2.1 as the rewrite of 2026-10-20 left it, binding every deployment with no word for the supersession [Resolve] writes; a deadline the page named and no rule minted or handed over; holder values injected with nothing saying they are fresh; and a disposition's form tested without its reference. *Because:* Final Critique 18's readers traced each on a deployment that keeps every rule: a resolution breaking Invariant 2.1, a commit stalled past the lease landing after the sweep's abandonment under a declared fence, a late release ending another take's grant against Lease Check 5.3, and an operator's outcome under `<kind>.intended` writing a second intent record against Check 2.2. What the composition does for an act it serves is otherwise unchanged.

- **2026-10-21 — The bounded-closure claim reads as provable.** *Chose:* *provable* (`glossary.md`: shown by the records alone, never by a system's say-so) where the page wrote *the records alone* or *from the records alone*: Invariant 4.1, under which the records reveal, provably, every act whose invocation has yielded or died as an aged intent with no record naming the intent's invocation id, and, by wording alone, Invariant 1's defended-in-line note and the acceptance bar; and *provide* where Composes said no constituent's records *grant* the act's critical section, so *grant* keeps the one meaning the glossary gives it, Lease's live grant; rules 563 to 563, the status draft as it stood. *Over:* the phrase restated at each site. *Because:* the maintainer ruled 2026-10-21 that *shred*, *grant* and *provable* are declared domain terms, each defined once, in `glossary.md`, and that the specifications say them where their meaning stood; the wording of Invariant 4.1 changed and no obligation did.
- **2026-10-20 — A writer's re-read, lease check and append are one transaction, and the journal carries no fence.** *Chose:* under the maintainer's ruling of 2026-10-20 14:26Z — Execution Contract Store 2 covers a guard decided across a lease check, the re-read, the lease check and the append being one transaction because the lease's grant and the journal live in the one store — no append lands beside a closing or an intent another writer committed after taking the critical section, so what the page built for that late append goes to Store 2: the journal fence, with its conveyance, its two minted instants and its headroom (journal fence 1 through 4, Allowance 13, Term journal fence, Term journal fence instant, Term journal fence lease terminus, Term journal fence per-write terminus); the fenceless branch and the binding duplicate it left for an operator to end (journal fence none 1 through 6, Which closing stands 6 and 9 through 11, read invocation 7 through 9, reconcile step 1.4, 1.5 and 5.2 through 5.7, resolve 9a, the binding duplicate finding, the closings key and the intents key, the two fields of [Read Invocation]'s answer that reported them, and their card); Invariant 2.4 and 2.5, so Invariant 2.1 binds every deployment; and close step 2.5. The retry only a declared fence admitted goes with the fence (Primitive policy 29a, 37a), so Primitive policy 32a and 37b bind every deployment as they bound this library's and no lost-reply write is issued twice, and Term unfenced write is the bound commit under commit fence none alone. Rules 598 to 563. *Over:* an optional fence on the journal's writes, and a fenceless mode in which a late append could land beside another writer's closing and wait as a binding duplicate for an operator (the 2026-08-30 entries). *Because:* the lease keeps its job for the act outside the store: every lease check, the critical section held across [Open], the commit and [Close], the commit fence and its minted deadline, act section 16 through 18 for the bound commit, and the sizing stand. What the composition does for an act outside the store is unchanged.
- **2026-10-20 — The store's guarantees cited, not restated, and the substrate's step-4 split read as gone.** *Chose:* Capability requirement 12 citing Execution Contract Store 1 through 4 for the journal's store; Capability requirement 7, which made a returned write visible to every later read, tombstoned to Execution Contract Store 2 and Execution Contract Store 3, with Term read-your-writes reading Capability requirement 8 and 12; recording-failure(step-4) no longer read as an append that landed without its placement — Primitive policy 24, 25 and 26 (the intent position's read-back, its proceeding and its bar on a retry) tombstoned to Execution Contract Store 1, and the code taken out of Primitive policy 27, 28 and 40, refuse step 3.3, 3.4 and 3.12, resolve 24 and 25 and reconcile step 3.16, each still reading back an invalid-request(step-4). Rules 601 to 598. *Over:* a journal whose returned write a later read might miss, and a substrate whose record action could land its append and lose its placement. *Because:* the maintainer ruled 2026-10-12 that the corpus takes a store's specification, never the store, and 2026-10-20 that Store 1 binds every store write of one composition action, its constituents' included, while a refused attempt a page keeps as evidence stays a domain choice: Audit Trail's record_action now commits nothing on a recording-failure and keeps its evidence on an invalid-request at step 3 or step 4 (its record action step 7.11), so only an invalid-request(step-4) leaves a record to read back. The critical section held across [Open], the commit and [Close] stays, and with it the journal fence, the fenceless late append and the binding duplicate surfaces: each re-read under the section is separated from its write by a lease reading, and the page does not read Store 2 as reaching a guard decided across an act outside the store. No rule reads an earlier version and Event Log's sequence numbers order the journal, so neither History 1 nor Order 1 is cited; what the protocol does for an act outside the store is unchanged.
- **2026-10-07 — A call in flight holds the grant, an unfenced write is sized, and a holder mints its own fences.** *Chose:* no release behind a call in flight, read through one Term so that every release on the page means it (act section 15, Term release); Lease's sizing bound whole for the writes no fence reaches — a call pause bound, a reading for every write, a write floor and a commit floor, a reading ahead of the commit that [Open] takes and may refuse on, and no second issue of a lost-reply write where journal fence is none (act section 16 through 18a, call pause bound 1 and 2, open step 5.4 through 5.6, commit 14c, Primitive policy 37b); a holder value for every sweep take, with act section 14 tombstoned; both lease-derived fence instants minted by the holder. *Over:* a release that shows the landing to the next holder by read-your-writes, which Lease refused as an exception no reader could pin to a time; dropping the retry under a declared fence as well, which would leave the per-write instant with nothing to guard (Ledger 2026-10-07-d); and a twin for the hold, which the model does not reject when it is flipped alone. *Because:* Lease grounded on 2026-10-04 with rules this page broke on its unknown partition, the first place the pilot adopter landed. Model v6 holds with the hold, and with the operator's reading one tick ahead the hold is what stops a false abandonment.
- **2026-09-10 — Lease is the atom; what a fence costs stays here.** *Chose:* [`atoms/lease.md`](../atoms/lease.md) owning the critical section's lease and both fences as one concept; the binding and the three payments here. *Over:* an atom covering the critical section alone. *Because:* the atom declines what carrying an instant costs; lease-owned findings went 3 → 1 → 0 across the extraction.
- **2026-09-10 — The findings register is extraction-pending.** *Chose:* classify against a forthcoming Condition Register, the two obligations and five conditions named. *Over:* declaring the totality claim false. *Because:* an unclassified register ends up in process memory and loses the outage span a check reads.
- **2026-09-10 — The intents key branches on service identity; the first does not.** *Chose:* the branch once, at the section titled *Which closing stands*. *Over:* an unbranched key. *Because:* unbranched, [Open] step 3's own report-only instruction was a conformance failure for a whole retention period.
- **2026-09-10 — not-open is a precondition on the caller.** *Chose:* the pair [Open] returned, on the action's call stack. *Over:* a retained handle, or deleting the code. *Because:* the handle is the state the execution contract forbids, and the code is the one name an adopter has for the condition.
- **2026-09-10 — The fence earns Invariant 8; the lease gate does not.** *Chose:* the duplicate surfaces count open intents per `(kind, act_key)`; the read gains read bound. *Over:* gating the intent write as the remedy. *Because:* the gated fenceless configuration admits a second live intent and the ungated fenced one does not.
- **2026-09-10 — The sweep's lease is stated, not maximised.** *Chose:* `closure_latency + journal_write_bound`. *Over:* a `max` with a start check. *Because:* the check reduced to `0 > journal_write_bound` whenever closure latency reached completion bound.
- **2026-09-10 — Supersession is transitive; the model does not confirm it.** *Chose:* the standing closing is the one no other closing names; the reachable set counts as one. *Over:* pairwise. *Because:* pairwise collapse reports binding duplicate on the check-6 chain; the model counts supersessions without identifying them.
- **2026-09-08 — Supersession is by name; the operator's seam is the sixth clock.** *Chose:* every closing over an existing record carries `supersedes`; now injected at the operator's seam. *Over:* the name for the abandoned case only, and an unbounded reading. *Because:* resolving actor names the operator, not a record; a destructive write cannot be decided by a reading nothing bounds. Both are rejected twins.
- **2026-09-08 — kind is an argument; the act's closings are a declared index.** *Chose:* kind first in every action but [Reconcile], `(kind, act_key)` keys, act closings. *Over:* the kind implicit in the caller. *Because:* a signature that omits the kind names the wrong critical section, and `act-landed(outcome_event_id)` had nothing to supply its payload.
- **2026-08-30 — The closure window is bounded by three sweep runs.** *Chose:* `completion_bound + 2 × clock_offset_allowance + 2 × reconciliation_cadence + 3 × run_bound < compensation_window`. *Over:* one run bound, and the two-term correction the gate prescribed. *Because:* a budgeted death involves three runs; the enumeration breaches the old form on 420 of 432 tuples and the correction on 396.
- **2026-08-30 — A duplicate is decided by supersession first and position second.** *Chose:* a declared field on [Read Invocation], a scan over the delta, a check over all four closing kinds. *Over:* three detectors that did not exist. *Because:* a degraded guarantee whose detection is asserted is worth less than an honest statement that there is none.
- **2026-08-30 — Fenceless is a declared degraded mode.** *Chose:* journal fence optional, the weaker guarantee stated over records. *Over:* requiring a fence no substrate here can supply. *Because:* the guarantee changes and stays checkable.
- **2026-08-30 — The composition's own writes are fenced, not merely gated.** *Chose:* journal fence as an instance capability requirement. *Over:* the gate alone. *Because:* the gate is check-then-act; the fence carries Invariant 2 with or without it.
- **2026-08-30 — The protocol is a compound, adopted by binding.** *Chose:* one composition owning the pair, the critical section, the sweep, the derived-not-remembered rule, positioned codes and the closure inequality; adopters bind and declare deviations from a closed list. *Over:* six methodology rules applied twenty times, or a Transaction pattern the constituents cannot support. *Because:* fourteen exact instances and ~920 KB of protocol prose clear the higher-order composition test, and the invariants are provable only over the pair of processes and the one critical section.

NOTE: End of Recoverable Invocation.
