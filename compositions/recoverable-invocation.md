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

The protocol is proved in `recoverable-invocation.tla` (TLA+): six components over one act — the invocation, the section host, the store, the journal, the sweep as two runs on two nodes, and an operator through [Resolve] as the third writer — with time explicit, the crash anywhere, and every write split into the instant its gate is passed and the instant it is issued. The composition wires the **Audit Trail** substrate and a **critical section** the deployment supplies, keyed by the act, and composes no store of its own. The emergent guarantee: every act committed through it is accounted for exactly once, by exactly one writer, within a declared window or with a declared record of why not.

---

## Intent

WHY:
An irreversible act and its account are two writes no transaction spans (the library's rule since 2026-08-27: an atomic set may not contain a write the host cannot take back). The order — intent, act, outcome — leaves exactly one reachable partial: the act committed, its record owed. Something must close it after the process that opened it is dead.

By 2026-08-30 twenty compositions had each solved this in their own words, and two days of fresh-reader gates found the same defects in every one: two writers landing an outcome for one act; a sweep reading in-flight work as a crash; a sweep re-emitting an outcome it could not have known; a rejection code saying nothing had committed when something had; a closure window that could not be met. One protocol, carried once. The rule: **one act, one intent, one outcome, one writer** — the invocation while it holds the section, the sweep after the invocation has yielded, never both.

Not a transaction, not the adopter's store, not an audit journal, not a class. An adopter names it in *Composes*, binds its parameters, declares any deviation, and deletes the paragraphs this page replaces.

---

## Composes

- **[Lease](../atoms/lease.md)** — the per-key grant of exclusive standing whose terminus is an instant. The act section is a lease, and so are both fences. This page binds the atom's parameters — which key, which holder, how long, which arm maps to which code — and restates none of its semantics. What the atom refuses to own and this page adds: which key protects which work, and how long a grant must last.
- **[Audit Trail](./audit-trail.md)** — the regulated-audit substrate and this composition's journal, its four constituents (Event Log, Actor Identity, Tamper Evidence, Retention Window) reached transitively per *Compositions of compositions* ([`spec-format.md`](../spec-format.md)). Consumed at the declared contract `record_action(action_ref, actor_ref, credential, data) → event_id | rejected(invalid-credential | invalid-request | recording-failure(step))` for every record this page writes, and `read_record(event_id) → audit_record | not-known` where an `event_id` is in hand. Attribution, retention and sealing of every record here are Audit Trail Invariants 1, 2 and 3; destruction of a payload at the horizon is Audit Trail Invariants 4 and 8.
- **The bound act** — not a constituent. The adopter's constituent commit call, supplied as a binding together with the read that tells whether it committed. The constituent's own contract governs the commit.
- **The act's section** — a critical section keyed by the act, supplied by the deployment (*Configuration*, `act_section`). No constituent grants it.

### Instance capability requirements

Four declared, two optional.

```text
CP1: The substrate MUST supply the open-upper-bound sequence-range read over the delta range.
CP2: The range read MUST answer a page of records with a cursor, a declared page size, and a page-complete signal.
CP3: The range read MUST declare the arms invalid-query and unavailable.
CP4: The composition MUST surface invalid-query on compliance_surface.
CP5: The composition MUST NOT retry an invalid-query read unchanged.
CP6: EVERY read path of Recoverable Invocation MUST transcribe unavailable at the read path's own position.
CP7: EVERY later range read of the instance, from any node, MUST return a record whose record_action returned on an arm that leaves the record appended.
CP8: EVERY range read issued after journal_write_bound has elapsed since a lost-reply append's issue MUST return the record.
CP9: A read_record that cannot reach the journal MUST land rejected(recording-failure(resolution)) at [Resolve].
CP10: A read_record that cannot reach the journal MUST NOT answer not-known.
CP11: IF the range read, read-your-writes or act_section is absent THEN the composition MUST NOT start.
```

Terms › `delta range`: the sequence-number range from `sequence_high_water + 1` with no upper bound.

Terms › `open-upper-bound sequence-range read`: `EventLog.read` over the delta range, reached through Audit Trail's list-shaped pass-through.

Terms › `read path`: [Open] step 3, [Reconcile] step 1, [Read Invocation], and the re-reads at [Close], [Refuse] and [Resolve]. The first three transcribe `unavailable` as `journal-unavailable`; the last three land it on the position's `recording-failure` arm.

Terms › `read-your-writes`: CP7 and CP8 together. The filtering of every range read on `action_ref`, `invocation_id` or a payload field is this composition's code; the substrate offers no such selector.

WHY:
The section is released on the holder's return, well inside `journal_write_bound`, so a waiter admitted then re-reads before a time-only guarantee says anything, sees no closing, and writes the second one (`-buggy-visible`, rejected). Without CP9 an outage at [Resolve]'s purge check reads as absence.

### `journal_fence` (optional)

A fence on the composition's own journal writes, standing to the journal as `commit_fence` stands to the adopter's store: a conveyance, a clock, an edge.

```text
JF1: A deployment declaring journal_fence MUST declare the conveyance: a deadline parameter on record_action, or a host-applied request-scoped deadline on every record_action of the instance.
JF2: §Where the allowance goes IS AUTHORITATIVE FOR the fence's instants.
NOTE: watch addressable sections — a section title as the subject of an authority claim (JF2, WA2, IS1, WC1, IV7).
JF4: The substrate MUST land a fenced-out write on the position's existing recording-failure arm.
JF5: A sweep run MUST absorb a fenced-out closing write into skipped and leave the intent open.
```

Terms › `position's existing arm`: `recording-failure(intent)` at [Open]; `recording-failure(outcome)` at [Close]; `recording-failure(refusal, constituent_code)` at [Refuse]; `recording-failure(resolution)` at [Resolve].

Terms › `journal_fence instant`: the earlier of the writer's lease terminus and the write's per-write terminus.

WHY:
`record_action` carries no deadline parameter, so the first conveyance is unavailable in this library. Without the per-write instant a write may land after `journal_write_bound` and inside the lease — after the read-back, which then retries and appends the duplicate (`-buggy-perwrite`, rejected).

### Under `journal_fence = none` — the case in this library today

```text
JN3: WHEN journal_fence = none:
    JN3a: A late append beside another writer's closing MUST leave both records.
    JN3b: The composition MUST set binding_duplicate on the act.
NOTE: JN1 deleted after CR-7; IV6a owns the pairing.
NOTE: JN2 deleted after CR-7; IV6 owns the rule.
JN5: The composition MUST surface a binding_duplicate.
JN5a: The composition MUST report a binding_duplicate.
JN5b: The composition MUST resolve a binding_duplicate.
JN6: A surface MUST report a duplicate as EXACTLY ONE OF the closings key, the intents key.
JN7: A surface MAY report the intents key ONLY IF the act kind declares a service_identity.
```

Three surfaces make JN5 checkable and read §*Which closing stands* for both keys: [Read Invocation]'s two `binding_duplicate` fields (RD6, RD7), [Reconcile] step 5's scan over the delta (RC41–RC43), and Generation acceptance check 2.

Terms › `quiescence`: no invocation in flight and no sweep run mid-pass.

WHY:
No auditor can enumerate which writers were paused, so the guarantee is over records alone. The scan rides the delta, where a late append appears, because step 1 keeps only open intents and an act with two closings is not open. The intent is inside this: [Open] releases on the intent write's return, so a late-landing intent leaves the next waiter's pre-check reading nothing and a second live intent appears, both escalating (Invariant 3) — invisible to any surface keyed on `invocation_id`, hence the intents key. The fence prevents it and the gate does not (`probe-fenceless-intent` violates, `probe-fenced-ungated-intent` holds); the gate is kept because it is this page's rule for every write. With the fence none of this machinery fires.

---

## Composition logic

### Bindings

An adopter binds the parameters below once per **act kind**. The instance's `bindings` Configuration entry is the table of bound kinds — configuration, not state.

```text
BD1: [Reconcile] MUST read completion_bound, commit_fence, probe, service_identity, retention_period and the <kind>.* vocabulary of every intent from the bindings table by the intent's kind.
BD2: The deployment MUST refuse a configuration change that unbinds a kind with an open intent.
BD3: The refusal BD2 names MUST land on compliance_surface with the reason.
BD4: [Reconcile] step 1 MUST surface EVERY <kind>.intended record whose kind the bindings table does not serve and which no closing record of any kind names, once per run, on compliance_surface.
BD5: [Reconcile] MUST NOT close an intent BD4 surfaces.
BD6: [Reconcile] MUST bound the pass BD4 names by the instance's longest retention_period.
BD7: The adopter MUST declare EVERY binding in the adopter's own Composes entry for this composition.
BD8: The adopter MUST declare a need outside the bindings as a deviation (Edge cases, Declared deviations).
```

WHY:
An unbound kind has no `probe`, no `completion_bound` and no `retention_period`, so nothing downstream can close or enumerate it. Unbinding is a deployment-plane operation with no signature block and no code. Check 3 exempts BD4's intents.

- **`act_key`** — the identity of one act: the field or tuple under which two invocations are the same act. The section is keyed by it; the sweep pairs by it; the pre-check reads by it.
  ```text
  AK1: The adopter MUST know act_key before [Open].
  AK2: An act whose key is minted by the commit MUST bind the key the adopter can name before the commit and declare the minted-key deviation.
  ```
- **`commit`** — the adopter's constituent call that makes the act, with its rejection arms partitioned by the adopter.
  ```text
  CM1: The adopter MUST partition the constituent's arms as EXACTLY ONE OF pre-commit, committed, unknown.
  CM2: The adopter MUST close a pre-commit arm through [Refuse].
  CM2a: The adopter MUST return the constituent's own code for a pre-commit arm.
  CM3: The adopter MUST close a committed arm through [Close].
  CM4: The adopter MUST transcribe the constituent's partition as the constituent states the partition.
  CM5: The adopter MUST treat a lost reply as unknown.
  CM6: The adopter MUST treat a reply the constituent's contract does not declare pre-commit as unknown.
  CM7: WHEN the arm = unknown:
      CM7a: The adopter MUST NOT call [Close].
      CM7b: The adopter MUST NOT call [Refuse].
      CM7c: The adopter MUST call [Yield].
      CM7d: The adopter MUST return rejected(recording-failure(outcome)) to the caller.
  CM8: The adopter MAY call [Refuse] ONLY IF the constituent declares the arm pre-commit.
  CM9: The binding MUST declare commit_fence as EXACTLY ONE OF none, declared.
  CM11: A declared commit_fence MUST declare the conveyance: a deadline parameter on the constituent's call, or a store-applied request-scoped deadline on every write of the adopter's instance.
  CM12: The adopter MUST NOT declare a relative request timeout as commit_fence.
  CM13: WHEN commit_fence = declared:
      CM13a: The sweep MAY write abandoned ONLY IF probe answers not-committed for an intent past abandon_edge.
  CM14: WHEN commit_fence = none:
      CM14a: The sweep MUST NOT write abandoned for the act kind.
      CM14b: The sweep MUST write escalated for a not-committed answer.
  ```
  Terms › `commit_fence`: an instance capability requirement on the constituent's store under which a write issued under the act's section is never applied after the fence's instant; `none` or `declared`.

  WHY: a lost reply mapped to a refusal closes the intent over an act that may have committed, and nothing looks at it again. No atom in this library declares a deadline parameter today.
- **`pairing_datum`** — the field the intent record and the constituent's record both carry by construction: the seam-injected `now` passed into `commit`, an adopter-minted nonce stored by the constituent, or a constituent-minted id the store exposes by the intent's parameters.
  ```text
  PD1: intent_data MUST carry pairing_datum.
  PD2: probe MUST match on pairing_datum by equality.
  PD3: A journal join MUST NOT pair on pairing_datum.
  PD4: The adopter MAY bind a seam-injected now as pairing_datum ONLY IF no two serialized invocations of one act_key carry the same reading on any node of the instance.
  PD5: The adopter MUST declare the obligation PD4 names where the datum is a seam-injected now.
  PD6: WHEN pairing_datum = none:
      PD6a: probe MUST NOT answer committed.
  ```
  WHY: two nodes' seams may read one instant within `clock_skew_allowance`, and the section separates invocations without separating stamps; the failure is safe (`undecidable`, escalated) but a nonce avoids it.
- **`repeatable`** — `yes` or `no`: whether two invocations against one `act_key` are two acts or one act attempted twice.
  ```text
  RP1: [Open]'s act-landed refusal MAY fire ONLY IF repeatable = no.
  ```
- **`probe`** — a read of the adopter's store keyed by `act_key` and `pairing_datum`, answering for the sweep: did the act commit, and with what outcome.
  ```text
  PR1: probe MUST answer EXACTLY ONE OF committed(outcome_action_ref, outcome_data), not-committed, undecidable(candidates), unavailable.
  PR2: probe MAY answer committed ONLY IF exactly one store record matches pairing_datum.
  PR3: probe MAY answer undecidable(candidates) ONLY IF more than one record matches pairing_datum OR payload_match holds.
  PR4: probe MUST map EVERY constituent read rejection to unavailable.
  PR5: probe MUST NOT map a constituent read rejection to not-committed.
  PR6: outcome_data MUST carry only what the store re-derives.
  PR7: WHEN the outcome's authoritative datum exists nowhere but in the dead invocation's memory:
      PR7a: probe MUST answer undecidable.
  ```
  Terms › `payload_match`: `pairing_datum = none` AND at least one store record matches the intent's payload.
- **`completion_bound`** — the longest a conforming invocation of the kind takes from [Open]'s section take to [Close]'s last write, including the constituent round-trip. The lease length of the section, the lower edge of the sweep, the first term of the liveness inequality. Read against the seam clock [Open] was injected with.
- **`commit_round_trip`** — the longest one `commit` call takes from issue to reply; charged by `lease_spend`.
- **`probe_round_trip`** — the longest one `probe` call takes from issue to answer; charged by `closure_spend`.
- **`journal`** — the Audit Trail instance the records go to, and the `action_ref` vocabulary of the kind.
  ```text
  JB1: EVERY act kind of an instance MUST share one Audit Trail instance.
  JB2: The vocabulary of a kind MUST declare <kind>.intended, the enumerated outcome refs <kind>.<outcome>, and <kind>.refused.
  JB3: The composition MUST derive <kind>.recovery_intended, <kind>.abandoned and <kind>.escalated from the vocabulary.
  JB4: The rebuild MUST classify a record as an outcome by membership in the enumerated outcome refs.
  JB5: The adopter MUST NOT declare audit as a kind.
  JB6: The substrate's retention_policy MUST resolve EVERY <kind>.* record to one fixed policy_ref of retention_period, selected on the <kind> prefix of action_ref and nothing else.
  JB7: IF the substrate admits one policy_ref per instance and no selector THEN kinds with different retention periods MUST run under different Recoverable Invocation instances.
  JB8: The sweep MUST derive the upper edge from retention_period.
  JB9: The sweep MUST NOT read the upper edge from a record's own retention_until.
  ```
  WHY: `sequence_high_water` is one scalar per instance. An intent retained late carries a later `retention_until`, and an edge read from it would examine an intent whose closings are purged.
- **`service_identity`** — a registered actor in the substrate's Actor Identity registry (`actor_ref` and `credential`) under which the sweep writes, or `none`.
  ```text
  SI1: WHEN service_identity = none:
      SI1a: The sweep MUST NOT write.
      SI1b: The sweep MUST surface EVERY aged open intent on compliance_surface.
  SI2: PROVISIONAL: Invariant 4's liveness arm DEGRADES TO surfaced under service_identity = none.
  ```
- **`outcome_envelope`** — the largest outcome payload the kind can write, sized by the adopter from the adopter's own caps, every set-valued field capped and every reference under `reference_length_cap` (Invariant 6).
- **`retry_terminus`** — `lease` (default) or the declared deviation `counted(n)`.
  ```text
  RT2: [Close] MUST NOT write BEFORE querying remaining.
  RT2a: IF journal_write_bound EXCEEDS remaining OR remaining = none THEN [Close] MUST NOT write.
  RT3: retry_terminus MUST NOT move the terminus.
  ```
  Terms › `terminus`: the section's lease — an invocation's standing to write ends at the lease's expiry, under every retry_terminus value.

### Composition state

Five elements, each carrying the Contract classification of [`execution-contract.md`](../execution-contract.md) §Composition state. Four are derived indexes rebuilt from one sequence-range read filtered to the bound kinds' records, whose `kind` and `act_key` the composition writes itself. One is extraction-pending. `act_section` is not composition state.

- **`open_invocations`** — map from `(kind, act_key)` to the set of intent records (`intent_event_id`, `invocation_id`, the payload) of every invocation of the act that has opened and not yet closed, refused, been abandoned or been escalated. *Derived index.*
  ```text
  OI1: IF service_identity != none THEN two open intents MUST NOT share one (kind, act_key).
  OI2: IF service_identity = none THEN several open intents MAY share one (kind, act_key).
  OI3: The composition MUST rebuild open_invocations from the range read filtered to <kind>.intended records, less those a later record names through invocation_id.
  OI4: [Open] MUST populate open_invocations.
  OI4a: [Close], [Refuse] and the sweep MUST clear open_invocations.
  OI5: [Open]'s pre-check, [Close]'s pre-check and the sweep MUST read open_invocations.
  OI6: open_invocations MUST NOT hold an intent past the retention horizon.
  ```
  WHY: two kinds with byte-equal keys are two acts. On a multi-node instance a rebuilt map is a journal read that may lag another node's intent, so [Not Open] is a precondition on the caller.
- **`act_closings`** — map from `(kind, act_key)` to the act's closing records, whoever wrote them. *Derived index*, same rebuild.
  ```text
  AC1: [Close], [Refuse], [Resolve] and the sweep MUST populate act_closings.
  AC2: [Open] step 3, [Resolve]'s supersession check and [Read Invocation] MUST read act_closings.
  ```
  WHY: every read is a delta above the mark, so a closing older than the mark is reachable only from a local map; without it `act-landed(outcome_event_id)` never fires.
- **`sweep_closed_ids`** — the set of `invocation_id`s the sweep has closed: an outcome under `recovery = true`, an `<kind>.abandoned`, or an `<kind>.escalated` naming the id. *Derived index*, same rebuild.
  ```text
  SC1: The sweep MUST NOT write a closing BEFORE consulting sweep_closed_ids under the section.
  ```
  WHY: two sweep runs — restart and cadence, one node or two — never both close one act.
- **`sequence_high_water`** — the highest `sequence_number` the composition has read. *Derived index.*
  ```text
  HW1: EVERY re-read of Recoverable Invocation MUST read the delta above sequence_high_water and advance the local maps by the delta.
  HW2: The mark MAY advance past a sequence_number ONLY AFTER settle_bound has elapsed since the sequence_number's recorded_at.
  HW3: EVERY instance MUST perform a full rebuild at process restart.
  HW4: EVERY instance MUST perform a full rebuild PER reconciliation_cadence.
  HW5: IF now EXCEEDS an intent's retention_end THEN EVERY read of open_invocations MUST drop the intent.
  HW6: A lost mark MUST rebuild both maps from the log's beginning.
  ```
  Terms › `settle_bound`: `journal_write_bound + clock_skew_allowance`.

  Terms › `retention_end`: `recorded_at + retention_period`.
  WHY: the delta rule needs a prefix-closed read, which Event Log does not grant. Contiguity cannot be the test: `next_sequence_number` counts allocations, so a gap is normal. A purge writes no log record, so the horizon is applied on read.
- **`findings`** — the register of what the sweep could not close and what the instance could not do, written to the deployment's `compliance_surface`. *Extraction-pending*; the named proposed atom is a **Condition Register** *(forthcoming)*.
  ```text
  FR1: The deployment MUST persist a finding for at least the retention_period of the kind the finding names.
  FR2: The deployment MUST persist a finding naming no kind for at least the instance's longest retention_period.
  FR3: A surfacing that fails MUST NOT reject a [Reconcile] run that has landed closings.
  FR4: The register MUST write a [Finding] as EXACTLY ONE OF act finding, instance finding.
  FR7: An instance finding MAY omit kind.
  FR8: A surface MUST NOT read a finding outside the five conditions.
  FR9: The register MUST set first_seen at the first surfacing.
  FR9a: The register MUST NOT move first_seen.
  FR10: The register MUST advance last_seen on every run that still sees the condition.
  FR11: WHEN a run does not see a standing condition:
      FR11a: The register MUST close the record with last_seen at the previous run.
  FR12: The register MUST open a new record for a recurrence.
  FR14: The register MUST hold one record per standing condition.
  FR15: A reader MUST NOT rely on an order across act_keys.
  ```
  Terms › `act finding`: {finding, kind, act_key, invocation_id, first_seen, run_id}; deduplicates on (invocation_id, finding); carries no last_seen and no span.

  Terms › `instance finding`: {finding, kind, first_seen, last_seen, run_id}; deduplicates on (finding, kind).
  The five conditions:
  - `journal-unavailable` — instance finding, no `kind`: the journal could not be read or written this run ([Reconcile] step 1).
  - `store-unavailable` — instance finding, `kind` present: the kind's adopter's store answered `unavailable` to `probe` ([Reconcile] step 3).
  - `closure-at-risk` — act finding: the act's remaining window is below what one more cadence and one more run need ([Reconcile] step 5). Generation acceptance check 3's `service_identity = none` branch reads it.
  - `binding_duplicate` — act finding: two closings or two open intents on one act (§*Which closing stands*). A report under `journal_fence = none`; no check reads it.
  - `unbound-kind` — act finding: an open intent of a kind the instance no longer binds.

  WHY: no constituent witnesses a surfacing, so no rebuild exists. One record spanning two outages would exempt every intent in the healthy gap (FR11, FR12). A store outage is per kind; a journal outage stops every kind (FR7).
- **`act_section`** — not composition state: a **[Lease](../atoms/lease.md)**, bound in *Configuration*.
  ```text
  AS1: The deployment MUST supply act_section with the Lease atom's semantics.
  AS2: A host MUST NOT free the section on a holder's death (Lease Invariant 3).
  ```

### Configuration

- **`bindings`** — the table of act kinds the instance serves, each with its full binding set. *Default:* none.
- **`act_section`** — an instance capability requirement: a [Lease](../atoms/lease.md) host. *Default:* none.
  ```text
  AS3: The deployment MUST share act_section across every node of the instance.
  AS5: EVERY action but [Reconcile] MUST take kind as the first argument.
  AS9: [Open] step 2 and [Resolve] MUST transcribe the atom's unavailable arm as rejected(section-unavailable).
  AS10: EVERY caller on this page MUST discard the atom's not-held arm.
  AS11: The composition MUST NOT use try_take.
  AS12: [Open] MUST NOT write the intent record BEFORE taking the section.
  AS13: The invocation MUST hold the section through [Close]'s last write.
  AS14: WHEN an invocation's lease has expired:
      AS14a: The invocation MUST NOT write.
      AS14b: The invocation MUST NOT re-take the section.
      AS14c: The invocation MUST discard a constituent reply that arrives after the expiry.
      AS14d: The invocation MUST return rejected(recording-failure(outcome)).
  AS15: The sweep MUST take the section on every act_key the sweep examines.
  AS16: The sweep MUST hold the section across the pre-check and the closing write.
  AS17: A sweep run MUST leave a closing write in flight at expiry for the next run.
  AS18: The section MUST admit re-entry by the section's own holder alone.
  ```
  Terms › `section key`: `(kind, act_key)`.

  Terms › `section holder`: the invocation_id for an invocation; the run's own seam-injected id for a sweep run; operator_run_id for [Resolve].

  Terms › `section duration`: `completion_bound` for an invocation; `sweep_lease` for a sweep run or an operator.
  WHY: `completion_bound` no shorter, so a conforming invocation is never evicted mid-section; no longer, so a stalled holder blocks the sweep for at most the bound. The lease ends the hold; the `journal_fence` keeps a dead holder's write from landing — with the fence Invariant 2 holds with or without the gate, without it Invariant 2 fails with or without the gate. The gate stops a holder starting a write the fence will refuse.
- **`journal_write_bound`** — the disclosed bound on a `record_action` from issue to landing: the substrate's `record_action_completion_bound` plus issue-to-first-commit latency, with headroom. *Default:* none.
  ```text
  JW1: IF journal_write_bound EXCEEDS remaining THEN a writer MUST NOT issue a journal write under the section.
  ```
  Terms › `sweep_lease`: `closure_latency + journal_write_bound`.
- **`reconciliation_cadence`** — the interval at which the sweep runs after the mandatory run at process restart. *Default:* none.
- **`read_bound`** — the disclosed bound on one under-section journal read ([Open] step 3, [Close] step 2, [Refuse], [Resolve]). Conditions 3 and 5. *Default:* none.
- **`closure_latency`** — the disclosed bound on one whole closure: re-read, `probe`, `<kind>.recovery_intended`, the closing record, the index update. Condition 5. *Default:* none.
- **`run_bound`** — the disclosed bound from a [Reconcile] run's start to the last closing it lands, over the largest backlog the deployment sizes for. *Default:* none.
  ```text
  RB1: The next run MUST NOT start beside a run in flight.
  ```
  WHY: sequentially, `run_bound` is the backlog times `closure_latency` plus one holder's remaining lease per act; condition 1 carries it three times.
- **`compensation_window`** — the duration within which the sweep closes an act whose invocation died, from the intent's `recorded_at`. Conditions 1 and 2; rearranged, the at-risk threshold of [Reconcile] step 5. *Default:* none.
- **`clock_skew_allowance`** — the allowance for comparing a reading from one clock with a stamp or instant from another; §*Where the allowance goes* owns where it is spent. *Default:* none.
- **`intent_candidates_cap`** — the most `store_candidates` an `<kind>.escalated` record names, each under `reference_length_cap`; past it, the count and the range. Sizes the compensation envelope (Invariant 6). *Default:* none.
- **`retention_period`** — a per-kind binding (*Bindings*, `journal`); [Reconcile] step 1 and condition 2 read it. *Default:* none.
- **`read_cap`** — the most invocations [Read Invocation] returns for one act, and the most records per invocation. *Default:* none.
- **`compliance_surface`** — the deployment's surface for the instance's `findings` (*Composition state* owns the contract); check 3 reads both branches on it. *Default:* none.

### Where the allowance goes

```text
WA1: clock_skew_allowance IS AUTHORITATIVE FOR every comparison in Recoverable Invocation between a reading taken at one seam and a stamp or instant minted at another.
WA2: This section IS AUTHORITATIVE FOR where the allowance is spent.
NOTE: watch addressable sections (JF2).
WA3: A writer MUST classify EVERY cross-seam comparison in Recoverable Invocation as EXACTLY ONE OF applied, minted.
WA4: An applied comparison MUST take the allowance at the reading.
WA5: An applied comparison MUST NOT decide a write.
WA6: An applied comparison MAY exclude a record from a pass.
WA7: A minted instant MUST carry the allowance subtracted at the minting.
WA8: A minted instant MAY decide a write.
WA9: A minter MUST NOT mint a fence's instant bare.
WA10: A minter MUST mint EVERY instant independently.
```

Seven clocks meet on this page: the adopter's seam ([Open] step 3), the sweep's seam ([Reconcile]), the operator's seam ([Resolve]), the reader's seam ([Read Invocation]), the substrate's `recorded_at`, the section host's `expires_at`, and — under a declared `commit_fence` — the constituent store's. One allowance covers every pair, set to cover the widest. [Lease](../atoms/lease.md) Invariant 6 owns the minting rule.

**Minted — three instants.**

Terms › `commit_fence deadline`: minted by the section host as the act's `expires_at`, judged by the adopter's constituent store, value `expires_at − clock_skew_allowance`; bound at *Bindings*, §`commit`.

Terms › `journal_fence lease terminus`: minted by the section host as the writer's `expires_at`, judged by the substrate, value `expires_at − clock_skew_allowance`; bound at *Composes*, §`journal_fence`.

Terms › `journal_fence per-write terminus`: minted by the writer's own seam at the write's issue, judged by the substrate, value `issue + journal_write_bound − clock_skew_allowance`; bound at *Composes*, §`journal_fence`.

**Applied — every other cross-seam comparison on this page:** [Open] step 3's age of an open intent; the retention drop on every read of `open_invocations`; [Resolve]'s too-young guard; the `sequence_high_water` advance; the sweep's edges and window; [Read Invocation]'s rebuild.

**Payments.** A minted instant is paid for, and this page owns the payments because the atom refuses to.

```text
WA12: IF commit_fence = declared OR journal_fence = declared THEN condition 3 of instance start MUST charge one clock_skew_allowance.
WA13: The sweep MUST NOT write abandoned BEFORE abandon_edge.
WA14: IF journal_fence = declared THEN the deployment MUST disclose journal_write_bound with clock_skew_allowance of headroom over the substrate's own worst case.
```

Terms › `abandon_edge`: the examine edge plus one further `clock_skew_allowance` — `recorded_at + completion_bound + 2 × clock_skew_allowance`.

Terms › `usable_term`: `completion_bound − clock_skew_allowance` — the term a fenced lease's operations have to finish in.

WHY:
A judge whose clock lags the minter admits, for the lag, a write the minter would call late (`-buggy-skew`, rejected; with clocks in step the bare instant holds, so the skew decides). The margin is required on every instant (`-buggy-perwrite`). One allowance in WA12: both fences pull the same terminus in. WA13 is sweep-to-store, a different pair from the minting's host-to-store. Without WA14 a write taking the full bound is fenced out and retried — safe, an undisclosed liveness cost; the model carries the fence, not the disclosure (Ledger, NOT MODELED).

### Instance start

```text
IS1: This section IS AUTHORITATIVE FOR the conditions of instance start.
NOTE: watch addressable sections (JF2).
IS2: The instance MUST check EVERY condition at start for EVERY bound act kind.
IS3: IF any condition fails for any bound kind THEN the instance MUST NOT start.
```

Terms › `worst_closure`: `completion_bound + 2 × clock_skew_allowance + 2 × reconciliation_cadence + 3 × run_bound` — `completion_bound` the kind's, the rest the instance's, the allowance counted twice for every kind, fenced or not.

Terms › `window_end`: `completion_bound + clock_skew_allowance + compensation_window`.

Terms › `lease_spend`: `2 × read_bound + 2 × journal_write_bound + commit_round_trip`, plus `clock_skew_allowance` ONLY IF the act kind declares `commit_fence` OR the substrate declares `journal_fence` (WA12).

Terms › `run_floor`: `max(completion_bound, closure_latency + journal_write_bound) + closure_latency`.

Terms › `closure_spend`: `read_bound + 2 × journal_write_bound + probe_round_trip`.

```text
IS5: The instance MAY start ONLY IF compensation_window EXCEEDS worst_closure.
IS6: The instance MAY start ONLY IF retention_period EXCEEDS window_end.
IS7: The instance MAY start ONLY IF completion_bound EXCEEDS lease_spend.
IS8: run_floor MUST NOT EXCEED run_bound.
IS9: The instance MAY start ONLY IF closure_latency EXCEEDS closure_spend.
```

Terms › `conditions of instance start`: condition 1 = IS5; condition 2 = IS6; condition 3 = IS7; condition 4 = IS8; condition 5 = IS9; there is no sixth condition on the sweep's lease.

WHY:
*Condition 1's three `run_bound` terms.* A budgeted death involves three runs: the run in flight when the act crossed the examine edge, which read `now` once and may lawfully finish its pass without the act; the run that examines the act and dies; the run that closes it. Two cadences, one after each of the first two. Over 432 parameter tuples the one-term form breaches on 420 and a two-term correction on 396; this form holds on every tuple meeting condition 4, with one tick of slack. The model has no backlog, so it could not catch this.

*Condition 2* keeps the sweep's upper edge outside the window; without it an orphan leaves the sweep's range before its promised window has elapsed, is closed by nobody, and check 7 removes it from checks 1–3.

*Condition 3* charges [Open]'s read and write, the commit, and [Close]'s read and write, all inside one lease; charging one write and the commit passes on `5 s > 4 s` and runs out of lease with the outcome unwritten.

*Condition 4's `max`.* The holder a run waits out may be an invocation (`completion_bound`) or a dead run or operator (`closure_latency + journal_write_bound`); the old floor `2 × closure_latency + journal_write_bound` charged the shorter. Over the same 432 tuples the old floor admits 324 and condition 1 breaches on 15; this one admits 288 and breaches on none.

*Condition 5.* A closure holds one read and two writes; below their sum the run passes the gate for the first write, fails it for the second, and repeats every run.

*No sixth condition.* `max(completion_bound, closure_latency) > closure_latency + journal_write_bound` reduces to `0 > journal_write_bound` whenever `closure_latency` reaches `completion_bound`, so a closure slower than the act's bound could not be configured; the lease is stated directly (`sweep_lease`).

### Primitive policies

```text
PP2: The adopter MUST cap act_key under reference_length_cap.
PP3: The composition MUST write act_key as a composition-written field of EVERY record the composition appends.
PP4: The composition MUST NOT recover act_key from an adopter's payload.
PP6: EVERY record this composition writes for an invocation MUST carry the invocation's invocation_id in the payload.
PP7: EVERY check and EVERY journal join MUST pair on invocation_id and no other field.
PP8: The adopter MUST pass actor_ref and credential through to record_action at the intent record.
PP9: The composition MUST validate actor_ref and credential as non-empty and MUST NOT inspect either.
PP10: The adopter MUST NOT call [Open] BEFORE capping actor_ref under reference_length_cap.
PP11: intent_data MUST carry the invocation's parameters and pairing_datum.
PP12: intent_data MUST NOT carry a field the substrate or the constituent stamps or mints.
PP13: The composition MUST write invocation_id, intent_event_id, kind and act_key into EVERY record the composition appends.
PP14: [Open] MUST size intent_data and the kind's largest record against outcome_envelope and the substrate's payload_cap as the substrate measures a payload.
PP15: [Open] MUST refuse invalid-request for an act whose largest record would not fit.
PP18: An action signature MUST NOT take now.
PP19: [Open] MUST use now for exactly one comparison: step 3's age of an open intent against recorded_at under clock_skew_allowance.
PP20: The composition MUST NOT stamp a record with now.
PP21: The adopter's action MUST carry invocation_id from [Open] into [Close] and [Refuse] as a parameter of each.
PP22: The sweep MUST read now once per run at the sweep's own seam.
```

Terms › `act_key`: opaque, adopter-typed; equality is byte-identity.

Terms › `invocation_id`: injected at the adopter's seam alongside `now`, fresh per invocation, unique across every node of the instance for the journal's lifetime; opaque, byte-identity.

Terms › `now`: the seam-injected reading — at the adopter's seam per invocation, at the sweep's seam once per run, at the operator's seam once per [Resolve] call alongside `operator_run_id`, at the reader's seam once per [Read Invocation] call.

Terms › `operator_run_id`: injected at the operator's seam once per [Resolve] call; the section holder for [Resolve].

Terms › `caller_kind`: EXACTLY ONE OF human, service — service where `actor_ref` names the kind's `service_identity`.

Terms › `examine_edge`: `recorded_at + completion_bound + clock_skew_allowance`.

Terms › `in-flight`: an open intent for which `examine_edge` EXCEEDS `now`.

Terms › `aged`: an open intent for which `now` EXCEEDS `examine_edge` OR `now` = `examine_edge`.

Terms › `horizon_edge`: `recorded_at + retention_period − clock_skew_allowance`.


Terms › `as the substrate measures a payload`: the serialized envelope `{action_ref, actor_ref, attestation_id, data}` with the longer of the caller's and the service identity's `actor_ref`, the substrate's `attestation_id_width`, and the framing. The sweep's two closings — the recovered outcome (`outcome_data` plus `recovery`, `acting_actor_ref`) and the escalation (`store_candidates` plus the same) — are sized separately; the bound is the larger.

WHY:
The four seam-against-stamp comparisons — step 3's age, the retention drop, the too-young guard, the mark advance — all only exclude; the mark advance comes nearest to deciding and is kept safe by the full rebuild at every restart and cadence. The substrate stamps `recorded_at` at its own seam.

```text
RM1: IF position = intent THEN invalid-credential MUST land rejected(invalid-credential) with nothing written.
NOTE: watch position scoping — every rule of this family scopes by IF position = … (RM1–RM19); the corpus's answer is the condition, not a new form.
RM2: IF position = intent THEN [Open] MUST NOT report invalid-request BEFORE reading back by invocation_id.
RM3: WHEN the intent-position read-back finds the record:
    RM3a: The action MUST proceed with a hard alert.
RM4: WHEN the intent-position read-back finds nothing:
    RM4a: The action MUST land rejected(invalid-request).
RM5: IF position = intent THEN recording-failure(step-2 | step-3) MUST land rejected(recording-failure(intent)).
RM6: IF position = intent THEN the action MUST read intent_event_id back for recording-failure(step-4).
RM6a: IF position = intent THEN the action MUST proceed with a hard alert for recording-failure(step-4).
RM7: The action MUST NOT retry after recording-failure(step-4).
RM8: IF position = outcome THEN the action MUST read event_id back by invocation_id for recording-failure(step-4) and for a retention-source invalid-request.
RM8a: IF position = outcome THEN the action MUST return success with a hard alert for recording-failure(step-4) and for a retention-source invalid-request.
RM9: IF position = outcome THEN the writer MUST retry recording-failure(step-2 | step-3) under the section, to the terminus at most.
RM10: A retry that reaches the terminus MUST land rejected(recording-failure(outcome)).
RM11: IF position = outcome THEN invalid-credential MUST land rejected(recording-failure(outcome)).
RM12: The composition MUST treat a record_action whose reply is lost as unknown at every position.
RM13: The composition MUST NOT retry a lost-reply write blind.
RM14: The composition MUST NOT read back a lost-reply write BEFORE journal_write_bound has elapsed since the issue, as remaining reports.
RM15: The composition MUST read back by invocation_id through the filtered range read.
RM16: WHEN the read-back finds the record:
    RM16a: The composition MUST adopt the record.
RM17: WHEN the read-back finds nothing:
    RM17a: The composition MAY retry.
RM18: The composition MUST take the intent's sequence_number and recorded_at from the filtered range read.
RM18a: The composition MUST NOT take the intent's sequence_number and recorded_at from read_record.
RM19: IF position = outcome THEN an invalid-request whose read-back finds nothing MUST land rejected(recording-failure(outcome)) with a hard alert.
```

WHY:
Intent-position `invalid-request` has four sources — the substrate's input check, Actor Identity's, the payload fault, the retention configuration — and only the retention source leaves the intent appended; a retry after `step-4` appends a second intent. At the outcome position the act has committed and no arm can refuse it, only report it. The read-back's completeness rests on Event Log Invariant 5 through Audit Trail Invariant 5 and on read-your-writes (CP7).

### Action wiring

Six actions and one read. [Open], [Close], [Refuse] and [Yield] are called by an adopter's action around the bound commit; [Reconcile] is the sweep, called by the deployment's scheduler and at every restart; [Resolve] is the operator's close; [Read Invocation] is the read.

```text
AW1: EVERY action's signature MUST export the position of every code that could land on more than one side of the commit.
AW2: An adopter MUST export no code for the protocol's sake beyond the table below.
AW3: An adopter's re-entry arm MUST NOT collapse [Read Invocation]'s journal-unavailable into not-known.
AW4: An adopter's action MUST run: validate the adopter's own inputs; [Open]; the bound commit; return.
AW5: The adopter MUST close EVERY constituent guard that fires after the intent (not-current-custodian, already-closed, archived) through [Refuse].
AW6: An adopter's action MUST NOT write to the journal for the act other than through [Open], [Close] and [Refuse].
```

| Source | Code the adopter exports | What the caller does with it |
|---|---|---|
| [Open] | `invalid-credential` | nothing was written anywhere; the credential is the caller's to fix |
| [Open] | `invalid-request` | the act's inputs or its outcome's size; the caller's to fix |
| [Open] | `act-in-flight(invocation_id)` ([Act In Flight]) | another invocation of this act is live or awaiting the sweep; retry later |
| [Open] | `act-landed(outcome_event_id)` ([Act Landed]) | the act is done; take the adopter's own re-entry arm, not a second act |
| [Open] | `section-unavailable` ([Section Unavailable]) | the section could not be taken inside the holder's lease; retry |
| [Open] | `journal-unavailable` ([Journal Unavailable]) | the pre-check's journal read failed; nothing written; retry |
| [Open] | `recording-failure(intent)` ([Recording Failure]) | the intent record did not land; nothing committed; the whole action may be retried |
| the bound `commit`'s pre-commit partition | the constituent's own code, after [Refuse] has landed the refusal | the act was refused and the attempt is recorded |
| [Refuse] | `already-accounted(closing_event_id)` ([Already Accounted]) | another writer already closed this invocation; report the act as accounted for, do not re-run |
| [Refuse] | `recording-failure(refusal, constituent_code)` | the refusal record did not land; the sweep records the attempt instead; never re-run the act |
| the `unknown` partition, after [Yield] | `recording-failure(outcome)` | the act may exist; its record is the sweep's; never re-run |
| [Close] | `recording-failure(outcome)` | the same |

[Resolve]'s codes are the operator's; [Reconcile]'s `journal-unavailable` goes to the scheduler. [Read Invocation] is not in the table because it is not called around the commit; it answers `journal-unavailable` (the act's state unreadable for now) and `not-known` ([Not Known] — no readable intent), and AW3 keeps a re-entry arm from re-running an irreversible act whose record is sitting in the journal.

---

#### `open`

```
open(kind, act_key, actor_ref, credential, intent_data) →
    {invocation_id, intent_event_id}
  | rejected(
      invalid-credential
    | invalid-request
    | act-in-flight(invocation_id)
    | act-landed(outcome_event_id)
    | section-unavailable
    | journal-unavailable
    | recording-failure(intent)
    )
```

Opens one invocation of the act: takes the section, sizes the records, writes the intent record — where the caller's credential is verified — and returns the pair the adopter carries through the commit to [Close].

Steps:

1. **Validate and size.**
   ```text
   OP1: [Open] MUST validate act_key, actor_ref and credential non-empty per Primitive policies.
   OP2: IF caller_kind = service THEN [Open] MUST land rejected(invalid-request).
   OP3: [Open] MUST size intent_data and the kind's largest record per PP14.
   OP3a: IF the sized record EXCEEDS the cap THEN [Open] MUST land rejected(invalid-request).
   OP4: A step-1 refusal MUST write nothing.
   ```
2. **Take the act's section.**
   ```text
   OP5: [Open] MUST take the section: take((kind, act_key), invocation_id, completion_bound).
   OP6: The take MUST NOT block longer than the current holder's remaining lease.
   OP7: A failed take MUST land rejected(section-unavailable) with nothing written.
   ```
3. **Pre-check under the section.**
   ```text
   OP8: [Open] MUST re-read the journal from sequence_high_water for the act_key under the section.
   OP8a: [Open] MUST take open_invocations at (kind, act_key) from the re-read.
   OP9: Step 3 MUST NOT decide from a local map hit.
   OP10: [Open] MUST release for an in-flight open intent.
   OP10a: [Open] MUST land rejected(act-in-flight(invocation_id)) for an in-flight open intent.
   OP11: IF service_identity != none THEN [Open] MUST release for an aged open intent.
   OP11a: IF service_identity != none THEN [Open] MUST land rejected(act-in-flight(invocation_id)) for an aged open intent.
   OP12: WHEN service_identity = none:
       OP12a: [Open] MUST proceed past an aged open intent.
       OP12b: [Open] MUST leave the old intent open.
       OP12b1: [Open] MUST surface the old intent on compliance_surface.
       OP12b2: An operator MUST close the old intent through [Resolve].
       OP12c: The new invocation's records MUST pair on the new invocation_id.
   OP13: WHEN repeatable = no:
       OP13a: [Open] MUST read the act's latest outcome from act_closings.
       OP13b: IF an outcome for the act_key EXISTS THEN [Open] MUST release.
       OP13b1: IF an outcome for the act_key EXISTS THEN [Open] MUST land rejected(act-landed(outcome_event_id)).
   OP14: [Open] MUST bound the step-3 read by read_bound.
   OP15: An [Open] whose read exhausts the lease MUST release.
   OP15a: An [Open] whose read exhausts the lease MUST land rejected(section-unavailable) with nothing written.
   OP16: WHEN the step-3 read fails:
       OP16a: [Open] MUST release.
       OP16b: [Open] MUST land rejected(journal-unavailable) with nothing written.
   ```
4. **Intent record.**
   ```text
   OP17: IF journal_write_bound EXCEEDS remaining THEN [Open] MUST NOT write the intent record.
   OP18: WHEN journal_write_bound EXCEEDS remaining:
       OP18a: [Open] MUST release.
       OP18b: [Open] MUST land rejected(section-unavailable).
   OP19: [Open] MUST write AuditTrail.record_action(action_ref = <kind>.intended, actor_ref, credential, data = intent payload) → intent_event_id.
   OP20: Step 4's arms MUST follow the intent position of the rejection-mapping rule.
   ```
5. **Populate and return.**
   ```text
   OP21: [Open] MUST populate open_invocations at (kind, act_key) with the intent.
   OP21a: [Open] MUST return {invocation_id, intent_event_id}.
   OP22: [Open] MUST hold the section at return.
   ```

WHY:
The service identity closes acts and never opens them (check 5). Step 3 reads the journal because on a multi-node instance a local absence is not a miss. OP10 protects pairing, not Invariant 2: two acts of one `act_key` in flight carry `pairing_datum` values `probe` cannot tell apart (Invariant 3). OP12's several open intents are the report-only deployment's declared degradation, not a `binding_duplicate`; blocking every crashed act's key until purge would trade one orphan for an unusable key. OP13 reads `act_closings` because the delta begins above the mark; the constituent's own `already-*` arm is the authoritative guard. OP16: the cheapest conforming implementation reads a failed range read as empty and appends a second live intent. OP20's `invalid-credential` is the seam at which authentication precedes commitment (Invariant 1).

---

#### `close`

```
close(kind, act_key, invocation_id, intent_event_id, actor_ref, credential,
      outcome_action_ref, outcome_data) →
    {outcome_event_id, landed_by: invocation | sweep | operator}
  | rejected(
      not-open
    | recording-failure(outcome)
    )
```

Writes the act's outcome record after the bound commit has returned, under the section [Open] took, and releases the section. The one action that can find its own work already done.

```text
CL1: The adopter MUST pass [Close] the actor_ref [Open] was given for the invocation.
CL2: The composition MUST NOT retain state between [Open] and [Close].
CL3: [Close] and [Refuse] MUST take intent_event_id.
CL4: [Close] MUST decide not-open from the invocation's own [Open] result ([Not Open]).
```

Steps:

1. **Confirm standing.**
   ```text
   CL5: [Close] MUST query remaining((kind, act_key), invocation_id).
   CL6: WHEN journal_write_bound EXCEEDS remaining OR remaining = none:
       CL6a: [Close] MUST write nothing.
       CL6b: [Close] MUST discard the commit's reply.
       NOTE: watch negative capability — an obligation to discard a reply already in hand (CL6b, AS14c).
       CL6c: [Close] MUST return rejected(recording-failure(outcome)).
   CL7: Step 1 MUST NOT vary with retry_terminus.
   ```
2. **Pre-check under the section — proceed as landed.**
   ```text
   CL8: [Close] MUST re-read the journal from sequence_high_water for the invocation_id under the section.
   CL9: WHEN a closing record naming the invocation_id is an outcome:
       CL9a: [Close] MUST adopt the outcome as the invocation's own.
       CL9b: [Close] MUST release.
       CL9b1: [Close] MUST return {outcome_event_id, landed_by}.
       CL9b2: IF the outcome carries resolved_by THEN [Close] MUST return landed_by = operator.
       CL9b3: IF the outcome carries no resolved_by THEN [Close] MUST return landed_by = sweep.
   CL10: WHEN a closing record naming the invocation_id is an abandonment OR an escalation:
       CL10a: [Close] MUST NOT adopt the record.
       CL10b: [Close] MUST release and return rejected(recording-failure(outcome)).
   CL11: WHEN the step-2 re-read fails:
       CL11a: [Close] MUST write nothing.
       CL11b: [Close] MUST return rejected(recording-failure(outcome)).
   CL12: Step 2 MUST run under every journal_fence value.
   ```
3. **Outcome record.**
   ```text
   CL13: [Close] MUST write AuditTrail.record_action(action_ref = outcome_action_ref, actor_ref, credential, data = outcome payload) → outcome_event_id.
   CL14: Step 3's arms MUST follow the outcome position of the rejection-mapping rule.
   CL15: A non-retention invalid-request at step 3 MUST land rejected(recording-failure(outcome)) with a hard alert.
   CL16: [Close] MUST NOT retry after recording-failure(step-2 | step-3) or a lost reply BEFORE re-running step 2.
   CL17: IF journal_write_bound EXCEEDS remaining THEN [Close] MUST NOT retry.
   CL18: WHEN retry_terminus = counted(n):
       CL18a: [Close] MAY retry at most n attempts.
   CL19: A retry cut short by the lease or the last attempt MUST land release and rejected(recording-failure(outcome)).
   CL20: An invalid-credential at step 3 MUST land release and rejected(recording-failure(outcome)).
   ```
4. **Clear and release.**
   ```text
   CL21: [Close] MUST remove the invocation_id from open_invocations at (kind, act_key).
   CL21a: [Close] MUST release the section.
   CL21b: [Close] MUST return {outcome_event_id, landed_by = invocation}.
   ```

WHY:
Check 2 reads an outcome without `recovery` whose `actor_ref` differs from its intent's as a conformance failure (CL1). Every route from an id to an `event_id` reads the intent's payload, which [Resolve] takes an argument to avoid (CL3). CL6 cannot tell a yielded invocation from one never opened; step 0 is the caller's precondition. CL10: an abandonment or escalation says the act was not accounted for, and the correction is [Resolve]'s `supersedes` path. CL11 lands on the position's own arm because the act has committed and the caller's next move is fixed. Step 2 under a fence cannot land a write; without one it is load-bearing — a paused invocation passes step 1, wakes after the sweep closed the act, and the re-read stops a second outcome — and still a mitigation, since a pause between step 2 and the write appends beside the sweep's record (JN3). CL15's act is escalated as `outcome-unrecordable`.

---

#### `refuse`

```
refuse(kind, act_key, invocation_id, intent_event_id, actor_ref, credential,
       reason, constituent_code) →
    {refusal_event_id}
  | rejected(
      not-open
    | already-accounted(closing_event_id)
    | recording-failure(refusal, constituent_code)
    )
```

Closes an intent whose bound commit did not commit — the constituent refused on a pre-commit arm — so the intent does not stand open for the sweep to probe.

Steps:

0. **Not open.**
   ```text
   RF1: [Refuse] MUST decide not-open from the invocation's own [Open] result ([Not Open]).
   RF1a: [Refuse] MUST write nothing for a pair no [Open] returned.
   NOTE: watch rule inheritance — RF1 and RF5 restate [Close]'s CL4 and CL8 for [Refuse] rather than inheriting; the grammar has no inheritance form.
   ```
1. **Confirm standing, before any read.**
   ```text
   RF2: [Refuse] MUST NOT read BEFORE querying remaining((kind, act_key), invocation_id).
   RF3: WHEN journal_write_bound EXCEEDS remaining OR remaining = none:
       RF3a: [Refuse] MUST write nothing.
       RF3b: [Refuse] MUST return rejected(recording-failure(refusal, constituent_code)).
   RF4: A yielded caller MUST NOT read at [Close] or [Refuse].
   RF4a: A yielded caller MUST NOT adopt at [Close] or [Refuse].
   ```
2. **Re-read under the section.**
   ```text
   RF5: [Refuse] MUST re-read the journal from sequence_high_water for the invocation_id under the section.
   RF6: IF a closing record naming the invocation_id EXISTS THEN [Refuse] MUST land rejected(already-accounted(closing_event_id)).
   RF6a: IF a closing record naming the invocation_id EXISTS THEN [Refuse] MUST append nothing.
   RF7: [Refuse] MUST NOT report already-accounted as not-open.
   ```
3. **Refusal record.**
   ```text
   RF8: [Refuse] MUST write <kind>.refused with {invocation_id, intent_event_id, kind, act_key, reason, constituent_code} under the caller's credential.
   RF9: The refusal record's arms MUST follow the intent position.
   RF9a: [Refuse] MUST read the refusal back by invocation_id for recording-failure(step-4) and for a retention-source invalid-request.
   RF9b: [Refuse] MUST NOT retry after step-4 or the retention-source invalid-request.
   RF10: recording-failure(step-2 | step-3) MUST land rejected(recording-failure(refusal, constituent_code)) with the intent left open.
   RF10a: A lost reply whose one read-back finds nothing MUST land rejected(recording-failure(refusal, constituent_code)) with the intent left open.
   RF10b: invalid-credential MUST land rejected(recording-failure(refusal, constituent_code)) with the intent left open.
   RF10c: A non-retention invalid-request MUST land rejected(recording-failure(refusal, constituent_code)) with the intent left open.
   RF11: [Refuse] MUST clear the map.
   RF11a: [Refuse] MUST release the section.
   RF12: The composition MUST NOT suppress a refusal record.
   ```

WHY:
Read before `remaining` and a lease-expired invocation reports `already-accounted` for a closing it had no standing to observe. A refusal that never lands leaves the intent open; the sweep writes the abandonment or escalation without the constituent's `reason`, which died with the invocation — so `recording-failure(refusal, constituent_code)` means the attempt is recorded by the sweep instead, never a reason to re-run, and the second slot tells the caller why.

---

#### `yield`

```
yield(kind, act_key, invocation_id) → ok
```

```text
YD1: [Yield] MUST release the section without writing.
YD2: The adopter's action MUST call [Yield] on the unknown partition.
YD3: No adopter MAY touch act_section directly.
YD4: [Yield] MUST NOT close the intent.
```

---

#### `resolve`

```
resolve(kind, act_key, invocation_id, intent_event_id, actor_ref, credential,
        disposition) →
    {closing_event_id}
  | rejected(
      already-accounted(closing_event_id)
    | not-known
    | section-unavailable
    | invalid-credential
    | invalid-request(purged | malformed | too-young | already-abandoned
                    | candidates-over-cap)
    | recording-failure(resolution)
    )
```

The human-attested close: an operator closes an open intent the sweep cannot — under `service_identity = none`, or for an escalated act the operator has investigated — supplying the disposition the operator's own run of the adopter's `probe` supports.

```text
RS1: The operator MUST supply disposition as EXACTLY ONE OF outcome(outcome_action_ref, outcome_data), abandoned(cause), escalated(candidates).
RS2: The substrate MUST validate the operator's credential at the closing record_action and nowhere earlier.
RS3: A credential failure MUST land rejected(invalid-credential) with the section released and nothing appended.
RS4: [Resolve] MUST take the section: take((kind, act_key), operator_run_id, sweep_lease).
RS4a: The take MUST NOT block longer than the holder's remaining lease.
RS5: A failed take MUST land rejected(section-unavailable).
RS6: IF journal_write_bound EXCEEDS remaining THEN [Resolve] MUST NOT write.
RS7: [Resolve] MUST re-read the act's records under the section.
RS8: An outcome or a refusal naming the invocation_id MUST land rejected(already-accounted(closing_event_id)).
RS9: An invocation_id with no readable intent record MUST land rejected(not-known).
RS10: [Resolve] MUST read the intent by read_record(intent_event_id).
RS11: An intent whose payload the substrate reports Purged MUST land rejected(invalid-request(purged)).
RS12: EVERY closing [Resolve] writes over an existing record MUST carry supersedes = that record's event_id.
RS13: WHEN no closing stands:
    RS13a: [Resolve] MAY write any disposition as the act's closing.
RS14: WHEN an escalated record stands:
    RS14a: [Resolve] MUST name the record in supersedes for any disposition.
RS15: WHEN an abandoned record stands:
    RS15a: [Resolve] MAY supersede the record ONLY IF disposition = outcome.
RS16: An abandoned disposition over an abandoned record MUST land rejected(invalid-request(already-abandoned)).
RS18: An abandoned disposition for an in-flight intent MUST land rejected(invalid-request(too-young)).
RS19: The too-young guard MUST compare against now injected at the operator's seam.
RS20: WHEN commit_fence = none:
    RS20a: [Resolve] MUST admit the operator's abandoned disposition as the operator's attestation that the store has been quiet for as long as the operator's judgment requires.
RS21: [Resolve] MUST write the closing record under the operator's own credential with recovery = true, resolved_by = actor_ref, acting_actor_ref = the intent's actor_ref, and no recovery_intended.
RS22: [Resolve] MUST release after the write.
RS23: The closing write's arms MUST follow the outcome position.
RS23a: After step-4 or the retention-source invalid-request, [Resolve] MUST read the record back by invocation_id and return success with a hard alert.
RS23b: [Resolve] MUST NOT retry after step-4 or the retention-source invalid-request.
RS24: step-2 | step-3, and a lost reply after an empty read-back, MUST land rejected(recording-failure(resolution)).
RS26: invalid-request MUST carry the cause: malformed, candidates-over-cap, purged, already-abandoned, too-young.
RS27: A candidate list exceeding intent_candidates_cap MUST land rejected(invalid-request(candidates-over-cap)).
```

WHY:
Audit Trail projects no read that validates a credential without appending, so validation before the take had no call to make; both substitutes broke it (an early `record_action` appends before the section; a direct `attest` mints an orphan attestation on every typo). RS10 is why [Resolve] takes `intent_event_id`: every route from an `invocation_id` to an `event_id` reads the payload the purge destroyed, and without the id a lawfully destroyed record answers `not-known`. `resolved_by` names the operator, not a record; without RS12 a lawful resolution read as a `binding_duplicate` (`-buggy-supersede`, rejected). The transitive rule is a prose repair the model does not confirm. RS19: a reading nothing bounds must not decide a destructive record (`-buggy-opclock` violates Invariant 5 against `probe-reportonly-clean`). RS23: a retry after `step-4` appends the duplicate in a deployment that has the fence and needs no pause to do it. RS26: the five causes imply three moves — fix and retry, nothing to do, wait and re-issue unchanged.

---

#### `reconcile`

```
reconcile() →     \* the only action with no `kind`: it sweeps every bound one
    {examined, closed, abandoned, escalated, reported, skipped, closed_already,
     surfaced, unreached}
  | rejected(journal-unavailable)
```

The sweep. Runs at every process restart and on `reconciliation_cadence`; reads `now` once at the sweep's own seam.

```text
RC1: WHEN step 1's enumeration fails:
    RC1a: The run MUST write nothing.
    RC1b: The run MUST open or advance the instance finding journal-unavailable on compliance_surface.
    RC1c: The run MUST return rejected(journal-unavailable).
RC10: WHEN service_identity = none for the act's kind:
    RC10a: The run MUST take the section.
    RC10a1: The run MUST run probe under the section.
    RC10a2: The run MUST release the section.
    RC10b: The run MUST NOT write for the act.
    RC10c: The run MUST report every closing step's result on compliance_surface.
    RC10d: The run MUST count the act in reported.
RC11: A run over a mixed instance MUST close the kinds that declare a service_identity.
RC11b: A run over a mixed instance MUST report the kinds that declare no service_identity.
RC11a: The run MUST sum the counts over both.
```

Terms › `examined`: an act step 1 kept and the run reached — took, or attempted to take, the act's section.

Terms › `partition`: `closed + abandoned + escalated + reported + skipped + closed_already = examined`.

Terms › `surfaced`: the unbound-kind intents step 1 reports; outside the partition.

Terms › `unreached`: the acts step 1 kept that the run stopped short of after the service identity's credential was refused; outside the partition.

Terms › `closed_already`: an act step 2's re-read finds another writer closed since step 1.

Terms › `skipped`: an act the run examined and left for the next run — a failed take; a probe answering unavailable; a closing write whose retries the lease cut short; a closing write left for the next run after step 3 counted the act; an act whose remaining fell below journal_write_bound at step 2 before any write; an act the fence refused a write for while the intent was short of abandon_edge. The list is exhaustive.

Terms › `reported`: an act of a service_identity = none kind the run examined.

WHY:
Without RC1 a journal outage returns zero counts and step 5 surfaces nothing, silently suppressing the at-risk report the window rests on. `surfaced` and `unreached` sit outside the partition because neither act was examined; counting either inside broke the identity. A persistently high `closed_already` says the run is racing another run or an operator. `reported` is in the partition because the run examined the act, and not `skipped` because an operator, not a later run, will close it.

1. **Enumerate between two edges.**
   ```text
   RC12: The run MUST rebuild open_invocations and act_closings from the substrate's range read.
   RC13: The run MUST keep EVERY aged intent for which horizon_edge EXCEEDS now, and no other intent.
   NOTE: watch applicability — the pass's domain is carried by a relative clause (RC13); the corpus has no WHERE.
   RC14: The run MUST make RC13's comparison from the sweep's seam reading against the substrate's stamp, under clock_skew_allowance.
   RC15: The run MUST keep every closing record in the delta for step 5.
   RC15a: The run MUST discard the kept closing records with the run.
   RC16: Step 1 MUST surface EVERY unbound-kind intent per BD4–BD6.
   ```
2. **Take the act's section and re-read.**
   ```text
   RC17: The run MUST take the section for each kept intent: take((kind, act_key), run_id, sweep_lease).
   RC17a: The take MUST NOT block longer than the current holder's remaining lease.
   RC18: A take that fails after the wait MUST count the act in skipped and surface the act in step 5.
   RC19: Under the section, the run MUST re-read open_invocations at (kind, act_key) and sweep_closed_ids.
   RC20: IF a closing record naming the invocation_id landed since step 1 THEN the run MUST release.
   RC20a: IF a closing record naming the invocation_id landed since step 1 THEN the run MUST count the act in closed_already.
   NOTE: RC21 deleted after CR-7; JW1 owns the rule.
   RC22: WHEN journal_write_bound EXCEEDS remaining:
       NOTE: RC22a deleted after CR-7; JW1 owns the rule.
       RC22b: The run MUST count the act in skipped.
   ```
3. **Probe the store.**
   ```text
   RC23: The run MUST call the adopter's bound probe(act_key, intent payload).
   RC24: WHEN probe = committed(outcome_action_ref, outcome_data):
       RC24a: The run MUST write <kind>.recovery_intended under the service identity with data = {invocation_id, intent_event_id, act_key, plan = outcome}.
       RC24b: The run MUST write the outcome record outcome_action_ref under the service identity with data = recovered outcome payload.
       RC24c: The run MUST count closed.
   RC25: A later run MAY write a second recovery_intended for the act.
   RC26: WHEN probe = not-committed AND commit_fence = declared AND the intent is past abandon_edge:
       RC26a: The run MUST write <kind>.abandoned under the service identity with data = {invocation_id, intent_event_id, act_key, cause = not-committed}.
       RC26b: The run MUST count abandoned.
   RC27: WHEN probe = not-committed AND commit_fence = none:
       RC27a: The run MUST write <kind>.escalated with cause = not-observed.
       RC27b: The run MUST count escalated.
   RC28: WHEN probe = not-committed AND commit_fence = declared AND the intent is short of abandon_edge:
       RC28a: The run MUST write nothing.
       RC28b: The run MUST count skipped.
   RC29: The sweep MUST NOT re-run an act.
   RC30: WHEN probe = undecidable(candidates):
       RC30a: The run MUST write <kind>.escalated under the service identity with data = {invocation_id, intent_event_id, act_key, cause = undecidable, store_candidates = candidates}.
       RC30b: The run MUST surface the act on compliance_surface.
       RC30c: The run MUST count escalated.
   RC31: store_candidates MUST NOT carry more than intent_candidates_cap references.
   RC31a: Past the cap, the escalated record MUST carry the count and the range.
   RC32: The sweep MUST NOT choose among candidates.
   RC33: The sweep MUST NOT write an outcome the sweep did not read.
   RC34: WHEN probe = unavailable:
       RC34a: The run MUST write nothing.
       RC34b: The run MUST release and count skipped.
       RC34c: The run MUST open or advance the instance finding store-unavailable for the act's kind.
   RC35: The sweep MUST NOT write abandoned for a store outage.
   RC36: EVERY closing write's arms MUST follow the outcome position.
   RC36a: After step-4 or the retention-source invalid-request, the run MUST read the record back.
   RC36b: The run MUST leave a step-2 | step-3 arm not landed within the lease for the next run.
   RC37: The run MUST surface an invalid-credential for the service identity on compliance_surface at once.
   RC37a: The run MUST NOT write further under the credential until reconfigured.
   RC38: A non-retention invalid-request on a closing write MUST close the act as <kind>.escalated with cause = outcome-unrecordable.
   ```
4. **Update and release.**
   ```text
   RC39: The run MUST update open_invocations.
   RC39a: The run MUST update act_closings.
   RC39b: The run MUST update sweep_closed_ids.
   RC39c: The run MUST release the section.
   ```
5. **Liveness, and the duplicate scan.**
   ```text
   RC40: IF intent_age EXCEEDS at_risk_threshold OR intent_age = at_risk_threshold THEN the run MUST surface an examined or skipped intent whose closing has not landed as the act finding closure-at-risk.
   RC41: The run MUST count closing records by invocation_id across the delta step 1 kept, discounting supersession per §Which closing stands.
   RC42: The run MUST count open intents by (kind, act_key) across the delta, under §Which closing stands' service_identity = none branch.
   RC43: The run MUST surface EVERY invocation_id or (kind, act_key) with more than one on compliance_surface as binding_duplicate.
   RC44: The duplicate scan MUST run over the delta.
   RC44a: The duplicate scan MUST NOT run over the horizon.
   RC45: The duplicate scan MUST run under every journal_fence value.
   RC46: The run MUST return the counts.
   ```

Terms › `at_risk_threshold`: `compensation_window − 2 × run_bound − reconciliation_cadence − clock_skew_allowance`.

Terms › `intent_age`: `now − recorded_at`.

WHY:
Below the examine edge the invocation may still hold its lease and a take would wait on a live act, which the cadence does not budget; the second writer is forbidden by the section, not the edge (the model holds with the edge removed at zero skew). The upper edge is an inequality because the direction of the allowance decides whether an intent whose closings may already be purge-eligible is examined; a re-close past it would be the duplicate. RC26 is final only under a fence past the abandon edge; RC27's `not-observed` is the honest degree for a fenceless store, where a paused process may still land the write. RC34's per-act count carries no span; the instance finding does. RC38: an outcome that outgrew the envelope cannot shrink, and the escalation record fits.

`at_risk_threshold` is Invariant 4's inequality rearranged: subtract the terms still ahead of an intent this run can see — this run's remaining pass, a cadence, the next run's pass, the allowance — and leave out the terms already spent. The scan rides the delta because a duplicate is made by a record landing and every duplicate appears in exactly one run's delta; with the fence a finding is a conformance failure in the fence itself, without it the scan is the degraded Invariant 2's detection clause.

```text
RC47: An actor that is not a writer MUST NOT write a closing record.
RC48: Two sweep runs MUST serialize on the section per act and on sweep_closed_ids under the section.
```

---

#### `read_invocation`

```
read_invocation(kind, act_key, invocation_id?) →
    {invocations: sequence of {invocation_id,
                               state: open | closed | refused | abandoned | escalated | resolved,
                               binding_duplicate: true | false,   \* the entry's: two closings on this id
                               records, more},
     binding_duplicate: true | false,   \* the act's: two open intents on this key
     more}
  | rejected(not-known)
  | rejected(journal-unavailable)
```

Reads the act's invocations — each intent and whichever closing record names it — through the same rebuild, for an adopter's re-entry arm and for an auditor.

```text
RD1: [Read Invocation] MUST perform the rebuild under now injected at the reader's own seam.
RD2: [Read Invocation] MUST return one entry per invocation_id, at most read_cap of the most recent, with more = true where the act has older ones.
RD3: WHEN invocation_id is given:
    RD3a: [Read Invocation] MUST return one entry.
RD4: records MUST carry the intent, the recovery_intended records and the closing records.
RD4a: [Read Invocation] MUST cap the recovery_intended records and the closing records at the most recent read_cap, with more = true beyond.
RD5: [Read Invocation] MUST NOT exclude a superseded record from records.
RD6: The entry-level binding_duplicate MUST report the closings key.
RD7: The act-level binding_duplicate MUST report the intents key.
RD8: WHEN service_identity = none:
    RD8a: The act-level binding_duplicate MUST read false.
RD9: [Read Invocation] MUST read the entry's state from §Which closing stands' table.
RD10: [Read Invocation] MUST transcribe the range read's unavailable arm as journal-unavailable.
RD11: [Read Invocation] MUST answer not-known for an act_key with no readable intent.
RD12: [Read Invocation] MUST NOT take a section.
RD12a: [Read Invocation] MUST NOT write.
RD13: An adopter that decides a write on [Read Invocation]'s answer MUST decide the write under the section through [Open]'s pre-check.
```

WHY:
The rebuild's comparisons are against the substrate's stamps, so the reader is a seam (RD1). Closings are capped because the degraded Invariant 2 admits them in plurality. Without RD10 the cheapest implementation answers `not-known` for a key whose intent and outcome are sitting in the journal. RD11 is also what a wholly purged act answers — the destroyed payload carried the key — the one admitted exception to §*Lawful destruction is answered before absence*; `read_record` by `event_id` still answers *Purged*.

---

### Which closing stands

One act may carry more than one closing record; a [Binding Duplicate] is what is left over once supersession is read.

```text
WC1: This section IS AUTHORITATIVE FOR which of an act's closing records is the act's.
NOTE: watch addressable sections (JF2).
WC2: A closing record MAY supersede another closing record ONLY IF the closing record names the other in supersedes.
WC3: resolved_by MUST NOT trigger supersession.
WC4: EVERY surface MUST read supersession transitively.
WC6: EVERY surface MUST count the standing closing and every record reachable from the standing closing through supersedes as one closing.
WC7: An act MAY carry the closings key ONLY IF two closings each supersede nothing AND are superseded by nothing.
WC8: Among unsuperseded closings, the lowest sequence_number MUST stand.
WC9: Position MUST NOT decide against a name.
WC10: [Read Invocation] and [Reconcile] step 5 MUST report two open intents on one (kind, act_key) as the intents key on the act.
WC11: A surface MAY report the intents key ONLY IF the act kind declares a service_identity.
WC12: A surface MUST report the closings key under every binding.
```

Terms › `standing closing`: the closing no other closing names.

Terms › `closings key`: two unsuperseded closings on one `invocation_id`; carried on the entry.

Terms › `intents key`: two open intents on one `(kind, act_key)`; carried on the act.


WHY:
Four surfaces need the answer and for two rounds each carried its own; transitive at one, pairwise at three, and a lawful correction read as a duplicate. Chains occur: a sweep escalates, an operator abandons naming it, check 6 shows the abandonment false, a second [Resolve] writes an outcome naming the abandonment — pairwise, the middle record belongs to two pairs. WC11: OP12 instructs a report-only deployment to leave an old intent open, so an unbranched second key reports this page's own instruction as a conformance failure. WC12: no report-only instruction produces two closings.

**Which `state` a standing closing projects.**

Terms › `state projection`: no standing closing → `open`; an outcome record `<kind>.<outcome>` → `closed`; `<kind>.refused` → `refused`; `<kind>.abandoned` without `resolved_by` → `abandoned`; `<kind>.abandoned` with `resolved_by` → `resolved`; `<kind>.escalated` → `escalated`.

An `escalated` entry becomes `resolved` when an operator's abandonment names it, and `closed` when any outcome names it. `resolved` is reserved for the case where a human's judgement is the only thing that closed an act and the act did not happen; an operator's outcome is `closed`. The `abandoned` split is the one check 6 reads: the sweep's abandonments are tested against `probe`, the operator's are exempt, and `resolved_by` separates them at both surfaces.

*Cited by:* [Read Invocation]'s `state` and both `binding_duplicate` fields; [Reconcile] step 5; Generation acceptance check 2; Invariant 2. None restates it.

### The load-bearing wiring decision — one act, one writer, one closer

WHY:
An irreversible act and its account are two writes no transaction spans, and closing the partial after the opening process is dead is a second writer by definition. The protocol is sound exactly when the two writers cannot both write for one act, the second cannot mistake in-flight work for a dead invocation's, and the second cannot write what it did not read — properties of the section, the edges and the probe, none of the adopter's act. A methodology rule does not stop twenty authors writing it twenty ways or spare the formal layer twenty models; the higher-order composition test's threshold is five exact instances and this clears it several times over ([`tools/survey/protocol_prose.py`](../tools/survey/protocol_prose.py)). What differs between adopters is the binding set; anything else is a deviation from a closed list. One page carries the protocol, one model proves it, one gate attacks it; an adopter's action shrinks to *validate, open, commit, close*.

---

## Composition-level invariants

- **Invariant 1 — Authentication precedes commitment.**
  ```text
  IV1: An invocation MUST NOT reach the bound commit BEFORE the substrate has validated the caller's credential for actor_ref inside [Open]'s intent record.
  IV2: invalid-credential MUST land as a pre-state refusal with nothing written.
  ```
  *Rests on:* Audit Trail's `record_action` and the Actor Identity attestation reached through it (Audit Trail Invariant 1); [Open] step 4 before the adopter's commit. *Defended in-line:* the ordering [Open] → commit → [Close] in every adopter; Generation acceptance check 1 tests it from the records alone.

- **Invariant 2 — One writer per act.**
  ```text
  IV3: IF journal_fence = declared THEN two closing records MUST NOT name one intent's invocation_id.
  IV4: EXACTLY ONE writer MUST write the closing record, under the act's section.
  IV5: Two sweep runs MUST NOT close one act.
  IV6: IF journal_fence = none THEN two unsuperseded closing records MUST NOT name one invocation_id at quiescence.
  IV6a: PROVISIONAL: IV3 DEGRADES TO IV6.
  IV7: §Which closing stands IS AUTHORITATIVE FOR which closing is the act's.
  NOTE: watch addressable sections (JF2).
  ```
  *Rests on:* `act_section` (Configuration) with lease-as-terminus semantics; the `journal_fence` (Composes) with its margin and per-write instant; the return-based read-your-writes clause (CP7); [Close] step 2's proceed-as-landed; [Reconcile] step 2's re-read under the section and `sweep_closed_ids`. *Defended in-line:* the load-bearing wiring decision; the model's six rejected twins bearing on this invariant — `-buggy-death`, `-buggy-reread`, `-buggy-journal`, `-buggy-visible`, `-buggy-skew`, `-buggy-perwrite` — each landing two closings for one act; a seventh, `-buggy-supersede`, lands two unsuperseded closings by omitting the name from a resolution over an escalation.

  WHY: the four closing kinds count together because each closes the act; quantified over outcomes alone, an escalation and an outcome coexisted. Under `service_identity = none` the operator and a second live invocation are kept apart by the section alone, which is why [Resolve] takes it.

- **Invariant 3 — Pairing is by the seam-injected key in the journal, and by the bound datum in the store.**
  ```text
  IV8: EVERY record this composition writes for an invocation MUST carry the invocation's invocation_id.
  IV9: EVERY check and EVERY journal join MUST pair on invocation_id and no other field.
  IV10: probe MUST make the intent-to-record join on pairing_datum by equality.
  IV10a: probe MUST NOT pair on a stamp within a window.
  IV11: WHEN pairing_datum = none OR pairing_datum matches more than one record:
      IV11a: The sweep MUST name candidates and close nothing.
  ```
  *Rests on:* the seam injection (Primitive policies); Event Log Invariant 2 through Audit Trail Invariant 5 (an appended payload is immutable); the `pairing_datum` binding.

- **Invariant 4 — Bounded closure (safety + liveness).**
  ```text
  IV12: The records alone MUST reveal EVERY act whose invocation has yielded or died, as an aged intent with no record naming the intent's invocation_id.
  IV13: IF the journal and the adopter's store are reachable THEN a writer MUST close EVERY aged intent by an outcome, an abandoned record or an escalation WITHIN compensation_window of the intent's recorded_at.
  IV15: WHEN the journal is unreachable:
      IV15a: A writer MUST NOT close the intent during the outage.
      IV15b: [Open] MUST refuse the key journal-unavailable for the outage's duration.
  IV16: [Reconcile] MUST surface a journal outage as the instance finding journal-unavailable, never as the outage's intents.
  IV17: The outage finding MUST carry the outage's start and end.
  IV18: IF service_identity = none THEN a writer MUST report EVERY aged intent as closure-at-risk WITHIN compensation_window, for an operator to close through [Resolve].
  IV18a: PROVISIONAL: IV13 DEGRADES TO IV18.
  IV19: IF commit_fence = none THEN the sweep MUST escalate an act the store cannot certify as not-committed.
  IV19a: IF commit_fence = none THEN the sweep MUST NOT abandon the act.
  IV19b: PROVISIONAL: the abandoned arm DEGRADES TO escalated.
  ```
  *Rests on:* [Reconcile]'s edges and steps 3–5; the kind's `completion_bound` and `retention_period`; the instance's `clock_skew_allowance`, `reconciliation_cadence`, `run_bound`, `closure_latency`, `read_bound`, `journal_write_bound` and `compensation_window`; the substrate's range read.

  WHY: during a journal outage no intent is enumerable, so per-intent evidence cannot exist; `act-in-flight` cannot be the outage's code because reading its payload is what failed.

- **Invariant 5 — Recovery is derived, never remembered.**
  ```text
  IV20: The sweep MUST NOT write an outcome BEFORE writing one or more <kind>.recovery_intended records naming the act and the plan.
  IV20a: EVERY outcome the sweep writes MUST carry the service identity's attestation with the original caller in acting_actor_ref.
  IV20b: EVERY outcome the sweep writes MUST carry only what probe re-derived from the store.
  IV21: EVERY outcome an operator writes through [Resolve] MUST carry the operator's own attestation, the original caller in acting_actor_ref, and resolved_by.
  IV21a: An operator's outcome MUST NOT owe a recovery_intended.
  IV22: A writer MAY write <kind>.abandoned ONLY IF the store can say the act did not happen.
  IV23: The sweep MAY write abandoned ONLY IF commit_fence = declared AND the intent is past abandon_edge.
  IV24: An operator MAY write abandoned ONLY IF the intent is aged, as the operator's own attestation.
  IV25: The sweep MUST escalate with candidates what the store cannot re-derive.
  IV26: The sweep MUST NOT close an act whose store the sweep cannot read.
  ```
  *Rests on:* `service_identity` (Bindings); Audit Trail Invariant 1 (the attesting actor is verified); [Reconcile] step 3. Generation acceptance check 6 and [Resolve]'s too-young guard rest on IV22.

- **Invariant 6 — The outcome is sized before the intent.**
  ```text
  IV27: IF outcome_envelope = the true maximum THEN an act MUST NOT commit with an outcome record or a compensation record the substrate's payload_cap could refuse.
  IV28: [Open] MUST NOT write the intent record BEFORE sizing the outcome and the compensation against outcome_envelope and intent_candidates_cap.
  ```
  *Rests on:* [Open] step 1; the adopter's caps under `reference_length_cap`. `outcome_envelope`'s truth is an externally-clearable check.

- **Invariant 7 — The sweep is bounded at both ends.**
  ```text
  IV29: [Reconcile] MUST NOT examine an in-flight intent.
  IV30: [Reconcile] MAY examine an intent ONLY IF the intent's horizon_edge EXCEEDS now.
  IV32: EVERY check MUST exclude an intent whose payload the substrate has destroyed.
  ```
  *Rests on:* Audit Trail Invariant 2 (retention coverage at quiescence — every `<kind>.*` record is placed under the kind's fixed policy, late at worst), Audit Trail Invariant 4 (the cascade destroys the payload), Audit Trail Invariant 8 and its `read_record` step 5 (destruction and an unplaced retention are each honestly reported), and the `journal` binding's fixed-policy obligation. [Reconcile] step 1 owns both edges.

- **Invariant 8 — Positioned codes.**
  ```text
  IV33: EVERY code an adopter's action exports that could land before the commit and after the commit MUST carry the position — recording-failure(intent | outcome) at least.
  IV34: The adopter's signature MUST declare the payload.
  IV35: A caller receiving intent MAY retry the action.
  IV36: A caller receiving outcome MUST NOT retry the action.
  ```
  *Rests on:* [Open], [Close] and [Refuse]'s signatures; the position rule (Primitive policies).

- **Invariant 9 — Constituent invariants preserved.**
  ```text
  IV37: EVERY Audit Trail invariant (1–8) MUST hold over the journal instance, and transitively every invariant of Audit Trail's four constituents.
  IV38: This composition MUST NOT write to the adopter's constituent store.
  IV39: The adopter's commit partition MUST transcribe the constituent's arms as the constituent states the arms.
  ```

---

## Examples

### Walkthrough — a disclosure, three ways

The adopter is Immutable Transaction Ledger's `disclose_subset`, bound as:

- `act_key` = disclosure of `(subject_ref, recipient, scope, authority)` by `actor_ref`.
- `commit` = `SelectiveDisclosure.record(subject_ref, recipient, scope, authority, disclosed_at = now)`; `invalid-request`, `unknown-authority-type` and `storage-failure` are pre-commit as the constituent declares them; a lost reply is `unknown`.
- `pairing_datum` = `disclosed_at`, the seam-injected `now`, carried in `intent_data` and passed into `commit`. Selective Disclosure admits no nonce, so the binding declares PD4's obligation and discharges it by minting `disclosed_at` from a per-node monotonic source whose low bits carry the node, the tag below the resolution at which the constituent's not-in-future guard discriminates, both seams sharing one clock authority (a declared deployment obligation). A deployment whose authority ticks at or below the tag's resolution tags elsewhere.
- `probe` = read Selective Disclosure's store by `subject_ref` and `recipient` and select, in the adopter's code, the record whose `scope`, authority and `disclosed_at` equal the intent's: `committed(ledger.disclosed, {disclosure_id, disclosed_at})` on exactly one match, `not-committed` on none, `undecidable(candidates)` on several, `unavailable` on any read outage — the constituent's `invalid-query` is `unavailable` to the sweep and surfaced on `compliance_surface`.
- `commit_fence = none`; `repeatable = yes`; `completion_bound = 30 s`; `commit_round_trip = 1 s`; `probe_round_trip = 1 s`; `service_identity = ledger-reconciler`.
- Instance: `reconciliation_cadence = 60 s`; `clock_skew_allowance = 2 s`; `closure_latency = 12 s`; `run_bound = 135 s` (a backlog of three orphans, sequentially, each at worst one holder's remaining lease and one closure: `3 × (30 + 12) = 126 s`, the balance headroom); `journal_write_bound = 3 s`; `read_bound = 2 s`; `compensation_window = 10 min`.

**The five conditions of instance start, against these numbers:**

1. `30 + 2×2 + 2×60 + 3×135 = 559 s < 600 s`.
2. `30 + 2 + 600 = 632 s < retention_period` — `ledger.*` carries a period above 632 s.
3. `30 s > 2×2 + 2×3 + 1 = 11 s`; neither fence is declared, so no allowance is charged.
4. `135 s ≥ max(30, 12 + 3) + 12 = 42 s`.
5. `12 s > 2 + 2×3 + 1 = 9 s`.

The sweep's lease is `12 + 3 = 15 s`; one closure inside it spends `2 + 1 + 3 + 3 = 9 s`, clearing the gate before both writes. (An earlier draft bound `closure_latency = 5 s`, which breaches condition 5: the second gate fails for any probe latency, the sweep re-opens a recovery intent every cadence and never lands a closing.) The instance starts.

**The clean run.** `disclose_subset(...)` validates; [Open] takes the section, sizes the outcome (`disclosed_entry_ids` under the ledger's cardinality cap) and the compensation, writes `ledger.disclose_intended` (`inv-7f2`) under the discloser's credential, and returns. `SelectiveDisclosure.record` → `dsc-411`. [Close] finds no outcome for `inv-7f2` under the section, writes `ledger.disclosed` with `{invocation_id: inv-7f2, intent_event_id, disclosure_id: dsc-411, ...}`, releases, returns `landed_by = invocation`. One intent, one outcome, one writer.

**The crash.** The run dies between `SelectiveDisclosure.record` returning `dsc-411` and [Close]. The section stays held until its lease runs out at `t + 30 s`; the host does not see the death. Thirty-two seconds later a [Reconcile] run keeps `inv-7f2` (older than `30 + 2 s`, inside the horizon), takes the section, re-reads — still open — and probes: exactly one record matches → `committed(ledger.disclosed, {disclosure_id: dsc-411, disclosed_at})`. The sweep writes `ledger.recovery_intended` then `ledger.disclosed` with `recovery = true, acting_actor_ref = <the discloser>`, both under `ledger-reconciler`, and releases. Accounted for within about forty-five seconds, inside the ten-minute window, by the one writer left alive.

**The stall.** The run does not die; `SelectiveDisclosure.record` is slow. The store applies the write at eight seconds and the invocation reaches [Close] at forty: `remaining` answers `none` (the lease expired at thirty), the invocation writes nothing and returns `rejected(recording-failure(outcome))`, and the sweep at thirty-five probed `committed` and closed it, or will. Or the store never applied the write, [Refuse] failed too, and `probe` answers `not-committed` — not final under `commit_fence = none`, since a process paused past the lease could still land the write at forty-five. The sweep writes `escalated` with `cause = not-observed`; the operator writes the abandonment through [Resolve] once the store has been quiet long enough. A write landing at fifty after a sweep read the store empty at thirty-five is survivable: the escalation stands, the operator's later `probe` finds the record, and the disposition is `outcome`. A store-level fence makes that order unreachable and gets `abandoned` from the sweep.

**The refusal.** A different caller opens a disclosure and `SelectiveDisclosure.record` refuses `invalid-request`. The adopter partitions the arm pre-commit and calls [Refuse]; `ledger.disclosure_refused` lands with the reason; the intent is closed; the trail keeps the authenticated attempt. Nothing for the sweep.

### Rejection path — a second invocation of the same act

Two operators call `transfer_custody` for one chain within a second of each other, in an adopter whose `act_key` is the chain. The first's [Open] takes the section and writes its intent. The second's [Open] waits on the section, takes it after the first's [Close] releases, and its step-3 pre-check finds no open intent — the outcome read runs only for a `repeatable = no` kind, and a transfer is repeatable — so it writes its own intent and its own transfer. Had the kind been non-repeatable (a genesis), the second would have landed `rejected(act-landed(outcome_event_id))` and the adopter's `already-*` arm would have answered its caller.

### Rejection path — the caller's retry after `outcome`

A caller receives `rejected(recording-failure(outcome))`. The position says the act committed. The caller does not re-run; it calls the adopter's read (through [Read Invocation]) and finds the act `open` — the sweep has not yet run — then, a minute later, `closed` with `recovery = true`. A caller that re-ran would have found `rejected(act-in-flight(invocation_id))` at [Open], the open intent being younger than the bound plus the allowance — and after the sweep, an `act-landed` refusal where the act is non-repeatable, or a second act where it is: the second act is the caller's decision, made with the position in hand.

### Regulated adversarial scenarios

**Regulator audit — "show me that every consequential act you took is accounted for."** The auditor enumerates the journal's `<kind>.intended` records inside the horizon and older than the bound, and for each finds exactly one closing record naming its `invocation_id` — not since superseded, an `abandoned` carrying a later `outcome` with `supersedes` being the corrected-false-abandonment shape check 6 reads; `recovery_intended` records are not closings and may be several — within `compensation_window` of its `recorded_at`, under the allowance (checks 2 and 3). An intent with no closing record is younger than the bound (in flight) or a conformance failure surfaced on `compliance_surface`, and the auditor can tell which from the stamps alone.

**Disputed act — "I never authorized that disclosure."** The outcome names `invocation_id`; the intent record with that id is attested under the disputant's credential, verified by Actor Identity before the store committed (Invariant 1), and sealed (Audit Trail Invariant 3). If the outcome carries `recovery = true`, the sweep wrote it — under `ledger-reconciler`, behind a `recovery_intended` record — and `acting_actor_ref` still names the disputant. The structural rebuttal is the intent, not the outcome; the sweep changes who attests the outcome, never who attested the intent.

**Breach investigation — "the reconciler's credential was compromised; what could it have written?"** Every record under the service identity is a closing record naming an `invocation_id` whose intent stands under a human's credential; a service-identity record with no such intent is a write outside this composition (check 5), and an outcome the store does not corroborate is one the sweep could not have derived (check 6). The compromised identity could close acts, never open them, and close only acts whose intents exist — the intent record is the control the service identity cannot forge.

---

## Generation acceptance

A derived implementation of Recoverable Invocation is acceptable when an auditor, given the journal and the adopter's constituent store, can clear the following from the records alone.

### Audit-Trail-traversal-clearable checks

```text
GA1: EVERY outcome record whose intent is inside the horizon MUST follow, in the journal's sequence, an intent record with the same invocation_id attested under the actor the outcome names — the outcome's own actor_ref where recovery is absent, the outcome's acting_actor_ref where recovery = true.
GA1a: An auditor MUST decide inside the horizon by read_record(intent_event_id) answering Retained.
GA1b: An auditor MUST NOT decide inside the horizon by arithmetic on the outcome's stamp or by the presence of an answer.
GA1c: An auditor MUST answer purged, never absent, for an outcome whose intent the substrate reports Purged.
GA2: For EVERY aged intent inside the horizon, two closing records of any of the four kinds MUST NOT name the intent's invocation_id.
GA2a: For EVERY aged intent inside the horizon, two <kind>.intended records MUST NOT carry the intent's invocation_id.
GA2b: Two intents MUST NOT stand open on one (kind, act_key) at any reading inside the horizon, under §Which closing stands' intents key and the key's service_identity = none branch.
GA2c: An auditor MUST read supersession transitively per §Which closing stands and count the reachable set as one closing.
GA2d: An auditor MUST read EVERY outcome as EXACTLY ONE OF the three outcome shapes.
GA2e: An auditor MUST report an outcome matching no outcome shape as a conformance failure.
GA3: For EVERY aged intent inside the horizon, a closing record MUST land WITHIN compensation_window of the intent's recorded_at, the auditor's reading tolerating clock_skew_allowance across seams.
GA3a: An auditor MUST exempt an intent of a kind the bindings table no longer serves.
GA3b: An auditor MUST exempt an intent whose window overlaps any span of journal-unavailable, or of store-unavailable for the intent's kind.
GA3c: An auditor MUST NOT exempt an intent for the healthy gap between two spans.
GA3d: IF service_identity = none THEN the register MUST carry EVERY aged intent as a closure-at-risk act finding WITHIN compensation_window.
GA4: An auditor MUST confirm all five conditions of instance start, as §Instance start states the conditions, for EVERY bound act kind from the kind's completion_bound, commit_round_trip, probe_round_trip, retention_period and commit_fence declaration, the substrate's journal_fence declaration, and the instance's clock_skew_allowance, reconciliation_cadence, run_bound, closure_latency, read_bound, journal_write_bound and compensation_window.
GA5: EVERY record the service identity attests whose named intent is inside the horizon MUST name an invocation_id whose intent record exists and is attested by a different actor.
GA5a: An auditor MUST report a service-identity record naming no readable intent inside the horizon as a write outside this composition.
GA5b: An auditor MUST answer purged for a service-identity record whose intent is Purged.
GA6: For EVERY outcome carrying recovery = true, probe run by the auditor against the constituent store MUST corroborate outcome_data or answer unavailable.
GA6a: An auditor MUST read unavailable as not applicable, never as failed.
GA6b: For EVERY <kind>.abandoned not superseded by an outcome carrying supersedes, probe MUST answer not-committed, or undecidable where the kind's pairing_datum = none and a later identical act exists.
GA6c: EVERY <kind>.abandoned carrying no resolved_by MUST belong to a kind whose commit_fence = declared.
GA6d: EVERY store_candidates entry of an <kind>.escalated record MUST match a store record of the intent.
GA7: An auditor MUST exclude an intent the substrate reports Purged from every check.
GA7a: An auditor MUST quantify GA1, GA2 and GA3 over intents whose payload is readable.
GA8: An auditor MUST clear Audit Trail's eight traversal checks over the journal instance.
```

Terms › `outcome shape`: `recovery` absent with `actor_ref` = the intent's `actor_ref`; `recovery = true` with `resolved_by`, `actor_ref` = `resolved_by`, no `recovery_intended` owed; `recovery = true` without `resolved_by`, `actor_ref` = the service identity, preceded by one or more `<kind>.recovery_intended` naming the same `invocation_id`.

Terms › `check map`: check 1 = GA1; check 2 = GA2; check 3 = GA3 (both branches externally clearable, reading `compliance_surface`); check 4 = GA4 (clearing it is clearing instance start); check 5 = GA5; check 6 = GA6; check 7 = GA7; check 8 = GA8.

Terms › `invariant map`: Invariant 1 → GA1; Invariants 2 and 5 → GA2; Invariant 4 → GA3 and GA4 (conditions 1, 4, 5; with Invariant 7 for condition 2); Invariant 5 → GA5 and GA6; Invariant 7 → GA7.

### Externally-clearable checks

```text
EC1: An auditor MUST clear from external evidence that a declared outage of the journal or the adopter's store was surfaced on compliance_surface with the outage's start and end, and that every intent whose window overlapped the outage was closed once the outage ended.
EC2: An auditor MUST clear from external evidence that act_section is shared across every node of the instance and implemented as a lease of the declared length.
EC3: An auditor MUST clear from external evidence that closure_latency, completion_bound, read_bound and run_bound were set from observed worst cases with headroom, run_bound over the largest backlog the deployment sizes for.
EC4: An auditor MUST clear from external evidence that the adopter's probe reads the store the act was made in.
EC5: WHEN service_identity = none:
    EC5a: An auditor MUST clear from external evidence that the surfaced intents were acted on through [Resolve].
EC6: An auditor MUST clear from external evidence that the store honours commit_fence — that a write carrying the minted deadline is never applied after the deadline.
EC7: An auditor MUST clear from external evidence that each adopter's outcome_envelope is the true maximum of the records the kind writes.
EC8: An auditor MUST clear from external evidence that no writer other than this composition's actions uses an adopter's journal vocabulary.
```

WHY:
EC1 is keyed on the outage record, not the intents: during a journal outage nothing is enumerable. The records show consequences, not mechanisms — no `binding_duplicate` at quiescence for EC2, no `abandoned` record whose act the store later holds for EC6. A `probe` that reads a projection can answer `not-committed` for a committed act, and the abandoned record it causes is false (EC4). The substrate does not reserve namespaces (EC8).

---

## Edge cases and explicit non-goals

- **Cross-store consistency under partial failure.** The reachable partials and their closers. *Crash after [Open], before the commit:* intent open, store untouched; `probe` answers `not-committed`; the sweep writes `<kind>.abandoned` where the kind declares a `commit_fence` and the intent is past the abandon edge, `<kind>.escalated` otherwise. *Crash after the commit, before [Close]:* `probe` answers `committed`; the sweep writes the outcome under `recovery = true`. *Crash inside [Close] after the outcome landed and before the map update:* the map is a rebuild trigger, not a partial. *A stalled invocation past its lease:* it yields; the sweep closes; the late [Close] adopts or reports `outcome`. *A refusal record that failed:* the intent stands, `probe` answers `not-committed`, the sweep closes it — abandoned under a fence, escalated without. *An outcome the store cannot corroborate:* `undecidable`, escalated with candidates, never chosen. There is no sixth partial; a deployment that finds one has a section that is not a section.
- **Declared deviations.**
  ```text
  DV1: An adopter MUST declare a deviation as EXACTLY ONE OF: retry_terminus = counted(n); minted key; journal without attribution.
  DV2: An adopter MUST record a need outside DV1 first, as a finding against the adopter or as evidence for the next revision of this page.
  DV3: WHEN retry_terminus = counted(n):
      DV3a: The adopter MUST bound the in-invocation retry of the outcome by n attempts.
      DV3b: The adopter MUST carry the seam-injected now [Open] step 3 needs.
      DV3c: [Close]'s remaining query before every write MUST NOT change.
  DV4: WHEN the act's key is minted by the commit:
      DV4a: The adopter MUST bind the key the adopter can name before the commit.
      DV4b: The adopter MUST declare the probe that finds the minted record from the bound key.
      DV4c: IF such a read NOT EXISTS in the constituent THEN the adopter MUST declare probe = undecidable for the kind.
  DV5: An adopter journaling to a bare Event Log MUST declare that the adopter is not an adopter of this page.
  ```
  WHY: Chain of Custody bounds its retry without a clock (DV3). Under DV4c the sweep escalates every orphan of the kind, the honest liveness degree. A bare Event Log adopter is the second group the higher-order composition test names, one instance short of its own compound.
- **Repeatable and non-repeatable acts.** The adopter's declaration; [Open]'s `act-landed` refusal fires only for `repeatable = no`. The composition does not guess.
- **What the sweep never does.**
  ```text
  NG2: The sweep MUST NOT run adopter code other than probe.
  NOTE: NG1 deleted after CR-7; RC29 owns the rule.
  NOTE: NG3 deleted after CR-7; RC32 owns the rule.
  NG4: The sweep MUST NOT write under a human's credential.
  NOTE: NG5 deleted after CR-7; RC35 and IV23 own the rule.
  NOTE: NG6 deleted after CR-7; RC13, IV29 and IV30 own the rule.
  NOTE: NG7 deleted after CR-7; RC17a owns the rule.
  ```
- **Clock semantics.**
  ```text
  CS1: The composition MUST NOT sample a clock.
  CS3: A record MUST carry only stamps of the substrate (recorded_at) or of the constituent (through probe).
  CS5: The composition MUST NOT time the lease.
  ```
  WHY: a clock read inside [Resolve] breaks CS1; `-buggy-opclock` shows the cost (Invariant 5: an act abandoned whose commit then lands).
- **Non-goals.**
  ```text
  NG8: An adopter MUST NOT describe [Open] → commit → [Close] as atomic.
  NG9: This composition MUST NOT offer a rollback.
  NG10: This composition MUST NOT add to the substrate's contract.
  NG11: The adopter MUST own the already-* re-entry arm, informed by [Read Invocation].
  NG12: A deployment whose regulator requires the account to outlive the act's own retention MUST set the journal's retention_policy accordingly.
  NG13: This composition MUST NOT govern the adopter's constituent store's lifecycle.
  ```
  WHY: an adopter needing a withdrawable act composes a Transaction pattern *(forthcoming)* over a store that offers one. Attribution, sealing, retention, purge and the range read are Audit Trail's; this composition adds record kinds and nothing else, and the substrate accepts a `<kind>.*` record from any authenticated caller, so *one outcome per intent* is enforced by this composition's writers and nobody else (EC8). This composition refuses the second intent for a non-repeatable act and leaves the caller's answer to the adopter. An act whose store record is purged before its journal records is corroborated by nothing (GA6a reads *not applicable*).

---

## Terms

Each `[Term]` marker above links to its card here; a card states what the concept *is* and its **Kind**. The substrate's rejections (`invalid-credential`, `invalid-request`, `recording-failure(step)`) are the substrate's cards.

### Vocabulary

Terms › `actors`: invocation; sweep run (also: the sweep, the run); operator; adopter's action (also: the adopter, the action); caller; deployment; auditor; substrate; section host (also: the host); writer — EXACTLY ONE OF invocation, sweep run, operator; minter — the section host or a writer's seam; reader; register (the deployment's findings surface); surface — [Read Invocation], [Reconcile] step 5, or Generation acceptance check 2.

Terms › `records`: `<kind>.intended`, `<kind>.<outcome>`, `<kind>.refused`, `<kind>.recovery_intended`, `<kind>.abandoned`, `<kind>.escalated`, [Finding].

Terms › `record verbs`: write, read, read back, take, release, hold, yield, adopt, retry, refuse, return, surface, count, probe, close, examine, keep, drop, name, carry, size, validate, land, supersede, rebuild, populate, clear, discard, report, proceed, wait, persist, start, derive, sample, declare, bind, treat, transcribe, issue, mint, reach, reveal, escalate, abandon, open, advance, set, move, admit, absorb, exclude, stand, serialize, time, query, run, pass, decide, pair, share, stay, sum, rely, trigger, hold, exist, answer, call, follow, re-read, leave, supply, perform, exempt, bound, block, use, re-run, match, map, make, export, classify, choose, cap, vary, update, touch, suppress, stamp, retain, resolve, remove, reject, recover, record, re-take, partition, own, owe, omit, offer, know, inspect, govern, free, fire, end, disclose, describe, corroborate, confirm, compare, collapse, check, charge, change, belong, add, commit, append, quantify.

Terms › `cited`: `take`, `try_take`, `remaining`, `release`, `expires_at`: Lease. `record_action`, `read_record`, `payload_cap`, `reference_length_cap`, `attestation_id_width`, `retention_policy`, `recorded_at`, `sequence_number`, `next_sequence_number`, `record_action_completion_bound`: Audit Trail.

Terms › `value sets`: `landed_by` = invocation | sweep | operator. `state` = open | closed | refused | abandoned | escalated | resolved. `disposition` = outcome | abandoned | escalated. `probe` answers = committed | not-committed | undecidable | unavailable. commit partition = pre-commit | committed | unknown. `repeatable` = yes | no. `retry_terminus` = lease | counted(n). `commit_fence` = none | declared. `journal_fence` = none | declared. `service_identity` = an actor | none. findings = journal-unavailable | store-unavailable | closure-at-risk | binding_duplicate | unbound-kind. [Resolve]'s `invalid-request` causes = purged | malformed | too-young | already-abandoned | candidates-over-cap. Cross-seam comparisons = applied | minted.

Terms › `position`: `intent` | `outcome` | `refusal` | `resolution` — the record a write lands: the intent at [Open], the outcome at [Close] or after [Yield], the refusal at [Refuse], the resolution at [Resolve].

Terms › `intent payload`: `intent_data` with `invocation_id`, `kind` and `act_key` added.

Terms › `outcome payload`: `outcome_data` with `invocation_id`, `intent_event_id`, `kind` and `act_key` added.

Terms › `recovered outcome payload`: the outcome payload with `recovery = true` and `acting_actor_ref` = the intent's `actor_ref` added.

Terms › `run_id`: a sweep run's own seam-injected id; the section holder for the run.

Terms › `true maximum`: the largest record a kind writes, as EC7 clears.

Terms › `cause`: `not-committed` | `not-observed` | `undecidable` | `outcome-unrecordable` — the closing record's escalation or abandonment cause.

Terms › `external evidence`: evidence outside the records — documentation, configuration, the deployment's own logs.

Terms › `recording-failure(step-4)`: the substrate's code for an append that committed and a retention placement that did not; the record is appended.

NOTE: labels JF3, JN4, CM10, RT1, PP1, PP5, PP16, PP17, AS4, AS6–AS8, IS4, FR5, FR6, FR13, IV14, IV31, CS2, CS4, WC5 and RC2–RC9 were never carried by a rule in any committed version of this spec; nothing was deleted and no tombstone is owed.

Terms › `bounds`: `completion_bound`, `commit_round_trip`, `probe_round_trip`, `journal_write_bound`, `read_bound`, `closure_latency`, `run_bound`, `compensation_window`, `clock_skew_allowance`, `retention_period`, `intent_candidates_cap`, `read_cap`.

Terms › `cadences`: `reconciliation_cadence`.

Terms › `qualifiers`: empty.

Terms › `terms`: (named expressions, each declared where it is used) `worst_closure`, `window_end`, `lease_spend`, `run_floor`, `closure_spend`, `examine_edge`, `abandon_edge`, `horizon_edge`, `at_risk_threshold`, `intent_age`, `settle_bound`, `retention_end`, `usable_term`, `sweep_lease`, `in-flight`, `aged`, `partition`, `examined`, `skipped`, `reported`, `surfaced`, `unreached`, `closed_already`, `standing closing`, `closings key`, `intents key`, `terminus`, `caller_kind`, `payload_match`, `quiescence`, `read path`, `read-your-writes`, `position's existing arm`, `journal_fence instant`, `commit_fence`, `section key`, `section holder`, `section duration`, `act finding`, `instance finding`, `act_key`, `invocation_id`, `now`, `operator_run_id`.

#### Open

The action an adopter's action calls before the bound commit: takes the act's section, sizes the outcome and the compensation against the substrate's cap, refuses an act already in flight or already landed, and writes the intent record under the caller's credential. Returns `{invocation_id, intent_event_id}` with the section held.

Kind: Operation

#### Close

The action an adopter's action calls after the bound commit returned: under the section, adopts an outcome the sweep already landed for the invocation or writes the outcome record, then releases. Returns `landed_by`; returns `recording-failure(outcome)` where the lease expired or the record could not land.

Kind: Operation

#### Refuse

The action an adopter's action calls when the bound commit refused on a pre-commit arm: writes the refusal record naming the intent, so the authenticated attempt is kept and the intent does not stand open, and releases the section.

Kind: Operation

#### Reconcile

The sweep, the composition's second writer: at restart and on cadence, examines open intents between the completion bound and the horizon, takes each act's section, probes the store, and closes each act with a re-derived outcome, an abandonment or an escalation — under the service identity behind a recovery-intended record, or as a report only where none is declared.

Kind: Operation

#### Yield

The release an adopter's action calls on a lost commit reply: the section is released, nothing is written, the intent stays open for the sweep.

Kind: Operation

#### Resolve

The human-attested close: an operator, present with an own credential, closes an open intent the sweep cannot — under a report-only deployment, or after investigating an escalation — supplying the disposition the operator's own run of `probe` supports; the record carries `recovery = true` and `resolved_by`.

Kind: Operation

#### Read Invocation

The composition's read: the act's invocations, each with records and `state`, for an adopter's re-entry arm and for an auditor. Takes no section, writes nothing.

Kind: Operation

#### Recording Failure

The positioned failure code `recording-failure(intent | outcome | refusal | resolution)`; `refusal` carries a second slot for the constituent's pre-commit code. `intent`: nothing committed, retry the action. `outcome`: the act exists or may exist, never re-run; the sweep or an operator writes the record. `refusal`: the intent stays open; the sweep or an operator closes it. `resolution`: nothing appended — the one retry-safe arm of [Resolve].

Kind:      Type
Role:      the positioned failure code
Projects:  recording_failure

#### Act In Flight

[Open]'s refusal where an open intent for the same act exists — younger than the bound (another invocation is between intent and outcome) or older (a dead invocation the sweep will close within the window). Carries the open `invocation_id`.

Kind:      Member
Member of: the open rejections
Role:      Rejection
Projects:  act_in_flight

#### Section Unavailable

[Open]'s and [Resolve]'s refusal where the act's section could not be taken within the current holder's remaining lease; nothing is written and the call may be retried.

Kind:      Member
Member of: the open rejections and the resolve rejections
Role:      Rejection
Projects:  section_unavailable

#### Not Open

[Close]'s and [Refuse]'s step 0 refusal, and theirs alone: an `invocation_id` and `intent_event_id` pair the adopter's action did not receive from its own [Open]. An adopter's programming error, not a protocol state; nothing is written.

```text
NO1: The composition MUST NOT decide not-open.
NO2: The adopter's action MUST hold [Open]'s returned pair on the action's own call stack for the life of the invocation.
NO3: The composition MUST NOT decide not-open from a map or a range read.
NO4: [Close] and [Refuse] MUST land rejected(recording-failure(outcome)) at step 1 for a pair no [Open] returned.
```

WHY: on a multi-node instance a local absence is not a miss, and a retained handle is the composition-owned state [`execution-contract.md`](../execution-contract.md) §Logic Confinement Principle forbids. NO4 is a false positive in the safe direction: no intent record exists, so nothing will look at the id.

#### Not Known

The read's answer for an act with no readable intent at all, at [Read Invocation] and at [Resolve]. Absence, not destruction: a lawfully purged intent is answered `invalid-request(purged)` at [Resolve], which takes `intent_event_id` for exactly that reason. [Read Invocation] is the one surface that cannot make the distinction and says so.

Kind:      Member
Member of: the read rejections and the resolve rejections
Role:      Rejection
Projects:  not_known

#### Finding

A record in the instance's `findings` register (*Composition state* owns the contract). An act finding names one act the run could not close and carries no span; an instance finding names a condition of the instance, or of one bound kind, and carries one.

Kind:      Type
Role:      the surfaced record
Projects:  finding

#### Binding Duplicate

The one token three surfaces agree on — [Read Invocation]'s two fields, [Reconcile] step 5's scan, Generation acceptance check 2 — answering two keys. Closings key: two closing records naming one `invocation_id` that neither supersede one another nor are superseded; holds under every binding. Intents key: two intents open at once on one `(kind, act_key)`; holds only if the kind declares a `service_identity`. §*Which closing stands* owns both keys.

Kind:      Type
Role:      the conformance finding two writers leave
Projects:  binding_duplicate

#### Journal Unavailable

The read-path outage code at [Open] step 3, [Reconcile] step 1 and [Read Invocation]: nothing was written, retry. A read's failure, never a write's. [Close], [Refuse] and [Resolve] do not carry it — by the time they read, the act's existence is decided, so their read failures land on their position's `recording-failure` arm.

Kind:      Member
Member of: the open rejections and the sweep's
Role:      Rejection
Projects:  journal_unavailable

#### Already Accounted

[Refuse]'s and [Resolve]'s refusal where a closing record already names the `invocation_id`; carries that record's `event_id`. Nothing is appended; the caller reports the act as accounted for. Distinct from `not-open` (a programming-error diagnosis never decided from a journal read) and not named `already-closed`, a constituent's pre-commit code an adopter transcribes verbatim.

Kind:      Member
Member of: the refuse rejections and the resolve rejections
Role:      Rejection
Projects:  already_accounted

#### Act Landed

[Open]'s refusal for a non-repeatable act whose outcome already exists; carries the `outcome_event_id`. The adopter's own re-entry arm answers the caller.

Kind:      Member
Member of: the open rejections
Role:      Rejection
Projects:  act_landed

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
[Section Unavailable]: #section-unavailable
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

`draft` — first draft 2026-08-30 (corpus date); the three passes and a fresh-reader gate are owed before any adopter binds to it.

## Ledger

```
status: draft
formal: verified — recoverable-invocation.tla (v5) + 9 twins + 8 probes and isolations (21,974 states **at a horizon of five ticks**, which is the whole of the claim: v5's four-phase [Open] costs about a factor of ten in states per tick and does not finish at six or seven, so "all invariants hold" here means *holds within five ticks at these constants* and no monotonicity argument is offered for more. **The twin suite is the evidence that five is enough for what it checks:** all nine twins still fail at this horizon, so each property's violating witness fits inside it; the two whose witnesses demonstrably do not — the window, and the intent landing past its section — have their own configurations; Invariants 1, 2, 4, 5 as safety over discrete time; six components over one act — the invocation, a section host with lease-as-terminus, a fenced-or-fenceless store, a journal whose writes return and become visible at separate instants, two sweep runs on two nodes with a blocking take, **an operator through [Resolve] as the third writer, taking the same section on its own seam reading and re-arming for a second call**, **[Open] split into take → read → gate → issue → return with the intent write carrying its own return and visibility instants**, a death budget and a pause budget; `service_identity` is a modelled dimension, so the sweep's writes and the operator's open-intent arm are gated by it; every journal write split into its gate and its issue, and carrying separate return, visibility and fence instants across two clocks; twins rejected — `-buggy-death`, host releases on death → Invariant 2; `-buggy-reread`, sweep skips the re-read under the section → Invariant 2; `-buggy-fence`, sweep abandons a fenceless act → Invariant 5; `-buggy-journal`, no `journal_fence` → Invariant 2; `-buggy-visible`, visibility only time-bounded → Invariant 2; `-buggy-skew`, fence instant minted bare → Invariant 2; `-buggy-perwrite`, no per-write fence instant → Invariant 2; `-buggy-supersede`, a resolution over an escalation carrying `resolved_by` and no `supersedes` → Invariants 2 and 6 (gate 9, F6); `-buggy-opclock`, the operator's reading one tick ahead in a report-only deployment → Invariant 5 (gate 9, F7), against `probe-reportonly-clean` which differs by that one constant and HOLDS; **Invariant 8 — an intent is never in flight while its own invocation no longer holds the section — is earned by the FENCE and not by the lease gate, which the model settles against the gate's own prescription: `probe-fenceless-intent` (no fence, gate on) VIOLATES it, `probe-fenced-ungated-intent` (fence on, gate off) HOLDS, and the fenced-and-gated case holds by monotonicity (gate 10, F6)**; established — the dead-run term inside the model's own frame is the sweep's own lease and not a second `completion_bound` (true of a world with one act in it; the page's inequality carries `run_bound` terms instead, which the model has no backlog to express — Configuration §`compensation_window`), the `remaining` gate is not what carries Invariant 2 (the fence is, in all four cells of gate × fence), the fence margin is required on every instant and not only the lease's, the lower edge not safety-bearing at zero skew; Invariant 4 is vacuous at the main constants and is checked in the window configurations instead; **reachability probes — `Probe_OperatorNeverHoldsSection`, `Probe_OperatorNeverWrites`, `Probe_OperatorNeverSupersedes` and `Probe_NeverASupersessionChain`, each a deliberate falsehood the checker rejects**, the last of them only after it had held twice and named two things that were off which the configuration did not say were off, so the operator's invariants are not vacuous the way Invariant 4 once was; not modeled — pairing, purge, the refusal path, `recovery_intended`, the bindings table's lifecycle and with it the `kind` half of the key, the rejection-code taxonomy, the derived indexes, the compliance surface, the sweep's own lost-reply retry, and **which record a supersession names**: the model counts supersessions and does not identify them, so a chain (an escalation superseded by an abandonment superseded by an outcome) and a double-naming of one record are the same state to it — the transitivity rule below is therefore a prose repair and is **not** model-confirmed), 2026-09-09
last gate: 2026-09-10 — twelfth gate, fresh reader, on the draft — 6 foundational, 15 refining and 6 rhetorical, corrected in this round together with the four of gate 11's nine that gate 12 did not re-find. **The round's measurement:** the Lease extraction's own claim held per class — lease-owned findings went 3 → 1 → **0** — while every surviving foundational was a consolidation that had not carried every obligation into its new owner. **Two consolidations this round**, both written in controlled normative form: the allowance's disposition (three passages, one of which asserted of another the opposite of what it said) and the instance-start condition set (four sites, one of which — the walkthrough — breached a condition the page declared eight lines above its own numbers, while the acceptance check that clears instance start named a subset); 2026-09-10 — eleventh gate — 9 foundational, 17 refining and 5 rhetorical; the round that measured defect density flat at 18-20 KB per foundational across four gates and diagnosed propagation failure as 16 of 19 caused findings, which is what put the diff-derived obligation sweep into standing round discipline; 2026-09-10 — tenth gate — 8 foundational; 2026-09-09 — ninth gate — 8 foundational, and the round that brought [Resolve] into the model as its third writer; 2026-09-09 — eighth gate, fresh reader, on the draft — 8 foundational, 15 refining and 7 rhetorical, all corrected in-round. Two of the eight were defects in start checks the previous round had copied out of Configuration into an acceptance check so an auditor would run them, and one of those two — the sweep's lease — was **unsatisfiable** wherever `closure_latency` reached `completion_bound`; 2026-09-08 — seventh gate, fresh reader, on the draft — 7 foundational, 12 refining and 8 rhetorical, all corrected in-round; conceptual independence returned CLEAN for the first time, and foundational timing findings reached zero. Five of the seven landed on [Resolve] or the purge, both on the model's own NOT MODELED list, and two of those five were then reproduced by bringing [Resolve] into the model; 2026-08-30 — sixth gate, fresh reader, on the draft — 6 foundational, 12 refining and 6 rhetorical, all corrected in-round, and the first round to run with the linter's mechanical checks active against the draft (they caught one defect the round itself introduced); fifth gate — 5 foundational, 11 refining and 5 rhetorical corrected in-round; fourth gate — 8 foundational, 19 refining and 5 rhetorical corrected in-round; third gate — 4 foundational, 15 refining and 6 rhetorical corrected in-round; second gate the same day — 6 foundational, 17 refining and 7 rhetorical corrected in-round; first gate — 8 foundational and 16 refining corrected in-round, 1 refining routed, 5 rhetorical corrected

open:
- 2026-09-10-a · refining · Composition state, `findings` · the register carries truth no constituent store replays, and it is classified extraction-pending with no atom yet owning it, so this page owns a durability contract that belongs to one → land the **Condition Register** atom, a durable register of named conditions each opening at a first sighting, advancing at every later one and ceasing when a pass no longer sees it; until it lands the contract in Composition state is the declaration and the debt is flagged rather than normalized
- 2026-09-10-b · refining · §Where the allowance goes · a deployment declaring `journal_fence` whose `journal_write_bound` carries no headroom fences out writes that take the full disclosed bound, and the model does not distinguish that state because it carries the fence and not the disclosure → disclose `journal_write_bound` with `clock_skew_allowance` of headroom over the substrate's own worst case, and carry the liveness cost as NOT MODELED until a model of the disclosures exists
```

## Decisions

Directional changes only. Everything smaller lives in the commit that made it: `git log -- compositions/recoverable-invocation.md`.

- **2026-09-10 — Rewritten in GRACE lang v0.28; nothing but language changed.** *Chose:* labelled rules, rationale under `WHY:`, the Ledger and invariant numbers unchanged. *Over:* the prose draft. *Because:* the migration plan.
- **2026-09-10 — Instance start in controlled form.** *Chose:* five terms, five one-line conditions, the round-trips as bindings. *Over:* inline inequalities marked `STRICTLY`. *Because:* arithmetic lives in term declarations, and a named term gives each expression one owner for the prose-versus-model diff.
- **2026-09-10 — Lease is the atom; what a fence costs stays here.** *Chose:* [`atoms/lease.md`](../atoms/lease.md) owning the section's lease and both fences as one concept; the binding and the three payments here. *Over:* an atom covering the section alone. *Because:* the atom declines what carrying an instant costs; lease-owned findings went 3 → 1 → 0 across the extraction.
- **2026-09-10 — One owner for the conditions of instance start, and there are five.** *Chose:* §*Instance start*, cited by number. *Over:* four sites. *Because:* they drifted three ways at once, and the `max` floor matters: over 432 tuples the old floor admits 324 and breaches on 15, the new admits 288 and breaches on none.
- **2026-09-10 — One owner for where the allowance is spent.** *Chose:* §*Where the allowance goes* — applied or minted, three instants, three payments. *Over:* three sites, one asserting the opposite of another. *Because:* the bare instant is the construction the Lease atom declares non-conforming; mint, then size for the minting.
- **2026-09-10 — The findings register is extraction-pending.** *Chose:* classify against a forthcoming Condition Register, the two obligations and five conditions named. *Over:* declaring the totality claim false. *Because:* an unclassified register ends up in process memory and loses the outage span a check reads.
- **2026-09-10 — The intents key branches on `service_identity`; the first does not.** *Chose:* the branch once, at §*Which closing stands*. *Over:* an unbranched key. *Because:* unbranched, [Open] step 3's own report-only instruction was a conformance failure for a whole retention period.
- **2026-09-10 — `not-open` is a precondition on the caller.** *Chose:* the pair [Open] returned, on the action's call stack. *Over:* a retained handle, or deleting the code. *Because:* the handle is the state the execution contract forbids, and the code is the one name an adopter has for the condition.
- **2026-09-10 — The fence earns Invariant 8; the lease gate does not.** *Chose:* the duplicate surfaces count open intents per `(kind, act_key)`; the read gains `read_bound`. *Over:* gating the intent write as the remedy. *Because:* the gated fenceless configuration admits a second live intent and the ungated fenced one does not.
- **2026-09-10 — The sweep's lease is stated, not maximised.** *Chose:* `closure_latency + journal_write_bound`. *Over:* a `max` with a start check. *Because:* the check reduced to `0 > journal_write_bound` whenever `closure_latency` reached `completion_bound`.
- **2026-09-10 — Supersession is transitive; the model does not confirm it.** *Chose:* the standing closing is the one no other closing names; the reachable set counts as one. *Over:* pairwise. *Because:* pairwise collapse reports `binding_duplicate` on the check-6 chain; the model counts supersessions without identifying them.
- **2026-09-08 — [Resolve] is modelled as the third writer.** *Chose:* model v4, the operator taking the same section on its own seam reading, `SupersedesNamed`, `OperatorSkew` and `service_identity` as modelled dimensions. *Over:* repairing from the gate's prescription. *Because:* the NOT MODELED list had named [Resolve] for three gates and the ninth returned five of seven foundational findings on it.
- **2026-09-08 — Supersession is by name; the operator's seam is the sixth clock.** *Chose:* every closing over an existing record carries `supersedes`; `now` injected at the operator's seam. *Over:* the name for the abandoned case only, and an unbounded reading. *Because:* `resolved_by` names the operator, not a record; a destructive write cannot be decided by a reading nothing bounds. Both are rejected twins.
- **2026-09-08 — `kind` is an argument; the act's closings are a declared index.** *Chose:* `kind` first in every action but [Reconcile], `(kind, act_key)` keys, `act_closings`. *Over:* the kind implicit in the caller. *Because:* a signature that omits the kind names the wrong section, and `act-landed(outcome_event_id)` had nothing to supply its payload.
- **2026-08-30 — The closure window is bounded by three sweep runs.** *Chose:* `completion_bound + 2 × clock_skew_allowance + 2 × reconciliation_cadence + 3 × run_bound < compensation_window`. *Over:* one `run_bound`, and the two-term correction the gate prescribed. *Because:* a budgeted death involves three runs; the enumeration breaches the old form on 420 of 432 tuples and the correction on 396.
- **2026-08-30 — A duplicate is decided by supersession first and position second.** *Chose:* a declared field on [Read Invocation], a scan over the delta, a check over all four closing kinds. *Over:* three detectors that did not exist. *Because:* a degraded guarantee whose detection is asserted is worth less than an honest statement that there is none.
- **2026-08-30 — Fenceless is a declared degraded mode.** *Chose:* `journal_fence` optional, the weaker guarantee stated over records. *Over:* requiring a fence no substrate here can supply. *Because:* the guarantee changes and stays checkable.
- **2026-08-30 — The composition's own writes are fenced, not merely gated.** *Chose:* `journal_fence` as an instance capability requirement. *Over:* the gate alone. *Because:* the gate is check-then-act; the fence carries Invariant 2 with or without it.
- **2026-08-30 — The model's two corrections.** *Chose:* a host that releases only on return or expiry, and one budgeted dead run. *Over:* release on death, and one bound. *Because:* the death twin lands two closings for one act.
- **2026-08-30 — The protocol is a compound, adopted by binding.** *Chose:* one composition owning the pair, the section, the sweep, the derived-not-remembered rule, positioned codes and the closure inequality; adopters bind and declare deviations from a closed list. *Over:* six methodology rules applied twenty times, or a Transaction pattern the constituents cannot support. *Because:* fourteen exact instances and ~920 KB of protocol prose clear the higher-order composition test, and the invariants are provable only over the pair of processes and the one section.

NOTE: End of Recoverable Invocation.
