// Audit Trail's [Seal Now], [Read Record] and [Verify Record], one test for each rule the render answers.
import { test, expect, afterAll } from "bun:test";
import { generateKeyPairSync } from "node:crypto";
import { Store } from "../src/store.ts";
import { testSeam } from "../src/seam.ts";
import { EventLog } from "../src/event_log.ts";
import { ActorIdentity, type RegistryAnswer } from "../src/actor_identity.ts";
import { RetentionWindow } from "../src/retention_window.ts";
import { TamperEvidence, sha256Chain } from "../src/tamper_evidence.ts";
import { LeaseHost } from "../src/lease.ts";
import { AuditTrail, matchBySliceCount, type AuditRecord } from "../src/audit_trail.ts";
import { canonical } from "../src/canonical.ts";

const store = new Store();
afterAll(() => store.close());
const DAY = 86_400_000;

const world = async (mode: "strict" | "lenient" = "strict") => {
  const seam = testSeam("2026-06-01T08:00:00.000Z");
  const px = `at_${crypto.randomUUID().replaceAll("-", "_")}_`;
  const book = new Map<string, RegistryAnswer>();
  let regDown = false;
  const log = await EventLog.open(store, seam, { name: `trail-${crypto.randomUUID()}` });
  const actors = await ActorIdentity.open(store, seam, (r) => (regDown ? { answer: "unreachable" } : book.get(r) ?? { answer: "unknown-actor" }));
  const retention = await RetentionWindow.open(store, seam, () => ({ answer: "policy", policy: { durationMs: 7 * 365 * DAY, maxPurgeDelayMs: 30 * DAY } }), { resolutionMs: 1000, prefix: px } as never);
  const tamper = await TamperEvidence.open(store, seam, sha256Chain(matchBySliceCount));
  const lease = await LeaseHost.open(store, seam, { prefix: px, pollMs: 50 });
  const at = await AuditTrail.open(store, seam, { log, actors, retention }, { retentionPolicy: "seven-years", reconciliationOperator: "op", sealing: { tamper, lease, mechanismCredential: "", sliceCap: 3, unsealedTailMode: mode } });
  const k = generateKeyPairSync("ed25519");
  const a = { ref: `actor-${crypto.randomUUID()}`, priv: k.privateKey.export({ format: "der", type: "pkcs8" }).toString("base64") };
  book.set(a.ref, { answer: "material", current: k.publicKey.export({ format: "der", type: "spki" }).toString("base64") });
  const record = async (n = 1) => { const ids: string[] = []; for (let i = 0; i < n; i++) ids.push(((await at.recordAction("patient.viewed", a.ref, a.priv, { i })) as { event_id: string }).event_id); return ids; };
  const payloads = async (from: number, to: number) => ((await log.read({ sequence: { from, to } })) as { data: unknown }[]).map((e) => canonical(e.data));
  return { seam, at, log, tamper, record, payloads, regDown: (v: boolean) => { regDown = v; } };
};

test("Seal now 1 to 5, 17, 21, seal coverage 13, 14: a seal covers the slice from sealed through plus one, up to the slice cap, names it by first, last and count, and advances; nothing to seal answers nothing-to-seal", async () => {
  const w = await world();
  expect(await w.at.sealNow()).toEqual({ refused: "nothing-to-seal" });
  await w.record(5);
  const first = await w.at.sealNow() as { evidence_id: string };
  const ev = (await w.tamper.read()).find((e) => e.evidence_id === first.evidence_id)!;
  expect(ev.record_set_ref).toBe("slice:1-3:3");                                                            // the cap is three
  const second = await w.at.sealNow() as { evidence_id: string };
  expect((await w.tamper.read()).find((e) => e.evidence_id === second.evidence_id)!.record_set_ref).toBe("slice:4-5:2");
  expect(await w.at.sealNow()).toEqual({ refused: "nothing-to-seal" });
});

test("Seal coverage 7, 8, Composes 17: two seals never overlap and never leave a hole; two sealings at once, serialized by the lock, cover each event once", async () => {
  const w = await world();
  await w.record(6);
  const out = await Promise.all([w.at.sealNow(), w.at.sealNow(), w.at.sealNow()]);
  const ok = out.filter((o) => "evidence_id" in o);
  expect(ok).toHaveLength(2);                                                                                 // 6 events, cap 3: two slices; the third finds nothing to seal
  const mine = new Set(ok.map((o) => (o as { evidence_id: string }).evidence_id));
  const refs = (await w.tamper.read()).filter((e) => mine.has(e.evidence_id)).map((e) => e.record_set_ref).sort();
  expect(refs).toEqual(["slice:1-3:3", "slice:4-6:3"]);                                                      // no overlap, no hole
});

test("Read record 1 to 4, step 4.1 to 4.3, 5.1, 5.2: a record is the event with its attestation, retention and coverage (covered with its seal, or unsealed tail); an unknown id is not-known; reading changes nothing", async () => {
  const w = await world();
  const [a, b, c, d] = await w.record(4);
  await w.at.sealNow();                                                                                       // seals 1 to 3
  const rec = await w.at.readRecord(a) as AuditRecord;
  expect([rec.action_ref, rec.sequence_number, rec.data]).toEqual(["patient.viewed", 1, { i: 0 }]);
  expect(rec.retention).toMatchObject({ state: "retained" });
  expect(rec.coverage).toMatchObject({ status: "covered", first: 1, last: 3 });
  expect((await w.at.readRecord(d) as AuditRecord).coverage).toEqual({ status: "unsealed-tail" });
  expect(await w.at.readRecord("no-such-event")).toBe("not-known");
  expect((await w.log.read({ sequence: { from: 1 } }) as unknown[]).length).toBe(4);                        // no audit event was produced by reading
  void b; void c;
});

test("Verify record steps 1 to 7: a sealed event with its range presented byte-exact verifies; a changed byte fails with seal-proof-invalid; the wrong count is seal-record-set-mismatch", async () => {
  const w = await world();
  const [a] = await w.record(3);
  await w.at.sealNow();
  const range = await w.payloads(1, 3);
  expect(await w.at.verifyRecord(a, range)).toEqual({ outcome: "verified" });
  const changed = [...range]; changed[1] = changed[1].replace("1", "9");
  expect(await w.at.verifyRecord(a, changed)).toEqual({ outcome: { failed: "seal-proof-invalid" } });
  expect(await w.at.verifyRecord(a, range.slice(0, 2))).toEqual({ outcome: { failed: "seal-record-set-mismatch" } });
});

test("Verify record step 4.4, 4.5: an event in the unsealed tail fails with unsealed in strict mode; lenient takes coverage as satisfied", async () => {
  const strict = await world("strict");
  const [x] = await strict.record(1);
  expect(await strict.at.verifyRecord(x, await strict.payloads(1, 1))).toEqual({ outcome: { failed: "unsealed" } });
  const lenient = await world("lenient");
  const [y] = await lenient.record(1);
  expect(await lenient.at.verifyRecord(y, await lenient.payloads(1, 1))).toEqual({ outcome: "verified" });
});

test("Verify record step 3.1 to 3.4, 6.1: an attestation that fails is failed-verification prefixed attestation-, with the seal not consulted; an unreachable registry is unverifiable(attestation-registry-unavailable); an unknown id is not-known", async () => {
  const w = await world();
  const [a] = await w.record(1);
  await w.at.sealNow();
  w.regDown(true);
  expect(await w.at.verifyRecord(a, await w.payloads(1, 1))).toEqual({ outcome: { unverifiable: "attestation-registry-unavailable" } });
  w.regDown(false);
  expect(await w.at.verifyRecord("no-such-event", [])).toBe("not-known");
});

test("Verify record 1, 4, step 2.2: an event that has no retention record and no log entry is not-known and carries no qualifier; a sealed event with its retention record carries none either", async () => {
  const w = await world();
  const [a] = await w.record(1);
  await w.at.sealNow();
  expect(await w.at.verifyRecord("no-such-event", [])).toBe("not-known");
  expect(await w.at.verifyRecord(a, await w.payloads(1, 1))).toEqual({ outcome: "verified" });                // no `qualifier` key: the compensation window is the orphan case, untested here (named in the entry)
});

test("Seal now 15, 16, 22, 23: the uncovered mark is set with this seal's holder before the seal call and cleared by a compare after the coverage landed; its history shows both", async () => {
  const w = await world();
  await w.record(2);
  await w.at.sealNow();
  const versions = await store.history("uncovered_mark", `mark:${w.log.logName}`);
  expect(versions.map((v) => v.state)).toEqual(["set", "clear"]);
  expect(versions[0].holder).toBe(versions[1].holder);
});

test("Verify record step 3.2: an attestation whose proof no longer holds is failed-verification prefixed attestation-, and the seal is not consulted (no covering seal needed)", async () => {
  const w = await world();
  const [a] = await w.record(1);
  const ev = (await w.log.read({ sequence: { from: 1, to: 1 } })) as { data: { attestation_id: string } }[];
  const id = ev[0].data.attestation_id;
  const row = (await store.read<Record<string, string>>(`SELECT * FROM attestations WHERE _id = $1`, [id]))[0];
  await store.commit([store.put("attestations", { ...row, _id: id, action_ref: "forged.action" } as never)]);
  expect(await w.at.verifyRecord(a, [])).toEqual({ outcome: { failed: "attestation-proof-invalid" } });
});

test("Seal now 20: where the sealing lock cannot be taken (the take answers unavailable) the seal answers recording-failure and seals nothing", async () => {
  const w = await world();
  await w.record(2);
  const sealing = (w.at as unknown as { cfg: { sealing: { lease: unknown } } }).cfg.sealing;
  const real = sealing.lease;
  sealing.lease = { take: async () => "unavailable", remaining: async () => ({ remaining_ms: 1000 }), release: async () => "not-held" };
  try {
    const before = (await w.tamper.read()).length;
    expect(await w.at.sealNow()).toEqual({ refused: "recording-failure" });
    expect((await w.tamper.read()).length).toBe(before);
  } finally { sealing.lease = real; }
});
