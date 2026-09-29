// Each test names the rule it holds; rule numbers are compositions/undo-history.md's.
import { assertEquals, assertThrows } from "@std/assert";
import { openLog } from "../src/store.ts";
import { manualSeam } from "../src/seam.ts";
import { Faults } from "../src/faults.ts";
import { largestEvent, UndoHistory } from "../src/composition.ts";
import { CONFIG, ok, world } from "./helpers.ts";

const types = (w: ReturnType<typeof world>) => w.uh.events().map((r) => r.event.type);

Deno.test("The walkthrough: an undone complete is pending again, and no transition was reversed", () => {
  const w = world();
  const u1 = ok(w.uh.add("buy milk"));
  ok(w.uh.complete(u1));
  assertEquals(w.uh.state()[0].state, "done");
  assertEquals(w.uh.undo(), { ok: "complete" });
  assertEquals(w.uh.state()[0].state, "pending");
  assertEquals(types(w), ["add", "complete", "undo"]); // Invariant 1.1; Event schema 3
});

Deno.test("Invariant 6.1 and Wiring decision 1 through 3: an undone delete comes back at its id, with its instants", () => {
  const w = world();
  const u2 = ok(w.uh.add("call the vet"));
  w.tick();
  ok(w.uh.edit(u2, "call the vet about Rosie"));
  const before = w.uh.state();
  w.tick();
  ok(w.uh.delete(u2));
  assertEquals(w.uh.state(), []);
  w.tick();
  assertEquals(w.uh.undo(), { ok: "delete" });
  assertEquals(w.uh.state(), before);
  // Event schema 4: the delete carries the snapshot, and the replay never read it (Event schema 6).
  const del = w.uh.events()[2].event as { snapshot: unknown };
  assertEquals(del.snapshot, before[0]);
});

Deno.test("Action wiring 3 and 6: a refused forward action appends nothing", () => {
  const w = world();
  const u1 = ok(w.uh.add("buy milk"));
  ok(w.uh.complete(u1));
  assertEquals(w.uh.add(""), { refused: "invalid-description" });
  assertEquals(w.uh.add("buy milk"), { refused: "duplicate-active" });
  assertEquals(w.uh.complete("task-404"), { refused: "not-known" });
  assertEquals(w.uh.complete(u1), { refused: "not-pending" });
  assertEquals(w.uh.edit(u1, "x"), { refused: "not-editable" });
  assertEquals(types(w), ["add", "complete"]);
});

Deno.test("Action wiring 11 through 14: a no-op edit answers ok, appends nothing, and is no undo target", () => {
  const w = world();
  const u = ok(w.uh.add("call the vet"));
  assertEquals(w.uh.edit(u, "  call the vet "), { ok: "ok" });
  assertEquals(types(w), ["add"]);
  assertEquals(w.uh.undo(), { ok: "add" });
});

Deno.test("Action wiring 16 and 19: nothing-to-undo on a fresh log, and once every forward event is undone", () => {
  const w = world();
  assertEquals(w.uh.undo(), { refused: "nothing-to-undo" });
  ok(w.uh.add("a"));
  ok(w.uh.undo());
  assertEquals(w.uh.undo(), { refused: "nothing-to-undo" }); // an undo event is never a target
});

Deno.test("Invariant 7 and Check 3.3: undo walks back through the surviving events, each named once", () => {
  const w = world();
  const u = ok(w.uh.add("a"));
  ok(w.uh.edit(u, "b"));
  ok(w.uh.complete(u));
  const walk = [w.uh.state()[0]];
  for (const want of ["complete", "edit", "add"] as const) {
    assertEquals(w.uh.undo(), { ok: want });
    walk.push(w.uh.state()[0]);
  }
  assertEquals(walk.map((u) => u && [u.description, u.state]), [["b", "done"], ["b", "pending"], ["a", "pending"], undefined]);
  const named = w.uh.events().flatMap((r) => r.event.type === "undo" ? [r.event.undone_event_id] : []);
  assertEquals(new Set(named).size, named.length);
});

Deno.test("Invariant 7.3: forward actions after an undo leave the undone state out of the walk", () => {
  const w = world();
  const u = ok(w.uh.add("a"));
  ok(w.uh.edit(u, "b"));
  ok(w.uh.undo());              // back to "a"
  ok(w.uh.complete(u));         // forward again
  assertEquals(w.uh.undo(), { ok: "complete" });
  assertEquals(w.uh.state()[0].description, "a"); // "b" is not revisited
  assertEquals(w.uh.undo(), { ok: "add" });
});

Deno.test("Action wiring 5: a failed append answers storage-failure and leaves the state as it was", () => {
  const w = world();
  const u = ok(w.uh.add("a"));
  w.f.arm("log.append");
  assertEquals(w.uh.complete(u), { refused: "storage-failure" });
  w.f.arm("log.append");
  assertEquals(w.uh.undo(), { refused: "storage-failure" });
  assertEquals([types(w), w.uh.state()[0].state], [["add"], "pending"]);
});

Deno.test("Action wiring 8: an undone add's id is never reused", () => {
  const w = world();
  const a = ok(w.uh.add("a"));
  ok(w.uh.undo());
  const b = ok(w.uh.add("a"));
  assertEquals(a === b, false);
});

Deno.test("Action wiring 20: read history answers Event Log's read, and its invalid-query", () => {
  const w = world();
  ok(w.uh.add("a"));
  ok(w.uh.undo());
  const r = ok(w.uh.read_history({ from: 1 }));
  assertEquals(r.map((e) => JSON.parse(e.data!).type), ["add", "undo"]);
  assertEquals(w.uh.read_history({ from: 2, to: 1 }), { refused: "invalid-query" });
});

Deno.test("Replay 7, 10, 12: the instants are the events' recording instants", () => {
  const w = world();
  const u = ok(w.uh.add("a"));
  w.tick();
  ok(w.uh.edit(u, "b"));
  w.tick();
  ok(w.uh.complete(u));
  const [e1, e2, e3] = w.uh.events();
  const s = w.uh.state()[0];
  assertEquals([s.added_at, s.edited_at, s.completed_at], [e1.recorded_at, e2.recorded_at, e3.recorded_at]);
});

Deno.test("Event schema 8 and 9: under a payload cap below the largest event the unreachable arm is reached; the cap is now checked at start", () => {
  const log = openLog(), seam = manualSeam(), f = new Faults();
  const small = { payloadCap: 512, descriptionCap: 1024 };
  const uh = UndoHistory.startUnchecked(log, seam, f, small);
  const u = ok(uh.add("a"));
  assertThrows(() => uh.edit(u, "b".repeat(600)), Error, "invalid-payload");
  assertThrows(() => UndoHistory.start(openLog(), seam, f, small));
  assertEquals(largestEvent(CONFIG.descriptionCap) <= CONFIG.payloadCap, true);
});
