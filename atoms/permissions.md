---
title: Permissions
parent: Atomic Concepts
has_toc: true
toc: true
---

# Permissions

<details markdown="block">
<summary>Table of contents</summary>
{: .text-delta }
1. TOC
{:toc}
</details>


## Summary

Permissions answers one question: "is this actor allowed to do this thing right now?" It works through grants — explicit records that tie a subject (the actor wanting access) to an action scope (the set of operations the grant covers). A grant stays in force until it is revoked, and revocation is immediate and permanent. Checking permission is a pure read-only lookup. If any active grant matches the subject and scope being asked about, the answer is "permitted"; otherwise it is "denied." There is no implicit access — no grant means no permission, always. The whole decision rests on stored records, so any auditor can re-run the same check and get the same answer. That is exactly what regulated access control needs: issue a grant when access is authorized, revoke it when it ends, check on every attempt, and the records show who could do what, from when to when. The pattern deliberately leaves out roles, attribute-based policies, scope hierarchies, delegation, and time-limited grants. Each is a separate pattern built on top of this minimal grant store.

---

## Intent

WHY:
*May this actor do this thing?* is the question every regulated system answers a thousand times a second, and the wrong shapes for it are everywhere: a boolean column, a role string parsed at the call site, a policy engine nobody can audit. This atom is the smallest honest answer — a grant is a record binding a subject to a scope, it is in force or withdrawn, and the query is satisfied by any live grant matching the pair. Two decisions carry it. Absence is denial, so there is no explicit deny to reconcile against an allow and no ordering to get wrong. And a subject may hold many independent grants over one scope, each with its own id and its own revocation, because two administrators granting the same access on two days is two facts, and collapsing them makes selective revocation impossible and the audit trail unreadable. Roles, attributes, hierarchies, expiry and delegation are all real and all compose; none of them is this.

## Structure

### Identity model

```text
Identity 1: The atom MUST identify a grant by the grant_id.
Identity 2: The host MUST allocate a grant_id at the atom's seam.
Identity 3: The transition MUST NOT allocate a grant_id.
Identity 4: The business caller MUST NOT supply a grant_id.
Identity 5: The atom MUST NOT reuse a grant_id.
Identity 6: The atom MUST NOT identify a grant by the subject_ref with the action_scope.
Identity 7: A subject_ref MAY hold two active grants over one action_scope.
Identity 8: [Revoke] MUST reach EXACTLY ONE grant.
```

Terms › `grant record`: one recorded binding of a subject to a scope; [Grant] the marker names the operation that writes one, and the two are not the same concept (council read 15).

Terms › `grant_id`: the opaque value naming one grant — a [Grant Id]; the handle revocation takes.

Terms › `subject_ref`: the opaque reference naming who holds the grant — a [Subject Ref]; the actor registry is a separate concept.

Terms › `action_scope`: the opaque reference naming what the grant covers — an [Action Scope]; matched exactly, and the composing system owns the vocabulary.

Terms › `seam`: the atom's I/O boundary as `execution-contract.md` §Logic confinement declares it; the host injects the clock reading and the grant_id here.

Terms › `transition`: the atom's evaluation of one call against the grant store, as `execution-contract.md` §Logic confinement declares it.

Terms › `business caller`: the party whose action the call carries, as `execution-contract.md` §Logic confinement declares it; never the source of an injected value.

Terms › `now`: the wall-time reading the host takes at the seam and hands to the transition, as `execution-contract.md` §Logic confinement declares it; never read inside the transition, never supplied by the business caller.

WHY:
Many grants over one pair is the deliberate opposite of [Subscription](./subscription.md)'s at-most-one, and the reason is the audit question each atom answers: a second subscription means a duplicate notification, while a second grant means a second authorization with its own issuer, date and reason (Identity 7). Collapsing them by identifying on the pair would make revoking one revoke all, and would erase which grant authorized which access (Identity 6, Identity 8).

### String input policy

```text
String 1: The atom MUST compare a string input byte-exactly.
String 2: The atom MUST NOT trim a string input.
String 3: The atom MUST NOT normalize a string input.
String 4: The atom MUST NOT case-fold a string input.
String 5: The atom MUST read a whitespace-only string as empty.
String 6: IF a string input EXCEEDS the string cap THEN [Grant] MUST answer invalid-request.
String 7: [Check] MUST read an over-length string input as matching nothing.
```

Terms › `string cap`: the deployment's bound on a string input's length; a cap of zero refuses every [Grant], which is the degenerate configuration a deployment owns rather than a state the atom admits.

WHY:
Byte-exact and nothing else. A scope vocabulary that needs case-insensitivity or normalization has a vocabulary the composing system owns, and an atom that quietly folded case would make `Documents:Read` and `documents:read` the same authorization in a system that meant them differently (String 1–4).

### State

```text
State 1: EVERY grant MUST stand in EXACTLY ONE OF active, revoked.
State 2: EVERY grant MUST carry grant_id, subject_ref, action_scope, granted_at and status.
State 3: A revoked grant MUST carry revoked_at.
State 4: [Grant] MUST stamp granted_at from the injected now.
State 5: [Revoke] MUST stamp revoked_at from the injected now.
State 6: The atom MUST NOT offer a revoked-to-active transition.
NOTE: State 7 deleted — Invariant 10.1 owns durability.
NOTE: State 8 deleted — Non-goal 1 owns it.
NOTE: State 9 deleted — Non-goal 3 owns it.
NOTE: State 10 deleted — Non-goal 6 owns it.
```

Terms › `status`: `active` | `revoked` — in force, or withdrawn and terminal.

Terms › `granted_at`: the instant the grant was recorded — a [Granted At].

Terms › `revoked_at`: the instant the grant was withdrawn — a [Revoked At].

WHY:
There is no stored denial, because absence is denial (Invariant 7.1) — an explicit deny would need a precedence rule against every allow, and precedence is where authorization systems go wrong. A revoked grant stays in the store because *who could do what, when* is the question the store exists to answer, and deleting the grant deletes the answer (State 7, Invariant 10.1).

### Operations

```
grant(subject_ref, action_scope) → grant_id | rejected(invalid-request | storage-failure)
revoke(grant_id) → ok | rejected(not-known | not-active | storage-failure)
permitted(subject_ref, action_scope) → permitted | denied
```

```text
Operation 1: [Grant] MUST record EXACTLY ONE grant per successful call.
Operation 2: [Grant] MUST stand the grant in active.
Operation 3: [Grant] MUST answer grant_id.
Operation 4: IF subject_ref is empty THEN [Grant] MUST answer invalid-request.
Operation 5: IF action_scope is empty THEN [Grant] MUST answer invalid-request.
Operation 6: [Grant] MUST NOT refuse a pair an active grant already covers.
Operation 7: IF the store refuses the write THEN [Grant] MUST answer storage-failure.
Operation 8: [Grant] MUST NOT record a partial grant.
Operation 9: IF the grant_id NOT EXISTS THEN [Revoke] MUST answer not-known.
Operation 10: IF the grant stands in revoked THEN [Revoke] MUST answer not-active.
Operation 11: [Revoke] MUST stand the grant in revoked.
Operation 12: [Revoke] MUST commit the active-to-revoked move as one write.
Operation 13: IF the store refuses the write THEN [Revoke] MUST answer storage-failure.
Operation 14: [Revoke] MUST leave the grant standing in active on storage-failure.
Operation 15: A caller MUST read storage-failure from [Revoke] as the grant standing in force.
Operation 16: [Check] MUST answer EXACTLY ONE OF permitted, denied.
Operation 17: [Check] MUST answer permitted ONLY IF an active grant matches the pair.
Operation 18: [Check] MUST answer denied for a pair no active grant matches.
Operation 19: [Check] MUST NOT refuse a call.
Operation 20: [Check] MUST NOT write.
Operation 21: [Check] MUST match a subject_ref exactly.
Operation 22: [Check] MUST match an action_scope exactly.
Operation 23: The host MUST read the clock at the atom's seam.
Operation 24: The transition MUST NOT read a clock.
Operation 25: The business caller MUST NOT supply now.
```

Terms › `pair`: one `subject_ref` with one `action_scope` — what [Check] matches over.

Terms › `live at an instant`: `granted_at` at or before the instant, and `revoked_at` either absent or after the instant — the reconstruction an auditor runs over stored fields, never over `status`, which carries the present rather than the past.

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the grant store |
|---|---|---|---|
| [Grant] | refs present, store accepts | `grant_id` | one grant lands in [Active] (Operation 1, Operation 2) |
| [Grant] | empty or whitespace-only ref, or over the cap | [Invalid Request] | none (Operation 4, Operation 5, String 6) |
| [Grant] | the pair already has a live grant | `grant_id` | a second, independent grant lands (Operation 6, Identity 7) |
| [Grant] | store refuses the write | [Storage Failure] | none — no partial record (Operation 7, Operation 8) |
| [Revoke] | id names a live grant | `ok` | [Active] → [Revoked], `revoked_at` stamped (Operation 11, State 5) |
| [Revoke] | id names a revoked grant | [Not Active] | none — and the answer a retry of a landed revoke gets (Operation 10) |
| [Revoke] | id names nothing | [Not Known] | none (Operation 9) |
| [Revoke] | store refuses the write | [Storage Failure] | none — **the subject keeps the access** (Operation 13–15) |
| [Check] | a live grant matches the pair | [Permitted] | none — the call reads (Operation 17, Operation 20) |
| [Check] | nothing matches, over-length argument included | [Denied] | none (Operation 18, String 7) |

WHY:
The two storage failures are not the same failure. A failed [Grant] leaves a record missing, which the caller discovers the next time the subject is denied; a failed [Revoke] leaves a subject holding access the organization has decided to remove, and a caller that reads it as *probably fine* has left the door open (Operation 15, Revoke persistence 1–4). [Check] refuses nothing: a malformed argument matches no grant, and the correct answer to *may this actor do this thing* is then `denied` rather than an error the call site has to interpret (Operation 19, String 7).

### Invariants

- **Invariant 1 — Grant immutability.**
  ```text
  Invariant 1.1: A recorded grant's grant_id, subject_ref, action_scope and granted_at MUST NOT change.
  Invariant 1.2: The atom MUST stamp granted_at once.
  ```
- **Invariant 2 — Status monotonicity.**
  ```text
  Invariant 2.1: A status MUST move from active to revoked.
  Invariant 2.2: A status MUST NOT move from revoked to active.
  ```
- **Invariant 3 — Revocation is terminal.**
  ```text
  Invariant 3.1: [Revoke] MUST answer not-active for a revoked grant.
  Invariant 3.2: [Check] MUST NOT answer permitted on a revoked grant.
  ```
- **Invariant 4 — Id stability.**
  ```text
  Invariant 4.1: [Grant] MUST set the grant_id.
  Invariant 4.2: A grant_id MUST NOT change.
  ```
- **Invariant 5 — No id reuse.**
  ```text
  Invariant 5.1: Two grants MUST NOT share a grant_id.
  ```
- **Invariant 6 — Evaluation self-containment.**
  ```text
  Invariant 6.1: [Check] MUST rest on the active grant set alone.
  Invariant 6.2: [Check] MUST NOT consult a source outside the active grant set.
  ```
- **Invariant 7 — Denial by absence.**
  ```text
  Invariant 7.1: [Check] MUST answer denied ONLY IF no active grant matches the pair.
  ```
- **Invariant 8 — Revoked grants confer no permission.**
  ```text
  Invariant 8.1: A revoked grant MUST NOT stand in the active grant set.
  ```
- **Invariant 9 — Timestamp ordering.**
  ```text
  Invariant 9.1: IF revoked_at EXISTS THEN granted_at MUST NOT EXCEED revoked_at.
  Invariant 9.2: A grant MUST stand in force at an instant ONLY IF the grant is live at the instant.
  ```
  WHY: best-effort under a clock that moves backward; the deployment owns clock discipline (Clock semantics 1–3).
- **Invariant 10 — Grant store durability.**
  ```text
  Invariant 10.1: The atom MUST NOT delete a grant record.
  Invariant 10.2: The grant set MUST NOT shrink.
  Invariant 10.3: A storage-failure from [Grant] MUST NOT leave a partial grant.
  ```

Self-containment and denial-by-absence give the *determinism* property — one query against one active set answers one way, always. Immutability and monotonicity give *auditability* — the authorization history is the store, with no recourse to logs or narration.

## Examples

The same atom, five domains, identical mechanic.

### Banking — segregation of duties on high-value transfers

Regulatory policy requires that no single employee can both initiate and approve a wire transfer above $25,000. Two grants are issued at onboarding: `grant(teller_t9, initiate:transfer) → grant_id g1` and `grant(supervisor_s4, approve:transfer) → grant_id g2`. When teller_t9 attempts to approve their own wire, the system calls `permitted(teller_t9, approve:transfer)` — `denied`. Only supervisor_s4 holds an active grant covering `approve:transfer`. SOX (Sarbanes-Oxley Act) requires this segregation to be demonstrable from records; the grant store is that demonstration.

### Healthcare — HIPAA minimum necessary access

A hospitalist physician is granted access to records for patients under their direct care: `grant(dr_chen, records:ward-7-patients) → g14`. A billing clerk holds a narrower grant: `grant(clerk_b3, records:billing-fields-only) → g22`. When the billing clerk attempts to open a full patient chart, `permitted(clerk_b3, records:ward-7-patients)` returns `denied`. When Dr. Chen's patient is discharged and transferred, the hospitalist grant is revoked: `revoke(g14)`. Subsequent `permitted` queries for Dr. Chen return `denied` for that ward's records. HIPAA (US Health Insurance Portability and Accountability Act) §164.312(a)(1) requires access controls that limit access to the minimum necessary; the grant store is the audit surface.

### Payments — PCI DSS restricted cardholder data access

PCI DSS (Payment Card Industry Data Security Standard — the card networks' mandatory security rules for handling cardholder data) Requirement 7 mandates that access to cardholder data be restricted to individuals whose job requires it. A fraud analyst is granted access: `grant(analyst_a6, cardholder-data:read) → g31`. A customer service representative is not granted this scope; `permitted(rep_r12, cardholder-data:read)` returns `denied`. When the analyst rotates teams, the grant is revoked: `revoke(g31)`. A QSA (Qualified Security Assessor — a PCI-certified auditor) audit calls `permitted` for every employee against the cardholder-data scope and expects to see `denied` for all but the explicitly granted staff; the revocation record shows when access was removed.

### Legal — role-based document access in a matter

A law firm's document management system grants associates access to documents in matters they are staffed on. `grant(associate_j, documents:matter-2024-91) → g55`. A partner on a different matter is not staffed: `permitted(partner_k, documents:matter-2024-91)` → `denied`. When the associate is rolled off the matter, `revoke(g55)` — subsequent access denied. Opposing counsel's discovery request asks the firm to demonstrate who had access to the matter documents and when access was withdrawn; the grant store provides the timeline.

### Source control — branch protection in regulated software

An FDA-regulated (US Food and Drug Administration — the federal agency regulating drugs and medical devices) medical-device team restricts merge access to the `release` branch. `grant(release_engineer_r, branch:release:merge) → g88`. Developers hold only `branch:feature:merge` grants. `permitted(developer_d, branch:release:merge)` → `denied`. When the release engineer changes roles, `revoke(g88)`; a new engineer is issued a fresh grant: `grant(new_release_engineer_n, branch:release:merge) → g91`. The FDA's 21 CFR (Code of Federal Regulations — the codification of US federal agency rules) Part 11 software validation requirements are satisfied in part by demonstrating that only authorized personnel can modify the release artifact; the grant store is that demonstration.

The mechanic is identical across all five. What differs: the scope vocabulary (account:approve vs. records:ward-7 vs. cardholder-data:read vs. documents:matter vs. branch:release:merge), the lifecycle of grants (long-lived role grants vs. short-lived patient-panel grants), the regulatory consequence of [Denied], and the composing patterns active around it (Actor Identity for grantor attribution, Event Log for access-attempt logging, Retention Window for how long the grant store must be kept).

### Regulated adversarial scenarios

Three scenarios the atom must survive in regulated contexts:

- **Regulator audit — who has access to what.** A HIPAA auditor asks *"which staff have access to full patient records?"* The auditor queries the grant store for all [Active] grants covering the patient-records scope. The grant store answers from stored fields alone — [Subject Ref], [Action Scope], [Granted At], [Status] — with no recourse to developer narration. Invariants 1, 6, and 7 are the structural answer: evaluation is self-contained; every active grant is observable; absence of a grant means denial.
- **Disputed access — was this actor permitted at the time of the action?** An actor claims they were not authorized to access a resource at a specific time. The investigator queries the grant store for grants where `subject_ref = actor_ref` and `action_scope = contested_scope` with `granted_at ≤ time_of_action` and (`revoked_at IS NULL OR revoked_at > time_of_action`). The timestamp-based form is preferred over `status = active` because [Status] reflects current state, not historical state — a grant revoked after the time of action has `status = revoked` now but was active then; the timestamp condition captures it correctly. A grant matching those criteria is the structural answer: the actor held an [Active] grant at the time of the action. Invariant 1.1 and Invariant 9.2 are what make the reconstruction answerable from the records; Invariant 9.1's ordering is best-effort under a clock that moves backward, so the reconstruction is as good as the deployment's clock discipline (Clock semantics 1).
- **Privilege escalation investigation — unauthorized access attempt.** A security incident suggests an actor accessed a resource beyond their grant. The investigator runs the same reconstruction the disputed-access scenario uses — the grants live at the time of the incident (`live at an instant`) — because [Check] answers only about now and the atom offers no query over a past instant (Invariant 6.1, Invariant 9.2). An empty reconstruction confirms no grant was in force — any access that occurred did so by circumventing the authorization surface, which is the security incident's scope, not the atom's. The grant store's integrity determines whether the authorization record can be trusted; composing with Tamper Evidence makes that determination structural.

---

## Generation acceptance

This atom's acceptance is what an external auditor can clear from the grant store's stored fields, with no recourse to source code, runbooks or developer narration.

### Conformance checks

```text
Check 1.1: An auditor MUST read EVERY grant's grant_id, subject_ref, action_scope, granted_at and status from the store (State 2).
Check 1.2: An auditor MUST read revoked_at on EVERY revoked grant (State 3).
Check 2.1: An auditor MUST reconstruct the grant set in force at a past instant from granted_at and revoked_at (Invariant 9.2).
Check 3.1: An auditor MUST find denied for a pair no active grant matches (Operation 18).
Check 3.2: An auditor MUST find no permitted answer whose matching active grant NOT EXISTS (Invariant 7.1).
Check 4.1: An auditor MUST find no grant whose status moved out of revoked (Invariant 2.2, Invariant 3.1).
Check 5.1: An auditor MUST find the grant set never shrinking across two readings (Invariant 10.1, Invariant 10.2).
Check 6.1: An auditor MUST identify which composing patterns a deployment wired in (Composition note 1).
```

### External checks

```text
External check 1: An auditor MUST read who issued a grant from the composing [Actor Identity](./actor-identity.md) attestations (Non-goal 9).
External check 2: An auditor MUST read whether an access was attempted from the composing [Event Log](./event-log.md) records (Non-goal 11).
External check 3: An auditor MUST read a departing subject's full revocation from the composing pattern's deprovisioning records (Deprovisioning 2, Deprovisioning 3, Deprovisioning 4).
External check 4: An auditor MUST read the serialization evidence for concurrent revokes from the deployment's own concurrency probe (Operation 12).
```

NOTE: EVERY check names the rule the check tests. The grant store answers *who could do what, and since when*; who authorized it, who tried, and whether a leaver's access was fully removed are the composing patterns' records.

## Non-goals

```text
Non-goal 1: The atom MUST NOT hold a role.
Non-goal 2: A deployment needing roles MUST NOT call [Grant] BEFORE the deployment resolves the role to grants.
Non-goal 3: The atom MUST NOT evaluate an attribute policy.
Non-goal 4: The atom MUST NOT expand a scope hierarchy.
Non-goal 5: The atom MUST NOT match a scope pattern.
Non-goal 6: The atom MUST NOT record an explicit denial.
Non-goal 7: The atom MUST NOT model a delegation.
Non-goal 8: The atom MUST NOT expire a grant.
Non-goal 9: The atom MUST NOT record who issued a grant.
Non-goal 10: A deployment needing grantor attribution MUST compose [Actor Identity](./actor-identity.md).
Non-goal 11: The atom MUST NOT record a [Check] call.
Non-goal 12: A deployment needing access-attempt records MUST compose [Event Log](./event-log.md).
Non-goal 13: The atom MUST NOT authenticate the caller.
Non-goal 14: The atom MUST NOT bind a subject_ref to the authenticated caller.
Non-goal 15: The atom MUST NOT revoke a subject's grants in bulk.
Non-goal 16: The atom MUST NOT carry a grant across trust domains.
```

WHY:
Roles and attributes are the two shapes people reach for first, and both compose: a role is a name the composing system resolves into grants before it calls, and an attribute policy is a pattern that decides and then grants (Non-goal 1–3). Explicit deny is refused on purpose — a deny that overrides an allow needs a precedence rule, and precedence is the part of an authorization system that is wrong in production (Non-goal 6, Invariant 7.1). The binding between the authenticated caller and the `subject_ref` passed to [Check] is the composing system's, and getting it wrong is how a correct authorization atom authorizes the wrong person (Non-goal 13, Non-goal 14).

Where the atom breaks down: when the scope vocabulary needs hierarchy or wildcards; when evaluation must reason about the resource's attributes at call time; when a grant must end on its own without anyone revoking it; when the grantor's identity is part of the evaluation rather than beside it.

## Edge cases

### Revoke persistence failure

```text
Revoke persistence 1: A caller MUST read storage-failure from [Revoke] as the subject keeping the access.
Revoke persistence 2: A caller MUST retry a revoke that answered storage-failure.
Revoke persistence 3: A caller MUST read not-active from a retried revoke as the revocation standing.
Revoke persistence 4: A high-assurance deployment MUST raise a security alert on storage-failure from [Revoke].
```

WHY:
The two storage failures have opposite polarity. A failed grant withholds access somebody should have and surfaces as a complaint; a failed revoke leaves access somebody should not have and surfaces as nothing at all. That asymmetry is why the retry is an obligation rather than advice, and why `not-active` on the retry is the good answer rather than an error (Revoke persistence 2, Revoke persistence 3).

### Deprovisioning a subject

```text
Deprovisioning 2: A composing pattern MUST enumerate a departing subject's active grants.
Deprovisioning 3: A composing pattern MUST call [Revoke] for EVERY grant the enumeration returns.
Deprovisioning 4: A composing pattern MUST NOT read one revoke as a subject's deprovisioning.
NOTE: Deprovisioning 1 deleted — Identity 8 owns one revoke reaching one grant.
```

WHY:
This is the many-grants decision's bill. A composing pattern that revokes one grant and calls the subject gone leaves every other live grant intact — the subject still has access, the records say so plainly, and nobody looked (Deprovisioning 3, Identity 7, Identity 8).

### Grant concurrency and revoke concurrency

```text
Grant concurrency 1: Two concurrent [Grant] calls on one pair MUST record two grants.
Grant concurrency 2: A composing pattern intending one authoritative grant MUST guard against a concurrent issue.
Revoke concurrency 1: Two concurrent [Revoke] calls on one grant_id MUST NOT succeed together.
Revoke concurrency 2: The losing concurrent [Revoke] MUST answer not-active.
```

WHY:
The polarity is deliberate on both sides: grants do not race because two grants are a legitimate state, and revokes do race because two revocations of one grant are one revocation (Grant concurrency 1, Revoke concurrency 1, Operation 12).

### Clock semantics

```text
Clock semantics 1: The deployment MUST own the clock's monotonicity.
Clock semantics 2: The deployment MUST own the clock's timezone handling.
Clock semantics 3: A deployment needing a defensible timeline MUST compose a trusted-timestamping pattern.
```

## Composition notes

```text
Composition note 1: A deployment MUST declare which composing patterns the deployment wired in.
Composition note 2: A composing pattern MUST own the scope vocabulary.
Composition note 3: A composing pattern MUST own the binding between the authenticated caller and the subject_ref.
Composition note 4: A composing pattern needing grantor attribution MUST attest [Grant] under the grantor's credential.
Composition note 5: A composing pattern MUST own a departing subject's deprovisioning sweep.
```

WHY:
[Attributed Permissions Admin](../compositions/attributed-permissions-admin.md) is the landed wiring for attribution: every grant and revoke paired with an [Actor Identity](./actor-identity.md) attestation, so *who authorized this access* is a record rather than an inference — and the pairing lives in that composition, never as a field here (Composition note 4). [Shared Todo](../compositions/shared-todo.md) wires this atom with [Personal Todo](./personal-todo.md) and [Assignment](./assignment.md): the scope vocabulary is that composition's, the task is Personal Todo's, responsibility is Assignment's, and permission is this atom's (Composition note 2). Forthcoming: Role-Based Access Control, Attribute-Based Access Control, Temporal Grant, Delegation, Policy Layer, Identity Federation.

## Terms

Each `[Term]` marker above links to its card here; a card states what the concept *is* and its **Kind**.

### Vocabulary

Terms › `actors`: the atom; the host; the transition; the deployment (also: a high-assurance deployment); a composing pattern (also: a pattern); a business caller; a caller; a subject; an auditor; the store; a grant; a status.

Terms › `records`: `grant record` — one binding, carrying `grant_id`, `subject_ref`, `action_scope`, `granted_at`, `status` and, once withdrawn, `revoked_at`.

Terms › `record verbs`: identify, allocate, supply, reuse, hold, reach, compare, trim, normalize, case-fold, read, stand, carry, stamp, offer, delete, record, answer, refuse, leave, take, write, match, rest, consult, change, move, set, share, shrink, evaluate, expand, model, expire, authenticate, bind, revoke, retry, raise, enumerate, call, guard, succeed, compose, resolve, attest, own, declare, find, reconstruct, commit, exceed.

Terms › `value sets`: grant answers = grant_id | rejected(invalid-request | storage-failure). revoke answers = ok | rejected(not-known | not-active | storage-failure). permitted answers = permitted | denied. `status` = active | revoked.

Terms › `bounds`: `string cap` (the deployment's bound on a string input's length).

Terms › `cadences`: empty.

Terms › `qualifiers`: `migrated` — rewritten in GRACE lang v0.35 (2026-09-12).

Terms › `terms`: `grant record`, `live at an instant`, `grant_id`, `subject_ref`, `action_scope`, `seam`, `transition`, `business caller`, `now`, `string cap`, `status`, `granted_at`, `revoked_at`, `pair`.

#### Grant

The behavior an administrator or composing pattern invokes to record a new grant binding a [Subject Ref] to an [Action Scope]. It allocates a fresh [Grant Id], stamps [Granted At], records the grant in [Active], and returns the [Grant Id]. It always creates a new record — duplicate grants for the same (subject, scope) pair are independent records, each with its own id.

Kind: Operation

#### Revoke

The behavior that withdraws a recorded grant, by id. It moves the grant at [Grant Id] from [Active] to [Revoked] and stamps [Revoked At]. Revocation is terminal: a grant already in [Revoked] is rejected with [Not Active].

Kind: Operation

#### Check

The read-only behavior a composing pattern invokes before an action to evaluate whether a (subject, scope) pair holds an [Active] grant. It returns [Permitted] if any [Active] grant matches the queried [Subject Ref] and [Action Scope], otherwise [Denied]. It changes nothing and never rejects — both outcomes are first-class results. (Its projected contract lowers the verb to `permitted`, which is also the name of one of its two answers — `permitted(alice, read) → denied` is well-formed and reads oddly; the lowering is recorded here because the rules speak [Check] and the wire speaks `permitted`.)

Kind: Operation

#### Grant Id

The opaque, immutable identity of a grant, host-allocated at the I/O seam on [Grant] and never reused. The [Subject Ref] and [Action Scope] are properties of the grant, not its identity; the id is the handle [Revoke] uses.

Kind:     Field
Field of: Permissions
Projects: grant_id

#### Subject Ref

The opaque reference to *who* holds the grant — the subject the grant binds. The atom does not interpret it; the actor registry is a separate concept. Set on [Grant], immutable thereafter, and matched byte-exactly by [Check].

Kind:     Field
Field of: Permissions
Projects: subject_ref

#### Action Scope

The opaque reference to *what* the grant covers — the scope the grant binds. The composing system defines scope semantics; the atom does exact match on the value (no hierarchy or wildcard). Set on [Grant], immutable thereafter.

Kind:     Field
Field of: Permissions
Projects: action_scope

#### Granted At

The wall-time the grant was recorded, stamped from the injected [Now] on [Grant]. Immutable thereafter, and never re-derived from the current clock.

Kind:     Field
Field of: Permissions
Projects: granted_at

#### Status

The grant's lifecycle state — [Active] or [Revoked]. Set to [Active] on [Grant]; transitions one-way to [Revoked] on [Revoke].

Kind:     Field
Field of: Permissions
Projects: status

#### Revoked At

The wall-time the grant was revoked, stamped from the injected [Now] on [Revoke]. Absent while the grant is [Active]; set once on [Revoke] and never changed after.

Kind:     Field
Field of: Permissions
Projects: revoked_at

#### Now

The current wall-time reading the transitions stamp [Granted At] and [Revoked At] from, supplied to the pure transition by the host at the I/O seam (never read inside the transition, never supplied by the business caller).

Kind:         Parameter
Parameter of: Grant and Revoke
Projects:     now

#### Active

The state of a grant that is in force: it contributes to [Check] evaluations. A grant enters [Active] on [Grant] and leaves it only on [Revoke].

Kind:      Member
Member of: the grant state
Role:      Outcome
Projects:  active

#### Revoked

The state of a grant that has been withdrawn: it no longer contributes to [Check] evaluations. A grant enters [Revoked] on [Revoke]; the transition is terminal — there is no [Revoked] → [Active] path.

Kind:      Member
Member of: the grant state
Role:      Outcome
Projects:  revoked

#### Permitted

The outcome [Check] returns when at least one [Active] grant matches the queried [Subject Ref] and [Action Scope]. A first-class result, not a success-or-reject acknowledgement.

Kind:      Member
Member of: the Check outcome
Role:      Outcome
Projects:  permitted

#### Denied

The outcome [Check] returns when no [Active] grant matches the queried pair — denial by absence. A first-class result; empty or malformed inputs also resolve to [Denied], since they match no [Active] grant.

Kind:      Member
Member of: the Check outcome
Role:      Outcome
Projects:  denied

#### Invalid Request

The refusal [Grant] returns when [Subject Ref] or [Action Scope] does not contain at least one non-whitespace character. A guard rejection that fails before any store write; no grant is recorded.

Kind:      Member
Member of: the Grant rejection
Role:      Outcome
Projects:  invalid-request

#### Not Known

The refusal [Revoke] returns when the supplied [Grant Id] references no grant the store holds.

Kind:      Member
Member of: the Revoke rejection
Role:      Outcome
Projects:  not-known

#### Not Active

The refusal [Revoke] returns when the referenced grant is not in [Active] — it is already [Revoked]. This is what makes revocation terminal and what a serialized second concurrent revoke receives.

Kind:      Member
Member of: the Revoke rejection
Role:      Outcome
Projects:  not-active

#### Storage Failure

The refusal [Grant] or [Revoke] returns when the store write fails after all preconditions pass. For [Grant], no grant is recorded. For [Revoke], the grant remains [Active] — a security-critical state the caller must retry, never treat as a confirmed revocation.

Kind:      Member
Member of: the action rejection
Role:      Outcome
Projects:  storage-failure

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a [Term] marker to its card heading above (kramdown
     auto-generates the heading anchors on GitHub Pages). Standard CommonMark /
     kramdown; no plugin required. -->

[Grant]: #grant
[Revoke]: #revoke
[Check]: #check
[Grant Id]: #grant-id
[Subject Ref]: #subject-ref
[Action Scope]: #action-scope
[Granted At]: #granted-at
[Status]: #status
[Revoked At]: #revoked-at
[Now]: #now
[Active]: #active
[Revoked]: #revoked
[Permitted]: #permitted
[Denied]: #denied
[Invalid Request]: #invalid-request
[Not Known]: #not-known
[Not Active]: #not-active
[Storage Failure]: #storage-failure

---

## Standards references

Permissions is a foundational access-control primitive with wide regulatory anchoring:

- **NIST (National Institute of Standards and Technology — US federal standards body) SP 800-53 Rev. 5, AC family (Access Control)** — AC-2 (Account Management), AC-3 (Access Enforcement), AC-6 (Least Privilege), AC-17 (Remote Access). The atom's grant-based evaluation surface is the operational form of AC-3's access enforcement function.
- **NIST SP 800-207 (Zero Trust Architecture)** — least-privilege access per request, with explicit per-resource authorization. The atom's [Check] query per (subject, scope) is the structural form of per-request evaluation.
- **ISO/IEC 27001 §A.9 (Access Control)** — the International Organization for Standardization / International Electrotechnical Commission information-security standard; logical access control, user access management, review of user access rights. The grant store is the access-rights record §A.9.2 requires.
- **HIPAA §164.312(a)(1) (Technical Safeguards — Access Control)** — unique user identification, emergency access procedure, automatic logoff, encryption. The minimum-necessary principle (§164.514(d)) is operationalized as narrow action scopes. The grant store demonstrates compliance.
- **Sarbanes-Oxley §404 (Internal Control over Financial Reporting)** — segregation of duties, access controls on financial systems. The grant store's timeline (who had what access, from when to when) is the §404 evidence trail.
- **PCI DSS Requirement 7 (Restrict Access to System Components and Cardholder Data)** — need-to-know access, formal access authorization, denial by default. Invariant 7 (denial by absence) is the structural form of PCI DSS's default-deny posture.
- **GDPR (EU General Data Protection Regulation) Article 25 (Data Protection by Design and by Default)** — technical measures ensuring only necessary data is processed. Scoped grants are the technical measure; the grant store demonstrates the measure.
- **NIST SP 800-63-3 (Digital Identity Guidelines)** — the atom composes with Authentication (which supplies NIST IAL/AAL/FAL — Identity, Authenticator, and Federation Assurance Levels — assurance levels) and with Actor Identity (which records the authorization-to-grant event).

It inherits from:

- **Daniel Jackson, *The Essence of Software*** — freestanding-atom posture; the discipline of composing authentication, identity, role management, and policy evaluation as separate atoms rather than absorbing them.
- **Eiffel's design-by-contract** — preconditions on [Grant] and [Revoke]; named rejection reasons.
- **Lampson's access matrix** (1971) — the foundational formal model of access control as a matrix of (subject, object, right) triples. [Grant] adds a right to the matrix; [Revoke] removes it; [Check] queries it. The atom is the structured-natural-language realization of Lampson's core operations.
- **Graham-Denning model** — formal treatment of grant and revoke as eight first-class protection operations. Grant and revoke are two of Graham-Denning's eight; the atom isolates those two (plus evaluation) as the minimal authorization surface.

---


## Status

`grounded on Final Critique 4 — 2026-06-18` — see the Ledger.

## Ledger

```
status: grounded on Final Critique 4 — 2026-06-18
formal: verified — permissions.als + 1 twin, 2026-06-03
last gate: 2026-06-18 — Final Critique 4, fresh reader — clean

open: none
```


## Decisions

Directional changes only — the turns a future reader must know the pattern took, and why. Everything smaller lives in the commit that made it: `git log -- atoms/permissions.md`.

- **2026-09-12 — Rewritten in GRACE lang v0.35; nothing but language changed.** *Chose:* labelled rules in fenced blocks, the three actions as a signature block, the string policy as its own rule family, the ten invariant numbers unchanged, Generation acceptance as conformance checks plus external checks ahead of Non-goals, Non-goals and Edge cases as two sections, the transition table kept beside the rules as the case space. *Over:* the prose spec. *Because:* the migration plan, and this atom completes [Shared Todo](../compositions/shared-todo.md)'s constituent set — Personal Todo, Assignment and Permissions all migrated, which makes that composition the one with no inherited term collision to resolve.

NOTE: End of Permissions.
