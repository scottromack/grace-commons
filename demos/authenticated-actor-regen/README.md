# Authenticated Actor — cold regeneration

> **Scope.** Regenerated 2026-09-28 from the specs as they stood at commit `a8e8f13`: [`compositions/authenticated-actor.md`](../../compositions/authenticated-actor.md), [`atoms/credential.md`](../../atoms/credential.md) and [`atoms/actor-identity.md`](../../atoms/actor-identity.md). The domain only: the three actions, the per-principal critical section with its lease, and the orphaned-credential leg. The gaps it met were closed in the spec the same day, and the render follows the closed page (council read 256).

No earlier render of this composition exists, so there is nothing to compare it against; the regeneration's yield is the spec findings in `CORNERS.md`.

**Cold exposure.** Credential and Actor Identity are carried from the [Login regeneration](../login-regen/) (`src/atoms.ts`), with one arm added: Credential's register answers storage-failure, which Login never reached. `src/seam.ts` and `src/faults.ts` are carried from there too; `Faults` gains the hooks a test uses to put another caller between two steps.

## Source

- `src/store.ts` — one SQLite database: both constituents' stores, the principal binding and its inverse (unique on both keys, never changed), and the attest log (append-only).
- `src/host.ts` — the host's critical section, keyed by principal reference, with a lease of exactly the holding action's completion bound.
- `src/atoms.ts` — Credential and Actor Identity, as far as the composition reaches them.
- `src/composition.ts` — [Register Authenticated Actor], [Attest As Actor], [Verify Actor Attestation] and the orphaned-credential leg.
- `tests/authenticated-actor.test.ts` — 18 tests, each naming the rule it holds.

## Running

```sh
deno task test
```

The tests use in-memory databases. Where the downloaded SQLite library needs a newer C library than the machine has, point `DENO_SQLITE_PATH` at the system's `libsqlite3.so.0`.
