# Recoverable Invocation — draft gate log (corpus date 2026-08-30)
Five fresh-reader gates on the draft, each a cold reader with the pass questions, the stripped body, and Audit Trail (plus Selective Disclosure for the walkthrough). Every foundational finding was checked against the text before the fix and was real.

| gate | F | R | Rh | what the foundational findings were about |
|---|---|---|---|---|
| 1 | 8 | 17 | 5 | protocol structure: late-landing commit → false abandoned; Close/Refuse without credentials; report-only locks keys forever; probe pairing on payload/window; beyond-horizon report unkeyed; probe outage; sweep lease; counted(n) breaks held check |
| 2 | 6 | 17 | 7 | relative deadline not a fence; lost commit reply has no arm; Resolve refuses escalated; Resolve outcomes fail checks; checks quantify over purged intents; sweep needs try_take |
| 3 | 4 | 15 | 6 | relative deadline after the lease (paused process); closing record purged before intent; journal write lands after sweep re-read; inequality inconsistent |
| 4 | 8 | 19 | 5 | lost journal reply; issue-to-land bound (journal_write_bound); fence conveyance and clock; Resolve abandoned vs check 6; unresolved retention; unrecordable outcome at the sweep; skips unbudgeted |
| 5 | 5 | 11 | 5 | retention edge must derive from the policy period; read-your-writes; run-level bound; allowance twice; between-edges arm |

Trend: rounds 1–2 were protocol structure; rounds 3–5 are the timing and consistency model — fences and their clocks, issue-to-land bounds, retention ordering across purge, read consistency, run bounds. Those are the questions the formal model exists to answer; the prose is now describing a timed two-process system with five clocks, and a sixth prose gate would find the next timing corner rather than settle the model. Next step: derive recoverable-invocation.tla (invocation, sweep, section host, store, journal; the bounds as parameters; twins: no lower edge, a lease that does not expire, a fence-less abandon) and transcribe what it settles back into the prose, then gate once more.

## The model (2026-08-30)

`recoverable-invocation.tla` derived and run through `tools/harness/check.mjs` on the device (node 22.23.2, tla-checker WASM): the correct model holds — 38,394 states, `Safety = TypeOK ∧ Inv1 ∧ Inv2 ∧ Inv4 ∧ Inv5` over discrete time, 28 s on the Mac — and each of three twins is rejected on exactly the invariant it was built to break and no other: `-buggy-death` (the section host releases on the holder's death → Invariant 2, 2,216 states), `-buggy-lease` (the invocation writes past its lease → Invariant 2, 1,340 states), `-buggy-fence` (the sweep abandons a fenceless act → Invariant 5, 957 states). Thirteen reachability probes (each a negated situation the checker must violate) confirm the model exercises abandonment, escalation, the invocation's own close, the sweep's close after a yield and after a crash, a fence-dropped commit, an escalation contradicted by a late landing, a run re-reading and finding the act closed, a run waiting on the other node's section, a closure despite a dead run, a dead run's lease held, a yield with the commit in flight, and a closure under a live-but-paused invocation.

Shape: five components over one act — the invocation (open, commit, outcome, yield, finish, crash), a section host (lease exactly `CompletionBound`, released on return or at expiry only), a store (fenced: lands within `StoreLatency` or drops past the fence instant; fenceless: lands within `LateLanding`), a journal (every write lands within `JournalWriteBound`, read-your-writes), and two sweep runs on two nodes with offset cadences (select at the edge, a blocking take, re-read under the section, probe, issue, hold until landed, return; a death budget of one). Time is scheduled, not fair: it does not advance past a due run, a take that can succeed, or a run's re-read.

What the model established, transcribed into the draft (`ri_fix6.py`):
1. **The section host must not release on death** (draft had "released on the holder's return or death"; the worked crash said "the section releases on death"). A run that dies with its closing write in flight frees the section; the other node's run re-reads before the write lands and closes again. With the lease running out instead, every write issued inside a lease has landed by its expiry. Directional — a Decisions entry.
2. **The closure inequality budgets no dead run.** Probes: with no death budgeted the window must exceed `bound + cadence + write` less one tick (Window 5 holds, 4 breaches for 3 + 2 + 1); with one death budgeted it must exceed that by one more `completion_bound` (Window 8 holds, 7 breaches). The inequality becomes `2 × completion_bound + 2 × clock_skew_allowance + reconciliation_cadence + run_bound < compensation_window`; Configuration, Invariant 4, check 4, and the walkthrough (`30 + 30 + 4 + 60 + 120 < 600`) updated. Directional — same Decisions entry.
3. **The lower edge is not safety-bearing at zero skew.** With `now >= intentLandAt + CompletionBound` removed from the sweep's examine condition, Safety still holds (64,430 states): the section and its lease forbid the second writer; the edge keeps a run's blocking take off live acts (an unbudgeted wait) and carries the allowance. [Reconcile] step 1's rationale rewritten; the planned "no lower edge" twin dropped because it is not a bug the model can reject.
4. **The re-read under the section is load-bearing only because the take blocks.** With an instantaneous take the `SweepSeen` branch was unreachable; with the blocking take (the draft's `take` semantics) a run that waited on the other node's section finds the act closed and writes nothing. No prose change; the draft already had the blocking take.

Harness findings for `tools/harness/README.md`: `\E b \in 1..N : f = [s \in S |-> …]` in Init gives `NoInitialStates` (write `f \in {[…] : b \in 1..N}`); a disjunction of primed branches inside a parameterized action costs about five times per successor (36 s → 8 s once split into one action per branch).

Next: one fresh gate on the transcribed draft — the success-criterion test: semantic and binding findings expected, timing defects not.

## Gate 6 — the success-criterion test (2026-08-30)

| round | foundational | refining | rhetorical | the findings |
|---|---|---|---|---|
| 6 | 3 | 13 | 7 | dead-run term uses the wrong lease; the journal write's lease gate is check-then-act with no fence; read-your-writes is bounded by time-since-issue but the section releases on return |

**Verdict: NOT CLEAN, and the success criterion is not met.** The criterion (recorded before the model was written, so it could not be fitted afterwards) said the post-model gate should return mostly semantic and binding findings, and that a crop of foundational timing defects would mean the model had not absorbed enough of the protocol. All three foundational findings are `timing`. The refining tail did shift as predicted — 5 semantic, 6 structural, 2 timing, **0 binding**: the adopter-facing surface, which is what the compound exists for, held completely.

Each finding was confirmed against the spec text before being accepted: the sweep's own lease is `max(completion_bound, closure_latency)` (`run_bound` entry); `record_action(action_ref, actor_ref, credential, data)` carries no deadline and the corpus declares no `journal_fence`; the visibility requirement is "visible once `journal_write_bound` has elapsed since the append was issued" while the section is "released on the holder's return".

**Why the model missed all three — one cause, three shapes.** At each of the three points the *model was more disciplined than the prose*, and its generosity is what hid the defect:

1. **F2 (the sharpest).** `IssueOutcome` fuses the lease check and the write into one atomic action, so no time can pass between passing `remaining ≥ journal_write_bound` and issuing the write. The pause the spec itself admits is unrepresentable, and the model therefore *encoded* the claim "a write issued inside the lease lands inside it" as a primitive instead of deriving it. The spec refutes itself two sections apart: `commit_fence` says "a relative request timeout is not a fence: it bounds the landing only of a write issued inside the lease, and nothing bounds when a paused process issues one," and then `act_section` gates every journal write on exactly such a relative bound. This is debt #19's *the model proved what it was told* at a finer grain — the failure mode the formal layer was supposed to end.
2. **F3.** The model's `SweepReturn` holds the section until the write has *landed*; the spec releases on `record_action`'s *return*, which its own visibility rule permits to be up to `journal_write_bound` before any other node can read it. The model gave the sweep a discipline the prose does not state.
3. **F1.** The model's sweep lease is `CompletionBound`; the spec's is `max(completion_bound, closure_latency)`, and the successor run arrives a cadence later rather than instantly. The `2 × completion_bound` dead-run term transcribed from the model this session is therefore wrong in the prose — a defect the transcription introduced.

**The methodology finding, for §Formal-model authoring pitfalls:** *an action that fuses a guard with its effect cannot find a check-then-act defect.* Every lease, deadline, or freshness gate in a model must be split into two actions with time allowed between them, or the model proves the gate works by construction. Companion rule: where the model's abstraction is *stronger* than the spec's stated discipline, the model is not validating the spec — it is validating a better spec that nobody will implement.

Next: correct the model at the three points (split guard from effect; release on issue with visibility lagging `journal_write_bound`; a distinct sweep-lease constant), re-run, and let the corrected model dictate the prose fix rather than fixing the prose by hand.

## The model, version 2 (2026-08-30)

The three foundational findings of gate 6 were all model-fidelity gaps, so the model was corrected rather than the prose, and the corrected model was made to say whether each proposed remedy actually closes its defect. Three changes:

1. **Every journal write splits into a gate and an issue**, with time free to pass between them. This is the whole of v2: v1 fused `remaining >= journal_write_bound` with the write, so the pause the spec itself admits was not a behaviour the model could exhibit.
2. **A write has a return instant and a visibility instant**, `return <= visible <= issue + journal_write_bound`, and the section is released on return — as the spec says — rather than on visibility, as v1 had it.
3. **`SweepLease` is its own constant**, so the closure arithmetic is measured rather than assumed.

The two candidate remedies are constants (`JournalFence`, `VisibleOnReturn`), so the twins with each set FALSE **are the prose as written**. Run through `tools/harness/check.mjs` on the device: the model holds at 58,115 states and every one of five twins is rejected — `-buggy-death` (host releases on death, 7,329), `-buggy-reread` (sweep skips the re-read under the section, 11,059), `-buggy-fence` (abandons a fenceless act, 971), `-buggy-journal` (no journal fence, 11,804), `-buggy-visible` (visibility only time-bounded, 9,453).

**What v2 established.**

- **F2 confirmed, and the remedy located.** With `JournalFence = FALSE` — the corpus today, since `record_action(action_ref, actor_ref, credential, data)` carries no deadline — Invariant 2 fails. The counterexample is not the one the gate narrated: it is two *sweep runs*, one paused past its lease, so the defect does not even need the invocation. The prescribed fix is a declared `journal_fence` instance capability, with the degradation stated where a substrate cannot offer one.
- **The `remaining` gate is not what carries Invariant 2 — the fence is.** A controlled 2×2: with the fence, Invariant 2 holds whether the gate is present (58,115 states) or removed (66,150); without the fence it fails either way (11,804 / 3,007). This demotion was not in the gate's findings; the model found it while the twin that removed the gate refused to fail. The gate's real work is to avoid starting a write the fence will refuse. The planned `-buggy-lease` twin was replaced by `-buggy-reread`, which tests something that *is* load-bearing.
- **F3 confirmed.** With visibility bounded only by time since issue, a waiter admitted at a release re-reads before the previous holder's write is visible and closes the act a second time. The fix is to state read-your-writes against the return, which is the event the protocol waits on.
- **F1 confirmed and measured.** Holding everything else fixed, one budgeted sweep-run death raises the smallest sufficient window by exactly the sweep's lease — 3, 5 and 7 for sweep leases of 3, 5 and 7 against a `completion_bound` of 3 — and with no death budgeted the sweep's lease does not enter the arithmetic at all. So the dead-run term is `max(completion_bound, closure_latency)`, not a second `completion_bound`, and the earlier prose understated the window by the difference wherever `closure_latency` is the larger.

**Two authoring rules this round earned, for §Formal-model authoring pitfalls.**

*An action that fuses a guard with its effect cannot find a check-then-act defect.* Every lease, deadline, freshness or liveness gate must be split into two actions with time free to pass between them, or the model proves the gate works by construction. The companion, stated generally: **where a model's abstraction is stronger than the spec's stated discipline, the model is not validating the spec — it is validating a better spec that nobody will implement.** Both of v2's corrections are instances, and so is v1's sweep, which held its section until its write had landed because that is what a careful implementer would do, not what the page said.

*A property that is really liveness, checked as time-indexed safety, needs the stall budgeted.* Without fairness, "pause for ever" is a behaviour of every model, and it starves the act at every window — which reads as a protocol defect and is not one. v2 gives the pause an explicit budget (`MaxPauses`), which keeps the F2 and F3 counterexamples reachable while making the window arithmetic measurable.

**Two harness notes for `tools/harness/README.md`.** The checker treats a primed variable that an action neither assigns nor lists in `UNCHANGED` as unchanged, silently — a variable added to `VARIABLES` and missed in thirteen actions changed no state count and produced no error, so audit every action for full variable coverage rather than trusting a passing run. And an invariant whose antecedent cannot fire inside `MaxTime` — a `Window` larger than the horizon — passes vacuously; check that the horizon exceeds every bound the invariant names.

Next: the seventh gate, on the transcribed draft.

## Gate 6's tail, closed (2026-08-30)

The three foundational findings were closed by correcting the model (above). The remaining twenty — thirteen refining, seven rhetorical — are closed in prose, in one pass with asserted anchors.

**R1 first, because the model's own correction had made it worse.** [Reconcile] step 5's at-risk threshold is a rearrangement of Invariant 4's inequality, and the inequality had just gained the sweep-lease term while the threshold had not. It is now *derived* rather than restated: subtract from the window every term still ahead of an intent the sweep can already see — a cadence, the run's `run_bound`, the one dead run the window budgets, and the allowance the comparison needs — and leave out the two the examine edge has already spent. Stated once, in step 5; Invariant 4 and check 4 carry the inequality it comes from and neither restates it.

**The fence-conditional abandonment (R2) had leaked into four places** — [Refuse]'s prose, the [Recording Failure] term card, and two lines of Edge cases — each of which said the sweep writes `<kind>.abandoned` full stop, where [Reconcile] step 3 writes it only under a declared `commit_fence` and escalates otherwise. Since no atom in the library declares a fence today, the unconditional reading was the one a cheapest-compliant implementer would have taken, and it is the arm that produces a false abandonment.

**Two findings changed a signature**, so every call site was swept rather than the first one patched: `recording-failure(refusal)` gains a second slot for the constituent's own pre-commit code (R6) at all five sites and in the term card, and `landed_by` gains `operator` (Rh7) in the action signature, the adoption arm, and the term card. The operator also joins Invariant 2 as a third writer (R4) — [Resolve] takes the same section on the same key, and under `service_identity = none` the section is the *only* thing keeping an operator and a live invocation apart.

**One fix downstream of the model, not in the gate's list.** [Close] step 2's adoption arm justified itself with "a write issued inside the lease lands inside it" — the claim the model refuted. Rewritten: with a `journal_fence` the arm is unreachable; without one it is reachable and load-bearing rather than defence in depth, and it is a mitigation and not a repair, since the re-read is itself check-then-act and an invocation paused between the re-read and its write still appends beside the sweep's record. That is Invariant 2's declared degradation, and the page now says so where the arm is.

The rest: the retention obligation admits a selector on the `<kind>` prefix and nothing else, with the consequence that kinds with different periods need different journal instances (R3); [Resolve] gains arms for an id with no readable intent and for a purged one, which is `invalid-request` carrying *purged* and never `not-open` (R5); the blocking take's second waiter is bounded by the holder's remaining lease at *its own* arrival (R7); check 3's outage exemption gains the externally-clearable item it cross-referenced (R8); the pairing datum's uniqueness obligation is across nodes rather than a matter of clock resolution (R9); the delta rule states the prefix-closure it needs, notes that the Event Log invariant does not grant it, and adds a full rebuild per cadence (R10); check 1 places an intent in the horizon by `read_record` rather than by arithmetic, since [Resolve] puts no bound between an intent and its outcome (R11); the regulator scenario excepts a superseded abandonment as it excepts a superseded escalation (R12); and `read_invocation`'s signature carries the two `more` flags its prose promised (R13). Rh1–Rh6 are wording, ordering and one missing default.

The draft lints clean. Next: the seventh gate.

## Gate 7 — the success criterion's second attempt (2026-08-30)

| round | foundational | refining | rhetorical | categories (foundational) |
|---|---|---|---|---|
| 7 | 7 | 16 | 6 | 4 timing, 3 structural, 0 semantic, 0 binding |

**Verdict: NOT CLEAN, worse than gate 6, and three of the seven are damage done in the fix round.** Every finding was verified against the page before being accepted.

**Mine, introduced closing gate 6 (F1, F4, F7).** All three come from one act: I added `journal_fence` as an instance capability requirement in a single paragraph, and did not hold it to the standard the page already holds its sibling to. `commit_fence` is declared with a conveyance form, a clock, and an edge widened by one allowance; the journal fence got none of the three. So: its instant is minted on the host's clock and judged on the substrate's, with no edge widened for the gap, which re-admits the very write it was introduced to refuse (F1) — and the page's `clock_skew_allowance` entry still says a cross-seam comparison "never by itself decides a write", which both fences now falsify. Worse, I appended the fence to a list whose closing sentence reads "a deployment that supplies the first three has a conforming reconciliation; one that does not has none and this composition does not start", so the same paragraph now both forbids fenceless operation and specifies its degraded behaviour — and the degradation it specifies is unobservable (Invariant 2 quantified over "writes whose issuers were not paused past their lease", a set no auditor can enumerate) and unimplemented (a lowest-`sequence_number` rule assigned to [Read Invocation], which has no such step) (F4). And the walkthrough's arithmetic is simply wrong: `30 + max(30, 5) + 4 + 60 + 120` is 244, not the 274 I wrote (F7).

**The rule this earns:** *a remedy introduced into a page must be specified to the standard of the nearest thing already there.* The page had a fully specified fence three sections away; the new one should have been written against it clause for clause.

**Pre-existing, and unmasked rather than caused (F2, F3, F5, F6).** The lost-reply read-back concludes absence from `journal_write_bound`, a disclosed SLO, which the page's own `commit_fence` doctrine says decides nothing (F2). Invariant 2 is quantified over *outcome* records while the regulator scenario promises exactly one *closing* — and the formal model's Inv2 counts `outcomeRecords + closingRecords <= 1`, so here the **prose understates what the model proves**, the mirror image of gate 6's pattern (F3). Nothing anywhere relates `compensation_window` to `retention_period`, so a horizon shorter than the window lets an orphan leave the sweep's range unclosed, with check 7 removing it from every check that would notice (F5). And an intent of an unbound act kind is promised a surfacing no step produces (F6).

**The finding about the findings.** Every surviving foundational defect sits in the model's own declared gaps. The model's header says skew is not modeled (F1), and lists the refusal path, retries, purge and [Resolve] as not modeled (F2, F5); the binding table's lifecycle is outside the model entirely (F6); and F3 is the one place the model is *stronger* than the prose. That correspondence is exact, and it makes the NOT MODELED list predictive: **it is the map of where the next gate's findings will be.** The model absorbed the interleavings inside its frame and the prose review has been pushed to the frame's edge — which is the boundary working, but only for what the frame covers. Extending the frame to skew and the retry path would move F1 and F2 from prose judgement to checker verdict.

## The frame metric, and what it says (2026-08-30)

From here every gate records, for each foundational finding, **where it sits relative to the formal model's frame**. The bucket that matters splits three ways, not two, because "inside the frame" conflates two very different failures with different remedies:

| bucket | meaning | remedy |
|---|---|---|
| **outside frame** | the model's own NOT MODELED list covers it | widen the frame, selectively |
| **inside, model wrong** | the model covers it and got it wrong, or silently supplied discipline the page does not state | fix the model — the correspondence is failing |
| **inside, transcription wrong** | the model is right and the prose failed to carry what it proves | fix the transcription, not the model |

Classified:

| gate | outside frame | inside, model wrong | inside, transcription wrong |
|---|---|---|---|
| 6 | 0 | **3** (F1 sweep lease, F2 fused gate, F3 release-on-return) | 0 |
| 7 | **5** (F1 skew, F2 retry, F4 start conditions, F5 purge horizon, F6 bindings lifecycle) | 0 | **2** (F3 Invariant 2 over closings, F7 the arithmetic) |

The trajectory is the result, not the totals. Model-fidelity defects went three to zero once v2 and v3 stopped being kinder than the page, and the residue moved wholly outside the frame. Gate 7 returning *more* findings than gate 6 is therefore not a regression in the model's standing: it is the prose review reaching the frame's edge, which is where it should be reaching. What would be a regression is the middle column filling up again.

Both of gate 7's inside-frame findings are the same shape and worth naming: the model proved something **stronger** than the page went on to claim. Its Invariant 2 counts outcomes and closings together while the page quantified over outcomes alone; it derived the closure term while the page transcribed the arithmetic wrongly. So transcription is now the weak joint, and it fails in the direction of *under*-claiming — the opposite of the failure that started this campaign.

**The two rules this round earned, for §Formal-model authoring pitfalls.**

*A model's NOT MODELED list is a prediction, not a disclaimer.* It names the places where prose is still carrying protocol risk alone, and the next gate's foundational findings will be found there. Five of gate 7's seven were, verbatim. So the list is maintained as a live artifact rather than written once: model v3's now carries the bindings table's lifecycle and the sweep's own lost-reply retry, both of which this round put there deliberately, and both of which are the honest prediction for gate 8.

*A remedy introduced into a page must be specified to the standard of its nearest established analogue.* The page had a fully specified fence — `commit_fence`, with a conveyance, a named clock, and an edge widened by one allowance. The `journal_fence` added in the previous round had none of the three, and produced three of gate 7's seven foundational findings on its own. Rewritten to the analogue clause for clause, it also needed something the analogue did not: the margin on **every** instant it mints, not only the lease's, which the checker established after the first correction still admitted the retry.

## Gate 8 (2026-08-30)

| round | foundational | refining | rhetorical | categories (foundational) |
|---|---|---|---|---|
| 8 | 6 | 12 | 6 | 3 structural, 2 semantic, **1 timing**, 0 binding |

**Verdict: NOT CLEAN — but the criterion's trend line has finally turned.** Timing findings across the last three gates run 3, 4, **1**, and the one survivor (F2) is arithmetic rather than interleaving: nothing in this round is a lease edge, a landing order, or a race. Semantic and structural now dominate, which is the transition the success criterion predicted would follow the model. Binding findings remain at zero for the third gate running — the adopter-facing surface has never once failed.

**Frame classification: 6 outside, 0 inside-model-wrong, 0 inside-transcription-wrong.** Model-fidelity defects stay at zero and transcription defects returned to zero. Every surviving defect is now page-craft outside anything a behavioural model would carry — signature completeness, code collision, whether a stated degradation is checkable.

| gate | outside frame | inside, model wrong | inside, transcription wrong |
|---|---|---|---|
| 6 | 0 | 3 | 0 |
| 7 | 5 | 0 | 2 |
| 8 | 6 | 0 | 0 |

**The prediction surface under-predicted once, and that is worth recording against it.** Five of gate 7's seven sat verbatim on the NOT MODELED list. Of gate 8's six, four correspond to entries on it ([Resolve], journal unreachability, the bindings lifecycle) but **F2 does not**: the window under-budgets a dead run by a whole `run_bound`, and `run_bound` is a *multi-act* quantity — a run's whole backlog — which the model cannot express at all because it carries one act. So the list has a blind spot of a particular shape: **quantities that only exist across many acts are invisible to a one-act model, and will not appear on a NOT MODELED list written from inside it.** Added to the list explicitly.

**The uncomfortable half: three of the six are mine, and one repeats last round's mistake.** F1 — the `journal_fence = none` degradation names three detectors ([Reconcile] step 2, check 2, [Read Invocation]) and all three fail: step 2 iterates only over *open* intents so a doubly-closed act never reaches it, check 2 still quantifies over outcomes alone, and [Read Invocation]'s signature has no `binding-duplicate` field. I wrote that paragraph last round and named three mechanisms without going to any of them. F6 — the [Refuse] re-read I added lands `rejected(not-open)` from a journal read, forty lines after the page states `not-open` is decided "never from a journal read". F5 — [Resolve]'s prose lands `not-known` and `invalid-request(purged)`, both codes I added last round, and neither is in its signature.

**F5 is the same defect as gate 7's R6** (`[Refuse]` exporting `constituent_code` it was never given). Twice now a fix round has added a code to prose and not carried it into the signature a generator builds from. A rule I already half-follow is not working, so it becomes a check instead: **`tools/linter` gains `E-code-not-in-signature` — every rejection code an action's prose lands must appear in that action's signature block.** Prototyped at `code_signature_check.py`: one finding on this draft (F5, exactly), **two across all fifty-five corpus files** (`customer-onboarding`'s `initiate_onboarding`, worth a look on their own account). Quiet enough to gate.

*And a lesson from the prototype itself.* Its first version reported thirteen findings, of which ten were false: a lazy regex over `rejected(...)` truncated at the first inner `)`, so every multi-line signature with nested groups read as declaring almost nothing. **A check whose parser is wrong does not fail loudly — it reports noise, and noise gets waved through.** The parser now matches parens by depth. This is the vacuity lesson relocated: an instrument must be verified against a case whose answer is known before its output is evidence for anything.

## The metric that matters: findings caused by the previous fix round

Counted by attributing every gate-8 finding to text that either predates the previous repair or was written by it. A finding is *caused* if the previous round wrote the sentence at fault, or if the previous round made a pre-existing sentence wrong.

| gate | foundational caused / total | refining caused / total | **caused rate (F+R)** |
|---|---|---|---|
| 7 | 3 / 7 (F1, F4, F7) | 5 / 16 (R4, R6, R7, R10, R11) | **8 / 23 = 35%** |
| 8 | 3 / 6 (F1, F5, F6) | 9 / 12 (R1, R3, R4, R5, R7, R8, R9, R10, R12) | **12 / 18 = 67%** |

**The rate nearly doubled. On this axis the prose is not converging — it is moving the defect frontier, which is exactly the failure mode we named.** Two-thirds of what gate 8 found exists because of what the gate-7 repair wrote. A fix round that generates two findings for every three it closes is not polishing.

**But the character of the caused findings changed completely, and that is the whole of the recommendation.**

Gate 7's self-inflicted set were *protocol* defects: a fence with no clock, no conveyance and no edge; a window term budgeting the wrong lease. Judgement was required to find them and judgement was required to fix them.

Gate 8's are almost entirely **bookkeeping**: a code landed in prose and absent from the signature (F5); three detectors named and none reached (F1); a code used in a place the page's own rule forbids (F6); four call sites left un-swept after the entry declaring the abbreviation obsolete (R5); a count partition that does not add up (R7); a clause assigned to a step that does not contain it (R8); a rule in one section contradicting a rule in another (R12); a claim about "three entries" left standing after a fourth was added (R1). **Ten of the twelve are mechanically decidable — no judgement, only cross-reference.**

So the conclusion is neither "keep gating" nor "the model will absorb it". It is a third thing, and it is the campaign's own logic applied one layer further out:

- **protocol** → the formal layer (done: timing 3, 4, 1 and both inside-frame buckets now empty);
- **internal consistency** → the linter, because a 67% caused rate on mechanically-decidable defects is a tooling gap, not a discipline gap;
- **semantic judgement** → what is left for a fresh reader, which is what the criterion always wanted the gates to be spending themselves on.

The first check of the second class is already prototyped and quiet: `E-code-not-in-signature`, one finding on this draft (F5 exactly), two across fifty-five corpus files, zero false positives after its parser was fixed. Gate 8 names at least four more of the same shape — every "X is stated in section Y" claim is checkable against section Y; every declared partition is checkable arithmetic; every abbreviation an entry declares obsolete is checkable at its call sites.

**Gate 9 is not scheduled.** Running another fresh reader against a page whose next repair will, on this evidence, seed two-thirds of the following gate's findings is spending a reader to measure my own error rate. The order now is: build the checks, run them, repair what they find, and only then spend a gate — on semantics.

---

## The gate-8 repair round — 2026-09-08

The first repair round run with the linter's mechanical checks active against
the draft. Twenty-four findings closed: 6 foundational, 12 refining, 6
rhetorical. Nothing routed.

### What the round did not do: apply the prescriptions

Two of the six foundational fixes departed from what the gate prescribed, and
both departures were forced by evidence rather than taste.

**F2 — the window inequality.** The gate prescribed a second `run_bound` term.
That is still wrong. The correction was derived instead from the page's own
timeline semantics and searched: `window_bound.py` enumerates the schedules the
page admits — where the pre-edge run starts and how long it runs, when each
later run starts, which run dies and when, whether it took the act's section
first — over 432 parameter tuples.

| form | breaches |
|---|---|
| what the page carried | 420 / 432 |
| what gate 8 prescribed (`2 × run_bound`) | 396 / 432 |
| `completion_bound + 2 × skew + 2 × cadence + 3 × run_bound` | 93 / 432 |
| the same, on tuples meeting the headroom obligation | **0 / 288**, slack exactly 1 |

The 93 breaching tuples are *exactly* the ones where `run_bound` is smaller
than one sweep lease plus one closure — so the headroom obligation
(`run_bound ≥ max(completion_bound, closure_latency) + closure_latency`) was
**found by the instrument** rather than added for tidiness, and it is what lets
the sweep's lease drop out of the inequality entirely rather than be
double-charged. A budgeted death involves three runs, not two: the run in
flight when the act crossed the examine edge and lawfully missed it, the run
that dies, and the run that closes.

**This is the frame metric paying out.** F2 landed in the *outside the modeled
frame* bucket at gate 8, and the reason is now precise: the formal model has
leases, fences and a window but no backlog, so it has no `run_bound` to
mis-charge. The right response to an outside-frame timing finding is a smaller
instrument that covers the hole — not a bigger model, and not a hand-checked
sum.

**F3 — the failed pre-check read.** The gate prescribed `recording-failure(intent)`
at [Open] "and the corresponding position elsewhere". Half taken. The nearest
established analogue is [Reconcile]'s own read failure, which carries its own
code, so [Open] got a code rather than a second sense for a write's failure —
and the round then *removed* a code instead of adding three: the sweep's
`enumeration-unavailable` is the same condition at another position and became
`journal-unavailable` too. At [Close], [Refuse] and [Resolve] the act's
existence is already decided when the read fails, so the position's own arm is
the answer and a new code there would have been the collision F6 is about.

### Defects the round itself introduced, and what caught them

Three, all found before delivery:

| defect | caught by |
|---|---|
| `[Journal Unavailable]` marker with no registry entry | **the linter** (`O-term-dangling`) |
| `already-closed(closing_event_id)` colliding with the constituent's own `already-closed`, named two paragraphs away | a hand sweep — renamed `already-accounted` |
| `binding-duplicate` and `binding_duplicate` both live on one page | a hand sweep |

**One of three caught mechanically.** That is the third layer's first real
measurement on a repair round, and it is a modest number honestly obtained: the
linter caught the defect whose shape it already had a check for, and nothing
else. The other two were caught because the round went looking, which is not a
process that scales.

The second is worth naming: repairing a code-collision finding (F6) introduced
a second code collision, against a constituent's code the page names two
paragraphs from the site. Fixing an instance of a shape is not the same as
knowing the shape.

### Two more candidate checks, triaged before building

Both new shapes were measured against the two questions the pipeline now asks
(`pressure-testing.md` §*A check needs a population, not just a rule*):

- **hyphen/underscore split of one identifier on one page** — decidable, stated
  without the word *claims*, trivially parseable. **Population: 0 in 56 files.**
  The only instance was the one this round made and fixed. A check would be
  preventive-only, a second `W-step-reference`, and the population rule says no.
- **a code this page introduces colliding with a code it attributes to a
  constituent** — rejected on the boundary. *Introduces* versus *attributes* is
  a question about what a sentence claims; the corpus carries no machine-readable
  mark for the difference.

Two candidates, two rejections, roughly a minute each. Third and fourth times
the pipeline has predicted a check's cost instead of discovering it.

### Standing

Gate 9 is now the next step and was not run today: this round's caused rate is
unmeasured until a fresh reader looks, and that reading is the point of the
gate. What can be said in advance is that the round closed 6 foundational and
introduced at least 3 defects, of which the third layer caught 1.

---

## Gate 9 — 2026-09-08, fresh reader, post-repair

**7 foundational, 12 refining, 8 rhetorical.** Pass 2 (conceptual independence)
returned **clean** for the first time in this page's life: every capability
attributed to Audit Trail resolves to a line of its projected contract, and the
two places Audit Trail grants nothing are declared here as this composition's
own instance capability requirements.

### The caused rate

| gate | foundational caused / total | refining caused / total | **caused rate (F+R)** |
|---|---|---|---|
| 7 | 3 / 7 | 5 / 16 | **8 / 23 = 35%** |
| 8 | 3 / 6 | 9 / 12 | **12 / 18 = 67%** |
| 9 | 4 / 7 (F2, F4, F6, F7) | 7 / 12 (R1, R2, R3, R4, R7, R10, R11) | **11 / 19 = 58%** |

Down from 67%, still high, and the number by itself says little. What it is
made of says everything.

### What the caused set is made of — the three-layer thesis, tested

| gate | caused findings that are mechanically decidable |
|---|---|
| 8 | **10 of 12** |
| 9 | **1 of 11** |

Gate 8's self-inflicted set was bookkeeping: codes absent from signatures,
counts that did not add up, clauses assigned to steps that did not carry them,
abbreviations left un-swept. That class is **gone**. Gate 9's caused set is
nine semantic findings, one shape already triaged out on population (the
partition, R2 — and note it fired again after being hand-fixed, which is what a
one-instance shape does), and one check candidate that was built and rejected
(R1, below).

**This is the architecture working as specified.** The linter absorbed the
mechanical class; the reader is now spending itself on semantics. That was the
whole claim, and it is the first round with evidence for it.

### The frame metric, and the timing series

| gate | outside frame | inside, model wrong | inside, transcription wrong | foundational timing findings |
|---|---|---|---|---|
| 6 | 0 | 3 | 0 | 3 |
| 7 | 5 | 0 | 2 | 4 |
| 8 | 6 | 0 | 0 | 1 |
| 9 | **7** | 0 | 0 | **0** |

**Zero timing findings.** The success criterion recorded before the model
existed — that a post-model gate should return semantic and binding problems
rather than timing defects — is met on the fourth gate after it.

**Five of the seven foundational findings land on [Resolve] or the retention
purge.** Both are on the model's NOT MODELED list. That list has now predicted
the location of the next gate's foundational findings three gates running,
which is no longer a coincidence and is an instruction: **[Resolve] is the next
component to bring inside the frame.** It is a third writer taking the same
section, with its own clock (F7), its own supersession semantics (F6) and its
own purge interaction (F5) — and the model has two writers.

### R1 as a check candidate: built, self-tested, rejected

Gate 9's R1 — a code an action's signature declares that the action's own prose
never lands — is the **inverse** of the rejected `E-code-not-in-signature`, and
it looked like the cleanest CONTAINS question the pipeline has seen: a
delimited code fence against a delimited section, no reading of any sentence.
Prototyped in `undeclared_landing_check.py`, five self-test cases passing in
both directions including a broken-variant check, corpus population **27
findings across 10 files** — by far the largest yield of any candidate.

It is still rejected, and the reason refines the boundary rather than repeating
it. Of the 27, **27 have the token elsewhere on the page**: chain-of-custody
lands `invalid-credential` for four actions in one shared wiring paragraph that
names all four; reserve-from-pool lands `pool-closed` in its Terms card. Every
one of those dismissals requires deciding whether a sentence written elsewhere
*covers this action* — which is a question about what the sentence claims.

**So the boundary's real test is not whether the rule is decidable, but whether
a finding can be dismissed without reading what a sentence claims.** A rule can
be perfectly mechanical and still be a claims question in disguise, and the
population measurement will not catch it: this candidate had the best
population of any so far and the worst dismissal cost.

---

## The gate-9 repair round — 2026-09-08, and model v4

All twenty-seven findings closed: 7 foundational, 12 refining, 8 rhetorical.
Nothing routed. The round ran **model first**, because five of the seven
foundational findings landed on [Resolve] or the retention purge, and the
model's NOT MODELED list had named both for three gates running.

### Model v4 — [Resolve] as the third writer

v1 to v3 modelled two writers against a page that always had three. v4 adds the
operator: a process that takes the same section, on its own seam reading, and
writes a closing over whatever record stands. Two of gate 9's findings become
constants, so the twin with each turned off IS the page as written.

| run | result |
|---|---|
| main (v4) | 71,249 states, all invariants hold |
| `-buggy-supersede` — a resolution over an escalation carrying `resolved_by` and no `supersedes` | **rejected**: Invariants 2 and 6 (F6) |
| `-buggy-opclock` — the operator's reading one tick ahead, report-only | **rejected**: Invariant 5 (F7) |
| `probe-reportonly-clean` — the same deployment, reading from the seam | **holds**, 32,228 states |
| the other seven twins | all still rejected |
| `Probe_OperatorNeverHoldsSection` / `NeverWrites` / `NeverSupersedes` | all three **rejected** |

**The three probes are new machinery and they are the point.** This model has
already been caught holding an invariant whose antecedent could not fire inside
the horizon, and "all invariants hold" is worth nothing for a behaviour the
configuration cannot reach. A new component now earns its invariants only after
a deliberate falsehood about it fails. `-buggy-opclock` also has a **passing
sibling** differing by one constant, so its violation is attributable to the
clock rather than to report-only mode.

### The wrong turn, which is the useful part

v4's first cut did not terminate inside the harness's window. The cause was not
the seven new variables: the operator's open-intent arm fired wherever an
intent was past the edge — most of the reachable space — so it interleaved with
both sweeps everywhere. **The fix was not a budget, it was a fidelity
correction.** The page admits an operator racing the sweep to an *open* intent
in exactly one deployment: `service_identity = none`, where the sweep writes
nothing. Making that a modelled dimension both shrank the space and made the
model right; the two are the same correction. A budget would have shrunk the
space and left the model wrong.

### Defects the round introduced, and what caught them

| defect | caught by |
|---|---|
| `[Journal Unavailable]`-shaped again: two new Terms cards with no marker using them | **the linter** (`O-term-orphan`) |
| the perwrite twin's hand-written config left behind by three new constants | the harness (`MissingConstants`) — then fixed at the root by deriving that config from the main one |
| a multi-line junction in a top-level definition | the checker's parser |

Three defects, **three caught mechanically, none by hand**. Last round it was
one of three. The `O-term-*` check has now fired on two consecutive repair
rounds against defects the round itself created, which is a gating check
earning its place twice over.

The shape sweep this round ran deliberately and found nothing: no
hyphen/underscore split, no code landed outside its signature, no code declared
and never landed. That sweep exists because the previous round's repair of a
code collision introduced a code collision.

### Standing

Gate 10 is the next measurement, and it measures this round. Two things to
watch in it: whether the caused set stays semantic (gate 8: 10 of 12
mechanically decidable; gate 9: 1 of 11), and whether the NOT MODELED list
predicts again now that [Resolve] is off it — the remaining entries are
pairing, the purge, the refusal path, the escalation's candidate list,
`recovery_intended`, the bindings table's lifecycle, the rejection-code
taxonomy, the derived indexes, the compliance surface, and the sweep's own
lost-reply retry.

---

## Gate 10 — 2026-09-09, fresh reader, post-repair-and-model-v4

**8 foundational, 15 refining, 7 rhetorical.** Up from 7/12/8. The counts went
the wrong way and the composition of them went several ways at once.

### The caused rate, and a third bucket

| gate | foundational caused / total | refining caused / total | **caused rate (F+R)** |
|---|---|---|---|
| 7 | 3 / 7 | 5 / 16 | **8 / 23 = 35%** |
| 8 | 3 / 6 | 9 / 12 | **12 / 18 = 67%** |
| 9 | 4 / 7 | 7 / 12 | **11 / 19 = 58%** |
| 10 | 5 / 8 (F1, F2, F5, F7, F8) | 7 / 15 (R2, R3, R5, R6, R13, R14, R15) | **12 / 23 = 52%** |

Two findings fit neither *caused* nor *pre-existing* and need their own bucket:
**exposed by promotion.** F3 and F4 are both defects in the two
`journal_write_bound` start checks, which have sat in Configuration since an
earlier round and which THIS round copied into Generation acceptance check 4 so
an auditor would actually run them. The round did not write the error; it moved
the error somewhere it could be caught. F4 is the sharper of the two and is
worth stating plainly: `max(completion_bound, closure_latency) > closure_latency
+ journal_write_bound` is **unsatisfiable whenever `closure_latency ≥
completion_bound`**, since it reduces to `0 > journal_write_bound`. So every
conforming instance has `completion_bound > closure_latency`, and the `max` that
exists "so that a slow closure is never cut off by a fast act's bound" protects
a case the start check makes unstartable.

**Promotion is a repair worth making even though it raises the count.** A wrong
check that nobody runs and a wrong check that an auditor runs are not equally
bad, and the second is the one that gets fixed.

### The bookkeeping class came back

| gate | caused findings that are mechanically decidable |
|---|---|
| 8 | 10 of 12 |
| 9 | 1 of 11 |
| 10 | **5 of 12** |

Gate 9's round was small and semantic. Gate 10's round was a **large structural
edit** — a parameter added to six signatures, a fourth derived index, a
disposition matrix, a rename — and the mechanical class returned with it. The
linter had a check for exactly one of the five shapes (the term registry, which
fired twice and was fixed both times before delivery). It had none for the
other four.

### Two of the four are shapes the pipeline triaged OUT on population

This is the finding that matters most, and it is a refutation of how the
population rule was applied rather than of the rule.

- **F7 — the partition still does not partition.** Third appearance: gate 8's
  R7, gate 9's R2, now **foundational**. Each round hand-fixed it and each
  round it came back, because each round added a path and the identity is only
  correct with respect to the paths that exist that day.
- **R3 — a renamed token surviving at a call site.** `terminus = counted(n)` in
  *Declared deviations*, after the rename to `retry_terminus`. Second
  appearance of the shape, and worse than a miss: the round's own sweep
  **printed this line** and the reader judged it fine.

Both were triaged out with the reasoning "one instance across fifty-six files
is a hand-fix wearing a tool's clothes." That measurement was correct and the
conclusion drawn from it was wrong. **Population must be counted in
recurrences, not in instances.** A construct that appears once in the corpus
but is rewritten every round on the page under active development has a
population of one *file* and a population of four *events*, and it is the
second number that decides whether a check pays. The cheap test is now two
greps rather than one: how many instances, and how many times has this shape
been repaired before.

### The frame metric grows a third failure mode

| gate | outside frame | inside, model wrong | inside, transcription wrong | inside, **switched off by a constant** | foundational timing |
|---|---|---|---|---|---|
| 6 | 0 | 3 | 0 | — | 3 |
| 7 | 5 | 0 | 2 | — | 4 |
| 8 | 6 | 0 | 0 | — | 1 |
| 9 | 7 | 0 | 0 | — | 0 |
| 10 | 6 | **1** (F6) | 0 | **1** (F5) | 0 |

**Timing findings stay at zero**, two gates running, which is the model doing
its job.

**F6 is the model being wrong, the first since gate 6.** The model declares that
the intent's return and its visibility are one event, and justifies it: "the
intent is written by the sole holder at the start of its lease, and the only
readers who could race it are held off by the section itself." F6 refutes the
justification. [Open]'s step-3 pre-check read has **no disclosed bound
anywhere**, and step 4's intent write is explicitly exempt from the `remaining`
gate — so an [Open] can spend its whole lease in the read and still issue an
intent that lands after the section has passed to the next waiter. Two live
intents on one `act_key`, which nothing detects, because all three duplicate
surfaces key on `invocation_id` and two invocations carry two of those. **v5
must split the intent write into its gate and its issue like every other write,
and give the under-section read a bound.**

**F5 is new and needs its own name.** Supersession chains — E superseded by A
superseded by O — are *expressible* in v4 and were *switched off* by
`MaxResolves = 1`. So the model neither missed it nor was wrong about it; the
configuration excluded it. The reachability probes invented last round would
have caught it had they asked the right question: they asked *does the operator
ever write*, and the question that was needed is *does the operator ever write
twice*. **A probe should be written for the second occurrence as well as the
first**, because the interesting protocol failures are almost never the first
time something happens.

### Standing

The gate-10 repair round is next and it has three parts that must go in order:
**(i)** model v5 — split [Open]'s intent write, bound the under-section read,
raise `MaxResolves` and add second-occurrence probes; **(ii)** the two checks
the recurrence rule now justifies — a declared partition that must add up, and
a retired token surviving at a call site; **(iii)** the prose repairs, with the
two start checks rederived rather than restated.

---

## The gate-10 repair round, part (i) — model v5, 2026-09-09

### What v5 does

[Open] is split into its four steps — take → read → gate → issue — plus a
returning step, and the intent write carries a **return** instant like every
other write on the page. Two new constants: `IntentGated` (the intent write
passes the same `remaining >= journal_write_bound` gate as every other write)
and `ReadBound` (the disclosed bound on the under-section pre-check read, of
which the page discloses none).

### A modelling error found on the way, and worth naming

v5's first cut let `invPhase` reach "opened" the instant the intent was
*issued*, which let [Yield] release the section with the write still in flight
and made the new invariant fail for a reason the protocol does not admit —
[Yield] is the adopter's `unknown` partition and runs long after [Open]
returned. **v4 could not make that mistake, because v4 landed the intent
atomically.** Splitting a write is exactly where a phase quietly stops meaning
what it used to mean, and the fix carries the page's own guarantee: the section
is released on the holder's RETURN, and a returned record is visible to every
later reader.

### F6's prescribed remedy is refuted — the fourth gate in a row

The gate prescribed "gate the intent write like every other write". Two full
runs say that is aimed at the wrong mechanism.

| configuration | `journal_fence` | intent gate | Inv7 (one live intent) |
|---|---|---|---|
| the twin the gate implies | **on** | **off** | **holds** — full run, all invariants |
| its sibling | on | on | holds (by monotonicity: a stronger guard removes behaviours) |
| **the deployment this library actually has** | **off** | on | **VIOLATED** |

**The fence is the mechanism, not the gate.** With a fence, a write that would
land past the lease is refused, so the intent is visible before the section
passes on whether or not the gate is there. Without a fence — the only
configuration this library offers — a second live intent for one `act_key` is
reachable **even with the gate**, and no surface on the page detects it,
because all three duplicate surfaces key on `invocation_id` and two
invocations carry two of those.

So the load-bearing part of F6's fix is its third clause and not its first:
**the duplicate scan and `binding_duplicate` must count open intents per
`(kind, act_key)`.** The gate is still worth adding — it costs nothing and it
is the page's own rule everywhere else — but it is not what closes the finding.

### The cost: fidelity bought with horizon

| model | horizon | states | result |
|---|---|---|---|
| v4 | 7 | 71,249 | holds |
| v5 | 7 | — | does not finish inside the harness's 180 s |
| v5 | 6 | — | does not finish |
| **v5** | **5** | **21,974** | **holds** |

Four phases and one more variable cost roughly a factor of ten per tick. Two
budget decisions were taken and both are stated where they are taken: the main
configuration sets `ReadBound = 1` and factors the read's duration out into the
Inv7 configurations, exactly as Inv4's window is factored out; and the horizon
drops from 7 to 5. **A shorter horizon is the kind of budget that makes a model
quietly vacuous**, so the probes were re-run at the new one: the operator still
holds the section and still writes at horizon 5, both probes rejected.

### One probe was miscast, and the miscasting is the finding

`Probe_IntentNeverInFlightUnheld` — *an intent is never in flight while the
section is not held by its invocation* — was written as a reachability probe,
which expects rejection. It **holds** under a fence, and that is not a
vacuity failure: it is the property F6 is actually about, stated directly
rather than through a modelled second actor. It belongs in `Safety` as an
invariant, and it fails in the fenceless configuration, which is exactly the
claim. **A probe that holds is either a vacuity failure or an invariant you
wrote in the wrong section**, and telling the two apart is a question about
what you meant, not about the run.

### Remaining in this round

**(i)** finish the model: promote the miscast probe to an invariant, re-run the
supersession-chain probe and the seven existing twins at the new horizon.
**(ii)** the two checks the recurrence rule now justifies — a declared
partition that must add up, and a retired token surviving at a call site.
**(iii)** the prose, with F6 repaired at the mechanism the model names rather
than the one the gate prescribed, and the two start checks rederived.

### Part (i) completed — the full v5 suite at horizon 5

| run | result |
|---|---|
| main v5, `Safety` including Inv8 | **21,974 states, holds** |
| nine twins — death, reread, fence, journal, visible, skew, perwrite, supersede, opclock | **all nine rejected** |
| `probe-fenceless-intent` — no fence, gate ON | **Inv8 VIOLATED** |
| `probe-fenced-ungated-intent` — fence ON, gate OFF | **holds** |
| fence ON, gate ON | holds, by monotonicity from the row above |
| `probe-reportonly-clean` | holds |
| three operator reachability probes | all three rejected |
| `probe-chain` — two supersessions | **rejected**, after two false holds |
| `iso-chain-safety` — Safety with two resolutions | holds |

**The horizon claim is bounded and the bound is evidenced.** All nine twins
still fail at five ticks, so each property's violating witness fits inside the
horizon; the two properties whose witnesses do not — the window, and the intent
landing past its section — have their own configurations. Nothing here claims
anything about behaviour longer than five ticks.

### The chain probe held twice, and both reasons were mine

The first hold was a configuration error: the probe pushed the sweeps out to
shrink the space, which removed the only thing that triggers the operator, so
the operator never acted at all. The second was worse. **The operator's phase
machine was terminal** — `OpReturn` set `opPhase` to "done" and nothing
returned it to "idle" — so `MaxResolves` was never the binding constraint and
the round's careful raising of it changed nothing.

Both times the honest-sounding report would have been "raised the budget, still
holds", and both times that sentence would have been false about the reason.
Gate 10's F5 said the behaviour was *expressible and switched off by a
configuration constant*; the behaviour was switched off by a **phase**, and the
constant named in the configuration was innocent. **When a probe holds, find
the switch that is actually off — it is rarely the one you documented.**

### What the model does NOT say about F5

The chain is now reachable, but the model **counts** supersessions and does not
**identify** them: a chain (E superseded by A superseded by O) and a
double-naming of one record (E ← A, E ← O) are the same state to it. So the
transitivity repair — *the standing closing is the one no other closing names* —
is a **prose** repair and is not model-confirmed, and the NOT MODELED list says
so. Naming which record a supersession names is the obvious next extension and
the list has now predicted three gates running.

## Part (ii) — the two checks the recurrence rule justified, both rejected

Zero checks built, and the reason is now a rule rather than a judgement call.

| candidate | dismissible without reading? | population | **would its decidable form have caught the defects?** |
|---|---|---|---|
| a declared partition must add up | yes | 1 instance, **3 recurrences** | **no — runs clean on the one instance that motivated it** |
| a retired token surviving at a call site | no | **178 instances**, 1 real | no — the 177 are the corpus's naming convention |

**The first is the sharper result and it names a gap in the triage.** The
recurrence rule was right: the partition had cost three hand-fixes and
escalated from refining to foundational, so of course it looked like a check
worth building. Its decidable form — *every name in an `a + b + c = d`
expression is a field of that action's declared return* — **passes on the very
instance that motivated it.** The defect was never an undeclared name; it was a
path falling into no bucket, and no parser can see that. The check would have
been built, would have run green, and would have prevented nothing, while
carrying a gating check's authority.

The second is the ordinary kind of rejection: 178 instances of which one is a
defect, and separating them means knowing that `intent_event_id` is a distinct
field rather than a stale name, which is a claims question.

**So the pipeline's triage is now three questions, in order:** can a finding be
dismissed without reading what a sentence claims; does the shape recur often
enough to be worth checking; and *does the mechanical shadow of the shape cover
the defects that made you want it*? The third catches a check that would run,
pass, and lie — and it is answerable before the check exists.

Both defects go back to part (iii) as hand-fixes, which is where they were
always going to be settled.

## Part (iii) — the prose, 2026-09-10

All thirty findings closed: 8 foundational, 15 refining, 7 rhetorical. The two
defects part (ii) handed back are among them.

**F6 is repaired at the mechanism the model proved, not the one the gate
prescribed.** The gate said gate the intent write; the model says the fence
earns the property and the gate is neither necessary nor sufficient. So the
page now: adds the gate anyway (it is the rule for every other write and it
costs nothing), gives the under-section read a disclosed `read_bound` — three
actions were spending an unbounded read inside a lease — and, the load-bearing
part, **re-keys the three duplicate surfaces**. A duplicate is now two
unsuperseded closings on one `invocation_id` **or two open intents on one
`(kind, act_key)`**, because two invocations carry two ids and every surface
keyed on the id alone was blind to the commonest duplicate a fenceless
substrate produces. The page says in as many words that a deployment which adds
the gate and reads it as the remedy has fixed nothing.

**F4 was the round's most serious arithmetic finding and it came from
promotion.** `max(completion_bound, closure_latency) > closure_latency +
journal_write_bound` reduces to `0 > journal_write_bound` whenever
`closure_latency` reaches `completion_bound`. Every instance that could start
therefore had `completion_bound > closure_latency`, the `max` was identically
`completion_bound`, and the case it was written to protect could not be
configured. The lease is now stated directly — `closure_latency +
journal_write_bound` — and the schedule enumeration was re-run under the new
definition **before** the prose was written: the window inequality holds on all
936 tuples meeting `run_bound ≥ 2 × closure_latency + journal_write_bound`,
with the same one tick of slack. F3 went the same way: the act's lease is
checked against everything spent under it, two reads and two writes and the
commit, where it had been checked against one write.

**F5's repair is prose and the page says the model does not confirm it.**
Supersession is transitive — the standing closing is the one no other closing
names — and the Ledger's NOT MODELED list carries the reason: the model counts
supersessions without identifying them.

**F1 is this campaign's cleanest instance of a repair damaging its own page.**
The previous round fixed [Refuse]'s step order in the paragraph's opening
sentence and left the old order six sentences later, in the same paragraph. The
action had no numbered steps, so that paragraph *was* its normative sequence
and it gave two incompatible ones. It has numbered steps now, and the heading
says why.

Linter clean; the deliberate shape sweep on this round's five new tokens found
nothing.

---

## Gate 11 — 2026-09-10

**9 foundational, 17 refining, 5 rhetorical.** Third consecutive rise in the
foundational count.

### The caused rate is the highest it has ever been

| gate | foundational caused / total | refining caused / total | **caused rate (F+R)** |
|---|---|---|---|
| 7 | 3 / 7 | 5 / 16 | **35%** |
| 8 | 3 / 6 | 9 / 12 | **67%** |
| 9 | 4 / 7 | 7 / 12 | **58%** |
| 10 | 5 / 8 | 7 / 15 | **52%** |
| 11 | **8 / 9** | 11 / 17 | **19 / 26 = 73%** |

Eight of nine foundational findings exist because of the previous round. Only
F1 — the action payloads not carrying `act_key`, which the Primitive policies
section has claimed they do for many rounds — predates it.

### Sixteen of the nineteen are ONE shape

**An obligation introduced in one place and not carried to the places that must
honour it.**

- Supersession was made transitive at [Resolve] and left pairwise at the three
  surfaces the same paragraph names (F2).
- A second duplicate key was added and the page's own report-only mode, which
  admits several open intents *by design*, was not exempted from it (F3).
- The last producing source of `not-open` was deleted and the code left
  exported by two signatures (F4).
- A credential pre-check was written for [Resolve] against a substrate surface
  Audit Trail does not project (F5).
- **A `closure_latency` floor was added and the walkthrough eight lines below
  it breaches it** — `read_bound = 2`, `journal_write_bound = 3`,
  `closure_latency = 5` against a floor of 8 — so under the page's own worked
  bindings the sweep can never land a closure (F6).
- Check 3 was re-keyed onto an outage record that only the journal branch has a
  producer for (F8).
- A state machine was specified for `compliance_surface` while the sentence
  three sections away still says there is no composition-owned middle (F9).
- And the partition, for the **fourth** consecutive round — this time
  self-contradicting inside the paragraph the last round rewrote: *`skipped`
  carries every act the run examined, and only those*, with path 5 reading
  *every act still unexamined* (F7).

**The round did run a sweep, and the sweep was over tokens.** It found nothing,
correctly: no split spellings, no unlanded codes, no orphan registry entries.
Every one of these defects is in an **obligation**, which a token sweep cannot
see. Sweeping the wrong thing carefully is indistinguishable, from the inside,
from sweeping the right thing.

### The measurement that reframes the campaign

| gate | body | foundational | **KB per foundational** |
|---|---|---|---|
| 8 | 118.9 KB | 6 | 19.8 |
| 9 | 137.6 KB | 7 | 19.7 |
| 10 | 152.4 KB | 8 | 19.1 |
| 11 | 163.9 KB | 9 | **18.2** |

**The defect density is flat.** One foundational finding per ~19 KB of body,
four gates running, while the body grew 38% and the foundational count grew
50%. The repairs are not reducing the density; they are growing the
denominator, and the count follows the size.

That is a different problem from the one this log has been tracking. It is not
that the repairs are careless — the caused findings are, individually, the kind
a careful reader catches. It is that **an obligation added to a page this large
has a propagation cost the round does not pay, and the next gate charges it**,
and every round adds obligations because every finding's fix is an obligation.

Two responses are available and they are not the same:

1. **Pay the propagation cost explicitly.** End every round with an *obligation
   sweep* rather than a token sweep: for each normative statement the round
   introduced, enumerate the sites that must honour it and check each. That is
   a checklist derived from the round's own diff. A numeric subset of it is
   mechanically checkable — *every worked example's bound values satisfy every
   inequality the page declares* would have caught F6 outright — and is worth
   putting through the three triage questions.

2. **Stop adding surface.** A page whose defect density is constant gets better
   only by getting smaller. Four rounds of repair have added 45 KB and three
   foundational findings; the same effort spent extracting the fence, the
   lease, the findings surface and the duplicate machinery into atoms this page
   *cites* would reduce the surface each round has to propagate across.

**Gate 12 is not the next step.** Running another fresh reader against a page
whose next repair will, on this evidence, seed three quarters of the following
gate's findings measures the repair rate and nothing else.

---

## Lease extracted — 2026-09-10

The first extraction this library has made on **recurrence evidence rather than
on shape**. `atoms/lease.md`, `draft`, six invariants, four operations, no
records.

**Why one atom and not two.** The obvious split is the grant (a per-key section)
from the fence (a deadline handed downstream). Taking it would have preserved
exactly the propagation the extraction exists to remove: **a fence is a terminus
handed to another party**, and stating it in two places is how the two got out
of step in the first place. So the atom covers both, and the paragraph that
explains why the allowance is minted into the instant rather than applied at the
reading is written once.

**What it refuses to own**, which is as important as what it owns: which key
protects which work, and how long a grant must last. Both stay with the
composing pattern. An atom that took them would have absorbed the thing that
differs between the patterns that use it.

**Its hard rule carries a proof rather than an argument.** Invariant 3 — death
is not observable, and no host may free a key early on a belief that a holder is
gone — is the formal model's `-buggy-death` twin, rejected. A pattern citing the
atom inherits that rather than restating it, which is one obligation fewer to
propagate per pattern.

**The linter found both propagation sites of the extraction itself**, on the
first run: a Ledger `last gate` line in the wrong grammar, and the corpus count
claim in the roadmap. That is the obligation sweep working mechanically on the
one class where it can — adding a file is an obligation with known sites — and
it is worth noticing that the sweep's first real use caught two things a token
sweep never would.

One thing the count exposes: `E-count-drift` compares a claim about **grounded**
patterns against a count of pattern *files*, so a `draft` atom drifts it. The
claim was written to keep the number honest by naming the discrepancy in the
same sentence. The check's imprecision is now recorded rather than worked
around silently.

**Next: shrink Recoverable Invocation against the atom, then gate 12.** Gate
12's density is the experiment — a page that cites the atom rather than
restating it should carry fewer obligations to propagate, and therefore fewer
findings per kilobyte. If the density does not move, the problem is not lease
semantics and the extraction queue needs a different head.

## Step 3 — Recoverable Invocation shrunk against the atom, 2026-09-10

**185,741 → 182,187 bytes. 3,554 removed, 1.9%.**

What came out is what the atom owns: the four operations' semantics, the
waiter's bound, release-by-a-non-holder, released-on-return-or-expiry-never-on-
death, and the two-clock minting rule both fences restated. `try_take` went
entirely — the atom declares it and this page never had a caller, which a fresh
reader noticed before the atom existed. What stayed is every **binding** of the
atom (which key, which holder, how long, which arm maps to which code) and
every argument that is about this protocol rather than about leases — in
particular the wiring decision that the fence and not the lease gate carries
Invariant 2.

The citation is correct and the page is better for it. **The number is the
finding.**

### The experiment as designed is underpowered, and it is better to say so now

At a density of ~19 KB per foundational finding, removing 3.5 KB predicts
removing **0.19 findings**. That is noise. Gate 12 cannot detect this
extraction, and a gate 12 that comes back at 8 or 9 foundational would tell us
nothing about whether extraction works.

### Why: the queue's head was chosen on cumulative evidence, not current

Classifying every foundational finding this page has produced by whether the
Lease atom now owns the obligation behind it:

| gate | foundational | lease-owned |
|---|---|---|
| 6 | 3 | 2 |
| 7 | 7 | 3 |
| 8 | 6 | 0 |
| 9 | 7 | 1 |
| 10 | 8 | 3 |
| 11 | 9 | **1** |

Ten of forty across six gates — a real share, and **a declining one.** Lease
semantics dominated gates 6 and 7, were argued out over gates 8 to 10, and by
gate 11 accounted for one finding of nine. The extraction was chosen on the
cumulative record, where lease is the largest single source, and the cumulative
record is the wrong measure: **an extraction removes future obligations, so the
queue's head should be chosen by where the obligations are NOW.**

By that measure the head should have been the **findings surface** — gate 11's
F9 says in as many words that `compliance_surface` is a state machine no atom
names, and F8 and F3 are both obligations of it — or the **duplicate and
supersession machinery**, which produced F2, F3 and F5 of gate 11 and F5 and F6
of gate 10.

### What to measure instead

Density cannot see one extraction. **Findings by obligation source can**, and it
is directly attributable: if gate 12 returns zero findings whose obligation the
Lease atom owns, the extraction worked for its class whether or not the page's
density moved. The baseline is the table above — one in gate 11, three in gate
10.

So gate 12 gets two questions rather than one: *did the density move* (expected:
no, and that is not evidence against extraction), and *did the lease-owned class
go to zero* (which is the actual claim).

## Owner consolidation — the supersession rule, 2026-09-10

The decision rule sharpened: **DRY on responsibility, not on nouns — one
authoritative owner per obligation.** A repeated *use* is composition and is
what a library is for. A repeated *ownership* is duplication, and it is what
propagates badly, because a rule stated in four places is a rule four repair
rounds must each find four times.

**That test has two cures, and this campaign had been reaching for only one.**

| candidate | owners | cure | result |
|---|---|---|---|
| lease semantics | 2 **patterns** (this page, Audit Trail) | extract to an atom both cite | **−3,554 bytes** |
| the supersession rule | 4 **sites in one page** + a fifth restatement | one statement, four citations | **+932 bytes** |

Extraction shrinks. Consolidation grows. **Both reduce owners, and only owner
count predicts the propagation failure** — which is the useful thing this pair
of measurements says, and it is not what either of them was expected to say.
Size is the wrong axis for the rule; it was only ever a proxy.

### What was consolidated

*Which of an act's closing records is the act's* was stated at [Resolve]'s
write description, at [Read Invocation]'s precedence paragraph, at Invariant 2's
pair clause and at Generation acceptance check 2's exemption, with a fifth
restatement inside [Reconcile] step 5's scan. Gate 11 found it made **transitive
at one of them and left pairwise at the other three**, with `resolved_by` still
admitted as a supersession trigger at the invariant after being forbidden at the
other two — a lawful correction reading as a `binding_duplicate` on the page's
own recovery path.

It now lives in one place, §*Which closing stands*, and the four sites cite it.
The block says what it owns and names its citers, so the next round can see at a
glance what a change to it must reach.

**No atom was warranted and the ownership test is what says so:** no other
pattern in this corpus owns this obligation, and Duplicate Prevention owns a
different one — *has this token been seen* rather than *which of several records
stands*. An atom here would have been a file nobody else cites.

### Next, by the same instrument

The **findings surface** is the remaining hot ownerless machine: gate 11
produced three findings from it (F3, F8, F9), and F9 says in as many words that
`compliance_surface` is a state machine no atom names. It is mentioned across
thirteen paragraphs of this page — more than supersession was — and, like
supersession, it has **one pattern and many sites**, so the cure is
consolidation rather than extraction. That is the next piece of work before
gate 12.

### What gate 12 measures

Not density — the interventions are far too small to move ~19 KB per finding,
and saying so before the gate rather than after is the point. **Three
attributable classes, each with a baseline:**

| class | gate 10 | gate 11 | expected at gate 12 |
|---|---|---|---|
| lease-owned | 3 | 1 | **0** |
| supersession-owned | 1 (F5) | 2 (F2, and F3 in part) | **0** |
| findings-surface-owned | 0 | 3 (F3, F8, F9) | consolidation pending |

A class that goes to zero is that cure working. The total foundational count is
expected to stay where it is, and that is not evidence against either cure.

---

## Gate 12 — 2026-09-10, the extraction experiment

**6 foundational, 15 refining, 6 rhetorical**, against gate 11's 9/17/5. Body
essentially flat: 167,789 bytes against 167,831.

**The first fall in the foundational count in four gates — and it must not be
read as one.** Gate 11's findings were never repaired; the roadmap sent the
effort to extraction instead. So gate 12 read the *same defective page* plus two
consolidations, and of gate 11's nine foundational findings only three
recurred, two were closed by the consolidations, and **four were simply not
re-found**. Reader variance is real and this is the measurement that shows its
size: a fresh reader missed four standing foundational defects that another
fresh reader had found on the same text. Any conclusion resting on the total is
worth less than the per-class tracking below.

### What actually happened to each class

| class | g10 | g11 | g12 | reading |
|---|---|---|---|---|
| lease **rule** (grant, terminus, waiter's bound, `remaining`) | 3 | 1 | **0** | the extraction held |
| lease **binding** — how *this page* binds the rule | — | — | **1** (F3) | the same defect one level down |
| supersession **rule** | 1 | 2 | **0** | the consolidation held |
| the duplicate **second key** | — | 1 | **2** (F1 recurring, F4) | consolidation did not carry the exemption |
| findings surface | 0 | 2 | **1** (F6) | halved; survivor is a classification miss |

**Two clean wins, and both are attributable.** Gate 11's F2 — the supersession
rule made transitive at one of four owners and pairwise at three — is gone, and
it was a recurring shape, not a one-off. Gate 11's F8 — the store-outage
exemption keyed on a record no step produced — is gone because the producer was
added. Neither recurred and neither spawned a replacement of its own kind.

### Every survivor is the same failure, one level up

F3, F1 and F6 have one shape between them: **a consolidation creates a new
owner and does not carry every obligation into it.**

- F3 — the *rule* about fence instants now has one owner in the atom, and
  **this page's binding of it is still stated at three sites, which disagree**:
  *Bindings* mints the instant with the allowance, Configuration says the fence
  carries the bare instant "which is where *Bindings* puts it" — an assertion
  about a passage that says the opposite — and *Primitive policies* cites the
  entry that denies it. Extraction removed duplicated ownership of the *rule*;
  it does nothing about duplicated statements of the *binding*, and the binding
  is what an implementer reads.
- F1 — the second key's rule is consolidated, and the `service_identity = none`
  exemption that check 3 carries was not carried with it, so the page still
  mandates a state three surfaces report as a failure. **This is gate 11's F3
  recurring through its own repair.**
- F6 — `findings` became a declared element and was not given the Contract
  classification every other element carries, so the page repudiates the old
  scheme without supplying the new one.

**So the rule earns its own corollary: consolidating is a change like any
other, and it needs the obligation sweep run on it.** When a new owner is
created, the sweep's question is not only *what must change because of this*
but *what did the old owners say that the new one must now say* — the
exemptions, the classifications, the bindings. Three of gate 12's six
foundational findings are answers to that question that nobody asked.

### What the experiment says about extraction

The claim under test was: a page that cites rather than restates carries fewer
obligations to propagate. **Held, for the classes where ownership actually
moved** — lease rule 3 → 1 → 0, supersession 1 → 2 → 0, findings 0 → 2 → 1 —
and each of those is directly attributable in a way the total is not. The
density question remains unanswered and unanswerable at this intervention size,
which was said before the gate ran and is repeated here so the silence is not
read as a result.

**And the honest correction to the method:** ownership has levels. Extracting a
rule to an atom leaves the *binding* behind, and a binding stated three ways is
the same defect wearing the composing pattern's clothes. The next consolidation
on this page is `commit_fence`'s binding, which F3 names precisely.


---

## The gate-12 repair round (2026-09-10)

**Scope.** Gate 12's 6 foundational, 15 refining and 6 rhetorical, plus the four
of gate 11's nine foundational findings gate 12 did not re-find and which were
still open: the payload keys (F1), `not-open`'s producing source (F4),
[Resolve]'s credential pre-validation (F5), and the count partition (F7).
Ten findings closed a defect gate 11 had also named, which is the fresh-reader
variance this campaign measured last round working in the other direction.

**Two consolidations, both written in controlled normative form.**

| | §*Where the allowance goes* | §*Instance start* |
|---|---|---|
| Obligation | where the cross-seam allowance is spent | the conditions of instance start |
| Owners before | 3 (Bindings, Configuration, Primitive policies) | 4 (Configuration ×3, Invariant 4, check 4, walkthrough) |
| Owners after | 1 | 1 |
| Findings it closes | F3, R4, R13 | F2, R1, R2 |
| New obligations it adds | 3 (a shorter usable lease, a widened abandon edge, a disclosed write bound with headroom) | 2 (condition 5; condition 3's fence term) |

**The round's size.** 185,699 → 216,525 characters, +16.6%. The page grew,
and it should have: the round added five obligations that did not exist, gave
`findings` a full Contract treatment, and gave [Read Invocation] two arms it
lacked. Owner count is what the experiment measures and it fell in both cases.

### The result that matters most

**Two of this round's findings were prose drifting away from a
machine-checkable form that was already correct.**

1. **Condition 4's floor.** The page said `run_bound ≥ 2 × closure_latency +
   journal_write_bound`. The schedule enumerator — the same script that refuted
   two earlier forms of the window inequality — had been filtering on
   `max(completion_bound, closure_latency) + closure_latency` since the round
   that wrote it. Re-run under each floor over the same 432 tuples:

   | floor | tuples admitted | window-inequality breaches among them |
   |---|---|---|
   | the prose's, `2 × closure_latency + journal_write_bound` | 324 | **15** |
   | the enumerator's `max` form | 288 | **0** |

   So the prose floor was not merely weaker — it admitted 15 deployments the
   window inequality does not hold for.

2. **The second key's report-only branch.** Gate 12's F1 (and gate 11's F3
   before it) is that the duplicate key has no exemption for the mode the page
   itself instructs to produce duplicates. The formal model's corresponding
   invariant has read `Inv7_OneLiveIntent == ServiceIdentity => ~secondOpened`
   since the gate that added it. **The branch was in the model all along.**

In both cases the machine-readable artifact was right and the sentence was
wrong, and in both cases the sentence was the newer of the two. This is the
campaign's first direct evidence for the controlled-language thesis measured
rather than argued: the prose did not rot through carelessness. It rotted
because nothing was reading it.

**Consequence for the method:** at the end of every round, diff the prose
against the model, the enumerator and the fixtures — in the direction of
*does the page still say what the code checks*, which is the opposite of the
usual direction.

### The first confirmed remedy in five gates

Four consecutive gates identified a real defect and prescribed the wrong
remedy, which the model distinguished each time; that is a frozen rule. Gate
12's R1 is the first prescription the evidence **confirmed**. The reason is
visible and does not weaken the rule: the evidence for the `max` form already
existed, so what the reader found was the prose disagreeing with a check, not a
hypothesis about a mechanism.

Gate 12's F3 is the rule holding in its usual direction. The finding was real —
three passages, one asserting of another the opposite of what it said. The
prescription was to make the fence carry the bare `expires_at`; that is the
construction the Lease atom declares non-conforming, and the correct repair is
the other way round: mint the allowance in, and then **size for the minting**,
which condition 3 now does. The gate's spurious-refusal scenario is unreachable
under that sizing.

### The obligation sweep

Nineteen obligations enumerated from the round's diff. The sweep found nine
unpropagated sites, and one defect the round did not introduce: the Summary and
the Ledger both said the formal model has **five** components and both then
listed six, the operator having been added at gate 9 without the count moving.
Nothing in this round touched either sentence — the sweep found it because
enumerating an obligation forces you to open the passages that must honour it.

**The linter caught a self-introduced defect for the fourth consecutive round**
— two Ledger `open:` lines written as prose and a `closed:` key the grammar
does not have. Fourth round running; the check is earning its place.

### What is owed at gate 13

The test for the next gate is specific, and it is the one this round's shape
sets up: **gate 12's every foundational finding was a consolidation that had
not carried every obligation into its new owner.** This round performed two
more consolidations and ran the sweep on them deliberately. If gate 13 finds
the same shape again, the sweep is not sufficient for consolidations and the
discipline needs a stronger form. If it does not, the corollary holds.
