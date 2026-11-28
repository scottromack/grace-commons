---
title: Session
id: 58
audience: common
---

# Session

<details markdown="block">
<summary>Table of contents</summary>
1. TOC
{:toc}
</details>

## What it is

Session answers "is this login still good, and for whom?" without re-checking the password on every request. When a principal (the user or service whose identity a login has just proved) logs in, a session is issued: a record tying that principal to a validity window whose deadline is fixed at issue, identified by a digest of an unguessable token the caller presents on later requests, so no record holds the token itself. Checking a token gives one of four clearly separated answers — valid, with the principal and the deadline; expired; revoked; or unknown — because a lapsed login, a deliberately cancelled one and a token that never existed call for different responses. A session stays recorded as active until it is deliberately revoked, which is permanent and records who revoked it, when and why, while an active session that has reached its deadline is shown expired, a status worked out by comparing the clock with the deadline and never written into the record. The deadline never changes — a session that needs to last longer is re-issued as a new record — so every session's validity window is provable from its one record. This is the mechanism behind browser sessions, API (Application Programming Interface) access tokens, mobile logins and short-lived elevated-access windows; it deliberately does not check credentials, decide what the principal may do or run the login flow, each of which is a separate pattern. A session carries the actor id of the principal it was opened for, the credential id of the credential checked when it opened, on which the sessions of one credential end together when that credential is revoked, and a session id the host mints when the session opens, which names the one session and grants nothing: the app learns who calls from the token, through [Validate]'s lookup of its digest.

*Also known as: a login session, an authenticated session, an access token, a session ticket.*

<details markdown="block">
<summary>WHY</summary>

A system that authenticates once and then permits action across many requests needs to answer *is this principal still authenticated?* without repeating the credential check every time. A session is that answer made durable: a bounded-lifetime record attesting that a principal completed authentication at a known moment and that the result has not been invalidated since.

The atom isolates that attestation from everything around it. It does not verify credentials, decide what the principal may do, or sequence the login flow, the multi-factor challenge and the issuance; each is another pattern's, which the app chooses. It answers one structural question: given this token, is there an active, unexpired, unrevoked session for a known principal? And the answer is one of four outcomes, each provable.

The time bound is the atom's core commitment, and the discipline around it is where most session designs go wrong. The expiry instant is set at issue and never mutated. A session needing a longer life is re-issued — a new record, a new token — never extended in place. That immutability is what makes every session's window auditable from one record: no history table, no event log, no developer's account of whether the session was extended. The record says when validity ends, and that field never changes.

The second commitment is that lapsing is *derived*, not written. There is no `expire` action, no `expired_at` column, and no stored [Expired] status. A session past its deadline is computed as expired at read time from the immutable deadline against the injected clock. Nothing fires, nothing is stamped, no scheduler is needed — and the stored state space stays exactly two values, which removes the failure mode where a flag lags the clock it is meant to idealize.

</details>

## What it keeps

### The sessions

Term session: one bounded-lifetime attestation that a principal completed authentication — a [Session], the record this atom holds.

#### Session

The record this atom defines: a time-limited authenticated channel — a durable attestation that a principal was authenticated at a specific moment, queryable until the [Session] lapses or is revoked. It carries its [Session Token Digest], [Principal Reference], [Issued By Reference], [Issuance Instant], [Expiry Instant], [Status], and the revocation fields; its [Expiry Instant] is set once on [Issue] and never mutated. A [Session] that needs a longer lifetime is re-issued, never extended.

Kind: Type

```
Identity 1: The atom MUST identify a session by the session token digest.
Identity 2: The session token MUST serve as the bearer credential whose session token digest [Validate] accepts.
Identity 3: The host MUST allocate a session token at the seam.
Identity 5: The atom MUST NOT reuse a session token digest.
Identity 6: The atom MUST NOT change a session token digest.
Identity 7: An identifier beside the session token digest MUST NOT authorize an action.
Identity 9: The deployment MUST draw the session token's random material from a cryptographically secure random source.
Identity 11: The atom MUST NOT interpret an opaque reference.
Identity 12: The atom MUST NOT confirm an opaque reference.
```

Term session token: the opaque bearer credential naming one session through its session token digest — a [Session Token]; unguessable, host-allocated at the seam, delivered by the host (Capability requirement 13) and presented by its holder on later requests.

#### Session Token

The opaque, system-generated bearer credential the host allocates at the seam for an [Issue] call, drawn from cryptographically random material, and delivers to its holder, who presents it on later requests. No record of the atom holds it: the [Session] is keyed by its [Session Token Digest], which is what [Validate] and [Revoke] are given. It is not reused after a [Session] lapses or is revoked.

Kind:       Type
Projection: session_token

Term session token digest: the digest of a session token, computed by the host at the seam (Execution Contract Logic confinement 8, Logic confinement 21) — a [Session Token Digest].

#### Session Token Digest

The digest of a [Session Token], computed by the host at the seam — the [Session]'s record identity, immutable and shared by no two sessions (Identity 1, Identity 6, Invariant 7.1). [Issue] records and answers it; [Validate] and [Revoke] are given it in place of the token; [Read] never answers it (Operation 3, Operation 58, Identity 2, Operation 36, Operation 52).

Kind:       Field
Field of:   Session
Projection: session_token_digest

#### Session Id

Stored as the host allocated it and compared by byte identity; never reused, and never presented to [Validate] or [Revoke], which take the session token digest.

Kind:       Field
Field of:   Session
Projection: session_id

```
Identity 13: The host MUST allocate a session id for [Issue] at the atom's seam.
Identity 14: [Issue] MUST NOT take a session id from the business caller.
```

Term principal reference: the actor id naming the authenticated principal — a [Principal Reference].

#### Principal Reference

The actor id of the authenticated principal for whom the [Session] is issued. The atom treats it as opaque — it does not validate that the principal exists or was authenticated. Set on [Issue], immutable thereafter; the value [Validate] returns in a [Valid] result.

Kind:       Field
Field of:   Session
Projection: principal_ref

#### Credential Id

The credential id of the credential whose verify the [Session] was issued after, the key the atom pairs its sessions on (Needs). The atom treats it as opaque and does not confirm that it names a credential; the app's key check does (Bonds Key 21, Key 22). Set on [Issue], immutable thereafter; [Revoke Sessions For Credential] finds the sessions it ends by it.

Kind:       Field
Field of:   Session
Projection: credential_id

Term issued by reference: the opaque reference naming the mechanism that issued the session — an [Issued By Reference].

#### Issued By Reference

The opaque reference to the mechanism that issued the [Session] (a login service, an SSO (single sign-on) system, an administrative process). Recorded as an immutable property of the [Session]. Set on [Issue], immutable thereafter.

Kind:       Field
Field of:   Session
Projection: issued_by_ref

Term issuance instant: the now of the [Issue] call that recorded the session — an [Issuance Instant].

#### Issuance Instant

The wall-time when [Issue] was called, stamped from the injected [Now]. Immutable thereafter. [Expiry Instant] is computed once as `[Issuance Instant] + [Session Duration]`.

Kind:       Field
Field of:   Session
Projection: issued_at

Term expiry instant: the instant the session's validity ends — an [Expiry Instant]; stamped at issue, never changed, never absent.

#### Expiry Instant

The time at which this [Session] expires — set on [Issue] as `[Issuance Instant] + [Session Duration]`, never null, and never mutated by any action. It states *when* validity ends; whether the [Session] has lapsed is *derived* from it against the injected [Now], never recorded as a stored status change. It is the sole stored input the expiry derivation needs.

Kind:       Field
Field of:   Session
Projection: expires_at

Term status: active | revoked — the stored status; in force, or cancelled and terminal. expired is not a value of it.

#### Status

The stored status of a [Session]: [Active] or [Revoked]. Set to [Active] on [Issue]; transitions to [Revoked] via [Revoke] and never returns to [Active]. The derived [Expired] is *not* a value of this field — it appears only in the [Effective Status] read projection.

Kind:       Field
Field of:   Session
Projection: status

#### Active

The only non-terminal stored state: the [Session] has been issued and may be validated. [Validate] derives expiry from the injected [Now] against the immutable [Expiry Instant] and returns [Valid] or [Invalid Expired]. A still-[Active] record past its [Expiry Instant] reads [Expired] by derivation but is *not* a stored terminal.

Kind:      Member
Member of: the stored status
Role:      Outcome

#### Revoked

The only stored terminal state: the [Session] was explicitly revoked, by [Revoke], or with its credential by [Revoke Sessions For Credential]. It can no longer be validated as [Valid], and admits no further transitions; a re-[Revoke] returns [Already Terminal]. Revocation takes precedence over expiry in [Validate]'s outcome vocabulary.

Kind:      Member
Member of: the stored status
Role:      Outcome

#### Expired

The derived status a lapsed [Session] reads as — **never stored**. It is the value of [Effective Status] when `[Status] = [Active] ∧ [Now] ≥ [Expiry Instant]`, computed at read time from the immutable [Expiry Instant] and the injected clock. No transition fires and no field is written when a [Session] lapses.

Kind:      Member
Member of: the derived effective status
Role:      Outcome

Term revocation instant: the now of the [Revoke] call that cancelled the session — a [Revocation Instant].

#### Revocation Instant

The injected [Now] of the [Revoke] call that transitioned the [Session]'s [Status] to [Revoked]. Null until revocation; immutable once set.

Kind:       Field
Field of:   Session
Projection: revoked_at

Term revoked by reference: the opaque reference naming the actor that cancelled the session — a [Revoked By Reference].

#### Revoked By Reference

The opaque reference to the actor or mechanism that performed the revocation. Required at [Revoke]; null until revocation; immutable once set; never recorded by [Revoke Sessions For Credential], whose call names no actor.

Kind:       Field
Field of:   Session
Projection: revoked_by_ref

Term revocation reason: the stated ground for the cancellation — a [Revocation Reason], carried from the call's [Reason].

#### Revocation Reason

The caller-supplied reason recorded for the revocation (from the [Reason] parameter). Required at [Revoke]; null until revocation; immutable once set; never recorded by [Revoke Sessions For Credential], whose call carries no reason.

Kind:       Field
Field of:   Session
Projection: revocation_reason

Term effective status: expired where the session is lapsed, and the stored status otherwise — an [Effective Status]; a pure projection over the session and now, never stored.

#### Effective Status

The status [Read] attaches to each returned [Session] record: [Expired] when `[Status] = [Active] ∧ [Now] ≥ [Expiry Instant]`, otherwise the stored [Status]. It is a pure projection over the record and the injected [Now] — **derived at read time, never stored** — and is what makes [Validate] return [Invalid Expired]. Every liveness query applies it.

Kind:       Field
Field of:   Session
Projection: effective_status

NOTE: watch a term entry's kind — the effective status is derived at each read and never stored, yet its term entry takes `Kind: Field`, as a stored field's does.

Term lapsed: the session's status EQUALS active and now is no earlier than the session's expiry instant — the condition [Validate] derives and never stamps.

```
State 1: EVERY session MUST stand in EXACTLY ONE OF active, revoked.
State 2: EVERY session MUST carry session token digest, principal reference, issued by reference, issuance instant, expiry instant and status.
State 4: A session [Revoke] stood in revoked MUST carry revocation instant, revoked by reference and revocation reason.
State 5: An active session MUST NOT carry revocation instant.
State 6: An active session MUST NOT carry revoked by reference.
State 7: An active session MUST NOT carry revocation reason.
State 10: The atom MUST NOT offer a transition out of revoked.
State 11: The atom MUST NOT remove a session from the database.
State 12: The atom MUST NOT hold a permission.
State 13: The atom MUST NOT hold a device context.
State 14: The atom MUST NOT hold a bound on concurrent sessions per principal reference.
State 15: EVERY session MUST carry a session id.
State 16: EVERY session MUST carry a credential id.
State 17: EVERY session [Revoke Sessions For Credential] stood in revoked MUST carry revocation instant as the session's one revocation field.
```

#### Expiry

```
Expiry 2: A lapse MUST NOT fire a transition.
Expiry 4: The deployment MUST NOT schedule a lapse.
Expiry 5: The atom MUST derive a lapse from expiry instant against now.
```

## What people do

### Every action

```
Operation 40: A liveness query MUST rest on the effective status.
Operation 41: A liveness query MUST NOT rest on the stored status alone.
Operation 45: The atom MUST NOT offer an expire action.
Operation 47: The atom MUST NOT offer an un-revoke action.
```

Term liveness query: any query for the sessions in force at the read-time clock — the atom's [Read] and the administrative surfaces built on it.

NOTE: watch the required input no rule records (Operation 30, Operation 50, Operation 51).

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the database |
|---|---|---|---|
| either write | database refuses | [Storage Failure] | none (Operation 12, Operation 34) |
| any call | its read of the session records fails | `state-unavailable` | none (Execution Contract Read 1, Execution Contract Read 3) |
| *a window lapses* | now reaches expiry instant | nothing is called | **nothing written** — no action, no stamp, no scheduler (Expiry 2 through 5, Invariant 12.3) |

#### Invalid Request

The rejection [Issue] returns when [Principal Reference], [Credential Id] or [Issued By Reference] is blank or longer than the maximum length, when [Session Duration] is no window length, or is zero or negative, or when the default session duration is absent, no window length, zero or negative; and [Revoke] returns when, on a session stored [Active], [Revoked By Reference] or [Reason] is blank or longer than the maximum length, or [Reason] is malformed.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-request

#### Not Known

The lookup-miss outcome: the supplied [Session Token Digest] references no record. [Validate] returns it as the structurally-distinct fourth outcome (no [Session] was revoked; no [Session] exists), and [Revoke] returns it as a rejection when its target digest is unknown.

Kind:       Member
Member of:  the lookup-miss outcome
Role:       Outcome
Projection: not-known

#### Storage Failure

The rejection [Issue], [Revoke] or [Revoke Sessions For Credential] returns when the underlying database write fails.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: storage-failure

### Issue

The behavior a composing pattern invokes to record a new [Session] for a principal. It creates the record in [Active] keyed by the [Session Token Digest] of the fresh [Session Token] the host allocated, stamps [Issuance Instant] and computes [Expiry Instant] from the injected [Now] and the [Session Duration], and answers [Issued], the [Session Token Digest] and the [Session Id] the host allocated for the call; the host, not the atom, delivers the [Session Token] itself. It makes no authentication judgment — it issues a [Session] for whatever [Principal Reference] it is given.

Kind: Operation

```
issue(principal_ref, credential_id, issued_by_ref, optional session_duration)
  answers issued(session_token_digest, session_id)
  refuses invalid-request | storage-failure
```

```
Operation 1: [Issue] MUST record EXACTLY ONE session per successful call.
Operation 2: [Issue] MUST stand the session in active.
Operation 3: [Issue] MUST answer the session token digest AND the session id.
Operation 4: IF principal reference EQUALS blank THEN [Issue] MUST answer invalid-request.
Operation 5: IF issued by reference EQUALS blank THEN [Issue] MUST answer invalid-request.
Operation 6: IF session duration EQUALS blank AND the default session duration DOES NOT EQUAL blank THEN [Issue] MUST apply the default session duration.
Operation 8: IF session duration DOES NOT EQUAL blank AND the session duration DOES NOT EXCEED the zero duration THEN [Issue] MUST answer invalid-request.
Operation 9: [Issue] MUST stamp issuance instant from the injected now.
Operation 10: [Issue] MUST stamp expiry instant from the expiry deadline.
Operation 11: [Issue] MUST NOT recompute expiry instant from a later clock reading.
Operation 12: IF the database refuses the write THEN [Issue] MUST answer storage-failure.
Operation 48: IF the default session duration EQUALS blank THEN [Issue] MUST answer invalid-request.
Operation 50: [Issue] MUST record the principal reference the call supplies.
Operation 51: [Issue] MUST record the issued by reference the call supplies.
Operation 55: IF a supplied session duration is malformed THEN [Issue] MUST answer invalid-request (Execution Contract Input 1).
Operation 65: IF the default session duration is no window length THEN [Issue] MUST answer invalid-request.
Operation 56: IF the default session duration DOES NOT EQUAL blank AND the default session duration DOES NOT EXCEED the zero duration THEN [Issue] MUST answer invalid-request.
Operation 58: [Issue] MUST record the session token digest of the session token the host allocates (Identity 3, Capability requirement 12).
Operation 62: [Issue] MUST record the session id the host allocated for the call (Identity 13).
Operation 66: IF credential id EQUALS blank THEN [Issue] MUST answer invalid-request.
Operation 67: [Issue] MUST record the credential id the call supplies.
```

Term session duration: the window a [Issue] call asks for, a window length — a [Session Duration]; consumed to compute the expiry deadline, never stored under this name.

#### Issued

The [Issue] outcome when the call records a session. It carries the [Session Token Digest] and the [Session Id].

Kind:       Member
Member of:  the issue outcome
Role:       Outcome
Projection: issued

#### Session Duration

The duration value, a whole number of seconds, [Issue] consumes to compute [Expiry Instant] (`[Issuance Instant] + [Session Duration]`). Supplied per call; if blank, the deployment's default applies; a value that is no whole number of seconds, zero or negative is rejected. It is never stored under its own name — only the computed [Expiry Instant] is stored.

Kind:         Parameter
Parameter of: Issue
Projection:   session_duration

Term window length: a whole number of seconds — what a session duration and the default session duration carry.

Term zero duration: a duration of no length — the floor a session duration must exceed, which refuses zero and every negative value.

Term expiry deadline: `(issued_at + session_duration)` — what [Issue] stores as expiry instant, computed once at issue (Execution Contract Logic confinement 9); on a call supplying no session duration, the default session duration [Issue] applies takes the session duration's place (Operation 6).

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the database |
|---|---|---|---|
| [Issue] | the principal reference, the credential id and the issued by reference present, a positive default configured, duration positive or defaulted, database accepts | [Issued], the new session token digest and the session id | one record lands in [Active] carrying the session token digest of the session token the host allocated, the session id the host allocated, the credential id and both references, issuance instant and expiry instant stamped (Operation 1, Operation 3, Operation 9, Operation 10, Operation 50, Operation 51, Operation 58, Operation 62) |
| [Issue] | a blank or over-long reference or credential id, a duration that is no window length or is not positive, no configured default, or a default that is no window length or is not positive | [Invalid Request] | none (Operation 4, Operation 5, Operation 66, Operation 8, Operation 48, String 7, Operation 55, Operation 56, Operation 65) |

### Validate

The read-only behavior a composing pattern invokes to answer, by the [Session Token Digest] of the [Session Token] a caller presents, whether there is a live [Session]. It returns one of four structurally distinct outcomes — [Valid], [Invalid Expired], [Invalid Revoked], or [Not Known] — deriving the lapsed condition from the stored record and the injected [Now]. It writes nothing under any path, including when the [Session] has lapsed.

Kind: Operation

```
validate(session_token_digest)
  answers valid(principal_ref, expires_at) | invalid(validation failure)
```

Term validation failure: expired | revoked | not-known — the reasons [Validate] gives for an invalid session.

NOTE: watch the outcome that carries a value — [Validate]'s invalid arm carries a validation failure, whose members the rules land as answers (Operation 14 through 16, Invariant 6.1) and the Examples write inside the arm.

```
Operation 14: IF the session token digest names no session THEN [Validate] MUST answer not-known.
Operation 15: IF the session's status EQUALS revoked THEN [Validate] MUST answer revoked.
Operation 16: IF the session is lapsed THEN [Validate] MUST answer expired.
Operation 17: [Validate] MUST answer expired ONLY IF the session's status EQUALS active.
Operation 18: IF the session's effective status EQUALS active THEN [Validate] MUST answer valid.
Operation 19: [Validate] MUST carry principal reference and expiry instant in a valid answer.
Operation 20: [Validate] MUST NOT write.
```

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the database |
|---|---|---|---|
| [Validate] | digest names nothing | [Not Known] | none — the call reads (Operation 14, Operation 20) |
| [Validate] | stored status is [Revoked] | [Invalid Revoked] | none — returned even where the window is still open (Operation 15) |
| [Validate] | stored [Active], now has reached expiry instant | [Invalid Expired] | none — derived, nothing written (Operation 16, Operation 17) |
| [Validate] | stored [Active], now short of expiry instant | [Valid], carrying [Principal Reference] and [Expiry Instant] | none (Operation 18, Operation 19) |

#### Valid

The [Validate] outcome when the [Session Token Digest] references a known record that is stored-[Active] and `[Now] < [Expiry Instant]`. It carries the [Principal Reference] and [Expiry Instant]. It is the one outcome the conjunctive validity bound (Invariant 3) admits; any single condition failing yields an invalid result instead.

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

### Revoke

The behavior a composing pattern invokes to explicitly cancel a [Session], with attribution. It is permitted only on a stored-[Active] record; it transitions [Status] to [Revoked] and records [Revocation Instant], [Revoked By Reference], and [Revocation Reason]. A [Session] that has merely lapsed is still stored-[Active] and so may still be revoked; only a prior [Revoked] blocks it.

Kind: Operation

```
revoke(session_token_digest, revoked_by_ref, reason)
  answers revoked
  refuses invalid-request | already-terminal | not-known | storage-failure
```

```
Operation 22: IF the session token digest names no session THEN [Revoke] MUST answer not-known.
Operation 23: IF the session's status EQUALS revoked THEN [Revoke] MUST answer already-terminal.
Operation 24: [Revoke] MUST answer already-terminal ONLY IF the session's status EQUALS revoked.
Operation 25: IF the session's status EQUALS active AND the revoked by reference the call supplies EQUALS blank THEN [Revoke] MUST answer invalid-request.
Operation 26: IF the session's status EQUALS active AND reason EQUALS blank THEN [Revoke] MUST answer invalid-request.
Operation 27: [Revoke] MUST accept a lapsed session.
Operation 28: [Revoke] MUST stand the session in revoked.
Operation 29: [Revoke] MUST stamp revocation instant from the injected now.
Operation 30: [Revoke] MUST record the revoked by reference the call supplies on the session.
Operation 31: [Revoke] MUST record the reason as the revocation reason.
Operation 33: [Revoke] MUST answer revoked.
Operation 34: IF the database refuses the write THEN [Revoke] MUST answer storage-failure.
Operation 36: [Revoke] MUST accept the session token digest as the whole authorization.
Operation 57: IF the session's status EQUALS active AND reason is malformed THEN [Revoke] MUST answer invalid-request (Execution Contract Input 1, Execution Contract Input 3).
```

NOTE: watch the untyped input (Term reason, Operation 57).

Term reason: the [Revoke] input the session keeps as revocation reason, a string input — a [Reason].

#### Reason

The caller-supplied reason string [Revoke] consumes and writes into the [Session]'s [Revocation Reason]. On a session stored [Active], a blank, over-long or malformed reason is refused (Operation 26, String 10, Operation 57). It is not stored under its own name — only [Revocation Reason] is stored.

Kind:         Parameter
Parameter of: Revoke
Projection:   reason

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the database |
|---|---|---|---|
| [Revoke] | digest names a session in [Active], attribution present | revoked | [Active] → [Revoked], three fields stamped; the session token digest, principal reference, issued by reference, issuance instant and expiry instant stand (Operation 28 through 31, Invariant 1.1, Invariant 2.1) |
| [Revoke] | digest names a session in [Active] past its deadline | revoked | as above — a lapse is not a stored terminal (Operation 27) |
| [Revoke] | digest names nothing | [Not Known] | none (Operation 22) |
| [Revoke] | stored status is already [Revoked] | [Already Terminal] | none (Operation 23, Operation 24) |
| [Revoke] | session in [Active], blank or over-long attribution, or a malformed reason | [Invalid Request] | none (Operation 25, Operation 26, String 9, String 10, Operation 57) |

#### Already Terminal

The rejection [Revoke] returns when the target [Session]'s stored [Status] is already [Revoked] — a re-revoke. The only stored terminal is [Revoked]; a merely-lapsed [Session] is not terminal and is not rejected here.

Kind:       Member
Member of:  the revoke rejection
Role:       Outcome
Projection: already-terminal

### Revoke Sessions For Credential

The write that cancels every session issued on one credential when the credential is revoked, as [Revoke] cancels one: every [Session] carrying the [Credential Id] whose stored [Status] is [Active] stands in [Revoked], recording [Revocation Instant] alone; the action the credential id need's on end names, which the app calls when an action the meeting offer's ends names ends the credential (Needs; Bonds Key 3). It takes the credential id alone and records no [Revoked By Reference] and no [Revocation Reason], since no actor's call reaches it. A lapsed session is still stored [Active] and is revoked with the rest (Term lapsed); a session already [Revoked] keeps its fields. Where no stored-[Active] session carries the credential id, a blank or over-long one included, since [Issue] records neither (Operation 66, String 7), it answers ok and writes nothing (Bonds Key 7).

Kind: Operation

```
revoke_sessions_for_credential(credential_id)
  answers ok
  refuses storage-failure
```

```
Operation 68: [Revoke Sessions For Credential] MUST stand in revoked EVERY active session that carries the credential id.
Operation 69: IF an active session carries the credential id THEN [Revoke Sessions For Credential] MUST stamp revocation instant from the injected now on EVERY session the call stands in revoked.
Operation 70: [Revoke Sessions For Credential] MUST NOT record a revoked by reference.
Operation 71: [Revoke Sessions For Credential] MUST NOT record a revocation reason.
Operation 72: [Revoke Sessions For Credential] MUST NOT write a session other than one Operation 68 stands in revoked.
Operation 73: IF the database refuses no write THEN [Revoke Sessions For Credential] MUST answer ok.
Operation 74: IF no active session carries the credential id THEN [Revoke Sessions For Credential] MUST NOT write.
Operation 75: IF the database refuses the write THEN [Revoke Sessions For Credential] MUST answer storage-failure.
```

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the database |
|---|---|---|---|
| [Revoke Sessions For Credential] | a session carrying the credential id stands in [Active] | ok (Operation 73) | each such session stands in [Revoked], carrying now as its revocation instant and no revoked by reference or revocation reason (Operation 68 through 71); every other session is left as it is (Operation 72) |
| [Revoke Sessions For Credential] | no session carrying the credential id stands in [Active] | ok (Operation 73) | none, no write (Operation 74) |
| [Revoke Sessions For Credential] | a session carrying the credential id stands in [Active], the database refuses the write | [Storage Failure] | none, each such session stays [Active] (Operation 75, Execution Contract Database 1) |

### Read

The render-time behavior that returns the matching [Session] records, each carrying its derived [Effective Status] and never its [Session Token Digest]. It only reads; no record changes. It is the surface every liveness query applies, since a raw [Active] with [Expiry Instant] in the past is a lapsed [Session], not a live one.

Kind: Operation

```
read(filter)
  answers the matching sessions
```

```
Operation 37: [Read] MUST answer EVERY session the filter matches.
Operation 38: [Read] MUST carry the effective status on EVERY answered session.
Operation 39: [Read] MUST NOT write.
Operation 52: [Read] MUST NOT carry the session token digest on an answered session.
Operation 53: IF a filter names a field whose value EQUALS blank THEN [Read] MUST answer no session.
Operation 59: [Read] MUST carry principal reference, issued by reference, issuance instant, expiry instant and status on EVERY answered session.
Operation 60: [Read] MUST carry revocation instant on EVERY answered revoked session, and revoked by reference and revocation reason on EVERY answered session [Revoke] stood in revoked.
Operation 61: IF the filter names a field other than principal reference and issued by reference OR the filter carries more than one value on a named field OR the filter's value on principal reference EXCEEDS the maximum length of principal reference OR the filter's value on issued by reference EXCEEDS the maximum length of issued by reference THEN [Read] MUST answer no session (String 6, Execution Contract Input 2, Execution Contract Query 1, Execution Contract Query 5).
Operation 63: [Read] MUST carry the session id on EVERY answered session.
Operation 64: [Read] MUST answer the sessions in issuance instant order, earliest first, then by session id ascending (Execution Contract Read 5, Execution Contract Logic confinement 10).
```

Term filter: the selection a [Read] call scopes the answer by — a [Filter] naming principal reference, issued by reference, both, no field, OR a field other than principal reference and issued by reference; a session matches a filter when it carries EVERY value the filter names (String 1) and the filter names no blank value (Operation 53), no value on principal reference or issued by reference that EXCEEDS the maximum length of that field (Operation 61), no more than one value on a field (Operation 61) and no field other than principal reference and issued by reference (Operation 61), so a filter naming no field matches EVERY session; consumed per call, never stored.

#### Filter

The selection a caller passes to [Read] to scope which [Session] records are returned: a [Principal Reference], an [Issued By Reference], both, neither, or a field other than principal reference and issued by reference. A [Session] matches when it carries every value the filter names, and a filter naming no field matches every [Session]; a filter naming a blank value, a value over the maximum length of its field, more than one value on a named field, or any field other than principal reference and issued by reference, matches none. Consumed per call; never stored.

Kind:         Parameter
Parameter of: Read
Projection:   filter

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the database |
|---|---|---|---|
| [Read] | a filter outside the next row's cases | the matching sessions, each carrying its principal reference, issued by reference, issuance instant, expiry instant, status, revocation instant once revoked, revoked by reference and revocation reason where [Revoke] stood it in revoked, effective status and session id, and no session token digest | none (Operation 37, Operation 38, Operation 52, Operation 59, Operation 60, Operation 63, Operation 64) |
| [Read] | a filter naming a blank value, or a value that EXCEEDS the maximum length of its field, or more than one value on a named field, or a field other than principal reference and issued by reference | no session | none (Operation 37, Operation 53, Operation 61, Term filter) |

### Read Session

The read that answers one session by its session id, with its derived [Effective Status] and never its [Session Token Digest]: the existence read the session id offer names (Offers; Bonds Key 26). It writes nothing, and the session id grants nothing (Identity 7); a session id no session carries answers not-known.

Kind: Operation

```
read_session(session_id)
  answers session
  refuses not-known
```

```
Operation 76: IF no session carries the session id THEN [Read Session] MUST answer not-known.
Operation 77: [Read Session] MUST answer the session's session id, principal reference, credential id, issued by reference, issuance instant, expiry instant AND effective status.
Operation 80: [Read Session] MUST answer EVERY revocation instant, revoked by reference AND revocation reason the session carries.
Operation 78: [Read Session] MUST NOT answer a session token digest.
Operation 79: [Read Session] MUST NOT write.
```

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the database |
|---|---|---|---|
| [Read Session] | no session carries the session id | [Not Known] | none (Operation 76, Operation 79) |
| [Read Session] | a session carries the session id | the session, carrying its session id, principal reference, credential id, issued by reference, issuance instant, expiry instant, effective status and every revocation instant, revoked by reference and revocation reason it carries, and no session token digest | none (Operation 77, Operation 78, Operation 79, Operation 80) |

## What is and what should never be (Invariants)

- **Invariant 3 — Validity bound conjunctive, by derivation.**
  ```
  Invariant 3.1: [Validate] MUST answer valid ONLY IF the session token digest names a session AND the session's status EQUALS active AND the session is not lapsed.
  Invariant 3.3: [Validate] MUST NOT answer expired for a revoked session.
  ```
- **Invariant 4 — Revocation absorbing.**
  ```
  Invariant 4.1: [Validate] MUST NOT answer valid for a revoked session.
  ```
- **Invariant 6 — Four structurally distinct validate outcomes.**
  ```
  Invariant 6.1: [Validate] MUST answer EXACTLY ONE OF valid, expired, revoked, not-known (Execution Contract Read 2).
  Invariant 6.2: An implementation MUST NOT merge two validate answers.
  ```
- **Invariant 7 — Session token digest uniqueness.**
  ```
  Invariant 7.1: Two sessions MUST NOT share a session token digest.
  Invariant 7.2: The host MUST NOT allocate a session token whose session token digest any session carries.
  Invariant 7.3: Two sessions MUST NOT share a session id.
  ```
- **Invariant 8 — Revocation attribution completeness.**
  ```
  Invariant 8.1: EVERY revoked session MUST carry a revocation instant.
  Invariant 8.2: EVERY session [Revoke] stood in revoked MUST carry a revoked by reference that DOES NOT EQUAL blank.
  Invariant 8.3: EVERY session [Revoke] stood in revoked MUST carry a revocation reason that DOES NOT EQUAL blank.
  ```
- **Invariant 10 — Every session has a finite lifetime.**
  ```
  Invariant 10.1: EVERY session MUST carry an expiry instant.
  ```
- **Invariant 11 — Expiry absorbing, by derivation.**
  ```
  Invariant 11.1: [Validate] MUST NOT answer valid for a lapsed session.
  ```
- **Invariant 1 — Issue immutability.**
  ```
  Invariant 1.1: A recorded session's session token digest, principal reference, credential id, issued by reference, issuance instant and expiry instant MUST NOT change.
  Invariant 1.2: A session's status and revocation fields MUST stand as the only fields a later action writes.
  ```
- **Invariant 2 — Expiry instant immutability.**
  ```
  Invariant 2.1: An action MUST NOT change a recorded expiry instant.
  ```
- **Invariant 5 — Stored terminal absorbing.**
  ```
  Invariant 5.1: A revoked session MUST NOT leave revoked.
  ```
- **Invariant 9 — Session durability over this atom's own surface.**
  ```
  Invariant 9.1: The atom MUST NOT offer a removal surface.
  Invariant 9.2: An action the atom offers MUST NOT reduce the session count.
  ```
- **Invariant 12 — Expiry is derived, never written.**
  ```
  Invariant 12.1: A session MUST NOT carry a stored expired status.
  Invariant 12.2: A session MUST NOT carry an expiry time stamp beside expiry instant.
  Invariant 12.3: A lapse MUST NOT write to the session.
  Invariant 12.4: The effective status MUST rest on the stored status, expiry instant and now.
  ```

Invariants 1, 2 and 10 together give the *temporal auditability* property — every session's window is fully determined from one record, with no mutable validity field. Invariants 3, 6 and 12 give *validation clarity* — the outcome of any [Validate] call is unambiguous, distinguishable, and computed from the record and the injected clock alone. Invariants 4 and 11 give *terminal finality* — neither a revoked session nor a lapsed one resurfaces as valid by any path.

## When something happens

### Concurrency

```
Concurrency 4: Two concurrent [Issue] calls carrying one principal reference MUST record two sessions.
```

## While something is so

### Clock dependence

```
Clock dependence 2: A rejection MUST NOT rest on now.
```

### String policy

```
String 1: The atom MUST compare a string input byte for byte.
String 2: The atom MUST NOT trim a string input.
String 3: The atom MUST NOT normalize a string input.
String 4: The atom MUST NOT case-fold a string input.
String 6: The deployment MAY declare a maximum length per string input PER Execution Contract Input 2; a filter's value on principal reference or issued by reference takes the maximum length of that field's string input.
String 7: IF a string input EXCEEDS the maximum length THEN [Issue] MUST answer invalid-request.
String 9: IF the session's status EQUALS active AND the revoked by reference the call supplies EXCEEDS the maximum length THEN [Revoke] MUST answer invalid-request.
String 10: IF the session's status EQUALS active AND reason EXCEEDS the maximum length THEN [Revoke] MUST answer invalid-request.
```
## Optional

```
Capability requirement 1: The deployment MUST supply now at the seam.
Capability requirement 2: The deployment MUST configure a default session duration.
Capability requirement 3: The deployment MUST supply the session token's random material at the seam.
Capability requirement 4: The session token's random material MUST NOT fall below the token entropy.
Capability requirement 5: The deployment MUST own the session token's format.
Capability requirement 10: The deployment MUST supply the session records PER Execution Contract Database 1 through 7, Execution Contract Read 5, Execution Contract Read 6 and Execution Contract Input 1.
Capability requirement 12: The deployment MUST supply the session token digest at the seam (Execution Contract Logic confinement 8).
Capability requirement 13: The host MUST deliver the session token to the business caller of the [Issue] call the host allocated the session token for.
Capability requirement 14: The deployment MUST supply at the seam, for each [Issue] call, a session id no session has carried PER Execution Contract Logic confinement 3 and Execution Contract Logic confinement 16.
```

Term default session duration: the window [Issue] applies where the call supplies no session duration, a window length; deployment configuration (Capability requirement 2), and its absence, a value that is no window length, or a value that does not exceed the zero duration, is a misconfiguration rather than an operating state, so [Issue] refuses every call while it stands, a call supplying its own session duration included (Operation 48, Operation 56, Operation 65).

Term token entropy: 128 bits of cryptographically secure random material — the floor a session token is drawn from, sufficient for negligible collision probability and for unguessability.

Term seam: the atom's I/O (input and output) boundary; the host injects the clock reading, the session token digest, the session id, the token's random material and the default session duration here.

Term transition: the atom's evaluation of one call against the session records.

Term now: the deployment's clock reading at the call — a [Now], as Execution Contract Logic confinement 11 declares it.

Term business caller: the party whose action the call carries; never the source of an injected value.

NOTE: watch the seam citation (Term seam, Term transition, Term business caller).

#### Now

The current clock reading (the pipeline's `clock_t`), pipeline-injected at the I/O seam on every action — not caller-trusted, not read inside any transition, not shown as a signature parameter. It is consumed only to stamp immutable write timestamps ([Issuance Instant], [Revocation Instant]) and to evaluate the pure expiry derivation in [Validate] and [Read] (no write).

Kind:         Parameter
Parameter of: Issue, Validate, Revoke, Revoke Sessions For Credential, Read and Read Session
Projection:   now

### Token format

```
Token format 1: The host MUST NOT allocate a claim set token whose expiry claim differs from the session's expiry instant.
Token format 2: A deployment extending a claim set token MUST call [Issue].
Token format 3: IF the session token's format cannot carry the expiry deadline exactly THEN the session token MUST carry no expiry claim.
```

NOTE: Token format 1 and Token format 2 bind a claim set token's expiry claim and its extension, never the token's format, which the deployment owns (Capability requirement 5, Non-goal 16), and Token format 3 gives the token whose format cannot carry the expiry deadline exactly no expiry claim at all; the host allocates the token at the top of the pipeline's Step 3, holding the invocation's one clock reading and the window [Issue] applies, so a claim set token's expiry claim carries the expiry deadline [Issue] stamps (Execution Contract Logic confinement 3, 9).

Term claim set token: a session token whose format carries its own expiry claim — a JWT (JSON Web Token — a compact, signed token format carrying claims; JSON is JavaScript Object Notation, a plain-text data format), for instance.

## Needs

The bonds this atom needs, of a bond kind [Bonds](../bonds.md) states; which atom meets each is the app's choice. [Issue] takes the principal and the credential id the call gives and checks neither: that the principal proved who it is, with that credential, is the action [Issue] follows (Composition note 2). [Issue] may follow another atom's action whose answer carries an actor id and then a credential id, the app making the call in that action's transaction with those two values, in that order, as its principal reference and credential id, and supplying the issued by reference and any session duration from its own action (Bonds Follow-up 1, Follow-up 2, Follow-up 8); a refusal of the issue undoes the followed action (Bonds Follow-up 5), and an app with no such action makes no such call (Bonds Follow-up 6). When an action the meeting offer's ends names ends a credential id, the app calls [Revoke Sessions For Credential] with it in that action's transaction (Bonds Key 3).

Term need key: key actor id; pairs sessions.

Term need key: key credential id; pairs sessions; on end Revoke Sessions For Credential.

Term need follow-up: runs Issue; takes actor id, credential id.

## Offers

The bond this atom offers, of a bond kind [Bonds](../bonds.md) states. The session id names one session and grants nothing (Identity 7); [Validate] and [Revoke] take the session token digest.

Term offer key: key session id; carried by sessions; calls Read Session.

## Left to others

```
Non-goal 1: The atom MUST NOT verify an authentication credential.
Deleted: Non-goal 2. Non-goal 1 owns it: the atom verifies no authentication credential, and which pattern does is the app's choice.
Non-goal 3: The atom MUST NOT sequence a challenge of more than one factor.
Deleted: Non-goal 4. Non-goal 3 owns it: the atom sequences no login, and the sign-in flow is the app's.
Non-goal 5: The atom MUST NOT decide what a principal reference may do.
Deleted: Non-goal 6. Non-goal 5 owns it: the atom decides nothing a principal may do; the app's permission does.
Non-goal 7: The atom MUST NOT extend a session in place.
Non-goal 8: A deployment needing a sliding window MUST call [Issue] again.
Non-goal 9: A composing pattern renewing a session MUST revoke the prior session.
Non-goal 10: The atom MUST NOT bind a session token to a device.
Non-goal 11: A deployment needing device binding MUST check the device context outside the atom.
Non-goal 12: The atom MUST NOT bound how many sessions one principal reference holds.
Non-goal 13: A deployment needing a bound on concurrent sessions MUST enforce the bound at the composing layer.
Non-goal 14: The atom MUST NOT propagate a revocation across a principal reference's other sessions.
Non-goal 15: A deployment needing log-out propagation MUST revoke one by one the principal reference's sessions whose session token digests the deployment holds.
Non-goal 16: The atom MUST NOT define the session token's format.
Non-goal 18: The atom MUST NOT enumerate a session token digest.
Non-goal 19: The atom MUST NOT seal a session against modification.
Non-goal 20: The atom MUST NOT bound how long a session is kept.
Deleted: Non-goal 21. Non-goal 20 owns it: the atom bounds no retention, and which pattern does is the app's choice.
Deleted: Non-goal 22. Non-goal 19 owns it: the atom seals no session, and which pattern makes records tamper-evident is the app's choice.
Deleted: Non-goal 24. Composition note 3 owns it: a composing pattern owns the attribution of an issuance.
Non-goal 25: The atom MUST NOT reconcile two readers disagreeing across the deadline.
Non-goal 26: The atom MUST NOT supply a time stamp verifiable outside the atom.
Non-goal 27: The atom MUST NOT detect an authentication credential's revocation.
Non-goal 28: The atom MUST NOT set a maximum session duration.
Non-goal 29: A deployment needing a maximum session duration MUST enforce the maximum at the composing layer.
Non-goal 30: The atom MUST NOT reconcile a session's revocation instant with a valid answer [Validate] gave on reading the session stored active.
```

NOTE: the owners — a pattern that verifies credentials (Non-goal 1); the app, which sequences the factors (Non-goal 3), calls [Issue] as the follow-up of a verified answer (Composition note 2) and calls [Revoke Sessions For Credential] in the action that revokes a credential, which the atom never detects (Non-goal 27; Bonds Key 3); the app's permission (Non-goal 5); the composing pattern (Non-goal 7 through 9, Composition note 5; Non-goal 10, Non-goal 11, Composition note 7; Non-goal 12, Non-goal 13, Composition note 8; Non-goal 14, Non-goal 15, Composition note 6; Non-goal 28, Non-goal 29); the deployment (Non-goal 16, Capability requirement 5; Non-goal 18); a pattern that makes records tamper-evident (Non-goal 19); a pattern that bounds retention (Non-goal 20); the composing pattern that attributes an issuance (Composition note 3); Execution Contract Logic confinement 7 (Non-goal 25); Execution Contract Logic confinement 3 and Database 2 (Non-goal 30); a pattern that anchors time (Non-goal 26).

```
Composition note 1: A deployment MUST declare which composing patterns the deployment wired in.
Composition note 2: IF no verified answer EXISTS THEN a composing pattern MUST NOT call [Issue].
Composition note 3: A composing pattern MUST own the attribution of an issuance.
Composition note 4: IF [Validate] gives an invalid answer THEN a composing pattern MUST NOT ask a permission check for the call.
Composition note 5: A composing pattern MUST own the renewal policy.
Composition note 6: A composing pattern MUST own the log-out propagation across a principal reference's sessions.
Composition note 7: A composing pattern MUST own the device binding.
Composition note 8: A composing pattern MUST own the bound on concurrent sessions per principal reference.
Composition note 9: A composing pattern MUST own the retention of the session records.
Composition note 12: A composing pattern MUST own the attribution of a revocation.
```

Term verified answer: the verified outcome a credential check produces, in the pattern that checks credentials; cited from that pattern, never restated here (Closed vocabulary 15).

Term invalid answer: an answer of [Validate] that carries a validation failure, so one that EQUALS expired, revoked OR not-known; a call whose read failed answers state-unavailable (Execution Contract Read 1), which is no invalid answer, and a composing pattern maps it as it maps any constituent rejection (the section titled Substrate composition invocation in `execution-contract.md`).

Term authentication credential: the material a principal presents to prove identity, as the pattern that checks credentials declares it; distinct from the session token, the bearer credential whose session token digest this atom's own [Validate] accepts (Identity 2).

NOTE: composing patterns — an app names the atoms it composes; this pattern names none.

## Example

### Browser login — issue and validate

A user logs in through the app's sign-in. The credential check answers `verified(user_u91, cred_c01)`, and the app follows it with `issue(principal_ref: user_u91, credential_id: cred_c01, issued_by_ref: login_svc_l01, session_duration: 3600)` → `issued(dig_7e41c9, ses_5c20)`, with the host allocating the session token `tok_abc123` and injecting its digest, `dig_7e41c9`, the session id `ses_5c20` and `now: 2026-09-01T10:00:00Z` at the seam. The record lands in [Active] keyed by `dig_7e41c9` and carrying `ses_5c20`, with `issued_at: 10:00:00Z` and `expires_at: 11:00:00Z`. The host delivers `tok_abc123` to the browser as a session cookie (Capability requirement 13); no record holds it.

Twenty minutes later the user requests a protected page with the cookie. The host computes the digest of `tok_abc123` at the seam: `validate(dig_7e41c9)` → `valid(principal_ref: user_u91, expires_at: 11:00:00Z)`, with `now: 10:20:00Z` injected. The atom finds the record, reads stored active, finds now short of the deadline, and answers. Nothing changes.

### Logout — revoke

The user clicks log out. `revoke(dig_7e41c9, revoked_by_ref: user_u91, reason: "user-initiated-logout")` → revoked, with `now: 10:45:00Z` injected. The record moves to [Revoked] with all three fields stamped. expiry instant stays `11:00:00Z` — that field is immutable.

If the browser re-presents the old cookie at `10:50:00Z`: `validate(dig_7e41c9)` → `invalid(revoked)`. The stored status is read first, so the answer is [Invalid Revoked] and not [Invalid Expired], even though the session would have lapsed naturally at `11:00:00Z`, ten minutes later (Operation 15).

### The credential is revoked — every session on it ends

Later that day `cred_c01` turns up in a breach dump and an administrator revokes it. In the revoking action's transaction the app calls `revoke_sessions_for_credential(cred_c01)` → ok, with `now: 14:00:00Z` injected (Bonds Key 3). Two sessions carry `cred_c01`: `dig_9a10f3`, stored active and live, and `dig_44b2e0`, stored active but lapsed at noon. Both stand in [Revoked] carrying `revoked_at: 14:00:00Z` and no revoked by reference or revocation reason (Operation 68 through 71). `dig_7e41c9`, revoked at logout, keeps its three fields (Operation 72). A second call with `cred_c01` finds no active session and writes nothing (Operation 74).

### A window lapses — derived

The user closes the browser without logging out. The window passes at `11:00:00Z`. **No call is made and no write occurs** — there is no action to call. At `11:30:00Z` a new tab presents the same cookie: `validate(dig_7e41c9)` → `invalid(expired)`. The record is still stored active, never transitioned; the answer comes from expiry instant against the injected now. Nothing is written, there is no expiry timestamp to write, and the record count is unchanged. A [Read] of the record now reports `effective_status: expired` (Expiry 2 through 5, Operation 16, Operation 38, Invariant 12.3).

### Rejection paths

`issue(principal_ref: svc_s03, credential_id: cred_c07, issued_by_ref: api_gateway_g01, session_duration: 0)` → invalid-request. A zero-length window is not an operating state (Operation 8).

`revoke(dig_7e41c9, revoked_by_ref: admin_a01, reason: "incident-response")` against an already-revoked session → already-terminal. The existing [Revocation Reason] is unchanged (Operation 23). A session that has merely *lapsed* is not a stored terminal, so the same call against a lapsed-but-unrevoked session succeeds and records the attribution (Operation 27).

A forged cookie, `tok_forged_xyz`, digested at the seam: `validate(dig_0b52aa)` → `invalid(not-known)`. No record for the digest — structurally distinct from [Invalid Revoked], because nothing was revoked and nothing exists (Operation 14, Invariant 6.1).

### Regulated adversarial scenarios

- **Regulator audit.** A HIPAA (Health Insurance Portability and Accountability Act) auditor asks whether access to a patient record at `14:32Z` on `2026-10-15` was under a valid, unrevoked session. The database yields the session keyed by `dig_7e41c9`: stored active, `issued_at: 14:00:00Z`, `expires_at: 15:00:00Z`, no revocation instant. Invariant 3.1 is the structural answer — at `14:32Z` the session was stored active and the deadline had not passed, so [Validate] would have answered [Valid]. The auditor confirms it provably, from the one record; there is no stored expiry flag to corroborate, only the immutable deadline (Check 3.1).
- **Disputed access.** A user denies access at `03:15Z` on `2026-11-20`. The investigator reconstructs the sessions in force for the principal at that instant from the records and finds the session keyed by `dig_7e41c9`: `issued_at: 2026-11-19T22:00:00Z`, `expires_at: 2026-11-20T06:00:00Z`, `issued_by_ref: login_svc_l01`. The session was in force. Whether the token was stolen is a separate investigation; what the records bound is the forensic window — issued through the Login service at 22:00Z, valid at 03:15Z, never revoked before the access. Who authenticated at 22:00Z and against what credential is [Actor Identity](./actor-identity.md)'s record, wired by Login (Non-goal 1, Composition note 3).
- **Breach investigation.** Session tokens are found in an exposed log file. The investigator reads every session with `issued_by_ref: api_gateway_g01` and keeps those whose issuance instant falls inside the exposure window — 47 sessions across 31 principals — then reads each effective status against the investigation clock: which are live, which lapsed, which were already revoked. [Read] answers no session token digest (Operation 52), so the team takes the tokens from the exposed log itself, the host computes the digest of each at the seam, and the team calls [Revoke] with each digest, *including the lapsed ones*, so that every closure is attributed (Operation 27); a token whose session was already revoked answers already-terminal and changes nothing (Operation 23). Invariant 8.1 through 8.3 is what makes it provable, six months later, which sessions were closed, by whom, when and why.

## Source

- **NIST (National Institute of Standards and Technology — US federal standards body) SP (Special Publication) 800-63B section 7 (Session Management)** — the primary standard for session management in authentication systems. Its session duration and session termination requirements correspond directly to this atom's behavioral commitments; its session binding and reauthentication triggers are the composing pattern's (Non-goal 10, Composition note 5, Composition note 7). The atom's [Expiry Instant] immutability and re-issuance discipline implement 800-63B's requirement that session extensions produce new session identifiers.
- **OWASP ASVS V3 (Application Security Verification Standard — Session Management)** — the OWASP (Open Worldwide Application Security Project) verification standard for session management security. Requirements for session token randomness, expiry, revocation on logout, and protection against fixation attacks are the deployment-configuration surface of this atom.
- **RFC (Request for Comments — the Internet's numbered standards series) 6265 (HTTP State Management Mechanism — HTTP being the Hypertext Transfer Protocol)** — the cookie standard. The [Session Token] the host delivers is the value of a `Set-Cookie` response header in browser-based deployments; the atom's records carry only its digest. The atom does not specify cookie attributes (Secure, HttpOnly, SameSite) — those are the composing pattern's configuration obligations.
- **SAML 2.0 section 4.1.4 (Session Establishment and Termination)** — the SAML (Security Assertion Markup Language — an XML (Extensible Markup Language) standard for exchanging authentication data between identity and service providers) session model maps to this atom: `AuthnStatement` issuance corresponds to [Issue]; `SessionNotOnOrAfter` corresponds to [Expiry Instant]; `SLO` (Single Logout) corresponds to [Revoke]. The atom's re-issuance discipline aligns with SAML's prohibition on reusing assertion IDs.
- **RFC 6819 (OAuth 2.0 Threat Model and Security Considerations — OAuth being Open Authorization, the web's delegated-authorization framework)** — identifies session-related threats (token theft, session fixation, CSRF — Cross-Site Request Forgery) that the deployment-configuration layer of this atom addresses. The atom's immutability and revocation invariants mitigate token theft's blast radius: a stolen token is bounded by [Expiry Instant] and can be revoked.
- **OIDC Session Management 1.0 (OpenID Connect Session Management)** — the OpenID Connect (OIDC — an identity layer built on OAuth 2.0) session management specification. The [Session Token] corresponds to an OIDC session's identifier; [Revoke] corresponds to OIDC's Front-Channel and Back-Channel Logout protocols, and natural lapse (the derived [Expired]) corresponds to a session reaching its `SessionNotOnOrAfter` bound without an explicit logout.
- **HIPAA section 164.312(a)(2)(iii) (Automatic Logoff)** — the HIPAA automatic logoff requirement: electronic information systems must terminate after a period of inactivity. The atom's [Expiry Instant] field is the structural mechanism for this requirement; the composing deployment configures the timeout.
- **PCI DSS (Payment Card Industry Data Security Standard — the card networks' mandatory security rules for cardholder data) Requirement 8.6 (Session Management)** — session timeout and re-authentication requirements for payment systems. The atom's [Expiry Instant] immutability and re-issuance discipline satisfy the structural portion of these requirements.

Inherited from:

- **Daniel Jackson, *The Essence of Software*** — the freestanding-atom posture; the discipline of keeping credential verification, session persistence, permission checking, and logout propagation as separate composable atoms rather than absorbing them here.
- **IETF (Internet Engineering Task Force) RFC 4120 (Kerberos)** — Kerberos tickets are the canonical precedent for time-bounded, revocable authentication session records. The atom's immutable [Expiry Instant], single-stored-terminal ([Revoked]) state machine with a derived-[Expired] read projection, and revocation attribution discipline are the structured-natural-language expression of Kerberos' core concepts — a Kerberos ticket's lifetime likewise lapses by the clock against its end-time without a status write, while explicit invalidation is the recorded act.

## Proof

### Generation acceptance

This atom's acceptance is provable: an external auditor clears it from the session records, with their committed versions (Execution Contract Generation acceptance 1), and the read-time clock the [Validate] and [Read] surfaces use.

#### Conformance checks

```
Check 1.1: An auditor MUST find an expiry instant on EVERY session (Invariant 10.1).
Check 1.2: An auditor MUST find one session token digest, session id, principal reference, credential id, issued by reference, issuance instant and expiry instant per session across the session's whole life (Invariant 1.1, Invariant 1.2, Invariant 2.1; Execution Contract Generation acceptance 1).
Check 1.3: An auditor MUST find no session whose issuance instant DOES NOT PRECEDE the session's expiry instant (Operation 8, Operation 10, Operation 56).
Check 2.1: An auditor MUST find no stored expired status on any session (Invariant 12.1).
Check 2.2: An auditor MUST find no expiry time stamp beside expiry instant (Invariant 12.2).
Check 2.3: An auditor MUST find no session with two committed versions whose status EQUALS active (Invariant 12.3; Execution Contract Generation acceptance 1).
Check 2.4: An auditor MUST reproduce the effective status from the stored status, expiry instant and the read-time clock (Invariant 12.4).
Check 3.1: An auditor MUST reconstruct the sessions in force at a past instant from issuance instant, expiry instant and revocation instant (Invariant 3.1, Expiry 5).
Check 4.1: An auditor MUST find a revocation instant on EVERY revoked session (Invariant 8.1).
Check 4.2: IF a revoked session carries a revoked by reference OR a revocation reason THEN an auditor MUST find on the session a revoked by reference that DOES NOT EQUAL blank AND a revocation reason that DOES NOT EQUAL blank (Invariant 8.2, Invariant 8.3, State 17).
Check 6.1: An auditor MUST find no session leaving revoked across two committed versions of the session (Invariant 5.1; Execution Contract Generation acceptance 1).
Check 7.1: An auditor MUST find no two sessions sharing a session id (Invariant 7.3, State 15).
```

NOTE: EVERY check names the rule the check tests.

Term committed version: a record as it stood at the commit that wrote it, as Execution Contract Generation acceptance 1 declares it.

#### External checks

```
External check 1: A deployment needing a session token's random material confirmed drawn from a cryptographically secure random source at the token entropy MUST read the deployment's own token generation (Identity 9, Capability requirement 3, Capability requirement 4).
External check 2: A deployment needing the four validate answers confirmed distinguishable MUST read the implementation's contract (Invariant 6.1, Invariant 6.2).
```

### Vocabulary

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is* and its **Kind**.

Term actors: the atom; the host; the transition; the implementation; the deployment; a composing pattern (also: a pattern); a business caller; a caller; a guard; a principal; an auditor; the database; a session; a status; a lapse; a liveness query; a rejection; a write; an action; a string input; an opaque reference; the session count; the session token's random material.

Term records: session — one bounded-lifetime attestation, carrying session token digest, session id, principal reference (an actor id), credential id, issued by reference, issuance instant, expiry instant, status and, once cancelled, revocation instant and, where [Revoke] cancelled it, revoked by reference and revocation reason.

Term record verbs: identify, serve, offer, compare, allocate, reuse, change, carry, share, draw, interpret, confirm, configure, supply, generate, fall, own, hold, record, stand, answer, apply, accept, stamp, recompute, derive, surface, write, fire, schedule, read, refuse, leave, rest, remove, merge, return, find, reproduce, reconstruct, verify, sequence, decide, extend, call, revoke, bind, check, bound, enforce, propagate, define, enumerate, seal, compose, trim, normalize, case-fold, set, differ, give, reduce, detect, reconcile, declare, deliver, authorize, take, ask.

Term value sets: status = active | revoked.

Term bounds: token entropy (the floor a session token's random material is drawn from); default session duration (the window [Issue] applies where the call supplies none); zero duration (the floor a session duration must exceed); maximum length (the cap per string input in Unicode code points, counted as the call supplies the value, 1,024 where a deployment declares none; a filter's value on principal reference or issued by reference takes the cap of that field's string input).

NOTE: watch the cap's measure (Term bounds).

Term cadences: empty.

Term qualifiers: migrated — rewritten in GRACE lang v0.35 (2026-09-12).

Term terms: session, session token, session token digest, principal reference, credential id, issued by reference, seam, transition, default session duration, token entropy, now, business caller, session duration, window length, zero duration, issuance instant, expiry deadline, expiry instant, lapsed, effective status, revocation instant, revoked by reference, revocation reason, reason, filter, liveness query, status, maximum length, validation failure, verified answer, invalid answer, authentication credential, claim set token, committed version.

Term cited: actor id, session id, credential id: Declarations.

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a [Term] marker to its term entry heading above (kramdown
     auto-generates the heading anchors on GitHub Pages). Standard CommonMark /
     kramdown; no plugin required. -->

[Session]: #session
[Issue]: #issue
[Validate]: #validate
[Revoke]: #revoke
[Revoke Sessions For Credential]: #revoke-sessions-for-credential
[Read]: #read
[Read Session]: #read-session
[Session Token]: #session-token
[Session Token Digest]: #session-token-digest
[Session Id]: #session-id
[Principal Reference]: #principal-reference
[Credential Id]: #credential-id
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
[Issued]: #issued
[Valid]: #valid
[Invalid Expired]: #invalid-expired
[Invalid Revoked]: #invalid-revoked
[Not Known]: #not-known
[Invalid Request]: #invalid-request
[Already Terminal]: #already-terminal
[Storage Failure]: #storage-failure

## Status

`doing` — see the Ledger.

<details markdown="block">
<summary>
    <h2 id="ledger" style="display: inline-block; margin-left: 1.5rem;">Ledger</h2>
</summary>

```
status: doing
formal: verified — session.als + 17 twins (the static data model: State 1, 2 and 4 through 7, Identity 1, Invariant 7.1, 8.1 through 8.3, 10.1, 12.1 and 12.2, Check 1.3, Operation 4, 5, 10 and 58 checked on every version an ordered sequence of admitted calls leaves); session.tla + 14 twins (across steps, while the clock moves: Invariant 1.1, 2.1, 3.1, 3.3, 4.1, 5.1, 6.1, 7.2, 9.2, 11.1, 12.3 and 12.4, Operation 20, 27 and 39, Concurrency 4, with Invariant 1.2 and 9.1, State 10 and 11, Identity 5 and 6 checked through them); the vote no of 2026-06-03 superseded by the maintainer's ruling of 2026-11-09 (both models; only the writing vetoes one), and neither vetoed; Invariant 6.2 cannot be stated (External check 2); owed rows: Operation 52; Operation 37, 53 and 61, 2026-11-11; both re-derived over the session token digest, 2026-11-21; model redraw deferred to Lean: session.als and session.tla, State 4, State 16, State 17, Invariant 1.1, Invariant 8.2, Invariant 8.3, Operation 66 through 75, 2026-11-28
last gate: 2026-11-28 — Final Critique 33, a delta round (diff base bf3c98b8, 3 labels: Operation 60, Check 1.2 and Check 4.1, with the Read Session case table Final Critique 32 added), one reader (Linus opencode-go/beam-free; GRID and EOS not run; the Claude reader off), frozen at 136c1460 — foundational count 1 after the blind second triage, cured, not clean, no sample; Linus reported none (its answer that [Revoke] is the only path into revoked missed [Revoke Sessions For Credential], Operation 68), and the blind second triage (Opus 5.5) placed Check 4.1's second clause foundational A: "a revoked by reference ... on EVERY session [Revoke] stood in revoked" names a set the records do not mark (a session [Revoke Sessions For Credential] revoked carries the revocation instant alone, State 17, and a [Revoke] that dropped both fields leaves the same record), so two auditors compile it to two queries (Execution Contract Generation acceptance 1: a check compiles to a read query an external auditor can run); cured by writing the check in record terms, Check 4.1 the revocation instant on every revoked session (Invariant 8.1) and new Check 4.2 either field present obliging both non-blank (Invariant 8.2, Invariant 8.3, State 17); what a read query cannot see, a [Revoke] that records neither field, stays owned by State 4, Operation 30 and Operation 31; refining, cured: Check 1.2 names the session id beside the other fields and cites Invariant 1.2, which makes the session id immutable; rhetorical, cured with the restating sentence: the [Read] case table's "revocation fields once revoked" reads as Operation 60; the delta round that reads the cures comes next; 2026-11-28 — Final Critique 32, a delta round (diff base 431dc37f, 89 labels, the reach of the String policy tombstones, the Login dissolve and the key offers' existence reads), one reader (Linus opencode/beam-free; GRID and EOS not run; the Claude reader off), frozen at bf3c98b8 — foundational count 1, cured, not clean, no sample: Check 4.1 demanded a revoked by reference and a revocation reason on EVERY revoked session, though [Revoke Sessions For Credential] records the revocation instant alone (State 17, Operation 70, Operation 71), so a session the credential cascade revoked failed the audit that Invariant 8.2 and Invariant 8.3 scope to [Revoke]'s sessions; cured by scoping the two fields to every session [Revoke] stood in revoked, and Operation 60's restatement for [Read] cured the same way by the settle itself; refining: Check 1.2 omitted the session token digest and the credential id that Invariant 1.1 holds immutable, added; 2026-11-27 — Final Critique 31, a delta round (diff base 88366445, 17 labels, the reach of Final Critique 30's settle, the grammar batch and the String policy tombstones), one reader (Linus opencode-go/beam-free; GRID and EOS not run), frozen at 431dc37f — foundational count 0 after the blind second triage, clean, one sample (Linus claimed two foundational findings and the triages placed both refuted: that Term filter lists "a field other than principal reference and issued by reference" among the shapes a [Filter] names while requiring none, though the first clause only lists the shapes a caller can send, a term entry carries no obligation, and Operation 61 answers no session for such a filter, as the Filter entry and the Read case table say; and that Operation 65 leaves a default session duration that is absent, zero or negative without a refusal, though Operation 48 refuses a blank default and Operation 56 one that does not exceed the zero duration, and the rejection line agrees; the blind second triage, one cold reader on Opus 5.5, found one refining inconsistency of its own, that Term default session duration still named only absence and a value that does not exceed the zero duration as a misconfiguration after Operation 65 added the value that is no window length, cured by adding it and citing Operation 65, a term entry that changes no rule); 2026-11-25 — Final Critique 30, a delta round (diff base 7748eafc, 4 labels reached: Operation 3, 57, 64 and 65, the settle of Final Critique 29), one reader (Linus opencode-go/beam-free; GRID and EOS not run), frozen at 88366445 — foundational count 0 after the blind second triage, clean, one sample (Linus's report counted 2 foundational, 3 refining and 1 rhetorical; both its foundational findings were placed no defect and refining by both triages: Operation 64 cites Execution Contract Read 5 as the default its own order stands in place of, and Read 5 says a specification that names its own order keeps it, as Favorite, Communication, Tenure and Reaction cite it; Operation 65's citation of Execution Contract Input 1 reached a setting that Input 1 does not, so Operation 65 and Invalid Request now say the default is no window length, the page's own Term, and no build differed; refining not cured: that the default's validity gates every [Issue] call, which Term default session duration states, and Operation 57's malformed Reason, which Execution Contract Input 1 and Input 3 define; one rhetorical, the happy-path-only example, declined, since Rejection paths holds the refusals)

open: none
```

</details>

<details markdown="block">
<summary>
    <h2 id="decisions" style="display: inline-block; margin-left: 1.5rem;">Decisions</h2>
</summary>

Decisions are kept in [the pattern's history](./session.hist.md#decisions), one dated entry for each turn the pattern took; everything smaller lives in the commit that made it: `git log -- atoms/session.md`.

</details>

NOTE: End of Session.
