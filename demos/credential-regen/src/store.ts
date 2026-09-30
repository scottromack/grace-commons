// One credential store instance. Triggers hold what the page forbids the store
// to lose: no removal (State 13, 15; Invariant 10.1), no changed property
// (Invariant 1.1), a terminal field written once (Invariant 1.2), a stored
// terminal absorbing (Invariant 5.1). There is no column for material, for an
// expired status or for a lapse instant (State 6, 7, 9, 10).
import { Database } from "@db/sqlite";

export const SCHEMA = `
CREATE TABLE credential (credential_id TEXT PRIMARY KEY, principal_ref TEXT NOT NULL, credential_type TEXT NOT NULL,
  verifier TEXT NOT NULL, registered_at TEXT NOT NULL, expires_at TEXT,
  status TEXT NOT NULL CHECK (status IN ('active','rotated','revoked')),
  rotated_at TEXT, successor_credential_id TEXT, revoked_at TEXT, revoked_by_ref TEXT, revocation_reason TEXT);
CREATE TRIGGER no_remove BEFORE DELETE ON credential BEGIN SELECT RAISE(ABORT,'a credential is never removed'); END;
CREATE TRIGGER no_property_change BEFORE UPDATE OF credential_id, principal_ref, credential_type, verifier, registered_at, expires_at ON credential
  BEGIN SELECT RAISE(ABORT,'a property never changes'); END;
CREATE TRIGGER terminal_absorbs BEFORE UPDATE ON credential WHEN OLD.status <> 'active'
  BEGIN SELECT RAISE(ABORT,'a stored terminal is absorbing'); END;
`;

export function openStore(path = ":memory:"): Database {
  const db = new Database(path);
  db.exec(SCHEMA);
  return db;
}
