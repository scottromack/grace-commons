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

Its central guarantee is that a session can never be issued without a successful credential check first — the wiring makes it structurally impossible, and an auditor can confirm it from the records because every issued session is named by a login-family audit event: login_succeeded on the clean path, or login_map_write_failure when the session's index entry could not be written, each committed with the session it names or, where the audit trail refuses it, re-emitted by the reconciliation sweep from the login's log entry. Its second guarantee is cascade completeness: when a credential is revoked, every still-active session the index or the trail names for it at that moment is cancelled before the operation returns, and any the cancel could not reach is counted back to the caller.

Every login attempt (success or failure), every logout, and every cascaded revocation is recorded, so an investigator can answer from the records alone which credentials established which sessions, whether a session rested on a valid credential, and when and by whom sessions were revoked. The cascade is the load-bearing guarantee that appears only when the three patterns are combined — it belongs to none of them alone — and it is what lets higher-level patterns reliably cut off access the moment a credential is pulled.

---

## Intent

Every system that authenticates principals eventually faces the same composability problem: credential verification is a momentary check, session management is a bounded persistence concept, and audit recording is a regulated obligation — and none of the three atoms can see the other two. Credential answers *"does this material match what was registered?"* and returns immediately. Session issues a time-bounded token but makes no authentication judgment — it issues a session for whatever principal it is given, trusting entirely that the caller verified authentication first. Audit Trail records events but knows nothing about the semantics of the events it records. The question of *what should happen at the boundary where these three concepts meet* — how the transition from credential verification to session issuance should be wired, what should be recorded and when, and especially what should happen to open sessions when a credential is revoked — belongs to no single atom. It belongs to the composition.

Login is that composition. It provides three services: the login action wires `Credential.verify → Session.issue` in the correct order, with every login attempt (successful or failed) recorded in the Audit Trail before returning. The logout action wires `Session.revoke` with attribution and Audit Trail recording. And [Revoke Sessions For Credential] provides the cascade: when a Credential is revoked — whether by the credential owner, an administrator, or an automated compromise-response process — every Session derived from that Credential is revoked in the same operation, and the full cascade is recorded.

The cascade is load-bearing for downstream compositions. Privileged Access Provisioning's `exercise_access` action depends on Session validity as its first guard: a session invalidated by credential revocation will block all subsequent `exercise_access` calls for any Capability issued to that principal's sessions. The cascade path is: `Credential.revoke` (outside this composition's surface) → caller invokes [Revoke Sessions For Credential] → Login reads the cascade set — the map's entry and the pairs the trail carries → `Session.revoke` for each Active session → Audit Trail records each revocation → Privileged Access Provisioning's session check thereafter returns `session-invalid`. The Login composition is the mechanism that makes this arc visible and traceable from records alone.

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
Composes 5: The composition MUST inherit a constituent's invariants PER Execution Contract Conformance 8.
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
Composes 18: The composition MUST read the substrate's events from sequence one.
```

Term composition: this pattern's wiring of [Credential](../atoms/credential.md), [Session](../atoms/session.md) and the [Audit Trail](./audit-trail.md) substrate — the issuance gate, the revocation cascade, the two maps and the sweep.

Term constituents: [Credential](../atoms/credential.md), [Session](../atoms/session.md), [Audit Trail](./audit-trail.md).

Term service identity: the composition's own registered actor and credential — a service identity; the attested emitter of every audit event this composition writes.

---

## Composition logic

### Composition state

```
Composition state 1: The composition MUST store a credential-to-sessions map.
Composition state 2: The composition MUST store the strict inverse of the credential-to-sessions map.
Composition state 3: The composition MUST write both maps under one transaction.
Composition state 4: The composition MUST NOT remove a session token from the credential-to-sessions map.
Composition state 5: The composition MUST NOT change a session-to-credential entry.
Composition state 6: The composition MUST key the credential-to-sessions map by credential id.
Composition state 7: The composition MUST rebuild a map from the substrate's login-family events.
Composition state 8: The composition MUST NOT rest a session's validity on a map write.
Composition state 9: The composition MUST store a login event log.
Composition state 10: The composition MUST append a login event log entry per login call reaching an outcome.
Deleted: Composition state 11. Execution Contract Database 3 owns it.
Deleted: Composition state 12. Execution Contract Database 3 and Execution Contract Database 4 own it.
Composition state 13: EVERY session MUST rest on EXACTLY ONE credential.
Composition state 14: A credential MAY carry a session beside another session.
Composition state 15: A credential MAY carry no session.
Composition state 16: A login event log entry MUST carry the entry id.
```

Term credential-to-sessions map: the composition's own map from a credential id to the session tokens issued under it — a credential to sessions map; the cascade's root index.

Term login event log: the composition's own append-only record of every login call, successful or refused — a login event log.

Term entry id: the id the host supplies at the seam for one login call's login event log entry — the key between the entry and the entry's mirrored event.

Term login-family events: the substrate's login_succeeded, login_map_write_failure and login_failed events.

**Contract classification: two derived indexes and one extraction-pending element** (the section titled Composition state in [`execution-contract.md`](../execution-contract.md)).

- The two **maps** are a *derived index*, and the pairing fact lives in a constituent: every issued session's `(credential_id, session_token)` pair is immutable audit content, written into the login_succeeded event's data and, on the map-write failure arm, into a login_map_write_failure event. *Rebuild procedure:* enumerate the substrate through the declared read, select the login-family events, and group each data's session token by its credential id. **Bound on the rebuild's totality, stated rather than assumed:** the traversal reads event payloads the substrate destroys at its retention horizon, so the rebuild is total only within that horizon — and the readers need it total for one session lifetime, not for the life of the credential. A login_map_write_failure event names a pair the live map lacks, so the rebuild reconstructs exactly the backfill Invariant 2.4's remediation prescribes — rebuild-on-miss **is** the remediation path.
- The **login event log** is *extraction-pending, against [Event Log](../atoms/event-log.md)*. The Contract's record-coordination rule says a composition that must record that its own calls occurred composes Event Log rather than growing bespoke records, and that is the extraction pending here: a second Event Log instance for the login-attempt journal, at which point the entries become that instance's events and the classification question dissolves.

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
Capability requirement 10: A deployment MUST declare the issuer references.
Capability requirement 11: A deployment MUST set the reconciliation window.
Capability requirement 12: A deployment MUST set the reconciliation cadence.
Capability requirement 13: The reconciliation cadence MUST NOT EXCEED the reconciliation window.
Deleted: Capability requirement 14. Execution Contract Database 1 owns it.
Capability requirement 15: A deployment MUST set whether a failed login reaches the substrate.
Capability requirement 16: The host MUST supply one entry id at the seam PER login call.
Capability requirement 17: A deployment MUST NOT revoke a session under the issuer references outside the composition.
Capability requirement 18: The deployment MUST supply the database PER Execution Contract Database 1 through 4.
```

Term seam: the composition's I/O boundary as the section titled Logic Confinement Principle in `execution-contract.md` declares it; the host injects one clock reading and, for a login call, one entry id here.
Term now: the wall-time reading the host takes at the seam and hands to the transition, as the section titled Logic Confinement Principle in `execution-contract.md` declares it; never read inside the transition, never supplied by the business caller.

Term transition: the composition's evaluation of one call against the constituents, as the section titled Logic Confinement Principle in `execution-contract.md` declares it.

Term issuer references: the issued by reference values the deployment's calling layers pass into login — the scope of every sweep comparison against the session records.

### Primitive policy

```
Primitive policy 1: The composition MUST answer invalid-request for a blank principal reference.
Primitive policy 2: The composition MUST answer invalid-request for a blank credential type.
Primitive policy 3: The composition MUST answer invalid-request for a blank presented material.
Primitive policy 4: The composition MUST answer invalid-request for a blank session token.
Primitive policy 5: The composition MUST answer invalid-request for a session duration the deployment did not set AND the caller did not supply.
Primitive policy 6: The composition MUST compare an opaque input byte-exact.
Primitive policy 7: The composition MUST NOT normalize an opaque input.
Primitive policy 8: The composition MUST NOT persist a presented material.
Primitive policy 9: The composition MUST NOT answer a presented material.
Primitive policy 10: IF a principal reference EXCEEDS Credential's length bound THEN the composition MUST answer invalid-request.
Primitive policy 11: IF a credential type EXCEEDS Credential's length bound THEN the composition MUST answer invalid-request.
Primitive policy 12: The composition MUST answer invalid-request for an issued by reference outside the issuer references.
Primitive policy 13: The composition MUST answer invalid-request for a logout reason beginning with the cascade reason's prefix.
Deleted: Primitive policy 14. Execution Contract Database 1 owns it: a login's session and its records commit together, so the sweep revokes no session under a reason of its own.
```


Term opaque input: principal reference | credential type | session token | credential id.

### Audit arm

```
Deleted: Audit arm 1. Execution Contract Database 1 owns it: an action's writes commit together, so no invocation retries an owed record.
Audit arm 2: The composition MUST NOT retry a landed record.
Deleted: Audit arm 3. Execution Contract Database 1 and Execution Contract Database 3 own it.
Audit arm 4: The composition MUST read an invalid-credential answer as a deployment fault.
Audit arm 5: The composition MUST alert on an invalid-credential answer.
Audit arm 6: The composition MUST read an invalid-request answer as a deployment fault.
Audit arm 7: The composition MUST NOT read an invalid-request answer as unreachable.
Audit arm 8: The composition MUST NOT retry an invalid-request answer in a loop.
Audit arm 9: The composition MUST read an invalid-request(step-4) answer as a record already landed.
Audit arm 10: The composition MUST read an invalid-request(step-3) answer as a record still owed.
Audit arm 11: The composition MUST read an invalid-request(step-1) or invalid-request(step-2) answer as a record still owed with nothing committed.
Audit arm 12: The composition MUST NOT retry an invalid-request(step-3) or invalid-request(step-4) answer.
```

### Action wiring

```
login(principal_ref, credential_type, presented_material, issued_by_ref, optional session_duration)
  answers login result
  refuses invalid-request | invalid-credential | storage-failure(stage)

logout(session_token, revoked_by_ref, reason)
  answers ok
  refuses invalid-request | not-known | already-terminal | storage-failure

revoke_sessions_for_credential(credential_id, revoked_by_ref, reason)
  answers revocation tally
  refuses invalid-request | storage-failure
```

Term login result: session token and expiry instant — what login answers.

Term revocation tally: revoked, skipped, failed and not-found — the four counts revoke_sessions_for_credential answers.

```
Action wiring 1: An admitted login MUST call Credential's verify with the principal reference, the credential type AND the presented material.
Action wiring 2: IF Credential's verify answers failed-verification THEN an admitted login MUST answer invalid-credential.
Action wiring 3: An admitted login MUST NOT answer Credential's verify reason to the caller.
Action wiring 4: An admitted login MUST call Session's issue ONLY AFTER Credential's verify answers verified.
Action wiring 5: An admitted login MUST read the credential id of the effective-active credential for the pair.
Action wiring 6: An admitted login MUST read the credential id again ONLY AFTER Session's issue commits.
Action wiring 7: IF the two credential id reads disagree THEN an admitted login MUST answer storage-failure naming the credential-id-confirm stage.
Action wiring 8: An admitted login MUST call Session's issue with the principal reference, the issued by reference AND the session duration.
Action wiring 9: An admitted login MUST write both maps ONLY AFTER Session's issue commits.
Action wiring 10: IF the map write fails THEN an admitted login MUST answer the session token.
Action wiring 11: IF the map write fails THEN an admitted login MUST record a map write failure event carrying the pair.
Action wiring 12: An admitted login MUST append a login event log entry.
Action wiring 13: An admitted login MUST record a login event under the service identity.
Action wiring 14: An admitted logout MUST call Session's revoke with the session token, the revoked by reference AND the reason.
Action wiring 15: IF Session's revoke answers not-known THEN an admitted logout MUST answer not-known.
Action wiring 16: An admitted logout MUST record a logout event under the service identity.
Action wiring 17: An admitted cascade MUST read the cascade set ONLY AFTER recording a cascade initiation event.
Action wiring 18: An admitted cascade MUST read the cascade set as the union of the map entry AND the event-derived set.
Action wiring 19: An admitted cascade MUST call Session's validate for EVERY session token the cascade set carries.
Action wiring 20: An admitted cascade MUST call Session's revoke for EVERY session token Session's validate answers valid for.
Action wiring 21: An admitted cascade MUST NOT call Session's revoke for a session token Session's validate answers invalid for.
Action wiring 22: IF Session's validate answers expired OR revoked THEN an admitted cascade MUST count the session token as skipped.
Action wiring 23: An admitted cascade MUST record a session revoked event per revoked session token.
Action wiring 24: An admitted cascade MUST NOT change the credential-to-sessions map.
Action wiring 25: An admitted cascade MUST record a cascade completion event carrying the initiation event's id AND the four counts.
Action wiring 26: An admitted cascade MUST answer the revocation tally.
Action wiring 27: IF Session's revoke answers already-terminal THEN an admitted logout MUST answer already-terminal.
Action wiring 28: IF Session's revoke answers storage-failure THEN an admitted logout MUST answer storage-failure.
Action wiring 29: IF Session's revoke answers invalid-request THEN an admitted logout MUST answer invalid-request.
Action wiring 30: IF the first credential id read finds no effective-active credential THEN an admitted login MUST answer storage-failure naming the credential-id-lookup stage.
Action wiring 31: IF Session's issue answers storage-failure THEN an admitted login MUST answer storage-failure naming the session-issue stage.
Action wiring 32: A cascade initiation event MUST carry the credential id, the revoked by reference AND the reason.
Action wiring 33: IF Audit Trail refuses the cascade initiation event THEN an admitted cascade MUST answer storage-failure.
Action wiring 34: An admitted cascade MUST call Session's revoke with the cascade reason.
Action wiring 35: IF Session's validate answers not-known THEN an admitted cascade MUST count the session token as not-found AND record a session not found event.
Action wiring 36: IF Session's revoke refuses a session token THEN an admitted cascade MUST count the session token as failed AND record a revoke failure event.
Action wiring 37: An admitted login MUST record the login event ONLY AFTER the login event log entry lands.
Action wiring 38: IF the login event log append fails THEN an admitted login MUST answer storage-failure naming the login-event-log stage.
Action wiring 39: A login event MUST carry the login event log entry's entry id.
```

Term admitted login: a login call whose inputs cleared the boundary predicate.

Term admitted logout: a logout call whose inputs cleared the boundary predicate.

Term admitted cascade: a [Revoke Sessions For Credential] call whose inputs cleared the boundary predicate.

Term cascade reason: "credential-revocation-cascade:" and the cascade initiation event's id, then ": " and the caller's reason — the join key the revoked Session record keeps.
Term cascade events: credential_revocation_cascade_initiated, session_revoked_by_cascade, session_revoke_failure_during_cascade, session_not_found_during_cascade, credential_revocation_cascade_completed and credential_revocation_cascade_abandoned — the substrate's events a cascade and the sweep's abandonment record.
Term cascade set: the union of the credential-to-sessions map's entry for a credential id and the event-derived set the substrate's login-family events carry for it.

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
Deleted: Reconciliation 1. Execution Contract Database 1 and Execution Contract Database 3 own it.
Reconciliation 2: The sweep MUST run every reconciliation cadence.
Reconciliation 3: The sweep MUST NOT store a record of the sweep's own.
Reconciliation 4: The sweep MUST close a discrepancy through an ordinary record_action.
Reconciliation 5: The sweep MUST re-emit an owed record the login event log carries.
Deleted: Reconciliation 6. Execution Contract Database 1 owns it.
Reconciliation 7: The sweep MUST NOT examine a session issued outside the issuer references.
Deleted: Reconciliation 8. Execution Contract Database 1 owns it: a login's session, its login event log entry and its login event commit together, so no session outruns every record.
Deleted: Reconciliation 9. Execution Contract Database 1 owns it.
Reconciliation 10: The sweep MUST record a revocation-family event for a revoked session carrying none.
Deleted: Reconciliation 11. Execution Contract Database 1 owns it.
Reconciliation 12: The sweep MUST record a cascade abandoned event for an initiation carrying no completion.
Reconciliation 15: The sweep MUST record the stored-reason member for a revoked session carrying no revocation-family event.
Deleted: Reconciliation 16. Execution Contract Database 1 owns it.
Reconciliation 17: The sweep MUST call [Revoke Sessions For Credential] again for an abandoned initiation's credential id with the initiation's revoked by reference AND reason.
Deleted: Reconciliation 18. Execution Contract Database 1 owns it.
Reconciliation 19: The sweep MUST call a cascade again ONLY AFTER recording a recovery intent.
Reconciliation 20: The sweep MUST write the pair a map write failure event carries into both maps.
Reconciliation 13: The sweep MUST escalate a discrepancy the reconciliation window did not close.
Reconciliation 14: The sweep MUST NOT examine an event the substrate's horizon EXCEEDS.
Reconciliation 21: The sweep MUST match a login event log entry to the entry's mirrored event by the entry id.
```

Term revocation-family event: logout_succeeded | session_revoked_by_cascade — the exact family a revoked session's record must belong to.
Term stored-reason member: session_revoked_by_cascade where the stored reason begins with the cascade reason's prefix; logout_succeeded otherwise.
Term recovery intent: the login_recovery_intended event, carrying the initiation event's id the sweep is about to act on.

---

## Composition-level invariants

Each emerges from the composition; none belongs to one constituent.

- **Invariant 1 — Credential gates issuance.**
  ```
  Invariant 1.1: EVERY session token the session-to-credential map carries MUST follow Credential's verify answering verified.
  Invariant 1.2: The composition MUST NOT call Session's issue for a login Credential's verify refused.
  ```
- **Invariant 2 — Cascade completeness.**
  ```
  Invariant 2.1: EVERY session the cascade set carried AND Session's validate answered valid for AND the cascade did not count failed MUST stand terminal at the cascade's return.
  Invariant 2.2: The composition MUST NOT read a cascade as covering a session the cascade set did not carry.
  Invariant 2.3: The cascade set MUST carry the union of the map's entry AND the event-derived set.
  Invariant 2.4: A lost map entry MUST NOT shrink the cascade set.
  ```
- **Invariant 3 — Session-credential traceability.**
  ```
  Invariant 3.1: EVERY session-to-credential entry's credential id MUST equal the credential id the confirming read answered.
  ```
- **Invariant 4 — Login event log completeness.**
  ```
  Deleted: Invariant 4.2. Execution Contract Database 1 owns it.
  Deleted: Invariant 4.1. Composition state 10 owns it.
  ```
- **Invariant 5 — Audit trail completeness.**
  ```
  Invariant 5.1: EVERY login succeeded event MUST name a session token the rebuilt session-to-credential map carries.
  Invariant 5.2: EVERY session revoked event MUST name a session token the cascade found valid.
  ```
- **Invariant 6 — Map inverse consistency.**
  ```
  Invariant 6.1: The credential-to-sessions map AND the session-to-credential map MUST agree.
  ```

---

## Examples

### Successful login and session use

A user enters their password in a financial system. The host system calls `login(principal_ref: user_u91, credential_type: "password", presented_material: <raw-password>, issued_by_ref: login_svc_l01)`.

Step 2: `Credential.verify(user_u91, "password", <raw-password>) → verified`. Step 3: a query of the credential records returns `credential_id: cred_c01`. Step 4: `Session.issue(user_u91, login_svc_l01, 3600) → session_token: tok_abc123`. Step 5: `credential_to_sessions[cred_c01]` = `{tok_abc123}`; `session_to_credential[tok_abc123]` = `cred_c01`. Steps 6–7: `login_event_log` entry and Audit Trail login_succeeded event recorded. Return: `tok_abc123`.

The host system sets a session cookie. On the next request, the host system (or Privileged Access Provisioning) calls `Session.validate(tok_abc123) → valid(principal_ref: user_u91, expires_at: 2026-09-01T11:00:00Z)`.

### Failed login — wrong password

The user enters an incorrect password. `login(user_u91, "password", <wrong-password>, login_svc_l01)`. Step 2: `Credential.verify → failed-verification(material-mismatch)`. Step 2 path: `login_event_log` entry with `outcome: failed-verification(material-mismatch)`; Audit Trail login_failed event. Return: invalid-credential. No session is issued; no entry appears in `credential_to_sessions` or `session_to_credential`.

### Logout

The user clicks "Log out." The host system calls `logout(session_token: tok_abc123, revoked_by_ref: user_u91, reason: "user-initiated-logout")`. Step 2: `Session.revoke(tok_abc123, user_u91, "user-initiated-logout") → revoked`. Step 3: Audit Trail logout_succeeded (composition-attributed; `requested_by: user_u91` in the data). Return: ok. Subsequent `Session.validate(tok_abc123) → invalid(revoked)`.

### Cascading revocation — compromise response

An incident-response team determines that `cred_c01` (user_u91's password credential) was likely compromised. The identity-management surface calls `Credential.revoke(cred_c01, revoked_by_ref: security_team_s01, reason: "suspected-compromise-2026-09-12")`. The response team then calls `revoke_sessions_for_credential(credential_id: cred_c01, revoked_by_ref: security_team_s01, reason: "suspected-compromise-2026-09-12")`.

The composition first records `credential_revocation_cascade_initiated` event `ev_c01` for `cred_c01`, carrying the revoking reference and the reason, and only then reads the cascade set: `credential_to_sessions[cred_c01]` = `{tok_abc123, tok_def456}` (two sessions were issued over the credential's lifetime), and the trail names no other. For `tok_abc123`: `Session.validate → valid(...)` → `Session.revoke(tok_abc123, security_team_s01, "credential-revocation-cascade:ev_c01: suspected-compromise-2026-09-12") → revoked`; Audit Trail session_revoked_by_cascade. For `tok_def456`: `Session.validate → invalid(expired)` → skipped (dead by derivation; no revocation write needed). Audit Trail `credential_revocation_cascade_completed` naming `ev_c01` with the four counts. Return: `{revoked: 1, skipped: 1, failed: 0, not_found: 0}`.

Any subsequent Privileged Access Provisioning `exercise_access` call under `tok_abc123` will return `session-invalid` at step 1, before the Capability is presented.

### Regulated adversarial scenarios

Three scenarios the composition must survive in regulated contexts:

**Regulator audit.** A SOX (Sarbanes-Oxley Act) auditor asks *"was the session used to exercise access to the quarter-end journal approval control at 09:14 on 2026-10-15 established under a valid, non-revoked credential?"* The auditor reads the Privileged Access Provisioning `session_access_log` to find `session_token: tok_abc123` was used at that time. The auditor queries `session_to_credential[tok_abc123]` → `credential_id: cred_c01`. The auditor reads the Credential records: `cred_c01` was `Active` at `09:14` (it was revoked at `11:40` on the same day, after the access). The Audit Trail's login_succeeded event for `tok_abc123` shows `attempted_at: 2026-10-15T08:52:00Z`, `credential_id: cred_c01`, `principal_ref: user_u91` in its data. Invariant 1 (credential gates issuance) is the structural guarantee that the session could not exist without a prior verified credential. The auditor has their answer from the records alone.

**Disputed login event.** A user claims *"I did not log in from that location at 03:00 AM on 2026-11-20."* The investigator queries the `login_event_log` for `principal_ref: user_u91` on that date. The entry shows `attempted_at: 2026-11-20T03:00:12Z`, `outcome: success`, `credential_id: cred_c01`, `session_token: tok_xyz789`. The Audit Trail's login_succeeded event corroborates the timestamp and credential used. Credential's Invariant 3 (sole-holder verification) means the presented material matched the verifier registered for user_u91's password credential — the login succeeded because someone presented the correct password. Whether that was the legitimate user or an attacker with the compromised password is a separate investigation; Login's records bound the forensic window: the session was issued at `03:00:12Z` after a successful credential check.

**Breach investigation — cascade completeness.** A security team is investigating a credential compromise. They ask *"how many active sessions were revoked when we cascaded the revocation of cred_c01, and is there any evidence that any session slipped through?"* The Audit Trail shows `credential_revocation_cascade_initiated` event `ev_d07` at `2026-12-03T14:22:00Z` for `cred_c01`, five session_revoked_by_cascade events each naming a distinct session token, and `credential_revocation_cascade_completed` naming `ev_d07` with `{revoked: 5, skipped: 0, failed: 0, not_found: 0}`. The completion event is what `Check 4.1` reads first; without it the initiation owes an abandoned event. There are no login_map_write_failure events for `cred_c01`, so the cascade set was the map's entry alone, and `credential_to_sessions[cred_c01]` shows the same five, each now `Session.validate → invalid(revoked)`. Invariant 2 is the structural guarantee behind the count: every session the set carried and validate found live stands terminal, and a zero failed count leaves none for a second cascade.

---

## Generation acceptance

An implementation is acceptable when an external auditor, given the credential records, the session records, the substrate's trail, the two maps and the login event log, can clear the checks below without recourse to source code, runbooks or developer narration.

### Conformance checks

```
Check 1.1: An auditor MUST find EVERY login succeeded event naming a session token the session-to-credential map carries (Invariant 5.1).
Check 1.2: An auditor MUST find EVERY session-to-credential entry naming a credential id the credential records carry (Invariant 3.1).
Check 2.1: An auditor MUST find the credential-to-sessions map AND the session-to-credential map agreeing (Invariant 6.1).
Check 2.2: An auditor MUST rebuild both maps from the substrate's login-family events (Composition state 7).
Check 2.3: An auditor MUST find EVERY map write failure event's session token carrying EXACTLY ONE OF an entry in both maps, an invalid answer from Session's validate (Action wiring 11).
Check 3.1: An auditor MUST find EVERY login call reaching an outcome carrying one login event log entry (Composition state 10).
Check 3.2: An auditor MUST find EVERY login event log entry's outcome matching the mirrored event's action reference (Composition state 10).
Check 3.3: An auditor MUST rebuild a principal reference's session set from the login event log (Composition state 10).
Check 4.1: An auditor MUST find EVERY cascade initiation event carrying EXACTLY ONE OF a completion event, an abandoned event (Reconciliation 12).
Check 4.2: An auditor MUST find EVERY session revoked event naming a session the cascade set carried (Invariant 5.2).
Check 5.1: An auditor MUST find EVERY revoked session under the issuer references carrying a revocation-family event (Reconciliation 10).
Deleted: Check 5.2. Execution Contract Database 1 owns it.
Check 6.1: An auditor MUST find EVERY audit event of the composition attested under the service identity (Composes 12).
```

NOTE: EVERY check names the rule the check tests.

### External checks

```
Deleted: External check 1. Execution Contract Database 3 owns it.
External check 2: An auditor needing the issuer references confirmed MUST read the deployment's own declaration (Capability requirement 10).
Deleted: External check 3. Execution Contract Database 1 owns it.
External check 4: An auditor needing the service identity's provisioning confirmed MUST read the substrate's actor registry (Capability requirement 8).
External check 5: An auditor needing a constituent's own guarantee confirmed MUST read the constituent's own acceptance (Composes 5).
External check 6: An auditor needing the substrate's own guarantee confirmed MUST read Audit Trail's own acceptance (Composes 6).
```

---

## Non-goals

```
Non-goal 1: The composition MUST NOT register a credential.
Non-goal 2: The composition MUST NOT rotate a credential.
Deleted: Non-goal 3. Wiring decision 3 owns it.
Non-goal 4: The composition MUST NOT offer Session's validate.
Non-goal 5: The composition MUST NOT authorize an action.
Non-goal 6: A deployment needing an authorized action MUST compose Permissions.
Non-goal 7: The composition MUST NOT bound a principal reference's concurrent sessions.
Non-goal 8: The composition MUST NOT renew a session.
Non-goal 9: The composition MUST NOT bind a session to a device.
Non-goal 10: The composition MUST NOT limit a login's rate.
Non-goal 11: The composition MUST NOT hold a second factor.
Non-goal 12: The composition MUST NOT adopt a session issued outside the issuer references.
Non-goal 13: The composition MUST NOT revoke a session issued outside the issuer references.
Deleted: Non-goal 14. Invariant 2.2 owns it.
```

NOTE: the owners — [Session](../atoms/session.md), whose validate callers call directly (Non-goal 4); the surface that issued a session outside the issuer references (Non-goal 12, Non-goal 13).

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

---

## Terms

The canonical concepts this spec refers to. Each `term` marker in the prose above links to its term entry here. A term entry states what the concept *is*, in plain English, plus its **Kind** — one of five: **Type** (a thing or category), **Operation** (a behavior), **Member** (a value of an enumerated Type), or, for a named datum, **Field** (a datum a Type carries — *what does it carry?*) or **Parameter** (a value an Operation needs — *what does it need?*). A term entry also names the Type it is a **Member of** / **Field of**, the Operation it is a **Parameter of**, and its **Role** where the domain assigns one. A term entry carries one **Projection** line — the concept's single canonical lowering token, the one place the concrete name stays visible on the page — for every Field, Parameter, and pinned/wire Member. Everything else about casing (each target's snake / camel / pascal / const / wire form) is **derived** from that one token by [`tools/harness/term-adapter.mjs`](../tools/harness/term-adapter.mjs), never hand-written. This is a composition, so its own concepts are the emergent cascade action it exposes ([Revoke Sessions For Credential]) — the load-bearing surface neither constituent provides — its own login rejection ([Invalid Credential]), the distinctive `login_event_log` classifications it records ([Outcome], with its [Success With Map Failure] and [Failed Storage Failure] members), and the cascade result's integrity-gap counter ([Not Known]). The two eponymous thin-wrapper actions — login (verify → issue) and logout (revoke) — are left backticked (their names would also collide with the page heading and the *Logout* example anchor). Its emergent state — the cascade maps (`credential_to_sessions`, `session_to_credential`) and the `login_event_log` — is a composition-introduced surface no constituent provides, left as backticked record tokens. References to the constituent atoms and their operations — Credential's `verify` / `register` / `revoke`, Session's `issue` / `revoke` / `validate`, Audit Trail's `record_action` — the relayed tokens (principal reference, credential id, session token, credential type), the constituent states (`Active` / `Revoked`, and the derived `Expired` effective status), the Audit Trail event types (login_succeeded, session_revoked_by_cascade, …), and the inherited rejections (invalid-request, not-known, already-terminal, storage-failure) remain qualified/backticked, not carded here. *(annotation.md Terms registry; representational only — it changes no guarantee, invariant, or behavior of the composition above.)*

### Vocabulary

Term qualifiers: migrated — rewritten in GRACE lang v0.40 (2026-09-14).

Term terms: composition, constituents, service identity, credential-to-sessions map, login event log, login-family events, seam, transition, issuer references, blank, opaque input, admitted login, admitted logout, admitted cascade, cascade set, revocation-family event, login result, revocation tally.

Term record verbs: call, answer, read, write, append, store, key, hold, remove, change, rest, rebuild, record, retry, re-emit, close, escalate, examine, revoke, issue, gate, cascade, verify, attest, carry, select, query, offer, serve, compose, inherit, declare, set, configure, provision, rotate, own, act, adopt, bound, renew, bind, authorize, register, count, stand, follow, name, equal, agree, match, find, persist, generate, mint, normalize, compare, skip, union, supply, take, alert, run, limit, shrink.

Term actors: the composition; the constituents; the substrate; the host; the transition; a deployment; an auditor; a caller; a principal; the sweep; a session; a credential; an event.

Term cited: Execution Contract Conformance 8 — recursive conformance and the inherited guarantee. The section titled Composition state in `execution-contract.md` — the derived-index and extraction-pending classifications. The section titled Substrate composition invocation in `execution-contract.md` — what naming a composition as a constituent means at runtime. The section titled Logic Confinement Principle in `execution-contract.md` — the seam and the transition. record_action, action reference: Audit Trail.

#### Revoke Sessions For Credential

The composition's load-bearing emergent action: given a credential id, it reads the cascade set — the map's entry and the pairs the trail carries — and revokes every still-`Active` derived session through `Session.revoke`, recording an initiation event, one event per session it acted on (already-terminal sessions are counted, not recorded), and a completion event carrying the counters. Returns `{revoked, skipped, failed, not_found}` (the snapshot accounting), or an inherited rejection. Called *after* an external `Credential.revoke`; it never revokes the credential itself. Neither constituent carries this cascade.

Kind: Operation

#### Invalid Credential

The composition's own login rejection — returned when `Credential.verify` fails (`failed-verification(reason)`): the credential check did not pass, so no session is issued and a failed-login event is recorded. The observable form of the credential-gates-issuance boundary (Invariant 1).

Kind:       Member
Member of:  the login rejection
Role:       Rejection
Projection: invalid-credential

#### Outcome

The `login_event_log` entry's classification of a login call: one of `success`, [Success With Map Failure], `failed-verification(reason)`, or [Failed Storage Failure]. Every login call appends exactly one entry (Composition state 10), giving the composition a records-alone query surface alongside the tamper-evident Audit Trail.

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

The [Outcome] for a login call that failed at a named stage after credential verification: `credential-id-lookup`, `credential-id-confirm` or `session-issue`, before a session was issued, or `login-event-log`, after it — the token is withheld. Carries the stage; the session token is null.

Kind:       Member
Member of:  the login outcome
Role:       Outcome
Projection: failed-storage-failure

#### Not Known

The [Revoke Sessions For Credential] counter for a data-integrity gap: a session token present in `credential_to_sessions` but absent from the Session records (`Session.validate → invalid(not-known)`). Distinct from skipped (already-terminal sessions); each increment writes a `session_not_found_during_cascade` event for investigation.

Kind:       Field
Field of:   the cascade result
Role:       the integrity-gap count
Projection: not_found

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a term marker to its term entry heading above (kramdown
     auto-generates the heading anchors on GitHub Pages). Standard CommonMark /
     kramdown; no plugin required. -->

[Revoke Sessions For Credential]: #revoke-sessions-for-credential
[Invalid Credential]: #invalid-credential
[Outcome]: #outcome
[Success With Map Failure]: #success-with-map-failure
[Failed Storage Failure]: #failed-storage-failure
[Not Known]: #not-known

---

## Standards references

- **NIST (National Institute of Standards and Technology — US federal standards body) SP 800-63B section 7 (Session Management)** — the primary standard for session lifecycle in authenticated systems. The composition's `login → Session.issue` wiring implements the session binding requirement; `logout → Session.revoke` implements the session termination requirement. The [Revoke Sessions For Credential] cascade implements the reauthentication-on-credential-change requirement: when a credential is revoked, all dependent sessions must be terminated.
- **NIST SP 800-53 AC-12 (Session Termination)** — requires that sessions terminate after a defined condition. The composition's logout and [Revoke Sessions For Credential] actions are the two termination surfaces; the expiry instant immutability of Session is the time-bounded termination mechanism.
- **OWASP ASVS V3.1 (Authentication) and V3.3 (Session Termination)** — the OWASP (Open Worldwide Application Security Project) Application Security Verification Standard; the login action's sequencing (verify then issue, with failed attempts recorded) and logout's full revocation (not just cookie deletion) correspond to ASVS requirements for authentication event logging and session invalidation on logout.
- **GDPR (EU General Data Protection Regulation — the European Union's data-privacy law) Article 32 (Security of Processing)** — the `login_event_log` and Audit Trail recording of all authentication events, including failures, contribute to the "appropriate technical measures" Article 32 requires. The [Revoke Sessions For Credential] cascade is a breach-response mechanism that reduces the blast radius of a compromised credential.
- **HIPAA (US Health Insurance Portability and Accountability Act) section 164.312(d) (Person or Entity Authentication)** — the composition's `Credential.verify → Session.issue` wiring is the structural implementation of this requirement: a session is issued only after the principal's identity is confirmed. The Audit Trail records the authentication event for post-incident investigation.
- **PCI DSS (Payment Card Industry Data Security Standard — the card networks' mandatory security rules for cardholder data) Requirement 8.2 (User Identification and Authentication)** and **Requirement 8.6 (Session Management)** — authentication event logging (all login attempts, successful and failed), session termination on logout, and revocation on credential change correspond to PCI DSS structural requirements. The `login_event_log` is the composition-layer record; the Audit Trail is the tamper-evident external-auditor record.
- **SOX section 302 / section 404 (Internal Controls)** — the `credential_to_sessions` map and its cascade action are the structural mechanism for ensuring that a compromised credential's access window can be closed completely and auditedly. An auditor can verify cascade completeness from the Audit Trail records alone without consulting the incident-response team.
- **OpenID Connect Core 1.0** — the composition is the Grace Commons expression of the OIDC (OpenID Connect — an identity layer built on OAuth 2.0) login flow: authorization code exchange (credential verification), session establishment (session issuance), and session revocation on logout or token revocation. The atoms' principal reference maps to the OIDC `sub` claim.

Inherited from:

- **Daniel Jackson, *The Essence of Software*** — the freestanding-atom posture that makes the cascade an emergent property of the composition rather than a feature bolted onto either Credential or Session.
- **NIST 800-63B section 4 (Authenticator and Verifier Requirements)** — the upstream standard for Credential's verifier-not-material storage discipline, which this composition inherits transitively.

---

## Status

`partially resolved` — see the Ledger.

## Ledger

```
status: partially resolved
formal: verified — login.tla, no twin, 2026-05-23
last gate: 2026-08-28 — second gate after closure, fresh reader — 5 foundational (all since closed), 16 refining (2 since closed), 3 rhetorical

open:
- 2026-08-29-a · refining · formal · the model's sweep carries no upper edge and no recovery record → extend it
```

## Decisions

Directional changes only — the turns a future reader must know the pattern took, and why. Everything smaller lives in the commit that made it: `git log -- compositions/login.md`; the migration, the family placement, the restoration and the reading of the gate's open lines that got it here are in [its history](./login.hist.md).

- **2026-08-28 — The cascade writes its join key into the Session record, and what cannot be re-emitted is re-run.** *Chose:* step 5b's revoke reason carries `initiation_event_id`, so a sweep re-emission carries the real id and check 3 counts it; the completion event waits for every per-session record; an initiation that dies without completion is abandoned and the cascade re-run. *Over:* re-emitted events with `initiation_event_id: null` excluded from the arithmetic, and a claim that the sweep re-derives every owed record. *Because:* a failed revoke and a not-found token leave nothing in any store to re-derive a record from, so the claim was false; re-running is the only honest closure, and the join key in the reason makes the re-emittable records exact rather than excused.
- **2026-08-29 — The sweep is bounded above as well as below, and records its intent before it revokes or re-runs.** *Chose:* every comparison scoped to the audit horizon, past which a missing event is destruction and the record is reported purged rather than repaired; a `login_recovery_intended` event before the second comparison's revoke and the fourth's re-run; `reconciliation_window` and `reconciliation_cadence` declared. *Over:* the age-bounded sweep of 2026-08-28 with no upper edge. *Because:* a comparison past the horizon revokes sessions whose issuance events aged out and re-emits logouts the purge lawfully removed, and a sweep that revokes with no record of its own is indistinguishable from a direct call (the frozen rules of 2026-08-29 — *A reconciliation is bounded at both ends*, *Recovery commits under a declared service identity*).
- **2026-08-28 — The sweep is age-bounded and `login_event_log` is extraction-pending against Event Log.** *Chose:* a declared `login_completion_bound` below which the sweep examines nothing, and the log classified as the composition's own call journal pending extraction, durable now. *Over:* an unbounded sweep and a "conditional derived index". *Because:* the unbounded sweep revoked logins still in flight, and the invented classification let a generator hold the sweep's only intent in memory.
- **2026-08-26 — Every Login event is composition-attributed.** *Chose:* attest under `application_actor_ref` / `application_credential`, with the human parties in `data`. *Over:* attesting under the principal's own credential. *Because:* Login's callers are end principals whose material is the thing under test, not registry actors — and a failed login has no valid credential to attest with. This governs every audit write the pattern makes.
- **2026-08-26 — Invariant 2 promises less than it did.** *Chose:* cascade completeness is claimed only for verifies that committed after the revocation, with the in-flight window named and a second cascade prescribed after quiescence. *Over:* single-cascade sufficiency. *Because:* a login whose verify committed before the revocation can land its session after the cascade's snapshot, and no single cascade can see it. The headline guarantee is narrower and true.

- **2026-09-14 — The first composition to name a composition as a constituent.** *Chose:* `Composes 6` and `Composes 7`, citing the section titled Substrate composition invocation in `execution-contract.md`, with `External check 6` sending an auditor to [Audit Trail](./audit-trail.md)'s own acceptance rather than re-verifying it here. *Over:* listing Event Log, Actor Identity, Retention Window and Tamper Evidence as this composition's constituents, which is what the atom-only reading of `Composes` would have produced. *Because:* the substrate's guarantees are inherited by reference — that is the point of naming a substrate — and re-listing its constituents would have claimed instances this composition does not hold. The corpus composes compositions and this is the first migrated spec where the rule surface has to say so.

- **2026-10-21 — The store's guarantees cited, not restated, the orphan-session comparison among them.** *Chose:* the store supplied under Execution Contract Store 1 through 4 (Capability requirement 18), and the seventeen rules that restated it, or existed only for a store that could lose or split a write, tombstoned to their owner — to Store 1, under which a login's session, its login event log entry and its login event commit together: the sweep's revoke of a session no record names, with its event, its reason, the boundary rule reserving that reason, its recovery intent and the invariant making the gap the sweep's (Reconciliation 8, 9, 16, 18, Primitive policy 14, Invariant 4.2), the lower edges below which the sweep examined no session and no cascade initiation, the login completion bound they read and its external check, and the auditor's twin of the orphan comparison (Reconciliation 6, 11, Capability requirement 14, External check 3, Check 5.2), and the invocation's own retry of a recording failure (Audit arm 1); to Store 1 and Store 3, the sweep's run at an instance's start and an owed record derived again at a restart (Reconciliation 1, Audit arm 3); to Store 3, the login event log's durability across a restart and its external check (Composition state 11, External check 1); and to Store 3 and Store 4, the bar on rebuilding the log at a restart (Composition state 12); with them Check 3.3 rebuilds a principal reference's session set from the log alone and Check 4.1 reads every cascade initiation, not only one older than the bound; rules 187 to 171. *Over:* a session committed apart from its records and found by a sweep once it outlived a declared completion bound, revoked under a reserved reason, and a login event log held across a restart by a rule of its own — the turns of 2026-08-28 and 2026-08-29, above. *Because:* the maintainer ruled 2026-10-12 that the corpus takes a store's specification, never the store, and 2026-10-20 that Store 1 binds every store write of one composition action, its constituents' included: Session's records, the login event log and the audit trail's records are one store, so a login that stops commits nothing and a login that commits leaves its session, its entry and its event together. The other calls a rule decided: the two maps stay a derived index outside the action's atomicity surface (obligation 2 of the section titled Composition state in `execution-contract.md`, which the ruling left as it was), so the maps' own transaction, the map write's failure arm and its event, the cascade's union read, the sweep's backfill and the check that waits on it stay (Composition state 3, 8, Action wiring 10, 11, 18, Reconciliation 20, Invariant 2.3, 2.4, Check 2.3); the audit trail's invalid-request at a record still leaves the action's other writes committed and the record owed, or at step-4 landed (Audit arm 9 through 12), so the re-emission, the comparison of revocations against their events and the cascade's abandon-and-re-run stay (Reconciliation 5, 10, 12, 15, 17, 19); and no kept rule reads a record's earlier version or compares two commits, so Store 5 and Order 1 are not cited. What the composition does for its domain is otherwise unchanged.

NOTE: End of Login.
