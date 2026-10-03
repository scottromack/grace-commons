# Audit Trail — the gate record (opened 2026-10-02)

> **Status: internal, running record. Not canonical.** One place for the counts, so a round is counted once and the same way. Append rows; correct a row only with a dated line under it. Sources: the commit messages of `compositions/audit-trail.md`, and the reader reports of the session transcript (the counts below are each reader's own).

## How a round is counted

1. **Round.** The reader runs made on one tree and cured together. Rounds are numbered by the commit subjects, from the gates of 2026-09-30; a halted launch that returned no report is not a round.
2. **Final Critique number.** The Ledger carried Final Critique 11 as its last recorded gate (2026-08-25). Each round since counts as one Final Critique, so **Final Critique = 11 + round**. This is the assumption the numbers rest on; it holds only if every round counted ran as a gate.
3. **Report.** One foundational finding in one reader's report. **Group:** the reports of one defect on one tree. A defect found again after a cure is a new group on the new tree, marked *repeat*.
4. **Headline count: distinct foundational groups.** Raw reports are shown beside it and never alone. Kind (A defect, B hardening, C ownership, D preference) and blame (fresh, older) are counted on groups.
5. **Refining and rhetorical** findings are counted as reports per reader and never added into a headline across readers; the Ledger's `last gate` line says "reports".
6. **Unit of comparison.** Two-reader rounds (12 to 18: state machine and implementer lenses) and three-pass rounds (19 on: GRID, EOS, Linus) have different readers; compare reports per reader and groups per round within a format, not across.

## Rounds

| Round | Final Critique | Format | Foundational reports (by reader) | Groups | Refining / rhetorical reports | Commit |
|---|---|---|---|---|---|---|
| 1 to 11 | 12 to 22 | not itemised here | not recorded in the repo or the transcript | | | `7d809f9` to `8df1491` |
| 12 | 23 | 2 readers | 4 + 4 = 8 | not grouped | 27 / 9 | in `8df1491` |
| 13 | 24 | 2 readers | 6 + 2 = 8 | not grouped | 27 / 5 | in `8df1491` |
| 14 | 25 | 2 readers | 4 + 6 = 10 | not grouped | 22 / 4 | in `8df1491` |
| 15 | 26 | 2 readers | 3 + 6 = 9 (2 arguable) | not grouped | 21 / 6 | in `8df1491` |
| 16 | 27 | 2 readers | 5 + 2 = 7 (+1 borderline) | not grouped | 13+ / 3+ | in `8df1491` |
| 17 | 28 | 2 readers | 4 + 1 = 5 | not grouped | 20 / 5 | in `8df1491` |
| 18 | 29 | 2 readers | 3 + 2 = 5 | not grouped | 19+ / 4+ | in `8df1491` |
| 19 | 30 | 3 passes | 5 + 2 + 3 = 10 | 10 | 32 / 8 | `3760070` |
| 20 | 31 | 3 passes, frozen tree | 3 + 2 + 5 = 10 | 8 | 31 / 6 | `e85690e` |
| 21 | 32 | 3 passes, frozen tree | 2 + 0 + 5 = 7 | 5 | 39 / 13 | `607c5f5` |

Rounds 12 to 18 counts are each reader's own count line; reader reports were not grouped across readers then, and the round-16 and round-18 refining counts are lower bounds (a reader's count was lost to a context compaction, or a borderline finding was counted apart). A "+" marks that.

**Numbering correction (2026-10-02).** The subjects of `3760070`, `e85690e` and `607c5f5` say rounds 18, 19 and 20. They are rounds 19, 20 and 21: round 18 is the two-reader gate inside `8df1491` (3 + 2), and a round 19 launched that day was halted before any reader returned. The Ledger's `last gate` read "Final Critique 19" and "20" for the same reason; it now reads 30 to 32 by the rule above.

## Groups, rounds 19 to 21

**Round 19** (tree changed between readers; 10 reports, 10 groups, all kind A; fresh 7, older 3)

| Group | Defect | Readers | Blame | Outcome |
|---|---|---|---|---|
| 19-1 | Purge Event's step-0 and step-0½ reads have no no-answer arm | GRID | fresh | cured |
| 19-2 | Concurrency 3a serialization has no expiry gate under a re-drive | GRID | fresh | cured |
| 19-3 | Read Record and Verify Record disagree while a coverage entry is missing | GRID | older | recorded, not cured |
| 19-4 | Closure floor omits the per-event seal | GRID | fresh | cured |
| 19-5 | Hold-release window has no declared source instant | GRID | fresh | cured |
| 19-6 | Invariant 5.1 and Check 3.3 cannot be met for live members of a partly-purged seal | EOS | fresh | cured |
| 19-7 | The four instances are not stated dedicated | EOS | older | cured |
| 19-8 | An orphan with a live intent past the horizon fits two rules | Linus | older | cured |
| 19-9 | A released hold leaves a state that fits no standing | Linus | fresh | cured |
| 19-10 | The floor's new seal term undercounts (repeat of 19-4 after its cure) | Linus | fresh | cured |

**Round 20** (frozen tree; 10 reports, 8 groups; kind A 6, C 2; fresh 7 groups, older 1)

| Group | Defect | Readers | Blame | Repeat of | Outcome |
|---|---|---|---|---|---|
| 20-1 | Hold-release restart has no recorded instant | GRID, EOS | fresh | 19-5, 19-9 | cured |
| 20-2 | Enumeration measured once; nothing re-measures | GRID | fresh | | cured |
| 20-3 | Horizon undefined when retention policy is a selector | GRID, Linus | fresh | refining in 19 | cured |
| 20-4 | Read Record keys a purged event on retention state, the pair on the destruction record | EOS | fresh | | cured |
| 20-5 | The third half reads two enumerations under its lease; the bound budgets one | Linus | fresh | | cured |
| 20-6 | A probe refused with nothing committed has no terminus | Linus | fresh | | cured |
| 20-7 | The boundary of a store outage is unstated | Linus | fresh | | cured |
| 20-8 | The destruction record's write scope is ambiguous | Linus | older | | cured |

**Round 21** (frozen tree; 7 reports, 5 groups; kind A 4, C 1; blame by reports fresh 6, older 1)

| Group | Defect | Readers | Blame | Repeat of | Outcome |
|---|---|---|---|---|---|
| 21-1 | An unreadable payload under Retained is read as an orphan | GRID (A), Linus (C) | fresh / older | | cured |
| 21-2 | The probe's circuit break does not stop on a step-4 refusal | GRID, Linus | fresh | 20-6 | cured |
| 21-3 | A blocking take and "no answer" give two behaviors | Linus | fresh | | cured |
| 21-4 | Liveness arithmetic is measured once; no failing-run arm | Linus | fresh | 20-2 | cured |
| 21-5 | An outage restart can carry a finding past the horizon | Linus | fresh | | cured |

**Repeats.** Groups that were cured and found again: round 20, 1 of 8 (20-1); round 21, 2 of 5 (21-2, 21-4). Across rounds 12 to 21 two defects recur far more than any other, by reader report: the *window counted from the hold's release* (rounds 13, 14, 15 twice, 16, then 19 to 20) and the *closure floor undercounts* (rounds 13, 14, 16, 19 to 21).

## Totals

| Format | Rounds | Foundational reports | Per reader | Distinct groups |
|---|---|---|---|---|
| Two readers | 12 to 18 | 8, 8, 10, 9, 7, 5, 5 | 4.0, 4.0, 5.0, 4.5, 3.5, 2.5, 2.5 | not grouped |
| Three passes | 19 to 21 | 10, 10, 7 | 3.3, 3.3, 2.3 | 10, 8, 5 |

## Log

- 2026-10-02 · opened. Rounds 19 to 21 itemised from the reader reports; rounds 12 to 18 from each reader's count line; rounds 1 to 11 not recoverable. Numbering of the last three commits corrected by this file.
