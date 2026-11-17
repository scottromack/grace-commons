// The world the Recoverable Invocation tests build: a journal over Audit Trail whose answers a test scripts, a Lease host as the act section, an act probe a test answers.
import { expect } from "bun:test";
import { generateKeyPairSync } from "node:crypto";
import { Store, Unavailable } from "../src/store.ts";
import { testSeam } from "../src/seam.ts";
import { EventLog, type LoggedEvent } from "../src/event_log.ts";
import { ActorIdentity, type RegistryAnswer } from "../src/actor_identity.ts";
import { RetentionWindow } from "../src/retention_window.ts";
import { LeaseHost } from "../src/lease.ts";
import { AuditTrail } from "../src/audit_trail.ts";
import { RecoverableInvocation, type Journal, type JournalAnswer, type KindBinding, type ProbeAnswer, type RecoverableInvocationConfig } from "../src/recoverable_invocation.ts";

export const DAY = 86_400_000;
export const KIND = "disclosure";
export const OUT = "disclosure.disclosed";

type Mode = "real" | "unavailable" | "rf2" | "rf3-landed" | "rf3-nothing" | "lost-landed" | "lost-nothing" | "step4-landed" | "step4-nothing" | "step1";

export const worldFor = (store: Store) => async (o: { service?: string | null; repeatable?: boolean; readBoundMs?: number; settle?: boolean; sweep?: boolean; second?: boolean } = {}) => {
  const seam = testSeam("2026-06-01T08:00:00.000Z");
  const px = `ri_${crypto.randomUUID().replaceAll("-", "_")}_`;
  const book = new Map<string, RegistryAnswer>();
  const log = await EventLog.open(store, seam, { name: `trail-${crypto.randomUUID()}` });
  const actors = await ActorIdentity.open(store, seam, (r) => book.get(r) ?? { answer: "unknown-actor" });
  const retention = await RetentionWindow.open(store, seam, () => ({ answer: "policy", policy: { durationMs: 7 * 365 * DAY, maxPurgeDelayMs: 30 * DAY } }), { resolutionMs: 1000, prefix: px } as never);
  const at = await AuditTrail.open(store, seam, { log, actors, retention }, { retentionPolicy: "seven-years", reconciliationOperator: "op" });
  const person = () => {
    const k = generateKeyPairSync("ed25519");
    const ref = `actor-${crypto.randomUUID()}`;
    book.set(ref, { answer: "material", current: k.publicKey.export({ format: "der", type: "spki" }).toString("base64") });
    return { ref, priv: k.privateKey.export({ format: "der", type: "pkcs8" }).toString("base64") };
  };
  const a = person();
  const stranger = person();
  const svc = person();
  const realLease = await LeaseHost.open(store, seam, { prefix: px, pollMs: 50, sleep: async (ms) => { seam.advance(ms); } });

  // The journal, with answers a test scripts per call; the calls it saw; the log read a test can fail.
  const script: Mode[] = [];
  const calls: string[] = [];
  let perCall = 0;
  const reads = { mode: "ok" as "ok" | "unavailable" | "invalid-query" | "hang" };
  const journal: Journal = {
    log: {
      payloadCap: log.payloadCap,
      read: async (q: Parameters<EventLog["read"]>[0]) => {
        if (reads.mode === "unavailable") throw new Unavailable();
        if (reads.mode === "invalid-query") return { refused: "invalid-query" } as const;
        if (reads.mode === "hang") return new Promise<LoggedEvent[]>(() => {});
        return log.read(q);
      },
    } as unknown as EventLog,
    recordAction: async (ref, actor, cred, data): Promise<JournalAnswer> => {
      calls.push(ref);
      seam.advance(perCall);
      const m = script.shift() ?? "real";
      const real = () => at.recordAction(ref, actor, cred, data) as Promise<JournalAnswer>;
      switch (m) {
        case "real": return real();
        case "unavailable": throw new Unavailable();
        case "rf2": return { refused: "recording-failure", step: "step-2" };
        case "rf3-landed": await real(); return { refused: "recording-failure", step: "step-3" };
        case "rf3-nothing": return { refused: "recording-failure", step: "step-3" };
        case "lost-landed": await real(); return "no-answer";
        case "lost-nothing": return "no-answer";
        case "step4-landed": await real(); return { refused: "invalid-request", step: "step-4", committed_ids: [] };
        case "step4-nothing": return { refused: "invalid-request", step: "step-4", committed_ids: [] };
        case "step1": return { refused: "invalid-request", step: "step-1", committed_ids: [] };
      }
    },
  };

  // The act section: the real Lease host, with the answers a test can change.
  const sec = { takeUnavailable: false, takeThrows: false, releaseThrows: false, remaining: null as null | ((n: number) => number | "none"), remainingCalls: 0, taken: [] as string[], released: [] as string[] };
  const actSection = {
    take: async (key: string, holder: string, ms: number) => {
      sec.taken.push(key);
      if (sec.takeThrows) throw new Error("storage-failure");
      if (sec.takeUnavailable) return "unavailable" as const;
      return realLease.take(key, holder, ms);
    },
    remaining: async (key: string, holder: string) => {
      const n = ++sec.remainingCalls;
      const o = sec.remaining?.(n);
      if (o !== undefined && o !== null) return o === "none" ? ("none" as const) : { remaining_ms: o };
      return realLease.remaining(key, holder);
    },
    release: async (key: string, holder: string) => {
      sec.released.push(key);
      if (sec.releaseThrows) throw new Error("storage-failure");
      return realLease.release(key, holder);
    },
    tryTake: realLease.tryTake.bind(realLease),
  } as unknown as LeaseHost;

  const alerts: { invocation_id: string; arm: string }[] = [];
  const surfaced: { arm: string; kind?: string; act_key?: string; invocation_id?: string; detail?: unknown }[] = [];
  // The act probe a test answers: what it is asked and what it says (act probe 1).
  const probe = { answer: { answer: "not-committed" } as ProbeAnswer | "throw", asked: [] as { act_key: string; payload: Record<string, unknown> }[] };
  const binding: KindBinding = {
    invocationCompletionBoundMs: 10_000,
    outcomes: [OUT],
    repeatable: o.repeatable ?? false,
    serviceIdentity: o.service === undefined ? svc.ref : o.service,
    retentionPeriodMs: 365 * DAY,
    outcomeEnvelopeBytes: 200,
    serviceCredential: o.service === null ? null : svc.priv,
    settlingPeriodMs: 100_000,
    actProbe: async (act_key, payload) => {
      probe.asked.push({ act_key, payload });
      if (probe.answer === "throw") throw new Error("the database rejected the read");
      return probe.answer;
    },
  };
  const refund: KindBinding = { ...binding, outcomes: ["refund.paid"], serviceIdentity: null, serviceCredential: null };   // a second kind that declares no service identity (a mixed instance, reconcile 3 to 5)
  const cfg: RecoverableInvocationConfig = {
    journal, actSection, bindings: { [KIND]: binding, ...(o.second ? { refund } : {}) },
    compliance: { hardAlert: (x) => alerts.push(x), surface: (x) => surfaced.push(x) },
    journalWriteBoundMs: 1000, pauseBoundMs: 100, commitRoundTripMs: 2000, clockAllowanceMs: 50,
    readBoundMs: o.readBoundMs ?? (o.sweep ? 500 : undefined), intentCandidatesCap: 5, referenceLengthCap: 128,
    sleep: async (ms) => { seam.advance(ms); },
    ...(o.sweep ? { sweep: { closureWindowMs: 200_000, runBoundMs: 20_000, sweepCadenceMs: 30_000, closureLatencyMs: 5000, probeRoundTripMs: 500, wait: (ms: number) => new Promise<void>((r) => setTimeout(r, Math.min(ms, 300))) } } : {}),   // the five conditions of Instance start hold; a stalled step-1 read gives up after 300 real milliseconds
  };
  await log.read({ sequence: { from: 1 } });                                                                       // warm the connection: the sweep world's read bound is real time (500 ms) and a cold first read can pass it
  const ri = await RecoverableInvocation.start(seam, cfg);
  const records = async () => ((await log.read({ sequence: { from: 1 } })) as LoggedEvent[]).map((e) => ({ seq: e.sequence_number, ...(e.data as { action_ref: string; data: Record<string, unknown> }) }));
  const open = (key = "act-1", data: unknown = { pairing: "p1" }) => ri.open(KIND, key, a.ref, a.priv, data);
  /** Another writer's closing, written straight to the journal (an operator's or the sweep's, not rendered here). */
  const closing = (ref: string, inv: string, key: string, extra: Record<string, unknown> = {}) => at.recordAction(ref, svc.ref, svc.priv, { invocation_id: inv, kind: KIND, act_key: key, intent_event_id: "x", ...extra });
  return { seam, at, log, ri, a, stranger, svc, script, calls, reads, sec, alerts, surfaced, records, open, closing, setPerCall: (n: number) => { perCall = n; }, realLease, binding, probe, cfg, refund };
};

export const ok = <T>(r: T | { refused: string }): T => { expect((r as { refused?: string }).refused).toBeUndefined(); return r as T; };
export const key = (k = "act-1") => JSON.stringify([KIND, k]);
