import { openStore } from "../src/store.ts";
import { manualSeam } from "../src/seam.ts";
import { Faults } from "../src/faults.ts";
import { Vault } from "../src/vault.ts";
import { shredder } from "../src/erasure.ts";
import { actorIdentity } from "../src/atoms.ts";
import { type AuditRecord, AuditTrail, type Config, CriticalSection } from "../src/composition.ts";

export const DAY = 86_400_000;
export const POLICY = { ref: "p_30d", durationMs: 30 * DAY, maxPurgeDelayMs: DAY };
export const BOUND = 1_000;                  // record action and purge completion bounds
export const PAST_BOUND = BOUND + 100 + 1;   // past the bound plus the clock offset allowance

export function config(v: Vault, f: Faults, over: Partial<Config> = {}): Config {
  return {
    retentionPolicy: POLICY.ref, policies: { [POLICY.ref]: POLICY }, sealCadence: { kind: "per-event" }, sealMechanism: "chained-hash",
    mechanismCredential: "", erasureMechanism: shredder(v, f), compensationWindowMs: 100_000, reconciliationCadenceMs: 60_000,
    reconciliationOperator: "audit_op", reconciliationOperatorCredential: "op_secret", payloadCap: 4096, attestationIdWidth: 16,
    recordActionCompletionBoundMs: BOUND, purgeCompletionBoundMs: BOUND, compensationClosureLatencyMs: 1_000, clockOffsetAllowanceMs: 100,
    criticalSection: new CriticalSection(), ...over,
  };
}

export function world(over: (v: Vault, f: Faults) => Partial<Config> = () => ({})) {
  const db = openStore(), seam = manualSeam(), f = new Faults(), v = new Vault();
  actorIdentity.register(db, "audit_op", "op_secret");
  actorIdentity.register(db, "alice", "alice_secret");
  const trail = AuditTrail.start(db, seam, f, v, config(v, f, over(v, f)));
  const rec = (action_ref = "doc.edit", data: Record<string, unknown> = { doc: "d1" }) => {
    const r = trail.record_action(action_ref, "alice", "alice_secret", data);
    if (!("ok" in r)) throw new Error(JSON.stringify(r));
    return r.ok;
  };
  // The presentation a verifier brings: the covering seal's record set, rendered from the log.
  const presentation = (event_id: string) => {
    const s = trail.coveringSeal(trail.seqOf(event_id)!)!;
    return db.prepare("SELECT event_id FROM event WHERE seq BETWEEN ? AND ? ORDER BY seq").all<{ event_id: string }>(s.first_seq, s.last_seq)
      .map((e) => v.open(`ev:${e.event_id}`, db.prepare("SELECT data FROM event WHERE event_id = ?").get<{ data: string }>(e.event_id)!.data)!);
  };
  const ops = () => db.prepare("SELECT event_id FROM event ORDER BY seq").all<{ event_id: string }>()
    .map((e) => trail.read_record(e.event_id)).filter((r): r is AuditRecord => r !== "not-known" && r.actor_ref === "audit_op");
  return { db, seam, f, v, trail, rec, presentation, ops };
}
