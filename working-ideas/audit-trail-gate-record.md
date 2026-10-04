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
| 22 | 33 | 3 passes, frozen tree | 3 + 2 + 2 = 7 | 5 | 37 / 9 | `cf8e56b` |
| 23 | 34 | 3 passes, frozen tree, cold to Status | 3 + 5 + 2 = 10 | 10 | 47 / 14 | `116c123` |
| 24 | 35 | 3 passes, frozen tree, cold to Status | 3 + 2 + 3 = 8 | 6 | 48 / 22 | `a3aadc6` |
| 25 | 36 | 3 passes, frozen tree, cold to Status | 2 + 2 + 3 = 7 | 7 | 59 / 19 | `fa2f26c` |
| 26 | 37 | 3 passes, one frozen text, cold to Status | 0 + 0 + 0 = 0 | 0 | 53 / 26 | this commit |

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

**Round 22** (frozen tree; 7 reports, 5 groups; kind A 3, C 2; blame by reports fresh 5, older 2)

| Group | Defect | Readers | Blame | Repeat of | Outcome |
|---|---|---|---|---|---|
| 22-1 | Second half 18 halts compensation for the run and nothing ends it | EOS, Linus | fresh | cure-spawned (21-1) | cured |
| 22-2 | Every scan-side cost grows with the log, inside a fixed window | GRID (C), Linus (C) | fresh / older | 21-4, 20-2 | named non-goal with owner |
| 22-3 | Rebuild-on-miss at sites where a miss is the normal case | GRID | older | refining since round 19 | cured |
| 22-4 | Horizon and window arithmetic validated only at start | GRID (C) | fresh | | cured (capability requirement) |
| 22-5 | The hold-release restart rests on an observation no store holds | EOS | fresh | 20-1, 19-5, 19-9 | cured |

**Repeats.** Groups that were cured and found again: round 20, 1 of 8 (20-1); round 21, 2 of 5 (21-2, 21-4); round 22, 2 of 5 (22-2, 22-5), and one more spawned by a round-21 cure (22-1). Across rounds 12 to 21 two defects recur far more than any other, by reader report: the *window counted from the hold's release* (rounds 13, 14, 15 twice, 16, then 19, 20 and 22) and the *closure floor undercounts* (rounds 13, 14, 16, 19 to 22, as the enumeration cost).

**Round 23** (frozen tree at `10a1796`, after the closure arithmetic and the hold went to instruments in `bbe773a` and `10a1796`; 10 reports, 10 groups; kind A 6, C 4; fresh 1, older 9; none rejected on triage; rules added 7, removed 0, one term)

A different format from rounds 19 to 22, so compare with care (rule 6): the readers ran on Opus, were capped at five ranked foundational findings each, and read the spec down to `## Status` only — not the Ledger, not Decisions, no model, no history.

| Group | Defect | Readers | Kind | Blame | Repeat of | Outcome |
|---|---|---|---|---|---|---|
| 23-1 | A hold can sit over content a delegation already destroyed; the page called it held over readable content | GRID | A | older | | cured |
| 23-2 | A Retained event with unreadable data and no destruction record has no read answer and no exit | GRID | A | fresh | 21-1, 22-1 | cured (read arm, exit); the unrestorable case recorded, Ledger 2026-10-03-d |
| 23-3 | The destruction-failed re-drive has no terminus | GRID (Linus as refining) | C | older | | already recorded, Ledger 2026-08-30-d |
| 23-4 | Retention Window's Record divergence rules are declined and the atom has not accepted it | EOS | C | older | | recorded, Ledger 2026-10-03-a |
| 23-5 | Nothing ties a member of purged events to a Purged retention; one stray member silences a whole seal | EOS | A | older | | cured |
| 23-6 | Unreadable is an answer neither constituent read declares | EOS | C | older | | recorded, Ledger 2026-10-03-b |
| 23-7 | The outage join is the deployment's and unbounded | EOS | A | older | | cured |
| 23-8 | No carrier for which mechanism cut which seal | EOS | C | older | | recorded, Ledger 2026-10-03-c |
| 23-9 | Record set match cannot be judged where the log has sequence gaps | Linus | A | older | | cured |
| 23-10 | A record action a leg starts can write after the leg's lease has ended | Linus | A | older | closure floor family | cured; enumerator twin |

One of the ten is lease timing, group 23-10. The hold-release restart did not appear. The adversarial pass recomputed closure sum with one dead run, closure spend, re-drive spend and the walkthrough and reported them sound. 23-10 sits in a premise the enumerator had transcribed from Per-act critical section 13h instead of deriving; it derives it now.

Refining reports seen by two readers, routed as Ledger lines 2026-10-03-e through i: no answer outside the signatures; [Seal Now] cited by step with no numbered steps; coverage ranges derived and durable at once; Retention Window's not-known passed through at purge; a bare recording-failure on [Seal Now]. The destruction-failed terminus was also one reader's refining report.

Refining reports seen by one reader, held here and not on the Ledger: the event and attestation relation called mandatory on both sides though reconciled orphans are permanent; `audit.reconciliation` payloads unvalidated at step 1 and no refusal for another operator-attributed `audit.*` name; regulation and vendor acronyms undefined at first use, and the seal cadence WHY pointing at Edge cases for text under Non-goals; Lease bound but absent from Composes, with no instance count or acceptance bar; Legal Hold named never a constituent while its store is read; no page owning a hold placement over an audit event; the uncovered mark a compare-and-clear state on a Lease that declares no carried record, outside the eight state elements; the suspended entry's run instants on an operational record while Generation acceptance promises records alone; Per-act critical section 2, 3, 4, 9b, 13a, 16, 17 and Instance start 25 restating Lease rules; Non-goal 12's rotation with no owning pattern; [Purge Event] taking no actor and writing no audit event; `recording-failure(step-3)` and step-2 by no answer landing on both sides of a commit with no position; purge completion bound's wait of Concurrency 3b reaching the purge bound itself while Instance start 23 checks only the seal bound.

**Round 24** (frozen tree at `7139b62`; the same brief as round 23, so the two compare; 8 reports, 6 groups; kind A 2, C 4; fresh 2, older 4; none rejected on triage; rules added 7, three amended in place)

| Group | Defect | Readers | Kind | Blame | Repeat of | Outcome |
|---|---|---|---|---|---|---|
| 24-1 | One seal must take the whole unsealed tail, and one rebuild the whole seal store, inside a fixed lease, with nothing to say so when it cannot | GRID, Linus | A | older | the shape of 22-2, at the sealing lock | alert, re-declaration and two non-goals with owner; a slice cap and a bounded rebuild recorded, Ledger 2026-10-03-l |
| 24-2 | A standing destruction-failed leaves an event in no standing, and Boundary one 5 bound the composition to end it | GRID (A), Linus (C) | C | older | 23-3 | owner named: a residual finding against the erasure mechanism; the abandoned record stays on Ledger 2026-08-30-d |
| 24-3 | Horizon needs a policy's retention period and no declared surface supplies one | GRID | C | older | | recorded, Ledger 2026-10-03-j |
| 24-4 | Outage and hold-run instants decide whether a late closure is a breach, on a record with no lifetime | EOS | A | fresh | refining in 23 | cured (lifetime) |
| 24-5 | Retention Window offers no transition-only purge | EOS | C | fresh | 23-4 | already recorded, Ledger 2026-10-03-a |
| 24-6 | Nothing drives the purge | Linus | C | older | | recorded, Ledger 2026-10-03-k |

Groups fell from 10 to 6 on the same brief, and two of the six were already Ledger lines. The scan's lease arithmetic and the hold drew no finding; the one lease finding is at the sealing lock, which no model and no enumerator carries. Three reports were of round 23's own cures, all refining: two sentences still counting thirteen external checks (three readers), Per-act critical section 13h against start margin, read record step 4.7 against Invariant 6.1. Each is amended in place.

Refining reports seen in both rounds or by two readers, routed as Ledger lines 2026-10-03-m through r: the store behind Durability 6 named by no capability requirement; the range pass-through with no contract; the uncovered mark on a Lease; a hold placement owned by no spec; `recording-failure(step-3)` with no position; purge completion bound against the wait of Concurrency 3b. Still on lines e through i from round 23 and reported again: no answer outside the signatures, [Seal Now] cited by step, coverage ranges derived and durable.

Refining reports seen by one reader, held here: acronyms never spelled out, and Summary words unglossed; `Legal Hold` and mechanism class with no knob entry or start rule; *Rests on:* lines omitting the sealing lock, Concurrency 3 and the first half; Invariant 4.1 unconditional against the cascade-failure arms; Capability requirement 10a's record unclassified; six composition-code filters over the log where Event Log routes a payload lookup to a reverse index; reconciliation operator provisioned in an attestation store that holds no actors; the erasure mechanism's contract specified here while Retention Window names Cryptographic Shredding its owner; record action step 3.5 vacuous where no rule populates compensated attestations outside a rebuild; per-event sealing alerting on benign lock contention, and the last event before a quiet period left unsealed; a timed-out verify call neither a constituent read nor unverifiable; the walkthrough's measured enumeration a start-time figure with no rotation shown.

**Round 25** (frozen tree at `c4bbdd7`, the same brief; the third pass stopped on a usage limit and was run again whole on the same tree; 7 reports, 7 groups; kind A 3, B 1, C 3; fresh 2, older 5; none rejected on triage; rules added 10, one tombstoned, ten amended)

| Group | Defect | Readers | Kind | Blame | Repeat of | Outcome |
|---|---|---|---|---|---|---|
| 25-1 | Restart persistence is declared for the audit log alone | GRID | C | older | | recorded, Ledger 2026-10-03-s |
| 25-2 | The range pass-through has no answer, refusal or payload rule | GRID | A | older | refining in 23 and 24 | cured |
| 25-3 | The record that decides a late closure is unclassified, outside the nine elements | EOS | A | fresh | 24-4 | cured: a state element, extraction-pending |
| 25-4 | A gated hold placement is an action no spec owns | EOS | C | older | refining in 23 and 24 | recorded, Ledger 2026-10-03-p |
| 25-5 | Any failure longer than a call pause restarts every finding's whole window | Linus | A | older | 23-7 | cured: the window runs to closure sum after the outage |
| 25-6 | A seal call slower than its lease leaves two seals over one range; the re-declaration does not fire on that exit | Linus | C | fresh | 24-1 | cured: a slice cap |
| 25-7 | verified can stand over a stored entry altered after sealing | Linus | B | older | | recorded, Ledger 2026-10-03-t |

Groups by round on this brief: 10, 6, 7. The count is not falling. Two clusters account for it: the outage rules (23-7, 24-4, 25-3, 25-5) and the sealing lock (24-1, 25-6), neither carried by a model or the enumerator, each cured in rounds 23 and 24 by a clause that answered the report. This round they are cured by structure: a classified state element and a rule tied to closure sum; a cap. The scan's lease arithmetic and the hold again drew no finding, and the third pass recomputed 1144 s, 298 s and 342 s.

Refining reports seen in two rounds or by two readers and already Ledger lines: no answer outside the signatures (e), [Seal Now] cited by step (f), coverage ranges derived and durable (g), Retention Window's not-known at purge (h), a bare recording-failure on [Seal Now] (i), the uncovered mark (o), `recording-failure(step-3)` with no position (q). New lines u and v: the dead pre-check at record action step 3.5, and `Legal Hold` not a knob. One was of the last unit's cure and is amended: purge eligible 9 had no hold exception.

Refining reports seen by one reader, held here: Event Log's serialized append absent from the six serialization obligations; references to a Lease edge case, External Anchoring and Credential management that resolve to nothing; the third half's placement mapping two of its refusals; Primitive policy 9 with no landing; the erasure mechanism specified here as a knob; the cadence driver, the scan scheduler and the purge sweep as one concept under three contracts, the sweep with no cadence; the Legal Hold store's instance topology; [Purge Event] carrying no actor; record action step 5.5's fallback enumeration against a 30-second bound; Per-act critical section 13e alerting with no headroom on a log that only grows; closure floor pricing the probe and the intent at one bound where start margin admits two.

**Round 26** (one frozen text, body hash `45ae204` over lines 1 to 1994, file hash `8b2bd62`; no edit between passes; the brief of rounds 23 to 25 with two additions: a reader commits to a class and may not report *foundational, but triage may downgrade it*, and a state where every record is safe and the only cost is a bounded delay, a held key or a surfaced alert is out of scope; 0 reports)

Between rounds 25 and 26 no reader ran on this page. The work was on what the page stands on: the capability sweep (Ledger lines s, m, o), Retention Window re-grounded with an owner of the destruction it accepts (line a), Lease grounded with a model (2026-10-02-a), and the hold placement given to the deployment (lines p, v). Every one was a kind C finding of rounds 23 to 25. The third pass's hardest attack, a stalled record action appending after its attestation was compensated, fails with zero slack, and it recomputed 19 min 4 s, 298 s and 342 s.

Refining reports routed as Ledger lines 2026-10-04-a through q. One is a propagation miss of this campaign: Lease Sizing 4a wants a lease that exceeds the work's bound and Per-act critical section 9a sets it equal (line a); the worst reachable state is a refused last write at the exact worst-case latency, so it is refining, and it is the first cure the next load-bearing touch owes. Reported again and already lines: no answer outside the signatures (e), coverage ranges derived and durable (g), Retention Window's not-known at purge (h), `recording-failure(step-3)` with no position (q), the pre-check that reads an index only a rebuild writes (u).

## Totals

| Format | Rounds | Foundational reports | Per reader | Distinct groups |
|---|---|---|---|---|
| Two readers | 12 to 18 | 8, 8, 10, 9, 7, 5, 5 | 4.0, 4.0, 5.0, 4.5, 3.5, 2.5, 2.5 | not grouped |
| Three passes | 19 to 22 | 10, 10, 7, 7 | 3.3, 3.3, 2.3, 2.3 | 10, 8, 5, 5 |
| Three passes, cold to Status | 23, 24, 25, 26 | 10, 8, 7, 0 | 3.3, 2.7, 2.3, 0 | 10, 6, 7, 0 |

## Log

- 2026-10-02 · opened. Rounds 19 to 21 itemised from the reader reports; rounds 12 to 18 from each reader's count line; rounds 1 to 11 not recoverable. Numbering of the last three commits corrected by this file.
- 2026-10-02 · round 22 itemised. The Ledger's Final Critique number is now 33.
- 2026-10-03 · round 23 itemised; the Ledger's Final Critique number is now 34. The readers stopped at `## Status`, which earlier rounds' readers did not, so the stale-Ledger reports of those rounds have no counterpart here.
- 2026-10-03 · round 24 itemised; the Ledger's Final Critique number is now 35.
- 2026-10-03 · round 25 itemised; the Ledger's Final Critique number is now 36.
- 2026-10-04 · round 26 itemised: zero foundational from three passes on one text; the Ledger's Final Critique number is now 37 and the status is grounded.
