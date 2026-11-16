// Login's reconciliation sweep, one test for each rule the render answers, named by the rule's label.
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
import { Login, CASCADE_REASON_PREFIX, type Discrepancy, type LoginConfig } from "../src/login.ts";

const store = new Store();
afterAll(() => store.close());

const DAY = 86_400_000, HOUR = 3_600_000;
const password = {
  derive: async (m: string) => Bun.password.hash(m, { algorithm: "argon2id", memoryCost: 1024, timeCost: 1 }),
  check: (p: string, v: string) => Bun.password.verify(p, v),
};
const world = async (over: Partial<LoginConfig> = {}, retentionPolicy = "seven-years") => {
  const seam = testSeam("2026-09-01T10:00:00.000Z");
  const book = new Map<string, RegistryAnswer>();
  const log = await EventLog.open(store, seam, { name: `sweep-${crypto.randomUUID()}` });
  const actors = await ActorIdentity.open(store, seam, (ref) => book.get(ref) ?? { answer: "unknown-actor" });
  const retention = await RetentionWindow.open(store, seam, (ref) => (ref === "seven-years" ? { answer: "policy", policy: { durationMs: 7 * 365 * DAY, maxPurgeDelayMs: 30 * DAY } } : { answer: "not-found" }), { resolutionMs: 1000 });
  let policy = retentionPolicy;
  const audit = await AuditTrail.open(store, seam, { log, actors, retention }, { retentionPolicy: () => policy, reconciliationOperator: "reconciliation-operator" });
  const credential = await Credential.open(store, seam, { types: { password }, defaultValidityMs: null });
  const px = `sw_${crypto.randomUUID().replaceAll("-", "_")}_`;      // this world's own tables: the sweep reads every record of its tables
  const session = await Session.open(store, seam, { defaultDurationSeconds: 3600, table: `${px}sessions` });
  const k = generateKeyPairSync("ed25519");
  const service = { actor_ref: `login-service-${crypto.randomUUID()}`, credential: k.privateKey.export({ format: "der", type: "pkcs8" }).toString("base64") };
  book.set(service.actor_ref, { answer: "material", current: k.publicKey.export({ format: "der", type: "spki" }).toString("base64") });
  const login = await Login.open(store, seam, { credential, session, audit }, { issuerReferences: ["login-svc"], sessionDurationSeconds: 3600, serviceIdentity: service, loginEventRetentionMs: 7 * 365 * DAY, tablePrefix: px, ...over });
  const user = async () => {
    const principal_ref = `user-${crypto.randomUUID()}`;
    const r = await credential.register(principal_ref, "correct horse", "password") as { credential_id: string };
    return { principal_ref, credential_id: r.credential_id, pw: "correct horse" };
  };
  const events = async () => (await log.read({ sequence: { from: 1 } })) as { event_id: string; data: { action_ref: string; data: Record<string, unknown> } }[];
  const names = async () => (await events()).map((e) => e.data.action_ref);
  return { px, seam, login, credential, session, audit, log, service, user, events, names, setPolicy: (p: string) => { policy = p; } };
};
const token = (a: unknown) => (a as { session_token: string }).session_token;
const empty = { reemitted: 0, mapped: 0, recovered: 0, revocationsRecorded: 0, escalated: 0 };

test("Reconciliation 20, Invariant 6.1: a pair a login succeeded event carries is written into a map that lacks it, either map; a healthy pair is left", async () => {
  const w = await world();
  const u = await w.user();
  const t = token(await w.login.login(u.principal_ref, "password", u.pw, "login-svc"));
  expect(await w.login.sweep()).toEqual(empty);
  await store.commit([{ text: `ERASE FROM ${w.px}session_credential WHERE _id = $1`, params: [t] }]);               // one side lost
  expect((await w.login.sweep()).mapped).toBe(1);
  expect(await store.read(`SELECT credential_id FROM ${w.px}session_credential WHERE _id = $1`, [t])).toEqual([{ credential_id: u.credential_id }]);
  await store.commit([{ text: `ERASE FROM ${w.px}credential_sessions WHERE _id = $1`, params: [`${u.credential_id}|${t}`] }, { text: `ERASE FROM ${w.px}session_credential WHERE _id = $1`, params: [t] }]);  // both lost
  expect((await w.login.sweep()).mapped).toBe(1);
  expect(await store.read(`SELECT session_token FROM ${w.px}credential_sessions WHERE credential_id = $1`, [u.credential_id])).toEqual([{ session_token: t }]);
  expect(await w.login.sweep()).toEqual(empty);
});

test("Reconciliation 5, 21, 4: an entry whose mirrored event is missing is re-emitted through an ordinary record_action under the service identity, matched by its entry id, and not twice", async () => {
  const w = await world();
  const u = await w.user();
  const t = token(await w.login.login(u.principal_ref, "password", u.pw, "login-svc"));
  const entry = (await store.read<Record<string, string>>(`SELECT * FROM ${w.px}login_event_log WHERE principal_ref = $1`, [u.principal_ref]))[0];
  // an owed entry: the log carries it and the substrate does not (a failed attempt whose event was never recorded)
  const owed = `owed-${crypto.randomUUID()}`;
  await store.commit([store.put(`${w.px}login_event_log`, { _id: owed, principal_ref: u.principal_ref, credential_type: "password", issued_by_ref: "login-svc", attempted_at: w.seam.now(), outcome: "failed-verification(material-mismatch)", credential_id: null, session_token: null })]);
  const r = await w.login.sweep();
  expect(r.reemitted).toBe(1);
  const evs = (await w.events()).filter((e) => e.data.action_ref === "login_failed");
  expect(evs).toHaveLength(1);
  expect(evs[0].data.data).toMatchObject({ entry_id: owed, principal_ref: u.principal_ref, reason: "material-mismatch" });
  expect((await w.events()).filter((e) => e.data.data.entry_id === entry._id)).toHaveLength(1);              // the matched pair is not emitted again
  expect((await w.login.sweep()).reemitted).toBe(0);
  expect(t).toBeTruthy();
});

test("Reconciliation 12, 17, 19, Check 4.1: an initiation with no completion, older than the window, is recorded abandoned, its recovery intended, then the cascade runs again; a young one is left; a closed one is not touched twice", async () => {
  const w = await world();
  const u = await w.user();
  const t = token(await w.login.login(u.principal_ref, "password", u.pw, "login-svc"));
  // the first cascade stopped after its initiation event: nothing else was written
  const init = await w.audit.recordAction("credential_revocation_cascade_initiated", w.service.actor_ref, w.service.credential, { credential_id: u.credential_id, revoked_by_ref: "security-team", reason: "compromise" }) as { event_id: string };
  expect(await w.login.sweep()).toEqual(empty);                                                              // inside the window: it may still be running
  w.seam.advance(2 * HOUR);
  expect(await w.session.validate(t)).toEqual({ invalid: "expired" });                                       // (the two-hour wait lapsed it; a second login gives a live session)
  const t2 = token(await w.login.login(u.principal_ref, "password", u.pw, "login-svc"));
  // the initiation is now older than the window; t2 was issued after it but the credential is the same, so the rerun covers it
  const r = await w.login.sweep();
  expect(r.recovered).toBe(1);
  const names = await w.names();
  const at = (n: string) => names.indexOf(n);
  expect(at("credential_revocation_cascade_abandoned")).toBeGreaterThan(-1);
  expect(at("login_recovery_intended")).toBeGreaterThan(at("credential_revocation_cascade_abandoned"));      // the intent before the rerun
  expect(at("login_recovery_intended")).toBeLessThan(names.lastIndexOf("credential_revocation_cascade_initiated"));
  expect((await w.events()).find((e) => e.data.action_ref === "login_recovery_intended")!.data.data.initiation_event_id).toBe(init.event_id);
  expect(await w.session.validate(t2)).toEqual({ invalid: "revoked" });
  const second = await w.login.sweep();
  expect(second.recovered).toBe(0);                                                                           // abandoned is a closure; the rerun carries its own completion
  expect(names.filter((n) => n === "credential_revocation_cascade_abandoned")).toHaveLength(1);
});

test("Reconciliation 15, 22, 23: a session revoked outside this composition gets the stored-reason member once; one revoked through Login already has its event and gets none; one event never matches two sessions", async () => {
  const w = await world();
  const u = await w.user();
  const viaLogin = token(await w.login.login(u.principal_ref, "password", u.pw, "login-svc"));
  await w.login.logout(viaLogin, u.principal_ref, "user-initiated-logout");
  const a = (await w.session.issue(u.principal_ref, "login-svc", 3600) as { session_token: string }).session_token;
  const b = (await w.session.issue(u.principal_ref, "login-svc", 3600) as { session_token: string }).session_token;
  const c = (await w.session.issue(u.principal_ref, "login-svc", 3600) as { session_token: string }).session_token;
  await w.session.revoke(a, "admin-1", "incident");                                                           // two revoked in one instant with one stored reason: two sessions, no event
  await w.session.revoke(b, "admin-1", "incident");
  await w.session.revoke(c, "admin-2", `${CASCADE_REASON_PREFIX}evt-9: compromise`);                          // a cascade-prefixed stored reason
  const r = await w.login.sweep();
  expect(r.revocationsRecorded).toBe(3);
  const evs = await w.events();
  expect(evs.filter((e) => e.data.action_ref === "logout_succeeded" && e.data.data.reason === "incident")).toHaveLength(2);   // one for each session, not one for both (Reconciliation 23)
  expect(evs.filter((e) => e.data.action_ref === "session_revoked_by_cascade")).toHaveLength(1);
  expect(evs.filter((e) => e.data.action_ref === "logout_succeeded" && e.data.data.reason === "user-initiated-logout")).toHaveLength(1);
  expect((await w.login.sweep()).revocationsRecorded).toBe(0);                                                // matched by revoked by, reason and instant now
});

test("Reconciliation 23: one revocation event never stands for a second session revoked with the same revoked by reference, reason and instant", async () => {
  const w = await world();
  const u = await w.user();
  const first = token(await w.login.login(u.principal_ref, "password", u.pw, "login-svc"));
  const second = (await w.session.issue(u.principal_ref, "login-svc", 3600) as { session_token: string }).session_token;
  expect(await w.login.logout(first, "admin", "end of shift")).toBe("ok");                                     // its event exists
  await w.session.revoke(second, "admin", "end of shift");                                                     // the same triple at the same instant, no event of its own
  expect((await w.login.sweep()).revocationsRecorded).toBe(1);
  expect((await w.events()).filter((e) => e.data.action_ref === "logout_succeeded" && e.data.data.reason === "end of shift")).toHaveLength(2);
});

test("Reconciliation 7: a session issued outside the issuer references is not examined", async () => {
  const w = await world();
  const u = await w.user();
  const foreign = (await w.session.issue(u.principal_ref, "someone-elses-gateway", 3600) as { session_token: string }).session_token;
  await w.session.revoke(foreign, "admin", "their business");
  expect((await w.login.sweep()).revocationsRecorded).toBe(0);
  expect((await w.names()).filter((n) => n === "logout_succeeded")).toHaveLength(0);
});

test("Reconciliation 14: an event the substrate's horizon exceeds is not examined", async () => {
  const w = await world({ horizonMs: 2 * HOUR });
  const u = await w.user();
  const x = (await w.session.issue(u.principal_ref, "login-svc", 3600) as { session_token: string }).session_token;
  await w.session.revoke(x, "admin", "long ago");
  w.seam.advance(3 * HOUR);                                                                                   // past the horizon
  expect((await w.login.sweep()).revocationsRecorded).toBe(0);
});

test("Reconciliation 14: an initiation event older than the substrate's horizon is not examined, so no abandonment is recorded for it", async () => {
  const w = await world({ horizonMs: 2 * HOUR });
  const u = await w.user();
  await w.audit.recordAction("credential_revocation_cascade_initiated", w.service.actor_ref, w.service.credential, { credential_id: u.credential_id, revoked_by_ref: "security-team", reason: "compromise" });
  w.seam.advance(3 * HOUR);                                                                                   // past the window and past the horizon
  expect((await w.login.sweep()).recovered).toBe(0);
  expect(await w.names()).not.toContain("credential_revocation_cascade_abandoned");
});

test("Reconciliation 13, Capability requirement 20: a discrepancy older than the window that the sweep cannot close is escalated to the surface the deployment supplies", async () => {
  const seen: Discrepancy[] = [];
  const w = await world({ escalate: (d) => { seen.push(d); } }, "no-such-policy");                            // the substrate refuses every record
  const u = await w.user();
  const owed = `owed-${crypto.randomUUID()}`;
  await store.commit([store.put(`${w.px}login_event_log`, { _id: owed, principal_ref: u.principal_ref, credential_type: "password", issued_by_ref: "login-svc", attempted_at: w.seam.now(), outcome: "success", credential_id: u.credential_id, session_token: "tok-x" })]);
  expect((await w.login.sweep()).escalated).toBe(0);                                                          // inside the window: left for the next run
  w.seam.advance(2 * HOUR);
  const r = await w.login.sweep();
  expect([r.reemitted, r.escalated]).toEqual([0, 1]);
  expect(seen.map((d) => [d.kind, d.id])).toEqual([["owed-entry", owed]]);
  w.setPolicy("seven-years");                                                                                 // the substrate recovers: the next sweep closes it
  expect((await w.login.sweep()).reemitted).toBe(1);
});

test("Capability requirement 12, 13, Reconciliation 2: a cadence above the window is refused; the default surface keeps what it is given; the sweep runs on a cadence and stops", async () => {
  await expect(world({ reconciliationWindowMs: HOUR, reconciliationCadenceMs: 2 * HOUR })).rejects.toThrow(/cadence/);
  const w = await world({ reconciliationWindowMs: 60_000, reconciliationCadenceMs: 20 });
  expect(w.login.escalations).toEqual([]);
  const reports: unknown[] = [];
  const stop = w.login.runEveryCadence((r) => reports.push(r));
  for (let i = 0; i < 100 && reports.length < 2; i++) await new Promise((res) => setTimeout(res, 50));   // a sweep takes as long as the database takes
  stop();
  let n = -1;                                                                                                // a sweep already under way finishes: wait until the count holds still
  for (let i = 0; i < 100 && reports.length !== n; i++) { n = reports.length; await new Promise((res) => setTimeout(res, 400)); }
  expect(n).toBeGreaterThanOrEqual(2);
  await new Promise((res) => setTimeout(res, 300));
  expect(reports.length).toBe(n);                                                                            // and no new one starts
});
