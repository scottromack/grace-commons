# GRACE lang v0.27 — review, Torvalds pass

Rewrite of `grace-lang-v027-review.md`, re-checked 2026-09-10. Counts: whole word, any case, over `atoms/` + `compositions/` + Recoverable Invocation (57 files) unless marked. Unpathed quotes: the review.

**The review breaks the rules it reviews. Fix it before the spec.**

## Findings

1. **Wrong root cause.** "That count was case-insensitive." Its own table (56 files) refutes it: in any case, `IS DERIVED FROM` is 6 and `ONLY IF` 28. Not 45. The count matched fragments: `derived from` 48, `never` (filed as `MUST NOT`) 57. Denominator moved 57 → 56, and "pattern files" is 53 patterns plus 3 index pages. The wrong cause is copied to `roadmap.md:716`. `discoveries.md:59` still says "Earned, present in 45–57 files". → P1

2. **The §1 fix breaks I9.** "has drifted, been read two ways, or produced a finding" is a disjunction in a rule. Make it a term. "Recurrence alone is not evidence" restates the rule. Delete it. → P2

3. **Review item 2 ranks by count after ruling count out. Pick one.** "Under either reading of §1 that is inverted": no. By token both fail; by concept both pass. By P2: `ONLY IF` carries gate 12 F1's repair (`recoverable-invocation.md:452`), so admit it. `ONLY UNDER` has no finding, so PROVISIONAL. `IS AUTHORITATIVE FOR`: label right, "zero of the form" wrong. Recoverable Invocation writes it three times.

4. **Disjunction is writable. No slot.** "Two `MUST` rules are conjunction, not disjunction": `(a ∨ b) → s` is `(a → s) ∧ (b → s)`. Only the gate, `s → (a ∨ b)`, needs a term, and a term is a declaration. All four uppercase `OR`s in the corpus already sit in query filters. None is in an obligation. → P3

5. **`≥` is writable. No slot.** Put the `max(…)` in `run_floor`, then `run_floor MUST NOT EXCEED run_bound`. Recoverable Invocation already spells it `NOT STRICTLY` (`:231`). `AT LEAST` would be the third spelling. Move its five `STRICTLY` lines to `EXCEEDS` forms. If §5 rejects `MUST NOT EXCEED`, fix the grammar, not the vocabulary.

6. **Degraded guarantee: real gap, wrong spelling.** The strong rule owns its condition (`ONLY IF`, `recoverable-invocation.md:452`). `R25 DEGRADES TO R25b WHEN fence = none` states it again: two owners (`pressure-testing.md:269`). The slot pairs rules. It does not condition them. Missed evidence: gate 12 F1 *is* this gap. Check 2 had no `service_identity = none` branch; check 3 had one. → P4

7. **"arithmetic lives in term declarations" fails the first controlled page.** All five instance-start conditions in Recoverable Invocation carry inline arithmetic. Budget five terms or drop the rule.

8. **I4: wrong premise, wrong remedy.** "passive voice is structurally impossible": false. `The actor MUST be granted invite_actor` passes I2 and §5. "the only item on that list a parser cannot actually enforce": false. §13 closes the slot after the modal to declared record verbs, and `be granted` is not one. So §13 enforces I4. Delete I4. Moving it to §20 makes a second owner.

9. **Review item 5: right sections, wrong evidence.** Both drifted sentences were normative: Configuration's `run_bound` floor (gate 12 R1) and check 2 (F1). `WHY ↛ Normative` touches neither. The catch is the round-end prose-versus-model diff (`pressure-testing.md:259`). I16: F1 is not absence read as coverage; F5 is. I17: "The duplicate-key finding" has no ID; F4 fits. Cut "the only structural fix", "I believe", "arrived at independently".

10. **Sources that do not exist.** "degrades from closed to escalated" and "the store is a bag": 0 hits outside the review. A paraphrase in quotation marks is a fabricated source. → P5

## Patch

```
P1  EVERY count of a candidate form MUST state its match pattern, its case rule and its file set.
P2  §21 MAY admit a form ONLY IF its concept recurs across specifications AND satisfies contested.
      Terms › contested: its free prose drifted, was read two ways, or produced a finding.
P3  EVERY disjunctive condition MUST name a declared term.
P4  PROVISIONAL: <strong rule> DEGRADES TO <weak rule>.
P5  EVERY quotation MUST match its named file verbatim.
```

Admit `ONLY IF`. Demote `ONLY UNDER`. Label `IS AUTHORITATIVE FOR` introduced. Delete I4. No slot for disjunction or `AT LEAST`. Keep §4, §8, §13, I15–I17.
