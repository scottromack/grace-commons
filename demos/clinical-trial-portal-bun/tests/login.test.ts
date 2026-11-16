// Login, one test for each rule the render answers, named by the rule's label.
import { test, expect, afterAll } from "bun:test";
import { generateKeyPairSync } from "node:crypto";
import { Store } from "../src/store.ts";
import { testSeam } from "../src/seam.ts";
import { Credential } from "../src/credential.ts";
import { Session } from "../src/session.ts";
import { EventLog } from "../src/event_log.ts";
import { ActorIdentity, type RegistryAnswer } from "../src/actor_identity.ts";
import { RetentionWindow } from "../src/retention_window.ts";
import { AuditTrail } from "../src/audit_trail.ts";
import { Login, CASCADE_REASON_PREFIX } from "../src/login.ts";

const store = new Store();
afterAll(() => store.close());

const DAY = 86_400_000;
const password = {
  derive: async (m: string) => Bun.password.hash(m, { algorithm: "argon2id", memoryCost: 1024, timeCost: 1 }),
  check: (p: string, v: string) => Bun.password.verify(p, v),
};
const world = async (retentionPolicy = "seven-years") => {
  const seam = testSeam("2026-09-01T10:00:00.000Z");
  const book = new Map<string, RegistryAnswer>();
  const log = await EventLog.open(store, seam, { name: `login-${crypto.randomUUID()}` });
  const actors = await ActorIdentity.open(store, seam, (ref) => book.get(ref) ?? { answer: "unknown-actor" });
  const retention = await RetentionWindow.open(store, seam, (ref) => (ref === "seven-years" ? { answer: "policy", policy: { durationMs: 7 * 365 * DAY, maxPurgeDelayMs: 30 * DAY } } : { answer: "not-found" }), { resolutionMs: 1000 });
  const audit = await AuditTrail.open(store, seam, { log, actors, retention }, { retentionPolicy, reconciliationOperator: "reconciliation-operator" });
  const credential = await Credential.open(store, seam, { types: { password }, defaultValidityMs: null });
  const session = await Session.open(store, seam, { defaultDurationSeconds: 3600 });
  const k = generateKeyPairSync("ed25519");
  const service = { actor_ref: `login-service-${crypto.randomUUID()}`, credential: k.privateKey.export({ format: "der", type: "pkcs8" }).toString("base64") };
  book.set(service.actor_ref, { answer: "material", current: k.publicKey.export({ format: "der", type: "spki" }).toString("base64") });
  const login = await Login.open(store, seam, { credential, session, audit }, { issuerReferences: ["login-svc", "api-gw"], sessionDurationSeconds: 3600, serviceIdentity: service, loginEventRetentionMs: 7 * 365 * DAY });
  const user = async (pw = "correct horse") => {
    const principal_ref = `user-${crypto.randomUUID()}`;
    const r = await credential.register(principal_ref, pw, "password") as { credential_id: string };
    return { principal_ref, credential_id: r.credential_id, pw };
  };
  const events = async () => (await log.read({ sequence: { from: 1 } })) as { sequence_number: number; data: { action_ref: string; actor_ref: string; data: Record<string, unknown> } }[];
  const entries = (principal_ref: string) => store.read<Record<string, unknown>>(`SELECT * FROM login_event_log WHERE principal_ref = $1`, [principal_ref]);
  return { seam, login, credential, session, audit, actors, log, service, user, events, entries };
};
const token = (a: unknown) => (a as { session_token: string }).session_token;

test("Action wiring 1, 4, 5, 8, 9, 12, 13, 39, 45, 46, Composes 12: a login verifies, issues a session, and writes its entry and its login succeeded event (attested under the service identity) with it; the maps carry the pair", async () => {
  const w = await world();
  const u = await w.user();
  const a = await w.login.login(u.principal_ref, "password", u.pw, "login-svc");
  const t = token(a);
  expect(await w.session.validate(t)).toEqual({ valid: { principal_ref: u.principal_ref, expires_at: "2026-09-01T11:00:00.000Z" } });
  const entry = (await w.entries(u.principal_ref))[0];
  expect([entry.outcome, entry.credential_id, entry.session_token]).toEqual(["success", u.credential_id, t]);
  const ev = (await w.events()).filter((e) => e.data.action_ref === "login_succeeded");
  expect(ev).toHaveLength(1);
  expect(ev[0].data.data).toMatchObject({ principal_ref: u.principal_ref, credential_id: u.credential_id, session_token: t, entry_id: entry._id });
  expect(ev[0].data.actor_ref).toBe(w.service.actor_ref);                                                    // Check 6.1
  expect(await store.read(`SELECT credential_id FROM session_credential WHERE _id = $1`, [t])).toEqual([{ credential_id: u.credential_id }]);
  expect(await store.read(`SELECT session_token FROM credential_sessions WHERE credential_id = $1`, [u.credential_id])).toEqual([{ session_token: t }]);
});

test("Action wiring 2, 3, 12, 13, Invariant 1.2, Check 3.1, 3.2: a wrong password and an unknown principal both answer invalid-credential with no reason, issue no session, and each write one entry and one login failed event", async () => {
  const w = await world();
  const u = await w.user();
  expect(await w.login.login(u.principal_ref, "password", "wrong", "login-svc")).toBe("invalid-credential");
  const ghost = `ghost-${crypto.randomUUID()}`;
  expect(await w.login.login(ghost, "password", "whatever", "login-svc")).toBe("invalid-credential");
  expect(await w.session.read({ principal_ref: u.principal_ref })).toEqual([]);
  expect((await w.entries(u.principal_ref))[0].outcome).toBe("failed-verification(material-mismatch)");
  expect((await w.entries(ghost))[0].outcome).toBe("failed-verification(no-active-credential)");
  const failed = (await w.events()).filter((e) => e.data.action_ref === "login_failed");
  expect(failed).toHaveLength(2);
  expect(failed.map((e) => e.data.data.entry_id).sort()).toEqual([(await w.entries(u.principal_ref))[0]._id, (await w.entries(ghost))[0]._id].sort());
});

test("Primitive policy 1 to 3, 5, 10 to 12, 18: a blank input, an over-long reference, an issuer outside the references, no duration, and a duration past the event's retention are invalid-request and write nothing", async () => {
  const w = await world();
  const u = await w.user();
  const bad = { refused: "invalid-request" };
  const before = (await w.events()).length;
  expect(await w.login.login(" ", "password", "x", "login-svc")).toEqual(bad);
  expect(await w.login.login(u.principal_ref, "", "x", "login-svc")).toEqual(bad);
  expect(await w.login.login(u.principal_ref, "password", "", "login-svc")).toEqual(bad);
  expect(await w.login.login("p".repeat(257), "password", "x", "login-svc")).toEqual(bad);
  expect(await w.login.login(u.principal_ref, "password", u.pw, "some-other-service")).toEqual(bad);
  expect(await w.login.login(u.principal_ref, "password", u.pw, "login-svc", 8 * 365 * 86_400)).toEqual(bad);
  expect((await w.events()).length).toBe(before);
  expect(await w.entries(u.principal_ref)).toEqual([]);
  expect(await w.session.read({ principal_ref: u.principal_ref })).toEqual([]);
});

test("Action wiring 30: a login that verifies where no credential id can be read answers storage-failure(credential-id-lookup) and writes nothing", async () => {
  const w = await world();
  const u = await w.user();
  const lying = Object.create(w.credential) as Credential;
  (lying as unknown as { read: () => Promise<[]> }).read = async () => [];
  const login = await Login.open(store, w.seam, { credential: lying, session: w.session, audit: w.audit }, { issuerReferences: ["login-svc"], sessionDurationSeconds: 3600, serviceIdentity: w.service, loginEventRetentionMs: 7 * 365 * DAY });
  expect(await login.login(u.principal_ref, "password", u.pw, "login-svc")).toEqual({ refused: "storage-failure", stage: "credential-id-lookup" });
  expect(await w.session.read({ principal_ref: u.principal_ref })).toEqual([]);
  expect(await w.entries(u.principal_ref)).toEqual([]);
});

test("Action wiring 45, 46, 38, Audit arm 13, Database 1: where the login event cannot be recorded, the login answers storage-failure(login-event-record) and the session and the entry are not written either", async () => {
  const w = await world("no-such-policy");
  const u = await w.user();
  expect(await w.login.login(u.principal_ref, "password", u.pw, "login-svc")).toEqual({ refused: "storage-failure", stage: "login-event-record" });
  expect(await w.session.read({ principal_ref: u.principal_ref })).toEqual([]);
  expect(await w.entries(u.principal_ref)).toEqual([]);
});

test("Composition state 3, 7, Action wiring 10, 14, 43: with the maps lost, a logout rebuilds them from the login succeeded events; a token no event carries is not-known and Session's revoke is not called", async () => {
  const w = await world();
  const u = await w.user();
  const t = token(await w.login.login(u.principal_ref, "password", u.pw, "login-svc"));
  await store.commit([{ text: `ERASE FROM session_credential WHERE _id = $1`, params: [t] }, { text: `ERASE FROM credential_sessions WHERE _id = $1`, params: [`${u.credential_id}|${t}`] }]);
  expect(await w.login.logout(t, u.principal_ref, "user-initiated-logout")).toBe("ok");
  expect(await w.session.validate(t)).toEqual({ invalid: "revoked" });
  expect(await store.read(`SELECT credential_id FROM session_credential WHERE _id = $1`, [t])).toEqual([{ credential_id: u.credential_id }]);   // rebuilt
  const forged = await w.session.issue("someone", "api-gw", 60) as { session_token: string };            // a session no login of this composition issued
  expect(await w.login.logout(forged.session_token, "someone", "bye")).toEqual({ refused: "not-known" });
  expect(await w.session.validate(forged.session_token)).toMatchObject({ valid: expect.anything() });
});

test("Action wiring 15, 16, 27, 29, Primitive policy 4, 13: a logout revokes the session and records logout succeeded with who asked; again is already-terminal; blank token, blank attribution and a cascade-prefixed reason are invalid-request", async () => {
  const w = await world();
  const u = await w.user();
  const t = token(await w.login.login(u.principal_ref, "password", u.pw, "login-svc"));
  expect(await w.login.logout(" ", u.principal_ref, "x")).toEqual({ refused: "invalid-request" });
  expect(await w.login.logout(t, " ", "x")).toEqual({ refused: "invalid-request" });
  expect(await w.login.logout(t, u.principal_ref, CASCADE_REASON_PREFIX + "forged")).toEqual({ refused: "invalid-request" });
  expect(await w.login.logout(t, u.principal_ref, "user-initiated-logout")).toBe("ok");
  const ev = (await w.events()).filter((e) => e.data.action_ref === "logout_succeeded");
  expect(ev).toHaveLength(1);
  expect(ev[0].data.data).toMatchObject({ session_token: t, revoked_by_ref: u.principal_ref, requested_by: u.principal_ref, reason: "user-initiated-logout", now: "2026-09-01T10:00:00.000Z" });
  expect(await w.login.logout(t, u.principal_ref, "again")).toEqual({ refused: "already-terminal" });
  expect((await w.events()).filter((e) => e.data.action_ref === "logout_succeeded")).toHaveLength(1);
});

test("Action wiring 17 to 26, 32, 34, 36: a cascade records its initiation first, revokes every valid session with the cascade reason and an event each, counts the rest skipped, and completes with the four counts; the map is unchanged", async () => {
  const w = await world();
  const u = await w.user();
  const a = token(await w.login.login(u.principal_ref, "password", u.pw, "login-svc"));
  const b = token(await w.login.login(u.principal_ref, "password", u.pw, "login-svc"));
  const c = token(await w.login.login(u.principal_ref, "password", u.pw, "login-svc"));
  const d = token(await w.login.login(u.principal_ref, "password", u.pw, "login-svc", 60));
  await w.login.logout(c, u.principal_ref, "user-initiated-logout");                                           // already revoked
  w.seam.advance(120_000);                                                                                     // d has lapsed
  const mapBefore = await store.read(`SELECT session_token FROM credential_sessions WHERE credential_id = $1`, [u.credential_id]);
  const tally = await w.login.revokeSessionsForCredential(u.credential_id, "security-team", "suspected-compromise");
  expect(tally).toEqual({ revoked: 2, skipped: 2, failed: 0, not_found: 0 });
  const ev = (await w.events()).map((e) => e.data);
  const names = ev.map((e) => e.action_ref).filter((n) => n.includes("cascade"));
  expect(names[0]).toBe("credential_revocation_cascade_initiated");
  expect(names.at(-1)).toBe("credential_revocation_cascade_completed");
  expect(names.filter((n) => n === "session_revoked_by_cascade")).toHaveLength(2);
  const init = (await w.events()).find((e) => e.data.action_ref === "credential_revocation_cascade_initiated")!;
  const done = ev.find((e) => e.action_ref === "credential_revocation_cascade_completed")!;
  expect(done.data).toMatchObject({ revoked: 2, skipped: 2, failed: 0, not_found: 0 });
  const initId = (await w.log.read({ sequence: { from: init.sequence_number, to: init.sequence_number } }) as { event_id: string }[])[0].event_id;
  expect(done.data.initiation_event_id).toBe(initId);
  for (const t of [a, b]) expect(await w.session.validate(t)).toEqual({ invalid: "revoked" });
  const rows = await w.session.read({ principal_ref: u.principal_ref });
  expect(rows.filter((r) => r.revocation_reason?.startsWith(`${CASCADE_REASON_PREFIX}${initId}: suspected-compromise`))).toHaveLength(2);
  expect(await store.read(`SELECT session_token FROM credential_sessions WHERE credential_id = $1`, [u.credential_id])).toEqual(mapBefore);  // Action wiring 24
});

test("Invariant 2.3, 2.4: a lost map entry does not shrink the cascade set, which is the union of the map and the events", async () => {
  const w = await world();
  const u = await w.user();
  const t = token(await w.login.login(u.principal_ref, "password", u.pw, "login-svc"));
  await store.commit([{ text: `ERASE FROM credential_sessions WHERE _id = $1`, params: [`${u.credential_id}|${t}`] }]);
  expect(await w.login.revokeSessionsForCredential(u.credential_id, "security-team", "compromise")).toEqual({ revoked: 1, skipped: 0, failed: 0, not_found: 0 });
  expect(await w.session.validate(t)).toEqual({ invalid: "revoked" });
});

test("Action wiring 35, 42: a token in the map that Session does not know is counted not-found with a session not found event", async () => {
  const w = await world();
  const u = await w.user();
  await store.commit([store.put("credential_sessions", { _id: `${u.credential_id}|ghost-token`, credential_id: u.credential_id, session_token: "ghost-token" })]);
  expect(await w.login.revokeSessionsForCredential(u.credential_id, "security-team", "compromise")).toEqual({ revoked: 0, skipped: 0, failed: 0, not_found: 1 });
  expect((await w.events()).filter((e) => e.data.action_ref === "session_not_found_during_cascade")).toHaveLength(1);
});

test("Primitive policy 15 to 17, Action wiring 33: a cascade with a blank credential id, revoking reference or reason is invalid-request and records nothing; where its initiation cannot be recorded it answers storage-failure", async () => {
  const w = await world();
  const before = (await w.events()).length;
  expect(await w.login.revokeSessionsForCredential(" ", "sec", "r")).toEqual({ refused: "invalid-request" });
  expect(await w.login.revokeSessionsForCredential("c", "", "r")).toEqual({ refused: "invalid-request" });
  expect(await w.login.revokeSessionsForCredential("c", "sec", " ")).toEqual({ refused: "invalid-request" });
  expect((await w.events()).length).toBe(before);
  const broken = await world("no-such-policy");
  expect(await broken.login.revokeSessionsForCredential("c", "sec", "r")).toEqual({ refused: "storage-failure" });
});

test("Database 2, Invariant 6.1: five logins at once land five sessions, five entries and five events in one order, and both maps agree", async () => {
  const w = await world();
  const u = await w.user();
  const out = await Promise.all(Array.from({ length: 5 }, () => w.login.login(u.principal_ref, "password", u.pw, "login-svc")));
  const tokens = out.map(token);
  expect(new Set(tokens).size).toBe(5);
  expect(await w.entries(u.principal_ref)).toHaveLength(5);
  const ev = (await w.events()).filter((e) => e.data.action_ref === "login_succeeded");
  expect(ev).toHaveLength(5);
  const seqs = (await w.events()).map((e) => e.sequence_number);
  expect(seqs).toEqual(Array.from({ length: seqs.length }, (_, i) => i + 1));
  const inverse = (await store.read<{ session_token: string }>(`SELECT session_token FROM credential_sessions WHERE credential_id = $1`, [u.credential_id])).map((r) => r.session_token).sort();
  expect(inverse).toEqual([...tokens].sort());
});
