// Session, one test for each rule the render answers, named by the rule's label.
import { test, expect, afterAll } from "bun:test";
import { Store } from "../src/store.ts";
import { testSeam } from "../src/seam.ts";
import { Session } from "../src/session.ts";

const store = new Store();
afterAll(() => store.close());

const world = async (defaultDurationSeconds: number | null = 3600) => {
  const seam = testSeam("2026-09-01T10:00:00.000Z");
  return { seam, ses: await Session.open(store, seam, { defaultDurationSeconds }) };
};
const who = () => `user-${crypto.randomUUID()}`;

test("Operation 1 to 3, 9, 10, 50, 51: an issue records one active session stamped from now, and answers its token", async () => {
  const { ses } = await world();
  const p = who();
  const r = await ses.issue(p, "login-svc", 3600) as { session_token: string };
  expect(typeof r.session_token).toBe("string");
  const rows = await ses.read({ principal_ref: p });
  expect(rows).toHaveLength(1);
  expect([rows[0].status, rows[0].issued_at, rows[0].expires_at, rows[0].issued_by_ref]).toEqual(["active", "2026-09-01T10:00:00.000Z", "2026-09-01T11:00:00.000Z", "login-svc"]);
});

test("Operation 18, 19, 14: a live session validates with its principal and expiry; a forged token is not-known", async () => {
  const { ses, seam } = await world();
  const p = who();
  const { session_token } = await ses.issue(p, "login-svc", 3600) as { session_token: string };
  seam.advance(20 * 60_000);
  expect(await ses.validate(session_token)).toEqual({ valid: { principal_ref: p, expires_at: "2026-09-01T11:00:00.000Z" } });
  expect(await ses.validate("tok_forged_xyz")).toEqual({ invalid: "not-known" });
});

test("Expiry 2 to 5, Operation 16, Invariant 12.3: a lapse is derived, the boundary instant reads lapsed, and nothing is written", async () => {
  const { ses, seam } = await world();
  const p = who();
  const { session_token } = await ses.issue(p, "login-svc", 3600) as { session_token: string };
  seam.set("2026-09-01T11:00:00.000Z");
  expect(await ses.validate(session_token)).toEqual({ invalid: "expired" });
  const row = (await ses.read({ principal_ref: p }))[0];
  expect([row.status, row.effective_status]).toEqual(["active", "expired"]);
  expect(await store.history("sessions", session_token)).toHaveLength(1);
});

test("Operation 4, 5, 8, 48, 55, 56: blank references, a duration that is no whole positive number, and no default are invalid-request", async () => {
  const { ses } = await world();
  expect(await ses.issue("", "svc", 60)).toEqual({ refused: "invalid-request" });
  expect(await ses.issue(who(), "  ", 60)).toEqual({ refused: "invalid-request" });
  expect(await ses.issue(who(), "svc", 0)).toEqual({ refused: "invalid-request" });
  expect(await ses.issue(who(), "svc", -5)).toEqual({ refused: "invalid-request" });
  expect(await ses.issue(who(), "svc", 1.5)).toEqual({ refused: "invalid-request" });
  expect(await ses.issue(who(), "svc", "60" as unknown as number)).toEqual({ refused: "invalid-request" });
  expect(await ses.issue("x".repeat(257), "svc", 60)).toEqual({ refused: "invalid-request" });
  const none = await world(null);
  expect(await none.ses.issue(who(), "svc")).toEqual({ refused: "invalid-request" });
  const zero = await world(0);
  expect(await zero.ses.issue(who(), "svc")).toEqual({ refused: "invalid-request" });
});

test("Operation 6: an issue with no duration applies the default", async () => {
  const { ses } = await world(120);
  const p = who();
  await ses.issue(p, "svc");
  expect((await ses.read({ principal_ref: p }))[0].expires_at).toBe("2026-09-01T10:02:00.000Z");
});

test("Operation 15, 28 to 33, Invariant 3.3, 8: a revoke stamps who, why and when; a revoked session validates revoked even inside its window; the earlier version is kept", async () => {
  const { ses, seam } = await world();
  const p = who();
  const { session_token } = await ses.issue(p, "login-svc", 3600) as { session_token: string };
  seam.advance(45 * 60_000);
  expect(await ses.revoke(session_token, p, "user-initiated-logout")).toBe("revoked");
  seam.advance(5 * 60_000);
  expect(await ses.validate(session_token)).toEqual({ invalid: "revoked" });
  const row = (await ses.read({ principal_ref: p }))[0];
  expect([row.status, row.revoked_at, row.revoked_by_ref, row.revocation_reason, row.expires_at]).toEqual(["revoked", "2026-09-01T10:45:00.000Z", p, "user-initiated-logout", "2026-09-01T11:00:00.000Z"]);
  expect((await store.history("sessions", session_token)).map((v) => v.status)).toEqual(["active", "revoked"]);
});

test("Operation 22 to 27: revoke refuses an unknown token, a revoked session (its reason unchanged) and blank attribution, and accepts a lapsed session", async () => {
  const { ses, seam } = await world();
  expect(await ses.revoke("tok_nope", "admin", "x")).toEqual({ refused: "not-known" });
  const { session_token } = await ses.issue(who(), "svc", 60) as { session_token: string };
  expect(await ses.revoke(session_token, " ", "why")).toEqual({ refused: "invalid-request" });
  expect(await ses.revoke(session_token, "admin", "")).toEqual({ refused: "invalid-request" });
  seam.advance(120_000);                                              // lapsed
  expect(await ses.revoke(session_token, "admin-1", "incident-response")).toBe("revoked");
  expect(await ses.revoke(session_token, "admin-2", "again")).toEqual({ refused: "already-terminal" });
  expect((await ses.read({ issued_by_ref: "svc" })).some((s) => s.revocation_reason === "again")).toBe(false);
});

test("Operation 52, 53, 61: a read never carries the token; a blank filter value, an over-long one or another field answers no session", async () => {
  const { ses } = await world();
  const p = who();
  const { session_token } = await ses.issue(p, "svc", 60) as { session_token: string };
  expect(JSON.stringify(await ses.read({ principal_ref: p }))).not.toContain(session_token);
  expect(await ses.read({ principal_ref: "" })).toEqual([]);
  expect(await ses.read({ principal_ref: "x".repeat(257) })).toEqual([]);
  expect(await ses.read({ expires_at: "2026-09-01T10:01:00.000Z" })).toEqual([]);
  expect((await ses.read({})).length).toBeGreaterThan(0);
});

test("Invariant 7.1: two issues never share a token", async () => {
  const { ses } = await world();
  const toks = await Promise.all(Array.from({ length: 8 }, () => ses.issue(who(), "svc", 60)));
  expect(new Set(toks.map((t) => (t as { session_token: string }).session_token)).size).toBe(8);
});
