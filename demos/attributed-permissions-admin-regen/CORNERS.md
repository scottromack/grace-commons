# CORNERS — Attributed Permissions Admin, cold regeneration

Findings and preferences from regenerating the demo from today's specs. A **finding** names a contradiction or a gap inside the specs and goes to the review channel; a **preference** is a choice where the specs leave room (the section titled *Implementation-discovered findings* in `contributing.md`).

---

## Findings

**1. Permissions declares no read, and the composition relies on one.** Permissions' Operations block declares `grant`, `revoke` and `permitted` and nothing else. The composition reads the grant "through Permissions' declared read" (Action wiring 55), enumerates a pair's active grants "through Permissions' declared read" (Action wiring 42), and forbids reading the store beside the declared read (Composes 6). Permissions' own Deprovisioning 2 asks a composing pattern to enumerate a subject's active grants, through a surface the atom does not offer. This render adds `read` and `activeGrants` to the atom and marks them as undeclared.

**2. Actor Identity declares no enumeration, and the composition relies on one.** Actor Identity declares `attest` and `verify`. Composes 20, Housekeeping 2 and Check 5.1 enumerate attestations "through Actor Identity's declared enumeration". This render adds `enumerate` and marks it as undeclared.

**3. The boundary trims credentials, and a credential is not to be inspected.** The Term *opaque input* lists the grantor's and the revoker's credentials; Primitive policy 6 through 8 trim every administered opaque input and pass the trimmed value on. Primitive policy 12 says the composition MUST NOT inspect a credential. A credential with surrounding whitespace reaches Actor Identity rewritten. This render trims, as Primitive policy 6 says, and records the conflict.

**4. The failed-grant leg is told not to examine what it is told to report.** Housekeeping 15 says the leg MUST NOT examine an aged-out attestation; Housekeeping 16 and 17 say it MUST report an aged-out unpaired attestation as a purge-pending orphan or a non-conformant purge. This render reads Housekeeping 15 as "does not report it as an ordinary orphan" and reports the two horizon readings.

## Preferences

- **A pairing refused under a transaction.** The rollback takes the grant with it, so the answer is `orphan-attestation` at `pre-grant`. The orphan log entry still carries the grant handle the pairing step held (Composition state 20), though no grant stands under it.
- **Reaching the `post-` positions.** Under the atomicity this render supplies they cannot happen. `Faults.nonAtomicHost` stands in for a host that does not honour it, so the tests can show the ordered partial and `verify_grant_attribution` answering `attribution-inconsistency`.
- **A pair-scoped revocation whose attest cannot be stored** counts that grant as remaining, so the answer is `partially-revoked`; the signature carries no `attribution-storage-failure` for this action. A grant skipped as `not-active` appears in neither list.
- **The credential mechanism** is an HMAC over the action and actor references under the actor's registered secret; a credential validates when it equals that secret.
- **The purge** is the retention layer's act, not the composition's, so the tests delete attestations directly to stand in for it.

---

## Against the 2026-05 render

The old render's `CORNERS.md` predicted four differences. All four hold:

- It refuses `duplicate-active-grant` and backs it with a unique index on the pair; this render issues the second grant (Wiring decision 8).
- It answers `credential-invalid`, `grantor-not-found` and `revoker-not-found`; this render answers `invalid-credential`.
- It answers the orphan's cause; this render answers `orphan-attestation` with the position and logs the cause.
- It has no `revoke_permission`; this render does, with Invariant 9 tested.

The regeneration found eight more, none of them predicted:

- **The attest runs inside the grant's transaction**, so a failed grant rolls the attestation back. Wiring decision 3 forbids enclosing the two; the old render's own `CORNERS.md` records this as a preference.
- **The composition mints the grant handle** (`ulid()` in `issue_grant`); Capability requirement 6 forbids it.
- **The revocation reads the grant before attesting**, to build the proposal from its scope and subject; Primitive policy 17 forbids it.
- **The proposals carry no nonce, no namespace prefix and no request instant**, and the revocation proposal carries the scope and subject instead of the grant handle (Capability requirement 10, 11 and 13; Identity 7, 11 and 12).
- **The boundary trims only to test for blank**, passes the untrimmed value on, refuses no blank credential and sets no length cap (Primitive policy 3, 4 and 8).
- **Refusal tokens carry field suffixes** (`invalid-request:subject_ref-empty`) and an `unknown-error` the signatures do not carry.
- **The two maps are not held disjoint** (Invariant 7.3); each map's attestation is unique within the map only.
- **Nothing reads a purge record** or reports `registry-unavailable`, and there is no failed-grant leg (Action wiring 62 through 67 and 75; Housekeeping).

The old render also cited its formal model at an `alloy/` path that does not exist; the model is `compositions/attributed-permissions-admin.als`, and the citations are corrected.

Test counts are not comparable: the old render's 35 tests cover its HTTP routes and login sessions as well as its domain; this render's 28 cover the domain only.
