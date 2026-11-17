// Beacon's own domain (SPEC.md): the study, subjects and visits, the seven permissions and who sees which subject, one test for each thing the file says.
import { test, expect, afterAll } from "bun:test";
import { Store, Unavailable } from "../src/store.ts";
import { PERMISSIONS, VISIT_KINDS, STUDY, MESSAGES, BeaconDomain } from "../src/beacon_domain.ts";
import { beaconWorld } from "./beacon_world.ts";

const store = new Store();
afterAll(() => store.close());
const world = beaconWorld(store);
type W = Awaited<ReturnType<typeof world>>;
const ok = <T>(r: T | { refused: string }): T => { expect((r as { refused?: string }).refused).toBeUndefined(); return r as T; };
const bad = (r: unknown) => r as { refused: string; needs?: string[]; message?: string };
const subjectsOf = async (w: W) => store.read<Record<string, unknown>>(`SELECT * FROM ${w.px}subjects`);

test("SPEC.md The permissions, The study: the seven permissions carry the words every screen uses, the visit kinds stand in their order, and the one study is seeded once", async () => {
  expect(PERMISSIONS.map((p) => [p.code, p.words])).toEqual([
    ["invite_actor", "Invite people"], ["grant_permission", "Give and take away permissions"], ["enroll_subject", "Enroll subjects"], ["record_visit", "Record visits"],
    ["view_audit", "See everyone's audit events"], ["view_own_audit", "See my own audit events"], ["view_all_subjects", "See every subject"],
  ]);
  expect([...VISIT_KINDS]).toEqual(["screening", "week 4", "week 12", "week 24", "end of study"]);
  expect(STUDY).toEqual({ code: "BCN-OX-201", title: "Beacon Oncology Phase II Trial" });
  const w = await world();
  await BeaconDomain.open(store, w.seam, { permissions: w.perms, trail: w.trail }, { prefix: w.px });                // a second start seeds nothing more
  expect(await store.read(`SELECT * FROM ${w.px}studies`)).toHaveLength(1);
});

test("SPEC.md The permissions: a person's permissions now are the ones Permissions answers held, in the file's order", async () => {
  const w = await world();
  const p = await w.person("view_all_subjects", "enroll_subject");
  expect(await w.domain.held(p.ref)).toEqual(["enroll_subject", "view_all_subjects"]);
  expect(await w.domain.held((await w.person()).ref)).toEqual([]);
});

test("SPEC.md A subject, What each action writes: an enrollment records the subject and its subject.enrolled event in one transaction, under the person, with the next code, screening, and the notes", async () => {
  const w = await world();
  const c = await w.person("enroll_subject");
  const s = ok(await w.domain.enrollSubject(c.ref, c.priv, "first of the cohort")) as { subject_id: string; code: string; status: string; study: string; enrolled_by: string; notes: string | null };
  expect(s).toMatchObject({ code: "BCN-001", status: "screening", study: "BCN-OX-201", enrolled_by: c.ref, notes: "first of the cohort" });
  const ev = (await w.events()).filter((e) => e.action_ref === "subject.enrolled");
  expect(ev).toHaveLength(1);
  expect(ev[0].actor_ref).toBe(c.ref);                                                                              // attested under the person
  expect(ev[0].data).toEqual({ target: s.subject_id, study: "BCN-OX-201", code: "BCN-001" });
  expect((await subjectsOf(w))[0]).toMatchObject({ _id: s.subject_id, code: "BCN-001", enrolled_at: "2026-09-01T10:00:00.000Z" });
  expect(ok(await w.domain.enrollSubject(c.ref, c.priv, "  "))).toMatchObject({ code: "BCN-002", notes: null });   // a blank note is none
});

test("SPEC.md A subject: the code is one more than the highest in use, never typed, and two enrollments at once never share one", async () => {
  const w = await world();
  const c = await w.person("enroll_subject");
  expect(await w.domain.nextSubjectCode(c.ref)).toBe("BCN-001");
  await store.commit([store.put(`${w.px}subjects`, { _id: "subject-old", code: "BCN-010", status: "screening", study: STUDY.code, enrolled_by: c.ref, enrolled_at: "2026-08-01T00:00:00.000Z", notes: null })]);
  expect(await w.domain.nextSubjectCode(c.ref)).toBe("BCN-011");                                                    // one more than the highest, gaps and all
  const out = (await Promise.all([1, 2, 3, 4, 5].map(() => w.domain.enrollSubject(c.ref, c.priv)))).map((r) => ok(r) as { code: string });
  expect(new Set(out.map((s) => s.code)).size).toBe(5);
  expect(out.map((s) => s.code).sort()).toEqual(["BCN-011", "BCN-012", "BCN-013", "BCN-014", "BCN-015"]);           // no two share one, none skipped
  expect((await w.events()).filter((e) => e.action_ref === "subject.enrolled")).toHaveLength(5);                    // each with its event
  expect(await w.domain.nextSubjectCode((await w.person()).ref)).toEqual({ refused: "access-denied", needs: ["enroll_subject"] });
});

test("SPEC.md Who may: a person without enroll_subject is answered access-denied naming it, and nothing is written", async () => {
  const w = await world();
  const v = await w.person("record_visit", "view_all_subjects");
  const r = bad(await w.domain.enrollSubject(v.ref, v.priv));
  expect(r).toEqual({ refused: "access-denied", needs: ["enroll_subject"] });
  expect(await subjectsOf(w)).toEqual([]);
  expect(await w.events()).toEqual([]);
});

test("Audit Trail's gate: a credential that does not belong to the person answers invalid-credential, and the subject is not written", async () => {
  const w = await world();
  const c = await w.person("enroll_subject");
  const other = await w.person();
  expect(bad(await w.domain.enrollSubject(c.ref, other.priv))).toEqual({ refused: "invalid-credential" });
  expect(await subjectsOf(w)).toEqual([]);
  expect(await w.events()).toEqual([]);
});

test("SPEC.md What each action writes: where the event cannot be recorded the change is not written (both or neither)", async () => {
  const w = await world();
  const c = await w.person("enroll_subject", "record_visit");
  const s = ok(await w.domain.enrollSubject(c.ref, c.priv)) as { subject_id: string };
  const real = w.trail.plan;
  w.trail.plan = async () => ({ refusal: { refused: "recording-failure", step: "step-2" }, keep: [] });
  expect(bad(await w.domain.enrollSubject(c.ref, c.priv)).refused).toBe("storage-failure");
  expect(bad(await w.domain.recordVisit(c.ref, c.priv, s.subject_id, "screening")).refused).toBe("storage-failure");
  w.trail.plan = real;
  expect(await subjectsOf(w)).toHaveLength(1);
  expect(await store.read(`SELECT * FROM ${w.px}visits`)).toEqual([]);
});

test("SPEC.md What each action writes: another event landing between the plan and the commit is planned again, and the enrollment still lands once", async () => {
  const w = await world();
  const c = await w.person("enroll_subject");
  const real = w.trail.plan;
  let once = true;
  w.trail.plan = async (a, r, cr, d, h) => {
    const p = await real(a, r, cr, d, h);
    if (once) { once = false; expect(await w.at.recordAction("other.event", c.ref, c.priv, {})).toHaveProperty("event_id"); }   // the log moves under the plan
    return p;
  };
  const s = ok(await w.domain.enrollSubject(c.ref, c.priv)) as { code: string };
  w.trail.plan = real;
  expect(s.code).toBe("BCN-001");
  expect(await subjectsOf(w)).toHaveLength(1);
  expect((await w.events()).filter((e) => e.action_ref === "subject.enrolled")).toHaveLength(1);
});

test("SPEC.md What each action writes: a visit's event planned again when the log moves under it, and the visit lands once", async () => {
  const w = await world();
  const c = await w.person("enroll_subject", "record_visit");
  const s = ok(await w.domain.enrollSubject(c.ref, c.priv)) as { subject_id: string };
  const real = w.trail.plan;
  let once = true;
  w.trail.plan = async (a, r, cr, d, h) => {
    const p = await real(a, r, cr, d, h);
    if (once) { once = false; expect(await w.at.recordAction("other.event", c.ref, c.priv, {})).toHaveProperty("event_id"); }
    return p;
  };
  ok(await w.domain.recordVisit(c.ref, c.priv, s.subject_id, "screening"));
  w.trail.plan = real;
  expect(await store.read(`SELECT * FROM ${w.px}visits`)).toHaveLength(1);
  expect((await w.events()).filter((e) => e.action_ref === "visit.recorded")).toHaveLength(1);
});

test("SPEC.md Who sees which subject: with view_all_subjects a person sees all of them, without it only the ones that person enrolled, and another's answers Not Found", async () => {
  const w = await world();
  const a = await w.person("enroll_subject", "record_visit");
  const b = await w.person("enroll_subject");
  const lead = await w.person("record_visit", "view_all_subjects");
  const sa = ok(await w.domain.enrollSubject(a.ref, a.priv)) as { subject_id: string };
  const sb = ok(await w.domain.enrollSubject(b.ref, b.priv)) as { subject_id: string };
  expect((ok(await w.domain.subjects(a.ref)) as { code: string }[]).map((s) => s.code)).toEqual(["BCN-001"]);
  expect((ok(await w.domain.subjects(b.ref)) as { code: string }[]).map((s) => s.code)).toEqual(["BCN-002"]);
  expect((ok(await w.domain.subjects(lead.ref)) as { code: string }[]).map((s) => s.code)).toEqual(["BCN-001", "BCN-002"]);
  expect(bad(await w.domain.subject(a.ref, sb.subject_id))).toEqual({ refused: "not-found", message: "Not Found." });   // as if it did not exist
  expect(bad(await w.domain.subject(a.ref, "no-such-subject"))).toEqual({ refused: "not-found", message: "Not Found." });
  expect(ok(await w.domain.subject(lead.ref, sa.subject_id))).toMatchObject({ subject: { code: "BCN-001" } });
});

test("SPEC.md A subject is seen only by a person who holds enroll_subject or record_visit to begin with: holding view_all_subjects alone is access-denied naming the two", async () => {
  const w = await world();
  const v = await w.person("view_all_subjects");
  expect(bad(await w.domain.subjects(v.ref))).toEqual({ refused: "access-denied", needs: ["enroll_subject", "record_visit"] });
  expect(bad(await w.domain.subject(v.ref, "x")).refused).toBe("access-denied");
});

test("SPEC.md A visit, Who records a visit: a visit has a kind, who recorded it and when, optional notes, and the event; listed oldest first", async () => {
  const w = await world();
  const c = await w.person("enroll_subject", "record_visit");
  const s = ok(await w.domain.enrollSubject(c.ref, c.priv)) as { subject_id: string };
  const v1 = ok(await w.domain.recordVisit(c.ref, c.priv, s.subject_id, "week 4", "stable")) as { visit_id: string; kind: string; recorded_by: string; recorded_at: string; notes: string | null };
  expect(v1).toMatchObject({ subject_id: s.subject_id, kind: "week 4", recorded_by: c.ref, recorded_at: "2026-09-01T10:00:00.000Z", notes: "stable" });
  w.seam.advance(1000);
  ok(await w.domain.recordVisit(c.ref, c.priv, s.subject_id, "screening"));
  w.seam.advance(1000);
  ok(await w.domain.recordVisit(c.ref, c.priv, s.subject_id, "end of study", ""));
  const ev = (await w.events()).filter((e) => e.action_ref === "visit.recorded");
  expect(ev).toHaveLength(3);
  expect(ev[0].data).toEqual({ target: v1.visit_id, subject: s.subject_id, kind: "week 4" });
  expect(ev[0].actor_ref).toBe(c.ref);
  const page = ok(await w.domain.subject(c.ref, s.subject_id)) as { visits: { kind: string; notes: string | null }[]; may_record: boolean };
  expect(page.visits.map((v) => v.kind)).toEqual(["week 4", "screening", "end of study"]);                          // oldest first, by when recorded
  expect(page.visits[2].notes).toBeNull();
  expect(page.may_record).toBe(true);
});

test("SPEC.md A visit: a visit with no kind, or none of the five, is refused with \"Visit type is required.\" and writes nothing", async () => {
  const w = await world();
  const c = await w.person("enroll_subject", "record_visit");
  const s = ok(await w.domain.enrollSubject(c.ref, c.priv)) as { subject_id: string };
  const before = (await w.events()).length;
  for (const kind of ["", "  ", "week 8", "Screening"]) expect(bad(await w.domain.recordVisit(c.ref, c.priv, s.subject_id, kind))).toEqual({ refused: "invalid-request", message: MESSAGES.visitType });
  expect((await w.events()).length).toBe(before);
  expect(await store.read(`SELECT * FROM ${w.px}visits`)).toEqual([]);
});

test("SPEC.md Who records a visit: only a person who holds record_visit (the plan's word); and only on a subject the person may see", async () => {
  const w = await world();
  const enroller = await w.person("enroll_subject");
  const recorder = await w.person("record_visit");
  const s = ok(await w.domain.enrollSubject(enroller.ref, enroller.priv)) as { subject_id: string };
  expect(bad(await w.domain.recordVisit(enroller.ref, enroller.priv, s.subject_id, "screening"))).toEqual({ refused: "access-denied", needs: ["record_visit"] });   // enroll_subject alone does not
  expect(bad(await w.domain.recordVisit(recorder.ref, recorder.priv, s.subject_id, "screening"))).toEqual({ refused: "not-found", message: "Not Found." });   // not this person's subject
  expect((await w.events()).filter((e) => e.action_ref === "visit.recorded")).toEqual([]);
  const page = ok(await w.domain.subject(enroller.ref, s.subject_id)) as { may_record: boolean };
  expect(page.may_record).toBe(false);                                                                              // the Record Visit form is for a person who may record
});

test("Execution Contract Constituent failure 3: a failed read of the database answers state-unavailable and writes nothing", async () => {
  const w = await world();
  const c = await w.person("enroll_subject");
  const real = w.perms.permitted.bind(w.perms);
  w.perms.permitted = async () => { throw new Unavailable(); };
  expect(bad(await w.domain.enrollSubject(c.ref, c.priv)).refused).toBe("state-unavailable");
  expect(bad(await w.domain.subjects(c.ref)).refused).toBe("state-unavailable");
  w.perms.permitted = real;
  expect(await subjectsOf(w)).toEqual([]);
});
