#!/usr/bin/env python3
"""Fault Plants on Beacon's chain verification and export (the sealing, what is checked, how a failure shows, the file and its cells): each plant changes one thing on the one line a tag names, the
test file that covers that file runs, the plant is put back. A plant is seen when a test fails. Run from the demo directory in a copy with node_modules and XTDB up:
python3 tests/case/plant_audit_verify.py [part of a plant's name]"""
import re, subprocess, sys

BA, SV = "src/beacon_audit.ts", "src/server.ts"
TB, TS = "tests/beacon.audit.verify.test.ts", "tests/server.audit.verify.test.ts"
# (name, file, tag: a substring of the one line to change, find: the text in that line, replace, test file)
PLANTS = [
    ("the sealing not run", BA, "const r = await this.audit.sealNow();", "await this.audit.sealNow()", '{ refused: "nothing-to-seal" } as const', TB),
    ("the sealing never done", BA, 'if (r.refused === "nothing-to-seal") break;', '=== "nothing-to-seal"', '=== "x"', TB),
    ("verifying whose events not narrowed", BA, "const { mine } = await this.visible(actor_ref, scope);", "actor_ref, scope)", 'actor_ref, "all")', TB),
    ("a slice checked against nothing", BA, "const v = await this.audit.verifyRecord(", "slices.get(key)", "[]", TB),
    ("the checked count doubled", BA, "if (outcome === \"verified\") { checked++; continue; }", "checked++", "checked += 2", TB),
    ("the failure's reason hidden", BA, "return { intact: false, checked, event: { number: e.sequence_number, event_id: e.event_id, action: d.action_ref }, reason };", ", reason }", ', reason: "unknown" }', TB),
    ("verifying open to a person with neither", BA, "// verifying: who may", "!scope", "false", TB),
    ("exporting open to a person with neither", BA, "// exporting: who may", "!scope", "false", TB),
    ("the export newest first", BA, "lines.push([String(e.sequence_number)", "lines.push(", "lines.splice(1, 0, ", TB),
    ("the export's token shown", BA, "lines.push([String(e.sequence_number)", "withhold(rest)", "rest", TB),
    ("a column dropped", BA, 'const lines: string[][] = [["number"', '"attestation id", ', "", TB),
    ("a sealed event shown unsealed", BA, 'const sealed = rec !== "not-known"', ': "unsealed"', ': "sealed"', TB),
    ("the export not an event", BA, 'const wrote = await this.write("beacon.audit_exported"', '"beacon.audit_exported"', '"beacon.audit_exportd"', TB),
    ("the export's count wrong", BA, 'row_count: mine.length, scope', "row_count: mine.length", "row_count: 0", TB),
    ("the export's scope dropped", BA, 'row_count: mine.length, scope', "row_count: mine.length, scope", "row_count: mine.length", TB),
    ("the file named for the month", BA, "filename: `beacon-audit-", ".slice(0, 10)", ".slice(0, 7)", TB),
    ("the lines ended with a newline", BA, "return { filename:", '"\\r\\n")', '"\\n")', TB),
    ("a formula cell written live (=)", BA, "const t = /^[=+", "[=+", "[+", TB),
    ("a formula cell written live (@)", BA, "const t = /^[=+", "@\\t", "\\t", TB),
    ("a comma not quoted", BA, 'return /[",\\r\\n]/.test(t)', '[",', '["', TB),
    ("a quote not doubled", BA, "replaceAll('\"', '\"\"')", "'\"\"'", "'\"'", TB),
    ("the intact words changed", SV, "<strong>Chain intact.</strong>", "Chain intact.", "Intact.", TS),
    ("the tampering words changed", SV, "<strong>Tampering detected.</strong>", "Tampering detected.", "Problem.", TS),
    ("the reason left off", SV, "esc(\"reason\" in r ? r.reason", 'r.reason : ""', '"" : ""', TS),
    ("the file not a CSV", SV, '"content-type": "text/csv; charset=utf-8"', "text/csv; charset=utf-8", "text/plain", TS),
    ("the file not a download", SV, "content-disposition", "attachment;", "inline;", TS),
    ("the file's name changed", SV, "content-disposition", "filename=", "name=", TS),
    ("the verify refusal dropped", SV, "// verifying: a refusal", 'refuse(c, r, person, "/audit")', 'c.html("")', TS),
    ("the export refusal dropped", SV, "// exporting: a refusal", 'refuse(c, r, person, "/audit")', 'c.html("")', TS),
    ("the verify link left off", SV, '<p><a href="/audit/verify">Verify chain</a>', "Verify chain", "Verify", TS),
    ("the export link left off", SV, '<p><a href="/audit/verify">Verify chain</a>', "Export CSV", "Export", TS),
]

def fails(f):
    r = subprocess.run(["./node_modules/.bin/bun", "test", f, "--timeout", "30000", "--bail"], capture_output=True, text=True)
    out = r.stdout + r.stderr
    return len(re.findall(r"^\(fail\)", out, re.M)) + (1 if "error: " in out and "Ran " not in out else 0)   # --bail prints no count; a file that does not load prints no "Ran"

def fresh_stack():
    subprocess.run(["bash", "stack/stack.sh", "restart"], capture_output=True, text=True)

named = sys.argv[1] if len(sys.argv) > 1 else ""
seen = total = 0
for name, src, tag, find, repl, test in PLANTS:
    if named not in name: continue
    orig = open(src).read()
    lines = orig.split("\n")
    hit = [i for i, l in enumerate(lines) if tag in l]
    if len(hit) != 1 or (find and find not in lines[hit[0]]):
        print("NOT APPLIED:", name, len(hit), flush=True); continue
    lines[hit[0]] = lines[hit[0]].replace(find, repl, 1) if find else lines[hit[0]]
    try:
        open(src, "w").write("\n".join(lines))
        if total % 8 == 0: fresh_stack()
        n = fails(test); total += 1; seen += n > 0
        print("%-62s %d fail" % (name, n), flush=True)
    finally:
        open(src, "w").write(orig)
print("%d of %d planted faults seen" % (seen, total))
