#!/usr/bin/env python3
"""Fault Plants on External Onboarding's [Onboard], its onboarding probe and binding, and the hooks they added to Credential, Party Identity and
Recoverable Invocation: each plant changes one thing on the one line a tag names, the onboard test file runs, the plant is put back. A plant is seen
when a test fails. Run from the demo directory in a copy with node_modules and XTDB up:  python3 tests/case/plant_onboard.py [part of a plant's name]"""
import re, subprocess, sys

EO = "src/external_onboarding.ts"
TEST = "tests/external_onboarding.onboard.test.ts"
# (name, file, tag: a substring of the one line to change, find: the text in that line, replace)
PLANTS = [
    ("a blank required input admitted", EO, "if (!this.inputs([invitation_token, accepting_identity_ref, name", ")) return bad;", ")) {}"),
    ("the reference length cap not applied to the enrolling actor", EO, "if (!this.inputs([invitation_token, accepting_identity_ref, name", "enrolling_actor_ref)) return bad;", "\"\")) return bad;"),
    ("accept's field rules not read first", EO, "this.invitation.validAccept(accepting_identity_ref)) return bad;", "!this.invitation.validAccept(accepting_identity_ref)", "false"),
    ("enroll's field rules not read first", EO, "this.p.parties.validEnroll(name, date_of_birth", "!this.p.parties.validEnroll(name, date_of_birth, document_type, document_ref, enrolling_actor_ref)", "false"),
    ("register's field rules not read first", EO, "this.p.credentials.validRegister(credential_material", "!(await this.p.credentials.validRegister(credential_material, credential_type, expires_at))", "false"),
    ("the largest outcome not sized", EO, "|| !this.sized(OUTCOME, enrolling_actor_ref, largest)", "|| !this.sized(OUTCOME, enrolling_actor_ref, largest)", ""),
    ("the intent not sized", EO, "if (!this.sized(`${ONBOARDING}.intended`", "!this.sized(`${ONBOARDING}.intended`, enrolling_actor_ref, intent) ||", ""),
    ("a minted id sized at one character", EO, "const largest = { invitation_token, accepting_identity_ref, party_id:", '"x".repeat(w.partyId)', '"x"'),
    ("the act key not the invitation token", EO, "this.p.ri.open(ONBOARDING, invitation_token,", "ONBOARDING, invitation_token, enrolling_actor_ref", "ONBOARDING, accepting_identity_ref, enrolling_actor_ref"),
    ("the credential material carried in the intent", EO, "const intent = { invitation_token, accepting_identity_ref, document_type", "credential_type };", "credential_type, credential_material };"),
    ("a landed act read as not-known", EO, 'case "act-landed"', 'cause: "already-resolved", stored_terminal: "accepted"', 'cause: "not-known"'),
    ("an open's recording failure at the outcome position read as intent", EO, 'case "recording-failure": return o.position === "intent"', 'o.position === "intent"', "true"),
    ("the credential registered under the invitation token", EO, "planRegister(enroll.party_id, credential_material", "enroll.party_id", "invitation_token"),
    ("the call's expiry not passed to register", EO, "planRegister(enroll.party_id, credential_material", "credential_type, expires_at)", "credential_type)"),
    ("the register left out of the transaction", EO, "this.commitWithin([...accept.stmts,", ", ...register.stmts", ""),
    ("the accept left out of the transaction", EO, "this.commitWithin([...accept.stmts,", "...accept.stmts, ", ""),
    ("an expired invitation answered as not-known", EO, 'accept.refused === "expired" || accept.refused === "not-known"', "cause: accept.refused", 'cause: "not-known"'),
    ("the stored terminal not named", EO, 'accept.refused === "already-resolved") return gone', "stored_terminal: accept.status", 'stored_terminal: "accepted"'),
    ("a pre-commit arm not kept by the invocation refuse", EO, "const r = await this.p.ri.refuse(", "await this.p.ri.refuse(ONBOARDING, token, open.invocation_id, open.intent_event_id, actor, cred, answer.refused, code)", '{ refusal_event_id: "x" } as never'),
    ("a refused refusal record answered as the refusal", EO, 'return { refused: "recording-failure", position: "refusal", constituent_code: r.constituent_code };', '{ refused: "recording-failure", position: "refusal", constituent_code: r.constituent_code }', "answer"),
    ("an accounted intent answered as the refusal", EO, 'if (r.refused === "already-accounted") return', '{ refused: "already-accounted", closing_event_id: r.closing_event_id }', "answer"),
    ("a duplicate credential at the plan answered as storage-failure", EO, 'Action wiring 32, 61: nothing committed', '{ refused: "duplicate-active-credential" }', '{ refused: "storage-failure" }'),
    ("a duplicate credential at the commit answered as storage-failure", EO, 'Action wiring 32, 61: the transaction rolled back', '{ refused: "duplicate-active-credential" }', '{ refused: "storage-failure" }'),
    ("a lost resolution not planned again", EO, 'c.guard === "resolved" || c.guard === "heads-moved"', 'c.guard === "resolved" || ', ""),
    ("a moved head not planned again", EO, 'c.guard === "resolved" || c.guard === "heads-moved"', ' || c.guard === "heads-moved"', ""),
    ("a guard the page does not name read as unknown", EO, "a guard the page does not name", 'if (c.guard) return gone({ refused: "storage-failure" }, "storage-failure");', ""),
    ("a commit with no reply read as pre-commit", EO, 'if (c === "no-reply") return this.unknown(', 'return this.unknown(open, invitation_token, "lost");', 'return gone({ refused: "storage-failure" }, "storage-failure");'),
    ("the commit round trip not applied", EO, 'setTimeout(() => r("no-reply"), this.cfg.commitRoundTripMs)', "this.cfg.commitRoundTripMs", "1e7"),
    ("a lost reply yielded as answered", EO, 'return this.unknown(open, invitation_token, "lost");', '"lost"', '"answered"'),
    ("an answered reply yielded as lost", EO, "// an answer no constituent declares", '"answered"', '"lost"'),
    ("an undeclared answer from a plan read as pre-commit", EO, "a code no constituent declares (Recoverable Invocation commit 7)", 'return this.unknown(open, invitation_token, "answered");', 'return gone({ refused: "storage-failure" }, "storage-failure");'),
    ("the invocation yield not called", EO, "try { await this.p.ri.yieldSection(", "await this.p.ri.yieldSection(ONBOARDING, token, open.invocation_id, reply);", ""),
    ("the close naming the credential id left off", EO, "OUTCOME, { invitation_token: token, accepting_identity_ref: accepting, party_id, credential_id }", "party_id, credential_id }", "party_id }"),
    ("a failed close answered without the invocation id", EO, 'const failed: OnboardRefusal = { refused: "recording-failure", position: "outcome", invocation_id', ", invocation_id: open.invocation_id", ""),
    ("a failed close answered as completed", EO, 'return "outcome_event_id" in r ? { party_id, credential_id } : failed;', ": failed", ": { party_id, credential_id }"),
    ("a pending invitation read as undecidable", EO, 'if (inv.status !== "accepted" ||', 'inv.status !== "accepted" || ', ""),
    ("an invitation accepted by another read as the intent's", EO, 'if (inv.status !== "accepted" ||', " || inv.accepting_identity_ref !== intent.accepting_identity_ref", ""),
    ("a party selected without its document type", EO, "const parties = all.filter(", "p.document_type === intent.document_type && ", ""),
    ("a party selected without its document reference", EO, "const parties = all.filter(", "p.document_ref === intent.document_ref && ", ""),
    ("a party selected without its enrolling actor", EO, "const parties = all.filter(", " && p.enrolling_actor_ref === intent_actor_ref", ""),
    ("a party selected only while unverified", EO, "const parties = all.filter(", "(p) => p.document_type", '(p) => p.state === "unverified" && p.document_type'),
    ("a credential selected under any type", EO, "c.credentials.read({ principal_ref: p.party_id", ", credential_type: intent.credential_type as string", ""),
    ("a credential another carries as successor selected", EO, "...found.filter((x) => !successors.has(x.credential_id))", ".filter((x) => !successors.has(x.credential_id))", ""),
    ("an invitation not found read as not-committed", EO, 'if (!inv) return { answer: "unavailable" };', '"unavailable"', '"not-committed"'),
    ("a rejected query read as not-committed", EO, "if (!Array.isArray(all)) return", '"unavailable"', '"not-committed"'),
    ("the binding's act made repeatable", EO, "repeatable: false,", "false", "true"),
    ("the binding's service identity declared", EO, "serviceIdentity: null, serviceCredential: null,", "serviceIdentity: null", 'serviceIdentity: "svc"'),
    ("the binding's outcomes widened", EO, "outcomes: [OUTCOME],", "[OUTCOME]", '[OUTCOME, `${ONBOARDING}.refused`]'),
    ("the binding's retention not the audit horizon", EO, "retentionPeriodMs: b.auditHorizonMs,", "b.auditHorizonMs", "1"),
    ("the binding's envelope not sized", EO, "outcomeEnvelopeBytes: new TextEncoder()", "new TextEncoder().encode(canonical(largest)).length", "1"),
    ("the binding's settling period dropped", EO, "settlingPeriodMs: b.settlingPeriodMs,", "b.settlingPeriodMs", "1"),
    ("the probe not told the intent's actor", "src/recoverable_invocation.ts", "await this.probe(b, rec.act_key, rec.payload, rec.actor_ref)", "rec.payload, rec.actor_ref", 'rec.payload, ""'),
    ("register's expiry rule not read first", "src/credential.ts", "if (typeof this.expiry(this.seam.now(), expires_at) === \"string\") return false;", '=== "string"', '=== "never"'),
    ("register's derive refusal not read first", "src/credential.ts", "return (await type.derive(material)) !== null;", "!== null", "!== undefined"),
    ("enroll's date rule not read first", "src/party_identity.ts", "return typeof date_of_birth === \"string\" && this.dobOk(date_of_birth);", "this.dobOk(date_of_birth)", "true"),
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
