---
title: Session-Gated Authorization
parent: Conceptual Compositions
nav_order: 14
has_toc: true
toc: true
---

# Session-Gated Authorization

<details markdown="block">
<summary>Table of contents</summary>
{: .text-delta }
1. TOC
{:toc}
</details>

**Composes:** [Session](../atoms/session.md) · [Permissions](../atoms/permissions.md)

## Summary

Session-Gated Authorization is a regulated composition — a combination of two simpler building-block patterns (called atoms), designed for settings where regulators audit access control. Every authorization query is gated by a mandatory session validation before the Permissions atom — the pattern recording who may do what — is consulted. An expired, revoked, or unrecognized session terminates the call before Permissions is reached.

The principal presented to Permissions is always the principal the session was issued for — never a value the caller supplies.

This composition owns two rules and inherits a third. It owns the **principal binding** — [Permissions](../atoms/permissions.md)'s `Composition note 3` assigns that to a composing pattern and declines to state it, so no atom holds it. It owns the **closure**: Permissions is unreachable unless a validate answered, which is stricter than anything Session says. The **gate itself** — that an invalid session must not reach Permissions — is [Session](../atoms/session.md)'s `Composition note 4`, cited here and obeyed, not invented here.

---

## Intent

Every system that issues session tokens and enforces authorization policies faces the same ordering problem: the runtime check must verify that the session is still valid *before* consulting the permission store, not after. An expired or revoked session that reaches `Permissions.permitted` is an authentication gap masquerading as an authorization query.

Session-Gated Authorization wires Session and Permissions into a single enforced boundary. `Session.validate` must return `valid` before `Permissions.permitted` is consulted. The gate is a pre-check at the composition boundary, not inside either constituent atom. Neither atom gains knowledge of the other; the sequencing constraint is owned entirely by the composition.

The second guarantee is principal binding: the subject passed to `Permissions.permitted` is always the `principal_ref` extracted from the validated session, never a caller-supplied value. A caller cannot interrogate permissions for an arbitrary principal by presenting an arbitrary session token. This eliminates a class of authorization bypass that is otherwise invisible when the two atoms are composed informally — when code calls `Permissions.permitted(caller_supplied_principal, scope)` without gating on the session, a compromised or forged request can probe any principal's permissions regardless of the session state.

---

## Composes

- **[Session](../atoms/session.md)** — the session a call presents, validated at the gate.
- **[Permissions](../atoms/permissions.md)** — the grants and the permission query behind the gate.

```
Composes 1: EXACTLY ONE Session instance MUST serve the composition.
Composes 2: EXACTLY ONE Permissions instance MUST serve the composition.
Composes 3: The composition MUST NOT change a constituent's spec.
Composes 4: The composition MUST NOT hold state across a call.
Composes 5: The composition MUST replace the constituents' own authorization surface.
Composes 6: The composition MUST discharge Permissions Composition note 3.
Composes 7: The composition MUST obey Session Composition note 4.
```

Term composition: this pattern's wiring of [Session](../atoms/session.md) and [Permissions](../atoms/permissions.md) — the gate, the principal binding and the one action below.

Term constituents: [Session](../atoms/session.md), [Permissions](../atoms/permissions.md).

WHY:
Composes 5 is the enclosure the other rules rest on. A deployment that exposes `Session.validate` or `Permissions.permitted` beside [Check Permitted] gives a caller a route to the permission store that never passes the gate, and every guarantee below is a guarantee about the route through [Check Permitted] alone. Non-goal 9 states what a deployment owes when it exposes both anyway.

Composes 6 and Composes 7 name the two constituent obligations this composition exists to discharge, and they are not the same kind of obligation. [Permissions](../atoms/permissions.md)'s `Composition note 3` **assigns** ownership — *a composing pattern MUST own the binding between the authenticated caller and the subject_ref* — and Invariant 2 is this composition owning it, which is what a composition note is for. [Session](../atoms/session.md)'s `Composition note 4` **states the rule itself** — *IF Validate gives an invalid answer THEN a composing pattern MUST NOT call Permissions* — and Session's own WHY names this composition as the pattern that carries it. So the gate as stated is Session's and is cited here rather than restated (Authority 5, Authority 6); what this composition adds over it is the closure Invariant 1.1 carries — Permissions unreachable unless a validate answered at all, which Session never says. Atoms may bind compositions; a composition cites what the composition inherits and owns what the composition adds (§Decisions, council read 53).

---

## Composition logic

### Composition state

```
Composition state 1: The composition MUST NOT store a record.
Composition state 2: The composition MUST NOT derive an index.
Composition state 3: The composition MUST evaluate the gate from the constituents' own surfaces.
Composition state 4: A deployment needing a record of an authorization decision MUST compose Audit Trail.
```

WHY:
The contract classification is *conforming, no stored composition state* (`execution-contract.md` §Composition state). There is no index, map or log at the composition boundary, so nothing here can go stale and nothing needs a rebuild — the gate is a sequencing constraint over state the constituents already hold. Composition state 4 is the cost: without [Audit Trail](./audit-trail.md) there is no per-call record, and the forensic scenario below says plainly what that costs an investigator.

### Primitive policy

```
Primitive policy 1: A deployment MUST pin the length bound.
Primitive policy 2: [Check Permitted] MUST answer invalid-request for a blank session_token.
Primitive policy 3: [Check Permitted] MUST answer invalid-request for a blank action_scope.
Primitive policy 4: [Check Permitted] MUST answer invalid-request for an argument EXCEEDS the length bound.
Primitive policy 5: The composition MUST compare an argument byte-exact.
Primitive policy 6: [Check Permitted] MUST NOT trim an argument.
Primitive policy 7: [Check Permitted] MUST NOT case-fold an argument.
Primitive policy 8: [Check Permitted] MUST NOT normalize an argument.
Primitive policy 9: [Check Permitted] MUST NOT call a constituent for an argument the boundary predicate refuses.
```

WHY:
invalid-request is composition-introduced: neither wired constituent operation declares it, and Primitive policy 9 is why neither is consulted when it fires. That matters for a reason the outcome set makes plain — [Permissions](../atoms/permissions.md) answers an empty `subject_ref` or action_scope with denied under its own default-deny posture, so a composition that let a malformed argument through would report *the answer is no* where the truth is *the request was not well-formed enough to ask*. Primitive policy 2 through 4 keep the three outcome classes distinct, which is Invariant 3's discipline applied to inputs rather than to answers.

### Action wiring

```
check_permitted(session_token, action_scope)
  answers permitted | denied
  refuses invalid-request | session-invalid(validation failure)
```

```
Action wiring 1: The composition MUST validate the arguments against the boundary predicate.
Action wiring 2: The composition MUST call Session's validate ONLY AFTER the arguments clear the boundary predicate.
Action wiring 3: The composition MUST call Session's validate with the session_token.
Deleted: Action wiring 4. Wiring decision 1 owns it.
Action wiring 5: An admitted gate MUST call Permissions' permitted with the valid answer's principal_ref.
Action wiring 6: An admitted gate MUST call Permissions' permitted with the action_scope.
Action wiring 7: [Check Permitted] MUST NOT accept a principal_ref.
Action wiring 8: [Check Permitted] MUST NOT call Permissions' permitted with a caller-supplied subject_ref.
Action wiring 9: IF Session's validate gives an invalid answer THEN [Check Permitted] MUST answer session-invalid naming the invalid answer's reason.
Action wiring 10: An admitted gate MUST answer Permissions' permitted answer.
Action wiring 11: [Check Permitted] MUST NOT change Permissions' permitted answer.
Action wiring 12: [Check Permitted] MUST NOT answer the valid answer's expires_at.
Action wiring 13: The composition MUST call Session's validate for EVERY call.
Action wiring 14: [Check Permitted] MUST NOT read a validate answer a prior call received.
Action wiring 15: [Check Permitted] MUST NOT write.
```

Term boundary predicate: the composition's own argument check — an argument NOT EXISTS, is blank OR EXCEEDS the length bound.

Term blank: a value that is absent, empty, or carries only whitespace — what the boundary predicate refuses; a blank argument NOT EXISTS.

Term length bound: the cap a deployment pins for an opaque argument — a [Length Bound]; the value is the deployment's, the existence is this composition's contract.

Term valid answer: Session's validate answer carrying a principal_ref and an expires_at.

Term invalid answer: Session's validate answer carrying expired, revoked OR not-known.

Term admitted gate: a [Check Permitted] call whose arguments cleared the boundary predicate AND whose Session validate gave a valid answer.

WHY:
Action wiring 2 and Wiring decision 1 are the whole composition stated as order. The boundary check runs before either constituent, the gate runs before Permissions, and both are `ONLY AFTER` rather than `BEFORE` because the grammar admits the positive form only in that direction (Timing 6, Hard invariant 11).

Action wiring 13 and Action wiring 14 are one rule split by polarity, and they are what the OWASP ASVS V3.3 claim in Standards rests on. A deployment caching a validate answer across calls satisfies neither: a session revoked between two calls reaches Permissions with validate never consulted, which is the gap this composition exists to close. Non-goal 8 says what such a deployment is building instead.

Action wiring 7 and Action wiring 8 are the principal binding stated twice on purpose — once as an argument the action does not take, once as a value it does not forward. A composition that took the argument and ignored it would satisfy the second and break the first, and an implementation that forwarded a caller value under a different name would satisfy the first and break the second.

Action wiring 12 keeps the gate binary. The `expires_at` reaches the composition and stops there: a caller that learns the deadline learns how long a stolen token remains useful, and no rule here needs the value.

### Wiring decision

```
Wiring decision 1: The composition MUST call Permissions' permitted ONLY AFTER Session's validate gives a valid answer.
```

WHY:
The decision the composition exists to make: the session gates the permission check, at the composition boundary, so neither atom learns the other's rules (§Intent). The rule is Action wiring 4's words, moved to the heading that names what it is.

---

## Composition-level invariants

- **Invariant 1 — Session gates authorization.**
  ```
  Invariant 1.1: The composition MUST NOT call Permissions' permitted for a session_token Session's validate gave no valid answer for.
  Deleted: Invariant 1.2. Session Composition note 4 owns it.
  Deleted: Invariant 1.3. Session Composition note 4 owns it.
  Deleted: Invariant 1.4. Session Composition note 4 owns it.
  ```
  WHY: [Session](../atoms/session.md)'s `Composition note 4` already forbids a composing pattern to call Permissions on an invalid answer, and `Composes 7` cites it — so the three deleted rules, which enumerated that prohibition over `expired`, revoked and not-known, restated a rule this spec cites rather than owns (Authority 6). Invariant 1.1 is not that rule. `Composition note 4` fires on an invalid answer *given*; Invariant 1.1 fires on no valid answer *given*, which also covers the call that never asked. The two do not normalize identically (Authority 4), and the gap between them is exactly what this composition adds: Session forbids acting on a bad answer, and the closure forbids acting on no answer at all. A deployment that skipped `validate` entirely would satisfy `Composition note 4` and breach Invariant 1.1.
- **Invariant 2 — Principal binding.**
  ```
  Invariant 2.1: EVERY subject_ref Permissions' permitted receives MUST equal the valid answer's principal_ref.
  Invariant 2.2: The composition MUST NOT query a principal_ref beside the session's own.
  ```
  WHY: this one is emergent in the sense the summary claims, and [Permissions](../atoms/permissions.md)'s `Composition note 3` is why — the atom assigns the binding to a composing pattern and declines to own it, so the rule exists here because no atom holds it. That is the shape Composes 6 discharges, and it is a different shape from Invariant 1's.
- **Invariant 3 — Denial is not rejection.**
  ```
  Invariant 3.1: A denied answer MUST follow an admitted gate.
  Invariant 3.2: A session-invalid answer MUST NOT follow an admitted gate.
  Invariant 3.3: The composition MUST NOT answer denied for a session Session's validate gave an invalid answer for.
  ```
  WHY: denied means the gate cleared and the answer is no; session-invalid means the gate did not clear and Permissions was never asked. A caller that collapses them reads an authentication failure as an authorization decision, and an auditor that collapses them cannot tell a revoked session from a missing grant.
- **Invariant 4 — Default deny.**
  ```
  Invariant 4.1: An admitted gate MUST answer denied for a pair no active grant covers.
  Invariant 4.2: A valid session MUST NOT stand as sufficient for access.
  ```
  WHY: session validity is necessary and never sufficient. The default-deny posture is [Permissions](../atoms/permissions.md)'s and passes through unmodified (Action wiring 10, Action wiring 11); what this composition adds is that it passes through at all rather than being softened by a valid session.

---

## Examples

### Happy path — valid session, permission granted

A principal holds an active session and has a grant for the requested scope.

```
check_permitted(
  session_token: "tok_abc123",
  action_scope:  "invoice:read"
) → permitted
```

Internally: `Session.validate("tok_abc123") → valid(principal_ref: "usr_42", expires_at: T+3600)`. Then: `Permissions.permitted("usr_42", "invoice:read") → permitted`.

### Session expired — gate blocks before Permissions

The session token identifies a session whose `expires_at` has passed.

```
check_permitted(
  session_token: "tok_expired",
  action_scope:  "invoice:read"
) → session-invalid(expired)
```

Internally: `Session.validate("tok_expired") → invalid(expired)`. Permissions is never consulted.

### Session revoked — gate blocks before Permissions

The session was revoked — directly by `Session.revoke`, by `logout`, or via cascade from [Login](./login.md)'s `revoke_sessions_for_credential`.

```
check_permitted(
  session_token: "tok_revoked",
  action_scope:  "invoice:read"
) → session-invalid(revoked)
```

Internally: `Session.validate("tok_revoked") → invalid(revoked)`. Permissions is never consulted.

### Session not known — gate blocks before Permissions

The token is unrecognized — never issued, already purged, or fabricated.

```
check_permitted(
  session_token: "tok_unknown",
  action_scope:  "invoice:read"
) → session-invalid(not-known)
```

Internally: `Session.validate("tok_unknown") → invalid(not-known)`. Permissions is never consulted.

### Malformed input — rejected before the gate

The caller presents a whitespace-only token.

```
check_permitted(
  session_token: "   ",
  action_scope:  "invoice:read"
) → invalid-request
```

The token fails the Primitive-policies predicate (whitespace-only counts as absent). Neither `Session.validate` nor `Permissions.permitted` is consulted. The outcome is not denied (no permission was evaluated) and not session-invalid (no session was consulted) — the three classes stay distinct.

### Valid session, permission denied

The session is active but the principal has no active grant for the requested scope.

```
check_permitted(
  session_token: "tok_abc123",
  action_scope:  "invoice:delete"
) → denied
```

Internally: `Session.validate("tok_abc123") → valid(principal_ref: "usr_42", ...)`. Then: `Permissions.permitted("usr_42", "invoice:delete") → denied`. The principal holds no active grant for `"invoice:delete"`.

### Regulated adversarial scenarios

**Regulator audit.** An auditor queries whether the system enforces access control at session-expiry boundaries — specifically, whether an expired session is permitted to evaluate any authorization query. By Invariant 1, any [Check Permitted] call with an expired session token returns `session-invalid(expired)` before Permissions is consulted. The session expiry state is verifiable from Session's own records; the composition's invariant is derivable from the action wiring alone, without inspecting runtime logs. If Audit Trail is composed in as a substrate, the individual [Check Permitted] records confirm the rejected outcome directly.

**Disputed access.** A data subject asserts that their account was accessed after they logged out — which revoked their session. The dispute requires establishing: (a) the session was revoked at time T; (b) any [Check Permitted] call after T with that session token returned `session-invalid(revoked)`, not permitted or denied. Session's state records the revocation timestamp. The composition's Invariant 1 establishes that Permissions was never reached after revocation. If Audit Trail is composed in, the dispute is answerable from records alone. If not, the argument is structural: the session was invalid (revoked) as of T, and the composition guarantees that an invalid session cannot produce a permitted or denied result.

**Breach forensics.** An investigator determines that a session token was stolen and seeks to establish what permissions were exercised under it before revocation. This composition does not maintain an authorization event log; forensic coverage of individual [Check Permitted] calls requires [Audit Trail](./audit-trail.md) composed in as a substrate (see *Composition notes*). Without Audit Trail, the investigator can establish from Session's state that the session was active for a given window and was eventually revoked, and from Permissions' state what grants the principal held during that window — but cannot enumerate individual [Check Permitted] calls or their outcomes from the composition's own state. This is a known scope limitation that composition with Audit Trail resolves.

---

## Generation acceptance

This composition introduces no per-call event log, so the acceptance bar has two tiers: what an auditor clears from the constituents' own state, and what needs evidence that state does not carry. Both are stated so the auditor knows which is which before starting.

### Conformance checks

```
Check 1.1: An auditor MUST find Session's state naming a disputed session_token's status at the disputed instant (Invariant 1.1).
Check 1.2: An auditor MUST find no permitted answer for a session_token Session's state shows expired at the disputed instant (Invariant 1.1, Session Composition note 4).
Check 1.3: An auditor MUST find no permitted answer for a session_token Session's state shows revoked at the disputed instant (Invariant 1.1, Session Composition note 4).
Check 2.1: An auditor MUST find Session's state naming the principal_ref a disputed permitted answer rests on (Invariant 2.1).
Check 2.2: An auditor MUST find Permissions' state carrying an active grant for the disputed pair at the disputed instant (Invariant 4.1).
Check 3.1: An auditor MUST find EVERY answer of the composition standing in EXACTLY ONE OF permitted, denied, invalid-request, session-invalid (Invariant 3.1, Invariant 3.2).
```

NOTE: EVERY check names the rule the check tests.

### External checks

```
External check 1: An auditor needing the gate's order confirmed MUST read the deployment's own implementation (Invariant 1.1).
External check 2: An auditor needing the principal binding confirmed MUST read the deployment's own implementation (Invariant 2.1).
External check 3: An auditor needing an enumeration of authorization attempts MUST read a composed Audit Trail (Composition state 1).
External check 4: An auditor needing a gate rejection's record MUST read a composed Audit Trail (Composition state 1).
External check 5: An auditor needing the constituents' surfaces confirmed unexposed MUST read the deployment's own wiring (Composes 5).
```

WHY:
The split is not a matter of thoroughness — it is what the absent log costs. Check 1.1 through 2.2 clear from the constituents' stored state, because Session records a session's status over time and Permissions records a grant's. External check 1 and External check 2 cannot: the *order* of two calls and the *provenance* of an argument leave no trace in either store, so an auditor without [Audit Trail](./audit-trail.md) is reading an implementation rather than a record. That is the honest bar, and it is why the breach-forensics scenario above answers structurally rather than from records.

External check 5 is the one a deployment can fail silently. Every guarantee here is a guarantee about calls that arrive through [Check Permitted]; a deployment that also exposes `Permissions.permitted` has a second door, and nothing in the composition's own records shows that the door exists.

---

## Non-goals

```
Non-goal 1: The composition MUST NOT issue a session.
Non-goal 2: The composition MUST NOT terminate a session.
Non-goal 3: The composition MUST NOT grant a permission.
Non-goal 4: The composition MUST NOT revoke a permission.
Non-goal 5: The composition MUST NOT expand an action_scope.
Non-goal 6: The composition MUST NOT match an action_scope by prefix.
Non-goal 7: The composition MUST NOT aggregate a principal_ref's sessions.
Non-goal 8: A deployment caching a validate answer across calls MUST NOT claim conformance.
Non-goal 9: A deployment exposing a constituent's surface beside [Check Permitted] MUST declare the exposure.
Non-goal 10: The composition MUST NOT record an authorization decision.
Non-goal 11: The composition MUST NOT distinguish a session that lapsed unused from one that lapsed in use.
Non-goal 12: The composition MUST NOT answer a storage failure.
```

WHY:
Non-goal 5 and Non-goal 6 are the scope contract: `invoice:read` does not match `invoice:*` or `invoice` unless those exact strings appear in active grants. Hierarchy, if a deployment needs it, lives outside both atoms — [Permissions](../atoms/permissions.md)'s `Composition note 2` assigns the scope vocabulary to the composing pattern, and this composition declines it rather than inventing one.

Non-goal 12 is an absence with a reason. `Session.validate` and `Permissions.permitted` both answer a first-class result for every declared case and neither declares a failure arm, so there is no constituent failure to map. A grant store that cannot be read produces no conforming Permissions answer at all — an availability fault at the constituent — and this composition adds no arm for it rather than inventing a guarantee past the constituents' own surfaces.

Non-goal 7 is worth stating because the opposite reads as helpful. A principal may hold several active sessions; [Check Permitted] answers on the presented token alone, and a composition that searched the principal's other sessions for a valid one would let a revoked token borrow a live one's standing.

---

## Edge cases

### Concurrency

```
Concurrency 1: The composition MUST answer from the validate answer the call received.
Concurrency 2: The composition MUST NOT detect a revocation that follows the validate answer.
Concurrency 3: A deployment needing a bound on a revocation's effect MUST bound Session's session_duration.
```

WHY:
The gate is point-in-time at the instant `Session.validate` runs. A revocation landing after that instant and before Permissions answers leaves a call that clears the gate and returns permitted or denied on a session that is revoked by the time the caller reads the answer. This is stated rather than cured: curing it would need a lock across two atoms that declare no such surface, and the honest bound is the session's own duration (Concurrency 3).

---

## Composition notes

```
Composition note 1: A deployment MUST declare which composing patterns the deployment wired in.
Deleted: Composition note 2. Composition state 4 owns it.
Composition note 3: A deployment MUST own the action_scope vocabulary.
Composition note 4: A deployment MUST NOT read this composition as a session lifecycle surface.
```

WHY:
[Login](./login.md) is this composition's lifecycle complement: Login wires `Credential.verify → Session.issue` and owns `revoke_sessions_for_credential`, and this composition wires `Session.validate → Permissions.permitted` at access time. The two need no coordination — a revocation Login cascades is visible to the next [Check Permitted] call because `Session.validate` reads the same store, which is the whole of the integration.

[Privileged Access Provisioning](./privileged-access-provisioning.md) enforces the same gate at the head of `exercise_access` and is not a use of this composition. The library treats them as independent implementations of one principle at two lifecycle points; whether that duplication should be shared is a design question for a deployment building both surfaces.

---

## Terms

The canonical concepts this spec refers to. Each `[Term]` marker in the prose above links to its term entry here. A term entry states what the concept *is*, in plain English, plus its **Kind** — one of five: **Type** (a thing or category), **Operation** (a behavior), **Member** (a value of an enumerated Type), or, for a named datum, **Field** (a datum a Type carries — *what does it carry?*) or **Parameter** (a value an Operation needs — *what does it need?*). A term entry also names the Type it is a **Member of** / **Field of**, the Operation it is a **Parameter of**, and its **Role** where the domain assigns one. A term entry carries one **Projects** line — the concept's single canonical lowering token, the one place the concrete name stays visible on the page — for every Field, Parameter, and pinned/wire Member. Everything else about casing (each target's snake / camel / pascal / const / wire form) is **derived** from that one token by [`tools/harness/term-adapter.mjs`](../tools/harness/term-adapter.mjs), never hand-written. This is a minimal, stateless composition — a gate — so its own concepts are just the single action it exposes ([Check Permitted]) and its two own rejections ([Session Invalid], the gate refusal; [Invalid Request], the boundary refusal — composition-introduced, since neither wired constituent operation can produce it). It introduces **no cross-atom state** and no new data, so there is nothing else to carry a term entry: the emergent guarantees it owns — the session-gates-authorization ordering (Invariant 1) and the principal binding (Invariant 2) — are structural properties, not data. References to the constituent atoms and their operations — Session's `validate` / `revoke`, Permissions' permitted — and the relayed outcomes (permitted, denied) and the `invalid(...)` reasons (`expired` / revoked / not-known) Session returns, remain qualified/backticked, not carded here. *(annotation.md Terms registry; representational only — it changes no guarantee, invariant, or behavior of the composition above.)*

### Vocabulary

Term qualifiers: migrated — rewritten in GRACE lang v0.40 (2026-09-14).

Term terms: composition, constituents, boundary predicate, blank, length bound, valid answer, invalid answer, admitted gate.

Term record verbs: validate, call, answer, accept, read, write, store, derive, evaluate, compare, trim, normalize, equal, stand, follow, reach, find, name, own, discharge, obey, change, replace, hold, serve, compose, declare, pin, bound, issue, terminate, grant, revoke, expand, match, aggregate, distinguish, record, detect, claim, query, receive, cover, case-fold.

Term actors: the composition; the constituents; a deployment; an auditor; a caller; a principal; a session; a grant; an argument; an answer.

Term value sets: check_permitted answers permitted | denied and refuses invalid-request | session-invalid(validation failure). invalid answer reasons = expired | revoked | not-known.

Term cited: `execution-contract.md` §Composition state — the no-stored-state classification. [Session](../atoms/session.md) `Composition note 4` — the gate obligation. [Permissions](../atoms/permissions.md) `Composition note 2` — the scope vocabulary. [Permissions](../atoms/permissions.md) `Composition note 3` — the caller-to-subject binding; validation failure: Session.

#### Check Permitted

The composition's single action: it validates the presented session and, only if valid, evaluates whether the session's own principal holds the requested permission — `Session.validate` before `Permissions.permitted`, always with the session-extracted `principal_ref` (Invariant 1 through 2). Returns permitted or denied (Permissions' result, passed through unmodified), or [Session Invalid] when the gate does not clear, or [Invalid Request] for inputs failing the boundary predicate.

Kind: Operation

#### Session Invalid

The composition's own gate rejection from [Check Permitted] — returned when `Session.validate` does not return `valid`: the session is `expired`, revoked, or not-known. It terminates the call **before Permissions is consulted** (Invariant 1), and is structurally distinct from a denied result (which means the gate cleared and the permission was evaluated — Invariant 3). Carries the reason.

Kind:      Member
Member of: the check-permitted rejection
Role:      Rejection
Projects:  session-invalid

#### Invalid Request

The composition's own boundary rejection from [Check Permitted] — returned when session_token or action_scope fails the Primitive-policies predicate (null, empty, whitespace-only, or over the deployment-pinned length cap). Composition-introduced: neither wired constituent operation produces it, and neither constituent is consulted when it fires.

Kind:      Member
Member of: the check-permitted rejection
Role:      Rejection
Projects:  invalid-request

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a [Term] marker to its term entry heading above (kramdown
     auto-generates the heading anchors on GitHub Pages). Standard CommonMark /
     kramdown; no plugin required. -->

[Check Permitted]: #check-permitted
[Session Invalid]: #session-invalid
[Invalid Request]: #invalid-request

---

#### Length Bound

The cap a deployment pins for an opaque argument at the composition boundary. The value is the deployment's choice; that a cap exists is this composition's contract, and an argument over it is refused as [Invalid Request] before either constituent runs (Primitive policy 1, Primitive policy 4).

Kind:      Parameter
Parameter of: the deployment
Projects:  length_bound

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a [Term] marker to its term entry heading above. -->

[Check Permitted]: #check-permitted
[Session Invalid]: #session-invalid
[Invalid Request]: #invalid-request
[Length Bound]: #length-bound

---

## Standards references

*Anchors: NIST (National Institute of Standards and Technology — US federal standards body) SP 800-53 AC-3 (Access Enforcement), NIST SP 800-53 AC-12 (Session Termination), NIST SP 800-63B §7 (re-authentication at resource access), OWASP (Open Worldwide Application Security Project) ASVS V3.3 (Application Security Verification Standard — session expiry enforced at the resource level), PCI DSS (Payment Card Industry Data Security Standard) Requirement 7 (restrict access to system components) + Requirement 8 (authenticate access to system components), HIPAA (US Health Insurance Portability and Accountability Act) §164.312(a)(1) (access control), HIPAA §164.312(d) (person or entity authentication), ISO/IEC 27001 §A.9.4.1 (International Organization for Standardization / International Electrotechnical Commission information-security standard — information access restriction).*

**NIST SP 800-53 AC-3** requires that the information system enforces approved authorizations for logical access. The gate ensures no authorization is evaluated under a session the system no longer considers valid.

**AC-12** requires that the information system terminates sessions after defined conditions. The termination itself is Session's and [Login](./login.md)'s act; what this composition contributes is the access-time complement — a session the system has terminated, whether by expiry, logout, or cascade from Login's `revoke_sessions_for_credential`, is refused at the composition boundary on every subsequent [Check Permitted] call, so a terminated session buys no further authorization.

**OWASP ASVS V3.3** specifically requires that session expiry is enforced at the *resource* level, not only by the session management layer. The composition satisfies this by re-validating the session token on every [Check Permitted] call rather than relying on an earlier validation result cached in the request context.

---

## Status

`grounded on Final Critique 8 — 2026-08-26` — see the Ledger.

## Ledger

```
status: grounded on Final Critique 8 — 2026-08-26
formal: verified — session-gated-authorization.als, no twin, 2026-06-03
last gate: 2026-08-26 — Final Critique 8, fresh reader — clean

open: none
```

## Decisions

Directional changes only — the turns a future reader must know the pattern took, and why. Everything smaller lives in the commit that made it: `git log -- compositions/session-gated-authorization.md`.

- **2026-09-14 — Rewritten in GRACE lang v0.40; nothing but language changed.** *Chose:* the single action as a signature block with `Action wiring` carrying the two-step gate, `Primitive policy` carrying the boundary predicate, `Concurrency` carrying the revocation race, the four invariant numbers unchanged, and the acceptance section's two declared tiers split into `Check` and `External check` exactly as the prose divided them. *Over:* the prose spec. *Because:* the migration plan; nothing in the corpus cites this composition by label, so the rewrite is free of frozen-number risk. The families are the wiring surfaces this composition actually has — no `Event schema`, no `Replay`, because it stores nothing and rebuilds nothing.
- **2026-09-14 — The gate is Session's, the closure is this composition's, and the Summary said both were emergent.** *Chose:* to cite the gate and own the closure — `Composes 7` names [Session](../atoms/session.md)'s `Composition note 4`, `Invariant 1.2` through `Invariant 1.4` are tombstoned to it, `Invariant 1.1` stands, and the Summary now claims exactly the two rules this composition holds. *Over:* carrying the prose's *emergent* claim unchanged, which the atom contradicts; and over deleting Invariant 1 entirely, which was the reviewer's counsel and cuts one rule too deep. *Because:* `Composition note 4` fires on an invalid answer *given* and `Invariant 1.1` fires on no valid answer *given*, so they do not normalize identically (Authority 4) — a deployment that skipped `validate` altogether would satisfy the note and breach the invariant. `Authority 6` forbids a citing spec to restate a rule, which is what the three enumerations did; it does not reach a rule that is strictly stronger. [Permissions](../atoms/permissions.md)'s `Composition note 3` is the third shape again: it assigns the caller-to-subject binding without stating it, so `Invariant 2` is owned here outright. The maintainer's ruling settles `open-questions.md` §*Which direction a rule may point across a seam*, open since council read 36: **atoms may bind compositions; a composition cites what the composition inherits and owns what the composition adds** (council read 53).

NOTE: End of Session-Gated Authorization.
