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

## Permanent ids

Every atom and composition carries a permanent id: a bare number in its front matter (`id`), given when the pattern is admitted, never changed and never reused. A rename changes the title, the file name and the file's path in `_data/pattern-ids.yml`; it never changes the id. That list holds every id ever given with the file that holds it, and a retired pattern keeps its id there, marked retired with its last name, so no number is handed out twice. One sequence numbers atoms and compositions alike (the folder says which kind it is), and `python3 tools/grace/check.py --gate` fails when a pattern has no id, two files share one, or an id is missing from the list or listed under another file.

The id is for machines and for AI sessions that need a key that survives a rename; no page shows it. Anything a person reads names a pattern by its name, never by an id or a code. An id appears only in machine and AI-only text, and there only where it saves real money. The seal above identifies one reviewed version of a pattern; the id identifies the pattern itself, whichever version it is at.

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
- **A read has two hands, and both are named.** A council member finds; the maintainer decides; the chair applies. A register line therefore carries the finder (the member and the read's id), the decision where one was needed, and the pass that landed it — and a fix that changed a rule says so in the commit that made it, under the finder's id. The council's value is that the finding and the repair are not the same hand: a reader who also writes the fix grades their own work, which is the failure the corpus's own review discipline exists to prevent (the section titled *Defending each claim in-line* in `pressure-testing.md`). Adopted 2026-09-12, at the council's third asking.
- **Reads are cited like commits.** Every read gets a number and is cited by it in the grammar's changelog — *council read 17*, spelled out, because the library's oldest rule is that it never mints an acronym (`naming.md`), and a register that abbreviated its own readings would be the first place to break it. The readings themselves are listed in the section titled *The register* in [`governance.hist.md`](./governance.hist.md).
- **What a read produces:** findings against the draft, each applied, declined with a reason, or routed to the watch list (Section 18 of `GRACE-lang.md`). A member's recusal on a finding about itself is recorded with the read.

The council's register of its reads, one entry per council read from 2026-09-10 until it closed on 2026-09-30, is record and is kept in [Governance — history](./governance.hist.md).

---

## Relationship to existing documents

- [`pressure-testing.md`](./pressure-testing.md) — the authoring standard that feeds the Council's review gate.
- [`contributing.md`](./contributing.md) — the contribution lifecycle that precedes Council admission.
- [`execution-contract.md`](./execution-contract.md) — sealed patterns are the stable inputs to the compilation pipeline.
- [Tamper Evidence](./atoms/tamper-evidence.md) — the integrity primitive the sealing mechanism instantiates.

---

*Draft. The direction is right; the specifics are open.*
