// Event Log — an append-only record: what is written stays in the order it arrived.
// Rendered from atoms/event-log.md (the page at the commit the entry names), with no code of any
// other render opened. A rule's label is in the comment where the code answers it.
//
// One table, `events`, holds every log instance; an event's log_name tells the instances apart
// (Identity 10: a composing pattern owns how many there are, and each serves one composition alone).
// An event is one record under its event id and is never written again (Invariant 2.1, State 8, 9).
// The sequence number is the log's order. Next sequence number (State 4) is the highest landed plus
// one; a fresh instance begins at one (State 5). The guard that keeps the order total is an ASSERT
// in the append's own transaction (Database 2): an append that finds another landed first is refused
// whole and plans again from what landed, so no two events share a number (Invariant 3.1) and none
// lands below one already landed (Invariant 4.1).
import { Store, Guard, type Row, type Stmt } from "./store.ts";
import { type Seam } from "./seam.ts";
import { canonical } from "./canonical.ts";

export interface LoggedEvent {
  event_id: string;
  sequence_number: number;
  recorded_at: string;
  data: unknown;
}

/** A range holds both its ends, an end being a value of the axis; a missing upper end holds everything above (Term query). */
export interface Query {
  sequence?: { from: number; to?: number };
  time?: { from: string; to?: string };
}

export interface EventLogConfig {
  /** The log's name (State 3). */
  name: string;
  /** The per-instance bound on the bytes of data (Term payload cap); 65,536 where none is declared. */
  payloadCap?: number;
}

type Stored = Row & { _id: string; log_name: string; seq: number | string; recorded_at: string; data: string };

const T = "events";
const COLUMNS = ["log_name", "seq", "recorded_at", "data"];
const DEFAULT_CAP = 65_536;

export interface AppendPlan {
  event_ids: string[];
  sequence_numbers: number[];
  stmts: Stmt[];
}

export class EventLog {
  private constructor(private store: Store, private seam: Seam, private cfg: Required<EventLogConfig>) {}

  static async open(store: Store, seam: Seam, cfg: EventLogConfig): Promise<EventLog> {
    await store.declare(T, COLUMNS);
    return new EventLog(store, seam, { name: cfg.name, payloadCap: cfg.payloadCap ?? DEFAULT_CAP });
  }

  /** The payload cap in force, in bytes (Term payload cap). */
  get payloadCap(): number {
    return this.cfg.payloadCap;
  }

  /** Highest sequence number landed in this log, 0 for a fresh instance (State 5). */
  private async top(): Promise<number> {
    const r = await this.store.read<Row>(`SELECT MAX(seq) AS top FROM ${T} WHERE log_name = $1`, [this.cfg.name]);
    return r[0]?.top == null ? 0 : Number(r[0].top);
  }

  /**
   * The statements that land these events in order, to commit alone or beside the other writes of one
   * action (Database 1), and the ids and numbers they carry. Refuses data over the cap (Operation 5).
   * The first statement is the guard: nothing has landed in this log since the plan read it.
   */
  async plan(datas: unknown[]): Promise<AppendPlan | { refused: "invalid-payload" }> {
    const texts = datas.map((d) => canonical(d ?? null));
    if (texts.some((t) => new TextEncoder().encode(t).length > this.cfg.payloadCap)) return { refused: "invalid-payload" }; // Operation 5; Operation 6: empty data is accepted
    const top = await this.top();
    const now = this.seam.now();                                                                               // Operation 2
    const ids = texts.map(() => this.seam.idMaterial());                                                       // Identity 2
    const seqs = texts.map((_, i) => top + 1 + i);                                                             // Operation 3, State 6
    const stmts: Stmt[] = [this.store.assertNone(T, "log_name = $1 AND seq > $2", [this.cfg.name, top], "log-moved")];
    texts.forEach((data, i) => stmts.push(this.store.put(T, { _id: ids[i], log_name: this.cfg.name, seq: seqs[i], recorded_at: now, data })));
    return { event_ids: ids, sequence_numbers: seqs, stmts };
  }

  async append(data: unknown): Promise<{ event_id: string } | { refused: "invalid-payload" | "storage-failure" }> {
    for (let attempt = 0; attempt < 50; attempt++) {
      const p = await this.plan([data]);
      if ("refused" in p) return p;
      try {
        await this.store.commit(p.stmts);
        return { event_id: p.event_ids[0] };                                                                   // Operation 4
      } catch (e) {
        if (e instanceof Guard) continue;                                                                      // another event landed first: plan again
        return { refused: "storage-failure" };                                                                 // Operation 9, 10: nothing landed
      }
    }
    return { refused: "storage-failure" };
  }

  /** The events a query matches, by sequence number, rising (Invariant 5.1, 5.2); invalid-query where it is malformed (Operation 15). */
  async read(query: Query): Promise<LoggedEvent[] | { refused: "invalid-query" }> {
    const known = Object.keys(query ?? {}).every((k) => k === "sequence" || k === "time");
    if (!query || !known || (!query.sequence && !query.time)) return { refused: "invalid-query" };             // no range, or more than the ranges
    const conds = ["log_name = $1"];
    const params: (string | number)[] = [this.cfg.name];
    const s = query.sequence;
    if (s) {
      const whole = (n: unknown) => typeof n === "number" && Number.isInteger(n) && n >= 1;                    // an end below one is malformed
      if (!whole(s.from) || (s.to !== undefined && !whole(s.to)) || (s.to !== undefined && s.from > s.to)) return { refused: "invalid-query" };
      params.push(s.from); conds.push(`seq >= $${params.length}`);
      if (s.to !== undefined) { params.push(s.to); conds.push(`seq <= $${params.length}`); }
    }
    const t = query.time;
    if (t) {
      const inst = (v: unknown) => typeof v === "string" && /^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d(\.\d{1,3})?Z$/.test(v) && !Number.isNaN(Date.parse(v));
      if (!inst(t.from) || (t.to !== undefined && !inst(t.to))) return { refused: "invalid-query" };
      const from = new Date(Date.parse(t.from)).toISOString();
      const to = t.to === undefined ? undefined : new Date(Date.parse(t.to)).toISOString();
      if (to !== undefined && from > to) return { refused: "invalid-query" };
      params.push(from); conds.push(`recorded_at >= $${params.length}`);
      if (to !== undefined) { params.push(to); conds.push(`recorded_at <= $${params.length}`); }
    }
    const rows = await this.store.read<Stored>(`SELECT * FROM ${T} WHERE ${conds.join(" AND ")} ORDER BY seq`, params); // Query 4: every filter
    return rows                                                                                                // Operation 16: empty for a well-formed query matching nothing
      .map((e) => ({ event_id: e._id, sequence_number: Number(e.seq), recorded_at: e.recorded_at, data: JSON.parse(e.data) }))
      .sort((a, b) => a.sequence_number - b.sequence_number);
  }
}
