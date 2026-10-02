# Notes — the cold-reader gate loop (opened 2026-10-02)

> **Status: internal, running notes. Not canonical.** Append dated lines; do not rewrite earlier ones. Opened after the complexity-ratchet decision of 2026-10-02 (`pressure-testing.md`, *Triage fields for a gate round*) to record what the new process does and does not do, round by round, on [Audit Trail](../compositions/audit-trail.md).

## Rounds under the new template

| Round | Foundational by reader (GRID, EOS, Linus) | Kind | Blame fresh : older | Rejected on triage | Net rules |
|---|---|---|---|---|---|
| 18 (2026-10-02) | 5, 2, 3 = 10 | all A | 7 : 3 | 0 of 10 (one closed by dated record) | about +5 |

Before the template (rounds 9 to 17): 3 to 10 foundational per round, about half in rules added the round before.

## What works

- **Readers find real defects.** Every round-18 foundational finding named a reachable state or two diverging implementations; none was rejected as wrong.
- **The blame field shows churn.** Seven of ten findings sat in rules changed within two rounds. Without the field it reads as ten new gaps.
- **A dated record is a real exit.** One finding closed as a recorded behavior the page already declared for derived indexes, with an owner, and nothing was added to the page's protocol.
- **One reader at a time runs.** Parallel readers stall the machine. Reports under 900 words are readable.
- **Commit first, process second.** Process and content landed as separate commits (`0acc8d8`, `3760070`).

## What does not

- **Triage did not brake.** Readers rate their own findings kind A and each one checked out against the page, so all ten were cured the same pass. Timing and ordering defects are kind A by nature; the template sorts them and does not thin them.
- **Cures spawn findings.** The closure floor's seal term undercounted (Linus pass); a no-answer arm added at two Purge Event reads left three sibling reads bare (same pass).
- **Later readers read earlier readers' cures.** Reader 3 found a defect in a cure made after reader 1. The tree is not frozen across a round's three passes.
- **The budget is per reader.** Three readers at five each is fifteen; the declared budget of 5 is not a round limit.
- **Refining findings go unrouted.** About 35 held "for the round close" in a scratch file outside the repo. That is silent in the sense the grounding rule means.
- **The same stale line costs a slot every round.** The Ledger's `last gate: 2026-08-25 … clean` was reported by all three readers.
- **Old gaps still surface.** Three of ten were older rules, so the page is not only churning on its own cures.

## Ideas to fix

1. **Freeze the tree for a round.** All three passes read the same tree; cure once after the third, with the sibling sweep below. Costs duplicate findings across readers; measure the overlap.
2. **Sibling sweep before every cure.** List the rules a cure's rule has siblings among (arms on reads, seals in sums, edges of a window) and cure them as one rule. Purge event 8 did this after the fact.
3. **Move the arithmetic to the Lease atom.** Closure floor, call pause, work bound, leg lease sizing: the page cites the atom's sizing rule instead of carrying it. This is the promotion candidate on the Lease atom's open line 2026-09-10-a; the timing cluster recurs in at least four rounds.
4. **Redo, not patch, a fresh-blame finding.** When the finding sits in a rule added within two rounds, re-derive the original cure with the finding in hand instead of adding a clause beside it.
5. **Budget per round.** Five ranked foundational per round across all passes; the rest counted as seen, not cured, and routed.
6. **Route refining at the round close.** Ledger open lines or one dated sentence naming what was held and why; the list lives in the repo.
7. **Fix the stale Ledger line** so no reader spends a slot on it.
8. **Count overlap.** Findings seen by more than one reader are the strongest; findings seen by one reader are the sample.

## Open questions

- Does a frozen tree lower the fresh share, or only move findings between readers?
- What does the page's asymptote look like once the timing cluster leaves it?
- Does the rejection rate rise on a page whose findings are not timing defects?

## Log

- 2026-10-02 · round 18 · opened; numbers above.
