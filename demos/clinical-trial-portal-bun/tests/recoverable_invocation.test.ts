// Recoverable Invocation's [Open], [Close], [Refuse] and [Yield], one test for each rule the render answers.
import { test, expect, afterAll } from "bun:test";
import { Store, Unavailable } from "../src/store.ts";
import { type LoggedEvent } from "../src/event_log.ts";
import { RecoverableInvocation, type Journal, type JournalAnswer } from "../src/recoverable_invocation.ts";
import { worldFor, ok, key, KIND, OUT, DAY } from "./ri_world.ts";

const store = new Store();
afterAll(() => store.close());
const world = worldFor(store);


test("Open step 4.3, Primitive policy 4, 9, 11; open step 5.1 to 5.3, act section 9: an intent record carries invocation id, kind, act key and the caller's data; open invocations holds it from the range read; the section is held at return", async () => {
  const w = await world();
  const r = ok(await w.open()) as { invocation_id: string; intent_event_id: string };
  const recs = await w.records();
  expect(recs).toHaveLength(1);
  expect(recs[0].action_ref).toBe("disclosure.intended");
  expect(recs[0].data).toEqual({ invocation_id: r.invocation_id, kind: KIND, act_key: "act-1", intent_data: { pairing: "p1" } });
  expect(await w.ri.openIntents(KIND, "act-1")).toEqual([{ invocation_id: r.invocation_id, intent_event_id: r.intent_event_id }]);
  const held = await w.realLease.remaining(key(), r.invocation_id);                                          // open step 5.3: held at return
  expect(held).not.toBe("none");
  expect(await w.realLease.tryTake(key(), "someone-else", 1000)).toBe("held");
});

test("Close step 3.1, 4.1 to 4.3, Primitive policy 11a, close 3: an outcome carries the intent event id, clears open invocations, releases the section and answers outcome event id with the invocation as landing actor", async () => {
  const w = await world();
  const r = ok(await w.open()) as { invocation_id: string; intent_event_id: string };
  const c = ok(await w.ri.close(KIND, "act-1", r.invocation_id, r.intent_event_id, w.a.ref, w.a.priv, OUT, { record: 7 })) as { outcome_event_id: string; landed_by: string };
  expect(c.landed_by).toBe("invocation");
  const recs = await w.records();
  expect(recs.map((x) => x.action_ref)).toEqual(["disclosure.intended", OUT]);
  expect(recs[1].data).toEqual({ invocation_id: r.invocation_id, kind: KIND, act_key: "act-1", intent_event_id: r.intent_event_id, data: { record: 7 } });
  expect(await w.ri.openIntents(KIND, "act-1")).toEqual([]);
  expect(await w.realLease.tryTake(key(), "someone-else", 1000)).toMatchObject({ taken: expect.any(String) });
});

test("Open step 1.9, 1.10, 1.2, 1.3, 1.4, 1.5, Primitive policy 12, 13: an unbound kind, a blank act key, actor or credential, a caller that is the service identity, and a record too big for the substrate are refused invalid-request with nothing written and no take", async () => {
  const w = await world();
  expect(await w.ri.open("nokind", "act-1", w.a.ref, w.a.priv, {})).toEqual({ refused: "invalid-request" });
  expect(await w.open("  ")).toEqual({ refused: "invalid-request" });
  expect(await w.ri.open(KIND, "act-1", "", w.a.priv, {})).toEqual({ refused: "invalid-request" });
  expect(await w.ri.open(KIND, "act-1", w.a.ref, "", {})).toEqual({ refused: "invalid-request" });
  expect(await w.ri.open(KIND, "act-1", w.svc.ref, w.svc.priv, {})).toEqual({ refused: "invalid-request" });
  expect(await w.open("act-1", { big: "x".repeat(70_000) })).toEqual({ refused: "invalid-request" });
  expect((await w.records()).length).toBe(0);
  expect(w.sec.taken).toEqual([]);
});

test("Open step 1.6 to 1.8, 3.13, Capability requirement 6, 13: a journal read that fails is journal-unavailable with nothing written, before a take at step 1 and released at step 3; an invalid-query is surfaced and lands the same", async () => {
  const w = await world();
  w.reads.mode = "unavailable";
  expect(await w.open()).toEqual({ refused: "journal-unavailable" });
  expect(w.sec.taken).toEqual([]);                                                                            // step 1.6: the read comes before any take
  w.reads.mode = "invalid-query";
  expect(await w.open()).toEqual({ refused: "journal-unavailable" });
  expect(w.surfaced.map((s) => s.arm)).toEqual(["invalid-query"]);                                            // Capability requirement 4: surfaced
  w.reads.mode = "ok";
  let reads = 0;
  const real = w.ri as unknown as { refresh: (...a: unknown[]) => Promise<void> };
  const orig = real.refresh.bind(w.ri);
  real.refresh = async (...args: unknown[]) => { if (++reads === 2) { w.reads.mode = "unavailable"; } return orig(...args); };   // the step-3 re-read fails
  expect(await w.open()).toEqual({ refused: "journal-unavailable" });
  expect(w.sec.released).toHaveLength(1);                                                                     // open step 3.13a
  expect((await w.records()).length).toBe(0);                                                                 // 3.13b: nothing written
});

test("Open step 1.7, 3.4, 3.5, Term in-flight: an open intent younger than invocation completion bound refuses act-in-flight naming it, with no take", async () => {
  const w = await world();
  const first = ok(await w.open()) as { invocation_id: string };
  await w.ri.yieldSection(KIND, "act-1", first.invocation_id, "answered");
  w.sec.taken.length = 0;
  w.seam.advance(5000);
  expect(await w.open()).toEqual({ refused: "act-in-flight", invocation_id: first.invocation_id });
  expect(w.sec.taken).toEqual([]);                                                                            // step 1.7: no take
});

test("Open step 3.6, 3.7: an aged open intent, the kind's service identity not none, refuses act-in-flight too; and open step 3.8: under none [Open] proceeds, leaves the old intent open and raises a hard alert", async () => {
  const s = await world();
  const old = ok(await s.open()) as { invocation_id: string };
  await s.ri.yieldSection(KIND, "act-1", old.invocation_id, "answered");
  s.seam.advance(10_100);                                                                                     // past the examine edge (completion bound and the allowance)
  expect(await s.open()).toEqual({ refused: "act-in-flight", invocation_id: old.invocation_id });
  const n = await world({ service: null });
  const o2 = ok(await n.open()) as { invocation_id: string };
  await n.ri.yieldSection(KIND, "act-1", o2.invocation_id, "answered");
  n.seam.advance(10_100);
  const fresh = ok(await n.open()) as { invocation_id: string };
  expect(fresh.invocation_id).not.toBe(o2.invocation_id);                                                     // 3.8a, 3.8e: the new invocation pairs on its own id
  expect(n.alerts).toContainEqual({ invocation_id: o2.invocation_id, arm: "aged-open-intent" });              // 3.8c
  expect((await n.ri.openIntents(KIND, "act-1")).map((x) => x.invocation_id).sort()).toEqual([o2.invocation_id, fresh.invocation_id].sort());   // 3.8b: the old intent stays open
});

test("Open step 3.9, repeatable 1: a non-repeatable act whose outcome stands refuses act-landed with the outcome event id; a repeatable one opens again", async () => {
  const w = await world();
  const r = ok(await w.open()) as { invocation_id: string; intent_event_id: string };
  const c = ok(await w.ri.close(KIND, "act-1", r.invocation_id, r.intent_event_id, w.a.ref, w.a.priv, OUT, {})) as { outcome_event_id: string };
  expect(await w.open()).toEqual({ refused: "act-landed", outcome_event_id: c.outcome_event_id });
  expect(w.sec.released.length).toBeGreaterThan(1);                                                           // step 3.9b: released
  const rep = await world({ repeatable: true });
  const r2 = ok(await rep.open()) as { invocation_id: string; intent_event_id: string };
  ok(await rep.ri.close(KIND, "act-1", r2.invocation_id, r2.intent_event_id, rep.a.ref, rep.a.priv, OUT, {}));
  ok(await rep.open());
});

test("Open step 2.3, act section 5, 17: a take that does not give the section is section-unavailable with nothing written, whether it answers unavailable or fails", async () => {
  const w = await world();
  w.sec.takeUnavailable = true;
  expect(await w.open()).toEqual({ refused: "section-unavailable" });
  w.sec.takeUnavailable = false; w.sec.takeThrows = true;
  expect(await w.open()).toEqual({ refused: "section-unavailable" });
  expect((await w.records()).length).toBe(0);
});

test("Open step 4.1, 4.2, journal write bound 1: a remaining at or below write floor writes no intent, releases and lands section-unavailable", async () => {
  const w = await world();
  w.sec.remaining = (n) => (n === 2 ? 1300 : 9000);                                                           // calls: step 3's lease check (1), step 4's reading (2)
  expect(await w.open()).toEqual({ refused: "section-unavailable" });
  expect((await w.records()).length).toBe(0);
  expect(w.sec.released).toHaveLength(1);
});

test("Open step 5.4 to 5.6, Term commit floor: a remaining at or below commit floor after the intent landed releases and lands recording-failure(outcome) with the intent left open", async () => {
  const w = await world();
  w.sec.remaining = (n) => (n >= 3 ? 2400 : 9000);                                                            // the step-5 reading (3rd) is at the floor
  expect(await w.open()).toEqual({ refused: "recording-failure", position: "outcome" });
  expect((await w.records()).map((r) => r.action_ref)).toEqual(["disclosure.intended"]);
  expect(w.sec.released).toHaveLength(1);
  expect(await w.ri.openIntents(KIND, "act-1")).toHaveLength(1);
});

test("Primitive policy 19, open step 4.5: an invalid credential at the intent passes through unchanged with nothing written, the section released", async () => {
  const w = await world();
  expect(await w.ri.open(KIND, "act-1", w.a.ref, w.stranger.priv, {})).toEqual({ refused: "invalid-credential" });
  expect((await w.records()).length).toBe(0);
  expect(w.sec.released).toHaveLength(1);
});

test("Primitive policy 20 to 23, 41, 44, 45: at the intent position invalid-request(step-1) is invalid-request; recording-failure(step-2) and a state-unavailable answer are recording-failure(intent); each released, nothing committed", async () => {
  const w = await world();
  w.script.push("step1");
  expect(await w.open()).toEqual({ refused: "invalid-request" });
  w.script.push("rf2");
  expect(await w.open()).toEqual({ refused: "recording-failure", position: "intent" });
  w.script.push("unavailable");
  expect(await w.open()).toEqual({ refused: "recording-failure", position: "intent" });
  expect((await w.records()).length).toBe(0);
  expect(w.sec.released).toHaveLength(3);
});

test("Primitive policy 20 to 22, 28: an invalid-request(step-4) at the intent is read back by invocation id; found, [Open] proceeds with a hard alert; nothing found, invalid-request", async () => {
  const w = await world();
  w.script.push("step4-landed");
  const r = ok(await w.open()) as { invocation_id: string };
  expect(w.alerts).toContainEqual({ invocation_id: r.invocation_id, arm: "intent-read-back" });
  w.script.push("step4-nothing");
  expect(await w.open("act-2")).toEqual({ refused: "invalid-request" });
});

test("Primitive policy 32 to 37b, 34: a lost reply at the intent is read back once, after journal write bound; found, adopted; nothing found, recording-failure(intent). recording-failure(step-3) reads as a lost reply", async () => {
  const w = await world();
  const t0 = w.seam.now();
  w.script.push("lost-landed");
  const r = ok(await w.open()) as { invocation_id: string; intent_event_id: string };
  expect(Date.parse(w.seam.now()) - Date.parse(t0)).toBeGreaterThanOrEqual(1000);                            // not read back before journal write bound
  expect((await w.records()).filter((x) => x.action_ref === "disclosure.intended")).toHaveLength(1);          // not retried blind (33)
  expect(r.intent_event_id).toBe((await w.ri.openIntents(KIND, "act-1"))[0].intent_event_id);
  w.script.push("lost-nothing");
  expect(await w.open("act-2")).toEqual({ refused: "recording-failure", position: "intent" });
  w.script.push("rf3-landed");
  ok(await w.open("act-3"));
  w.script.push("rf3-nothing");
  expect(await w.open("act-4")).toEqual({ refused: "recording-failure", position: "intent" });
});

test("Close step 1.2, 3.10: a remaining at or below write floor writes nothing, discards the commit's reply, releases and lands recording-failure(outcome)", async () => {
  const w = await world();
  const r = ok(await w.open()) as { invocation_id: string; intent_event_id: string };
  w.sec.remaining = () => 1300;
  expect(await w.ri.close(KIND, "act-1", r.invocation_id, r.intent_event_id, w.a.ref, w.a.priv, OUT, {})).toEqual({ refused: "recording-failure", position: "outcome" });
  expect((await w.records()).map((x) => x.action_ref)).toEqual(["disclosure.intended"]);
  const released = w.sec.released.length;
  w.sec.remaining = (n) => (n === 1 ? 9000 : 1300);                                                           // the reading behind the re-read
  expect(await w.ri.close(KIND, "act-1", r.invocation_id, r.intent_event_id, w.a.ref, w.a.priv, OUT, {})).toEqual({ refused: "recording-failure", position: "outcome" });
  expect(w.sec.released.length).toBe(released + 1);
  expect((await w.records()).length).toBe(1);
});

test("Close 6: an outcome action reference outside the kind's enumerated refs lands recording-failure(outcome) with a hard alert, released, nothing appended", async () => {
  const w = await world();
  const r = ok(await w.open()) as { invocation_id: string; intent_event_id: string };
  expect(await w.ri.close(KIND, "act-1", r.invocation_id, r.intent_event_id, w.a.ref, w.a.priv, "disclosure.invented", {})).toEqual({ refused: "recording-failure", position: "outcome" });
  expect(w.alerts).toContainEqual({ invocation_id: r.invocation_id, arm: "outcome-ref-not-enumerated" });
  expect((await w.records()).length).toBe(1);
  expect(w.sec.released).toHaveLength(1);
});

test("Close step 2.2: an outcome already standing among the closings is adopted, released, and its landing actor read from the record: the invocation, the sweep (recovery), the operator (resolving actor)", async () => {
  for (const [extra, who] of [[{}, "invocation"], [{ recovery: true }, "sweep"], [{ recovery: true, resolving_actor: "op-1" }, "operator"]] as const) {
    const w = await world();
    const r = ok(await w.open()) as { invocation_id: string; intent_event_id: string };
    const landed = ok(await w.closing(OUT, r.invocation_id, "act-1", extra)) as { event_id: string };
    const c = await w.ri.close(KIND, "act-1", r.invocation_id, r.intent_event_id, w.a.ref, w.a.priv, OUT, {});
    expect(c).toEqual({ outcome_event_id: landed.event_id, landed_by: who });
    expect((await w.records()).filter((x) => x.action_ref === OUT)).toHaveLength(1);                           // one standing closing: nothing appended
  }
});

test("Close step 2.3, Which closing stands 2 to 7: an abandonment or an escalation standing is not adopted (recording-failure(outcome)); an outcome superseding the escalation is the standing closing and is adopted", async () => {
  const w = await world();
  const r = ok(await w.open()) as { invocation_id: string; intent_event_id: string };
  const esc = ok(await w.closing("disclosure.escalated", r.invocation_id, "act-1")) as { event_id: string };
  expect(await w.ri.close(KIND, "act-1", r.invocation_id, r.intent_event_id, w.a.ref, w.a.priv, OUT, {})).toEqual({ refused: "recording-failure", position: "outcome" });
  expect((await w.records()).filter((x) => x.action_ref === OUT)).toHaveLength(0);
  const r2 = ok(await w.open("act-2")) as { invocation_id: string; intent_event_id: string };                    // a held section for the second invocation
  const esc2 = ok(await w.closing("disclosure.escalated", r2.invocation_id, "act-2")) as { event_id: string };
  const out = ok(await w.closing(OUT, r2.invocation_id, "act-2", { supersedes: esc2.event_id, resolving_actor: "op-1" })) as { event_id: string };
  const c = await w.ri.close(KIND, "act-2", r2.invocation_id, r2.intent_event_id, w.a.ref, w.a.priv, OUT, {});
  expect(c).toEqual({ outcome_event_id: out.event_id, landed_by: "operator" });                                // the escalation is superseded: the outcome stands
});

test("Close step 2.4, 2.4a to 2.4c: a re-read that fails writes nothing, releases and lands recording-failure(outcome)", async () => {
  const w = await world();
  const r = ok(await w.open()) as { invocation_id: string; intent_event_id: string };
  w.reads.mode = "unavailable";
  expect(await w.ri.close(KIND, "act-1", r.invocation_id, r.intent_event_id, w.a.ref, w.a.priv, OUT, {})).toEqual({ refused: "recording-failure", position: "outcome" });
  expect((await w.records()).length).toBe(1);
  expect(w.sec.released).toHaveLength(1);
});

test("Capability requirement 15: a read under the critical section that returns nothing within read bound lands where unavailable lands", async () => {
  const w = await world({ readBoundMs: 40 });
  const r = ok(await w.open()) as { invocation_id: string; intent_event_id: string };
  w.reads.mode = "hang";
  expect(await w.ri.close(KIND, "act-1", r.invocation_id, r.intent_event_id, w.a.ref, w.a.priv, OUT, {})).toEqual({ refused: "recording-failure", position: "outcome" });
  expect((await w.records()).length).toBe(1);
});

test("Primitive policy 29, 30, close step 3.4, 3.5, 3.7: a recording-failure(step-2) at the outcome is retried under the section with step 2 re-run first, to the terminus at most; cut short, recording-failure(outcome), released", async () => {
  const w = await world();
  const r = ok(await w.open()) as { invocation_id: string; intent_event_id: string };
  w.script.push("rf2", "rf2");
  const c = ok(await w.ri.close(KIND, "act-1", r.invocation_id, r.intent_event_id, w.a.ref, w.a.priv, OUT, {})) as { landed_by: string };
  expect(c.landed_by).toBe("invocation");
  expect(w.calls.filter((x) => x === OUT)).toHaveLength(3);                                                   // two failures, then the write that landed
  const x = await world();
  const r2 = ok(await x.open()) as { invocation_id: string; intent_event_id: string };
  x.setPerCall(2500);                                                                                         // every call takes 2.5 seconds; the lease is ten
  x.script.push("rf2", "rf2", "rf2", "rf2", "rf2", "rf2", "rf2", "rf2");
  expect(await x.ri.close(KIND, "act-1", r2.invocation_id, r2.intent_event_id, x.a.ref, x.a.priv, OUT, {})).toEqual({ refused: "recording-failure", position: "outcome" });
  expect(x.calls.filter((c2) => c2 === OUT).length).toBeLessThan(5);                                          // stopped at the terminus, not after eight
  expect(x.sec.released.length).toBeGreaterThan(0);
});

test("Primitive policy 31, close step 3.3, 3.8: at the outcome an invalid credential and an invalid-request(step-1) land recording-failure(outcome), the second with a hard alert; no retry", async () => {
  const w = await world();
  const r = ok(await w.open()) as { invocation_id: string; intent_event_id: string };
  expect(await w.ri.close(KIND, "act-1", r.invocation_id, r.intent_event_id, w.a.ref, w.stranger.priv, OUT, {})).toEqual({ refused: "recording-failure", position: "outcome" });
  const r2 = ok(await w.open("act-2")) as { invocation_id: string; intent_event_id: string };
  w.script.push("step1");
  expect(await w.ri.close(KIND, "act-2", r2.invocation_id, r2.intent_event_id, w.a.ref, w.a.priv, OUT, {})).toEqual({ refused: "recording-failure", position: "outcome" });
  expect(w.alerts.some((x) => x.invocation_id === r2.invocation_id)).toBe(true);
  expect(w.calls.filter((x) => x === OUT)).toHaveLength(2);
});

test("Primitive policy 27, 28, 36, 37b, 40: at the outcome a step-4 read-back that finds the record succeeds with a hard alert; nothing found, recording-failure(outcome) with a hard alert; a lost reply is read back once, adopted or recording-failure(outcome)", async () => {
  const w = await world();
  const r = ok(await w.open()) as { invocation_id: string; intent_event_id: string };
  w.script.push("step4-landed");
  const c = ok(await w.ri.close(KIND, "act-1", r.invocation_id, r.intent_event_id, w.a.ref, w.a.priv, OUT, {})) as { landed_by: string };
  expect(c.landed_by).toBe("invocation");
  expect(w.alerts).toContainEqual({ invocation_id: r.invocation_id, arm: "outcome-read-back" });
  const r2 = ok(await w.open("act-2")) as { invocation_id: string; intent_event_id: string };
  w.script.push("step4-nothing");
  expect(await w.ri.close(KIND, "act-2", r2.invocation_id, r2.intent_event_id, w.a.ref, w.a.priv, OUT, {})).toEqual({ refused: "recording-failure", position: "outcome" });
  expect(w.alerts).toContainEqual({ invocation_id: r2.invocation_id, arm: "invalid-request-step-4" });
  const r3 = ok(await w.open("act-3")) as { invocation_id: string; intent_event_id: string };
  w.script.push("lost-landed");
  ok(await w.ri.close(KIND, "act-3", r3.invocation_id, r3.intent_event_id, w.a.ref, w.a.priv, OUT, {}));
  expect((await w.records()).filter((x) => x.action_ref === OUT && x.data.invocation_id === r3.invocation_id)).toHaveLength(1);
  const r4 = ok(await w.open("act-4")) as { invocation_id: string; intent_event_id: string };
  w.script.push("lost-nothing");
  expect(await w.ri.close(KIND, "act-4", r4.invocation_id, r4.intent_event_id, w.a.ref, w.a.priv, OUT, {})).toEqual({ refused: "recording-failure", position: "outcome" });
});

test("Refuse step 3.1, 3.9, 3.10, 3.12: a refusal record carries the invocation id, intent event id, kind, act key, reason and constituent code under the caller's credential, clears open invocations and releases", async () => {
  const w = await world();
  const r = ok(await w.open()) as { invocation_id: string; intent_event_id: string };
  const f = ok(await w.ri.refuse(KIND, "act-1", r.invocation_id, r.intent_event_id, w.a.ref, w.a.priv, "no such patient", "patient-not-found")) as { refusal_event_id: string };
  const recs = await w.records();
  expect(recs[1].action_ref).toBe("disclosure.refused");
  expect(recs[1].data).toEqual({ invocation_id: r.invocation_id, intent_event_id: r.intent_event_id, kind: KIND, act_key: "act-1", reason: "no such patient", constituent_code: "patient-not-found" });
  expect(f.refusal_event_id).toBeDefined();
  expect(await w.ri.openIntents(KIND, "act-1")).toEqual([]);
  expect(w.sec.released).toHaveLength(1);
});

test("Refuse step 1.2, 3.13: a remaining at or below write floor writes nothing, releases and lands recording-failure(refusal, constituent code)", async () => {
  const w = await world();
  const r = ok(await w.open()) as { invocation_id: string; intent_event_id: string };
  w.sec.remaining = () => 1300;
  expect(await w.ri.refuse(KIND, "act-1", r.invocation_id, r.intent_event_id, w.a.ref, w.a.priv, "why", "code-9")).toEqual({ refused: "recording-failure", position: "refusal", constituent_code: "code-9" });
  w.sec.remaining = (n) => (n === 1 ? 9000 : 1300);
  expect(await w.ri.refuse(KIND, "act-1", r.invocation_id, r.intent_event_id, w.a.ref, w.a.priv, "why", "code-9")).toEqual({ refused: "recording-failure", position: "refusal", constituent_code: "code-9" });
  expect((await w.records()).length).toBe(1);
});

test("Refuse step 2.2, 2.3, 2.5: a closing already naming the invocation id is already-accounted with its event id, nothing appended, released", async () => {
  const w = await world();
  const r = ok(await w.open()) as { invocation_id: string; intent_event_id: string };
  const landed = ok(await w.closing(OUT, r.invocation_id, "act-1")) as { event_id: string };
  expect(await w.ri.refuse(KIND, "act-1", r.invocation_id, r.intent_event_id, w.a.ref, w.a.priv, "why", "c")).toEqual({ refused: "already-accounted", closing_event_id: landed.event_id });
  expect((await w.records()).length).toBe(2);
  expect(w.sec.released).toHaveLength(1);
});

test("Refuse step 3.4 to 3.8: every failed refusal write lands recording-failure(refusal, constituent code) with the intent left open and no retry", async () => {
  const w = await world();
  let i = 0;
  const refuseWith = async (m: Mode | null, cred = w.a.priv) => {
    const k = `act-${++i}`;                                                                                   // each refusal needs a section of its own: a failed one releases
    const r = ok(await w.open(k)) as { invocation_id: string; intent_event_id: string };
    if (m) w.script.push(m);
    return { r, k, out: await w.ri.refuse(KIND, k, r.invocation_id, r.intent_event_id, w.a.ref, cred, "why", "c-1") };
  };
  const fail = { refused: "recording-failure", position: "refusal", constituent_code: "c-1" };
  for (const m of ["rf2", "step1", "step4-nothing", "lost-nothing", "rf3-nothing", "unavailable"] as Mode[]) {
    const x = await refuseWith(m);
    expect(x.out).toEqual(fail);
    expect(await w.ri.openIntents(KIND, x.k)).toHaveLength(1);                                                // the intent stands open for the sweep
  }
  expect((await refuseWith(null, w.stranger.priv)).out).toEqual(fail);
  expect(w.calls.filter((x) => x === "disclosure.refused")).toHaveLength(7);                                  // one call each: no retry
  ok((await refuseWith("lost-landed")).out);                                                                  // a lost reply whose read-back finds the record is the refusal event id
});

test("Yield 1, 4, 5, 6: [Yield] writes nothing; an answered reply releases the section; a lost one issues no release and the grant ends at its instant", async () => {
  const w = await world();
  const r = ok(await w.open()) as { invocation_id: string };
  const before = (await w.records()).length;
  expect(await w.ri.yieldSection(KIND, "act-1", r.invocation_id, "lost")).toBe("ok");
  expect(w.sec.released).toEqual([]);
  expect(await w.realLease.tryTake(key(), "another", 1000)).toBe("held");
  w.seam.advance(10_001);                                                                                     // the grant ended at its instant
  expect(await w.realLease.tryTake(key(), "another", 1000)).toMatchObject({ taken: expect.any(String) });
  const x = await world();
  const r2 = ok(await x.open()) as { invocation_id: string };
  expect(await x.ri.yieldSection(KIND, "act-1", r2.invocation_id, "answered")).toBe("ok");
  expect(x.sec.released).toHaveLength(1);
  expect((await x.records()).length).toBe(1);                                                                 // yield 4: the intent is not closed
  expect((await w.records()).length).toBe(before);
});

test("Sequence high water 2, 1, 6: the mark does not pass a record before settle bound has elapsed since its recording instant, a re-read reads it once, and a lost mark rebuilds from the beginning", async () => {
  const w = await world();
  ok(await w.open());
  const m1 = w.ri.sequenceHighWater;
  expect(m1).toBe(0);                                                                                         // the intent is younger than settle bound (1,050 ms)
  w.seam.advance(2000);
  await w.ri.openIntents(KIND, "act-1");
  expect(w.ri.sequenceHighWater).toBe(1);
  expect(await w.ri.openIntents(KIND, "act-1")).toHaveLength(1);                                              // read once, not twice
  await w.ri.rebuild();
  expect(await w.ri.openIntents(KIND, "act-1")).toHaveLength(1);
});

test("Sequence high water 5, Term retention end: an intent past its retention end is dropped from open invocations on every read", async () => {
  const w = await world({ service: null });
  ok(await w.open());
  expect(await w.ri.openIntents(KIND, "act-1")).toHaveLength(1);
  w.seam.advance(365 * DAY);
  expect(await w.ri.openIntents(KIND, "act-1")).toEqual([]);
});

test("Capability requirement 11: without the range read, read-your-writes or the act section the composition does not start", async () => {
  const w = await world();
  const cfg = { journal: undefined as unknown as Journal, actSection: w.realLease, bindings: {}, compliance: { hardAlert() {}, surface() {} }, journalWriteBoundMs: 1, pauseBoundMs: 1, commitRoundTripMs: 1, clockAllowanceMs: 1, intentCandidatesCap: 1, referenceLengthCap: 1 };
  await expect(RecoverableInvocation.start(w.seam, cfg)).rejects.toThrow(/does not start/);
});
