---
title: Session
parent: Atomic Concepts
has_toc: true
toc: true
---

# Session

<details markdown="block">
<summary>Table of contents</summary>
{: .text-delta }
1. TOC
{:toc}
</details>

## Summary

Session answers "is this login still good, and for whom?" without re-checking the password on every request. When a principal logs in, a session is issued: a record tying that principal to a time-limited validity window, identified by a random token the caller presents on later requests.

Checking a token returns one of four clearly separated answers — valid, and for which principal and until when; expired; revoked; unknown. They are never lumped into one "no," because a lapsed login, a deliberately cancelled one, and a token that never existed call for different responses.

A session is stored [Active] until it is deliberately cancelled — [Revoked], with who, when and why recorded, and that is permanent. It can also simply run out. When its window passes the session is *shown* expired, a status worked out on the fly by comparing the clock to the deadline, never written into the record and never a stored state. The deadline is fixed at issue and never changed; a session that needs to last longer is re-issued as a new record rather than extended in place. That keeps every session's validity window fully auditable from the record alone.

This is the mechanism behind browser sessions, API (Application Programming Interface) access tokens, mobile logins and short-lived elevated-access windows. It deliberately does not check credentials, decide what the principal may do, or run the login flow — each is a separate pattern.

*Also known as: a login session, an authenticated session, an access token, a session ticket.*

---

## Intent

WHY:
A system that authenticates once and then permits action across many requests needs to answer *is this principal still authenticated?* without repeating the credential check every time. A session is that answer made durable: a bounded-lifetime record attesting that a principal completed authentication at a known moment and that the result has not been invalidated since.

The atom isolates that attestation from everything around it. It does not verify credentials — that is [Credential](./credential.md)'s surface. It does not decide what the principal may do — that is [Permissions](./permissions.md)'. It does not sequence the login flow, the multi-factor challenge and the issuance — that is [Login](../compositions/login.md)'s. It answers one structural question: given this token, is there an active, unexpired, unrevoked session for a known principal? And the answer is one of four outcomes, derivable from the records alone.

The time bound is the atom's core commitment, and the discipline around it is where most session designs go wrong. `expires_at` is set at issue and never mutated. A session needing a longer life is re-issued — a new record, a new token — never extended in place. That immutability is what makes every session's window auditable from one record: no history table, no event log, no developer's account of whether an extension was granted. The record says when validity ends, and that field never changes.

The second commitment is that lapsing is *derived*, not written. There is no `expire` action, no `expired_at` column, and no stored [Expired] status. A session past its deadline is computed as expired at read time from the immutable deadline against the injected clock. Nothing fires, nothing is stamped, no scheduler is needed — and the stored state space stays exactly two values, which removes the failure mode where a flag lags the clock it is meant to idealize.

## Structure

### Identity model

```text
Identity 1: The atom MUST identify a session by the session_token.
Identity 2: The session_token MUST serve as the bearer credential [Validate] accepts.
Identity 3: The host MUST allocate a session_token at the seam.
Identity 4: The transition MUST NOT allocate a session_token.
Identity 5: The atom MUST NOT reuse a session_token.
Identity 6: The atom MUST NOT change a session_token.
Identity 7: The atom MUST NOT carry a session identifier beside the session_token.
Identity 8: Two sessions MUST NOT share a session_token.
Identity 9: The deployment MUST draw a session_token from a cryptographically secure random source.
Identity 10: The deployment MUST NOT draw a session_token from the session's public properties.
Identity 11: The atom MUST NOT interpret a principal_ref.
Identity 12: The atom MUST NOT confirm that a principal_ref names an authenticated principal.
```

Terms › `session`: one bounded-lifetime attestation that a principal completed authentication — a [Session], the record this atom holds.

Terms › `session_token`: the opaque value naming one session — a [Session Token]; unguessable, host-allocated at the seam, and the capability [Validate] and [Revoke] accept.

Terms › `principal_ref`: the opaque reference naming the authenticated principal — a [Principal Ref].

Terms › `issued_by_ref`: the opaque reference naming the mechanism that issued the session — an [Issued By Ref].

Terms › `seam`: the atom's I/O boundary as `execution-contract.md` §Logic confinement declares it; the host injects the clock reading, the session_token and the token's random material here.

Terms › `transition`: the atom's evaluation of one call against the session store, as `execution-contract.md` §Logic confinement declares it.

WHY:
The token is both identity and bearer credential, and that is deliberate rather than a shortcut: it is how session systems actually work — the cookie *is* the session identifier — and it makes [Validate] a lookup rather than a join. A separate opaque id beside the token would add indirection and buy nothing at this atom's scope (Identity 7).

Because the token is the credential, its security properties are structural and not deployment taste. Two sessions for one principal issued at different moments have unrelated tokens, and nothing about a token is derivable from the principal or the issue time (Identity 9, Identity 10, Configuration 3–5).

### Configuration

```text
Configuration 1: The deployment MUST configure a default session duration.
Configuration 2: IF the default session duration NOT EXISTS THEN [Issue] MUST answer invalid-request.
Configuration 3: The deployment MUST supply the session_token's random material at the seam.
Configuration 4: The transition MUST NOT generate the session_token's random material.
Configuration 5: The session_token's random material MUST NOT fall below the token entropy.
Configuration 6: The deployment MUST own the session_token's format.
Configuration 7: The deployment MUST own whether the store holds a session_token raw.
```

Terms › `default session duration`: the window [Issue] applies where the call supplies no `session_duration`; deployment configuration, and its absence is a misconfiguration rather than an operating state.

Terms › `token entropy`: 128 bits of cryptographically secure random material — the floor a `session_token` is drawn from, sufficient for negligible collision probability and for unguessability.

WHY:
A session store with no duration policy is a misconfigured deployment, not a store that issues unbounded sessions — so the absence is a refusal at [Issue] rather than a silent default of forever (Configuration 1, Configuration 2, Invariant 10).

Raw-versus-hashed token storage is left open because both are conformant: storing raw is simpler, storing a hash means a database breach yields no usable token, and the choice belongs in the composing pattern's configuration where it can be documented (Configuration 7).

### Operations

```
issue(principal_ref, issued_by_ref, session_duration) → session_token | rejected(invalid-request | storage-failure)
validate(session_token) → valid(principal_ref, expires_at) | invalid(expired | revoked | not-known)
revoke(session_token, revoked_by_ref, reason) → revoked | rejected(invalid-request | already-terminal | not-known | storage-failure)
read(filter) → session_records
```

```text
Operation 1: [Issue] MUST record EXACTLY ONE session per successful call.
Operation 2: [Issue] MUST stand the session in active.
Operation 3: [Issue] MUST answer the session_token.
Operation 4: IF principal_ref NOT EXISTS THEN [Issue] MUST answer invalid-request.
Operation 5: IF issued_by_ref NOT EXISTS THEN [Issue] MUST answer invalid-request.
Operation 6: IF session_duration NOT EXISTS THEN [Issue] MUST apply the default session duration.
Operation 7: [Issue] MUST accept a session_duration ONLY IF the session_duration EXCEEDS the zero duration.
Operation 8: IF the session_duration NOT EXCEEDS the zero duration THEN [Issue] MUST answer invalid-request.
Operation 9: [Issue] MUST stamp issued_at from the injected now.
Operation 10: [Issue] MUST stamp expires_at from the expiry deadline.
Operation 11: [Issue] MUST NOT recompute expires_at from a later clock reading.
Operation 12: IF the store refuses the write THEN [Issue] MUST answer storage-failure.
Operation 13: [Validate] MUST answer EXACTLY ONE OF valid, expired, revoked, not-known.
Operation 14: IF the session_token names no session THEN [Validate] MUST answer not-known.
Operation 15: IF the session stands in revoked THEN [Validate] MUST answer revoked.
Operation 16: IF the session is lapsed THEN [Validate] MUST answer expired.
Operation 17: [Validate] MUST answer expired ONLY IF the session stands in active.
Operation 18: [Validate] MUST answer valid ONLY IF the session stands in active AND the session is not lapsed.
Operation 19: [Validate] MUST carry principal_ref and expires_at in a valid answer.
Operation 20: [Validate] MUST NOT write.
Operation 21: [Validate] MUST NOT refuse a call.
Operation 22: IF the session_token names no session THEN [Revoke] MUST answer not-known.
Operation 23: IF the session stands in revoked THEN [Revoke] MUST answer already-terminal.
Operation 24: [Revoke] MUST answer already-terminal ONLY IF the session stands in revoked.
Operation 25: IF the session stands in active AND revoked_by_ref NOT EXISTS THEN [Revoke] MUST answer invalid-request.
Operation 26: IF the session stands in active AND reason NOT EXISTS THEN [Revoke] MUST answer invalid-request.
Operation 27: [Revoke] MUST accept a lapsed session.
Operation 28: [Revoke] MUST stand the session in revoked.
Operation 29: [Revoke] MUST stamp revoked_at from the injected now.
Operation 30: [Revoke] MUST record revoked_by_ref on the session.
Operation 31: [Revoke] MUST record the reason as the revocation_reason.
Operation 32: [Revoke] MUST commit the status move and the three revocation fields in one operation.
Operation 33: [Revoke] MUST answer revoked.
Operation 34: IF the store refuses the write THEN [Revoke] MUST answer storage-failure.
Operation 35: A refused write MUST leave the store as the call found the store.
Operation 36: [Revoke] MUST accept the session_token as the whole authorization.
Operation 37: [Read] MUST answer EVERY session the filter matches.
Operation 38: [Read] MUST carry the effective_status on EVERY answered session.
Operation 39: [Read] MUST NOT write.
Operation 40: A liveness query MUST rest on the effective_status.
Operation 41: A liveness query MUST NOT rest on the stored status alone.
Operation 42: The host MUST read the clock at the seam.
Operation 43: The transition MUST NOT read a clock.
Operation 44: The business caller MUST NOT supply now.
Operation 45: The atom MUST NOT offer an expire action.
Operation 46: The atom MUST NOT offer an extend action.
Operation 47: The atom MUST NOT offer an un-revoke action.
```

Terms › `now`: the wall-time reading the host takes at the seam and hands to the transition — a [Now], as `execution-contract.md` §Logic confinement declares it; never read inside the transition, never supplied by the business caller.

Terms › `business caller`: the party whose action the call carries, as `execution-contract.md` §Logic confinement declares it; never the source of an injected value.

Terms › `session_duration`: the window a [Issue] call asks for — a [Session Duration]; consumed to compute the expiry deadline, never stored under this name.

Terms › `zero duration`: a duration of no length — the floor a `session_duration` must exceed, which refuses zero and every negative value.

Terms › `issued_at`: the instant the session was recorded — an [Issued At].

Terms › `expiry deadline`: `issued_at + session_duration` — what [Issue] stores as `expires_at`, computed once at issue.

Terms › `expires_at`: the instant the session's validity ends — an [Expires At]; stamped at issue, never changed, never absent.

Terms › `lapsed`: the session stands in `active` and `now` is no earlier than the session's `expires_at` — the condition [Validate] derives and never stamps.

Terms › `effective_status`: `expired` where the session is lapsed, and the stored status otherwise — an [Effective Status]; a pure projection over the session and `now`, never stored.

Terms › `revoked_at`: the instant the session was cancelled — a [Revoked At].

Terms › `revoked_by_ref`: the opaque reference naming the actor that cancelled the session — a [Revoked By Ref].

Terms › `revocation_reason`: the stated ground for the cancellation — a [Revocation Reason], carried from the call's [Reason].

Terms › `reason`: the [Revoke] argument the session keeps as `revocation_reason` — a [Reason].

Terms › `filter`: the selection a [Read] call scopes the answer by — a [Filter]; consumed per call, never stored.

Terms › `liveness query`: any query for the sessions in force — the administrative surfaces, and the auditor's reconstruction.

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the store |
|---|---|---|---|
| [Issue] | both references present, duration positive or defaulted, store accepts | the new `session_token` | one record lands in [Active], `issued_at` and `expires_at` stamped (Operation 1, Operation 9, Operation 10) |
| [Issue] | a blank reference, a non-positive duration, or no configured default | [Invalid Request] | none (Operation 4, Operation 5, Operation 8, Configuration 2) |
| [Validate] | token names nothing | [Not Known] | none — the call reads (Operation 14, Operation 20) |
| [Validate] | stored status is [Revoked] | [Invalid Revoked] | none — returned even where the window is still open (Operation 15) |
| [Validate] | stored [Active], `now` has reached `expires_at` | [Invalid Expired] | none — derived, nothing written (Operation 16, Operation 17) |
| [Validate] | stored [Active], `now` short of `expires_at` | [Valid], carrying [Principal Ref] and [Expires At] | none (Operation 18, Operation 19) |
| [Revoke] | token names a session in [Active], attribution present | `revoked` | [Active] → [Revoked], three fields stamped (Operation 28–32) |
| [Revoke] | token names a session in [Active] past its deadline | `revoked` | as above — a lapse is not a stored terminal (Operation 27) |
| [Revoke] | token names nothing | [Not Known] | none (Operation 22) |
| [Revoke] | stored status is already [Revoked] | [Already Terminal] | none (Operation 23, Operation 24) |
| [Revoke] | session in [Active], blank attribution | [Invalid Request] | none (Operation 25, Operation 26) |
| either write | store refuses | [Storage Failure] | none (Operation 12, Operation 34, Operation 35) |
| *a window lapses* | `now` reaches `expires_at` | nothing is called | **nothing written** — no action, no stamp, no scheduler (Expiry 1–5) |
| [Read] | a filter | the matching sessions, each carrying its `effective_status` | none (Operation 37, Operation 38) |

WHY:
The order of [Validate]'s four answers is load-bearing and not an optimization. The [Active] test is consulted only once the [Revoked] test has failed, so a session revoked *and* past its deadline answers [Invalid Revoked] and never [Invalid Expired] — an implementation must not short-circuit on the cheap numeric comparison before reading the status (Operation 15, Operation 17, Invariant 3). The distinction is operational: a revocation is a decision somebody made — a logout, a compromise response, an administrative act — and a lapse is normal end-of-life, and a composing pattern may well answer them differently.

The boundary is exact. [Valid] holds while `now` is short of `expires_at`; the instant `now` reaches it, [Invalid Expired] fires (Operation 16, Operation 18).

[Validate] is a pure read on every path, including the lapsed one. It increments no counter, touches no field and produces no side effect, because there is no stored [Expired] to transition into (Operation 20, Expiry 1).

A lapsed session is still revocable, and that is the one place this atom's shape surprises a reader. The only stored terminal is [Revoked]; a still-[Active] record past its deadline reads [Expired] by derivation but is not closed to [Revoke] — so a deployment that wants an attributed record of closing a session that had already lapsed can have one (Operation 27, Invariant 5). A breach response that revokes every exposed token, lapsed ones included, is the case this serves.

Revocation takes the token as the whole authorization, and the atom exposes no way to enumerate tokens — which is honest only because the token is unguessable (Identity 9, Operation 36, Non-goal 18).

### State

```text
State 1: EVERY session MUST stand in EXACTLY ONE OF active, revoked.
State 2: EVERY session MUST carry session_token, principal_ref, issued_by_ref, issued_at, expires_at and status.
State 3: EVERY session MUST carry an expires_at.
State 4: A revoked session MUST carry revoked_at, revoked_by_ref and revocation_reason.
State 5: An active session MUST NOT carry revoked_at.
State 6: An active session MUST NOT carry revoked_by_ref.
State 7: An active session MUST NOT carry revocation_reason.
State 8: A session MUST NOT carry a stored expired status.
State 9: A session MUST NOT carry an expiry timestamp beside expires_at.
State 10: The atom MUST NOT offer a transition out of revoked.
State 11: The atom MUST NOT remove a session from the store.
State 12: The atom MUST NOT hold a permission.
State 13: The atom MUST NOT hold a device context.
State 14: The atom MUST NOT hold a concurrency bound per principal_ref.
```

Terms › `status`: `active` | `revoked` — the stored status; in force, or cancelled and terminal. `expired` is not a value of it.

WHY:
The stored state space is two values because lapsing needs no third. [Expired] is a *read projection*, so the store holds what was decided and derives what the clock decides (State 1, State 8, Expiry 1–5). That is what removes the stored-flag-that-lags-the-clock failure mode `pressure-testing.md` §Formal-model authoring pitfalls names.

#### Expiry

```text
Expiry 1: A lapse MUST NOT write to the session.
Expiry 2: A lapse MUST NOT fire a transition.
Expiry 3: The atom MUST NOT stamp an expiry.
Expiry 4: The deployment MUST NOT schedule a lapse.
Expiry 5: The atom MUST derive a lapse from expires_at against now.
Expiry 6: A lapsed session MUST NOT stand in a stored terminal.
Expiry 7: [Read] MUST surface a lapse as the effective_status.
Expiry 8: [Validate] MUST surface a lapse as expired.
```

### Invariants

- **Invariant 1 — Issue immutability.**
  ```text
  Invariant 1.1: A recorded session's session_token, principal_ref, issued_by_ref, issued_at and expires_at MUST NOT change.
  Invariant 1.2: A session's status and revocation fields MUST stand as the only fields a later action writes.
  ```
- **Invariant 2 — Expiry timestamp immutability.**
  ```text
  Invariant 2.1: No action MUST change a recorded expires_at.
  Invariant 2.2: A deployment extending a session MUST call [Issue].
  ```
- **Invariant 3 — Validity bound conjunctive, by derivation.**
  ```text
  Invariant 3.1: [Validate] MUST answer valid ONLY IF the session_token names a session AND the session stands in active AND the session is not lapsed.
  Invariant 3.2: [Validate] MUST derive the lapse from expires_at against now.
  Invariant 3.3: [Validate] MUST NOT answer expired for a revoked session.
  ```
- **Invariant 4 — Revocation absorbing.**
  ```text
  Invariant 4.1: [Validate] MUST NOT answer valid for a revoked session.
  ```
- **Invariant 5 — Stored terminal absorbing.**
  ```text
  Invariant 5.1: A revoked session MUST NOT leave revoked.
  Invariant 5.2: [Revoke] MUST answer already-terminal against a revoked session.
  Invariant 5.3: A lapsed session MUST reach [Revoke].
  ```
- **Invariant 6 — Four structurally distinct validate outcomes.**
  ```text
  Invariant 6.1: [Validate] MUST answer EXACTLY ONE OF valid, expired, revoked, not-known.
  Invariant 6.2: An implementation MUST NOT merge two validate answers.
  ```
- **Invariant 7 — Session token uniqueness.**
  ```text
  Invariant 7.1: Two sessions MUST NOT share a session_token.
  Invariant 7.2: [Issue] MUST NOT allocate a session_token any session carries.
  ```
- **Invariant 8 — Revocation attribution completeness.**
  ```text
  Invariant 8.1: EVERY revoked session MUST carry a revoked_at.
  Invariant 8.2: EVERY revoked session's revoked_by_ref MUST carry a non-whitespace character.
  Invariant 8.3: EVERY revoked session's revocation_reason MUST carry a non-whitespace character.
  ```
- **Invariant 9 — Session durability over this atom's own surface.**
  ```text
  Invariant 9.1: The atom MUST NOT offer a removal surface.
  Invariant 9.2: An action the atom offers MUST NOT reduce the session count.
  Invariant 9.3: A storage-failure rejection MUST leave no partial session in the store.
  ```
  WHY: disposal under a retention policy is the composing pattern's declared act, outside this atom's own surface — the same scoping [Retention Window](./retention-window.md) carries elsewhere (Non-goal 20, Non-goal 21).
- **Invariant 10 — Every session has a finite lifetime.**
  ```text
  Invariant 10.1: EVERY session MUST carry an expires_at.
  Invariant 10.2: The atom MUST NOT record a session carrying no expires_at.
  ```
- **Invariant 11 — Expiry absorbing, by derivation.**
  ```text
  Invariant 11.1: [Validate] MUST NOT answer valid for a lapsed session.
  Invariant 11.2: A lapsed session MUST stand lapsed at EVERY later now.
  ```
  WHY: the expiry analogue of Invariant 4, and the asymmetry is the point — revocation is an absorbing *stored* state, a lapse is an absorbing *derived* condition. Invariant 11.2 rests on the deadline's immutability (Invariant 2.1) and on the deployment's clock discipline (Clock semantics 1); both paths that foreclose a valid answer are stated so the verification surface is symmetric.
- **Invariant 12 — Expiry is derived, never written.**
  ```text
  Invariant 12.1: A session MUST NOT carry a stored expired status.
  Invariant 12.2: A session MUST NOT carry an expiry timestamp beside expires_at.
  Invariant 12.3: A lapse MUST NOT write to the session.
  Invariant 12.4: The effective_status MUST rest on expires_at and now alone.
  ```

Invariants 1, 2 and 10 together give the *temporal auditability* property — every session's window is fully determined from one record, with no mutable validity field. Invariants 3, 6 and 12 give *validation clarity* — the outcome of any [Validate] call is unambiguous, distinguishable, and computed from the record and the injected clock alone. Invariants 4 and 11 give *terminal finality* — neither a revoked session nor a lapsed one resurfaces as valid by any path.

---

## Examples

### Browser login — issue and validate

A user logs in through the [Login](../compositions/login.md) composition. After the credential check, Login calls `issue(principal_ref: user_u91, issued_by_ref: login_svc_l01, session_duration: 3600)` → `tok_abc123`, with the host injecting `now: 2026-09-01T10:00:00Z` at the seam. The record lands in [Active] with `issued_at: 10:00:00Z` and `expires_at: 11:00:00Z`. The token goes to the browser as a session cookie.

Twenty minutes later the user requests a protected page. `validate(tok_abc123)` → `valid(principal_ref: user_u91, expires_at: 11:00:00Z)`, with `now: 10:20:00Z` injected. The atom finds the record, reads stored `active`, finds `now` short of the deadline, and answers. Nothing changes.

### Logout — revoke

The user clicks log out. `revoke(tok_abc123, revoked_by_ref: user_u91, reason: "user-initiated-logout")` → `revoked`, with `now: 10:45:00Z` injected. The record moves to [Revoked] with all three fields stamped. `expires_at` stays `11:00:00Z` — that field is immutable.

If the browser re-presents the old cookie at `10:50:00Z`: `validate(tok_abc123)` → `invalid(revoked)`. The stored status is read first, so the answer is [Invalid Revoked] and not [Invalid Expired], even though the session would have lapsed naturally fifteen minutes later (Operation 15).

### A window lapses — derived

The user closes the browser without logging out. The window passes at `11:00:00Z`. **No call is made and no write occurs** — there is no action to call. At `11:30:00Z` a new tab presents the same cookie: `validate(tok_abc123)` → `invalid(expired)`. The record is still stored `active`, never transitioned; the answer comes from `expires_at` against the injected `now`. Nothing is written, there is no expiry timestamp to write, and the record count is unchanged. A [Read] of the record now reports `effective_status: expired` (Expiry 1–8).

### Rejection paths

`issue(principal_ref: svc_s03, issued_by_ref: api_gateway_g01, session_duration: 0)` → `rejected(invalid-request)`. A zero-length window is not an operating state (Operation 8).

`revoke(tok_abc123, revoked_by_ref: admin_a01, reason: "incident-response")` against an already-revoked session → `rejected(already-terminal)`. The existing [Revocation Reason] is unchanged (Operation 23). A session that has merely *lapsed* is not a stored terminal, so the same call against a lapsed-but-unrevoked session succeeds and records the attribution (Operation 27).

`validate(tok_forged_xyz)` → `invalid(not-known)`. No record for the token — structurally distinct from [Invalid Revoked], because nothing was revoked and nothing exists (Operation 14, Invariant 6.1).

### Regulated adversarial scenarios

- **Regulator audit.** A HIPAA (Health Insurance Portability and Accountability Act) auditor asks whether access to a patient record at `14:32Z` on `2026-10-15` was under a valid, unrevoked session. The store yields `tok_abc123`: stored `active`, `issued_at: 14:00:00Z`, `expires_at: 15:00:00Z`, no `revoked_at`. Invariant 3.1 is the structural answer — at `14:32Z` the session was stored active and the deadline had not passed, so [Validate] would have answered [Valid]. The auditor confirms it from the record alone; there is no stored expiry flag to corroborate, only the immutable deadline (Check 3.1).
- **Disputed access.** A user denies access at `03:15` on `2026-11-20`. The investigator queries sessions for the principal live at that instant and finds `tok_abc123`: `issued_at: 2026-11-19T22:00:00Z`, `expires_at: 2026-11-20T06:00:00Z`, `issued_by_ref: login_svc_l01`. The session was in force. Whether the token was stolen is a separate investigation; what the records bound is the forensic window — issued through the Login service at 22:00, valid at 03:15, never revoked before the access. Who authenticated at 22:00 and against what credential is [Actor Identity](./actor-identity.md)'s record, wired by Login (Non-goal 1, Composition note 3).
- **Breach investigation.** Session tokens are found in an exposed log file. The investigator queries every session with `issued_by_ref: api_gateway_g01` inside the exposure window — 47 sessions across 31 principals — and reads each `effective_status` against the investigation clock: which are live, which lapsed, which were already revoked. The team then calls [Revoke] on every session not already revoked, *including the lapsed ones*, so that every closure is attributed (Operation 27). Invariant 8.1–8.3 is what lets an auditor six months later reconstruct which sessions were closed, by whom, when and why, with no recourse to the incident runbook.

---

## Generation acceptance

This atom's acceptance is what an external auditor can clear from the session store and the read-time clock the [Validate] and [Read] surfaces use, with no recourse to source code, runbooks or developer narration.

### Conformance checks

```text
Check 1.1: An auditor MUST find an expires_at on EVERY session (Invariant 10.1).
Check 1.2: An auditor MUST find one expires_at per session across the session's whole life (Invariant 2.1).
Check 2.1: An auditor MUST find no stored expired status on any session (Invariant 12.1).
Check 2.2: An auditor MUST find no expiry timestamp beside expires_at (Invariant 12.2).
Check 2.3: An auditor MUST find no field written by a lapse (Invariant 12.3).
Check 2.4: An auditor MUST reproduce the effective_status from expires_at against the read-time clock (Invariant 12.4).
Check 3.1: An auditor MUST reconstruct the sessions in force at a past instant from issued_at, expires_at and revoked_at (Invariant 3.1, Invariant 3.2).
Check 4.1: An auditor MUST find a revoked_at, a revoked_by_ref and a revocation_reason on EVERY revoked session (Invariant 8.1, Invariant 8.2, Invariant 8.3).
Check 5.1: An auditor MUST find the four validate answers distinguishable on the implementation's contract (Invariant 6.1, Invariant 6.2).
Check 6.1: An auditor MUST find no revoked session standing in active (Invariant 5.1).
```

NOTE: EVERY check names the rule the check tests.

WHY:
Check 3.1 is the reconstruction [Validate] itself applies: a session was in force at an instant when its `issued_at` does not follow that instant, its `expires_at` does, and its `revoked_at` is either absent or later. The stored status need not be consulted beyond *not revoked at that instant*, because the lapse is computed from the deadline rather than remembered — which is the whole point of Invariant 12 and the reason this check needs the store and a clock and nothing else.

Check 5.1 is the one check that reads a contract rather than records. Four distinguishable answers is a behavioural commitment, and no arrangement of stored fields can evidence it — a conforming store behind an implementation that collapses [Invalid Expired] and [Invalid Revoked] into one boolean fails Invariant 6.2 while every record looks correct.

## Non-goals

```text
Non-goal 1: The atom MUST NOT verify an authentication credential.
Non-goal 2: A deployment needing an authentication credential verified MUST compose [Credential](./credential.md).
Non-goal 3: The atom MUST NOT sequence a multi-factor challenge.
Non-goal 4: A deployment needing a login flow MUST compose [Login](../compositions/login.md).
Non-goal 5: The atom MUST NOT decide what a principal_ref may do.
Non-goal 6: A deployment needing an authorization decision MUST compose [Permissions](./permissions.md).
Non-goal 7: The atom MUST NOT extend a session in place.
Non-goal 8: A deployment needing a sliding window MUST call [Issue] again.
Non-goal 9: A composing pattern renewing a session MUST revoke the prior session.
Non-goal 10: The atom MUST NOT bind a session_token to a device.
Non-goal 11: A deployment needing device binding MUST check the device context outside the atom.
Non-goal 12: The atom MUST NOT bound how many sessions one principal_ref holds.
Non-goal 13: A deployment needing a concurrency bound MUST enforce the bound at the composing layer.
Non-goal 14: The atom MUST NOT propagate a revocation across a principal_ref's other sessions.
Non-goal 15: A deployment needing logout propagation MUST revoke the principal_ref's sessions one by one.
Non-goal 16: The atom MUST NOT define the session_token's format.
Non-goal 17: The atom MUST NOT define how the store holds a session_token.
Non-goal 18: The atom MUST NOT enumerate a session_token.
Non-goal 19: The atom MUST NOT seal a session against modification.
Non-goal 20: The atom MUST NOT bound how long a session is kept.
Non-goal 21: A deployment needing a retention bound MUST compose [Retention Window](./retention-window.md).
Non-goal 22: A deployment needing court-admissible records MUST compose [Tamper Evidence](./tamper-evidence.md).
Non-goal 23: The atom MUST NOT record who called [Issue].
Non-goal 24: A deployment needing attribution on issuance MUST compose [Actor Identity](./actor-identity.md).
```

WHY:
[Issue] makes no authentication judgement at all. It records a session for whatever `principal_ref` arrives, and it does not and cannot check that a credential was verified first — an implementation calling [Issue] without that check has a process error this atom cannot detect (Non-goal 1, Non-goal 2). The guard is [Login](../compositions/login.md)'s wiring, not a rule here.

Renewal is two calls and not one: a new [Issue] for the new window, and a [Revoke] of the prior token so the old one does not outlive the handover on its own deadline. Both actions are in scope; the renewal *policy* — what triggers it, how often — is the composing pattern's (Non-goal 7–9, Invariant 2.2).

The token is opaque and its format is deployment configuration — with one constraint that survives the choice, stated as rules rather than left here (Token format 1, Token format 2).

## Edge cases

### String policy

```text
String 1: The atom MUST compare a string input byte-exactly.
String 2: The atom MUST NOT trim a string input.
String 3: The atom MUST NOT normalize a string input.
String 4: The atom MUST NOT case-fold a string input.
String 5: The atom MUST read a whitespace-only string input as blank.
String 6: The deployment MUST set a maximum length per string input.
String 7: IF a string input EXCEEDS the maximum length THEN the action MUST answer invalid-request.
String 8: The deployment MUST canonicalize an opaque reference.
```

Terms › `verified answer`: the `verified` outcome [Credential](./credential.md)'s verification produces; cited from that atom, never restated here (Closed vocabulary 15).

Terms › `invalid answer`: [Validate]'s answer standing in `expired`, `revoked` OR `not-known` — every answer outside `valid`.

Terms › `authentication credential`: the material a principal presents to prove identity, as [Credential](./credential.md) declares it; distinct from the `session_token`, which is the bearer credential this atom's own [Validate] accepts (Identity 2).

Terms › `blank`: a value that is absent, empty, or carries only whitespace — what every presence check in this atom refuses; a blank argument NOT EXISTS.

WHY:
Byte-exactness means callers own canonicalization: two references differing only in case or normalization form are two distinct principals to this atom, and nothing here will reconcile them (String 1, String 8).

### Token format

```text
Token format 1: A claim set token's expiry claim MUST NOT differ from the session's expires_at.
Token format 2: A deployment extending a claim set token MUST call [Issue].
```

Terms › `claim set token`: a `session_token` whose format carries its own expiry claim — a JWT (JSON Web Token — a compact, signed token format carrying claims), for instance.

WHY:
The format is the deployment's (Configuration 6, Non-goal 16), but one constraint survives the choice: where the token carries its own expiry, this atom's immutability takes precedence over the format's native extension claims. A claim set that disagrees with the record is a second authority for when validity ends, and the record is the authority (Invariant 2.1).

### Clock semantics

```text
Clock semantics 1: The deployment MUST own the clock's monotonicity.
Clock semantics 2: The deployment MUST own the clock's honesty.
Clock semantics 3: The deployment MUST own the clock's synchronization.
Clock semantics 4: A guard MUST NOT read now.
Clock semantics 5: A rejection MUST NOT rest on now.
Clock semantics 6: The atom MUST NOT reconcile two readers disagreeing across the deadline.
Clock semantics 7: A deployment needing an externally verifiable timestamp MUST compose a trusted-timestamping pattern.
```

WHY:
This atom accepts no caller-supplied instant — the window arrives as a duration, and every timestamp is the seam's reading — so no guard needs the clock to refuse anything, and no rejection in the taxonomy depends on it (Clock semantics 4, Clock semantics 5). The clock's only jobs are stamping two immutable fields and feeding one pure derivation.

That derivation has a bounded consequence worth naming rather than hiding: two readers with slightly skewed clocks evaluating a session near its deadline may briefly disagree on whether it has lapsed. That is the standard read-time-derivation cost, it is bounded by the deployment's skew envelope, and it is harmless here because no write is at stake and revocation — the only stored terminal — is untouched by it (Clock semantics 6).

### Concurrency

```text
Concurrency 1: The implementation MUST serialize a status move on one session_token.
Concurrency 2: Two concurrent [Revoke] calls on one session_token MUST answer revoked once.
Concurrency 3: The [Revoke] call the serialization places second MUST answer already-terminal.
Concurrency 4: Two concurrent [Issue] calls carrying one principal_ref MUST record two sessions.
```

## Composition notes

```text
Composition note 1: A deployment MUST declare which composing patterns the deployment wired in.
Composition note 2: IF the verified answer NOT EXISTS THEN a composing pattern MUST NOT call [Issue].
Composition note 3: A composing pattern MUST own the attribution of an issuance.
Composition note 4: IF [Validate] gives an invalid answer THEN a composing pattern MUST NOT call [Permissions](./permissions.md).
Composition note 5: A composing pattern MUST own the renewal policy.
Composition note 6: A composing pattern MUST own the logout propagation across a principal_ref's sessions.
Composition note 7: A composing pattern MUST own the device binding.
Composition note 8: A composing pattern MUST own the concurrency bound per principal_ref.
Composition note 9: A composing pattern MUST own the retention of the session store.
Composition note 10: A composing pattern reading the session store MUST NOT write to the session store.
Composition note 11: The atom MUST NOT detect an authentication credential's revocation.
```

WHY:
[Login](../compositions/login.md) is the wiring this atom exists inside: a successful `Credential.verify` produces the [Issue] call, both attested under the verified principal. It carries a cascade invariant neither constituent holds alone — revoking the underlying [Credential](./credential.md) invalidates every session derived from it, which is a property of the composition's emergent state (Composition note 2).

[Session-Gated Authorization](../compositions/session-gated-authorization.md) gates every [Permissions](./permissions.md) query on session validity: the pre-check fires first, and a stale or revoked session rejects before Permissions is consulted (Composition note 4). [Privileged Access Provisioning](../compositions/privileged-access-provisioning.md) does the same at the head of `exercise_access` — a non-[Valid] answer blocks the exercise before a capability token is presented — and reads the store without writing to it, which is why Composition note 10 exists. [External Onboarding](../compositions/external-onboarding.md) admits the identity and registers the credential; the first session arrives through Login in the step immediately after, so this atom is not a constituent of that composition.

[Actor Identity](./actor-identity.md) pairs an [Issue] with an attestation where non-repudiation is required, and [Audit Trail](../compositions/audit-trail.md) is where the issuance and revocation events are recorded. [Tamper Evidence](./tamper-evidence.md) hash-chains the store, revocation attribution included, for deployments that need cryptographic proof no record was altered after the fact.

## Terms

Each `[Term]` marker above links to its card here; a card states what the concept *is* and its **Kind**.

### Vocabulary

Terms › `actors`: the atom; the host; the transition; the implementation; the deployment; a composing pattern (also: a pattern); a business caller; a caller; a guard; a principal; an auditor; the store; a session; a status; a lapse; a liveness query; a rejection; a write; an action; a string input; an opaque reference; the session count; the session_token's random material.

Terms › `records`: `session` — one bounded-lifetime attestation, carrying `session_token`, `principal_ref`, `issued_by_ref`, `issued_at`, `expires_at`, `status` and, once cancelled, `revoked_at`, `revoked_by_ref` and `revocation_reason`.

Terms › `record verbs`: identify, serve, offer, compare, allocate, reuse, change, carry, share, draw, interpret, confirm, configure, supply, generate, fall, own, hold, record, stand, answer, apply, accept, stamp, recompute, derive, surface, write, fire, schedule, read, refuse, commit, leave, rest, remove, merge, return, reach, find, reproduce, reconstruct, verify, sequence, decide, extend, call, revoke, bind, check, bound, enforce, propagate, define, enumerate, seal, compose, trim, normalize, case-fold, set, exceed, differ, give, reduce, detect, canonicalize, reconcile, serialize, declare.

Terms › `value sets`: issue answers = session_token | rejected(invalid-request | storage-failure). validate answers = valid(principal_ref, expires_at) | invalid(expired | revoked | not-known). revoke answers = revoked | rejected(invalid-request | already-terminal | not-known | storage-failure). read answers = the matching sessions, each carrying its `effective_status`. `status` = active | revoked.

Terms › `bounds`: `token entropy` (the floor a session_token's random material is drawn from); `default session duration` (the window [Issue] applies where the call supplies none); `zero duration` (the floor a session_duration must exceed); `maximum length` (the deployment's cap per string input).

Terms › `cadences`: empty.

Terms › `qualifiers`: `migrated` — rewritten in GRACE lang v0.35 (2026-09-12).

Terms › `terms`: `session`, `session_token`, `principal_ref`, `issued_by_ref`, `seam`, `transition`, `default session duration`, `token entropy`, `now`, `business caller`, `session_duration`, `zero duration`, `issued_at`, `expiry deadline`, `expires_at`, `lapsed`, `effective_status`, `revoked_at`, `revoked_by_ref`, `revocation_reason`, `reason`, `filter`, `liveness query`, `status`, `blank`, `maximum length`.

#### Session

The record this atom defines: a time-limited authenticated channel — a durable attestation that a principal was authenticated at a specific moment, queryable until the [Session] lapses or is revoked. It carries its [Session Token], [Principal Ref], [Issued By Ref], [Issued At], [Expires At], [Status], and the revocation fields; its [Expires At] is set once on [Issue] and never mutated. A [Session] that needs a longer lifetime is re-issued, never extended.

Kind: Type

#### Issue

The behavior the composing Login pattern invokes to record a new [Session] for a principal. It creates the record in [Active] with a fresh [Session Token], stamps [Issued At] and computes [Expires At] from the injected [Now] and the [Session Duration], and returns the [Session Token]. It makes no authentication judgment — it issues a [Session] for whatever [Principal Ref] it is given.

Kind: Operation

#### Validate

The read-only behavior a composing pattern invokes to answer, by [Session Token], whether there is a live [Session]. It returns one of four structurally distinct outcomes — [Valid], [Invalid Expired], [Invalid Revoked], or [Not Known] — deriving the lapsed condition from the stored record and the injected [Now]. It writes nothing under any path, including when the [Session] has lapsed.

Kind: Operation

#### Revoke

The behavior a composing pattern invokes to explicitly cancel a [Session], with attribution. It is permitted only on a stored-[Active] record; it transitions [Status] to [Revoked] and records [Revoked At], [Revoked By Ref], and [Revocation Reason]. A [Session] that has merely lapsed is still stored-[Active] and so may still be revoked; only a prior [Revoked] blocks it.

Kind: Operation

#### Read

The render-time behavior that returns the matching [Session] records, each carrying its derived [Effective Status]. It only reads; no record changes. It is the surface every liveness query applies, since a raw [Active] with [Expires At] in the past is a lapsed [Session], not a live one.

Kind: Operation

#### Session Token

The opaque, cryptographically random, immutable, system-generated value [Issue] produces — both the [Session]'s record identity and the bearer credential the caller presents to [Validate] and [Revoke]. It is the injected `id_t`; no two sessions share one, and it is not reused after a [Session] lapses or is revoked.

Kind:     Field
Field of: Session
Projects: session_token

#### Principal Ref

The opaque reference to the authenticated principal for whom the [Session] is issued. The atom treats it as opaque — it does not validate that the principal exists or was authenticated. Set on [Issue], immutable thereafter; the value [Validate] returns in a [Valid] result.

Kind:     Field
Field of: Session
Projects: principal_ref

#### Issued By Ref

The opaque reference to the mechanism that issued the [Session] (a Login service, an SSO system, an administrative process). Recorded as an immutable property of the [Session]. Set on [Issue], immutable thereafter.

Kind:     Field
Field of: Session
Projects: issued_by_ref

#### Issued At

The wall-time when [Issue] was called, stamped from the injected [Now]. Immutable thereafter. [Expires At] is computed once as `[Issued At] + [Session Duration]`.

Kind:     Field
Field of: Session
Projects: issued_at

#### Expires At

The time at which this [Session] expires — set on [Issue] as `[Issued At] + [Session Duration]`, never null, and never mutated by any action. It states *when* validity ends; whether the [Session] has lapsed is *derived* from it against the injected [Now], never recorded as a stored status change. It is the sole stored input the expiry derivation needs.

Kind:     Field
Field of: Session
Projects: expires_at

#### Status

The stored status of a [Session]: [Active] or [Revoked]. Set to [Active] on [Issue]; transitions to [Revoked] via [Revoke] and never returns to [Active]. The derived [Expired] is *not* a value of this field — it appears only in the [Effective Status] read projection.

Kind:     Field
Field of: Session
Projects: status

#### Revoked At

The wall-time the [Session]'s [Status] transitioned to [Revoked], stamped from the injected [Now]. Null until revocation; immutable once set.

Kind:     Field
Field of: Session
Projects: revoked_at

#### Revoked By Ref

The opaque reference to the actor or mechanism that performed the revocation. Required at [Revoke]; null until revocation; immutable once set.

Kind:     Field
Field of: Session
Projects: revoked_by_ref

#### Revocation Reason

The caller-supplied reason recorded for the revocation (from the [Reason] parameter). Required at [Revoke]; null until revocation; immutable once set.

Kind:     Field
Field of: Session
Projects: revocation_reason

#### Effective Status

The status [Read] attaches to each returned [Session] record: [Expired] when `[Status] = [Active] ∧ [Now] ≥ [Expires At]`, otherwise the stored [Status]. It is a pure projection over the record and the injected [Now] — **derived at read time, never stored** — and is what makes [Validate] return [Invalid Expired]. Every liveness query applies it.

Kind:     Field
Field of: Session
Projects: effective_status

#### Session Duration

The duration value [Issue] consumes to compute [Expires At] (`[Issued At] + [Session Duration]`). Supplied per call; if null, the deployment's default applies; zero or negative is rejected. It is never stored under its own name — only the computed [Expires At] is stored.

Kind:         Parameter
Parameter of: Issue
Projects:     session_duration

#### Now

The current clock reading (the pipeline's `clock_t`), pipeline-injected at the I/O seam on every action — not caller-trusted, not read inside any transition, not shown as a signature parameter. It is consumed only to stamp immutable write timestamps ([Issued At], [Revoked At]) and to evaluate the pure expiry derivation in [Validate] and [Read] (no write).

Kind:         Parameter
Parameter of: Validate
Projects:     now

#### Reason

The caller-supplied reason string [Revoke] consumes and writes into the [Session]'s [Revocation Reason]. Required non-null and non-empty. It is not stored under its own name — only [Revocation Reason] is stored.

Kind:         Parameter
Parameter of: Revoke
Projects:     reason

#### Filter

The selection a caller passes to [Read] to scope which [Session] records are returned. Consumed per call; never stored.

Kind:         Parameter
Parameter of: Read
Projects:     filter

#### Active

The only non-terminal stored state: the [Session] has been issued and may be validated. [Validate] derives expiry from the injected [Now] against the immutable [Expires At] and returns [Valid] or [Invalid Expired]. A still-[Active] record past its [Expires At] reads [Expired] by derivation but is *not* a stored terminal.

Kind:      Member
Member of: the stored status
Role:      Outcome

#### Revoked

The only stored terminal state: the [Session] was explicitly revoked. It can no longer be validated as [Valid], and admits no further transitions; a re-[Revoke] returns [Already Terminal]. Revocation takes precedence over expiry in [Validate]'s outcome vocabulary.

Kind:      Member
Member of: the stored status
Role:      Outcome

#### Expired

The derived status a lapsed [Session] reads as — **never stored**. It is the value of [Effective Status] when `[Status] = [Active] ∧ [Now] ≥ [Expires At]`, computed at read time from the immutable [Expires At] and the injected clock. No transition fires and no field is written when a [Session] lapses.

Kind:      Member
Member of: the derived effective status
Role:      Outcome

#### Valid

The [Validate] outcome when the [Session Token] references a known record that is stored-[Active] and `[Now] < [Expires At]`. It carries the [Principal Ref] and [Expires At]. It is the one outcome the conjunctive validity bound (Invariant 3) admits; any single condition failing yields an invalid result instead.

Kind:      Member
Member of: the validate outcome
Role:      Outcome
Projects:  valid

#### Invalid Expired

The [Validate] outcome when the record is stored-[Active] and `[Now] ≥ [Expires At]` — reached **by derivation, with no write**. Structurally distinct from [Invalid Revoked]; the [Active] guard is checked first so a revoked-and-past-deadline [Session] returns [Invalid Revoked], never this.

Kind:      Member
Member of: the validate outcome
Role:      Outcome
Projects:  expired

#### Invalid Revoked

The [Validate] outcome when the record's stored [Status] is [Revoked] — regardless of whether [Expires At] is still in the future. Revocation takes precedence over expiry, so this is returned even when the [Session] would also have lapsed. Permanent for a given token (Invariant 4).

Kind:      Member
Member of: the validate outcome
Role:      Outcome
Projects:  revoked

#### Not Known

The lookup-miss outcome: the supplied [Session Token] references no record. [Validate] returns it as the structurally-distinct fourth outcome (no [Session] was revoked; no [Session] exists), and [Revoke] returns it as a rejection when its target token is unknown.

Kind:      Member
Member of: the lookup-miss outcome
Role:      Outcome
Projects:  not-known

#### Invalid Request

The rejection [Issue] returns when [Principal Ref] or [Issued By Ref] is null or empty, when [Session Duration] is zero or negative, or when the deployment default duration is absent; and [Revoke] returns when [Revoked By Ref] or [Reason] is null or empty.

Kind:      Member
Member of: the action rejection
Role:      Outcome
Projects:  invalid-request

#### Already Terminal

The rejection [Revoke] returns when the target [Session]'s stored [Status] is already [Revoked] — a re-revoke. The only stored terminal is [Revoked]; a merely-lapsed [Session] is not terminal and is not rejected here.

Kind:      Member
Member of: the revoke rejection
Role:      Outcome
Projects:  already-terminal

#### Storage Failure

The rejection [Issue] or [Revoke] returns when the underlying store write fails. [Issue] leaves no partial record; [Revoke] commits no state change. The caller must treat it as definitive.

Kind:      Member
Member of: the action rejection
Role:      Outcome
Projects:  storage-failure

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a [Term] marker to its card heading above (kramdown
     auto-generates the heading anchors on GitHub Pages). Standard CommonMark /
     kramdown; no plugin required. -->

[Session]: #session
[Issue]: #issue
[Validate]: #validate
[Revoke]: #revoke
[Read]: #read
[Session Token]: #session-token
[Principal Ref]: #principal-ref
[Issued By Ref]: #issued-by-ref
[Issued At]: #issued-at
[Expires At]: #expires-at
[Status]: #status
[Revoked At]: #revoked-at
[Revoked By Ref]: #revoked-by-ref
[Revocation Reason]: #revocation-reason
[Effective Status]: #effective-status
[Session Duration]: #session-duration
[Now]: #now
[Reason]: #reason
[Filter]: #filter
[Active]: #active
[Revoked]: #revoked
[Expired]: #expired
[Valid]: #valid
[Invalid Expired]: #invalid-expired
[Invalid Revoked]: #invalid-revoked
[Not Known]: #not-known
[Invalid Request]: #invalid-request
[Already Terminal]: #already-terminal
[Storage Failure]: #storage-failure

## Standards references

- **NIST (National Institute of Standards and Technology — US federal standards body) SP 800-63B §7 (Session Management)** — the primary standard for session management in authentication systems. Requirements for session binding, session duration, reauthentication triggers, and session termination correspond directly to this atom's behavioral commitments. The atom's [Expires At] immutability and re-issuance discipline implement 800-63B's requirement that session extensions produce new session identifiers.
- **OWASP ASVS V3 (Application Security Verification Standard — Session Management)** — the OWASP (Open Worldwide Application Security Project) verification standard for session management security. Requirements for session token randomness, expiry, revocation on logout, and protection against fixation attacks are the deployment-configuration surface of this atom.
- **RFC 6265 (HTTP State Management Mechanism)** — the cookie standard. The atom's [Session Token] is the value delivered in a `Set-Cookie` response header in browser-based deployments. The atom does not specify cookie attributes (Secure, HttpOnly, SameSite) — those are the composing pattern's configuration obligations.
- **SAML 2.0 §4.1.4 (Session Establishment and Termination)** — the SAML (Security Assertion Markup Language — an XML standard for exchanging authentication data between identity and service providers) session model maps to this atom: `AuthnStatement` issuance corresponds to [Issue]; `SessionNotOnOrAfter` corresponds to [Expires At]; `SLO` (Single Logout) corresponds to [Revoke]. The atom's re-issuance discipline aligns with SAML's prohibition on reusing assertion IDs.
- **RFC 6819 (OAuth 2.0 Threat Model and Security Considerations)** — identifies session-related threats (token theft, session fixation, CSRF — Cross-Site Request Forgery) that the deployment-configuration layer of this atom addresses. The atom's immutability and revocation invariants mitigate token theft's blast radius: a stolen token is bounded by [Expires At] and can be revoked.
- **OIDC Session Management 1.0 (OpenID Connect Session Management)** — the OpenID Connect (OIDC — an identity layer built on OAuth 2.0) session management specification. The atom's [Session Token] corresponds to an OIDC session's identifier; [Revoke] corresponds to OIDC's Front-Channel and Back-Channel Logout protocols, and natural lapse (the derived [Expired]) corresponds to a session reaching its `SessionNotOnOrAfter` bound without an explicit logout.
- **HIPAA §164.312(a)(2)(iii) (Automatic Logoff)** — the HIPAA automatic logoff requirement: electronic information systems must terminate after a period of inactivity. The atom's [Expires At] field is the structural mechanism for this requirement; the composing deployment configures the timeout.
- **PCI DSS (Payment Card Industry Data Security Standard — the card networks' mandatory security rules for cardholder data) Requirement 8.6 (Session Management)** — session timeout and re-authentication requirements for payment systems. The atom's [Expires At] immutability and re-issuance discipline satisfy the structural portion of these requirements.

Inherited from:

- **Daniel Jackson, *The Essence of Software*** — the freestanding-atom posture; the discipline of keeping credential verification, session persistence, permission checking, and logout propagation as separate composable atoms rather than absorbing them here.
- **IETF (Internet Engineering Task Force) RFC 4120 (Kerberos)** — Kerberos tickets are the canonical precedent for time-bounded, revocable authentication session records. The atom's immutable [Expires At], single-stored-terminal ([Revoked]) state machine with a derived-[Expired] read projection, and revocation attribution discipline are the structured-natural-language expression of Kerberos' core concepts — a Kerberos ticket's lifetime likewise lapses by the clock against its end-time without a status write, while explicit invalidation is the recorded act.


## Status

`grounded on Final Critique 5 — 2026-06-23` — see the Ledger.

## Ledger

```
status: grounded on Final Critique 5 — 2026-06-23
formal: not applicable — vote no 2026-06-03
last gate: 2026-06-23 — Final Critique 5, fresh reader — clean

open: none
```

## Decisions

Directional changes only — the turns a future reader must know the pattern took, and why. Everything smaller lives in the commit that made it: `git log -- atoms/session.md`.

- **2026-09-12 — Rewritten in GRACE lang v0.35; nothing but language changed.** *Chose:* labelled rules in fenced blocks, the four actions as a signature block, the twelve invariant numbers and the six acceptance checks unchanged, the derived lapse routed through a declared `lapsed` and `effective_status` so no rule carries the comparison, the arithmetic in `issued_at + session_duration` moved into a declared `expiry deadline` (Hard invariant 24), [Validate]'s four-row precedence table kept beside the rules as the case space, Generation acceptance moved ahead of Non-goals to match the migrated corpus, the string-input paragraph raised to a `String 1–8` family matching Permissions and Notification, Non-goals and Edge cases split into two sections. *Over:* the prose spec. *Because:* the migration plan; nothing in the corpus cites this atom by label, so the rewrite is free of frozen-number risk. Expiry earned its own family — eight rules that say a lapse writes nothing, fires nothing, stamps nothing and is scheduled by nobody — because the whole commitment was carried by prose emphasis in four places and is now a surface a checker can read.

- **2026-06-21 — Expiry is derived at read time, never stored.** *Chose:* the stored state space is `{Active, Revoked}`; `Expired` is the projection `status = Active ∧ now ≥ expires_at` computed from the immutable `expires_at` and the injected clock (Invariant 12). *Over:* a stored `Expired` terminal written by a lazy or scheduled transition. *Because:* a stored flag lags the clock it idealizes, and a session's lapse has no side effect that would need a write to carry it.

NOTE: End of Session.
