# GRACE lang v0.27 — review

Against the corpus as of 2026-09-10. File set: the 56 Markdown files in `atoms/` and `compositions/` (53 patterns, 3 index pages), with the Recoverable Invocation draft counted apart. Counts are whole word. Quotations match the file they name. Revised after [`grace-lang-v027-review-torvalds.md`](./grace-lang-v027-review-torvalds.md); decisions settled 2026-09-10.

**Verdict.** The core holds: §4, §8, §13, I15–I17. §1's admission test was ambiguous and missing its second half. Of three claimed gaps, one was real. Eight changes for v0.28.

---

## Changes for v0.28

### 1. §1: admit by concept, and only where the prose has failed

```
§21 MAY admit a form ONLY IF its concept recurs across specifications AND satisfies contested.
```

Terms › `contested`: its free-prose expression drifted, was read two ways, OR produced a finding.

For counts, §1 cites `pressure-testing.md` §*Measure the form, not the word*.

*Why.* Read as the token in its controlled role, the grammar is empty: uppercase `MUST` is in 3 files, `MUST NOT` and `MAY` in 1, the rest in 0 (table: `roadmap.md` debt #21). That reading is circular, since a token appears only after its form is admitted. Read as the concept, every form qualifies, and recurrence alone admits noise: `before` is in 55 of 56 files, mostly narrative. The term exists because the condition would otherwise mix `AND` with `OR` (change 3).

### 2. §21: admit `ONLY IF`, make `ONLY UNDER` PROVISIONAL, label `IS AUTHORITATIVE FOR` introduced

*Why.* By change 1, not by count. `ONLY IF` carries gate 12 F1's repair: "The second key holds ONLY IF the act kind declares a `service_identity`." (`recoverable-invocation.md`). `ONLY UNDER` has no controlled use and no finding. `IS AUTHORITATIVE FOR` has an earned concept (three consecutive gates; DRY on responsibility depends on it) and an invented phrasing (6 of 56 files in any case, 0 as the form; the draft writes it three times). §1 claims every admitted form is earned; the label keeps that claim true.

### 3. I9: `OR` inside conditions only

- `OR` appears only inside a condition or a term declaration, never in an obligation or between obligations.
- `OR` is inclusive. An exclusive choice is `EXACTLY ONE OF`.
- A condition uses `AND` or `OR`, not both. A mix goes through a declared term.

Beacon's `/people` gate: `/people MAY serve an actor ONLY IF the actor holds invite_actor OR grant_permission.`

### 4. `≥` is written `MUST NOT EXCEED`

`run_floor MUST NOT EXCEED run_bound.` No `AT LEAST`. `STRICTLY` is not a form.

*Why.* `x MUST NOT EXCEED y` means `y ≥ x`, with no new form. The draft's `STRICTLY` / `NOT STRICTLY` would be a second spelling and `AT LEAST` a third.

### 5. Degraded guarantee: a pairing slot

```
PROVISIONAL: <strong rule> DEGRADES TO <weak rule>.
```

The condition stays on the strong rule's `ONLY IF`. The slot carries none.

*Why.* Gate 12 F1: check 2's second key had no `service_identity = none` branch; check 3 had one. The strong rule never said it was conditional. The repair put the condition on the strong rule, but the pairing is still prose, so reverse diff sees two unrelated rules. A condition in the slot as well would make two owners.

### 6. Arithmetic lives in term declarations, never in rules

Promoted from §2's example.

*Why.* A named expression has one owner, and the round-end diff can match it against the enumerator by name. The `run_bound` floor drifted from the enumerator for two rounds as inline arithmetic. Cost: each of the draft's five instance-start conditions needs a term.

### 7. Delete I4

*Why.* §13 restricts the verb after a modal to declared record verbs, so it already rejects `The actor MUST be granted invite_actor.` I4 is a second owner. Not moved to §20, for the same reason.

### 8. One site is one page

`pressure-testing.md` owns the rule and now says so. The draft's two `IS AUTHORITATIVE FOR` sections conform.

---

## Keep

- **§4, forbidden arrows.** `WHY ↛ Normative` keeps rationale from carrying obligations. It is not the fix for prose drifting from a model: both drifted sentences in gate 12 were normative (Configuration's `run_bound` floor, R1; check 2's second key, F1). The round-end prose-versus-model diff is (`pressure-testing.md` §*Where a claim lives in both a controlled form and a prose form, the prose is the half that rots*).
- **I15–I17, anti-inference.** I16's instance is gate 12 F5: an outage answered `not-known`, absence standing in for coverage. I17's is gate 12 F4: two open intents on one act, each entry read alone as clean.
- **§8, BEFORE/AFTER asymmetry.** `MUST NOT … BEFORE` is safety, checkable at any instant. Positive `MUST … BEFORE` smuggles a liveness claim into an ordering claim. Liveness goes through `WITHIN`. The draft's Invariant 4 splits the same way.
- **§13, closed vocabulary with declared record verbs.** Instance: Attributed Permissions Admin revoked grants while its evaluation answered per pair, so a revoked grant read as a revoked permission. Repaired by [Revoke Permission] (its Decisions, 2026-09-10).
