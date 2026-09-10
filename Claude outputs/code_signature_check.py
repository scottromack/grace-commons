#!/usr/bin/env python3
"""Prototype linter check: every rejection code an action's PROSE lands must
appear in that action's SIGNATURE block.

Gate 7's R6 and gate 8's F5 are the same defect: a fix round added a code or a
parameter to an action's prose and did not carry it into the signature a
generator actually builds from. That is mechanical, so it should be a check and
not a resolution. Report-only; not wired into the linter.

Usage: code_signature_check.py <file.md> [<file.md> ...]
"""
import re, sys, os

# codes that name a constituent's arm being transcribed, not this action's export
NOISE = {"step", "step-2", "step-3", "step-4", "steps"}

def actions(text):
    """Yield (name, signature_block, prose) per `#### `name`` action section."""
    parts = re.split(r'\n#### ', text)
    for part in parts[1:]:
        name = part.split('\n', 1)[0].strip().strip('`')
        m = re.search(r'```\n(.*?)\n```', part, re.S)
        if not m:
            continue
        sig = m.group(1)
        prose = part[m.end():]
        # stop at the next top-level section
        prose = re.split(r'\n## ', prose)[0]
        yield name, sig, prose

def balanced(blob, start):
    """Text inside the parens opening at `start`, matched to its own close."""
    depth = 0
    for i in range(start, len(blob)):
        if blob[i] == '(':
            depth += 1
        elif blob[i] == ')':
            depth -= 1
            if depth == 0:
                return blob[start + 1:i], i
    return None, len(blob)

def codes(blob):
    """Rejection codes named in a blob: the head of each rejected(...) item.
    The parens must be matched, not regex-guessed: a signature block carries
    several nested groups across several lines, and a lazy match silently
    truncates the list — which made the first version of this check report
    three quarters false positives."""
    out = set()
    i = 0
    while True:
        j = blob.find('rejected(', i)
        if j < 0:
            break
        inner, end = balanced(blob, j + len('rejected'))
        i = end + 1
        if inner is None:
            continue
        # split on | at depth 0 only
        depth = 0; alt = ''; alts = []
        for ch in inner:
            if ch == '(':
                depth += 1
            elif ch == ')':
                depth -= 1
            if ch == '|' and depth == 0:
                alts.append(alt); alt = ''
            else:
                alt += ch
        alts.append(alt)
        for a in alts:
            head = re.split(r'[\s(]', a.strip())[0].strip('`*_,.[]')
            if head and head not in NOISE and not head.startswith('<'):
                out.add(head)
    return out

def check(path):
    text = open(path).read()
    findings = []
    for name, sig, prose in actions(text):
        declared = codes(sig)
        if not declared:
            continue
        landed = codes(prose)
        for c in sorted(landed - declared):
            findings.append((name, c))
    return findings

total = 0
for path in sys.argv[1:]:
    fs = check(path)
    if fs:
        print(f"{os.path.basename(path)}:")
        for name, c in fs:
            print(f"    [E-code-not-in-signature] `{name}` lands `rejected({c})` "
                  f"but its signature does not declare it")
        total += len(fs)
print(f"\n— {len(sys.argv)-1} file(s), {total} finding(s).")
