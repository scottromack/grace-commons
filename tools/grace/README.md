# GRACE lang surface checker

The mechanical slice of [`GRACE-lang.md`](../../GRACE-lang.md): what a form-reader can decide about a spec's normative surface without semantics. It is the forerunner of the parser §11 obliges, not the parser — it resolves no identifiers (Closed vocabulary 4), matches no value against a value set (Hard invariant 14), and normalizes nothing (§16).

```
python3 tools/grace/check.py                 # GRACE-lang.md + every spec carrying a ```text fence
python3 tools/grace/check.py <paths...>      # named files
python3 tools/grace/check.py --gate          # exit 1 on any non-advisory finding
```

Standard library only. One finding per line, `path:line: [CODE] message`. Non-gating by default — landed 2026-09-11 against a corpus of three migrated documents, and it starts by measuring, not defending (the linter's rule for a new check, `tools/linter/README.md` §Advisory codes).

| Code | What it reads |
|---|---|
| **F-fence-first / F-unlabelled / F-fence-empty / F-signature** | A ```text fence whose first line is neither a labelled rule nor a surface prefix (Surface 19); an unprefixed line in a normative block that is not a rule (Hard invariant 1, Sugar 3); a signature block — a bare fence opening `name(` — with no result arrow (Surface 20). Any other fence is the surface nothing (Surface 21). |
| **R-label-heading / R-label-abbrev** | A label whose name is not the heading the rule sits under, or whose invariant or step number is not the one it sits under (Rule shape 7); an abbreviation in a label (Rule shape 8). |
| **L-dup-label / L-tombstone-reuse / L-dup-tombstone** | A label used twice; a rule carrying a label a tombstone reserves (Hard invariant 25, Hard invariant 27). |
| **R-no-modal / R-if-then / R-when-colon / R-when-empty / R-nested-when / R-child-label** | The rule form and the statement shapes (Rule shape 2, Rule shape 6, Hard invariant 3): a sentence with no modal and no `IS AUTHORITATIVE FOR` is a declaration, not a rule (Closed vocabulary 14); `IF` without `THEN`; a WHEN block's shape and children (WHEN block 3, Hard invariant 6). |
| **V-mixed / V-or-obligation** | `AND` and `OR` in one condition (Hard invariant 7); `OR` outside a condition (Hard invariant 8). |
| **B-before / B-after / B-banned / B-exceed** | Positive `MUST … BEFORE` (Timing 6, Hard invariant 11); `AFTER` under `MUST NOT` (Timing 4); `AT LEAST`, `STRICTLY` (Timing 10, Timing 11); `MUST EXCEED` (Timing 9). |
| **A-arith** | An arithmetic operator in a rule (Hard invariant 24, Closed vocabulary 9). |
| **P-pronoun** | A pronoun in a rule (Hard invariant 4). |
| **C-copula / C-verb** | A copula after the modal; a verb after the modal the spec's record-verb declaration does not carry (Closed vocabulary 8). |
| **F-bracket** | A bracketed range in a rule — read as a term marker by the corpus linter, and arithmetic besides. |
| **X-ref** | A reference to a label, by one of the spec's own label names, that no rule carries (Hard invariant 12). A heading-numbered group — `Invariant 2`, `Check 5` — counts as carried when a rule under it exists; another spec's `Invariant N` is left to the corpus linter. |
| **W-or-word / W-watch-word / W-term-unused** *(advisory)* | A lower-case `or` inside an obligation; `after`, `before`, `until`, `while`, `unless` inside a rule (§18's watch list); a `Terms ›` declaration nothing uses. |

A code span inside a rule is read as quoted text, never as the rule's own tokens — the grammar's meta-rules mention the tokens they govern (`GRACE-lang.md` §18, provisional).
