// One SQLite database holds every store: the four constituents, the atoms Audit
// Trail reaches, and the composition's five records. Each module writes only
// its own tables; the composition reaches the transitive atoms only through
// Audit Trail (Composes 7).
import { Database } from "@db/sqlite";

export const SCHEMA = `
-- Actor Identity
CREATE TABLE actor (actor_ref TEXT PRIMARY KEY, secret TEXT NOT NULL);
CREATE TABLE attestation (attestation_id TEXT PRIMARY KEY, action_ref TEXT NOT NULL, actor_ref TEXT NOT NULL,
  proof TEXT NOT NULL, attested_at TEXT NOT NULL);
CREATE TRIGGER attestation_immutable BEFORE UPDATE ON attestation BEGIN SELECT RAISE(ABORT,'attestation is immutable'); END;
-- Event Log
CREATE TABLE event (seq INTEGER PRIMARY KEY AUTOINCREMENT, event_id TEXT NOT NULL UNIQUE, recorded_at TEXT NOT NULL, data TEXT);
-- Retention Window
CREATE TABLE retention (retention_id TEXT PRIMARY KEY, record_ref TEXT NOT NULL, policy_ref TEXT NOT NULL,
  retained_at TEXT NOT NULL, retention_deadline TEXT NOT NULL, purge_deadline TEXT NOT NULL,
  state TEXT NOT NULL CHECK (state IN ('retained','purged')), purged_at TEXT);
-- Audit Trail's derived indexes and destruction pairs
CREATE TABLE at_event_attestation (event_id TEXT PRIMARY KEY, attestation_id TEXT NOT NULL);
CREATE TABLE at_event_retention (event_id TEXT PRIMARY KEY, retention_id TEXT NOT NULL);
CREATE TABLE at_event_seq (event_id TEXT PRIMARY KEY, seq INTEGER NOT NULL);
CREATE TABLE at_destruction (event_id TEXT PRIMARY KEY, attestation_id TEXT NOT NULL);
-- Permissions
CREATE TABLE grant_record (grant_id TEXT PRIMARY KEY, subject_ref TEXT NOT NULL, action_scope TEXT NOT NULL,
  status TEXT NOT NULL, granted_at TEXT NOT NULL, revoked_at TEXT);
-- Approval Step
CREATE TABLE step (step_id TEXT PRIMARY KEY, subject_ref TEXT NOT NULL, approver_ref TEXT NOT NULL,
  submitter_ref TEXT NOT NULL, scope TEXT NOT NULL, submitted_at TEXT NOT NULL, reason TEXT,
  state TEXT NOT NULL CHECK (state IN ('pending','approved','rejected','withdrawn')),
  decided_by TEXT, decision_reason TEXT, decided_at TEXT, withdrawn_by TEXT, withdrawal_reason TEXT, withdrawn_at TEXT);
-- Assignment
CREATE TABLE assignment (assignment_id TEXT PRIMARY KEY, task_ref TEXT NOT NULL, assignee_ref TEXT NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('active','recalled','transferred')), assigned_at TEXT NOT NULL, ended_at TEXT);
-- Multi-Party Approval: the chain store and the four indexes (Composition state 1)
CREATE TABLE chain (chain_id TEXT PRIMARY KEY, subject_ref TEXT NOT NULL, scope TEXT NOT NULL,
  initiator_ref TEXT NOT NULL, approver_set TEXT NOT NULL, quorum_rule TEXT NOT NULL,
  initiated_at TEXT NOT NULL, invocation_id TEXT NOT NULL,
  state TEXT NOT NULL CHECK (state IN ('Pending','Approved','Rejected','Withdrawn')),
  terminal_at TEXT, audit_pending INTEGER NOT NULL DEFAULT 0, landed_ids TEXT NOT NULL DEFAULT '{"steps":[],"assignments":[]}');
CREATE TABLE chain_step (chain_id TEXT NOT NULL, pos INTEGER NOT NULL, step_id TEXT NOT NULL, PRIMARY KEY (chain_id, pos));
CREATE TABLE step_chain (step_id TEXT PRIMARY KEY, chain_id TEXT NOT NULL);
CREATE TABLE step_assignment (step_id TEXT PRIMARY KEY, assignment_id TEXT NOT NULL);
CREATE TABLE event_index (chain_id TEXT NOT NULL, ord INTEGER NOT NULL, event_id TEXT NOT NULL, step_id TEXT,
  PRIMARY KEY (chain_id, ord));
-- Composition state 8 and Invariant 7 and 8: no chain record is removed; a terminal chain
-- keeps its state and terminal instant; declared fields never change.
CREATE TRIGGER chain_no_delete BEFORE DELETE ON chain BEGIN SELECT RAISE(ABORT,'a chain record is never removed'); END;
CREATE TRIGGER chain_terminal_absorbing BEFORE UPDATE OF state, terminal_at ON chain
  WHEN OLD.state <> 'Pending' BEGIN SELECT RAISE(ABORT,'a terminal chain does not change'); END;
CREATE TRIGGER chain_declared_immutable BEFORE UPDATE OF chain_id, subject_ref, scope, initiator_ref, approver_set,
  quorum_rule, initiated_at, invocation_id ON chain BEGIN SELECT RAISE(ABORT,'declared fields are immutable'); END;
`;

export function openStore(path = ":memory:"): Database {
  const db = new Database(path);
  db.exec(SCHEMA);
  return db;
}
