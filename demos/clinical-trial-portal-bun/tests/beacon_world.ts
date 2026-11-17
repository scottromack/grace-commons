// The world Beacon's own domain tests build: Audit Trail as the substrate, Permissions, the domain, and people who hold the permissions a test gives them.
import { generateKeyPairSync } from "node:crypto";
import { Store } from "../src/store.ts";
import { testSeam } from "../src/seam.ts";
import { EventLog, type LoggedEvent } from "../src/event_log.ts";
import { ActorIdentity, type RegistryAnswer } from "../src/actor_identity.ts";
import { RetentionWindow } from "../src/retention_window.ts";
import { AuditTrail } from "../src/audit_trail.ts";
import { Permissions } from "../src/permissions.ts";
import { BeaconDomain, type PermissionCode } from "../src/beacon_domain.ts";
import { type Trail } from "../src/external_onboarding.ts";

const DAY = 86_400_000;

export const beaconWorld = (store: Store) => async () => {
  const seam = testSeam("2026-09-01T10:00:00.000Z");
  const px = `bc_${crypto.randomUUID().replaceAll("-", "_")}_`;
  const book = new Map<string, RegistryAnswer>();
  const log = await EventLog.open(store, seam, { name: `bc-${crypto.randomUUID()}` });
  const actors = await ActorIdentity.open(store, seam, (r) => book.get(r) ?? { answer: "unknown-actor" });
  const retention = await RetentionWindow.open(store, seam, () => ({ answer: "policy", policy: { durationMs: 2555 * DAY, maxPurgeDelayMs: 30 * DAY } }), { resolutionMs: 1000, prefix: px } as never);
  const at = await AuditTrail.open(store, seam, { log, actors, retention }, { retentionPolicy: "seven-years", reconciliationOperator: "op" });
  const perms = await Permissions.open(store, seam, { table: `${px}grants` });
  const trail: Trail = { log: { payloadCap: log.payloadCap, read: (q) => log.read(q) }, index: (s) => at.index(s), plan: (a, r, c, d, h = 0) => at.plan(a, r, c, d, h) };
  const domain = await BeaconDomain.open(store, seam, { permissions: perms, trail }, { prefix: px });
  /** A person with an actor reference, a key, and the permissions given. */
  const person = async (...held: PermissionCode[]) => {
    const k = generateKeyPairSync("ed25519");
    const ref = `person-${crypto.randomUUID()}`;
    book.set(ref, { answer: "material", current: k.publicKey.export({ format: "der", type: "spki" }).toString("base64") });
    for (const p of held) await perms.grant(ref, p);
    return { ref, priv: k.privateKey.export({ format: "der", type: "pkcs8" }).toString("base64") };
  };
  const events = async () => ((await log.read({ sequence: { from: 1 } })) as LoggedEvent[]).map((e) => ({ seq: e.sequence_number, ...(e.data as { action_ref: string; actor_ref: string; data: Record<string, unknown> }) }));
  return { seam, px, perms, domain, trail, person, events, log, at, store };
};
