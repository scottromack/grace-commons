// The actions, their refusals and the quorum rule. Each test names the rule it holds.
import { assert, assertEquals } from "@std/assert";
import { approvalStep, assignment } from "../src/atoms.ts";
import { MultiPartyApproval } from "../src/composition.ts";
import { ALL, APPROVERS, CONFIG, ONE, TWO, world } from "./helpers.ts";

Deno.test("the walkthrough: all-of-N, three approvals, one resolution; nine events, each verified (Walkthrough, Invariant 2.1)", () => {
  const w = world();
  const { chain_id, steps } = w.open();
  assertEquals(w.mpa.approve_step("park", w.cred("park"), chain_id, steps[1], "in policy"), { ok: "approved" });
  assertEquals(w.mpa.chain(chain_id)!.state, "Pending");
  w.mpa.approve_step("chen", w.cred("chen"), chain_id, steps[0]);
  w.mpa.approve_step("walsh", w.cred("walsh"), chain_id, steps[2]);
  const c = w.mpa.chain(chain_id)!;
  assertEquals(c.state, "Approved");
  assertEquals(w.of("chain_resolved").length, 1);
  assertEquals(w.of("chain_resolved")[0].data.reason, "quorum met: 3 of 3 approved under all-of-N");
  assertEquals(w.events().length, 9);
  for (const e of w.events()) assertEquals(w.audit.verify_record(e.id), "verified");
  assertEquals(w.mpa.eventIndex(chain_id).length, 9);                                        // Action wiring 57
});

Deno.test("the intent verifies the credential before anything commits (Invariant 10.1, Audit arm 1)", () => {
  const w = world();
  assertEquals(w.mpa.initiate_chain("morgan", "wrong", "s", "sc", APPROVERS, ALL), { refused: "invalid-credential" });
  assertEquals(w.mpa.chains().length, 0);
  assertEquals((w.db.prepare("SELECT COUNT(*) AS n FROM step").get<{ n: number }>())!.n, 0);
  assertEquals((w.db.prepare("SELECT COUNT(*) AS n FROM assignment").get<{ n: number }>())!.n, 0);
});

Deno.test("a pre-intent refusal records nothing (Action wiring 2, Non-goal 9, Primitive policy 11)", () => {
  const w = world();
  assertEquals(w.mpa.initiate_chain("chen", w.cred("chen"), "s", "sc", APPROVERS, ALL), { refused: "permission-denied" });
  assertEquals(w.mpa.initiate_chain("morgan", w.cred("morgan"), "s", "sc", ["chen", "chen"], ALL), { refused: "invalid-request" });      // 6
  assertEquals(w.mpa.initiate_chain("morgan", w.cred("morgan"), "s", "sc", APPROVERS, { rule: "M-of-N", m: 4 }), { refused: "invalid-request" });  // 8
  assertEquals(w.mpa.initiate_chain("morgan", w.cred("morgan"), " ", "sc", APPROVERS, ALL), { refused: "invalid-request" });             // 3
  assertEquals(w.mpa.initiate_chain("morgan", w.cred("morgan"), "s".repeat(201), "sc", APPROVERS, ALL), { refused: "invalid-request" }); // 4
  assertEquals(w.mpa.initiate_chain("", "x", "s", "sc", APPROVERS, ALL), { refused: "invalid-request" });                               // 1
  assertEquals(w.mpa.initiate_chain("morgan", w.cred("morgan"), "s", "sc", ["x".repeat(65)], ALL), { refused: "invalid-request" });     // 2
  assertEquals(w.events().length, 0);
});

Deno.test("the deployment's knobs: minimum, allowed rules, payload budget (Primitive policy 5, 7, 10)", () => {
  const w = world({ approverSetMinimum: 2, allowedQuorumRules: ["all-of-N"] });
  assertEquals(w.mpa.initiate_chain("morgan", w.cred("morgan"), "s", "sc", ["chen"], ALL), { refused: "invalid-request" });
  assertEquals(w.mpa.initiate_chain("morgan", w.cred("morgan"), "s", "sc", APPROVERS, ONE), { refused: "invalid-request" });
  const many = Array.from({ length: 150 }, (_, i) => `approver_${i}`);
  assertEquals(w.mpa.initiate_chain("morgan", w.cred("morgan"), "s", "sc", many, ALL), { refused: "invalid-request" });
});

Deno.test("an initiation writes a chain, a step and an assignment per slot, in order, with the prefixed reason (Action wiring 6 through 14)", () => {
  const w = world();
  const { chain_id, steps } = w.open();
  assertEquals(steps.length, 3);
  steps.forEach((id, i) => {
    const s = approvalStep.get(w.db, id)!;
    assertEquals([s.approver_ref, s.submitter_ref, s.reason], [APPROVERS[i], "morgan", `chain:${chain_id}: Q1 close`]);
    assertEquals(w.mpa.stepChain(id), chain_id);
    const a = assignment.active_for(w.db, id);
    assert(a !== "none" && a.assignee_ref === APPROVERS[i]);
  });
  const [intent] = w.of("chain_initiation_intended"), [init] = w.of("chain_initiated");
  assertEquals("chain_id" in intent.data, false);                                              // 4: no minted id
  assertEquals(init.data.intent_event_id, intent.id);
  assertEquals((init.data.chain_shape as { step_ids: string[] }).step_ids, steps);
});

Deno.test("M-of-N(2): the second approval approves; the third step stays Pending, its assignment recalled (Cascade 1, 13)", () => {
  const w = world();
  const { chain_id, steps } = w.open(TWO);
  w.mpa.approve_step("chen", w.cred("chen"), chain_id, steps[0]);
  w.mpa.approve_step("park", w.cred("park"), chain_id, steps[1]);
  assertEquals(w.mpa.chain(chain_id)!.state, "Approved");
  assertEquals(approvalStep.get(w.db, steps[2])!.state, "pending");
  assertEquals(assignment.active_for(w.db, steps[2]), "none");
  assertEquals(w.of("chain_resolved")[0].data.recalled_step_ids, [steps[2]]);
  assertEquals(w.of("chain_resolved")[0].actor_ref, "mpa_service");                            // Action wiring 38
});

Deno.test("a trailing decision lands, flagged, and changes no chain (Action wiring 18, 19, 31)", () => {
  const w = world();
  const { chain_id, steps } = w.open(TWO);
  w.mpa.approve_step("chen", w.cred("chen"), chain_id, steps[0]);
  w.mpa.approve_step("park", w.cred("park"), chain_id, steps[1]);
  const before = w.mpa.chain(chain_id)!;
  assertEquals(w.mpa.approve_step("walsh", w.cred("walsh"), chain_id, steps[2], "concur"), { ok: "approved" });
  assertEquals(w.of("step_approved").at(-1)!.data.trailing, true);
  assertEquals(w.of("chain_resolved").length, 1);
  assertEquals(w.mpa.chain(chain_id), before);
});

Deno.test("one rejection under all-of-N rejects, with the rule reason (Wiring decision 2, 9)", () => {
  const w = world();
  const { chain_id, steps } = w.open();
  assertEquals(w.mpa.reject_step("walsh", w.cred("walsh"), chain_id, steps[2], "counterparty not approved"), { ok: "rejected_outcome" });
  assertEquals(w.mpa.chain(chain_id)!.state, "Rejected");
  assertEquals(w.of("chain_resolved")[0].data.reason, "quorum unreachable: all-of-N; 2 remain achievable; rejections present");
  assertEquals(w.of("chain_resolved")[0].data.recalled_step_ids, steps.slice(0, 2));
});

Deno.test("withdrawals alone that make quorum unreachable end the chain Withdrawn, not Rejected (Wiring decision 3)", () => {
  const w = world();
  const { chain_id, steps } = w.open(TWO, APPROVERS, "ross");
  w.mpa.approve_step("chen", w.cred("chen"), chain_id, steps[0]);
  assertEquals(w.mpa.withdraw_step("ross", w.cred("ross"), chain_id, steps[1], "wrong reviewer"), { ok: "withdrawn" });
  assertEquals(w.mpa.chain(chain_id)!.state, "Pending");
  w.mpa.withdraw_step("ross", w.cred("ross"), chain_id, steps[2], "mis-scoped");
  assertEquals(w.mpa.chain(chain_id)!.state, "Withdrawn");
  assertEquals(w.of("chain_resolved")[0].data.reason, "chain withdrawn by cascade: M-of-N(2); quorum unreachable by withdrawal alone");
  assertEquals(w.of("chain_resolved")[0].data.recalled_step_ids, []);
});

Deno.test("the quorum rule over the three rules (Term met vectors, Term lost vectors)", () => {
  const q = MultiPartyApproval.quorum;
  assertEquals(q(ALL, { A: 3, R: 0, W: 0, N: 3 }), "Approved");
  assertEquals(q(ALL, { A: 2, R: 0, W: 1, N: 3 }), "Withdrawn");
  assertEquals(q(TWO, { A: 1, R: 1, W: 0, N: 3 }), "Pending");
  assertEquals(q(TWO, { A: 1, R: 1, W: 1, N: 3 }), "Rejected");
  assertEquals(q(ONE, { A: 1, R: 2, W: 0, N: 3 }), "Approved");
  assertEquals(q(ONE, { A: 0, R: 2, W: 1, N: 3 }), "Rejected");
});

Deno.test("a step not under the named chain answers not-known before any intent (Action wiring 17)", () => {
  const w = world();
  const a = w.open(), b = w.open();
  const n = w.events().length;
  assertEquals(w.mpa.approve_step("chen", w.cred("chen"), a.chain_id, b.steps[0]), { refused: "not-known" });
  assertEquals(w.events().length, n);
});

Deno.test("a step refusal is relayed after the intent; the intent stands without an outcome (Action wiring 22, Check 10.5)", () => {
  const w = world();
  const { chain_id, steps } = w.open();
  assertEquals(w.mpa.approve_step("park", w.cred("park"), chain_id, steps[0]), { refused: "unauthorized" });
  assertEquals(w.of("step_decision_intended").length, 1);
  assertEquals(w.of("step_approved").length, 0);
  w.mpa.approve_step("chen", w.cred("chen"), chain_id, steps[0]);
  assertEquals(w.mpa.approve_step("chen", w.cred("chen"), chain_id, steps[0]), { refused: "not-pending" });
});

Deno.test("a step store failure answers recording-failure at the intent: nothing committed (Action wiring 23, Audit arm 14)", () => {
  const w = world();
  const { chain_id, steps } = w.open();
  w.f.arm("step.approve");
  assertEquals(w.mpa.approve_step("chen", w.cred("chen"), chain_id, steps[0]), { refused: "recording-failure", position: "intent" });
  assertEquals(approvalStep.get(w.db, steps[0])!.state, "pending");
});

Deno.test("[Withdraw Chain]: its refusals, then the cascade under the initiator's credential (Action wiring 40 through 50, Cascade 5)", () => {
  const w = world();
  const { chain_id, steps } = w.open();
  assertEquals(w.mpa.withdraw_chain("chen", w.cred("chen"), chain_id, "x"), { refused: "permission-denied" });
  assertEquals(w.mpa.withdraw_chain("morgan", w.cred("morgan"), "chain-999", "x"), { refused: "not-known" });
  assertEquals(w.mpa.withdraw_chain("ross", w.cred("ross"), chain_id, "x"), { refused: "unauthorized" });
  assertEquals(w.mpa.withdraw_chain("morgan", w.cred("morgan"), chain_id, " "), { refused: "invalid-request" });
  assertEquals(w.of("chain_withdrawal_intended").length, 0);                                    // pre-intent refusals
  assertEquals(w.mpa.withdraw_chain("morgan", w.cred("morgan"), chain_id, "wrong entry"), { ok: "withdrawn" });
  assertEquals(w.mpa.chain(chain_id)!.state, "Withdrawn");
  for (const id of steps) assertEquals(approvalStep.get(w.db, id)!.state, "withdrawn");
  const cascaded = w.of("step_withdrawn");
  assertEquals(cascaded.length, 3);
  for (const e of cascaded) assertEquals([e.actor_ref, e.data.cascade, e.data.recovery], ["morgan", true, undefined]);
  assertEquals(w.of("chain_withdrawn")[0].data.intent_event_id, w.of("chain_withdrawal_intended")[0].id);
  assertEquals(w.mpa.withdraw_chain("morgan", w.cred("morgan"), chain_id, "again"), { refused: "not-pending" });
});

Deno.test("[Read Chain]: permission, the query rules, order, and no audit event (Action wiring 51 through 56)", () => {
  const w = world();
  const a = w.open(), b = w.open(ONE);
  assertEquals(w.mpa.read_chain("chen", {}), { refused: "permission-denied" });
  assertEquals(w.mpa.read_chain("auditor", { color: "red" } as never), { refused: "invalid-query" });
  assertEquals(w.mpa.read_chain("auditor", { subject_ref: " " }), { refused: "invalid-query" });
  assertEquals(w.mpa.read_chain("auditor", { state: "Done" }), { refused: "invalid-query" });
  assertEquals(w.mpa.read_chain("auditor", { initiated_at: { after: "2027", before: "2026" } }), { refused: "invalid-query" });
  const n = w.events().length;
  const r = w.mpa.read_chain("auditor", { subject_ref: "je-2026-0441", state: "Pending" });
  assert("ok" in r);
  assertEquals(r.ok.map((x) => x.chain.chain_id), [a.chain_id, b.chain_id]);
  assertEquals(r.ok[0].steps.map((s) => s.assignments.length), [1, 1, 1]);
  assertEquals(w.events().length, n);
});

Deno.test("an instance refuses to start when the window does not exceed the liveness sum (Capability requirement 11)", () => {
  let threw = false;
  try { world({ compensationWindowMs: CONFIG.decisionCompletionBoundMs + CONFIG.reconciliationCadenceMs + CONFIG.outcomeWriteLatencyMs }); }
  catch { threw = true; }
  assert(threw);
});
