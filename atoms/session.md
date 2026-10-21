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

A session is stored [Active] until it is deliberately cancelled — [Revoked], with who, when and why recorded, and that is permanent. It can also simply run out. When its window passes the session is *shown* expired, a status worked out on the fly by comparing the clock to the deadline, never written into the record and never a stored state. The deadline is fixed at issue and never changed; a session that needs to last longer is re-issued as a new record rather than extended in place. That keeps every session's validity window provable from the session's one record.

This is the mechanism behind browser sessions, API (Application Programming Interface) access tokens, mobile logins and short-lived elevated-access windows. It deliberately does not check credentials, decide what the principal may do, or run the login flow — each is a separate pattern.

*Also known as: a login session, an authenticated session, an access token, a session ticket.*

---

## Intent

WHY:
A system that authenticates once and then permits action across many requests needs to answer *is this principal still authenticated?* without repeating the credential check every time. A session is that answer made durable: a bounded-lifetime record attesting that a principal completed authentication at a known moment and that the result has not been invalidated since.

The atom isolates that attestation from everything around it. It does not verify credentials — that is [Credential](./credential.md)'s surface. It does not decide what the principal may do — that is [Permissions](./permissions.md)'. It does not sequence the login flow, the multi-factor challenge and the issuance — that is [Login](../compositions/login.md)'s. It answers one structural question: given this token, is there an active, unexpired, unrevoked session for a known principal? And the answer is one of four outcomes, each provable.

The time bound is the atom's core commitment, and the discipline around it is where most session designs go wrong. expiry instant is set at issue and never mutated. A session needing a longer life is re-issued — a new record, a new token — never extended in place. That immutability is what makes every session's window auditable from one record: no history table, no event log, no developer's account of whether the session was extended. The record says when validity ends, and that field never changes.

The second commitment is that lapsing is *derived*, not written. There is no `expire` action, no `expired_at` column, and no stored [Expired] status. A session past its deadline is computed as lapse instant read time from the immutable deadline against the injected clock. Nothing fires, nothing is stamped, no scheduler is needed — and the stored state space stays exactly two values, which removes the failure mode where a flag lags the clock it is meant to idealize.

## Structure

### Identity model

```
Identity 1: The atom MUST identify a session by the session token.
Identity 2: The session token MUST serve as the bearer credential [Validate] accepts.
Identity 3: The host MUST allocate a session token at the seam.
Identity 4: The transition MUST NOT allocate a session token.
Identity 5: The atom MUST NOT reuse a session token.
Identity 6: The atom MUST NOT change a session token.
Identity 7: The atom MUST NOT carry a session identifier beside the session token.
Identity 8: Two sessions MUST NOT share a session token.
Identity 9: The deployment MUST draw a session token from a cryptographically secure random source.
Identity 10: The deployment MUST NOT draw a session token from the session's public properties.
Identity 11: The atom MUST NOT interpret a principal reference.
Identity 12: The atom MUST NOT confirm that a principal reference names an authenticated principal.
```

Term session: one bounded-lifetime attestation that a principal completed authentication — a [Session], the record this atom holds.

Term session token: the opaque value naming one session — a [Session Token]; unguessable, host-allocated at the seam, and the capability [Validate] and [Revoke] accept.

Term principal reference: the opaque reference naming the authenticated principal — a [Principal Reference].

Term issued by reference: the opaque reference naming the mechanism that issued the session — an [Issued By Reference].

Term seam: the atom's I/O boundary as the section titled Logic Confinement Principle in `execution-contract.md` declares it; the host injects the clock reading, the session token and the token's random material here.

Term transition: the atom's evaluation of one call against the session records, as the section titled Logic Confinement Principle in `execution-contract.md` declares it.

### State

```
State 1: EVERY session MUST stand in EXACTLY ONE OF active, revoked.
State 2: EVERY session MUST carry session token, principal reference, issued by reference, issuance instant, expiry instant and status.
State 3: EVERY session MUST carry an expiry instant.
State 4: A revoked session MUST carry revocation instant, revoked by reference and revocation reason.
State 5: An active session MUST NOT carry revocation instant.
State 6: An active session MUST NOT carry revoked by reference.
State 7: An active session MUST NOT carry revocation reason.
State 8: A session MUST NOT carry a stored expired status.
State 9: A session MUST NOT carry an expiry timestamp beside expiry instant.
State 10: The atom MUST NOT offer a transition out of revoked.
State 11: The atom MUST NOT remove a session from the database.
State 12: The atom MUST NOT hold a permission.
State 13: The atom MUST NOT hold a device context.
State 14: The atom MUST NOT hold a concurrency bound per principal reference.
```

Term status: active | revoked — the stored status; in force, or cancelled and terminal. expired is not a value of it.

#### Expiry

```
Expiry 1: A lapse MUST NOT write to the session.
Expiry 2: A lapse MUST NOT fire a transition.
Expiry 3: The atom MUST NOT stamp an expiry.
Expiry 4: The deployment MUST NOT schedule a lapse.
Expiry 5: The atom MUST derive a lapse from expiry instant against now.
Expiry 6: A lapsed session MUST NOT stand in a stored terminal.
Expiry 7: [Read] MUST surface a lapse as the effective status.
Expiry 8: [Validate] MUST surface a lapse as expired.
```

### Capability requirement

```
Capability requirement 1: The deployment MUST supply now at the seam.
Capability requirement 2: The deployment MUST configure a default session duration.
Capability requirement 3: The deployment MUST supply the session token's random material at the seam.
Capability requirement 4: The session token's random material MUST NOT fall below the token entropy.
Capability requirement 5: The deployment MUST own the session token's format.
Capability requirement 6: The deployment MUST own whether the database holds a session token raw.
Capability requirement 10: The deployment MUST supply the session records PER Execution Contract Database 1 through 4.
Capability requirement 11: The deployment MAY configure a default session duration ONLY IF the default session duration EXCEEDS the zero duration.
Deleted: Capability requirement 7. Execution Contract Logic confinement 7 owns it.
Deleted: Capability requirement 8. Execution Contract Logic confinement 7 owns it.
Deleted: Capability requirement 9. Execution Contract Logic confinement 7 owns it.
Deleted: Configuration 1. Capability requirement 2 owns it.
Deleted: Configuration 2. Operation 48 owns it.
Deleted: Configuration 3. Capability requirement 3 owns it.
Deleted: Configuration 4. Operation 49 owns it.
Deleted: Configuration 5. Capability requirement 4 owns it.
Deleted: Configuration 6. Capability requirement 5 owns it.
Deleted: Configuration 7. Capability requirement 6 owns it.
Deleted: Clock semantics 1. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 2. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 3. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 4. Clock dependence 1 owns it.
Deleted: Clock semantics 5. Clock dependence 2 owns it.
Deleted: Clock semantics 6. Non-goal 25 owns it.
Deleted: Clock semantics 7. Non-goal 26 owns it.
```

Term default session duration: the window [Issue] applies where the call supplies no session duration; deployment configuration, and its absence is a misconfiguration rather than an operating state.

Term token entropy: 128 bits of cryptographically secure random material — the floor a session token is drawn from, sufficient for negligible collision probability and for unguessability.

### Operations

```
issue(principal_ref, issued_by_ref, session_duration)
  answers session_token
  refuses invalid-request | storage-failure

validate(session_token)
  answers valid(principal_ref, expires_at) | invalid(validation failure)

revoke(session_token, revoked_by_ref, reason)
  answers revoked
  refuses invalid-request | already-terminal | not-known | storage-failure

read(filter)
  answers session_records
```

Term validation failure: expired | revoked | not-known — the reasons [Validate] gives for an invalid session.

```
Operation 1: [Issue] MUST record EXACTLY ONE session per successful call.
Operation 2: [Issue] MUST stand the session in active.
Operation 3: [Issue] MUST answer the session token.
Operation 4: IF principal reference EQUALS blank THEN [Issue] MUST answer invalid-request.
Operation 5: IF issued by reference EQUALS blank THEN [Issue] MUST answer invalid-request.
Operation 6: IF session duration EQUALS blank AND the default session duration DOES NOT EQUAL blank THEN [Issue] MUST apply the default session duration.
Operation 7: [Issue] MUST accept a session duration ONLY IF the session duration EXCEEDS the zero duration.
Operation 8: IF session duration DOES NOT EQUAL blank AND the session duration DOES NOT EXCEED the zero duration THEN [Issue] MUST answer invalid-request.
Operation 9: [Issue] MUST stamp issuance instant from the injected now.
Operation 10: [Issue] MUST stamp expiry instant from the expiry deadline.
Operation 11: [Issue] MUST NOT recompute expiry instant from a later clock reading.
Operation 12: IF the database refuses the write THEN [Issue] MUST answer storage-failure.
Operation 13: [Validate] MUST answer EXACTLY ONE OF valid, expired, revoked, not-known.
Operation 14: IF the session token names no session THEN [Validate] MUST answer not-known.
Operation 15: IF the session's status EQUALS revoked THEN [Validate] MUST answer revoked.
Operation 16: IF the session is lapsed THEN [Validate] MUST answer expired.
Operation 17: [Validate] MUST answer expired ONLY IF the session's status EQUALS active.
Operation 18: [Validate] MUST answer valid ONLY IF the session's status EQUALS active AND the session is not lapsed.
Operation 19: [Validate] MUST carry principal reference and expiry instant in a valid answer.
Operation 20: [Validate] MUST NOT write.
Operation 21: [Validate] MUST NOT refuse a call.
Operation 22: IF the session token names no session THEN [Revoke] MUST answer not-known.
Operation 23: IF the session's status EQUALS revoked THEN [Revoke] MUST answer already-terminal.
Operation 24: [Revoke] MUST answer already-terminal ONLY IF the session's status EQUALS revoked.
Operation 25: IF the session's status EQUALS active AND revoked by reference EQUALS blank THEN [Revoke] MUST answer invalid-request.
Operation 26: IF the session's status EQUALS active AND reason EQUALS blank THEN [Revoke] MUST answer invalid-request.
Operation 27: [Revoke] MUST accept a lapsed session.
Operation 28: [Revoke] MUST stand the session in revoked.
Operation 29: [Revoke] MUST stamp revocation instant from the injected now.
Operation 30: [Revoke] MUST record revoked by reference on the session.
Operation 31: [Revoke] MUST record the reason as the revocation reason.
Deleted: Operation 32. Execution Contract Database 1 owns it.
Operation 33: [Revoke] MUST answer revoked.
Operation 34: IF the database refuses the write THEN [Revoke] MUST answer storage-failure.
Deleted: Operation 35. Execution Contract Database 3 owns it.
Operation 36: [Revoke] MUST accept the session token as the whole authorization.
Operation 37: [Read] MUST answer EVERY session the filter matches.
Operation 38: [Read] MUST carry the effective status on EVERY answered session.
Operation 39: [Read] MUST NOT write.
Operation 40: A liveness query MUST rest on the effective status.
Operation 41: A liveness query MUST NOT rest on the stored status alone.
Deleted: Operation 42. Capability requirement 1 owns it.
Deleted: Operation 43. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 44. Execution Contract Logic confinement 3 owns it.
Operation 45: The atom MUST NOT offer an expire action.
Operation 46: The atom MUST NOT offer an extend action.
Operation 47: The atom MUST NOT offer an un-revoke action.
Operation 48: IF the default session duration EQUALS blank THEN [Issue] MUST answer invalid-request.
Operation 49: The transition MUST NOT generate the session token's random material.
```

Term now: the wall-time reading the host takes at the seam and hands to the transition — a [Now], as the section titled Logic Confinement Principle in `execution-contract.md` declares it; never read inside the transition, never supplied by the business caller.

Term business caller: the party whose action the call carries, as the section titled Logic Confinement Principle in `execution-contract.md` declares it; never the source of an injected value.

Term session duration: the window a [Issue] call asks for — a [Session Duration]; consumed to compute the expiry deadline, never stored under this name.

Term zero duration: a duration of no length — the floor a session duration must exceed, which refuses zero and every negative value.

Term issuance instant: the instant the session was recorded — an [Issuance Instant].

Term expiry deadline: `issued_at + session_duration` — what [Issue] stores as expiry instant, computed once at issue.

Term expiry instant: the instant the session's validity ends — an [Expiry Instant]; stamped at issue, never changed, never absent.

Term lapsed: the session's status EQUALS active and now is no earlier than the session's expiry instant — the condition [Validate] derives and never stamps.

Term effective status: expired where the session is lapsed, and the stored status otherwise — an [Effective Status]; a pure projection over the session and now, never stored.

Term revocation instant: the instant the session was cancelled — a [Revocation Instant].

Term revoked by reference: the opaque reference naming the actor that cancelled the session — a [Revoked By Reference].

Term revocation reason: the stated ground for the cancellation — a [Revocation Reason], carried from the call's [Reason].

Term reason: the [Revoke] input the session keeps as revocation reason — a [Reason].

Term filter: the selection a [Read] call scopes the answer by — a [Filter]; consumed per call, never stored.

Term liveness query: any query for the sessions in force at the read-time clock — the atom's [Read] and the administrative surfaces built on it.

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the database |
|---|---|---|---|
| [Issue] | both references present, duration positive or defaulted, database accepts | the new session token | one record lands in [Active], issuance instant and expiry instant stamped (Operation 1, Operation 9, Operation 10) |
| [Issue] | a blank or over-long reference, a non-positive duration, or no configured default | [Invalid Request] | none (Operation 4, Operation 5, Operation 8, Operation 48, String 7) |
| [Validate] | token names nothing | [Not Known] | none — the call reads (Operation 14, Operation 20) |
| [Validate] | stored status is [Revoked] | [Invalid Revoked] | none — returned even where the window is still open (Operation 15) |
| [Validate] | stored [Active], now has reached expiry instant | [Invalid Expired] | none — derived, nothing written (Operation 16, Operation 17) |
| [Validate] | stored [Active], now short of expiry instant | [Valid], carrying [Principal Reference] and [Expiry Instant] | none (Operation 18, Operation 19) |
| [Revoke] | token names a session in [Active], attribution present | revoked | [Active] → [Revoked], three fields stamped (Operation 28 through 31) |
| [Revoke] | token names a session in [Active] past its deadline | revoked | as above — a lapse is not a stored terminal (Operation 27) |
| [Revoke] | token names nothing | [Not Known] | none (Operation 22) |
| [Revoke] | stored status is already [Revoked] | [Already Terminal] | none (Operation 23, Operation 24) |
| [Revoke] | session in [Active], blank or over-long attribution | [Invalid Request] | none (Operation 25, Operation 26, String 9, String 10) |
| either write | database refuses | [Storage Failure] | none (Operation 12, Operation 34) |
| *a window lapses* | now reaches expiry instant | nothing is called | **nothing written** — no action, no stamp, no scheduler (Expiry 1 through 5) |
| [Read] | a filter | the matching sessions, each carrying its effective status | none (Operation 37, Operation 38) |

### Invariants

- **Invariant 1 — Issue immutability.**
  ```
  Invariant 1.1: A recorded session's session token, principal reference, issued by reference, issuance instant and expiry instant MUST NOT change.
  Invariant 1.2: A session's status and revocation fields MUST stand as the only fields a later action writes.
  ```
- **Invariant 2 — Expiry timestamp immutability.**
  ```
  Invariant 2.1: No action MUST change a recorded expiry instant.
  Invariant 2.2: A deployment extending a session MUST call [Issue].
  ```
- **Invariant 3 — Validity bound conjunctive, by derivation.**
  ```
  Invariant 3.1: [Validate] MUST answer valid ONLY IF the session token names a session AND the session's status EQUALS active AND the session is not lapsed.
  Invariant 3.2: [Validate] MUST derive the lapse from expiry instant against now.
  Invariant 3.3: [Validate] MUST NOT answer expired for a revoked session.
  ```
- **Invariant 4 — Revocation absorbing.**
  ```
  Invariant 4.1: [Validate] MUST NOT answer valid for a revoked session.
  ```
- **Invariant 5 — Stored terminal absorbing.**
  ```
  Invariant 5.1: A revoked session MUST NOT leave revoked.
  Invariant 5.2: [Revoke] MUST answer already-terminal against a revoked session.
  Invariant 5.3: A lapsed session MUST reach [Revoke].
  ```
- **Invariant 6 — Four structurally distinct validate outcomes.**
  ```
  Invariant 6.1: [Validate] MUST answer EXACTLY ONE OF valid, expired, revoked, not-known.
  Invariant 6.2: An implementation MUST NOT merge two validate answers.
  ```
- **Invariant 7 — Session token uniqueness.**
  ```
  Invariant 7.1: Two sessions MUST NOT share a session token.
  Invariant 7.2: [Issue] MUST NOT allocate a session token any session carries.
  ```
- **Invariant 8 — Revocation attribution completeness.**
  ```
  Invariant 8.1: EVERY revoked session MUST carry a revocation instant.
  Invariant 8.2: EVERY revoked session's revoked by reference MUST stand non-blank.
  Invariant 8.3: EVERY revoked session's revocation reason MUST stand non-blank.
  ```
- **Invariant 9 — Session durability over this atom's own surface.**
  ```
  Invariant 9.1: The atom MUST NOT offer a removal surface.
  Invariant 9.2: An action the atom offers MUST NOT reduce the session count.
  Deleted: Invariant 9.3. Execution Contract Database 1 owns it.
  ```
- **Invariant 10 — Every session has a finite lifetime.**
  ```
  Invariant 10.1: EVERY session MUST carry an expiry instant.
  Invariant 10.2: The atom MUST NOT record a session carrying no expiry instant.
  ```
- **Invariant 11 — Expiry absorbing, by derivation.**
  ```
  Invariant 11.1: [Validate] MUST NOT answer valid for a lapsed session.
  Invariant 11.2: A lapsed session MUST stand lapsed at EVERY later now.
  ```
- **Invariant 12 — Expiry is derived, never written.**
  ```
  Invariant 12.1: A session MUST NOT carry a stored expired status.
  Invariant 12.2: A session MUST NOT carry an expiry timestamp beside expiry instant.
  Invariant 12.3: A lapse MUST NOT write to the session.
  Invariant 12.4: The effective status MUST rest on the stored status, expiry instant and now.
  ```

Invariants 1, 2 and 10 together give the *temporal auditability* property — every session's window is fully determined from one record, with no mutable validity field. Invariants 3, 6 and 12 give *validation clarity* — the outcome of any [Validate] call is unambiguous, distinguishable, and computed from the record and the injected clock alone. Invariants 4 and 11 give *terminal finality* — neither a revoked session nor a lapsed one resurfaces as valid by any path.

---

## Examples

### Browser login — issue and validate

A user logs in through the [Login](../compositions/login.md) composition. After the credential check, Login calls `issue(principal_ref: user_u91, issued_by_ref: login_svc_l01, session_duration: 3600)` → `tok_abc123`, with the host injecting `now: 2026-09-01T10:00:00Z` at the seam. The record lands in [Active] with `issued_at: 10:00:00Z` and `expires_at: 11:00:00Z`. The token goes to the browser as a session cookie.

Twenty minutes later the user requests a protected page. `validate(tok_abc123)` → `valid(principal_ref: user_u91, expires_at: 11:00:00Z)`, with `now: 10:20:00Z` injected. The atom finds the record, reads stored active, finds now short of the deadline, and answers. Nothing changes.

### Logout — revoke

The user clicks log out. `revoke(tok_abc123, revoked_by_ref: user_u91, reason: "user-initiated-logout")` → revoked, with `now: 10:45:00Z` injected. The record moves to [Revoked] with all three fields stamped. expiry instant stays `11:00:00Z` — that field is immutable.

If the browser re-presents the old cookie at `10:50:00Z`: `validate(tok_abc123)` → `invalid(revoked)`. The stored status is read first, so the answer is [Invalid Revoked] and not [Invalid Expired], even though the session would have lapsed naturally fifteen minutes later (Operation 15).

### A window lapses — derived

The user closes the browser without logging out. The window passes at `11:00:00Z`. **No call is made and no write occurs** — there is no action to call. At `11:30:00Z` a new tab presents the same cookie: `validate(tok_abc123)` → `invalid(expired)`. The record is still stored active, never transitioned; the answer comes from expiry instant against the injected now. Nothing is written, there is no expiry timestamp to write, and the record count is unchanged. A [Read] of the record now reports `effective_status: expired` (Expiry 1 through 8).

### Rejection paths

`issue(principal_ref: svc_s03, issued_by_ref: api_gateway_g01, session_duration: 0)` → invalid-request. A zero-length window is not an operating state (Operation 8).

`revoke(tok_abc123, revoked_by_ref: admin_a01, reason: "incident-response")` against an already-revoked session → already-terminal. The existing [Revocation Reason] is unchanged (Operation 23). A session that has merely *lapsed* is not a stored terminal, so the same call against a lapsed-but-unrevoked session succeeds and records the attribution (Operation 27).

`validate(tok_forged_xyz)` → `invalid(not-known)`. No record for the token — structurally distinct from [Invalid Revoked], because nothing was revoked and nothing exists (Operation 14, Invariant 6.1).

### Regulated adversarial scenarios

- **Regulator audit.** A HIPAA (Health Insurance Portability and Accountability Act) auditor asks whether access to a patient record at `14:32Z` on `2026-10-15` was under a valid, unrevoked session. The database yields `tok_abc123`: stored active, `issued_at: 14:00:00Z`, `expires_at: 15:00:00Z`, no revocation instant. Invariant 3.1 is the structural answer — at `14:32Z` the session was stored active and the deadline had not passed, so [Validate] would have answered [Valid]. The auditor confirms it provably, from the one record; there is no stored expiry flag to corroborate, only the immutable deadline (Check 3.1).
- **Disputed access.** A user denies access at `03:15` on `2026-11-20`. The investigator reconstructs the sessions in force for the principal at that instant from the records and finds `tok_abc123`: `issued_at: 2026-11-19T22:00:00Z`, `expires_at: 2026-11-20T06:00:00Z`, `issued_by_ref: login_svc_l01`. The session was in force. Whether the token was stolen is a separate investigation; what the records bound is the forensic window — issued through the Login service at 22:00, valid at 03:15, never revoked before the access. Who authenticated at 22:00 and against what credential is [Actor Identity](./actor-identity.md)'s record, wired by Login (Non-goal 1, Composition note 3).
- **Breach investigation.** Session tokens are found in an exposed log file. The investigator queries every session with `issued_by_ref: api_gateway_g01` inside the exposure window — 47 sessions across 31 principals — and reads each effective status against the investigation clock: which are live, which lapsed, which were already revoked. The team then calls [Revoke] on every session not already revoked, *including the lapsed ones*, so that every closure is attributed (Operation 27). Invariant 8.1 through 8.3 is what makes it provable, six months later, which sessions were closed, by whom, when and why.

---

## Generation acceptance

This atom's acceptance is provable: an external auditor clears it from the session records and the read-time clock the [Validate] and [Read] surfaces use.

### Conformance checks

```
Check 1.1: An auditor MUST find an expiry instant on EVERY session (Invariant 10.1).
Check 1.2: An auditor MUST find one expiry instant per session across the session's whole life (Invariant 2.1).
Check 2.1: An auditor MUST find no stored expired status on any session (Invariant 12.1).
Check 2.2: An auditor MUST find no expiry timestamp beside expiry instant (Invariant 12.2).
Check 2.3: An auditor MUST find no field written by a lapse (Invariant 12.3).
Check 2.4: An auditor MUST reproduce the effective status from the stored status, expiry instant and the read-time clock (Invariant 12.4).
Check 3.1: An auditor MUST reconstruct the sessions in force at a past instant from issuance instant, expiry instant and revocation instant (Invariant 3.1, Invariant 3.2).
Check 4.1: An auditor MUST find a revocation instant, a revoked by reference and a revocation reason on EVERY revoked session (Invariant 8.1, Invariant 8.2, Invariant 8.3).
Check 5.1: An auditor MUST find the four validate answers distinguishable on the implementation's contract (Invariant 6.1, Invariant 6.2).
Check 6.1: An auditor MUST find no revoked session whose status EQUALS active (Invariant 5.1).
```

NOTE: EVERY check names the rule the check tests.

## Non-goals

```
Non-goal 1: The atom MUST NOT verify an authentication credential.
Non-goal 2: A deployment needing an authentication credential verified MUST compose Credential.
Non-goal 3: The atom MUST NOT sequence a multi-factor challenge.
Non-goal 4: A deployment needing a login flow MUST compose Login.
Non-goal 5: The atom MUST NOT decide what a principal reference may do.
Non-goal 6: A deployment needing an authorization decision MUST compose Permissions.
Non-goal 7: The atom MUST NOT extend a session in place.
Non-goal 8: A deployment needing a sliding window MUST call [Issue] again.
Non-goal 9: A composing pattern renewing a session MUST revoke the prior session.
Non-goal 10: The atom MUST NOT bind a session token to a device.
Non-goal 11: A deployment needing device binding MUST check the device context outside the atom.
Non-goal 12: The atom MUST NOT bound how many sessions one principal reference holds.
Non-goal 13: A deployment needing a concurrency bound MUST enforce the bound at the composing layer.
Non-goal 14: The atom MUST NOT propagate a revocation across a principal reference's other sessions.
Non-goal 15: A deployment needing logout propagation MUST revoke the principal reference's sessions one by one.
Non-goal 16: The atom MUST NOT define the session token's format.
Non-goal 17: The atom MUST NOT define how the database holds a session token.
Non-goal 18: The atom MUST NOT enumerate a session token.
Non-goal 19: The atom MUST NOT seal a session against modification.
Non-goal 20: The atom MUST NOT bound how long a session is kept.
Non-goal 21: A deployment needing a retention bound MUST compose Retention Window.
Non-goal 22: A deployment needing court-admissible records MUST compose Tamper Evidence.
Non-goal 23: The atom MUST NOT record who called [Issue].
Non-goal 24: A deployment needing attribution on issuance MUST compose Actor Identity.
Non-goal 25: The atom MUST NOT reconcile two readers disagreeing across the deadline.
Non-goal 26: A deployment needing an externally verifiable timestamp MUST compose a trusted timestamping pattern.
```

NOTE: the owners — [Login](../compositions/login.md) (Non-goal 1, Non-goal 2, Composition note 2); the deployment (Non-goal 16, Capability requirement 5; Non-goal 17, Capability requirement 6); [Tamper Evidence](./tamper-evidence.md) (Non-goal 19, Non-goal 22); [Retention Window](./retention-window.md) (Non-goal 20, Non-goal 21); [Actor Identity](./actor-identity.md) (Non-goal 23, Non-goal 24); Execution Contract Logic confinement 7 (Non-goal 25).

## Edge cases

### Clock dependence

```
Clock dependence 1: A guard MUST NOT read now.
Clock dependence 2: A rejection MUST NOT rest on now.
```

### Concurrency

```
Deleted: Concurrency 1. Execution Contract Database 2 owns it.
Deleted: Concurrency 2. Execution Contract Database 2 owns it.
Deleted: Concurrency 3. Execution Contract Database 2 owns it.
Concurrency 4: Two concurrent [Issue] calls carrying one principal reference MUST record two sessions.
```

### String policy

```
String 1: The atom MUST compare a string input byte-exactly.
String 2: The atom MUST NOT trim a string input.
String 3: The atom MUST NOT normalize a string input.
String 4: The atom MUST NOT case-fold a string input.
String 5: The atom MUST read a whitespace-only string input as blank.
String 6: The deployment MUST set a maximum length per string input.
String 7: IF a string input EXCEEDS the maximum length THEN [Issue] MUST answer invalid-request.
String 8: The deployment MUST canonicalize an opaque reference.
String 9: IF the session's status EQUALS active AND revoked by reference EXCEEDS the maximum length THEN [Revoke] MUST answer invalid-request.
String 10: IF the session's status EQUALS active AND reason EXCEEDS the maximum length THEN [Revoke] MUST answer invalid-request.
```

Term verified answer: the verified outcome [Credential](./credential.md)'s verification produces; cited from that atom, never restated here (Closed vocabulary 15).

Term invalid answer: an answer of [Validate] that EQUALS expired, revoked OR not-known — every answer outside valid.

Term authentication credential: the material a principal presents to prove identity, as [Credential](./credential.md) declares it; distinct from the session token, which is the bearer credential this atom's own [Validate] accepts (Identity 2).

### Token format

```
Token format 1: A claim set token's expiry claim MUST NOT differ from the session's expiry instant.
Token format 2: A deployment extending a claim set token MUST call [Issue].
```

Term claim set token: a session token whose format carries its own expiry claim — a JWT (JSON Web Token — a compact, signed token format carrying claims; JSON is JavaScript Object Notation, a plain-text data format), for instance.

## Composition notes

```
Composition note 1: A deployment MUST declare which composing patterns the deployment wired in.
Composition note 2: IF no verified answer EXISTS THEN a composing pattern MUST NOT call [Issue].
Composition note 3: A composing pattern MUST own the attribution of an issuance.
Composition note 4: IF [Validate] gives an invalid answer THEN a composing pattern MUST NOT call Permissions.
Composition note 5: A composing pattern MUST own the renewal policy.
Composition note 6: A composing pattern MUST own the logout propagation across a principal reference's sessions.
Composition note 7: A composing pattern MUST own the device binding.
Composition note 8: A composing pattern MUST own the concurrency bound per principal reference.
Composition note 9: A composing pattern MUST own the retention of the session records.
Composition note 10: A composing pattern reading the session records MUST NOT write to the session records.
Composition note 11: The atom MUST NOT detect an authentication credential's revocation.
```

NOTE: composing patterns — [Login](../compositions/login.md), [Session-Gated Authorization](../compositions/session-gated-authorization.md), [Privileged Access Provisioning](../compositions/privileged-access-provisioning.md).

## Terms

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is* and its **Kind**.

### Vocabulary

Term actors: the atom; the host; the transition; the implementation; the deployment; a composing pattern (also: a pattern); a business caller; a caller; a guard; a principal; an auditor; the database; a session; a status; a lapse; a liveness query; a rejection; a write; an action; a string input; an opaque reference; the session count; the session token's random material.

Term records: session — one bounded-lifetime attestation, carrying session token, principal reference, issued by reference, issuance instant, expiry instant, status and, once cancelled, revocation instant, revoked by reference and revocation reason.

Term record verbs: identify, serve, offer, compare, allocate, reuse, change, carry, share, draw, interpret, confirm, configure, supply, generate, fall, own, hold, record, stand, answer, apply, accept, stamp, recompute, derive, surface, write, fire, schedule, read, refuse, leave, rest, remove, merge, return, reach, find, reproduce, reconstruct, verify, sequence, decide, extend, call, revoke, bind, check, bound, enforce, propagate, define, enumerate, seal, compose, trim, normalize, case-fold, set, exceed, differ, give, reduce, detect, canonicalize, reconcile, declare.

Term value sets: status = active | revoked.

Term bounds: token entropy (the floor a session token's random material is drawn from); default session duration (the window [Issue] applies where the call supplies none); zero duration (the floor a session duration must exceed); maximum length (the deployment's cap per string input).

Term cadences: empty.

Term qualifiers: migrated — rewritten in GRACE lang v0.35 (2026-09-12).

Term terms: session, session token, principal reference, issued by reference, seam, transition, default session duration, token entropy, now, business caller, session duration, zero duration, issuance instant, expiry deadline, expiry instant, lapsed, effective status, revocation instant, revoked by reference, revocation reason, reason, filter, liveness query, status, blank, maximum length, validation failure.

#### Session

The record this atom defines: a time-limited authenticated channel — a durable attestation that a principal was authenticated at a specific moment, queryable until the [Session] lapses or is revoked. It carries its [Session Token], [Principal Reference], [Issued By Reference], [Issuance Instant], [Expiry Instant], [Status], and the revocation fields; its [Expiry Instant] is set once on [Issue] and never mutated. A [Session] that needs a longer lifetime is re-issued, never extended.

Kind: Type

#### Issue

The behavior the composing Login pattern invokes to record a new [Session] for a principal. It creates the record in [Active] with a fresh [Session Token], stamps [Issuance Instant] and computes [Expiry Instant] from the injected [Now] and the [Session Duration], and returns the [Session Token]. It makes no authentication judgment — it issues a [Session] for whatever [Principal Reference] it is given.

Kind: Operation

#### Validate

The read-only behavior a composing pattern invokes to answer, by [Session Token], whether there is a live [Session]. It returns one of four structurally distinct outcomes — [Valid], [Invalid Expired], [Invalid Revoked], or [Not Known] — deriving the lapsed condition from the stored record and the injected [Now]. It writes nothing under any path, including when the [Session] has lapsed.

Kind: Operation

#### Revoke

The behavior a composing pattern invokes to explicitly cancel a [Session], with attribution. It is permitted only on a stored-[Active] record; it transitions [Status] to [Revoked] and records [Revocation Instant], [Revoked By Reference], and [Revocation Reason]. A [Session] that has merely lapsed is still stored-[Active] and so may still be revoked; only a prior [Revoked] blocks it.

Kind: Operation

#### Read

The render-time behavior that returns the matching [Session] records, each carrying its derived [Effective Status]. It only reads; no record changes. It is the surface every liveness query applies, since a raw [Active] with [Expiry Instant] in the past is a lapsed [Session], not a live one.

Kind: Operation

#### Session Token

The opaque, cryptographically random, immutable, system-generated value [Issue] produces — both the [Session]'s record identity and the bearer credential the caller presents to [Validate] and [Revoke]. It is the injected `id_t`; no two sessions share one, and it is not reused after a [Session] lapses or is revoked.

Kind:       Field
Field of:   Session
Projection: session_token

#### Principal Reference

The opaque reference to the authenticated principal for whom the [Session] is issued. The atom treats it as opaque — it does not validate that the principal exists or was authenticated. Set on [Issue], immutable thereafter; the value [Validate] returns in a [Valid] result.

Kind:       Field
Field of:   Session
Projection: principal_ref

#### Issued By Reference

The opaque reference to the mechanism that issued the [Session] (a Login service, an SSO (single sign-on) system, an administrative process). Recorded as an immutable property of the [Session]. Set on [Issue], immutable thereafter.

Kind:       Field
Field of:   Session
Projection: issued_by_ref

#### Issuance Instant

The wall-time when [Issue] was called, stamped from the injected [Now]. Immutable thereafter. [Expiry Instant] is computed once as `[Issuance Instant] + [Session Duration]`.

Kind:       Field
Field of:   Session
Projection: issued_at

#### Expiry Instant

The time at which this [Session] expires — set on [Issue] as `[Issuance Instant] + [Session Duration]`, never null, and never mutated by any action. It states *when* validity ends; whether the [Session] has lapsed is *derived* from it against the injected [Now], never recorded as a stored status change. It is the sole stored input the expiry derivation needs.

Kind:       Field
Field of:   Session
Projection: expires_at

#### Status

The stored status of a [Session]: [Active] or [Revoked]. Set to [Active] on [Issue]; transitions to [Revoked] via [Revoke] and never returns to [Active]. The derived [Expired] is *not* a value of this field — it appears only in the [Effective Status] read projection.

Kind:       Field
Field of:   Session
Projection: status

#### Revocation Instant

The wall-time the [Session]'s [Status] transitioned to [Revoked], stamped from the injected [Now]. Null until revocation; immutable once set.

Kind:       Field
Field of:   Session
Projection: revoked_at

#### Revoked By Reference

The opaque reference to the actor or mechanism that performed the revocation. Required at [Revoke]; null until revocation; immutable once set.

Kind:       Field
Field of:   Session
Projection: revoked_by_ref

#### Revocation Reason

The caller-supplied reason recorded for the revocation (from the [Reason] parameter). Required at [Revoke]; null until revocation; immutable once set.

Kind:       Field
Field of:   Session
Projection: revocation_reason

#### Effective Status

The status [Read] attaches to each returned [Session] record: [Expired] when `[Status] = [Active] ∧ [Now] ≥ [Expiry Instant]`, otherwise the stored [Status]. It is a pure projection over the record and the injected [Now] — **derived at read time, never stored** — and is what makes [Validate] return [Invalid Expired]. Every liveness query applies it.

Kind:       Field
Field of:   Session
Projection: effective_status

#### Session Duration

The duration value [Issue] consumes to compute [Expiry Instant] (`[Issuance Instant] + [Session Duration]`). Supplied per call; if null, the deployment's default applies; zero or negative is rejected. It is never stored under its own name — only the computed [Expiry Instant] is stored.

Kind:         Parameter
Parameter of: Issue
Projection:   session_duration

#### Now

The current clock reading (the pipeline's `clock_t`), pipeline-injected at the I/O seam on every action — not caller-trusted, not read inside any transition, not shown as a signature parameter. It is consumed only to stamp immutable write timestamps ([Issuance Instant], [Revocation Instant]) and to evaluate the pure expiry derivation in [Validate] and [Read] (no write).

Kind:         Parameter
Parameter of: Validate
Projection:   now

#### Reason

The caller-supplied reason string [Revoke] consumes and writes into the [Session]'s [Revocation Reason]. Required non-null and non-empty. It is not stored under its own name — only [Revocation Reason] is stored.

Kind:         Parameter
Parameter of: Revoke
Projection:   reason

#### Filter

The selection a caller passes to [Read] to scope which [Session] records are returned. Consumed per call; never stored.

Kind:         Parameter
Parameter of: Read
Projection:   filter

#### Active

The only non-terminal stored state: the [Session] has been issued and may be validated. [Validate] derives expiry from the injected [Now] against the immutable [Expiry Instant] and returns [Valid] or [Invalid Expired]. A still-[Active] record past its [Expiry Instant] reads [Expired] by derivation but is *not* a stored terminal.

Kind:      Member
Member of: the stored status
Role:      Outcome

#### Revoked

The only stored terminal state: the [Session] was explicitly revoked. It can no longer be validated as [Valid], and admits no further transitions; a re-[Revoke] returns [Already Terminal]. Revocation takes precedence over expiry in [Validate]'s outcome vocabulary.

Kind:      Member
Member of: the stored status
Role:      Outcome

#### Expired

The derived status a lapsed [Session] reads as — **never stored**. It is the value of [Effective Status] when `[Status] = [Active] ∧ [Now] ≥ [Expiry Instant]`, computed at read time from the immutable [Expiry Instant] and the injected clock. No transition fires and no field is written when a [Session] lapses.

Kind:      Member
Member of: the derived effective status
Role:      Outcome

#### Valid

The [Validate] outcome when the [Session Token] references a known record that is stored-[Active] and `[Now] < [Expiry Instant]`. It carries the [Principal Reference] and [Expiry Instant]. It is the one outcome the conjunctive validity bound (Invariant 3) admits; any single condition failing yields an invalid result instead.

Kind:       Member
Member of:  the validate outcome
Role:       Outcome
Projection: valid

#### Invalid Expired

The [Validate] outcome when the record is stored-[Active] and `[Now] ≥ [Expiry Instant]` — reached **by derivation, with no write**. Structurally distinct from [Invalid Revoked]; the [Active] guard is checked first so a revoked-and-past-deadline [Session] returns [Invalid Revoked], never this.

Kind:       Member
Member of:  the validate outcome
Role:       Outcome
Projection: expired

#### Invalid Revoked

The [Validate] outcome when the record's stored [Status] is [Revoked] — regardless of whether [Expiry Instant] is still in the future. Revocation takes precedence over expiry, so this is returned even when the [Session] would also have lapsed. Permanent for a given token (Invariant 4).

Kind:       Member
Member of:  the validate outcome
Role:       Outcome
Projection: revoked

#### Not Known

The lookup-miss outcome: the supplied [Session Token] references no record. [Validate] returns it as the structurally-distinct fourth outcome (no [Session] was revoked; no [Session] exists), and [Revoke] returns it as a rejection when its target token is unknown.

Kind:       Member
Member of:  the lookup-miss outcome
Role:       Outcome
Projection: not-known

#### Invalid Request

The rejection [Issue] returns when [Principal Reference] or [Issued By Reference] is null, empty or longer than the maximum length, when [Session Duration] is zero or negative, or when the deployment default duration is absent; and [Revoke] returns when, on a session stored [Active], [Revoked By Reference] or [Reason] is null, empty or longer than the maximum length.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-request

#### Already Terminal

The rejection [Revoke] returns when the target [Session]'s stored [Status] is already [Revoked] — a re-revoke. The only stored terminal is [Revoked]; a merely-lapsed [Session] is not terminal and is not rejected here.

Kind:       Member
Member of:  the revoke rejection
Role:       Outcome
Projection: already-terminal

#### Storage Failure

The rejection [Issue] or [Revoke] returns when the underlying database write fails. The caller must treat it as definitive.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: storage-failure

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a [Term] marker to its term entry heading above (kramdown
     auto-generates the heading anchors on GitHub Pages). Standard CommonMark /
     kramdown; no plugin required. -->

[Session]: #session
[Issue]: #issue
[Validate]: #validate
[Revoke]: #revoke
[Read]: #read
[Session Token]: #session-token
[Principal Reference]: #principal-reference
[Issued By Reference]: #issued-by-reference
[Issuance Instant]: #issuance-instant
[Expiry Instant]: #expiry-instant
[Status]: #status
[Revocation Instant]: #revocation-instant
[Revoked By Reference]: #revoked-by-reference
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

- **NIST (National Institute of Standards and Technology — US federal standards body) SP 800-63B section 7 (Session Management)** — the primary standard for session management in authentication systems. Requirements for session binding, session duration, reauthentication triggers, and session termination correspond directly to this atom's behavioral commitments. The atom's [Expiry Instant] immutability and re-issuance discipline implement 800-63B's requirement that session extensions produce new session identifiers.
- **OWASP ASVS V3 (Application Security Verification Standard — Session Management)** — the OWASP (Open Worldwide Application Security Project) verification standard for session management security. Requirements for session token randomness, expiry, revocation on logout, and protection against fixation attacks are the deployment-configuration surface of this atom.
- **RFC (Request for Comments — the Internet's numbered standards series) 6265 (HTTP State Management Mechanism — HTTP being the Hypertext Transfer Protocol)** — the cookie standard. The atom's [Session Token] is the value delivered in a `Set-Cookie` response header in browser-based deployments. The atom does not specify cookie attributes (Secure, HttpOnly, SameSite) — those are the composing pattern's configuration obligations.
- **SAML 2.0 section 4.1.4 (Session Establishment and Termination)** — the SAML (Security Assertion Markup Language — an XML (Extensible Markup Language) standard for exchanging authentication data between identity and service providers) session model maps to this atom: `AuthnStatement` issuance corresponds to [Issue]; `SessionNotOnOrAfter` corresponds to [Expiry Instant]; `SLO` (Single Logout) corresponds to [Revoke]. The atom's re-issuance discipline aligns with SAML's prohibition on reusing assertion IDs.
- **RFC 6819 (OAuth 2.0 Threat Model and Security Considerations)** — identifies session-related threats (token theft, session fixation, CSRF — Cross-Site Request Forgery) that the deployment-configuration layer of this atom addresses. The atom's immutability and revocation invariants mitigate token theft's blast radius: a stolen token is bounded by [Expiry Instant] and can be revoked.
- **OIDC Session Management 1.0 (OpenID Connect Session Management)** — the OpenID Connect (OIDC — an identity layer built on OAuth 2.0) session management specification. The atom's [Session Token] corresponds to an OIDC session's identifier; [Revoke] corresponds to OIDC's Front-Channel and Back-Channel Logout protocols, and natural lapse (the derived [Expired]) corresponds to a session reaching its `SessionNotOnOrAfter` bound without an explicit logout.
- **HIPAA section 164.312(a)(2)(iii) (Automatic Logoff)** — the HIPAA automatic logoff requirement: electronic information systems must terminate after a period of inactivity. The atom's [Expiry Instant] field is the structural mechanism for this requirement; the composing deployment configures the timeout.
- **PCI DSS (Payment Card Industry Data Security Standard — the card networks' mandatory security rules for cardholder data) Requirement 8.6 (Session Management)** — session timeout and re-authentication requirements for payment systems. The atom's [Expiry Instant] immutability and re-issuance discipline satisfy the structural portion of these requirements.

Inherited from:

- **Daniel Jackson, *The Essence of Software*** — the freestanding-atom posture; the discipline of keeping credential verification, session persistence, permission checking, and logout propagation as separate composable atoms rather than absorbing them here.
- **IETF (Internet Engineering Task Force) RFC 4120 (Kerberos)** — Kerberos tickets are the canonical precedent for time-bounded, revocable authentication session records. The atom's immutable [Expiry Instant], single-stored-terminal ([Revoked]) state machine with a derived-[Expired] read projection, and revocation attribution discipline are the structured-natural-language expression of Kerberos' core concepts — a Kerberos ticket's lifetime likewise lapses by the clock against its end-time without a status write, while explicit invalidation is the recorded act.

## Status

`partially resolved` — see the Ledger.

## Ledger

```
status: partially resolved
formal: not applicable — vote no 2026-06-03
last gate: 2026-10-21 — Final Critique 6, the council's first round on the page and the first on its Store-contract rewrite (76db839), three fresh readers on free models (GRID Nemotron 3 Ultra, EOS MiniMax M3.1 Flash, Linus GLM-5.3 Flash), each handed only the round's reading set, three passes on one text (frozen at ac6f9a4); the round rests on three counted passes — foundational count 4 after triage (14 reports: 5 standing, merged into 4; 6 sent down; 3 rejected), all Kind A: Term liveness query bound an auditor's reconstruction of a past instant to the read-time effective status, against Check 3.1; Invariant 12.4 rested the effective status on expiry instant and now alone, which the page's own Term breaks on every revoked session past its deadline; String 7 obliged [Validate] and [Read], which refuse nothing, to refuse an over-long string input; and a configured default session duration of zero or less met no floor, issued by one build and refused by another; 19 refining reports, 5 rhetorical reports; not clean; every foundational finding cured in place; 2026-06-23 — Final Critique 5, fresh reader — clean

open:
- 2026-10-21-a · refining · Term filter; Operation 37; [Read] · which fields a filter names, how a field matches and what a filter naming no field matches are unstated, Operation 37 obliges every matching session and says nothing of the rest, the answer has no order, and the answer arm session_records names no declared term (GRACE-lang Closed vocabulary 27) → declare the filter over the fields the Examples and composing patterns read (principal reference, issued by reference, issuance instant), an answer of the matching sessions only, an order, and the arm as a term
- 2026-10-21-b · refining · Token format 1; Identity 9; Identity 10 · Token format 1 binds a claim set token's expiry claim and names no actor, though the host allocates the token (Identity 3) and holds every input of the expiry deadline at the seam; and a token carrying its own expiry claim is unread against Identity 9 and 10 (drawn from a random source, never from the session's public properties) → name the host as the claim's writer, and say how a claim set token meets Identity 9 and 10
- 2026-10-21-c · refining · Term session duration; Term expiry deadline · the window carries no unit, which only the Browser login example pins (3600 to one hour), and Final Critique 5's text left the unit to the deployment → state the unit, or a Capability requirement that the deployment declare it
- 2026-10-21-d · refining · Identity 8; State 3; State 8; State 9; Expiry 1; Operation 13; Operation 46 · each carries a proposition another rule carries too (Invariant 7.1; Invariant 10.1, with State 2 and Invariant 10.2; Invariant 12.1; Invariant 12.2; Invariant 12.3; Invariant 6.1; Non-goal 7), against GRACE-lang Authority 3 → tombstone one copy of each pair to the other, the checks citing the copy kept
- 2026-10-21-e · refining · Non-goal 23; Term issued by reference · who called [Issue] reads as the mechanism issued by reference records, which the Browser login example fills with the calling Login service → narrow Non-goal 23 to the actor's attribution, which Non-goal 24 and Composition note 3 give to Actor Identity and the composing pattern
- 2026-10-21-f · refining · Identity 11; Identity 12 · only the principal reference is said to be uninterpreted and unconfirmed, while revoked by reference and issued by reference are recorded on the caller's word too → say it of every opaque reference
- 2026-10-21-g · refining · String 6; String 8 · String 6 sets a maximum length per string input, which no rule applies to the token or the filter, and String 8 names neither the inputs it canonicalizes nor the canonical form → state which inputs each covers
- 2026-10-21-h · refining · Now entry; Term seam · the Now entry gives Parameter of: Validate, while [Issue], [Revoke] and [Read] consume now too (Operation 9, Operation 29, Expiry 7), and Term seam names no default session duration, which [Issue] applies (Operation 6) → name every consumer, and where the default enters
- 2026-10-21-i · refining · Clock dependence 1; Clock dependence 2 · read now can be taken for consuming the injected now, which the lapse derivation does (Expiry 5, Expiry 8) → pin that a guard takes no clock reading of its own
- 2026-10-21-j · refining · Operation 7; Summary · no maximum bounds a supplied session duration, while the Summary names short-lived elevated-access windows → a deployment maximum, or the Summary's claim narrowed
- 2026-10-21-k · refining · Non-goal 26 · a trusted timestamping pattern is linked nowhere and not marked forthcoming → link it, or mark it forthcoming
```

## Decisions

Directional changes only — the turns a future reader must know the pattern took, and why. Everything smaller lives in the commit that made it: `git log -- atoms/session.md`; the migration that got it here is in [its history](./session.hist.md).

- **2026-10-21 — A liveness query reads the present; the effective status reads the stored status; the length cap refuses only the writes; the default window is positive.** *Chose:* the auditor's reconstruction of a past instant taken out of Term liveness query, so Operation 40 and 41 bind the queries [Read] and the administrative surfaces answer at the read-time clock, and a past instant is reconstructed from the three instants each record carries (Check 3.1), the Disputed access investigator with it; Invariant 12.4 and Check 2.4 resting the effective status on the stored status, expiry instant and now, as Term effective status and Term lapsed already did; String 7 naming [Issue], and String 9 and String 10 refusing an over-long revoked by reference or reason only on a session stored active, Operation 25 and 26's form, so [Validate] and [Read], which refuse nothing, meet no length refusal and an over-long token names no session; the default session duration held above the zero duration (Capability requirement 11), the floor of Operation 8 held to a supplied duration, and Operation 6 applying the default only where one is configured. *Over:* an auditor's reconstruction bound to a projection of the present; an invariant the page's own Term breaks on every revoked session past its deadline; a refusal obliged on two actions whose signatures carry none; a configured default of zero or less, which one build refuses and another issues as a window already closed. *Because:* Final Critique 6 found each a divergence between conforming builds, or a stated check a conforming deployment fails, and the corpus already held the length cap's cure: Credential's thirteenth round names the action each length refusal binds. What the atom answers a well-formed call on a conforming deployment is unchanged.

- **2026-10-19 — The store's guarantees cited, not restated.** *Chose:* the session store supplied under Execution Contract Store 1 through 4 (Capability requirement 10), and the six rules that restated them tombstoned to their owner — Operation 32, [Revoke]'s status move and its three revocation fields committed in one operation, and Invariant 9.3, no partial session left by a storage-failure, to Store 1; Operation 35, a write the store refused leaving the store as the call found it, to Store 3; Concurrency 1 through 3, status moves on one session token serialized, two concurrent revokes answering revoked once and the later one already-terminal, to Store 2; rules 178 to 173. *Over:* the atom restating, for its own store, what every deployment's store guarantees. *Because:* the maintainer ruled 2026-10-12 that the corpus takes a store's specification, never the store, and `execution-contract.md` writes it once as the Store contract. A session's window stays auditable from its one record, as the Intent has it: the expiry instant is stamped once and no action changes it (Invariant 2.1), and the atom's own no-removal rules stay (State 11, Invariant 9.1 and 9.2). Check 1.2 rests on the auditor's own reads of a session across its life, as Credential's re-read checks do, and Check 3.1 reconstructs a past instant from the instants each record carries, so the atom cites neither History 1 nor Order 1. What the atom does for its domain is unchanged.

- **2026-06-21 — Expiry is derived at read time, never stored.** *Chose:* the stored state space is `{Active, Revoked}`; `Expired` is the projection `status = Active ∧ now ≥ expires_at` computed from the immutable expiry instant and the injected clock (Invariant 12). *Over:* a stored `Expired` terminal written by a lazy or scheduled transition. *Because:* a stored flag lags the clock it idealizes, and a session's lapse has no side effect that would need a write to carry it.

NOTE: End of Session.
