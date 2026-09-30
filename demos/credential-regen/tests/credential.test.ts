// Each test names the rule it holds; rule numbers are atoms/credential.md's.
import { assertEquals, assertThrows } from "@std/assert";
import { DAY, keys, ok, world } from "./helpers.ts";

Deno.test("Password: register, verify, and material never stored (Operation 11, 17, 21 through 23; State 9)", () => {
  const w = world();
  const id = ok(w.c.register("user_u91", "correct horse battery staple", "password"));
  assertEquals(w.c.verify("user_u91", "password", "correct horse battery staple"), "verified");
  assertEquals(w.c.verify("user_u91", "password", "hunter2"), { "failed-verification": "material-mismatch" });
  const row = w.db.prepare("SELECT * FROM credential").get<Record<string, string>>()!;
  assertEquals(Object.values(row).some((v) => String(v).includes("correct horse")), false);
  assertEquals("verifier" in w.c.read({ credential_id: id })[0], false); // Operation 53
});

Deno.test("Capability requirement 18: a salted hash and a signature both check through their type's check function", () => {
  const w = world();
  ok(w.c.register("alice", "same secret", "password"));
  ok(w.c.register("bob", "same secret", "password"));
  const [a, b] = w.db.prepare("SELECT verifier FROM credential").all<{ verifier: string }>();
  assertEquals(a.verifier === b.verifier, false); // salted: equal material, unequal verifiers
  const k = keys();
  ok(w.c.register("svc", k.pem, "public-key"));
  assertEquals(w.c.verify("svc", "public-key", k.signed("nonce-1")), "verified");
  assertEquals(w.c.verify("svc", "public-key", keys().signed("nonce-1")), { "failed-verification": "material-mismatch" });
  assertEquals(w.c.verify("svc", "public-key", "not json"), { "failed-verification": "material-mismatch" }); // Operation 68
  assertEquals(w.c.register("svc2", "not a key", "public-key"), { refused: "invalid-request" }); // Operation 66
});

Deno.test("Operation 1 through 7 and String 7: register's refusals, invalid-request before duplicate", () => {
  const w = world();
  ok(w.c.register("user_u91", "x", "password"));
  assertEquals(w.c.register("user_u91", "y", "password"), { refused: "duplicate-active-credential" });
  assertEquals(w.c.register("user_u91", "y", "Password "), { refused: "invalid-request" }); // Identity 11
  assertEquals(w.c.register(" ", "y", "password"), { refused: "invalid-request" });
  assertEquals(w.c.register("u".repeat(65), "y", "password"), { refused: "invalid-request" });
  assertEquals(w.c.register("user_u91", "y", "password", w.seam.now()), { refused: "invalid-request" }); // Operation 5
});

Deno.test("Operation 13 and Capability requirement 7: the default is a validity from now, so a late registration is not born lapsed", () => {
  const w = world();
  w.seam.advance(400 * DAY);
  const id = ok(w.c.register("user_u91", "x", "password"));
  assertEquals(w.c.read({ credential_id: id })[0].effective_status, "active");
  assertEquals(w.c.read({ credential_id: id })[0].expires_at, new Date(w.seam.ms() + 90 * DAY).toISOString());
});

Deno.test("The deadline: the boundary reads lapsed, nothing is written, and a lapsed credential blocks nothing (Operation 8; Invariant 11, 12)", () => {
  const w = world();
  const id = ok(w.c.register("svc", "t1", "api-token", "2026-07-01T00:00:00.000Z"));
  const before = w.db.prepare("SELECT * FROM credential").all();
  w.seam.set("2026-07-01T00:00:00.000Z");
  assertEquals(w.c.read({ credential_id: id })[0].effective_status, "expired");
  assertEquals(w.c.verify("svc", "api-token", "t1"), { "failed-verification": "no-active-credential" });
  assertEquals(w.c.rotate(id, "t2"), { refused: "not-active" });
  assertEquals(w.c.revoke(id, "admin", "r"), { refused: "already-terminal" });
  assertEquals(w.db.prepare("SELECT * FROM credential").all(), before);
  assertEquals("ok" in w.c.register("svc", "t2", "api-token"), true);
});

Deno.test("Rotate states its successor whole and commits both writes (Operation 35 through 41, 58 through 64)", () => {
  const w = world();
  const c07 = ok(w.c.register("svc", "old", "api-token", "2026-06-30T00:00:00.000Z"));
  w.seam.set("2026-06-01T00:00:00.000Z");
  const c11 = ok(w.c.rotate(c07, "new", "2026-09-01T00:00:00.000Z"));
  const [p, s] = [w.c.read({ credential_id: c07 })[0], w.c.read({ credential_id: c11 })[0]];
  assertEquals([p.status, p.successor_credential_id, p.rotated_at], ["rotated", c11, "2026-06-01T00:00:00.000Z"]);
  assertEquals([s.status, s.registered_at, s.expires_at], ["active", "2026-06-01T00:00:00.000Z", "2026-09-01T00:00:00.000Z"]);
  assertEquals(w.c.verify("svc", "api-token", "new"), "verified");
  assertEquals(w.c.verify("svc", "api-token", "old"), { "failed-verification": "material-mismatch" });
  // Operation 62: no deadline supplied, so now plus the default validity.
  const c12 = ok(w.c.rotate(c11, "newer"));
  assertEquals(w.c.read({ credential_id: c12 })[0].expires_at, new Date(Date.parse("2026-06-01T00:00:00.000Z") + 90 * DAY).toISOString());
});

Deno.test("Operation 65 and Capability requirement 8: a rotate on an early reading loses to a register on a late one", () => {
  const w = world();
  const c11 = ok(w.c.register("svc", "t1", "api-token", "2026-07-01T00:00:00.000Z"));
  w.seam.set("2026-07-02T00:00:00.000Z");
  ok(w.c.register("svc", "t2", "api-token"));               // c11 read lapsed; admitted
  w.seam.set("2026-06-30T00:00:00.000Z");                  // the rotate's reading, taken earlier
  assertEquals(w.c.rotate(c11, "t3"), { refused: "not-active" });
  w.seam.set("2026-07-02T00:00:00.000Z");
  assertEquals(w.c.read({ principal_ref: "svc" }).filter((c) => c.effective_status === "active").length, 1); // Check 1.1
});

Deno.test("Operation 27 through 34: the standing checks before invalid-request", () => {
  const w = world();
  const id = ok(w.c.register("svc", "t1", "api-token"));
  assertEquals(w.c.rotate("cred_404", ""), { refused: "not-known" });
  assertEquals(w.c.rotate(id, "  "), { refused: "invalid-request" });
  ok(w.c.rotate(id, "t2"));
  assertEquals(w.c.rotate(id, "  "), { refused: "not-active" });
  assertEquals(w.c.revoke(id, "admin", "  "), { refused: "already-terminal" });
});

Deno.test("Concurrency 1 and 2: a revoke landing inside a rotate leaves the rotate the loser, and no successor", () => {
  const w = world();
  const id = ok(w.c.register("svc", "t1", "api-token"));
  w.f.between("rotate-before-write", () => ok(w.c.revoke(id, "admin", "exposed")));
  assertEquals(w.c.rotate(id, "t2"), { refused: "not-active" });
  assertEquals(w.c.read().map((c) => c.status), ["revoked"]);
});

Deno.test("Revoke: attribution recorded, the stored terminal absorbs (Operation 42, 43; Invariant 4, 5, 9; String 9)", () => {
  const w = world();
  const id = ok(w.c.register("svc", "t1", "api-token"));
  assertEquals(w.c.revoke(id, "admin_a01", "x".repeat(65)), { refused: "invalid-request" });
  assertEquals(w.c.revoke(id, "admin_a01", "log-exposure"), { ok: "revoked" });
  const r = w.c.read({ credential_id: id })[0];
  assertEquals([r.revoked_by_ref, r.revocation_reason, r.revoked_at], ["admin_a01", "log-exposure", w.seam.now()]);
  assertEquals(w.c.verify("svc", "api-token", "t1"), { "failed-verification": "no-active-credential" });
  assertThrows(() => w.db.exec("UPDATE credential SET status = 'active'")); // Invariant 5.1
  assertThrows(() => w.db.exec("DELETE FROM credential"));                  // Invariant 10.1
});

Deno.test("Operation 45 through 49: a failed write answers storage-failure and leaves nothing", () => {
  const w = world();
  w.f.arm("store.write");
  assertEquals(w.c.register("user_u92", "z", "password"), { refused: "storage-failure" });
  assertEquals(w.c.read(), []);
  const id = ok(w.c.register("user_u92", "z", "password"));
  w.f.arm("store.write");
  assertEquals(w.c.rotate(id, "zz"), { refused: "storage-failure" });
  assertEquals(w.c.read().map((c) => c.status), ["active"]); // Atomic writes 5
});

Deno.test("Capability requirement 21 through 23: an overdue holder's write is refused", () => {
  const w = world();
  w.f.between("register-before-write", () => w.seam.advance(5_000));
  assertEquals(w.c.register("user_u93", "z", "password"), { refused: "storage-failure" });
  assertEquals(w.c.read(), []);
  assertEquals("ok" in w.c.register("user_u93", "z", "password"), true); // the section was released
});

Deno.test("Operation 69 and Term filter: read answers in registration order, an empty filter matches every credential", () => {
  const w = world();
  ok(w.c.register("b", "1", "password"));
  w.seam.advance(1);
  ok(w.c.register("a", "2", "password"));
  assertEquals(w.c.read().map((c) => c.principal_ref), ["b", "a"]);
  assertEquals(w.c.read({ principal_ref: "a" }).length, 1);
});
