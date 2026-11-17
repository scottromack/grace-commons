// Beacon's pages: the front page, sign in and sign out, the dashboard, the "Access denied" page, and the subjects (the list, Enroll Subject, a subject and Record Visit).
// Built from SPEC.md (The screens; People & Permissions' words; The permissions) with Hono, the stack STACK.md pins. Every screen is a page the server
// draws and every action works with no script running in the browser (SPEC.md, The screens): forms post, the server answers with a page or a redirect.
//
// A session is a random opaque value kept in a cookie the browser's scripts cannot read (HttpOnly), and the session record, not the cookie, is what
// makes a person signed in (SPEC.md): the cookie holds the session token and nothing else, and every request asks Session whether it is still valid.
import { Hono, type Context } from "hono";
import { getCookie, setCookie, deleteCookie } from "hono/cookie";
import { type Beacon, SEED } from "./beacon.ts";
import { PERMISSIONS, VISIT_KINDS, MESSAGES, type PermissionCode, type Refusal, type SubjectView, type VisitView } from "./beacon_domain.ts";
import { type PersonView } from "./beacon_people.ts";

export const COOKIE = "beacon_session";
export const SESSION_SECONDS = 7 * 86_400;
export const WORDS = Object.fromEntries(PERMISSIONS.map((p) => [p.code, p.words])) as Record<PermissionCode, string>;
export const MSG = {
  required: "Email and password are required.",
  invalid: "Invalid email or password.",
} as const;

/** Text into a page: every character that means something to HTML is written as itself, never as markup. */
export const esc = (s: unknown): string => String(s ?? "").replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[c]!);

const page = (title: string, body: string, who?: PersonView): string => `<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>${esc(title)} — Beacon Clinical Research</title>
<style>body{font:16px/1.5 system-ui,sans-serif;margin:0;color:#1d2433;background:#f6f7f9}header{background:#12304f;color:#fff;padding:12px 24px;display:flex;justify-content:space-between;align-items:center}header a{color:#fff}main{max-width:720px;margin:32px auto;padding:0 24px}.tile{display:inline-block;margin:0 12px 12px 0;padding:16px 20px;background:#fff;border:1px solid #cfd6e0;border-radius:8px;text-decoration:none;color:inherit}label{display:block;margin:12px 0 4px}input{padding:8px;width:100%;max-width:320px}button{margin-top:16px;padding:8px 16px}.error{color:#a12020}.demo{background:#fff;border:1px solid #cfd6e0;padding:8px 16px;margin-top:24px}table{border-collapse:collapse;width:100%;background:#fff}td,th{border:1px solid #cfd6e0;padding:6px 10px;text-align:left}textarea,select{padding:8px;width:100%;max-width:480px;font:inherit}.muted{color:#5b6577}</style></head>
<body><header><strong>Beacon Clinical Research</strong>${who ? `<span>${esc(who.display_name)} · <a href="/logout">Sign out</a></span>` : ""}</header><main>${body}</main></body></html>`;

export const loginPage = (error?: string): string => page("Sign in", `<h1>Sign in</h1>${error ? `<p class="error" role="alert">${esc(error)}</p>` : ""}
<form method="post" action="/login"><label for="email">Email</label><input id="email" name="email" type="email" autocomplete="username"><label for="password">Password</label><input id="password" name="password" type="password" autocomplete="current-password"><button type="submit">Sign in</button></form>
<div class="demo"><p>This is a demonstration. Two accounts:</p><ul>${SEED.map((s) => `<li>${esc(s.name)}: <code>${esc(s.email)}</code>, password <code>${esc(s.password)}</code></li>`).join("")}</ul></div>`);

/** The page a signed-in person who lacks a permission a page needs is answered with: it names the permission or permissions that would open it, and a way back (SPEC.md, The screens). */
export const deniedPage = (needs: PermissionCode[], who?: PersonView): string => page("Access denied", `<h1>Access denied</h1>
<p>This page needs ${needs.length > 1 ? "one of these permissions" : "this permission"}: ${needs.map((n) => `<strong>${esc(WORDS[n])}</strong>`).join(" or ")}.</p><p><a href="/dashboard">Back to the dashboard</a></p>`, who);

type Held = { person: PersonView; holds: PermissionCode[] };
type Ctx = Context<{ Variables: { me: Held; token: string } }>;

/** A time as a person reads it: the date, the minute and the zone (the instant is held in UTC). */
export const when = (iso: string): string => iso.replace("T", " ").replace(/:\d\d(\.\d+)?Z$/, " UTC");

/** What a person is told where a call is refused or fails: what happened and what to do next, and no more than the answer names (SPEC.md, execution-contract's UI rule). */
export const WORDS_OF = {
  notFound: "Not Found.",
  storage: "That did not save, and nothing was changed. Please try again.",
  unavailable: "Beacon cannot read its records just now. Please try again in a moment.",
  signedOut: "Your sign-in has ended. Please sign in again.",
} as const;
const may = (holds: PermissionCode[], ...any: PermissionCode[]) => any.some((p) => holds.includes(p));

/** The tiles of the dashboard, each for the pages the person may open (SPEC.md, The screens, Dashboard; the live render's narrower offers are the comparison's to report). */
export const tilesFor = (holds: PermissionCode[]): { href: string; label: string }[] => [
  ...(may(holds, "invite_actor", "grant_permission") ? [{ href: "/people", label: "People & Permissions" }] : []),
  ...(may(holds, "enroll_subject", "record_visit") ? [{ href: "/subjects", label: "Subjects" }] : []),
  ...(may(holds, "view_audit", "view_own_audit") ? [{ href: "/audit", label: "Audit Trail" }] : []),
];

export function buildApp(beacon: Beacon, o: { secureCookie?: boolean } = {}): Hono<{ Variables: { me: Held; token: string } }> {
  const app = new Hono<{ Variables: { me: Held; token: string } }>();

  /** A person without a session who asks for any page but sign-in, accepting an invitation and the front page is sent to sign-in (SPEC.md, The screens). */
  const signedIn = async (c: Context<{ Variables: { me: Held; token: string } }>, next: () => Promise<void>) => {
    const token = getCookie(c, COOKIE) ?? "";
    const me = await beacon.who(token);
    if (!me) { if (token) deleteCookie(c, COOKIE, { path: "/" }); return c.redirect("/login", 302); }
    if (!beacon.keyOf(token)) {                                                                                       // a server restart signs everyone out: the unsealed key lived only in the running server (SPEC.md, People)
      await beacon.signOut(token); deleteCookie(c, COOKIE, { path: "/" }); return c.redirect("/login", 302);
    }
    c.set("me", me); c.set("token", token);
    await next();
  };

  app.get("/", (c) => c.redirect("/login", 302));                                                                  // the front page sends the person to sign-in

  app.get("/login", async (c) => (await beacon.who(getCookie(c, COOKIE) ?? "")) ? c.redirect("/dashboard", 302) : c.html(loginPage()));   // a person already signed in is sent to the dashboard

  app.post("/login", async (c) => {
    const f = await c.req.parseBody();
    const email = typeof f.email === "string" ? f.email : "", password = typeof f.password === "string" ? f.password : "";
    if (email.trim() === "" || password === "") return c.html(loginPage(MSG.required), 400);                      // an empty field
    const r = await beacon.signIn(email, password);
    if ("refused" in r) return c.html(loginPage(r.refused === "invalid-credential" ? MSG.invalid : r.refused === "invalid-request" ? MSG.required : "Sign-in is unavailable. Please try again."), r.refused === "invalid-credential" ? 401 : r.refused === "invalid-request" ? 400 : 503);   // both wrong email and wrong password say nothing of which
    setCookie(c, COOKIE, r.session_token, { httpOnly: true, sameSite: "Lax", path: "/", maxAge: SESSION_SECONDS, secure: o.secureCookie ?? false });
    return c.redirect("/dashboard", 302);
  });

  /** Ends the session, clears the cookie, returns to the front page (SPEC.md, Sign out); anyone may call it. */
  const logout = async (c: Context) => {
    const token = getCookie(c, COOKIE);
    if (token) await beacon.signOut(token);
    deleteCookie(c, COOKIE, { path: "/" });
    return c.redirect("/", 302);
  };
  app.get("/logout", logout);
  app.post("/logout", logout);

  app.get("/dashboard", signedIn, (c) => {
    const { person, holds } = c.get("me");
    const tiles = tilesFor(holds);
    return c.html(page("Dashboard", `<h1>Welcome, ${esc(person.display_name)}</h1>${tiles.length ? tiles.map((t) => `<a class="tile" href="${esc(t.href)}">${esc(t.label)}</a>`).join("") : "<p>You do not hold a permission that opens a page yet.</p>"}`, person));
  });

  // ---- Subjects (SPEC.md, The study, subjects and visits; The screens) ------------------------------------------------

  /** The answer to a refused call: a page that says what happened and what the person can do next. */
  const refuse = (c: Ctx, r: Refusal, who: PersonView, back: string): Response | Promise<Response> => {
    const link = `<p><a href="${esc(back)}">Back</a></p>`;
    switch (r.refused) {
      case "access-denied": return denied(c, r.needs, who);
      case "not-found": return c.html(page("Not Found", `<h1>${esc(WORDS_OF.notFound)}</h1>${link}`, who), 404);
      case "invalid-request": return c.html(page("Not saved", `<p class="error" role="alert">${esc(r.message ?? "That was not accepted.")}</p>${link}`, who), 400);
      case "invalid-credential": return c.html(page("Sign in again", `<p class="error" role="alert">${esc(WORDS_OF.signedOut)}</p><p><a href="/logout">Sign in again</a></p>`, who), 401);
      case "state-unavailable": return c.html(page("Try again", `<p class="error" role="alert">${esc(WORDS_OF.unavailable)}</p>${link}`, who), 503);
      default: return c.html(page("Try again", `<p class="error" role="alert">${esc(WORDS_OF.storage)}</p>${link}`, who), 503);
    }
  };

  app.get("/subjects", signedIn, async (c) => {
    const { person, holds } = c.get("me");
    const r = await beacon.domain.subjects(person.actor_ref);
    if ("refused" in r) return refuse(c, r, person, "/dashboard");
    const enroll = may(holds, "enroll_subject");
    const rows = (r as SubjectView[]).map((s) => `<tr><td><a href="/subjects/${esc(s.subject_id)}">${esc(s.code)}</a></td><td>${esc(s.status)}</td><td>${esc(when(s.enrolled_at))}</td><td>${esc(s.notes ?? "")}</td></tr>`).join("");
    const body = rows
      ? `<table><thead><tr><th>Subject</th><th>Status</th><th>Enrolled</th><th>Notes</th></tr></thead><tbody>${rows}</tbody></table>`
      : enroll ? `<p><a href="/subjects/new">Enroll the first subject.</a></p>` : `<p class="muted">There are no subjects you may see yet.</p>`;
    return c.html(page("Subjects", `<h1>Subjects</h1>${enroll && rows ? `<p><a href="/subjects/new">Enroll a subject</a></p>` : ""}${body}<p><a href="/dashboard">Back to the dashboard</a></p>`, person));
  });

  app.get("/subjects/new", signedIn, async (c) => {
    const { person } = c.get("me");
    const code = await beacon.domain.nextSubjectCode(person.actor_ref);
    if (typeof code !== "string") return refuse(c, code, person, "/subjects");
    return c.html(page("Enroll a subject", `<h1>Enroll a subject</h1><form method="post" action="/subjects/new"><label for="code">Subject code</label><input id="code" value="${esc(code)}" readonly>
<label for="notes">Notes (optional)</label><textarea id="notes" name="notes" rows="3"></textarea><button type="submit">Enroll subject</button></form><p><a href="/subjects">Back to subjects</a></p>`, person));
  });

  app.post("/subjects/new", signedIn, async (c) => {
    const { person } = c.get("me");
    const f = await c.req.parseBody();
    const r = await beacon.domain.enrollSubject(person.actor_ref, beacon.keyOf(c.get("token")) ?? "", typeof f.notes === "string" ? f.notes : null);
    if ("refused" in r) return refuse(c, r, person, "/subjects/new");
    return c.redirect(`/subjects/${r.subject_id}`, 302);
  });

  const subjectPage = async (c: Ctx, id: string, error?: string): Promise<Response> => {
    const { person } = c.get("me");
    const r = await beacon.domain.subject(person.actor_ref, id);
    if ("refused" in r) return refuse(c, r, person, "/subjects");
    const by = (await beacon.people.byActor(r.subject.enrolled_by))?.display_name ?? r.subject.enrolled_by;
    const visits = r.visits.length
      ? `<table><thead><tr><th>Visit</th><th>Recorded</th><th>Notes</th></tr></thead><tbody>${r.visits.map((v: VisitView) => `<tr><td>${esc(v.kind)}</td><td>${esc(when(v.recorded_at))}</td><td>${esc(v.notes ?? "")}</td></tr>`).join("")}</tbody></table>`
      : "<p>No visits recorded yet.</p>";
    const form = r.may_record ? `<h2>Record a visit</h2>${error ? `<p class="error" role="alert">${esc(error)}</p>` : ""}<form method="post" action="/subjects/${esc(r.subject.subject_id)}/visits"><label for="kind">Visit type</label><select id="kind" name="kind"><option value="">Choose a visit type</option>${VISIT_KINDS.map((k) => `<option value="${esc(k)}">${esc(k)}</option>`).join("")}</select>
<label for="notes">Notes (optional)</label><textarea id="notes" name="notes" rows="3"></textarea><button type="submit">Record visit</button></form>` : "";
    return c.html(page(r.subject.code, `<h1>${esc(r.subject.code)}</h1><p>Status: ${esc(r.subject.status)}<br>Enrolled by ${esc(by)} on ${esc(when(r.subject.enrolled_at))}${r.subject.notes ? `<br>Notes: ${esc(r.subject.notes)}` : ""}</p><h2>Visit history</h2>${visits}${form}<p><a href="/subjects">Back to subjects</a></p>`, person), error ? 400 : 200);
  };
  app.get("/subjects/:id", signedIn, (c) => subjectPage(c, c.req.param("id")));

  app.post("/subjects/:id/visits", signedIn, async (c) => {
    const { person } = c.get("me");
    const id = c.req.param("id"), f = await c.req.parseBody();
    const r = await beacon.domain.recordVisit(person.actor_ref, beacon.keyOf(c.get("token")) ?? "", id, typeof f.kind === "string" ? f.kind : "", typeof f.notes === "string" ? f.notes : null);
    if ("refused" in r) return r.refused === "invalid-request" && r.message === MESSAGES.visitType ? subjectPage(c, id, MESSAGES.visitType) : refuse(c, r, person, `/subjects/${id}`);
    return c.redirect(`/subjects/${id}`, 302);
  });

  return app;
}

/** What a gated page answers where the person lacks every permission it needs: the page "Access denied", status 403. */
export const denied = (c: Context, needs: PermissionCode[], who?: PersonView) => c.html(deniedPage(needs, who), 403);
