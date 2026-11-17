#!/usr/bin/env python3
"""Fault Plants on Beacon's Audit Trail page and its own part (who sees how much, the filters, the retention switch, the events it writes, the token it withholds): each plant changes one thing on the one line a tag names, the
test file that covers that file runs, the plant is put back. A plant is seen when a test fails. Run from the demo directory in a copy with node_modules and XTDB up:
python3 tests/case/plant_audit.py [part of a plant's name]"""
import re, subprocess, sys

BA, SV = "src/beacon_audit.ts", "src/server.ts"
TB, TS = "tests/beacon.audit.test.ts", "tests/server.audit.test.ts"
# (name, file, tag: a substring of the one line to change, find: the text in that line, replace, test file)
PLANTS = [
    ("the all and own scopes swapped", BA, 'held.includes("view_audit") ? "all"', '"all" : held', '"own" : held', TB),
    ("every person who holds nothing given own scope", BA, 'held.includes("view_own_audit") ? "own" : null', '"own" : null', '"own" : "own"', TB),
    ("own scope seeing everyone's events", BA, '(scope === "all" || (e.data as', 'scope === "all" || ', 'true || ', TB),
    ("the retention window twice as long", BA, "const floor = on ?", "RETENTION_DAYS * DAY", "RETENTION_DAYS * DAY * 2", TB),
    ("the retention window ignored", BA, "const floor = on ?", "on ? new Date(", "false ? new Date(", TB),
    ("the retention window starting on", BA, 'return s?.enabled === "true";', '=== "true"', '!== "false"', TB),
    ("the events oldest first", BA, ".sort((a, b) => b.number - a.number)", "b.number - a.number", "a.number - b.number", TB),
    ("the from date ignored", BA, "dayStart(f.from))", "!f.from || e.recorded_at >= dayStart(f.from)", "true", TB),
    ("the to day cut at its start", BA, "dayEnd(f.to)", "dayEnd(f.to)", "dayStart(f.to)", TB),
    ("the action filter ignored", BA, "(!f.action || d.action_ref === f.action)", "!f.action || d.action_ref === f.action", "true", TB),
    ("the opening not an event", BA, 'const wrote = await this.write("beacon.audit_viewed"', '"beacon.audit_viewed"', '"beacon.audit_viewd"', TB),
    ("the opening's count wrong", BA, "scope, result_count: rows.length", "result_count: rows.length", "result_count: rows.length + 1", TB),
    ("the opening's scope dropped", BA, "scope, result_count: rows.length", "scope, result_count", "result_count", TB),
    ("a bad to date admitted", BA, "if ((f.from && !isDay(f.from))", "(f.to && !isDay(f.to))", "false", TB),
    ("a bad from date admitted", BA, "if ((f.from && !isDay(f.from))", "(f.from && !isDay(f.from))", "false", TB),
    ("a from after a to admitted", BA, "if (f.from && f.to && f.from > f.to)", "f.from > f.to", "f.from < f.to", TB),
    ("the switch open to any who view", BA, '!(await this.domain.held(actor_ref)).includes("view_audit")', '!(await this.domain.held(actor_ref)).includes("view_audit")', "false", TB),
    ("the switch's event stating on always", BA, 'retention: on ? "on" : "off"', 'on ? "on" : "off"', '"on"', TB),
    ("the switch's change not kept", BA, "enabled: String(on)", "String(on)", '"true"', TB),
    ("the switch's days wrong", BA, "days: RETENTION_DAYS", "RETENTION_DAYS", "1", TB),
    ("the token shown", BA, "JSON.stringify(withhold(rest))", "withhold(rest)", "rest", TB),
    ("the token shown where nested", BA, 'k === "session_token" ? WITHHELD : withhold(x)', ": withhold(x)", ": x", TB),
    ("the target dropped", BA, 'target: typeof target === "string" ? target : ""', 'typeof target === "string" ? target : ""', '""', TB),
    ("a person shown by id", BA, "return (ref) => names.get(ref)", "names.get(ref) ?? ", "", TB),
    ("the service shown by id", BA, "return (ref) => names.get(ref)", " ?? this.serviceName(ref)", "", TB),
    ("the audit page's refusal dropped", SV, ': refuse(c, r, person, "/dashboard");', 'refuse(c, r, person, "/dashboard")', 'c.html("")', TS),
    ("a bad date answered 200", SV, '<a href="/audit">Back to the audit trail</a>', ", 400)", ", 200)", TS),
    ("the target column dropped", SV, "<th>#</th><th>Time</th>", "<th>Target</th>", "", TS),
    ("the scope words swapped", SV, '"Everyone\'s events." : "Your own events."', '"Everyone\'s events." : "Your own events."', '"Your own events." : "Everyone\'s events."', TS),
    ("the chosen action not marked", SV, 'a === r.filters.action ? " selected"', '" selected"', '""', TS),
    ("the off words changed", SV, "off, every event is shown", "off, every event is shown", "off", TS),
    ("the switch always offering on", SV, '<input type="hidden" name="on" value=', 'r.retention_on ? "false" : "true"', '"true"', TS),
    ("the switch going elsewhere", SV, 'return c.redirect("/audit", 302);', '"/audit"', '"/dashboard"', TS),
    ("the from date read as the to", SV, 'from: q("from")', 'from: q("from")', 'from: q("to")', TS),
    ("the payload written as markup", SV, "<td><code>${esc(e.payload)}</code></td>", "esc(e.payload)", "e.payload", TS),
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
