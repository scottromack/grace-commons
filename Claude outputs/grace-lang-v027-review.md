# GRACE lang v0.27 — review

Against the corpus as of 2026-09-10. File set: the 56 Markdown files in `atoms/` and `compositions/` (53 patterns, 3 index pages), with the Recoverable Invocation draft counted apart. Counts are whole word. Quotations match the file they name. Revised after [`grace-lang-v027-review-torvalds.md`](./grace-lang-v027-review-torvalds.md).

**Verdict.** The core holds: §4, §8, §13, I15–I17. §1's admission test is ambiguous and missing its second half. Of three claimed gaps, one is real. Seven decisions below.

---

## Fixes

### 1. §1: admit by concept, and only where the prose has failed

§1 admits forms *earned by repeated use*. Read as the token in its controlled role, the grammar is empty: uppercase `MUST` is in 3 files, `MUST NOT` and `MAY` in 1, the rest in 0 (table: `roadmap.md` debt #21). Read as the concept, every form qualifies, PROVISIONAL included.

The token reading is circular: a form's token appears only after the form is admitted. So it is the concept. But recurrence alone admits noise: `before` is in 55 of 56 files, mostly narrative.

```
§21 MAY admit a form ONLY IF its concept recurs across specifications AND satisfies contested.
```

Terms › `contested`: its free-prose expression drifted, was read two ways, or produced a finding.

For counts, §1 cites `pressure-testing.md` §*Measure the form, not the word*. It does not restate it.

### 2. `IS AUTHORITATIVE FOR` is introduced, not discovered. Label it.

Concept earned: three consecutive gates turned on it, and DRY on responsibility depends on it. Phrasing invented: 6 of 56 files in any case, 0 as the form. The draft writes it three times, in §*Where the allowance goes* and §*Instance start*. §1 claims every admitted form is earned. Label this one and the claim holds everywhere else.

---

## Keep

- **§4, forbidden arrows.** `WHY ↛ Normative` keeps rationale from carrying obligations. It is not the fix for prose drifting from a model: both drifted sentences in gate 12 were normative (Configuration's `run_bound` floor, R1; check 2's second key, F1). The round-end prose-versus-model diff is (`pressure-testing.md` §*Where a claim lives in both a controlled form and a prose form, the prose is the half that rots*).
- **I15–I17, anti-inference.** I16's instance is gate 12 F5: an outage answered `not-known`, absence standing in for coverage. I17's is gate 12 F4: two open intents on one act, each entry read alone as clean.
- **§8, BEFORE/AFTER asymmetry.** `MUST NOT … BEFORE` is safety, checkable at any instant. Positive `MUST … BEFORE` smuggles a liveness claim into an ordering claim. Liveness goes through `WITHIN`. The draft's Invariant 4 splits the same way.
- **§13, closed vocabulary with declared record verbs.** Instance: Attributed Permissions Admin revoked grants while its evaluation answered per pair, so a revoked grant read as a revoked permission. Repaired by [Revoke Permission] (its Decisions, 2026-09-10).

---

## Decisions

**A. `ONLY IF` and `ONLY UNDER`.** Judge by fix 1's rule, not by count. `ONLY IF` carries gate 12 F1's repair — "The second key holds ONLY IF the act kind declares a `service_identity`." (`recoverable-invocation.md`) — so it is contested. `ONLY UNDER` has no controlled use and no finding.
Proposed: admit `ONLY IF`; `ONLY UNDER` goes PROVISIONAL.

**B. Disjunction.** Writable without `OR`. `(a ∨ b) → s` is two rules. Only `s → (a ∨ b)` needs a term, and a term is a declaration, not a slot. All four uppercase `OR`s in the corpus sit in query filters; none is in an obligation.
Proposed, with no PROVISIONAL slot:

```
EVERY disjunctive condition MUST name a declared term.
```

Beacon's `/people` gate: Terms › `people_manager`: an actor holding `invite_actor` or `grant_permission`. Then `/people MAY serve an actor ONLY IF the actor satisfies people_manager.`

**C. `≥`.** Writable. Put the `max(…)` in a term, `run_floor`, then `run_floor MUST NOT EXCEED run_bound.` The draft already spells it a second way, `NOT STRICTLY` (instance-start condition 4). `AT LEAST` would be a third.
Proposed: `MUST NOT EXCEED`; the draft's five `STRICTLY` lines move to `EXCEEDS` forms. If §5 rejects `MUST NOT EXCEED`, fix the grammar, not the vocabulary.

**D. Degraded guarantee.** The one real gap. Instance: gate 12 F1. Check 2's second key had no `service_identity = none` branch; check 3 had one. The strong rule never said it was conditional. The repair put the condition on the strong rule (`ONLY IF`, decision A). The pairing is still prose, so reverse diff sees two unrelated rules.
Proposed:

```
PROVISIONAL: <strong rule> DEGRADES TO <weak rule>.
```

The condition stays on the strong rule. Writing it into the slot as well makes two owners.

**E. Arithmetic.** §2's example puts `max(…)` in a declared term. Promoted to a rule (arithmetic lives in term declarations, never in rules), it fails all five instance-start conditions in the draft. Either the draft owes five terms, or a numbered condition may carry one inequality.

**F. I4, active voice.** Passive passes I2 and §5: `The actor MUST be granted invite_actor.` If §13 closes the verb slot to declared record verbs, §13 already rejects that: delete I4. If it does not, I4 is the only guard: keep it, enforced on the token after the modal. Needs §13's text. Moving I4 to §20 is wrong either way; it makes a second owner.

**G. One site.** `pressure-testing.md` says to "introduce the form at exactly one site". The draft carries `IS AUTHORITATIVE FOR` in two sections. Is a site a page or a section?
