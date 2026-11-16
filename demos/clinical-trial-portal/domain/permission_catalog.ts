// domain/permission_catalog.ts
//
// The permissions Beacon knows, with the plain words the screens show, and the
// one-time retirement of the old reach ('all' | 'own' on a grant) for a database
// that was built while grants carried one.
//
// A permission is held or not held, nothing more. Where `own` once kept a person
// to that person's own records, a permission of its own says so:
//
//   view_audit         See everyone's audit events   (was view_audit, reach all)
//   view_own_audit     See my own audit events       (was view_audit, reach own)
//   view_all_subjects  See every subject             (was enroll_subject or
//                      record_visit, reach all; without it a person sees the
//                      subjects that person enrolled)

import type { DB } from "../lib/db.ts";

export const CATALOG = [
  { code: "invite_actor", label: "Invite people" },
  { code: "grant_permission", label: "Give and take away permissions" },
  { code: "enroll_subject", label: "Enroll subjects" },
  { code: "record_visit", label: "Record visits" },
  { code: "view_audit", label: "See everyone's audit events" },
  { code: "view_own_audit", label: "See my own audit events" },
  { code: "view_all_subjects", label: "See every subject" },
] as const;

/** Insert each permission that is missing and set each label to the catalog's. */
export function ensureCatalog(db: DB): Record<string, number> {
  const ids: Record<string, number> = {};
  for (const def of CATALOG) {
    const row = db
      .prepare("SELECT id FROM permissions WHERE code = ?")
      .get<{ id: number }>(def.code);
    if (row) {
      db.prepare("UPDATE permissions SET label = ? WHERE id = ?").run(def.label, row.id);
      ids[def.code] = row.id;
    } else {
      const made = db
        .prepare("INSERT INTO permissions (code, label) VALUES (?, ?) RETURNING id")
        .get<{ id: number }>(def.code, def.label);
      ids[def.code] = made!.id;
    }
  }
  return ids;
}

/** PRAGMA user_version that marks a database whose reach is retired. */
export const REACH_RETIRED_VERSION = 2;

/**
 * Retire the reach on grants, once per database (PRAGMA user_version), so no
 * person sees more afterwards than before:
 *   - an active view_audit grant of reach 'own' is revoked and the person is
 *     granted view_own_audit, by the same grantor;
 *   - an active enroll_subject or record_visit grant of reach 'all' gives the
 *     person view_all_subjects, by the same grantor.
 * Direct writes, like the seed's bootstrap grants: no audit event is recorded
 * for them (README, seams). Returns what it did, for the log.
 */
export function retireReach(db: DB): { revoked: number; granted: number; skipped: boolean } {
  const version = db.prepare("PRAGMA user_version").get<{ user_version: number }>()!.user_version;
  if (version >= REACH_RETIRED_VERSION) return { revoked: 0, granted: 0, skipped: true };

  const ids = ensureCatalog(db);
  const now = new Date().toISOString();
  let revoked = 0;
  let granted = 0;

  const holdsNow = (actor: number, permission: number) =>
    db
      .prepare(
        "SELECT 1 AS x FROM grants WHERE grantee_actor_id = ? AND permission_id = ? AND revoked_at IS NULL LIMIT 1",
      )
      .get(actor, permission) !== undefined;
  const grant = (grantor: number, grantee: number, permission: number) => {
    if (holdsNow(grantee, permission)) return;
    db.prepare(
      "INSERT INTO grants (grantor_actor_id, grantee_actor_id, permission_id, issued_at) VALUES (?, ?, ?, ?)",
    ).run(grantor, grantee, permission, now);
    granted++;
  };

  type Legacy = { id: number; grantor_actor_id: number; grantee_actor_id: number; code: string; scope: string };
  const legacy = db
    .prepare(
      `SELECT g.id, g.grantor_actor_id, g.grantee_actor_id, p.code, g.scope
       FROM grants g JOIN permissions p ON p.id = g.permission_id
       WHERE g.revoked_at IS NULL ORDER BY g.id ASC`,
    )
    .all<Legacy>();

  for (const g of legacy) {
    if (g.code === "view_audit" && g.scope === "own") {
      db.prepare(
        "UPDATE grants SET revoked_at = ?, revoke_reason = ? WHERE id = ? AND revoked_at IS NULL",
      ).run(now, "reach retired: held now as view_own_audit", g.id);
      revoked++;
      grant(g.grantor_actor_id, g.grantee_actor_id, ids["view_own_audit"]);
    } else if ((g.code === "enroll_subject" || g.code === "record_visit") && g.scope === "all") {
      grant(g.grantor_actor_id, g.grantee_actor_id, ids["view_all_subjects"]);
    }
  }

  db.exec(`PRAGMA user_version = ${REACH_RETIRED_VERSION}`);
  return { revoked, granted, skipped: false };
}
