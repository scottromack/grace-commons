// Beacon's pages: the front page, sign in and sign out, accepting an invitation, People & Permissions, the dashboard, the Audit Trail pages (the list, chain verification, the export) and its retention switch, the "Access denied" page, and the subjects (the list, Enroll Subject, a subject and Record Visit).
// Built from SPEC.md (The screens; People & Permissions' words; The permissions) with Hono, the stack STACK.md pins. Every screen is a page the server
// draws and every action works with no script running in the browser (SPEC.md, The screens): forms post, the server answers with a page or a redirect.
//
// A session is a random opaque value kept in a cookie the browser's scripts cannot read (HttpOnly), and the session record, not the cookie, is what
// makes a person signed in (SPEC.md): the cookie holds the session token and nothing else, and every request asks Session whether it is still valid.
import { Hono, type Context } from "hono";
import { getCookie, setCookie, deleteCookie } from "hono/cookie";
import { type Beacon, SEED, INVITATION_WORDS, MIN_PASSWORD, readContext } from "./beacon.ts";
import { PERMISSIONS, VISIT_KINDS, MESSAGES, type PermissionCode, type Refusal, type SubjectView, type VisitView } from "./beacon_domain.ts";
import { type PersonView } from "./beacon_people.ts";
import { type AuditRow, RETENTION_DAYS } from "./beacon_audit.ts";
import { type PersonRow, type HistoryRow, type PendingRow } from "./beacon_admin.ts";

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

  // ---- Accepting an invitation (SPEC.md, The screens, Accept an invitation) -----------------------------------------------------

  /** A link that will not do answers one sentence and no form (SPEC.md); the three are its own words. */
  const badLink = (c: Context, why: keyof typeof INVITATION_WORDS) => c.html(page("Invitation", `<h1>Invitation</h1><p class="error" role="alert">${esc(INVITATION_WORDS[why])}</p><p><a href="/login">Sign in</a></p>`), why === "unknown" ? 404 : 410);

  const acceptForm = (token: string, i: { email: string; role: string; display_name: string }, error?: string) => page("Set up your account", `<h1>Set up your account</h1>${error ? `<p class="error" role="alert">${esc(error)}</p>` : ""}
<form method="post" action="/invitations/accept/${esc(encodeURIComponent(token))}"><label for="email">Email</label><input id="email" value="${esc(i.email)}" readonly>
<label for="role">Your role</label><input id="role" value="${esc(i.role)}" readonly>
<label for="password">Password (at least ${MIN_PASSWORD} characters)</label><input id="password" name="password" type="password" autocomplete="new-password" minlength="${MIN_PASSWORD}" required>
<label for="confirm">Confirm password</label><input id="confirm" name="confirm" type="password" autocomplete="new-password" required><button type="submit">Create account</button></form>`);

  app.get("/invitations/accept/:token", async (c) => {
    const token = c.req.param("token"), i = await beacon.invitationFor(token);
    return "invalid" in i ? badLink(c, i.invalid) : c.html(acceptForm(token, i));
  });

  app.post("/invitations/accept/:token", async (c) => {
    const token = c.req.param("token"), f = await c.req.parseBody();
    const r = await beacon.acceptInvitation(token, typeof f.password === "string" ? f.password : "", typeof f.confirm === "string" ? f.confirm : "");
    if ("invalid" in r) return badLink(c, r.invalid);
    if ("refused" in r) {
      const i = await beacon.invitationFor(token);
      if ("invalid" in i) return badLink(c, i.invalid);
      const say = r.refused === "invalid-request" ? (r.message ?? "That was not accepted.") : r.refused === "state-unavailable" ? WORDS_OF.unavailable : WORDS_OF.storage;
      return c.html(acceptForm(token, i, say), r.refused === "invalid-request" ? 400 : 503);
    }
    setCookie(c, COOKIE, r.session_token, { httpOnly: true, sameSite: "Lax", path: "/", maxAge: SESSION_SECONDS, secure: o.secureCookie ?? false });   // accepting signs the person in
    return c.redirect("/dashboard", 302);                                                                             // and sends the person to the dashboard
  });

  // ---- Audit Trail (SPEC.md, The screens, Audit Trail) ---------------------------------------------------------------------------

  const auditPage = async (c: Ctx): Promise<Response> => {
    const { person } = c.get("me");
    const q = (k: string) => c.req.query(k) ?? "";
    const r = await beacon.audits.view(person.actor_ref, beacon.keyOf(c.get("token")) ?? "", { action: q("action"), from: q("from"), to: q("to") });
    if ("refused" in r) return r.refused === "invalid-request" && r.message ? c.html(page("Audit Trail", `<h1>Audit Trail</h1><p class="error" role="alert">${esc(r.message)}</p><p><a href="/audit">Back to the audit trail</a></p>`, person), 400) : refuse(c, r, person, "/dashboard");
    const row = (e: AuditRow) => `<tr><td>${e.number}</td><td>${esc(when(e.recorded_at))}</td><td>${esc(e.action)}</td><td>${esc(e.target)}</td><td>${esc(e.actor)}</td><td><code>${esc(e.payload)}</code></td></tr>`;
    const opt = (a: string) => `<option value="${esc(a)}"${a === r.filters.action ? " selected" : ""}>${esc(a)}</option>`;
    const body = `<h1>Audit Trail</h1><p class="muted">${r.scope === "all" ? "Everyone's events." : "Your own events."}</p>
<p><a href="/audit/verify">Verify chain</a> · <a href="/audit/export.csv">Export CSV</a></p>
<form method="get" action="/audit"><label for="action">Action</label><select id="action" name="action"><option value="">All actions</option>${r.actions.map(opt).join("")}</select>
<label for="from">From (date)</label><input id="from" name="from" type="date" value="${esc(r.filters.from ?? "")}"><label for="to">To (date)</label><input id="to" name="to" type="date" value="${esc(r.filters.to ?? "")}"><button type="submit">Filter</button></form>
<form method="post" action="/audit/retention"><p>Retention window: <strong>${r.retention_on ? `on, the last ${RETENTION_DAYS} days` : "off, every event is shown"}</strong>. It hides events from this page and never deletes one.</p>
<input type="hidden" name="on" value="${r.retention_on ? "false" : "true"}"><button type="submit">Turn the retention window ${r.retention_on ? "off" : "on"}</button></form>
${r.rows.length ? `<table><thead><tr><th>#</th><th>Time</th><th>Action</th><th>Target</th><th>Actor</th><th>Payload</th></tr></thead><tbody>${r.rows.map(row).join("")}</tbody></table>` : "<p>No events match.</p>"}<p><a href="/dashboard">Back to the dashboard</a></p>`;
    return c.html(page("Audit Trail", body, person));
  };
  app.get("/audit", signedIn, (c) => auditPage(c));

  app.get("/audit/verify", signedIn, async (c) => {
    const { person } = c.get("me");
    const r = await beacon.audits.verifyChain(person.actor_ref, beacon.keyOf(c.get("token")) ?? "");
    if ("refused" in r) return refuse(c, r, person, "/audit");                                                              // verifying: a refusal
    const back = `<p><a href="/audit">Back to the audit trail</a></p>`;
    return c.html(page("Chain verification", "intact" in r && r.intact
      ? `<h1>Chain verification</h1><p><strong>Chain intact.</strong> ${r.checked} event${r.checked === 1 ? "" : "s"} checked.${r.unsealed ? ` ${r.unsealed} more ${r.unsealed === 1 ? "was" : "were"} written while this page ran and ${r.unsealed === 1 ? "is" : "are"} sealed at the next check.` : ""}</p>${back}`
      : `<h1>Chain verification</h1><p class="error" role="alert"><strong>Tampering detected.</strong> Event ${"event" in r ? r.event.number : ""} (${esc("event" in r ? r.event.action : "")}) failed: ${esc("reason" in r ? r.reason : "")}. ${r.checked} event${r.checked === 1 ? "" : "s"} before it were checked.</p>${back}`, person));
  });

  app.get("/audit/export.csv", signedIn, async (c) => {
    const { person } = c.get("me");
    const r = await beacon.audits.exportCsv(person.actor_ref, beacon.keyOf(c.get("token")) ?? "");
    if ("refused" in r) return refuse(c, r, person, "/audit");                                                              // exporting: a refusal
    return new Response(r.csv, { status: 200, headers: { "content-type": "text/csv; charset=utf-8", "content-disposition": `attachment; filename="${r.filename}"` } });
  });

  app.post("/audit/retention", signedIn, async (c) => {
    const { person } = c.get("me");
    const f = await c.req.parseBody();
    const r = await beacon.audits.setRetention(person.actor_ref, beacon.keyOf(c.get("token")) ?? "", f.on === "true");
    if ("refused" in r) return refuse(c, r, person, "/audit");
    return c.redirect("/audit", 302);
  });

  // ---- People & Permissions (SPEC.md, The screens, People & Permissions) ---------------------------------------------------------

  const permWords = (code: string): string => WORDS[code as PermissionCode] ?? code;
  const peoplePage = async (c: Ctx, o: { link?: string } = {}): Promise<Response> => {
    const { person } = c.get("me");
    const v = await beacon.peopleAdmin.view(person.actor_ref, readContext);
    if ("refused" in v) return refuse(c, v, person, "/dashboard");
    const origin = new URL(c.req.url).origin;
    const mark = (p: PersonRow, code: PermissionCode) => `<li>${esc(permWords(code))}${v.may_grant ? ` <form method="post" action="/people/take" style="display:inline"><input type="hidden" name="person" value="${esc(p.person.actor_ref)}"><input type="hidden" name="permission" value="${esc(code)}"><button type="submit" aria-label="Take away ${esc(permWords(code))} from ${esc(p.person.display_name)}">Take away</button></form>` : ""}</li>`;
    const personRow = (p: PersonRow) => `<tr><td>${esc(p.person.display_name)}</td><td>${esc(p.person.email)}</td><td>${p.held.length === PERMISSIONS.length ? "holds every permission" : p.held.length ? `<ul>${p.held.map((x) => mark(p, x)).join("")}</ul>` : "none"}${v.may_grant && p.offered.length ? `<form method="post" action="/people/give"><input type="hidden" name="person" value="${esc(p.person.actor_ref)}"><label for="give-${esc(p.person.actor_ref)}">Give</label><select id="give-${esc(p.person.actor_ref)}" name="permission">${p.offered.map((x) => `<option value="${esc(x)}">${esc(permWords(x))}</option>`).join("")}</select><button type="submit">Give</button></form>` : ""}</td></tr>`;
    const histRow = (h: HistoryRow) => `<tr><td>${esc(when(h.granted_at))}</td><td>${esc(h.to)}</td><td>${esc(permWords(h.code))}</td><td>${esc(h.by)}</td><td>${h.held_now ? "held now" : `revoked ${esc(h.revoked_at ? when(h.revoked_at) : "")}`}</td></tr>`;
    const pendRow = (i: PendingRow) => `<tr><td>${esc(i.email)}</td><td>${esc(i.role)}</td><td>${esc(when(i.expires_at))}</td><td><code>${esc(`${origin}/invitations/accept/${i.invitation_token}`)}</code></td><td>${v.may_invite ? `<form method="post" action="/people/invitations/${esc(encodeURIComponent(i.invitation_token))}/revoke"><button type="submit">Revoke</button></form>` : ""}</td></tr>`;
    const invite = v.may_invite ? `<h2>Invite someone</h2>${o.link ? `<p>Invite link — copy and share this with the invitee: <code>${esc(o.link)}</code></p>` : ""}<form method="post" action="/people/invite"><label for="inv-email">Email</label><input id="inv-email" name="email" type="email" required><label for="inv-name">Display name</label><input id="inv-name" name="display_name" required><label for="inv-role">Role</label><input id="inv-role" name="role" list="roles" placeholder="coordinator" required><datalist id="roles"><option value="coordinator"></datalist><button type="submit">Invite</button></form>` : "";
    return c.html(page("People & Permissions", `<h1>People &amp; Permissions</h1><h2>People</h2><table><thead><tr><th>Name</th><th>Email</th><th>Permissions held now</th></tr></thead><tbody>${v.people.map(personRow).join("")}</tbody></table>
<h2>Permissions History</h2><p class="muted">Every permission ever given, oldest first. It records who gave what; it never opens or closes anything.</p>${v.history.length ? `<table><thead><tr><th>When</th><th>To</th><th>Permission</th><th>Given by</th><th>Held now</th></tr></thead><tbody>${v.history.map(histRow).join("")}</tbody></table>` : "<p>No permission has been given yet.</p>"}
<h2>Pending Invitations</h2>${v.pending.length ? `<table><thead><tr><th>Email</th><th>Role</th><th>Expires</th><th>Link</th><th></th></tr></thead><tbody>${v.pending.map(pendRow).join("")}</tbody></table>` : "<p>No invitation is waiting.</p>"}${invite}<p><a href="/dashboard">Back to the dashboard</a></p>`, person));
  };
  app.get("/people", signedIn, (c) => peoplePage(c));

  const grantAction = (which: "give" | "take") => async (c: Ctx) => {
    const { person } = c.get("me");
    const f = await c.req.parseBody();
    const who = typeof f.person === "string" ? f.person : "", code = typeof f.permission === "string" ? f.permission : "";
    const key = beacon.keyOf(c.get("token")) ?? "";
    const r = which === "give" ? await beacon.peopleAdmin.give(person.actor_ref, key, who, code) : await beacon.peopleAdmin.take(person.actor_ref, key, who, code);
    if ("refused" in r) return refuse(c, r, person, "/people");
    return c.redirect("/people", 302);                                                                                  // give or take: back to the page
  };
  app.post("/people/give", signedIn, grantAction("give"));
  app.post("/people/take", signedIn, grantAction("take"));

  app.post("/people/invite", signedIn, async (c) => {
    const { person } = c.get("me");
    const f = await c.req.parseBody();
    const r = await beacon.invite(c.get("token"), typeof f.email === "string" ? f.email : "", typeof f.display_name === "string" ? f.display_name : "", typeof f.role === "string" ? f.role : "");
    if ("refused" in r) return refuse(c, r, person, "/people");
    return peoplePage(c, { link: `${new URL(c.req.url).origin}/invitations/accept/${r.invitation_token}` });                // Beacon sends no email in this render: the link is shown to copy and share
  });

  app.post("/people/invitations/:token/revoke", signedIn, async (c) => {
    const { person } = c.get("me");
    const r = await beacon.revokeInvitation(c.get("token"), c.req.param("token"));
    if (r !== "revoked") return refuse(c, r, person, "/people");
    return c.redirect("/people", 302);                                                                                  // revoke: back to the page
  });

  return app;
}

/** What a gated page answers where the person lacks every permission it needs: the page "Access denied", status 403. */
export const denied = (c: Context, needs: PermissionCode[], who?: PersonView) => c.html(deniedPage(needs, who), 403);
