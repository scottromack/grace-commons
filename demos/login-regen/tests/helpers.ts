import { openStore } from "../src/store.ts";
import { manualSeam } from "../src/seam.ts";
import { Faults } from "../src/faults.ts";
import { AuditTrail } from "../src/audit_trail.ts";
import { actorIdentity } from "../src/substrate_atoms.ts";
import { credential } from "../src/atoms.ts";
import { type Config, Login } from "../src/composition.ts";

export const CONFIG: Config = {
  defaultSessionDurationMs: 3_600_000, issuerRefs: ["login_svc"], reconciliationWindowMs: 600_000, reconciliationCadenceMs: 300_000,
  loginCompletionBoundMs: 60_000, auditFailedLogins: true, auditHorizonMs: 7 * 365 * 86_400_000,
  serviceActor: "login_service", serviceCredential: "login_service_secret",
};
export const AFTER_BOUND = CONFIG.loginCompletionBoundMs + 1;

export function world(config: Partial<Config> = {}) {
  const db = openStore();
  const seam = manualSeam();
  const f = new Faults();
  const audit = new AuditTrail(db, seam, f, { referenceCap: 64, payloadCap: 4096, attestationIdWidth: 16,
    retentionPolicy: { ref: "sox_7_year", durationMs: 7 * 365 * 86_400_000, maxPurgeDelayMs: 30 * 86_400_000 } });
  actorIdentity.register(db, "login_service", "login_service_secret");
  const cred = credential.register(db, seam, "user_u91", "password", "correct horse") as { ok: string };
  const login = Login.start(db, seam, f, audit, { ...CONFIG, ...config });
  const good = () => login.login("user_u91", "password", "correct horse", "login_svc");
  const token = () => { const r = good(); if (!("ok" in r)) throw new Error(JSON.stringify(r)); return r.ok.session_token; };
  const of = (action_ref: string) => login.events().filter((e) => e.action_ref === action_ref);
  return { db, seam, f, audit, login, cred_id: cred.ok, good, token, of };
}
