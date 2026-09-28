import { assert, assertEquals } from "@std/assert";
import { openStore } from "../src/store.ts";
import { manualSeam } from "../src/seam.ts";
import { Faults } from "../src/faults.ts";
import { notification, subscription } from "../src/atoms.ts";
import { fanout, type FanoutResult } from "../src/composition.ts";

function world() {
  const db = openStore(), seam = manualSeam(), f = new Faults();
  const sub = (ref: string, scope = "task:assigned") => (subscription.subscribe(db, seam, ref, scope) as { ok: string }).ok;
  const fan = (payload: unknown = { task_id: "t7" }, scope = "task:assigned") => fanout(db, seam, f, { notificationStringCap: 64 }, scope, payload);
  const records = () => db.prepare("SELECT * FROM notification").all<{ recipient_ref: string; payload: string }>();
  return { db, seam, f, sub, fan, records };
}
const ok = (r: ReturnType<ReturnType<typeof world>["fan"]>) => { if ("refused" in r) throw new Error(JSON.stringify(r)); return r as FanoutResult; };

Deno.test("the walkthrough: one record per active subscriber, one payload, a cancel honoured next time", () => {
  const w = world(), ids = ["dev_a", "dev_b", "dev_c"].map((r) => w.sub(r));
  const r = ok(w.fan());
  assertEquals([r.created.length, r.failed], [3, []]);
  assertEquals(new Set(w.records().map((x) => x.payload)).size, 1, "Invariant 2.1");
  subscription.cancel(w.db, w.seam, ids[1]);
  const r2 = ok(w.fan({ task_id: "t8" }));
  assertEquals(r2.created.length, 2);
  assert(r.fanout_id !== r2.fanout_id, "Invariant 8.1");
  assertEquals((notification.status_of(w.db, r.created[1]) as { status: string }).status, "pending", "earlier records unaffected");
});

Deno.test("invalid input takes no id and calls no constituent", () => {
  const w = world();
  w.sub("dev_a");
  assertEquals(w.fan(null), { refused: "invalid-request" });
  assertEquals(w.fan({ t: 1 }, ""), { refused: "invalid-request" });
  assertEquals(w.records().length, 0);
  assertEquals(ok(w.fan()).fanout_id, "fanout-001", "the refused calls took no id");
  assertEquals(ok(w.fan("")).created.length, 1, "an empty payload is a payload (Notification Operation 5)");
});

Deno.test("an unreachable subscription store answers subscribers-unavailable and creates nothing", () => {
  const w = world();
  w.sub("dev_a");
  w.f.arm("sub.read:task:assigned");
  assertEquals(w.fan(), { refused: "subscribers-unavailable" });
  assertEquals(w.records().length, 0);
});

Deno.test("an empty subscriber set still answers an id", () => {
  const w = world(), r = ok(w.fan());
  assertEquals([r.created, r.failed, r.fanout_id], [[], [], "fanout-001"]);
});

Deno.test("a failed create does not stop the fan-out; every subscriber lands in exactly one list", () => {
  const w = world();
  ["dev_a", "dev_b", "dev_c", "dev_d"].forEach((r) => w.sub(r));
  w.f.arm("notif.store:dev_b");
  w.f.arm("notif.hang:dev_c");
  const r = ok(w.fan());
  assertEquals(r.failed.sort(), ["dev_b", "dev_c"]);
  assertEquals(r.created.length + r.failed.length, 4, "Invariant 1.2");
  assertEquals(w.records().length, 2, "a declared storage-failure recorded nothing (Notification Operation 7)");
});

Deno.test("an unrecordable create is indeterminate: a record may exist the result does not name", () => {
  const w = world();
  w.sub("dev_a");
  w.f.arm("notif.lost:dev_a");
  const r = ok(w.fan());
  assertEquals([r.created, r.failed], [[], ["dev_a"]]);
  assertEquals(w.records().length, 1, "Indeterminate outcome 2: not read as no record");
});

Deno.test("a payload over Notification's cap fails every subscriber alike; a bad ref fails alone", () => {
  const w = world();
  ["dev_a", "dev_b"].forEach((r) => w.sub(r));
  assertEquals(ok(w.fan("x".repeat(100))).failed.length, 2);
  const x = world();
  x.sub("dev_a");
  assertEquals(subscription.subscribe(x.db, x.seam, "   ", "task:assigned"), { refused: "invalid-request" }, "Subscription refuses a whitespace-only ref now");
  const long = "u".repeat(80);
  x.sub(long);
  assertEquals(ok(x.fan()).failed, [long], "Subscription caps no length; Notification does");
});
