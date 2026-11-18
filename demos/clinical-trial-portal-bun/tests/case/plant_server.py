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
    ("the way back left off the header", SV, "<body><header>${who ?", '<a href="/dashboard"><strong>Beacon Clinical Research</strong></a>', "<strong>Beacon Clinical Research</strong>"),
    ("the menu left off the signed-in screens", SV, "const html = (await res.text()).replace(MENU_HERE", "menuFor(me.holds, c.req.path)", '""'),
    ("the current menu entry not marked", SV, "path === t.href || path.startsWith", 'path === t.href || path.startsWith(`${t.href}/`) ? \' aria-current="page"\' : ""', '""'),
    ("the stylesheet not linked", SV, '<link rel="stylesheet" href="/app.css">', '<link rel="stylesheet" href="/app.css">', ""),
    ("a denied page answering 200", SV, "c.html(deniedPage(needs, who), 403)", "403", "200"),
    ("a name written as markup", SV, 'export const esc =', '"<": "&lt;"', '"<": "<"'),
    ("only one demonstration account shown", SV, "${SEED.map((s) =>", "SEED.map(", "SEED.slice(0, 1).map("),
    ("a demonstration password hidden", SV, "password <code>${esc(s.password)}</code>", "${esc(s.password)}", "***"),
    ("the subjects page refusal dropped", SV, 'if ("refused" in r) return refuse(c, r, person, "/dashboard");', 'return refuse(c, r, person, "/dashboard")', 'return c.html("")'),
    ("the first-subject words changed", SV, "Enroll the first subject.", "Enroll the first subject.", "Enroll one."),
    ("the first-subject link left off", SV, "Enroll the first subject.", '<a href="/subjects/new">Enroll the first subject.</a>', "Enroll the first subject."),
    ("enroll offered to one who may only record", SV, 'const enroll = may(holds, "enroll_subject");', '"enroll_subject"', '"enroll_subject", "record_visit"'),
    ("the next code editable", SV, '<input id="code" value=', " readonly>", ">"),
    ("the enroll form posting elsewhere", SV, 'form method="post" action="/subjects/new"', 'action="/subjects/new"', 'action="/subjects"'),
    ("enrolling goes to the list", SV, "return c.redirect(`/subjects/${r.subject_id}`, 302);", "/subjects/${r.subject_id}", "/subjects"),
    ("enrolling drops the notes", SV, "beacon.domain.enrollSubject(", 'typeof f.notes === "string" ? f.notes : null', "null"),
    ("enrolling without the person's key", SV, "beacon.domain.enrollSubject(", 'beacon.keyOf(c.get("token")) ?? ""', '""'),
    ("recording without the person's key", SV, "beacon.domain.recordVisit(", 'beacon.keyOf(c.get("token")) ?? ""', '""'),
    ("a visit's notes dropped", SV, "beacon.domain.recordVisit(", 'typeof f.notes === "string" ? f.notes : null', "null"),
    ("a visit's kind not read", SV, "beacon.domain.recordVisit(", 'typeof f.kind === "string" ? f.kind : ""', '""'),
    ("a refused visit answered 200", SV, "error ? 400 : 200", "error ? 400 : 200", "200"),
    ("the visit-type message dropped", SV, "r.message === MESSAGES.visitType ?", "subjectPage(c, id, MESSAGES.visitType)", "subjectPage(c, id)"),
    ("a recorded visit going to the list", SV, "return c.redirect(`/subjects/${id}`, 302);", "/subjects/${id}", "/subjects"),
    ("the no-visits words changed", SV, "<p>No visits recorded yet.</p>", "No visits recorded yet.", "None."),
    ("visits newest first", SV, "r.visits.map((v: VisitView)", "r.visits.map", "[...r.visits].reverse().map"),
    ("the visit form offered to everyone", SV, "const form = r.may_record ?", "r.may_record ?", "true ?"),
    ("only four kinds offered", SV, "VISIT_KINDS.map((k)", "VISIT_KINDS.map(", "VISIT_KINDS.slice(1).map("),
    ("the visit form posting elsewhere", SV, "action=\"/subjects/${esc(r.subject.subject_id)}/visits\"", "/visits", "/visit"),
    ("the enrolling person shown as a reference", SV, "const by = (await beacon.people.byActor", "display_name ??", "actor_ref ??"),
    ("a time shown as the raw instant", SV, "export const when =", '.replace("T", " ")', ""),
    ("a subject's notes written as markup in the list", SV, '<td>${esc(s.notes ?? "")}</td>', 'esc(s.notes ?? "")', 's.notes ?? ""'),
    ("a subject's notes written as markup on its page", SV, "Notes: ${esc(r.subject.notes)}", "${esc(r.subject.notes)}", "${r.subject.notes}"),
    ("a not-found subject answered 200", SV, 'c.html(page("Not Found"', "who), 404)", "who), 200)"),
    ("the not-found words changed", SV, 'notFound: "Not Found."', "Not Found.", "Missing."),
    ("a refused key answered 200", SV, 'case "invalid-credential": return c.html(', ", 401)", ", 200)"),
    ("the signed-out words changed", SV, 'signedOut: "Your sign-in has ended.', "has ended", "is fine"),
    ("the sign-in-again link dropped", SV, "<p><a href=\"/logout\">Sign in again</a></p>", '<a href="/logout">Sign in again</a>', ""),
    ("a lost key not noticed", SV, "if (!beacon.keyOf(token)) {", "!beacon.keyOf(token)", "false"),
    ("a lost key leaving the session standing", SV, "await beacon.signOut(token); deleteCookie(c, COOKIE", "await beacon.signOut(token); ", ""),
    ("a lost key leaving the cookie", SV, "await beacon.signOut(token); deleteCookie(c, COOKIE", 'deleteCookie(c, COOKIE, { path: "/" }); ', ""),
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
