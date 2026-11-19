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

The Edge Finder reads a composition's closure tables (`Action | Input | Lands | Owner` and `Answer | Lands | Owner`) from the IR and writes one check for each row (`rounds/seam-trial-code/gen_tests_calls.py`, unit `tooling: the Edge Finder scores a composition, Login first`, 2026-11-16). It was written for Login; since 2026-11-18 (unit `tooling: the Edge Finder reads a second composition, Session-Gated Authorization first`) a composition is read by its own reader and Session-Gated Authorization has one. What is Login's alone (the cascade reason prefix, its eleven untyped inputs, its settings) stays behind Login's reader; a composition with no reader stops the generator with its name.

| Pattern | Case-table rows | Edge Finder on the render |
|---|---|---|
| Login | 41 | **38 run (57 scenarios), 38 passing, 3 not run** (the length bound, the retention period and the byte-exact property: the pattern names no setting for them): `tests/case/login.case.test.ts`, run in `bun test` |
| Session-Gated Authorization | 9 | **9 run (15 scenarios), 9 passing, 0 not run**: `tests/case/session_gated_authorization.case.test.ts`, run in `bun test` (the two constituents answer by script; no store is needed). 11 of 11 Fault Plants on `src/session_gated_authorization.ts` are seen by these Case Tests alone (`tests/case/plant_sga_case.py`); the first run of the plants saw 9 of 11, the two unseen (a trimmed token, a case-folded scope) showing the opaque-input row's first scenario used inputs with nothing to trim, and the generator's scenario for that row now presents a padded, mixed-case token and scope. The length-bound rows run because the bound is a deployment's setting the scenarios declare (`length_bound`, Primitive policy 1), where Login's equivalent names none. |
| External Onboarding | 57 | **untested**: the generator has no reader for it |
| Audit Trail | 120 | **untested**: the generator has no reader for it |
| Recoverable Invocation | 91 | **untested**: the generator has no reader for it |
| Attributed Permissions Admin | 0 | **no case table to read**: the page has no closure table; the unit's step 6 names its case tables, and it has none |
| Permissions (an atom, 12 rows), Session (15), Actor Identity (15), Retention Window (15), Event Log (6), Tamper Evidence (10) | 73 | **untested**: the atom generator `gen_tests.py` does not run on the current IR (it reads `subject_actions` and `answer_shape`, gone since the Reader unit; `rounds/page-proof-trial.md`, the third measure, and the ask under `## Needs Scott` there) |
| Credential, Party Identity, Invitation, Lease | 0 | no case table to read |

So of the 391 case-table rows of the patterns Beacon composes, the Edge Finder has read 50 (Login's 41 and Session-Gated Authorization's 9), run 47 and passed 47, and read none of the other 341. The 3 Login rows not run and the 341 unread are the gap, named; the render's own tests cover the same patterns' rules by their labels and are not a substitute for the rows.

## The last full run before the deploy (2026-11-18)

`bun test --timeout 60000` on a fresh store, in a clone at `56f3a54e` plus this unit's files: **454 tests, 450 pass, 3 skip, 1 fail**, 1,114 seconds. The one failure is Lease's `waiters are admitted in arrival order` (`tests/lease.test.ts`): a read in `Lease.standing` answered `state-unavailable` with XTDB's own message, `cached plan must not change result type`. Run alone on fresh stores the file failed once and passed twice, so it is intermittent and not cured. What it is: a read whose plan XTDB cached before the table it reads gained its first columns is refused once, and Beacon's reads answer `state-unavailable` and write nothing (Execution Contract Read 1), so the fault fails safe; it is not a Lease rule and no rule of the page is wrong for it. It can happen on the deployed Beacon in the first seconds after a start, before every table has a row, and a person's call would then be refused once and succeed on repeat. Reported, not explained away; the cure (declaring every column of every table when it is declared, or reading again once) is a change to `src/store.ts` for the next part.

## What each pattern's page was when it was rendered (2026-11-18)

Said so no page or answer claims a build from a page the render did not read. The last commit of each page Beacon composes, against the last commit that edited its render (`git log -1 -- src/<file>`):

| Page | Last commit of the page | Rendered from it? |
|---|---|---|
| Credential, Event Log, Tamper Evidence, Retention Window, Party Identity, Invitation, Lease, Session-Gated Authorization, Recoverable Invocation, Audit Trail, External Onboarding | `3935761e` (2026-11-16) | yes: no later commit touches them |
| Attributed Permissions Admin | `1b41855c` (2026-11-16) | yes: the render's last edit, `f6c1ecae`, is later |
| Permissions | `50c77f44` (Final Critique 12, 2026-11-17: the database citation) | the render's last edit is `f6c1ecae`, after `087655cc`; Final Critique 12 is a citation and no rule |
| Actor Identity | `1895f220` (Final Critique 19; Final Critique 18 changed Read 6's paging clause) | **no**: the render's last edit is `1619f21b` (2026-11-16); Beacon reads only its registry answer and no paged read |
| Session | `376d0c3d` (Final Critique 24, 2026-11-17: a cap change meets a call in flight; an id the cap cannot supply) | **no**: the render's last edit is `4c00a76a` (2026-11-16) |
| Login | `5013eb4b` (Final Critique 16, 2026-11-17: the revocation instant leaves the sweep's match; the rebuild is a lost entry's; the login succeeded event is the service identity's own) | **no**: the render's last edit is `4c00a76a` (2026-11-16); its delta round is queued |

So the deployed Beacon is built from the library as it stood on 2026-11-16 and 2026-11-17 and not from these four pages as they now stand. The cures of Session's, Login's and Actor Identity's rounds are not in it; when each page's delta round has cleared, the parts that read it are rendered again from the changed page (the unit's rule). Nothing public says the deployed Beacon is built from the current library.

## What is not tested at all

`src/main.ts` (the boot: open, seed, serve) and `stack/start.sh` are not under `bun test`: they start a process that owns the store's port. They were run once by hand on 2026-11-18: the store came up, the seed ran, the server answered `/login` 200, signed in as the principal investigator (302 to `/dashboard`) and answered `/dashboard`, `/subjects`, `/people`, `/audit` and `/audit/verify` 200. The linux image was built by Fly's builder and not run before the deploy.

## The run for the visual design unit (2026-11-19)

`bun test --timeout 60000` on a fresh store, in a clone at `7f42d75e` plus `demo: Beacon takes the visual design system the Next render used`: **466 tests, 463 pass, 3 skip, 0 fail**, 884 seconds. Lease's `waiters are admitted in arrival order` passed this run; it is intermittent (above) and still not cured.
