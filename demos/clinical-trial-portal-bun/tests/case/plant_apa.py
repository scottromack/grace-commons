#!/usr/bin/env python3
"""Fault Plants on Attributed Permissions Admin and the hooks it added to Permissions and the seam: each plant changes one thing on the one line a tag names, the onboard test file runs, the plant is put back. A plant is seen
when a test fails. Run from the demo directory in a copy with node_modules and XTDB up:  python3 tests/case/plant_apa.py [part of a plant's name]"""
import re, subprocess, sys

AP = "src/attributed_permissions_admin.ts"
TEST = "tests/attributed_permissions_admin.test.ts"
# (name, file, tag: a substring of the one line to change, find: the text in that line, replace)
PLANTS = [
    ("a blank administered input admitted", AP, 'if (opaque.some((v) => typeof v !== "string" || isBlank(v))) return null;', "return null;", "{}"),
    ("a blank credential admitted", AP, 'if (typeof credential !== "string" || isBlank(credential)) return null;', "return null;", "{}"),
    ("the length cap not applied", AP, "[...v].length > this.cap", "> this.cap", "> 1e9"),
    ("the length cap's boundary refused", AP, "[...v].length > this.cap", "> this.cap", ">= this.cap"),
    ("an administered input not trimmed", AP, "const t = opaque.map(trim);", "opaque.map(trim)", "opaque"),
    ("an administered input's case folded", AP, "const t = opaque.map(trim);", ".map(trim)", ".map((v) => trim(v).toLowerCase())"),
    ("the pair not read first", AP, "const inForce = await this.held(subject, scope);", "await this.held(subject, scope)", "undefined"),
    ("a held pair attested anyway", AP, "if (inForce) return { grant_id: inForce.grant_id };", "return { grant_id: inForce.grant_id };", "{}"),
    ("the nonce left out", AP, "const nonce = this.seam.nonce();", "this.seam.nonce()", '""'),
    ("a grant proposal without the namespace prefix", AP, "return this.cfg.grantProposalFormat ?", ": `${this.cfg.namespacePrefix}${canonical(fields)}`", ": canonical(fields)"),
    ("a revocation proposal without the namespace prefix", AP, "return `${this.cfg.namespacePrefix}${canonical({ grant_id, requested_at })}`;", "${this.cfg.namespacePrefix}", ""),
    ("an attestation under another actor", AP, "const a = await this.actors.plan(proposal, grantor, grantor_credential);", "proposal, grantor", "proposal, subject"),
    ("an orphan not logged at issuance", AP, "try { await this.store.commit([...a.stmts, ...this.orphan(a.attestation_id, proposal, requested_at, reason)]);", ", ...this.orphan(a.attestation_id, proposal, requested_at, reason)", ""),
    ("an orphan answered at the wrong position", AP, 'return { orphan: "pre-grant", attestation_id: a.attestation_id };', '"pre-grant"', '"post-grant"'),
    ("an already-attributed handle not read as an orphan", AP, 'if ("held" in g && (await this.attributed(handle)))', "(await this.attributed(handle))", "false"),
    ("the grant attribution entry left out", AP, "...this.entry(GRANT_MAP, handle, a.attestation_id)];", ", ...this.entry(GRANT_MAP, handle, a.attestation_id)", ""),
    ("the grant left out of the issuance", AP, 'const stmts = [...a.stmts, ...("held" in g ? [] : g.stmts)', '...("held" in g ? [] : g.stmts), ', ""),
    ("the attestation left out of the issuance", AP, 'const stmts = [...a.stmts, ...("held" in g ? [] : g.stmts)', "[...a.stmts, ", "["),
    ("a lost pair not read again", AP, 'e.guard === "pair-held" || e.guard === "entry-held"', 'e.guard === "pair-held" || ', ""),
    ("a refused revoke answered as done", AP, "return p;                                                                                                      // Action wiring 27", "return p;", "return { attestation_id: a.attestation_id, stmts: [] };"),
    ("an orphan not logged at a revocation", AP, "try { await this.store.commit([...ahead, ...a.stmts, ...this.orphan(", ", ...this.orphan(a.attestation_id, proposal, requested_at, p.refused)", ""),
    ("the revocation attribution entry left out", AP, "const stmts = [...a.stmts, ...p.stmts, ...this.entry(REVOKE_MAP, grant_id, a.attestation_id)];", ", ...this.entry(REVOKE_MAP, grant_id, a.attestation_id)", ""),
    ("a grant revoked meanwhile not read as not-active", AP, 'if (e instanceof Guard && e.guard === "revoked")', 'e.guard === "revoked"', "false"),
    ("an unheld pair answered not-known", AP, "if (set.length === 0) return", '{ refused: "not-permitted" }', '{ refused: "not-known" }'),
    ("a revoked grant enumerated", AP, "// Action wiring 42: the enumerated set, one read", 'g.status === "active" && ', ""),
    ("an unknown grant answered as inconsistent", AP, 'if (!grant) return "not-known";', '"not-known"', '"attribution-inconsistency"'),
    ("a missing grant entry answered as not-known", AP, 'if (!issued) return "attribution-inconsistency";', 'return "attribution-inconsistency";', 'return "not-known";'),
    ("a missing revocation entry answered as not-known", AP, 'if (!revoked) return "attribution-inconsistency";', '"attribution-inconsistency"', '"not-known"'),
    ("a revocation entry read for an active grant", AP, 'if (grant.status === "revoked") {', 'grant.status === "revoked"', "true"),
    ("the purge record read for a present attestation", AP, 'if (v !== "not-known") return v;', 'v !== "not-known"', "false"),
    ("the purge record ignored", AP, "if (await this.cfg.purgeRecord?.(attestation_id))", "await this.cfg.purgeRecord?.(attestation_id)", "false"),
    ("an evaluation trimmed", AP, "return this.perms.permitted(subject_ref, action_scope);", "(subject_ref, action_scope)", "(subject_ref.trim(), action_scope)"),
    ("a blank clock offset allowance admitted", AP, "if (cfg.clockOffsetAllowanceMs === null", "=== null ||", "=== 12345 ||"),
    ("a blank retention horizon admitted", AP, "if (cfg.retentionHorizonMs === null", "=== null ||", "=== 12345 ||"),
    ("a length cap over Permissions' admitted", AP, "cfg.lengthCap > parts.permissions.stringCap", "cfg.lengthCap > parts.permissions.stringCap", "false"),
    ("the default cap not Permissions'", AP, "this.cap = cfg.lengthCap ?? perms.stringCap;", "?? perms.stringCap", "?? 1e9"),
    ("a deployment fault at the attestation not alerted", AP, 'if (r === "invalid-request") {', 'this.cfg.alert?.({ arm: "primitive-policy-16", action });', ""),
    ("an attestation storage-failure answered as storage-failure", AP, 'if (r === "storage-failure") return { refused: "attribution-storage-failure" };', '"attribution-storage-failure"', '"storage-failure"'),
    ("Permissions' revoke plan answering a revoked grant as known", "src/permissions.ts", 'if (g.status === "revoked") return { refused: "not-active" };', 'return { refused: "not-active" };', "{}"),
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
