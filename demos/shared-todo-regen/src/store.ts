// One SQLite database holds the three constituents' stores. The composition
// stores nothing of its own (Composition state 1).
import { Database } from "@db/sqlite";

export const SCHEMA = `
-- Personal Todo: a deleted unit is not held (State 10)
CREATE TABLE unit (id TEXT PRIMARY KEY, description TEXT NOT NULL, state TEXT NOT NULL CHECK (state IN ('pending','done')),
  added_at TEXT NOT NULL, edited_at TEXT, completed_at TEXT);
-- Permissions: a grant is never removed
CREATE TABLE grant_record (grant_id TEXT PRIMARY KEY, subject_ref TEXT NOT NULL, action_scope TEXT NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('active','revoked')), granted_at TEXT NOT NULL, revoked_at TEXT);
CREATE TRIGGER grant_no_delete BEFORE DELETE ON grant_record BEGIN SELECT RAISE(ABORT,'a grant is never removed'); END;
-- Assignment: an assignment is never removed (State 10)
CREATE TABLE assignment (assignment_id TEXT PRIMARY KEY, task_ref TEXT NOT NULL, assignee_ref TEXT NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('active','recalled','transferred')), assigned_at TEXT NOT NULL, ended_at TEXT);
CREATE TRIGGER assignment_no_delete BEFORE DELETE ON assignment BEGIN SELECT RAISE(ABORT,'an assignment is never removed'); END;
`;

export function openStore(path = ":memory:"): Database {
  const db = new Database(path);
  db.exec(SCHEMA);
  return db;
}
