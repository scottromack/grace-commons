// One SQLite database holds every store: Credential, Session, the atoms Audit
// Trail reaches, and Login's two maps and its login event log. The composition
// holds no instance of what Audit Trail reaches (Composes 7); the tables share a
// file, not an owner.
import { Database } from "@db/sqlite";

export const SCHEMA = `
CREATE TABLE actor (actor_ref TEXT PRIMARY KEY, secret TEXT NOT NULL);
CREATE TABLE attestation (attestation_id TEXT PRIMARY KEY, action_ref TEXT NOT NULL, actor_ref TEXT NOT NULL,
  proof TEXT NOT NULL, attested_at TEXT NOT NULL);
CREATE TABLE event (seq INTEGER PRIMARY KEY AUTOINCREMENT, event_id TEXT NOT NULL UNIQUE, recorded_at TEXT NOT NULL, data TEXT);
CREATE TABLE retention (retention_id TEXT PRIMARY KEY, record_ref TEXT NOT NULL, policy_ref TEXT NOT NULL,
  retained_at TEXT NOT NULL, retention_deadline TEXT NOT NULL, purge_deadline TEXT NOT NULL, state TEXT NOT NULL, purged_at TEXT);
CREATE TABLE at_event_attestation (event_id TEXT PRIMARY KEY, attestation_id TEXT NOT NULL);
CREATE TABLE at_event_retention (event_id TEXT PRIMARY KEY, retention_id TEXT NOT NULL);
CREATE TABLE at_event_seq (event_id TEXT PRIMARY KEY, seq INTEGER NOT NULL);
CREATE TABLE at_destruction (event_id TEXT PRIMARY KEY, attestation_id TEXT NOT NULL);
-- Credential
CREATE TABLE credential (credential_id TEXT PRIMARY KEY, principal_ref TEXT NOT NULL, credential_type TEXT NOT NULL,
  verifier TEXT NOT NULL, registered_at TEXT NOT NULL, expires_at TEXT,
  status TEXT NOT NULL CHECK (status IN ('active','rotated','revoked')), successor_id TEXT, ended_at TEXT,
  revoked_by_ref TEXT, revocation_reason TEXT);
-- Session
CREATE TABLE session (session_token TEXT PRIMARY KEY, principal_ref TEXT NOT NULL, issued_by_ref TEXT NOT NULL,
  issued_at TEXT NOT NULL, expires_at TEXT NOT NULL, status TEXT NOT NULL CHECK (status IN ('active','revoked')),
  revoked_at TEXT, revoked_by_ref TEXT, revocation_reason TEXT);
-- Login: the two maps (Composition state 1 through 6) and the login event log (9 through 12)
CREATE TABLE credential_to_sessions (credential_id TEXT NOT NULL, session_token TEXT NOT NULL, PRIMARY KEY (credential_id, session_token));
CREATE TABLE session_to_credential (session_token TEXT PRIMARY KEY, credential_id TEXT NOT NULL);
CREATE TRIGGER c2s_no_delete BEFORE DELETE ON credential_to_sessions BEGIN SELECT RAISE(ABORT,'a map entry is never removed'); END;
CREATE TRIGGER s2c_no_update BEFORE UPDATE ON session_to_credential BEGIN SELECT RAISE(ABORT,'a map entry never changes'); END;
CREATE TRIGGER s2c_no_delete BEFORE DELETE ON session_to_credential BEGIN SELECT RAISE(ABORT,'a map entry is never removed'); END;
CREATE TABLE login_event_log (entry_id INTEGER PRIMARY KEY AUTOINCREMENT, attempted_at TEXT NOT NULL, principal_ref TEXT NOT NULL,
  credential_type TEXT NOT NULL, issued_by_ref TEXT NOT NULL, outcome TEXT NOT NULL, reason TEXT, stage TEXT,
  credential_id TEXT, session_token TEXT);
CREATE TRIGGER log_no_update BEFORE UPDATE ON login_event_log BEGIN SELECT RAISE(ABORT,'the login event log is append-only'); END;
CREATE TRIGGER log_no_delete BEFORE DELETE ON login_event_log BEGIN SELECT RAISE(ABORT,'the login event log is append-only'); END;
`;

export function openStore(path = ":memory:"): Database {
  const db = new Database(path);
  db.exec(SCHEMA);
  return db;
}
