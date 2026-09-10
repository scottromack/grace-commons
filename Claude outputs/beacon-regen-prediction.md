# Beacon regen — the prediction, written before the regen

**Why this file exists.** A regenerated render that no longer shows eleven chips proves nothing on its own: the generator is not deterministic, and "it works now" is indistinguishable from a lucky re-roll. This is the page's own frozen rule applied one layer down — *a plausible remediation is a hypothesis until something distinguishes it from its siblings.* So the differences the spec change should produce are written down **first**, and the regen is checked against them.

Written 2026-09-10, against `compositions/attributed-permissions-admin.md` as of the [Revoke Permission] round. Motivating report: Beacon issue #2.

---

## The spec delta driving it

Three things changed, and only these three should show up in a render:

1. **[Revoke Permission]** exists — `revoke_permission(subject_ref, action_scope, revoker_ref, revoker_credential)`, enumerating the pair's Active grants and performing [Revoke Grant] over each. Returns `ok` / `not-permitted` / `partially-revoked`.
2. **No enumerating read is projected.** An administrative list of an actor's permissions is `permitted` projected over the declared scope set — **one entry per scope, never one per grant.**
3. **`revoke_permission_completion_bound`** is the revocation-side lower edge for the reconciliation leg and Generation acceptance check 5.

Everything else is unchanged by construction: no new proposal format, no change to Invariant 7, no change to checks 1–4 or 6.

---

## The principle, because a regen is most likely to get it subtly wrong

**The audit trail reads the attribution projection; the permissions page reads the access projection.** One store, two projections, and the bug was the access question being answered out of the attribution one.

- **Attribution is a bag, keyed by grant.** Eleven grants are eleven administrative acts, each attested by a named grantor at a named time. Collapsing them destroys evidence. `grant_attribution` and `revocation_attribution` are keyed by `grant_id` for exactly this reason.
- **Access is a set, keyed by `(subject_ref, action_scope)`.** One question, one answer, because Permissions' `check` cannot see multiplicity by construction — its Invariant 7 answers Denied iff *no* Active grant matches.

Nothing was ever wrong with the data. The wrong projection was on screen.

So the mirror-image mistake is now the live risk: **a regen that tidies the Audit Trail by deduplicating it.** Eleven grant events *should* be eleven rows. A dedupe there would be the same category error pointed the other way, and it would be worse, because the permissions page merely misreported state while a deduplicated audit trail destroys the record of who authorised what and when.

---

## Per-render conformance delta

### Render 1 — Deno · Hono · SQLite · HTMX *(`beacon-clinical.fly.dev` — the render issue #2 was reported against; verified in source)*

| Site | Now | Must become |
|---|---|---|
| `domain/grants.ts` → `listForActor` | one row per grant; no `revoked_at` filter in the SQL (every caller filters in application code) | return **one row per distinct `permission_code`**, Active only — this is `permitted` projected over the scope set, and belongs in the query rather than in five callers |
| `views/people.tsx` → the permissions cell | `<Badge label={g.permission_code}>` per grant row | one badge per distinct code |
| `views/people.tsx` → the ✗ form | `POST /grants/${g.id}/revoke` | `POST` keyed by `(grantee_actor_id, permission_id)` |
| `routes/people.ts:36`, `routes/dashboard.ts:21`, `routes/subjects.ts` ×3 | each re-filters `revoked_at === null` by hand | inherit the filter from the query; check each still wants a set rather than a bag |
| `composition.ts` | `revokeGrant(ctx, { grant_id, reason })` only | add `revokePermission`, enumerating then revoking each, one `grant.revoked` event per grant |
| `domain/grants.ts` → `listAll` | same missing filter, **and unreferenced** | delete, or fix and use — dead code carrying a live defect is worse than either |

**A correction to an earlier draft of this file, kept rather than deleted.** It claimed `listForActor`'s missing `revoked_at` filter left revoked chips on screen. It does not: all five call sites filter `revoked_at === null` in application code, so there is **no revoked-chip defect on any render-1 surface**. What remains is a latent hazard only — a function whose doc comment says *"Return all active grants"*, whose SQL does not, and whose correctness therefore depends on five callers each remembering. `listAll` has the same shape and is unreferenced. Worth fixing at the query, not worth calling a bug. *(The error is the one this campaign is about: a query was read and a consequence asserted without checking the callers.)*

**Render 1's access gate is correct**, and better than render 2's. `findActiveFor` in `middleware/require_permission.ts` filters `revoked_at IS NULL` and uses `LIMIT 1` — genuinely set-valued, immune to the multiplicity, and with no bag-of-codes equivalent to render 2's `activeCodesFor`. Render 1's only defect is the one issue #2 reports.

**This is not transcription-wrong against the spec as it stood.** When render 1 was generated, no page said what a listing read should return — that absence is exactly finding 2026-09-10-b, now closed. Two renders built the undeclared read two different ways and both got it wrong, which is the argument for having declared it.

### Render 2 — Next.js 15 · PostgreSQL *(`beacon-clinical-next.fly.dev` — also live; verified in source)*

| Site | Now | Must become |
|---|---|---|
| `auth/permit.ts` → `activeGrantsFor(actorId)` | one row per grant, `WHERE ... revoked_at IS NULL`, `ORDER BY g.id ASC` | keep — it correctly filters Active — but name it as an **attribution** read, not an access read |
| `auth/permit.ts` → `activeCodesFor(actorId)` | `activeGrantsFor(...).map(g => g.code)` — **a bag of codes**, `invite_actor` eleven times | a **distinct** set of codes; this is `permitted` projected over the scope set |
| `app/people/page.tsx` → `activeGrants` per row | rendered one chip per grant | one chip per distinct `code` |
| `app/people/page.tsx` → the ✗ form | posts `grant_id` | posts `(grantee_actor_id, permission_id)` |
| `app/people/actions.ts` → `revokeGrant(formData)` | `composition.revokeGrant(ctx, { grant_id, ... })` | `composition.revokePermission(ctx, { grantee_actor_id, permission_id, ... })` |
| `composition.ts` | `revokeGrant(grant_id)` only | add `revokePermission`, enumerating then revoking each, one `grant.revoked` event per grant |
| Audit Trail view | one row per event | **unchanged** — one row per event, never deduplicated; may *group* by `(actor, requested_at)` for readability, never collapse |

**`activeCodesFor` is the one to watch.** It feeds nav gating and dashboard tiles, and it is a bag today. Membership tests over a bag still answer correctly, so nothing visibly breaks — which is exactly why it survived. It is the same category error as the chips, one layer inward. Note render 2 does *not* have render 1's revoked-grant defect: it filters correctly and fails only on multiplicity.

### Render 4 — MongoDB ghost *(inferred from its own `CORNERS.md`, not re-read)*

`CORNERS.md` item 2 records that its `revokeGrant` deliberately mirrors render 2's behaviour. So it inherits render 2's delta, and its CORNERS entry should be **rewritten rather than deleted** — the note said the port was faithful to a render-2 behaviour that has since been found defective, which is true and worth keeping as history.

### Render 3 — Go headless

No grant surface. **Predicted unchanged**, and if the regen changes it, that is a finding about the regen, not about the spec.

---

## What a reviewer should be able to observe

Stated so each is checkable, and so a miss is attributable.

1. **Grant the same permission three times.** The list shows **one** chip. Before: three.
2. **Then click its ✗ once.** `permitted` for that pair answers **denied**, and the chip is gone. Before: one grant revoked, two still Active, permission still held.
3. **The audit trail shows three `grant.revoked` events**, one per grant, sharing one `requested_at`. Not one event, and not none. A single [Revoke Permission] over Anya's eleven `invite_actor` grants therefore produces **eleven** audit rows in one burst — correct, each separately attested, and the shared `requested_at` is the spec's declared grouping key, so a reader can present them as one administrative act without inventing a field. **A regen that emits fewer rows than grants revoked has broken the audit trail, not tidied it.**
4. **`listForActor` filters Active in the query, and its callers stop re-filtering.** Five hand-written `revoked_at === null` checks collapse to none. Testable without a UI.
5. **Revoking a permission the actor does not hold** answers `not-permitted` — a first-class *nothing to do*, distinguishable from an error.
6. **`activeCodesFor` returns distinct codes (render 2).** Testable directly; no UI needed.
7. **Checks 1–4 and 6 are unchanged**, and check 5's revocation-side lower edge names `revoke_permission_completion_bound`.
8. **The Go render's chain still verifies byte-for-byte** under render 2's canonical contract. This fix touches no record shape, so the cross-language result must survive it. If it doesn't, something changed that shouldn't have.

---

## The trap, restated because it is easy to half-fix

**Deduplicating the display alone makes it worse.** Eleven chips collapse to one; the admin clicks ✗; one of ten survivors is revoked; the chip reappears on refresh. The display fix and the pair-scoped revoke must land together or not at all. Observation 2 above is the one that catches a half-fix.

## Existing data needs no migration — but only if both land

Eleven Active `invite_actor` grants are already in the store. With a set-valued list **and** a pair-scoped revoke, they are handled correctly with no migration: one chip, one click, all eleven revoked, `permitted` answers denied. Ship the display fix alone and the store's multiplicity becomes invisible while remaining live, which is strictly worse than the bug reported.

## What this fix does *not* address

The concurrent-issue race. A grant committed between the enumeration and the last revocation survives the sweep — declared in the spec, not foreclosed. The caller's terminal condition is `permitted` answering denied, and a demo that re-reads after revoking is conforming. A render that *claims* the first `ok` is terminal without supplying per-pair serialization would be over-promising.

Also unaddressed by design: whether Beacon *wants* duplicate grants prevented at issue time. That is a live delegated obligation on Beacon's sheet (roadmap #22) and a separate decision — the multiplicity is lawful and often intentional, and the spec fix deliberately keeps it.
