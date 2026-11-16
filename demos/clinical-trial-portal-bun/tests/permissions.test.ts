// Permissions, one test for each rule the render answers, named by the rule's label.
import { test, expect, afterAll } from "bun:test";
import { Store } from "../src/store.ts";
import { testSeam } from "../src/seam.ts";
import { Permissions } from "../src/permissions.ts";

const store = new Store();
afterAll(() => store.close());

const world = async (stringCap?: number) => {
  const seam = testSeam("2026-05-01T09:00:00.000Z");
  return { seam, perm: await Permissions.open(store, seam, { table: `grants_${crypto.randomUUID().replaceAll("-", "_")}`, stringCap }) };
};

test("Operation 1 to 3, 17, 18, 21, 22: a grant records one active grant and answers its id; permitted only for the exact pair, denied for every other", async () => {
  const { perm } = await world();
  const g = await perm.grant("usr_42", "invoice:read") as { grant_id: string };
  expect(await perm.permitted("usr_42", "invoice:read")).toBe("permitted");
  for (const [s, a] of [["usr_42", "invoice:delete"], ["usr_43", "invoice:read"], ["USR_42", "invoice:read"], ["usr_42 ", "invoice:read"], ["usr_42", "Invoice:read"]]) expect(await perm.permitted(s, a)).toBe("denied");
  const all = await perm.read();
  expect(all).toHaveLength(1);
  expect([all[0].grant_id, all[0].status, all[0].granted_at, all[0].revoked_at]).toEqual([g.grant_id, "active", "2026-05-01T09:00:00.000Z", null]);
});

test("Operation 4, 5, String 6: a blank reference or scope, or a string over the cap, is invalid-request and records nothing", async () => {
  const { perm } = await world(10);
  expect(await perm.grant(" ", "scope")).toEqual({ refused: "invalid-request" });
  expect(await perm.grant("subject", "")).toEqual({ refused: "invalid-request" });
  expect(await perm.grant("x".repeat(11), "scope")).toEqual({ refused: "invalid-request" });
  expect(await perm.grant("subject", "y".repeat(11))).toEqual({ refused: "invalid-request" });
  expect(await perm.read()).toEqual([]);
});

test("Identity 7, Operation 33, 34, Invariant 11.1: a grant on a pair an active grant covers answers that grant's id and writes nothing", async () => {
  const { perm } = await world();
  const a = await perm.grant("usr_42", "invoice:read") as { grant_id: string };
  const b = await perm.grant("usr_42", "invoice:read") as { grant_id: string };
  expect(b.grant_id).toBe(a.grant_id);
  expect(await perm.read()).toHaveLength(1);
});

test("Grant concurrency 1, Database 2: ten grants on one pair at once leave exactly one grant, and every call answers its id", async () => {
  const { perm } = await world();
  const out = await Promise.all(Array.from({ length: 10 }, () => perm.grant("usr_77", "ledger:write")));
  const ids = new Set(out.map((o) => (o as { grant_id: string }).grant_id));
  expect(ids.size).toBe(1);
  expect(await perm.read()).toHaveLength(1);
});

test("Operation 9 to 11, Invariant 1.1, Identity 8: a revoke stands the grant revoked with its instant, the pair and grant instant unchanged, the earlier version kept; not-known and not-active are refused apart", async () => {
  const { perm, seam } = await world();
  const g = await perm.grant("usr_42", "invoice:read") as { grant_id: string };
  seam.advance(3600_000);
  expect(await perm.revoke(g.grant_id)).toBe("ok");
  expect(await perm.permitted("usr_42", "invoice:read")).toBe("denied");
  const row = (await perm.read())[0];
  expect([row.status, row.granted_at, row.revoked_at]).toEqual(["revoked", "2026-05-01T09:00:00.000Z", "2026-05-01T10:00:00.000Z"]);
  expect(await perm.revoke(g.grant_id)).toEqual({ refused: "not-active" });
  expect(await perm.revoke("no-such-grant")).toEqual({ refused: "not-known" });
  expect((await store.history((perm as unknown as { T: string }).T, g.grant_id)).map((v) => v.status)).toEqual(["active", "revoked"]);
});

test("Invariant 11.1: a revoked pair may be granted again, a new grant; both stay in the read", async () => {
  const { perm, seam } = await world();
  const a = await perm.grant("usr_42", "invoice:read") as { grant_id: string };
  await perm.revoke(a.grant_id);
  seam.advance(1000);
  const b = await perm.grant("usr_42", "invoice:read") as { grant_id: string };
  expect(b.grant_id).not.toBe(a.grant_id);
  expect((await perm.read()).map((g) => g.status)).toEqual(["revoked", "active"]);
  expect(await perm.permitted("usr_42", "invoice:read")).toBe("permitted");
});

test("Operation 20, 28, Non-goal 9: permitted and read write nothing, and a grant carries no grantor", async () => {
  const { perm } = await world();
  const g = await perm.grant("usr_42", "invoice:read") as { grant_id: string };
  await perm.permitted("usr_42", "invoice:read"); await perm.read();
  expect(await store.history((perm as unknown as { T: string }).T, g.grant_id)).toHaveLength(1);
  expect(Object.keys((await perm.read())[0]).sort()).toEqual(["action_scope", "grant_id", "granted_at", "revoked_at", "status", "subject_ref"]);
});
