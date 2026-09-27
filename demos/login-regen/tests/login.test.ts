// Login's three actions and its sweep. Each test names the rule it holds.
import { assert, assertEquals, assertThrows } from "@std/assert";
import { credential, session } from "../src/atoms.ts";
import { Login } from "../src/composition.ts";
import { AFTER_BOUND, CONFIG, world } from "./helpers.ts";

Deno.test("a verified login issues a session, writes both maps, one entry and one login_succeeded (Action wiring 1 through 13)", () => {
  const w = world();
  const r = w.good();
  assert("ok" in r);
  const t = r.ok.session_token;
  assertEquals(w.login.maps(), { c2s: [{ credential_id: w.cred_id, session_token: t }], s2c: [{ credential_id: w.cred_id, session_token: t }] });
  const [e] = w.login.loginEventLog();
  assertEquals([e.outcome, e.credential_id, e.session_token], ["success", w.cred_id, t]);
  const [ev] = w.of("login_succeeded");
  assertEquals([ev.data.session_token, ev.data.credential_id, ev.data.login_entry_id], [t, w.cred_id, e.entry_id]);
  assertEquals("valid" in session.validate(w.db, w.seam, t), true);
});

Deno.test("a wrong password issues nothing and never answers the reason (Action wiring 2, 3; Invariant 1.2)", () => {
  const w = world();
  assertEquals(w.login.login("user_u91", "password", "wrong", "login_svc"), { refused: "invalid-credential" });
  assertEquals(session.read(w.db).length, 0);
  assertEquals(w.login.loginEventLog()[0].outcome, "failed-verification");
  assertEquals(w.of("login_failed")[0].data.reason, "material-mismatch");
});

Deno.test("with failed-login auditing off, a failure writes the entry and no event (Capability requirement 15)", () => {
  const w = world({ auditFailedLogins: false });
  w.login.login("user_u91", "password", "wrong", "login_svc");
  assertEquals(w.login.loginEventLog().length, 1);
  assertEquals(w.of("login_failed").length, 0);
});

Deno.test("the boundary predicate refuses blanks and an unset duration before any constituent (Primitive policy 1 through 5)", () => {
  const w = world({ defaultSessionDurationMs: undefined });
  assertEquals(w.login.login(" ", "password", "x", "login_svc"), { refused: "invalid-request" });
  assertEquals(w.login.login("user_u91", "password", "", "login_svc"), { refused: "invalid-request" });
  assertEquals(w.good(), { refused: "invalid-request" });
  assertEquals(w.login.loginEventLog().length, 0);
});

Deno.test("a session store failure lands at the session-issue stage (Action wiring 31)", () => {
  const w = world();
  w.f.arm("session.issue");
  assertEquals(w.good(), { refused: "storage-failure", stage: "session-issue" });
  const [e] = w.login.loginEventLog();
  assertEquals([e.outcome, e.stage, e.credential_id, e.session_token], ["failed-storage-failure", "session-issue", w.cred_id, null]);
});

Deno.test("a rotation between the two reads lands at the credential-id-confirm stage (Action wiring 5 through 7)", () => {
  const w = world();
  const orig = session.issue;
  session.issue = (...a: Parameters<typeof orig>) => { const r = orig(...a); credential.rotate(w.db, w.seam, w.cred_id, "correct horse"); return r; };
  try { assertEquals(w.good(), { refused: "storage-failure", stage: "credential-id-confirm" }); } finally { session.issue = orig; }
  assertEquals(w.login.maps().s2c.length, 0);                                        // Invariant 3.1: nothing roots on the predecessor
});

Deno.test("a map write failure still answers the token and records the pair; the cascade still reaches it (Action wiring 10, 11; Invariant 2.4)", () => {
  const w = world();
  w.f.arm("maps.write");
  const r = w.good();
  assert("ok" in r);
  assertEquals(w.login.maps().s2c.length, 0);
  assertEquals(w.login.loginEventLog()[0].outcome, "success-with-map-failure");
  assertEquals(w.of("login_map_write_failure")[0].data.session_token, r.ok.session_token);
  const c = w.login.revoke_sessions_for_credential(w.cred_id, "security_team", "suspected compromise");
  assertEquals(c, { ok: { revoked: 1, skipped: 0, failed: 0, not_found: 0 } });
});

Deno.test("logout revokes and records; it relays Session's refusals by name (Action wiring 14 through 16, 27 through 29)", () => {
  const w = world();
  const t = w.token();
  assertEquals(w.login.logout(t, "user_u91", "user-initiated-logout"), { ok: "ok" });
  assertEquals(w.of("logout_succeeded")[0].data, { session_token: t, requested_by: "user_u91", reason: "user-initiated-logout" });
  assertEquals(w.login.logout(t, "user_u91", "again"), { refused: "already-terminal" });
  assertEquals(w.login.logout("nope", "user_u91", "x"), { refused: "not-known" });
  assertEquals(w.login.logout(w.token(), "user_u91", " "), { refused: "invalid-request" });
  const u = w.token();
  w.f.arm("session.revoke");
  assertEquals(w.login.logout(u, "user_u91", "bye"), { refused: "storage-failure" });
});

Deno.test("the cascade: initiation first, the join key in the stored reason, four counts, a completion carrying them (Action wiring 17 through 26, 32 through 36)", () => {
  const w = world();
  const live = w.token();
  const lapsed = w.login.login("user_u91", "password", "correct horse", "login_svc", 1000);
  assert("ok" in lapsed);
  const gone = w.token();
  w.login.logout(gone, "user_u91", "bye");
  const failing = w.token();
  w.seam.advance(2000);
  w.f.arm(`session.revoke:${failing}`);
  const r = w.login.revoke_sessions_for_credential(w.cred_id, "security_team", "suspected compromise");
  assertEquals(r, { ok: { revoked: 1, skipped: 2, failed: 1, not_found: 0 } });
  const [init] = w.of("credential_revocation_cascade_initiated");
  assertEquals(init.data, { credential_id: w.cred_id, revoked_by_ref: "security_team", reason: "suspected compromise" });
  const s = session.read(w.db).find((x) => x.session_token === live)!;
  assertEquals(s.revocation_reason, `credential-revocation-cascade:${init.event_id}: suspected compromise`);
  assertEquals(w.of("session_revoke_failure_during_cascade")[0].data.session_token, failing);
  const [done] = w.of("credential_revocation_cascade_completed");
  assertEquals([done.data.initiation_event_id, done.data.revoked, done.data.skipped, done.data.failed], [init.event_id, 1, 2, 1]);
  assert(init.seq < done.seq);
});

Deno.test("a token in the cascade set that Session does not know is counted not-found and recorded (Action wiring 35)", () => {
  const w = world();
  w.db.exec(`INSERT INTO credential_to_sessions VALUES ('${w.cred_id}', 'session-999')`);
  const r = w.login.revoke_sessions_for_credential(w.cred_id, "security_team", "check");
  assertEquals(r, { ok: { revoked: 0, skipped: 0, failed: 0, not_found: 1 } });
  assertEquals(w.of("session_not_found_during_cascade")[0].data.session_token, "session-999");
});

Deno.test("an unrecorded initiation answers storage-failure and revokes nothing (Action wiring 33)", () => {
  const w = world();
  const t = w.token();
  w.f.arm("log.append:credential_revocation_cascade_initiated", 2);
  assertEquals(w.login.revoke_sessions_for_credential(w.cred_id, "security_team", "x"), { refused: "storage-failure" });
  assert("valid" in session.validate(w.db, w.seam, t));
});

Deno.test("every event is the service identity's, the human party in the data (Composes 12 through 14; Check 6.1)", () => {
  const w = world();
  const t = w.token();
  w.login.login("user_u91", "password", "wrong", "login_svc");
  w.login.logout(t, "user_u91", "bye");
  w.login.revoke_sessions_for_credential(w.cred_id, "security_team", "x");
  const all = w.audit.log_read(1).filter((e) => e.envelope);
  assertEquals(all.length, 5);
  for (const e of all) assertEquals(e.envelope!.actor_ref, "login_service");
});

Deno.test("the maps agree, rebuild from the events, and never lose an entry (Invariant 6.1; Composition state 4, 5, 7)", () => {
  const w = world();
  w.token(); w.token();
  const m = w.login.maps();
  assertEquals(m.c2s, m.s2c);
  assertEquals(w.login.rebuildMaps(), m.s2c);
  assertThrows(() => w.db.exec("DELETE FROM credential_to_sessions"));
  assertThrows(() => w.db.exec("UPDATE session_to_credential SET credential_id = 'x'"));
  assertThrows(() => w.db.exec("DELETE FROM login_event_log"));
});

Deno.test("the sweep re-emits an owed login record from its entry, once (Reconciliation 5; Audit arm 3)", () => {
  const w = world();
  w.f.arm("log.append:login_succeeded", 2);
  const t = w.token();
  assertEquals(w.of("login_succeeded").length, 0);
  w.seam.advance(AFTER_BOUND);
  w.login.sweep();
  assertEquals(w.of("login_succeeded").map((e) => e.data.session_token), [t]);
  w.login.sweep();
  assertEquals(w.of("login_succeeded").length, 1);
});

Deno.test("the sweep backfills a map write failure's pair (Reconciliation 20; Check 2.3)", () => {
  const w = world();
  w.f.arm("maps.write");
  const r = w.good();
  assert("ok" in r);
  w.seam.advance(AFTER_BOUND);
  w.login.sweep();
  assertEquals(w.login.maps().s2c, [{ credential_id: w.cred_id, session_token: r.ok.session_token }]);
});

Deno.test("an orphan session: left while young, revoked after a recovery intent once old, never outside the issuers (Reconciliation 6 through 9, 16, 18; Non-goal 13)", () => {
  const w = world();
  const orphan = session.issue(w.db, w.seam, w.f, "user_u91", "login_svc", 60_000_000, undefined) as { ok: string };
  const foreign = session.issue(w.db, w.seam, w.f, "user_u91", "other_svc", 60_000_000, undefined) as { ok: string };
  w.login.sweep();
  assert("valid" in session.validate(w.db, w.seam, orphan.ok));
  w.seam.advance(AFTER_BOUND);
  w.login.sweep();
  assertEquals(session.validate(w.db, w.seam, orphan.ok), { invalid: "revoked" });
  assertEquals(session.read(w.db).find((s) => s.session_token === orphan.ok)!.revocation_reason, "unattributed-issuance-recovery");
  const [intent] = w.of("login_recovery_intended"), [rec] = w.of("orphan_session_revoked");
  assert(intent.seq < rec.seq);
  assert("valid" in session.validate(w.db, w.seam, foreign.ok));
});

Deno.test("a revoked session with no revocation-family event gets the member its stored reason names (Reconciliation 10, 15)", () => {
  const w = world();
  const a = w.token(), b = w.token();
  session.revoke(w.db, w.seam, w.f, a, "admin", "policy");
  session.revoke(w.db, w.seam, w.f, b, "sec", "credential-revocation-cascade:event-042: breach");
  w.seam.advance(AFTER_BOUND);
  w.login.sweep();
  assertEquals(w.of("logout_succeeded").map((e) => [e.data.session_token, e.data.requested_by]), [[a, "admin"]]);
  assertEquals(w.of("session_revoked_by_cascade").map((e) => [e.data.session_token, e.data.initiation_event_id, e.data.credential_id]), [[b, "event-042", w.cred_id]]);
});

Deno.test("an initiation with no completion is abandoned, then the cascade runs again (Reconciliation 11, 12, 17, 19)", () => {
  const w = world();
  const t = w.token();
  w.f.arm("log.append:credential_revocation_cascade_completed", 2);
  w.login.revoke_sessions_for_credential(w.cred_id, "security_team", "breach");
  const [init] = w.of("credential_revocation_cascade_initiated");
  w.login.sweep();
  assertEquals(w.of("credential_revocation_cascade_abandoned").length, 0);          // 11: too young
  w.seam.advance(AFTER_BOUND);
  w.login.sweep();
  const [ab] = w.of("credential_revocation_cascade_abandoned");
  assertEquals(ab.data.initiation_event_id, init.event_id);
  assertEquals(w.of("credential_revocation_cascade_initiated").length, 2);
  assertEquals(w.of("credential_revocation_cascade_completed").length, 1);
  assertEquals(session.validate(w.db, w.seam, t), { invalid: "revoked" });
});

Deno.test("an owed record the window did not close escalates (Reconciliation 13)", () => {
  const w = world();
  w.f.arm("log.append:login_succeeded", 10);
  w.token();
  w.seam.advance(CONFIG.reconciliationWindowMs + 1);
  w.login.sweep();
  assert(w.login.findings.some((f) => f.discrepancy.startsWith("entry:")));
});

Deno.test("an instance refuses a cadence longer than its window (Capability requirement 13)", () => {
  assertThrows(() => world({ reconciliationCadenceMs: CONFIG.reconciliationWindowMs + 1 }));
});

Deno.test("Login never registers, rotates or revokes a credential (Composes 8 through 10; Wiring decision 3)", () => {
  const w = world();
  w.token();
  w.login.revoke_sessions_for_credential(w.cred_id, "security_team", "x");
  assertEquals(credential.read(w.db, w.seam, { credential_id: w.cred_id })[0].status, "active");
  assert(!("register" in Login.prototype) && !("rotate" in Login.prototype));
});
