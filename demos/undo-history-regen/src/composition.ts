// Undo History: the six actions, the event schemas and the replay. The log is
// the truth; the state is a projection of it, rebuilt by the replay; an undo
// appends an event and never asks Personal Todo to reverse a transition.
// Rule numbers are compositions/undo-history.md's.
import type { Database } from "@db/sqlite";
import type { Seam } from "./seam.ts";
import { Faults } from "./faults.ts";
import { eventLog, type LoggedEvent, normalize, personalTodo, type Unit } from "./atoms.ts";
import { freshState } from "./store.ts";

type Forward = "add" | "edit" | "complete" | "delete";
export type Event =
  | { type: "add"; id: string; description: string }
  | { type: "edit"; id: string; prior_description: string; new_description: string }
  | { type: "complete"; id: string }
  | { type: "delete"; id: string; snapshot: Unit }
  | { type: "undo"; undone_event_id: string; undone_event_type: Forward };
export interface Recorded { seq: number; event_id: string; recorded_at: string; event: Event }

type A<T, E extends string> = { ok: T } | { refused: E };
const NONE = new Faults(); // the replay's own writes never fail: the derived state is a projection

export interface Config { payloadCap: number; descriptionCap: number }

export class UndoHistory {
  private constructor(private log: Database, private seam: Seam, private f: Faults, private cfg: Config) {}

  // Event schema 9: the largest event the five schemas carry fits the payload cap.
  static start(log: Database, seam: Seam, f: Faults, cfg: Config) {
    if (largestEvent(cfg.descriptionCap) > cfg.payloadCap) throw new Error("refusing to start: the payload cap is below the largest event");
    return new UndoHistory(log, seam, f, cfg);
  }
  // A deployment that skips Event schema 9: the arm Event schema 8 calls unreachable is reachable.
  static startUnchecked(log: Database, seam: Seam, f: Faults, cfg: Config) { return new UndoHistory(log, seam, f, cfg); }

  events(): Recorded[] {
    return eventLog.rows(this.log, 1).map((e: LoggedEvent) => ({ seq: e.seq, event_id: e.event_id, recorded_at: e.recorded_at, event: JSON.parse(e.data!) }));
  }

  // ---- The replay: Replay 1 through 14 ----
  replay(events = this.events()): Database {
    const undone = new Set(events.flatMap((r) => r.event.type === "undo" ? [r.event.undone_event_id] : [])); // Replay 2
    const db = freshState();
    for (const r of events) {                                      // Replay 1: sequence number order
      if (r.event.type === "undo" || undone.has(r.event_id)) continue; // Replay 3, 4
      // Replay 5 through 13; Wiring decision 5 forbids a new add event, not this one: the surviving event runs as Personal Todo's own forward action, with the
      // event's id and recording instant injected at the atom's seam. It never refuses: it succeeded once.
      const at: Seam = { now: () => r.recorded_at, id: () => (r.event as { id: string }).id };
      const e = r.event;
      const out = e.type === "add" ? personalTodo.add(db, at, NONE, e.description)
        : e.type === "edit" ? personalTodo.edit(db, at, NONE, e.id, e.new_description)
        : e.type === "complete" ? personalTodo.complete(db, at, NONE, e.id)
        : personalTodo.delete(db, NONE, e.id);
      if ("refused" in out) throw new Error(`replay refused ${r.event_id}: ${out.refused}`);
    }
    return db;
  }
  state(): Unit[] { return personalTodo.read(this.replay()); }

  // ---- The forward actions: Action wiring 1 through 14 ----
  add(description: string): A<string, "invalid-description" | "duplicate-active" | "storage-failure"> {
    const id = this.seam.id("task"); // Action wiring 8, 9: the seam's id, never the composition's
    const r = personalTodo.add(this.replay(), { now: this.seam.now, id: () => id }, NONE, description);
    if ("refused" in r) return r; // Action wiring 3, 6
    return this.append({ type: "add", id, description: normalize(description) }, id);
  }
  edit(id: string, new_description: string): A<"ok", "not-known" | "not-editable" | "invalid-description" | "duplicate-active" | "storage-failure"> {
    const db = this.replay();
    const before = db.prepare("SELECT description FROM unit WHERE id = ?").get<{ description: string }>(id)?.description;
    const r = personalTodo.edit(db, this.seam, NONE, id, new_description);
    if ("refused" in r) return r;
    const after = db.prepare("SELECT description FROM unit WHERE id = ?").get<{ description: string }>(id)!.description;
    if (after === before) return { ok: "ok" }; // Action wiring 11 through 14: a no-op edit appends nothing
    return this.append({ type: "edit", id, prior_description: before!, new_description: after }, "ok"); // Event schema 5
  }
  complete(id: string): A<"ok", "not-known" | "not-pending" | "storage-failure"> {
    const r = personalTodo.complete(this.replay(), this.seam, NONE, id);
    if ("refused" in r) return r;
    return this.append({ type: "complete", id }, "ok");
  }
  delete(id: string): A<"ok", "not-known" | "storage-failure"> {
    const db = this.replay();
    const snapshot = db.prepare("SELECT * FROM unit WHERE id = ?").get<Unit>(id); // Event schema 4
    const r = personalTodo.delete(db, NONE, id);
    if ("refused" in r) return r;
    return this.append({ type: "delete", id, snapshot: snapshot! }, "ok");
  }

  // ---- [Undo]: Action wiring 15 through 19 ----
  undo(): A<Forward, "nothing-to-undo" | "storage-failure"> {
    const events = this.events();
    const undone = new Set(events.flatMap((r) => r.event.type === "undo" ? [r.event.undone_event_id] : []));
    const target = events.filter((r) => r.event.type !== "undo" && !undone.has(r.event_id)).at(-1); // Term undo target
    if (!target) return { refused: "nothing-to-undo" };
    const type = target.event.type as Forward;
    return this.append({ type: "undo", undone_event_id: target.event_id, undone_event_type: type }, type);
  }

  // ---- [Read History]: Action wiring 20, 21 ----
  read_history(query: { from: number; to?: number }) { return eventLog.read(this.log, query); }

  // Action wiring 4, 5, 7: append, then the next read replays; Event schema 8: invalid-payload is a deployment fault.
  private append<T>(event: Event, answer: T): A<T, "storage-failure"> {
    const r = eventLog.append(this.log, this.seam, this.f, JSON.stringify(event), this.cfg.payloadCap);
    if ("ok" in r) return { ok: answer };
    if (r.refused === "storage-failure") return { refused: "storage-failure" };
    throw new Error("deployment fault: Event Log answered invalid-payload");
  }
}

// The largest event: an edit carrying two descriptions at the cap, every codepoint escaped by JSON.stringify
// at its widest (a lone surrogate, six characters), with the id at a generous width.
export function largestEvent(descriptionCap: number) {
  const wide = "\u{D800}".repeat(descriptionCap);
  return JSON.stringify({ type: "edit", id: "x".repeat(64), prior_description: wide, new_description: wide }).length;
}
