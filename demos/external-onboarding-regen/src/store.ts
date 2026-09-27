// The constituents' stores and the substrate's; the composition stores nothing
// (Composition state 1).
import { Database } from "@db/sqlite";

export function openStore(): Database {
  const db = new Database(":memory:");
  db.exec(`
CREATE TABLE actor (actor_ref TEXT PRIMARY KEY, secret TEXT NOT NULL);
CREATE TABLE attestation (attestation_id TEXT PRIMARY KEY, action_ref TEXT NOT NULL, actor_ref TEXT NOT NULL, proof TEXT NOT NULL, attested_at TEXT NOT NULL);
CREATE TABLE event (seq INTEGER PRIMARY KEY AUTOINCREMENT, event_id TEXT NOT NULL UNIQUE, recorded_at TEXT NOT NULL, data TEXT);
CREATE TABLE retention (retention_id TEXT PRIMARY KEY, record_ref TEXT NOT NULL, policy_ref TEXT NOT NULL, retained_at TEXT NOT NULL,
  retention_deadline TEXT NOT NULL, purge_deadline TEXT NOT NULL, state TEXT NOT NULL, purged_at TEXT);
CREATE TABLE at_event_attestation (event_id TEXT PRIMARY KEY, attestation_id TEXT NOT NULL);
CREATE TABLE at_event_retention (event_id TEXT PRIMARY KEY, retention_id TEXT NOT NULL);
CREATE TABLE at_event_seq (event_id TEXT PRIMARY KEY, seq INTEGER NOT NULL);
CREATE TABLE at_destruction (event_id TEXT PRIMARY KEY, attestation_id TEXT NOT NULL);
CREATE TABLE invitation (invitation_token TEXT PRIMARY KEY, inviter_ref TEXT NOT NULL, invitee_ref TEXT, context TEXT NOT NULL,
  initiated_at TEXT NOT NULL, expires_at TEXT NOT NULL, status TEXT NOT NULL CHECK (status IN ('pending','accepted','declined','revoked')),
  accepting_identity_ref TEXT, accepted_at TEXT, declined_at TEXT, revoked_by_ref TEXT, revocation_reason TEXT, revoked_at TEXT);
CREATE TABLE party (party_id TEXT PRIMARY KEY, name TEXT NOT NULL, date_of_birth TEXT NOT NULL, document_type TEXT NOT NULL,
  document_ref TEXT NOT NULL, enrolling_actor_ref TEXT NOT NULL, enrolled_at TEXT NOT NULL, state TEXT NOT NULL, ord INTEGER NOT NULL);
CREATE TABLE credential (credential_id TEXT PRIMARY KEY, principal_ref TEXT NOT NULL, credential_type TEXT NOT NULL, verifier TEXT NOT NULL,
  registered_at TEXT NOT NULL, expires_at TEXT, status TEXT NOT NULL, successor_id TEXT, ended_at TEXT);
`);
  return db;
}
