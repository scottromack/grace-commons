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

Permissions answers one question: "is this actor allowed to do this thing right now?" It answers from grants — records that each tie a subject (the actor wanting access) to an action scope (the name of what the grant covers, matched exactly) — and the answer is "permitted" when a grant still in force matches the pair, and "denied" otherwise, so no grant means no permission, always. A grant stays in force until it is revoked: once a revocation is recorded, that grant no longer counts toward any answer and can never count again, while a revocation the database fails to record leaves the grant in force and tells the caller so, to retry. Grants are never deleted, and each keeps when it was granted and, once revoked, when it was revoked, so an auditor re-running a check against the same records gets the same answer, and the records show who could do what, from when to when. Each grant carries an identifier that means nothing by itself, supplied, like the clock reading, by the system running Permissions from outside Permissions' own logic. Roles, attribute-based policies, scope hierarchies, delegation and time-limited grants are left to separate patterns, and so are recording who issued a grant, logging attempts to act, and tying a signed-in user to the subject a grant names.

---

## Intent

<details markdown="block">
<summary>WHY</summary>

*May this actor do this thing?* is the question every regulated system answers a thousand times a second, and the wrong shapes for it are everywhere: a boolean column, a role string parsed at the call site, a policy engine nobody can audit. This atom is the smallest honest answer — a grant binds a subject to a scope, it is in force or withdrawn, and the query is satisfied by any active grant matching the pair. Two decisions carry it. Absence is denial, so there is no explicit deny to reconcile against an allow and no ordering to get wrong. And a subject may hold many independent grants over one scope, each with its own id and its own revocation, because two administrators granting the same access on two days is two facts, and collapsing them makes selective revocation impossible and the audit trail unreadable. Roles, attributes, hierarchies, expiry and delegation are all real and all compose; none of them is this.

</details>

## Structure

### Identity model

```
Identity 1: The atom MUST identify a grant by the grant id.
Identity 2: The host MUST allocate a grant id at the atom's seam.
Identity 3: The transition MUST NOT allocate a grant id.
Identity 4: The business caller MUST NOT supply a grant id to [Grant].
Deleted: Identity 5. Invariant 5.1 owns it.
Identity 6: The atom MUST NOT identify a grant by the subject reference with the action scope.
Identity 7: A subject reference MAY hold two active grants over one action scope.
Identity 8: [Revoke] MUST reach EXACTLY ONE grant.
```

NOTE: open 2026-10-26-a — the grant id's source is named as the host's allocation (Identity 2) and not among what the deployment supplies (Capability requirement 1, Capability requirement 4 through 6).

Term grant record: one recorded binding of a subject to a scope; [Grant] the marker names the operation that writes one, and the two are not the same concept (council read 15).

Term grant id: the opaque value naming one grant — a [Grant Id]; the handle revocation takes.

Term subject reference: the opaque reference naming who holds the grant — a [Subject Reference]; the actor registry is a separate concept.

Term action scope: the opaque reference naming what the grant covers — an [Action Scope]; matched exactly, and a composing pattern owns the vocabulary.

Term seam: the atom's I/O boundary as the section titled Logic Confinement Principle in `execution-contract.md` declares it; the host injects the clock reading and the grant id here.

Term transition: the atom's evaluation of one call against the grant records, as the section titled Logic Confinement Principle in `execution-contract.md` declares it.

Term business caller: the party whose action the call carries, as the section titled Logic Confinement Principle in `execution-contract.md` declares it; never the source of an injected value.

Term now: the deployment's clock reading at the call, as Execution Contract Logic confinement 11 declares it.

NOTE: open 2026-10-21-f — Term seam, Term transition and Term business caller cite the section titled Logic Confinement Principle in `execution-contract.md`, which declares none of them.

### State

```
State 1: EVERY grant MUST stand in EXACTLY ONE OF active, revoked.
State 2: EVERY grant MUST carry grant id, subject reference, action scope, grant instant and status.
State 3: A revoked grant MUST carry revocation instant.
State 4: [Grant] MUST stamp grant instant from the injected now.
State 5: [Revoke] MUST stamp revocation instant from the injected now.
Deleted: State 6. Invariant 2.2 owns it.
Deleted: State 7. Invariant 10.1 owns durability.
Deleted: State 8. Non-goal 1 owns it.
Deleted: State 9. Non-goal 3 owns it.
Deleted: State 10. Non-goal 6 owns it.
```

Term status: active | revoked — in force, or withdrawn and terminal.

Term grant instant: the instant the grant was recorded — a [Grant Instant].

Term revocation instant: the instant the grant was withdrawn — a [Revocation Instant].

### Capability requirement

```
Capability requirement 1: The deployment MUST supply now at the seam.
Capability requirement 4: The deployment MUST supply the grant records PER Execution Contract Database 1 through 4, Execution Contract Database 6, Execution Contract Read 1 through 4, Execution Contract Refusal 1 and Execution Contract Conformance 9.
Capability requirement 5: The deployment MUST supply the string cap.
Capability requirement 6: The deployment MUST NOT change the string cap for the life of the instance.
Deleted: Capability requirement 2. Execution Contract Logic confinement 7 owns it.
Deleted: Capability requirement 3. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 1. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 2. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 3. Non-goal 17 owns it.
```

### Operations

```
grant(subject_ref, action_scope)
  answers grant_id
  refuses invalid-request | storage-failure

revoke(grant_id)
  answers ok
  refuses not-known | not-active | storage-failure

permitted(subject_ref, action_scope)
  answers permitted | denied

read()
  answers every grant
```

NOTE: open 2026-10-26-b — the rules name the action [Check] and the signature block declares the action as permitted; only the Check entry, which carries no obligation, says the one is the other.

```
Operation 1: [Grant] MUST record EXACTLY ONE grant per successful call.
Operation 2: [Grant] MUST stand the grant in active.
Operation 3: [Grant] MUST answer grant id.
Operation 4: IF subject reference EQUALS blank THEN [Grant] MUST answer invalid-request.
Operation 5: IF action scope EQUALS blank THEN [Grant] MUST answer invalid-request.
Operation 6: [Grant] MUST NOT refuse a pair an active grant already covers.
Operation 7: IF the database refuses the write THEN [Grant] MUST answer storage-failure.
Deleted: Operation 8. Execution Contract Database 1 owns it.
Operation 9: IF no grant EXISTS for the grant id THEN [Revoke] MUST answer not-known.
Operation 10: IF the grant's status EQUALS revoked THEN [Revoke] MUST answer not-active.
Operation 11: [Revoke] MUST stand the grant in revoked.
Deleted: Operation 12. Execution Contract Database 1 and Execution Contract Database 2 own it.
Operation 13: IF the database refuses the write THEN [Revoke] MUST answer storage-failure.
Deleted: Operation 14. Execution Contract Database 3 owns it.
Operation 15: A caller MUST read storage-failure from [Revoke] as a grant whose status EQUALS active.
Operation 16: [Check] MUST answer EXACTLY ONE OF permitted, denied.
Operation 17: [Check] MUST answer permitted ONLY IF an active grant matches the pair.
Operation 18: [Check] MUST answer denied for a pair no active grant matches.
Deleted: Operation 19. Operation 16 and Execution Contract Read 2 own it.
Operation 20: [Check] MUST NOT write.
Operation 21: [Check] MUST match a subject reference exactly.
Operation 22: [Check] MUST match an action scope exactly.
Deleted: Operation 23. Capability requirement 1 owns it.
Deleted: Operation 24. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 25. Execution Contract Logic confinement 3 owns it.
Operation 26: [Read] MUST answer EVERY grant, active AND revoked.
Operation 27: [Read] MUST answer a grant's grant id, subject reference, action scope, grant instant, status AND revocation instant.
Operation 28: [Read] MUST NOT write.
Deleted: Operation 29. Operation 26 and Execution Contract Read 2 own it.
Deleted: Operation 30. Execution Contract Read 1 owns it.
Deleted: Operation 31. Execution Contract Read 1 owns it: after the read, every refusal rule of [Grant] before the write answers invalid-request.
Deleted: Operation 32. Execution Contract Refusal 1 owns it.
```

NOTE: open 2026-10-21-h — [Read] answers every grant in no stated order and with no bound on the answer (Operation 26, Operation 27).

Term pair: one subject reference with one action scope — what [Check] matches over.

Term grant set: every grant the database holds, active and revoked — what [Read] answers (Operation 26).

Term active grant set: the grants of the grant set whose status EQUALS active — what [Check] rests on (Invariant 6.1).

Term live at an instant: grant instant at or before the instant, and revocation instant either absent or after the instant — the reconstruction an auditor runs over stored fields, never over status, which carries the present rather than the past.

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the grant records |
|---|---|---|---|
| [Grant] | refs present, database accepts | grant id | one grant lands in [Active] (Operation 1, Operation 2) |
| [Grant] | empty or whitespace-only ref, or over the cap | [Invalid Request] | none (Operation 4, Operation 5, String 6) |
| [Grant] | refs present, an active grant already covers the pair, database accepts | grant id | a second, independent grant lands (Operation 6, Identity 7) |
| [Grant] | database refuses the write | [Storage Failure] | none (Operation 7) |
| [Revoke] | id names an active grant | ok | [Active] → [Revoked], revocation instant stamped (Operation 11, State 5) |
| [Revoke] | id names a revoked grant | [Not Active] | none — and the answer a retry of a landed revoke gets (Operation 10) |
| [Revoke] | id names nothing | [Not Known] | none (Operation 9) |
| [Revoke] | database refuses the write | [Storage Failure] | none — **the subject keeps the access** (Operation 13, Operation 15) |
| [Check] | an active grant matches the pair | [Permitted] | none — the call reads (Operation 17, Operation 20) |
| [Check] | nothing matches, over-length argument included | [Denied] | none (Operation 18, String 7) |
| [Read] | any call | every grant, with its stored fields | none (Operation 26 through 28) |
| any call | its read of the grant records fails | `state-unavailable` | none (Execution Contract Read 1, Execution Contract Read 3) |

Where two [Revoke] cases hold at once, the refusal listed first on [Revoke]'s refuses line answers (Execution Contract Refusal 1).

### Invariants

- **Invariant 1 — Grant immutability.**
  ```
  Invariant 1.1: A recorded grant's grant id, subject reference, action scope and grant instant MUST NOT change.
  Invariant 1.2: The atom MUST stamp grant instant once.
  ```
- **Invariant 2 — Status monotonicity.**
  ```
  Deleted: Invariant 2.1. State 1 owns it.
  Invariant 2.2: A status MUST NOT move from revoked to active.
  ```
- **Invariant 3 — Revocation is terminal.**
  ```
  Invariant 3.2: [Check] MUST NOT answer permitted on a revoked grant.
  Deleted: Invariant 3.1. Operation 10 owns it.
  ```
- **Invariant 4 — Id stability.**
  ```
  Invariant 4.1: [Grant] MUST set the grant id.
  Invariant 4.2: A grant id MUST NOT change.
  ```
- **Invariant 5 — No id reuse.**
  ```
  Invariant 5.1: Two grants MUST NOT share a grant id.
  ```
- **Invariant 6 — Evaluation self-containment.**
  ```
  Invariant 6.1: [Check] MUST rest on the active grant set alone.
  Invariant 6.2: [Check] MUST NOT consult a source outside the active grant set.
  ```
- **Invariant 7 — Denial by absence.**
  ```
  Invariant 7.1: [Check] MUST answer denied ONLY IF no active grant matches the pair.
  ```
- **Invariant 8 — Revoked grants confer no permission.**
  ```
  Invariant 8.1: A revoked grant MUST NOT stand in the active grant set.
  ```
- **Invariant 9 — Timestamp ordering.**
  ```
  Invariant 9.1: IF revocation instant DOES NOT EQUAL blank THEN revocation instant MUST NOT PRECEDE grant instant.
  Invariant 9.2: A grant MUST stand in active at an instant ONLY IF the grant is live at the instant.
  ```
- **Invariant 10 — Grant record durability.**
  ```
  Invariant 10.1: The atom MUST NOT delete a grant record.
  Deleted: Invariant 10.2. Invariant 10.1 owns it (Execution Contract Database 6).
  Deleted: Invariant 10.3. Execution Contract Database 1 owns it.
  ```

Self-containment and denial-by-absence give the *determinism* property — one query against one active set answers one way, always. Immutability and monotonicity give *auditability* — the authorization history is provable from the database.

## Examples

The same atom, five domains, identical mechanic.

### Banking — segregation of duties on high-value transfers

Regulatory policy requires that no single employee can both initiate and approve a wire transfer above $25,000. Two grants are issued at onboarding: `grant(teller_t9, initiate:transfer) → grant_id g1` and `grant(supervisor_s4, approve:transfer) → grant_id g2`. When teller_t9 attempts to approve their own wire, the system calls `permitted(teller_t9, approve:transfer)` — denied. Only supervisor_s4 holds an active grant covering `approve:transfer`. SOX (Sarbanes-Oxley Act) requires this segregation to be provable; the grant records are the proof.

### Healthcare — minimum necessary access

A hospitalist physician is granted access to records for patients under their direct care: `grant(dr_chen, records:ward-7-patients) → g14`. A billing clerk holds a narrower grant: `grant(clerk_b3, records:billing-fields-only) → g22`. When the billing clerk attempts to open a full patient chart, `permitted(clerk_b3, records:ward-7-patients)` returns denied. When Dr. Chen's patient is discharged and transferred, the hospitalist grant is revoked: `revoke(g14)`. Subsequent permitted queries for Dr. Chen return denied for that ward's records, since g14 was Dr. Chen's only grant over the scope (a second grant over it would keep the access, Identity 7). HIPAA (US Health Insurance Portability and Accountability Act) section 164.312(a)(1) requires access controls, and section 164.514(d) limits each use of patient records to the minimum necessary; the grant records are the audit surface.

### Payments — restricted cardholder data access

PCI DSS (Payment Card Industry Data Security Standard — the card networks' mandatory security rules for handling cardholder data) Requirement 7 mandates that access to cardholder data be restricted to individuals whose job requires it. A fraud analyst is granted access: `grant(analyst_a6, cardholder-data:read) → g31`. A customer service representative is not granted this scope; `permitted(rep_r12, cardholder-data:read)` returns denied. When the analyst rotates teams, the grant is revoked: `revoke(g31)`. A QSA (Qualified Security Assessor — a PCI-certified auditor) audit calls permitted for every employee against the cardholder-data scope and expects to see denied for all but the explicitly granted staff; the revocation record shows when access was removed.

### Legal — role-based document access in a matter

A law firm's document management system grants associates access to documents in matters they are staffed on. `grant(associate_j, documents:matter-2024-91) → g55`. A partner on a different matter is not staffed: `permitted(partner_k, documents:matter-2024-91)` → denied. When the associate is rolled off the matter, `revoke(g55)` — subsequent access denied. Opposing counsel's discovery request asks the firm to demonstrate who had access to the matter documents and when access was withdrawn; the grant records provide the timeline.

### Source control — branch protection in regulated software

An FDA-regulated (US Food and Drug Administration — the federal agency regulating drugs and medical devices) medical-device team restricts merge access to the `release` branch. `grant(release_engineer_r, branch:release:merge) → g88`. Developers hold only `branch:feature:merge` grants. `permitted(developer_d, branch:release:merge)` → denied. When the release engineer changes roles, `revoke(g88)`; a new engineer is issued a fresh grant: `grant(new_release_engineer_n, branch:release:merge) → g91`. The FDA's 21 CFR (Code of Federal Regulations — the codification of US federal agency rules) Part 11 software validation requirements are satisfied in part by demonstrating that only authorized personnel can modify the release artifact; the grant records are that demonstration.

The mechanic is identical across all five. What differs: the scope vocabulary (approve:transfer vs. records:ward-7-patients vs. cardholder-data:read vs. documents:matter-2024-91 vs. branch:release:merge), the lifecycle of grants (long-lived role grants vs. short-lived patient-panel grants), the regulatory consequence of [Denied], and the composing patterns active around it (Actor Identity for grantor attribution, Event Log for access-attempt logging, Retention Window for how long the grant records must be kept).

### Rejection paths

One sequence on the banking grants above, walking every refusal the atom answers:

- `grant(teller_t9, "   ")` → invalid-request: a whitespace-only action scope is blank, so no grant is recorded (Operation 5, String 5).
- `revoke(g7)` → not-known: no grant carries the id g7 (Operation 9).
- `revoke(g1)` → ok: g1 moves from [Active] to [Revoked], its revocation instant stamped from the injected now (Operation 11, State 5), and `permitted(teller_t9, initiate:transfer)` now answers denied, g1 having been teller_t9's only grant over the scope.
- `revoke(g1)` again → not-active: g1 is already revoked, the answer a retry of a landed revoke gets too (Operation 10, Revoke persistence 3).
- The database refuses the write. `revoke(g2)` → storage-failure: g2 stays active and supervisor_s4 keeps the access, which is how the caller reads the answer before retrying (Operation 13, Operation 15, Revoke persistence 2). Retried, the write commits: `revoke(g2)` → ok.

### Regulated adversarial scenarios

Three scenarios the atom must survive in regulated contexts:

- **Regulator audit — who has access to what.** A HIPAA auditor asks *"which staff have access to full patient records?"* The auditor queries the grant records for all [Active] grants covering the patient-records scope. The grant records answer provably, from stored fields — [Subject Reference], [Action Scope], [Grant Instant], [Status]. Invariants 1, 6, and 7 are the structural answer: evaluation is self-contained; every active grant is observable; absence of a grant means denial.
- **Disputed access — was this actor permitted at the time of the action?** An actor claims they were not authorized to access a resource at a specific time. The investigator queries the grant records for grants where `subject_ref = actor_ref` and `action_scope = contested_scope` with `granted_at ≤ time_of_action` and (`revoked_at IS NULL OR revoked_at > time_of_action`). The timestamp-based form is preferred over `status = active` because [Status] reflects current state, not historical state — a grant revoked after the time of action has `status = revoked` now but was active then; the timestamp condition captures it correctly. A grant matching those criteria is the structural answer: the actor held an [Active] grant at the time of the action. Invariant 1.1 and Invariant 9.2 are what make the reconstruction provable, and Invariant 9.1's ordering rests on clocks whose readings never go backward and agree across the nodes that stamp a grant and its revocation, which the deployment owns (Execution Contract Logic confinement 7).
- **Privilege escalation investigation — unauthorized access attempt.** A security incident suggests an actor accessed a resource beyond their grant. The investigator runs the same reconstruction the disputed-access scenario uses — the grants live at the time of the incident (live at an instant, Invariant 9.2) — because [Check] answers only about now (Invariant 6.1) and its signature takes no instant. An empty reconstruction confirms no grant was in force — any access that occurred did so by circumventing the authorization surface, which is the security incident's scope, not the atom's. The grant records' integrity determines whether the authorization record can be trusted; composing with Tamper Evidence makes that determination structural.

---

## Generation acceptance

This atom's acceptance is provable: an external auditor clears it from the grant records' stored fields.

### Conformance checks

```
Check 1.1: An auditor MUST read EVERY grant's grant id, subject reference, action scope, grant instant and status from the database (State 2).
Check 1.2: An auditor MUST read revocation instant on EVERY revoked grant (State 3).
Check 1.3: An auditor MUST find EVERY grant's grant id, subject reference, action scope and grant instant unchanged across two readings (Invariant 1.1, Invariant 4.2).
Check 1.4: An auditor MUST find no two grants sharing a grant id (Invariant 5.1).
Check 1.5: An auditor MUST find no grant whose revocation instant PRECEDES the grant's grant instant (Invariant 9.1).
Check 2.1: An auditor MUST reconstruct the grants standing in active at a past instant from grant instant and revocation instant (Invariant 9.2).
Check 3.1: An auditor MUST find denied for a pair no active grant matches (Operation 18).
Check 3.2: An auditor MUST find no permitted answer for which no matching active grant EXISTS (Operation 17).
Check 3.3: An auditor MUST find permitted for a pair an active grant matches (Invariant 7.1).
Check 4.1: An auditor MUST find no grant whose status moved out of revoked (Invariant 2.2, Operation 10).
Check 5.1: An auditor MUST find the grant set never shrinking across two readings (Invariant 10.1).
Deleted: Check 6.1. Execution Contract Conformance 9 owns it.
```

### External checks

```
External check 1: An auditor MUST read who issued a grant from the composing Actor Identity attestations (Non-goal 9).
External check 2: An auditor MUST read whether an access was attempted from the composing Event Log records (Non-goal 11).
External check 3: An auditor MUST read a departing subject's full revocation from the composing pattern's deprovisioning records (Deprovisioning 2 through 5).
Deleted: External check 5. Execution Contract Conformance 9 owns it.
Deleted: External check 4. Execution Contract Database 2 owns it.
```

NOTE: EVERY check names the rule the check tests. The grant records answer *who could do what, and since when*; who authorized it, who tried, and whether a leaver's access was fully removed are the composing patterns' records.

## Non-goals

```
Non-goal 1: The atom MUST NOT hold a role.
Non-goal 2: A deployment needing roles MUST NOT call [Grant] BEFORE the deployment resolves the role to grants.
Non-goal 3: The atom MUST NOT evaluate an attribute policy.
Non-goal 4: The atom MUST NOT expand a scope hierarchy.
Non-goal 5: The atom MUST NOT match a scope pattern.
Non-goal 6: The atom MUST NOT record an explicit denial.
Non-goal 7: The atom MUST NOT model a delegation.
Non-goal 8: The atom MUST NOT expire a grant.
Non-goal 9: The atom MUST NOT record who issued a grant.
Non-goal 10: A deployment needing grantor attribution MUST compose Actor Identity.
Non-goal 11: The atom MUST NOT record a [Check] call.
Non-goal 12: A deployment needing access-attempt records MUST compose Event Log.
Non-goal 13: The atom MUST NOT authenticate the caller.
Non-goal 14: The atom MUST NOT bind a subject reference to the authenticated caller.
Non-goal 15: The atom MUST NOT revoke a subject's grants in bulk.
Non-goal 16: The atom MUST NOT carry a grant across trust domains.
Non-goal 17: A deployment needing a defensible timeline MUST compose a trusted timestamping pattern.
```

NOTE: the owners — [Actor Identity](./actor-identity.md) (Non-goal 9, Non-goal 10, External check 1); [Event Log](./event-log.md) (Non-goal 11, Non-goal 12, External check 2); the composing pattern (Non-goal 14, Composition note 3; Non-goal 15, Composition note 5); a Trusted Timestamping pattern *(forthcoming)* (Non-goal 17).

Where the atom breaks down: when the scope vocabulary needs hierarchy or wildcards; when evaluation must reason about the resource's attributes at call time; when a grant must end on its own without anyone revoking it; when the grantor's identity is part of the evaluation rather than beside it.

## Edge cases

### String policy

```
String 1: The atom MUST compare a string input byte-exactly.
String 2: The atom MUST NOT trim a string input.
String 3: The atom MUST NOT normalize a string input.
String 4: The atom MUST NOT case-fold a string input.
String 5: The atom MUST read a whitespace-only string as empty.
String 6: IF a string input EXCEEDS the string cap THEN [Grant] MUST answer invalid-request.
String 7: [Check] MUST read an over-length string input as matching nothing.
```

Term string cap: the deployment's bound on a string input's length in Unicode code points; a cap of zero refuses every [Grant], which is the degenerate configuration a deployment owns rather than a state the atom admits.

NOTE: watch host obligations — this atom refuses a string input over the cap on [Grant] and reads one as matching nothing on [Check], and obliges the deployment to supply the cap and to hold it unchanged for the life of the instance (String 6, String 7, Capability requirement 5, Capability requirement 6), where [Duplicate Prevention](./duplicate-prevention.md) declares a cap and [Provenance](./provenance.md) obliges the deployment to set one; Final Critique 6 cured the cap's supplier, and Final Critique 7 its unit, counted in Unicode code points as [Credential](./credential.md) declares its length bound, and its constancy.

### Deprovisioning a subject

```
Deprovisioning 2: A composing pattern MUST enumerate a departing subject's active grants.
Deprovisioning 3: A composing pattern MUST call [Revoke] for EVERY grant the enumeration returns.
Deprovisioning 4: A composing pattern MUST NOT read one revoke as a subject's deprovisioning.
Deprovisioning 5: A composing pattern MUST record a subject's deprovisioning ONLY IF no active grant EXISTS for the subject.
Deleted: Deprovisioning 1. Identity 8 owns one revoke reaching one grant.
```

### Grant concurrency and revoke concurrency

```
Grant concurrency 1: Two concurrent [Grant] calls on one pair MUST record two grants.
Grant concurrency 2: A composing pattern intending one authoritative grant MUST guard against a concurrent issue.
Deleted: Revoke concurrency 1. Execution Contract Database 2 owns it.
Deleted: Revoke concurrency 2. Execution Contract Database 2 owns it.
```

NOTE: open 2026-10-21-e — one authoritative grant and the guard against a concurrent issue (Grant concurrency 2) name neither what the composing pattern guards nor how, while the atom refuses no covered pair (Operation 6).

### Revoke persistence failure

```
Deleted: Revoke persistence 1. Operation 15 owns it.
Revoke persistence 2: A caller MUST retry a revoke that answered storage-failure.
Revoke persistence 3: A caller MUST read not-active from a retried revoke as the revocation standing.
Revoke persistence 4: A high-assurance deployment MUST raise a security alert on storage-failure from [Revoke].
```

NOTE: open 2026-10-21-c — the caller's retry of a refused revoke names no terminus (Revoke persistence 2), and a high-assurance deployment (Revoke persistence 4) is declared only as an alias of the deployment, so whether the qualifier narrows the rule is unstated.

## Composition notes

```
Composition note 1: A deployment MUST declare which composing patterns the deployment wired in.
Composition note 2: A composing pattern MUST own the scope vocabulary.
Composition note 3: A composing pattern MUST own the binding between the authenticated caller and the subject reference.
Composition note 4: A composing pattern needing grantor attribution MUST attest [Grant] under the grantor's credential.
Composition note 5: A composing pattern MUST own a departing subject's deprovisioning sweep.
```

NOTE: composing patterns — [Attributed Permissions Admin](../compositions/attributed-permissions-admin.md), [Shared Todo](../compositions/shared-todo.md). Forthcoming: Role-Based Access Control, Attribute-Based Access Control, Temporal Grant, Delegation, Policy Layer, Identity Federation.

## Terms

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is* and its **Kind**.

### Vocabulary

Term actors: the atom; the host; the transition; the deployment (also: a high-assurance deployment); a composing pattern (also: a pattern); a business caller; a caller; a subject; a grantor; an auditor; the database; a grant; a status.

Term records: grant record — one binding, carrying grant id, subject reference, action scope, grant instant, status and, once withdrawn, revocation instant.

Term record verbs: identify, allocate, supply, reuse, hold, reach, compare, trim, normalize, case-fold, read, stand, carry, stamp, offer, delete, record, answer, refuse, take, write, match, rest, consult, change, move, set, share, shrink, evaluate, expand, model, expire, authenticate, bind, revoke, retry, raise, enumerate, call, guard, compose, resolve, attest, own, declare, find, reconstruct, precede, cover, return, issue, attempt, wire.

Term value sets: status = active | revoked.

Term bounds: string cap (the deployment's bound on a string input's length in Unicode code points).

Term cadences: empty.

Term qualifiers: migrated — rewritten in GRACE lang v0.35 (2026-09-12).

Term terms: grant record, live at an instant, grant id, subject reference, action scope, seam, transition, business caller, now, string cap, status, grant instant, revocation instant, pair, grant set, active grant set.

#### Grant

The behavior an administrator or composing pattern invokes to record a new grant binding a [Subject Reference] to an [Action Scope]. It allocates a fresh [Grant Id], stamps [Grant Instant], records the grant in [Active], and returns the [Grant Id]. A pair an active grant already covers is no ground for refusal: duplicate grants for the same (subject, scope) pair are independent records, each with its own id.

Kind: Operation

#### Revoke

The behavior that withdraws a recorded grant, by id. It moves the grant at [Grant Id] from [Active] to [Revoked] and stamps [Revocation Instant]. Revocation is terminal: a grant already in [Revoked] is rejected with [Not Active].

Kind: Operation

#### Check

The read-only behavior a composing pattern invokes before an action to evaluate whether a (subject, scope) pair holds an [Active] grant. It returns [Permitted] if any [Active] grant matches the queried [Subject Reference] and [Action Scope], otherwise [Denied]. It changes nothing, and both answers are first-class results. (Its projected contract lowers the verb to permitted, which is also the name of one of its two answers — `permitted(alice, read) → denied` is well-formed and reads oddly; the lowering is recorded here because the rules speak [Check] and the wire speaks permitted.)

Kind: Operation

#### Read

The read-only query answering every grant the database holds, [Active] and [Revoked], each with its stored fields. It is what a composing pattern enumerates a subject's or a pair's grants through, filtering in its own code (Deprovisioning 2), and what an auditor reads the database through (Check 1.1). It changes nothing.

Kind: Operation

#### Grant Id

The opaque, immutable identity of a grant, host-allocated at the I/O seam on [Grant] and never reused. The [Subject Reference] and [Action Scope] are properties of the grant, not its identity; the id is the handle [Revoke] uses.

Kind:       Field
Field of:   Permissions
Projection: grant_id

#### Subject Reference

The opaque reference to *who* holds the grant — the subject the grant binds. The atom does not interpret it; the actor registry is a separate concept. Set on [Grant], immutable thereafter, and matched byte-exactly by [Check].

Kind:       Field
Field of:   Permissions
Projection: subject_ref

#### Action Scope

The opaque reference to *what* the grant covers — the scope the grant binds. A composing pattern defines scope semantics; the atom does exact match on the value (no hierarchy or wildcard). Set on [Grant], immutable thereafter.

Kind:       Field
Field of:   Permissions
Projection: action_scope

#### Grant Instant

The wall-time the grant was recorded, stamped from the injected [Now] on [Grant]. Immutable thereafter, and never re-derived from the current clock.

Kind:       Field
Field of:   Permissions
Projection: granted_at

#### Status

The grant's lifecycle state — [Active] or [Revoked]. Set to [Active] on [Grant]; transitions one-way to [Revoked] on [Revoke].

Kind:       Field
Field of:   Permissions
Projection: status

#### Revocation Instant

The wall-time the grant was revoked, stamped from the injected [Now] on [Revoke]. Absent while the grant is [Active]; set once on [Revoke] and never changed after.

Kind:       Field
Field of:   Permissions
Projection: revoked_at

#### Now

The current wall-time reading the transitions stamp [Grant Instant] and [Revocation Instant] from, supplied to the pure transition by the host at the I/O seam (never read inside the transition, never supplied by the business caller).

Kind:         Parameter
Parameter of: Grant and Revoke
Projection:   now

#### Active

The state of a grant that is in force: it contributes to [Check] evaluations. A grant enters [Active] on [Grant] and leaves it only on [Revoke].

Kind:       Member
Member of:  the grant state
Role:       Outcome
Projection: active

#### Revoked

The state of a grant that has been withdrawn: it no longer contributes to [Check] evaluations. A grant enters [Revoked] on [Revoke]; the transition is terminal — there is no [Revoked] → [Active] path.

Kind:       Member
Member of:  the grant state
Role:       Outcome
Projection: revoked

#### Permitted

The outcome [Check] returns when the grant records are read and at least one [Active] grant matches the queried [Subject Reference] and [Action Scope]. A first-class result, not a success-or-reject acknowledgement.

Kind:       Member
Member of:  the Check outcome
Role:       Outcome
Projection: permitted

#### Denied

The outcome [Check] returns when the grant records are read and no [Active] grant matches the queried pair — denial by absence. A first-class result; empty or malformed inputs also resolve to [Denied], since they match no [Active] grant.

Kind:       Member
Member of:  the Check outcome
Role:       Outcome
Projection: denied

#### Invalid Request

The refusal [Grant] returns when [Subject Reference] or [Action Scope] is blank, or a string input exceeds the string cap (String 6). A guard rejection that fails before any database write; no grant is recorded.

Kind:       Member
Member of:  the Grant rejection
Role:       Outcome
Projection: invalid-request

#### Not Known

The refusal [Revoke] returns when the supplied [Grant Id] references no grant the database holds.

Kind:       Member
Member of:  the Revoke rejection
Role:       Outcome
Projection: not-known

#### Not Active

The refusal [Revoke] returns when the referenced grant is not in [Active] — it is already [Revoked]. This is what makes revocation terminal.

Kind:       Member
Member of:  the Revoke rejection
Role:       Outcome
Projection: not-active

#### Storage Failure

The refusal [Grant] or [Revoke] returns when the database write fails after all preconditions pass. For [Revoke], the grant remains [Active] — a security-critical state the caller must retry, never treat as a confirmed revocation.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: storage-failure

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a [Term] marker to its term entry heading above (kramdown
     auto-generates the heading anchors on GitHub Pages). Standard CommonMark /
     kramdown; no plugin required. -->

[Grant]: #grant
[Revoke]: #revoke
[Check]: #check
[Read]: #read
[Grant Id]: #grant-id
[Subject Reference]: #subject-reference
[Action Scope]: #action-scope
[Grant Instant]: #grant-instant
[Status]: #status
[Revocation Instant]: #revocation-instant
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
- **ISO/IEC 27001 clause A.9 (Access Control)** — the International Organization for Standardization / International Electrotechnical Commission information-security standard; logical access control, user access management, review of user access rights. The grant records are the access-rights record clause A.9.2 requires.
- **HIPAA section 164.312(a)(1) (Technical Safeguards — Access Control)** — unique user identification, emergency access procedure, automatic logoff, encryption. The minimum-necessary principle (section 164.514(d)) is operationalized as narrow action scopes. The grant records demonstrate compliance.
- **Sarbanes-Oxley section 404 (Internal Control over Financial Reporting)** — segregation of duties, access controls on financial systems. The grant records' timeline (who had what access, from when to when) is the section 404 evidence trail.
- **PCI DSS Requirement 7 (Restrict Access to System Components and Cardholder Data)** — need-to-know access, formal access authorization, denial by default. Invariant 7 (denial by absence) is the structural form of PCI DSS's default-deny posture.
- **GDPR (EU General Data Protection Regulation) Article 25 (Data Protection by Design and by Default)** — technical measures ensuring only necessary data is processed. Scoped grants are the technical measure; the grant records demonstrate the measure.
- **NIST SP 800-63-3 (Digital Identity Guidelines)** — the atom composes with Authentication (which supplies NIST IAL/AAL/FAL — Identity, Authenticator, and Federation Assurance Levels — assurance levels) and with Actor Identity (which records the authorization-to-grant event).

It inherits from:

- **Daniel Jackson, *The Essence of Software*** — freestanding-atom posture; the discipline of composing authentication, identity, role management, and policy evaluation as separate atoms rather than absorbing them.
- **Eiffel's design-by-contract** — preconditions on [Grant] and [Revoke]; named rejection reasons.
- **Lampson's access matrix** (1971) — the foundational formal model of access control as a matrix of (subject, object, right) triples. [Grant] adds a right to the matrix; [Revoke] removes it; [Check] queries it. The atom is the structured-natural-language realization of Lampson's core operations.
- **Graham-Denning model** — formal treatment of grant and revoke as eight first-class protection operations. Grant and revoke are two of Graham-Denning's eight; the atom isolates those two (plus evaluation) as the minimal authorization surface.

---

## Status

`grounded on Final Critique 8 — 2026-10-26` — see the Ledger.

## Ledger

```
status: grounded on Final Critique 8 — 2026-10-26
formal: verified — permissions.als + 1 twin, 2026-06-03
last gate: 2026-10-26 — Final Critique 8 — foundational count 0, clean, one sample

open:
- 2026-10-21-c · refining · Revoke persistence 2, 4 · the caller's retry of a refused revoke names no terminus (Pass 1: every retry loop names its terminus), and the deployment that raises the alert is declared only as an alias of the deployment → name the bound at which the caller stops and what it raises there; say which deployments alert
- 2026-10-21-e · refining · Grant concurrency 2 · one authoritative grant and the guard against a concurrent issue name neither what the composing pattern guards nor how, while the atom refuses no covered pair (Operation 6) → name what the composing pattern guards, outside the atom
- 2026-10-21-f · refining · Term seam; Term transition; Term business caller · each says the section titled Logic Confinement Principle in `execution-contract.md` declares it, and that section declares none of the three → declare the three there, the corpus's one seam wording, or point each at its declaration
- 2026-10-21-h · refining · Operation 26, 27 · [Read] answers every grant in no stated order and with no bound on the answer → say the order is unspecified or give one; bound or page the answer
- 2026-10-26-a · refining · Identity 2; Capability requirement 1, 4 through 6 · the grant id's source is named as the host's allocation (Identity 2) and not among what the deployment supplies, where the atom shape in `spec-format.md` lists an id source under Capability requirement; Approval Step (its 2026-10-26-a), Assignment (its 2026-10-26-a), Event Log (its 2026-10-22-b) and Tamper Evidence (its 2026-10-22-a) route the same form → name the source among the Capability requirements, in the one form the corpus settles for its twenty host-allocation atoms
- 2026-10-26-b · refining · Operation 16 through 22; the signature block · the rules name the action [Check] and the signature block declares it as permitted, and only the Check entry, a term entry, which carries no obligation (GRACE-lang Surface 25 and 27), says the one is the other; permitted is also one of [Check]'s two answers → name the action alike in the rules and on the wire, whose permitted every composing page calls, or tie the two names on the normative surface in the form the corpus settles for the wire layer (the Watch list's the wire layer)
```

<details markdown="block">
<summary>
    <h2 id="decisions" style="display: inline-block; margin-left: 1.5rem;">Decisions</h2>
</summary>

Directional changes only — the turns a future reader must know the pattern took, and why. Everything smaller lives in the commit that made it: `git log -- atoms/permissions.md`; the rounds and the migration that got it here are in [its history](./permissions.hist.md).

- **2026-10-19 — The store's guarantees cited, not restated.** *Chose:* the grant store supplied under Execution Contract Store 1 through 4 (Capability requirement 4), and the seven rules that restated them tombstoned to their owner — Operation 8 and Invariant 10.3, no partial grant, to Store 1; Operation 12, the active-to-revoked move committed as one write, to Store 1 and Store 2; Revoke concurrency 1 and 2, two revokes of one grant never both succeeding and the later answering not-active, and External check 4, the deployment's evidence of that serialization, to Store 2; Operation 14, a refused revoke leaving the grant active, to Store 3; rules 111 to 105. *Over:* the atom restating, for its own store, what every deployment's store guarantees. *Because:* the maintainer ruled 2026-10-12 that the corpus takes a store's specification, never the store, and `execution-contract.md` writes it once as the Store contract. The grant set that never shrinks stays (Invariant 10.2), the atom's own surface that Check 5.1 reads, and so does the caller's reading of a refused revoke (Operation 15, Revoke persistence 1 through 4): it binds the caller, which no Store rule does. What the atom does for its domain is unchanged.

- **2026-10-21 — A failed read answers on every action, each writing action's refusals in one stated order; coverage is no ground for refusal; a deprovisioning is recorded only once no grant stands.** *Chose:* state-unavailable on all four actions where the read of the grant store fails, the Execution Contract's Step 1 failure (Operation 30, Term store read), [Check] and [Read] refusing nothing else and answering only on an answered read (Operation 16, Operation 18, Operation 19, Operation 26, Operation 29), the refusals of [Grant] and [Revoke] in one stated order, the store read first (Operation 31, Operation 32, Term grant refusal order, Term revoke refusal order), and Invariant 3.1, which said outside that order what Operation 10 says, deleted to it; [Grant] forbidden to refuse a call on the ground that an active grant already covers the pair, not to refuse a covered pair at all (Operation 6); a composing pattern recording a subject's deprovisioning only where no active grant exists for the subject (Deprovisioning 5); a check that finds permitted for a matched pair, Check 3.2 citing the rule it tests (Check 3.3, Operation 17); the composing patterns a deployment wired in read from the deployment's own declaration (External check 5). *Over:* [Check] and [Read] forbidden to refuse a store they cannot read; a ban on refusing a covered pair that the write refusal, a lowered string cap and the failed read each break; a sweep recorded complete while a grant issued during it, or one whose revoke never answered, stays active; conformance checks a build denying every pair clears; a check reading what the grant store does not carry. *Because:* Final Critique 5 found each a divergence between conforming builds, or a stated check a conforming build fails or a violating one passes, and the corpus already held three of the cures: Actor Identity's fifth round answers a failed store read on every action and reads the composing patterns from the deployment's declaration, and Retention Window's eighth answers each writing action's refusals in one stated order, the form the maintainer ruled for Verified Repair on 2026-10-19, and forbids a refusal on a stated ground (its Operation 18). Compositions affected: the pages that compose this atom route state-unavailable from all four actions, and record a deprovisioning only once no grant stands, when their rounds read them.

- **2026-10-21 — A failed read answers as the Execution Contract says.** *Chose:* the failed read cited from the Execution Contract (Capability requirement 4, Execution Contract Read 1 through 3) and the four rules that restated it deleted to it: the atom-wide state-unavailable (Operation 30) to Read 1; [Check]'s and [Read]'s state-unavailable on a failed read alone (Operation 19, Operation 29) to Read 2 beside the rules that close each action's answers; and the grant refusal order (Operation 31), whose rules after the read all answer invalid-request, to Read 1; the read's condition off the rules it held to an answered read (Operation 16, Operation 18, Operation 26), the read off the revoke refusal order, Term database read deleted, and state-unavailable off every signature; rules 109 to 105. *Over:* the page stating for itself what every action answers when the grant records cannot be read. *Because:* the maintainer ruled on 2026-10-21 that the Execution Contract states the failed read once; this page's fifth Final Critique had made the cure the contract's Read family is written from. What [Check] answers on an answered read is unchanged.

- **2026-10-21 — Which refusal answers is the Execution Contract's.** *Chose:* [Revoke]'s refuses line kept as the page wrote it, already in the order the revoke refusal order gave — not-known, not-active, then storage-failure, which answers only at the write — and the order cited from the Execution Contract (Capability requirement 4, Execution Contract Refusal 1); Operation 32, which evaluated the revoke refusal order, deleted to Refusal 1, and Term revoke refusal order deleted with it; rules 105 to 104. *Over:* the page stating for itself which of [Revoke]'s refusals answers when both apply. *Because:* the maintainer ruled on 2026-10-21 that the Execution Contract states once that the refusal listed first on an action's refuses line answers; this page's fifth Final Critique had made the cure one specification at a time. What each action answers on every call is unchanged.

- **2026-10-22 — The wiring is read outside the records, and a ban on refusing names its ground, as the Execution Contract says.** *Chose:* External check 5, the auditor reading which composing patterns a deployment wired in from the deployment's own declaration, deleted to Execution Contract Conformance 9, with Check 6.1's tombstone, which named it, now naming the contract, the checks NOTE's clause restating it removed, and the label cited on Capability requirement 4; Operation 6's ground clause retired, the rule written again as the page first had it, *[Grant] MUST NOT refuse a pair an active grant already covers*, which Execution Contract Refusal 1's second sentence reads as naming the ground, so a blank reference still answers invalid-request; rules 104 to 103. *Over:* the page stating for itself that the wiring is an external check, and Operation 6 carrying the ground clause its fifth Final Critique wrote. *Because:* the maintainer ruled on 2026-10-22 that five repeated cures are each stated once, the wiring declaration and the refusal ban among them; this page's fifth Final Critique had made both cures one specification at a time. What each action does and answers is unchanged.

</details>

NOTE: End of Permissions.
