# Multi-Party Approval — cold regeneration

> **Scope.** Regenerated 2026-09-26 from the specs as they stood at commit `2ff9caf`: [`compositions/multi-party-approval.md`](../../compositions/multi-party-approval.md), its constituents [`atoms/approval-step.md`](../../atoms/approval-step.md), [`atoms/permissions.md`](../../atoms/permissions.md), [`atoms/assignment.md`](../../atoms/assignment.md) and [`compositions/audit-trail.md`](../../compositions/audit-trail.md), and the atoms Audit Trail reaches. The domain only: no server, no views, no deployment. The seven spec findings it surfaced were cured the same day, and the render follows the cured pages (council read 232).

The purpose is the comparison. The [2026-05 render](../multi-party-approval/) was built against the specs of that month and never rebuilt; this one was built from today's pages alone, and the two are compared in `CORNERS.md`, the section titled *Against the 2026-05 render*.

**Cold exposure.** Before writing this render the author had written the old render's drift section from the specs, without reading its code. The old render was opened only for the comparison.

## Source

- `src/store.ts` — one SQLite database holding every store. Triggers hold a chain record's permanence, a terminal chain's absorption and the declared fields' immutability (Composition state 8; Invariant 7 and 8).
- `src/seam.ts` — the host's clock and every id.
- `src/faults.ts` — fault injection for the failure arms the specs name.
- `src/atoms.ts` — Actor Identity, Event Log, Retention Window, Permissions, Approval Step and Assignment, as far as the composition and Audit Trail reach them.
- `src/audit_trail.ts` — Audit Trail to the depth this composition reaches (see `CORNERS.md`).
- `src/composition.ts` — the six actions, the quorum rule, the chain evaluation, the cascade, the initiation recovery and the sweep's four legs.
- `tests/actions.test.ts`, `tests/recovery.test.ts` — 31 tests, each naming the rule it holds.

## Running

```sh
deno task test
```

The tests use an in-memory database. Where the downloaded SQLite library needs a newer C library than the machine has, point `DENO_SQLITE_PATH` at the system's `libsqlite3.so.0`.
