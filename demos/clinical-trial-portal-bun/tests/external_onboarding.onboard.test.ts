// External Onboarding's [Onboard] and its onboarding probe, one test for each rule the render answers, named by the rule's label.
import { test, expect, afterAll } from "bun:test";
import { Store, Unavailable } from "../src/store.ts";
import { canonical } from "../src/canonical.ts";
import { eoWorld } from "./eo_world.ts";

const store = new Store();
afterAll(() => store.close());
const world = eoWorld(store);
type W = Awaited<ReturnType<typeof world>>;
type Ans = { refused?: string; position?: string; cause?: string; stored_terminal?: string; invocation_id?: string; constituent_code?: string; closing_event_id?: string; party_id?: string; credential_id?: string };
const ans = (r: unknown) => r as Ans;

/** An [Onboard] call: every input a valid one, any of them replaced. */
const onboard = (w: W, token: string, over: Partial<{ accepting: string; name: string; dob: string; dt: string; dr: string; ct: string; cm: string; exp: string | undefined; enrolling: string; cred: string }> = {}) => {
  const a = { accepting: "new@acme.com", name: "Ada Lovelace", dob: "1990-05-01", dt: "passport", dr: "P-123", ct: "password", cm: "correct horse", exp: undefined as string | undefined, enrolling: w.enroller.ref, cred: w.enroller.priv, ...over };
  return w.eo.onboard(token, a.accepting, a.name, a.dob, a.dt, a.dr, a.ct, a.cm, a.exp, a.enrolling, a.cred);
};
const refs = async (w: W) => (await w.events()).map((e) => e.action_ref);
const partiesOf = async (w: W, dr = "P-123") => { const all = await w.parties.read({}); return (Array.isArray(all) ? all : []).filter((p) => p.document_ref === dr); };
/** The party id and the credential id the next onboarding mints (the party id, then the credential id: Party Identity's enroll mints first). */
const mint = (w: W, party: string, credential?: string) => { w.ids.push(party); if (credential) w.ids.push(credential); };
/** What an onboarding left written, for a test that says "nothing": no party, no credential, the invitation as it was. */
const none = async (w: W) => { expect(await partiesOf(w)).toEqual([]); };
const status = async (w: W, token: string) => (await w.invitations()).find((i) => i._id === token)?.status;
/** Mint the party id through a patched planEnroll, so a test can plant a credential or a party under it first. */
const never = () => new Promise<never>(() => {});

test("Action wiring 9, 26, 29, 37, 38, 56, 57, Composes 14, 19, Wiring decision 1, 2, 4: an onboard opens the invocation, runs accept, enroll and register as one transaction, closes with the one outcome, and answers the party id and the credential id", async () => {
  const w = await world();
  const token = await w.issue();
  const before = (await w.events()).length;
  const r = ans(await onboard(w, token));
  expect(r.refused).toBeUndefined();
  const ev = (await w.events()).slice(before);
  expect(ev.map((e) => e.action_ref)).toEqual(["onboarding.intended", "onboarding.completed"]);                 // Action wiring 26: nothing else is written to the trail
  expect(ev.map((e) => e.actor_ref)).toEqual([w.enroller.ref, w.enroller.ref]);                                  // Composes 14: attested under the calling actor
  expect(ev[0].data).toMatchObject({ kind: "onboarding", act_key: token });                                       // Action wiring 56: the act key is the invitation token
  expect(ev[0].data.intent_data).toEqual({ invitation_token: token, accepting_identity_ref: "new@acme.com", document_type: "passport", document_ref: "P-123", credential_type: "password" });   // Action wiring 57: and the intent data names nothing of the person or the material
  expect(ev[1].data).toMatchObject({ kind: "onboarding", act_key: token });
  expect(ev[1].data.data).toEqual({ invitation_token: token, accepting_identity_ref: "new@acme.com", party_id: r.party_id, credential_id: r.credential_id });   // Action wiring 37
  expect(ev[1].data.invocation_id).toBe(ev[0].data.invocation_id);
  expect(await status(w, token)).toBe("accepted");                                                                // Wiring decision 1: the accept came first
  expect((await w.invitations())[0]).toMatchObject({ accepting_identity_ref: "new@acme.com" });                  // Wiring decision 4: the accepting identity reference the caller supplied
  const [party] = await partiesOf(w);
  expect(party).toMatchObject({ party_id: r.party_id, name: "Ada Lovelace", date_of_birth: "1990-05-01", document_type: "passport", state: "unverified", enrolling_actor_ref: w.enroller.ref });
  const cred = await w.credentials.read({ principal_ref: r.party_id });
  expect(cred).toHaveLength(1);                                                                                   // Wiring decision 2: the party id is the principal reference
  expect(cred[0]).toMatchObject({ credential_id: r.credential_id, credential_type: "password", status: "active", expires_at: null });
  expect(await w.credentials.verify(r.party_id!, "password", "correct horse")).toBe("verified");                  // the material reached Credential raw
  expect(JSON.stringify(await w.events())).not.toContain("correct horse");                                       // and no record carries it
});

test("Action wiring 29: the call's expiry instant reaches Credential unchanged, and blank where the call supplies none", async () => {
  const w = await world();
  const a = ans(await onboard(w, await w.issue(), { exp: "2026-12-01T00:00:00.000Z", dr: "P-1" }));
  expect((await w.credentials.read({ principal_ref: a.party_id }))[0].expires_at).toBe("2026-12-01T00:00:00.000Z");
  const b = ans(await onboard(w, await w.issue(), { dr: "P-2" }));
  expect((await w.credentials.read({ principal_ref: b.party_id }))[0].expires_at).toBeNull();
});

test("Primitive policy 1, 4, 10: a blank required input answers invalid-request, writes nothing, and no intent is recorded", async () => {
  const w = await world();
  const token = await w.issue();
  const before = (await w.events()).length;
  for (const over of [{ accepting: " " }, { name: "" }, { dob: "" }, { dt: "  " }, { dr: "" }, { ct: "" }, { cm: "" }, { cm: "   " }, { enrolling: "" }, { cred: "" }]) {
    expect(ans(await onboard(w, token, over)).refused).toBe("invalid-request");
  }
  expect(ans(await w.eo.onboard("", "a", "n", "1990-05-01", "d", "r", "password", "m", undefined, w.enroller.ref, w.enroller.priv)).refused).toBe("invalid-request");
  expect((await w.events()).length).toBe(before);                                                                 // Primitive policy 4: no attempt record before validating
  expect(await status(w, token)).toBe("pending");
  await none(w);
});

test("Primitive policy 2, 10: an enrolling actor reference over the reference length cap answers invalid-request, writes nothing", async () => {
  const w = await world();
  const token = await w.issue();
  const before = (await w.events()).length;
  expect(ans(await onboard(w, token, { enrolling: "a".repeat(129) })).refused).toBe("invalid-request");
  expect((await w.events()).length).toBe(before);
});

test("Primitive policy 3, 10: every field a constituent's own rules refuse answers invalid-request before any record", async () => {
  const w = await world();
  const token = await w.issue();
  const before = (await w.events()).length;
  for (const over of [
    { accepting: "a".repeat(300) },                      // Invitation's accept: the identity reference over its length bound
    { dob: "1990-02-30" },                               // Party Identity's enroll: no such calendar date
    { dob: "2999-01-01" },                               // Party Identity's enroll: the date of birth is ahead of now
    { name: "n".repeat(300) },                           // Party Identity's enroll: a field over its length bound
    { ct: "no-such-type" },                              // Credential's register: a type no registry holds
    { cm: "m".repeat(300) },                             // Credential's register: material the type refuses
    { exp: "not-an-instant" },                           // Credential's register: an expiry that is no instant
    { exp: "2026-01-01T00:00:00.000Z" },                 // Credential's register: an expiry already past
  ]) expect(ans(await onboard(w, token, over)).refused).toBe("invalid-request");
  expect((await w.events()).length).toBe(before);
  expect(await status(w, token)).toBe("pending");
  await none(w);
});

test("Primitive policy 5, 6, 10: the intent data or the largest outcome over the payload cap answers invalid-request, nothing written", async () => {
  const w = await world({ payloadCap: 330 });
  const token = await w.issue();
  const before = (await w.events()).length;
  const r = ans(await onboard(w, token, { accepting: "a".repeat(120) }));                                       // the outcome carries the accepting reference, the two ids at their width bounds and the token
  expect(r.refused).toBe("invalid-request");
  expect((await w.events()).length).toBe(before);
  await none(w);
});

test("Audit arm 1, Action wiring 1, 2, Recoverable Invocation Action wiring table: a refused credential answers invalid-credential, nothing written", async () => {
  const w = await world();
  const token = await w.issue();
  const before = (await w.events()).length;
  expect(ans(await onboard(w, token, { cred: w.person().priv })).refused).toBe("invalid-credential");
  expect(ans(await onboard(w, token, { enrolling: "unknown-actor" })).refused).toBe("invalid-credential");
  expect((await w.events()).length).toBe(before);
  expect(await status(w, token)).toBe("pending");                                                                 // no constituent was reached
  await none(w);
});

test("Recoverable Invocation Action wiring table, open step 1, 3, 4: an invalid-request from the journal answers invalid-request; a recording-failure at the intent answers recording-failure(intent); a section that cannot be taken answers section-unavailable; a journal that cannot be read answers journal-unavailable, never read as not-known; each nothing written", async () => {
  const w = await world();
  const token = await w.issue();
  const before = (await w.events()).length;
  w.jscript.push("step1");
  expect(ans(await onboard(w, token)).refused).toBe("invalid-request");
  w.jscript.push("rf2");
  expect(ans(await onboard(w, token))).toEqual({ refused: "recording-failure", position: "intent" });
  w.sec.takeUnavailable = true;
  expect(ans(await onboard(w, token)).refused).toBe("section-unavailable");
  w.sec.takeUnavailable = false;
  w.jreads.mode = "unavailable";
  expect(ans(await onboard(w, token)).refused).toBe("journal-unavailable");
  w.jreads.mode = "ok";
  expect((await w.events()).length).toBe(before);
  expect(await status(w, token)).toBe("pending");
  await none(w);
});

test("Recoverable Invocation Action wiring table, open step 5: a lease that no longer covers the commit answers recording-failure(outcome), the intent left open for the sweep, no constituent called", async () => {
  const w = await world();
  const token = await w.issue();
  w.sec.calls = 0;
  w.sec.remaining = (n) => (n >= 3 ? 1 : (undefined as never));                                                  // the read for the commit finds one millisecond
  const r = ans(await onboard(w, token));
  w.sec.remaining = null;
  expect(r.refused).toBe("recording-failure");
  expect(r.position).toBe("outcome");
  expect(await refs(w)).toContain("onboarding.intended");
  expect(await status(w, token)).toBe("pending");                                                                 // the transaction was never issued
  await none(w);
});

test("Recoverable Invocation Action wiring table, open step 3.5: an onboarding of the token in flight answers act-in-flight, nothing written", async () => {
  const w = await world();
  const token = await w.issue();
  const held = await w.ri.open("onboarding", token, w.enroller.ref, w.enroller.priv, { invitation_token: token });   // another invocation holds the act's critical section
  expect(held).toHaveProperty("invocation_id");
  const before = (await w.events()).length;
  const r = ans(await onboard(w, token));
  expect(r).toEqual({ refused: "act-in-flight", invocation_id: (held as { invocation_id: string }).invocation_id });
  expect((await w.events()).length).toBe(before);
  await none(w);
});

test("Action wiring 59: an onboard of a token whose act landed answers invitation-invalid carrying already-resolved and accepted, and writes nothing", async () => {
  const w = await world();
  const token = await w.issue();
  expect(ans(await onboard(w, token)).refused).toBeUndefined();
  const before = (await w.events()).length;
  expect(ans(await onboard(w, token, { dr: "P-other" }))).toEqual({ refused: "invitation-invalid", cause: "already-resolved", stored_terminal: "accepted" });
  expect((await w.events()).length).toBe(before);                                                                 // open step 3.9: no intent for an act that landed
  expect(await partiesOf(w, "P-other")).toEqual([]);
  expect(await partiesOf(w)).toHaveLength(1);
});

test("Action wiring 17, 18, 24, 58, Recoverable Invocation commit 2: an expired or unknown invitation answers invitation-invalid carrying the code; the transaction wrote nothing beyond the intent and the refusal record", async () => {
  const w = await world();
  const token = await w.issue();
  w.seam.advance(2 * 3600 * 1000);
  const before = (await w.events()).length;
  expect(ans(await onboard(w, token))).toEqual({ refused: "invitation-invalid", cause: "expired" });
  const ev = (await w.events()).slice(before);
  expect(ev.map((e) => e.action_ref)).toEqual(["onboarding.intended", "onboarding.refused"]);                   // Action wiring 24
  expect(ev[1].data).toMatchObject({ kind: "onboarding", act_key: token, constituent_code: "expired", invocation_id: ev[0].data.invocation_id });
  expect(await status(w, token)).toBe("pending");
  await none(w);
  const unknown = "no-such-token";
  expect(ans(await onboard(w, unknown))).toEqual({ refused: "invitation-invalid", cause: "not-known" });
  expect((await refs(w)).slice(-2)).toEqual(["onboarding.intended", "onboarding.refused"]);
});

test("Action wiring 19, 20, 58: an invitation another call resolved answers invitation-invalid carrying already-resolved and the stored terminal, each with the refusal record", async () => {
  const w = await world();
  const declined = await w.issue();
  expect(await w.eo.decline(declined, w.service.ref, w.service.priv)).toBe("declined");
  expect(ans(await onboard(w, declined))).toEqual({ refused: "invitation-invalid", cause: "already-resolved", stored_terminal: "declined" });
  const revoked = await w.issue();
  expect(await w.eo.revoke(revoked, w.inviter.ref, "no longer needed", w.inviter.priv)).toBe("revoked");
  expect(ans(await onboard(w, revoked))).toEqual({ refused: "invitation-invalid", cause: "already-resolved", stored_terminal: "revoked" });
  const taken = await w.issue();
  expect(await w.invitation.accept(taken, "someone@else.com")).toBe("accepted");                                  // resolved outside the composition's actions, as a test
  expect(ans(await onboard(w, taken))).toEqual({ refused: "invitation-invalid", cause: "already-resolved", stored_terminal: "accepted" });
  expect((await w.events()).filter((e) => e.action_ref === "onboarding.refused")).toHaveLength(3);
  await none(w);
});

test("Action wiring 19, 20, Invitation Invariant 2, Concurrency 1: an invitation resolved between the plan and the commit is read again, and the refusal names the terminal", async () => {
  const w = await world();
  const token = await w.issue();
  let once = true;
  w.commits.run = async (_stmts, real) => {
    if (once) { once = false; expect(await w.invitation.accept(token, "rival@acme.com")).toBe("accepted"); }      // another resolution lands first
    return real();
  };
  expect(ans(await onboard(w, token))).toEqual({ refused: "invitation-invalid", cause: "already-resolved", stored_terminal: "accepted" });
  expect((await w.invitations())[0].accepting_identity_ref).toBe("rival@acme.com");
  await none(w);                                                                                                  // the rolled-back transaction left no party and no credential
});

test("Action wiring 32, 58, 61, Recoverable Invocation commit 2: a duplicate active credential answers duplicate-active-credential, the transaction rolled back, the invitation pending, the refusal record kept", async () => {
  const w = await world();
  const token = await w.issue();
  const party = `party-${crypto.randomUUID()}`;
  expect(await w.credentials.register(party, "someone else's", "password")).toHaveProperty("credential_id");     // an active credential already sits under the id the enroll will mint
  const orig = w.parties.planEnroll.bind(w.parties);
  w.parties.planEnroll = async (...a) => { mint(w, party); return orig(...a); };
  const before = (await w.events()).length;
  expect(ans(await onboard(w, token))).toEqual({ refused: "duplicate-active-credential" });
  w.parties.planEnroll = orig;
  const ev = (await w.events()).slice(before);
  expect(ev.map((e) => e.action_ref)).toEqual(["onboarding.intended", "onboarding.refused"]);
  expect(ev[1].data).toMatchObject({ reason: "duplicate-active-credential", constituent_code: "duplicate-active-credential" });
  expect(await status(w, token)).toBe("pending");                                                                 // Action wiring 61: no write committed
  expect((await w.parties.read({ party_id: party }) as unknown[])).toEqual([]);
  expect(await w.credentials.read({ principal_ref: party })).toHaveLength(1);                                     // only the one that was already there
  mint(w, "unused-1");                                                                                            // the arc runs again after a refusal (open step 3.9): a fresh onboarding of the same token
  w.ids.length = 0;
  expect(ans(await onboard(w, token)).refused).toBeUndefined();
});

test("Action wiring 32, 61: a credential registered for the party between the plan and the commit answers duplicate-active-credential, the transaction rolled back", async () => {
  const w = await world();
  const token = await w.issue();
  const party = `party-${crypto.randomUUID()}`;
  const orig = w.parties.planEnroll.bind(w.parties);
  w.parties.planEnroll = async (...a) => { mint(w, party); return orig(...a); };
  w.commits.run = async (_s, real) => { expect(await w.credentials.register(party, "rival", "password")).toHaveProperty("credential_id"); return real(); };
  expect(ans(await onboard(w, token))).toEqual({ refused: "duplicate-active-credential" });
  w.parties.planEnroll = orig;
  expect(await status(w, token)).toBe("pending");
  expect(await w.credentials.read({ principal_ref: party })).toHaveLength(1);
  expect((await refs(w)).slice(-2)).toEqual(["onboarding.intended", "onboarding.refused"]);
});

test("Party Identity Identity 4 beside Action wiring 26: another enrollment landing between the plan and the commit is planned again, and the onboarding completes", async () => {
  const w = await world();
  const token = await w.issue();
  let once = true;
  w.commits.run = async (_s, real) => {
    if (once) { once = false; expect(await w.parties.enroll("Rival", "1980-01-01", "passport", "P-rival", w.enroller.ref)).toHaveProperty("party_id"); }
    return real();
  };
  const r = ans(await onboard(w, token));
  expect(r.refused).toBeUndefined();
  expect(await partiesOf(w)).toHaveLength(1);
  expect(await partiesOf(w, "P-rival")).toHaveLength(1);
});

test("Action wiring 31, 58, Recoverable Invocation commit 3: a constituent's storage-failure before the commit answers storage-failure, rolled back, the refusal record kept", async () => {
  const w = await world();
  const held = await w.parties.enroll("Grace", "1985-01-01", "passport", "P-held", w.enroller.ref) as { party_id: string };   // a party, with no credential, whose id the next enroll will mint again
  const token = await w.issue();
  const orig = w.parties.planEnroll.bind(w.parties);
  w.parties.planEnroll = async (...a) => { mint(w, held.party_id!); return orig(...a); };
  const before = (await w.events()).length;
  expect(ans(await onboard(w, token, { dr: "P-second" }))).toEqual({ refused: "storage-failure" });              // Party Identity's id guard holds inside the transaction
  w.parties.planEnroll = orig;
  expect((await w.events()).slice(before).map((e) => e.action_ref)).toEqual(["onboarding.intended", "onboarding.refused"]);
  expect(await status(w, token)).toBe("pending");
});

test("Execution Contract Constituent failure 3, Recoverable Invocation commit 2: a failed read of the database answers state-unavailable, the intent kept by the refusal record", async () => {
  const w = await world();
  const token = await w.issue();
  const orig = w.invitation.planAccept.bind(w.invitation);
  w.invitation.planAccept = async () => { throw new Unavailable(); };
  const before = (await w.events()).length;
  expect(ans(await onboard(w, token))).toEqual({ refused: "state-unavailable" });
  w.invitation.planAccept = orig;
  expect((await w.events()).slice(before).map((e) => e.action_ref)).toEqual(["onboarding.intended", "onboarding.refused"]);
  await none(w);
});

test("Recoverable Invocation Action wiring table, refuse: an already-accounted intent answers already-accounted; a refusal record Audit Trail refuses answers recording-failure(refusal) carrying the constituent's code, never re-run", async () => {
  const w = await world();
  const token = await w.issue();
  w.jscript.push("real", "rf2");                                                                                  // the intent lands, the refusal record does not
  w.seam.advance(2 * 3600 * 1000);
  expect(ans(await onboard(w, token))).toEqual({ refused: "recording-failure", position: "refusal", constituent_code: "expired" });
  expect(await refs(w)).not.toContain("onboarding.refused");                                                      // the intent stays open for the sweep
  const w2 = await world();
  const t2 = await w2.issue();
  w2.seam.advance(2 * 3600 * 1000);
  const orig = w2.ri.refuse.bind(w2.ri);
  w2.ri.refuse = async (...a) => {                                                                                 // a closing naming the invocation lands before the refusal does (refuse step 2.2)
    await w2.at.recordAction("onboarding.abandoned", w2.enroller.ref, w2.enroller.priv, { invocation_id: a[2], kind: a[0], act_key: a[1], intent_event_id: a[3] });
    return orig(...a);
  };
  const r = ans(await onboard(w2, t2));
  w2.ri.refuse = orig;
  expect(r.refused).toBe("already-accounted");
  expect(r.closing_event_id).toBeDefined();
  expect((await w2.events()).map((e) => e.action_ref).slice(-2)).toEqual(["onboarding.intended", "onboarding.abandoned"]);   // refuse step 2.5: nothing appended
});

test("Action wiring 37, Recoverable Invocation Action wiring table, close: an outcome Audit Trail refuses answers recording-failure(outcome) carrying the invocation id, the committed arc left for the operator's resolve, never re-run", async () => {
  const w = await world();
  const token = await w.issue();
  w.jscript.push("real", "lost-nothing");                                                                         // the intent lands, the outcome record gets no answer and is not found
  const r = ans(await onboard(w, token));
  expect(r.refused).toBe("recording-failure");
  expect(r.position).toBe("outcome");
  const intent = (await w.events()).find((e) => e.action_ref === "onboarding.intended")!;
  expect(r.invocation_id).toBe(intent.data.invocation_id);
  expect(await status(w, token)).toBe("accepted");                                                                // the three writes committed
  expect(await partiesOf(w)).toHaveLength(1);
  expect(await refs(w)).not.toContain("onboarding.completed");
  expect(await w.ri.openIntents("onboarding", token)).toHaveLength(1);                                            // the record is owed, and the sweep or an operator closes it
});

test("Action wiring 60, Recoverable Invocation commit 6, 8: a transaction with no answer within the commit round trip answers recording-failure(outcome) after the invocation yield, nothing closed", async () => {
  const w = await world({ commitRoundTripMs: 40 });
  const token = await w.issue();
  w.commits.run = () => never();
  const r = ans(await onboard(w, token));
  expect(r.refused).toBe("recording-failure");
  expect(r.position).toBe("outcome");
  expect(r.invocation_id).toBeDefined();
  expect(await refs(w)).toEqual(expect.arrayContaining(["onboarding.intended"]));
  expect(await refs(w)).not.toContain("onboarding.completed");
  expect(await refs(w)).not.toContain("onboarding.refused");                                                      // the act may exist: no refusal is written
  expect(w.sec.released).toEqual([]);                                                                             // yield 6: a lost reply leaves the grant to end at its instant
});

test("Action wiring 60, Recoverable Invocation commit 7: an answer no constituent declares, from the commit or from a plan, answers recording-failure(outcome), nothing closed or refused", async () => {
  const w = await world();
  const token = await w.issue();
  w.commits.run = async () => { throw new Error("a code nobody declares"); };
  expect(ans(await onboard(w, token)).position).toBe("outcome");
  w.commits.run = null;
  expect(w.sec.released).toHaveLength(1);                                                                         // yield 4: an answered reply released the section
  expect(ans(await onboard(w, token)).refused).toBe("act-in-flight");                                             // the intent stands open
  const orig = w.parties.planEnroll.bind(w.parties);
  w.parties.planEnroll = async () => { throw new Error("a code nobody declares"); };
  expect(ans(await onboard(w, await w.issue(), { dr: "P-x" })).position).toBe("outcome");
  w.parties.planEnroll = orig;
  expect(await refs(w)).not.toContain("onboarding.refused");
  expect(await refs(w)).not.toContain("onboarding.completed");
});

test("Wiring decision 1, 5, Invitation Invariant 2, Recoverable Invocation repeatable 2: two onboards of one invitation at once leave one party and one credential, and the other meets a refusal that creates no constituent record", async () => {
  const w = await world();
  const token = await w.issue();
  const [a, b] = (await Promise.all([onboard(w, token, { accepting: "a@acme.com" }), onboard(w, token, { accepting: "b@acme.com" })])).map(ans);
  const won = [a, b].filter((r) => r.refused === undefined);
  expect(won).toHaveLength(1);
  const lost = [a, b].find((r) => r.refused !== undefined)!;
  expect(["act-in-flight", "section-unavailable", "invitation-invalid"]).toContain(lost.refused!);
  expect(await partiesOf(w)).toHaveLength(1);
  expect(await w.credentials.read({ principal_ref: won[0].party_id })).toHaveLength(1);
  expect(await status(w, token)).toBe("accepted");
});

// ---- The onboarding probe (Term onboarding probe) -----------------------------------------------------------------

/** A committed arc whose completion record was never written: the commit landed, and the reply that would have said so did not arrive. */
const orphan = async (w: W, over: Parameters<typeof onboard>[2] = {}) => {
  const token = await w.issue();
  let landing: Promise<void> = Promise.resolve();
  w.commits.run = async (_s, real) => { landing = real(); await landing; return never(); };                      // the commit lands, and its reply is the one that never arrives
  w.eoCfg.commitRoundTripMs = 40;
  const r = ans(await onboard(w, token, over));
  await landing;
  w.commits.run = null;
  w.eoCfg.commitRoundTripMs = 2000;
  expect(r.position).toBe("outcome");
  return token;
};
const intentOf = async (w: W, token: string) => (await w.events()).find((e) => e.action_ref === "onboarding.intended" && e.data.act_key === token)!;
const asked = async (w: W, token: string) => { const i = await intentOf(w, token); return w.probe(token, i.data, i.actor_ref); };

test("Term onboarding probe, Recoverable Invocation act probe 1: an invitation pending, declined, revoked or accepted by another accepting identity reference answers not-committed", async () => {
  const w = await world();
  const pending = await w.issue();
  const open = await w.ri.open("onboarding", pending, w.enroller.ref, w.enroller.priv, { invitation_token: pending, accepting_identity_ref: "new@acme.com", document_type: "passport", document_ref: "P-123", credential_type: "password" });
  expect(open).toHaveProperty("invocation_id");
  const probe = (t: string) => w.probe(t, { intent_data: { accepting_identity_ref: "new@acme.com", document_type: "passport", document_ref: "P-123", credential_type: "password" } }, w.enroller.ref);
  expect(await probe(pending)).toEqual({ answer: "not-committed" });
  const declined = await w.issue(); await w.eo.decline(declined, w.service.ref, w.service.priv);
  expect(await probe(declined)).toEqual({ answer: "not-committed" });
  const revoked = await w.issue(); await w.eo.revoke(revoked, w.inviter.ref, "gone", w.inviter.priv);
  expect(await probe(revoked)).toEqual({ answer: "not-committed" });
  const other = await w.issue(); await w.invitation.accept(other, "someone@else.com");
  expect(await probe(other)).toEqual({ answer: "not-committed" });
});

test("Term onboarding probe, Recoverable Invocation act probe 3a, pairing datum 6a: an invitation accepted by the intent's accepting identity reference answers undecidable carrying the party id and the credential id, and never committed", async () => {
  const w = await world();
  const token = await orphan(w);
  const [party] = await partiesOf(w);
  const [cred] = await w.credentials.read({ principal_ref: party.party_id });
  expect(await asked(w, token)).toEqual({ answer: "undecidable", candidates: [party.party_id, cred.credential_id] });
});

test("Term onboarding probe: the party selection is by document type, document reference and enrolling actor reference, in any state; the credential set is the registered ones under the intent's credential type that no other found carries as its successor", async () => {
  const w = await world();
  const token = await orphan(w);
  const [mine] = await partiesOf(w);
  const [first] = await w.credentials.read({ principal_ref: mine.party_id });
  // A party the intent does not describe: another document reference, and one enrolled by another actor.
  const t2 = await w.issue(); expect(ans(await onboard(w, t2, { dr: "P-999" })).refused).toBeUndefined();
  const t3 = await w.issue(); const other = w.person(); expect(ans(await onboard(w, t3, { enrolling: other.ref, cred: other.priv })).refused).toBeUndefined();
  const t4 = await w.issue(); expect(ans(await onboard(w, t4, { dt: "licence" })).refused).toBeUndefined();   // the same document reference and actor, another document type
  // The party moves to another state; a rotated credential has a successor.
  expect(await w.parties.verify(mine.party_id, w.service.ref, "document-check", "passed", "ev-1")).toHaveProperty("verification_id");
  const rotated = await w.credentials.rotate(first.credential_id, "a new horse") as { credential_id: string };
  const pin = await w.credentials.register(mine.party_id, "1234", "pin") as { credential_id: string };               // a credential of another type for the same party
  const answer = await asked(w, token);
  expect(answer).toEqual({ answer: "undecidable", candidates: [mine.party_id, first.credential_id] });             // the party in any state; the first credential, since the rotated one is another's successor
  expect(JSON.stringify(answer)).not.toContain(rotated.credential_id);
  expect(JSON.stringify(answer)).not.toContain(pin.credential_id);                                                // the intent's credential type only
});

test("Term onboarding probe, Recoverable Invocation act probe 4, 5: a read refused answers unavailable, never not-committed; an invitation the read does not find decides nothing", async () => {
  const w = await world();
  const token = await w.issue();
  const intent = { intent_data: { accepting_identity_ref: "new@acme.com", document_type: "passport", document_ref: "P-123", credential_type: "password" } };
  await w.invitation.accept(token, "new@acme.com");
  const orig = w.parties.read.bind(w.parties);
  w.parties.read = async () => ({ refused: "invalid-query" as const });
  expect(await w.probe(token, intent, w.enroller.ref)).toEqual({ answer: "unavailable" });
  w.parties.read = orig;
  expect(await w.probe("no-such-token", intent, w.enroller.ref)).toEqual({ answer: "unavailable" });
});

test("Composes 17, 18, 19, 20, Term onboarding binding: the instance serves the one act kind, onboarding, under the invitation token, with the one outcome, no service identity, and the probe the render's own", async () => {
  const w = await world();
  expect(w.binding).toMatchObject({ outcomes: ["onboarding.completed"], repeatable: false, serviceIdentity: null, serviceCredential: null, retentionPeriodMs: 7 * 365 * 86_400_000, settlingPeriodMs: 100_000, invocationCompletionBoundMs: 10_000 });
  const widest = { invitation_token: "x".repeat(43), accepting_identity_ref: "x".repeat(128), party_id: "x".repeat(36), credential_id: "x".repeat(36) };
  expect(w.binding.outcomeEnvelopeBytes).toBe(new TextEncoder().encode(canonical(widest)).length);                // Primitive policy 6: sized from the minted-id width bounds
  const token = await orphan(await world());
  expect(token).toBeDefined();
  // the sweep reads the probe by the act key and the intent, and the intent record's actor is the enrolling actor reference
  const w2 = await world();
  const t2 = await orphan(w2);
  w2.seam.advance(250_000);                                                                                       // past the closure window and the completion bound
  const tally = await w2.ri.reconcile();
  expect(tally).toHaveProperty("examined");
  expect(w2.probed.length).toBeGreaterThan(0);
  expect(w2.probed[0]).toMatchObject({ act_key: t2, actor: w2.enroller.ref });
  expect(w2.probed[0].intent.intent_data).toMatchObject({ invitation_token: t2, accepting_identity_ref: "new@acme.com", document_type: "passport", document_ref: "P-123", credential_type: "password" });
});
