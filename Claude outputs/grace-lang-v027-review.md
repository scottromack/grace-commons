# GRACE lang v0.27 — review

Against the corpus as of 2026-09-10 (56 pattern files). Reviewed as a spec, not as a proposal: the strong parts are stated briefly, the actionable parts at length.

---

## 1. §1 rests on a measurement that was wrong, and the correction improves the section

Debt #21 recorded seven candidate forms as *earned now — 45–57 of 57 files each*. **That count was case-insensitive.** It measured the English words. Re-measured for the uppercase token in its controlled role:

| form | UPPERCASE files | any-case files |
|---|---|---|
| `MUST` | **3** | 54 |
| `MUST NOT` | **1** | 40 |
| `MAY` | **1** | 54 |
| `EVERY` | **0** | 55 |
| `EXACTLY ONE` | **0** | 47 |
| `WITHIN` | **0** | 47 |
| `ONLY IF` | **0** | 28 |
| `ONLY AFTER` | **0** | 20 |
| `ONLY UNDER` | **0** | 15 |
| `IS AUTHORITATIVE FOR` | **0** | 6 |
| `IS DERIVED FROM` | **0** | 6 |

The three files with an uppercase `MUST` are Attributed Permissions Admin, Audit Trail and Multi-Party Approval — and APA's arrived the same morning.

**So §1's test is ambiguous, and the whole admission list depends on which way it resolves.** *"only forms already earned by repeated use"* — read as *the token in its role*, nothing in §21 qualifies and the grammar is empty. Read as *the concept*, everything qualifies including all four PROVISIONAL entries.

It has to be the concept, for a reason worth putting in the document: **requiring the token to pre-exist is circular.** A controlled form exists to replace the free-prose expression of a recurring idea; its token appears only once someone admits it.

**But then §1 needs its second half, which §19 implies and §1 omits.** Not *does this concept recur* but **does its free-prose expression drift or produce findings?** `before` is in 55 files and most are narrative. `only if` is in 28 carrying real conditions. Recurrence alone is not a case for control — the commonest words in this corpus carry the least obligation.

**Suggested §1 addition:** *A form is earned when its concept recurs across specifications AND its free-prose expression has drifted, been read two ways, or produced a finding. Recurrence alone is not evidence. A count of a candidate form states its own case-sensitivity.*

---

## 2. Two items in §18/§21 to reconsider against that test

**`IS AUTHORITATIVE FOR` is a deliberate introduction, not a discovery — label it.** Six files of any-case use, zero of the form. The *concept* is earned (three consecutive gates turned on it, and the DRY-on-responsibility rule depends on it); the *phrasing* is invented. Admitting it is right, and the frozen rule already covers the case — introduce at one site, propagate after use. But §1 currently claims every admitted form is earned, so this is an unlabelled exception. Naming it as the one deliberate introduction preserves §1's force everywhere else.

**`ONLY IF` is PROVISIONAL at 28 files while `ONLY UNDER` is admitted at 15.** Under either reading of §1 that is inverted, and I can find no justification in the document. Either admit `ONLY IF` or state what disqualifies it.

---

## 3. Three things v0.27 cannot express, which deserve PROVISIONAL slots rather than silence

A gap that is named is a gap the next author can work around. A gap that is silent gets filled with prose.

**Disjunction.** `OR` is forbidden (I9), and closed value sets do not cover the common case: Beacon's own route gate is *`invite_actor` or `grant_permission`*. Two `MUST` rules are conjunction, not disjunction, so this is currently inexpressible. The right resolution is probably **push the disjunction into a declared vocabulary term** — consistent with *one canonical term for one meaning*, and it keeps I9 intact. That needs stating, or authors hit it immediately and reach for prose.

**The degraded guarantee.** This corpus's most distinctive pattern: *"with `journal_fence = none` this invariant degrades from closed to escalated."* Recoverable Invocation carries three, Attributed Permissions Admin one. v0.27 can express the weak rule and the strong rule, but nothing expresses that one **is the degradation of** the other — so reverse diff sees two unrelated rules, and a reader of the strong form never learns it is conditional. Suggested slot: `PROVISIONAL: R25 DEGRADES TO R25b WHEN fence = none`.

**`≥`.** `EXCEEDS` is strict-greater only. Instance start has five conditions, four strict and one not: `run_bound ≥ max(completion_bound, closure_latency + journal_write_bound) + closure_latency` is unwritable. Suggested slot: `PROVISIONAL: AT LEAST`.

*(Arithmetic itself is already handled well — §2's example puts `max(...)` inside a declared term. Worth promoting to a stated rule: **arithmetic lives in term declarations, never in rules.**)*

---

## 4. I4 should be dropped from the parser-enforced list

`I4. Normative prose uses active voice.` It is the only item on that list a parser cannot actually enforce, and it is the exact *infer intent from prose* shape the linter has rejected five times out of five. It is also redundant: given I2 (explicit subject) and §5's `subject modal verb object`, passive voice is structurally impossible.

Listing one unenforceable rule beside twenty-two enforceable ones weakens the claim the others make. Move it to §20 Strict Caveman as style guidance, where it already effectively lives.

---

## 5. What is strong, and why

**§4's forbidden arrows are the direct fix for a defect measured today.** Two of this round's findings were prose that had drifted away from a machine-checkable form which was correct all along — a configuration floor the schedule enumerator had been filtering on correctly for two rounds, and a report-only branch that has been in the formal model's invariant since the gate that wrote it. Neither rotted through carelessness; both rotted because nothing was reading them. `WHY ↛ Normative` removes the second source of truth entirely, which is the only structural fix for that class.

**I15–I17 are the anti-inference invariants and they name this corpus's actual defect shapes.** Gate 12's F1 was an absence being read as coverage — I16 forbids it outright. The duplicate-key finding was multiple outcomes read as exclusive — I17 forbids it unless `EXACTLY ONE` says so.

**§8's BEFORE/AFTER asymmetry is the subtlest thing in the document and I believe it is right.** `MUST NOT … BEFORE` is pure safety — checkable at any instant, no claim that anything happens. Positive `MUST … BEFORE` smuggles a liveness claim (that the thing happens at all) into an ordering claim, and says nothing about the case where the later event never occurs. Routing all liveness through `WITHIN bound` gives it exactly one bounded form. That is the same split Invariant 4 had to be rewritten to make explicit, arrived at independently.

**§13's closed vocabulary with declared record verbs** forecloses the failure where a noun acquires behaviour by association — the shape behind *the store is a bag, the answer is a set, and nobody said which the screen shows*.
