// Each test names the rule it holds; rule numbers are compositions/shared-todo.md's.
import { assertEquals } from "@std/assert";
import { assignment, permissions, personalTodo } from "../src/atoms.ts";
import { ok, world } from "./helpers.ts";

const statuses = (w: ReturnType<typeof world>, task: string) => assignment.history_for(w.db, task).map((a) => [a.assignee_ref, a.status]);

Deno.test("The sprint board, end to end: the gate, the relay and the cascade", () => {
  const w = world();
  const t1 = ok(w.st.add_task("alice", "implement login flow"));
  const a1 = ok(w.st.assign_task("manager", t1, "alice"));
  assertEquals(w.st.edit_task("alice", t1, "implement login flow — OAuth2 only"), { ok: "ok" });
  ok(w.st.reassign_task("manager", a1, "bob"));
  assertEquals(w.st.complete_task("bob", t1), { ok: "ok" });
  assertEquals(w.st.responsible_actor("manager", t1), { ok: "bob" }); // Action wiring 8: completion recalls nothing
  assertEquals(w.st.delete_task("carol", t1), { refused: "permission-denied" });
  assertEquals(w.st.delete_task("manager", t1), { ok: "ok" });
  assertEquals(statuses(w, t1), [["alice", "transferred"], ["bob", "recalled"]]); // Invariant 3.1, 4.2
});

Deno.test("Action wiring 1 through 3 and Invariant 1.2: a denied call reaches no constituent", () => {
  const w = world();
  const t = ok(w.st.add_task("alice", "t"));
  const a = ok(w.st.assign_task("manager", t, "alice"));
  const before = [personalTodo.read(w.db), assignment.history_for(w.db, t)];
  for (const r of [
    w.st.add_task("manager", "u"), w.st.edit_task("manager", t, "v"), w.st.complete_task("manager", t),
    w.st.delete_task("alice", t), w.st.assign_task("alice", t, "bob"), w.st.reassign_task("alice", a, "bob"),
    w.st.recall_assignment("alice", a), w.st.responsible_actor("carol", t), w.st.visible_tasks("carol"),
  ]) assertEquals(r, { refused: "permission-denied" });
  assertEquals([personalTodo.read(w.db), assignment.history_for(w.db, t)], before);
});

Deno.test("Action wiring 19: a denied view is permission-denied, never an empty list", () => {
  const w = world();
  assertEquals(w.st.visible_tasks("alice"), { ok: [] });
  assertEquals(w.st.visible_tasks("carol"), { refused: "permission-denied" });
});

Deno.test("Action wiring 20 and 21: the responsible actor, unassigned, or not-known", () => {
  const w = world();
  const t = ok(w.st.add_task("alice", "t"));
  assertEquals(w.st.responsible_actor("manager", t), { ok: "unassigned" });
  ok(w.st.assign_task("manager", t, "alice"));
  assertEquals(w.st.responsible_actor("manager", t), { ok: "alice" });
  assertEquals(w.st.responsible_actor("manager", "task-404"), { refused: "not-known" });
  ok(w.st.delete_task("manager", t));
  assertEquals(w.st.responsible_actor("manager", t), { refused: "not-known" });
});

Deno.test("Action wiring 13 through 15: assign checks the task is carried, and accepts a done one", () => {
  const w = world();
  const t = ok(w.st.add_task("alice", "t"));
  ok(w.st.complete_task("alice", t));
  assertEquals("ok" in w.st.assign_task("manager", t, "bob"), true);
  assertEquals(w.st.assign_task("manager", "task-404", "bob"), { refused: "not-known" });
  const u = ok(w.st.add_task("alice", "u"));
  ok(w.st.delete_task("manager", u));
  assertEquals(w.st.assign_task("manager", u, "bob"), { refused: "not-known" }); // Invariant 3.2
});

Deno.test("Action wiring 11 and 12: a failed recall answers storage-failure and deletes nothing", () => {
  const w = world();
  const t = ok(w.st.add_task("alice", "t"));
  ok(w.st.assign_task("manager", t, "alice"));
  w.f.arm("assignment.recall");
  assertEquals(w.st.delete_task("manager", t), { refused: "storage-failure" });
  assertEquals(w.st.responsible_actor("manager", t), { ok: "alice" });
});

Deno.test("Wiring decision 3: a delete failing after the recall leaves the recall standing", () => {
  const w = world();
  const t = ok(w.st.add_task("alice", "t"));
  ok(w.st.assign_task("manager", t, "alice"));
  w.f.arm("todo.delete");
  assertEquals(w.st.delete_task("manager", t), { refused: "storage-failure" });
  assertEquals(w.st.responsible_actor("manager", t), { ok: "unassigned" });
  assertEquals(w.st.delete_task("manager", t), { ok: "ok" }); // the retry
});

Deno.test("Composes 9: a constituent's refusal is answered unchanged", () => {
  const w = world();
  const t = ok(w.st.add_task("alice", "t"));
  assertEquals(w.st.add_task("alice", "  "), { refused: "invalid-description" });
  ok(w.st.complete_task("alice", t));
  assertEquals(w.st.edit_task("alice", t, "x"), { refused: "not-editable" });
  assertEquals(w.st.complete_task("alice", t), { refused: "not-pending" });
  const a = ok(w.st.assign_task("manager", t, "alice"));
  ok(w.st.recall_assignment("manager", a));
  assertEquals(w.st.reassign_task("manager", a, "bob"), { refused: "not-active" });
  assertEquals(w.st.recall_assignment("manager", a), { refused: "not-active" });
});

Deno.test("Non-goal 15: one instance, one uniqueness — across actors, and against a done task", () => {
  const w = world();
  const t = ok(w.st.add_task("alice", "Write the report"));
  assertEquals(w.st.add_task("bob", " Write the report "), { refused: "duplicate-active" });
  ok(w.st.complete_task("alice", t));
  assertEquals(w.st.add_task("bob", "Write the report"), { refused: "duplicate-active" });
  assertEquals("ok" in w.st.add_task("bob", "write the report"), true); // case-sensitive
});

Deno.test("Concurrency 2 and 3: the loser of two assigns, and of two deletes", () => {
  const w = world();
  const t = ok(w.st.add_task("alice", "t"));
  ok(w.st.assign_task("manager", t, "alice"));
  assertEquals(w.st.assign_task("manager", t, "bob"), { refused: "already-assigned" });
  ok(w.st.delete_task("manager", t));
  assertEquals(w.st.delete_task("manager", t), { refused: "not-known" });
});

Deno.test("Invariant 5.2: a task's delete changes no grant", () => {
  const w = world();
  const t = ok(w.st.add_task("alice", "t"));
  const before = permissions.read(w.db);
  ok(w.st.delete_task("manager", t));
  assertEquals(permissions.read(w.db), before);
});

Deno.test("Concurrency 4 and 5: a grant revoked inside a call does not reach it", () => {
  const w = world();
  const t = ok(w.st.add_task("alice", "t"));
  ok(w.st.assign_task("manager", t, "alice"));
  w.f.between("after-recall", () => permissions.revoke(w.db, w.seam, w.grants["manager tasks:delete"]));
  assertEquals(w.st.delete_task("manager", t), { ok: "ok" });
  const u = ok(w.st.add_task("alice", "u"));
  assertEquals(w.st.delete_task("manager", u), { refused: "permission-denied" });
});
