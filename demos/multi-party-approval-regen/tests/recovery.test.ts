// The failure arms, the initiation recovery and the sweep. Each test names the rule it holds.
import { assert, assertEquals, assertThrows } from "@std/assert";
import { approvalStep, assignment } from "../src/atoms.ts";
import { ALL, APPROVERS, CONFIG, TWO, world } from "./helpers.ts";

const AFTER_BOUND = CONFIG.decisionCompletionBoundMs + 1;

Deno.test("an outcome failure before the append answers recording-failure at the outcome: the act committed (Audit arm 10, 15)", () => {
  const w = world();
  const { chain_id, steps } = w.open();
  w.f.arm("log.append:step_approved");
  assertEquals(w.mpa.approve_step("chen", w.cred("chen"), chain_id, steps[0]), { refused: "recording-failure", position: "outcome" });
  assertEquals(approvalStep.get(w.db, steps[0])!.state, "approved");
  assertEquals(w.of("step_approved").length, 0);
});

Deno.test("an outcome refused at the retention step is read back and proceeds as landed (Audit arm 6, 8, 9)", () => {
  const w = world();
  const { chain_id, steps } = w.open();
  w.f.arm("retention.place:step_approved");
  assertEquals(w.mpa.approve_step("chen", w.cred("chen"), chain_id, steps[0]), { ok: "approved" });
  assert(w.mpa.eventIndex(chain_id).some((e) => e.event_id === w.of("step_approved")[0].id));
});

Deno.test("the sweep leaves a young transition and re-emits an aged one, once, under the service identity (Reconciliation 4, 17, 21)", () => {
  const w = world();
  const { chain_id, steps } = w.open();
  w.f.arm("log.append:step_approved");
  w.mpa.approve_step("chen", w.cred("chen"), chain_id, steps[0]);
  w.mpa.sweep();
  assertEquals(w.of("step_approved").length, 0);
  w.seam.advance(AFTER_BOUND);
  w.mpa.sweep();
  const [re] = w.of("step_approved");
  assertEquals([re.actor_ref, re.data.acting_actor_ref, re.data.recovery], ["mpa_service", "chen", true]);
  assertEquals(re.data.intent_event_candidates, [w.of("step_decision_intended")[0].id]);
  assert(w.of("chain_recovery_intended")[0].seq < re.seq);                                       // 28
  w.mpa.sweep();
  assertEquals(w.of("step_approved").length, 1);                                                 // Invariant 5.1
});

Deno.test("a submit failure closes the chain by the initiation recovery, disposition a (Action wiring 9, 62; Reconciliation 12 through 15; Invariant 1.2)", () => {
  const w = world();
  w.f.arm("step.submit:park");                                                                   // the first submit lands, the second refuses
  assertEquals(w.mpa.initiate_chain("morgan", w.cred("morgan"), "s", "sc", APPROVERS, ALL), { refused: "recording-failure", position: "outcome" });
  const [c] = w.mpa.chains();
  assertEquals([c.state, c.audit_pending], ["Withdrawn", false]);
  const [failed] = w.of("chain_initiation_failed");
  assertEquals([failed.actor_ref, failed.data.disposition], ["mpa_service", "a"]);
  assertEquals((failed.data.chain_shape as { step_ids: string[] }).step_ids, w.mpa.stepList(c.chain_id));
  assertEquals(w.mpa.stepList(c.chain_id).length, 1);
  assertEquals(approvalStep.get(w.db, w.mpa.stepList(c.chain_id)[0])!.state, "withdrawn");
  const [withdrawn] = w.of("chain_withdrawn");
  assertEquals([withdrawn.data.recovery, withdrawn.data.initiation_failed_event_id], [true, failed.id]);
  assertEquals(withdrawn.data.reason, "initiation-failed recovery (disposition a)");
});

Deno.test("an assign failure closes the chain, disposition b (Action wiring 12)", () => {
  const w = world();
  w.f.arm("assignment.assign:step-002");
  assertEquals(w.mpa.initiate_chain("morgan", w.cred("morgan"), "s", "sc", APPROVERS, ALL), { refused: "recording-failure", position: "outcome" });
  const [c] = w.mpa.chains();
  assertEquals(c.state, "Withdrawn");
  assertEquals(w.of("chain_initiation_failed")[0].data.disposition, "b");
  for (const id of w.mpa.stepList(c.chain_id)) assertEquals(assignment.active_for(w.db, id), "none");
});

Deno.test("an unlanded initiation event closes the chain, disposition c, and answers at the outcome (Action wiring 15)", () => {
  const w = world();
  w.f.arm("log.append:chain_initiated");
  assertEquals(w.mpa.initiate_chain("morgan", w.cred("morgan"), "s", "sc", APPROVERS, ALL), { refused: "recording-failure", position: "outcome" });
  assertEquals(w.mpa.chains()[0].state, "Withdrawn");
  assertEquals(w.of("chain_initiation_failed")[0].data.disposition, "c");
});

Deno.test("a quarantined chain its approvers drove terminal is recorded, not withdrawn (Reconciliation 9, 10, 16; disposition d)", () => {
  const w = world();
  w.f.arm("log.append:chain_initiated");
  w.f.arm("log.append:chain_initiation_failed");
  w.mpa.initiate_chain("morgan", w.cred("morgan"), "s", "sc", APPROVERS, ALL);
  const [c] = w.mpa.chains();
  assertEquals([c.state, c.audit_pending], ["Pending", true]);                                   // 11: quarantined
  for (const [i, a] of APPROVERS.entries()) w.mpa.approve_step(a, w.cred(a), c.chain_id, w.mpa.stepList(c.chain_id)[i]);
  assertEquals(w.mpa.chain(c.chain_id)!.state, "Approved");                                      // nothing gates decisions on the flag
  w.seam.advance(AFTER_BOUND);
  w.mpa.sweep();
  const x = w.mpa.chain(c.chain_id)!;
  assertEquals([x.state, x.audit_pending], ["Approved", false]);
  const [init] = w.of("chain_initiated");
  assertEquals([init.actor_ref, init.data.disposition, init.data.recovery], ["mpa_service", "d", true]);
});

Deno.test("a partial cascade is carried on the resolution and closed by the sweep (Cascade 8, 9; Reconciliation 26, 30; Check 5.4)", () => {
  const w = world();
  const { chain_id, steps } = w.open();
  const third = w.mpa.stepAssignment(steps[2])!;
  w.f.arm(`assignment.recall:${third}`);
  assertEquals(w.mpa.reject_step("chen", w.cred("chen"), chain_id, steps[0], "no"), { ok: "rejected_outcome" });
  const [res] = w.of("chain_resolved");
  assertEquals([res.data.cascade_partial, res.data.recalled_step_ids], [true, [steps[1]]]);
  assertEquals(res.data.partial_steps, [{ step_id: steps[2], call: "recall" }]);
  w.seam.advance(AFTER_BOUND);
  w.mpa.sweep();
  assertEquals(assignment.active_for(w.db, steps[2]), "none");
  const closure = w.of("cascade_completed");
  assertEquals(closure.map((e) => [e.data.step_id, e.data.closure_mark]), [[steps[2], "retried"]]);
});

Deno.test("a decision written around the composition counts Pending, reads out-of-band, and is alerted, never re-emitted (Wiring decision 7, 8; Reconciliation 19, 20)", () => {
  const w = world();
  const { chain_id, steps } = w.open(TWO);
  approvalStep.resolve(w.db, w.seam, w.f, "approve", steps[0], "chen");
  approvalStep.resolve(w.db, w.seam, w.f, "approve", steps[1], "park");
  assertEquals(w.mpa.routedVector(chain_id).A, 0);
  w.seam.advance(AFTER_BOUND);
  w.mpa.sweep();
  assertEquals(w.mpa.chain(chain_id)!.state, "Pending");
  assertEquals(w.of("step_approved").length, 0);
  assertEquals(w.mpa.alerts.filter((a) => a.kind === "out-of-band").length, 2);
  const r = w.mpa.read_chain("auditor", { chain_id });
  assert("ok" in r);
  assertEquals(r.ok[0].steps.map((s) => s.out_of_band), [true, true, false]);
});

Deno.test("past the horizon a purged decision intent still routes, by its surviving action and actor (Term routed transition)", () => {
  const w = world();
  const { chain_id, steps } = w.open(TWO);
  w.mpa.approve_step("chen", w.cred("chen"), chain_id, steps[0]);
  w.audit.purge_for_test(w.of("step_decision_intended")[0].id);
  assertEquals(w.mpa.routedVector(chain_id).A, 1);
});

Deno.test("the sweep leaves a chain another holder holds to the next run (Reconciliation 6, 7)", () => {
  const w = world();
  const { chain_id, steps } = w.open();
  w.f.arm("log.append:step_approved");
  w.mpa.approve_step("chen", w.cred("chen"), chain_id, steps[0]);
  w.seam.advance(AFTER_BOUND);
  w.mpa.holdForTest(chain_id);
  w.mpa.sweep();
  assertEquals(w.of("step_approved").length, 0);
  w.mpa.releaseForTest(chain_id);
  w.mpa.sweep();
  assertEquals(w.of("step_approved").length, 1);
});

Deno.test("an open marker past the compensation window opens a finding (Reconciliation 32)", () => {
  const w = world();
  w.f.arm("log.append:chain_initiated", 5);
  w.f.arm("log.append:chain_initiation_failed", 5);
  w.mpa.initiate_chain("morgan", w.cred("morgan"), "s", "sc", APPROVERS, ALL);
  w.seam.advance(CONFIG.compensationWindowMs + 1);
  w.mpa.sweep();
  assert(w.mpa.findings.some((f) => f.marker === "quarantine"));
});

Deno.test("a terminal chain keeps its state and terminal instant; declared fields never change (Invariant 7, 8)", () => {
  const w = world();
  const { chain_id, steps } = w.open();
  w.mpa.reject_step("chen", w.cred("chen"), chain_id, steps[0], "no");
  assertThrows(() => w.db.exec(`UPDATE chain SET state = 'Approved' WHERE chain_id = '${chain_id}'`));
  assertThrows(() => w.db.exec(`UPDATE chain SET scope = 'other' WHERE chain_id = '${chain_id}'`));
  assertThrows(() => w.db.exec(`DELETE FROM chain WHERE chain_id = '${chain_id}'`));
});

Deno.test("the records: one terminal event per terminal chain, outcomes after their intents, and the service identity only where Check 5.3 allows", () => {
  const w = world();
  const a = w.open(), b = w.open(TWO), c = w.open();
  for (const [i, x] of APPROVERS.entries()) w.mpa.approve_step(x, w.cred(x), a.chain_id, a.steps[i]);
  w.mpa.reject_step("chen", w.cred("chen"), b.chain_id, b.steps[0], "no");
  w.mpa.reject_step("park", w.cred("park"), b.chain_id, b.steps[1], "no");
  w.mpa.withdraw_chain("morgan", w.cred("morgan"), c.chain_id, "superseded");
  for (const ch of [a, b, c]) {
    const terminal = w.events().filter((e) => e.data.chain_id === ch.chain_id && ["chain_resolved", "chain_withdrawn"].includes(e.action_ref));
    assertEquals(terminal.length, 1);                                                            // Check 7.1
  }
  const byId = new Map(w.events().map((e) => [e.id, e]));
  for (const e of w.events().filter((e) => e.data.intent_event_id)) {                            // Check 10.1
    const i = byId.get(e.data.intent_event_id as string)!;
    assert(i.seq < e.seq && i.actor_ref === e.actor_ref);
  }
  const allowed = ["chain_resolved", "cascade_completed", "chain_initiation_failed"];
  for (const e of w.events().filter((e) => e.actor_ref === "mpa_service")) assert(allowed.includes(e.action_ref) || e.data.recovery === true);  // Check 5.3
});

Deno.test("at quiescence an open step holds one Active assignment and a settled step none (Invariant 4.1, 4.2)", () => {
  const w = world();
  const a = w.open(TWO), b = w.open();
  w.mpa.approve_step("chen", w.cred("chen"), a.chain_id, a.steps[0]);
  w.mpa.approve_step("park", w.cred("park"), a.chain_id, a.steps[1]);
  w.mpa.approve_step("chen", w.cred("chen"), b.chain_id, b.steps[0]);
  for (const ch of [a, b]) for (const id of ch.steps) {
    const open = approvalStep.get(w.db, id)!.state === "pending" && w.mpa.chain(ch.chain_id)!.state === "Pending";
    assertEquals(assignment.active_for(w.db, id) !== "none", open);
  }
});
