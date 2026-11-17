// Recoverable Invocation's [Resolve] and [Read Invocation]: one test for each rule the render answers.
import { test, expect, afterAll } from "bun:test";
import { Store } from "../src/store.ts";
import { type LoggedEvent } from "../src/event_log.ts";
import { type Tally, type InvocationReport, type InvocationEntry, type ResolveResult } from "../src/recoverable_invocation.ts";
import { worldFor, ok, key, KIND, OUT } from "./ri_world.ts";

const store = new Store();
afterAll(() => store.close());
const world = worldFor(store);
const resolveWorld = (o: Parameters<typeof world>[0] = {}) => world({ sweep: true, ...o });
type W = Awaited<ReturnType<typeof resolveWorld>>;
type Opened = { invocation_id: string; intent_event_id: string };

/** An invocation that opened and was never closed: its section yielded, the intent left open. */
const died = async (w: W, act = "act-1"): Promise<Opened> => {
  const r = ok(await w.ri.open(KIND, act, w.a.ref, w.a.priv, { pairing: `p-${act}` })) as Opened;
  await w.ri.yieldSection(KIND, act, r.invocation_id, "answered");
  return r;
};
const age = (w: W, ms = 11_000) => w.seam.advance(ms);                                                      // past the examine edge: completion bound 10 000 and the allowance 50
const aged = async (w: W, act = "act-1") => { const r = await died(w, act); age(w); return r; };
const raw = async (w: W) => ((await w.log.read({ sequence: { from: 1 } })) as LoggedEvent[]).map((e) => ({ id: e.event_id, ...(e.data as unknown as { action_ref: string; actor_ref: string; data: Record<string, unknown> }) }));
const count = async (w: W) => (await raw(w)).length;
const outcome = (n = 1) => ({ form: "outcome" as const, outcome_action_ref: OUT, outcome_data: { n } });
const abandoned = (cause = "the act never ran") => ({ form: "abandoned" as const, cause });
const escalated = (candidates: string[] = ["c1"]) => ({ form: "escalated" as const, candidates });
const done = (r: unknown) => (r as ResolveResult).closing_event_id;
const refused = (r: unknown) => r as { refused: string; cause?: string; closing_event_id?: string; position?: string };
const run = async (w: W) => (await w.ri.reconcile()) as Tally;
const report = (r: unknown) => ok(r as InvocationReport) as InvocationReport;
const states = (r: InvocationReport) => r.invocations.map((e) => e.state);

test("resolve 1, 30, 31, 33: a kind not served, a disposition outside the three forms, an outcome ref outside the enumerated refs: invalid-request(malformed) with no take and nothing appended", async () => {
  const w = await resolveWorld();
  const r = await aged(w);
  const before = await count(w);
  const bad = [
    await w.ri.resolve("nokind", "act-1", r.invocation_id, r.intent_event_id, w.op.ref, w.op.priv, outcome()),
    await w.resolve(r.invocation_id, r.intent_event_id, { form: "bogus" } as never),
    await w.resolve(r.invocation_id, r.intent_event_id, null as never),
    await w.resolve(r.invocation_id, r.intent_event_id, { form: "outcome", outcome_action_ref: "disclosure.other", outcome_data: {} }),
    await w.resolve(r.invocation_id, r.intent_event_id, { form: "outcome", outcome_action_ref: 7, outcome_data: {} } as never),
    await w.resolve(r.invocation_id, r.intent_event_id, { form: "abandoned", cause: 7 } as never),
    await w.resolve(r.invocation_id, r.intent_event_id, { form: "escalated", candidates: "c1" } as never),
    await w.resolve(r.invocation_id, r.intent_event_id, { form: "escalated", candidates: [1] } as never),
  ];
  for (const x of bad) expect(refused(x)).toEqual({ refused: "invalid-request", cause: "malformed" });
  expect(w.sec.taken).toHaveLength(1);                                                                        // the open's take alone: no take for a refusal of the form
  expect(w.rr.asked).toHaveLength(0);
  expect(await count(w)).toBe(before);
});

test("resolve 28, 27: candidates over the intent candidates cap: invalid-request(candidates-over-cap), nothing appended; the cap itself is allowed", async () => {
  const w = await resolveWorld();
  const r = await aged(w);
  const before = await count(w);
  expect(refused(await w.resolve(r.invocation_id, r.intent_event_id, escalated(["1", "2", "3", "4", "5", "6"])))).toEqual({ refused: "invalid-request", cause: "candidates-over-cap" });
  expect(await count(w)).toBe(before);
  ok(await w.resolve(r.invocation_id, r.intent_event_id, escalated(["1", "2", "3", "4", "5"])));
  expect(await count(w)).toBe(before + 1);
});

test("resolve 4, 6, Term operator run id, Term sweep lease: the take is (kind, act key), a fresh operator run id, sweep lease; a failed take is section-unavailable with nothing written", async () => {
  const w = await resolveWorld();
  const r = await aged(w);
  const taken0 = w.sec.taken.length;
  ok(await w.resolve(r.invocation_id, r.intent_event_id, escalated()));
  w.seam.advance(1000);
  ok(await w.resolve(r.invocation_id, r.intent_event_id, outcome()));
  expect(w.sec.taken.slice(taken0)).toEqual([key(), key()]);
  const [h1, h2] = w.sec.holders.slice(-2);
  expect(h1).not.toBe(h2);                                                                                    // fresh for every call
  expect(h1).not.toBe(r.invocation_id);
  expect(w.sec.terms.slice(-2)).toEqual([5000 + 1000, 5000 + 1000]);                                          // closure latency and journal write bound
  const x = await aged(w, "act-2");
  const before = await count(w);
  w.sec.remaining = () => 6000;                                                                               // a lease that reads as held, so only the take's own answer stops the call (resolve 6)
  w.sec.takeUnavailable = true;
  expect(refused(await w.resolve(x.invocation_id, x.intent_event_id, outcome()))).toEqual({ refused: "section-unavailable" });
  w.sec.takeUnavailable = false; w.sec.takeThrows = true;
  expect(refused(await w.resolve(x.invocation_id, x.intent_event_id, outcome(), "act-2"))).toEqual({ refused: "section-unavailable" });
  w.sec.takeThrows = false; w.sec.remaining = null;
  expect(await count(w)).toBe(before);
  expect(w.rr.asked).toHaveLength(2);                                                                         // only the two resolves that took the section read
});

test("resolve 7, 38, 39: a remaining at or below the write floor, before the re-read or before the closing, is section-unavailable, nothing written, released", async () => {
  const w = await resolveWorld();
  const r = await aged(w);
  const before = await count(w);
  for (const failAt of [1, 2]) {
    w.sec.remainingCalls = 0;
    w.sec.remaining = (n) => (n === failAt ? 1300 : undefined);                                               // write floor 1000 + 3 * 100: an equal remaining does not exceed it
    const released = w.sec.released.length;
    expect(refused(await w.resolve(r.invocation_id, r.intent_event_id, outcome()))).toEqual({ refused: "section-unavailable" });
    expect(w.sec.released.length).toBe(released + 1);
    expect(await count(w)).toBe(before);
  }
  w.sec.remainingCalls = 0;
  w.sec.remaining = (n) => (n === 1 ? "none" : undefined);
  expect(refused(await w.resolve(r.invocation_id, r.intent_event_id, outcome()))).toEqual({ refused: "section-unavailable" });
  w.sec.remaining = (n) => (n === 1 ? 1301 : undefined);
  w.sec.remainingCalls = 0;
  ok(await w.resolve(r.invocation_id, r.intent_event_id, outcome()));                                         // a remaining that exceeds the floor proceeds
});

test("resolve 8, Capability requirement 6, 13, 15: a re-read that fails, is invalid or returns nothing within read bound is recording-failure(resolution), nothing written, released", async () => {
  const w = await resolveWorld();
  const r = await aged(w);
  const before = await count(w);
  for (const mode of ["unavailable", "invalid-query", "hang"] as const) {
    w.reads.mode = mode;
    const released = w.sec.released.length;
    expect(refused(await w.resolve(r.invocation_id, r.intent_event_id, outcome()))).toEqual({ refused: "recording-failure", position: "resolution" });
    expect(w.sec.released.length).toBe(released + 1);
  }
  expect(w.surfaced.some((s) => s.arm === "invalid-query")).toBe(true);
  expect(w.rr.asked).toHaveLength(0);
  w.reads.mode = "ok";
  expect(await count(w)).toBe(before);
});

test("resolve 10, 11, 34, 12, Capability requirement 9, 10, 18, 19: read_record by the intent event id; not-known, a record that is no intent of the pair, a Purged payload, and a read that fails", async () => {
  const w = await resolveWorld();
  const r = await aged(w);
  const other = await aged(w, "act-2");
  ok(await w.resolve(r.invocation_id, r.intent_event_id, outcome()));
  const fresh = await aged(w, "act-3");
  const notIntent = await w.closing(`${KIND}.refused`, fresh.invocation_id, "act-3") as { event_id: string };         // carries the pair, and is no intent
  const otherKey = await w.closing(`${KIND}.intended`, fresh.invocation_id, "act-other") as { event_id: string };    // an intent carrying the invocation id under another act key
  const before = await count(w);
  const asked0 = w.rr.asked.length;
  const no = { refused: "not-known" };
  expect(refused(await w.resolve(fresh.invocation_id, "no-such-event", outcome(), "act-3"))).toEqual(no);        // resolve 10
  expect(w.rr.asked.slice(asked0)).toEqual(["no-such-event"]);                                                  // resolve 11
  expect(refused(await w.resolve(fresh.invocation_id, other.intent_event_id, outcome(), "act-3"))).toEqual(no); // resolve 34: another act's intent
  expect(refused(await w.resolve("another-id", fresh.intent_event_id, outcome(), "act-3"))).toEqual(no);         // resolve 34: an invocation id the intent does not carry
  const closing = (await raw(w)).find((x) => x.action_ref === OUT)!;
  expect(refused(await w.resolve(fresh.invocation_id, closing.id, outcome(), "act-3"))).toEqual(no);            // resolve 34: a record that is no intent, of another invocation
  expect(refused(await w.resolve(fresh.invocation_id, notIntent.event_id, outcome(), "act-3"))).toEqual(no);     // resolve 34: a record of the pair that is no intent
  expect(refused(await w.resolve(fresh.invocation_id, otherKey.event_id, outcome(), "act-3"))).toEqual(no);      // resolve 34: an intent of the invocation under another act key
  w.rr.mode = "purged";
  expect(refused(await w.resolve(fresh.invocation_id, fresh.intent_event_id, outcome(), "act-3"))).toEqual({ refused: "invalid-request", cause: "purged" });   // resolve 12
  for (const mode of ["unavailable", "no-answer", "hang"] as const) {
    w.rr.mode = mode;
    const released = w.sec.released.length;
    expect(refused(await w.resolve(fresh.invocation_id, fresh.intent_event_id, outcome(), "act-3"))).toEqual({ refused: "recording-failure", position: "resolution" });   // never not-known
    expect(w.sec.released.length).toBe(released + 1);
  }
  w.rr.mode = "ok";
  expect(await count(w)).toBe(before);                                                                          // nothing appended by any refusal
});

test("resolve 14, 21, 22, 35, 13, Invariant 5.4: no closing standing: the outcome is written under the operator's credential with recovery, the resolving actor and the acting actor, no recovery_intended, and returned", async () => {
  const w = await resolveWorld();
  const r = await aged(w);
  const releasedBefore = w.sec.released.length;
  const id = done(await w.resolve(r.invocation_id, r.intent_event_id, outcome(7)));
  const recs = await raw(w);
  const closing = recs.find((x) => x.id === id)!;
  expect(closing.action_ref).toBe(OUT);
  expect(closing.actor_ref).toBe(w.op.ref);                                                                     // the operator's own credential
  expect(closing.data).toEqual({ invocation_id: r.invocation_id, kind: KIND, act_key: "act-1", intent_event_id: r.intent_event_id, data: { n: 7 }, recovery: true, resolving_actor: w.op.ref, acting_actor_ref: w.a.ref });
  expect(recs.some((x) => x.action_ref === `${KIND}.recovery_intended`)).toBe(false);
  expect(w.sec.released.length).toBe(releasedBefore + 1);                                                       // resolve 22: released after the write
  expect(w.sec.released.at(-1)).toBe(key());
  expect(await w.ri.openIntents(KIND, "act-1")).toEqual([]);                                                    // the intent is closed: open invocations drop it
  expect(refused(await w.open())).toMatchObject({ refused: "act-landed", outcome_event_id: id });              // act closings holds it
});

test("resolve 1, 21, 14: an abandoned and an escalated disposition write their own record, carrying the cause and the candidates", async () => {
  const w = await resolveWorld();
  const x = await aged(w, "act-1");
  const y = await aged(w, "act-2");
  const idA = done(await w.resolve(x.invocation_id, x.intent_event_id, abandoned("never ran")));
  const idE = done(await w.resolve(y.invocation_id, y.intent_event_id, escalated(["c1", "c2"]), "act-2"));
  const recs = await raw(w);
  const a = recs.find((r) => r.id === idA)!, e = recs.find((r) => r.id === idE)!;
  expect(a.action_ref).toBe(`${KIND}.abandoned`);
  expect(a.data).toMatchObject({ cause: "never ran", recovery: true, resolving_actor: w.op.ref, acting_actor_ref: w.a.ref });
  expect(a.data.supersedes).toBeUndefined();
  expect(e.action_ref).toBe(`${KIND}.escalated`);
  expect(e.data).toMatchObject({ database_candidates: ["c1", "c2"], recovery: true, resolving_actor: w.op.ref });
  expect(a.actor_ref).toBe(w.op.ref);
});

test("resolve 18, 19, 32, Invariant 5.8: an abandoned disposition for an in-flight intent is invalid-request(too-young), compared against now at the operator's seam; any other disposition may close it", async () => {
  const w = await resolveWorld();
  const r = await died(w);
  const before = await count(w);
  w.seam.advance(10_049);                                                                                       // completion bound 10 000 and the allowance 50: one millisecond short
  const released = w.sec.released.length;
  expect(refused(await w.resolve(r.invocation_id, r.intent_event_id, abandoned()))).toEqual({ refused: "invalid-request", cause: "too-young" });
  expect(w.sec.released.length).toBe(released + 1);
  expect(await count(w)).toBe(before);
  w.seam.advance(1);
  ok(await w.resolve(r.invocation_id, r.intent_event_id, abandoned()));                                         // no longer in flight
  const y = await died(w, "act-2");
  ok(await w.resolve(y.invocation_id, y.intent_event_id, outcome(), "act-2"));                                  // an outcome for an in-flight intent: allowed
  const z = await died(w, "act-3");
  ok(await w.resolve(z.invocation_id, z.intent_event_id, escalated(), "act-3"));
});

test("resolve 9: a refusal, or an outcome carrying no resolving actor, naming the invocation id is already-accounted(closing event id), nothing appended", async () => {
  const w = await resolveWorld();
  const swept = await aged(w, "act-1");
  w.probe.answer = { answer: "committed", outcome_action_ref: OUT, outcome_data: { n: 1 } };
  await run(w);
  const sweepOutcome = (await raw(w)).find((x) => x.action_ref === OUT)!;
  const refuse = ok(await w.ri.open(KIND, "act-2", w.a.ref, w.a.priv, { pairing: "p2" })) as Opened;
  const rf = ok(await w.ri.refuse(KIND, "act-2", refuse.invocation_id, refuse.intent_event_id, w.a.ref, w.a.priv, "no", "code")) as { refusal_event_id: string };
  const closed = ok(await w.ri.open(KIND, "act-3", w.a.ref, w.a.priv, { pairing: "p3" })) as Opened;
  const oc = ok(await w.ri.close(KIND, "act-3", closed.invocation_id, closed.intent_event_id, w.a.ref, w.a.priv, OUT, { n: 3 })) as { outcome_event_id: string };
  const before = await count(w);
  for (const d of [outcome(), abandoned(), escalated()]) {
    expect(refused(await w.resolve(swept.invocation_id, swept.intent_event_id, d))).toEqual({ refused: "already-accounted", closing_event_id: sweepOutcome.id });
    expect(refused(await w.resolve(refuse.invocation_id, refuse.intent_event_id, d, "act-2"))).toEqual({ refused: "already-accounted", closing_event_id: rf.refusal_event_id });
    expect(refused(await w.resolve(closed.invocation_id, closed.intent_event_id, d, "act-3"))).toEqual({ refused: "already-accounted", closing_event_id: oc.outcome_event_id });
  }
  expect(await count(w)).toBe(before);
});

test("resolve 15, 13: an escalation standing: any disposition, naming it in supersedes", async () => {
  const w = await resolveWorld();
  const ids: string[] = [];
  const dispositions = [outcome(), abandoned(), escalated(["c9"])];
  for (const [i, d] of dispositions.entries()) {
    const act = `act-${i}`;
    const r = await aged(w, act);
    w.probe.answer = { answer: "not-committed" };
    await run(w);                                                                                               // the sweep escalates every aged act it has not closed
    const esc = (await raw(w)).find((x) => x.action_ref === `${KIND}.escalated` && x.data.invocation_id === r.invocation_id)!;
    const id = done(await w.resolve(r.invocation_id, r.intent_event_id, d, act));
    const written = (await raw(w)).find((x) => x.id === id)!;
    expect(written.data.supersedes).toBe(esc.id);
    ids.push(id);
  }
  expect(new Set(ids).size).toBe(3);
});

test("resolve 16, 13, 27: an abandonment standing: an outcome supersedes it; any other disposition is invalid-request(already-abandoned)", async () => {
  const w = await resolveWorld();
  const r = await aged(w);
  const ab = done(await w.resolve(r.invocation_id, r.intent_event_id, abandoned()));
  const before = await count(w);
  expect(refused(await w.resolve(r.invocation_id, r.intent_event_id, abandoned("again")))).toEqual({ refused: "invalid-request", cause: "already-abandoned" });
  expect(refused(await w.resolve(r.invocation_id, r.intent_event_id, escalated()))).toEqual({ refused: "invalid-request", cause: "already-abandoned" });
  expect(await count(w)).toBe(before);
  const id = done(await w.resolve(r.invocation_id, r.intent_event_id, outcome()));
  expect((await raw(w)).find((x) => x.id === id)!.data.supersedes).toBe(ab);
});

test("resolve 36, 13: an outcome an operator wrote standing: an outcome supersedes it; any other disposition is already-accounted(the standing closing)", async () => {
  const w = await resolveWorld();
  const r = await aged(w);
  const first = done(await w.resolve(r.invocation_id, r.intent_event_id, outcome(1)));
  const second = done(await w.resolve(r.invocation_id, r.intent_event_id, outcome(2)));                         // the same reference again: a correction
  const recs = await raw(w);
  expect(recs.find((x) => x.id === second)!.data).toMatchObject({ supersedes: first, data: { n: 2 } });
  const before = recs.length;
  expect(refused(await w.resolve(r.invocation_id, r.intent_event_id, abandoned()))).toEqual({ refused: "already-accounted", closing_event_id: second });   // the one that stands now
  expect(refused(await w.resolve(r.invocation_id, r.intent_event_id, escalated()))).toEqual({ refused: "already-accounted", closing_event_id: second });
  expect(await count(w)).toBe(before);
});

test("resolve 2, 3: a credential the substrate refuses is invalid-credential with the section released and nothing appended", async () => {
  const w = await resolveWorld();
  const r = await aged(w);
  const before = await count(w);
  const released = w.sec.released.length;
  expect(refused(await w.ri.resolve(KIND, "act-1", r.invocation_id, r.intent_event_id, w.op.ref, w.stranger.priv, outcome()))).toEqual({ refused: "invalid-credential" });
  expect(w.sec.released.length).toBe(released + 1);
  expect(await count(w)).toBe(before);
});

test("resolve 22 to 26, 29, Primitive policy 36, 37b: the closing write's arms at the resolution position", async () => {
  const w = await resolveWorld();
  const rf = { refused: "recording-failure", position: "resolution" };
  const x = await aged(w);
  const before = await count(w);
  const calls = () => w.calls.length;
  // resolve 26: recording-failure(step-2) lands recording-failure(resolution), and is not retried.
  let c = calls();
  w.script.push("rf2");
  expect(refused(await w.resolve(x.invocation_id, x.intent_event_id, outcome()))).toEqual(rf);
  expect(calls() - c).toBe(1);
  // resolve 26: recording-failure(step-3) with nothing found, and a lost reply with nothing found.
  for (const m of ["rf3-nothing", "lost-nothing"] as const) { w.script.push(m); expect(refused(await w.resolve(x.invocation_id, x.intent_event_id, outcome()))).toEqual(rf); }
  // Primitive policy 45: state-unavailable reads as recording-failure(step-2).
  w.script.push("unavailable");
  expect(refused(await w.resolve(x.invocation_id, x.intent_event_id, outcome()))).toEqual(rf);
  // resolve 29: invalid-request(step-1) lands recording-failure(resolution) with a hard alert; resolve 25: no retry.
  c = calls(); w.alerts.length = 0;
  w.script.push("step1");
  expect(refused(await w.resolve(x.invocation_id, x.intent_event_id, outcome()))).toEqual(rf);
  expect(calls() - c).toBe(1);
  expect(w.alerts.map((a) => a.invocation_id)).toEqual([x.invocation_id]);
  // resolve 25, Primitive policy 37b: invalid-request(step-4) whose read-back finds nothing.
  c = calls();
  w.script.push("step4-nothing");
  expect(refused(await w.resolve(x.invocation_id, x.intent_event_id, outcome()))).toEqual(rf);
  expect(calls() - c).toBe(1);
  expect(await count(w)).toBe(before);
  // resolve 24: invalid-request(step-4) whose read-back finds the record is success with a hard alert.
  w.alerts.length = 0;
  w.script.push("step4-landed");
  const id = done(await w.resolve(x.invocation_id, x.intent_event_id, outcome(1)));
  expect(w.alerts).toHaveLength(1);
  expect((await raw(w)).find((r) => r.id === id)).toBeDefined();
  // Primitive policy 36, resolve 35: a lost reply or a step-3 whose read-back finds the record is adopted, the closing event id returned, no alert.
  for (const m of ["lost-landed", "rf3-landed"] as const) {
    w.alerts.length = 0;
    w.script.push(m);
    const prior = (await raw(w)).filter((r) => r.action_ref === OUT).at(-1)!;
    const adopted = done(await w.resolve(x.invocation_id, x.intent_event_id, outcome(2)));
    const rec = (await raw(w)).find((r) => r.id === adopted)!;
    expect(rec.data.supersedes).toBe(prior.id);                                                                 // the record this write landed, not the earlier one of the same reference
    expect(w.alerts).toHaveLength(0);
  }
});

test("Primitive policy 36 at [Resolve]: a lost reply whose read-back finds nothing does not adopt an earlier closing of the same reference", async () => {
  const w = await resolveWorld();
  const x = await aged(w);
  const first = done(await w.resolve(x.invocation_id, x.intent_event_id, outcome(1)));
  w.script.push("lost-nothing");
  expect(refused(await w.resolve(x.invocation_id, x.intent_event_id, outcome(2)))).toEqual({ refused: "recording-failure", position: "resolution" });
  expect((await raw(w)).filter((r) => r.action_ref === OUT).map((r) => r.id)).toEqual([first]);
});

test("resolve 8, 9: a closing another writer landed since the instance last read is found by the re-read under the section: already-accounted, nothing appended", async () => {
  const w = await resolveWorld();
  const x = await aged(w);
  const landed = await w.closing(OUT, x.invocation_id, "act-1", { intent_event_id: x.intent_event_id, recovery: true }) as { event_id: string };
  const before = await count(w);
  expect(refused(await w.resolve(x.invocation_id, x.intent_event_id, outcome()))).toEqual({ refused: "already-accounted", closing_event_id: landed.event_id });
  expect(await count(w)).toBe(before);
});

test("Which closing stands 2 to 7, Reconcile step 2.5: a closing an operator wrote is the act's; the sweep finds it and examines nothing", async () => {
  const w = await resolveWorld();
  const x = await aged(w);
  w.probe.answer = { answer: "not-committed" };
  await run(w);                                                                                                 // the sweep escalates it
  const id = done(await w.resolve(x.invocation_id, x.intent_event_id, outcome()));
  w.probe.asked.length = 0;
  const t = await run(w);
  expect(t).toMatchObject({ examined: 0 });
  expect(w.probe.asked).toHaveLength(0);
  expect(report(await w.ri.readInvocation(KIND, "act-1", x.invocation_id)).invocations[0]).toMatchObject({ state: "closed", records: expect.arrayContaining([expect.objectContaining({ event_id: id })]) });
});

test("read invocation 17: a kind the bindings table does not serve answers not-known with no read", async () => {
  const w = await resolveWorld();
  w.reads.mode = "unavailable";
  expect(await w.ri.readInvocation("nokind", "act-1")).toEqual({ refused: "not-known" });
});

test("read invocation 11, Action wiring 3, Capability requirement 13: a range read that fails answers journal-unavailable, never not-known; an invalid-query lands there too, surfaced", async () => {
  const w = await resolveWorld();
  await died(w);
  for (const mode of ["unavailable", "invalid-query"] as const) {
    w.reads.mode = mode;
    expect(await w.ri.readInvocation(KIND, "act-1")).toEqual({ refused: "journal-unavailable" });
    expect(await w.ri.readInvocation(KIND, "no-act")).toEqual({ refused: "journal-unavailable" });
  }
  expect(w.surfaced.some((s) => s.arm === "invalid-query")).toBe(true);
  w.reads.mode = "ok";
  expect(Array.isArray(report(await w.ri.readInvocation(KIND, "act-1")).invocations)).toBe(true);
});

test("read invocation 12, 3b: an act key with no readable intent, and an invocation id no readable intent of the act key carries, answer not-known", async () => {
  const w = await resolveWorld();
  const r = await died(w, "act-1");
  const other = await died(w, "act-2");
  expect(await w.ri.readInvocation(KIND, "act-9")).toEqual({ refused: "not-known" });
  expect(await w.ri.readInvocation(KIND, "act-9", r.invocation_id)).toEqual({ refused: "not-known" });
  expect(await w.ri.readInvocation(KIND, "act-1", "no-such-invocation")).toEqual({ refused: "not-known" });
  expect(await w.ri.readInvocation(KIND, "act-1", other.invocation_id)).toEqual({ refused: "not-known" });       // another act's invocation
  w.seam.advance(365 * 86_400_000 - 50);                                                                        // retention end: the period less the allowance
  expect(await w.ri.readInvocation(KIND, "act-1")).toEqual({ refused: "not-known" });                          // sequence high water 5: the intent is no longer readable
});

test("read invocation 2, 3, 4, 16, 10: the act's invocations earliest first by the sequence numbers of their intents, each entry its state and its records earliest first", async () => {
  const w = await resolveWorld({ repeatable: true });
  const open = async () => ok(await w.ri.open(KIND, "act-1", w.a.ref, w.a.priv, { pairing: "p" })) as Opened;
  const one = await open();
  ok(await w.ri.close(KIND, "act-1", one.invocation_id, one.intent_event_id, w.a.ref, w.a.priv, OUT, { n: 1 }));
  const two = await open();
  ok(await w.ri.refuse(KIND, "act-1", two.invocation_id, two.intent_event_id, w.a.ref, w.a.priv, "no", "code"));
  const three = await open();
  await w.ri.yieldSection(KIND, "act-1", three.invocation_id, "answered");
  const all = report(await w.ri.readInvocation(KIND, "act-1"));                                                 // blank: read invocation 2
  expect(all.invocations.map((e) => e.invocation_id)).toEqual([one.invocation_id, two.invocation_id, three.invocation_id]);
  expect(states(all)).toEqual(["closed", "refused", "open"]);
  expect(all.more).toBe(false);
  const e1 = all.invocations[0];
  expect(e1.records.map((r) => r.action_ref)).toEqual([`${KIND}.intended`, OUT]);                               // read invocation 4
  expect(e1.records.map((r) => r.sequence_number)).toEqual([...e1.records.map((r) => r.sequence_number)].sort((p, q) => p - q));
  expect(e1.records[0].event_id).toBe(one.intent_event_id);
  expect(all.invocations[1].records.map((r) => r.action_ref)).toEqual([`${KIND}.intended`, `${KIND}.refused`]);
  expect(all.invocations[2].records.map((r) => r.action_ref)).toEqual([`${KIND}.intended`]);
  expect(report(await w.ri.readInvocation(KIND, "act-1", "  ")).invocations).toHaveLength(3);                    // a blank invocation id is no id (read invocation 2)
  const single = report(await w.ri.readInvocation(KIND, "act-1", two.invocation_id));                           // read invocation 3a
  expect(single.invocations.map((e) => e.invocation_id)).toEqual([two.invocation_id]);
  expect(single.invocations[0].state).toBe("refused");
});

test("read invocation 10, Which closing stands, Term state projection: open, closed, refused, abandoned, escalated and resolved", async () => {
  const w = await resolveWorld();
  const acts = ["open", "closed", "refused", "abandoned", "escalated", "resolved"];
  const made: Record<string, Opened> = {};
  for (const a of acts) made[a] = await died(w, a);
  age(w);
  const as = (a: string) => made[a];
  await w.closing(OUT, as("closed").invocation_id, "closed", { intent_event_id: as("closed").intent_event_id });                        // another writer's outcome, no resolving actor
  await w.closing(`${KIND}.refused`, as("refused").invocation_id, "refused", { intent_event_id: as("refused").intent_event_id });
  await w.closing(`${KIND}.abandoned`, as("abandoned").invocation_id, "abandoned", { intent_event_id: as("abandoned").intent_event_id });   // no resolving actor: abandoned
  await w.closing(`${KIND}.escalated`, as("escalated").invocation_id, "escalated", { intent_event_id: as("escalated").intent_event_id });
  ok(await w.resolve(as("resolved").invocation_id, as("resolved").intent_event_id, abandoned(), "resolved"));  // an operator's abandonment: resolved
  for (const a of acts) {
    const e = report(await w.ri.readInvocation(KIND, a)).invocations[0] as InvocationEntry;
    expect(e.state).toBe(a);
  }
});

test("read invocation 6, 4: a superseded closing is not excluded from records; the entry's state is the standing closing's", async () => {
  const w = await resolveWorld();
  const x = await aged(w);
  w.probe.answer = { answer: "not-committed" };
  await run(w);
  const out = done(await w.resolve(x.invocation_id, x.intent_event_id, outcome()));
  const e = report(await w.ri.readInvocation(KIND, "act-1", x.invocation_id)).invocations[0];
  expect(e.records.map((r) => r.action_ref)).toEqual([`${KIND}.intended`, `${KIND}.escalated`, OUT]);           // the escalation the outcome supersedes stays
  expect(e.records.at(-1)!.event_id).toBe(out);
  expect(e.state).toBe("closed");
});

test("read invocation 4: the recovery_intended records are carried beside the intent and the closing", async () => {
  const w = await resolveWorld();
  const x = await aged(w);
  w.probe.answer = { answer: "committed", outcome_action_ref: OUT, outcome_data: { n: 1 } };
  await run(w);
  const e = report(await w.ri.readInvocation(KIND, "act-1", x.invocation_id)).invocations[0];
  expect(e.records.map((r) => r.action_ref)).toEqual([`${KIND}.intended`, `${KIND}.recovery_intended`, OUT]);
});

test("read invocation 2, 5, 16, Term read cap: at most read cap invocations, the most recent, earliest first, more set; the records of an invocation capped likewise", async () => {
  const w = await resolveWorld({ repeatable: true, readCap: 2 });
  const open = async () => ok(await w.ri.open(KIND, "act-1", w.a.ref, w.a.priv, {})) as Opened;
  const made: Opened[] = [];
  for (let i = 0; i < 3; i++) { const r = await open(); made.push(r); ok(await w.ri.close(KIND, "act-1", r.invocation_id, r.intent_event_id, w.a.ref, w.a.priv, OUT, { n: i })); }
  const all = report(await w.ri.readInvocation(KIND, "act-1"));
  expect(all.invocations.map((e) => e.invocation_id)).toEqual([made[1].invocation_id, made[2].invocation_id]);   // the two most recent, earliest first
  expect(all.more).toBe(true);
  const one = report(await w.ri.readInvocation(KIND, "act-1", made[2].invocation_id));
  expect(one.more).toBe(false);                                                                                 // a single read has no older invocations to leave out
  // records: an escalation and two outcomes on one invocation, a read cap of two keeps the last two closings.
  const w2 = await resolveWorld({ readCap: 2 });
  const x = await aged(w2);
  w2.probe.answer = { answer: "not-committed" };
  await run(w2);
  const first = done(await w2.resolve(x.invocation_id, x.intent_event_id, outcome(1)));
  const second = done(await w2.resolve(x.invocation_id, x.intent_event_id, outcome(2)));
  const e = report(await w2.ri.readInvocation(KIND, "act-1", x.invocation_id)).invocations[0];
  expect(e.records.map((r) => r.event_id)).toEqual([x.intent_event_id, first, second]);                          // the intent, and the most recent two closings
  expect(e.more).toBe(true);
  const w3 = await resolveWorld({ readCap: 5 });
  const y = await aged(w3);
  expect(report(await w3.ri.readInvocation(KIND, "act-1", y.invocation_id)).invocations[0].more).toBe(false);
});

test("read invocation 13, 14, 1: it takes no critical section and writes nothing, and it reads another writer's record through the rebuild", async () => {
  const w = await resolveWorld();
  const x = await aged(w);
  const taken = w.sec.taken.length, calls = w.calls.length, before = await count(w);
  await w.closing(`${KIND}.abandoned`, x.invocation_id, "act-1", { intent_event_id: x.intent_event_id });
  const e = report(await w.ri.readInvocation(KIND, "act-1")).invocations[0];
  expect(e.state).toBe("abandoned");                                                                            // the rebuild read the record written behind the instance's back
  expect(w.sec.taken.length).toBe(taken);
  expect(w.calls.length).toBe(calls);
  expect(await count(w)).toBe(before + 1);                                                                      // the one record the test wrote
});
