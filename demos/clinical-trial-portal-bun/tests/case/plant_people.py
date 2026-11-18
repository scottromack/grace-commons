#!/usr/bin/env python3
"""Fault Plants on Beacon's People & Permissions part and page (who may see and do what, giving and taking away, the history, the pending invitations): each plant changes one thing on the one line a tag names, the
test file that covers that file runs, the plant is put back. A plant is seen when a test fails. Run from the demo directory in a copy with node_modules and XTDB up:
python3 tests/case/plant_people.py [part of a plant's name]"""
import re, subprocess, sys

BA, SV = "src/beacon_admin.ts", "src/server.ts"
TB, TS = "tests/beacon.admin.test.ts", "tests/server.people.test.ts"
# (name, file, tag: a substring of the one line to change, find: the text in that line, replace, test file)
PLANTS = [
    ("the page open to a person with neither permission", BA, "if (!may_grant && !may_invite)", "!may_grant && !may_invite", "false", TB),
    ("the two rights swapped", BA, 'const may_grant = mine.includes("grant_permission")', 'may_grant = mine.includes("grant_permission"), may_invite = mine.includes("invite_actor")', 'may_grant = mine.includes("invite_actor"), may_invite = mine.includes("grant_permission")', TB),
    ("a held permission given again", BA, "if ((await this.p.domain.held(grantee_ref)).includes(code as PermissionCode)) return { already: true };", ".includes(code as PermissionCode)", '.includes("x" as PermissionCode)', TB),
    ("a held permission offered again", BA, "offered: PERMISSIONS.map", "!held.includes(c)", "true", TB),
    ("the history newest first", BA, ".sort((a, b) => (a.granted_at < b.granted_at", "? -1 : a.granted_at > b.granted_at ? 1", "? 1 : a.granted_at > b.granted_at ? -1", TB),
    ("the giver not shown", BA, 'const by = typeof a === "object"', "attestations.get(a.issuance_attestation_id)", "undefined", TB),
    ("a revoked grant shown held", BA, "held_now: g.status", '=== "active"', '=== "revoked"', TB),
    ("the revoke instant dropped", BA, "revoked_at: g.revoked_at", "revoked_at: g.revoked_at", "revoked_at: null", TB),
    ("a lapsed invitation still pending", BA, 'if (i.effective_status === "pending" &&', 'i.effective_status === "pending" && ', "true && ", TB),
    ("a grant with no event", BA, 'const wrote = await this.p.audits.write("grant.issued"', '"grant.issued"', '"grant.issue"', TB),
    ("a grant's event without the grantee", BA, 'const wrote = await this.p.audits.write("grant.issued"', "grantee: grantee_ref, ", "", TB),
    ("a grant attested by the grantee", BA, "const r = await this.p.admin.issueGrant(", "actor_ref, key)", "grantee_ref, key)", TB),
    ("a taking-away with no event", BA, "for (const id of r.revoked_grant_ids)", "r.revoked_grant_ids", "r.revoked_grant_ids.slice(0, 0)", TB),
    ("a taking-away's event named wrong", BA, 'const wrote = await this.p.audits.write("grant.revoked"', '"grant.revoked"', '"grant.revokd"', TB),
    ("a taking-away's reason dropped", BA, 'reason: "taken away from People & Permissions"', '"taken away from People & Permissions"', "1", TB),
    ("taking away what is not held made no refusal", BA, 'if ("refused" in r) return r.refused === "not-permitted"', '=== "not-permitted"', '=== "x"', TB),
    ("giving open to one who may not", BA, 'if (!(await this.p.domain.held(actor_ref)).includes("grant_permission"))', '!(await this.p.domain.held(actor_ref)).includes("grant_permission")', "false", TB),
    ("an unknown permission admitted", BA, "if (!isCode(code))", "!isCode(code)", "false", TB),
    ("an unknown person admitted", BA, "if (!(await this.p.people.byActor(grantee_ref)))", "!(await this.p.people.byActor(grantee_ref))", "false", TB),
    ("the page's refusal dropped", SV, 'if ("refused" in v) return refuse(c, v, person, "/dashboard");', 'refuse(c, v, person, "/dashboard")', 'c.html("")', TS),
    ("the marks shown to every person", SV, "const mark = (p: PersonRow", "v.may_grant ?", "true ?", TS),
    ("the choice to give shown to every person", SV, "const personRow = (p: PersonRow)", "v.may_grant && p.offered.length", "p.offered.length", TS),
    ("every permission not summed", SV, "const personRow = (p: PersonRow)", "p.held.length === PERMISSIONS.length", "false", TS),
    ("a person with nothing shown otherwise", SV, "const personRow = (p: PersonRow)", ': "none"}', ': "nothing"}', TS),
    ("the invite form shown to every person", SV, "const invite = v.may_invite ?", "v.may_invite ?", "true ?", TS),
    ("the revoke mark shown to every person", SV, "const pendRow = (i: PendingRow)", "v.may_invite ?", "true ?", TS),
    ("the invite link's words changed", SV, "Invite link — copy and share this with the invitee:", "Invite link — copy and share this with the invitee:", "Link:", TS),
    ("the invite link pointing elsewhere", SV, "return peoplePage(c, { link:", "/invitations/accept/", "/invite/", TS),
    ("giving and taking going to the page's other end", SV, "// give or take: back to the page", '"/people"', '"/dashboard"', TS),
    ("a revoke going elsewhere", SV, "// revoke: back to the page", '"/people"', '"/dashboard"', TS),
    ("giving done as taking", SV, 'const r = which === "give"', 'which === "give"', 'which === "take"', TS),
    ("the person read as the permission", SV, 'const who = typeof f.person === "string"', 'f.person : ""', 'f.permission : ""', TS),
    ("the permission not read", SV, 'const who = typeof f.person === "string"', 'f.permission : ""', '"" : ""', TS),
    ("the invitee's name read as the email", SV, "const r = await beacon.invite(c.get(\"token\")", 'f.display_name : ""', 'f.email : ""', TS),
    ("the role not read", SV, "const r = await beacon.invite(c.get(\"token\")", 'f.role : ""', '"" : ""', TS),
    ("a revoke of another invitation", SV, "const r = await beacon.revokeInvitation(", 'c.req.param("token")', '"x"', TS),
    ("a role written as markup", SV, "const pendRow = (i: PendingRow)", "${esc(i.role)}", "${i.role}", TS),
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
