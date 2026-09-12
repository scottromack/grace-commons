# GRACE lang surface checker

The mechanical slice of [`GRACE-lang.md`](../../GRACE-lang.md): what a form-reader can decide about a spec's normative surface without semantics. It is the forerunner of the parser §11 obliges, not the parser — it resolves no identifiers (Closed vocabulary 4), matches no value against a value set (Hard invariant 14), and normalizes nothing (§16).

```
python3 tools/grace/check.py                 # GRACE-lang.md + every spec carrying a ```text fence
python3 tools/grace/check.py <paths...>      # named files
python3 tools/grace/check.py --gate          # exit 1 on any non-advisory finding
```

Both tools read one whitelist: a spec is scanned when its `Terms › qualifiers` line declares `migrated`. Nothing is inferred from the presence of a fence, so an unmigrated spec that grows one is not suddenly held to the language.

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
| **D-decl-modal / D-decl-selfref / D-decl-unresolved** *(advisory)* | What a declaration carries. A definition is not a rule, so a modal in one is an obligation in a definition's clothes (Closed vocabulary 12, Closed vocabulary 14); a definition that computes over itself, or over a datum the spec declares nowhere (Closed vocabulary 4). A declaration may carry the arithmetic a rule may not (Closed vocabulary 9, Closed vocabulary 11), which is where complexity goes when a rule cannot hold it — and, until these landed, the one place nothing read. |
| **K-check-bare** *(advisory)* | A `Check` or `External check` rule naming no rule. The auditor is the last reader nobody audits: a check whose failure nobody can state passes forever, and Lease's Check 6.1 was vacuous against the very rule it rested on for a day (council read 8). Landed 2026-09-11 against a baseline of 83, most of them checks citing an invariant in prose rather than by label. |
| **F-prefix-first** | A tombstone opening a fenced block: `Surface 18` classifies the block by its first line, so a `NOTE: … deleted` written at the top silently demotes every rule beneath it. The edit looks like housekeeping and reads like a deletion — it happened once, during council read 15's repair pass, and the checker caught it. |
| **V-dup-vocab** | A `Terms › record verbs` or `Terms › terms` line naming the same name twice. The corpus's rewrite template shipped `identify` twice and five atoms inherited it, plus two compositions with their own — the defect a template repeats is the defect no reader sees (council read 16). |
| **E-not-exclusive** *(advisory)* | An `EXACTLY ONE OF` whose members are not exclusive — one member containing another, so the exclusive choice does not exclude (Earned vocabulary 4). Two instances on file before it landed, both in a self-containment invariant, both repaired by declaring the set as a term (council read 9, council read 13). |
| **W-or-word / W-watch-word / W-term-unused** *(advisory)* | A lower-case `or` inside an obligation; `after`, `before`, `until`, `while`, `unless` inside a rule (§18's watch list); a `Terms ›` declaration nothing uses. |

A code span inside a rule is read as quoted text, never as the rule's own tokens — the grammar's meta-rules mention the tokens they govern (`GRACE-lang.md` §18, provisional).

## What re-opens when a rule changes

`check.py` resolves a citation forward — a reference names a rule that exists.
[`cites.py`](cites.py) walks it backward, which is the reading nobody was doing:

```
python3 tools/grace/cites.py 'Fence 5'            # what rests on this rule
python3 tools/grace/cites.py 'fence'              # what rests on this term
python3 tools/grace/cites.py --changed HEAD~1     # what a commit's edits re-open
python3 tools/grace/cites.py --into event-log     # what the corpus cites INTO a spec
python3 tools/grace/cites.py --terms seam         # every declaration of one name
python3 tools/grace/cites.py --queue              # unmigrated specs, most-cited first
python3 tools/grace/cites.py --drift              # one name declared two ways; families spread across specs
python3 tools/grace/cites.py --unchecked <spec>   # rules no check names
```

`--into` is the pre-flight for rewriting a spec: a label the corpus cites is a
label that keeps its number. `--terms` answers the drift question — one name,
several declarations, and a reader of two specs reads both (council read 9 found `seam`
declared seven ways). `--queue` orders the migration by who is cited most,
which is how the corpus schedules its own work. `--drift` sweeps across Terms
registries — the space between documents, where the corpus's error mass moved
once the interiors got clean (council read 10). `--unchecked` is `K-check-bare`'s inverse: a check naming no rule is one
failure, a rule no check names is the other, and an unchecked *invariant* is the
one worth reading — a claim about every reachable state that nothing tests
(council read 11). Like the rest of the walker it names a
reading, not a defect: two specs may mean different things by one word and be
right, and the human decides which.

A rule rests on a label it cites and on every term it uses; a term rests on the
terms its own definition computes over, walked to the end of the chain. Rules
are the last hop and never a step in the walk — rule to rule to rule re-opens
the whole document, which is the same as re-opening nothing.

The tool names a reading and decides nothing (`GRACE-lang.md` Principle 8). It
exists because of a specific failure: Lease's `Check 6.1` measured a margin
Fence 5 set, Fence 5 was repaired, and nothing put the check back in front of a
reader — the citation graph was there, and only ever read forward (council read 8).
