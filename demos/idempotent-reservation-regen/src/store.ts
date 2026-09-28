// The two constituent stores and the composition's token results map
// (Composition state 1 through 3).
import { Database } from "@db/sqlite";
export function openStore(): Database {
  const db = new Database(":memory:");
  db.exec(`
-- Provisional Commitment (State 1 through 11): no commitment is ever removed.
CREATE TABLE commitment (id TEXT PRIMARY KEY, resource TEXT NOT NULL, requester TEXT NOT NULL, placed_at TEXT NOT NULL, expires_at TEXT NOT NULL,
  state TEXT NOT NULL CHECK (state IN ('held','confirmed','released','expired')), terminal_at TEXT);
CREATE TRIGGER commitment_no_delete BEFORE DELETE ON commitment BEGIN SELECT RAISE(ABORT,'a commitment is never removed'); END;
-- Duplicate Prevention: the recorded set.
CREATE TABLE guard (identity TEXT PRIMARY KEY, recorded_at TEXT NOT NULL);
-- The token results map: extraction-pending, durable (Capability requirement 12 through 14).
CREATE TABLE token_results (token TEXT PRIMARY KEY, action_type TEXT NOT NULL, digest TEXT NOT NULL, result TEXT NOT NULL,
  pending_at TEXT NOT NULL, completed_at TEXT, recovered INTEGER NOT NULL DEFAULT 0);
`);
  return db;
}
