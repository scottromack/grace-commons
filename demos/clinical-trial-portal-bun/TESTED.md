# What Beacon's render is tested by, and what it is not

Said as the unit's step 6 asks: the render's own tests, then the Edge Finder's Case Tests for every pattern Beacon uses, with rows, checkable, passed and each miss named; a pattern the generator cannot read is named untested, not passed over. Measured on the render at the commit the entry names, with `bun test` on a fresh store (`bash stack/stack.sh restart` first; a store that has run for hours makes two timing tests fail that pass alone).

## The render's own tests

Every rule a part rendered has a test that names it in its title, and every part was proved by planting faults: one change to one line, the tests run, a plant is seen when a test fails. The plant scripts are `tests/case/plant_*.py`; each part's entry in `rounds/escalations.md` gives its count (every plant seen, but those named equivalent or unreachable there and dropped from the count, such as a call with no key that the composition itself refuses).

| Pattern or part | Its tests (files) |
|---|---|
| Credential, Session, Event Log, Tamper Evidence, Actor Identity, Retention Window, Party Identity, Invitation, Lease, Permissions | 11, 9, 9, 9, 9, 7, 9, 8, 7, 7 |
| Login | 12 + 10 (the sweep) + the 38 Case Tests below |
| Session-Gated Authorization | 7 |
| Recoverable Invocation | 31 + 25 (the sweep) + 27 (resolve and read) |
| External Onboarding | 23 + 29 (Onboard) |
| Attributed Permissions Admin | 23 |
| Audit Trail | 8 + 10 (sealing, reading and verifying a record) |
| Beacon's own parts | the domain 15, the people and their keys 8, the composition root 9, invitations 12, the audit screens' part 10 + 7, People & Permissions 9, the seed 5 |
| The pages | 23 (sign in, the dashboard, subjects), 6 (accepting an invitation), 5 + 4 (Audit Trail, chain verification, export), 9 (People & Permissions) |

## The Edge Finder's Case Tests

The Edge Finder reads a composition's closure tables (`Action | Input | Lands | Owner` and `Answer | Lands | Owner`) from the IR and writes one check for each row (`rounds/seam-trial-code/gen_tests_calls.py`, unit `tooling: the Edge Finder scores a composition, Login first`, 2026-11-16). It was written for Login and reads Login alone.

| Pattern | Case-table rows | Edge Finder on the render |
|---|---|---|
| Login | 41 | **38 run (57 scenarios), 38 passing, 3 not run** (the length bound, the retention period and the byte-exact property: the pattern names no setting for them): `tests/case/login.case.test.ts`, run in `bun test` |
| Session-Gated Authorization | 9 | **untested**: the generator stops on `the cascade reason prefix is not in the IR`, a Login-only assertion |
| External Onboarding | 57 | **untested**, the same stop |
| Audit Trail | 120 | **untested**, the same stop |
| Recoverable Invocation | 91 | **untested**, the same stop |
| Attributed Permissions Admin | 0 | **no case table to read**: the page has no closure table; the unit's step 6 names its case tables, and it has none |
| Permissions (an atom, 12 rows), Session (15), Actor Identity (15), Retention Window (15), Event Log (6), Tamper Evidence (10) | 73 | **untested**: the atom generator `gen_tests.py` does not run on the current IR (it reads `subject_actions` and `answer_shape`, gone since the Reader unit; `rounds/page-proof-trial.md`, the third measure, and the ask under `## Needs Scott` there) |
| Credential, Party Identity, Invitation, Lease | 0 | no case table to read |

So of the 391 case-table rows of the patterns Beacon composes, the Edge Finder has read 41 (Login's), run 38 and passed 38, and read none of the other 350. The 3 Login rows not run and the 350 unread are the gap, named; the render's own tests cover the same patterns' rules by their labels and are not a substitute for the rows.
