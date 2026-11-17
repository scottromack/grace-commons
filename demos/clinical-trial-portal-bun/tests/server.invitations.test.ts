// Beacon's page for accepting an invitation, one test for each thing SPEC.md says of it (The screens, Accept an invitation).
import { test, expect, afterAll } from "bun:test";
import { Store } from "../src/store.ts";
import { testSeam } from "../src/seam.ts";
import { Beacon, INVITATION_WORDS, FORM_WORDS } from "../src/beacon.ts";
import { buildApp, COOKIE } from "../src/server.ts";

const store = new Store();
afterAll(() => store.close());
const world = async () => {
  const seam = testSeam("2026-09-01T10:00:00.000Z");
  const prefix = `si_${crypto.randomUUID().replaceAll("-", "_")}_`;
  const b = await Beacon.open(store, { seam, prefix, argon: { memoryCost: 1024, timeCost: 1 }, scrypt: { N: 1024, r: 8, p: 1 } });
  await b.seed();
  const anya = ((await b.signIn("anya@beacon.clinical", "demo-pi")) as { session_token: string }).session_token;
  return { b, seam, anya, app: buildApp(b) };
};
type W = Awaited<ReturnType<typeof world>>;
const form = (f: Record<string, string>) => ({ method: "POST", headers: { "content-type": "application/x-www-form-urlencoded" }, body: new URLSearchParams(f).toString() });
const link = (t: string) => `/invitations/accept/${encodeURIComponent(t)}`;
const invite = async (w: W, email = "pat@beacon.clinical") => ((await w.b.invite(w.anya, email, "Pat Rivera", "coordinator")) as { invitation_token: string }).invitation_token;

test("SPEC.md Accept an invitation: a person with no session may open the link; the page is a \"Set up your account\" form with the invited email and the intended role, a password and its confirmation, and no script", async () => {
  const w = await world();
  const t = await invite(w);
  const r = await w.app.request(link(t));
  expect(r.status).toBe(200);
  const html = await r.text();
  expect(html).toContain("Set up your account");
  expect(html).toContain('value="pat@beacon.clinical"');
  expect(html).toContain('value="coordinator"');
  expect(html).toContain('name="password"');
  expect(html).toContain('name="confirm"');
  expect(html).toMatch(/id="email"[^>]* readonly/);                                                                     // the invited email is shown, not typed
  expect(html).toMatch(/id="role"[^>]* readonly/);
  expect(html.match(/type="password"/g)).toHaveLength(2);                                                               // both passwords are hidden as typed
  expect(html).toContain(`action="${link(t)}"`);
  expect(html).not.toContain("<script");
});

test("SPEC.md Accept an invitation: a link that is unknown says \"This invitation link is invalid.\"; one used or revoked says \"This invitation has already been used or revoked.\"; one past its date says \"This invitation has expired. Please ask for a new one.\"; none shows the form", async () => {
  const w = await world();
  const used = await invite(w, "a@b.c"), revoked = await invite(w, "d@e.f"), old = await invite(w, "g@h.i");
  await w.b.acceptInvitation(used, "password1", "password1");
  await w.b.revokeInvitation(w.anya, revoked);
  w.seam.advance(8 * 86_400_000);
  const html = async (t: string) => { const r = await w.app.request(link(t)); return [r.status, await r.text()] as const; };
  for (const [t, why] of [["nope", "unknown"], [used, "resolved"], [revoked, "resolved"], [old, "expired"]] as const) {
    const [status, body] = await html(t);
    expect(status).toBe(why === "unknown" ? 404 : 410);
    expect(body).toContain(INVITATION_WORDS[why]);
    expect(body).not.toContain('name="password"');
  }
});

test("SPEC.md Accept an invitation: accepting creates the account and signs the person in: the cookie is the session, the person goes to the dashboard and may sign in again with the password", async () => {
  const w = await world();
  const t = await invite(w);
  const r = await w.app.request(link(t), form({ password: "correct horse", confirm: "correct horse" }));
  expect([r.status, r.headers.get("location")]).toEqual([302, "/dashboard"]);
  const cookie = /beacon_session=([^;]*)/.exec(r.headers.get("set-cookie") ?? "")?.[1] ?? "";
  expect(cookie).not.toBe("");
  expect(r.headers.get("set-cookie")).toContain("HttpOnly");
  const dash = await (await w.app.request("/dashboard", { headers: { cookie: `${COOKIE}=${cookie}` } })).text();
  expect(dash).toContain("Welcome, Pat Rivera");
  expect(dash).toContain("You do not hold a permission that opens a page yet.");
  const again = await w.app.request("/login", form({ email: "Pat@Beacon.Clinical", password: "correct horse" }));
  expect(again.status).toBe(302);
});

test("SPEC.md Accept an invitation: a password under 8 characters or a confirmation that differs is answered on the same form, with the words, no cookie and the link unspent", async () => {
  const w = await world();
  const t = await invite(w);
  for (const [f, say] of [[{ password: "short", confirm: "short" }, FORM_WORDS.password], [{ password: "eightchr", confirm: "eightchx" }, FORM_WORDS.confirm], [{}, FORM_WORDS.password]] as const) {
    const r = await w.app.request(link(t), form(f));
    expect(r.status).toBe(400);
    expect(r.headers.get("set-cookie")).toBeNull();
    const html = await r.text();
    expect(html).toContain(say);
    expect(html).toContain('value="pat@beacon.clinical"');                                                              // the form again, not a dead end
  }
  expect((await w.b.invitations.read({ invitation_token: t }))[0].status).toBe("pending");
});

test("SPEC.md Accept an invitation: a second use of a link says it has been used, and sets no cookie", async () => {
  const w = await world();
  const t = await invite(w);
  await w.app.request(link(t), form({ password: "password1", confirm: "password1" }));
  const r = await w.app.request(link(t), form({ password: "password2", confirm: "password2" }));
  expect(r.status).toBe(410);
  expect(await r.text()).toContain(INVITATION_WORDS.resolved);
  expect(r.headers.get("set-cookie")).toBeNull();
});

test("SPEC.md The screens: an invitation's role and name are written as text, never as markup", async () => {
  const w = await world();
  const r = await w.b.invite(w.anya, "x@y.z", "<b>X</b>", "<script>1</script>");
  const html = await (await w.app.request(link((r as { invitation_token: string }).invitation_token))).text();
  expect(html).toContain("&lt;script&gt;1&lt;/script&gt;");
  expect(html).not.toContain("<script");
});
