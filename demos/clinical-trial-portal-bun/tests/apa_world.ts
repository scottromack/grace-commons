// The world the Attributed Permissions Admin tests build: an Actor Identity instance whose registry and mechanism a test can move, a Permissions instance, and the composition.
import { generateKeyPairSync } from "node:crypto";
import { Store } from "../src/store.ts";
import { testSeam } from "../src/seam.ts";
import { ActorIdentity, ed25519, type RegistryAnswer, type Check } from "../src/actor_identity.ts";
import { Permissions } from "../src/permissions.ts";
import { AttributedPermissionsAdmin, type AdminConfig } from "../src/attributed_permissions_admin.ts";

export const PREFIX = "apa:";

export const apaWorld = (store: Store) => async (o: Partial<AdminConfig> & { permissionsCap?: number } = {}) => {
  const seam = testSeam("2026-09-01T10:00:00.000Z");
  const px = `apa_${crypto.randomUUID().replaceAll("-", "_")}_`;
  const book = new Map<string, RegistryAnswer>();
  const registry = { unreachable: false };
  const mech = { unavailable: false };
  const actors = await ActorIdentity.open(store, seam, (r) => (registry.unreachable ? { answer: "unreachable" } : book.get(r) ?? { answer: "unknown-actor" }), {
    ...ed25519,
    credentialCheck: (c, m): Check => (mech.unavailable ? "unavailable" : ed25519.credentialCheck(c, m)),
  });
  const grants = `${px}grants`;
  const perms = await Permissions.open(store, seam, { table: grants, ...(o.permissionsCap ? { stringCap: o.permissionsCap } : {}) });
  const alerts: { arm: string; action: string }[] = [];
  const purged = new Set<string>();
  const admin = await AttributedPermissionsAdmin.open(store, seam, { permissions: perms, actors }, {
    namespacePrefix: PREFIX, clockOffsetAllowanceMs: 50, retentionHorizonMs: 7 * 365 * 86_400_000,
    purgeRecord: async (id) => purged.has(id), alert: (a) => alerts.push(a), ...o,
  });
  const person = () => {
    const k = generateKeyPair();
    const ref = `admin-${crypto.randomUUID()}`;
    book.set(ref, { answer: "material", current: k.pub });
    return { ref, priv: k.priv };
  };
  const a = person();
  const attestations = async () => actors.read();
  const entries = async (table: "grant_attribution" | "revocation_attribution" | "orphan_log") => store.read<Record<string, unknown>>(`SELECT * FROM ${table}`);
  const mine = async (table: "grant_attribution" | "revocation_attribution" | "orphan_log", ids: string[]) => (await entries(table)).filter((r) => ids.includes(r._id as string));
  return { seam, px, book, registry, mech, actors, perms, grants, admin, alerts, purged, person, a, attestations, entries, mine, store };
};

function generateKeyPair() {
  const k = generateKeyPairSync("ed25519");
  return { pub: k.publicKey.export({ format: "der", type: "spki" }).toString("base64"), priv: k.privateKey.export({ format: "der", type: "pkcs8" }).toString("base64") };
}
