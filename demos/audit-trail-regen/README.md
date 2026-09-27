# Audit Trail — cold regeneration

> **Scope.** Regenerated 2026-09-27 from the specs as they stood at commit `72da79e`: [`compositions/audit-trail.md`](../../compositions/audit-trail.md) and its four constituents, [`atoms/actor-identity.md`](../../atoms/actor-identity.md), [`atoms/event-log.md`](../../atoms/event-log.md), [`atoms/retention-window.md`](../../atoms/retention-window.md) and [`atoms/tamper-evidence.md`](../../atoms/tamper-evidence.md). The domain only: no server, no views, no deployment. The gaps it met were closed in the spec the same day, and the render follows the closed page (council read 242).

The purpose is the comparison. Audit Trail's only earlier render is inside the [clinical-trial portal](../clinical-trial-portal/), built against the specs of 2026-05; the two are compared in `CORNERS.md`, the section titled *Against the portal's audit trail*.

**Cold exposure.** Before writing this render the author had written the partial Audit Trail inside the [Multi-Party Approval regeneration](../multi-party-approval-regen/), itself rendered from the specs alone, and carried into the Login, Session-Gated Authorization and External Onboarding regenerations. Nothing was carried from it but `src/faults.ts` and the Deno configuration. The portal's code was opened only for the comparison.

## Source

- `src/store.ts` — one SQLite database. Triggers keep attestations, events and seals unchanged and unremoved, and the derived indexes and destruction records insert-only.
- `src/vault.ts` — the at-rest keying: each event's data field and each attestation's proof sealed under a key of its own.
- `src/erasure.ts` — the erasure mechanism, shredding-class: it destroys the two keys and rewrites no stored byte.
- `src/seam.ts` — the host's clock and every id.
- `src/atoms.ts` — the four constituents, as far as the composition reaches them.
- `src/composition.ts` — instance start, the six actions, the derived indexes with their rebuilds, and the reconciliation scan's three halves.
- `tests/audit.test.ts` — 18 tests, each naming the rule it holds.

## Running

```sh
deno task test
```

The tests use an in-memory database. Where the downloaded SQLite library needs a newer C library than the machine has, point `DENO_SQLITE_PATH` at the system's `libsqlite3.so.0`.
