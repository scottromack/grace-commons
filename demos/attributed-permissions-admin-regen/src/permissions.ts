// Permissions: grant, revoke, the evaluation and the read.
import type { Database } from "@db/sqlite";
import type { Faults } from "./store.ts";

export type GrantAnswer = { ok: string } | { refused: "invalid-request" | "storage-failure" };
export type RevokeAnswer = { ok: true } | { refused: "not-known" | "not-active" | "storage-failure" };
export interface GrantRecord {
  grant_id: string; subject_ref: string; action_scope: string;
  status: "active" | "revoked"; granted_at: string; revoked_at: string | null;
}

// String 6: the deployment's string cap. This deployment sets it here, and
// the composition's own length cap is checked against it at start
// (Capability requirement 29 and 30).
export const STRING_CAP = 256;

// Operation 1 through 8: a pair an active grant already covers is not refused (Operation 6).
// String 2: the atom trims nothing.
export function grant(db: Database, seam: { now(): string; grantId(): string }, faults: Faults,
  subject_ref: string, action_scope: string): GrantAnswer {
  if (subject_ref === "" || action_scope === "") return { refused: "invalid-request" };
  if (subject_ref.length > STRING_CAP || action_scope.length > STRING_CAP) return { refused: "invalid-request" };
  if (faults.grantStorage) return { refused: "storage-failure" };
  const id = seam.grantId();
  db.prepare("INSERT INTO grant_record VALUES (?, ?, ?, 'active', ?, NULL)").run(id, subject_ref, action_scope, seam.now());
  return { ok: id };
}

// Operation 9 through 15.
export function revoke(db: Database, seam: { now(): string }, faults: Faults, grant_id: string): RevokeAnswer {
  const g = db.prepare("SELECT status FROM grant_record WHERE grant_id = ?").get<{ status: string }>(grant_id);
  if (!g) return { refused: "not-known" };
  if (g.status === "revoked") return { refused: "not-active" };
  if (faults.revokeStorage) return { refused: "storage-failure" };
  db.prepare("UPDATE grant_record SET status = 'revoked', revoked_at = ? WHERE grant_id = ?").run(seam.now(), grant_id);
  return { ok: true };
}

// Operation 16 through 22: exact match, never refuses, never writes.
// String 7: an over-length argument matches nothing.
export function permitted(db: Database, subject_ref: string, action_scope: string): "permitted" | "denied" {
  if (subject_ref.length > STRING_CAP || action_scope.length > STRING_CAP) return "denied";
  const row = db.prepare("SELECT 1 FROM grant_record WHERE subject_ref = ? AND action_scope = ? AND status = 'active'")
    .get(subject_ref, action_scope);
  return row ? "permitted" : "denied";
}

// Operation 26 through 29: every grant, active and revoked, with its stored
// fields. No filter; a composing pattern filters in its own code.
export function read(db: Database): GrantRecord[] {
  return db.prepare("SELECT * FROM grant_record ORDER BY grant_id").all<GrantRecord>();
}
