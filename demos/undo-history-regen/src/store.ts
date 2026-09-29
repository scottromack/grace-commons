// Two stores. The event log instance is the composition's sole truth; the
// derived state is Personal Todo's shape, built fresh by every replay in a
// database of its own and never kept (Composes 3, 4; Replay 15 permits a
// cache and this render keeps none).
import { Database } from "@db/sqlite";

export const LOG_SCHEMA = `
CREATE TABLE event (seq INTEGER PRIMARY KEY AUTOINCREMENT, event_id TEXT NOT NULL UNIQUE, recorded_at TEXT NOT NULL, data TEXT);
CREATE TRIGGER event_no_update BEFORE UPDATE ON event BEGIN SELECT RAISE(ABORT,'an event never changes'); END;
CREATE TRIGGER event_no_delete BEFORE DELETE ON event BEGIN SELECT RAISE(ABORT,'an event is never removed'); END;
`;
export const STATE_SCHEMA = `
CREATE TABLE unit (id TEXT PRIMARY KEY, description TEXT NOT NULL, state TEXT NOT NULL CHECK (state IN ('pending','done')),
  added_at TEXT NOT NULL, edited_at TEXT, completed_at TEXT);
`;

export function openLog(path = ":memory:"): Database {
  const db = new Database(path);
  db.exec(LOG_SCHEMA);
  return db;
}
export function freshState(): Database {
  const db = new Database(":memory:");
  db.exec(STATE_SCHEMA);
  return db;
}
