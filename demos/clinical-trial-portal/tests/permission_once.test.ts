// tests/permission_once.test.ts — a person holds a permission once; the screen shows
// it once; the Permissions History keeps every grant; and no reach ('all' | 'own')
// is left on a grant, so what `own` kept a person to is a permission of its own
// and nobody sees more than before.

import { assertEquals, assertStringIncludes, assert } from "jsr:@std/assert";
import * as grants from "../domain/grants.ts";
import * as eventLog from "../domain/event_log.ts";
import * as subjects from "../domain/subjects.ts";
import * as studies from "../domain/studies.ts";
import * as composition from "../composition.ts";
import { retireReach, ensureCatalog } from "../domain/permission_catalog.ts";
import { openDb } from "../lib/db.ts";
import { get, formPost, MIGRATION_SQL, world } from "./_app.ts";

async function ctxOf(w: Awaited<ReturnType<typeof world>>, first: string) {
  return {
    db: w.db,
    actor: { id: w.id[first], party_id: 0, display_name: first },
    session: null,
  };
}

// ── granting ────────────────────────────────────────────────────────────────

Deno.test("grant: a permission already held answers the grant in force and writes nothing", async () => {
  const w = await world();
  const ctx = await ctxOf(w, "Anya");
  const before = grants.listActiveOver(w.db, w.id["Sam"], w.perm["record_visit"]);
  assertEquals(before.length, 0);

  const first = composition.grantPermission(ctx, { grantee_actor_id: w.id["Sam"], permission_id: w.perm["record_visit"] });
  const eventsAfterFirst = eventLog.listFiltered(w.db, { action: "grant.issued" }).length;
  const again = composition.grantPermission(ctx, { grantee_actor_id: w.id["Sam"], permission_id: w.perm["record_visit"] });

  assertEquals(again.id, first.id, "the second call answers the grant in force");
  assertEquals(grants.listActiveOver(w.db, w.id["Sam"], w.perm["record_visit"]).length, 1);
  assertEquals(eventLog.listFiltered(w.db, { action: "grant.issued" }).length, eventsAfterFirst, "no second grant.issued");
  w.db.close();
});

Deno.test("grant: ten clicks on the Give control leave one grant", async () => {
  const w = await world();
  for (let i = 0; i < 10; i++) {
    const res = await formPost(w.app, "/grants", {
      grantee_actor_id: String(w.id["Jordan"]),
      permission_id: String(w.perm["invite_actor"]),
    }, w.cookie["Anya"]);
    assertEquals(res.status, 302);
  }
  assertEquals(grants.listActiveOver(w.db, w.id["Jordan"], w.perm["invite_actor"]).length, 1);
  w.db.close();
});

// ── the screen ──────────────────────────────────────────────────────────────

Deno.test("screen: each permission shown once, the Give control offers only what is not held, words not codes", async () => {
  const w = await world();
  const html = await (await get(w.app, "/people", w.cookie["Anya"])).text();

  assertStringIncludes(html, "Permissions History");
  assertEquals(html.includes('name="scope"'), false, "no all / own choice");
  for (const code of ["invite_actor", "grant_permission", "enroll_subject", "record_visit", "view_audit", "view_own_audit", "view_all_subjects"]) {
    assertEquals(html.includes(code) && !html.includes(`value="${code}"`), false, `no action code "${code}" where a name can stand`);
  }
  assertStringIncludes(html, "See everyone&#39;s audit events");

  // Sam holds two permissions: the Give control in his row offers the other five.
  const samRow = html.split("<tr").find((r) => r.includes("sam@t.local"))!;
  const offered = [...samRow.matchAll(/<option value="\d+">([^<]+)<\/option>/g)].map((m) => m[1]);
  assertEquals(offered.includes("Enroll subjects"), false);
  assertEquals(offered.includes("See my own audit events"), false);
  assertEquals(offered.length, 5);
  w.db.close();
});

Deno.test("screen: a person granted the same permission twice (grants recorded before the rule) shows it once, withdrawn once, both grants in the history", async () => {
  const w = await world();
  // Two active grants over one pair: what the screen made twelve of before.
  for (let i = 0; i < 2; i++) {
    grants.create(w.db, { grantor_actor_id: w.id["Anya"], grantee_actor_id: w.id["Jordan"], permission_id: w.perm["invite_actor"] });
  }
  const html = await (await get(w.app, "/people", w.cookie["Anya"])).text();
  const jordanRow = html.split("<tr").find((r) => r.includes("jordan@t.local"))!;
  assertEquals(jordanRow.split(">Invite people").length - 1, 1, "shown once in the chips (the Give control no longer offers it)");
  assertStringIncludes(jordanRow, "Invite people (2 grants)");

  const res = await formPost(w.app, "/permissions/revoke", {
    grantee_actor_id: String(w.id["Jordan"]),
    permission_id: String(w.perm["invite_actor"]),
  }, w.cookie["Anya"]);
  assertEquals(res.status, 302);
  assertEquals(grants.holds(w.db, w.id["Jordan"], "invite_actor"), false, "none of its grants is left active");
  assertEquals(eventLog.listFiltered(w.db, { action: "grant.revoked" }).length, 2, "one grant.revoked per grant");

  const after = await (await get(w.app, "/people", w.cookie["Anya"])).text();
  const history = after.slice(after.indexOf("Permissions History"));
  const jordanInvite = history.split("<tr").filter((r) => r.includes("Jordan") && r.includes("Invite people"));
  assertEquals(jordanInvite.length, 2, "both grants stay in the history");
  assert(jordanInvite.every((r) => r.includes("Taken away")), "both marked taken away");
  w.db.close();
});

Deno.test("revoke: a pair that holds no active grant writes nothing", async () => {
  const w = await world();
  const ctx = await ctxOf(w, "Anya");
  const before = eventLog.listAll(w.db).length;
  const out = composition.revokePermission(ctx, { grantee_actor_id: w.id["Jordan"], permission_id: w.perm["record_visit"], reason: "x" });
  assertEquals(out.length, 0);
  assertEquals(eventLog.listAll(w.db).length, before);
  w.db.close();
});

// ── what `own` kept a person to: each place, narrow against wide ────────────

function actorsIn(html: string): Set<number> {
  return new Set([...html.matchAll(/actor#(\d+)/g)].map((m) => Number(m[1])));
}

Deno.test("audit list: view_own_audit shows only the person's own events; view_audit shows everyone's", async () => {
  const w = await world();
  // Events by several people: logins already made one each (session.opened / login.succeeded).
  const maya = actorsIn(await (await get(w.app, "/audit", w.cookie["Maya"])).text());
  assertEquals([...maya], [w.id["Maya"]], "Maya sees her own events and no one else's");
  const jordan = actorsIn(await (await get(w.app, "/audit", w.cookie["Jordan"])).text());
  for (const first of ["Anya", "Jordan", "Maya", "Sam"]) assert(jordan.has(w.id[first]), `Jordan sees ${first}'s events`);
  w.db.close();
});

Deno.test("audit export: view_own_audit exports only the person's own events; view_audit exports everyone's", async () => {
  const w = await world();
  const actorColumn = (csv: string) =>
    new Set(csv.trim().split("\n").slice(1).map((line) => line.split(",")[2].replaceAll('"', "")));
  const maya = actorColumn(await (await get(w.app, "/audit/export.csv", w.cookie["Maya"])).text());
  assertEquals([...maya], [String(w.id["Maya"])]);
  const jordan = actorColumn(await (await get(w.app, "/audit/export.csv", w.cookie["Jordan"])).text());
  assert(jordan.size >= 4, "Jordan's export holds every person's events");
  w.db.close();
});

Deno.test("audit: a person with neither audit permission is refused", async () => {
  const w = await world();
  // Withdraw Sam's own-audit permission through the screen's call.
  composition.revokePermission(await ctxOf(w, "Anya"), { grantee_actor_id: w.id["Sam"], permission_id: w.perm["view_own_audit"], reason: "test" });
  assertEquals((await get(w.app, "/audit", w.cookie["Sam"])).status, 403);
  assertEquals((await get(w.app, "/audit/export.csv", w.cookie["Sam"])).status, 403);
  w.db.close();
});

Deno.test("subjects list and detail: without view_all_subjects a person sees the subjects that person enrolled; with it, every subject", async () => {
  const w = await world();
  const study = studies.getByProtocol(w.db, "BCN-OX-201")!;
  const bySam = subjects.create(w.db, { study_id: study.id, subject_code: "BCN-001", enrolled_by_actor_id: w.id["Sam"], notes: null });
  const byMaya = subjects.create(w.db, { study_id: study.id, subject_code: "BCN-002", enrolled_by_actor_id: w.id["Maya"], notes: null });

  const mayaList = await (await get(w.app, "/subjects", w.cookie["Maya"])).text();
  assertStringIncludes(mayaList, "BCN-002");
  assertEquals(mayaList.includes("BCN-001"), false, "Maya's list holds no subject Sam enrolled");
  assertEquals((await get(w.app, `/subjects/${byMaya.id}`, w.cookie["Maya"])).status, 200);
  assertEquals((await get(w.app, `/subjects/${bySam.id}`, w.cookie["Maya"])).status, 404, "nor its detail");

  const anyaList = await (await get(w.app, "/subjects", w.cookie["Anya"])).text();
  assertStringIncludes(anyaList, "BCN-001");
  assertStringIncludes(anyaList, "BCN-002");
  assertEquals((await get(w.app, `/subjects/${bySam.id}`, w.cookie["Anya"])).status, 200);
  w.db.close();
});

Deno.test("no reach is left: no two grants over one permission can disagree, and no code reads a granted scope", async () => {
  // The finding (d) the unit counted: with 'own' and 'all' both held, the one issued
  // first applied. With no reach there is nothing to choose between: a permission
  // answers held or not held, whichever grant is first.
  const w = await world();
  const found = grants.findActiveFor(w.db, w.id["Anya"], ["view_audit"]);
  assert(found !== null);
  assertEquals("scope" in (found as unknown as Record<string, unknown>), true, "the column remains in the table, unread");
  for (const file of ["../routes/audit.ts", "../routes/subjects.ts", "../middleware/require_permission.ts", "../routes/people.ts", "../composition.ts", "../lib/env.ts"]) {
    const text = Deno.readTextFileSync(new URL(file, import.meta.url));
    assertEquals(/granted_scope|\.scope\b/.test(text), false, `${file} reads no granted scope`);
  }
  w.db.close();
});

// ── a database built while grants carried a reach ───────────────────────────

Deno.test("retireReach: own audit becomes view_own_audit, wide enrol becomes view_all_subjects, once, and nobody sees more", () => {
  const db = openDb(":memory:");
  db.exec(MIGRATION_SQL);
  const ids = ensureCatalog(db);
  db.exec(`
    INSERT INTO parties (id, email, display_name, created_at) VALUES (1,'a@x','A','t'),(2,'b@x','B','t'),(3,'c@x','C','t');
    INSERT INTO actors (id, party_id, created_at) VALUES (1,1,'t'),(2,2,'t'),(3,3,'t');
  `);
  const ins = db.prepare(
    "INSERT INTO grants (grantor_actor_id, grantee_actor_id, permission_id, scope, issued_at) VALUES (1, ?, ?, ?, 't')",
  );
  ins.run(1, ids["enroll_subject"], "all");      // PI: sees every subject
  ins.run(2, ids["enroll_subject"], "own");      // coordinator: sees hers
  ins.run(2, ids["view_audit"], "own");          // coordinator: her own audit events
  ins.run(3, ids["view_audit"], "all");          // auditor: everyone's

  const done = retireReach(db);
  assertEquals(done.skipped, false);
  const holds = (actor: number, code: string) => grants.holds(db, actor, code);
  assertEquals(holds(1, "view_all_subjects"), true);
  assertEquals(holds(2, "view_all_subjects"), false, "own enrolment stays narrow");
  assertEquals(holds(2, "view_audit"), false, "own audit is not everyone's");
  assertEquals(holds(2, "view_own_audit"), true);
  assertEquals(holds(3, "view_audit"), true);
  assertEquals(holds(3, "view_own_audit"), false);

  // Once per database: a later grant of enroll_subject (reach column defaulting to
  // 'all') must not hand out view_all_subjects at the next start.
  ins.run(3, ids["enroll_subject"], "all");
  assertEquals(retireReach(db).skipped, true);
  assertEquals(holds(3, "view_all_subjects"), false);
  db.close();
});
