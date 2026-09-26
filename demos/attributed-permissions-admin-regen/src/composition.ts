// Attributed Permissions Admin, rendered from compositions/attributed-permissions-admin.md.
// Every rule cited below is that page's unless another page is named.
import type { Database } from "@db/sqlite";
import type { Faults } from "./store.ts";
import type { Seam } from "./seam.ts";
import * as AI from "./actor_identity.ts";
import * as P from "./permissions.ts";

export interface Config {
  prefix: string;                        // the namespace prefix (Capability requirement 11 and 13)
  lengthCap: number;                     // the composition's length cap (Capability requirement 29)
  retentionScope: "pair" | "per-store";  // Capability requirement 27
  issuanceBoundMs: number;               // Capability requirement 16
  revocationBoundMs: number;             // Capability requirement 17
  pairScopedBoundMs: number;             // Capability requirement 18
  retentionHorizonMs?: number;           // the retention layer's horizon, when one is declared
}

export interface Instance { db: Database; seam: Seam; faults: Faults; config: Config; registryUp: boolean }

// Capability requirement 19, 25, 29 and 30: an instance starts only with its bounds ordered,
// its length cap inside the constituent's, and the pairing atomicity supplied.
export function start(db: Database, seam: Seam, config: Config, faults: Faults = {}): Instance {
  if (config.lengthCap > P.STRING_CAP) throw new Error("length cap exceeds the Permissions string cap");
  if (config.revocationBoundMs > config.pairScopedBoundMs) throw new Error("revocation bound exceeds the pair-scoped bound");
  if (config.prefix.trim() === "") throw new Error("the namespace prefix is blank");
  return { db, seam, faults, config, registryUp: true };
}

export type Position = "pre-grant" | "post-grant" | "pre-revoke" | "post-revoke";
export type Refusal =
  | { refused: "invalid-request" | "invalid-credential" | "attribution-storage-failure" | "not-known" | "not-active" | "not-permitted" }
  | { refused: "orphan-attestation"; position: Position; grant_id?: string }
  | { refused: "partially-revoked"; revoked_grant_ids: string[]; remaining: string[] };

// ---- boundary predicate (Primitive policy 1 through 8) ----
// Administered inputs are trimmed once, here, and the trimmed value reaches the
// constituent. The credential, last, is checked for blank and length and passed
// as given (Term administered opaque input; Primitive policy 12).
function admit(cap: number, inputs: string[], credential: string): string[] | undefined {
  const out = inputs.map((s) => s.trim());
  if (out.some((s) => s === "" || s.length > cap)) return undefined;
  if (credential.trim() === "" || credential.length > cap) return undefined;
  return [...out, credential];
}

// Capability requirement 15: canonical serialization, keys in a fixed order.
function canonical(prefix: string, body: Record<string, string>): string {
  const keys = Object.keys(body).sort();
  return prefix + JSON.stringify(Object.fromEntries(keys.map((k) => [k, body[k]])));
}

function logOrphan(db: Database, attestation_id: string, proposal: string, requested_at: string,
  reason: string, grant_id: string | null = null) {
  db.prepare("INSERT INTO orphan_log VALUES (?, ?, ?, ?, ?)").run(attestation_id, proposal, requested_at, reason, grant_id);
}

// ---- Issue Grant (Action wiring 1 through 15) ----
export function issue_grant(x: Instance, subject_ref: string, action_scope: string,
  grantor_ref: string, grantor_credential: string): { ok: { grant_id: string; attestation_id: string } } | Refusal {
  const a = admit(x.config.lengthCap, [subject_ref, action_scope, grantor_ref], grantor_credential);
  if (!a) return { refused: "invalid-request" };
  const [subject, scope, grantor, credential] = a;
  const requested_at = x.seam.now();                       // Identity 7 and 8
  const proposal = canonical(x.config.prefix, { subject_ref: subject, action_scope: scope, nonce: x.seam.nonce(), requested_at });

  // Wiring decision 3: the attest commits on its own, outside any transaction.
  const att = AI.attest(x.db, x.seam, x.faults, proposal, grantor, credential);
  if ("refused" in att) {
    if (att.refused === "storage-failure") return { refused: "attribution-storage-failure" };
    return { refused: att.refused };                       // Action wiring 3, 4 and 6
  }
  const attestation_id = att.ok;
  return pairWrite(x, attestation_id, proposal, requested_at, "grant",
    () => P.grant(x.db, x.seam, x.faults, subject, scope),
    (grant_id) => x.db.prepare("INSERT INTO grant_attribution VALUES (?, ?)").run(grant_id, attestation_id));
}

// One constituent write and its pairing entry under one transaction (Capability
// requirement 23). Under a non-honouring host the write commits alone first.
function pairWrite(x: Instance, attestation_id: string, proposal: string, requested_at: string,
  side: "grant" | "revoke", write: () => { ok: string | true } | { refused: string }, pair: (grant_id: string) => void,
  target?: string): any {
  const pre: Position = side === "grant" ? "pre-grant" : "pre-revoke";
  const post: Position = side === "grant" ? "post-grant" : "post-revoke";
  const storageReason = side === "grant" ? "grant-storage-failure" : "revocation-storage-failure";
  let grant_id = target ?? "";
  const refusedWrite = (r: string) => {
    logOrphan(x.db, attestation_id, proposal, requested_at, r === "storage-failure" ? storageReason : r);
    if (r === "not-known" || r === "not-active") return { refused: r };     // Action wiring 23, 24, 26
    return { refused: "orphan-attestation", position: pre };               // Action wiring 8, 9, 25
  };

  if (x.faults.nonAtomicHost) {
    const w = write();
    if ("refused" in w) return refusedWrite(w.refused);
    if (side === "grant") grant_id = w.ok as string;
    logOrphan(x.db, attestation_id, proposal, requested_at, "pairing-write-failure", grant_id);
    return side === "grant"
      ? { refused: "orphan-attestation", position: post, grant_id }       // Action wiring 14
      : { refused: "orphan-attestation", position: post };                // Action wiring 33
  }

  x.db.exec("BEGIN");
  const w = write();
  if ("refused" in w) { x.db.exec("ROLLBACK"); return refusedWrite(w.refused); }
  if (side === "grant") grant_id = w.ok as string;
  try {
    if (x.faults.pairingWrite) throw new Error("pairing write refused");
    pair(grant_id);
    x.db.exec("COMMIT");
  } catch {
    x.db.exec("ROLLBACK");
    // Action wiring 13 and 32; Composition state 20: the pairing step's entry carries the handle.
    logOrphan(x.db, attestation_id, proposal, requested_at, "pairing-write-failure", grant_id);
    return { refused: "orphan-attestation", position: pre };
  }
  return side === "grant" ? { ok: { grant_id, attestation_id } } : { ok: { attestation_id } };
}

// ---- Revoke Grant (Action wiring 16 through 41) ----
export function revoke_grant(x: Instance, grant_id: string, revoker_ref: string, revoker_credential: string):
  { ok: { attestation_id: string } } | Refusal {
  const a = admit(x.config.lengthCap, [grant_id, revoker_ref], revoker_credential);
  if (!a) return { refused: "invalid-request" };
  return revokeOne(x, a[0], a[1], a[2], x.seam.now());
}

// Primitive policy 17: no Permissions query before the attestation.
function revokeOne(x: Instance, grant_id: string, revoker: string, credential: string, requested_at: string):
  { ok: { attestation_id: string } } | Refusal {
  const proposal = canonical(x.config.prefix, { grant_id, requested_at });
  const att = AI.attest(x.db, x.seam, x.faults, proposal, revoker, credential);
  if ("refused" in att) {
    if (att.refused === "storage-failure") return { refused: "attribution-storage-failure" };
    return { refused: att.refused };                       // Action wiring 18, 19 and 21
  }
  const attestation_id = att.ok;
  return pairWrite(x, attestation_id, proposal, requested_at, "revoke",
    () => P.revoke(x.db, x.seam, x.faults, grant_id),
    () => x.db.prepare("INSERT INTO revocation_attribution VALUES (?, ?)").run(grant_id, attestation_id),
    grant_id);
}

// ---- Revoke Permission (Action wiring 42 through 54, Wiring decision 6) ----
export function revoke_permission(x: Instance, subject_ref: string, action_scope: string,
  revoker_ref: string, revoker_credential: string):
  { ok: { revoked_grant_ids: string[]; attestation_ids: string[] } } | Refusal {
  const a = admit(x.config.lengthCap, [subject_ref, action_scope, revoker_ref], revoker_credential);
  if (!a) return { refused: "invalid-request" };
  const [subject, scope, revoker, credential] = a;
  // Action wiring 42: one read, filtered here to the pair's active grants (Term enumerated set).
  const enumerated = P.read(x.db)
    .filter((g) => g.subject_ref === subject && g.action_scope === scope && g.status === "active")
    .map((g) => g.grant_id);
  if (enumerated.length === 0) return { refused: "not-permitted" };  // Action wiring 43 through 45
  const requested_at = x.seam.now();                         // Identity 9: one reading for every attestation
  const revoked: string[] = [], attestations: string[] = [], remaining: string[] = [];
  for (const g of enumerated) {
    const r = revokeOne(x, g, revoker, credential, requested_at);
    if ("ok" in r) { revoked.push(g); attestations.push(r.ok.attestation_id); continue; }
    if (r.refused === "not-active") continue;                // Action wiring 47
    if ((r.refused === "invalid-credential" || r.refused === "invalid-request") && revoked.length === 0 && remaining.length === 0)
      return { refused: r.refused };                         // the credential fails before anything lands
    remaining.push(g);
  }
  if (remaining.length === 0) return { ok: { revoked_grant_ids: revoked, attestation_ids: attestations } };
  return { refused: "partially-revoked", revoked_grant_ids: revoked, remaining };  // Action wiring 49; Invariant 9.4
}

// ---- Verify Grant Attribution (Action wiring 55 through 80); writes nothing ----
export type VerifyResult = AI.VerifyAnswer | { "not-applicable": "purged" };
export interface AttributionRecord {
  grant_record: P.GrantRecord;
  issuance_attestation_id: string; issuance_verify_result: VerifyResult;
  revocation_attestation_id?: string; revocation_verify_result?: VerifyResult;
}

function verifyOne(x: Instance, id: string): VerifyResult {
  const v = AI.verify(x.db, id, x.registryUp);
  if (v !== "not-known") return v;
  // Action wiring 62 through 67: the purge record, read only after an absent attestation
  // and only where the retention scope is per-store.
  if (x.config.retentionScope === "per-store" &&
      x.db.prepare("SELECT 1 FROM purge_record WHERE attestation_id = ?").get(id)) return { "not-applicable": "purged" };
  return "not-known";                                        // the tamper reading
}

export function verify_grant_attribution(x: Instance, grant_id: string):
  { ok: AttributionRecord } | "not-known" | "attribution-inconsistency" {
  const g = P.read(x.db).find((r) => r.grant_id === grant_id);  // Action wiring 55
  if (!g) return "not-known";
  const ga = x.db.prepare("SELECT attestation_id FROM grant_attribution WHERE grant_id = ?").get<{ attestation_id: string }>(grant_id);
  if (!ga) return "attribution-inconsistency";
  const rec: AttributionRecord = { grant_record: g, issuance_attestation_id: ga.attestation_id, issuance_verify_result: verifyOne(x, ga.attestation_id) };
  if (g.status === "revoked") {
    const ra = x.db.prepare("SELECT attestation_id FROM revocation_attribution WHERE grant_id = ?").get<{ attestation_id: string }>(grant_id);
    if (!ra) return "attribution-inconsistency";
    rec.revocation_attestation_id = ra.attestation_id;
    rec.revocation_verify_result = verifyOne(x, ra.attestation_id);
  }
  return { ok: rec };
}

// ---- the evaluation passthrough (Action wiring 81 through 83; Primitive policy 11) ----
export function permitted(x: Instance, subject_ref: string, action_scope: string): "permitted" | "denied" {
  return P.permitted(x.db, subject_ref, action_scope);
}

// ---- the failed-grant leg (Housekeeping 1 through 18): reads and reports, never writes ----
export type LegFinding = { attestation_id: string; reading: "orphan" | "purge-pending-orphan" | "non-conformant-purge" };
export function failed_grant_leg(x: Instance, now: string): LegFinding[] {
  const out: LegFinding[] = [];
  const t = Date.parse(now);
  for (const e of AI.read(x.db)) {                                        // Housekeeping 2
    if (!e.action_ref.startsWith(x.config.prefix)) continue;              // Housekeeping 3
    const named = x.db.prepare("SELECT 1 FROM grant_attribution WHERE attestation_id = ? UNION SELECT 1 FROM revocation_attribution WHERE attestation_id = ?")
      .get(e.attestation_id, e.attestation_id);
    if (named) continue;
    const body = JSON.parse(e.action_ref.slice(x.config.prefix.length)) as Record<string, string>;
    const age = t - Date.parse(body.requested_at);                        // Housekeeping 13
    const bound = "grant_id" in body ? x.config.pairScopedBoundMs : x.config.issuanceBoundMs;  // Housekeeping 11 and 12
    if (age <= bound) continue;
    if (x.config.retentionHorizonMs !== undefined && age > x.config.retentionHorizonMs) {
      const logged = x.db.prepare("SELECT 1 FROM orphan_log WHERE attestation_id = ?").get(e.attestation_id);
      out.push({ attestation_id: e.attestation_id, reading: logged ? "purge-pending-orphan" : "non-conformant-purge" });
      continue;
    }
    out.push({ attestation_id: e.attestation_id, reading: "orphan" });  // Housekeeping 4 and 5
  }
  return out;
}
