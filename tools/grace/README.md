# GRACE lang surface checker

The mechanical slice of [`GRACE-lang.md`](../../GRACE-lang.md): what a form-reader can decide about a spec's normative surface without semantics. It is the forerunner of the parser §11 obliges, not the parser — it resolves no identifiers (C3), matches no value against a value set (I14), and normalizes nothing (§16).

```
python3 tools/grace/check.py                 # GRACE-lang.md + every spec carrying a ```text fence
python3 tools/grace/check.py <paths...>      # named files
python3 tools/grace/check.py --gate          # exit 1 on any non-advisory finding
```

Standard library only. One finding per line, `path:line: [CODE] message`. Non-gating by default — landed 2026-09-11 against a corpus of three migrated documents, and it starts by measuring, not defending (the linter's rule for a new check, `tools/linter/README.md` §Advisory codes).

| Code | What it reads |
|---|---|
| **F-fence-first / F-unlabelled / F-fence-empty / F-signature** | A ```text fence whose first line is neither a labelled rule nor a surface prefix (S17a); an unprefixed line in a normative block that is not a rule (I1, U3); a signature block — a bare fence opening `name(` — with no result arrow (S17b). Any other fence is the surface nothing (S17c). |
| **L-dup-label / L-tombstone-reuse / L-dup-tombstone** | A label used twice; a rule carrying a label a tombstone reserves (I25, I27). |
| **R-no-modal / R-if-then / R-when-colon / R-when-empty / R-nested-when / R-child-label** | The rule form and the statement shapes (R2, R6, I3): a sentence with no modal and no `IS AUTHORITATIVE FOR` is a declaration, not a rule (C12); `IF` without `THEN`; a WHEN block's shape and children (W3, I7). |
| **V-mixed / V-or-obligation** | `AND` and `OR` in one condition (I8); `OR` outside a condition (I9). |
| **B-before / B-after / B-banned / B-exceed** | Positive `MUST … BEFORE` (B6, I12); `AFTER` under `MUST NOT` (B4); `AT LEAST`, `STRICTLY` (B10, B11); `MUST EXCEED` (B9). |
| **A-arith** | An arithmetic operator in a rule (I24, C8). |
| **P-pronoun** | A pronoun in a rule (I5). |
| **C-copula / C-verb** | A copula after the modal; a verb after the modal the spec's record-verb declaration does not carry (C7). |
| **F-bracket** | A bracketed range in a rule — read as a term marker by the corpus linter, and arithmetic besides. |
| **X-ref** | A reference to a label in one of the spec's own families that no rule or tombstone carries (I13). Exemplar labels inside `NOTE:` blocks are excluded, and so are labels a `NOTE:` declares never used (a gap is not a deletion). |
| **W-or-word / W-watch-word / W-term-unused** *(advisory)* | A lower-case `or` inside an obligation; `after`, `before`, `until`, `while`, `unless` inside a rule (§18's watch list); a `Terms ›` declaration nothing uses. |

A code span inside a rule is read as quoted text, never as the rule's own tokens — the grammar's meta-rules mention the tokens they govern (`GRACE-lang.md` §18, provisional).
