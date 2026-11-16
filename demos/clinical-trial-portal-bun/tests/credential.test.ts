// Credential, one test for each rule the render answers, named by the rule's label.
import { test, expect, afterAll } from "bun:test";
import { Store } from "../src/store.ts";
import { testSeam } from "../src/seam.ts";
import { Credential, type Registry } from "../src/credential.ts";

const store = new Store();
afterAll(() => store.close());

// A password type: argon2id derives the verifier, the check is the same library's verify (constant time).
const password = {
  derive: async (m: string) => (m.length > 200 ? null : Bun.password.hash(m.normalize("NFC"), { algorithm: "argon2id", memoryCost: 1024, timeCost: 1 })),
  check: (p: string, v: string) => Bun.password.verify(p.normalize("NFC"), v),
};
const registry = (defaultValidityMs: number | null = null): Registry => ({ types: { password }, defaultValidityMs });
const world = async (defaultValidityMs: number | null = null) => {
  const seam = testSeam();
  return { seam, cred: await Credential.open(store, seam, registry(defaultValidityMs)) };
};
const who = () => `user-${crypto.randomUUID()}`;

test("Operation 16, 17, 23, 53: a registered credential verifies, and no read carries the verifier or the material", async () => {
  const { cred } = await world();
  const p = who();
  const r = await cred.register(p, "correct horse", "password");
  expect("credential_id" in r).toBe(true);
  expect(await cred.verify(p, "password", "correct horse")).toBe("verified");
  const rows = await cred.read({ principal_ref: p });
  expect(rows).toHaveLength(1);
  expect(JSON.stringify(rows)).not.toContain("correct horse");
  expect("verifier" in rows[0]).toBe(false);
});

test("Operation 22, 18, 19: a wrong material is material-mismatch; an unknown principal, an unregistered type and a revoked pair all answer the one reason", async () => {
  const { cred } = await world();
  const p = who();
  const r = await cred.register(p, "pw-one-pw", "password") as { credential_id: string };
  expect(await cred.verify(p, "password", "nope")).toEqual({ failed: "material-mismatch" });
  expect(await cred.verify(who(), "password", "pw-one-pw")).toEqual({ failed: "no-active-credential" });
  expect(await cred.verify(p, "api-token", "pw-one-pw")).toEqual({ failed: "no-active-credential" });
  await cred.revoke(r.credential_id, "admin", "exposed");
  expect(await cred.verify(p, "password", "pw-one-pw")).toEqual({ failed: "no-active-credential" });
});

test("Operation 1 to 4: blank principal, blank type, empty material and an unregistered type are invalid-request; whitespace material is not empty", async () => {
  const { cred } = await world();
  expect(await cred.register("  ", "x", "password")).toEqual({ refused: "invalid-request" });
  expect(await cred.register(who(), "x", "")).toEqual({ refused: "invalid-request" });
  expect(await cred.register(who(), "", "password")).toEqual({ refused: "invalid-request" });
  expect(await cred.register(who(), "x", "Password ")).toEqual({ refused: "invalid-request" });
  expect("credential_id" in (await cred.register(who(), "   ", "password"))).toBe(true);
});

test("Operation 6, Invariant 2.1: a second register on one pair is refused; two at once leave one (Database 2)", async () => {
  const { cred } = await world();
  const p = who();
  await cred.register(p, "a-password", "password");
  expect(await cred.register(p, "other", "password")).toEqual({ refused: "duplicate-active-credential" });
  const q = who();
  const both = await Promise.all([cred.register(q, "one-one-one", "password"), cred.register(q, "two-two-two", "password")]);
  expect(both.filter((r) => "credential_id" in r)).toHaveLength(1);
  expect((await cred.read({ principal_ref: q })).filter((c) => c.effective_status === "active")).toHaveLength(1);
});

test("Operation 5, 63, 80: an expiry not ahead of now, or not an instant, is invalid-request", async () => {
  const { cred, seam } = await world();
  expect(await cred.register(who(), "pw-pw-pw", "password", seam.now())).toEqual({ refused: "invalid-request" });
  expect(await cred.register(who(), "pw-pw-pw", "password", "tomorrow")).toEqual({ refused: "invalid-request" });
});

test("Term lapsed, Operation 8, Invariant 12: the boundary instant reads lapsed, nothing is written, a lapsed credential does not block the pair, and verify fails", async () => {
  const { cred, seam } = await world();
  const p = who();
  const r = await cred.register(p, "pw-pw-pw", "password", "2026-01-01T01:00:00.000Z") as { credential_id: string };
  expect(await cred.verify(p, "password", "pw-pw-pw")).toBe("verified");
  seam.set("2026-01-01T01:00:00.000Z");
  expect((await cred.read({ credential_id: r.credential_id }))[0].effective_status).toBe("expired");
  expect((await cred.read({ credential_id: r.credential_id }))[0].status).toBe("active");
  expect(await cred.verify(p, "password", "pw-pw-pw")).toEqual({ failed: "no-active-credential" });
  expect("credential_id" in (await cred.register(p, "new-pw-new", "password"))).toBe(true);
  expect(await store.history("credential", r.credential_id)).toHaveLength(1); // Invariant 12.1: the lapse wrote no version
});

test("Operation 13, 71: the default validity is recorded as the expiry, and unbounded records none", async () => {
  const day = await world(86_400_000);
  const r = await day.cred.register(who(), "pw-pw-pw", "password") as { credential_id: string };
  expect((await day.cred.read({ credential_id: r.credential_id }))[0].expires_at).toBe("2026-01-02T00:00:00.000Z");
  const open = await world(null);
  const s = await open.cred.register(who(), "pw-pw-pw", "password") as { credential_id: string };
  expect((await open.cred.read({ credential_id: s.credential_id }))[0].expires_at).toBeNull();
});

test("Operation 35 to 41, Invariant 6, 7: a rotate makes an active successor on the pair, stands the prior rotated, and the prior's earlier version is kept (Database 5)", async () => {
  const { cred, seam } = await world();
  const p = who();
  const a = await cred.register(p, "first-pw-1", "password") as { credential_id: string };
  seam.advance(1000);
  const b = await cred.rotate(a.credential_id, "second-pw-2") as { credential_id: string };
  const rows = await cred.read({ principal_ref: p });
  expect(rows.map((r) => r.status)).toEqual(["rotated", "active"]);                       // Operation 69: earliest first
  expect(rows[0].successor_credential_id).toBe(b.credential_id);
  expect(rows[0].rotated_at).toBe(seam.now());
  expect(await cred.verify(p, "password", "second-pw-2")).toBe("verified");
  expect(await cred.verify(p, "password", "first-pw-1")).toEqual({ failed: "material-mismatch" });
  const versions = await store.history("credential", a.credential_id);
  expect(versions.map((v) => v.status)).toEqual(["active", "rotated"]);
  expect(versions[0].verifier).toBe(versions[1].verifier);                                 // Invariant 6.1
});

test("Operation 27, 28, 31: rotate refuses an unknown id, a credential not active, and empty material", async () => {
  const { cred } = await world();
  expect(await cred.rotate("no-such-id", "x")).toEqual({ refused: "not-known" });
  const a = await cred.register(who(), "pw-pw-pw", "password") as { credential_id: string };
  expect(await cred.rotate(a.credential_id, "")).toEqual({ refused: "invalid-request" });
  await cred.rotate(a.credential_id, "pw-two-pw");
  expect(await cred.rotate(a.credential_id, "pw-three")).toEqual({ refused: "not-active" });
});

test("Operation 42, 43, 29, 32, 33, Invariant 9: a revoke records who, why and when; revoking again is already-terminal; blanks are invalid-request", async () => {
  const { cred, seam } = await world();
  const a = await cred.register(who(), "pw-pw-pw", "password") as { credential_id: string };
  expect(await cred.revoke(a.credential_id, " ", "why")).toEqual({ refused: "invalid-request" });
  expect(await cred.revoke(a.credential_id, "admin-1", "")).toEqual({ refused: "invalid-request" });
  seam.advance(5000);
  expect(await cred.revoke(a.credential_id, "admin-1", "log exposure")).toBe("revoked");
  const row = (await cred.read({ credential_id: a.credential_id }))[0];
  expect([row.status, row.revoked_by_ref, row.revocation_reason, row.revoked_at]).toEqual(["revoked", "admin-1", "log exposure", seam.now()]);
  expect(await cred.revoke(a.credential_id, "admin-2", "again")).toEqual({ refused: "already-terminal" });
  expect(await cred.revoke("no-such-id", "admin", "x")).toEqual({ refused: "not-known" });
  expect((await cred.read({ credential_id: a.credential_id }))[0].revoked_by_ref).toBe("admin-1"); // Invariant 1.2
});

test("Operation 73: a filter naming a blank value answers no credential; an empty filter answers every one", async () => {
  const { cred } = await world();
  await cred.register(who(), "pw-pw-pw", "password");
  expect(await cred.read({ principal_ref: "" })).toEqual([]);
  expect((await cred.read({})).length).toBeGreaterThan(0);
});
