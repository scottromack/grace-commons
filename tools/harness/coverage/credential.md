# Coverage matrix — `credential`

- **Pattern:** `atoms/credential.md`, grounded in English on Final Critique 12 (2026-09-29).
- **Model:** `credential.tla` + four isolated twins: `credential-buggy.tla` (Invariant 7.1), `credential-buggy-toctou.tla` (Capability requirement 8), `credential-buggy-overdue.tla` (Capability requirement 23), `credential-buggy-rotate-race.tla` (Operation 65).
- **Reviewer / date:** re-derived 2026-09-29, closing the Ledger's formal line: per-credential deadlines, a call's reading held from its start to its commit, the pair's critical section with an overdue holder, and revoke outside the section. Supersedes the 2026-06-21 matrix, whose model carried one deadline for every credential and one reading per step.
- **Formal-layer vote load-bearing claims:** Invariant 2.1 at a settled reading, Invariant 7.1, and Invariant 12 (expiry derived, never stored).

## Step 1 — harness re-run (must pass)

- Correct model: `node check.mjs ../../atoms/credential.tla` → `PASS` — 36,772 states, all five invariants hold (`MaxClock = 2`, `MaxC = 3`, `Calls = 2`).
- `credential-buggy.tla --buggy` → rejected at 173 states: a rotate stands the prior in rotated without writing its successor link.
- `credential-buggy-toctou.tla --buggy` → rejected: no section, so two calls both pass the uniqueness check and both commit.
- `credential-buggy-overdue.tla --buggy` → rejected: a holder released as overdue still commits beside the next holder's credential.
- `credential-buggy-rotate-race.tla --buggy` → rejected: without Operation 65, a rotate begun on an early reading commits its successor beside a credential a register on a later reading committed first.

Isolation, checked with a configuration naming `TypeOK` and one invariant: each of the three uniqueness twins violates `Inv_EffectiveActiveUniqueness` and holds `Inv_RotationChain` (35,848; 40,394; 36,788 states). The rotation-chain twin shares the correct model's register and section, so its uniqueness holds.

## Step 2 — coverage matrix

| Spec invariant | Load-bearing (vote)? | Verdict | Model construct / reason |
|---|---|---|---|
| Invariant 1 — Registration immutability | no | by-construction | No action rewrites `deadline` or `registered` on a used slot; only `status` and `successor` move. |
| Invariant 2.1 — Effective-active uniqueness at a settled reading | YES | **covered** | `Inv_EffectiveActiveUniqueness == \A c : Settled(c) => EffActiveCount(c) <= 1`, over per-credential deadlines and every reading from 0 to `MaxClock`. |
| Invariant 3 — Sole-holder verification | no | out-of-scope | Verify, the derivation and the check functions are not modelled. |
| Invariant 4, 5 — Revocation and stored terminals absorbing | no | by-construction | No action leaves `Rotated` or `Revoked`. |
| Invariant 6 — Rotation does not mutate | no | by-construction | A rotate writes the prior's `status` and `successor` only. |
| Invariant 7.1 — Every rotated credential names a successor | YES | **covered** | `Inv_RotationChain`; twin `credential-buggy.tla`. Invariant 7.2 (same pair) holds by construction: the model is one pair. |
| Invariant 8, 9, 10 — Material, revocation record, durability | no | out-of-scope | Storage and field properties, not state-machine ones. |
| Invariant 11 — A lapse precludes verification | no | by-construction | Verify is not modelled; a lapsed credential is not effective-active at the reading, which is what every guard reads. |
| Invariant 12 — Expiry derived, never written | YES | **covered** | `Inv_NoStoredExpired` and `Inv_DerivedExpiryCoherent` at every reading. |
| Capability requirement 8, 22, 23; Operation 65 | mechanism | **covered by twins** | Each is removed in one twin, and each removal breaks Invariant 2.1. |

## Step 3 — bound saturation

`MaxClock = 2` gives readings 0, 1 and 2 and deadlines 1, 2 and none (3), which is every ordering the races need: a prior lapsing at 1, a rotate reading 0, a register reading 1, and a later credential with a deadline or none. The store may begin empty or holding one active credential with any deadline, so two calls reach every race over one prior, and `MaxC = 3` holds the prior, a register's credential and a rotate's successor. `MaxClock = 3` did not finish inside the local 180-second window and was not run to completion.

## Outcome

- GAP rows: none. The three load-bearing claims are asserted, and each mechanism the English added on 2026-09-29 — the section, the overdue holder's refused commit, Operation 65 — has a twin whose removal breaks Invariant 2.1.
