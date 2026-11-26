#!/usr/bin/env python3
"""The grammar tree: every labelled rule of a page parsed to one GF tree (assets/design/grammar-tree.md
in the council's folder, the Money pretest).

    python3 tools/grammar/grammar.py pretest library/atoms/money.md     # the report, as JSON on stdout
    python3 tools/grammar/grammar.py tree library/atoms/money.md "Operation 8"   # one rule's trees

GRACE-lang.md stays the spec; the grammar is checked against it. GraceCore.gf holds the rule shape
(section 5) and the closed vocabulary (sections 13 and 14); this script generates one lexicon per page
from the page's own Term lines, term-entry headings and signature blocks and from declarations.md, with
the regular inflections of each word, so no content word is entered by hand. English function words
(the, of, whose ...) are a closed list here, FUNCTION_WORDS. The script calls the `gf` binary (GF 3.12):
$GF_BIN, else `gf` on PATH, else ~/.local/opt/gf-3.12/bin/gf with its lib beside it.

A rule counts as one tree, ambiguous (more than one tree: a failure, since a rule with two trees cannot
be a receipt) or failed (no tree). Each tree is written back in normalize.py's fields (GraceCoreNorm.gf)
and compared with normalize.py's lowering of the same rule; every disagreement is listed.
"""
from __future__ import annotations

import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
sys.path.insert(0, str(ROOT / "tools" / "grace"))
import ir  # noqa: E402
import normalize  # noqa: E402

KEYWORDS = {"IF", "THEN", "MUST", "NOT", "MAY", "EQUALS", "EQUAL", "DOES", "EXCEEDS", "EXCEED", "PRECEDES",
            "PRECEDE", "IS", "IN", "EXISTS", "AND", "OR", "PER", "ONLY", "(", ")"}
# English closed-class words and the punctuation a phrase carries; GRACE's own quantifiers in capitals.
FUNCTION_WORDS = """the a an of to for in on at by with as from under over between against without within
into onto across through throughout before after below above beside than then so whose that which who whom
where when what while this these those its it their them they no not any each both either neither or and
nor other another every all some one two three only also own same such per via including whether if
outside inside beyond until upon past near along around behind except among toward towards despite unless once
EVERY EXACTLY ONE OF NO , . ; : 's""".split()
# the External check form's own word (spec-format.md, the External check row: "a check needing evidence
# the records do not carry"; every External check reads "An auditor needing ... MUST read ...")
FORM_WORDS = ["needing"]
# the comparison verbs a modal takes in place of a record verb (normalize.py: act EXCEED)
OP_VERBS = ["EXCEED", "PRECEDE", "EQUAL"]


def tokenize(text: str) -> list[str]:
    text = text.strip()
    if text.endswith("."):
        text = text[:-1]
    out = []
    for m in re.finditer(r"\[[^\]]+\]|[A-Za-z][A-Za-z-]*(?:'s)?|\d+|[(),.;:]", text):
        t = m.group(0)
        if t.endswith("'s") and not t.startswith("["):
            out += [t[:-2], "'s"]
            continue
        out.append(t)
    fw = set(FUNCTION_WORDS)
    return [t.lower() if t not in KEYWORDS and t[:1].isupper() and t.lower() in fw and t not in fw else t
            for t in out]


def inflections(w: str) -> set[str]:
    forms = {w, w + "s", w + "es", w + "ing", w + "ed", w + "d"}
    if w.endswith("y"):
        forms |= {w[:-1] + "ies", w[:-1] + "ied"}
    if w.endswith("e"):
        forms.add(w[:-1] + "ing")
    return forms


def lexicon(page: Path, root: Path) -> tuple[set[str], list[str]]:
    """The page's words and record verbs, from its Term lines, term-entry headings and signature blocks
    and from declarations.md; label families from the page's labels and execution-contract.md."""
    text = page.read_text(encoding="utf-8")
    sources = [ln[5:] for ln in text.splitlines() if ln.startswith("Term ")]
    sources += [ln[5:] for ln in text.splitlines() if ln.startswith("#### ")]
    sources += ["[" + ln[5:].strip() + "]" for ln in text.splitlines() if ln.startswith("#### ")]
    sources += re.findall(r"```\n([a-z_]+\([^`]*?)```", text, re.S)
    decl = (root / "library" / "declarations.md").read_text(encoding="utf-8")
    sources += [ln[5:] for ln in decl.splitlines() if ln.startswith("Term ")]
    labels = re.findall(r"^\s*([A-Z][A-Za-z]*(?: [a-z]+)*) \d", text, re.M)
    ec = (root / "library" / "execution-contract.md").read_text(encoding="utf-8")
    labels += re.findall(r"^\s*(?:\*\*|- )?([A-Z][A-Za-z]*(?: [a-z]+)*) \d+[a-z]?:", ec, re.M)
    sources += labels + ["Execution Contract", "GRACE-lang", "Non-goals", "through"]
    words: set[str] = set()
    for s in sources:
        for t in tokenize(s):
            if t in KEYWORDS or t.isdigit():
                continue
            words.add(t)
            if re.fullmatch(r"[a-z][a-z-]*", t):
                words |= inflections(t)
    words |= set(FUNCTION_WORDS) | set(FORM_WORDS)
    m = re.search(r"^Term record verbs: (.*)\.$", text, re.M)
    verbs = ([v.strip() for v in m.group(1).split(",")] if m else []) + OP_VERBS
    return words, verbs


def gf_bin() -> tuple[str, dict]:
    env = dict(os.environ)
    if os.environ.get("GF_BIN"):
        return os.environ["GF_BIN"], env
    if shutil.which("gf"):
        return "gf", env
    home = Path.home() / ".local" / "opt" / "gf-3.12"
    env["DYLD_LIBRARY_PATH"] = str(home / "lib")
    return str(home / "bin" / "gf"), env


def gf_str(s: str) -> str:
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'


def fun_name(prefix: str, word: str) -> str:
    """A stable GF name for a word: the word itself, any other character written as _<hex>_, so a tree
    names the same word the same way whatever else the lexicon holds (a receipt across an edit)."""
    return prefix + "".join(c if c.isascii() and c.isalnum() else f"_{ord(c):x}_" for c in word)


def build(page: Path, root: Path, out: Path) -> Path:
    """Write the page's lexicon modules beside the core and compile one PGF."""
    words, verbs = lexicon(page, root)
    for f in ("GraceCore.gf", "GraceCoreEng.gf", "GraceCoreNorm.gf"):
        shutil.copy(HERE / f, out / f)
    ws = sorted(words)
    vs = sorted(set(verbs))
    absl = ["abstract GraceLex = GraceCore ** {", "  flags startcat = Rule ;", "  fun"]
    absl += [f"    {fun_name('w_', w)} : W ;" for w in ws] + [f"    {fun_name('v_', v)} : V ;" for v in vs] + ["}"]
    (out / "GraceLex.gf").write_text("\n".join(absl) + "\n", encoding="utf-8")
    for lang in ("Eng", "Norm"):
        c = [f"concrete GraceLex{lang} of GraceLex = GraceCore{lang} ** {{", "  lin"]
        c += [f"    {fun_name('w_', w)} = {gf_str(w)} ;" for w in ws]
        c += [f"    {fun_name('v_', v)} = {gf_str(v)} ;" for v in vs] + ["}"]
        (out / f"GraceLex{lang}.gf").write_text("\n".join(c) + "\n", encoding="utf-8")
    gf, env = gf_bin()
    r = subprocess.run([gf, "-make", "--output-dir", str(out), str(out / "GraceLexEng.gf"),
                        str(out / "GraceLexNorm.gf")], capture_output=True, text=True, cwd=out, env=env)
    if r.returncode != 0 or not (out / "GraceLex.pgf").exists():
        raise SystemExit("gf -make failed:\n" + r.stdout + r.stderr)
    (out / "lexicon.json").write_text(json.dumps({"words": ws, "verbs": vs}, indent=0), encoding="utf-8")
    return out / "GraceLex.pgf"


def run_gf(pgf: Path, commands: list[str]) -> str:
    gf, env = gf_bin()
    r = subprocess.run([gf, "--run", str(pgf)], input="\n".join(commands) + "\n", capture_output=True,
                       text=True, env=env)
    return r.stdout + r.stderr


def parse_all(pgf: Path, items: list[tuple[str, list[str]]]) -> dict[str, dict]:
    """Each item's trees (all of them) and, for a rule with exactly one, its Norm linearization."""
    cmds = []
    for label, toks in items:
        cmds += [f"ps {gf_str('@@ ' + label)}", f"p -cat=Rule -lang=GraceLexEng {gf_str(' '.join(toks))}"]
    out = run_gf(pgf, cmds)
    res: dict[str, dict] = {}
    cur = None
    for ln in out.splitlines():
        if ln.startswith("@@ "):
            cur = ln[3:]
            res[cur] = {"trees": [], "error": None}
        elif cur is not None and ln.strip():
            if ln.startswith("The parser failed") or ln.startswith("The sentence is not complete"):
                res[cur]["error"] = ln.strip()
            else:
                res[cur]["trees"].append(ln.strip())
    norm_cmds = []
    for label, r in res.items():
        if len(r["trees"]) == 1:
            norm_cmds += [f"ps {gf_str('@@ ' + label)}", f"l -lang=GraceLexNorm {r['trees'][0]}"]
    out = run_gf(pgf, norm_cmds)
    cur = None
    for ln in out.splitlines():
        if ln.startswith("@@ "):
            cur = ln[3:]
        elif cur is not None and ln.strip():
            res[cur]["norm"] = ln.strip()
    return res


def tidy(s: str) -> str:
    s = re.sub(r"\s+", " ", s).strip()
    s = re.sub(r"^(\w+)= ?", r"\1=", s)
    # the leading article is lowered by the tokenizer (The, A, An); compare it lowered on both sides
    s = re.sub(r"=(The|A|An) ", lambda m: "=" + m.group(1).lower() + " ", s)
    s = s.replace(" 's", "'s").replace(" ,", ",").replace(" ;", ";").replace(" :", ":")
    s = re.sub(r"(\d) \. (\d)", r"\1.\2", s)
    return s.rstrip(",").strip()


def clause_text(c: dict) -> str:
    return c.get("text", "")


def norm_fields(form: dict) -> str:
    """normalize.py's form, written in GraceCoreNorm's fields."""
    parts = []
    if form.get("if"):
        parts.append("if=" + f" {form['if']['join']} ".join(clause_text(c) for c in form["if"]["clauses"]))
    parts.append("subject=" + ((form["quantifier"] + " ") if form.get("quantifier") else "") + form.get("subject", ""))
    for ob in form.get("obligations", []):
        parts.append("modal=" + ob.get("modal", ""))
        parts.append("act=" + ob.get("act", ""))
        parts.append("object=" + ob.get("object", ""))
        for t in ob.get("timing", []):
            parts.append(f"timing={t['kind']} {t.get('term', '')}")
        for g in ob.get("only_if", []):
            parts.append("only_if=" + f" {g['join']} ".join(clause_text(c) for c in g["clauses"]))
        if ob.get("cited"):
            parts.append("cited=" + ob["cited"])
    return "|".join(tidy(p) for p in parts)


def tree_fields(norm: str) -> str:
    return "|".join(tidy(p) for p in norm.split("|"))


def shape(form: dict, text: str) -> str:
    if form.get("kind") == "when" or text.lstrip().startswith("WHEN"):
        return "WHEN"
    mods = [ob.get("modal") for ob in form.get("obligations", [])]
    if len(mods) != 1:
        return "other"
    m = mods[0]
    if form.get("if"):
        return {"MUST": "IF … MUST", "MUST NOT": "IF … MUST NOT"}.get(m, "other")
    return {"MUST": "plain MUST", "MUST NOT": "plain MUST NOT", "MAY": "plain MAY"}.get(m, "other")


SHAPES = ["plain MUST", "plain MUST NOT", "IF … MUST", "plain MAY", "IF … MUST NOT", "WHEN", "other"]


def pretest(page: Path, root: Path = ROOT, keep: Path | None = None) -> dict:
    doc = ir.parse(page, root)
    rules = [r for r in doc["rules"] if not r["text"].lstrip().startswith("Deleted:")]
    forms = normalize.lower_doc(doc)["rules"]
    out = keep or Path(tempfile.mkdtemp(prefix="grammar-"))
    out.mkdir(parents=True, exist_ok=True)
    pgf = build(page, root, out)
    items = [(r["label"], tokenize(r["text"])) for r in rules]
    # the receipt test, one case each: spacing (an edit normalize.py reads as the same form) and a bound
    # changed (EXCEEDS to PRECEDES), on the first rule whose condition compares with EXCEEDS
    probe = next((r for r in rules if " EXCEEDS " in r["text"] and r["text"].startswith("IF ")), None)
    if probe:
        spaced = probe["text"].replace(" ", "  ")
        items += [("receipt:editorial", tokenize(spaced)),
                  ("receipt:meaning", tokenize(probe["text"].replace(" EXCEEDS ", " PRECEDES ", 1)))]
    res = parse_all(pgf, items)
    rows = []
    for r in rules:
        p = res.get(r["label"], {"trees": [], "error": "no output"})
        form = forms.get(r["label"]) or {}
        n = len(p["trees"])
        row = {"label": r["label"], "shape": shape(form, r["text"]), "trees": n,
               "verdict": "one tree" if n == 1 else ("ambiguous" if n > 1 else "failed"),
               "error": p.get("error")}
        if n == 1:
            row["tree"] = p["trees"][0]
            a, b = tree_fields(p.get("norm", "")), norm_fields(form)
            row["normalize"] = "agrees" if a == b else "differs"
            if a != b:
                row["tree_fields"], row["normalize_fields"] = a, b
        rows.append(row)
    by_shape = {s: {"rules": 0, "one tree": 0, "ambiguous": 0, "failed": 0} for s in SHAPES}
    for row in rows:
        by_shape[row["shape"]]["rules"] += 1
        by_shape[row["shape"]][row["verdict"]] += 1
    receipt = {}
    if probe:
        base = res.get(probe["label"], {}).get("trees", [])
        ed = res.get("receipt:editorial", {}).get("trees", [])
        me = res.get("receipt:meaning", {}).get("trees", [])
        receipt = {"rule": probe["label"],
                   "editorial": {"edit": "every space doubled (normalize.py squeezes spacing)",
                                 "equal": len(base) == 1 and ed == base},
                   "meaning": {"edit": "EXCEEDS to PRECEDES",
                               "differs": len(base) == 1 and len(me) == 1 and me != base}}
    one = sum(1 for r in rows if r["verdict"] == "one tree")
    unknown = sorted({m.group(1) for r in rows if r["error"]
                      for m in [re.search(r'token \d+: "?([^"]+)"?', r["error"] or "")] if m})
    return {"page": str(page.relative_to(root)), "rules": len(rows), "one tree": one,
            "share": round(one / len(rows), 4) if rows else 0.0, "bar": 0.9, "passed": bool(rows) and one / len(rows) >= 0.9,
            "by shape": by_shape, "shapes unexercised": [s for s in SHAPES if by_shape[s]["rules"] == 0],
            "normalize differs": [r["label"] for r in rows if r.get("normalize") == "differs"],
            "failed at": unknown, "receipt": receipt, "rows": rows, "build": str(out)}


def main(argv: list[str]) -> int:
    if len(argv) >= 3 and argv[1] == "pretest":
        rep = pretest(ROOT / argv[2], ROOT, Path(argv[argv.index("--keep") + 1]) if "--keep" in argv else None)
        print(json.dumps(rep, indent=1, ensure_ascii=False))
        return 0 if rep["passed"] else 1
    if len(argv) >= 4 and argv[1] == "tree":
        page = ROOT / argv[2]
        doc = ir.parse(page, ROOT)
        r = next(x for x in doc["rules"] if x["label"] == argv[3])
        out = Path(tempfile.mkdtemp(prefix="grammar-"))
        res = parse_all(build(page, ROOT, out), [(r["label"], tokenize(r["text"]))])
        print(json.dumps(res, indent=1, ensure_ascii=False))
        return 0
    print(__doc__)
    return 2


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
