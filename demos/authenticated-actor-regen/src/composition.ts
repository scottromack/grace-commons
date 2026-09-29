// Authenticated Actor: the three actions and the orphaned-credential leg.
// Rule numbers are compositions/authenticated-actor.md's.
import type { Database } from "@db/sqlite";
import type { Seam } from "./seam.ts";
import type { Faults } from "./faults.ts";
import type { Holding, Sections } from "./host.ts";
import { actorIdentity, credential } from "./atoms.ts";

const blank = (s: string | undefined | null) => s === undefined || s === null || s.trim() === "";

export interface Config {
  attestSurfaceSeparation: "enforced";   // Capability requirement 1
  gatingCredentialTypeDefault: string;   // 2
  registrationCompletionBoundMs: number; // 7
  attestCompletionBoundMs: number;       // 8
  reconciliationCadenceMs: number;       // 9
  clockOffsetAllowanceMs: number;        // 10
}

export type RegisterAnswer =
  | { ok: { credential_id: string; actor_ref: string; bound_at: string } }
  | { refused: "invalid-request" }
  | { refused: { "invalid-credential": string } }
  | { refused: { "namespace-conflict": "guard" | "binding" } }
  | { refused: { "storage-failure": "credential" | "binding" } }
  | { refused: { "orphan-credential": string } };

export type AttestAnswer =
  | { ok: string }
  | { refused: "invalid-request" | "not-bound" | "credential-not-active" | "invalid-attest-credential" }
  | { refused: { "attest-failed": "attestation" | { log: string | null } } };

export interface Binding { principal_ref: string; actor_ref: string; credential_type: string; credential_id: string; bound_at: string }
export interface LogEntry {
  entry_id: number; attempted_at: string; principal_ref: string; action_ref: string; outcome: string;
  observed_status: string | null; credential_id: string | null; attestation_id: string | null;
}

export class AuthenticatedActor {
  private constructor(private db: Database, private seam: Seam, private f: Faults, private sections: Sections, private cfg: Config) {}

  // Capability requirement 11: no start on an unset bound. Housekeeping 1: the leg runs at start.
  static start(db: Database, seam: Seam, f: Faults, sections: Sections, cfg: Partial<Config>) {
    for (const k of ["attestSurfaceSeparation", "gatingCredentialTypeDefault", "registrationCompletionBoundMs",
      "attestCompletionBoundMs", "reconciliationCadenceMs", "clockOffsetAllowanceMs"] as const) {
      if (cfg[k] === undefined) throw new Error(`refusing to start: ${k} is not set`);
    }
    const instance = new AuthenticatedActor(db, seam, f, sections, cfg as Config);
    return { instance, report: instance.orphanedCredentials() };
  }

  binding(principal_ref: string) {
    return this.db.prepare("SELECT * FROM principal_binding WHERE principal_ref = ?").get<Binding>(principal_ref);
  }
  private inverse(actor_ref: string) {
    return this.db.prepare("SELECT principal_ref FROM actor_binding WHERE actor_ref = ?").get<{ principal_ref: string }>(actor_ref);
  }
  log(): LogEntry[] { return this.db.prepare("SELECT * FROM attest_log ORDER BY entry_id").all<LogEntry>(); }

  // ---- [Register Authenticated Actor] ----
  register(principal_ref: string, actor_ref: string, credential_material: string, credential_type?: string, expires_at?: string): RegisterAnswer {
    const now = this.seam.now();
    // Primitive policy 1 through 4 and 7; Action wiring 30 fills an absent credential type.
    if (blank(principal_ref) || blank(actor_ref) || blank(credential_material)) return { refused: "invalid-request" };
    if (credential_type !== undefined && blank(credential_type)) return { refused: "invalid-request" };
    if (expires_at !== undefined && !(now < expires_at)) return { refused: "invalid-request" };
    const type = credential_type ?? this.cfg.gatingCredentialTypeDefault;

    let held = this.sections.take(principal_ref, this.cfg.registrationCompletionBoundMs); // Action wiring 1
    try {
      // Action wiring 2, 3: the guard.
      if (this.binding(principal_ref) || this.inverse(actor_ref)) return { refused: { "namespace-conflict": "guard" } };
      // Action wiring 4 through 8.
      let credential_id: string;
      const r = credential.register(this.db, this.seam, this.f, principal_ref, type, credential_material, expires_at);
      if ("ok" in r) credential_id = r.ok;
      else if (r.refused === "invalid-request") return { refused: "invalid-request" };          // Action wiring 31
      else if (r.refused === "storage-failure") return { refused: { "storage-failure": "credential" } }; // Action wiring 32
      else {
        const existing = credential.effectiveActive(this.db, principal_ref, type, this.seam.now())!;
        if (credential.verify(this.db, this.seam, principal_ref, type, credential_material) !== "verified") {
          return { refused: { "invalid-credential": existing.credential_id } };
        }
        credential_id = existing.credential_id;
      }
      this.f.at("after-credential");
      // Action wiring 12, 13, 33: a lapsed holder takes the section again and re-runs the guard.
      if (held.lapsed()) {
        held = this.sections.take(principal_ref, this.cfg.registrationCompletionBoundMs);
        if (this.binding(principal_ref)) return { refused: { "orphan-credential": credential_id } };
        if (this.inverse(actor_ref)) return { refused: { "namespace-conflict": "binding" } };
      }
      // Action wiring 9 through 11; Composition state 3: both directions in one transaction.
      if (this.f.hit("binding.write")) return { refused: { "storage-failure": "binding" } };
      try {
        this.db.exec("BEGIN");
        this.db.prepare("INSERT INTO principal_binding VALUES (?, ?, ?, ?, ?)").run(principal_ref, actor_ref, type, credential_id, now);
        this.db.prepare("INSERT INTO actor_binding VALUES (?, ?)").run(actor_ref, principal_ref);
        this.db.exec("COMMIT");
      } catch (e) {
        this.db.exec("ROLLBACK");
        if (String(e).includes("UNIQUE")) return { refused: { "namespace-conflict": "binding" } };
        throw e;
      }
      return { ok: { credential_id, actor_ref, bound_at: now } };
    } finally {
      held.release(); // Capability requirement 4
    }
  }

  // ---- [Attest As Actor] ----
  attest(principal_ref: string, action_ref: string, attest_credential: string): AttestAnswer {
    const now = this.seam.now();
    const entry = (outcome: string, extra: Partial<LogEntry> = {}) => this.append({ attempted_at: now, principal_ref, action_ref, outcome, ...extra });
    // Composition state 8 logs refused calls too; Action wiring 25 answers a failed append.
    const refuse = (outcome: "invalid-request" | "not-bound" | "credential-not-active" | "invalid-attest-credential", extra: Partial<LogEntry> = {}): AttestAnswer =>
      entry(outcome, extra) ? { refused: outcome } : { refused: { "attest-failed": { log: null } } };

    if (blank(principal_ref) || blank(action_ref) || blank(attest_credential)) return refuse("invalid-request"); // Primitive policy 1, 5, 6
    const b = this.binding(principal_ref); // Action wiring 14
    if (!b) return refuse("not-bound"); // 15

    let held: Holding = this.sections.take(principal_ref, this.cfg.attestCompletionBoundMs); // 16
    try {
      for (;;) {
        // Action wiring 17, 18: the gate, keyed on the bound pair (Composes 9, 10).
        const records = credential.read(this.db, this.seam, { principal_ref, credential_type: b.credential_type });
        const gate = records.find((c) => c.effective_status === "active");
        if (!gate) {
          const last = records.at(-1)!;
          return refuse("credential-not-active", { observed_status: last.effective_status, credential_id: last.credential_id });
        }
        this.f.at("after-gate");
        // Wiring decision 3; Action wiring 36: a lapse before the attestation goes back to the gate.
        if (held.lapsed()) { held = this.sections.take(principal_ref, this.cfg.attestCompletionBoundMs); continue; }
        // Action wiring 19 through 23: the bound actor reference, the caller's attest credential.
        const r = actorIdentity.attest(this.db, this.seam, this.f, action_ref, b.actor_ref, attest_credential);
        if ("refused" in r) {
          if (r.refused === "invalid-credential") return refuse("invalid-attest-credential", { credential_id: gate.credential_id });
          const ok = entry("attest-failed", { credential_id: gate.credential_id });
          return { refused: { "attest-failed": ok ? "attestation" : { log: null } } };
        }
        this.f.at("after-attest");
        // Action wiring 24, 25, 37.
        if (held.lapsed()) held = this.sections.take(principal_ref, this.cfg.attestCompletionBoundMs);
        return entry("success", { credential_id: gate.credential_id, attestation_id: r.ok })
          ? { ok: r.ok }
          : { refused: { "attest-failed": { log: r.ok } } };
      }
    } finally {
      held.release();
    }
  }

  private append(e: Omit<LogEntry, "entry_id" | "observed_status" | "credential_id" | "attestation_id"> & Partial<LogEntry>): boolean {
    if (this.f.hit("attest_log.append")) return false;
    this.db.prepare("INSERT INTO attest_log (attempted_at, principal_ref, action_ref, outcome, observed_status, credential_id, attestation_id) VALUES (?, ?, ?, ?, ?, ?, ?)")
      .run(e.attempted_at, e.principal_ref, e.action_ref, e.outcome, e.observed_status ?? null, e.credential_id ?? null, e.attestation_id ?? null);
    return true;
  }

  // ---- [Verify Actor Attestation] ---- Action wiring 26 through 28; Non-goal 13.
  verify(attestation_id: string): { result: string; actor_ref?: string; principal_ref?: string } {
    const v = actorIdentity.verify(this.db, attestation_id);
    if (v === "not-known") return { result: v };
    const result = v === "verified" ? v : `failed-verification(${v["failed-verification"]})`;
    const a = actorIdentity.read(this.db).find((x) => x.attestation_id === attestation_id)!;
    const p = this.inverse(a.actor_ref);
    return p ? { result, actor_ref: a.actor_ref, principal_ref: p.principal_ref } : { result, actor_ref: a.actor_ref };
  }

  // ---- The orphaned-credential leg ---- Housekeeping 3 through 7: reads, holds nothing, reports.
  orphanedCredentials(): string[] {
    const edge = Date.parse(this.seam.now()) - this.cfg.registrationCompletionBoundMs - this.cfg.clockOffsetAllowanceMs;
    return credential.read(this.db, this.seam, {})
      .filter((c) => Date.parse(c.registered_at) < edge)
      .filter((c) => {
        const b = this.binding(c.principal_ref);
        return !b || b.credential_type !== c.credential_type;
      })
      .map((c) => c.credential_id);
  }
}
