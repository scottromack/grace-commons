// External Onboarding. Each test names the rule it holds.
import { assert, assertEquals, assertThrows } from "@std/assert";
import { CriticalSection, ExternalOnboarding } from "../src/composition.ts";
import { credential, partyIdentity } from "../src/atoms.ts";
import { openStore } from "../src/store.ts";
import { manualSeam } from "../src/seam.ts";
import { Faults } from "../src/faults.ts";
import { AFTER, config, world } from "./helpers.ts";

const parties = (w: ReturnType<typeof world>) => (partyIdentity.read(w.db, {}) as { ok: { party_id: string }[] }).ok;

Deno.test("invite then onboard: one party, one credential naming it, one completion record naming the whole arc (Action wiring 1 through 38; Invariant 3.1, 5.1)", () => {
  const w = world();
  const token = w.invite();
  const r = w.eo.onboard(w.input(token));
  assert("ok" in r);
  const [c] = w.of("onboarding.completed");
  assertEquals(c.data, { invitation_token: token, accepting_identity_ref: "idp:maya", party_id: r.ok.party_id, credential_id: r.ok.credential_id });
  assertEquals(credential.read(w.db, { principal_ref: r.ok.party_id }).length, 1);
  assertEquals(w.eo.events().map((e) => e.action_ref), ["invitation.initiate-attempt", "invitation.initiated", "onboarding.accept-attempt",
    "onboarding.invitation-accepted", "onboarding.completed"]);
  assertEquals(w.of("invitation.initiated")[0].actor_ref, "hr_admin");                            // Composes 14
  assertEquals(c.actor_ref, "onboarding_svc");
});

Deno.test("a credential that does not validate stops the action at its attempt record (Audit arm 1, 4; Action wiring 1, 2)", () => {
  const w = world();
  const token = w.invite();
  assertEquals(w.eo.onboard(w.input(token, { actor_credential: "wrong" })), { refused: "invalid-credential" });
  assertEquals(parties(w).length, 0);
  assertEquals(w.eo.onboard(w.input(token)).hasOwnProperty("ok"), true);                          // the invitation was never consumed
});

Deno.test("fields are validated against the constituents' rules before anything is recorded (Primitive policy 1 through 4, 10)", () => {
  const w = world();
  const token = w.invite();
  const n = w.eo.events().length;
  assertEquals(w.eo.onboard(w.input(token, { date_of_birth: "1990-13-45" })), { refused: "invalid-request" });
  assertEquals(w.eo.onboard(w.input(token, { credential_type: "retina" })), { refused: "invalid-request" });
  assertEquals(w.eo.onboard(w.input(token, { name: " " })), { refused: "invalid-request" });
  assertEquals(w.eo.invite("hr_admin", undefined, "x", 1, "hr_admin-secret"), { refused: "invalid-request" });
  assertEquals(w.eo.events().length, n);
});

Deno.test("a resume choice on a pending invitation is refused before the attempt (Primitive policy 7 through 9)", () => {
  const w = world();
  const token = w.invite();
  const n = w.eo.events().length;
  assertEquals(w.eo.onboard(w.input(token, { resume_party_id: "party-001" })), { refused: "invalid-request" });
  assertEquals(w.eo.events().length, n);
});

Deno.test("the gate's refusals: a second accept, a declined, an expired and an unknown invitation (Action wiring 17 through 24; Wiring decision 3)", () => {
  const w = world();
  const a = w.invite(), b = w.invite(), c = w.invite();
  assert("ok" in w.eo.onboard(w.input(a)));
  assertEquals(w.eo.onboard(w.input(a, { accepting_identity_ref: "idp:other" })), { refused: "invitation-invalid", reason: "already-resolved", stored: "accepted" });
  w.eo.decline(b, "decline_svc", "decline_svc-secret");
  assertEquals(w.eo.onboard(w.input(b)), { refused: "invitation-invalid", reason: "already-resolved", stored: "declined" });
  w.seam.advance(8 * 86_400_000);
  assertEquals(w.eo.onboard(w.input(c)), { refused: "invitation-invalid", reason: "expired" });
  assertEquals(w.eo.onboard(w.input("invitation-999")), { refused: "invitation-invalid", reason: "not-known" });
  assertEquals(parties(w).length, 1);
});

Deno.test("a young acceptance by the same acceptor is not resumed: the in-flight arc is not raced (Term resumable acceptance)", () => {
  const w = world();
  const t = w.invite();
  w.f.arm("credential.register");
  w.eo.onboard(w.input(t));
  assertEquals(w.eo.onboard(w.input(t)), { refused: "invitation-invalid", reason: "already-resolved", stored: "accepted" });
});

Deno.test("decline records no decliner; revoke carries its reason; both relay the gate (Action wiring 40 through 55)", () => {
  const w = world();
  const a = w.invite(), b = w.invite();
  assertEquals(w.eo.decline(a, "decline_svc", "decline_svc-secret"), { ok: "declined" });
  assertEquals(w.of("invitation.declined")[0].data, { invitation_token: a });
  assertEquals(w.eo.decline(a, "decline_svc", "decline_svc-secret"), { refused: "invitation-invalid", reason: "already-resolved", stored: "declined" });
  assertEquals(w.eo.revoke(b, "hr_admin", "position withdrawn", "hr_admin-secret"), { ok: "revoked" });
  assertEquals(w.of("invitation.revoked")[0].data, { invitation_token: b, reason: "position withdrawn" });
  assertEquals(w.eo.revoke("invitation-999", "hr_admin", "x", "hr_admin-secret"), { refused: "invitation-invalid", reason: "not-known" });
});

Deno.test("a register refused on the fresh arc records the interruption; the resume re-enters with the arc's own party (Action wiring 30; Resume 10, 32; Invariant 1.2)", () => {
  const w = world();
  const t = w.invite();
  w.f.arm("credential.register");
  assertEquals(w.eo.onboard(w.input(t)), { refused: "storage-failure", position: "outcome" });
  const [intr] = w.of("onboarding.interrupted");
  assertEquals([intr.data.stage, intr.data.reason], ["credential-registration", "storage-failure"]);
  const party = intr.data.party_id as string;
  w.seam.advance(AFTER);
  const r = w.eo.onboard(w.input(t));
  assert("ok" in r);
  assertEquals(r.ok.party_id, party);
  assertEquals(parties(w).length, 1);
  assertEquals(w.of("onboarding.resume-intended")[0].data.stage, "credential-registration");
});

Deno.test("a crash after enrollment leaves no record of the stage; the resume finds the sole party (Resume 12, 16 through 20)", () => {
  const w = world();
  const t = w.invite();
  w.f.arm("credential.register");
  w.f.arm("log.append:onboarding.interrupted");
  w.eo.onboard(w.input(t));
  assertEquals(w.of("onboarding.interrupted").length, 0);
  w.seam.advance(AFTER);
  const r = w.eo.onboard(w.input(t));
  assert("ok" in r);
  assertEquals(parties(w).length, 1);
  assertEquals(w.of("onboarding.resume-intended")[0].data.stage, "unrecorded");
});

Deno.test("two matching parties are never chosen between; the administrator's choice resumes the arc (Resume 21 through 24)", () => {
  const w = world();
  const t = w.invite();
  w.f.arm("credential.register");
  w.f.arm("log.append:onboarding.interrupted");
  w.eo.onboard(w.input(t));
  partyIdentity.enroll(w.db, w.seam, w.f, "Maya Chen", "1990-04-12", "passport", "P1234567", "onboarding_svc");  // a second, by hand
  w.seam.advance(AFTER);
  const r = w.eo.onboard(w.input(t));
  assert("refused" in r && r.refused === "onboarding-indeterminate");
  const cands = (r as { party_candidates: string[] }).party_candidates;
  assertEquals(cands.length, 2);
  assertEquals(w.eo.onboard(w.input(t, { resume_party_id: "party-999" })), { refused: "invalid-request" });
  const ok = w.eo.onboard(w.input(t, { resume_party_id: cands[1] }));
  assert("ok" in ok);
  assertEquals(ok.ok.party_id, cands[1]);
});

Deno.test("an acceptance record that never landed is written from the Invitation record on resume (Resume 11, 30)", () => {
  const w = world();
  const t = w.invite();
  w.f.arm("log.append:onboarding.invitation-accepted");
  assertEquals(w.eo.onboard(w.input(t)), { refused: "storage-failure", position: "outcome" });
  assertEquals(parties(w).length, 0);
  w.seam.advance(AFTER);
  const r = w.eo.onboard(w.input(t));
  assert("ok" in r);
  assertEquals(w.of("onboarding.resume-intended")[0].data.stage, "acceptance-unrecorded");
  assertEquals(w.of("onboarding.invitation-accepted").length, 1);
});

Deno.test("the credential the arc registered is the one it completes with, found as the sole root in the window (Action wiring 33, 35; Resume 39 through 41)", () => {
  const w = world();
  const t = w.invite();
  w.f.arm("log.append:onboarding.completed");
  assertEquals(w.eo.onboard(w.input(t)), { refused: "storage-failure", position: "outcome" });
  const [cred] = credential.read(w.db, {});
  w.seam.advance(AFTER);
  const r = w.eo.onboard(w.input(t, { credential_material: "a different secret" }));
  assert("ok" in r);
  assertEquals(r.ok.credential_id, cred.credential_id);
  assertEquals(credential.read(w.db, {}).length, 1);
  assertEquals(w.of("onboarding.completed").length, 1);                                           // Invariant 4.4
});

Deno.test("a resume that died before writing the acceptance record resumes at acceptance-unrecorded (Resume 9, 11)", () => {
  const w = world();
  const t = w.invite();
  w.f.arm("log.append:onboarding.invitation-accepted");
  w.eo.onboard(w.input(t));
  w.seam.advance(AFTER);
  w.f.arm("log.append:onboarding.invitation-accepted");
  assertEquals(w.eo.onboard(w.input(t)), { refused: "storage-failure", position: "outcome" });   // the resume record lands, the acceptance record does not
  w.seam.advance(AFTER);
  const r = w.eo.onboard(w.input(t));
  assert("ok" in r);
  assertEquals(w.of("onboarding.resume-intended").map((e) => e.data.stage), ["acceptance-unrecorded", "acceptance-unrecorded"]);
});

Deno.test("a resume whose documents the arc never recorded is refused (Resume 13 through 15)", () => {
  const w = world();
  const t = w.invite();
  w.f.arm("credential.register");
  w.eo.onboard(w.input(t));
  w.seam.advance(AFTER);
  assertEquals(w.eo.onboard(w.input(t, { document_ref: "P0000000" })), { refused: "invalid-request" });
});

Deno.test("a completed arc is not resumed; a young resume record is not raced; an aged acceptance is not re-run (Resume 4, 7, 8)", () => {
  const w = world({ auditHorizonMs: 10 * 86_400_000 });
  const done = w.invite();
  assert("ok" in w.eo.onboard(w.input(done)));
  w.seam.advance(AFTER);
  assertEquals(w.eo.onboard(w.input(done)), { refused: "invitation-invalid", reason: "already-resolved", stored: "accepted" });
  const t = w.invite();
  w.f.arm("credential.register", 2);
  w.eo.onboard(w.input(t));
  w.seam.advance(AFTER);
  w.f.arm("log.append:onboarding.interrupted");
  w.eo.onboard(w.input(t));                                                                        // the resume record lands; its arc stops unrecorded
  w.f.clear();
  assertEquals(w.eo.onboard(w.input(t)), { refused: "invitation-invalid", reason: "already-resolved", stored: "accepted" });  // young: not raced
  w.seam.advance(AFTER);
  assert("ok" in w.eo.onboard(w.input(t)));                                                         // dead: resumed from unrecorded (Resume 9)
  const aged = w.invite();
  w.f.arm("credential.register");
  w.eo.onboard(w.input(aged));
  w.seam.advance(11 * 86_400_000);
  assertEquals(w.eo.onboard(w.input(aged)), { refused: "invitation-invalid", reason: "already-resolved", stored: "accepted" });
});

Deno.test("a fresh arc the host refuses the critical section answers at the outcome (Action wiring 10, 11)", () => {
  const w = world();
  const t = w.invite();
  w.cfg.criticalSection!.take(t);
  assertEquals(w.eo.onboard(w.input(t)), { refused: "storage-failure", position: "outcome" });
  assertEquals(parties(w).length, 0);
});

Deno.test("an instance refuses to start without its bound, its allowance or its critical section, or with a bound past the lease (Capability requirement 17 through 20)", () => {
  const mk = (o: object) => () => ExternalOnboarding.start(openStore(), manualSeam(), new Faults(), undefined as never, config(o));
  assertThrows(mk({ onboardingCompletionBoundMs: undefined }));
  assertThrows(mk({ clockOffsetAllowanceMs: undefined }));
  assertThrows(mk({ criticalSection: undefined }));
  assertThrows(mk({ criticalSection: new CriticalSection(1000) }));
});
