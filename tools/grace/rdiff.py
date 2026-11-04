#!/usr/bin/env python3
"""The reverse diff (GRACE-lang section 17): what a change did to the rules.

It compares two commits' normalized rules, not their text (Reverse diff 1) and
reports each rule ADDED, REMOVED or CHANGED (Reverse diff 2). A rule is the
label's form, so two forms that normalize identically are equivalent (Reverse
diff 3): `AFTER` against `ONLY AFTER`, `×` against `*`, a reworded WHY: or UX:
or NOTE: beside it, a rule that moved to another label with its form unchanged.
Equivalence is assumed from nothing else (Reverse diff 4), so a rule the
normalizer cannot lower (normalize.py, `N-unlowered`) is compared by its text
as written. A change to WHY: or UX: is not reported (Reverse diff 5): those
lines are never rules and never reach the normalized form.

    python3 tools/grace/rdiff.py HEAD~1                 # every spec a change since HEAD~1 touched, against the working tree
    python3 tools/grace/rdiff.py HEAD~3 HEAD~1          # between two commits
    python3 tools/grace/rdiff.py HEAD~1 --spec atoms/cart.md

One line per rule, `RESULT path: label: rule`, a CHANGED one with both forms;
the summary goes to stderr. Exit 1 when any obligation differs, 0 when none does,
as `git diff --exit-code` does. Standard library only.
"""
from __future__ import annotations

import subprocess
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
sys.path.insert(0, str(HERE.parent / "linter"))
import ir  # noqa: E402
import normalize  # noqa: E402

CATALOGUES = ("readme.md", "index.md", "taxonomy.md")


def forms_of(text: str, name: str = "spec.md") -> dict[str, dict]:
    """The normalized form of each rule of a spec's text, by label."""
    with tempfile.TemporaryDirectory() as tmp:
        path = Path(tmp) / name
        path.write_text(text, encoding="utf-8")
        return ir.parse(path, Path(tmp))["normalized"]["rules"]


def comparable(form: dict) -> dict:
    """What a form says of its own rule: a WHEN block's list of children is
    each child's to report, and a child's block is its condition, not the
    block's label."""
    out = {k: v for k, v in form.items() if k != "children"}
    if "when" in out:
        out["when"] = out["when"]["condition"]
    return out


def diff(old: dict[str, dict], new: dict[str, dict]) -> list[tuple[str, str, dict | None, dict | None]]:
    """(result, label, old form, new form) for each rule that differs. A rule
    removed under one label and added under another with the same form is the
    same obligation, and neither is reported."""
    removed = {lab: f for lab, f in old.items() if lab not in new}
    added = {lab: f for lab, f in new.items() if lab not in old}
    for lab in sorted(removed):
        twin = next((a for a in sorted(added) if comparable(added[a]) == comparable(removed[lab])), None)
        if twin:
            del added[twin], removed[lab]
    out = [("REMOVED", lab, f, None) for lab, f in removed.items()]
    out += [("ADDED", lab, None, f) for lab, f in added.items()]
    out += [("CHANGED", lab, old[lab], new[lab]) for lab in old
            if lab in new and comparable(old[lab]) != comparable(new[lab])]
    return sorted(out, key=lambda r: (r[1], r[0]))


def show(root: Path, rev: str | None, path: str) -> str | None:
    """A spec's text at a commit, or in the working tree when `rev` is None;
    None when the spec is not there."""
    if rev is None:
        p = root / path
        return p.read_text(encoding="utf-8") if p.is_file() else None
    r = subprocess.run(["git", "show", f"{rev}:{path}"], cwd=root, capture_output=True, text=True)
    return r.stdout if r.returncode == 0 else None


def touched(root: Path, base: str, head: str | None) -> list[str]:
    """The specs a change between two commits touched."""
    cmd = ["git", "diff", "--name-only", base] + ([head] if head else []) + ["--", "atoms", "compositions"]
    r = subprocess.run(cmd, cwd=root, capture_output=True, text=True, check=True)
    return sorted(p for p in r.stdout.split() if p.endswith(".md") and not p.endswith(".hist.md")
                  and Path(p).name.lower() not in CATALOGUES)


def main(argv: list[str]) -> int:
    root = HERE.parents[1]
    args, specs = [], []
    it = iter(argv[1:])
    for a in it:
        if a == "--spec":
            specs.append(next(it, ""))
        else:
            args.append(a)
    if not 1 <= len(args) <= 2:
        print(__doc__, file=sys.stderr)
        return 2
    base, head = args[0], (args[1] if len(args) > 1 else None)
    differing = 0
    counts = {"ADDED": 0, "REMOVED": 0, "CHANGED": 0}
    for path in specs or touched(root, base, head):
        before, after = show(root, base, path), show(root, head, path)
        old = forms_of(before, Path(path).name) if before is not None else {}
        new = forms_of(after, Path(path).name) if after is not None else {}
        for result, label, was, now in diff(old, new):
            counts[result] += 1
            differing += 1
            if result == "CHANGED":
                print(f"CHANGED {path}: {label}: was {normalize.render(was)} now {normalize.render(now)}")
            else:
                print(f"{result} {path}: {label}: {normalize.render(was or now)}")
    print(f"rdiff: {counts['ADDED']} ADDED, {counts['REMOVED']} REMOVED, {counts['CHANGED']} CHANGED", file=sys.stderr)
    return 1 if differing else 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
