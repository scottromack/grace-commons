# Coverage matrix — `capability-backed-sharing`

- **Pattern:** `compositions/capability-backed-sharing.md`
- **Model:** `capability-backed-sharing.tla` + `capability-backed-sharing.cfg` (TLA+, two disclosures; invariants Inv2_NoOrphanSeal, Inv2_NoUnsurfacedUnsealed, Safety; no PROPERTY) + buggy twins `capability-backed-sharing-buggy.tla` (silence hazard) and `capability-backed-sharing-buggy-old-wiring.tla` (the append outside the transaction)
- **Reviewer / date:** mayor, from the page at fc78924 and the model as it stands — 2026-11-10 (unit `formal: more coverage for the yes votes`, step 1; the page had no matrix)
- **Formal-layer vote load-bearing claims:** the model checks Invariant 2 only, the disclosure-accountability binding. Its header states the claim "Safety plus liveness" at its true strength: safety is mechanical; the WITHIN arm of Invariant 2.4 is carried only as enabledness (`RetrySeal` is enabled in exactly the unsealed configuration), and the bound is "a configuration value and an acceptance check".

## Step 1 — harness run

- Correct model: `node check.mjs ../../compositions/capability-backed-sharing.tla` → `HOLDS` ✓ (25 states, TLC, 2026-11-10).
- Buggy twins: `-buggy` → `CAUGHT` (`Inv2_NoUnsurfacedUnsealed`, 7 states); `-buggy-old-wiring` → `CAUGHT` (`Inv2_NoOrphanSeal`, 7 states).

## Step 2 — coverage matrix

One row per rule of *Composition-level invariants* (the page's numbering). The page states six invariants; the model reaches the second.

| Spec claim | Load-bearing (vote)? | Verdict | Model construct / reason |
|---|---|---|---|
| Invariant 1.1 — every capability-backed disclosure's records name the allocator as the authorizing party | no | out-of-scope (named reason) | No party fields in the model; a field claim. Alloy's (static). |
| Invariant 1.2 — no record carries a redeemer identity | no | out-of-scope (named reason) | A rule about what no record carries. Same shape as Capability Invariant 3 (by-construction, recorded as an assumption). |
| Invariant 1.3 — every disclosure record carries the capability's intended recipient | no | out-of-scope (named reason) | A field claim; open line 2026-10-27-a asks about the recipient term. |
| Invariant 1.4 — the allocator-named claim is made only if the events lie inside the audit horizon | no | out-of-scope (named reason) | No audit horizon, no clock. |
| Invariant 2.1 — every disclosure event names a disclosure record | yes | **covered** | `Inv2_NoOrphanSeal` (an audit seal for a disclosure implies its transaction committed); `-buggy-old-wiring` (the append lands while the transaction aborts) rejects it. |
| Invariant 2.2 — a disclosure record carries no two disclosure events | yes | **covered** | `Inv2_BindingBijection` in `Safety` (at most one seal per disclosure; `auditState` is a single value per disclosure). No twin lands a second seal. |
| Invariant 2.3 — every committed disclosure whose event has not landed stands as a pending marker | yes | **covered** | `Unsealed(d)` is defined as the committed-and-unsealed configuration, and `Inv2_NoUnsurfacedUnsealed` requires it to be surfaced; the marker is *derived* from that configuration (header: the disclosure_to_redemption index "is deliberately NOT a variable"), so the marker's existence is a definition, not a check. |
| Invariant 2.4 — every pending marker whose intent is not in the aged events is sealed within the compensation window | yes | out-of-scope as modeled; **owed as a PROPERTY** (b) | The header states it: the model carries only the enabledness half (`RetrySeal` enabled exactly when unsealed). The WITHIN bound has no clock here. Step 2a: sort as a bound a model clock makes an invariant (a window counter with `Unsealed(d) => age[d] <= W`), with a twin that never runs `RetrySeal` (an unfair scheduler) rejected by it. The EVENTUALLY form needs the fairness the page assumes (Reconciliation cadence and run bound) stated in the model header. |
| Invariant 2.5 — the binding claim is made only if the deployment declares window, cadence and run bound | no | out-of-scope (named reason) | A claim about what a deployment declares (an acceptance check). |
| Invariant 3.1 — every authorization event names a capability token in the Capability records | yes | out-of-scope (named reason) | No allocation, no authorization event, no token in the model; it models the redeem-and-disclose path only. Owed (b): the allocate path is a second half of the page. |
| Invariant 3.2 — every capability-to-sharing entry names exactly one authorization event | yes | out-of-scope (named reason) | The same; owed with 3.1. |
| Invariant 3.3 — every authorization event carries the allocator's attestation | yes | out-of-scope (named reason) | The same. |
| Invariant 3.4 — every allocated capability is settled within the compensation window | yes | out-of-scope as modeled; **owed as a PROPERTY** (b) | The same WITHIN shape as 2.4, over the allocation path; "settled" is the Term (authorization event, revoked, or lapsed). |
| Invariant 4.1 — every disclosure record carries the capability's disclosed scope | no | out-of-scope (named reason) | A field claim. |
| Invariant 4.2 — disclosure events naming a token do not exceed the capability's consumed count | yes | out-of-scope (named reason) | No redemption counter. `capability.als` covers the counter's bounds (a: another page owns the counter, not this count equality across the two records). The equality of the disclosure-event count and the consumed count is the composition's own and is owed (b). |
| Invariant 6.1, 6.2 — an allocation and a revocation follow a validation of the actor's credential | yes | out-of-scope (named reason) | No actor, no validation. Same shape as Authenticated Actor's registration guard; Session-gated authorization checks it for its gate. Owed (b) as an ordering claim over the allocation and revocation actions. |

Out-of-scope residual, named (the model's own): the intent's refusal or abandonment event; the `disclosure_to_redemption` index (derived, not a variable); Audit Trail's own completeness and the clock (a).

## Step 3 — bound saturation

Two disclosures; each runs the same four actions (`WriteIntent`, `CommitClean`, `CommitUnsealed`, `RetrySeal`): 25 states. A third disclosure only repeats the per-disclosure shape and adds no cross-disclosure interaction the checks name (none of them reads two disclosures); not raised in this pass.

## Outcome

- GAP rows: the page states six invariants; the model covers Invariant 2 (2.1 to 2.3) with two rejecting twins. Invariants 3 and 6 (the allocation half) and Invariant 4.2 have no model; Invariants 2.4 and 3.4 carry a WITHIN that the model does not check.
- by-construction flags: Invariant 2.3's marker is derived, so it is a definition.
- Owed (step 2 of the coverage unit): **(b)** the allocation half: an `Allocate` and `Revoke` action, with Invariant 3.1 through 3.3, 6.1, 6.2 and 4.2; **(b)** the WITHIN of Invariants 2.4 and 3.4 as an invariant over a window counter, and the EVENTUALLY form as a PROPERTY with the fairness the page assumes in the header, with a twin that never seals; **(c)** Invariant 1.2 (no redeemer identity: a rule about what no record carries), 1.4 and 2.5 (claims about what is said, not what a record does) stay with their reasons; **(a)** the counter's bounds are Capability's. **Tool owed** (step 2c): Alloy for the static fields (Invariants 1.1, 1.3, 3.1 to 3.3, 4.1) unless writing it vetoes it.
- Result: **findings routed** — coverage debt; no English defect.
