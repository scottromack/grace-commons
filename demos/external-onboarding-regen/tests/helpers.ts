import { openStore } from "../src/store.ts";
import { manualSeam } from "../src/seam.ts";
import { Faults } from "../src/faults.ts";
import { AuditTrail } from "../src/audit_trail.ts";
import { actorIdentity } from "../src/substrate_atoms.ts";
import { type Config, CriticalSection, ExternalOnboarding, type OnboardInput } from "../src/composition.ts";

export const BOUND = 60_000, ALLOWANCE = 5_000;
export const AFTER = BOUND + ALLOWANCE + 1;
export function config(over: Partial<Config> = {}): Config {
  return { invitation: { ttlBoundsMs: [60_000, 30 * 86_400_000], defaultTtlMs: 7 * 86_400_000 }, onboardingCompletionBoundMs: BOUND,
    clockOffsetAllowanceMs: ALLOWANCE, auditHorizonMs: 365 * 86_400_000, idWidth: 16, criticalSection: new CriticalSection(120_000), ...over };
}
export function world(over: Partial<Config> = {}) {
  const db = openStore();
  const seam = manualSeam();
  const f = new Faults();
  const audit = new AuditTrail(db, seam, f, { referenceCap: 64, payloadCap: 2048, attestationIdWidth: 16,
    retentionPolicy: { ref: "hr_7_year", durationMs: 7 * 365 * 86_400_000, maxPurgeDelayMs: 30 * 86_400_000 } });
  for (const a of ["hr_admin", "onboarding_svc", "decline_svc"]) actorIdentity.register(db, a, `${a}-secret`);
  const cfg = config(over);
  const eo = ExternalOnboarding.start(db, seam, f, audit, cfg);
  const invite = () => { const r = eo.invite("hr_admin", "new.hire@example.com", "employee onboarding", undefined, "hr_admin-secret"); if (!("ok" in r)) throw new Error(JSON.stringify(r)); return r.ok; };
  const input = (token: string, o: Partial<OnboardInput> = {}): OnboardInput => ({ invitation_token: token, accepting_identity_ref: "idp:maya",
    name: "Maya Chen", date_of_birth: "1990-04-12", document_type: "passport", document_ref: "P1234567", credential_type: "password",
    credential_material: "correct horse", enrolling_actor_ref: "onboarding_svc", actor_credential: "onboarding_svc-secret", ...o });
  const of = (action_ref: string) => eo.events().filter((e) => e.action_ref === action_ref);
  return { db, seam, f, audit, eo, cfg, invite, input, of };
}
