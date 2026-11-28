---
title: Durable Intent
id: 76
audience: common
---

# Durable Intent

<details markdown="block">
<summary>Table of contents</summary>
1. TOC
{:toc}
</details>

## What it is

Durable Intent is the account a regulated action leaves of something it cannot take back: one record written before the act says what the act is about to do, the adopter's database makes the act, and one record written after says what happened, so that every act has one closing that stands, written by one writer at a time. An action that adopts it opens an invocation ([Open] takes the act's critical section, a guard held over the act, and writes the intent record under the caller's own credential); [Close] then writes the outcome, [Refuse] writes that the act was refused before it committed, [Yield] gives the act up where its result is unknown, and [Read Invocation] tells a caller what stands for an act. Where the process dies between the two records, the account is left open in the journal for another pattern to finish.

<details markdown="block">
<summary>WHY</summary>

An irreversible act and its account are two writes no transaction spans, because the library's rule since 2026-08-27 is that an atomic set may not contain a write the host cannot take back; the order intent, act, outcome therefore leaves exactly one reachable partial, the act committed with its record owed. This atom owns the two writes, the rule that one invocation has one standing closing (*Which closing stands*) and the position every code carries; the clean-up of the partial and a person's part belong to the atoms that follow this atom's records by key, each keeping its own rules for what it does with them (Scott, 2026-11-23, the split of Recoverable Invocation, ruling of 9:29 AM Central).

</details>

## What it keeps

### Journal terms

Term position's existing arm: `recording-failure(intent)` at [Open]; `recording-failure(outcome)` at [Close]; `recording-failure(refusal, constituent_code)` at [Refuse]; `recording-failure(resolution)` at [Resolve]; at the sweep's writes, which follow the outcome position, the act left for the next run.

Term constituent code: constituent_code — the refusal code a constituent returned, carried beside the composition's own.

### Derived indexes

- **open invocations**
  Term open invocations: map from `(kind, act_key)` to the set of intent records (intent event id, invocation id, the payload) of every invocation of the act that has opened and not yet closed, refused, been abandoned or been escalated. Derived index. Past the horizon it holds no intent (open invocations 7), and no reader needs one there: every read drops an intent whose retention end has passed (sequence high water 5).

  ```
  open invocations 1: IF service identity DOES NOT EQUAL none THEN two open intents MUST NOT share one (kind, act key).
  open invocations 2: IF service identity EQUALS none THEN several open intents MAY share one (kind, act key).
  open invocations 3: The composition MUST rebuild open invocations from the range read's `<kind>.intended` records, less those a later closing record in the same read names through invocation id.
  open invocations 4: [Open] MUST populate open invocations.
  open invocations 5: [Close], [Refuse], [Resolve] and the sweep MUST clear an intent from open invocations ONLY AFTER a closing record naming the intent's invocation id has landed.
  open invocations 6: [Open]'s pre-check, [Close]'s pre-check and the sweep MUST read open invocations.
  open invocations 7: open invocations MUST NOT hold an intent past the retention horizon.
  ```
- **act closings**
  Term act closings: map from `(kind, act_key)` to the closing records of every invocation of the key, whoever wrote them. *Derived index*, same rebuild. Past the horizon it holds no closing whose payload the substrate destroyed (sequence high water 5), the rebuild keying each closing on the act key its payload carries (Primitive policy 2), and no reader needs one there: [Resolve] answers a purged intent invalid-request(purged), [Read Invocation] answers an act key with no readable intent not-known (read invocation 12), and the commit refuses a non-repeatable act's second attempt wherever the adopter's database holds the act.

  ```
  act closings 1: [Close], [Refuse], [Resolve] and the sweep MUST populate act closings.
  act closings 2: [Open] step 3, [Resolve]'s supersession check, [Reconcile] step 2 and step 5 and [Read Invocation] MUST read act closings.
  ```
- **sequence high water**
  Term sequence high water: the highest sequence number the composition has read whose recording instant settle bound has passed (sequence high water 2). Derived index. Past the horizon it holds no record and no payload, only a sequence number, which a payload's destruction leaves as it was: still derived, and rebuilt from the log's beginning where lost (sequence high water 6).

  ```
  sequence high water 1: EVERY re-read of the journal MUST read the delta above sequence high water and advance open invocations, act closings and sweep closed ids by the delta.
  sequence high water 2: The mark MAY advance past a sequence number ONLY AFTER settle bound has elapsed since the sequence number's recording instant.
  sequence high water 3: EVERY instance MUST perform a full rebuild at process restart.
  sequence high water 4: EVERY instance MUST perform a full rebuild PER sweep cadence.
  sequence high water 5: IF a record's retention end PRECEDES now THEN EVERY read of open invocations and EVERY read of act closings MUST drop the record.
  sequence high water 6: A lost mark MUST rebuild open invocations, act closings and sweep closed ids from the log's beginning.
  ```
  Term sweep closed ids: the set of invocation id values the sweep has closed, the third derived index, kept by the sweep beside open invocations and act closings and advanced and rebuilt with them (sequence high water 1, sequence high water 6).

  Term settle bound: `(journal_write_bound + clock_allowance)`.

  Term retention end: `((recorded_at + retention_period) - clock_allowance)` — the end of a record's retention, less the allowance for the two clocks, so that a read of open invocations or of act closings drops the record no later than the substrate's clock reaches that end.

### Which closing stands

One invocation may carry more than one closing record; one act key carries the closings of every invocation the key names, each invocation's standing on its own.

```
Which closing stands 1: This section IS AUTHORITATIVE FOR which of the closing records naming one invocation id is the invocation's.
NOTE: watch addressable sections.
Which closing stands 2: A closing record MAY supersede another closing record ONLY IF the closing record names that other closing record in supersedes and both closing records name the same invocation id.
Which closing stands 3: A closing record's carrying resolving actor MUST NOT trigger supersession; only the naming of Which closing stands 2 does, as an operator's abandonment, carrying resolving actor, naming an escalation supersedes the escalation.
Which closing stands 4: EVERY surface MUST read supersession transitively.
Which closing stands 5: EVERY surface MUST count the standing closing and every record the standing closing reaches through supersedes as one closing.
Which closing stands 7: Among the unsuperseded closings naming one invocation id, the lowest sequence number MUST stand.
```
Which closing stands 7 decides only a record set that already breaks Invariant 2.1 and Check 2.1: it keeps every reader's answer one where a conformance failure has landed, and a conforming journal never reaches it.

Term closing event id: closing_event_id — the event id of a closing record; where already-accounted carries it, the event id of the invocation's standing closing (Term standing closing), whichever writer wrote it.

Term standing closing: of one invocation id, the closing that stands under Which closing stands — of the closings naming the invocation id that no other closing naming it names, the one of the lowest sequence number.

**Which state a standing closing projects.**

Term state projection: no standing closing → open; an outcome record `<kind>.<outcome>` → closed; `<kind>.refused` → refused; `<kind>.abandoned` without resolving actor → abandoned; `<kind>.abandoned` with resolving actor → resolved; `<kind>.escalated` → escalated.

An escalated entry becomes resolved when an operator's abandonment names it, and closed when any outcome names it. resolved is reserved for the case where a human's judgement is the only thing that closed an act and the act did not happen; an operator's outcome is closed. The abandoned split is the one a check of the operator's closings reads: only an operator abandons, so an abandoned record carrying no resolving actor is a conformance failure that a reader still shows as abandoned, and resolving actor tells the two apart at both surfaces.

*Cited by:* [Read Invocation]'s state; Generation acceptance check 2; Invariant 2. None restates it.

## What people do

### Every action

```
Action wiring 1: EVERY action's signature MUST export the position of every code that could land on more than one side of the commit.
Action wiring 2: An adopter MUST export no code for the protocol's sake beyond the table below.
Action wiring 3: An adopter's re-entry arm MUST NOT collapse [Read Invocation]'s journal-unavailable into not-known.
Action wiring 4: An adopter's action MUST run: validate the adopter's own inputs; [Open]; the bound commit; [Refuse] for a pre-commit arm, [Close] for a committed arm and [Yield] for the unknown partition; return.
Action wiring 6: An adopter's action MUST NOT write to the journal for the act other than through [Open], [Close] and [Refuse].
```
| Source | Code the adopter exports | What the caller does with it |
|---|---|---|
| [Open] | invalid-credential | nothing was written anywhere; the credential is the caller's to fix |
| [Open] | invalid-request | the act's inputs or its outcome's size; the caller's to fix |
| [Open] | `act-in-flight(invocation_id)` ([Act In Flight]) | another invocation of this act is live or awaiting the sweep; retry later |
| [Open] | `act-landed(outcome_event_id)` ([Act Landed]) | the act is done; take the adopter's own re-entry arm, not a second act |
| [Open] | section-unavailable ([Critical Section Unavailable]) | the critical section could not be taken inside the holder's lease; retry |
| [Open] | journal-unavailable ([Journal Unavailable]) | [Open] step 1's journal read failed, or step 3's failed or returned nothing within read bound; nothing written; retry |
| [Open] | `recording-failure(intent)` ([Recording Failure]) | the intent record did not land; nothing committed; the whole action may be retried |
| [Open] | `recording-failure(outcome)` | the intent stands and the lease no longer covers the commit, which this invocation never issues (open step 5.6); the record is the sweep's; never re-run |
| the bound commit's pre-commit partition | the constituent's own code, after [Refuse] has landed the refusal | the act was refused and the attempt is recorded |
| [Refuse] | `already-accounted(closing_event_id)` ([Already Accounted]) | another writer already closed this invocation; report the act as accounted for, do not re-run |
| [Refuse] | `recording-failure(refusal, constituent_code)` | the refusal record did not land; the sweep records the attempt instead; never re-run the act |
| the unknown partition, after [Yield] | `recording-failure(outcome)` | the act may exist; its record is the sweep's; never re-run |
| [Close] | `recording-failure(outcome)` | the same |

*Never re-run* holds while the invocation is unclosed; once [Read Invocation] shows its closing, a new call is the caller's decision: a new act where the kind is repeatable, and where it is not, a second attempt that [Open] or the commit refuses wherever act closings or the adopter's database holds the act (open step 3.9). [Resolve]'s codes are the operator's; [Reconcile]'s journal-unavailable goes to the sweep's starter. [Read Invocation] is not in the table because it is not called around the commit; it answers journal-unavailable (the act's state unreadable for now) and not-known ([Not Known] — no readable intent), and Action wiring 3 keeps a re-entry arm from re-running an irreversible act whose record is sitting in the journal.

### Open

The action an adopter's action calls before the bound commit: takes the act's critical section, sizes the outcome and the escalation against the substrate's cap, refuses an act already in flight or already landed, and writes the intent record under the caller's credential. Returns `{invocation_id, intent_event_id}` with the critical section held; it first takes the reading the commit goes out behind, and returns `recording-failure(outcome)` where that reading does not cover the commit.

Kind: Operation

```
open(kind, act_key, actor_ref, credential, intent_data)
  answers open result
  refuses invalid-credential | invalid-request | act-in-flight(invocation_id) | act-landed(outcome_event_id) | section-unavailable | journal-unavailable | recording-failure(intent) | recording-failure(outcome)
```
Term open result: invocation id and intent event id — what open answers. Neither invocation id nor now is a parameter of open: the adopter's seam injects both (Term invocation id, Term now, Primitive policy 14).

Term intent event id: intent_event_id — the event id the journal assigns the intent record, carried by every later record of the invocation (Primitive policy 11a).

Term intent data: intent_data — the caller's payload at [Open], carrying the invocation's parameters and the pairing datum.

Term attested append: the append of one record through the atom's journal need under an actor reference and a credential the caller supplies, which the substrate validates BEFORE the record is appended, refusing invalid-credential with nothing written, and answering the record's event id; the journal kind carries no actor and no credential (Bonds journal 1 through 9), so this term is held on the app's glue until the unit `bonds: permission` states how a need of another atom's decision is said.

Term actor reference: actor_ref — the acting actor the caller names with a credential, which the substrate validates before the record is appended (Term attested append).

Opens one invocation of the act: takes the critical section, sizes the records, writes the intent record — where the caller's credential is verified — and returns the pair the adopter carries through the commit to [Close]. The order of step 1's rules is no order of work (GRACE-lang Timing 13): open step 1.6 places the read of open invocations before a take, not before step 1's refusals, so an unbound kind is refused with no read and no take (open step 1.9), and where a read's answer meets another refusal, [Open]'s refuses line decides which answers (Execution Contract Refusal 1).

Steps:

1. **Validate and size.**

   ```
   open step 1.1: [Open] MUST validate act key, actor reference and credential as not blank per Primitive policies, and no other input: intent data is sized into the intent payload (open step 1.3) and written as given, blank included.
   open step 1.2: IF caller kind EQUALS service THEN [Open] MUST land invalid-request.
   open step 1.3: [Open] MUST size intent payload and the kind's largest record per Primitive policy 12, for a kind in the bindings table (open step 1.9).
   open step 1.4: IF the sized intent payload EXCEEDS the substrate's payload cap OR the sized largest record EXCEEDS the substrate's payload cap THEN [Open] MUST land invalid-request.
   open step 1.5: A step-1 refusal MUST write nothing.
   open step 1.6: [Open] MUST NOT take the critical section BEFORE reading open invocations at (kind, act key) from the journal.
   open step 1.7: IF the read of open step 1.6 shows an open intent open step 3.5 or open step 3.7 refuses THEN [Open] MUST land act-in-flight(invocation id) carrying the invocation id of that open intent, with no take.
   open step 1.8: IF the read of open step 1.6 fails THEN [Open] MUST land journal-unavailable.
   open step 1.9: IF kind IS NOT IN the bindings table THEN [Open] MUST land invalid-request with no read and no take.
   open step 1.10: IF act key EQUALS blank OR actor reference EQUALS blank OR credential EQUALS blank THEN [Open] MUST land invalid-request.
   ```
2. **Take the act's critical section.**

   ```
   open step 2.1: [Open] MUST take the critical section: take((kind, act key), invocation id, invocation completion bound).
   open step 2.3: A failed take, a storage-failure and no answer included (Execution Contract Constituent failure 1, Bonds guard 2), MUST land section-unavailable with nothing written.
   ```
3. **Pre-check under the critical section.**

   ```
   open step 3.1: [Open] MUST re-read the journal from sequence high water for the act key under the critical section.
   open step 3.2: [Open] MUST take open invocations at (kind, act key) from the local maps.
   open step 3.3: Step 3 MUST NOT decide BEFORE the step-3 re-read advances the local maps (sequence high water 1).
   open step 3.4: [Open] MUST release for an in-flight open intent.
   open step 3.5: [Open] MUST land act-in-flight(invocation id) for an in-flight open intent, carrying the invocation id of that open intent.
   open step 3.6: IF service identity DOES NOT EQUAL none THEN [Open] MUST release for an aged open intent.
   open step 3.7: IF service identity DOES NOT EQUAL none THEN [Open] MUST land act-in-flight(invocation id) for an aged open intent, carrying the invocation id of that open intent.
   open step 3.8: WHEN service identity EQUALS none:
       open step 3.8a: [Open] MUST proceed past an aged open intent without refusing on the old intent, and open step 3.9, open step 3.11 and open step 3.13 answer unchanged.
       open step 3.8b: [Open] MUST leave the old intent open.
       open step 3.8c: [Open] MUST surface the old intent on compliance surface as a hard alert.
       open step 3.8d: An operator MUST close the old intent through [Resolve].
       open step 3.8e: The new invocation's records MUST pair on the new invocation id.
   open step 3.9: WHEN repeatable EQUALS no:
       open step 3.9a: [Open] MUST read from act closings the outcomes that stand for the act key, an outcome standing where the outcome IS the standing closing of an invocation of the key (Which closing stands 1).
       open step 3.9b: IF an outcome for the act key EXISTS THEN [Open] MUST release.
       open step 3.9c: IF an outcome for the act key EXISTS THEN [Open] MUST land act-landed(outcome event id) carrying the event id of the outcome of the lowest sequence number open step 3.9a read.
   open step 3.10: [Open] MUST bound the step-3 read by read bound.
   open step 3.11: An [Open] whose read exhausts the lease MUST release.
   open step 3.12: An [Open] whose read exhausts the lease MUST land section-unavailable with nothing written.
   open step 3.13: WHEN the step-3 read fails:
       open step 3.13a: [Open] MUST release.
       open step 3.13b: [Open] MUST land journal-unavailable with nothing written.
   ```
4. **Intent record.**

   ```
   open step 4.1: IF the remaining [Open] queried for the intent record (journal write bound 1) DOES NOT EXCEED write floor THEN [Open] MUST NOT write the intent record.
   open step 4.2: WHEN the remaining [Open] queried for the intent record (journal write bound 1) DOES NOT EXCEED write floor:
       open step 4.2a: [Open] MUST release.
       open step 4.2b: [Open] MUST land section-unavailable with nothing written.
   open step 4.3: [Open] MUST make an attested append of the intent record (action reference set to `<kind>.intended`, actor reference, credential, data set to intent payload) through the atom's journal need, answering intent event id.
   open step 4.4: Step 4's arms MUST follow the intent position of Primitive policy 19 through 23 and Primitive policy 27 through 43.
   open step 4.5: IF step 4 lands a refusal THEN [Open] MUST release.
   ```
5. **Populate, read for the commit, and return.**

   ```
   open step 5.1: [Open] MUST populate open invocations at (kind, act key) with the intent alone, the intent's sequence number and recording instant coming from the filtered range read of the next re-read (Primitive policy 38, Primitive policy 39).
   open step 5.4: [Open] MUST query remaining((kind, act key), invocation id) as the last call [Open] makes, the release of open step 5.5 excepted.
   open step 5.5: IF remaining DOES NOT EXCEED commit floor THEN [Open] MUST release.
   open step 5.6: IF remaining DOES NOT EXCEED commit floor THEN [Open] MUST land recording-failure(outcome) with the intent left open.
   open step 5.2: IF remaining EXCEEDS commit floor THEN [Open] MUST return invocation id and intent event id.
   open step 5.3: IF remaining EXCEEDS commit floor THEN [Open] MUST hold the critical section at return.
   ```
### Close

The action an adopter's action calls after the bound commit returned: under the critical section, adopts an outcome the sweep already landed for the invocation or writes the outcome record, then releases. Returns landing actor; returns `recording-failure(outcome)` where the lease expired or the record could not land.

Kind: Operation

```
close(kind, act_key, invocation_id, intent_event_id, actor_ref, credential, outcome_action_ref, outcome_data)
  answers close result
  refuses recording-failure(outcome)
```
Term close result: outcome event id and landing actor — what close answers.

Term outcome data: outcome_data — the caller's payload at [Close].

Term outcome action reference: outcome_action_ref — the action reference [Close] writes on the outcome record, one of the kind's outcome refs (Term bindings table).

Term outcome event id: outcome_event_id — the event id the journal assigns the outcome record.

Term landing actor: landed_by — which writer landed the outcome: the invocation, the operator, or the sweep.

Writes the act's outcome record after the bound commit has returned, under the critical section [Open] took, and releases the critical section. The one action that can find its own work already done. Its step-1 reading confirms standing alone: the outcome record goes out behind a reading of its own, taken after the step-2 re-read (journal write bound 1, pause bound 2, close step 3.10).

```
close 1: The adopter MUST pass [Close] the actor reference and the credential [Open] was given for the invocation.
close 2: The composition MUST NOT retain state between [Open] and [Close].
close 3: [Close] and [Refuse] MUST take intent event id.
close 4: The adopter's action MUST decide not-open from the invocation's own [Open] result ([Not Open]).
close 5: The adopter MUST pass [Close] outcome data carrying only what act probe answers for the act.
close 6: IF the step-2 re-read finds no closing record naming the invocation id AND an outcome action reference IS NOT IN the kind's outcome refs THEN [Close] MUST land recording-failure(outcome) with a hard alert, the critical section released and nothing appended.
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
       close step 1.2d: [Close] MUST release.
   ```
2. **Pre-check under the critical section — proceed as landed.**

   ```
   close step 2.1: [Close] MUST re-read the journal from sequence high water for the invocation id under the critical section.
   close step 2.2: WHEN the standing closing among the closing records naming the invocation id is an outcome:
       close step 2.2a: [Close] MUST adopt the outcome as the invocation's own.
       close step 2.2b: [Close] MUST release.
       close step 2.2c: [Close] MUST return outcome event id and landing actor.
       close step 2.2d: IF the outcome carries resolving actor THEN [Close] MUST return landing actor set to operator.
       close step 2.2e: IF the outcome's recovery EQUALS true AND the outcome's resolving actor EQUALS blank THEN [Close] MUST return landing actor set to sweep.
       close step 2.2f: IF the outcome's recovery EQUALS blank AND the outcome's resolving actor EQUALS blank THEN [Close] MUST return landing actor set to invocation.
   close step 2.3: WHEN the standing closing among the closing records naming the invocation id is an abandonment OR an escalation OR a refusal:
       close step 2.3a: [Close] MUST NOT adopt the record.
       close step 2.3b: [Close] MUST release and return recording-failure(outcome).
   close step 2.4: WHEN the step-2 re-read fails:
       close step 2.4a: [Close] MUST write nothing.
       close step 2.4b: [Close] MUST return recording-failure(outcome).
       close step 2.4c: [Close] MUST release.
   ```
3. **Outcome record.**

   ```
   close step 3.1: IF the step-2 re-read finds no closing record naming the invocation id THEN [Close] MUST make an attested append of the outcome record (action reference set to outcome action reference, actor reference, credential, data set to outcome payload) through the atom's journal need, answering outcome event id.
   close step 3.2: Step 3's arms MUST follow the outcome position of Primitive policy 19 through 23 and Primitive policy 27 through 43.
   close step 3.3: An invalid-request(step-1), invalid-request(step-2) or invalid-request(step-3) at step 3 MUST land recording-failure(outcome) with a hard alert.
   close step 3.4: [Close] MUST NOT retry after recording-failure(step-2) BEFORE re-running step 2.
   close step 3.5: IF remaining DOES NOT EXCEED write floor THEN [Close] MUST NOT retry.
   close step 3.7: WHEN the lease cuts a retry short:
       close step 3.7a: [Close] MUST release.
       close step 3.7b: [Close] MUST land recording-failure(outcome).
   close step 3.8: WHEN step 3 answers invalid-credential:
       close step 3.8a: [Close] MUST release.
       close step 3.8b: [Close] MUST land recording-failure(outcome).
   close step 3.9: IF [Close] lands recording-failure(outcome) at step 3 THEN [Close] MUST release.
   close step 3.10: WHEN the remaining [Close] queried for the outcome record (journal write bound 1) DOES NOT EXCEED write floor:
       close step 3.10a: [Close] MUST NOT write the outcome record.
       close step 3.10b: [Close] MUST land recording-failure(outcome).
   close step 3.11: [Close] MUST query remaining((kind, act key), invocation id) for the outcome record ONLY AFTER the step-2 re-read.
   ```
4. **Clear and release.**

   ```
   close step 4.1: IF the outcome record landed at step 3 THEN [Close] MUST remove the invocation id from open invocations at (kind, act key).
   close step 4.2: IF the outcome record landed at step 3 THEN [Close] MUST release the critical section.
   close step 4.3: IF the outcome record landed at step 3 THEN [Close] MUST return outcome event id and landing actor set to invocation.
   ```
### Refuse

The action an adopter's action calls when the bound commit refused on a pre-commit arm: writes the refusal record naming the intent, so the authenticated attempt is kept and the intent does not stand open, and releases the critical section.

Kind: Operation

```
refuse(kind, act_key, invocation_id, intent_event_id, actor_ref, credential, reason, constituent_code)
  answers refusal_event_id
  refuses already-accounted(closing_event_id) | recording-failure(refusal, constituent_code)
```
Term refusal event id: refusal_event_id — the event id the journal assigns the refusal record; what refuse answers.

Closes an intent whose bound commit did not commit — the constituent refused on a pre-commit arm — so the intent does not stand open for the sweep to probe. Its step-1 reading confirms standing alone: the refusal record goes out behind a reading of its own, taken after the step-2 re-read (journal write bound 1, pause bound 2, refuse step 3.13).

Steps:

0. **Not open.**

   ```
   refuse step 0.1: The adopter's action MUST decide not-open from the invocation's own [Open] result ([Not Open]).
   refuse step 0.2: [Refuse] MUST write nothing for a pair no [Open] returned.
   refuse step 0.3: The adopter MUST pass [Refuse] the actor reference and the credential [Open] was given for the invocation.
   NOTE: watch rule inheritance — refuse step 0.1 and refuse step 2.1 restate [Close]'s close 4 and close step 2.1 for [Refuse] rather than inheriting; the grammar has no inheritance form.
   ```
1. **Confirm standing, before any read.**

   ```
   refuse step 1.1: [Refuse] MUST NOT read BEFORE querying remaining((kind, act key), invocation id).
   refuse step 1.2: WHEN remaining DOES NOT EXCEED write floor OR remaining EQUALS none:
       refuse step 1.2a: [Refuse] MUST write nothing.
       refuse step 1.2b: [Refuse] MUST return recording-failure(refusal, constituent code).
       refuse step 1.2c: [Refuse] MUST release.
   refuse step 1.3: A yielded caller MUST NOT read at [Close] or [Refuse].
   refuse step 1.4: A yielded caller MUST NOT adopt at [Close] or [Refuse].
   ```
2. **Re-read under the critical section.**

   ```
   refuse step 2.1: [Refuse] MUST re-read the journal from sequence high water for the invocation id under the critical section.
   refuse step 2.2: IF a closing record naming the invocation id EXISTS THEN [Refuse] MUST land already-accounted(closing event id).
   refuse step 2.3: IF a closing record naming the invocation id EXISTS THEN [Refuse] MUST append nothing.
   refuse step 2.4: [Refuse] MUST NOT report already-accounted as not-open.
   refuse step 2.5: IF a closing record naming the invocation id EXISTS THEN [Refuse] MUST release.
   ```
3. **Refusal record.**

   ```
   refuse step 3.1: [Refuse] MUST make an attested append of the refusal record (action reference set to `<kind>.refused`, actor reference, credential, data set to invocation id, intent event id, kind, act key, reason and constituent code) through the atom's journal need, answering refusal event id.
   refuse step 3.3: [Refuse] MUST read the refusal back by invocation id for invalid-request(step-4).
   refuse step 3.4: [Refuse] MUST NOT retry after invalid-request(step-3) or invalid-request(step-4).
   refuse step 3.5: recording-failure(step-2) and recording-failure(step-3) MUST land recording-failure(refusal, constituent code) with the intent left open, a step-3 whose record the read-back of Primitive policy 32a finds excepted.
   refuse step 3.6: A lost reply whose one read-back finds nothing MUST land recording-failure(refusal, constituent code) with the intent left open.
   refuse step 3.7: invalid-credential MUST land recording-failure(refusal, constituent code) with the intent left open.
   refuse step 3.8: An invalid-request(step-1), invalid-request(step-2) or invalid-request(step-3) MUST land recording-failure(refusal, constituent code) with the intent left open.
   refuse step 3.9: IF the write answers an event id OR a read-back finds the refusal record THEN [Refuse] MUST remove the invocation id from open invocations at (kind, act key).
   refuse step 3.10: [Refuse] MUST release the critical section.
   refuse step 3.11: The composition MUST NOT suppress a refusal record.
   refuse step 3.12: IF the write answers an event id OR a read-back finds the refusal record THEN [Refuse] MUST return refusal event id, with a hard alert for an invalid-request(step-4).
   refuse step 3.13: WHEN the remaining [Refuse] queried for the refusal record (journal write bound 1) DOES NOT EXCEED write floor:
       refuse step 3.13a: [Refuse] MUST NOT write the refusal record.
       refuse step 3.13b: [Refuse] MUST land recording-failure(refusal, constituent code) with the intent left open.
   refuse step 3.14: [Refuse] MUST query remaining((kind, act key), invocation id) for the refusal record ONLY AFTER the step-2 re-read.
   ```
### Yield

What an adopter's action calls on the unknown partition: nothing is written and the intent stays open for the sweep; the critical section is released where the commit answered, and left to end at its instant where the commit's reply was lost.

Kind: Operation

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
yield 6: IF reply EQUALS lost THEN [Yield] MUST NOT issue the guard's release for the grant.
yield 7: The adopter's action MUST pass reply as lost for a bound commit that returned nothing AND as answered for a reply the constituent's contract declares neither pre-commit nor committed.
yield 8: IF the release of yield 5 answers storage-failure THEN [Yield] MUST answer ok with nothing written, the grant ending at the grant's instant (act section 15, act section 20, Execution Contract Constituent failure 1).
```
Term reply: reply — answered | lost: what the bound commit returned on the unknown partition.

### Read Invocation

The composition's read: the act's invocations, each with records and state, for an adopter's re-entry arm and for an auditor. Takes no critical section, writes nothing.

Kind: Operation

```
read_invocation(kind, act_key, optional invocation_id)
  answers invocation report
  refuses not-known | journal-unavailable
```
Term invocation report: invocations, a sequence of invocation entry; and more (read invocation 2) — what read_invocation answers.

Term invocation entry: invocation id; state; records; and more (read invocation 5) — one invocation in an invocation report.

Reads the act's invocations — each intent and whichever closing record names it — through the same rebuild, for an adopter's re-entry arm and for an auditor.

```
read invocation 1: [Read Invocation] MUST perform the rebuild under now injected at the reader's own seam.
read invocation 2: IF invocation id EQUALS blank THEN [Read Invocation] MUST return one entry per invocation id whose intent is readable, at most read cap of the most recent, with more set to true where the act has older ones.
read invocation 3: WHEN invocation id DOES NOT EQUAL blank:
    read invocation 3a: [Read Invocation] MUST return one entry for an invocation id a readable intent of the act key carries.
    read invocation 3b: [Read Invocation] MUST answer not-known for an invocation id no readable intent of the act key carries.
NOTE: watch the blank optional input (read invocation 2, read invocation 3).
read invocation 4: records MUST carry the intent, the recovery_intended records and the closing records.
read invocation 5: [Read Invocation] MUST cap the recovery_intended records and the closing records together, a superseded closing counted like any other, at the most recent read cap, the standing closing kept within the cap wherever the standing closing falls, the intent excepted, with more set to true beyond.
read invocation 6: [Read Invocation] MUST NOT exclude a superseded record from records except beyond the cap of read invocation 5.
read invocation 16: [Read Invocation] MUST answer an invocation report's invocations earliest first by the sequence numbers of the invocations' intents, and an invocation entry's records earliest first by sequence number.
NOTE: watch read-order polarity (read invocation 16).
read invocation 10: [Read Invocation] MUST read the entry's state from the table in the section titled Which closing stands.
read invocation 11: [Read Invocation] MUST transcribe the range read's unavailable arm as journal-unavailable.
read invocation 12: [Read Invocation] MUST answer not-known for an act key with no readable intent.
read invocation 13: [Read Invocation] MUST NOT take a critical section.
read invocation 14: [Read Invocation] MUST NOT write.
read invocation 15: An adopter that decides a write on [Read Invocation]'s answer MUST decide the write under the critical section through [Open]'s pre-check.
read invocation 17: IF kind IS NOT IN the bindings table THEN [Read Invocation] MUST answer not-known with no read.
read invocation 18: IF act key EQUALS blank THEN [Read Invocation] MUST answer not-known with no read.
read invocation 19: The app's key check of a written invocation id MUST call [Read Invocation] with the kind and the act key of the act the write belongs to beside the invocation id.
```
## What is and what should never be (Invariants)

- **Invariant 1 — Authentication precedes commitment.**
  ```
  Invariant 1.1: An invocation MUST NOT reach the bound commit BEFORE the substrate has validated the caller's credential for actor reference inside [Open]'s intent record.
  Invariant 1.2: IF position EQUALS intent THEN [Open] MUST NOT write for a call answering invalid-credential.
  NOTE: watch position scoping (Primitive policy 19).
  ```
  *Rests on:* the attested append and the credential check the substrate makes before it (Term attested append, the held credential check on the app's glue); [Open] step 4 before the adopter's commit. *Defended in-line:* the ordering [Open] → commit → [Close] in every adopter; Generation acceptance check 1 makes it provable.

- **Invariant 2 — One writer per act.**
  ```
  Invariant 2.1: Two unsuperseded closing records MUST NOT name one intent's invocation id.
  ```
  ```
  Invariant 2.6: The section titled Which closing stands IS AUTHORITATIVE FOR which closing is the invocation's.
  NOTE: watch addressable sections.
  ```
  *Rests on:* act section (Configuration) with lease-as-terminus semantics; Execution Contract Database 2, under which a writer's re-read, lease check and append are one transaction, the lease check being one of the guard reads Database 2 puts inside the transaction that appends: the remaining a writer decides on is the grant's state (journal write bound 1), and the grant and the journal are records of one database, since a composing action's one transaction takes in its constituents' writes (Execution Contract Constituent failure 1); the return-based read-your-writes clause (Execution Contract Database 1 through 4, Database 7 and Refusal 1); [Close] step 2's proceed-as-landed; [Reconcile] step 2's re-read under the critical section and sweep closed ids. *Defended in-line:* the load-bearing wiring decision; the model's rejected twins bearing on this invariant — `-buggy-reread` and `-buggy-visible`, each landing two closings for one act, and `-buggy-journal`, a take that does not refuse the write it overtakes, landing a second invocation's intent beside the first's at the main constants and an outcome beside the sweep's at nine ticks; a fourth, `-buggy-supersede`, lands two unsuperseded closings by omitting the name from a resolution over an escalation.

- **Invariant 3 — Pairing is by the seam-injected key in the journal, and by the bound datum in the database.**
  ```
  Invariant 3.1: EVERY record this composition writes for an invocation MUST carry the invocation's invocation id.
  Invariant 3.2: EVERY check over the journal and EVERY journal join MUST pair on invocation id and no other field.
  Invariant 3.3: IF pairing datum DOES NOT EQUAL none THEN act probe MUST make the intent-to-record join, a join of the intent with the adopter's record and no journal join, on pairing datum by equality.
  Invariant 3.4: act probe MUST NOT pair on a stamp within a window.
  Invariant 3.5: WHEN pairing datum EQUALS none OR pairing datum matches more than one record:
      Invariant 3.5a: The sweep MUST name candidates and write no outcome.
  ```
  *Rests on:* the seam injection (Primitive policies); Bonds journal 1 (a record the journal answered a place for is kept unchanged); the pairing datum binding; Contracts Act probe 3 and Act probe 4 (the probe's answer where the datum is none).

- **Invariant 6 — The outcome is sized before the intent.**
  ```
  Invariant 6.1: IF outcome envelope EQUALS the true maximum THEN an act MUST NOT commit with an outcome record or an `<kind>.escalated` record the substrate's payload cap could refuse.
  Invariant 6.2: [Open] MUST NOT write the intent record BEFORE sizing the outcome and the escalation against outcome envelope and intent candidates cap.
  ```
  *Rests on:* [Open] step 1; Primitive policy 13a, which holds every closing written after any start to the settings of that start (Execution Contract Logic confinement 17), so an intent opened earlier still fits; the adopter's caps under reference length cap. outcome envelope's truth is an externally-clearable check.

- **Invariant 8 — Positioned codes.**
  ```
  Invariant 8.1: EVERY code an adopter's action exports that could land before the commit and after the commit MUST carry the position — recording-failure(intent) and recording-failure(outcome) at least.
  Invariant 8.2: The adopter's signature MUST declare the payload.
  Invariant 8.3: A caller receiving intent MAY retry the action.
  Invariant 8.4: A caller receiving outcome MUST NOT retry the action.
  ```
  *Rests on:* [Open], [Close] and [Refuse]'s signatures; the position rule (Primitive policies).

## When something happens

### Cross-record consistency under partial failure

The reachable partials and their closers. *Crash after [Open], before the commit:* intent open, database untouched; act probe answers not-committed; the sweep writes `<kind>.escalated`, and an operator who finds the database quiet abandons the act through [Resolve]. *Crash after the commit, before [Close]:* act probe answers committed; the sweep writes the outcome under `recovery = true`. *Crash inside [Close] after the outcome landed and before the map update:* the map is a rebuild trigger, not a partial. *A stalled invocation past its lease:* it writes nothing; the sweep closes; the late [Close] returns recording-failure(outcome). *A refusal record that failed:* the intent stands, act probe answers not-committed, and the sweep escalates it. *An outcome the database cannot corroborate:* undecidable, escalated with candidates, never chosen. These five are every partial the critical section leaves: a sixth would take two writers for one act, which Invariant 2 rules out.

## While something is so

### Primitive policy

```
Primitive policy 1: The adopter MUST cap act key under reference length cap.
Primitive policy 2: The composition MUST write act key as a composition-written field of EVERY record the composition appends.
Primitive policy 3: The composition MUST NOT recover act key from an adopter's payload.
Primitive policy 4: EVERY record this composition writes for an invocation MUST carry the invocation's invocation id in the payload.
Primitive policy 5: Invariant 3.2 IS AUTHORITATIVE FOR the field a check over the journal or a journal join pairs on.
Primitive policy 6: The adopter MUST pass actor reference and credential through to the attested append at the intent record.
Primitive policy 7: The composition MUST validate actor reference and credential as not blank.
Primitive policy 7a: The composition MUST NOT inspect actor reference or credential beyond the test of Primitive policy 7.
Primitive policy 8: The adopter MUST NOT call [Open] BEFORE capping actor reference under reference length cap.
Primitive policy 9: intent data MUST carry the invocation's parameters and pairing datum.
Primitive policy 10: intent data MUST NOT carry a field the substrate or the constituent stamps or mints.
Primitive policy 10a: intent data MUST NOT carry a field named for invocation id, kind and act key (Term intent payload names the fields the composition adds).
Primitive policy 10b: outcome data MUST NOT carry a field named for invocation id, intent event id, kind and act key (Term outcome payload names the fields the composition adds).
Primitive policy 10c: outcome data MUST NOT carry a field named for recovery, acting actor reference, resolving actor and supersedes (Term outcome shape and Term supersedes name the fields a closing adds).
Primitive policy 11: The composition MUST write invocation id, kind and act key into EVERY record the composition appends.
Primitive policy 11a: The composition MUST write intent event id into EVERY record of the invocation but the intent.
Primitive policy 12: [Open] MUST size intent payload and, for a kind in the bindings table (open step 1.9), the kind's largest record, each separately, against the substrate's payload cap as the substrate measures a payload.
Primitive policy 13: [Open] MUST refuse invalid-request for an act whose intent payload or whose largest record does not fit.
Primitive policy 13a: IF the largest record of any kind in the bindings table, sized as Primitive policy 12 sizes a largest record, on the settings the start reads, EXCEEDS the substrate's payload cap THEN the instance MUST NOT start.
Primitive policy 14: An action signature MUST NOT take now.
Primitive policy 15: [Open] MUST use now for three comparisons alone: the age of an open intent against recording instant under clock allowance, at step 1 and at step 3, the retention drop of sequence high water 5, and the advance of the mark under settle bound (sequence high water 2).
Primitive policy 15a: [Close], [Refuse] and [Read Invocation] MUST use now for the retention drop of sequence high water 5 and the advance of the mark under settle bound (sequence high water 2) alone.
Primitive policy 17: The adopter's action MUST carry invocation id from [Open] into [Close] and [Refuse] as a parameter of each.
Primitive policy 18: The sweep MUST read now once per run at the sweep's own seam.
```
Term journal join: a pairing of two journal records on a field each carries, to decide that they belong to one invocation. A read of one record by the event id another record carries, as the one-record read of the intent event id at Check 1.2 (Bonds journal 7), is a lookup, not a join. A grouping of an act's records on the kind and act key they carry, as Check 2.3 and act closings do, decides which records are the act's and never that two belong to one invocation, so it is no join.

Term now: the deployment's clock reading at the call, as Execution Contract Logic confinement 11 declares it.

NOTE: watch the fresh holder value (Term operator run id, Term run id).

Term hard alert: an alert on the compliance surface naming the invocation id and the arm that raised it — beside the findings register and no part of it, and what a deployment's operators are paged by.

Term caller kind: EXACTLY ONE OF human, service — service where actor reference names the kind's service identity, which a comparison by byte-identity decides on the actor reference as the deployment canonicalizes it at the seam (Execution Contract Logic confinement 13) and on the kind's service identity's actor reference in that same canonical form; a comparison inspects nothing in the reference (Primitive policy 7a).

Term examine edge: `((recorded_at + invocation_completion_bound) + clock_allowance)`.

Term in-flight: an open intent for which now PRECEDES examine edge.

Term aged: an open intent for which now DOES NOT PRECEDE examine edge — every open intent that is not in-flight.

Term largest record: the largest of the closings the sweep and [Resolve] write for a kind, as the substrate measures a payload — the recovered outcome, built from outcome envelope, the `<kind>.escalated` record, built from intent candidates cap, and an operator's closing of either, an abandonment included (only an operator abandons: Term state projection), which adds resolving actor and supersedes (Invariant 6.2).

Term as the substrate measures a payload: the serialized envelope `{action_ref, actor_ref, attestation_id, data}` with data as the record carries it, the invocation id, kind and act key of Primitive policy 11 and the intent event id of a closing included, and with an actor reference at reference length cap (the writer's, whether the caller's, the service identity's or the operator's, which the substrate refuses beyond that cap), the substrate's attestation id width, and the framing. The sweep's two closings — the recovered outcome (outcome payload plus recovery, acting actor reference) and the escalation (invocation id, intent event id, kind, act key and database candidates, plus the same) — and the operator's closings through [Resolve] (either of the two with resolving actor and supersedes added, and an abandonment, which carries its cause, the longest word of Escalation's closed Term cause, with the same two) are sized separately, each reference at reference length cap; the bound is the largest.

```
Primitive policy 19: IF position EQUALS intent THEN invalid-credential MUST pass through unchanged with nothing written.
NOTE: watch position scoping — every rule of this family scopes by IF position = … (Primitive policy 19 through 23, Primitive policy 27 through 43); the corpus's answer is the condition, not a new form.
Primitive policy 20: IF position EQUALS intent THEN [Open] MUST NOT report invalid-request(step-4) BEFORE reading back by invocation id.
Primitive policy 21: WHEN the read-back of Primitive policy 20 finds the record:
    Primitive policy 21a: The action MUST proceed with a hard alert.
Primitive policy 22: WHEN the read-back of Primitive policy 20 finds nothing:
    Primitive policy 22a: The action MUST land invalid-request.
Primitive policy 23: IF position EQUALS intent THEN recording-failure(step-2) and recording-failure(step-3) MUST land recording-failure(intent), a step-3 whose record the read-back of Primitive policy 32a finds excepted.
Primitive policy 27: IF position EQUALS outcome THEN the action MUST read event id back by invocation id for invalid-request(step-4).
Primitive policy 28: IF position EQUALS outcome THEN the action MUST return success with a hard alert for an invalid-request(step-4) whose read-back finds the record.
Primitive policy 29: IF position EQUALS outcome THEN the writer MUST retry recording-failure(step-2) under the critical section, to the terminus at most.
Primitive policy 30: A retry that reaches the terminus MUST land recording-failure(outcome).
Primitive policy 31: IF position EQUALS outcome THEN invalid-credential MUST land recording-failure(outcome).
Primitive policy 32: The composition MUST treat an attested append whose reply is lost as unknown at every position.
Primitive policy 32a: The composition MUST treat recording-failure(step-3) as a lost reply.
Primitive policy 33: The composition MUST NOT retry a lost-reply write blind.
Primitive policy 34: The composition MUST NOT read back a lost-reply write BEFORE journal write bound has elapsed since the issue, the elapse read on the host's clock through a remaining the writer queries, never on a clock the caller reads.
Primitive policy 35: The composition MUST read back by invocation id through the filtered range read over the delta range as sequence high water stood at the issue of the write read back.
Primitive policy 36: WHEN the read-back finds the record:
    Primitive policy 36a: The composition MUST adopt the record.
Primitive policy 37: WHEN the read-back finds nothing:
    Primitive policy 37b: The composition MUST land the position's existing arm.
Primitive policy 38: The composition MUST take the intent's sequence number and recording instant from the filtered range read.
Primitive policy 39: The composition MUST NOT take the intent's sequence number and recording instant from the one-record read.
Primitive policy 40: IF position EQUALS outcome THEN an invalid-request(step-4) whose read-back finds nothing MUST land recording-failure(outcome) with a hard alert.
Primitive policy 41: IF position EQUALS intent THEN invalid-request(step-1), invalid-request(step-2) and invalid-request(step-3) MUST land invalid-request.
Primitive policy 42: IF position EQUALS outcome THEN invalid-request(step-1), invalid-request(step-2) and invalid-request(step-3) MUST land recording-failure(outcome) with a hard alert.
Primitive policy 43: The action MUST NOT retry after invalid-request(step-3) or invalid-request(step-4).
Primitive policy 44: The composition MUST treat recording-failure(step-4) as recording-failure(step-2) at every position.
Primitive policy 45: The composition MUST treat an attested append that answers state-unavailable as recording-failure(step-2) at every position (Execution Contract Read 1).
Primitive policy 46: The vocabulary of a kind MUST declare `<kind>.intended`, the enumerated outcome refs `<kind>.<outcome>`, and `<kind>.refused`.
Primitive policy 46a: The vocabulary of a kind MUST NOT declare an outcome ref among `<kind>.intended`, `<kind>.refused`, `<kind>.recovery_intended`, `<kind>.abandoned` and `<kind>.escalated`.
Primitive policy 47: The composition MUST derive `<kind>.recovery_intended`, `<kind>.abandoned` and `<kind>.escalated` from the vocabulary.
Primitive policy 48: The rebuild MUST classify a record as an outcome by membership in the enumerated outcome refs.
Primitive policy 49: The adopter MUST NOT declare a kind whose action references fall in the reserved namespace.
NOTE: watch the constituent's failed read (Primitive policy 45, act section 20).
```
Term lost reply: an attested append that answers recording-failure(step-3) (Primitive policy 32a), or whose reply has not arrived when journal write bound has elapsed since the write's issue, the elapse read as Primitive policy 34 reads it; the bound commit's reply is lost as yield 7 says.

## Optional

### What the substrate supplies

```
Capability requirement 1: The substrate MUST supply the open-upper-bound sequence-range read over the delta range.
Capability requirement 3: The range read MUST declare the arm invalid-query and one failed-read arm that answers unavailable and state-unavailable alike (Capability requirement 6).
Capability requirement 4: The composition MUST surface invalid-query on compliance surface.
Capability requirement 5: The composition MUST NOT retry an invalid-query read unchanged.
Capability requirement 6: EVERY read path MUST transcribe unavailable and state-unavailable alike at the read path's own position.
NOTE: watch the constituent's failed read (Primitive policy 45).
Capability requirement 8: EVERY range read issued after journal write bound has elapsed since a lost-reply append's issue MUST return the record.
```
```
Capability requirement 13: EVERY read path MUST land an invalid-query where the read path lands unavailable, the landing opening no instance finding journal-unavailable (Capability requirement 14).
Capability requirement 14: The composition MUST NOT surface an invalid-query as the instance finding journal-unavailable.
Capability requirement 15: EVERY read path that reads under the critical section MUST land a read that returns nothing within read bound where the read path lands unavailable.
```
Term delta range: the sequence-number range from `(sequence_high_water + 1)` with no upper bound.

Term open-upper-bound sequence-range read: the journal need's read over the delta range: it answers every record the range holds, as one sequence (Bonds journal 2).

Term read path: [Open] step 1 and step 3, [Reconcile] step 1, [Read Invocation], and the re-reads at [Close], [Refuse], [Resolve] and [Reconcile] step 2. The reads at [Open], [Reconcile] step 1 and [Read Invocation] transcribe unavailable as journal-unavailable; the re-reads at [Close], [Refuse] and [Resolve] land it on the position's recording-failure arm, and so do the read-backs of Primitive policy 20, 27 and 35; the re-read at [Reconcile] step 2 leaves the act for the next run under the instance finding journal-unavailable. A read-back at the intent position that gives no answer lands the intent position although the intent may stand: nothing is committed, a retry is safe, and the stray intent is the sweep's to close; at any other position it lands that position's recording-failure arm, as the read-backs above do. A read fails where it answers unavailable or state-unavailable, the two read as one arm (Execution Contract Read 1). A read under the critical section that returns nothing within read bound lands where the read path lands unavailable (Capability requirement 15). A read outside it that returns nothing — [Open] step 1, [Reconcile] step 1 and [Read Invocation] — leaves the action no answer to give (Execution Contract Error model 1), as the journal's own such reads do, and a [Reconcile] run so stalled ends at run bound. An invalid-query is no outage of the journal but a fault of the build: it lands where unavailable lands, is surfaced, and opens no outage finding (Capability requirement 4, 13 and 14).

Term read-your-writes: Capability requirement 8 and Execution Contract Database 1 through 4, Database 7 and Refusal 1 together. The filtering of every range read on action reference, invocation id or a payload field is this composition's code; the substrate offers no such selector.

### The act's critical section

- **act section**
  ```
  act section 4: EVERY action but [Reconcile] MUST take kind as the first input.
  act section 5: [Open] step 2 and [Resolve] MUST transcribe the guard need's unavailable arm as section-unavailable.
  ```
  ```
  act section 8: [Open] MUST NOT write the intent record BEFORE taking the critical section.
  act section 9: The invocation MUST hold the critical section through [Close]'s last write.
  act section 10: WHEN an invocation's lease has expired:
      act section 10a: The invocation MUST NOT write.
      act section 10b: The invocation MUST NOT re-take the critical section.
  ```
  ```
  act section 15: IF a call in flight EXISTS under the grant THEN the holder MUST NOT issue the guard's release for the grant.
  ```
  ```
  act section 20: IF a release answers no answer OR state-unavailable THEN the holder MUST NOT decide an answer on the release (Execution Contract Read 1).
  NOTE: watch the constituent's failed read (Primitive policy 45).
  act section 21: IF a release answers storage-failure THEN the composition MUST land the position's existing arm with nothing written, at [Open], [Close], [Refuse] and [Resolve] (Execution Contract Constituent failure 1).
  ```
  Term critical section duration: invocation completion bound for an invocation; sweep lease for a sweep run or an operator; the longest a take on a key asks for is the larger of the two.

  Term release: to issue the guard's release for the grant where no call in flight exists under the grant, and to issue nothing where one does — the grant then ends at its instant (act section 15). EVERY release on this pattern reads so. The guard's own release is the call alone: the word here names the decision whether to issue it.

  Term terminus: the end of the critical section's grant, at its release or at its instant — an invocation's standing to write ends there.

### Bounds the deployment declares

- **journal write bound**
  Term journal write bound: the disclosed bound on an attested append from issue to landing: issue-to-first-commit latency, with headroom. *Default:* none.

  ```
  journal write bound 1: A writer MUST issue a journal write under the critical section ONLY IF a remaining the writer queried for that write EXCEEDS write floor.
  ```
- **pause bound**
  Term pause bound: this composition's value of [Lease](./lease.md)'s call pause bound: the longest time from a holder's decision to issue one call — a lease call, the issue of a journal write, the issue of the bound commit — to the moment the call has taken effect or failed. *Default:* none.

  ```
  pause bound 1: The deployment MUST supply Lease Capability requirement 7 for EVERY lease call on this pattern and for this pattern's unfenced writes, the bound commit and every journal write, with pause bound as the atom's call pause bound.
  pause bound 2: A writer MUST issue a journal write WITHIN pause bound of asking for the write's remaining.
  ```
  A journal write is a unit of work in Lease's sense, its bound the pause from the reading to the issue (pause bound 2) and journal write bound from the issue to the landing (Lease Term unit's bound); the pause bound bounds the write's issue, as the atom's Term unit of work allows, and not the whole record action.

  Term write floor: `(journal_write_bound + (3 * pause_bound))` — Lease's start floor for one journal write: the reading and the issue behind it inside one pause, the write, and the atom's two-call margin. A remaining that answers none does not exceed it.

  Term commit floor: `(commit_round_trip + (4 * pause_bound))` — the same for the bound commit, with one pause more for the hand from [Open]'s return to the adopter's call.

- **read bound**
  Term read bound: the disclosed bound on one journal read under the critical section ([Open] step 3, [Close] step 2, [Refuse], [Resolve], [Reconcile] step 2). Conditions 3 and 5. *Default:* none.

- **read cap**
  Term read cap: the most invocations [Read Invocation] returns for one act, and the most records per invocation, at least one. *Default:* none.

### Bindings the actions read

- **bindings table**
  Term bindings table: the deployment's map from each kind the composition serves to that kind's bindings — repeatable, service identity, pairing datum, act probe, invocation completion bound, commit round trip, retention period, outcome envelope, intent candidates cap and outcome refs (the `<kind>.<outcome>` action references [Close] may write as the kind's outcome, none of them `<kind>.intended`, `<kind>.refused`, `<kind>.recovery_intended`, `<kind>.abandoned` or `<kind>.escalated`). *Default:* none.

  ```
  bindings table 1: The deployment MUST supply the bindings table, with an entry for every kind the composition serves, as a setting with no default (Execution Contract Logic confinement 15, Logic confinement 17).
  bindings table 2: EVERY action MUST read a kind's bindings from the bindings table by that kind.
  ```
  Term kind: the act kind an invocation belongs to — a key of the bindings table while the instance serves the kind, and the `<kind>` of every action reference the act's records carry.

  Term repeatable: `yes` or no: whether two invocations against one act key are two acts or one act attempted twice.

  Term service identity: a registered actor (actor reference and credential) under which the sweep writes, or none; the substrate validates its credential as it validates a caller's (Term attested append).

  Term act probe: a read of the adopter's database keyed by act key and pairing datum, answering for the sweep: did the act commit, and with what outcome.

  Term invocation completion bound: the longest a conforming invocation of the kind takes from [Open]'s critical section take to [Close]'s last write, including the constituent round-trip, and sized by the deployment to hold [Open]'s read bound, [Open]'s intent write with the wait and read-back of Primitive policy 34, the commit floor, [Close]'s step-1 query (pause bound), [Close]'s step-2 re-read (read bound) and [Close]'s write floor; a bound below them fails every [Close] and leaves the act to the sweep. The lease length of the critical section. Read against the seam clock [Open] was injected with. *Default:* none.

  Term commit round trip: the longest one commit call takes from issue to reply. *Default:* none.

  Term clock allowance: the most two of the deployment's clocks may differ (Execution Contract Logic confinement 18), spent where a reading from one clock meets a stamp or an instant minted from another. *Default:* none.

  Term retention period: the keep the atom's journal need asks of each record of a kind, as the need's keep states it (Bonds journal 6); here a per-kind binding. *Default:* none.

  Term intent candidates cap: the most database candidates an `<kind>.escalated` record names, each under reference length cap. Sizes the escalation (Invariant 6). *Default:* none.

- **outcome envelope**
  Term outcome envelope: the largest outcome payload the kind can write, sized by the adopter from the adopter's own caps, every set-valued field capped and every reference under reference length cap (Invariant 6).

## Needs

The bonds this atom needs, each of a bond kind [Bonds](../bonds.md) states, and the contract it needs of a system that is not Grace's, which [Contracts](../contracts.md) states.

Term need guard: key critical section key; holder critical section holder; span duration; calls take, remaining, release; arms expires_at, unavailable, remaining_term, none, released, no answer; writes closing record.

Term need journal: records intent record, closing record; calls append, read; arms event_id, events, invalid-query; keep duration; tamper sealed; stream invocation journal.

The journal need's keep is the retention period of each kind (Term retention period), its tamper is the seal the disputed act rests on (Regulated adversarial scenarios), and its stream is the one every act's records go to, so that one read answers an act's intent and every closing of it, whoever wrote them (Term act closings). A lookup of one record by its event id is the read of the range that holds the record's place and no other place (Bonds journal 7). The need carries no actor and no credential: the attested append is held (Term attested append).

Term contract need commit: asks the act under act key, the key the app supplies and the intent record carries; answers pre-commit, committed, unknown; bound commit round trip.

## Offers

Term offer key: key invocation id; carried by intent record, closing record; calls Read Invocation.

## Left to others

### Non-goals

```
Non-goal 1: An adopter MUST NOT describe [Open], then the commit, then [Close] as atomic.
Non-goal 2: This composition MUST NOT offer a rollback.
```
```
Non-goal 4: The adopter MUST own the `already-*` re-entry arm, informed by [Read Invocation].
```
NOTE: the owners — a Transaction pattern *(forthcoming)* (Non-goal 1, Non-goal 2); the adopter (Non-goal 4).

## Example

### A clean run

**The clean run.** `disclose_subset(...)` validates; [Open] takes the critical section, sizes the intent payload (`disclosed_entry_ids` under the ledger's cardinality cap, which the intent alone carries) with the kind's largest record, writes `ledger.disclosure.intended` (`inv-7f2`) under the discloser's credential, and returns. `SelectiveDisclosure.record` → `dsc-411`. [Close] finds no outcome for `inv-7f2` under the critical section, writes `ledger.disclosure.disclosed` with `{invocation_id: inv-7f2, intent_event_id, disclosure_id: dsc-411, ...}`, releases, returns `landed_by = invocation`. One intent, one outcome, one writer.

### The lost reply

**The lost reply.** `SelectiveDisclosure.record` is issued and its reply never arrives. The arm is unknown: the adopter calls [Yield] and returns `recording-failure(outcome)`. Nothing is released — the commit is a call in flight — so the critical section runs to `t + 30 s`, and a second `disclose_subset` on the same four fields meets `act-in-flight(inv-7f2)` at [Open]'s read ahead of the take, without waiting. The [Reconcile] run after `t + 32 s` (the 30 s invocation completion bound and the 2 s clock allowance this example discloses) probes, and closes as in the crash where the database holds the record and as in the stall where it does not.

### The refusal

**The refusal.** A different caller opens a disclosure and `SelectiveDisclosure.record` refuses invalid-request. The adopter partitions the arm pre-commit and calls [Refuse]; `ledger.disclosure.refused` lands with the reason; the intent is closed; the trail keeps the authenticated attempt. Nothing for the sweep.

### Rejection — a second invocation of the same act

Two operators call `transfer_custody` for one chain within a second of each other, in an adopter whose act key is the chain. The first's [Open] takes the critical section and writes its intent. The second's [Open] reads the first's open intent ahead of the take and lands act-in-flight, or, where that intent is not yet visible to the read (Capability requirement 8), waits on the critical section and takes it after the first's [Close] releases. Called again, or at that take, its step-3 pre-check finds no open intent — the outcome read runs only for a `repeatable = no` kind, and a transfer is repeatable — so it writes its own intent and its own transfer. Had the kind been non-repeatable (a genesis), the second would have landed `act-landed(outcome_event_id)` and the adopter's `already-*` arm would have answered its caller.

### Rejection — the caller's retry after outcome

A caller receives `recording-failure(outcome)`. The position says the act may exist. The caller does not re-run; it calls the adopter's read (through [Read Invocation]) and finds the act open — the sweep has not yet run — then, a minute later, closed with `recovery = true`. A caller that re-ran would have found `act-in-flight(invocation_id)` at [Open], the open intent being younger than the bound plus the allowance — and after the sweep, an act-landed refusal where the act is non-repeatable, or a second act where it is: the second act is the caller's decision, made with the position in hand.

### Regulated adversarial scenarios

**Regulator audit — "show me that every consequential act you took is accounted for."** The auditor enumerates the journal's `<kind>.intended` records inside the horizon and older than the bound, and for each finds exactly one closing record naming its invocation id — not since superseded, an abandoned carrying a later outcome with supersedes being the corrected-false-abandonment shape check 6 reads; recovery_intended records are not closings and may be several — within closure window of its recording instant, under the allowance (checks 2 and 3). An intent with no closing record is younger than the bound (in flight), a conformance failure surfaced on compliance surface, or an intent of a kind the bindings table no longer serves, and the auditor can tell which from the stamps alone.

**Disputed act — "I never authorized that disclosure."** The outcome names invocation id; the intent record with that id is attested under the disputant's credential, verified before the database committed (Invariant 1), and sealed (the tamper of the atom's journal need). If the outcome carries `recovery = true` and no resolving actor, the sweep wrote it — under `ledger-reconciler`, behind a recovery_intended record — and acting actor reference still names the disputant. The structural rebuttal is the intent, not the outcome; the sweep changes who attests the outcome, never who attested the intent.

**Breach investigation — "the reconciler's credential was compromised; what could it have written?"** Every record under the service identity is a closing record naming an invocation id whose intent stands under a human's credential; a service-identity record with no such intent is a write outside this composition (check 5), and an outcome the database does not corroborate is one the sweep could not have derived (check 6). The compromised identity could close acts, never open them, and close only acts whose intents exist — the intent record is the control the service identity cannot forge.

## Source

The composition anchors the accountability a regulated adopter's regime requires of a consequential act: an attributable record of intent before the act, a record of outcome after it, and a bounded, attributable account of any act the process failed to record — SOX section 404 (Sarbanes-Oxley Act — internal controls over financial reporting), HIPAA section 164.312(b) (Health Insurance Portability and Accountability Act — audit controls), PCI DSS Requirement 10 (Payment Card Industry Data Security Standard — logging and monitoring), 21 CFR (Code of Federal Regulations) Part 11 (electronic records and signatures), and GDPR (General Data Protection Regulation) Article 30 and Article 32 (records of processing; integrity of processing). Each adopter's own section names the regime its act falls under; this composition supplies the form the regime's *accountability* clause requires and no substantive judgment about the act.

## Proof

### Generation acceptance

A derived implementation of Durable Intent is acceptable when the following are provable to an auditor given the journal and the adopter's constituent records.

#### Conformance checks

```
Check 1.1: EVERY outcome record whose intent is inside the horizon MUST follow, in the journal's sequence, an intent record with the same invocation id attested under the actor the outcome names — the outcome's own actor reference where recovery is absent, the outcome's acting actor reference where recovery EQUALS true.
Check 1.2: An auditor MUST decide inside the horizon by the one-record read of the intent event id answering the intent record within the keep.
Check 1.3: An auditor MUST NOT decide inside the horizon by arithmetic on the outcome's stamp or by the presence of an answer.
Check 1.4: An auditor MUST answer purged, never absent, for an outcome whose intent lies past the keep of the atom's journal need.
Check 2.1: For EVERY elapsed intent inside the horizon, two unsuperseded closing records of any of the four kinds MUST NOT name the intent's invocation id at any reading inside the horizon.
Check 2.2: For EVERY elapsed intent inside the horizon, two `<kind>.intended` records MUST NOT carry the intent's invocation id.
Check 2.3: Two intents MUST NOT stand open on one (kind, act key) at any reading inside the horizon, for a kind whose service identity DOES NOT EQUAL none.
Check 2.4: An auditor MUST read supersession transitively PER the section titled Which closing stands and count the reachable set as one closing.
Check 2.5: An auditor MUST read EVERY outcome as EXACTLY ONE OF the three outcome shapes.
Check 2.6: An auditor MUST report an outcome matching no outcome shape as a failure to conform.
```
Term outcome shape: recovery absent with actor reference set to the intent's actor reference; recovery set to true with resolving actor, actor reference set to resolving actor, acting actor reference set to the intent's actor reference, whether or not a `<kind>.recovery_intended` precedes it; recovery set to true without resolving actor, actor reference set to the service identity, acting actor reference set to the intent's actor reference, preceded by one or more `<kind>.recovery_intended` naming the same invocation id.

#### External checks

```
External check 7: An auditor MUST clear from external evidence that each adopter's outcome envelope is the true maximum of the outcome payloads the kind writes.
```
### Vocabulary

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

[Open]'s refusal where the act's critical section could not be taken (a failed take, a storage-failure and no answer included: open step 2.3) or could not be taken within the current holder's remaining lease, or was held with too little of the lease left to write (open step 3.12, open step 4.2b); nothing is written and the call may be retried.

Kind:       Member
Member of:  the open rejections
Role:       Rejection
Projection: section_unavailable

#### Not Open

[Close]'s precondition (close 4) and [Refuse]'s step 0, and theirs alone: an invocation id and intent event id pair the adopter's action did not receive from its own [Open]. An adopter's programming error, not a protocol state; nothing is written. It is the adopter's action that decides it and no action of this pattern returns it, so neither signature lists it.

```
Not Open 1: The composition MUST NOT decide not-open.
Not Open 2: The adopter's action MUST hold [Open]'s returned pair on the action's own call stack for the life of the invocation.
Not Open 3: The composition MUST NOT decide not-open from a map or a range read.
Not Open 4: [Close] MUST land recording-failure(outcome) at step 1 for a pair no [Open] returned.
Not Open 5: [Refuse] MUST land recording-failure(refusal, constituent code) at step 1 for a pair no [Open] returned.
```
Not Open 4 and Not Open 5 are decided where the grant answers none (close step 1.2, refuse step 1.2), an expired grant included: the composition cannot tell a pair no [Open] returned from a grant that ended, answers both alike and writes nothing. No rule checks that intent event id belongs to invocation id; the pair is the adopter's to hold whole (Not Open 2).

#### Not Known

The read's answer for an act with no readable intent at all, at [Read Invocation] and at [Resolve], a lawfully purged intent and a blank act key, invocation id or intent event id excepted at [Resolve] (resolve 12, resolve 33a); for an invocation id no readable intent of the act carries, and for a kind the bindings table does not serve and for a blank act key, at [Read Invocation] (read invocation 17, read invocation 18); and for an intent event id naming no intent of the act that carries the invocation id, at [Resolve], where a blank act key, invocation id or intent event id is excepted. Absence, not destruction: a lawfully purged intent is answered `invalid-request(purged)` at [Resolve], which takes intent event id for exactly that reason. [Read Invocation] is the one surface that cannot make the distinction and says so.

Kind:       Member
Member of:  the read rejections and the resolve rejections
Role:       Rejection
Projection: not_known

#### Journal Unavailable

The read-path outage code at [Open] step 1 and step 3, [Reconcile] step 1 and [Read Invocation]: nothing was written, retry. A read's failure, never a write's. [Close], [Refuse] and [Resolve] do not carry it — by the time they read, the act's existence is decided, so their read failures land on their position's recording-failure arm.

Kind:       Member
Member of:  the open rejections, the read rejections and the sweep's
Role:       Rejection
Projection: journal_unavailable

#### Already Accounted

[Refuse]'s and [Resolve]'s refusal where a closing record already names the invocation id; carries the closing event id (Term closing event id). Nothing is appended; the caller reports the act as accounted for. Distinct from not-open (a programming-error diagnosis never decided from a journal read) and not named `already-closed`, a constituent's pre-commit code an adopter transcribes verbatim.

Kind:       Member
Member of:  the refuse rejections and the resolve rejections
Role:       Rejection
Projection: already_accounted

#### Act Landed

[Open]'s refusal for a non-repeatable act whose outcome act closings holds; carries the outcome event id. The adopter's own re-entry arm answers the caller. Where act closings holds none for an act the adopter's database holds — its outcome's payload destroyed at the horizon, or an escalation standing — the commit's own refusal answers instead.

Kind:       Member
Member of:  the open rejections
Role:       Rejection
Projection: act_landed

Term actors: composition (also: this composition) — the atom's own build, the subject of a rule no one action owns; invocation; sweep run (also: the sweep, the run); operator; adopter's action (also: the adopter, the action); caller; deployment; auditor; substrate; critical section host (also: the host); writer — EXACTLY ONE OF invocation, sweep run, operator; reader; register (the deployment's findings surface); surface — [Read Invocation] or Generation acceptance check 2.

Term records: `<kind>.intended`, `<kind>.<outcome>`, `<kind>.refused`, `<kind>.recovery_intended`, `<kind>.abandoned`, `<kind>.escalated`, [Finding].

Term record verbs: write, read, read back, take, release, hold, yield, adopt, retry, refuse, return, surface, count, probe, close, examine, keep, drop, name, carry, size, validate, land, supersede, rebuild, populate, clear, discard, report, proceed, wait, persist, start, derive, sample, declare, bind, treat, transcribe, issue, mint, reach, reveal, escalate, abandon, open, advance, set, move, admit, exclude, stand, serialize, time, query, run, pass, decide, pair, share, stay, sum, rely, trigger, exist, answer, call, follow, re-read, leave, supply, perform, exempt, bound, block, use, re-run, match, map, make, export, classify, choose, cap, vary, update, touch, suppress, stamp, retain, resolve, remove, reject, recover, record, re-take, partition, own, owe, omit, offer, know, inspect, govern, free, fire, end, describe, corroborate, confirm, compare, collapse, check, charge, change, belong, add, commit, append, quantify, survive.

Term cited: take, try_take, remaining, expiry instant, call in flight, no answer: Bonds. invocation id, act key, critical section key, critical section holder, sealed, closing record, invocation journal: Declarations. pairing datum: Contracts. payload cap, reference length cap, attestation id width, recording instant, sequence number, next sequence number, event id, action reference, reserved namespace, invalid-credential, invalid-request(step-1), invalid-request(step-2), invalid-request(step-3), invalid-request(step-4), recording-failure(step-2), recording-failure(step-3), recording-failure(step-4): Audit Trail, held with the attested append (the app's glue).

Term value sets: landing actor = invocation | sweep | operator. state = open | closed | refused | abandoned | escalated | resolved. disposition = outcome | abandoned | escalated. act probe answers committed | not-committed | undecidable | unavailable. commit partition = pre-commit | committed | unknown. repeatable = yes | no. service identity = an actor | none. findings = journal-unavailable | store-unavailable | credential-refused | closure-at-risk | unbound-kind | escalated. [Resolve]'s invalid-request causes = purged | malformed | too-young | already-abandoned | candidates-over-cap.

Term position: intent | outcome | refusal | resolution — the record a write lands: the intent at [Open], the outcome at [Close] or after [Yield], the refusal at [Refuse], the resolution at [Resolve].

Term intent payload: intent data with invocation id, kind and act key added.

Term outcome payload: outcome data with invocation id, intent event id, kind and act key added.

Term supersedes: the field of a closing [Resolve] writes over an existing record, naming that record's event id.

Term resolving actor: the operator's actor reference, carried by a closing record an operator writes through [Resolve].

Term recovery: a closing record's flag, set to true on the sweep's recovered outcome (Term recovered outcome payload) and on every closing an operator writes through [Resolve], and absent on the invocation's own outcome (Term outcome shape).

Term readable intent: an intent record within the keep the atom's journal need asked, from the record's append to the record's retention end.

Term true maximum: the largest outcome payload a kind writes, as External check 7 clears.

Term bounds: invocation completion bound, commit round trip, journal write bound, pause bound, read bound, run bound, closure window, clock allowance, retention period, intent candidates cap, read cap.

Term cadences: sweep cadence.

Term qualifiers: migrated — rewritten in GRACE-lang, the corpus's rule grammar, v0.35 (2026-09-11).

Term terms: (named expressions, each declared where it is used) examine edge, settle bound, retention end, sweep lease, in-flight, aged, partition, examined, surfaced, standing closing, closing event id, terminus, caller kind, read path, read-your-writes, journal join, lost reply, `position's existing arm`, critical section key, critical section holder, critical section duration, reply, release, hard alert, unfenced write, write floor, commit floor, instance finding, kind, act key, invocation id, now, operator run id, open result, close result, invocation report, invocation entry, span, acting actor reference, resolving actor, recovery_intended, database candidates, readable intent.

[Open]: #open
[Close]: #close
[Refuse]: #refuse
[Yield]: #yield
[Read Invocation]: #read-invocation
[Recording Failure]: #recording-failure
[Act In Flight]: #act-in-flight
[Act Landed]: #act-landed
[Critical Section Unavailable]: #critical-section-unavailable
[Not Open]: #not-open
[Not Known]: #not-known
[Journal Unavailable]: #journal-unavailable
[Already Accounted]: #already-accounted
[Finding]: ./escalation.md#finding
[Reconcile]: ./sweep.md#reconcile
[Resolve]: ./escalation.md#resolve

## Status

`doing` — see the Ledger.

<details markdown="block">
<summary>
    <h2 id="ledger" style="display: inline-block; margin-left: 1.5rem;">Ledger</h2>
</summary>

```
status: doing
formal: pending — no model yet; new formal modelling is paused (budget.toml formal_new_models, Scott 2026-11-23) and Lean replaces the model layer
last gate: 2026-11-28 — Final Critique 18, a delta round (diff base 6fc0bc44, 2 labels: act section 5 and Term offer key; the key offer's existence read, Final Critique 17's settle and one unit commit), one reader (Linus opencode-go/beam-free; GRID and EOS not run; the Claude reader off), frozen at b34e69f0 — foundational count 1 after the blind second triage, cured, not clean, no sample; Linus's one foundational finding, that Term offer key names Read Invocation, which takes kind and act key beside the invocation id, so a key check holding the invocation id alone answers not-known (read invocation 17, read invocation 18), was placed refining B by the first triage (every writer that pairs a record on invocation id holds the kind and the act key: Primitive policy 2, resolve's inputs, reconcile step 2.1) and foundational A by the blind second triage (Opus 5.5; two conforming builds: an app that passes kind and act key, and one that calls the read with the offered value alone, which Bonds' Term existence read ("for one value") permits), so the count is 1; Linus's cure, key act key, was refused (an act key cannot name one invocation of a repeatable kind: Invariant 3.2, Term journal join) and cured instead by read invocation 19, the app's key check calls Read Invocation with the kind and the act key of the act the write belongs to; two refining cures, open step 4.2b now reads "with nothing written" as open step 2.3 and open step 3.12 do and the Critical Section Unavailable entry cites open step 4.2b, the label of the landing; the blind triage's own finding that [Open]'s remaining queries at open step 4.1 and open step 5.4 have no unavailable arm of their own was refuted (Bonds guard 2 reads a remaining that answers no answer as none, guard 4 and Execution Contract Read 1), its other three placed rhetorical, the checker's eleven hits false; the delta round that reads the cure comes next; 2026-11-28 — Final Critique 17, a delta round (diff base 412a4c68, 0 labels reached; the three term entries and one Member line Final Critique 16 changed, with the six rules and table rows that name them), one reader (Linus opencode/beam-free; GRID and EOS not run; the Claude reader off), frozen at 6fc0bc44 — foundational count 0 after the blind second triage, clean, one sample; Linus's one foundational claim, that act section 5's [Resolve] and Journal Unavailable cannot both be obeyed where [Resolve]'s read fails with an unavailable arm, was placed not foundational by both triages (refuted by the first, refining B by the blind second triage, Opus 5.5): act section 5 transcribes the guard need's unavailable arm, the failed take of open step 2 and resolve 6, and Journal Unavailable and Term read path govern the journal reads, so a [Resolve] whose take fails answers section-unavailable and one whose re-read fails answers recording-failure(resolution), each call one answer; cured by act section 5 naming the guard need's arm in place of "the atom's"; refining, cured: the Critical Section Unavailable entry names open step 2.3's failed take beside the lease readings, and the Not Known entry's first clause excepts a blank act key, invocation id or intent event id at [Resolve] (resolve 33a) as its last clause does; the blind second triage's N1, that the Critical Section Unavailable entry omits [Resolve], refuted: Final Critique 16 narrowed it to [Open]'s refusal because Escalation owns [Resolve]'s (its Section Unavailable entry and resolve 6, resolve's signature lists section-unavailable); the checker's eleven hits false; model redraw: none; 2026-11-28 — Final Critique 16, a delta round (diff base 1c3019a2, 4 labels), one reader (Linus opencode/beam-free; GRID and EOS not run; the Claude reader off), frozen at 412a4c68 — foundational count 1 after the blind second triage, cured, not clean, no sample; Linus's two foundational claims were placed not foundational by both triages: (1) Term Not Known's purged and blank clauses at [Resolve] overlap: refining, Escalation owns [Resolve] (resolve 10, 12, 33a, 34 except a purged intent and a blank id from not-known), and Linus's cure would take a purged intent out of not-known at [Read Invocation] too, against read invocation 12; cured by the first clause reading "a lawfully purged intent excepted at [Resolve]"; (2) read invocation 18 owes a blank invocation id not-known with no read: refuted, invocation id is optional and blank is the list-all call (read invocation 2), so the cure would answer every list-all call not-known; the blind second triage's own foundational finding: the Critical Section Unavailable entry claimed [Resolve]'s refusal and the resolve rejections while Escalation owns [Resolve] and declares its own Section Unavailable entry with another Projection spelling (`section-unavailable`), so two entries of one refusal named two spellings; cured by the entry naming [Open]'s refusal and the open rejections alone; refining cured: Journal Unavailable's membership names the read rejections, as [Read Invocation]'s refuses line lists it; the checker's eleven hits false; model redraw: none; 2026-11-28 — Final Critique 15, a delta round (diff base 0bfa7bf9, 146 labels), one reader (Linus opencode/beam-free; GRID and EOS not run), frozen at 1c3019a2 — foundational count 2 after the blind second triage, cured, not clean, no sample (Linus's three foundational claims, that open step 4.1 and 4.3, close step 3.1 and 3.10, and refuse step 3.1 and 3.13 each bind one call to write and not write, were placed refuted by both triages: each floor arm lands a refusal the action's refuses line lists (section-unavailable, recording-failure(outcome), recording-failure(refusal, constituent code)), and Execution Contract Read 4 binds a rule saying what an action does only to a call it admits, as Final Critique 14 placed the same class; journal write bound 1 already gates every write; the blind second triage, one cold reader on Opus 5.5, found two foundational, Kind A, coverage, that the report missed: close step 3.10 and refuse step 3.13 test a remaining queried for the record and only the action prose said the query comes after the step-2 re-read, so one build writes on the step-1 reading and another re-queries, now close step 3.11 and refuse step 3.14; and a blank act key at [Read Invocation] answered not-known with a read in one build, journal-unavailable in an outage in another, and the Not Known entry's exception for a blank act key could be read to reach it, now read invocation 18 and the entry names it; refining, cured: refuse step 3.1 takes the attested append's form its siblings use; the checker's eleven hits were false (answers lines the page's Terms declare, the Critical Section Unavailable entry, no case table for Read Invocation, four acronyms spelled out at line 747); rhetorical, left as written: open step 3.9a's capital IS, Which closing stands 3's second clause; no model redraw: no model reads these rules); 2026-11-28 — Final Critique 14, a full round, three readers (GRID opencode/nemotron-3.5-super-vl-free, EOS anthropic/claude-sonnet-5-5, Linus opencode/beam-free; three families, no pass lapsed; the Claude reader off), frozen at 0bfa7bf9 — foundational count 1, cured, not clean, no sample; ten foundational claims were reported (GRID 2, EOS 4, Linus 4) and the triage placed nine refuted or refining: that open step 3.4 and 3.5 (and 3.6 and 3.7) oblige two things on one input (a release is a guard call and the landing is the answer, as the page pairs them at open step 3.9b and 3.9c), that invalid-credential first on the refuses line decides a call refused earlier (it arises only as the attested append's answer), that the Primitive policy ranges of open step 4.4 and close step 3.2 import the other position's rules (each position's rules are guarded by position), that open step 5.1's "next re-read" names no read (the record's number and instant are the same on any read), that close step 4.3 contradicts close step 3.9 (placed refining: Execution Contract Read 4 binds a rule only for an admitted call, and 4.3 now reads the landed outcome), and EOS's non-repeatable second attempt and retention floor placed refining, Kind C, and asked of Scott; one stood foundational, Kind A, wording, EOS's: Primitive policy 21 and 22 read "the intent-position read-back", which Term read path also names for Primitive policy 35's, so a lost reply whose read-back finds nothing could land invalid-request (policy 22) or recording-failure(intent) (policy 37b), the caller told to fix or to retry; both now read "the read-back of Primitive policy 20"; eleven refining cures made (close step 4.3 and 3.4, Invariant 1.2's act, Action wiring 4's routes named by the page, Term open invocations and sequence high water past the horizon, Term actors takes the composition, Term cited takes the step codes the attested append holds, Term invocation completion bound adds close step 1's query); 2026-11-28 — Final Critique 13, a delta round (diff base e58c04a8, 3 labels), one reader (Linus opencode/beam-free; GRID and EOS not run), frozen at 6ba66cf6 — foundational count 1 after the blind second triage, cured, not clean, no sample (Linus's two foundational claims: yield 8 against Execution Contract Constituent failure 1 was placed refuted by both triages, since the grant's ending at its instant is the lapse of an unreleased grant and no write, Term release and the section's own text say so, yield 8 is the rule that cites the label to land ok with nothing written as act section 21 does at its four actions, and the finder's storage-failure would add an arm [Yield]'s signature does not have; Term caller kind, the second claim, was placed refining by the first triage and foundational, Kind A, by the blind second triage, which decides: Logic confinement 13 canonicalizes the references a call carries and the service identity is a setting of the bindings table the call does not carry, so one build compares the actor reference canonicalized against the service identity raw, another canonicalizes both, and a service identity held in a spelling the seam changes is classified human by one and service by the other, which decides whether open step 1.2 lands invalid-request; cured by Term caller kind deciding the comparison on the actor reference as the deployment canonicalizes it and on the kind's service identity's actor reference in that same canonical form; refining, cured: the checker's invalid-credential hit, whose owner Term cited now names, Audit Trail's attested append; refuted: open step 1.2 owing a service a path to open (the service identity only closes, Breach investigation), the owner of the kind's service identity (Term bindings table, bindings table 1), and ten of the checker's eleven hits (answers lines the page's Terms declare, the Critical Section Unavailable entry, no case table for Read Invocation, four acronyms spelled out at their one use); no model redraw: no model reads the two rules); 2026-11-27 — Final Critique 12, a delta round (diff base 6d80e43b, 3 labels), one reader (Linus opencode-go/beam-free; GRID and EOS not run), frozen at e58c04a8 — foundational count 1, cured, not clean, no sample (Linus's one foundational, Kind A, triaged by the first triage: Execution Contract Constituent failure 1 lets an app land an atom's answer as a code of its own that commits nothing only by a rule that cites that label, and yield 8, Final Critique 11's cure, answers ok when the release answers storage-failure without citing it, so a build that reads the Execution Contract over the page answers storage-failure where another answers ok; yield 8 now cites Execution Contract Constituent failure 1, as act section 21 does; refining, cured: Term caller kind compares the actor reference by byte-identity but cited nothing for the spelling compared, and now says the actor reference as the deployment canonicalizes it at the seam, Execution Contract Logic confinement 13, as Capacity Constraint Enforcement's and Consent's actor reference entries do; Linus's second refining report, that a blank actor reference has no caller kind, was placed rhetorical, since open step 1.10 lands invalid-request for a blank actor reference and open step 1.2 lands the same code for a service, so no two builds answer differently; no model redraw: the models' answers are unchanged); 2026-11-27 — Final Critique 11, a delta round (diff base 0d91df79, 9 labels), one reader (Linus opencode-go/beam-free; GRID and EOS not run), frozen at 6d80e43b — foundational count 1 after the blind second triage, cured, not clean, no sample; Linus reported none and pressed three questions that held (Primitive policy 7 and 7a against Term caller kind, open step 2.3 against act section 21, pause bound 1); the blind second triage, one cold reader on Opus 5.5, placed one foundational, Kind A: act section 21 lists [Open], [Close], [Refuse] and [Resolve], so a release at [Yield] (yield 5) that answers storage-failure had no rule, and Execution Contract Constituent failure 1 then made the app action answer storage-failure, a code that carries no position, where the act may exist (Invariant 8.4); cured by yield 8, [Yield] answers ok with nothing written and the grant ends at its instant, so the table's recording-failure(outcome) after [Yield] stands and [Yield] gains no failure arm (Atom budget 1); refining, cured: Term caller kind cited Primitive policy 7, the not-blank test, for the clause that forbids inspection, which the grammar batch's split moved to Primitive policy 7a; the second triage's refining report on pause bound 1 (Lease Capability requirement 7 against a journal write that is a unit of work) was placed rhetorical by the first triage, since both floors and Invariant 2 hold under either reading and its cure would restate Lease Capability requirement 13; the checker's twelve hits were false (a result term read as a code, the Projection read against the heading, `ok`, the Read Invocation rules read as no case row, four acronyms spelled out in their parenthesis at line 746); 2026-11-25 — Final Critique 10, a delta round (diff base 699fb37e, 7 labels), one reader (Linus opencode/beam-free; GRID and EOS not run), frozen at 0d91df79 — foundational count 0 after the blind second triage, clean, one sample; Linus's one foundational claim, that Invariant 6.2's Rests on line promises an intent opened earlier still fits while outcome envelope's truth is an externally-clearable check that is no setting held to the start, was placed rhetorical, Kind D, by both triages (an Opus subagent for the first): the envelope is a field of the bindings table, a setting with no default held to the start by Execution Contract Logic confinement 17 (bindings table 1), Primitive policy 13a sizes the largest record on the settings the start reads, and the truth of the envelope, that it EQUALS the true maximum, is Invariant 6.1's antecedent and External check 7's, cleared by an auditor from external evidence and read by no instance, so no build has anything to re-evaluate mid-run; the finder's cure would have declared the envelope unheld against bindings table 1; the sentence is left as written; 2026-11-25 — Final Critique 9, a delta round (diff base 45912569, reach of the diff on the page), one reader (Linus claude-sonnet-5-5; GRID and EOS not run), frozen at 699fb37e — foundational count 1 after the first triage (no blind second triage, the count is not zero), cured in the round, not clean, no sample; the report claimed 1 foundational, 5 refining and 1 rhetorical; cured: Primitive policy 13a, a start condition (the instance MUST NOT start while the largest record of any kind in the bindings table, sized as Primitive policy 12 sizes a largest record, on the settings the start reads, exceeds the substrate's payload cap), so every closing written after any start fits the settings of that start (Execution Contract Logic confinement 17) and an intent opened under a larger cap, or under a smaller intent candidates cap, no longer meets a closing the substrate refuses, the form Defensible Retention's start condition on its largest gate record already takes, with Invariant 6 resting on it; refining cured: open step 1.4 carries an operator on each disjunct, Primitive policy 12 sizes the largest record for a kind in the bindings table as open step 1.3 does, and Term as the substrate measures a payload sizes an abandonment's cause at the longest word of Escalation's closed Term cause; refuted: Invariant 3.2 and Primitive policy 5 (Term journal join already makes a read of one record by the event id another carries, the closing's intent event id and supersedes among them, a lookup and no join, and Invariant 3.3's join is of the intent with the adopter's record, Term act probe), close 6 (the outcome action reference is the adopter's own constant, one of the kind's outcome refs, so a bad one is the adopter's defect that Term hard alert pages operators for, and both readings land recording-failure(outcome) with nothing appended), the rhetorical finding (Term largest record runs 62 words and Term as the substrate measures a payload two sentences of 76 and 81); model redraw deferred to Lean: none
open: none
```

</details>

<details markdown="block">
<summary>
    <h2 id="decisions" style="display: inline-block; margin-left: 1.5rem;">Decisions</h2>
</summary>

- **2026-11-23 — Split out of Recoverable Invocation.** *Chose:* the rules of Open, Close, Refuse, Yield and Read Invocation, Which closing stands, the journal's position rules and Invariant 1, 2.1, 2.6, 3, 6 and 8, moved as they stood, a rule changing only where its owner's name changed. *Over:* one page carrying the whole protocol after 57 rounds. *Because:* a pattern that has run far past the round cap does not ground, and the corpus is moving from compositions to atoms, bonds and marked glue (Scott, 2026-11-23, rulings of 05:35Z and 9:29 AM Central).

</details>

NOTE: End of Durable Intent.
