#!/usr/bin/env python3
"""Fault Plants on Beacon's invitations (inviting, revoking, what a link shows, accepting, and the accept page): each plant changes one thing on the one line a tag names, the
test file that covers that file runs, the plant is put back. A plant is seen when a test fails. Run from the demo directory in a copy with node_modules and XTDB up:
python3 tests/case/plant_invitations.py [part of a plant's name]"""
import re, subprocess, sys

BC, SV = "src/beacon.ts", "src/server.ts"
TB, TS = "tests/beacon.invitations.test.ts", "tests/server.invitations.test.ts"
# (name, file, tag: a substring of the one line to change, find: the text in that line, replace, test file)
PLANTS = [
    ("inviting without invite_actor", BC, "// who may invite", '!me.holds.includes("invite_actor")', "false", TB),
    ("revoking without invite_actor", BC, "// who may revoke", '!me.holds.includes("invite_actor")', "false", TB),
    ("inviting with no key held", BC, "// inviting: a session with no key", "!me || !key", "!me", TB),
    ("revoking with no key held", BC, "// revoking: a session with no key", "!me || !key", "!me", TB),
    ("the invitee's email not normalized", BC, "const invitee = normalEmail(email);", "normalEmail(email)", "email", TB),
    ("an email that has an account invited", BC, "if (await this.people.byEmail(invitee)) return", "await this.people.byEmail(invitee)", "null", TB),
    ("a blank role admitted", BC, "if (isBlank(email) || isBlank(display_name) || isBlank(role))", " || isBlank(role)", "", TB),
    ("a blank name admitted", BC, "if (isBlank(email) || isBlank(display_name) || isBlank(role))", " || isBlank(display_name)", "", TB),
    ("a blank email admitted", BC, "if (isBlank(email) || isBlank(display_name) || isBlank(role))", "isBlank(email) || ", "", TB),
    ("an invitation lasting a day", BC, "const r = await this.onboarding.invite(me.person.actor_ref", "WEEK_S, key)", "86_400, key)", TB),
    ("an invitation signed with no key", BC, "const r = await this.onboarding.invite(me.person.actor_ref", "WEEK_S, key)", 'WEEK_S, "")', TB),
    ("the role left out of the context", BC, "const r = await this.onboarding.invite(me.person.actor_ref", "invitationContext(role.trim(), display_name.trim())", 'invitationContext("", display_name.trim())', TB),
    ("a revocation signed with no key", BC, "const r = await this.onboarding.revoke(", '"revoked by the inviter", key)', '"revoked by the inviter", "")', TB),
    ("a revoked unknown link answered as used", BC, 'if (r.refused === "invitation-invalid") return r.cause === "not-known"', 'r.cause === "not-known"', "false", TB),
    ("an expired link shown as used", BC, 'if (i.effective_status === "expired") return { invalid: "expired" };', '"expired" }', '"resolved" }', TB),
    ("a used link still shown", BC, 'if (i.effective_status !== "pending") return', '!== "pending"', '=== "revoked"', TB),
    ("an unknown link shown as used", BC, "if (!i) return { invalid: \"unknown\" };", '"unknown"', '"resolved"', TB),
    ("a link with no invitee shown", BC, "if (!c || isBlank(i.invitee_ref))", " || isBlank(i.invitee_ref)", "", TB),
    ("the link's role left out", BC, "return { email: i.invitee_ref as string, role: c.role", "role: c.role", 'role: ""', TB),
    ("the link's name left out", BC, "return { email: i.invitee_ref as string, role: c.role", "display_name: c.display_name", 'display_name: ""', TB),
    ("a short password admitted", BC, "[...password].length < MIN_PASSWORD", "< MIN_PASSWORD", "< 1", TB),
    ("the confirmation not compared", BC, "if (password !== confirmation)", "password !== confirmation", "false", TB),
    ("an account made twice for one email", BC, "if (await this.people.byEmail(i.email)) return { refused", "await this.people.byEmail(i.email)", "null", TB),
    ("the party named by something else", BC, "const p = partyFor(i.display_name, i.email);", "i.display_name", "i.email", TB),
    ("the person named by the email", BC, "party_id: r.party_id, email: i.email", "display_name: i.display_name", "display_name: i.email", TB),
    ("a person made under another party", BC, "party_id: r.party_id, email: i.email", "party_id: r.party_id", 'party_id: crypto.randomUUID()', TB),
    ("the person not signed in", BC, "const s = await this.signIn(i.email, password);", "this.signIn(i.email, password)", 'Promise.resolve({ refused: "storage-failure" as const })', TB),
    ("onboarding the wrong password", BC, "const r = await this.onboarding.onboard(", '"password", password, undefined', '"password", "x" + password, undefined', TB),
    ("an unknown link answered with a form", SV, "why === \"unknown\" ? 404 : 410", "404", "200", TS),
    ("a used link answered with a form status", SV, "why === \"unknown\" ? 404 : 410", "410", "200", TS),
    ("a link's words swapped", SV, "<p class=\"error\" role=\"alert\">${esc(INVITATION_WORDS[why])}", "INVITATION_WORDS[why]", "INVITATION_WORDS.unknown", TS),
    ("the invited email editable", SV, '<input id="email" value="${esc(i.email)}" readonly>', " readonly>", ">", TS),
    ("the role not shown", SV, 'id="role" value=', "${esc(i.role)}", "", TS),
    ("the password shown as typed", SV, 'autocomplete="new-password" minlength', 'type="password"', 'type="text"', TS),
    ("the confirmation shown as typed", SV, 'id="confirm" name="confirm" type="password"', 'type="password"', 'type="text"', TS),
    ("the form posting elsewhere", SV, "<form method=\"post\" action=\"/invitations/accept/", "/invitations/accept/", "/invitations/", TS),
    ("the cookie dropped on accept", SV, "// accepting signs the person in", "setCookie(c, COOKIE, r.session_token", "0 && setCookie(c, COOKIE, r.session_token", TS),
    ("the cookie readable by scripts on accept", SV, "// accepting signs the person in", "httpOnly: true", "httpOnly: false", TS),
    ("accepting sent to the front page", SV, "// and sends the person to the dashboard", '"/dashboard"', '"/"', TS),
    ("a refused form answered 200", SV, "acceptForm(token, i, say), r.refused", "400", "200", TS),
    ("a refused form's words dropped", SV, "const say = r.refused", '(r.message ?? "That was not accepted.")', '"That was not accepted."', TS),
    ("a spent link on post answered with a redirect", SV, 'if ("invalid" in r) return badLink(c, r.invalid);', "return badLink(c, r.invalid)", 'return c.redirect("/dashboard", 302)', TS),
    ("the password not read from the form", SV, 'beacon.acceptInvitation(token, typeof f.password', 'f.password : ""', 'f.password : "xxxxxxxx"', TS),
    ("the confirmation read as the password", SV, 'typeof f.confirm === "string" ? f.confirm : ""', 'f.confirm : ""', 'f.password : ""', TS),
    ("the role written as markup", SV, 'id="role" value=', "${esc(i.role)}", "${i.role}", TS),
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
