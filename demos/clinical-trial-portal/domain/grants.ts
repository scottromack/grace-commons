// domain/grants.ts
//
// Atom: Permissions (grants)
//
// Library spec (quoted from grace-commons/atoms/permissions.md):
//   "A grant is the atom's unit of authorization: a binding of a subject to an
//    action scope that remains active until revoked. Evaluation is grant-lookup:
//    if any active grant exists for the queried (subject, scope) pair, the answer
//    is permitted; otherwise denied. No active grant, no permission — there is
//    no implicit permission and no notion of a default-allow posture within this
//    atom. [...] grants are immutable once recorded; revocation is terminal;
//    evaluation is a read-only query over the active grant set."
//
// The reach of a permission (the old `scope` column, 'all' | 'own') is gone from
//   this render: a permission is held or not held, nothing more. Where `own` once
//   kept a person to that person's own records, a permission of its own now says
//   so (`view_own_audit` against `view_audit`; subjects the person enrolled
//   against `view_all_subjects`). The column stays in the table, unread and never
//   written, so the conformance fixture and the other renders' agreement on the
//   table's shape are as before.
//
// Invariants:
//   - A grant is active until its revoked_at is set (terminal)
//   - revoke_reason is required when revoking (composition layer enforces this)
//   - grantor_actor_id captures who issued the grant (attribution)
//   - a subject holds at most one active grant over one permission
//     (composition.grantPermission answers the grant in force and writes nothing);
//     grants recorded before that rule may stand twice, and show once

import type { DB } from "../lib/db.ts";

export interface Grant {
  id: number;
  grantor_actor_id: number;
  grantee_actor_id: number;
  permission_id: number;
  issued_at: string;
  revoked_at: string | null;
  revoke_reason: string | null;
}

/** A grant with the permission code joined in — useful for display. */
export interface GrantWithCode extends Grant {
  permission_code: string;
  permission_label: string;
}

/** Find a grant by id. Returns null if not found. */
export function getById(db: DB, id: number): Grant | null {
  return (
    db.prepare("SELECT * FROM grants WHERE id = ?").get<Grant>(id) ?? null
  );
}

/**
 * Find the first active grant for an actor that covers any of the given
 * permission codes. Returns null if no active matching grant exists.
 *
 * Used by requirePermission middleware (Appendix A.9).
 */
export function findActiveFor(
  db: DB,
  actor_id: number,
  codes: string[],
): Grant | null {
  if (codes.length === 0) return null;
  const placeholders = codes.map(() => "?").join(",");
  return (
    db
      .prepare(
        `SELECT g.*
         FROM grants g
         JOIN permissions p ON p.id = g.permission_id
         WHERE g.grantee_actor_id = ?
           AND p.code IN (${placeholders})
           AND g.revoked_at IS NULL
         LIMIT 1`,
      )
      .get<Grant>(actor_id, ...codes) ?? null
  );
}

/** Does the actor hold the permission now (an active grant, however many)? */
export function holds(db: DB, actor_id: number, code: string): boolean {
  return findActiveFor(db, actor_id, [code]) !== null;
}

/** Every active grant the actor holds over one permission, oldest first. */
export function listActiveOver(
  db: DB,
  actor_id: number,
  permission_id: number,
): Grant[] {
  return db
    .prepare(
      `SELECT * FROM grants
       WHERE grantee_actor_id = ? AND permission_id = ? AND revoked_at IS NULL
       ORDER BY issued_at ASC, id ASC`,
    )
    .all<Grant>(actor_id, permission_id);
}

/** Return every grant for an actor (revoked ones too), with permission code included. */
export function listForActor(db: DB, actor_id: number): GrantWithCode[] {
  return db
    .prepare(
      `SELECT g.*, p.code AS permission_code, p.label AS permission_label
       FROM grants g
       JOIN permissions p ON p.id = g.permission_id
       WHERE g.grantee_actor_id = ?
       ORDER BY g.issued_at ASC`,
    )
    .all<GrantWithCode>(actor_id);
}

/** Return all grants (all actors), with permission code included, for the people view. */
export function listAll(db: DB): GrantWithCode[] {
  return db
    .prepare(
      `SELECT g.*, p.code AS permission_code, p.label AS permission_label
       FROM grants g
       JOIN permissions p ON p.id = g.permission_id
       ORDER BY g.grantee_actor_id ASC, g.issued_at ASC`,
    )
    .all<GrantWithCode>();
}

/** A grant in the history: who held it, who granted it, under which permission. */
export interface GrantHistoryRow extends GrantWithCode {
  grantee_name: string;
  grantor_name: string;
}

/** Every grant ever issued, oldest first, revoked ones included (Permissions History). */
export function listHistory(db: DB): GrantHistoryRow[] {
  return db
    .prepare(
      `SELECT g.*, p.code AS permission_code, p.label AS permission_label,
              pe.display_name AS grantee_name, pr.display_name AS grantor_name
       FROM grants g
       JOIN permissions p ON p.id = g.permission_id
       JOIN actors ae ON ae.id = g.grantee_actor_id
       JOIN parties pe ON pe.id = ae.party_id
       JOIN actors ar ON ar.id = g.grantor_actor_id
       JOIN parties pr ON pr.id = ar.party_id
       ORDER BY g.issued_at ASC, g.id ASC`,
    )
    .all<GrantHistoryRow>();
}

/**
 * Create a new grant record.
 * Called only from composition.grantPermission — never directly from routes.
 */
export function create(
  db: DB,
  input: {
    grantor_actor_id: number;
    grantee_actor_id: number;
    permission_id: number;
  },
): Grant {
  const now = new Date().toISOString();
  const row = db
    .prepare(
      `INSERT INTO grants
         (grantor_actor_id, grantee_actor_id, permission_id, issued_at)
       VALUES (?, ?, ?, ?) RETURNING *`,
    )
    .get<Grant>(
      input.grantor_actor_id,
      input.grantee_actor_id,
      input.permission_id,
      now,
    );
  if (!row) throw new Error("grants.create: insert returned no row");
  return row;
}

/**
 * Revoke a grant by id.
 * Called only from composition.revokeGrant — never directly from routes.
 */
export function revoke(db: DB, id: number, reason: string): void {
  const now = new Date().toISOString();
  db.prepare(
    `UPDATE grants SET revoked_at = ?, revoke_reason = ?
     WHERE id = ? AND revoked_at IS NULL`,
  ).run(now, reason, id);
}
