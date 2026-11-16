// The stack answers: Bun reaches XTDB over its Postgres wire port, a write is read back,
// and an earlier version of a record is still there to read (Execution Contract Database 5).
import { test, expect, afterAll } from "bun:test";
import postgres from "postgres";

const sql = postgres({ host: "127.0.0.1", port: 5432, database: "xtdb", fetch_types: false, prepare: false });
afterAll(() => sql.end());

test("a write is read back, and the earlier version of a record is kept", async () => {
  const id = `stack-${crypto.randomUUID()}`;
  await sql`INSERT INTO stack_probe RECORDS {_id: ${sql.typed(id, 25)}, v: 1}`;
  await sql`INSERT INTO stack_probe RECORDS {_id: ${sql.typed(id, 25)}, v: 2}`;
  const now = await sql`SELECT v FROM stack_probe WHERE _id = ${id}`;
  expect(now.map((r) => Number(r.v))).toEqual([2]);
  const all = await sql`SELECT v FROM stack_probe FOR ALL VALID_TIME WHERE _id = ${id} ORDER BY _valid_from`;
  expect(all.map((r) => Number(r.v))).toEqual([1, 2]);
});
