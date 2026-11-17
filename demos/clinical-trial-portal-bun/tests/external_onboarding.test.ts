// External Onboarding's [Invite], [Decline] and [Revoke], one test for each rule the render answers, named by the rule's label.
import { test, expect, afterAll } from "bun:test";
import { Store } from "../src/store.ts";
import { canonical } from "../src/canonical.ts";
import { ExternalOnboarding } from "../src/external_onboarding.ts";
import { eoWorld } from "./eo_world.ts";

const store = new Store();
afterAll(() => store.close());
const world = eoWorld(store);
const bad = (r: unknown) => r as { refused: string; position?: string; cause?: string; stored_terminal?: string };
const nothing = async (w: Awaited<ReturnType<typeof world>>) => { expect(await w.events()).toEqual([]); expect(await w.invitations()).toEqual([]); };
const step = (s: "step-1" | "step-2" | "step-3" | "step-4") => ({ refusal: { refused: "invalid-request" as const, step: s, committed_ids: [] }, keep: [] });

test("Action wiring 1, 3, 4, 6, 7, Composes 14, Invariant 4.2: an invite records its attempt, then Invitation's initiate, then the initiated record, one transaction, and answers the token", async () => {
  const w = await world();
  const r = await w.eo.invite(w.inviter.ref, "new@acme.com", "org::acme", 3600, w.inviter.priv);
  const token = (r as { invitation_token: string }).invitation_token;
  const ev = await w.events();
  expect(ev.map((e) => e.action_ref)).toEqual(["invitation.initiate-attempt", "invitation.initiated"]);
  expect(ev.map((e) => e.seq)).toEqual([1, 2]);                                                                  // one transaction: the two records number one after the other
  expect(ev.map((e) => e.actor_ref)).toEqual([w.inviter.ref, w.inviter.ref]);                                    // Composes 14: attested under the calling actor
  expect(ev[0].data).toEqual({ invitee_ref: "new@acme.com", context: "org::acme", ttl: 3600 });
  expect(ev[1].data).toEqual({ invitation_token: token, invitee_ref: "new@acme.com", context: "org::acme", ttl: 3600 });
  const inv = await w.invitations();
  expect(inv).toHaveLength(1);
  expect(inv[0]).toMatchObject({ _id: token, inviter_ref: w.inviter.ref, invitee_ref: "new@acme.com", context: "org::acme", status: "pending" });
  expect(w.plans).toEqual([{ action: "invitation.initiate-attempt", actor: w.inviter.ref, ahead: 0 }, { action: "invitation.initiated", actor: w.inviter.ref, ahead: 1 }]);
  expect(await w.attestations(w.inviter.ref)).toHaveLength(2);
});

test("Action wiring 3, 6: the invitee reference and the ttl are blank on both records where the call supplies none, and the default ttl applies", async () => {
  const w = await world();
  const r = await w.eo.invite(w.inviter.ref, undefined, "org::acme", undefined, w.inviter.priv);
  expect(bad(r).refused).toBeUndefined();
  const ev = await w.events();
  expect(ev[0].data).toEqual({ invitee_ref: null, context: "org::acme", ttl: null });
  expect(ev[1].data).toMatchObject({ invitee_ref: null, ttl: null });
  expect((await w.invitations())[0].expires_at).toBe("2026-09-08T10:00:00.000Z");                                // seven days, Invitation's default
  const again = await w.eo.invite(w.inviter.ref, "  ", "org::b", null, w.inviter.priv);                          // a blank invitee reads as none
  expect(bad(again).refused).toBeUndefined();
  expect((await w.events())[2].data).toEqual({ invitee_ref: null, context: "org::b", ttl: null });
});

test("Action wiring 1, 2, Audit arm 1, Non-goal 10: a refused credential answers invalid-credential, nothing written, and no constituent is called", async () => {
  const w = await world();
  const other = w.person();
  expect(bad(await w.eo.invite(w.inviter.ref, null, "org::acme", 3600, other.priv))).toEqual({ refused: "invalid-credential" });
  expect(bad(await w.eo.invite("unknown-actor", null, "org::acme", 3600, w.inviter.priv))).toEqual({ refused: "invalid-credential" });
  await nothing(w);
  expect(await w.attestations(w.inviter.ref)).toEqual([]);                                                       // the refused attempt is not recorded
  const token = await w.issue();
  const before = (await w.events()).length;
  expect(bad(await w.eo.decline(token, w.service.ref, other.priv))).toEqual({ refused: "invalid-credential" });
  expect(bad(await w.eo.revoke(token, w.inviter.ref, "no longer needed", other.priv))).toEqual({ refused: "invalid-credential" });
  expect((await w.events()).length).toBe(before);
  expect((await w.invitations())[0].status).toBe("pending");                                                     // Action wiring 1: the constituent was never reached
});

test("Primitive policy 1, 4, 10: a blank required input answers invalid-request, writes nothing and records no attempt", async () => {
  const w = await world();
  const p = w.inviter.priv;
  const token = await w.issue();
  const calls = w.plans.length;
  const cases: unknown[] = [
    await w.eo.invite("", null, "ctx", 3600, p), await w.eo.invite("  ", null, "ctx", 3600, p),
    await w.eo.invite(w.inviter.ref, null, "", 3600, p), await w.eo.invite(w.inviter.ref, null, "ctx", 3600, " "),
    await w.eo.decline("", w.service.ref, p), await w.eo.decline(token, "", p), await w.eo.decline(token, w.service.ref, ""),
    await w.eo.revoke("", w.inviter.ref, "why", p), await w.eo.revoke(token, "", "why", p), await w.eo.revoke(token, w.inviter.ref, " ", p), await w.eo.revoke(token, w.inviter.ref, "why", ""),
  ];
  for (const c of cases) expect(c).toEqual({ refused: "invalid-request" });
  expect(w.plans.length).toBe(calls);                                                                            // Primitive policy 4: no attempt record before the inputs are validated
  expect((await w.events()).length).toBe(2);                                                                     // only the issue's pair
});

test("Primitive policy 2, 10: an actor reference over the reference length cap answers invalid-request; one at the cap goes to the gate", async () => {
  const w = await world();
  const at = "a".repeat(128), over = "a".repeat(129);
  expect(bad(await w.eo.invite(at, null, "ctx", 3600, w.inviter.priv)).refused).toBe("invalid-credential");      // inside the cap: the gate refuses the unknown actor
  expect(await w.eo.invite(over, null, "ctx", 3600, w.inviter.priv)).toEqual({ refused: "invalid-request" });
  const token = await w.issue();
  expect(await w.eo.decline(token, over, w.inviter.priv)).toEqual({ refused: "invalid-request" });
  expect(await w.eo.revoke(token, over, "why", w.inviter.priv)).toEqual({ refused: "invalid-request" });
  expect(await w.eo.decline(token, at, w.inviter.priv)).toEqual({ refused: "invalid-credential" });
  expect(w.plans.every((p) => p.actor !== over)).toBe(true);
});

test("Primitive policy 3, 10: a field Invitation's own rules refuse answers invalid-request before any record", async () => {
  const w = await world();
  const p = w.inviter.priv;
  const bounds = [59, 30 * 86_400 + 1, 1.5, 0, -5, "3600" as unknown as number];
  for (const ttl of bounds) expect(await w.eo.invite(w.inviter.ref, null, "ctx", ttl, p)).toEqual({ refused: "invalid-request" });
  expect(await w.eo.invite(w.inviter.ref, null, "c".repeat(257), 3600, p)).toEqual({ refused: "invalid-request" });
  expect(await w.eo.invite(w.inviter.ref, "i".repeat(257), "ctx", 3600, p)).toEqual({ refused: "invalid-request" });
  const token = await w.issue();
  expect(await w.eo.revoke(token, w.inviter.ref, "r".repeat(257), p)).toEqual({ refused: "invalid-request" });
  expect(w.plans.length).toBe(2);                                                                                // the issue's two plans alone
  expect(bad(await w.eo.invite(w.inviter.ref, null, "ctx", 60, p)).refused).toBeUndefined();                    // the bounds are inclusive
  expect(bad(await w.eo.invite(w.inviter.ref, null, "ctx", 30 * 86_400, p)).refused).toBeUndefined();
});

test("Primitive policy 5, 6, 10: the data of an event over the payload cap answers invalid-request, the minted token sized at its width bound", async () => {
  const ref = "actor-x";
  const need = (w: number) => new TextEncoder().encode(canonical({ action_ref: "invitation.initiated", actor_ref: ref, attestation_id: "x".repeat(36), data: { invitation_token: "x".repeat(w), invitee_ref: null, context: "ctx", ttl: 3600 } })).length;
  const run = async (payloadCap: number, width: number) => {
    const w = await world({ payloadCap, widths: { invitationToken: width, partyId: 36, credentialId: 36, eventId: 36 } });
    // the real actor reference is longer than `ref`; size the cap against it
    const grow = w.inviter.ref.length - ref.length;
    const r = await w.eo.invite(w.inviter.ref, null, "ctx", 3600, w.inviter.priv);
    return { r, w, grow };
  };
  const probe = await run(65_536, 43);
  const cap = need(43) + probe.grow;
  const fits = await run(cap, 43);
  expect(bad(fits.r).refused).toBeUndefined();                                                                   // exactly at the cap: admitted
  const over = await run(cap - 1, 43);
  expect(over.r).toEqual({ refused: "invalid-request" });
  await nothing(over.w);
  const wider = await run(cap, 44);                                                                              // Primitive policy 6: sized at the declared width, not at the width this call minted
  expect(wider.r).toEqual({ refused: "invalid-request" });
  await nothing(wider.w);
  const w = await world({ payloadCap: 90 });                                                                    // the attempt record alone is over a small cap, for decline and revoke too
  expect(await w.eo.decline("t".repeat(43), w.service.ref, w.service.priv)).toEqual({ refused: "invalid-request" });
  expect(await w.eo.revoke("t".repeat(43), w.inviter.ref, "reason", w.inviter.priv)).toEqual({ refused: "invalid-request" });
  expect(w.plans).toEqual([]);
});

test("Audit arm 2, 3, 19, Execution Contract Constituent failure 4: a recording failure, or an invalid-request below step-3, at the attempt record answers storage-failure carrying intent, nothing written", async () => {
  const w = await world();
  w.script.push({ refusal: { refused: "recording-failure", step: "step-2" }, keep: [] });
  expect(bad(await w.eo.invite(w.inviter.ref, null, "ctx", 3600, w.inviter.priv))).toEqual({ refused: "storage-failure", position: "intent" });
  expect(w.alerts).toEqual([]);                                                                                  // a recording failure is no invalid-request from the substrate
  for (const s of ["step-1", "step-2"] as const) {
    w.script.push(step(s));
    expect(bad(await w.eo.invite(w.inviter.ref, null, "ctx", 3600, w.inviter.priv))).toEqual({ refused: "storage-failure", position: "intent" });
  }
  expect(w.alerts.map((a) => a.step)).toEqual(["step-1", "step-2"]);                                             // Audit arm 19
  await nothing(w);
  expect(w.plans.map((p) => p.ahead)).toEqual([0, 0, 0]);                                                         // Audit arm 4: the refused attempt record stopped the action
});

test("Audit arm 21, 23, 24: an attempt record refused at step-3 or step-4 answers storage-failure carrying attempt-evidence, its attestation committed and no constituent written", async () => {
  const w = await world();
  for (const s of ["step-3", "step-4"] as const) {
    const real = await w.at.plan("invitation.initiate-attempt", w.inviter.ref, w.inviter.priv, { invitee_ref: null, context: "ctx", ttl: 3600 });
    if ("refusal" in real) throw new Error("the real plan refused");
    w.script.push({ refusal: { refused: "invalid-request", step: s, committed_ids: [real.event_id] }, keep: real.stmts as never });
    expect(bad(await w.eo.invite(w.inviter.ref, null, "ctx", 3600, w.inviter.priv))).toEqual({ refused: "storage-failure", position: "attempt-evidence" });
    expect(await w.invitations()).toEqual([]);                                                                   // Audit arm 23: no constituent has written
  }
  expect(await w.attestations(w.inviter.ref)).toHaveLength(2);                                                   // the attestations stand committed, one for each refusal
  expect(w.alerts.map((a) => a.step)).toEqual(["step-3", "step-4"]);
});

test("Audit arm 5, 13, 22, 17: a post-write record refused answers as its refusal says and rolls the whole action back", async () => {
  const w = await world();
  const refusals: [unknown, unknown][] = [
    [{ refusal: { refused: "recording-failure", step: "step-3" }, keep: [] }, { refused: "storage-failure", position: "intent" }],     // Audit arm 5
    [step("step-3"), { refused: "storage-failure", position: "intent" }],                                                              // Audit arm 22
    [step("step-1"), { refused: "storage-failure", position: "intent" }],
    [{ refusal: { refused: "invalid-credential" }, keep: [] }, { refused: "invalid-credential" }],                                     // Audit arm 13
  ];
  for (const [scripted, answer] of refusals) {
    w.script.push(undefined, scripted as never);                                                                 // the attempt record is real, the post-write record refused
    expect(bad(await w.eo.invite(w.inviter.ref, null, "ctx", 3600, w.inviter.priv))).toEqual(answer as never);
    await nothing(w);                                                                                            // a committed nothing: not the attempt record, not the invitation
  }
  expect(w.alerts.map((a) => a.step)).toEqual(["step-3", "step-1"]);                                             // the two invalid-requests alerted
  const token = await w.issue();
  w.script.push(undefined, { refusal: { refused: "recording-failure", step: "step-4" }, keep: [] });
  expect(bad(await w.eo.decline(token, w.service.ref, w.service.priv))).toEqual({ refused: "storage-failure", position: "intent" });
  expect((await w.invitations())[0].status).toBe("pending");                                                     // the decline rolled back
  w.script.push(undefined, step("step-3"));
  expect(bad(await w.eo.revoke(token, w.inviter.ref, "why", w.inviter.priv))).toEqual({ refused: "storage-failure", position: "intent" });
  expect((await w.invitations())[0].status).toBe("pending");
});

test("Audit arm 8, 9, 10, 11: a post-write record refused at step-4 is read back from the attempt record's sequence number to the open end, and found, the action proceeds as landed", async () => {
  const w = await world();
  const first = await w.issue();                                                                                 // events 1 and 2
  w.policy["invitation.initiated"] = "no-such-policy";                                                            // the substrate's real step-4 refusal: the event appends, its retention cannot be placed
  w.reads.length = 0;
  const r = await w.eo.invite(w.inviter.ref, null, "second", 3600, w.inviter.priv);
  const token = (r as { invitation_token: string }).invitation_token;
  expect(token).toBeDefined();
  expect(w.reads).toEqual([{ sequence: { from: 3 } }]);                                                           // from the attempt record's own sequence number, with no end
  expect((await w.events()).map((e) => e.action_ref)).toEqual(["invitation.initiate-attempt", "invitation.initiated", "invitation.initiate-attempt", "invitation.initiated"]);
  expect((await w.invitations()).map((i) => i._id).sort()).toEqual([first, token].sort());                       // the action's own write stands
  expect(w.alerts.map((a) => a.step)).toEqual(["step-4"]);
  // [Decline] and [Revoke] meet the same arm.
  w.policy["invitation.declined"] = "no-such-policy"; w.policy["invitation.revoked"] = "no-such-policy";
  expect(await w.eo.decline(first, w.service.ref, w.service.priv)).toBe("declined");
  expect(await w.eo.revoke(token, w.inviter.ref, "why", w.inviter.priv)).toBe("revoked");
  expect(w.reads).toEqual([{ sequence: { from: 3 } }, { sequence: { from: 5 } }, { sequence: { from: 7 } }]);
  const rows = Object.fromEntries((await w.invitations()).map((i) => [i._id as string, i.status]));
  expect(rows).toEqual({ [first]: "declined", [token]: "revoked" });
});

test("Audit arm 25: a post-write record refused at step-4 that the substrate kept none of answers storage-failure carrying intent, nothing written", async () => {
  const w = await world();
  w.script.push(undefined, step("step-4"));
  expect(bad(await w.eo.invite(w.inviter.ref, null, "ctx", 3600, w.inviter.priv))).toEqual({ refused: "storage-failure", position: "intent" });
  await nothing(w);
  expect(w.reads).toEqual([]);                                                                                   // nothing was kept, so nothing is read back
});

test("Audit arm 14, 17, Execution Contract Constituent failure 1: a write that fails answers storage-failure carrying intent, the attempt record and the post-write record with it", async () => {
  const w = await world();
  const first = await w.issue();
  const held = (w.seam as unknown as { tokenMaterial: () => string });
  held.tokenMaterial = () => first;                                                                              // the token the database already holds (Identity 5, 6)
  expect(bad(await w.eo.invite(w.inviter.ref, null, "again", 3600, w.inviter.priv))).toEqual({ refused: "storage-failure", position: "intent" });
  expect((await w.events()).length).toBe(2);                                                                     // the first invite's pair alone
  expect(await w.invitations()).toHaveLength(1);
});

test("Execution Contract Constituent failure 3, Read 1: a failed read of the database answers state-unavailable, nothing written", async () => {
  const w = await world();
  w.script.push("unavailable");
  expect(bad(await w.eo.invite(w.inviter.ref, null, "ctx", 3600, w.inviter.priv))).toEqual({ refused: "state-unavailable" });
  w.script.push(undefined, "unavailable");
  expect(bad(await w.eo.invite(w.inviter.ref, null, "ctx", 3600, w.inviter.priv))).toEqual({ refused: "state-unavailable" });
  await nothing(w);
  const token = await w.issue();
  w.script.push("unavailable");
  expect(bad(await w.eo.decline(token, w.service.ref, w.service.priv))).toEqual({ refused: "state-unavailable" });
  w.script.push("unavailable");
  expect(bad(await w.eo.revoke(token, w.inviter.ref, "why", w.inviter.priv))).toEqual({ refused: "state-unavailable" });
  expect((await w.invitations())[0].status).toBe("pending");
});

test("Action wiring 40, 41, 45, 46, 47: a decline records its attempt under the service actor reference, declines the invitation, records the token alone, and answers declined", async () => {
  const w = await world();
  const token = await w.issue();
  const before = (await w.events()).length;
  expect(await w.eo.decline(token, w.service.ref, w.service.priv)).toBe("declined");
  const ev = (await w.events()).slice(before);
  expect(ev.map((e) => e.action_ref)).toEqual(["invitation.decline-attempt", "invitation.declined"]);
  expect(ev.map((e) => e.seq)).toEqual([before + 1, before + 2]);
  expect(ev.map((e) => e.actor_ref)).toEqual([w.service.ref, w.service.ref]);
  expect(ev.map((e) => e.data)).toEqual([{ invitation_token: token }, { invitation_token: token }]);            // Action wiring 47: no decliner's identity
  expect((await w.invitations())[0].status).toBe("declined");
});

test("Action wiring 42, 43, 44: a decline Invitation refuses answers invitation-invalid carrying the refusal, nothing written", async () => {
  const w = await world();
  const token = await w.issue();
  const n = (await w.events()).length;
  expect(bad(await w.eo.decline("no-such-token", w.service.ref, w.service.priv))).toEqual({ refused: "invitation-invalid", cause: "not-known" });
  w.seam.advance(3600 * 1000);                                                                                   // the issue's ttl, the boundary instant reads lapsed
  expect(bad(await w.eo.decline(token, w.service.ref, w.service.priv))).toEqual({ refused: "invitation-invalid", cause: "expired" });
  const fresh = await w.issue("two");
  expect(await w.eo.decline(fresh, w.service.ref, w.service.priv)).toBe("declined");
  expect(bad(await w.eo.decline(fresh, w.service.ref, w.service.priv))).toEqual({ refused: "invitation-invalid", cause: "already-resolved", stored_terminal: "declined" });
  const third = await w.issue("three");
  expect(await w.eo.revoke(third, w.inviter.ref, "why", w.inviter.priv)).toBe("revoked");
  expect(bad(await w.eo.decline(third, w.service.ref, w.service.priv))).toEqual({ refused: "invitation-invalid", cause: "already-resolved", stored_terminal: "revoked" });
  const fourth = await w.issue("four");
  expect(await w.invitation.accept(fourth, "someone@acme.com")).toBe("accepted");                                // resolved outside the composition (Composes 10)
  expect(bad(await w.eo.decline(fourth, w.service.ref, w.service.priv))).toEqual({ refused: "invitation-invalid", cause: "already-resolved", stored_terminal: "accepted" });
  expect((await w.events()).length).toBe(n + 3 * 2 + 2 + 2);                                                     // three issues, one landed decline and one landed revoke, a pair each; the refusals added none
});

test("Action wiring 48, 49, 54, 55: a revoke records its attempt and its record with the reason under the revoked by reference, revokes the invitation, and answers revoked", async () => {
  const w = await world();
  const token = await w.issue();
  const before = (await w.events()).length;
  expect(await w.eo.revoke(token, w.inviter.ref, "issued in error", w.inviter.priv)).toBe("revoked");
  const ev = (await w.events()).slice(before);
  expect(ev.map((e) => e.action_ref)).toEqual(["invitation.revoke-attempt", "invitation.revoked"]);
  expect(ev.map((e) => e.actor_ref)).toEqual([w.inviter.ref, w.inviter.ref]);
  expect(ev.map((e) => e.data)).toEqual([{ invitation_token: token, revocation_reason: "issued in error" }, { invitation_token: token, revocation_reason: "issued in error" }]);
  expect((await w.invitations())[0]).toMatchObject({ status: "revoked", revoked_by_ref: w.inviter.ref, revocation_reason: "issued in error" });
});

test("Action wiring 50, 51, 52: a revoke Invitation refuses answers invitation-invalid carrying the refusal, nothing written", async () => {
  const w = await world();
  const token = await w.issue();
  const n = (await w.events()).length;
  expect(bad(await w.eo.revoke("no-such-token", w.inviter.ref, "why", w.inviter.priv))).toEqual({ refused: "invitation-invalid", cause: "not-known" });
  expect(await w.eo.revoke(token, w.inviter.ref, "why", w.inviter.priv)).toBe("revoked");
  expect(bad(await w.eo.revoke(token, w.inviter.ref, "again", w.inviter.priv))).toEqual({ refused: "invitation-invalid", cause: "already-resolved", stored_terminal: "revoked" });
  const second = await w.issue("two");
  w.seam.advance(3600 * 1000);
  expect(bad(await w.eo.revoke(second, w.inviter.ref, "why", w.inviter.priv))).toEqual({ refused: "invitation-invalid", cause: "expired" });
  expect((await w.events()).length).toBe(n + 2 + 2);                                                             // the one landed revoke and the second issue; the refusals added none
});

test("Concurrency 1, Invariant 4.1: two declines of one invitation resolve through Invitation's single resolution, one landed pair of records and one invitation-invalid", async () => {
  const w = await world();
  const token = await w.issue();
  const n = (await w.events()).length;
  const [x, y] = await Promise.all([w.eo.decline(token, w.service.ref, w.service.priv), w.eo.decline(token, w.service.ref, w.service.priv)]);
  const answers = [x, y].map((a) => (typeof a === "string" ? a : `${bad(a).cause}:${bad(a).stored_terminal}`)).sort();
  expect(answers).toEqual(["already-resolved:declined", "declined"]);
  expect((await w.events()).length).toBe(n + 2);                                                                 // the loser wrote nothing
  expect((await w.invitations())[0].status).toBe("declined");
});

test("Concurrency 1: an invitation resolved outside the composition between the plan and the commit is planned again, and answers what it now is", async () => {
  const w = await world();
  const token = await w.issue();
  const n = (await w.events()).length;
  w.hook.run = async (action) => { if (action === "invitation.declined") { w.hook.run = null; expect(await w.invitation.accept(token, "someone@acme.com")).toBe("accepted"); } };
  expect(bad(await w.eo.decline(token, w.service.ref, w.service.priv))).toEqual({ refused: "invitation-invalid", cause: "already-resolved", stored_terminal: "accepted" });
  expect((await w.events()).length).toBe(n);                                                                     // the lost call wrote nothing
  expect((await w.invitations())[0].status).toBe("accepted");
});

test("Action wiring 1, Audit arm 17: two invites at once both land, their records numbered without a gap or a repeat", async () => {
  const w = await world();
  const rs = await Promise.all([1, 2, 3].map((i) => w.eo.invite(w.inviter.ref, null, `ctx-${i}`, 3600, w.inviter.priv)));
  for (const r of rs) expect(bad(r).refused).toBeUndefined();
  const ev = await w.events();
  expect(ev.map((e) => e.seq)).toEqual([1, 2, 3, 4, 5, 6]);
  for (let i = 0; i < 6; i += 2) {                                                                               // each transaction's attempt record is followed directly by its own initiated record
    expect(ev[i].action_ref).toBe("invitation.initiate-attempt");
    expect(ev[i + 1].action_ref).toBe("invitation.initiated");
    expect(ev[i].data.context).toBe(ev[i + 1].data.context);
  }
  expect(await w.invitations()).toHaveLength(3);
});

test("Capability requirement 18, 19, 22: a blank onboarding completion bound, clock offset allowance or minted-id width bounds, and the composition does not start", async () => {
  const w = await world();
  const parts = { invitation: w.invitation, trail: w.trail };
  const ok = { referenceLengthCap: 128, onboardingCompletionBoundMs: 10_000, clockOffsetAllowanceMs: 50, mintedIdWidths: { invitationToken: 43, partyId: 36, credentialId: 36, eventId: 36 } };
  await ExternalOnboarding.open(store, w.seam, parts, ok);
  await expect(ExternalOnboarding.open(store, w.seam, parts, { ...ok, onboardingCompletionBoundMs: null })).rejects.toThrow("onboarding completion bound");
  await expect(ExternalOnboarding.open(store, w.seam, parts, { ...ok, clockOffsetAllowanceMs: null })).rejects.toThrow("clock offset allowance");
  await expect(ExternalOnboarding.open(store, w.seam, parts, { ...ok, mintedIdWidths: null })).rejects.toThrow("minted-id width bounds");
});

test("EventLog plan ahead: a second plan of one transaction numbers after the first and leaves the guard to it", async () => {
  const w = await world();
  const a = await w.log.plan([{ n: 1 }]);
  const b = await w.log.plan([{ n: 2 }], 1);
  if ("refused" in a || "refused" in b) throw new Error("refused");
  expect([a.sequence_numbers, b.sequence_numbers]).toEqual([[1], [2]]);
  expect(a.stmts.length).toBe(b.stmts.length + 1);                                                               // the guard is the first plan's alone
  await w.store.commit([...a.stmts, ...b.stmts]);
  expect((await w.events()).map((e) => e.seq)).toEqual([1, 2]);
  const c = await w.log.plan([{ n: 3 }]);
  if ("refused" in c) throw new Error("refused");
  expect(c.sequence_numbers).toEqual([3]);                                                                       // the head moved past both
});
