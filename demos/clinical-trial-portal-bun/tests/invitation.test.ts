// Invitation, one test for each rule the render answers, named by the rule's label.
import { test, expect, afterAll } from "bun:test";
import { Store } from "../src/store.ts";
import { testSeam } from "../src/seam.ts";
import { Invitation } from "../src/invitation.ts";

const store = new Store();
afterAll(() => store.close());

const world = async (defaultTtl: number | null = 3600) => {
  const seam = testSeam("2026-07-01T08:00:00.000Z");
  const inv = await Invitation.open(store, seam, { ttlBounds: { min: 60, max: 86_400 * 30 }, defaultTtl, table: `inv_${crypto.randomUUID().replaceAll("-", "_")}` });
  const make = async (ttl?: number) => (await inv.initiate("anya", "maya@beacon.clinical", "study BCN-OX-201", ttl) as { invitation_token: string }).invitation_token;
  return { seam, inv, make };
};

test("Operation 4, 8 to 14: an initiate records the inviter, invitee and context, pending, with the default ttl as the expiry, and answers the token", async () => {
  const { inv, make } = await world();
  const t = await make();
  const [row] = await inv.read({ invitation_token: t });
  expect([row.inviter_ref, row.invitee_ref, row.context, row.status, row.initiated_at, row.expires_at]).toEqual(["anya", "maya@beacon.clinical", "study BCN-OX-201", "pending", "2026-07-01T08:00:00.000Z", "2026-07-01T09:00:00.000Z"]);
  const own = await make(7200);
  expect((await inv.read({ invitation_token: own }))[0].expires_at).toBe("2026-07-01T10:00:00.000Z");
  expect(new Set([t, own]).size).toBe(2);
});

test("Operation 1 to 6, 48, 49: a blank inviter or context, a ttl outside the bounds or not a whole number, no ttl and no default, and an over-long string are invalid-request; an absent invitee is fine", async () => {
  const { inv } = await world();
  const bad = { refused: "invalid-request" };
  expect(await inv.initiate(" ", "x", "ctx")).toEqual(bad);
  expect(await inv.initiate("anya", "x", "")).toEqual(bad);
  expect(await inv.initiate("anya", "x", "ctx", 59)).toEqual(bad);
  expect(await inv.initiate("anya", "x", "ctx", 86_400 * 30 + 1)).toEqual(bad);
  expect(await inv.initiate("anya", "x", "ctx", 90.5)).toEqual(bad);
  expect(await inv.initiate("anya", "x", "ctx", "3600" as unknown as number)).toEqual(bad);
  expect(await inv.initiate("a".repeat(257), "x", "ctx")).toEqual(bad);
  const none = await world(null);
  expect(await none.inv.initiate("anya", "x", "ctx")).toEqual(bad);                                          // no ttl, no default
  expect("invitation_token" in (await inv.initiate("anya", undefined, "ctx"))).toBe(true);                   // Operation 6
  expect((await inv.read({ context: "ctx" }))[0].invitee_ref).toBeNull();
  await expect(Invitation.open(store, testSeam(), { ttlBounds: { min: 60, max: 120 }, defaultTtl: 3600 })).rejects.toThrow(/default ttl/);   // Capability requirement 4
});

test("Operation 28, 29, State 3, Identity 13: an accept stands the invitation accepted and records the identity and the instant; the identity is not matched against the invitee", async () => {
  const { inv, make, seam } = await world();
  const t = await make();
  seam.advance(120_000);
  expect(await inv.accept(t, "party-9")).toBe("accepted");
  const [row] = await inv.read({ invitation_token: t });
  expect([row.status, row.accepting_identity_ref, row.accepted_at, row.initiated_at, row.inviter_ref, row.expires_at]).toEqual(["accepted", "party-9", "2026-07-01T08:02:00.000Z", "2026-07-01T08:00:00.000Z", "anya", "2026-07-01T09:00:00.000Z"]);
});

test("Operation 15 to 17, 20, Invariant 2.1: not-known; a stored terminal answers already-resolved naming its status; a lapsed invitation answers expired, boundary included; no second terminal is ever reached", async () => {
  const { inv, make, seam } = await world();
  expect(await inv.accept("no-such-token", "party-9")).toEqual({ refused: "not-known" });
  const a = await make(), d = await make(), r = await make(), e = await make(60);
  await inv.accept(a, "party-9"); await inv.decline(d); await inv.revoke(r, "anya", "sent in error");
  expect(await inv.decline(a)).toEqual({ refused: "already-resolved", status: "accepted" });
  expect(await inv.accept(d, "party-9")).toEqual({ refused: "already-resolved", status: "declined" });
  expect(await inv.revoke(r, "anya", "again")).toEqual({ refused: "already-resolved", status: "revoked" });
  seam.set("2026-07-01T08:01:00.000Z");                                                                       // the boundary instant of e
  for (const res of [await inv.accept(e, "p"), await inv.decline(e), await inv.revoke(e, "anya", "late")]) expect(res).toEqual({ refused: "expired" });
  expect((await inv.read({ invitation_token: e }))[0]).toMatchObject({ status: "pending", effective_status: "expired" });   // never stored (State 7)
});

test("Term status check, Operation 23 to 25, 50, 51: the status check comes before the call's inputs; blank or over-long inputs are invalid-request on a pending invitation", async () => {
  const { inv, make } = await world();
  const t = await make();
  expect(await inv.accept(t, " ")).toEqual({ refused: "invalid-request" });
  expect(await inv.accept(t, "p".repeat(257))).toEqual({ refused: "invalid-request" });
  expect(await inv.revoke(t, "", "why")).toEqual({ refused: "invalid-request" });
  expect(await inv.revoke(t, "anya", "")).toEqual({ refused: "invalid-request" });
  expect((await inv.read({ invitation_token: t }))[0].status).toBe("pending");
  await inv.decline(t);
  expect(await inv.accept(t, " ")).toEqual({ refused: "already-resolved", status: "declined" });              // the status first
  expect(await inv.accept("no-such-token", "")).toEqual({ refused: "not-known" });
});

test("Operation 30 to 33, State 4, 5: decline records its instant and takes no acting reference; revoke records who, why and when", async () => {
  const { inv, make, seam } = await world();
  const d = await make(), r = await make();
  seam.advance(1000);
  await inv.decline(d); await inv.revoke(r, "anya", "wrong person");
  expect(await inv.read({ invitation_token: d })).toMatchObject([{ status: "declined", declined_at: "2026-07-01T08:00:01.000Z", accepting_identity_ref: null, revoked_by_ref: null }]);
  expect(await inv.read({ invitation_token: r })).toMatchObject([{ status: "revoked", revoked_by_ref: "anya", revocation_reason: "wrong person", revoked_at: "2026-07-01T08:00:01.000Z" }]);
  expect(inv.decline.length).toBe(1);
});

test("Database 2, Invariant 2.1, 2.2: ten accepts of one invitation at once resolve it once; the rest answer already-resolved", async () => {
  const { inv, make } = await world();
  const t = await make();
  const out = await Promise.all(Array.from({ length: 10 }, (_, i) => inv.accept(t, `party-${i}`)));
  expect(out.filter((o) => o === "accepted")).toHaveLength(1);
  expect(out.filter((o) => typeof o === "object" && (o as { refused: string }).refused === "already-resolved")).toHaveLength(9);
  expect(await store.history((inv as unknown as { T: string }).T, t)).toHaveLength(2);
});

test("Operation 41 to 47, Term filter: a read answers every match with its effective status and writes nothing; a status filter matches the stored status; a blank value or an unknown field matches nothing", async () => {
  const { inv, make, seam } = await world();
  const a = await make(), b = await make(60);
  await inv.accept(a, "party-1");
  seam.advance(120_000);                                                                                     // b has lapsed
  expect(Object.fromEntries((await inv.read()).map((i) => [i.invitation_token === a ? "a" : "b", i.effective_status]))).toEqual({ a: "accepted", b: "expired" });
  expect((await inv.read({ status: "pending" })).map((i) => i.invitation_token)).toEqual([b]);                // stored status, not effective
  expect(await inv.read({ status: "expired" })).toEqual([]);
  expect(await inv.read({ context: "" })).toEqual([]);
  expect(await inv.read({ colour: "red" })).toEqual([]);
  expect((await inv.read({ accepting_identity_ref: "party-1" })).map((i) => i.invitation_token)).toEqual([a]);
  expect(await store.history((inv as unknown as { T: string }).T, b)).toHaveLength(1);
});
