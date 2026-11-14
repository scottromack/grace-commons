---
title: Spec Format — history
nav_exclude: true
search_exclude: true
---

# Spec Format — the record

What [Spec Format](./spec-format.md) once said that it no longer needs to say: the Status paragraph's revision log, the Regulated overlay section, the dated asides, the convention bullets that restated the grammar, and the sentences that recorded when a family was promoted. Moved here byte for byte on 2026-11-14.

## Regulated overlay

Applies to any atom carrying the regulated overlay, any atom in another category whose acceptance bar is set by an external evaluator, and any composition naming a regulated atom. Two additional sections are *required* — they sit alongside the standard sections of the atom or composition shape, not in place of them.

### Required additions

**Regulated adversarial scenarios** — an Examples subsection (placed after the standard happy-path and domain examples within the Examples section) that walks the three canonical adversarial reads: *regulator audit*, *disputed transaction or data-subject request*, and *breach or incident investigation*. All three must be walked; conflating them into one scenario loses the structural three-class requirement and is a Pass 3 finding. What each read must demonstrate — the invariant a regulator's query rests on, the structural rebuttal to a dispute, the forensic-window bound for a breach — is methodology content owned by the section titled *Regulated-pattern conventions* in [`pressure-testing.md`](./pressure-testing.md); this document fixes only the subsection's placement and the three-class requirement.

**Generation acceptance** — a standalone section (placed after Examples, before Non-goals) naming what a derived implementation must produce. **Its presence is not the overlay's to require: every migrated spec carries it, regulated or not, or declines by delegation on its `Term qualifiers` line** (the section titled *Generation acceptance* in [`pressure-testing.md`](./pressure-testing.md), amended 2026-09-14; enforced by the linter). What the overlay owns is the two-subsection structure below and the records-alone bar. The bar — what an auditor must be able to clear *from the records alone*, with no recourse to source code, runbooks, or developer narration — is methodology content owned by the section titled *Regulated-pattern conventions* in [`pressure-testing.md`](./pressure-testing.md). This document fixes the section's placement and, for compositions, its two-subsection structure:

- **Conformance checks** (titled `Record checks` in the prose shape) — the checks an auditor can answer by reading the composition's records (including the Audit Trail substrate where applicable). Each check references the composition-level invariant it verifies.
- **External checks** — questions that arise around the composition but require external evidence (a Policy Registry, a Permissions registry, court documentation) to answer. These are the *audit-gap* questions — important to surface, but not the composition's own contract to satisfy.

The split convention was established in Multi-Party Approval's Round 3 and applied retroactively to regulated compositions; the bar an external auditor can clear from the records alone is structurally distinct from the bar the composing organization must clear with its own governance evidence.

Both regulated-overlay conventions are *inherited from the methodology directly* (see [`pressure-testing.md`](./pressure-testing.md)'s *Regulated-pattern conventions*), not re-derived from predecessor patterns. A new regulated pattern's commit message cites the methodology, not earlier worked examples.

## The Status paragraph's revision log

Revised 2026-06-10 (Refactor 1): the ownership seam with the Execution Contract assigned (the section titled *Ownership seam with the Execution Contract*), the composition-state subsection's semantics (then titled `Application state`) deferred to the Contract's composition-state rule, and the drifted pattern-count snapshot this line previously carried removed under the no-snapshot rule (the section titled *Current state of the library* in [`AGENTS.md`](./AGENTS.md)). Revised 2026-06-11: the cross-cutting authoring conventions gained the structural-relation invariant templates (guided-tool design review, F4), and the vocabulary direction landed — the composition shape's state subsection renamed `Application state` → **Composition state**, with the working nouns banned by lint rules J and K scoped out of this document. Revised 2026-06-13: the structural-relation invariant templates gained a fourth member — *acyclicity / well-foundedness* for self-referential relations — landing the concept-recovery exercise's strongest candidate as a template rather than a new atom (see the section titled *Concept-recovery atom backlog* in [`roadmap.md`](./roadmap.md)); the four templates were then promoted from an inline cross-cutting-conventions bullet to their own section, *Structural-relation invariant templates*, with a plain-language table (presentation only — semantics unchanged, still cross-referenced to the entry *Relations* under Pass 3 in [`pressure-testing.md`](./pressure-testing.md) and the section titled *Composition state* in [`execution-contract.md`](./execution-contract.md)). Revised 2026-09-15: the section titled *Heading standard* added as the one owner of every heading's name, level, parent, order and requirement for a migrated spec, read by `lint.py`'s `H-heading`; the composition list's subsections renamed to the names the migrated corpus uses (council read 80). Future refinements land via the standard scheduled-rescan and touch-triggered re-pass disciplines.

## Promoted at v0.42, v0.43 and v0.62

Promoted to the standard label families at [`GRACE-lang.md`](./GRACE-lang.md) v0.42; the table titled *Rule families* states the family's meaning, and the heading table places it before *Action wiring*, where all four naming specifications already placed it.

Promoted to the standard label families at [`GRACE-lang.md`](./GRACE-lang.md) v0.42; the table titled *Rule families* states the family's meaning, and the heading table places it after *Wiring decision*.

Promoted to the standard label families at [`GRACE-lang.md`](./GRACE-lang.md) v0.43; the table titled *Rule families* states the family's meaning, and the heading table places it after *Reconciliation*, its declared pair.

Promoted to the standard label families at [`GRACE-lang.md`](./GRACE-lang.md) v0.62; the table titled *Rule families* states the family's meaning, and the heading table places it after *Housekeeping*, where all three naming specifications already filed it last.

Promoted at [`GRACE-lang.md`](./GRACE-lang.md) v0.62; the heading table places it after *Scope vocabulary*, the three naming specifications having filed it last in Composition logic.

## The six nodes the prose shape spread

The six nodes the prose shape spread across six sections live here — inputs on the signature, with their validity in a policy family; outputs on the answers line; each decision as the rule that answers a refusal; behavior and feedback as the rules that record, change and answer. The prose shape stated one set of obligations six times, which is how a spec came to disagree with itself; a rewritten spec states each once (adopted 2026-09-11).

## The Heading standard's adoption

 Adopted 2026-09-15, on the maintainer's rulings that headings and levels are standardized, that a spec carries every heading its shape requires and may skip the rest, and that one order governs.

## The four convention bullets that restate GRACE-lang

- **The normative surface — a place for everything.** A spec's obligations live in exactly two places: bare fenced blocks of labelled GRACE lang rules, and `Term` declarations (with the Terms registry's term entries). The parser reads those and nothing else. Every other line — Summary, Intent, walkthroughs, `WHY:` rationale, the prose around a rule — is explanation by construction and carries no obligation; a sentence outside the surface that reads as one is a defect in the sentence, not a second owner. Section 2 of [`GRACE-lang.md`](./GRACE-lang.md) states the same rule from the language's side (Surface 2). Adopted 2026-09-11.
- **Declare domain meaning, not GRACE meaning.** A spec declares what its domain forces — the nouns, the verbs, the value sets, the signatures, the local exception. What every spec shares is the grammar's: the standard label families (the table titled *Rule families* in the section titled *Heading standard*), the categories, the outcome shapes, the timing concepts. Restating one of them in a spec adds a second owner for something the spec does not own ([`GRACE-lang.md`](./GRACE-lang.md) Principle 9 through 11, Standard label 1 through 3). Explicit has never meant repeating a globally-known fact in every file. Adopted 2026-09-11.
- **A term entry is the reader's copy.** The `Term` declaration owns a term's definition; the registry term entry under `## Terms` — heading, prose, `Kind` — and the `[Name]: #anchor` lines that land a bracket marker on it are reader sugar on the *nothing* surface, carrying no obligation, and `Kind` is the term entry's reader metadata rather than a declared value set ([`GRACE-lang.md`](./GRACE-lang.md) Surface 25 through 27). A term entry that states an obligation the declaration does not is a defect in the card. Adopted 2026-09-11.
- **A migrated spec says so.** A spec rewritten in GRACE lang declares `migrated` on its `Term qualifiers` line, with the grammar version and the date. The corpus tools read that marker as the whitelist — a spec that has not declared it is not scanned, not walked, and not held to the language's rules (Section 13 of [`GRACE-lang.md`](./GRACE-lang.md)). Adopted 2026-09-11.

## The convention bullet that restated the three reading tiers

- **Three reading tiers, always.** Every spec has a Summary (Tier 1 — anyone), a main text (Tier 2 — technical readers), and optional formal models (Tier 3 — experts). The Summary is plain language with zero unexplained jargon. The main text defines every non-everyday term inline at first use. Formal models are dense and expert-only. See *Three reading tiers* above.
