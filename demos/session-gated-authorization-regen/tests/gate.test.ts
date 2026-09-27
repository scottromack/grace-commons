// Session-Gated Authorization. Each test names the rule it holds.
import { assert, assertEquals, assertThrows } from "@std/assert";
import { openStore } from "../src/store.ts";
import { permissions, session } from "../src/atoms.ts";
import { SessionGatedAuthorization } from "../src/composition.ts";

function world(bound = 128) {
  const db = openStore();
  let t = Date.UTC(2026, 8, 27);
  const now = () => new Date(t).toISOString();
  const gate = SessionGatedAuthorization.start(db, now, bound);
  const calls: [string, string][] = [];
  const real = permissions.permitted;
  permissions.permitted = (d, s, a) => { calls.push([s, a]); return real(d, s, a); };
  const done = () => { permissions.permitted = real; };
  return { db, now, gate, calls, done, advance: (ms: number) => { t += ms; } };
}

Deno.test("a valid session and a grant answer permitted, asking Permissions with the session's own principal (Action wiring 5, 6; Invariant 2.1)", () => {
  const w = world();
  try {
    const tok = session.issue(w.db, w.now, "usr_42", "login_svc", 3_600_000);
    permissions.grant(w.db, w.now, "usr_42", "invoice:read");
    assertEquals(w.gate.check_permitted(tok, "invoice:read"), "permitted");
    assertEquals(w.calls, [["usr_42", "invoice:read"]]);
  } finally { w.done(); }
});

Deno.test("a valid session with no grant answers denied: the gate cleared, the answer is no (Invariant 3.1, 4.1, 4.2)", () => {
  const w = world();
  try {
    const tok = session.issue(w.db, w.now, "usr_42", "login_svc", 3_600_000);
    assertEquals(w.gate.check_permitted(tok, "invoice:delete"), "denied");
    assertEquals(w.calls.length, 1);
  } finally { w.done(); }
});

Deno.test("an expired, revoked or unknown session is refused, naming the reason, and Permissions is never asked (Action wiring 9; Invariant 1.1, 3.2, 3.3)", () => {
  const w = world();
  try {
    permissions.grant(w.db, w.now, "usr_42", "invoice:read");
    const lapsing = session.issue(w.db, w.now, "usr_42", "login_svc", 1000);
    const revoked = session.issue(w.db, w.now, "usr_42", "login_svc", 3_600_000);
    session.revoke(w.db, w.now, revoked, "usr_42", "logout");
    w.advance(1000);
    assertEquals(w.gate.check_permitted(lapsing, "invoice:read"), { "session-invalid": "expired" });
    assertEquals(w.gate.check_permitted(revoked, "invoice:read"), { "session-invalid": "revoked" });
    assertEquals(w.gate.check_permitted("tok_unknown", "invoice:read"), { "session-invalid": "not-known" });
    assertEquals(w.calls, []);
  } finally { w.done(); }
});

Deno.test("malformed input is refused before either constituent; nothing trimmed or folded (Primitive policy 2 through 9)", () => {
  const w = world(16);
  try {
    const tok = session.issue(w.db, w.now, "usr_42", "login_svc", 3_600_000);
    permissions.grant(w.db, w.now, "usr_42", "invoice:read");
    assertEquals(w.gate.check_permitted("   ", "invoice:read"), "invalid-request");
    assertEquals(w.gate.check_permitted(tok, ""), "invalid-request");
    assertEquals(w.gate.check_permitted(tok, "x".repeat(17)), "invalid-request");
    assertEquals(w.calls, []);
    assertEquals(w.gate.check_permitted(tok, " invoice:read"), "denied");
    assertEquals(w.gate.check_permitted(tok, "Invoice:Read"), "denied");
  } finally { w.done(); }
});

Deno.test("every call validates afresh: a revocation between two calls is seen by the second (Action wiring 13, 14)", () => {
  const w = world();
  try {
    const tok = session.issue(w.db, w.now, "usr_42", "login_svc", 3_600_000);
    permissions.grant(w.db, w.now, "usr_42", "invoice:read");
    assertEquals(w.gate.check_permitted(tok, "invoice:read"), "permitted");
    session.revoke(w.db, w.now, tok, "security", "breach");
    assertEquals(w.gate.check_permitted(tok, "invoice:read"), { "session-invalid": "revoked" });
  } finally { w.done(); }
});

Deno.test("a scope over the Permissions cap cannot pass the boundary as a denial (Primitive policy 10)", () => {
  assertThrows(() => world(permissions.stringCap + 1));
  const w = world(permissions.stringCap);
  try {
    const tok = session.issue(w.db, w.now, "usr_42", "login_svc", 3_600_000);
    assertEquals(w.gate.check_permitted(tok, "x".repeat(permissions.stringCap + 1)), "invalid-request");
  } finally { w.done(); }
});

Deno.test("the gate writes nothing and answers one of four classes (Composition state 1; Action wiring 15; Check 3.1)", () => {
  const w = world();
  try {
    const tok = session.issue(w.db, w.now, "usr_42", "login_svc", 3_600_000);
    const before = JSON.stringify([w.db.prepare("SELECT * FROM session").all(), w.db.prepare("SELECT * FROM grant_record").all()]);
    const answers = [w.gate.check_permitted(tok, "a"), w.gate.check_permitted("nope", "a"), w.gate.check_permitted(" ", "a")];
    assertEquals(JSON.stringify([w.db.prepare("SELECT * FROM session").all(), w.db.prepare("SELECT * FROM grant_record").all()]), before);
    for (const a of answers) assert(a === "permitted" || a === "denied" || a === "invalid-request" || (typeof a === "object" && "session-invalid" in a));
    assertEquals(answers[0], "denied");                                                  // Action wiring 12: nothing of the expiry instant
  } finally { w.done(); }
});
