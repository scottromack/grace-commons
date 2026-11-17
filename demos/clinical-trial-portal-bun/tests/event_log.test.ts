// Event Log, one test for each rule the render answers, named by the rule's label.
import { test, expect, afterAll } from "bun:test";
import { Store } from "../src/store.ts";
import { testSeam } from "../src/seam.ts";
import { EventLog, type LoggedEvent } from "../src/event_log.ts";

const store = new Store();
afterAll(() => store.close());

const world = async (payloadCap?: number) => {
  const seam = testSeam("2026-05-07T14:00:00.000Z");
  return { seam, log: await EventLog.open(store, seam, { name: `log-${crypto.randomUUID()}`, payloadCap }) };
};
const events = (r: LoggedEvent[] | { refused: string }) => r as LoggedEvent[];

test("State 5, Operation 1 to 4, Invariant 5.2: a fresh log begins at one; each append lands the next number and reads back rising, stamped from now", async () => {
  const { log, seam } = await world();
  const a = await log.append({ type: "deposit", amount: 500 }) as { event_id: string };
  seam.advance(1000);
  await log.append({ type: "withdrawal", amount: 100 });
  const all = events(await log.read({ sequence: { from: 1 } }));
  expect(all.map((e) => e.sequence_number)).toEqual([1, 2]);
  expect(all[0].event_id).toBe(a.event_id);
  expect(all.map((e) => e.recorded_at)).toEqual(["2026-05-07T14:00:00.000Z", "2026-05-07T14:00:01.000Z"]);
  expect(all[0].data).toEqual({ amount: 500, type: "deposit" });
});

test("Operation 5, 6, 9: data over the payload cap is invalid-payload and lands nothing; empty data is accepted", async () => {
  const { log } = await world(64);
  expect(await log.append("x".repeat(100))).toEqual({ refused: "invalid-payload" });
  expect(events(await log.read({ sequence: { from: 1 } }))).toEqual([]);
  expect("event_id" in (await log.append(null))).toBe(true);
  expect("event_id" in (await log.append(""))).toBe(true);
});

test("Operation 15, 16: a malformed query is invalid-query; a well-formed one matching nothing answers empty", async () => {
  const { log } = await world();
  await log.append({ n: 1 });
  for (const bad of [{}, { sequence: { from: -1, to: 5 } }, { sequence: { from: 0 } }, { sequence: { from: 3, to: 2 } }, { sequence: { from: 1.5 } },
    { time: { from: "yesterday" } }, { time: { from: "2026-05-08T00:00:00Z", to: "2026-05-07T00:00:00Z" } }, { sequence: { from: 1 }, other: 1 } as never])
    expect(await log.read(bad)).toEqual({ refused: "invalid-query" });
  expect(events(await log.read({ sequence: { from: 9, to: 12 } }))).toEqual([]);
  expect(events(await log.read({ time: { from: "2030-01-01T00:00:00Z" } }))).toEqual([]);
});

test("Query 2, 4: a range holds both its ends; a missing upper end holds everything above; two ranges combine as all-of", async () => {
  const { log, seam } = await world();
  for (let i = 1; i <= 5; i++) { await log.append({ i }); seam.advance(60_000); }
  expect(events(await log.read({ sequence: { from: 2, to: 4 } })).map((e) => e.sequence_number)).toEqual([2, 3, 4]);
  expect(events(await log.read({ sequence: { from: 4 } })).map((e) => e.sequence_number)).toEqual([4, 5]);
  expect(events(await log.read({ sequence: { from: 1, to: 5 }, time: { from: "2026-05-07T14:02:00Z", to: "2026-05-07T14:03:00Z" } })).map((e) => e.sequence_number)).toEqual([3, 4]);
});

test("Invariant 3.1, 4.1, 6.1, State 6: eight appends at once land eight events, numbered one to eight with no number shared and no gap, each event id its own", async () => {
  const { log } = await world();
  const out = await Promise.all(Array.from({ length: 8 }, (_, i) => log.append({ i })));
  expect(out.every((o) => "event_id" in o)).toBe(true);
  const all = events(await log.read({ sequence: { from: 1 } }));
  expect(all.map((e) => e.sequence_number)).toEqual([1, 2, 3, 4, 5, 6, 7, 8]);
  expect(new Set(all.map((e) => e.event_id)).size).toBe(8);
  expect(all.map((e) => (e.data as { i: number }).i).sort()).toEqual([0, 1, 2, 3, 4, 5, 6, 7]);
});

test("Invariant 2.1, 1.1, State 8, 9: a landed event is one version and never written again; a later append leaves it as it was", async () => {
  const { log } = await world();
  const a = await log.append({ keep: true }) as { event_id: string };
  await log.append({ next: true });
  expect(await store.history("events", a.event_id)).toHaveLength(1);
  expect(events(await log.read({ sequence: { from: 1, to: 1 } }))[0].data).toEqual({ keep: true });
});

test("Identity 10, Composes 4a: two log instances number their events apart and never read each other's", async () => {
  const one = await world();
  const two = await world();
  await one.log.append({ a: 1 });
  await one.log.append({ a: 2 });
  await two.log.append({ b: 1 });
  expect(events(await one.log.read({ sequence: { from: 1 } }))).toHaveLength(2);
  const b = events(await two.log.read({ sequence: { from: 1 } }));
  expect(b).toHaveLength(1);
  expect(b[0].sequence_number).toBe(1);
});

test("Database 1: several events planned together land together, in order, beside another write of the same action", async () => {
  const { log } = await world();
  const plan = await log.plan([{ step: "entry" }, { step: "event" }]);
  if ("refused" in plan) throw new Error("refused");
  await store.commit(plan.stmts);
  const all = events(await log.read({ sequence: { from: 1 } }));
  expect(all.map((e) => e.sequence_number)).toEqual([1, 2]);
  expect(all.map((e) => e.event_id)).toEqual(plan.event_ids);
  // a plan made before another event landed is refused whole when committed
  const stale = await log.plan([{ late: true }]);
  await log.append({ first: true });
  if ("refused" in stale) throw new Error("refused");
  await expect(store.commit(stale.stmts)).rejects.toThrow();
  expect(events(await log.read({ sequence: { from: 1 } }))).toHaveLength(3); // the two planned together and the one that landed first; the stale plan wrote nothing
});

test("State 4, 5, Database 2: the log carries its next sequence number; a fresh instance has none and begins at one, an append advances it by the events it lands, and an append never scans for it", async () => {
  const { log } = await world();
  const name = (log as unknown as { cfg: { name: string } }).cfg.name;
  const head = () => store.read<{ next_seq: string }>(`SELECT next_seq FROM log_heads WHERE _id = $1`, [name]);
  expect(await head()).toEqual([]);
  for (let i = 0; i < 25; i++) await log.append({ i });
  expect(Number((await head())[0].next_seq)).toBe(26);
  const plan = await log.plan([{ a: 1 }, { b: 2 }]);
  if ("refused" in plan) throw new Error("refused");
  expect(plan.sequence_numbers).toEqual([26, 27]);
  await store.commit(plan.stmts);
  expect(Number((await head())[0].next_seq)).toBe(28);
  expect((events(await log.read({ sequence: { from: 1 } }))).map((e) => e.sequence_number)).toEqual(Array.from({ length: 27 }, (_, i) => i + 1));
});
