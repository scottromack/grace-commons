// External Onboarding, rendered from compositions/external-onboarding.md.
// Every rule cited is that page's unless another page is named.
import type { Database } from "@db/sqlite";
import type { Seam } from "./seam.ts";
import type { Faults } from "./faults.ts";
import type { AuditTrail, RecordAnswer } from "./audit_trail.ts";
import { credential, invitation, type InvitationConfig, partyIdentity } from "./atoms.ts";

// The host's critical section keyed by invitation token (Capability requirement 13 through 17).
export class CriticalSection {
  private held = new Set<string>();
  constructor(readonly leaseMs: number) {}
  take(token: string): boolean { if (this.held.has(token)) return false; this.held.add(token); return true; }
  release(token: string) { this.held.delete(token); }
}

export interface Config {
  invitation: InvitationConfig;
  onboardingCompletionBoundMs?: number;   // Capability requirement 5
  clockOffsetAllowanceMs?: number;        // 7
  auditHorizonMs: number;                 // 9
  idWidth: number;                        // 11
  criticalSection?: CriticalSection;      // 13
}
export type Position = "intent" | "outcome";
export type Stage = "acceptance-unrecorded" | "unrecorded" | "party-enrollment" | "credential-registration";
export type Refusal =
  | { refused: "invalid-request" | "invalid-credential" | "duplicate-active-credential" }
  | { refused: "storage-failure"; position: Position }
  | { refused: "invitation-invalid"; reason: "expired" | "not-known" | "already-resolved"; stored?: string }
  | { refused: "onboarding-indeterminate"; party_candidates?: string[]; credential_candidates?: string[] };
export interface OnboardInput {
  invitation_token: string; accepting_identity_ref: string; name: string; date_of_birth: string; document_type: string; document_ref: string;
  credential_type: string; credential_material: string; expires_at?: string; enrolling_actor_ref: string; actor_credential: string;
  resume_party_id?: string; resume_credential_id?: string;
}
type Ev = { seq: number; event_id: string; recorded_at: string; action_ref: string; actor_ref: string; data: Record<string, unknown> };
interface Arc { token: string; inv: { now: string; attemptSeq: number }; input: OnboardInput }

export class ExternalOnboarding {
  readonly alerts: { kind: string; detail: string }[] = [];
  private cs: CriticalSection;
  private widened: number;

  private constructor(private db: Database, private seam: Seam, private f: Faults, private audit: AuditTrail, readonly config: Config) {
    this.cs = config.criticalSection!;
    this.widened = config.onboardingCompletionBoundMs! + config.clockOffsetAllowanceMs!;  // Term widened bound
  }

  // Capability requirement 17 through 20.
  static start(db: Database, seam: Seam, f: Faults, audit: AuditTrail, config: Config): ExternalOnboarding {
    if (config.onboardingCompletionBoundMs === undefined) throw new Error("no onboarding completion bound");
    if (config.clockOffsetAllowanceMs === undefined) throw new Error("no clock offset allowance");
    if (!config.criticalSection) throw new Error("no critical section");
    if (config.onboardingCompletionBoundMs + config.clockOffsetAllowanceMs > config.criticalSection.leaseMs) throw new Error("widened bound exceeds the lease");
    return new ExternalOnboarding(db, seam, f, audit, config);
  }

  // ---- the substrate: an attempt record and a post-write record (Audit arm 1 through 13) ----
  private attempt(action_ref: string, actor: string, cred: string, data: Record<string, unknown>): { seq: number } | Refusal {
    const r = this.audit.record_action(action_ref, actor, cred, data);
    if ("ok" in r) return { seq: this.seqOf(r.ok) };
    if (r.refused === "invalid-credential") return { refused: "invalid-credential" };                 // 1
    if (r.refused === "invalid-request") this.alerts.push({ kind: "audit-invalid-request", detail: action_ref });  // 19
    return { refused: "storage-failure", position: "intent" };                                        // 2, 3, 4: every arm, the retention step included
  }
  private post(action_ref: string, actor: string, cred: string, data: Record<string, unknown>, fromSeq: number, onFail: Position = "outcome"):
    { landed: true } | Refusal {
    const r: RecordAnswer = this.audit.record_action(action_ref, actor, cred, data);
    if ("ok" in r) return { landed: true };
    if (r.refused === "invalid-credential") return { refused: "invalid-credential" };                 // 13
    if (r.refused === "recording-failure" && r.step === "step-4") {                                   // 6, 7, 20
      this.alerts.push({ kind: "unretained-event", detail: action_ref });
      return { landed: true };
    }
    if (r.refused === "invalid-request") {                                                             // 8 through 12
      this.alerts.push({ kind: "audit-invalid-request", detail: action_ref });
      const back = this.events(fromSeq).find((e) => e.action_ref === action_ref && e.data.invitation_token === data.invitation_token);
      if (back) return { landed: true };
    }
    return { refused: "storage-failure", position: onFail };                                          // 5, 12
  }
  // Composes 11 through 13: an open-ended sequence range, filtered here.
  events(from = 1): Ev[] {
    return this.audit.log_read(from).filter((e) => e.envelope).map((e) => ({ seq: e.seq, event_id: e.event_id, recorded_at: e.recorded_at,
      action_ref: e.envelope!.action_ref, actor_ref: e.envelope!.actor_ref, data: e.envelope!.data }));
  }
  private seqOf(event_id: string) { return this.events().find((e) => e.event_id === event_id)!.seq; }

  // ---- Primitive policy ----
  private refOk(r: string) { return r.trim() !== "" && new TextEncoder().encode(r).length <= this.audit.config.referenceCap; }
  private fits(actor: string, data: Record<string, unknown>): boolean {                                 // 5, 6
    const c = this.audit.config;
    return JSON.stringify({ action_ref: "onboarding.invitation-accepted", actor_ref: actor, attestation_id: "x".repeat(c.attestationIdWidth), data }).length <= c.payloadCap;
  }
  private pad() { return "x".repeat(this.config.idWidth); }

  // ---- [Invite] (Action wiring 1 through 7) ----
  invite(inviter_ref: string, invitee_ref: string | undefined, context: string, ttlMs: number | undefined, actor_credential: string): { ok: string } | Refusal {
    if (!this.refOk(inviter_ref) || context.trim() === "" || actor_credential.trim() === "") return { refused: "invalid-request" };  // 1, 2
    if (!invitation.validInitiate(this.config.invitation, inviter_ref, context, ttlMs)) return { refused: "invalid-request" };        // 3
    const record = { invitation_token: this.pad(), invitee_ref: invitee_ref ?? null, context, ttl: ttlMs ?? null };
    if (!this.fits(inviter_ref, record)) return { refused: "invalid-request" };
    const now = this.seam.now();                                                                        // Capability requirement 2
    const a = this.attempt("invitation.initiate-attempt", inviter_ref, actor_credential, { invitee_ref: invitee_ref ?? null, context, ttl: ttlMs ?? null, attempted_at: now });  // 3
    if ("refused" in a) return a;
    const i = invitation.initiate(this.db, this.seam, this.f, this.config.invitation, inviter_ref, invitee_ref, context, ttlMs);  // 4
    if ("refused" in i) return i.refused === "invalid-request" ? { refused: "invalid-request" } : { refused: "storage-failure", position: "intent" };  // 5; Audit arm 14
    const p = this.post("invitation.initiated", inviter_ref, actor_credential, { ...record, invitation_token: i.ok }, a.seq);  // 6
    return "refused" in p ? p : { ok: i.ok };                                                          // 7
  }

  // ---- [Onboard] (Action wiring 8 through 39; Resume 1 through 47) ----
  onboard(x: OnboardInput): { ok: { party_id: string; credential_id: string } } | Refusal {
    const required = [x.invitation_token, x.accepting_identity_ref, x.name, x.date_of_birth, x.document_type, x.document_ref,
      x.credential_type, x.credential_material, x.enrolling_actor_ref, x.actor_credential];
    if (required.some((s) => s === undefined || s.trim() === "") || !this.refOk(x.enrolling_actor_ref)) return { refused: "invalid-request" };  // 1, 2
    const now = this.seam.now();
    if (!partyIdentity.validEnroll(now, x.name, x.date_of_birth, x.document_type, x.document_ref, x.enrolling_actor_ref)) return { refused: "invalid-request" };  // 3
    if (!credential.validRegister(now, "principal", x.credential_material, x.credential_type, x.expires_at)) return { refused: "invalid-request" };
    if (!this.fits(x.enrolling_actor_ref, { invitation_token: x.invitation_token, accepting_identity_ref: x.accepting_identity_ref, party_id: this.pad(),
      credential_id: this.pad(), stage: "credential-registration", reason: "onboarding-indeterminate", document_type: x.document_type, document_ref: x.document_ref }))
      return { refused: "invalid-request" };                                                            // 5, 6
    if (x.resume_party_id !== undefined || x.resume_credential_id !== undefined) {                     // 7 through 9
      const [i] = invitation.read(this.db, this.seam, { invitation_token: x.invitation_token });
      if (i && i.status === "pending") return { refused: "invalid-request" };
    }
    const attemptData = { invitation_token: x.invitation_token, accepting_identity_ref: x.accepting_identity_ref, document_type: x.document_type, document_ref: x.document_ref };
    const a = this.attempt("onboarding.accept-attempt", x.enrolling_actor_ref, x.actor_credential, attemptData);  // 8
    if ("refused" in a) return a;
    const arc: Arc = { token: x.invitation_token, inv: { now, attemptSeq: a.seq }, input: x };
    const g = invitation.resolve(this.db, this.seam, this.f, "accept", x.invitation_token, { accepting_identity_ref: x.accepting_identity_ref });  // 9
    if ("ok" in g) {
      if (!this.cs.take(arc.token)) return { refused: "storage-failure", position: "outcome" };        // 10, 11
      try { return this.freshArc(arc); } finally { this.cs.release(arc.token); }                       // 39
    }
    switch (g.refused) {
      case "expired": return { refused: "invitation-invalid", reason: "expired" };                     // 17
      case "not-known": return { refused: "invitation-invalid", reason: "not-known" };                 // 18
      case "invalid-request": return { refused: "invalid-request" };                                   // 21
      case "storage-failure": return { refused: "storage-failure", position: "intent" };               // Audit arm 14
    }
    if (g.stored !== "accepted") return { refused: "invitation-invalid", reason: "already-resolved", stored: g.stored };  // 19
    const [i] = invitation.read(this.db, this.seam, { invitation_token: arc.token });                   // 20
    const resumable = i.accepting_identity_ref === x.accepting_identity_ref && Date.parse(i.accepted_at!) + this.widened < Date.parse(now);  // Term resumable acceptance
    if (!resumable) return { refused: "invitation-invalid", reason: "already-resolved", stored: "accepted" };  // 23
    return this.resume(arc);                                                                            // 22
  }

  private freshArc(arc: Arc): { ok: { party_id: string; credential_id: string } } | Refusal {
    const x = arc.input;
    const accepted = this.post("onboarding.invitation-accepted", x.enrolling_actor_ref, x.actor_credential,
      { invitation_token: arc.token, accepting_identity_ref: x.accepting_identity_ref, document_type: x.document_type, document_ref: x.document_ref }, arc.inv.attemptSeq);  // 25
    if ("refused" in accepted) return accepted;
    const e = partyIdentity.enroll(this.db, this.seam, this.f, x.name, x.date_of_birth, x.document_type, x.document_ref, x.enrolling_actor_ref);  // 26
    if ("refused" in e) return this.interrupt(arc, "party-enrollment", e.refused, undefined,
      e.refused === "invalid-request" ? { refused: "invalid-request" } : { refused: "storage-failure", position: "outcome" });  // 27, 28; Audit arm 15
    return this.registerAndComplete(arc, e.ok, false);
  }

  // Action wiring 29 through 38; on the resume arm, Resume 39 through 47.
  private registerAndComplete(arc: Arc, party_id: string, resumed: boolean): { ok: { party_id: string; credential_id: string } } | Refusal {
    const x = arc.input;
    let credential_id: string;
    const r = credential.register(this.db, this.seam, this.f, party_id, x.credential_material, x.credential_type, x.expires_at);
    if ("ok" in r) credential_id = r.ok;
    else if (r.refused === "duplicate-active-credential" && resumed) {                                // 33
      const c = this.credentialCandidates(arc, party_id);
      if (x.resume_credential_id !== undefined) {
        if (!c.includes(x.resume_credential_id)) return { refused: "invalid-request" };                 // 44
        credential_id = x.resume_credential_id;                                                          // 45
      } else if (c.length === 1) credential_id = c[0];                                                   // 41
      else return this.interrupt(arc, "credential-registration", "onboarding-indeterminate", party_id,
        { refused: "onboarding-indeterminate", credential_candidates: c });                             // 42, 43, 47
    } else {
      const answer: Refusal = r.refused === "invalid-request" ? { refused: "invalid-request" }          // 31
        : r.refused === "duplicate-active-credential" ? { refused: "duplicate-active-credential" }       // 32
        : { refused: "storage-failure", position: "outcome" };                                          // Audit arm 16
      return this.interrupt(arc, "credential-registration", r.refused, party_id, answer);               // 30
    }
    const done = this.post("onboarding.completed", x.enrolling_actor_ref, x.actor_credential,
      { invitation_token: arc.token, accepting_identity_ref: x.accepting_identity_ref, party_id, credential_id }, arc.inv.attemptSeq);  // 37
    return "refused" in done ? done : { ok: { party_id, credential_id } };                              // 38
  }

  // Action wiring 27, 30 and 36: the record's own refusal never changes the arc's answer.
  private interrupt(arc: Arc, stage: Stage, reason: string, party_id: string | undefined, answer: Refusal): Refusal {
    this.post("onboarding.interrupted", arc.input.enrolling_actor_ref, arc.input.actor_credential,
      { invitation_token: arc.token, accepting_identity_ref: arc.input.accepting_identity_ref, ...(party_id ? { party_id } : {}), stage, reason }, arc.inv.attemptSeq);
    return answer;
  }

  // ---- the resume arm ----
  private resume(arc: Arc): { ok: { party_id: string; credential_id: string } } | Refusal {
    if (!this.cs.take(arc.token)) return { refused: "storage-failure", position: "intent" };             // Resume 1, 2
    try { return this.resumeHeld(arc); } finally { this.cs.release(arc.token); }                         // 3
  }

  private tokenEvents(token: string) { return this.events().filter((e) => e.data.invitation_token === token); }

  private resumeHeld(arc: Arc): { ok: { party_id: string; credential_id: string } } | Refusal {
    const x = arc.input, now = Date.parse(arc.inv.now), c = this.config;
    const [i] = invitation.read(this.db, this.seam, { invitation_token: arc.token });
    if (Date.parse(i.accepted_at!) + c.auditHorizonMs - c.clockOffsetAllowanceMs! < now)
      return { refused: "invitation-invalid", reason: "already-resolved", stored: "accepted" };          // 4, 5
    const evs = this.tokenEvents(arc.token);                                                             // 6
    if (evs.some((e) => e.action_ref === "onboarding.completed")) return { refused: "invitation-invalid", reason: "already-resolved", stored: "accepted" };  // 7
    const resumes = evs.filter((e) => e.action_ref === "onboarding.resume-intended");
    const last = resumes.at(-1);
    const openResume = last && !evs.some((e) => e.seq > last.seq && ["onboarding.completed", "onboarding.interrupted"].includes(e.action_ref));
    if (openResume && !(Date.parse(last!.recorded_at) + this.widened < now))
      return { refused: "invitation-invalid", reason: "already-resolved", stored: "accepted" };          // 8
    const acceptance = evs.find((e) => e.action_ref === "onboarding.invitation-accepted");
    const interruption = evs.filter((e) => e.action_ref === "onboarding.interrupted").at(-1);
    let stage: Stage, party_id: string | undefined;
    if (!acceptance) stage = "acceptance-unrecorded";                                                    // 11 (see CORNERS.md on 9)
    else if (openResume) stage = "unrecorded";                                                           // 9
    else if (interruption) { stage = interruption.data.stage as Stage; party_id = interruption.data.party_id as string | undefined; }  // 10
    else stage = "unrecorded";                                                                           // 12
    // 13, 14: the arc's recorded documents; 15: the call's pair among them.
    const attempts = evs.filter((e) => e.action_ref === "onboarding.accept-attempt" && e.data.accepting_identity_ref === x.accepting_identity_ref);
    const docs = acceptance ? [acceptance] : attempts;
    if (!docs.some((e) => e.data.document_type === x.document_type && e.data.document_ref === x.document_ref)) return { refused: "invalid-request" };
    const union = this.windowUnion(i.accepted_at!, resumes.map((e) => e.recorded_at));
    if (stage === "unrecorded" && !party_id) {                                                           // 16 through 26
      const q = partyIdentity.read(this.db, { enrolled_at: union });
      if ("refused" in q) { this.alerts.push({ kind: "party-invalid-query", detail: arc.token }); return { refused: "invalid-request" }; }
      const actors = new Set([...(acceptance ? [acceptance] : attempts), ...resumes].map((e) => e.actor_ref));  // Term arc's actor set
      const candidates = q.ok.filter((p) => docs.some((d) => d.data.document_type === p.document_type && d.data.document_ref === p.document_ref) &&
        actors.has(p.enrolling_actor_ref)).map((p) => p.party_id);
      if (x.resume_party_id !== undefined) {
        if (!candidates.includes(x.resume_party_id)) return { refused: "invalid-request" };             // 22
        party_id = x.resume_party_id;                                                                    // 23
      } else if (candidates.length === 1) party_id = candidates[0];                                      // 20
      else if (candidates.length > 1) return { refused: "onboarding-indeterminate", party_candidates: candidates };  // 21
    }
    // 27 through 29, 34 through 37: the resume record before any constituent write.
    const rec = this.post("onboarding.resume-intended", x.enrolling_actor_ref, x.actor_credential,
      { invitation_token: arc.token, accepting_identity_ref: x.accepting_identity_ref, document_type: x.document_type, document_ref: x.document_ref,
        stage, ...(party_id ? { party_id } : {}) }, arc.inv.attemptSeq, "intent");
    if ("refused" in rec) return rec;
    if (stage === "acceptance-unrecorded") {                                                             // 30
      const acc = this.post("onboarding.invitation-accepted", x.enrolling_actor_ref, x.actor_credential,
        { invitation_token: arc.token, accepting_identity_ref: i.accepting_identity_ref, document_type: x.document_type, document_ref: x.document_ref }, arc.inv.attemptSeq);
      if ("refused" in acc) return acc;
    }
    if (!party_id) {                                                                                     // 31
      const e = partyIdentity.enroll(this.db, this.seam, this.f, x.name, x.date_of_birth, x.document_type, x.document_ref, x.enrolling_actor_ref);
      if ("refused" in e) return this.interrupt(arc, "party-enrollment", e.refused, undefined,
        e.refused === "invalid-request" ? { refused: "invalid-request" } : { refused: "storage-failure", position: "outcome" });
      party_id = e.ok;
    }
    return this.registerAndComplete(arc, party_id, true);                                                // 32
  }

  // Term arc's window union: one read from the earliest lower edge to the latest upper edge.
  private windowUnion(accepted_at: string, resumeInstants: string[]): { from: string; to: string } {
    const anchors = [accepted_at, ...resumeInstants].map(Date.parse), a = this.config.clockOffsetAllowanceMs!;
    return { from: new Date(Math.min(...anchors) - a).toISOString(), to: new Date(Math.max(...anchors) + this.widened).toISOString() };
  }
  // Resume 39, 40: chain roots registered inside the window union.
  private credentialCandidates(arc: Arc, party_id: string): string[] {
    const [i] = invitation.read(this.db, this.seam, { invitation_token: arc.token });
    const union = this.windowUnion(i.accepted_at!, this.tokenEvents(arc.token).filter((e) => e.action_ref === "onboarding.resume-intended").map((e) => e.recorded_at));
    const all = credential.read(this.db, { principal_ref: party_id, credential_type: arc.input.credential_type });
    const successors = new Set(all.map((c) => c.successor_id).filter(Boolean));
    return all.filter((c) => !successors.has(c.credential_id) && c.registered_at >= union.from && c.registered_at <= union.to).map((c) => c.credential_id);
  }

  // ---- [Decline] (Action wiring 40 through 47) and [Revoke] (48 through 55) ----
  decline(invitation_token: string, service_actor_ref: string, actor_credential: string): { ok: "declined" } | Refusal {
    if ([invitation_token, actor_credential].some((s) => s.trim() === "") || !this.refOk(service_actor_ref)) return { refused: "invalid-request" };
    this.seam.now();
    const a = this.attempt("invitation.decline-attempt", service_actor_ref, actor_credential, { invitation_token });
    if ("refused" in a) return a;
    const r = invitation.resolve(this.db, this.seam, this.f, "decline", invitation_token, {});
    if ("refused" in r) return this.gateRefusal(r);
    const p = this.post("invitation.declined", service_actor_ref, actor_credential, { invitation_token }, a.seq);
    return "refused" in p ? p : { ok: "declined" };
  }
  revoke(invitation_token: string, revoked_by_ref: string, reason: string, actor_credential: string): { ok: "revoked" } | Refusal {
    if ([invitation_token, reason, actor_credential].some((s) => s.trim() === "") || !this.refOk(revoked_by_ref)) return { refused: "invalid-request" };
    this.seam.now();
    const a = this.attempt("invitation.revoke-attempt", revoked_by_ref, actor_credential, { invitation_token, reason });
    if ("refused" in a) return a;
    const r = invitation.resolve(this.db, this.seam, this.f, "revoke", invitation_token, { revoked_by_ref, reason });
    if ("refused" in r) return this.gateRefusal(r);
    const p = this.post("invitation.revoked", revoked_by_ref, actor_credential, { invitation_token, reason }, a.seq);
    return "refused" in p ? p : { ok: "revoked" };
  }
  private gateRefusal(r: { refused: string; stored?: string }): Refusal {
    if (r.refused === "expired" || r.refused === "not-known") return { refused: "invitation-invalid", reason: r.refused };
    if (r.refused === "already-resolved") return { refused: "invitation-invalid", reason: "already-resolved", stored: r.stored };
    if (r.refused === "invalid-request") return { refused: "invalid-request" };
    return { refused: "storage-failure", position: "intent" };
  }
}
