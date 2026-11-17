// Party Identity — a lasting, verifiable identity record for an external party.
// Rendered from atoms/party-identity.md (the page at the commit the entry names), with no code of any other
// render opened. A rule's label is in the comment where the code answers it.
//
// A party is one record under its party id; every action that changes it writes a new version of the record
// (Execution Contract Database 5) carrying the whole of its two lists, the verification events and the state
// changes, in insertion order (the order of the lists is the atom's authority, Term insertion order). The
// guard of a write is an ASSERT on the party's `version` inside the write's own transaction (Database 2): a
// call that finds another landed first reads again and decides again. Enrollments take an ordinal from one
// head record so that parties read back in insertion order. No action removes a party or an event.
import { Store, Guard, type Row, type Stmt } from "./store.ts";
import { type Seam, isBlank } from "./seam.ts";
import { canonical } from "./canonical.ts";

export type PartyState = "unverified" | "verified" | "suspended" | "closed";
export interface VerificationEvent { verification_id: string; verifying_actor_ref: string; verification_method: string; verification_result: "passed" | "failed"; evidence_ref: string; verified_at: string; insertion: number }
export interface StateChangeEvent { state_change_id: string; prior_state: PartyState; new_state: PartyState; acting_ref: string; changed_at: string; reason?: string; insertion: number }
export interface PartyView {
  party_id: string; name: string; date_of_birth: string; document_type: string; document_ref: string; enrolled_at: string; enrolling_actor_ref: string;
  state: PartyState; state_changes: StateChangeEvent[]; verifications: VerificationEvent[];
}
export type PartyRefusal = "invalid-request" | "not-known" | "already-closed" | "not-verifiable" | "already-suspended" | "not-suspended" | "no-passed-verification-since-suspend" | "storage-failure";

type Stored = Row & {
  _id: string; name: string; date_of_birth: string; document_type: string; document_ref: string; enrolled_at: string; enrolling_actor_ref: string;
  state: PartyState; verifications: string; state_changes: string; version: number | string; ordinal: number | string;
};

const T = "parties_identity";            // not `parties`: the portal's own party records are Beacon's
const H = "party_heads";
const COLUMNS = ["name", "date_of_birth", "document_type", "document_ref", "enrolled_at", "enrolling_actor_ref", "state", "verifications", "state_changes", "version", "ordinal"];

export interface PartyConfig { lengthBound?: number; table?: string; headTable?: string }

export class PartyIdentity {
  private readonly T: string;
  private readonly H: string;
  private constructor(private store: Store, private seam: Seam, private cfg: PartyConfig) {
    this.T = cfg.table ?? T;
    this.H = cfg.headTable ?? H;
  }

  static async open(store: Store, seam: Seam, cfg: PartyConfig = {}): Promise<PartyIdentity> {
    await store.declare(cfg.table ?? T, COLUMNS);
    await store.declare(cfg.headTable ?? H, ["next_ordinal"]);
    return new PartyIdentity(store, seam, cfg);
  }

  /** The next insertion number of one party: one count across both lists, which is what insertion order across them means (Term insertion order). */
  private nextInsertion(p: Stored): number {
    const all = [...(JSON.parse(p.verifications) as { insertion: number }[]), ...(JSON.parse(p.state_changes) as { insertion: number }[])];
    return all.reduce((m, e) => Math.max(m, e.insertion), 0) + 1;
  }

  private long(v: string): boolean {
    return [...v].length > (this.cfg.lengthBound ?? 256);                                                      // Capability requirement 7, Execution Contract Input 2
  }
  private bad(v: unknown): boolean {
    return typeof v !== "string" || isBlank(v) || this.long(v);                                                // Operation 1: a required string input blank is invalid-request
  }

  // ---------------------------------------------------------------- enroll

  /** A calendar date in the date form, and not after today in the deployment's clock (Operation 2, 3). */
  private dobOk(dob: string): boolean {
    const m = /^(\d{4})-(\d{2})-(\d{2})$/.exec(dob);
    if (!m) return false;
    const [y, mo, d] = [Number(m[1]), Number(m[2]), Number(m[3])];
    const t = new Date(Date.UTC(y, mo - 1, d));
    if (t.getUTCFullYear() !== y || t.getUTCMonth() !== mo - 1 || t.getUTCDate() !== d) return false;       // Operation 2: no such calendar date
    return !(Date.parse(this.seam.now()) < t.getTime());                                                      // Operation 3: now precedes the date of birth start
  }

  /** The statements that record one party, or the refusal, to commit alone (`enroll`) or beside an action's other writes. */
  async planEnroll(name: string, date_of_birth: string, document_type: string, document_ref: string, enrolling_actor_ref: string): Promise<{ party_id: string; stmts: Stmt[] } | { refused: "invalid-request" }> {
    if ([name, document_type, document_ref, enrolling_actor_ref].some((v) => this.bad(v))) return { refused: "invalid-request" };   // Operation 1
    if (typeof date_of_birth !== "string" || !this.dobOk(date_of_birth)) return { refused: "invalid-request" };                      // Operation 2, 3
    const head = (await this.store.read<Row & { next_ordinal: number | string }>(`SELECT next_ordinal FROM ${this.H} WHERE _id = 'parties'`))[0];
    const ordinal = head ? Number(head.next_ordinal) : 1;
    const id = this.seam.idMaterial();                                                                        // Identity 4: the id comes from the seam
    return {
      party_id: id,
      stmts: [
        head ? this.store.assertSome(this.H, "_id = 'parties' AND next_ordinal = $1", [ordinal], "heads-moved") : this.store.assertNone(this.H, "_id = 'parties'", [], "heads-moved"),
        this.store.put(this.H, { _id: "parties", next_ordinal: ordinal + 1 }),
        this.store.assertNone(this.T, "_id = $1", [id], "id-held"),                                           // Identity 7
        this.store.put(this.T, {
          _id: id, name, date_of_birth, document_type, document_ref, enrolled_at: this.seam.now(), enrolling_actor_ref,     // Operation 5, 6
          state: "unverified", verifications: "[]", state_changes: "[]", version: 1, ordinal,                  // Operation 7
        }),
      ],
    };
  }

  async enroll(name: string, date_of_birth: string, document_type: string, document_ref: string, enrolling_actor_ref: string): Promise<{ party_id: string } | { refused: "invalid-request" | "storage-failure" }> {
    for (let attempt = 0; attempt < 50; attempt++) {
      const p = await this.planEnroll(name, date_of_birth, document_type, document_ref, enrolling_actor_ref);
      if ("refused" in p) return p;
      try {
        await this.store.commit(p.stmts);
        return { party_id: p.party_id };                                                                      // Operation 8
      } catch (e) {
        if (e instanceof Guard && e.guard === "heads-moved") continue;                                        // another enrollment landed first
        return { refused: "storage-failure" };                                                                // Operation 39, 42: nothing was recorded
      }
    }
    return { refused: "storage-failure" };
  }

  // ---------------------------------------------------------------- the party actions

  /** The state check every party action makes before it reads its remaining inputs (Term state check). */
  private async found(party_id: string): Promise<Stored | PartyRefusal> {
    if (isBlank(party_id)) return "invalid-request";                                                           // Operation 10
    const p = (await this.store.read<Stored>(`SELECT * FROM ${this.T} WHERE _id = $1`, [party_id]))[0];
    if (!p) return "not-known";                                                                                // Operation 11, 12
    if (p.state === "closed") return "already-closed";                                                         // Operation 13
    return p;
  }

  /** Write the party's next version with the lists as they now stand, guarded on the version the call read. */
  private async write(p: Stored, patch: { state?: PartyState; verifications?: VerificationEvent[]; state_changes?: StateChangeEvent[] }): Promise<"ok" | PartyRefusal> {
    const next: Stored = {
      ...p, version: Number(p.version) + 1,
      state: patch.state ?? p.state,
      verifications: patch.verifications ? canonical(patch.verifications) : p.verifications,
      state_changes: patch.state_changes ? canonical(patch.state_changes) : p.state_changes,
    };
    try {
      await this.store.commit([this.store.assertSome(this.T, "_id = $1 AND version = $2", [p._id, Number(p.version)], "party-moved"), this.store.put(this.T, next)]);
    } catch (e) {
      if (e instanceof Guard) return "retry" as never;
      return "storage-failure";                                                                                // Operation 39, 41, 43: nothing was written
    }
    return "ok";
  }

  private async act<T>(party_id: string, run: (p: Stored) => Promise<{ answer: T } | { refused: PartyRefusal } | { retry: true }>): Promise<T | { refused: PartyRefusal }> {
    for (let attempt = 0; attempt < 50; attempt++) {
      const p = await this.found(party_id);
      if (typeof p === "string") return { refused: p };
      const r = await run(p);
      if ("retry" in r) continue;                                                                              // another call changed the party first: read again, decide again
      return "refused" in r ? r : r.answer;
    }
    return { refused: "storage-failure" };
  }

  async verify(party_id: string, verifying_actor_ref: string, verification_method: string, verification_result: string, evidence_ref: string): Promise<{ verification_id: string; state_change_id?: string } | { refused: PartyRefusal }> {
    return this.act(party_id, async (p) => {
      if ([verifying_actor_ref, verification_method, evidence_ref].some((v) => this.bad(v))) return { refused: "invalid-request" };       // Operation 1
      if (verification_result !== "passed" && verification_result !== "failed") return { refused: "invalid-request" };                      // Operation 21
      const now = this.seam.now();
      const verification_id = this.seam.idMaterial();
      const ev: VerificationEvent = { verification_id, verifying_actor_ref, verification_method, verification_result, evidence_ref, verified_at: now, insertion: this.nextInsertion(p) };   // Operation 22 to 24
      const verifications = [...(JSON.parse(p.verifications) as VerificationEvent[]), ev];
      let patch: Parameters<PartyIdentity["write"]>[1] = { verifications };
      let state_change_id: string | undefined;
      if (p.state === "unverified" && verification_result === "passed") {                                       // Operation 25, 26: the one transition a verify drives
        state_change_id = this.seam.idMaterial();
        patch = { verifications, state: "verified", state_changes: [...(JSON.parse(p.state_changes) as StateChangeEvent[]), { state_change_id, prior_state: "unverified", new_state: "verified", acting_ref: verifying_actor_ref, changed_at: now, insertion: this.nextInsertion(p) + 1 }] };   // Operation 33, 34, 36: no reason
      }
      const w = await this.write(p, patch);
      if (w === "ok") return { answer: state_change_id ? { verification_id, state_change_id } : { verification_id } };                           // Operation 27, 29, 37
      return w === ("retry" as never) ? { retry: true } : { refused: w };
    });
  }

  private async transition(party_id: string, acting_ref: string, reason: string, to: PartyState, guard: (p: Stored) => PartyRefusal | null): Promise<{ state_change_id: string } | { refused: PartyRefusal }> {
    return this.act(party_id, async (p) => {
      const refused = guard(p);                                                                                 // the state checks first (Operation 14 to 18)
      if (refused) return { refused };
      if (this.bad(acting_ref) || this.bad(reason)) return { refused: "invalid-request" };                      // Operation 1
      const state_change_id = this.seam.idMaterial();
      const ev: StateChangeEvent = { state_change_id, prior_state: p.state, new_state: to, acting_ref, changed_at: this.seam.now(), reason, insertion: this.nextInsertion(p) };   // Operation 33 to 35
      const w = await this.write(p, { state: to, state_changes: [...(JSON.parse(p.state_changes) as StateChangeEvent[]), ev] });                 // Operation 30 to 32
      if (w === "ok") return { answer: { state_change_id } };                                                   // Operation 37
      return w === ("retry" as never) ? { retry: true } : { refused: w };
    });
  }

  suspend(party_id: string, suspending_actor_ref: string, reason: string) {
    return this.transition(party_id, suspending_actor_ref, reason, "suspended", (p) => (p.state === "unverified" ? "not-verifiable" : p.state === "suspended" ? "already-suspended" : null));   // Operation 14, 15
  }

  reinstate(party_id: string, reinstating_actor_ref: string, reason: string) {
    return this.transition(party_id, reinstating_actor_ref, reason, "verified", (p) => {
      if (p.state === "unverified" || p.state === "verified") return "not-suspended";                           // Operation 16
      // Operation 18, Term fresh verification: a passed verification appended after the party's most recent suspend, in insertion order.
      const changes = JSON.parse(p.state_changes) as StateChangeEvent[];
      const lastSuspend = changes.filter((c) => c.new_state === "suspended").reduce((m, c) => Math.max(m, c.insertion), 0);
      const fresh = (JSON.parse(p.verifications) as VerificationEvent[]).some((v) => v.verification_result === "passed" && v.insertion > lastSuspend);
      return fresh ? null : "no-passed-verification-since-suspend";
    });
  }

  close(party_id: string, closing_actor_ref: string, reason: string) {
    return this.transition(party_id, closing_actor_ref, reason, "closed", () => null);
  }

  // ---------------------------------------------------------------- read

  /** The matching parties in insertion order, each with both lists in insertion order (Operation 48 to 61). */
  async read(query: { party_id?: string; state?: PartyState; enrolled?: { from: string; to: string } } = {}): Promise<PartyView[] | { refused: "invalid-query" }> {
    const axes = ["party_id", "state", "enrolled"];
    if (Object.keys(query).some((k) => !axes.includes(k))) return { refused: "invalid-query" };                // Operation 48
    if ("party_id" in query && (typeof query.party_id !== "string" || isBlank(query.party_id))) return { refused: "invalid-query" };       // Operation 49: the axis admits every value that is not blank
    if ("state" in query && !["unverified", "verified", "suspended", "closed"].includes(String(query.state))) return { refused: "invalid-query" };
    if ("enrolled" in query) {
      const r = query.enrolled as { from?: unknown; to?: unknown };
      const inst = (v: unknown) => typeof v === "string" && !Number.isNaN(Date.parse(v));
      if (!r || !inst(r.from) || !inst(r.to) || Date.parse(r.from as string) > Date.parse(r.to as string)) return { refused: "invalid-query" };   // Query 1, 2: a range holds both its ends
    }
    const rows = await this.store.read<Stored>(`SELECT * FROM ${this.T}`);
    return rows
      .sort((a, b) => Number(a.ordinal) - Number(b.ordinal))
      .filter((p) => (query.party_id === undefined || p._id === query.party_id) && (query.state === undefined || p.state === query.state)
        && (!query.enrolled || (Date.parse(p.enrolled_at) >= Date.parse(query.enrolled.from) && Date.parse(p.enrolled_at) <= Date.parse(query.enrolled.to))))
      .map((p) => ({
        party_id: p._id, name: p.name, date_of_birth: p.date_of_birth, document_type: p.document_type, document_ref: p.document_ref,
        enrolled_at: p.enrolled_at, enrolling_actor_ref: p.enrolling_actor_ref, state: p.state,
        state_changes: JSON.parse(p.state_changes), verifications: JSON.parse(p.verifications),
      }));
  }
}
