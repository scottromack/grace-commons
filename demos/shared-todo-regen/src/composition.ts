// Shared Todo: the gate, the cascade and the nine actions. The composition
// stores nothing (Composition state 1); every answer is a constituent's, or
// permission-denied, or one of the two derived queries' own (Action wiring 18;
// Composes 9). Rule numbers are compositions/shared-todo.md's.
import type { Database } from "@db/sqlite";
import type { Seam } from "./seam.ts";
import type { Faults } from "./faults.ts";
import { assignment, permissions, personalTodo, type Unit } from "./atoms.ts";

export type Scope = "tasks:view" | "tasks:add" | "tasks:edit" | "tasks:complete" | "tasks:delete" | "tasks:assign" | "tasks:recall";
type Answer<T, E extends string> = { ok: T } | { refused: E | "permission-denied" };

export class SharedTodo {
  constructor(private db: Database, private seam: Seam, private f: Faults) {}

  // Action wiring 1 through 4; Concurrency 4, 5: one check, at the call's start, never repeated.
  private gate<T, E extends string>(actor_ref: string, scope: Scope, then: () => Answer<T, E>): Answer<T, E> {
    if (permissions.permitted(this.db, actor_ref, scope) === "denied") return { refused: "permission-denied" };
    return then();
  }

  add_task(actor_ref: string, description: string) { // Scope vocabulary 3; Action wiring 5
    return this.gate(actor_ref, "tasks:add", () => personalTodo.add(this.db, this.seam, this.f, description));
  }
  edit_task(actor_ref: string, task_id: string, new_description: string) { // Scope vocabulary 4; Action wiring 6
    return this.gate(actor_ref, "tasks:edit", () => personalTodo.edit(this.db, this.seam, this.f, task_id, new_description));
  }
  complete_task(actor_ref: string, task_id: string) { // Scope vocabulary 5; Action wiring 7, 8
    return this.gate(actor_ref, "tasks:complete", () => personalTodo.complete(this.db, this.seam, this.f, task_id));
  }
  // Scope vocabulary 6; Action wiring 9 through 12; Wiring decision 1 through 3: recall first, then delete, no transaction.
  delete_task(actor_ref: string, task_id: string) {
    return this.gate(actor_ref, "tasks:delete", (): Answer<"ok", "not-known" | "storage-failure"> => {
      const active = assignment.active_for(this.db, task_id);
      if (active !== "none") {
        const r = assignment.recall(this.db, this.seam, this.f, active.assignment_id);
        if ("refused" in r && r.refused === "storage-failure") return { refused: "storage-failure" };
        // not-known and not-active cannot land: the host serializes calls naming one task id (Concurrency 1).
        if ("refused" in r) throw new Error(`recall answered ${r.refused} under the host's serialization`);
      }
      this.f.at("after-recall");
      return personalTodo.delete(this.db, this.f, task_id);
    });
  }
  // Scope vocabulary 7; Action wiring 13 through 15: the task must be carried, pending or done.
  assign_task(actor_ref: string, task_id: string, assignee_ref: string) {
    return this.gate(actor_ref, "tasks:assign", (): Answer<string, "not-known" | "invalid-request" | "already-assigned" | "storage-failure"> => {
      if (!this.carries(task_id)) return { refused: "not-known" };
      return assignment.assign(this.db, this.seam, this.f, task_id, assignee_ref);
    });
  }
  reassign_task(actor_ref: string, assignment_id: string, new_assignee_ref: string) { // Scope vocabulary 8; Action wiring 16
    return this.gate(actor_ref, "tasks:assign", () => assignment.reassign(this.db, this.seam, this.f, assignment_id, new_assignee_ref));
  }
  recall_assignment(actor_ref: string, assignment_id: string) { // Scope vocabulary 9; Action wiring 17
    return this.gate(actor_ref, "tasks:recall", () => assignment.recall(this.db, this.seam, this.f, assignment_id));
  }

  // [Responsible Actor] — Scope vocabulary 2; Composition state 2; Action wiring 20, 21.
  responsible_actor(actor_ref: string, task_id: string) {
    return this.gate(actor_ref, "tasks:view", (): Answer<string, "not-known"> => {
      if (!this.carries(task_id)) return { refused: "not-known" };
      const a = assignment.active_for(this.db, task_id);
      return { ok: a === "none" ? "unassigned" : a.assignee_ref };
    });
  }
  // [Visible Tasks] — Scope vocabulary 2; Composition state 3; Action wiring 19: a denied read is denied, never empty.
  visible_tasks(actor_ref: string) {
    return this.gate(actor_ref, "tasks:view", (): Answer<Unit[], never> => ({ ok: personalTodo.read(this.db) }));
  }

  private carries(task_id: string) { return personalTodo.read(this.db).some((u) => u.id === task_id); }
}
