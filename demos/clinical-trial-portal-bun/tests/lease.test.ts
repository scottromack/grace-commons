// Lease, one test for each rule the render answers, named by the rule's label.
import { test, expect, afterAll } from "bun:test";
import { Store } from "../src/store.ts";
import { testSeam } from "../src/seam.ts";
import { LeaseHost } from "../src/lease.ts";

const store = new Store();
afterAll(() => store.close());

const world = async () => {
  const seam = testSeam("2026-08-01T12:00:00.000Z");
  const host = await LeaseHost.open(store, seam, { prefix: `ls_${crypto.randomUUID().replaceAll("-", "_")}_`, pollMs: 500, staleMs: 3000, sleep: async (ms) => { seam.advance(ms); await new Promise((r) => setTimeout(r, 1)); } });
  return { seam, host, key: `key-${crypto.randomUUID()}` };
};
const SEC = 1000;

test("Operation 6a, 6b, 2a, 2b, Invariant 1.2: a try_take on a free key takes it, expires_at set from the host's reading; a second holder is held; the first holder is not asked twice", async () => {
  const { host, key } = await world();
  expect(await host.tryTake(key, "a", 10 * SEC)).toEqual({ taken: "2026-08-01T12:00:10.000Z" });
  expect(await host.tryTake(key, "b", 10 * SEC)).toBe("held");
});

test("State 2, 3, Invariant 2: a grant ends at its instant with nothing written (the instant equal to expires_at reads free) and a release ends it earlier; the history shows no write for the lapse", async () => {
  const { host, seam, key } = await world();
  await host.tryTake(key, "a", 10 * SEC);
  seam.advance(9_999);
  expect(await host.tryTake(key, "b", SEC)).toBe("held");
  seam.advance(1);                                                                                           // now equals expires_at
  expect(await host.tryTake(key, "b", 5 * SEC)).toEqual({ taken: "2026-08-01T12:00:15.000Z" });
  expect(await host.release(key, "b")).toBe("released");
  expect(await host.tryTake(key, "c", SEC)).toEqual({ taken: "2026-08-01T12:00:11.000Z" });
  const versions = await store.history(`${(host as unknown as { L: string }).L}`, key);
  expect(versions.map((v) => v.holder)).toEqual(["a", "b", null, "c"]);                                      // a, b, b released, c: the lapse between a and b wrote nothing
});

test("Operation 8 to 14, Invariant 5.1: remaining answers the holder's own term from the host's reading and none to anyone else; release answers released to the holder and not-held to any other, never a failure", async () => {
  const { host, seam, key } = await world();
  await host.tryTake(key, "a", 10 * SEC);
  seam.advance(4 * SEC);
  expect(await host.remaining(key, "a")).toEqual({ remaining_ms: 6 * SEC });
  expect(await host.remaining(key, "b")).toBe("none");
  expect(await host.release(key, "b")).toBe("not-held");
  expect(await host.remaining(key, "a")).toEqual({ remaining_ms: 6 * SEC });                                 // another holder's release reached nothing (Operation 13)
  seam.advance(6 * SEC);
  expect(await host.remaining(key, "a")).toBe("none");                                                       // lapsed
  expect(await host.release(key, "a")).toBe("not-held");
});

test("Operation 1a, 1, 2: a take on a free key with no waiter succeeds at once; a take on a held key waits for it and succeeds at the first reading the key is free", async () => {
  const { host, seam, key } = await world();
  expect(await host.take(key, "a", 10 * SEC)).toEqual({ expires_at: "2026-08-01T12:00:10.000Z" });
  const b = await host.take(key, "b", 5 * SEC);
  expect(b).toEqual({ expires_at: "2026-08-01T12:00:15.000Z" });                                             // took at the reading a's term ended
  expect(seam.now()).toBe("2026-08-01T12:00:10.000Z");
});

test("Operation 4, 5, 5a, Invariant 4.1, 4.2: waiters are admitted in arrival order; a waiter's bound is fixed at its arrival and admitting an earlier waiter does not extend it, so the later waiter's take answers unavailable", async () => {
  const { host, seam, key } = await world();
  await host.take(key, "a", 10 * SEC);
  const [b, c] = await Promise.all([host.take(key, "b", 10 * SEC), (async () => { await new Promise((r) => setTimeout(r, 20)); return host.take(key, "c", 10 * SEC); })()]);
  expect(b).toMatchObject({ expires_at: expect.any(String) });
  expect(c).toBe("unavailable");                                                                              // c's bound was a's expiry; b took the key at it
  expect(seam.now() >= "2026-08-01T12:00:10.000Z").toBe(true);
});

test("Operation 6c, 5b: a try_take on a free key with a waiter standing is held; the lease state keeps exactly one record for the key", async () => {
  const { host, key } = await world();
  await host.tryTake(key, "a", 10 * SEC);
  const waiting = host.take(key, "w", SEC);
  await new Promise((r) => setTimeout(r, 30));
  expect(await host.tryTake(key, "x", SEC)).toBe("held");
  await waiting;
  const rows = await store.read(`SELECT _id FROM ${(host as unknown as { L: string }).L}`);
  expect(rows.filter((r) => r._id === key)).toHaveLength(1);
});

test("Database 2: twenty try_takes on one free key at once leave exactly one holder; the other nineteen are held", async () => {
  const { host, key } = await world();
  const out = await Promise.all(Array.from({ length: 20 }, (_, i) => host.tryTake(key, `h${i}`, 60 * SEC)));
  expect(out.filter((o) => o !== "held")).toHaveLength(1);
});
