// Beacon's composition root: the seed, signing in and out, and the one identifier that runs through the patterns, one test for each thing SPEC.md says.
import { test, expect, afterAll } from "bun:test";
import { Store } from "../src/store.ts";
import { testSeam } from "../src/seam.ts";
import { Beacon, SEED, partyFor } from "../src/beacon.ts";
import { type LoggedEvent } from "../src/event_log.ts";

const store = new Store();
afterAll(() => store.close());
const world = async () => {
  const seam = testSeam("2026-09-01T10:00:00.000Z");
  const prefix = `bc_${crypto.randomUUID().replaceAll("-", "_")}_`;
  const b = await Beacon.open(store, { seam, prefix, argon: { memoryCost: 1024, timeCost: 1 }, scrypt: { N: 1024, r: 8, p: 1 } });
  await b.seed();
  const events = async () => ((await b.log.read({ sequence: { from: 1 } })) as LoggedEvent[]).map((e) => e.data as { action_ref: string; actor_ref: string; data: Record<string, unknown> });
  return { b, seam, events };
};
type W = Awaited<ReturnType<typeof world>>;
const who = async (w: W, email: string) => (await w.b.people.byEmail(email))!;

test("SPEC.md People, The data a render starts from: the seed makes the two accounts with the words it names and the permissions they start with, and makes nothing twice", async () => {
  const w = await world();
  const people = await w.b.people.list();
  expect(people.map((p) => [p.email, p.display_name])).toEqual([["anya@beacon.clinical", "Dr. Anya Okonkwo"], ["jordan@beacon.clinical", "Jordan Lee"]]);
  expect(await w.b.domain.held((await who(w, "anya@beacon.clinical")).actor_ref)).toEqual(["invite_actor", "grant_permission", "enroll_subject", "record_visit", "view_audit", "view_all_subjects"]);
  expect(await w.b.domain.held((await who(w, "jordan@beacon.clinical")).actor_ref)).toEqual(["view_audit"]);
  const grants = (await w.b.permissions.read()).length;
  expect(grants).toBe(7);
  await w.b.seed();
  expect(await w.b.people.list()).toHaveLength(2);
  expect((await w.b.permissions.read()).length).toBe(7);
  expect(SEED.map((s) => s.password)).toEqual(["demo-pi", "demo-cra"]);
});

test("SPEC.md People: one identifier runs through the patterns, the party id as the actor reference, the credential's principal and the holder of permissions; Party Identity holds the placeholders SPEC names", async () => {
  const w = await world();
  const anya = await who(w, "anya@beacon.clinical");
  const party = (await w.b.parties.read({ party_id: anya.party_id })) as { party_id: string; name: string; date_of_birth: string; document_type: string; document_ref: string; state: string }[];
  expect(party[0]).toMatchObject({ party_id: anya.party_id, name: "Dr. Anya Okonkwo", ...{ date_of_birth: "1900-01-01", document_type: "beacon-account", document_ref: "anya@beacon.clinical" }, state: "unverified" });
  expect(partyFor("N", "e@x.y")).toEqual({ name: "N", date_of_birth: "1900-01-01", document_type: "beacon-account", document_ref: "e@x.y" });
  expect(anya.actor_ref).toBe(anya.party_id);
  expect((await w.b.credentials.read({ principal_ref: anya.party_id }))[0]).toMatchObject({ credential_type: "password", status: "active" });
  expect(await w.b.permissions.permitted(anya.party_id, "enroll_subject")).toBe("permitted");
});

test("Attributed Permissions Admin Action wiring 2, 17 through SPEC.md: every seeded grant carries an attestation by the principal investigator, which verifies", async () => {
  const w = await world();
  const anya = await who(w, "anya@beacon.clinical");
  for (const g of await w.b.permissions.read()) {
    const v = (await w.b.admin.verifyGrantAttribution(g.grant_id)) as { issuance_attestation_id: string; issuance_verify_result: string };
    expect(v.issuance_verify_result).toBe("verified");
    expect((await w.b.actors.read()).find((a) => a.attestation_id === v.issuance_attestation_id)!.actor_ref).toBe(anya.actor_ref);
  }
});

test("SPEC.md Sign in, Login: a correct email and password open a session, hold the person's key for it, and write the login event under the service identity; who the session is and what the person holds are answered", async () => {
  const w = await world();
  const s = await w.b.signIn("Anya@Beacon.Clinical ", "demo-pi");
  expect(s).toHaveProperty("session_token");
  const t = (s as { session_token: string }).session_token;
  const me = (await w.b.who(t))!;
  expect(me.person.email).toBe("anya@beacon.clinical");
  expect(me.holds).toContain("grant_permission");
  expect(w.b.keyOf(t)).toBe(await w.b.people.unlock(me.person.actor_ref, "demo-pi"));
  const login = (await w.events()).filter((e) => e.action_ref === "login_succeeded");
  expect(login).toHaveLength(1);
  expect(login[0].actor_ref).not.toBe(me.person.actor_ref);                                                         // attested under Login's service identity, not the person
  expect(login[0].data).toMatchObject({ principal_ref: me.person.party_id, session_token: t });
});

test("SPEC.md Sign in: a wrong password and an unknown email answer alike, and each is logged as a failed login; a blank field is invalid-request", async () => {
  const w = await world();
  expect(await w.b.signIn("anya@beacon.clinical", "wrong")).toEqual({ refused: "invalid-credential" });
  expect(await w.b.signIn("nobody@beacon.clinical", "demo-pi")).toEqual({ refused: "invalid-credential" });
  expect(await w.b.signIn("", "demo-pi")).toEqual({ refused: "invalid-request" });
  expect(await w.b.signIn("anya@beacon.clinical", "")).toEqual({ refused: "invalid-request" });
  expect((await w.events()).filter((e) => e.action_ref === "login_failed")).toHaveLength(2);
  expect(w.b.keys.size).toBe(0);                                                                                    // no key was held
});

test("SPEC.md Sign out: the session is revoked through the system's own call and the key it held is dropped", async () => {
  const w = await world();
  const t = ((await w.b.signIn("anya@beacon.clinical", "demo-pi")) as { session_token: string }).session_token;
  expect(w.b.keys.size).toBe(1);
  await w.b.signOut(t);
  expect(w.b.keys.size).toBe(0);                                                                                    // dropped by the sign-out itself
  expect((await w.b.session.validate(t))).toHaveProperty("invalid");                                                // the system's own call revoked the session
  expect(await w.b.who(t)).toBeNull();
  expect(w.b.keyOf(t)).toBeNull();
  expect((await w.events()).filter((e) => e.action_ref === "logout_succeeded")).toHaveLength(1);
});

test("SPEC.md People & Permissions (a session lasts seven days): a session past its time is no one, and its key is dropped", async () => {
  const w = await world();
  const t = ((await w.b.signIn("jordan@beacon.clinical", "demo-cra")) as { session_token: string }).session_token;
  w.seam.advance(6 * 86_400_000);
  expect(await w.b.who(t)).not.toBeNull();
  expect(w.b.keyOf(t)).not.toBeNull();
  w.seam.advance(2 * 86_400_000);
  expect(w.b.keyOf(t)).toBeNull();                                                                                  // the key's own time is the session's, not a look at who
  expect(await w.b.who(t)).toBeNull();
  expect(w.b.keys.size).toBe(0);
});

test("Session-Gated Authorization: a signed-in person's permissions are the ones held by the party the session names", async () => {
  const w = await world();
  const anya = ((await w.b.signIn("anya@beacon.clinical", "demo-pi")) as { session_token: string }).session_token;
  const jordan = ((await w.b.signIn("jordan@beacon.clinical", "demo-cra")) as { session_token: string }).session_token;
  expect(await w.b.gate.checkPermitted(anya, "enroll_subject")).toBe("permitted");
  expect(await w.b.gate.checkPermitted(jordan, "enroll_subject")).toBe("denied");
  expect(await w.b.gate.checkPermitted(jordan, "view_audit")).toBe("permitted");
});

test("The held key does the work: a signed-in person gives a permission through Attributed Permissions Admin and enrolls a subject, each attested by that person", async () => {
  const w = await world();
  const t = ((await w.b.signIn("anya@beacon.clinical", "demo-pi")) as { session_token: string }).session_token;
  const anya = (await w.b.who(t))!.person;
  const jordan = await who(w, "jordan@beacon.clinical");
  const key = w.b.keyOf(t)!;
  const g = (await w.b.admin.issueGrant(jordan.actor_ref, "enroll_subject", anya.actor_ref, key)) as { grant_id: string };
  expect((await w.b.admin.verifyGrantAttribution(g.grant_id)) as { issuance_verify_result: string }).toMatchObject({ issuance_verify_result: "verified" });
  expect(await w.b.domain.held(jordan.actor_ref)).toEqual(["enroll_subject", "view_audit"]);
  const s = await w.b.domain.enrollSubject(anya.actor_ref, key, "first");
  expect(s).toMatchObject({ code: "BCN-001", enrolled_by: anya.actor_ref });
  expect((await w.events()).find((e) => e.action_ref === "subject.enrolled")!.actor_ref).toBe(anya.actor_ref);
});
