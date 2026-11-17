// Recoverable Invocation — the protocol a regulated action follows around an act it cannot take back: [Open], [Close],
// [Refuse], [Yield], [Reconcile] (the sweep), [Resolve] (an operator's close), [Read Invocation], and the derived indexes
// they read.
// Rendered from compositions/recoverable-invocation.md (the page at the commit the entry names), with no code of
// any other render opened. A rule's label is in the comment where the code answers it.
//
// The composition's state is derived: open invocations, act closings, sweep closed ids and the sequence high water
// are rebuilt from one range read of the journal (Composition state), held in this process, and rebuilt at start
// (sequence high water 3, 6) and at every sweep run (4). The critical section is a Lease on the key (kind, act key);
// the journal is Audit Trail. The findings register is `FindingsRegister`, held in this process: the deployment
// persists it (findings 1, 2, 14), which this render does not.
//
// Every action of the page is rendered. [Resolve] and [Read Invocation] came last; the closings [Resolve] writes (an
// abandonment, an escalation, a superseding record) were read by [Close], [Refuse] and the sweep before it existed.
//
// Where the render does not meet the page: a release is Lease's own transaction, not joined to the record write
// (act section 21 asks that a release answering storage-failure leave nothing written standing; here the record
// stands and the action answers its position's arm, which is the safe side for [Close] and [Refuse]). The same
// holds at [Resolve] (resolve 22). It holds for reconcile 8 and 9: the sweep's two writes for one act (the recovery_intended and the outcome) are two
// journal transactions here, not one, and a release that fails after a closing counts the act skipped while the
// closing stands, which the next run finds and counts closed already.
import { type Seam, isBlank } from "./seam.ts";
import { canonical } from "./canonical.ts";
import { Unavailable } from "./store.ts";
import { type EventLog, type LoggedEvent } from "./event_log.ts";
import { type RecordRefusal, type AuditRecord } from "./audit_trail.ts";
import { type LeaseHost } from "./lease.ts";

/** What record_action answers; a reply that never came is "no-answer" (Primitive policy 32). */
export type JournalAnswer = { event_id: string } | RecordRefusal | "no-answer";
export interface Journal {
  recordAction(action_ref: string, actor_ref: string, credential: string, data?: unknown): Promise<JournalAnswer>;
  /** Audit Trail's read_record, read at [Resolve] alone (resolve 11): the record, "not-known", or a reply that never came (Capability requirement 9, 19). A call that throws Unavailable is state-unavailable. */
  readRecord(event_id: string): Promise<AuditRecord | "not-known" | "no-answer">;
  readonly log: EventLog;
}

/** The parameters an adopter binds once per act kind (Bindings). */
export interface KindBinding {
  /** The longest a conforming invocation takes, [Open]'s take to [Close]'s last write; the critical section's lease term (Term invocation completion bound). */
  invocationCompletionBoundMs: number;
  /** The enumerated outcome refs `<kind>.<outcome>`, with the kind prefix (journal 2). */
  outcomes: string[];
  /** `yes` or no (Term repeatable). */
  repeatable: boolean;
  /** The actor reference the sweep writes under, or null for none (Term service identity). */
  serviceIdentity: string | null;
  /** The kind's retention period, from its records' recording instants (Term retention period). */
  retentionPeriodMs: number;
  /** The largest outcome payload the kind can write, in bytes of its data (Term outcome envelope). */
  outcomeEnvelopeBytes: number;
  /** The credential the sweep writes under the service identity with; null where the kind has no service identity (Term service identity). */
  serviceCredential?: string | null;
  /** The adopter's act probe, read by act key and the intent's payload (Term act probe); absent reads as unavailable, since the sweep must not close an act whose database it cannot read (Invariant 5.10). */
  actProbe?: (act_key: string, intent_payload: Record<string, unknown>) => Promise<ProbeAnswer>;
  /** The time the adopter declares for an operator to settle an escalation (Term settling period). */
  settlingPeriodMs?: number;
}

/** act probe 1: exactly one of four. */
export type ProbeAnswer =
  | { answer: "committed"; outcome_action_ref: string; outcome_data: unknown }
  | { answer: "not-committed" }
  | { answer: "undecidable"; candidates: string[] }
  | { answer: "unavailable" };

export interface Compliance {
  /** A hard alert naming the invocation id and the arm that raised it (Term hard alert). */
  hardAlert(a: { invocation_id: string; arm: string }): void;
  /** A surfaced fault of the build or an old intent left open (open step 3.8c, Capability requirement 4); a sweep's report of an act under a kind with no service identity (reconcile 2e). */
  surface(a: { arm: string; kind?: string; act_key?: string; invocation_id?: string; detail?: unknown }): void;
}

/** The bounds the sweep adds (Instance start 4 to 8 are checked against them at start). */
export interface SweepConfig {
  /** The duration within which the sweep closes an act whose invocation died, from the intent's recording instant (Term closure window). */
  closureWindowMs: number;
  /** The bound from a run's start to the last closing it lands (Term run bound). */
  runBoundMs: number;
  /** The interval at which the sweep runs after the run at restart (Term sweep cadence). */
  sweepCadenceMs: number;
  /** One whole closure: re-read, act probe, recovery_intended, the closing, the index update (Term closure latency). */
  closureLatencyMs: number;
  /** The longest one act probe takes from issue to answer (Term probe round trip). */
  probeRoundTripMs: number;
  /** What a run waits on a stalled step-1 read (run bound 2): the default is a real wait, a test shortens it. */
  wait?: (ms: number) => Promise<void>;
}

export type FindingName = "journal-unavailable" | "store-unavailable" | "credential-refused" | "closure-at-risk" | "unbound-kind" | "escalated";
const ACT_FINDINGS = new Set<FindingName>(["closure-at-risk", "unbound-kind", "escalated"]);
const INSTANCE_FINDINGS = new Set<FindingName>(["journal-unavailable", "store-unavailable", "credential-refused"]);
export interface RunReading { run_id: string; at: string }
/** Term act finding: deduplicates on (invocation id, finding); carries no last seen and no span (findings 4). */
export interface ActFinding { finding: FindingName; kind: string; act_key: string; invocation_id: string; first_seen: RunReading; run_id: string }
/** Term instance finding: deduplicates on (finding, kind) while the record stands; kind may be absent (findings 5, 12). */
export interface InstanceFinding { finding: FindingName; kind: string | null; first_seen: RunReading; last_seen: RunReading; run_id: string; closed: boolean }

/** The register of Composition state's findings (findings 3 to 13). The deployment persists it (findings 1, 2, 14); this one lives in the process. */
export class FindingsRegister {
  readonly acts: ActFinding[] = [];
  readonly instances: InstanceFinding[] = [];
  /** An act finding: set once at the first surfacing, never moved (findings 7, 8). */
  act(finding: FindingName, kind: string, act_key: string, invocation_id: string, run: RunReading): void {
    if (!ACT_FINDINGS.has(finding)) throw new Error(`${finding} is no act finding`);                             // findings 4, 6
    if (this.acts.some((f) => f.invocation_id === invocation_id && f.finding === finding)) return;                // deduplicates on (invocation id, finding)
    this.acts.push({ finding, kind, act_key, invocation_id, first_seen: run, run_id: run.run_id });
  }
  /** An instance finding: opened at the first sighting, advanced by every run that still sees the condition (findings 9, 12). */
  instance(finding: FindingName, kind: string | null, run: RunReading): void {
    if (!INSTANCE_FINDINGS.has(finding)) throw new Error(`${finding} is no instance finding`);                    // findings 4, 6
    const standing = this.instances.find((f) => !f.closed && f.finding === finding && f.kind === kind);
    if (standing) { standing.last_seen = run; return; }                                                          // findings 9: advance last seen; first seen is not moved (findings 8)
    this.instances.push({ finding, kind, first_seen: run, last_seen: run, run_id: run.run_id, closed: false });      // findings 7, 11: a recurrence is a new record
  }
  /** A run whose condition read answered that the condition does not stand closes the record with last seen as it was (findings 10a). */
  close(finding: FindingName, kind: string | null): void {
    for (const f of this.instances) if (!f.closed && f.finding === finding && f.kind === kind) f.closed = true;
  }
  standing(finding: FindingName, kind: string | null): InstanceFinding | null {
    return this.instances.find((f) => !f.closed && f.finding === finding && f.kind === kind) ?? null;
  }
}

export type Tally = { examined: number; closed: number; escalated: number; reported: number; skipped: number; closed_already: number; surfaced: number; unreached: number };

export interface RecoverableInvocationConfig {
  journal: Journal;
  /** The act section: a Lease host shared by every node of the instance (act section 1, 3). */
  actSection: LeaseHost;
  bindings: Record<string, KindBinding>;
  compliance: Compliance;
  /** The disclosed bounds, in milliseconds. */
  journalWriteBoundMs: number;
  pauseBoundMs: number;
  commitRoundTripMs: number;
  clockAllowanceMs: number;
  /** One journal read under the critical section; a read that returns nothing within it lands as unavailable (Capability requirement 15). */
  readBoundMs?: number;
  /** Most database candidates an escalated record names, and the cap on a reference's length, to size the largest record (Invariant 6.2). */
  intentCandidatesCap: number;
  referenceLengthCap: number;
  /** What a wait does: the default is a real wait, a test moves its clock here. */
  sleep?: (ms: number) => Promise<void>;
  /** The sweep's bounds; absent, the instance runs no sweep and Instance start's five conditions are not checked (they read the sweep's bounds). */
  sweep?: SweepConfig;
  /** The findings register; the default lives in this process. */
  register?: FindingsRegister;
  /** Term read cap: the most invocations [Read Invocation] returns for one act and the most records per invocation. Default: none. */
  readCap?: number;
}

export type OpenResult = { invocation_id: string; intent_event_id: string };
export type OpenRefusal =
  | { refused: "invalid-credential" }
  | { refused: "invalid-request" }
  | { refused: "act-in-flight"; invocation_id: string }
  | { refused: "act-landed"; outcome_event_id: string }
  | { refused: "section-unavailable" }
  | { refused: "journal-unavailable" }
  | { refused: "recording-failure"; position: "intent" | "outcome" };

/** resolve 1: exactly one of three. */
export type Disposition =
  | { form: "outcome"; outcome_action_ref: string; outcome_data: unknown }
  | { form: "abandoned"; cause: string }
  | { form: "escalated"; candidates: string[] };
export type ResolveRefusal =
  | { refused: "already-accounted"; closing_event_id: string }
  | { refused: "not-known" }
  | { refused: "section-unavailable" }
  | { refused: "invalid-credential" }
  | { refused: "invalid-request"; cause: "malformed" | "candidates-over-cap" | "purged" | "already-abandoned" | "too-young" }   // resolve 27
  | { refused: "recording-failure"; position: "resolution" };
export type ResolveResult = { closing_event_id: string };

/** Term state projection. */
export type InvocationState = "open" | "closed" | "refused" | "abandoned" | "escalated" | "resolved";
export interface InvocationRecord { event_id: string; sequence_number: number; recorded_at: string; action_ref: string; actor_ref: string; data: Record<string, unknown> }
/** Term invocation entry: one invocation, its state and its records, and whether older records were left out (read invocation 5). */
export interface InvocationEntry { invocation_id: string; state: InvocationState; records: InvocationRecord[]; more: boolean }
/** Term invocation report. */
export interface InvocationReport { invocations: InvocationEntry[]; more: boolean }
export type ReadInvocationRefusal = { refused: "not-known" } | { refused: "journal-unavailable" };

export type CloseResult = { outcome_event_id: string; landed_by: "invocation" | "operator" | "sweep" };
export type CloseRefusal = { refused: "recording-failure"; position: "outcome" };
export type RefuseResult = { refusal_event_id: string };
export type RefuseRefusal = { refused: "already-accounted"; closing_event_id: string } | { refused: "recording-failure"; position: "refusal"; constituent_code: string };

/** A record of the journal this composition wrote or reads: what the derived indexes hold. */
interface Rec {
  event_id: string;
  seq: number;
  recorded_at: string;
  action_ref: string;
  invocation_id: string;
  kind: string;
  act_key: string;
  intent_event_id: string | null;
  supersedes: string | null;
  recovery: boolean;
  resolving_actor: string | null;
  actor_ref: string;
  payload: Record<string, unknown>;
  /** unbound-intent and unbound-named are the records of a kind the bindings table no longer serves (Binding 4). */
  role: "intent" | "outcome" | "refused" | "abandoned" | "escalated" | "recovery_intended" | "unbound-intent" | "unbound-named";
}
const CLOSING_ROLES = new Set<Rec["role"]>(["outcome", "refused", "abandoned", "escalated"]);

class ReadFailed extends Error { constructor(msg: string, readonly invalidQuery = false) { super(msg); } }
const actKey = (kind: string, act_key: string) => canonical([kind, act_key]);

export class RecoverableInvocation {
  private mark = 0;                                   // sequence high water (State 4)
  private readonly seen = new Set<string>();
  private readonly byAct = new Map<string, Rec[]>();
  private readonly byInvocation = new Map<string, Rec[]>();
  private readonly cleared = new Set<string>();       // invocation ids [Close] or [Refuse] removed from open invocations (close step 4.1, refuse step 3.9)
  private readonly sweepClosed = new Set<string>();   // sweep closed ids: an outcome under recovery or an escalation naming the id, carrying no resolving actor
  private runInFlight: Promise<Tally | { refused: "journal-unavailable" } | "no-answer"> | null = null;
  readonly register: FindingsRegister;
  private readonly writeFloor: number;
  private readonly commitFloor: number;
  private readonly settleBound: number;

  private constructor(private seam: Seam, private cfg: RecoverableInvocationConfig) {
    this.register = cfg.register ?? new FindingsRegister();
    this.writeFloor = cfg.journalWriteBoundMs + 3 * cfg.pauseBoundMs;                                             // Term write floor
    this.commitFloor = cfg.commitRoundTripMs + 4 * cfg.pauseBoundMs;                                              // Term commit floor
    this.settleBound = cfg.journalWriteBoundMs + cfg.clockAllowanceMs;                                            // Term settle bound
  }

  /** Capability requirement 11: without the range read, the read-your-writes journal or the act section, the composition does not start. Sequence high water 3: a full rebuild at start. */
  static async start(seam: Seam, cfg: RecoverableInvocationConfig): Promise<RecoverableInvocation> {
    if (!cfg.journal?.log || typeof cfg.journal.recordAction !== "function" || !cfg.actSection) throw new Error("Recoverable Invocation does not start: the range read, read-your-writes or the act section is absent");
    const failed = RecoverableInvocation.startConditions(cfg);                                                      // Instance start 2, 3: every condition for every bound kind, or no start
    if (failed.length) throw new Error(`Recoverable Invocation does not start: ${failed.join("; ")}`);
    const ri = new RecoverableInvocation(seam, cfg);
    await ri.refresh();
    return ri;
  }

  /** Instance start 4 to 8 for every bound kind, against the sweep's bounds; the conditions that fail, named. Absent a sweep there is nothing to check them against. */
  static startConditions(cfg: RecoverableInvocationConfig): string[] {
    const s = cfg.sweep;
    if (!s) return [];
    const failed: string[] = [];
    const rb = cfg.readBoundMs;
    if (rb === undefined) return ["a sweep needs read bound, which Instance start 6 and 8 read"];
    const a = cfg.clockAllowanceMs;
    for (const [kind, b] of Object.entries(cfg.bindings)) {
      const icb = b.invocationCompletionBoundMs;
      if (b.settlingPeriodMs === undefined) { failed.push(`${kind}: settling period is not bound`); continue; }
      const worstClosure = icb + 2 * a + 2 * s.sweepCadenceMs + 3 * s.runBoundMs;                                  // Term worst closure
      if (!(s.closureWindowMs > worstClosure)) failed.push(`${kind}: Instance start 4 (closure window ${s.closureWindowMs} does not exceed worst closure ${worstClosure})`);
      const examineWindowEnd = icb + a + s.closureWindowMs;                                                        // Term examine window end
      const retentionFloor = examineWindowEnd + b.settlingPeriodMs + s.runBoundMs;                                 // Term retention floor
      if (!(b.retentionPeriodMs > retentionFloor)) failed.push(`${kind}: Instance start 5 (retention period ${b.retentionPeriodMs} does not exceed retention floor ${retentionFloor})`);
      const leaseSpend = 2 * rb + 2 * cfg.journalWriteBoundMs + cfg.commitRoundTripMs + 9 * cfg.pauseBoundMs;        // Term lease spend
      if (!(icb > leaseSpend)) failed.push(`${kind}: Instance start 6 (invocation completion bound ${icb} does not exceed lease spend ${leaseSpend})`);
      const runFloor = Math.max(icb, s.closureLatencyMs + cfg.journalWriteBoundMs) + s.closureLatencyMs;            // Term run floor
      if (runFloor > s.runBoundMs) failed.push(`${kind}: Instance start 7 (run floor ${runFloor} exceeds run bound ${s.runBoundMs})`);
      const sweepLeaseSpend = Math.max(rb + 2 * cfg.journalWriteBoundMs + s.probeRoundTripMs + 7 * cfg.pauseBoundMs, 2 * rb + cfg.journalWriteBoundMs + 6 * cfg.pauseBoundMs);   // Term sweep lease spend
      if (!(s.closureLatencyMs > sweepLeaseSpend)) failed.push(`${kind}: Instance start 8 (closure latency ${s.closureLatencyMs} does not exceed sweep lease spend ${sweepLeaseSpend})`);
    }
    return failed;
  }

  // ----- the derived indexes -------------------------------------------------------------------------------

  private ms(iso: string) { return Date.parse(iso); }
  private sleep(ms: number) { return (this.cfg.sleep ?? ((n) => new Promise<void>((r) => setTimeout(r, n))))(ms); }

  private classify(ev: LoggedEvent): Rec | null {
    const d = ev.data as { action_ref?: unknown; actor_ref?: unknown; data?: Record<string, unknown> } | null;
    const ref = d?.action_ref;
    const p = d?.data;
    if (typeof ref !== "string" || !p || typeof p !== "object") return null;
    const kind = typeof p.kind === "string" ? p.kind : null;
    if (!kind || !ref.startsWith(`${kind}.`)) return null;                                                          // another pattern's record
    const b = this.cfg.bindings[kind];
    const role: Rec["role"] | null = !b
      ? (ref === `${kind}.intended` ? "unbound-intent" : ref === `${kind}.recovery_intended` ? "recovery_intended" : "unbound-named")   // Binding 4: the intent and its recovery_intended excepted, any other `<kind>.*` names the id
      : ref === `${kind}.intended` ? "intent" : ref === `${kind}.refused` ? "refused" : ref === `${kind}.abandoned` ? "abandoned"
      : ref === `${kind}.escalated` ? "escalated" : ref === `${kind}.recovery_intended` ? "recovery_intended"
      : b.outcomes.includes(ref) ? "outcome" : null;                                                               // journal 4: an outcome by membership in the enumerated refs
    if (!role || typeof p.invocation_id !== "string" || typeof p.act_key !== "string") return null;
    return {
      event_id: ev.event_id, seq: ev.sequence_number, recorded_at: ev.recorded_at, action_ref: ref, invocation_id: p.invocation_id, kind, act_key: p.act_key,
      intent_event_id: typeof p.intent_event_id === "string" ? p.intent_event_id : null,
      supersedes: typeof p.supersedes === "string" ? p.supersedes : null,
      recovery: p.recovery === true,
      resolving_actor: typeof p.resolving_actor === "string" ? p.resolving_actor : null,
      actor_ref: typeof d?.actor_ref === "string" ? d.actor_ref : "",
      payload: p,
      role,
    };
  }

  /**
   * Read the delta above sequence high water and advance the local maps by it (sequence high water 1). The mark moves past a
   * sequence number only once settle bound has passed since its recording instant (sequence high water 2). A read that fails
   * throws ReadFailed; an invalid-query is a fault of the build and is surfaced (Capability requirement 4, 13).
   */
  private async refresh(from = this.mark + 1, bounded = true): Promise<void> {
    let read: LoggedEvent[] | { refused: "invalid-query" };
    try {
      const bound = bounded ? this.cfg.readBoundMs : undefined;
      const call = this.cfg.journal.log.read({ sequence: { from } });
      read = bound === undefined ? await call : await Promise.race([call, new Promise<never>((_, no) => setTimeout(() => no(new ReadFailed("read bound")), bound))]);   // Capability requirement 15
    } catch (e) {
      if (e instanceof ReadFailed || e instanceof Unavailable) throw new ReadFailed(String((e as Error).message));      // Capability requirement 6: unavailable and state-unavailable alike
      throw e;
    }
    if (!Array.isArray(read)) {
      this.cfg.compliance.surface({ arm: "invalid-query" });                                                        // Capability requirement 4, 5: surfaced, never retried unchanged
      throw new ReadFailed("invalid-query", true);
    }
    for (const ev of read) {
      if (this.seen.has(ev.event_id)) continue;                                                                     // a record re-read above an unsettled mark is read once
      const rec = this.classify(ev);
      this.seen.add(ev.event_id);
      if (!rec) continue;
      if ((rec.role === "outcome" && rec.recovery && !rec.resolving_actor) || (rec.role === "escalated" && !rec.resolving_actor)) this.sweepClosed.add(rec.invocation_id);   // Term sweep closed ids
      (this.byAct.get(actKey(rec.kind, rec.act_key)) ?? this.byAct.set(actKey(rec.kind, rec.act_key), []).get(actKey(rec.kind, rec.act_key))!).push(rec);
      (this.byInvocation.get(rec.invocation_id) ?? this.byInvocation.set(rec.invocation_id, []).get(rec.invocation_id)!).push(rec);
    }
    const now = this.ms(this.seam.now());
    for (const ev of read) {
      if (ev.sequence_number !== this.mark + 1) continue;                                                           // the mark moves over a run of settled records only
      if (this.ms(ev.recorded_at) + this.settleBound > now) break;
      this.mark = ev.sequence_number;
    }
  }

  /** The standing closing of an invocation among the closings naming it (Which closing stands 2 to 7): the lowest-numbered of those no other closing names. */
  private standing(invocation_id: string): Rec | null {
    const closings = (this.byInvocation.get(invocation_id) ?? []).filter((r) => CLOSING_ROLES.has(r.role));
    const named = new Set(closings.map((c) => c.supersedes).filter((s): s is string => !!s));
    return closings.filter((c) => !named.has(c.event_id)).sort((a, b) => a.seq - b.seq)[0] ?? null;
  }

  /** open invocations at (kind, act key): an intent no closing names through its invocation id (open invocations 3), within its retention (sequence high water 5). */
  private openInvocations(kind: string, act_key: string): Rec[] {
    const b = this.cfg.bindings[kind];
    const now = this.ms(this.seam.now());
    return (this.byAct.get(actKey(kind, act_key)) ?? []).filter((r) =>
      r.role === "intent" && !this.cleared.has(r.invocation_id) && !this.standing(r.invocation_id)
      && this.ms(r.recorded_at) + b.retentionPeriodMs - this.cfg.clockAllowanceMs > now);                          // Term retention end
  }

  /** act closings at (kind, act key): the act's outcome that stands, the latest by sequence number (open step 3.9a). */
  private latestOutcome(kind: string, act_key: string): Rec | null {
    return (this.byAct.get(actKey(kind, act_key)) ?? []).filter((r) => r.role === "outcome").sort((a, b) => b.seq - a.seq)[0] ?? null;
  }

  // ----- the critical section ------------------------------------------------------------------------------

  private async remaining(kind: string, act_key: string, holder: string): Promise<number | null> {
    try {
      const r = await this.cfg.actSection.remaining(actKey(kind, act_key), holder);
      return r === "none" ? null : r.remaining_ms;
    } catch { return null; }                                                                                        // act section 17: no answer or state-unavailable reads as none for the rest of the grant
  }
  /** Journal write bound 1: a writer issues only if the remaining it queried exceeds the floor. */
  private async above(kind: string, act_key: string, holder: string, floor: number): Promise<boolean> {
    const r = await this.remaining(kind, act_key, holder);
    return r !== null && r > floor;
  }
  /** Term release; a release that answers storage-failure fails the action (act section 21). Not-held is discarded (act section 6). */
  private async release(kind: string, act_key: string, holder: string): Promise<boolean> {
    try { await this.cfg.actSection.release(actKey(kind, act_key), holder); return true; } catch { return false; }
  }

  // ----- one record_action, by position --------------------------------------------------------------------

  /**
   * One journal write and what it answers, read by Primitive policy 19 to 45. A lost reply (Primitive policy 32, 32a) is read back
   * once, after journal write bound has passed since the issue (33 to 35), by invocation id through the range read as the mark stood
   * at the issue. An invalid-request(step-4) is read back too (20, 27). A read-back that fails is "readback-failed".
   */
  private async write(ref: string, actor_ref: string, credential: string, payload: Record<string, unknown>, invocation_id: string, supersedes?: string | null):
    Promise<{ t: "landed"; event_id: string; alert: boolean } | { t: "invalid-credential" } | { t: "invalid-request" } | { t: "invalid-request-step-4" }
      | { t: "retry" } | { t: "lost-nothing"; step3: boolean } | { t: "readback-failed" }> {
    const issued = this.ms(this.seam.now());
    const markAtIssue = this.mark;
    let a: JournalAnswer;
    try { a = await this.cfg.journal.recordAction(ref, actor_ref, credential, payload); }
    catch (e) { if (e instanceof Unavailable) return { t: "retry" }; throw e; }                                      // Primitive policy 45: state-unavailable reads as recording-failure(step-2)
    if (typeof a === "object" && "event_id" in a) return { t: "landed", event_id: (a as { event_id: string }).event_id, alert: false };
    const lost = a === "no-answer" || (a as RecordRefusal & { step?: string }).step === "step-3" && (a as RecordRefusal).refused === "recording-failure";
    const readBack = async (): Promise<Rec | null | "failed"> => {
      try {
        while (this.ms(this.seam.now()) < issued + this.cfg.journalWriteBoundMs) await this.sleep(Math.max(1, issued + this.cfg.journalWriteBoundMs - this.ms(this.seam.now())));   // Primitive policy 34
        await this.refresh(markAtIssue + 1);                                                                          // Primitive policy 35
      } catch (e) { if (e instanceof ReadFailed) return "failed"; throw e; }
      return (this.byInvocation.get(invocation_id) ?? []).find((r) => r.action_ref === ref && (supersedes === undefined || r.supersedes === supersedes)) ?? null;   // a record of the same reference an operator's earlier closing wrote is not this write
    };
    if (lost) {
      const found = await readBack();
      if (found === "failed") return { t: "readback-failed" };                                                      // read path: the position's recording-failure arm
      return found ? { t: "landed", event_id: found.event_id, alert: false } : { t: "lost-nothing", step3: typeof a === "object" };   // Primitive policy 36, 37b; a recording-failure(step-3) is told from no answer at the sweep (reconcile step 3.22)
    }
    const r = a as RecordRefusal;
    if (r.refused === "invalid-credential") return { t: "invalid-credential" };
    if (r.refused === "invalid-request") {
      if (r.step !== "step-4") return { t: "invalid-request" };                                                      // Primitive policy 41, 42
      const found = await readBack();
      if (found === "failed") return { t: "readback-failed" };
      return found ? { t: "landed", event_id: found.event_id, alert: true } : { t: "invalid-request-step-4" };      // Primitive policy 21, 22, 28, 40: found proceeds with a hard alert
    }
    return { t: "retry" };                                                                                           // recording-failure(step-2) and (step-4) (Primitive policy 44)
  }

  // ----- [Open] --------------------------------------------------------------------------------------------

  /** The size the substrate measures: the serialized envelope with the attestation id's width (Term as the substrate measures a payload). */
  private measure(actor_ref: string, ref: string, data: unknown): number {
    return new TextEncoder().encode(canonical({ action_ref: ref, actor_ref, attestation_id: this.seam.idMaterial(), data })).length;
  }

  /** The intent's refusal under open step 3.5, 3.7 and 1.7: the in-flight intent, or an aged one where the kind has a service identity. */
  private blocking(kind: string, act_key: string): Rec | null {
    const b = this.cfg.bindings[kind];
    const now = this.ms(this.seam.now());
    const open = this.openInvocations(kind, act_key).sort((a, c) => a.seq - c.seq);
    const inflight = (r: Rec) => this.ms(r.recorded_at) + b.invocationCompletionBoundMs + this.cfg.clockAllowanceMs > now;     // Term examine edge, in-flight
    return open.find((r) => inflight(r) || b.serviceIdentity !== null) ?? null;                                    // open step 3.5, 3.7: in flight always; aged unless the service identity is none
  }

  async open(kind: string, act_key: string, actor_ref: string, credential: string, intent_data: unknown): Promise<OpenResult | OpenRefusal> {
    const b = this.cfg.bindings[kind];
    // Step 1: validate and size, writing nothing (open step 1.5). The order is no order of work; an unbound kind is refused with no read and no take (1.9).
    if (!b) return { refused: "invalid-request" };                                                                  // open step 1.9
    if (isBlank(act_key) || isBlank(actor_ref) || isBlank(credential)) return { refused: "invalid-request" };       // open step 1.1, 1.10; Primitive policy 7
    if (b.serviceIdentity !== null && actor_ref === b.serviceIdentity) return { refused: "invalid-request" };        // open step 1.2: caller kind service, by byte-identity
    if (actor_ref.length > this.cfg.referenceLengthCap || act_key.length > this.cfg.referenceLengthCap) return { refused: "invalid-request" };   // Primitive policy 1, 8
    const invocation_id = this.seam.idMaterial();                                                                   // Term invocation id: injected at the seam, fresh per invocation
    const intentPayload = { invocation_id, kind, act_key, intent_data };                                            // Primitive policy 9, 11: parameters and pairing datum; id, kind and act key written by the composition
    const cap = this.cfg.journal.log.payloadCap;
    const largest = Math.max(
      this.measure(actor_ref, `${kind}.x`, { invocation_id, kind, act_key, intent_event_id: "x".repeat(36), recovery: true, outcome: "x".repeat(b.outcomeEnvelopeBytes) }),
      this.measure(actor_ref, `${kind}.escalated`, { invocation_id, kind, act_key, intent_event_id: "x".repeat(36), candidates: "x".repeat(this.cfg.intentCandidatesCap * this.cfg.referenceLengthCap) }));   // Term largest record, Invariant 6.2
    if (this.measure(actor_ref, `${kind}.intended`, intentPayload) > cap || largest > cap) return { refused: "invalid-request" };   // open step 1.3, 1.4; Primitive policy 12, 13
    // Step 1.6: read open invocations from the journal before any take.
    try { await this.refresh(undefined, false); } catch (e) { if (e instanceof ReadFailed) return { refused: "journal-unavailable" }; throw e; }   // open step 1.8; a read outside the section is not bounded (Term read path)
    const first = this.blocking(kind, act_key);
    if (first) return { refused: "act-in-flight", invocation_id: first.invocation_id };                             // open step 1.7, with no take

    // Step 2: take the critical section (open step 2.1); a failed take is section-unavailable with nothing written (2.3, act section 5).
    let took: Awaited<ReturnType<LeaseHost["take"]>>;
    try { took = await this.cfg.actSection.take(actKey(kind, act_key), invocation_id, b.invocationCompletionBoundMs); }
    catch { return { refused: "section-unavailable" }; }
    if (took === "unavailable") return { refused: "section-unavailable" };
    const out = async <T>(r: T): Promise<T> => { await this.release(kind, act_key, invocation_id); return r; };

    // Step 3: pre-check under the critical section.
    try { await this.refresh(); } catch (e) {
      if (e instanceof ReadFailed) return out({ refused: "journal-unavailable" });                                  // open step 3.13
      throw e;
    }
    if ((await this.remaining(kind, act_key, invocation_id)) === null) return out({ refused: "section-unavailable" });   // open step 3.11, 3.12: a read that exhausts the lease
    const block = this.blocking(kind, act_key);
    if (block) return out({ refused: "act-in-flight", invocation_id: block.invocation_id });                        // open step 3.4 to 3.7
    if (b.serviceIdentity === null) {
      for (const old of this.openInvocations(kind, act_key)) this.cfg.compliance.hardAlert({ invocation_id: old.invocation_id, arm: "aged-open-intent" });   // open step 3.8a to 3.8c: left open, surfaced; closing it is an operator's
    }
    if (!b.repeatable) {
      const landed = this.latestOutcome(kind, act_key);                                                             // open step 3.9a
      if (landed) return out({ refused: "act-landed", outcome_event_id: landed.event_id });                         // open step 3.9b, 3.9c
    }

    // Step 4: the intent record, behind a reading of its own (open step 4.1, journal write bound 1).
    if (!(await this.above(kind, act_key, invocation_id, this.writeFloor))) return out({ refused: "section-unavailable" });   // open step 4.1, 4.2
    const w = await this.write(`${kind}.intended`, actor_ref, credential, intentPayload, invocation_id);             // open step 4.3
    if (w.t === "invalid-credential") return out({ refused: "invalid-credential" });                                // Primitive policy 19: passed through unchanged, nothing written
    if (w.t === "invalid-request" || w.t === "invalid-request-step-4") return out({ refused: "invalid-request" });   // Primitive policy 22, 41
    if (w.t !== "landed") return out({ refused: "recording-failure", position: "intent" });                          // Primitive policy 23, 37b, 44, 45
    if (w.alert) this.cfg.compliance.hardAlert({ invocation_id, arm: "intent-read-back" });                         // Primitive policy 21a

    // Step 5: populate from the next re-read, read for the commit, and return.
    try { await this.refresh(); } catch (e) { if (!(e instanceof ReadFailed)) throw e; }                            // open step 5.1, Primitive policy 38: the intent's sequence number and instant come from the range read
    if (!(await this.above(kind, act_key, invocation_id, this.commitFloor))) {                                      // open step 5.4, 5.5
      await this.release(kind, act_key, invocation_id);
      return { refused: "recording-failure", position: "outcome" };                                                 // open step 5.6: the intent stands, the lease no longer covers the commit
    }
    return { invocation_id, intent_event_id: w.event_id };                                                          // open step 5.2, 5.3: the section held at return
  }

  // ----- [Close] -------------------------------------------------------------------------------------------

  async close(kind: string, act_key: string, invocation_id: string, intent_event_id: string, actor_ref: string, credential: string, outcome_action_ref: string, outcome_data: unknown): Promise<CloseResult | CloseRefusal> {
    const fail: CloseRefusal = { refused: "recording-failure", position: "outcome" };
    const done = async <T>(r: T): Promise<T> => { await this.release(kind, act_key, invocation_id); return r; };
    const b = this.cfg.bindings[kind];
    if (!b || !b.outcomes.includes(outcome_action_ref)) {                                                           // close 6: an outcome ref outside the kind's enumerated refs
      this.cfg.compliance.hardAlert({ invocation_id, arm: "outcome-ref-not-enumerated" });
      return done(fail);
    }
    // Step 1: confirm standing before any read (close step 1.1, 1.2). The commit's reply is discarded with the rest.
    if (!(await this.above(kind, act_key, invocation_id, this.writeFloor))) return done(fail);
    const payload = { invocation_id, kind, act_key, intent_event_id, data: outcome_data };                         // Primitive policy 11, 11a
    for (;;) {
      // Step 2: re-read under the critical section, proceed as landed.
      try { await this.refresh(); } catch (e) {
        if (e instanceof ReadFailed) return done(fail);                                                             // close step 2.4: nothing written
        throw e;
      }
      const stands = this.standing(invocation_id);
      if (stands) {
        if (stands.role !== "outcome") return done(fail);                                                           // close step 2.3: an abandonment or an escalation is not adopted (a refusal is unreachable, Action wiring 4)
        this.cleared.add(invocation_id);
        return done({ outcome_event_id: stands.event_id, landed_by: stands.resolving_actor ? "operator" : stands.recovery ? "sweep" : "invocation" } as CloseResult);   // close step 2.2a to 2.2f
      }
      // Step 3: the outcome record, behind a reading of its own (close step 3.10).
      if (!(await this.above(kind, act_key, invocation_id, this.writeFloor))) return done(fail);                    // close step 3.5, 3.7, 3.10
      const w = await this.write(outcome_action_ref, actor_ref, credential, payload, invocation_id);               // close step 3.1
      if (w.t === "landed") {
        if (w.alert) this.cfg.compliance.hardAlert({ invocation_id, arm: "outcome-read-back" });                    // Primitive policy 28
        this.cleared.add(invocation_id);                                                                            // close step 4.1
        return done({ outcome_event_id: w.event_id, landed_by: "invocation" } as CloseResult);                      // close step 4.2, 4.3
      }
      if (w.t === "invalid-request" || w.t === "invalid-request-step-4") { this.cfg.compliance.hardAlert({ invocation_id, arm: w.t }); return done(fail); }   // close step 3.3; Primitive policy 40, 42
      if (w.t === "retry") continue;                                                                                // Primitive policy 29, close step 3.4: retry under the section to the terminus, step 2 re-run first
      return done(fail);                                                                                            // invalid-credential (3.8), a lost reply with nothing found (Primitive policy 37b), a failed read-back
    }
  }

  // ----- [Refuse] ------------------------------------------------------------------------------------------

  async refuse(kind: string, act_key: string, invocation_id: string, intent_event_id: string, actor_ref: string, credential: string, reason: string, constituent_code: string): Promise<RefuseResult | RefuseRefusal> {
    const fail: RefuseRefusal = { refused: "recording-failure", position: "refusal", constituent_code };
    const done = async <T>(r: T): Promise<T> => { await this.release(kind, act_key, invocation_id); return r; };
    // Step 1: confirm standing before any read (refuse step 1.1, 1.2).
    if (!(await this.above(kind, act_key, invocation_id, this.writeFloor))) return done(fail);
    // Step 2: re-read under the critical section; a closing already naming the invocation id is already-accounted.
    try { await this.refresh(); } catch (e) {
      if (e instanceof ReadFailed) return done(fail);                                                               // Capability requirement 6, Term read path
      throw e;
    }
    const stands = this.standing(invocation_id);
    if (stands) return done({ refused: "already-accounted", closing_event_id: stands.event_id } as RefuseRefusal);   // refuse step 2.2, 2.3, 2.5: nothing appended
    // Step 3: the refusal record, behind a reading of its own (refuse step 3.13).
    if (!(await this.above(kind, act_key, invocation_id, this.writeFloor))) return done(fail);
    const w = await this.write(`${kind}.refused`, actor_ref, credential, { invocation_id, intent_event_id, kind, act_key, reason, constituent_code }, invocation_id);   // refuse step 3.1
    if (w.t === "landed") {
      if (w.alert) this.cfg.compliance.hardAlert({ invocation_id, arm: "refusal-read-back" });                      // refuse step 3.12
      this.cleared.add(invocation_id);                                                                              // refuse step 3.9
      return done({ refusal_event_id: w.event_id } as RefuseResult);                                                // refuse step 3.10, 3.12
    }
    return done(fail);                                                                                              // refuse step 3.5 to 3.8: the intent is left open for the sweep; no retry (3.4)
  }

  // ----- [Yield] -------------------------------------------------------------------------------------------

  /** yield 1, 4: writes nothing and closes nothing. An answered reply releases the section; a lost one leaves the grant to end at its instant (yield 5, 6). */
  async yieldSection(kind: string, act_key: string, invocation_id: string, reply: "answered" | "lost"): Promise<"ok" | { refused: "storage-failure" }> {
    if (reply === "lost") return "ok";
    return (await this.release(kind, act_key, invocation_id)) ? "ok" : { refused: "storage-failure" };
  }

  // ----- [Reconcile] ---------------------------------------------------------------------------------------

  /** One sweep write at the outcome position (reconcile step 3.15): each issue behind a reading of its own (journal write bound 1), a retry under the section to the terminus at most (Primitive policy 29, reconcile step 3.17). */
  private async sweepWrite(kind: string, key: string, holder: string, invocation_id: string, ref: string, payload: Record<string, unknown>):
    Promise<{ t: "landed"; event_id: string } | { t: "credential" } | { t: "unrecordable" } | { t: "later"; journal: boolean }> {
    const b = this.cfg.bindings[kind];
    let retried = false;
    for (;;) {
      if (!(await this.above(kind, key, holder, this.writeFloor))) return { t: "later", journal: retried };           // reconcile step 3.17: cut short, left for the next run; a retry that the lease cut is a recording-failure(step-2) left (3.22)
      const w = await this.write(ref, b.serviceIdentity!, b.serviceCredential ?? "", payload, invocation_id);
      switch (w.t) {
        case "landed":
          if (w.alert) this.cfg.compliance.hardAlert({ invocation_id, arm: "sweep-read-back" });                      // reconcile step 3.16, Primitive policy 28: success with a hard alert
          return { t: "landed", event_id: w.event_id };
        case "invalid-credential": return { t: "credential" };                                                       // reconcile step 3.18
        case "invalid-request": return { t: "unrecordable" };                                                        // reconcile step 3.20; Primitive policy 43: no retry
        case "invalid-request-step-4":
          this.cfg.compliance.hardAlert({ invocation_id, arm: "invalid-request-step-4" });                           // Primitive policy 40: a hard alert, the act left for the next run
          return { t: "later", journal: false };
        case "retry": retried = true; continue;                                                                      // Primitive policy 29, 44, 45
        case "lost-nothing": return { t: "later", journal: w.step3 };                                                // Primitive policy 37b; reconcile step 3.22 names recording-failure(step-3) alone
        case "readback-failed": return { t: "later", journal: false };                                               // Capability requirement 6: the position's arm
      }
    }
  }

  /** The adopter's act probe; a rejection or no answer is unavailable (act probe 4, 5). A kind with none bound reads as unavailable (Invariant 5.10). */
  private async probe(b: KindBinding, act_key: string, intent_payload: Record<string, unknown>): Promise<ProbeAnswer> {
    try { return b.actProbe ? await b.actProbe(act_key, intent_payload) : { answer: "unavailable" }; } catch { return { answer: "unavailable" }; }
  }

  /**
   * The sweep, once per node at a time (run bound 1). It reads now once (Primitive policy 18), rebuilds from the range read (sequence
   * high water 4), keeps every aged intent of a served kind short of its horizon edge, and examines each under the act's critical section.
   */
  reconcile(): Promise<Tally | { refused: "journal-unavailable" } | "no-answer"> {
    if (!this.cfg.sweep) throw new Error("this instance runs no sweep: no sweep bounds were given");
    if (this.runInFlight) return this.runInFlight;                                                                  // run bound 1
    const run = this.run().finally(() => { this.runInFlight = null; });
    this.runInFlight = run;
    return run;
  }

  private async run(): Promise<Tally | { refused: "journal-unavailable" } | "no-answer"> {
    const sw = this.cfg.sweep!;
    const allow = this.cfg.clockAllowanceMs;
    const run_id = this.seam.idMaterial();                                                                          // Term run id: fresh for every run
    const reading: RunReading = { run_id, at: this.seam.now() };                                                    // Primitive policy 18: now once, at the sweep's own seam
    const now = this.ms(reading.at);
    const tally: Tally = { examined: 0, closed: 0, escalated: 0, reported: 0, skipped: 0, closed_already: 0, surfaced: 0, unreached: 0 };
    const sweepLease = sw.closureLatencyMs + this.cfg.journalWriteBoundMs;                                          // Term sweep lease
    const seen = new Map<string, [FindingName, string | null]>();                                                   // the instance findings whose condition the run saw
    const gone = new Map<string, [FindingName, string | null]>();                                                   // ... and those whose condition read answered that it does not stand
    const mark = (m: Map<string, [FindingName, string | null]>, f: FindingName, kind: string | null) => m.set(JSON.stringify([f, kind]), [f, kind]);
    const safe = (f: () => void) => { try { f(); } catch { /* findings 3: a surfacing that fails never rejects a run that has landed closings */ } };
    const closeOutRegister = () => {
      for (const [f, kind] of seen.values()) safe(() => this.register.instance(f, kind, reading));                  // findings 9: the run still sees the condition
      for (const [k, [f, kind]] of gone) if (!seen.has(k)) safe(() => this.register.close(f, kind));                // findings 10a; a run with no condition read leaves the record (10b)
    };

    // Step 1: enumerate between two edges (reconcile 1; reconcile step 1.1 to 1.7).
    const rebuilding = this.rebuild(false);                                                                         // a read outside the critical section is not bounded (Term read path)
    rebuilding.catch(() => {});                                                                                     // a read that outlives run bound 2 is not an unhandled rejection
    const wait = sw.wait ?? ((ms: number) => new Promise<void>((r) => setTimeout(r, ms)));
    try {
      const first = await Promise.race([rebuilding.then(() => "read" as const), wait(sw.runBoundMs).then(() => "stalled" as const)]);
      if (first === "stalled") return "no-answer";                                                                  // run bound 2: no answer to give, nothing written
    } catch (e) {
      if (!(e instanceof ReadFailed)) throw e;
      if (!e.invalidQuery) mark(seen, "journal-unavailable", null);                                                 // reconcile 1b; Capability requirement 14: an invalid-query opens no outage finding
      closeOutRegister();
      return { refused: "journal-unavailable" };                                                                    // reconcile 1a, 1c: nothing written
    }
    mark(gone, "journal-unavailable", null);                                                                        // the enumeration's answer is the condition read (Term condition read)
    const maxRetention = Math.max(...Object.values(this.cfg.bindings).map((b) => b.retentionPeriodMs));
    const kept: Rec[] = [];
    for (const recs of this.byInvocation.values()) {
      for (const r of recs) {
        if (r.role === "unbound-intent") {                                                                          // reconcile step 1.6, Binding 4 to 6
          if (recs.some((x) => x.role === "unbound-named")) continue;
          if (this.ms(r.recorded_at) + maxRetention <= now) continue;                                               // Binding 6: the pass is bounded by the instance's longest retention period
          tally.surfaced++;                                                                                         // reconcile step 1.7
          this.cfg.compliance.surface({ arm: "unbound-kind", kind: r.kind, act_key: r.act_key, invocation_id: r.invocation_id });
          safe(() => this.register.act("unbound-kind", r.kind, r.act_key, r.invocation_id, reading));
          continue;
        }
        if (r.role !== "intent" || this.standing(r.invocation_id) || this.sweepClosed.has(r.invocation_id)) continue;
        const b = this.cfg.bindings[r.kind];
        const aged = this.ms(r.recorded_at) + b.invocationCompletionBoundMs + allow <= now;                         // Term aged (Invariant 7.1)
        const horizonEdge = this.ms(r.recorded_at) + b.retentionPeriodMs - allow - sw.runBoundMs;                   // Term horizon edge (Invariant 7.2)
        if (aged && now < horizonEdge) kept.push(r);                                                                // reconcile step 1.2, 1.3
      }
    }
    kept.sort((a, c) => a.seq - c.seq);
    for (const r of kept) if (this.cfg.bindings[r.kind].serviceIdentity === null) {
      this.cfg.compliance.surface({ arm: "aged-open-intent", kind: r.kind, act_key: r.act_key, invocation_id: r.invocation_id });   // service identity 1b
    }

    const landed = new Set<string>();                                                                               // the invocation ids whose closing stands at the end of the run
    const unreachedKinds = new Set<string>();

    const credentialRefused = (rec: Rec) => {
      this.cfg.compliance.hardAlert({ invocation_id: rec.invocation_id, arm: "credential-refused" });               // reconcile step 3.18: at once
      mark(seen, "credential-refused", rec.kind);                                                                   // reconcile step 3.24a
      unreachedKinds.add(rec.kind);                                                                                 // reconcile step 3.19, 2.1, 2.8: nothing more under the credential until reconfigured
      for (const k of kept) if (k.kind === rec.kind) safe(() => this.register.act("closure-at-risk", k.kind, k.act_key, k.invocation_id, reading));   // reconcile step 3.24b
    };

    /** A closing the sweep writes as `<kind>.escalated`: the cause and what the database named. */
    const escalate = async (rec: Rec, holder: string, extra: Record<string, unknown>): Promise<"escalated" | "skipped"> => {
      const r = await this.sweepWrite(rec.kind, rec.act_key, holder, rec.invocation_id, `${rec.kind}.escalated`, { invocation_id: rec.invocation_id, intent_event_id: rec.event_id, kind: rec.kind, act_key: rec.act_key, ...extra });
      if (r.t === "landed") {
        this.sweepClosed.add(rec.invocation_id); landed.add(rec.invocation_id);
        mark(gone, "credential-refused", rec.kind);
        safe(() => this.register.act("escalated", rec.kind, rec.act_key, rec.invocation_id, reading));              // reconcile step 3.21
        return "escalated";
      }
      if (r.t === "credential") credentialRefused(rec);
      else if (r.t === "unrecordable") this.cfg.compliance.hardAlert({ invocation_id: rec.invocation_id, arm: "escalation-unrecordable" });   // reconcile step 3.23: left for the next run with a hard alert
      else if (r.journal) mark(seen, "journal-unavailable", null);                                                  // reconcile step 3.22
      return "skipped";
    };

    /** Steps 2 and 3 for one act, under its critical section; the caller releases (step 4.4). */
    const examine = async (rec: Rec, holder: string): Promise<"closed" | "escalated" | "reported" | "skipped" | "closed_already"> => {
      const b = this.cfg.bindings[rec.kind];
      try { await this.refresh(); } catch (e) {                                                                     // reconcile step 2.4
        if (!(e instanceof ReadFailed)) throw e;
        if (!e.invalidQuery) mark(seen, "journal-unavailable", null);                                               // reconcile step 2.10d
        return "skipped";                                                                                           // reconcile step 2.10a to 2.10c: nothing written, released
      }
      if (this.standing(rec.invocation_id) || this.sweepClosed.has(rec.invocation_id)) { landed.add(rec.invocation_id); return "closed_already"; }   // reconcile step 2.5, 2.6; sweep closed ids 1
      if (!(await this.above(rec.kind, rec.act_key, holder, this.writeFloor))) return "skipped";                    // reconcile step 2.7, 2.11: the reading comes before the act probe
      const probe = await this.probe(b, rec.act_key, rec.payload);                                                  // reconcile step 3.1; reconcile 2b under none
      if (probe.answer === "unavailable") { mark(seen, "store-unavailable", rec.kind); return "skipped"; }          // reconcile step 3.13; under none the closure table's row lands the same (open line 2026-11-07-d)
      if (b.serviceIdentity === null) {
        this.cfg.compliance.surface({ arm: "reported", kind: rec.kind, act_key: rec.act_key, invocation_id: rec.invocation_id, detail: probe });   // reconcile 2e: the result reported, nothing written (2d)
        return "reported";                                                                                          // reconcile 2f
      }
      mark(gone, "store-unavailable", rec.kind);                                                                    // the act probe's answer is the condition read (Term condition read)
      if (probe.answer === "not-committed") return escalate(rec, holder, { cause: "not-observed" });               // reconcile step 3.5; 3.7: the sweep never re-runs an act
      if (probe.answer === "undecidable") {                                                                         // reconcile step 3.8 to 3.12: candidates named, none chosen, no outcome written
        const over = probe.candidates.length > this.cfg.intentCandidatesCap;
        return escalate(rec, holder, {
          cause: "undecidable",
          database_candidates: probe.candidates.slice(0, this.cfg.intentCandidatesCap),                             // reconcile step 3.9
          ...(over ? { candidates_count: probe.candidates.length, candidates_range: { first: probe.candidates[0], last: probe.candidates[probe.candidates.length - 1] } } : {}),   // reconcile step 3.10
        });
      }
      if (!b.outcomes.includes(probe.outcome_action_ref)) {                                                         // act probe 9 broken by the adopter's probe: nothing written, a fault of the build surfaced
        this.cfg.compliance.surface({ arm: "probe-outcome-not-enumerated", kind: rec.kind, act_key: rec.act_key, invocation_id: rec.invocation_id });
        return "skipped";
      }
      const intended = await this.sweepWrite(rec.kind, rec.act_key, holder, rec.invocation_id, `${rec.kind}.recovery_intended`,   // reconcile step 3.2a, Invariant 5.1
        { invocation_id: rec.invocation_id, intent_event_id: rec.event_id, kind: rec.kind, act_key: rec.act_key, plan: "outcome" });
      const closing = intended.t === "landed"
        ? await this.sweepWrite(rec.kind, rec.act_key, holder, rec.invocation_id, probe.outcome_action_ref,         // reconcile step 3.2b
            { invocation_id: rec.invocation_id, intent_event_id: rec.event_id, kind: rec.kind, act_key: rec.act_key, data: probe.outcome_data, recovery: true, acting_actor_ref: rec.actor_ref })   // Invariant 5.2, 5.3
        : intended;
      if (closing.t === "landed") {
        this.sweepClosed.add(rec.invocation_id); landed.add(rec.invocation_id);                                     // reconcile step 4.3
        mark(gone, "credential-refused", rec.kind);
        return "closed";                                                                                            // reconcile step 3.2c
      }
      if (closing.t === "credential") { credentialRefused(rec); return "skipped"; }
      if (closing.t === "unrecordable") return escalate(rec, holder, { cause: "outcome-unrecordable" });            // reconcile step 3.20
      if (closing.journal) mark(seen, "journal-unavailable", null);                                                 // reconcile step 3.22
      return "skipped";                                                                                             // reconcile step 3.17
    };

    for (const rec of kept) {
      if (unreachedKinds.has(rec.kind)) { tally.unreached++; continue; }                                            // reconcile step 2.1, 2.8, 2.9
      tally.examined++;
      const holder = `${run_id}:${rec.invocation_id}`;                                                              // Term critical section holder
      let took: Awaited<ReturnType<LeaseHost["take"]>>;
      try { took = await this.cfg.actSection.take(actKey(rec.kind, rec.act_key), holder, sweepLease); }             // reconcile step 2.1
      catch { tally.skipped++; continue; }                                                                          // reconcile step 2.3, 9: a failed take, no answer included, nothing written
      if (took === "unavailable") { tally.skipped++; continue; }
      let count = await examine(rec, holder);
      if (!(await this.release(rec.kind, rec.act_key, holder))) count = "skipped";                                  // reconcile step 4.4; reconcile 9
      tally[count]++;
      if (count === "closed" || count === "escalated") { try { await this.refresh(); } catch (e) { if (!(e instanceof ReadFailed)) throw e; } }   // reconcile step 4.1 to 4.3
    }

    // Step 5: liveness.
    const atRisk = sw.closureWindowMs - 2 * sw.runBoundMs - sw.sweepCadenceMs - allow;                             // Term at risk threshold
    for (const rec of kept) {
      if (landed.has(rec.invocation_id) || atRisk > now - this.ms(rec.recorded_at)) continue;                       // reconcile step 5.1: an examined, skipped or unreached intent whose closing has not landed
      safe(() => this.register.act("closure-at-risk", rec.kind, rec.act_key, rec.invocation_id, reading));
    }
    for (const recs of this.byInvocation.values()) {                                                                // reconcile step 5.9: an escalation still standing near the horizon
      const intent = recs.find((r) => r.role === "intent");
      const b = intent ? this.cfg.bindings[intent.kind] : undefined;
      if (!intent || !b || this.standing(intent.invocation_id)?.role !== "escalated") continue;
      const settlingEdge = this.ms(intent.recorded_at) + b.retentionPeriodMs - allow - sw.runBoundMs - (b.settlingPeriodMs ?? 0);   // Term settling edge
      if (now >= settlingEdge) safe(() => this.register.act("closure-at-risk", intent.kind, intent.act_key, intent.invocation_id, reading));
    }
    closeOutRegister();
    return tally;                                                                                                   // reconcile step 5.8
  }

  // ----- [Resolve] -----------------------------------------------------------------------------------------

  /**
   * The human-attested close: an operator closes an open intent the sweep cannot, or corrects an outcome an operator wrote (resolve 36).
   * The page names no order between read_record (resolve 11) and the re-read (resolve 8), nor between the closing a re-read finds and the
   * too-young guard (resolve 9, 18); this render re-reads, then reads the record, then reads the closing, then the guard.
   */
  async resolve(kind: string, act_key: string, invocation_id: string, intent_event_id: string, actor_ref: string, credential: string, disposition: Disposition):
    Promise<ResolveResult | ResolveRefusal> {
    const b = this.cfg.bindings[kind];
    const sw = this.cfg.sweep;
    if (!sw) throw new Error("this instance runs no sweep: [Resolve] takes the sweep lease, which the sweep's bounds set");
    const failed: ResolveRefusal = { refused: "recording-failure", position: "resolution" };
    // Validate, with no take and nothing appended (resolve 30, 31, 33; the cap, resolve 28, is checked with the form: the page names no order).
    const d = disposition as Disposition | null;
    const malformed: ResolveRefusal = { refused: "invalid-request", cause: "malformed" };
    if (!b) return malformed;                                                                                       // resolve 33
    if (!d || typeof d !== "object") return malformed;
    if (d.form === "outcome") {
      if (typeof d.outcome_action_ref !== "string" || !b.outcomes.includes(d.outcome_action_ref)) return malformed; // resolve 31
    } else if (d.form === "abandoned") {
      if (typeof d.cause !== "string") return malformed;
    } else if (d.form === "escalated") {
      if (!Array.isArray(d.candidates) || d.candidates.some((c) => typeof c !== "string")) return malformed;
      if (d.candidates.length > this.cfg.intentCandidatesCap) return { refused: "invalid-request", cause: "candidates-over-cap" };   // resolve 28
    } else return malformed;                                                                                        // resolve 1, 30: exactly one of the three forms

    const holder = this.seam.idMaterial();                                                                          // Term operator run id: injected once per call, fresh for every call
    let took: Awaited<ReturnType<LeaseHost["take"]>>;
    try { took = await this.cfg.actSection.take(actKey(kind, act_key), holder, sw.closureLatencyMs + this.cfg.journalWriteBoundMs); }   // resolve 4: take((kind, act key), operator run id, sweep lease)
    catch { return { refused: "section-unavailable" }; }                                                            // resolve 6: a failed take, no answer included
    if (took === "unavailable") return { refused: "section-unavailable" };
    const out = async <T>(r: T): Promise<T> => { await this.release(kind, act_key, holder); return r; };           // resolve 22, 37: every refusal while the section is held releases it

    // Re-read under the critical section, behind a reading of its own (resolve 38, 8).
    if (!(await this.above(kind, act_key, holder, this.writeFloor))) return out({ refused: "section-unavailable" });   // resolve 7: nothing written
    try { await this.refresh(); } catch (e) {
      if (e instanceof ReadFailed) return out(failed);                                                              // Capability requirement 6, 13, 15; the re-read's own row: nothing written
      throw e;
    }

    // The intent, by read_record (resolve 11); never from it the intent's sequence number or instant (Primitive policy 39).
    let rec: AuditRecord | "not-known" | "no-answer";
    const readBound = this.cfg.readBoundMs;
    try {
      const call = this.cfg.journal.readRecord(intent_event_id);
      rec = readBound === undefined ? await call : await Promise.race([call, new Promise<never>((_, no) => setTimeout(() => no(new ReadFailed("read bound")), readBound))]);   // Capability requirement 19
    } catch (e) {
      if (e instanceof ReadFailed || e instanceof Unavailable) return out(failed);                                  // Capability requirement 9, 18: never not-known
      throw e;
    }
    if (rec === "no-answer") return out(failed);                                                                    // Capability requirement 9, 10
    if (rec === "not-known") return out({ refused: "not-known" });                                                  // resolve 10
    if (typeof rec.retention === "object" && rec.retention.state === "purged") return out({ refused: "invalid-request", cause: "purged" });   // resolve 12
    const named = rec.data as { invocation_id?: unknown; kind?: unknown; act_key?: unknown } | null;
    if (rec.action_ref !== `${kind}.intended` || named?.invocation_id !== invocation_id || named?.act_key !== act_key || named?.kind !== kind) return out({ refused: "not-known" });   // resolve 34

    // The closing that stands (Which closing stands), and what the disposition may do to it (the closing table: resolve 9, 14, 15, 16, 36).
    const stands = this.standing(invocation_id);
    let supersedes: string | null = null;
    if (stands) {
      if (stands.role === "refused" || (stands.role === "outcome" && !stands.resolving_actor)) return out({ refused: "already-accounted", closing_event_id: stands.event_id });   // resolve 9
      if (stands.role === "outcome") {                                                                              // resolve 36: an outcome an operator wrote
        if (d.form !== "outcome") return out({ refused: "already-accounted", closing_event_id: stands.event_id });  // resolve 36b
        supersedes = stands.event_id;                                                                               // resolve 36a, 13
      } else if (stands.role === "abandoned") {                                                                     // resolve 16
        if (d.form !== "outcome") return out({ refused: "invalid-request", cause: "already-abandoned" });           // resolve 16b
        supersedes = stands.event_id;                                                                               // resolve 16a, 13
      } else if (stands.role === "escalated") supersedes = stands.event_id;                                         // resolve 15: any disposition, naming it
    }                                                                                                               // resolve 14: no closing standing, any disposition
    if (d.form === "abandoned") {
      const intent = (this.byInvocation.get(invocation_id) ?? []).find((r) => r.role === "intent");
      const inflight = intent && this.ms(intent.recorded_at) + b.invocationCompletionBoundMs + this.cfg.clockAllowanceMs > this.ms(this.seam.now());   // Term examine edge; resolve 19: now injected at the operator's seam
      if (inflight) return out({ refused: "invalid-request", cause: "too-young" });                                 // resolve 18
    }

    // The closing record, under the operator's own credential, behind a reading of its own (resolve 39, 21).
    if (!(await this.above(kind, act_key, holder, this.writeFloor))) return out({ refused: "section-unavailable" });   // resolve 39, 7
    const base = { invocation_id, kind, act_key, intent_event_id, recovery: true, resolving_actor: actor_ref, acting_actor_ref: rec.actor_ref, ...(supersedes ? { supersedes } : {}) };   // resolve 21: no recovery_intended; 13
    const [ref, payload] = d.form === "outcome" ? [d.outcome_action_ref, { ...base, data: d.outcome_data }]
      : d.form === "abandoned" ? [`${kind}.abandoned`, { ...base, cause: d.cause }]
      : [`${kind}.escalated`, { ...base, database_candidates: d.candidates }];
    const w = await this.write(ref, actor_ref, credential, payload, invocation_id, supersedes);
    switch (w.t) {
      case "landed":
        if (w.alert) this.cfg.compliance.hardAlert({ invocation_id, arm: "resolution-read-back" });                 // resolve 24
        this.cleared.add(invocation_id);
        try { await this.refresh(); } catch (e) { if (!(e instanceof ReadFailed)) throw e; }                        // the closing is read from the next re-read; one that fails leaves it to the next
        return out({ closing_event_id: w.event_id });                                                               // resolve 22, 35
      case "invalid-credential": return out({ refused: "invalid-credential" });                                     // resolve 3: nothing appended
      case "invalid-request":
        this.cfg.compliance.hardAlert({ invocation_id, arm: "invalid-request" });                                   // resolve 29
        return out(failed);
      default: return out(failed);                                                                                  // resolve 25, 26: step-2, a lost reply after an empty read-back, a step-4 that read back nothing, a read-back that failed; no retry
    }
  }

  // ----- [Read Invocation] ---------------------------------------------------------------------------------

  /** Term state projection, read from the standing closing (read invocation 10). */
  private stateOf(invocation_id: string): InvocationState {
    const s = this.standing(invocation_id);
    if (!s) return "open";
    return s.role === "outcome" ? "closed" : s.role === "refused" ? "refused" : s.role === "escalated" ? "escalated" : s.resolving_actor ? "resolved" : "abandoned";
  }

  /**
   * The act's invocations, each intent and whichever closings name it, through the same rebuild (read invocation 1 to 17). It takes no
   * critical section (13) and writes nothing (14). A read cap, where the deployment declares one, bounds the invocations and the records.
   */
  async readInvocation(kind: string, act_key: string, invocation_id?: string): Promise<InvocationReport | ReadInvocationRefusal> {
    const b = this.cfg.bindings[kind];
    if (!b) return { refused: "not-known" };                                                                        // read invocation 17: with no read
    try { await this.refresh(undefined, false); } catch (e) {                                                       // read invocation 1, 11; a read outside the section is not bounded (Term read path)
      if (e instanceof ReadFailed) return { refused: "journal-unavailable" };                                       // never not-known (Action wiring 3); an invalid-query lands there too, surfaced (Capability requirement 13)
      throw e;
    }
    const now = this.ms(this.seam.now());
    const cap = this.cfg.readCap ?? Infinity;
    const intents = (this.byAct.get(actKey(kind, act_key)) ?? [])
      .filter((r) => r.role === "intent" && this.ms(r.recorded_at) + b.retentionPeriodMs - this.cfg.clockAllowanceMs > now)   // a readable intent: within its retention (sequence high water 5)
      .sort((x, y) => x.seq - y.seq);
    if (!intents.length) return { refused: "not-known" };                                                           // read invocation 12
    const entry = (intent: Rec): InvocationEntry => {
      const all = (this.byInvocation.get(intent.invocation_id) ?? []).filter((r) => r.role !== "intent" && r.role !== "unbound-intent" && r.role !== "unbound-named")
        .sort((x, y) => x.seq - y.seq);                                                                             // read invocation 6: a superseded closing is not excluded; 16: earliest first
      const kept = all.length > cap ? all.slice(all.length - cap) : all;                                            // read invocation 5: the most recent read cap
      const view = (r: Rec): InvocationRecord => ({ event_id: r.event_id, sequence_number: r.seq, recorded_at: r.recorded_at, action_ref: r.action_ref, actor_ref: r.actor_ref, data: r.payload });
      return { invocation_id: intent.invocation_id, state: this.stateOf(intent.invocation_id), records: [intent, ...kept].map(view), more: all.length > kept.length };   // read invocation 4, 10
    };
    if (invocation_id !== undefined && !isBlank(invocation_id)) {                                                   // read invocation 3
      const one = intents.find((r) => r.invocation_id === invocation_id);
      if (!one) return { refused: "not-known" };                                                                    // read invocation 3b
      return { invocations: [entry(one)], more: false };                                                            // read invocation 3a
    }
    const recent = intents.length > cap ? intents.slice(intents.length - cap) : intents;                            // read invocation 2: the most recent read cap, earliest first (16)
    return { invocations: recent.map(entry), more: intents.length > recent.length };
  }

  // ----- reads for the tests and the next parts ------------------------------------------------------------

  /** The open intents at (kind, act key) as the local maps hold them, after re-reading the delta. */
  async openIntents(kind: string, act_key: string): Promise<{ invocation_id: string; intent_event_id: string }[]> {
    await this.refresh();
    return this.openInvocations(kind, act_key).map((r) => ({ invocation_id: r.invocation_id, intent_event_id: r.event_id }));
  }
  get sequenceHighWater(): number { return this.mark; }
  /** sequence high water 3, 6: a full rebuild from the log's beginning. */
  async rebuild(bounded = true): Promise<void> {
    this.mark = 0; this.seen.clear(); this.byAct.clear(); this.byInvocation.clear(); this.cleared.clear(); this.sweepClosed.clear();
    await this.refresh(1, bounded);
  }
}

