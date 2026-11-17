// Party Identity, one test for each rule the render answers, named by the rule's label.
import { test, expect, afterAll } from "bun:test";
import { Store } from "../src/store.ts";
import { testSeam } from "../src/seam.ts";
import { PartyIdentity, type PartyView } from "../src/party_identity.ts";

const store = new Store();
afterAll(() => store.close());

const world = async () => {
  const seam = testSeam("2026-06-01T09:00:00.000Z");
  const px = `pi_${crypto.randomUUID().replaceAll("-", "_")}`;
  return { seam, pi: await PartyIdentity.open(store, seam, { table: `${px}_p`, headTable: `${px}_h` }) };
};
const enroll = async (pi: PartyIdentity) => (await pi.enroll("Ada Byron", "1984-03-02", "passport", "P-123", "officer-1") as { party_id: string }).party_id;
const one = async (pi: PartyIdentity, id: string) => ((await pi.read({ party_id: id })) as PartyView[])[0];

test("Operation 4 to 8, State 1 to 3: an enroll records every enrollment field, stands the party unverified with empty lists, and answers its id", async () => {
  const { pi } = await world();
  const id = await enroll(pi);
  expect(await one(pi, id)).toEqual({ party_id: id, name: "Ada Byron", date_of_birth: "1984-03-02", document_type: "passport", document_ref: "P-123", enrolled_at: "2026-06-01T09:00:00.000Z", enrolling_actor_ref: "officer-1", state: "unverified", state_changes: [], verifications: [] });
});

test("Operation 1 to 3, 9, 42: a blank required string, a date that is no calendar date, a date after now and an over-long string are invalid-request and record nothing", async () => {
  const { pi } = await world();
  for (const args of [["", "1984-03-02", "passport", "P-1", "o"], ["n", "1984-03-02", " ", "P-1", "o"], ["n", "1984-03-02", "passport", "", "o"], ["n", "1984-03-02", "passport", "P-1", ""],
    ["n", "1984-02-30", "passport", "P-1", "o"], ["n", "02/03/1984", "passport", "P-1", "o"], ["n", "2026-06-02", "passport", "P-1", "o"], ["x".repeat(257), "1984-03-02", "passport", "P-1", "o"]] as [string, string, string, string, string][])
    expect(await pi.enroll(...args)).toEqual({ refused: "invalid-request" });
  expect(await pi.read()).toEqual([]);
  expect("party_id" in (await pi.enroll("n", "2026-06-01", "passport", "P-1", "o"))).toBe(true);        // today is not after today
});

test("Operation 21 to 29, 36: a passed verify on an unverified party appends the event, drives unverified to verified with a state change that carries no reason, and answers both ids; a failed one appends only the event", async () => {
  const { pi } = await world();
  const a = await enroll(pi), b = await enroll(pi);
  expect(await pi.verify(a, "v-1", "document-scan", "failed", "ev-1")).toEqual({ verification_id: expect.any(String) });
  expect((await one(pi, a)).state).toBe("unverified");
  const r = await pi.verify(a, "v-1", "document-scan", "passed", "ev-2") as { verification_id: string; state_change_id: string };
  expect(r.state_change_id).toBeTruthy();
  const pa = await one(pi, a);
  expect(pa.state).toBe("verified");
  expect(pa.verifications.map((v) => [v.verification_result, v.verifying_actor_ref, v.verification_method, v.evidence_ref])).toEqual([["failed", "v-1", "document-scan", "ev-1"], ["passed", "v-1", "document-scan", "ev-2"]]);
  expect(pa.state_changes).toHaveLength(1);
  expect([pa.state_changes[0].prior_state, pa.state_changes[0].new_state, pa.state_changes[0].acting_ref, pa.state_changes[0].reason]).toEqual(["unverified", "verified", "v-1", undefined]);
  const again = await pi.verify(a, "v-2", "biometric", "passed", "ev-3");                                  // a verified party: an event, no transition
  expect("state_change_id" in again).toBe(false);
  expect((await one(pi, a)).state_changes).toHaveLength(1);
  expect((await one(pi, b)).verifications).toEqual([]);
  expect(await pi.verify(a, "v-1", "m", "maybe", "e")).toEqual({ refused: "invalid-request" });
});

test("Operation 10 to 16: blank id is invalid-request, an unknown id not-known, a closed party already-closed for every action, an unverified party not-verifiable to suspend and not-suspended to reinstate", async () => {
  const { pi } = await world();
  const id = await enroll(pi);
  expect(await pi.verify(" ", "v", "m", "passed", "e")).toEqual({ refused: "invalid-request" });
  expect(await pi.verify("no-such-party", "v", "m", "passed", "e")).toEqual({ refused: "not-known" });
  expect(await pi.suspend(id, "o", "why")).toEqual({ refused: "not-verifiable" });
  expect(await pi.reinstate(id, "o", "why")).toEqual({ refused: "not-suspended" });
  const c = await pi.close(id, "o", "left the programme");
  expect("state_change_id" in c).toBe(true);
  for (const r of [await pi.verify(id, "v", "m", "passed", "e"), await pi.suspend(id, "o", "r"), await pi.reinstate(id, "o", "r"), await pi.close(id, "o", "r")]) expect(r).toEqual({ refused: "already-closed" });
});

test("Operation 14, 15, 18, 30, 31, 35, Term fresh verification: suspend then reinstate; a suspended party is already-suspended, and cannot be reinstated without a passed verification appended after the suspend", async () => {
  const { pi, seam } = await world();
  const id = await enroll(pi);
  await pi.verify(id, "v", "scan", "passed", "ev-1");
  const s = await pi.suspend(id, "officer-2", "sanctions hit") as { state_change_id: string };
  expect(s.state_change_id).toBeTruthy();
  expect((await one(pi, id)).state).toBe("suspended");
  expect(await pi.suspend(id, "officer-2", "again")).toEqual({ refused: "already-suspended" });
  expect(await pi.reinstate(id, "officer-2", "cleared")).toEqual({ refused: "no-passed-verification-since-suspend" });   // the earlier pass came before the suspend
  seam.advance(1000);
  await pi.verify(id, "v", "scan", "failed", "ev-2");
  expect(await pi.reinstate(id, "officer-2", "cleared")).toEqual({ refused: "no-passed-verification-since-suspend" });   // a failed one does not count
  await pi.verify(id, "v", "scan", "passed", "ev-3");
  expect((await one(pi, id)).state).toBe("suspended");                                                    // a verify drives no transition from suspended (Operation 26)
  const r = await pi.reinstate(id, "officer-2", "cleared") as { state_change_id: string };
  expect(r.state_change_id).toBeTruthy();
  const p = await one(pi, id);
  expect(p.state).toBe("verified");
  expect(p.state_changes.map((c) => [c.prior_state, c.new_state, c.reason])).toEqual([["unverified", "verified", undefined], ["verified", "suspended", "sanctions hit"], ["suspended", "verified", "cleared"]]);
  expect(await pi.suspend(id, "officer-2", "")).toEqual({ refused: "invalid-request" });                  // a reason is required, after the state checks (Operation 1)
});

test("Operation 1, 41, 43: a refused action leaves the party as it found it; the state check comes before the call's other inputs", async () => {
  const { pi } = await world();
  const id = await enroll(pi);
  const before = await one(pi, id);
  expect(await pi.suspend(id, "", "")).toEqual({ refused: "not-verifiable" });                           // the state check answers first
  expect(await pi.verify(id, "", "m", "passed", "e")).toEqual({ refused: "invalid-request" });
  expect(await one(pi, id)).toEqual(before);
});

test("Operation 44 to 47, Invariant: the lists only grow, each version of the party keeps the earlier lists, enrollment fields never change", async () => {
  const { pi } = await world();
  const id = await enroll(pi);
  await pi.verify(id, "v", "m", "passed", "e1"); await pi.suspend(id, "o", "r"); await pi.verify(id, "v", "m", "passed", "e2"); await pi.reinstate(id, "o", "r2");
  const versions = await store.history((pi as unknown as { T: string }).T, id);
  expect(versions.map((v) => v.state)).toEqual(["unverified", "verified", "suspended", "suspended", "verified"]);   // enroll, verify (passed: verified), suspend, verify (no transition), reinstate
  const lens = versions.map((v) => JSON.parse(String(v.verifications)).length + JSON.parse(String(v.state_changes)).length);
  expect(lens.every((n, i) => i === 0 || n >= lens[i - 1])).toBe(true);
  expect(new Set(versions.map((v) => `${v.name}|${v.date_of_birth}|${v.document_type}|${v.document_ref}|${v.enrolled_at}|${v.enrolling_actor_ref}`)).size).toBe(1);
});

test("Operation 48 to 54, 61: a read answers every matching party in insertion order; an unreadable filter is invalid-query and is not ignored; none matching answers empty", async () => {
  const { pi, seam } = await world();
  const ids: string[] = [];
  for (let i = 0; i < 3; i++) { ids.push(await enroll(pi)); seam.advance(1000); }
  await pi.verify(ids[1], "v", "m", "passed", "e");
  expect(((await pi.read()) as PartyView[]).map((p) => p.party_id)).toEqual(ids);
  expect(((await pi.read({ state: "verified" })) as PartyView[]).map((p) => p.party_id)).toEqual([ids[1]]);
  expect(((await pi.read({ state: "unverified" })) as PartyView[]).map((p) => p.party_id)).toEqual([ids[0], ids[2]]);
  expect(((await pi.read({ enrolled: { from: "2026-06-01T09:00:01.000Z", to: "2026-06-01T09:00:02.000Z" } })) as PartyView[]).map((p) => p.party_id)).toEqual([ids[1], ids[2]]);
  expect(await pi.read({ party_id: "no-such-party" })).toEqual([]);
  for (const bad of [{ colour: "red" }, { state: "dormant" }, { party_id: " " }, { enrolled: { from: "2026-06-01T09:00:00Z" } }, { enrolled: { from: "2026-06-02T00:00:00Z", to: "2026-06-01T00:00:00Z" } }] as never[])
    expect(await pi.read(bad)).toEqual({ refused: "invalid-query" });
});

test("Database 2: ten enrollments at once land ten parties in ten distinct places of the insertion order; two verifies at once on one party both land", async () => {
  const { pi } = await world();
  const out = await Promise.all(Array.from({ length: 10 }, () => pi.enroll("n", "1990-01-01", "id", "d", "o")));
  expect(out.every((o) => "party_id" in o)).toBe(true);
  const all = await pi.read() as PartyView[];
  expect(all).toHaveLength(10);
  const id = all[0].party_id;
  await Promise.all([pi.verify(id, "v1", "m", "failed", "e1"), pi.verify(id, "v2", "m", "failed", "e2")]);
  expect((await one(pi, id)).verifications.map((v) => v.insertion).sort()).toEqual([1, 2]);
});
