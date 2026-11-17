// Beacon's own domain: the study, the subject and the visit, the seven permissions with their words, and who sees which subject.
// Rendered from SPEC.md in this directory (The permissions, The study, subjects and visits, What each action writes to the audit trail)
// and from the patterns it names; there is no library atom for these (SPEC.md, Built from).
//
// An action that changes something writes its audit event in the same transaction as the change, so either both are written or neither
// (SPEC.md, What each action writes): the subject or the visit and Audit Trail's attempt record are planned together and committed as one
// (Database 1). The event's `target` is a key of its data beside the payload the table names, since Audit Trail's record carries data alone.
// A person's permission is Permissions' answer to the person's actor reference (Permissions Operation 16); the page's gate is the caller's,
// and these actions check it again where the SPEC names who may do the thing (an action is never a way round a permission).
import { Store, Guard, Unavailable, type Row, type Stmt } from "./store.ts";
import { type Seam, isBlank } from "./seam.ts";
import { type Permissions } from "./permissions.ts";
import { type Trail } from "./external_onboarding.ts";

/** The seven permissions and the words every screen uses (SPEC.md, The permissions). */
export const PERMISSIONS = [
  { code: "invite_actor", words: "Invite people" },
  { code: "grant_permission", words: "Give and take away permissions" },
  { code: "enroll_subject", words: "Enroll subjects" },
  { code: "record_visit", words: "Record visits" },
  { code: "view_audit", words: "See everyone's audit events" },
  { code: "view_own_audit", words: "See my own audit events" },
  { code: "view_all_subjects", words: "See every subject" },
] as const;
export type PermissionCode = (typeof PERMISSIONS)[number]["code"];
export const VISIT_KINDS = ["screening", "week 4", "week 12", "week 24", "end of study"] as const;
export const SUBJECT_STATUSES = ["screening", "enrolled", "withdrawn", "completed"] as const;
export const STUDY = { code: "BCN-OX-201", title: "Beacon Oncology Phase II Trial" } as const;
export const MESSAGES = { visitType: "Visit type is required.", notFound: "Not Found." } as const;

export interface SubjectView { subject_id: string; code: string; status: string; study: string; enrolled_by: string; enrolled_at: string; notes: string | null }
export interface VisitView { visit_id: string; subject_id: string; kind: string; recorded_by: string; recorded_at: string; notes: string | null }

export type Refusal =
  | { refused: "access-denied"; needs: PermissionCode[] }
  | { refused: "not-found"; message: typeof MESSAGES.notFound }
  | { refused: "invalid-request"; message?: string }
  | { refused: "invalid-credential" }
  | { refused: "storage-failure" }
  | { refused: "state-unavailable" };

const STUDIES_T = "studies", SUBJECTS_T = "subjects", VISITS_T = "visits";
const TRIES = 50;

type Subject = Row & { _id: string; code: string; status: string; study: string; enrolled_by: string; enrolled_at: string; notes: string | null };
type Visit = Row & { _id: string; subject_id: string; kind: string; recorded_by: string; recorded_at: string; notes: string | null };

export class BeaconDomain {
  private constructor(private store: Store, private seam: Seam, private perms: Permissions, private trail: Trail, private STUDIES: string, private SUBJECTS: string, private VISITS: string) {}

  /** The study is seeded, one of it: there is no screen to make another (SPEC.md, The study). */
  static async open(store: Store, seam: Seam, parts: { permissions: Permissions; trail: Trail }, cfg: { prefix?: string } = {}): Promise<BeaconDomain> {
    const [STUDIES, SUBJECTS, VISITS] = [STUDIES_T, SUBJECTS_T, VISITS_T].map((t) => `${cfg.prefix ?? ""}${t}`);   // one deployment, the default prefix; a test world names its own
    await store.declare(STUDIES, ["title"]);
    await store.declare(SUBJECTS, ["code", "status", "study", "enrolled_by", "enrolled_at", "notes"]);
    await store.declare(VISITS, ["subject_id", "kind", "recorded_by", "recorded_at", "notes"]);
    if ((await store.read(`SELECT _id FROM ${STUDIES} WHERE _id = $1`, [STUDY.code])).length === 0) {
      await store.commit([store.assertNone(STUDIES, "_id = $1", [STUDY.code], "study-held"), store.put(STUDIES, { _id: STUDY.code, title: STUDY.title })]);
    }
    return new BeaconDomain(store, seam, parts.permissions, parts.trail, STUDIES, SUBJECTS, VISITS);
  }

  /** A person's permissions now: each of the seven Permissions says is held, in the order SPEC.md lists them (the Permissions answer to the actor reference). */
  async held(actor_ref: string): Promise<PermissionCode[]> {
    const out: PermissionCode[] = [];
    for (const p of PERMISSIONS) if ((await this.perms.permitted(actor_ref, p.code)) === "permitted") out.push(p.code);
    return out;
  }
  private async may(actor_ref: string, ...any: PermissionCode[]): Promise<boolean> {
    for (const p of any) if ((await this.perms.permitted(actor_ref, p)) === "permitted") return true;
    return false;
  }

  // ---- Which subjects a person sees (SPEC.md, Who sees which subject) -----------------------------------------------

  /** A subject is seen only by a person who holds `enroll_subject` or `record_visit` to begin with; all of them with `view_all_subjects`, else the ones the person enrolled. */
  private async visible(actor_ref: string): Promise<{ s: Subject[] } | Refusal> {
    if (!(await this.may(actor_ref, "enroll_subject", "record_visit"))) return { refused: "access-denied", needs: ["enroll_subject", "record_visit"] };
    const all = await this.store.read<Subject>(`SELECT * FROM ${this.SUBJECTS}`);
    const seeAll = await this.may(actor_ref, "view_all_subjects");
    return { s: all.filter((x) => seeAll || x.enrolled_by === actor_ref).sort((a, b) => (a.code < b.code ? -1 : 1)) };
  }

  async subjects(actor_ref: string): Promise<SubjectView[] | Refusal> {
    try {
      const v = await this.visible(actor_ref);
      return "refused" in v ? v : v.s.map(subjectView);
    } catch (e) { if (e instanceof Unavailable) return { refused: "state-unavailable" }; throw e; }
  }

  /** A subject the person may see, its visits oldest first; another's answers Not Found as if it did not exist (SPEC.md). */
  async subject(actor_ref: string, subject_id: string): Promise<{ subject: SubjectView; visits: VisitView[]; may_record: boolean } | Refusal> {
    try {
      const v = await this.visible(actor_ref);
      if ("refused" in v) return v;
      const s = v.s.find((x) => x._id === subject_id);
      if (!s) return { refused: "not-found", message: MESSAGES.notFound };
      const visits = (await this.store.read<Visit>(`SELECT * FROM ${this.VISITS} WHERE subject_id = $1`, [s._id])).sort((a, b) => (a.recorded_at < b.recorded_at ? -1 : a.recorded_at > b.recorded_at ? 1 : a._id < b._id ? -1 : 1));
      return { subject: subjectView(s), visits: visits.map(visitView), may_record: await this.may(actor_ref, "record_visit") };
    } catch (e) { if (e instanceof Unavailable) return { refused: "state-unavailable" }; throw e; }
  }

  // ---- [Enroll Subject] -----------------------------------------------------------------------------------------------

  /** The next code: `BCN-` and three digits, one more than the highest in use, starting at `BCN-001`; assigned by the system, never typed (SPEC.md, A subject). */
  private async nextCode(): Promise<string> {
    const used = (await this.store.read<{ code: string }>(`SELECT code FROM ${this.SUBJECTS}`)).map((r) => Number(/^BCN-(\d+)$/.exec(r.code)?.[1] ?? 0));
    return `BCN-${String(Math.max(0, ...used) + 1).padStart(3, "0")}`;
  }

  /** The code the Enroll Subject screen shows, not editable (SPEC.md, Enroll Subject). */
  async nextSubjectCode(actor_ref: string): Promise<string | Refusal> {
    if (!(await this.may(actor_ref, "enroll_subject"))) return { refused: "access-denied", needs: ["enroll_subject"] };
    return this.nextCode();
  }

  async enrollSubject(actor_ref: string, credential: string, notes?: string | null): Promise<SubjectView | Refusal> {
    if (isBlank(actor_ref) || isBlank(credential)) return { refused: "invalid-request" };
    try {
      if (!(await this.may(actor_ref, "enroll_subject"))) return { refused: "access-denied", needs: ["enroll_subject"] };   // SPEC.md, who may enroll
      for (let tries = 0; tries < TRIES; tries++) {
        const code = await this.nextCode();
        const row: Subject = { _id: `subject-${this.seam.idMaterial()}`, code, status: "screening", study: STUDY.code, enrolled_by: actor_ref, enrolled_at: this.seam.now(), notes: isBlank(notes) ? null : (notes as string) };
        const done = await this.write("subject.enrolled", actor_ref, credential, { target: row._id, study: STUDY.code, code }, [   // the event's payload: study, code
          this.store.assertNone(this.SUBJECTS, "code = $1", [code], "code-held"),                                          // two enrollments at once never share a code
          this.store.put(this.SUBJECTS, row),
        ]);
        if (done === "again") continue;
        return done === "ok" ? subjectView(row) : done;
      }
      return { refused: "storage-failure" };
    } catch (e) { if (e instanceof Unavailable) return { refused: "state-unavailable" }; throw e; }
  }

  // ---- [Record Visit] -----------------------------------------------------------------------------------------------

  async recordVisit(actor_ref: string, credential: string, subject_id: string, kind: string, notes?: string | null): Promise<VisitView | Refusal> {
    if (isBlank(actor_ref) || isBlank(credential)) return { refused: "invalid-request" };
    try {
      if (!(await this.may(actor_ref, "record_visit"))) return { refused: "access-denied", needs: ["record_visit"] };   // SPEC.md, who records a visit: the plan's word, not the live render's
      const v = await this.visible(actor_ref);
      if ("refused" in v) return v;
      const s = v.s.find((x) => x._id === subject_id);
      if (!s) return { refused: "not-found", message: MESSAGES.notFound };                                           // another's subject answers as if it did not exist
      if (isBlank(kind) || !(VISIT_KINDS as readonly string[]).includes(kind)) return { refused: "invalid-request", message: MESSAGES.visitType };   // a visit with no kind
      const row: Visit = { _id: `visit-${this.seam.idMaterial()}`, subject_id: s._id, kind, recorded_by: actor_ref, recorded_at: this.seam.now(), notes: isBlank(notes) ? null : (notes as string) };
      const done = await this.write("visit.recorded", actor_ref, credential, { target: row._id, subject: s._id, kind }, [this.store.put(this.VISITS, row)]);   // the payload: subject, kind
      if (done === "again") return { refused: "storage-failure" };
      return done === "ok" ? visitView(row) : done;
    } catch (e) { if (e instanceof Unavailable) return { refused: "state-unavailable" }; throw e; }
  }

  // ---- The change and its event, one transaction -------------------------------------------------------------------------------

  /** Plan the event, commit it beside the change (Database 1), index it after; "again" where the log moved or a guard of the change failed, for the caller to plan again. */
  private async write(action_ref: string, actor_ref: string, credential: string, data: unknown, change: Stmt[]): Promise<"ok" | "again" | Refusal> {
    for (let tries = 0; tries < TRIES; tries++) {
      const p = await this.trail.plan(action_ref, actor_ref, credential, data, 0);
      if ("refusal" in p) return p.refusal.refused === "invalid-credential" ? { refused: "invalid-credential" } : { refused: "storage-failure" };   // nothing is written: the change waits on its event
      try {
        await this.store.commit([...change, ...p.stmts]);
      } catch (e) {
        if (e instanceof Guard && e.guard === "log-moved") continue;                                                 // another event landed first
        if (e instanceof Guard) return "again";                                                                      // a guard of the change (a code taken)
        return { refused: "storage-failure" };                                                                       // a committed nothing
      }
      await this.trail.index(p.indexStmt);
      return "ok";
    }
    return { refused: "storage-failure" };
  }
}

const subjectView = (s: Subject): SubjectView => ({ subject_id: s._id, code: s.code, status: s.status, study: s.study, enrolled_by: s.enrolled_by, enrolled_at: s.enrolled_at, notes: s.notes });
const visitView = (v: Visit): VisitView => ({ visit_id: v._id, subject_id: v.subject_id, kind: v.kind, recorded_by: v.recorded_by, recorded_at: v.recorded_at, notes: v.notes });
