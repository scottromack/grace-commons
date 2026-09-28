# Customer Onboarding — cold regeneration

> **Scope.** Regenerated 2026-09-28 from the specs as they stood at commit `251dc3f`: [`compositions/customer-onboarding.md`](../../compositions/customer-onboarding.md), [`atoms/party-identity.md`](../../atoms/party-identity.md), [`atoms/retention-window.md`](../../atoms/retention-window.md) and the [Audit Trail](../../compositions/audit-trail.md) substrate. Rendered to the depth `CORNERS.md` states: the six actions, the activity gate and the four indexes; the rebuild and the reconciliation are not rendered. The gaps it met were closed in the specs the same day (council read 254).

No earlier render of this composition exists, so there is nothing to compare it against; the regeneration's yield is the spec findings in `CORNERS.md`.

**Cold exposure.** The author read the prose spec the 2026-09-14 rewrite replaced, to check what the rewrite changed. The Audit Trail substrate and `src/faults.ts`, `src/seam.ts`, `src/vault.ts`, `src/erasure.ts` are carried from the [Defensible Retention regeneration](../defensible-retention-regen/).

## Source

- `src/store.ts` — the business database: Party Identity's store, the party retention instance, and the four indexes.
- `src/atoms.ts` — Party Identity. The party retention instance is the Retention Window the substrate carries, run over the business database.
- `src/composition.ts` — the six actions.
- `tests/onboarding.test.ts` — 10 tests, each naming the rule it holds.

## Running

```sh
deno task test
```

The tests use in-memory databases. Where the downloaded SQLite library needs a newer C library than the machine has, point `DENO_SQLITE_PATH` at the system's `libsqlite3.so.0`.
