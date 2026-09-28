import { openStore } from "../src/audit_store.ts";
import { openBusinessStore } from "../src/store.ts";
import { manualSeam } from "../src/seam.ts";
import { Faults } from "../src/faults.ts";
import { Vault } from "../src/vault.ts";
import { shredder } from "../src/erasure.ts";
import { actorIdentity, eventLog } from "../src/audit_atoms.ts";
import { AuditTrail, CriticalSection } from "../src/audit_trail.ts";
import { type Config, CustomerOnboarding } from "../src/composition.ts";
import { partyIdentity } from "../src/atoms.ts";

export const DAY = 86_400_000;
export const CONFIG: Config = {
  policies: { active_1y: { ref: "active_1y", durationMs: 400 * DAY, maxPurgeDelayMs: DAY }, post_5y: { ref: "post_5y", durationMs: 5 * 365 * DAY, maxPurgeDelayMs: DAY } },
  activeRelationshipPolicy: "active_1y", postClosurePolicy: "post_5y", monitoringIntervalMs: 365 * DAY, schedulerToleranceMs: 7 * DAY,
  adverseTriggerTypes: ["sanctions-match", "pep-status-change", "adverse-media"], triggerSetCap: 16,
};
export const FIELDS = { name: "Ada Obi", date_of_birth: "1990-04-02", document_type: "passport", document_ref: "P123" };

export function world(over: Partial<Config> = {}) {
  const adb = openStore(), db = openBusinessStore(), seam = manualSeam(), f = new Faults(), v = new Vault();
  for (const [a, s] of [["officer", "officer_secret"], ["screening", "screen_secret"], ["audit_op", "op_secret"]]) actorIdentity.register(adb, a, s);
  const trail = AuditTrail.start(adb, seam, f, v, {
    retentionPolicy: "audit_7y", policies: { audit_7y: { ref: "audit_7y", durationMs: 7 * 365 * DAY, maxPurgeDelayMs: DAY } }, sealCadence: { kind: "per-event" },
    sealMechanism: "chained-hash", mechanismCredential: "", erasureMechanism: shredder(v, f), compensationWindowMs: 100_000, reconciliationCadenceMs: 60_000,
    reconciliationOperator: "audit_op", reconciliationOperatorCredential: "op_secret", payloadCap: 8192, attestationIdWidth: 16,
    recordActionCompletionBoundMs: 1_000, purgeCompletionBoundMs: 1_000, compensationClosureLatencyMs: 1_000, clockOffsetAllowanceMs: 100, criticalSection: new CriticalSection() });
  const co = new CustomerOnboarding(trail, db, seam, f, { ...CONFIG, ...over });
  const events = () => eventLog.read(adb, v, 1).map((e) => { const env = e.data === null ? null : JSON.parse(e.data); return { action: env?.action_ref ?? "", data: env?.data ?? null }; });
  co.trailRead = events;
  const of = (action: string) => events().filter((e) => e.action === `customer-onboarding.${action}`).map((e) => e.data!);
  const state = (party_id: string) => (partyIdentity.read(db, f, party_id) as { ok: { state: string }[] }).ok[0].state;
  const open = () => { const r = co.initiate_onboarding(undefined, FIELDS, "officer", "officer_secret", "active_1y"); if (!("ok" in r)) throw new Error(JSON.stringify(r)); return r.ok; };
  const partyOf = (case_id: string) => co.monitoring(case_id)!.party_id;
  const verify = (case_id: string) => co.record_verification(case_id, "officer", "manual-review", "passed", "ev-1", "officer_secret");
  const trig = (case_id: string, type = "sanctions-match", ref = "ofac-hit-1") => co.trigger_monitoring_review(case_id, type, ref, "screening", "screen_secret");
  return { adb, db, seam, f, v, trail, co, events, of, state, open, partyOf, verify, trig };
}
