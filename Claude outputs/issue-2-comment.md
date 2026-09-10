Traced this properly and the first read I had of it was wrong, so here is the corrected one — it turns out to be a more serious bug than the screenshot suggests.

**Short version: the duplicate chips are cosmetic. The ✗ next to them is not.**

Permissions declares exactly three actions — `grant`, `revoke`, `check` — and no enumerating read at all. `check` answers `permitted | denied` for one `(subject, scope)` pair, and its Invariant 7 is *Denied if and only if no [Active] grant exists matching the queried pair*. So the permission **answer** is set-valued: eleven active grants and one are indistinguishable through every read the spec offers. The bag lives only in the grant store, deliberately (Invariant 10 — grants are never deleted).

The demo's Permissions column is rendering that store. A list of permissions should be `check` projected over the scope set — one entry per distinct scope — which is exactly the singular behaviour you inferred.

Now the part that matters. In `composition.ts`:

```ts
export function revokeGrant(ctx, input: { grant_id: number; reason: string })
  → grants.revoke(tx.db, input.grant_id, ...)
```

Revoke is **by grant id**, and `grantPermission` always calls `grants.create` with no existence check. So with eleven active `invite_actor` grants, clicking one ✗ revokes one record — and by Invariant 7 the actor **still holds `invite_actor`**. An administrator revokes a permission, watches a chip disappear, and access persists. That is a security misread, and it gets worse the more times the permission was granted.

Which makes the two fixes coupled, and that coupling is the real finding: **deduplicating the display alone would make it worse.** Eleven chips collapse to one, the admin clicks ✗, one of ten survivors is revoked, and the chip reappears on refresh. The list must be a set *and* the ✗ must revoke every active grant for the pair — because what `check` answers is the only observable that matters.

**Where the gap actually is.** Not the atom: Permissions permits duplicate grants deliberately and says so, and since it projects no listing read it never has to say what a list means. The gap is in Attributed Permissions Admin, the composition that puts an administrative surface over it. Its write surface is keyed by `grant_id`; its evaluation surface (`permitted`, a passthrough to `check`) is keyed by `(subject_ref, action_scope)`; and it never reconciles them or says what an administrator must do to make `permitted` answer denied. An administrative composition that cannot express *remove this permission* is the defect. That is now logged against the composition as a foundational finding, with the undeclared listing read as a refining one beside it.

Worth saying plainly: my first pass at this blamed the deployment, citing two edge cases about *concurrent* grant issuance. Both are scoped to simultaneous calls, and what you did was sequential — press Grant, wait, press again. The clauses do not cover it. Reading a delegation clause as covering a case it explicitly scoped itself away from is its own kind of mistake, and catching it was worth the detour.

The fix lands with the demo regen rather than as a patch, since the core library is mid-refactor — which is also the honest test: if the spec work is right, the new render should differ here specifically.

Thanks for this. It bought considerably more than a bug fix.
