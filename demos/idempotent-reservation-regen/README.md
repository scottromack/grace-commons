# Idempotent Reservation — cold regeneration

> **Scope.** Regenerated 2026-09-28 from the specs as they stood at commit `accbdb9`: [`compositions/idempotent-reservation.md`](../../compositions/idempotent-reservation.md) and its constituents [`atoms/provisional-commitment.md`](../../atoms/provisional-commitment.md) and [`atoms/duplicate-prevention.md`](../../atoms/duplicate-prevention.md). The domain only: no server, no views, no deployment. The gaps it met were closed in the spec the same day, and the render follows the closed page (council read 248).

No earlier render of this composition exists, so there is nothing to compare it against; the regeneration's yield is the spec findings in `CORNERS.md`.

**Cold exposure.** Before writing this render the author had written none of this composition's code. To settle what the 2026-09-14 rewrite left undecided, the author read the prose spec that preceded it (see `CORNERS.md`). `src/faults.ts` is carried from the [Audit Trail regeneration](../audit-trail-regen/).

## Source

- `src/store.ts` — one SQLite database: the commitment store, Duplicate Prevention's recorded set, and the token results map.
- `src/seam.ts` — the host's clock, every id, and the parameters digest.
- `src/atoms.ts` — Provisional Commitment and Duplicate Prevention.
- `src/composition.ts` — instance start, the four token-carrying actions with their re-entry arms, and the eviction leg.
- `tests/reservation.test.ts` — 14 tests, each naming the rule it holds.

## Running

```sh
deno task test
```

The tests use an in-memory database. Where the downloaded SQLite library needs a newer C library than the machine has, point `DENO_SQLITE_PATH` at the system's `libsqlite3.so.0`.
