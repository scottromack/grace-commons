#!/usr/bin/env python3
"""Prototype: a page claims `[Action] step N` does something with `token`,
and that step does not name `token`.

This is gate 8's F1 exactly: the `journal_fence = none` degradation asserted
that "[Reconcile] step 2 surfaces any act whose re-read finds more than one
closing on `compliance_surface`", and step 2 carries no surfacing clause at
all. The weaker sibling (the step does not exist) is `step_ref_check.py`; this
one asks whether the step carries what it was said to carry.

Reported with the referring sentence, because — per the campaign's own lesson —
a finding being true does not make the rule right, and this rule is a heuristic
that must be read before it is trusted.

Usage: mechanism_check.py <file.md> [...]
"""
import re, sys, os

REF = re.compile(r"\[([A-Z][A-Za-z ]*)\]\s+step\s+(\d+)")
ACTION = re.compile(r"(?m)^#### `([a-z_]+)`")
STEP = re.compile(r"(?m)^(\d+)\. ")
TOKEN = re.compile(r"`([a-z_][a-z0-9_.]{3,})`")

def step_texts(text):
    """{action: {step number: that step's text}}."""
    out = {}
    heads = list(ACTION.finditer(text))
    for i, h in enumerate(heads):
        end = heads[i + 1].start() if i + 1 < len(heads) else len(text)
        sec = text[h.end():end]
        marks = list(STEP.finditer(sec))
        steps = {}
        for j, m in enumerate(marks):
            stop = marks[j + 1].start() if j + 1 < len(marks) else len(sec)
            steps[int(m.group(1))] = sec[m.start():stop]
        out[h.group(1)] = steps
    return out

def sentence_around(text, idx):
    start = max(text.rfind(". ", 0, idx), text.rfind("\n", 0, idx)) + 1
    end = text.find(". ", idx)
    return text[start: end if end > 0 else min(len(text), idx + 300)].strip()

def check(path):
    text = open(path).read()
    steps = step_texts(text)
    out = []
    for m in REF.finditer(text):
        name = m.group(1).strip().lower().replace(" ", "_")
        n = int(m.group(2))
        if name not in steps or n not in steps[name]:
            continue
        body = steps[name][n]
        sent = sentence_around(text, m.start())
        # the sentence must not itself be inside the target action's own steps
        for t in set(TOKEN.findall(sent)):
            if t in body:
                continue
            # only count tokens the page uses as machinery, not prose nouns
            if text.count(f"`{t}`") < 2:
                continue
            out.append((m.group(1), n, t, sent[:190]))
    return out

if __name__ == "__main__":
    total = 0
    for path in sys.argv[1:]:
        fs = check(path)
        if fs:
            print(f"{os.path.basename(path)}:")
            for name, n, t, sent in fs:
                print(f"    [{name}] step {n} is said to carry `{t}`, which that step does not name")
                print(f"        …{sent}…")
            total += len(fs)
    print(f"\n— {len(sys.argv)-1} file(s), {total} candidate(s).")
