# Session-Gated Authorization — cold regeneration

> **Scope.** Regenerated 2026-09-27 from the specs as they stood at commit `c332e04`: [`compositions/session-gated-authorization.md`](../../compositions/session-gated-authorization.md) and its constituents [`atoms/session.md`](../../atoms/session.md) and [`atoms/permissions.md`](../../atoms/permissions.md). The domain only. The gap it met was closed in the spec the same day, and the render follows the closed page (council read 236).

Its one earlier render is the [clinical-trial portal](../clinical-trial-portal/)'s two middlewares; the two are compared in `CORNERS.md`, the section titled *Against the portal's gate*.

**Cold exposure.** The author had read the portal's login code for the Login regeneration, not its middleware; the middleware was opened only for the comparison.

## Source

- `src/store.ts` — Session's and Permissions' stores; the composition stores nothing.
- `src/atoms.ts` — Session and Permissions, as far as the gate reaches them.
- `src/composition.ts` — `start` and `check_permitted`.
- `tests/gate.test.ts` — 7 tests, each naming the rule it holds.

## Running

```sh
deno task test
```

Where the downloaded SQLite library needs a newer C library than the machine has, point `DENO_SQLITE_PATH` at the system's `libsqlite3.so.0`.
