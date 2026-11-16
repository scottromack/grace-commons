// The database the render keeps its records in: XTDB over its Postgres wire port.
//
// What this module owes the specifications (Execution Contract Database 1 to 5):
//   Database 1  one action's writes commit together or not at all: `commit` runs every
//               statement of one action in one transaction.
//   Database 2  a guard is decided inside the transaction that writes: XTDB refuses a
//               query inside a write transaction, so the guard is an ASSERT statement
//               in the same transaction (`assertNone`, `assertOne`), and a write whose
//               guard no longer holds is refused whole (`Guard`), never half done.
//   Database 5  every record keeps its earlier versions: a change is a new version of
//               the record under the same _id (`put`), and `history` reads them all.
// Instants are ISO 8601 UTC text with milliseconds, so one string order is the time order.
import postgres from "postgres";

export type Value = string | number | boolean | null;
export type Row = Record<string, Value>;
export type Stmt = { text: string; params: Value[] };

/** The database could not serve a read: the action answers state-unavailable and writes nothing (Execution Contract Read 1). */
export class Unavailable extends Error {
  constructor(message = "state-unavailable") {
    super(message);
  }
}

/** A guard that held when the action read, and no longer holds inside the transaction. */
export class Guard extends Error {
  constructor(public readonly guard: string) {
    super(guard);
  }
}

export interface StoreOptions {
  host?: string;
  port?: number;
  database?: string;
}

const NAME = /^[a-z_][a-z0-9_]*$/;
const oidOf = (v: Value): number | null =>
  v === null ? null : typeof v === "string" ? 25 : typeof v === "boolean" ? 16 : Number.isInteger(v) ? 20 : 701;

export class Store {
  readonly sql: postgres.Sql;
  constructor(opts: StoreOptions = {}) {
    this.sql = postgres({
      host: opts.host ?? "127.0.0.1",
      port: opts.port ?? 5432,
      database: opts.database ?? "xtdb",
      fetch_types: false,
      prepare: false,
      onnotice: () => {},
    });
  }

  close(): Promise<void> {
    return this.sql.end();
  }

  /** Read rows. A table no action has written to yet does not exist in XTDB, and reads as empty. */
  async read<T extends Row = Row>(text: string, params: Value[] = []): Promise<T[]> {
    try {
      const rows = await this.sql.unsafe(text, params.map((p) => this.bind(this.sql, p)));
      return rows.map((r) => ({ ...r })) as unknown as T[];
    } catch (e) {
      if (/Table not found/.test((e as Error).message)) return [];
      throw new Unavailable((e as Error).message);
    }
  }

  /**
   * Make a table exist with its columns. XTDB plans a guard or a read only over a table and columns
   * some record has carried, so a table is declared once, before its first action: a record carrying
   * every column is written and withdrawn, and the table keeps the columns. The declaring record's
   * _id is `_schema`; it is never read as a record of the table (every read here names a column).
   */
  async declare(table: string, columns: string[]): Promise<void> {
    this.name(table);
    try {
      await this.sql.unsafe(`SELECT _id FROM ${table} LIMIT 1`);
      return;
    } catch (e) {
      if (!/Table not found/.test((e as Error).message)) throw e;
    }
    const row: Row & { _id: string } = { _id: "_schema" };
    for (const c of columns) row[c] = null;
    await this.commit([this.put(table, row), { text: `DELETE FROM ${table} WHERE _id = $1`, params: ["_schema"] }]);
  }

  /** Every version of a record, oldest first (Database 5). */
  history<T extends Row = Row>(table: string, id: string): Promise<T[]> {
    this.name(table);
    return this.read<T>(`SELECT * FROM ${table} FOR ALL VALID_TIME WHERE _id = $1 ORDER BY _valid_from`, [id]);
  }

  /** One action's statements, committed together (Database 1) or not at all. */
  async commit(stmts: Stmt[]): Promise<void> {
    try {
      await this.sql.begin(async (tx) => {
        for (const s of stmts) await tx.unsafe(s.text, s.params.map((p) => this.bind(tx, p)));
      });
    } catch (e) {
      const g = /guard:([a-z0-9-]+)/.exec((e as Error).message)?.[1];
      if (g) throw new Guard(g);
      throw e;
    }
  }

  /** Write a record, or a new version of it under the same _id. Absent fields are written as null. */
  put(table: string, row: Row & { _id: string }): Stmt {
    this.name(table);
    const keys = Object.keys(row);
    keys.forEach((k) => this.name(k));
    const params: Value[] = [];
    const fields = keys.map((k) => {
      const v = row[k];
      if (v === null) return `${k}: NULL`;
      params.push(v);
      return `${k}: $${params.length}`;
    });
    return { text: `INSERT INTO ${table} RECORDS {${fields.join(", ")}}`, params };
  }

  /** Guard: no record of the table matches (a condition over its columns, `$n` for each param). */
  assertNone(table: string, where: string, params: Value[], guard: string): Stmt {
    this.name(table);
    return { text: `ASSERT NOT EXISTS (SELECT 1 FROM ${table} WHERE ${where}), 'guard:${guard}'`, params };
  }

  /** Guard: at least one record of the table matches. */
  assertSome(table: string, where: string, params: Value[], guard: string): Stmt {
    this.name(table);
    return { text: `ASSERT EXISTS (SELECT 1 FROM ${table} WHERE ${where}), 'guard:${guard}'`, params };
  }

  private name(n: string) {
    if (!NAME.test(n)) throw new Error(`not a table or column name: ${n}`);
  }
  private bind(s: postgres.Sql | postgres.TransactionSql, v: Value) {
    const oid = oidOf(v);
    return oid === null ? null : (s as postgres.Sql).typed(v as never, oid);
  }
}

export const num = (v: Value | undefined): number => Number(v);
