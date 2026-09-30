# Credential — cold regeneration

> **Scope.** Regenerated 2026-09-29 from [`atoms/credential.md`](../../atoms/credential.md) as it stood at commit `4e68b2b`, after Final Critique 7 and its cure. The atom whole: the five actions, the per-pair critical section with its lease, and a derivation registry with three real credential types — a salted, costed password hash, an API-token hash, and an Ed25519 public key checked against a signed challenge. The gaps it met were closed in the spec the same day, and the render follows the closed page (council read 266).

The purpose is the builder's check the page had never had. Credential was rendered before only as far as [Login](../login-regen/) reached it, with one unsalted hash; the two are compared in `CORNERS.md`.

**Cold exposure.** The author had carried the Login render's Credential into three regenerations and wrote much of the page's current text at reads 262 and 264, so this render is a builder's check rather than a stranger's; the cold re-gate goes to a new session. `src/faults.ts` is carried from the [Authenticated Actor regeneration](../authenticated-actor-regen/).

## Source

- `src/seam.ts` — the clock, the id material and the entropy a salted derivation consumes.
- `src/registry.ts` — the deployment's derivation and check functions per type, run at the seam.
- `src/store.ts` — the credential store; triggers hold no removal, no changed property and an absorbing terminal.
- `src/sections.ts` — the per-pair critical section with its lease.
- `src/credential.ts` — [Register], [Verify], [Rotate], [Revoke] and [Read].
- `tests/credential.test.ts` — 13 tests, each naming the rule it holds.

## Running

```sh
deno task test
```

The tests use in-memory databases. Where the downloaded SQLite library needs a newer C library than the machine has, point `DENO_SQLITE_PATH` at the system's `libsqlite3.so.0`.
