# Coverage matrix — `privileged-access-provisioning`

- **Pattern:** `compositions/privileged-access-provisioning.md`
- **Model:** `privileged-access-provisioning.tla` + `privileged-access-provisioning.cfg` (TLA+; two requests, three approvers, two tokens, quorum 2; INVARIANTs TypeOK, ApprovalGatesProvisioning, MapInverseConsistency, CascadeFiresAtMostOnce, TokensAllocatedOnlyForProvisioned, NoPendingRequestHasToken, ExhaustedSubsetAllocated; `ACTION_CONSTRAINT TerminalAbsorbingAction`; no PROPERTY; no buggy twin)
- **Reviewer / date:** mayor, from the page at fc78924 and the model as it stands — 2026-11-10 (unit `formal: more coverage for the yes votes`, step 1; the page had no matrix)
- **Formal-layer vote load-bearing claims:** the model header names four: approval gates provisioning, the cascade fires at most once, terminal states are absorbing, the two maps are strict inverses; a fifth, `EventuallyTerminal` (under weak fairness a request with enough approvals reaches a terminal state), is written in the file and commented out.

## Step 1 — harness run

- Correct model: `node check.mjs ../../compositions/privileged-access-provisioning.tla` → `HOLDS` ✓ (1,682 states, TLC, 2026-11-10).
- Buggy twin: none. The Ledger says "no twin". Every check below marked **covered** is one no twin has shown able to fail.
- **Two defects in the model file itself**, found by reading the cfg against the file: (1) `TerminalAbsorbingAction` is listed as `ACTION_CONSTRAINT` in the cfg. An action constraint *prunes* the explored transitions to those satisfying it, so it asserts nothing: a transition out of a terminal state is silently never explored. The file's own comment says to add it under "Action Properties" (`PROPERTY`). The terminal-absorbing claim is therefore uncovered, not covered. (2) `TerminalAbsorbing` (the state predicate) is a tautology (`terminal => terminal`), and `CascadeFiresAtMostOnce` is the same proposition as `MapInverseConsistency`'s first half (`cap_to_request[request_to_cap[r]] = r`), not the immutability of the token its comment promises.

## Step 2 — coverage matrix

One row per rule of *Composition-level invariants* (the page's numbering; the model's names follow an older list of four).

| Spec claim | Load-bearing (vote)? | Verdict | Model construct / reason |
|---|---|---|---|
| Invariant 1.1 — every token in the Capability instance parses to a request whose chain is Approved | yes | **covered** | `ApprovalGatesProvisioning` (`request_to_cap[r] # none => chain_state[r] = "Approved"`). "Parses to a request" is the map; the Capability instance's own tokens are `cap_allocated`, tied to the map by `TokensAllocatedOnlyForProvisioned`. No twin gives a token to an unapproved chain. |
| Invariant 1.2 — the cascade fires only if the substrate reports the chain Approved | yes | **covered** (same check) | The cascade is `ApproveStep` reaching quorum; the check reads the chain state at the token's presence, not at the cascade's firing step. A cascade that fires and later sees the chain change is not distinguished. |
| Invariant 2.1 — a request never acquires two tokens across the system's lifetime | yes | **GAP** (weak) → owed (b) | `CascadeFiresAtMostOnce` is meant to state it and does not: its body is `cap_to_request[request_to_cap[r]] = r`, which a request holding one token at a time satisfies even if the token changes. The immutability needs an action property: `[][request_to_cap[r] # "none" => request_to_cap'[r] = request_to_cap[r]]_vars`, with a twin that issues a second token. |
| Invariant 2.2 — the cascade is not fired for a request the provisioning conjunction fails for | yes | by-construction | `ApproveStep` fires the cascade only at quorum; `NoPendingRequestHasToken` states the Pending side. No twin fires the cascade early. |
| Invariant 3.1 — every exercise event follows a Session validate answering valid in the same invocation | yes | out-of-scope (named reason) | Header: "Credential.verify / Session.validate / Permissions.permitted (abstracted as always-pass)". `session-gated-authorization.als` checks the gate (a) for the gate; the composition's own wiring is owed (b). |
| Invariant 3.2 — an exercise event carries the principal the validate answered | yes | out-of-scope (named reason) | No principal. A field claim: Alloy's. |
| Invariant 4.1 — a revoked credential's session answers session-invalid at an exercise (conditional on the wired cascade) | no | out-of-scope (named reason) | No credential, no session. The conditional wiring is Login's cascade (`login.tla`, with the drift found in `login.md`'s matrix). |
| Invariant 5.1 through 5.4 — audit-arc completeness at quiescence | yes | out-of-scope (named reason) | "Audit Trail writes are abstracted away". The completeness claims are at quiescence, a "within the audit horizon" form; Audit Trail's completeness is Audit Trail's (a); the request-to-events map is owed (b). |
| Invariant 6.1 — every decision follows a Credential verify answering verified | yes | out-of-scope (named reason) | The same abstraction (always-pass). Owed (b). |
| Invariant 7.1 — every Denied request carries a denial event at quiescence | yes | out-of-scope (named reason) | The same. |
| Invariant 7.2 — every Denied request names a chain whose state is Rejected | yes | **GAP** → owed (b) | The model has both `Denied` and `Rejected`; `RejectStep` sets them together, and no check reads `request_state = "Denied" => chain_state = "Rejected"`. Cheap to state. |
| Invariant 7.3 — every ProvisioningFailed request carries a failure event with the relayed reason at quiescence | yes | out-of-scope (named reason) | No events. |
| Invariant 8.1 — the composition does not change a request's identity fields | no | out-of-scope (named reason) | No identity fields. Same action-property shape as Invariant 2.1. |
| Invariant 8.2 — a request state does not return to Pending from a terminal state | yes | **GAP** → owed (b) | `TerminalAbsorbingAction` is an `ACTION_CONSTRAINT`, which restricts the explored transitions and so asserts nothing (see Step 1). `TerminalAbsorbing` is a tautology. As written, no check covers 8.2. Promote the action formula to `PROPERTY`; a twin whose `WithdrawRequest` fires from a terminal state rejects it. |
| Invariant 9.1 — every event the request-to-events map names resolves in the one audit substrate | no | out-of-scope (named reason) | No events, no substrate. A deployment-declared single instance. |
| Invariant 10.1, 10.2 — the composition does not change an exercise event or a failed exercise event | no | out-of-scope (named reason) | No events. An action property, with Invariant 8.1. |
| Model-only checks (`NoPendingRequestHasToken`, `ExhaustedSubsetAllocated`, `TokensAllocatedOnlyForProvisioned`, `MapInverseConsistency`) | — | **covered** | State consistency between the maps, the allocated set and the exhausted set. They cover the model's own variables; the page names the maps' agreement in Invariant 2.1's wiring. |
| Liveness — a request with enough approvals eventually reaches a terminal state (`EventuallyTerminal`, commented out) | no | out-of-scope as modeled; **owed as a PROPERTY** (b) | Step 2a: an EVENTUALLY owed as a PROPERTY under TLC, with the fairness the page assumes stated in the header. The file's `FairnessSpec` (weak fairness on withdraw, revoke and approve) is the draft; its twin is a model that never delivers (an unfair approver). |

Out-of-scope residual, named (the model's own list): Credential.verify, Session.validate and Permissions.permitted as always-pass; Audit Trail event writes; clock, TTL and expiry; the Capability redeem counter (a binary redeemable/exhausted flag).

## Step 3 — bound saturation

Two requests, three approvers, two tokens, quorum 2: 1,682 states. A third request would multiply the space and add no interaction the checks name (every check reads one request, or one token's map); not raised in this pass.

## Outcome

- GAP rows: Invariant 2.1 (weak check), 7.2 (no check), 8.2 (a constraint in place of a property). 8.2 is a model defect in the cfg that makes a claimed-covered invariant uncovered.
- by-construction flags: Invariant 2.2.
- Owed (step 2 of the coverage unit): **(b)** move `TerminalAbsorbingAction` from `ACTION_CONSTRAINT` to `PROPERTY` and give it a twin; **(b)** Invariant 2.1 as an action property on the token map with a twin; **(b)** Invariant 7.2; **(b)** `EventuallyTerminal` as a PROPERTY under weak fairness stated in the header; **(b)** the composition's own wiring of Invariants 3.1, 6.1 and 4.1 (a session and a credential action that can fail, with a twin that skips the guard), and 5.x, 7.1, 7.3 (an event per transition); **(a)** Audit Trail completeness is Audit Trail's; **(c)** none. **Tool owed** (step 2c): Alloy for the static field claims (Invariants 3.2, 9.1); the page has no Alloy model.
- Result: **findings routed** — three GAP rows, one of them a defect in the cfg; no English defect.
