// The business side: Party Identity's store, the party retention instance, and
// the composition's four derived indexes (Composition state 1 through 4). The
// audit instance's stores are a second database (Composes 8).
import { Database } from "@db/sqlite";
export function openBusinessStore(): Database {
  const db = new Database(":memory:");
  db.exec(`
CREATE TABLE party (party_id TEXT PRIMARY KEY, name TEXT, date_of_birth TEXT, document_type TEXT, document_ref TEXT, enrolled_by TEXT,
  enrolled_at TEXT NOT NULL, state TEXT NOT NULL CHECK (state IN ('unverified','verified','suspended','closed')));
CREATE TABLE party_event (seq INTEGER PRIMARY KEY AUTOINCREMENT, party_id TEXT NOT NULL, kind TEXT NOT NULL, id TEXT NOT NULL,
  result TEXT, prior TEXT, next TEXT, actor TEXT, reason TEXT, at TEXT NOT NULL);
CREATE TRIGGER party_no_delete BEFORE DELETE ON party BEGIN SELECT RAISE(ABORT,'no removal'); END;
CREATE TABLE retention (retention_id TEXT PRIMARY KEY, record_ref TEXT NOT NULL, policy_ref TEXT NOT NULL, retained_at TEXT NOT NULL,
  retention_deadline TEXT NOT NULL, purge_deadline TEXT NOT NULL, state TEXT NOT NULL, purged_at TEXT);
CREATE TABLE party_to_case (party_id TEXT PRIMARY KEY, case_id TEXT NOT NULL, enrollment_path TEXT NOT NULL, active INTEGER NOT NULL);
CREATE TABLE case_to_monitoring (case_id TEXT PRIMARY KEY, party_id TEXT NOT NULL, opened_at TEXT NOT NULL, next_review_due TEXT NOT NULL);
CREATE TABLE case_to_retentions (case_id TEXT PRIMARY KEY, current_placement TEXT NOT NULL, post_closure_placement TEXT);
CREATE TABLE case_to_open_triggers (case_id TEXT NOT NULL, trigger_id TEXT NOT NULL, trigger_type TEXT NOT NULL, trigger_ref TEXT NOT NULL, trigger_instant TEXT NOT NULL,
  PRIMARY KEY (case_id, trigger_id));
`);
  return db;
}
