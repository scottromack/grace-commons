#!/usr/bin/env python3
"""The grammar tree: every labelled rule of a page parsed to one GF tree (the council's
assets/design/grammar-tree.md, the pretest).

    python3 tools/grammar/grammar.py pretest library/atoms/money.md [--keep <dir>]   # the report, JSON
    python3 tools/grammar/grammar.py tree library/atoms/money.md "Operation 8"        # one rule's trees
    python3 tools/grammar/grammar.py corpus <dir>                                      # every atom, a report each

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
            "PRECEDE", "IS", "IN", "EXISTS", "AND", "OR", "PER", "ONLY", "(", ")",
            # the WHEN block, the tails and the authority shape (sections 5, 7, 9 and 10)
            "WHEN", "AFTER", "BEFORE", "WITHIN", "UNDER", "AUTHORITATIVE", "FOR"}
# English closed-class words and the punctuation a phrase carries; GRACE's own quantifiers in capitals.
FUNCTION_WORDS = """the a an of to for in on at by with as from under over between against without within
into onto across through throughout before after below above beside than then so whose that which who whom
where when what while this these those its it their them they no not any each both either neither or and
nor other another every all some one two three only also own same such per via including whether if
outside inside beyond until upon past near along around behind except among toward towards despite unless once
zero four five six seven eight nine ten first second third fourth fifth sixth seventh eighth ninth tenth
could cannot
EVERY EXACTLY ONE OF NO , . ; : 's '""".split()
# the cardinals beside one, two and three are the numbers normalize.py reads as words (NUMBER_WORDS, zero to
# ten), and the ordinals are their kin: English closed-class words, as the determiners above are
# the External check form's own word (spec-format.md, the External check row: "a check needing evidence
# the records do not carry"; every External check reads "An auditor needing ... MUST read ...")
FORM_WORDS = ["needing"]
# the comparison verbs a modal takes in place of a record verb (normalize.py: act EXCEED)
OP_VERBS = ["EXCEED", "PRECEDE", "EQUAL"]
SOURCES = ["page", "declarations.md", "GRACE-lang sections 13-14", "DictEng", "compound", "function words",
           "code span"]
# the closed vocabulary a meaning swap exchanges, each class's members as token runs
SWAP_CLASSES = {
    "modal": [["MUST", "NOT"], ["MUST"], ["MAY"]],
    "comparison": [["DOES", "NOT", "EQUAL"], ["DOES", "NOT", "EXCEED"], ["DOES", "NOT", "PRECEDE"],
                   ["IS", "NOT", "IN"], ["EQUALS"], ["EXCEEDS"], ["PRECEDES"], ["IS", "IN"]],
    "join": [["AND"], ["OR"]],
}


# a parenthesis written against the word before it, "invalid-request(step-4)": an arm's payload or a call,
# never a citation, which normalize.py takes only after a space (CITED); no rule of the grammar takes it
ATTACHED = "(attached"


def tokenize(text: str) -> list[str]:
    text = text.strip()
    if text.endswith("."):
        text = text[:-1]
    out = []
    # a bracket marker, a code span, a word (an identifier's underscore included), a possessive, a label's
    # number with its letter ("4a"), a number, punctuation, and any other character as itself, so that no
    # character of a rule is dropped unseen (an em dash or a rule symbol fails where it stands)
    for m in re.finditer(r"\[[^\]\n]+\]|`[^`\n]+`|[A-Za-z][A-Za-z_-]*(?:'s|')?|'s\b|\d+[a-z]\b|\d+|-|[(),.;:]|\S",
                         text):
        t = m.group(0)
        if t == "(" and m.start() > 0 and (text[m.start() - 1].isalnum() or text[m.start() - 1] in "_-"):
            out.append(ATTACHED)
            continue
        if t.startswith("`"):                          # a code span is one token; gf splits at spaces
            out.append(t.replace(" ", "_"))
            continue
        if t.endswith("'s") and len(t) > 2 and not t.startswith("["):
            out += [t[:-2], "'s"]
            continue
        if t.endswith("'") and len(t) > 1:          # a plural possessive, "the series' exceptions"
            out += [t[:-1], "'"]
            continue
        # a bracket marker is one token, and gf splits tokens at spaces: its spaces are written `_`
        out.append(t.replace(" ", "_") if t.startswith("[") else t)
    fw = set(FUNCTION_WORDS)
    # a capitalised function word is lowered where a sentence starts (the rule's first word, or the first
    # after a reserved token, "THEN The"), never inside a phrase ("the section titled Which closing stands")
    out = [t.lower() if (i == 0 or out[i - 1] in KEYWORDS) and t not in KEYWORDS and t[:1].isupper()
           and (len(t) == 1 or not t.isupper()) and t.lower() in fw and t not in fw else t for i, t in enumerate(out)]
    return [t for i, t in enumerate(out) if not (t in (",", ":") and edge_comma(out, i))]


MODAL_HEADS = {"MUST", "MAY"}


def paren_tokens(toks: list[str]) -> set[str]:
    """The tokens a rule writes inside parentheses: the words a closing citation may carry before its
    number (the grammar's CW, one entry for each such word of the page's rules)."""
    out, depth = set(), 0
    for t in toks:
        if t == "(":
            depth += 1
        elif t == ")":
            depth = max(0, depth - 1)
        elif depth:
            out.add(t)
    return out


def numberish(t: str) -> bool:
    """A number, or a label's number with its letter ("4a"): what a closing citation must carry."""
    return bool(re.fullmatch(r"\d+[a-z]?", t))


def edge_comma(toks: list[str], i: int) -> bool:
    """A comma is a separator (the corpus run, step 1, and GLM's comma policy): between two words of
    one phrase it separates a list's members, and the tree keeps it; at a phrase's edge it separates
    nothing, and the tree drops it, as normalize.py does. A phrase's edges are the rule's ends, a
    reserved token on either side, and the end of the act (`find, for EVERY row ...`)."""
    if i == 0 or i == len(toks) - 1 or toks[i - 1] in KEYWORDS or toks[i + 1] in KEYWORDS:
        return True
    if i >= 2 and toks[i - 2] in MODAL_HEADS:
        return True
    return i >= 3 and toks[i - 2] == "NOT" and toks[i - 3] == "MUST"


# what a source may give the lexicon: a word, a bracket marker, a possessive or a list's punctuation; a code
# span and a rule symbol are never a word (a rule carrying one fails where it stands)
LEX_TOKEN = re.compile(r"[A-Za-z][A-Za-z_-]*|\[[^\]`]+\]|'s|'|[,.;:]")


def reserved(t: str) -> bool:
    """An upper-case token is a reserved token (GRACE-lang Casing 2), never a domain word (Casing 5): the
    lexicon takes none, or a tail the grammar lacks (BEFORE, WITHIN, ONLY AFTER) reads as a phrase's
    word. GRACE's quantifiers in a phrase (EVERY, EXACTLY ONE OF, NO) are FUNCTION_WORDS."""
    return len(t) > 1 and t.isupper() and t not in FUNCTION_WORDS


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
            if t in KEYWORDS or t.isdigit() or reserved(t) or not LEX_TOKEN.fullmatch(t):
                continue
            out.add(t)
            if inflect and re.fullmatch(r"[a-z][a-z-]*", t):
                out |= inflections(t)
    return out


def dicteng_path() -> Path:
    return Path(os.environ.get("GF_DICTENG") or
                Path.home() / ".local" / "opt" / "gf-rgl" / "src" / "english" / "DictEng.gf")


_DICT: set[str] | None = None
_PROPER: set[str] | None = None


def dicteng() -> set[str]:
    """Every single-word form DictEng.gf and IrregEng.gf (beside it) write, with the regular inflections
    of each entry's first form."""
    global _DICT
    if _DICT is None:
        _DICT = set()
        _PROPER_FORMS.clear()
        p = dicteng_path()
        for q in (p, p.parent / "IrregEng.gf"):
            if not q.exists():
                continue
            for ln in q.read_text(encoding="utf-8").splitlines():
                if not (ln.startswith("lin ") or re.match(r"\s*\w+\s*=\s*irreg", ln)):
                    continue
                forms = [f for f in re.findall(r'"([^"]+)"', ln) if re.fullmatch(r"[a-z][a-z-]*", f)]
                _DICT |= set(forms)
                _PROPER_FORMS.update(f for f in re.findall(r'"([^"]+)"', ln) if re.fullmatch(r"[A-Z][a-z]+", f))
                if forms:
                    _DICT |= inflections(forms[0])
    return _DICT


_PROPER_FORMS: set[str] = set()


def proper_names() -> set[str]:
    """DictEng's capitalised entries, the proper names a rule may carry (GRACE-lang v0.76, Term proper
    name: European, Monday; the maintainer's ruling of 2026-11-27, 8:06 AM Central)."""
    dicteng()
    return _PROPER_FORMS


_NAMES: dict[str, list[str]] = {}


def pattern_names(root: Path) -> list[str]:
    key = str(root)
    if key not in _NAMES:
        names = []
        for d in ("atoms", "compositions", "apps"):
            for q in sorted((root / "library" / d).rglob("*")):
                if q.suffix in (".md", ".idd") and not q.name.endswith(".hist.md") and q.is_file():
                    m = re.search(r"^title: (.+)$", q.read_text(encoding="utf-8")[:400], re.M)
                    if m:
                        names.append(m.group(1).strip().strip('"'))
        _NAMES[key] = names
    return _NAMES[key]


def page_sources(page: Path, root: Path) -> dict[str, list[str]]:
    text = page.read_text(encoding="utf-8")
    lines = text.splitlines()
    # a Term line in the tree order stands indented under the rule it serves
    pg = [ln.lstrip()[5:] for ln in lines if ln.lstrip().startswith("Term ")]
    # a term entry's or an action's heading: #### in the section shape, ### for an action in the tree order
    heads = [ln.lstrip("#").strip() for ln in lines if ln.startswith(("### ", "#### "))]
    pg += heads + ["[" + h + "]" for h in heads]
    pg += re.findall(r"```\n([a-z_]+\([^`]*?)```", text, re.S)
    labels = re.findall(r"^\s*([A-Z][A-Za-z-]*(?: [a-z]+)*) \d", text, re.M)
    ec = (root / "library" / "execution-contract.md").read_text(encoding="utf-8")
    labels += re.findall(r"^\s*(?:\*\*|- )?([A-Z][A-Za-z]*(?: [a-z]+)*) \d+[a-z]?:", ec, re.M)
    pg += labels + ["Execution Contract", "GRACE-lang", "Non-goals", "through"]
    # the library's pattern names, each a spec's name as its title gives it (GRACE-lang Term name), named in a
    # rule as Execution Contract and GRACE-lang are: "MUST compose Restorable Delete"
    pg += pattern_names(root)
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
        for w in need:
            if re.fullmatch(r"\d+[a-z]", w):              # a lettered label number, "Sizing 4a"
                lex.setdefault(w, "page")
        d = dicteng()
        for w in sorted(need):
            if w not in lex and w not in KEYWORDS and not reserved(w) and (w in d or w.lower() in d or w in proper_names()) \
                    and not w.isdigit():
                lex[w] = "DictEng"
        # a code span, a code spelling such as a template (Term rule symbol: "a code spelling such as a
        # template sits in a code span"; Earned vocabulary 16), is a phrase's word as the rule writes it
        for w in need:
            if len(w) > 2 and w.startswith("`") and w.endswith("`"):
                lex.setdefault(w, "code span")
        # a hyphenated word every part of which a source supplies ("non-blank", "byte-exactly")
        for w in sorted(need):
            parts = [x for x in w.split("-") if x]       # a bare "-" has no parts: it is a sign, never a compound
            if w not in lex and not reserved(w) and len(parts) > 1 and all(x in lex or x in d for x in parts if x):
                lex[w] = "compound"
    text = page.read_text(encoding="utf-8")
    m = re.search(r"^Term record verbs: (.*)\.$", text, re.M)
    # a record verb is one word, as normalize.py's act is (the first word after the modal): a verb the page
    # writes in two words ("read back") gives the grammar its first word, and the rest stands in the object
    verbs = ([v.strip().split()[0] for v in m.group(1).split(",") if v.strip()] if m else []) + OP_VERBS
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


def build(page: Path, root: Path, out: Path, need: set[str] | None = None,
          cite: set[str] | None = None) -> Path:
    """Write the page's lexicon modules beside the core and compile one PGF. `cite`, the tokens the
    rules write inside parentheses, gives the words a citation carries before its number (CW)."""
    lex, verbs = lexicon(page, root, need)
    for f in ("GraceCore.gf", "GraceCoreEng.gf", "GraceCoreNorm.gf"):
        shutil.copy(HERE / f, out / f)
    ws = sorted(lex)
    vs = sorted(set(verbs))
    cws = sorted(w for w in (cite or set()) if w in lex and not numberish(w))
    ns = sorted(w for w in lex if re.fullmatch(r"\d+[a-z]", w))
    absl = ["abstract GraceLex = GraceCore ** {", "  flags startcat = Rule ;", "  fun"]
    absl += [f"    {fun_name('w_', w)} : W ;" for w in ws] + [f"    {fun_name('v_', v)} : V ;" for v in vs]
    absl += [f"    {fun_name('c_', w)} : CW ;" for w in cws] + [f"    {fun_name('n_', w)} : Num ;" for w in ns] + ["}"]
    (out / "GraceLex.gf").write_text("\n".join(absl) + "\n", encoding="utf-8")
    for lang in ("Eng", "Norm"):
        c = [f"concrete GraceLex{lang} of GraceLex = GraceCore{lang} ** {{", "  lin"]
        c += [f"    {fun_name('w_', w)} = {gf_str(w)} ;" for w in ws]
        c += [f"    {fun_name('v_', v)} = {gf_str(v)} ;" for v in vs]
        c += [f"    {fun_name('c_', w)} = {gf_str(w)} ;" for w in cws]
        c += [f"    {fun_name('n_', w)} = {gf_str(w)} ;" for w in ns] + ["}"]
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
    s = s.replace(" 's", "'s").replace(" ' ", "' ").replace(" ,", ",").replace(" ;", ";").replace(" :", ":")
    s = re.sub(r"- (\d)", r"-\1", s)                       # "step-2", split at the digit
    s = re.sub(r"\b(AND|OR|THEN|EQUAL|EXCEED|PRECEDE|EQUALS|EXCEEDS|PRECEDES|EXISTS|IN), ", r"\1 ", s)
    s = re.sub(r"^(\w+)=: ?", r"\1=", s)
    # a comma at a phrase's edge is a separator on both sides (edge_comma)
    s = re.sub(r"^(\w+)=, ?", r"\1=", s)
    s = re.sub(r",(?= (?:AND|OR|THEN|PER|ONLY|IS|EQUALS|EXCEEDS|PRECEDES|DOES|EXISTS|WITHIN|BEFORE|AFTER)\b)", "", s)
    s = re.sub(r"(\d) \. (\d)", r"\1.\2", s)
    s = re.sub(r"\[[^\]]*\]|`[^`]*`", lambda m: m.group(0).replace("_", " "), s)
    return s.rstrip(",:").strip()


def clause_text(c: dict) -> str:
    return c.get("text", "")


def canon(fields: list[str]) -> str:
    """The fields in the order they stand. Tail order stays in the tree: GRACE-lang Hard invariant 15
    reads "The parser MUST NOT infer from rule order", which speaks of the order of rules, not of a
    rule's tails (GLM's S1, settled in the corpus run), and normalize.py keeps a rule's tails in the
    order they stand too (Reverse diff 4, `normalize.tails`). A loop 1 that opens on tail order alone is
    a harness fault, and `tail_order_only` names that cause."""
    return "|".join(fields)


def tail_order_only(a: str, b: str) -> bool:
    """The two forms differ only in the order of their tails."""
    fa, fb = a.split("|"), b.split("|")
    return a != b and sorted(fa) == sorted(fb)


def norm_fields(form: dict) -> str:
    """normalize.py's form, written in GraceCoreNorm's fields."""
    parts = []
    if form.get("if"):
        parts.append("if=" + f" {form['if']['join']} ".join(clause_text(c) for c in form["if"]["clauses"]))
    if form.get("kind") == "when":
        cond = form["condition"]
        return canon([tidy("when=" + f" {cond['join']} ".join(clause_text(c) for c in cond["clauses"]))])
    if form.get("kind") == "authority":
        return canon([tidy("subject=" + form.get("subject", "")), tidy("authority=" + form.get("proposition", ""))])
    parts.append("subject=" + ((form["quantifier"] + " ") if form.get("quantifier") else "") + form.get("subject", ""))
    for ob in form.get("obligations", []):
        parts.append("modal=" + ob.get("modal", ""))
        parts.append("act=" + ob.get("act", ""))
        obj = ob.get("object", "")
        if "exclusive" in ob:      # normalize.py keeps EXACTLY ONE OF's members apart from the object
            obj = (obj + " EXACTLY ONE OF " + ", ".join(ob["exclusive"])).strip()
        parts.append("object=" + obj)
        for kind, item in normalize.tails(ob):
            if kind in ("ONLY IF", "ONLY UNDER"):
                key = "only_if=" if kind == "ONLY IF" else "only_under="
                parts.append(key + f" {item['join']} ".join(clause_text(c) for c in item["clauses"]))
            else:
                parts.append(f"timing={kind} {item.get('term', '')}")
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


# GLM's S2: "ought" is an English modal outside GRACE-lang's three; a page finding, never a modal
# could and cannot stand inside a phrase since GRACE-lang v0.76 (Earned vocabulary 25), function words above
NOT_MODALS = {"ought", "should", "shall", "must", "may", "might", "can", "will", "would"}


def home(row: dict, toks: list[str], lex: dict[str, str], form: dict, text: str) -> tuple[str, str, str]:
    """The home a rule's failure is filed to (grammar, page, normalize.py, GRACE-lang), the fragment, and
    the cure proposed, by the token the parser stopped at and what stands before it. The rules, each read
    on the corpus run's clusters (assets/design/grammar-tree-corpus.md in the council):

      grammar     GRACE-lang admits the form and the Rule lacks it; or two trees. The absence form's
                  `EXISTS for`, the WHEN block, the tails ONLY AFTER, AFTER, WITHIN, BEFORE and ONLY UNDER,
                  IS AUTHORITATIVE FOR and a code span are the Rule's since the grammar's own cures
                  (2026-11-27): a rule that fails at one of them is read for what else stands there.
      GRACE-lang  no clause admits it or bars it. Since v0.76 (the maintainer's ruling of 2026-11-27) none
                  is left: a citation stands only at a rule's end, an arm's payload or a call in a code span,
                  no other parenthesis in a rule (Rule shape 9 to 11), lower-case and joins subjects (Rule
                  shape 12), and a phrase carries one comparison (Earned vocabulary 24), so each is a page's.
      page        the page writes outside GRACE-lang: a word no source supplies, a modal outside the three,
                  EXISTS qualified otherwise than by a preposition phrase, a parenthesis outside a citation
                  or a code span, AND joining subjects, a second comparison inside one phrase,
                  a lower-case reserved word, IS or ONLY outside its form, a second obligation, OR outside
                  a condition, a rule symbol.
    """
    at = row.get("failed at")
    m = re.search(r"token (\d+)", row.get("error") or "")
    i = int(m.group(1)) - 1 if m else None
    before = toks[:i] if i is not None and i <= len(toks) else toks
    prev = before[-1] if before else ""
    if row["verdict"] == "ambiguous":
        return "grammar", "two trees", "one reading: the grammar takes a record verb as one word, as normalize.py's act is"
    if at is None:
        return "grammar", "the rule ends where the Rule wants more", "read the rule; admit the shape or file it"
    if at == "WHEN":
        return "page", "WHEN after a rule's start (Term rule form)", "open the block with WHEN, its statements as children"
    if prev == "EXISTS":
        return "page", f"EXISTS qualified otherwise than by a preposition phrase ({at})", "rephrase (Term absence form)"
    if at in ("BEFORE", "WITHIN", "AFTER", "UNDER", "AUTHORITATIVE", "FOR") or (at == "ONLY" and prev not in KEYWORDS) \
            or at.startswith("`"):
        return "grammar", f"{at} where the Rule takes none", "read the rule"
    if at == ATTACHED:
        return "page", "a parenthesis against its word (an arm's payload or a call)", \
            "write the arm or the call in a code span (Rule shape 10)"
    if at == ")" and "(" in before:
        inner = before[len(before) - before[::-1].index("("):]
        if i == len(toks) - 1 and not any(numberish(t) for t in inner):
            return "page", "a closing parenthetical with no number", \
                "rephrase, or write a tuple in a code span (Rule shape 11)"
        return "page", "a parenthetical before the rule's end", \
            "move the citation to the rule's end (Rule shape 9), or rephrase"
    if at in NOT_MODALS:
        return "page", f"'{at}', no modal of GRACE-lang's three", "rephrase in closed vocabulary"
    if at in ("EXCEED", "EQUAL", "PRECEDE") and prev == "not":
        return "page", f"a reserved word in lower case (does not {at})", f"write DOES NOT {at} (Casing 2, Earned vocabulary 17)"
    if at in ("after", "within", "before", "exactly") and prev in ("ONLY", "MUST", "NOT") or at == "exactly":
        return "page", f"a reserved word in lower case ({at})", "write it in upper case or rephrase (Casing 2)"
    if at == "(" or (")" in before and "(" in before and at not in lex):
        return "page", "a parenthetical before the rule's end", "move the citation to the rule's end (Rule shape 9), or rephrase"
    if ")" in before and before.index(")") < len(before) and before[-1] == ")":
        return "page", "words after a parenthetical", "move the citation to the rule's end (Rule shape 9), or rephrase"
    if at in ("DOES", "EXISTS", "EQUALS", "EXCEEDS", "PRECEDES", "EQUAL", "IS"):
        return "page", "a second comparison inside one phrase", "write one comparison to a subject, an object or a clause (Earned vocabulary 24)"
    if at == "AND" and "MUST" not in before and "MAY" not in before:
        return "page", "AND joining subjects", "write lower-case and (Rule shape 12)"
    if at in ("MUST", "MAY") or (at == "AND" and prev != ","):
        return "page", "a second obligation", "split the rule (Rule shape 3)"
    if at in ("OR", "or", "and", "NOT"):
        return "page", f"{at} where the Rule takes none (Hard invariant 7, 8)", "rephrase"
    if prev in ("IS", "ONLY") or prev == "NOT" and len(before) > 1 and before[-2] == "IS":
        return "page", f"{prev} outside its reserved form", "rephrase in closed vocabulary"
    if at not in lex and at not in KEYWORDS and not at.isdigit():
        if not LEX_TOKEN.fullmatch(at):
            return "page", f"a rule symbol ({at})", "rephrase (Earned vocabulary 16)"
        if at.isupper() and len(at) > 1:
            return "page", f"an upper-case token GRACE-lang does not reserve ({at})", "write it in lower case"
        return "page", "a word no source supplies", "declare it or rephrase"
    return "grammar", f"a known word where the Rule takes none ({at})", "read the rule"


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
    # a tombstone carries no obligation, and a PROVISIONAL: line has no normative force (GRACE-lang Surface 15)
    rules = [r for r in doc["rules"] if not r["text"].lstrip().startswith(("Deleted:", "PROVISIONAL:"))]
    forms = normalize.lower_doc(doc)["rules"]
    toks = {r["label"]: tokenize(r["text"]) for r in rules}
    need = {t for ts in toks.values() for t in ts}
    out = keep or Path(tempfile.mkdtemp(prefix="grammar-"))
    out.mkdir(parents=True, exist_ok=True)
    cite = {t for ts in toks.values() for t in paren_tokens(ts)}
    pgf = build(page, root, out, need, cite)
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
        row["unlowered"] = form.get("kind") == "unlowered"
        if n == 1:
            row["tree"] = one[k]
            row["uses"] = [c for c in ("CPred", "SCmp", "OOr") if re.search(rf"\b{c}\b", one[k])]
            a, b = tree_fields(norm.get(k, "")), norm_fields(form)
            row["loop 1"] = a == b
            if a != b:
                row["tree_fields"], row["normalize_fields"] = a, b
                row["loop 1 cause"] = "tail order" if tail_order_only(a, b) else (
                    "normalize.py cannot lower the rule" if row["unlowered"] else
                    "a closing parenthetical with no number: a citation to the grammar, text to normalize.py"
                    if a.count("|cited=") > b.count("|cited=") else "the fields differ")
            row["loop 2"] = back.get(k, {}).get("trees") == [one[k]]
            mine = [(what, sw_res.get(lab, {"trees": []})["trees"]) for kk, lab, what in sw_index if kk == k]
            row["swaps"] = len(mine)
            row["swaps parsed"] = sum(1 for _, ts in mine if ts)
            row["swaps same tree"] = [what for what, ts in mine if one[k] in ts]
        else:
            m = re.search(r'token (\d+): "?([^"]+)"?', p.get("error") or "")
            if m:
                row["failed at"] = m.group(2)
            row["home"], row["fragment"], row["cure"] = home(row, toks[k], lex, form, r["text"])
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
        "failures": [{k: r.get(k) for k in ("label", "shape", "verdict", "fragment", "failed at", "home", "cure",
                                            "error")} for r in rows if r["verdict"] != "one tree"],
        "one tree without CPred": sum(1 for r in ones if "CPred" not in r["uses"]),
        "one tree without CPred or SCmp": sum(1 for r in ones if not {"CPred", "SCmp"} & set(r["uses"])),
        "uses": {c: [r["label"] for r in ones if c in r["uses"]] for c in ("CPred", "SCmp", "OOr")},
        "seconds": round(time.monotonic() - t0, 1), "rows": rows, "build": str(out),
    }


def atoms(root: Path = ROOT) -> list[Path]:
    """Every atom page: library/atoms/*.md but its history files, index.md and the taxonomy note."""
    return sorted(p for p in [*(root / "library" / "atoms").glob("*.md"), *(root / "library" / "atoms").glob("*.idd")]
                  if not p.name.endswith(".hist.md") and p.name not in ("index.md", "TAXONOMY.md", "_TAXONOMY.md"))


def corpus(out: Path, root: Path = ROOT) -> dict:
    """The pretest's full method on every atom, one JSON report each in `out`, and the totals."""
    out.mkdir(parents=True, exist_ok=True)
    t0, totals = time.monotonic(), {"atoms": 0, "rules": 0, "one tree": 0, "seconds": {}}
    for page in atoms(root):
        with tempfile.TemporaryDirectory(prefix="grammar-") as d:
            rep = pretest(page, root, Path(d))
        rep.pop("build", None)
        (out / f"{page.stem}.json").write_text(json.dumps(rep, indent=1, ensure_ascii=False), encoding="utf-8")
        totals["atoms"] += 1
        totals["rules"] += rep["rules"]
        totals["one tree"] += rep["one tree"]
        totals["seconds"][page.stem] = rep["seconds"]
        print(f"{page.stem}: {rep['one tree']}/{rep['rules']} in {rep['seconds']} s", file=sys.stderr, flush=True)
    totals["total seconds"] = round(time.monotonic() - t0, 1)
    (out / "_totals.json").write_text(json.dumps(totals, indent=1), encoding="utf-8")
    return totals


def main(argv: list[str]) -> int:
    if len(argv) >= 3 and argv[1] == "corpus":
        print(json.dumps(corpus(Path(argv[2])), indent=1))
        return 0
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
        print(json.dumps(parse_many(build(page, ROOT, out, set(toks), paren_tokens(toks)), [(r["label"], toks)]), indent=1,
                         ensure_ascii=False))
        return 0
    print(__doc__)
    return 2


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
