import { assert, assertEquals, assertThrows } from "@std/assert";
import { DAY, PAST_BOUND, POLICY, world } from "./helpers.ts";
import { actorIdentity } from "../src/atoms.ts";
import { AuditTrail, CriticalSection } from "../src/composition.ts";
import { openStore } from "../src/store.ts";
import { manualSeam } from "../src/seam.ts";
import { Faults } from "../src/faults.ts";
import { Vault } from "../src/vault.ts";
import { config } from "./helpers.ts";

const rr = (r: ReturnType<ReturnType<typeof world>["trail"]["read_record"]>) => { if (r === "not-known") throw new Error("not-known"); return r; };

Deno.test("record, read and verify: the whole happy path", () => {
  const w = world(), id = w.rec();
  const r = rr(w.trail.read_record(id));
  assertEquals([r.action_ref, r.actor_ref, r.data], ["doc.edit", "alice", { doc: "d1" }]);
  assert(typeof r.retention === "object" && r.retention.state === "Retained" && r.retention.policy_ref === POLICY.ref);
  assertEquals(r.coverage.status, "covered");
  assertEquals(w.trail.verify_record(id, w.presentation(id)), { outcome: "verified", compensationWindow: false });
  assertEquals(w.trail.read_record("event-999"), "not-known");
  assertEquals(w.trail.verify_record("event-999", []), "not-known");
});

Deno.test("a tampered or mismatched presentation fails the seal", () => {
  const w = world(), id = w.rec();
  assertEquals(w.trail.verify_record(id, ["forged"]), { outcome: { "failed-verification": "seal-proof-invalid" }, compensationWindow: false });
  assertEquals(w.trail.verify_record(id, []), { outcome: { "failed-verification": "seal-record-set-mismatch" }, compensationWindow: false });
});

Deno.test("step 1: the reserved namespace, blank and overlong references, the payload cap", () => {
  const w = world(), t = w.trail;
  assertEquals(t.record_action("audit.compensation", "alice", "alice_secret", {}), { refused: "invalid-request" });
  assertEquals(t.record_action("audit.other", "audit_op", "op_secret", {}), { refused: "invalid-request" });
  assertEquals(t.record_action("audit.compensation", "audit_op", "op_secret", { subject: "nothing" }), { refused: "invalid-request" });
  assertEquals(t.record_action("audit.compensation", "audit_op", "op_secret", { subject: "event" }), { refused: "invalid-request" });
  assertEquals(t.record_action(" ", "alice", "alice_secret", {}), { refused: "invalid-request" });
  assertEquals(t.record_action("a".repeat(1025), "alice", "alice_secret", {}), { refused: "invalid-request" });
  assertEquals(t.record_action("doc.edit", "alice", "alice_secret", { blob: "x".repeat(5000) }), { refused: "invalid-request" });
  assertEquals(t.record_action("doc.edit", "alice", "wrong", {}), { refused: "invalid-credential" });
  assertEquals(actorIdentity.read(w.db).length, 0, "no refusal at step 1 leaves an attestation");
});

Deno.test("recording failures name their step; step 3 and 4 leave what reconciliation finds", () => {
  const w = world(), t = w.trail;
  w.f.arm("identity.attest:doc.edit");
  assertEquals(t.record_action("doc.edit", "alice", "alice_secret", {}), { refused: "recording-failure", step: "step-2" });
  w.f.arm("log.append:doc.edit");
  assertEquals(t.record_action("doc.edit", "alice", "alice_secret", {}), { refused: "recording-failure", step: "step-3" });
  assertEquals(actorIdentity.read(w.db).length, 1, "an orphan attestation");
  w.f.arm("retention.place:doc.edit");
  assertEquals(t.record_action("doc.edit", "alice", "alice_secret", {}), { refused: "recording-failure", step: "step-4" });
  const ev = w.db.prepare("SELECT event_id FROM event").all<{ event_id: string }>();
  assertEquals(ev.length, 1, "an unretained event");
  const r = rr(t.read_record(ev[0].event_id));
  assertEquals(r.retention, "unresolved (compensation window)");
  assertEquals(r.coverage.status, "unsealed-tail", "step 4 refused before step 6 sealed");
  assertEquals(t.verify_record(ev[0].event_id, []), { outcome: { "failed-verification": "unsealed" }, compensationWindow: true });
});

Deno.test("the unsealed tail: strict refuses, lenient verifies, Seal Now covers", () => {
  const strict = world(() => ({ sealCadence: { kind: "on-demand" } })), id = strict.rec();
  assertEquals(rr(strict.trail.read_record(id)).coverage, { status: "unsealed-tail" });
  assertEquals(strict.trail.verify_record(id, []), { outcome: { "failed-verification": "unsealed" }, compensationWindow: false });
  const s = strict.trail.seal_now();
  assert("ok" in s);
  const cov = rr(strict.trail.read_record(id)).coverage;
  assert(cov.status === "covered" && cov.range[0] === 1 && cov.range[1] === 1);
  assertEquals(strict.trail.seal_now(), { refused: "nothing-to-seal" });
  const lenient = world(() => ({ sealCadence: { kind: "on-demand" }, unsealedTailMode: "lenient" })), id2 = lenient.rec();
  assertEquals(lenient.trail.verify_record(id2, []), { outcome: "verified", compensationWindow: false });
});

Deno.test("an interval cadence seals a run; the chain links seals", () => {
  const w = world(() => ({ sealCadence: { kind: "interval", events: 2 } }));
  const a = w.rec();
  assertEquals(rr(w.trail.read_record(a)).coverage.status, "unsealed-tail");
  const b = w.rec();
  const cov = rr(w.trail.read_record(b)).coverage;
  assert(cov.status === "covered" && cov.range[0] === 1 && cov.range[1] === 2);
  assertEquals(w.trail.verify_record(a, w.presentation(a)).valueOf(), { outcome: "verified", compensationWindow: false });
  const c = w.rec(), d = w.rec();
  assertEquals(w.trail.verify_record(d, w.presentation(d)), { outcome: "verified", compensationWindow: false });
  assert(c !== d);
});

Deno.test("a seal failure never rejects the action", () => {
  const w = world();
  w.f.arm("seal.mechanism");
  const id = w.rec();
  assertEquals(rr(w.trail.read_record(id)).coverage.status, "unsealed-tail");
  assertEquals(w.trail.alerts.map((a) => a.kind), ["seal-failure"]);
});

Deno.test("verify: registry and mechanism outages are unverifiable; a retired actor fails", () => {
  const w = world(), id = w.rec(), p = w.presentation(id);
  w.trail.registryUp = false;
  assertEquals(w.trail.verify_record(id, p), { outcome: { unverifiable: "attestation-registry-unavailable" }, compensationWindow: false });
  w.trail.registryUp = true; w.trail.mechanismUp = false;
  assertEquals(w.trail.verify_record(id, p), { outcome: { unverifiable: "seal-mechanism-verification-unavailable" }, compensationWindow: false });
  w.trail.mechanismUp = true;
  actorIdentity.retire(w.db, "alice");
  assertEquals(w.trail.verify_record(id, p), { outcome: { "failed-verification": "attestation-actor-unknown-in-registry" }, compensationWindow: false });
});

Deno.test("purge: refused before the deadline, under hold, unknown; then the whole cascade", () => {
  let held = true;
  const w = world(() => ({ legalHold: () => held })), id = w.rec();
  assertEquals(w.trail.purge_event(id), { refused: "under-legal-hold" });
  held = false;
  assertEquals(w.trail.purge_event(id), { refused: "not-eligible" });
  assertEquals(w.trail.purge_event("event-999"), { refused: "not-known" });
  w.seam.advance(POLICY.durationMs + 1);
  assert(w.trail.purge_eligible().includes(id));
  assertEquals(w.trail.purge_event(id), { ok: "ok" });
  assert(w.trail.closedEntry(id));
  const r = rr(w.trail.read_record(id));
  assertEquals([r.action_ref, r.actor_ref, r.data], ["doc.edit", "alice", null], "who and what survive through the pair; the data does not");
  assert(typeof r.retention === "object" && r.retention.state === "Purged");
  assertEquals(r.coverage.status, "records-purged");
  assertEquals(w.trail.verify_record(id, []), { outcome: { "failed-verification": "purged" }, compensationWindow: false });
  assertEquals(w.trail.purge_event(id), { ok: "ok" }, "a re-run over a closed entry resumes and adopts what landed");
  assertEquals(w.db.prepare("SELECT COUNT(*) AS n FROM erasure_outcome").get<{ n: number }>()!.n, 1, "no second delegation");
});

Deno.test("purge seals the tail first; a sibling reads partially-purged", () => {
  const w = world(() => ({ sealCadence: { kind: "on-demand" } }));
  const a = w.rec(), b = w.rec();
  w.seam.advance(POLICY.durationMs + 1);
  assertEquals(w.trail.purge_event(a), { ok: "ok" });
  const cov = rr(w.trail.read_record(b)).coverage;
  assert(cov.status === "partially-purged" && cov.range[1] === 2);
  assertEquals(w.trail.verify_record(b, []), { outcome: { unverifiable: "partially-purged-coverage" }, compensationWindow: false });
});

Deno.test("the first half skips a cascade whose section is held, and takes it on the next run", () => {
  const cs = new CriticalSection();
  const w = world(() => ({ criticalSection: cs })), id = w.rec();
  w.seam.advance(POLICY.durationMs + 1);
  w.f.arm(`erasure.fail:${id}`);
  assertEquals(w.trail.purge_event(id), { refused: "cascade-failure", step: "step-3" });
  w.seam.advance(PAST_BOUND);
  cs.take(id);
  w.trail.scan();
  assert(!w.trail.closedEntry(id));
  cs.release(id);
  w.trail.scan();
  assert(w.trail.closedEntry(id));
});

Deno.test("first half: a cascade stopped at step 2 or step 3 is re-driven to closure", () => {
  const w = world(), a = w.rec(), b = w.rec();
  w.seam.advance(POLICY.durationMs + 1);
  w.f.arm(`cascade.step2:${a}`);
  assertEquals(w.trail.purge_event(a), { refused: "cascade-failure", step: "step-2" });
  w.f.arm(`erasure.fail:${b}`);
  assertEquals(w.trail.purge_event(b), { refused: "cascade-failure", step: "step-3" });
  assert(w.trail.alerts.some((x) => x.kind === "divergence" && x.detail === b));
  w.trail.scan();
  assert(!w.trail.closedEntry(a), "inside the purge completion bound the scan waits");
  w.seam.advance(PAST_BOUND);
  w.trail.scan();
  assert(w.trail.closedEntry(a) && w.trail.closedEntry(b));
  assertEquals(w.trail.alerts.filter((x) => x.kind === "half-completed-cascade").map((x) => x.detail).sort(), [a, b].sort());
});

Deno.test("second half: an orphan attestation is narrated and compensated once", () => {
  const w = world();
  w.f.arm("log.append:doc.edit");
  w.trail.record_action("doc.edit", "alice", "alice_secret", {});
  const orphan = actorIdentity.read(w.db)[0].attestation_id;
  w.trail.scan();
  assertEquals(w.ops().length, 0, "inside the record action bound the scan waits");
  w.seam.advance(PAST_BOUND);
  w.trail.scan();
  w.trail.scan();
  const ops = w.ops().map((r) => [r.action_ref, (r.data as Record<string, unknown>).subject, (r.data as Record<string, unknown>).attestation_id]);
  assertEquals(ops, [["audit.reconciliation", "attestation", orphan], ["audit.compensation", "attestation", orphan]]);
  assert(w.trail.compensatedAttestations().has(orphan));
});

Deno.test("second half: an orphan beyond the horizon is reported, not compensated", () => {
  const w = world();
  w.f.arm("log.append:doc.edit");
  w.trail.record_action("doc.edit", "alice", "alice_secret", {});
  w.seam.advance(POLICY.durationMs + DAY);
  w.trail.scan();
  w.trail.scan();
  const ops = w.ops().map((r) => [r.action_ref, (r.data as Record<string, unknown>).disposition]);
  assertEquals(ops, [["audit.reconciliation", "beyond-horizon"]]);
});

Deno.test("third half: an unretained event is placed and compensated", () => {
  const w = world();
  w.f.arm("retention.place:doc.edit");
  w.trail.record_action("doc.edit", "alice", "alice_secret", { doc: "d9" });
  const id = w.db.prepare("SELECT event_id FROM event").get<{ event_id: string }>()!.event_id;
  w.seam.advance(PAST_BOUND);
  w.trail.scan();
  w.trail.scan();
  const r = rr(w.trail.read_record(id));
  assert(typeof r.retention === "object" && r.retention.state === "Retained");
  assertEquals(w.trail.verify_record(id, w.presentation(id)), { outcome: "verified", compensationWindow: false });
  const ops = w.ops().map((o) => [o.action_ref, (o.data as Record<string, unknown>).event_id]);
  assertEquals(ops, [["audit.reconciliation", id], ["audit.compensation", id]]);
});

Deno.test("Check 7.1: every derived index rebuilds from its sources", () => {
  const w = world();
  w.f.arm("index.write:doc.edit");
  const id = w.rec();
  assertEquals(w.db.prepare("SELECT COUNT(*) AS n FROM event_to_attestation").get<{ n: number }>()!.n, 0);
  assertEquals(w.trail.verify_record(id, w.presentation(id)), { outcome: "verified", compensationWindow: false });
  assertEquals(rr(w.trail.read_record(id)).attestation_id, actorIdentity.read(w.db)[0].attestation_id);
  const before = w.db.prepare("SELECT * FROM seal_coverage").all();
  w.db.exec("DELETE FROM seal_coverage");
  w.trail.rebuildCoverage();
  assertEquals(w.db.prepare("SELECT * FROM seal_coverage").all(), before);
});

Deno.test("instance start refuses a blank parameter and a short compensation window", () => {
  const db = openStore(), seam = manualSeam(), f = new Faults(), v = new Vault();
  assertThrows(() => AuditTrail.start(db, seam, f, v, { ...config(v, f), erasureMechanism: undefined }), Error, "erasureMechanism");
  assertThrows(() => AuditTrail.start(db, seam, f, v, { ...config(v, f), compensationWindowMs: 62_100 }), Error, "closure sum");
  const t = AuditTrail.start(db, seam, f, v, { ...config(v, f), reconciliationCadenceMs: undefined, sealCadence: { kind: "interval", timeMs: 30_000 } });
  assertEquals(t.c.reconciliationCadenceMs, 30_000);
  assertThrows(() => AuditTrail.start(db, seam, f, v, { ...config(v, f), reconciliationCadenceMs: undefined }), Error, "reconciliationCadenceMs");
});

Deno.test("a repair refused after its intent landed is written next run under the one intent", () => {
  const orphan = world();
  orphan.f.arm("log.append:doc.edit");
  orphan.trail.record_action("doc.edit", "alice", "alice_secret", {});
  orphan.seam.advance(PAST_BOUND);
  orphan.f.arm("log.append:audit.compensation");
  orphan.trail.scan();
  orphan.trail.scan();
  assertEquals(orphan.ops().map((r) => r.action_ref), ["audit.reconciliation", "audit.compensation"]);
  const unretained = world();
  unretained.f.arm("retention.place:doc.edit");
  unretained.trail.record_action("doc.edit", "alice", "alice_secret", {});
  unretained.seam.advance(PAST_BOUND);
  unretained.f.arm("retention.place:event-001");
  unretained.trail.scan();
  unretained.trail.scan();
  assertEquals(unretained.ops().map((r) => r.action_ref), ["audit.reconciliation", "audit.compensation"]);
  assertEquals(unretained.trail.alerts.filter((x) => x.kind === "reconciliation-write-refused").length, 0, "the placement, not a write, failed");
});
