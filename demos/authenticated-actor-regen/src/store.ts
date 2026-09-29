// One SQLite database holds both constituents' stores and the composition's
// two records: the principal binding with its strict inverse (Composition
// state 1 through 6) and the attest log (7 through 10). The composition holds
// no constituent's record, only the ids that name one (Composition state 11).
import { Database } from "@db/sqlite";

export const SCHEMA = `
-- Actor Identity: the actor registry's public material and the attestation store
CREATE TABLE actor (actor_ref TEXT PRIMARY KEY, secret TEXT NOT NULL);
CREATE TABLE attestation (attestation_id TEXT PRIMARY KEY, action_ref TEXT NOT NULL, actor_ref TEXT NOT NULL,
  proof TEXT NOT NULL, attested_at TEXT NOT NULL);
CREATE TRIGGER at_no_update BEFORE UPDATE ON attestation BEGIN SELECT RAISE(ABORT,'an attestation is immutable'); END;
-- Credential
CREATE TABLE credential (credential_id TEXT PRIMARY KEY, principal_ref TEXT NOT NULL, credential_type TEXT NOT NULL,
  verifier TEXT NOT NULL, registered_at TEXT NOT NULL, expires_at TEXT,
  status TEXT NOT NULL CHECK (status IN ('active','rotated','revoked')), successor_id TEXT, ended_at TEXT,
  revoked_by_ref TEXT, revocation_reason TEXT);
-- The principal binding and its inverse, unique on both keys (Composition state 4, 5), never changed (6)
CREATE TABLE principal_binding (principal_ref TEXT PRIMARY KEY, actor_ref TEXT NOT NULL UNIQUE,
  credential_type TEXT NOT NULL, credential_id TEXT NOT NULL, bound_at TEXT NOT NULL);
CREATE TABLE actor_binding (actor_ref TEXT PRIMARY KEY, principal_ref TEXT NOT NULL UNIQUE);
CREATE TRIGGER pb_no_update BEFORE UPDATE ON principal_binding BEGIN SELECT RAISE(ABORT,'a binding never changes'); END;
CREATE TRIGGER pb_no_delete BEFORE DELETE ON principal_binding BEGIN SELECT RAISE(ABORT,'a binding never changes'); END;
CREATE TRIGGER ab_no_update BEFORE UPDATE ON actor_binding BEGIN SELECT RAISE(ABORT,'a binding never changes'); END;
CREATE TRIGGER ab_no_delete BEFORE DELETE ON actor_binding BEGIN SELECT RAISE(ABORT,'a binding never changes'); END;
-- The attest log: one entry per call, never changed (Composition state 8, 9)
CREATE TABLE attest_log (entry_id INTEGER PRIMARY KEY AUTOINCREMENT, attempted_at TEXT NOT NULL, principal_ref TEXT NOT NULL,
  action_ref TEXT NOT NULL, outcome TEXT NOT NULL, observed_status TEXT, credential_id TEXT, attestation_id TEXT);
CREATE TRIGGER log_no_update BEFORE UPDATE ON attest_log BEGIN SELECT RAISE(ABORT,'the attest log is append-only'); END;
CREATE TRIGGER log_no_delete BEFORE DELETE ON attest_log BEGIN SELECT RAISE(ABORT,'the attest log is append-only'); END;
`;

export function openStore(path = ":memory:"): Database {
  const db = new Database(path);
  db.exec(SCHEMA);
  return db;
}
