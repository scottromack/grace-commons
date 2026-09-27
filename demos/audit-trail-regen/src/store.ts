// Every store: the four constituents, and the composition's own elements —
// the insert-only derived maps and the extraction-pending records the cascade
// writes (Composition state; Durability 6).
import { Database } from "@db/sqlite";

export function openStore(): Database {
  const db = new Database(":memory:");
  db.exec(`
-- Actor Identity: the proof is stored through the vault.
CREATE TABLE actor (actor_ref TEXT PRIMARY KEY, secret TEXT NOT NULL);
CREATE TABLE attestation (attestation_id TEXT PRIMARY KEY, action_ref TEXT NOT NULL, actor_ref TEXT NOT NULL, proof TEXT NOT NULL, attested_at TEXT NOT NULL);
CREATE TRIGGER attestation_no_update BEFORE UPDATE ON attestation BEGIN SELECT RAISE(ABORT,'an attestation never changes'); END;
CREATE TRIGGER attestation_no_delete BEFORE DELETE ON attestation BEGIN SELECT RAISE(ABORT,'an attestation is never deleted'); END;
-- Event Log: the data field is stored through the vault.
CREATE TABLE event (seq INTEGER PRIMARY KEY AUTOINCREMENT, event_id TEXT NOT NULL UNIQUE, recorded_at TEXT NOT NULL, data TEXT NOT NULL);
CREATE TRIGGER event_no_update BEFORE UPDATE ON event BEGIN SELECT RAISE(ABORT,'an event never changes'); END;
CREATE TRIGGER event_no_delete BEFORE DELETE ON event BEGIN SELECT RAISE(ABORT,'an event is never removed'); END;
-- Retention Window
CREATE TABLE retention (retention_id TEXT PRIMARY KEY, record_ref TEXT NOT NULL, policy_ref TEXT NOT NULL, retained_at TEXT NOT NULL,
  retention_deadline TEXT NOT NULL, purge_deadline TEXT NOT NULL, state TEXT NOT NULL CHECK (state IN ('retained','purged')), purged_at TEXT);
-- Tamper Evidence
CREATE TABLE evidence (evidence_id TEXT PRIMARY KEY, record_set_ref TEXT NOT NULL, proof TEXT NOT NULL, sealed_at TEXT NOT NULL, anchored_at TEXT);
CREATE TRIGGER evidence_no_update BEFORE UPDATE ON evidence BEGIN SELECT RAISE(ABORT,'an evidence never changes'); END;
-- The composition's derived indexes (insert-only).
CREATE TABLE event_to_attestation (event_id TEXT PRIMARY KEY, attestation_id TEXT NOT NULL);
CREATE TABLE event_to_retention (event_id TEXT PRIMARY KEY, retention_id TEXT NOT NULL);
CREATE TABLE event_to_sequence (event_id TEXT PRIMARY KEY, seq INTEGER NOT NULL);
CREATE TABLE seal_coverage (evidence_id TEXT PRIMARY KEY, first_seq INTEGER NOT NULL, last_seq INTEGER NOT NULL);
-- The composition's extraction-pending records (durable, never rebuilt).
CREATE TABLE purged_events (evidence_id TEXT NOT NULL, seq INTEGER NOT NULL, PRIMARY KEY (evidence_id, seq));
CREATE TABLE destruction_record (event_id TEXT PRIMARY KEY, attestation_id TEXT NOT NULL, seq INTEGER NOT NULL);
CREATE TABLE erasure_outcome (n INTEGER PRIMARY KEY AUTOINCREMENT, event_id TEXT NOT NULL, outcome TEXT NOT NULL, reason TEXT, recorded_at TEXT NOT NULL);
CREATE TRIGGER e2a_no_update BEFORE UPDATE ON event_to_attestation BEGIN SELECT RAISE(ABORT,'insert-only'); END;
CREATE TRIGGER e2r_no_update BEFORE UPDATE ON event_to_retention BEGIN SELECT RAISE(ABORT,'insert-only'); END;
CREATE TRIGGER e2s_no_update BEFORE UPDATE ON event_to_sequence BEGIN SELECT RAISE(ABORT,'insert-only'); END;
CREATE TRIGGER cov_no_update BEFORE UPDATE ON seal_coverage BEGIN SELECT RAISE(ABORT,'insert-only'); END;
CREATE TRIGGER dr_no_update BEFORE UPDATE ON destruction_record BEGIN SELECT RAISE(ABORT,'insert-only'); END;
`);
  return db;
}
