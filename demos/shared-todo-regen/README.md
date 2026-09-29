# Shared Todo — cold regeneration

> **Scope.** Regenerated 2026-09-28 from the specs as they stood at commit `5343d4d`: [`compositions/shared-todo.md`](../../compositions/shared-todo.md), [`atoms/personal-todo.md`](../../atoms/personal-todo.md), [`atoms/permissions.md`](../../atoms/permissions.md) and [`atoms/assignment.md`](../../atoms/assignment.md). The domain only: the gate, the cascade, the seven actions and the two derived queries. The gaps it met were closed in the spec the same day, and the render follows the closed page (council read 258).

No earlier render of this composition exists, so there is nothing to compare it against; the regeneration's yield is the spec findings in `CORNERS.md`.

**Cold exposure.** The author read the prose spec the 2026-09-14 rewrite replaced, to check what the rewrite changed. Permissions and Assignment are carried from the [Multi-Party Approval regeneration](../multi-party-approval-regen/); Assignment gains [Reassign] and Permissions its read, which that composition never reached. Personal Todo is rendered here for the first time. `src/faults.ts` is carried from the [Authenticated Actor regeneration](../authenticated-actor-regen/).

## Source

- `src/store.ts` — one SQLite database holding the three constituents' stores; the composition stores nothing.
- `src/atoms.ts` — Personal Todo, Permissions and Assignment, as far as the composition reaches them.
- `src/composition.ts` — the gate and the nine actions.
- `tests/shared-todo.test.ts` — 12 tests, each naming the rule it holds.

## Running

```sh
deno task test
```

The tests use in-memory databases. Where the downloaded SQLite library needs a newer C library than the machine has, point `DENO_SQLITE_PATH` at the system's `libsqlite3.so.0`.
