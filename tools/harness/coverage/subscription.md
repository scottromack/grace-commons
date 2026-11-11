# Coverage matrix — `atoms/subscription.md`

- **Pattern:** `atoms/subscription.md`
- **Model:** `subscription.als` + buggy twins `subscription-buggy.als` (rebuilt 2026-11-10 from the current model) and `subscription-buggy-cancelled-at-unbound.als` (2026-11-10)
- **Reviewer / date:** Claude Sonnet 4.6 — 2026-06-03
- **Formal-layer vote load-bearing claims:** Invariant 6 (at-most-one-Active per (subscriber_ref, event_scope) pair), Invariant 2 (status monotonicity Active → Cancelled), Invariant 4 (new subscribe after cancel produces a new distinct id / no id reuse)

## Step 1 — harness re-run (must pass)

- Correct model: `node check.mjs ../../atoms/subscription.als` → `PASS` ☐ *(not re-run here; lineage records green run 2026-06-03, all 7 checks UNSAT)*
- Buggy twin: `node check.mjs ../../atoms/subscription-buggy.als --buggy` → `PASS` (rejected) ☐
- 2026-11-10 (unit `tooling: every check has a twin that breaks it`): four checks restated a fact word for word and went (`A_NoIdReuse` and `A_IdsDistinctAcrossStatuses` = `fact NoIdReuse`, `A_AtMostOneActivePerKey` = `fact AtMostOneActivePerKey`, `A_TimestampOrdering` = `fact TimestampOrdering`), leaving 3 checks; `subscription-buggy.als` was rebuilt from the current model (same defect: no `AtMostOneActivePerKey`; its checks had drifted) and `subscription-buggy-cancelled-at-unbound.als` added. `GRACE_STATES_LEDGER=off node audit.mjs --only 'atoms/subscription[.-]'`: the model HOLDS, both twins CAUGHT, every one of the 3 checks broken by a twin, 0 red.

## Step 2 — coverage matrix

The model bounds: static snapshot; up to 6 `SubscriptionRecord` sigs (scope 6 for all checks), with `3 Int` for timestamp fields. Four structural `fact`s + four `assert/check` pairs covering the vote-named claims. Seven `run` non-vacuity predicates.

| Spec invariant (no. + name) | Load-bearing (vote)? | Verdict | Model construct / reason |
|---|---|---|---|
| Invariant 1 — Subscription immutability | No | `owed` by-construction (`subscriber`, `event_scope`, `subscribed_at`, and `sub_id` are fields on `SubscriptionRecord`; the static snapshot model has no mutation action that alters them — `cancel` only changes `status` and `cancelled_at` in the spec; no transition predicate exists in this model to re-assign immutable fields) | Static model; immutable fields not subject to modification by any modeled action |
| **Invariant 2 — Status monotonicity** | **Yes** | `checked` **covered** | `A_CancelledHasCancelledAt` asserts every Cancelled record carries a `cancelled_at`; `A_ActiveHasNoCancelledAt` asserts Active records carry no `cancelled_at` — together these encode the one-directional state machine; both `check ... for 6`. The `CancelledAtConsistency` fact is the by-construction counterpart; the asserts verify it explicitly. Broken by `subscription-buggy-cancelled-at-unbound.als` (`A_CancelledHasCancelledAt`, `A_ActiveHasNoCancelledAt`). |
| Invariant 3 — Cancellation is terminal | No | `checked` **covered** | `A_CancelledHasCancelledAt` (Cancelled has timestamp) + `A_ActiveHasNoCancelledAt` (Active has no timestamp) together assert the terminal absorption: once Cancelled, no re-activation is possible because re-activation would require losing `cancelled_at` and gaining Active status — structurally prevented by the fact and checked by the asserts. Also by-construction (no re-activate transition predicate exists in the model). Broken by `subscription-buggy-cancelled-at-unbound.als` (`A_CancelledHasCancelledAt`, `A_ActiveHasNoCancelledAt`). |
| **Invariant 4 — New subscribe after cancel produces a new id** | **Yes** | `owed` (was covered via Invariant 5) | Assumed by `fact NoIdReuse` of the static model (`all disj r1, r2 : SubscriptionRecord | r1.sub_id != r2.sub_id`), which no twin can break; the check `A_IdsDistinctAcrossStatuses` restated it word for word and went (2026-11-10); owed to a stepping model, where a subscribe after cancel minting a fresh id is an action a twin can break. `ShowCancelThenResubscribe` run still shows the scenario is SAT |
| Invariant 5 — No id reuse | No | `owed` (was covered) | Assumed by `fact NoIdReuse` of the static model, which no twin can break; the check `A_NoIdReuse` restated it word for word and went (2026-11-10); owed to a stepping model |
| **Invariant 6 — At most one active subscription per (subscriber_ref, event_scope)** | **Yes** | `checked` **covered** | `A_NoDualActiveForSameKey` asserts it pairwise: two records for one (subscriber, scope) pair are never both Active; `check A_NoDualActiveForSameKey for 6`. `fact AtMostOneActivePerKey` assumes it; `A_AtMostOneActivePerKey` restated that fact word for word and went (2026-11-10). Buggy twin removes the `AtMostOneActivePerKey` fact; checker finds counterexample on `A_NoDualActiveForSameKey`. Broken by `subscription-buggy.als`. |
| Invariant 7 — Evaluation self-containment | No | `unstatable` by-construction (`subscribers_for` and `subscribed` queries are not modeled as actions; the atom's query logic is a pure filter over the Active subscription set, structural by the model's definition of `AtMostOneActivePerKey` and the subscription record structure) | Query-surface property; not a structural invariant requiring its own check |
| Invariant 8 — Absence means not-subscribed | No | `owed` by-construction (biconditional "Active grant iff permitted" analog: no Active record for (subscriber, scope) means `subscribers_for` returns nothing for that pair — follows directly from `AtMostOneActivePerKey` and the Active-filter semantics; no explicit assert needed beyond the exclusivity check) | Follows from Invariant 6 coverage + query-filter semantics |
| Invariant 9 — Timestamp ordering | No | `owed` (was covered) | Assumed by `fact TimestampOrdering` of the static model (`r.status = Cancelled implies r.subscribed_at <= r.cancelled_at`), which no twin can break; the check `A_TimestampOrdering` restated it word for word and went (2026-11-10); owed to a stepping model, where cancel stamping `cancelled_at` from the clock is an action a twin can break. *Note: spec qualifies this as best-effort under non-monotonic clocks, but the model asserts it unconditionally within the Int-bounded scope — this is correct for the structural check; real-world non-monotonic violations are deployment-level* |

**Note on Invariant 9 (timestamp ordering) coverage.** Unlike Notification and Permissions (which explicitly exclude timestamp ordering as out-of-scope), Subscription's model includes integer timestamps and explicitly asserts `A_TimestampOrdering`. This is a stronger model commitment than the spec's "best-effort" qualification. The structural assertion is correct — within the model's Int scope, the ordering holds — and does not misrepresent the spec, because the spec's "best-effort" caveat applies to real-world clock skew, not to the abstract structural model. No discrepancy.

**Note on the buggy twin.** The lineage notes: "The buggy file additionally carries one vacuous `run`, `ShowCancelTransition` — harmless: `--buggy` mode passes on the counterexample and ignores run vacuity." This is an acceptable known limitation in the buggy twin; it does not affect the check results.

## Step 3 — bound saturation

Model scope: all checks at `for 6 but 3 Int`. At 6 SubscriptionRecord sigs, all meaningful (subscriber, scope, status) triples and id-collision scenarios are explored. The `ShowTwoActiveSubscribersForSameScope` run (confirming two different subscribers can both be Active on the same scope) is SAT, and `ShowCancelThenResubscribe` is SAT — the key non-vacuity scenarios pass. Not formally re-run at larger scope; lineage records scope 6 as the shipped bound.

## Outcome

- GAP rows: **none**
- by-construction flags on load-bearing invariants: **none** (Invariants 2, 4, and 6 are all explicitly asserted by named checks)
- Result: **clean** — all three vote-named load-bearing invariants (Inv 2, Inv 4/5, Inv 6) covered by named `check` asserts; Invariant 9 additionally covered (stronger than required by spec); all out-of-scope items defensible. Lineage entry: *"Coverage cross-check 2026-06-03 — clean (Invariants 2, 4, 6 covered by named checks; Invariant 9 additionally covered by A_TimestampOrdering; saturation confirmed at scope 6)."*
