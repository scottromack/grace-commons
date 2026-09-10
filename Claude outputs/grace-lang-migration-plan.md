# GRACE lang migration — plan

Proposal, 2026-09-10. On approval it replaces the order of work in `roadmap.md` debt #21, and this file is deleted.

**Goal: every obligation in the corpus in GRACE lang, everything else cut to a budget, in 30 days.**

## Why

Measured 2026-09-10 over the 53 patterns. Counts are whole word, outside code spans and fences.

- **5.2 MB of prose.** Atoms 1.7 MB, compositions 3.4 MB. Median spec 79 KB; Audit Trail 306 KB. The Recoverable Invocation draft alone is 215 KB.
- **20,133 sentences, mean 33 words.** 29% run 40 words or more (heuristic split, outside code, tables and headings).
- **4,253 modal markers in prose** (`must`, `never`, `only if`, `exactly one`, `at most one`, `may not`, any case). 10 are uppercase.
- **~920 KB of compositions re-derive one protocol** in their own words (`roadmap.md` debt #20).
- **Checks on controlled forms work.** Six of six promoted checks read one; five of five rejected checks read free prose (`discoveries.md`).
- **Prose is the half that rots.** Both of gate 12's drift findings: the sentence wrong, the machine artifact right (`pressure-testing.md`).

## What saved means

Read at the gate that closes the repair round, day 28. Fixed now so it cannot be fitted afterwards.

| measure | now | day 28 |
|---|---|---|
| a gate's findings caused by the previous repair round | 73% at gate 11; lowest 35%, gate 7 | under 35% |
| foundational findings that are transcription errors | 0 at gates 8–10 | 0 |
| modal markers outside controlled lines, normative sections | 4,253 in all sections | 0 |
| pattern prose | 5.2 MB | ≤ 1.6 MB |
| mean rationale sentence | 33 words | ≤ 20 |
| method docs | 941 KB | ≤ 240 KB |

Bytes are the easy half. If the first two rows miss, the language has not fixed the defect, whatever the size says.

## Rules

```
The migration MUST NOT change an obligation.
EVERY migrated spec MUST pass the parser.
The new spec's parse MUST contain EVERY obligation in the old spec's inventory.
EVERY term on a migrated spec MUST have a declaration.
A migrated spec MUST NOT EXCEED spec_budget.
EVERY contradiction between old prose and a model MUST land as a Ledger open line.
A migrated spec MAY keep its Status token ONLY IF its diff carries no unexplained line.
EVERY quotation MUST match its named file verbatim.
```

Terms › `spec_budget`: 30% of the spec's bytes on 2026-09-10.

A pattern file is a **spec**. The rewrite renames the corpus's own *page* too: 194 uses across 52 specs, 112 in the draft.

Defects found on the way are logged, never fixed in the rewrite. Repair rounds caused 35% of gate 7's findings and 67% of gate 8's; a migration that repairs as it goes would compound that.

## Where the bytes go

| section | share | becomes |
|---|---|---|
| Composition logic | 26% | GRACE lang |
| Structure (atoms) | 13% | GRACE lang |
| Edge cases and explicit non-goals | 11% | rules in the owning section; non-goals one line each |
| Terms | 10% | one-line declarations |
| Examples | 8% | real examples, each citing the rules it exercises; restatements go |
| Generation acceptance | 7% | GRACE lang, the manifest source |
| Composition-level invariants | 6% | GRACE lang |
| Intent, Composition notes | 5% | Strict Caveman, budgeted |
| Decisions, Ledger | 5% | history (decision 3) |
| Standards references | 3% | a list |
| Summary, Composes | 4% | Tier 1 plain language; `COMPOSES` lines |

## Phase 0 — make the language real (days 1–4)

1. **Land `grace-lang.md` v0.28**: v0.27 plus the review's eight changes. Blocked: v0.27's text is not in the repo.
2. **Restate the doctrine: clear over clever, with real examples.** `the-spec-layer.md` (*Verbosity is a feature when it preserves meaning*; *Verbosity is the architecture of the bridge*) and `spec-format.md` (*Complete over concise*) kept the spirit and lost the shape. The shape is plain declaratives, between Shakespeare and algebra: *X does this. Y does not do X. MUST. MUST NOT.* Obligations in GRACE lang, rationale in Strict Caveman, real examples, the Tier 1 Summary as the bridge.
3. **Build `tools/grace/`**, standard library like the linter. It lowers every controlled line to `SUBJECT / MODAL / ACTION / OBJECT / CONDITION`, rejects malformed lines and resolves every term. Fixtures in both directions, mutation-verified.
4. **Two linter checks**, advisory until their sweep reaches zero, then gating: a modal marker outside a controlled line in a normative section, and `spec_budget`.
5. **Write the section contract** (the table above) into `spec-format.md`, and point `tools/conformance/extract-manifest.mjs` at the controlled Generation acceptance form.
6. **Give drafts a home.** `AGENTS.md`: a draft goes to its canonical path on first write, under the `draft` status token. Nothing lives in a scratch folder. v0.27 never reached the repo.

## Phase 1 — pilot (days 5–8)

Duplicate Prevention and Event Log (small atoms with models) and the Recoverable Invocation draft (the hardest spec, and the compound debt #20 needs). The draft moves to `compositions/` under its `draft` token, where the linter reads it. Exit criteria, fixed before the pilot runs:

- obligation diff: no unexplained line;
- linter, the specs' models and manifests: verdicts unchanged;
- every spec within `spec_budget`;
- a fresh-reader gate on Recoverable Invocation: no transcription-wrong foundational finding.

A failed pilot fixes the language or the pipeline, not the specs.

## Per-spec pipeline

1. **Inventory.** Two independent extractors list the old spec's obligations as tuples, each citing its sentence; a person settles disagreements. A one-time migration aid, never a standing check, because it infers from prose.
2. **Rewrite.** A drafter writes GRACE lang lines, declared terms, budgeted rationale, and the spec's real examples, each citing the rules it exercises.
3. **Parse.** `tools/grace/` lowers the new spec.
4. **Diff.** Inventory against parse; a missing or extra obligation sends the spec back to step 2.
5. **Oracles.** Linter, the harness on the spec's models, manifest equality where a manifest exists.
6. **Linus pass.** An adversarial read of the diff and the findings, nothing else.
7. **Ledger line.** Migrated to v0.28; diff clean.

## Ground Recoverable Invocation (days 9–14)

Its status line: "the three passes and a fresh-reader gate are owed before any adopter binds to it." They run beside wave A.

```
Wave B MAY start ONLY IF Recoverable Invocation carries a grounded Status token.
```

## Phase 2 — waves (days 9–20)

- **A. The other 26 atoms, in parallel, days 9–14.** Atoms go first because they declare the record verbs compositions use (§13).
- **B. The 14 exact protocol adopters, days 15–20** (debt #20). Each spec's re-derived protocol becomes a binding to Recoverable Invocation. Evidence: `tools/survey/protocol_prose.py` falls from ~920 KB.
- **C. The other 11 compositions, days 15–20.**

One fresh-reader gate per wave, on three random specs and the wave's largest.

## Phase 3 — method docs (days 21–25)

941 KB across twelve documents. `pressure-testing.md` (281 KB): each frozen rule as controlled lines, two sentences of rationale, one evidence pointer. `roadmap.md` (341 KB): state tables and open orders of work; progress narratives go to git history. `discoveries.md`: one paragraph per finding. Budget: 25%.

## Repair round (days 26–28)

Work every Ledger open line the migration logged. One fresh-reader gate closes the round, and *What saved means* is read there.

## Close `Claude outputs/` (days 29–30)

Every file goes to its canonical home or is deleted; git keeps the history.

| file | goes to |
|---|---|
| `recoverable-invocation.md` | `compositions/`, at the pilot |
| `model/` (66 files) | `compositions/`, beside the spec; `_superseded/` deleted |
| `window_bound.py` | `tools/`, as the enumerator the round-end diff reads |
| `code_signature_check.py`, `mechanism_check.py`, `undeclared_landing_check.py` | deleted; check prototypes |
| seven gate reports and `gate_log.md` | deleted once every finding is on the spec's Ledger |
| `beacon-regen-prediction.md`, `issue-2-comment.md` | deleted |
| the v0.27 review, this plan | deleted once `grace-lang.md` v0.28 and debt #21 carry them |

Exit: the folder is gone.

## Risks

- **The inventory is inference.** Two extractors and a person on disagreement. The parse, the models and the manifests check the result, not the inventory.
- **The budget tempts dropping obligations.** The diff gates first; the budget never overrides it.
- **The language is wrong at scale.** The grammar is frozen during the waves. New forms enter only as PROVISIONAL and are admitted by §1's rule afterwards.
- **Recoverable Invocation does not ground by day 14.** Wave B waits; wave C and the method docs do not.
- **Volume.** Four agents per spec is about 210 agent runs; the waves run in batches.

## Decisions

1. **v0.27's text.** Paste it; Phase 0 starts there.
2. **Semantic freeze** during migration, repairs after (proposed).
3. **Decisions sections:** keep as history, or one line each.
4. **Execution** as a multi-agent workflow, wave by wave.
