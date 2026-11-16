// Audit Trail's [Record Action], one test for each rule the render answers, named by the rule's label.
import { test, expect, afterAll } from "bun:test";
import { generateKeyPairSync } from "node:crypto";
import { Store } from "../src/store.ts";
import { testSeam } from "../src/seam.ts";
import { EventLog } from "../src/event_log.ts";
import { ActorIdentity, type RegistryAnswer } from "../src/actor_identity.ts";
import { RetentionWindow, type PolicyRegistry } from "../src/retention_window.ts";
import { AuditTrail } from "../src/audit_trail.ts";

const store = new Store();
afterAll(() => store.close());

const DAY = 86_400_000;
const world = async (payloadCap?: number) => {
  const seam = testSeam("2026-06-01T08:00:00.000Z");
  const book = new Map<string, RegistryAnswer>();
  let regDown = false, polDown = false;
  const log = await EventLog.open(store, seam, { name: `audit-${crypto.randomUUID()}`, payloadCap });
  const actors = await ActorIdentity.open(store, seam, (ref) => (regDown ? { answer: "unreachable" } : book.get(ref) ?? { answer: "unknown-actor" }));
  const policies: PolicyRegistry = (ref) => (polDown ? { answer: "unreachable" } : ref === "seven-years" ? { answer: "policy", policy: { durationMs: 7 * 365 * DAY, maxPurgeDelayMs: 30 * DAY } } : { answer: "not-found" });
  const retention = await RetentionWindow.open(store, seam, policies, { resolutionMs: 1000 });
  const at = await AuditTrail.open(store, seam, { log, actors, retention }, { retentionPolicy: "seven-years", reconciliationOperator: "reconciliation-operator" });
  const enrol = (ref = `actor-${crypto.randomUUID()}`) => {
    const { publicKey, privateKey } = generateKeyPairSync("ed25519");
    const pub = publicKey.export({ format: "der", type: "spki" }).toString("base64");
    book.set(ref, { answer: "material", current: pub });
    return { ref, priv: privateKey.export({ format: "der", type: "pkcs8" }).toString("base64") };
  };
  return { seam, at, log, actors, retention, enrol, regDown: (v: boolean) => { regDown = v; }, polDown: (v: boolean) => { polDown = v; } };
};
const tail = async (w: Awaited<ReturnType<typeof world>>) => (await w.log.read({ sequence: { from: 1 } })) as { event_id: string; sequence_number: number; data: Record<string, unknown> }[];

test("Record action step 2 to 5, 7.1: a recorded action lands an attested event under retention, linked in the indexes, in one write", async () => {
  const w = await world();
  const a = w.enrol();
  const r = await w.at.recordAction("patient.viewed", a.ref, a.priv, { patient: "p123" }) as { event_id: string };
  const events = await tail(w);
  expect(events).toHaveLength(1);
  expect(events[0].event_id).toBe(r.event_id);
  const body = events[0].data as { action_ref: string; actor_ref: string; attestation_id: string; data: unknown };
  expect([body.action_ref, body.actor_ref, body.data]).toEqual(["patient.viewed", a.ref, { patient: "p123" }]);   // step 3.1: the full constructed payload
  expect(await w.actors.verify(body.attestation_id)).toBe("verified");                                           // step 2
  const ret = (await w.retention.read()).find((x) => x.record_ref === r.event_id)!;                              // step 4.3: record reference is the event id
  expect([ret.state, ret.retained_at]).toEqual(["retained", "2026-06-01T08:00:00.000Z"]);
  const idx = await w.at.indexOf(r.event_id);                                                                    // step 5.1, 5.2
  expect(idx).toEqual({ attestation_id: body.attestation_id, retention_id: ret.retention_id, sequence_number: events[0].sequence_number });
});

test("Primitive policy 10 to 14: the credential is consumed by the attest and written nowhere: not in the event, the attestation or the history", async () => {
  const w = await world();
  const a = w.enrol();
  const r = await w.at.recordAction("order.signed", a.ref, a.priv, { n: 1 }) as { event_id: string };
  expect(JSON.stringify(await store.history("events", r.event_id))).not.toContain(a.priv);
  expect(JSON.stringify(await w.actors.read())).not.toContain(a.priv);
});

test("Step 1, Primitive policy 1, 2, 5, 22, 23, 7.10: blank references and an oversize payload are invalid-request(step-1) and record nothing; empty data is valid", async () => {
  const w = await world(300);
  const a = w.enrol();
  const none = { refused: "invalid-request", step: "step-1", committed_ids: [] };
  expect(await w.at.recordAction(" ", a.ref, a.priv)).toEqual(none);
  expect(await w.at.recordAction("act", "", a.priv)).toEqual(none);
  expect(await w.at.recordAction("act", a.ref, a.priv, { big: "x".repeat(400) })).toEqual(none);
  expect(await tail(w)).toEqual([]);
  expect((await w.actors.read()).filter((x) => x.actor_ref === a.ref)).toHaveLength(0);
  expect("event_id" in (await w.at.recordAction("act", a.ref, a.priv))).toBe(true);                             // Primitive policy 23
});

test("Primitive policy 8, 9, 9a, step 1.4: the reserved namespace is the reconciliation operator's, for two references alone, each naming its subject", async () => {
  const w = await world();
  const a = w.enrol(), op = w.enrol("reconciliation-operator");
  const none = { refused: "invalid-request", step: "step-1", committed_ids: [] };
  expect(await w.at.recordAction("audit.compensation", a.ref, a.priv, { subject: "attestation", id: "x" })).toEqual(none);   // not the operator
  expect(await w.at.recordAction("audit.other", op.ref, op.priv, { subject: "attestation", id: "x" })).toEqual(none);          // not a reserved reference of the two
  expect(await w.at.recordAction("audit.compensation", op.ref, op.priv, { id: "x" })).toEqual(none);                           // no discriminator
  expect(await w.at.recordAction("audit.compensation", op.ref, op.priv, { subject: "attestation" })).toEqual(none);            // no id
  expect("event_id" in (await w.at.recordAction("audit.compensation", op.ref, op.priv, { subject: "attestation", id: "att-1" }))).toBe(true);
  expect("event_id" in (await w.at.recordAction("Audit.view", a.ref, a.priv))).toBe(true);                                     // `Audit.` is not reserved
});

test("Step 2.2, 2.4, 2.14: a credential that fails is invalid-credential unchanged; an unreachable registry is recording-failure(step-2); neither records", async () => {
  const w = await world();
  const a = w.enrol(), b = w.enrol();
  expect(await w.at.recordAction("act", a.ref, b.priv)).toEqual({ refused: "invalid-credential" });
  w.regDown(true);
  expect(await w.at.recordAction("act", a.ref, a.priv)).toEqual({ refused: "recording-failure", step: "step-2" });
  expect(await tail(w)).toEqual([]);
});

test("Step 4.6, 7.11, 7.16, 7.12: an unresolved policy is invalid-request(step-4) and keeps the attestation and the event committed, carrying both ids, with no retention", async () => {
  const w = await world();
  const a = w.enrol();
  const seam = w.seam;
  const bad = await AuditTrail.open(store, seam, { log: w.log, actors: w.actors, retention: w.retention }, { retentionPolicy: "no-such-policy", reconciliationOperator: "reconciliation-operator" });
  const r = await bad.recordAction("act", a.ref, a.priv, { n: 1 }) as { refused: string; step: string; committed_ids: string[] };
  expect([r.refused, r.step, r.committed_ids]).toEqual(["invalid-request", "step-4", [r.committed_ids[0], r.committed_ids[1]]]);
  const events = await tail(w);
  expect(events).toHaveLength(1);
  expect(events[0].event_id).toBe(r.committed_ids[1]);
  expect((events[0].data as { attestation_id: string }).attestation_id).toBe(r.committed_ids[0]);
  expect(await w.actors.verify(r.committed_ids[0])).toBe("verified");
  expect((await w.retention.read()).filter((x) => x.record_ref === r.committed_ids[1])).toHaveLength(0);
});

test("Step 4.10, 7.5: an unreachable policy registry is recording-failure(step-4) and commits nothing", async () => {
  const w = await world();
  const a = w.enrol();
  w.polDown(true);
  expect(await w.at.recordAction("act", a.ref, a.priv)).toEqual({ refused: "recording-failure", step: "step-4" });
  expect(await tail(w)).toEqual([]);
  expect((await w.actors.read()).filter((x) => x.actor_ref === a.ref)).toHaveLength(0);
});

test("Retention policy 3, Composes 4a: eight actions at once land eight events in one order, each with its own attestation and one retention; a policy selector reads the data", async () => {
  const w = await world();
  const a = w.enrol();
  const seen: string[] = [];
  const sel = await AuditTrail.open(store, w.seam, { log: w.log, actors: w.actors, retention: w.retention }, { retentionPolicy: (act, _actor, d) => { seen.push(`${act}:${(d as { k: number }).k}`); return "seven-years"; }, reconciliationOperator: "reconciliation-operator" });
  const out = await Promise.all(Array.from({ length: 8 }, (_, i) => sel.recordAction("act", a.ref, a.priv, { k: i })));
  expect(out.every((o) => "event_id" in o)).toBe(true);
  const events = await tail(w);
  expect(events.map((e) => e.sequence_number)).toEqual([1, 2, 3, 4, 5, 6, 7, 8]);
  expect(new Set(events.map((e) => (e.data as { attestation_id: string }).attestation_id)).size).toBe(8);
  for (const e of events) expect((await w.retention.read()).filter((r) => r.record_ref === e.event_id)).toHaveLength(1);
  expect(seen.length).toBeGreaterThanOrEqual(8);
});
