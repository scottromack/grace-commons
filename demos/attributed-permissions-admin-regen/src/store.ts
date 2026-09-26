// One SQLite database holds both constituents' stores and the composition's
// three records. The attribution maps sit in the Permissions instance's store
// (Capability requirement 22), so one transaction can enclose a Permissions
// write and its pairing entry (Capability requirement 23). The attestation
// store is separate in meaning: an attest commits on its own, never inside
// the grant's transaction (Wiring decision 3).
import { Database } from "@db/sqlite";

export const SCHEMA = `
CREATE TABLE actor (actor_ref TEXT PRIMARY KEY, secret TEXT NOT NULL);
CREATE TABLE attestation (
  attestation_id TEXT PRIMARY KEY, action_ref TEXT NOT NULL, actor_ref TEXT NOT NULL,
  proof TEXT NOT NULL, attested_at TEXT NOT NULL);
CREATE TABLE grant_record (
  grant_id TEXT PRIMARY KEY, subject_ref TEXT NOT NULL, action_scope TEXT NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('active','revoked')),
  granted_at TEXT NOT NULL, revoked_at TEXT);
CREATE TABLE grant_attribution (grant_id TEXT PRIMARY KEY, attestation_id TEXT NOT NULL UNIQUE);
CREATE TABLE revocation_attribution (grant_id TEXT PRIMARY KEY, attestation_id TEXT NOT NULL UNIQUE);
CREATE TABLE orphan_log (
  attestation_id TEXT PRIMARY KEY, proposal TEXT NOT NULL, requested_at TEXT NOT NULL,
  reason TEXT NOT NULL, grant_id TEXT);
CREATE TABLE purge_record (attestation_id TEXT PRIMARY KEY);
-- Composition state 14 through 17 and Invariant 6 and 8: written once, never changed or dropped.
CREATE TRIGGER ga_no_update BEFORE UPDATE ON grant_attribution BEGIN SELECT RAISE(ABORT,'attribution entry is write-once'); END;
CREATE TRIGGER ga_no_delete BEFORE DELETE ON grant_attribution BEGIN SELECT RAISE(ABORT,'attribution entry is write-once'); END;
CREATE TRIGGER ra_no_update BEFORE UPDATE ON revocation_attribution BEGIN SELECT RAISE(ABORT,'attribution entry is write-once'); END;
CREATE TRIGGER ra_no_delete BEFORE DELETE ON revocation_attribution BEGIN SELECT RAISE(ABORT,'attribution entry is write-once'); END;
CREATE TRIGGER ol_no_update BEFORE UPDATE ON orphan_log BEGIN SELECT RAISE(ABORT,'orphan log entry is write-once'); END;
CREATE TRIGGER ol_no_delete BEFORE DELETE ON orphan_log BEGIN SELECT RAISE(ABORT,'orphan log entry is write-once'); END;
-- Actor Identity Invariant 1.1 and 4.2: a recorded attestation never changes. Deletion is
-- left to the composing retention layer (Actor Identity Composition note 4), which the
-- tests stand in for when they purge.
CREATE TRIGGER at_no_update BEFORE UPDATE ON attestation BEGIN SELECT RAISE(ABORT,'attestation is immutable'); END;
-- Invariant 7.3: the two maps' attestations stand disjoint.
CREATE TRIGGER ra_disjoint BEFORE INSERT ON revocation_attribution
  WHEN EXISTS (SELECT 1 FROM grant_attribution WHERE attestation_id = NEW.attestation_id)
  BEGIN SELECT RAISE(ABORT,'attestation already names an issuance'); END;
CREATE TRIGGER ga_disjoint BEFORE INSERT ON grant_attribution
  WHEN EXISTS (SELECT 1 FROM revocation_attribution WHERE attestation_id = NEW.attestation_id)
  BEGIN SELECT RAISE(ABORT,'attestation already names a revocation'); END;
`;

export function openStore(path = ":memory:"): Database {
  const db = new Database(path);
  db.exec(SCHEMA);
  return db;
}

// Fault injection for the failure paths the spec names; a test sets one and
// the next matching write refuses.
export interface Faults {
  attestStorage?: boolean;
  grantStorage?: boolean;
  revokeStorage?: boolean;
  pairingWrite?: boolean;
  // A host that does not honour the pairing write atomicity: the constituent
  // write commits on its own and the pairing then fails. This is the partial
  // Invariant 1.3 and 2.3 name, and the only way to reach a post- position.
  nonAtomicHost?: boolean;
}
