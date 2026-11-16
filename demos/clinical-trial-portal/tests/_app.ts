// tests/_app.ts — a test app over the full route graph, and the HTTP helpers.
//
// Mirrors main.ts's route graph with one shared in-memory database (a ":memory:"
// open per request would give each request an empty one). Used by the tests of
// who sees what; e2e.test.ts keeps its own copy of the same helpers.

import { Hono } from "hono";
import type { Context } from "hono";
import { openDb, type DB } from "../lib/db.ts";
import type { AppEnv } from "../lib/env.ts";
import { authRouter } from "../routes/auth.ts";
import { invitationsRouter } from "../routes/invitations.ts";
import { dashboardRouter } from "../routes/dashboard.ts";
import { peopleRouter } from "../routes/people.ts";
import { subjectsRouter } from "../routes/subjects.ts";
import { auditRouter } from "../routes/audit.ts";
import * as parties from "../domain/parties.ts";
import * as actors from "../domain/actors.ts";
import * as credentials from "../domain/credentials.ts";
import * as grants from "../domain/grants.ts";
import * as studies from "../domain/studies.ts";
import { ensureCatalog } from "../domain/permission_catalog.ts";
import { hashPassword } from "../lib/password.ts";

export const MIGRATION_SQL = Deno.readTextFileSync(
  new URL("../migrations/0001_init.sql", import.meta.url),
);

export function buildTestApp(db: DB): Hono<AppEnv> {
  const app = new Hono<AppEnv>();
  app.use("*", async (c: Context<AppEnv>, next) => {
    c.set("db", db);
    await next();
  });
  app.get("/", (c) => c.redirect("/login"));
  app.route("/", authRouter);
  app.route("/", invitationsRouter);
  app.route("/", dashboardRouter);
  app.route("/", peopleRouter);
  app.route("/", subjectsRouter);
  app.route("/", auditRouter);
  app.notFound((c) => c.text("Not Found", 404));
  return app;
}

export function formPost(
  app: Hono<AppEnv>,
  path: string,
  fields: Record<string, string>,
  cookie?: string,
) {
  return app.request(path, {
    method: "POST",
    headers: {
      "Content-Type": "application/x-www-form-urlencoded",
      ...(cookie ? { Cookie: cookie } : {}),
    },
    body: new URLSearchParams(fields).toString(),
  });
}

export function get(app: Hono<AppEnv>, path: string, cookie?: string) {
  return app.request(path, { headers: cookie ? { Cookie: cookie } : {} });
}

export function sessionCookie(res: Response): string {
  const m = res.headers.get("set-cookie")?.match(/session=([^;]+)/);
  if (!m) throw new Error("no session cookie");
  return `session=${m[1]}`;
}

export interface World {
  db: DB;
  app: Hono<AppEnv>;
  perm: Record<string, number>;
  /** actor id by first name */
  id: Record<string, number>;
  /** logged-in cookie by first name */
  cookie: Record<string, string>;
}

/**
 * A database with the permission catalog, the study, and four people:
 *   Anya  — the PI: invite_actor, grant_permission, enroll_subject, record_visit,
 *           view_audit, view_all_subjects (as the seed grants them)
 *   Jordan — view_audit (everyone's audit events)
 *   Maya  — enroll_subject, view_own_audit (was: enroll_subject, view_audit of reach own)
 *   Sam   — enroll_subject, view_own_audit
 * Everyone is logged in.
 */
export async function world(): Promise<World> {
  const db = openDb(":memory:");
  db.exec(MIGRATION_SQL);
  const perm = ensureCatalog(db);
  studies.create(db, "BCN-OX-201", "Beacon Oncology Phase II Trial");

  const id: Record<string, number> = {};
  for (const [first, email] of [
    ["Anya", "anya@t.local"],
    ["Jordan", "jordan@t.local"],
    ["Maya", "maya@t.local"],
    ["Sam", "sam@t.local"],
  ] as const) {
    const party = parties.create(db, email, first);
    const actor = actors.create(db, party.id);
    credentials.create(db, actor.id, "password", await hashPassword("pw-" + first));
    id[first] = actor.id;
  }
  const give = (to: string, codes: string[]) => {
    for (const code of codes) {
      grants.create(db, {
        grantor_actor_id: id["Anya"],
        grantee_actor_id: id[to],
        permission_id: perm[code],
      });
    }
  };
  give("Anya", ["invite_actor", "grant_permission", "enroll_subject", "record_visit", "view_audit", "view_all_subjects"]);
  give("Jordan", ["view_audit"]);
  give("Maya", ["enroll_subject", "view_own_audit"]);
  give("Sam", ["enroll_subject", "view_own_audit"]);

  const app = buildTestApp(db);
  const cookie: Record<string, string> = {};
  for (const [first, email] of [
    ["Anya", "anya@t.local"],
    ["Jordan", "jordan@t.local"],
    ["Maya", "maya@t.local"],
    ["Sam", "sam@t.local"],
  ] as const) {
    cookie[first] = sessionCookie(await formPost(app, "/login", { email, password: "pw-" + first }));
  }
  return { db, app, perm, id, cookie };
}
