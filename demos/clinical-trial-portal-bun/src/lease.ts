// Lease — one holder at a time over a key, ended by release or by an instant.
// Rendered from atoms/lease.md (the page at the commit the entry names), with no code of any other render
// opened. A rule's label is in the comment where the code answers it.
//
// The host here is this module over the one store: it holds exactly one lease state per key (State 1) as one
// record under the key, answers every question from the one clock of the seam (Capability requirement 4),
// and holds its grants across a restart because the store does (Capability requirement 5). Free is derived at
// each question from the passed instant and never written (State 2, 3): a lapsed grant is a record nobody
// rewrote. A take, a release and the admission of a waiter are each one write guarded on the version the call
// read, inside its own transaction (Database 2). The line of waiters on a key is kept as records too (State
// 4); a waiter's bound is fixed at its arrival and no admission extends it (Invariant 4.1, 4.2). A host
// restart ends the line: a waiter standing across one is not admitted afterwards (Operation 5c), which the
// store cannot make a promise about for a call that died with the process, so the waiter's own caller gives
// up when its process does.
import { Store, Guard, type Row } from "./store.ts";
import { type Seam } from "./seam.ts";

type Lease = Row & { _id: string; holder: string | null; expires_at: string | null; version: number | string };
type Waiter = Row & { _id: string; key: string; holder: string; n: number | string; bound: string; status: "waiting" | "done" | "gone" };

const L = "leases";
const W = "lease_waiters";
const H = "lease_heads";

export interface LeaseConfig {
  /** Between two looks of a waiting take, in milliseconds. */
  pollMs?: number;
  /** What a waiting take does between two looks; the default is a real wait, a test moves its clock here. */
  sleep?: (ms: number) => Promise<void>;
  /** How long after its bound a waiter still stands while the key is free, in milliseconds (default 2000). */
  staleMs?: number;
  /** Table names (a test world names its own). */
  prefix?: string;
}

export class LeaseHost {
  private readonly L: string; private readonly W: string; private readonly H: string;
  private constructor(private store: Store, private seam: Seam, private cfg: LeaseConfig) {
    const px = cfg.prefix ?? "";
    this.L = px + L; this.W = px + W; this.H = px + H;
  }

  static async open(store: Store, seam: Seam, cfg: LeaseConfig = {}): Promise<LeaseHost> {
    const px = cfg.prefix ?? "";
    await store.declare(px + L, ["holder", "expires_at", "version"]);
    await store.declare(px + W, ["key", "holder", "n", "bound", "status"]);
    await store.declare(px + H, ["next_n"]);
    return new LeaseHost(store, seam, cfg);
  }

  private reading(): string { return this.seam.now(); }                                                       // the host's reading, never a caller's own
  private ms(iso: string): number { return Date.parse(iso); }

  private async state(key: string): Promise<{ lease: Lease | null; free: boolean; at: string }> {
    const at = this.reading();
    const lease = (await this.store.read<Lease>(`SELECT * FROM ${this.L} WHERE _id = $1`, [key]))[0] ?? null;
    return { lease, free: !lease || !lease.holder || at >= (lease.expires_at as string), at };                // State 2: free derived from the passed instant; the instant equal to expires_at reads free
  }

  /**
   * The line of waiters on a key at this reading, in arrival order (Operation 5a). While another holder holds the key a waiter whose
   * bound does not exceed the reading is out of the line (Operation 4, 5b: its take answers unavailable and the host does not carry it
   * forward). While the key is free a waiter whose bound has just passed still stands: it is to be admitted at the first reading the key is
   * free (Operation 2), and it stays in the line for the stale margin after its bound, past which a waiter nobody is waiting for any more
   * (its process is gone) no longer blocks the key.
   */
  private async standing(key: string, free: boolean): Promise<Waiter[]> {
    const at = this.reading();
    const stale = this.cfg.staleMs ?? 2000;
    const all = await this.store.read<Waiter>(`SELECT * FROM ${this.W} WHERE key = $1 AND status = 'waiting'`, [key]);
    return all.filter((w) => (free ? this.ms(at) <= this.ms(w.bound) + stale : at < w.bound)).sort((a, b) => Number(a.n) - Number(b.n));
  }

  private async grant(key: string, holder: string, duration: number, seen: Lease | null, waiterId?: string): Promise<string | null> {
    const at = this.reading();
    const expires_at = new Date(this.ms(at) + duration).toISOString();                                       // Operation 2b: set from the host's reading at the success
    const stmts = [
      seen ? this.store.assertSome(this.L, "_id = $1 AND version = $2", [key, Number(seen.version)], "lease-moved") : this.store.assertNone(this.L, "_id = $1", [key], "lease-moved"),
      this.store.put(this.L, { _id: key, holder, expires_at, version: seen ? Number(seen.version) + 1 : 1 }),   // Operation 2a: the key stands held by the asking holder
      ...(waiterId ? [this.store.put(this.W, { ...(await this.store.read<Waiter>(`SELECT * FROM ${this.W} WHERE _id = $1`, [waiterId]))[0], status: "done" })] : []),
    ];
    try { await this.store.commit(stmts); } catch (e) { if (e instanceof Guard) return null; throw e; }
    return expires_at;
  }

  async tryTake(key: string, holder: string, duration: number): Promise<{ taken: string } | "held"> {
    for (let i = 0; i < 20; i++) {
      const s = await this.state(key);
      if (!s.free || (await this.standing(key, true)).length > 0) return "held";                                    // Operation 6b, 6c: held, or free with a waiter standing
      const e = await this.grant(key, holder, duration, s.lease);                                              // Operation 6a
      if (e) return { taken: e };
    }
    return "held";                                                                                            // another take kept winning: the key is held
  }

  /** Wait for the key; answers expires_at, or unavailable once the waiter's bound has elapsed with another holder on the key (Operation 1 to 5). */
  async take(key: string, holder: string, duration: number): Promise<{ expires_at: string } | "unavailable"> {
    const s0 = await this.state(key);
    if (s0.free && (await this.standing(key, true)).length === 0) {                                                 // Operation 1a: free, no waiter: succeeds at the reading the take arrives at
      const e = await this.grant(key, holder, duration, s0.lease);
      if (e) return { expires_at: e };
    }
    const head = (await this.store.read<Row & { next_n: number | string }>(`SELECT next_n FROM ${this.H} WHERE _id = $1`, [key]))[0];
    const n = head ? Number(head.next_n) : 1;
    const bound = s0.free || !s0.lease ? s0.at : (s0.lease.expires_at as string);                              // Term waiter's bound: the arrival reading plus the arrival term (the holder's remaining term, zero where free)
    const id = `${key}|${n}`;
    try {
      await this.store.commit([
        head ? this.store.assertSome(this.H, "_id = $1 AND next_n = $2", [key, n], "head-moved") : this.store.assertNone(this.H, "_id = $1", [key], "head-moved"),
        this.store.put(this.H, { _id: key, next_n: n + 1 }),
        this.store.put(this.W, { _id: id, key, holder, n, bound, status: "waiting" }),                         // State 4: every waiter with its bound
      ]);
    } catch (e) {
      if (e instanceof Guard) return this.take(key, holder, duration);                                        // another arrival took the number: arrive again
      throw e;
    }
    const sleep = this.cfg.sleep ?? ((ms) => new Promise<void>((r) => setTimeout(r, ms)));
    for (;;) {
      const s = await this.state(key);
      const line = await this.standing(key, s.free);
      if (s.free && line[0]?._id === id) {                                                                    // Operation 2: the first in arrival order, at the first reading the key is free
        const e = await this.grant(key, holder, duration, s.lease, id);
        if (e) return { expires_at: e };
        continue;
      }
      if (!s.free && s.at >= bound) {                                                                         // Operation 4, 5: the bound does not exceed the reading and another holder holds the key
        await this.store.commit([this.store.put(this.W, { _id: id, key, holder, n, bound, status: "gone" })]);
        return "unavailable";                                                                                 // Operation 1b: exactly one of expires_at, unavailable
      }
      await sleep(this.cfg.pollMs ?? 25);
    }
  }

  /** The remaining term of the asking holder, in milliseconds; none for any other party (Operation 8, 9, 10). */
  async remaining(key: string, holder: string): Promise<{ remaining_ms: number } | "none"> {
    const s = await this.state(key);
    if (s.free || !s.lease || s.lease.holder !== holder) return "none";                                       // Invariant 5.1: answered against the pair as the host holds it
    return { remaining_ms: this.ms(s.lease.expires_at as string) - this.ms(s.at) };
  }

  /** Ends the asking holder's grant; not-held for any other party and never a failure (Operation 11 to 14). */
  async release(key: string, holder: string): Promise<"released" | "not-held"> {
    for (let i = 0; i < 20; i++) {
      const s = await this.state(key);
      if (s.free || !s.lease || s.lease.holder !== holder) return "not-held";
      try {
        await this.store.commit([
          this.store.assertSome(this.L, "_id = $1 AND version = $2", [key, Number(s.lease.version)], "lease-moved"),
          this.store.put(this.L, { _id: key, holder: null, expires_at: s.at, version: Number(s.lease.version) + 1 }),   // Invariant 2.1: a grant ends at release or at its instant
        ]);
        return "released";
      } catch (e) { if (!(e instanceof Guard)) throw e; }
    }
    return "not-held";
  }
}
