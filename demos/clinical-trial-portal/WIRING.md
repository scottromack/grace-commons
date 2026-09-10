# Beacon — assembly wiring

*What the generated [RECIPE](./RECIPE.md) cannot infer, and what no constituent composition owns.*

This file governs **all four Beacon renders**. They are one assembly rendered four ways; this directory holds the reference render (Deno · Hono · SQLite · HTMX, live at `beacon-clinical.fly.dev`), and renders 2–4 wire the same compositions to the same declarations.

The RECIPE is an inventory — it lists which atoms and compositions are *present*, and says so itself: *"Capability upper bound, not proof of wiring."* This file is the wiring: what is actually composed, what reads the assembly needs that nobody projects, and which delegated decisions the deployment has made.

**Why it exists.** Beacon's People & Permissions surface assembles [External Onboarding](../../compositions/external-onboarding.md), [Attributed Permissions Admin](../../compositions/attributed-permissions-admin.md), [Login](../../compositions/login.md) / [Session-Gated Authorization](../../compositions/session-gated-authorization.md) and an app-specific trial domain. No single composition owns that page. So when it needed a read none of them projects — *what access does this actor currently hold?* — there was nobody standing where they could see the question, and two renders invented two different wrong answers to it. An assembly that wires compositions is itself a composition, and it inherits their obligations: chiefly **capability provenance** — declare a read your constituents do not project, with its arms and its semantics, rather than reaching into a store.

---

## Compositions wired

| Composition | What it owns here |
|---|---|
| [External Onboarding](../../compositions/external-onboarding.md) | invitation → party → credential; `issueInvitation`, `acceptInvitation`, `revokeInvitation` |
| [Login](../../compositions/login.md) · [Session-Gated Authorization](../../compositions/session-gated-authorization.md) | `login`, `logout`, and the per-route permission gate |
| [Attributed Permissions Admin](../../compositions/attributed-permissions-admin.md) | `grantPermission`, `revokeGrant`, and — once rendered — `revokePermission` |
| [Audit Trail](../../compositions/audit-trail.md) | the attested, hash-chained event log every action above writes to |
| *app-specific* | studies, subjects, visits — no composition; the trial domain is Beacon's own |

---

## Declared reads

Reads this assembly needs that **no constituent projects**. Each carries the same obligations a composition's own reads carry: a named question, a declared multiplicity, and the constituent surface it projects.

### `access_for(actor) → set of action_scope`

**Question:** *what can this actor do right now?*

**Multiplicity: a SET.** One entry per `action_scope`, never one per grant.

**Projects:** [Permissions](../../atoms/permissions.md) `check`, evaluated over the deployment's declared scope set — equivalently, APA's `permitted` passthrough per scope. `check` is set-valued by construction: its Invariant 7 answers Denied **iff no** Active grant matches, so it cannot see multiplicity and neither may this read.

**Why it is not a constituent's.** Permissions declares exactly `grant`, `revoke`, `check` and no enumerating read; APA adds `verify_grant_attribution` and `permitted` and no enumerating read either (APA Ledger 2026-09-10-b). Neither is wrong to omit it — an atom answers one pair at a time, and a composition that administers grants need not enumerate access. The enumeration is the *assembly's* need, because the assembly draws a screen.

**What this read is not.** It is not a listing of the grant store. The grant store is a **bag** keyed by grant — [Permissions](../../atoms/permissions.md) Invariant 10 keeps every grant, and several Active grants on one pair are lawful and often intentional. A list built from that bag answers the access question with attribution data, which is the defect Beacon issue #2 reported.

### `attribution_for(actor, action_scope) → list of grant records`

**Question:** *who conferred this, and when?*

**Multiplicity: a BAG.** One entry per grant, ordered, never deduplicated.

**Projects:** APA `verify_grant_attribution` per `grant_id`.

**Presented as attribution, never as access.** This is the pair of the read above and the reason both must exist separately: the same underlying store answers two different questions with two different multiplicities. The Audit Trail surface is this projection; it must never be deduplicated for tidiness.

### Adding to this list

A read belongs here when the assembly needs it and no constituent projects it. Declare the question, the multiplicity, and the constituent surface it projects. **Do not add a read here without checking every call site of its current implementation** — an earlier draft of Beacon's regen notes asserted a defect from a query's text without reading its callers, and was wrong.

---

## Delegated obligations, answered

Clauses the specs hand *upward* to the deployment. A delegated obligation with no recorded answer is not delegated, it is dropped ([`pressure-testing.md`](../../pressure-testing.md)); this section is where Beacon answers. Seeded from the clauses that bear on the surface issue #2 touched; the full transitive sheet for this wiring is [roadmap](../../roadmap.md) debt #22.

### Duplicate active grants on one `(subject_ref, action_scope)` — **not guarded. Permitted by design.**

*The clauses.* [Permissions](../../atoms/permissions.md), *Concurrent grant proliferation*: **"Composing systems that intend to issue a single authoritative grant should guard against concurrent issuance."** [APA](../../compositions/attributed-permissions-admin.md), *Concurrent issuance of the same grant*: **"Deployments that need single-issuance semantics should compose with Idempotent Reservation or wrap [Issue Grant] with a token-based deduplication layer."**

*Beacon's answer: no guard.* Duplicate Active grants on one pair are permitted, at issue time and sequentially as well as concurrently.

*Because:* the multiplicity is legitimate and will shortly be the normal case. RBAC / Role Management is *(forthcoming)* on the Permissions atom, and under it a role resolves into a set of [Grant] calls — so an actor holding two roles that both include `view_audit` will carry two Active grants on that pair **by design**, with two grantors and two attestations. Guarding issuance now would forbid the case the composition exists to attribute, and would have to be undone when the pattern lands.

*What makes it safe to leave unguarded:* `access_for` is set-valued, so multiplicity is not visible as noise on the access surface; `attribution_for` is where it belongs and where it is informative; and **[Revoke Permission]** is the administrative act that removes a capability whatever conferred it, so an administrator is never asked to count grants. Without those three the answer would be different — this is a decision about the assembly, not a general one.

*Revisit when:* RBAC lands. Pair-scoped revocation then strips grants a role conferred while leaving the role assignment standing, and the next role sync would re-grant them. That reconciliation is the role manager's to specify, and this answer should be re-read against it.

---

## Not declared here

**Presentation.** Chips or a matrix; whether the ✗ should ask *this grant* or *this permission*; whether multiplicity is surfaced at all on the access view. Two competent implementers can disagree and both be right, so it is design, not wiring — and it is the deliberate line this file draws. What the declarations above give a designer is a settled vocabulary to design against: **access view** and **attribution view**, with the multiplicity of each already decided.

**The page's real limitation is not presentational.** Administering a clinical trial by granting `record_visit` to a person one capability code at a time is not a workflow anybody has; roles are. That is the missing pattern above, not a layout problem, and a role matrix drawn over per-capability grants would misdescribe what the system does. The surface stays honestly plain until RBAC lands.
