// The world the External Onboarding tests build: Audit Trail as the substrate behind a trail whose plans a test can script, an Invitation instance, and the composition.
import { generateKeyPairSync } from "node:crypto";
import { Store, Unavailable } from "../src/store.ts";
import { testSeam } from "../src/seam.ts";
import { EventLog, type LoggedEvent } from "../src/event_log.ts";
import { ActorIdentity, type RegistryAnswer } from "../src/actor_identity.ts";
import { RetentionWindow } from "../src/retention_window.ts";
import { AuditTrail, type RecordRefusal } from "../src/audit_trail.ts";
import { Invitation } from "../src/invitation.ts";
import { ExternalOnboarding, type Trail } from "../src/external_onboarding.ts";

export const DAY = 86_400_000;
export type Scripted = "unavailable" | { refusal: RecordRefusal; keep: { text: string; params: never[] }[] };

export const eoWorld = (store: Store) => async (o: { payloadCap?: number; widths?: { invitationToken: number; partyId: number; credentialId: number; eventId: number } } = {}) => {
  const seam = testSeam("2026-09-01T10:00:00.000Z");
  const px = `eo_${crypto.randomUUID().replaceAll("-", "_")}_`;
  const book = new Map<string, RegistryAnswer>();
  const log = await EventLog.open(store, seam, { name: `eo-${crypto.randomUUID()}`, ...(o.payloadCap ? { payloadCap: o.payloadCap } : {}) });
  const actors = await ActorIdentity.open(store, seam, (r) => book.get(r) ?? { answer: "unknown-actor" });
  const retention = await RetentionWindow.open(store, seam, (ref) => (ref === "seven-years" ? { answer: "policy", policy: { durationMs: 7 * 365 * DAY, maxPurgeDelayMs: 30 * DAY } } : { answer: "not-found" }), { resolutionMs: 1000, prefix: px } as never);
  const policy: Record<string, string> = {};                                                                      // an action reference a test points at a policy the registry does not hold: a real step-4 refusal
  const at = await AuditTrail.open(store, seam, { log, actors, retention }, { retentionPolicy: (ref) => policy[ref] ?? "seven-years", reconciliationOperator: "op" });
  const invitation = await Invitation.open(store, seam, { ttlBounds: { min: 60, max: 30 * 86_400 }, defaultTtl: 604_800, table: `${px}invitations` });
  const person = () => {
    const k = generateKeyPairSync("ed25519");
    const ref = `actor-${crypto.randomUUID()}`;
    book.set(ref, { answer: "material", current: k.publicKey.export({ format: "der", type: "spki" }).toString("base64") });
    return { ref, priv: k.privateKey.export({ format: "der", type: "pkcs8" }).toString("base64") };
  };

  // The trail the composition sees: Audit Trail's plan, with the answers a test scripts per plan call (and the calls it saw, the log reads it made).
  const script: (Scripted | undefined)[] = [];
  const plans: { action: string; actor: string; ahead: number }[] = [];
  const reads: unknown[] = [];
  const alerts: { arm: string; action: string; step: string }[] = [];
  const hook: { run: null | ((action: string) => Promise<void>) } = { run: null };                              // what happens elsewhere while the composition plans: called before each plan
  const trail: Trail = {
    log: { payloadCap: log.payloadCap, read: async (q) => { reads.push(q); return log.read(q); } },
    index: (s) => at.index(s),
    plan: async (action, actor, cred, data, ahead = 0) => {
      plans.push({ action, actor, ahead });
      if (hook.run) await hook.run(action);
      const m = script.shift();
      if (m === "unavailable") throw new Unavailable();
      if (m) return m as never;
      return at.plan(action, actor, cred, data, ahead);
    },
  };
  const eo = await ExternalOnboarding.open(store, seam, { invitation, trail }, {
    referenceLengthCap: 128, onboardingCompletionBoundMs: 10_000, clockOffsetAllowanceMs: 50,
    mintedIdWidths: o.widths ?? { invitationToken: 43, partyId: 36, credentialId: 36, eventId: 36 },
    alert: (a) => alerts.push(a),
  });
  const inviter = person();
  const service = person();
  const events = async () => ((await log.read({ sequence: { from: 1 } })) as LoggedEvent[]).map((e) => ({ seq: e.sequence_number, ...(e.data as { action_ref: string; actor_ref: string; data: Record<string, unknown> }) }));
  const invitations = () => store.read<Record<string, unknown>>(`SELECT * FROM ${px}invitations`);
  const attestations = (actor: string) => store.read(`SELECT * FROM attestations WHERE actor_ref = $1`, [actor]);
  /** A pending invitation, issued through the composition. */
  const issue = async (ctx = "org::acme") => {
    const r = await eo.invite(inviter.ref, null, ctx, 3600, inviter.priv) as { invitation_token: string };
    return r.invitation_token;
  };
  return { seam, at, log, invitation, eo, inviter, service, person, policy, script, hook, plans, reads, alerts, events, invitations, attestations, issue, trail, store };
};
