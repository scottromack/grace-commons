#!/usr/bin/env python3
"""Fault Plants on Beacon's first pages (front page, sign in and out, dashboard, access denied): each plant changes one thing on the one line a tag names, the onboard test file runs, the plant is put back. A plant is seen
when a test fails. Run from the demo directory in a copy with node_modules and XTDB up:  python3 tests/case/plant_server.py [part of a plant's name]"""
import re, subprocess, sys

SV = "src/server.ts"
TEST = "tests/server.test.ts"
# (name, file, tag: a substring of the one line to change, find: the text in that line, replace)
PLANTS = [
    ("the front page not sending to sign-in", SV, 'app.get("/", (c) =>', '"/login"', '"/dashboard"'),
    ("a signed-in person shown the sign-in page", SV, 'app.get("/login", async (c) =>', 'c.redirect("/dashboard", 302)', "c.html(loginPage())"),
    ("the required message changed", SV, 'required: "Email and password are required."', "are required", "required"),
    ("the invalid message changed", SV, 'invalid: "Invalid email or password."', "Invalid email or password.", "Wrong"),
    ("an empty field admitted", SV, 'if (email.trim() === "" || password === "")', 'return c.html(loginPage(MSG.required), 400);', "{}"),
    ("a wrong password answered 200", SV, 'r.refused === "invalid-credential" ? MSG.invalid', 'r.refused === "invalid-credential" ? 401', 'r.refused === "invalid-credential" ? 200'),
    ("the cookie readable by scripts", SV, "setCookie(c, COOKIE, r.session_token", "httpOnly: true", "httpOnly: false"),
    ("the cookie's same-site changed", SV, "setCookie(c, COOKIE, r.session_token", 'sameSite: "Lax"', 'sameSite: "None"'),
    ("the cookie lasting a minute", SV, "setCookie(c, COOKIE, r.session_token", "maxAge: SESSION_SECONDS", "maxAge: 60"),
    ("the cookie on another path", SV, "setCookie(c, COOKIE, r.session_token", 'path: "/"', 'path: "/x"'),
    ("the cookie holding the email", SV, "setCookie(c, COOKIE, r.session_token", "COOKIE, r.session_token", "COOKIE, email"),
    ("the cookie always secure", SV, "setCookie(c, COOKIE, r.session_token", "secure: o.secureCookie ?? false", "secure: true"),
    ("a signed-in person sent to the front page", SV, '    return c.redirect("/dashboard", 302);', '"/dashboard"', '"/"'),
    ("a person without a session sent elsewhere", SV, 'return c.redirect("/login", 302); }', '"/login"', '"/"'),
    ("a dead cookie left in the browser", SV, "if (!me) { if (token) deleteCookie", 'if (token) deleteCookie(c, COOKIE, { path: "/" });', ""),
    ("a sign-out that does not sign out", SV, "if (token) await beacon.signOut(token);", "await beacon.signOut(token)", "0"),
    ("a sign-out that leaves the cookie", SV, '    deleteCookie(c, COOKIE, { path: "/" });', 'deleteCookie(c, COOKIE, { path: "/" });', ""),
    ("a sign-out returning to sign-in", SV, '    return c.redirect("/", 302);', '"/"', '"/login"'),
    ("a sign-out by post dropped", SV, 'app.post("/logout", logout);', 'app.post("/logout", logout);', ""),
    ("the welcome changed", SV, "Welcome, ${esc(person.display_name)}", "Welcome, ", "Hello, "),
    ("the people tile without grant_permission", SV, '"/people", label', '"invite_actor", "grant_permission"', '"invite_actor"'),
    ("the subjects tile without record_visit", SV, '"/subjects", label', '"enroll_subject", "record_visit"', '"enroll_subject"'),
    ("the audit tile without view_own_audit", SV, '"/audit", label', '"view_audit", "view_own_audit"', '"view_audit"'),
    ("one permission worded as one of several", SV, 'needs.length > 1 ? "one of these permissions"', 'needs.length > 1 ?', "true ?"),
    ("the way back left off the denied page", SV, '<p><a href="/dashboard">Back to the dashboard</a></p>', '<a href="/dashboard">Back to the dashboard</a>', ""),
    ("a denied page answering 200", SV, "c.html(deniedPage(needs, who), 403)", "403", "200"),
    ("a name written as markup", SV, 'export const esc =', '"<": "&lt;"', '"<": "<"'),
    ("only one demonstration account shown", SV, "${SEED.map((s) =>", "SEED.map(", "SEED.slice(0, 1).map("),
    ("a demonstration password hidden", SV, "password <code>${esc(s.password)}</code>", "${esc(s.password)}", "***"),
]

def fails(f):
    r = subprocess.run(["./node_modules/.bin/bun", "test", f, "--timeout", "30000", "--bail"], capture_output=True, text=True)
    out = r.stdout + r.stderr
    return len(re.findall(r"^\(fail\)", out, re.M)) + (1 if "error: " in out and "Ran " not in out else 0)   # --bail prints no count; a file that does not load prints no "Ran"

def fresh_stack():
    subprocess.run(["bash", "stack/stack.sh", "restart"], capture_output=True, text=True)

named = sys.argv[1] if len(sys.argv) > 1 else ""
seen = total = 0
for name, src, tag, find, repl in PLANTS:
    if named not in name: continue
    orig = open(src).read()
    lines = orig.split("\n")
    hit = [i for i, l in enumerate(lines) if re.search(re.escape(tag) + (r"(?!\d)" if tag[-1].isdigit() else ""), l)]
    if len(hit) != 1 or (find and find not in lines[hit[0]]):
        print("NOT APPLIED:", name, len(hit), flush=True); continue
    lines[hit[0]] = lines[hit[0]].replace(find, repl, 1) if find else lines[hit[0]]
    try:
        open(src, "w").write("\n".join(lines))
        if total % 8 == 0: fresh_stack()
        n = fails(TEST); total += 1; seen += n > 0
        print("%-62s %d fail" % (name, n), flush=True)
    finally:
        open(src, "w").write(orig)
print("%d of %d planted faults seen" % (seen, total))
