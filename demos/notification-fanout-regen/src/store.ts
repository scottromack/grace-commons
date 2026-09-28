// The two constituent stores. The composition keeps none of its own
// (Composition state 1, 2).
import { Database } from "@db/sqlite";
export function openStore(): Database {
  const db = new Database(":memory:");
  db.exec(`
CREATE TABLE subscription (subscription_id TEXT PRIMARY KEY, subscriber_ref TEXT NOT NULL, event_scope TEXT NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('active','cancelled')), subscribed_at TEXT NOT NULL, cancelled_at TEXT);
CREATE TABLE notification (notification_id TEXT PRIMARY KEY, recipient_ref TEXT NOT NULL, payload TEXT NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('pending','delivered','failed','expired')), created_at TEXT NOT NULL, terminal_at TEXT);
`);
  return db;
}
