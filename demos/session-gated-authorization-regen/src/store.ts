// Session's and Permissions' stores. The composition stores nothing
// (Composition state 1 and 2).
import { Database } from "@db/sqlite";

export function openStore(): Database {
  const db = new Database(":memory:");
  db.exec(`
CREATE TABLE session (session_token TEXT PRIMARY KEY, principal_ref TEXT NOT NULL, issued_by_ref TEXT NOT NULL,
  issued_at TEXT NOT NULL, expires_at TEXT NOT NULL, status TEXT NOT NULL CHECK (status IN ('active','revoked')),
  revoked_at TEXT, revoked_by_ref TEXT, revocation_reason TEXT);
CREATE TABLE grant_record (grant_id TEXT PRIMARY KEY, subject_ref TEXT NOT NULL, action_scope TEXT NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('active','revoked')), granted_at TEXT NOT NULL, revoked_at TEXT);
`);
  return db;
}
