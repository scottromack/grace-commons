// Rendered from the page's Composition-level invariants, Action wiring and
// Conformance checks. Each test names the rule it holds.
import { assert, assertEquals, assertThrows } from "@std/assert";
import { openStore } from "../src/store.ts";
import { counterSeam } from "../src/seam.ts";
import * as AI from "../src/actor_identity.ts";
import * as C from "../src/composition.ts";

const CONFIG: C.Config = {
  prefix: "apa:", lengthCap: 128, retentionScope: "per-store",
  issuanceBoundMs: 60_000, revocationBoundMs: 60_000, pairScopedBoundMs: 300_000,
};

function fresh(config: Partial<C.Config> = {}) {
  const db = openStore();
  AI.register(db, "alice", "alice-secret");
  AI.register(db, "bob", "bob-secret");
  return C.start(db, counterSeam(), { ...CONFIG, ...config });
}
const issue = (x: C.Instance, s = "u1", sc = "reports:read") => C.issue_grant(x, s, sc, "alice", "alice-secret");
const count = (x: C.Instance, t: string) => (x.db.prepare(`SELECT COUNT(*) AS n FROM ${t}`).get<{ n: number }>()!).n;
const orphans = (x: C.Instance) => x.db.prepare("SELECT * FROM orphan_log ORDER BY attestation_id").all<Record<string, string | null>>();

// ---- Issue Grant ----
Deno.test("issue_grant answers the grant's handle and the attestation (Action wiring 15, Invariant 1.1)", () => {
  const x = fresh();
  const r = issue(x);
  assert("ok" in r);
  assertEquals(r.ok, { grant_id: "g1", attestation_id: "a1" });
  assertEquals(x.db.prepare("SELECT attestation_id FROM grant_attribution WHERE grant_id='g1'").get(), { attestation_id: "a1" });
  assertEquals(C.permitted(x, "u1", "reports:read"), "permitted");
});

Deno.test("the grant proposal carries the prefix, subject, scope, nonce and request instant, never a grant id (Identity 11 and 13)", () => {
  const x = fresh();
  issue(x);
  const { action_ref } = x.db.prepare("SELECT action_ref FROM attestation").get<{ action_ref: string }>()!;
  assert(action_ref.startsWith("apa:"));
  const body = JSON.parse(action_ref.slice(4));
  assertEquals(Object.keys(body).sort(), ["action_scope", "nonce", "requested_at", "subject_ref"]);
});

Deno.test("a second active grant on one pair is not refused (Wiring decision 8)", () => {
  const x = fresh();
  assert("ok" in issue(x));
  assert("ok" in C.issue_grant(x, "u1", "reports:read", "bob", "bob-secret"));
  assertEquals(count(x, "grant_record"), 2);
});

Deno.test("a credential that does not validate answers invalid-credential and writes no grant (Action wiring 3 and 6)", () => {
  const x = fresh();
  assertEquals(C.issue_grant(x, "u1", "s", "alice", "wrong"), { refused: "invalid-credential" });
  assertEquals(C.issue_grant(x, "u1", "s", "nobody", "x"), { refused: "invalid-credential" });
  assertEquals(count(x, "grant_record"), 0);
  assertEquals(count(x, "attestation"), 0);
});

Deno.test("the boundary predicate refuses blank and over-length inputs before any constituent call (Primitive policy 1 through 5)", () => {
  const x = fresh();
  assertEquals(C.issue_grant(x, "  ", "s", "alice", "alice-secret"), { refused: "invalid-request" });
  assertEquals(C.issue_grant(x, "u", "s", "alice", " "), { refused: "invalid-request" });
  assertEquals(C.issue_grant(x, "u".repeat(129), "s", "alice", "alice-secret"), { refused: "invalid-request" });
  assertEquals(count(x, "attestation"), 0);
});

Deno.test("administration trims once; the evaluation does not trim (Primitive policy 6 through 11)", () => {
  const x = fresh();
  assert("ok" in C.issue_grant(x, "  u1 ", " s ", "alice", "alice-secret"));
  assertEquals(C.permitted(x, "u1", "s"), "permitted");
  assertEquals(C.permitted(x, " u1", "s"), "denied");
  assertEquals(C.permitted(x, "U1", "s"), "denied");
});

Deno.test("an attest storage failure answers attribution-storage-failure and writes no grant (Action wiring 5 and 6)", () => {
  const x = fresh();
  x.faults.attestStorage = true;
  assertEquals(issue(x), { refused: "attribution-storage-failure" });
  assertEquals(count(x, "grant_record"), 0);
});

Deno.test("a refused grant answers orphan-attestation at pre-grant and logs the orphan (Action wiring 9 and 10)", () => {
  const x = fresh();
  x.faults.grantStorage = true;
  assertEquals(issue(x), { refused: "orphan-attestation", position: "pre-grant" });
  const [o] = orphans(x);
  assertEquals([o.attestation_id, o.reason, o.grant_id], ["a1", "grant-storage-failure", null]);
  assert(String(o.proposal).startsWith("apa:"));
});

Deno.test("a refused pairing rolls the grant back and answers pre-grant (Action wiring 13, Capability requirement 23)", () => {
  const x = fresh();
  x.faults.pairingWrite = true;
  assertEquals(issue(x), { refused: "orphan-attestation", position: "pre-grant" });
  assertEquals(count(x, "grant_record"), 0);
  assertEquals(orphans(x)[0].reason, "pairing-write-failure");
  assertEquals(orphans(x)[0].grant_id, "g1");
});

Deno.test("a non-honouring host leaves the ordered partial: post-grant carrying the handle (Action wiring 14, Invariant 1.3)", () => {
  const x = fresh();
  x.faults.nonAtomicHost = true;
  assertEquals(issue(x), { refused: "orphan-attestation", position: "post-grant", grant_id: "g1" });
  assertEquals(C.verify_grant_attribution(x, "g1"), "attribution-inconsistency");
  assertEquals(orphans(x)[0].grant_id, "g1");                 // Composition state 20 and 21
});

// ---- Revoke Grant ----
Deno.test("revoke_grant answers the attestation and pairs it (Action wiring 41, Invariant 2.1)", () => {
  const x = fresh();
  issue(x);
  const r = C.revoke_grant(x, "g1", "bob", "bob-secret");
  assertEquals(r, { ok: { attestation_id: "a2" } });
  assertEquals(C.permitted(x, "u1", "reports:read"), "denied");
  const { action_ref } = x.db.prepare("SELECT action_ref FROM attestation WHERE attestation_id='a2'").get<{ action_ref: string }>()!;
  assertEquals(Object.keys(JSON.parse(action_ref.slice(4))).sort(), ["grant_id", "requested_at"]);  // Identity 12
});

Deno.test("not-known and not-active surface the constituent's code and leave a logged orphan (Action wiring 23, 24, 26, 29, 30)", () => {
  const x = fresh();
  assertEquals(C.revoke_grant(x, "g9", "bob", "bob-secret"), { refused: "not-known" });
  issue(x);
  C.revoke_grant(x, "g1", "bob", "bob-secret");
  assertEquals(C.revoke_grant(x, "g1", "bob", "bob-secret"), { refused: "not-active" });
  assertEquals(orphans(x).map((o) => o.reason), ["not-known", "not-active"]);
});

Deno.test("a refused revoke answers pre-revoke; a refused pairing answers pre-revoke; a non-honouring host answers post-revoke", () => {
  const x = fresh();
  issue(x);
  x.faults.revokeStorage = true;
  assertEquals(C.revoke_grant(x, "g1", "bob", "bob-secret"), { refused: "orphan-attestation", position: "pre-revoke" });
  x.faults.revokeStorage = false; x.faults.pairingWrite = true;
  assertEquals(C.revoke_grant(x, "g1", "bob", "bob-secret"), { refused: "orphan-attestation", position: "pre-revoke" });
  assertEquals(C.permitted(x, "u1", "reports:read"), "permitted");  // nothing committed
  x.faults.pairingWrite = false; x.faults.nonAtomicHost = true;
  assertEquals(C.revoke_grant(x, "g1", "bob", "bob-secret"), { refused: "orphan-attestation", position: "post-revoke" });
  assertEquals(C.verify_grant_attribution(x, "g1"), "attribution-inconsistency");  // Invariant 2.3
  assertEquals(orphans(x).map((o) => o.reason), ["revocation-storage-failure", "pairing-write-failure", "pairing-write-failure"]);
});

// ---- Revoke Permission ----
Deno.test("revoke_permission exists and revokes every grant on the pair under one request instant (Wiring decision 6, Identity 9, Invariant 9)", () => {
  const x = fresh();
  issue(x); C.issue_grant(x, "u1", "reports:read", "bob", "bob-secret"); issue(x, "u2");
  const r = C.revoke_permission(x, "u1", "reports:read", "bob", "bob-secret");
  assertEquals(r, { ok: { revoked_grant_ids: ["g1", "g2"], attestation_ids: ["a4", "a5"] } });
  assertEquals(C.permitted(x, "u1", "reports:read"), "denied");     // Action wiring 51
  assertEquals(C.permitted(x, "u2", "reports:read"), "permitted");
  const instants = new Set(["a4", "a5"].map((id) =>
    JSON.parse(x.db.prepare("SELECT action_ref FROM attestation WHERE attestation_id=?").get<{ action_ref: string }>(id)!.action_ref.slice(4)).requested_at));
  assertEquals(instants.size, 1);
  assertEquals(count(x, "revocation_attribution"), 2);              // Invariant 9.2
});

Deno.test("an empty enumerated set answers not-permitted and attests nothing (Action wiring 43 through 45)", () => {
  const x = fresh();
  assertEquals(C.revoke_permission(x, "u1", "reports:read", "bob", "bob-secret"), { refused: "not-permitted" });
  assertEquals(count(x, "attestation"), 0);
});

Deno.test("a grant reaching no committed revocation answers partially-revoked naming only the enumerated grants (Action wiring 49, Invariant 9.4)", () => {
  const x = fresh();
  issue(x); issue(x);
  // The second revoke refuses: fail storage after the first commits.
  let calls = 0;
  const realExec = x.db.exec.bind(x.db);
  x.db.exec = ((sql: string) => { if (sql === "BEGIN" && ++calls === 2) x.faults.revokeStorage = true; return realExec(sql); }) as typeof x.db.exec;
  const r = C.revoke_permission(x, "u1", "reports:read", "bob", "bob-secret");
  assertEquals(r, { refused: "partially-revoked", revoked_grant_ids: ["g1"], remaining: ["g2"] });
  assertEquals(C.permitted(x, "u1", "reports:read"), "permitted");
});

Deno.test("revoke_permission answers invalid-credential before anything lands", () => {
  const x = fresh();
  issue(x);
  assertEquals(C.revoke_permission(x, "u1", "reports:read", "bob", "nope"), { refused: "invalid-credential" });
  assertEquals(C.permitted(x, "u1", "reports:read"), "permitted");
});

// ---- Verify Grant Attribution ----
Deno.test("verify answers the record, the issuance pair, and the revocation pair once revoked (Invariant 3.1 and 3.2)", () => {
  const x = fresh();
  issue(x);
  const v1 = C.verify_grant_attribution(x, "g1");
  assert(typeof v1 === "object");
  assertEquals([v1.ok.issuance_attestation_id, v1.ok.issuance_verify_result, v1.ok.revocation_attestation_id], ["a1", "verified", undefined]);
  C.revoke_grant(x, "g1", "bob", "bob-secret");
  const v2 = C.verify_grant_attribution(x, "g1");
  assert(typeof v2 === "object");
  assertEquals([v2.ok.revocation_attestation_id, v2.ok.revocation_verify_result], ["a2", "verified"]);
  assertEquals(C.verify_grant_attribution(x, "g9"), "not-known");
});

Deno.test("verify writes nothing (Action wiring 78)", () => {
  const x = fresh();
  issue(x);
  const before = ["attestation", "grant_record", "grant_attribution", "orphan_log"].map((t) => count(x, t));
  C.verify_grant_attribution(x, "g1"); C.verify_grant_attribution(x, "g9");
  assertEquals(["attestation", "grant_record", "grant_attribution", "orphan_log"].map((t) => count(x, t)), before);
});

Deno.test("an absent attestation: purged under per-store answers not-applicable(purged); unnamed answers the tamper reading (Action wiring 62 through 64)", () => {
  const x = fresh();
  issue(x); issue(x, "u2");
  x.db.exec("DELETE FROM attestation WHERE attestation_id IN ('a1','a2')");
  x.db.exec("INSERT INTO purge_record VALUES ('a1')");
  const v1 = C.verify_grant_attribution(x, "g1"), v2 = C.verify_grant_attribution(x, "g2");
  assert(typeof v1 === "object" && typeof v2 === "object");
  assertEquals(v1.ok.issuance_verify_result, { "not-applicable": "purged" });
  assertEquals(v2.ok.issuance_verify_result, "not-known");
});

Deno.test("under a pair-scoped retention scope the purge record is not consulted (Action wiring 67)", () => {
  const x = fresh({ retentionScope: "pair" });
  issue(x);
  x.db.exec("DELETE FROM attestation WHERE attestation_id = 'a1'");
  x.db.exec("INSERT INTO purge_record VALUES ('a1')");
  const v = C.verify_grant_attribution(x, "g1");
  assert(typeof v === "object");
  assertEquals(v.ok.issuance_verify_result, "not-known");
});

Deno.test("a registry outage surfaces as registry-unavailable (Action wiring 75)", () => {
  const x = fresh();
  issue(x);
  x.registryUp = false;
  const v = C.verify_grant_attribution(x, "g1");
  assert(typeof v === "object");
  assertEquals(v.ok.issuance_verify_result, { "failed-verification": "registry-unavailable" });
});

// ---- composition state ----
Deno.test("attribution entries and orphan log entries are write-once (Invariant 6 and 8)", () => {
  const x = fresh();
  issue(x);
  x.faults.grantStorage = true; issue(x);
  assertThrows(() => x.db.exec("UPDATE grant_attribution SET attestation_id='a9'"));
  assertThrows(() => x.db.exec("DELETE FROM grant_attribution"));
  assertThrows(() => x.db.exec("UPDATE orphan_log SET reason='x'"));
  assertThrows(() => x.db.exec("DELETE FROM orphan_log"));
});

Deno.test("the maps stand injective and disjoint (Invariant 7.1 through 7.3)", () => {
  const x = fresh();
  issue(x); issue(x);
  C.revoke_grant(x, "g1", "bob", "bob-secret");
  assertThrows(() => x.db.exec("INSERT INTO grant_attribution VALUES ('g9','a1')"));        // 7.1
  assertThrows(() => x.db.exec("INSERT INTO revocation_attribution VALUES ('g2','a3')"));   // 7.2
  assertThrows(() => x.db.exec("INSERT INTO revocation_attribution VALUES ('g2','a2')"));   // 7.3
});

Deno.test("two issuances for one pair carry distinct proposals (Invariant 7.5) and distinct attestations (7.4)", () => {
  const x = fresh();
  issue(x); issue(x);
  const rows = x.db.prepare("SELECT attestation_id, action_ref FROM attestation").all<{ attestation_id: string; action_ref: string }>();
  assertEquals(new Set(rows.map((r) => r.action_ref)).size, 2);
  assertEquals(new Set(rows.map((r) => r.attestation_id)).size, 2);
});

Deno.test("an attestation's stamp does not exceed its grant's (Invariant 4.1)", () => {
  const x = fresh();
  issue(x);
  const a = x.db.prepare("SELECT attested_at FROM attestation WHERE attestation_id='a1'").get<{ attested_at: string }>()!;
  const g = x.db.prepare("SELECT granted_at FROM grant_record WHERE grant_id='g1'").get<{ granted_at: string }>()!;
  assert(a.attested_at <= g.granted_at);
});

// ---- instance start (Capability requirement 19, 29, 30) ----
Deno.test("an instance refuses to start with a length cap past the constituent's, or misordered bounds", () => {
  assertThrows(() => C.start(openStore(), counterSeam(), { ...CONFIG, lengthCap: 10_000 }));
  assertThrows(() => C.start(openStore(), counterSeam(), { ...CONFIG, revocationBoundMs: 999_999 }));
});

// ---- the failed-grant leg ----
Deno.test("the leg reports aged orphans, skips young ones and foreign prefixes, and writes nothing (Housekeeping 2 through 13)", () => {
  const x = fresh({ retentionHorizonMs: 10_000_000 });
  issue(x);                                        // paired
  x.faults.grantStorage = true; issue(x);          // orphan a2, logged
  x.faults.grantStorage = false;
  AI.attest(x.db, x.seam, x.faults, "other:{}", "alice", "alice-secret");  // foreign
  const soon = new Date(Date.UTC(2026, 8, 26) + 30_000).toISOString();
  assertEquals(C.failed_grant_leg(x, soon), []);   // inside the issuance bound: inconclusive
  const later = new Date(Date.UTC(2026, 8, 26) + 120_000).toISOString();
  assertEquals(C.failed_grant_leg(x, later), [{ attestation_id: "a2", reading: "orphan" }]);
  // An unpaired attestation the log never recorded (Housekeeping 17).
  AI.attest(x.db, x.seam, x.faults, `apa:${JSON.stringify({ grant_id: "g1", requested_at: soon })}`, "bob", "bob-secret");
  const before = ["attestation", "grant_record", "grant_attribution", "revocation_attribution", "orphan_log"].map((t) => count(x, t));
  const past = new Date(Date.UTC(2026, 8, 26) + 20_000_000).toISOString();
  assertEquals(C.failed_grant_leg(x, past), [
    { attestation_id: "a2", reading: "purge-pending-orphan" },
    { attestation_id: "a4", reading: "non-conformant-purge" },
  ]);
  assertEquals(["attestation", "grant_record", "grant_attribution", "revocation_attribution", "orphan_log"].map((t) => count(x, t)), before);  // Housekeeping 6
});
