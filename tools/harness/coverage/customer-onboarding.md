# Coverage matrix — `customer-onboarding`

- **Pattern:** `compositions/customer-onboarding.md`
- **Model:** `customer-onboarding.tla` + `customer-onboarding.cfg` (TLA+, one party, `MaxTriggers = 2`; invariant `Safety` = TypeOK and `Inv_OpenTriggerIffSuspended`; no PROPERTY) + buggy twin `customer-onboarding-buggy.tla` (a suspend with no trigger)
- **Reviewer / date:** mayor, from the page at fc78924 and the model as it stands — 2026-11-10 (unit `formal: more coverage for the yes votes`, step 1; the page had no matrix)
- **Formal-layer vote load-bearing claims:** the model header names one: the adverse-monitoring coupling, an adverse trigger precedes a suspend and a party is suspended if and only if it carries an open trigger. The page states 35 rules under *Composition-level invariants*; the model reaches 7.1 and 7.2 and the order claim of 3.1.

## Step 1 — harness run

- Correct model: `node check.mjs ../../compositions/customer-onboarding.tla` → `HOLDS` ✓ (3 states, TLC, 2026-11-10).
- Buggy twin: `node check.mjs ../../compositions/customer-onboarding-buggy.tla --buggy` → `CAUGHT` ✓ (4 states, `Safety`).

## Step 2 — coverage matrix

One row per rule of *Composition-level invariants* (the page's numbering; the section states its rules in one block). "Owed (b)" in a row means the model left the claim out and nothing about the tool prevents stating it; the sort is the unit's step 2.

| Spec claim | Load-bearing (vote)? | Verdict | Model construct / reason |
|---|---|---|---|
| Invariant 1.1 — `Activity Permitted` answers permitted only if the index names the party and Party Identity reports verified | yes | out-of-scope (named reason) | No index, no Activity Permitted; the model's `state` has no unverified party. Owed (b). |
| Invariant 1.2 — it answers permitted for a party the index names and Party Identity reports verified | yes | out-of-scope (named reason) | The same. The converse of 1.1 (liveness of an answer, not a state): owed (b), a twin that refuses a named, verified party. |
| Invariant 1.3 — a party reaches regulated activity only if `Activity Permitted` answers permitted | yes | out-of-scope (named reason) | The same; an action-enablement claim, a guard conjunct and a twin that drops it. Owed (b). |
| Invariant 2.1 — a transitioning verification carries a landed verification recorded record naming both ids | yes | out-of-scope (named reason) | No verification, no log. Owed (b). |
| Invariant 2.2 — a verification recorded record stands under a seal per Audit Trail's cadence | no | out-of-scope (named reason) | Audit Trail's seal cadence (a): `audit-trail.tla`. |
| Invariant 2.3 — a quiescent verified party carries a verification recorded record | yes | out-of-scope (named reason) | No records, no in-flight invocation. A quiescence claim; owed (b). |
| Invariant 2.4 — a verified party may carry an owed record within the compensation window | yes | out-of-scope (named reason) → owed as a bound | A WITHIN: a window counter makes it an invariant (step 2a). Owed (b). |
| Invariant 3.1 — a party suspended record stands later in the log than its monitoring triggered record | yes | **covered** in part | The model's `RaiseTrigger` sets openTriggers and state in one step, so the trigger precedes the suspend by construction; the model has no log, so "later in the log" is not represented. The header names this the load-bearing claim ("trigger precedes suspend"). Owed (b): a log, and a twin that suspends first. |
| Invariant 3.2 — a trigger on suspended party record stands later than the monitoring triggered record | no | out-of-scope (named reason) | No log. Owed (b), with 3.1. |
| Invariant 3.3 — a reader reads later as the Event Log's insertion order | no | out-of-scope (named reason) | A reading rule; Event Log's order is Event Log's (a). |
| Invariant 3.4 — a reader does not read later as a timestamp difference | no | out-of-scope (named reason) | A rule about what a reader does not read; stays with the reason (c). |
| Invariant 4.1 — a reinstated party carries a passed verification later than the most recent suspension | yes | out-of-scope (named reason) | No verification in the model: `ResolveTrigger` reinstates when the last trigger clears, with no passed verification. The same claim is Party Identity Invariant 4 (`party-identity.tla`, covered, with a twin) for the atom; this page's own claim is the composition's clearing path. Owed (b). |
| Invariant 4.2 — a reinstated party carries a landed review cleared record naming the verification id | yes | out-of-scope (named reason) | No review, no record. Owed (b). |
| Invariant 4.3 — the clearing actor attests the fresh evidence | yes | out-of-scope (named reason) | No actor. Owed (b). |
| Invariant 4.4 — the composition does not claim the verifying actor reference stands authenticated | no | out-of-scope (named reason) | A rule about what is claimed (c). |
| Invariant 5.1 — an active case's party record stands under an unelapsed placement | yes | out-of-scope (named reason) | No placement, no retention. Retention Window's own models carry the arithmetic (a); the coupling is owed (b). |
| Invariant 5.2 — an active case's placements form a continuous chain | yes | out-of-scope (named reason) | The same. Owed (b). |
| Invariant 5.3 — a closed case's party record stands under the post closure placement | yes | out-of-scope (named reason) | The same. Owed (b). |
| Invariant 5.4 — a purging layer destroys a record only if every placement over it has elapsed | yes | out-of-scope (named reason) | The same; an action guard. Owed (b). |
| Invariant 5.5 — the composition exposes no purge surface | no | out-of-scope (named reason) | A rule about an absent surface (c). |
| Invariant 5.6 — a purging layer does not destroy a closed case's record before the post closure floor | yes | out-of-scope (named reason) | The same as 5.4. Owed (b). |
| Invariant 6.1 — a verified party under an active case carries a case-to-monitoring entry | yes | out-of-scope (named reason) | No monitoring entry. The model's `openTriggers` is the only monitoring state. Owed (b). |
| Invariant 6.2 — a case-to-monitoring entry carries a next review due | no | out-of-scope (named reason) | A field claim. Alloy's (static). |
| Invariant 7.1 — a quiescent active case carries a non-empty open-trigger set only if the party is suspended | yes | **covered** | `Inv_OpenTriggerIffSuspended`, the biconditional (`(openTriggers > 0) = (state = "Suspended")`); `customer-onboarding-buggy.tla` adds a suspend with no trigger and the check rejects it. The model has no in-flight invocation, so "quiescent" is every state. |
| Invariant 7.2 — a quiescent suspended party under an active case carries a non-empty open-trigger set | yes | **covered** | The same biconditional, the other direction. The twin breaks the direction "suspended without a trigger"; no twin breaks "a trigger with no suspend" (`ResolveTrigger`'s reinstate-on-last-clear), so that direction's power is untested. Owed (b): a twin that leaves a party verified with an open trigger. |
| Invariant 7.3 — a verified party carrying a closed trigger inside the clearance window stands as a surfaced orphan | yes | out-of-scope (named reason) | No clearance window, no orphan state, one trigger counter. Owed (b). |
| Invariant 7.4 — a quiescent closed case carries an empty open-trigger set | yes | out-of-scope (named reason) | No closed case (the model's states are Verified and Suspended only). Owed (b). |
| Invariant 7.5 — a party closed record names every trigger the closure swept | yes | out-of-scope (named reason) | No closure, no identity for a trigger (header: "trigger identity/attribution" not modeled). Owed (b). |
| Invariant 8.1 — no constituent write under an unvalidated credential | yes | out-of-scope (named reason) | No credential. Authentication precedence is Authenticated Actor's and Session-Gated Authorization's pattern (a: see their checks); this page's claim is owed (b). |
| Invariant 8.2 — an action validates exactly one actor's credential | no | out-of-scope (named reason) | A counting claim over a call's wiring (c). |
| Invariant 8.3 — the composition does not claim a recorded actor reference stands authenticated | no | out-of-scope (named reason) | A rule about what is claimed (c). |
| Invariants 8.4, 8.5, 8.6, 8.7 — a credential validation establishes no identity, no channel binding, no authorization, no customer evidence | no | out-of-scope (named reason) | Four rules about what a validation does not establish (c). |

Out-of-scope residual, named (the model header's own list): the Party Identity verification lifecycle (`party-identity.tla`), the Audit Trail substrate (`audit-trail.tla`), Retention Window, trigger identity and attribution.

## Step 3 — bound saturation

`MaxTriggers = 2` gives 3 states (Verified/0, Suspended/1, Suspended/2); a third trigger adds one more of the same shape. The space is too small to saturate meaningfully: it is a counter. Not raised in this pass.

## Outcome

- GAP rows: the model covers a coupling (7.1, 7.2) and the order of 3.1 by construction, and nothing else. 32 of the 35 rules are out of scope, and 19 of those are rows marked load-bearing (every rule of 1, 2.1, 2.3, 2.4, 4.1 to 4.3, 5.1 to 5.4, 5.6, 6.1, 7.3 to 7.5 and 8.1, except those Audit Trail or Retention Window own). This is the thinnest model of the ten matrices written in this pass, and a `formal: verified` page.
- by-construction flags on load-bearing claims: Invariant 3.1's order (one step writes both fields).
- Owed (step 2 of the coverage unit): **(b)** the case record: a party state with Unverified, Verified, Suspended and Closed; a case with active and closed status; a log; placements with a retention instant; the clearing path (a passed verification after the suspension, a review cleared record, the clearing actor); the purge guard; the sweep at closure; the orphan during the clearance window. Twins: suspend with no trigger (present), reinstate with no passed verification, purge before the floor, a closure that leaves a trigger open, a reinstate that skips the review record. **(a)** Retention arithmetic is Retention Window's; Audit Trail seals are Audit Trail's. **(c)** Invariants 3.4, 4.4, 5.5, 8.2, 8.3 and 8.4 to 8.7 are rules about what is not claimed or not established; they stay with the reason. **Tool owed** (step 2c): the page has no Alloy model; its static claims are the field claims of Invariant 6.2 and the placement chain's shape (5.2), owed to Alloy unless writing it vetoes it.
- Result: **findings routed** — coverage debt on a thin model; no English defect found by reading the model against the page.
