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

A step has four states: pending, plus three terminal ones — approved, rejected (with a required reason), and withdrawn. All three are absorbing; there is no re-open and no decision reversal.

The core guarantee is that every decision is fully attributed. An anonymous decision, a rejection with no reason, or a missing timestamp is a failure. So the record alone proves a required control existed and operated, which is exactly what an auditor or investigator asks for.

This is distinct from a permission (standing, reusable authority to do a class of things) and from an assignment (who owns a task, not who approved it). A controller may be *permitted* to approve journal entries, and each entry still needs an Approval Step proving they *did* approve that one. Delegation is a composing concept, not a property of this atom.

*Also known as: an approval gate, a sign-off, an authorization step, a review gate.*

---

## Intent

WHY:
Many actions in regulated systems require explicit human authorization before they may proceed. A journal entry above a materiality threshold needs a controller's approval before it posts. A clinical-trial protocol deviation needs the principal investigator's approval before the deviant procedure happens. A pharmaceutical batch release needs a qualified person under 21 CFR (Code of Federal Regulations) Part 211. An engineering change order needs a release chain. The structure is identical every time: something is submitted, a named actor reviews it, and the outcome is an auditable record that external evaluators rely on as evidence the required control existed and operated.

This atom is that structure and nothing else. It records the gate, who the gate was for, the outcome, the actor who decided, and when — and it guarantees those records are present and immutable. Cryptographic protection against post-hoc modification, the bar for court-admissible evidence under SOX (Sarbanes-Oxley Act) §404 and FDA (US Food and Drug Administration) Part 11, is [Tamper Evidence](./tamper-evidence.md)'s and is not provided here.

Three adjacent concepts are distinguished, and every distinction is load-bearing.

[Permissions](./permissions.md) governs *standing* authorization — a persistent grant, checked at every relevant invocation, live until revoked. This atom governs *transient decision* authorization — a one-time gate on one subject that produces a terminal outcome and closes. Permissions answers *may this actor generally do things of this kind?* This atom answers *has this specific thing been approved by the specifically named actor for this specific scope?* A controller with permission to approve journal entries still needs a step record per entry: the grant says they are allowed, the step says they did. Both are present in a conforming SOX deployment and neither replaces the other.

[Assignment](./assignment.md) governs *responsibility binding* — who owns the work, with a lifecycle of its own. This atom governs the decision. A document may be assigned to an author and simultaneously submitted to a reviewer; the two coexist without overlapping. Confusing them produces either a spec that cannot record the approval or one that loses track of who owns the work.

[State Machine](./state-machine.md) is the general engine: states and transitions declared by the deployment, opaque to the atom. This atom is a *specific* state machine whose four states, four transitions and approval semantics are fixed here — one named approver, a decision that is itself a compliance record, a required reason on rejection. The axis is specificity: an external evaluator knows this atom's states from the spec and must read a State Machine instance's declaration to know that one's. The two are the fixed and declared poles of the same category, and they compose into [Execute Gated Workflow](../compositions/execute-gated-workflow.md).

## Structure

### Identity model

```
Identity 1: The atom MUST identify a step by the step_id.
Identity 2: The host MUST allocate a step_id at the seam.
Identity 3: The transition MUST NOT allocate a step_id.
Identity 4: The atom MUST NOT change a step_id.
Identity 5: Two steps in one store instance MUST NOT share a step_id.
Identity 6: The deployment MUST choose a step_id format that sorts in lexicographic byte order.
Identity 7: The deployment MUST route EVERY call to one store instance.
Identity 8: The atom MUST NOT identify a step by the subject_ref.
Identity 9: The atom MUST admit a second step carrying a recorded subject_ref.
Identity 10: The atom MUST compare a reference byte-exactly.
Identity 11: The atom MUST NOT normalize a reference.
Identity 12: The atom MUST NOT confirm that a subject_ref names a known subject.
Identity 13: The atom MUST NOT interpret a scope.
Identity 14: The deployment MUST supply a reference in one canonical byte form.
```

Term step: one authorization gate — one subject, one approver, one submitter, one scope and one outcome; the record this atom holds.

Term step_id: the opaque value naming one step — a [Step Id]; host-allocated at the seam.

Term subject_ref: the opaque reference naming the thing being approved — a [Subject Ref]; a property of the step, never the step's identity.

Term approver_ref: the opaque reference naming the actor required to approve — an [Approver Ref]; the authorization anchor.

Term submitter_ref: the opaque reference naming the actor requesting approval — a [Submitter Ref]; the attribution anchor for the submission.

Term scope: the string naming the kind of approval requested — a [Scope]; recorded and filtered on, never interpreted.

Term reference: subject_ref, approver_ref, submitter_ref, decided_by, withdrawn_by OR scope — every string this atom compares for equality.

Term store instance: one named step store a call is routed to; step_id uniqueness ranges over one instance.

Term seam: the atom's I/O boundary as `execution-contract.md` §Logic confinement declares it; the host injects the clock reading and the step_id here.

Term transition: the atom's evaluation of one call against the step store, as `execution-contract.md` §Logic confinement declares it.

WHY:
Identity 10 is the rule the exclusivity invariants rest on. decided_by against approver_ref (Invariant 4) and withdrawn_by against submitter_ref (Invariant 5) are exact byte-sequence comparisons on the values as supplied — no Unicode normalization, no case folding, no trimming. Two references that render identically and differ in bytes are different actors to this atom, and a precomposed accented character will not match its decomposed twin. That is unforgiving, and it is the only comparison an exclusivity guard can safely make: a normalizing comparison would let the atom decide that two spellings name one actor, which is an identity judgment this atom has no standing to make. Canonicalization is the deployment's (Identity 14).

### State

```
State 1: A step MUST NOT leave a terminal state.
State 2: The atom MUST NOT offer a re-open surface.
State 3: The atom MUST NOT offer a decision reversal surface.
State 4: The atom MUST NOT offer a re-submission surface on a recorded step.
State 5: The atom MUST NOT offer a removal surface.
State 6: The atom MUST NOT offer a delegation surface.
State 7: EVERY step MUST carry step_id, subject_ref, approver_ref, submitter_ref, scope, submitted_at and a state.
State 8: A step MAY carry reason.
State 9: EVERY approved step MUST carry decided_by and decided_at.
State 10: EVERY rejected step MUST carry decided_by, decision_reason and decided_at.
State 11: EVERY withdrawn step MUST carry withdrawn_by, withdrawal_reason and withdrawn_at.
State 12: An approved step MAY carry decision_reason.
State 13: A pending step MUST NOT carry an attribution field.
State 14: The store instance's step count MUST NOT fall.
State 15: The atom MUST NOT record a receipt instant.
```

WHY:
State 4 is the one deployments push against. A pending [Approval Step] cannot be revised into a new version; a changed approval need is a new [Submit] producing a new step_id, and the original is withdrawn or decided on its own terms. Revision in place would make the record answer *what is being approved now* when the question an auditor asks is *what was presented to the approver, and what did they decide about it*.

State 15 names what makes back-insertion undetectable here. The atom stores the declared instants and no separate creation instant, so a step written today with submitted_at a year back reads as a year-old gate. The composing [Audit Trail](../compositions/audit-trail.md) entry carries the receipt instant, and that comparison is where back-insertion surfaces.

### Capability requirement

```
Capability requirement 1: The deployment MUST supply now at the seam.
Capability requirement 2: The deployment MUST own the clock's monotonicity.
Capability requirement 3: The deployment MUST own the clock's honesty.
Capability requirement 4: The deployment MUST own the clock's synchronization.
Deleted: Clock semantics 1. Capability requirement 2 owns it.
Deleted: Clock semantics 2. Capability requirement 3 owns it.
Deleted: Clock semantics 3. Capability requirement 4 owns it.
Deleted: Clock semantics 4. State 15 owns it.
Deleted: Clock semantics 5. Non-goal 21 owns it.
```

WHY:
What the deployment supplies, which is what the family means. The rule stood under `Operation` — one action's rules — while naming no action, because this spec was migrated before the standard family had a home in an atom; the five atoms migrated a day later put the same obligation here. The words are the words the rule carried (council read 76).

WHY:
Clock skew between a caller and the seam can push a decided_at the caller believes is current past the injected reading, and Operation 18 rejects it. That is the correct rejection: the bound is enforced against the injected now, not against the caller's belief about the time.

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
Operation 1: IF subject_ref EQUALS blank THEN [Submit] MUST answer invalid-request.
Operation 2: IF approver_ref EQUALS blank THEN [Submit] MUST answer invalid-request.
Operation 3: IF submitter_ref EQUALS blank THEN [Submit] MUST answer invalid-request.
Operation 4: IF scope EQUALS blank THEN [Submit] MUST answer invalid-request.
Operation 5: IF a supplied reason EQUALS blank THEN [Submit] MUST answer invalid-request.
Operation 6: IF the resolved submitted_at EXCEEDS now THEN [Submit] MUST answer invalid-request.
Operation 7: An admitted submit MUST record EXACTLY ONE step.
Operation 8: An admitted submit MUST stand the step in pending.
Operation 9: An admitted submit MUST answer the step_id.
Operation 10: IF step_id EQUALS blank THEN a resolving action MUST answer invalid-request.
Operation 11: IF the step_id names no step THEN a resolving action MUST answer not-known.
Operation 12: A resolving action MUST answer not-known ONLY IF step_id DOES NOT EQUAL blank.
Operation 13: IF the step's state IS IN the terminal states THEN a resolving action MUST answer not-pending.
Operation 14: A resolving action MUST answer not-pending ONLY IF the step_id names a step.
Operation 15: IF the deciding reference EQUALS blank THEN a resolving action MUST answer invalid-request.
Operation 16: IF reason EQUALS blank THEN [Reject] MUST answer invalid-request.
Operation 17: IF reason EQUALS blank THEN [Withdraw] MUST answer invalid-request.
Operation 18: IF the resolved decision instant EXCEEDS now THEN a resolving action MUST answer invalid-request.
Operation 19: IF the resolved decision instant precedes the step's submitted_at THEN a resolving action MUST answer invalid-request.
Operation 20: A resolving action MUST answer invalid-request on an attribution fault ONLY IF the step's state EQUALS pending.
Operation 21: IF decided_by DOES NOT EQUAL approver_ref THEN a deciding action MUST answer unauthorized.
Operation 22: IF withdrawn_by DOES NOT EQUAL submitter_ref THEN [Withdraw] MUST answer unauthorized.
Operation 23: A resolving action MUST answer unauthorized ONLY IF EVERY attribution check passes.
Operation 24: An admitted approve MUST stand the step in approved.
Operation 25: An admitted reject MUST stand the step in rejected.
Operation 26: An admitted withdraw MUST stand the step in withdrawn.
Operation 27: An admitted approve MUST record decided_by and the resolved decision instant as decided_at.
Operation 28: An admitted reject MUST record decided_by, reason as decision_reason and the resolved decision instant as decided_at.
Operation 29: An admitted withdraw MUST record withdrawn_by, reason as withdrawal_reason and the resolved decision instant as withdrawn_at.
Operation 30: An admitted approve MUST record a supplied reason as decision_reason.
Operation 31: An admitted resolve MUST commit the state change and the recorded fields in one operation.
Operation 32: An admitted resolve MUST answer the action's success token.
Operation 33: A resolving action MUST NOT change a submission field.
Operation 34: IF the store refuses the write THEN a writing action MUST answer storage-failure.
Operation 35: An action MUST answer storage-failure ONLY IF EVERY precondition passes.
Operation 36: A refused action MUST leave the step as the call found the step.
Operation 37: A refused action MUST NOT record an attribution field.
Operation 38: An admitted read MUST answer the matching steps in submitted_at ascending order.
Operation 39: An admitted read MUST order two steps sharing a submitted_at by step_id ascending.
Operation 40: An admitted read MUST answer EVERY step matching the supplied filters.
Operation 41: An admitted read MUST NOT answer a step failing a supplied filter.
Operation 42: IF no step matches THEN an admitted read MUST answer an empty step sequence.
Operation 43: An admitted read MUST match an instant-range filter against ONLY the steps carrying the filter's field.
Operation 44: IF a filter's axis IS NOT IN the filter axes THEN [Read] MUST answer invalid-query.
Operation 45: IF a reference filter's value EQUALS blank THEN [Read] MUST answer invalid-query.
Operation 46: IF a state filter's value IS NOT IN the states THEN [Read] MUST answer invalid-query.
Operation 47: IF a range filter's end precedes the range's start THEN [Read] MUST answer invalid-query.
Operation 48: [Read] MUST NOT write.
Deleted: Operation 49. Capability requirement 1 owns it.
Deleted: Operation 50. `execution-contract.md` §Logic confinement owns it.
Deleted: Operation 51. `execution-contract.md` §Logic confinement owns it.
Deleted: Operation 52. `execution-contract.md` §Logic confinement owns it.
```

Term now: the wall-time reading the host takes at the seam and hands to the transition, as `execution-contract.md` §Logic confinement declares it; never read inside the transition, never supplied by the business caller.

Term business caller: the party whose action the call carries, as `execution-contract.md` §Logic confinement declares it; never the source of an injected value.

Term states: pending | approved | rejected | withdrawn — a [State], and the whole state space.

Term terminal state: approved | rejected OR withdrawn — the three absorbing members of states.

Term resolving action: [Approve] | [Reject] | [Withdraw] — the three actions that close a pending step.

Term deciding action: [Approve] | [Reject] — the two a guard on approver_ref covers.

Term writing action: [Submit] | [Approve] | [Reject] | [Withdraw] — every action but [Read].

Term deciding reference: decided_by on a deciding action, and withdrawn_by on [Withdraw] — the actor reference a resolving action carries.

Term decision instant: decided_at on a deciding action, and withdrawn_at on [Withdraw] — the instant a resolving action records.

Term resolved decision instant: the decision instant the step carries — the supplied value where one exists, and now otherwise.

Term resolved submitted_at: the submitted_at the step carries — the supplied value where one exists, and now otherwise.

Term submission field: step_id, subject_ref, approver_ref, submitter_ref, scope, submitted_at OR reason — every field [Submit] sets.

Term attribution field: decided_by, decision_reason, decided_at, withdrawn_by, withdrawal_reason OR withdrawn_at — every field a resolving action sets.

Term attribution check: Operation 15 through 19 — every check a resolving action makes before the actor guard.

Term filter axes: step_id | subject_ref | approver_ref | submitter_ref | scope | state | submitted_at | decided_at | withdrawn_at — the nine axes [Read] accepts, and no others.

Term admitted submit: a [Submit] call whose references, scope, supplied reason and resolved submitted_at the guards all admit.

Term admitted resolve: a resolving action whose step_id names a pending step and whose reason, deciding reference and resolved decision instant the guards admit, and whose deciding reference matches the step's anchor.

Term admitted approve: an admitted resolve on [Approve].

Term admitted reject: an admitted resolve on [Reject].

Term admitted withdraw: an admitted resolve on [Withdraw].

Term admitted read: a [Read] call whose every filter axis and filter value the guards admit.

| # | Condition | a resolving action answers |
|---|---|---|
| 1 | step_id is blank | invalid-request |
| 2 | step_id is well-formed, it names no step | not-known |
| 3 | the step exists, it stands in a terminal state | not-pending |
| 4 | the step stands in pending, an attribution check fails | invalid-request |
| 5 | every attribution check passes, the deciding reference is not the anchor | unauthorized |
| 6 | every precondition passes, the store refuses the write | storage-failure |
| 7 | every precondition passes, the store accepts the write | the success token |

NOTE: watch condition negation — invalid-request occupies rows 1 and 4 of one precedence chain, so the answer alone does not say which guard refused. [State Machine](./state-machine.md) and [Audit Trail](../compositions/audit-trail.md) carry the same shape.

WHY:
Row 1 precedes the store lookup because a blank step_id is garbage, not a reference to a missing step, and answering [Not Known] would tell the caller their id was valid and unmatched. Row 3 precedes row 4 because a terminal step refuses every resolving call, and a caller told [Invalid Request] about their timestamp on an already-decided step is fixing nothing. Row 5 sits last among the guards deliberately: telling an unauthorized caller *unauthorized* is itself a disclosure — it confirms the step exists, is pending, and that their attribution was otherwise well-formed — so every cheaper refusal is spent first.

Operation 19 states the within-step temporal bound as a precedence rather than as a comparison, so no rule here spells `≥` as a two-arm disjunction. A decision recorded *at* the instant of submission is legal, and `precedes` admits it in one arm.

Operation 43 is the filter rule an auditor has to understand before trusting a result set: an instant-range filter on decided_at answers only steps carrying a decided_at, so pending and withdrawn steps are excluded whether or not a state filter says so. The alternative — treating an absent field as unmatched-but-present — would make *every step decided in March* silently include steps that were never decided at all.

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
  WHY: all three terminals absorb, and the atom carries no re-open, re-activate or reversal surface (State 2, State 3). A decision made in error is answered by a new [Submit] naming the relationship to the original, which produces a more complete record than a reversal: an auditor sees the first decision and the correction, in order, rather than a record that no longer says what happened.
- **Invariant 4 — Approver exclusivity.**
  ```
  Invariant 4.1: An approved step's decided_by MUST equal the step's approver_ref.
  Invariant 4.2: A rejected step's decided_by MUST equal the step's approver_ref.
  ```
  WHY: there is no fallback approver, no escalation and no *any authorized actor* surface. Delegation — binding a different actor to stand in for the named approver — is a composing pattern's, and it works either by producing a step whose approver_ref names the delegate or by gating the call before it reaches this surface (Non-goal 5, Non-goal 6).
- **Invariant 5 — Submitter exclusivity.**
  ```
  Invariant 5.1: A withdrawn step's withdrawn_by MUST equal the step's submitter_ref.
  ```
- **Invariant 6 — Decision attribution completeness.**
  ```
  Invariant 6.1: EVERY terminal step's attribution reference MUST stand non-blank.
  Invariant 6.2: EVERY terminal step MUST carry the terminal state's instant.
  Invariant 6.3: EVERY rejected step's decision_reason MUST stand non-blank.
  Invariant 6.4: EVERY withdrawn step's withdrawal_reason MUST stand non-blank.
  ```
  WHY: the load-bearing one. An anonymous decision, a whitespace-only attribution, a missing instant or a rejection with no stated reason each defeat the audit trail SOX §404 control evidence and FDA Part 11 electronic-signature requirements rest on. A rejection in particular is not operationally meaningful without its reason — the record would show that something was refused and leave the submitter, and a later auditor, with no account of why.
- **Invariant 7 — Temporal ordering.**
  ```
  Invariant 7.1: A terminal step's terminal instant MUST NOT precede the step's submitted_at.
  ```
  WHY: a step cannot be documented as decided or withdrawn before it was submitted. The bound holds on the value persisted, whether caller-supplied or resolved to now, and is enforced before the transition commits (Operation 19).
- **Invariant 8 — Submission attribution completeness.**
  ```
  Invariant 8.1: EVERY step's step_id, subject_ref, approver_ref, submitter_ref and scope MUST stand non-blank.
  Invariant 8.2: EVERY step MUST carry a submitted_at.
  ```
- **Invariant 9 — Concurrent step independence.**
  ```
  Invariant 9.1: A resolving action on one step MUST NOT change a second step's field.
  ```
  WHY: independence is universal rather than scoped to a shared subject, though the shared-subject case is the operationally interesting one — a subject with two open gates needs two decisions, and whether a subject has any open gate is a subject_ref and pending query rather than a field on the subject.
- **Invariant 10 — Store durability.**
  ```
  Invariant 10.1: The atom MUST NOT remove a step from the store.
  Invariant 10.2: A storage-failure rejection MUST leave no partial record in the store.
  Invariant 10.3: An answered step_id MUST name a durably persisted step.
  ```
  WHY: a terminal step is retained as audit evidence. Deleting one would destroy the proof that the required gate was reached and resolved, which is the single thing an external evaluator comes to this store for.

---

## Examples

### SOX journal entry approval

A controller determines that posting JE-2026-0441 needs senior finance approval under SOX §404 controls. `submit(subject_ref: "je-2026-0441", approver_ref: "finance_director_chen", submitter_ref: "controller_morgan", scope: "financial:journal-entry:post")` → `step-001`, standing in pending (Operation 7 through 9).

The finance director approves: `approve("step-001", decided_by: "finance_director_chen", reason: "Reviewed and approved — posting authorized")` → approved. The step stands in approved, carrying decided_by, decision_reason and decided_at (Operation 24, Operation 27, Operation 30).

An auditor later runs `read({subject_ref: "je-2026-0441", state: approved})` and sees who submitted, who approved, when, and why. The control evidence is in the record without developer testimony.

Or the director finds a misclassification: `reject("step-001", decided_by: "finance_director_chen", reason: "GL account 4120 is incorrect — should be 4130 per revenue recognition policy")` → rejected_outcome. The composing workflow routes the entry back, and the corrected entry needs a new [Submit] — this step is closed (Invariant 3.1, State 4).

Or the controller catches a routing error first: `withdraw("step-001", withdrawn_by: "controller_morgan", reason: "Wrong approver — cross-border entries route to tax_director")` → withdrawn, and `step-002` carries the right approver_ref.

### Rejection paths

`approve("step-001", decided_by: "controller_morgan")` → unauthorized. The submitter is not the approver, and the step stays pending with nothing written (Operation 21, Operation 36).

`approve("step-001", decided_by: "finance_director_chen")` against the already-approved step → not-pending. Not unauthorized, even though the caller is the right actor — the step refuses every resolving call, and saying so sends the caller to the right problem (Operation 13, Operation 20).

`reject("step-002", decided_by: "tax_director", reason: "   ")` → invalid-request. A rejection with no stated reason is not an audit record (Operation 16, Invariant 6.3).

`approve("", decided_by: "finance_director_chen")` → invalid-request, refused before any store lookup — a blank id is garbage, not a reference to a missing step (Operation 10, Operation 12).

`approve("step-003", decided_by: "finance_director_chen", decided_at: "2020-01-01")` against a step submitted in 2026 → invalid-request. A decision cannot predate its submission (Operation 19).

`submit(subject_ref: "je-0442", approver_ref: "dir_chen", submitter_ref: "controller_morgan", scope: "   ")` → invalid-request (Operation 4).

`read({subject_ref: "je-2026-0441", approver_email: "chen@…"})` → invalid-query. The key stands outside the nine axes and is refused rather than ignored (Operation 44).

### Multiple gates on one subject

A cross-border entry needs both finance and tax sign-off. Two [Submit] calls produce `step-010` and `step-011` on the same subject_ref, each with its own approver_ref. Approving one leaves the other pending and untouched (Invariant 9.1). Whether the subject has any open gate is `read({subject_ref: X, state: pending})` — a non-empty answer means at least one gate is open. Whether *both* were required, and whether two approvals are enough, is [Multi-Party Approval](../compositions/multi-party-approval.md)'s (Non-goal 3).

### Regulated adversarial scenarios

- **Regulator audit.** A SOX §404 examiner asks for evidence that the materiality control operated on a sample of entries. `read({scope: "financial:journal-entry:post", submitted_at: {after: …, before: …}})` answers the gates with full attribution, and Check 2.1 through 3.4 are what make each one usable. What the atom cannot answer is which entries *should* have had a gate and did not — that comparison needs the transaction set, which lives outside (Non-goal 18, External check 2).
- **Disputed approval.** A director denies approving an entry under an FDA Part 11 signature challenge. The record shows decided_by equal to approver_ref, byte for byte, with the instant and the reason. That proves the call carried their reference and proves nothing about who made the call — the cryptographic binding is [Actor Identity](./actor-identity.md)'s, and the atom says so rather than letting the record be read as a signature (Non-goal 14, External check 3).
- **Breach forensics.** An investigator examining unauthorized approval attempts finds that the store holds no record of them: a refused call writes nothing (Operation 36, Operation 37), so unauthorized attempts leave no trace here at all. The attempt log is the composing [Audit Trail](../compositions/audit-trail.md)'s, and this store's contribution is the negative evidence — every decision that *did* land, fully attributed (External check 4).

---

## Generation acceptance

This atom's acceptance is what an external auditor can clear from the step store alone, with no recourse to source code, runbooks or developer narration.

### Conformance checks

```
Check 1.1: An auditor MUST find EVERY step whose state EQUALS EXACTLY ONE OF pending, approved, rejected, withdrawn (Invariant 2.1).
Check 2.1: An auditor MUST find EVERY step's step_id, subject_ref, approver_ref, submitter_ref and scope non-blank (Invariant 8.1).
Check 2.2: An auditor MUST find a submitted_at on EVERY step (Invariant 8.2).
Check 3.1: An auditor MUST find EVERY terminal step's attribution reference non-blank (Invariant 6.1).
Check 3.2: An auditor MUST find the terminal state's instant on EVERY terminal step (Invariant 6.2).
Check 3.3: An auditor MUST find EVERY rejected step's decision_reason non-blank (Invariant 6.3).
Check 3.4: An auditor MUST find EVERY withdrawn step's withdrawal_reason non-blank (Invariant 6.4).
Check 3.5: An auditor MUST find no terminal step's terminal instant preceding the step's submitted_at (Invariant 7.1).
Check 4.1: An auditor MUST find EVERY approved step's decided_by equal to the step's approver_ref (Invariant 4.1).
Check 4.2: An auditor MUST find EVERY rejected step's decided_by equal to the step's approver_ref (Invariant 4.2).
Check 4.3: An auditor MUST find EVERY withdrawn step's withdrawn_by equal to the step's submitter_ref (Invariant 5.1).
Check 5.1: An auditor MUST find no attribution field on a pending step (State 13).
Check 6.1: An auditor MUST find no step absent from a later unfiltered read (Invariant 10.1).
Check 6.2: An auditor MUST find a re-read step's submission fields unchanged from the prior read (Invariant 1.1).
Check 6.3: An auditor MUST find no step whose state EQUALS pending on a later read of a step a prior read found terminal (Invariant 3.1).
```

NOTE: EVERY check names the rule the check tests.

### External checks

```
External check 1: A deployment needing EVERY issued step_id found in the store MUST capture the submit answers (Invariant 10.3).
External check 2: A deployment needing the subjects carrying no step identified MUST read the subject set beside the step store (Non-goal 19).
External check 3: A deployment needing a decided_by bound to an actor MUST read the composing Actor Identity attestation (Non-goal 14).
External check 4: A deployment needing a refused call's attempt recorded MUST read the composing Audit Trail (Operation 37).
```

WHY:
External check 1 is the answer-capture split: enumerating every *issued* step_id needs the submit answers captured at call time, because a production auditor reading the store cannot know about a step the store is missing. Check 6.1 is the store-alone substitute from the other direction — no step present at an earlier read has since vanished.

External check 2 is the boundary that most resembles a gap and is not one. This store holds the gates that were submitted; it cannot show the subjects for which no gate was ever submitted, because absence is invisible to a query over what exists. An auditor asking *show me every entry above the materiality threshold with no controller approval* supplies the transaction set and the required-gate mapping, and this store supplies the gates to compare against (Non-goal 18, Non-goal 19). It is the same boundary [Selective Disclosure](./selective-disclosure.md) states as Selective Disclosure Invariant 5.1 — with the difference that this atom declares it a non-goal rather than an invariant it cannot enforce.

External check 4 records a deliberate silence. A refused call writes nothing here, so an unauthorized attempt leaves no trace in this store at all. That is correct for a record whose subject is decisions rather than attempts, and it means an investigation into attempted unauthorized approvals must read the composing audit log, not this one.

## Non-goals

```
Non-goal 1: The atom MUST NOT read two [Submit] calls carrying one field set as one step.
Non-goal 2: A deployment needing at-most-once submission MUST compose Duplicate Prevention.
Non-goal 3: The atom MUST NOT decide whether a subject's open gates are enough.
Non-goal 4: A deployment needing a quorum rule MUST compose Multi-Party Approval.
Non-goal 5: The atom MUST NOT bind a second actor to stand in for an approver_ref.
Non-goal 6: A deployment needing delegation MUST compose a delegation pattern.
Non-goal 7: The atom MUST NOT confirm that a subject stands in an approvable state.
Non-goal 8: The atom MUST NOT interpret what an approved step permits.
Non-goal 9: The atom MUST NOT decide who may call an action.
Non-goal 10: A deployment needing an authorization decision MUST compose Permissions.
Non-goal 11: The atom MUST NOT notify an approver_ref.
Non-goal 12: A deployment needing an approver notified MUST compose Notification.
Non-goal 13: The atom MUST NOT refuse a submitter_ref matching the step's approver_ref.
Non-goal 14: The atom MUST NOT bind a decided_by to an actor.
Non-goal 15: A deployment needing a non-repudiable decision MUST compose Actor Identity.
Non-goal 16: The atom MUST NOT detect a rewrite under the store.
Non-goal 17: A deployment needing a rewrite detected MUST compose Tamper Evidence.
Non-goal 18: The atom MUST NOT declare which gates a subject requires.
Non-goal 19: The atom MUST NOT detect a subject carrying no step.
Non-goal 20: The atom MUST NOT bound submitted_at from below.
Non-goal 21: A deployment needing a verifiable time anchor MUST compose a trusted timestamping pattern.
```

WHY:
Non-goal 13 is the one that looks like a missing control. A [Submit] naming the same actor as submitter and approver is accepted, and that actor may then decide the step they raised. The atom does not refuse self-approval structurally, because segregation of duties is a *policy* about which actor pairings are allowed, and policies vary — the SOX §404 control requiring distinct actors on a financial action, the Part 11 expectation that a signature attests to a decision the signer did not originate, and the many deployments where a single-actor gate is the intended design. [Permissions](./permissions.md) refuses the pairing where a declared policy says so, and [Multi-Party Approval](../compositions/multi-party-approval.md) requires a second step with a different approver. Building either into the atom would make a policy look like a structure.

Non-goal 18 and Non-goal 19 are the completeness boundary. This atom records the gates that were submitted and cannot record the ones that were not; a query over what exists cannot see an absence. The required-gate mapping — *every journal entry above $10K needs a controller and a CFO approval* — is the calling system's business-rule layer, and the comparison is a composition's (External check 2).

Non-goal 20 keeps submitted_at unbounded below on purpose. A gate is routinely recorded by a workflow bridge after the request was actually made through another channel — an email, a meeting, a paper form — and refusing the earlier instant would force the record to misstate when the request happened. The future bound refuses the one direction that is always fabrication; the defence against a step back-inserted into the past is the composing [Audit Trail](../compositions/audit-trail.md) and [Tamper Evidence](./tamper-evidence.md) layer, which makes the record's creation order itself evident.

---

## Edge cases

### Atomic writes

```
Atomic writes 1: A reader MUST NOT observe a terminal state without the state's attribution fields.
Atomic writes 2: An uncommitted crash MUST leave the step as the call found the step.
Atomic writes 3: The implementation MUST resolve a dangling transition.
Atomic writes 4: The store MUST NOT serve a read BEFORE the implementation resolves the dangling transition.
```

Term uncommitted crash: a crash BEFORE an admitted resolve's commit lands.

Term dangling transition: an admitted resolve's mutations standing partly applied once a crash has landed; the implementation resolves one by completing the mutations OR rolling the mutations back.

WHY:
Every resolving action writes the state and its attribution fields together (Operation 31), and a crash between them produces a terminal step with a missing decider or a missing instant — which is Invariant 6 violated in exactly the way an auditor cannot distinguish from an implementation that never wrote them. The obligation is all-or-none observability: a partly applied resolve must never be servable.

### Concurrency

```
Concurrency 1: The implementation MUST serialize two resolving actions against one step.
Concurrency 2: A serialized resolving action MUST read the state the prior resolving action left.
Concurrency 3: The second serialized resolving action against one pending step MUST answer not-pending.
```

WHY:
Unlike a store whose concurrent writes contend over nothing, two resolving calls on one step contend over the state itself, and the outcome is not a race: the first lands and the second reads a terminal state and answers not-pending (Operation 13). That makes a retry self-detecting, which is what Indeterminate outcome 3 rests on.

### Indeterminate outcome

```
Indeterminate outcome 1: A caller receiving no answer MUST NOT retry BEFORE the caller reads the step store.
Indeterminate outcome 2: A caller MUST NOT read a transport fault as a storage-failure.
Indeterminate outcome 3: A caller retrying a landed resolving action MUST read not-pending.
```

WHY:
The [Storage Failure] guarantees are the store's: it committed or it did not, and the answer means it did not. The caller's knowledge is weaker — a lost response after a commit leaves them unable to tell *refused, nothing written* from *succeeded, answer lost*. The two actions differ under that ambiguity and the difference is worth knowing before the retry. Retrying a resolving action is self-detecting (Indeterminate outcome 3, Concurrency 3). Retrying [Submit] is not: submission is not idempotent, so a retry after a lost answer creates a second step (Non-goal 1, Non-goal 2).

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


WHY:
The cost of byte-exactness lands hardest on the exclusivity guards. An approver whose reference is stored one way and supplied another gets unauthorized on their own step — correct by Identity 10, and indistinguishable to them from being the wrong actor. A deployment that does not canonicalize will discover this as an approver who cannot approve.

NOTE: watch host obligations — this atom sets no maximum length on a string input, where [Duplicate Prevention](./duplicate-prevention.md) declares a cap and [Provenance](./provenance.md) obliges the deployment to set one. Three postures, and the *host obligations* docket row carries the count — a watch flag states the pressure, never a census nothing reads.

---

## Composition notes

```
Composition note 1: A deployment MUST declare which composing patterns the deployment wired in.
Composition note 2: A composing pattern MUST own the authorization of a call.
Composition note 3: A composing pattern MUST own the segregation policy over a submitter_ref and an approver_ref.
Composition note 4: A composing pattern MUST own the attestation binding a decided_by.
Composition note 5: A composing pattern MUST own the notification of an approver_ref.
Composition note 6: A composing pattern MUST own a quorum rule over two steps.
Composition note 7: A composing pattern MUST own the delegation of an approver_ref.
Composition note 8: A composing pattern MUST own the tamper seal over the step store.
Composition note 9: A composing pattern MUST own at-most-once submission.
Composition note 10: A composing pattern MUST own the required gate mapping for a subject.
Composition note 11: A composing pattern reading the step store MUST NOT write to the step store.
```

WHY:
[Multi-Party Approval](../compositions/multi-party-approval.md) is the composition this atom is the unit of: N steps under a named quorum rule — all-of-N, M-of-N, one-of-N — layered on [Permissions](./permissions.md) for chain-level authorization, [Assignment](./assignment.md) for the in-tray binding per pending step, and an [Audit Trail](../compositions/audit-trail.md) substrate. The quorum evaluation is the load-bearing wiring decision and it is emphatically not here (Composition note 6, Non-goal 3): this atom knows one gate and its outcome, and knows nothing about how many gates make a decision.

[Execute Gated Workflow](../compositions/execute-gated-workflow.md) is where this atom meets its sibling. A [State Machine](./state-machine.md) instance governs the process lifecycle, a guarded declared transition fires only where its bound step stands approved, and the two atoms are the fixed-state and declared-state poles of one category rather than competitors.

[Permissions](./permissions.md) governs who may submit and who may read, and is also where segregation of duties lands (Composition note 3, Non-goal 13). [Actor Identity](./actor-identity.md) supplies the electronic signature that makes decided_by non-repudiable under FDA 21 CFR Part 11 and SOX §404 — the attestation is the signature event and this atom's record is the gate the signature attaches to. [Assignment](./assignment.md) is a composing peer rather than an overlap: it tracks who owns the work that becomes the subject. [Event Log](./event-log.md) journals every call as an event where this atom holds the current-state projection, [Tamper Evidence](./tamper-evidence.md) seals the records, and [Duplicate Prevention](./duplicate-prevention.md) supplies at-most-once submission under retry.

---

## Terms

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is* and its **Kind**.

### Vocabulary

Term actors: the atom; the host; the transition; the implementation; the deployment; a composing pattern; a business caller; a caller; a guard; an auditor; a regulator; an examiner; an investigator; an actor; an approver; a submitter; the store; a step; a pending step; a terminal step; an approved step; a rejected step; a withdrawn step; a resolving action; a deciding action; a writing action; a refused action; an action; a query; a filter; a reference filter; a state filter; a range filter; an instant-range filter; a rejection; a crash; a reader; a string input; an opaque reference; the store instance's step count; an attribution check.

Term records: step — one authorization gate, carrying step_id, subject_ref, approver_ref, submitter_ref, scope, submitted_at, a state and, where supplied or set, reason, decided_by, decision_reason, decided_at, withdrawn_by, withdrawal_reason and withdrawn_at.

Term record verbs: identify, allocate, change, carry, stand, answer, record, set, take, leave, own, match, equal, normalize, interpret, confirm, admit, offer, detect, route, share, precede, follow, exceed, compare, order, trim, case-fold, refuse, write, read, find, observe, resolve, complete, serve, serialize, commit, fall, bound, decide, declare, compose, wire, supply, remove, sort, name, notify, bind, capture, choose, canonicalize, retry, permit.

Term value sets: state = pending | approved | rejected | withdrawn.

Term bounds: empty.

Term cadences: empty.

Term qualifiers: migrated — rewritten in GRACE lang v0.40 (2026-09-12).

Term terms: step, step_id, subject_ref, approver_ref, submitter_ref, scope, reference, store instance, seam, transition, now, business caller, states, terminal state, resolving action, deciding action, writing action, deciding reference, decision instant, resolved decision instant, resolved submitted_at, submission field, attribution field, attribution check, filter axes, admitted submit, admitted resolve, admitted approve, admitted reject, admitted withdraw, admitted read, string input, blank, uncommitted crash, dangling transition.

#### Approval Step

The record this atom defines: a single authorization gate binding a required approval to one named approver, for a specified subject and scope, with a lifecycle from submission through one terminal decision. It carries its [Step Id], [Subject Ref], [Approver Ref], [Submitter Ref], [Scope], [Submitted At], [Reason], the [State] field, and the state-specific decision/withdrawal fields; the submission fields are immutable from creation. A fresh approval need is a new Approval Step, never a re-opened one.

Kind: Type

#### Submit

The behavior that records a new approval gate. It assigns a fresh [Step Id], records [Subject Ref], [Approver Ref], [Submitter Ref], [Scope], [Reason] (if supplied), and [Submitted At], enters the step in [Pending], and returns the [Step Id] (or a rejection naming the failed precondition).

Kind: Operation

#### Approve

The resolving behavior the named approver invokes to record the affirmative decision and move a [Pending] step to [Approved]. Permitted only when [Decided By] matches [Approver Ref]; it stamps [Decided By], [Decision Reason] (optional for an approval), and [Decided At]. On an already-terminal step it is rejected [Not Pending]; from any other actor it is rejected [Unauthorized].

Kind: Operation

#### Reject

The resolving behavior the named approver invokes to record the negative decision and move a [Pending] step to [Rejected]. Requires a stated reason. Permitted only when [Decided By] matches [Approver Ref]; it stamps [Decided By], [Decision Reason], and [Decided At]. Its success token is rejected_outcome, distinct from the action's own rejection path. On an already-terminal step it is rejected [Not Pending]; from any other actor it is rejected [Unauthorized].

Kind: Operation

#### Withdraw

The resolving behavior the submitter invokes to retract a request and move a [Pending] step to [Withdrawn]. Requires a stated reason. Permitted only when [Withdrawn By] matches [Submitter Ref]; it stamps [Withdrawn By], [Withdrawal Reason], and [Withdrawn At]. On an already-terminal step it is rejected [Not Pending]; from any actor other than the submitter it is rejected [Unauthorized].

Kind: Operation

#### Read

The read-only behavior that returns the steps matching a [Query], ordered by [Submitted At] ascending with [Step Id] as a lexicographic-byte-order tiebreaker. A well-formed [Query] matching no steps returns an empty sequence; a malformed one is rejected [Invalid Query]. It changes nothing.

Kind: Operation

#### Step Id

The opaque, immutable, system-generated identity of an approval step, assigned on [Submit], never reused or reassigned within the store instance. It must be a non-empty string sortable in lexicographic byte-order (for deterministic [Read] ordering). The subject, approver, scope, submitter, reason, and timestamps are properties of the step, not its identity.

Kind:       Field
Field of:   Approval Step
Projection: step_id

#### Subject Ref

The opaque reference to the thing being approved — a document, transaction, work item, or protocol-deviation id. Set on [Submit], immutable thereafter. The atom does not validate that the subject exists or is in any particular state; that is the caller's responsibility.

Kind:       Field
Field of:   Approval Step
Projection: subject_ref

#### Approver Ref

The opaque reference to the actor required to approve. Set on [Submit], immutable. It is the authorization anchor: only the actor whose reference matches it may [Approve] or [Reject] the step (Invariant 4). Delegation is a composing concept, not a property of this atom.

Kind:       Field
Field of:   Approval Step
Projection: approver_ref

#### Submitter Ref

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

#### Submitted At

The timestamp at which the step was submitted, set on [Submit] (caller-supplied or wall-clock-defaulted; must not be in the future). Immutable. It is the lower bound the temporal-ordering invariant measures decision and withdrawal timestamps against (Invariant 7).

Kind:       Field
Field of:   Approval Step
Projection: submitted_at

#### State

The field holding the step's current state — one of [Pending], [Approved], [Rejected], or [Withdrawn]. Set to [Pending] on [Submit]; transitions once to a terminal via [Approve], [Reject], or [Withdraw], then never changes (Invariants 2 and 3).

Kind:       Field
Field of:   Approval Step
Projection: state

#### Decided By

The opaque reference to the actor who decided, stamped on [Approve] or [Reject]. Present on [Approved] and [Rejected] steps; immutable once set. It must match [Approver Ref] for the decision to be accepted (Invariant 4) and must not be blank (Invariant 6).

Kind:       Field
Field of:   Approval Step
Projection: decided_by

#### Decision Reason

The stated reason recorded with a decision, stamped on [Approve] or [Reject]. Required on a [Rejected] step (Invariant 6); optional on an [Approved] step. Present on [Approved] and [Rejected] steps only; immutable once set.

Kind:       Field
Field of:   Approval Step
Projection: decision_reason

#### Decided At

The timestamp at which the decision was recorded, stamped on [Approve] or [Reject] (caller-supplied or wall-clock-defaulted; must not be in the future). Present on [Approved] and [Rejected] steps; immutable once set. [Decided At] ≥ [Submitted At] always holds (Invariant 7).

Kind:       Field
Field of:   Approval Step
Projection: decided_at

#### Withdrawn By

The opaque reference to the actor who withdrew the request, stamped on [Withdraw]. Present on [Withdrawn] steps; immutable once set. It must match [Submitter Ref] for the withdrawal to be accepted (Invariant 5) and must not be blank (Invariant 6).

Kind:       Field
Field of:   Approval Step
Projection: withdrawn_by

#### Withdrawal Reason

The stated reason recorded with a withdrawal, stamped on [Withdraw]. Required (Invariant 6). Present on [Withdrawn] steps only; immutable once set.

Kind:       Field
Field of:   Approval Step
Projection: withdrawal_reason

#### Withdrawn At

The timestamp at which the withdrawal was recorded, stamped on [Withdraw] (caller-supplied or wall-clock-defaulted; must not be in the future). Present on [Withdrawn] steps; immutable once set. [Withdrawn At] ≥ [Submitted At] always holds (Invariant 7).

Kind:       Field
Field of:   Approval Step
Projection: withdrawn_at

#### Query

The selection a caller passes to [Read] to scope which steps are returned — any combination of the supported filter axes ([Step Id], [Subject Ref], [Approver Ref], [Submitter Ref], [Scope], [State], and time ranges on the timestamp fields). Consumed per call; never stored.

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

The terminal state a step reaches when the named approver affirmatively decided within [Approve]. Carries all submission fields plus [Decided By], [Decision Reason] (if supplied), and [Decided At]. Absorbing: no action transitions it elsewhere. It is also the [Approve] success token and a state filter value.

Kind:       Member
Member of:  the step state
Role:       Outcome
Projection: approved

#### Rejected

The terminal state a step reaches when the named approver negatively decided within [Reject]. Carries all submission fields plus [Decided By], [Decision Reason] (required), and [Decided At]. Absorbing. As a state filter value its wire form is rejected; the [Reject] success token is the distinct rejected_outcome, kept verbatim in the projected contract.

Kind:       Member
Member of:  the step state
Role:       Outcome
Projection: rejected

#### Withdrawn

The terminal state a step reaches when the submitter retracted the request within [Withdraw]. Carries all submission fields plus [Withdrawn By], [Withdrawal Reason], and [Withdrawn At]. Absorbing. It is also the [Withdraw] success token and a state filter value.

Kind:       Member
Member of:  the step state
Role:       Outcome
Projection: withdrawn

#### Invalid Request

The rejection a write action ([Submit], [Approve], [Reject], [Withdraw]) returns when an input is malformed — a blank required field, a malformed [Step Id], a missing-reason [Reject]/[Withdraw], a future or backdated-before-[Submitted At] timestamp. A guard rejection that writes nothing.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-request

#### Not Known

The rejection a resolving action ([Approve], [Reject], [Withdraw]) returns when the supplied [Step Id] is well-formed but references no step in the store. Checked after the malformed-[Step Id] guard and before the state check.

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

The rejection a resolving action returns when the deciding actor is not the authorized one — [Decided By] not matching [Approver Ref] on [Approve]/[Reject], or [Withdrawn By] not matching [Submitter Ref] on [Withdraw]. The record is left [Pending] and nothing is written (Invariants 4 and 5).

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: unauthorized

#### Storage Failure

The rejection any write action returns when the underlying store write fails after all preconditions pass. No [Step Id] is issued on [Submit]; a resolving action leaves the step in [Pending]. The caller must retry.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: storage-failure

#### Invalid Query

The rejection [Read] returns when a filter is malformed — a blank string-axis value, a [State] value outside the four states, a time range with end before start, or an unrecognized filter key (rejected rather than silently ignored).

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
[Subject Ref]: #subject-ref
[Approver Ref]: #approver-ref
[Submitter Ref]: #submitter-ref
[Scope]: #scope
[Reason]: #reason
[Submitted At]: #submitted-at
[State]: #state
[Decided By]: #decided-by
[Decision Reason]: #decision-reason
[Decided At]: #decided-at
[Withdrawn By]: #withdrawn-by
[Withdrawal Reason]: #withdrawal-reason
[Withdrawn At]: #withdrawn-at
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

- **Sarbanes-Oxley §404 (17 U.S.C. §7262)** — internal control over financial reporting. The approval step is the structural form of a financial reporting control: a gate that must be cleared before a material action proceeds, with an auditable record of who cleared it. SOX auditors reviewing control evidence query approval step records directly; Invariants 4, 6, and 8 are the structural guarantees the evidence must carry.
- **FDA 21 CFR Part 11 (Electronic Records; Electronic Signatures)** — for FDA-regulated contexts (pharmaceutical manufacturing, clinical trials, medical device quality systems): each approval step by a named actor constitutes an electronic signature on the action. Part 11 §11.50 requires that electronic signatures are attributable to one individual and §11.70 requires that they are linked to their respective records to prevent removal, substitution, or falsification. Composition with [Actor Identity](./actor-identity.md) provides the cryptographic binding; composition with [Tamper Evidence](./tamper-evidence.md) provides the linking and non-falsifiability. The Approval Step record is the gate; the composition is the compliant electronic signature system.
- **ICH (International Council for Harmonisation of Technical Requirements for Pharmaceuticals for Human Use) E6(R3) Good Clinical Practice — Guideline** — the international standard for clinical trial conduct. Section 4 (Investigator's Responsibilities) and Section 5 (Sponsor's Responsibilities) require documented approval steps at multiple points in the trial lifecycle: investigator approval of protocol deviations, IRB (Institutional Review Board) approval of informed consent amendments, sponsor approval of site qualification assessments. Each maps to an Approval Step record whose [Scope] identifies the specific GCP obligation.
- **ISO 9001:2015 §8.5.1 (Control of production and service provision)** — the International Organization for Standardization's quality-management standard; requires that production and service provision activities be controlled by documented procedures including approval of documents, products, and services at defined points. Approval steps are the documented approval records §8.5.1 anticipates; the atom's immutability invariants satisfy the document control requirements.
- **ISO 13485:2016 §4.2 (Documentation requirements)** — for medical device manufacturers: records of approval activities must be maintained. Approval Step records are the compliant implementation surface.

---

## Status

`grounded on Final Critique 5 — 2026-07-12` — see the Ledger.

## Ledger

```
status: grounded on Final Critique 5 — 2026-07-12
formal: verified — approval-step.tla + 1 twin, 2026-06-03
last gate: 2026-07-12 — Final Critique 5, fresh reader — clean

open: none
```

## Decisions

Directional changes only — the turns a future reader must know the pattern took, and why. Everything smaller lives in the commit that made it: `git log -- atoms/approval-step.md`.

- **2026-09-12 — Rewritten in GRACE lang v0.40; nothing but language changed.** *Chose:* the five actions as a signature block, Invariant 1 through 10 keeping their numbers, every success effect conditioned on a declared admitted submit, admitted resolve or admitted read (Hard invariant 16), the six-step rejection precedence — repeated verbatim in four places in the prose, once per resolving action and once in the state table — collapsed to one seven-row case space with the ordering carried by `ONLY IF` guards, the three resolving actions unified under declared resolving action, deciding reference and decision instant terms so [Approve], [Reject] and [Withdraw] state their shared guards once instead of three times, the six acceptance areas opened into `Check 1.1 through 6.3` with four `External check`s, the Non-goals-and-edge-cases prose split into a `Non-goal 1 through 20` family and five edge-case families (`String`, `Clock semantics`, `Concurrency`, `Atomic writes`, `Indeterminate outcome`). *Over:* the prose spec. *Because:* the migration plan; `cites.py --into approval-step` found nothing citing this atom by label. 81.1 KB → 62.7 KB.

- **2026-09-12 — Three propositions had two owners each.** *Chose:* `Invariant 2.1` owns membership exclusivity and the `State` family no longer restates it; `Operation 8` owns *an admitted submit stands the step in pending*; `Identity 12` owns *the atom does not confirm a subject_ref*. *Over:* keeping each pair. *Because:* Authority 3, and all three were found by `W-duplicate-proposition` rather than by reading — the same pattern as State Machine, where the duplicates a 169-rule surface hides are exactly the ones no reader finds.

- **2026-09-12 — A cross-spec citation was written in the local form.** *Chose:* `Selective Disclosure Invariant 5.1`, the qualified form §11 declares. *Over:* `[Selective Disclosure](./selective-disclosure.md) states as its \`Invariant 5\``, which reads as a citation of *this* spec's Invariant 5 — submitter exclusivity, an unrelated rule. *Because:* the citation-aim audit resolved it against the local registry and the aim was wrong. Nothing enforces the qualified form, and a census over the corpus returns 24 candidates of which nearly all are local citations that merely sit near a spec link — so the class is docketed rather than instrumented.

NOTE: End of Approval Step.
