import { openStore } from "../src/audit_store.ts";
import { openBusinessStore } from "../src/store.ts";
import { manualSeam } from "../src/seam.ts";
import { Faults } from "../src/faults.ts";
import { Vault } from "../src/vault.ts";
import { shredder } from "../src/erasure.ts";
import { actorIdentity } from "../src/audit_atoms.ts";
import { AuditTrail, CriticalSection } from "../src/audit_trail.ts";
import { type Config, DefensibleRetention } from "../src/composition.ts";

export const DAY = 86_400_000;
export const BOUND = 60_000;                        // retention completion bound
export const POLICIES = { p_30d: { ref: "p_30d", durationMs: 30 * DAY, maxPurgeDelayMs: DAY }, p_10d: { ref: "p_10d", durationMs: 10 * DAY, maxPurgeDelayMs: DAY } };
export const AUDIT_POLICY = { ref: "audit_400d", durationMs: 400 * DAY, maxPurgeDelayMs: DAY };

export function config(over: Partial<Config> = {}): Config {
  return { holdCheckMode: "strict", policies: POLICIES, longestHoldMs: 365 * DAY, fieldCapBytes: 256, holdIdsCap: 2,
    serviceActor: "dr_service", serviceCredential: "svc_secret", retentionCompletionBoundMs: BOUND, compensationWindowMs: 3_600_000,
    reconciliationCadenceMs: 600_000, auditWriteLatencyMs: 1_000, clockOffsetAllowanceMs: 100, ...over };
}

export function world(over: Partial<Config> = {}) {
  const adb = openStore(), db = openBusinessStore(), seam = manualSeam(), f = new Faults(), v = new Vault();
  for (const [a, s] of [["dr_service", "svc_secret"], ["clerk", "clerk_secret"], ["counsel", "counsel_secret"], ["audit_op", "op_secret"]])
    actorIdentity.register(adb, a, s);
  const trail = AuditTrail.start(adb, seam, f, v, {
    retentionPolicy: AUDIT_POLICY.ref, policies: { [AUDIT_POLICY.ref]: AUDIT_POLICY }, sealCadence: { kind: "per-event" }, sealMechanism: "chained-hash",
    mechanismCredential: "", erasureMechanism: shredder(v, f), compensationWindowMs: 100_000, reconciliationCadenceMs: 60_000,
    reconciliationOperator: "audit_op", reconciliationOperatorCredential: "op_secret", payloadCap: 4096, attestationIdWidth: 16,
    recordActionCompletionBoundMs: 1_000, purgeCompletionBoundMs: 1_000, compensationClosureLatencyMs: 1_000, clockOffsetAllowanceMs: 100,
    criticalSection: new CriticalSection() });
  const dr = DefensibleRetention.start({ trail, db: adb, v }, db, seam, f, config(over));
  const place = (record_ref = "txn-1", policy_ref = "p_30d") => {
    const r = dr.place_record_under_retention(record_ref, policy_ref, "clerk", "clerk_secret");
    if (!("ok" in r)) throw new Error(JSON.stringify(r));
    return r.ok;
  };
  const hold = (record_ref = "txn-1") => {
    const r = dr.place_hold(record_ref, "counsel", "counsel_secret", "SEC inquiry", "case-7");
    if (!("ok" in r)) throw new Error(JSON.stringify(r));
    return r.ok;
  };
  const purge = (id: string) => dr.purge_record(id, "clerk", "clerk_secret");
  const trailOf = (action: string) => dr.events().filter((e) => e.action_ref === action).map((e) => e.data!);
  const retention = (id: string) => db.prepare("SELECT * FROM retention WHERE retention_id = ?").get<{ state: string }>(id)!;
  return { adb, db, seam, f, v, trail, dr, place, hold, purge, trailOf, retention };
}
