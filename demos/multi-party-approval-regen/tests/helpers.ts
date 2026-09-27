import { openStore } from "../src/store.ts";
import { manualSeam } from "../src/seam.ts";
import { Faults } from "../src/faults.ts";
import { AuditTrail } from "../src/audit_trail.ts";
import { actorIdentity, permissions } from "../src/atoms.ts";
import { type Config, MultiPartyApproval, type Quorum, SCOPES } from "../src/composition.ts";

export const CONFIG: Config = {
  approverSetMinimum: 1, approverSetUniqueness: true, allowedQuorumRules: ["all-of-N", "M-of-N", "one-of-N"],
  fieldLengthCap: 200, idWidth: 16,
  decisionCompletionBoundMs: 60_000, compensationWindowMs: 600_000, reconciliationCadenceMs: 300_000, outcomeWriteLatencyMs: 10_000,
  auditHorizonMs: 7 * 365 * 86_400_000, serviceActor: "mpa_service", serviceCredential: "mpa_service_secret",
};
export const ALL: Quorum = { rule: "all-of-N" };
export const TWO: Quorum = { rule: "M-of-N", m: 2 };
export const ONE: Quorum = { rule: "one-of-N" };
export const APPROVERS = ["chen", "park", "walsh"];

export function world(config: Partial<Config> = {}) {
  const db = openStore();
  const seam = manualSeam();
  const f = new Faults();
  const audit = new AuditTrail(db, seam, f, { referenceCap: 64, payloadCap: 4096, attestationIdWidth: 16,
    retentionPolicy: { ref: "sox_7_year", durationMs: 7 * 365 * 86_400_000, maxPurgeDelayMs: 30 * 86_400_000 } });
  for (const a of ["morgan", "ross", "auditor", "mallory", ...APPROVERS]) actorIdentity.register(db, a, `${a}-secret`);
  actorIdentity.register(db, "mpa_service", "mpa_service_secret");
  for (const s of [SCOPES.initiate, SCOPES.withdraw, SCOPES.read]) permissions.grant(db, seam, "morgan", s);
  for (const s of [SCOPES.initiate, SCOPES.withdraw]) permissions.grant(db, seam, "ross", s);
  permissions.grant(db, seam, "auditor", SCOPES.read);
  const mpa = MultiPartyApproval.start(db, seam, f, audit, { ...CONFIG, ...config });
  const cred = (a: string) => `${a}-secret`;
  const open = (q: Quorum = ALL, approvers = APPROVERS, by = "morgan") => {
    const r = mpa.initiate_chain(by, cred(by), "je-2026-0441", "financial:journal-entry:post", approvers, q, "Q1 close");
    if (!("ok" in r)) throw new Error(JSON.stringify(r));
    return { chain_id: r.ok, steps: mpa.stepList(r.ok) };
  };
  const events = () => audit.log_read().filter((e) => e.envelope).map((e) => ({ id: e.event_id, seq: e.seq, ...e.envelope! }));
  const of = (action_ref: string) => events().filter((e) => e.action_ref === action_ref);
  return { db, seam, f, audit, mpa, cred, open, events, of };
}
