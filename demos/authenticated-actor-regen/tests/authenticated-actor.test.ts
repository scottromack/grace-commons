// Each test names the rule it holds; rule numbers are compositions/authenticated-actor.md's.
import { assertEquals, assertThrows } from "@std/assert";
import { actorIdentity, credential } from "../src/atoms.ts";
import { AuthenticatedActor } from "../src/composition.ts";
import { CONFIG, smith, world } from "./helpers.ts";

const credentials = (w: ReturnType<typeof world>) => credential.read(w.db, w.seam, {});

Deno.test("Composition state 1 through 3: a registration binds both directions under one transaction", () => {
  const w = world();
  const r = smith(w);
  assertEquals(r.actor_ref, "actor_smith");
  assertEquals(w.aa.binding("dev_smith")?.credential_type, "fido2");
  assertEquals(w.db.prepare("SELECT principal_ref FROM actor_binding WHERE actor_ref = 'actor_smith'").value<[string]>(), ["dev_smith"]);
  // Composition state 6: a binding never changes.
  assertThrows(() => w.db.exec("UPDATE principal_binding SET actor_ref = 'actor_jones'"));
});

Deno.test("Action wiring 30 and Primitive policy 4: an absent credential type takes the default, a blank one is refused", () => {
  const w = world();
  assertEquals(w.aa.register("dev_smith", "actor_smith", "m", "  "), { refused: "invalid-request" });
  const r = w.aa.register("dev_smith", "actor_smith", "m", "password");
  assertEquals("ok" in r && w.aa.binding("dev_smith")?.credential_type, "password");
  const s = w.aa.register("dev_jones", "actor_jones", "m");
  assertEquals("ok" in s && w.aa.binding("dev_jones")?.credential_type, "fido2");
});

Deno.test("Action wiring 2 and 3: the guard refuses either bound key, and nothing is registered", () => {
  const w = world();
  smith(w);
  assertEquals(w.aa.register("dev_smith", "actor_jones", "m"), { refused: { "namespace-conflict": "guard" } });
  assertEquals(w.aa.register("dev_jones", "actor_smith", "m"), { refused: { "namespace-conflict": "guard" } });
  assertEquals(credentials(w).length, 1);
});

Deno.test("Action wiring 31 and 32: Credential's refusals land as invalid-request and storage-failure naming the credential", () => {
  const w = world();
  assertEquals(w.aa.register("dev_smith", "actor_smith", "m", "smartcard"), { refused: "invalid-request" });
  w.f.arm("credential.register");
  assertEquals(w.aa.register("dev_smith", "actor_smith", "m"), { refused: { "storage-failure": "credential" } });
  assertEquals(credentials(w).length, 0);
});

Deno.test("Action wiring 5 through 8 and 11: a binding failure re-enters through the arm, which asks for possession", () => {
  const w = world();
  w.f.arm("binding.write");
  assertEquals(w.aa.register("dev_smith", "actor_smith", "smith-fido2"), { refused: { "storage-failure": "binding" } });
  const [c] = credentials(w);
  assertEquals(w.aa.register("dev_smith", "actor_smith", "not-smith"), { refused: { "invalid-credential": c.credential_id } });
  const r = w.aa.register("dev_smith", "actor_smith", "smith-fido2");
  assertEquals("ok" in r && r.ok.credential_id, c.credential_id);
  assertEquals(credentials(w).length, 1);
});

Deno.test("Action wiring 10: two principals racing one actor reference — the binding write decides", () => {
  const w = world();
  w.f.between("after-credential", () => {
    const r = w.aa.register("dev_jones", "actor_smith", "jones-fido2");
    assertEquals("ok" in r, true);
  });
  assertEquals(w.aa.register("dev_smith", "actor_smith", "smith-fido2"), { refused: { "namespace-conflict": "binding" } });
  assertEquals(w.aa.binding("dev_jones")?.actor_ref, "actor_smith");
  // Housekeeping 6: dev_smith's credential is bound to nothing, and the leg reports it once it is old enough.
  w.seam.advance(CONFIG.registrationCompletionBoundMs + CONFIG.clockOffsetAllowanceMs + 1);
  assertEquals(w.aa.orphanedCredentials(), ["credential-001"]);
});

Deno.test("Action wiring 12 and 13: a lapsed holder re-runs the guard and answers orphan-credential", () => {
  const w = world();
  w.f.between("after-credential", () => {
    w.seam.advance(CONFIG.registrationCompletionBoundMs);
    assertEquals("ok" in w.aa.register("dev_smith", "actor_jones", "smith-pw", "password"), true);
  });
  assertEquals(w.aa.register("dev_smith", "actor_smith", "smith-fido2"), { refused: { "orphan-credential": "credential-001" } });
  w.seam.advance(CONFIG.registrationCompletionBoundMs + CONFIG.clockOffsetAllowanceMs + 1);
  assertEquals(w.aa.orphanedCredentials(), ["credential-001"]);
});

Deno.test("Action wiring 33: a lapsed holder finding its actor reference bound answers namespace-conflict naming the binding", () => {
  const w = world();
  w.f.between("after-credential", () => {
    w.seam.advance(CONFIG.registrationCompletionBoundMs);
    assertEquals("ok" in w.aa.register("dev_jones", "actor_smith", "jones-fido2"), true);
  });
  assertEquals(w.aa.register("dev_smith", "actor_smith", "smith-fido2"), { refused: { "namespace-conflict": "binding" } });
});

Deno.test("Invariant 1 and 4.3: attest while active, then a revocation closes the surface forward only", () => {
  const w = world();
  const { credential_id } = smith(w);
  const a = w.aa.attest("dev_smith", "commit_c44a", "smith-signing-key");
  assertEquals(a, { ok: "attestation-001" });
  credential.revoke(w.db, w.seam, credential_id, "security_team", "key-compromise");
  assertEquals(w.aa.attest("dev_smith", "commit_c45b", "smith-signing-key"), { refused: "credential-not-active" });
  const [ok, refused] = w.aa.log();
  assertEquals([ok.outcome, ok.credential_id, ok.attestation_id], ["success", credential_id, "attestation-001"]);
  // Action wiring 34: the refused entry carries what the gate saw.
  assertEquals([refused.outcome, refused.observed_status, refused.credential_id], ["credential-not-active", "revoked", credential_id]);
  // Wiring decision 4: the earlier attestation stands.
  assertEquals(w.aa.verify("attestation-001"), { result: "verified", actor_ref: "actor_smith", principal_ref: "dev_smith" });
});

Deno.test("Composes 9 and Housekeeping 6: a rotation keeps the surface open, and its successor is no orphan", () => {
  const w = world();
  const { credential_id } = smith(w);
  const rot = credential.rotate(w.db, w.seam, credential_id, "smith-fido2-new") as { ok: string };
  assertEquals("ok" in w.aa.attest("dev_smith", "commit_c46c", "smith-signing-key"), true);
  assertEquals(w.aa.log()[0].credential_id, rot.ok);
  w.seam.advance(CONFIG.registrationCompletionBoundMs + CONFIG.clockOffsetAllowanceMs + 1);
  assertEquals(w.aa.orphanedCredentials(), []);
});

Deno.test("Composition state 8: refused calls are logged — invalid-request, not-bound, invalid-attest-credential", () => {
  const w = world();
  smith(w);
  assertEquals(w.aa.attest("dev_smith", " ", "k"), { refused: "invalid-request" });
  assertEquals(w.aa.attest("dev_unknown", "action_x", "k"), { refused: "not-bound" });
  assertEquals(w.aa.attest("dev_smith", "commit_c47d", "wrong-key"), { refused: "invalid-attest-credential" });
  assertEquals(w.aa.log().map((e) => e.outcome), ["invalid-request", "not-bound", "invalid-attest-credential"]);
  // Action wiring 23: the login material is never a signing key.
  assertEquals(w.aa.attest("dev_smith", "commit_c47e", "smith-fido2"), { refused: "invalid-attest-credential" });
  // Composition state 9: an entry never changes.
  assertThrows(() => w.db.exec("DELETE FROM attest_log"));
});

Deno.test("Action wiring 25 and Invariant 4.2: attest-failed at the attestation is logged; at the log it carries the id and no entry", () => {
  const w = world();
  smith(w);
  w.f.arm("identity.attest");
  assertEquals(w.aa.attest("dev_smith", "c1", "smith-signing-key"), { refused: { "attest-failed": "attestation" } });
  assertEquals(w.aa.log().map((e) => e.outcome), ["attest-failed"]);
  w.f.arm("attest_log.append");
  assertEquals(w.aa.attest("dev_smith", "c2", "smith-signing-key"), { refused: { "attest-failed": { log: "attestation-001" } } });
  assertEquals(w.aa.log().length, 1);
  assertEquals(actorIdentity.read(w.db).map((a) => a.attestation_id), ["attestation-001"]);
});

Deno.test("Action wiring 25: a refusal whose entry fails answers attest-failed naming the log, with no attestation id", () => {
  const w = world();
  w.f.arm("attest_log.append");
  assertEquals(w.aa.attest("dev_unknown", "action_x", "k"), { refused: { "attest-failed": { log: null } } });
  assertEquals(w.aa.log().length, 0);
});

Deno.test("Concurrency 3 and Check 2: a revoke inside the held section is the declared residue, sized by the window", () => {
  const w = world();
  const { credential_id } = smith(w);
  w.f.between("after-gate", () => credential.revoke(w.db, w.seam, credential_id, "ops", "offboarded"));
  assertEquals(w.aa.attest("dev_smith", "c1", "smith-signing-key"), { ok: "attestation-001" });
  // The auditor's read: the attestation's instant against the gate credential's revoked instant.
  const [e] = w.aa.log();
  const att = actorIdentity.read(w.db)[0];
  const revoked = credential.read(w.db, w.seam, { credential_id: e.credential_id! })[0];
  const edge = Date.parse(revoked.ended_at!) + CONFIG.clockOffsetAllowanceMs + CONFIG.attestCompletionBoundMs;
  assertEquals(Date.parse(att.attested_at) <= edge, true); // Check 2.3: residue, not violation
  // Concurrency 5: the next gate read closes.
  assertEquals(w.aa.attest("dev_smith", "c2", "smith-signing-key"), { refused: "credential-not-active" });
});

Deno.test("Action wiring 36: a lease lapsing after the gate read sends the call back to the gate", () => {
  const w = world();
  const { credential_id } = smith(w);
  w.f.between("after-gate", () => {
    w.seam.advance(CONFIG.attestCompletionBoundMs);
    credential.revoke(w.db, w.seam, credential_id, "ops", "offboarded");
  });
  assertEquals(w.aa.attest("dev_smith", "c1", "smith-signing-key"), { refused: "credential-not-active" });
  assertEquals(actorIdentity.read(w.db).length, 0);
});

Deno.test("Action wiring 27 and Non-goal 13: verify resolves through the inverse map, and only through it", () => {
  const w = world();
  smith(w);
  w.aa.attest("dev_smith", "c1", "smith-signing-key");
  actorIdentity.attest(w.db, w.seam, w.f, "elsewhere", "actor_jones", "jones-signing-key");
  assertEquals(w.aa.verify("attestation-002"), { result: "verified", actor_ref: "actor_jones" });
  assertEquals(w.aa.verify("attestation-404"), { result: "not-known" });
  // A known attestation resolves whatever its verification answers.
  actorIdentity.retire(w.db, "actor_smith");
  assertEquals(w.aa.verify("attestation-001"),
    { result: "failed-verification(actor-unknown-in-registry)", actor_ref: "actor_smith", principal_ref: "dev_smith" });
});

Deno.test("Action wiring 37: a lease lapsing after the attestation is taken again, and the success entry lands", () => {
  const w = world();
  smith(w);
  w.f.between("after-attest", () => w.seam.advance(CONFIG.attestCompletionBoundMs));
  assertEquals(w.aa.attest("dev_smith", "c1", "smith-signing-key"), { ok: "attestation-001" });
  assertEquals(w.aa.log().map((e) => e.outcome), ["success"]);
});

Deno.test("Capability requirement 11 and Housekeeping 5: no start on an unset bound; a young credential is not examined", () => {
  const w = world();
  const { clockOffsetAllowanceMs: _, ...partial } = CONFIG;
  assertThrows(() => AuthenticatedActor.start(w.db, w.seam, w.f, w.sections, partial));
  w.f.arm("binding.write");
  w.aa.register("dev_smith", "actor_smith", "smith-fido2");
  w.seam.advance(CONFIG.registrationCompletionBoundMs + CONFIG.clockOffsetAllowanceMs - 1);
  assertEquals(w.aa.orphanedCredentials(), []);
  w.seam.advance(2);
  assertEquals(AuthenticatedActor.start(w.db, w.seam, w.f, w.sections, CONFIG).report, ["credential-001"]); // Housekeeping 1
});
