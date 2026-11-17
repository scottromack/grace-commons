// Beacon's pages, one test for each thing SPEC.md says of the front page, sign in and out, the dashboard and the access-denied page.
import { test, expect, afterAll } from "bun:test";
import { Store } from "../src/store.ts";
import { testSeam } from "../src/seam.ts";
import { Beacon } from "../src/beacon.ts";
import { Hono } from "hono";
import { generateKeyPairSync } from "node:crypto";
import { buildApp, COOKIE, esc, deniedPage, tilesFor, loginPage, denied } from "../src/server.ts";

const store = new Store();
afterAll(() => store.close());
const world = async () => {
  const seam = testSeam("2026-09-01T10:00:00.000Z");
  const prefix = `sv_${crypto.randomUUID().replaceAll("-", "_")}_`;
  const b = await Beacon.open(store, { seam, prefix, argon: { memoryCost: 1024, timeCost: 1 }, scrypt: { N: 1024, r: 8, p: 1 } });
  await b.seed();
  return { b, seam, app: buildApp(b) };
};
type W = Awaited<ReturnType<typeof world>>;
const form = (f: Record<string, string>) => ({ method: "POST", headers: { "content-type": "application/x-www-form-urlencoded" }, body: new URLSearchParams(f).toString() });
const cookieOf = (r: Response): string => /beacon_session=([^;]*)/.exec(r.headers.get("set-cookie") ?? "")?.[1] ?? "";
const signIn = async (w: W, email: string, password: string) => {
  const r = await w.app.request("/login", form({ email, password }));
  expect(r.status).toBe(302);
  return cookieOf(r);
};
const get = (w: W, path: string, cookie?: string) => w.app.request(path, cookie ? { headers: { cookie: `${COOKIE}=${cookie}` } } : {});

test("SPEC.md The screens, Front page: / sends the person to sign-in", async () => {
  const w = await world();
  const r = await get(w, "/");
  expect([r.status, r.headers.get("location")]).toEqual([302, "/login"]);
});

test("SPEC.md The screens, Sign in: the page asks for an email and a password and shows the two demonstration accounts with their passwords", async () => {
  const w = await world();
  const r = await get(w, "/login");
  expect(r.status).toBe(200);
  const html = await r.text();
  expect(html).toContain('name="email"');
  expect(html).toContain('name="password"');
  expect(html).toContain("anya@beacon.clinical");
  expect(html).toContain("demo-pi");
  expect(html).toContain("jordan@beacon.clinical");
  expect(html).toContain("demo-cra");
  expect(html).not.toContain("<script");                                                                              // every action works with no script running (SPEC.md, The screens)
});

test("SPEC.md Sign in: an empty field answers \"Email and password are required.\"; a wrong password and an unknown email both answer \"Invalid email or password.\" and say nothing of which was wrong; no cookie is set", async () => {
  const w = await world();
  for (const f of [{ email: "", password: "x" }, { email: "anya@beacon.clinical", password: "" }, {}]) {
    const r = await w.app.request("/login", form(f));
    expect(r.status).toBe(400);
    expect(await r.text()).toContain("Email and password are required.");
    expect(r.headers.get("set-cookie")).toBeNull();
  }
  const wrong = await w.app.request("/login", form({ email: "anya@beacon.clinical", password: "nope" }));
  const unknown = await w.app.request("/login", form({ email: "ghost@beacon.clinical", password: "nope" }));
  expect([wrong.status, unknown.status]).toEqual([401, 401]);
  const [a, b] = [await wrong.text(), await unknown.text()];
  expect(a).toContain("Invalid email or password.");
  expect(a).toBe(b);                                                                                                  // the same page, byte for byte
  expect(wrong.headers.get("set-cookie")).toBeNull();
  expect(a).not.toMatch(/unknown|no such|wrong password|not found/i);
});

test("SPEC.md Sign in, People & Permissions (the session cookie): a correct sign-in sets a cookie scripts cannot read holding the session token, for seven days, and goes to the dashboard", async () => {
  const w = await world();
  const r = await w.app.request("/login", form({ email: "Anya@Beacon.Clinical", password: "demo-pi" }));
  expect([r.status, r.headers.get("location")]).toEqual([302, "/dashboard"]);
  const sc = r.headers.get("set-cookie")!;
  expect(sc).toContain("HttpOnly");
  expect(sc).toMatch(/SameSite=Lax/i);
  expect(sc).toMatch(/Path=\/(;|$)/);
  expect(sc).toContain(`Max-Age=${7 * 86_400}`);
  const token = cookieOf(r);
  expect(token.length).toBeGreaterThan(20);
  expect((await w.b.who(token))!.person.email).toBe("anya@beacon.clinical");                                          // the session record, not the cookie, makes the person signed in
});

test("SPEC.md Sign in: a person already signed in is sent to the dashboard from /login", async () => {
  const w = await world();
  const c = await signIn(w, "jordan@beacon.clinical", "demo-cra");
  const r = await get(w, "/login", c);
  expect([r.status, r.headers.get("location")]).toEqual([302, "/dashboard"]);
});

test("SPEC.md The screens: a person without a session who asks for a page that needs one is sent to sign-in; so is a cookie the session record does not stand behind", async () => {
  const w = await world();
  expect((await get(w, "/dashboard")).headers.get("location")).toBe("/login");
  const stale = await get(w, "/dashboard", "not-a-session");
  expect([stale.status, stale.headers.get("location")]).toEqual([302, "/login"]);
  expect(stale.headers.get("set-cookie")).toContain(`${COOKIE}=;`);                                                    // the dead cookie is cleared
});

test("SPEC.md Dashboard: \"Welcome, <name>\" and a tile for each of People & Permissions, Subjects and Audit Trail the person may open", async () => {
  const w = await world();
  const anya = await (await get(w, "/dashboard", await signIn(w, "anya@beacon.clinical", "demo-pi"))).text();
  expect(anya).toContain("Welcome, Dr. Anya Okonkwo");
  for (const t of ["People &amp; Permissions", "Subjects", "Audit Trail"]) expect(anya).toContain(t);
  const jordan = await (await get(w, "/dashboard", await signIn(w, "jordan@beacon.clinical", "demo-cra"))).text();
  expect(jordan).toContain("Welcome, Jordan Lee");
  expect(jordan).toContain("Audit Trail");
  expect(jordan).not.toContain("Subjects");
  expect(jordan).not.toContain("People &amp; Permissions");
  expect(tilesFor(["view_own_audit"]).map((t) => t.label)).toEqual(["Audit Trail"]);
  expect(tilesFor(["grant_permission"]).map((t) => t.label)).toEqual(["People & Permissions"]);
  expect(tilesFor(["record_visit"]).map((t) => t.label)).toEqual(["Subjects"]);
  expect(tilesFor(["view_all_subjects"])).toEqual([]);
});

test("SPEC.md Sign out: ends the session, clears the cookie, returns to the front page, for anyone", async () => {
  const w = await world();
  const c = await signIn(w, "anya@beacon.clinical", "demo-pi");
  const r = await get(w, "/logout", c);
  expect([r.status, r.headers.get("location")]).toEqual([302, "/"]);
  expect(r.headers.get("set-cookie")).toContain(`${COOKIE}=;`);
  expect(await w.b.who(c)).toBeNull();
  expect((await get(w, "/dashboard", c)).headers.get("location")).toBe("/login");                                      // the revoked session stands behind nothing
  const anyone = await get(w, "/logout");
  expect([anyone.status, anyone.headers.get("location")]).toEqual([302, "/"]);                                         // no session: still returns to the front page
  const c2 = await signIn(w, "anya@beacon.clinical", "demo-pi");
  const post = await w.app.request("/logout", { method: "POST", headers: { cookie: `${COOKIE}=${c2}` } });
  expect(post.status).toBe(302);
  expect(await w.b.who(c2)).toBeNull();
});

test("SPEC.md People & Permissions (a session lasts seven days): a cookie past the session's seven days is sent to sign-in", async () => {
  const w = await world();
  const c = await signIn(w, "anya@beacon.clinical", "demo-pi");
  w.seam.advance(6 * 86_400_000);
  expect((await get(w, "/dashboard", c)).status).toBe(200);
  w.seam.advance(2 * 86_400_000);
  expect((await get(w, "/dashboard", c)).headers.get("location")).toBe("/login");
});

test("SPEC.md The screens, Access denied: the page names the permission or permissions that would open the page, and a way back to the dashboard", async () => {
  const one = deniedPage(["enroll_subject"]);
  expect(one).toContain("Access denied");
  expect(one).toContain("Enroll subjects");
  expect(one).toContain('href="/dashboard"');
  const two = deniedPage(["enroll_subject", "record_visit"]);
  expect(two).toContain("Enroll subjects");
  expect(two).toContain("Record visits");
  expect(two).toContain("one of these permissions");
  expect(one).not.toContain("one of these");
});

test("SPEC.md The screens: a gated page answers a person who lacks the permission with the Access denied page and status 403", async () => {
  const t = new Hono();
  t.get("/gated", (c) => denied(c, ["view_audit", "view_own_audit"]));
  const r = await t.request("/gated");
  expect(r.status).toBe(403);
  expect(await r.text()).toContain("Access denied");
});

test("People & Permissions (the cookie): the cookie is Secure only where the deployment says it is served over https", async () => {
  const w = await world();
  const plain = await w.app.request("/login", form({ email: "anya@beacon.clinical", password: "demo-pi" }));
  expect(plain.headers.get("set-cookie")).not.toContain("Secure");
  const tls = await buildApp(w.b, { secureCookie: true }).request("/login", form({ email: "jordan@beacon.clinical", password: "demo-cra" }));
  expect(tls.headers.get("set-cookie")).toContain("Secure");
});

test("Output escaping: a name or a message that holds markup is written as text, never as markup", async () => {
  expect(esc(`<img src=x onerror="a">&'`)).toBe("&lt;img src=x onerror=&quot;a&quot;&gt;&amp;&#39;");
  expect(loginPage("<script>alert(1)</script>")).not.toContain("<script>alert");
  const w = await world();
  const e = await w.b.parties.enroll("<b>Eve</b>", "1900-01-01", "beacon-account", "eve@x.y", "seed") as { party_id: string };
  await w.b.credentials.register(e.party_id, "eve-password", "password");
  await w.b.people.create({ party_id: e.party_id, email: "eve@x.y", display_name: "<b>Eve</b>", password: "eve-password" });
  const html = await (await get(w, "/dashboard", await signIn(w, "eve@x.y", "eve-password"))).text();
  expect(html).toContain("Welcome, &lt;b&gt;Eve&lt;/b&gt;");
  expect(html).not.toContain("<b>Eve</b>");
  expect(html).toContain("You do not hold a permission that opens a page yet.");
});

// ---- Subjects (SPEC.md, The study, subjects and visits; The screens: Subjects, Enroll Subject, A subject) ----------------------------

const post = (w: W, path: string, cookie: string, f: Record<string, string>) => w.app.request(path, { ...form(f), headers: { "content-type": "application/x-www-form-urlencoded", cookie: `${COOKIE}=${cookie}` } });
const enroll = async (w: W, cookie: string, notes = ""): Promise<string> => {
  const r = await post(w, "/subjects/new", cookie, { notes });
  expect(r.status).toBe(302);
  return /^\/subjects\/(.+)$/.exec(r.headers.get("location")!)![1];
};
/** Jordan is given enrolling and recording by Anya, through the composition and Anya's held key: he sees only the subjects he enrolled. */
const jordanGiven = async (w: W, ...codes: ("enroll_subject" | "record_visit")[]) => {
  const t = ((await w.b.signIn("anya@beacon.clinical", "demo-pi")) as { session_token: string }).session_token;
  const anya = (await w.b.who(t))!.person;
  const jordan = (await w.b.people.byEmail("jordan@beacon.clinical"))!;
  for (const code of codes) await w.b.admin.issueGrant(jordan.actor_ref, code, anya.actor_ref, w.b.keyOf(t)!);
};

test("SPEC.md Subjects: a person who may enroll and has none sees \"Enroll the first subject.\"; a person who may do neither is answered Access denied naming both permissions", async () => {
  const w = await world();
  const anya = await signIn(w, "anya@beacon.clinical", "demo-pi");
  const html = await (await get(w, "/subjects", anya)).text();
  expect(html).toContain("Enroll the first subject.");
  expect(html).toContain('href="/subjects/new"');
  const jordan = await signIn(w, "jordan@beacon.clinical", "demo-cra");
  const d = await get(w, "/subjects", jordan);
  expect(d.status).toBe(403);
  const dh = await d.text();
  expect(dh).toContain("Access denied");
  expect(dh).toContain("Enroll subjects");
  expect(dh).toContain("Record visits");
  expect((await get(w, "/subjects")).headers.get("location")).toBe("/login");
});

test("SPEC.md Enroll Subject: the next code is shown and not editable; enrolling makes the subject, starts it at screening, and goes to its page; the next is one more", async () => {
  const w = await world();
  const anya = await signIn(w, "anya@beacon.clinical", "demo-pi");
  const f = await (await get(w, "/subjects/new", anya)).text();
  expect(f).toContain("BCN-001");
  expect(f).toMatch(/<input[^>]*value="BCN-001"[^>]*readonly/);
  expect(f).toContain('name="notes"');
  expect(f).not.toMatch(/name="code"/);
  expect(f).toContain('action="/subjects/new"');
  const id = await enroll(w, anya, "first <b>one</b>");
  const page = await (await get(w, `/subjects/${id}`, anya)).text();
  expect(page).toContain("BCN-001");
  expect(page).toContain("Status: screening");
  expect(page).toContain("Enrolled by Dr. Anya Okonkwo on 2026-09-01 10:00 UTC");                                        // the person, by name and not by reference
  expect(page).toContain("first &lt;b&gt;one&lt;/b&gt;");                                                              // notes are text, never markup
  expect(page).not.toContain("<b>one</b>");
  expect(await (await get(w, "/subjects/new", anya)).text()).toContain("BCN-002");
  await enroll(w, anya);
  const list = await (await get(w, "/subjects", anya)).text();
  expect(list.indexOf("BCN-001")).toBeLessThan(list.indexOf("BCN-002"));
  expect(list).toContain(`href="/subjects/${id}"`);
  expect(list).not.toContain("Enroll the first subject.");
  expect(list).toContain("2026-09-01 10:00 UTC");
});

test("SPEC.md Enroll Subject: a person who does not hold enroll_subject is answered Access denied and nothing is made", async () => {
  const w = await world();
  await jordanGiven(w, "record_visit");                                                                              // Jordan may record, not enroll
  const jordan = await signIn(w, "jordan@beacon.clinical", "demo-cra");
  const g = await get(w, "/subjects/new", jordan);
  expect(g.status).toBe(403);
  expect(await g.text()).toContain("Enroll subjects");
  const none = await (await get(w, "/subjects", jordan)).text();
  expect(none).not.toContain('href="/subjects/new"');                                                                 // enrolling is not offered to one who may only record
  const p = await post(w, "/subjects/new", jordan, { notes: "x" });
  expect(p.status).toBe(403);
  const anya = await signIn(w, "anya@beacon.clinical", "demo-pi");
  expect(await (await get(w, "/subjects", anya)).text()).toContain("Enroll the first subject.");
});

test("SPEC.md A subject: no visits says \"No visits recorded yet.\"; a recorded visit is listed, oldest first, with who and when it was recorded", async () => {
  const w = await world();
  const anya = await signIn(w, "anya@beacon.clinical", "demo-pi");
  const id = await enroll(w, anya);
  expect(await (await get(w, `/subjects/${id}`, anya)).text()).toContain("No visits recorded yet.");
  const r = await post(w, `/subjects/${id}/visits`, anya, { kind: "week 4", notes: "ok" });
  expect([r.status, r.headers.get("location")]).toEqual([302, `/subjects/${id}`]);
  w.seam.advance(60_000);
  await post(w, `/subjects/${id}/visits`, anya, { kind: "screening" });
  const html = await (await get(w, `/subjects/${id}`, anya)).text();
  expect(html).not.toContain("No visits recorded yet.");
  expect(html.indexOf("week 4")).toBeLessThan(html.indexOf("screening</td>"));                                         // oldest first, whatever the kind
  expect(html).toContain("2026-09-01 10:00 UTC");
  expect(html).toContain("2026-09-01 10:01 UTC");
  expect(html).toContain("ok");
});

test("SPEC.md A subject, Record Visit: the form offers the five kinds; a visit with no kind, or a kind that is not one of them, answers \"Visit type is required.\" and records nothing", async () => {
  const w = await world();
  const anya = await signIn(w, "anya@beacon.clinical", "demo-pi");
  const id = await enroll(w, anya);
  const html = await (await get(w, `/subjects/${id}`, anya)).text();
  for (const k of ["screening", "week 4", "week 12", "week 24", "end of study"]) expect(html).toContain(`value="${k}"`);
  expect(html).toContain(`action="/subjects/${id}/visits"`);
  for (const bad of [{ kind: "" }, {}, { kind: "week 99" }]) {
    const r = await post(w, `/subjects/${id}/visits`, anya, bad);
    expect(r.status).toBe(400);
    expect(await r.text()).toContain("Visit type is required.");
  }
  expect(await (await get(w, `/subjects/${id}`, anya)).text()).toContain("No visits recorded yet.");
});

test("SPEC.md Who sees which subject: a person without view_all_subjects sees the subjects that person enrolled, and another's answers Not Found. as if it did not exist; a person with it sees every one", async () => {
  const w = await world();
  await jordanGiven(w, "enroll_subject", "record_visit");
  const anya = await signIn(w, "anya@beacon.clinical", "demo-pi");
  const jordan = await signIn(w, "jordan@beacon.clinical", "demo-cra");
  const anyas = await enroll(w, anya);
  const jordans = await enroll(w, jordan);
  const jl = await (await get(w, "/subjects", jordan)).text();
  expect(jl).toContain(`href="/subjects/${jordans}"`);
  expect(jl).not.toContain(`href="/subjects/${anyas}"`);
  const nf = await get(w, `/subjects/${anyas}`, jordan);
  expect(nf.status).toBe(404);
  expect(await nf.text()).toContain("Not Found.");
  const unknown = await get(w, "/subjects/subject-nope", jordan);
  expect(unknown.status).toBe(404);                                                                                  // no different from a subject that does not exist
  const rv = await post(w, `/subjects/${anyas}/visits`, jordan, { kind: "screening" });
  expect(rv.status).toBe(404);
  const al = await (await get(w, "/subjects", anya)).text();
  expect(al).toContain(`href="/subjects/${anyas}"`);
  expect(al).toContain(`href="/subjects/${jordans}"`);
});

test("SPEC.md Who records a visit: a person who holds record_visit; the form is not offered to one who does not, and a post is answered Access denied", async () => {
  const w = await world();
  await jordanGiven(w, "enroll_subject");                                                                            // Jordan may enroll, not record
  const jordan = await signIn(w, "jordan@beacon.clinical", "demo-cra");
  const id = await enroll(w, jordan);
  const html = await (await get(w, `/subjects/${id}`, jordan)).text();
  expect(html).not.toContain("Record a visit");
  expect(html).not.toContain('name="kind"');
  const r = await post(w, `/subjects/${id}/visits`, jordan, { kind: "screening" });
  expect(r.status).toBe(403);
  expect(await r.text()).toContain("Record visits");
  const anya = await signIn(w, "anya@beacon.clinical", "demo-pi");
  expect(await (await get(w, `/subjects/${id}`, anya)).text()).toContain("Record a visit");
});

test("SPEC.md People (a server restart signs everyone out): a session whose key is gone is sent to sign-in and ended; the subject pages need a session", async () => {
  const w = await world();
  const anya = await signIn(w, "anya@beacon.clinical", "demo-pi");
  w.b.keys.drop(anya);                                                                                               // what a restart does: the key lived only in the running server
  const r = await get(w, "/subjects", anya);
  expect([r.status, r.headers.get("location")]).toEqual([302, "/login"]);
  expect(r.headers.get("set-cookie")).toContain(`${COOKIE}=;`);
  expect(await w.b.who(anya)).toBeNull();                                                                           // the session itself is ended
  for (const path of ["/subjects", "/subjects/new", "/subjects/x"]) expect((await get(w, path)).headers.get("location")).toBe("/login");
  expect((await post(w, "/subjects/new", "nope", {})).headers.get("location")).toBe("/login");
});

test("SPEC.md Subjects: a subject's code and notes are written as text, never as markup", async () => {
  const w = await world();
  const anya = await signIn(w, "anya@beacon.clinical", "demo-pi");
  await enroll(w, anya, "<script>alert(1)</script>");
  const html = await (await get(w, "/subjects", anya)).text();
  expect(html).toContain("&lt;script&gt;alert(1)&lt;/script&gt;");
  expect(html).not.toContain("<script");
});

test("SPEC.md Subjects (a refused call): a person whose key the system will not attest is told that the sign-in has ended and what to do; nothing is made, no event is written", async () => {
  const w = await world();
  const anya = await signIn(w, "anya@beacon.clinical", "demo-pi");
  const id = await enroll(w, anya);
  const other = generateKeyPairSync("ed25519").privateKey.export({ format: "der", type: "pkcs8" }).toString("base64");
  w.b.keys.hold(anya, other, Date.parse("2026-09-02T10:00:00.000Z"));                                                // a key the registry does not stand behind
  const r = await post(w, "/subjects/new", anya, { notes: "x" });
  expect(r.status).toBe(401);
  const html = await r.text();
  expect(html).toContain("Your sign-in has ended. Please sign in again.");
  expect(html).toContain(">Sign in again</a>");                                                                         // the way on, beside the header's own sign-out link
  const v = await post(w, `/subjects/${id}/visits`, anya, { kind: "screening" });
  expect(v.status).toBe(401);
  expect((await w.b.domain.subjects((await w.b.who(anya))!.person.actor_ref) as { code: string }[]).map((s) => s.code)).toEqual(["BCN-001"]);   // no second subject
});
