#!/usr/bin/env python3
"""Triage prototype: a code an action's SIGNATURE declares that the action's own
prose never lands — the inverse of `E-code-not-in-signature`, which was rejected
because it could not tell an own export from a transcribed constituent code.

This direction has no such problem. The signature block is a delimited code
fence; the prose is the text between that block and the next action heading.
"Does this token occur in that text" is a question about what the section
CONTAINS, with no reading of what any sentence claims. If a declared arm is
never mentioned again, either an implementer must invent when to return it or
the declaration is dead — and both are defects a generator gets burned by.

Gate 9's R1 is one instance: [Resolve] exports `invalid-credential` and its
prose never mentions it.

SELF-TEST FIRST, in both directions, and against a deliberately broken variant.
The sweep's output is evidence only if the self-test passes.

Usage: undeclared_landing_check.py --self-test
       undeclared_landing_check.py <file.md> [...]
"""
import re, sys, os

ACTION = re.compile(r"(?m)^#### `([a-z_]+)`\s*$")
FENCE = re.compile(r"```\n(.*?)\n```", re.S)


def balanced(blob, start):
    depth = 0
    for i in range(start, len(blob)):
        if blob[i] == "(":
            depth += 1
        elif blob[i] == ")":
            depth -= 1
            if depth == 0:
                return blob[start + 1:i], i
    return None, len(blob)


def declared_codes(sig):
    """Heads of the top-level alternatives inside each `rejected( ... )`."""
    out = []
    i = 0
    while True:
        j = sig.find("rejected(", i)
        if j < 0:
            break
        inner, end = balanced(sig, j + len("rejected"))
        i = end + 1
        if inner is None:
            continue
        depth, alt, alts = 0, "", []
        for ch in inner:
            if ch == "(":
                depth += 1
            elif ch == ")":
                depth -= 1
            if ch == "|" and depth == 0:
                alts.append(alt)
                alt = ""
            else:
                alt += ch
        alts.append(alt)
        for a in alts:
            head = re.split(r"[\s(]", a.strip())[0].strip("`*_,.[]")
            if head and not head.startswith("<"):
                out.append(head)
    return out


def sections(text):
    """(name, signature block, the prose of that action's own section)."""
    heads = list(ACTION.finditer(text))
    for k, h in enumerate(heads):
        end = heads[k + 1].start() if k + 1 < len(heads) else len(text)
        body = text[h.end():end]
        # an action section also ends at the next top-level heading
        body = re.split(r"\n## ", body)[0]
        m = FENCE.search(body)
        if not m:
            continue
        yield h.group(1), m.group(1), body[m.end():]


def check(path, prose_only=True):
    findings = []
    text = open(path).read()
    for name, sig, prose in sections(text):
        hay = prose if prose_only else text
        for code in declared_codes(sig):
            if code not in hay:
                findings.append((name, code))
    return findings


# ---- self-test ------------------------------------------------------------
GOOD = """## L

#### `alpha`

```
alpha(x) →
    ok
  | rejected(not-open | recording-failure(intent))
```

Does the thing. A caller that did not open gets `not-open`; a write that did
not land gets `recording-failure(intent)`.

#### `beta`

```
beta(y) → ok | rejected(section-unavailable)
```

A failed take is `section-unavailable`.
"""
BAD = GOOD.replace(
    "A caller that did not open gets `not-open`; a write that did\nnot land gets `recording-failure(intent)`.",
    "A write that did not land gets `recording-failure(intent)`.")
BAD2 = GOOD.replace("A failed take is `section-unavailable`.",
                    "A failed take is refused.")
# the trap the first prototype fell into: a code landed only in a SHARED
# paragraph outside the action's own section must still count as undeclared,
# because an implementer building that action from its section cannot see it.
ELSEWHERE = GOOD.replace(
    "A caller that did not open gets `not-open`; a write that did\nnot land gets `recording-failure(intent)`.",
    "A write that did not land gets `recording-failure(intent)`.") + \
    "\n## Elsewhere\n\nSome other section mentions `not-open` in passing.\n"


def self_test():
    import tempfile
    cases = [("known good (every declared code landed)", GOOD, 0),
             ("one declared code never landed", BAD, 1),
             ("a second action's only code never landed", BAD2, 1),
             ("landed only in a shared section, not the action's", ELSEWHERE, 1)]
    ok = True
    for label, text, want in cases:
        with tempfile.NamedTemporaryFile("w", suffix=".md", delete=False) as f:
            f.write(text)
            p = f.name
        got = len(check(p))
        os.unlink(p)
        v = "PASS" if got == want else "FAIL"
        if got != want:
            ok = False
        print(f"  {v}  {label}: expected {want}, got {got}")
    # broken-check verification: a variant that searches the WHOLE page must
    # fail the fourth case, or that case is pinning nothing.
    with tempfile.NamedTemporaryFile("w", suffix=".md", delete=False) as f:
        f.write(ELSEWHERE)
        p = f.name
    broken = len(check(p, prose_only=False))
    os.unlink(p)
    v = "PASS" if broken == 0 else "FAIL"
    if broken != 0:
        ok = False
    print(f"  {v}  broken variant (whole-page search) misses case 4 as expected: "
          f"got {broken}, want 0")
    return ok


if __name__ == "__main__":
    if "--self-test" in sys.argv:
        print("self-test:")
        sys.exit(0 if self_test() else 1)
    total = 0
    for path in sys.argv[1:]:
        fs = check(path)
        if fs:
            print(f"{os.path.basename(path)}:")
            for name, code in fs:
                print(f"    `{name}` declares `rejected({code})` and its own "
                      f"prose never mentions it")
            total += len(fs)
    print(f"\n— {len(sys.argv)-1} file(s), {total} finding(s).")
