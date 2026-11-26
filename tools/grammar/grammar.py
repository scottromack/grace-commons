#!/usr/bin/env python3
"""The grammar tree: every labelled rule of a page parsed to one GF tree (the council's
assets/design/grammar-tree.md, the pretest).

    python3 tools/grammar/grammar.py pretest library/atoms/money.md [--keep <dir>]   # the report, JSON
    python3 tools/grammar/grammar.py tree library/atoms/money.md "Operation 8"        # one rule's trees

GRACE-lang.md stays the spec; the grammar is checked against it. GraceCore.gf holds the rule shape
(section 5) and the closed vocabulary (sections 13 and 14), its constructors named for their role.
This script builds one lexicon per page, each word from the first source that has it (Scott,
2026-11-26 12:23 PM Central):

  1. the page's own Term lines (with its term-entry headings and signature blocks);
  2. library/declarations.md;
  3. GRACE-lang.md sections 13 and 14;
  4. GF's resource-library English dictionary, DictEng.gf, for any plain English word left.

A word a higher source supplies never takes the dictionary's. Words of sources 1 to 3 carry their
regular inflections; DictEng supplies the forms it lists, and the regular ones of its base. English
function words (the, of, whose ...) are the grammar's own closed list, FUNCTION_WORDS. No content word
is entered by hand. GF 3.12 runs as $GF_BIN, else `gf` on PATH, else ~/.local/opt/gf-3.12/bin/gf with its
lib beside it; DictEng.gf is $GF_DICTENG, else ~/.local/opt/gf-rgl/src/english/DictEng.gf.

Per rule: one tree, ambiguous (a failure: a rule with two trees cannot be a receipt) or failed. Two
loops run on every rule with one tree: loop 1, text to tree to normalize.py's fields (GraceCoreNorm.gf),
must equal normalize.py's lowering; loop 2, tree to text (GraceCoreEng.gf) to tree, must give the same
tree. The meaning sweep, the audit of normalize.py: every closed-vocabulary swap the rule admits (a
modal, a comparison, the join of a condition) and one Term swap must each give a different tree.
"""
from __future__ import annotations

import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import time
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
SOURCES = ["page", "declarations.md", "GRACE-lang sections 13-14", "DictEng", "compound", "function words"]
# the closed vocabulary a meaning swap exchanges, each class's members as token runs
SWAP_CLASSES = {
    "modal": [["MUST", "NOT"], ["MUST"], ["MAY"]],
    "comparison": [["DOES", "NOT", "EQUAL"], ["DOES", "NOT", "EXCEED"], ["DOES", "NOT", "PRECEDE"],
                   ["IS", "NOT", "IN"], ["EQUALS"], ["EXCEEDS"], ["PRECEDES"], ["IS", "IN"]],
    "join": [["AND"], ["OR"]],
}


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
        forms |= {w[:-1] + "ing", w + "r", w + "st"}
    forms |= {w + "er", w + "est"}
    if w.endswith("y"):
        forms |= {w[:-1] + "ier", w[:-1] + "iest"}
    return forms


def words_of(texts: list[str], inflect: bool = True) -> set[str]:
    out: set[str] = set()
    for s in texts:
        for t in tokenize(s):
            if t in KEYWORDS or t.isdigit():
                continue
            out.add(t)
            if inflect and re.fullmatch(r"[a-z][a-z-]*", t):
                out |= inflections(t)
    return out


def dicteng_path() -> Path:
    return Path(os.environ.get("GF_DICTENG") or
                Path.home() / ".local" / "opt" / "gf-rgl" / "src" / "english" / "DictEng.gf")


_DICT: set[str] | None = None


def dicteng() -> set[str]:
    """Every single-word form DictEng.gf and IrregEng.gf (beside it) write, with the regular inflections
    of each entry's first form."""
    global _DICT
    if _DICT is None:
        _DICT = set()
        p = dicteng_path()
        for q in (p, p.parent / "IrregEng.gf"):
            if not q.exists():
                continue
            for ln in q.read_text(encoding="utf-8").splitlines():
                if not (ln.startswith("lin ") or re.match(r"\s*\w+\s*=\s*irreg", ln)):
                    continue
                forms = [f for f in re.findall(r'"([^"]+)"', ln) if re.fullmatch(r"[a-z][a-z-]*", f)]
                _DICT |= set(forms)
                if forms:
                    _DICT |= inflections(forms[0])
    return _DICT


def page_sources(page: Path, root: Path) -> dict[str, list[str]]:
    text = page.read_text(encoding="utf-8")
    lines = text.splitlines()
    pg = [ln[5:] for ln in lines if ln.startswith("Term ")]
    pg += [ln[5:] for ln in lines if ln.startswith("#### ")]
    pg += ["[" + ln[5:].strip() + "]" for ln in lines if ln.startswith("#### ")]
    pg += re.findall(r"```\n([a-z_]+\([^`]*?)```", text, re.S)
    labels = re.findall(r"^\s*([A-Z][A-Za-z-]*(?: [a-z]+)*) \d", text, re.M)
    ec = (root / "library" / "execution-contract.md").read_text(encoding="utf-8")
    labels += re.findall(r"^\s*(?:\*\*|- )?([A-Z][A-Za-z]*(?: [a-z]+)*) \d+[a-z]?:", ec, re.M)
    pg += labels + ["Execution Contract", "GRACE-lang", "Non-goals", "through"]
    decl = (root / "library" / "declarations.md").read_text(encoding="utf-8")
    dc = [ln[5:] for ln in decl.splitlines() if ln.startswith("Term ")]
    gl = (root / "how" / "GRACE-lang.md").read_text(encoding="utf-8")
    m = re.search(r"^### 13\. .*?(?=^### 15\. )", gl, re.M | re.S)
    return {"page": pg, "declarations.md": dc, "GRACE-lang sections 13-14": [m.group(0)] if m else []}


def lexicon(page: Path, root: Path, need: set[str] | None = None) -> tuple[dict[str, str], list[str]]:
    """Each word with the source that supplies it, by the order of SOURCES, and the record verbs.
    `need`, the tokens the page's rules use, bounds what DictEng contributes."""
    src = page_sources(page, root)
    lex: dict[str, str] = {}
    for name in ("page", "declarations.md", "GRACE-lang sections 13-14"):
        for w in sorted(words_of(src[name])):
            lex.setdefault(w, name)
    for w in FUNCTION_WORDS + FORM_WORDS:
        lex.setdefault(w, "function words")
    if need:
        d = dicteng()
        for w in sorted(need):
            if w not in lex and w not in KEYWORDS and (w in d or w.lower() in d) and not w.isdigit():
                lex[w] = "DictEng"
        # a hyphenated word every part of which a source supplies ("non-blank", "byte-exactly")
        for w in sorted(need):
            parts = w.split("-")
            if w not in lex and len(parts) > 1 and all(x in lex or x in d for x in parts if x):
                lex[w] = "compound"
    text = page.read_text(encoding="utf-8")
    m = re.search(r"^Term record verbs: (.*)\.$", text, re.M)
    verbs = ([v.strip() for v in m.group(1).split(",")] if m else []) + OP_VERBS
    return lex, verbs


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


def build(page: Path, root: Path, out: Path, need: set[str] | None = None) -> Path:
    """Write the page's lexicon modules beside the core and compile one PGF."""
    lex, verbs = lexicon(page, root, need)
    for f in ("GraceCore.gf", "GraceCoreEng.gf", "GraceCoreNorm.gf"):
        shutil.copy(HERE / f, out / f)
    ws = sorted(lex)
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
    (out / "lexicon.json").write_text(json.dumps({"words": lex, "verbs": vs}, indent=0), encoding="utf-8")
    return out / "GraceLex.pgf"


def run_gf(pgf: Path, commands: list[str]) -> str:
    gf, env = gf_bin()
    r = subprocess.run([gf, "--run", str(pgf)], input="\n".join(commands) + "\n", capture_output=True,
                       text=True, env=env)
    return r.stdout + r.stderr


def collect(out: str, key: str) -> dict[str, list[str]]:
    res: dict[str, list[str]] = {}
    cur = None
    for ln in out.splitlines():
        if ln.startswith("@@ "):
            cur = ln[3:]
            res[cur] = []
        elif cur is not None and ln.strip():
            res[cur].append(ln.strip())
    return res


def parse_many(pgf: Path, items: list[tuple[str, list[str]]]) -> dict[str, dict]:
    cmds = []
    for label, toks in items:
        cmds += [f"ps {gf_str('@@ ' + label)}", f"p -cat=Rule -lang=GraceLexEng {gf_str(' '.join(toks))}"]
    res = {}
    for label, lines in collect(run_gf(pgf, cmds), "p").items():
        err = next((ln for ln in lines if ln.startswith(("The parser failed", "The sentence is not complete"))), None)
        res[label] = {"trees": [ln for ln in lines if ln != err], "error": err}
    return res


def linearize_many(pgf: Path, lang: str, trees: dict[str, str]) -> dict[str, str]:
    cmds = []
    for label, t in trees.items():
        cmds += [f"ps {gf_str('@@ ' + label)}", f"l -lang={lang} {t}"]
    return {k: " ".join(v) for k, v in collect(run_gf(pgf, cmds), "l").items()}


def tidy(s: str) -> str:
    s = re.sub(r"\s+", " ", s).strip()
    s = re.sub(r"^(\w+)= ?", r"\1=", s)
    # the tokenizer lowers a leading function word (The, A, Two ...); compare it lowered on both sides
    s = re.sub(r"=([A-Z][a-z]*) ", lambda m: "=" + (m.group(1).lower() if m.group(1).lower() in FUNCTION_WORDS
               else m.group(1)) + " ", s)
    s = s.replace(" 's", "'s").replace(" ,", ",").replace(" ;", ";").replace(" :", ":")
    s = re.sub(r"(\d) \. (\d)", r"\1.\2", s)
    return s.rstrip(",").strip()


def clause_text(c: dict) -> str:
    return c.get("text", "")


def canon(fields: list[str]) -> str:
    """The fields in one order: the tails (timing, only_if, cited) sorted, since normalize.py's form is
    the same whatever the order of a rule's tails (GRACE-lang Hard invariant 15)."""
    head = [f for f in fields if not f.startswith(("timing=", "only_if=", "cited="))]
    return "|".join(head + sorted(f for f in fields if f not in head))


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
    return canon([tidy(p) for p in parts])


def tree_fields(norm: str) -> str:
    return canon([tidy(p) for p in norm.split("|")])


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


def fragment(text: str, toks: list[str], error: str | None) -> str:
    """The fragment a failure sits in (grammar-tree.md, *Every failure is attributed per fragment*)."""
    at = None
    m = re.search(r"token (\d+)", error or "")
    if m:
        at = int(m.group(1)) - 1
    if "`" in text or '"' in text:
        return "a quoted identifier"
    if "EXACTLY ONE OF" in text:
        return "EXACTLY ONE OF"
    if re.search(r"\([^)]*(\d\s*[-+*/×÷]\s*\d| [-+*/×÷] )[^)]*\)", text):
        return "arithmetic in parentheses"
    if at is not None and "(" in toks[:at + 1] and ")" not in toks[toks.index("(") if "(" in toks else 0:at + 1]:
        return "a parenthetical citation"
    head = text.split(" THEN ")[0] if text.startswith("IF ") else ""
    if " AND " in head and " OR " in head:
        return "coordination scope (A AND B OR C)"
    if text.lstrip().startswith("WHEN"):
        return "WHEN"
    tail = text.split(" PER ")[-1] if " PER " in text else ""
    if tail and at is not None and re.search(r"\b(whose|that|which|where)\b", tail):
        return "a relative clause in a tail"
    if error and error.startswith("The parser failed"):
        return "a word no source supplies" if at is not None and toks[at] not in KEYWORDS else "the rule shape"
    return "the rule shape"


def spans(toks: list[str], members: list[list[str]]) -> list[tuple[int, int, list[str]]]:
    """Where a class's members stand in the tokens, longest first, never overlapping."""
    out, used = [], set()
    for mem in sorted(members, key=len, reverse=True):
        n = len(mem)
        for i in range(len(toks) - n + 1):
            if toks[i:i + n] == mem and not used & set(range(i, i + n)):
                out.append((i, i + n, mem))
                used |= set(range(i, i + n))
    return sorted(out)


def swaps(toks: list[str], lex: dict[str, str]) -> list[tuple[str, list[str]]]:
    """Every closed-vocabulary swap the rule admits (each occurrence, each other member of its class)
    and one Term swap (the first page word, for another page word)."""
    out = []
    for cls, members in SWAP_CLASSES.items():
        for i, j, mem in spans(toks, members):
            for other in members:
                if other != mem:
                    out.append((f"{cls}: {' '.join(mem)} → {' '.join(other)}", toks[:i] + other + toks[j:]))
    page_words = sorted(w for w, s in lex.items() if s == "page" and re.fullmatch(r"[a-z][a-z-]+", w))
    for k, t in enumerate(toks):
        if lex.get(t) == "page" and re.fullmatch(r"[a-z][a-z-]+", t):
            alt = next((w for w in page_words if w != t and not w.startswith(t) and not t.startswith(w)), None)
            if alt:
                out.append((f"term: {t} → {alt}", toks[:k] + [alt] + toks[k + 1:]))
            break
    return out


def pretest(page: Path, root: Path = ROOT, keep: Path | None = None) -> dict:
    t0 = time.monotonic()
    doc = ir.parse(page, root)
    rules = [r for r in doc["rules"] if not r["text"].lstrip().startswith("Deleted:")]
    forms = normalize.lower_doc(doc)["rules"]
    toks = {r["label"]: tokenize(r["text"]) for r in rules}
    need = {t for ts in toks.values() for t in ts}
    out = keep or Path(tempfile.mkdtemp(prefix="grammar-"))
    out.mkdir(parents=True, exist_ok=True)
    pgf = build(page, root, out, need)
    lex = json.loads((out / "lexicon.json").read_text(encoding="utf-8"))["words"]
    res = parse_many(pgf, list(toks.items()))
    one = {k: v["trees"][0] for k, v in res.items() if len(v["trees"]) == 1}
    norm = linearize_many(pgf, "GraceLexNorm", one)
    eng = linearize_many(pgf, "GraceLexEng", one)
    back = parse_many(pgf, [(k, v.split()) for k, v in eng.items()])
    sw_items, sw_index = [], []
    for k in one:
        for n, (what, variant) in enumerate(swaps(toks[k], lex)):
            sw_items.append((f"{k} #{n}", variant))
            sw_index.append((k, f"{k} #{n}", what))
    sw_res = parse_many(pgf, sw_items) if sw_items else {}
    rows = []
    for r in rules:
        k = r["label"]
        p = res.get(k, {"trees": [], "error": "no output"})
        form = forms.get(k) or {}
        n = len(p["trees"])
        row = {"label": k, "shape": shape(form, r["text"]), "trees": n,
               "verdict": "one tree" if n == 1 else ("ambiguous" if n > 1 else "failed"), "error": p.get("error")}
        if n == 1:
            row["tree"] = one[k]
            a, b = tree_fields(norm.get(k, "")), norm_fields(form)
            row["loop 1"] = a == b
            if a != b:
                row["tree_fields"], row["normalize_fields"] = a, b
            row["loop 2"] = back.get(k, {}).get("trees") == [one[k]]
            mine = [(what, sw_res.get(lab, {"trees": []})["trees"]) for kk, lab, what in sw_index if kk == k]
            row["swaps"] = len(mine)
            row["swaps parsed"] = sum(1 for _, ts in mine if ts)
            row["swaps same tree"] = [what for what, ts in mine if one[k] in ts]
        else:
            row["fragment"] = fragment(r["text"], toks[k], p.get("error"))
            m = re.search(r'token (\d+): "?([^"]+)"?', p.get("error") or "")
            if m:
                row["failed at"] = m.group(2)
        rows.append(row)
    by_shape = {s: {"rules": 0, "one tree": 0, "ambiguous": 0, "failed": 0} for s in SHAPES}
    for row in rows:
        by_shape[row["shape"]]["rules"] += 1
        by_shape[row["shape"]][row["verdict"]] += 1
    examples = {}
    for row in rows:
        if row["verdict"] == "one tree" and row["shape"] not in examples:
            examples[row["shape"]] = {"label": row["label"], "tree": row["tree"]}
    used = {t for ts in toks.values() for t in ts if t in lex}
    supplied = {s: sum(1 for w in used if lex[w] == s) for s in SOURCES}
    good = sum(1 for r in rows if r["verdict"] == "one tree")
    ones = [r for r in rows if r["verdict"] == "one tree"]
    return {
        "page": str(page.relative_to(root)), "rules": len(rows), "one tree": good,
        "share": round(good / len(rows), 4) if rows else 0.0, "bar": 0.9,
        "passed": bool(rows) and good / len(rows) >= 0.9,
        "by shape": by_shape, "shapes unexercised": [s for s in SHAPES if by_shape[s]["rules"] == 0],
        "loop 1 closes": sum(1 for r in ones if r["loop 1"]), "loop 2 closes": sum(1 for r in ones if r["loop 2"]),
        "loop 1 open": [r["label"] for r in ones if not r["loop 1"]],
        "loop 2 open": [r["label"] for r in ones if not r["loop 2"]],
        "swaps": sum(r["swaps"] for r in ones), "swaps parsed": sum(r["swaps parsed"] for r in ones),
        "swaps same tree": [(r["label"], w) for r in ones for w in r["swaps same tree"]],
        "words used, by source": supplied, "words used": len(used),
        "lexicon size, by source": {s: sum(1 for w in lex.values() if w == s) for s in SOURCES},
        "dicteng": str(dicteng_path()), "examples": examples,
        "failures": [{k: r.get(k) for k in ("label", "shape", "verdict", "fragment", "failed at", "error")}
                     for r in rows if r["verdict"] != "one tree"],
        "seconds": round(time.monotonic() - t0, 1), "rows": rows, "build": str(out),
    }


def main(argv: list[str]) -> int:
    if len(argv) >= 3 and argv[1] == "pretest":
        rep = pretest(ROOT / argv[2], ROOT, Path(argv[argv.index("--keep") + 1]) if "--keep" in argv else None)
        print(json.dumps(rep, indent=1, ensure_ascii=False))
        return 0 if rep["passed"] else 1
    if len(argv) >= 4 and argv[1] == "tree":
        page = ROOT / argv[2]
        doc = ir.parse(page, ROOT)
        r = next(x for x in doc["rules"] if x["label"] == argv[3])
        toks = tokenize(r["text"])
        out = Path(tempfile.mkdtemp(prefix="grammar-"))
        print(json.dumps(parse_many(build(page, ROOT, out, set(toks)), [(r["label"], toks)]), indent=1,
                         ensure_ascii=False))
        return 0
    print(__doc__)
    return 2


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
