# Fresh-reader adversarial gate — Recoverable Invocation

VERDICT: NOT CLEAN
FOUNDATIONAL: 7
REFINING: 12
RHETORICAL: 8

Pass 1 (GRID) surfaced F1, F3, F5, R1, R3, R4, R10, Rh6, Rh8. Pass 2 (EOS) is otherwise **clean**: the substrate's own extraction case clears Gates 1–3 (the sweep is a state machine no constituent carries), the three state elements are honestly classified as derived indexes with a past-horizon answer, the Lease atom is named as forthcoming rather than absorbed, and every capability attributed to Audit Trail — the open-upper-bound range read, `record_action`'s four-arm contract with its `(step)` payload, `read_record`'s *Purged* answer, `payload_cap` / `reference_length_cap` / `attestation_id_width`, `retention_policy`'s selector form, the `reconciliation_operator` convention, Invariants 1/2/3/4/8 — resolves to a line of that page's projected contract. The two places Audit Trail grants nothing (the pass-through range read's rejection arms; read-your-writes) are declared here as this composition's own instance capability requirements, which is the correct disposition. Pass 3 supplied F2, F4, F6, F7 and most of the refining list.

---

## FOUNDATIONAL FINDINGS

### F1 — No surface of this composition carries `kind`, and the page declares that omission fatal
**WHERE:** all seven signature blocks (`open`, `close`, `refuse`, `yield`, `resolve`, `reconcile`, `read_invocation`); *Composition state* → `open_invocations`; *Configuration* → `act_section`.

**DEFECT:** One instance serves many act kinds (`bindings` is "the table of act kinds this instance serves"; `journal` is "one per Recoverable Invocation instance, shared by every act kind it serves"). The section is keyed by `(kind, act_key)`, and the page argues the point explicitly — "abbreviated `act_key` nowhere, since two kinds with byte-equal keys are two sections and a signature that omits the kind names the wrong one." Every one of this composition's own signatures then omits it: `open(act_key, actor_ref, credential, intent_data)` must call `take((kind, act_key), …)`, build `action_ref = <kind>.intended`, and look up the kind's `completion_bound`, `outcome_envelope` and `service_identity`, with no argument naming the kind. `close`, `refuse`, `yield` and `resolve` must each call `remaining`/`release`/`take` on the pair with the same gap. And `open_invocations` — the map three steps read — is keyed on `act_key` alone, while [Reconcile] step 1 rebuilds it in one pass across every bound kind.

**FAILURE:** An instance binds `custody` and `ledger`, both with `act_key = subject_ref`. Subject `S` has a live `ledger` intent. A `custody` invocation calls `open(S, …)`: an implementer has no argument from which to derive `<kind>`, and if the map is built as declared, `open_invocations[S]` returns the `ledger` intent — the `custody` invocation is refused `act-in-flight(<a foreign invocation_id>)`. Symmetrically, [Reconcile] step 2 reads `open_invocations[S]`, finds two kinds' intents under one entry, and cannot say which `(kind, act_key)` section to take before probing.

**FIX:** Add `kind` as the first parameter of `open`, `close`, `refuse`, `yield`, `resolve` and `read_invocation`, and key `open_invocations` on `(kind, act_key)` throughout, exactly as `act_section` is keyed and for the reason `act_section` gives.

---

### F2 — `not-open` carries two meanings, and the page asserts twice that it carries one
**WHERE:** [Close]/[Refuse] step 0 ("**`not-open`** is step 0 of [Close] and [Refuse]…"); [Refuse]'s body; [Resolve]'s body; Terms → *Already Accounted*.

**DEFECT:** The page fixes the code globally: "`not-open` … decided from the invocation's own [Open] result — the `intent_event_id` [Open] returned — and never from a journal read: an `invocation_id` this invocation did not open is an adopter's programming error, not a protocol state." [Refuse] repeats it and builds `already-accounted` specifically so that "another writer already closed this invocation" does not land on `not-open`, arguing "Two meanings on one code here would be worse than elsewhere, because they imply opposite actions — fix the calling code, or report the act as already closed by another writer." The *Already Accounted* card repeats it a third time ("never decided from a journal read"). [Resolve] then does exactly the forbidden thing: "re-reads the act's records under it — an outcome or a refusal naming the id → `rejected(not-open)` — here meaning *nothing left to resolve*, wider than [Close]'s absence-from-the-map." That is a second, unrelated meaning, decided from a journal read, on the one code the page spends three passages fixing to a single meaning.

**FAILURE:** An operator resolves an escalation that a sweep run closed thirty seconds earlier. [Resolve] returns `not-open`. The operator's tool, built to the page's stated global rule, reads `not-open` as "this id was never opened by this caller — a programming error" and files a defect, when the truth is "already accounted for, report it and stop" — the exact pair of opposite actions [Refuse] minted `already-accounted` to keep apart. A generator implementing the stated rule ("never from a journal read") produces a [Resolve] with no arm at all for an already-closed intent.

**FIX:** Give [Resolve] `already-accounted(closing_event_id)` — the code [Refuse] already defines for the identical condition — and delete `not-open` from [Resolve]'s signature, leaving it as step 0's single programming-error diagnosis everywhere.

---

### F3 — Three surfaces read records that no declared state element retains and the delta-bounded read cannot see
**WHERE:** [Open] step 3 (`act-landed`); *Composition state* → `open_invocations`, `closed_acts`, `sequence_high_water`; [Resolve]'s supersession re-read; [Read Invocation].

**DEFECT:** Reads on this page are delta reads — "Every re-read on this page reads the delta above [`sequence_high_water`] and **advances the local maps by that delta**" — so anything older than the mark must be in a local map. Three elements are declared, and none holds an invocation-written closing record keyed by act: `open_invocations` is intents "less those a later record names" (it discards exactly the closings), `closed_acts` is "the set of `invocation_id`s the **sweep** has closed", and `sequence_high_water` is a scalar. [Open] step 3 nevertheless says "for an act kind bound `repeatable = no`, read the act's latest outcome **through the same rebuild**" — a rebuild that by construction throws that record away and a read bounded below by the mark. The same gap hits [Resolve] (it must find an `escalated` record days old in order to supersede it) and [Read Invocation] (the act's older invocations, which it promises to reach "by `invocation_id`").

**FAILURE:** A genesis chain is created on day 1; its `ledger.created` outcome lands at sequence 900. On day 30 the mark stands at 40,000 and the caller re-runs the genesis. [Open] step 3's delta read starts above the mark, no local map holds sequence 900, and the `act-landed(outcome_event_id)` refusal — an exported code with a payload no source can supply — never fires. The invocation proceeds to a second genesis commit and is caught, if at all, by the constituent's own `already-*` arm. [Resolve] on a two-day-old escalation misses the record it is meant to supersede and writes an unlinked second closing.

**FIX:** Either declare a fourth derived index (`act_closings`: `(kind, act_key) → the act's closing records`, rebuilt from the same range read, past-horizon *not needed*), or state that [Open]'s `act-landed` guard, [Resolve]'s supersession read and [Read Invocation] issue a full filtered range read from the log's beginning rather than a delta read — and say which, since the two have different cost bounds.

---

### F4 — Invariant 4 promises a per-intent outage surfacing that [Reconcile] cannot produce, and an acceptance check clears on it
**WHERE:** Invariant 4 (*Liveness*); [Reconcile]'s preamble; Generation acceptance check 3; *Externally-clearable checks*, first bullet.

**DEFECT:** Invariant 4's liveness is "conditional on the journal and the adopter's store being reachable — an outage leaves the intent open and its key refused `journal-unavailable` at [Open] for the outage's duration, **surfaced by [Reconcile] step 5**." [Reconcile] then states the opposite of itself: on a journal outage "the run writes nothing, surfaces the outage on `compliance_surface`, and returns `rejected(journal-unavailable)`" — it never reaches step 5 — and the page says why in its own words: step 5 "can only report intents it enumerated." So during a journal outage no *intent* is surfaced, only the outage. Check 3's exemption is keyed on the intent ("one surfaced during a declared outage"), and the externally-clearable check asks "whether **every intent** left open across a declared outage … was surfaced on `compliance_surface` for the outage's duration" — evidence the composition structurally cannot produce. (The store-outage arm is only partly better: step 5 surfaces an intent only once it crosses the at-risk threshold, not "for the outage's duration.")

**FAILURE:** The journal is unreachable for 20 minutes against a 10-minute `compensation_window`. Four orphans cross their windows. The journal returns; the sweep closes them. The auditor runs check 3: four intents whose closing landed past the window. The exemption requires each to have been surfaced during the outage; none was, because nothing could be enumerated. Lawful, correctly-handled behaviour reads as four conformance failures, and the externally-clearable check that was supposed to rescue them is unclearable.

**FIX:** Re-word the exemption to key on the outage record rather than on the intent — the run's `journal-unavailable` finding, carrying the outage's start and end, exempts every intent whose window overlaps it — and correct Invariant 4's liveness clause to say that a journal outage is surfaced as an outage, not as its intents.

---

### F5 — [Resolve]'s `invalid-request(purged)` arm needs an id only the destroyed payload carries, and the page says so elsewhere
**WHERE:** [Resolve] signature and body; *Composes* (`read_record` "called where an `event_id` is in hand: by [Resolve] to tell a purged intent from an absent one"); [Read Invocation]'s `not-known` paragraph; Invariant 7.

**DEFECT:** [Resolve] takes `(act_key, invocation_id, …)` and no `intent_event_id`. To answer *purged* it must call `read_record(intent_event_id)`, so it must first resolve `invocation_id → intent_event_id`. Both declared routes read the intent's payload: the filtered range read matches on the payload's `invocation_id`, and `open_invocations` is built by that same filter. The page states the consequence itself, twice — "An intent whose payload the substrate has destroyed is unreadable by the filter that builds `open_invocations`, so it is in neither map" (*Composition state*), and [Read Invocation]'s admitted exception: "an act whose every intent the substrate has purged answers [`not-known`], **by construction**: the destroyed payload carried the key." The identical construction applies to [Resolve], so its `invalid-request(purged)` arm is dead and its stated guarantee — "never `not-known`, because absence and lawful destruction are different answers and this page does not let the second read as the first" — is exactly what the page admits happens at [Read Invocation].

**FAILURE:** Under `service_identity = none`, an intent is surfaced and never resolved. Its payload is purged at the horizon. An operator calls `resolve(act_key, invocation_id, …)`. Every read that could produce `intent_event_id` reads the destroyed payload, so [Resolve] returns `not-known` — lawful destruction reported as absence, which §*Lawful destruction is answered before absence* forbids and this signature's `purged` payload exists to prevent.

**FIX:** Add `intent_event_id` to [Resolve]'s argument list (the operator holds it from the escalation record or from [Read Invocation]) so the `read_record` call has an id in hand; or delete the `purged` arm and extend [Read Invocation]'s admitted exception to [Resolve] in the same words.

---

### F6 — A resolution that closes an `escalated` record names nothing, so both duplicate surfaces fail a lawful resolution
**WHERE:** [Resolve] (the write description, and "an `escalated` record is **superseded** by the operator's disposition"); [Read Invocation]'s precedence rule; Generation acceptance check 2's exemption.

**DEFECT:** Supersession is defined by naming: check 2 exempts "a closing that names another in `supersedes`, or carries `resolved_by`, **together with the one it names**," and [Read Invocation] says such a closing "replaces **the one it names**." For the abandoned case [Resolve] is required to carry `supersedes = <the abandoned event_id>`. For the escalated case it is not: the record is written "with `recovery = true, resolved_by = actor_ref, acting_actor_ref = …`" and no `supersedes`. A record carrying only `resolved_by` names the operator, not a record — so the exemption and the precedence rule have no referent, and by their own next sentence ("Among closings that supersede nothing and are superseded by nothing, the **lowest `sequence_number`** wins and the rest are duplicates") both records fall into the duplicate bucket.

**FAILURE:** The sweep escalates `inv-7f2` (`cause = not-observed`) at sequence 5000. An operator investigates, runs `probe`, and resolves it with an `outcome` disposition at sequence 5200 carrying `resolved_by` and no `supersedes`. [Read Invocation] then reports `state = escalated` (lowest sequence wins) and `binding_duplicate = true` for a correctly resolved act, and check 2 counts two unexempted closings on one `invocation_id` and fails the deployment — on the page's own headline recovery path.

**FIX:** Require every [Resolve] closing to carry `supersedes = <the event_id of the record it closes over>` whenever one exists — escalations included — and drop the bare `resolved_by` trigger from both the precedence rule and check 2's exemption, so supersession is always by name.

---

### F7 — [Resolve] performs an age comparison with no declared clock, falsifying two closed claims
**WHERE:** [Resolve] ("an `abandoned` disposition for an intent younger than `completion_bound + clock_skew_allowance` → `rejected(invalid-request)`"); *Configuration* → `clock_skew_allowance` ("Five clocks meet on this page"); *Primitive policies* → `now`; *Edge cases* → *Clock semantics*.

**DEFECT:** The page states a complete clock inventory twice. `clock_skew_allowance` enumerates five: the adopter's seam, the sweep's seam, the substrate's `recorded_at`, the section host's `expires_at`, and the store's under a `commit_fence`. *Clock semantics* states the injection rule exhaustively: "`now` and `invocation_id` are injected at the adopter's seam per invocation, and at the sweep's seam once per run." [Resolve] is neither an adopter invocation nor a sweep run — it mints its own `operator_run_id` "per operator call" — yet its too-young guard compares a present reading against the substrate's `recorded_at` under the allowance. No seam supplies that reading, so a sixth clock exists unnamed, or the action reads one inside itself, which *Logic Confinement* forbids and this page's own "The composition samples no clock" denies.

**FAILURE:** A generator implements [Resolve] and reaches the too-young guard with no injected `now` in scope; the only way to close the step is a wall-clock read inside the transition. The guard is not cosmetic — it is what stops an operator writing `abandoned` while a fenceless write may still land — so a non-deterministic, unbounded-skew reading now decides a destructive record, on a page that says no write is decided by a cross-seam comparison outside a declared fence.

**FIX:** Declare the operator seam as a sixth clock: `now` and `operator_run_id` are injected per [Resolve] call, the guard runs under `clock_skew_allowance`, and both the five-clock enumeration and the *Clock semantics* injection rule are amended to say so.

---

## REFINING FINDINGS

- **R1** — [Resolve] signature · `invalid-credential` is exported but no step lands it; the body routes [Resolve]'s `record_action` arms through the *outcome* position rule, which maps `invalid-credential` to a `recording-failure`, leaving the signature arm dead or contradicted → land it explicitly as a pre-write refusal with nothing appended, or remove it.
- **R2** — [Reconcile] return contract · the claimed partition `closed + abandoned + escalated + skipped + closed_already = examined` has no bucket for the service-identity `invalid-credential` path ("writes nothing further under until reconfigured"), for an act whose closing write was left for the next run after step 3 already said "Count `closed`", or for the unbound-kind intents step 1 surfaces → state that all three fall in `skipped`, and say whether unbound-kind intents enter `examined`.
- **R3** — Generation acceptance check 4 · says "confirm all three, **strictly**" while its third is stated with `≥`, and it omits the two `journal_write_bound` start checks the page declares, so clearing check 4 does not clear instance start → list all five, and mark which are strict.
- **R4** — Walkthrough · concludes "the instance starts" without ever binding `journal_write_bound`, on which two start checks turn (`completion_bound > journal_write_bound + commit round-trip`; `max(completion_bound, closure_latency) > closure_latency + journal_write_bound`) → bind it and show both, as the other three are shown.
- **R5** — Invariant 2 (*Defended in-line*) · "the formal model's **four** rejected twins" names death, a sweep that skips its re-read, an absent `journal_fence`, and a time-only visibility clause — a set that includes two twins named nowhere else and omits `-buggy-skew` and `-buggy-perwrite`, which *Composes* names → reconcile the enumeration to the twins the page actually names.
- **R6** — [Refuse] vs [Close] steps 1–2 · [Refuse] re-reads *before* it checks `remaining` while saying it does both "exactly as" [Close], which checks `remaining` first; the two orders answer differently once the lease has expired and a closing has landed ([Refuse] → `already-accounted`, [Close] → `recording-failure(outcome)` with the landed `outcome_event_id` discarded) → fix one order, and say whether a yielded [Close] may still adopt.
- **R7** — *Composes* §`journal_fence` · the three surfaces are said to "agree on one name", but `binding_duplicate` is defined over **closing** records at both [Read Invocation] and [Reconcile] step 5 while check 2 also fails a duplicate `<kind>.intended` — the duplicate-intent case has no runtime detector at all → extend the scan and the field to intents, or say the intent case is audit-only.
- **R8** — [Close] step 2 · "Under conforming section semantics **and a declared `journal_fence`** this arm is unreachable" is contradicted by the paused-invocation path the same paragraph then describes, which is fence-independent up to the re-read; the fence changes the fate of the write, not the reachability of the pre-check → say the pre-check fires either way and the fence decides only whether the write can land.
- **R9** — Walkthrough (`pairing_datum`) · the uniqueness obligation is discharged by minting `disclosed_at` from "a per-node monotonic source whose low bits carry the node", while the same paragraph asserts Selective Disclosure's not-in-future guard (`disclosed_at ≤ now` against its own injected reading, per that atom's [Record]) "refuses nothing a conforming adopter issues" → state the resolution relation under which a node-tagged stamp never exceeds the shared authority's reading.
- **R10** — *Configuration* → `compliance_surface` · the minimum record `{kind, act_key, invocation_id, finding, first_seen, run_id}` cannot be produced for the journal-outage finding (no intent was enumerated, so four of six fields are unavailable, and the `(invocation_id, finding)` dedup key is undefined), and "durable for at least `retention_period` of the kind it names" is undefined for a finding on an **unbound** kind → declare an instance-scoped finding shape for outages and unbound kinds.
- **R11** — [Read Invocation] · `records` caps the `recovery_intended` records at `read_cap` but places no cap on closing records, which the degraded Invariant 2 admits in plurality → cap them on the same term with `more`.
- **R12** — [Resolve] · a second `abandoned` disposition over an already-abandoned intent is unstated, and "an `escalated` record is superseded by the operator's disposition" admits unbounded re-escalation, each superseding the last → state the disposition/existing-record matrix.

## RHETORICAL FINDINGS

- **Rh1** — Walkthrough · "requires a `retention_period` above ten and a half minutes" rounds the stated 632 s down to 630 s, the unsafe direction → say "above 632 s".
- **Rh2** — *Rejection path — a second invocation of the same act* · says the second [Open]'s pre-check "finds the first's outcome", but the outcome read runs only for `repeatable = no` and this example is a repeatable transfer → drop the clause.
- **Rh3** — [Read Invocation] heading · labelled "(passthrough)" though nothing is passed through: it is composition-owned, built from the filtered range read plus the precedence rule → drop the label.
- **Rh4** — Bindings → `terminus` · the name says terminus, the effect is a retry bound ("the lease still governs when the invocation may write") → rename to `retry_terminus` or say plainly that the terminus is the lease under both values.
- **Rh5** — `retention_period` · declared twice, inside the `journal` binding and as a Configuration entry, with no statement of which is normative → declare once, cross-reference the other.
- **Rh6** — Terms · `not-open` and `not-known` are this composition's own rejections but have no cards, unlike every other composition-owned rejection; the Terms preamble's exemption covers only the substrate's tokens → add both cards (and note that `invalid-request(purged | malformed)` is this page's payload on a substrate token).
- **Rh7** — *Primitive policies*, the read-back paragraph · says the intent's `sequence_number` and `recorded_at` "are read through `read_record(intent_event_id)`", though the declared range read already returns both on every event → say which is intended.
- **Rh8** — [Reconcile] step 1 · "Rebuild `open_invocations` from the substrate's range read" defers to a named procedure without citing *Composition state*, which [Open] step 3 and [Close] step 2 both cite → add the citation.
