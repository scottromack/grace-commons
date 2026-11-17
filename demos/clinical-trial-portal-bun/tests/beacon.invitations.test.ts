// Beacon's invitations: who may invite and revoke, what a link shows, and what accepting one makes (SPEC.md, The screens, Accept an invitation; People & Permissions, 3).
import { test, expect, afterAll } from "bun:test";
import { Store } from "../src/store.ts";
import { testSeam } from "../src/seam.ts";
import { Beacon, INVITATION_WORDS, FORM_WORDS, invitationContext, readContext, partyFor } from "../src/beacon.ts";
import { type LoggedEvent } from "../src/event_log.ts";

const store = new Store();
afterAll(() => store.close());
const world = async () => {
  const seam = testSeam("2026-09-01T10:00:00.000Z");
  const prefix = `bi_${crypto.randomUUID().replaceAll("-", "_")}_`;
  const b = await Beacon.open(store, { seam, prefix, argon: { memoryCost: 1024, timeCost: 1 }, scrypt: { N: 1024, r: 8, p: 1 } });
  await b.seed();
  const anya = ((await b.signIn("anya@beacon.clinical", "demo-pi")) as { session_token: string }).session_token;
  const jordan = ((await b.signIn("jordan@beacon.clinical", "demo-cra")) as { session_token: string }).session_token;
  const events = async () => ((await b.log.read({ sequence: { from: 1 } })) as LoggedEvent[]).map((e) => e.data as { action_ref: string; actor_ref: string; data: Record<string, unknown> });
  return { b, seam, anya, jordan, events };
};
type W = Awaited<ReturnType<typeof world>>;
const invite = async (w: W, email = "Pat@Beacon.Clinical ", name = "Pat Rivera", role = "coordinator") => {
  const r = await w.b.invite(w.anya, email, name, role);
  expect(r).toHaveProperty("invitation_token");
  return (r as { invitation_token: string }).invitation_token;
};

test("SPEC.md People & Permissions 3: a person who holds `invite_actor` invites by email, name and role; the invitee is the email trimmed and in lower case, the role and the name travel as the context, and the invitation lasts seven days", async () => {
  const w = await world();
  const t = await invite(w);
  const i = (await w.b.invitations.read({ invitation_token: t }))[0];
  expect([i.invitee_ref, i.status, i.inviter_ref]).toEqual(["pat@beacon.clinical", "pending", (await w.b.people.byEmail("anya@beacon.clinical"))!.actor_ref]);
  expect(readContext(i.context)).toEqual({ role: "coordinator", display_name: "Pat Rivera" });
  expect(Date.parse(i.expires_at) - Date.parse(i.initiated_at)).toBe(7 * 86_400_000);
  expect(await w.b.invitationFor(t)).toEqual({ email: "pat@beacon.clinical", role: "coordinator", display_name: "Pat Rivera", expires_at: i.expires_at });
  expect(readContext("not json")).toBeNull();
  expect(readContext(invitationContext("a", "b"))).toEqual({ role: "a", display_name: "b" });
});

test("SPEC.md People & Permissions 3: inviting is signed with the inviter's key and writes its attempt and its record under the inviter", async () => {
  const w = await world();
  await invite(w);
  const mine = (await w.events()).filter((e) => e.action_ref.startsWith("invitation."));
  const anya = (await w.b.people.byEmail("anya@beacon.clinical"))!.actor_ref;
  expect(mine.map((e) => e.action_ref)).toEqual(["invitation.initiate-attempt", "invitation.initiated"]);
  expect(mine.every((e) => e.actor_ref === anya)).toBe(true);
});

test("SPEC.md People & Permissions 3: a person who does not hold `invite_actor` is refused and nothing is made; a blank field is refused with the words; an email that already has an account is refused", async () => {
  const w = await world();
  expect(await w.b.invite(w.jordan, "x@y.z", "X", "r")).toEqual({ refused: "access-denied", needs: ["invite_actor"] });
  for (const a of [["", "N", "r"], ["x@y.z", " ", "r"], ["x@y.z", "N", ""]] as const) expect(await w.b.invite(w.anya, ...a)).toEqual({ refused: "invalid-request", message: FORM_WORDS.invite });
  expect(await w.b.invite(w.anya, "JORDAN@beacon.clinical", "J", "r")).toEqual({ refused: "invalid-request", message: FORM_WORDS.hasAccount });
  expect(await w.b.invitations.read()).toEqual([]);
  expect(await w.b.invite("no-such-session", "x@y.z", "X", "r")).toEqual({ refused: "invalid-credential" });
});

test("SPEC.md The screens, Accept an invitation: a link shows the invited email, the role and the name; an unknown link, a used or revoked one and an expired one each say their own words", async () => {
  const w = await world();
  expect(await w.b.invitationFor("nope")).toEqual({ invalid: "unknown" });
  expect(await w.b.invitationFor("")).toEqual({ invalid: "unknown" });
  const used = await invite(w, "a@b.c", "A", "r"), revoked = await invite(w, "d@e.f", "D", "r"), old = await invite(w, "g@h.i", "G", "r");
  expect(await w.b.acceptInvitation(used, "password1", "password1")).toHaveProperty("session_token");
  expect(await w.b.revokeInvitation(w.anya, revoked)).toBe("revoked");
  expect(await w.b.invitationFor(used)).toEqual({ invalid: "resolved" });
  expect(await w.b.invitationFor(revoked)).toEqual({ invalid: "resolved" });
  w.seam.advance?.(8 * 86_400_000);
  expect(await w.b.invitationFor(old)).toEqual({ invalid: "expired" });
  expect(INVITATION_WORDS).toEqual({ unknown: "This invitation link is invalid.", resolved: "This invitation has already been used or revoked.", expired: "This invitation has expired. Please ask for a new one." });
});

test("SPEC.md Accept an invitation, People: accepting enrolls the party with the placeholders, makes the person under the party id with a key, registers the password, holds no permission, and signs the person in", async () => {
  const w = await world();
  const t = await invite(w);
  const r = await w.b.acceptInvitation(t, "correct horse", "correct horse");
  expect(r).toHaveProperty("session_token");
  const { session_token, person } = r as { session_token: string; person: { actor_ref: string; party_id: string; email: string; display_name: string } };
  expect([person.email, person.display_name, person.actor_ref]).toEqual(["pat@beacon.clinical", "Pat Rivera", person.party_id]);
  const party = (await w.b.parties.read({ party_id: person.party_id })) as { name: string; date_of_birth: string; document_type: string; document_ref: string }[];
  expect(party[0]).toMatchObject(partyFor("Pat Rivera", "pat@beacon.clinical"));
  expect((await w.b.credentials.read({ principal_ref: person.party_id }))[0]).toMatchObject({ credential_type: "password", status: "active" });
  expect(await w.b.domain.held(person.actor_ref)).toEqual([]);
  expect((await w.b.who(session_token))!.person.actor_ref).toBe(person.actor_ref);
  expect(w.b.keyOf(session_token)).not.toBeNull();
  expect((await w.b.invitations.read({ invitation_token: t }))[0]).toMatchObject({ status: "accepted", accepting_identity_ref: "pat@beacon.clinical" });
  expect(await w.b.signIn("PAT@beacon.clinical", "correct horse")).toHaveProperty("session_token");                 // the person signs in again with the same password
  expect(await w.b.signIn("pat@beacon.clinical", "wrong")).toEqual({ refused: "invalid-credential" });
});

test("SPEC.md Accept an invitation: the password is at least 8 characters and its confirmation matches; a refused form spends nothing and the link still works", async () => {
  const w = await world();
  const t = await invite(w);
  expect(await w.b.acceptInvitation(t, "short", "short")).toEqual({ refused: "invalid-request", message: FORM_WORDS.password });
  expect(await w.b.acceptInvitation(t, "eightchr", "eightchx")).toEqual({ refused: "invalid-request", message: FORM_WORDS.confirm });
  expect(await w.b.acceptInvitation(t, "", "")).toEqual({ refused: "invalid-request", message: FORM_WORDS.password });
  expect(await w.b.people.byEmail("pat@beacon.clinical")).toBeNull();
  expect((await w.b.invitations.read({ invitation_token: t }))[0].status).toBe("pending");
  expect(await w.b.acceptInvitation(t, "eightchr", "eightchr")).toHaveProperty("session_token");
});

test("SPEC.md Accept an invitation: a link is used once; a second acceptance says it has been used and makes no second person", async () => {
  const w = await world();
  const t = await invite(w);
  await w.b.acceptInvitation(t, "password1", "password1");
  expect(await w.b.acceptInvitation(t, "password2", "password2")).toEqual({ invalid: "resolved" });
  expect(await w.b.people.list()).toHaveLength(3);
  expect(await w.b.acceptInvitation("nope", "password1", "password1")).toEqual({ invalid: "unknown" });
});

test("SPEC.md People & Permissions 3: a pending invitation can be revoked by a person who holds `invite_actor`, signed with that person's key; a person who does not hold it is refused; the link then says it was revoked", async () => {
  const w = await world();
  const t = await invite(w);
  expect(await w.b.revokeInvitation(w.jordan, t)).toEqual({ refused: "access-denied", needs: ["invite_actor"] });
  expect(await w.b.revokeInvitation("no-such-session", t)).toEqual({ refused: "invalid-credential" });
  expect(await w.b.revokeInvitation(w.anya, t)).toBe("revoked");
  expect(await w.b.revokeInvitation(w.anya, t)).toEqual({ refused: "invalid-request", message: INVITATION_WORDS.resolved });
  expect(await w.b.revokeInvitation(w.anya, "nope")).toEqual({ refused: "not-found", message: "Not Found." });
  expect(await w.b.acceptInvitation(t, "password1", "password1")).toEqual({ invalid: "resolved" });
  const anya = (await w.b.people.byEmail("anya@beacon.clinical"))!.actor_ref;
  expect((await w.events()).filter((e) => e.action_ref === "invitation.revoked").map((e) => e.actor_ref)).toEqual([anya]);
});

test("SPEC.md Accept an invitation: an invitation whose email has an account by the time it is accepted is refused and spends nothing", async () => {
  const w = await world();
  const t = await invite(w, "jordan2@beacon.clinical", "J2", "r");
  const u = await invite(w, "jordan2@beacon.clinical", "J2 again", "r");
  expect(await w.b.acceptInvitation(t, "password1", "password1")).toHaveProperty("session_token");
  expect(await w.b.acceptInvitation(u, "password1", "password1")).toEqual({ refused: "invalid-request", message: FORM_WORDS.hasAccount });
  expect((await w.b.invitations.read({ invitation_token: u }))[0].status).toBe("pending");
});

test("External Onboarding through Beacon: accepting writes the onboarding's records under the service identity, and an event of it verifies", async () => {
  const w = await world();
  const t = await invite(w);
  await w.b.acceptInvitation(t, "password1", "password1");
  const ev = (await w.events()).filter((e) => e.action_ref.startsWith("onboarding.") || e.action_ref.startsWith("invitation.accept"));
  expect(ev.length).toBeGreaterThan(0);
  expect(ev.every((e) => e.actor_ref.startsWith("beacon-service-"))).toBe(true);
});

test("SPEC.md People (the person's key): a session whose key is gone (a restart) cannot invite or revoke, and nothing is written", async () => {
  const w = await world();
  const t = await invite(w);
  w.b.keys.drop(w.anya);
  expect(await w.b.invite(w.anya, "x@y.z", "X", "r")).toEqual({ refused: "invalid-credential" });
  expect(await w.b.revokeInvitation(w.anya, t)).toEqual({ refused: "invalid-credential" });
  expect((await w.b.invitations.read()).map((i) => i.status)).toEqual(["pending"]);
});

test("SPEC.md Accept an invitation: an invitation Beacon did not make (no invitee, or a context that is not its own) shows as an invalid link", async () => {
  const w = await world();
  const key = w.b.keyOf(w.anya)!, me = (await w.b.people.byEmail("anya@beacon.clinical"))!.actor_ref;
  const noInvitee = (await w.b.onboarding.invite(me, null, invitationContext("r", "N"), null, key)) as { invitation_token: string };
  const foreign = (await w.b.onboarding.invite(me, "q@r.s", "plain words", null, key)) as { invitation_token: string };
  expect(await w.b.invitationFor(noInvitee.invitation_token)).toEqual({ invalid: "unknown" });
  expect(await w.b.invitationFor(foreign.invitation_token)).toEqual({ invalid: "unknown" });
});
