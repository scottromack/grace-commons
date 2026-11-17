// External Onboarding — admitting an outside party: [Invite], [Decline] and [Revoke] on the audit arm. [Onboard]
// (the one action that follows Recoverable Invocation, with its onboarding transaction and its probe) is the part after
// this one and is not here.
// Rendered from compositions/external-onboarding.md (the page at the commit the entry names), with no code of any
// other render opened. A rule's label is in the comment where the code answers it.
//
// The composition stores nothing (Composition state 1, 3): the tracing from a party to its invitation is the trail's.
// Each action is one transaction (Database 1): the attempt record, the constituent's write and the post-write record
// are planned in that order and committed together, so a refusal anywhere leaves nothing written ("a committed
// nothing", Audit arm 17), except what the Audit arm names: the attestation an attempt record Audit Trail refused at
// step-3 or step-4 leaves committed (Audit arm 21, 23), and the post-write record a step-4 refusal left in the log,
// which the landing read finds and the action then proceeds as landed (Audit arm 8 to 11).
// The attempt record's attestation is the credential gate: nothing is verified outside it (Action wiring 2) and every
// record is attested under the calling actor's credential (Composes 14). The composition declares no service identity
// (Composes 15).
//
// Where the render does not meet the page: Capability requirement 2 asks one reading of now per invocation; the
// constituents read the seam's clock themselves, so the three actions read none of their own, and Capability
// requirement 12 (the widths the constituents allocate) is the deployment's declaration, which the sizing below uses.
import { Store, Guard, Unavailable, type Stmt } from "./store.ts";
import { type Seam, isBlank } from "./seam.ts";
import { canonical } from "./canonical.ts";
import { type Invitation } from "./invitation.ts";
import { type RecordRefusal } from "./audit_trail.ts";
import { type EventLog, type LoggedEvent } from "./event_log.ts";

/** What the composition asks of the substrate: Audit Trail's record_action as statements to join one transaction, and its range read. */
export interface Trail {
  plan(action_ref: string, actor_ref: string, credential: string, data?: unknown, ahead?: number): Promise<
    | { event_id: string; sequence_number: number; stmts: Stmt[]; indexStmt: Stmt }
    | { refusal: RecordRefusal; keep: Stmt[] }
  >;
  index(indexStmt: Stmt): Promise<void>;
  readonly log: Pick<EventLog, "payloadCap" | "read">;
}

export interface ExternalOnboardingConfig {
  /** Audit Trail's reference length cap, in code points (Primitive policy 2). */
  referenceLengthCap: number;
  /** Capability requirement 5, 18: the longest an [Onboard] takes. Blank, the composition does not start. */
  onboardingCompletionBoundMs: number | null;
  /** Capability requirement 7, 19: the bound on the difference between any two clocks at the seams. Blank, the composition does not start. */
  clockOffsetAllowanceMs: number | null;
  /** Capability requirement 11, 22: the widths the wired constituents allocate for an invitation token, a party id, a credential id and an event id. Blank, the composition does not start. */
  mintedIdWidths: { invitationToken: number; partyId: number; credentialId: number; eventId: number } | null;
  /** Audit arm 19: an invalid-request from Audit Trail is a deployment fault, alerted. */
  alert?: (a: { arm: string; action: string; step: string }) => void;
}

export type Position = "intent" | "attempt-evidence";
export type InvitationInvalid = { refused: "invitation-invalid"; cause: "expired" | "not-known" | "already-resolved"; stored_terminal?: "accepted" | "declined" | "revoked" };
export type Refusal =
  | { refused: "invalid-request" }
  | { refused: "invalid-credential" }
  | { refused: "storage-failure"; position: Position }
  | { refused: "state-unavailable" }
  | InvitationInvalid;

const ATTEMPT = { invite: "invitation.initiate-attempt", decline: "invitation.decline-attempt", revoke: "invitation.revoke-attempt" } as const;
const POST = { invite: "invitation.initiated", decline: "invitation.declined", revoke: "invitation.revoked" } as const;
const TRIES = 50;

type Spec = {
  action: "invite" | "decline" | "revoke";
  actor_ref: string;
  actor_credential: string;
  attempt: unknown;
  /** The constituent's write as statements, with the token the post-write record names (Action wiring 6, 45, 54), or its refusal. */
  constituent: () => Promise<{ invitation_token: string; stmts: Stmt[] } | { refused: string; status?: string }>;
  post: (token: string) => unknown;
  /** What a constituent refusal answers (Action wiring 5, 42 to 44, 50 to 53). */
  refusal: (r: { refused: string; status?: string }) => Refusal;
};

export class ExternalOnboarding {
  private constructor(private store: Store, private seam: Seam, private invitation: Invitation, private trail: Trail, private cfg: ExternalOnboardingConfig & { mintedIdWidths: NonNullable<ExternalOnboardingConfig["mintedIdWidths"]> }) {}

  /** Capability requirement 18, 19, 22: a blank bound, and the composition does not start. */
  static async open(store: Store, seam: Seam, parts: { invitation: Invitation; trail: Trail }, cfg: ExternalOnboardingConfig): Promise<ExternalOnboarding> {
    if (cfg.onboardingCompletionBoundMs === null || cfg.onboardingCompletionBoundMs === undefined) throw new Error("External Onboarding does not start: the onboarding completion bound is blank");   // Capability requirement 18
    if (cfg.clockOffsetAllowanceMs === null || cfg.clockOffsetAllowanceMs === undefined) throw new Error("External Onboarding does not start: the clock offset allowance is blank");              // Capability requirement 19
    if (!cfg.mintedIdWidths) throw new Error("External Onboarding does not start: the minted-id width bounds are blank");                                                                      // Capability requirement 22
    return new ExternalOnboarding(store, seam, parts.invitation, parts.trail, cfg as ExternalOnboardingConfig & { mintedIdWidths: NonNullable<ExternalOnboardingConfig["mintedIdWidths"]> });
  }

  // ---- Input checks, before any record (Primitive policy 1 to 6, 10) ------------------------------------------------

  /** Primitive policy 1, 2: a blank required input, or an actor reference over the reference length cap. */
  private inputs(required: unknown[], actor_ref: string): boolean {
    if (required.some((v) => typeof v !== "string" || isBlank(v))) return false;                                    // Primitive policy 1
    return [...actor_ref].length <= this.cfg.referenceLengthCap;                                                    // Primitive policy 2
  }

  /** Primitive policy 5, 6: the data of an event the action will emit, with the ids a constituent mints sized at their width bounds, within the payload cap. */
  private sized(action_ref: string, actor_ref: string, data: unknown): boolean {
    const w = this.cfg.mintedIdWidths;
    const payload = { action_ref, actor_ref, attestation_id: "x".repeat(w.eventId), data };
    return new TextEncoder().encode(canonical(payload)).length <= this.trail.log.payloadCap;
  }
  private fit(actor_ref: string, action: Spec["action"], attempt: unknown, post: unknown): boolean {
    return this.sized(ATTEMPT[action], actor_ref, attempt) && this.sized(POST[action], actor_ref, post);
  }
  private token(): string { return "x".repeat(this.cfg.mintedIdWidths.invitationToken); }

  // ---- The actions --------------------------------------------------------------------------------------------------

  /** [Invite] (Action wiring 3 to 7): the initiate attempt, Invitation's initiate, the initiated record, answering the token. */
  async invite(inviter_ref: string, invitee_ref: string | null | undefined, context: string, ttl: number | null | undefined, actor_credential: string): Promise<{ invitation_token: string } | Refusal> {
    if (!this.inputs([inviter_ref, context, actor_credential], inviter_ref)) return { refused: "invalid-request" };  // Primitive policy 1, 2, 10
    if (!this.invitation.validInitiate(inviter_ref, invitee_ref, context, ttl)) return { refused: "invalid-request" }; // Primitive policy 3
    const invitee = isBlank(invitee_ref) ? null : invitee_ref;
    const ttlRecorded = ttl === undefined ? null : ttl;                                                              // Action wiring 3, 6: blank where the call supplies none
    const attempt = { invitee_ref: invitee, context, ttl: ttlRecorded };                                             // Action wiring 3
    const post = (t: string) => ({ invitation_token: t, invitee_ref: invitee, context, ttl: ttlRecorded });          // Action wiring 6
    if (!this.fit(inviter_ref, "invite", attempt, post(this.token()))) return { refused: "invalid-request" };       // Primitive policy 5, 6, 10
    const r = await this.run({
      action: "invite", actor_ref: inviter_ref, actor_credential, attempt, post,
      constituent: () => this.invitation.planInitiate(inviter_ref, invitee_ref, context, ttl),                       // Action wiring 4
      refusal: (c) => (c.refused === "invalid-request" ? { refused: "invalid-request" } : { refused: "storage-failure", position: "intent" }),   // Action wiring 5
    });
    return "ok" in r ? { invitation_token: r.token } : r;                                                            // Action wiring 7
  }

  /** [Decline] (Action wiring 40 to 47): the decline attempt under the service actor reference, Invitation's decline, the decline record carrying the token alone (no decliner's identity, 47). */
  async decline(invitation_token: string, service_actor_ref: string, actor_credential: string): Promise<"declined" | Refusal> {
    if (!this.inputs([invitation_token, service_actor_ref, actor_credential], service_actor_ref)) return { refused: "invalid-request" };
    const attempt = { invitation_token };                                                                            // Action wiring 40
    const post = () => ({ invitation_token });                                                                       // Action wiring 45
    if (!this.fit(service_actor_ref, "decline", attempt, post())) return { refused: "invalid-request" };
    const r = await this.run({
      action: "decline", actor_ref: service_actor_ref, actor_credential, attempt, post,
      constituent: async () => { const p = await this.invitation.planDecline(invitation_token); return "refused" in p ? p : { invitation_token, stmts: p.stmts }; },   // Action wiring 41
      refusal: (c) => this.invalid(c),                                                                               // Action wiring 42 to 44
    });
    return "ok" in r ? "declined" : r;                                                                               // Action wiring 46
  }

  /** [Revoke] (Action wiring 48 to 55): the revoke attempt under the revoked by reference, Invitation's revoke, the revoke record carrying the token and the reason. */
  async revoke(invitation_token: string, revoked_by_ref: string, reason: string, actor_credential: string): Promise<"revoked" | Refusal> {
    if (!this.inputs([invitation_token, revoked_by_ref, reason, actor_credential], revoked_by_ref)) return { refused: "invalid-request" };
    if (!this.invitation.validRevoke(revoked_by_ref, reason)) return { refused: "invalid-request" };                // Primitive policy 3
    const attempt = { invitation_token, revocation_reason: reason };                                                 // Action wiring 48
    const post = () => ({ invitation_token, revocation_reason: reason });                                            // Action wiring 54
    if (!this.fit(revoked_by_ref, "revoke", attempt, post())) return { refused: "invalid-request" };
    const r = await this.run({
      action: "revoke", actor_ref: revoked_by_ref, actor_credential, attempt, post,
      constituent: async () => { const p = await this.invitation.planRevoke(invitation_token, revoked_by_ref, reason); return "refused" in p ? p : { invitation_token, stmts: p.stmts }; },   // Action wiring 49
      refusal: (c) => (c.refused === "invalid-request" ? { refused: "invalid-request" } : this.invalid(c)),         // Action wiring 50 to 53
    });
    return "ok" in r ? "revoked" : r;                                                                                // Action wiring 55
  }

  /** The refusal a gate call met, as the page names it: expired, not-known, or already-resolved carrying the stored terminal (Term invitation refusal). */
  private invalid(c: { refused: string; status?: string }): Refusal {
    if (c.refused === "already-resolved") return { refused: "invitation-invalid", cause: "already-resolved", stored_terminal: c.status as InvitationInvalid["stored_terminal"] };
    if (c.refused === "expired" || c.refused === "not-known") return { refused: "invitation-invalid", cause: c.refused };
    return { refused: "storage-failure", position: "intent" };                                                       // Audit arm 14: Invitation's storage-failure
  }

  // ---- One action: attempt record, constituent write, post-write record, one transaction ------------------------------

  private async run(s: Spec): Promise<{ ok: true; token: string } | Refusal> {
    for (let tries = 0; tries < TRIES; tries++) {
      try {
        const a = await this.trail.plan(ATTEMPT[s.action], s.actor_ref, s.actor_credential, s.attempt);              // Action wiring 1: the attempt record first; its attestation is the credential gate (Action wiring 2)
        if ("refusal" in a) return await this.attemptRefused(s.action, a.refusal, a.keep);
        const c = await s.constituent();                                                                              // only after the attempt record lands
        if ("refused" in c) return s.refusal(c);                                                                      // nothing was committed: the attempt record was only planned
        const token = c.invitation_token;
        const p = await this.trail.plan(POST[s.action], s.actor_ref, s.actor_credential, s.post(token), 1);         // the post-write record, numbered after the attempt record
        if ("refusal" in p) return await this.postRefused(s, a, c, token, p.refusal, p.keep);
        try {
          await this.store.commit([...a.stmts, ...c.stmts, ...p.stmts]);                                              // Database 1: one transaction
        } catch (e) {
          if (e instanceof Guard && (e.guard === "log-moved" || e.guard === "resolved")) continue;                    // another event or another resolution landed first: plan again, the next read says which
          return { refused: "storage-failure", position: "intent" };                                                  // Audit arm 14, 17: a committed nothing
        }
        await this.trail.index(a.indexStmt); await this.trail.index(p.indexStmt);
        return { ok: true, token };
      } catch (e) {
        if (e instanceof Unavailable) return { refused: "state-unavailable" };                                        // Execution Contract Constituent failure 3
        throw e;
      }
    }
    return { refused: "storage-failure", position: "intent" };
  }

  /** What Audit Trail's refusal of the attempt record lands as (Audit arm 1 to 4, 21, 23). */
  private async attemptRefused(action: Spec["action"], r: RecordRefusal, keep: Stmt[]): Promise<Refusal> {
    if (r.refused === "invalid-credential") return { refused: "invalid-credential" };                                // Audit arm 1: nothing written (Non-goal 10)
    if (r.refused === "recording-failure") return { refused: "storage-failure", position: "intent" };               // Audit arm 2
    this.cfg.alert?.({ arm: "audit-arm-19", action, step: r.step });                                                  // Audit arm 19
    if (r.step === "step-1" || r.step === "step-2") return { refused: "storage-failure", position: "intent" };      // Audit arm 3: below step-3
    if (keep.length) { try { await this.store.commit(keep); } catch { /* the refusal still answers; the committed ids are what the substrate names */ } }
    return { refused: "storage-failure", position: "attempt-evidence" };                                              // Audit arm 21: the attestation stands committed, no constituent has written (23)
  }

  /** What Audit Trail's refusal of the post-write record lands as (Audit arm 5, 8 to 11, 13, 22, 25). */
  private async postRefused(
    s: Spec, a: { sequence_number: number; stmts: Stmt[]; indexStmt: Stmt }, c: { stmts: Stmt[] }, token: string, r: RecordRefusal, keep: Stmt[],
  ): Promise<{ ok: true; token: string } | Refusal> {
    if (r.refused === "invalid-credential") return { refused: "invalid-credential" };                                // Audit arm 13: the action's writes are rolled back
    if (r.refused === "recording-failure") return { refused: "storage-failure", position: "intent" };               // Audit arm 5
    this.cfg.alert?.({ arm: "audit-arm-19", action: s.action, step: r.step });                                        // Audit arm 19
    if (r.step !== "step-4") return { refused: "storage-failure", position: "intent" };                              // Audit arm 22
    // Audit arm 8: what the substrate kept at step-4 is the record, appended and attested. Where it kept none there is
    // nothing to find, and the read-back's answer is its own (Audit arm 25): nothing is committed.
    if (!keep.length) return { refused: "storage-failure", position: "intent" };                                     // Audit arm 25
    // The action commits beside the kept record, as one transaction, and the landing read then finds it.
    try { await this.store.commit([...a.stmts, ...c.stmts, ...keep]); } catch {
      return { refused: "storage-failure", position: "intent" };                                                     // a committed nothing (Audit arm 17)
    }
    await this.trail.index(a.indexStmt);
    const found = await this.landingRead(a.sequence_number, POST[s.action], token);                                  // Audit arm 9, 10
    return found ? { ok: true, token } : { refused: "storage-failure", position: "intent" };                         // Audit arm 11, 25
  }

  /** Audit arm 9, 10: from the sequence number of the invocation's own attempt record to the open end, matched by action reference and invitation token. */
  private async landingRead(from: number, action_ref: string, token: string): Promise<boolean> {
    const evs = await this.trail.log.read({ sequence: { from } });                                                   // Composes 11, 12, 13: an open-ended range, selected in the composition's own code
    if (!Array.isArray(evs)) throw new Unavailable();
    return (evs as LoggedEvent[]).some((e) => {
      const d = e.data as { action_ref?: string; data?: { invitation_token?: string } | null };
      return d.action_ref === action_ref && d.data?.invitation_token === token;
    });
  }
}
