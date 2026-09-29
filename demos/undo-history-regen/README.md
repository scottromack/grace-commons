# Undo History — cold regeneration

> **Scope.** Regenerated 2026-09-28 from the specs as they stood at commit `babe179`: [`compositions/undo-history.md`](../../compositions/undo-history.md), [`atoms/personal-todo.md`](../../atoms/personal-todo.md) and [`atoms/event-log.md`](../../atoms/event-log.md). The domain only: the six actions, the five event schemas and the replay. The gaps it met were closed in the spec the same day, and the render follows the closed page (council read 260).

No earlier render of this composition exists, so there is nothing to compare it against; the regeneration's yield is the spec findings in `CORNERS.md`.

**Cold exposure.** The author read the page as it stood before the 2026-09-14 rewrite, to check what the rewrite changed: it was already in rule form, and the rewrite changed nothing but spelling. Personal Todo is carried from the [Shared Todo regeneration](../shared-todo-regen/), Event Log from the [Login regeneration](../login-regen/); Event Log's read takes a query and answers invalid-query, which Login never reached. `src/faults.ts` is carried from the [Authenticated Actor regeneration](../authenticated-actor-regen/).

## Source

- `src/store.ts` — the event log instance, append-only, and the schema of the derived state each replay builds fresh.
- `src/atoms.ts` — Personal Todo and Event Log, as far as the composition reaches them.
- `src/composition.ts` — the replay, the four forward actions, [Undo] and [Read History].
- `tests/undo-history.test.ts` — 12 tests, each naming the rule it holds.

## Running

```sh
deno task test
```

The tests use in-memory databases. Where the downloaded SQLite library needs a newer C library than the machine has, point `DENO_SQLITE_PATH` at the system's `libsqlite3.so.0`.
