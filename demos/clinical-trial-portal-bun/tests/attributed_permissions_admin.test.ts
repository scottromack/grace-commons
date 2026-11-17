// Attributed Permissions Admin, one test for each rule the render answers, named by the rule's label.
import { test, expect, afterAll } from "bun:test";
import { Store, Unavailable } from "../src/store.ts";
import { canonical } from "../src/canonical.ts";
import { apaWorld, PREFIX } from "./apa_world.ts";

const store = new Store();
afterAll(() => store.close());
const world = apaWorld(store);
type W = Awaited<ReturnType<typeof world>>;
type Ans = { refused?: string; grant_id?: string; attestation_id?: string; orphan?: string; ok?: boolean; revoked_grant_ids?: string[]; attestation_ids?: string[] };
const ans = (r: unknown) => r as Ans;
const who = () => `subject-${crypto.randomUUID()}`;
/** The attestations an actor made, oldest first. */
const by = async (w: W, ref: string) => (await w.attestations()).filter((x) => x.actor_ref === ref);
const allGrants = async (w: W) => w.perms.read();
const parse = (proposal: string) => JSON.parse(proposal.slice(PREFIX.length)) as Record<string, string>;
/** Another call's revocation, a direct write to the grant records (it leaves no revocation entry). */
const directRevoke = async (w: W, id: string) => {
  const g = (await store.read<Record<string, unknown>>(`SELECT * FROM ${w.grants} WHERE _id = $1`, [id]))[0];
  await store.commit([store.put(w.grants, { ...g, _id: id, status: "revoked", revoked_at: "2026-09-01T10:00:01.000Z" } as never)]);
};
const issue = async (w: W, subject = who(), scope = "records:read") => { const r = ans(await w.admin.issueGrant(subject, scope, w.a.ref, w.a.priv)); expect(r.grant_id).toBeDefined(); return { subject, scope, ...r }; };

test("Action wiring 1, 2, 7, 15, Composes 15, 16, Composition state 5, 11, 25, Identity 4, 8, 11, 13: an issuance attests the proposal under the grantor, then records the grant, then the attribution entry, one transaction, and answers the handle and the attestation", async () => {
  const w = await world();
  const g = await issue(w);
  const att = await by(w, w.a.ref);
  expect(att).toHaveLength(1);
  expect(att[0].attestation_id).toBe(g.attestation_id);
  const p = parse(att[0].action_ref);                                                                              // the attestation's action reference is the proposal
  expect(att[0].action_ref.startsWith(PREFIX)).toBe(true);                                                         // Capability requirement 11
  expect(Object.keys(p).sort()).toEqual(["action_scope", "nonce", "requested_at", "subject_ref"]);                 // Identity 11, 13: the grant's handle is not in it
  expect(p).toMatchObject({ subject_ref: g.subject, action_scope: g.scope, requested_at: "2026-09-01T10:00:00.000Z" });
  expect(p.nonce.length).toBeGreaterThan(20);                                                                      // Identity 4, 5
  const grant = (await allGrants(w)).find((x) => x.grant_id === g.grant_id)!;
  expect(grant).toMatchObject({ subject_ref: g.subject, action_scope: g.scope, status: "active" });
  expect(await w.mine("grant_attribution", [g.grant_id!])).toEqual([{ _id: g.grant_id, attestation_id: g.attestation_id }]);   // Composition state 5, 11
  expect(await w.actors.verify(g.attestation_id!)).toBe("verified");
});

test("Identity 4, 6, 7, Invariant 7.4, 7.5, Clock semantics 6, 7: two issuances carry two nonces, so two proposals and two attestations, though the request instant is the same", async () => {
  const w = await world();
  await issue(w); await issue(w);
  const [a, b] = await by(w, w.a.ref);
  expect(a.action_ref).not.toBe(b.action_ref);
  expect(parse(a.action_ref).requested_at).toBe(parse(b.action_ref).requested_at);
  expect(parse(a.action_ref).nonce).not.toBe(parse(b.action_ref).nonce);
  expect(a.attestation_id).not.toBe(b.attestation_id);
});

test("Primitive policy 1 to 5, 10: a blank or over-long administered input, or a blank credential, answers invalid-request and calls no constituent", async () => {
  const w = await world();
  for (const bad of [["", "s", w.a.ref], ["x", " ", w.a.ref], ["x", "s", ""], ["x", "s", "\t "]] as const) {
    expect(ans(await w.admin.issueGrant(bad[0], bad[1], bad[2], w.a.priv)).refused).toBe("invalid-request");
  }
  expect(ans(await w.admin.issueGrant("x", "s", w.a.ref, "")).refused).toBe("invalid-request");                    // Primitive policy 4
  expect(ans(await w.admin.issueGrant("x".repeat(257), "s", w.a.ref, w.a.priv)).refused).toBe("invalid-request");  // Primitive policy 3: the Permissions instance's cap, 256
  expect(ans(await w.admin.issueGrant("x".repeat(256), "s", w.a.ref, w.a.priv)).refused).toBeUndefined();         // the boundary itself stands
  expect(ans(await w.admin.revokeGrant(" ", w.a.ref, w.a.priv)).refused).toBe("invalid-request");
  expect(ans(await w.admin.revokePermission("x", "", w.a.ref, w.a.priv)).refused).toBe("invalid-request");
  expect(ans(await w.admin.revokePermission("x", "s", w.a.ref, "")).refused).toBe("invalid-request");
  expect(await by(w, w.a.ref)).toHaveLength(1);                                                                    // only the one admitted issuance attested
});

test("Primitive policy 6 to 10, 12: an administered input is trimmed once and the trimmed value goes on; case is kept; a credential is not trimmed", async () => {
  const w = await world();
  const r = ans(await w.admin.issueGrant("  alice  ", "\trecords:read\n", `  ${w.a.ref} `, w.a.priv));
  const g = (await allGrants(w)).find((x) => x.grant_id === r.grant_id)!;
  expect(g).toMatchObject({ subject_ref: "alice", action_scope: "records:read" });                                 // Primitive policy 8
  expect((await by(w, w.a.ref))[0].actor_ref).toBe(w.a.ref);
  expect(parse((await by(w, w.a.ref))[0].action_ref)).toMatchObject({ subject_ref: "alice", action_scope: "records:read" });
  const upper = ans(await w.admin.issueGrant("Alice", "records:read", w.a.ref, w.a.priv));                         // Primitive policy 9, 10: Alice is another subject
  expect(upper.grant_id).not.toBe(r.grant_id);
  const seen: string[] = [];
  const real = w.actors.plan.bind(w.actors);
  w.actors.plan = async (p, r, c) => { seen.push(c); return real(p, r, c); };
  await w.admin.issueGrant("bob", "s", w.a.ref, ` ${w.a.priv} `);
  expect(seen).toEqual([` ${w.a.priv} `]);                                                                         // Primitive policy 12, 13: the credential goes on as it came
});

test("Action wiring 3, 6, 18, 21, 92, Audit: a credential Actor Identity refuses answers invalid-credential, and no Permissions write follows, at each of the three actions", async () => {
  const w = await world();
  const g = await issue(w);
  const stranger = w.person();
  expect(ans(await w.admin.issueGrant("bob", "s", w.a.ref, stranger.priv)).refused).toBe("invalid-credential");
  expect(ans(await w.admin.issueGrant("bob", "s", "unknown-actor", w.a.priv)).refused).toBe("invalid-credential");
  expect(ans(await w.admin.revokeGrant(g.grant_id!, w.a.ref, stranger.priv)).refused).toBe("invalid-credential");
  expect(ans(await w.admin.revokePermission(g.subject, g.scope, w.a.ref, stranger.priv)).refused).toBe("invalid-credential");
  expect((await allGrants(w)).map((x) => x.status)).toEqual(["active"]);                                           // nothing was granted, nothing revoked
  expect(await by(w, w.a.ref)).toHaveLength(1);                                                                    // no attestation for the refused calls
});

test("Action wiring 5, 20, 94, 96 to 98, Primitive policy 14 to 16: a constituent's storage-failure answers attribution-storage-failure; mechanism-unavailable and registry-unavailable answer as themselves; an invalid-request at the attestation is a deployment fault, alerted", async () => {
  const w = await world();
  const g = await issue(w);
  w.registry.unreachable = true;
  expect(ans(await w.admin.issueGrant("bob", "s", w.a.ref, w.a.priv)).refused).toBe("registry-unavailable");
  expect(ans(await w.admin.revokeGrant(g.grant_id!, w.a.ref, w.a.priv)).refused).toBe("registry-unavailable");
  w.registry.unreachable = false;
  w.mech.unavailable = true;
  expect(ans(await w.admin.issueGrant("bob", "s", w.a.ref, w.a.priv)).refused).toBe("mechanism-unavailable");      // Action wiring 96
  expect(ans(await w.admin.revokeGrant(g.grant_id!, w.a.ref, w.a.priv)).refused).toBe("mechanism-unavailable");    // Action wiring 97
  expect(ans(await w.admin.revokePermission(g.subject, g.scope, w.a.ref, w.a.priv)).refused).toBe("mechanism-unavailable");   // Action wiring 98
  w.mech.unavailable = false;
  const real = w.actors.plan.bind(w.actors);
  w.actors.plan = async () => ({ refused: "storage-failure" });
  expect(ans(await w.admin.issueGrant("bob", "s", w.a.ref, w.a.priv)).refused).toBe("attribution-storage-failure");
  expect(ans(await w.admin.revokeGrant(g.grant_id!, w.a.ref, w.a.priv)).refused).toBe("attribution-storage-failure");
  expect(ans(await w.admin.revokePermission(g.subject, g.scope, w.a.ref, w.a.priv)).refused).toBe("attribution-storage-failure");   // Action wiring 94
  w.actors.plan = async () => ({ refused: "invalid-request" });
  expect(ans(await w.admin.issueGrant("bob", "s", w.a.ref, w.a.priv)).refused).toBe("invalid-request");           // Primitive policy 14
  expect(w.alerts).toEqual([{ arm: "primitive-policy-16", action: "issue_grant" }]);
  w.actors.plan = real;
  expect((await allGrants(w)).map((x) => x.status)).toEqual(["active"]);
});

test("Action wiring 103 to 106: an issuance over a pair an active grant holds answers that grant's handle, attests nothing and writes nothing", async () => {
  const w = await world();
  const g = await issue(w);
  const before = (await w.attestations()).length;
  const again = ans(await w.admin.issueGrant(g.subject, g.scope, w.a.ref, w.a.priv));
  expect(again).toEqual({ grant_id: g.grant_id });                                                                 // no attestation id
  expect((await w.attestations()).length).toBe(before);
  expect(await allGrants(w)).toHaveLength(1);
  expect(await w.mine("grant_attribution", [g.grant_id!])).toHaveLength(1);
});

test("Action wiring 8, 10, 101, Atomic writes 8, Wiring decision 4, 5, Composition state 19: where Permissions refuses the grant, the issuance answers orphan-attestation carrying pre-grant, the attestation committed with an orphan log entry that is never deleted", async () => {
  const w = await world();
  const orig = w.perms.plan.bind(w.perms);
  w.perms.plan = async () => ({ refused: "invalid-request" });
  const r = ans(await w.admin.issueGrant("bob", "s", w.a.ref, w.a.priv));
  w.perms.plan = orig;
  expect(r).toEqual({ orphan: "pre-grant", attestation_id: (await by(w, w.a.ref))[0].attestation_id });
  expect(await allGrants(w)).toEqual([]);                                                                          // no grant
  const [att] = await by(w, w.a.ref);
  const [log] = await w.mine("orphan_log", [att.attestation_id]);
  expect(log).toMatchObject({ attestation_id: att.attestation_id, proposal: att.action_ref, requested_at: "2026-09-01T10:00:00.000Z", reason: "invalid-request" });
  expect(await w.actors.verify(att.attestation_id)).toBe("verified");                                              // the attestation stands as evidence of an attempted act
});

test("Action wiring 15, Composes 19: a grant the pair acquired by a direct write between the read and the write, named by no attribution entry, is answered with the handle and the attestation and attributed", async () => {
  const w = await world();
  const orig = w.perms.plan.bind(w.perms);
  const direct = `direct-${crypto.randomUUID()}`;
  w.perms.plan = async (s, sc) => { await store.commit([store.put(w.grants, { _id: direct, subject_ref: s, action_scope: sc, granted_at: "2026-09-01T09:00:00.000Z", status: "active", revoked_at: null })]); return orig(s, sc); };
  const r = ans(await w.admin.issueGrant("bob", "s", w.a.ref, w.a.priv));
  w.perms.plan = orig;
  expect(r.grant_id).toBe(direct);
  expect(r.attestation_id).toBeDefined();
  expect(await w.mine("grant_attribution", [direct])).toEqual([{ _id: direct, attestation_id: r.attestation_id }]);
});

test("Concurrency 1, 2, 10, 11, Composes 23, 24: two issuances over one pair that both read it unheld produce one grant and two attestations, the second answering orphan-attestation with the reason already-held", async () => {
  const w = await world();
  const orig = w.perms.plan.bind(w.perms);
  let arrived = 0; let release!: () => void;
  const gate = new Promise<void>((r) => { release = r; });
  w.perms.plan = async (s, sc) => { if (arrived++ < 2) { if (arrived === 2) release(); await gate; } return orig(s, sc); };   // both have read the pair before either writes
  const [x, y] = (await Promise.all([w.admin.issueGrant("bob", "s", w.a.ref, w.a.priv), w.admin.issueGrant("bob", "s", w.a.ref, w.a.priv)])).map(ans);
  w.perms.plan = orig;
  expect([x, y].filter((r) => r.grant_id !== undefined)).toHaveLength(1);
  const lost = [x, y].find((r) => r.orphan !== undefined)!;
  expect(lost.orphan).toBe("pre-grant");
  expect(await allGrants(w)).toHaveLength(1);
  const att = await by(w, w.a.ref);
  expect(att).toHaveLength(2);                                                                                     // two attestations, neither shared (Composes 24)
  const [log] = await w.mine("orphan_log", [lost.attestation_id!]);
  expect(log).toMatchObject({ reason: "already-held" });
  expect(await w.mine("orphan_log", att.map((a) => a.attestation_id))).toHaveLength(1);
});

test("Action wiring 16, 17, 22, 41, Composes 17, Identity 12, Composition state 12: a revocation attests the grant's handle and the request instant, revokes, records the revocation entry, and answers ok and the attestation", async () => {
  const w = await world();
  const g = await issue(w);
  w.seam.set("2026-09-02T09:00:00.000Z");
  const r = ans(await w.admin.revokeGrant(g.grant_id!, w.a.ref, w.a.priv));
  expect(r.ok).toBe(true);
  const att = await by(w, w.a.ref);
  expect(att).toHaveLength(2);
  const rev = att.find((x) => x.attestation_id === r.attestation_id)!;
  expect(rev.action_ref).toBe(`${PREFIX}${canonical({ grant_id: g.grant_id, requested_at: "2026-09-02T09:00:00.000Z" })}`);   // Capability requirement 12, 13
  expect(Object.keys(parse(rev.action_ref)).sort()).toEqual(["grant_id", "requested_at"]);                         // Identity 12
  expect((await allGrants(w))[0]).toMatchObject({ status: "revoked", revoked_at: "2026-09-02T09:00:00.000Z" });
  expect(await w.mine("revocation_attribution", [g.grant_id!])).toEqual([{ _id: g.grant_id, attestation_id: r.attestation_id }]);
  expect(rev.attestation_id).not.toBe(g.attestation_id);                                                           // Invariant 7.3, 7.6: disjoint, and the proposals differ in kind
});

test("Action wiring 23, 24, 26, 27 to 30, 102, Atomic writes 8: a revocation of an unknown or an already revoked grant answers not-known or not-active, with the attestation committed and an orphan log entry carrying the reason", async () => {
  const w = await world();
  const g = await issue(w);
  expect(ans(await w.admin.revokeGrant(g.grant_id!, w.a.ref, w.a.priv)).ok).toBe(true);
  const second = ans(await w.admin.revokeGrant(g.grant_id!, w.a.ref, w.a.priv));
  expect(second.refused).toBe("not-active");
  const unknown = ans(await w.admin.revokeGrant("no-such-grant", w.a.ref, w.a.priv));
  expect(unknown.refused).toBe("not-known");
  const att = await by(w, w.a.ref);
  expect(att).toHaveLength(4);                                                                                     // an attestation for each attempt
  const logs = await w.mine("orphan_log", att.map((a) => a.attestation_id));
  expect(logs.map((l) => l.reason).sort()).toEqual(["not-active", "not-known"]);
  expect(await w.mine("revocation_attribution", [g.grant_id!])).toHaveLength(1);                                   // Composition state 13: one revocation entry per grant
  expect((await allGrants(w))[0].status).toBe("revoked");
});

test("Atomic writes 5, 6, Composition state 13: a grant revoked by another call between the plan and the write answers not-active, the constituent write not retried, the attestation committed as an orphan", async () => {
  const w = await world();
  const g = await issue(w);
  const orig = w.perms.planRevoke.bind(w.perms);
  w.perms.planRevoke = async (id) => { const p = await orig(id); await directRevoke(w, id); return p; };           // another revocation commits after this one's plan
  const r = ans(await w.admin.revokeGrant(g.grant_id!, w.a.ref, w.a.priv));
  w.perms.planRevoke = orig;
  expect(r.refused).toBe("not-active");
  const att = await by(w, w.a.ref);
  const logs = await w.mine("orphan_log", att.map((a) => a.attestation_id));
  expect(logs).toHaveLength(1);
  expect(logs[0]).toMatchObject({ reason: "not-active" });
  expect(await w.mine("revocation_attribution", [g.grant_id!])).toEqual([]);                                       // the other call's revocation is a direct write
});

test("Action wiring 42 to 48, 51, 52, Identity 9, 10, Composes 23, 24: a pair-scoped revocation enumerates the pair's active grants, revokes each under its own attestation at one request instant, and the evaluation then answers denied", async () => {
  const w = await world();
  const subject = who();
  const g1 = ans(await w.admin.issueGrant(subject, "s", w.a.ref, w.a.priv)).grant_id!;
  // Permissions holds a pair once; a second active grant on the pair is what a direct write leaves, which the enumeration must still meet.
  const ghost = `ghost-${crypto.randomUUID()}`;
  await store.commit([store.put(w.grants, { _id: ghost, subject_ref: subject, action_scope: "s", granted_at: "2026-09-01T09:59:00.000Z", status: "active", revoked_at: null })]);
  const old = `old-${crypto.randomUUID()}`;                                                                          // a grant of the pair already revoked: not in the enumerated set
  await store.commit([store.put(w.grants, { _id: old, subject_ref: subject, action_scope: "s", granted_at: "2026-09-01T09:00:00.000Z", status: "revoked", revoked_at: "2026-09-01T09:30:00.000Z" })]);
  expect(await w.admin.permitted(subject, "s")).toBe("permitted");
  w.seam.set("2026-09-03T08:00:00.000Z");
  const r = ans(await w.admin.revokePermission(subject, "s", w.a.ref, w.a.priv));
  expect(r.ok).toBe(true);
  expect(r.revoked_grant_ids!.slice().sort()).toEqual([g1, ghost].sort());                                         // Action wiring 46
  expect(new Set(r.attestation_ids).size).toBe(2);                                                                 // a distinct attestation per grant
  const revs = (await by(w, w.a.ref)).filter((x) => r.attestation_ids!.includes(x.attestation_id));
  expect(revs.map((x) => parse(x.action_ref).requested_at)).toEqual(["2026-09-03T08:00:00.000Z", "2026-09-03T08:00:00.000Z"]);   // Identity 9
  r.revoked_grant_ids!.forEach((id, i) => expect(parse(revs.find((x) => x.attestation_id === r.attestation_ids![i])!.action_ref).grant_id).toBe(id));   // the lists are in one order
  expect(await w.admin.permitted(subject, "s")).toBe("denied");                                                    // Action wiring 51
  expect(await w.mine("revocation_attribution", [g1, ghost])).toHaveLength(2);                                      // Invariant 9.2
});

test("Action wiring 43, 44, 45: a pair-scoped revocation of an unheld pair answers not-permitted, attests nothing, and is never not-known", async () => {
  const w = await world();
  const before = (await w.attestations()).length;
  const r = ans(await w.admin.revokePermission(who(), "s", w.a.ref, w.a.priv));
  expect(r).toEqual({ refused: "not-permitted" });
  expect((await w.attestations()).length).toBe(before);
});

test("Atomic writes 6, 8, Action wiring 46: a grant of the enumerated set another call revoked first is the first refusal; what stood before it is committed, the orphan is logged, and the invocation answers", async () => {
  const w = await world();
  const subject = who();
  const g1 = ans(await w.admin.issueGrant(subject, "s", w.a.ref, w.a.priv)).grant_id!;
  const ghost = `ghost-${crypto.randomUUID()}`;
  await store.commit([store.put(w.grants, { _id: ghost, subject_ref: subject, action_scope: "s", granted_at: "2026-09-01T09:59:00.000Z", status: "active", revoked_at: null })]);
  const orig = w.perms.planRevoke.bind(w.perms);
  const order: string[] = [];
  w.perms.planRevoke = async (id) => { order.push(id); if (order.length === 2) await directRevoke(w, id); return orig(id); };   // the second grant is revoked by another call before its plan reads it
  const r = ans(await w.admin.revokePermission(subject, "s", w.a.ref, w.a.priv));
  w.perms.planRevoke = orig;
  expect(r.refused).toBe("storage-failure");
  const [first, second] = order;
  expect(await w.mine("revocation_attribution", [first])).toHaveLength(1);                                         // the first revocation committed
  expect((await allGrants(w)).find((g) => g.grant_id === first)!.status).toBe("revoked");
  const logs = await w.mine("orphan_log", (await by(w, w.a.ref)).map((a) => a.attestation_id));
  expect(logs).toHaveLength(1);
  expect(logs[0]).toMatchObject({ reason: "not-active" });
  expect([first, second].sort()).toEqual([g1, ghost].sort());
});

test("Action wiring 55 to 60, 78, 79, 80, Invariant 3.1 to 3.4: a verification answers the grant record, the issuance attestation and its verification, and for a revoked grant the revocation's too, writing nothing", async () => {
  const w = await world();
  const g = await issue(w);
  const before = (await w.attestations()).length;
  const v = await w.admin.verifyGrantAttribution(g.grant_id!) as { grant_record: { status: string }; issuance_attestation_id: string; issuance_verify_result: unknown; revocation_attestation_id?: string; revocation_verify_result?: unknown };
  expect(v).toMatchObject({ grant_record: { grant_id: g.grant_id, status: "active" }, issuance_attestation_id: g.attestation_id, issuance_verify_result: "verified" });
  expect(v.revocation_attestation_id).toBeUndefined();                                                             // Action wiring 80: only a revoked grant
  expect(v.revocation_verify_result).toBeUndefined();
  const r = ans(await w.admin.revokeGrant(g.grant_id!, w.a.ref, w.a.priv));
  const v2 = await w.admin.verifyGrantAttribution(g.grant_id!) as typeof v;
  expect(v2).toMatchObject({ grant_record: { status: "revoked" }, issuance_verify_result: "verified", revocation_attestation_id: r.attestation_id, revocation_verify_result: "verified" });
  expect((await w.attestations()).length).toBe(before + 1);                                                        // Action wiring 78: the verification wrote nothing (the one is the revocation)
});

test("Action wiring 56, 58, 60, 70, 71: an unknown grant answers not-known; a grant with no attribution entry, or a revoked one with no revocation entry, answers attribution-inconsistency", async () => {
  const w = await world();
  expect(await w.admin.verifyGrantAttribution("no-such-grant")).toBe("not-known");
  const direct = ((await w.perms.grant(who(), "s")) as { grant_id: string }).grant_id;                              // a direct write
  expect(await w.admin.verifyGrantAttribution(direct)).toBe("attribution-inconsistency");                           // Action wiring 58, Invariant 1.4
  const g = await issue(w);
  await directRevoke(w, g.grant_id!);                                                                               // a direct revocation: no revocation entry
  expect(await w.admin.verifyGrantAttribution(g.grant_id!)).toBe("attribution-inconsistency");                      // Action wiring 60, Invariant 2.4
});

test("Action wiring 61 to 66, 68, 69, 73, 74: an absent attestation reads the purge record; one the purge record names is not-applicable carrying purged, and one it does not is the tamper reading, not-known", async () => {
  const w = await world();
  const g = await issue(w);
  await store.commit([{ text: "DELETE FROM attestations WHERE _id = $1", params: [g.attestation_id!] }]);          // the attestation is gone
  const tamper = await w.admin.verifyGrantAttribution(g.grant_id!) as { issuance_verify_result: unknown };
  expect(tamper.issuance_verify_result).toBe("not-known");                                                          // Action wiring 64: the tamper reading
  w.purged.add(g.attestation_id!);
  const lawful = await w.admin.verifyGrantAttribution(g.grant_id!) as { issuance_verify_result: unknown };
  expect(lawful.issuance_verify_result).toEqual({ "not-applicable": "purged" });                                    // Action wiring 63, 65
});

test("Action wiring 61, 75, 76, 99, 100: a verification that fails answers the reason in the record, and a registry or a mechanism that cannot answer is a failed verification carrying that reason, not a refusal", async () => {
  const w = await world();
  const g = await issue(w);
  w.registry.unreachable = true;
  const v = await w.admin.verifyGrantAttribution(g.grant_id!) as { issuance_verify_result: unknown };
  expect(v.issuance_verify_result).toEqual({ failed: "registry-unavailable" });
  w.registry.unreachable = false;
  const other = w.person();
  w.book.set(w.a.ref, w.book.get(other.ref)!);                                                                      // the registry now holds other material
  const v2 = await w.admin.verifyGrantAttribution(g.grant_id!) as { issuance_verify_result: unknown };
  expect(v2.issuance_verify_result).toEqual({ failed: "proof-invalid" });
});

test("Action wiring 81 to 83, Primitive policy 11, Composes 9, 10: an evaluation passes through unchanged, untrimmed, unrecorded and unattributed", async () => {
  const w = await world();
  const g = await issue(w, "alice", "records:read");
  const before = (await w.attestations()).length;
  expect(await w.admin.permitted("alice", "records:read")).toBe("permitted");
  expect(await w.admin.permitted(" alice", "records:read")).toBe("denied");                                          // not trimmed
  expect(await w.admin.permitted("Alice", "records:read")).toBe("denied");                                           // not folded
  expect((await w.attestations()).length).toBe(before);
  expect(g.grant_id).toBeDefined();
});

test("Capability requirement 20, 35, 29, 30, Composes: a blank declaration, or a length cap over Permissions', and the composition does not start", async () => {
  await expect(world({ clockOffsetAllowanceMs: null })).rejects.toThrow(/clock offset allowance/);
  await expect(world({ retentionHorizonMs: null })).rejects.toThrow(/retention horizon/);
  await expect(world({ namespacePrefix: " " })).rejects.toThrow(/namespace prefix/);
  await expect(world({ lengthCap: 300 })).rejects.toThrow(/length cap/);
  const w = await world({ lengthCap: 50, permissionsCap: 60 });                                                    // Capability requirement 29: a smaller cap stands
  expect(ans(await w.admin.issueGrant("x".repeat(51), "s", w.a.ref, w.a.priv)).refused).toBe("invalid-request");
  expect(ans(await w.admin.issueGrant("x".repeat(50), "s", w.a.ref, w.a.priv)).refused).toBeUndefined();
  const d = await world({ permissionsCap: 50 });                                                                    // Capability requirement 36: none declared, Permissions' own
  expect(ans(await d.admin.issueGrant("x".repeat(51), "s", d.a.ref, d.a.priv)).refused).toBe("invalid-request");
  expect(ans(await d.admin.issueGrant("x".repeat(50), "s", d.a.ref, d.a.priv)).refused).toBeUndefined();
});

test("Execution Contract Constituent failure 3: a failed read of the database answers state-unavailable and writes nothing", async () => {
  const w = await world();
  const real = w.perms.read.bind(w.perms);
  w.perms.read = async () => { throw new Unavailable(); };
  expect(ans(await w.admin.issueGrant("bob", "s", w.a.ref, w.a.priv)).refused).toBe("state-unavailable");
  expect(ans(await w.admin.revokePermission("bob", "s", w.a.ref, w.a.priv)).refused).toBe("state-unavailable");
  w.perms.read = real;
  expect(await by(w, w.a.ref)).toEqual([]);
});
