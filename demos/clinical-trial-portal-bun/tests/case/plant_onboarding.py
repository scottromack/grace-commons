#!/usr/bin/env python3
"""Fault Plants on External Onboarding's [Invite], [Decline] and [Revoke] and the hooks they added to three atoms: each plant changes one thing on
the one line a tag names, that file's test file runs, the plant is put back. A plant is seen when a test fails. Run from the demo directory in a copy with
node_modules and XTDB up:  python3 tests/case/plant_onboarding.py [part of a plant's name]"""
import re, subprocess, sys

EO = "src/external_onboarding.ts"
TEST = "tests/external_onboarding.test.ts"
# (name, file, tag: a substring of the one line to change, find: the text in that line, replace)
PLANTS = [
    ("a blank required input admitted", EO, "required.some(", ") return false;", ") return true;"),
    ("the reference length cap not applied", EO, ".length <= this.cfg.referenceLengthCap", "<= this.cfg.referenceLengthCap", "<= 1e9"),
    ("the reference length cap's boundary refused", EO, ".length <= this.cfg.referenceLengthCap", "<= this.cfg.referenceLengthCap", "< this.cfg.referenceLengthCap"),
    ("an invite's constituent field rules not read first", EO, "this.invitation.validInitiate(", "!this.invitation.validInitiate(inviter_ref, invitee_ref, context, ttl)", "false"),
    ("a revoke's constituent field rules not read first", EO, "this.invitation.validRevoke(", "!this.invitation.validRevoke(revoked_by_ref, reason)", "false"),
    ("the payload cap not checked", EO, ".length <= this.trail.log.payloadCap", "<= this.trail.log.payloadCap", "<= 1e12"),
    ("the payload cap's boundary refused", EO, ".length <= this.trail.log.payloadCap", "<= this.trail.log.payloadCap", "< this.trail.log.payloadCap"),
    ("the token sized at one character, not its width bound", EO, "private token()", "this.cfg.mintedIdWidths.invitationToken", "1"),
    ("the post-write record not sized", EO, "return this.sized(ATTEMPT[action]", " && this.sized(POST[action], actor_ref, post)", ""),
    ("a blank invitee reference recorded", EO, "const invitee = isBlank", "isBlank(invitee_ref) ? null : invitee_ref", "invitee_ref"),
    ("an absent ttl not recorded as blank", EO, "const ttlRecorded", "ttl === undefined ? null : ttl", "ttl"),
    ("the post-write record numbered with a guard of its own", EO, "s.post(token), 1)", ", 1)", ", 0)"),
    ("a refused attempt record not stopping the action", EO, 'if ("refusal" in a) return await this.attemptRefused', 'return await this.attemptRefused(s.action, a.refusal, a.keep);', "{ await this.attemptRefused(s.action, a.refusal, a.keep); }"),
    ("a refused credential at the attempt not answered", EO, "Audit arm 1: nothing written", 'if (r.refused === "invalid-credential") return { refused: "invalid-credential" };', ""),
    ("a recording failure at the attempt read as attempt-evidence", EO, "// Audit arm 2", '"intent"', '"attempt-evidence"'),
    ("an invalid-request below step-3 at the attempt read as attempt-evidence", EO, "// Audit arm 3", '"intent"', '"attempt-evidence"'),
    ("an invalid-request from the substrate at the attempt not alerted", EO, 'arm: "audit-arm-19", action, step: r.step', 'this.cfg.alert?.({ arm: "audit-arm-19", action, step: r.step });', ""),
    ("an invalid-request from the substrate at the post-write record not alerted", EO, 'arm: "audit-arm-19", action: s.action, step: r.step', 'this.cfg.alert?.({ arm: "audit-arm-19", action: s.action, step: r.step });', ""),
    ("the attestation of a step-3 or step-4 refusal not committed", EO, "if (keep.length) { try { await this.store.commit(keep)", "if (keep.length)", "if (false)"),
    ("attempt-evidence answered as intent", EO, "// Audit arm 21: the attestation stands", '"attempt-evidence"', '"intent"'),
    ("a refused credential at the post-write record read as storage-failure", EO, "// Audit arm 13", '{ refused: "invalid-credential" }', '{ refused: "storage-failure", position: "intent" }'),
    ("a recording failure at the post-write record read as attempt-evidence", EO, "// Audit arm 5", '"intent"', '"attempt-evidence"'),
    ("a post-write step below step-4 read as attempt-evidence", EO, "// Audit arm 22", '{ refused: "storage-failure", position: "intent" }', '{ refused: "storage-failure", position: "attempt-evidence" }'),
    ("a step-4 refusal that kept nothing committed anyway", EO, "// Audit arm 25", 'if (!keep.length) return { refused: "storage-failure", position: "intent" };', ""),
    ("the action not committed beside the kept record", EO, "await this.store.commit([...a.stmts, ...c.stmts, ...keep])", "...a.stmts, ...c.stmts, ", ""),
    ("the landing read from the first sequence number", EO, "const evs = await this.trail.log.read", "{ sequence: { from } }", "{ sequence: { from: 1 } }"),
    ("the landing read ended at the next record", EO, "const evs = await this.trail.log.read", "{ sequence: { from } }", "{ sequence: { from, to: from + 1 } }"),
    ("a failed commit read as attempt-evidence", EO, "Audit arm 14, 17: a committed nothing", '"intent"', '"attempt-evidence"'),
    ("a lost resolution not planned again", EO, 'e.guard === "log-moved" || e.guard === "resolved"', ' || e.guard === "resolved"', ""),
    ("a moved log not planned again", EO, 'e.guard === "log-moved" || e.guard === "resolved"', 'e.guard === "log-moved" || ', ""),
    ("an unavailable read not answered state-unavailable", EO, "Execution Contract Constituent failure 3", 'if (e instanceof Unavailable) return { refused: "state-unavailable" };', ""),
    ("an expired invitation answered as not-known", EO, 'if (c.refused === "expired" || c.refused === "not-known")', "cause: c.refused", 'cause: "not-known"'),
    ("the stored terminal not named", EO, 'if (c.refused === "already-resolved")', "stored_terminal: c.status as InvitationInvalid", "stored_terminal: \"declined\" as InvitationInvalid"),
    ("a decliner's identity recorded", EO, "const attempt = { invitation_token };", "{ invitation_token }", "{ invitation_token, decliner: service_actor_ref }"),
    ("a decline attested under another reference", EO, 'action: "decline", actor_ref: service_actor_ref', "actor_ref: service_actor_ref", "actor_ref: invitation_token"),
    ("the revocation reason left off the revoke attempt", EO, "const attempt = { invitation_token, revocation_reason: reason };", ", revocation_reason: reason", ""),
    ("the revocation reason left off the revoke record", EO, "const post = () => ({ invitation_token, revocation_reason: reason });", ", revocation_reason: reason", ""),
    ("a revoke's reason over the cap not read first", "src/invitation.ts", "return !(isBlank(revoked_by_ref)", "|| this.long(reason)", ""),
    ("an initiate's inputs not read before the attempt", "src/invitation.ts", "return this.initiateSeconds(inviter_ref, invitee_ref, context, ttl) !== null;", "this.initiateSeconds(inviter_ref, invitee_ref, context, ttl) !== null", "true"),
    ("the second record numbered as the first", "src/event_log.ts", "const first = base + ahead;", "base + ahead", "base"),
    ("the second record's own guard kept", "src/event_log.ts", "const stmts: Stmt[] = [...(ahead > 0", "ahead > 0 ? [] : [guard]", "[guard]"),
    ("the audit plan not passing ahead on", "src/audit_trail.ts", "const ev = await this.log.plan([payload], ahead);", ", ahead)", ")"),
    ("the audit plan answering no sequence number", "src/audit_trail.ts", "sequence_number: ev.sequence_numbers[0],", "ev.sequence_numbers[0]", "0"),
]

def fails(f):
    r = subprocess.run(["./node_modules/.bin/bun", "test", f, "--timeout", "30000"], capture_output=True, text=True)
    m = re.search(r"\n\s*(\d+) fail", r.stdout + r.stderr)
    return int(m.group(1)) if m else 0

def fresh_stack():
    subprocess.run(["bash", "stack/stack.sh", "restart"], capture_output=True, text=True)

named = sys.argv[1] if len(sys.argv) > 1 else ""
seen = total = 0
for name, src, tag, find, repl in PLANTS:
    if named not in name: continue
    orig = open(src).read()
    lines = orig.split("\n")
    hit = [i for i, l in enumerate(lines) if re.search(re.escape(tag) + (r"(?!\d)" if tag[-1].isdigit() else ""), l)]
    if len(hit) != 1 or find not in lines[hit[0]]:
        print("NOT APPLIED:", name, len(hit)); continue
    lines[hit[0]] = lines[hit[0]].replace(find, repl, 1)
    try:
        open(src, "w").write("\n".join(lines))
        if total % 8 == 0: fresh_stack()
        n = fails(TEST); total += 1; seen += n > 0
        print("%-62s %d fail" % (name, n), flush=True)
    finally:
        open(src, "w").write(orig)
print("%d of %d planted faults seen" % (seen, total))
