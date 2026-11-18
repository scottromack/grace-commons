// Beacon's People & Permissions part: who sees it, what each person holds and is offered, giving and taking away, the history, the pending invitations (SPEC.md, People & Permissions).
import { test, expect, afterAll } from "bun:test";
import { Store } from "../src/store.ts";
import { testSeam } from "../src/seam.ts";
import { Beacon, readContext } from "../src/beacon.ts";
import { type LoggedEvent } from "../src/event_log.ts";
import { ADMIN_WORDS, type PeopleView } from "../src/beacon_admin.ts";
import { PERMISSIONS } from "../src/beacon_domain.ts";

const store = new Store();
afterAll(() => store.close());
const DAY = 86_400_000;
const world = async () => {
  const seam = testSeam("2026-09-01T10:00:00.000Z");
  const prefix = `bm_${crypto.randomUUID().replaceAll("-", "_")}_`;
  const b = await Beacon.open(store, { seam, prefix, argon: { memoryCost: 1024, timeCost: 1 }, scrypt: { N: 1024, r: 8, p: 1 } });
  await b.seed();
  const sign = async (email: string, pw: string) => { const s = (await b.signIn(email, pw)) as { session_token: string; person: { actor_ref: string } }; return { token: s.session_token, ref: s.person.actor_ref, key: b.keyOf(s.session_token)! }; };
  const anya = await sign("anya@beacon.clinical", "demo-pi"), jordan = await sign("jordan@beacon.clinical", "demo-cra");
  let n = 0;
  const pat = async (name = "Pat Rivera") => {
    const t = ((await b.invite(anya.token, `pat${++n}@beacon.clinical`, name, "coordinator")) as { invitation_token: string }).invitation_token;
    const a = (await b.acceptInvitation(t, "password1", "password1")) as { session_token: string; person: { actor_ref: string } };
    return { token: a.session_token, ref: a.person.actor_ref, key: b.keyOf(a.session_token)! };
  };
  const events = async () => ((await b.log.read({ sequence: { from: 1 } })) as LoggedEvent[]).map((e) => e.data as { action_ref: string; actor_ref: string; data: Record<string, unknown> });
  const view = async (who: { ref: string }) => (await b.peopleAdmin.view(who.ref, readContext)) as PeopleView;
  return { b, seam, anya, jordan, pat, events, view };
};

test("SPEC.md People & Permissions: a person who holds `invite_actor` or `grant_permission` sees each person once with what that person holds now; a person who holds neither is refused", async () => {
  const w = await world();
  const v = await w.view(w.anya);
  expect(v.people.map((p) => p.person.email).sort()).toEqual(["anya@beacon.clinical", "jordan@beacon.clinical"]);
  expect(v).toMatchObject({ may_grant: true, may_invite: true });
  expect(v.people.find((p) => p.person.email === "jordan@beacon.clinical")!.held).toEqual(["view_audit"]);
  expect(await w.b.peopleAdmin.view(w.jordan.ref, readContext)).toEqual({ refused: "access-denied", needs: ["invite_actor", "grant_permission"] });
  expect(await w.b.peopleAdmin.view("", readContext)).toEqual({ refused: "invalid-request" });
}, 90000);

test("SPEC.md People & Permissions 1: the permissions a person does not hold are offered to give, and only those; a person who holds all seven has none offered", async () => {
  const w = await world();
  const v = await w.view(w.anya);
  const jordan = v.people.find((p) => p.person.email === "jordan@beacon.clinical")!;
  expect(jordan.offered).toEqual(PERMISSIONS.map((p) => p.code).filter((c) => c !== "view_audit"));
  expect(jordan.held.filter((c) => jordan.offered.includes(c))).toEqual([]);
  const anya = v.people.find((p) => p.person.email === "anya@beacon.clinical")!;
  expect(anya.offered).toEqual(["view_own_audit"]);
  for (const c of anya.offered) await w.b.peopleAdmin.give(w.anya.ref, w.anya.key, w.anya.ref, c);
  const all = (await w.view(w.anya)).people.find((p) => p.person.email === "anya@beacon.clinical")!;
  expect([all.held.length, all.offered]).toEqual([7, []]);
}, 90000);

test("SPEC.md People & Permissions 1, Attributed Permissions Admin: giving a permission is attested by the person who gives it, with that person's key; the grantee holds it, and `grant.issued` is written under the giver with the grant, the grantee and the permission", async () => {
  const w = await world();
  const p = await w.pat();
  const r = await w.b.peopleAdmin.give(w.anya.ref, w.anya.key, p.ref, "enroll_subject");
  expect(r).toHaveProperty("grant_id");
  expect(await w.b.domain.held(p.ref)).toEqual(["enroll_subject"]);
  const a = (await w.b.admin.verifyGrantAttribution((r as { grant_id: string }).grant_id)) as { issuance_attestation_id: string; issuance_verify_result: string };
  expect(a.issuance_verify_result).toBe("verified");
  expect((await w.b.actors.read()).find((x) => x.attestation_id === a.issuance_attestation_id)!.actor_ref).toBe(w.anya.ref);
  const e = (await w.events()).filter((x) => x.action_ref === "grant.issued");
  expect(e).toHaveLength(1);
  expect(e[0]).toMatchObject({ actor_ref: w.anya.ref, data: { target: (r as { grant_id: string }).grant_id, grantee: p.ref, permission: "enroll_subject" } });
}, 90000);

test("SPEC.md People & Permissions: only a person who holds `grant_permission` gives or takes away; a permission already held, one not held, an unknown person and an unknown permission are each refused with their words, and nothing is written", async () => {
  const w = await world();
  const p = await w.pat();
  await w.b.peopleAdmin.give(w.anya.ref, w.anya.key, p.ref, "enroll_subject");
  const n = (await w.b.permissions.read()).length, ev = (await w.events()).length;
  expect(await w.b.peopleAdmin.give(w.jordan.ref, w.jordan.key, p.ref, "record_visit")).toEqual({ refused: "access-denied", needs: ["grant_permission"] });
  expect(await w.b.peopleAdmin.take(w.jordan.ref, w.jordan.key, p.ref, "enroll_subject")).toEqual({ refused: "access-denied", needs: ["grant_permission"] });
  expect(await w.b.peopleAdmin.give(w.anya.ref, w.anya.key, p.ref, "enroll_subject")).toEqual({ refused: "invalid-request", message: ADMIN_WORDS.held });
  expect(await w.b.peopleAdmin.take(w.anya.ref, w.anya.key, p.ref, "record_visit")).toEqual({ refused: "invalid-request", message: ADMIN_WORDS.notHeld });
  expect(await w.b.peopleAdmin.give(w.anya.ref, w.anya.key, "nobody", "record_visit")).toEqual({ refused: "not-found", message: ADMIN_WORDS.noPerson });
  expect(await w.b.peopleAdmin.give(w.anya.ref, w.anya.key, p.ref, "make_coffee")).toEqual({ refused: "invalid-request", message: ADMIN_WORDS.noPermission });
  expect(await w.b.peopleAdmin.give(w.anya.ref, "", p.ref, "record_visit")).toEqual({ refused: "invalid-request" });
  expect((await w.b.permissions.read()).length).toBe(n);
  expect((await w.events()).length).toBe(ev);
}, 90000);

test("SPEC.md People & Permissions 1: taking a permission away takes it whole, attested by the person who takes it, with one `grant.revoked` event for each grant taken; the person no longer holds it", async () => {
  const w = await world();
  const p = await w.pat();
  const g = (await w.b.peopleAdmin.give(w.anya.ref, w.anya.key, p.ref, "enroll_subject")) as { grant_id: string };
  expect(await w.b.peopleAdmin.take(w.anya.ref, w.anya.key, p.ref, "enroll_subject")).toEqual({ revoked: 1 });
  expect(await w.b.domain.held(p.ref)).toEqual([]);
  const e = (await w.events()).filter((x) => x.action_ref === "grant.revoked");
  expect(e).toHaveLength(1);
  expect(e[0]).toMatchObject({ actor_ref: w.anya.ref, data: { target: g.grant_id, grantee: p.ref, permission: "enroll_subject" } });
  expect(typeof e[0].data.reason).toBe("string");
  const a = (await w.b.admin.verifyGrantAttribution(g.grant_id)) as { revocation_attestation_id?: string; revocation_verify_result?: string };
  expect(a.revocation_verify_result).toBe("verified");
  expect((await w.b.actors.read()).find((x) => x.attestation_id === a.revocation_attestation_id)!.actor_ref).toBe(w.anya.ref);
  expect(await w.b.peopleAdmin.give(w.anya.ref, w.anya.key, p.ref, "enroll_subject")).toHaveProperty("grant_id");   // and may be given again
}, 90000);

test("SPEC.md People & Permissions 2: the history lists every permission ever given, oldest first, to whom, which, by whom, and whether it is held now, the revoked ones marked", async () => {
  const w = await world();
  const p = await w.pat("Pat Rivera");
  w.seam.advance(60_000);
  await w.b.peopleAdmin.give(w.anya.ref, w.anya.key, p.ref, "enroll_subject");
  w.seam.advance(60_000);
  await w.b.peopleAdmin.take(w.anya.ref, w.anya.key, p.ref, "enroll_subject");
  w.seam.advance(60_000);
  await w.b.peopleAdmin.give(w.anya.ref, w.anya.key, p.ref, "enroll_subject");
  const h = (await w.view(w.anya)).history;
  expect(h).toHaveLength(7 + 2);                                                                                    // the seed's seven and the two grants of one permission over time
  expect(h.map((x) => x.granted_at)).toEqual([...h.map((x) => x.granted_at)].sort());
  const mine = h.filter((x) => x.to === "Pat Rivera");
  expect(mine.map((x) => [x.code, x.by, x.held_now])).toEqual([["enroll_subject", "Dr. Anya Okonkwo", false], ["enroll_subject", "Dr. Anya Okonkwo", true]]);
  expect(mine[0].revoked_at).not.toBeNull();
  expect(mine[1].revoked_at).toBeNull();
  expect(h.slice(0, 7).every((x) => x.by === "Dr. Anya Okonkwo" && x.held_now)).toBe(true);                         // the seed's, given by the principal investigator
}, 90000);

test("SPEC.md People & Permissions 3: the pending invitations are listed with email, role, name and expiry, and leave the list once accepted, revoked or expired", async () => {
  const w = await world();
  const t1 = ((await w.b.invite(w.anya.token, "a@b.c", "A", "coordinator")) as { invitation_token: string }).invitation_token;
  w.seam.advance(1000);
  const t2 = ((await w.b.invite(w.anya.token, "d@e.f", "D", "monitor")) as { invitation_token: string }).invitation_token;
  w.seam.advance(1000);
  const t3 = ((await w.b.invite(w.anya.token, "g@h.i", "G", "monitor")) as { invitation_token: string }).invitation_token;
  let v = await w.view(w.anya);
  expect(v.pending.map((x) => [x.email, x.role, x.display_name])).toEqual([["a@b.c", "coordinator", "A"], ["d@e.f", "monitor", "D"], ["g@h.i", "monitor", "G"]]);
  expect(Date.parse(v.pending[0].expires_at) - Date.parse("2026-09-01T10:00:00.000Z")).toBe(7 * DAY);                 // the first, made at the start
  await w.b.acceptInvitation(t1, "password1", "password1");
  await w.b.revokeInvitation(w.anya.token, t2);
  expect((await w.view(w.anya)).pending.map((x) => x.invitation_token)).toEqual([t3]);
  w.seam.advance(8 * DAY);
  expect((await w.view(w.anya)).pending).toEqual([]);
}, 90000);

test("SPEC.md People & Permissions: a person who holds `invite_actor` alone sees the page without the right to give or take away; one who holds `grant_permission` alone, without the right to invite", async () => {
  const w = await world();
  const inviter = await w.pat("Inviter"), granter = await w.pat("Granter");
  await w.b.peopleAdmin.give(w.anya.ref, w.anya.key, inviter.ref, "invite_actor");
  await w.b.peopleAdmin.give(w.anya.ref, w.anya.key, granter.ref, "grant_permission");
  expect(await w.view(inviter)).toMatchObject({ may_grant: false, may_invite: true });
  expect(await w.view(granter)).toMatchObject({ may_grant: true, may_invite: false });
  expect(await w.b.peopleAdmin.give(inviter.ref, inviter.key, granter.ref, "record_visit")).toEqual({ refused: "access-denied", needs: ["grant_permission"] });
}, 90000);
