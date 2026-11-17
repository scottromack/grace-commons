// The world the External Onboarding tests build: Audit Trail as the substrate behind a trail whose plans a test can script, an Invitation instance, and the composition.
import { generateKeyPairSync } from "node:crypto";
import { Store, Unavailable, type Stmt } from "../src/store.ts";
import { testSeam } from "../src/seam.ts";
import { EventLog, type LoggedEvent } from "../src/event_log.ts";
import { ActorIdentity, type RegistryAnswer } from "../src/actor_identity.ts";
import { RetentionWindow } from "../src/retention_window.ts";
import { AuditTrail, type RecordRefusal } from "../src/audit_trail.ts";
import { Invitation } from "../src/invitation.ts";
import { PartyIdentity } from "../src/party_identity.ts";
import { Credential } from "../src/credential.ts";
import { LeaseHost } from "../src/lease.ts";
import { RecoverableInvocation, type Journal, type JournalAnswer } from "../src/recoverable_invocation.ts";
import { ExternalOnboarding, onboardingBinding, onboardingProbe, ONBOARDING, type Trail } from "../src/external_onboarding.ts";

export const DAY = 86_400_000;
/** A password credential type: argon2id derives the verifier (cheap parameters, a test's own). */
export const password = {
  derive: async (m: string) => (m.length > 200 ? null : Bun.password.hash(m.normalize("NFC"), { algorithm: "argon2id", memoryCost: 1024, timeCost: 1 })),
  check: (p: string, v: string) => Bun.password.verify(p.normalize("NFC"), v),
};
/** What the journal Recoverable Invocation writes through answers at its next call, scripted by a test; the default is Audit Trail's own answer. */
export type JournalMode = "real" | "rf2" | "step1" | "lost-nothing";
export type Scripted = "unavailable" | { refusal: RecordRefusal; keep: { text: string; params: never[] }[] };

export const eoWorld = (store: Store) => async (o: { payloadCap?: number; commitRoundTripMs?: number; widths?: { invitationToken: number; partyId: number; credentialId: number; eventId: number } } = {}) => {
  const seam = testSeam("2026-09-01T10:00:00.000Z");
  const ids: string[] = [];                                                                                       // ids a test makes the next mint answer (the party and credential ids of one onboarding)
  seam.idMaterial = () => ids.shift() ?? crypto.randomUUID();
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
  const parties = await PartyIdentity.open(store, seam, { table: `${px}parties`, headTable: `${px}party_heads` });
  const credentials = await Credential.open(store, seam, { types: { password, pin: password }, defaultValidityMs: null });
  const widths = o.widths ?? { invitationToken: 43, partyId: 36, credentialId: 36, eventId: 36 };

  // The Recoverable Invocation instance serving the composition writes to the same Audit Trail instance (Composes 17, 18).
  const jscript: JournalMode[] = [];
  const jreads = { mode: "ok" as "ok" | "unavailable" };
  const journal: Journal = {
    log: { payloadCap: log.payloadCap, read: async (q: Parameters<EventLog["read"]>[0]) => { if (jreads.mode === "unavailable") throw new Unavailable(); return log.read(q); } } as unknown as EventLog,
    readRecord: (id) => at.readRecord(id),
    recordAction: async (ref, actor, cred, data): Promise<JournalAnswer> => {
      const m = jscript.shift() ?? "real";
      if (m === "rf2") return { refused: "recording-failure", step: "step-2" };
      if (m === "step1") return { refused: "invalid-request", step: "step-1", committed_ids: [] };
      if (m === "lost-nothing") return "no-answer";
      return at.recordAction(ref, actor, cred, data) as Promise<JournalAnswer>;
    },
  };
  const lease = await LeaseHost.open(store, seam, { prefix: px, pollMs: 50, sleep: async (ms) => { seam.advance(ms); } });
  const sec = { released: [] as string[], takeUnavailable: false, remaining: null as null | ((n: number) => number | "none"), calls: 0 };
  const actSection = {
    take: async (key: string, holder: string, ms: number) => (sec.takeUnavailable ? ("unavailable" as const) : lease.take(key, holder, ms)),
    remaining: async (k: string, h: string) => { const o = sec.remaining?.(++sec.calls); return o === undefined || o === null ? lease.remaining(k, h) : o === "none" ? ("none" as const) : { remaining_ms: o }; },
    release: (k: string, h: string) => { sec.released.push(k); return lease.release(k, h); },
  } as unknown as LeaseHost;
  const bindingCfg = { onboardingCompletionBoundMs: 10_000, auditHorizonMs: 7 * 365 * DAY, settlingPeriodMs: 100_000, referenceLengthCap: 128, mintedIdWidths: widths };
  const probe = onboardingProbe({ invitation, parties, credentials });
  const probed: { act_key: string; intent: Record<string, unknown>; actor: string }[] = [];
  const binding = onboardingBinding({ ...bindingCfg, probe: async (k, i, a) => { probed.push({ act_key: k, intent: i, actor: a }); return probe(k, i, a); } });
  const surfaced: { arm: string; kind?: string; act_key?: string; invocation_id?: string; detail?: unknown }[] = [];
  const hard: { invocation_id: string; arm: string }[] = [];
  const ri = await RecoverableInvocation.start(seam, {
    journal, actSection, bindings: { [ONBOARDING]: binding },
    compliance: { hardAlert: (x) => hard.push(x), surface: (x) => surfaced.push(x) },
    journalWriteBoundMs: 1000, pauseBoundMs: 100, commitRoundTripMs: 2000, clockAllowanceMs: 50, readBoundMs: 500, intentCandidatesCap: 5, referenceLengthCap: 128,
    sleep: async (ms) => { seam.advance(ms); },
    sweep: { closureWindowMs: 200_000, runBoundMs: 20_000, sweepCadenceMs: 30_000, closureLatencyMs: 5000, probeRoundTripMs: 500, wait: (ms: number) => new Promise<void>((r) => setTimeout(r, Math.min(ms, 300))) },
  });
  await log.read({ sequence: { from: 1 } });
  const commits: { run: null | ((stmts: Stmt[], real: () => Promise<void>) => Promise<void>) } = { run: null };       // what the onboarding transaction's commit does in a test
  const eoStore = Object.assign(Object.create(store), { commit: (stmts: Stmt[]) => (commits.run ? commits.run(stmts, () => store.commit(stmts)) : store.commit(stmts)) }) as Store;
  const eoCfg = {
    referenceLengthCap: 128, onboardingCompletionBoundMs: 10_000, clockOffsetAllowanceMs: 50, commitRoundTripMs: o.commitRoundTripMs ?? 2000,
    mintedIdWidths: widths,
    alert: (a: { arm: string; action: string; step: string }) => alerts.push(a),
  };
  const eo = await ExternalOnboarding.open(eoStore, seam, { invitation, parties, credentials, trail, ri }, eoCfg);
  const inviter = person();
  const enroller = person();
  const service = person();
  const events = async () => ((await log.read({ sequence: { from: 1 } })) as LoggedEvent[]).map((e) => ({ seq: e.sequence_number, ...(e.data as { action_ref: string; actor_ref: string; data: Record<string, unknown> }) }));
  const invitations = () => store.read<Record<string, unknown>>(`SELECT * FROM ${px}invitations`);
  const attestations = (actor: string) => store.read(`SELECT * FROM attestations WHERE actor_ref = $1`, [actor]);
  /** A pending invitation, issued through the composition. */
  const issue = async (ctx = "org::acme") => {
    const r = await eo.invite(inviter.ref, null, ctx, 3600, inviter.priv) as { invitation_token: string };
    return r.invitation_token;
  };
  return { seam, at, log, invitation, parties, credentials, ri, lease, jscript, jreads, sec, ids, commits, binding, probe, probed, surfaced, hard, eoCfg, eo, inviter, enroller, service, person, policy, script, hook, plans, reads, alerts, events, invitations, attestations, issue, trail, store };
};
