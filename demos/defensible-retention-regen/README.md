# Defensible Retention — cold regeneration

> **Scope.** Regenerated 2026-09-27 from the specs as they stood at commit `97ca36f`: [`compositions/defensible-retention.md`](../../compositions/defensible-retention.md) and its constituents [`atoms/legal-hold.md`](../../atoms/legal-hold.md), [`atoms/retention-window.md`](../../atoms/retention-window.md) and the [Audit Trail](../../compositions/audit-trail.md) substrate. The domain only: no server, no views, no deployment. The gaps it met were closed in the spec the same day, and the render follows the closed page (council read 244).

No earlier render of this composition exists, so there is nothing to compare it against; the regeneration's yield is the spec findings in `CORNERS.md`.

**Cold exposure.** The Audit Trail substrate — `src/audit_trail.ts`, `src/audit_atoms.ts`, `src/audit_store.ts`, `src/vault.ts`, `src/erasure.ts` — is carried whole from the [Audit Trail regeneration](../audit-trail-regen/), itself rendered from the specs alone. `src/faults.ts` and `src/seam.ts` come with it.

## Source

- `src/store.ts` — the business database: Legal Hold's store, the business Retention Window instance, and the two derived indexes. The audit instance's stores are a second database, so no business retention can govern an audit event (Composes 8).
- `src/atoms.ts` — Legal Hold. The business Retention Window instance is the same atom the substrate carries, run over the business database.
- `src/composition.ts` — instance start, the five actions, the rebuild, and the sweep.
- `tests/retention.test.ts` — 13 tests, each naming the rule it holds.

## Running

```sh
deno task test
```

The tests use in-memory databases. Where the downloaded SQLite library needs a newer C library than the machine has, point `DENO_SQLITE_PATH` at the system's `libsqlite3.so.0`.
