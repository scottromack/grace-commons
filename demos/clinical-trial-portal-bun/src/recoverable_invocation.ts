// Recoverable Invocation — the protocol a regulated action follows around an act it cannot take back, to the depth
// this part reaches: [Open], [Close], [Refuse], [Yield], and the derived indexes they read.
// Rendered from compositions/recoverable-invocation.md (the page at the commit the entry names), with no code of
// any other render opened. A rule's label is in the comment where the code answers it.
//
// The composition's state is derived: open invocations, act closings and the sequence high water are rebuilt from
// one range read of the journal (Composition state), held in this process, and rebuilt at start (sequence high
// water 3, 6). The critical section is a Lease on the key (kind, act key); the journal is Audit Trail.
//
// Not rendered here, said so and not hidden: [Reconcile] (the sweep, sweep closed ids, the findings register and
// Instance start's conditions), [Resolve] and [Read Invocation]. They are the next parts. A closing written by
// them is read here already (an abandonment, an escalation, a superseding record) since [Close] and [Refuse] must
// find it.
//
// Where the render does not meet the page: a release is Lease's own transaction, not joined to the record write
// (act section 21 asks that a release answering storage-failure leave nothing written standing; here the record
// stands and the action answers its position's arm, which is the safe side for [Close] and [Refuse]).
import { type Seam, isBlank } from "./seam.ts";
import { canonical } from "./canonical.ts";
import { Unavailable } from "./store.ts";
import { type EventLog, type LoggedEvent } from "./event_log.ts";
import { type RecordRefusal } from "./audit_trail.ts";
import { type LeaseHost } from "./lease.ts";

/** What record_action answers; a reply that never came is "no-answer" (Primitive policy 32). */
export type JournalAnswer = { event_id: string } | RecordRefusal | "no-answer";
export interface Journal {
  recordAction(action_ref: string, actor_ref: string, credential: string, data?: unknown): Promise<JournalAnswer>;
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
}

export interface Compliance {
  /** A hard alert naming the invocation id and the arm that raised it (Term hard alert). */
  hardAlert(a: { invocation_id: string; arm: string }): void;
  /** A surfaced fault of the build or an old intent left open (open step 3.8c, Capability requirement 4). */
  surface(a: { arm: string; kind?: string; act_key?: string; invocation_id?: string }): void;
}

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
  role: "intent" | "outcome" | "refused" | "abandoned" | "escalated" | "recovery_intended";
}
const CLOSING_ROLES = new Set<Rec["role"]>(["outcome", "refused", "abandoned", "escalated"]);

class ReadFailed extends Error {}
const actKey = (kind: string, act_key: string) => canonical([kind, act_key]);

export class RecoverableInvocation {
  private mark = 0;                                   // sequence high water (State 4)
  private readonly seen = new Set<string>();
  private readonly byAct = new Map<string, Rec[]>();
  private readonly byInvocation = new Map<string, Rec[]>();
  private readonly cleared = new Set<string>();       // invocation ids [Close] or [Refuse] removed from open invocations (close step 4.1, refuse step 3.9)
  private readonly writeFloor: number;
  private readonly commitFloor: number;
  private readonly settleBound: number;

  private constructor(private seam: Seam, private cfg: RecoverableInvocationConfig) {
    this.writeFloor = cfg.journalWriteBoundMs + 3 * cfg.pauseBoundMs;                                             // Term write floor
    this.commitFloor = cfg.commitRoundTripMs + 4 * cfg.pauseBoundMs;                                              // Term commit floor
    this.settleBound = cfg.journalWriteBoundMs + cfg.clockAllowanceMs;                                            // Term settle bound
  }

  /** Capability requirement 11: without the range read, the read-your-writes journal or the act section, the composition does not start. Sequence high water 3: a full rebuild at start. */
  static async start(seam: Seam, cfg: RecoverableInvocationConfig): Promise<RecoverableInvocation> {
    if (!cfg.journal?.log || typeof cfg.journal.recordAction !== "function" || !cfg.actSection) throw new Error("Recoverable Invocation does not start: the range read, read-your-writes or the act section is absent");
    const ri = new RecoverableInvocation(seam, cfg);
    await ri.refresh();
    return ri;
  }

  // ----- the derived indexes -------------------------------------------------------------------------------

  private ms(iso: string) { return Date.parse(iso); }
  private sleep(ms: number) { return (this.cfg.sleep ?? ((n) => new Promise<void>((r) => setTimeout(r, n))))(ms); }

  private classify(ev: LoggedEvent): Rec | null {
    const d = ev.data as { action_ref?: unknown; data?: Record<string, unknown> } | null;
    const ref = d?.action_ref;
    const p = d?.data;
    if (typeof ref !== "string" || !p || typeof p !== "object") return null;
    const kind = typeof p.kind === "string" ? p.kind : null;
    const b = kind ? this.cfg.bindings[kind] : undefined;
    if (!kind || !b || !ref.startsWith(`${kind}.`)) return null;                                                   // another kind's record, or an unbound one (the sweep's, not rendered here)
    const role: Rec["role"] | null =
      ref === `${kind}.intended` ? "intent" : ref === `${kind}.refused` ? "refused" : ref === `${kind}.abandoned` ? "abandoned"
      : ref === `${kind}.escalated` ? "escalated" : ref === `${kind}.recovery_intended` ? "recovery_intended"
      : b.outcomes.includes(ref) ? "outcome" : null;                                                               // journal 4: an outcome by membership in the enumerated refs
    if (!role || typeof p.invocation_id !== "string" || typeof p.act_key !== "string") return null;
    return {
      event_id: ev.event_id, seq: ev.sequence_number, recorded_at: ev.recorded_at, action_ref: ref, invocation_id: p.invocation_id, kind, act_key: p.act_key,
      intent_event_id: typeof p.intent_event_id === "string" ? p.intent_event_id : null,
      supersedes: typeof p.supersedes === "string" ? p.supersedes : null,
      recovery: p.recovery === true,
      resolving_actor: typeof p.resolving_actor === "string" ? p.resolving_actor : null,
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
      throw new ReadFailed("invalid-query");
    }
    for (const ev of read) {
      if (this.seen.has(ev.event_id)) continue;                                                                     // a record re-read above an unsettled mark is read once
      const rec = this.classify(ev);
      this.seen.add(ev.event_id);
      if (!rec) continue;
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
  private async write(ref: string, actor_ref: string, credential: string, payload: Record<string, unknown>, invocation_id: string):
    Promise<{ t: "landed"; event_id: string; alert: boolean } | { t: "invalid-credential" } | { t: "invalid-request" } | { t: "invalid-request-step-4" }
      | { t: "retry" } | { t: "lost-nothing" } | { t: "readback-failed" }> {
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
      return (this.byInvocation.get(invocation_id) ?? []).find((r) => r.action_ref === ref) ?? null;
    };
    if (lost) {
      const found = await readBack();
      if (found === "failed") return { t: "readback-failed" };                                                      // read path: the position's recording-failure arm
      return found ? { t: "landed", event_id: found.event_id, alert: false } : { t: "lost-nothing" };                // Primitive policy 36, 37b
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

  // ----- reads for the tests and the next parts ------------------------------------------------------------

  /** The open intents at (kind, act key) as the local maps hold them, after re-reading the delta. */
  async openIntents(kind: string, act_key: string): Promise<{ invocation_id: string; intent_event_id: string }[]> {
    await this.refresh();
    return this.openInvocations(kind, act_key).map((r) => ({ invocation_id: r.invocation_id, intent_event_id: r.event_id }));
  }
  get sequenceHighWater(): number { return this.mark; }
  /** sequence high water 3, 6: a full rebuild from the log's beginning. */
  async rebuild(): Promise<void> {
    this.mark = 0; this.seen.clear(); this.byAct.clear(); this.byInvocation.clear(); this.cleared.clear();
    await this.refresh();
  }
}

