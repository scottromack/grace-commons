---
title: Login
parent: Conceptual Compositions
nav_order: 13
has_toc: true
toc: true
---

# Login

<details markdown="block">
<summary>Table of contents</summary>
{: .text-delta }
1. TOC
{:toc}
</details>

## Summary

Login wires together the full lifecycle of logging in: checking the presented credential, issuing a time-limited session on success, logging out, and — crucially — cancelling every session that came from a credential when that credential is revoked. It combines three patterns: one that verifies credentials (Credential), one that issues and tracks time-limited sessions (Session), and the tamper-evident audit record that spans all of it (Audit Trail).

Its central guarantee is that a session can never be issued without a successful credential check first — the wiring makes it structurally impossible, and an auditor can confirm it from the records because every issued session is named by a login-family audit event: login_succeeded on the clean path, or login_map_write_failure on the map-degradation arm, each recorded before the call returns or retried until it lands — and a session that outran every record (a crash inside the issuing call) is found by the issuance-reconciliation sweep — once it is older than the deployment's declared login-completion bound, so a login still in flight is never mistaken for a dead one — and revoked with a record, unusable anyway since the dying call returned its token to no one. Its second guarantee is cascade completeness: when a credential is revoked, every still-active session derived from it is cancelled before the operation returns, leaving none behind.

Every login attempt (success or failure), every logout, and every cascaded revocation is recorded, so an investigator can answer from the records alone which credentials established which sessions, whether a session rested on a valid credential, and when and by whom sessions were revoked. The cascade is the load-bearing guarantee that appears only when the three patterns are combined — it belongs to none of them alone — and it is what lets higher-level patterns reliably cut off access the moment a credential is pulled.

---

## Intent

Every system that authenticates principals eventually faces the same composability problem: credential verification is a momentary check, session management is a bounded persistence concept, and audit recording is a regulated obligation — and none of the three atoms can see the other two. Credential answers *"does this material match what was registered?"* and returns immediately. Session issues a time-bounded token but makes no authentication judgment — it issues a session for whatever principal it is given, trusting entirely that the caller verified authentication first. Audit Trail records events but knows nothing about the semantics of the events it records. The question of *what should happen at the boundary where these three concepts meet* — how the transition from credential verification to session issuance should be wired, what should be recorded and when, and especially what should happen to open sessions when a credential is revoked — belongs to no single atom. It belongs to the composition.

Login is that composition. It provides three services: the login action wires `Credential.verify → Session.issue` in the correct order, with every login attempt (successful or failed) recorded in the Audit Trail before returning. The logout action wires `Session.revoke` with attribution and Audit Trail recording. And [Revoke Sessions For Credential] provides the cascade: when a Credential is revoked — whether by the credential owner, an administrator, or an automated compromise-response process — every Session derived from that Credential is revoked in the same operation, and the full cascade is recorded.

The cascade is load-bearing for downstream compositions. Privileged Access Provisioning's `exercise_access` action depends on Session validity as its first guard: a session invalidated by credential revocation will block all subsequent `exercise_access` calls for any Capability issued to that principal's sessions. The cascade path is: `Credential.revoke` (outside this composition's surface) → caller invokes [Revoke Sessions For Credential] → Login walks `credential_to_sessions[credential_id]` → `Session.revoke` for each Active session → Audit Trail records each revocation → Privileged Access Provisioning's session check thereafter returns `session-invalid`. The Login composition is the mechanism that makes this arc visible and traceable from records alone.

This composition does not implement multi-factor authentication (MFA — requiring two or more independent proofs of identity), account lockout, rate limiting, or session renewal. It implements the minimal correct wiring of three atoms for the common authenticated-session case — the pattern that every other authentication-adjacent composition either calls or depends on.

---

## Composes

- **[Credential](../atoms/credential.md)** — the verification surface.
- **[Session](../atoms/session.md)** — the time-bounded session record.
- **[Audit Trail](./audit-trail.md)** — the regulated-audit substrate.

```
Composes 1: EXACTLY ONE Credential instance MUST serve the composition.
Composes 2: EXACTLY ONE Session instance MUST serve the composition.
Composes 3: EXACTLY ONE Audit Trail instance MUST serve the composition.
Composes 4: The composition MUST NOT change a constituent's spec.
Composes 5: The composition MUST inherit a constituent's invariants PER the section titled Conformance in `execution-contract.md`.
Composes 6: The composition MUST read Audit Trail as a substrate PER the section titled Substrate composition invocation in `execution-contract.md`.
Composes 7: The composition MUST NOT hold an instance of a constituent Audit Trail reaches.
Composes 8: The composition MUST NOT call Credential's register.
Composes 9: The composition MUST NOT call Credential's rotate.
Composes 10: The composition MUST NOT call Credential's revoke.
Composes 11: The composition MUST NOT offer Session's validate on the composition's surface.
Composes 12: The composition MUST attest EVERY audit event under the composition's own service identity.
Composes 13: The composition MUST carry a human party in an audit event's data.
Composes 14: The composition MUST NOT attest an audit event under a caller's credential.
Composes 15: The composition MUST read the substrate's events by an open-ended sequence range.
Composes 16: The composition MUST select an event in the composition's own code.
Composes 17: The composition MUST NOT query the substrate by a payload predicate.
```

Term composition: this pattern's wiring of [Credential](../atoms/credential.md), [Session](../atoms/session.md) and the [Audit Trail](./audit-trail.md) substrate — the issuance gate, the revocation cascade, the two maps and the sweep.

Term constituents: [Credential](../atoms/credential.md), [Session](../atoms/session.md), [Audit Trail](./audit-trail.md).

Term service identity: the composition's own registered actor and credential — a service identity; the attested emitter of every audit event this composition writes.

WHY:
Composes 6 and Composes 7 are the corpus's first migrated use of a **composition as a constituent**. [Audit Trail](./audit-trail.md) is a substrate, not an atom, so Event Log, Actor Identity, Retention Window and Tamper Evidence are reached *through* it and this composition holds no instance of any of them — which the section titled Substrate composition invocation in `execution-contract.md` is what makes legitimate rather than a topology accident.

Composes 12 through 14 are the attestation decision and it is forced rather than chosen. Login's callers are end principals whose presented material is the very thing under test — a failed login's principal has no attestable credential at all — so the only honest attestation surface for every event this composition writes is its own registered identity, with the human parties carried as data.

Composes 15 through 17 declare the read capability exactly. The substrate passes a sequence-range read through to its Event Log unchanged; every selection is enumerate-and-filter in composition code, which is the move the substrate itself uses for its own rebuilds. A payload-predicate *query* is the forthcoming Reverse Index pattern's shape, and a deployment may compose one over the trail as an instance optimization without changing this contract.

---

## Composition logic

### Composition state

```
Composition state 1: The composition MUST store a credential-to-sessions map.
Composition state 2: The composition MUST store the strict inverse of the credential-to-sessions map.
Composition state 3: The composition MUST write both maps under one transaction.
Composition state 4: The composition MUST NOT remove a session_token from the credential-to-sessions map.
Composition state 5: The composition MUST NOT change a session-to-credential entry.
Composition state 6: The composition MUST key the credential-to-sessions map by credential_id.
Composition state 7: The composition MUST rebuild a map from the substrate's login-family events.
Composition state 8: The composition MUST NOT rest a session's validity on a map write.
Composition state 9: The composition MUST store a login event log.
Composition state 10: The composition MUST append a login event log entry per login call reaching an outcome.
Composition state 11: The composition MUST hold the login event log durable across a restart.
Composition state 12: The composition MUST NOT rebuild the login event log at a restart.
```

Term credential-to-sessions map: the composition's own map from a credential_id to the session tokens issued under it — a credential to sessions map; the cascade's root index.

Term login event log: the composition's own append-only record of every login call, successful or refused — a login event log.

Term login-family events: the substrate's login_succeeded, login_map_write_failure and login_failed events.

**Contract classification: two derived indexes and one extraction-pending element** (the section titled Composition state in [`execution-contract.md`](../execution-contract.md)).

- The two **maps** are a *derived index*, and the pairing fact lives in a constituent: every issued session's `(credential_id, session_token)` pair is immutable audit content, written into the login_succeeded event's data and, on the map-write failure arm, into a login_map_write_failure event. *Rebuild procedure:* enumerate the substrate through the declared read, select the login-family events, and group each data's session_token by its credential_id. **Bound on the rebuild's totality, stated rather than assumed:** the traversal reads event payloads the substrate destroys at its retention horizon, so the rebuild is total only within that horizon — and the readers need it total for one session lifetime, not for the life of the credential, which the WHY below works out. A login_map_write_failure event names a pair the live map lacks, so the rebuild reconstructs exactly the backfill Invariant 2.4's remediation prescribes — rebuild-on-miss **is** the remediation path.
- The **login event log** is *extraction-pending, against [Event Log](../atoms/event-log.md)*, with a durability obligation now rather than later. The Contract's record-coordination rule says a composition that must record that its own calls occurred composes Event Log rather than growing a bespoke store, and that is the extraction pending here: a second Event Log instance for the login-attempt journal, at which point the entries become that instance's events and the classification question dissolves.

WHY:
The maps' rebuild is bounded by the substrate's horizon, and **the bound is comfortably longer than anything that reads it** — which is the finding rather than a reason to skip stating it. The traversal reads login_succeeded payloads, which the substrate destroys entirely at the horizon, `action_ref` included. What matters is which pairs a reader actually needs: the cascade skips every non-Active session, so the only pairs whose recovery can change an outcome are those whose sessions are still Active, and an Active session is by construction within its own duration. The rebuild therefore has to remain valid for **one session lifetime**, not for the life of the credential or the trail — hours or days against an audit horizon of years.

Stating that comparison is not ceremony; it is what separates this map from the same shape elsewhere in the corpus where it is a live defect. Where a claim can outlive the evidence it reads, a spec owes a declared ordering and a check. Here the claim cannot, because the reader discards exactly the entries whose evidence would have expired. A deployment configuring an audit horizon shorter than its own session duration would invert that — a configuration no regulated deployment reaches by accident, and one this ordering makes visible if it ever did.

Composition state 11 and Composition state 12 are the durability obligation stated rather than softened. An entry whose mirrored audit event has not yet landed **is** the durable intent for that record — the payload the sweep's re-emission is built from. An implementation holding the log in memory, or rebuilding it from the trail at restart on the theory that it is a cache, discards exactly that intent and turns a delivered session into one the sweep's second comparison kills. An earlier draft called this *a conditional derived index with a truth-bearing window*, which named the fact and dodged the classification.

With failed-login auditing enabled — the default and the regulated posture — every entry mirrors a substrate event and the log reads as a derived index over the login family. With the knob disabled, the failed-attempt entries carry truth no constituent holds. The same classification and the same durability obligation cover both: the store is durable as a whole, or the sweep's premises fail.

### Capability requirement

```
Capability requirement 1: The deployment MUST supply now at the seam.
Deleted: Capability requirement 2. Execution Contract Logic confinement 3 owns it.
Deleted: Capability requirement 3. Execution Contract Logic confinement 3 owns it.
Capability requirement 4: The composition MUST NOT mint an id.
Capability requirement 5: The composition MUST NOT generate cryptographic material.
Capability requirement 6: A deployment MUST set the default session duration.
Capability requirement 7: A deployment MUST configure the substrate instance with a retention policy.
Capability requirement 8: A deployment MUST provision the service identity as a registered actor.
Capability requirement 9: A deployment MUST rotate the service identity's credential.
Capability requirement 10: A deployment MUST declare the issuer refs.
Capability requirement 11: A deployment MUST set the reconciliation window.
Capability requirement 12: A deployment MUST set the reconciliation cadence.
Capability requirement 13: The reconciliation cadence MUST NOT EXCEED the reconciliation window.
Capability requirement 14: A deployment MUST set the login completion bound.
Capability requirement 15: A deployment MUST set whether a failed login reaches the substrate.
```

Term seam: the composition's I/O boundary as the section titled Logic Confinement Principle in `execution-contract.md` declares it; the host injects one clock reading here.
Term now: the wall-time reading the host takes at the seam and hands to the transition, as the section titled Logic Confinement Principle in `execution-contract.md` declares it; never read inside the transition, never supplied by the business caller.

Term transition: the composition's evaluation of one call against the constituents, as the section titled Logic Confinement Principle in `execution-contract.md` declares it.

Term issuer refs: the issued_by_ref values the deployment's calling layers pass into login — the scope of every sweep comparison against the session store.

Term login completion bound: the deployment's declared maximum duration between a session issuing and the login event log entry landing — also the bound between a cascade's initiation and its completion.

WHY:
The clock reading serves exactly one purpose at this layer: stamping the login event log entry, one reading per invocation whichever arm writes it. **No guard here is time-gated.** Input validation, the verify gate and the cascade's active check are state- and outcome-valued; session expiry is [Session](../atoms/session.md)'s own temporal rule evaluated against the reading injected at *that* constituent's seam. Two seams, two readings, never claimed equal.

Capability requirement 14 is the one a deployment can set wrong in both directions. The sweep examines only sessions older than the bound, because a younger one may belong to a login still in flight and revoking it would hand that login a dead token to return; set too short it kills live logins, set too long it delays the sweep's closure of a genuine crash. The deployment picks it from its own latency envelope and states it.

Capability requirement 13 exists because a cadence longer than the window makes the window unmeetable — a discrepancy could not be surfaced in time to close inside it.

### Primitive policy

```
Primitive policy 1: The composition MUST answer invalid-request for a blank principal_ref.
Primitive policy 2: The composition MUST answer invalid-request for a blank credential_type.
Primitive policy 3: The composition MUST answer invalid-request for a blank presented_material.
Primitive policy 4: The composition MUST answer invalid-request for a blank session_token.
Primitive policy 5: The composition MUST answer invalid-request for a session_duration the deployment did not set AND the caller did not supply.
Primitive policy 6: The composition MUST compare an opaque input byte-exact.
Primitive policy 7: The composition MUST NOT normalize an opaque input.
Primitive policy 8: The composition MUST NOT persist a presented_material.
Primitive policy 9: The composition MUST NOT answer a presented_material.
```


Term opaque input: principal_ref | credential_type | session_token | credential_id.

WHY:
Primitive policy 8 and Primitive policy 9 inherit [Credential](../atoms/credential.md)'s consumed-never-stored discipline and restate it here only because this composition **holds** the material briefly on its way to `verify`. The constituent's guarantee is about the constituent's store; this rule is about the composition's own hands.

### Audit arm

```
Audit arm 1: The composition MUST retry a recording-failure.
Audit arm 2: The composition MUST NOT retry a landed record.
Audit arm 3: The composition MUST derive an owed record again at a restart.
Audit arm 4: The composition MUST read an invalid-credential answer as a deployment fault.
Audit arm 5: The composition MUST alert on an invalid-credential answer.
Audit arm 6: The composition MUST read an invalid-request answer as a deployment fault.
Audit arm 7: The composition MUST NOT read an invalid-request answer as unreachable.
Audit arm 8: The composition MUST NOT retry an invalid-request answer in a loop.
Audit arm 9: The composition MUST read a retention-sourced invalid-request as a record already landed.
Audit arm 10: The composition MUST read a cap-sourced invalid-request as a record still owed.
```

WHY:
One arm rule for every `record_action` this composition makes, stated once here and cited at each site, because a site that claimed an arm unreachable would be wrong about this substrate. `recording-failure` is the transient arm — owed, retried, re-derived by the sweep if the process dies first. `invalid-credential` is the composition's own credential being bad, which is a deployment fault rather than a caller outcome.

invalid-request is the arm a reader most wants to call unreachable and cannot. The substrate raises it not only for an over-cap payload — which the boundary predicate forecloses for validated inputs — but for its own retention-configuration faults and for an Event Log cap disagreement, neither of which any caller input controls. **Its two sources land differently and the sweep must tell them apart** (Audit arm 9, Audit arm 10): on the retention source the event is *already appended and attested*, because the substrate places retention after the append, so nothing is owed and the unretained event is the substrate's own reconciliation's; on the cap source nothing was appended, the record stays owed, and it lands once the deployment corrects the cap.

### Action wiring

```
login(principal_ref, credential_type, presented_material, issued_by_ref, optional session_duration)
  answers login result
  refuses invalid-request | credential-invalid | storage-failure(stage)

logout(session_token, revoked_by_ref, reason)
  answers ok
  refuses invalid-request | not-found

revoke_sessions_for_credential(credential_id, revoked_by_ref, reason)
  answers revocation tally
  refuses invalid-request
```

Term login result: session_token and expires_at — what login answers.

Term revocation tally: revoked, skipped and failed — what revoke_sessions_for_credential answers.

```
Action wiring 1: An admitted login MUST call Credential's verify with the principal_ref, the credential_type AND the presented_material.
Action wiring 2: IF Credential's verify answers failed-verification THEN an admitted login MUST answer credential-invalid.
Action wiring 3: An admitted login MUST NOT answer Credential's verify reason to the caller.
Action wiring 4: An admitted login MUST call Session's issue ONLY AFTER Credential's verify answers verified.
Action wiring 5: An admitted login MUST read the credential_id of the effective-active credential for the pair.
Action wiring 6: An admitted login MUST read the credential_id again ONLY AFTER Session's issue commits.
Action wiring 7: IF the two credential_id reads disagree THEN an admitted login MUST answer storage-failure naming the stage.
Action wiring 8: An admitted login MUST call Session's issue with the principal_ref, the issued_by_ref AND the session duration.
Action wiring 9: An admitted login MUST write both maps ONLY AFTER Session's issue commits.
Action wiring 10: IF the map write fails THEN an admitted login MUST answer the session_token.
Action wiring 11: IF the map write fails THEN an admitted login MUST record a map write failure event carrying the pair.
Action wiring 12: An admitted login MUST append a login event log entry.
Action wiring 13: An admitted login MUST record a login event under the service identity.
Action wiring 14: An admitted logout MUST call Session's revoke with the session_token, the revoked_by_ref AND the reason.
Action wiring 15: IF Session's revoke answers not-known THEN an admitted logout MUST answer not-found.
Action wiring 16: An admitted logout MUST record a logout event under the service identity.
Action wiring 17: An admitted cascade MUST read the cascade set ONLY AFTER recording a cascade initiation event.
Action wiring 18: An admitted cascade MUST read the cascade set as the union of the map entry AND the event-derived set.
Action wiring 19: An admitted cascade MUST call Session's validate for EVERY session_token the cascade set carries.
Action wiring 20: An admitted cascade MUST call Session's revoke for EVERY session_token Session's validate answers valid for.
Action wiring 21: An admitted cascade MUST NOT call Session's revoke for a session_token Session's validate answers invalid for.
Action wiring 22: An admitted cascade MUST count a skipped session_token.
Action wiring 23: An admitted cascade MUST record a session revoked event per revoked session_token.
Action wiring 24: An admitted cascade MUST NOT change the credential-to-sessions map.
Action wiring 25: An admitted cascade MUST record a cascade completion event naming the initiation.
Action wiring 26: An admitted cascade MUST answer the revoked count, the skipped count AND the failed count.
```

Term admitted login: a login call whose inputs cleared the boundary predicate.

Term admitted logout: a logout call whose inputs cleared the boundary predicate.

Term admitted cascade: a [Revoke Sessions For Credential] call whose inputs cleared the boundary predicate.

Term cascade set: the union of the credential-to-sessions map's entry for a credential_id and the event-derived set the substrate's login-family events carry for it.

WHY:
Action wiring 5 through 7 are the sandwich, and it exists because two reads of one credential store can straddle a rotation. The first read names the credential the verify gated on; the second confirms it is still the effective-active one after the session committed. A disagreement means the credential rotated mid-login, and the honest answer is a storage failure at the named stage rather than a session pinned to a credential that no longer gates it.

Action wiring 10 and Action wiring 11 are the map's subordination stated as rules. The session is real and is returned; the map write is an index write, so its failure costs a lookup and not a login. What keeps the cascade complete anyway is Action wiring 11's event: the pair lands in the trail, so the cascade's union read finds it even when the live map does not.

Action wiring 18 is why the cascade cannot silently shrink. Reading the map alone would miss exactly the pairs Action wiring 10's arm produced; reading the events alone would be slower and no more complete. The union is the gate input, and a lost map entry can never shrink it.

Action wiring 21 skips rather than revokes, and the reason is derivation rather than error avoidance. A lapsed session reads invalid by [Session](../atoms/session.md)'s derived-expiry projection — there is no expire action, no expiry write and no stored expired state anywhere — so a revoke over it would in fact commit and would record a revocation of something already dead.

### Wiring decision

```
Wiring decision 1: The composition MUST gate a session's issuance on Credential's verify answering verified.
Wiring decision 2: The composition MUST cascade a credential's revocation to the credential's sessions.
Wiring decision 3: The composition MUST NOT revoke a credential.
Wiring decision 4: The composition MUST NOT read a cascade as complete for a session the cascade set did not carry.
```

WHY:
The cascade is the composition's reason to exist and its direction is the opposite of [Authenticated Actor](./authenticated-actor.md)'s over the same [Credential](../atoms/credential.md) constituent. There, revocation closes a surface *forward* by gating each new attestation, because an attestation is an immutable past act with nothing to revoke. Here revocation reaches *backward* into live grants, because a session is a live grant and killing it is both possible and required. Same atom, same event, two cascades — and which one a composition owes is decided by whether the thing downstream is a record or a grant.

Wiring decision 3 keeps the two surfaces apart. This composition provides the downstream cascade and never the credential revocation itself, which belongs to the identity-management surface and arrives here as a call.

### Reconciliation

```
Reconciliation 1: The sweep MUST run at an instance's start.
Reconciliation 2: The sweep MUST run every reconciliation cadence.
Reconciliation 3: The sweep MUST NOT store a record of the sweep's own.
Reconciliation 4: The sweep MUST close a discrepancy through an ordinary record_action.
Reconciliation 5: The sweep MUST re-emit an owed record the login event log carries.
Reconciliation 6: The sweep MUST NOT examine a session whose issued instant is younger than the login completion bound.
Reconciliation 7: The sweep MUST NOT examine a session issued outside the issuer refs.
Reconciliation 8: The sweep MUST revoke a session no login-family event AND no login event log entry names.
Reconciliation 9: The sweep MUST record an orphan session revoked event for a session the sweep revokes.
Reconciliation 10: The sweep MUST record a revocation-family event for a revoked session carrying none.
Reconciliation 11: The sweep MUST NOT examine a cascade initiation younger than the login completion bound.
Reconciliation 12: The sweep MUST record a cascade abandoned event for an initiation carrying no completion.
Reconciliation 13: The sweep MUST escalate a discrepancy the reconciliation window did not close.
Reconciliation 14: The sweep MUST NOT examine an event the substrate's horizon EXCEEDS.
```

Term revocation-family event: logout_succeeded | session_revoked_by_cascade | orphan_session_revoked — the exact family a revoked session's record must belong to.

WHY:
The sweep is four comparisons and each closes a different partial. **Entry versus events** re-emits a record the log holds and the trail lacks — which is why the log's durability is a Composition state rule and not an implementation note, since the entry *is* the intent the re-emission is built from. **Sessions versus records** finds a session the constituent holds and neither the trail nor the log names: a login that died between issuing and recording, which is the one comparison that *revokes* rather than records, because a session nobody can attribute is a session nobody can audit. **Revocations versus events** finds the mirror case, a revoked session with no revocation-family event. **Initiations versus completions** finds a cascade that died mid-flight and abandons it explicitly rather than leaving an initiation open forever.

Reconciliation 6 and Reconciliation 11 are the same lower edge twice. A session or an initiation younger than the completion bound may belong to work still in flight, and acting on it would hand a live login a dead token or abandon a cascade that is still running.

Reconciliation 14 is the upper edge and it is not a knob of its own — it is the substrate's retention horizon, past which the events the sweep reads no longer exist to be read.

Reconciliation 3 is what keeps the sweep cheap to reason about: every comparison reads state already durable, and every closure is an ordinary composition-attributed record. The sweep grows no store, so two runs at once produce at worst two attempts at one closure.

---

## Composition-level invariants

Each emerges from the composition; none belongs to one constituent.

- **Invariant 1 — Credential gates issuance.**
  ```
  Invariant 1.1: EVERY session_token the session-to-credential map carries MUST follow Credential's verify answering verified.
  Invariant 1.2: The composition MUST NOT call Session's issue for a login Credential's verify refused.
  ```
- **Invariant 2 — Cascade completeness.**
  ```
  Invariant 2.1: EVERY session the cascade set carried AND Session's validate answered valid for MUST stand terminal at the cascade's return.
  Invariant 2.2: The composition MUST NOT read a cascade as covering a session the cascade set did not carry.
  Invariant 2.3: The cascade set MUST carry the union of the map's entry AND the event-derived set.
  Invariant 2.4: A lost map entry MUST NOT shrink the cascade set.
  ```
  WHY: the claim is snapshot-scoped on purpose. A session issued after the set was read is outside the cascade by construction, and a cascade that claimed otherwise would be promising to catch a login that had not happened when it looked.
- **Invariant 3 — Session-credential traceability.**
  ```
  Invariant 3.1: EVERY session-to-credential entry's credential_id MUST equal the credential_id the confirming read answered.
  ```
- **Invariant 4 — Login event log completeness.**
  ```
  Invariant 4.2: A login committing Session's issue AND carrying no login event log entry MUST stand as the sweep's to close.
  Deleted: Invariant 4.1. Composition state 10 owns it.
  ```
  WHY: the deleted invariant's one exception is Invariant 4.2, and it is named rather than hidden. The session exists and the entry does not, which is exactly the *sessions versus records* comparison's input — so the gap is a sweep obligation rather than a broken invariant.
- **Invariant 5 — Audit trail completeness.**
  ```
  Invariant 5.1: EVERY login succeeded event MUST name a session_token the session-to-credential map carries.
  Invariant 5.2: EVERY session revoked event MUST name a session_token the cascade found valid.
  ```
- **Invariant 6 — Map inverse consistency.**
  ```
  Invariant 6.1: The credential-to-sessions map AND the session-to-credential map MUST agree.
  ```
  WHY: the two are projections of one relation, so a divergence is an index defect the rebuild resolves and never a fact of its own.

---

## Examples

### Successful login and session use

A user enters their password in a financial system. The host system calls `login(principal_ref: user_u91, credential_type: "password", presented_material: <raw-password>, issued_by_ref: login_svc_l01)`.

Step 2: `Credential.verify(user_u91, "password", <raw-password>) → verified`. Step 3: credential store query returns `credential_id: cred_c01`. Step 4: `Session.issue(user_u91, login_svc_l01, 3600) → session_token: tok_abc123`. Step 5: `credential_to_sessions[cred_c01]` = `{tok_abc123}`; `session_to_credential[tok_abc123]` = `cred_c01`. Steps 6–7: `login_event_log` entry and Audit Trail login_succeeded event recorded. Return: `tok_abc123`.

The host system sets a session cookie. On the next request, the host system (or Privileged Access Provisioning) calls `Session.validate(tok_abc123) → valid(principal_ref: user_u91, expires_at: 2026-09-01T11:00:00Z)`.

### Failed login — wrong password

The user enters an incorrect password. `login(user_u91, "password", <wrong-password>, login_svc_l01)`. Step 2: `Credential.verify → failed-verification(material-mismatch)`. Step 2 path: `login_event_log` entry with `outcome: failed-verification(material-mismatch)`; Audit Trail login_failed event. Return: credential-invalid. No session is issued; no entry appears in `credential_to_sessions` or `session_to_credential`.

### Logout

The user clicks "Log out." The host system calls `logout(session_token: tok_abc123, actor_ref: user_u91, reason: "user-initiated-logout")`. Step 2: `Session.revoke(tok_abc123, user_u91, "user-initiated-logout") → revoked`. Step 3: Audit Trail logout_succeeded (composition-attributed; `requested_by: user_u91` in the data). Return: `logged-out`. Subsequent `Session.validate(tok_abc123) → invalid(revoked)`.

### Cascading revocation — compromise response

An incident-response team determines that `cred_c01` (user_u91's password credential) was likely compromised. The identity-management surface calls `Credential.revoke(cred_c01, revoked_by_ref: security_team_s01, reason: "suspected-compromise-2026-09-12")`. The response team then calls `revoke_sessions_for_credential(credential_id: cred_c01, revoked_by_ref: security_team_s01, reason: "suspected-compromise-2026-09-12")`.

Step 2: `credential_to_sessions[cred_c01]` = `{tok_abc123, tok_def456}` (two sessions were issued over the credential's lifetime). Step 3: Audit Trail `credential_revocation_cascade_initiated` event for `cred_c01`, `session_count: 2`. Step 5a — `tok_abc123`: `Session.validate → valid(...)` → `Session.revoke(tok_abc123, security_team_s01, "credential-revocation-cascade: suspected-compromise-2026-09-12") → revoked`; Audit Trail session_revoked_by_cascade. Step 5b — `tok_def456`: `Session.validate → invalid(expired)` → skipped (dead by derivation; no revocation write needed). Return: `{revoked: 1, skipped: 1, failures: 0, not_found: 0}`.

Any subsequent Privileged Access Provisioning `exercise_access` call under `tok_abc123` will return `session-invalid` at step 1, before the Capability is presented.

### Regulated adversarial scenarios

Three scenarios the composition must survive in regulated contexts:

**Regulator audit.** A SOX (Sarbanes-Oxley Act) auditor asks *"was the session used to exercise access to financial control Final Critique 789 at 09:14 on 2026-10-15 established under a valid, non-revoked credential?"* The auditor reads the Privileged Access Provisioning `session_access_log` to find `session_token: tok_abc123` was used at that time. The auditor queries `session_to_credential[tok_abc123]` → `credential_id: cred_c01`. The auditor reads the Credential store: `cred_c01` was `Active` at `09:14` (it was revoked at `11:40` on the same day, after the access). The Audit Trail's login_succeeded event for `tok_abc123` shows `attempted_at: 2026-10-15T08:52:00Z`, `credential_id: cred_c01`, `principal_ref: user_u91` in its data. Invariant 1 (credential gates issuance) is the structural guarantee that the session could not exist without a prior verified credential. The auditor has their answer from the records alone.

**Disputed login event.** A user claims *"I did not log in from that location at 03:00 AM on 2026-11-20."* The investigator queries the `login_event_log` for `principal_ref: user_u91` on that date. The entry shows `attempted_at: 2026-11-20T03:00:12Z`, `outcome: success`, `credential_id: cred_c01`, `session_token: tok_xyz789`. The Audit Trail's login_succeeded event corroborates the timestamp and credential used. Credential's Invariant 3 (sole-holder verification) means the presented material matched the verifier registered for user_u91's password credential — the login succeeded because someone presented the correct password. Whether that was the legitimate user or an attacker with the compromised password is a separate investigation; Login's records bound the forensic window: the session was issued at `03:00:12Z` after a successful credential check.

**Breach investigation — cascade completeness.** A security team is investigating a credential compromise. They ask *"how many active sessions were revoked when we cascaded the revocation of cred_c01, and is there any evidence that any session slipped through?"* The Audit Trail shows: `credential_revocation_cascade_initiated` at `2026-12-03T14:22:00Z` for `cred_c01`, `session_count: 5`. Five subsequent session_revoked_by_cascade events appear, each naming a distinct session_token. There are no login_map_write_failure events for `cred_c01`. Invariant 2 (cascade completeness) is the structural guarantee: all 5 sessions are accounted for. The investigator can confirm by querying `credential_to_sessions[cred_c01]` directly — 5 entries, each with `Session.validate → invalid(...)`. Cascade is confirmed complete.

---

## Generation acceptance

An implementation is acceptable when an external auditor, given the credential store, the session store, the substrate's trail, the two maps and the login event log, can clear the checks below without recourse to source code, runbooks or developer narration.

### Conformance checks

```
Check 1.1: An auditor MUST find EVERY login succeeded event naming a session_token the session-to-credential map carries (Invariant 5.1).
Check 1.2: An auditor MUST find EVERY session-to-credential entry naming a credential_id the credential store carries (Invariant 3.1).
Check 2.1: An auditor MUST find the credential-to-sessions map AND the session-to-credential map agreeing (Invariant 6.1).
Check 2.2: An auditor MUST rebuild both maps from the substrate's login-family events (Composition state 7).
Check 2.3: An auditor MUST find EVERY map write failure event's session_token carrying EXACTLY ONE OF an entry in both maps, an invalid answer from Session's validate (Action wiring 11).
Check 3.1: An auditor MUST find EVERY login call reaching an outcome carrying one login event log entry (Invariant 4.1).
Check 3.2: An auditor MUST find EVERY login event log entry's outcome matching the mirrored event's action_ref (Composition state 10).
Check 3.3: An auditor MUST rebuild a principal_ref's session set from the login event log AND the orphan session revoked events naming the principal_ref (Invariant 4.2).
Check 4.1: An auditor MUST find EVERY cascade initiation event older than the login completion bound carrying EXACTLY ONE OF a completion event, an abandoned event (Reconciliation 12).
Check 4.2: An auditor MUST find EVERY session revoked event naming a session the cascade set carried (Invariant 5.2).
Check 5.1: An auditor MUST find EVERY revoked session under the issuer refs carrying a revocation-family event (Reconciliation 10).
Check 5.2: An auditor MUST find EVERY session under the issuer refs older than the login completion bound named by a login-family event AND no session the login event log lacks an entry for (Reconciliation 8).
Check 6.1: An auditor MUST find EVERY audit event of the composition attested under the service identity (Composes 12).
```

NOTE: EVERY check names the rule the check tests.

### External checks

```
External check 1: An auditor needing the login event log's durability confirmed MUST read the deployment's own store configuration (Composition state 11).
External check 2: An auditor needing the issuer refs confirmed MUST read the deployment's own declaration (Capability requirement 10).
External check 3: An auditor needing the login completion bound confirmed MUST read the deployment's own declaration (Capability requirement 14).
External check 4: An auditor needing the service identity's provisioning confirmed MUST read the substrate's actor registry (Capability requirement 8).
External check 5: An auditor needing a constituent's own guarantee confirmed MUST read the constituent's own acceptance (Composes 5).
External check 6: An auditor needing the substrate's own guarantee confirmed MUST read Audit Trail's own acceptance (Composes 6).
```

WHY:
Check 5.2 is the sweep's own comparison written as an auditor's, and the pair with External check 3 is why it works: a session younger than the bound is not a finding, so an auditor without the declared bound would file against every login in flight. The bound is an operating fact rather than a record, which is what puts it on the external side.

Check 2.3 and Check 3.3 are the two an auditor cannot reach from the others. Check 2.3 is the map-degradation exit: `Action wiring 11` records the failure and nothing else says when the record stops mattering, which is either a backfilled pair or a session that has died. Check 3.3 is the reconstruction claim rather than a coverage claim — the log alone is short by exactly the sessions `Invariant 4.2` names as the sweep's, so the pair of surfaces is what makes a principal's history answerable from records with no external source.

External check 6 is the corpus's first check that sends an auditor to a **composition's** acceptance rather than an atom's. [Audit Trail](./audit-trail.md) is a substrate here, so its own guarantees are inherited by reference under the section titled Conformance in `execution-contract.md` and are not re-verified at this layer — the auditor reads its acceptance, not this one's.

---

## Non-goals

```
Non-goal 1: The composition MUST NOT register a credential.
Non-goal 2: The composition MUST NOT rotate a credential.
Deleted: Non-goal 3. Wiring decision 3 owns it.
Non-goal 4: The composition MUST NOT offer Session's validate.
Non-goal 5: The composition MUST NOT authorize an action.
Non-goal 6: A deployment needing an authorized action MUST compose Permissions.
Non-goal 7: The composition MUST NOT bound a principal_ref's concurrent sessions.
Non-goal 8: The composition MUST NOT renew a session.
Non-goal 9: The composition MUST NOT bind a session to a device.
Non-goal 10: The composition MUST NOT limit a login's rate.
Non-goal 11: The composition MUST NOT hold a second factor.
Non-goal 12: The composition MUST NOT adopt a session issued outside the issuer refs.
Non-goal 13: The composition MUST NOT revoke a session issued outside the issuer refs.
Deleted: Non-goal 14. Invariant 2.2 owns it.
```

WHY:
Non-goal 12 and Non-goal 13 are one boundary seen from both sides. A session outside the declared issuers is another surface's business, and a sweep that adopted one would be claiming authority over a grant it never issued; a sweep that revoked one would be destroying it.

Non-goal 4 is why this composition's surface is narrower than it looks. Callers validate sessions by calling [Session](../atoms/session.md) directly; re-exposing `validate` here would put a read with no composition semantics on the boundary and invite a caller to believe the composition had added something to it.

Non-goal 10 and Non-goal 11 are the two a regulated reader expects and does not get. Rate limiting and a second factor are real obligations and neither is this wiring's: both belong to the calling layer or to a composing pattern, and absorbing either would make the gate's meaning depend on a policy the composition cannot state.

---

## Composition notes

```
Composition note 1: A deployment MUST declare which composing patterns the deployment wired in.
Composition note 2: A deployment MUST own a credential's registration, rotation AND revocation.
Composition note 3: A deployment MUST call [Revoke Sessions For Credential] when the deployment revokes a credential.
Composition note 4: A deployment MUST own a login's rate limit.
Composition note 5: A deployment MUST own a second factor.
Composition note 6: A deployment MUST act on the sweep's escalation.
```

WHY:
Composition note 3 is the cascade's trigger and it is the deployment's to pull. This composition provides the downstream half and never the revocation itself, so a deployment that revokes a credential without calling the cascade leaves live sessions behind a dead credential — which is precisely the failure the cascade exists to prevent and the one place the composition depends on being invoked.

---

## Terms

The canonical concepts this spec refers to. Each `term` marker in the prose above links to its term entry here. A term entry states what the concept *is*, in plain English, plus its **Kind** — one of five: **Type** (a thing or category), **Operation** (a behavior), **Member** (a value of an enumerated Type), or, for a named datum, **Field** (a datum a Type carries — *what does it carry?*) or **Parameter** (a value an Operation needs — *what does it need?*). A term entry also names the Type it is a **Member of** / **Field of**, the Operation it is a **Parameter of**, and its **Role** where the domain assigns one. A term entry carries one **Projection** line — the concept's single canonical lowering token, the one place the concrete name stays visible on the page — for every Field, Parameter, and pinned/wire Member. Everything else about casing (each target's snake / camel / pascal / const / wire form) is **derived** from that one token by [`tools/harness/term-adapter.mjs`](../tools/harness/term-adapter.mjs), never hand-written. This is a composition, so its own concepts are the emergent cascade action it exposes ([Revoke Sessions For Credential]) — the load-bearing surface neither constituent provides — its own login rejection ([Credential Invalid]), the distinctive `login_event_log` classifications it records ([Outcome], with its [Success With Map Failure] and [Failed Storage Failure] members), and the cascade result's integrity-gap counter ([Not Found]). The two eponymous thin-wrapper actions — login (verify → issue) and logout (revoke) — are left backticked (their names would also collide with the page heading and the *Logout* example anchor). Its emergent state — the cascade maps (`credential_to_sessions`, `session_to_credential`) and the `login_event_log` — is a composition-introduced surface no constituent provides, left as backticked store tokens. References to the constituent atoms and their operations — Credential's `verify` / `register` / `revoke`, Session's `issue` / `revoke` / `validate`, Audit Trail's `record_action` — the relayed tokens (principal_ref, credential_id, session_token, credential_type), the constituent states (`Active` / `Revoked`, and the derived `Expired` effective status), the Audit Trail event types (login_succeeded, session_revoked_by_cascade, orphan_session_revoked, …), and the inherited rejections (invalid-request, `not-known`, `already-terminal`, storage-failure) remain qualified/backticked, not carded here. *(annotation.md Terms registry; representational only — it changes no guarantee, invariant, or behavior of the composition above.)*

### Vocabulary

Term qualifiers: migrated — rewritten in GRACE lang v0.40 (2026-09-14).

Term terms: composition, constituents, service identity, credential-to-sessions map, login event log, login-family events, seam, transition, issuer refs, login completion bound, blank, opaque input, admitted login, admitted logout, admitted cascade, cascade set, revocation-family event, login result, revocation tally.

Term record verbs: call, answer, read, write, append, store, key, hold, remove, change, rest, rebuild, record, retry, re-emit, close, escalate, examine, revoke, issue, gate, cascade, verify, attest, carry, select, query, offer, serve, compose, inherit, declare, set, configure, provision, rotate, own, act, adopt, bound, renew, bind, authorize, register, count, stand, follow, name, equal, agree, match, find, persist, generate, mint, normalize, compare, skip, union, supply, take, alert, run, limit, derive, shrink.

Term actors: the composition; the constituents; the substrate; the host; the transition; a deployment; an auditor; a caller; a principal; the sweep; a session; a credential; an event.

Term cited: the section titled Conformance in `execution-contract.md` — recursive conformance and the inherited guarantee. The section titled Composition state in `execution-contract.md` — the derived-index and extraction-pending classifications. The section titled Substrate composition invocation in `execution-contract.md` — what naming a composition as a constituent means at runtime. The section titled Logic Confinement Principle in `execution-contract.md` — the seam and the transition.

#### Revoke Sessions For Credential

The composition's load-bearing emergent action: given a credential_id, it walks `credential_to_sessions[credential_id]` and revokes every still-`Active` derived session through `Session.revoke`, recording an initiation event, one event per session it acted on (already-terminal sessions are counted, not recorded), and a completion event carrying the counters. Returns `{revoked, skipped, failures, not_found}` (the snapshot accounting), or an inherited rejection. Called *after* an external `Credential.revoke`; it never revokes the credential itself. Neither constituent carries this cascade.

Kind: Operation

#### Credential Invalid

The composition's own login rejection — returned when `Credential.verify` fails (`failed-verification(reason)`): the credential check did not pass, so no session is issued and a failed-login event is recorded. The observable form of the credential-gates-issuance boundary (Invariant 1).

Kind:       Member
Member of:  the login rejection
Role:       Rejection
Projection: credential-invalid

#### Outcome

The `login_event_log` entry's classification of a login call: one of `success`, [Success With Map Failure], `failed-verification(reason)`, or [Failed Storage Failure]. Every login call appends exactly one entry (Invariant 4), giving the composition a records-alone query surface alongside the tamper-evident Audit Trail.

Kind:       Field
Field of:   the login-event-log entry
Role:       the login-attempt classification
Projection: outcome

#### Success With Map Failure

The [Outcome] for the load-bearing step-5 asymmetry: `Session.issue` succeeded and the session was returned to the caller, but the cascade-map write failed. The session is valid and stays cascade-covered through the event side (Invariant 2.3's union); the login_map_write_failure Audit Trail event is both that coverage and the canonical remediation signal for the fast-path map.

Kind:       Member
Member of:  the login outcome
Role:       Outcome
Projection: success-with-map-failure

#### Failed Storage Failure

The [Outcome] for a login call that failed at a named stage (`credential-id-lookup`, `credential-id-confirm`, or `session-issue`) after credential verification but before a session was issued. Carries the stage; the session token is null.

Kind:       Member
Member of:  the login outcome
Role:       Outcome
Projection: failed-storage-failure

#### Not Found

The [Revoke Sessions For Credential] counter for a data-integrity gap: a session_token present in `credential_to_sessions` but absent from the Session store (`Session.validate → invalid(not-known)`). Distinct from skipped (already-terminal sessions); each increment writes a `session_not_found_during_cascade` event for investigation.

Kind:       Field
Field of:   the cascade result
Role:       the integrity-gap count
Projection: not_found

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a term marker to its term entry heading above (kramdown
     auto-generates the heading anchors on GitHub Pages). Standard CommonMark /
     kramdown; no plugin required. -->

[Revoke Sessions For Credential]: #revoke-sessions-for-credential
[Credential Invalid]: #credential-invalid
[Outcome]: #outcome
[Success With Map Failure]: #success-with-map-failure
[Failed Storage Failure]: #failed-storage-failure
[Not Found]: #not-found

---

## Standards references

- **NIST (National Institute of Standards and Technology — US federal standards body) SP 800-63B §7 (Session Management)** — the primary standard for session lifecycle in authenticated systems. The composition's `login → Session.issue` wiring implements the session binding requirement; `logout → Session.revoke` implements the session termination requirement. The [Revoke Sessions For Credential] cascade implements the reauthentication-on-credential-change requirement: when a credential is revoked, all dependent sessions must be terminated.
- **NIST SP 800-53 AC-12 (Session Termination)** — requires that sessions terminate after a defined condition. The composition's logout and [Revoke Sessions For Credential] actions are the two termination surfaces; the expires_at immutability of Session is the time-bounded termination mechanism.
- **OWASP ASVS V3.1 (Authentication) and V3.3 (Session Termination)** — the OWASP (Open Worldwide Application Security Project) Application Security Verification Standard; the login action's sequencing (verify then issue, with failed attempts recorded) and logout's full revocation (not just cookie deletion) correspond to ASVS requirements for authentication event logging and session invalidation on logout.
- **GDPR (EU General Data Protection Regulation — the European Union's data-privacy law) Article 32 (Security of Processing)** — the `login_event_log` and Audit Trail recording of all authentication events, including failures, contribute to the "appropriate technical measures" Article 32 requires. The [Revoke Sessions For Credential] cascade is a breach-response mechanism that reduces the blast radius of a compromised credential.
- **HIPAA (US Health Insurance Portability and Accountability Act) §164.312(d) (Person or Entity Authentication)** — the composition's `Credential.verify → Session.issue` wiring is the structural implementation of this requirement: a session is issued only after the principal's identity is confirmed. The Audit Trail records the authentication event for post-incident investigation.
- **PCI DSS (Payment Card Industry Data Security Standard — the card networks' mandatory security rules for cardholder data) Requirement 8.2 (User Identification and Authentication)** and **Requirement 8.6 (Session Management)** — authentication event logging (all login attempts, successful and failed), session termination on logout, and revocation on credential change correspond to PCI DSS structural requirements. The `login_event_log` is the composition-layer record; the Audit Trail is the tamper-evident external-auditor record.
- **SOX §302 / §404 (Internal Controls)** — the `credential_to_sessions` map and its cascade action are the structural mechanism for ensuring that a compromised credential's access window can be closed completely and auditedly. An auditor can verify cascade completeness from the Audit Trail records alone without consulting the incident-response team.
- **OpenID Connect Core 1.0** — the composition is the Grace Commons expression of the OIDC (OpenID Connect — an identity layer built on OAuth 2.0) login flow: authorization code exchange (credential verification), session establishment (session issuance), and session revocation on logout or token revocation. The atoms' principal_ref maps to the OIDC `sub` claim.

Inherited from:

- **Daniel Jackson, *The Essence of Software*** — the freestanding-atom posture that makes the cascade an emergent property of the composition rather than a feature bolted onto either Credential or Session.
- **NIST 800-63B §4 (Authenticator and Verifier Requirements)** — the upstream standard for Credential's verifier-not-material storage discipline, which this composition inherits transitively.

---

## Status

`partially resolved` — see the Ledger.

## Ledger

```
status: partially resolved
formal: verified — login.tla, no twin, 2026-05-23
last gate: 2026-08-28 — second gate after closure, fresh reader — 5 foundational (all since closed), 16 refining (2 since closed), 3 rhetorical

open:
- 2026-08-27-j · refining · `login` step 1 · adopts Session's and the audit instance's string policies and never Credential's per-string cap or derivation-registry constraint, though three inputs flow to `Credential.verify`, which declares no `invalid-request` arm → adopt Credential's policy or name the landing
- 2026-08-27-k · refining · The recovery discipline, bullet 1 · "mirrored audit event is absent" names no matching key; failure-path entries carry no `session_token` → name the key
- 2026-08-27-m · refining · Invariant 5, first clause · stated absolutely over a lossy derived index, with no window named → name the retry window as `Check 5.2` does
- 2026-08-27-n · refining · `logout` `reason`; The recovery discipline, bullet 3 · the cascade prefix is the sweep's sole discriminator and a caller can supply it, making the sweep emit a `session_revoked_by_cascade` with no initiation → reserve the prefix or discriminate on a stored field
- 2026-08-27-p · refining · Composition state; Edge cases · `TTL` used three times and never expanded; `OIDC` / `OAuth 2.0` used before their gloss → gloss at first use
- 2026-08-27-q · refining · `login` steps 2–3; Invariant 3 · a rotation to identical material defeats the verify–read–verify sandwich, rooting the session on a `Rotated` id → name the case and its landing
- 2026-08-27-r · rhetorical · Intent; Terms, [Revoke Sessions For Credential] term entry · both say the cascade walks the map alone, predating Invariant 2.3's union → align
- 2026-08-27-s · rhetorical · Examples, Regulator-audit scenario · "exercise access to financial control Final Critique 789" is a review artifact in an identifier → replace
- 2026-08-27-t · rhetorical · Examples, Cascading revocation · per-session iterations labelled "Step 5a"/"Step 5b", which are the loop's sub-steps → relabel
- 2026-08-27-u · rhetorical · Examples, Breach investigation · "Cascade is confirmed complete" with no completion event, which `Check 4.1` now requires first → add the event
- 2026-08-26-a · refining · Invariant 2, second-cascade closure · needs the retry-quiescence qualifier → add it
- 2026-08-26-b · refining · Invariant 2, exception clause · omits the conformance-fault arm step 5b carries on the same landing → add it
- 2026-08-26-c · refining · Composition state · "populated atomically with each `Session.issue` call" contradicts the outside-the-atomicity-surface classification (the atomicity is between the two map writes) → restate
- 2026-08-26-d · refining · Summary · uses the map-degradation vocabulary before any map is introduced → introduce or defer
- 2026-08-26-e · rhetorical · Invariant 1 · "immediately preceding call" is imprecise → state the ordering
- 2026-08-26-f · rhetorical · `login` step 3 · "both sides of the read" overstates under a revoke-then-re-register race → narrow
- 2026-08-28-a · refining · Invariants 2, 5; `Check 4.1` · "Active" used for both stored status and validate's `valid`; step 5c skips lapsed stored-Active sessions, which are not terminal in the store → quantify over sessions that read `valid` at 5a; "terminal or lapsed" for the post-state
- 2026-08-28-b · refining · Configuration `default_session_duration`; `login` step 4 · Configuration says an absent default returns `invalid-request`; step 4 routes Session's `invalid-request` to a storage-failure landing → check the default at step 1 and return `invalid-request` there, or delete the claim
- 2026-08-28-c · refining · cascade step 5b · `Session.revoke`'s `not-known` arm unaddressed; unreachable after a `valid` 5a only by Session Invariant 9 → state the unreachability and its source
- 2026-08-28-d · refining · `login` steps 2–6 · `login_event_log` appends have no failure arm although the entry is durable intent → specify the arm
- 2026-08-28-e · refining · `login` step 1; Configuration `issuer_refs` · `issued_by_ref` membership in `issuer_refs` is never checked, so a caller can issue sessions the sweep never sees → validate at step 1
- 2026-08-28-f · refining · recovery discipline, third comparison · assumes Login is the sole non-cascade revoker; a direct `Session.revoke` elsewhere is re-emitted as a logout nobody requested → declare the sole-revoker obligation; mark logout re-emissions `recovery = true`
- 2026-08-28-g · refining · Composes; cascade step 2; both rebuilds · the open-upper-bound read's lower bound is never stated → state it
- 2026-08-28-h · refining · `Check 5.2` · quantifies over every session under the issuer refs while the naming events are destroyed at the audit horizon → scope to the horizon
- 2026-08-29-a · refining · formal · the model's sweep carries no upper edge and no recovery record → extend it
- 2026-08-28-i · refining · `login` step 3; Invariant 3 · the sandwich proves an effective-Active record on each side, not the same one; a same-material rotation inside the window roots the session on the predecessor → state the residual or compare ids
- 2026-08-28-j · refining · Composition state · the credential↔session relation's cardinality and modality are undeclared → declare
- 2026-08-28-k · refining · Composition state; Edge cases · TTL never spelled out; OIDC used before its gloss → define at first use
- 2026-08-28-l · refining · Summary · unexplained jargon; "cancelled before the operation returns, leaving none behind" overclaims against Invariant 2's window → gloss; state the snapshot scope
- 2026-08-28-m · refining · Intent; term entrys · describe the cascade as walking `credential_to_sessions` only where step 2 reads the union → align
- 2026-08-28-n · refining · `Check 5.1`; Invariant 5 · a crash between steps 5 and 6 leaves a map entry only `orphan_session_revoked` names → carve out (`Check 5.1` carries the orphan through the revocation-family event; Invariant 5's inverse still owed)
- 2026-08-28-o · rhetorical · Examples, cascade and breach · step labels wrong; completion event omitted; the breach reconciliation uses the form `Check 4.1` calls wrong → rewrite
- 2026-08-28-p · rhetorical · Examples, regulator audit · "financial control Final Critique 789" search-and-replace artifact → restore
- 2026-08-28-q · rhetorical · `login` step 5 failure arm and step 7 · "retries until it lands" without citing the recovery discipline → cite
```

## Decisions

Directional changes only — the turns a future reader must know the pattern took, and why. Everything smaller lives in the commit that made it: `git log -- compositions/login.md`.

- **2026-08-28 — The cascade writes its join key into the Session record, and what cannot be re-emitted is re-run.** *Chose:* step 5b's revoke reason carries `initiation_event_id`, so a sweep re-emission carries the real id and check 3 counts it; the completion event waits for every per-session record; an initiation that dies without completion is abandoned and the cascade re-run. *Over:* re-emitted events with `initiation_event_id: null` excluded from the arithmetic, and a claim that the sweep re-derives every owed record. *Because:* a failed revoke and a not-found token leave nothing in any store to re-derive a record from, so the claim was false; re-running is the only honest closure, and the join key in the reason makes the re-emittable records exact rather than excused.
- **2026-08-29 — The sweep is bounded above as well as below, and records its intent before it revokes or re-runs.** *Chose:* every comparison scoped to the audit horizon, past which a missing event is destruction and the record is reported purged rather than repaired; a `login_recovery_intended` event before the second comparison's revoke and the fourth's re-run; `reconciliation_window` and `reconciliation_cadence` declared. *Over:* the age-bounded sweep of 2026-08-28 with no upper edge. *Because:* a comparison past the horizon revokes sessions whose issuance events aged out and re-emits logouts the purge lawfully removed, and a sweep that revokes with no record of its own is indistinguishable from a direct call (the frozen rules of 2026-08-29 — *A reconciliation is bounded at both ends*, *Recovery commits under a declared service identity*).
- **2026-08-28 — The sweep is age-bounded and `login_event_log` is extraction-pending against Event Log.** *Chose:* a declared `login_completion_bound` below which the sweep examines nothing, and the log classified as the composition's own call journal pending extraction, durable now. *Over:* an unbounded sweep and a "conditional derived index". *Because:* the unbounded sweep revoked logins still in flight, and the invented classification let a generator hold the sweep's only intent in memory.
- **2026-08-26 — Every Login event is composition-attributed.** *Chose:* attest under `application_actor_ref` / `application_credential`, with the human parties in `data`. *Over:* attesting under the principal's own credential. *Because:* Login's callers are end principals whose material is the thing under test, not registry actors — and a failed login has no valid credential to attest with. This governs every audit write the pattern makes.
- **2026-08-26 — Invariant 2 promises less than it did.** *Chose:* cascade completeness is claimed only for verifies that committed after the revocation, with the in-flight window named and a second cascade prescribed after quiescence. *Over:* single-cascade sufficiency. *Because:* a login whose verify committed before the revocation can land its session after the cascade's snapshot, and no single cascade can see it. The headline guarantee is narrower and true.

- **2026-09-14 — Rewritten in GRACE lang v0.40; nothing but language changed.** *Chose:* `Composes`, `Composition state`, `Capability requirement`, `Primitive policy`, `Audit arm`, `Action wiring`, `Wiring decision`, `Reconciliation` as the surfaces, the six invariant numbers unchanged, and an acceptance section distributed from the checks the prose already named. *Over:* the prose spec. *Because:* the migration plan; nothing in the corpus cites this composition by label. **No preservation claim was collapsed** — this is the first composition of the epoch carrying none, because every invariant here already emerges and the constituents' guarantees were carried as citations rather than as invariants of their own. The three tombstones it does carry are re-homings inside the spec rather than collapses: `Invariant 4.1` to `Composition state 10`, `Non-goal 3` to `Wiring decision 3`, `Non-goal 14` to `Invariant 2.2`.
- **2026-09-14 — `Reconciliation` reaches recurrence in consecutive migrations, and the decision not to merge it with `Eviction` holds.** *Chose:* to take `Reconciliation` for the issuance-reconciliation sweep. *Over:* minting a third name, or folding it into `Composition state`. *Because:* [Authenticated Actor](./authenticated-actor.md) minted it one migration earlier for the orphaned-credential leg, and this sweep is the same family rather than the same shape: both run outside any invocation, both report or close rather than serve a caller, both owe an age edge. [Idempotent Reservation](./idempotent-reservation.md)'s `Eviction` shares the *shape* and remains separate for the reason council read 61 stated — it evicts where these report, and the difference decides whether a liveness bound is owed. Two consecutive specs is Principle 2's recurrence bar met for `Reconciliation`; `Eviction` stays at one and stays flagged (council read 62).
- **2026-09-14 — The first composition to name a composition as a constituent.** *Chose:* `Composes 6` and `Composes 7`, citing the section titled Substrate composition invocation in `execution-contract.md`, with `External check 6` sending an auditor to [Audit Trail](./audit-trail.md)'s own acceptance rather than re-verifying it here. *Over:* listing Event Log, Actor Identity, Retention Window and Tamper Evidence as this composition's constituents, which is what the atom-only reading of `Composes` would have produced. *Because:* the substrate's guarantees are inherited by reference — that is the point of naming a substrate — and re-listing its constituents would have claimed instances this composition does not hold. The corpus composes compositions and this is the first migrated spec where the rule surface has to say so.

NOTE: End of Login.
