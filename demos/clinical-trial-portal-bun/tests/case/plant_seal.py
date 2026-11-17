#!/usr/bin/env python3
"""Fault Plants on Credential, Session, Event Log, Tamper Evidence, Actor Identity, Retention Window, Party Identity and Audit Trail's Record Action: each plant changes one thing in one source file, that
file's own test file runs, the plant is put back. A plant is seen when a test fails. Run from the demo directory in a copy with node_modules
and XTDB up:  python3 tests/case/plant_atoms.py"""
import re, subprocess

PLANTS = [
    ("src/audit_trail.ts", "tests/audit_trail.seal.test.ts", [
        ("a seal of an empty slice attempted", 'if (events.length === 0) return { refused: "nothing-to-seal" };', ""),
        ("sealed through read as zero: every seal starts at one", "const sealed = await sealedThrough(this);", "const sealed = 0;"),
        ("the uncovered mark never set before the seal call", 'await store.commit([store.put(MARK, { _id: `mark:${this.log.logName}`, state: "set", holder })]);', ""),
        ("the unsealed tail read as lenient by default", '(cfgS.unsealedTailMode ?? "strict") === "strict"', "false"),
        ("a seal failure not prefixed seal-", "`seal-${t.failed}`", "t.failed"),
        ("an attestation failure not prefixed attestation-", "`attestation-${att.failed}`", "att.failed"),
        ("record set match always yes", "original.length === Number(/:(\\d+)$/.exec(ref)?.[1])", "true"),
        ("the sealing lock never taken", 'if (got === "unavailable") return { refused: "recording-failure" };', ""),
    ]),
]

def fails(f):
    r = subprocess.run(["./node_modules/.bin/bun", "test", f, "--timeout", "30000"], capture_output=True, text=True)
    m = re.search(r"\n\s*(\d+) fail", r.stdout + r.stderr)
    return int(m.group(1)) if m else 0

seen = total = 0
for src, test, plants in PLANTS:
    orig = open(src).read()
    try:
        for name, old, new in plants:
            if old not in orig:
                print("NOT APPLIED:", src, name); continue
            open(src, "w").write(orig.replace(old, new, 1))
            n = fails(test); total += 1; seen += n > 0
            print("%-12s %-46s %d fail" % (src.split("/")[-1][:12], name, n))
    finally:
        open(src, "w").write(orig)
print("%d of %d planted faults seen" % (seen, total))
