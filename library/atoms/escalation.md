---
title: Escalation
id: 78
audience: common
has_toc: true
toc: true
---

# Escalation

<details markdown="block">
<summary>Table of contents</summary>
{: .text-xs .font-medium .uppercase .tracking-wide .opacity-50 }
1. TOC
{:toc}
</details>

## What it is

Escalation is how a person finishes what the sweep could not: the findings the instance leaves on the deployment's compliance surface (what the sweep could not close and what the instance could not do), the closure-at-risk finding that tells a person an act's window is running out, and [Resolve], the operator's own closing of an act under the same critical section the invocation and the sweep use. Only a person abandons an act, as the operator's own attested write, and an operator's closing carries the resolving actor so that it can be told from the sweep's.

<details markdown="block">
<summary>WHY</summary>

An act the database cannot certify is no act a program may close for the person who made it, because a guessed outcome in a regulated account is worse than a late one, and its findings must reach a person before the act's window ends. This atom holds the person's side: the findings, the operator's [Resolve] and the closure-at-risk finding, with the sweep's escalation records as what it reads (Scott, 2026-11-23, ruling of 9:29 AM Central). The findings register's protocol is owed to an atom of its own and moves there when that atom is bonded; the rules stay here until that atom's own text covers each (findings 3 through 13).

</details>

## What it keeps

### Journal terms

Term closing event id: closing_event_id — the event id of a closing record. Where already-accounted carries it, it is the event id of the invocation's standing closing (Term standing closing), whichever writer wrote it; where [Resolve] answers it, and does not refuse, it is the event id of the closing [Resolve] writes (resolve 35).

### The findings register

- **findings**
  Term findings: the register of what the sweep could not close and what the instance could not do, written to the deployment's compliance surface. *Extraction-pending*: an atom of its own is owed.

  ```
  findings 1: The deployment MUST persist a finding naming a kind the bindings table serves for at least the retention period of that kind.
  findings 2: The deployment MUST persist a finding naming no kind for at least the instance's longest retention period.
  findings 3: A surfacing that fails MUST NOT reject a [Reconcile] run that has landed closings.
  findings 4: The register MUST write a [Finding] as EXACTLY ONE OF act finding, instance finding.
  findings 5: An instance finding MAY omit kind ONLY IF the instance finding is journal-unavailable.
  findings 6: A surface MUST NOT read a finding outside the six conditions.
  findings 7: The register MUST set first seen at the first surfacing.
  findings 8: The register MUST NOT move first seen.
  findings 9: The register MUST advance last seen on every run that still sees an instance finding's condition.
  findings 10: WHEN a run does not see a standing instance finding's condition:
      findings 10a: IF the run's condition read answered that the condition does not stand THEN the register MUST close the record with last seen per Term last seen.
      findings 10b: IF the run made no condition read, or the run's condition read gave no answer, THEN the register MUST NOT close the record.
  findings 11: The register MUST open a new record for a recurrence of an instance finding's condition after the record closed (findings 10a).
  findings 12: The register MUST hold one record per standing condition of an instance finding.
  findings 13: A reader MUST NOT rely on an order across act keys.
  findings 14: The deployment MUST persist a finding naming a kind the bindings table does not serve for at least the instance's longest retention period.
  findings 15: The register MUST open no second record for an act finding on the act finding's deduplication key.
  NOTE: until the register moves onto an atom of its own (`roadmap.md` states where it stands), the deployment persists the register (findings 1, findings 2 and findings 14) and this pattern states its records (findings 3 through 13); the debt is that no atom owns either yet, and the atom, when it lands, takes both.
  ```
  Term act finding: {finding, kind, act_key, invocation_id, first_seen, run_id}; deduplicates on (invocation id, finding); carries no last seen and no span. An act finding records a sighting; whether the act still stands escalated is [Read Invocation]'s answer, not the register's.

  Term instance finding: {finding, kind, first_seen, last_seen, run_id}; deduplicates on (finding, kind) while the record stands (findings 12).

  Term first seen: the run that first surfaced a finding, with the run's reading of now; set once (findings 7, findings 8).

  Term condition read: the read, or the answer of a write, that tells a run whether an instance finding's condition stands: [Reconcile] step 1's enumeration for journal-unavailable, the act probe of the kind for store-unavailable, at [Reconcile] step 3 for a kind that declares a service identity and under Sweep reconcile 2b for a kind under none, and the answer of the run's write under the kind's service identity at [Reconcile] step 3 for credential-refused. A run sees the condition when its condition read answers that it stands; a run that makes no condition read, or whose condition read gives no answer, has no reading of it, and a condition read that answered with no record in it has answered (Execution Contract Read 2; findings 9, findings 10).

  Term last seen: the last run that still saw an instance finding's condition, with the run's reading of now (findings 9, findings 10).

  Term span: an instance finding's first seen to the finding's last seen, each with the run's reading of now, as the register records the outage (Sweep Invariant 4.5); Check 3.3 and Check 3.4 read the span.
  The six conditions:
  - journal-unavailable — instance finding, no kind: the journal could not be read or written this run ([Reconcile] step 1, Sweep reconcile step 2.10, Sweep reconcile step 3.22).
  - store-unavailable — instance finding, kind present: the kind's adopter's database answered unavailable to act probe ([Reconcile] step 3, Sweep reconcile 2g).
  - credential-refused — instance finding, kind present: a write under a service identity answered invalid-credential, and the kind's service identity EQUALS it ([Reconcile] step 3, Sweep reconcile step 3.18, Sweep reconcile step 3.24a); a run's write under the identity that answers otherwise ends it.
  - closure-at-risk — act finding: the act's remaining window is no more than two run bounds, a sweep cadence and the clock allowance (Sweep reconcile step 5.1), or an escalation still standing has less than the kind's settling period left before its intent's horizon edge (Sweep reconcile step 5.9), or an aged intent of a kind whose credential-refused stands (Sweep reconcile step 3.24b, Invariant 4.11). Generation acceptance check 3's `service_identity = none` branch reads it.
  - unbound-kind — act finding: an open intent of a kind the instance no longer binds.
  - escalated — act finding: the sweep closed the act as `<kind>.escalated` and an operator's [Resolve] is what ends it ([Reconcile] step 3).

## What people do

### Resolve

The human-attested close: an operator, present with an own credential, closes an open intent the sweep cannot — under a report-only deployment, or after investigating an escalation — supplying the disposition the operator's own run of act probe supports; the record carries `recovery = true` and resolving actor.

Kind: Operation

```
resolve(kind, act_key, invocation_id, intent_event_id, actor_ref, credential, disposition)
  answers closing_event_id
  refuses already-accounted(closing_event_id) | not-known | section-unavailable | invalid-credential | invalid-request(resolve refusal) | recording-failure(resolution)
```
The human-attested close: an operator closes an open intent the sweep cannot — under `service_identity = none`, or for an escalated act the operator has investigated — supplying the disposition the operator's own run of the adopter's act probe supports. An operator corrects an outcome an operator wrote by an outcome naming it in supersedes (resolve 36).

```
resolve 1: The operator MUST supply disposition as EXACTLY ONE OF outcome(outcome action reference, outcome data), abandoned(cause), escalated(candidates).
resolve 2: The substrate MUST validate the operator's credential at the closing record_action and nowhere earlier.
resolve 3: A credential failure MUST land invalid-credential with the critical section released and nothing appended.
resolve 4: [Resolve] MUST take the critical section: take((kind, act key), operator run id, sweep lease).
resolve 4a: IF caller kind EQUALS service THEN [Resolve] MUST land invalid-request(malformed) with no take and nothing appended.
resolve 6: A failed take, a storage-failure and no answer included (Execution Contract Constituent failure 1, Bonds guard 2), MUST land section-unavailable.
resolve 7: WHEN a remaining [Resolve] queried DOES NOT EXCEED write floor:
    resolve 7a: [Resolve] MUST NOT write.
    resolve 7b: [Resolve] MUST release.
    resolve 7c: [Resolve] MUST land section-unavailable.
resolve 38: [Resolve] MUST NOT re-read BEFORE querying remaining((kind, act key), operator run id).
resolve 39: [Resolve] MUST NOT write the closing record of resolve 21 BEFORE querying remaining((kind, act key), operator run id) again, behind the re-read of resolve 8, for the closing record.
resolve 8: [Resolve] MUST re-read the journal from sequence high water for the act key under the critical section.
NOTE: watch rule inheritance.
resolve 9: IF an outcome or a refusal names the invocation id THEN [Resolve] MUST land already-accounted(closing event id), an outcome carrying a resolving actor excepted.
resolve 10: An intent event id read_record answers not-known for MUST land not-known, an intent whose payload the substrate reports Purged excepted.
resolve 11: [Resolve] MUST read the intent by read_record(intent event id).
resolve 12: An intent whose payload the substrate reports Purged MUST land invalid-request(purged).
resolve 13: EVERY closing [Resolve] writes over a standing closing MUST carry supersedes naming that closing's event id.
resolve 14: WHEN no closing stands:
    resolve 14a: [Resolve] MAY write any disposition as the act's closing.
resolve 15: WHEN an escalated record stands:
    resolve 15a: [Resolve] MUST name the record in supersedes for any disposition.
resolve 16: WHEN an abandoned record stands:
    resolve 16a: [Resolve] MAY supersede the record ONLY IF disposition EQUALS outcome.
    resolve 16b: IF disposition DOES NOT EQUAL outcome THEN [Resolve] MUST land invalid-request(already-abandoned).
resolve 36: WHEN an outcome carrying a resolving actor stands:
    resolve 36a: [Resolve] MAY supersede the outcome ONLY IF disposition EQUALS outcome.
    resolve 36b: IF disposition DOES NOT EQUAL outcome THEN [Resolve] MUST land already-accounted(closing event id).
resolve 18: An abandoned disposition for an in-flight intent MUST land invalid-request(too-young).
resolve 19: The too-young guard MUST compare against now injected at the operator's seam.
resolve 32: [Resolve] MUST admit the operator's abandoned disposition for an elapsed intent as the operator's attestation that the database has been quiet for as long as the operator's judgment requires.
resolve 21: [Resolve] MUST write the closing record under the operator's own credential with recovery set to true, resolving actor set to actor reference, acting actor reference set to the intent's actor reference, and no recovery_intended.
resolve 22: [Resolve] MUST release after the write.
resolve 23: The closing write's arms MUST follow the resolution position of resolve 24 through 29.
resolve 24: After invalid-request(step-4), [Resolve] MUST read the record back by invocation id and return success with a hard alert.
resolve 25: [Resolve] MUST NOT retry after invalid-request(step-3) or invalid-request(step-4).
resolve 26: recording-failure(step-2) and a lost reply (a recording-failure(step-3) included) MUST land recording-failure(resolution), a lost reply whose read-back finds the record excepted.
resolve 27: invalid-request MUST carry the cause: malformed, candidates-over-cap, purged, already-abandoned, too-young.
resolve 27a: IF the grounds of more than one cause of resolve 27 apply to one call THEN [Resolve] MUST carry the cause resolve 27 lists first.
resolve 28: A candidate list exceeding intent candidates cap MUST land invalid-request(candidates-over-cap).
resolve 29: An invalid-request(step-1), invalid-request(step-2) or invalid-request(step-3) from the closing write MUST land recording-failure(resolution).
resolve 40: [Resolve] MUST surface a hard alert for an invalid-request(step-1), invalid-request(step-2) or invalid-request(step-3) from the closing write.
resolve 30: A disposition outside the three forms resolve 1 names MUST land invalid-request(malformed) with no take and nothing appended.
resolve 31: A disposition whose outcome action reference IS NOT IN the kind's enumerated outcome refs MUST land invalid-request(malformed) with no take and nothing appended.
resolve 33: IF kind IS NOT IN the bindings table THEN [Resolve] MUST land invalid-request(malformed) with no take and nothing appended.
resolve 33a: IF act key EQUALS blank OR invocation id EQUALS blank OR intent event id EQUALS blank THEN [Resolve] MUST land invalid-request(malformed) with no take and nothing appended.
resolve 33b: [Resolve] MUST NOT answer already-accounted or not-known for a call that resolve 4a, resolve 30, resolve 31, resolve 33 or resolve 33a lands as invalid-request(malformed).
NOTE: watch the blank id (resolve 34).
resolve 34: An intent event id naming no `<kind>.intended` record of the act key carrying invocation id MUST land not-known, an intent whose payload the substrate reports Purged and a blank act key, invocation id or intent event id (resolve 33a) excepted.
resolve 35: [Resolve] MUST return closing event id for the closing the write lands.
resolve 37: IF [Resolve] holds the critical section AND [Resolve] lands a refusal THEN [Resolve] MUST release.
```
## What is and what should never be (Invariants)

- **Invariant 4 — Bounded closure (safety + liveness).**
  ```
  Invariant 4.6: IF service identity EQUALS none THEN EVERY aged intent of a kind the bindings table serves MUST carry the act finding closure-at-risk WITHIN closure window, for an operator to close through [Resolve].
  Invariant 4.7: PROVISIONAL: Sweep Invariant 4.2 DEGRADES TO Invariant 4.6, and to Invariant 4.11 for a kind whose credential-refused stands.
  Invariant 4.8: A closing record the sweep writes for an act the database cannot certify as not-committed MUST carry the action reference `<kind>.escalated`.
  Invariant 4.9: The sweep MUST NOT abandon an act.
  Invariant 4.11: IF an instance finding credential-refused stands for the intent's kind THEN EVERY aged intent of the kind the bindings table serves MUST carry the act finding closure-at-risk WITHIN closure window, for an operator to close through [Resolve].
  ```
- **Invariant 5 — Recovery is derived, never remembered.**
  ```
  Invariant 5.4: EVERY outcome an operator writes through [Resolve] MUST carry the operator's own attestation, the original caller in acting actor reference, and resolving actor.
  Invariant 5.5: An operator's outcome MUST NOT owe a recovery_intended.
  Invariant 5.8: An operator MAY write abandoned ONLY IF the intent is an elapsed intent, as the operator's own attestation.
  ```
## While something is so

### Terms the primitive policy reads

Term operator run id: injected at the operator's seam once per [Resolve] call, fresh for every call; the critical section holder for [Resolve].

## Optional

### What the substrate supplies

```
Capability requirement 9: A read_record that cannot reach the journal MUST land recording-failure(resolution) at [Resolve].
Capability requirement 10: A read_record that cannot reach the journal MUST NOT answer not-known.
```
```
Capability requirement 18: A read_record that answers state-unavailable MUST land recording-failure(resolution) at [Resolve] (Execution Contract Read 1).
NOTE: watch the constituent's failed read.
Capability requirement 19: A read_record at [Resolve] that returns nothing within read bound MUST land recording-failure(resolution).
```
### Bounds the deployment declares

- **intent candidates cap**
  Term intent candidates cap: the most database candidates an `<kind>.escalated` record names, each under reference length cap. Sizes the escalation. *Default:* none.

## Needs

The bonds this atom needs, each of a bond kind [Bonds](../bonds.md) states.

Term need guard: key critical section key; holder critical section holder; span duration; calls take, remaining, release; arms expires_at, unavailable, remaining_term, none, released, no answer; writes closing record.

Term need key: key invocation id; pairs closing record.

## Left to others

NOTE: the owners — an atom of its own, owed (the findings register's protocol, findings 3 through 13, and the register's persistence in findings 1, findings 2 and findings 14; a bond owed, not yet written); the atom whose records this one follows by key (the intent and which closing stands); the sweep (what the sweep closes and escalates).

## Example

### The stall

**The stall.** The run does not die; `SelectiveDisclosure.record` is slow, past the commit round trip the deployment disclosed — outside the bounds, and what follows is what the protocol still holds there. The database applies the write at eight seconds; the adopter, unanswered past its commit round trip, has already yielded and returned `recording-failure(outcome)`, and the sweep at thirty-five probes committed and closes it. Or the database never applied the write, and the act probe answers not-committed — not final, since a process paused past the lease could still land the commit at forty-five. The sweep writes escalated with `cause = not-observed`; the operator writes the abandonment through [Resolve] once the database has been quiet long enough. A write landing at fifty after a sweep read the database empty at thirty-five is survivable: the escalation stands, the operator's later run of the act probe finds the record, and the disposition is outcome.

## Source

The composition anchors the accountability a regulated adopter's regime requires of a consequential act: an attributable record of intent before the act, a record of outcome after it, and a bounded, attributable account of any act the process failed to record — SOX section 404 (Sarbanes-Oxley Act — internal controls over financial reporting), HIPAA section 164.312(b) (Health Insurance Portability and Accountability Act — audit controls), PCI DSS Requirement 10 (Payment Card Industry Data Security Standard — logging and monitoring), 21 CFR (Code of Federal Regulations) Part 11 (electronic records and signatures), and GDPR (General Data Protection Regulation) Article 30 and Article 32 (records of processing; integrity of processing). Each adopter's own section names the regime its act falls under; this composition supplies the form the regime's *accountability* clause requires and no substantive judgment about the act.

## Proof

### Generation acceptance

A derived implementation of Escalation is acceptable when the following are provable to an auditor given the journal and the adopter's constituent records.

#### Conformance checks

```
Check 3.3: An auditor MUST exempt an intent whose window overlaps any span of journal-unavailable, or of store-unavailable or credential-refused for the intent's kind.
Check 3.4: An auditor MUST NOT exempt an intent for the healthy gap between two spans, the gap running from a closed record's last seen to the next record's first seen (findings 10a, findings 11).
Check 3.5: IF service identity EQUALS none THEN the register MUST carry EVERY aged intent of a kind the bindings table serves as a closure-at-risk act finding WITHIN closure window.
Check 3.6: IF an intent's window overlaps a span of credential-refused for the intent's kind THEN the register MUST carry the intent, an intent a closing record names excepted, as a closure-at-risk act finding WITHIN closure window.
```
```
Check 6.4: EVERY `<kind>.abandoned` MUST carry a resolving actor.
Check 6.5: EVERY database candidates entry of an `<kind>.escalated` record carrying no resolving actor MUST match a database record of the intent.
```
#### External checks

```
External check 1: An auditor MUST clear from external evidence that a declared outage of the journal or the adopter's database was surfaced on compliance surface with first seen and last seen, and that every intent whose window overlapped the outage was closed once the outage ended.
```
```
External check 5: WHEN service identity EQUALS none:
    External check 5a: An auditor MUST clear from external evidence that the aged intents the register carries as closure-at-risk (Check 3.5) were acted on through [Resolve].
```
### Vocabulary

#### Finding

A record in the instance's findings register (*Composition state* owns the contract). An act finding names one act the run could not close and carries no span; an instance finding names a condition of the instance, or of one bound kind, and carries one.

Kind:       Type
Role:       the surfaced record
Projection: finding

Term actors: invocation; sweep run (also: the sweep, the run); operator; adopter's action (also: the adopter, the action); caller; deployment; auditor; substrate; critical section host (also: the host); writer — EXACTLY ONE OF invocation, sweep run, operator; reader; register (the deployment's findings surface); surface — [Read Invocation] or Generation acceptance check 2.

Term records: `<kind>.intended`, `<kind>.<outcome>`, `<kind>.refused`, `<kind>.recovery_intended`, `<kind>.abandoned`, `<kind>.escalated`, [Finding].

Term record verbs: write, read, read back, take, release, hold, yield, adopt, retry, refuse, return, surface, count, probe, close, examine, keep, drop, name, carry, size, validate, land, supersede, rebuild, populate, clear, discard, report, proceed, wait, persist, start, derive, sample, declare, bind, treat, transcribe, issue, mint, reach, reveal, escalate, abandon, open, advance, set, move, admit, exclude, stand, serialize, time, query, run, pass, decide, pair, share, stay, sum, rely, trigger, exist, answer, call, follow, re-read, leave, supply, perform, exempt, bound, block, use, re-run, match, map, make, export, classify, choose, cap, vary, update, touch, suppress, stamp, retain, resolve, remove, reject, recover, record, re-take, partition, own, owe, omit, offer, know, inspect, govern, free, fire, end, describe, corroborate, confirm, compare, collapse, check, charge, change, belong, add, commit, append, quantify, survive.

Term cited: take, try_take, remaining, expiry instant, call in flight, no answer: Bonds. critical section key, critical section holder, invocation id, act key: Declarations. record_action, read_record, payload cap, reference length cap, attestation id width, retention policy, recording instant, sequence number, next sequence number, event id, action reference, policy reference, retention deadline, reserved namespace, retention state, Retained, Purged: Audit Trail. caller kind, in-flight, standing closing, lost reply, hard alert, write floor, sequence high water, read path, now: Durable Intent. aged, elapsed intent, horizon edge, sweep lease, acting actor reference, recovery_intended, database candidates: Sweep.

Term value sets: landing actor = invocation | sweep | operator. state = open | closed | refused | abandoned | escalated | resolved. disposition = outcome | abandoned | escalated. act probe answers committed | not-committed | undecidable | unavailable. commit partition = pre-commit | committed | unknown. repeatable = yes | no. service identity = an actor | none. finding conditions = journal-unavailable | store-unavailable | credential-refused | closure-at-risk | unbound-kind | escalated. [Resolve]'s invalid-request causes = malformed | candidates-over-cap | purged | already-abandoned | too-young.

Term resolving actor: the operator's actor reference, carried by a closing record an operator writes through [Resolve] (resolve 21).

Term cause: not-committed | not-observed | undecidable | outcome-unrecordable — the closing record's escalation or abandonment cause.

Term bindings table: the table of act kinds the instance serves, each with its binding set, which the deployment declares.

Term kind: the act kind an invocation belongs to — a key of the bindings table while the instance serves the kind, and the `<kind>` of every action reference the act's records carry.

Term service identity: a registered actor in the substrate's Actor Identity registry (actor reference and credential) under which the sweep writes, or none.

Term bounds: invocation completion bound, commit round trip, probe round trip, journal write bound, pause bound, read bound, closure latency, run bound, closure window, clock allowance, retention period, settling period, intent candidates cap, read cap.

Term cadences: sweep cadence.

Term qualifiers: migrated — rewritten in GRACE-lang, the corpus's rule grammar, v0.35 (2026-09-11).

Term terms: (named expressions, each declared where it is used) worst closure, examine window end, retention floor, lease spend, run floor, sweep lease spend, examine edge, at risk threshold, settling edge, intent age, settle bound, retention end, run interval, partition, examined, skipped, reported, surfaced, unreached, closed already, terminus, payload match, act quiescence, read-your-writes, journal join, `position's existing arm`, cross-seam comparison, critical section key, critical section duration, reply, release, unfenced write, commit floor, act finding, instance finding, operator run id, resolve refusal, open result, close result, reconcile tally, invocation report, invocation entry, first seen, last seen, condition read, span, resolving actor, readable intent.

[Resolve]: #resolve
[Finding]: #finding
[Read Invocation]: ./durable-intent.md#read-invocation
[Reconcile]: ./sweep.md#reconcile

## Status

`done — 2026-11-23` — see the Ledger.

<details markdown="block">
<summary>
    <h2 id="ledger" style="display: inline-block; margin-left: 1.5rem;">Ledger</h2>
</summary>

```
status: done — 2026-11-23
formal: pending — no model yet; new formal modelling is paused (budget.toml formal_new_models, Scott 2026-11-23) and Lean replaces the model layer
last gate: 2026-11-23 — Final Critique 2, a delta round, one reader (Linus opencode/beam-free), frozen at b8a27b32 — foundational count 0 after the blind second triage, clean, one sample; Linus's two foundational claims refuted (act findings key on the invocation id, one per intent; findings 10b leaves an unread run's interval unread, and its cure would split a real outage), one refining cured (Check 3.4 says what the healthy gap is)
open: none
```

</details>

<details markdown="block">
<summary>
    <h2 id="decisions" style="display: inline-block; margin-left: 1.5rem;">Decisions</h2>
</summary>

- **2026-11-23 — Split out of Recoverable Invocation.** *Chose:* the rules of Resolve and the findings, the closure-at-risk finding, Invariant 4.6 through 4.9, 4.11, 5.4, 5.5 and 5.8, moved as they stood, a rule changing only where its owner's name changed. *Over:* one page carrying the whole protocol after 57 rounds. *Because:* a pattern that has run far past the round cap does not ground, and the corpus is moving from compositions to atoms, bonds and marked glue (Scott, 2026-11-23, rulings of 05:35Z and 9:29 AM Central).

</details>

NOTE: End of Escalation.
