// Idempotent Reservation, rendered from compositions/idempotent-reservation.md.
// Every rule cited is that page's unless another page is named.
import type { Database } from "@db/sqlite";
import type { Seam } from "./seam.ts";
import type { Faults } from "./faults.ts";
import { type Commitment, duplicatePrevention, type PcAnswer, provisionalCommitment } from "./atoms.ts";

export type Action = "place_hold" | "confirm" | "release" | "expire";                     // Term action type
export type Params = { resource: string; requester: string; duration: number } | { id: string };
export type Answer = { ok: string } | { refused: string; candidates?: string[] }
  | { refused: "recording-failure"; position: "intent" } | { refused: "recording-failure"; position: "outcome"; answer: Answer };
export interface Config {
  windowMs: number;                  // Capability requirement 1
  tokenMaxLength: number;            // 2
  completionBoundMs: number;         // 9
  atomicAck: boolean;                // 17
  durationBounds: [number, number];  // Provisional Commitment's duration bounds
  resultAttempts?: number;           // the result write's retries inside the bound (see CORNERS.md)
}
interface Entry { token: string; action_type: Action; digest: string; result: string; pending_at: string; completed_at: string | null; recovered: number }

export class IdempotentReservation {
  private held = new Set<string>();  // the per-token critical section (Capability requirement 5 through 8)
  private constructor(private db: Database, private seam: Seam, private f: Faults, readonly c: Config) {}
  static start(db: Database, seam: Seam, f: Faults, c: Config) {
    if (!(c.windowMs > c.completionBoundMs)) throw new Error("instance will not start: the idempotency window does not exceed the reservation completion bound");  // 10, 11
    return new IdempotentReservation(db, seam, f, c);
  }
  private take(token: string) { if (this.held.has(token)) return false; this.held.add(token); return true; }
  private entry(token: string) { return this.db.prepare("SELECT * FROM token_results WHERE token = ?").get<Entry>(token); }
  private elapsed(e: Entry) { return !(Date.parse(this.seam.now()) - Date.parse(e.pending_at) < this.c.windowMs); }
  private check(token: string) {                                                            // Capability requirement 16: fail-closed
    const a = duplicatePrevention.check(this.db, this.seam, this.f, token, this.c.windowMs);
    return a === "unavailable" ? "seen" : a;
  }
  private record(token: string) { duplicatePrevention.record(this.db, this.seam, token); }
  candidates(p: Params): string[] {                                                         // Indeterminate outcome 3, 4; Term candidates
    if (!("resource" in p)) return [p.id];                                                  // Indeterminate outcome 14
    const now = this.seam.now();
    return provisionalCommitment.read(this.db).filter((c: Commitment) => c.state === "held" && c.expires_at > now && c.resource === p.resource && c.requester === p.requester).map((c) => c.id);
  }

  place_hold(resource: string, requester: string, duration: number, token: string) { return this.invoke("place_hold", { resource, requester, duration }, token); }
  confirm(id: string, token: string) { return this.invoke("confirm", { id }, token); }
  release(id: string, token: string) { return this.invoke("release", { id }, token); }
  expire(id: string, token: string) { return this.invoke("expire", { id }, token); }
  read(): Commitment[] { return provisionalCommitment.read(this.db); }                      // Action wiring 22, 23

  private invoke(action: Action, params: Params, token: string): Answer {
    if (typeof token !== "string" || token.trim() === "") return { refused: "invalid-request" };                     // Primitive policy 1
    if (new TextEncoder().encode(token).length > this.c.tokenMaxLength) return { refused: "invalid-request" };      // 2, 7
    if (!this.take(token)) throw new Error("a holder did not release the token's section");                         // Action wiring 2; synchronous host
    try {
      const digest = this.seam.digest(params);                                                                       // Composition state 9, 10
      let e = this.entry(token);                                                                                     // Action wiring 3
      const dp = this.check(token);                                                                                  // 4
      if (e && (e.action_type !== action || e.digest !== digest)) return { refused: "token-collision" };            // 7, 8
      if (e && e.completed_at !== null) {
        if (this.elapsed(e) && dp === "not-seen") {                                                                  // 12
          this.db.prepare("DELETE FROM token_results WHERE token = ?").run(token);
          e = undefined;
        } else {
          if (dp === "not-seen") this.record(token);                                                                // 11
          return JSON.parse(e.result);                                                                               // 9, 10
        }
      }
      if (e) {                                                                                                       // a pending entry: Indeterminate outcome 1, 2
        if (action !== "place_hold") return this.delegate(action, params, token, true);                             // 9
        const cands = this.candidates(params);
        if (cands.length === 0) return this.delegate(action, params, token, true);                                  // 5
        return this.close(token, { refused: "outcome-unknown", candidates: cands }, true);                          // 6, 7
      }
      if (dp === "seen") {                                                                                           // a seen token carrying no entry
        if (action !== "place_hold") {                                                                               // Indeterminate outcome 13
          if (!this.pending(token, action, digest)) return { refused: "recording-failure", position: "intent" };
          return this.delegate(action, params, token, true);
        }
        return { refused: "outcome-unknown", candidates: this.candidates(params) };                                 // Indeterminate outcome 10; Wiring decision 4
      }
      if (!this.pending(token, action, digest)) return { refused: "recording-failure", position: "intent" };        // Action wiring 13, 14
      return this.delegate(action, params, token, false);
    } finally { this.held.delete(token); }                                                                           // 5
  }
  private pending(token: string, action: Action, digest: string) {                                                  // Composition state 4
    if (this.f.hit("map.pending", token)) return false;
    this.db.prepare("INSERT INTO token_results VALUES (?, ?, ?, 'pending', ?, NULL, 0)").run(token, action, digest, this.seam.now());
    return true;
  }
  private delegate(action: Action, params: Params, token: string, recovered: boolean): Answer {
    let a: PcAnswer = "resource" in params
      ? provisionalCommitment.place_hold(this.db, this.seam, this.f, params.resource, params.requester, params.duration, this.c.durationBounds)
      : provisionalCommitment.resolve(this.db, this.seam, this.f, action as "confirm", params.id);                  // Composes 6
    if (!this.c.atomicAck && "refused" in a && a.refused === "storage-failure")                                      // Capability requirement 17
      a = { refused: "outcome-unknown", candidates: this.candidates(params) } as PcAnswer;
    return this.close(token, a as Answer, recovered);
  }
  // Overwrite the pending entry in place (Composition state 5, 7), then record the guard (Action wiring 20).
  private close(token: string, answer: Answer, recovered: boolean): Answer {
    let landed = false;
    for (let i = 0; i < (this.c.resultAttempts ?? 3) && !landed; i++) {                                            // 17
      if (this.f.hit("map.result", token)) continue;
      this.db.prepare("UPDATE token_results SET result = ?, completed_at = ?, recovered = ? WHERE token = ?")
        .run(JSON.stringify(answer), this.seam.now(), recovered ? 1 : 0, token);                                    // Wiring decision 1, 2; Indeterminate outcome 8
      landed = true;
    }
    if (!landed) return { refused: "recording-failure", position: "outcome", answer };                              // 18, 19; Wiring decision 5
    this.record(token);                                                                                              // 20, 25; Composes 7
    return answer;                                                                                                   // 21
  }

  // ---- the eviction leg (Housekeeping 1 through 9) ----
  evict(): string[] {
    const now = Date.parse(this.seam.now()), out: string[] = [];                                                    // 9
    for (const e of this.db.prepare("SELECT * FROM token_results").all<Entry>()) {
      if (!this.take(e.token)) continue;                                                                             // 1, 2
      try {
        if (now - Date.parse(e.pending_at) < this.c.completionBoundMs) continue;                                    // 3
        if (this.check(e.token) !== "not-seen" || !this.elapsed(e)) continue;                                       // 4 through 6
        this.db.prepare("DELETE FROM token_results WHERE token = ?").run(e.token);
        out.push(e.token);
      } finally { this.held.delete(e.token); }
    }
    return out;
  }
  holdSection(token: string) { return this.take(token); }                                                            // for tests: another holder
  releaseSection(token: string) { this.held.delete(token); }
}
