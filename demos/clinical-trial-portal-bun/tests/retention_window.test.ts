// Retention Window, one test for each rule the render answers, named by the rule's label.
import { test, expect, afterAll } from "bun:test";
import { Store } from "../src/store.ts";
import { testSeam } from "../src/seam.ts";
import { RetentionWindow, type PolicyRegistry } from "../src/retention_window.ts";

const store = new Store();
afterAll(() => store.close());

const DAY = 86_400_000;
const policies: Record<string, { durationMs: number; maxPurgeDelayMs: number }> = {
  "sox-7y": { durationMs: 7 * 365 * DAY, maxPurgeDelayMs: 30 * DAY },
  "short": { durationMs: 10 * DAY, maxPurgeDelayMs: 0 },
  "zero": { durationMs: 0, maxPurgeDelayMs: DAY },
  "negative-delay": { durationMs: DAY, maxPurgeDelayMs: -1 },
  "unresolved": { durationMs: NaN, maxPurgeDelayMs: DAY },
  "unresolved-delay": { durationMs: DAY, maxPurgeDelayMs: NaN },
  "forever": { durationMs: 9e15, maxPurgeDelayMs: DAY },
};
const world = async (resolutionMs = 1000, destroy?: (r: string) => never[] | { text: string; params: string[] }[]) => {
  const seam = testSeam("2026-06-22T00:00:00.000Z");
  let down = false;
  const registry: PolicyRegistry = (ref) => (down ? { answer: "unreachable" } : policies[ref] ? { answer: "policy", policy: policies[ref] } : { answer: "not-found" });
  const rw = await RetentionWindow.open(store, seam, registry, { resolutionMs, destroy: destroy as never });
  return { seam, rw, outage: (v: boolean) => { down = v; } };
};
const rec = () => `txn-${crypto.randomUUID()}`;

test("Operation 1 to 3, State 2 to 6: a placement records one retained retention with its two deadlines from the policy", async () => {
  const { rw } = await world();
  const r = rec();
  const p = await rw.place(r, "short") as { retention_id: string };
  const row = (await rw.read()).find((x) => x.retention_id === p.retention_id)!;
  expect([row.record_ref, row.policy_ref, row.state, row.retained_at, row.retention_until, row.purge_deadline]).toEqual([r, "short", "retained", "2026-06-22T00:00:00.000Z", "2026-07-02T00:00:00.000Z", "2026-07-02T00:00:00.000Z"]);
  const sox = await rw.place(rec(), "sox-7y") as { retention_id: string };
  const s = (await rw.read()).find((x) => x.retention_id === sox.retention_id)!;
  expect(Date.parse(s.purge_deadline) - Date.parse(s.retention_until)).toBe(30 * DAY);
});

test("State 4a, 6a: the instants round up to the time resolution", async () => {
  const { rw, seam } = await world(60_000);                       // one minute
  seam.set("2026-06-22T00:00:00.500Z");
  const p = await rw.place(rec(), "short") as { retention_id: string };
  const row = (await rw.read()).find((x) => x.retention_id === p.retention_id)!;
  expect(row.retained_at).toBe("2026-06-22T00:01:00.000Z");
  expect(row.retention_until).toBe("2026-07-02T00:01:00.000Z");
});

test("Operation 4 to 8c, 24b: blank references, an unknown policy, an unreadable registry and each invalid policy are refused apart, and record nothing", async () => {
  const w = await world();
  const before = (await w.rw.read()).length;
  expect(await w.rw.place(" ", "short")).toEqual({ refused: "invalid-request" });
  expect(await w.rw.place(rec(), "")).toEqual({ refused: "invalid-request" });
  expect(await w.rw.place(rec(), "no-such-policy")).toEqual({ refused: "policy-not-found" });
  for (const bad of ["zero", "negative-delay", "unresolved", "unresolved-delay", "forever"]) expect(await w.rw.place(rec(), bad)).toEqual({ refused: "invalid-policy" });
  w.outage(true);
  expect(await w.rw.place(rec(), "short")).toEqual({ refused: "registry-unavailable" });
  expect((await w.rw.read()).length).toBe(before);
});

test("Operation 16, 17, Invariant 7.1: a purge before the retention deadline is refused and writes nothing; the boundary instant is eligible", async () => {
  const { rw, seam } = await world();
  const p = await rw.place(rec(), "short") as { retention_id: string };
  seam.set("2026-07-01T23:59:59.000Z");
  expect(await rw.purge(p.retention_id)).toEqual({ refused: "retention-period-not-elapsed" });
  expect((await rw.read()).find((x) => x.retention_id === p.retention_id)!.purge_eligible).toBe("no");
  expect(await store.history("retentions", p.retention_id)).toHaveLength(1);
  seam.set("2026-07-02T00:00:00.000Z");
  expect((await rw.read()).find((x) => x.retention_id === p.retention_id)!.purge_eligible).toBe("yes");
  expect(await rw.purge(p.retention_id)).toBe("ok");
});

test("Operation 12, 13, 15, 18, Invariant 3, 5, 8.1: a purge stands the retention purged with its instant, leaves every earlier field, is not repeated, and is not refused when late", async () => {
  const { rw, seam } = await world();
  const p = await rw.place(rec(), "sox-7y") as { retention_id: string };
  seam.set("2040-01-01T00:00:00.000Z");                           // years past the purge deadline
  expect(await rw.purge(p.retention_id)).toBe("ok");
  expect(await rw.purge(p.retention_id)).toEqual({ refused: "not-retained" });
  expect(await rw.purge("no-such-retention")).toEqual({ refused: "not-known" });
  const row = (await rw.read()).find((x) => x.retention_id === p.retention_id)!;
  expect([row.state, row.purged_at, row.purge_eligible]).toEqual(["purged", "2040-01-01T00:00:00.000Z", null]);
  expect(Date.parse(row.purged_at!)).toBeGreaterThanOrEqual(Date.parse(row.retention_until));
  const versions = await store.history("retentions", p.retention_id);
  expect(versions.map((v) => v.state)).toEqual(["retained", "purged"]);
  expect([versions[0].retained_at, versions[0].retention_until, versions[0].purge_deadline, versions[0].record_ref]).toEqual([versions[1].retained_at, versions[1].retention_until, versions[1].purge_deadline, versions[1].record_ref]);
});

test("Operation 13b: where no composing pattern owns the destruction, the purge removes every version of the record in the same write", async () => {
  const table = `docs_${crypto.randomUUID().replaceAll("-", "_")}`;
  await store.commit([store.put(table, { _id: "d1", body: "v1" })]);
  await store.commit([store.put(table, { _id: "d1", body: "v2" })]);
  const { rw, seam } = await world(1000, (ref) => [{ text: `ERASE FROM ${table} WHERE _id = $1`, params: [ref] }]);
  const p = await rw.place("d1", "short") as { retention_id: string };
  seam.set("2026-07-02T00:00:00.000Z");
  expect((await store.history(table, "d1")).length).toBe(2);
  expect(await rw.purge(p.retention_id)).toBe("ok");
  expect(await store.history(table, "d1")).toHaveLength(0);
  expect((await rw.read()).find((x) => x.retention_id === p.retention_id)!.state).toBe("purged");
});

test("Invariant 9.1, 10.1, 11.1, Identity 9, Operation 29, 32: two retentions over one record carry two ids; the retention set only grows; a read carries eligibility only while retained and writes nothing", async () => {
  const { rw } = await world();
  const r = rec();
  const a = await rw.place(r, "short") as { retention_id: string };
  const b = await rw.place(r, "sox-7y") as { retention_id: string };
  expect(a.retention_id).not.toBe(b.retention_id);
  const n = (await rw.read()).length;
  await rw.read();
  expect((await rw.read()).length).toBe(n);
  expect(await store.history("retentions", a.retention_id)).toHaveLength(1);
});
