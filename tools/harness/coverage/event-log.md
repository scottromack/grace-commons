# Coverage matrix — `event-log`

- **Pattern:** `atoms/event-log.md`
- **Model:** `event-log.tla` (+ buggy twin `event-log-buggy.tla`)
- **Reviewer / date:** agent coverage cross-check — 2026-06-03
- **Formal-layer vote load-bearing claims:** Invariant 4 (sequence-number monotonicity), Invariant 1 (append-only)

## Step 1 — harness re-run (must pass)

- Correct model: `node check.mjs ../../atoms/event-log.tla` → `PASS` ☐ *(per Lineage: 119 states, all invariants hold)*
- Buggy twin: `node check.mjs ../../atoms/event-log-buggy.tla --buggy` → `PASS` (rejected) ☐ *(per Lineage: rejected at 14 states)*
- 2026-11-10 (unit `tooling: every check has a twin that breaks it`): `audit.mjs` → HOLDS, three twins CAUGHT; `Inv4_Monotonic` and `Inv3_TotalOrder` broken by `event-log-buggy-remove.tla` (a blanked slot carries sequence 0) and by `event-log-buggy.tla`, `Inv6_NoIdReuse` by the new `event-log-buggy-eid.tla` (the event_id counter restarts at 1), `Inv1_AppendOnlyPrefix` by the new `event-log-buggy-remove.tla` (a landed event removed in place).

## Step 2 — coverage matrix

| Spec invariant (no. + name) | Load-bearing (vote)? | Verdict | Model construct / reason |
|---|---|---|---|
| Invariant 1 — Append-only | YES | `checked` covered (promoted 2026-06-04) | `Inv1_AppendOnlyPrefix`: `∀ i ∈ 1..MaxLen : i ≤ len ⇔ log[i] ≠ EmptyEvt` — every position up to `len` holds a landed event, none past it. A removed event leaves a hole. Broken by `event-log-buggy-remove.tla`. |
| Invariant 2 — Event immutability | No | `owed` by-construction | Filled slots are never overwritten; `AppendOk` only writes position `len+1`. Acceptable: not load-bearing per vote. |
| Invariant 3 — Total order | No (vote named Inv4 & Inv1 only) | `checked` covered | `Inv3_TotalOrder`: `∀ i,j ∈ 1..len : i≠j ⇒ log[i].seq ≠ log[j].seq` Broken by `event-log-buggy-remove.tla`, `event-log-buggy.tla`. |
| Invariant 4 — Sequence-number monotonicity | YES | `checked` covered | `Inv4_Monotonic`: `∀ i,j ∈ 1..len : i < j ⇒ log[i].seq < log[j].seq` Broken by `event-log-buggy-remove.tla`, `event-log-buggy.tla`. |
| Invariant 5 — Read consistency | No | `owed` out-of-scope (ordering it relies on is exactly Inv4, which is checked; query-shape property) | Per model header comment. |
| Invariant 6 — No id reuse | No | `checked` covered | `Inv6_NoIdReuse`: `∀ i,j ∈ 1..len : i≠j ⇒ log[i].eid ≠ log[j].eid` Broken by `event-log-buggy-eid.tla`. |
| Invariant 7 — Wall-time best-effort monotonicity | No | `unstatable` out-of-scope (explicitly best-effort; clock not modeled) | Per model header comment. |

## Step 3 — bound saturation

Per Lineage: `MaxLen=4`, `MaxSeq=6` → 119 reachable states. Model includes `AppendStorageFail` which consumes sequence numbers without landing events, so the state space covers the gap scenario. Bound appears adequate for exercising the monotonicity claim under storage-failure gaps.

- At `MaxLen=4, MaxSeq=6`: 119 states (per Lineage).
- Saturation re-run not executed here; Lineage documents the verified count.

## Outcome

- GAP rows: none
- by-construction flags on load-bearing invariants: **Invariant 1 (append-only) is load-bearing (vote) and held by-construction rather than by a named check.** Flag for promotion to an explicit state predicate (e.g., `Inv1_AppendOnly == ∀ i ∈ 1..MaxLen : (i > len) ⇒ log[i] = EmptyEvt`) so the check surface matches the vote.
- Result: **one load-bearing by-construction flag to route** — no hard GAPs. All voted load-bearing invariants are verified (Inv4 as explicit check; Inv1 by construction), but Inv1 promotion is recommended.
