---
title: Approval Step
parent: Atomic Concepts
has_toc: true
toc: true
---

# Approval Step

<details markdown="block">
<summary>Table of contents</summary>
{: .text-delta }
1. TOC
{:toc}
</details>

## Summary

Approval Step records a single authorization gate. A specific thing was submitted for approval, presented to one named approver, and ended in a decision — approved, rejected, or withdrawn — with who decided, when, and why.

Each step has exactly one approver (the only person who may approve or reject it), one submitter (the only person who may withdraw it before a decision), one subject (the thing being approved), and one scope (the kind of approval being requested). Those, and the timestamps, are fixed at submission and never change.

A step has four states: pending, plus three terminal ones — approved, rejected and withdrawn, the last two each with a required reason. All three are absorbing; there is no re-open and no decision reversal.

The core guarantee is that every decision is fully attributed. An anonymous decision, a rejection with no reason, or a missing timestamp is a failure. So it is provable that a required control existed and operated, which is exactly what an auditor or investigator asks for.

This is distinct from a permission (standing, reusable authority to do a class of things) and from an assignment (who owns a task, not who approved it). A controller may be *permitted* to approve journal entries, and each entry still needs an Approval Step proving they *did* approve that one. Delegation is a composing concept, not a property of this atom.

*Also known as: an approval gate, a sign-off, an authorization step, a review gate.*

---

## Intent

WHY:
Many actions in regulated systems require explicit human authorization before they may proceed. A journal entry above a materiality threshold needs a controller's approval before it posts. A clinical-trial protocol deviation needs the principal investigator's approval before the deviant procedure happens. A pharmaceutical batch release needs a qualified person under 21 CFR (Code of Federal Regulations) Part 211. An engineering change order needs a release chain. The structure is identical every time: something is submitted, a named actor reviews it, and the outcome is an auditable record that external evaluators rely on as evidence the required control existed and operated.

This atom is that structure and nothing else. It records the gate, who the gate was for, the outcome, the actor who decided, and when — and it guarantees those records are present and immutable. Cryptographic protection against post-hoc modification, the bar for court-admissible evidence under SOX (Sarbanes-Oxley Act) section 404 and FDA (US Food and Drug Administration) Part 11, is [Tamper Evidence](./tamper-evidence.md)'s and is not provided here.

Three adjacent concepts are distinguished, and every distinction is load-bearing.

[Permissions](./permissions.md) governs *standing* authorization — a persistent grant, checked at every relevant invocation, live until revoked. This atom governs *transient decision* authorization — a one-time gate on one subject that produces a terminal outcome and closes. Permissions answers *may this actor generally do things of this kind?* This atom answers *has this specific thing been approved by the specifically named actor for this specific scope?* A controller with permission to approve journal entries still needs a step record per entry: the grant says they are allowed, the step says they did. Both are present in a conforming SOX deployment and neither replaces the other.

[Assignment](./assignment.md) governs *responsibility binding* — who owns the work, with a lifecycle of its own. This atom governs the decision. A document may be assigned to an author and simultaneously submitted to a reviewer; the two coexist without overlapping. Confusing them produces either a spec that cannot record the approval or one that loses track of who owns the work.

[State Machine](./state-machine.md) is the general engine: states and transitions declared by the deployment, opaque to the atom. This atom is a *specific* state machine whose four states, four transitions and approval semantics are fixed here — one named approver, a decision that is itself a compliance record, a required reason on rejection. The axis is specificity: an external evaluator knows this atom's states from the spec and must read a State Machine instance's declaration to know that one's. The two are the fixed and declared poles of the same category, and they compose into [Execute Gated Workflow](../compositions/execute-gated-workflow.md).

## Structure

### Identity model

```
Identity 1: The atom MUST identify a step by the step id.
Identity 2: The host MUST allocate a step id at the seam.
Identity 3: The transition MUST NOT allocate a step id.
Identity 4: The atom MUST NOT change a step id.
Identity 5: Two steps in one database instance MUST NOT share a step id.
Deleted: Identity 6. Operation 39 owns it: two steps sharing a submission instant are ordered by step id in lexicographic byte order.
Identity 7: The deployment MUST route EVERY call to one database instance.
Identity 8: The atom MUST NOT identify a step by the subject reference.
Identity 9: The atom MUST admit a second step carrying a recorded subject reference.
Identity 10: The atom MUST compare a reference byte-exactly.
Identity 11: The atom MUST NOT normalize a reference.
Identity 12: The atom MUST NOT confirm that a subject reference names a known subject.
Identity 13: The atom MUST NOT interpret a scope.
Identity 14: The deployment MUST supply a reference in one canonical byte form.
```

NOTE: open 2026-10-26-a — the step id's source is named as the host's allocation (Identity 2) and not among what the deployment supplies (Capability requirement 1, Capability requirement 5).

Term step: one authorization gate — one subject, one approver, one submitter, one scope and one outcome; an [Approval Step], the record this atom holds.

Term step id: the opaque value naming one step — a [Step Id]; host-allocated at the seam.

Term subject reference: the opaque reference naming the thing being approved — a [Subject Reference]; a property of the step, never the step's identity.

Term approver reference: the opaque reference naming the actor required to approve — an [Approver Reference]; the authorization anchor.

Term submitter reference: the opaque reference naming the actor requesting approval — a [Submitter Reference]; the attribution anchor for the submission.

Term scope: the string naming the kind of approval requested — a [Scope]; recorded and filtered on, never interpreted.

Term reference: subject reference, approver reference, submitter reference, deciding actor, withdrawing actor, step id OR scope — every string this atom compares for equality.

Term database instance: one named database a call is routed to; step id uniqueness ranges over one instance.

Term seam: the atom's I/O boundary as the section titled Logic Confinement Principle in `execution-contract.md` declares it; the host injects the clock reading and the step id here.

Term transition: the atom's evaluation of one call against the step records, as the section titled Logic Confinement Principle in `execution-contract.md` declares it.

### State

```
Deleted: State 1. Invariant 3.1 owns it.
State 2: The atom MUST NOT offer a re-open surface.
State 3: The atom MUST NOT offer a decision reversal surface.
State 4: The atom MUST NOT offer a re-submission surface on a recorded step.
State 5: The atom MUST NOT offer a removal surface.
State 6: The atom MUST NOT offer a delegation surface.
State 7: EVERY step MUST carry step id, subject reference, approver reference, submitter reference, scope, submission instant and a state.
State 8: A step MAY carry reason.
State 9: EVERY approved step MUST carry deciding actor and decision instant.
State 10: EVERY rejected step MUST carry deciding actor, decision reason and decision instant.
State 11: EVERY withdrawn step MUST carry withdrawing actor, withdrawal reason and withdrawal instant.
State 12: An approved step MAY carry decision reason.
State 13: A pending step MUST NOT carry an attribution field.
State 14: The database instance's step count MUST NOT fall.
State 15: The atom MUST NOT record a receipt instant.
```

### Capability requirement

```
Capability requirement 1: The deployment MUST supply now at the seam.
Capability requirement 5: The deployment MUST supply the step records PER Execution Contract Database 1 through 4, Execution Contract Read 1 through 3 and Execution Contract Refusal 1.
Deleted: Capability requirement 2. Execution Contract Logic confinement 7 owns it.
Deleted: Capability requirement 3. Execution Contract Logic confinement 7 owns it.
Deleted: Capability requirement 4. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 1. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 2. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 3. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 4. State 15 owns it.
Deleted: Clock semantics 5. Non-goal 21 owns it.
```

### Operations

```
submit(subject_ref, approver_ref, submitter_ref, scope, optional reason, optional submitted_at)
  answers step_id
  refuses invalid-request | storage-failure

approve(step_id, decided_by, optional reason, optional decided_at)
  answers approved
  refuses invalid-request | not-known | not-pending | unauthorized | storage-failure

reject(step_id, decided_by, reason, optional decided_at)
  answers rejected_outcome
  refuses invalid-request | not-known | not-pending | unauthorized | storage-failure

withdraw(step_id, withdrawn_by, reason, optional withdrawn_at)
  answers withdrawn
  refuses invalid-request | not-known | not-pending | unauthorized | storage-failure

read(query)
  answers the matching steps
  refuses invalid-query
```

```
Operation 1: IF subject reference EQUALS blank THEN [Submit] MUST answer invalid-request.
Operation 2: IF approver reference EQUALS blank THEN [Submit] MUST answer invalid-request.
Operation 3: IF submitter reference EQUALS blank THEN [Submit] MUST answer invalid-request.
Operation 4: IF scope EQUALS blank THEN [Submit] MUST answer invalid-request.
Operation 5: IF a supplied reason EQUALS blank THEN [Submit] MUST answer invalid-request.
Operation 6: IF now PRECEDES the resolved submission instant THEN [Submit] MUST answer invalid-request.
Operation 7: An admitted submit MUST record EXACTLY ONE step.
Operation 8: An admitted submit MUST stand the step in pending.
Operation 9: An admitted submit MUST answer the step id.
Operation 10: IF step id EQUALS blank THEN a resolving action MUST answer invalid-request.
Operation 11: IF the step id names no step THEN a resolving action MUST answer not-known.
Deleted: Operation 12. Execution Contract Refusal 1 owns it.
Operation 13: IF the step's state IS IN the terminal states THEN a resolving action MUST answer not-pending.
Deleted: Operation 14. Execution Contract Refusal 1 owns it.
Operation 15: IF the deciding reference EQUALS blank THEN a resolving action MUST answer invalid-request.
Operation 16: IF reason EQUALS blank THEN [Reject] MUST answer invalid-request.
Operation 17: IF reason EQUALS blank THEN [Withdraw] MUST answer invalid-request.
Operation 18: IF now PRECEDES the resolved decision instant THEN a resolving action MUST answer invalid-request.
Operation 19: IF the resolved decision instant PRECEDES the step's submission instant THEN a resolving action MUST answer invalid-request.
Operation 20: A resolving action MUST answer invalid-request on an attribution fault ONLY IF the step's state EQUALS pending.
Operation 21: IF deciding actor DOES NOT EQUAL approver reference THEN a deciding action MUST answer unauthorized.
Operation 22: IF withdrawing actor DOES NOT EQUAL submitter reference THEN [Withdraw] MUST answer unauthorized.
Deleted: Operation 23. Execution Contract Refusal 1 owns it.
Operation 24: An admitted approve MUST stand the step in approved.
Operation 25: An admitted reject MUST stand the step in rejected.
Operation 26: An admitted withdraw MUST stand the step in withdrawn.
Operation 27: An admitted approve MUST record deciding actor and the resolved decision instant as decision instant.
Operation 28: An admitted reject MUST record deciding actor, reason as decision reason and the resolved decision instant as decision instant.
Operation 29: An admitted withdraw MUST record withdrawing actor, reason as withdrawal reason and the resolved decision instant as withdrawal instant.
Operation 30: An admitted approve MUST record a supplied reason as decision reason.
Deleted: Operation 31. Execution Contract Database 1 owns it.
Operation 32: An admitted resolve MUST answer the action's success token.
Operation 33: A resolving action MUST NOT change a submission field.
Operation 34: IF the database refuses the write THEN a writing action MUST answer storage-failure.
Deleted: Operation 35. Execution Contract Refusal 1 owns it.
Operation 36: A refused action MUST leave the step as the call found the step.
Operation 37: A refused action MUST NOT record an attribution field.
Operation 38: An admitted read MUST answer the matching steps in submission instant ascending order.
Operation 39: An admitted read MUST order two steps sharing a submission instant by step id ascending in lexicographic byte order.
Operation 40: An admitted read MUST answer EVERY step matching the supplied filters.
Operation 41: An admitted read MUST NOT answer a step failing a supplied filter.
Operation 42: IF no step matching the supplied filters EXISTS THEN an admitted read MUST answer an empty step sequence.
Deleted: Operation 43. Term query and Operation 41 own it: a step carrying no instant on a range filter's axis fails the filter.
Operation 44: IF a filter's axis IS NOT IN the filter axes THEN [Read] MUST answer invalid-query.
Operation 45: IF a filter's axis IS IN the string axes AND the filter's value EQUALS blank THEN [Read] MUST answer invalid-query.
Operation 46: IF a state filter's value IS NOT IN the states THEN [Read] MUST answer invalid-query.
Operation 47: IF a range filter's end PRECEDES the range's start THEN [Read] MUST answer invalid-query.
Operation 48: [Read] MUST NOT write.
Deleted: Operation 49. Capability requirement 1 owns it.
Deleted: Operation 50. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 51. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 52. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 53. Execution Contract Read 1 owns it.
Deleted: Operation 54. Execution Contract Read 1 owns it: after the read, every refusal rule of [Submit] answers invalid-request.
Deleted: Operation 55. Execution Contract Refusal 1 and Operation 20 own it.
Deleted: Operation 56. Execution Contract Read 1 owns it: after the read, every refusal rule of [Read] answers invalid-query.
Operation 57: IF a supplied reason EQUALS blank THEN [Approve] MUST answer invalid-request.
Operation 58: IF the query is malformed THEN [Read] MUST answer invalid-query.
```

NOTE: watch the blank filter value (Operation 45).

Term now: the wall-time reading the host takes at the seam and hands to the transition, as the section titled Logic Confinement Principle in `execution-contract.md` declares it; never read inside the transition, never supplied by the business caller.

Term business caller: the party whose action the call carries, as the section titled Logic Confinement Principle in `execution-contract.md` declares it; never the source of an injected value.

NOTE: open 2026-10-26-b — Term seam, Term transition, Term business caller and Term now cite the section titled Logic Confinement Principle in `execution-contract.md`, which declares none of them.

Term states: pending | approved | rejected | withdrawn — a [State], and the whole state space.

Term terminal state: approved | rejected OR withdrawn — the three absorbing members of states.

Term resolving action: [Approve] | [Reject] | [Withdraw] — the three actions that close a pending step.

Term deciding action: [Approve] | [Reject] — the two a guard on approver reference covers.

Term writing action: [Submit] | [Approve] | [Reject] | [Withdraw] — every action but [Read].

Term deciding reference: deciding actor on a deciding action, and withdrawing actor on [Withdraw] — the actor reference a resolving action carries.

Term resolved decision instant: the instant a resolving action records, as decision instant on a deciding action and as withdrawal instant on [Withdraw] — the supplied value where one exists, and now otherwise.

Term resolved submission instant: the submission instant the step carries — the supplied value where one exists, and now otherwise.

Term submission field: step id, subject reference, approver reference, submitter reference, scope, submission instant OR reason — every field [Submit] sets.

Term attribution field: deciding actor, decision reason, decision instant, withdrawing actor, withdrawal reason OR withdrawal instant — every field a resolving action sets.

Term attribution reference: deciding actor on an approved step or a rejected step, and withdrawing actor on a withdrawn step — the actor reference a terminal step carries.

Term attribution check: Operation 15 through 19 and Operation 57 — every check a resolving action makes before the actor guard.

Term attribution fault: an attribution check the call fails.

Term filter axes: step id | subject reference | approver reference | submitter reference | scope | state | submission instant | decision instant | withdrawal instant — the nine axes [Read] accepts, and no others.

Term string axes: step id | subject reference | approver reference | submitter reference | scope — the axes whose filter value carries a string.

Term query: what a read asks for — a [Query]; any combination of the filter axes. A filter on submission instant, decision instant or withdrawal instant carries a range, whose filter values are its start and its end, and a filter on any other axis carries one string. An instant at either end lies inside the range; a step whose instant on the filter's axis lies inside the range matches the filter, and a step carrying no instant on that axis fails it. A query is malformed where a filter carries a value its axis does not take, a range missing its start or its end among them, or where an end a range carries is not an instant.

NOTE: watch the range's ends (Term query).

Term admitted submit: a [Submit] call whose references, scope, supplied reason and resolved submission instant the guards all admit.

Term authorization anchor: the approver reference on a deciding action, and the submitter reference on [Withdraw].

Term admitted resolve: a resolving action whose step id names a pending step and whose reason, deciding reference and resolved decision instant the guards admit, and whose deciding reference matches the step's authorization anchor.

Term admitted approve: an admitted resolve on [Approve].

Term admitted reject: an admitted resolve on [Reject].

Term admitted withdraw: an admitted resolve on [Withdraw].

Term admitted read: a [Read] call whose every filter axis and filter value the guards admit.

Term success token: approved on [Approve], rejected_outcome on [Reject] and withdrawn on [Withdraw] — the answer an admitted resolve returns.

| # | Condition | a resolving action answers |
|---|---|---|
| 1 | step id is blank | [Invalid Request] |
| 2 | step id is not blank, it names no step | [Not Known] |
| 3 | the step exists, it stands in a terminal state | [Not Pending] |
| 4 | the step stands in pending, an attribution check fails | [Invalid Request] |
| 5 | every attribution check passes, the deciding reference is not the authorization anchor | [Unauthorized] |
| 6 | every precondition passes, the database refuses the write | [Storage Failure] |
| 7 | every precondition passes, the database accepts the write | the success token |

Where two rows hold at once, the earlier row answers: the rows follow the refuses line (Execution Contract Refusal 1), and row 4 answers only on a pending step (Operation 20).

NOTE: watch condition negation — invalid-request occupies rows 1 and 4 of one precedence chain, so the answer alone does not say which guard refused. [State Machine](./state-machine.md) and [Audit Trail](../compositions/audit-trail.md) carry the same shape.

### Invariants

- **Invariant 1 — Submission immutability.**
  ```
  Invariant 1.1: A recorded submission field MUST NOT change.
  ```
- **Invariant 2 — Membership exclusivity.**
  ```
  Invariant 2.1: EVERY step MUST stand in EXACTLY ONE OF pending, approved, rejected, withdrawn.
  ```
- **Invariant 3 — Terminal absorption.**
  ```
  Invariant 3.1: A step whose state IS IN the terminal states MUST NOT leave the terminal state.
  ```
- **Invariant 4 — Approver exclusivity.**
  ```
  Invariant 4.1: An approved step's deciding actor MUST equal the step's approver reference.
  Invariant 4.2: A rejected step's deciding actor MUST equal the step's approver reference.
  ```
- **Invariant 5 — Submitter exclusivity.**
  ```
  Invariant 5.1: A withdrawn step's withdrawing actor MUST equal the step's submitter reference.
  ```
- **Invariant 6 — Decision attribution completeness.**
  ```
  Invariant 6.1: EVERY terminal step's attribution reference MUST stand non-blank.
  Invariant 6.2: EVERY terminal step MUST carry the terminal state's instant.
  Invariant 6.3: EVERY rejected step's decision reason MUST stand non-blank.
  Invariant 6.4: EVERY withdrawn step's withdrawal reason MUST stand non-blank.
  ```
- **Invariant 7 — Temporal ordering.**
  ```
  Invariant 7.1: A terminal step's terminal instant MUST NOT PRECEDE the step's submission instant.
  ```
- **Invariant 8 — Submission attribution completeness.**
  ```
  Invariant 8.1: EVERY step's step id, subject reference, approver reference, submitter reference and scope MUST stand non-blank.
  Invariant 8.2: EVERY step MUST carry a submission instant.
  ```
- **Invariant 9 — Concurrent step independence.**
  ```
  Invariant 9.1: A resolving action on one step MUST NOT change a second step's field.
  ```
- **Invariant 10 — Record durability.**
  ```
  Invariant 10.1: The atom MUST NOT remove a step from the database.
  Deleted: Invariant 10.2. Execution Contract Database 1 owns it.
  Deleted: Invariant 10.3. Execution Contract Database 3 owns it.
  ```

---

## Examples

### SOX journal entry approval

A controller determines that posting JE-2026-0441 needs senior finance approval under SOX section 404 controls. `submit(subject_ref: "je-2026-0441", approver_ref: "finance_director_chen", submitter_ref: "controller_morgan", scope: "financial:journal-entry:post")` → `step-001`, standing in pending (Operation 7 through 9).

The finance director approves: `approve("step-001", decided_by: "finance_director_chen", reason: "Reviewed and approved — posting authorized")` → approved. The step stands in approved, carrying deciding actor, decision reason and decision instant (Operation 24, Operation 27, Operation 30).

An auditor later runs `read({subject_ref: "je-2026-0441", state: approved})` and sees who submitted, who approved, when, and why. The control evidence is provable from the record.

Or the director finds a misclassification: `reject("step-001", decided_by: "finance_director_chen", reason: "General ledger account 4120 is incorrect — should be 4130 per revenue recognition policy")` → rejected_outcome. The composing workflow routes the entry back, and the corrected entry needs a new [Submit] — this step is closed (Invariant 3.1, State 4).

Or the controller catches a routing error first: `withdraw("step-001", withdrawn_by: "controller_morgan", reason: "Wrong approver — cross-border entries route to tax_director")` → withdrawn, and `step-002` carries the right approver reference.

### Rejection paths

`approve("step-001", decided_by: "controller_morgan")` → unauthorized. The submitter is not the approver, and the step stays pending with nothing written (Operation 21, Operation 36).

`approve("step-001", decided_by: "finance_director_chen")` against the already-approved step → not-pending. Not unauthorized, even though the caller is the right actor — the step refuses every resolving call, and saying so sends the caller to the right problem (Operation 13, Operation 20).

`reject("step-002", decided_by: "tax_director", reason: "   ")` → invalid-request. A rejection with no stated reason is not an audit record (Operation 16, Invariant 6.3).

`approve("", decided_by: "finance_director_chen")` → invalid-request — a blank id is garbage, not a reference to a missing step (Operation 10, Execution Contract Refusal 1).

`approve("step-003", decided_by: "finance_director_chen", decided_at: "2020-01-01")` against a step submitted in 2026 → invalid-request. A decision cannot predate its submission (Operation 19).

`submit(subject_ref: "je-0442", approver_ref: "dir_chen", submitter_ref: "controller_morgan", scope: "   ")` → invalid-request (Operation 4).

`read({subject_ref: "je-2026-0441", approver_email: "chen@…"})` → invalid-query. The key stands outside the nine axes and is refused rather than ignored (Operation 44).

### Multiple gates on one subject

A cross-border entry needs both finance and tax sign-off. Two [Submit] calls produce `step-010` and `step-011` on the same subject reference, each with its own approver reference. Approving one leaves the other pending and untouched (Invariant 9.1). Whether the subject has any open gate is `read({subject_ref: X, state: pending})` — a non-empty answer means at least one gate is open. Whether *both* were required, and whether two approvals are enough, is [Multi-Party Approval](../compositions/multi-party-approval.md)'s (Non-goal 3).

### Regulated adversarial scenarios

- **Regulator audit.** A SOX section 404 examiner asks for evidence that the materiality control operated on a sample of entries. `read({scope: "financial:journal-entry:post", submitted_at: {start: …, end: …}})` answers the gates with full attribution, and Check 2.1 through 3.4 are what make each one usable. What the atom cannot answer is which entries *should* have had a gate and did not — that comparison needs the transaction set, which lives outside (Non-goal 18, External check 2).
- **Disputed approval.** A director denies approving an entry under an FDA Part 11 signature challenge. The record shows deciding actor equal to approver reference, byte for byte, with the instant and the reason. That proves the call carried their reference and proves nothing about who made the call — the cryptographic binding is [Actor Identity](./actor-identity.md)'s, and the atom says so rather than letting the record be read as a signature (Non-goal 14, External check 3).
- **Breach forensics.** An investigator examining unauthorized approval attempts finds that the database holds no record of them: a refused call writes nothing (Operation 36, Operation 37), so unauthorized attempts leave no trace here at all. The attempt log is the composing [Audit Trail](../compositions/audit-trail.md)'s, and these records' contribution is the negative evidence — every decision that *did* land, fully attributed (External check 4).

---

## Generation acceptance

This atom's acceptance is provable: an external auditor clears it from the step records.

### Conformance checks

```
Check 1.1: An auditor MUST find EVERY step standing in EXACTLY ONE OF pending, approved, rejected, withdrawn (Invariant 2.1).
Check 2.1: An auditor MUST find EVERY step's step id, subject reference, approver reference, submitter reference and scope non-blank (Invariant 8.1).
Check 2.2: An auditor MUST find a submission instant on EVERY step (Invariant 8.2).
Check 3.1: An auditor MUST find EVERY terminal step's attribution reference non-blank (Invariant 6.1).
Check 3.2: An auditor MUST find the terminal state's instant on EVERY terminal step (Invariant 6.2).
Check 3.3: An auditor MUST find EVERY rejected step's decision reason non-blank (Invariant 6.3).
Check 3.4: An auditor MUST find EVERY withdrawn step's withdrawal reason non-blank (Invariant 6.4).
Check 3.5: An auditor MUST find no terminal step's terminal instant preceding the step's submission instant (Invariant 7.1).
Check 4.1: An auditor MUST find EVERY approved step's deciding actor equal to the step's approver reference (Invariant 4.1).
Check 4.2: An auditor MUST find EVERY rejected step's deciding actor equal to the step's approver reference (Invariant 4.2).
Check 4.3: An auditor MUST find EVERY withdrawn step's withdrawing actor equal to the step's submitter reference (Invariant 5.1).
Check 5.1: An auditor MUST find no attribution field on a pending step (State 13).
Check 6.1: An auditor MUST find no step absent from a later unfiltered read (Invariant 10.1).
Check 6.2: An auditor MUST find a re-read step's submission fields unchanged from the prior read (Invariant 1.1).
Check 6.3: An auditor MUST find no step whose state EQUALS pending on a later read of a step a prior read found terminal (Invariant 3.1).
```

NOTE: EVERY check names the rule the check tests.

### External checks

```
Deleted: External check 1. Execution Contract Database 3 owns it.
External check 2: A deployment needing the subjects carrying no step identified MUST read the subject set beside the step records (Non-goal 19).
External check 3: A deployment needing a deciding actor bound to an actor MUST read the composing Actor Identity attestation (Non-goal 14).
External check 4: A deployment needing a refused call's attempt recorded MUST read the composing Audit Trail (Operation 37).
```

## Non-goals

```
Non-goal 1: The atom MUST NOT read two [Submit] calls carrying one field set as one step.
Non-goal 2: A deployment needing at-most-once submission MUST compose Duplicate Prevention.
Non-goal 3: The atom MUST NOT decide whether a subject's open gates are enough.
Non-goal 4: A deployment needing a quorum rule MUST compose Multi-Party Approval.
Non-goal 5: The atom MUST NOT bind a second actor to stand in for an approver reference.
Non-goal 6: A deployment needing delegation MUST compose a delegation pattern.
Non-goal 7: The atom MUST NOT confirm that a subject stands in an approvable state.
Non-goal 8: The atom MUST NOT interpret what an approved step permits.
Non-goal 9: The atom MUST NOT decide who may call an action.
Non-goal 10: A deployment needing an authorization decision MUST compose Permissions.
Non-goal 11: The atom MUST NOT notify an approver reference.
Non-goal 12: A deployment needing an approver notified MUST compose Notification.
Non-goal 13: The atom MUST NOT refuse a submitter reference matching the step's approver reference.
Non-goal 14: The atom MUST NOT bind a deciding actor to an actor.
Non-goal 15: A deployment needing a non-repudiable decision MUST compose Actor Identity.
Non-goal 16: The atom MUST NOT detect a rewrite under the database.
Non-goal 17: A deployment needing a rewrite detected MUST compose Tamper Evidence.
Non-goal 18: The atom MUST NOT declare which gates a subject requires.
Non-goal 19: The atom MUST NOT detect a subject carrying no step.
Non-goal 20: The atom MUST NOT bound submission instant from below.
Non-goal 21: A deployment needing a verifiable time anchor MUST compose a trusted timestamping pattern.
```

NOTE: the owners — [Duplicate Prevention](./duplicate-prevention.md) (Non-goal 1, Non-goal 2); [Multi-Party Approval](../compositions/multi-party-approval.md) (Non-goal 3, Non-goal 4; Non-goal 13, Composition note 3); a delegation pattern *(forthcoming)* (Non-goal 5, Non-goal 6); [Permissions](./permissions.md) (Non-goal 9, Non-goal 10; Non-goal 13, Composition note 3); [Notification](./notification.md) (Non-goal 11, Non-goal 12; Composition note 5); [Actor Identity](./actor-identity.md) (Non-goal 14, Non-goal 15); [Tamper Evidence](./tamper-evidence.md) (Non-goal 16, Non-goal 17; Non-goal 20); the composing pattern that owns the required gate mapping (Non-goal 18, Composition note 10); the deployment (Non-goal 19, External check 2); [Audit Trail](../compositions/audit-trail.md) (Non-goal 20); a Trusted Timestamping pattern *(forthcoming)* (Non-goal 21).

NOTE: open 2026-10-21-e — the owners NOTE names no owner for Non-goal 7 or Non-goal 8.

---

## Edge cases

### Atomic writes

```
Deleted: Atomic writes 1. Execution Contract Database 1 owns it.
Deleted: Atomic writes 2. Execution Contract Database 1 and Execution Contract Database 3 own it.
Deleted: Atomic writes 3. Execution Contract Database 1 owns it.
Deleted: Atomic writes 4. Execution Contract Database 1 owns it.
```

### Concurrency

```
Deleted: Concurrency 1. Execution Contract Database 2 owns it.
Deleted: Concurrency 2. Execution Contract Database 2 owns it.
Deleted: Concurrency 3. Execution Contract Database 2 owns it.
```

### Indeterminate outcome

```
Indeterminate outcome 1: A caller receiving no answer MUST NOT retry BEFORE the caller reads the step records (Execution Contract Error model 1).
Deleted: Indeterminate outcome 2. Execution Contract Error model 1 owns it.
Deleted: Indeterminate outcome 3. Execution Contract Error model 1 owns it.
```

NOTE: open 2026-10-21-d — a caller with no answer is sent to the step records, and no read says whether its submit landed, where two submits carrying one field set are two steps (Non-goal 1).

### String policy

```
String 1: The atom MUST compare a string input byte-exactly.
String 2: The atom MUST NOT trim a string input.
String 3: The atom MUST NOT normalize a string input.
String 4: The atom MUST NOT case-fold a string input.
String 5: The atom MUST read a whitespace-only string input as blank.
String 6: The atom MUST read an absent string input as blank.
String 7: The deployment MUST canonicalize an opaque reference.
```

Term string input: a reference, reason OR a filter's value — every caller-supplied string this atom accepts.

NOTE: open 2026-10-21-c — nothing names the answer to a supplied submission, decision or withdrawal instant that cannot be read as an instant (Operation 6, Operation 18, Operation 19), and Term string input leaves the instant inputs out.

NOTE: watch host obligations — this atom sets no maximum length on a string input, where [Duplicate Prevention](./duplicate-prevention.md) declares a cap and [Provenance](./provenance.md) obliges the deployment to set one. Three postures, and the *host obligations* docket row carries the count — a watch flag states the pressure, never a census nothing reads.

---

## Composition notes

```
Composition note 1: A deployment MUST declare which composing patterns the deployment wired in.
Composition note 2: A composing pattern MUST own the authorization of a call.
Composition note 3: A composing pattern MUST own the segregation policy over a submitter reference and an approver reference.
Composition note 4: A composing pattern MUST own the attestation binding a deciding actor.
Composition note 5: A composing pattern MUST own the notification of an approver reference.
Composition note 6: A composing pattern MUST own a quorum rule over two steps.
Composition note 7: A composing pattern MUST own the delegation of an approver reference.
Composition note 8: A composing pattern MUST own the tamper seal over the step records.
Composition note 9: A composing pattern MUST own at-most-once submission.
Composition note 10: A composing pattern MUST own the required gate mapping for a subject.
Composition note 11: A composing pattern reading the step records MUST NOT write to the step records.
```

NOTE: composing patterns — [Multi-Party Approval](../compositions/multi-party-approval.md), [Execute Gated Workflow](../compositions/execute-gated-workflow.md).

---

## Terms

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is* and its **Kind**.

### Vocabulary

Term actors: the atom; the host; the transition; the deployment; a composing pattern; a business caller; a caller; a guard; an auditor; a regulator; an examiner; an investigator; an actor; an approver; a submitter; the database; a step; a pending step; a terminal step; an approved step; a rejected step; a withdrawn step; a resolving action; a deciding action; a writing action; a refused action; an action; a query; a filter; a state filter; a range filter; a string input; an opaque reference; the database instance's step count; an attribution check.

Term records: step — one authorization gate, carrying step id, subject reference, approver reference, submitter reference, scope, submission instant, a state and, where supplied or set, reason, deciding actor, decision reason, decision instant, withdrawing actor, withdrawal reason and withdrawal instant.

Term record verbs: identify, allocate, change, carry, stand, answer, record, set, take, leave, own, match, equal, normalize, interpret, confirm, admit, offer, detect, route, share, precede, follow, exceed, compare, order, trim, case-fold, refuse, write, read, find, complete, fall, bound, decide, declare, compose, wire, supply, remove, sort, name, notify, bind, choose, canonicalize, retry, permit, evaluate.

Term value sets: state = pending | approved | rejected | withdrawn.

Term bounds: empty.

Term cadences: empty.

Term qualifiers: migrated — rewritten in GRACE lang v0.40 (2026-09-12).

Term terms: step, step id, subject reference, approver reference, submitter reference, scope, reference, database instance, seam, transition, now, business caller, states, terminal state, resolving action, deciding action, writing action, deciding reference, resolved decision instant, resolved submission instant, submission field, attribution field, attribution reference, attribution check, attribution fault, filter axes, string axes, query, admitted submit, authorization anchor, admitted resolve, admitted approve, admitted reject, admitted withdraw, admitted read, success token, string input, blank.

#### Approval Step

The record this atom defines: a single authorization gate binding a required approval to one named approver, for a specified subject and scope, with a lifecycle from submission through one terminal decision. It carries its [Step Id], [Subject Reference], [Approver Reference], [Submitter Reference], [Scope], [Submission Instant], [Reason], the [State] field, and the state-specific decision/withdrawal fields; the submission fields are immutable from creation. A fresh approval need is a new Approval Step, never a re-opened one.

Kind: Type

#### Submit

The behavior that records a new approval gate. It assigns a fresh [Step Id], records [Subject Reference], [Approver Reference], [Submitter Reference], [Scope], [Reason] (if supplied), and [Submission Instant], enters the step in [Pending], and returns the [Step Id] (or a rejection naming the failed precondition).

Kind: Operation

#### Approve

The resolving behavior the named approver invokes to record the affirmative decision and move a [Pending] step to [Approved]. Permitted only when [Deciding Actor] matches [Approver Reference]; it stamps [Deciding Actor], [Decision Reason] (optional for an approval), and [Decision Instant]. On an already-terminal step it is rejected [Not Pending]; from any other actor it is rejected [Unauthorized].

Kind: Operation

#### Reject

The resolving behavior the named approver invokes to record the negative decision and move a [Pending] step to [Rejected]. Requires a stated reason. Permitted only when [Deciding Actor] matches [Approver Reference]; it stamps [Deciding Actor], [Decision Reason], and [Decision Instant]. Its success token is rejected_outcome, distinct from the action's own rejection path. On an already-terminal step it is rejected [Not Pending]; from any other actor it is rejected [Unauthorized].

Kind: Operation

#### Withdraw

The resolving behavior the submitter invokes to retract a request and move a [Pending] step to [Withdrawn]. Requires a stated reason. Permitted only when [Withdrawing Actor] matches [Submitter Reference]; it stamps [Withdrawing Actor], [Withdrawal Reason], and [Withdrawal Instant]. On an already-terminal step it is rejected [Not Pending]; from any actor other than the submitter it is rejected [Unauthorized].

Kind: Operation

#### Read

The read-only behavior that returns the steps matching a [Query], ordered by [Submission Instant] ascending with [Step Id] as a lexicographic-byte-order tiebreaker. A well-formed [Query] matching no steps returns an empty sequence; a malformed one is rejected [Invalid Query]. It changes nothing.

Kind: Operation

#### Step Id

The opaque, immutable, system-generated identity of an approval step, assigned on [Submit], never reused or reassigned within the database instance. It must be a non-empty string sortable in lexicographic byte-order (for deterministic [Read] ordering). The subject, approver, scope, submitter, reason, and timestamps are properties of the step, not its identity.

Kind:       Field
Field of:   Approval Step
Projection: step_id

#### Subject Reference

The opaque reference to the thing being approved — a document, transaction, work item, or protocol-deviation id. Set on [Submit], immutable thereafter. The atom does not validate that the subject exists or is in any particular state; that is the caller's responsibility.

Kind:       Field
Field of:   Approval Step
Projection: subject_ref

#### Approver Reference

The opaque reference to the actor required to approve. Set on [Submit], immutable. It is the authorization anchor: only the actor whose reference matches it may [Approve] or [Reject] the step (Invariant 4). Delegation is a composing concept, not a property of this atom.

Kind:       Field
Field of:   Approval Step
Projection: approver_ref

#### Submitter Reference

The opaque reference to the actor submitting the approval request. Set on [Submit], immutable. It is the attribution anchor for the submission and the authorization anchor for [Withdraw]: only the actor whose reference matches it may withdraw the step (Invariant 5).

Kind:       Field
Field of:   Approval Step
Projection: submitter_ref

#### Scope

The non-empty string naming the kind of approval being requested (for example `"financial:journal-entry:post"`). Set on [Submit], immutable. The atom does not interpret scope semantics; it records the scope as an auditable field and uses it as an exact-match filter axis for [Read].

Kind:       Field
Field of:   Approval Step
Projection: scope

#### Reason

The optional submission-context string supplied at [Submit] — a description of what is being approved, the underlying business rule, or a summary of the deviation. Stored under its own name; immutable thereafter. Its absence is valid; if supplied it must not be blank. (Distinct from the [Decision Reason] and [Withdrawal Reason] fields the resolving actions write.)

Kind:       Field
Field of:   Approval Step
Projection: reason

#### Submission Instant

The timestamp at which the step was submitted, set on [Submit] (caller-supplied or wall-clock-defaulted; must not be in the future). Immutable. It is the lower bound the temporal-ordering invariant measures decision and withdrawal timestamps against (Invariant 7).

Kind:       Field
Field of:   Approval Step
Projection: submitted_at

#### State

The field holding the step's current state — one of [Pending], [Approved], [Rejected], or [Withdrawn]. Set to [Pending] on [Submit]; transitions once to a terminal via [Approve], [Reject], or [Withdraw], then never changes (Invariants 2 and 3).

Kind:       Field
Field of:   Approval Step
Projection: state

#### Deciding Actor

The opaque reference to the actor who decided, stamped on [Approve] or [Reject]. Present on [Approved] and [Rejected] steps; immutable once set. It must match [Approver Reference] for the decision to be accepted (Invariant 4) and must not be blank (Invariant 6).

Kind:       Field
Field of:   Approval Step
Projection: decided_by

#### Decision Reason

The stated reason recorded with a decision, stamped on [Approve] or [Reject]. Required on a [Rejected] step (Invariant 6); optional on an [Approved] step, and refused [Invalid Request] when supplied blank (Operation 57). Present on [Approved] and [Rejected] steps only; immutable once set.

Kind:       Field
Field of:   Approval Step
Projection: decision_reason

#### Decision Instant

The timestamp at which the decision was recorded, stamped on [Approve] or [Reject] (caller-supplied or wall-clock-defaulted; must not be in the future). Present on [Approved] and [Rejected] steps; immutable once set. [Decision Instant] ≥ [Submission Instant] always holds (Invariant 7).

Kind:       Field
Field of:   Approval Step
Projection: decided_at

#### Withdrawing Actor

The opaque reference to the actor who withdrew the request, stamped on [Withdraw]. Present on [Withdrawn] steps; immutable once set. It must match [Submitter Reference] for the withdrawal to be accepted (Invariant 5) and must not be blank (Invariant 6).

Kind:       Field
Field of:   Approval Step
Projection: withdrawn_by

#### Withdrawal Reason

The stated reason recorded with a withdrawal, stamped on [Withdraw]. Required (Invariant 6). Present on [Withdrawn] steps only; immutable once set.

Kind:       Field
Field of:   Approval Step
Projection: withdrawal_reason

#### Withdrawal Instant

The timestamp at which the withdrawal was recorded, stamped on [Withdraw] (caller-supplied or wall-clock-defaulted; must not be in the future). Present on [Withdrawn] steps; immutable once set. [Withdrawal Instant] ≥ [Submission Instant] always holds (Invariant 7).

Kind:       Field
Field of:   Approval Step
Projection: withdrawn_at

#### Query

The selection a caller passes to [Read] to scope which steps are returned — any combination of the supported filter axes ([Step Id], [Subject Reference], [Approver Reference], [Submitter Reference], [Scope], [State], and a time range on [Submission Instant], [Decision Instant] or [Withdrawal Instant]). A time range carries a start and an end, and an instant at either end lies inside it; a step carrying no instant on a range's field matches no range on it. Consumed per call; never stored.

Kind:         Parameter
Parameter of: Read
Projection:   query

#### Pending

The single non-terminal state: the approval gate is open and no terminal decision has been made. The lifecycle proceeds [Pending] → one of {[Approved], [Rejected], [Withdrawn]}. It is also the state filter value queried for outstanding gates on a subject.

Kind:       Member
Member of:  the step state
Role:       Outcome
Projection: pending

#### Approved

The terminal state a step reaches when the named approver affirmatively decided within [Approve]. Carries all submission fields plus [Deciding Actor], [Decision Reason] (if supplied), and [Decision Instant]. Absorbing: no action transitions it elsewhere. It is also the [Approve] success token and a state filter value.

Kind:       Member
Member of:  the step state
Role:       Outcome
Projection: approved

#### Rejected

The terminal state a step reaches when the named approver negatively decided within [Reject]. Carries all submission fields plus [Deciding Actor], [Decision Reason] (required), and [Decision Instant]. Absorbing. As a state filter value its wire form is rejected; the [Reject] success token is the distinct rejected_outcome, kept verbatim in the projected contract.

Kind:       Member
Member of:  the step state
Role:       Outcome
Projection: rejected

#### Withdrawn

The terminal state a step reaches when the submitter retracted the request within [Withdraw]. Carries all submission fields plus [Withdrawing Actor], [Withdrawal Reason], and [Withdrawal Instant]. Absorbing. It is also the [Withdraw] success token and a state filter value.

Kind:       Member
Member of:  the step state
Role:       Outcome
Projection: withdrawn

#### Invalid Request

The rejection a write action ([Submit], [Approve], [Reject], [Withdraw]) returns when an input is malformed — a blank required field, the [Step Id] among them, a missing-reason [Reject]/[Withdraw], a blank reason supplied to [Submit] or [Approve], a future or backdated-before-[Submission Instant] timestamp. A guard rejection that writes nothing.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-request

#### Not Known

The rejection a resolving action ([Approve], [Reject], [Withdraw]) returns when the supplied [Step Id] is not blank but references no step in the database. Checked after the blank-[Step Id] guard and before the state check.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: not-known

#### Not Pending

The rejection a resolving action returns when the referenced step is already terminal — [Approved], [Rejected], or [Withdrawn]. It is the structural expression of terminal absorption (Invariant 3): no further transition is admitted.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: not-pending

#### Unauthorized

The rejection a resolving action returns when the deciding actor is not the authorized one — [Deciding Actor] not matching [Approver Reference] on [Approve]/[Reject], or [Withdrawing Actor] not matching [Submitter Reference] on [Withdraw]. The record is left [Pending] and nothing is written (Invariants 4 and 5).

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: unauthorized

#### Storage Failure

The rejection any write action returns when the underlying database write fails after all preconditions pass. No [Step Id] is issued on [Submit]; a resolving action leaves the step in [Pending]. The caller must retry.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: storage-failure

#### Invalid Query

The rejection [Read] returns when a filter is malformed — a blank string-axis value, a [State] value outside the four states, a time range missing its start or its end, with end before start or with an end that is not an instant, a value its field does not take (a time range on a field that is not an instant, or a single value on one that is), or an unrecognized filter key (rejected rather than silently ignored).

Kind:       Member
Member of:  the Read rejection
Role:       Outcome
Projection: invalid-query

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a [Term] marker to its term entry heading above (kramdown
     auto-generates the heading anchors on GitHub Pages). Standard CommonMark /
     kramdown; no plugin required. -->

[Approval Step]: #approval-step
[Submit]: #submit
[Approve]: #approve
[Reject]: #reject
[Withdraw]: #withdraw
[Read]: #read
[Step Id]: #step-id
[Subject Reference]: #subject-reference
[Approver Reference]: #approver-reference
[Submitter Reference]: #submitter-reference
[Scope]: #scope
[Reason]: #reason
[Submission Instant]: #submission-instant
[State]: #state
[Deciding Actor]: #deciding-actor
[Decision Reason]: #decision-reason
[Decision Instant]: #decision-instant
[Withdrawing Actor]: #withdrawing-actor
[Withdrawal Reason]: #withdrawal-reason
[Withdrawal Instant]: #withdrawal-instant
[Query]: #query
[Pending]: #pending
[Approved]: #approved
[Rejected]: #rejected
[Withdrawn]: #withdrawn
[Invalid Request]: #invalid-request
[Not Known]: #not-known
[Not Pending]: #not-pending
[Unauthorized]: #unauthorized
[Storage Failure]: #storage-failure
[Invalid Query]: #invalid-query

---

## Standards references

- **Sarbanes-Oxley section 404 (17 U.S.C. section 7262)** — internal control over financial reporting. The approval step is the structural form of a financial reporting control: a gate that must be cleared before a material action proceeds, with an auditable record of who cleared it. SOX auditors reviewing control evidence query approval step records directly; Invariants 4, 6, and 8 are the structural guarantees the evidence must carry.
- **FDA 21 CFR Part 11 (Electronic Records; Electronic Signatures)** — for FDA-regulated contexts (pharmaceutical manufacturing, clinical trials, medical device quality systems): each approval step by a named actor is the record an electronic signature on the action is linked to. Part 11 section 11.50 requires that electronic signatures are attributable to one individual and section 11.70 requires that they are linked to their respective records to prevent removal, substitution, or falsification. Composition with [Actor Identity](./actor-identity.md) provides the cryptographic binding; composition with [Tamper Evidence](./tamper-evidence.md) provides the linking and non-falsifiability. The Approval Step record is the gate; the composition is the compliant electronic signature system.
- **ICH (International Council for Harmonisation of Technical Requirements for Pharmaceuticals for Human Use) E6(R3) Good Clinical Practice — Guideline** — the international standard for clinical trial conduct. Section 4 (Investigator's Responsibilities) and Section 5 (Sponsor's Responsibilities) require documented approval steps at multiple points in the trial lifecycle: investigator approval of protocol deviations, IRB (Institutional Review Board) approval of informed consent amendments, sponsor approval of site qualification assessments. Each maps to an Approval Step record whose [Scope] identifies the specific GCP obligation.
- **ISO 9001:2015 clause 8.5.1 (Control of production and service provision)** — the International Organization for Standardization's quality-management standard; requires that production and service provision activities be controlled by documented procedures including approval of documents, products, and services at defined points. Approval steps are the documented approval records section 8.5.1 anticipates; the atom's immutability invariants satisfy the document control requirements.
- **ISO 13485:2016 clause 4.2 (Documentation requirements)** — for medical device manufacturers: records of approval activities must be maintained. Approval Step records are the compliant implementation surface.

---

## Status

`partially resolved` — see the Ledger.

## Ledger

```
status: partially resolved
formal: verified — approval-step.tla + 1 twin, 2026-06-03
last gate: 2026-10-26 — Final Critique 7 — foundational count 4, not clean, no sample

open:
- 2026-10-21-c · refining · Operation 6; Operation 18; Operation 19; Term string input · nothing names the answer to a supplied submission, decision or withdrawal instant that cannot be read as an instant, and Term string input leaves the instant inputs out → a rule answering it invalid-request, or the binding named as its owner
- 2026-10-21-d · refining · Indeterminate outcome 1 · a caller with no answer is sent to the step records, and no read says whether its submit landed, where two submits carrying one field set are two steps (Non-goal 1); its BEFORE takes a clause where the grammar's tail takes a term → name the read, or Duplicate Prevention (Non-goal 2) as its owner, and write the tail on a term
- 2026-10-21-e · refining · Non-goals NOTE · the owners NOTE gives no owner for Non-goal 7 or Non-goal 8 → one owner each, linked or marked forthcoming
- 2026-10-26-a · refining · Identity 2; Capability requirement 1, 5 · the step id's source is named as the host's allocation (Identity 2) and not among what the deployment supplies, where the atom shape in `spec-format.md` lists an id source under Capability requirement; Assignment (its 2026-10-26-a), Event Log (its 2026-10-22-b) and Tamper Evidence (its 2026-10-22-a) route the same form → name the source among the Capability requirements, in the one form the corpus settles for its twenty host-allocation atoms
- 2026-10-26-b · refining · Term seam; Term transition; Term business caller; Term now · each says the section titled Logic Confinement Principle in `execution-contract.md` declares it, and that section declares none of the four → declare the four there, the corpus's one seam wording, or point each at its declaration
```

## Decisions

Directional changes only — the turns a future reader must know the pattern took, and why. Everything smaller lives in the commit that made it: `git log -- atoms/approval-step.md`; the migration and the repairs that got it here are in [its history](./approval-step.hist.md).

- **2026-10-21 — Which refusal answers is the Execution Contract's.** *Chose:* the resolving actions' refuses line kept as the page wrote it — invalid-request, not-known, not-pending, unauthorized, then storage-failure, which answers only at the write — and the order cited from the Execution Contract (Capability requirement 5, Execution Contract Refusal 1); the rules that only stated it deleted to Refusal 1: Operation 55, which evaluated the resolve refusal order, with Term resolve refusal order, and the pairs Operation 12 (a blank step id ahead of not-known), Operation 14 (not-known ahead of not-pending), Operation 23 (an attribution fault ahead of unauthorized) and Operation 35 (storage-failure behind every precondition); rules 154 to 149. Operation 20 stays the page's own: invalid-request answers a blank step id ahead of not-known and an attribution fault only on a pending step, after not-known and not-pending, so it holds two places in the order and no fixed line can carry both; Refusal 1 reads a refusal Operation 20 keeps from a call as not applying to it. *Over:* the page stating for itself which of a resolving action's refusals answers when several apply. *Because:* the maintainer ruled on 2026-10-21 that the Execution Contract states once that the refusal listed first on an action's refuses line answers; this page's sixth Final Critique had made the cure one specification at a time. What each action answers on every call is unchanged.

- **2026-10-21 — A failed read answers as the Execution Contract says.** *Chose:* the failed read cited from the Execution Contract (Capability requirement 5, Execution Contract Read 1 through 3) and the three rules that restated it deleted to Read 1: the atom-wide state-unavailable (Operation 53), and the submit and read refusal orders (Operation 54, Operation 56), whose rules after the read answer one code each, invalid-request and invalid-query; the read's condition off the admitted submit, resolve and read it held to an answered read, the read off the resolve refusal order and its table, Term database read deleted, and state-unavailable off every signature and the examples; rules 157 to 154. *Over:* the page stating for itself what every action answers when the step records cannot be read. *Because:* the maintainer ruled on 2026-10-21 that the Execution Contract states the failed read once; this page's sixth Final Critique had made one of the cures the contract's Read family is written from, and the read first in every order, which it gave as the pipeline's, is Read 1's. What each action answers on an answered read is unchanged.

- **2026-10-21 — A failed read answers on every action; each action's refusals answer in one stated order; a deleted subject answers as a live one.** *Chose:* state-unavailable on all five actions where the read of the step records fails, the Execution Contract's Step 1 failure (Operation 53, Term database read), the admitted submit, resolve and read each held to an answered read; one refusal order for [Submit], one for the three resolving actions and one for [Read], the read first since Step 1 runs before any guard, and the resolving actions' in the order the case table and Final Critique 5's fixed priority gave — blank step id, not-known, not-pending, the attribution checks, the actor guard (Operation 54 through 56) — with Operation 12, 14, 20 and 23 kept as the order's own pairs; and the Execution Contract's dangling-reference sentence rewritten, so a deleted subject produces no refusal of this atom's, which never consults it (Identity 12). *Over:* a failed read answered by no code the page names, which one build surfaced as a fault, one as invalid-query and one as an empty answer an auditor reads as no steps; pairwise ONLY IF rules that, each read alone, forbid what the rule they order obliges; and a guard failure the contract obliged and the atom forbids. *Because:* Final Critique 6 found each a divergence between conforming builds, or two rules no build can both obey, and the corpus already held each cure: Actor Identity's fifth round answered the failed read on every action, Verified Repair's ruling of 2026-10-19 gave each action one stated order, and the contract's own paragraph says this atom owns a decision about a reference, never the referenced thing. A blank step id is now refused after the Step 1 read, not before any lookup, since the pipeline reads first. What the atom answers a well-formed call on a readable database is unchanged.

- **2026-10-19 — The store's guarantees cited, not restated.** *Chose:* the step store supplied under Execution Contract Store 1 through 4 (Capability requirement 5), and the eleven rules that restated them, or stood in for them, tombstoned to their owner — Operation 31, a resolve's state change and recorded fields committed in one operation, Invariant 10.2, no partial record left by a storage-failure, and Atomic writes 1, 3 and 4, no reader seeing a terminal state without its attribution fields, a dangling transition resolved and no read served before it is, to Store 1; Atomic writes 2, an uncommitted crash leaving the step as the call found it, to Store 1 and Store 3; Invariant 10.3, an answered step id naming a durably persisted step, and External check 1, the submit answers captured to find a step the store is missing, to Store 3; Concurrency 1 through 3, two resolving actions on one step serialized, the later reading what the earlier left and answering not-pending, to Store 2; rules 163 to 153. *Over:* the atom restating, for its own store, what every deployment's store guarantees, and a deployment journalling its submit answers against a store that might lose a step. *Because:* the maintainer ruled 2026-10-12 that the corpus takes a store's specification, never the store, and `execution-contract.md` writes it once as the Store contract. The atom's own no-removal rules stay (State 5, State 14, Invariant 10.1), since Store 4 alone does not keep the atom from removing a step; Check 6.1 through 6.3 rest on the auditor's own two reads, and [Read] orders by submission instant and step id, so the atom cites neither History 1 nor Order 1. What the atom does for its domain is unchanged.

NOTE: End of Approval Step.
