# Coverage matrix — `party-identity`

- **Pattern:** `atoms/party-identity.md`
- **Model:** `party-identity.tla` + `party-identity.cfg` (TLA+, one party, `MaxEvents = 6`; `Safety` = TypeOK, Inv2, Inv3, Inv4, Inv6) + buggy twin `party-identity-buggy.tla` (drops the Reinstate guard)
- **Reviewer / date:** mayor, from the page at fc78924 and the model as it stands — 2026-11-10 (unit `formal: more coverage for the yes votes`, step 1; the page had no matrix, though the coverage cross-check of 2026-06-03 promoted Inv 6 on it, see the README)
- **Formal-layer vote load-bearing claims:** Invariant 4 (a verified party rests on a passed verification after the most recent suspend, in insertion order) is the model's stated load-bearing claim; the 2026-06-03 sweep promoted Invariant 6 (append-only) and Invariant 3 (closed absorbing, history-flag form) to explicit checks.

## Step 1 — harness run

- Correct model: `node check.mjs ../../atoms/party-identity.tla` → `HOLDS` ✓ (532 states, TLC, 2026-11-10).
- Buggy twin: `node check.mjs ../../atoms/party-identity-buggy.tla --buggy` → `CAUGHT` ✓ (137 states). One twin, one defect: it breaks Inv 4 and no other check. Inv 2, Inv 3 and Inv 6 have no twin of their own.

## Step 2 — coverage matrix

One row per rule of *Invariants* (the page's numbering), then the rules outside it that name a checkable claim.

| Spec claim | Load-bearing (vote)? | Verdict | Model construct / reason |
|---|---|---|---|
| Invariant 1.1 — the atom does not remove a party | no | by-construction | One party, and no action removes it; the model has no delete action. A regression adding one is not catchable as written. |
| Invariant 2.1 — every party stands in exactly one of four states | no | **covered** (weak) | `Inv2_StateExclusivity == pstate \in States`; the same proposition as `TypeOK`'s `pstate \in States`, so no twin can break it without breaking TypeOK. A variable holds one value, so "exactly one" is the data model's. |
| Invariant 3.1 — closed does not leave closed | yes (promoted 2026-06-03) | **covered** | `Inv3_ClosedAbsorbing` (history flag `everClosed => pstate = "Closed"`). No twin leaves closed, so the check has not been shown to fail. |
| Invariant 4.1 — a verified party carries a fresh verification | yes | **covered** | `Inv4_PassedAfterSuspend`, derived from the log by `HasPassedAfterSuspend`; the twin drops the Reinstate guard and the check rejects it. "Fresh" is read as: a `passed` verification after the most recent suspend. The page's *Fresh Verification* term may carry more (the model has no instants). |
| Invariant 5.1 — no verification event changes | no | by-construction | The log is written only at `len + 1`; no action rewrites a slot. As a state invariant it cannot be stated; as an action property it can: `[][\A i \in 1..len : log'[i] = log[i]]_vars`. Owed (b). |
| Invariant 6.1 — no verification event removed | no | **covered** (state half) | `Inv6_AppendOnlyPrefix` (a contiguous filled prefix; a hole or a write past the tail violates it). Removal is not an action the model can take; the action form is owed with 5.1. |
| Invariant 6.2 — no append before a prior event | no | by-construction | Every action writes slot `len + 1`. Same action form owed. |
| Invariant 6.3 — the event list length does not fall | no | by-construction | `len' = len + 1` in every action. As a property: `[][len' >= len]_vars`; owed (b). |
| Invariant 8.1 — every transitioning action appends a state change event | yes | **covered** in part | Each action appends exactly one log slot (`Inv6_AppendOnlyPrefix` and `len' = len + 1`). The model has one log for both event kinds (`vp`, `vf` are verification events; `sus`, `rei`, `cls` are state changes), so the claim that the first transition (Unverified to Verified by a passed verification) appends a *state change* event as well as the verification event is not distinguished. Owed (b). |
| Invariant 8.2 — the state change log length does not fall | no | by-construction | The same as 6.3; the model has one length. |
| Invariants 7, 9, 10, 11 | — | deleted / owned elsewhere | Invariant 7 (Non-goal 3), 9 and 10 (Identity 6 through 9) and 11 (Execution Contract Database 1 to 3) are deleted from this page. |
| Identity 7 through 9 — no two parties, verification events or state change events share an id | no | out-of-scope (named reason) | One party in the model, and ids are not modeled (header: "Multiple parties and id uniqueness — structural, not ordering; Alloy's bounded-structural surface is the right tool"). The Alloy model the header points to does not exist. **Owed to Alloy** (b). |
| Identity 5, 6 — the atom does not generate or change an assigned id | no | out-of-scope (named reason) | No ids modeled. Static claim over a record shape: Alloy's, with Identity 7 through 9. |
| State 4, 5, 7 — a verification event, state change event and reasoned action carry their fields | no | out-of-scope (named reason) | The events are letters; no field is modeled. Static claim: Alloy's. |
| Ordering 3 through 5 — read the most recent event from insertion order; no ordering from an instant | no | **covered** (partly) | Insertion order is the model's only order (`log` indexed by `len`); there are no instants, so "an instant does not bound a reconstruction" is true by the model's absence of time. `HasPassedAfterSuspend` is the read of the most recent event. |

## Step 3 — bound saturation

One party, six events, five event kinds: 532 states. A longer log adds only repetitions of the same five actions, which the prefix check and `HasPassedAfterSuspend` read position by position; a run at `MaxEvents = 7` is owed to confirm the count is the only thing that grows. Not run in this pass.

## Outcome

- GAP rows: none on the English's load-bearing claims (Inv 4 is covered with a rejecting twin).
- by-construction flags: Invariants 5.1, 6.2, 6.3, 8.2 — action properties the model holds by writing only slot `len + 1`. All four are expressible as `PROPERTY` with a `[][…]_vars` action formula (step 2a: no cfg checks a PROPERTY today), and one twin that rewrites or drops a slot would reject them.
- Owed (step 2 of the coverage unit): **(b)** Invariants 5.1, 6.1 (action form), 6.2, 6.3, 8.2 as `PROPERTY` with twins; **(b)** Invariant 8.1, split the log into verification events and state change events; **(b)** a twin for Inv 2 and Inv 3 (an action that leaves Closed). **Tool owed** (step 2c): an Alloy model for Identity 5 through 9 and State 4, 5, 7 (ids, fields and their uniqueness), as the model header itself says, unless writing it vetoes it.
- Result: **findings routed** — no English defect; coverage debt only.
