// The business side: Legal Hold's store, the business Retention Window
// instance, and the composition's two derived indexes (Composition state 1, 2).
// The audit instance's stores live in audit_store.ts, a second database, so no
// business retention can govern an audit event (Composes 8).
import { Database } from "@db/sqlite";

export function openBusinessStore(): Database {
  const db = new Database(":memory:");
  db.exec(`
-- Legal Hold (State 1 through 8): a hold is never deleted.
CREATE TABLE hold (hold_id TEXT PRIMARY KEY, record_ref TEXT NOT NULL, placed_by TEXT NOT NULL, reason TEXT NOT NULL, case_ref TEXT,
  placed_at TEXT NOT NULL, state TEXT NOT NULL CHECK (state IN ('active','released')), released_by TEXT, release_reason TEXT, released_at TEXT);
CREATE TRIGGER hold_no_delete BEFORE DELETE ON hold BEGIN SELECT RAISE(ABORT,'a hold is never deleted'); END;
-- The business Retention Window instance.
CREATE TABLE retention (retention_id TEXT PRIMARY KEY, record_ref TEXT NOT NULL, policy_ref TEXT NOT NULL, retained_at TEXT NOT NULL,
  retention_deadline TEXT NOT NULL, purge_deadline TEXT NOT NULL, state TEXT NOT NULL CHECK (state IN ('retained','purged')), purged_at TEXT);
CREATE TRIGGER retention_no_delete BEFORE DELETE ON retention BEGIN SELECT RAISE(ABORT,'a retention is never deleted'); END;
-- The composition's derived indexes: no truth of their own (Composition state 9 through 11).
CREATE TABLE record_to_retentions (record_ref TEXT NOT NULL, retention_id TEXT NOT NULL, PRIMARY KEY (record_ref, retention_id));
CREATE TABLE retention_to_record (retention_id TEXT PRIMARY KEY, record_ref TEXT NOT NULL, retention_deadline TEXT NOT NULL, purge_deadline TEXT NOT NULL);
`);
  return db;
}
