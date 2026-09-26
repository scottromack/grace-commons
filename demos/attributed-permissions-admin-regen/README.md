# Attributed Permissions Admin — cold regeneration

> **Scope.** Regenerated 2026-09-26 from the specs as they stand at commit `1180a9b`: [`compositions/attributed-permissions-admin.md`](../../compositions/attributed-permissions-admin.md), [`atoms/permissions.md`](../../atoms/permissions.md) and [`atoms/actor-identity.md`](../../atoms/actor-identity.md). The domain only: no server, no views, no deployment.

The purpose is the comparison. The [2026-05 render](../attributed-permissions-admin/) was built against the specs of that month and never rebuilt; this one was built from today's pages alone, and the two are compared in `CORNERS.md`, the section titled *Against the 2026-05 render*.

**Cold exposure.** Before writing this render the author had read parts of the old render's `issue_grant` and its schema comments, and had written the old render's drift list from the specs. Nothing of the old render's code was consulted while writing this one; the old render was opened again only for the comparison.

## Source

- `src/store.ts` — one SQLite database holding both constituents' stores and the composition's records: the two attribution maps, the orphan log and the purge record. Triggers hold the write-once rules (Invariant 6 and 8), the disjointness of the two maps (Invariant 7.3) and the immutability of an attestation (Actor Identity Invariant 1.1). `Faults` injects the failure paths the page names.
- `src/seam.ts` — the host's seam: the clock reading, the nonce and the two atoms' handles. Nothing inside a transition reads a clock or mints an id.
- `src/actor_identity.ts` — `attest`, `verify`, and the enumeration the composition needs (see `CORNERS.md`).
- `src/permissions.ts` — `grant`, `revoke`, `permitted`, and the read and the enumeration the composition needs (see `CORNERS.md`).
- `src/composition.ts` — `start`, `issue_grant`, `revoke_grant`, `revoke_permission`, `verify_grant_attribution`, `permitted` and the failed-grant leg.
- `tests/composition.test.ts` — 28 tests, each naming the rule it holds.

## Running

```sh
deno task test
```

The tests use an in-memory database. Where the downloaded SQLite library needs a newer C library than the machine has, point `DENO_SQLITE_PATH` at the system's `libsqlite3.so.0`.
