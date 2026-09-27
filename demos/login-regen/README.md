# Login — cold regeneration

> **Scope.** Regenerated 2026-09-27 from the specs as they stood at commit `4ceccfa`: [`compositions/login.md`](../../compositions/login.md), its constituents [`atoms/credential.md`](../../atoms/credential.md), [`atoms/session.md`](../../atoms/session.md) and [`compositions/audit-trail.md`](../../compositions/audit-trail.md), and the atoms Audit Trail reaches. The domain only: no server, no views, no deployment. The gaps it met were closed in the spec the same day, and the render follows the closed page (council read 234).

The purpose is the comparison. Login's only earlier render is inside the [clinical-trial portal](../clinical-trial-portal/), built against the specs of 2026-05; the two are compared in `CORNERS.md`, the section titled *Against the portal's login*.

**Cold exposure.** Before writing this render the author had written the portal's drift section from the specs, and read the prose spec that preceded the 2026-09-14 rewrite of Login to settle what the rewrite left undecided (see `CORNERS.md`). The portal's code was opened only for the comparison. `src/audit_trail.ts`, `src/substrate_atoms.ts` and `src/faults.ts` are carried over from the [Multi-Party Approval regeneration](../multi-party-approval-regen/), itself rendered from the specs alone.

## Source

- `src/store.ts` — one SQLite database. Triggers keep the two maps' entries and the login event log unchanged and unremoved (Composition state 4, 5, 9).
- `src/seam.ts` — the host's clock and every id, the session token among them.
- `src/atoms.ts` — Credential and Session.
- `src/audit_trail.ts`, `src/substrate_atoms.ts` — Audit Trail to the depth Login reaches, and the atoms it reaches.
- `src/composition.ts` — login, logout, the cascade, the map rebuild and the sweep.
- `tests/login.test.ts` — 21 tests, each naming the rule it holds.

## Running

```sh
deno task test
```

The tests use an in-memory database. Where the downloaded SQLite library needs a newer C library than the machine has, point `DENO_SQLITE_PATH` at the system's `libsqlite3.so.0`.
