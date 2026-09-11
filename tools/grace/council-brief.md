# Council brief — reading a GRACE lang document

The read a council member gives `GRACE-lang.md` or a spec written in it. The mechanical slice has already run: [`tools/grace/check.py`](./check.py) reads fences, labels, tombstones, the rule form, WHEN blocks, `AND`/`OR`, `BEFORE`/`AFTER`, the banned words, arithmetic, pronouns, the verb after the modal and cross-rule references, and its output is attached to the read. A read reports only what the checker cannot see. A model instructed to be a static analyser is not one; the analyser is code, and the read is the complement.

## Inputs

The document under review; the checker's output for it; `GRACE-lang.md` at its current version; for a migrated spec, the prose version it replaced (`git show <commit>:<path>`). Nothing else — no prior reads, no findings context (`pressure-testing.md` §*Automated councils*, the fresh-reader discipline). `WHY:` is not a source: it carries nothing (S5, S6), so a rule is never judged against it, only against the prose the rule replaced.

## Report

1. **Unresolved identifiers (C3).** A subject, object, term or value a rule uses that no `Terms ›` declaration and no Vocabulary line owns — or that two declarations own with different definitions.
2. **Meaning, against the source.** *Dropped:* an obligation the prose stated that no rule or declaration carries. *Altered:* a rule that says something the prose did not — a different actor, step, arm, condition, or a weaker or stronger modal. *Contradiction:* two rules that normalize to `X MUST a` and `X MUST NOT a` under one condition.
3. **Owners.** An obligation stated at two sites; a claim in prose or `WHY:` that reads as an obligation no rule carries (a place for everything: `spec-format.md` §*The normative surface*).
4. **Collisions across specs.** A term borrowed with a name and a different definition (the `run_floor` class); two specs claiming authority for one proposition (A3); a section title used as a rule's subject or object; a `spec::label` reference to a label the other spec does not carry.
5. **Watch-list pressure (`GRACE-lang.md` §18).** A site where an admitted form strained — persistent state, applicability, cardinality, negation, event versus state, satisfaction, addressable sections, template identifiers — with the rule label, so the count accrues at the site.
6. **Admission evidence (G2).** A form that recurs across specifications and has produced a finding. Evidence for the maintainer, who decides (G13); the read recommends, never admits.
7. **Process.** Anything about the council, the reads, or the maintainer's decisions goes to `governance.md` §*The language council*, never into the grammar.

## Do not report

A finding the checker already printed — cite its line instead. Tone, phrasing, readability, synonyms for a declared record verb, a shorter way to say a rule that parses. New grammar without item 6's evidence. Two rules that both apply under one condition — the children of a WHEN block and any two rules are independent, and the grammar forbids inferring precedence from order (I15, W2); only a contradiction (item 2) is a finding.

## Form

A numbered list. Each finding: the site (label, or `path:line`), the class from the list above, the quote, what it breaks (the invariant, check or cross-spec reader that reads the site), the fix as a rule or declaration in the language. One verdict line at the end. Where a finding is about the reviewer, the reviewer recuses and says so. The read receives an id (`CR-n`) and a line in `governance.md`'s register; the grammar's changelog cites it by that id.
