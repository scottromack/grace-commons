---
title: Governance
nav_order: 2
parent: Community
has_toc: true
toc: true
---

# Governance

<details markdown="block">
<summary>Table of contents</summary>
{: .text-delta }
1. TOC
{:toc}
</details>

> **Draft.** A working proposal for how Grace Commons governs pattern admission and signals trust to consumers as the library matures.

---

## The problem

A pattern library is only as useful as it is trustworthy. Anyone can publish a collection of specs. What makes a spec worth building against is knowing it has been reviewed, that it won't change underneath you without notice, and that the version you built against is the same one everyone else sees.

The three-pass methodology in [`pressure-testing.md`](./pressure-testing.md) handles the quality bar for individual patterns. This document proposes what sits above that — the process for admitting patterns to the canonical library, and the mechanism that makes "admitted" mean something durable.

---

## Hybrid review

Software fails in two ways: logical failures and judgment failures. A logical failure is a missing state, an invariant that doesn't hold, an action that doesn't enumerate its rejections. A judgment failure is a spec that is technically complete but solves the wrong problem, or adds complexity the library doesn't need.

The existing three passes already embody this split. Pass 1 (GRID structural) is mechanical — a spec either resolves all nine nodes or it doesn't. Pass 2 (EOS conceptual independence) and Pass 3 (Linus adversarial) require judgment — conducted, under the current methodology, by AI reviewers in fresh-reader mode (the Final Critique and the council-run rescans; see [`pressure-testing.md`](./pressure-testing.md)), with human attention spent on triage and adjudication of their findings rather than on conducting rounds. The governance layer formalizes the resulting split: a machine gate runs first and is a hard block, AI-conducted adversarial review supplies the findings, and a named human authority adjudicates the admission call. *(Corrected 2026-06-11; this paragraph previously claimed Passes 2 and 3 were human-conducted, which predated the council methodology.)*

The review body is the **ALL Council** — AI plus humans, together covering all the bases a solo reviewer cannot. The name is the concept: neither alone is sufficient.

---

## Cryptographic sealing

When a pattern is admitted to the canonical library, it receives a cryptographic seal — a content hash of the specification at that version, recorded in a tamper-evident log. The seal is not the file's Git hash; it is a stable identity for a specific, reviewed version of the spec.

What this gives consumers:

- **Version pinning.** Pin to a sealed version and know it hasn't changed since it was reviewed.
- **Provenance.** The seal is proof that a specific version was reviewed and admitted at a specific point in time.
- **Drift detection.** A consumer holding a sealed hash can verify their local copy against the canonical version at any time.

This is the library applying its own [Tamper Evidence](./atoms/tamper-evidence.md) atom to itself — which is the right thing to do.

---

## Open questions

1. **Sealing mechanism.** Git-based content hashing is the simplest path. RFC 3161 external timestamping provides stronger legal provenance. The right answer depends on how far the library's institutional ambitions reach.

2. **Council composition.** The minimum viable form is a small group with domain expertise across the library's categories — enough to catch judgment failures that the authoring passes miss. Growth path is an open working-group model as the contributor community develops.

3. **Versioning.** When a sealed pattern is revised, the new version is reviewed and re-sealed; the old seal remains valid for consumers pinned to it. The deprecation path for older versions needs a short spec of its own.

---

## The language council

The reviewers a GRACE lang draft is run past. An internal process of the corpus, kept out of the grammar on purpose (`GRACE-lang.md` v0.32 tombstoned its G9–G12): the grammar states what the language is; who reads a draft and how is decided here, and can change without a grammar release.

- **Members to date:** Claude, Kimi, Gemini, GPT, GLM, Grok, Mistral — the AI seat of the ALL Council above.
- **The chair:** the council is headed by a president, currently Claude, named by the maintainer; the maintainer — the human in charge of the corpus, Scott — is president of all. The chair carries the council's advice to the maintainer and holds no power over admission.
- **Advisory, never admitting.** The council advises; the maintainer decides every admission to the grammar (`GRACE-lang.md` Principle 8, under Principle 2's test — recurrence and contested).
- **Reads are cited like commits.** Every read gets an id and is cited by it in the grammar's changelog. To date: CR-1 Kimi on v0.28 and the Recoverable Invocation rewrite (2026-09-10); CR-2 Gemini on v0.28 (2026-09-11); CR-3 GPT on v0.28 (2026-09-11); CR-4 GLM on v0.29 (2026-09-11); CR-5 GLM on v0.30 (2026-09-11); CR-6 GLM on v0.31 (2026-09-11); CR-7 GLM on Recoverable Invocation as rewritten (2026-09-11) — two contradictions, one parse-blocking form (the signature block), a mechanical rewrite of about sixty rules, and a Principle 2 docket; applied the same day, language only, [Resolve] read pending. CR-8 GLM on Lease as rewritten and relabelled (2026-09-11) — the relabel read clean in use; seven findings, of which the undeclared `effect instant`, the undeclared question set, the deixis in Composition note 2 and two watch-list flags were applied the same day, and the signature block's arity, the Terms card's surface, the label families and the fence margin were decided by the maintainer the same day (v0.35): multi-action signature blocks admitted, the `Terms ›` line the one owner with the card as reader sugar, the standard label families declared once in the grammar under a new locality principle, and the allowance made a floor so Check 6.1 does work. New reads append here.
- **What a read produces:** findings against the draft, each applied, declined with a reason, or routed to the watch list (`GRACE-lang.md` §18). A member's recusal on a finding about itself is recorded with the read.

---

## Relationship to existing documents

- [`pressure-testing.md`](./pressure-testing.md) — the authoring standard that feeds the Council's review gate.
- [`contributing.md`](./contributing.md) — the contribution lifecycle that precedes Council admission.
- [`execution-contract.md`](./execution-contract.md) — sealed patterns are the stable inputs to the compilation pipeline.
- [Tamper Evidence](./atoms/tamper-evidence.md) — the integrity primitive the sealing mechanism instantiates.

---

*Draft. The direction is right; the specifics are open.*
