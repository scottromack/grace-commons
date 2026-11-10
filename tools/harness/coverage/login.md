# Coverage matrix — `login`

- **Pattern:** `compositions/login.md`
- **Model:** `login.tla` + `login.cfg` (TLA+; one `Safety` invariant, no `PROPERTY`; no buggy twin, no static Alloy model)
- **Reviewer / date:** mayor, from the page at fc78924 and the model as it stands — 2026-11-10 (unit `formal: more coverage for the yes votes`, step 1; the page had no matrix)
- **Formal-layer vote load-bearing claims:** the Ledger reads `formal: verified — login.tla, no twin, 2026-05-23`; the model header names the credential gate, cascade completeness (including the Final Critique 1 Logout-versus-cascade interleaving), map inverse consistency and cascade audit ordering.

## Step 1 — harness run

- Correct model: `node check.mjs ../../compositions/login.tla` → `HOLDS` ✓ (1,188 states, TLC, 2026-11-10).
- Buggy twin: none. A model with no twin has not shown that any of its checks can fail; every row below marked **covered** is therefore a check no twin has yet rejected.

## Step 2 — coverage matrix

One row per numbered rule of *Composition-level invariants* (the page's numbering at fc78924). The model's own invariant names follow an older numbering (its "Invariant 4" is the event log, its "Invariant 5" the cascade order), so the table cites the model's names.

| Spec claim | Load-bearing (vote)? | Verdict | Model construct / reason |
|---|---|---|---|
| Invariant 1.1 — every token in the session-to-credential map follows a `verify` of `verified` | yes | by-construction | `Login` and `LoginMapWriteFailure` guard on `cred_status[cred] = "active"`; `Credential_Gates_Issuance` checks only that an issued session maps to some credential and has a log entry, a proxy that cannot see a session issued while the credential was refused. `Credential.verify` is modeled as the guard (header: "modeled as a guard"). |
| Invariant 1.2 — no `issue` call for a refused `verify` | yes | by-construction | The same guard: no action issues without an active credential. A twin that drops the guard would break `Cascade_Completeness` only through a later cascade, and no check names the claim directly. |
| Invariant 2.1 — every session the cascade set carried and `validate` answered valid for stands terminal at the cascade's return | yes | **covered** (cascade set = `cred_to_sessions`) | `Cascade_Completeness` (every session the cascade acted on is terminal) and `Cascade_Coverage` (no session in `cred_to_sessions[c]` stays active once `c` is initiated). Logout racing the cascade (Final Critique 1) is an interleaving TLC explores: `Logout` is its own action. |
| Invariant 2.2 — no cascade read as covering a session its set did not carry | yes | **GAP** → owed (b) | The model's cascade set is exactly `cred_to_sessions[cred]`, so "a session outside the set" is any `map_write_failed` session, which the model leaves active after the cascade and excludes from `Cascade_Coverage`. The claim that the cascade's return does not cover it is not asserted; the model only states the exclusion. |
| Invariant 2.3 — the cascade set carries the union of the map's entry and the event-derived set | yes | **GAP** → owed (b) | The model has no event-derived set. `RevokeSessionsForCredential` snapshots `cred_to_sessions[cred]` only; `log_sessions` is recorded but never read by the cascade. The page's current text (Wiring decision 2 and 4, Reconciliation 17 and 20) is not what the model checks: the model describes the cascade as it stood before the event-derived union. |
| Invariant 2.4 — a lost map entry does not shrink the cascade set | yes | **GAP** → owed (b) | The model *does* shrink it: a session from `LoginMapWriteFailure` is absent from `cred_to_sessions` and so from the cascade, and stays `active` for a revoked credential. Under the page's Invariant 2.1 and 2.4 that state is a violation; the model passes only because its cascade is the older one. |
| Invariant 3.1 — each session-to-credential entry's credential id equals the id the login's `read` answered | yes | out-of-scope (named reason) | `session_to_cred` is written once, from the `cred` argument; the model has no separate `read` answer to differ from it, so equality is true by the schema. `Session_Credential_Traceability` checks only that an entry names a real credential id. Immutability after write holds by inspection of `Next` (the header says so); not asserted. |
| Invariant 5.1 — every login succeeded event names a token the rebuilt map carries | yes | **covered** in part, rest out-of-scope | `Login_Event_Log_Completeness` (every issued session has a log entry) states the entry exists; the "rebuilt map" half, and the event's contents, are Audit Trail's (a); this page's Reconciliation rebuilds the map, which the model has no action for. |
| Invariant 5.2 — every session revoked event names a token the cascade found valid | yes | **covered** (proxy) | `Cascade_Audit_Ordering` (a cascade-revoked session's credential is in `cascade_initiated`) and `Cascade_Completeness`; `RevokeSessionsForCredential` adds only sessions that were `active`. The ordering of the event against the revoke is a step claim over one atomic action. |
| Invariant 6.1 — the two maps agree | yes | **covered** | `Map_Inverse_Consistency`, both directions, with the `map_write_failed` exclusion the page's edge case names. |
| Invariants 4.1, 4.2 | — | deleted | The page deleted both (Composition state 10; Execution Contract Database 1). |

Out-of-scope residual, named: Audit Trail's own completeness (this page's Invariant 5 delegates to `compositions/audit-trail.tla`, covered there); `Credential.verify`'s internals; storage failure of the session write (the action does not fire); cross-system clock skew (one logical clock); the order of the cascade's per-session revokes (the model's cascade is one atomic step).

## Step 3 — bound saturation

Checked at 2 credentials, 3 session tokens and `MaxClock = 3`: 1,188 states. Not raised in this pass; a rerun at `MaxClock = 4` is owed with the rederived model, since the cascade changes the space.

## Outcome

- GAP rows: Invariant 2.2, 2.3 and 2.4, one cause — the model's cascade set is the credential-to-sessions map alone, where the page's cascade set is the union with the event-derived set. This is model drift, not a page defect: the English says what the cascade must do, and the model checks an older cascade.
- by-construction flags on load-bearing claims: Invariant 1.1 and 1.2 (a guard, no check that fails when the guard goes). Both want a twin that issues without the guard.
- Owed (step 2 of the coverage unit): **(b)** Invariant 2.2, 2.3 and 2.4 — add an event-derived set (the sessions the log shows issued for the credential) to the cascade, make `LoginMapWriteFailure` leave a session the cascade still reaches, and check that no session of a revoked credential stays active; the twin drops the union. **(b)** Invariant 1.1 and 1.2 — a twin that issues for a revoked credential, and a check that no session is `active` against a credential not active at its issue. **Tool owed** (step 2c): Login has no Alloy model; its claims are stateful, so none is owed under 2c unless writing one finds a static claim the page states.
- Result: **findings routed** — three rows owed (one cause) and two by-construction flags. Coverage cross-check 2026-11-10 — no defect in the English.
