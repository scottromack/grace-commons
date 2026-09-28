# Notification Fanout — cold regeneration

> **Scope.** Regenerated 2026-09-28 from the specs as they stood at commit `4e4964e`: [`compositions/notification-fanout.md`](../../compositions/notification-fanout.md) and its constituents [`atoms/subscription.md`](../../atoms/subscription.md) and [`atoms/notification.md`](../../atoms/notification.md). The domain only: no server, no views, no deployment, no delivery layer. The gaps it met were closed in the spec the same day, and the render follows the closed page (council read 250).

No earlier render of this composition exists, so there is nothing to compare it against; the regeneration's yield is the spec findings in `CORNERS.md`.

**Cold exposure.** The author read this page's Ledger line by line against the page at council read 246, the same day, and read the prose spec the 2026-09-14 rewrite replaced to check what it dropped. `src/faults.ts` and `src/seam.ts` are carried from the [Audit Trail regeneration](../audit-trail-regen/).

## Source

- `src/store.ts` — one SQLite database: the subscription store and the notification store.
- `src/atoms.ts` — Subscription and Notification, as far as the fanout reaches them.
- `src/composition.ts` — the one action.
- `tests/fanout.test.ts` — 7 tests, each naming the rule it holds.

## Running

```sh
deno task test
```

The tests use an in-memory database. Where the downloaded SQLite library needs a newer C library than the machine has, point `DENO_SQLITE_PATH` at the system's `libsqlite3.so.0`.
