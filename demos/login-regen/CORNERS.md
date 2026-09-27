# CORNERS — Login, cold regeneration

Findings and preferences from regenerating Login from today's specs. A **finding** names a contradiction or a gap inside the specs and goes to the review channel; a **preference** is a choice where the specs leave room (the section titled *Implementation-discovered findings* in `contributing.md`).

---

## Findings

All closed in the spec on 2026-09-27 (council read 234); the render follows the closed page. The page's Ledger lines were left as they stand.

**1. The 2026-09-14 rewrite dropped decided content.** Its Decisions entry says nothing but language changed. The build met ten points the page left undecided, and the prose spec before the rewrite — and this page's own Decisions of 2026-08-28 and 2026-08-29 — had decided each:

- what logout answers when Session's revoke answers already-terminal, storage-failure or invalid-request — the signature carried only not-known (now Action wiring 27 through 29);
- where login lands when the first credential read finds nothing, or Session's issue fails — the stages were named only in a term entry (Action wiring 30, 31);
- what a cascade answers when its initiation event cannot be recorded — the signature carried only invalid-request (Action wiring 33);
- what the initiation carries, and the join key the revoked Session record keeps, which the page's own 2026-08-28 decision names (Action wiring 32, 34; the cascade reason);
- the not-found count and its event, which the page's own term entry kept, and the failure event (Action wiring 35, 36; the revocation tally);
- the names of the six cascade events (the cascade events);
- which revocation-family member the sweep records for a revoked session carrying none (Reconciliation 15);
- the reason the sweep revokes an orphan under (Reconciliation 16);
- that an abandoned cascade runs again, which the page's 2026-08-28 decision names (Reconciliation 17);
- the recovery intent before a sweep revoke or re-run, which the page's 2026-08-29 decision names (Reconciliation 18, 19).

Where the rewrite changed a design on purpose — the credential id read twice around the session, not the credential verified twice — the rewrite's design stands.

**2. Check 2.3 waited on a backfill no rule wrote.** It expects a map write failure's pair to end in both maps or in a dead session; nothing wrote the pair. *Closed:* Reconciliation 20.

**3. Check 3.1 cited a deleted invariant.** It cited Invariant 4.1, which is a tombstone. *Closed:* it cites Composition state 10.

**4. The examples had drifted from the signatures.** Logout was called with `actor_ref` and answered `logged-out`; the cascade's initiation carried a session count the set is read only after; the tally said `failures`. *Closed:* the examples follow the signatures.

## Preferences

- **Audit arm 1's retry** is one retry inside the call; the sweep owns every record still owed.
- **The key between a login event log entry and its mirrored event** is the entry's id, carried in the event's data. The page names none (Ledger 2026-08-27-k).
- **The cascade's boundary refuses a blank credential id, revoking reference or reason.** Primitive policy names four inputs and none of these; Session would refuse the blanks one session at a time.
- **Session's invalid-request at issue** is relayed as invalid-request with no login event log entry; it is not one of the four outcomes.
- **Issued-by membership in the issuer references** is not checked at login (Ledger 2026-08-28-e).
- **The open-ended read starts at sequence one** (Ledger 2026-08-28-g).
- **The sweep leaves an owed entry younger than the login completion bound**, as it leaves a young session.
- **The derivation function** is a SHA-256 stand-in for the deployment's password function.

---

## Against the portal's login

The portal's drift section predicted one difference: it answers `invalid_credentials` and records the cause as audit detail. It holds.

The regeneration found seven more, none of them predicted:

- **No cascade.** There is no `revoke_sessions_for_credential` and no credential-to-session maps, so a revoked credential leaves its sessions live (Wiring decision 2).
- **No login event log** (Composition state 9).
- **The login is attributed to the user.** `login.succeeded` is written as the logged-in actor and `login.failed` as no one; every Login event is the service identity's, with the human party in the data (Composes 12 through 14).
- **The session and its audit event commit in one transaction,** so an audit fault denies the login; the spec returns the session and owes the record (Audit arm 3).
- **The composition verifies the password itself,** reading the stored hash; the spec gates on Credential's verify, and Credential's read never answers a verifier (Action wiring 1; Credential Operation 53).
- **The composition mints the token and reads the clock,** where the host injects both (Capability requirement 1 and 4; Session Operation 49).
- **No sweep** (Reconciliation 1 through 20).
