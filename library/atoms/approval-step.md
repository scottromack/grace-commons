---
title: Approval Step
id: 29
audience: common
---

# Approval Step

<details markdown="block">
<summary>Table of contents</summary>
{: .text-xs .font-medium .uppercase .tracking-wide .opacity-50 }
1. TOC
{:toc}
</details>

## What it is

Approval Step records a single authorization gate. A specific thing was submitted for approval, presented to one named approver, and ended in a decision — approved, rejected, or withdrawn — with who decided, when, and why.

Each step has exactly one approver (the only person who may approve or reject it), one submitter (the only person who may withdraw it before a decision), one subject (the thing being approved), and one scope (the kind of approval being requested). Those, and the submission time, are fixed at submission and never change.

A step has four states: pending, plus three final ones — approved, rejected and withdrawn, the last two each with a required reason. A step that reaches a final state stays there: there is no re-open and no decision reversal.

The core guarantee is that every decision is fully attributed. An anonymous decision, a rejection with no reason, or a missing timestamp is a failure. So it is provable that a required control existed and operated, which is exactly what an auditor or investigator asks for.

This is distinct from a permission (standing, reusable authority to do a class of things) and from an assignment (who owns a task, not who approved it). A controller may be *permitted* to approve journal entries, and each entry still needs an Approval Step proving they *did* approve that one. Delegation — letting someone decide in the named approver's place — is not part of the step; a deployment that needs it adds it separately.

*Also known as: an approval gate, a sign-off, an authorization step, a review gate.*

<details markdown="block">
<summary>WHY</summary>

Many actions in regulated systems require explicit human authorization before they may proceed. A journal entry above a materiality threshold needs a controller's approval before it posts. A clinical-trial protocol deviation needs the principal investigator's approval before the deviant procedure happens. A pharmaceutical batch release needs a qualified person under 21 CFR (Code of Federal Regulations) Part 211. An engineering change order needs a release chain. The structure is identical every time: something is submitted, a named actor reviews it, and the outcome is an auditable record that external evaluators rely on as evidence the required control existed and operated.

This atom is that structure and nothing else. It records the gate, who the gate was for, the outcome, the actor who decided, and when — and it guarantees those records are present and immutable. Cryptographic protection against post-hoc modification, the bar for court-admissible evidence under SOX (Sarbanes-Oxley Act) section 404 and FDA (US Food and Drug Administration) Part 11, is another pattern's and is not provided here.

Three adjacent concepts are distinguished, and every distinction is load-bearing.

The app's permission governs *standing* authorization — a persistent grant, checked at every relevant invocation, live until revoked. This atom governs *transient decision* authorization — a one-time gate on one subject that produces a terminal outcome and closes. A permission answers *may this actor generally do things of this kind?* This atom answers *has this specific thing been approved by the specifically named actor for this specific scope?* A controller with permission to approve journal entries still needs a step record per entry: the grant says they are allowed, the step says they did. Both are present in a conforming SOX deployment and neither replaces the other.

An assignment pattern governs *responsibility binding* — who owns the work, with a lifecycle of its own. This atom governs the decision. A document may be assigned to an author and simultaneously submitted to a reviewer; the two coexist without overlapping. Confusing them produces either a spec that cannot record the approval or one that loses track of who owns the work.

A general state machine is the general engine: states and transitions declared by the deployment, opaque to the atom. This atom is a *specific* state machine whose four states, three transitions out of pending and approval semantics are fixed here — one named approver, a decision that is itself a compliance record, a required reason on rejection. The axis is specificity: an external evaluator knows this atom's states from the spec and must read a general state machine's declaration to know that one's. The two are the fixed and declared poles of the same category, and they compose into a gated workflow.

</details>

## What it keeps

### The steps

```
Identity 1: The atom MUST identify a step by the step id.
Identity 2: The host MUST allocate a step id for a [Submit] at the seam.
Identity 4: The atom MUST NOT change a step id.
Identity 5: Two steps in one database instance MUST NOT share a step id.
Identity 8: The atom MUST NOT identify a step by the subject reference.
Identity 9: The atom MUST admit a second step carrying a recorded subject reference.
Identity 10: The atom MUST compare a reference byte-exactly.
Identity 11: The atom MUST NOT normalize a reference.
Identity 12: The atom MUST NOT confirm that a subject reference names a known subject.
Identity 13: The atom MUST NOT interpret a scope.
```

Term step: one authorization gate — one subject, one approver, one submitter, one scope and one outcome; an [Approval Step], the record this atom holds.

Term subject reference: the opaque reference naming the thing being approved — a [Subject Reference]; a property of the step, never the step's identity.

Term approver reference: the opaque reference naming the actor required to approve — an [Approver Reference]; the authorization anchor.

Term submitter reference: the opaque reference naming the actor requesting approval — a [Submitter Reference]; the attribution anchor for the submission.

Term scope: the string naming the kind of approval requested — a [Scope]; recorded and filtered on, never interpreted.

Term reference: subject reference, approver reference, submitter reference, deciding actor, withdrawing actor, step id OR scope — every string this atom compares for equality, a reason, a decision reason and a withdrawal reason excepted.

```
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

#### Approval Step

The record this atom defines: a single authorization gate binding a required approval to one named approver, for a specified subject and scope, with a lifecycle from submission through one terminal decision. It carries its [Step Id], [Subject Reference], [Approver Reference], [Submitter Reference], [Scope], [Submission Instant], [Reason], the [State] field, and the state-specific decision/withdrawal fields; the submission fields are immutable from creation. A fresh approval need is a new Approval Step, never a re-opened one. No action of the atom is undone: a step is never re-opened, reversed or removed (State 2 through 5, Invariant 10.1), so no undo is owed (Execution Contract Undo 4).

Kind: Type

#### Step Id

The opaque, immutable, system-generated identity of an approval step, assigned on [Submit], never reused or reassigned within the database instance. The subject, approver, scope, submitter, reason, and timestamps are properties of the step, not its identity.

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

The non-blank string naming the kind of approval being requested (for example `"financial:journal-entry:post"`). Set on [Submit], immutable. The atom does not interpret scope semantics; it records the scope as an auditable field and uses it as an exact-match filter axis for [Read].

Kind:       Field
Field of:   Approval Step
Projection: scope

#### Reason

The optional submission-context string supplied at [Submit] — a description of what is being approved, the underlying business rule, or a summary of the deviation. Stored under its own name; immutable thereafter. (Distinct from the [Decision Reason] and [Withdrawal Reason] fields the resolving actions write.)

Kind:       Field
Field of:   Approval Step
Projection: reason

#### Submission Instant

The timestamp at which the step was submitted, set on [Submit] (caller-supplied or wall-clock-defaulted). Immutable. It is the lower bound the temporal-ordering invariant measures decision and withdrawal timestamps against (Invariant 7).

Kind:       Field
Field of:   Approval Step
Projection: submitted_at

#### State

The field holding the step's current state — one of [Pending], [Approved], [Rejected], or [Withdrawn]. Set to [Pending] on [Submit]; transitions once to a terminal via [Approve], [Reject], or [Withdraw], then never changes (Invariants 2 and 3).

Kind:       Field
Field of:   Approval Step
Projection: state

#### Deciding Actor

The opaque reference to the actor who decided, stamped on [Approve] or [Reject]. Present on [Approved] and [Rejected] steps; immutable once set. Invariant 4 holds it to [Approver Reference] and Invariant 6 holds it non-blank.

Kind:       Field
Field of:   Approval Step
Projection: decided_by

#### Decision Reason

The stated reason recorded with a decision, stamped on [Approve] or [Reject]. Required on a [Rejected] step (Invariant 6); optional on an [Approved] step, and refused [Invalid Request] when supplied blank (Operation 57). Present on [Approved] and [Rejected] steps only; immutable once set.

Kind:       Field
Field of:   Approval Step
Projection: decision_reason

#### Decision Instant

The timestamp at which the decision was recorded, stamped on [Approve] or [Reject] (caller-supplied or wall-clock-defaulted). Present on [Approved] and [Rejected] steps; immutable once set. [Decision Instant] ≥ [Submission Instant] always holds (Invariant 7).

Kind:       Field
Field of:   Approval Step
Projection: decided_at

#### Withdrawing Actor

The opaque reference to the actor who withdrew the request, stamped on [Withdraw]. Present on [Withdrawn] steps; immutable once set. Invariant 5 holds it to [Submitter Reference] and Invariant 6 holds it non-blank.

Kind:       Field
Field of:   Approval Step
Projection: withdrawn_by

#### Withdrawal Reason

The stated reason recorded with a withdrawal, stamped on [Withdraw]. Required (Invariant 6). Present on [Withdrawn] steps only; immutable once set.

Kind:       Field
Field of:   Approval Step
Projection: withdrawal_reason

#### Withdrawal Instant

The timestamp at which the withdrawal was recorded, stamped on [Withdraw] (caller-supplied or wall-clock-defaulted). Present on [Withdrawn] steps; immutable once set. [Withdrawal Instant] ≥ [Submission Instant] always holds (Invariant 7).

Kind:       Field
Field of:   Approval Step
Projection: withdrawn_at

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

Term step id: the opaque value naming one step — a [Step Id]; host-allocated at the seam.

## What people do

### Every action

```
Operation 10: IF step id EQUALS blank THEN a resolving action MUST answer invalid-request.
Operation 11: IF the step id names no step THEN a resolving action MUST answer not-known.
Operation 13: IF the step's state IS IN the terminal states THEN a resolving action MUST answer not-pending.
Operation 15: IF the deciding reference EQUALS blank THEN a resolving action MUST answer invalid-request.
Operation 18: IF now PRECEDES the resolved decision instant THEN a resolving action MUST answer invalid-request.
Operation 19: IF the resolved decision instant PRECEDES the step's submission instant THEN a resolving action MUST answer invalid-request.
Operation 64: IF the resolved decision instant is malformed THEN a resolving action MUST answer invalid-request (Execution Contract Input 1).
Operation 65: IF the deciding reference EXCEEDS the string cap OR reason EXCEEDS the string cap THEN a resolving action MUST answer invalid-request.
Operation 20: A resolving action MUST answer invalid-request on an attribution fault ONLY IF the step's state EQUALS pending.
Operation 21: IF deciding actor DOES NOT EQUAL approver reference THEN a deciding action MUST answer unauthorized.
Operation 32: An admitted resolve MUST answer the action's success token.
Operation 33: A resolving action MUST NOT change a submission field.
Operation 34: IF the database refuses the write THEN a writing action MUST answer storage-failure.
Operation 36: A refused action MUST leave the step as the call found the step.
Operation 37: A refused action MUST NOT record an attribution field.
```

NOTE: watch the blank filter value (Operation 45).

NOTE: watch the optional field no rule records (Operation 61).

NOTE: watch the required input no rule records (Operation 62).

Term states: pending | approved | rejected | withdrawn — a [State], and the whole state space.

Term terminal state: approved | rejected | withdrawn — the three absorbing members of states.

Term resolving action: [Approve] | [Reject] | [Withdraw] — the three actions that close a pending step.

Term deciding action: [Approve] | [Reject] — the two a guard on approver reference covers.

Term writing action: [Submit] | [Approve] | [Reject] | [Withdraw] — every action but [Read].

Term deciding reference: deciding actor on a deciding action, and withdrawing actor on [Withdraw] — the actor reference a resolving action carries.

Term resolved decision instant: the instant a resolving action records, as decision instant on a deciding action and as withdrawal instant on [Withdraw] — the supplied value, as Execution Contract Logic confinement 12 resolves it.

Term resolved submission instant: the instant the step carries as submission instant — the supplied value, as Execution Contract Logic confinement 12 resolves it.

Term submission field: step id, subject reference, approver reference, submitter reference, scope, submission instant OR reason — every field [Submit] sets.

Term attribution field: deciding actor, decision reason, decision instant, withdrawing actor, withdrawal reason OR withdrawal instant — every field a resolving action sets.

Term attribution reference: deciding actor on an approved step or a rejected step, and withdrawing actor on a withdrawn step — the actor reference a terminal step carries.

Term terminal instant: decision instant on an approved step or a rejected step, and withdrawal instant on a withdrawn step — the instant a terminal step carries.

Term attribution check: Operation 15 through 19, Operation 57, Operation 64 through 65.

Term attribution fault: an attribution check the call fails.

Term filter axes: step id | subject reference | approver reference | submitter reference | scope | state | submission instant | decision instant | withdrawal instant — the nine axes [Read] accepts, and no others, each spelled as its field's projection.

Term string axes: step id | subject reference | approver reference | submitter reference | scope — the axes whose filter value carries a string.

Term carried reason: the reason the call's input holds, blank included — a call that omits reason carries none, and the omission is no blank reason (State 8, String 6).

Term admitted submit: a [Submit] call whose references, scope, carried reason and resolved submission instant the guards, Execution Contract Input 2 included, all admit.

Term authorization anchor: the approver reference on a deciding action, and the submitter reference on [Withdraw].

Term admitted resolve: a resolving action whose step id names a pending step and whose reason, deciding reference and resolved decision instant the guards admit, and whose deciding reference matches the step's authorization anchor.

Term admitted approve: an admitted resolve on [Approve].

Term admitted reject: an admitted resolve on [Reject].

Term admitted withdraw: an admitted resolve on [Withdraw].

Term admitted read: a [Read] call whose every filter axis and filter value the guards admit.

Term matching steps: the steps that satisfy every supplied filter — the answer of an admitted read.

Term landing read: a [Read] of the step by step id after a lost resolving action, whose answer shows the step's state and its deciding actor or withdrawing actor, and a [Read] filtered on subject reference, approver reference, submitter reference, scope and a range of submission instant spanning the call's resolved submission instant after a lost [Submit] — where the call supplied the instant, a range holding that instant, and where the call left it blank, the range from the instant the caller sent the call, less the clock allowance, to the instant the caller sent the landing read, plus the clock allowance (Execution Contract Logic confinement 18) — the read whose answer shows whether the call landed; where an earlier [Submit] carries the same field set, its answer holds both steps and shows only that a step carrying the field set stands (Indeterminate outcome 4).

Term success token: approved on [Approve], rejected_outcome on [Reject] and withdrawn on [Withdraw] — the answer an admitted resolve returns.

The case space, and the rule that owns each case:

| # | Condition | a resolving action answers | Owner |
|---|---|---|---|
| 1 | step id is blank or over the string cap | [Invalid Request] | Operation 10; Execution Contract Input 2 |
| 2 | step id is not blank, it names no step | [Not Known] | Operation 11 |
| 3 | the step exists, it stands in a terminal state | [Not Pending] | Operation 13 |
| 4 | the step stands in pending, an attribution check fails | [Invalid Request] | Operation 20; Operation 15 through 19, Operation 57, Operation 64 through 65 |
| 5 | every attribution check passes, the deciding reference is not the authorization anchor | [Unauthorized] | Operation 21, Operation 22 |
| 6 | every precondition passes, the database refuses the write | [Storage Failure] | Operation 34 |
| 7 | every precondition passes, the database accepts the write | the success token | Operation 32; Invariant 1.1, Invariant 9.1 |

Where two rows hold at once, the earlier row answers: the rows follow the refuses line (Execution Contract Refusal 1), and row 4 answers only on a pending step (Operation 20).

NOTE: watch condition negation — invalid-request occupies rows 1 and 4 of one precedence chain, so the answer alone does not say which guard refused. A general state machine and an audit pattern carry the same shape.

#### Invalid Request

The rejection a write action ([Submit], [Approve], [Reject], [Withdraw]) returns when an input is malformed — a blank required field, the [Step Id] among them, a missing-reason [Reject]/[Withdraw], a blank reason supplied to [Submit] or [Approve], a string input over the string cap (Execution Contract Input 2), a supplied timestamp that is not an instant, a future or backdated-before-[Submission Instant] timestamp. A guard rejection that writes nothing.

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

The rejection any write action returns when the underlying database write fails after all preconditions pass. No [Step Id] is issued on [Submit]; a resolving action leaves the step in [Pending].

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: storage-failure

### Submit

#### Submit

The behavior that records a new approval gate. It assigns a fresh [Step Id], records [Subject Reference], [Approver Reference], [Submitter Reference], [Scope], [Reason] (if supplied), and [Submission Instant], enters the step in [Pending], and returns the [Step Id] (or a rejection naming the failed precondition).

Kind: Operation

```
submit(subject_ref, approver_ref, submitter_ref, scope, optional reason, optional submitted_at)
  answers step_id
  refuses invalid-request | storage-failure
```

```
Operation 1: IF subject reference EQUALS blank THEN [Submit] MUST answer invalid-request.
Operation 2: IF approver reference EQUALS blank THEN [Submit] MUST answer invalid-request.
Operation 3: IF submitter reference EQUALS blank THEN [Submit] MUST answer invalid-request.
Operation 4: IF scope EQUALS blank THEN [Submit] MUST answer invalid-request.
Operation 5: IF a carried reason EQUALS blank THEN [Submit] MUST answer invalid-request.
Operation 6: IF now PRECEDES the resolved submission instant THEN [Submit] MUST answer invalid-request.
Operation 63: IF the resolved submission instant is malformed THEN [Submit] MUST answer invalid-request (Execution Contract Input 1).
Operation 7: An admitted submit MUST record EXACTLY ONE step.
Operation 8: An admitted submit MUST stand the step in pending.
Operation 9: An admitted submit MUST answer the step id.
Operation 61: An admitted submit MUST record a supplied reason.
Operation 62: An admitted submit MUST record subject reference, approver reference, submitter reference, scope and the resolved submission instant as submission instant.
```

`submit(subject_ref: "je-0442", approver_ref: "dir_chen", submitter_ref: "controller_morgan", scope: "   ")` → invalid-request (Operation 4).

### Approve

#### Approve

The resolving behavior the named approver invokes to record the affirmative decision and move a [Pending] step to [Approved]. Permitted only when [Deciding Actor] matches [Approver Reference]; it stamps [Deciding Actor], [Decision Reason] (optional for an approval), and [Decision Instant]. On an already-terminal step it is rejected [Not Pending]; from any other actor it is rejected [Unauthorized].

Kind: Operation

```
approve(step_id, decided_by, optional reason, optional decided_at)
  answers approved
  refuses invalid-request | not-known | not-pending | unauthorized | storage-failure
```

```
Operation 24: An admitted approve MUST stand the step in approved.
Operation 27: An admitted approve MUST record deciding actor and the resolved decision instant as decision instant.
Operation 30: An admitted approve MUST record a supplied reason as decision reason.
Operation 57: IF a carried reason EQUALS blank THEN [Approve] MUST answer invalid-request.
```

`approve("step-001", decided_by: "controller_morgan")` → unauthorized. The submitter is not the approver, and the step stays pending with nothing written (Operation 21, Operation 36).

`approve("step-001", decided_by: "finance_director_chen")` against the already-approved step → not-pending. Not unauthorized, even though the caller is the right actor — the step refuses every resolving call, and saying so sends the caller to the right problem (Operation 13, Operation 20).

`approve("", decided_by: "finance_director_chen")` → invalid-request — a blank id is garbage, not a reference to a missing step (Operation 10, Execution Contract Refusal 1).

`approve("step-003", decided_by: "finance_director_chen", decided_at: "2020-01-01")` against a step submitted in 2026 → invalid-request. A decision cannot predate its submission (Operation 19).

### Reject

#### Reject

The resolving behavior the named approver invokes to record the negative decision and move a [Pending] step to [Rejected]. Requires a stated reason. Permitted only when [Deciding Actor] matches [Approver Reference]; it stamps [Deciding Actor], [Decision Reason], and [Decision Instant]. Its success token is rejected_outcome, distinct from the action's own rejection path. On an already-terminal step it is rejected [Not Pending]; from any other actor it is rejected [Unauthorized].

Kind: Operation

```
reject(step_id, decided_by, reason, optional decided_at)
  answers rejected_outcome
  refuses invalid-request | not-known | not-pending | unauthorized | storage-failure
```

```
Operation 16: IF reason EQUALS blank THEN [Reject] MUST answer invalid-request.
Operation 25: An admitted reject MUST stand the step in rejected.
Operation 28: An admitted reject MUST record deciding actor, reason as decision reason and the resolved decision instant as decision instant.
```

`reject("step-002", decided_by: "tax_director", reason: "   ")` → invalid-request. A rejection with no stated reason is not an audit record (Operation 16, Invariant 6.3).

### Withdraw

#### Withdraw

The resolving behavior the submitter invokes to retract a request and move a [Pending] step to [Withdrawn]. Requires a stated reason. Permitted only when [Withdrawing Actor] matches [Submitter Reference]; it stamps [Withdrawing Actor], [Withdrawal Reason], and [Withdrawal Instant]. On an already-terminal step it is rejected [Not Pending]; from any actor other than the submitter it is rejected [Unauthorized].

Kind: Operation

```
withdraw(step_id, withdrawn_by, reason, optional withdrawn_at)
  answers withdrawn
  refuses invalid-request | not-known | not-pending | unauthorized | storage-failure
```

```
Operation 17: IF reason EQUALS blank THEN [Withdraw] MUST answer invalid-request.
Operation 22: IF withdrawing actor DOES NOT EQUAL submitter reference THEN [Withdraw] MUST answer unauthorized.
Operation 26: An admitted withdraw MUST stand the step in withdrawn.
Operation 29: An admitted withdraw MUST record withdrawing actor, reason as withdrawal reason and the resolved decision instant as withdrawal instant.
```

### Read

#### Read

The read-only behavior that returns the steps matching a [Query], ordered by [Submission Instant] ascending with [Step Id] ascending as the tiebreaker. A well-formed [Query] matching no steps returns an empty sequence; a malformed one is rejected [Invalid Query]. It changes nothing.

Kind: Operation

```
read(query)
  answers the matching steps
  refuses invalid-query
```

```
Operation 38: An admitted read MUST answer the matching steps in submission instant ascending order.
Operation 39: An admitted read MUST order two steps sharing a submission instant by step id ascending (Execution Contract Logic confinement 10).
Operation 40: An admitted read MUST answer EVERY step matching the supplied filters.
Operation 41: An admitted read MUST NOT answer a step failing a supplied filter.
Operation 42: IF no step matching the supplied filters EXISTS THEN an admitted read MUST answer an empty step sequence.
Operation 44: IF a filter's axis IS NOT IN the filter axes THEN [Read] MUST answer invalid-query.
Operation 45: IF a filter's axis IS IN the string axes AND the filter's value EQUALS blank THEN [Read] MUST answer invalid-query.
Operation 46: IF a state filter's value IS NOT IN the states THEN [Read] MUST answer invalid-query.
Operation 47: IF a range filter's end PRECEDES the range's start THEN [Read] MUST answer invalid-query.
Operation 48: [Read] MUST NOT write.
Operation 58: IF the query is malformed THEN [Read] MUST answer invalid-query (Execution Contract Query 1).
Operation 66: IF a filter's value EXCEEDS the string cap THEN [Read] MUST answer invalid-query.
```

`read({subject_ref: "je-2026-0441", approver_email: "chen@…"})` → invalid-query. The key stands outside the nine axes and is refused rather than ignored (Operation 44).

#### Query

The selection a caller passes to [Read] to scope which steps are returned — any combination of the supported filter axes ([Step Id], [Subject Reference], [Approver Reference], [Submitter Reference], [Scope], [State], and a time range on [Submission Instant], [Decision Instant] or [Withdrawal Instant]). Consumed per call; never stored.

Kind:         Parameter
Parameter of: Read
Projection:   query

#### Invalid Query

The rejection [Read] returns when a filter is malformed — a blank string-axis value, a filter's value over the string cap, a [State] value outside the four states, a time range missing its start or its end, with end before start or with a start or an end that is not an instant, a value its field does not take (a time range on a field that is not an instant, or a single value on one that is), or an unrecognized filter key (rejected rather than silently ignored).

Kind:       Member
Member of:  the Read rejection
Role:       Outcome
Projection: invalid-query

## What is and what should never be (Invariants)

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
  Invariant 6.2: EVERY terminal step MUST carry the terminal instant.
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
  ```

---

## When something happens

### Indeterminate outcome

```
Indeterminate outcome 1: A caller receiving no answer MUST NOT retry BEFORE the landing read (Execution Contract Error model 1).
Indeterminate outcome 4: A deployment needing a lost [Submit] told from an earlier [Submit] carrying the same field set MUST compose an idempotency pattern (Non-goal 1).
```

## While something is so

### String policy

```
String 1: The atom MUST compare a string input byte-exactly.
String 2: The atom MUST NOT trim a string input.
String 3: The atom MUST NOT normalize a string input.
String 4: The atom MUST NOT case-fold a string input.
String 5: The atom MUST read a whitespace-only string input as blank.
String 6: The atom MUST read an absent string input that the signature does not mark optional as blank.
```

Term string input: a reference, reason OR a filter's value — every caller-supplied string this atom accepts.

NOTE: watch the cap's measure (Term string cap).

---

## Optional

```
Capability requirement 1: The deployment MUST supply now at the seam (Execution Contract Logic confinement 11).
Capability requirement 5: The deployment MUST supply the step records PER Execution Contract Database 1 through 5, Execution Contract Database 7, Execution Contract Read 1 through 4, Execution Contract Refusal 1, Execution Contract Query 1 through 4 and Execution Contract Input 1.
Capability requirement 6: The deployment MAY declare the string cap PER Execution Contract Input 2.
Capability requirement 7: The deployment MUST supply at the seam a step id no step in the database instance has carried PER Execution Contract Logic confinement 3 and Execution Contract Logic confinement 16.
```

Term database instance: one named database a call is routed to; step id uniqueness ranges over one instance.

Term seam: the atom's input/output boundary; the host injects the clock reading here on every call and the step id on a [Submit] alone.

Term transition: the atom's evaluation of one call against the step records.

Term now: the deployment's clock reading at the call, as Execution Contract Logic confinement 11 declares it.

Term business caller: the party whose action the call carries; never the source of an injected value.

Term query: what a read asks for — a [Query]; any combination of the filter axes, a filter on submission instant, decision instant or withdrawal instant carrying a range.

Term string cap: the bound on a string input's length in Unicode code points, counted PER Execution Contract Input 2 on a write input and PER Execution Contract Query 5 on a filter's value; 1,024 code points where a deployment declares none.

## Needs

The bonds this atom needs, of a bond kind [Bonds](../bonds.md) states; which atom meets each is the app's choice.

Term need key: key actor id; pairs steps.

## Offers

The bond this atom offers, of a bond kind [Bonds](../bonds.md) states.

Term offer key: key step id; carried by steps; calls Read.

## Left to others

```
Non-goal 1: The atom MUST NOT read two [Submit] calls carrying one field set as one step.
Deleted: Non-goal 2. Non-goal 1 owns it: the atom reads two submits of one field set as two steps, and which pattern makes a submission at-most-once is the app's choice.
Non-goal 3: The atom MUST NOT decide whether a subject's open gates are enough.
Deleted: Non-goal 4. Non-goal 3 owns it: the atom decides no quorum over a subject's gates, and which pattern does is the app's choice.
Non-goal 5: The atom MUST NOT bind a second actor to stand in for an approver reference.
Non-goal 6: A deployment needing delegation MUST compose a delegation pattern.
Non-goal 7: The atom MUST NOT confirm that a subject stands in an approvable state.
Non-goal 8: The atom MUST NOT interpret what an approved step permits.
Non-goal 9: The atom MUST NOT decide who may call an action.
Deleted: Non-goal 10. Non-goal 9 owns it: the atom decides no caller's authority; the app's permission does.
Non-goal 11: The atom MUST NOT notify an approver reference.
Deleted: Non-goal 12. Non-goal 11 owns it: the atom notifies no approver, and which pattern does is the app's choice.
Non-goal 13: The atom MUST NOT refuse a submitter reference matching the step's approver reference.
Non-goal 14: The atom MUST NOT bind a deciding actor to an actor.
Deleted: Non-goal 15. Non-goal 14 owns it: the atom binds no deciding actor to an actor, and which pattern attests an actor is the app's choice.
Non-goal 16: The atom MUST NOT detect a rewrite under the database.
Deleted: Non-goal 17. Non-goal 16 owns it: the atom detects no rewrite, and which pattern makes the records tamper-evident is the app's choice.
Non-goal 18: The atom MUST NOT declare which gates a subject requires.
Non-goal 19: The atom MUST NOT detect a subject carrying no step.
Non-goal 20: The atom MUST NOT bound submission instant from below.
Non-goal 21: A deployment needing a verifiable time anchor MUST compose a trusted timestamping pattern.
Non-goal 22: The atom MUST NOT own the clock's monotonicity (Execution Contract Logic confinement 7).
```

NOTE: the owners — an idempotency pattern (Non-goal 1, Non-goal 2); a quorum pattern (Non-goal 3, Non-goal 4; Non-goal 13, Composition note 3); Delegation *(forthcoming)* (Non-goal 5, Non-goal 6); the app's permission (Non-goal 9, Non-goal 10; Non-goal 13, Composition note 3); a notification pattern (Non-goal 11, Non-goal 12; Composition note 5); an attestation pattern (Non-goal 14, Non-goal 15); a tamper-evidence pattern (Non-goal 16, Non-goal 17); a gated-workflow pattern (Non-goal 7, Non-goal 8); the composing pattern that owns the required gate mapping (Non-goal 18, Composition note 10); the deployment (Non-goal 19, External check 2); Trusted Timestamping *(forthcoming)* (Non-goal 20, Non-goal 21).

---

```
Deleted: Composition note 1. Execution Contract Conformance 9 owns it: every deployment declares which composing patterns it wired in.
Composition note 2: A composing pattern MUST own the authorization of a call.
Composition note 3: A composing pattern MUST own the segregation policy over a submitter reference and an approver reference.
Composition note 4: A composing pattern MUST own the attestation binding a deciding actor.
Composition note 5: A composing pattern MUST own the notification of an approver reference.
Composition note 6: A composing pattern MUST own a quorum rule over two steps.
Composition note 7: A composing pattern MUST own the delegation of an approver reference.
Composition note 8: A composing pattern MUST own the tamper seal over the step records.
Composition note 9: A composing pattern MUST own at-most-once submission.
Composition note 10: A composing pattern MUST own the required gate mapping for a subject.
```

---

## Example

### SOX journal entry approval

A controller determines that posting JE-2026-0441 needs senior finance approval under SOX section 404 controls. `submit(subject_ref: "je-2026-0441", approver_ref: "finance_director_chen", submitter_ref: "controller_morgan", scope: "financial:journal-entry:post")` → `step-001`, standing in pending (Operation 7 through 9).

The finance director approves: `approve("step-001", decided_by: "finance_director_chen", reason: "Reviewed and approved — posting authorized")` → approved. The step stands in approved, carrying deciding actor, decision reason and decision instant (Operation 24, Operation 27, Operation 30).

An auditor later runs `read({subject_ref: "je-2026-0441", state: approved})` and sees who submitted, who approved, when, and why. The control evidence is provable from the record.

Or the director finds a misclassification: `reject("step-001", decided_by: "finance_director_chen", reason: "General ledger account 4120 is incorrect — should be 4130 per revenue recognition policy")` → rejected_outcome. The composing workflow routes the entry back, and the corrected entry needs a new [Submit] — this step is closed (Invariant 3.1, State 4).

Or the controller catches a routing error first: `withdraw("step-001", withdrawn_by: "controller_morgan", reason: "Wrong approver — cross-border entries route to tax_director")` → withdrawn, and `step-002` carries the right approver reference.

### Multiple gates on one subject

The three endings above are three alternative histories of step-001, not one sequence: run in order on one step, the second and third would answer not-pending (Operation 13).

A cross-border entry needs both finance and tax sign-off. Two [Submit] calls produce `step-010` and `step-011` on the same subject reference, each with its own approver reference. Approving one leaves the other pending and untouched (Invariant 9.1). Whether the subject has any open gate is `read({subject_ref: X, state: pending})` — a non-empty answer means at least one gate is open. Whether *both* were required, and whether two approvals are enough, is another pattern's (Non-goal 3).

### Regulated adversarial scenarios

- **Regulator audit.** A SOX section 404 examiner asks for evidence that the materiality control operated on a sample of entries. `read({scope: "financial:journal-entry:post", submitted_at: {start: …, end: …}})` answers the gates with full attribution, and Check 2.1 through 3.5 are what make each one usable. What the atom cannot answer is which entries *should* have had a gate and did not — that comparison needs the transaction set, which lives outside (Non-goal 18, External check 2).
- **Disputed approval.** A director denies approving an entry under an FDA Part 11 signature challenge. The record shows deciding actor equal to approver reference, byte for byte, with the instant and the reason. That proves the call carried their reference and proves nothing about who made the call — the cryptographic binding is another pattern's, and the atom says so rather than letting the record be read as a signature (Non-goal 14, External check 3).
- **Breach forensics.** An investigator examining unauthorized approval attempts finds that the database holds no record of them: a refused call writes nothing (Operation 36, Operation 37), so unauthorized attempts leave no trace here at all. The attempt log is the composing another pattern's, and these records' contribution is the negative evidence — every decision that *did* land, fully attributed (External check 4).

---

## Source

- **Sarbanes-Oxley section 404 (15 U.S.C. (United States Code) section 7262)** — internal control over financial reporting. The approval step is the structural form of a financial reporting control: a gate that must be cleared before a material action proceeds, with an auditable record of who cleared it. SOX auditors reviewing control evidence query approval step records directly; Invariants 4, 6, and 8 are the structural guarantees the evidence must carry.
- **FDA 21 CFR Part 11 (Electronic Records; Electronic Signatures)** — for FDA-regulated contexts (pharmaceutical manufacturing, clinical trials, medical device quality systems): each approval step by a named actor is the record an electronic signature on the action is linked to. Part 11 section 11.50 requires that electronic signatures are attributable to one individual and section 11.70 requires that they are linked to their respective records to prevent removal, substitution, or falsification. Composition with an attestation pattern provides the cryptographic binding; composition with a tamper-evidence pattern provides the linking and non-falsifiability. The Approval Step record is the gate; the composition is the compliant electronic signature system.
- **ICH (International Council for Harmonisation of Technical Requirements for Pharmaceuticals for Human Use) E6(R3) Good Clinical Practice — Guideline** — the international standard for clinical trial conduct. Section 4 (Investigator's Responsibilities) and Section 5 (Sponsor's Responsibilities) require documented approval steps at multiple points in the trial lifecycle: investigator approval of protocol deviations, IRB (Institutional Review Board) approval of informed consent amendments, sponsor approval of site qualification assessments. Each maps to an Approval Step record whose [Scope] identifies the specific Good Clinical Practice obligation.
- **ISO 9001:2015 clause 8.5.1 (Control of production and service provision)** — the International Organization for Standardization's quality-management standard; requires that production and service provision activities be controlled by documented procedures including approval of documents, products, and services at defined points. Approval steps are the documented approval records section 8.5.1 anticipates; the atom's immutability invariants satisfy the document control requirements.
- **ISO 13485:2016 clause 4.2 (Documentation requirements)** — for medical device manufacturers: records of approval activities must be maintained. Approval Step records are the compliant implementation surface.

---

## Proof

### Generation acceptance

This atom's acceptance is provable: an external auditor clears it from the step records, with their committed versions (Execution Contract Generation acceptance 1).

#### Conformance checks

```
Check 1.1: An auditor MUST find EVERY step standing in EXACTLY ONE OF pending, approved, rejected, withdrawn (Invariant 2.1).
Check 2.1: An auditor MUST find EVERY step's step id, subject reference, approver reference, submitter reference and scope non-blank (Invariant 8.1).
Check 2.2: An auditor MUST find a submission instant on EVERY step (Invariant 8.2).
Check 3.1: An auditor MUST find EVERY terminal step's attribution reference non-blank (Invariant 6.1).
Check 3.2: An auditor MUST find the terminal instant on EVERY terminal step (Invariant 6.2).
Check 3.3: An auditor MUST find EVERY rejected step's decision reason non-blank (Invariant 6.3).
Check 3.4: An auditor MUST find EVERY withdrawn step's withdrawal reason non-blank (Invariant 6.4).
Check 3.5: An auditor MUST find no terminal step's terminal instant preceding the step's submission instant (Invariant 7.1).
Check 4.1: An auditor MUST find EVERY approved step's deciding actor equal to the step's approver reference (Invariant 4.1).
Check 4.2: An auditor MUST find EVERY rejected step's deciding actor equal to the step's approver reference (Invariant 4.2).
Check 4.3: An auditor MUST find EVERY withdrawn step's withdrawing actor equal to the step's submitter reference (Invariant 5.1).
Check 5.1: An auditor MUST find no attribution field on a pending step (State 13).
Check 6.1: An auditor MUST find an unfiltered read answering EVERY step with a committed version (Invariant 10.1; Execution Contract Generation acceptance 1).
Check 6.2: An auditor MUST find EVERY step's submission fields unchanged across EVERY committed version of the step (Invariant 1.1; Execution Contract Generation acceptance 1).
Check 6.3: An auditor MUST find no step leaving a terminal state across two committed versions of the step (Invariant 3.1; Execution Contract Generation acceptance 1).
```

NOTE: EVERY check names the rule the check tests.

Term committed version: a record as it stood at the commit that wrote it, as Execution Contract Generation acceptance 1 declares it.

#### External checks

```
External check 2: A deployment needing the subjects carrying no step identified MUST read the subject set beside the step records (Non-goal 19).
External check 3: A deployment needing a deciding actor bound to an actor MUST read the composing attestation pattern (Non-goal 14).
External check 4: A deployment needing a refused call's attempt recorded MUST read the composing audit pattern (Operation 37).
```

### Vocabulary

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is* and its **Kind**.

Term actors: the atom; the host; the transition; the deployment; a composing pattern; a business caller; a caller; a guard; an auditor; a regulator; an examiner; an investigator; an actor; an approver; a submitter; the database; a step; a pending step; a terminal step; an approved step; a rejected step; a withdrawn step; a resolving action; a deciding action; a writing action; a refused action; an action; a query; a filter; a state filter; a range filter; a string input; an opaque reference; the database instance's step count; an attribution check.

Term records: step — one authorization gate, carrying step id, subject reference, approver reference, submitter reference, scope, submission instant, a state and, where supplied or set, reason, deciding actor, decision reason, decision instant, withdrawing actor, withdrawal reason and withdrawal instant.

Term record verbs: identify, allocate, change, carry, stand, answer, record, set, take, leave, own, match, equal, normalize, interpret, confirm, admit, offer, detect, route, share, precede, follow, compare, order, trim, case-fold, refuse, write, read, find, complete, fall, bound, decide, declare, compose, wire, supply, remove, sort, name, notify, bind, choose, retry, permit, evaluate, call, require.

Term value sets: state = pending | approved | rejected | withdrawn.

Term bounds: string cap.

Term cadences: empty.

Term qualifiers: migrated — rewritten in GRACE lang v0.40 (2026-09-12).

Term terms: step, step id, subject reference, approver reference, submitter reference, scope, reference, database instance, seam, transition, now, business caller, states, terminal state, resolving action, deciding action, writing action, deciding reference, resolved decision instant, resolved submission instant, submission field, attribution field, attribution reference, terminal instant, attribution check, attribution fault, filter axes, string axes, query, carried reason, admitted submit, authorization anchor, admitted resolve, admitted approve, admitted reject, admitted withdraw, admitted read, matching steps, landing read, success token, committed version, string input, blank, string cap.

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

## Status

`doing` — see the Ledger.

<details markdown="block">
<summary>
    <h2 id="ledger" style="display: inline-block; margin-left: 1.5rem;">Ledger</h2>
</summary>

```
status: doing
formal: verified — approval-step.tla + 3 twins (2026-06-03); approval-step.als + 10 twins (the static data model, 2026-11-11: Invariant 2.1, 4.1, 4.2, 5.1, 6.1 through 6.4, 7.1, 8.1, 8.2 and State 13 checked on every record [Submit] or one admitted resolve leaves, Invariant 4 and 5 a cross-check with the TLA+ model; nothing testable in Alloy for Invariant 1, 3, 9 and 10: each compares a step with a later version of it or with a second step, which a single state cannot show, so they are the TLA+ model's); coverage 2026-11-10 (unit formal: more coverage for the yes votes): owes TLA+ checks of Invariant 1 and Invariant 3 (across steps); owed rows: Invariant 1; Invariant 3, 2026-11-11
last gate: 2026-11-26 — Final Critique 20, frozen at bd35b8ce — foundational count 1, cured, not clean, no sample (Term string cap restated a narrower measure than Execution Contract Input 2, now cited per Input 2 and Query 5; the omitted-reason, landing-read range, Term reference and Operation 18 reports were placed refining or refuted by rules the page and the method state, and their wording cures are in the same commit); 2026-11-20 — Final Critique 19, a delta round, one reader (Linus, opencode/beam-free), frozen at 05c032a5 — foundational count 0 after the blind second triage, clean, one sample (Linus's one foundational report, that Operation 61 obliges recording only a supplied reason and so leaves what an admitted submit with an omitted reason records unowned, and its four refining and two rhetorical reports were refuted or placed rhetorical by both triages on rules the page and the method state: Earned vocabulary 21 and 22 read a supplied optional input as non-blank and an omitted one as blank, State 8 makes the reason optional, Term records says a step carries a reason where supplied or set, the Reason entry names the field, Term attribution check lists Operation 57 and Term terminal state names the three terminal members, so no two conforming builds differ); 2026-11-20 — Final Critique 18, frozen at 6c79ec3 — foundational count 1 after the blind second triage, cured, not clean, no sample; 2026-11-20 — Final Critique 17, a delta round, frozen at 88bcb94 — foundational count 1, cured, not clean, no sample; 2026-11-20 — Final Critique 16, a delta round, frozen at 44b2d6a — foundational count 1, cured, not clean, no sample; 2026-11-05 — Final Critique 15, a delta round, frozen at 00843d2 — foundational count 0, clean, no sample; 2026-11-04 — Final Critique 14, a delta round, frozen at 075c6e4 — foundational count 1, cured by a held cure, not clean, no sample; 2026-11-03 — Final Critique 13, a delta round, frozen at 30a4db8 — foundational count 1, cured, not clean, no sample; 2026-11-02 — Final Critique 12, a delta round, frozen at e63380b — foundational count 1, cured, not clean, no sample; 2026-10-29 — Final Critique 11 — foundational count 0, clean, one sample

open: none
```

</details>

<details markdown="block">
<summary>
    <h2 id="decisions" style="display: inline-block; margin-left: 1.5rem;">Decisions</h2>
</summary>

Decisions are kept in [the pattern's history](./approval-step.hist.md#decisions), one dated entry for each turn the pattern took; everything smaller lives in the commit that made it: `git log -- atoms/approval-step.md`.

</details>

NOTE: End of Approval Step.
