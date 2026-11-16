// Tamper Evidence, one test for each rule the render answers, named by the rule's label.
import { test, expect, afterAll } from "bun:test";
import { Store } from "../src/store.ts";
import { testSeam } from "../src/seam.ts";
import { TamperEvidence, sha256Chain, hmacChain, type Mechanism } from "../src/tamper_evidence.ts";

const store = new Store();
afterAll(() => store.close());

// A record set here is { ref, records }; the host's match is that the presented set carries the reference.
type RS = { ref: string; records: unknown[] };
const same: Mechanism["match"] = (ref, original) => (original as RS).ref === ref;
const asRecords = (m: Mechanism): Mechanism => ({
  ...m,
  compute: (rs, k) => m.compute((rs as RS).records, k),
  check: (p, o, k) => m.check(p, (o as RS).records, k),
});
const journal = (ref = `journal-${crypto.randomUUID()}`): RS => ({ ref, records: [{ n: 1, amount: 500 }, { n: 2, amount: -100 }, { n: 3, amount: 25 }] });
const world = async (mech: Mechanism = asRecords(sha256Chain(same))) => {
  const seam = testSeam("2026-05-10T23:59:00.000Z");
  return { seam, te: await TamperEvidence.open(store, seam, mech) };
};

test("Operation 1 to 3, State 3, 5: a seal records one evidence with its proof and sealing instant, and the credential is stored nowhere", async () => {
  const { te } = await world(asRecords(hmacChain(same)));
  const rs = journal();
  const r = await te.seal(rs.ref, "signing-key-xyz", rs) as { evidence_id: string };
  const all = (await te.read()).filter((e) => e.evidence_id === r.evidence_id);
  expect(all).toHaveLength(1);
  expect([all[0].record_set_ref, all[0].sealed_at, all[0].anchored_at]).toEqual([rs.ref, "2026-05-10T23:59:00.000Z", null]);
  expect(JSON.stringify(await store.history("evidence", r.evidence_id))).not.toContain("signing-key-xyz");
});

test("Operation 19, 33: the records as sealed verify", async () => {
  const { te } = await world();
  const rs = journal();
  const { evidence_id } = await te.seal(rs.ref, "", rs) as { evidence_id: string };
  expect(await te.verify(evidence_id, journal(rs.ref))).toBe("verified");
});

test("Operation 18, Invariant 2.1, 3.2, Check 3.1: a single changed byte of a record fails with proof-invalid; a reordered or dropped record too", async () => {
  const { te } = await world();
  const rs = journal();
  const { evidence_id } = await te.seal(rs.ref, "", rs) as { evidence_id: string };
  const changed = journal(rs.ref); (changed.records[1] as { amount: number }).amount = -101;
  expect(await te.verify(evidence_id, changed)).toEqual({ failed: "proof-invalid" });
  const dropped = journal(rs.ref); dropped.records.pop();
  expect(await te.verify(evidence_id, dropped)).toEqual({ failed: "proof-invalid" });
  const swapped = journal(rs.ref); swapped.records.reverse();
  expect(await te.verify(evidence_id, swapped)).toEqual({ failed: "proof-invalid" });
});

test("Operation 15, 16: an unknown evidence id is not-known; the wrong record set is record-set-mismatch, not a tampering signal", async () => {
  const { te } = await world();
  const rs = journal();
  const { evidence_id } = await te.seal(rs.ref, "", rs) as { evidence_id: string };
  expect(await te.verify("no-such-evidence", rs)).toBe("not-known");
  expect(await te.verify(evidence_id, journal("journal-other-day"))).toEqual({ failed: "record-set-mismatch" });
});

test("Operation 6, 7, 8, 34: blank reference, blank credential for a keyed mechanism and a string over the cap are invalid-request; an unkeyed mechanism takes a blank credential", async () => {
  const keyed = await world(asRecords(hmacChain(same)));
  expect(await keyed.te.seal(" ", "k", journal())).toEqual({ refused: "invalid-request" });
  expect(await keyed.te.seal("ref-1", "", journal("ref-1"))).toEqual({ refused: "invalid-request" });
  expect(await keyed.te.seal("x".repeat(4097), "k", journal())).toEqual({ refused: "invalid-request" });
  expect(await keyed.te.seal("ref-2", "k".repeat(4097), journal("ref-2"))).toEqual({ refused: "invalid-request" });
  const open = await world();
  expect("evidence_id" in (await open.te.seal("ref-3", "", journal("ref-3")))).toBe(true);
});

test("Operation 9: a mechanism that cannot compute answers mechanism-failure with its reason and records nothing", async () => {
  const { te } = await world();
  const before = (await te.read()).length;
  expect(await te.seal("ref-bad", "", { ref: "ref-bad", records: "not a list" })).toEqual({ mechanism_failure: "unreadable-records" });
  expect((await te.read()).length).toBe(before);
});

test("Invariant 4.1, 8.2, Capability requirement 9, Operation 17: a keyed proof verifies under its key; with the key unavailable the answer is mechanism-verification-unavailable; a wrong key is proof-invalid", async () => {
  const { te } = await world(asRecords(hmacChain(same)));
  const rs = journal();
  const { evidence_id } = await te.seal(rs.ref, "key-a", rs) as { evidence_id: string };
  expect(await te.verify(evidence_id, journal(rs.ref), "key-a")).toBe("verified");
  expect(await te.verify(evidence_id, journal(rs.ref), "key-b")).toEqual({ failed: "proof-invalid" });
  expect(await te.verify(evidence_id, journal(rs.ref))).toEqual({ failed: "mechanism-verification-unavailable" });
});

test("Invariant 7.1: two verifications of one evidence against one record set answer alike", async () => {
  const { te } = await world();
  const rs = journal();
  const { evidence_id } = await te.seal(rs.ref, "", rs) as { evidence_id: string };
  const bad = journal(rs.ref); bad.records.push({ n: 4 });
  expect(await te.verify(evidence_id, bad)).toEqual(await te.verify(evidence_id, bad));
});

test("Identity 8, Invariant 1.1, 5.2, 6.1, Operation 20, 29: two seals over one record set carry two ids; an evidence is one version, and verify and read write nothing", async () => {
  const { te } = await world();
  const rs = journal();
  const a = await te.seal(rs.ref, "", rs) as { evidence_id: string };
  const b = await te.seal(rs.ref, "", rs) as { evidence_id: string };
  expect(a.evidence_id).not.toBe(b.evidence_id);
  await te.verify(a.evidence_id, rs); await te.read();
  expect(await store.history("evidence", a.evidence_id)).toHaveLength(1);
});
