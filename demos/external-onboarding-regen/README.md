# External Onboarding — cold regeneration

> **Scope.** Regenerated 2026-09-27 from the specs as they stood at commit `f4daa48`: [`compositions/external-onboarding.md`](../../compositions/external-onboarding.md), its constituents [`atoms/invitation.md`](../../atoms/invitation.md), [`atoms/credential.md`](../../atoms/credential.md), [`atoms/party-identity.md`](../../atoms/party-identity.md) and [`compositions/audit-trail.md`](../../compositions/audit-trail.md), and the atoms Audit Trail reaches. The domain only. The gap it met was closed in the spec the same day, and the render follows the closed page (council read 240).

Its one earlier render is the [clinical-trial portal](../clinical-trial-portal/)'s invitation flow; the two are compared in `CORNERS.md`, the section titled *Against the portal's onboarding*.

**Cold exposure.** The author had read the portal's login code for the Login regeneration, not its invitation code; that was opened only for the comparison. `src/audit_trail.ts`, `src/substrate_atoms.ts` and `src/faults.ts` are carried over from the [Login regeneration](../login-regen/).

## Source

- `src/store.ts` — the constituents' and the substrate's stores; the composition stores nothing.
- `src/atoms.ts` — Invitation, Party Identity and Credential.
- `src/composition.ts` — the four actions, the fresh arc and the resume arm, and the host's critical section.
- `tests/onboarding.test.ts` — 17 tests, each naming the rule it holds.

## Running

```sh
deno task test
```

Where the downloaded SQLite library needs a newer C library than the machine has, point `DENO_SQLITE_PATH` at the system's `libsqlite3.so.0`.
