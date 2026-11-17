// Recoverable Invocation's [Reconcile], the sweep, and the findings register: one test for each rule the render answers.
import { test, expect, afterAll } from "bun:test";
import { Store } from "../src/store.ts";
import { type LoggedEvent } from "../src/event_log.ts";
import { RecoverableInvocation, FindingsRegister, type Tally } from "../src/recoverable_invocation.ts";
import { worldFor, ok, key, KIND, OUT, DAY } from "./ri_world.ts";

const store = new Store();
afterAll(() => store.close());
const world = worldFor(store);
const sweepWorld = (o: Parameters<typeof world>[0] = {}) => world({ sweep: true, ...o });
type W = Awaited<ReturnType<typeof sweepWorld>>;
type Opened = { invocation_id: string; intent_event_id: string };

/** An invocation that opened and was never closed: its section yielded, the intent left open for the sweep. */
const died = async (w: W, act = "act-1", kind = KIND): Promise<Opened> => {
  const r = ok(await w.ri.open(kind, act, w.a.ref, w.a.priv, { pairing: `p-${act}` })) as Opened;
  await w.ri.yieldSection(kind, act, r.invocation_id, "answered");
  return r;
};
const age = (w: W, ms = 11_000) => w.seam.advance(ms);                                                      // past the examine edge: completion bound 10 000 and the allowance 50
const refs = async (w: W) => (await w.records()).map((r) => r.action_ref);
const raw = async (w: W) => ((await w.log.read({ sequence: { from: 1 } })) as LoggedEvent[]).map((e) => e.data as unknown as { action_ref: string; actor_ref: string; data: Record<string, unknown> });
const run = async (w: W) => (await w.ri.reconcile()) as Tally;
const partition = (t: Tally) => expect(t.examined).toBe(t.closed + t.escalated + t.reported + t.skipped + t.closed_already);   // Term partition
const COMMITTED = { answer: "committed" as const, outcome_action_ref: OUT, outcome_data: { n: 1 } };
/** Run a hook at the nth refresh of the instance (1 is the step-1 rebuild, 2 the step-2 re-read of the first act). */
const atRefresh = (w: W, n: number, hook: () => Promise<void> | void) => {
  let reads = 0;
  const inst = w.ri as unknown as { refresh: (...a: unknown[]) => Promise<void> };
  const orig = inst.refresh.bind(w.ri);
  inst.refresh = async (...args: unknown[]) => { if (++reads === n) await hook(); return orig(...args); };
};

test("Instance start 2 to 8: every condition is checked for every bound kind, and an instance one of them fails does not start", async () => {
  const w = await sweepWorld();
  expect(RecoverableInvocation.startConditions(w.cfg)).toEqual([]);
  const bad = (sweep: object, b: object = {}) => RecoverableInvocation.startConditions({ ...w.cfg, sweep: { ...w.cfg.sweep!, ...sweep }, bindings: { [KIND]: { ...w.binding, ...b } } });
  expect(bad({ closureWindowMs: 130_100 })).toEqual([expect.stringMatching(/Instance start 4/)]);              // worst closure 10 000 + 100 + 60 000 + 60 000: an equal window does not exceed it
  expect(bad({}, { retentionPeriodMs: 330_050 })).toEqual([expect.stringMatching(/Instance start 5/)]);          // retention floor 210 050 + 100 000 + 20 000
  expect(bad({}, { invocationCompletionBoundMs: 5900 })).toEqual([expect.stringMatching(/Instance start 6/)]);   // lease spend 1000 + 2000 + 2000 + 900
  expect(bad({ runBoundMs: 14_999 })).toEqual([expect.stringMatching(/Instance start 7/)]);                      // run floor 10 000 + 5000
  expect(bad({ closureLatencyMs: 3700 })).toEqual([expect.stringMatching(/Instance start 8/)]);                  // sweep lease spend 3700
  expect(bad({}, { settlingPeriodMs: undefined })).toEqual([expect.stringMatching(/settling period/)]);
  expect(RecoverableInvocation.startConditions({ ...w.cfg, readBoundMs: undefined })).toHaveLength(1);           // no read bound, no conditions to read
  await expect(RecoverableInvocation.start(w.seam, { ...w.cfg, sweep: { ...w.cfg.sweep!, closureWindowMs: 1 } })).rejects.toThrow(/does not start.*Instance start 4/);   // Instance start 3
  const none = await world();
  expect(() => none.ri.reconcile()).toThrow(/runs no sweep/);
});

test("Reconcile step 1.2, 1.3, Term aged, in-flight, Invariant 7.1: an in-flight intent is not examined; once aged it is", async () => {
  const w = await sweepWorld();
  w.probe.answer = COMMITTED;
  await died(w);
  w.seam.advance(5000);
  expect(await run(w)).toMatchObject({ examined: 0, closed: 0 });
  expect(w.probe.asked).toHaveLength(0);
  age(w, 6000);                                                                                               // 11 000 past the recording instant
  expect(await run(w)).toMatchObject({ examined: 1, closed: 1 });
});

test("Reconcile step 2.1, 3.1, 3.2a to 3.2c, Invariant 5.1 to 5.3, Primitive policy 4, 11: a committed act is closed by a recovery_intended and then the outcome, under the service identity, carrying only what the probe re-derived and the original caller as acting actor", async () => {
  const w = await sweepWorld();
  w.probe.answer = COMMITTED;
  const d = await died(w);
  age(w);
  const t = await run(w);
  expect(t).toEqual({ examined: 1, closed: 1, escalated: 0, reported: 0, skipped: 0, closed_already: 0, surfaced: 0, unreached: 0 });
  partition(t);
  expect(await refs(w)).toEqual(["disclosure.intended", "disclosure.recovery_intended", OUT]);                  // the plan before the outcome (Invariant 5.1)
  const [intent, plan, out] = await raw(w);
  expect(plan.actor_ref).toBe(w.svc.ref);                                                                     // Invariant 5.2: the service identity's attestation
  expect(out.actor_ref).toBe(w.svc.ref);
  expect(plan.data).toEqual({ invocation_id: d.invocation_id, intent_event_id: d.intent_event_id, kind: KIND, act_key: "act-1", plan: "outcome" });
  expect(out.data).toEqual({ invocation_id: d.invocation_id, kind: KIND, act_key: "act-1", intent_event_id: d.intent_event_id, data: { n: 1 }, recovery: true, acting_actor_ref: w.a.ref });   // the recovered outcome payload
  expect(w.probe.asked).toEqual([{ act_key: "act-1", payload: intent.data }]);                                // reconcile step 3.1: act key and the intent payload
  expect(await w.ri.openIntents(KIND, "act-1")).toEqual([]);                                                  // reconcile step 4.1
  expect(w.sec.released).toHaveLength(2);                                                                     // the invocation's yield and the run's release (step 4.4)
  expect(await w.realLease.tryTake(key(), "someone-else", 1000)).toMatchObject({ taken: expect.any(String) });
  expect(await run(w)).toMatchObject({ examined: 0 });                                                        // the act is closed: nothing left to keep
  expect(w.ri.register.acts).toEqual([]);
  expect(w.ri.register.instances).toEqual([]);
});

test("Reconcile step 3.5, 3.7, 3.21, 3.26, Invariant 4.8: an act the database does not show is escalated as not-observed, counted in escalated, surfaced as the act finding escalated, and never re-run", async () => {
  const w = await sweepWorld();
  w.probe.answer = { answer: "not-committed" };
  const d = await died(w);
  age(w);
  const t = await run(w);
  expect(t).toMatchObject({ examined: 1, escalated: 1, closed: 0 });
  partition(t);
  expect(await refs(w)).toEqual(["disclosure.intended", "disclosure.escalated"]);
  expect((await raw(w))[1].data).toEqual({ invocation_id: d.invocation_id, intent_event_id: d.intent_event_id, kind: KIND, act_key: "act-1", cause: "not-observed" });
  expect(w.ri.register.acts).toMatchObject([{ finding: "escalated", kind: KIND, act_key: "act-1", invocation_id: d.invocation_id }]);
  expect(await run(w)).toMatchObject({ examined: 0 });
  expect(w.probe.asked).toHaveLength(1);
});

test("Reconcile step 3.8 to 3.12, Invariant 3.5, 5.9: an undecidable act is escalated naming the candidates, never choosing among them and never writing an outcome; past intent candidates cap the record carries the count and the range", async () => {
  const w = await sweepWorld();
  w.probe.answer = { answer: "undecidable", candidates: ["r-1", "r-2"] };
  await died(w, "act-1");
  age(w);
  expect(await run(w)).toMatchObject({ escalated: 1 });
  const [, e1] = await raw(w);
  expect(e1.action_ref).toBe("disclosure.escalated");
  expect(e1.data).toMatchObject({ cause: "undecidable", database_candidates: ["r-1", "r-2"] });
  expect(e1.data).not.toHaveProperty("candidates_count");
  w.probe.answer = { answer: "undecidable", candidates: ["a", "b", "c", "d", "e", "f", "g"] };                 // cap 5
  await died(w, "act-2");
  age(w);
  expect(await run(w)).toMatchObject({ escalated: 1 });
  const last = (await raw(w)).at(-1)!;
  expect(last.data).toMatchObject({ cause: "undecidable", database_candidates: ["a", "b", "c", "d", "e"], candidates_count: 7, candidates_range: { first: "a", last: "g" } });
  expect((await refs(w)).filter((r) => r === OUT)).toEqual([]);
});

test("Reconcile step 3.13, findings 9 to 12, Term condition read: an act probe that answers unavailable writes nothing, releases and counts the act skipped, and opens store-unavailable for the kind; a later run advances it, one that reads the database closes it, and one that reads nothing leaves it", async () => {
  const w = await sweepWorld();
  w.probe.answer = { answer: "unavailable" };
  const d = await died(w);
  age(w);
  const t = await run(w);
  expect(t).toMatchObject({ examined: 1, skipped: 1 });
  partition(t);
  expect(await refs(w)).toEqual(["disclosure.intended"]);
  expect(w.sec.released).toHaveLength(2);
  const first = structuredClone(w.ri.register.standing("store-unavailable", KIND)!);                          // the register advances its record in place
  expect(first.first_seen).toEqual(first.last_seen);
  w.seam.advance(1000);
  await run(w);
  const advanced = w.ri.register.standing("store-unavailable", KIND)!;
  expect(w.ri.register.instances).toHaveLength(1);                                                            // findings 12: one record per standing condition
  expect(advanced.first_seen).toEqual(first.first_seen);                                                      // findings 8: first seen never moves
  expect(advanced.last_seen.at).not.toBe(first.last_seen.at);                                                 // findings 9
  w.probe.answer = "throw";                                                                                   // act probe 4: a rejection reads as unavailable
  expect(await run(w)).toMatchObject({ skipped: 1 });
  await w.closing(OUT, d.invocation_id, "act-1", { intent_event_id: d.intent_event_id });                     // another writer closes the act: the next run reads no database
  expect(await run(w)).toMatchObject({ examined: 0 });
  expect(w.ri.register.standing("store-unavailable", KIND)).not.toBeNull();                                   // findings 10b: no condition read, no close
  w.probe.answer = { answer: "not-committed" };
  await died(w, "act-2");
  age(w);
  await run(w);
  expect(w.ri.register.standing("store-unavailable", KIND)).toBeNull();                                       // findings 10a: the probe answered, the condition does not stand
  expect(w.ri.register.instances.map((f) => f.closed)).toEqual([true]);
  w.probe.answer = { answer: "unavailable" };
  await died(w, "act-3");
  age(w);
  await run(w);
  expect(w.ri.register.instances).toHaveLength(2);                                                            // findings 11: a recurrence is a new record
});

test("Reconcile step 2.4 to 2.6, sweep closed ids 1: a closing another writer lands between step 1 and the re-read under the section is found, nothing is written, the act is counted closed already and the section released", async () => {
  const w = await sweepWorld();
  w.probe.answer = COMMITTED;
  const d = await died(w);
  age(w);
  atRefresh(w, 2, async () => { await w.closing(OUT, d.invocation_id, "act-1", { intent_event_id: d.intent_event_id }); });
  const t = await run(w);
  expect(t).toMatchObject({ examined: 1, closed_already: 1, closed: 0 });
  partition(t);
  expect(w.probe.asked).toHaveLength(0);
  expect(await refs(w)).toEqual(["disclosure.intended", OUT]);
  expect(w.sec.released).toHaveLength(2);
});

test("Reconcile step 2.3, reconcile 9: a take that does not give the section, whether it answers unavailable or fails, counts the act skipped with nothing written; a release that fails after a closing counts it skipped too, and the next run finds the closing", async () => {
  const w = await sweepWorld();
  w.probe.answer = COMMITTED;
  await died(w);
  age(w);
  w.sec.takeUnavailable = true;
  expect(await run(w)).toMatchObject({ examined: 1, skipped: 1 });
  w.sec.takeUnavailable = false; w.sec.takeThrows = true;
  expect(await run(w)).toMatchObject({ examined: 1, skipped: 1 });
  expect(await refs(w)).toEqual(["disclosure.intended"]);
  w.sec.takeThrows = false; w.sec.releaseThrows = true;
  const t = await run(w);
  expect(t).toMatchObject({ examined: 1, skipped: 1, closed: 0 });                                            // reconcile 9; the closing stands (the render's release is no part of the journal's transaction)
  partition(t);
  expect(await refs(w)).toEqual(["disclosure.intended", "disclosure.recovery_intended", OUT]);
  w.sec.releaseThrows = false;
  expect(await run(w)).toMatchObject({ examined: 0 });
});

test("Reconcile step 2.7, 2.11, journal write bound 1: a remaining at or below write floor after the re-read counts the act skipped, releases, and the act probe is not called", async () => {
  const w = await sweepWorld();
  w.probe.answer = COMMITTED;
  await died(w);
  age(w);
  w.sec.remaining = () => 1300;                                                                               // write floor is 1000 + 3 * 100
  expect(await run(w)).toMatchObject({ examined: 1, skipped: 1 });
  expect(w.probe.asked).toHaveLength(0);
  expect(await refs(w)).toEqual(["disclosure.intended"]);
  expect(w.sec.released).toHaveLength(2);
});

test("Reconcile step 2.10, Capability requirement 13, 14: a re-read under the section that fails writes nothing, releases, counts the act skipped and opens journal-unavailable; an invalid-query is surfaced and opens no outage finding", async () => {
  const w = await sweepWorld();
  w.probe.answer = COMMITTED;
  await died(w);
  age(w);
  atRefresh(w, 2, () => { w.reads.mode = "unavailable"; });
  expect(await run(w)).toMatchObject({ examined: 1, skipped: 1 });
  expect(await refs(w)).toEqual(["disclosure.intended"]);
  expect(w.probe.asked).toHaveLength(0);
  expect(w.sec.released).toHaveLength(2);
  expect(w.ri.register.standing("journal-unavailable", null)).not.toBeNull();
  const v = await sweepWorld();
  v.probe.answer = COMMITTED;
  await died(v);
  age(v);
  atRefresh(v, 2, () => { v.reads.mode = "invalid-query"; });
  expect(await run(v)).toMatchObject({ examined: 1, skipped: 1 });
  expect(v.surfaced.map((s) => s.arm)).toContain("invalid-query");
  expect(v.ri.register.instances).toEqual([]);
});

test("Reconcile 1, 1a to 1c, run bound 2, Capability requirement 13, 14: an enumeration that fails writes nothing and returns journal-unavailable, opening or advancing the outage finding, which a run that enumerates closes; an invalid-query opens none; a stalled read ends the run with no answer", async () => {
  const w = await sweepWorld();
  w.probe.answer = COMMITTED;
  await died(w);
  age(w);
  w.reads.mode = "unavailable";
  expect(await w.ri.reconcile()).toEqual({ refused: "journal-unavailable" });
  const f = structuredClone(w.ri.register.standing("journal-unavailable", null)!);
  expect(f.kind).toBeNull();                                                                                  // findings 5: an instance finding may omit kind
  w.seam.advance(500);
  expect(await w.ri.reconcile()).toEqual({ refused: "journal-unavailable" });
  expect(w.ri.register.instances).toHaveLength(1);
  expect(w.ri.register.standing("journal-unavailable", null)!.last_seen.at).not.toBe(f.last_seen.at);
  expect(await refs(w)).toEqual(["disclosure.intended"]);
  expect(w.sec.taken).toHaveLength(1);                                                                        // the invocation's own take: the run took none
  w.reads.mode = "invalid-query";
  expect(await w.ri.reconcile()).toEqual({ refused: "journal-unavailable" });
  expect(w.surfaced.map((s) => s.arm)).toContain("invalid-query");
  w.reads.mode = "hang";
  expect(await w.ri.reconcile()).toBe("no-answer");
  expect(await refs(w)).toEqual(["disclosure.intended"]);
  w.reads.mode = "ok";
  expect(await run(w)).toMatchObject({ closed: 1 });
  expect(w.ri.register.standing("journal-unavailable", null)).toBeNull();                                     // findings 10a
});

test("Reconcile step 1.6, 1.7, Binding 4 to 6: an intent of a kind the bindings table does not serve is surfaced once per run and counted in surfaced, never closed, until a record of its kind names it; the pass is bounded by the longest retention period", async () => {
  const w = await sweepWorld();
  const ghost = (ref: string, inv: string) => w.at.recordAction(ref, w.a.ref, w.a.priv, { invocation_id: inv, kind: "ghost", act_key: "k1" });
  await ghost("ghost.intended", "g1");
  await ghost("ghost.intended", "g2");
  await ghost("ghost.recovery_intended", "g2");                                                               // Binding 4: the intent's own recovery_intended names nothing
  await ghost("ghost.intended", "g3");
  await ghost("ghost.refused", "g3");                                                                         // a `<kind>.*` record that names the id
  age(w);
  const t = await run(w);
  expect(t).toMatchObject({ surfaced: 2, examined: 0 });                                                      // g1 and g2
  expect(w.surfaced.filter((s) => s.arm === "unbound-kind").map((s) => s.invocation_id).sort()).toEqual(["g1", "g2"]);
  expect(w.ri.register.acts.map((a) => a.invocation_id).sort()).toEqual(["g1", "g2"]);
  expect(w.ri.register.acts.every((a) => a.finding === "unbound-kind")).toBe(true);
  expect(await refs(w)).toHaveLength(5);                                                                      // Binding 5: nothing written
  expect(await run(w)).toMatchObject({ surfaced: 2 });                                                        // once per run
  w.seam.advance(366 * DAY);
  expect(await run(w)).toMatchObject({ surfaced: 0 });                                                        // Binding 6
});

test("Reconcile 2, 2a to 2f, service identity 1a, 1b: under none the run takes the section, probes, writes nothing, releases, reports the result and counts the act reported; an unavailable probe counts it skipped", async () => {
  const w = await sweepWorld({ service: null });
  w.probe.answer = COMMITTED;
  const d = await died(w);
  age(w);
  const t = await run(w);
  expect(t).toMatchObject({ examined: 1, reported: 1, closed: 0 });
  partition(t);
  expect(await refs(w)).toEqual(["disclosure.intended"]);                                                     // 2d
  expect(w.surfaced).toContainEqual({ arm: "aged-open-intent", kind: KIND, act_key: "act-1", invocation_id: d.invocation_id });   // service identity 1b
  expect(w.surfaced).toContainEqual({ arm: "reported", kind: KIND, act_key: "act-1", invocation_id: d.invocation_id, detail: COMMITTED });   // 2e
  expect(w.sec.taken).toHaveLength(2);                                                                        // 2a
  expect(w.sec.released).toHaveLength(2);                                                                     // 2c
  expect(await w.ri.openIntents(KIND, "act-1")).toHaveLength(1);                                              // the intent stays open for an operator
  w.probe.answer = { answer: "unavailable" };
  const u = await run(w);
  expect(u).toMatchObject({ examined: 1, skipped: 1, reported: 0 });                                          // 2f
  expect(w.ri.register.standing("store-unavailable", KIND)).not.toBeNull();                                   // the closure table's row (open line 2026-11-07-d)
});

test("Reconcile 3 to 5, Term partition: a mixed instance closes the kinds that declare a service identity, reports the kinds that declare none, and sums the counts", async () => {
  const w = await sweepWorld({ second: true });
  w.probe.answer = COMMITTED;
  await died(w, "act-1");
  await died(w, "act-9", "refund");
  age(w);
  const t = await run(w);
  expect(t).toMatchObject({ examined: 2, closed: 1, reported: 1 });
  partition(t);
  expect(await refs(w)).toEqual(["disclosure.intended", "refund.intended", "disclosure.recovery_intended", OUT]);
});

test("Reconcile step 3.18, 3.19, 3.24, 2.1, 2.8, 2.9: a write under the service identity that answers invalid-credential is a hard alert at once, counts the act skipped, writes nothing more under the credential, leaves the kind's other intents unreached, opens credential-refused for the kind and surfaces every aged intent of it as closure-at-risk; once the credential is reconfigured a landed write closes the finding", async () => {
  const w = await sweepWorld();
  w.probe.answer = COMMITTED;
  const d1 = await died(w, "act-1");
  const d2 = await died(w, "act-2");
  age(w);
  w.binding.serviceCredential = w.stranger.priv;
  const before = w.calls.length;
  const t = await run(w);
  expect(t).toMatchObject({ examined: 1, skipped: 1, unreached: 1, closed: 0 });
  partition(t);
  expect(w.alerts).toContainEqual({ invocation_id: d1.invocation_id, arm: "credential-refused" });
  expect(w.calls.slice(before)).toEqual(["disclosure.recovery_intended"]);                                    // one write, then nothing under the credential
  expect(await refs(w)).toEqual(["disclosure.intended", "disclosure.intended"]);
  expect(w.ri.register.standing("credential-refused", KIND)).not.toBeNull();
  expect(w.ri.register.acts.filter((a) => a.finding === "closure-at-risk").map((a) => a.invocation_id).sort()).toEqual([d1.invocation_id, d2.invocation_id].sort());
  expect(w.probe.asked).toHaveLength(1);                                                                      // the unreached act was never taken
  expect(w.sec.taken).toHaveLength(3);                                                                        // the two invocations' takes and one run take
  w.binding.serviceCredential = w.svc.priv;
  expect(await run(w)).toMatchObject({ examined: 2, closed: 2 });
  expect(w.ri.register.standing("credential-refused", KIND)).toBeNull();                                      // the run's write under the identity answered otherwise
});

test("Act probe 9, Invariant 5.3, 5.10: a committed answer naming an outcome the kind does not enumerate writes nothing and is surfaced; a kind with no act probe bound is read as unavailable, the act left open", async () => {
  const w = await sweepWorld();
  w.probe.answer = { answer: "committed", outcome_action_ref: "disclosure.invented", outcome_data: {} };
  const d = await died(w);
  age(w);
  expect(await run(w)).toMatchObject({ examined: 1, skipped: 1, closed: 0 });
  expect(await refs(w)).toEqual(["disclosure.intended"]);
  expect(w.surfaced).toContainEqual({ arm: "probe-outcome-not-enumerated", kind: KIND, act_key: "act-1", invocation_id: d.invocation_id });
  const v = await sweepWorld();
  await died(v);
  age(v);
  v.binding.actProbe = undefined;
  expect(await run(v)).toMatchObject({ examined: 1, skipped: 1 });
  expect(await refs(v)).toEqual(["disclosure.intended"]);
  expect(v.ri.register.standing("store-unavailable", KIND)).not.toBeNull();
});

test("Reconcile step 3.20, 3.23, 3.26: an invalid-request on a closing or a recovery_intended write closes the act as escalated with cause outcome-unrecordable, counted in escalated alone; where that escalation answers the same the act is left for the next run with a hard alert", async () => {
  const w = await sweepWorld();
  w.probe.answer = COMMITTED;
  await died(w, "act-1");
  age(w);
  w.script.push("step1");                                                                                     // the recovery_intended write
  const t = await run(w);
  expect(t).toMatchObject({ examined: 1, escalated: 1, closed: 0 });
  partition(t);
  expect(await refs(w)).toEqual(["disclosure.intended", "disclosure.escalated"]);
  expect((await raw(w))[1].data).toMatchObject({ cause: "outcome-unrecordable" });
  const v = await sweepWorld();
  v.probe.answer = COMMITTED;
  await died(v, "act-1");
  age(v);
  v.script.push("real", "step1");                                                                             // the plan lands, the outcome is refused
  expect(await run(v)).toMatchObject({ escalated: 1 });
  expect(await refs(v)).toEqual(["disclosure.intended", "disclosure.recovery_intended", "disclosure.escalated"]);
  const x = await sweepWorld();
  x.probe.answer = COMMITTED;
  const d = await died(x, "act-1");
  age(x);
  x.script.push("step1", "step1");                                                                            // the write and the escalation
  expect(await run(x)).toMatchObject({ examined: 1, skipped: 1, escalated: 0 });
  expect(x.alerts).toContainEqual({ invocation_id: d.invocation_id, arm: "escalation-unrecordable" });
  expect(await refs(x)).toEqual(["disclosure.intended"]);
});

test("Reconcile step 3.15 to 3.17, 3.22, Primitive policy 29, 36, 37b, 40, 28: the sweep's writes follow the outcome position: a failed write is retried within the lease, a lost reply is read back once, and what the lease cuts short is left for the next run", async () => {
  const retry = await sweepWorld();
  retry.probe.answer = COMMITTED;
  await died(retry);
  age(retry);
  retry.script.push("rf2");
  expect(await run(retry)).toMatchObject({ closed: 1 });                                                      // Primitive policy 29
  expect(retry.calls.filter((c) => c === "disclosure.recovery_intended")).toHaveLength(2);

  const cut = await sweepWorld();
  cut.probe.answer = COMMITTED;
  await died(cut);
  age(cut);
  cut.script.push("rf2");
  const base = cut.sec.remainingCalls;
  cut.sec.remaining = (n) => (n - base >= 3 ? 1000 : 9000);                                                   // the run's third reading, the one before the retry, is at the floor
  expect(await run(cut)).toMatchObject({ examined: 1, skipped: 1 });
  expect(await refs(cut)).toEqual(["disclosure.intended"]);
  expect(cut.ri.register.standing("journal-unavailable", null)).not.toBeNull();                               // reconcile step 3.22: a recording-failure(step-2) left for the next run

  const lostLanded = await sweepWorld();
  lostLanded.probe.answer = COMMITTED;
  await died(lostLanded);
  age(lostLanded);
  lostLanded.script.push("lost-landed");
  expect(await run(lostLanded)).toMatchObject({ closed: 1 });                                                 // Primitive policy 36: the record read back is adopted
  expect((await refs(lostLanded)).filter((r) => r === "disclosure.recovery_intended")).toHaveLength(1);       // and not written twice

  const lostNothing = await sweepWorld();
  lostNothing.probe.answer = COMMITTED;
  await died(lostNothing);
  age(lostNothing);
  lostNothing.script.push("lost-nothing");
  expect(await run(lostNothing)).toMatchObject({ skipped: 1 });                                               // Primitive policy 37b: left for the next run
  expect(lostNothing.ri.register.instances).toEqual([]);                                                      // a lost reply with no answer is no recording-failure(step-3)
  const step3 = await sweepWorld();
  step3.probe.answer = COMMITTED;
  await died(step3);
  age(step3);
  step3.script.push("rf3-nothing");
  expect(await run(step3)).toMatchObject({ skipped: 1 });
  expect(step3.ri.register.standing("journal-unavailable", null)).not.toBeNull();                             // reconcile step 3.22: a recording-failure(step-3)

  const s4 = await sweepWorld();
  s4.probe.answer = COMMITTED;
  const d4 = await died(s4);
  age(s4);
  s4.script.push("step4-nothing");
  expect(await run(s4)).toMatchObject({ skipped: 1 });                                                        // Primitive policy 40: a hard alert, the act left for the next run
  expect(s4.alerts).toContainEqual({ invocation_id: d4.invocation_id, arm: "invalid-request-step-4" });
  const s4l = await sweepWorld();
  s4l.probe.answer = COMMITTED;
  const d4l = await died(s4l);
  age(s4l);
  s4l.script.push("step4-landed");
  expect(await run(s4l)).toMatchObject({ closed: 1 });                                                        // reconcile step 3.16, Primitive policy 28: success with a hard alert
  expect(s4l.alerts).toContainEqual({ invocation_id: d4l.invocation_id, arm: "sweep-read-back" });
});

test("Reconcile step 5.1, Term at risk threshold, intent age, Invariant 4.6: an examined, skipped or unreached intent whose closing has not landed is surfaced as closure-at-risk once its age reaches the threshold, once only", async () => {
  const w = await sweepWorld();
  w.probe.answer = { answer: "unavailable" };
  const d = await died(w);
  age(w);
  await run(w);
  expect(w.ri.register.acts).toEqual([]);                                                                     // age 11 000 is short of 200 000 - 40 000 - 30 000 - 50
  w.seam.advance(118_949);                                                                                    // age 129 949
  await run(w);
  expect(w.ri.register.acts).toEqual([]);
  w.seam.advance(1);                                                                                          // age 129 950: the threshold does not exceed the age
  await run(w);
  expect(w.ri.register.acts).toMatchObject([{ finding: "closure-at-risk", invocation_id: d.invocation_id }]);
  await run(w);
  expect(w.ri.register.acts).toHaveLength(1);                                                                 // an act finding deduplicates on (invocation id, finding)
  const n = await sweepWorld({ service: null });                                                              // Invariant 4.6: a report-only kind reports every aged intent as at risk
  n.probe.answer = COMMITTED;
  const dn = await died(n);
  n.seam.advance(130_000);
  expect(await run(n)).toMatchObject({ reported: 1 });
  expect(n.ri.register.acts).toMatchObject([{ finding: "closure-at-risk", invocation_id: dn.invocation_id }]);
});

test("Reconcile step 5.9, Term settling edge: an escalation still standing with less than the kind's settling period left before its intent's horizon edge is surfaced as closure-at-risk", async () => {
  const w = await sweepWorld();
  w.probe.answer = { answer: "not-committed" };
  const d = await died(w);
  age(w);
  await run(w);                                                                                               // escalated
  w.ri.register.acts.length = 0;
  const recorded = Date.parse((await w.log.read({ sequence: { from: 1 } }) as LoggedEvent[])[0].recorded_at);
  const edge = recorded + 365 * DAY - 50 - 20_000 - 100_000;                                                  // retention end less the allowance, the run bound and the settling period
  w.seam.set(new Date(edge - 1).toISOString());
  await run(w);
  expect(w.ri.register.acts).toEqual([]);
  w.seam.set(new Date(edge).toISOString());
  await run(w);
  expect(w.ri.register.acts).toMatchObject([{ finding: "closure-at-risk", invocation_id: d.invocation_id }]);
});

test("Reconcile step 1.2, Invariant 7.2, Term horizon edge: an intent whose horizon edge has come is no longer examined", async () => {
  const w = await sweepWorld();
  w.probe.answer = { answer: "unavailable" };
  await died(w);
  age(w);
  expect(await run(w)).toMatchObject({ examined: 1 });
  const recorded = Date.parse((await w.log.read({ sequence: { from: 1 } }) as LoggedEvent[])[0].recorded_at);
  const edge = recorded + 365 * DAY - 50 - 20_000;
  w.seam.set(new Date(edge - 1).toISOString());
  expect(await run(w)).toMatchObject({ examined: 1 });
  w.seam.set(new Date(edge).toISOString());
  expect(await run(w)).toMatchObject({ examined: 0 });
});

test("Run bound 1: a node that has a run in flight starts none beside it", async () => {
  const w = await sweepWorld();
  w.probe.answer = COMMITTED;
  await died(w);
  age(w);
  const [x, y] = await Promise.all([w.ri.reconcile(), w.ri.reconcile()]);
  expect(y).toBe(x);
  expect(w.probe.asked).toHaveLength(1);
});

test("Reconcile 7, Invariant 2.1, 2.3: two nodes' runs serialize on the critical section, so no act carries two closings", async () => {
  const w = await sweepWorld();
  w.probe.answer = COMMITTED;
  await died(w);
  age(w);
  const other = await RecoverableInvocation.start(w.seam, w.cfg);
  const [x, y] = (await Promise.all([w.ri.reconcile(), other.reconcile()])) as Tally[];
  partition(x); partition(y);
  expect((await refs(w)).filter((r) => r === OUT)).toHaveLength(1);
  expect(x.closed + y.closed).toBe(1);
});

test("Rebuild, sweep closed ids, Term sweep closed ids: the sweep's outcome and an escalation without a resolving actor are in sweep closed ids after a rebuild; an operator's closing is a closing but not the sweep's", async () => {
  const w = await sweepWorld();
  w.probe.answer = COMMITTED;
  const d = await died(w);
  const e = await died(w, "act-2");
  age(w);
  await w.closing(OUT, e.invocation_id, "act-2", { intent_event_id: e.intent_event_id, recovery: true, resolving_actor: "operator-1" });   // an operator's outcome
  await w.ri.reconcile();                                                                                     // closes act-1 as the sweep, finds act-2 closed by its operator
  await w.ri.rebuild();
  const closed = (w.ri as unknown as { sweepClosed: Set<string> }).sweepClosed;
  expect([...closed]).toEqual([d.invocation_id]);
});

test("Findings 4 to 12, Term act finding, instance finding: an act finding deduplicates on (invocation id, finding) and is set once; an instance finding is one record per standing condition, advanced while the condition stands, closed when it does not, a recurrence a new record; a name outside the six conditions is refused", () => {
  const r = new FindingsRegister();
  const run1 = { run_id: "r1", at: "2026-06-01T00:00:00.000Z" };
  const run2 = { run_id: "r2", at: "2026-06-01T00:10:00.000Z" };
  r.act("escalated", "k", "a", "i1", run1);
  r.act("escalated", "k", "a", "i1", run2);
  r.act("closure-at-risk", "k", "a", "i1", run2);
  expect(r.acts.map((f) => [f.finding, f.first_seen.run_id])).toEqual([["escalated", "r1"], ["closure-at-risk", "r2"]]);
  r.instance("store-unavailable", "k", run1);
  r.instance("store-unavailable", "k", run2);
  r.instance("store-unavailable", "other", run2);                                                             // deduplicates on (finding, kind)
  expect(r.instances).toHaveLength(2);
  expect(r.standing("store-unavailable", "k")).toMatchObject({ first_seen: run1, last_seen: run2, run_id: "r1" });
  r.close("store-unavailable", "k");
  expect(r.standing("store-unavailable", "k")).toBeNull();
  expect(r.instances[0].last_seen).toEqual(run2);                                                             // closed with last seen as it was
  r.instance("store-unavailable", "k", run2);
  expect(r.instances).toHaveLength(3);                                                                        // findings 11
  expect(() => r.act("journal-unavailable" as never, "k", "a", "i2", run1)).toThrow();                        // findings 4: an act finding is one of the act kinds
  expect(() => r.instance("escalated" as never, null, run1)).toThrow();
  expect(() => r.instance("made-up" as never, null, run1)).toThrow();                                         // findings 6
});
