// Retention Window — keep a record long enough, and do not keep it longer.
// Rendered from atoms/retention-window.md (the page at the commit the entry names), with no code of any
// other render opened. A rule's label is in the comment where the code answers it.
//
// A retention is one record in `retentions` under its retention id. A purge is a new version of it
// (Execution Contract Database 5), so the placement's earlier version is there to read; the atom never
// removes a retention (Invariant 10.1). Purge eligibility is derived at each read and never written
// (State 7, Invariant 11). The policy registry is the host's: it resolves a policy reference to elapsed
// lengths at the seam of a placement alone (Operation 24, 24a, 26). Where no composing pattern owns the
// destruction, the host gives the statements that remove every version of the record (Operation 13b)
// and the purge writes them in its own transaction (Database 1).
import { Store, Guard, type Row, type Stmt } from "./store.ts";
import { type Seam, isBlank } from "./seam.ts";

/** What the host resolves a policy to: elapsed lengths in milliseconds; NaN or non-finite is degenerate (Term degenerate duration). */
export interface Policy { durationMs: number; maxPurgeDelayMs: number }
export type PolicyAnswer = { answer: "policy"; policy: Policy } | { answer: "not-found" } | { answer: "unreachable" };
export type PolicyRegistry = (policy_ref: string) => Promise<PolicyAnswer> | PolicyAnswer;

export type PlaceRefusal = "invalid-request" | "registry-unavailable" | "policy-not-found" | "invalid-policy" | "storage-failure";
export type PurgeRefusal = "not-known" | "not-retained" | "retention-period-not-elapsed" | "storage-failure";

export interface RetentionConfig {
  /** The time resolution in milliseconds, measured from the epoch (Capability requirement 5, Term time resolution). */
  resolutionMs: number;
  /**
   * Where no composing pattern owns the destruction (Operation 13b): the statements that remove every
   * version of the record a record reference names. Absent: a composing pattern owns it, and a purge
   * leaves the record standing until that pattern confirms the destruction.
   */
  destroy?: (record_ref: string) => Stmt[];
}

export interface RetentionView {
  retention_id: string;
  record_ref: string;
  policy_ref: string;
  retained_at: string;
  retention_until: string;
  purge_deadline: string;
  state: "retained" | "purged";
  purged_at: string | null;
  /** Derived at the read; present while retained (Operation 31, Term purge eligible). */
  purge_eligible: "yes" | "no" | null;
}

type Stored = Row & {
  _id: string; record_ref: string; policy_ref: string; retained_at: string; retention_until: string;
  purge_deadline: string; state: "retained" | "purged"; purged_at: string | null;
};

const T = "retentions";
const COLUMNS = ["record_ref", "policy_ref", "retained_at", "retention_until", "purge_deadline", "state", "purged_at"];
const MAX_INSTANT = Date.UTC(9999, 11, 31, 23, 59, 59, 999);

export class RetentionWindow {
  private constructor(private store: Store, private seam: Seam, private registry: PolicyRegistry, private cfg: RetentionConfig) {}

  static async open(store: Store, seam: Seam, registry: PolicyRegistry, cfg: RetentionConfig): Promise<RetentionWindow> {
    if (!(cfg.resolutionMs >= 1)) throw new Error("the time resolution must be at least one millisecond");
    await store.declare(T, COLUMNS);
    return new RetentionWindow(store, seam, registry, cfg);
  }

  private up(ms: number): number {
    return Math.ceil(ms / this.cfg.resolutionMs) * this.cfg.resolutionMs;                                     // State 4a, 6a, Operation 13a
  }

  /** The statements that record one retention, or the refusal, to commit alone (`place`) or beside an action's other writes. */
  async plan(record_ref: string, policy_ref: string): Promise<{ retention_id: string; stmts: Stmt[] } | { refused: PlaceRefusal }> {
    if (isBlank(record_ref) || isBlank(policy_ref)) return { refused: "invalid-request" };                    // Operation 4, 5
    const got = await this.registry(policy_ref);                                                              // Operation 24: resolved at this seam alone
    if (got.answer === "unreachable") return { refused: "registry-unavailable" };                             // Operation 24b
    if (got.answer === "not-found") return { refused: "policy-not-found" };                                   // Operation 6
    const { durationMs, maxPurgeDelayMs } = got.policy;
    if (!Number.isFinite(durationMs) || !(durationMs > 0)) return { refused: "invalid-policy" };              // Operation 7, 7a
    if (!Number.isFinite(maxPurgeDelayMs) || maxPurgeDelayMs < 0) return { refused: "invalid-policy" };       // Operation 8, 8b
    const at = this.up(Date.parse(this.seam.now()));                                                          // State 4, 4a
    const until = this.up(at + durationMs);                                                                   // State 5, 6a
    const deadline = this.up(until + maxPurgeDelayMs);                                                        // State 6, 6a
    if (until > MAX_INSTANT || deadline > MAX_INSTANT) return { refused: "invalid-policy" };                  // Operation 8c
    const id = this.seam.idMaterial();                                                                        // Identity 2
    return {
      retention_id: id,
      stmts: [
        this.store.assertNone(T, "_id = $1", [id], "id-held"),                                                // Invariant 9.1
        this.store.put(T, {
          _id: id, record_ref, policy_ref, retained_at: new Date(at).toISOString(),                           // Operation 1, 2; State 2
          retention_until: new Date(until).toISOString(), purge_deadline: new Date(deadline).toISOString(),
          state: "retained", purged_at: null,
        }),
      ],
    };
  }

  async place(record_ref: string, policy_ref: string): Promise<{ retention_id: string } | { refused: PlaceRefusal }> {
    const p = await this.plan(record_ref, policy_ref);
    if ("refused" in p) return p;
    try {
      await this.store.commit(p.stmts);
    } catch {
      return { refused: "storage-failure" };                                                                  // Operation 9
    }
    return { retention_id: p.retention_id };                                                                  // Operation 3
  }

  async purge(retention_id: string): Promise<"ok" | { refused: PurgeRefusal }> {
    const r = (await this.store.read<Stored>(`SELECT * FROM ${T} WHERE _id = $1`, [retention_id ?? ""]))[0];
    if (!r) return { refused: "not-known" };                                                                  // Operation 14
    if (r.state === "purged") return { refused: "not-retained" };                                             // Operation 15
    const now = this.up(Date.parse(this.seam.now()));                                                         // Operation 21: one now per call; Operation 13a
    if (now < Date.parse(r.retention_until)) return { refused: "retention-period-not-elapsed" };              // Operation 16, 17, Invariant 7.1: writes nothing
    const stmts: Stmt[] = [
      this.store.assertSome(T, "_id = $1 AND state = 'retained'", [r._id], "not-retained"),
      this.store.put(T, { ...r, state: "purged", purged_at: new Date(now).toISOString() }),                   // Operation 12, 13; Invariant 5: nothing else changes
      ...(this.cfg.destroy ? this.cfg.destroy(r.record_ref) : []),                                            // Operation 13b: in the same write
    ];
    try {
      await this.store.commit(stmts);
    } catch (e) {
      if (e instanceof Guard) return { refused: "not-retained" };
      return { refused: "storage-failure" };                                                                  // Operation 19, 20: it stays retained
    }
    return "ok";                                                                                              // Operation 18: a late purge is not refused
  }

  /** Every retention, retained and purged, with its stored fields and, while retained, purge eligible (Operation 29 to 32). */
  async read(): Promise<RetentionView[]> {
    const now = this.up(Date.parse(this.seam.now()));
    const rows = await this.store.read<Stored>(`SELECT * FROM ${T}`);
    return rows
      .sort((a, b) => (a.retained_at < b.retained_at ? -1 : a.retained_at > b.retained_at ? 1 : a._id < b._id ? -1 : 1))
      .map((r) => ({
        retention_id: r._id, record_ref: r.record_ref, policy_ref: r.policy_ref, retained_at: r.retained_at,
        retention_until: r.retention_until, purge_deadline: r.purge_deadline, state: r.state, purged_at: r.purged_at,
        purge_eligible: r.state === "retained" ? (now < Date.parse(r.retention_until) ? "no" : "yes") : null,    // Term purge eligible: derived, never stored
      }));
  }
}
