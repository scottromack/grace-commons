// Party Identity, from atoms/party-identity.md; rule numbers are the atom's own.
import type { Database } from "@db/sqlite";
import type { Seam } from "./seam.ts";
import type { Faults } from "./faults.ts";

const blank = (s: unknown) => s === undefined || s === null || (typeof s === "string" && s.trim() === "");
export interface Party { party_id: string; state: string; enrolled_at: string }
export interface PartyEvent { kind: "verification" | "state-change"; id: string; result: string | null; prior: string | null; next: string | null; at: string }
type Refusal<T extends string> = { refused: T };

export const partyIdentity = {
  enroll(db: Database, seam: Seam, f: Faults, fields: { name: string; date_of_birth: string; document_type: string; document_ref: string }, enrolling_actor_ref: string):
    { ok: string } | Refusal<"invalid-request" | "storage-failure"> {
    const now = seam.now();
    if ([fields.name, fields.date_of_birth, fields.document_type, fields.document_ref, enrolling_actor_ref].some(blank)) return { refused: "invalid-request" };  // Operation 1
    if (isNaN(Date.parse(fields.date_of_birth)) || now < fields.date_of_birth) return { refused: "invalid-request" };  // 2, 3
    if (f.hit("pi.write", "enroll")) return { refused: "storage-failure" };
    const id = seam.id("party");
    db.prepare("INSERT INTO party VALUES (?, ?, ?, ?, ?, ?, ?, 'unverified')").run(id, fields.name, fields.date_of_birth, fields.document_type, fields.document_ref, enrolling_actor_ref, now);
    return { ok: id };                                                                                                  // 4 through 8
  },
  // Operation 10 through 41: a party action.
  verify(db: Database, seam: Seam, f: Faults, party_id: string, actor: string, method: string, result: string, evidence_ref: string):
    { ok: { verification_id: string; state_change_id?: string } } | Refusal<"not-known" | "already-closed" | "invalid-request" | "storage-failure"> {
    const p = partyIdentity.pre(db, party_id); if ("refused" in p) return p;
    if (p.ok.state === "closed") return { refused: "already-closed" };                                                    // 13
    if ([actor, method, evidence_ref].some(blank) || (result !== "passed" && result !== "failed")) return { refused: "invalid-request" };  // 1, 21
    if (f.hit("pi.write", "verify")) return { refused: "storage-failure" };
    const now = seam.now(), vid = seam.id("verification");
    db.prepare("INSERT INTO party_event (party_id, kind, id, result, actor, at) VALUES (?, 'verification', ?, ?, ?, ?)").run(party_id, vid, result, actor, now);
    if (p.ok.state === "unverified" && result === "passed") return { ok: { verification_id: vid, state_change_id: partyIdentity.transition(db, seam, party_id, "unverified", "verified", actor, null) } };  // 25, 28
    return { ok: { verification_id: vid } };                                                                             // 29
  },
  suspend(db: Database, seam: Seam, f: Faults, party_id: string, actor: string, reason: string) {
    return partyIdentity.move(db, seam, f, party_id, actor, reason, "suspend", (s) => s === "unverified" ? "not-verifiable" : s === "suspended" ? "already-suspended" : null, "suspended");  // 14, 15, 30
  },
  reinstate(db: Database, seam: Seam, f: Faults, party_id: string, actor: string, reason: string) {
    return partyIdentity.move(db, seam, f, party_id, actor, reason, "reinstate", (s) => {
      if (s !== "suspended") return "not-suspended";                                                                     // 16
      const ev = db.prepare("SELECT kind, result, next FROM party_event WHERE party_id = ? ORDER BY seq").all<{ kind: string; result: string | null; next: string | null }>(party_id);
      const lastSuspend = ev.map((e, i) => e.kind === "state-change" && e.next === "suspended" ? i : -1).reduce((a, b) => Math.max(a, b), -1);
      return ev.slice(lastSuspend + 1).some((e) => e.kind === "verification" && e.result === "passed") ? null : "no-passed-verification-since-suspend";  // 18
    }, "verified");                                                                                                       // 31
  },
  close(db: Database, seam: Seam, f: Faults, party_id: string, actor: string, reason: string) {
    return partyIdentity.move(db, seam, f, party_id, actor, reason, "close", () => null, "closed");                      // 32
  },
  pre(db: Database, party_id: string): { ok: Party } | Refusal<"invalid-request" | "not-known"> {
    if (blank(party_id)) return { refused: "invalid-request" };                                                          // 10
    const p = db.prepare("SELECT * FROM party WHERE party_id = ?").get<Party>(party_id);
    return p ? { ok: p } : { refused: "not-known" };                                                                     // 11
  },
  move(db: Database, seam: Seam, f: Faults, party_id: string, actor: string, reason: string, key: string, check: (s: string) => string | null, next: string):
    { ok: string } | Refusal<string> {
    const p = partyIdentity.pre(db, party_id); if ("refused" in p) return p;
    if (p.ok.state === "closed") return { refused: "already-closed" };
    const r = check(p.ok.state); if (r) return { refused: r };
    if (blank(actor) || blank(reason) || reason.length > 2000) return { refused: "invalid-request" };                     // 1, 20
    if (f.hit("pi.write", key)) return { refused: "storage-failure" };                                                  // 39 through 43
    return { ok: partyIdentity.transition(db, seam, party_id, p.ok.state, next, actor, reason) };
  },
  transition(db: Database, seam: Seam, party_id: string, prior: string, next: string, actor: string, reason: string | null) {  // 33 through 38
    const id = seam.id("state-change");
    db.prepare("UPDATE party SET state = ? WHERE party_id = ?").run(next, party_id);
    db.prepare("INSERT INTO party_event (party_id, kind, id, prior, next, actor, reason, at) VALUES (?, 'state-change', ?, ?, ?, ?, ?, ?)").run(party_id, id, prior, next, actor, reason, seam.now());
    return id;
  },
  // Operation 48 through 56: a singleton read by party id. A fault stands for an unanswered read (the seam's, not the atom's).
  read(db: Database, f: Faults, party_id: string): { ok: (Party & { log: PartyEvent[] })[] } | "unanswered" {
    if (f.hit("pi.read", party_id)) return "unanswered";
    const p = db.prepare("SELECT * FROM party WHERE party_id = ?").get<Party>(party_id);
    if (!p) return { ok: [] };
    return { ok: [{ ...p, log: db.prepare("SELECT kind, id, result, prior, next, at FROM party_event WHERE party_id = ? ORDER BY seq").all<PartyEvent>(party_id) }] };
  },
};
