// Credential: register, verify, rotate, revoke and read. Rule numbers are
// atoms/credential.md's. Each call takes one reading of now at its start
// (Capability requirement 1); derivation and check run at the seam (registry.ts).
import type { Database } from "@db/sqlite";
import type { Seam } from "./seam.ts";
import type { Faults } from "./faults.ts";
import type { Registry } from "./registry.ts";
import { type Holding, pairKey, Sections } from "./sections.ts";

export interface Config { defaultValidityMs: number | null; lengthBound: number; leaseMs: number }
export interface Row {
  credential_id: string; principal_ref: string; credential_type: string; verifier: string; registered_at: string;
  expires_at: string | null; status: "active" | "rotated" | "revoked"; rotated_at: string | null;
  successor_credential_id: string | null; revoked_at: string | null; revoked_by_ref: string | null; revocation_reason: string | null;
}
type A<T, E extends string> = { ok: T } | { refused: E };

const blank = (s: unknown) => typeof s !== "string" || s.trim() === "";        // String 5, 6
const live = (c: Row, now: string) => c.expires_at === null || c.expires_at > now; // Term live; the boundary reads lapsed
const effectiveActive = (c: Row, now: string) => c.status === "active" && live(c, now);

export class Credential {
  private sections: Sections;
  constructor(private db: Database, private seam: Seam, private f: Faults, private registry: Registry, private cfg: Config) {
    this.sections = new Sections(seam, cfg.leaseMs);
  }
  private tooLong = (s: string) => [...s].length > this.cfg.lengthBound;       // String 7, 9
  private byId = (id: string) => this.db.prepare("SELECT * FROM credential WHERE credential_id = ?").get<Row>(id);
  private pair = (p: string, t: string) =>
    this.db.prepare("SELECT * FROM credential WHERE principal_ref = ? AND credential_type = ? ORDER BY registered_at, credential_id").all<Row>(p, t);
  private deadline(expires_at: string | undefined, now: string): string | null { // Operation 12, 13, 61, 62
    if (expires_at !== undefined) return expires_at;
    return this.cfg.defaultValidityMs === null ? null : new Date(Date.parse(now) + this.cfg.defaultValidityMs).toISOString();
  }

  // ---- [Register]: Operation 1 through 17, 66 ----
  register(principal_ref: string, credential_material: string, credential_type: string, expires_at?: string):
    A<string, "invalid-request" | "duplicate-active-credential" | "storage-failure"> {
    const now = this.seam.now();
    if (blank(principal_ref) || blank(credential_material) || blank(credential_type)) return { refused: "invalid-request" };
    if (this.tooLong(principal_ref) || this.tooLong(credential_type)) return { refused: "invalid-request" };
    const fns = this.registry[credential_type];
    if (!fns) return { refused: "invalid-request" };                                   // Operation 4; Identity 11
    if (expires_at !== undefined && !(now < expires_at)) return { refused: "invalid-request" }; // Operation 5
    const verifier = fns.derive(credential_material, this.seam.entropy());              // at the seam
    if (verifier === "refused") return { refused: "invalid-request" };                 // Operation 66
    const held = this.sections.take(pairKey(principal_ref, credential_type));          // Capability requirement 8
    try {
      if (this.pair(principal_ref, credential_type).some((c) => effectiveActive(c, now))) return { refused: "duplicate-active-credential" }; // 6, 8
      const id = this.seam.id();                                                        // Operation 9; Identity 2
      this.f.at("register-before-write");
      if (held.overdue() || this.f.hit("store.write")) return { refused: "storage-failure" }; // Capability requirement 23; Operation 45, 48
      this.db.prepare("INSERT INTO credential (credential_id, principal_ref, credential_type, verifier, registered_at, expires_at, status) VALUES (?, ?, ?, ?, ?, ?, 'active')")
        .run(id, principal_ref, credential_type, verifier, now, this.deadline(expires_at, now));
      return { ok: id };
    } finally { held.release(); }                                                       // Capability requirement 9, 17
  }

  // ---- [Verify]: Operation 18 through 26, 68 — writes nothing ----
  verify(principal_ref: string, credential_type: string, presented_material: string):
    "verified" | { "failed-verification": "material-mismatch" | "no-active-credential" } {
    const now = this.seam.now();
    const c = this.pair(principal_ref, credential_type).find((r) => effectiveActive(r, now)); // the window reading first (20)
    if (!c) return { "failed-verification": "no-active-credential" };                      // 18, 19
    const r = this.registry[credential_type].check(presented_material ?? "", c.verifier);  // at the seam (21, 24)
    return r === "match" ? "verified" : { "failed-verification": "material-mismatch" };      // 22, 23, 68
  }

  // ---- [Rotate]: Operation 27, 28, 31, 35 through 41, 58 through 65, 67 ----
  rotate(credential_id: string, new_credential_material: string, expires_at?: string):
    A<string, "not-known" | "not-active" | "invalid-request" | "storage-failure"> {
    const now = this.seam.now();
    const prior = this.byId(credential_id);
    if (!prior) return { refused: "not-known" };                                        // 27
    const held: Holding = this.sections.take(pairKey(prior.principal_ref, prior.credential_type)); // Capability requirement 8
    try {
      const pair = this.pair(prior.principal_ref, prior.credential_type);
      const p = pair.find((c) => c.credential_id === credential_id)!;
      if (!effectiveActive(p, now)) return { refused: "not-active" };                  // 28
      if (pair.some((c) => c.credential_id !== credential_id && effectiveActive(c, now))) return { refused: "not-active" }; // 65
      if (blank(new_credential_material)) return { refused: "invalid-request" };        // 31, after the standing checks (34)
      if (expires_at !== undefined && !(now < expires_at)) return { refused: "invalid-request" }; // 63
      const verifier = this.registry[p.credential_type].derive(new_credential_material, this.seam.entropy());
      if (verifier === "refused") return { refused: "invalid-request" };                 // 67
      const id = this.seam.id();                                                          // 58
      this.f.at("rotate-before-write");
      if (held.overdue() || this.f.hit("store.write")) return { refused: "storage-failure" }; // 23, 45, 49
      this.db.exec("BEGIN");                                                               // 40; Capability requirement 12
      this.db.prepare("INSERT INTO credential (credential_id, principal_ref, credential_type, verifier, registered_at, expires_at, status) VALUES (?, ?, ?, ?, ?, ?, 'active')")
        .run(id, p.principal_ref, p.credential_type, verifier, now, this.deadline(expires_at, now)); // 35, 36, 59 through 62
      // Concurrency 1: the standing check and the status change as one statement; a revoke outside the
      // pair's section may have moved the prior first, and then the rotate loses (Concurrency 2).
      const moved = this.db.prepare("UPDATE credential SET status = 'rotated', rotated_at = ?, successor_credential_id = ? WHERE credential_id = ? AND status = 'active'")
        .run(now, id, credential_id);                                                     // 37 through 39
      if (moved !== 1) { this.db.exec("ROLLBACK"); return { refused: "not-active" }; }
      this.db.exec("COMMIT");
      return { ok: id };                                                                   // 41
    } finally { held.release(); }
  }

  // ---- [Revoke]: Operation 27, 29, 32 through 34, 42 through 44; String 9 ----
  revoke(credential_id: string, revoked_by_ref: string, reason: string):
    A<"revoked", "not-known" | "already-terminal" | "invalid-request" | "storage-failure"> {
    const now = this.seam.now();
    const c = this.byId(credential_id);
    if (!c) return { refused: "not-known" };
    if (!effectiveActive(c, now)) return { refused: "already-terminal" };
    if (blank(revoked_by_ref) || blank(reason) || this.tooLong(revoked_by_ref) || this.tooLong(reason)) return { refused: "invalid-request" };
    if (this.f.hit("store.write")) return { refused: "storage-failure" };
    // Concurrency 1: the standing check and the status change as one statement.
    const r = this.db.prepare("UPDATE credential SET status = 'revoked', revoked_at = ?, revoked_by_ref = ?, revocation_reason = ? WHERE credential_id = ? AND status = 'active'")
      .run(now, revoked_by_ref, reason, credential_id);
    return r === 1 ? { ok: "revoked" } : { refused: "already-terminal" };               // Concurrency 2
  }

  // ---- [Read]: Operation 51 through 55, 69 — never the verifier, never a refusal ----
  read(filter: { principal_ref?: string; credential_type?: string; credential_id?: string } = {}) {
    const now = this.seam.now();
    const keys = ["principal_ref", "credential_type", "credential_id"] as const;
    return this.db.prepare("SELECT * FROM credential ORDER BY registered_at, credential_id").all<Row>()
      .filter((c) => keys.every((k) => filter?.[k] === undefined || c[k] === filter[k]))
      .map(({ verifier: _v, ...c }) => ({ ...c, effective_status: c.status === "active" && !live(c as Row, now) ? "expired" : c.status }));
  }
}
