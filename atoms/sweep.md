---
title: Sweep
id: 77
audience: common
parent: Atomic Concepts
has_toc: true
toc: true
---

# Sweep

<details markdown="block">
<summary>Table of contents</summary>
{: .text-xs .font-medium .uppercase .tracking-wide .opacity-50 }
1. TOC
{:toc}
</details>

## What it is

Sweep finishes the account of an act whose invocation died or yielded: a clean-up run, started at every restart and on a set cadence, that looks only at intents whose time limit has passed, takes the same critical section the invocation held, asks the adopter's database whether the act happened, and writes only what it can read back from that database. It closes an act as done only where the database answers that the act committed with exactly one matching record; where the act did not commit, or the database cannot say, the sweep records the act for a person to settle ([Escalation](./escalation.md)), and it never abandons an act.

<details markdown="block">
<summary>WHY</summary>

A sweep that wrote what it could not know would be a second writer making up the first one's account, and one that read in-flight work as a crash would close an act its invocation still owns, because a dead invocation and a slow one look alike from outside. This atom is the sweep alone: it reads only aged intents (the lower edge) inside the retention horizon (the upper edge), writes a plan before an outcome, and answers what it cannot settle with an escalation, not a guess (Scott, 2026-11-23, ruling of 9:29 AM Central: the sweep closes only on committed with exactly one match; not-committed and undecidable escalate, and only a person abandons). The records it reads and the writer it must exclude are [Durable Intent](./durable-intent.md)'s.

</details>

## What it keeps

### Derived indexes

- **sweep closed ids**
  Term sweep closed ids: the set of invocation id values the sweep has closed: an outcome under `recovery = true` or an `<kind>.escalated` naming the id and carrying no resolving actor (an operator's closing carries one, Escalation resolve 21). *Derived index*, same rebuild. Past the horizon the set holds no id whose closing's payload the substrate destroyed, the rebuild reading the id from the payload (Durable Intent Primitive policy 4), and no reader needs one there: only the sweep reads the set, for an intent short of the intent's horizon edge (reconcile step 1.2), and every closing of that intent was recorded after the intent under the kind's one retention period (Recoverable Invocation journal 6).

  ```
  sweep closed ids 1: The sweep MUST NOT write a closing BEFORE consulting sweep closed ids under the critical section (reconcile step 2.4 through 2.6).
  ```
## What people do

### Reconcile

The sweep, the composition's second writer: at restart and on cadence, examines open intents between the invocation completion bound and the horizon, takes each act's critical section, probes the database, and closes each act with a re-derived outcome or an escalation — under the service identity behind a recovery-intended record, or as a report only where none is declared.

Kind: Operation

```
reconcile()
  answers reconcile tally
  refuses journal-unavailable
```
Term reconcile tally: examined, closed, escalated, reported, skipped, closed already, surfaced and unreached — what reconcile answers; reconcile is the one action with no kind: the run sweeps every bound kind.

The sweep. Its starter starts a run at every process restart and on sweep cadence (Execution Contract Scheduled leg 1; sweep cadence 2, 3); a run reads now once at the sweep's own seam.

```
reconcile 1: WHEN step 1's enumeration fails:
    reconcile 1a: The run MUST NOT write to the journal.
    reconcile 1b: The run MUST open or advance the instance finding journal-unavailable on compliance surface.
    reconcile 1c: The run MUST return journal-unavailable.
reconcile 2: WHEN service identity EQUALS none for the act's kind:
    reconcile 2a: The run MUST take the critical section.
    reconcile 2b: IF step 2 counted the act in no count THEN the run MUST run act probe under the critical section.
    reconcile 2c: The run MUST release the critical section.
    reconcile 2d: The run MUST NOT write to the journal for the act.
    reconcile 2e: The run MUST report the answer of act probe for the act on compliance surface.
    reconcile 2f: IF step 2 counted the act in no count AND act probe DOES NOT EQUAL unavailable THEN the run MUST count the act in reported.
    reconcile 2g: IF act probe EQUALS unavailable THEN the run MUST keep the instance finding store-unavailable standing for the act's kind on compliance surface, as reconcile step 3.13c does for a kind that declares a service identity.
reconcile 3: A run over a mixed instance MUST close each act of a kind that declares a service identity as reconcile step 3 says, an act step 3 leaves for the next run excepted.
reconcile 4: A run over a mixed instance MUST report the kinds that declare no service identity.
reconcile 5: The run MUST sum the counts over both.
```
Term examined: an act step 1 kept and the run reached — took, or attempted to take, the act's critical section.

Term partition: `((((closed + escalated) + reported) + skipped) + closed_already) = examined`.

Term surfaced: the unbound-kind intents step 1 reports; outside the partition.

Term unreached: the acts step 1 kept that the run stopped short of after a write under the service identity of the act's kind answered invalid-credential (reconcile step 2.1, reconcile step 2.8 through 2.9); outside the partition.

Term closed already: an act for which step 2's re-read finds a closing record naming the invocation id, another writer's (reconcile step 2.6).

Term skipped: an act the run examined and left for the next run, in place of any count the act held — a failed take, a storage-failure and no answer included; a release that answered storage-failure (reconcile 9a); a re-read at step 2 that failed (reconcile step 2.10); an act probe answering unavailable; a closing write or a recovery_intended write whose retries the lease cut short; a closing write or a recovery_intended write left for the next run after step 3 counted the act; a read-back that failed (reconcile step 3.16c); an act whose remaining did not exceed write floor at step 2 before any write, a remaining of none or no answer included (reconcile step 2.7); an act whose write under the service identity answered invalid-credential (reconcile step 3.18); an act whose outcome-unrecordable escalation answered invalid-request(step-1), invalid-request(step-2) or invalid-request(step-3) (reconcile step 3.23). The list is exhaustive.

Term reported: an act the run examined, of a kind whose service identity EQUALS none, that step 2 counted in no count and whose act probe did not answer unavailable.

1. **Enumerate between two edges.**

   ```
   reconcile step 1.1: The run MUST rebuild open invocations, act closings and sweep closed ids from the substrate's range read (Durable Intent sequence high water 4 and 6).
   reconcile step 1.2: The run MUST keep EVERY aged intent of a kind the bindings table serves for which now PRECEDES horizon edge, and no other intent.
   NOTE: watch applicability — the pass's domain is carried by a relative clause (reconcile step 1.2); the corpus has no WHERE.
   reconcile step 1.3: The run MUST make reconcile step 1.2's comparison from the sweep's seam reading against the substrate's stamp, under clock allowance.
   reconcile step 1.6: Step 1 MUST surface EVERY unbound-kind intent per Recoverable Invocation Binding 4 through 6.
   reconcile step 1.7: The run MUST count EVERY intent step 1 surfaces in surfaced.
   ```
2. **Take the act's critical section and re-read.**

   ```
   reconcile step 2.1: The run MUST take the critical section for each kept intent: take((kind, act key), critical section holder, sweep lease), an intent not yet examined when a write under the service identity of the intent's kind answers invalid-credential excepted.
   NOTE: watch applicability (reconcile step 1.2).
   reconcile step 2.3: A take that fails after the wait, no answer included, MUST count the act in skipped.
   reconcile step 2.4: Under the critical section, the run MUST re-read open invocations and act closings at (kind, act key) and sweep closed ids from sequence high water.
   NOTE: watch rule inheritance (Durable Intent refuse step 0.1).
   reconcile step 2.5: IF the step-2 re-read finds a closing record naming the invocation id THEN the run MUST release.
   reconcile step 2.6: IF the step-2 re-read finds a closing record naming the invocation id THEN the run MUST count the act in closed already.
   reconcile step 2.7: WHEN the step-2 re-read finds no closing record naming the invocation id AND service identity DOES NOT EQUAL none for the act's kind AND a remaining the run queried for the act (Durable Intent journal write bound 1) DOES NOT EXCEED write floor, a remaining of none or no answer included (Lease Term expired):
       reconcile step 2.7a: The run MUST count the act in skipped.
       reconcile step 2.7b: The run MUST release.
   reconcile step 2.8: The run MUST NOT take the critical section for an intent reconcile step 2.1 excepts.
   reconcile step 2.9: The run MUST count EVERY intent reconcile step 2.1 excepts in unreached.
   reconcile step 2.10: WHEN the step-2 re-read fails:
       reconcile step 2.10a: The run MUST NOT write to the journal for the act.
       reconcile step 2.10b: The run MUST release.
       reconcile step 2.10c: The run MUST count the act in skipped.
       reconcile step 2.10d: The run MUST open or advance the instance finding journal-unavailable on compliance surface.
   reconcile step 2.11: The run MUST NOT call act probe BEFORE querying remaining((kind, act key), critical section holder).
   reconcile step 2.12: The run MUST examine the kept intents one at a time, steps 2 to 4 for one act before the next, oldest recording instant first (the window of Invariant 4.2 runs from the recording instant).
   ```
3. **Probe the database.**

   ```
   reconcile step 3.1: IF step 2 counted the act in no count AND service identity DOES NOT EQUAL none for the act's kind THEN the run MUST call the adopter's bound act probe on act key and intent payload.
   reconcile step 3.2: WHEN act probe EQUALS committed(outcome action reference, outcome data) AND service identity DOES NOT EQUAL none for the act's kind:
       reconcile step 3.2a: The run MUST write `<kind>.recovery_intended` under the service identity with data carrying invocation id, intent event id, act key and plan set to outcome.
       reconcile step 3.2b: The run MUST write the outcome record outcome action reference under the service identity with data set to recovered outcome payload.
       reconcile step 3.2c: The run MUST count closed.
   NOTE: watch applicability (reconcile step 1.2).
   reconcile step 3.3: A later run MAY write a second recovery_intended for the act.
   reconcile step 3.5: WHEN act probe EQUALS not-committed AND service identity DOES NOT EQUAL none for the act's kind:
       reconcile step 3.5a: The run MUST write `<kind>.escalated` under the service identity with data carrying invocation id, intent event id, act key and cause set to not-observed.
       reconcile step 3.5b: The run MUST count escalated.
   reconcile step 3.7: The sweep MUST NOT re-run an act.
   reconcile step 3.8: WHEN act probe EQUALS undecidable(candidates) AND service identity DOES NOT EQUAL none for the act's kind:
       reconcile step 3.8a: The run MUST write `<kind>.escalated` under the service identity with data carrying invocation id, intent event id, act key, cause set to undecidable and database candidates set to candidates, capped as reconcile step 3.9 says.
       reconcile step 3.8c: The run MUST count escalated.
   reconcile step 3.9: database candidates MUST NOT carry more than intent candidates cap references, the first of candidates in act probe's order.
   reconcile step 3.10: Past the cap, the escalated record MUST carry the count of EVERY candidate and the range, the first and the last of candidates in act probe's order; the range is a pair of bounds, no reference of database candidates, so a cap of 1 carries the first reference and a range that names the same reference twice.
   reconcile step 3.11: The sweep MUST NOT choose among candidates.
   reconcile step 3.12: The sweep MUST NOT write an outcome the sweep did not read.
   reconcile step 3.13: WHEN act probe EQUALS unavailable:
       reconcile step 3.13a: The run MUST NOT write to the journal for the act.
       reconcile step 3.13b: The run MUST release and count skipped.
       reconcile step 3.13c: The run MUST open or advance the instance finding store-unavailable for the act's kind.
   reconcile step 3.15: EVERY closing write's arms and EVERY recovery_intended write's arms MUST follow the outcome position.
   reconcile step 3.15a: The run MUST query remaining((kind, act key), critical section holder) behind the act probe and again behind each journal write of step 3 that another write follows, as that write's own reading (Durable Intent journal write bound 1).
   reconcile step 3.16: After invalid-request(step-4) (Audit Trail record action step 4.5), the run MUST read the record back by invocation id.
   reconcile step 3.16a: IF the read-back finds the record THEN the run MUST count the act in closed or escalated, as the write's arm counts the act and in place of any count the act held, with a hard alert.
   reconcile step 3.16b: IF the read-back finds nothing THEN the run MUST leave the write for the next run (reconcile step 3.17), with a hard alert.
   reconcile step 3.16c: IF the read-back answers unavailable or gives no answer THEN the run MUST leave the write for the next run (reconcile step 3.17), with a hard alert, and count the act in skipped.
   reconcile step 3.17: The run MUST leave EVERY step-2 arm and step-3 arm not landed within the lease for the next run.
   reconcile step 3.18: The run MUST surface an invalid-credential for a service identity on compliance surface at once, as a hard alert.
   reconcile step 3.19: The run MUST NOT write further under the credential once a write under the credential has answered invalid-credential; the next run's first write under the credential tries the credential again, and a write that answers otherwise ends the finding credential-refused (Escalation Term findings).
   reconcile step 3.20: An invalid-request(step-1), invalid-request(step-2) or invalid-request(step-3) on a closing write or on a recovery_intended write MUST close the act as `<kind>.escalated` with cause set to outcome-unrecordable, the write of that escalation excepted (reconcile step 3.23).
   reconcile step 3.21: The run MUST surface EVERY act the run closes as `<kind>.escalated` on compliance surface as the act finding escalated.
   reconcile step 3.22: The run MUST open or advance the instance finding journal-unavailable on compliance surface for EVERY recording-failure(step-2) and EVERY recording-failure(step-3) reconcile step 3.17 leaves for the next run.
   reconcile step 3.23: IF the escalation reconcile step 3.20 writes answers invalid-request(step-1), invalid-request(step-2) or invalid-request(step-3) THEN the run MUST leave the act for the next run with a hard alert.
   reconcile step 3.24: WHEN a write under a kind's service identity answers invalid-credential:
       reconcile step 3.24a: The run MUST open or advance the instance finding credential-refused on compliance surface for EVERY kind whose service identity EQUALS the service identity of the write.
   reconcile step 3.24b: IF an instance finding credential-refused stands for a kind once the run's condition read is taken THEN the run MUST surface EVERY aged intent of the kind step 1 kept and the run did not close as the act finding closure-at-risk, for an operator to close through [Resolve] (Escalation Invariant 4.11); a standing finding alone owes the report, whatever a write of this run answered.
   reconcile step 3.25: IF the run leaves the act for the next run at step 3 THEN the run MUST release.
   reconcile step 3.26: The run MUST count EVERY act reconcile step 3.20 closes in escalated, in place of any count the act held.
   ```
4. **Update and release.**

   ```
   reconcile step 4.1: The run MUST update open invocations.
   reconcile step 4.2: The run MUST update act closings.
   reconcile step 4.3: The run MUST update sweep closed ids.
   reconcile step 4.4: The run MUST release the critical section of EVERY act the run has not released already.
   ```
5. **Liveness.**

   ```
   reconcile step 5.1: IF at risk threshold DOES NOT EXCEED intent age THEN the run MUST surface an examined, skipped or unreached intent whose closing has not landed as the act finding closure-at-risk.
   reconcile step 5.9: IF an escalated record stands for an intent AND the intent's settling edge PRECEDES now AND now PRECEDES the intent's horizon edge THEN the run MUST surface the intent as the act finding closure-at-risk.
   reconcile step 5.8: The run MUST return the counts.
   ```
Term at risk threshold: `(((closure_window - (2 * run_bound)) - sweep_cadence) - clock_allowance)`.

Term intent age: `(now - recorded_at)`.

Term settling edge: `(horizon_edge - settling_period)` — the instant after which an escalation still standing has less than the kind's settling period left before the intent's horizon edge.

```
reconcile 6: An actor that is not a writer MUST NOT write a closing record.
reconcile 7: Two sweep runs MUST serialize on the critical section per act.
reconcile 7a: Two sweep runs MUST serialize on sweep closed ids under the critical section.
reconcile 8: The run MUST commit EVERY journal write for an act as a separate transaction, the recovery_intended record and the closing record apart, so a recovery_intended record stays committed when the closing write fails (reconcile step 3.3, reconcile step 3.22; Execution Contract Database 1 holds within each write).
reconcile 9: IF a take on act section answers storage-failure THEN the run MUST count the act in skipped with nothing written for the act (Execution Contract Constituent failure 1).
reconcile 9a: IF a release on act section answers storage-failure THEN the run MUST count the act in skipped, a write already committed for the act standing (Execution Contract Constituent failure 1).
```
## What is and what should never be (Invariants)

- **Invariant 2 — One writer per act.**
  ```
  Invariant 2.3: Two sweep runs MUST NOT close one act.
  ```
- **Invariant 4 — Bounded closure (safety + liveness).**
  ```
  Invariant 4.1: The records MUST reveal, provably, EVERY act whose invocation has yielded or died, as an aged intent with no record naming the intent's invocation id.
  Invariant 4.2: IF the journal and the adopter's database are reachable AND service identity DOES NOT EQUAL none for the intent's kind AND the intent's kind IS IN the bindings table AND no instance finding credential-refused stands for the kind THEN EVERY elapsed intent MUST carry a closing record, an outcome, an abandoned record or an escalation, WITHIN closure window of the intent's recording instant, an intent Escalation Check 3.3 exempts excepted.
  Invariant 4.3: WHEN the journal is unreachable:
      Invariant 4.3a: A writer MUST NOT close the intent during the outage.
  Invariant 4.4: [Reconcile] MUST surface a journal outage as the instance finding journal-unavailable, never as the outage's intents.
  Invariant 4.5: The outage finding MUST carry first seen per Term first seen and last seen per Term last seen.
  ```
  *Rests on:* [Reconcile]'s edges and steps 3–5; the kind's invocation completion bound and retention period; the instance's clock allowance, sweep cadence, run bound, closure latency, read bound, journal write bound and closure window; the substrate's range read; the starter's runs (sweep cadence 2, 3; Execution Contract Scheduled leg 1).

- **Invariant 5 — Recovery is derived, never remembered.**
  ```
  Invariant 5.1: The sweep MUST NOT write an outcome BEFORE writing one or more `<kind>.recovery_intended` records naming the act and the plan.
  Invariant 5.2: EVERY outcome the sweep writes MUST carry the service identity's attestation with the original caller in acting actor reference.
  Invariant 5.3: EVERY outcome the sweep writes MUST carry only what act probe re-derived from the database.
  ```
  ```
  Invariant 5.9: The sweep MUST escalate with candidates what the database cannot re-derive.
  Invariant 5.10: The sweep MUST NOT close an act whose database the sweep cannot read.
  ```
  *Rests on:* service identity (Bindings); Audit Trail Invariant 1 (the attesting actor is verified); [Reconcile] step 3. Generation acceptance Escalation Check 6.4 rests on Escalation Invariant 4.9, and [Resolve]'s too-young guard on Escalation Invariant 5.8: an operator's abandonment is the operator's attestation (Escalation resolve 32), not the database's word.

- **Invariant 7 — The sweep is bounded at both ends.**
  ```
  Invariant 7.1: [Reconcile] MUST NOT examine an in-flight intent.
  Invariant 7.2: [Reconcile] MAY examine an intent ONLY IF now PRECEDES the intent's horizon edge.
  Invariant 7.3: EVERY check MUST exclude an intent whose payload the substrate has destroyed.
  ```
  *Rests on:* Audit Trail Invariant 2 (retention coverage at quiescence — every `<kind>.*` record is placed under the kind's fixed policy, late at worst), Audit Trail Invariant 4 (the cascade destroys the payload), Audit Trail Invariant 8 and its read_record step 5 (destruction and an unplaced retention are each honestly reported), and the journal binding's fixed-policy obligation. [Reconcile] step 1 owns both edges.

## While something is so

### Terms the primitive policy reads

Term aged: an open intent for which examine edge DOES NOT EXCEED now.

Term elapsed intent: an intent, open or closed, for which examine edge DOES NOT EXCEED now.

Term horizon edge: `(((recorded_at + retention_period) - clock_allowance) - run_bound)` — the allowance for the two clocks, the run bound for the age of a run's one reading by the time the run reads and writes on it.

## Optional

### The act's critical section

- **act section**
  ```
  act section 11: The sweep MUST take the critical section on every act key the sweep examines.
  act section 12: The sweep MUST hold the critical section across the pre-check and the closing write.
  act section 13: A sweep run MUST leave a closing write in flight at expiry for the next run.
  ```
### Bounds the deployment declares

- **journal write bound**
  Term sweep lease: `(closure_latency + journal_write_bound)`.

- **sweep cadence**
  Term sweep cadence: the interval at which the sweep runs after the mandatory run at process restart. *Default:* none, required at start (Execution Contract Logic confinement 15).

  ```
  sweep cadence 2: A run MUST start WITHIN sweep cadence of the previous run's return, the death of the process that ran the previous run excepted (sweep cadence 3).
  sweep cadence 3: IF the process that ran the previous run has died THEN a run MUST start WITHIN run interval of the previous run's start.
  ```
  Term run interval: `(sweep_cadence + run_bound)` — the gap between two runs' starts that worst closure charges (Recoverable Invocation Instance start 4): a run's run bound, then the cadence.

- **closure latency**
  Term closure latency: the disclosed bound on one whole closure: re-read, act probe, `<kind>.recovery_intended`, the closing record, the index update. Condition 5. *Default:* none, required at start (Execution Contract Logic confinement 15).

- **run bound**
  Term run bound: the disclosed bound from a [Reconcile] run's start to the last closing it lands, over the largest backlog the deployment sizes for, the wait of each take counted, which Lease's take ends at the waiter's last reading (reconcile step 2.3); a backlog past the one the deployment sizes for is a breach of the deployment's own sizing, and no bound is claimed for it. *Default:* none, required at start (Execution Contract Logic confinement 15).

  ```
  run bound 1: A node MUST NOT start a run beside the node's own run in flight.
  run bound 2: A run whose step-1 enumeration gives no answer MUST end once run bound has elapsed since the run's start.
  ```
### Bindings the actions read

- **probe round trip**
  Term probe round trip: the longest one act probe call takes from issue to answer; charged by sweep lease spend.

## Left to others

### What the sweep never does

```
Sweep never 1: The sweep MUST NOT run adopter code other than act probe.
Sweep never 2: The sweep MUST NOT write under a human's credential.
Sweep never 3: The sweep MUST NOT read the adopter's database other than through act probe.
```
NOTE: the owners — [Durable Intent](./durable-intent.md) (the intent, the outcome and which closing stands); [Escalation](./escalation.md) (what the sweep cannot close, and the operator's closing); [Recoverable Invocation](../apps/recoverable-invocation/index.md) (the adopter's act probe, the bounds and the instance's start).

## Example

### The crash

**The crash.** The run dies between `SelectiveDisclosure.record` returning `dsc-411` and [Close]. The critical section stays held until its lease runs out at `t + 30 s`; the host does not see the death. Thirty-two seconds later a [Reconcile] run keeps `inv-7f2` (older than `30 + 2 s`, inside the horizon), takes the critical section, re-reads — still open — and probes: exactly one record matches → `committed(ledger.disclosure.disclosed, {disclosure_id: dsc-411, ...})`. The sweep writes `ledger.disclosure.recovery_intended` then `ledger.disclosure.disclosed` with `recovery = true, acting_actor_ref = <the discloser>`, both under `ledger-reconciler`, and releases. Accounted for within about forty-five seconds, inside the ten-minute window, by the one writer left alive.

**The credential refused.** The next run probes `inv-7f3` and the probe answers committed, but the first write under `ledger-reconciler` answers `invalid-credential`. The run surfaces a hard alert at once, opens the finding credential-refused for `ledger.disclosure`, counts the act in skipped and the intents it had not yet examined in unreached, writes nothing further under the credential, and surfaces every aged intent of the kind it kept as closure-at-risk, for an operator to close through [Resolve]. The run after it tries the credential again with its first write.

## Source

The composition anchors the accountability a regulated adopter's regime requires of a consequential act: an attributable record of intent before the act, a record of outcome after it, and a bounded, attributable account of any act the process failed to record — SOX section 404 (Sarbanes-Oxley Act — internal controls over financial reporting), HIPAA section 164.312(b) (Health Insurance Portability and Accountability Act — audit controls), PCI DSS Requirement 10 (Payment Card Industry Data Security Standard — logging and monitoring), 21 CFR (Code of Federal Regulations) Part 11 (electronic records and signatures), and GDPR (General Data Protection Regulation) Article 30 and Article 32 (records of processing; integrity of processing). Each adopter's own section names the regime its act falls under; this composition supplies the form the regime's *accountability* clause requires and no substantive judgment about the act.

## Proof

### Generation acceptance

A derived implementation of Sweep is acceptable when the following are provable to an auditor given the journal and the adopter's constituent records.

#### Conformance checks

```
Check 3.1: For EVERY elapsed intent for which the auditor's now PRECEDES the intent's horizon edge, of a kind whose service identity DOES NOT EQUAL none, a closing record MUST land WITHIN closure window of the intent's recording instant, the auditor's reading tolerating clock allowance across seams, an intent Escalation Check 3.3 exempts excepted.
Check 3.2: An auditor MUST exempt an intent of a kind the bindings table no longer serves from Check 3.1, Escalation Check 3.5 and Escalation Check 3.6.
```
```
Check 5.1: EVERY record the service identity attests whose named intent is inside the horizon MUST name an invocation id whose intent record exists and is attested by a different actor.
Check 5.2: An auditor MUST report a service-identity record naming no readable intent inside the horizon as a write outside this composition.
Check 5.3: An auditor MUST answer purged for a service-identity record whose intent is Purged.
Check 6.1: For EVERY outcome that stands and whose recovery EQUALS true, act probe run by the auditor against the constituent records as of the outcome's commit (Execution Contract Database 5, Database 8) MUST corroborate outcome data or answer unavailable, an outcome carrying a resolving actor also passing where act probe answers undecidable with outcome data among the candidates.
Check 6.2: An auditor MUST read unavailable as not applicable, never as failed.
```
```
Check 7.1: An auditor MUST exclude an intent the substrate reports Purged from every check.
Check 7.2: An auditor MUST quantify Durable Intent Check 1, Durable Intent Check 2 and Check 3 over intents whose payload is readable.
Check 7.3: An auditor MUST exclude from Durable Intent Check 2 and Check 3 an intent whose horizon edge PRECEDES the auditor's now.
```
#### External checks

```
External check 10: An auditor MUST clear from external evidence that EVERY invalid-credential a write under a service identity answered was surfaced on compliance surface at once as a hard alert (reconcile step 3.18).
External check 11: An auditor MUST clear from external evidence that runs start as sweep cadence 2 and 3 state (Execution Contract Scheduled leg 1).
```
### Vocabulary

Term actors: invocation; sweep run (also: the sweep, the run); operator; adopter's action (also: the adopter, the action); caller; deployment; auditor; substrate; critical section host (also: the host); writer — EXACTLY ONE OF invocation, sweep run, operator; reader; register (the deployment's findings surface); surface — [Read Invocation] or Generation acceptance check 2.

Term records: `<kind>.intended`, `<kind>.<outcome>`, `<kind>.refused`, `<kind>.recovery_intended`, `<kind>.abandoned`, `<kind>.escalated`, [Finding].

Term record verbs: write, read, read back, take, release, hold, yield, adopt, retry, refuse, return, surface, count, probe, close, examine, keep, drop, name, carry, size, validate, land, supersede, rebuild, populate, clear, discard, report, proceed, wait, persist, start, derive, sample, declare, bind, treat, transcribe, issue, mint, reach, reveal, escalate, abandon, open, advance, set, move, admit, exclude, stand, serialize, time, query, run, pass, decide, pair, share, stay, sum, rely, trigger, exist, answer, call, follow, re-read, leave, supply, perform, exempt, bound, block, use, re-run, match, map, make, export, classify, choose, cap, vary, update, touch, suppress, stamp, retain, resolve, remove, reject, recover, record, re-take, partition, own, owe, omit, offer, know, inspect, govern, free, fire, end, describe, corroborate, confirm, compare, collapse, check, charge, change, belong, add, commit, append, quantify, survive.

Term cited: take, try_take, remaining, expiry instant, call in flight, no answer: Lease. record_action, read_record, payload cap, reference length cap, attestation id width, retention policy, recording instant, sequence number, next sequence number, event id, action reference, policy reference, retention deadline, reserved namespace, retention state, Retained, Purged: Audit Trail. write floor, examine edge, in-flight, hard alert, critical section holder: Durable Intent. act finding, instance finding, condition read, resolving actor: Escalation.

Term value sets: landing actor = invocation | sweep | operator. state = open | closed | refused | abandoned | escalated | resolved. disposition = outcome | abandoned | escalated. act probe answers committed | not-committed | undecidable | unavailable. commit partition = pre-commit | committed | unknown. repeatable = yes | no. service identity = an actor | none. findings = journal-unavailable | store-unavailable | credential-refused | closure-at-risk | unbound-kind | escalated. [Resolve]'s invalid-request causes = purged | malformed | too-young | already-abandoned | candidates-over-cap.

Term recovered outcome payload: the outcome payload with recovery set to true and acting actor reference set to the intent's actor reference added.

Term acting actor reference: the original caller's actor reference, carried by an outcome the sweep or an operator writes (Invariant 5.2, Escalation Invariant 5.4).

Term plan: the field of a `<kind>.recovery_intended` record naming the closing the sweep is about to write, set to outcome (reconcile step 3.2a).

Term recovery_intended: a `<kind>.recovery_intended` record — the sweep's statement of an act and its plan, written before the outcome it names (Invariant 5.1).

Term database candidates: the records in the database an `<kind>.escalated` record names as possibly the intent's, at most intent candidates cap of them (reconcile step 3.8a).

Term run id: a sweep run's own seam-injected id, fresh for every run; with the examined intent's invocation id, the critical section holder for one take.

Term bounds: invocation completion bound, commit round trip, probe round trip, journal write bound, pause bound, read bound, closure latency, run bound, closure window, clock allowance, retention period, settling period, intent candidates cap, read cap.

Term cadences: sweep cadence.

Term qualifiers: migrated — rewritten in GRACE-lang, the corpus's rule grammar, v0.35 (2026-09-11).

Term terms: (named expressions, each declared where it is used) worst closure, examine window end, retention floor, lease spend, run floor, sweep lease spend, examine edge, horizon edge, at risk threshold, settling edge, intent age, settle bound, retention end, sweep lease, run interval, in-flight, aged, partition, examined, skipped, reported, surfaced, unreached, closed already, standing closing, terminus, caller kind, payload match, act quiescence, read path, read-your-writes, journal join, lost reply, `position's existing arm`, cross-seam comparison, critical section key, critical section holder, critical section duration, reply, release, hard alert, unfenced write, write floor, commit floor, act finding, instance finding, kind, act key, invocation id, now, operator run id, resolve refusal, open result, close result, reconcile tally, invocation report, invocation entry, first seen, last seen, condition read, span, acting actor reference, resolving actor, recovery_intended, database candidates, readable intent.

[Reconcile]: #reconcile
[Close]: ./durable-intent.md#close
[Finding]: ./escalation.md#finding
[Read Invocation]: ./durable-intent.md#read-invocation
[Resolve]: ./escalation.md#resolve

## Status

`done — 2026-11-23` — see the Ledger.

<details markdown="block">
<summary>
    <h2 id="ledger" style="display: inline-block; margin-left: 1.5rem;">Ledger</h2>
</summary>

```
status: done — 2026-11-23
formal: pending — no model yet; new formal modelling is paused (budget.toml formal_new_models, Scott 2026-11-23) and Lean replaces the model layer
last gate: 2026-11-23 — Final Critique 3, a delta round (diff base 817faf2c, 42 labels), one reader (Linus opencode/beam-free; GRID and EOS not run), frozen at 07887353 — foundational count 0 after the blind second triage, clean, one sample; Linus's one foundational claim refuted (reconcile step 1.2 and Invariant 7.2 read the one `now` a run takes at the sweep's seam, Execution Contract Scheduled leg 2 and Logic confinement 11, and Term horizon edge charges run bound for that reading's age, so a kept intent satisfies Invariant 7.2 through the run; a backlog past the deployment's sizing is a breach of that sizing, Term run bound); the rhetorical claim (reconcile step 1.2's relative clause) is the watched applicability pressure the page already flags; no cure; model redraw deferred to Lean: none
open: none
```

</details>

<details markdown="block">
<summary>
    <h2 id="decisions" style="display: inline-block; margin-left: 1.5rem;">Decisions</h2>
</summary>

- **2026-11-23 — Split out of Recoverable Invocation.** *Chose:* the rules of Reconcile and the sweep's bounds, Invariant 2.3, Invariant 4.1 through 4.5, 5.1 through 5.3, 5.9, 5.10 and 7, moved as they stood, a rule changing only where its owner's name changed. *Over:* one page carrying the whole protocol after 57 rounds. *Because:* a pattern that has run far past the round cap does not ground, and the corpus is moving from compositions to atoms, bonds and marked glue (Scott, 2026-11-23, rulings of 05:35Z and 9:29 AM Central).

</details>

NOTE: End of Sweep.
