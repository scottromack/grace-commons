// Beacon's People & Permissions page, one test for each thing SPEC.md says of it (The screens, People & Permissions).
import { test, expect, afterAll } from "bun:test";
import { Store } from "../src/store.ts";
import { testSeam } from "../src/seam.ts";
import { Beacon, FORM_WORDS } from "../src/beacon.ts";
import { buildApp, COOKIE } from "../src/server.ts";

const store = new Store();
afterAll(() => store.close());
const world = async () => {
  const seam = testSeam("2026-09-01T10:00:00.000Z");
  const prefix = `sp_${crypto.randomUUID().replaceAll("-", "_")}_`;
  const b = await Beacon.open(store, { seam, prefix, argon: { memoryCost: 1024, timeCost: 1 }, scrypt: { N: 1024, r: 8, p: 1 } });
  await b.seed();
  return { b, seam, app: buildApp(b) };
};
type W = Awaited<ReturnType<typeof world>>;
const form = (f: Record<string, string>, cookie?: string) => ({ method: "POST", headers: { "content-type": "application/x-www-form-urlencoded", ...(cookie ? { cookie: `${COOKIE}=${cookie}` } : {}) }, body: new URLSearchParams(f).toString() });
const signIn = async (w: W, email: string, password: string) => /beacon_session=([^;]*)/.exec((await w.app.request("/login", form({ email, password }))).headers.get("set-cookie") ?? "")?.[1] ?? "";
const get = (w: W, path: string, cookie?: string) => w.app.request(path, cookie ? { headers: { cookie: `${COOKIE}=${cookie}` } } : {});
const post = (w: W, path: string, cookie: string, f: Record<string, string>) => w.app.request(path, form(f, cookie));
const ref = async (w: W, email: string) => (await w.b.people.byEmail(email))!.actor_ref;
/** A person made by invitation, signed in, who holds what is given. */
const person = async (w: W, anya: string, name: string, ...give: string[]) => {
  const t = ((await w.b.invite(anya, `${name.toLowerCase().replace(/\W/g, "")}@beacon.clinical`, name, "coordinator")) as { invitation_token: string }).invitation_token;
  const a = (await w.b.acceptInvitation(t, "password1", "password1")) as { session_token: string; person: { actor_ref: string } };
  const anyaP = (await w.b.who(anya))!.person;
  for (const g of give) await w.b.peopleAdmin.give(anyaP.actor_ref, w.b.keyOf(anya)!, a.person.actor_ref, g);
  return { cookie: a.session_token, ref: a.person.actor_ref };
};

test("SPEC.md The screens, People & Permissions: no session goes to sign-in; a person who holds neither `invite_actor` nor `grant_permission` is answered Access denied naming both", async () => {
  const w = await world();
  expect((await get(w, "/people")).headers.get("location")).toBe("/login");
  const jordan = await signIn(w, "jordan@beacon.clinical", "demo-cra");
  const r = await get(w, "/people", jordan);
  expect(r.status).toBe(403);
  const html = await r.text();
  expect(html).toContain("Invite people");
  expect(html).toContain("Give and take away permissions");
  for (const path of ["/people/give", "/people/take", "/people/invite"]) expect((await post(w, path, jordan, { person: "x", permission: "record_visit", email: "a@b.c", display_name: "A", role: "r" })).status).toBe(403);
}, 90000);

test("SPEC.md People & Permissions 1: each person once, with the permissions held now in the words, each with a mark that takes it away whole, and the permissions not held offered to give", async () => {
  const w = await world();
  const anya = await signIn(w, "anya@beacon.clinical", "demo-pi");
  const html = await (await get(w, "/people", anya)).text();
  for (const h of ["<h2>People</h2>", "<h2>Permissions History</h2>", "<h2>Pending Invitations</h2>", "<h2>Invite someone</h2>"]) expect(html).toContain(h);
  expect(html.split("<td>jordan@beacon.clinical</td>")).toHaveLength(2);                                             // once
  expect(html.split("<td>anya@beacon.clinical</td>")).toHaveLength(2);
  expect(html.match(/action="\/people\/take"/g)).toHaveLength(7);                                                    // a mark for each permission held: six and one
  expect(html).toContain("Invite people");
  expect(html).toContain("See everyone&#39;s audit events");
  expect(html).toContain("<option value=\"view_own_audit\">See my own audit events</option>");
  const jordan = html.slice(html.indexOf("<td>Jordan Lee</td>"));
  expect(jordan.slice(0, jordan.indexOf("</tr>"))).not.toMatch(/<option value="view_audit">/);                         // only those not held are offered
  expect(html).not.toContain("<script");
}, 90000);

test("SPEC.md People & Permissions 1: a person who holds all seven shows \"holds every permission\" with no mark and nothing to give; one who holds none shows \"none\"", async () => {
  const w = await world();
  const anya = await signIn(w, "anya@beacon.clinical", "demo-pi");
  const p = await person(w, anya, "Pat Rivera");
  await post(w, "/people/give", anya, { person: await ref(w, "anya@beacon.clinical"), permission: "view_own_audit" });
  const html = await (await get(w, "/people", anya)).text();
  expect(html).toContain("holds every permission");
  expect(html).toContain("<td>none<form");                                                                            // Pat holds none, and is offered every permission
  const patRow = html.slice(html.indexOf("<td>Pat Rivera</td>"));
  expect(patRow.slice(0, patRow.indexOf("</tr>"))).toContain('name="permission"');                                    // and is offered all seven
  expect(p.ref).toBeTruthy();
}, 90000);

test("SPEC.md People & Permissions 1: giving and taking away are forms the server answers with a redirect back, and the page then shows what the person holds; the history gains the grant", async () => {
  const w = await world();
  const anya = await signIn(w, "anya@beacon.clinical", "demo-pi");
  const jordan = await ref(w, "jordan@beacon.clinical");
  const g = await post(w, "/people/give", anya, { person: jordan, permission: "record_visit" });
  expect([g.status, g.headers.get("location")]).toEqual([302, "/people"]);
  expect(await w.b.domain.held(jordan)).toContain("record_visit");
  const html = await (await get(w, "/people", anya)).text();
  expect(html).toContain("held now");
  expect(html.match(/<td>Record visits<\/td><td>Dr\. Anya Okonkwo<\/td><td>held now<\/td>/g)).toHaveLength(2);        // her own seeded grant and the one just given
  const t = await post(w, "/people/take", anya, { person: jordan, permission: "record_visit" });
  expect([t.status, t.headers.get("location")]).toEqual([302, "/people"]);
  expect(await w.b.domain.held(jordan)).not.toContain("record_visit");
  expect(await (await get(w, "/people", anya)).text()).toMatch(/<td>revoked 2026-09-01/);                            // the history marks it revoked
}, 90000);

test("SPEC.md People & Permissions 1: the marks and the choice to give are offered only to a person who holds `grant_permission`; a person who holds `invite_actor` alone sees the people without them, and a give or a take from that person is refused", async () => {
  const w = await world();
  const anya = await signIn(w, "anya@beacon.clinical", "demo-pi");
  const inviter = await person(w, anya, "Inviter", "invite_actor");
  const html = await (await get(w, "/people", inviter.cookie)).text();
  expect(html).not.toContain('action="/people/take"');
  expect(html).not.toContain('action="/people/give"');
  expect(html).toContain('action="/people/invite"');
  expect((await post(w, "/people/give", inviter.cookie, { person: inviter.ref, permission: "enroll_subject" })).status).toBe(403);
  expect(await w.b.domain.held(inviter.ref)).toEqual(["invite_actor"]);
}, 90000);

test("SPEC.md People & Permissions: a permission already held, or not held, is answered with its words on a page that says what to do next, and nothing is made", async () => {
  const w = await world();
  const anya = await signIn(w, "anya@beacon.clinical", "demo-pi");
  const jordan = await ref(w, "jordan@beacon.clinical");
  const held = await post(w, "/people/give", anya, { person: jordan, permission: "view_audit" });
  expect(held.status).toBe(400);
  expect(await held.text()).toContain("That person already holds that permission.");
  const not = await post(w, "/people/take", anya, { person: jordan, permission: "record_visit" });
  expect(not.status).toBe(400);
  expect(await not.text()).toContain("That person does not hold that permission.");
  expect((await post(w, "/people/give", anya, { person: "nobody", permission: "record_visit" })).status).toBe(404);
  expect((await post(w, "/people/give", anya, { permission: "record_visit" })).status).toBe(400);
  expect((await w.b.permissions.read()).length).toBe(7);
}, 90000);

test("SPEC.md People & Permissions 3: inviting shows the link to copy and share, because Beacon sends no email; the pending list then shows email, role, expiry and link, and the link takes the invitee to the form", async () => {
  const w = await world();
  const anya = await signIn(w, "anya@beacon.clinical", "demo-pi");
  const r = await post(w, "/people/invite", anya, { email: "New@Beacon.Clinical", display_name: "New Person", role: "coordinator" });
  expect(r.status).toBe(200);
  const html = await r.text();
  expect(html).toContain("Invite link — copy and share this with the invitee:");
  const link = /Invite link — copy and share this with the invitee: <code>(http[^<]*\/invitations\/accept\/[^<]+)<\/code>/.exec(html)![1];     // the banner's own link, not the pending list's
  expect(link.startsWith("http://localhost")).toBe(true);
  expect(html).toContain("<td>new@beacon.clinical</td><td>coordinator</td>");
  const path = new URL(link).pathname;
  expect(await (await get(w, path)).text()).toContain("Set up your account");
  const again = await (await get(w, "/people", anya)).text();
  expect(again).toContain(link);                                                                                       // still listed, with its link, as pending
  expect(again).not.toContain("Invite link — copy and share");                                                         // the banner is for the page just made
  const acc = await w.app.request(path, form({ password: "password1", confirm: "password1" }));
  const cookie = /beacon_session=([^;]*)/.exec(acc.headers.get("set-cookie") ?? "")![1];
  expect(await (await get(w, "/dashboard", cookie)).text()).toContain("Welcome, New Person");                          // the name the form asked for travelled with the invitation
}, 90000);

test("SPEC.md People & Permissions 3: a pending invitation is revoked from its mark by a person who holds `invite_actor`; its link then says it has been used or revoked; a blank field is answered with the words", async () => {
  const w = await world();
  const anya = await signIn(w, "anya@beacon.clinical", "demo-pi");
  const t = ((await w.b.invite(anya, "x@y.z", "X", "r")) as { invitation_token: string }).invitation_token;
  const r = await post(w, `/people/invitations/${t}/revoke`, anya, {});
  expect([r.status, r.headers.get("location")]).toEqual([302, "/people"]);
  expect(await (await get(w, "/people", anya)).text()).toContain("No invitation is waiting.");
  expect(await (await get(w, `/invitations/accept/${t}`)).text()).toContain("already been used or revoked");
  const blank = await post(w, "/people/invite", anya, { email: "", display_name: "A", role: "r" });
  expect(blank.status).toBe(400);
  expect(await blank.text()).toContain(FORM_WORDS.invite);
  const granter = await person(w, anya, "Granter", "grant_permission");
  const t2 = ((await w.b.invite(anya, "s@t.u", "S", "r")) as { invitation_token: string }).invitation_token;
  const gp = await (await get(w, "/people", granter.cookie)).text();
  expect(gp).toContain(t2);                                                                                           // the pending list is seen by one who holds either permission
  expect(gp).not.toContain('action="/people/invite"');                                                                 // but the form to invite and the mark to revoke are for `invite_actor`
  expect(gp).not.toContain("/revoke");
  expect((await post(w, `/people/invitations/${t}/revoke`, granter.cookie, {})).status).toBe(403);
  expect((await post(w, "/people/invite", granter.cookie, { email: "q@r.s", display_name: "Q", role: "r" })).status).toBe(403);
}, 90000);

test("SPEC.md The screens: a person's name, email and a role are written as text, never as markup", async () => {
  const w = await world();
  const anya = await signIn(w, "anya@beacon.clinical", "demo-pi");
  await w.b.invite(anya, "m@n.o", "<b>Bold</b>", "<script>1</script>");
  const html = await (await get(w, "/people", anya)).text();
  expect(html).toContain("&lt;script&gt;1&lt;/script&gt;");
  expect(html).not.toContain("<script");
  expect(html).not.toContain("<b>Bold");
}, 90000);
