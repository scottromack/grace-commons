# Coverage matrix — Actor Suspension

> Formal-layer **coverage cross-check** (the section titled *The coverage cross-check* in pressure-testing.md).
> First emitted 2026-10-27 with the page's re-derived model. The formal-layer vote of Final Critique 4 (2026-06-10) was yes;
> the model on disk until this one verified the one-transaction cascade with rollback the 2026-08-29 turn retired, and the
> Ledger's formal line had read *pending* since.

- **Pattern:** `compositions/actor-suspension.md`
- **Models:** `actor-suspension.tla` (one actor, a planned grant and credential and a post-snapshot grant; up to two cascades with a reinstatement between; the stop at the outcome, the resume, the sweep, the post-commit index writes, the high-water mark, the tail read and the audit horizon) + `-buggy-rollback`, `-buggy-unresolved`, `-buggy-absentactive`, `-buggy-agedresume`, `-buggy-unordered` + probes `-probe-stop`, `-probe-resume`, `-probe-sweep`, `-probe-agedcompletion`, `-probe-miss`, `-probe-latewrite`, `-probe-reinstate`, `-probe-issue`, `-probe-secondcascade`
- **Reviewer / date:** the model's author, the settling session of Final Critique 6 (the mayor) — 2026-10-27. Not a fresh-context read; the next scheduled rescan owes one.
- **Formal-layer vote load-bearing claims:** multi-surface revocation (a suspended actor holds no planned member active, Invariant 1.1 through 1.3), the issuance gate's reading (no actor the trail holds suspending or suspended reads active, Capability requirement 40 through 42 through the miss rule), the sealed enumeration (an outcome names its plan's whole revoked set, Invariant 2), completion rather than undoing (Wiring decision 2, 3), and one outcome per invocation (Identity 15, Invariant 1.10).
- **Layering:** no model imports another. Permissions, Session and Credential enter as their contracts — a revoke closes a member standing active, a closed member stays closed, and a benign terminal answer closes nothing new (their own models prove the atoms). Audit Trail's records land with their action (Execution Contract Database 1); of its refusals the model takes the one that stops a cascade at its outcome.

## Step 1 — harness run (must pass)

- `actor-suspension.tla` → `HOLDS` ✓ *(36,044 states, every state explored; about a minute in the harness)*
  - `-buggy-rollback` → `CAUGHT` ✓ *(3; NoUnrevoke)* · `-buggy-unresolved` → `CAUGHT` ✓ *(4; Inv1_1)* · `-buggy-absentactive` → `CAUGHT` ✓ *(2; GateSafe — the page at 94f7de6, a finding)* · `-buggy-agedresume` → `CAUGHT` ✓ *(164; OutcomeHonest — the page at 94f7de6, a finding)* · `-buggy-unordered` → `CAUGHT` ✓ *(244; GateSafe — the page at 251321c, the model's finding)*
  - `-probe-stop` *(3)*, `-probe-resume` *(11)*, `-probe-sweep` *(12)*, `-probe-agedcompletion` *(164)*, `-probe-miss` *(2)*, `-probe-latewrite` *(7)*, `-probe-reinstate` *(5)*, `-probe-issue` *(4)*, `-probe-secondcascade` *(18)* → each rejected ✓

`node audit.mjs --only compositions/actor-suspension`: 15 models, 1 HOLDS, 14 CAUGHT, 0 problems. Each twin is the model byte for byte below a two-line header with one constant flipped in its .cfg; each probe adds one invariant. The checker refuses a step that leaves a variable undefined, so every step it took defined all eight; the twins take the branches the main model disables (the retired unresolved arm, the rollback).

## Step 2 — coverage matrix

| Spec invariant or claim | Load-bearing (vote)? | Verdict | Model construct / reason |
|---|---|---|---|
| Invariant 1.1 through 1.3 — a suspended actor holds no planned member active | YES | **covered** | `Inv1_1`, at every state. `-buggy-unresolved`: a credential Credential refuses as invalid-request named unresolved and the outcome recorded with it live (Action wiring 35 before Final Critique 6; Final Critique 6's eos F3). |
| Invariant 1.5 through 1.9 — a stopped cascade stands suspending until a resume or the sweep completes it | YES | **covered** | The stop at the outcome leaves an open intent the gate reads suspending (`GateSafe`), and a resume or the sweep completes it with one outcome (`OneOutcome`); `-probe-stop`, `-probe-resume`, `-probe-sweep` show each path taken. The completion window is arithmetic, not an interleaving: out of scope. |
| Invariant 1.12 — no claim over a post-snapshot member | no | **covered** | The post-snapshot grant `x` enters a plan only at a later snapshot; `Inv1_1` reads the plan alone. `-probe-issue`. |
| Invariant 2.2 through 2.5, 2.8; Wiring decision 8 — an outcome names its plan's whole revoked set, unresolved members included | YES | **covered — finding, cured** | `OutcomeHonest`. **Finding, cured on the page in Final Critique 6:** a resume of an open cascade whose intent had aged out had no rule, and reading its unreadable plan as empty names an empty revoked set with no marker (`-buggy-agedresume`); Reconciliation 25 and 26 now bind every cascade, so a resume snapshots the actor's active members and marks its outcome (Final Critique 6's linus FF3). `-probe-agedcompletion`. |
| Wiring decision 2, 3; Composes 24; Atomic writes 3 — a cascade is completed, never undone | YES | **covered** | `NoUnrevoke`. `-buggy-rollback`: the stop undoing its revocations, the one-transaction rollback wiring the 2026-08-29 turn retired (the twin the formal line asked for). |
| Identity 15; Invariant 1.10 — one outcome per invocation id | YES | **covered** | `OneOutcome`: a resume and the sweep over one open cascade serialize (Execution Contract Database 2), and the later finds the outcome. |
| Capability requirement 40 through 42; Composition state 20 through 29, 54 — the issuance gate refuses a suspending or suspended actor, an absent key resolved by the tail read above the mark | YES | **covered — finding, cured** | `GateSafe`. **Finding, cured on the page in Final Critique 6:** Composition state 29 read an absent key as active wherever no open intent stood above the mark, so an actor whose suspension had just committed, its entry not yet written, read active (`-buggy-absentactive`, two states in); it now asks for no suspension intent, and Composition state 54 reads the tail read's events as the rebuild does. `-probe-miss`. |
| Composition state 27, 55 — an entry is answered, and written, only against the log's order | YES | **covered — the model's finding, cured** | `GateSafe`. **The model's finding, cured on the page in the commit that lands it:** with no rule ordering the post-commit index writes, a reinstatement's active entry written after a later suspension was indexed and the mark advanced past it stood below the mark and read a suspended actor as active (`-buggy-unordered`; open line 2026-10-26-e at 251321c). Composition state 55: a writer writes no entry over one whose event stands later in the log. `-probe-latewrite`. |
| Composition state 18; Reconciliation 4, 6, 7 — the index outside every transaction; the sweep indexes before it advances the mark | no | **covered** | The model's index writes follow their act's commit, in any order or lost, and its sweep advances the mark only over what it indexed; `GateSafe` holds over every interleaving. |
| Invariant 5.1 through 5.9 — authentication precedes every revocation | no | out-of-scope (credentials) | The model checks no credential and no attribution (Ledger 2026-08-30-i). |
| Primitive policy 19, 20 — the plan cap | no | out-of-scope (sizes) | The plan holds at most three members. |
| Action wiring 90; Primitive policy 11 — a constituent's storage-failure or invalid-request commits nothing | no | by-construction | Each action is one transaction (Database 1), so a failed act is no step. |
| Composition state 32 through 40 — the rebuild | no | out-of-scope (rebuild) | The model rebuilds nothing; the tail read takes the rebuild's reading (Composition state 54). |
| Invariant 4.1 through 4.7 — the constituents' invariants hold | no | out-of-scope (constituents) | Each constituent's own model. |

## Result

Every vote-named claim the model takes is covered by a named check with a twin that breaks it. Two findings Final Critique 6 cured stand as twins of the page at its frozen commit, and one the model found is cured on the page in the commit that lands it. Credentials, attribution, the plan cap, the completion window's arithmetic and the rebuild are out of scope, the first recorded as open line 2026-08-30-i.
